# The standard error study:  three standard errors of the sparse AUCinf,obs and
# AUMCinf,obs, all for the estimate AUClast + Clast/lambda.z (and its AUMC
# equivalent) from the arithmetic mean profile:
#
#   * "yuan":  lambda.z treated as known (Yuan 1993), sparse_lambda_z_se = "none"
#   * "delta":  the delta method for lambda.z from the log means,
#     sparse_lambda_z_se = "delta"
#   * "individual":  lambda.z and its standard error from a Tobit regression
#     of every individual sample from the start of the half-life range onward
#     (censored below the LLOQ), with a random intercept for each animal when
#     animals give more than one sample.  The extrapolation uses that lambda.z,
#     and its variance is added to the Yuan variance as though lambda.z were
#     independent of the means.
#
# No animal is sampled at the dose:  for oral dosing, the concentration at time
# 0 is imputed as zero (as the start_conc0 imputation does in pk.nca()), and
# for IV bolus dosing, C0 is back-extrapolated from the mean profile by the
# sparse IV estimators.  The truth is the AUC (and AUMC) from 0 to infinity of
# the population mean concentration curve, which is what the arithmetic means
# estimate.

# The sparse AUCinf,obs and AUMCinf,obs functions for the route
sparse_inf_functions <- list(
  oral = list(auc = PKNCA::pk.calc.aucinf.obs_sparse, aumc = PKNCA::pk.calc.aumcinf.obs_sparse),
  iv = list(auc = PKNCA::pk.calc.aucivinf.obs_sparse, aumc = PKNCA::pk.calc.aumcivinf.obs_sparse)
)

# The pooled samples as the sparse estimators take them:  for oral dosing, the
# concentration at time 0 imputed as zero (known, so it has no subject)
sparse_inputs <- function(d, route) {
  if (route == "oral") {
    list(conc = c(0, d$conc_reported), time = c(0, d$time), subject = c(NA, d$subject))
  } else {
    list(conc = d$conc_reported, time = d$time, subject = d$subject)
  }
}

# The arithmetic mean profile of the pooled samples, with PKNCA's BLQ rule
mean_profile <- function(inputs) {
  sparse_pk <- PKNCA::sparse_mean(PKNCA::as_sparse_pk(conc = inputs$conc, time = inputs$time, subject = inputs$subject))
  data.frame(
    time = vapply(sparse_pk, `[[`, "time", FUN.VALUE = 1),
    mean = vapply(sparse_pk, `[[`, "mean", FUN.VALUE = 1)
  )
}

# The estimates of one data set for the three methods
estimate_se_replicate <- function(d, route, design, lloq) {
  inputs <- sparse_inputs(d, route)
  fun_auc <- sparse_inf_functions[[route]]$auc
  fun_aumc <- sparse_inf_functions[[route]]$aumc
  # The half-life of the arithmetic mean profile, as pk.nca() calculates it
  profile <- mean_profile(inputs)
  hl <- suppressWarnings(PKNCA::pk.calc.half.life(conc = profile$mean, time = profile$time))
  if (is.na(hl$lambda.z)) {
    return(NULL)
  }
  idx_last <- max(which(profile$mean > 0))
  tlast <- profile$time[idx_last]
  clast <- profile$mean[idx_last]
  base_args <-
    c(
      inputs,
      list(
        lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
        lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points
      )
    )
  out <- list()
  for (method in c("none", "delta")) {
    args <- c(base_args, list(options = list(sparse_lambda_z_se = method)))
    auc <- unlist(suppressWarnings(do.call(fun_auc, args)))
    aumc <- unlist(suppressWarnings(do.call(fun_aumc, args)))
    label <- if (method == "none") "yuan" else "delta"
    out[[length(out) + 1]] <-
      data.frame(
        method = label, parameter = c("auc", "aumc"),
        estimate = c(auc[[1]], aumc[[1]]),
        se = c(auc[[2]], aumc[[2]]),
        df = c(auc[[3]], aumc[[3]])
      )
  }
  # Individual samples from the start of the half-life range onward
  d_terminal <- d[d$time >= hl$lambda.z.time.first, ]
  tobit <- fit_tobit_lambda_z(d_terminal, random = design == "batch", lloq = lloq)
  if (!is.na(tobit[["lambda.z"]]) && tobit[["lambda.z"]] > 0) {
    lambda_z <- tobit[["lambda.z"]]
    # The Yuan part with the Tobit lambda.z, and the added lambda.z variance
    args <- c(base_args, list(options = list(sparse_lambda_z_se = "none")))
    args$lambda.z <- lambda_z
    auc <- unlist(do.call(fun_auc, args))
    aumc <- unlist(do.call(fun_aumc, args))
    d_auc_d_lambda_z <- -clast/lambda_z^2
    d_aumc_d_lambda_z <- -tlast*clast/lambda_z^2 - 2*clast/lambda_z^3
    var_lambda_z <- tobit[["se"]]^2
    v_auc <- auc[[2]]^2
    v_aumc <- aumc[[2]]^2
    v_lz_auc <- d_auc_d_lambda_z^2*var_lambda_z
    v_lz_aumc <- d_aumc_d_lambda_z^2*var_lambda_z
    out[[length(out) + 1]] <-
      data.frame(
        method = "individual", parameter = c("auc", "aumc"),
        estimate = c(auc[[1]], aumc[[1]]),
        se = sqrt(c(v_auc + v_lz_auc, v_aumc + v_lz_aumc)),
        df =
          c(
            combine_df(v_auc, auc[[3]], v_lz_auc, tobit[["df"]]),
            combine_df(v_aumc, aumc[[3]], v_lz_aumc, tobit[["df"]])
          )
      )
  }
  ret <- do.call(rbind, out)
  ret$percent_extrapolated <- 100*clast/hl$lambda.z/ret$estimate[ret$method == "yuan" & ret$parameter == "auc"]
  ret
}

