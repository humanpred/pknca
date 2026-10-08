# Simulation-estimation study for the standard error of a sparse AUCinf,obs and
# AUMCinf,obs, used by vignette("v24-sparse-auc-to-infinity").
#
# Three standard errors are compared, all for the estimate AUClast + Clast/lambda.z
# (and its AUMC equivalent) from the arithmetic mean profile:
#
#   * "yuan":  lambda.z treated as known (Yuan 1993), sparse_lambda_z_se = "none"
#   * "delta":  the delta method for lambda.z from the log means,
#     sparse_lambda_z_se = "delta"
#   * "individual":  lambda.z and its standard error from a Tobit regression of
#     every individual sample from the start of the half-life range onward
#     (censored below the LLOQ), with a random intercept for each animal when
#     animals give more than one sample.  The extrapolation uses that lambda.z,
#     and its variance is added to the Yuan variance as though lambda.z were
#     independent of the means.
#
# The design (one- and two-compartment models, oral and IV bolus, serial and
# batch sampling) is in data-raw/sparse_simulation_design.R.  No animal is
# sampled at the dose:  for oral dosing, the concentration at time 0 is imputed
# as zero (as the start_conc0 imputation does in pk.nca()), and for IV bolus
# dosing, C0 is back-extrapolated from the mean profile by the sparse IV
# estimators (pk.calc.aucivinf.obs_sparse() and pk.calc.aumcivinf.obs_sparse()).
# The truth is the AUC (and AUMC) from 0 to infinity of the population mean
# concentration curve, which is what the arithmetic means estimate:  the mean
# of the individual values over a large virtual population.
#
# Run from the package root with the PKNCA version that has
# pk.calc.aucinf.obs_sparse() installed:
#
#   Rscript data-raw/sparse_aucinf_simulation.R
#
# It writes vignettes/v24-sparse-auc-to-infinity-simulation.rds.  Every replicate
# runs inside withr::with_seed() with its own seed, so the results do not depend
# on how the replicates are spread over cores.

library(PKNCA)

n_replicates <- as.integer(Sys.getenv("SIM_REPLICATES", "5000"))
seed_base <- 20261007
n_cores <- as.integer(Sys.getenv("SIM_CORES", "16"))

n_virtual <- as.integer(Sys.getenv("SIM_VIRTUAL", "100000"))

source("data-raw/sparse_simulation_design.R")

# The truth ####

# The AUC and AUMC from 0 to infinity of a block of virtual animals
animal_auc_aumc_block <- function(rows, animals, route) {
  ret <- matrix(NA_real_, length(rows), 2)
  for (i in seq_along(rows)) {
    ret[i, ] <- animal_inf_parameters(animals[rows[i], ], route)[c("aucinf", "aumcinf")]
  }
  ret
}

# The AUC and AUMC of the population mean curve, with the Monte Carlo standard
# error of each (in percent)
true_values <- function(scenario_row, seed) {
  route <- scenario_row$route
  animals <- withr::with_seed(seed, draw_animals(n_virtual, scenario_row))
  blocks <- split(seq_len(n_virtual), cut(seq_len(n_virtual), n_cores, labels = FALSE))
  values <-
    do.call(
      rbind,
      parallel::mclapply(blocks, animal_auc_aumc_block, animals = animals, route = route, mc.cores = n_cores)
    )
  truth <- colMeans(values)
  list(
    truth = c(auc = truth[[1]], aumc = truth[[2]]),
    mcse_percent = 100*apply(values, 2, stats::sd)/sqrt(n_virtual)/truth
  )
}

# Tobit regression for the individual-sample method ####

# Gauss-Hermite nodes and weights for integrating over a normal random effect
# (Golub-Welsch); integral of f(u) dnorm(u, 0, tau) = sum(w * f(sqrt(2) tau x))
gauss_hermite <- function(n) {
  off_diagonal <- sqrt(seq_len(n - 1)/2)
  jacobi <- matrix(0, n, n)
  jacobi[cbind(seq_len(n - 1), seq_len(n - 1) + 1)] <- off_diagonal
  jacobi[cbind(seq_len(n - 1) + 1, seq_len(n - 1))] <- off_diagonal
  e <- eigen(jacobi, symmetric = TRUE)
  list(nodes = e$values, weights = e$vectors[1, ]^2)
}
gh <- gauss_hermite(15)

