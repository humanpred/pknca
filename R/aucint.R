#' Calculate the AUXC (AUC or AUMC) over an interval with interpolation and/or
#' extrapolation of concentrations for the beginning and end of the
#' interval.
#'
#' @details
#' When `pk.calc.auxcint()` needs to extrapolate using `lambda.z` (in other
#' words, using the half-life), it will always extrapolate using the logarithmic
#' trapezoidal rule to align with using a half-life calculation for the
#' extrapolation.
#'
#' @inheritParams pk.calc.auxc
#' @inheritParams assert_intervaltime_single
#' @inheritParams assert_lambdaz
#' @param clast,clast.obs,clast.pred The last concentration above the limit of
#'   quantification; this is used for AUCinf calculations.  If provided as
#'   clast.obs (observed clast value, default), AUCinf is AUCinf,obs. If
#'   provided as clast.pred, AUCinf is AUCinf,pred.
#' @param time.dose,route,duration.dose The time of doses, route of
#'   administration, and duration of dose used with interpolation and
#'   extrapolation of concentration data (see [interp.extrap.conc.dose()]).  If
#'   `NULL`, [interp.extrap.conc()] will be used instead (assuming that no doses
#'   affecting concentrations are in the interval).
#' @param fun_linear,fun_log,fun_inf Integration functions for linear, 
#'   logarithmic, and infinite extrapolation methods.
#' @param ... Additional arguments passed to `pk.calc.auxc` and
#'   `interp.extrap.conc`
#' @family AUC calculations
#' @family AUMC calculations
#' @seealso [PKNCA.options()], [interp.extrap.conc.dose()]
#' @returns The AUXC for an interval of time as a number
#' @export
pk.calc.auxcint <- function(conc, time,
                            interval=NULL, start=NULL, end=NULL,
                            clast=pk.calc.clast.obs(conc, time),
                            lambda.z=NA,
                            time.dose=NULL,
                            route="extravascular",
                            duration.dose=0,
                            auc.type=c("AUClast", "AUCinf", "AUCall"),
                            options=list(),
                            method=NULL,
                            conc.blq=NULL,
                            conc.na=NULL,
                            check=TRUE,
                            fun_linear,
                            fun_log,
                            fun_inf) {
  # Check inputs
  auc.type <- match.arg(auc.type)
  method <- PKNCA.choose.option(name="auc.method", value=method, options=options)
  if (check) {
    assert_conc_time(conc, time)
    data <-
      clean.conc.blq(
        conc = conc, time = time,
        conc.blq = conc.blq, conc.na = conc.na, options = options,
        check = FALSE
      )
  } else {
    data <- data.frame(conc, time)
  }
  if (all(data$conc %in% 0)) {
    return(structure(0, exclude = "DO NOT EXCLUDE"))
  }
  interval <- assert_intervaltime_single(interval = interval, start = start, end = end)
  missing_times <-
    if (is.infinite(interval[2])) {
      setdiff(c(interval[1], time.dose), data$time)
    } else {
      setdiff(c(interval, time.dose), data$time)
    }
  # Handle the potential double-calculation (before/after tlast) with AUCinf/AUMCinf
  conc_clast <- NULL
  time_clast <- NULL
  if (auc.type %in% "AUCinf") {
    tlast <- pk.calc.tlast(conc=data$conc, time=data$time)
    clast_obs <- pk.calc.clast.obs(conc=data$conc, time=data$time)
    if (is.na(clast) && is.na(lambda.z)) {
      # clast.pred is NA likely because the half-life was not calculable
      return(structure(NA_real_, exclude = "clast.pred is NA because the half-life is NA"))
    } else if (is.na(clast)) {
      stop("Please report a bug. clast is NA and the half-life is not NA") # nocov
    } else if (clast != clast_obs & interval[2] > tlast) {
      # If using clast.pred, we need to doubly calculate at tlast.
      conc_clast <- clast
      time_clast <- tlast
    }
  }
  extrap_times <- numeric()
  if (length(missing_times) > 0) {
    if (is.null(time.dose)) {
      missing_conc <-
        interp.extrap.conc(
          conc = data$conc, time = data$time,
          time.out = missing_times,
          method = method,
          auc.type = auc.type,
          clast = clast,
          lambda.z = lambda.z,
          options = options,
          ...
        )
    } else {
      missing_conc <-
        interp.extrap.conc.dose(
          conc = data$conc, time = data$time,
          time.out = missing_times,
          method = method,
          auc.type = auc.type,
          clast = clast, lambda.z = lambda.z,
          options = options,
          # arguments specific to interp.extrap.conc.dose
          time.dose = time.dose,
          route.dose = route,
          duration.dose = duration.dose,
          out.after = FALSE,
          ...
        )
    }
    new_data <- data.frame(conc=c(data$conc, conc_clast, missing_conc),
                           time=c(data$time, time_clast, missing_times))
    tlast <- pk.calc.tlast(conc = data$conc, time = data$time, check = FALSE)
    extrap_times <- missing_times[missing_times > tlast]
    new_data <- new_data[new_data$time >= interval[1] &
                           new_data$time <= interval[2],]
    new_data <- new_data[order(new_data$time),]
    conc_interp <- new_data$conc
    time_interp <- new_data$time
    if (any(mask_na_conc <- is.na(conc_interp))) {
      missing_times <- time_interp[mask_na_conc]
      warning_message <-
        if (any(is.na(lambda.z))) {
          paste("Some interpolated/extrapolated concentration values are missing",
                "(may be due to interpolating or extrapolating over a dose with lambda.z=NA).",
                "Time points with missing data are: ",
                paste(missing_times, collapse=", "))
        } else {
          paste("Some interpolated/extrapolated concentration values are missing",
                "Time points with missing data are: ",
                paste(missing_times, collapse=", "))
        }
      warning(warning_message)
      return(NA_real_)
    }
  } else {
    mask_time <- data$time >= interval[1] & data$time <= interval[2]
    conc_interp <- data$conc[mask_time]
    time_interp <- data$time[mask_time]
  }
  
  interval_method <-
    choose_interval_method(
      conc = conc_interp,
      time = time_interp,
      tlast = max(time_interp),
      method = method,
      auc.type = auc.type,
      options = options
    )
  if (is.finite(interval[2])) {
    interval_method[length(interval_method)] <- "zero"
  }
  if (length(extrap_times) > 0) {
    interval_method[which(time_interp == extrap_times) - 1] <- "log"
  }
  ret <-
    auc_integrate(
      conc = conc_interp, time = time_interp,
      clast = clast, tlast = tlast, lambda.z = lambda.z,
      interval_method = interval_method,
      fun_linear = fun_linear,
      fun_log = fun_log,
      fun_inf = fun_inf
    )
  ret
}

