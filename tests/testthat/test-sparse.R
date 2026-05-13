
# ============================================================================
# Sparse AUC Tests (Original)
# ============================================================================
test_that("sparse_auc", {
  d_sparse <-
    data.frame(
      id = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 4L, 5L, 6L, 7L, 8L, 9L, 7L, 8L, 9L),
      conc = c(0, 0, 0, 1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 3.03, 1.98, 2.22, 3.34, 1.3, 1.22, 3.54, 2.84, 2.55, 0.3, 0.0421, 0.231),
      time = c(0, 0, 0, 1, 1, 1, 6, 6, 6, 2, 2, 2, 10, 10, 10, 4, 4, 4, 24, 24, 24),
      dose = c(100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100)
    )
  # calculated using the PK library with
  # v_batch <- PK::auc(data=d_sparse, method="t", design="batch")
  # v_serial <- PK::auc(data=d_sparse, method="t", design="ssd")
  auclast <- 39.4689 # using linear trapezoidal rule
  auclast_se_batch <- 7.30997787038754 # for a batch design (with multiple measures from the same animal taken into account)
  auclast_df_batch <- 2.74598236184576
  auclast_se_serial <- 6.86584835083522 # for a serial design (with multiple measures from the same animal not taken into account)
  auclast_df_serial <- 2.82631153092225
  
  expect_warning(
    sparse_batch <- pk.calc.sparse_auc(conc = d_sparse$conc, time = d_sparse$time, subject = d_sparse$id),
    regexp = "Cannot yet calculate sparse degrees of freedom for multiple samples per subject"
  )
  expect_equal(sparse_batch$sparse_auc, auclast)
  expect_equal(sparse_batch$sparse_auc_se, auclast_se_batch)
  expect_equal(sparse_batch$sparse_auc_df, NA_real_)
  
  sparse_serial <- pk.calc.sparse_auc(conc = d_sparse$conc, time = d_sparse$time, subject = seq_len(nrow(d_sparse)))
  expect_equal(sparse_serial$sparse_auc, auclast)
  expect_equal(as.numeric(sparse_serial$sparse_auc_se), auclast_se_serial)
  expect_equal(sparse_serial$sparse_auc_df, auclast_df_serial)
})

test_that("sparse_auclast expected errors", {
  expect_error(
    pk.calc.sparse_auclast(auc.type = "foo"),
    class = "pknca_sparse_auclast_change_auclast"
  )
})

test_that("sparse_auc_df and sparse_auc_se are in the parameter list (#292)", {
  expect_true(
    all(c("sparse_auc_df", "sparse_auc_se") %in% names(get.interval.cols()))
  )
})

test_that("sparse_mean", {
  d_sparse <-
    data.frame(
      id = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 4L, 5L, 6L, 7L, 8L, 9L, 7L, 8L, 9L),
      conc = c(0, 0, 0, 1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 3.03, 1.98, 2.22, 3.34, 1.3, 1.22, 3.54, 2.84, 2.55, 0.3, 0.0421, 0.231),
      time = c(0, 0, 0, 1, 1, 1, 6, 6, 6, 2, 2, 2, 10, 10, 10, 4, 4, 4, 24, 24, 24),
      dose = c(100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100)
    )
  
  sparse_pk <- as_sparse_pk(d_sparse)
  sparse_pk_wt <- sparse_auc_weight_linear(sparse_pk)
  sparse_pk_mean <- sparse_mean(sparse_pk_wt, sparse_mean_method = "arithmetic mean")
  
  expect_equal(
    sparse_pk_mean[[7]]$mean_method,
    "arithmetic mean"
  )
})

# ============================================================================
# Sparse AUMC Tests
# ============================================================================
test_that("sparse_aumc calculates moment-based variance correctly", {
  d_sparse <-
    data.frame(
      id = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 4L, 5L, 6L, 7L, 8L, 9L, 7L, 8L, 9L),
      conc = c(0, 0, 0, 1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 3.03, 1.98, 2.22, 3.34, 1.3, 1.22, 3.54, 2.84, 2.55, 0.3, 0.0421, 0.231),
      time = c(0, 0, 0, 1, 1, 1, 6, 6, 6, 2, 2, 2, 10, 10, 10, 4, 4, 4, 24, 24, 24),
      dose = c(100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100)
    )
  
  # Calculate sparse AUMC
  expect_warning(
    sparse_aumc_batch <- pk.calc.sparse_aumc(
      conc = d_sparse$conc, 
      time = d_sparse$time, 
      subject = d_sparse$id
    ),
    regexp = "Cannot yet calculate sparse degrees of freedom for multiple samples per subject"
  )
  
  # Basic checks
  expect_true(is.numeric(sparse_aumc_batch$sparse_aumc))
  expect_true(is.numeric(sparse_aumc_batch$sparse_aumc_se))
  expect_true(is.na(sparse_aumc_batch$sparse_aumc_df))
  
  # AUMC should be positive
  expect_true(sparse_aumc_batch$sparse_aumc > 0)
  expect_true(sparse_aumc_batch$sparse_aumc_se > 0)
  
  # For serial design (no repeated measures)
  sparse_aumc_serial <- pk.calc.sparse_aumc(
    conc = d_sparse$conc,
    time = d_sparse$time,
    subject = seq_len(nrow(d_sparse))
  )
  
  expect_true(is.numeric(sparse_aumc_serial$sparse_aumc))
  expect_true(is.numeric(sparse_aumc_serial$sparse_aumc_se))
  expect_true(is.numeric(sparse_aumc_serial$sparse_aumc_df))
  expect_true(!is.na(sparse_aumc_serial$sparse_aumc_df))
})

