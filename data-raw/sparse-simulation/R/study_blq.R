# Treatments of BLQ samples in the sparse AUC to infinity, after Barnett,
# Geys, Jacobs, and Jaki (2021) and their BLOQ package, against PKNCA's
# substitution of zero.
#
# BLOQ works on complete designs (a subject-by-time matrix) and gives the AUC
# to the last time.  Its per-time methods need nothing from other times, so
# they are applied here to the samples at each time of a sparse data set, and
# the imputed data set goes through PKNCA's sparse AUC to infinity with the
# delta-method standard error:
#
#   * "zero":  BLQ as 0 (PKNCA's default, with its rule that a time with more
#     than half of its samples BLQ has a mean of 0)
#   * "half_lloq":  BLQ as LLOQ/2 (BLOQ::imputeConstant(); Method 2)
#   * "ros":  regression on order statistics on the log scale
#     (BLOQ::imputeROS(); Method 3)
#   * "kernel":  kernel density imputation
#     (BLOQ::imputeKernelDensityEstimation(); Method 7, which Barnett et al.
#     recommend)
#   * "cml_impute":  censored maximum likelihood at each time, then the
#     expected order statistics below the LLOQ (BLOQ::imputeCML(); Method 5,
#     the two-step approach)
#   * "cml_direct":  the censored maximum likelihood mean of each time and its
#     variance from the information matrix
#     (BLOQ::estimateAUCwithCMLperTimePoint(); Method 4, the direct approach),
#     with the AUC to infinity and its delta-method variance from those means
#     with the times independent
#
# The likelihood methods use BLOQ's additive (normal) model:  BLOQ 0.1-2 fits
# its multiplicative model to log10 concentrations and back-transforms with
# exp(), which does not return the fitted mean.  ROS uses natural logarithms
# throughout, so its multiplicative version is used (the additive one can
# impute negative concentrations).
#
# BLOQ's own rule (imputeBLOQ()) falls back to LLOQ/2 at a time where every
# sample is BLQ; ROS and the likelihood methods also need at least two
# measured samples at the time, and fall back to LLOQ/2 otherwise.  In batch
# designs, the imputed values at a time go to its BLQ animals in the order of
# their concentrations at their batch's previous time (Barnett et al.,
# section 4); in serial designs, the order does not matter.

blq_methods <- c("zero", "half_lloq", "ros", "kernel", "cml_impute", "cml_direct")

# The imputed values at one time:  the BLQ samples of `x` (BLQ samples as 0)
# replaced, with whether the method fell back to LLOQ/2
impute_time <- function(x, blq, lloq, method, use_seed) {
  n_measured <- sum(!blq)
  minimum_measured <- c(half_lloq = 0, ros = 2, kernel = 1, cml_impute = 2)[[method]]
  if (method == "half_lloq" || n_measured < max(1, minimum_measured)) {
    x[blq] <- lloq/2
    return(list(x = x, fallback = method != "half_lloq"))
  }
  column <- matrix(x, ncol = 1)
  imputed <-
    tryCatch(
      switch(
        method,
        ros = BLOQ::imputeROS(column, LOQ = lloq, isMultiplicative = TRUE, useSeed = use_seed),
        kernel = BLOQ::imputeKernelDensityEstimation(column, LOQ = lloq, useSeed = use_seed),
        cml_impute = BLOQ::imputeCML(column, LOQ = lloq, isMultiplicative = FALSE, useSeed = use_seed, printCMLmessage = FALSE)
      ),
      error = function(e) NULL
    )
  if (is.null(imputed) || any(!is.finite(imputed[blq, 1]))) {
    x[blq] <- lloq/2
    return(list(x = x, fallback = TRUE))
  }
  list(x = imputed[, 1], fallback = FALSE)
}

