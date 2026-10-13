# Known answers for wj2005_estimate():  a literal transcription of equations
# 2 to 7, 15, 3, and 20 of Wolfsegger and Jaki (2005), written with loops and
# with the paper's sum(u_l ybar_l) (minus lambda) rather than lambda, so that
# it shares no code with the vectorized implementation.
source(file.path("..", "..", "R", "wolfsegger_jaki_2005.R"))

# x is a list with one vector of concentrations per time; the first time may
# be a known zero (variance zero).  Returns the estimate and its variance.
wj2005_by_the_paper <- function(x, time, n_tail) {
  n_times <- length(time)
  k <- n_times - n_tail
  n <- numeric(n_times)
  xbar <- numeric(n_times)
  s2x <- numeric(n_times)
  ybar <- numeric(n_times)
  s2y <- numeric(n_times)
  for (j in seq_len(n_times)) {
    n[j] <- length(x[[j]])
    xbar[j] <- sum(x[[j]])/n[j]
    s2x[j] <- sum((x[[j]] - xbar[j])^2)/(n[j] - 1)
    if (j > k) {
      # Equation 5:  the bias-corrected log values, with the estimates
      y <- log(x[[j]]) + s2x[j]/(2*xbar[j]^2)
      ybar[j] <- sum(y)/n[j]
      s2y[j] <- sum((y - ybar[j])^2)/(n[j] - 1)
    }
  }
  # Equation 23
  s2xbar <- s2x/n
  s2ybar <- s2y/n
  # Equation 2:  trapezoidal weights over the first K times
  w <- numeric(k)
  w[1] <- (time[2] - time[1])/2
  for (j in 2:(k - 1)) {
    w[j] <- (time[j + 1] - time[j - 1])/2
  }
  w[k] <- (time[k] - time[k - 1])/2
  # Equations 6 and 7
  tbar <- 0
  for (l in (k + 1):n_times) {
    tbar <- tbar + time[l]/(n_times - k)
  }
  sum_a2 <- 0
  for (l in (k + 1):n_times) {
    sum_a2 <- sum_a2 + (time[l] - tbar)^2
  }
  u <- numeric(n_times)
  for (l in (k + 1):n_times) {
    u[l] <- (time[l] - tbar)/sum_a2
  }
  sum_uy <- 0
  sum_u2s2 <- 0
  for (l in (k + 1):n_times) {
    sum_uy <- sum_uy + u[l]*ybar[l]
    sum_u2s2 <- sum_u2s2 + u[l]^2*s2ybar[l]
  }
  # Equation 4:  lambda = -sum(u ybar); equation 15 with the estimates
  lambda <- -sum_uy
  beta <- xbar[k]*sum_u2s2/lambda^3
  # Equation 3
  estimate <- 0
  for (j in seq_len(k - 1)) {
    estimate <- estimate + w[j]*xbar[j]
  }
  estimate <- estimate + xbar[k]*(w[k] + 1/lambda) - beta
  # Equation 20
  variance <- 0
  for (j in seq_len(k - 1)) {
    variance <- variance + w[j]^2*s2xbar[j]
  }
  variance <-
    variance +
    sum_u2s2/sum_uy^4*(xbar[k]^2 + s2xbar[k]) +
    s2xbar[k]*(w[k] - 1/sum_uy - sum_u2s2/sum_uy^3)^2
  c(estimate = estimate, variance = variance)
}

# The implementation's estimate and variance for the same data
wj2005_by_the_code <- function(x, time, n_tail, zero_first) {
  conc_by_time <- list()
  for (j in seq_along(x)) {
    conc_by_time[[j]] <- matrix(x[[j]], nrow = 1)
  }
  n <- vapply(x, length, 1)
  ret <- wj2005_estimate(wj2005_summaries(conc_by_time), time, n, n_tail, zero_first)
  c(estimate = ret$estimate, variance = ret$variance)
}

test_that("wj2005_estimate() matches equations 3, 15, and 20 of the paper", {
  time <- c(0, 0.5, 1, 2, 4, 6, 8, 12, 24)
  curve <- c(0, 4, 6, 7, 5, 3.5, 2.4, 1.1, 0.15)
  for (n_animals in c(3, 5, 12)) {
    x <- list(rep(0, n_animals))
    withr::with_seed(n_animals, {
      for (j in 2:length(time)) {
        x[[j]] <- curve[j]*exp(stats::rnorm(n_animals, sd = 0.3))
      }
    })
    expect_equal(
      wj2005_by_the_code(x, time, n_tail = 3, zero_first = TRUE),
      wj2005_by_the_paper(x, time, n_tail = 3),
      tolerance = 1e-10
    )
  }
})

test_that("wj2005_estimate() gives the true AUC of equation 1 with no variability", {
  # Every animal at the curve:  the estimate is equation 1 at the true means,
  # with lambda from the log-linear tail, and the variance is zero
  time <- c(0, 1, 2, 4, 8, 12, 16)
  lambda <- 0.2
  curve <- c(0, 5, 6, 6*exp(-lambda*c(2, 6, 10, 14)))
  x <- lapply(curve, rep, times = 4)
  k <- length(time) - 3
  w <- c((time[2] - time[1])/2, (time[3:k] - time[1:(k - 2)])/2, (time[k] - time[k - 1])/2)
  expected <- sum(w*curve[1:k]) + curve[k]/lambda
  result <- wj2005_by_the_code(x, time, n_tail = 3, zero_first = TRUE)
  expect_equal(result[["estimate"]], expected, tolerance = 1e-12)
  expect_equal(result[["variance"]], 0)
})

test_that("wj2005_estimate() returns NA when lambda.z is not positive", {
  time <- c(0, 1, 2, 4, 8, 12)
  # Rising tail
  x <- list(rep(0, 3), c(1, 1.1, 0.9), c(2, 2.1, 1.9), c(3, 3.1, 2.9), c(4, 4.2, 3.8), c(5, 5.1, 4.9))
  result <- wj2005_by_the_code(x, time, n_tail = 3, zero_first = TRUE)
  expect_equal(unname(result), c(NA_real_, NA_real_))
})
