# The FDA mixed-effects model for unscaled average bioequivalence (SAS
# RANDOM TRT/TYPE=FA0(2), REPEATED/GRP=TRT, DDFM=SATTERTH).  The anchors are
# known answers (with complete data the model reproduces the intra-subject
# contrasts with n - 2 degrees of freedom), nlme as an independent REML fitter,
# a dense N x N computation with numerical derivatives as an independent check
# of the Satterthwaite degrees of freedom, and finite-difference checks of the
# analytic derivatives.

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
# standard error of each test formulation in `levels`.
expect_fda_matches_nlme <- function(w, tol, levels = "T") {
  d <- .be_fda_design(w)
  m <- .be_fda_mixed(w)
  nf <- fda_nlme(w)
  tt <- summary(nf)$tTable
  expect_gte(m$loglik, fda_loglik(fda_nlme_theta(nf, d), d) - 1e-9)
  for (tl in levels) {
    expect_equal(m$contrasts[[tl]]$pe_log, tt[paste0(".trt", tl), "Value"], tolerance = tol)
    expect_equal(m$contrasts[[tl]]$se, tt[paste0(".trt", tl), "Std.Error"], tolerance = tol)
  }
}

# Dense reference computation on the SAS scale `phi` (the Cholesky factor
# entries of G, then the residual variances of the replicated treatments): the
# full N x N covariance matrix, the REML log-likelihood, and the variance of the
# contrast `cvec`.
fda_dense_cov <- function(phi, d) {
  L <- .be_fda_chol(phi, d)
  G <- L %*% t(L)
  s2 <- rep(0, d$k)
  s2[d$replicated] <- phi[-seq_len(d$n_g)]
  V <- matrix(0, length(d$y), length(d$y))
  for (r in d$rows) {
    ti <- d$trt_idx[r]
    V[r, r] <- G[ti, ti, drop = FALSE] + diag(s2[ti], length(ti))
  }
  V
}
fda_dense_loglik <- function(phi, d) {
  V <- fda_dense_cov(phi, d)
  vi <- solve(V)
  A <- t(d$X) %*% vi %*% d$X
  e <- d$y - d$X %*% solve(A, t(d$X) %*% vi %*% d$y)
  -0.5 * (as.numeric(determinant(V)$modulus) + as.numeric(determinant(A)$modulus) + sum(e * (vi %*% e)))
}
fda_dense_var <- function(phi, d, cvec) {
  vi <- solve(fda_dense_cov(phi, d))
  drop(t(cvec) %*% solve(t(d$X) %*% vi %*% d$X) %*% cvec)
}

# Central-difference gradient and Hessian of fn(x, ...) with step h.
fda_num_grad <- function(fn, x, h, ...) {
  out <- numeric(length(x))
  for (i in seq_along(x)) {
    e <- replace(numeric(length(x)), i, h)
    out[i] <- (fn(x + e, ...) - fn(x - e, ...)) / (2 * h)
  }
  out
}
fda_num_hessian <- function(fn, x, h, ...) {
  n <- length(x)
  out <- matrix(0, n, n)
  for (i in seq_len(n)) {
    for (j in i:n) {
      ei <- replace(numeric(n), i, h)
      ej <- replace(numeric(n), j, h)
      out[i, j] <- out[j, i] <-
        (fn(x + ei + ej, ...) - fn(x + ei - ej, ...) - fn(x - ei + ej, ...) + fn(x - ei - ej, ...)) / (4 * h^2)
    }
  }
  out
}

# Satterthwaite degrees of freedom of test formulation `level` from the dense
# computation with numerical derivatives, at the fit `m` from .be_fda_mixed().
fda_dense_df <- function(w, m, level = "T", h = 1e-5) {
  d <- .be_fda_design(w)
  phi <- c(m$u[seq_len(d$n_g)], exp(m$u[-seq_len(d$n_g)]))
  cvec <- as.numeric(colnames(d$X) == paste0(".trt", level))
  info <- -fda_num_hessian(fda_dense_loglik, phi, h, d = d)
  g <- fda_num_grad(fda_dense_var, phi, h / 10, d = d, cvec = cvec)
  2 * fda_dense_var(phi, d, cvec)^2 / drop(t(g) %*% solve(info, g))
}

