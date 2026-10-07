#' Generate a sparse_pk object
#'
#' @inheritParams assert_conc_time
#' @param subject Subject identifiers (may be any class; may not be null).  A
#'   missing subject marks an imputed concentration (such as the zero that the
#'   `start_conc0` imputation adds at the start of an interval):  a time where
#'   every subject is missing has a known concentration, which enters sparse
#'   estimates but not their variance.
#' @returns A sparse_pk object which is a list of lists.  The inner lists have
#'   elements named: "time", The time of measurement; "conc", The concentration
#'   measured; "subject", The subject identifiers; "imputed", Whether the
#'   concentration at that time is imputed (known).  The object will usually be
#'   modified by future functions to add more named elements to the inner list.
#' @family Sparse Methods
#' @export
as_sparse_pk <- function(conc, time, subject) {
  if (is.data.frame(conc) && missing(time) && missing(subject)) {
    time <- conc$time
    subject <- conc$subject
    conc <- conc$conc
  }
  assert_conc_time(conc = conc, time = time, any_missing_conc = TRUE, sorted_time = FALSE)
  checkmate::assert_vector(subject, len=length(conc), null.ok=FALSE)
  # Drop observations with missing concentrations so that per-timepoint means,
  # variances, and subject counts reflect only available data.
  mask_ok <- !is.na(conc)
  conc <- conc[mask_ok]
  time <- time[mask_ok]
  subject <- subject[mask_ok]

  unique_times <- sort(unique(time))
  ret <- list()
  for (current_time in unique_times) {
    current_mask <- time %in% current_time
    imputed <- all(is.na(subject[current_mask]))
    if (!imputed && anyNA(subject[current_mask])) {
      rlang::abort(
        sprintf(
          "At time %g, some subjects are missing:  a time must have either all measured (non-missing subjects) or all imputed (missing subjects) concentrations",
          current_time
        ),
        class = "pknca_error_sparse_pk_mixed_imputed"
      )
    }
    ret <-
      append(
        ret,
        list(list(
          time=current_time,
          conc=conc[current_mask],
          subject=subject[current_mask],
          imputed=imputed
        ))
      )
  }
  class(ret) <- "sparse_pk"
  ret
}

#' Set or get a sparse_pk object attribute
#'
#' @param sparse_pk A sparse_pk object from [as_sparse_pk()]
#' @param ... Either a character string (to get that value) or a named vector
#'   the same length as `sparse_pk` to set the value.
#' @returns Either the attribute value or an updated `sparse_pk` object
#' @keywords Internal
sparse_pk_attribute <- function(sparse_pk, ...) {
  args <- list(...)
  checkmate::assert_list(args, len = 1)
  if (is.null(names(args))) {
    vapply(X=sparse_pk, FUN="[[", args[[1]], FUN.VALUE = 1)
  } else {
    if (length(args[[1]]) != length(sparse_pk)) {
      rlang::abort(
        "The length of the argument must match the length of sparse_pk",
        class = "pknca_error_sparse_pk_attribute_length"
      )
    }
    for (idx in seq_along(sparse_pk)) {
      sparse_pk[[idx]][names(args)[1]] <- args[[1]][idx]
    }
    sparse_pk
  }
}

#' Calculate the weight for sparse AUC calculation with the linear-trapezoidal
#' rule
#'
#' The weight is used as the \eqn{w_i}{w_i} parameter in [pk.calc.sparse_auc()]
#'
#' \deqn{w_i = \frac{\delta_{time,i-1,i} + \delta_{time,i,i+1}}{2}}{w_i = (d_time[i-1,i] + d_time[i,i+1])/2}
#' \deqn{\delta_{time,i,i+1} = t_{i+1} - t_i}{d_time = t_[i+1] - t_i, and zero if i < 1 or i > K}
#'
#' Where:
#'
#' \describe{
#'   \item{\eqn{w_i}{w_i}}{is the weight at time i}
#'   \item{\eqn{\delta_{time,i-1,i}}{d_time[i-1,i]} and \eqn{\delta_{time,i,i+1}}{d_time[i,i+1]}}{are the changes between time i-1 and i or i and i+1 (zero outside of the time range)}
#'   \item{\eqn{t_i}{t_i}}{is the time at time i}
#' }
#'
#' @inheritParams sparse_pk_attribute
#' @returns A numeric vector of weights for sparse AUC calculations the same
#'   length as `sparse_pk`
#' @family Sparse Methods
#' @export
sparse_auc_weight_linear <- function(sparse_pk) {
  times <- vapply(X=sparse_pk, FUN="[[", "time", FUN.VALUE = 1)
  half_diff_times <- diff(times)/2
  weights <- c(0, half_diff_times) + c(half_diff_times, 0)
  sparse_pk_attribute(sparse_pk=sparse_pk, weight=weights)
}

#' Calculate the mean concentration at all time points for use in sparse NCA
#' calculations
#'
#' Choices for the method of calculation (the argument `sparse_mean_method`)
#' are:
#'
#' \describe{
#'   \item{"arithmetic mean"}{Arithmetic mean (ignoring number of BLQ samples)}
#'   \item{"arithmetic mean, <=50% BLQ"}{If >50% of the measurements are BLQ, zero.  Otherwise, the arithmetic mean of all samples (including the BLQ as zero).}
#' }
#'
#' @inheritParams sparse_pk_attribute
#' @param sparse_mean_method The method used to calculate the sparse mean (see
#'   details)
#' @returns A vector the same length as `sparse_pk` with the mean concentration
#'   at each of those times.
#' @family Sparse Methods
#' @export
sparse_mean <- function(sparse_pk, sparse_mean_method=c("arithmetic mean, <=50% BLQ", "arithmetic mean")) {
  sparse_mean_method <- match.arg(sparse_mean_method)
  ret <-
    vapply(
      X = sparse_pk,
      FUN = function(current_time) mean(current_time$conc),
      FUN.VALUE = 1
    )
  if (sparse_mean_method == "arithmetic mean, <=50% BLQ") {
    numerator <-
      vapply(
        X=sparse_pk,
        FUN=function(current_time) sum(current_time$conc == 0),
        FUN.VALUE = 1
      )
    denominator <-
      vapply(
        X = sparse_pk,
        FUN = function(current_time) length(current_time$conc),
        FUN.VALUE = 1
      )
    frac_blq <- numerator/denominator
    ret[frac_blq > 0.5] <- 0
  } else if (sparse_mean_method == "arithmetic mean") {
    # do nothing
  } else {
    rlang::abort(
      sprintf(
        "Invalid sparse_mean_method: %s",
        sparse_mean_method
      ),
      class = "pknca_error_invalid_sparse_mean_method"
    )
  }
  sparse_pk <- sparse_pk_attribute(sparse_pk, mean=ret)
  sparse_pk <- sparse_pk_attribute(sparse_pk, mean_method=rep(sparse_mean_method, length(ret)))
  sparse_pk
}

