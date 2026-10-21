# The FDA mixed-effects model for unscaled average bioequivalence (SAS
# RANDOM TRT/TYPE=FA0(2), REPEATED/GRP=TRT, DDFM=SATTERTH).  The anchors are
# known answers (with complete data the model reproduces the intra-subject
# contrasts with n - 2 degrees of freedom), nlme as an independent REML fitter,
# and finite-difference checks of the analytic derivatives.

# Standardized single-endpoint frame (as from be_dataset()) with the reference
# first in the treatment factor.
fda_work <- function(d) {
  w <- be_isc_work(d)
  w$.trt <- stats::relevel(factor(w$.trt), ref = "R")
  w
}

# The same model fit by nlme: correlated treatment random effects (unstructured)
# and treatment-specific residual variances.
fda_nlme <- function(w) {
  nlme::lme(
    .logval ~ .sequence + .period + .trt,
    random = list(.subject = nlme::pdSymm(~ 0 + .trt)),
    weights = nlme::varIdent(form = ~ 1 | .trt),
    data = w, method = "REML",
    control = nlme::lmeControl(opt = "optim", returnObject = TRUE)
  )
}

# REML log-likelihood at natural parameters, for numerical derivatives.
fda_loglik <- function(theta, d) {
  .be_fda_reml(theta, d)$loglik
}

# An nlme fit's covariance parameters on the natural scale of .be_fda_reml(),
# with an unidentified residual variance folded into G.
fda_nlme_theta <- function(fit, d) {
  G <- as.matrix(nlme::getVarCov(fit))
  mult <- stats::coef(fit$modelStruct$varStruct, unconstrained = FALSE, allCoef = TRUE)[d$levels]
  s2 <- (fit$sigma * mult)^2
  diag(G)[!d$replicated] <- diag(G)[!d$replicated] + s2[!d$replicated]
  c(G[lower.tri(G, diag = TRUE)], s2[d$replicated])
}

# The FDA model and nlme agree when nlme converges, and otherwise the FDA fit
# has at least nlme's REML log-likelihood and agrees to within nlme's
# convergence.  `tol` is the relative tolerance for the estimate and its
# standard error.
expect_fda_matches_nlme <- function(w, tol) {
  d <- .be_fda_design(w)
  m <- .be_fda_mixed(w)
  nf <- fda_nlme(w)
  tt <- summary(nf)$tTable
  expect_gte(m$loglik, fda_loglik(fda_nlme_theta(nf, d), d) - 1e-9)
  expect_equal(m$contrasts$T$pe_log, tt[".trtT", "Value"], tolerance = tol)
  expect_equal(m$contrasts$T$se, tt[".trtT", "Std.Error"], tolerance = tol)
}

test_that("with complete data the FDA mixed model reproduces the intra-subject contrasts on n - 2 df", {
  full <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  cases <- list(
    full = full,
    unbalanced = full[!(full$subject %in% c("1", "3")), ],
    two_by_two = generate_be_replicate(24, 20240501, "2x2", cv_wr = 0.3, cv_wt = 0.3),
    large = generate_be_replicate(100, 11, "full", cv_wr = 0.4, cv_wt = 0.35)
  )
  for (nm in names(cases)) {
    w <- fda_work(cases[[nm]])
    fda <- .be_fda_mixed(w)$contrasts$T
    isc <- .be_isc(w, "R", "T")
    expect_equal(fda$pe_log, isc$pe_log, tolerance = 1e-7, label = nm)
    expect_equal(fda$se, isc$se, tolerance = 1e-5, label = nm)
    expect_equal(fda$df, isc$df, tolerance = 1e-4, label = nm)
  }
})

test_that("the FDA mixed model matches nlme with incomplete data and for a partial replicate", {
  full <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  partial <- generate_be_replicate(24, 20240501, "partial", cv_wr = 0.45, cv_wt = 0.40)
  cases <- list(
    full_incomplete = full[-c(which(full$subject == "5")[4], which(full$subject == "8")[2]), ],
    partial = partial,
    partial_incomplete = partial[-which(partial$subject == "4")[2], ]
  )
  # The full replicate identifies every covariance parameter, so nlme
  # converges to the same fit.
  expect_fda_matches_nlme(fda_work(cases$full_incomplete), tol = 1e-5)
  # A partial replicate's test residual variance is not identifiable, and nlme
  # stops short of the REML optimum.
  expect_fda_matches_nlme(fda_work(cases$partial), tol = 1e-3)
  expect_fda_matches_nlme(fda_work(cases$partial_incomplete), tol = 1e-3)
  # With incomplete data the model differs from the intra-subject contrasts,
  # which drop the incomplete subjects.
  w <- fda_work(cases$full_incomplete)
  expect_false(isTRUE(all.equal(.be_fda_mixed(w)$contrasts$T$pe_log, .be_isc(w, "R", "T")$pe_log)))
  # Satterthwaite degrees of freedom at an interior optimum.
  expect_equal(.be_fda_mixed(w)$contrasts$T$df, 22.4730, tolerance = 1e-4)
})

