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
  o_conc <- PKNCAconc(d$conc, conc~time|part+subject, concu = "ng/mL", timeu_pref = "hr")
  o_dose <- PKNCAdose(d$dose, dose~time|part+subject, doseu = "mg")
  # The objects keep the date-times
  expect_s3_class(o_conc$data$time, "POSIXct")
  expect_equal(o_conc$units$timeu, "hr", ignore_attr = TRUE)
  o_data <- PKNCAdata(o_conc, o_dose)
  expect_equal(o_data$conc$data$time, d$conc$time_hr)
  expect_equal(o_data$dose$data$time, c(0, 0))
  expect_equal(o_data$conc$units$timeu, "hr", ignore_attr = TRUE)
  expect_equal(o_data$conc$units$timeu_pref, "hr", ignore_attr = TRUE)
  expect_equal(
    o_data$time_reference,
    data.frame(part = "A", subject = 1:2, time_reference = d$dose$time, time_reference_type = "first_dose")
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

test_that("Without units, POSIXct times are in hours", {
  d <- datetime_test_data()
  o_conc <- PKNCAconc(d$conc, conc~time|part+subject)
  # No time unit is set, so the analysis has no units
  expect_null(o_conc$units$timeu)
  expect_no_warning(o_data <- PKNCAdata(o_conc, PKNCAdose(d$dose, dose~time|part+subject)))
  expect_equal(o_data$conc$data$time, d$conc$time_hr)
  expect_null(o_data$conc$units$timeu)
  # The default single-dose intervals are the usual 0 to 24 hours
  expect_equal(o_data$intervals$end, c(24, Inf, 24, Inf))
})

test_that("timeu alone gives the unit for date-time input", {
  d <- datetime_test_data()
  o_conc <- PKNCAconc(d$conc, conc~time|part+subject, timeu = "min")
  expect_equal(o_conc$units$timeu, "min", ignore_attr = TRUE)
  expect_warning(
    o_data <- PKNCAdata(o_conc, PKNCAdose(d$dose, dose~time|part+subject)),
    class = "pknca_warning_single_dose_aucs_unit"
  )
  expect_equal(o_data$conc$data$time, d$conc$time_hr * 60)
  expect_equal(o_data$conc$units$timeu, "min", ignore_attr = TRUE)
})

test_that("timeu_pref takes precedence over timeu for date-time input", {
  skip_if_not_installed("units")
  d <- datetime_test_data()
  o_conc <- PKNCAconc(d$conc, conc~time|part+subject, concu = "ng/mL", timeu = "min", timeu_pref = "hr")
  # Date-times have no original unit to convert from, so timeu becomes timeu_pref
  expect_equal(o_conc$units$timeu, "hr", ignore_attr = TRUE)
  expect_equal(o_conc$units$timeu_pref, "hr", ignore_attr = TRUE)
  o_data <- PKNCAdata(o_conc, PKNCAdose(d$dose, dose~time|part+subject, doseu = "mg"))
  expect_equal(o_data$conc$data$time, d$conc$time_hr)
  d_nca <- as.data.frame(pk.nca(o_data))
  expect_equal(unique(d_nca$PPORRESU[d_nca$PPTESTCD == "tmax"]), "hr")
  expect_equal(d_nca$PPORRES[d_nca$PPTESTCD == "tmax"], c(2, 2))
})

test_that("The unit for date-time input must be one time unit value", {
  d <- datetime_test_data()
  d$conc$timeu_col <- "hr"
  expect_error(
    PKNCAconc(d$conc, conc~time|part+subject, timeu = "timeu_col"),
    class = "pknca_error_datetime_timeu"
  )
  expect_error(
    PKNCAconc(d$conc, conc~time|part+subject, timeu_pref = "mg"),
    regexp = "must be a time unit",
    class = "pknca_error_datetime_time_unit"
  )
  # A numeric time is unaffected
  expect_equal(PKNCAconc(d$conc, conc~time_hr|part+subject, timeu = "hr")$units$timeu, "hr", ignore_attr = TRUE)
})

test_that("Date times are 08:00, with a warning", {
  skip_if_not_installed("units")
  d_conc <- data.frame(subject = 1, time = as.Date("2024-01-01") + 0:3, conc = c(0, 4, 2, 1))
  d_dose <- data.frame(subject = 1, time = as.Date("2024-01-01"), dose = 1)
  expect_warning(
    o_conc <- PKNCAconc(d_conc, conc~time|subject, timeu_pref = "day"),
    class = "pknca_warning_date_assumed_time"
  )
  expect_warning(
    o_dose <- PKNCAdose(d_dose, dose~time|subject),
    class = "pknca_warning_date_assumed_time"
  )
  expect_warning(
    o_data <- PKNCAdata(o_conc, o_dose),
    class = "pknca_warning_single_dose_aucs_unit"
  )
  expect_equal(o_data$conc$data$time, 0:3)
  expect_equal(o_data$time_reference$time_reference, as.POSIXct("2024-01-01 08:00", tz = "UTC"))

  # A Date takes the time zone of the date-times it is paired with, so 08:00
  # is local 08:00:  2 hours after a 06:00 dose.
  d_dose_dt <- data.frame(subject = 1, time = as.POSIXct("2024-01-01 06:00", tz = "America/New_York"), dose = 1)
  o_data_tz <-
    PKNCAdata(
      o_conc, PKNCAdose(d_dose_dt, dose~time|subject),
      intervals = data.frame(start = 0, end = 3, cmax = TRUE)
    )
  expect_equal(o_data_tz$conc$data$time, 0:3 + 2/24)
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

test_that("Without dose data, each subject's first concentration is the reference", {
  skip_if_not_installed("units")
  d <- datetime_test_data()
  # The first sample of subject 2 is excluded, so its reference is its second
  d$conc$excl <- NA_character_
  d$conc$excl[7] <- "Sample hemolyzed"
  o_conc <- PKNCAconc(d$conc, conc~time|part+subject, exclude = "excl", timeu_pref = "hr")
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 24, cmax = TRUE))
  expect_equal(
    o_data$time_reference,
    data.frame(
      part = "A", subject = 1:2,
      time_reference = d$conc$time[c(1, 8)],
      time_reference_type = "first_conc"
    )
  )
  expect_equal(o_data$conc$data$time, c(0, 1, 2, 4, 8, 24, -1, 0, 1, 3, 7, 23))
  expect_output(
    print(o_data),
    regexp = "; 2 of 2 groups have no dose and use the first concentration.",
    fixed = TRUE
  )
  # Analytes (groups right of the "/") share their subject's reference
  d_conc_analyte <- rbind(cbind(d$conc, analyte = "parent"), cbind(d$conc, analyte = "metabolite"))
  o_data_analyte <-
    PKNCAdata(
      PKNCAconc(d_conc_analyte, conc~time|part+subject/analyte, exclude = "excl", timeu_pref = "hr"),
      intervals = data.frame(start = 0, end = 24, cmax = TRUE)
    )
  expect_equal(o_data_analyte$time_reference, o_data$time_reference)
  # A subject whose concentrations are all excluded uses its first one
  d$conc$excl[1:6] <- "Not dosed"
  o_data_all_excl <-
    PKNCAdata(
      PKNCAconc(d$conc, conc~time|part+subject, exclude = "excl", timeu_pref = "hr"),
      intervals = data.frame(start = 0, end = 24, cmax = TRUE)
    )
  expect_equal(o_data_all_excl$time_reference$time_reference, d$conc$time[c(1, 8)])
})

test_that("Subjects without an included dose use their first concentration, with a warning", {
  skip_if_not_installed("units")
  d <- datetime_test_data()
  o_conc <- PKNCAconc(d$conc, conc~time|part+subject, concu = "ng/mL", timeu_pref = "hr")
  expected_reference <-
    data.frame(
      part = "A", subject = 1:2,
      time_reference = d$conc$time[c(1, 7)],
      time_reference_type = c("first_dose", "first_conc")
    )
  # Automatic intervals need a dose for every subject, so they are given
  intervals <- data.frame(start = 0, end = 24, cmax = TRUE)
  expect_warning(
    o_data <- PKNCAdata(o_conc, PKNCAdose(d$dose[1, ], dose~time|part+subject), intervals = intervals),
    regexp = "part=A, subject=2",
    class = "pknca_warning_datetime_first_conc_reference"
  )
  expect_equal(o_data$time_reference, expected_reference)
  # A subject whose only dose is excluded
  d_dose_excl <- d$dose
  d_dose_excl$excl <- c(NA, "Not given")
  expect_warning(
    o_data_excl <-
      PKNCAdata(o_conc, PKNCAdose(d_dose_excl, dose~time|part+subject, exclude = "excl"), intervals = intervals),
    class = "pknca_warning_datetime_first_conc_reference"
  )
  expect_equal(o_data_excl$time_reference, expected_reference)
  # Subject 2's first sample was at its (excluded) dose time
  expect_equal(o_data_excl$dose$data$time, c(0, 0))
  # Dose data without dose times give every subject its first concentration
  expect_warning(
    o_data_no_time <-
      PKNCAdata(
        o_conc, PKNCAdose(d$dose, dose~.|part+subject),
        intervals = data.frame(start = 0, end = 24, cmax = TRUE)
      ),
    regexp = "subject=1; part=A, subject=2",
    class = "pknca_warning_datetime_first_conc_reference"
  )
  expect_equal(o_data_no_time$time_reference$time_reference_type, c("first_conc", "first_conc"))
  # CDISC results carry the first-concentration reference as PPRFTDTC
  o_nca <- suppressWarnings(pk.nca(o_data))
  d_cdisc <- as.data.frame(o_nca, out_format = "cdisc")
  expect_equal(
    unique(d_cdisc$PPRFTDTC[d_cdisc$subject == 2]),
    lubridate::format_ISO8601(d$conc$time[7], precision = "ymdhms")
  )
})

test_that("Without doses, the reference is per period in a crossover", {
  skip_if_not_installed("units")
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  d_conc <-
    data.frame(
      subject = rep(1:2, each = 4),
      period = rep(rep(1:2, each = 2), 2),
      time = t0 + c(0, 2, 168, 170, 1, 3, 169, 171) * 3600,
      conc = c(0, 5, 0, 4, 0, 6, 0, 3)
    )
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|period+subject, timeu_pref = "hr"),
      intervals = data.frame(start = 0, end = 24, cmax = TRUE)
    )
  expect_equal(o_data$conc$data$time, rep(c(0, 2), 4))
  expect_equal(o_data$time_reference$time_reference_type, rep("first_conc", 4))
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
    data.frame(
      part = c("MAD", "SAD"), subject = 1, time_reference = t0 + c(180, 0) * 3600,
      time_reference_type = "first_dose"
    )
  )
  # Manually-given intervals are relative to the reference:  0 to 12 hours holds
  # only the concentration 1 hour after the MAD reference and the concentrations
  # at 0 and 1 hour after the SAD reference.
  o_nca <- pk.nca(o_data)
  d_nca <- as.data.frame(o_nca)
  expect_equal(d_nca$part[d_nca$PPTESTCD == "cmax"], c("MAD", "SAD"))
  expect_equal(d_nca$PPORRES[d_nca$PPTESTCD == "cmax"], c(4, 3))
})

