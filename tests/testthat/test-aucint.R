
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
    info = "No interpolation/extrapolation is equivalent to normal AUC"
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
    info = "Giving interval and start+end are the same, no interp/extrap (test 1)"
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
    info = "Giving interval and start+end are the same, no interp/extrap (test 2)"
  )
})

# ============================================================================
# Warning and NA Handling Tests
# ============================================================================
test_that("AUCint gives a warning and NA when it cannot interpolate or extrapolate a value", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  expect_warning(
    over_dose <-
      pk.calc.aucint(
        conc = concdata$conc,
        time = concdata$time,
        interval = c(0, 4),
        time.dose = 1.5,
        lambda.z = NA,
        auc.type = "AUCinf"
      ),
    regexp = "Some interpolated/extrapolated concentration values are missing \\(may be due to interpolating or extrapolating over a dose with lambda.z=NA\\). Time points with missing data are:  1.5, 4",
    info = "warned when integrating over a dose with lambda.z=NA"
  )
  expect_equal(over_dose, NA_real_,
               info = "When you cannot integrate over a dose, you get NA"
  )
  
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
      regexp = "Some interpolated/extrapolated concentration values are missing Time points with missing data are:  -1, -0.5",
      info = "warned when integrating over a dose with lambda.z=NA"
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
    info = "AUCinf is traced"
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
    info = "AUCinf is traced with clast respected"
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
    info = "AUCinf is traced with lambda.z respected"
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
    info = "AUCinf is traced with clast and lambda.z respected"
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
    info = "AUCall is the same as AUClast when no BLQ follow tlast (both AUCall)"
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
    info = "AUCall is the same as AUClast when no BLQ follow tlast (test AUClast)"
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
    info = "AUCall is the same the normal calculation when no interpolation/extrapolation happens"
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
    info = "AUCall traces correctly"
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
    info = "Calculation with dosing at the same time as an observation causes no change."
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
    info = "Calculation with dosing at a time after all observations causes no change."
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
    info = "Calculation with dosing at a time after all observations causes no change."
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
    info = "Simple AUClast = aucint.last"
  )
  
  expect_equal(
    pk.calc.aucint.all(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.auc.all(conc = concdata$conc, time = concdata$time),
    info = "Simple AUCall = aucint.all"
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
    info = "Simple AUCinf.obs = aucint.inf.obs"
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
    info = "Simple AUCinf.pred = aucint.inf.pred"
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
  expect_equal(attr(auc_pred, "method"), "AUC: lin up/log down")

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
    structure(aucinf_obs5_lin + (6-5)*(clast-ctau_extrap)/log(clast/ctau_extrap), method="AUC: linear")
  )
})

# ============================================================================
# Half-Life NA Handling Tests (#450)
# ============================================================================
test_that("aucint.inf.pred returns NA when half-life is not estimable (#450)", {
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
  aucint_inf_pred_prep <- as.data.frame(o_nca)
  aucint_inf_pred <- aucint_inf_pred_prep$PPORRES[aucint_inf_pred_prep$PPTESTCD %in% "aucint.inf.pred"]
  expect_equal(aucint_inf_pred, NA_real_)
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
      expect_equal(
        attr(v, "method"),
        paste0("AUC: ", method),
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
    info = "No interpolation/extrapolation is equivalent to normal AUMC"
  )
})

test_that("aumcint works with infinite intervals", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  
  expect_equal(
    pk.calc.aumcint.last(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.aumc.last(conc = concdata$conc, time = concdata$time),
    info = "Simple AUMClast = aumcint.last"
  )
  
  expect_equal(
    pk.calc.aumcint.all(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.aumc.all(conc = concdata$conc, time = concdata$time),
    info = "Simple AUMCall = aumcint.all"
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
    info = "Simple AUMCinf.obs = aumcint.inf.obs"
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
    info = "Simple AUMCinf.pred = aumcint.inf.pred"
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
  expect_equal(length(auc_inf), 4)
  expect_equal(length(aumc_inf), 4)
  auc_desc <- vapply(cols[auc_inf], FUN = function(x) x$desc, FUN.VALUE = character(1))
  aumc_desc <- vapply(cols[aumc_inf], FUN = function(x) x$desc, FUN.VALUE = character(1))
  expect_true(all(grepl("AUCinf,", auc_desc, fixed = TRUE)))
  expect_true(all(grepl("AUMCinf,", aumc_desc, fixed = TRUE)))
})

test_that("dose-aware interval parameters are not described as dose-normalized (#582)", {
  cols <- get.interval.cols()
  dose_aware <- grep("int[.].*[.]dose$", names(cols), value = TRUE)
  expect_equal(length(dose_aware), 8)
  descs <- vapply(cols[dose_aware], FUN = function(x) x$desc, FUN.VALUE = character(1))
  # "dn" is the abbreviation for dose normalization (auclast.dn and friends);
  # these parameters use dose-aware interpolation instead.
  expect_equal(unname(descs[grepl("dn", descs, fixed = TRUE)]), character(0))
  expect_true(all(grepl("dose-aware", descs, fixed = TRUE)))
})

test_that("a missing dose time gives NA rather than interpolating at NA (#367)", {
  conc <- 2^(0:-5)
  time <- 0:5
  expect_warning(
    auc_na_dose <- pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf, time.dose = NA_real_),
    regexp = "time.dose is NA"
  )
  expect_equal(auc_na_dose, structure(NA_real_, exclude = "dose time is missing"))
  expect_warning(
    aumc_na_dose <- pk.calc.aumcint.last(conc = conc, time = time, start = 0, end = Inf, time.dose = NA_real_),
    regexp = "time.dose is NA"
  )
  expect_equal(aumc_na_dose, structure(NA_real_, exclude = "dose time is missing"))
  # One unknown dose time is enough; the others cannot make the timeline whole
  expect_warning(
    auc_partial_na_dose <-
      pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf, time.dose = c(0, NA_real_)),
    regexp = "time.dose is NA"
  )
  expect_equal(auc_partial_na_dose, structure(NA_real_, exclude = "dose time is missing"))
  # A known dose time is still used
  expect_equal(
    pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf, time.dose = 0),
    pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf)
  )
})

test_that("pk.nca gives NA for dose-aware interval parameters without dose data (#367)", {
  d_conc <- data.frame(conc = 2^(0:-5), time = 0:5)
  o_conc <- PKNCAconc(d_conc, conc~time)
  dose_aware <- grep("int[.].*[.]dose$", names(get.interval.cols()), value = TRUE)
  d_interval <- data.frame(start = 0, end = Inf, aucint.last = TRUE)
  d_interval[dose_aware] <- TRUE
  o_data <- PKNCAdata(o_conc, intervals = d_interval)
  suppressMessages(suppressWarnings(o_nca <- pk.nca(o_data)))
  res <- as.data.frame(o_nca)
  res_dose_aware <- res[res$PPTESTCD %in% dose_aware, ]
  expect_equal(sort(res_dose_aware$PPTESTCD), sort(dose_aware))
  expect_equal(as.numeric(res_dose_aware$PPORRES), rep(NA_real_, length(dose_aware)))
  expect_equal(res_dose_aware$exclude, rep("dose time is missing", length(dose_aware)))
  # The dose-unaware siblings are still calculated
  # lin up/log down (the default) with conc halving every hour: each 1-hour
  # segment contributes (conc_k - conc_k/2)/log(2)
  expect_equal(
    as.numeric(res$PPORRES[res$PPTESTCD %in% "aucint.last"]),
    sum(2^(-1:-5)) / log(2)
  )
})