#' Calculate the AUC over an interval with interpolation and/or
#' extrapolation of concentrations for the beginning and end of the
#' interval.
#'
#' @details
#' When `pk.calc.aucint()` needs to extrapolate using `lambda.z` (in other
#' words, using the half-life), it will always extrapolate using the logarithmic
#' trapezoidal rule to align with using a half-life calculation for the
#' extrapolation.
#'
#' @inheritParams pk.calc.auxcint
#' @family AUC calculations
#' @seealso [PKNCA.options()], [interp.extrap.conc.dose()]
#' @returns The AUC for an interval of time as a number
#' @export
pk.calc.aucint <- function(conc, time, ..., options=list()) {
  pk.calc.auxcint(
    conc = conc, time = time, ...,
    options = options,
    fun_linear = aucintegrate_linear,
    fun_log = aucintegrate_log,
    fun_inf = aucintegrate_inf
  )
}

#' @describeIn pk.calc.aucint Interpolate or extrapolate concentrations for
#'   AUClast
#' @export
pk.calc.aucint.last <- function(conc, time, start=NULL, end=NULL, time.dose, ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aucint(conc=conc, time=time,
                 start=start, end=end,
                 options=options,
                 time.dose=time.dose,
                 ...,
                 auc.type="AUClast")
}
#' @describeIn pk.calc.aucint Interpolate or extrapolate concentrations for
#'   AUCall
#' @export
pk.calc.aucint.all <- function(conc, time, start=NULL, end=NULL, time.dose, ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aucint(conc=conc, time=time,
                 start=start, end=end,
                 options=options,
                 time.dose=time.dose,
                 ...,
                 auc.type="AUCall")
}
#' @describeIn pk.calc.aucint Interpolate or extrapolate concentrations for
#'   AUCinf.obs
#' @export
pk.calc.aucint.inf.obs <- function(conc, time, start=NULL, end=NULL, time.dose, lambda.z, clast.obs, ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aucint(conc=conc, time=time,
                 start=start, end=end,
                 time.dose=time.dose,
                 lambda.z=lambda.z, clast=clast.obs,
                 options=options, ...,
                 auc.type="AUCinf")
}
#' @describeIn pk.calc.aucint Interpolate or extrapolate concentrations for
#'   AUCinf.pred
#' @export
pk.calc.aucint.inf.pred <- function(conc, time, start=NULL, end=NULL, time.dose, lambda.z, clast.pred, ..., options=list()) {
  if (missing(time.dose)) {
    time.dose <- NULL
  }
  pk.calc.aucint(conc=conc, time=time,
                 start=start, end=end,
                 time.dose=time.dose,
                 lambda.z=lambda.z, clast=clast.pred,
                 options=options, ...,
                 auc.type="AUCinf")
}