test_that("A dose formula without the subject is an error, not a pooled reference", {
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  # Crossover:  pooling one reference per period would put every subject's
  # times relative to whichever subject was dosed first.
  d_conc <-
    data.frame(
      subject = rep(1:2, each = 2),
      period = 1,
      time = t0 + c(0, 3600, 1800, 5400),
      conc = c(0, 2, 0, 2.5)
    )
  d_dose <- data.frame(subject = 1:2, period = 1, time = t0 + c(0, 1800), dose = 1)
  expect_error(
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|period+subject),
      PKNCAdose(d_dose, dose~time|period)
    ),
    regexp = "conc ~ time | period + subject; dose formula: dose ~ time | period",
    fixed = TRUE,
    class = "pknca_error_datetime_subject_not_grouped"
  )
  # A subject given by name rather than as a group is required, too
  expect_error(
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|period, subject = "subject"),
      PKNCAdose(d_dose, dose~time|period)
    ),
    class = "pknca_error_datetime_subject_not_grouped"
  )
})

test_that("Each crossover subject's reference is its own dose", {
  skip_if_not_installed("units")
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  # Subject 2 is dosed 30 minutes after subject 1 in each period; periods are
  # one week apart.
  d_conc <-
    data.frame(
      subject = rep(1:2, each = 4),
      period = rep(rep(1:2, each = 2), 2),
      time = t0 + c(0, 2, 168, 170, 0.5, 2.5, 168.5, 170.5) * 3600,
      conc = c(0, 5, 0, 4, 0, 6, 0, 3)
    )
  d_dose <-
    data.frame(
      subject = rep(1:2, each = 2),
      period = rep(1:2, 2),
      time = t0 + c(0, 168, 0.5, 168.5) * 3600,
      dose = 1
    )
  # With the period in the dose formula, the reference is per period
  o_data_period <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|period+subject, timeu_pref = "hr"),
      PKNCAdose(d_dose, dose~time|period+subject)
    )
  expect_equal(o_data_period$conc$data$time, rep(c(0, 2), 4))
  expect_equal(o_data_period$time_reference$time_reference, t0 + c(0, 0.5, 168, 168.5) * 3600)
  # With only the subject in the dose formula, the reference is each subject's
  # period-1 dose
  o_data_subject <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|period+subject, timeu_pref = "hr"),
      PKNCAdose(d_dose, dose~time|subject),
      intervals = data.frame(start = c(0, 168), end = c(24, 192), cmax = TRUE)
    )
  expect_equal(o_data_subject$conc$data$time, rep(c(0, 2, 168, 170), 2))
  expect_equal(
    o_data_subject$time_reference,
    data.frame(subject = 1:2, time_reference = t0 + c(0, 0.5) * 3600, time_reference_type = "first_dose")
  )
})

