# Known answers for the coverage summary that every comparison is scored by:
# a hand-made set of intervals with a known coverage, width, and bias.
source(file.path("..", "..", "R", "study_comparisons.R"))

test_that("summarize_intervals() scores hand-made intervals exactly", {
  scenarios <- data.frame(scenario = 1, route = "oral")
  results <-
    data.frame(
      scenario = 1, n_per_time = 4, interval = "test", parameter = "auc",
      # Covering, covering, missing low (interval below the truth), missing
      # high, and a failure
      estimate = c(10, 10, 8, 12, NA),
      lower = c(9, 9.5, 7, 11, NA),
      upper = c(11, 10.5, 9, 13, NA),
      truth = 10,
      n_fallback = c(0, 0, 0, 1, 0)
    )
  summary <- summarize_intervals(results, scenarios)
  expect_equal(summary$n_attempted, 5)
  expect_equal(summary$n, 4)
  expect_equal(summary$coverage, 50)
  expect_equal(summary$coverage_attempted, 40)
  expect_equal(summary$miss_low, 25)
  expect_equal(summary$miss_high, 25)
  # Widths 20%, 10%, 20%, 20% of the truth
  expect_equal(summary$median_ci_width, 20)
  # Relative errors 0, 0, -20%, +20%
  expect_equal(summary$relative_bias, 0)
  expect_equal(summary$median_bias, 0)
  expect_equal(summary$median_absolute_error, 10)
  expect_equal(summary$coverage_mcse, 100*sqrt(0.5*0.5/4))
  expect_equal(summary$percent_fallback, 20)
})

test_that("summarize_intervals() counts an interval touching the truth as covering", {
  scenarios <- data.frame(scenario = 1)
  results <-
    data.frame(
      scenario = 1, n_per_time = 4, interval = "test", parameter = "auc",
      estimate = c(10, 10), lower = c(10, 8), upper = c(12, 10), truth = 10, n_fallback = 0
    )
  expect_equal(summarize_intervals(results, scenarios)$coverage, 100)
})
