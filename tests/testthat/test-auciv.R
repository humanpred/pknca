
# ============================================================================
# Basic pk.calc.auciv Tests
# ============================================================================
test_that("pk.calc.auciv works correctly", {
  # No time 0 in data and no auc.type to calculate the AUC from c0
  expect_equal(
    pk.calc.auciv(conc = 1:2, time = 1:2, c0 = 3, auc = NA_real_),
    structure(NA_real_, exclude = "No time 0 in data")
  )
  
  # Standard calculation with time 0
  expect_equal(
    # No check is done to confirm that the auc argument matches the data
    pk.calc.auciv(conc = 0:5, time = 0:5, c0 = 1, auc = 2.75),
    2.75 + 1 - 0.5,
    ignore_attr = TRUE
  )
  
  # With check = FALSE
  expect_equal(
    # No verifications are made on the data
    pk.calc.auciv(conc = 0:5, time = 0:5, c0 = 1, auc = 2.75, check=FALSE),
    2.75 + 1 - 0.5,
    ignore_attr = TRUE
  )
  
  # With NA c0
  expect_equal(
    pk.calc.auciv(conc = 0:5, time = 0:5, c0 = NA, auc = 2.75),
    structure(NA_real_, exclude = "c0 is not calculated")
  )
})

# ============================================================================
# pk.calc.auciv_pbext Tests
# ============================================================================
test_that("pk.calc.auciv_pbext calculates percent back-extrapolation correctly", {
  expect_equal(
    pk.calc.auciv_pbext(conc = c(0, 1), time = c(0, 1), auc = 1, auciv = 2.1),
    100 * (1 - 1/2.1)
  )
  
  # Zero back-extrapolation (auc = auciv)
  expect_equal(
    pk.calc.auciv_pbext(conc = c(0, 1), time = c(0, 1), auc = 2.5, auciv = 2.5),
    0
  )
  
  # 50% back-extrapolation
  expect_equal(
    pk.calc.auciv_pbext(conc = c(0, 1), time = c(0, 1), auc = 1, auciv = 2),
    50
  )
})

# ============================================================================
# pk.calc.aumciv Tests
# ============================================================================
test_that("pk.calc.aumciv works correctly", {
  # No time 0 in data and no auc.type to calculate the AUMC from c0
  expect_equal(
    pk.calc.aumciv(conc = 1:2, time = 1:2, c0 = 3, aumc = NA_real_),
    structure(NA_real_, exclude = "No time 0 in data")
  )
  
  # With NA c0
  expect_equal(
    pk.calc.aumciv(conc = 0:5, time = 0:5, c0 = NA, aumc = 2.75),
    structure(NA_real_, exclude = "c0 is not calculated")
  )
  
  # Standard calculation with time 0
  expect_equal(
    pk.calc.aumciv(conc = 0:5, time = 0:5, c0 = 1, aumc = 15, check = FALSE),
    15 + pk.calc.aumc.last(conc = c(1, 1), time = c(0, 1), check = FALSE) - 
      pk.calc.aumc.last(conc = c(0, 1), time = c(0, 1), check = FALSE)
  )
})

# ============================================================================
# NA Data Handling (#353)
# ============================================================================
test_that("NA data are removed from concentrations for calculation of AUCiv (#353)", {
  d_iv_353alt <- data.frame(conc = c(NA, 4, 2, 1, 0.45), time = c(0, 5, 15, 30, 60))
  d_intervals <- data.frame(start = 0, end = Inf, aucivinf.obs = TRUE)
  o_conc_353alt <- PKNCAconc(data = d_iv_353alt, conc~time)
  o_dose <- PKNCAdose(data = data.frame(time = 0), ~time)
  o_data_353alt <- PKNCAdata(o_conc_353alt, o_dose, intervals = d_intervals)
  # aucinf.obs cannot start before the first measurement and warns once.  The NA
  # concentration at time 0 is dropped, so aucivinf.obs is calculated from c0
  # rather than from aucinf.obs.
  expect_warning(
    o_nca <- pk.nca(o_data_353alt),
    regexp = "Requesting an AUC range starting (0) before the first measurement (5) is not allowed",
    fixed = TRUE
  )
  expect_s3_class(o_nca, "PKNCAresults")
  result <- as.data.frame(o_nca)
  expect_equal(
    result$PPORRES[result$PPTESTCD == "aucivinf.obs"], 109.02992,
    tolerance = 1e-6
  )
  expect_true(is.na(result$PPORRES[result$PPTESTCD == "aucinf.obs"]))
})

