# The bootstrap (Shen and Machado 2017) standard error and percentile interval
# of the sparse AUCinf,obs and AUMCinf,obs, on the same simulated data sets as
# data-raw/sparse_aucinf_simulation.R, for vignette("v24-sparse-auc-to-infinity").
#
# Each data set is resampled with sparse_bootstrap() (animals within each
# sampling-time stratum), and every replicate's AUCinf,obs and AUMCinf,obs are
# calculated as pk.nca() calculates them:  the half-life of the arithmetic mean
# profile and pk.calc.aucinf.obs_sparse() (or the IV bolus equivalent), with
# the oral concentration at time 0 imputed as zero.  Calling pk.nca() for every
# replicate would give the same values far more slowly.
#
# The bootstrap standard error is the standard deviation of the replicates; the
# intervals are the percentile interval and the estimate plus or minus 1.96
# bootstrap standard errors.
#
#   Rscript data-raw/sparse_bootstrap_simulation.R
#
# writes vignettes/v24-sparse-auc-to-infinity-bootstrap.rds (the summary).

# The design, the truth, and the simulation of a data set (the main block of
# that script does not run when it is sourced)
source("data-raw/sparse_aucinf_simulation.R")

n_boot <- as.integer(Sys.getenv("SIM_BOOT", "200"))
n_boot_replicates <- as.integer(Sys.getenv("SIM_BOOT_REPLICATES", "2000"))
# The bootstrap seeds are offset from the data seeds of the same replicate
boot_seed_offset <- 1e9

# The AUCinf,obs and AUMCinf,obs of one data set (or bootstrap replicate)
estimate_inf <- function(conc, time, subject, route) {
  if (route == "oral") {
    # The imputed zero at time 0 is known, so it has no subject
    conc <- c(0, conc)
    time <- c(0, time)
    subject <- c(NA, subject)
  }
  sparse_pk <- sparse_mean(as_sparse_pk(conc = conc, time = time, subject = subject))
  means <- vapply(sparse_pk, `[[`, "mean", FUN.VALUE = 1)
  times <- vapply(sparse_pk, `[[`, "time", FUN.VALUE = 1)
  hl <- suppressWarnings(pk.calc.half.life(conc = means, time = times))
  if (is.na(hl$lambda.z)) {
    return(c(auc = NA_real_, aumc = NA_real_))
  }
  args <-
    list(
      conc = conc, time = time, subject = subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
      options = list(sparse_lambda_z_se = "none")
    )
  c(
    auc = unlist(suppressWarnings(do.call(sparse_inf_functions[[route]]$auc, args)))[[1]],
    aumc = unlist(suppressWarnings(do.call(sparse_inf_functions[[route]]$aumc, args)))[[1]]
  )
}

run_bootstrap_replicate <- function(scenario_row, replicate) {
  seed <- seed_base + 100000*scenario_row$scenario + replicate
  # The same data set as in data-raw/sparse_aucinf_simulation.R
  d <- withr::with_seed(seed, simulate_data(scenario_row, scenario_lloq(scenario_row)))
  o_conc <- PKNCAconc(d, conc_reported ~ time | subject, sparse = TRUE)
  o_boot <- sparse_bootstrap(o_conc, n_boot = n_boot, seed = seed + boot_seed_offset)
  d_boot <- o_boot$data_sparse
  estimates <- matrix(NA_real_, n_boot + 1, 2, dimnames = list(NULL, c("auc", "aumc")))
  replicates <- c("original", paste0("bootstrap", seq_len(n_boot)))
  for (i in seq_along(replicates)) {
    rows <- d_boot$bootstrap == replicates[i]
    estimates[i, ] <-
      estimate_inf(d_boot$conc_reported[rows], d_boot$time[rows], d_boot$bootstrap_subject[rows], scenario_row$route)
  }
  truth <- c(auc = scenario_row$truth_auc, aumc = scenario_row$truth_aumc)
  ret <- list()
  for (parameter in c("auc", "aumc")) {
    boot <- estimates[-1, parameter]
    boot <- boot[!is.na(boot)]
    ret[[parameter]] <-
      data.frame(
        scenario = scenario_row$scenario, replicate = replicate, parameter = parameter,
        truth = truth[[parameter]], estimate = estimates[1, parameter],
        n_valid = length(boot),
        boot_sd = if (length(boot) > 1) stats::sd(boot) else NA_real_,
        boot_lower = if (length(boot) > 0) unname(stats::quantile(boot, 0.025)) else NA_real_,
        boot_upper = if (length(boot) > 0) unname(stats::quantile(boot, 0.975)) else NA_real_
      )
  }
  do.call(rbind, ret)
}