# The trapezoidal weights of the mean profile for an AUC or AUMC:  AUClast
# integrates to tlast, the last time with a positive mean, and AUCall adds the
# triangle from tlast to the next time.  That next time's mean is zero by the
# definition of tlast, so it carries no weight either; neither do later times.
# Times without weight do not enter the variance or its degrees of freedom.
sparse_auc_weight_type <- function(sparse_pk, auc.type) {
  if (!(auc.type %in% c("AUClast", "AUCall"))) {
    rlang::abort(
      sprintf(
        "The sparse AUC and AUMC are calculated with auc.type 'AUClast' or 'AUCall', not '%s'",
        auc.type
      ),
      class = "pknca_error_sparse_auc_type"
    )
  }
  times <- sparse_pk_attribute(sparse_pk, "time")
  means <- sparse_pk_attribute(sparse_pk, "mean")
  idx_last <- max(c(0L, which(means > 0)))
  idx_end <- if (auc.type == "AUCall") min(idx_last + 1L, length(times)) else idx_last
  weights <- rep(0, length(times))
  if (idx_end > 1) {
    half_diff_times <- diff(times[seq_len(idx_end)])/2
    weights[seq_len(idx_end)] <- c(0, half_diff_times) + c(half_diff_times, 0)
  }
  weights[seq_along(weights) > idx_last] <- 0
  sparse_pk_attribute(sparse_pk = sparse_pk, weight = weights)
}

# The times of a sparse_pk object that enter the variance of an estimate:  those
# with a nonzero weight and measured concentrations (an imputed concentration is
# known, so it has no variance)
sparse_pk_weighted <- function(sparse_pk) {
  imputed <- vapply(X = sparse_pk, FUN = function(current_time) isTRUE(current_time$imputed), FUN.VALUE = TRUE)
  ret <- sparse_pk[sparse_pk_attribute(sparse_pk, "weight") != 0 & !imputed]
  class(ret) <- class(sparse_pk)
  ret
}

