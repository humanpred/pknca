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
# The truth is the AUC (and AUMC) of the population mean concentration curve,
# which is what the arithmetic means estimate; it has a closed form for the
# one-compartment model below.  Concentrations come from pmxTools.
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
n_cores <- as.integer(Sys.getenv("SIM_CORES", "12"))

# Model and scenarios ####

# One-compartment model with first-order absorption; dose 100, typical ka 1.5/hr
# and V 10, with log-normal variability (omega) on ka, ke, and V and a
# multiplicative residual error with mean 1
model <- list(dose = 100, ka = 1.5, v = 10, omega_ka = 0.3, omega_ke = 0.3, omega_v = 0.3, sigma = 0.15)

scenarios <-
  expand.grid(
    design = c("serial", "batch"),
    blq = c("none", "moderate"),
    elimination = c("fast", "slow"),
    stringsAsFactors = FALSE
  )
scenarios$scenario <- seq_len(nrow(scenarios))
# Fast elimination leaves a small extrapolated area and slow a large one
scenarios$ke <- ifelse(scenarios$elimination == "fast", 0.15, 0.07)

sample_times <- c(0.25, 0.5, 1, 2, 4, 6, 8, 12, 24)
# Batch design:  three batches of four animals, each sampled at three times
batch_times <- list(c(0.25, 2, 8), c(0.5, 4, 12), c(1, 6, 24))
n_serial <- 4

# The concentration of one animal at the given times (pmxTools takes scalar
# parameters)
conc_1cmt <- function(time, dose, ka, ke, v) {
  pmxTools::calc_sd_1cmt_linear_oral_1(t = time, CL = ke*v, V = v, ka = ka, dose = dose)
}

# E[X^p] for log-normal X with median m and log-scale standard deviation omega
lnorm_moment <- function(m, omega, p) {
  exp(p*log(m) + p^2*omega^2/2)
}

# The AUC and AUMC to infinity of the population mean curve:  the means of the
# individual AUC = dose/(V ke) and AUMC = dose/(V ke) (1/ke + 1/ka)
true_values <- function(ke) {
  inv_v <- lnorm_moment(model$v, model$omega_v, -1)
  c(
    auc = model$dose*inv_v*lnorm_moment(ke, model$omega_ke, -1),
    aumc =
      model$dose*inv_v*(
        lnorm_moment(ke, model$omega_ke, -2) +
          lnorm_moment(ke, model$omega_ke, -1)*lnorm_moment(model$ka, model$omega_ka, -1)
      )
  )
}

# The LLOQ for moderate BLQ:  70% of the median concentration at the last time,
# which leaves about a third of those samples BLQ
scenario_lloq <- function(blq, ke) {
  if (blq == "none") {
    return(0)
  }
  0.7*conc_1cmt(24, model$dose, model$ka, ke, model$v)
}

