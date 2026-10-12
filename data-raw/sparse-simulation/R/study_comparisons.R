# Published interval methods for the sparse AUC to infinity compared with
# PKNCA's on the same data sets:
#
#   * PKNCA:  Yuan's and the delta-method intervals (t with Satterthwaite
#     degrees of freedom); the sparse_bootstrap() percentile interval (AUC,
#     AUMC, and MRT); and a bootstrap-t interval on the delta-method standard
#     error, the construction of Wolfsegger and Jaki (2005) applied to PKNCA's
#     estimator:  the pivot (estimate* - estimate)/se* of the replicates gives
#     the interval estimate - q(0.975) se to estimate - q(0.025) se.
#   * The PK package (nca(), Wolfsegger and Jaki 2009 for serial sacrifice and
#     Jaki and Wolfsegger 2012 for batch designs):  its asymptotic ("z") and
#     bootstrap-t intervals for the AUC and AUMC to infinity, MRT,
#     non-compartmental half-life (log(2) MRT), clearance, and Vss, with
#     lambda.z from the log means of the last n.tail = 3 times.
#   * Wolfsegger and Jaki (2005), serial sacrifice only (wj2005_intervals()).
#
# PK and the 2005 estimator start the AUC at the first time given.  For oral
# dosing, the known zero at time 0 is given to each (as PKNCA imputes it); for
# IV bolus dosing neither back-extrapolates C0, so their AUC starts at the
# first sample.

# PKNCA's estimates with the delta-method standard error from the
# replicate's own half-life, for the bootstrap-t pivot:  AUC and AUMC estimate
# and standard error, and the MRT
pknca_delta_estimates <- function(d, route) {
  inputs <- sparse_inputs(d, route)
  profile <- mean_profile(inputs)
  hl <- suppressWarnings(PKNCA::pk.calc.half.life(conc = profile$mean, time = profile$time))
  ret <- c(auc = NA_real_, auc_se = NA_real_, aumc = NA_real_, aumc_se = NA_real_, mrt = NA_real_)
  if (is.na(hl$lambda.z)) {
    return(ret)
  }
  args <-
    c(
      inputs,
      list(
        lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
        lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
        options = list(sparse_lambda_z_se = "delta")
      )
    )
  auc <- unlist(suppressWarnings(do.call(sparse_inf_functions[[route]]$auc, args)))
  aumc <- unlist(suppressWarnings(do.call(sparse_inf_functions[[route]]$aumc, args)))
  ret[] <- c(auc[[1]], auc[[2]], aumc[[1]], aumc[[2]], aumc[[1]]/auc[[1]])
  ret
}

# The bootstrap intervals of PKNCA's estimates for one data set:  percentile
# (AUC, AUMC, MRT) and bootstrap-t on the delta-method standard error (AUC,
# AUMC).  The bootstrap seed is that of the bootstrap study, so the percentile
# intervals of the AUC and AUMC are the same as there.
pknca_bootstrap_intervals <- function(d, route, n_boot, seed) {
  boot_data <- bootstrap_datasets(d, n_boot, seed)
  estimates <- matrix(NA_real_, length(boot_data), 5, dimnames = list(NULL, c("auc", "auc_se", "aumc", "aumc_se", "mrt")))
  for (i in seq_along(boot_data)) {
    estimates[i, ] <- pknca_delta_estimates(boot_data[[i]], route)
  }
  original <- estimates[1, ]
  boot <- estimates[-1, , drop = FALSE]
  out <- list()
  for (parameter in c("auc", "aumc", "mrt")) {
    values <- boot[, parameter]
    values <- values[is.finite(values)]
    out[[length(out) + 1]] <-
      data.frame(
        interval = "pknca percentile", parameter = parameter, estimate = original[[parameter]],
        se = if (length(values) > 1) stats::sd(values) else NA_real_,
        lower = if (length(values) > 0) unname(stats::quantile(values, 0.025)) else NA_real_,
        upper = if (length(values) > 0) unname(stats::quantile(values, 0.975)) else NA_real_,
        n_valid_bootstrap = length(values)
      )
  }
  for (parameter in c("auc", "aumc")) {
    se_name <- paste0(parameter, "_se")
    pivot <- (boot[, parameter] - original[[parameter]])/boot[, se_name]
    pivot <- pivot[is.finite(pivot)]
    quantiles <-
      if (is.finite(original[[parameter]]) && is.finite(original[[se_name]]) && length(pivot) > 0) {
        stats::quantile(pivot, c(0.025, 0.975), type = 5, names = FALSE)
      } else {
        c(NA_real_, NA_real_)
      }
    out[[length(out) + 1]] <-
      data.frame(
        interval = "pknca boot-t", parameter = parameter, estimate = original[[parameter]],
        se = original[[se_name]],
        lower = original[[parameter]] - quantiles[2]*original[[se_name]],
        upper = original[[parameter]] - quantiles[1]*original[[se_name]],
        n_valid_bootstrap = length(pivot)
      )
  }
  do.call(rbind, out)
}

