# The AUC from 0 to infinity of Wolfsegger and Jaki (2005) for serial
# sacrifice designs, with its asymptotic and bootstrap-t intervals.  No
# package implements it (the PK package implements the later estimator of
# Wolfsegger and Jaki 2009), so it is written here from the paper:
#
#   * The trapezoidal sum runs over the first K times, and the extrapolation is
#     xbar_K/lambda (equation 3).
#   * lambda is minus the least-squares slope over the last J - K times of the
#     bias-corrected log means, ybar_j = mean(log x_ij) + s2_xj/(2 xbar_j^2)
#     (equations 4 to 7), so it is independent of the trapezoidal sum.
#   * The bias correction is beta = xbar_K V[lambda]/lambda^3 (equation 15),
#     with V[lambda] = sum(u_j^2 s2_yj/n_j) (equation 11).
#   * The variance is equation 20, the asymptotic interval equation 30, and
#     the bootstrap-t interval equation 31, with the pivot
#     (AUC* - AUC)/sqrt(V*) from a bootstrap stratified by time.
#
# A concentration of zero (BLQ) has no logarithm; as in the PK package, it is
# replaced by 1e-256 in the logarithms.  A known zero at time 0 (oral dosing)
# enters the trapezoidal sum with no variance.

# The per-time summaries of serial data:  the means and variances of the
# concentrations and of their logarithms, as matrices with one row per data
# set (one row for the original data; one per replicate for the bootstrap)
wj2005_summaries <- function(conc_by_time) {
  n_rows <- nrow(conc_by_time[[1]])
  n_times <- length(conc_by_time)
  ret <- list(
    xbar = matrix(NA_real_, n_rows, n_times), s2x = matrix(NA_real_, n_rows, n_times),
    ybar = matrix(NA_real_, n_rows, n_times), s2y = matrix(NA_real_, n_rows, n_times)
  )
  for (j in seq_len(n_times)) {
    x <- conc_by_time[[j]]
    y <- log(ifelse(x == 0, 1e-256, x))
    ret$xbar[, j] <- rowMeans(x)
    ret$s2x[, j] <- (rowSums(x^2) - ncol(x)*ret$xbar[, j]^2)/(ncol(x) - 1)
    ret$ybar[, j] <- rowMeans(y)
    ret$s2y[, j] <- (rowSums(y^2) - ncol(y)*ret$ybar[, j]^2)/(ncol(y) - 1)
  }
  ret
}

# The estimate and its variance (equations 3, 15, and 20) for each row of the
# summaries.  `time` and `n` are the times and animals per time; `zero_first`
# says the first time is a known zero (no variance).
wj2005_estimate <- function(summaries, time, n, n_tail, zero_first) {
  n_times <- length(time)
  k <- n_times - n_tail
  tail <- (k + 1):n_times
  head <- seq_len(k)
  a <- time[tail] - mean(time[tail])
  u <- a/sum(a^2)
  # The bias-corrected log means of the tail
  ybar_tail <- summaries$ybar[, tail, drop = FALSE] + summaries$s2x[, tail, drop = FALSE]/(2*summaries$xbar[, tail, drop = FALSE]^2)
  lambda <- -as.vector(ybar_tail %*% u)
  var_lambda <- as.vector((summaries$s2y[, tail, drop = FALSE]/rep(n[tail], each = nrow(ybar_tail))) %*% u^2)
  # Trapezoidal weights over the first K times
  w <- numeric(k)
  w[1] <- (time[2] - time[1])/2
  if (k > 2) {
    w[2:(k - 1)] <- (time[3:k] - time[1:(k - 2)])/2
  }
  w[k] <- (time[k] - time[k - 1])/2
  xbar <- summaries$xbar[, head, drop = FALSE]
  s2xbar <- summaries$s2x[, head, drop = FALSE]/rep(n[head], each = nrow(xbar))
  if (zero_first) {
    s2xbar[, 1] <- 0
  }
  xbar_k <- xbar[, k]
  s2xbar_k <- s2xbar[, k]
  beta <- xbar_k*var_lambda/lambda^3
  estimate <- as.vector(xbar[, -k, drop = FALSE] %*% w[-k]) + xbar_k*(w[k] + 1/lambda) - beta
  variance <-
    as.vector(s2xbar[, -k, drop = FALSE] %*% w[-k]^2) +
    var_lambda/lambda^4*(xbar_k^2 + s2xbar_k) +
    s2xbar_k*(w[k] + 1/lambda + var_lambda/lambda^3)^2
  bad <- !is.finite(lambda) | lambda <= 0 | !is.finite(variance) | variance < 0
  estimate[bad] <- NA_real_
  variance[bad] <- NA_real_
  data.frame(estimate = estimate, variance = variance, lambda = lambda)
}

# The asymptotic and bootstrap-t intervals of one serial data set (columns
# time and conc_reported).  For oral dosing, `zero_first` adds the known zero
# at time 0.  The bootstrap resamples the animals at each time
# (`n_bootstrap` replicates under `seed`; none gives no bootstrap-t interval).
wj2005_intervals <- function(d, n_tail = 3, zero_first, n_bootstrap, seed, conf_level = 0.95) {
  time <- sort(unique(d$time))
  conc_by_time <- list()
  for (j in seq_along(time)) {
    conc_by_time[[j]] <- matrix(d$conc_reported[d$time == time[j]], nrow = 1)
  }
  if (zero_first) {
    time <- c(0, time)
    conc_by_time <- c(list(matrix(0, nrow = 1, ncol = ncol(conc_by_time[[1]]))), conc_by_time)
  }
  n <- vapply(conc_by_time, ncol, 1)
  original <- wj2005_estimate(wj2005_summaries(conc_by_time), time, n, n_tail, zero_first)
  alpha <- 1 - conf_level
  se <- sqrt(original$variance)
  z <- stats::qnorm(1 - alpha/2)
  if (n_bootstrap == 0) {
    return(
      data.frame(
        interval = c("wj2005 z", "wj2005 boot-t"), parameter = "auc",
        estimate = original$estimate, se = se,
        lower = c(original$estimate - z*se, NA_real_), upper = c(original$estimate + z*se, NA_real_),
        n_valid_bootstrap = c(NA_integer_, 0L)
      )
    )
  }
  boot_by_time <- list()
  withr::with_seed(seed, {
    for (j in seq_along(conc_by_time)) {
      x <- as.vector(conc_by_time[[j]])
      boot_by_time[[j]] <- matrix(x[sample.int(length(x), n_bootstrap*length(x), replace = TRUE)], nrow = n_bootstrap)
    }
  })
  boot <- wj2005_estimate(wj2005_summaries(boot_by_time), time, n, n_tail, zero_first)
  pivot <- (boot$estimate - original$estimate)/sqrt(boot$variance)
  pivot <- pivot[is.finite(pivot)]
  boot_t <-
    if (is.finite(original$estimate) && length(pivot) > 0) {
      # Quantile type 5, as in the PK package
      stats::quantile(pivot, c(alpha/2, 1 - alpha/2), type = 5, names = FALSE)
    } else {
      c(NA_real_, NA_real_)
    }
  data.frame(
    interval = c("wj2005 z", "wj2005 boot-t"), parameter = "auc",
    estimate = original$estimate, se = se,
    lower = c(original$estimate - z*se, original$estimate - boot_t[2]*se),
    upper = c(original$estimate + z*se, original$estimate - boot_t[1]*se),
    n_valid_bootstrap = c(NA_integer_, length(pivot))
  )
}
