#' Calculate AUXC (AUC or AUMC) over an interval with interpolation/extrapolation
#'
#' Calculates AUC or AUMC over a given interval, optionally interpolating or
#' extrapolating concentrations.
#'
#' @details
#' # Doses bound the profile
#'
#' When dose times are given, the profile being integrated ends at the first
#' dose at or after `end`:  a concentration measured after that dose belongs to
#' a later profile and is neither integrated nor used for
#' interpolation/extrapolation into this interval.  A dose within the interval
#' does not end the profile -- the interval asks for the profiles on both sides
#' of it to be integrated together -- but it does become a point to integrate
#' to, so that the profile ending at the dose is not interpolated into the one
#' starting at it.  Concentrations from before the interval are used to estimate
#' the concentration at `start`, and that estimate does not interpolate across a
#' dose either (see [interp.extrap.conc.dose()]).
#'
#' # The region after Tlast
#'
#' Each dose within the interval starts a new profile, and the region of each
#' profile after its last measurable concentration is handled the same way as
#' the matching AUC parameter, so that an interval spanning several doses gives
#' the sum of the intervals covering each of them:
#'
#' \describe{
#'   \item{`AUClast`}{contributes zero.}
#'   \item{`AUCall`}{contributes the triangle from `clast` to the first
#'     below-the-limit-of-quantification measurement and zero after that.}
#'   \item{`AUCinf`}{is extrapolated with `lambda.z` (in other words, with the
#'     half-life), always using the logarithmic trapezoidal rule to align with
#'     the exponential decay that the half-life describes.  When `lambda.z` is
#'     not estimable and the interval is finite, `AUCall` is used instead.}
#' }
#'
#' When the interval ends at or before Tlast, no extrapolation happens and
#' `lambda.z` is not used at all.  The extrapolation that was used is reported
#' in the method (`PPANMETH`) column.
#'
#' @inheritParams pk.calc.auxc
#' @inheritParams assert_intervaltime_single
#' @inheritParams assert_lambdaz
#' @param clast,clast.obs,clast.pred The last concentration above the limit of
#'   quantification; this is used for AUCinf calculations. If provided as
#'   `clast.obs` (observed clast value, default), AUCinf is AUCinf,obs. If
#'   provided as `clast.pred`, AUCinf is AUCinf,pred.
#' @param time.dose,route,duration.dose The time of doses, route of
#'   administration, and duration of dose used with interpolation and
#'   extrapolation of concentration data (see [interp.extrap.conc.dose()]).
#'   If `NULL` or if every `time.dose` is `NA` (an analysis with no dosing
#'   data), [interp.extrap.conc()] is used instead and the calculation is not
#'   dose-aware.  If only some `time.dose` values are `NA`, the result is `NA`
#'   because that dose cannot be placed on the timeline.
#' @param fun_linear,fun_log,fun_inf Integration functions for linear,
#'   logarithmic, and infinite extrapolation methods.
#' @param ... Additional arguments passed to `pk.calc.auxc` and
#'   `interp.extrap.conc`
#'
#' @return The AUXC for an interval of time as a number
#'
#' @family AUC calculations
#' @family AUMC calculations
#' @seealso [PKNCA.options()], [interp.extrap.conc.dose()]
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
                            fun_inf,
                            ...) {
  # Check inputs
  auc.type <- match.arg(auc.type)
  method <- PKNCA.choose.option(name="auc.method", value=method, options=options)
  if (!is.null(time.dose) && all(is.na(time.dose))) {
    # No dose time is known at all, which is what an analysis without dosing
    # data gives, so the calculation simply is not dose-aware.
    time.dose <- NULL
  } else if (anyNA(time.dose)) {
    # Dose-aware interpolation cannot place a dose at an unknown time, and the
    # unknown time must not become a point to interpolate to.
    rlang::warn("time.dose is NA", class = "pknca_warning_timedose_na")
    return(structure(NA_real_, exclude = "dose time is missing"))
  }
  dose_aware <- !is.null(time.dose)
  if (check) {
    assert_conc_time(conc, time)
  }
  interval <- assert_intervaltime_single(interval = interval, start = start, end = end)
  if (dose_aware) {
    # A concentration measured after the dose that follows the interval belongs
    # to a later profile, so it is neither integrated nor interpolated or
    # extrapolated into this interval (#508).  Dropping it here is also what
    # makes Tlast the Tlast of the profile being integrated, which is what
    # says whether the interval reaches past it.
    #
    # The dose that starts the interval is not a bound in the same way:  the
    # concentration at the start of the interval is estimated from the profile
    # before it, which interp.extrap.conc.dose() does without interpolating
    # across the dose.
    window_end <- dose_window_end(time.dose = time.dose, interval = interval)
    mask_conc <- time <= window_end
    conc <- conc[mask_conc]
    time <- time[mask_conc]
    mask_dose <- time.dose <= window_end
    if (length(route) == length(time.dose)) {
      route <- route[mask_dose]
    }
    if (length(duration.dose) == length(time.dose)) {
      duration.dose <- duration.dose[mask_dose]
    }
    time.dose <- time.dose[mask_dose]
  }
  if (length(conc) == 0) {
    return(structure(NA_real_, exclude = "no concentration data before the dose after the interval"))
  }
  if (check) {
    data <-
      clean_conc_blq_by_profile(
        conc = conc, time = time, time.dose = time.dose,
        conc.blq = conc.blq, conc.na = conc.na, options = options
      )
  } else {
    data <- data.frame(conc, time)
  }
  if (all(data$conc %in% 0)) {
    return(structure(0, exclude = "DO NOT EXCLUDE"))
  }
  tlast <- pk.calc.tlast(conc = data$conc, time = data$time, check = FALSE)
  # Does the interval reach past the last measurable concentration?  That region
  # is the only one where the type of extrapolation, and with it lambda.z, can
  # matter.
  extrapolates <- is.infinite(interval[2]) || interval[2] > tlast
  auc_type_calc <- auc.type
  lambda_z_used <- FALSE
  if (auc.type %in% "AUCinf") {
    if (!extrapolates) {
      # The interval is interpolated throughout, so the half-life never enters
      # the result and neither does an exclusion of it (#270).  AUClast and
      # AUCinf integrate identically when nothing after tlast is in the
      # interval.
      auc_type_calc <- "AUClast"
    } else if (is.na(lambda.z)) {
      if (is.infinite(interval[2])) {
        # Without a half-life there is no finite tail to fall back to
        return(structure(NA_real_, exclude = "the half-life is NA"))
      }
      # With no estimable half-life, the tail of the interval is the AUCall
      # triangle instead (#508)
      auc_type_calc <- "AUCall"
    } else {
      lambda_z_used <- TRUE
    }
  }
  if (auc_type_calc %in% "AUCinf") {
    # After tlast the half-life describes the profile, so the measurements there
    # (all below the limit of quantification) are replaced by the extrapolated
    # concentrations, the same way pk.calc.auxc() ignores everything after tlast
    # for AUCinf.
    data <- data[data$time <= tlast, , drop = FALSE]
  }
  extrap_method <-
    if (!extrapolates) {
      "none"
    } else if (lambda_z_used) {
      pknca_extrap_method_halflife
    } else if (auc.type %in% "AUCinf") {
      "AUCall (half-life not estimable)"
    } else {
      auc.type
    }
  # The ends of the interval, and each dose within it, become points to
  # integrate to.  The dose is a point of its own because the concentration
  # before it belongs to the profile that is ending: without it, a pre-dose gap
  # would be filled by interpolating from before the dose to after it.
  time_dose_interp <-
    if (dose_aware) {
      time.dose[interval[1] <= time.dose & time.dose <= interval[2]]
    } else {
      NULL
    }
  missing_times <-
    if (is.infinite(interval[2])) {
      setdiff(c(interval[1], time_dose_interp), data$time)
    } else {
      setdiff(c(interval, time_dose_interp), data$time)
    }
  # Handle the potential double-calculation (before/after tlast) with AUCinf/AUMCinf
  conc_clast <- NULL
  time_clast <- NULL
  if (auc_type_calc %in% "AUCinf") {
    clast_obs <- pk.calc.clast.obs(conc=data$conc, time=data$time)
    all_times <- c(data$time, missing_times)
    time_after_tlast <- all_times[all_times > tlast & all_times <= interval[2]]
    if (is.na(clast)) {
      rlang::abort("Please report a bug. clast is NA and the half-life is not NA", class = "pknca_error_internal_clast_na")  # nocov
    } else if (clast != clast_obs && length(time_after_tlast) > 0) {
      # If using clast.pred, the integration is done twice at tlast: once with
      # clast.obs to end the observed data and once with clast.pred to start the
      # extrapolation.  That duplicate only changes the result when a later
      # point in the interval is integrated to from clast.pred.  Extrapolation
      # past the end of the interval is analytic from clast and tlast, so a
      # trailing duplicate would only add a zero-width interval that makes tlast
      # ambiguous in choose_interval_method().
      conc_clast <- clast
      time_clast <- tlast
    }
  }
  extrap_times <- numeric()
  if (length(missing_times) > 0) {
    if (!dose_aware) {
      missing_conc <-
        interp.extrap.conc(
          conc = data$conc, time = data$time,
          time.out = missing_times,
          method = method,
          auc.type = auc_type_calc,
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
          auc.type = auc_type_calc,
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
      rlang::warn(warning_message, class = "pknca_warning_missing_interpolated_concentrations")
      return(NA_real_)
    }
  } else {
    mask_time <- data$time >= interval[1] & data$time <= interval[2]
    conc_interp <- data$conc[mask_time]
    time_interp <- data$time[mask_time]
  }

  interval_method <-
    interval_method_by_profile(
      conc = conc_interp,
      time = time_interp,
      time.dose = time_dose_interp,
      lambda_z_used = lambda_z_used,
      method = method,
      auc.type = auc_type_calc,
      options = options
    )
  if (is.finite(interval[2])) {
    interval_method[length(interval_method)] <- "zero"
  }
  if (lambda_z_used && length(extrap_times) > 0) {
    interval_method[which(time_interp %in% extrap_times) - 1] <- "log"
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
  # Add method details as an attribute
  attr(ret, "method") <-
    c(
      paste0("AUC: ", method),
      paste0(
        pknca_interp_method_prefix,
        if (dose_aware) "dose-aware" else "not dose-aware (no dosing data)"
      ),
      paste0(pknca_extrap_method_prefix, extrap_method)
    )
  if (auc.type %in% "AUCinf" && !lambda_z_used) {
    # The half-life did not enter the result, so an exclusion of the half-life
    # (or of clast.pred, which comes from it) does not apply to it (#270).
    attr(ret, "exclude") <- "DO NOT EXCLUDE"
  }

  ret
}

# How pk.calc.auxcint() names, in the method (PPANMETH) column, whether it knew
# the dose times (#539) and how it handled the interval after Tlast.  The
# half-life exclusions in exclude_nca.R read the extrapolation text to tell an
# AUCint that used the half-life from one that only interpolated (#270), so
# these are named once here.
pknca_interp_method_prefix <- "Interpolation: "
pknca_extrap_method_prefix <- "Extrapolation: "
pknca_extrap_method_halflife <- "half-life"

# The first dose at or after the end of the interval, which is where the profile
# being integrated ends; `Inf` when there is no such dose.  A dose within the
# interval does not end it, because the interval asks for the profiles on both
# sides of that dose to be integrated together.  A concentration measured at the
# same time as a dose is taken to be measured before it, matching
# interp.extrap.conc.dose().
dose_window_end <- function(time.dose, interval) {
  dose_after <- time.dose[time.dose >= interval[2]]
  if (length(dose_after) > 0) min(dose_after) else Inf
}

# Which dosing interval each time belongs to.  A concentration measured at the
# same time as a dose is taken to be measured before it, matching
# interp.extrap.conc.dose(), so `left.open = TRUE` puts it with the profile that
# ends at the dose.
profile_of_time <- function(time, time.dose) {
  findInterval(
    x = time,
    vec = if (is.null(time.dose)) numeric() else sort(unique(time.dose)),
    left.open = TRUE
  )
}

# Clean the concentrations one dosing interval at a time, so that a value below
# the limit of quantification which trails its own profile is treated as
# trailing rather than as a middle value of the data as a whole.  Cleaning
# everything at once would drop it (the default for a middle value), and the
# AUCall triangle of that profile would then be drawn to the next dose instead
# of to it.
clean_conc_blq_by_profile <- function(conc, time, time.dose, conc.blq, conc.na, options) {
  profile <- profile_of_time(time = time, time.dose = time.dose)
  ret <- list()
  for (current in sort(unique(profile))) {
    mask <- profile == current
    ret[[length(ret) + 1L]] <-
      clean.conc.blq(
        conc = conc[mask], time = time[mask],
        conc.blq = conc.blq, conc.na = conc.na, options = options,
        check = FALSE
      )
  }
  do.call(rbind, ret)
}

# The Tlast that an AU(M)C is integrated against: the last measurable
# concentration, or the end of the data when the half-life described everything
# after it (and when nothing is measurable, where choose_interval_method()
# integrates zero but still wants a number).
tlast_for_integration <- function(conc, time, lambda_z_used) {
  ret <-
    if (lambda_z_used) {
      max(time)
    } else {
      pk.calc.tlast(conc = conc, time = time, check = FALSE)
    }
  if (is.na(ret)) max(time) else ret
}

# How to integrate each pair of concentrations, chosen one profile at a time.
#
# Each dose within the interval ends one profile and starts the next, and how
# the region after a profile's Tlast is integrated is part of what the AUC type
# means:  AUClast leaves it out, AUCall draws its triangle within it.  Choosing
# the method once against a single Tlast for the whole interval would instead
# integrate the area under a concentration extrapolated down to the dose, which
# is exactly the area that AUClast leaves out, and it would make an AUC over
# several dosing intervals differ from the sum of the AUCs over each of them.
#
# Only the last profile extrapolates past the end of the data, so each earlier
# profile contributes its integration methods without its extrapolation.
interval_method_by_profile <- function(conc, time, time.dose, lambda_z_used, method, auc.type, options) {
  # A time that appears twice is the duplicate at Tlast that AUCinf,pred adds
  # (clast.obs to end the observed data and clast.pred to start the
  # extrapolation).  Both points end the same profile, and splitting between
  # them would leave choose_interval_method() with an ambiguous Tlast.
  time_once <- time[!(duplicated(time) | duplicated(time, fromLast = TRUE))]
  # A dose at either end of the data does not split it
  split_time <-
    sort(unique(time.dose[time.dose %in% time_once &
                            time.dose > time[1] &
                            time.dose < time[length(time)]]))
  idx_split <- c(1L, match(split_time, time), length(time))
  n_profile <- length(idx_split) - 1L
  ret <- character()
  for (i in seq_len(n_profile)) {
    idx <- idx_split[i]:idx_split[i + 1]
    is_last <- i == n_profile
    profile_method <-
      choose_interval_method(
        conc = conc[idx],
        time = time[idx],
        tlast =
          tlast_for_integration(
            conc = conc[idx], time = time[idx],
            lambda_z_used = lambda_z_used && is_last
          ),
        method = method,
        auc.type = auc.type,
        options = options
      )
    if (!is_last) {
      profile_method <- profile_method[-length(profile_method)]
    }
    ret <- c(ret, profile_method)
  }
  ret
}

#' @describeIn pk.calc.auxcint Calculate AUC over an interval
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

#' @describeIn pk.calc.auxcint Interpolate or extrapolate concentrations for
#'   AUClast
#' @export
pk.calc.aucint.last <- function(conc, time, start=NULL, end=NULL, time.dose,
                                route="extravascular", duration.dose=0,
                                ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aucint(conc=conc, time=time,
                 start=start, end=end,
                 options=options,
                 time.dose=time.dose,
                 route=route, duration.dose=duration.dose,
                 ...,
                 auc.type="AUClast")
}

pknca_concept(pk.calc.aucint.last) <- "auc"
#' @describeIn pk.calc.auxcint Interpolate or extrapolate concentrations for
#'   AUCall
#' @export
pk.calc.aucint.all <- function(conc, time, start=NULL, end=NULL, time.dose,
                               route="extravascular", duration.dose=0,
                               ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aucint(conc=conc, time=time,
                 start=start, end=end,
                 options=options,
                 time.dose=time.dose,
                 route=route, duration.dose=duration.dose,
                 ...,
                 auc.type="AUCall")
}

pknca_concept(pk.calc.aucint.all) <- "auc"
#' @describeIn pk.calc.auxcint Interpolate or extrapolate concentrations for
#'   AUCinf.obs
#' @export
pk.calc.aucint.inf.obs <- function(conc, time, start=NULL, end=NULL, time.dose, lambda.z, clast.obs,
                                   route="extravascular", duration.dose=0,
                                   ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aucint(conc=conc, time=time,
                 start=start, end=end,
                 time.dose=time.dose,
                 route=route, duration.dose=duration.dose,
                 lambda.z=lambda.z, clast=clast.obs,
                 options=options, ...,
                 auc.type="AUCinf")
}

pknca_concept(pk.calc.aucint.inf.obs) <- "auc"
#' @describeIn pk.calc.auxcint Interpolate or extrapolate concentrations for
#'   AUCinf.pred
#' @export
pk.calc.aucint.inf.pred <- function(conc, time, start=NULL, end=NULL, time.dose, lambda.z, clast.pred,
                                    route="extravascular", duration.dose=0,
                                    ..., options=list()) {
  if (missing(time.dose)) {
    time.dose <- NULL
  }
  pk.calc.aucint(conc=conc, time=time,
                 start=start, end=end,
                 time.dose=time.dose,
                 route=route, duration.dose=duration.dose,
                 lambda.z=lambda.z, clast=clast.pred,
                 options=options, ...,
                 auc.type="AUCinf")
}

pknca_concept(pk.calc.aucint.inf.pred) <- "auc"

add.interval.col("aucint.last",
                 FUN="pk.calc.aucint.last",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUClast extrapolation)",
                 desc="AUC from T1 to T2 (zero extrap)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group",
                                 route="route.group", duration.dose="duration.dose.group"),
                 pptestcd_cdisc="AUCINT",
                 pptest_cdisc="AUC from T1 to T2",
                 formula="$AUC_{\\text{int,last}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$",
                 formula_note="Trapezoidal rule with interpolation at interval boundaries",
                 tier = "common")