add.interval.col("aucint.last",
                 FUN="pk.calc.aucint.last",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUClast extrapolation)",
                 desc="The area under the concentration time curve in the interval extrapolating from Tlast to infinity with zeros (matching AUClast)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose=NULL))

add.interval.col("aucint.last.dose",
                 FUN="pk.calc.aucint.last",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUClast extrapolation, dose-aware)",
                 desc="The area under the concentration time curve in the interval extrapolating from Tlast to infinity with zeros (matching AUClast) with dose-aware interpolation/extrapolation of concentrations",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group"))

add.interval.col("aucint.all",
                 FUN="pk.calc.aucint.all",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUCall extrapolation)",
                 desc="The area under the concentration time curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUCall)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose=NULL))

add.interval.col("aucint.all.dose",
                 FUN="pk.calc.aucint.all",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUCall extrapolation, dose-aware)",
                 desc="The area under the concentration time curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUCall) with dose-aware interpolation/extrapolation of concentrations",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group"))

add.interval.col("aucint.inf.obs",
                 FUN="pk.calc.aucint.inf.obs",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUCinf,obs extrapolation)",
                 desc="The area under the concentration time curve in the interval extrapolating from Tlast to infinity with zeros (matching AUClast)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose=NULL),
                 depends=c("lambda.z", "clast.obs"))

add.interval.col("aucint.inf.obs.dose",
                 FUN="pk.calc.aucint.inf.obs",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUCinf,obs extrapolation, dose-aware)",
                 desc="The area under the concentration time curve in the interval extrapolating from Tlast to infinity with zeros (matching AUClast) with dose-aware interpolation/extrapolation of concentrations",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group"),
                 depends=c("lambda.z", "clast.obs"))

add.interval.col("aucint.inf.pred",
                 FUN="pk.calc.aucint.inf.pred",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUCinf,pred extrapolation)",
                 desc="The area under the concentration time curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUCall)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose=NULL),
                 depends=c("lambda.z", "clast.pred"))

add.interval.col("aucint.inf.pred.dose",
                 FUN="pk.calc.aucint.inf.pred",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUCinf,pred extrapolation, dose-aware)",
                 desc="The area under the concentration time curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUCall) with dose-aware interpolation/extrapolation of concentrations",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group"),
                 depends=c("lambda.z", "clast.pred"))

PKNCA.set.summary(
  name= c(
    "aucint.last", "aucint.last.dose", "aucint.all", "aucint.all.dose",
    "aucint.inf.obs", "aucint.inf.obs.dose", "aucint.inf.pred", "aucint.inf.pred.dose"
  ),
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)


#' Calculate the AUMC over an interval with interpolation and/or
#' extrapolation of concentrations for the beginning and end of the
#' interval.
#'
#' @details
#' When `pk.calc.aumcint()` needs to extrapolate using `lambda.z` (in other
#' words, using the half-life), it will always extrapolate using the logarithmic
#' trapezoidal rule to align with using a half-life calculation for the
#' extrapolation.
#'
#' @inheritParams pk.calc.auxcint
#' @family AUMC calculations
#' @returns The AUMC for an interval of time as a number
#' @export
pk.calc.aumcint <- function(conc, time, ..., options=list()) {
  pk.calc.auxcint(
    conc = conc, time = time, ...,
    options = options,
    fun_linear = aumcintegrate_linear,
    fun_log = aumcintegrate_log,
    fun_inf = aumcintegrate_inf
  )
}

#' @describeIn pk.calc.aumcint Interpolate or extrapolate concentrations for
#'   AUMClast
#' @export
pk.calc.aumcint.last <- function(conc, time, start=NULL, end=NULL, time.dose, ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aumcint(conc=conc, time=time,
                  start=start, end=end,
                  options=options,
                  time.dose=time.dose,
                  ...,
                  auc.type="AUClast")
}

