#' Compute the half-life and associated parameters
#'
#' The terminal elimination half-life is estimated from the final points in the
#' concentration-time curve using semi-log regression (`log(conc)~time`, the
#' `"log-linear"` method) or Tobit regression (`"tobit"` method) with automated
#' selection of the points for calculation (unless `manually.selected.points` is
#' `TRUE`).
#'
#' See the "Half-Life Calculation" and "Half-Life Calculation with Tobit
#' Regression" vignettes for more details on the calculation methods.
#'
#' @details If `manually.selected.points` is `FALSE` (default), the
#' half-life is calculated by computing the best fit line for all points at or
#' after tmax (based on the value of `allow.tmax.in.half.life`).
#'
#' For `hl_method = "log-linear"`, the best half-life is chosen by the
#' following rules in order:
#'
#' \itemize{
#'  \item{At least `min.hl.points` points included}
#'  \item{A `lambda.z` > 0 and at the same time the best adjusted r-squared
#'  (within `adj.r.squared.factor`)}
#'  \item{The one with the most points included}
#' }
#'
#' For `hl_method = "tobit"`, BLQ observations are retained and treated as
#' left-censored.  The best window is the one minimizing
#' `tobit_residual * n ^ tobit_n_points_penalty` (default: raw `tobit_residual`)
#' among windows with `lambda.z > 0` and at least `min.hl.points` above-LLOQ
#' points.  On ties the largest window (most total points) is preferred.
#'
#' If `manually.selected.points` is `TRUE`, the `conc` and `time` data are
#' used as-is without any form of point selection.  When
#' `TRUE`, `adj.r.squared.factor`, `min.hl.points`, and
#' `allow.tmax.in.half.life` are ignored.
#'
#' @inheritParams assert_conc_time
#' @inheritParams choose_interval_method
#' @inheritParams PKNCA.choose.option
#' @inheritParams pk.nca.interval
#' @param tmax Time of maximum concentration (will be calculated and
#'   included in the return data frame if not given)
#' @param tlast Time of last concentration above the limit of
#'   quantification (will be calculated and included in the return data
#'   frame if not given)
#' @param lloq Lower limit of quantification.  A scalar or a vector the same
#'   length as `conc`.  Required when `hl_method = "tobit"`.
#' @param hl_method The method used to estimate the half-life.
#'   `"log-linear"` (default) uses ordinary least-squares regression on
#'   log-transformed concentrations.  `"tobit"` uses maximum-likelihood Tobit
#'   regression that properly accounts for BLQ observations.  The global default
#'   can be changed via `PKNCA.options(hl_method = "tobit")`.
#' @param manually.selected.points Have the input points (`conc` and
#'   `time`) been manually selected?  The impact of setting this to
#'   `TRUE` is that no selection for the best points will be done.  When
#'   `TRUE`, this option causes the options of `adj.r.squared.factor`,
#'   `min.hl.points`, and `allow.tmax.in.half.life` to be ignored.
#' @param min.hl.points The minimum number of points that must be
#'   included to calculate the half-life.  For `hl_method = "tobit"` this
#'   counts only above-LLOQ points.
#' @param adj.r.squared.factor The allowance in adjusted r-squared for
#'   adding another point (log-linear method only).
#' @param tobit_n_points_penalty The penalty exponent on the number of points
#'   for Tobit window selection.  See [PKNCA.options()].
#' @param tobit_optim_control A list of control parameters passed to
#'   [stats::optim()] for the Tobit fit.  See [PKNCA.options()].
#' @inheritParams clean.conc.blq
#' @inheritParams pk.calc.tmax
#' @param allow.tmax.in.half.life Allow the concentration point for tmax
#'   to be included in the half-life slope calculation.
#' @return A data frame with one row.  Columns depend on `hl_method`:
#'
#'   Columns returned by both methods:
#'  \describe{
#'   \item{tmax}{Time of maximum observed concentration (only included
#'     if not given as an input)}
#'   \item{tlast}{Time of last observed concentration above the LOQ (only
#'     included if not given as an input)}
#'   \item{lambda.z}{elimination rate}
#'   \item{lambda.z.time.first}{first time for half-life calculation}
#'   \item{lambda.z.time.last}{last time for half-life calculation}
#'   \item{lambda.z.n.points}{number of points in half-life calculation
#'     (all points for Tobit, including BLQ)}
#'   \item{clast.pred}{Concentration at tlast as predicted by the half-life
#'     line}
#'   \item{half.life}{half-life}
#'   \item{span.ratio}{ratio of the above-LLOQ time span to the half-life}
#'  }
#'
#'   Additional columns for `hl_method = "log-linear"`:
#'  \describe{
#'   \item{r.squared}{coefficient of determination}
#'   \item{adj.r.squared}{adjusted coefficient of determination}
#'   \item{lambda.z.corrxy}{correlation between time and log-conc for the
#'     half-life points}
#'  }
#'
#'   Additional columns for `hl_method = "tobit"`:
#'  \describe{
#'   \item{lambda.z.n.points_blq}{number of BLQ points included in the fit}
#'   \item{tobit_residual}{estimated residual standard deviation from the
#'     Tobit fit (on the log-concentration scale)}
#'   \item{adj_tobit_residual}{adjusted Tobit residual (analogous to
#'     adjusted r-squared; penalizes smaller windows)}
#'  }
#' @references
#'
#' Gabrielsson J, Weiner D.  "Section 2.8.4 Strategies for estimation of
#' lambda-z."  Pharmacokinetic & Pharmacodynamic Data Analysis: Concepts
#' and Applications, 4th Edition.  Stockholm, Sweden: Swedish
#' Pharmaceutical Press, 2000.  167-9.
#' @family NCA parameter calculations
#' @family Half-life and elimination
#' @export
pk.calc.half.life <- function(conc, time, tmax, tlast,
                              time.dose=NULL,
                              duration.dose=0,
                              lloq=NULL,
                              hl_method=c("log-linear", "tobit"),
                              manually.selected.points=FALSE,
                              options=list(),
                              min.hl.points=NULL,
                              adj.r.squared.factor=NULL,
                              tobit_n_points_penalty=NULL,
                              tobit_optim_control=NULL,
                              conc.blq=NULL,
                              conc.na=NULL,
                              first.tmax=NULL,
                              allow.tmax.in.half.life=NULL,
                              check=TRUE) {
  # Resolve hl_method: explicit argument takes match.arg; missing uses PKNCA.options
  if (missing(hl_method)) {
    hl_method <- PKNCA.choose.option(name = "hl_method", value = NULL, options = options)
  } else {
    hl_method <- match.arg(hl_method)
  }
  is_tobit <- hl_method == "tobit"

  # Resolve remaining options
  min.hl.points <-
    PKNCA.choose.option(name="min.hl.points", value=min.hl.points, options=options)
  conc.blq <-
    PKNCA.choose.option(name="conc.blq", value=conc.blq, options=options)
  conc.na <-
    PKNCA.choose.option(name="conc.na", value=conc.na, options=options)
  first.tmax <-
    PKNCA.choose.option(name="first.tmax", value=first.tmax, options=options)
  allow.tmax.in.half.life <-
    PKNCA.choose.option(name="allow.tmax.in.half.life", value=allow.tmax.in.half.life, options=options)
  if (!is_tobit) {
    adj.r.squared.factor <-
      PKNCA.choose.option(name="adj.r.squared.factor", value=adj.r.squared.factor, options=options)
  } else {
    tobit_n_points_penalty <-
      PKNCA.choose.option(name="tobit_n_points_penalty", value=tobit_n_points_penalty, options=options)
    tobit_optim_control <-
      PKNCA.choose.option(name="tobit_optim_control", value=tobit_optim_control, options=options)
    if (is.null(lloq)) {
      stop("lloq must be provided when hl_method is 'tobit'")
    }
  }

  # --- Data preparation ---
  if (check) {
    assert_conc_time(conc = conc, time = time)
    data <- clean.conc.blq(conc, time, conc.blq=conc.blq, conc.na=conc.na)
  } else {
    data <- data.frame(conc=conc, time=time)
  }

  if (is_tobit) {
    # For Tobit: build a parallel data set keeping BLQ observations.
    # Only remove NA concentrations/times; do not drop BLQ values.
    lloq_vec <- if (length(lloq) == 1) rep(as.numeric(lloq), length(conc)) else as.numeric(lloq)
    keep_tobit <- !is.na(conc) & !is.na(time)
    data_tobit <- data.frame(
      conc = as.numeric(conc)[keep_tobit],
      time = as.numeric(time)[keep_tobit],
      lloq = lloq_vec[keep_tobit]
    )
    data_tobit$mask_blq <- data_tobit$conc < data_tobit$lloq
    data_tobit$log_lloq  <- log(data_tobit$lloq)
    data_tobit$log_conc  <- log(data_tobit$conc)  # -Inf for 0; mask_blq governs usage
    if (!is.null(time.dose)) {
      end.dose <- as.numeric(time.dose) + as.numeric(duration.dose)
      if (any(!is.na(end.dose))) {
        data_tobit <- data_tobit[data_tobit$time > max(end.dose, na.rm = TRUE), ]
      }
    }
  }

  data$log_conc <- log(data$conc)
  # Filter out points with 0 concentration. as.numeric() to handle units objects
  data <- data[as.numeric(data$conc) > 0, ]
  if (!is.null(time.dose)) {
    end.dose <- as.numeric(time.dose) + as.numeric(duration.dose)
    if (any(!is.na(end.dose))) {
      data <- data[as.numeric(data$time) > max(end.dose, na.rm = TRUE), ]
    }
  }

  # Build return skeleton.  Column order must match existing behaviour for the
  # log-linear method (tests compare whole data frames including column order).
  if (!is_tobit) {
    ret <- data.frame(
      lambda.z            = NA_real_,
      r.squared           = NA_real_,
      adj.r.squared       = NA_real_,
      lambda.z.corrxy     = NA_real_,
      lambda.z.time.first = NA_real_,
      lambda.z.time.last  = NA_real_,
      lambda.z.n.points   = NA_integer_,
      clast.pred          = NA_real_,
      half.life           = NA_real_,
      span.ratio          = NA_real_
    )
    ret_replacements <- c(
      "lambda.z", "r.squared", "adj.r.squared", "lambda.z.corrxy",
      "lambda.z.time.first", "lambda.z.time.last", "lambda.z.n.points",
      "clast.pred", "half.life", "span.ratio"
    )
  } else {
    ret <- data.frame(
      lambda.z              = NA_real_,
      lambda.z.time.first   = NA_real_,
      lambda.z.time.last    = NA_real_,
      lambda.z.n.points     = NA_integer_,
      lambda.z.n.points_blq = NA_integer_,
      clast.pred            = NA_real_,
      half.life             = NA_real_,
      span.ratio            = NA_real_,
      tobit_residual        = NA_real_,
      adj_tobit_residual    = NA_real_
    )
    ret_replacements <- c(
      "lambda.z", "lambda.z.time.first", "lambda.z.time.last",
      "lambda.z.n.points", "lambda.z.n.points_blq",
      "clast.pred", "half.life", "span.ratio",
      "tobit_residual", "adj_tobit_residual"
    )
  }

  # tmax and tlast are always derived from the standard (above-LOQ) data
  if (missing(tmax)) {
    ret$tmax <- pk.calc.tmax(data$conc, data$time, first.tmax=first.tmax, check=FALSE)
  } else {
    ret$tmax <- tmax
  }
  if (missing(tlast)) {
    ret$tlast <- pk.calc.tlast(data$conc, data$time, check=FALSE)
  } else {
    ret$tlast <- tlast
  }

  # When all concentrations are the same (non-zero) value cannot compute half-life (#503)
  if (isTRUE(stats::sd(data$log_conc[is.finite(data$log_conc)], na.rm = TRUE) == 0)) {
    attr(ret, "exclude") <- "No point variability in concentrations for half-life calculation"
    # Drop tmax/tlast inputs before returning
    if (!missing(tmax)) ret$tmax <- NULL
    if (!missing(tlast)) ret$tlast <- NULL
    return(ret)
  }

  # ---- Log-linear method ----
  if (!is_tobit) {
    # Data frame to use for computation of half-life
    if (allow.tmax.in.half.life) {
      dfK <- data[as.numeric(data$time) >= as.numeric(ret$tmax), ]
    } else {
      dfK <- data[as.numeric(data$time) > as.numeric(ret$tmax), ]
    }

    if (manually.selected.points) {
      attr(ret, "method") <- "Lambda Z: Manual selection"
      if (nrow(data) > 0) {
        fit <- fit_half_life(data=data, tlast=ret$tlast)
        ret[, ret_replacements] <- fit[, ret_replacements]
        if (ret$half.life <= 0) {
          attr(ret, "exclude") <- "Negative half-life estimated with manually-selected points"
        }
      } else {
        warning("No data to manually fit for half-life (all concentrations may be 0 or excluded)")
        ret <- structure(
          ret,
          exclude = "No data to manually fit for half-life (all concentrations may be 0 or excluded)"
        )
      }
    } else if (nrow(dfK) >= min.hl.points) {
      half_lives_for_selection <-
        data.frame(
          r.squared        = -Inf,
          adj.r.squared    = -Inf,
          clast.pred       = NA_real_,
          lambda.z         = -Inf,
          lambda.z.n.points = NA_integer_,
          lambda.z.time.first = dfK$time,
          lambda.z.time.last  = NA_real_,
          log_conc         = dfK$log_conc,
          span.ratio       = NA_real_,
          half.life        = NA_real_
        )
      half_lives_for_selection <-
        half_lives_for_selection[order(-half_lives_for_selection$lambda.z.time.first), ]
      dfK_for_fit <- data.frame(
        log_conc = half_lives_for_selection$log_conc,
        time     = half_lives_for_selection$lambda.z.time.first
      )
      for (i in min.hl.points:nrow(half_lives_for_selection)) {
        fit <- fit_half_life(data=dfK_for_fit[seq_len(i), , drop=FALSE], tlast=ret$tlast)
        half_lives_for_selection[i, names(fit)] <- fit
      }
      # When min.hl.points == 2 and only 2 points are available, all fits with
      # positive lambda.z are initially selected (TRUE), and the tie-breaking
      # block below then picks the one with the most points — which is the
      # intended behavior in this edge case.
      mask_best <-
        half_lives_for_selection$lambda.z > 0 &
        if (min.hl.points == 2 && nrow(half_lives_for_selection) == 2) {
          rlang::warn(
            message = "2 points used for half-life calculation",
            class = "pknca_halflife_2points"
          )
          TRUE
        } else {
          half_lives_for_selection$adj.r.squared >
            (max(half_lives_for_selection$adj.r.squared, na.rm=TRUE) - adj.r.squared.factor)
        }
      mask_best[is.na(mask_best)] <- FALSE
      if (sum(mask_best) > 1) {
        mask_best <-
          mask_best &
          half_lives_for_selection$lambda.z.n.points ==
            max(half_lives_for_selection$lambda.z.n.points[mask_best])
      }
      if (any(mask_best)) {
        ret[, ret_replacements] <- half_lives_for_selection[mask_best, ret_replacements]
      }
    } else {
      attr(ret, "exclude") <-
        sprintf(
          "Too few points for half-life calculation (min.hl.points=%g with only %g points)",
          min.hl.points, nrow(dfK)
        )
      rlang::warn(
        message = attr(ret, "exclude"),
        class = "pknca_halflife_too_few_points"
      )
    }

  # ---- Tobit method ----
  } else {
    # Data frame for Tobit: all non-NA points after tmax (including BLQ),
    # sorted ascending by time
    if (allow.tmax.in.half.life) {
      dfK_all <- data_tobit[data_tobit$time >= ret$tmax, ]
    } else {
      dfK_all <- data_tobit[data_tobit$time > ret$tmax, ]
    }
    dfK_all <- dfK_all[order(dfK_all$time), ]

    n_above_lloq <- sum(!dfK_all$mask_blq)

    if (manually.selected.points) {
      attr(ret, "method") <- "Lambda Z: Manual selection"
      # Use data_tobit as-is (all non-NA points, no tmax filter applied again)
      if (nrow(data_tobit) > 0) {
        fit <- fit_half_life_tobit(
          data = data_tobit,
          tlast = ret$tlast,
          optim_control = tobit_optim_control
        )
        # Only update if all fit columns are present
        common_cols <- intersect(ret_replacements, names(fit))
        ret[, common_cols] <- fit[, common_cols]
        if (!is.na(ret$half.life) && ret$half.life <= 0) {
          attr(ret, "exclude") <- "Negative half-life estimated with manually-selected points"
        }
      } else {
        warning("No data to manually fit for half-life (all concentrations may be 0 or excluded)")
        ret <- structure(
          ret,
          exclude = "No data to manually fit for half-life (all concentrations may be 0 or excluded)"
        )
      }
    } else if (n_above_lloq >= min.hl.points) {
      # Identify valid starting indices: those leaving >= min.hl.points above-LLOQ
      # points from the start through the end of dfK_all.
      above_lloq_idx <- which(!dfK_all$mask_blq)
      # The last valid starting row is the one at position
      # (n_above_lloq - min.hl.points + 1) in above_lloq_idx
      max_start_row <- above_lloq_idx[n_above_lloq - min.hl.points + 1]
      n_windows <- max_start_row

      tobit_fits <- vector("list", n_windows)
      for (j in seq_len(n_windows)) {
        tobit_fits[[j]] <- fit_half_life_tobit(
          data = dfK_all[j:nrow(dfK_all), , drop = FALSE],
          tlast = ret$tlast,
          optim_control = tobit_optim_control
        )
      }
      all_tobit <- do.call(rbind, tobit_fits)

      # Selection criterion: tobit_residual * n_points ^ penalty
      selection_criterion <-
        all_tobit$tobit_residual *
        (all_tobit$lambda.z.n.points ^ tobit_n_points_penalty)
      valid <- !is.na(all_tobit$lambda.z) & all_tobit$lambda.z > 0
      if (any(valid)) {
        min_crit <- min(selection_criterion[valid], na.rm = TRUE)
        mask_best <- valid & !is.na(selection_criterion) & selection_criterion <= min_crit
        if (sum(mask_best) > 1) {
          # On ties prefer the largest window (smallest j = most total points)
          mask_best <- mask_best &
            all_tobit$lambda.z.n.points == max(all_tobit$lambda.z.n.points[mask_best])
        }
        if (any(mask_best)) {
          common_cols <- intersect(ret_replacements, names(all_tobit))
          ret[, common_cols] <- all_tobit[mask_best, common_cols]
        }
      }
    } else {
      attr(ret, "exclude") <-
        sprintf(
          "Too few above-LLOQ points for Tobit half-life (min.hl.points=%g with only %g above-LLOQ points)",
          min.hl.points, n_above_lloq
        )
      rlang::warn(
        message = attr(ret, "exclude"),
        class = "pknca_halflife_too_few_points"
      )
    }
  }

  # Drop the inputs of tmax and tlast, if given.
  if (!missing(tmax)) ret$tmax <- NULL
  if (!missing(tlast)) ret$tlast <- NULL
  ret
}