test_that("Sparse date-time data take one reference per group", {
  # PKNCA requires every subject in a sparse group to share the group's dosing,
  # so the reference is the group's dose, or without doses the group's first
  # sample (not each animal's first sample).
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  d_conc <-
    data.frame(
      treatment = rep(c("A", "B"), each = 4),
      id = rep(1:4, each = 2),
      time = t0 + c(0, 3600, 1800, 5400, 7200, 10800, 9000, 12600),
      conc = c(0, 2, 1, 2.5, 0, 2, 1, 2.5)
    )
  d_dose <- data.frame(treatment = c("A", "B"), time = t0 + c(0, 7200), dose = 1)
  o_conc <- PKNCAconc(d_conc, conc~time|treatment, subject = "id", sparse = TRUE)
  o_data <-
    PKNCAdata(
      o_conc, PKNCAdose(d_dose, dose~time|treatment),
      intervals = data.frame(start = 0, end = 2, cmax = TRUE)
    )
  expect_equal(o_data$conc$data_sparse$time, rep(c(0, 1, 0.5, 1.5), 2))
  expect_equal(
    o_data$time_reference,
    data.frame(treatment = c("A", "B"), time_reference = t0 + c(0, 7200), time_reference_type = "first_dose")
  )
  o_data_no_dose <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 2, cmax = TRUE))
  expect_equal(o_data_no_dose$conc$data_sparse$time, rep(c(0, 1, 0.5, 1.5), 2))
  expect_equal(o_data_no_dose$time_reference$time_reference_type, c("first_conc", "first_conc"))
})

