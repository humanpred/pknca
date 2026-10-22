# FDA mixed-effects model for unscaled average bioequivalence in replicate
# designs ----------------------------------------------------------------------
#
# The FDA progesterone (2011) and warfarin (2012) guidances decide the unscaled
# 80.00-125.00% criterion with
#
#   PROC MIXED; CLASSES SEQ SUBJ PER TRT;
#     MODEL Y = SEQ PER TRT / DDFM=SATTERTH;
#     RANDOM TRT / TYPE=FA0(2) SUB=SUBJ G;
#     REPEATED / GRP=TRT SUB=SUBJ;
#
# so each subject has correlated random effects for the treatments (an
# unstructured k x k covariance G, parameterized by its Cholesky factor as
# TYPE=FA0 is) and the residual variance differs by treatment.  The REML fit,
# its information matrix, and the Satterthwaite degrees of freedom are computed
# here subject by subject, so the cost grows linearly with the number of
# subjects; subjects with the same treatment pattern share one covariance
# block.
#
# The model is for replicate designs, where some formulation is given twice
# and its within-subject variance keeps every covariance block positive
# definite.  A treatment that no subject receives twice has a residual variance
# that cannot be separated from its between-subject variance (the guidance
# model is over-specified for a partial replicate's test formulation); that
# residual variance is fixed at zero, which leaves the likelihood, the
# estimates, and their variance unchanged.
#
# Every error raised here has the class `pknca_error_be_fda_model`, so callers
# can defer it until a decision needs the model.
#
# Parameter scales: `theta` holds the natural covariance parameters (the lower
# triangle of G by column, then the residual variance of each replicated
# treatment); `u`, the optimization scale, holds the lower triangle of the
# Cholesky factor L of G, then the log residual variances.  The information and
# the Satterthwaite degrees of freedom use the SAS scale (the Cholesky factor,
# then the residual variances), on which a fit with a singular G is still a
# stationary point.

# Design pieces for the FDA mixed model of one endpoint.  `ds_ep` carries
# `.subject`, `.sequence`, `.period`, `.trt` (reference first), and `.logval`.
# A missing `.sequence` is replaced by each subject's treatment pattern, as for
# the intra-subject contrasts.  Covariates are not used.
.be_fda_design <- function(ds_ep) {
  ds_ep <- ds_ep[order(ds_ep$.subject, ds_ep$.period), , drop = FALSE]
  subj <- droplevels(factor(ds_ep$.subject))
  seq_id <- .be_isc_sequence(ds_ep, subj, derived = all(is.na(ds_ep$.sequence)))
  ds_ep$.sequence <- factor(seq_id[as.integer(subj)])
  ds_ep$.trt <- droplevels(ds_ep$.trt)
  fixed <- .be_model_formula(ds_ep[, !startsWith(names(ds_ep), ".cov_"), drop = FALSE], random = FALSE)
  X <- stats::model.matrix(fixed, data = ds_ep)
  qx <- qr(X)
  X <- X[, sort(qx$pivot[seq_len(qx$rank)]), drop = FALSE]
  test_cols <- paste0(".trt", levels(ds_ep$.trt)[-1])
  if (!all(test_cols %in% colnames(X))) {
    rlang::abort(
      "The treatment effect is aliased with the sequence or period effects, so the FDA mixed model cannot estimate it.",
      class = c("pknca_error_be_fda_model_aliased", "pknca_error_be_fda_model")
    )
  }
  trt_idx <- as.integer(ds_ep$.trt)
  k <- nlevels(ds_ep$.trt)
  rows <- split(seq_along(subj), subj)
  pattern <- vapply(rows, .be_fda_pattern, character(1), trt_idx = trt_idx)
  list(
    X = X, y = ds_ep$.logval, rows = rows, pattern = pattern, subj = subj,
    trt_idx = trt_idx, k = k, levels = levels(ds_ep$.trt),
    replicated = vapply(seq_len(k), .be_fda_is_replicated, logical(1), trt_idx = trt_idx, subj = subj),
    gi = which(lower.tri(diag(k), diag = TRUE), arr.ind = TRUE),
    n_g = k * (k + 1) / 2, test_cols = test_cols
  )
}

