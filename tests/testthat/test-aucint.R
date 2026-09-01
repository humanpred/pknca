
# ============================================================================
# Basic Error Handling Tests
# ============================================================================
test_that("AUCint gives errors appropriately", {
  expect_error(
    pk.calc.aucint(conc = 1, time = 1),
    regexp = "One of `interval` or `start` and `end` must be given"
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, end = 1),
    regexp = "Both `start` and `end` or neither must be given"
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, start = 1),
    regexp = "Both `start` and `end` or neither must be given"
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, start = 1:2, end = 1),
    regexp = "Assertion on 'start' failed: Must have length 1."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, start = 1, end = 1:2),
    regexp = "Assertion on 'end' failed: Must have length 1."
  )
  
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, start = "A", end = 1),
    regexp = "Assertion on 'start' failed: Must be of type 'number', not 'character'."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, start = factor("A"), end = 1),
    regexp = "Assertion on 'start' failed: Must be of type 'number', not 'factor'."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, start = Inf, end = 1),
    regexp = "Assertion on 'start' failed: Must be finite."
  )
  
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, end = "A", start = 1),
    regexp = "Assertion on 'end' failed: Must be of type 'number', not 'character'."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, end = factor("A"), start = 1),
    regexp = "Assertion on 'end' failed: Must be of type 'number', not 'factor'."
  )
  
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, interval = 1:3),
    regexp = "Assertion on 'interval' failed: Must have length 2, but has length 3."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, interval = c("A", "B")),
    regexp = "Assertion on 'interval' failed: Must be of type 'numeric', not 'character'."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, interval = factor(c("A", "B"))),
    regexp = "Assertion on 'interval' failed: Must be of type 'numeric', not 'factor'."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, interval = c(Inf, 1)),
    regexp = "Assertion on 'interval' failed: Must be sorted."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, interval = c(-Inf, 1)),
    regexp = "Assertion on 'interval\\[1\\]' failed: Must be finite."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, interval = c(1, 1)),
    regexp = "Assertion on 'interval' failed: Contains duplicated values, position 2."
  )
  expect_error(
    pk.calc.aucint(conc = 1, time = 1, interval = c(1, 0)),
    regexp = "Assertion on 'interval' failed: Must be sorted."
  )
})

# ============================================================================
# Basic Equivalence Tests (no interpolation/extrapolation)
# ============================================================================
test_that("AUCint gives the same value when no interpolation/extrapolation is required", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3)
    ),
    pk.calc.auc(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3)
    ),
    info = "No interpolation/extrapolation is equivalent to normal AUC",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      start = 0, end = 3
    ),
    pk.calc.auc(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3)
    ),
    info = "Giving interval and start+end are the same, no interp/extrap (test 1)",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      start = 0, end = 2
    ),
    pk.calc.auc(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 2)
    ),
    info = "Giving interval and start+end are the same, no interp/extrap (test 2)",
    ignore_attr = "method"
  )
})

# ============================================================================
# Warning and NA Handling Tests
# ============================================================================
test_that("AUCint falls back to AUCall over a dose when the half-life is not estimable (#508)", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)

  over_dose <-
    pk.calc.aucint(
      conc = concdata$conc,
      time = concdata$time,
      interval = c(0, 4),
      time.dose = 1.5,
      lambda.z = NA,
      auc.type = "AUCinf"
    )
  # The dose at 1.5 is within the interval, so nothing is estimated there and
  # the measured concentrations on either side of it are integrated.  With no
  # half-life to extrapolate with, the region after tlast is AUCall, which is
  # AUClast because nothing was measured after tlast.
  expect_equal(
    as.numeric(over_dose),
    as.numeric(
      pk.calc.auc(
        conc = concdata$conc, time = concdata$time,
        interval = c(0, 3), auc.type = "AUCall"
      )
    )
  )
  expect_equal(
    attr(over_dose, "method"),
    c(
      "AUC: lin up/log down",
      "Interpolation: dose-aware",
      "Extrapolation: AUCall (half-life not estimable)"
    )
  )
  # The half-life was not used, so an exclusion of it does not reach the result
  expect_equal(attr(over_dose, "exclude"), "DO NOT EXCLUDE")
})

test_that("AUCint gives a warning and NA when it cannot interpolate or extrapolate a value", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)

  expect_warning(
    expect_warning(
      before_time <-
        pk.calc.aucint(
          conc = concdata$conc,
          time = concdata$time,
          interval = c(-1, 4),
          time.dose = c(-1.5, -0.5),
          lambda.z = 1,
          auc.type = "AUCinf"
        ),
      regexp = "Some interpolated/extrapolated concentration values are missing Time points with missing data are:  -1",
      info = "warned when the start of the interval falls between two doses"
    ),
    regexp = "Cannot interpolate between two doses or after a dose without a concentration after the first dose"
  )
  expect_equal(
    before_time, NA_real_,
    info = "When you cannot interpolate a point, you get NA"
  )
})