add.interval.col("aucint.all",
                 FUN="pk.calc.aucint.all",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUCall extrapolation)",
                 desc="AUC from T1 to T2 (AUCall extrap)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group",
                                 route="route.group", duration.dose="duration.dose.group"),
                 pptestcd_cdisc="AUCINTA",
                 pptest_cdisc="AUCint (based on AUCall extrapolation)",
                 formula="$AUC_{\\text{int,all}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$",
                 formula_note="Trapezoidal rule with interpolation at interval boundaries")

add.interval.col("aucint.inf.obs",
                 FUN="pk.calc.aucint.inf.obs",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUCinf,obs extrapolation)",
                 desc="AUC from T1 to T2 (AUCinf,obs extrap)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group",
                                 route="route.group", duration.dose="duration.dose.group"),
                 depends=c("lambda.z", "clast.obs"),
                 pptestcd_cdisc="AUCINTIS",
                 pptest_cdisc="AUCint (based on AUCinf,obs extrapolation)",
                 formula="$AUC_{\\text{int,}\\infty\\text{,obs}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$",
                 formula_note="Trapezoidal rule with interpolation at interval boundaries",
                 tier = "common")

add.interval.col("aucint.inf.pred",
                 FUN="pk.calc.aucint.inf.pred",
                 values=c(FALSE, TRUE),
                 unit_type="auc",
                 pretty_name="AUCint (based on AUCinf,pred extrapolation)",
                 desc="AUC from T1 to T2 (AUCinf,pred extrap)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group",
                                 route="route.group", duration.dose="duration.dose.group"),
                 depends=c("lambda.z", "clast.pred"),
                 pptestcd_cdisc="AUCINTIP",
                 pptest_cdisc="AUCint (based on AUCinf,pred extrapolation)",
                 formula="$AUC_{\\text{int,}\\infty\\text{,pred}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$",
                 formula_note="Trapezoidal rule with interpolation at interval boundaries")

