# How the number of animals per sampling time changes the coverage of the
# bootstrap (Shen and Machado 2017) compared with Yuan's and the delta-method
# standard errors, for the sparse AUCinf,obs and AUMCinf,obs, used by
# vignette("v24-sparse-auc-to-infinity").
#
# One scenario of data-raw/sparse_aucinf_simulation.R (two compartments, oral,
# serial sacrifice, slow elimination), with and without BLQ samples, is
# simulated with 4, 6, 10, 20, 50, and 100 animals per time.  The data seeds do
# not depend on the number of animals, so N = 4 reproduces the data sets of the
# main studies.
#
# Yuan's and the delta-method standard errors come from
# pk.calc.aucinf.obs_sparse() and pk.calc.aumcinf.obs_sparse() on each data
# set.  The bootstrap replicates (sparse_bootstrap(), 200 each) need only the
# point estimate, which is the linear-trapezoidal AUCinf,obs (or AUMCinf,obs)
# of the replicate's arithmetic mean profile; it is calculated with
# pk.calc.auc.inf.obs() and pk.calc.aumc.inf.obs(), which skips the standard
# error that the sparse functions would also calculate for every replicate.
#
#   Rscript data-raw/sparse_bootstrap_n_profile.R
#
# writes vignettes/v24-sparse-auc-to-infinity-bootstrap-n.rds (the summary).

# The design, the truth, the data simulation, and the bootstrap settings
source("data-raw/sparse_bootstrap_simulation.R")

n_profile_replicates <- as.integer(Sys.getenv("SIM_PROFILE_REPLICATES", "2000"))
n_per_time <- c(4, 6, 10, 20, 50, 100)
profile_scenarios <-
  scenarios[
    scenarios$compartments == 2 & scenarios$route == "oral" &
      scenarios$design == "serial" & scenarios$elimination == "slow",
  ]

# The AUCinf,obs and AUMCinf,obs of the arithmetic mean profile (the sparse
# point estimate), with the oral concentration at time 0 imputed as zero
estimate_inf_point <- function(conc, time, subject) {
  sparse_pk <- sparse_mean(as_sparse_pk(conc = c(0, conc), time = c(0, time), subject = c(NA, subject)))
  means <- vapply(sparse_pk, `[[`, "mean", FUN.VALUE = 1)
  times <- vapply(sparse_pk, `[[`, "time", FUN.VALUE = 1)
  hl <- suppressWarnings(pk.calc.half.life(conc = means, time = times))
  if (is.na(hl$lambda.z)) {
    return(c(auc = NA_real_, aumc = NA_real_))
  }
  idx_last <- max(which(means > 0))
  args <-
    list(
      conc = means, time = times, clast = means[idx_last], lambda.z = hl$lambda.z,
      method = "linear"
    )
  c(
    auc = suppressWarnings(do.call(pk.calc.auc.inf.obs, args)),
    aumc = suppressWarnings(do.call(pk.calc.aumc.inf.obs, args))
  )
}

# Yuan's and the delta-method estimates and standard errors of one data set
estimate_inf_se <- function(d) {
  conc <- c(0, d$conc_reported)
  time <- c(0, d$time)
  subject <- c(NA, d$subject)
  sparse_pk <- sparse_mean(as_sparse_pk(conc = conc, time = time, subject = subject))
  means <- vapply(sparse_pk, `[[`, "mean", FUN.VALUE = 1)
  times <- vapply(sparse_pk, `[[`, "time", FUN.VALUE = 1)
  hl <- suppressWarnings(pk.calc.half.life(conc = means, time = times))
  if (is.na(hl$lambda.z)) {
    return(NULL)
  }
  out <- list()
  for (method in c("none", "delta")) {
    args <-
      list(
        conc = conc, time = time, subject = subject,
        lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
        lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
        options = list(sparse_lambda_z_se = method)
      )
    auc <- unlist(suppressWarnings(do.call(pk.calc.aucinf.obs_sparse, args)))
    aumc <- unlist(suppressWarnings(do.call(pk.calc.aumcinf.obs_sparse, args)))
    out[[method]] <-
      data.frame(
        method = if (method == "none") "yuan" else "delta", parameter = c("auc", "aumc"),
        estimate = c(auc[[1]], aumc[[1]]), se = c(auc[[2]], aumc[[2]]), df = c(auc[[3]], aumc[[3]])
      )
  }
  do.call(rbind, out)
}

