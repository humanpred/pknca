#' Is a time vector a date-time (POSIXct) or a date (Date)?
#'
#' @param x The time vector to test
#' @returns `TRUE` for POSIXct and Date vectors, `FALSE` otherwise
#' @keywords Internal
#' @noRd
is_datetime_time <- function(x) {
  inherits(x, c("POSIXct", "Date"))
}

#' Check and choose the time unit for a date-time time column
#'
#' Date-times have no numeric unit of their own, so they are converted directly
#' to the unit used for calculations and reports:  `timeu_pref` when given
#' (it takes precedence over `timeu`), otherwise `timeu`, otherwise hours.  A
#' Date column is midnight of that date, and the user is told so.
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
  if (!is_datetime_time(time)) {
    return(timeu)
  }
  if (inherits(time, "Date")) {
    pknca_warn_date_midnight(time_col = time_col, data_type = "concentration")
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

#' Convert a difftime to a number in a time unit
#'
#' @param x A difftime vector
#' @param unit A time unit recognized by `pknca_hours_factor()`
#' @returns A numeric vector
#' @keywords Internal
#' @noRd
pknca_difftime_to_unit <- function(x, unit) {
  as.numeric(x, units = "secs") / (3600 * pknca_hours_factor(unit))
}

pknca_warn_date_midnight <- function(time_col, data_type) {
  rlang::warn(
    sprintf(
      "The %s time column ('%s') is a Date; each time is taken as midnight at the start of that date.",
      data_type, time_col
    ),
    class = "pknca_warning_date_midnight"
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
#' @param tz The time zone for a Date's midnight
#' @returns A POSIXct vector
#' @keywords Internal
#' @noRd
pknca_as_posixct <- function(x, tz) {
  if (inherits(x, "Date")) {
    # Midnight of the date in the time zone of the analysis (not UTC midnight,
    # which is a different instant for any other time zone)
    as.POSIXct(format(x, "%Y-%m-%d"), tz = tz, format = "%Y-%m-%d")
  } else {
    x
  }
}

#' Convert date-time concentration and dose times to numeric time
#'
#' Numeric time is relative to the time reference of each group (see
#' `pknca_datetime_reference()`), in the time unit of the concentration data
#' (see `pknca_datetime_timeu()`), or hours when there are no units.
#'
#' @param data A PKNCAdata object under construction (with `conc` and `dose`)
#' @returns `data` with numeric times and a `time_reference` element (a
#'   data.frame with the reference group columns, a POSIXct `time_reference`
#'   column, and a `time_reference_type` column), or `data` unchanged when the
#'   times are numeric
#' @keywords Internal
#' @noRd
pknca_datetime_to_numeric <- function(data) {
  o_conc <- data$conc
  o_dose <- data$dose
  conc_dataname <- getDataName(o_conc)
  conc_time_col <- o_conc$columns$time
  conc_time <- o_conc[[conc_dataname]][[conc_time_col]]
  has_dose_time <- !identical(o_dose, NA) && length(o_dose$columns$time) == 1
  dose_time_col <- if (has_dose_time) o_dose$columns$time else NA_character_
  dose_time <- if (has_dose_time) o_dose$data[[dose_time_col]] else NULL
  conc_is_dt <- is_datetime_time(conc_time)
  dose_is_dt <- has_dose_time && is_datetime_time(dose_time)
  if (!conc_is_dt && !dose_is_dt) {
    return(data)
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
  # Time zones:  the instant of a POSIXct value does not depend on its time
  # zone, but the report of the reference (PPRFTDTC) and the midnight of a Date
  # do, so the two must agree.
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
  conc_time <- pknca_as_posixct(conc_time, tz = tz)
  dose_time <- pknca_as_posixct(dose_time, tz = tz)

  time_reference <-
    pknca_datetime_reference(
      o_conc = o_conc, conc_time = conc_time,
      o_dose = o_dose, dose_time = if (has_dose_time) dose_time else NULL
    )
  ref_groups <- setdiff(names(time_reference), c("time_reference", "time_reference_type"))
  conc_ref <-
    pknca_datetime_match_reference(
      o_conc[[conc_dataname]][, ref_groups, drop = FALSE],
      time_reference
    )
  dose_ref <-
    if (has_dose_time) {
      pknca_datetime_match_reference(o_dose$data[, ref_groups, drop = FALSE], time_reference)
    }

  # Date-times are converted directly to the unit of the analysis (the unit
  # PKNCAconc() chose from timeu_pref and timeu), or to hours when there are no
  # units.
  time_unit <- pknca_datetime_time_unit(o_conc)
  o_conc[[conc_dataname]][[conc_time_col]] <-
    pknca_difftime_to_unit(difftime(conc_time, conc_ref, units = "secs"), unit = time_unit)
  if (has_dose_time) {
    o_dose$data[[dose_time_col]] <-
      pknca_difftime_to_unit(difftime(dose_time, dose_ref, units = "secs"), unit = time_unit)
  }
  data$conc <- o_conc
  data$dose <- o_dose
  data$time_reference <- time_reference
  data
}

#' Convert difftime durations to numbers in the time unit of the analysis
#'
#' Numeric durations are already in the time unit of the analysis.  Durations
#' given as difftime are converted exactly to that unit:  the unit of the
#' concentration data, or hours for date-time data without units.
#'
#' @param data A PKNCAdata object under construction, after any date-time
#'   conversion
#' @returns `data` with numeric durations
#' @keywords Internal
#' @noRd
pknca_duration_to_numeric <- function(data) {
  o_conc <- data$conc
  o_dose <- data$dose
  conc_dataname <- getDataName(o_conc)
  duration_cols <-
    list(
      conc = o_conc$columns$duration,
      dose = if (identical(o_dose, NA)) NULL else o_dose$columns$duration
    )
  is_difftime <-
    c(
      conc = any(vapply(X = o_conc[[conc_dataname]][duration_cols$conc], FUN = inherits, FUN.VALUE = TRUE, what = "difftime")),
      dose =
        length(duration_cols$dose) > 0 &&
          any(vapply(X = o_dose$data[duration_cols$dose], FUN = inherits, FUN.VALUE = TRUE, what = "difftime"))
    )
  if (!any(is_difftime)) {
    return(data)
  }
  time_unit <-
    if (!is.null(data$time_reference)) {
      pknca_datetime_time_unit(o_conc)
    } else if (!is.null(o_conc$units$timeu)) {
      as.vector(o_conc$units$timeu)
    } else if (!is.null(o_conc$columns$timeu)) {
      unique(as.character(o_conc[[conc_dataname]][[o_conc$columns$timeu]]))
    } else {
      NA_character_
    }
  if (length(time_unit) != 1 || is.na(time_unit) || is.na(pknca_hours_factor(time_unit))) {
    rlang::abort(
      "Durations given as difftime need date-time times or a single time unit (`timeu`) for the concentration data, to know the unit to convert them to.",
      class = "pknca_error_difftime_duration_unit"
    )
  }
  for (duration_col in duration_cols$conc) {
    if (inherits(o_conc[[conc_dataname]][[duration_col]], "difftime")) {
      o_conc[[conc_dataname]][[duration_col]] <-
        pknca_difftime_to_unit(o_conc[[conc_dataname]][[duration_col]], unit = time_unit)
    }
  }
  for (duration_col in duration_cols$dose) {
    if (inherits(o_dose$data[[duration_col]], "difftime")) {
      o_dose$data[[duration_col]] <- pknca_difftime_to_unit(o_dose$data[[duration_col]], unit = time_unit)
    }
  }
  data$conc <- o_conc
  data$dose <- o_dose
  data
}

#' Convert date-time interval bounds to numeric time
#'
#' Rows whose `start` and `end` are date-times (POSIXct, or Date for midnight)
#' become numeric times relative to the time reference of the group they apply
#' to, in the time unit of the analysis, the same way concentration and dose
#' times are converted.  A row that does not give every reference group column
#' applies to all the matching groups, so it becomes one row per group, each
#' relative to that group's own reference.  An `end` of `Inf` (numeric, or a
#' POSIXct `Inf`) stays `Inf`.  Numeric intervals are returned unchanged, so
#' converting twice is harmless.
#'
#' @param intervals The intervals data.frame
#' @param data The PKNCAdata object (after its own date-time conversion)
#' @returns `intervals` with numeric `start` and `end`; when date-time bounds
#'   were converted, an `interval_time_kind` column is `"datetime"` for the
#'   converted rows and `"relative"` for rows that were already numeric
#' @keywords Internal
#' @noRd
pknca_interval_times_to_numeric <- function(intervals, data) {
  if (!is.data.frame(intervals) || !all(c("start", "end") %in% names(intervals))) {
    # Other checks report malformed intervals
    return(intervals)
  }
  dt_start <- is_datetime_time(intervals$start)
  dt_end <- is_datetime_time(intervals$end)
  if (!dt_start && !dt_end) {
    if ("interval_time_kind" %in% names(intervals)) {
      intervals$interval_time_kind[is.na(intervals$interval_time_kind)] <- "relative"
    }
    return(intervals)
  }
  # A date-time bound with a numeric bound:  only an open end (Inf) can pair
  # with a date-time start.
  if (!dt_start || (!dt_end && !all(is.infinite(intervals$end) & intervals$end > 0))) {
    rlang::abort(
      "Interval `start` and `end` must both be date-times or both be numeric; the only numeric bound allowed with a date-time `start` is `end = Inf`.",
      class = "pknca_error_interval_datetime_mixed"
    )
  }
  time_reference <- data$time_reference
  if (is.null(time_reference)) {
    rlang::abort(
      "Intervals given as date-times need date-time concentration and dose times to be relative to; with numeric times, give numeric intervals.",
      class = "pknca_error_interval_datetime_numeric_data"
    )
  }
  tz_ref <- pknca_datetime_tz(time_reference$time_reference)
  for (bound in c("start", "end")) {
    if (is_datetime_time(intervals[[bound]])) {
      tz_bound <- pknca_datetime_tz(intervals[[bound]])
      if (!is.na(tz_bound) && !identical(tz_bound, tz_ref)) {
        rlang::abort(
          sprintf(
            "Interval date-times must have the same time zone (UTC offset) as the concentration and dose date-times; the time zones are: '%s', '%s'",
            tz_bound, tz_ref
          ),
          class = "pknca_error_datetime_mixed_tz"
        )
      }
      if (inherits(intervals[[bound]], "Date")) {
        pknca_warn_date_midnight(time_col = bound, data_type = "interval")
      }
    }
  }
  start_abs <- pknca_as_posixct(intervals$start, tz = tz_ref)
  if (any(!is.finite(as.numeric(start_abs)))) {
    rlang::abort(
      "Interval `start` date-times must be finite (not NA or infinite).",
      class = "pknca_error_interval_datetime_start_infinite"
    )
  }
  end_abs <-
    if (dt_end) {
      pknca_as_posixct(intervals$end, tz = tz_ref)
    } else {
      intervals$end
    }
  ref_groups <- setdiff(names(time_reference), c("time_reference", "time_reference_type"))
  conc_groups <- names(getGroups(data$conc))
  if (length(setdiff(ref_groups, conc_groups)) > 0) {
    rlang::abort(
      sprintf(
        "Date-time intervals need the time reference groups to be concentration groups; add %s to the concentration formula groups.",
        paste0("'", setdiff(ref_groups, conc_groups), "'", collapse = ", ")
      ),
      class = "pknca_error_interval_datetime_groups"
    )
  }
  # Each row gets the reference of every group it applies to
  intervals$row_XXX <- seq_len(nrow(intervals))
  intervals$start <- NULL
  intervals$end <- NULL
  join_groups <- intersect(names(intervals), ref_groups)
  ret <-
    if (length(join_groups) > 0) {
      dplyr::inner_join(
        intervals, time_reference[, c(ref_groups, "time_reference"), drop = FALSE],
        by = join_groups, relationship = "many-to-many"
      )
    } else {
      dplyr::cross_join(intervals, time_reference[, c(ref_groups, "time_reference"), drop = FALSE])
    }
  missing_rows <- setdiff(seq_along(start_abs), ret$row_XXX)
  if (length(missing_rows) > 0) {
    rlang::abort(
      sprintf(
        "Date-time interval rows %s match no group with a time reference.",
        paste(missing_rows, collapse = ", ")
      ),
      class = "pknca_error_interval_datetime_no_reference"
    )
  }
  ret <- as.data.frame(ret)
  ret <- ret[order(ret$row_XXX), , drop = FALSE]
  time_unit <- pknca_datetime_time_unit(data$conc)
  ret$start <-
    pknca_difftime_to_unit(
      difftime(start_abs[ret$row_XXX], ret$time_reference, units = "secs"),
      unit = time_unit
    )
  current_end <- end_abs[ret$row_XXX]
  # An infinite end (numeric, or a POSIXct Inf) stays infinite
  end_num <- as.numeric(current_end)
  mask_finite_end <- is.finite(end_num)
  end_num[mask_finite_end] <-
    pknca_difftime_to_unit(
      difftime(current_end[mask_finite_end], ret$time_reference[mask_finite_end], units = "secs"),
      unit = time_unit
    )
  ret$end <- end_num
  ret$interval_time_kind <- "datetime"
  ret$row_XXX <- NULL
  ret$time_reference <- NULL
  # Keep the original column order, with start and end first as usual
  ret <- ret[, unique(c("start", "end", setdiff(names(ret), c("start", "end")))), drop = FALSE]
  rownames(ret) <- NULL
  ret
}

#' Get the time unit that date-time input is converted to
#'
#' @param o_conc A PKNCAconc object
#' @returns The time unit of the concentration data, or `"hr"` without units
#' @keywords Internal
#' @noRd
pknca_datetime_time_unit <- function(o_conc) {
  as.vector(choose_first(o_conc$units$timeu, "hr"))
}

#' Find the date-time reference of each group
#'
#' With dose times, the groups are the concentration grouping columns and the
#' subject that the dose formula shares, and for dense data the subject must be
#' one of them (otherwise one reference would be pooled across subjects).  The
#' reference is the first included dose of the group (`"first_dose"`); a group
#' of concentrations without an included dose uses its first concentration
#' (`"first_conc"`), with a warning.  Without dose times, the groups are the
#' concentration grouping columns to the left of any `/` and, for dense data,
#' the subject, and every reference is the first concentration.  The first
#' concentration is the first included (not excluded) one, or the first one
#' when all are excluded.
#'
#' Sparse data are the exception to per-subject references:  PKNCA requires
#' every subject in a sparse group to share the group's dosing, so the
#' reference is per group, and each animal's first sample is not its own
#' reference.
#'
#' @param o_conc,o_dose The PKNCAconc and PKNCAdose (or `NA`) objects
#' @param conc_time,dose_time The POSIXct concentration and dose times
#'   (`dose_time` is `NULL` without dose times)
#' @returns A data.frame with the reference group columns, `time_reference`
#'   (POSIXct), and `time_reference_type` (`"first_dose"` or `"first_conc"`)
#' @keywords Internal
#' @noRd
pknca_datetime_reference <- function(o_conc, conc_time, o_dose, dose_time) {
  conc_data <- as.data.frame(o_conc)
  subject_col <- if (is_sparse_pk(o_conc)) character() else o_conc$columns$subject
  has_dose_time <- !is.null(dose_time)
  if (has_dose_time) {
    conc_keys <- unique(c(unlist(o_conc$columns$groups), subject_col))
    ref_groups <- intersect(conc_keys, unlist(o_dose$columns$groups))
    if (length(subject_col) == 1 && !(subject_col %in% ref_groups)) {
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
  } else {
    ref_groups <- unique(c(o_conc$columns$groups$group_vars, subject_col))
  }
  conc_excluded <- !is.na(normalize_exclude(o_conc))
  conc_ref_data <- conc_data[, ref_groups, drop = FALSE]
  conc_ref_data$time_reference <- conc_time
  conc_ref_data <- conc_ref_data[!is.na(conc_time), , drop = FALSE]
  conc_included <- !conc_excluded[!is.na(conc_time)]
  first_conc <- pknca_datetime_first(conc_ref_data[conc_included, , drop = FALSE], ref_groups)
  # Groups whose concentrations are all excluded still need a reference
  first_conc_excluded <- pknca_datetime_first(conc_ref_data, ref_groups)
  first_conc <-
    rbind(
      first_conc,
      first_conc_excluded[is.na(pknca_datetime_match_reference(first_conc_excluded[, ref_groups, drop = FALSE], first_conc)), , drop = FALSE]
    )
  first_conc <- pknca_datetime_sort_groups(first_conc, ref_groups)
  first_conc$time_reference_type <- rep("first_conc", nrow(first_conc))
  if (!has_dose_time) {
    if (!identical(o_dose, NA)) {
      pknca_warn_first_conc_reference(first_conc[, ref_groups, drop = FALSE])
    }
    return(first_conc)
  }
  dose_excluded <- !is.na(normalize_exclude(o_dose))
  dose_ref_data <- o_dose$data[, ref_groups, drop = FALSE]
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

#' Format a date-time as an ISO 8601 date-time for CDISC --DTC variables
#'
#' @param x A POSIXct vector
#' @returns A character vector like `"2024-01-01T08:00:00"`
#' @keywords Internal
#' @noRd
format_iso8601_datetime <- function(x) {
  ret <- format(x, format = "%Y-%m-%dT%H:%M:%S", tz = pknca_datetime_tz(x))
  ret[is.na(x)] <- NA_character_
  ret
}