# ============================================================================
# AUC Type Tests (AUClast, AUCall, AUCinf)
# ============================================================================
test_that("AUCint respects auc.type and does the correct calculations for each AUC type", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  concdata_blq <- data.frame(conc = c(8, 4, 2, 1, 0), time = 0:4)
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3), auc.type = "AUClast"
    ),
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3)
    ),
    info = "Default AUC type is AUClast"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 4), auc.type = "AUCinf", clast = 1, lambda.z = log(2)
    ),
    pk.calc.auc(
      conc = c(concdata$conc, 0.5), time = c(concdata$time, 4),
      interval = c(0, 4)
    ),
    info = "AUCinf is traced",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 4), auc.type = "AUCinf", clast = 2, lambda.z = log(2)
    ),
    pk.calc.auc(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3)
    ) +
      pk.calc.auc(
        conc = c(2, 1), time = c(3, 4),
        interval = c(3, 4)
      ),
    info = "AUCinf is traced with clast respected",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 4), auc.type = "AUCinf", clast = 1, lambda.z = log(2) * 2
    ),
    pk.calc.auc(
      conc = c(concdata$conc, 0.25), time = c(concdata$time, 4),
      interval = c(0, 4)
    ),
    info = "AUCinf is traced with lambda.z respected",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 4), auc.type = "AUCinf", clast = 2, lambda.z = 2 * log(2)
    ),
    pk.calc.auc(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3)
    ) +
      pk.calc.auc(
        conc = c(2, 0.5), time = c(3, 4),
        interval = c(3, 4)
      ),
    info = "AUCinf is traced with clast and lambda.z respected",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3), auc.type = "AUCall"
    ),
    pk.calc.auc(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3), auc.type = "AUCall"
    ),
    info = "AUCall is the same as AUClast when no BLQ follow tlast (both AUCall)",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3), auc.type = "AUCall"
    ),
    pk.calc.auc(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3), auc.type = "AUClast"
    ),
    info = "AUCall is the same as AUClast when no BLQ follow tlast (test AUClast)",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata_blq$conc, time = concdata_blq$time,
      interval = c(0, 4), auc.type = "AUCall"
    ),
    pk.calc.auc(
      conc = concdata_blq$conc, time = concdata_blq$time,
      interval = c(0, 4), auc.type = "AUCall"
    ),
    info = "AUCall is the same the normal calculation when no interpolation/extrapolation happens",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata_blq$conc, time = concdata_blq$time,
      interval = c(0, 3.5), auc.type = "AUCall"
    ),
    pk.calc.auc(
      conc = c(concdata$conc, 0.5), time = c(concdata$time, 3.5),
      interval = c(0, 4), auc.type = "AUClast"
    ),
    info = "AUCall traces correctly",
    ignore_attr = "method"
  )
})

# ============================================================================
# Dose Handling Tests
# ============================================================================
test_that("aucint respects doses", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  concdata_blq <- data.frame(conc = c(8, 4, 2, 1, 0), time = 0:4)
  time.dose_at <- 1
  time.dose_after_all <- 4.5
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata_blq$conc, time = concdata_blq$time,
      interval = c(0, 4), auc.type = "AUCall", time.dose = time.dose_at
    ),
    pk.calc.aucint(
      conc = concdata_blq$conc, time = concdata_blq$time,
      interval = c(0, 4), auc.type = "AUCall"
    ),
    info = "Calculation with dosing at the same time as an observation causes no change.",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata_blq$conc, time = concdata_blq$time,
      interval = c(0, 4), auc.type = "AUCall", time.dose = time.dose_after_all
    ),
    pk.calc.aucint(
      conc = concdata_blq$conc, time = concdata_blq$time,
      interval = c(0, 4), auc.type = "AUCall"
    ),
    info = "Calculation with dosing at a time after all observations causes no change.",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint(
      conc = concdata_blq$conc, time = concdata_blq$time,
      time.dose = 5,
      interval = c(0, 4), auc.type = "AUCall"
    ),
    pk.calc.aucint(
      conc = concdata_blq$conc, time = concdata_blq$time,
      interval = c(0, 4), auc.type = "AUCall"
    ),
    info = "Calculation with dosing at a time after all observations causes no change.",
    ignore_attr = "method"
  )
})

