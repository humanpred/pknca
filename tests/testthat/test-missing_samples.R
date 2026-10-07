test_that("pknca_missing_samples reports absent rows and NA concentrations against the group's schedule", {
  o_conc <- PKNCAconc(tmax_coverage_conc(), conc ~ time | subject, time.nominal = "time_nominal")
  expect_equal(
    pknca_missing_samples(o_conc),
    rbind(
      data.frame(subject = 5, time_nominal = 1, reason = "NA concentration"),
      data.frame(subject = 6, time_nominal = 0.5, reason = "no row"),
      data.frame(subject = 6, time_nominal = 1, reason = "no row"),
      data.frame(subject = 6, time_nominal = 2, reason = "no row"),
      data.frame(subject = 6, time_nominal = 4, reason = "no row")
    )
  )
})

test_that("pknca_missing_samples gives the same answer for PKNCAconc, PKNCAdata, and PKNCAresults objects", {
  o_nca <- tmax_coverage_results()
  expected <- pknca_missing_samples(as_PKNCAconc(o_nca))
  expect_equal(nrow(expected), 5)
  expect_equal(pknca_missing_samples(as_PKNCAdata(o_nca)), expected)
  expect_equal(pknca_missing_samples(o_nca), expected)
})

test_that("pknca_missing_samples uses each group's own schedule", {
  d_conc <-
    rbind(
      data.frame(treatment = "A", subject = 1, time_nominal = c(0, 1, 2), time = c(0, 1, 2), conc = c(0, 2, 1)),
      data.frame(treatment = "A", subject = 2, time_nominal = c(0, 2), time = c(0, 2), conc = c(0, 1)),
      data.frame(treatment = "B", subject = 1, time_nominal = c(0, 4), time = c(0, 4), conc = c(0, 2)),
      data.frame(treatment = "B", subject = 2, time_nominal = c(0, 4), time = c(0, 4), conc = c(0, 3))
    )
  o_conc <- PKNCAconc(d_conc, conc ~ time | treatment + subject, time.nominal = "time_nominal")
  # Treatment B has no 1-hour sample in its schedule, and treatment A has no
  # 4-hour sample in its schedule
  expect_equal(
    pknca_missing_samples(o_conc),
    data.frame(treatment = "A", subject = 2, time_nominal = 1, reason = "no row")
  )
})

test_that("pknca_missing_samples reports excluded samples, and a sample is usable when any row at the time is", {
  d_conc <-
    rbind(
      data.frame(subject = 1, time_nominal = c(0, 1, 2), time = c(0, 1, 2), conc = c(0, 2, 1), excl = c(NA, "Swap", NA)),
      data.frame(subject = 2, time_nominal = c(0, 1, 2), time = c(0, 1, 2), conc = c(0, NA, 1), excl = c(NA, "Lost", NA)),
      # A repeat sample at 1 hour replaces the excluded one
      data.frame(subject = 3, time_nominal = c(0, 1, 1, 2), time = c(0, 1, 1.1, 2), conc = c(0, 2, 2.1, 1), excl = c(NA, "Swap", NA, NA))
    )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal", exclude = "excl")
  expect_equal(
    pknca_missing_samples(o_conc),
    rbind(
      data.frame(subject = 1, time_nominal = 1, reason = "excluded"),
      # An NA concentration is reported as such, whether or not it is excluded
      data.frame(subject = 2, time_nominal = 1, reason = "NA concentration")
    )
  )
})

test_that("pknca_missing_samples ignores unscheduled samples and returns no rows when nothing is missing", {
  d_conc <-
    rbind(
      data.frame(subject = 1, time_nominal = c(0, 1, 2), time = c(0, 1, 2), conc = c(0, 2, 1)),
      data.frame(subject = 2, time_nominal = c(0, 1, 2, NA), time = c(0, 1, 2, 3), conc = c(0, 3, 1, 0.5))
    )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal")
  expect_equal(
    pknca_missing_samples(o_conc),
    data.frame(subject = numeric(), time_nominal = numeric(), reason = character())
  )
})

test_that("pknca_missing_samples works without groups", {
  d_conc <- data.frame(time_nominal = c(0, 1, 2), time = c(0, 1, 2), conc = c(0, NA, 1))
  o_conc <- PKNCAconc(d_conc, conc ~ time, time.nominal = "time_nominal")
  expect_equal(
    pknca_missing_samples(o_conc),
    data.frame(time_nominal = 1, reason = "NA concentration")
  )
  # One group column and no subject column beside it
  d_conc$study <- "S1"
  o_conc_study <- PKNCAconc(d_conc, conc ~ time | study, time.nominal = "time_nominal")
  expect_equal(
    pknca_missing_samples(o_conc_study),
    data.frame(study = "S1", time_nominal = 1, reason = "NA concentration")
  )
})

