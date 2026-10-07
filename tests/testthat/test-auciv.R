
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

# ============================================================================
# Sparse IV bolus AUC and AUMC
# ============================================================================
# Serial sacrifice after an IV bolus, without a sample at time 0
d_sparse_iv <-
  data.frame(
    time = rep(c(0.25, 0.5, 1, 2, 4, 8, 24), each = 4),
    conc =
      c(9.1, 10.4, 8.7, 9.9,  8.8, 9.5, 8.1, 9.2,  8.2, 7.6, 8.9, 7.9,
        6.4, 7.1, 6.0, 6.9,  4.6, 4.1, 5.0, 4.3,  2.1, 1.8, 2.3, 1.9,
        0.10, 0.08, 0.12, 0.09)
  )
d_sparse_iv$subject <- seq_len(nrow(d_sparse_iv))

# The sparse IV AUC (or AUMC) as a function of the time-point means:  C0 from
# the log-linear back-extrapolation of the first two means, the linear
# trapezoidal rule from time 0, and, with half-life points `idx_hl`, the
# extrapolation with lambda.z refit to their log means
sparse_iv_from_means <- function(means, times, idx_hl, moment) {
  c0 <- means[1]*(means[1]/means[2])^(times[1]/(times[2] - times[1]))
  all_times <- c(0, times)
  values <- c(c0, means)
  if (moment) {
    values <- all_times*values
  }
  ret <- sum(diff(all_times)*(values[-1] + values[-length(values)])/2)
  if (length(idx_hl) > 0) {
    lambda_z <- -unname(stats::coef(stats::lm(log(means[idx_hl]) ~ times[idx_hl]))[2])
    tlast <- times[length(times)]
    clast <- means[length(means)]
    ret <- ret + if (moment) tlast*clast/lambda_z + clast/lambda_z^2 else clast/lambda_z
  }
  ret
}

# The serial-sacrifice standard error from the numeric gradient of
# sparse_iv_from_means()
sparse_iv_numeric_se <- function(d, idx_hl, moment) {
  means <- unname(tapply(d$conc, d$time, mean))
  times <- sort(unique(d$time))
  gradient <- numeric(length(means))
  for (j in seq_along(means)) {
    h <- 1e-6*means[j]
    up <- down <- means
    up[j] <- up[j] + h
    down[j] <- down[j] - h
    gradient[j] <-
      (sparse_iv_from_means(up, times, idx_hl, moment) - sparse_iv_from_means(down, times, idx_hl, moment))/(2*h)
  }
  s2 <- unname(tapply(d$conc, d$time, stats::var))
  n <- unname(tapply(d$conc, d$time, length))
  sqrt(sum(gradient^2*s2/n))
}

test_that("sparse IV bolus AUClast back-extrapolates C0 with its uncertainty", {
  result <- pk.calc.aucivlast_sparse(conc = d_sparse_iv$conc, time = d_sparse_iv$time, subject = d_sparse_iv$subject)
  means <- unname(tapply(d_sparse_iv$conc, d_sparse_iv$time, mean))
  times <- sort(unique(d_sparse_iv$time))
  expect_equal(names(result), c("aucivlast", "aucivlast_se", "aucivlast_df"))
  expect_equal(result$aucivlast, sparse_iv_from_means(means, times, integer(), FALSE))
  expect_equal(result$aucivlast_se, sparse_iv_numeric_se(d_sparse_iv, integer(), FALSE), tolerance = 1e-6)
  expect_false(is.na(result$aucivlast_df))
  expect_equal(attr(result, "method")[3], "Sparse C0: logslope on the mean profile")
  # C0 is the c0 parameter of the mean profile
  expect_equal(
    result$aucivlast - sum(diff(times)*(means[-1] + means[-length(means)])/2),
    times[1]*(pk.calc.c0(conc = means, time = times) + means[1])/2
  )
})