# The log-likelihood of each observation:  the density above the LLOQ and the
# probability of being below it when censored
tobit_obs_ll <- function(mean, sigma, log_conc, censored, log_lloq) {
  ifelse(
    censored,
    stats::pnorm(log_lloq, mean, sigma, log.p = TRUE),
    stats::dnorm(log_conc, mean, sigma, log = TRUE)
  )
}

# log(sum(exp(x))) of each row, without overflow
log_sum_exp_rows <- function(x) {
  row_max <- apply(x, 1, max)
  row_max + log(rowSums(exp(x - row_max)))
}

# Negative log-likelihood of log(conc) = a - lambda.z time + u_subject + e, with
# e ~ N(0, sigma^2) censored below log(lloq) and u ~ N(0, tau^2) when random
tobit_nll <- function(par, log_conc, time, censored, log_lloq, subject, random) {
  mean_fixed <- par[1] - par[2]*time
  sigma <- exp(par[3])
  if (!random) {
    return(-sum(tobit_obs_ll(mean_fixed, sigma, log_conc, censored, log_lloq)))
  }
  tau <- exp(par[4])
  # The log-likelihood of each subject's observations at each quadrature node
  subject_index <- match(subject, unique(subject))
  node_ll <- matrix(NA_real_, max(subject_index), length(gh$nodes))
  for (q in seq_along(gh$nodes)) {
    obs_ll <- tobit_obs_ll(mean_fixed + sqrt(2)*tau*gh$nodes[q], sigma, log_conc, censored, log_lloq)
    node_ll[, q] <- rowsum(obs_ll, subject_index)[, 1] + log(gh$weights[q])
  }
  -sum(log_sum_exp_rows(node_ll))
}

# lambda.z and its standard error from the Tobit fit
fit_tobit_lambda_z <- function(d, random, lloq) {
  log_lloq <- if (lloq > 0) log(lloq) else -Inf
  above <- !d$blq
  if (sum(above) < 3) {
    return(c(lambda.z = NA_real_, se = NA_real_, df = NA_real_))
  }
  ols <- stats::lm(log(d$conc_reported[above]) ~ d$time[above])
  start <- c(unname(stats::coef(ols)[1]), -unname(stats::coef(ols)[2]), log(max(stats::sigma(ols), 0.05)))
  if (random) {
    start <- c(start, log(0.2))
  }
  args <-
    list(
      log_conc = ifelse(above, log(pmax(d$conc_reported, .Machine$double.xmin)), NA_real_),
      time = d$time, censored = d$blq, log_lloq = log_lloq, subject = d$subject, random = random
    )
  fit <-
    tryCatch(
      do.call(stats::optim, c(list(par = start, fn = tobit_nll, method = "BFGS", control = list(maxit = 500)), args)),
      error = function(e) NULL
    )
  if (is.null(fit) || fit$convergence != 0) {
    return(c(lambda.z = NA_real_, se = NA_real_, df = NA_real_))
  }
  hessian <- tryCatch(do.call(stats::optimHess, c(list(par = fit$par, fn = tobit_nll), args)), error = function(e) NULL)
  cov_par <- tryCatch(solve(hessian), error = function(e) NULL)
  se <- if (is.null(cov_par) || cov_par[2, 2] <= 0) NA_real_ else sqrt(cov_par[2, 2])
  n_par <- length(start)
  df <- if (random) length(unique(d$subject)) - 1 else nrow(d) - n_par
  c(lambda.z = fit$par[2], se = se, df = df)
}

# Estimation ####

# A t-interval with the Satterthwaite combination of two variance components
combine_df <- function(v1, df1, v2, df2) {
  (v1 + v2)^2/(v1^2/df1 + v2^2/df2)
}

# The sparse AUCinf,obs and AUMCinf,obs functions for the route, and their
# results as unnamed estimate, standard error, and degrees of freedom
sparse_inf_functions <- list(
  oral = list(auc = pk.calc.aucinf.obs_sparse, aumc = pk.calc.aumcinf.obs_sparse),
  iv = list(auc = pk.calc.aucivinf.obs_sparse, aumc = pk.calc.aumcivinf.obs_sparse)
)