test_that("missing dose information does not cause NA time (#353)", {
  d_iv_nodose <- data.frame(conc = c(4, 2, 1, 0.45), time = c(5, 15, 30, 60))
  d_intervals <- data.frame(start = 0, end = Inf, aucivinf.obs = TRUE)
  o_conc_nodose <- PKNCAconc(data = d_iv_nodose, conc ~ time)
  o_data_nodose <- PKNCAdata(o_conc_nodose, intervals = d_intervals, impute = "start_conc0")
  
  expect_warning(
    o_nca <- pk.nca(o_data_nodose),
    regexp = "time.dose is NA"
  )
  expect_s3_class(o_nca, "PKNCAresults")
})

test_that("pk.calc.auciv: method attribute is set and propagated", {

  auc_params <- c("auciv")
  auc_methods <- c("linear", "lin up/log down", "lin-log")
  auc_args <- list(
    conc=3:1,
    time=0:2,
    c0 = 1,
    auc = 2
  )

  for (param in auc_params) {
    auc_fun <- get(paste0("pk.calc.", param))
    args_fun <- auc_args[intersect(names(auc_args), names(formals(auc_fun)))]
    for (method in auc_methods) {
      args_fun$method <- method
      v <- do.call(auc_fun, args_fun)
      expect_equal(
        attr(v, "method"),
        paste0("AUC: ", method),
        info=paste("pk.calc.param sets method attribute for", param, "with method", method)
      )
    }
  }
})

# ============================================================================
# Wrapper Function Tests (pk.calc.auxciv)
# ============================================================================
test_that("pk.calc.auxciv wrapper correctly delegates to AUC and AUMC functions", {
  conc_data <- 0:5
  time_data <- 0:5
  c0_val <- 1
  
  # Test AUC delegation
  auc_test <- 2.75
  auc_via_wrapper <- pk.calc.auxciv(
    conc = conc_data, time = time_data,
    c0 = c0_val, auxc = auc_test,
    fun_auxc_last = pk.calc.auc.last,
    check = FALSE
  )
  
  auc_direct <- pk.calc.auciv(
    conc = conc_data, time = time_data,
    c0 = c0_val, auc = auc_test,
    check = FALSE
  )
  
  expect_equal(auc_via_wrapper, auc_direct,
               info = "auciv should use auxciv wrapper with auc.last function"
  )
  
  # Test AUMC delegation
  aumc_test <- 15
  aumc_via_wrapper <- pk.calc.auxciv(
    conc = conc_data, time = time_data,
    c0 = c0_val, auxc = aumc_test,
    fun_auxc_last = pk.calc.aumc.last,
    check = FALSE
  )
  
  aumc_direct <- pk.calc.aumciv(
    conc = conc_data, time = time_data,
    c0 = c0_val, aumc = aumc_test,
    check = FALSE
  )
  
  expect_equal(aumc_via_wrapper, aumc_direct,
               info = "aumciv should use auxciv wrapper with aumc.last function"
  )
})

# ============================================================================
# Check Argument Tests
# ============================================================================
test_that("auxciv functions respect the check argument", {
  conc_data <- 0:5
  time_data <- 0:5
  
  # With check = TRUE (default)
  result_checked <- pk.calc.auciv(
    conc = conc_data, time = time_data,
    c0 = 1, auc = 2.75,
    check = TRUE
  )
  
  # With check = FALSE
  result_unchecked <- pk.calc.auciv(
    conc = conc_data, time = time_data,
    c0 = 1, auc = 2.75,
    check = FALSE
  )
  
  expect_equal(result_checked, result_unchecked,
               info = "Results should be the same with clean data"
  )
})