test_that("Ungrouped date-time data use the single first dose", {
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  o_data <-
    PKNCAdata(
      PKNCAconc(data.frame(time = t0 + c(0, 1, 2) * 3600, conc = c(0, 2, 1)), conc~time),
      PKNCAdose(data.frame(time = t0 + 3600, dose = 1), dose~time),
      intervals = data.frame(start = 0, end = 1, cmax = TRUE)
    )
  expect_equal(o_data$conc$data$time, c(-1, 0, 1))
  expect_equal(o_data$time_reference, data.frame(time_reference = t0 + 3600, time_reference_type = "first_dose"))
})

test_that("Numeric durations are in the time unit; difftime durations are converted", {
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  d_conc <-
    data.frame(subject = 1, time = t0 + c(0, 6, 12) * 3600, conc = c(0, 5, 2), dur = c(6, 6, 12), vol = 1)
  d_dose <- data.frame(subject = 1, time = t0, dose = 10, dur = 0.5)
  intervals <- data.frame(start = 0, end = 24, cmax = TRUE)
  # Numeric durations are already in the unit of the analysis (hours here)
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|subject, duration = "dur", volume = "vol"),
      PKNCAdose(d_dose, dose~time|subject, route = "intravascular", duration = "dur"),
      intervals = intervals
    )
  expect_equal(o_data$conc$data$dur, c(6, 6, 12))
  expect_equal(o_data$dose$data$dur, 0.5)
  # difftime durations are converted exactly, here to days
  d_conc$dur <- as.difftime(c(6, 6, 12), units = "hours")
  d_dose$dur <- as.difftime(30, units = "mins")
  expect_no_warning(
    o_data_day <-
      PKNCAdata(
        PKNCAconc(d_conc, conc~time|subject, duration = "dur", volume = "vol", timeu_pref = "day"),
        PKNCAdose(d_dose, dose~time|subject, route = "intravascular", duration = "dur"),
        intervals = intervals
      )
  )
  expect_equal(o_data_day$conc$data$time, c(0, 0.25, 0.5))
  expect_equal(o_data_day$conc$data$dur, c(0.25, 0.25, 0.5))
  expect_equal(o_data_day$dose$data$dur, 0.5 / 24)
  # A scalar difftime duration works, too
  o_data_scalar <-
    PKNCAdata(
      PKNCAconc(d_conc[, c("subject", "time", "conc")], conc~time|subject),
      PKNCAdose(d_dose, dose~time|subject, route = "intravascular", duration = as.difftime(15, units = "mins")),
      intervals = intervals
    )
  expect_equal(o_data_scalar$dose$data$duration, 0.25)
  # Negative difftime durations are still invalid
  d_dose$dur <- as.difftime(-30, units = "mins")
  expect_error(
    PKNCAdose(d_dose, dose~time|subject, route = "intravascular", duration = "dur"),
    class = "pknca_error_dose_invalid_duration"
  )
})

