# --- Tests for shared helpers ------------------------------------------------

test_that("std_dtc_to_rdate parses mixed precision datetimes", {
  result <- std_dtc_to_rdate(c(
    "2024-01-01T08:00:00",
    "2024-01-01T10:30",
    "2024-01-02T14",
    "2024-01-03"
  ))
  expect_s3_class(result, "POSIXct")
  expect_equal(length(result), 4)
  expect_false(any(is.na(result)))
  # Full precision
  expect_equal(format(result[1], "%H:%M:%S"), "08:00:00")
  # Minute precision
  expect_equal(format(result[2], "%H:%M"), "10:30")
})

test_that("parse_iso8601_duration handles standard durations", {
  expect_equal(parse_iso8601_duration("PT1H"), 1)
  expect_equal(parse_iso8601_duration("PT2H"), 2)
  expect_equal(parse_iso8601_duration("PT30M"), 0.5)
  expect_equal(parse_iso8601_duration("PT1H30M"), 1.5)
  expect_equal(parse_iso8601_duration("PT3600S"), 1)
  expect_true(is.na(parse_iso8601_duration(NA)))
  expect_true(is.na(parse_iso8601_duration("not_a_duration")))
})

test_that("parse_iso8601_duration handles negative elapsed times", {
  # EXELTM can encode pre-dose times as PT-0.083H
  expect_equal(parse_iso8601_duration("PT-0.083H"), -0.083)
})

test_that("parse_iso8601_duration handles vectors", {
  result <- parse_iso8601_duration(c("PT1H", "PT2H", NA, "PT30M"))
  expect_equal(result, c(1, 2, NA, 0.5))
})

test_that("route_cdisc_to_pknca maps routes correctly", {
  expect_equal(route_cdisc_to_pknca("ORAL"), "extravascular")
  expect_equal(route_cdisc_to_pknca("INTRAVENOUS INFUSION"), "intravascular")
  expect_equal(route_cdisc_to_pknca("INTRAVENOUS BOLUS"), "intravascular")
  expect_equal(route_cdisc_to_pknca("SUBCUTANEOUS"), "extravascular")
  expect_equal(route_cdisc_to_pknca("INTRAMUSCULAR"), "extravascular")
})

# --- Tests for ex_to_PKNCAdose -----------------------------------------------