#' @describeIn pk.calc.auxcint Calculate AUMC over an interval
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

#' @describeIn pk.calc.auxcint Interpolate or extrapolate concentrations for
#'   AUMClast
#' @export
pk.calc.aumcint.last <- function(conc, time, start=NULL, end=NULL, time.dose,
                                 route="extravascular", duration.dose=0,
                                 ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aumcint(conc=conc, time=time,
                  start=start, end=end,
                  options=options,
                  time.dose=time.dose,
                  route=route, duration.dose=duration.dose,
                  ...,
                  auc.type="AUClast")
}

pknca_concept(pk.calc.aumcint.last) <- "aumc"

#' @describeIn pk.calc.auxcint Interpolate or extrapolate concentrations for
#'   AUMCall
#' @export
pk.calc.aumcint.all <- function(conc, time, start=NULL, end=NULL, time.dose,
                                route="extravascular", duration.dose=0,
                                ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aumcint(conc=conc, time=time,
                  start=start, end=end,
                  options=options,
                  time.dose=time.dose,
                  route=route, duration.dose=duration.dose,
                  ...,
                  auc.type="AUCall")
}

pknca_concept(pk.calc.aumcint.all) <- "aumc"

#' @describeIn pk.calc.auxcint Interpolate or extrapolate concentrations for
#'   AUMCinf.obs
#' @export
pk.calc.aumcint.inf.obs <- function(conc, time, start=NULL, end=NULL, time.dose, lambda.z, clast.obs,
                                    route="extravascular", duration.dose=0,
                                    ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aumcint(conc=conc, time=time,
                  start=start, end=end,
                  time.dose=time.dose,
                  route=route, duration.dose=duration.dose,
                  lambda.z=lambda.z, clast=clast.obs,
                  options=options, ...,
                  auc.type="AUCinf")
}