# The standard error study on the data sets of one scenario
run_se_study <- function(datasets, scenario_row, n_replicates) {
  started <- Sys.time()
  lloq <- scenario_lloq(scenario_row)
  data_list <- split_datasets(datasets, n_replicates)
  out <- vector("list", length(data_list))
  for (i in seq_along(data_list)) {
    d <- data_list[[i]]
    ret <- estimate_se_replicate(d, scenario_row$route, scenario_row$design, lloq)
    if (!is.null(ret)) {
      ret$truth <- c(auc = scenario_row$truth_auc, aumc = scenario_row$truth_aumc)[ret$parameter]
      ret$replicate <- as.integer(names(data_list)[i])
      ret$scenario <- scenario_row$scenario
      ret$blq_last_time <- mean(d$blq[d$time == max(d$time)])
      out[[i]] <- ret
    }
  }
  with_branch_seconds(do.call(rbind, out), started)
}

summarize_se <- function(results, scenarios) {
  results$t_quantile <- ifelse(is.finite(results$df) & results$df > 0, stats::qt(0.975, results$df), stats::qnorm(0.975))
  results$covered <- abs(results$estimate - results$truth) <= results$t_quantile*results$se
  key <- paste(results$scenario, results$method, results$parameter)
  by_key <- split(results, key)
  keys <- unique(results[, c("scenario", "method", "parameter")])
  rows <- list()
  for (i in seq_len(nrow(keys))) {
    r <- by_key[[paste(keys$scenario[i], keys$method[i], keys$parameter[i])]]
    ok <- is.finite(r$estimate) & is.finite(r$se)
    relative_error <- (r$estimate[ok] - r$truth[1])/r$truth[1]
    rows[[i]] <- data.frame(
      keys[i, ],
      n = sum(ok),
      truth = r$truth[1],
      relative_bias = 100*mean(relative_error),
      # The estimate can have heavy tails (a lambda.z near zero), so robust
      # summaries are given with the moments
      rmse = 100*sqrt(mean(relative_error^2)),
      median_absolute_error = 100*stats::median(abs(relative_error)),
      empirical_sd = stats::sd(r$estimate[ok]),
      mean_se = mean(r$se[ok]),
      median_ci_width = 100*stats::median(2*r$t_quantile[ok]*r$se[ok]/r$truth[1]),
      median_df = stats::median(r$df[ok], na.rm = TRUE),
      coverage = 100*mean(r$covered[ok]),
      coverage_mcse = 100*sqrt(mean(r$covered[ok])*(1 - mean(r$covered[ok]))/sum(ok)),
      percent_extrapolated = mean(r$percent_extrapolated[ok]),
      blq_last_time = 100*mean(r$blq_last_time[ok])
    )
  }
  ret <- do.call(rbind, rows)
  ret$se_ratio <- ret$mean_se/ret$empirical_sd
  merge(scenarios, ret, by = "scenario")
}