#' Perform the half-life fit given the data.  The function simply fits
#' the data without any validation.  No selection of points or any other
#' components are done.
#'
#' @param data The data to fit.  Must have two columns named "log_conc"
#'   and "time"
#' @param tlast The time of last observed concentration above the limit
#'   of quantification.
#' @return A data.frame with one row and columns named "r.squared",
#'   "adj.r.squared", "PROB", "lambda.z", "clast.pred",
#'   "lambda.z.n.points", "half.life", "span.ratio"
#' @seealso [pk.calc.half.life()]
fit_half_life <- function(data, tlast) {
  fit <- stats::.lm.fit(x=cbind(1, data$time), y=data$log_conc)

  # as.numeric is so that it works for units objects
  r_squared <- 1 - as.numeric(sum(fit$residuals^2))/as.numeric(sum((data$log_conc - mean(data$log_conc))^2))
  clast_pred <- exp(sum(fit$coefficients*c(1, as.numeric(tlast))))
  lambda_z <- -fit$coefficients[2]
  ret <-
    data.frame(
      r.squared=r_squared,
      adj.r.squared=adj.r.squared(r_squared, nrow(data)),
      lambda.z.corrxy=if(nrow(data) > 1) stats::cor(data$time, data$log_conc) else NA,
      lambda.z=lambda_z,
      clast.pred=clast_pred,
      lambda.z.time.first=min(data$time, na.rm=TRUE),
      lambda.z.time.last=max(data$time, na.rm=TRUE),
      lambda.z.n.points=nrow(data)
    )
  ret$half.life <- log(2)/ret$lambda.z
  ret$span.ratio <- (max(data$time) - min(data$time))/ret$half.life
  ret
}

