# Regulatory bioequivalence assessment and reference scaling.
#
# Expected values are pinned constants computed from the deterministic
# generate_be_replicate() data (helper-bioequivalence.R) and cross-checked
# during development against PowerTOST 1.5.7 and replicateBE 1.1.3, which are
# NOT dependencies of PKNCA.  Each pinned block notes how its numbers arise.

# be_regulator --------------------------------------------------------------

test_that("be_regulator returns the documented constants for every framework", {
  expect_equal(be_regulator("ABE")$scaling, "none")

  ema <- be_regulator("EMA")
  expect_equal(ema$scaling, "abel")
  expect_equal(ema$cvswitch, 0.30)
  expect_equal(ema$r_const, 0.76)
  expect_equal(ema$cvcap, 0.50)
  expect_true(ema$pe_constr)

  hc <- be_regulator("HC")
  expect_equal(hc$r_const, 0.76)
  expect_equal(hc$cvcap, 0.57382)

  gcc <- be_regulator("GCC")
  expect_equal(gcc$scaling, "abel")
  expect_equal(gcc$cvcap, 0.30)

  fda <- be_regulator("FDA")
  expect_equal(fda$scaling, "rsabe")
  expect_equal(fda$switch_swr, 0.294)
  expect_equal(fda$est_method, "isc")
})

test_that("be_regulator scaling constants match their regulatory definitions", {
  # FDA RSABE: r_const = log(1.25) / sigma_w0 with sigma_w0 = 0.25.
  expect_equal(be_regulator("FDA")$r_const, log(1.25) / 0.25)
  # NTID / HVNTID: r_const = -log(0.9) / 0.1.
  expect_equal(be_regulator("NTID")$r_const, -log(0.9) / 0.1)
  expect_equal(be_regulator("HVNTID")$r_const, -log(0.9) / 0.1)
  # EMA constant 0.76 ~ log(1.25) / sqrt(log(1 + 0.30^2)), rounded by the EMA.
  expect_equal(round(log(1.25) / sqrt(log(1 + 0.30^2)), 2), 0.76)
})

test_that("be_regulator rejects unknown frameworks", {
  expect_error(be_regulator("XYZ"))
})

# be_expand_limits ----------------------------------------------------------

test_that("be_expand_limits reproduces the regulatory acceptance limits", {
  # swR = 0.485616493 (CVwR 51.57%): EMA capped at 50%, HC uncapped, GCC fixed.
  expect_equal(unname(be_expand_limits(0.485616493, "EMA")), c(69.83678, 143.19102), tolerance = 1e-5)
  expect_equal(unname(be_expand_limits(0.485616493, "HC")), c(69.13780, 144.63867), tolerance = 1e-5)
  expect_equal(unname(be_expand_limits(0.485616493, "GCC")), c(75, 400 / 3), tolerance = 1e-9)
  # swR = 0.395143191 (CVwR 41.11%): EMA uncapped expansion.
  expect_equal(unname(be_expand_limits(0.395143191, "EMA")), c(74.05895, 135.02757), tolerance = 1e-5)
})

test_that("be_expand_limits stays at 80-125% below the switching variability", {
  # swR = 0.132 corresponds to CVwR ~ 13% (below the 30% switch).
  expect_equal(unname(be_expand_limits(0.132057326, "EMA")), c(80, 125))
  expect_equal(unname(be_expand_limits(0.132057326, "GCC")), c(80, 125))
  # ABE never widens.
  expect_equal(unname(be_expand_limits(0.6, "ABE")), c(80, 125))
})

test_that("be_expand_limits caps at the framework maximum", {
  # Above the EMA cap (CVwR > 50%) the limits are fixed at 69.84-143.19%.
  expect_equal(unname(be_expand_limits(0.9, "EMA")), c(69.83678, 143.19102), tolerance = 1e-5)
  # GCC is a fixed band for any CVwR above the switch.
  expect_equal(unname(be_expand_limits(0.9, "GCC")), c(75, 400 / 3), tolerance = 1e-9)
})

# be_design -----------------------------------------------------------------

