# The Tobit half-life compared with the log-linear half-life for the sparse
# AUCinf,obs and AUMCinf,obs with BLQ samples, used by
# vignette("v24-sparse-auc-to-infinity").
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
#     intercept for each animal in the batch design (fit_tobit_lambda_z() of
#     data-raw/sparse_aucinf_simulation.R)
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
# The bootstrap (sparse_bootstrap(), 200 replicates) recalculates the same
# lambda.z and estimate in every replicate.
#
# The data sets are those of the BLQ scenarios of
# data-raw/sparse_aucinf_simulation.R (the first SIM_TOBIT_SE_REPLICATES of
# each) and of the BLQ arm of data-raw/sparse_bootstrap_n_profile.R (the first
# SIM_TOBIT_PROFILE_REPLICATES at each number of animals per time).
#
#   Rscript data-raw/sparse_tobit_simulation.R
#
# writes vignettes/v24-sparse-auc-to-infinity-tobit.rds (the summary).

# The design, the truth, the data simulation, the Tobit fit to the individual
# samples, and the bootstrap settings
source("data-raw/sparse_bootstrap_n_profile.R")

n_tobit_se_replicates <- as.integer(Sys.getenv("SIM_TOBIT_SE_REPLICATES", "1000"))
n_tobit_profile_replicates <- as.integer(Sys.getenv("SIM_TOBIT_PROFILE_REPLICATES", "2000"))
lambda_z_methods <- c("log-linear", "tobit-mean", "tobit-individual")

# The pooled samples as the sparse estimators take them:  for oral dosing, the
# concentration at time 0 imputed as zero (known, so it has no subject)
sparse_inputs <- function(d, route) {
  if (route == "oral") {
    list(conc = c(0, d$conc_reported), time = c(0, d$time), subject = c(NA, d$subject))
  } else {
    list(conc = d$conc_reported, time = d$time, subject = d$subject)
  }
}