# Yuan's and the delta-method intervals of one data set
pknca_analytic_intervals <- function(d, route) {
  analytic <- estimate_inf_se(d, route)
  if (is.null(analytic)) {
    return(NULL)
  }
  quantile_t <- ifelse(is.finite(analytic$df) & analytic$df > 0, stats::qt(0.975, analytic$df), stats::qnorm(0.975))
  data.frame(
    interval = paste("pknca", analytic$method), parameter = analytic$parameter,
    estimate = analytic$estimate, se = analytic$se,
    lower = analytic$estimate - quantile_t*analytic$se,
    upper = analytic$estimate + quantile_t*analytic$se,
    n_valid_bootstrap = NA_integer_
  )
}

pk_parameter_names <-
  c(
    "AUC to infinity" = "auc", "AUMC to infinity" = "aumc", "Mean residence time" = "mrt",
    "non-compartmental half-life" = "half_life_nc", "Clearance" = "cl",
    "Volume of distribution at steady state" = "vss"
  )

# The PK package's nca() on one data set, or NULL if it stops with an error.
# Its bootstrap draws from R's random number generator, so it runs under
# `seed`.
pk_nca <- function(d_pk, design, nsample, seed) {
  tryCatch(
    withr::with_seed(seed, {
      if (design == "ssd") {
        PK::nca(conc = d_pk$conc, time = d_pk$time, n.tail = 3, dose = model$dose, method = c("z", "boott"), nsample = nsample, design = design)
      } else {
        PK::nca(data = d_pk, n.tail = 3, dose = model$dose, method = c("z", "boott"), nsample = nsample, design = design)
      }
    }),
    error = function(e) NULL
  )
}

# The PK package's intervals of one data set, with the dose for the clearance
# and Vss.  BLQ samples are given as 0, as PKNCA takes them; PK's batch-design
# function stops with an error when some but not all of a time's samples are
# 0, and then the BLQ samples are omitted instead (`n_fallback` is 1).
pk_intervals <- function(d, scenario_row, nsample, seed) {
  design <- if (scenario_row$design == "serial") "ssd" else "batch"
  d_pk <- data.frame(id = d$subject, conc = d$conc_reported, time = d$time)
  if (scenario_row$route == "oral") {
    # The known zero at time 0:  one per animal at each time (serial) or one
    # per animal (batch), so the number of animals per time is unchanged
    zero_ids <- if (design == "ssd") -seq_len(sum(d$time == d$time[1])) else unique(d$subject)
    d_zero <- data.frame(id = zero_ids, conc = 0, time = 0)
  } else {
    d_zero <- d_pk[0, ]
  }
  n_fallback <- 0L
  result <- pk_nca(rbind(d_zero, d_pk), design, nsample, seed)
  if (is.null(result) && any(d$blq)) {
    n_fallback <- 1L
    result <- pk_nca(rbind(d_zero, d_pk[!d$blq, ]), design, nsample, seed)
  }
  if (is.null(result)) {
    return(
      data.frame(
        interval = rep(c("pk z", "pk boot-t"), each = length(pk_parameter_names)),
        parameter = rep(unname(pk_parameter_names), 2),
        estimate = NA_real_, se = NA_real_, lower = NA_real_, upper = NA_real_, n_valid_bootstrap = NA_integer_,
        n_fallback = n_fallback
      )
    )
  }
  cis <- result$CIs
  parameter_label <- sub("^.*% CI for the (.*) using a .*$", "\\1", rownames(cis))
  keep <- parameter_label %in% names(pk_parameter_names)
  data.frame(
    interval = ifelse(cis$method[keep] == "z", "pk z", "pk boot-t"),
    parameter = unname(pk_parameter_names[parameter_label[keep]]),
    estimate = cis$est[keep], se = cis$stderr[keep],
    lower = cis$lower[keep], upper = cis$upper[keep],
    n_valid_bootstrap = NA_integer_,
    n_fallback = n_fallback
  )
}

