# The Tobit half-life compared with the log-linear half-life for the sparse
# AUCinf,obs and AUMCinf,obs with BLQ samples.
#
# Three estimates of lambda.z are compared:
#
#   * "log-linear":  the log-linear half-life of the arithmetic mean profile
#     (pk.calc.half.life(), as in the other studies)
#   * "tobit-mean":  the Tobit half-life of the mean profile, with the LLOQ of
#     each time carried through the mean profile and a time whose mean is BLQ
#     censored (pk.calc.half.life(hl_method = "tobit"), as pk.nca() calculates
#     it for sparse data)
#   * "tobit-individual":  a Tobit regression of every individual sample from
#     the start of the log-linear half-life range onward, with a random
#     intercept for each animal in the batch design (fit_tobit_lambda_z())
#
# Each gives the AUC (and AUMC) to infinity as the sparse AUClast plus the
# extrapolation from the mean at tlast.  The intervals are:
#
#   * log-linear:  Yuan's standard error, the delta method, and the bootstrap
#   * tobit-mean:  Yuan's standard error (the Tobit fit has no standard error
#     for lambda.z, and the delta method needs the log-linear fit) and the
#     bootstrap
#   * tobit-individual:  Yuan's variance plus the variance of lambda.z from
#     the Tobit fit (as the "individual" method of the standard error study),
#     and the bootstrap
#
# The bootstrap (sparse_bootstrap()) recalculates the same lambda.z and
# estimate in every replicate.  The data sets are those of the BLQ scenarios of
# the standard error study and of the BLQ arm of the profile over the number
# of animals per time.

lambda_z_methods <- c("log-linear", "tobit-mean", "tobit-individual")

# The three estimates of lambda.z from one data set (or bootstrap replicate),
# with the log-linear half-life points and the standard error of the
# individual-sample Tobit fit
lambda_z_estimates <- function(d, route, design, lloq) {
  inputs <- sparse_inputs(d, route)
  profile <- mean_profile(inputs)
  log_linear <- suppressWarnings(PKNCA::pk.calc.half.life(conc = profile$mean, time = profile$time))
  tobit_mean <- suppressWarnings(PKNCA::pk.calc.half.life(conc = profile$mean, time = profile$time, lloq = lloq, hl_method = "tobit"))
  tobit_individual <- c(lambda.z = NA_real_, se = NA_real_, df = NA_real_)
  if (!is.na(log_linear$lambda.z)) {
    d_terminal <- d[d$time >= log_linear$lambda.z.time.first, ]
    tobit_individual <- fit_tobit_lambda_z(d_terminal, random = design == "batch", lloq = lloq)
  }
  list(
    inputs = inputs,
    log_linear = log_linear,
    lambda_z = c(
      "log-linear" = log_linear$lambda.z,
      "tobit-mean" = tobit_mean$lambda.z,
      "tobit-individual" = unname(tobit_individual[["lambda.z"]])
    ),
    tobit_individual = tobit_individual
  )
}

# The sparse AUCinf,obs and AUMCinf,obs (estimate, standard error, and degrees
# of freedom) with a given lambda.z; the delta method needs the log-linear
# half-life points
sparse_inf_with_lambda_z <- function(inputs, route, lambda_z, log_linear = NULL, lambda_z_se = "none") {
  if (!is.finite(lambda_z) || lambda_z <= 0) {
    return(list(auc = c(NA_real_, NA_real_, NA_real_), aumc = c(NA_real_, NA_real_, NA_real_)))
  }
  args <-
    c(
      inputs,
      list(
        lambda.z = lambda_z,
        lambda.z.time.first = if (is.null(log_linear)) NA_real_ else log_linear$lambda.z.time.first,
        lambda.z.time.last = if (is.null(log_linear)) NA_real_ else log_linear$lambda.z.time.last,
        lambda.z.n.points = if (is.null(log_linear)) NA_integer_ else log_linear$lambda.z.n.points,
        options = list(sparse_lambda_z_se = lambda_z_se)
      )
    )
  list(
    auc = unname(unlist(suppressWarnings(do.call(sparse_inf_functions[[route]]$auc, args)))),
    aumc = unname(unlist(suppressWarnings(do.call(sparse_inf_functions[[route]]$aumc, args))))
  )
}

