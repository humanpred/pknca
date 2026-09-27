# Two subjects in one study part, the second dosed 30 minutes after the first,
# with the same relative sampling times (0, 1, 2, 4, 8, 24 hours)
datetime_test_data <- function(tz = "UTC") {
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = tz)
  rel_hr <- c(0, 1, 2, 4, 8, 24)
  offset_s <- c(0, 1800)
  d_conc <-
    data.frame(
      part = "A",
      subject = rep(1:2, each = length(rel_hr)),
      time = t0 + rep(rel_hr * 3600, 2) + rep(offset_s, each = length(rel_hr)),
      time_hr = rep(rel_hr, 2),
      conc = c(0, 5, 8, 6, 3, 1, 0, 4, 7, 5, 2, 0.5)
    )
  d_dose <- data.frame(part = "A", subject = 1:2, time = t0 + offset_s, time_hr = 0, dose = 100)
  list(conc = d_conc, dose = d_dose, t0 = t0)
}

test_that("POSIXct times become numeric time relative to each subject's first dose", {
  skip_if_not_installed("units")
  d <- datetime_test_data()
  o_conc <- PKNCAconc(d$conc, conc~time|part+subject, concu = "ng/mL", timeu = "s", timeu_pref = "hr")
  o_dose <- PKNCAdose(d$dose, dose~time|part+subject, doseu = "mg")
  # The objects keep the date-times
  expect_s3_class(o_conc$data$time, "POSIXct")
  expect_equal(o_conc$units$timeu, "s", ignore_attr = TRUE)
  o_data <- PKNCAdata(o_conc, o_dose)
  expect_equal(o_data$conc$data$time, d$conc$time_hr)
  expect_equal(o_data$dose$data$time, c(0, 0))
  expect_equal(o_data$conc$units$timeu, "hr", ignore_attr = TRUE)
  expect_equal(o_data$conc$units$timeu_pref, "hr", ignore_attr = TRUE)
  expect_equal(
    o_data$time_reference,
    data.frame(part = "A", subject = 1:2, time_reference = d$dose$time)
  )
  # Automatic intervals are in the preferred time unit
  expect_equal(o_data$intervals$start, c(0, 0, 0, 0))
  expect_equal(o_data$intervals$end, c(24, Inf, 24, Inf))

  # The results are those of the equivalent numeric-time analysis
  o_conc_num <- PKNCAconc(d$conc, conc~time_hr|part+subject, concu = "ng/mL", timeu = "hr")
  o_dose_num <- PKNCAdose(d$dose, dose~time_hr|part+subject, doseu = "mg")
  o_nca <- pk.nca(o_data)
  o_nca_num <- pk.nca(PKNCAdata(o_conc_num, o_dose_num))
  expect_equal(as.data.frame(o_nca), as.data.frame(o_nca_num))
  expect_equal(
    as.data.frame(o_nca)$PPORRESU[as.data.frame(o_nca)$PPTESTCD == "tmax"],
    c("hr", "hr")
  )
})

test_that("Without timeu_pref, POSIXct times are in seconds, with a warning", {
  d <- datetime_test_data()
  # Without any units, no time unit is set
  o_conc <- PKNCAconc(d$conc, conc~time|part+subject)
  expect_null(o_conc$units$timeu)
  expect_warning(
    o_data <- PKNCAdata(o_conc, PKNCAdose(d$dose, dose~time|part+subject)),
    class = "pknca_warning_datetime_seconds"
  )
  expect_equal(o_data$conc$data$time, d$conc$time_hr * 3600)
  expect_null(o_data$conc$units$timeu)
  # The default single-dose interval (0 to 24) is in seconds
  expect_equal(o_data$intervals$end, c(24, Inf, 24, Inf))
  # With timeu = "s", the unit is kept
  o_conc_s <- PKNCAconc(d$conc, conc~time|part+subject, timeu = "s")
  expect_warning(
    o_data_s <- PKNCAdata(o_conc_s, PKNCAdose(d$dose, dose~time|part+subject)),
    class = "pknca_warning_datetime_seconds"
  )
  expect_equal(o_data_s$conc$units$timeu, "s", ignore_attr = TRUE)
})

