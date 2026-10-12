# The bootstrap (Shen and Machado 2017) standard error and percentile interval
# of the sparse AUCinf,obs and AUMCinf,obs, on the data sets of the standard
# error study.
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

# The seed of the bootstrap of one data set, offset from its data seed
bootstrap_seed <- function(seed_base, scenario, replicate, boot_seed_offset) {
  data_seed(seed_base, scenario, replicate) + boot_seed_offset
}

# The original data set and its bootstrap replicates from sparse_bootstrap(),
# as a list of n_boot + 1 data sets (the original first) with the bootstrap
# draw of each animal as its subject
bootstrap_datasets <- function(d, n_boot, seed) {
  o_conc <- PKNCA::PKNCAconc(d, conc_reported ~ time | subject, sparse = TRUE)
  d_boot <- PKNCA::sparse_bootstrap(o_conc, n_boot = n_boot, seed = seed)$data_sparse
  replicates <- c("original", paste0("bootstrap", seq_len(n_boot)))
  out <- vector("list", n_boot + 1)
  for (i in seq_along(replicates)) {
    rows <- d_boot$bootstrap == replicates[i]
    out[[i]] <-
      data.frame(
        subject = d_boot$bootstrap_subject[rows], time = d_boot$time[rows],
        conc_reported = d_boot$conc_reported[rows], blq = d_boot$blq[rows]
      )
  }
  out
}

# The AUCinf,obs and AUMCinf,obs of one data set (or bootstrap replicate)
estimate_inf <- function(conc, time, subject, route) {
  if (route == "oral") {
    # The imputed zero at time 0 is known, so it has no subject
    conc <- c(0, conc)
    time <- c(0, time)
    subject <- c(NA, subject)
  }
  profile <- mean_profile(list(conc = conc, time = time, subject = subject))
  hl <- suppressWarnings(PKNCA::pk.calc.half.life(conc = profile$mean, time = profile$time))
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

run_bootstrap_replicate <- function(d, scenario_row, replicate, settings) {
  seed <- bootstrap_seed(settings$seed_base, scenario_row$scenario, replicate, settings$boot_seed_offset)
  boot <- bootstrap_datasets(d, settings$n_boot, seed)
  estimates <- matrix(NA_real_, settings$n_boot + 1, 2, dimnames = list(NULL, c("auc", "aumc")))
  for (i in seq_along(boot)) {
    estimates[i, ] <- estimate_inf(boot[[i]]$conc_reported, boot[[i]]$time, boot[[i]]$subject, scenario_row$route)
  }
  truth <- c(auc = scenario_row$truth_auc, aumc = scenario_row$truth_aumc)
  ret <- list()
  for (parameter in c("auc", "aumc")) {
    values <- estimates[-1, parameter]
    values <- values[!is.na(values)]
    ret[[parameter]] <-
      data.frame(
        scenario = scenario_row$scenario, replicate = replicate, parameter = parameter,
        truth = truth[[parameter]], estimate = estimates[1, parameter],
        n_valid = length(values),
        boot_sd = if (length(values) > 1) stats::sd(values) else NA_real_,
        boot_lower = if (length(values) > 0) unname(stats::quantile(values, 0.025)) else NA_real_,
        boot_upper = if (length(values) > 0) unname(stats::quantile(values, 0.975)) else NA_real_
      )
  }
  do.call(rbind, ret)
}

# The bootstrap study on the data sets of one scenario
run_bootstrap_study <- function(datasets, scenario_row, settings) {
  started <- Sys.time()
  data_list <- split_datasets(datasets, settings$n_boot_replicates)
  out <- vector("list", length(data_list))
  for (i in seq_along(data_list)) {
    out[[i]] <- run_bootstrap_replicate(data_list[[i]], scenario_row, as.integer(names(data_list)[i]), settings)
  }
  with_branch_seconds(do.call(rbind, out), started)
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