#' Negative log-likelihood for Tobit half-life regression
#'
#' Helper function used by `fit_half_life_tobit()` via [stats::optim()].
#' For observations above the LLOQ, the normal density contributes to the
#' likelihood.  For censored (BLQ) observations, the normal CDF up to the
#' LLOQ contributes.
#'
#' @param par A 3-element numeric vector: `c(log_c0, lambda_z, log_resid_error)`
#' @param log_conc Natural log of observed concentration (may be `-Inf` for
#'   BLQ; those values are not used when `mask_blq` is `TRUE`)
#' @param time Numeric time vector
#' @param mask_blq Logical vector; `TRUE` where the observation is below the
#'   LLOQ
#' @param log_lloq Natural log of the lower limit of quantification
#' @return The negative sum of the log-likelihood (a scalar)
#' @seealso `fit_half_life_tobit()`
fit_half_life_tobit_LL <- function(par, log_conc, time, mask_blq, log_lloq) {
  log_c0 <- par[[1]]
  lambda_z <- par[[2]]
  resid_error <- exp(par[[3]])
  est <- log_c0 - lambda_z * time
  ret <- rep(NA_real_, length(time))
  if (any(mask_blq)) {
    ret[mask_blq] <-
      stats::pnorm(
        q = log_lloq[mask_blq],
        mean = est[mask_blq],
        sd = resid_error,
        log.p = TRUE
      )
  }
  ret[!mask_blq] <-
    stats::dnorm(
      x = log_conc[!mask_blq],
      mean = est[!mask_blq],
      sd = resid_error,
      log = TRUE
    )
  -sum(ret)
}

