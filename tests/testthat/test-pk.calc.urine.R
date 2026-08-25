test_that("pk.calc.volpk", {
  expect_equal(pk.calc.volpk(c(1, 2, 3)), 6)
  expect_equal(pk.calc.volpk(c(1, NA, 3)), NA_real_)
  expect_equal(pk.calc.volpk(NA), NA_real_)
  expect_equal(pk.calc.volpk(numeric()), NA_real_)
})

test_that("pk.calc.ae", {
  expect_equal(
    pk.calc.ae(conc=1:5, volume=1:5),
    sum((1:5)^2)
  )
  expect_equal(
    pk.calc.ae(conc = NA, volume = NA),
    structure(NA_real_, exclude = "All concentrations and volumes are missing")
  )
  expect_equal(
    pk.calc.ae(conc = c(1, NA), volume = c(1, NA)),
    structure(NA_real_, exclude = "1 of 2 concentrations and volumes are missing")
  )
  expect_equal(
    pk.calc.ae(conc = c(NA, NA), volume = c(1, 1)),
    structure(NA_real_, exclude = "All concentrations are missing")
  )
  expect_equal(
    pk.calc.ae(conc = c(1, NA), volume = c(1, 1)),
    structure(NA_real_, exclude = "1 of 2 concentrations are missing")
  )
  expect_equal(
    pk.calc.ae(conc = c(1, 1), volume = c(NA, NA)),
    structure(NA_real_, exclude = "All volumes are missing")
  )
  expect_equal(
    pk.calc.ae(conc = c(1, 1), volume = c(NA, 1)),
    structure(NA_real_, exclude = "1 of 2 volumes are missing")
  )
  expect_equal(
    pk.calc.ae(conc = c(NA, NA, 1, 1), volume = c(NA, 1, NA, 1)),
    structure(NA_real_, exclude = "1 of 4 concentrations and volumes are missing; 1 of 4 concentrations are missing; 1 of 4 volumes are missing")
  )
})

test_that("pk.calc.clr", {
  expect_equal(pk.calc.clr(ae=1, auc=10),
               0.1,
               info="CLr is calculated correctly with both scalars")
  expect_equal(pk.calc.clr(ae=c(1, 2), auc=10),
               0.3,
               info="CLr is calculated correctly with a vector Ae and a scalar AUC")
  expect_equal(pk.calc.clr(ae=c(1, 2), auc=c(1, 10)),
               c(3, 0.3),
               info="CLr is calculated correctly with both vectors (but that is not the likely calculation method)")
})

test_that("pk.calc.fe", {
  expect_equal(pk.calc.fe(1, 10),
               0.1,
               info="fe is calculated correctly with both scalars")
  expect_equal(pk.calc.fe(c(1, 2), 10),
               0.3,
               info="fe is calculated correctly with both vector/scalar")
})

test_that("pk.calc.ertlst", {
  # All NA
  expect_equal(
    pk.calc.ertlst(conc = c(NA, NA), volume = c(1, 1), time = c(0, 1), duration.conc = c(1, 1)),
    structure(NA_real_, exclude = "All concentrations are missing")
  )
  expect_equal(
    pk.calc.ertlst(conc = c(NA, NA), volume = c(NA, NA), time = c(0, 1), duration.conc = c(1, 1)),
    structure(NA_real_, exclude = "All concentrations and volumes are missing")
  )
  # All 0 or NA
  expect_equal(
    pk.calc.ertlst(conc = c(0, NA), volume = c(1, 1), time = c(0, 1), duration.conc = c(1, 1)),
    structure(0, exclude = "1 of 2 concentrations are missing")
  )
  # Normal case
  expect_equal(
    pk.calc.ertlst(conc = c(1, 2, 0), volume = c(1, 1, 1), time = c(0, 1, 2), duration.conc = c(1, 1, 1)),
    max(c(0, 1) + 1/2)
  )
})