# ============================================================================
# Infinite Interval Tests
# ============================================================================
test_that("aucint works with infinite intervals", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  expect_equal(
    pk.calc.aucint.last(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.auc.last(conc = concdata$conc, time = concdata$time),
    info = "Simple AUClast = aucint.last",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint.all(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.auc.all(conc = concdata$conc, time = concdata$time),
    info = "Simple AUCall = aucint.all",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint.inf.obs(
      conc = concdata$conc, time = concdata$time,
      start = 0, end = Inf,
      clast.obs = 1, lambda.z = log(2)
    ),
    pk.calc.auc.inf.obs(
      conc = concdata$conc, time = concdata$time,
      clast.obs = 1, lambda.z = log(2)
    ),
    info = "Simple AUCinf.obs = aucint.inf.obs",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aucint.inf.pred(
      conc = concdata$conc, time = concdata$time,
      start = 0, end = Inf,
      clast.pred = 2, lambda.z = log(2)
    ),
    pk.calc.auc.inf.pred(
      conc = concdata$conc, time = concdata$time,
      clast.pred = 2, lambda.z = log(2)
    ),
    info = "Simple AUCinf.pred = aucint.inf.pred",
    ignore_attr = "method"
  )
})

test_that("aucint.inf.pred works when the interval ends at infinity (#620)", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  lambda_z <- log(2)
  clast_pred <- 2
  clast_obs <- 1
  # Starting at 0.5 requires an interpolated concentration, which is the path
  # where the clast.pred concentration is added a second time at tlast.  With
  # nothing after tlast in the interval, that duplicate made tlast ambiguous.
  conc_start <- 8 * 2^-0.5
  # lin up/log down (the default) with a monotonically decreasing profile: the
  # log trapezoid for each segment plus clast.pred/lambda.z after tlast
  expected_pred <-
    (conc_start - 4) / log(conc_start / 4) * 0.5 +
    (4 - 2) / log(4 / 2) +
    (2 - 1) / log(2 / 1) +
    clast_pred / lambda_z
  auc_pred <-
    pk.calc.aucint.inf.pred(
      conc = concdata$conc, time = concdata$time,
      start = 0.5, end = Inf,
      clast.pred = clast_pred, lambda.z = lambda_z
    )
  expect_equal(as.numeric(auc_pred), expected_pred)
  expect_equal(
    attr(auc_pred, "method"),
    c(
      "AUC: lin up/log down",
      "Interpolation: not dose-aware (no dosing data)",
      "Extrapolation: half-life"
    )
  )

  # AUCinf,obs and AUCinf,pred differ only by the extrapolated tail
  auc_obs <-
    pk.calc.aucint.inf.obs(
      conc = concdata$conc, time = concdata$time,
      start = 0.5, end = Inf,
      clast.obs = clast_obs, lambda.z = lambda_z
    )
  expect_equal(as.numeric(auc_obs) - as.numeric(auc_pred), (clast_obs - clast_pred) / lambda_z)

  # An interval that ends far after tlast converges to the infinite interval
  expect_equal(
    as.numeric(
      pk.calc.aucint.inf.pred(
        conc = concdata$conc, time = concdata$time,
        start = 0.5, end = 200,
        clast.pred = clast_pred, lambda.z = lambda_z
      )
    ),
    expected_pred
  )

  # The same holds for AUMC
  aumc_pred <-
    pk.calc.aumcint.inf.pred(
      conc = concdata$conc, time = concdata$time,
      start = 0.5, end = Inf,
      clast.pred = clast_pred, lambda.z = lambda_z
    )
  aumc_obs <-
    pk.calc.aumcint.inf.obs(
      conc = concdata$conc, time = concdata$time,
      start = 0.5, end = Inf,
      clast.obs = clast_obs, lambda.z = lambda_z
    )
  tlast <- 3
  expect_equal(
    as.numeric(aumc_obs) - as.numeric(aumc_pred),
    (clast_obs - clast_pred) * tlast / lambda_z + (clast_obs - clast_pred) / lambda_z^2
  )
})

test_that("pk.nca calculates aucint.inf.pred with an infinite interval end (#620)", {
  d_conc <- data.frame(subject = 1, time = c(1, 2, 4, 8), conc = c(50, 40, 8, 2))
  d_dose <- data.frame(subject = 1, dose = 100, time = 0)
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  o_dose <- PKNCAdose(d_dose, dose~time|subject)
  o_data <-
    PKNCAdata(
      o_conc, o_dose,
      intervals =
        data.frame(
          start = 0, end = Inf,
          aucint.inf.obs = TRUE, aucint.inf.pred = TRUE,
          lambda.z = TRUE, clast.obs = TRUE, clast.pred = TRUE
        )
    )
  o_nca <- pk.nca(o_data)
  res <- as.data.frame(o_nca)
  value <- function(x) res$PPORRES[res$PPTESTCD %in% x]
  expect_equal(value("aucint.inf.obs"), 131.08069, tolerance = 1e-6)
  expect_equal(
    value("aucint.inf.obs") - value("aucint.inf.pred"),
    (value("clast.obs") - value("clast.pred")) / value("lambda.z")
  )
})

# ============================================================================
# Check Argument Tests
# ============================================================================
test_that("aucint respects the check argument", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  expect_equal(
    pk.calc.aucint.last(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.aucint.last(conc = concdata$conc, time = concdata$time, start = 0, end = Inf, check = FALSE)
  )
  
  baddata <- data.frame(
    conc = c(8, 4, 2, NA),
    time = c(0:2, NA)
  )
  expect_error(
    pk.calc.aucint.last(conc = baddata$conc, time = baddata$time, start = 0, end = Inf, check = FALSE)
  )
})

# ============================================================================
# All-Zero Concentration Tests
# ============================================================================
test_that("aucint works for all zero concentrations with interpolated or extrapolated concentrations", {
  expect_equal(
    pk.calc.aucint(conc = c(0, 0, 0, 0), time = 0:3, interval = c(0, 4)),
    structure(0, exclude = "DO NOT EXCLUDE")
  )
  
  expect_equal(
    pk.calc.aucint(conc = c(0, 0, 0, 0), time = 0:3, interval = c(0, 2.5)),
    structure(0, exclude = "DO NOT EXCLUDE")
  )
})