run_profile_replicate <- function(scenario_row, n, replicate) {
  # simulate_data() reads the number of animals per time from the global
  # environment, where the design was sourced
  assign("n_serial", n, envir = globalenv())
  seed <- seed_base + 100000*scenario_row$scenario + replicate
  d <- withr::with_seed(seed, simulate_data(scenario_row, scenario_lloq(scenario_row)))
  truth <- c(auc = scenario_row$truth_auc, aumc = scenario_row$truth_aumc)
  analytic <- estimate_inf_se(d)
  o_boot <- sparse_bootstrap(PKNCAconc(d, conc_reported ~ time | subject, sparse = TRUE), n_boot = n_boot, seed = seed + boot_seed_offset)
  d_boot <- o_boot$data_sparse
  replicates <- paste0("bootstrap", seq_len(n_boot))
  boot <- matrix(NA_real_, n_boot, 2, dimnames = list(NULL, c("auc", "aumc")))
  for (i in seq_along(replicates)) {
    rows <- d_boot$bootstrap == replicates[i]
    boot[i, ] <- estimate_inf_point(d_boot$conc_reported[rows], d_boot$time[rows], d_boot$bootstrap_subject[rows])
  }
  original <- estimate_inf_point(d$conc_reported, d$time, d$subject)
  ret <- list()
  for (parameter in c("auc", "aumc")) {
    values <- boot[, parameter]
    values <- values[!is.na(values)]
    ret[[parameter]] <-
      data.frame(
        method = c("percentile", "boot_se"), parameter = parameter,
        estimate = original[[parameter]],
        lower = c(unname(stats::quantile(values, 0.025)), original[[parameter]] - stats::qnorm(0.975)*stats::sd(values)),
        upper = c(unname(stats::quantile(values, 0.975)), original[[parameter]] + stats::qnorm(0.975)*stats::sd(values)),
        se = stats::sd(values)
      )
  }
  boot_out <- do.call(rbind, ret)
  if (!is.null(analytic)) {
    quantile_t <- ifelse(is.finite(analytic$df) & analytic$df > 0, stats::qt(0.975, analytic$df), stats::qnorm(0.975))
    analytic$lower <- analytic$estimate - quantile_t*analytic$se
    analytic$upper <- analytic$estimate + quantile_t*analytic$se
    analytic$df <- NULL
    boot_out <- rbind(boot_out, analytic[, names(boot_out)])
  }
  boot_out$truth <- truth[boot_out$parameter]
  boot_out$n_per_time <- n
  boot_out$blq <- scenario_row$blq
  boot_out$replicate <- replicate
  boot_out
}

run_profile_job <- function(i, jobs, profile_scenarios) {
  run_profile_replicate(profile_scenarios[jobs$row[i], ], jobs$n[i], jobs$replicate[i])
}

summarize_profile <- function(results) {
  results <- results[is.finite(results$estimate) & is.finite(results$lower) & is.finite(results$upper), ]
  results$covered <- results$lower <= results$truth & results$truth <= results$upper
  key <- paste(results$n_per_time, results$blq, results$method, results$parameter)
  rows <- list()
  for (current_rows in split(seq_len(nrow(results)), factor(key, levels = unique(key)))) {
    r <- results[current_rows, ]
    rows[[length(rows) + 1]] <-
      data.frame(
        n_per_time = r$n_per_time[1], blq = r$blq[1], method = r$method[1], parameter = r$parameter[1],
        n = nrow(r),
        coverage = 100*mean(r$covered),
        coverage_mcse = 100*sqrt(mean(r$covered)*(1 - mean(r$covered))/nrow(r)),
        median_ci_width = 100*stats::median((r$upper - r$lower)/r$truth),
        # The estimate is the same for every method; its bias does not shrink
        # with more animals
        median_bias = 100*stats::median((r$estimate - r$truth)/r$truth),
        # Robust:  the bootstrap standard error is heavy-tailed when lambda.z
        # is near zero in a replicate
        median_se_ratio = stats::median(r$se)/(stats::IQR(r$estimate)/1.349)
      )
  }
  do.call(rbind, rows)
}

if (sys.nframe() == 0) {
  started <- Sys.time()
  # The truth with the seed of data-raw/sparse_aucinf_simulation.R for this
  # route, elimination, and number of compartments
  truth_keys <- unique(scenarios[, c("route", "elimination", "compartments")])
  truth_index <- which(truth_keys$route == "oral" & truth_keys$elimination == "slow" & truth_keys$compartments == 2)
  tv <- true_values(profile_scenarios[1, ], seed = seed_base + truth_index)
  profile_scenarios$truth_auc <- tv$truth[["auc"]]
  profile_scenarios$truth_aumc <- tv$truth[["aumc"]]
  jobs <- expand.grid(row = seq_len(nrow(profile_scenarios)), n = n_per_time, replicate = seq_len(n_profile_replicates))
  results <-
    parallel::mclapply(
      seq_len(nrow(jobs)), run_profile_job,
      jobs = jobs, profile_scenarios = profile_scenarios, mc.cores = n_cores, mc.preschedule = TRUE
    )
  failed <- vapply(results, inherits, "try-error", FUN.VALUE = TRUE)
  if (any(failed)) {
    stop("Replicates failed:  ", paste(unique(vapply(results[failed], as.character, "")), collapse = "; "))
  }
  results <- do.call(rbind, results)
  simulation <-
    list(
      summary = summarize_profile(results),
      n_per_time = n_per_time,
      n_boot = n_boot,
      n_replicates = n_profile_replicates,
      truth = tv$truth,
      seed_base = seed_base,
      boot_seed_offset = boot_seed_offset,
      pknca_version = as.character(utils::packageVersion("PKNCA")),
      r_version = R.version.string,
      run_date = format(Sys.Date()),
      run_minutes = as.numeric(difftime(Sys.time(), started, units = "mins"))
    )
  saveRDS(simulation, "vignettes/v24-sparse-auc-to-infinity-bootstrap-n.rds")
  saveRDS(results, "data-raw/sparse_bootstrap_n_profile_replicates.rds")
  print(simulation$summary, digits = 3)
}