#' Sparse AUC or AUMC with its standard error, to tlast or to infinity
#'
#' The estimate is the AUClast (or AUMClast) of the mean profile, plus with
#' `extrapolate = TRUE` its extrapolation from tlast with `lambda.z`:
#' \eqn{C_{last}/\lambda_z} for the AUC (Yuan 1993) and \eqn{t_{last}
#' C_{last}/\lambda_z + C_{last}/\lambda_z^2} for the AUMC, where
#' \eqn{C_{last}} is the mean concentration at tlast.  Both are linear in the
#' means at each time (the moment means \eqn{t_i \bar{y}_i} for the AUMC), so
#' the variance is that of [var_sparse_auc()] (or [var_sparse_aumc()]) with the
#' trapezoidal weights plus the extrapolation weight at tlast.
#'
#' With `lambda_z_se = "none"` (Yuan 1993), `lambda.z` is treated as known.  With
#' `"delta"`, its uncertainty is added with the delta method:  `lambda.z` is minus
#' the least-squares slope of the log mean concentrations on time over the
#' half-life points, \eqn{\lambda_z = -\sum_j c_j \log \bar{y}_j} with
#' \eqn{c_j = (t_j - \bar{t})/\sum_k (t_k - \bar{t})^2}, so the estimate is a
#' smooth function of the means, and its gradient takes the place of the weights.
#' For the AUC, the weight of the mean at time \eqn{j} is
#' \deqn{w_j + \frac{\delta_{j,last}}{\lambda_z} + \frac{C_{last}}{\lambda_z^2} \frac{c_j}{\bar{y}_j}.}
#' The gradient covers the covariance of `lambda.z` with \eqn{C_{last}} and the
#' AUClast, which come from the same samples.  The half-life points are taken as
#' fixed:  the uncertainty of choosing them is not included.
#'
#' The area starts at time 0.  Without a concentration at time 0 (measured or
#' imputed), the result is `NA`, except for an IV bolus (`iv_bolus = TRUE`):
#' then \eqn{C_0} is estimated from the mean profile as [pk.calc.c0()] does
#' (see `sparse_c0()`), and the AUC from time 0 to the first sample is added.
#' \eqn{C_0} is a smooth function of the means, so its gradient adds to the
#' weights of the means it comes from.  The AUMC from time 0 to the first sample
#' is \eqn{t_1^2 \bar{y}_1/2} with the linear trapezoidal rule whatever
#' \eqn{C_0} is, so \eqn{C_0} does not change the AUMC.
#'
#' @param moment Calculate the AUMC (`TRUE`) or the AUC (`FALSE`)?
#' @param extrapolate Extrapolate to infinity (`TRUE`) or stop at tlast
#'   (`FALSE`)?
#' @param auc.type Without extrapolation, `"AUClast"` or `"AUCall"` (see
#'   [pk.calc.sparse_auc()])
#' @param iv_bolus Back-extrapolate to \eqn{C_0} when there is no concentration
#'   at time 0?
#' @param lambda_z_se How the standard error accounts for `lambda.z` (see
#'   Details and the `sparse_lambda_z_se` option of [PKNCA.options()])
#' @inheritParams pk.calc.sparse_auc
#' @inheritParams pk.calc.half.life
#' @param lambda.z The elimination rate of the mean profile
#' @param lambda.z.time.first,lambda.z.time.last,lambda.z.n.points The first
#'   and last time and the number of points of the half-life fit to the mean
#'   profile (used with `lambda_z_se = "delta"`)
#' @returns A list with the `estimate`, its standard error (`se`), the
#'   degrees of freedom (`df`), and the method used for \eqn{C_0}
#'   (`c0_method`, `NA` when \eqn{C_0} was not back-extrapolated)
#' @references
#' Yuan J. Estimation of variance for AUC in animal studies.  Journal of
#' Pharmaceutical Sciences.  1993;82(7):761-763. doi:10.1002/jps.2600820718
#' @keywords Internal
#' @noRd
sparse_auxc_obs <- function(conc, time, subject, lambda.z = NA,
                            lambda.z.time.first = NA, lambda.z.time.last = NA,
                            lambda.z.n.points = NA,
                            moment = FALSE, extrapolate = TRUE, auc.type = "AUClast",
                            iv_bolus = FALSE, lambda_z_se = "delta",
                            hl_method = "log-linear") {
  na_ret <- list(estimate = NA_real_, se = NA_real_, df = NA_real_, c0_method = NA_character_)
  sparse_pk <- as_sparse_pk(conc = conc, time = time, subject = subject)
  sparse_pk <- sparse_mean(sparse_pk = sparse_pk, sparse_mean_method = "arithmetic mean, <=50% BLQ")
  # The area starts at time 0 (the start of the interval in pk.nca()), as for
  # the sparse AUClast
  time_first <- min(sparse_pk_attribute(sparse_pk, "time"))
  c0 <- list(c0 = NA_real_, gradient = numeric(), method = NA_character_)
  if (time_first > 0 && iv_bolus) {
    c0 <- sparse_c0(sparse_pk)
    if (is.na(c0$c0)) {
      return(na_ret)
    }
    # C0 enters the mean profile as a known (imputed) concentration; its
    # uncertainty is in its gradient below
    sparse_pk <-
      sparse_mean(
        as_sparse_pk(conc = c(c0$c0, conc), time = c(0, time), subject = c(NA, subject)),
        sparse_mean_method = "arithmetic mean, <=50% BLQ"
      )
  } else if (time_first > 0) {
    rlang::warn(
      sprintf("Requesting an AUC range starting (0) before the first measurement (%g) is not allowed", time_first),
      class = "pknca_warning_auc_before_first"
    )
    return(na_ret)
  }
  # The extrapolation to infinity starts from tlast
  sparse_pk <- sparse_auc_weight_type(sparse_pk, auc.type = if (extrapolate) "AUClast" else auc.type)
  times <- sparse_pk_attribute(sparse_pk, "time")
  means <- sparse_pk_attribute(sparse_pk, "mean")
  weights <- sparse_pk_attribute(sparse_pk, "weight")
  idx_last <- max(c(0L, which(means > 0)))
  if (extrapolate && (idx_last == 0 || is.na(lambda.z) || lambda.z <= 0)) {
    return(na_ret)
  }
  if (moment) {
    # Moment means and the AUMClast of the mean profile (linear trapezoidal)
    values <- times * means
  } else {
    values <- means
  }
  estimate <- sum(weights*values)
  if (!is.na(c0$c0) && !moment) {
    # The weight of C0 (the first trapezoid) passes to the means it comes from;
    # time 0 is first, and the gradient is over the measured times after it
    weights[-1] <- weights[-1] + weights[1]*c0$gradient
  }
  if (extrapolate) {
    tlast <- times[idx_last]
    extrapolation_weight <-
      if (moment) {
        1/lambda.z + 1/(tlast*lambda.z^2)
      } else {
        1/lambda.z
      }
    estimate <- estimate + values[idx_last]*extrapolation_weight
    weights[idx_last] <- weights[idx_last] + extrapolation_weight
  }
  if (extrapolate && lambda_z_se == "delta") {
    if (hl_method != "log-linear") {
      rlang::warn(
        "The delta-method standard error for lambda.z needs the log-linear half-life (the hl_method option), so it is not calculated",
        class = "pknca_warning_sparse_lambda_z_se_hl_method"
      )
      return(list(estimate = estimate, se = NA_real_, df = NA_real_, c0_method = c0$method))
    }
    # The half-life points of the mean profile (the half-life is fit to the
    # positive means from lambda.z.time.first through lambda.z.time.last)
    tolerance <- sqrt(.Machine$double.eps)*max(1, abs(times))
    idx_hl <-
      which(
        times >= lambda.z.time.first - tolerance &
          times <= lambda.z.time.last + tolerance &
          means > 0
      )
    if (length(idx_hl) != lambda.z.n.points) {
      rlang::warn(
        sprintf(
          "The %d half-life points of the mean profile could not be identified (%d positive means are between %g and %g), so the delta-method standard error is not calculated",
          lambda.z.n.points, length(idx_hl), lambda.z.time.first, lambda.z.time.last
        ),
        class = "pknca_warning_sparse_lambda_z_points"
      )
      return(list(estimate = estimate, se = NA_real_, df = NA_real_, c0_method = c0$method))
    }
    time_hl <- times[idx_hl]
    slope_weights <- (time_hl - mean(time_hl))/sum((time_hl - mean(time_hl))^2)
    # d(estimate)/d(lambda.z) times d(lambda.z)/d(value_j) = -c_j/value_j; the
    # log of a moment mean differs from the log of the mean by the constant
    # log(t_j), so the same holds for moment means
    d_estimate_d_lambda_z <-
      if (moment) {
        -values[idx_last]*(1/lambda.z^2 + 2/(tlast*lambda.z^3))
      } else {
        -values[idx_last]/lambda.z^2
      }
    weights[idx_hl] <-
      weights[idx_hl] + d_estimate_d_lambda_z*(-slope_weights/values[idx_hl])
  }
  sparse_pk <- sparse_pk_attribute(sparse_pk, weight = weights)
  variance <-
    if (moment) {
      var_sparse_aumc(sparse_pk)
    } else {
      var_sparse_auc(sparse_pk)
    }
  list(
    estimate = estimate,
    se = sqrt(as.numeric(variance)),
    df = attr(variance, "df"),
    c0_method = c0$method
  )
}