# The point estimates of one data set for each lambda.z method:  the
# linear-trapezoidal AUCinf,obs and AUMCinf,obs of the mean profile, which
# equal the sparse estimates, without their standard errors (oral dosing; the
# IV bolus back-extrapolation needs the sparse functions)
point_estimates <- function(estimates, route) {
  ret <- matrix(NA_real_, 2, length(lambda_z_methods), dimnames = list(c("auc", "aumc"), lambda_z_methods))
  inputs <- estimates$inputs
  profile <- NULL
  for (current_method in lambda_z_methods) {
    lambda_z <- estimates$lambda_z[[current_method]]
    if (!is.finite(lambda_z) || lambda_z <= 0) {
      next
    }
    if (route == "oral") {
      if (is.null(profile)) {
        profile <- mean_profile(inputs)
        clast <- profile$mean[max(which(profile$mean > 0))]
      }
      args <- list(conc = profile$mean, time = profile$time, clast = clast, lambda.z = lambda_z, method = "linear")
      ret["auc", current_method] <- suppressWarnings(do.call(PKNCA::pk.calc.auc.inf.obs, args))
      ret["aumc", current_method] <- suppressWarnings(do.call(PKNCA::pk.calc.aumc.inf.obs, args))
    } else {
      result <- sparse_inf_with_lambda_z(inputs, route, lambda_z)
      ret[, current_method] <- c(result$auc[1], result$aumc[1])
    }
  }
  ret
}