test_that("A date-time time column requires timeu = 's'", {
  d <- datetime_test_data()
  expect_error(
    PKNCAconc(d$conc, conc~time|part+subject, timeu = "hr"),
    class = "pknca_error_datetime_timeu"
  )
  # A numeric time is unaffected
  expect_equal(PKNCAconc(d$conc, conc~time_hr|part+subject, timeu = "hr")$units$timeu, "hr", ignore_attr = TRUE)
})

test_that("Date times are midnight, with a warning", {
  skip_if_not_installed("units")
  d_conc <- data.frame(subject = 1, time = as.Date("2024-01-01") + 0:3, conc = c(0, 4, 2, 1))
  d_dose <- data.frame(subject = 1, time = as.Date("2024-01-01"), dose = 1)
  expect_warning(
    o_conc <- PKNCAconc(d_conc, conc~time|subject, timeu_pref = "day"),
    class = "pknca_warning_date_midnight"
  )
  expect_warning(
    o_dose <- PKNCAdose(d_dose, dose~time|subject),
    class = "pknca_warning_date_midnight"
  )
  o_data <- PKNCAdata(o_conc, o_dose)
  expect_equal(o_data$conc$data$time, 0:3)
  expect_equal(o_data$time_reference$time_reference, as.POSIXct("2024-01-01", tz = "UTC"))

  # A Date takes the time zone of the date-times it is paired with, so midnight
  # is local midnight.
  d_dose_dt <- data.frame(subject = 1, time = as.POSIXct("2024-01-01 06:00", tz = "America/New_York"), dose = 1)
  o_data_tz <- PKNCAdata(o_conc, PKNCAdose(d_dose_dt, dose~time|subject))
  expect_equal(o_data_tz$conc$data$time, c(-0.25, 0.75, 1.75, 2.75))
})

test_that("Numeric and date-time times cannot be mixed", {
  d <- datetime_test_data()
  o_conc_dt <- PKNCAconc(d$conc, conc~time|part+subject)
  o_conc_num <- PKNCAconc(d$conc, conc~time_hr|part+subject)
  o_dose_dt <- PKNCAdose(d$dose, dose~time|part+subject)
  o_dose_num <- PKNCAdose(d$dose, dose~time_hr|part+subject)
  expect_error(PKNCAdata(o_conc_dt, o_dose_num), class = "pknca_error_datetime_mixed")
  expect_error(PKNCAdata(o_conc_num, o_dose_dt), class = "pknca_error_datetime_mixed")
  # Numeric with numeric is unaffected and has no time reference
  expect_null(PKNCAdata(o_conc_num, o_dose_num)$time_reference)
})

test_that("Date-times with different time zones are an error", {
  d <- datetime_test_data(tz = "UTC")
  d_dose <- d$dose
  d_dose$time <- as.POSIXct(format(d_dose$time), tz = "America/New_York")
  expect_error(
    PKNCAdata(
      PKNCAconc(d$conc, conc~time|part+subject),
      PKNCAdose(d_dose, dose~time|part+subject)
    ),
    class = "pknca_error_datetime_mixed_tz"
  )
})

test_that("Date-time concentrations need dose times for the reference", {
  d <- datetime_test_data()
  o_conc <- PKNCAconc(d$conc, conc~time|part+subject)
  expect_error(
    PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 24, cmax = TRUE)),
    class = "pknca_error_datetime_no_dose_time"
  )
  expect_error(
    PKNCAdata(o_conc, PKNCAdose(d$dose, dose~.|part+subject)),
    class = "pknca_error_datetime_no_dose_time"
  )
  # A subject without a dose has no reference
  expect_error(
    PKNCAdata(o_conc, PKNCAdose(d$dose[1, ], dose~time|part+subject)),
    regexp = "part=A, subject=2",
    class = "pknca_error_datetime_no_reference"
  )
  # Nor does a subject whose only dose is excluded
  d_dose_excl <- d$dose
  d_dose_excl$excl <- c(NA, "Not given")
  expect_error(
    PKNCAdata(o_conc, PKNCAdose(d_dose_excl, dose~time|part+subject, exclude = "excl")),
    class = "pknca_error_datetime_no_reference"
  )
})