# ============================================================================
# Edge Cases Tests
# ============================================================================
test_that("IV calculations handle edge cases correctly", {
  # Zero concentrations
  expect_true(
    is.numeric(pk.calc.auciv(conc = rep(0, 5), time = 0:4, c0 = 0, auc = 0))
  )
  
  # Single time point after time 0
  result_single <- pk.calc.auciv(
    conc = c(0, 5), time = c(0, 1),
    c0 = 10, auc = 2.5
  )
  expect_true(is.numeric(result_single))
  
})

# ============================================================================
# Back-Extrapolation Percentage Edge Cases
# ============================================================================
test_that("pk.calc.auciv_pbext handles edge cases correctly", {
  # Zero back-extrapolation (auciv = auc)
  expect_equal(pk.calc.auciv_pbext(conc = c(0, 1), time = c(0, 1), auc = 5, auciv = 5), 0)
  
  # 100% back-extrapolation (auc = 0, auciv > 0)
  expect_equal(pk.calc.auciv_pbext(conc = c(0, 1), time = c(0, 1), auc = 0, auciv = 5), 100)
  
  # auciv < auc must raise an error — not a valid physical scenario
  expect_error(
    pk.calc.auciv_pbext(conc = c(0, 1), time = c(0, 1), auc = 5, auciv = 3),
    regexp = "(?i)auciv must be >= auc"
  )
})


# ============================================================================
# Consistency Tests Between AUC and AUMC
# ============================================================================
test_that("AUCiv and AUMCiv calculations are consistent", {
  conc_data <- 0:5
  time_data <- 0:5
  c0_val <- 1
  
  # Calculate AUCiv
  auciv_result <- pk.calc.auciv(
    conc = conc_data, time = time_data,
    c0 = c0_val, auc = 2.75,
    check = FALSE
  )
  
  # Calculate AUMCiv
  aumciv_result <- pk.calc.aumciv(
    conc = conc_data, time = time_data,
    c0 = c0_val, aumc = 15,
    check = FALSE
  )
  
  # Both should return numeric values
  expect_true(is.numeric(auciv_result))
  expect_true(is.numeric(aumciv_result))
  
  # AUMC should be larger than AUC (for positive concentrations and times)
  expect_true(aumciv_result > auciv_result)
})


# ============================================================================
# Back-extrapolation without a measured time 0 concentration (#352)
# ============================================================================

# The profile without a time 0 measurement and the same profile with a measured
# BLQ (zero) concentration at time 0.  c0 replaces the time 0 concentration in
# both, so every IV parameter must agree between them.
d_iv_352 <- data.frame(conc = c(4, 2, 1, 0.45), time = c(5, 15, 30, 60))
d_iv_352_t0 <- data.frame(conc = c(0, 4, 2, 1, 0.45), time = c(0, 5, 15, 30, 60))
d_dose_352 <- data.frame(dose = 100, time = 0)
params_352 <-
  c(
    "aucivlast", "aucivall", "aucivint.last", "aucivint.all",
    "aucivinf.obs", "aucivinf.pred",
    "aumcivlast", "aumcivall", "aumcivint.last", "aumcivint.all",
    "aumcivinf.obs", "aumcivinf.pred",
    "aucivpbextlast", "aucivpbextall", "aucivpbextint.last",
    "aucivpbextint.all", "aucivpbextinf.obs", "aucivpbextinf.pred"
  )

nca_352 <- function(d_conc) {
  d_intervals <- data.frame(start = 0, end = Inf)
  d_intervals[params_352] <- TRUE
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time),
      PKNCAdose(d_dose_352, dose~time, route = "intravascular"),
      intervals = d_intervals
    )
  as.data.frame(suppressWarnings(pk.nca(o_data)))
}