# The intervals of one data set
run_tobit_replicate <- function(d, scenario_row, n, replicate, settings) {
  seed <- bootstrap_seed(settings$seed_base, scenario_row$scenario, replicate, settings$boot_seed_offset)
  lloq <- scenario_lloq(scenario_row)
  route <- scenario_row$route
  estimates <- lambda_z_estimates(d, route, scenario_row$design, lloq)
  truth <- c(auc = scenario_row$truth_auc, aumc = scenario_row$truth_aumc)
  out <- list()
  # The analytical intervals
  analytic <- list(
    "log-linear yuan" = sparse_inf_with_lambda_z(estimates$inputs, route, estimates$lambda_z[["log-linear"]], estimates$log_linear, "none"),
    "log-linear delta" = sparse_inf_with_lambda_z(estimates$inputs, route, estimates$lambda_z[["log-linear"]], estimates$log_linear, "delta"),
    "tobit-mean yuan" = sparse_inf_with_lambda_z(estimates$inputs, route, estimates$lambda_z[["tobit-mean"]])
  )
  individual <- sparse_inf_with_lambda_z(estimates$inputs, route, estimates$lambda_z[["tobit-individual"]])
  for (current_name in names(analytic)) {
    for (parameter in c("auc", "aumc")) {
      value <- analytic[[current_name]][[parameter]]
      quantile_t <- if (is.finite(value[3]) && value[3] > 0) stats::qt(0.975, value[3]) else stats::qnorm(0.975)
      out[[length(out) + 1]] <-
        data.frame(
          interval = current_name, parameter = parameter, estimate = value[1],
          lower = value[1] - quantile_t*value[2], upper = value[1] + quantile_t*value[2]
        )
    }
  }
  # Yuan's variance plus the variance of the individual-sample Tobit lambda.z
  lambda_z <- estimates$lambda_z[["tobit-individual"]]
  tobit <- estimates$tobit_individual
  if (is.finite(lambda_z) && lambda_z > 0) {
    profile <- mean_profile(estimates$inputs)
    idx_last <- max(which(profile$mean > 0))
    clast <- profile$mean[idx_last]
    tlast <- profile$time[idx_last]
    gradient <- c(auc = -clast/lambda_z^2, aumc = -tlast*clast/lambda_z^2 - 2*clast/lambda_z^3)
    for (parameter in c("auc", "aumc")) {
      value <- individual[[parameter]]
      v_yuan <- value[2]^2
      v_lambda_z <- gradient[[parameter]]^2*tobit[["se"]]^2
      df <- combine_df(v_yuan, value[3], v_lambda_z, tobit[["df"]])
      quantile_t <- if (is.finite(df) && df > 0) stats::qt(0.975, df) else stats::qnorm(0.975)
      se <- sqrt(v_yuan + v_lambda_z)
      out[[length(out) + 1]] <-
        data.frame(
          interval = "tobit-individual yuan+var", parameter = parameter, estimate = value[1],
          lower = value[1] - quantile_t*se, upper = value[1] + quantile_t*se
        )
    }
  }
  # The bootstrap percentile intervals for each lambda.z method
  boot_data <- bootstrap_datasets(d, settings$n_boot, seed)[-1]
  boot <- array(NA_real_, c(settings$n_boot, 2, length(lambda_z_methods)), dimnames = list(NULL, c("auc", "aumc"), lambda_z_methods))
  for (i in seq_along(boot_data)) {
    replicate_estimates <- lambda_z_estimates(boot_data[[i]], route, scenario_row$design, lloq)
    boot[i, , ] <- point_estimates(replicate_estimates, route)
  }
  original <- point_estimates(estimates, route)
  for (current_method in lambda_z_methods) {
    for (parameter in c("auc", "aumc")) {
      values <- boot[, parameter, current_method]
      values <- values[is.finite(values)]
      out[[length(out) + 1]] <-
        data.frame(
          interval = paste(current_method, "bootstrap"), parameter = parameter,
          estimate = original[parameter, current_method],
          lower = if (length(values) > 0) unname(stats::quantile(values, 0.025)) else NA_real_,
          upper = if (length(values) > 0) unname(stats::quantile(values, 0.975)) else NA_real_
        )
    }
  }
  ret <- do.call(rbind, out)
  ret$truth <- truth[ret$parameter]
  ret$scenario <- scenario_row$scenario
  ret$n_per_time <- n
  ret$replicate <- replicate
  ret
}

# The Tobit study on the data sets of one scenario and number of animals
run_tobit_study <- function(datasets, scenario_row, n, n_replicates, settings) {
  started <- Sys.time()
  data_list <- split_datasets(datasets, n_replicates)
  out <- vector("list", length(data_list))
  for (i in seq_along(data_list)) {
    out[[i]] <- run_tobit_replicate(data_list[[i]], scenario_row, n, as.integer(names(data_list)[i]), settings)
  }
  with_branch_seconds(do.call(rbind, out), started)
}

summarize_tobit <- function(results) {
  results <- results[is.finite(results$estimate) & is.finite(results$lower) & is.finite(results$upper), ]
  results$covered <- results$lower <= results$truth & results$truth <= results$upper
  key <- paste(results$scenario, results$n_per_time, results$interval, results$parameter)
  rows <- list()
  for (current_rows in split(seq_len(nrow(results)), factor(key, levels = unique(key)))) {
    r <- results[current_rows, ]
    relative_error <- (r$estimate - r$truth)/r$truth
    rows[[length(rows) + 1]] <-
      data.frame(
        scenario = r$scenario[1], n_per_time = r$n_per_time[1],
        interval = r$interval[1], lambda_z_method = sub(" .*$", "", r$interval[1]),
        parameter = r$parameter[1], n = nrow(r),
        coverage = 100*mean(r$covered),
        coverage_mcse = 100*sqrt(mean(r$covered)*(1 - mean(r$covered))/nrow(r)),
        median_ci_width = 100*stats::median((r$upper - r$lower)/r$truth),
        median_bias = 100*stats::median(relative_error),
        median_absolute_error = 100*stats::median(abs(relative_error))
      )
  }
  do.call(rbind, rows)
}
