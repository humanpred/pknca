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
    structure(NA, exclude = "All concentrations are missing")
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
    structure(NA, exclude = "1 of 2 concentrations are missing")
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