test_that("sparse_aumclast works correctly", {
  d_sparse <-
    data.frame(
      id = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L),
      conc = c(0, 0, 0, 1.75, 2.2, 1.58, 0.3, 0.4, 0.2),
      time = c(0, 0, 0, 1, 1, 1, 2, 2, 2)
    )
  
  result <- pk.calc.sparse_aumclast(
    conc = d_sparse$conc,
    time = d_sparse$time,
    subject = seq_len(nrow(d_sparse))
  )
  
  # Check column names
  expect_true("sparse_aumclast" %in% names(result))
  expect_true("sparse_aumc_se" %in% names(result))
  expect_true("sparse_aumc_df" %in% names(result))
  
  # Check values are reasonable
  expect_true(result$sparse_aumclast > 0)
  expect_true(result$sparse_aumc_se > 0)
})

test_that("sparse_aumclast expected errors", {
  expect_error(
    pk.calc.sparse_aumclast(auc.type = "foo"),
    class = "pknca_sparse_aumclast_change_auc_type"
  )
})

test_that("sparse_aumc_df and sparse_aumc_se are in the parameter list", {
  expect_true(
    all(c("sparse_aumc_df", "sparse_aumc_se", "sparse_aumclast") %in% names(get.interval.cols()))
  )
})


# ============================================================================
# Moment Mean Calculation Tests
# ============================================================================
test_that("moment means are calculated correctly", {
  # Create simple sparse_pk with known values
  d_test <- data.frame(
    id = c(1, 2, 1, 2),
    conc = c(10, 12, 8, 6),
    time = c(1, 1, 2, 2)
  )
  
  sparse_pk <- as_sparse_pk(d_test)
  
  # Create moment data
  moment_sparse_pk <- sparse_pk
  for (idx in seq_along(moment_sparse_pk)) {
    time_i <- moment_sparse_pk[[idx]]$time
    moment_sparse_pk[[idx]]$conc <- moment_sparse_pk[[idx]]$conc * time_i
  }
  
  # Calculate means on moment data
  moment_sparse_pk_mean <- sparse_mean(
    moment_sparse_pk,
    sparse_mean_method = "arithmetic mean"
  )
  
  # Check moment means
  # At time 1: mean(1*10, 1*12) = mean(10, 12) = 11
  expect_equal(moment_sparse_pk_mean[[1]]$mean, 11)
  
  # At time 2: mean(2*8, 2*6) = mean(16, 12) = 14
  expect_equal(moment_sparse_pk_mean[[2]]$mean, 14)
  
  # Compare to concentration means (should be different at t=2)
  conc_sparse_pk_mean <- sparse_mean(sparse_pk, sparse_mean_method = "arithmetic mean")
  
  # At time 1: same as moment mean
  expect_equal(conc_sparse_pk_mean[[1]]$mean, 11)
  
  # At time 2: different from moment mean
  expect_equal(conc_sparse_pk_mean[[2]]$mean, 7)  # mean(8, 6) = 7, not 14
  expect_false(conc_sparse_pk_mean[[2]]$mean == moment_sparse_pk_mean[[2]]$mean)
})


# ============================================================================
# Integration Tests
# ============================================================================
test_that("sparse AUC and AUMC integrate correctly with PKNCA workflow", {
  d_sparse <- data.frame(
    id = rep(1:3, 4),
    conc = c(0, 0, 0, 10, 11, 9, 6, 7, 5, 2, 3, 1),
    time = c(0, 0, 0, 1, 1, 1, 2, 2, 2, 4, 4, 4)
  )
  
  # Calculate both AUC and AUMC
  # Batch design (repeated subjects) → expected warning about df
  expect_warning(
    auc_result <- pk.calc.sparse_auclast(
      conc = d_sparse$conc,
      time = d_sparse$time,
      subject = d_sparse$id
    ),
    regexp = "Cannot yet calculate sparse degrees of freedom for multiple samples per subject"
  )
  
  expect_warning(
    aumc_result <- pk.calc.sparse_aumclast(
      conc = d_sparse$conc,
      time = d_sparse$time,
      subject = d_sparse$id
    ),
    regexp = "Cannot yet calculate sparse degrees of freedom for multiple samples per subject"
  )
  
  # Both should return data frames with 3 columns
  expect_equal(ncol(auc_result), 3)
  expect_equal(ncol(aumc_result), 3)
  
  # Column names should be correct
  expect_true(all(c("sparse_auclast", "sparse_auc_se", "sparse_auc_df") %in% names(auc_result)))
  expect_true(all(c("sparse_aumclast", "sparse_aumc_se", "sparse_aumc_df") %in% names(aumc_result)))
  
  # All values should be positive or NA (df is NA for batch design)
  expect_true(all(auc_result > 0 | is.na(auc_result)))
  expect_true(all(aumc_result > 0 | is.na(aumc_result)))
})
