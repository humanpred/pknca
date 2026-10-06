#' Is a time vector a date-time (POSIXct) or a date (Date)?
#'
#' @param x The time vector to test
#' @returns `TRUE` for POSIXct and Date vectors, `FALSE` otherwise
#' @keywords Internal
#' @noRd
is_datetime_date <- function(x) {
  inherits(x, c("POSIXct", "Date"))
}

#' Check and choose the time unit for a date-time time column
#'
#' Date-times have no numeric unit of their own, so they are converted directly
#' to the unit used for calculations and reports:  `timeu_pref` when given
#' (it takes precedence over `timeu`), otherwise `timeu`, otherwise hours.  A
#' Date column is 08:00 on that date, and the user is told so.
#'
#' @param time The time vector from the data
#' @param timeu,timeu_pref The `timeu` and `timeu_pref` arguments given to
#'   [PKNCAconc()]
#' @param time_col The name of the time column (for messages)
#' @param data The concentration data (to reject a column name as `timeu`)
#' @returns `timeu`, set to `timeu_pref` when that was given.  When neither was
#'   given, it stays `NULL`, and the time is in hours without units.
#' @keywords Internal
#' @noRd
pknca_datetime_timeu <- function(time, timeu, timeu_pref, time_col, data) {
  if (!is_datetime_date(time)) {
    return(timeu)
  }
  if (inherits(time, "Date")) {
    pknca_warn_date_time(time_col = time_col, data_type = "concentration")
  }
  if (!is.null(timeu_pref)) {
    timeu <- timeu_pref
  }
  if (!is.null(timeu)) {
    if (!is.character(timeu) || length(timeu) != 1 || is.na(timeu) || timeu %in% names(data)) {
      rlang::abort(
        sprintf(
          "When the time column ('%s') is a date-time (POSIXct) or Date, `timeu` and `timeu_pref` must be a single time unit (not a column name).",
          time_col
        ),
        class = "pknca_error_datetime_timeu"
      )
    }
    if (is.na(pknca_hours_factor(timeu))) {
      rlang::abort(
        sprintf(
          "The time unit for the date-time column ('%s') must be a time unit (like \"hr\" or \"day\"), not '%s'.",
          time_col, timeu
        ),
        class = "pknca_error_datetime_time_unit"
      )
    }
  }
  timeu
}

#' Get duration values to check
#'
#' A difftime duration is checked by its length in seconds; it becomes a number
#' in the time unit of the analysis in [PKNCAdata()].
#'
#' @param x The duration values
#' @returns `x` as a number
#' @keywords Internal
#' @noRd
pknca_duration_check_values <- function(x) {
  if (inherits(x, "difftime")) {
    as.numeric(x, units = "secs")
  } else {
    x
  }
}

#' Find the number of hours in a time unit
#'
#' @param unit A time unit string
#' @returns The number of hours in one `unit` (1 for `"hr"`), or `NA_real_`
#'   when the units package does not recognize `unit` as a time unit
#' @keywords Internal
#' @noRd
pknca_hours_factor <- function(unit) {
  if (identical(as.character(unit), "hr")) {
    return(1)
  }
  rlang::check_installed("units", reason = "to convert times to units other than hours")
  tryCatch(
    pknca_units_conversion_factor(from = unit, to = "hr"),
    error = function(e) NA_real_
  )
}