test_that("ex_to_PKNCAdose returns a PKNCAdose object", {
  ex <- data.frame(
    USUBJID = c("SUBJ-001", "SUBJ-001"),
    EXTRT   = c("DRUG A", "DRUG A"),
    EXDOSE  = c(100, 100),
    EXDOSU  = "mg",
    EXROUTE = "ORAL",
    EXSTDTC = c("2024-01-01T08:00", "2024-01-08T08:00"),
    EXENDTC = c(NA, NA),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  expect_s3_class(result, "PKNCAdose")
})

test_that("ex_to_PKNCAdose handles oral doses with NA EXENDTC", {
  ex <- data.frame(
    USUBJID = c("SUBJ-001", "SUBJ-001"),
    EXTRT   = c("DRUG A", "DRUG A"),
    EXDOSE  = c(100, 100),
    EXDOSU  = "mg",
    EXROUTE = "ORAL",
    EXSTDTC = c("2024-01-01T08:00", "2024-01-08T08:00"),
    EXENDTC = c(NA, NA),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  # Duration should be 0 for oral doses with NA EXENDTC
  expect_true(all(result$data$EXDUR == 0))
})

test_that("ex_to_PKNCAdose derives duration from EXENDTC for IV infusions", {
  ex <- data.frame(
    USUBJID = "SUBJ-001",
    EXTRT   = "DRUG B",
    EXDOSE  = 50,
    EXDOSU  = "mg",
    EXROUTE = "INTRAVENOUS INFUSION",
    EXSTDTC = "2024-01-01T09:00:00",
    EXENDTC = "2024-01-01T10:00:00",
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  expect_equal(result$data$EXDUR, 1)
})

test_that("ex_to_PKNCAdose maps routes correctly", {
  ex <- data.frame(
    USUBJID = c("SUBJ-001", "SUBJ-002", "SUBJ-003", "SUBJ-004"),
    EXTRT   = "DRUG A",
    EXDOSE  = 100,
    EXDOSU  = "mg",
    EXROUTE = c("ORAL", "INTRAVENOUS INFUSION", "INTRAVENOUS BOLUS", "SUBCUTANEOUS"),
    EXSTDTC = "2024-01-01T08:00",
    EXENDTC = c(NA, "2024-01-01T09:00", "2024-01-01T08:00", NA),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  route_col <- result$columns$route
  # Oral and subcutaneous are extravascular; IV infusion and bolus are intravascular
  expect_equal(
    result$data[[route_col]],
    c("extravascular", "intravascular", "intravascular", "extravascular")
  )
})

test_that("ex_to_PKNCAdose computes relative time from first dose per subject", {
  ex <- data.frame(
    USUBJID = c("SUBJ-001", "SUBJ-001", "SUBJ-002", "SUBJ-002"),
    EXTRT   = "DRUG A",
    EXDOSE  = 100,
    EXDOSU  = "mg",
    EXROUTE = "ORAL",
    EXSTDTC = c("2024-01-01T08:00", "2024-01-02T08:00",
                "2024-01-01T10:00", "2024-01-02T10:00"),
    EXENDTC = c(NA, NA, NA, NA),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  # First dose for each subject should be time 0, second dose at 24h
  expect_equal(result$data$AFRLT, c(0, 24, 0, 24))
})

test_that("ex_to_PKNCAdose handles mixed datetime precision", {
  ex <- data.frame(
    USUBJID = c("SUBJ-001", "SUBJ-001", "SUBJ-001"),
    EXTRT   = "DRUG A",
    EXDOSE  = 100,
    EXDOSU  = "mg",
    EXROUTE = "ORAL",
    EXSTDTC = c("2024-01-01T08:00:00", "2024-01-01T10:30", "2024-01-02"),
    EXENDTC = c(NA, NA, NA),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  expect_s3_class(result, "PKNCAdose")
  # All dates should be parsed (no NAs in AFRLT)
  expect_false(any(is.na(result$data$AFRLT)))
})

test_that("ex_to_PKNCAdose derives EXELTM from EXRFTDTC when available", {
  ex <- data.frame(
    USUBJID  = c("SUBJ-001", "SUBJ-001"),
    EXTRT    = "DRUG A",
    EXDOSE   = 100,
    EXDOSU   = "mg",
    EXROUTE  = "ORAL",
    EXSTDTC  = c("2024-01-01T08:00", "2024-01-02T08:00"),
    EXENDTC  = c(NA, NA),
    EXRFTDTC = c("2024-01-01T08:00", "2024-01-01T08:00"),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  # EXELTM should be 0 for first dose, 24 for second
  expect_equal(result$data$EXELTM, c(0, 24))
})


test_that("ex_to_PKNCAdose uses pre-existing EXDUR without deriving", {
  ex <- data.frame(
    USUBJID = c("SUBJ-001", "SUBJ-001"),
    EXTRT   = "DRUG B",
    EXDOSE  = c(50, 50),
    EXDOSU  = "mg",
    EXROUTE = "INTRAVENOUS INFUSION",
    EXSTDTC = c("2024-01-01T09:00:00", "2024-01-08T09:00:00"),
    EXENDTC = c("2024-01-01T10:00:00", "2024-01-08T10:00:00"),
    # Pre-existing EXDUR that differs from EXENDTC - EXSTDTC (1h)
    # e.g. actual infusion was 0.75h, recorded separately from collection times
    EXDUR   = c(0.75, 0.5),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  # Should use the provided EXDUR, not derive from EXENDTC - EXSTDTC
  expect_equal(result$data$EXDUR, c(0.75, 0.5))
})

test_that("ex_to_PKNCAdose uses pre-existing EXELTM without deriving", {
  ex <- data.frame(
    USUBJID  = c("SUBJ-001", "SUBJ-001"),
    EXTRT    = "DRUG A",
    EXDOSE   = c(100, 100),
    EXDOSU   = "mg",
    EXROUTE  = "ORAL",
    EXSTDTC  = c("2024-01-01T08:00", "2024-01-02T08:00"),
    EXENDTC  = c(NA, NA),
    EXRFTDTC = c("2024-01-01T08:00", "2024-01-01T08:00"),
    # Pre-existing EXELTM that differs from EXSTDTC - EXRFTDTC (0h, 24h)
    # e.g. protocol-defined nominal elapsed times
    EXELTM   = c(0, 168),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  # Should use the provided EXELTM, not derive from EXSTDTC - EXRFTDTC
  expect_equal(result$data$EXELTM, c(0, 168))
})

test_that("ex_to_PKNCAdose works without optional columns", {
  # Minimal dataset: no EXENDTC, no EXRFTDTC, no EXROUTE, no EXDOSU
  ex <- data.frame(
    USUBJID = c("SUBJ-001", "SUBJ-001"),
    EXTRT   = "DRUG A",
    EXDOSE  = c(100, 100),
    EXSTDTC = c("2024-01-01T08:00", "2024-01-08T08:00"),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  expect_s3_class(result, "PKNCAdose")
})

test_that("ex_to_PKNCAdose derives NFRLT from EXRFTDTC and numeric EXELTM", {
  ex <- data.frame(
    USUBJID  = c("S1", "S1"),
    EXTRT    = "DRUG A",
    EXDOSE   = 100,
    EXDOSU   = "mg",
    EXROUTE  = "ORAL",
    EXSTDTC  = c("2024-01-01T08:00:00", "2024-01-02T08:00:00"),
    EXENDTC  = NA,
    EXRFTDTC = c("2024-01-01T08:00:00", "2024-01-02T08:00:00"),
    EXELTM   = c(0, 24),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  expect_true("NFRLT" %in% names(result$data))
  # Dose 1: (EXRFTDTC + 0h) - min(EXRFTDTC) = 0
  # Dose 2: (EXRFTDTC + 24h) - min(EXRFTDTC) = 48
  #   because EXRFTDTC[2] is already 24h after EXRFTDTC[1], plus EXELTM=24
  expect_equal(result$data$NFRLT, c(0, 48))
})

test_that("ex_to_PKNCAdose derives NFRLT from EXRFTDTC and ISO 8601 EXELTM", {
  ex <- data.frame(
    USUBJID  = c("S1", "S1"),
    EXTRT    = "DRUG A",
    EXDOSE   = 100,
    EXDOSU   = "mg",
    EXROUTE  = "ORAL",
    EXSTDTC  = c("2024-01-01T08:00:00", "2024-01-02T08:00:00"),
    EXENDTC  = NA,
    EXRFTDTC = c("2024-01-01T08:00:00", "2024-01-01T08:00:00"),
    EXELTM   = c("PT0H", "PT24H"),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  expect_true("NFRLT" %in% names(result$data))
  # Same EXRFTDTC for both, so:
  # Dose 1: (EXRFTDTC + 0h) - EXRFTDTC = 0
  # Dose 2: (EXRFTDTC + 24h) - EXRFTDTC = 24
  expect_equal(result$data$NFRLT, c(0, 24))
  # EXELTM should be parsed to numeric
  expect_equal(result$data$EXELTM, c(0, 24))
})

test_that("ex_to_PKNCAdose uses NFRLT as time.nominal", {
  ex <- data.frame(
    USUBJID  = c("S1", "S1"),
    EXTRT    = "DRUG A",
    EXDOSE   = 100,
    EXDOSU   = "mg",
    EXROUTE  = "ORAL",
    EXSTDTC  = c("2024-01-01T08:00:00", "2024-01-02T08:00:00"),
    EXENDTC  = NA,
    EXRFTDTC = c("2024-01-01T08:00:00", "2024-01-01T08:00:00"),
    EXELTM   = c(0, 24),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  # time.nominal should point to NFRLT
  expect_equal(result$columns$time.nominal, "NFRLT")
})

test_that("ex_to_PKNCAdose skips NFRLT when EXRFTDTC is absent", {
  ex <- data.frame(
    USUBJID = c("S1", "S1"),
    EXTRT   = "DRUG A",
    EXDOSE  = 100,
    EXDOSU  = "mg",
    EXROUTE = "ORAL",
    EXSTDTC = c("2024-01-01T08:00", "2024-01-02T08:00"),
    EXENDTC = NA,
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  expect_false("NFRLT" %in% names(result$data))
})

test_that("ex_to_PKNCAdose derives NFRLT per treatment group", {
  ex <- data.frame(
    USUBJID  = c("S1", "S1", "S1", "S1"),
    EXTRT    = c("DRUG A", "DRUG A", "DRUG B", "DRUG B"),
    EXDOSE   = 100,
    EXDOSU   = "mg",
    EXROUTE  = "ORAL",
    EXSTDTC  = c("2024-01-01T08:00", "2024-01-02T08:00",
                 "2024-01-01T10:00", "2024-01-02T10:00"),
    EXENDTC  = NA,
    EXRFTDTC = c("2024-01-01T08:00", "2024-01-01T08:00",
                 "2024-01-01T10:00", "2024-01-01T10:00"),
    EXELTM   = c(0, 24, 0, 24),
    stringsAsFactors = FALSE
  )
  result <- ex_to_PKNCAdose(ex)
  expect_true("NFRLT" %in% names(result$data))
  # Each treatment group has its own nominal_ref = min(EXRFTDTC)
  # DRUG A: NFRLT = (EXRFTDTC + EXELTM) - min(EXRFTDTC_A) = 0, 24
  # DRUG B: NFRLT = (EXRFTDTC + EXELTM) - min(EXRFTDTC_B) = 0, 24
  expect_equal(result$data$NFRLT, c(0, 24, 0, 24))
})