# One data set with its BLQ samples imputed by `method`, with the number of
# times that fell back to LLOQ/2 and the number of negative imputed values
impute_dataset <- function(d, lloq, method, design, seed) {
  n_fallback <- 0
  if (method == "zero" || !any(d$blq)) {
    return(list(d = d, n_fallback = n_fallback, n_negative = 0))
  }
  times <- sort(unique(d$time[d$blq]))
  withr::with_seed(seed, {
    for (j in seq_along(times)) {
      rows <- which(d$time == times[j])
      result <- impute_time(d$conc_reported[rows], d$blq[rows], lloq, method, use_seed = j)
      n_fallback <- n_fallback + result$fallback
      values <- result$x
      blq_rows <- rows[d$blq[rows]]
      if (design == "batch" && length(blq_rows) > 1) {
        values[d$blq[rows]] <- impute_order_batch(d, blq_rows, sort(values[d$blq[rows]]))
      }
      d$conc_reported[rows] <- values
    }
  })
  list(d = d, n_fallback = n_fallback, n_negative = sum(d$conc_reported[d$blq] < 0))
}

# Imputed values (sorted) assigned to the BLQ rows of a batch design in the
# order of each animal's concentration at its previous sampled time
impute_order_batch <- function(d, blq_rows, sorted_values) {
  previous <- numeric(length(blq_rows))
  for (i in seq_along(blq_rows)) {
    animal_rows <- which(d$subject == d$subject[blq_rows[i]] & d$time < d$time[blq_rows[i]])
    previous[i] <- if (length(animal_rows) > 0) d$conc_reported[animal_rows[which.max(d$time[animal_rows])]] else 0
  }
  sorted_values[rank(previous, ties.method = "first")]
}

# The censored maximum likelihood mean of each time and its variance (Method
# 4); a time without BLQ samples has the sample mean and its variance
cml_direct_means <- function(d, lloq) {
  times <- sort(unique(d$time))
  ret <- data.frame(time = times, mean = NA_real_, variance = NA_real_, fallback = FALSE)
  for (j in seq_along(times)) {
    x <- d$conc_reported[d$time == times[j]]
    blq <- d$blq[d$time == times[j]]
    fit <- NULL
    if (any(blq) && sum(!blq) >= 2) {
      fit <-
        tryCatch(
          BLOQ::estimateAUCwithCMLperTimePoint(matrix(x, ncol = 1), LOQ = lloq, timePoints = 0, isMultiplicative = FALSE, onlyFitCML = TRUE, printCMLmessage = FALSE),
          error = function(e) NULL
        )
    }
    if (!is.null(fit)) {
      ret$mean[j] <- fit$estCML[1, "mean"]
      ret$variance[j] <- tryCatch(stats::vcov(fit$CML[[1]])[1, 1], error = function(e) NA_real_)
    }
    if (is.null(fit) || !is.finite(ret$mean[j]) || !is.finite(ret$variance[j]) || ret$variance[j] <= 0) {
      ret$fallback[j] <- any(blq)
      x[blq] <- lloq/2
      ret$mean[j] <- mean(x)
      ret$variance[j] <- stats::var(x)/length(x)
    }
  }
  ret
}

# The AUC to infinity of a mean profile with lambda.z from the log means of
# the half-life points `hl_points` and, for IV bolus, C0 back-extrapolated from
# the first two means as PKNCA does
auc_inf_of_means <- function(means, times, hl_points, iv_bolus) {
  if (iv_bolus) {
    c0 <- if (means[1] > means[2] && means[2] > 0) means[1]*(means[1]/means[2])^(times[1]/(times[2] - times[1])) else means[1]
    means <- c(c0, means)
    times <- c(0, times)
    hl_points <- hl_points + 1
  }
  slope_weights <- (times[hl_points] - mean(times[hl_points]))/sum((times[hl_points] - mean(times[hl_points]))^2)
  lambda_z <- -sum(slope_weights*log(means[hl_points]))
  n <- length(times)
  sum(diff(times)*(means[-1] + means[-n])/2) + means[n]/lambda_z
}

