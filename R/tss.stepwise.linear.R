#' Compute the time to steady state using stepwise test of linear trend
#'
#' A linear slope is fit through the data to find when it becomes
#' non-significant.  Note that this is less preferred than the
#' `pk.tss.monoexponential` due to the fact that with more time or more subjects
#' the performance of the test changes (see reference).
#'
#' The model is fit with a different magnitude by treatment (as a factor, if
#' given) and a random slope by subject (if given).  A minimum of `min.points`
#' is required to fit the model.
#'
#' @param \dots See [pk.tss.data.prep()]
#' @param check See [pk.tss.data.prep()]
#' @param min.points The minimum number of points required for the fit
#' @param level The confidence level required for assessment of steady-state
#' @param verbose Describe models as they are run, show convergence of the model
#'   (passed to the nlme function), and additional details while running.
#' @returns A scalar float for the first time when steady-state is achieved or
#'   `NA` if it is not observed.
#' @family Time to steady-state calculations
#' @references Maganti L, Panebianco DL, Maes AL.  Evaluation of Methods for
#' Estimating Time to Steady State with Examples from Phase 1 Studies. AAPS
#' Journal 10(1):141-7. doi:10.1208/s12248-008-9014-y
#' @export
pk.tss.stepwise.linear <- function(...,
                                   min.points=3, level=0.95, verbose=FALSE,
                                   check=TRUE) {
  # Check inputs
  modeldata <- pk.tss.data.prep(..., check=check)
  if (!length(min.points) == 1) {
    rlang::warn(
      message = "Only first value of min.points is used",
      class = "pknca_warning_min_points_length"
    )
    min.points <- min.points[1]
  }
  
  checkmate::assert_number(min.points, lower = 3)
  
  if (!length(level) == 1) {
    rlang::warn(
      message = "Only first value of level is being used",
      class = "pknca_warning_tss_level_multiple"
    )
    level <- level[1]
  }
  
  checkmate::assert_numeric(level, any.missing = FALSE)
  
  if (level <= 0 || level >= 1){
    rlang::abort(
      message = "level must be between 0 and 1, exclusive",
      class = "pknca_error_tss_level_range"
    )  }
  
  # Confirm that we may have sufficient data to complete the
  # modeling.  Because of the variety of methods used for estimating
  # time to steady-state, assurance that we have enough data is more
  # simply determined by model convergence.
  if (length(unique(modeldata$time)) < min.points) {
    rlang::warn(
      message = "After removing non-dosing time points, insufficient data remains for tss calculation",
      class = "pknca_warning_tss_insufficient_data"
    )
    return(NA)
  }
  # Assign treatment if given and with multiple levels
  formula.to.fit <- stats::as.formula("conc~time")
  if ("treatment" %in% names(modeldata))
    formula.to.fit <- stats::as.formula("conc~time+treatment")
  # Ensure that the dosing times are in order to allow us to kick
  # them out in order.
  remaining.time <- sort(unique(modeldata$time))
  ret <- NA
  while (is.na(ret) &
         (length(remaining.time) >= min.points)) {
    if (verbose) {
      rlang::inform(
        message = paste("Trying", min(remaining.time, na.rm = TRUE)),
        class = "pknca_message_tss_trying_time"
      )
    }
    try({
      # Try to make the model
      current.interval <-
        if ("subject" %in% names(modeldata)) {
          # If we have a subject column, try to fit a linear
          # mixed-effects model.
          current.model <-
            nlme::lme(
              formula.to.fit,
              random=~time|subject,
              data=modeldata[modeldata$time >= min(remaining.time),,drop=FALSE])
          nlme::intervals(current.model, level=level, which="fixed")$fixed["time",]
        } else {
          # If we do not have a subject column, fit a linear model.
          current.model <-
            stats::glm(
              formula.to.fit,
              data=modeldata[modeldata$time >= min(remaining.time),,drop=FALSE])
          # There is no intervals function for glm, so build one
          ci <- as.vector(stats::confint(current.model, "time", level=level))
          c(ci[1], stats::coef(current.model)[["time"]], ci[2])
        }
      if (verbose) {
        rlang::inform(
          message = sprintf(
            "Current interval %g [%g, %g]",
            current.interval[2],
            current.interval[1],
            current.interval[3]
          ),
          class = "pknca_message_tss_interval"
        )
      }
      # If the signs of the upper and lower bounds of the slope of
      # the confidence interval for time are different, then we have
      # a non-significant slope.  A non-significant slope indicates steady-state.
      if (sign(current.interval[1]) != sign(current.interval[3]))
        ret <- min(remaining.time, na.rm=TRUE)
    }, silent=!verbose)
    remaining.time <- remaining.time[-1]
  }
  data.frame(
    tss.stepwise.linear=ret,
    stringsAsFactors=FALSE
  )
}