#' Convert a difftime to a number in a time unit
#'
#' `pknca_difftime_to_unit()` expresses a duration in the time unit of an
#' analysis, such as a collection duration that is the difference of two
#' date-times, so that it can be used with `PKNCAconc()` and `PKNCAdose()`
#' times and durations given in that unit.  The same conversion turns
#' date-times and `difftime` durations into numbers in [pk.nca()].
#'
#' A `difftime` of any of its units (seconds, minutes, hours, days, or weeks)
#' is converted exactly, through seconds.  `unit` may be any time unit that the
#' units package knows, such as `"hr"`, `"min"`, `"day"`, or `"week"`.  Hours
#' (`"hr"`) need no conversion, so they work without the units package;
#' every other unit needs the units package installed, which stops with an
#' error from rlang if it is missing.
#'
#' To convert a number that is not a `difftime`, say its unit first with
#' [base::as.difftime()].
#'
#' @param x A `difftime` vector (`NA` values stay `NA`, and a zero-length
#'   vector gives a zero-length result)
#' @param unit The time unit to express `x` in, a single string such as
#'   `"hr"` or `"day"`
#' @returns A numeric vector the length of `x`: the duration in `unit`, with no
#'   unit or other attributes
#' @section Errors:
#' An `x` that is not a `difftime` stops with the class
#' `pknca_error_difftime_not_difftime`, because a plain number has no unit to
#' convert from.  A `unit` that is not a single string, or that is not a time
#' unit the units package can convert hours to, stops with the class
#' `pknca_error_difftime_unit`.
#' @examples
#' # Hours need no conversion beyond the difftime's own unit
#' pknca_difftime_to_unit(as.difftime(90, units = "mins"), unit = "hr")
#' @examplesIf requireNamespace("units", quietly = TRUE)
#' # Any other unit needs the units package
#' pknca_difftime_to_unit(as.difftime(36, units = "hours"), unit = "day")
#' # The difference of two date-times
#' start <- as.POSIXct("2026-10-05 08:00:00", tz = "UTC")
#' end <- as.POSIXct("2026-10-05 20:30:00", tz = "UTC")
#' pknca_difftime_to_unit(difftime(end, start), unit = "min")
#' @export
pknca_difftime_to_unit <- function(x, unit) {
  if (!inherits(x, "difftime")) {
    rlang::abort(
      sprintf(
        "`x` must be a difftime, not %s; use as.difftime() to give a number its unit.",
        paste(class(x), collapse = "/")
      ),
      class = "pknca_error_difftime_not_difftime"
    )
  }
  if (!is.character(unit) || length(unit) != 1 || is.na(unit)) {
    rlang::abort(
      "`unit` must be a single time unit string, like \"hr\" or \"day\".",
      class = "pknca_error_difftime_unit"
    )
  }
  hours_factor <- pknca_hours_factor(unit)
  if (is.na(hours_factor)) {
    rlang::abort(
      sprintf("`unit` must be a time unit (like \"hr\" or \"day\"), not '%s'.", unit),
      class = "pknca_error_difftime_unit"
    )
  }
  as.numeric(x, units = "secs") / (3600 * hours_factor)
}

pknca_warn_date_time <- function(time_col, data_type) {
  rlang::warn(
    sprintf(
      "The %s time column ('%s') is a Date; each time is taken as 08:00 on that date.",
      data_type, time_col
    ),
    class = "pknca_warning_date_assumed_time"
  )
}

#' Get the time zone of a date-time vector
#'
#' @param x A POSIXct or Date vector
#' @returns The `tzone` attribute of a POSIXct vector (`""` for the session time
#'   zone), or `NA_character_` for a Date (which has no time zone)
#' @keywords Internal
#' @noRd
pknca_datetime_tz <- function(x) {
  if (inherits(x, "Date")) {
    NA_character_
  } else {
    tz <- attr(x, "tzone", exact = TRUE)
    if (is.null(tz)) "" else tz[1]
  }
}

#' Convert a date-time or Date vector to POSIXct in a time zone
#'
#' @param x A POSIXct or Date vector
#' @param tz The time zone for a Date's 08:00
#' @returns A POSIXct vector
#' @keywords Internal
#' @noRd
pknca_as_posixct <- function(x, tz) {
  if (inherits(x, "Date")) {
    # 08:00 is the usual time of a first PK sample when only the date is known.
    # It is 08:00 in the time zone of the analysis (not UTC 08:00, which is a
    # different instant for any other time zone).
    as.POSIXct(paste(format(x, "%Y-%m-%d"), "08:00:00"), tz = tz, format = "%Y-%m-%d %H:%M:%S")
  } else {
    x
  }
}