# Whether any subject receives treatment `t` (an index) more than once.
.be_fda_is_replicated <- function(t, trt_idx, subj) {
  any(tabulate(as.integer(subj)[trt_idx == t], nbins = nlevels(subj)) >= 2)
}

# A subject's treatment pattern: the treatment indices of its rows `i`.
.be_fda_pattern <- function(i, trt_idx) {
  paste(trt_idx[i], collapse = ".")
}

# The Cholesky factor L of G from the optimization scale u.
.be_fda_chol <- function(u, d) {
  L <- matrix(0, d$k, d$k)
  L[lower.tri(L, diag = TRUE)] <- u[seq_len(d$n_g)]
  L
}

# Natural covariance parameters theta from the optimization scale u.
.be_fda_theta <- function(u, d) {
  L <- .be_fda_chol(u, d)
  G <- L %*% t(L)
  c(G[lower.tri(G, diag = TRUE)], exp(u[-seq_len(d$n_g)]))
}

# d V / d theta_j for every natural parameter j, for a subject whose rows have
# treatment indices `ti`.
.be_fda_dv <- function(ti, d) {
  out <- vector("list", d$n_g + sum(d$replicated))
  for (j in seq_len(d$n_g)) {
    a <- d$gi[j, 1]
    b <- d$gi[j, 2]
    out[[j]] <- (outer(ti == a, ti == b) | outer(ti == b, ti == a)) * 1
  }
  j <- d$n_g
  for (t in which(d$replicated)) {
    j <- j + 1
    out[[j]] <- diag(as.numeric(ti == t), length(ti))
  }
  out
}

# Handler that turns a failed Cholesky decomposition into NULL.
.be_fda_null <- function(cnd) {
  NULL
}

# REML fit quantities at natural parameters theta: the log-likelihood (without
# its constant), the fixed effects `beta`, their covariance `C`, and one block
# per treatment pattern with V^-1, the d V / d theta_j, and each member's
# residual e = y - X beta with V^-1 e.  NULL when a covariance block is not
# positive definite.
.be_fda_reml <- function(theta, d) {
  G <- matrix(0, d$k, d$k)
  G[lower.tri(G, diag = TRUE)] <- theta[seq_len(d$n_g)]
  G <- G + t(G) - diag(diag(G), d$k)
  s2 <- rep(0, d$k)
  s2[d$replicated] <- theta[-seq_len(d$n_g)]
  p <- ncol(d$X)
  A <- matrix(0, p, p)
  b <- numeric(p)
  logdet <- 0
  blocks <- list()
  for (pat in unique(d$pattern)) {
    members <- d$rows[d$pattern == pat]
    ti <- d$trt_idx[members[[1]]]
    ch <- tryCatch(chol(G[ti, ti, drop = FALSE] + diag(s2[ti], length(ti))), error = .be_fda_null)
    if (is.null(ch)) {
      return(NULL)
    }
    vi <- chol2inv(ch)
    logdet <- logdet + length(members) * 2 * sum(log(diag(ch)))
    for (i in members) {
      xi <- d$X[i, , drop = FALSE]
      A <- A + crossprod(xi, vi %*% xi)
      b <- b + drop(crossprod(xi, vi %*% d$y[i]))
    }
    blocks[[pat]] <- list(members = members, vi = vi, dv = .be_fda_dv(ti, d))
  }
  ch_a <- tryCatch(chol(A), error = .be_fda_null)
  if (is.null(ch_a)) {
    return(NULL)
  }
  C <- chol2inv(ch_a)
  beta <- drop(C %*% b)
  q <- 0
  for (pat in names(blocks)) {
    blocks[[pat]]$res <- lapply(blocks[[pat]]$members, .be_fda_resid, d = d, beta = beta, vi = blocks[[pat]]$vi)
    for (rs in blocks[[pat]]$res) {
      q <- q + sum(rs$e * rs$r)
    }
  }
  list(loglik = -0.5 * (logdet + 2 * sum(log(diag(ch_a))) + q), beta = beta, C = C, blocks = blocks)
}

# A subject's residual e = y - X beta and V^-1 e, for its rows `i`.
.be_fda_resid <- function(i, d, beta, vi) {
  e <- d$y[i] - drop(d$X[i, , drop = FALSE] %*% beta)
  list(i = i, e = e, r = drop(vi %*% e))
}