test_that("sparse IV bolus AUCinf,obs adds the uncertainty of C0 and lambda.z", {
  means <- unname(tapply(d_sparse_iv$conc, d_sparse_iv$time, mean))
  times <- sort(unique(d_sparse_iv$time))
  hl <- pk.calc.half.life(conc = means, time = times)
  idx_hl <- which(times >= hl$lambda.z.time.first & times <= hl$lambda.z.time.last)
  args <-
    list(
      conc = d_sparse_iv$conc, time = d_sparse_iv$time, subject = d_sparse_iv$subject,
      lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
      lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points
    )
  auc <- do.call(pk.calc.aucivinf.obs_sparse, args)
  aumc <- do.call(pk.calc.aumcivinf.obs_sparse, args)
  expect_equal(auc$aucivinf.obs, sparse_iv_from_means(means, times, idx_hl, FALSE))
  expect_equal(auc$aucivinf.obs_se, sparse_iv_numeric_se(d_sparse_iv, idx_hl, FALSE), tolerance = 1e-6)
  expect_equal(aumc$aumcivinf.obs, sparse_iv_from_means(means, times, idx_hl, TRUE))
  expect_equal(aumc$aumcivinf.obs_se, sparse_iv_numeric_se(d_sparse_iv, idx_hl, TRUE), tolerance = 1e-6)
  expect_equal(
    attr(auc, "method")[3:4],
    c("Sparse C0: logslope on the mean profile", "Sparse SE: delta method for lambda.z")
  )
})

test_that("C0 does not change the sparse IV bolus AUMC", {
  # The AUMC from time 0 to the first sample is t1^2 ybar_1/2 with the linear
  # trapezoidal rule, so it equals the sparse AUMC with any known
  # concentration at time 0
  result <- pk.calc.aumcivlast_sparse(conc = d_sparse_iv$conc, time = d_sparse_iv$time, subject = d_sparse_iv$subject)
  known_zero <-
    pk.calc.aumclast_sparse(
      conc = c(0, d_sparse_iv$conc), time = c(0, d_sparse_iv$time), subject = c(NA, d_sparse_iv$subject)
    )
  expect_equal(result$aumcivlast, known_zero$aumclast)
  expect_equal(result$aumcivlast_se, known_zero$aumclast_se)
  expect_equal(result$aumcivlast_df, known_zero$aumclast_df)
})

test_that("sparse IV bolus C0 falls back to C1 when the first means rise", {
  d_rise <- d_sparse_iv
  # The second mean is above the first, so logslope does not apply
  d_rise$conc[d_rise$time == 0.5] <- d_rise$conc[d_rise$time == 0.5] + 2
  result <- pk.calc.aucivlast_sparse(conc = d_rise$conc, time = d_rise$time, subject = d_rise$subject)
  means <- unname(tapply(d_rise$conc, d_rise$time, mean))
  times <- sort(unique(d_rise$time))
  w <- c(0, diff(times)/2) + c(diff(times)/2, 0)
  # C0 = ybar_1, so the first mean also carries the weight of the trapezoid
  # from time 0:  t1/2 as its own end and t1/2 through C0
  g <- w
  g[1] <- g[1] + times[1]
  s2 <- unname(tapply(d_rise$conc, d_rise$time, stats::var))
  expect_equal(result$aucivlast, sum(w*means) + times[1]*means[1])
  expect_equal(result$aucivlast_se, sqrt(sum(g^2*s2/4)))
  expect_equal(attr(result, "method")[3], "Sparse C0: c1 on the mean profile")
})