#' Get and check the date-time concentration and dose times
#'
#' Concentration and dose times must both be numeric or both be date-times, and
#' date-times must share a time zone:  the instant of a POSIXct value does not
#' depend on its time zone, but the report of the reference (PPRFTDTC) and the
#' 08:00 of a Date do.
#'
#' @param data A PKNCAdata object
#' @returns A list with `is_datetime` (`FALSE` for numeric times) and, for
#'   date-times, `conc_time` and `dose_time` (POSIXct; `dose_time` is `NULL`
#'   without dose times) and `tz`
#' @keywords Internal
#' @noRd
pknca_datetime_times <- function(data) {
  o_conc <- as_PKNCAconc(data)
  o_dose <- as_PKNCAdose(data)
  conc_time_col <- o_conc$columns$time
  conc_time <- as.data.frame(o_conc)[[conc_time_col]]
  has_dose_time <- !identical(o_dose, NA) && length(o_dose$columns$time) == 1
  dose_time_col <- if (has_dose_time) o_dose$columns$time else NA_character_
  dose_time <- if (has_dose_time) as.data.frame(o_dose)[[dose_time_col]]
  conc_is_dt <- is_datetime_date(conc_time)
  dose_is_dt <- has_dose_time && is_datetime_date(dose_time)
  if (!conc_is_dt && !dose_is_dt) {
    return(list(is_datetime = FALSE))
  }
  if (has_dose_time && conc_is_dt != dose_is_dt) {
    rlang::abort(
      sprintf(
        "Concentration and dose times must both be numeric or both be date-times (POSIXct or Date).  The concentration time ('%s') is %s and the dose time ('%s') is %s.",
        conc_time_col, class(conc_time)[1],
        dose_time_col, class(dose_time)[1]
      ),
      class = "pknca_error_datetime_mixed"
    )
  }
  tz_all <- c(pknca_datetime_tz(conc_time), if (has_dose_time) pknca_datetime_tz(dose_time))
  tz_known <- unique(tz_all[!is.na(tz_all)])
  if (length(tz_known) > 1) {
    rlang::abort(
      sprintf(
        "Concentration and dose date-times must have the same time zone (UTC offset); the time zones are: %s",
        paste0("'", tz_known, "'", collapse = ", ")
      ),
      class = "pknca_error_datetime_mixed_tz"
    )
  }
  tz <- if (length(tz_known) == 0) "UTC" else tz_known
  list(
    is_datetime = TRUE,
    conc_time = pknca_as_posixct(conc_time, tz = tz),
    dose_time = if (has_dose_time) pknca_as_posixct(dose_time, tz = tz),
    tz = tz
  )
}

#' Replace the data within a PKNCAconc or PKNCAdose object
#'
#' @param object A PKNCAconc or PKNCAdose object
#' @param value The new data.frame
#' @returns `object` with `value` as its data
#' @keywords Internal
#' @noRd
pknca_replace_data <- function(object, value) {
  object[[getDataName(object)]] <- value
  object
}

#' Convert date-time and difftime inputs of a PKNCAdata object to numbers
#'
#' Date-time concentration and dose times become numeric times relative to the
#' time reference of each group (see `pknca_datetime_reference()`), in the time
#' unit of the concentration data (see `pknca_datetime_timeu()`), or hours when
#' there are no units; difftime durations become numbers in the same unit; and
#' date-time interval bounds become numeric times relative to the same
#' references (see `pknca_interval_times_to_numeric()`).  [pk.nca()] calls
#' this, so the PKNCAdata object keeps the date-times and its intervals can
#' change until the calculation.  Numeric inputs are unchanged, so converting
#' twice is harmless.
#'
#' @param data A PKNCAdata object
#' @param warn Give the warnings of the conversion (a group using its first
#'   concentration as the reference, Date interval bounds)?  [PKNCAdata()]
#'   converts a copy only to check the data and to choose automatic intervals,
#'   and leaves the warnings to [pk.nca()].
#' @returns `data` with numeric times, durations, and intervals, and, for
#'   date-time data, a `time_reference` element (a data.frame with the
#'   reference group columns, a POSIXct `time_reference` column, and a
#'   `time_reference_type` column)
#' @keywords Internal
#' @noRd
pknca_datetime_convert <- function(data, warn = TRUE) {
  times <- pknca_datetime_times(data)
  if (times$is_datetime) {
    time_reference <- pknca_datetime_quietly(pknca_datetime_reference(data, times), warn = warn)
    ref_groups <- setdiff(names(time_reference), c("time_reference", "time_reference_type"))
    time_unit <- pknca_datetime_time_unit(as_PKNCAconc(data))

    o_conc <- as_PKNCAconc(data)
    conc_data <- as.data.frame(o_conc)
    conc_ref <- pknca_datetime_match_reference(conc_data[, ref_groups, drop = FALSE], time_reference)
    conc_data[[o_conc$columns$time]] <-
      pknca_difftime_to_unit(difftime(times$conc_time, conc_ref, units = "secs"), unit = time_unit)
    data$conc <- pknca_replace_data(o_conc, conc_data)

    if (!is.null(times$dose_time)) {
      o_dose <- as_PKNCAdose(data)
      dose_data <- as.data.frame(o_dose)
      dose_ref <- pknca_datetime_match_reference(dose_data[, ref_groups, drop = FALSE], time_reference)
      dose_data[[o_dose$columns$time]] <-
        pknca_difftime_to_unit(difftime(times$dose_time, dose_ref, units = "secs"), unit = time_unit)
      data$dose <- pknca_replace_data(o_dose, dose_data)
    }
    data$time_reference <- time_reference
  }
  data <- pknca_duration_to_numeric(data)
  if (!is.null(data$intervals)) {
    data$intervals <- pknca_interval_times_to_numeric(data$intervals, data, warn = warn)
  }
  data
}