# M_j = X' V^-1 V_j V^-1 X for each natural parameter j.
.be_fda_m <- function(fit, d) {
  n_par <- length(fit$blocks[[1]]$dv)
  M <- rep(list(matrix(0, ncol(d$X), ncol(d$X))), n_par)
  for (blk in fit$blocks) {
    for (j in seq_len(n_par)) {
      inner <- blk$vi %*% blk$dv[[j]] %*% blk$vi
      for (i in blk$members) {
        xi <- d$X[i, , drop = FALSE]
        M[[j]] <- M[[j]] + crossprod(xi, inner %*% xi)
      }
    }
  }
  M
}

# Gradient of the REML log-likelihood with respect to the natural parameters,
# -tr(P V_j) / 2 + (Py)' V_j (Py) / 2, where P = V^-1 - V^-1 X C X' V^-1, so
# tr(P V_j) = tr(V^-1 V_j) - tr(C M_j), and P y = V^-1 (y - X beta).
.be_fda_gradient <- function(fit, d, M = .be_fda_m(fit, d)) {
  n_par <- length(M)
  out <- numeric(n_par)
  for (j in seq_len(n_par)) {
    tr_v <- 0
    quad <- 0
    for (blk in fit$blocks) {
      tr_v <- tr_v + length(blk$members) * sum(blk$vi * blk$dv[[j]])
      for (rs in blk$res) {
        quad <- quad + sum(rs$r * (blk$dv[[j]] %*% rs$r))
      }
    }
    out[j] <- -0.5 * (tr_v - sum(fit$C * M[[j]])) + 0.5 * quad
  }
  out
}

# Observed information of the natural parameters, minus the Hessian of the REML
# log-likelihood.  V is linear in theta, so d P / d theta_j = -P V_j P and
#   I_ab = -tr(P V_a P V_b) / 2 + (Py)' V_a P V_b (Py),
# with
#   tr(P V_a P V_b) = tr(V^-1 V_a V^-1 V_b) - 2 tr(C N_ab) + tr(C M_a C M_b),
#   N_ab = X' V^-1 V_a V^-1 V_b V^-1 X,
#   (Py)' V_a P V_b (Py) = (Py)' V_a V^-1 V_b (Py) - w_a' C w_b,
#   w_a = X' V^-1 V_a (Py),
# each summed by subject.
.be_fda_information <- function(fit, d, M = .be_fda_m(fit, d)) {
  n_par <- length(M)
  p <- ncol(d$X)
  w <- rep(list(numeric(p)), n_par)
  for (blk in fit$blocks) {
    for (rs in blk$res) {
      xi <- d$X[rs$i, , drop = FALSE]
      for (a in seq_len(n_par)) {
        w[[a]] <- w[[a]] + drop(crossprod(xi, blk$vi %*% blk$dv[[a]] %*% rs$r))
      }
    }
  }
  info <- matrix(0, n_par, n_par)
  for (a in seq_len(n_par)) {
    for (b in a:n_par) {
      tr_vv <- 0
      n_ab <- matrix(0, p, p)
      quad <- 0
      for (blk in fit$blocks) {
        va_vi_vb <- blk$dv[[a]] %*% blk$vi %*% blk$dv[[b]]
        tr_vv <- tr_vv + length(blk$members) * sum(diag(blk$vi %*% va_vi_vb))
        inner <- blk$vi %*% va_vi_vb %*% blk$vi
        for (rs in blk$res) {
          xi <- d$X[rs$i, , drop = FALSE]
          n_ab <- n_ab + crossprod(xi, inner %*% xi)
          quad <- quad + sum(rs$r * (va_vi_vb %*% rs$r))
        }
      }
      tr_pp <- tr_vv - 2 * sum(fit$C * n_ab) + sum(diag(fit$C %*% M[[a]] %*% fit$C %*% M[[b]]))
      info[a, b] <- info[b, a] <- -0.5 * tr_pp + quad - drop(crossprod(w[[a]], fit$C %*% w[[b]]))
    }
  }
  info
}