test_that("pk.calc.ermax", {
  # All NA
  expect_equal(
    pk.calc.ermax(conc = c(NA, NA), volume = c(1, 1), time = c(0, 1), duration.conc = c(1, 1)),
    structure(NA_real_, exclude = "All concentrations are missing")
  )
  # Concentrations present but all volumes NA → all er values are NA
  expect_equal(
    pk.calc.ermax(conc = c(1, 2), volume = c(NA, NA), time = c(0, 1), duration.conc = c(1, 1)),
    structure(NA_real_, exclude = "All volumes are missing")
  )
  # Normal case
  expect_equal(
    pk.calc.ermax(conc = c(1, 2, 3), volume = c(2, 2, 2), time = c(0, 1, 2), duration.conc = c(2, 2, 2)),
    max(c(1, 2, 3) * 2 / 2)
  )
})

test_that("pk.calc.ertmax", {
  # All NA or 0
  expect_equal(
    pk.calc.ertmax(conc = c(NA, 0), volume = c(1, 1), time = c(0, 1), duration.conc = c(1, 1)),
    structure(NA_real_, exclude = "1 of 2 concentrations are missing")
  )
  # Normal case, last tmax
  expect_equal(
    pk.calc.ertmax(conc = c(1, 3, 2), volume = c(2, 2, 2), time = c(0, 1, 2), duration.conc = c(2, 2, 2), first.tmax = FALSE),
    (1 + 2/2)
  )
  # Normal case, first tmax
  expect_equal(
    pk.calc.ertmax(conc = c(1, 3, 2), volume = c(2, 2, 2), time = c(0, 1, 2), duration.conc = c(2, 2, 2), first.tmax = TRUE),
    (1 + 2/2)
  )
  # Multiple maxima
  expect_equal(
    pk.calc.ertmax(conc = c(1, 3, 3), volume = c(2, 2, 2), time = c(0, 1, 2), duration.conc = c(2, 2, 2), first.tmax = TRUE),
    (1 + 2/2)
  )
  expect_equal(
    pk.calc.ertmax(conc = c(1, 3, 3), volume = c(2, 2, 2), time = c(0, 1, 2), duration.conc = c(2, 2, 2), first.tmax = FALSE),
    (2 + 2/2)
  )
})

test_that("generate_missing_messages", {
  # Ensure that the deparse(substitute()) methods work
  conc <- NA_real_
  volume <- NA_real_
  expect_equal(
    as.character(PKNCA:::generate_missing_messages(conc, volume)),
    "All conc and volume are missing"
  )
})

test_that("zero-length input gives NA rather than zero (issue 601)", {
  # pk.calc.ae() also attaches the reason for the exclusion
  ae_empty <- pk.calc.ae(conc = numeric(0), volume = numeric(0))
  expect_equal(as.numeric(ae_empty), NA_real_)
  expect_match(attr(ae_empty, "exclude"), "missing")
  expect_equal(as.numeric(pk.calc.ae(conc = NULL, volume = NULL)), NA_real_)
  expect_equal(pk.calc.clr(ae = numeric(0), auc = 10), NA_real_)
  expect_equal(pk.calc.fe(ae = numeric(0), dose = 100), NA_real_)
  # Unchanged for real input
  expect_equal(pk.calc.ae(conc = c(1, 2), volume = c(10, 10)), 30)
  expect_equal(pk.calc.clr(ae = c(5, 5), auc = 10), 1)
  expect_equal(pk.calc.fe(ae = c(5, 5), dose = 100), 0.1)
})

test_that("pk.calc.erint", {
  # The amount recovered divided by the duration of the interval, not by the
  # sum of the collection durations
  expect_equal(pk.calc.erint(ae = 3000, start = 0, end = 24), 125)
  expect_equal(pk.calc.erint(ae = 3000, start = 12, end = 24), 250)
  expect_equal(pk.calc.erint(ae = 0, start = 0, end = 24), 0)
})

test_that("pk.calc.erint has no answer for an interval ending at infinity", {
  expect_equal(
    pk.calc.erint(ae = 3000, start = 0, end = Inf),
    structure(
      NA_real_,
      exclude = "Excretion rate is not defined for an interval ending at infinity"
    )
  )
})

test_that("pk.calc.erint gives NA for zero-length input", {
  expect_equal(pk.calc.erint(numeric(), 0, 24), NA_real_)
  expect_equal(pk.calc.erint(3000, numeric(), 24), NA_real_)
  expect_equal(pk.calc.erint(3000, 0, numeric()), NA_real_)
})

test_that("pk.calc.erint propagates a missing amount", {
  expect_equal(pk.calc.erint(ae = NA_real_, start = 0, end = 24), NA_real_)
})