#' The concentration at time 0 of a sparse mean profile after an IV bolus
#'
#' The methods of [pk.calc.c0()] are tried in its default order on the mean
#' profile (`"c0"` does not apply, since there is no concentration at time 0):
#' `"logslope"`, `"c1"`, `"cmin"`, then `"set0"`.  The first that gives a value
#' is used, with its gradient with respect to the means.  With `"logslope"`,
#' \eqn{C_0 = \bar{y}_1 (\bar{y}_1/\bar{y}_2)^{t_1/(t_2 - t_1)}}, so
#' \eqn{\partial C_0/\partial \bar{y}_1 = C_0 t_2/((t_2 - t_1)\bar{y}_1)} and
#' \eqn{\partial C_0/\partial \bar{y}_2 = -C_0 t_1/((t_2 - t_1)\bar{y}_2)}.
#'
#' @param sparse_pk A sparse_pk object with means (from [sparse_mean()]) and no
#'   time 0
#' @returns A list with `c0`, its `gradient` with respect to the means of
#'   `sparse_pk`, and the `method` used
#' @keywords Internal
#' @noRd
sparse_c0 <- function(sparse_pk) {
  times <- sparse_pk_attribute(sparse_pk, "time")
  means <- sparse_pk_attribute(sparse_pk, "mean")
  gradient <- rep(0, length(means))
  for (method in c("logslope", "c1", "cmin", "set0")) {
    c0 <- pk.calc.c0(conc = means, time = times, time.dose = 0, method = method, check = FALSE)
    if (!is.na(c0)) {
      break
    }
  }
  if (method == "logslope") {
    gradient[1] <- c0*times[2]/((times[2] - times[1])*means[1])
    gradient[2] <- -c0*times[1]/((times[2] - times[1])*means[2])
  } else if (method == "c1") {
    gradient[1] <- 1
  } else if (method == "cmin" && c0 > 0) {
    # A mean of zero is set by the BLQ rule, not estimated, so it has no gradient
    gradient[which.min(means)] <- 1
  }
  list(c0 = c0, gradient = gradient, method = method)
}

#' Calculate the variance for the AUC of sparsely sampled PK
#'
#' Equation 7.vii in Nedelman and Jia, 1998 is used for this calculation:
#'
#' \deqn{var\left(\hat{AUC}\right) = \sum\limits_{i=0}^m\left(\frac{w_i^2 s_i^2}{r_i}\right) + 2\sum\limits_{i<j}\left(\frac{w_i w_j r_{ij} s_{ij}}{r_i r_j}\right)}{var(AUC) = sum_(i=0)^(m) ((w_i^2 * s_i^2)/(r_i) + + 2*sum_(i<j)((w_i * w_j * r_ij * s_ij)/(r_i * r_j))}
#'
#' The degrees of freedom are the Satterthwaite approximation of equation 6 of
#' the same paper for any sampling design, including subjects with more than
#' one sample (see the `"df"` attribute of the return value and Details of
#' [cov_holder()] for the covariance).
#'
#' @inheritParams sparse_pk_attribute
#' @returns The variance of the AUC estimate with a `"df"` attribute containing
#'   its degrees of freedom.
#' @references
#' Nedelman JR, Jia X. An extension of Satterthwaite’s approximation applied to
#' pharmacokinetics. Journal of Biopharmaceutical Statistics. 1998;8(2):317-328.
#' doi:10.1080/10543409808835241
#'
#' Holder DJ. Comments on Nedelman and Jia’s Extension of Satterthwaite’s
#' Approximation Applied to Pharmacokinetics. Journal of Biopharmaceutical
#' Statistics. 2001;11(1-2):75-79. doi:10.1081/BIP-100104199
#' @export
var_sparse_auc <- function(sparse_pk) {
  # Times with no weight in the AUC or an imputed (known) concentration do not
  # contribute to its variance
  sparse_pk <- sparse_pk_weighted(sparse_pk)
  if (length(sparse_pk) == 0) {
    return(structure(0, df = NA_real_))
  }
  covariance <- cov_holder(sparse_pk)
  var_auc <- 0
  weights <- sparse_pk_attribute(sparse_pk, "weight")
  for (idx1 in seq_along(sparse_pk)) {
    n_idx1 <- length(unique(sparse_pk[[idx1]]$subject))
    var_auc <-
      var_auc +
      weights[idx1]^2*covariance[idx1, idx1]/n_idx1
    for (idx2 in seq_len(idx1 - 1)) {
      n_idx2 <- length(unique(sparse_pk[[idx2]]$subject))
      n_both <- length(unique(intersect(sparse_pk[[idx1]]$subject, sparse_pk[[idx2]]$subject)))
      var_auc <-
        var_auc +
        2*weights[idx1]*weights[idx2]*n_both*covariance[idx1, idx2]/(n_idx1*n_idx2)
    }
  }
  attr(var_auc, "df") <-
    sparse_satterthwaite_df(sparse_pk = sparse_pk, weights = weights, covariance = covariance)
  var_auc
}

#' Satterthwaite degrees of freedom for the variance of a sparse AUC or AUMC
#'
#' The variance estimate is a quadratic form in the individual measurements,
#' \eqn{\hat{V} = y^T M y} with
#' \eqn{M = (I - P)^T \Delta B \Delta (I - P)} in the notation of equation 6 of
#' Nedelman and Jia (1998):  \eqn{(I - P)} subtracts the mean at each time, and
#' \eqn{B} pairs the measurements of each subject with the weights
#' \eqn{A_{ij} = w_i w_j r_{ij} / (r_i r_j h_{ij})}, where \eqn{h_{ij}} is the
#' divisor of Holder's covariance (see [cov_holder()]) and \eqn{A_{ij} = 0} where
#' fewer than two subjects are sampled at both times (where [cov_holder()] gives
#' 0).  With \eqn{\Omega} the covariance of the measurements (`covariance` for
#' the measurements of one subject, 0 between subjects), the degrees of freedom
#' are \eqn{2 E^2 / V} with \eqn{E = tr(M\Omega)}, which equals the variance
#' estimate, and \eqn{V = 2 tr(M\Omega M\Omega)}.  When each subject has one
#' sample, this is equation 6a of Nedelman, Gibiansky, and Lau (1995).
#'
#' The matrices have one row per measurement, so they are only built for the
#' measurements of one group.
#'
#' @inheritParams sparse_pk_attribute
#' @param weights The weight of each time in the estimate (such as the
#'   trapezoidal weights)
#' @param covariance The covariance matrix of the times from [cov_holder()]
#' @returns The degrees of freedom, or `NA` if a time has fewer than two
#'   subjects (when its variance cannot be estimated)
#' @references
#' Nedelman JR, Jia X. An extension of Satterthwaite’s approximation applied to
#' pharmacokinetics. Journal of Biopharmaceutical Statistics. 1998;8(2):317-328.
#' doi:10.1080/10543409808835241
#'
#' Nedelman JR, Gibiansky E, Lau DTW. Applying Bailer’s method for AUC
#' confidence intervals to sparse sampling. Pharmaceutical Research.
#' 1995;12(1):124-128.
#' @keywords Internal
#' @noRd
sparse_satterthwaite_df <- function(sparse_pk, weights, covariance) {
  if (anyNA(covariance)) {
    return(NA_real_)
  }
  n_times <- length(sparse_pk)
  subject <- unlist(lapply(sparse_pk, `[[`, "subject"))
  time_idx <- rep(seq_len(n_times), lengths(lapply(sparse_pk, `[[`, "subject")))
  # Subjects at each time (r_i) and at both of two times (r_ij)
  incidence <- unclass(table(factor(time_idx, levels = seq_len(n_times)), subject) > 0) * 1
  r_both <- incidence %*% t(incidence)
  r <- diag(r_both)
  holder_divisor <- (r_both - 1) + (1 - r_both/r) * (1 - t(t(r_both)/r))
  weight_pairs <- outer(weights, weights) * r_both / (outer(r, r) * holder_divisor)
  weight_pairs[r_both < 2] <- 0
  # One row and column per measurement
  same_subject <- outer(subject, subject, "==")
  center <- diag(length(subject)) - outer(time_idx, time_idx, "==")/r[time_idx]
  omega <- covariance[time_idx, time_idx] * same_subject
  b_matrix <- weight_pairs[time_idx, time_idx] * same_subject
  m_omega <- t(center) %*% b_matrix %*% center %*% omega
  expected <- sum(diag(m_omega))
  # tr(X X) is the sum of the elementwise product of X and its transpose
  variance <- 2*sum(m_omega * t(m_omega))
  2*expected^2/variance
}