# Method 4's AUC to infinity with its delta-method standard error (numerical
# gradient; the times are independent)
cml_direct_interval <- function(d, lloq, route) {
  means <- cml_direct_means(d, lloq)
  if (route == "oral") {
    means <- rbind(data.frame(time = 0, mean = 0, variance = 0, fallback = FALSE), means)
  }
  hl <- suppressWarnings(PKNCA::pk.calc.half.life(conc = means$mean, time = means$time))
  fallback <- sum(means$fallback)
  if (is.na(hl$lambda.z) || any(means$mean[means$time > 0] <= 0)) {
    return(data.frame(estimate = NA_real_, se = NA_real_, n_fallback = fallback))
  }
  hl_points <- which(means$time >= hl$lambda.z.time.first & means$time <= hl$lambda.z.time.last)
  iv_bolus <- route == "iv"
  estimate <- auc_inf_of_means(means$mean, means$time, hl_points, iv_bolus)
  gradient <- numeric(nrow(means))
  for (j in which(means$variance > 0)) {
    step <- 1e-6*means$mean[j]
    up <- means$mean
    down <- means$mean
    up[j] <- up[j] + step
    down[j] <- down[j] - step
    gradient[j] <- (auc_inf_of_means(up, means$time, hl_points, iv_bolus) - auc_inf_of_means(down, means$time, hl_points, iv_bolus))/(2*step)
  }
  data.frame(estimate = estimate, se = sqrt(sum(gradient^2*means$variance)), n_fallback = fallback)
}

# The AUC to infinity intervals of one data set for every BLQ method
blq_intervals <- function(d, scenario_row, replicate, settings) {
  route <- scenario_row$route
  lloq <- scenario_lloq(scenario_row)
  seed <- data_seed(settings$seed_base, scenario_row$scenario, replicate) + settings$blq_seed_offset
  out <- list()
  for (method in setdiff(blq_methods, "cml_direct")) {
    imputed <- impute_dataset(d, lloq, method, scenario_row$design, seed)
    analytic <- pknca_analytic_intervals(imputed$d, route)
    delta <- if (is.null(analytic)) NULL else analytic[analytic$interval == "pknca delta" & analytic$parameter == "auc", ]
    if (is.null(delta) || nrow(delta) == 0) {
      delta <- data.frame(estimate = NA_real_, se = NA_real_, lower = NA_real_, upper = NA_real_)
    }
    out[[method]] <-
      data.frame(
        interval = paste(method, "delta"), parameter = "auc",
        estimate = delta$estimate, se = delta$se, lower = delta$lower, upper = delta$upper,
        n_fallback = imputed$n_fallback, n_negative = imputed$n_negative
      )
  }
  direct <- withr::with_seed(seed, cml_direct_interval(d, lloq, route))
  z <- stats::qnorm(0.975)
  out[["cml_direct"]] <-
    data.frame(
      interval = "cml_direct z", parameter = "auc",
      estimate = direct$estimate, se = direct$se,
      lower = direct$estimate - z*direct$se, upper = direct$estimate + z*direct$se,
      n_fallback = direct$n_fallback, n_negative = 0
    )
  ret <- do.call(rbind, out)
  ret$truth <- scenario_row$truth_auc
  ret$n_blq <- sum(d$blq)
  ret
}

# The BLQ study on the data sets of one scenario
run_blq_study <- function(datasets, scenario_row, settings) {
  started <- Sys.time()
  data_list <- split_datasets(datasets, settings$n_blq_replicates)
  out <- vector("list", length(data_list))
  for (i in seq_along(data_list)) {
    replicate <- as.integer(names(data_list)[i])
    ret <- blq_intervals(data_list[[i]], scenario_row, replicate, settings)
    ret$replicate <- replicate
    out[[i]] <- ret
  }
  ret <- do.call(rbind, out)
  ret$scenario <- scenario_row$scenario
  ret$n_per_time <- n_serial
  with_branch_seconds(ret, started)
}

# How often each method fell back to LLOQ/2 or imputed negative values
summarize_blq_fallbacks <- function(results) {
  key <- paste(results$scenario, results$interval)
  rows <- list()
  for (current_rows in split(seq_len(nrow(results)), factor(key, levels = unique(key)))) {
    r <- results[current_rows, ]
    rows[[length(rows) + 1]] <-
      data.frame(
        scenario = r$scenario[1], interval = r$interval[1], n = nrow(r),
        mean_blq_samples = mean(r$n_blq),
        percent_with_fallback = 100*mean(r$n_fallback > 0),
        percent_with_negative = 100*mean(r$n_negative > 0)
      )
  }
  do.call(rbind, rows)
}