# Component `m` of theta_G(x), the lower triangle of L L' for Cholesky entries
# `x` (all components when `m` is NULL).
fda_theta_g <- function(x, d, m = NULL) {
  L <- .be_fda_chol(x, d)
  G <- L %*% t(L)
  out <- G[lower.tri(G, diag = TRUE)]
  if (is.null(m)) out else out[m]
}

# Mocks for the failure paths.
fda_flat_objective <- function(u, d) {
  .Machine$double.xmax
}
fda_zero_information <- function(fit, d, M) {
  matrix(0, length(M), length(M))
}
fda_negative_information <- function(fit, d, M) {
  -diag(length(M))
}
fda_failing_mixed <- function(ds_ep) {
  rlang::abort("mocked failure", class = c("pknca_error_be_fda_model_convergence", "pknca_error_be_fda_model"))
}

# An estimate for the decision functions with the given ratio and interval (%).
fda_est <- function(gmr, lower, upper, se = 0.02, df = 22) {
  list(pe_log = log(gmr / 100), se = se, df = df, n = 24, gmr_percent = gmr, ci_lower = lower, ci_upper = upper)
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

test_that("the FDA mixed model matches nlme and the dense computation with incomplete data and a partial replicate", {
  full <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  partial <- generate_be_replicate(24, 20240501, "partial", cv_wr = 0.45, cv_wt = 0.40)
  full_incomplete <- fda_work(full[-c(which(full$subject == "5")[4], which(full$subject == "8")[2]), ])
  partial_incomplete <- fda_work(partial[-which(partial$subject == "4")[2], ])
  # The full replicate identifies every covariance parameter, so nlme
  # converges to the same fit.
  expect_fda_matches_nlme(full_incomplete, tol = 1e-5)
  # A partial replicate's test residual variance is not identifiable, and nlme
  # stops short of the REML optimum.
  expect_fda_matches_nlme(fda_work(partial), tol = 1e-3)
  expect_fda_matches_nlme(partial_incomplete, tol = 1e-3)
  # With incomplete data the model differs from the intra-subject contrasts,
  # which drop the incomplete subjects.
  m <- .be_fda_mixed(full_incomplete)
  expect_false(isTRUE(all.equal(m$contrasts$T$pe_log, .be_isc(full_incomplete, "R", "T")$pe_log)))
  expect_equal(m$contrasts$T$df, fda_dense_df(full_incomplete, m), tolerance = 1e-4)
  expect_equal(m$contrasts$T$df, 22.4730, tolerance = 1e-4)
  mp <- .be_fda_mixed(partial_incomplete)
  expect_equal(mp$contrasts$T$df, fda_dense_df(partial_incomplete, mp), tolerance = 1e-4)
})

test_that("the analytic gradient, information, and Cholesky derivatives match finite differences", {
  wp <- fda_work(generate_be_replicate(24, 20240501, "partial", cv_wr = 0.45, cv_wt = 0.40))
  dp <- .be_fda_design(wp)
  u <- .be_fda_start(dp, 0.5)
  expect_equal(.be_fda_objective_grad(u, dp), fda_num_grad(.be_fda_objective, u, 1e-6, d = dp), tolerance = 1e-5)

  full <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  partial <- generate_be_replicate(24, 20240501, "partial", cv_wr = 0.45, cv_wt = 0.40)
  cases <- list(
    full = fda_work(full),
    partial_unbalanced = fda_work(partial[!(partial$subject %in% c("1", "5")), ])
  )
  for (nm in names(cases)) {
    d <- .be_fda_design(cases[[nm]])
    m <- .be_fda_mixed(cases[[nm]])
    theta <- m$theta
    fit <- .be_fda_reml(theta, d)
    expect_equal(
      .be_fda_information(fit, d),
      -fda_num_hessian(fda_loglik, theta, 1e-5, d = d),
      tolerance = 1e-4, label = nm
    )
    # The fit is stationary on the optimization (Cholesky) scale, also when
    # the optimum has a singular G and the natural-scale gradient is not zero.
    expect_lt(max(abs(.be_fda_objective_grad(m$u, d))), 1e-3)
  }

  # theta_G(L) = lower triangle of L L'; its Jacobian and Hessians in the
  # Cholesky entries.
  d3 <- list(k = 3, n_g = 6, gi = which(lower.tri(diag(3), diag = TRUE), arr.ind = TRUE))
  lam <- c(0.7, -0.2, 0.4, 0.5, 0.1, 0.3)
  derivs <- .be_fda_chol_derivs(.be_fda_chol(lam, d3), d3)
  num_jac <- matrix(0, 6, 6)
  for (p in 1:6) {
    e <- replace(numeric(6), p, 1e-6)
    num_jac[, p] <- (fda_theta_g(lam + e, d3) - fda_theta_g(lam - e, d3)) / 2e-6
  }
  expect_equal(derivs$jac, num_jac, tolerance = 1e-8)
  for (m in 1:6) {
    expect_equal(derivs$hess[[m]], fda_num_hessian(fda_theta_g, lam, 1e-4, d = d3, m = m), tolerance = 1e-6)
  }
})

test_that("a fit with a singular between-subject covariance uses the Cholesky-scale information", {
  # The REML optimum has a singular G (SAS reports that G is not positive
  # definite).  The degrees of freedom come from the information on the
  # Cholesky (FA0) scale, where the optimum is stationary; the dense
  # computation on that scale agrees.
  w <- fda_work(generate_be_replicate(48, 7, "full", cv_wr = 0.3, cv_wt = 0.5))
  m <- .be_fda_mixed(w)
  G <- matrix(c(m$theta[1], m$theta[2], m$theta[2], m$theta[3]), 2)
  expect_lt(min(eigen(G, symmetric = TRUE)$values), 1e-8)
  expect_fda_matches_nlme(w, tol = 1e-3)
  expect_equal(m$contrasts$T$df, fda_dense_df(w, m), tolerance = 1e-3)
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
  expect_fda_matches_nlme(w, tol = 1e-3, levels = c("T1", "T2"))
  for (tl in c("T1", "T2")) {
    expect_equal(m$contrasts[[tl]]$df, fda_dense_df(w, m, level = tl), tolerance = 1e-3, label = tl)
  }
  # Every subject gets T then R, so treatment is aliased with period.
  fixed_order <- generate_be_replicate(24, 20240501, "2x2")
  fixed_order <- fixed_order[fixed_order$sequence == "TR", ]
  expect_error(.be_fda_mixed(fda_work(fixed_order)), class = "pknca_error_be_fda_model_aliased")
})

test_that("the FDA mixed model stops on degenerate input and failed fits", {
  # Two subjects leave fewer residual degrees of freedom than covariance
  # parameters.
  expect_error(
    .be_fda_mixed(fda_work(generate_be_replicate(2, 5, "full"))),
    class = "pknca_error_be_fda_model_insufficient"
  )
  # Identical test replicates within each subject: the test within-subject
  # variance is zero and the likelihood has no maximum.
  full <- generate_be_replicate(16, 5, "full", cv_wr = 0.1, cv_wt = 0.3)
  is_t <- full$treatment == "T"
  full$PK[is_t] <- exp(stats::ave(log(full$PK[is_t]), full$subject[is_t]))
  expect_error(.be_fda_mixed(fda_work(full)), regexp = "formulation\\(s\\) T is zero", class = "pknca_error_be_fda_model_degenerate")

  w <- fda_work(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  local({
    local_mocked_bindings(.be_fda_objective = fda_flat_objective)
    expect_error(.be_fda_mixed(w), class = "pknca_error_be_fda_model_convergence")
  })
  local({
    local_mocked_bindings(.be_fda_information = fda_zero_information)
    expect_error(.be_fda_mixed(w), class = "pknca_error_be_fda_model_singular")
  })
  local({
    local_mocked_bindings(.be_fda_information = fda_negative_information)
    expect_error(.be_fda_mixed(w), class = "pknca_error_be_fda_model_df")
  })
})

test_that("model_type = 'isc' uses the FDA mixed model for a replicate design and the ANOVA otherwise", {
  full <- generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40)
  incomplete <- full[-c(which(full$subject == "5")[4], which(full$subject == "8")[2]), ]
  ds <- be_dataset(be_replicate_long(incomplete), "treatment", "R", "auclast")
  fit <- be_fit_model_single(ds$data, "isc")
  p <- be_extract_param(fit, ds$data, alpha = 0.10)
  fc <- fit$fda$contrasts$T
  expect_equal(p$model_gmr_percent, 100 * exp(fc$pe_log), tolerance = 1e-10)
  expect_equal(
    c(p$model_ci_lower, p$model_ci_upper),
    100 * exp(fc$pe_log + c(-1, 1) * stats::qt(0.95, fc$df) * fc$se),
    tolerance = 1e-10
  )
  expect_equal(p$model_df, fc$df)
  expect_true(is.na(p$model_error))

  # Without a replicated formulation (parallel or 2x2) the ANOVA ratio is kept.
  par_ds <- be_dataset(generate_be_parallel(), "treatment", "R", "auclast")
  expect_null(be_fit_model_single(par_ds$data, "isc")$fda)
  ds_2x2 <- be_dataset(be_replicate_long(generate_be_replicate(24, 20240501, "2x2")), "treatment", "R", "auclast")
  fit_2x2 <- be_fit_model_single(ds_2x2$data, "isc")
  expect_null(fit_2x2$fda)
  expect_equal(
    be_extract_param(fit_2x2, ds_2x2$data)$model_gmr_percent,
    be_extract_param(be_fit_model_single(ds_2x2$data, "anova"), ds_2x2$data)$model_gmr_percent
  )
})

test_that("an FDA mixed model failure stops only the decisions that need the unscaled criterion", {
  local_mocked_bindings(.be_fda_mixed = fda_failing_mixed)
  # High variability: FDA RSABE decides on the reference-scaled bound alone.
  hi <- be_replicate_long(generate_be_replicate(24, 20240501, "full", cv_wr = 0.45, cv_wt = 0.40))
  ds <- be_dataset(hi, "treatment", "R", "auclast")
  p <- be_extract_param(be_fit_model_single(ds$data, "isc"), ds$data)
  expect_true(is.na(p$model_gmr_percent))
  expect_identical(p$model_error, "mocked failure")
  fda <- suppressWarnings(be_assess(hi, "treatment", "R", "auclast", regulator = "FDA"))
  expect_equal(fda$criterion, -0.0735236679, tolerance = 1e-8)
  expect_true(fda$pass)
  # The NTID interval and the low-variability fallback need the model.
  expect_error(
    suppressWarnings(be_assess(hi, "treatment", "R", "auclast", regulator = "NTID")),
    regexp = "mocked failure",
    class = "pknca_error_be_fda_model_unavailable"
  )
  lo <- be_replicate_long(generate_be_replicate(24, 2024, "full", cv_wr = 0.12, cv_wt = 0.12, gmr = 1.02))
  expect_error(
    suppressWarnings(be_assess(lo, "treatment", "R", "auclast", regulator = "FDA")),
    class = "pknca_error_be_fda_model"
  )
})

test_that("the FDA deciders apply the unscaled criterion to the unscaled estimate", {
  inside <- fda_est(100, 90, 110)
  outside <- fda_est(90, 78, 105)
  fda <- be_regulator("FDA")
  low <- list(swR = 0.2, s2wR = 0.04, df_wR = 22)
  # RSABE below the switch: the unscaled estimate decides and is reported.
  expect_false(.be_rsabe(inside, low, fda, 0.1, unscaled = outside)$pass)
  expect_true(.be_rsabe(outside, low, fda, 0.1, unscaled = inside)$pass)
  expect_identical(.be_rsabe(inside, low, fda, 0.1, unscaled = outside)$report, outside)
  # Above the switch the intra-subject contrasts decide and are reported.
  high <- list(swR = 0.4, s2wR = 0.16, df_wR = 22)
  scaled <- .be_rsabe(inside, high, fda, 0.1, unscaled = outside)
  expect_true(scaled$pass)
  expect_identical(scaled$report, inside)
  # NTID and HVNTID: the conventional interval is the unscaled one.
  ntid_wv <- list(swR = 0.2, s2wR = 0.04, df_wR = 22, swT = 0.2, sw_ratio_ci_upper = 1.5)
  expect_true(.be_ntid(fda_est(100, 70, 140), ntid_wv, be_regulator("NTID"), 0.1, unscaled = inside)$pass)
  expect_false(.be_ntid(inside, ntid_wv, be_regulator("NTID"), 0.1, unscaled = outside)$pass)
  expect_identical(.be_ntid(inside, ntid_wv, be_regulator("NTID"), 0.1, unscaled = outside)$report, outside)
  expect_true(.be_hvntid(outside, ntid_wv, be_regulator("HVNTID"), 0.1, unscaled = inside)$pass)
  expect_false(.be_hvntid(inside, ntid_wv, be_regulator("HVNTID"), 0.1, unscaled = outside)$pass)
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
  expect_match(
    attr(fda, "caption"),
    "the unscaled 80.00-125.00% criterion uses the FDA mixed-effects model",
    fixed = TRUE
  )
})
