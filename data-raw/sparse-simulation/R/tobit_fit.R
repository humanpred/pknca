# Tobit regression of the individual log concentrations for lambda.z, with a
# random intercept for each animal when animals give more than one sample.

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

# A t-interval with the Satterthwaite combination of two variance components
combine_df <- function(v1, df1, v2, df2) {
  (v1 + v2)^2/(v1^2/df1 + v2^2/df2)
}