# ============================================================================
# Logarithmic Extrapolation Tests (#203)
# ============================================================================
test_that("aucint uses log extrapolation regardless of the interpolation method (#203)", {
  d_conc <-
    data.frame(
      conc = c(0, 1, 2, 0.75, 0.5, 0.2),
      time = c(0, 1, 2, 3, 4, 5)
    )
  lambda_z <- 0.661
  clast <- d_conc$conc[nrow(d_conc)]
  ctau_extrap <- clast*exp(-lambda_z*(6-5))
  
  aucinf_obs5_lin <-
    pk.calc.aucint.inf.obs(
      conc = d_conc$conc,
      time = d_conc$time,
      start = 0, end = 5,
      clast.obs = clast,
      lambda.z = lambda_z,
      options = list(auc.method="linear")
    )
  aucinf_obs6_lin <-
    pk.calc.aucint.inf.obs(
      conc = d_conc$conc,
      time = d_conc$time,
      start = 0, end = 6,
      clast.obs = clast,
      lambda.z = lambda_z,
      options = list(auc.method="linear")
    )
  aucinf_obs5_log <-
    pk.calc.aucint.inf.obs(
      conc = d_conc$conc,
      time = d_conc$time,
      start = 0, end = 5,
      clast.obs = clast,
      lambda.z = lambda_z,
      options = list(auc.method="lin up/log down")
    )
  aucinf_obs6_log <-
    pk.calc.aucint.inf.obs(
      conc = d_conc$conc,
      time = d_conc$time,
      start = 0, end = 6,
      clast.obs = clast,
      lambda.z = lambda_z,
      options = list(auc.method="lin up/log down")
    )
  
  # These are two ways of saying the same thing, the first is simpler logically,
  # the second is more directly mathematical.
  expect_equal(
    aucinf_obs6_lin - aucinf_obs5_lin,
    aucinf_obs6_log - aucinf_obs5_log,
    ignore_attr = TRUE
  )
  expect_equal(
    aucinf_obs6_lin,
    structure(
      as.numeric(aucinf_obs5_lin) + (6-5)*(clast-ctau_extrap)/log(clast/ctau_extrap),
      method =
        c(
          "AUC: linear",
          "Interpolation: not dose-aware (no dosing data)",
          "Extrapolation: half-life"
        )
    )
  )
})

# ============================================================================
# Half-Life NA Handling Tests (#450)
# ============================================================================
test_that("aucint.inf.pred is calculated without a half-life when it only interpolates (#450, #270)", {
  d_conc <-
    data.frame(
      time = c(0.00, 1.08, 2.08, 4.08, 6.08, 8.08, 13.90),
      conc = c(0.4, 0.8, 1.6, 1.9, 1.7, 1.2, 0.3)
    )
  intervals <- data.frame(start = 0, end = 12, aucint.inf.pred = TRUE)
  o_conc <- PKNCAconc(d_conc, conc ~ time)
  o_data <- PKNCAdata(o_conc, intervals = intervals)
  expect_warning(
    o_nca <- suppressMessages(pk.nca(o_data)),
    regexp = "Too few points for half-life calculation"
  )
  res <- as.data.frame(o_nca)
  row <- res[res$PPTESTCD %in% "aucint.inf.pred", ]
  # The interval ends before tlast (13.9), so the AUCinf extrapolation is never
  # reached and the missing half-life does not matter
  expect_equal(
    as.numeric(row$PPORRES),
    as.numeric(
      pk.calc.aucint.last(conc = d_conc$conc, time = d_conc$time, start = 0, end = 12)
    )
  )
  expect_true(grepl("Extrapolation: none", row$PPANMETH, fixed = TRUE))
  expect_equal(row$exclude, NA_character_)
})

test_that("aucint.inf.* falls back to AUCall when the half-life is not estimable (#508)", {
  # Concentrations rise to the end of the profile, so there is no terminal phase
  # to fit, and the interval reaches past tlast so the tail has to be
  # extrapolated somehow
  d_conc <- data.frame(time = 0:4, conc = c(0.4, 0.8, 1.6, 1.9, 0))
  intervals <-
    data.frame(
      start = 0, end = 5,
      aucint.inf.obs = TRUE, aucint.inf.pred = TRUE, aucint.all = TRUE
    )
  o_conc <- PKNCAconc(d_conc, conc ~ time)
  o_data <- PKNCAdata(o_conc, intervals = intervals)
  expect_warning(
    o_nca <- suppressMessages(pk.nca(o_data)),
    regexp = "Too few points for half-life calculation"
  )
  res <- as.data.frame(o_nca)
  auc_all <- as.numeric(res$PPORRES[res$PPTESTCD %in% "aucint.all"])
  for (param in c("aucint.inf.obs", "aucint.inf.pred")) {
    row <- res[res$PPTESTCD %in% param, ]
    expect_equal(as.numeric(row$PPORRES), auc_all, info = param)
    expect_true(
      grepl("Extrapolation: AUCall (half-life not estimable)", row$PPANMETH, fixed = TRUE),
      info = param
    )
    # Nothing that was excluded went into the result (#270)
    expect_equal(row$exclude, NA_character_, info = param)
  }
})