test_that("IV AUC is calculated without a time 0 concentration (#352)", {
  r <- nca_352(d_iv_352)
  value <- stats::setNames(r$PPORRES, r$PPTESTCD)
  # c0 back-extrapolates to 5.656854, so the AUC starts at time 0 even though
  # the first measurement is at time 5.
  expect_equal(unname(value["c0"]), 5.656854, tolerance = 1e-6)
  expect_equal(unname(value["aucivlast"]), 95.06123, tolerance = 1e-6)
  expect_equal(unname(value["aucivall"]), 95.06123, tolerance = 1e-6)
  expect_equal(unname(value["aucivint.last"]), 95.06123, tolerance = 1e-6)
  expect_equal(unname(value["aucivint.all"]), 95.06123, tolerance = 1e-6)
  expect_equal(unname(value["aucivinf.obs"]), 109.02992, tolerance = 1e-6)
  expect_equal(unname(value["aucivinf.pred"]), 108.45559, tolerance = 1e-6)
  expect_equal(unname(value["aumcivlast"]), 1685.66716, tolerance = 1e-6)
  expect_equal(unname(value["aumcivall"]), 1685.66716, tolerance = 1e-6)
  expect_equal(unname(value["aumcivint.last"]), 1685.66716, tolerance = 1e-6)
  expect_equal(unname(value["aumcivint.all"]), 1685.66716, tolerance = 1e-6)
  expect_equal(unname(value["aumcivinf.obs"]), 2957.39875, tolerance = 1e-6)
  expect_equal(unname(value["aumcivinf.pred"]), 2905.11073, tolerance = 1e-6)
})

test_that("the percent back-extrapolated is NA without a time 0 concentration (#352)", {
  r <- nca_352(d_iv_352)
  value <- stats::setNames(r$PPORRES, r$PPTESTCD)
  exclude <- stats::setNames(r$exclude, r$PPTESTCD)
  pbext <- grep("^aucivpbext", params_352, value = TRUE)
  # Without a measured concentration at time 0, no AUC describes the observed
  # part of the IV AUC, so the percent back-extrapolated is not calculable.
  expect_true(all(is.na(value[pbext])))
  expect_true(
    all(grepl(
      "Percent back-extrapolated requires a measured concentration at time 0",
      exclude[pbext],
      fixed = TRUE
    ))
  )
  # AUClast, AUCall, AUCinf,obs, and AUCinf,pred also carry the reason they
  # could not be calculated; the aucint family calculates and does not.
  expect_equal(
    unname(exclude[c("aucivpbextlast", "aucivpbextall", "aucivpbextinf.obs", "aucivpbextinf.pred")]),
    rep(
      paste(
        "Requesting an AUC range starting (0) before the first measurement (5) is not allowed",
        "Percent back-extrapolated requires a measured concentration at time 0",
        sep = "; "
      ),
      4
    )
  )
  expect_equal(
    unname(exclude[c("aucivpbextint.last", "aucivpbextint.all")]),
    rep("Percent back-extrapolated requires a measured concentration at time 0", 2)
  )
  # The AUCs that c0 makes calculable are not excluded.
  expect_true(all(is.na(exclude[setdiff(params_352, pbext)])))
})

test_that("a measured zero at time 0 gives the same IV parameters (#352)", {
  no_t0 <- nca_352(d_iv_352)
  with_t0 <- nca_352(d_iv_352_t0)
  ivparams <- setdiff(params_352, grep("^aucivpbext", params_352, value = TRUE))
  expect_equal(
    stats::setNames(no_t0$PPORRES, no_t0$PPTESTCD)[ivparams],
    stats::setNames(with_t0$PPORRES, with_t0$PPTESTCD)[ivparams]
  )
  # The percent back-extrapolated is calculable only when the AUC without
  # back-extrapolation is.
  with_t0_value <- stats::setNames(with_t0$PPORRES, with_t0$PPTESTCD)
  expect_equal(unname(with_t0_value["aucivpbextlast"]), 14.62568, tolerance = 1e-6)
  expect_equal(unname(with_t0_value["aucivpbextall"]), 14.62568, tolerance = 1e-6)
  expect_equal(unname(with_t0_value["aucivpbextint.last"]), 14.62568, tolerance = 1e-6)
  expect_equal(unname(with_t0_value["aucivpbextint.all"]), 14.62568, tolerance = 1e-6)
  expect_equal(unname(with_t0_value["aucivpbextinf.obs"]), 12.75187, tolerance = 1e-6)
  expect_equal(unname(with_t0_value["aucivpbextinf.pred"]), 12.81940, tolerance = 1e-6)
})

