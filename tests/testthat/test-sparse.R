
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
  expect_equal(sparse_batch$sparse_auc, structure(auclast, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))
  expect_equal(sparse_batch$sparse_auc_se, structure(auclast_se_batch, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))
  expect_equal(sparse_batch$sparse_auc_df, structure(NA_real_, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))

  sparse_serial <- pk.calc.sparse_auc(conc=d_sparse$conc, time=d_sparse$time, subject=seq_len(nrow(d_sparse)))
  expect_equal(sparse_serial$sparse_auc, structure(auclast, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))
  expect_equal(as.numeric(sparse_serial$sparse_auc_se), auclast_se_serial)
  expect_equal(sparse_serial$sparse_auc_df, structure(auclast_df_serial, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))
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

test_that("sparse_auc and sparse_auclast method attribute", {
  d_sparse <-
    data.frame(
      id = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 4L, 5L, 6L, 7L, 8L, 9L, 7L, 8L, 9L),
      conc = c(0, 0, 0,  1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 3.03, 1.98, 2.22, 3.34, 1.3, 1.22, 3.54, 2.84, 2.55, 0.3, 0.0421, 0.231),
      time = c(0, 0, 0, 1, 1, 1, 6, 6, 6, 2, 2, 2, 10, 10, 10, 4, 4, 4, 24, 24, 24),
      dose = c(100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100)
    )
  auc <- pk.calc.sparse_auc(conc=d_sparse$conc, time=d_sparse$time, subject=seq_len(nrow(d_sparse)))
  expect_equal(attr(auc$sparse_auc, "method"),
               c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ"))

  auclast <- pk.calc.sparse_auclast(conc=d_sparse$conc, time=d_sparse$time, subject=seq_len(nrow(d_sparse)))
  expect_equal(attr(auclast$sparse_auclast, "method"),
               c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ"))
})

test_that("sparse AUC/AUMC only allow method = 'linear' (#469)", {
  d_sparse <-
    data.frame(
      id = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 4L, 5L, 6L, 7L, 8L, 9L, 7L, 8L, 9L),
      conc = c(0, 0, 0,  1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 3.03, 1.98, 2.22, 3.34, 1.3, 1.22, 3.54, 2.84, 2.55, 0.3, 0.0421, 0.231),
      time = c(0, 0, 0, 1, 1, 1, 6, 6, 6, 2, 2, 2, 10, 10, 10, 4, 4, 4, 24, 24, 24)
    )
  subject <- seq_len(nrow(d_sparse))
  # The default ("linear") is accepted
  expect_equal(
    attr(pk.calc.sparse_auc(conc=d_sparse$conc, time=d_sparse$time, subject=subject)$sparse_auc, "method")[1],
    "AUC: linear"
  )
  # Any non-linear method is a hard error for both AUC and AUMC, including the
  # *last wrappers that forward `method` through `...`
  expect_error(
    pk.calc.sparse_auc(conc=d_sparse$conc, time=d_sparse$time, subject=subject, method="lin up/log down"),
    class = "pknca_sparse_method"
  )
  expect_error(
    pk.calc.sparse_auclast(conc=d_sparse$conc, time=d_sparse$time, subject=subject, method="lin-log"),
    class = "pknca_sparse_method"
  )
  expect_error(
    pk.calc.sparse_aumc(conc=d_sparse$conc, time=d_sparse$time, subject=subject, method="lin up/log down"),
    class = "pknca_sparse_method"
  )
  expect_error(
    pk.calc.sparse_aumclast(conc=d_sparse$conc, time=d_sparse$time, subject=subject, method="log"),
    class = "pknca_sparse_method"
  )
})