pknca_concept(pk.calc.aumcint.inf.obs) <- "aumc"

#' @describeIn pk.calc.auxcint Interpolate or extrapolate concentrations for
#'   AUMCinf.pred
#' @export
pk.calc.aumcint.inf.pred <- function(conc, time, start=NULL, end=NULL, time.dose, lambda.z, clast.pred,
                                     route="extravascular", duration.dose=0,
                                     ..., options=list()) {
  if (missing(time.dose))
    time.dose <- NULL
  pk.calc.aumcint(conc=conc, time=time,
                  start=start, end=end,
                  time.dose=time.dose,
                  route=route, duration.dose=duration.dose,
                  lambda.z=lambda.z, clast=clast.pred,
                  options=options, ...,
                  auc.type="AUCinf")
}

pknca_concept(pk.calc.aumcint.inf.pred) <- "aumc"


add.interval.col("aumcint.last",
                 FUN="pk.calc.aumcint.last",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMClast extrapolation)",
                 desc="AUMC from T1 to T2 (zero extrap)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group",
                                 route="route.group", duration.dose="duration.dose.group"),
                 formula="$AUMC_{\\text{int,last}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$",
                 formula_note="Trapezoidal rule with interpolation at interval boundaries")

add.interval.col("aumcint.all",
                 FUN="pk.calc.aumcint.all",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMCall extrapolation)",
                 desc="AUMC from T1 to T2 (AUMCall extrap)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group",
                                 route="route.group", duration.dose="duration.dose.group"),
                 formula="$AUMC_{\\text{int,all}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$",
                 formula_note="Trapezoidal rule with interpolation at interval boundaries")