test_that("pk.calc.auxciv calculates the AUXC from c0 when auxc is NA", {
  conc <- c(4, 2, 1, 0.45)
  time <- c(5, 15, 30, 60)
  c0 <- 5.656854
  # Identical to calculating on the profile with c0 measured at time 0
  expect_equal(
    pk.calc.auciv(conc = conc, time = time, c0 = c0, auc = NA_real_, auc.type = "AUClast"),
    structure(
      pk.calc.auc.last(conc = c(c0, conc), time = c(0, time)),
      exclude = "DO NOT EXCLUDE"
    ),
    ignore_attr = "method"
  )
  expect_equal(
    pk.calc.aumciv(conc = conc, time = time, c0 = c0, aumc = NA_real_, auc.type = "AUClast"),
    structure(
      pk.calc.aumc.last(conc = c(c0, conc), time = c(0, time)),
      exclude = "DO NOT EXCLUDE"
    ),
    ignore_attr = "method"
  )
  lambda.z <- 0.03221489
  expect_equal(
    pk.calc.auciv(
      conc = conc, time = time, c0 = c0, auc = NA_real_,
      auc.type = "AUCinf", lambda.z = lambda.z, clast = 0.45
    ),
    structure(
      pk.calc.auc.inf.obs(
        conc = c(c0, conc), time = c(0, time),
        clast.obs = 0.45, lambda.z = lambda.z
      ),
      exclude = "DO NOT EXCLUDE"
    ),
    ignore_attr = "method"
  )
})

test_that("pk.calc.auxciv replaces the conc.origin segment when auxc is calculated", {
  conc <- c(4, 2, 1, 0.45)
  time <- c(5, 15, 30, 60)
  c0 <- 5.656854
  # aucint.last extrapolates back to time 0 with conc.origin = 0
  auc_origin0 <- pk.calc.aucint.last(conc = conc, time = time, start = 0, end = Inf, time.dose = NULL)
  expect_equal(
    pk.calc.auciv(conc = conc, time = time, c0 = c0, auc = auc_origin0),
    pk.calc.auc.last(conc = c(c0, conc), time = c(0, time)),
    ignore_attr = TRUE
  )
})

test_that("pk.calc.auxciv reports why it could not calculate", {
  expect_warning(
    expect_warning(
      expect_equal(
        pk.calc.auciv(conc = numeric(), time = numeric(), c0 = 1, auc = 1),
        structure(NA_real_, exclude = "No data for AUC calculation")
      ),
      regexp = "No concentration data given"
    ),
    regexp = "No time data given"
  )
  expect_equal(
    pk.calc.auciv(conc = c(4, 2), time = c(5, 15), c0 = NA, auc = 1, auc.type = "AUClast"),
    structure(NA_real_, exclude = "c0 is not calculated")
  )
})


test_that("pk.calc.auciv_pbext requires a measured concentration at time 0", {
  expect_equal(
    pk.calc.auciv_pbext(conc = c(4, 2), time = c(5, 15), auc = 81, auciv = 95),
    structure(
      NA_real_,
      exclude = "Percent back-extrapolated requires a measured concentration at time 0"
    )
  )
  # An NA at time 0 is not a measurement
  expect_equal(
    pk.calc.auciv_pbext(conc = c(NA, 4, 2), time = c(0, 5, 15), auc = 81, auciv = 95),
    structure(
      NA_real_,
      exclude = "Percent back-extrapolated requires a measured concentration at time 0"
    )
  )
  # A BLQ (zero) at time 0 is a measurement
  expect_equal(
    pk.calc.auciv_pbext(conc = c(0, 4, 2), time = c(0, 5, 15), auc = 81, auciv = 95),
    100 * (1 - 81/95)
  )
})