#' Evaluate an expression, optionally without the conversion's warnings
#'
#' @param expr The expression
#' @param warn Keep the warnings?
#' @returns The value of `expr`
#' @keywords Internal
#' @noRd
pknca_datetime_quietly <- function(expr, warn) {
  if (warn) {
    expr
  } else {
    withCallingHandlers(
      expr,
      pknca_warning_datetime_first_conc_reference = function(w) rlang::cnd_muffle(w),
      pknca_warning_date_assumed_time = function(w) rlang::cnd_muffle(w)
    )
  }
}

#' Convert difftime durations to numbers in the time unit of the analysis
#'
#' Numeric durations are already in the time unit of the analysis.  Durations
#' given as difftime are converted exactly to that unit:  the unit of the
#' concentration data, or hours for date-time data without units.
#'
#' @param data A PKNCAdata object, after any date-time conversion
#' @returns `data` with numeric durations
#' @keywords Internal
#' @noRd
pknca_duration_to_numeric <- function(data) {
  o_conc <- as_PKNCAconc(data)
  o_dose <- as_PKNCAdose(data)
  conc_data <- as.data.frame(o_conc)
  dose_data <- if (!identical(o_dose, NA)) as.data.frame(o_dose)
  conc_cols <- o_conc$columns$duration
  dose_cols <- if (!identical(o_dose, NA)) o_dose$columns$duration
  is_difftime <- function(cols, current_data) {
    length(cols) > 0 &&
      any(vapply(X = current_data[cols], FUN = inherits, FUN.VALUE = TRUE, what = "difftime"))
  }
  if (!is_difftime(conc_cols, conc_data) && !is_difftime(dose_cols, dose_data)) {
    return(data)
  }
  time_unit <-
    if (!is.null(data$time_reference)) {
      pknca_datetime_time_unit(o_conc)
    } else if (!is.null(o_conc$units$timeu)) {
      o_conc$units$timeu
    } else if (!is.null(o_conc$columns$timeu)) {
      unique(as.character(conc_data[[o_conc$columns$timeu]]))
    } else {
      NA_character_
    }
  if (length(time_unit) != 1 || is.na(time_unit) || is.na(pknca_hours_factor(time_unit))) {
    rlang::abort(
      "Durations given as difftime need date-time times or a single time unit (`timeu`) for the concentration data, to know the unit to convert them to.",
      class = "pknca_error_difftime_duration_unit"
    )
  }
  for (duration_col in conc_cols) {
    if (inherits(conc_data[[duration_col]], "difftime")) {
      conc_data[[duration_col]] <- pknca_difftime_to_unit(conc_data[[duration_col]], unit = time_unit)
    }
  }
  data$conc <- pknca_replace_data(o_conc, conc_data)
  if (!is.null(dose_data)) {
    for (duration_col in dose_cols) {
      if (inherits(dose_data[[duration_col]], "difftime")) {
        dose_data[[duration_col]] <- pknca_difftime_to_unit(dose_data[[duration_col]], unit = time_unit)
      }
    }
    data$dose <- pknca_replace_data(o_dose, dose_data)
  }
  data
}

