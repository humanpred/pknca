
# ============================================================================
# Basic pk.calc.auciv Tests
# ============================================================================
test_that("pk.calc.auciv works correctly", {
  # No time 0 in data
  expect_equal(
    pk.calc.auciv(conc = 1:2, time = 1:2),
    structure(NA_real_, exclude = "No time 0 in data")
  )
  
  # Standard calculation with time 0
  expect_equal(
    # No check is done to confirm that the auc argument matches the data
    pk.calc.auciv(conc = 0:5, time = 0:5, c0 = 1, auc = 2.75),
    2.75 + 1 - 0.5
  )
  
  # With check = FALSE
  expect_equal(
    # No verifications are made on the data
    pk.calc.auciv(conc = 0:5, time = 0:5, c0 = 1, auc = 2.75, check = FALSE),
    2.75 + 1 - 0.5
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
    pk.calc.auciv_pbext(auc = 1, auciv = 2.1),
    100 * (1 - 1/2.1)
  )
  
  # Zero back-extrapolation (auc = auciv)
  expect_equal(
    pk.calc.auciv_pbext(auc = 2.5, auciv = 2.5),
    0
  )
  
  # 50% back-extrapolation
  expect_equal(
    pk.calc.auciv_pbext(auc = 1, auciv = 2),
    50
  )
})

# ============================================================================
# pk.calc.aumciv Tests
# ============================================================================
test_that("pk.calc.aumciv works correctly", {
  # No time 0 in data
  expect_equal(
    pk.calc.aumciv(conc = 1:2, time = 1:2, c0 = NA, aumc = 5),
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
# pk.calc.aumciv_pbext Tests
# ============================================================================
test_that("pk.calc.aumciv_pbext calculates percent back-extrapolation correctly", {
  expect_equal(
    pk.calc.aumciv_pbext(aumc = 10, aumciv = 15),
    100 * (1 - 10/15)
  )
  
  # Zero back-extrapolation (aumc = aumciv)
  expect_equal(
    pk.calc.aumciv_pbext(aumc = 20, aumciv = 20),
    0
  )
  
  # 50% back-extrapolation
  expect_equal(
    pk.calc.aumciv_pbext(aumc = 10, aumciv = 20),
    50
  )
  
  # Different percentage
  expect_equal(
    pk.calc.aumciv_pbext(aumc = 7.5, aumciv = 10),
    25
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
  # The same warning is expected three times
  expect_warning(expect_warning(expect_warning(
    o_nca <- pk.nca(o_data_353alt),
    regexp = "Requesting an AUC range starting (0) before the first measurement (5) is not allowed",
    fixed = TRUE),
    regexp = "Requesting an AUC range starting (0) before the first measurement (5) is not allowed",
    fixed = TRUE),
    regexp = "Requesting an AUC range starting (0) before the first measurement (5) is not allowed",
    fixed = TRUE
  )
  expect_s3_class(o_nca, "PKNCAresults")
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
  
  # Very small c0
  result_small_c0 <- pk.calc.auciv(
    conc = 0:5, time = 0:5,
    c0 = 0.001, auc = 2.75
  )
  expect_true(is.numeric(result_small_c0))
  
  # c0 smaller than first measured concentration
  result_c0_smaller <- pk.calc.auciv(
    conc = c(5, 4, 3, 2, 1), time = 0:4,
    c0 = 3, auc = 10
  )
  expect_true(is.numeric(result_c0_smaller))
})

# ============================================================================
# Back-Extrapolation Percentage Edge Cases
# ============================================================================
test_that("pk.calc.auciv_pbext handles edge cases correctly", {
  # Zero back-extrapolation (auciv = auc)
  expect_equal(pk.calc.auciv_pbext(auc = 5, auciv = 5), 0)
  
  # 100% back-extrapolation (auc = 0, auciv > 0)
  expect_equal(pk.calc.auciv_pbext(auc = 0, auciv = 5), 100)
  
  # Negative back-extrapolation (auciv < auc - should not happen in practice)
  expect_true(pk.calc.auciv_pbext(auc = 5, auciv = 3) < 0)
})

test_that("pk.calc.aumciv_pbext handles edge cases correctly", {
  # Zero back-extrapolation (aumciv = aumc)
  expect_equal(pk.calc.aumciv_pbext(aumc = 20, aumciv = 20), 0)
  
  # 100% back-extrapolation (aumc = 0, aumciv > 0)
  expect_equal(pk.calc.aumciv_pbext(aumc = 0, aumciv = 25), 100)
  
  # Negative back-extrapolation (aumciv < aumc - should not happen in practice)
  expect_true(pk.calc.aumciv_pbext(aumc = 30, aumciv = 20) < 0)
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
# Consistency Between AUC and AUMC Percent Back-Extrapolation
# ============================================================================
test_that("AUCiv and AUMCiv percent back-extrapolation follow same formula", {
  # Both should use the same formula: 100 * (1 - value / value_iv)
  auc <- 10
  auciv <- 12
  aumc <- 50
  aumciv <- 60
  
  auciv_pbext <- pk.calc.auciv_pbext(auc = auc, auciv = auciv)
  aumciv_pbext <- pk.calc.aumciv_pbext(aumc = aumc, aumciv = aumciv)
  
  # Same percentage if proportions are the same
  expect_equal(
    auciv_pbext,
    aumciv_pbext,
    info = "Same proportional back-extrapolation should give same percentage"
  )
  
  # Verify the formula directly
  expect_equal(
    auciv_pbext,
    100 * (1 - auc/auciv)
  )
  
  expect_equal(
    aumciv_pbext,
    100 * (1 - aumc/aumciv)
  )
})
