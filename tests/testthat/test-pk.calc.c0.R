test_that("pk.calc.c0", {
  # Input checks
  expect_error(
    pk.calc.c0(5:1, 4:0),
    regexp="Assertion on 'time' failed: Must be sorted."
  )
  expect_error(
    pk.calc.c0(5:1, 0:4, time.dose = 1:2),
    regexp = "Must have length 1"
  )
  expect_error(
    pk.calc.c0(5:1, 0:4, time.dose = "1"),
    regexp = "Must be of type 'number'"
  )
  expect_error(pk.calc.c0(5:1, 0:4, method="blah"),
               regexp="should be one of",
               info="method must be valid")
  expect_warning(
    c0_na_time_dose <- pk.calc.c0(conc = 0:3, time = 0:3, time.dose = NA_real_),
    regexp = "time.dose is NA"
  )
  expect_equal(
    c0_na_time_dose,
    structure(NA_real_, exclude = "dose time is missing")
  )
  expect_warning(
    c0_late_time_dose <- pk.calc.c0(5:1, 0:4, time.dose=30),
    regexp="time.dose is after all available data"
  )
  expect_equal(
    c0_late_time_dose,
    structure(NA_real_, exclude = "dose time is after all available concentration data")
  )

  # Simple calculations
  expect_equal(pk.calc.c0(1:5, 0:4), 1,
               info="When there is a nonzero concentration at the default time of dosing")
  expect_equal(pk.calc.c0(1:5, 0:4, time.dose=1), 2,
               info="When there is a nonzero concentration at the nondefault time of dosing")
  # It will fall through to subsequent methods if applicable
  expect_equal(pk.calc.c0(c(0, 2, 1, 0.5), 0:3),
               pk.calc.c0.method.logslope(c(0, 2, 1, 0.5), 0:3),
               info="Falls through to second method")
  expect_equal(pk.calc.c0(c(0, 2, 0, 0), 0:3),
               pk.calc.c0.method.c1(c(0, 2, 0, 0), 0:3),
               info="Falls through to third method")
  expect_equal(pk.calc.c0(c(0, 2, 1, 0.5), 0:3, method="c1"),
               pk.calc.c0.method.c1(c(0, 2, 1, 0.5), 0:3),
               info="Respects method order")

})

test_that("pk.calc.c0.method.logslope", {
  expect_equal(pk.calc.c0.method.logslope(c(0, 2, 1, 0.5), 0:3), 4)
  expect_equal(pk.calc.c0.method.logslope(c(0, 2, 0, 0), 0:3), NA,
               info="returns NA when C2 is 0")
  expect_equal(pk.calc.c0.method.logslope(c(0, 2, 0, 0.5), 0:3), NA,
               info="returns NA when C2 is 0, even when subsequent are > 0")
  expect_equal(pk.calc.c0.method.logslope(c(0, 2, NA, 0.5), 0:3), 4,
               info="ignores missing concentrations")
  expect_equal(pk.calc.c0.method.logslope(c(0, 2, NA, 0.5), 2:5, time.dose=2), 4,
               info="handles nonzero time.dose")
  expect_equal(pk.calc.c0.method.logslope(c(2, NA, 0.5), 3:5, time.dose=2), 4,
               info="works when time.dose isn't an observed time")
})

test_that("pk.calc.c0.method.c0", {
  expect_equal(pk.calc.c0.method.c0(c(0, 2, 1, 0.5), 0:3), NA)
  expect_equal(pk.calc.c0.method.c0(c(2, NA, 0.5), 3:5, time.dose=3), 2,
               info="works when time.dose matches a nonzero conc")
})

test_that("pk.calc.c0.method.c1", {
  expect_equal(pk.calc.c0.method.c1(c(0, 2, 1, 0.5), 0:3), 2)
  expect_equal(pk.calc.c0.method.c1(c(2, NA, 0.5), 3:5, time.dose=3), 0.5,
               info="works when time.dose matches a nonzero conc and skips over NA")
  expect_equal(pk.calc.c0.method.c1(c(2, NA, 0.5), 3:5, time.dose=30), NA,
               info="returns NA when time.dose is after the last measurement")
  expect_warning(
    v1 <- pk.calc.c0.method.c1(rep(NA, 3), 3:5, time.dose=1),
    regexp="All concentration data are missing"
  )
  expect_equal(v1, NA,
               info="returns NA when all inputs are NA")
})

test_that("pk.calc.c0.method.set0", {
  expect_equal(pk.calc.c0.method.set0(), 0)
  expect_equal(pk.calc.c0.method.set0(1, 1), 0)
})

test_that("pk.calc.c0.method.cmin", {
  expect_equal(pk.calc.c0.method.cmin(c(0, 2, 1, 0.5), 0:3), 0)
  expect_equal(pk.calc.c0.method.cmin(c(2, NA, 0.5), 3:5, time.dose=3), 0.5)
})

test_that("pk.calc.c0 with no measured concentration is NA in the default order", {
  # Every method but set0 needs a measurement, and set0 would make up a C0 of 0
  expect_warning(
    expect_equal(pk.calc.c0(conc = c(NA, NA, NA), time = 0:2), NA_real_),
    class = "pknca_warning_all_concentration_missing"
  )
  # A lone missing concentration at the dose time
  expect_warning(
    expect_equal(pk.calc.c0(conc = NA_real_, time = 0), NA_real_),
    class = "pknca_warning_all_concentration_missing"
  )
  # With set0 listed explicitly, it is used
  expect_warning(
    expect_equal(pk.calc.c0(conc = c(NA, NA), time = 0:1, method = "set0"), 0),
    class = "pknca_warning_all_concentration_missing"
  )
  expect_warning(
    expect_equal(
      pk.calc.c0(conc = c(NA, NA), time = 0:1, method = c("c0", "logslope", "c1", "cmin", "set0")),
      0
    ),
    class = "pknca_warning_all_concentration_missing"
  )
  # One measured concentration is enough for the default order:  c1 uses it
  # after the missing one at the dose time, and a measured zero at the dose time
  # is C0 through cmin
  expect_equal(pk.calc.c0(conc = c(NA, 5), time = 0:1), 5)
  expect_equal(pk.calc.c0(conc = c(0, NA), time = 0:1), 0)
})

test_that("c0 through pk.nca with no measured concentration is NA", {
  d_conc <- data.frame(id = 1, time = 0:2, conc = NA_real_)
  d_dose <- data.frame(id = 1, time = 0, dose = 1)
  expect_warning(
    o_data <-
      PKNCAdata(
        PKNCAconc(d_conc, conc ~ time | id),
        PKNCAdose(d_dose, dose ~ time | id, route = "intravascular"),
        intervals = data.frame(start = 0, end = 2, c0 = TRUE)
      ),
    class = "pknca_warning_all_concentration_missing"
  )
  expect_warning(
    res <- as.data.frame(suppressMessages(pk.nca(o_data))),
    class = "pknca_warning_all_concentration_missing"
  )
  expect_equal(res$PPTESTCD, "c0")
  expect_equal(res$PPORRES, NA_real_)
})