#' Convert date-time interval bounds to numeric time
#'
#' Rows whose `start` and `end` are date-times (POSIXct, or Date for 08:00)
#' become numeric times relative to the time reference of the group they apply
#' to, in the time unit of the analysis, the same way concentration and dose
#' times are converted.  A row that does not give every reference group column
#' applies to all the matching groups, so it becomes one row per group, each
#' relative to that group's own reference.  An `end` of `Inf` (numeric, or a
#' POSIXct `Inf`) stays `Inf`.  Numeric intervals are returned unchanged, so
#' converting twice is harmless.  The intervals are checked by
#' [assert_intervals()] before this is called.
#'
#' @param intervals The intervals data.frame
#' @param data The PKNCAdata object, after its own date-time conversion (with
#'   `time_reference`)
#' @param warn Warn for Date bounds?
#' @returns `intervals` with numeric `start` and `end`; when date-time bounds
#'   were converted, an `interval_time_kind` column is `"datetime"` for the
#'   converted rows and `"relative"` for rows that were already numeric
#' @keywords Internal
#' @noRd
pknca_interval_times_to_numeric <- function(intervals, data, warn = TRUE) {
  dt_start <- is_datetime_date(intervals$start)
  dt_end <- is_datetime_date(intervals$end)
  if (!dt_start && !dt_end) {
    if ("interval_time_kind" %in% names(intervals)) {
      intervals$interval_time_kind[is.na(intervals$interval_time_kind)] <- "relative"
    }
    return(intervals)
  }
  if (warn) {
    for (bound in c("start", "end")[c(dt_start, dt_end)]) {
      if (inherits(intervals[[bound]], "Date")) {
        pknca_warn_date_time(time_col = bound, data_type = "interval")
      }
    }
  }
  time_reference <- data$time_reference
  tz_ref <- pknca_datetime_tz(time_reference$time_reference)
  start_abs <- pknca_as_posixct(intervals$start, tz = tz_ref)
  end_abs <- if (dt_end) pknca_as_posixct(intervals$end, tz = tz_ref) else intervals$end
  ref_groups <- setdiff(names(time_reference), c("time_reference", "time_reference_type"))
  # Temporary column names that cannot collide with the user's columns
  row_col <- paste0(max(colnames(intervals)), "X")
  ref_col <- paste0(max(c(colnames(intervals), row_col)), "X")
  ref_table <- time_reference[, c(ref_groups, "time_reference"), drop = FALSE]
  names(ref_table)[names(ref_table) == "time_reference"] <- ref_col
  intervals[[row_col]] <- seq_len(nrow(intervals))
  intervals$start <- NULL
  intervals$end <- NULL
  # Each row gets the reference of every group it applies to
  join_groups <- intersect(names(intervals), ref_groups)
  ret <-
    if (length(join_groups) > 0) {
      dplyr::inner_join(intervals, ref_table, by = join_groups, relationship = "many-to-many")
    } else {
      dplyr::cross_join(intervals, ref_table)
    }
  ret <- as.data.frame(ret)
  ret <- ret[order(ret[[row_col]]), , drop = FALSE]
  time_unit <- pknca_datetime_time_unit(as_PKNCAconc(data))
  ret$start <-
    pknca_difftime_to_unit(
      difftime(start_abs[ret[[row_col]]], ret[[ref_col]], units = "secs"),
      unit = time_unit
    )
  current_end <- end_abs[ret[[row_col]]]
  # An infinite end (numeric, or a POSIXct Inf) stays infinite
  end_num <- as.numeric(current_end)
  mask_finite_end <- is.finite(end_num)
  end_num[mask_finite_end] <-
    pknca_difftime_to_unit(
      difftime(current_end[mask_finite_end], ret[[ref_col]][mask_finite_end], units = "secs"),
      unit = time_unit
    )
  ret$end <- end_num
  ret$interval_time_kind <- "datetime"
  ret[[row_col]] <- NULL
  ret[[ref_col]] <- NULL
  # start and end first, as usual
  ret <- ret[, unique(c("start", "end", setdiff(names(ret), c("start", "end")))), drop = FALSE]
  rownames(ret) <- NULL
  ret
}