test_that("be_design classifies the standard crossover designs", {
  full <- be_design(
    generate_be_replicate(24, 1, "full"), "subject", "sequence", "period", "treatment", "R"
  )
  expect_equal(full$design, "full_replicate")
  expect_true(full$replicate_reference && full$replicate_test)
  expect_true(all(full$feasible))

  partial <- be_design(
    generate_be_replicate(30, 2, "partial"), "subject", "sequence", "period", "treatment", "R"
  )
  expect_equal(partial$design, "partial_replicate")
  expect_true(partial$replicate_reference)
  expect_false(partial$replicate_test)
  expect_true(partial$feasible[["rsabe"]])
  expect_false(partial$feasible[["ntid"]])

  conv <- be_design(
    generate_be_replicate(16, 3, "2x2"), "subject", "sequence", "period", "treatment", "R"
  )
  expect_equal(conv$design, "2x2x2")
  expect_equal(unname(conv$feasible[c("abe", "abel", "ntid")]), c(TRUE, FALSE, FALSE))
})

test_that("be_design can derive sequences and flags dropout as unbalanced", {
  d <- generate_be_replicate(24, 1, "full")
  expect_equal(
    be_design(d, "subject", NA, "period", "treatment", "R")$sequences,
    c("RTRT", "TRTR")
  )
  expect_false(be_design(d[-3, ], "subject", "sequence", "period", "treatment", "R")$balanced)
})

test_that("be_design errors on an unknown reference value", {
  expect_error(
    be_design(generate_be_replicate(8, 1, "full"), "subject", "sequence", "period", "treatment", "Z"),
    "not found"
  )
})

# be_within_var -------------------------------------------------------------

test_that("be_within_var (method A) matches the ANOVA within-subject variances", {
  # Pinned to the reference implementation's CV.calc on the high-variability
  # full replicate: swR = 0.446... here is dataset-specific.
  d <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  wv <- be_within_var(d, "PK", "subject", "period", "treatment", "R")
  expect_equal(wv$swR, 0.485616493, tolerance = 1e-7)
  expect_equal(wv$cvwr_percent, 51.5704078, tolerance = 1e-5)
  expect_equal(wv$df_wR, 22)
  expect_equal(wv$swT, 0.383008171, tolerance = 1e-7)
  expect_equal(wv$df_wT, 22)
  # swT/swR upper 90% confidence bound (used by the NTID criterion).
  expect_equal(wv$sw_ratio, 0.788705030, tolerance = 1e-7)
  expect_equal(wv$sw_ratio_ci_upper, 1.128639463, tolerance = 1e-7)
})

test_that("be_within_var returns NA test variability for a partial replicate", {
  dp <- generate_be_replicate(30, 505, "partial", cv_wr = 0.40)
  wv <- be_within_var(dp, "PK", "subject", "period", "treatment", "R")
  expect_equal(wv$swR, 0.428849840, tolerance = 1e-7)
  expect_true(is.na(wv$swT))
  expect_true(is.na(wv$sw_ratio))
  expect_error(
    be_within_var(dp, "PK", "subject", "period", "treatment", "R", method = "B"),
    "fully replicated"
  )
})

test_that("be_within_var method B agrees with method A to within a few percent", {
  d <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  a <- be_within_var(d, "PK", "subject", "period", "treatment", "R", method = "A")
  b <- be_within_var(d, "PK", "subject", "period", "treatment", "R", method = "B")
  expect_equal(b$swR, a$swR, tolerance = 0.1)
  expect_equal(b$swT, a$swT, tolerance = 0.1)
})

# Internal criterion building blocks ----------------------------------------

test_that(".be_isc reproduces the intra-subject contrast point estimate", {
  d <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  work <- data.frame(.subject = factor(d$subject), .trt = as.character(d$treatment), .logval = log(d$PK))
  isc <- .be_isc(work, "R", "T", alpha = 0.10)
  expect_equal(isc$gmr_percent, 88.3595729, tolerance = 1e-5)
  expect_equal(isc$se, 0.104543750, tolerance = 1e-7)
  expect_equal(isc$df, 23)
  expect_equal(c(isc$ci_lower, isc$ci_upper), c(73.865065, 105.698331), tolerance = 1e-4)
})

test_that(".be_rsabe_bound is monotone in the point estimate and flips once", {
  # Larger |point estimate| should only ever worsen (increase) the bound.
  b_small <- .be_rsabe_bound(log(1.00), 0.05, 0.09, 30, log(1.25) / 0.25)
  b_large <- .be_rsabe_bound(log(1.20), 0.05, 0.09, 30, log(1.25) / 0.25)
  expect_lt(b_small, b_large)
  # A tiny within-reference variance (s2wR -> 0) makes scaling impossible to pass
  # for a non-unity ratio.
  expect_gt(.be_rsabe_bound(log(1.20), 0.05, 1e-6, 30, log(1.25) / 0.25), 0)
})

# be_assess: expanding-limits frameworks (no oracle dependency) --------------

