# Known answers for the study of what the sparse estimates converge to:  a
# population of one animal with one compartment after an IV bolus has a
# monoexponential mean curve, so every half-life is the true one and the bias
# of the AUC to infinity is the linear trapezoidal rule's alone; and the closed
# form of the mean with BLQ samples counted as zero matches numerical
# integration over the residual error.
source(file.path("..", "..", "R", "design.R"))
source(file.path("..", "..", "R", "study_se.R"))
source(file.path("..", "..", "R", "study_converged.R"))

test_that("converged_population() gives the known answers for a monoexponential curve", {
  scenario <- design_scenarios()
  scenario <- scenario[scenario$route == "iv" & scenario$design == "serial" & scenario$blq == "none" &
    scenario$elimination == "fast" & scenario$compartments == 1, ]
  animal <- typical_animal(scenario)
  ke <- animal$cl/animal$v1
  result <- converged_population(animal, scenario)
  expect_equal(result$duration, c(24, 24, 48, 72))
  expect_equal(result$blq, c("none", "moderate", "none", "none"))
  no_blq <- result[result$blq == "none", ]
  expect_equal(no_blq$tlast, c(24, 48, 72))
  expect_equal(no_blq$half_life_typical, rep(log(2)/ke, 3))
  expect_equal(no_blq$half_life_converged, rep(log(2)/ke, 3))
  expect_equal(no_blq$half_life_local, rep(log(2)/ke, 3))
  expect_equal(no_blq$half_life_effective, rep(log(2)/ke, 3))
  expect_equal(no_blq$bias_clast, rep(0, 3))
  expect_equal(no_blq$bias_lambda_z, rep(0, 3))
  expect_equal(no_blq$percent_extrapolated, 100*exp(-ke*no_blq$tlast))
  # The linear trapezoidal AUC to tlast, with the back-extrapolated C0 exact,
  # against the exact area
  c0 <- model$dose/animal$v1
  aucinf <- c0/ke
  for (i in seq_len(nrow(no_blq))) {
    times <- c(0, sampling_times$iv, converged_extra_times)
    times <- times[times <= no_blq$tlast[i]]
    conc <- c0*exp(-ke*times)
    trapezoid <- sum(diff(times)*(utils::head(conc, -1) + utils::tail(conc, -1))/2)
    exact <- aucinf*(1 - exp(-ke*no_blq$tlast[i]))
    expect_equal(no_blq$bias_trapezoid[i], 100*(trapezoid - exact)/aucinf)
  }
  # The parts of the bias sum to the total
  expect_equal(result$bias_total, result$bias_trapezoid + result$bias_clast + result$bias_lambda_z)
})

test_that("population_blq_mean() matches numerical integration over the residual error", {
  s <- model$sigma
  # Each column has some samples BLQ, but fewer than half (40% in the second)
  conc <- matrix(c(1, 2, 0.9, 1.4), nrow = 2)
  lloq <- 1
  expected_above <- function(c) {
    # c*e with log(e) = z normal (mean -s^2/2, sd s), counted when c*e >=
    # lloq; the density is negligible beyond 12 standard deviations
    stats::integrate(
      function(z) c*exp(z)*stats::dnorm(z, mean = -s^2/2, sd = s),
      lower = log(lloq/c), upper = -s^2/2 + 12*s, rel.tol = 1e-10
    )$value
  }
  expected <- c(mean(vapply(conc[, 1], expected_above, 1)), mean(vapply(conc[, 2], expected_above, 1)))
  expect_equal(population_blq_mean(conc, lloq), expected, tolerance = 1e-8)
  # More than half of the samples BLQ:  the mean is zero
  conc_low <- matrix(c(0.5, 0.6, 1.5), ncol = 1)
  expect_equal(population_blq_mean(conc_low, lloq), 0)
})

test_that("converged_population() averages over animals:  two animals with different elimination", {
  scenario <- design_scenarios()
  scenario <- scenario[scenario$route == "iv" & scenario$design == "serial" & scenario$blq == "none" &
    scenario$elimination == "fast" & scenario$compartments == 1, ]
  animals <- data.frame(ka = 5, cl = c(1, 3), v1 = c(10, 12))
  k <- animals$cl/animals$v1
  c0 <- model$dose/animals$v1
  result <- converged_population(animals, scenario)
  expect_equal(result$duration, c(24, 24, 48, 72))
  # The population mean curve is the mean of two exponentials, so its local
  # slope, the area after a time, and the AUC to infinity have closed forms
  mean_at <- function(t) mean(c0*exp(-k*t))
  for (i in seq_len(nrow(result))) {
    t <- result$tlast[i]
    lambda_local <- sum(c0*k*exp(-k*t))/sum(c0*exp(-k*t))
    tail_area <- mean(c0/k*exp(-k*t))
    aucinf <- mean(c0/k)
    expect_equal(result$half_life_local[i], log(2)/lambda_local, tolerance = 1e-7)
    expect_equal(result$half_life_effective[i], log(2)*tail_area/mean_at(t))
    expect_equal(result$percent_extrapolated[i], 100*tail_area/aucinf)
    lambda_fit <- log(2)/result$half_life_converged[i]
    expect_equal(result$bias_lambda_z[i], 100*(mean_at(t)/lambda_fit - tail_area)/aucinf)
  }
  # The mean of two exponentials declines ever more slowly, so the fitted
  # half-life lies between the faster animal's and the local half-life
  no_blq <- result[result$blq == "none", ]
  expect_true(all(no_blq$half_life_converged > log(2)/max(k)))
  expect_true(all(no_blq$half_life_converged < no_blq$half_life_local))

  # With BLQ samples, Clast is the mean with BLQ samples counted as zero, and
  # its bias is measured against the population mean
  blq_row <- result[result$blq == "moderate", ]
  lloq <- scenario_lloq(transform(scenario, blq = "moderate"))
  c_24 <- c0*exp(-k*24)
  s <- model$sigma
  clast_blq <- mean(c_24*stats::pnorm((log(c_24/lloq) + s^2/2)/s))
  expect_equal(blq_row$tlast, 24)
  expect_equal(
    blq_row$bias_clast,
    100*(clast_blq - mean_at(24))*blq_row$half_life_converged/log(2)/mean(c0/k)
  )
  expect_lt(blq_row$bias_clast, 0)
})

test_that("converged_estimate() ends the profile at the last positive mean and imputes zero at time 0 for oral dosing", {
  k <- 0.2
  times <- sampling_times$oral
  # Monoexponential after the first sample, and the last mean zero (more than
  # half of its samples BLQ)
  means <- 10*exp(-k*times)
  means[length(means)] <- 0
  e <- converged_estimate(times, means, "oral")
  expect_equal(e$tlast, 12)
  expect_equal(e$clast, 10*exp(-k*12))
  expect_equal(e$lambda.z, k)
  all_times <- c(0, times[-length(times)])
  conc <- c(0, means[-length(means)])
  trapezoid <- sum(diff(all_times)*(utils::head(conc, -1) + utils::tail(conc, -1))/2)
  expect_equal(e$auclast, trapezoid)
  expect_equal(e$aucinf, trapezoid + e$clast/k)
})

test_that("population_blq_mean() sets a time to zero only when more than half of its samples are BLQ", {
  # One animal with lloq 1 is BLQ with probability above one half when its
  # concentration is below exp(sigma^2/2)
  threshold <- exp(model$sigma^2/2)
  conc <- matrix(c(0.995, 1.005)*threshold, nrow = 1)
  ret <- population_blq_mean(conc, lloq = 1)
  expect_equal(ret[1], 0)
  expect_gt(ret[2], 0)
})