test_that("pk.calc.erlst", {
  conc <- c(10, 20, 5, 1)
  volume <- c(100, 50, 200, 100)
  time <- c(0, 4, 8, 12)
  duration.conc <- c(4, 4, 4, 12)
  # Excretion rates are 250, 250, 250, 8.333...
  expect_equal(
    pk.calc.erlst(conc, volume, time, duration.conc),
    100 / 12
  )
})

test_that("pk.calc.erlst uses the collection midpoint to order, matching ertlst", {
  # Collections given out of order; the last by midpoint is the one at time 8
  conc <- c(1, 3, 2)
  volume <- c(100, 100, 100)
  time <- c(0, 8, 4)
  duration.conc <- c(4, 4, 4)
  expect_equal(pk.calc.erlst(conc, volume, time, duration.conc), 75)
  expect_equal(pk.calc.ertlst(conc, volume, time, duration.conc), 10)
})

test_that("pk.calc.erlst ignores trailing zero excretion rates", {
  conc <- c(10, 0, 0)
  volume <- c(100, 100, 100)
  time <- c(0, 4, 8)
  duration.conc <- c(4, 4, 4)
  expect_equal(pk.calc.erlst(conc, volume, time, duration.conc), 250)
})

test_that("pk.calc.erlst is 0 when no collection has a positive rate", {
  # Matches pk.calc.ertlst(), which also gives 0 in this case
  expect_equal(pk.calc.erlst(c(0, 0), c(1, 1), c(0, 4), c(4, 4)), 0)
  expect_equal(pk.calc.ertlst(c(0, 0), c(1, 1), c(0, 4), c(4, 4)), 0)
})

test_that("pk.calc.erlst gives NA when everything is missing", {
  expect_equal(
    pk.calc.erlst(c(NA, NA), c(1, 1), c(0, 4), c(4, 4)),
    structure(NA_real_, exclude = "All concentrations are missing")
  )
  # Zero-length input is reported the same way as by the sibling parameters
  expect_equal(
    pk.calc.erlst(numeric(), numeric(), numeric(), numeric()),
    pk.calc.ermax(numeric(), numeric(), numeric(), numeric())
  )
})

test_that("erint and erlst use the CDISC codes for their calculations", {
  ic <- get.interval.cols()
  expect_equal(ic$erint$pptestcd_cdisc, "ERINT")
  expect_equal(ic$erint$pptest_cdisc, "Excret Rate from T1 to T2")
  expect_equal(ic$erlst$pptestcd_cdisc, "ERLST")
  expect_equal(ic$erlst$pptest_cdisc, "Last Meas Excretion Rate")
})

test_that("the excretion parameter CDISC names match the standard", {
  # ertlst and ertmax both return the collection midpoint, which is what the
  # CDISC names say; volpk returns the summed volume
  ic <- get.interval.cols()
  expect_equal(ic$ertlst$pptest_cdisc, "Midpoint of Interval of Last Nonzero ER")
  expect_equal(ic$ertmax$pptest_cdisc, "Midpoint of Interval of Maximum ER")
  expect_equal(ic$volpk$pptest_cdisc, "Sum of Urine Vol")
})

test_that("erint and erlst are calculated by pk.nca()", {
  d_conc <-
    data.frame(
      conc = c(10, 20, 5, 1),
      time = c(0, 4, 8, 12),
      volume = c(100, 50, 200, 100),
      duration = 4,
      ID = 1
    )
  d_dose <- data.frame(dose = 100, time = 0, ID = 1)
  o_conc <-
    PKNCAconc(d_conc, conc ~ time | ID, volume = "volume", duration = "duration")
  o_dose <- PKNCAdose(d_dose, dose ~ time | ID)
  o_data <-
    PKNCAdata(
      o_conc, o_dose,
      intervals = data.frame(start = 0, end = 24, erint = TRUE, erlst = TRUE, ae = TRUE)
    )
  result <- as.data.frame(pk.nca(o_data))
  expect_setequal(result$PPTESTCD, c("erint", "erlst", "ae"))
  ae <- result$PPORRES[result$PPTESTCD == "ae"]
  expect_equal(result$PPORRES[result$PPTESTCD == "erint"], ae / 24)
  expect_equal(result$PPORRES[result$PPTESTCD == "erlst"], 100 / 4)
})