#' Calculate the covariance for two time points with sparse sampling
#'
#' The calculation follows equation A3 in Holder 2001 (see references below):
#'
#' \deqn{\hat{\sigma}_{ij} = \sum\limits_{k=1}^{r_{ij}}{\frac{\left(x_{ik} - \bar{x}_i\right)\left(x_{jk} - \bar{x}_j\right)}{\left(r_{ij} - 1\right) + \left(1 - \frac{r_{ij}}{r_i}\right)\left(1 - \frac{r_{ij}}{r_j}\right)}}}{sigma_ij = sum_(k=1)^(r_ij)((x_ik-xbar_i)(x_jk-xbar_j)/((r_ij-1)+(1-r_ij/r_i)*(1-r_ij/r_j)))}
#'
#' If \eqn{r_{ij} = 0}{r_ij = 0}, then \eqn{\hat{\sigma}_{ij}}{sigma_ij} is
#' defined as zero (rather than dividing by zero).
#'
#' Where:
#' \describe{
#'   \item{\eqn{\hat{\sigma}_{ij}}{sigma_ij}}{The covariance of times i and j}
#'   \item{\eqn{r_i}{r_i} and \eqn{r_j}{r_j}}{The number of subjects (usually animals) at times i and j, respectively}
#'   \item{\eqn{r_{ij}{r_ij}}}{The number of subjects (usually animals) at both times i and j}
#'   \item{\eqn{x_{ik}}{x_ik} and \eqn{x_{jk}}{x_jk}}{The concentration measured for animal k at times i and j, respectively}
#'   \item{\eqn{\bar{x}_i}{xbar_i} and \eqn{\bar{x}_j}{xbar_j}}{The mean of the concentrations at times i and j, respectively}
#' }
#'
#' The Cauchy-Schwartz inequality is enforced for covariances to keep
#' correlation coefficients between -1 and 1, inclusive, as described in
#' equations 8 and 9 of Nedelman and Jia 1998.
#'
#' @inheritParams sparse_pk_attribute
#' @returns A matrix with one row and one column for each element of
#'   `sparse_pk_attribute`.  The covariances are on the off diagonals, and for
#'   simplicity of use, it also calculates the variance on the diagonal
#'   elements.
#' @keywords Internal
#' @references
#' Holder DJ. Comments on Nedelman and Jia’s Extension of Satterthwaite’s
#' Approximation Applied to Pharmacokinetics. Journal of Biopharmaceutical
#' Statistics. 2001;11(1-2):75-79. doi:10.1081/BIP-100104199
#'
#' Nedelman JR, Jia X. An extension of Satterthwaite’s approximation applied to
#' pharmacokinetics. Journal of Biopharmaceutical Statistics. 1998;8(2):317-328.
#' doi:10.1080/10543409808835241
#' @export
cov_holder <- function(sparse_pk) {
  ret <-
    matrix(
      data=0,
      nrow=length(sparse_pk),
      ncol=length(sparse_pk)
    )
  
  time_means <- sparse_pk_attribute(sparse_pk, "mean")
  
  for (idx1 in seq_along(sparse_pk)) {
    # Variance on the diagonal
    ret[idx1, idx1] <- stats::var(sparse_pk[[idx1]]$conc)
    for (idx2 in seq_len(idx1 - 1)) {
      subject_idx1 <- sparse_pk[[idx1]]$subject
      subject_idx2 <- sparse_pk[[idx2]]$subject
      subject_both <- intersect(subject_idx1, subject_idx2)
      if (length(subject_both) > 1) {
        # Holder covariance on the off-diagonals when there is more than one
        # subject in both times
        cov_ij <- 0
        for (current_subject in subject_both) {
          cov_ij <-
            cov_ij +
            (sparse_pk[[idx1]]$conc[sparse_pk[[idx1]]$subject %in% current_subject] - time_means[[idx1]]) *
            (sparse_pk[[idx2]]$conc[sparse_pk[[idx2]]$subject %in% current_subject] - time_means[[idx2]])
        }
        # Apply the common denominator
        cov_ij <-
          cov_ij /
          (
            (length(subject_both) - 1) + (1 - length(subject_both)/length(subject_idx1))*(1 - length(subject_both)/length(subject_idx2))
          )
        # Enforce the Cauchy-Schwartz inequality
        cov_cs <- sqrt(ret[idx1, idx1] * ret[idx2, idx2])
        if (abs(cov_ij) > cov_cs) {
          cov_ij <- sign(cov_ij)*cov_cs
        }
        # The matrix is symmetric
        ret[idx1, idx2] <- ret[idx2, idx1] <- cov_ij
      }
    }
  }
  ret
}