test_that("difftime durations with numeric time need a time unit", {
  d_conc <- data.frame(subject = 1, time = c(0, 6, 12), conc = c(0, 5, 2))
  d_dose <- data.frame(subject = 1, time = 0, dose = 10, dur = as.difftime(30, units = "mins"))
  o_dose <- PKNCAdose(d_dose, dose~time|subject, route = "intravascular", duration = "dur")
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|subject, timeu = "hr"), o_dose,
      intervals = data.frame(start = 0, end = 12, cmax = TRUE)
    )
  expect_equal(o_data$dose$data$dur, 0.5)
  expect_error(
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|subject), o_dose,
      intervals = data.frame(start = 0, end = 12, cmax = TRUE)
    ),
    class = "pknca_error_difftime_duration_unit"
  )
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

test_that("The nominal time is not converted", {
  d <- datetime_test_data()
  o_data <-
    PKNCAdata(
      PKNCAconc(d$conc, conc~time|part+subject, time.nominal = "time_hr"),
      PKNCAdose(d$dose, dose~time|part+subject)
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

test_that("PPRFTDTC is an ISO 8601 date-time in the data's time zone", {
  # The reference 08:00 in New York is reported as 08:00, without an offset
  d <- datetime_test_data(tz = "America/New_York")
  o_nca <-
    pk.nca(PKNCAdata(
      PKNCAconc(d$conc, conc~time|part+subject),
      PKNCAdose(d$dose, dose~time|part+subject)
    ))
  d_cdisc <- as.data.frame(o_nca, out_format = "cdisc")
  expect_equal(sort(unique(d_cdisc$PPRFTDTC)), c("2024-03-01T08:00:00", "2024-03-01T08:30:00"))
})

# Two subjects without dosing data; each subject's reference is its first
# sample (08:00 and 09:00), with samples 0, 1, 2, 4, and 8 hours later.
datetime_interval_data <- function() {
  t0 <- as.POSIXct("2024-03-01 08:00:00", tz = "UTC")
  rel <- c(0, 1, 2, 4, 8)
  d_conc <-
    data.frame(
      subject = rep(1:2, each = 5),
      time = t0 + c(rel, rel + 1) * 3600,
      conc = rep(c(1, 4, 6, 3, 1), 2)
    )
  list(
    t0 = t0,
    o_conc = PKNCAconc(d_conc, conc~time|subject, concu = "ng/mL", timeu_pref = "hr")
  )
}

test_that("An absolute date-time window gives each subject its own relative interval", {
  skip_if_not_installed("units")
  d <- datetime_interval_data()
  intervals <- data.frame(start = d$t0 + 2 * 3600, end = d$t0 + 4 * 3600, aucint.last = TRUE)
  o_data <- PKNCAdata(d$o_conc, intervals = intervals)
  # One row per subject:  10:00 to 12:00 is 2 to 4 hours after subject 1's
  # reference and 1 to 3 hours after subject 2's
  expect_equal(o_data$intervals$subject, 1:2)
  expect_equal(o_data$intervals$start, c(2, 1))
  expect_equal(o_data$intervals$end, c(4, 3))
  expect_equal(o_data$intervals$interval_time_kind, c("datetime", "datetime"))
  d_nca <- as.data.frame(pk.nca(o_data))
  # Linear-up/log-down by hand.  Subject 1:  6 to 3 over 2 to 4 hours (log).
  # Subject 2:  4 to 6 over 1 to 2 hours (linear), then 6 at 2 hours to the
  # log-interpolated concentration at 3 hours (log).
  conc_3 <- 6 * (3/6)^(1/2)
  expected <-
    c(
      (6 - 3) * 2 / log(6/3),
      (4 + 6) / 2 + (6 - conc_3) / log(6/conc_3)
    )
  expect_equal(d_nca$PPORRES[d_nca$PPTESTCD == "aucint.last"], expected, tolerance = 1e-10)
})

test_that("Grouped date-time interval rows use their group's reference", {
  d <- datetime_interval_data()
  intervals <-
    data.frame(
      subject = 1:2,
      start = d$t0 + c(2, 3) * 3600,
      end = d$t0 + c(4, 5) * 3600,
      cmax = TRUE
    )
  o_data <- PKNCAdata(d$o_conc, intervals = intervals)
  expect_equal(o_data$intervals$subject, 1:2)
  expect_equal(o_data$intervals$start, c(2, 2))
  expect_equal(o_data$intervals$end, c(4, 4))
  # A row for a group with no time reference is an error
  expect_error(
    PKNCAdata(d$o_conc, intervals = data.frame(subject = 3L, start = d$t0, end = d$t0 + 3600, cmax = TRUE)),
    regexp = "rows 1 match no group",
    class = "pknca_error_interval_datetime_no_reference"
  )
})

test_that("Date interval bounds are 08:00, with a warning", {
  d <- datetime_interval_data()
  intervals <- data.frame(start = as.Date("2024-03-01"), end = as.Date("2024-03-02"), cmax = TRUE)
  expect_warning(
    expect_warning(
      o_data <- PKNCAdata(d$o_conc, intervals = intervals),
      regexp = "The interval time column ('start') is a Date",
      fixed = TRUE,
      class = "pknca_warning_date_assumed_time"
    ),
    regexp = "The interval time column ('end') is a Date",
    fixed = TRUE,
    class = "pknca_warning_date_assumed_time"
  )
  # 08:00 on each date, relative to references at 08:00 and 09:00
  expect_equal(o_data$intervals$start, c(0, -1))
  expect_equal(o_data$intervals$end, c(24, 23))
})

test_that("An infinite interval end stays infinite; an infinite start is an error", {
  d <- datetime_interval_data()
  start <- d$t0 + 2 * 3600
  o_data_num <- PKNCAdata(d$o_conc, intervals = data.frame(start = start, end = Inf, cmax = TRUE))
  expect_equal(o_data_num$intervals$start, c(2, 1))
  expect_equal(o_data_num$intervals$end, c(Inf, Inf))
  # A POSIXct Inf end behaves exactly like a numeric Inf end
  o_data_posix <-
    PKNCAdata(d$o_conc, intervals = data.frame(start = start, end = as.POSIXct(Inf, tz = "UTC"), cmax = TRUE))
  expect_equal(o_data_posix$intervals, o_data_num$intervals)
  expect_equal(as.data.frame(pk.nca(o_data_posix)), as.data.frame(pk.nca(o_data_num)))
  expect_error(
    PKNCAdata(
      d$o_conc,
      intervals = data.frame(start = as.POSIXct(-Inf, tz = "UTC"), end = d$t0, cmax = TRUE)
    ),
    class = "pknca_error_interval_datetime_start_infinite"
  )
})

test_that("Date-time intervals must pair with date-time bounds and date-time data", {
  d <- datetime_interval_data()
  expect_error(
    PKNCAdata(d$o_conc, intervals = data.frame(start = d$t0, end = 24, cmax = TRUE)),
    class = "pknca_error_interval_datetime_mixed"
  )
  expect_error(
    PKNCAdata(d$o_conc, intervals = data.frame(start = 0, end = d$t0 + 3600, cmax = TRUE)),
    class = "pknca_error_interval_datetime_mixed"
  )
  o_conc_num <- PKNCAconc(data.frame(subject = 1, time = 0:2, conc = c(1, 2, 1)), conc~time|subject)
  expect_error(
    PKNCAdata(o_conc_num, intervals = data.frame(start = d$t0, end = d$t0 + 3600, cmax = TRUE)),
    class = "pknca_error_interval_datetime_numeric_data"
  )
  expect_error(
    PKNCAdata(
      d$o_conc,
      intervals =
        data.frame(
          start = as.POSIXct("2024-03-01 10:00", tz = "America/New_York"),
          end = as.POSIXct("2024-03-01 12:00", tz = "America/New_York"),
          cmax = TRUE
        )
    ),
    class = "pknca_error_datetime_mixed_tz"
  )
  # A subject named outside the groups cannot carry its reference into the
  # intervals
  t0 <- d$t0
  d_conc_ungrouped <- data.frame(id = 1:2, period = 1, time = t0 + c(0, 3600), conc = 1)
  expect_error(
    PKNCAdata(
      PKNCAconc(d_conc_ungrouped, conc~time|period, subject = "id", timeu_pref = "hr"),
      intervals = data.frame(start = t0, end = t0 + 3600, cmax = TRUE)
    ),
    class = "pknca_error_interval_datetime_groups"
  )
})

test_that("Date-time intervals set after PKNCAdata() are converted", {
  skip_if_not_installed("units")
  d <- datetime_interval_data()
  intervals_dt <- data.frame(start = d$t0 + 2 * 3600, end = d$t0 + 4 * 3600, aucint.last = TRUE)
  o_data_constructed <- PKNCAdata(d$o_conc, intervals = intervals_dt)
  expected <- as.data.frame(pk.nca(o_data_constructed))
  o_data <- PKNCAdata(d$o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  # Through set_intervals()
  o_data_set <- set_intervals(o_data, intervals_dt)
  expect_equal(check.interval.specification(o_data_set$intervals), o_data_constructed$intervals)
  # Through direct assignment, converted by pk.nca()
  o_data_direct <- o_data
  o_data_direct$intervals <- intervals_dt
  o_nca_direct <- pk.nca(o_data_direct)
  expect_equal(as.data.frame(o_nca_direct), expected)
  expect_equal(o_nca_direct$data$intervals$start, c(2, 1))
})

test_that("Converting intervals is idempotent and marks relative rows", {
  d <- datetime_interval_data()
  o_data <-
    PKNCAdata(d$o_conc, intervals = data.frame(start = d$t0, end = d$t0 + 3600, cmax = TRUE))
  expect_equal(pknca_interval_times_to_numeric(o_data$intervals, o_data), o_data$intervals)
  # Numeric intervals without a kind column are unchanged
  numeric_intervals <- data.frame(start = 0, end = 1, cmax = TRUE)
  expect_equal(pknca_interval_times_to_numeric(numeric_intervals, o_data), numeric_intervals)
  # Rows added later without a kind are relative
  added <- rbind(o_data$intervals, o_data$intervals[1, ])
  added$interval_time_kind[3] <- NA
  expect_equal(
    pknca_interval_times_to_numeric(added, o_data)$interval_time_kind,
    c("datetime", "datetime", "relative")
  )
  # Malformed intervals are left for the other checks
  expect_equal(pknca_interval_times_to_numeric(data.frame(start = 0), o_data), data.frame(start = 0))
})