#' Check date-time interval bounds
#'
#' @param intervals The intervals data.frame (with a date-time `start` or
#'   `end`)
#' @param data The PKNCAdata object (with date-time times)
#' @returns `intervals`, invisibly, or an error
#' @keywords Internal
#' @noRd
assert_interval_times_datetime <- function(intervals, data) {
  dt_start <- is_datetime_date(intervals$start)
  dt_end <- is_datetime_date(intervals$end)
  # Only an open end (Inf) can pair a numeric bound with a date-time start
  if (!dt_start || (!dt_end && !all(is.infinite(intervals$end) & intervals$end > 0))) {
    rlang::abort(
      "Interval `start` and `end` must both be date-times or both be numeric; the only numeric bound allowed with a date-time `start` is `end = Inf`.",
      class = "pknca_error_interval_datetime_mixed"
    )
  }
  times <- pknca_datetime_times(data)
  if (!times$is_datetime) {
    rlang::abort(
      "Intervals given as date-times need date-time concentration and dose times to be relative to; with numeric times, give numeric intervals.",
      class = "pknca_error_interval_datetime_numeric_data"
    )
  }
  for (bound in c("start", "end")[c(dt_start, dt_end)]) {
    tz_bound <- pknca_datetime_tz(intervals[[bound]])
    if (!is.na(tz_bound) && !identical(tz_bound, times$tz)) {
      rlang::abort(
        sprintf(
          "Interval date-times must have the same time zone (UTC offset) as the concentration and dose date-times; the time zones are: '%s', '%s'",
          tz_bound, times$tz
        ),
        class = "pknca_error_datetime_mixed_tz"
      )
    }
  }
  start_seconds <- as.numeric(pknca_as_posixct(intervals$start, tz = times$tz))
  if (any(!is.finite(start_seconds))) {
    rlang::abort(
      "Interval `start` date-times must be finite (not NA or infinite).",
      class = "pknca_error_interval_datetime_start_infinite"
    )
  }
  end_seconds <-
    if (dt_end) {
      as.numeric(pknca_as_posixct(intervals$end, tz = times$tz))
    } else {
      intervals$end
    }
  assert_interval_end_after_start(start = start_seconds, end = end_seconds)
  time_reference <- pknca_datetime_quietly(pknca_datetime_reference(data, times), warn = FALSE)
  ref_groups <- setdiff(names(time_reference), c("time_reference", "time_reference_type"))
  conc_groups <- names(getGroups(as_PKNCAconc(data)))
  if (length(setdiff(ref_groups, conc_groups)) > 0) {
    rlang::abort(
      sprintf(
        "Date-time intervals need the time reference groups to be concentration groups; add %s to the concentration formula groups.",
        paste0("'", setdiff(ref_groups, conc_groups), "'", collapse = ", ")
      ),
      class = "pknca_error_interval_datetime_groups"
    )
  }
  join_groups <- intersect(names(intervals), ref_groups)
  if (length(join_groups) > 0) {
    # A temporary column name that cannot collide with the user's columns
    matched_col <- paste0(max(colnames(intervals)), "X")
    reference_groups <- unique(time_reference[, join_groups, drop = FALSE])
    reference_groups[[matched_col]] <- TRUE
    matched <-
      !is.na(dplyr::left_join(
        intervals[, join_groups, drop = FALSE], reference_groups,
        by = join_groups
      )[[matched_col]])
    if (!all(matched)) {
      rlang::abort(
        sprintf(
          "Date-time interval rows %s match no group with a time reference.",
          paste(which(!matched), collapse = ", ")
        ),
        class = "pknca_error_interval_datetime_no_reference"
      )
    }
  }
  invisible(intervals)
}

#' Check numeric interval bounds
#'
#' @param intervals The intervals data.frame (with numeric `start` and `end`)
#' @returns `intervals`, invisibly, or an error
#' @keywords Internal
#' @noRd
assert_interval_times_numeric <- function(intervals) {
  checkmate::assert_numeric(intervals$start, any.missing = FALSE, finite = TRUE, .var.name = "intervals$start")
  checkmate::assert_numeric(intervals$end, .var.name = "intervals$end")
  assert_interval_end_after_start(start = intervals$start, end = intervals$end)
  invisible(intervals)
}

#' Check that every interval end is a number after its start
#'
#' An end may be `Inf` (an interval to infinity, as for AUCinf), but not
#' missing, `NaN`, or `-Inf`.
#'
#' @param start,end The interval starts and ends as numbers (for date-times,
#'   seconds since the epoch, with an infinite end kept infinite)
#' @returns `NULL`, invisibly, or an error naming the offending rows
#' @keywords Internal
#' @noRd
assert_interval_end_after_start <- function(start, end) {
  end <- as.numeric(end)
  start <- as.numeric(start)
  mask_invalid <- is.na(end) | end == -Inf
  if (any(mask_invalid)) {
    rlang::abort(
      sprintf(
        "Interval `end` must not be missing, NaN, or -Inf (Inf is allowed); rows: %s",
        paste(which(mask_invalid), collapse = ", ")
      ),
      class = "pknca_error_interval_end_invalid"
    )
  }
  mask_order <- end <= start
  if (any(mask_order)) {
    rlang::abort(
      sprintf(
        "Interval `end` must be after `start`; rows: %s",
        paste(which(mask_order), collapse = ", ")
      ),
      class = "pknca_error_interval_end_not_after_start"
    )
  }
  invisible(NULL)
}