# Jacobian of the natural G parameters with respect to the Cholesky factor
# entries (both in lower-triangle column order), and for each G parameter its
# Hessian with respect to those entries.  theta_ab = sum_c L_ac L_bc, so
# d theta_ab / d L_rs = [a = r] L_bs + [b = r] L_as and
# d2 theta_ab / d L_rs d L_tv = [s = v] ([a = r][b = t] + [b = r][a = t]).
.be_fda_chol_derivs <- function(L, d) {
  gi <- d$gi
  jac <- matrix(0, d$n_g, d$n_g)
  hess <- rep(list(matrix(0, d$n_g, d$n_g)), d$n_g)
  for (m in seq_len(d$n_g)) {
    a <- gi[m, 1]
    b <- gi[m, 2]
    for (p1 in seq_len(d$n_g)) {
      r <- gi[p1, 1]
      s <- gi[p1, 2]
      jac[m, p1] <- (a == r) * L[b, s] + (b == r) * L[a, s]
      for (p2 in seq_len(d$n_g)) {
        t <- gi[p2, 1]
        v <- gi[p2, 2]
        hess[[m]][p1, p2] <- (s == v) * ((a == r) * (b == t) + (b == r) * (a == t))
      }
    }
  }
  list(jac = jac, hess = hess)
}

# Negative REML log-likelihood on the optimization scale (for stats::optim).
.be_fda_objective <- function(u, d) {
  fit <- .be_fda_reml(.be_fda_theta(u, d), d)
  if (is.null(fit)) .Machine$double.xmax else -fit$loglik
}

# Gradient of .be_fda_objective(): the natural-parameter gradient through the
# Cholesky factor for G and through exp() for the residual variances.
.be_fda_objective_grad <- function(u, d) {
  theta <- .be_fda_theta(u, d)
  fit <- .be_fda_reml(theta, d)
  if (is.null(fit)) {
    return(rep(0, length(u)))
  }
  g <- .be_fda_gradient(fit, d)
  jac <- .be_fda_chol_derivs(.be_fda_chol(u, d), d)$jac
  idx_g <- seq_len(d$n_g)
  -c(drop(crossprod(jac, g[idx_g])), g[-idx_g] * theta[-idx_g])
}

# Starting values on the optimization scale: the within-subject variance from a
# fixed-effects fit with subject, the between-subject variance from the subject
# means of the fixed-effects residuals, and between-subject correlation `rho`.
# An unreplicated treatment's within-subject variance goes into G.
.be_fda_start <- function(d, rho) {
  n <- length(d$y)
  subj_x <- stats::model.matrix(~ 0 + d$subj)
  fit_w <- stats::lm.fit(cbind(d$X, subj_x), d$y)
  df_w <- n - fit_w$rank
  s2w <- if (df_w > 0) sum(fit_w$residuals^2) / df_w else stats::var(d$y)
  e0 <- stats::lm.fit(d$X, d$y)$residuals
  s2b <- max(stats::var(tapply(e0, d$subj, mean)) - s2w / 2, s2w / 10)
  G <- s2b * (rho + (1 - rho) * diag(d$k))
  diag(G)[!d$replicated] <- diag(G)[!d$replicated] + s2w
  L <- t(chol(G))
  c(L[lower.tri(L, diag = TRUE)], rep(log(s2w), sum(d$replicated)))
}