test_that("The reference is the first included dose within the shared groups", {
  skip_if_not_installed("units")
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  # Two study parts one week apart, with two doses 12 hours apart in each part
  d_conc <-
    data.frame(
      subject = 1,
      part = rep(c("SAD", "MAD"), each = 3),
      time = t0 + c(0, 1, 13, 168, 169, 181) * 3600,
      conc = c(0, 3, 4, 0, 3, 4)
    )
  d_dose <-
    data.frame(
      subject = 1,
      part = rep(c("SAD", "MAD"), each = 2),
      time = t0 + c(0, 12, 168, 180) * 3600,
      dose = 1,
      excl = c(NA, NA, "Vomited", NA)
    )
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|part+subject, concu = "ng/mL", timeu_pref = "hr"),
      PKNCAdose(d_dose, dose~time|part+subject, exclude = "excl"),
      intervals = data.frame(start = 0, end = 12, cmax = TRUE)
    )
  expect_equal(o_data$conc$data$time, c(0, 1, 13, -12, -11, 1))
  expect_equal(o_data$dose$data$time, c(0, 12, -12, 0))
  expect_equal(
    o_data$time_reference,
    data.frame(part = c("MAD", "SAD"), subject = 1, time_reference = t0 + c(180, 0) * 3600)
  )
  # Manually-given intervals are relative to the reference:  0 to 12 hours holds
  # only the concentration 1 hour after the MAD reference and the concentrations
  # at 0 and 1 hour after the SAD reference.
  o_nca <- pk.nca(o_data)
  d_nca <- as.data.frame(o_nca)
  expect_equal(d_nca$part[d_nca$PPTESTCD == "cmax"], c("MAD", "SAD"))
  expect_equal(d_nca$PPORRES[d_nca$PPTESTCD == "cmax"], c(4, 3))
})

test_that("A dose grouping without the subject gives one reference per shared group", {
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  d_conc <-
    data.frame(
      treatment = "A",
      id = rep(1:2, each = 2),
      time = t0 + c(0, 3600, 1800, 5400),
      conc = c(1, 2, 1.5, 2.5)
    )
  d_dose <- data.frame(treatment = "A", time = t0, dose = 1)
  expect_warning(
    o_data <-
      PKNCAdata(
        PKNCAconc(d_conc, conc~time|treatment, subject = "id", sparse = TRUE),
        PKNCAdose(d_dose, dose~time|treatment),
        intervals = data.frame(start = 0, end = 7200, cmax = TRUE)
      ),
    class = "pknca_warning_datetime_seconds"
  )
  expect_equal(o_data$conc$data_sparse$time, c(0, 3600, 1800, 5400))
  expect_equal(o_data$time_reference, data.frame(treatment = "A", time_reference = t0))
})

test_that("Ungrouped date-time data use the single first dose", {
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  expect_warning(
    o_data <-
      PKNCAdata(
        PKNCAconc(data.frame(time = t0 + c(0, 60, 120), conc = c(0, 2, 1)), conc~time),
        PKNCAdose(data.frame(time = t0 + 60, dose = 1), dose~time),
        intervals = data.frame(start = 0, end = 60, cmax = TRUE)
      ),
    class = "pknca_warning_datetime_seconds"
  )
  expect_equal(o_data$conc$data$time, c(-60, 0, 60))
  expect_equal(o_data$time_reference, data.frame(time_reference = t0 + 60))
})

test_that("Durations follow the time to the preferred unit", {
  skip_if_not_installed("units")
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  d_conc <-
    data.frame(subject = 1, time = t0 + c(0, 6, 12) * 3600, conc = c(0, 5, 2), dur = c(6, 6, 12) * 3600, vol = 1)
  d_dose <- data.frame(subject = 1, time = t0, dose = 10, dur = 1800)
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|subject, duration = "dur", volume = "vol", timeu_pref = "hr"),
      PKNCAdose(d_dose, dose~time|subject, route = "intravascular", duration = "dur"),
      intervals = data.frame(start = 0, end = 24, cmax = TRUE)
    )
  expect_equal(o_data$conc$data$dur, c(6, 6, 12))
  expect_equal(o_data$dose$data$dur, 0.5)
})