run_bootstrap_job <- function(i, jobs, scenarios) {
  run_bootstrap_replicate(scenarios[jobs$scenario[i], ], jobs$replicate[i])
}

summarize_bootstrap <- function(results, scenarios) {
  ok <- is.finite(results$estimate) & is.finite(results$boot_sd)
  results <- results[ok, ]
  results$covered_percentile <- results$boot_lower <= results$truth & results$truth <= results$boot_upper
  results$covered_normal <- abs(results$estimate - results$truth) <= stats::qnorm(0.975)*results$boot_sd
  key <- paste(results$scenario, results$parameter)
  rows <- list()
  for (current_rows in split(seq_len(nrow(results)), factor(key, levels = unique(key)))) {
    r <- results[current_rows, ]
    rows[[length(rows) + 1]] <-
      data.frame(
        scenario = r$scenario[1], parameter = r$parameter[1], n = nrow(r),
        coverage_percentile = 100*mean(r$covered_percentile),
        coverage_normal = 100*mean(r$covered_normal),
        median_ci_width_percentile = 100*stats::median((r$boot_upper - r$boot_lower)/r$truth),
        median_ci_width_normal = 100*stats::median(2*stats::qnorm(0.975)*r$boot_sd/r$truth),
        mean_boot_sd = mean(r$boot_sd),
        empirical_sd = stats::sd(r$estimate),
        median_valid = stats::median(r$n_valid)
      )
  }
  ret <- do.call(rbind, rows)
  ret$se_ratio <- ret$mean_boot_sd/ret$empirical_sd
  merge(scenarios, ret, by = "scenario")
}

if (sys.nframe() == 0) {
  started <- Sys.time()
  # The truth, as in data-raw/sparse_aucinf_simulation.R
  truth_keys <- unique(scenarios[, c("route", "elimination", "compartments")])
  scenarios$truth_auc <- NA_real_
  scenarios$truth_aumc <- NA_real_
  for (i in seq_len(nrow(truth_keys))) {
    rows <- which(
      scenarios$route == truth_keys$route[i] & scenarios$elimination == truth_keys$elimination[i] &
        scenarios$compartments == truth_keys$compartments[i]
    )
    tv <- true_values(scenarios[rows[1], ], seed = seed_base + i)
    scenarios$truth_auc[rows] <- tv$truth[["auc"]]
    scenarios$truth_aumc[rows] <- tv$truth[["aumc"]]
  }
  jobs <- expand.grid(scenario = scenarios$scenario, replicate = seq_len(n_boot_replicates))
  results <-
    parallel::mclapply(
      seq_len(nrow(jobs)), run_bootstrap_job,
      jobs = jobs, scenarios = scenarios, mc.cores = n_cores, mc.preschedule = TRUE
    )
  failed <- vapply(results, inherits, "try-error", FUN.VALUE = TRUE)
  if (any(failed)) {
    stop("Replicates failed:  ", paste(unique(vapply(results[failed], as.character, "")), collapse = "; "))
  }
  results <- do.call(rbind, results)
  simulation <-
    list(
      summary = summarize_bootstrap(results, scenarios),
      n_boot = n_boot,
      n_replicates = n_boot_replicates,
      seed_base = seed_base,
      boot_seed_offset = boot_seed_offset,
      pknca_version = as.character(utils::packageVersion("PKNCA")),
      r_version = R.version.string,
      run_date = format(Sys.Date()),
      run_minutes = as.numeric(difftime(Sys.time(), started, units = "mins"))
    )
  saveRDS(simulation, "vignettes/v24-sparse-auc-to-infinity-bootstrap.rds")
  saveRDS(results, "data-raw/sparse_bootstrap_simulation_replicates.rds")
  print(simulation$summary[, c("compartments", "route", "design", "blq", "elimination", "parameter", "n", "coverage_percentile", "coverage_normal", "se_ratio")], digits = 3)
}
