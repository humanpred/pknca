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
  # NTID: r_const = -log(0.9) / 0.1; HVNTID is unscaled (no r_const).
  expect_equal(be_regulator("NTID")$r_const, -log(0.9) / 0.1)
  expect_true(is.na(be_regulator("HVNTID")$r_const))
  # swT/swR ratio cap applies to the narrow therapeutic index frameworks only.
  expect_equal(be_regulator("NTID")$sw_ratio_cap, 2.5)
  expect_equal(be_regulator("HVNTID")$sw_ratio_cap, 2.5)
  expect_true(is.na(be_regulator("EMA")$sw_ratio_cap))
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

test_that("be_within_var (anova) matches the ANOVA within-subject variances", {
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
    be_within_var(dp, "PK", "subject", "period", "treatment", "R", model_type = "nlme"),
    "fully replicated"
  )
})

test_that("be_within_var nlme agrees with anova to within a few percent", {
  d <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  a <- be_within_var(d, "PK", "subject", "period", "treatment", "R", model_type = "anova")
  b <- be_within_var(d, "PK", "subject", "period", "treatment", "R", model_type = "nlme")
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
  # Signature: (pe_log, se, df_pe, s2wR, dfRR, r_const).
  # Larger |point estimate| should only ever worsen (increase) the bound.
  b_small <- .be_rsabe_bound(log(1.00), 0.05, 30, 0.09, 30, log(1.25) / 0.25)
  b_large <- .be_rsabe_bound(log(1.20), 0.05, 30, 0.09, 30, log(1.25) / 0.25)
  expect_lt(b_small, b_large)
  # A tiny within-reference variance (s2wR -> 0) makes scaling impossible to pass
  # for a non-unity ratio.
  expect_gt(.be_rsabe_bound(log(1.20), 0.05, 30, 1e-6, 30, log(1.25) / 0.25), 0)
})

test_that(".be_rsabe_bound matches the PowerTOST RSABE/NTID criterion formula", {
  # Cross-check the linearized bound against an independent recomputation of the
  # same Howe/Hyslop criterion used by PowerTOST's power.RSABE / power.NTID:
  #   hw = qt(0.95, df_pe) * se; Em = pe^2 - se^2; Es = r^2 * s2wR
  #   Cm = max((pe-hw)^2, (pe+hw)^2); Cs = Es * dfRR / qchisq(0.95, dfRR)
  #   bound = Em - Es + sqrt((Cm-Em)^2 + (Cs-Es)^2)
  pt_bound <- function(pe, se, df_pe, s2wR, dfRR, r) {
    hw <- stats::qt(0.95, df_pe) * se
    Em <- pe^2 - se^2
    Es <- r^2 * s2wR
    Cm <- max((pe - hw)^2, (pe + hw)^2)
    Cs <- Es * dfRR / stats::qchisq(0.95, dfRR)
    Em - Es + sqrt((Cm - Em)^2 + (Cs - Es)^2)
  }
  for (args in list(
    list(pe = log(1.05), se = 0.10, df_pe = 23, s2wR = 0.236, dfRR = 22, r = log(1.25) / 0.25),
    list(pe = log(0.92), se = 0.06, df_pe = 35, s2wR = 0.09, dfRR = 34, r = -log(0.9) / 0.1)
  )) {
    expect_equal(
      do.call(.be_rsabe_bound, unname(args[c("pe", "se", "df_pe", "s2wR", "dfRR", "r")])),
      do.call(pt_bound, args),
      tolerance = 1e-10
    )
  }
})

# be_assess: expanding-limits frameworks (no oracle dependency) --------------

test_that("be_assess (EMA) reproduces the reference scaling decision", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  # model_type = "anova" uses base-R fixed effects (no modeling-package dependency) and
  # matches the reference implementation's Method A exactly.
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", model_type = "anova")
  expect_s3_class(res, "be_assess")
  expect_equal(res$gmr_percent, 88.359573, tolerance = 1e-5)
  expect_equal(c(res$ci_lower, res$ci_upper), c(75.617477, 103.248804), tolerance = 1e-4)
  expect_equal(res$cvwr_percent, 51.5704078, tolerance = 1e-5)
  expect_equal(c(res$limit_lower, res$limit_upper), c(69.83678, 143.19102), tolerance = 1e-4)
  expect_true(res$pass)
})