test_that("pknca_missing_samples needs nominal times", {
  o_conc <- PKNCAconc(tmax_coverage_conc(), conc ~ time | subject)
  expect_error(
    pknca_missing_samples(o_conc),
    class = "pknca_error_missing_samples_no_time_nominal"
  )
  d_conc <- tmax_coverage_conc()
  d_conc$time_nominal <- NA_real_
  o_conc_na <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal")
  expect_error(
    pknca_missing_samples(o_conc_na),
    regexp = "the nominal time column ('time_nominal') has no values",
    fixed = TRUE,
    class = "pknca_error_missing_samples_no_nominal_values"
  )
  expect_error(pknca_missing_samples(tmax_coverage_conc()), regexp = "Must inherit from class")
})

test_that("pknca_missing_samples reports only existing rows for sparse data", {
  d_conc <-
    rbind(
      data.frame(subject = 1, time_nominal = c(0, 2), time = c(0, 2), conc = c(0, 2)),
      data.frame(subject = 2, time_nominal = c(1, 4), time = c(1, 4), conc = c(NA, 1)),
      data.frame(subject = 3, time_nominal = c(0, 4), time = c(0, 4), conc = c(0, 1.5))
    )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal", sparse = TRUE)
  expect_message(
    result <- pknca_missing_samples(o_conc),
    class = "pknca_message_missing_samples_sparse"
  )
  expect_equal(result, data.frame(subject = 2, time_nominal = 1, reason = "NA concentration"))
})

test_that("pknca_semi_join keeps every row of x when there are no columns to match", {
  x <- data.frame(a = 1:3)
  expect_equal(pknca_semi_join(x, data.frame(b = 1), by = character()), x)
  expect_equal(pknca_semi_join(x, data.frame(b = numeric()), by = character()), x[0, , drop = FALSE])
  expect_equal(pknca_semi_join(x, data.frame(a = c(1L, 3L)), by = "a"), data.frame(a = c(1L, 3L)))
})

test_that("pknca_missing_samples does not report groups whose nominal times restart at each dose", {
  d_restart <- restart_conc(peaks = c(1, 1, 2))
  # Subject 3 misses the 2-hour sample after the second dose, which the first
  # dose's 2-hour sample would otherwise fill
  d_restart <- d_restart[!(d_restart$subject == 3 & d_restart$time == 26), ]
  o_conc <- PKNCAconc(d_restart, conc ~ time | subject, time.nominal = "time_nominal")
  expect_warning(
    result <- pknca_missing_samples(o_conc),
    regexp = "Missing samples are not reported for the data:  the nominal times of 3 subject(s) decrease while the actual times increase, as when the nominal times restart at each dose",
    fixed = TRUE,
    class = "pknca_warning_missing_samples_nominal_restart"
  )
  expect_equal(result, data.frame(subject = numeric(), time_nominal = numeric(), reason = character()))

  # Only the group with restarting nominal times is left out
  d_restart$treatment <- "A"
  d_once <- tmax_coverage_conc()
  d_once$treatment <- "B"
  o_conc_two <- PKNCAconc(rbind(d_restart, d_once), conc ~ time | treatment + subject, time.nominal = "time_nominal")
  result_two <-
    withCallingHandlers(
      pknca_missing_samples(o_conc_two),
      pknca_warning_missing_samples_nominal_restart = function(w) {
        expect_equal(w$group, data.frame(treatment = "A"))
        expect_match(conditionMessage(w), "Missing samples are not reported for treatment=A:", fixed = TRUE)
        invokeRestart("muffleWarning")
      }
    )
  expect_equal(
    result_two,
    cbind(treatment = "B", pknca_missing_samples(PKNCAconc(tmax_coverage_conc(), conc ~ time | subject, time.nominal = "time_nominal")))
  )
})

test_that("pknca_nominal_restart_keys finds decreasing nominal times and allows repeats", {
  d_conc <-
    rbind(
      # Repeated samples at one nominal time, and two samples at one actual time
      data.frame(subject = 1, time = c(0, 1, 1.1, 2, 2), time_nominal = c(0, 1, 1, 2, 3)),
      # A restart
      data.frame(subject = 2, time = c(0, 1, 24, 25), time_nominal = c(0, 1, 0, 1)),
      # Missing times are ignored
      data.frame(subject = 3, time = c(0, NA, 2), time_nominal = c(0, 5, NA))
    )
  expect_equal(
    pknca_nominal_restart_keys(d_conc, id_cols = "subject", actual_col = "time", nominal_col = "time_nominal"),
    pknca_interval_group_key(data.frame(subject = 2), "subject")
  )
  expect_equal(
    pknca_nominal_restart_keys(d_conc[1, ], id_cols = "subject", actual_col = "time", nominal_col = "time_nominal"),
    character()
  )
  # Without subject columns, the data are one subject
  expect_equal(
    pknca_nominal_restart_keys(d_conc[d_conc$subject == 2, ], id_cols = character(), actual_col = "time", nominal_col = "time_nominal"),
    ""
  )
})