add.interval.col("aumcint.inf.obs",
                 FUN="pk.calc.aumcint.inf.obs",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMCinf,obs extrapolation)",
                 desc="AUMC from T1 to T2 (AUMCinf,obs extrap)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group",
                                 route="route.group", duration.dose="duration.dose.group"),
                 depends=c("lambda.z", "clast.obs"),
                 formula="$AUMC_{\\text{int,}\\infty\\text{,obs}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$",
                 formula_note="Trapezoidal rule with interpolation at interval boundaries")

add.interval.col("aumcint.inf.pred",
                 FUN="pk.calc.aumcint.inf.pred",
                 values=c(FALSE, TRUE),
                 unit_type="aumc",
                 pretty_name="AUMCint (based on AUMCinf,pred extrapolation)",
                 desc="AUMC from T1 to T2 (AUMCinf,pred extrap)",
                 formalsmap=list(conc="conc.group", time="time.group", time.dose="time.dose.group",
                                 route="route.group", duration.dose="duration.dose.group"),
                 depends=c("lambda.z", "clast.pred"),
                 formula="$AUMC_{\\text{int,}\\infty\\text{,pred}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$",
                 formula_note="Trapezoidal rule with interpolation at interval boundaries")

# =============================================================================
# SET SUMMARY STATISTICS - Count (8)
# =============================================================================
PKNCA.set.summary(
  name= c(
    # AUC related
    "aucint.last", "aucint.all", "aucint.inf.obs", "aucint.inf.pred",

    # AUMC related
    "aumcint.last", "aumcint.all", "aumcint.inf.obs", "aumcint.inf.pred"
  ), 
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