test_that("be_assess applies HC, GCC, and ABE limits correctly", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  hc <- be_assess(d, "treatment", "R", "auclast", regulator = "HC", model_type = "anova")
  expect_equal(c(hc$limit_lower, hc$limit_upper), c(69.13780, 144.63867), tolerance = 1e-4)
  expect_true(hc$pass)

  gcc <- be_assess(d, "treatment", "R", "auclast", regulator = "GCC", model_type = "anova")
  expect_equal(c(gcc$limit_lower, gcc$limit_upper), c(75, 400 / 3), tolerance = 1e-6)
  expect_true(gcc$pass)

  # Unscaled ABE fails here because the conventional CI dips below 80%.
  abe <- be_assess(d, "treatment", "R", "auclast", regulator = "ABE", model_type = "anova")
  expect_equal(c(abe$limit_lower, abe$limit_upper), c(80, 125))
  expect_false(abe$pass)
  expect_true(is.na(abe$swr))
})

# be_assess: FDA reference-scaled family (no oracle dependency) ---------------

test_that("be_assess (FDA RSABE) computes the linearized criterion", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "FDA")
  expect_equal(res$gmr_percent, 88.3595729, tolerance = 1e-5)
  # Linearized Howe/Hyslop bound; equals the PowerTOST power.RSABE criterion.
  expect_equal(res$criterion, -0.073963079, tolerance = 1e-6)
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
  expect_equal(ntid_hi$criterion, -0.130502036, tolerance = 1e-6)
  expect_false(ntid_hi$pass)

  # Low variability with a tight CI: all three gates pass.
  d_lo <- be_replicate_long(generate_be_replicate(24, 2024, "full", cv_wr = 0.12, cv_wt = 0.12, gmr = 1.02))
  ntid_lo <- be_assess(d_lo, "treatment", "R", "auclast", regulator = "NTID")
  expect_true(ntid_lo$pass)
})

test_that("be_assess (HVNTID) is unscaled: conventional CI plus the ratio bound", {
  # HVNTID has no reference-scaled bound (criterion is NA); it needs the
  # conventional 90% CI within 80-125% and swT/swR upper bound <= 2.5.
  d_hi <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  hv_hi <- be_assess(d_hi, "treatment", "R", "auclast", regulator = "HVNTID")
  expect_true(is.na(hv_hi$criterion))
  expect_false(hv_hi$pass) # conventional CI dips below 80%
  d_lo <- be_replicate_long(generate_be_replicate(24, 2024, "full", cv_wr = 0.12, cv_wt = 0.12, gmr = 1.02))
  expect_true(be_assess(d_lo, "treatment", "R", "auclast", regulator = "HVNTID")$pass)
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
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", model_type = "anova")
  expect_gt(res$gmr_percent, 125)
  expect_false(res$pass)
})

# be_assess: method B (mixed model) requires the modeling packages ------------

test_that("be_assess method B (mixed model) matches method A on a balanced design", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  a <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", model_type = "anova")
  b <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", model_type = "lmer")
  expect_equal(b$gmr_percent, a$gmr_percent, tolerance = 1e-6)
  expect_equal(b$ci_lower, a$ci_lower, tolerance = 1e-6)
  expect_equal(b$ci_upper, a$ci_upper, tolerance = 1e-6)
})

# be_compare ----------------------------------------------------------------

test_that("be_compare assesses one dataset under several frameworks", {
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  cmp <- be_compare(
    d, "treatment", "R", "auclast",
    regulators = c("EMA", "HC", "GCC", "FDA", "NTID", "HVNTID"), model_type = "anova"
  )
  expect_s3_class(cmp, "be_compare")
  expect_setequal(unique(cmp$regulator), c("EMA", "HC", "GCC", "FDA", "NTID", "HVNTID"))
  # The same data: EMA/HC/GCC (widened limits) and FDA (reference scaling) pass;
  # NTID and HVNTID fail because the conventional 90% CI dips below 80%.
  passes <- stats::setNames(cmp$pass, cmp$regulator)
  expect_true(all(passes[c("EMA", "HC", "GCC", "FDA")]))
  expect_false(passes[["NTID"]])
  expect_false(passes[["HVNTID"]])

  grid <- summary(cmp)
  expect_s3_class(grid, "summary_be_compare")
  expect_true("FDA" %in% names(grid))
})