#' Perform a Tobit half-life fit given the data.  The function fits the data
#' using maximum likelihood without any point selection or validation.
#'
#' @param data The data to fit.  Must have columns named `"log_conc"`,
#'   `"time"`, `"log_lloq"`, and `"mask_blq"`.  `log_conc` for BLQ
#'   observations is not used (the likelihood uses `log_lloq` instead).
#' @param tlast The time of last observed concentration above the lower limit
#'   of quantification.
#' @param optim_control A list of control parameters passed to [stats::optim()].
#' @return A data.frame with one row and columns named `"lambda.z"`,
#'   `"clast.pred"`, `"lambda.z.time.first"`, `"lambda.z.time.last"`,
#'   `"lambda.z.n.points"`, `"lambda.z.n.points_blq"`, `"half.life"`,
#'   `"span.ratio"`, `"tobit_residual"`, and `"adj_tobit_residual"`.
#'   Returns `NA` for all columns if [stats::optim()] does not converge,
#'   and emits a warning.
#' @seealso [pk.calc.half.life()], `fit_half_life_tobit_LL()`
fit_half_life_tobit <- function(data, tlast, optim_control = list()) {
  above_lloq_log_conc <- data$log_conc[!data$mask_blq]
  na_ret <- data.frame(
    lambda.z = NA_real_,
    clast.pred = NA_real_,
    lambda.z.time.first = min(data$time, na.rm = TRUE),
    lambda.z.time.last = max(data$time, na.rm = TRUE),
    lambda.z.n.points = nrow(data),
    lambda.z.n.points_blq = sum(data$mask_blq),
    half.life = NA_real_,
    span.ratio = NA_real_,
    tobit_residual = NA_real_,
    adj_tobit_residual = NA_real_
  )
  # Guard: need at least 2 above-LLOQ points for initial parameter estimation
  if (length(above_lloq_log_conc) < 2) {
    rlang::warn(
      message = "Too few above-LLOQ points for Tobit half-life initial parameter estimation",
      class = "pknca_tobit_too_few_points"
    )
    return(na_ret)
  }
  # Guard: all above-LLOQ log-concentrations identical → no fit possible
  sd_above <- stats::sd(above_lloq_log_conc)
  if (!is.finite(sd_above) || sd_above == 0) {
    rlang::warn(
      message = "No variability in above-LLOQ concentrations for Tobit half-life fit",
      class = "pknca_tobit_no_variability"
    )
    return(na_ret)
  }
  init_lambda_z <-
    -log(2) *
    diff(range(above_lloq_log_conc)) /
    diff(range(data$time[!data$mask_blq]))
  # Protect against degenerate time range (all above-LLOQ at same time)
  if (!is.finite(init_lambda_z)) init_lambda_z <- 0.1
  # Merge user control with a higher default maxit to improve convergence
  # on challenging data (e.g. near-exact profiles or many BLQ points).
  effective_control <- c(list(maxit = 2000), optim_control)
  fit <- stats::optim(
    par = c(
      log_c0 = max(above_lloq_log_conc),
      lambda_z = init_lambda_z,
      log_resid_error = log(sd_above / 5)
    ),
    fn = fit_half_life_tobit_LL,
    log_conc = data$log_conc,
    time = as.numeric(data$time),
    mask_blq = data$mask_blq,
    log_lloq = data$log_lloq,
    control = effective_control
  )
  # code 0 = converged; any other code = failure
  if (fit$convergence != 0) {
    rlang::warn(
      message = paste0(
        "Tobit half-life optimization did not converge (code ", fit$convergence, ")"
      ),
      class = "pknca_tobit_no_convergence"
    )
    return(na_ret)
  }
  tobit_residual <- exp(fit$par[["log_resid_error"]])
  # adj_tobit_residual uses only points at or before tlast (analogous to adj.r.squared)
  n_before_tlast <- sum(as.numeric(data$time) <= as.numeric(tlast))
  adj_tobit_residual <-
    if (n_before_tlast > 2) {
      tobit_residual * (n_before_tlast - 2) / (n_before_tlast - 1)
    } else {
      NA_real_
    }
  lambda_z <- fit$par[["lambda_z"]]
  clast_pred <- exp(fit$par[["log_c0"]] - lambda_z * as.numeric(tlast))
  above_lloq_times <- data$time[!data$mask_blq]
  ret <- data.frame(
    lambda.z = lambda_z,
    clast.pred = clast_pred,
    lambda.z.time.first = min(data$time, na.rm = TRUE),
    lambda.z.time.last = max(data$time, na.rm = TRUE),
    lambda.z.n.points = nrow(data),
    lambda.z.n.points_blq = sum(data$mask_blq),
    half.life = log(2) / lambda_z,
    tobit_residual = tobit_residual,
    adj_tobit_residual = adj_tobit_residual
  )
  # span.ratio uses only above-LLOQ time range (same as reference implementation)
  ret$span.ratio <- diff(range(as.numeric(above_lloq_times))) / ret$half.life
  ret
}

