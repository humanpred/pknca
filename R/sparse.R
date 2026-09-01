#' Generate a sparse_pk object
#'
#' @inheritParams assert_conc_time
#' @param subject Subject identifiers (may be any class; may not be null)
#' @returns A sparse_pk object which is a list of lists.  The inner lists have
#'   elements named: "time", The time of measurement; "conc", The concentration
#'   measured; "subject", The subject identifiers.  The object will usually be
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
  checkmate::assert_vector(subject, any.missing=FALSE, len=length(conc), null.ok=FALSE)
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
    ret <-
      append(
        ret,
        list(list(
          time=current_time,
          conc=conc[current_mask],
          subject=subject[current_mask]
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

#' Calculate the variance for the AUC of sparsely sampled PK
#'
#' Equation 7.vii in Nedelman and Jia, 1998 is used for this calculation:
#'
#' \deqn{var\left(\hat{AUC}\right) = \sum\limits_{i=0}^m\left(\frac{w_i^2 s_i^2}{r_i}\right) + 2\sum\limits_{i<j}\left(\frac{w_i w_j r_{ij} s_{ij}}{r_i r_j}\right)}{var(AUC) = sum_(i=0)^(m) ((w_i^2 * s_i^2)/(r_i) + + 2*sum_(i<j)((w_i * w_j * r_ij * s_ij)/(r_i * r_j))}
#'
#' The degrees of freedom are calculated as described in equation 6 of the same
#' paper.
#'
#' @inheritParams sparse_pk_attribute
#' @references
#' Nedelman JR, Jia X. An extension of Satterthwaite’s approximation applied to
#' pharmacokinetics. Journal of Biopharmaceutical Statistics. 1998;8(2):317-328.
#' doi:10.1080/10543409808835241
#' @export
var_sparse_auc <- function(sparse_pk) {
  covariance <- cov_holder(sparse_pk)
  var_auc <- 0
  weights <- sparse_pk_attribute(sparse_pk, "weight")
  # number of subjects at a given time point
  n <- rep(0, length(sparse_pk))
  df <- 0
  for (idx1 in seq_along(sparse_pk)) {
    n_idx1 <- length(unique(sparse_pk[[idx1]]$subject))
    n[idx1] <- n_idx1
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
  # df based on equation 6 of Nedelman and Jia 1998
  # df_e <- sum(diag(covariance))
  # df_v <- 2*sum(diag(covariance %*% covariance))
  # df <- 2*df_e^2/df_v
  # df based on equation 6a of Nedelman et al 1995
  df <-
    sum(weights^2 * diag(covariance)/n)^2 /
    sum(weights^4 * diag(covariance)^2/(n^2*(n-1)))
  if (sum(covariance[lower.tri(covariance)] != 0) > 0) {
    rlang::warn(
      "Cannot yet calculate sparse degrees of freedom for multiple samples per subject",
      class = "pknca_warning_sparse_df_multi"
    )
    df <- NA_real_
  } 
  attr(var_auc, "df") <- df
  var_auc
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
  sparse_pk_wt <- sparse_auc_weight_linear(sparse_pk)
  sparse_pk_mean <- sparse_mean(sparse_pk=sparse_pk_wt, sparse_mean_method="arithmetic mean, <=50% BLQ")
  auc <-
    pk.calc.auc(
      conc=sparse_pk_attribute(sparse_pk_mean, "mean"),
      time=sparse_pk_attribute(sparse_pk_mean, "time"),
      auc.type=auc.type,
      method=method,
      options=options
    )

  var_auc <- var_sparse_auc(sparse_pk_mean)
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
  pptestcd_cdisc="SPARSEAL",
  pptest_cdisc="Sparse AUClast",
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
  formula="$df = \\frac{\\left(\\sum w_i^2 \\hat{\\sigma}_{ii}/n_i\\right)^2}{\\sum w_i^4 \\hat{\\sigma}_{ii}^2 / (n_i^2(n_i-1))}$",
  formula_note="Satterthwaite approximation (Nedelman et al 1995, eq. 6a)")

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
  # number of subjects at a given time point
  n <- rep(0, length(sparse_pk))
  
  for (idx1 in seq_along(sparse_pk)) {
    n_idx1 <- length(unique(sparse_pk[[idx1]]$subject))
    n[idx1] <- n_idx1
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
  # (equation 6, Nedelman and Jia 1998)
  df <-
    sum(weights^2 * diag(covariance) / n)^2 /
    sum(weights^4 * diag(covariance)^2 / (n^2 * (n - 1)))
  
  if (sum(covariance[lower.tri(covariance)] != 0) > 0) {
    rlang::warn(
      "Cannot yet calculate sparse degrees of freedom for multiple samples per subject",
      class = "pknca_warning_sparse_aumc_df_multi"
    )
    df <- NA_real_
  }
  # else if (any(n == 1)) {
  #   # Requires >= 2 subjects per time point for df calculation
  #   df <- NA_real_
  # }
  
  attr(var_aumc, "df") <- df
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
  
  # Calculate weights (same as for AUC)
  sparse_pk_wt <- sparse_auc_weight_linear(sparse_pk)
  
  # Calculate mean CONCENTRATION (for pk.calc.aumc integration)
  sparse_pk_mean <- sparse_mean(
    sparse_pk = sparse_pk_wt,
    sparse_mean_method = "arithmetic mean, <=50% BLQ"
  )
  
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
  var_aumc <- var_sparse_aumc(sparse_pk_wt)
  
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
  depends     = "sparse_auclast"
)

add.interval.col(
  "sparse_aumc_se",
  FUN = NA,
  values = c(FALSE, TRUE),
  unit_type = "aumc",
  pretty_name = "Sparse AUMC standard error",
  desc = "SE of sparse AUMC to last conc above LOQ",
  depends = "sparse_aumclast"
)

add.interval.col(
  "sparse_aumc_df",
  FUN = NA,
  values = c(FALSE, TRUE),
  unit_type = "count",
  pretty_name = "Sparse AUMC degrees of freedom",
  desc = "variance DF for sparse AUMC to Tlast",
  depends = "sparse_aumclast"
)

PKNCA.set.summary(
  name = c("sparse_auclast", "sparse_aumclast"),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)

PKNCA.set.summary(
  name = c(
    "sparse_auc_se", "sparse_auc_df",
    "sparse_aumc_se", "sparse_aumc_df"
  ),
  description = "arithmetic mean and standard deviation",
  point = business.mean,
  spread = business.sd
)