test_that("be_compare skips frameworks the design cannot support", {
  dp <- be_replicate_long(generate_be_replicate(30, 505, "partial", cv_wr = 0.40))
  expect_warning(
    cmp <- be_compare(dp, "treatment", "R", "auclast", regulators = c("EMA", "FDA", "NTID"), model_type = "anova"),
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
  o_conc <- PKNCAconc(conc, conc ~ time | sequence + period + treatment + subject,
                      concu = "ng/mL", timeu = "h", amountu = "mg")
  o_dose <- PKNCAdose(dose, dose ~ time | sequence + period + treatment + subject)
  o_res <- suppressWarnings(suppressMessages(
    pk.nca(PKNCAdata(o_conc, o_dose, intervals = data.frame(start = 0, end = Inf, cmax = TRUE, auclast = TRUE)))
  ))
  res <- suppressMessages(be_assess(o_res, "treatment", "R", c("cmax", "auclast"), regulator = "EMA"))
  expect_setequal(res$endpoint, c("cmax", "auclast"))
  expect_true(all(is.finite(res$gmr_percent)))
  expect_true(all(res$ci_lower < res$ci_upper))
})

# Pipeline stage functions ---------------------------------------------------

test_that("be_fit_model_single dispatches and bundles within-variances", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  ds <- be_dataset(be_replicate_long(generate_be_replicate(24, 20240501, "full")),
                   "treatment", "R", "auclast")
  ds_ep <- ds$data[ds$data$PPTESTCD == "auclast", ]
  for (mt in c("lmer", "anova")) {
    fit <- be_fit_model_single(ds_ep, mt, scaling = TRUE)
    expect_s3_class(fit, "be_fit")
    expect_identical(fit$model_type, mt)
    expect_equal(fit$ref_var$sw, 0.485616493, tolerance = 1e-7) # ANOVA swR, shared
  }
})

test_that("be_extract_param returns both the model and ISC point estimates", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  ds <- be_dataset(be_replicate_long(generate_be_replicate(24, 20240501, "full")),
                   "treatment", "R", "auclast")
  ds_ep <- ds$data[ds$data$PPTESTCD == "auclast", ]
  p <- be_extract_param(be_fit_model_single(ds_ep, "lmer"), ds_ep, alpha = 0.10)
  # lmer model contrast == replicateBE method.A on the balanced design
  expect_equal(p$model_gmr_percent, 88.359573, tolerance = 1e-5)
  expect_equal(c(p$model_ci_lower, p$model_ci_upper), c(75.617477, 103.248804), tolerance = 1e-4)
  # ISC point estimate (wider, used by the FDA family)
  expect_equal(p$isc_gmr_percent, 88.3595729, tolerance = 1e-5)
  expect_equal(p$swr, 0.485616493, tolerance = 1e-7)
})

test_that("be_table applies the regulator decision to extracted parameters", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  ds <- be_dataset(be_replicate_long(generate_be_replicate(24, 20240501, "full")),
                   "treatment", "R", "auclast")
  ds_ep <- ds$data[ds$data$PPTESTCD == "auclast", ]
  p <- be_extract_param(be_fit_model_single(ds_ep, "lmer"), ds_ep, alpha = 0.10)
  p$endpoint <- "auclast"
  tab <- be_table(p, "EMA", alpha = 0.10, design = "full_replicate", model_type = "lmer")
  expect_equal(c(tab$limit_lower, tab$limit_upper), c(69.83678, 143.19102), tolerance = 1e-4)
  expect_true(tab$pass)
  expect_identical(tab$regulator, "EMA")
})

test_that("model_type lmer and anova give the same GMR on a balanced design", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  lmer_res <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", model_type = "lmer")
  anova_res <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", model_type = "anova")
  expect_equal(lmer_res$gmr_percent, anova_res$gmr_percent, tolerance = 1e-6)
  expect_equal(lmer_res$ci_lower, anova_res$ci_lower, tolerance = 1e-6)
})

# Design-steered model selection, geometric means, and units ------------------

test_that("be_design recommends and be_assess auto-selects the model by design", {
  full <- be_design(generate_be_replicate(24, 1, "full"), "subject", "sequence", "period", "treatment", "R")
  conv <- be_design(generate_be_replicate(16, 3, "2x2"), "subject", "sequence", "period", "treatment", "R")
  expect_identical(full$recommended_model_type, "lmer")
  expect_identical(conv$recommended_model_type, "anova")
})

test_that("be_assess steers model_type by design but the FDA family stays anova", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  full <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  conv <- be_replicate_long(generate_be_replicate(16, 9, "2x2", cv_wr = 0.3, cv_wt = 0.3))
  expect_identical(be_assess(full, "treatment", "R", "auclast", regulator = "ABE")$model_type, "lmer")
  expect_identical(be_assess(conv, "treatment", "R", "auclast", regulator = "ABE")$model_type, "anova")
  # FDA always uses the intra-subject-contrast (anova) path regardless of design
  expect_identical(be_assess(full, "treatment", "R", "auclast", regulator = "FDA")$model_type, "anova")
})

