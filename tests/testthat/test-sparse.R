
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
  
  sparse_batch <- pk.calc.sparse_auc(conc = d_sparse$conc, time = d_sparse$time, subject = d_sparse$id)
  expect_equal(sparse_batch$sparse_auc, structure(auclast, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))
  expect_equal(sparse_batch$sparse_auc_se, structure(auclast_se_batch, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))
  expect_equal(sparse_batch$sparse_auc_df, structure(auclast_df_batch, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))

  sparse_serial <- pk.calc.sparse_auc(conc=d_sparse$conc, time=d_sparse$time, subject=seq_len(nrow(d_sparse)))
  expect_equal(sparse_serial$sparse_auc, structure(auclast, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))
  expect_equal(as.numeric(sparse_serial$sparse_auc_se), auclast_se_serial)
  expect_equal(sparse_serial$sparse_auc_df, structure(auclast_df_serial, method=c("AUC: linear", "Sparse: arithmetic mean, <=50% BLQ")))
})

test_that("as_sparse_pk drops NA concentrations (#563)", {
  sparse_pk <- as_sparse_pk(
    conc    = c(0, 0, 5, 7, 3, NA),
    time    = c(0, 0, 4, 4, 24, 24),
    subject = c(1, 2, 3, 4, 5, 6)
  )
  # The NA row (subject 6, time 24) should be dropped
  expect_length(sparse_pk, 3)  # 3 unique times: 0, 4, 24
  expect_equal(sparse_pk[[3]]$conc, 3)
  expect_equal(sparse_pk[[3]]$subject, 5)
})

test_that("as_sparse_pk rejects invalid subject vectors", {
  conc <- c(0, 0, 5, 7, 3, NA)
  time <- c(0, 0, 4, 4, 24, 24)
  expect_error(
    as_sparse_pk(conc = conc, time = time, subject = NULL),
    regexp = "Must be of type 'vector', not 'NULL'"
  )
  # Length is checked against the full input, before NA concentrations drop
  expect_error(
    as_sparse_pk(conc = conc, time = time, subject = 1:5),
    regexp = "Must have length 6, but has length 5"
  )
  # A missing subject marks an imputed concentration, which cannot share a
  # time with measured ones
  expect_error(
    as_sparse_pk(conc = conc, time = time, subject = c(1, 2, 3, NA, 5, 6)),
    class = "pknca_error_sparse_pk_mixed_imputed"
  )
})

test_that("sparse_auc tolerates NA concentrations (#563)", {
  result <- pk.calc.sparse_auc(
    conc    = c(0, 0, 5, 7, 3, NA),
    time    = c(0, 0, 4, 4, 24, 24),
    subject = 1:6
  )
  expect_false(is.na(result$sparse_auc))
  # Mean profile: time 0 = 0, time 4 = 6, time 24 = 3
  # AUC linear: 0.5*(0+6)*4 + 0.5*(6+3)*20 = 12 + 90 = 102
  expect_equal(as.numeric(result$sparse_auc), 102)
})

