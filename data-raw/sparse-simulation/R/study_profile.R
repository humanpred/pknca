# How the number of animals per sampling time changes the coverage of the
# bootstrap (Shen and Machado 2017) compared with Yuan's and the delta-method
# standard errors, for the sparse AUCinf,obs and AUMCinf,obs.
#
# One scenario of the standard error study (two compartments, oral, serial
# sacrifice, slow elimination), with and without BLQ samples, is simulated
# with 4, 6, 10, 20, 50, and 100 animals per time.  The data seeds do not
# depend on the number of animals, so N = 4 reproduces the data sets of the
# standard error study.
#
# Yuan's and the delta-method standard errors come from
# pk.calc.aucinf.obs_sparse() and pk.calc.aumcinf.obs_sparse() on each data
# set.  The bootstrap replicates (sparse_bootstrap()) need only the point
# estimate, which is the linear-trapezoidal AUCinf,obs (or AUMCinf,obs) of the
# replicate's arithmetic mean profile; it is calculated with
# pk.calc.auc.inf.obs() and pk.calc.aumc.inf.obs(), which skips the standard
# error that the sparse functions would also calculate for every replicate.

# The scenarios of the profile:  every number of animals per time for the two
# scenarios (with and without BLQ samples)
profile_grid <- function(scenarios, n_per_time) {
  profile_scenarios <-
    scenarios$scenario[
      scenarios$compartments == 2 & scenarios$route == "oral" &
        scenarios$design == "serial" & scenarios$elimination == "slow"
    ]
  expand.grid(scenario = profile_scenarios, n_per_time = n_per_time)
}

# The AUCinf,obs and AUMCinf,obs of the arithmetic mean profile (the sparse
# point estimate), with the oral concentration at time 0 imputed as zero
estimate_inf_point <- function(conc, time, subject) {
  profile <- mean_profile(list(conc = c(0, conc), time = c(0, time), subject = c(NA, subject)))
  hl <- suppressWarnings(PKNCA::pk.calc.half.life(conc = profile$mean, time = profile$time))
  if (is.na(hl$lambda.z)) {
    return(c(auc = NA_real_, aumc = NA_real_))
  }
  idx_last <- max(which(profile$mean > 0))
  args <-
    list(
      conc = profile$mean, time = profile$time, clast = profile$mean[idx_last], lambda.z = hl$lambda.z,
      method = "linear"
    )
  c(
    auc = suppressWarnings(do.call(PKNCA::pk.calc.auc.inf.obs, args)),
    aumc = suppressWarnings(do.call(PKNCA::pk.calc.aumc.inf.obs, args))
  )
}

# Yuan's and the delta-method estimates and standard errors of one data set
estimate_inf_se <- function(d, route = "oral") {
  inputs <- sparse_inputs(d, route)
  profile <- mean_profile(inputs)
  hl <- suppressWarnings(PKNCA::pk.calc.half.life(conc = profile$mean, time = profile$time))
  if (is.na(hl$lambda.z)) {
    return(NULL)
  }
  out <- list()
  for (method in c("none", "delta")) {
    args <-
      c(
        inputs,
        list(
          lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
          lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
          options = list(sparse_lambda_z_se = method)
        )
      )
    auc <- unlist(suppressWarnings(do.call(sparse_inf_functions[[route]]$auc, args)))
    aumc <- unlist(suppressWarnings(do.call(sparse_inf_functions[[route]]$aumc, args)))
    out[[method]] <-
      data.frame(
        method = if (method == "none") "yuan" else "delta", parameter = c("auc", "aumc"),
        estimate = c(auc[[1]], aumc[[1]]), se = c(auc[[2]], aumc[[2]]), df = c(auc[[3]], aumc[[3]])
      )
  }
  do.call(rbind, out)
}

run_profile_replicate <- function(d, scenario_row, n, replicate, settings) {
  seed <- bootstrap_seed(settings$seed_base, scenario_row$scenario, replicate, settings$boot_seed_offset)
  truth <- c(auc = scenario_row$truth_auc, aumc = scenario_row$truth_aumc)
  analytic <- estimate_inf_se(d)
  boot_data <- bootstrap_datasets(d, settings$n_boot, seed)[-1]
  boot <- matrix(NA_real_, settings$n_boot, 2, dimnames = list(NULL, c("auc", "aumc")))
  for (i in seq_along(boot_data)) {
    boot[i, ] <- estimate_inf_point(boot_data[[i]]$conc_reported, boot_data[[i]]$time, boot_data[[i]]$subject)
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

# The profile study on the data sets of one scenario and number of animals
run_profile_study <- function(datasets, scenario_row, n, settings) {
  started <- Sys.time()
  data_list <- split_datasets(datasets, settings$n_profile_replicates)
  out <- vector("list", length(data_list))
  for (i in seq_along(data_list)) {
    out[[i]] <- run_profile_replicate(data_list[[i]], scenario_row, n, as.integer(names(data_list)[i]), settings)
  }
  with_branch_seconds(do.call(rbind, out), started)
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
