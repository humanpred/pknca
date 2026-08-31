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
      rlang::abort("lloq must be provided when hl_method is 'tobit'", class = "pknca_error_lloq_required_tobit")
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
        ret[, ret_replacements] <- fit[ret_replacements]
        if (ret$half.life <= 0) {
          attr(ret, "exclude") <- "Negative half-life estimated with manually-selected points"
        }
      } else {
        rlang::warn(
          "No data to manually fit for half-life (all concentrations may be 0 or excluded)",
          class = "pknca_warning_no_halflife_data"
        )
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
          rlang::warn("2 points used for half-life calculation", class = "pknca_warning_halflife_2points")
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
      } else {
        # A well-fitting span with lambda.z <= 0 can anchor the adjusted
        # r-squared tolerance so that no span with lambda.z > 0 is within it.
        attr(ret, "exclude") <-
          "No valid terminal phase: no span with lambda.z > 0 within the adjusted r-squared tolerance of the best fit"
      }
    } else {
      attr(ret, "exclude") <-
        sprintf(
          "Too few points for half-life calculation (min.hl.points=%g with only %g points)",
          min.hl.points, nrow(dfK)
        )
      rlang::warn(attr(ret, "exclude"), class = "pknca_warning_halflife_too_few_points")
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
        rlang::warn(
          "No data to manually fit for half-life (all concentrations may be 0 or excluded)",
          class = "pknca_warning_no_halflife_data_tobit"
        )
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
      } else {
        # No span with a positive elimination rate (or no converged fit)
        attr(ret, "exclude") <-
          "No valid terminal phase: no Tobit span with lambda.z > 0"
      }
    } else {
      attr(ret, "exclude") <-
        sprintf(
          "Too few above-LLOQ points for Tobit half-life (min.hl.points=%g with only %g above-LLOQ points)",
          min.hl.points, n_above_lloq
        )
      rlang::warn(attr(ret, "exclude"), class = "pknca_warning_halflife_too_few_points_tobit")
    }
  }

  # Drop the inputs of tmax and tlast, if given.
  if (!missing(tmax)) ret$tmax <- NULL
  if (!missing(tlast)) ret$tlast <- NULL
  ret
}

pknca_concept(pk.calc.half.life) <- "half_life"

