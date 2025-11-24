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
    regexp = "Assertion on 'interval[1]' failed: Must be finite.",
    fixed = TRUE
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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
    info = "Giving interval and start+end are the same, no interp/extrap (test 2)"
  )
})

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
    regexp = "Some interpolated/extrapolated concentration values are missing (may be due to interpolating or extrapolating over a dose with lambda.z=NA). Time points with missing data are:  1.5, 4",
    fixed = TRUE,
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
      fixed = TRUE,
      info = "warned when integrating over a dose with lambda.z=NA"
    ),
    regexp = "Cannot interpolate between two doses or after a dose without a concentration after the first dose"
  )
  expect_equal(
    before_time, NA_real_,
    info = "When you cannot interpolate a point, you get NA"
  )
})

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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
    info = "AUCall traces correctly"
  )
})

test_that("aucint respects doses", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  concdata_blq <- data.frame(conc = c(8, 4, 2, 1, 0), time = 0:4)
  time.dose_at <- 1
  time.dose_between <- 1.5
  time.dose_after_tlast <- 3.5
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
  # expect_warning(no_lambda.z_dose <-
  #                  pk.calc.aucint(conc=concdata_blq$conc, time=concdata_blq$time,
  #                                 interval=c(0, 4), auc.type="AUCall", time.dose=time.dose_between),
  #                regexp="Cannot interpolate/extrapolate to dosing times in pk.calc.aucint without lambda.z",
  #                fixed=TRUE)
  # expect_equal(no_lambda.z_dose, NA_real_,
  #              info="Calculating with dosing times, without observations, and without lambda.z")
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

test_that("aucint works with infinite intervals", {
  concdata <- data.frame(conc = c(8, 4, 2, 1), time = 0:3)
  expect_equal(pk.calc.aucint.last(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.auc.last(conc = concdata$conc, time = concdata$time),
    ignore_attr = TRUE,
    info = "Simple AUClast = aucint.last"
  )
  expect_equal(pk.calc.aucint.all(conc = concdata$conc, time = concdata$time, start = 0, end = Inf),
    pk.calc.auc.all(conc = concdata$conc, time = concdata$time),
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
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
    ignore_attr = TRUE,
    info = "Simple AUCinf.pred = aucint.inf.pred"
  )
})

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
    aucinf_obs5_lin + (6-5)*(clast-ctau_extrap)/log(clast/ctau_extrap),
    ignore_attr = TRUE
  )
})

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
