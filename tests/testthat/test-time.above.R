test_that("time.above expected errors", {
  expect_error(
    pk.calc.time_above(conc=c(1, 1), time=c(1, 2), conc_above="X", method="linear"),
    regexp="Must be of type 'number'"
  )
  expect_error(
    pk.calc.time_above(conc=c(1, 1), time=c(1, 2), conc_above=1:2, method="linear"),
    regexp='Must have length 1'
  )
  expect_error(
    pk.calc.time_above(conc=c(1, 1), time=c(1, 2), conc_above=NA, method="linear"),
    regexp='May not be NA'
  )
  expect_error(
    pk.calc.time_above(time="X", conc_above=5, method="linear"),
    regexp='conc must be given'
  )
  expect_error(
    pk.calc.time_above(conc="X", conc_above=5, method="linear"),
    regexp='time must be given'
  )
  expect_error(
    pk.calc.time_above(conc="X", time="X", conc_above=5, method="linear"),
    regexp="Assertion on 'conc' failed: Must be of type 'numeric', not 'character'."
  )
  expect_error(
    pk.calc.time_above(conc=5, time="X", conc_above=5, method="linear"),
    regexp="Assertion on 'time' failed: Must be of type 'numeric', not 'character'."
  )
  expect_error(
    pk.calc.time_above(conc=5, time=5, conc_above=5, method="foo"),
    regexp='should be one of'
  )
})

test_that("time.above simple scenarios", {
  expect_equal(
    pk.calc.time_above(conc=5, time=5, conc_above=5, method="linear"),
    structure(NA_real_, exclude="Too few measured concentrations to assess time.above")
  )
})

test_that("time.above linear", {
  expect_equal(
    pk.calc.time_above(conc=c(5, 5), time=1:2, conc_above=5, method="linear"),
    1,
    info="All above, single period"
  )
  expect_equal(
    pk.calc.time_above(conc=c(5, 6, 5), time=1:3, conc_above=5, method="linear"),
    2,
    info="All above, multiple periods"
  )
  expect_equal(
    pk.calc.time_above(conc=c(4, 4), time=1:2, conc_above=5, method="linear"),
    0,
    info="All below, single period"
  )
  expect_equal(
    pk.calc.time_above(conc=c(5, 4, 5), time=1:3, conc_above=5, method="linear"),
    0,
    info="Some equal to conc_above, but all below"
  )
  expect_equal(
    pk.calc.time_above(conc=c(6, 4, 5), time=1:3, conc_above=5, method="linear"),
    0.5
  )
  expect_equal(
    pk.calc.time_above(conc=c(6, NA, 5), time=1:3, conc_above=5, method="linear"),
    2,
    info="NA is ignored"
  )
})

test_that("time.above with 'lin up/log down'", {
  expect_equal(
    pk.calc.time_above(conc=c(6, 4, 5), time=1:3, conc_above=5, method='lin up/log down'),
    (log(6) - log(5))/(log(6) - log(4))
  )
  expect_equal(
    pk.calc.time_above(conc=c(6, 4, 5), time=(1:3)*2, conc_above=5, method='lin up/log down'),
    (log(6) - log(5))/(log(6) - log(4))*2
  )

  expect_equal(
    pk.calc.time_above(conc=c(6, 4, 6), time=1:3, conc_above=5, method='lin up/log down'),
    (log(6) - log(5))/(log(6) - log(4)) + 0.5
  )
  expect_equal(
    pk.calc.time_above(conc=c(6, 4, 6, 0), time=1:4, conc_above=5, method='lin up/log down'),
    (log(6) - log(5))/(log(6) - log(4)) + 0.5 + 1/6
  )
  expect_equal(
    pk.calc.time_above(conc=c(6, 0, 6, 0), time=1:4, conc_above=5, method='lin up/log down'),
    1/6 + 1/6 + 1/6
  )
})

test_that("time.above with 'lin up/log down' falls back to linear for negative concentrations (#697)", {
  expect_warning(
    res_cross <- pk.calc.time_above(
      conc = c(1, -2, 3, -1),
      time = 0:3,
      conc_above = 0,
      method = "lin up/log down"
    ),
    regexp = "Negative concentrations found"
  )
  expect_equal(res_cross, 1/3 + 3/5 + 3/4)
  expect_equal(
    res_cross,
    suppressWarnings(pk.calc.time_above(
      conc = c(1, -2, 3, -1),
      time = 0:3,
      conc_above = 0,
      method = "linear"
    ))
  )

  expect_warning(
    res_neg <- pk.calc.time_above(
      conc = c(-1, -3),
      time = 0:1,
      conc_above = -2,
      method = "lin up/log down"
    ),
    regexp = "Negative concentrations found"
  )
  expect_equal(res_neg, 0.5)

  expect_warning(
    res_mixed <- pk.calc.time_above(
      conc = c(6, 4, 6, -2),
      time = 1:4,
      conc_above = 5,
      method = "lin up/log down"
    ),
    regexp = "Negative concentrations found"
  )
  expect_equal(
    res_mixed,
    (log(6) - log(5)) / (log(6) - log(4)) + 0.5 + 1/8
  )
})