#' Perform the half-life fit given the data.  The function simply fits
#' the data without any validation.  No selection of points or any other
#' components are done.
#'
#' @param data The data to fit.  Must have two columns named "log_conc"
#'   and "time"
#' @param tlast The time of last observed concentration above the limit
#'   of quantification.
#' @return A named list with one value each for "r.squared", "adj.r.squared",
#'   "lambda.z.corrxy", "lambda.z", "clast.pred", "lambda.z.time.first",
#'   "lambda.z.time.last", "lambda.z.n.points", "half.life", and "span.ratio".
#'   [pk.calc.half.life()] fits one candidate per span of terminal points and
#'   builds a data.frame from the candidate it selects.
#' @seealso [pk.calc.half.life()]
fit_half_life <- function(data, tlast) {
  fit <- stats::.lm.fit(x=cbind(1, data$time), y=data$log_conc)

  # as.numeric is so that it works for units objects
  r_squared <- 1 - as.numeric(sum(fit$residuals^2))/as.numeric(sum((data$log_conc - mean(data$log_conc))^2))
  clast_pred <- exp(sum(fit$coefficients*c(1, as.numeric(tlast))))
  lambda_z <- -fit$coefficients[2]
  half_life <- log(2)/lambda_z
  list(
    r.squared=r_squared,
    adj.r.squared=adj.r.squared(r_squared, nrow(data)),
    lambda.z.corrxy=if(nrow(data) > 1) stats::cor(data$time, data$log_conc) else NA_real_,
    lambda.z=lambda_z,
    clast.pred=clast_pred,
    lambda.z.time.first=min(data$time, na.rm=TRUE),
    lambda.z.time.last=max(data$time, na.rm=TRUE),
    lambda.z.n.points=nrow(data),
    half.life=half_life,
    span.ratio=(max(data$time) - min(data$time))/half_life
  )
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
      "Too few above-LLOQ points for Tobit half-life initial parameter estimation",
      class = "pknca_warning_tobit_too_few_points"
    )
    return(na_ret)
  }
  # Guard: all above-LLOQ log-concentrations identical → no fit possible
  sd_above <- stats::sd(above_lloq_log_conc)
  if (!is.finite(sd_above) || sd_above == 0) {
    rlang::warn(
      "No variability in above-LLOQ concentrations for Tobit half-life fit",
      class = "pknca_warning_tobit_no_variability"
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
      sprintf("Tobit half-life optimization did not converge (code %s)", fit$convergence),
      class = "pknca_warning_tobit_no_convergence"
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
                 depends=c("tmax", "tlast"),
                 pptestcd_cdisc="LAMZHL",
                 pptest_cdisc="Half-Life Lambda z",
                 formula="$t_{1/2} = \\frac{\\ln(2)}{\\lambda_z}$",
                 tier = "common")
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
                 desc="R-squared of half-life fit",
                 depends="half.life",
                 pptestcd_cdisc="R2",
                 pptest_cdisc="R Squared",
                 formula="$r^2 = 1 - \\frac{\\sum_{i \\in \\lambda_z} (y_i - \\hat{y}_i)^2}{\\sum_{i \\in \\lambda_z} (y_i - \\bar{y})^2}$", formula_note="Regression of $y = \\log C$ on time over the terminal points")
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
                 desc="Adjusted R-sq of half-life fit",
                 depends="half.life",
                 pptestcd_cdisc="R2ADJ",
                 pptest_cdisc="R Squared Adjusted",
                 formula="$r^2_{adj} = 1 - (1 - r^2) \\frac{n-1}{n-2}$")
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
                 desc="Corr(time,log-conc) for lambda.z",
                 depends="half.life",
                 pptestcd_cdisc="CORRXY",
                 pptest_cdisc="Correlation Between TimeX and Log ConcY",
                 formula="$r_{t,\\log C} = \\text{cor}(t_{\\lambda_z}, \\log C_{\\lambda_z})$")
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
                 desc="Terminal elim rate (lambda.z)",
                 depends="half.life",
                 pptestcd_cdisc="LAMZ",
                 pptest_cdisc="Lambda z",
                 formula="$\\lambda_z = -\\text{slope of } \\log(C) \\text{ vs } t$")
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
                 desc="First time point for lambda.z",
                 depends="half.life",
                 pptestcd_cdisc="LAMZLL",
                 pptest_cdisc="Lambda z Lower Limit",
                 formula="$\\lambda_z t_{\\text{first}} = \\min\\left(t_{\\lambda_z}\\right)$")
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
                 desc="Last time point for lambda.z",
                 depends="half.life",
                 pptestcd_cdisc="LAMZUL",
                 pptest_cdisc="Lambda z Upper Limit",
                 formula="$\\lambda_z t_{\\text{last}} = \\max\\left(t_{\\lambda_z}\\right)$")
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
                 desc="Number of points used, lambda.z",
                 depends="half.life",
                 pptestcd_cdisc="LAMZNPT",
                 pptest_cdisc="Number of Points for Lambda z",
                 formula="$n_{\\lambda_z} = \\left| t_{\\lambda_z} \\right|$")
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
                 desc="Predicted Clast from half-life",
                 depends="half.life",
                 pptestcd_cdisc="CLSTP",
                 pptest_cdisc="Clast pred",
                 formula="$C_{\\text{last,pred}} = e^{\\text{intercept} - \\lambda_z \\cdot t_{\\text{last}}}$",
                 selection = list(concept = "last_conc"))
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
                 desc="Lambda z time span to half-life ratio",
                 depends="half.life",
                 pptestcd_cdisc="LAMZSPN",
                 pptest_cdisc="Lambda z Span",
                 formula="$\\text{span ratio} = \\frac{t_{\\lambda_z,\\text{last}} - t_{\\lambda_z,\\text{first}}}{t_{1/2}}$")
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
                 desc="Tobit fit residual SD, log-conc",
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
                 desc="Adjusted Tobit residual SD",
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
                 desc="BLQ points in Tobit lambda.z",
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
      rlang::abort(
        sprintf(
          "More than one half-life calculation was attempted on the following rows: %s",
          paste(ret_current$rowid, collapse = ", ")
        ),
        class = "pknca_error_duplicate_halflife_rows"
      )
    }
    ret[ret_current$rowid] <- ret_current$hl_used
  }
  ret
}

#' @export
get_halflife_points.PKNCAdata <- function(object) {
  get_halflife_points(pk.nca(halflife_only_PKNCAdata(object)))
}