test_that("model_type nlme requires a fully replicated design", {
  dp <- be_replicate_long(generate_be_replicate(30, 505, "partial", cv_wr = 0.40))
  expect_error(
    be_assess(dp, "treatment", "R", "auclast", regulator = "FDA", model_type = "nlme"),
    "fully replicated"
  )
})

test_that("be_assess reports geometric means with measurement-scale 90% CIs", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  res <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA")
  for (col in c("gm_reference", "gm_reference_lower", "gm_reference_upper",
                "gm_test", "gm_test_lower", "gm_test_upper")) {
    expect_true(col %in% names(res))
  }
  expect_true(res$gm_reference_lower < res$gm_reference && res$gm_reference < res$gm_reference_upper)
  expect_true(res$gm_test_lower < res$gm_test && res$gm_test < res$gm_test_upper)
  # the geometric mean ratio equals gm_test / gm_reference
  expect_equal(res$gmr_percent, res$gm_test / res$gm_reference * 100, tolerance = 1e-6)
})

test_that("be_assess omits the units column with a warning when units are absent", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  d$PPORRESU <- NULL # remove the units column
  expect_warning(
    res <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA"),
    "omitting the .units. column"
  )
  expect_false("units" %in% names(res))
})

test_that("units flow from a data.frame via the PPORRESU/PPSTRESU column", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"), units = "ng/mL")
  expect_identical(
    be_assess(d, "treatment", "R", "auclast", regulator = "EMA")$units, "ng/mL"
  )
  # PPSTRES takes precedence over PPORRES, and so does its PPSTRESU column
  d$PPSTRES <- d$PPORRES
  d$PPSTRESU <- "ug/mL"
  expect_identical(
    be_assess(d, "treatment", "R", "auclast", regulator = "EMA")$units, "ug/mL"
  )
})

test_that("be_assess output is sorted by endpoint (requested) then reference-first test", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  base <- generate_be_replicate(24, 20240501, "full")
  d <- rbind(be_replicate_long(base, "cmax"), be_replicate_long(base, "auclast"))
  res <- be_assess(d, "treatment", "R", c("cmax", "auclast"), regulator = "EMA")
  expect_identical(res$endpoint, c("cmax", "auclast"))
  # per-endpoint units differ
  expect_identical(res$units, c("ng/mL", "h*ng/mL"))
})

test_that("be_assess attaches a methods caption", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  ema <- suppressWarnings(be_assess(d, "treatment", "R", "auclast", regulator = "EMA"))
  expect_match(attr(ema, "caption"), "least-squares means")
  expect_match(attr(ema, "caption"), "mixed-effects model")
  fda <- suppressWarnings(be_assess(d, "treatment", "R", "auclast", regulator = "FDA"))
  expect_match(attr(fda, "caption"), "intra-subject contrasts")
  expect_match(attr(fda, "caption"), "Howe/Hyslop")
})

test_that("be_compare emits the units-missing warning only once", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  d$PPORRESU <- NULL # unit-less
  n <- 0L
  withCallingHandlers(
    be_compare(d, "treatment", "R", "auclast", regulators = c("EMA", "HC", "GCC", "FDA")),
    pknca_be_units_missing = function(w) {
      n <<- n + 1L
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(n, 1L)
})

# Friendlier defaults and the non-log-normal guard ---------------------------

test_that("be_assess defaults to ABE so a simple 2x2 works out of the box", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  expect_identical(formals(be_assess)$regulator, "ABE")
  d <- be_replicate_long(generate_be_replicate(16, 9, "2x2", cv_wr = 0.3, cv_wt = 0.3))
  res <- be_assess(d, "treatment", "R", "auclast") # no regulator argument
  expect_identical(res$regulator, "ABE")
})

test_that("be_compare includes ABE so a 2x2 degrades gracefully", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(16, 9, "2x2", cv_wr = 0.3, cv_wt = 0.3))
  cmp <- suppressWarnings(be_compare(d, "treatment", "R", "auclast"))
  expect_identical(unique(cmp$regulator), "ABE")
})

test_that("be_dataset warns for non-log-normal endpoints (e.g. Tmax)", {
  d <- be_replicate_long(generate_be_replicate(16, 9, "2x2"), "tmax")
  expect_warning(
    be_dataset(d, "treatment", "R", "tmax"),
    "not log-normal"
  )
})