test_that("pk.calc.aucint and wrappers: method attribute is set and propagated", {
  aucint_params <- c("aucint", "aucint.last", "aucint.inf.obs", "aucint.inf.pred", "aucint.all")
  auc_methods <- c("linear", "lin up/log down", "lin-log")
  auc_args <- list(
    conc = c(0,1,1),
    time = 0:2,
    interval = c(0,2),
    lambda.z = 1,
    clast.pred = 1,
    clast.obs = 1,
    start = 0,
    end = 2
  )

  for (param in aucint_params) {
    auc_fun <- get(paste0("pk.calc.", param))
    args_fun <- auc_args[intersect(names(auc_args), names(formals(auc_fun)))]
    # pk.calc.aucint accepts the interval via `...`, so it is not in formals();
    # always supply it so the bare function receives a valid interval.
    args_fun$interval <- auc_args$interval
    for (method in auc_methods) {
      args_fun$method <- method
      v <- do.call(auc_fun, args_fun)
      # The interval ends at the last measurement, so nothing is extrapolated
      expect_equal(
        attr(v, "method"),
        c(
          paste0("AUC: ", method),
          "Interpolation: not dose-aware (no dosing data)",
          "Extrapolation: none"
        ),
        info = paste("pk.calc.param sets method attribute for", param, "with method", method)
      )
    }
  }
})
# ============================================================================
# AUMC Tests (parallel to AUC tests)
# ============================================================================
test_that("AUMCint functions work analogously to AUCint", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  # Test that aumcint.last works
  expect_true(
    is.numeric(pk.calc.aumcint.last(conc = concdata$conc, time = concdata$time, start = 0, end = Inf))
  )
  
  # Test that aumcint.all works
  expect_true(
    is.numeric(pk.calc.aumcint.all(conc = concdata$conc, time = concdata$time, start = 0, end = Inf))
  )
  
  # Test that aumcint.inf.obs works with lambda.z and clast
  expect_true(
    is.numeric(
      pk.calc.aumcint.inf.obs(
        conc = concdata$conc, time = concdata$time,
        start = 0, end = Inf,
        clast.obs = 1, lambda.z = log(2)
      )
    )
  )
  
  # Test that aumcint.inf.pred works with lambda.z and clast
  expect_true(
    is.numeric(
      pk.calc.aumcint.inf.pred(
        conc = concdata$conc, time = concdata$time,
        start = 0, end = Inf,
        clast.pred = 2, lambda.z = log(2)
      )
    )
  )
})

test_that("AUMCint gives the same value when no interpolation/extrapolation is required", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  expect_equal(
    pk.calc.aumcint(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3)
    ),
    pk.calc.aumc(
      conc = concdata$conc, time = concdata$time,
      interval = c(0, 3)
    ),
    info = "No interpolation/extrapolation is equivalent to normal AUMC",
    ignore_attr = "method"
  )
})

test_that("aumcint works with infinite intervals", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  expect_equal(
    pk.calc.aumcint.last(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.aumc.last(conc = concdata$conc, time = concdata$time),
    info = "Simple AUMClast = aumcint.last",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aumcint.all(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.aumc.all(conc = concdata$conc, time = concdata$time),
    info = "Simple AUMCall = aumcint.all",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aumcint.inf.obs(
      conc = concdata$conc, time = concdata$time,
      start = 0, end = Inf,
      clast.obs = 1, lambda.z = log(2)
    ),
    pk.calc.aumc.inf.obs(
      conc = concdata$conc, time = concdata$time,
      clast.obs = 1, lambda.z = log(2)
    ),
    info = "Simple AUMCinf.obs = aumcint.inf.obs",
    ignore_attr = "method"
  )
  
  expect_equal(
    pk.calc.aumcint.inf.pred(
      conc = concdata$conc, time = concdata$time,
      start = 0, end = Inf,
      clast.pred = 2, lambda.z = log(2)
    ),
    pk.calc.aumc.inf.pred(
      conc = concdata$conc, time = concdata$time,
      clast.pred = 2, lambda.z = log(2)
    ),
    info = "Simple AUMCinf.pred = aumcint.inf.pred",
    ignore_attr = "method"
  )
})

# ============================================================================
# Wrapper Function Tests (pk.calc.auxcint)
# ============================================================================
test_that("pk.calc.auxcint wrapper correctly delegates to AUC and AUMC functions", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  # Test that aucint uses auxcint with AUC integration functions
  auc_direct <- pk.calc.aucint(
    conc = concdata$conc, time = concdata$time,
    interval = c(0, 3)
  )
  
  auc_via_auxcint <- pk.calc.auxcint(
    conc = concdata$conc, time = concdata$time,
    interval = c(0, 3),
    fun_linear = aucintegrate_linear,
    fun_log = aucintegrate_log,
    fun_inf = aucintegrate_inf
  )
  
  expect_equal(auc_direct, auc_via_auxcint,
               info = "aucint should use auxcint wrapper with AUC integration functions"
  )
  
  # Test that aumcint uses auxcint with AUMC integration functions
  aumc_direct <- pk.calc.aumcint(
    conc = concdata$conc, time = concdata$time,
    interval = c(0, 3)
  )
  
  aumc_via_auxcint <- pk.calc.auxcint(
    conc = concdata$conc, time = concdata$time,
    interval = c(0, 3),
    fun_linear = aumcintegrate_linear,
    fun_log = aumcintegrate_log,
    fun_inf = aumcintegrate_inf
  )
  
  expect_equal(aumc_direct, aumc_via_auxcint,
               info = "aumcint should use auxcint wrapper with AUMC integration functions"
  )
})

