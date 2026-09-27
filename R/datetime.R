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
#' Numeric time is relative to the first (non-excluded) dose of each group,
#' where the group is the set of grouping columns shared by the concentration
#' and dose data (for example, subject within a study part or period).  The
#' numeric time is in `timeu_pref` when given, otherwise in seconds; the
#' collection durations of the concentration data and the dosing durations are
#' rescaled to the same unit.
#'
#' @param data A PKNCAdata object under construction (with `conc` and `dose`)
#' @returns `data` with numeric times and a `time_reference` element (a
#'   data.frame with the shared group columns and a POSIXct `time_reference`
#'   column), or `data` unchanged when the times are numeric
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
  if (conc_is_dt && !has_dose_time) {
    rlang::abort(
      "Date-time concentration times require dosing data with dose times; the first dose of each group is the time reference.",
      class = "pknca_error_datetime_no_dose_time"
    )
  }
  if (conc_is_dt != dose_is_dt) {
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
  tz_all <- c(pknca_datetime_tz(conc_time), pknca_datetime_tz(dose_time))
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

  # The reference is the first included dose within the groups shared by
  # concentration and dosing.
  shared_groups <- intersect(unlist(o_conc$columns$groups), unlist(o_dose$columns$groups))
  dose_excluded <- !is.na(normalize_exclude(o_dose))
  dose_ref_data <- o_dose$data[, shared_groups, drop = FALSE]
  dose_ref_data$time_reference <- dose_time
  dose_ref_data <- dose_ref_data[!dose_excluded & !is.na(dose_time), , drop = FALSE]
  time_reference <-
    if (nrow(dose_ref_data) == 0) {
      dose_ref_data
    } else {
      as.data.frame(dplyr::summarise(
        dplyr::group_by(dose_ref_data, dplyr::across(dplyr::all_of(shared_groups))),
        time_reference = min(.data$time_reference),
        .groups = "drop"
      ))
    }

  # Match each concentration row to its reference
  conc_groups <- o_conc[[conc_dataname]][, shared_groups, drop = FALSE]
  conc_ref <- pknca_datetime_match_reference(conc_groups, time_reference)
  if (anyNA(conc_ref)) {
    missing_groups <- unique(conc_groups[is.na(conc_ref), , drop = FALSE])
    rlang::abort(
      sprintf(
        "No included dose time is available as the time reference for the concentration date-times%s",
        if (ncol(missing_groups) > 0) {
          paste0(" in these groups: ", paste(name_value_text(missing_groups), collapse = "; "))
        } else {
          ""
        }
      ),
      class = "pknca_error_datetime_no_reference"
    )
  }
  dose_ref <-
    pknca_datetime_match_reference(o_dose$data[, shared_groups, drop = FALSE], time_reference)

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
  o_dose$data[[dose_time_col]] <-
    as.numeric(difftime(dose_time, dose_ref, units = "secs")) * time_factor
  # Durations were given in the original time unit (seconds), so they follow the
  # times to the new unit.
  if (time_factor != 1) {
    for (duration_col in o_conc$columns$duration) {
      o_conc[[conc_dataname]][[duration_col]] <-
        o_conc[[conc_dataname]][[duration_col]] * time_factor
    }
    for (duration_col in o_dose$columns$duration) {
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