test_that("sparse_auclast expected errors", {
  expect_error(
    pk.calc.sparse_auclast(auc.type = "foo"),
    class = "pknca_error_sparse_auclast_change_auclast"
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
      subject = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 4L, 5L, 6L, 7L, 8L, 9L, 7L, 8L, 9L),
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
    class = "pknca_error_sparse_auc_method"
  )
  expect_error(
    pk.calc.sparse_auclast(conc=d_sparse$conc, time=d_sparse$time, subject=subject, method="lin-log"),
    class = "pknca_error_sparse_auc_method"
  )
  expect_error(
    pk.calc.sparse_aumc(conc=d_sparse$conc, time=d_sparse$time, subject=subject, method="lin up/log down"),
    class = "pknca_error_sparse_aumc_method"
  )
  expect_error(
    pk.calc.sparse_aumclast(conc=d_sparse$conc, time=d_sparse$time, subject=subject, method="log"),
    class = "pknca_error_sparse_aumc_method"
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

test_that("sparse AUC degrees of freedom match Nedelman and Jia (1998) for a batch design", {
  # Example 1a of Yeh (1990), with the AUC, standard error, and degrees of
  # freedom given by the code in the appendix of Nedelman and Jia (1998):  three
  # batches of three animals, each batch sampled at three times
  time <- c(0, 0.5, 1, 2, 4, 6, 8, 12, 24)
  batch_of_time <- c(1, 2, 1, 2, 1, 2, 3, 3, 3)
  conc_by_time <-
    list(
      c(0, 0, 0), c(4, 1.3, 3.2), c(4.69, 2.07, 6.45), c(6.68, 3.83, 6.08),
      c(4.69, 4.06, 6.45), c(8.13, 9.54, 6.29), c(9.36, 13, 5.48),
      c(5.18, 5.18, 2.79), c(1.06, 2.15, 0.827)
    )
  d_yeh <-
    data.frame(
      time = rep(time, each = 3),
      subject = paste0(rep(batch_of_time, each = 3), "_", 1:3),
      conc = unlist(conc_by_time)
    )
  result <- pk.calc.sparse_auc(conc = d_yeh$conc, time = d_yeh$time, subject = d_yeh$subject)
  expect_equal(as.numeric(result$sparse_auc), 110.1015, tolerance = 1e-7)
  expect_equal(as.numeric(result$sparse_auc_se), 14.78964, tolerance = 1e-6)
  expect_equal(as.numeric(result$sparse_auc_df), 2.144318, tolerance = 1e-6)
})

test_that("sparse AUC degrees of freedom with one sample per subject are equation 6a of Nedelman et al (1995)", {
  d_serial <-
    data.frame(
      time = rep(c(0, 1, 2, 4, 8, 24), times = c(3, 4, 3, 5, 3, 4)),
      conc = c(2.1, 2.6, 1.9, 4.2, 3.6, 4.9, 4.4, 5.1, 6.0, 4.7, 4.1, 3.3, 3.9, 4.6, 3.0, 2.2, 1.5, 1.9, 0.4, 0.6, 0.3, 0.5)
    )
  d_serial$subject <- seq_len(nrow(d_serial))
  result <- pk.calc.sparse_auc(conc = d_serial$conc, time = d_serial$time, subject = d_serial$subject)
  times <- unique(d_serial$time)
  w <- c(0, diff(times)/2) + c(diff(times)/2, 0)
  s2 <- tapply(d_serial$conc, d_serial$time, stats::var)
  n <- tapply(d_serial$conc, d_serial$time, length)
  expected_df <- sum(w^2*s2/n)^2/sum(w^4*s2^2/(n^2*(n - 1)))
  expect_equal(as.numeric(result$sparse_auc_df), unname(expected_df))
})

test_that("sparse AUC degrees of freedom are NA when a time has one subject", {
  # The variance at time 2 cannot be estimated from one subject
  result <-
    pk.calc.sparse_auc(
      conc = c(0, 0, 5, 6, 3, 4, 2),
      time = c(0, 0, 1, 1, 2, 4, 4),
      subject = c(1, 2, 1, 2, 3, 1, 2)
    )
  expect_true(is.na(result$sparse_auc_se))
  expect_true(is.na(result$sparse_auc_df))
})

# Serial sacrifice where two of three animals are BLQ at 24 hours, so the mean
# there is zero and tlast is 8 hours
d_trailing_zero <-
  data.frame(
    time = rep(c(0, 1, 2, 4, 8, 24), each = 3),
    conc = c(0, 0, 0,  5, 6, 4,  8, 7, 9,  6, 5, 7,  3, 2.5, 3.5,  0, 0, 0.4)
  )
d_trailing_zero$subject <- seq_len(nrow(d_trailing_zero))

test_that("the sparse AUClast standard error stops at tlast with it", {
  result <-
    pk.calc.sparse_auc(
      conc = d_trailing_zero$conc, time = d_trailing_zero$time,
      subject = d_trailing_zero$subject
    )
  # Bailer (1988) to tlast:  sum(w^2 s^2 / n) over the times up to 8 hours
  times <- c(0, 1, 2, 4, 8)
  w <- c(0, diff(times)/2) + c(diff(times)/2, 0)
  s2 <- tapply(d_trailing_zero$conc, d_trailing_zero$time, stats::var)[1:5]
  expect_equal(as.numeric(result$sparse_auc), 41)
  expect_equal(as.numeric(result$sparse_auc_se), sqrt(sum(w^2*s2/3)))
  # The time after tlast does not change the result
  mask <- d_trailing_zero$time <= 8
  expect_equal(
    result,
    pk.calc.sparse_auc(
      conc = d_trailing_zero$conc[mask], time = d_trailing_zero$time[mask],
      subject = d_trailing_zero$subject[mask]
    )
  )
})

test_that("the sparse AUCall standard error includes the triangle after tlast", {
  result <-
    pk.calc.sparse_auc(
      conc = d_trailing_zero$conc, time = d_trailing_zero$time,
      subject = d_trailing_zero$subject, auc.type = "AUCall"
    )
  # The 24-hour mean is zero, so only the weight of the 8-hour mean grows (by
  # half of the 16 hours to the next time)
  times <- c(0, 1, 2, 4, 8)
  w <- c(0, diff(times)/2) + c(diff(times)/2, 0)
  w[5] <- w[5] + (24 - 8)/2
  s2 <- tapply(d_trailing_zero$conc, d_trailing_zero$time, stats::var)[1:5]
  expect_equal(as.numeric(result$sparse_auc), 41 + 3*16/2)
  expect_equal(as.numeric(result$sparse_auc_se), sqrt(sum(w^2*s2/3)))
})

test_that("pk.nca() calculates the sparse AUCall and AUMCall with their standard errors", {
  d_intervals <- data.frame(start = 0, end = 24, auclast = TRUE, aucall = TRUE, aumcall = TRUE)
  res <-
    as.data.frame(suppressMessages(pk.nca(PKNCAdata(
      PKNCAconc(d_trailing_zero, conc ~ time | subject, sparse = TRUE),
      intervals = d_intervals
    ))))
  direct_auc <-
    pk.calc.sparse_auc(
      conc = d_trailing_zero$conc, time = d_trailing_zero$time,
      subject = d_trailing_zero$subject, auc.type = "AUCall"
    )
  direct_aumc <-
    pk.calc.sparse_aumc(
      conc = d_trailing_zero$conc, time = d_trailing_zero$time,
      subject = d_trailing_zero$subject, auc.type = "AUCall"
    )
  values <- stats::setNames(res$PPORRES, res$PPTESTCD)
  # The triangle after tlast makes AUCall differ from AUClast (41)
  expect_equal(values[["auclast"]], 41)
  expect_equal(values[["aucall"]], 41 + 3*16/2)
  expect_equal(values[["aucall_se"]], as.numeric(direct_auc$sparse_auc_se))
  expect_equal(values[["aucall_df"]], as.numeric(direct_auc$sparse_auc_df))
  expect_equal(values[["aumcall"]], as.numeric(direct_aumc$sparse_aumc))
  expect_equal(values[["aumcall_se"]], as.numeric(direct_aumc$sparse_aumc_se))
  expect_equal(values[["aumcall_df"]], as.numeric(direct_aumc$sparse_aumc_df))
  expect_match(res$PPANMETH[res$PPTESTCD == "aucall"], "Sparse: arithmetic mean", fixed = TRUE)
})

test_that("the sparse AUMClast standard error stops at tlast with it", {
  mask <- d_trailing_zero$time <= 8
  expect_equal(
    pk.calc.sparse_aumc(
      conc = d_trailing_zero$conc, time = d_trailing_zero$time,
      subject = d_trailing_zero$subject
    ),
    pk.calc.sparse_aumc(
      conc = d_trailing_zero$conc[mask], time = d_trailing_zero$time[mask],
      subject = d_trailing_zero$subject[mask]
    )
  )
})

test_that("sparse AUC and AUMC with no positive mean have no variance", {
  result <- pk.calc.sparse_auc(conc = rep(0, 6), time = rep(c(0, 1, 2), each = 2), subject = 1:6)
  expect_equal(as.numeric(result$sparse_auc), 0)
  expect_equal(as.numeric(result$sparse_auc_se), 0)
  expect_true(is.na(result$sparse_auc_df))
})

test_that("sparse AUC and AUMC refuse an AUC type whose variance they do not calculate", {
  expect_error(
    pk.calc.sparse_auc(conc = d_trailing_zero$conc, time = d_trailing_zero$time,
                       subject = d_trailing_zero$subject, auc.type = "AUCinf.obs"),
    class = "pknca_error_sparse_auc_type"
  )
  expect_error(
    pk.calc.sparse_aumc(conc = d_trailing_zero$conc, time = d_trailing_zero$time,
                        subject = d_trailing_zero$subject, auc.type = "AUCinf.obs"),
    class = "pknca_error_sparse_auc_type"
  )
})

# ============================================================================
# Sparse AUC and AUMC to infinity (Yuan 1993 and the delta method)
# ============================================================================
# Serial sacrifice:  four animals at each time, each sampled once
d_sparse_inf <-
  data.frame(
    time = rep(c(0, 0.5, 1, 2, 4, 6, 8, 12, 24), each = 4),
    conc =
      c(0, 0, 0, 0,  3.1, 4.4, 3.6, 5.2,  5.8, 6.9, 5.1, 7.4,  7.2, 6.1, 8.3, 6.6,
        5.0, 6.2, 4.4, 5.6,  4.1, 3.4, 4.8, 3.7,  2.9, 3.5, 2.4, 3.1,
        1.6, 1.9, 1.3, 1.8,  0.33, 0.27, 0.41, 0.30)
  )
d_sparse_inf$subject <- seq_len(nrow(d_sparse_inf))

# The half-life of the mean profile, as pk.nca() calculates it for sparse data
sparse_inf_half_life <- function(d) {
  means <- tapply(d$conc, d$time, mean)
  pk.calc.half.life(conc = unname(means), time = as.numeric(names(means)))
}

# AUCinf (or AUMCinf) as a function of the time-point means, with lambda.z
# refit by least squares to the log means of the half-life points; its numeric
# gradient is the delta-method weight vector
sparse_inf_from_means <- function(means, times, idx_hl, moment) {
  idx_last <- length(means)
  w <- c(0, diff(times)/2) + c(diff(times)/2, 0)
  lambda_z <- -unname(stats::coef(stats::lm(log(means[idx_hl]) ~ times[idx_hl]))[2])
  if (moment) {
    sum(w*times*means) + times[idx_last]*means[idx_last]/lambda_z + means[idx_last]/lambda_z^2
  } else {
    sum(w*means) + means[idx_last]/lambda_z
  }
}

sparse_inf_numeric_se <- function(d, hl, moment) {
  means <- unname(tapply(d$conc, d$time, mean))
  times <- sort(unique(d$time))
  idx_hl <- which(times >= hl$lambda.z.time.first & times <= hl$lambda.z.time.last)
  gradient <- numeric(length(means))
  for (j in seq_along(means)) {
    h <- 1e-6*max(means[j], 1)
    up <- down <- means
    up[j] <- up[j] + h
    down[j] <- down[j] - h
    gradient[j] <-
      (sparse_inf_from_means(up, times, idx_hl, moment) - sparse_inf_from_means(down, times, idx_hl, moment))/(2*h)
  }
  # Serial sacrifice:  the means are independent with variance s^2/n.  The
  # moment means t*ybar have variance t^2 s^2/n and gradient (d/dybar)/t, so
  # the same sum results.
  s2 <- unname(tapply(d$conc, d$time, stats::var))
  n <- unname(tapply(d$conc, d$time, length))
  sqrt(sum(gradient^2*s2/n))
}

test_that("sparse AUCinf,obs with lambda.z known is Yuan (1993) equations 3 and 4", {
  hl <- sparse_inf_half_life(d_sparse_inf)
  result <-
    pk.calc.aucinf.obs_sparse(
      conc = d_sparse_inf$conc, time = d_sparse_inf$time, subject = d_sparse_inf$subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
      options = list(sparse_lambda_z_se = "none")
    )
  times <- sort(unique(d_sparse_inf$time))
  means <- tapply(d_sparse_inf$conc, d_sparse_inf$time, mean)
  s2 <- tapply(d_sparse_inf$conc, d_sparse_inf$time, stats::var)
  w <- c(0, diff(times)/2) + c(diff(times)/2, 0)
  g <- w
  g[length(g)] <- g[length(g)] + 1/hl$lambda.z
  expect_equal(names(result), c("aucinf.obs", "aucinf.obs_se", "aucinf.obs_df"))
  expect_equal(result$aucinf.obs, unname(sum(w*means) + means[length(means)]/hl$lambda.z))
  expect_equal(result$aucinf.obs_se, unname(sqrt(sum(g^2*s2/4))))
  # The estimate is the sparse AUClast plus the extrapolation from the mean at tlast
  auclast <- pk.calc.sparse_auclast(conc = d_sparse_inf$conc, time = d_sparse_inf$time, subject = d_sparse_inf$subject)
  expect_equal(result$aucinf.obs, as.numeric(auclast$sparse_auclast) + unname(means[length(means)])/hl$lambda.z)
  expect_equal(attr(result, "method")[3], "Sparse SE: lambda.z treated as known (Yuan 1993)")
})

test_that("the delta-method standard error of sparse AUCinf,obs and AUMCinf,obs matches a numeric gradient", {
  hl <- sparse_inf_half_life(d_sparse_inf)
  args <-
    list(
      conc = d_sparse_inf$conc, time = d_sparse_inf$time, subject = d_sparse_inf$subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
      options = list(sparse_lambda_z_se = "delta")
    )
  auc <- do.call(pk.calc.aucinf.obs_sparse, args)
  aumc <- do.call(pk.calc.aumcinf.obs_sparse, args)
  expect_equal(auc$aucinf.obs_se, sparse_inf_numeric_se(d_sparse_inf, hl, moment = FALSE), tolerance = 1e-6)
  expect_equal(aumc$aumcinf.obs_se, sparse_inf_numeric_se(d_sparse_inf, hl, moment = TRUE), tolerance = 1e-6)
  expect_equal(attr(auc, "method")[3], "Sparse SE: delta method for lambda.z")
  # The delta method is the default
  args$options <- list()
  expect_equal(do.call(pk.calc.aucinf.obs_sparse, args), auc)
  # The point estimates do not depend on the standard error method
  args$options <- list(sparse_lambda_z_se = "none")
  expect_equal(auc$aucinf.obs, do.call(pk.calc.aucinf.obs_sparse, args)$aucinf.obs)
  expect_equal(aumc$aumcinf.obs, do.call(pk.calc.aumcinf.obs_sparse, args)$aumcinf.obs)
})

test_that("the delta-method standard error covers the covariances of a batch design", {
  # Three batches of four animals, each batch sampled at three times (and the
  # first batch predose)
  d_batch <-
    data.frame(
      time = rep(c(0, 0.5, 2, 6, 1, 4, 12, 3, 8, 24), each = 4),
      subject = rep(c(rep(1:4, 4), rep(5:8, 3), rep(9:12, 3))),
      conc =
        c(0, 0, 0, 0,  4.1, 3.2, 5.0, 3.8,  6.9, 5.6, 7.7, 6.1,  4.4, 3.5, 5.3, 3.9,
          6.0, 4.8, 6.8, 5.1,  6.3, 5.0, 7.1, 5.6,  2.0, 1.5, 2.4, 1.7,
          7.1, 5.9, 7.9, 6.4,  3.1, 2.4, 3.6, 2.7,  0.40, 0.29, 0.47, 0.33)
    )
  hl <- sparse_inf_half_life(d_batch)
  auc <-
    pk.calc.aucinf.obs_sparse(
      conc = d_batch$conc, time = d_batch$time, subject = d_batch$subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
      options = list(sparse_lambda_z_se = "delta")
    )
  # The covariance of the means:  r_ij sigma_ij / (r_i r_j), with Holder's
  # covariance sigma_ij
  sparse_pk <- sparse_mean(as_sparse_pk(conc = d_batch$conc, time = d_batch$time, subject = d_batch$subject))
  sigma <- cov_holder(sparse_pk)
  subjects <- lapply(sparse_pk, `[[`, "subject")
  r_both <- matrix(0, length(subjects), length(subjects))
  for (i in seq_along(subjects)) {
    for (j in seq_along(subjects)) {
      r_both[i, j] <- length(intersect(subjects[[i]], subjects[[j]]))
    }
  }
  cov_means <- r_both*sigma/outer(diag(r_both), diag(r_both))
  means <- sparse_pk_attribute(sparse_pk, "mean")
  times <- sparse_pk_attribute(sparse_pk, "time")
  idx_hl <- which(times >= hl$lambda.z.time.first & times <= hl$lambda.z.time.last)
  gradient <- numeric(length(means))
  for (j in seq_along(means)) {
    h <- 1e-6*max(means[j], 1)
    up <- down <- means
    up[j] <- up[j] + h
    down[j] <- down[j] - h
    gradient[j] <- (sparse_inf_from_means(up, times, idx_hl, FALSE) - sparse_inf_from_means(down, times, idx_hl, FALSE))/(2*h)
  }
  expect_equal(auc$aucinf.obs_se, sqrt(drop(t(gradient) %*% cov_means %*% gradient)), tolerance = 1e-6)
  expect_false(is.na(auc$aucinf.obs_df))
})

test_that("sparse AUMCinf,obs with lambda.z known extrapolates the moment at tlast", {
  hl <- sparse_inf_half_life(d_sparse_inf)
  result <-
    pk.calc.aumcinf.obs_sparse(
      conc = d_sparse_inf$conc, time = d_sparse_inf$time, subject = d_sparse_inf$subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
      options = list(sparse_lambda_z_se = "none")
    )
  times <- sort(unique(d_sparse_inf$time))
  means <- unname(tapply(d_sparse_inf$conc, d_sparse_inf$time, mean))
  s2 <- unname(tapply(d_sparse_inf$conc, d_sparse_inf$time, stats::var))
  w <- c(0, diff(times)/2) + c(diff(times)/2, 0)
  tlast <- 24
  clast <- means[length(means)]
  # Weights on the moment means t*ybar, whose variance is t^2 s^2/n
  g <- w
  g[length(g)] <- g[length(g)] + 1/hl$lambda.z + 1/(tlast*hl$lambda.z^2)
  expect_equal(result$aumcinf.obs, sum(w*times*means) + tlast*clast/hl$lambda.z + clast/hl$lambda.z^2)
  expect_equal(result$aumcinf.obs_se, sqrt(sum(g^2*times^2*s2/4)))
})

test_that("sparse AUCinf,obs and AUMCinf,obs are NA without a lambda.z", {
  result <-
    pk.calc.aucinf.obs_sparse(
      conc = d_sparse_inf$conc, time = d_sparse_inf$time, subject = d_sparse_inf$subject,
      lambda.z = NA_real_, lambda.z.time.first = NA_real_, lambda.z.time.last = NA_real_,
      lambda.z.n.points = NA_integer_
    )
  expect_true(all(is.na(unlist(result))))
})

test_that("sparse AUCinf,obs and AUMCinf,obs are NA without a sample at time 0, like the sparse AUClast", {
  d_late <- d_sparse_inf[d_sparse_inf$time > 0, ]
  hl <- sparse_inf_half_life(d_late)
  args <-
    list(
      conc = d_late$conc, time = d_late$time, subject = d_late$subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points
    )
  expect_warning(
    auclast <- pk.calc.sparse_auclast(conc = d_late$conc, time = d_late$time, subject = d_late$subject),
    class = "pknca_warning_auc_before_first"
  )
  expect_true(is.na(auclast$sparse_auclast))
  expect_warning(auc <- do.call(pk.calc.aucinf.obs_sparse, args), class = "pknca_warning_auc_before_first")
  expect_warning(aumc <- do.call(pk.calc.aumcinf.obs_sparse, args), class = "pknca_warning_auc_before_first")
  expect_true(all(is.na(unlist(auc))))
  expect_true(all(is.na(unlist(aumc))))
})

test_that("the delta-method standard error needs identifiable log-linear half-life points", {
  hl <- sparse_inf_half_life(d_sparse_inf)
  args <-
    list(
      conc = d_sparse_inf$conc, time = d_sparse_inf$time, subject = d_sparse_inf$subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points + 1,
      options = list(sparse_lambda_z_se = "delta")
    )
  expect_warning(
    result <- do.call(pk.calc.aucinf.obs_sparse, args),
    class = "pknca_warning_sparse_lambda_z_points"
  )
  expect_false(is.na(result$aucinf.obs))
  expect_true(is.na(result$aucinf.obs_se))
  args$lambda.z.n.points <- hl$lambda.z.n.points
  args$options <- list(sparse_lambda_z_se = "none")
  yuan <- do.call(pk.calc.aucinf.obs_sparse, args)
  # Without the log-linear half-life, the estimate is kept and the standard
  # error is NA
  args$options <- list(sparse_lambda_z_se = "delta", hl_method = "tobit")
  expect_warning(
    result <- do.call(pk.calc.aucinf.obs_sparse, args),
    class = "pknca_warning_sparse_lambda_z_se_hl_method"
  )
  expect_equal(result$aucinf.obs, yuan$aucinf.obs)
  expect_true(is.na(result$aucinf.obs_se))
  expect_true(is.na(result$aucinf.obs_df))
})

test_that("pk.nca() calculates sparse AUCinf,obs and AUMCinf,obs with their standard errors", {
  o_data <-
    PKNCAdata(
      PKNCAconc(d_sparse_inf, conc ~ time | subject, sparse = TRUE),
      intervals = data.frame(start = 0, end = Inf, aucinf.obs = TRUE, aumcinf.obs = TRUE),
      options = list(sparse_lambda_z_se = "delta")
    )
  o_nca <- suppressMessages(pk.nca(o_data))
  d_res <- as.data.frame(o_nca)
  hl <- sparse_inf_half_life(d_sparse_inf)
  direct <-
    pk.calc.aucinf.obs_sparse(
      conc = d_sparse_inf$conc, time = d_sparse_inf$time, subject = d_sparse_inf$subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
      options = list(sparse_lambda_z_se = "delta")
    )
  result_values <- stats::setNames(d_res$PPORRES, d_res$PPTESTCD)
  expect_equal(result_values[["aucinf.obs"]], direct$aucinf.obs)
  expect_equal(result_values[["aucinf.obs_se"]], direct$aucinf.obs_se)
  expect_equal(result_values[["aucinf.obs_df"]], direct$aucinf.obs_df)
  expect_false(is.na(result_values[["aumcinf.obs_se"]]))
  expect_match(d_res$PPANMETH[d_res$PPTESTCD == "aucinf.obs"], "Sparse SE: delta method for lambda.z", fixed = TRUE)
  # The summary shows the estimate with its standard error
  o_summary <- summary(o_nca)
  expect_equal(
    o_summary$aucinf.obs,
    sprintf("%s [%s]", signifString(direct$aucinf.obs, 3), signifString(direct$aucinf.obs_se, 3))
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
  sparse_aumc_batch <- pk.calc.sparse_aumc(
    conc = d_sparse$conc,
    time = d_sparse$time,
    subject = d_sparse$id
  )

  # Basic checks
  expect_true(is.numeric(sparse_aumc_batch$sparse_aumc))
  expect_true(is.numeric(sparse_aumc_batch$sparse_aumc_se))
  # The AUMC is the linear-trapezoidal integral of the moment values (t*C), so
  # the expected values are those of the AUC method applied to them, as given by
  # the code in the appendix of Nedelman and Jia (1998)
  expect_equal(as.numeric(sparse_aumc_batch$sparse_aumc), 295.6202667, tolerance = 1e-9)
  expect_equal(as.numeric(sparse_aumc_batch$sparse_aumc_se), 66.92717545, tolerance = 1e-9)
  expect_equal(as.numeric(sparse_aumc_batch$sparse_aumc_df), 2.473378057, tolerance = 1e-9)
  
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
    class = "pknca_error_sparse_aumclast_change_auc_type"
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
    subject = c(1, 2, 1, 2),
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
  o_data_default <- without_sparse_deprecation(PKNCAdata(o_conc, intervals = d_intervals))
  o_data_keep <-
    without_sparse_deprecation(
      PKNCAdata(o_conc, intervals = d_intervals, options = list(conc.blq = "keep"))
    )
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
  
  # Calculate both AUC and AUMC (every subject at every time)
  auc_result <- pk.calc.sparse_auclast(
    conc = d_sparse$conc,
    time = d_sparse$time,
    subject = d_sparse$id
  )
  aumc_result <- pk.calc.sparse_aumclast(
    conc = d_sparse$conc,
    time = d_sparse$time,
    subject = d_sparse$id
  )
  
  # Both should return data frames with 3 columns
  expect_equal(ncol(auc_result), 3)
  expect_equal(ncol(aumc_result), 3)
  
  # Column names should be correct
  expect_true(all(c("sparse_auclast", "sparse_auc_se", "sparse_auc_df") %in% names(auc_result)))
  expect_true(all(c("sparse_aumclast", "sparse_aumc_se", "sparse_aumc_df") %in% names(aumc_result)))
  
  # All values, including the degrees of freedom, should be positive
  expect_true(all(auc_result > 0))
  expect_true(all(aumc_result > 0))
})

# ============================================================================
# Deprecation of the sparse_* / *.sparse.* interval-specification names
# ============================================================================
test_that("the deprecated sparse parameter names each map to a unified name", {
  # Every deprecated name must point at a registered replacement, and the
  # replacement must not itself be deprecated
  expect_setequal(
    names(deprecated_sparse_parameters),
    c("sparse_auclast", "sparse_auc_se", "sparse_auc_df",
      "sparse_aumclast", "sparse_aumc_se", "sparse_aumc_df",
      "cl.sparse.last", "mrt.sparse.last", "kel.sparse.last",
      "vss.sparse.last", "vz.sparse.last")
  )
  expect_true(all(deprecated_sparse_parameters %in% names(get.interval.cols())))
  expect_equal(
    intersect(deprecated_sparse_parameters, names(deprecated_sparse_parameters)),
    character()
  )
})

test_that("requesting a deprecated sparse parameter warns with its replacement", {
  d_sparse <- data.frame(id = 1:8, conc = c(0, 0, 2, 3, 1, 1.5, 0.4, 0.6), time = rep(c(0, 1, 2, 4), each = 2))
  o_conc_sparse <- PKNCAconc(d_sparse, conc~time|id, sparse = TRUE)

  rlang::reset_warning_verbosity("pknca_deprecated_sparse_sparse_auclast")
  expect_warning(
    PKNCAdata(o_conc_sparse, intervals = data.frame(start = 0, end = 4, sparse_auclast = TRUE)),
    regexp = "deprecated and will be an error in the next minor release.*sparse_auclast -> auclast",
    class = "pknca_warning_deprecated_sparse_parameter"
  )
  # Only once per session for the same request
  expect_no_warning(
    PKNCAdata(o_conc_sparse, intervals = data.frame(start = 0, end = 4, sparse_auclast = TRUE)),
    class = "pknca_warning_deprecated_sparse_parameter"
  )

  # Vz is the one replacement whose value changes, and the warning says so
  rlang::reset_warning_verbosity("pknca_deprecated_sparse_vz.sparse.last")
  expect_warning(
    PKNCAdata(o_conc_sparse, intervals = data.frame(start = 0, end = 4, vz.sparse.last = TRUE)),
    regexp = "vz[.]sparse[.]last -> vz[.]last [(]which uses the lambda.z fitted on the mean profile",
    class = "pknca_warning_deprecated_sparse_parameter"
  )

  # A dependency that the user did not name is not reported:  cl.sparse.last is
  # calculated from sparse_auclast, but the user wrote only the one column
  rlang::reset_warning_verbosity("pknca_deprecated_sparse_cl.sparse.last")
  deprecation <-
    tryCatch(
      PKNCAdata(o_conc_sparse, intervals = data.frame(start = 0, end = 4, cl.sparse.last = TRUE)),
      pknca_warning_deprecated_sparse_parameter = function(w) w
    )
  expect_match(conditionMessage(deprecation), "cl.sparse.last -> cl.last", fixed = TRUE)
  expect_false(grepl("sparse_auclast", conditionMessage(deprecation), fixed = TRUE))

  # The unified names are silent
  expect_no_warning(
    PKNCAdata(o_conc_sparse, intervals = data.frame(start = 0, end = 4, auclast = TRUE, vz.last = TRUE)),
    class = "pknca_warning_deprecated_sparse_parameter"
  )
})

test_that("the deprecated names still give the values they always have", {
  d_sparse <-
    data.frame(
      id = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 4L, 5L, 6L, 7L, 8L, 9L, 7L, 8L, 9L),
      conc = c(0, 0, 0, 1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 3.03, 1.98, 2.22, 3.34, 1.3, 1.22, 3.54, 2.84, 2.55, 0.3, 0.0421, 0.231),
      time = c(0, 0, 0, 1, 1, 1, 6, 6, 6, 2, 2, 2, 10, 10, 10, 4, 4, 4, 24, 24, 24)
    )
  o_conc_sparse <- PKNCAconc(d_sparse, conc~time|id, sparse = TRUE)
  d_dose <- data.frame(id = unique(d_sparse$id), dose = 100, time = 0)
  o_dose <- PKNCAdose(d_dose, dose~time|id, route = "intravascular")
  d_intervals <-
    data.frame(
      start = 0, end = 24,
      sparse_auclast = TRUE, sparse_aumclast = TRUE,
      cl.sparse.last = TRUE, mrt.sparse.last = TRUE, kel.sparse.last = TRUE,
      vss.sparse.last = TRUE, vz.sparse.last = TRUE,
      auclast = TRUE, aumclast = TRUE,
      cl.last = TRUE, mrt.last = TRUE, kel.last = TRUE, vss.last = TRUE, vz.last = TRUE
    )
  o_nca <-
    suppressMessages(suppressWarnings(
      pk.nca(PKNCAdata(o_conc_sparse, o_dose, intervals = d_intervals))
    ))
  df_result <- as.data.frame(o_nca)
  value_of <- function(x) df_result$PPORRES[df_result$PPTESTCD %in% x]

  # Every replacement but Vz gives the same number as the name it replaces
  expect_equal(value_of("auclast"), value_of("sparse_auclast"))
  expect_equal(value_of("aumclast"), value_of("sparse_aumclast"))
  expect_equal(value_of("cl.last"), value_of("cl.sparse.last"))
  expect_equal(value_of("mrt.last"), value_of("mrt.sparse.last"))
  expect_equal(value_of("kel.last"), value_of("kel.sparse.last"))
  expect_equal(value_of("vss.last"), value_of("vss.sparse.last"))
  # vz.sparse.last is cl/(1/MRT), which makes it equal to Vss; vz.last divides
  # by the lambda.z fitted on the mean profile, which these data cannot fit
  expect_equal(value_of("vz.sparse.last"), value_of("vss.sparse.last"))
  expect_equal(value_of("vz.last"), NA_real_)
})

# ============================================================================
# Imputation and the sparse estimators
# ============================================================================
test_that("an imputation that adds a nonzero concentration is refused for a sparse estimator", {
  # No time-0 sample, so start_cmin adds the minimum concentration at time 0:
  # an estimate that belongs to no subject, with a variance that the sparse
  # estimators cannot account for.
  d_sparse <-
    data.frame(
      id = 1:9,
      conc = c(1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 0.3, 0.0421, 0.231),
      time = rep(c(1, 6, 24), each = 3)
    )
  o_conc <- PKNCAconc(d_sparse, conc~time|id, sparse = TRUE)
  o_data <-
    PKNCAdata(
      o_conc,
      intervals = data.frame(start = 0, end = 24, auclast = TRUE),
      impute = "start_cmin"
    )
  expect_error(
    suppressMessages(pk.nca(o_data)),
    regexp = "sparse estimators support only imputed zero concentrations.*'start_cmin' imputed other values in the pooled samples for the interval start=0, end=24.*calculated from the pooled samples: auclast",
    class = "pknca_error_sparse_impute"
  )
  # It is a diagnosed problem, so it does not ask for a bug report
  expect_false(
    grepl(
      "report a bug",
      conditionMessage(tryCatch(suppressMessages(pk.nca(o_data)), error = function(e) e)),
      fixed = TRUE
    )
  )

  # The same imputation with only mean-profile parameters is fine
  o_data_dense_params <-
    PKNCAdata(
      o_conc,
      intervals = data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE),
      impute = "start_cmin"
    )
  expect_no_error(suppressMessages(suppressWarnings(pk.nca(o_data_dense_params))))

  # And so are the deprecated sparse-only parameters, which are calculated from
  # the pooled samples just as `auclast` is
  o_data_legacy <-
    without_sparse_deprecation(
      PKNCAdata(
        o_conc,
        intervals = data.frame(start = 0, end = 24, sparse_auclast = TRUE),
        impute = "start_cmin"
      )
    )
  expect_error(
    suppressMessages(pk.nca(o_data_legacy)),
    class = "pknca_error_sparse_impute"
  )
})

test_that("a sparse AUC needs a time-0 concentration, measured or imputed as zero", {
  # Serial sacrifice without a time-0 sample
  d_no_zero <- d_sparse_inf[d_sparse_inf$time > 0, ]
  d_no_zero$id <- seq_len(nrow(d_no_zero))
  # The same animals with known zero concentrations at time 0 from three more
  # animals
  d_zero <- rbind(data.frame(time = 0, conc = 0, id = 100 + 1:3), d_no_zero[, c("time", "conc", "id")])
  params <- c("auclast", "aumclast", "aucall", "aumcall", "aucinf.obs", "aumcinf.obs")
  d_intervals <- data.frame(start = 0, end = Inf)
  d_intervals[params] <- TRUE
  res_missing <-
    as.data.frame(suppressMessages(suppressWarnings(pk.nca(
      PKNCAdata(PKNCAconc(d_no_zero, conc~time|id, sparse = TRUE), intervals = d_intervals)
    ))))
  res_imputed <-
    as.data.frame(suppressMessages(pk.nca(
      PKNCAdata(PKNCAconc(d_no_zero, conc~time|id, sparse = TRUE), intervals = d_intervals, impute = "start_conc0")
    )))
  res_zero <-
    as.data.frame(suppressMessages(pk.nca(
      PKNCAdata(PKNCAconc(d_zero, conc~time|id, sparse = TRUE), intervals = d_intervals)
    )))
  all_params <- c(params, paste0(params, "_se"), paste0(params, "_df"))
  for (current_param in all_params) {
    value_missing <- res_missing$PPORRES[res_missing$PPTESTCD == current_param]
    value_imputed <- res_imputed$PPORRES[res_imputed$PPTESTCD == current_param]
    value_zero <- res_zero$PPORRES[res_zero$PPTESTCD == current_param]
    # Without a time-0 concentration, every sparse AUC and AUMC is missing
    expect_equal(value_missing, NA_real_, info = current_param)
    # An imputed zero is a known concentration:  the estimates, standard
    # errors, and degrees of freedom match those of measured zeros, which have
    # no variance
    expect_equal(value_imputed, value_zero, info = current_param)
    expect_false(is.na(value_imputed), info = current_param)
  }
  expect_true(all(grepl("Imputation: start_conc0", res_imputed$PPANMETH, fixed = TRUE)))
})

test_that("as_sparse_pk() marks a time with only missing subjects as imputed", {
  sparse_pk <- as_sparse_pk(conc = c(0, 1, 2, 3), time = c(0, 1, 1, 2), subject = c(NA, 1, 2, 3))
  expect_equal(vapply(sparse_pk, `[[`, "imputed", FUN.VALUE = TRUE), c(TRUE, FALSE, FALSE))
  expect_error(
    as_sparse_pk(conc = c(0, 1, 2, 3), time = c(0, 1, 1, 2), subject = c(NA, 1, NA, 3)),
    class = "pknca_error_sparse_pk_mixed_imputed"
  )
  # The imputed time enters the estimate but not the variance
  sparse_pk <- sparse_auc_weight_linear(sparse_mean(sparse_pk))
  expect_equal(length(sparse_pk_weighted(sparse_pk)), 2)
})

test_that("an imputation that leaves the pooled samples alone still calculates", {
  # A time-0 sample of 0 already exists, so start_conc0 changes nothing
  d_sparse <-
    data.frame(
      id = 1:12,
      conc = c(0, 0, 0, 1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 0.3, 0.0421, 0.231),
      time = rep(c(0, 1, 6, 24), each = 3)
    )
  o_conc <- PKNCAconc(d_sparse, conc~time|id, sparse = TRUE)
  d_intervals <- data.frame(start = 0, end = 24, auclast = TRUE)
  res_imputed <-
    as.data.frame(suppressMessages(pk.nca(
      PKNCAdata(o_conc, intervals = d_intervals, impute = "start_conc0")
    )))
  res_plain <-
    as.data.frame(suppressMessages(pk.nca(PKNCAdata(o_conc, intervals = d_intervals))))
  # The values match the un-imputed run; only the reported method differs
  expect_equal(res_imputed$PPTESTCD, res_plain$PPTESTCD)
  expect_equal(res_imputed$PPORRES, res_plain$PPORRES)
  expect_true(all(grepl("Imputation: start_conc0", res_imputed$PPANMETH, fixed = TRUE)))
})