# Add the column to the interval specification
add.interval.col("half.life",
                 FUN="pk.calc.half.life",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Half-life",
                 desc="The (terminal) half-life",
                 depends=c("tmax", "tlast"))
PKNCA.set.summary(
  name="half.life",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)
add.interval.col("r.squared",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="unitless",
                 pretty_name="$r^2$",
                 desc="The r^2 value of the half-life calculation",
                 depends="half.life")
PKNCA.set.summary(
  name="r.squared",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)
add.interval.col("adj.r.squared",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="unitless",
                 pretty_name="$r^2_{adj}$",
                 desc="The adjusted r^2 value of the half-life calculation",
                 depends="half.life")
PKNCA.set.summary(
  name="adj.r.squared",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)
add.interval.col("lambda.z.corrxy",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="unitless",
                 pretty_name="Correlation (time, log-conc)",
                 desc="Correlation between time and log-concentration for lambda.z points",
                 depends="half.life")
PKNCA.set.summary(
  name="lambda.z.corrxy",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)
add.interval.col("lambda.z",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="$\\lambda_z$",
                 desc="The elimination rate of the terminal half-life",
                 depends="half.life")
PKNCA.set.summary(
  name="lambda.z",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("lambda.z.time.first",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="First time for $\\lambda_z$",
                 desc="The first time point used for the calculation of half-life",
                 depends="half.life")
PKNCA.set.summary(
  name="lambda.z.time.first",
  description="median and range",
  point=business.median,
  spread=business.range
)
add.interval.col("lambda.z.time.last",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Last time for $\\lambda_z$",
                 desc="The last time point used for the calculation of half-life",
                 depends="half.life")
PKNCA.set.summary(
  name="lambda.z.time.last",
  description="median and range",
  point=business.median,
  spread=business.range
)
add.interval.col("lambda.z.n.points",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="count",
                 pretty_name="Number of points used for lambda_z",
                 desc="The number of points used for the calculation of half-life",
                 depends="half.life")
PKNCA.set.summary(
  name="lambda.z.n.points",
  description="median and range",
  point=business.median,
  spread=business.range
)
add.interval.col("clast.pred",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Clast,pred",
                 desc="The concentration at Tlast as predicted by the half-life",
                 depends="half.life")
PKNCA.set.summary(
  name="clast.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("span.ratio",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Span ratio",
                 desc="The ratio of the half-life to the duration used for half-life calculation",
                 depends="half.life")
PKNCA.set.summary(
  name="span.ratio",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("tobit_residual",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="unitless",
                 pretty_name="Tobit residual SD",
                 desc="The estimated residual standard deviation (on the log-concentration scale) from the Tobit half-life fit",
                 depends="half.life")
PKNCA.set.summary(
  name="tobit_residual",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)
add.interval.col("adj_tobit_residual",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="unitless",
                 pretty_name="Adjusted Tobit residual SD",
                 desc="The adjusted Tobit residual standard deviation (analogous to adjusted r-squared; penalizes smaller windows)",
                 depends="half.life")
PKNCA.set.summary(
  name="adj_tobit_residual",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)
add.interval.col("lambda.z.n.points_blq",
                 FUN=NA,
                 values=c(FALSE, TRUE),
                 unit_type="count",
                 pretty_name="Number of BLQ points for lambda_z (Tobit)",
                 desc="The number of BLQ points included in the Tobit half-life calculation",
                 depends="half.life")
PKNCA.set.summary(
  name="lambda.z.n.points_blq",
  description="median and range",
  point=business.median,
  spread=business.range
)

#' Determine which concentrations were used for half-life calculation
#'
#' @param object A PKNCAresults or PKNCAdata object
#' @returns A logical vector with `TRUE` if the point was used for half-life
#'   (including concentrations below the limit of quantification within the
#'   range of times for calculation), `FALSE` if it was not used for half-life
#'   but the half-life was calculated for the interval, and `NA` if half-life
#'   was not calculated for the interval. If a row is excluded from all
#'   calculations, it is set to `NA` as well.
#' @examples
#' o_conc <- PKNCAconc(Theoph, conc~Time|Subject)
#' o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
#' o_nca <- pk.nca(o_data)
#' get_halflife_points(o_nca)
#' @export
#' 
get_halflife_points <- function(object) {
  UseMethod("get_halflife_points")
}

#' @export
get_halflife_points.PKNCAresults <- function(object) {
  # Insert a ROWID column so that we can reconstruct the order at the end
  rowid_col <- paste0(max(names(as.data.frame(as_PKNCAconc(object)))), "ROWID")
  object$data$conc$data[[rowid_col]] <- seq_len(nrow(object$data$conc$data))

  # Find the concentrations and results that go together
  splitdata <- full_join_PKNCAdata(as_PKNCAdata(object), extra_conc_cols = rowid_col)
  splitresults_prep <- as.data.frame(object)
  splitresults <-
    tidyr::nest(
      splitresults_prep,
      data_results = !c(intersect(names(splitresults_prep), names(splitdata)), "start", "end")
    )
  base_results <-
    dplyr::inner_join(
      splitdata, splitresults,
      by = intersect(names(splitdata), names(splitresults))
    )

  ret <- rep(NA, nrow(as.data.frame(as_PKNCAconc(object))))
  for (idx in seq_len(nrow(base_results))) {
    ret_current <-
      get_halflife_points_single(
        conc = base_results$data_conc[[idx]],
        results = base_results$data_results[[idx]],
        time_start = base_results$start[[idx]],
        time_end = base_results$end[[idx]],
        rowid_col = rowid_col
      )
    if (any(!is.na(ret[ret_current$rowid]))) {
      stop(
        "More than one half-life calculation was attempted on the following rows: ",
        paste(ret_current$rowid, collapse = ", ")
      )
    }
    ret[ret_current$rowid] <- ret_current$hl_used
  }
  ret
}

#' @export
get_halflife_points.PKNCAdata <- function(object) {

  # Keep only intervals with half-life calculations
  hl_dep_cols <- c("half.life" ,get.parameter.deps("half.life"))
  int_to_keep <- rowSums(object$intervals[, hl_dep_cols]) > 0
  object$intervals <- object$intervals[int_to_keep, ]
  object$intervals[, "half.life"] <- TRUE
  params_to_ignore <- setdiff(names(get.interval.cols()), c("half.life", "start", "end"))
  object$intervals[, params_to_ignore] <- FALSE
  object$intervals <- unique(object$intervals)

  # Only calculate half.life for the results object
  o_nca <- pk.nca(object)

  # Get the half-life points from the results object
  get_halflife_points(o_nca)
}

# Get the half-life points for a single interval
get_halflife_points_single <- function(conc, results, time_start, time_end, rowid_col) {
  checkmate::assert_number(time_start, na.ok = FALSE, finite = TRUE, null.ok = FALSE)
  checkmate::assert_number(time_end, na.ok = FALSE, null.ok = FALSE)
  checkmate::assert_true(time_start < time_end)
  # Values for the current group outside of the interval time range are not
  # included in the current half-life calculations.
  conc_included <- conc[conc$time >= time_start & conc$time <= time_end, ]
  ret <- data.frame(hl_used = NA, rowid = conc_included[[rowid_col]])
  if ("half.life" %in% results$PPTESTCD) {
    # "include_half.life" and "exclude_half.life" columns are present in conc, if
    # they apply. That comes from `full_join_PKNCAdata()`
    if ("include_half.life" %in% names(conc_included) && !all(is.na(conc_included$include_half.life))) {
      ret$hl_used <- conc_included$include_half.life %in% TRUE
    } else {
      # Shift the time by time_start to account for the fact that
      # lambda.z.time.first and lambda.z.time.last are relative to the start of the interval
      time_first <- time_start + results$PPORRES[results$PPTESTCD %in% "lambda.z.time.first"]
      time_last <- time_start + results$PPORRES[results$PPTESTCD %in% "lambda.z.time.last"]
      excluded <-
        if ("exclude_half.life" %in% names(conc_included)) {
          conc_included$exclude_half.life %in% TRUE
        } else {
          FALSE
        }
      ret$hl_used <- (time_first <= conc_included$time) & (conc_included$time <= time_last) & !excluded
    }
  }
  ret
}