# Reduce a PKNCAdata object to calculating only half-life, and only for the
# intervals where half-life (or a parameter depending on it) was requested.
halflife_only_PKNCAdata <- function(object) {
  hl_dep_cols <- c("half.life" ,get.parameter.deps("half.life"))
  int_to_keep <- rowSums(object$intervals[, hl_dep_cols]) > 0
  object$intervals <- object$intervals[int_to_keep, ]
  object$intervals[, "half.life"] <- TRUE
  params_to_ignore <- setdiff(names(get.interval.cols()), c("half.life", "start", "end"))
  object$intervals[, params_to_ignore] <- FALSE
  object$intervals <- unique(object$intervals)
  object
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

#' Get the half-life fit line for each interval
#'
#' The half-life fit is the log-linear regression of concentration on time,
#' `log(conc) = intercept + slope*time`.  Concentrations along the line are
#' `exp(intercept + slope*time)`.
#'
#' Times in a `PKNCAresults` object are relative to the start of the interval,
#' but `time_first`, `time_last`, and the time scale of `intercept` are on the
#' same scale as the times in the concentration data so that the line can be
#' drawn with the observed concentrations.
#'
#' @inheritParams get_halflife_points
#' @returns A data.frame with one row for each group and interval where
#'   half-life was calculated.  Along with the grouping columns and the interval
#'   `start` and `end` times, it has the columns:
#'
#'   * `intercept`: the natural log of the concentration where the line crosses
#'     time 0
#'   * `slope`: the slope of the line, `-lambda.z`
#'   * `time_first`, `time_last`: the first and last times of the concentrations
#'     used for the fit
#'
#'   `intercept` and `slope` are `NA` when the half-life could not be
#'   calculated or was excluded.
#' @seealso [get_halflife_points()] to see which concentrations were used for
#'   the fit
#' @examples
#' o_conc <- PKNCAconc(Theoph, conc~Time|Subject)
#' o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
#' o_nca <- pk.nca(o_data)
#' get_halflife_fit(o_nca)
#' @export
get_halflife_fit <- function(object) {
  UseMethod("get_halflife_fit")
}

#' @export
get_halflife_fit.PKNCAdata <- function(object) {
  get_halflife_fit(pk.nca(halflife_only_PKNCAdata(object)))
}

#' @export
get_halflife_fit.PKNCAresults <- function(object) {
  # clast.pred is the fitted concentration at tlast, so it is on the line
  # whether or not tlast was one of the points used for the fit.
  fit_params <-
    c("lambda.z", "clast.pred", "tlast", "lambda.z.time.first", "lambda.z.time.last")
  results <- as.data.frame(object)
  results <- results[results$PPTESTCD %in% fit_params, , drop = FALSE]
  if (nrow(results) == 0) {
    rlang::abort(
      "No half-life results are available to make a fit",
      class = "pknca_error_no_halflife_fit"
    )
  }
  # Excluded values cannot contribute to a fit
  exclude_col <- object$columns$exclude
  if (!is.null(exclude_col) && exclude_col %in% names(results)) {
    results$PPORRES[!is.na(results[[exclude_col]])] <- NA_real_
  }
  # PPORRES is used (rather than PPSTRES) so that the fit is on the same scale
  # as the concentration and time data.
  group_cols <-
    setdiff(
      names(results),
      c("PPTESTCD", "PPORRES", "PPSTRES", "PPORRESU", "PPSTRESU", "PPANMETH", exclude_col)
    )
  ret <-
    tidyr::pivot_wider(
      results,
      id_cols = dplyr::all_of(group_cols),
      names_from = "PPTESTCD",
      values_from = "PPORRES"
    )
  missing_params <- setdiff(fit_params, names(ret))
  if (length(missing_params) > 0) {
    rlang::abort(
      sprintf(
        "Half-life fit requires the following missing parameters: %s",
        paste(missing_params, collapse = ", ")
      ),
      class = "pknca_error_no_halflife_fit"
    )
  }

  # Results times are relative to the start of the interval; shift them to the
  # times in the concentration data.
  ret$slope <- -ret$lambda.z
  ret$intercept <- log(ret$clast.pred) + ret$lambda.z*(ret$tlast + ret$start)
  ret$time_first <- ret$start + ret$lambda.z.time.first
  ret$time_last <- ret$start + ret$lambda.z.time.last
  # A partial fit is not usable, so give all or nothing
  no_fit <- is.na(ret$intercept) | is.na(ret$slope)
  ret[no_fit, c("intercept", "slope", "time_first", "time_last")] <- NA_real_

  as.data.frame(ret[, c(group_cols, "intercept", "slope", "time_first", "time_last")])
}

#' Interpolate and extrapolate concentrations along the half-life fit
#'
#' Concentrations are given as concentrations, not log-concentrations.  Take the
#' natural log of `conc` if the log-concentration is wanted.
#'
#' Like [stats::approx()], give either `tout` for specific times or `n` for
#' equally-spaced times.  With `n`, the times span the concentrations used for
#' the fit (`time_first` to `time_last` from [get_halflife_fit()]), so `tout` is
#' required to extrapolate.
#'
#' @inheritParams get_halflife_points
#' @param tout Times for output.  The same times are used for every group and
#'   interval.  If `NULL` (the default), `n` equally-spaced times spanning the
#'   concentrations used for the fit are used instead.
#' @param n The number of equally-spaced times to generate when `tout` is
#'   `NULL`.  It is ignored when `tout` is given.
#' @param extrapolate_earlier,extrapolate_later Should concentrations be
#'   extrapolated before the first (`extrapolate_earlier`) or after the last
#'   (`extrapolate_later`) concentration used for the fit?  Times outside the
#'   fit that are not extrapolated give an `NA` concentration.
#' @returns A data.frame with the grouping columns, the interval `start` and
#'   `end` times, and the columns:
#'
#'   * `time`: the time of the concentration, on the same scale as the times in
#'     the concentration data
#'   * `conc`: the concentration on the half-life fit at that time
#'
#'   `conc` is `NA` where the half-life could not be calculated or was excluded,
#'   and where extrapolation was requested but not allowed.  Groups without a
#'   fit give a single row with an `NA` `time` when `tout` is `NULL`, since no
#'   times can be generated for them.
#' @seealso [get_halflife_fit()] for the slope and intercept of the fit, and
#'   [get_halflife_points()] for the concentrations used for it
#' @examples
#' o_conc <- PKNCAconc(Theoph, conc~Time|Subject)
#' o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
#' o_nca <- pk.nca(o_data)
#' # Equally-spaced times across the fit
#' head(get_halflife_curve(o_nca))
#' # Specific times, extrapolating past the last concentration used
#' get_halflife_curve(o_nca, tout = c(12, 24, 36))
#' @export
get_halflife_curve <- function(object, tout = NULL, n = 50,
                               extrapolate_earlier = FALSE, extrapolate_later = TRUE) {
  checkmate::assert_numeric(tout, any.missing = FALSE, min.len = 1, null.ok = TRUE)
  checkmate::assert_count(n, positive = TRUE)
  checkmate::assert_flag(extrapolate_earlier)
  checkmate::assert_flag(extrapolate_later)
  fit <- get_halflife_fit(object)
  # A group column named time or conc cannot reach here; standardize_column_names()
  # rejects it when the PKNCAdata object is made.
  group_cols <-
    setdiff(names(fit), c("intercept", "slope", "time_first", "time_last"))
  curves <-
    lapply(
      X = seq_len(nrow(fit)),
      FUN = halflife_curve_single,
      fit = fit,
      tout = tout,
      n = n,
      extrapolate_earlier = extrapolate_earlier,
      extrapolate_later = extrapolate_later
    )
  curves <- do.call(rbind, curves)
  ret <-
    cbind(
      fit[curves$idx, group_cols, drop = FALSE],
      curves[, c("time", "conc"), drop = FALSE]
    )
  rownames(ret) <- NULL
  ret
}

# Generate the concentrations along the half-life fit for one row of the fit
halflife_curve_single <- function(idx, fit, tout, n, extrapolate_earlier, extrapolate_later) {
  time_first <- fit$time_first[idx]
  time_last <- fit$time_last[idx]
  time_current <-
    if (!is.null(tout)) {
      tout
    } else if (is.na(time_first)) {
      # Without a fit there is no time range to span
      NA_real_
    } else {
      seq(from = time_first, to = time_last, length.out = n)
    }
  conc <- exp(fit$intercept[idx] + fit$slope[idx]*time_current)
  # %in% TRUE keeps an NA time or an NA fit out of the subscript
  if (!extrapolate_earlier) {
    conc[(time_current < time_first) %in% TRUE] <- NA_real_
  }
  if (!extrapolate_later) {
    conc[(time_current > time_last) %in% TRUE] <- NA_real_
  }
  data.frame(idx = idx, time = time_current, conc = conc)
}