#' Get the time unit that date-time input is converted to
#'
#' @param o_conc A PKNCAconc object
#' @returns The time unit of the concentration data, or `"hr"` without units
#' @keywords Internal
#' @noRd
pknca_datetime_time_unit <- function(o_conc) {
  choose_first(o_conc$units$timeu, "hr")
}

#' Find the groups that date-time references are computed within
#'
#' With dose times, the groups are the concentration grouping columns and the
#' subject that the dose formula shares, and for dense data the subject must be
#' one of them (otherwise one reference would be pooled across subjects).
#' Without dose times, the groups are the concentration grouping columns to the
#' left of any `/` and, for dense data, the subject.  Sparse data use one
#' reference per group rather than per subject, because PKNCA requires every
#' subject in a sparse group to share the group's dosing.
#'
#' The same groups locate the time point reference of each CDISC result row
#' (see `pknca_cdisc_interval_reference()`), for numeric times too.  Numeric
#' times have no per-subject reference to protect, so a dose formula without
#' the subject is allowed there (`check_subject = FALSE`):  every subject of a
#' group then shares the group's doses.
#'
#' @param o_conc,o_dose The PKNCAconc and PKNCAdose (or `NA`) objects
#' @param has_dose_time Are there dose times?
#' @param check_subject Require the subject among the groups (as date-time
#'   references need)?
#' @returns A character vector of column names
#' @keywords Internal
#' @noRd
pknca_datetime_ref_groups <- function(o_conc, o_dose, has_dose_time, check_subject = TRUE) {
  subject_col <- if (is_sparse_pk(o_conc)) character() else o_conc$columns$subject
  if (!has_dose_time) {
    return(unique(c(o_conc$columns$groups$group_vars, subject_col)))
  }
  conc_keys <- unique(c(unlist(o_conc$columns$groups), subject_col))
  ref_groups <- intersect(conc_keys, unlist(o_dose$columns$groups))
  if (check_subject && length(subject_col) == 1 && !(subject_col %in% ref_groups)) {
    rlang::abort(
      sprintf(
        paste(
          "With date-time times, the dose formula must include the subject column ('%s') so that each subject has its own time reference.",
          "Concentration formula: %s; dose formula: %s"
        ),
        subject_col,
        paste(deparse(stats::formula(o_conc)), collapse = " "),
        paste(deparse(stats::formula(o_dose)), collapse = " ")
      ),
      class = "pknca_error_datetime_subject_not_grouped"
    )
  }
  ref_groups
}

#' Find the date-time reference of each group
#'
#' The groups are those of `pknca_datetime_ref_groups()`.  The reference is the
#' first included dose of the group (`"first_dose"`); a group of concentrations
#' without an included dose uses its first concentration (`"first_conc"`), with
#' a warning, and without dose times every reference is the first
#' concentration.  The first concentration is the first included (not
#' excluded) one, or the first one when all are excluded.
#'
#' @param data A PKNCAdata object
#' @param times The result of `pknca_datetime_times(data)`
#' @returns A data.frame with the reference group columns, `time_reference`
#'   (POSIXct), and `time_reference_type` (`"first_dose"` or `"first_conc"`)
#' @keywords Internal
#' @noRd
pknca_datetime_reference <- function(data, times) {
  o_conc <- as_PKNCAconc(data)
  o_dose <- as_PKNCAdose(data)
  has_dose_time <- !is.null(times$dose_time)
  ref_groups <- pknca_datetime_ref_groups(o_conc, o_dose, has_dose_time = has_dose_time)
  conc_time <- times$conc_time
  conc_excluded <- !is.na(normalize_exclude(o_conc))
  conc_ref_data <- as.data.frame(o_conc)[, ref_groups, drop = FALSE]
  conc_ref_data$time_reference <- conc_time
  conc_ref_data <- conc_ref_data[!is.na(conc_time), , drop = FALSE]
  conc_included <- !conc_excluded[!is.na(conc_time)]
  first_conc <- pknca_datetime_first_included(conc_ref_data, ref_groups, included = conc_included)
  first_conc <- pknca_datetime_sort_groups(first_conc, ref_groups)
  first_conc$time_reference_type <- rep("first_conc", nrow(first_conc))
  if (!has_dose_time) {
    if (!identical(o_dose, NA)) {
      pknca_warn_first_conc_reference(first_conc[, ref_groups, drop = FALSE])
    }
    return(first_conc)
  }
  dose_time <- times$dose_time
  dose_excluded <- !is.na(normalize_exclude(o_dose))
  dose_ref_data <- as.data.frame(o_dose)[, ref_groups, drop = FALSE]
  dose_ref_data$time_reference <- dose_time
  first_dose <-
    pknca_datetime_first(
      dose_ref_data[!dose_excluded & !is.na(dose_time), , drop = FALSE],
      ref_groups
    )
  first_dose$time_reference_type <- rep("first_dose", nrow(first_dose))
  mask_no_dose <-
    is.na(pknca_datetime_match_reference(first_conc[, ref_groups, drop = FALSE], first_dose))
  if (any(mask_no_dose)) {
    pknca_warn_first_conc_reference(first_conc[mask_no_dose, ref_groups, drop = FALSE])
  }
  pknca_datetime_sort_groups(rbind(first_dose, first_conc[mask_no_dose, , drop = FALSE]), ref_groups)
}