# The three estimates of lambda.z from one data set (or bootstrap replicate),
# with the log-linear half-life points and the standard error of the
# individual-sample Tobit fit.  `subject_col` names the animal identifier.
lambda_z_estimates <- function(d, route, design, lloq, subject_col) {
  # A bootstrap replicate identifies each draw of an animal separately
  d$subject <- d[[subject_col]]
  inputs <- sparse_inputs(d, route)
  sparse_pk <- sparse_mean(as_sparse_pk(conc = inputs$conc, time = inputs$time, subject = inputs$subject))
  means <- vapply(sparse_pk, `[[`, "mean", FUN.VALUE = 1)
  times <- vapply(sparse_pk, `[[`, "time", FUN.VALUE = 1)
  log_linear <- suppressWarnings(pk.calc.half.life(conc = means, time = times))
  tobit_mean <- suppressWarnings(pk.calc.half.life(conc = means, time = times, lloq = lloq, hl_method = "tobit"))
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

# The point estimates of one bootstrap replicate for each lambda.z method:
# the linear-trapezoidal AUCinf,obs and AUMCinf,obs of the replicate's mean
# profile, which equal the sparse estimates, without their standard errors
# (oral dosing; the IV bolus back-extrapolation needs the sparse functions)
point_estimates <- function(estimates, route) {
  ret <- matrix(NA_real_, 2, length(lambda_z_methods), dimnames = list(c("auc", "aumc"), lambda_z_methods))
  inputs <- estimates$inputs
  sparse_pk <- NULL
  for (current_method in lambda_z_methods) {
    lambda_z <- estimates$lambda_z[[current_method]]
    if (!is.finite(lambda_z) || lambda_z <= 0) {
      next
    }
    if (route == "oral") {
      if (is.null(sparse_pk)) {
        sparse_pk <- sparse_mean(as_sparse_pk(conc = inputs$conc, time = inputs$time, subject = inputs$subject))
        means <- vapply(sparse_pk, `[[`, "mean", FUN.VALUE = 1)
        times <- vapply(sparse_pk, `[[`, "time", FUN.VALUE = 1)
        clast <- means[max(which(means > 0))]
      }
      args <- list(conc = means, time = times, clast = clast, lambda.z = lambda_z, method = "linear")
      ret["auc", current_method] <- suppressWarnings(do.call(pk.calc.auc.inf.obs, args))
      ret["aumc", current_method] <- suppressWarnings(do.call(pk.calc.aumc.inf.obs, args))
    } else {
      result <- sparse_inf_with_lambda_z(inputs, route, lambda_z)
      ret[, current_method] <- c(result$auc[1], result$aumc[1])
    }
  }
  ret
}

# The intervals of one data set
run_tobit_replicate <- function(scenario_row, n, replicate) {
  # simulate_data() reads the number of animals per time from the global
  # environment, where the design was sourced
  assign("n_serial", n, envir = globalenv())
  assign("n_batch", n, envir = globalenv())
  seed <- seed_base + 100000*scenario_row$scenario + replicate
  lloq <- scenario_lloq(scenario_row)
  route <- scenario_row$route
  d <- withr::with_seed(seed, simulate_data(scenario_row, lloq))
  estimates <- lambda_z_estimates(d, route, scenario_row$design, lloq, subject_col = "subject")
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
    sparse_pk <- sparse_mean(as_sparse_pk(conc = estimates$inputs$conc, time = estimates$inputs$time, subject = estimates$inputs$subject))
    means <- vapply(sparse_pk, `[[`, "mean", FUN.VALUE = 1)
    times <- vapply(sparse_pk, `[[`, "time", FUN.VALUE = 1)
    idx_last <- max(which(means > 0))
    clast <- means[idx_last]
    tlast <- times[idx_last]
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
  o_boot <- sparse_bootstrap(PKNCAconc(d, conc_reported ~ time | subject, sparse = TRUE), n_boot = n_boot, seed = seed + boot_seed_offset)
  d_boot <- o_boot$data_sparse
  boot <- array(NA_real_, c(n_boot, 2, length(lambda_z_methods)), dimnames = list(NULL, c("auc", "aumc"), lambda_z_methods))
  for (i in seq_len(n_boot)) {
    rows <- d_boot$bootstrap == paste0("bootstrap", i)
    replicate_estimates <-
      lambda_z_estimates(d_boot[rows, ], route, scenario_row$design, lloq, subject_col = "bootstrap_subject")
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

run_tobit_job <- function(i, jobs, all_scenarios) {
  # mclapply() returns a try-error for a failed job
  run_tobit_replicate(all_scenarios[all_scenarios$scenario == jobs$scenario[i], ], jobs$n[i], jobs$replicate[i])
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

if (sys.nframe() == 0) {
  started <- Sys.time()
  # The truth of each route, elimination, and number of compartments, with
  # the seeds of data-raw/sparse_aucinf_simulation.R
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
  blq_scenarios <- scenarios$scenario[scenarios$blq == "moderate"]
  profile_scenario <- profile_scenarios$scenario[profile_scenarios$blq == "moderate"]
  # The profile's 4 animals per time is one of the SE study's scenarios, which
  # then has the profile's number of data sets
  jobs <-
    rbind(
      expand.grid(scenario = setdiff(blq_scenarios, profile_scenario), n = 4, replicate = seq_len(n_tobit_se_replicates)),
      expand.grid(scenario = profile_scenario, n = n_per_time, replicate = seq_len(n_tobit_profile_replicates))
    )
  results <-
    parallel::mclapply(
      seq_len(nrow(jobs)), run_tobit_job,
      jobs = jobs, all_scenarios = scenarios, mc.cores = n_cores, mc.preschedule = TRUE
    )
  failed <- vapply(results, inherits, "try-error", FUN.VALUE = TRUE)
  if (any(failed)) {
    stop("Replicates failed:  ", paste(unique(vapply(results[failed], as.character, "")), collapse = "; "))
  }
  results <- do.call(rbind, results)
  simulation <-
    list(
      summary = summarize_tobit(results),
      scenarios = scenarios,
      n_per_time = n_per_time,
      profile_scenario = profile_scenario,
      n_boot = n_boot,
      n_se_replicates = n_tobit_se_replicates,
      n_profile_replicates = n_tobit_profile_replicates,
      seed_base = seed_base,
      boot_seed_offset = boot_seed_offset,
      pknca_version = as.character(utils::packageVersion("PKNCA")),
      r_version = R.version.string,
      run_date = format(Sys.Date()),
      run_minutes = as.numeric(difftime(Sys.time(), started, units = "mins"))
    )
  saveRDS(simulation, "vignettes/v24-sparse-auc-to-infinity-tobit.rds")
  saveRDS(results, "data-raw/sparse_tobit_simulation_replicates.rds")
  print(simulation$summary[simulation$summary$parameter == "auc", c("scenario", "n_per_time", "interval", "n", "coverage", "median_bias")], digits = 3)
}
