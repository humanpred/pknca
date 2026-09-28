#' Is a time vector a date-time (POSIXct) or a date (Date)?
#'
#' @param x The time vector to test
#' @returns `TRUE` for POSIXct and Date vectors, `FALSE` otherwise
#' @keywords Internal
#' @noRd
is_datetime_time <- function(x) {
  inherits(x, c("POSIXct", "Date"))
}

#' Check and default the time unit for a date-time time column
#'
#' Date-time (POSIXct) differences are measured in seconds, so the original time
#' unit of a date-time column is seconds.  A Date column is midnight of that
#' date, and the user is told so.
#'
#' @param time The time vector from the data
#' @param timeu,timeu_pref The `timeu` and `timeu_pref` arguments given to
#'   [PKNCAconc()]
#' @param time_col The name of the time column (for messages)
#' @returns `timeu`, set to `"s"` when it was not given and `timeu_pref` was
#'   (without `timeu_pref`, the analysis may have no units at all)
#' @keywords Internal
#' @noRd
pknca_datetime_timeu <- function(time, timeu, timeu_pref, time_col) {
  if (!is_datetime_time(time)) {
    return(timeu)
  }
  if (inherits(time, "Date")) {
    pknca_warn_date_midnight(time_col = time_col, data_type = "concentration")
  }
  if (is.null(timeu)) {
    if (!is.null(timeu_pref)) {
      timeu <- "s"
    }
  } else if (!identical(timeu, "s")) {
    rlang::abort(
      sprintf(
        "When the time column ('%s') is a date-time (POSIXct) or Date, `timeu` must be \"s\" (or not given); use `timeu_pref` to choose the reporting unit.",
        time_col
      ),
      class = "pknca_error_datetime_timeu"
    )
  }
  timeu
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
#' `pknca_datetime_reference()`).  The
#' numeric time is in `timeu_pref` when given, otherwise in seconds; the
#' collection durations of the concentration data and the dosing durations are
#' rescaled to the same unit.
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

  # The numeric time unit is the preferred time unit (so that intervals are
  # given in the reporting unit), or seconds.
  # Date-time differences are in seconds whether or not units were given
  timeu_orig <- choose_first(o_conc$units$timeu, "s")
  timeu_new <- choose_first(o_conc$units$timeu_pref, timeu_orig)
  if (identical(as.vector(timeu_new), "s")) {
    rlang::warn(
      paste(
        "Date-time times were converted to seconds after the first dose because no preferred time unit (`timeu_pref`) was given.",
        "Times in automatic intervals and options (like `single.dose.aucs`) are in seconds, too; set `timeu_pref` (for example, \"hr\") in PKNCAconc() to use another unit."
      ),
      class = "pknca_warning_datetime_seconds"
    )
  }
  time_factor <- pknca_unit_reconcile_factor(from = timeu_orig, to = timeu_new)
  if (is.na(time_factor)) {
    rlang::abort(
      sprintf(
        "Cannot convert date-time differences from '%s' to the preferred time unit '%s'%s.",
        timeu_orig, timeu_new,
        if (requireNamespace("units", quietly = TRUE)) "" else " (the units package is required)"
      ),
      class = "pknca_error_datetime_timeu_pref"
    )
  }
  o_conc[[conc_dataname]][[conc_time_col]] <-
    as.numeric(difftime(conc_time, conc_ref, units = "secs")) * time_factor
  if (has_dose_time) {
    o_dose$data[[dose_time_col]] <-
      as.numeric(difftime(dose_time, dose_ref, units = "secs")) * time_factor
  }
  # Durations were given in the original time unit (seconds), so they follow the
  # times to the new unit.
  if (time_factor != 1) {
    for (duration_col in o_conc$columns$duration) {
      o_conc[[conc_dataname]][[duration_col]] <-
        o_conc[[conc_dataname]][[duration_col]] * time_factor
    }
    for (duration_col in if (identical(o_dose, NA)) NULL else o_dose$columns$duration) {
      o_dose$data[[duration_col]] <- o_dose$data[[duration_col]] * time_factor
    }
  }
  if (!is.null(o_conc$units$timeu)) {
    o_conc$units$timeu <- timeu_new
  }
  data$conc <- o_conc
  data$dose <- o_dose
  data$time_reference <- time_reference
  data
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