#' @describeIn pk.calc.aumcint Interpolate or extrapolate concentrations for
#'   AUMCall
#' @export
pk.calc.aumcint.all <- function(conc, time, start=NULL, end=NULL, time.dose, ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aumcint(conc=conc, time=time,
                  start=start, end=end,
                  options=options,
                  time.dose=time.dose,
                  ...,
                  auc.type="AUCall")
}

#' @describeIn pk.calc.aumcint Interpolate or extrapolate concentrations for
#'   AUMCinf.obs
#' @export
pk.calc.aumcint.inf.obs <- function(conc, time, start=NULL, end=NULL, time.dose, lambda.z, clast.obs, ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aumcint(conc=conc, time=time,
                  start=start, end=end,
                  time.dose=time.dose,
                  lambda.z=lambda.z, clast=clast.obs,
                  options=options, ...,
                  auc.type="AUCinf")
}

#' @describeIn pk.calc.aumcint Interpolate or extrapolate concentrations for
#'   AUMCinf.pred
#' @export
pk.calc.aumcint.inf.pred <- function(conc, time, start=NULL, end=NULL, time.dose, lambda.z, clast.pred, ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aumcint(conc=conc, time=time,
                  start=start, end=end,
                  time.dose=time.dose,
                  lambda.z=lambda.z, clast=clast.pred,
                  options=options, ...,
                  auc.type="AUCinf")
}


# aumcint.last (without dose awareness)
add.interval.col("aumcint.last",
                 FUN="pk.calc.aumcint.last",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMClast extrapolation)",
                 desc="The area under the moment curve in the interval extrapolating from Tlast to infinity with zeros (matching AUMClast)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose=NULL))

# aumcint.last.dose (WITH dose awareness)
add.interval.col("aumcint.last.dose",
                 FUN="pk.calc.aumcint.last",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMClast extrapolation, dose-aware)",
                 desc="The area under the moment curve in the interval extrapolating from Tlast to infinity with zeros (matching AUMClast) with dose-aware interpolation/extrapolation of concentrations",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group"))

# aumcint.all (without dose awareness)
add.interval.col("aumcint.all",
                 FUN="pk.calc.aumcint.all",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMCall extrapolation)",
                 desc="The area under the moment curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUMCall)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose=NULL))

# aumcint.all.dose (WITH dose awareness)
add.interval.col("aumcint.all.dose",
                 FUN="pk.calc.aumcint.all",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMCall extrapolation, dose-aware)",
                 desc="The area under the moment curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUMCall) with dose-aware interpolation/extrapolation of concentrations",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group"))

# aumcint.inf.obs (without dose awareness)
add.interval.col("aumcint.inf.obs",
                 FUN="pk.calc.aumcint.inf.obs",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMCinf,obs extrapolation)",
                 desc="The area under the moment curve in the interval extrapolating from Tlast to infinity with zeros (matching AUMClast)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose=NULL),
                 depends=c("lambda.z", "clast.obs"))

# aumcint.inf.obs.dose (WITH dose awareness)
add.interval.col("aumcint.inf.obs.dose",
                 FUN="pk.calc.aumcint.inf.obs",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMCinf,obs extrapolation, dose-aware)",
                 desc="The area under the moment curve in the interval extrapolating from Tlast to infinity with zeros (matching AUMClast) with dose-aware interpolation/extrapolation of concentrations",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group"),
                 depends=c("lambda.z", "clast.obs"))

# aumcint.inf.pred (without dose awareness)
add.interval.col("aumcint.inf.pred",
                 FUN="pk.calc.aumcint.inf.pred",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMCinf,pred extrapolation)",
                 desc="The area under the moment curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUMCall)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose=NULL),
                 depends=c("lambda.z", "clast.pred"))

# aumcint.inf.pred.dose (WITH dose awareness)
add.interval.col("aumcint.inf.pred.dose",
                 FUN="pk.calc.aumcint.inf.pred",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMCinf,pred extrapolation, dose-aware)",
                 desc="The area under the moment curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUMCall) with dose-aware interpolation/extrapolation of concentrations",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group"),
                 depends=c("lambda.z", "clast.pred"))

PKNCA.set.summary(
  name = c(
    "aumcint.last", "aumcint.last.dose",
    "aumcint.all",  "aumcint.all.dose",
    "aumcint.inf.obs", "aumcint.inf.obs.dose",
    "aumcint.inf.pred", "aumcint.inf.pred.dose"
  ),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)