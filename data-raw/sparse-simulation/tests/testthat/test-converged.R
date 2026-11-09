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