# ============================================================================
# Dose-Aware vs Non-Dose-Aware Wrapper Function Tests
# ============================================================================
test_that("Dose-aware and non-dose-aware wrapper functions work correctly", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  # Test aucint.last (no dose)
  auc_no_dose <- pk.calc.aucint.last(
    conc = concdata$conc, time = concdata$time,
    start = 0, end = 4
  )
  expect_true(is.numeric(auc_no_dose))
  
  # Test aucint.last with dose at observation time
  auc_with_dose <- pk.calc.aucint.last(
    conc = concdata$conc, time = concdata$time,
    start = 0, end = 4,
    time.dose = 0  # Dose at observation time
  )
  expect_equal(auc_no_dose, auc_with_dose,
               ignore_attr = "method",
               info = "Dose at observation time should not affect AUC"
  )
  
  # Test aumcint.last (no dose)
  aumc_no_dose <- pk.calc.aumcint.last(
    conc = concdata$conc, time = concdata$time,
    start = 0, end = 4
  )
  expect_true(is.numeric(aumc_no_dose))
  
  # Test aumcint.all
  aumc_all <- pk.calc.aumcint.all(
    conc = concdata$conc, time = concdata$time,
    start = 0, end = 4
  )
  expect_true(is.numeric(aumc_all))
})

# ============================================================================
# Integration Function Tests
# ============================================================================
test_that("Integration functions are passed correctly through wrapper", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  # Test that auxcint can be called directly with different integration functions
  auc_result <- pk.calc.auxcint(
    conc = concdata$conc, time = concdata$time,
    interval = c(0, 3),
    fun_linear = aucintegrate_linear,
    fun_log = aucintegrate_log,
    fun_inf = aucintegrate_inf
  )
  
  aumc_result <- pk.calc.auxcint(
    conc = concdata$conc, time = concdata$time,
    interval = c(0, 3),
    fun_linear = aumcintegrate_linear,
    fun_log = aumcintegrate_log,
    fun_inf = aumcintegrate_inf
  )
  
  # AUC and AUMC should be different
  expect_false(auc_result == aumc_result)
  
  # Both should be positive numeric values
  expect_true(is.numeric(auc_result) && auc_result > 0)
  expect_true(is.numeric(aumc_result) && aumc_result > 0)
})

test_that("the *int.inf.* descriptions name the AUCinf extrapolation they use (#582)", {
  cols <- get.interval.cols()
  auc_inf <- grep("^aucint[.]inf[.]", names(cols), value = TRUE)
  aumc_inf <- grep("^aumcint[.]inf[.]", names(cols), value = TRUE)
  expect_equal(length(auc_inf), 2)
  expect_equal(length(aumc_inf), 2)
  auc_desc <- vapply(cols[auc_inf], FUN = function(x) x$desc, FUN.VALUE = character(1))
  aumc_desc <- vapply(cols[aumc_inf], FUN = function(x) x$desc, FUN.VALUE = character(1))
  expect_true(all(grepl("AUCinf,", auc_desc, fixed = TRUE)))
  expect_true(all(grepl("AUMCinf,", aumc_desc, fixed = TRUE)))
})

test_that("the retired `.dose` interval parameters point at their replacement (#539)", {
  retired <-
    c(
      "aucint.last.dose", "aucint.all.dose", "aucint.inf.obs.dose", "aucint.inf.pred.dose",
      "aumcint.last.dose", "aumcint.all.dose", "aumcint.inf.obs.dose", "aumcint.inf.pred.dose"
    )
  expect_equal(intersect(retired, names(get.interval.cols())), character(0))

  d_conc <- data.frame(conc = 2^(0:-5), time = 0:5)
  o_conc <- PKNCAconc(d_conc, conc~time)
  expect_error(
    PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 5, aucint.last.dose = TRUE)),
    regexp = "'aucint.last.dose' is now named 'aucint.last'",
    fixed = TRUE
  )
})