#' Extract the mean concentration-time profile as a data.frame
#'
#' @inheritParams sparse_pk_attribute
#' @return A data.frame with names of "conc" and "time"
#' @keywords Internal
sparse_to_dense_pk <- function(sparse_pk) {
  data.frame(
    conc=sparse_pk_attribute(sparse_pk, "mean"),
    time=sparse_pk_attribute(sparse_pk, "time")
  )
}

#' Calculate AUC and related parameters using sparse NCA methods
#'
#' The AUC is calculated as:
#'
#' \deqn{AUC=\sum\limits_{i} w_i \bar{C}_i}{AUC = sum(w_i * Cbar_i)}
#'
#' Where:
#'
#' \describe{
#'   \item{\eqn{AUC}{AUC}}{is the estimated area under the concentration-time curve}
#'   \item{\eqn{w_i}{w_i}}{is the weight applied to the concentration at time i (related to the time which it affects, see [sparse_auc_weight_linear()])}
#'   \item{\eqn{\bar{C}_i}{Cbar_i}}{is the average concentration at time i}
#' }
#' @inheritParams pk.calc.auc
#' @inheritParams as_sparse_pk
#' @family Sparse Methods
#' @export
pk.calc.sparse_auc <- function(conc, time, subject,
                               method="linear",
                               auc.type="AUClast",
                               ...,
                               options=list()) {
  # Sparse AUC is only defined for linear interpolation.  `method` is kept as an
  # argument so it is used consistently below (and so other methods could be
  # enabled here in the future), but only "linear" is currently allowed.
  if (!identical(method, "linear")) {
    rlang::abort('Sparse AUC calculation only supports `method = "linear"`.', class = "pknca_error_sparse_auc_method")
  }
  sparse_pk <- as_sparse_pk(conc=conc, time=time, subject=subject)
  sparse_pk_mean <- sparse_mean(sparse_pk=sparse_pk, sparse_mean_method="arithmetic mean, <=50% BLQ")
  # The weights end where the AUC does, so the variance describes the same area
  sparse_pk_mean <- sparse_auc_weight_type(sparse_pk_mean, auc.type = auc.type)
  auc <-
    pk.calc.auc(
      conc=sparse_pk_attribute(sparse_pk_mean, "mean"),
      time=sparse_pk_attribute(sparse_pk_mean, "time"),
      auc.type=auc.type,
      method=method,
      options=options
    )

  # Without an estimate (no concentration at time 0, say), there is no
  # standard error either
  var_auc <-
    if (is.na(auc)) {
      structure(NA_real_, df = NA_real_)
    } else {
      var_sparse_auc(sparse_pk_mean)
    }
  ret <- data.frame(
    sparse_auc=auc,
    # as.numeric() drops the "df" attribute
    sparse_auc_se=sqrt(as.numeric(var_auc)),
    sparse_auc_df=attr(var_auc, "df")
  )

  # Add method details as an attribute
  for (col in names(ret)) {
    attr(ret[[col]], "method") <- c(paste0("AUC: ", method), "Sparse: arithmetic mean, <=50% BLQ")
  }

  ret
}

#' @describeIn pk.calc.sparse_auc Compute the AUClast for sparse PK
#' @export
pk.calc.sparse_auclast <- function(conc, time, subject, ..., options=list()) {
  if ("auc.type" %in% names(list(...))) {
    rlang::abort(
      "auc.type cannot be changed when calling pk.calc.sparse_auclast, please use pk.calc.sparse_auc",
      class = "pknca_error_sparse_auclast_change_auclast"
    )
  }
  ret <-
    pk.calc.sparse_auc(
      conc=conc, time=time, subject=subject, ...,
      options=options,
      auc.type="AUClast",
      lambda.z=NA
    )
  names(ret)[names(ret) == "sparse_auc"] <- "sparse_auclast"
  ret
}

pknca_concept(pk.calc.sparse_auclast) <- "auc"

add.interval.col(
  "sparse_auclast",
  FUN=NA,
  FUN_sparse="pk.calc.sparse_auclast",
  values=c(FALSE, TRUE),
  unit_type="auc",
  pretty_name="Sparse AUClast",
  desc="Sparse AUC to last conc above LOQ",
  # Deprecated in favor of auclast's own sparse estimator (see
  # deprecated_sparse_parameters below), and computes the identical value;
  # shares its CT code (CDISC has no sparse-specific AUClast code).
  pptestcd_cdisc="AUCLST",
  pptest_cdisc="AUC to Last Nonzero Conc",
  formula="$AUC_{\\text{sparse}} = \\sum_k \\frac{\\bar{C}_k + \\bar{C}_{k+1}}{2} \\Delta t_k$",
  formula_note="Linear trapezoidal using population mean concentrations",
  tier = "common")

add.interval.col(
  "sparse_auc_se",
  FUN=NA,
  values=c(FALSE, TRUE),
  unit_type="auc",
  pretty_name="Sparse AUClast standard error",
  desc="SE of sparse AUC to last conc above LOQ",
  depends="sparse_auclast",
  # No CDISC PKPARMCD code exists for the standard error of a PK parameter
  # (real submissions carry this in SUPPPP, not as its own PP record); kept
  # as a sponsor-defined code despite the "common" tier -- see the
  # pknca_cdisc_codes() gap list.
  pptestcd_cdisc="SPARSEAS",
  pptest_cdisc="Sparse AUClast standard error",
  formula="$SE(AUC_{\\text{sparse}}) = \\sqrt{\\sum_{i,j} w_i w_j \\hat{\\sigma}_{ij} / n}$",
  formula_note="Variance from weighted covariance across subjects (Nedelman and Jia 1998, Holder 2001)",
  tier = "common")

add.interval.col(
  "sparse_auc_df",
  FUN=NA,
  values=c(FALSE, TRUE),
  unit_type="count",
  pretty_name="Sparse AUClast degrees of freedom",
  desc="DF for sparse AUC to last conc above LOQ",
  depends="sparse_auclast",
  pptestcd_cdisc="SPARSEAD",
  pptest_cdisc="Sparse AUClast degrees of freedom",
  formula="$df = \\frac{\\left(tr(M\\Omega)\\right)^2}{tr\\left(\\left(M\\Omega\\right)^2\\right)}$",
  formula_note="Satterthwaite approximation for any sampling design (Nedelman and Jia 1998, eq. 6)")