test_that("a zero at time 0 does not become the sparse IV bolus C0", {
  # As for pk.calc.c0(), an imputed (or measured) zero at time 0 is not C0, so
  # the result is the same as without a time-0 concentration
  expected <- pk.calc.aucivlast_sparse(conc = d_sparse_iv$conc, time = d_sparse_iv$time, subject = d_sparse_iv$subject)
  imputed <-
    pk.calc.aucivlast_sparse(
      conc = c(0, d_sparse_iv$conc), time = c(0, d_sparse_iv$time), subject = c(NA, d_sparse_iv$subject)
    )
  measured <-
    pk.calc.aucivlast_sparse(
      conc = c(0, 0, d_sparse_iv$conc), time = c(0, 0, d_sparse_iv$time), subject = c(101, 102, d_sparse_iv$subject)
    )
  expect_equal(imputed, expected)
  expect_equal(measured, expected)
  # Through pk.nca() with the start_conc0 imputation
  d_intervals <- data.frame(start = 0, end = Inf, aucivlast = TRUE)
  d_dose <- data.frame(time = 0, dose = 100)
  res <-
    as.data.frame(suppressMessages(suppressWarnings(pk.nca(PKNCAdata(
      PKNCAconc(d_sparse_iv, conc ~ time | subject, sparse = TRUE),
      PKNCAdose(d_dose, dose ~ time, route = "intravascular"),
      intervals = d_intervals, impute = "start_conc0"
    )))))
  expect_equal(res$PPORRES[res$PPTESTCD == "aucivlast"], expected$aucivlast)
  expect_equal(res$PPORRES[res$PPTESTCD == "aucivlast_se"], expected$aucivlast_se)
})

test_that("a sparse IV bolus with a measured time 0 uses it", {
  d_zero <- rbind(data.frame(time = 0, conc = c(12.1, 11.4, 12.8, 11.9), subject = 101:104), d_sparse_iv)
  result <- pk.calc.aucivlast_sparse(conc = d_zero$conc, time = d_zero$time, subject = d_zero$subject)
  auclast <- pk.calc.auclast_sparse(conc = d_zero$conc, time = d_zero$time, subject = d_zero$subject)
  expect_equal(unname(unlist(result)), unname(unlist(auclast)))
  expect_false(any(grepl("Sparse C0", attr(result, "method"), fixed = TRUE)))
})

test_that("every IV AUC and AUMC calculates for sparse IV bolus data", {
  all_cols <- get.interval.cols()
  # The back-extrapolated percentage needs a measured time 0 (tested above)
  iv_params <- grep("^au[mc]*civ", names(all_cols), value = TRUE)
  iv_params <- iv_params[!grepl("pbext|_(se|df)$", iv_params)]
  d_intervals <- data.frame(start = 0, end = 24)
  d_intervals[iv_params] <- TRUE
  d_dose <- data.frame(time = 0, dose = 100)
  res_sparse <-
    as.data.frame(suppressMessages(suppressWarnings(pk.nca(PKNCAdata(
      PKNCAconc(d_sparse_iv, conc ~ time | subject, sparse = TRUE),
      PKNCAdose(d_dose, dose ~ time, route = "intravascular"),
      intervals = d_intervals, options = list(auc.method = "linear")
    )))))
  d_mean <- stats::aggregate(conc ~ time, d_sparse_iv, mean)
  d_mean$subject <- 1
  res_mean <-
    as.data.frame(suppressMessages(suppressWarnings(pk.nca(PKNCAdata(
      PKNCAconc(d_mean, conc ~ time | subject),
      PKNCAdose(cbind(d_dose, subject = 1), dose ~ time | subject, route = "intravascular"),
      intervals = d_intervals, options = list(auc.method = "linear")
    )))))
  for (current_param in iv_params) {
    value_sparse <- res_sparse$PPORRES[res_sparse$PPTESTCD == current_param]
    value_mean <- res_mean$PPORRES[res_mean$PPTESTCD == current_param]
    expect_false(is.na(value_sparse), info = current_param)
    # The sparse estimators use the linear trapezoidal rule on the mean profile
    expect_equal(value_sparse, value_mean, tolerance = 1e-6, info = current_param)
    # Parameters with a sparse estimator report its standard error
    if (!is.na(all_cols[[current_param]]$FUN_sparse %||% NA)) {
      expect_false(is.na(res_sparse$PPORRES[res_sparse$PPTESTCD == paste0(current_param, "_se")]), info = current_param)
      expect_false(is.na(res_sparse$PPORRES[res_sparse$PPTESTCD == paste0(current_param, "_df")]), info = current_param)
    }
  }
})