test_that("a missing dose time gives NA rather than interpolating at NA (#367, #539)", {
  conc <- 2^(0:-5)
  time <- 0:5
  # Every dose time unknown is what an analysis with no dosing data gives, so
  # the calculation falls back to not being dose-aware
  expect_equal(
    pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf, time.dose = NA_real_),
    pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf)
  )
  expect_equal(
    pk.calc.aumcint.last(conc = conc, time = time, start = 0, end = Inf, time.dose = NA_real_),
    pk.calc.aumcint.last(conc = conc, time = time, start = 0, end = Inf)
  )
  # One unknown dose time among known ones is a dose that cannot be placed
  expect_warning(
    auc_partial_na_dose <-
      pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf, time.dose = c(0, NA_real_)),
    regexp = "time.dose is NA"
  )
  expect_equal(auc_partial_na_dose, structure(NA_real_, exclude = "dose time is missing"))
  # A known dose time is still used
  expect_equal(
    pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf, time.dose = 0),
    pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf),
    ignore_attr = "method"
  )
})

test_that("pk.nca calculates the interval parameters without dose data (#367, #539)", {
  d_conc <- data.frame(conc = 2^(0:-5), time = 0:5)
  o_conc <- PKNCAconc(d_conc, conc~time)
  int_params <- c("aucint.last", "aucint.all", "aumcint.last", "aumcint.all")
  d_interval <- data.frame(start = 0, end = Inf)
  d_interval[int_params] <- TRUE
  o_data <- PKNCAdata(o_conc, intervals = d_interval)
  suppressMessages(suppressWarnings(o_nca <- pk.nca(o_data)))
  res <- as.data.frame(o_nca)
  # Dose awareness is the only method now, with a fallback when there are no
  # dose times to be aware of, so nothing is left uncalculated and the method
  # column says which was used
  expect_equal(sort(res$PPTESTCD), sort(int_params))
  expect_false(anyNA(res$PPORRES))
  expect_equal(res$exclude, rep(NA_character_, length(int_params)))
  expect_true(
    all(grepl("Interpolation: not dose-aware (no dosing data)", res$PPANMETH, fixed = TRUE))
  )
  # lin up/log down (the default) with conc halving every hour: each 1-hour
  # segment contributes (conc_k - conc_k/2)/log(2)
  expect_equal(
    as.numeric(res$PPORRES[res$PPTESTCD %in% "aucint.last"]),
    sum(2^(-1:-5)) / log(2)
  )
})

test_that("AUCint does not reach past the doses around the interval (#508)", {
  # Measurable through 7.59 hr, below the limit of quantification after that,
  # dosed again at 24.1 hr, and measurable again after that dose.  Integrating
  # 0 to 24 must not interpolate from 7.59 hr up to the 24.654 hr measurement,
  # which belongs to the next profile.
  d_conc <-
    data.frame(
      subject = 1,
      time = c(0, 0.5, 1, 2, 4, 7.59, 12, 16, 24, 24.654, 26, 30),
      conc = c(0, 3.5, 3.0, 2.4, 1.5, 0.8, 0, 0, 0, 1.2, 3.0, 1.8)
    )
  d_dose <- data.frame(subject = 1, time = c(0, 24.1), dose = 100)
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  intervals <-
    data.frame(
      start = 0, end = 24,
      auclast = TRUE, aucall = TRUE,
      aucint.last = TRUE, aucint.all = TRUE,
      aucint.inf.obs = TRUE,
      clast.obs = TRUE, lambda.z = TRUE
    )
  o_data <- PKNCAdata(o_conc, o_dose, intervals = intervals)
  res <- as.data.frame(pk.nca(o_data))
  value <- function(x) as.numeric(res$PPORRES[res$PPTESTCD %in% x])

  # With the interval covering the whole dosing interval, each AUCint is the
  # AUC parameter whose extrapolation it uses
  expect_equal(value("aucint.last"), value("auclast"))
  expect_equal(value("aucint.all"), value("aucall"))
  # AUCinf extrapolates from clast with the half-life to the end of the interval
  expect_equal(
    value("aucint.inf.obs"),
    value("auclast") +
      value("clast.obs") / value("lambda.z") * (1 - exp(-value("lambda.z") * (24 - 7.59)))
  )
  expect_true(
    all(grepl("Interpolation: dose-aware", res$PPANMETH[res$PPTESTCD %in% "aucint.last"], fixed = TRUE))
  )
})

test_that("AUCint uses the profile the interval falls in, not the one before it (#508)", {
  # The second dosing interval only: measurements from the first must not be
  # interpolated into it
  conc <- c(0, 4, 2, 1, 0, 8, 4, 2)
  time <- c(0, 1, 2, 3, 4, 25, 26, 27)
  time.dose <- c(0, 24)
  second <-
    pk.calc.aucint.last(
      conc = conc, time = time, start = 24, end = 27, time.dose = time.dose
    )
  # Nothing was measured between the 4 hr sample and the dose at 24 hr, so the
  # concentration at the start of the interval is the pre-dose zero
  expect_equal(
    as.numeric(second),
    as.numeric(
      pk.calc.auc(
        conc = c(0, 8, 4, 2), time = c(24, 25, 26, 27),
        interval = c(24, 27), auc.type = "AUClast"
      )
    )
  )
})