test_that("the analytic gradient and information match finite differences", {
  w <- fda_work(generate_be_replicate(24, 20240501, "partial", cv_wr = 0.45, cv_wt = 0.40))
  d <- .be_fda_design(w)
  u <- .be_fda_start(d, 0.5)
  numeric_grad <- vapply(seq_along(u), function(j) {
    h <- 1e-6 * max(1, abs(u[j]))
    (.be_fda_objective(replace(u, j, u[j] + h), d) - .be_fda_objective(replace(u, j, u[j] - h), d)) / (2 * h)
  }, numeric(1))
  expect_equal(.be_fda_objective_grad(u, d), numeric_grad, tolerance = 1e-5)

  wf <- fda_work(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  df <- .be_fda_design(wf)
  theta <- .be_fda_mixed(wf)$theta
  fit <- .be_fda_reml(theta, df)
  expect_equal(
    .be_fda_information(fit, df),
    -stats::optimHess(theta, fda_loglik, d = df, control = list(ndeps = rep(1e-5, length(theta)))),
    tolerance = 1e-5
  )
  # The REML gradient vanishes at an interior optimum.
  expect_lt(max(abs(.be_fda_gradient(fit, df))), 1e-3)
})

test_that("a fit with a singular between-subject covariance uses the Cholesky-scale information", {
  # The REML optimum has a singular G (SAS reports that G is not positive
  # definite).  The degrees of freedom come from the information on the
  # Cholesky (FA0) scale, where the optimum is stationary.
  w <- fda_work(generate_be_replicate(48, 7, "full", cv_wr = 0.3, cv_wt = 0.5))
  m <- .be_fda_mixed(w)
  G <- matrix(c(m$theta[1], m$theta[2], m$theta[2], m$theta[3]), 2)
  expect_lt(min(eigen(G, symmetric = TRUE)$values), 1e-8)
  expect_fda_matches_nlme(w, tol = 1e-3)
  expect_equal(m$contrasts$T$df, 118.4934, tolerance = 1e-4)
})

test_that("the FDA mixed model handles several test formulations and rejects an aliased treatment", {
  d <- generate_be_williams()
  w <- data.frame(
    .subject = factor(d$subject), .sequence = factor(d$sequence),
    .period = factor(d$period), .trt = stats::relevel(factor(d$treatment), ref = "R"),
    .logval = log(d$PPORRES)
  )
  m <- .be_fda_mixed(w)
  expect_named(m$contrasts, c("T1", "T2"))
  for (tl in c("T1", "T2")) {
    expect_true(is.finite(m$contrasts[[tl]]$se))
    expect_gt(m$contrasts[[tl]]$df, 0)
  }
  # Every subject gets T then R, so treatment is aliased with period.
  fixed_order <- generate_be_replicate(24, 20240501, "2x2")
  fixed_order <- fixed_order[fixed_order$sequence == "TR", ]
  expect_error(.be_fda_mixed(fda_work(fixed_order)), class = "pknca_error_be_fda_model_aliased")
})

test_that("model_type = 'isc' uses the FDA mixed model for the ratio and keeps the ANOVA for a parallel design", {
  full <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  incomplete <- full[-c(which(full$subject == "5")[4], which(full$subject == "8")[2]), ]
  ds <- be_dataset(be_replicate_long(incomplete), "treatment", "R", "auclast")
  ds_ep <- ds$data
  fit <- be_fit_model_single(ds_ep, "isc")
  p <- be_extract_param(fit, ds_ep, alpha = 0.10)
  fc <- fit$fda$contrasts$T
  expect_equal(p$model_gmr_percent, 100 * exp(fc$pe_log), tolerance = 1e-10)
  expect_equal(
    c(p$model_ci_lower, p$model_ci_upper),
    100 * exp(fc$pe_log + c(-1, 1) * stats::qt(0.95, fc$df) * fc$se),
    tolerance = 1e-10
  )
  expect_equal(p$model_df, fc$df)

  par_ds <- be_dataset(generate_be_parallel(), "treatment", "R", "auclast")
  expect_null(be_fit_model_single(par_ds$data, "isc")$fda)
})

test_that("the FDA unscaled criteria use the FDA mixed model and report its interval", {
  full <- generate_be_replicate(24, 2024, "full", cv_wr = 0.12, cv_wt = 0.12, gmr = 1.02)
  incomplete <- full[-c(which(full$subject == "5")[4], which(full$subject == "8")[2]), ]
  long <- be_replicate_long(incomplete)
  ds <- be_dataset(long, "treatment", "R", "auclast")
  p <- be_extract_param(be_fit_model_single(ds$data, "isc"), ds$data, alpha = 0.10)
  # swR < 0.294, so FDA RSABE falls back to the unscaled criterion.
  fda <- suppressWarnings(be_assess(long, "treatment", "R", "auclast", regulator = "FDA"))
  expect_true(is.na(fda$criterion))
  expect_equal(c(fda$gmr_percent, fda$ci_lower, fda$ci_upper),
               c(p$model_gmr_percent, p$model_ci_lower, p$model_ci_upper), tolerance = 1e-10)
  expect_false(isTRUE(all.equal(fda$ci_lower, p$isc_ci_lower)))
  # NTID: the scaled bound uses the intra-subject contrasts, and the row shows
  # the interval of the unscaled criterion.
  ntid <- suppressWarnings(be_assess(long, "treatment", "R", "auclast", regulator = "NTID"))
  expect_equal(c(ntid$ci_lower, ntid$ci_upper), c(p$model_ci_lower, p$model_ci_upper), tolerance = 1e-10)
  expect_false(is.na(ntid$criterion))
  hv <- suppressWarnings(be_assess(long, "treatment", "R", "auclast", regulator = "HVNTID"))
  expect_equal(c(hv$ci_lower, hv$ci_upper), c(p$model_ci_lower, p$model_ci_upper), tolerance = 1e-10)
  expect_match(attr(fda, "caption"), "FDA mixed-effects model")
})