# The interval-specification names that the unified sparse parameters replace.
# They still calculate, and give the same values they always have, but they are
# deprecated:  see warn_deprecated_sparse_parameters().
#
# `kel.sparse.last` maps to `kel.last` because both are 1/MRT.  Only
# `vz.sparse.last` changes meaning:  `vz.last` divides the clearance by the
# terminal rate constant fitted on the mean profile rather than by 1/MRT, which
# is why `vz.sparse.last` equals `vss.sparse.last` and `vz.last` does not equal
# `vss.last`.
deprecated_sparse_parameters <- c(
  sparse_auclast = "auclast",
  sparse_auc_se = "auclast_se",
  sparse_auc_df = "auclast_df",
  sparse_aumclast = "aumclast",
  sparse_aumc_se = "aumclast_se",
  sparse_aumc_df = "aumclast_df",
  cl.sparse.last = "cl.last",
  mrt.sparse.last = "mrt.last",
  kel.sparse.last = "kel.last",
  vss.sparse.last = "vss.last",
  vz.sparse.last = "vz.last"
)

# Warn once per session for each set of deprecated parameter names an interval
# specification requests.  These are interval-specification columns rather than
# functions, so there is no function call for lifecycle to attach itself to.
warn_deprecated_sparse_parameters <- function(requested) {
  deprecated <- intersect(names(deprecated_sparse_parameters), requested)
  if (length(deprecated) == 0) {
    return(invisible(NULL))
  }
  replacement_note <-
    ifelse(
      deprecated %in% "vz.sparse.last",
      " (which uses the lambda.z fitted on the mean profile rather than 1/MRT, so the value changes)",
      ""
    )
  rlang::warn(
    sprintf(
      "%s deprecated and will be an error in the next minor release of PKNCA; use %s instead:\n%s",
      ngettext(length(deprecated), msg1="This NCA parameter is", msg2="These NCA parameters are"),
      ngettext(length(deprecated), msg1="the unified name", msg2="the unified names"),
      paste0(
        "  ", deprecated, " -> ", deprecated_sparse_parameters[deprecated], replacement_note,
        collapse = "\n"
      )
    ),
    class = "pknca_warning_deprecated_sparse_parameter",
    .frequency = "once",
    .frequency_id = paste(c("pknca_deprecated_sparse", sort(deprecated)), collapse = "_")
  )
}

#' Is a PKNCA object used for sparse PK?
#'
#' @param object The object to see if it includes sparse PK
#' @returns `TRUE` if sparse and `FALSE` if dense (not sparse)
#' @export
is_sparse_pk <- function(object) {
  UseMethod("is_sparse_pk")
}

#' Calculate the variance for the AUMC of sparsely sampled PK
#'
#' This function calculates the variance of the area under the first moment
#' curve (AUMC) for sparse PK data. It follows the same methodology as
#' [var_sparse_auc()] but applies to the moment curve (time × concentration).
#'
#' Equation 7.vii in Nedelman and Jia, 1998 is adapted for AUMC:
#'
#' \deqn{var\left(\hat{AUMC}\right) = \sum\limits_{i=0}^m\left(\frac{w_i^2 s_i^2}{r_i}\right) + 2\sum\limits_{i<j}\left(\frac{w_i w_j r_{ij} s_{ij}}{r_i r_j}\right)}{var(AUMC) = sum_(i=0)^(m) ((w_i^2 * s_i^2)/(r_i) + + 2*sum_(i<j)((w_i * w_j * r_ij * s_ij)/(r_i * r_j))}
#'
#' where the variance and covariance terms are calculated on the moment curve
#' (time × concentration) rather than concentration alone.
#'
#' The degrees of freedom are calculated as described in equation 6 of the same
#' paper, reusing the structure from [var_sparse_auc()].
#'
#' @inheritParams sparse_pk_attribute
#' @returns The variance of the AUMC estimate with a "df" attribute containing
#'   the degrees of freedom
#' @references
#' Nedelman JR, Jia X. An extension of Satterthwaite's approximation applied to
#' pharmacokinetics. Journal of Biopharmaceutical Statistics. 1998;8(2):317-328.
#' doi:10.1080/10543409808835241
#' @keywords internal
#' @export
var_sparse_aumc <- function(sparse_pk) {
  # Times with no weight in the AUMC or an imputed (known) concentration do not
  # contribute to its variance
  sparse_pk <- sparse_pk_weighted(sparse_pk)
  if (length(sparse_pk) == 0) {
    return(structure(0, df = NA_real_))
  }
  # Step 1: Transform concentration to moment data (t * C) per subject
  # Must be done BEFORE calculating means — variance must be estimated
  # on individual moment values, not on mean concentrations
  # (Nedelman and Jia, 1998, equation 7.vii extended to moment curve)
  moment_sparse_pk <- sparse_pk
  for (idx in seq_along(moment_sparse_pk)) {
    time_i <- moment_sparse_pk[[idx]]$time
    # Multiply each individual concentration measurement by its time
    moment_sparse_pk[[idx]]$conc <-
      moment_sparse_pk[[idx]]$conc * time_i
  }
  
  # Step 2: Calculate mean of moment data at each time point
  # mean(t*C) not mean(C) — critical for correct variance estimation
  moment_sparse_pk_mean <- sparse_mean(
    sparse_pk = moment_sparse_pk,
    sparse_mean_method = "arithmetic mean, <=50% BLQ"
  )
  
  # Step 3: Covariance matrix on moment data using Holder (2001) estimator
  covariance <- cov_holder(moment_sparse_pk_mean)
  
  # Step 4: Variance of AUMC via weighted sum (equation 7.vii,
  # Nedelman and Jia 1998, applied to moment data)
  var_aumc <- 0
  # Use ORIGINAL sparse_pk for weights (time-based, not moment-based)
  weights <- sparse_pk_attribute(sparse_pk, "weight")

  for (idx1 in seq_along(sparse_pk)) {
    n_idx1 <- length(unique(sparse_pk[[idx1]]$subject))
    var_aumc <-
      var_aumc +
      weights[idx1]^2 * covariance[idx1, idx1] / n_idx1
    
    for (idx2 in seq_len(idx1 - 1)) {
      n_idx2 <- length(unique(sparse_pk[[idx2]]$subject))
      n_both <- length(unique(intersect(sparse_pk[[idx1]]$subject, sparse_pk[[idx2]]$subject)))
      var_aumc <-
        var_aumc +
        2 * weights[idx1] * weights[idx2] * n_both * covariance[idx1, idx2] / (n_idx1 * n_idx2)
    }
  }
  
  # Step 5: Degrees of freedom — Satterthwaite approximation
  # (equation 6, Nedelman and Jia 1998, on the moment data)
  attr(var_aumc, "df") <-
    sparse_satterthwaite_df(sparse_pk = sparse_pk, weights = weights, covariance = covariance)
  var_aumc
}