test_that("Elapsed time crosses a daylight saving time change correctly", {
  skip_if_not_installed("units")
  # Clocks moved forward one hour at 2024-03-10 02:00 in New York
  t0 <- as.POSIXct("2024-03-09 08:00:00", tz = "America/New_York")
  d_conc <-
    data.frame(
      subject = 1,
      time = as.POSIXct(c("2024-03-09 08:00:00", "2024-03-10 08:00:00"), tz = "America/New_York"),
      conc = c(0, 1)
    )
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|subject, timeu_pref = "hr"),
      PKNCAdose(data.frame(subject = 1, time = t0, dose = 1), dose~time|subject)
    )
  expect_equal(o_data$conc$data$time, c(0, 23))
})

test_that("A preferred time unit that is not a time is an error", {
  skip_if_not_installed("units")
  d <- datetime_test_data()
  expect_error(
    PKNCAdata(
      PKNCAconc(d$conc, conc~time|part+subject, timeu_pref = "mg"),
      PKNCAdose(d$dose, dose~time|part+subject)
    ),
    class = "pknca_error_datetime_timeu_pref"
  )
})

test_that("The nominal time is not converted", {
  d <- datetime_test_data()
  expect_warning(
    o_data <-
      PKNCAdata(
        PKNCAconc(d$conc, conc~time|part+subject, time.nominal = "time_hr"),
        PKNCAdose(d$dose, dose~time|part+subject)
      ),
    class = "pknca_warning_datetime_seconds"
  )
  expect_equal(o_data$conc$data$time_hr, d$conc$time_hr)
})

test_that("CDISC results carry the reference date-time as PPRFTDTC", {
  skip_if_not_installed("units")
  d <- datetime_test_data(tz = "America/New_York")
  o_nca <-
    pk.nca(PKNCAdata(
      PKNCAconc(d$conc, conc~time|part+subject, concu = "ng/mL", timeu_pref = "hr"),
      PKNCAdose(d$dose, dose~time|part+subject)
    ))
  d_cdisc <- as.data.frame(o_nca, out_format = "cdisc")
  expect_equal(
    unique(d_cdisc[, c("subject", "PPRFTDTC")]),
    data.frame(subject = 1:2, PPRFTDTC = c("2024-03-01T08:00:00", "2024-03-01T08:30:00")),
    ignore_attr = TRUE
  )
  # The long format is unchanged, and numeric-time results have no PPRFTDTC
  expect_false("PPRFTDTC" %in% names(as.data.frame(o_nca)))
  o_nca_num <-
    pk.nca(PKNCAdata(
      PKNCAconc(d$conc, conc~time_hr|part+subject),
      PKNCAdose(d$dose, dose~time_hr|part+subject)
    ))
  expect_false("PPRFTDTC" %in% names(as.data.frame(o_nca_num, out_format = "cdisc")))
})

test_that("print.PKNCAdata reports the date-time reference", {
  d <- datetime_test_data()
  o_data <-
    suppressWarnings(PKNCAdata(
      PKNCAconc(d$conc, conc~time|part+subject),
      PKNCAdose(d$dose, dose~time|part+subject)
    ))
  expect_output(
    print(o_data),
    regexp = "Times are relative to the first dose within each part+subject (date-time input).",
    fixed = TRUE
  )
})

test_that("superposition() requires numeric times", {
  d <- datetime_test_data()
  expect_error(
    superposition(PKNCAconc(d$conc, conc~time|part+subject), tau = 24),
    class = "pknca_error_datetime_superposition"
  )
})

test_that("format_iso8601_datetime keeps missing values missing", {
  expect_equal(
    format_iso8601_datetime(as.POSIXct(c("2024-01-02 03:04:05", NA), tz = "UTC")),
    c("2024-01-02T03:04:05", NA)
  )
})