test_that("be_assess (EMA) reproduces the reference scaling decision", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  # method = "A" uses base-R fixed effects (no modeling-package dependency) and
  # matches the reference implementation's Method A exactly.
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", method = "A")
  expect_s3_class(res, "be_assess")
  expect_equal(res$gmr_percent, 88.359573, tolerance = 1e-5)
  expect_equal(c(res$ci_lower, res$ci_upper), c(75.617477, 103.248804), tolerance = 1e-4)
  expect_equal(res$cvwr_percent, 51.5704078, tolerance = 1e-5)
  expect_equal(c(res$limit_lower, res$limit_upper), c(69.83678, 143.19102), tolerance = 1e-4)
  expect_true(res$pass)
})

test_that("be_assess applies HC, GCC, and ABE limits correctly", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  hc <- be_assess(d, "treatment", "R", "auclast", regulator = "HC", method = "A")
  expect_equal(c(hc$limit_lower, hc$limit_upper), c(69.13780, 144.63867), tolerance = 1e-4)
  expect_true(hc$pass)

  gcc <- be_assess(d, "treatment", "R", "auclast", regulator = "GCC", method = "A")
  expect_equal(c(gcc$limit_lower, gcc$limit_upper), c(75, 400 / 3), tolerance = 1e-6)
  expect_true(gcc$pass)

  # Unscaled ABE fails here because the conventional CI dips below 80%.
  abe <- be_assess(d, "treatment", "R", "auclast", regulator = "ABE", method = "A")
  expect_equal(c(abe$limit_lower, abe$limit_upper), c(80, 125))
  expect_false(abe$pass)
  expect_true(is.na(abe$swr))
})

# be_assess: FDA reference-scaled family (no oracle dependency) ---------------

test_that("be_assess (FDA RSABE) computes the linearized criterion", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "FDA")
  expect_equal(res$gmr_percent, 88.3595729, tolerance = 1e-5)
  expect_equal(res$criterion, -0.012265464, tolerance = 1e-6)
  expect_true(is.na(res$limit_lower))
  expect_true(res$pass)
})

test_that("be_assess (FDA RSABE) falls back to unscaled ABE when swR < 0.294", {
  d <- be_replicate_long(generate_be_replicate(24, 2024, "full", cv_wr = 0.12, cv_wt = 0.12, gmr = 1.02))
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "FDA")
  # Below the switch the criterion is not used and the conventional limits apply.
  expect_true(is.na(res$criterion))
  expect_equal(c(res$limit_lower, res$limit_upper), c(80, 125))
  expect_true(res$pass)
})

test_that("be_assess (NTID) enforces all three gates", {
  # High variability: scaled bound and ratio pass, but the conventional CI dips
  # below 80% so NTID fails.
  d_hi <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  ntid_hi <- be_assess(d_hi, "treatment", "R", "auclast", regulator = "NTID")
  expect_equal(ntid_hi$criterion, -0.034465877, tolerance = 1e-6)
  expect_false(ntid_hi$pass)

  # Low variability with a tight CI: all three gates pass.
  d_lo <- be_replicate_long(generate_be_replicate(24, 2024, "full", cv_wr = 0.12, cv_wt = 0.12, gmr = 1.02))
  ntid_lo <- be_assess(d_lo, "treatment", "R", "auclast", regulator = "NTID")
  expect_true(ntid_lo$pass)
})

test_that("be_assess (HVNTID) uses the scaled bound and ratio constraint", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "HVNTID")
  expect_equal(res$criterion, -0.034465877, tolerance = 1e-6)
  expect_true(res$pass)
})

test_that("be_assess errors when the design cannot support the framework", {
  dp <- be_replicate_long(generate_be_replicate(30, 505, "partial", cv_wr = 0.40))
  expect_error(
    be_assess(dp, "treatment", "R", "auclast", regulator = "NTID"),
    "fully replicated"
  )
  # But RSABE and ABEL only need a replicated reference and still work.
  expect_true(is.finite(be_assess(dp, "treatment", "R", "auclast", regulator = "FDA")$criterion))
})

test_that("be_assess warns about and skips missing endpoints", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  expect_warning(
    res <- be_assess(d, "treatment", "R", c("auclast", "cmax"), regulator = "FDA"),
    "not found and skipped: cmax"
  )
  expect_equal(res$endpoint, "auclast")
  expect_error(
    be_assess(d, "treatment", "R", "cmax", regulator = "FDA"),
    "None of the requested endpoints"
  )
})