simulate_data <- function(design, ke, lloq) {
  sampling <-
    if (design == "serial") {
      data.frame(
        subject = seq_len(length(sample_times)*n_serial),
        time = rep(sample_times, each = n_serial)
      )
    } else {
      batches <- list()
      for (b in seq_along(batch_times)) {
        batches[[b]] <- expand.grid(subject = (b - 1)*4 + 1:4, time = batch_times[[b]])
      }
      do.call(rbind, batches)
    }
  subjects <- sort(unique(sampling$subject))
  eta <-
    data.frame(
      subject = subjects,
      ka = model$ka*exp(stats::rnorm(length(subjects), sd = model$omega_ka)),
      ke = ke*exp(stats::rnorm(length(subjects), sd = model$omega_ke)),
      v = model$v*exp(stats::rnorm(length(subjects), sd = model$omega_v))
    )
  d <- merge(sampling, eta, by = "subject")
  d$conc <- NA_real_
  for (i in seq_len(nrow(d))) {
    d$conc[i] <- conc_1cmt(d$time[i], model$dose, d$ka[i], d$ke[i], d$v[i])
  }
  d$conc <- d$conc*exp(stats::rnorm(nrow(d), mean = -model$sigma^2/2, sd = model$sigma))
  d$blq <- d$conc < lloq
  d$conc_reported <- ifelse(d$blq, 0, d$conc)
  d[order(d$time, d$subject), c("subject", "time", "conc_reported", "blq")]
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
  subjects <- unique(subject)
  node_ll <- matrix(NA_real_, length(subjects), length(gh$nodes))
  for (q in seq_along(gh$nodes)) {
    obs_ll <- tobit_obs_ll(mean_fixed + sqrt(2)*tau*gh$nodes[q], sigma, log_conc, censored, log_lloq)
    node_ll[, q] <- tapply(obs_ll, factor(subject, levels = subjects), sum) + log(gh$weights[q])
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

estimate_replicate <- function(d, design, lloq, truth) {
  conc <- d$conc_reported
  # The half-life of the arithmetic mean profile, as pk.nca() calculates it
  sparse_pk <- sparse_mean(as_sparse_pk(conc = conc, time = d$time, subject = d$subject))
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
      conc = conc, time = d$time, subject = d$subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points
    )
  out <- list()
  for (method in c("none", "delta")) {
    args <- c(base_args, list(options = list(sparse_lambda_z_se = method)))
    auc <- suppressWarnings(do.call(pk.calc.aucinf.obs_sparse, args))
    aumc <- suppressWarnings(do.call(pk.calc.aumcinf.obs_sparse, args))
    label <- if (method == "none") "yuan" else "delta"
    out[[length(out) + 1]] <-
      data.frame(
        method = label, parameter = c("auc", "aumc"),
        estimate = c(auc$aucinf.obs, aumc$aumcinf.obs),
        se = c(auc$aucinf.obs_se, aumc$aumcinf.obs_se),
        df = c(auc$aucinf.obs_df, aumc$aumcinf.obs_df)
      )
  }
  # Individual samples from the start of the half-life range onward
  d_terminal <- d[d$time >= hl$lambda.z.time.first, ]
  tobit <- fit_tobit_lambda_z(d_terminal, random = design == "batch", lloq = lloq)
  if (!is.na(tobit[["lambda.z"]]) && tobit[["lambda.z"]] > 0) {
    lambda_z <- tobit[["lambda.z"]]
    # The Yuan part with the Tobit lambda.z, and the added lambda.z variance
    args <- base_args
    args$lambda.z <- lambda_z
    auc <- do.call(pk.calc.aucinf.obs_sparse, args)
    aumc <- do.call(pk.calc.aumcinf.obs_sparse, args)
    d_auc_d_lambda_z <- -clast/lambda_z^2
    d_aumc_d_lambda_z <- -tlast*clast/lambda_z^2 - 2*clast/lambda_z^3
    var_lambda_z <- tobit[["se"]]^2
    v_auc <- auc$aucinf.obs_se^2
    v_aumc <- aumc$aumcinf.obs_se^2
    v_lz_auc <- d_auc_d_lambda_z^2*var_lambda_z
    v_lz_aumc <- d_aumc_d_lambda_z^2*var_lambda_z
    out[[length(out) + 1]] <-
      data.frame(
        method = "individual", parameter = c("auc", "aumc"),
        estimate = c(auc$aucinf.obs, aumc$aumcinf.obs),
        se = sqrt(c(v_auc + v_lz_auc, v_aumc + v_lz_aumc)),
        df =
          c(
            combine_df(v_auc, auc$aucinf.obs_df, v_lz_auc, tobit[["df"]]),
            combine_df(v_aumc, aumc$aumcinf.obs_df, v_lz_aumc, tobit[["df"]])
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
    lloq <- scenario_lloq(scenario_row$blq, scenario_row$ke)
    d <- simulate_data(scenario_row$design, scenario_row$ke, lloq)
    ret <- estimate_replicate(d, scenario_row$design, lloq, true_values(scenario_row$ke))
    if (!is.null(ret)) {
      ret$replicate <- replicate
      ret$scenario <- scenario_row$scenario
      ret$blq_last_time <- mean(d$blq[d$time == max(d$time)])
    }
    ret
  })
}

# Summary ####

summarize_results <- function(results) {
  results$t_quantile <- ifelse(is.finite(results$df) & results$df > 0, stats::qt(0.975, results$df), stats::qnorm(0.975))
  results$covered <- abs(results$estimate - results$truth) <= results$t_quantile*results$se
  keys <- unique(results[, c("scenario", "method", "parameter")])
  rows <- list()
  for (i in seq_len(nrow(keys))) {
    r <- merge(results, keys[i, ])
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
      summary = summarize_results(results),
      scenarios = scenarios,
      model = model,
      sample_times = sample_times,
      batch_times = batch_times,
      n_serial = n_serial,
      n_replicates = n_replicates,
      seed_base = seed_base,
      pknca_version = as.character(utils::packageVersion("PKNCA")),
      r_version = R.version.string,
      run_date = format(Sys.Date()),
      run_minutes = as.numeric(difftime(Sys.time(), started, units = "mins"))
    )
  saveRDS(simulation, "vignettes/v24-sparse-auc-to-infinity-simulation.rds")
  saveRDS(results, "data-raw/sparse_aucinf_simulation_replicates.rds")
  print(simulation$summary[, c("design", "blq", "elimination", "method", "parameter", "n", "relative_bias", "se_ratio", "coverage")], digits = 3)
}