test_that("cov_holder clips covariance to Cauchy-Schwartz bound", {
  # Construct data where the Holder covariance formula exceeds sqrt(var1*var2).
  # Time 1: subjects 1 & 2, concentrations 0 & 10 → var = 50
  # Time 2: subjects 1, 2, & 3, concentrations 0, 10, & 5 → var = 25
  # Both subjects measured at time 1 and time 2, so subject_both = {1,2}.
  # Holder numerator = (0-5)(0-5) + (10-5)(10-5) = 50
  # Holder denominator = (2-1) + (1-2/2)*(1-2/3) = 1
  # raw cov_ij = 50 > sqrt(50*25) ≈ 35.36 → Cauchy-Schwartz is violated
  conc <- c(0, 10, 0, 10, 5)
  time <- c(1, 1, 2, 2, 2)
  subject <- c(1, 2, 1, 2, 3)

  sparse_pk <- as_sparse_pk(conc = conc, time = time, subject = subject)
  sparse_pk_wt <- sparse_auc_weight_linear(sparse_pk)
  sparse_pk_mean <- sparse_mean(sparse_pk_wt, sparse_mean_method = "arithmetic mean")
  cov_mat <- cov_holder(sparse_pk_mean)

  # After clipping, |cov[1,2]| must equal sqrt(var[1,1] * var[2,2])
  expect_equal(abs(cov_mat[1, 2]), sqrt(cov_mat[1, 1] * cov_mat[2, 2]))
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
# Per-run options forwarding
# ============================================================================
# Shared setup: serial sparse design with 3 animals per
# timepoint.  At t=2, 2 of 3 measurements are BLQ (strictly more than 50%), so
# sparse_mean zeroes that timepoint and the mean profile is
# (0,0), (1,3), (2,0), (3,2).  The default conc.blq (middle = "drop") drops the
# middle zero before integration (AUClast = 6.5); conc.blq = "keep" keeps it
# (AUClast = 4).
d_sparse_579 <-
  data.frame(
    id = 1:12,
    conc = c(0, 0, 0,   2, 3, 4,   0, 0, 1.5,   1, 2, 3),
    time = c(0, 0, 0,   1, 1, 1,   2, 2, 2,     3, 3, 3)
  )

test_that("pk.calc.sparse_auc and pk.calc.sparse_aumc use their options argument for the mean-profile integration", {
  r_default <-
    pk.calc.sparse_auclast(
      conc = d_sparse_579$conc, time = d_sparse_579$time, subject = d_sparse_579$id
    )
  r_keep <-
    pk.calc.sparse_auclast(
      conc = d_sparse_579$conc, time = d_sparse_579$time, subject = d_sparse_579$id,
      options = list(conc.blq = "keep")
    )
  expect_equal(as.numeric(r_default$sparse_auclast), 6.5)
  expect_equal(as.numeric(r_keep$sparse_auclast), 4)
  # The sparse AUC variance is calculated from the individual measurements and
  # weights, not the cleaned mean profile, so it is unaffected by conc.blq
  expect_equal(as.numeric(r_default$sparse_auc_se), as.numeric(r_keep$sparse_auc_se))

  # The same forwarding applies to the sparse AUMC.  Moment profile:
  # t*C = (0,0), (1,3), (2,0), (3,6); default drops the middle zero
  # concentration (AUMClast = 10.5); conc.blq = "keep" keeps it (AUMClast = 6).
  ra_default <-
    pk.calc.sparse_aumclast(
      conc = d_sparse_579$conc, time = d_sparse_579$time, subject = d_sparse_579$id
    )
  ra_keep <-
    pk.calc.sparse_aumclast(
      conc = d_sparse_579$conc, time = d_sparse_579$time, subject = d_sparse_579$id,
      options = list(conc.blq = "keep")
    )
  expect_equal(as.numeric(ra_default$sparse_aumclast), 10.5)
  expect_equal(as.numeric(ra_keep$sparse_aumclast), 6)
})

test_that("per-PKNCAdata options affect sparse_auclast and match the global-option route", {
  o_conc <- PKNCAconc(d_sparse_579, conc ~ time | id, sparse = TRUE)
  d_intervals <- data.frame(start = 0, end = 3, sparse_auclast = TRUE)
  o_data_default <- PKNCAdata(o_conc, intervals = d_intervals)
  o_data_keep <- PKNCAdata(o_conc, intervals = d_intervals, options = list(conc.blq = "keep"))
  res_default <- as.data.frame(suppressMessages(pk.nca(o_data_default, verbose = FALSE)))
  res_keep <- as.data.frame(suppressMessages(pk.nca(o_data_keep, verbose = FALSE)))
  expect_equal(
    res_default$PPORRES[res_default$PPTESTCD %in% "sparse_auclast"],
    6.5
  )
  expect_equal(
    res_keep$PPORRES[res_keep$PPTESTCD %in% "sparse_auclast"],
    4
  )

  # The global-option route matches the per-run route
  old_conc.blq <- PKNCA.options("conc.blq")
  on.exit(PKNCA.options(conc.blq = old_conc.blq))
  PKNCA.options(conc.blq = "keep")
  res_global <- as.data.frame(suppressMessages(pk.nca(o_data_default, verbose = FALSE)))
  expect_equal(
    res_global$PPORRES[res_global$PPTESTCD %in% "sparse_auclast"],
    4
  )
})

test_that("sparse_mean does not zero a timepoint with exactly 50% BLQ", {
  # Exactly 50% BLQ: the arithmetic mean is used (BLQ values count as zero)
  sparse_pk_half <- as_sparse_pk(conc = c(0, 0, 2, 4), time = rep(1, 4), subject = 1:4)
  expect_equal(
    sparse_pk_attribute(sparse_mean(sparse_pk_half), "mean"),
    1.5
  )
  # Strictly more than 50% BLQ: the mean is zeroed
  sparse_pk_most <- as_sparse_pk(conc = c(0, 0, 0, 4), time = rep(1, 4), subject = 1:4)
  expect_equal(
    sparse_pk_attribute(sparse_mean(sparse_pk_most), "mean"),
    0
  )
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