test_that("be_assess accepts the reported PE-constraint failure", {
  # GMR pushed above 125% so the point-estimate constraint fails even though the
  # widened limits are very wide.
  d <- be_replicate_long(generate_be_replicate(24, 11, "full", cv_wr = 0.5, cv_wt = 0.5, gmr = 1.35))
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", method = "A")
  expect_gt(res$gmr_percent, 125)
  expect_false(res$pass)
})

# be_assess: method B (mixed model) requires the modeling packages ------------

test_that("be_assess method B (mixed model) matches method A on a balanced design", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  a <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", method = "A")
  b <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", method = "B")
  expect_equal(b$gmr_percent, a$gmr_percent, tolerance = 1e-6)
  expect_equal(b$ci_lower, a$ci_lower, tolerance = 1e-6)
  expect_equal(b$ci_upper, a$ci_upper, tolerance = 1e-6)
})

# be_compare ----------------------------------------------------------------

test_that("be_compare assesses one dataset under several frameworks", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  cmp <- be_compare(
    d, "treatment", "R", "auclast",
    regulators = c("EMA", "HC", "GCC", "FDA", "NTID", "HVNTID"), method = "A"
  )
  expect_s3_class(cmp, "be_compare")
  expect_setequal(unique(cmp$regulator), c("EMA", "HC", "GCC", "FDA", "NTID", "HVNTID"))
  # The same data: EMA/HC/GCC/FDA/HVNTID pass, NTID fails (conventional CI).
  passes <- stats::setNames(cmp$pass, cmp$regulator)
  expect_true(all(passes[c("EMA", "HC", "GCC", "FDA", "HVNTID")]))
  expect_false(passes[["NTID"]])

  grid <- summary(cmp)
  expect_s3_class(grid, "summary_be_compare")
  expect_true("FDA" %in% names(grid))
})

test_that("be_compare skips frameworks the design cannot support", {
  dp <- be_replicate_long(generate_be_replicate(30, 505, "partial", cv_wr = 0.40))
  expect_warning(
    cmp <- be_compare(dp, "treatment", "R", "auclast", regulators = c("EMA", "FDA", "NTID"), method = "A"),
    "Skipping NTID"
  )
  expect_setequal(unique(cmp$regulator), c("EMA", "FDA"))
})

# S3 methods and the full PKNCAresults pipeline ------------------------------

test_that("be_assess S3 methods print and summarize without error", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "FDA")
  expect_output(print(res), "Bioequivalence assessment: FDA")
  expect_s3_class(as.data.frame(res), "data.frame")
  expect_false(inherits(as.data.frame(res), "be_assess"))
  expect_output(print(summary(res)), "pass = bioequivalent")
  expect_output(print(be_regulator("EMA")), "regulator: EMA")
  expect_output(print(be_design(generate_be_replicate(8, 1, "full"), "subject", "sequence", "period", "treatment", "R")), "full_replicate")
  expect_output(print(be_within_var(generate_be_replicate(8, 1, "full"), "PK", "subject", "period", "treatment", "R")), "Within-subject")
})

test_that("be_assess runs end-to-end from a PKNCAresults object", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- generate_be_replicate(12, 20240501, "full", cv_wr = 0.30, cv_wt = 0.28)
  # Build minimal concentration data: one observation per subject/period is not
  # enough for NCA, so expand each row into a short profile.
  conc <- do.call(rbind, lapply(seq_len(nrow(d)), function(i) {
    times <- c(0, 1, 2, 4, 8)
    cmax <- d$PK[i] / 10
    data.frame(
      subject = d$subject[i], sequence = d$sequence[i], period = d$period[i],
      treatment = d$treatment[i], time = times,
      conc = c(0, cmax, cmax * 0.8, cmax * 0.5, cmax * 0.2)
    )
  }))
  dose <- conc[conc$time == 0, c("subject", "sequence", "period", "treatment")]
  dose$dose <- 100
  dose$time <- 0
  o_conc <- PKNCAconc(conc, conc ~ time | sequence + period + treatment + subject)
  o_dose <- PKNCAdose(dose, dose ~ time | sequence + period + treatment + subject)
  o_res <- suppressWarnings(suppressMessages(
    pk.nca(PKNCAdata(o_conc, o_dose, intervals = data.frame(start = 0, end = Inf, cmax = TRUE, auclast = TRUE)))
  ))
  res <- suppressMessages(be_assess(o_res, "treatment", "R", c("cmax", "auclast"), regulator = "EMA"))
  expect_setequal(res$endpoint, c("cmax", "auclast"))
  expect_true(all(is.finite(res$gmr_percent)))
  expect_true(all(res$ci_lower < res$ci_upper))
})