# The true values of every parameter of the comparisons:  the AUC and AUMC
# of the population mean curve and the functions of them that the
# estimators estimate (the MRT is the mean transit time after oral dosing)
comparison_truth <- function(scenario_row) {
  auc <- scenario_row$truth_auc
  aumc <- scenario_row$truth_aumc
  c(
    auc = auc, aumc = aumc, mrt = aumc/auc, half_life_nc = log(2)*aumc/auc,
    cl = model$dose/auc, vss = model$dose*aumc/auc^2
  )
}

# Every interval of one data set.  `include` names the method families to run:
# "pknca", "pk", and "wj2005".
comparison_intervals <- function(d, scenario_row, replicate, settings, include) {
  route <- scenario_row$route
  seed <- bootstrap_seed(settings$seed_base, scenario_row$scenario, replicate, settings$boot_seed_offset)
  out <- list()
  if ("pknca" %in% include) {
    out[["analytic"]] <- pknca_analytic_intervals(d, route)
    out[["bootstrap"]] <- pknca_bootstrap_intervals(d, route, settings$n_boot, seed)
  }
  if ("pk" %in% include) {
    out[["pk"]] <- pk_intervals(d, scenario_row, settings$pk_nsample, seed - settings$boot_seed_offset + settings$pk_seed_offset)
  }
  if ("wj2005" %in% include && scenario_row$design == "serial") {
    out[["wj2005"]] <-
      wj2005_intervals(
        d, n_tail = 3, zero_first = route == "oral", n_bootstrap = settings$wj_nsample,
        seed = seed - settings$boot_seed_offset + settings$wj_seed_offset
      )
  }
  for (current in setdiff(names(out), "pk")) {
    out[[current]]$n_fallback <- 0L
  }
  ret <- do.call(rbind, out)
  ret$truth <- comparison_truth(scenario_row)[ret$parameter]
  ret
}

# The comparison study on the data sets of one scenario and number of animals
run_comparison_study <- function(datasets, scenario_row, n, n_replicates, settings, include) {
  started <- Sys.time()
  data_list <- split_datasets(datasets, n_replicates)
  out <- vector("list", length(data_list))
  for (i in seq_along(data_list)) {
    replicate <- as.integer(names(data_list)[i])
    ret <- comparison_intervals(data_list[[i]], scenario_row, replicate, settings, include)
    ret$replicate <- replicate
    out[[i]] <- ret
  }
  ret <- do.call(rbind, out)
  ret$scenario <- scenario_row$scenario
  ret$n_per_time <- n
  with_branch_seconds(ret, started)
}

# Coverage, width, and bias of every interval.  A data set whose interval
# could not be calculated counts in `n_attempted` but not in `n`;
# `coverage_attempted` counts it as a miss.
summarize_intervals <- function(results, scenarios) {
  results$finite <- is.finite(results$estimate) & is.finite(results$lower) & is.finite(results$upper)
  results$covered <- results$finite & results$lower <= results$truth & results$truth <= results$upper
  key <- paste(results$scenario, results$n_per_time, results$interval, results$parameter)
  rows <- list()
  for (current_rows in split(seq_len(nrow(results)), factor(key, levels = unique(key)))) {
    r <- results[current_rows, ]
    ok <- r$finite
    relative_error <- (r$estimate[ok] - r$truth[ok])/r$truth[ok]
    coverage <- mean(r$covered[ok])
    rows[[length(rows) + 1]] <-
      data.frame(
        scenario = r$scenario[1], n_per_time = r$n_per_time[1],
        interval = r$interval[1], parameter = r$parameter[1],
        n_attempted = nrow(r), n = sum(ok),
        truth = r$truth[1],
        coverage = 100*coverage,
        coverage_mcse = 100*sqrt(coverage*(1 - coverage)/sum(ok)),
        coverage_attempted = 100*mean(r$covered),
        # Misses with the whole interval below or above the truth
        miss_low = 100*mean(r$upper[ok] < r$truth[ok]),
        miss_high = 100*mean(r$lower[ok] > r$truth[ok]),
        median_ci_width = 100*stats::median((r$upper[ok] - r$lower[ok])/r$truth[ok]),
        relative_bias = 100*mean(relative_error),
        median_bias = 100*stats::median(relative_error),
        median_absolute_error = 100*stats::median(abs(relative_error)),
        # Data sets that needed a method's fallback (see pk_intervals() and
        # the BLQ study)
        percent_fallback = 100*mean(r$n_fallback > 0)
      )
  }
  merge(scenarios, do.call(rbind, rows), by = "scenario")
}