test_that("AUCint is NA when nothing was measured before the dose after the interval (#508)", {
  # Every measurement is after the dose that follows the interval, so none of
  # them belongs to the profile being integrated
  expect_equal(
    pk.calc.aucint.last(
      conc = c(8, 4, 2), time = c(13, 14, 16),
      start = 0, end = 12, time.dose = c(0, 12)
    ),
    structure(
      NA_real_,
      exclude = "no concentration data before the dose after the interval"
    )
  )
})

test_that("aucint.inf.* is NA over an infinite interval without a half-life (#508)", {
  conc <- c(8, 4, 2, 1)
  time <- 0:3
  # An unbounded tail cannot fall back to AUCall, so there is nothing to report
  expect_equal(
    pk.calc.aucint.inf.obs(
      conc = conc, time = time, start = 0, end = Inf,
      clast.obs = 1, lambda.z = NA
    ),
    structure(NA_real_, exclude = "the half-life is NA")
  )
  expect_equal(
    pk.calc.aucint.inf.pred(
      conc = conc, time = time, start = 0, end = Inf,
      clast.pred = NA_real_, lambda.z = NA
    ),
    structure(NA_real_, exclude = "the half-life is NA")
  )
})

test_that("aucint is zero over an interval that is entirely after Tlast", {
  auc <-
    pk.calc.aucint.last(
      conc = c(0, 8, 4, 2, 0, 0, 0), time = 0:6,
      start = 4.5, end = 6
    )
  expect_equal(as.numeric(auc), 0)
  expect_true("Extrapolation: AUClast" %in% attr(auc, "method"))
})

test_that("a dose within the interval is integrated across, not estimated at (#508)", {
  # q12h with a gap around each dose, so there is no trough measurement to
  # integrate to.  Nothing is estimated inside the interval: the measured
  # concentrations on either side of the dose are integrated, which is what
  # auclast and aucall do over the same interval.
  d_conc <-
    data.frame(
      subject = 1,
      time = c(0, 1, 2, 6, 13, 14, 18, 25, 26, 30),
      conc = c(0, 10, 8, 4, 12, 9, 5, 13, 10, 6)
    )
  d_dose <- data.frame(subject = 1, time = c(0, 12, 24, 36), dose = 100)
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  intervals <-
    data.frame(
      start = 0, end = c(24, 36),
      auclast = TRUE, aucall = TRUE, aucint.last = TRUE, aucint.all = TRUE
    )
  res <- as.data.frame(suppressWarnings(pk.nca(PKNCAdata(o_conc, o_dose, intervals = intervals))))
  value <- function(param, e) {
    as.numeric(res$PPORRES[res$PPTESTCD %in% param & res$end %in% e])
  }
  for (e in c(24, 36)) {
    expect_equal(value("aucint.last", e), value("auclast", e), info = paste("end =", e))
    expect_equal(value("aucint.all", e), value("aucall", e), info = paste("end =", e))
  }
})

test_that("a dose within the interval keeps the measured concentrations around it (#508)", {
  # Both profiles end with measurements below the limit of quantification.  The
  # dose at 12 hr is not a point to integrate to, so the interval is integrated
  # against one Tlast the way auclast and aucall are.
  d_conc <-
    data.frame(
      subject = 1,
      time = c(0, 1, 2, 6, 10, 12, 13, 14, 18, 22, 24),
      conc = c(0, 10, 8, 4, 0, 0, 12, 9, 5, 0, 0)
    )
  d_dose <- data.frame(subject = 1, time = c(0, 12, 24), dose = 100)
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  intervals <-
    data.frame(
      start = c(0, 12, 0), end = c(12, 24, 24),
      auclast = TRUE, aucall = TRUE, aucint.last = TRUE, aucint.all = TRUE
    )
  res <- as.data.frame(pk.nca(PKNCAdata(o_conc, o_dose, intervals = intervals)))
  value <- function(param, s, e) {
    as.numeric(res$PPORRES[res$PPTESTCD %in% param & res$start %in% s & res$end %in% e])
  }
  # Each interval, whether it covers one dosing interval or two, matches the
  # AUC parameter that the AUCint is named for
  for (i in seq_len(3)) {
    s <- c(0, 12, 0)[i]
    e <- c(12, 24, 24)[i]
    expect_equal(value("aucint.last", s, e), value("auclast", s, e), info = paste("end =", e))
    expect_equal(value("aucint.all", s, e), value("aucall", s, e), info = paste("end =", e))
  }
})

test_that("the trough before a dose is extrapolated from the profile before it (#508)", {
  # The second dosing interval, with no pre-dose sample at 24 hr.  The
  # concentration there comes from the first profile's own Clast, not from the
  # Clast of the interval being calculated.
  conc <- c(0, 10, 6, 3, 1.5, 12, 7, 4)
  time <- c(0, 1, 2, 6, 12, 25, 26, 30)
  lambda_z <- log(2) / 6
  expect_equal(
    interp.extrap.conc.dose(
      conc = conc, time = time, time.out = 24, time.dose = c(0, 24),
      route.dose = "extravascular", duration.dose = 0, out.after = FALSE,
      auc.type = "AUCinf", clast = 4, lambda.z = lambda_z
    ),
    structure(1.5 * exp(-lambda_z * (24 - 12)), Method = "Extrapolation")
  )
})