#' Sort a data.frame by group columns
#'
#' @param data A data.frame
#' @param groups The group column names (possibly none)
#' @returns `data` sorted by `groups`, with row names reset
#' @keywords Internal
#' @noRd
pknca_datetime_sort_groups <- function(data, groups) {
  if (length(groups) > 0 && nrow(data) > 0) {
    data <- data[do.call(order, unname(as.list(data[, groups, drop = FALSE]))), , drop = FALSE]
  }
  rownames(data) <- NULL
  data
}

#' Warn that concentration groups use their first concentration as the
#' reference because they have no included dose time
#'
#' @param groups A data.frame of the affected groups' values (possibly with no
#'   columns)
#' @returns `NULL`, invisibly, after the warning
#' @keywords Internal
#' @noRd
pknca_warn_first_conc_reference <- function(groups) {
  rlang::warn(
    sprintf(
      "No included dose time is available for the concentration date-times%s; the first concentration is the time reference instead.",
      if (ncol(groups) > 0) {
        paste0(" in these groups: ", paste(name_value_text(groups), collapse = "; "))
      } else {
        ""
      }
    ),
    class = "pknca_warning_datetime_first_conc_reference"
  )
  invisible(NULL)
}

#' Find the earliest time within each group
#'
#' @param data A data.frame with the group columns and `time_reference`
#' @param groups The group column names (possibly none)
#' @returns A data.frame with one row per group, the group columns, and
#'   `time_reference`
#' @keywords Internal
#' @noRd
pknca_datetime_first <- function(data, groups) {
  if (nrow(data) == 0) {
    data
  } else {
    as.data.frame(dplyr::summarise(
      dplyr::group_by(data, dplyr::across(dplyr::all_of(groups))),
      time_reference = min(.data$time_reference),
      .groups = "drop"
    ))
  }
}

#' Find the first included time within each group
#'
#' A group whose times are all excluded still needs a reference, so it uses its
#' first time regardless of exclusion.
#'
#' @param data A data.frame with the group columns and `time_reference` (with
#'   no missing times)
#' @param groups The group column names (possibly none)
#' @param included A logical vector, one per row of `data`:  is the time
#'   included (not excluded)?
#' @returns A data.frame with one row per group, the group columns, and
#'   `time_reference`
#' @keywords Internal
#' @noRd
pknca_datetime_first_included <- function(data, groups, included) {
  first <- pknca_datetime_first(data[included, , drop = FALSE], groups)
  first_any <- pknca_datetime_first(data, groups)
  mask_all_excluded <-
    is.na(pknca_datetime_match_reference(first_any[, groups, drop = FALSE], first))
  rbind(first, first_any[mask_all_excluded, , drop = FALSE])
}

#' Find the time reference for each row of group values
#'
#' @param groups_data A data.frame of group values (possibly with no columns)
#' @param time_reference A data.frame with the same group columns and a
#'   `time_reference` column, one row per group
#' @returns A POSIXct vector with one value per row of `groups_data`, `NA` where
#'   there is no reference
#' @keywords Internal
#' @noRd
pknca_datetime_match_reference <- function(groups_data, time_reference) {
  if (ncol(groups_data) == 0) {
    # Without groups there is at most one reference; indexing an empty
    # reference gives NA.
    time_reference$time_reference[rep(1L, nrow(groups_data))]
  } else {
    dplyr::left_join(
      groups_data, time_reference,
      by = names(groups_data),
      relationship = "many-to-one"
    )$time_reference
  }
}