estimate_replicate <- function(d, route, design, lloq, truth) {
  conc <- d$conc_reported
  time <- d$time
  subject <- d$subject
  if (route == "oral") {
    # The imputed zero at time 0 is known, so it has no subject
    conc <- c(0, conc)
    time <- c(0, time)
    subject <- c(NA, subject)
  }
  fun_auc <- sparse_inf_functions[[route]]$auc
  fun_aumc <- sparse_inf_functions[[route]]$aumc
  # The half-life of the arithmetic mean profile, as pk.nca() calculates it
  sparse_pk <- sparse_mean(as_sparse_pk(conc = conc, time = time, subject = subject))
  means <- vapply(sparse_pk, `[[`, "mean", FUN.VALUE = 1)
  times <- vapply(sparse_pk, `[[`, "time", FUN.VALUE = 1)
  hl <- suppressWarnings(pk.calc.half.life(conc = means, time = times))
  if (is.na(hl$lambda.z)) {
    return(NULL)
  }
  idx_last <- max(which(means > 0))
  tlast <- times[idx_last]
  clast <- means[idx_last]
  base_args <-
    list(
      conc = conc, time = time, subject = subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points
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
  ret$truth <- truth[ret$parameter]
  ret$percent_extrapolated <- 100*clast/hl$lambda.z/ret$estimate[ret$method == "yuan" & ret$parameter == "auc"]
  ret
}

run_replicate <- function(scenario_row, replicate) {
  withr::with_seed(seed_base + 100000*scenario_row$scenario + replicate, {
    lloq <- scenario_lloq(scenario_row)
    d <- simulate_data(scenario_row, lloq)
    truth <- c(auc = scenario_row$truth_auc, aumc = scenario_row$truth_aumc)
    ret <- estimate_replicate(d, scenario_row$route, scenario_row$design, lloq, truth)
    if (!is.null(ret)) {
      ret$replicate <- replicate
      ret$scenario <- scenario_row$scenario
      ret$blq_last_time <- mean(d$blq[d$time == max(d$time)])
    }
    ret
  })
}

# Summary ####

summarize_results <- function(results, scenarios) {
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

# One replicate of the job list
run_job <- function(i, jobs) {
  run_replicate(scenarios[jobs$scenario[i], ], jobs$replicate[i])
}

if (sys.nframe() == 0) {
  started <- Sys.time()
  # The truth depends on the route, elimination, and number of compartments
  truth_keys <- unique(scenarios[, c("route", "elimination", "compartments")])
  truth_mcse <- list()
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
    truth_mcse[[i]] <- data.frame(truth_keys[i, ], auc = tv$mcse_percent[1], aumc = tv$mcse_percent[2], row.names = NULL)
  }
  jobs <- expand.grid(scenario = scenarios$scenario, replicate = seq_len(n_replicates))
  results <-
    parallel::mclapply(
      seq_len(nrow(jobs)),
      run_job,
      jobs = jobs,
      mc.cores = n_cores,
      mc.preschedule = TRUE
    )
  failed <- vapply(results, inherits, "try-error", FUN.VALUE = TRUE)
  if (any(failed)) {
    stop("Replicates failed:  ", paste(unique(vapply(results[failed], as.character, "")), collapse = "; "))
  }
  results <- do.call(rbind, results)
  simulation <-
    list(
      summary = summarize_results(results, scenarios),
      scenarios = scenarios,
      model = model,
      model_1cmt = model_1cmt,
      model_2cmt = model_2cmt,
      sampling_times = sampling_times,
      batch_times = batch_times,
      n_serial = n_serial,
      n_batch = n_batch,
      n_replicates = n_replicates,
      n_virtual = n_virtual,
      truth_mcse_percent = do.call(rbind, truth_mcse),
      seed_base = seed_base,
      pknca_version = as.character(utils::packageVersion("PKNCA")),
      pmxtools_version = as.character(utils::packageVersion("pmxTools")),
      r_version = R.version.string,
      run_date = format(Sys.Date()),
      run_minutes = as.numeric(difftime(Sys.time(), started, units = "mins"))
    )
  saveRDS(simulation, "vignettes/v24-sparse-auc-to-infinity-simulation.rds")
  saveRDS(results, "data-raw/sparse_aucinf_simulation_replicates.rds")
  print(simulation$summary[, c("compartments", "route", "design", "blq", "elimination", "method", "parameter", "n", "relative_bias", "se_ratio", "coverage")], digits = 3)
}