# Fit the FDA mixed model to one endpoint and return, for each test
# formulation, the log test/reference estimate, its standard error, and the
# Satterthwaite degrees of freedom, plus the REML log-likelihood (without its
# constant), the natural covariance parameters `theta`, and the optimization
# scale parameters `u`.
.be_fda_mixed <- function(ds_ep) {
  d <- .be_fda_design(ds_ep)
  n_par <- d$n_g + sum(d$replicated)
  if (length(d$y) - ncol(d$X) <= n_par) {
    rlang::abort(
      sprintf(
        "The FDA mixed model has %d covariance parameters but only %d residual degrees of freedom.",
        n_par, length(d$y) - ncol(d$X)
      ),
      class = c("pknca_error_be_fda_model_insufficient", "pknca_error_be_fda_model")
    )
  }
  best <- .be_fda_optimize(d)
  theta <- .be_fda_theta(best$par, d)
  .be_fda_check_variances(theta, d)
  if (max(abs(.be_fda_objective_grad(best$par, d))) > 1e-3 * max(1, abs(best$value))) {
    .be_fda_abort_convergence()
  }
  fit <- .be_fda_reml(theta, d)
  M <- .be_fda_m(fit, d)
  info_theta <- .be_fda_information(fit, d, M)
  grad_theta <- .be_fda_gradient(fit, d, M)
  # Information on the SAS scale: J' I J minus the gradient-weighted Hessian of
  # the G parameters in the Cholesky entries (zero at an interior optimum).
  derivs <- .be_fda_chol_derivs(.be_fda_chol(best$par, d), d)
  n_par <- length(theta)
  idx_g <- seq_len(d$n_g)
  jac <- diag(n_par)
  jac[idx_g, idx_g] <- derivs$jac
  info <- crossprod(jac, info_theta %*% jac)
  for (m in idx_g) {
    info[idx_g, idx_g] <- info[idx_g, idx_g] - grad_theta[m] * derivs$hess[[m]]
  }
  cov_par <- tryCatch(solve(info), error = .be_fda_null)
  if (is.null(cov_par)) {
    rlang::abort(
      "The information matrix of the FDA mixed model is singular, so its Satterthwaite degrees of freedom are not available.",
      class = c("pknca_error_be_fda_model_singular", "pknca_error_be_fda_model")
    )
  }
  contrasts <- list()
  for (j in seq_along(d$test_cols)) {
    cvec <- as.numeric(colnames(d$X) == d$test_cols[j])
    cc <- drop(fit$C %*% cvec)
    f <- sum(cvec * cc)
    # d f / d theta_j = c' C M_j C c, carried to the SAS scale.
    g <- crossprod(jac, vapply(M, .be_fda_quad, numeric(1), x = cc))
    df <- 2 * f^2 / drop(crossprod(g, cov_par %*% g))
    if (!is.finite(df) || df <= 0) {
      rlang::abort(
        sprintf("The Satterthwaite degrees of freedom of the FDA mixed model are not positive (%g).", df),
        class = c("pknca_error_be_fda_model_df", "pknca_error_be_fda_model")
      )
    }
    contrasts[[d$levels[j + 1]]] <- list(pe_log = sum(cvec * fit$beta), se = sqrt(f), df = df)
  }
  list(contrasts = contrasts, loglik = fit$loglik, theta = theta, u = best$par)
}

# Maximize the REML log-likelihood from two starting points (high and zero
# between-subject correlation) and return the better optim() result.  Stops
# unless a fit converged to a finite likelihood.
.be_fda_optimize <- function(d) {
  best <- NULL
  for (rho in c(0.9, 0)) {
    opt <- stats::optim(
      .be_fda_start(d, rho), .be_fda_objective, .be_fda_objective_grad, d = d,
      method = "BFGS", control = list(maxit = 2000, reltol = 1e-14)
    )
    if (opt$convergence == 0 && opt$value < .Machine$double.xmax && (is.null(best) || opt$value < best$value)) {
      best <- opt
    }
  }
  if (is.null(best)) {
    .be_fda_abort_convergence()
  }
  best
}

.be_fda_abort_convergence <- function() {
  rlang::abort(
    "The REML fit of the FDA mixed model did not converge.",
    class = c("pknca_error_be_fda_model_convergence", "pknca_error_be_fda_model")
  )
}

# Stop when a replicated formulation's within-subject variance is zero (its
# replicate administrations agree exactly once the fixed effects are removed),
# where the REML likelihood has no maximum.
.be_fda_check_variances <- function(theta, d) {
  idx_g <- seq_len(d$n_g)
  diag_g <- theta[idx_g][d$gi[, 1] == d$gi[, 2]]
  s2 <- theta[-idx_g]
  zero <- s2 < 1e-8 * (diag_g[d$replicated] + s2)
  if (any(zero)) {
    rlang::abort(
      sprintf(
        "The within-subject variance of formulation(s) %s is zero, so the FDA mixed model is degenerate.",
        paste(d$levels[d$replicated][zero], collapse = ", ")
      ),
      class = c("pknca_error_be_fda_model_degenerate", "pknca_error_be_fda_model")
    )
  }
  invisible(theta)
}

# The quadratic form x' M x.
.be_fda_quad <- function(M, x) {
  sum(x * (M %*% x))
}