#' Calculate AUMC and related parameters using sparse NCA methods
#'
#' The AUMC is calculated as:
#'
#' \deqn{AUMC=\sum\limits_{i} w_i \overline{t_i C_i}}{AUMC = sum(w_i * mean(t_i * C_i))}
#'
#' Where:
#'
#' \describe{
#'   \item{\eqn{AUMC}{AUMC}}{is the estimated area under the first moment curve}
#'   \item{\eqn{w_i}{w_i}}{is the weight applied to time i (same as for AUC, see [sparse_auc_weight_linear()])}
#'   \item{\eqn{\overline{t_i C_i}}{mean(t_i * C_i)}}{is the average of the moment (time × concentration) at time i}
#' }
#'
#' @inheritParams pk.calc.sparse_auc
#' @returns A data.frame with columns:
#'   \item{sparse_aumc}{The estimated AUMC}
#'   \item{sparse_aumc_se}{Standard error of the AUMC estimate}
#'   \item{sparse_aumc_df}{Degrees of freedom for the variance estimate}
#' @family Sparse Methods
#' @export
pk.calc.sparse_aumc <- function(conc, time, subject,
                                method = "linear",
                                auc.type = "AUClast",
                                ...,
                                options = list()) {
  # Sparse AUMC is only defined for linear interpolation (see pk.calc.sparse_auc).
  if (!identical(method, "linear")) {
    rlang::abort('Sparse AUMC calculation only supports `method = "linear"`.', class = "pknca_error_sparse_aumc_method")
  }
  # Create sparse_pk object from data
  sparse_pk <- as_sparse_pk(conc = conc, time = time, subject = subject)

  # Calculate mean CONCENTRATION (for pk.calc.aumc integration)
  sparse_pk_mean <- sparse_mean(
    sparse_pk = sparse_pk,
    sparse_mean_method = "arithmetic mean, <=50% BLQ"
  )
  # Calculate weights (same as for AUC), ending where the AUMC does
  sparse_pk_mean <- sparse_auc_weight_type(sparse_pk_mean, auc.type = auc.type)
  
  # Use pk.calc.aumc on the mean concentration profile
  # pk.calc.aumc will handle the time*conc multiplication during integration
  aumc <-
    pk.calc.aumc(
      conc = sparse_pk_attribute(sparse_pk_mean, "mean"),
      time = sparse_pk_attribute(sparse_pk_mean, "time"),
      auc.type = auc.type,
      method = method,
      options = options
    )
  
  # Calculate variance on MOMENT data (this is where the fix matters)
  # var_sparse_aumc will create moment data internally
  var_aumc <-
    if (is.na(aumc)) {
      # Without an estimate (no concentration at time 0, say), there is no
      # standard error either
      structure(NA_real_, df = NA_real_)
    } else {
      var_sparse_aumc(sparse_pk_mean)
    }

  data.frame(
    sparse_aumc = aumc,
    sparse_aumc_se = sqrt(as.numeric(var_aumc)),
    sparse_aumc_df = attr(var_aumc, "df")
  )
}

#' @describeIn pk.calc.sparse_aumc Compute the AUMClast for sparse PK
#' @export
pk.calc.sparse_aumclast <- function(conc, time, subject, ..., options = list()) {
  if ("auc.type" %in% names(list(...))) {
    rlang::abort(
      "auc.type cannot be changed when calling pk.calc.sparse_aumclast, please use pk.calc.sparse_aumc",
      class = "pknca_error_sparse_aumclast_change_auc_type"
    )
  }
  ret <- pk.calc.sparse_aumc(
    conc = conc, time = time, subject = subject,
    ..., options = options,
    auc.type = "AUClast",
    lambda.z = NA
  )
  names(ret)[names(ret) == "sparse_aumc"] <- "sparse_aumclast"
  ret
}

pknca_concept(pk.calc.sparse_aumclast) <- "aumc"

add.interval.col(
  "sparse_aumclast",
  FUN = NA,
  FUN_sparse = "pk.calc.sparse_aumclast",
  values = c(FALSE, TRUE),
  unit_type = "aumc",
  pretty_name = "Sparse AUMClast",
  desc = "Sparse AUMC to last conc above LOQ",
  depends     = "sparse_auclast",
  # CDISC has no code for a sparse AUMC estimate (only SPARSEAL/AS/AD cover
  # sparse AUC); sponsor-defined, consistent with those.
  pptestcd_cdisc = "SPARSEML",
  pptest_cdisc = "Sparse AUMClast"
)

add.interval.col(
  "sparse_aumc_se",
  FUN = NA,
  values = c(FALSE, TRUE),
  unit_type = "aumc",
  pretty_name = "Sparse AUMC standard error",
  desc = "SE of sparse AUMC to last conc above LOQ",
  depends = "sparse_aumclast",
  pptestcd_cdisc = "SPARSEMS",
  pptest_cdisc = "Sparse AUMClast standard error"
)

add.interval.col(
  "sparse_aumc_df",
  FUN = NA,
  values = c(FALSE, TRUE),
  unit_type = "count",
  pretty_name = "Sparse AUMC degrees of freedom",
  desc = "variance DF for sparse AUMC to Tlast",
  depends = "sparse_aumclast",
  pptestcd_cdisc = "SPARSEMD",
  pptest_cdisc = "Sparse AUMClast degrees of freedom"
)

PKNCA.set.summary(
  name = c("sparse_auclast", "sparse_aumclast"),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)

PKNCA.set.summary(
  name = c("sparse_auc_df", "sparse_aumc_df"),
  description = "arithmetic mean and standard deviation",
  point = business.mean,
  spread = business.sd
)

PKNCA.set.summary(
  name = "sparse_auc_se",
  description = "estimate and standard error",
  point = business.mean,
  spread = summary_spread_one_se,
  spread_for = "sparse_auclast"
)
PKNCA.set.summary(
  name = "sparse_aumc_se",
  description = "estimate and standard error",
  point = business.mean,
  spread = summary_spread_one_se,
  spread_for = "sparse_aumclast"
)
