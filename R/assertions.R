#' Assert that an interval is accurately defined as an interval, and return the
#' interval
#'
#' @param interval Numeric vector of two numbers for the start and end time of
#'   integration
#' @param start The start time of the interval
#' @param end The end time of the interval
#' @returns `interval` (or `c(start, end)`)
#' @keywords Internal
assert_intervaltime_single <- function(interval = NULL, start = NULL, end = NULL) {
  if (is.null(interval) && is.null(start) && is.null(end)) {
    rlang::abort("One of `interval` or `start` and `end` must be given", class = "pknca_error_missing_interval")
  }

  if (xor(is.null(start), is.null(end))) {
    rlang::abort("Both `start` and `end` or neither must be given", class = "pknca_error_partial_interval")
  }
  if (!is.null(interval)) {
    checkmate::assert_numeric(x = interval, sorted = TRUE, unique = TRUE, any.missing = FALSE, len = 2)
    checkmate::assert_number(x = interval[1], na.ok = FALSE, finite = TRUE)
  }

  if (!is.null(start)) {
    # Check start and end
    checkmate::assert_number(start, na.ok = FALSE, finite = TRUE, null.ok = FALSE)
    checkmate::assert_number(end, na.ok = FALSE, finite = FALSE, lower = start, null.ok = FALSE)

    if (is.null(interval)) {
      interval <- c(start, end)
    } else if (start != interval[1]) {
      rlang::abort(
        sprintf(
          "`start` must be the same as the first value in the interval if both are given: %s!=%s",
          start,
          interval[1]
        ),
        class = "pknca_error_interval_start_mismatch"
      )
    } else if (end != interval[2]) {
      rlang::abort(
        sprintf(
          "`end` must be the same as the second value in the interval if both are given: %s!=%s",
          end,
          interval[2]
        ),
        class = "pknca_error_interval_end_mismatch"
      )
    }
  }

  interval
}

#' Verify that concentration measurements are valid
#'
#' @param conc Measured concentrations
#' @param any_missing_conc Are any concentration values allowed to be `NA`?
#' @returns `conc` or give an informative error
#' @rdname assert_conc_time
assert_conc <- function(conc, any_missing_conc = TRUE) {
  if (length(conc) == 0) {
    rlang::warn("No concentration data given", class = "pknca_warning_no_concentration")
  } else {
    checkmate::assert_numeric(conc, finite = TRUE, any.missing = any_missing_conc)
    if (all(is.na(conc))) {
      rlang::warn("All concentration data are missing", class = "pknca_warning_all_concentration_missing")
    } else if (any(!is.na(conc) & as.numeric(conc) < 0)) {
      # as.numeric(conc) is required for compatibility with units
      rlang::warn("Negative concentrations found", class = "pknca_warning_negative_concentration")
    }
  }
  conc
}

#' Verify that time values are valid
#'
#' @param time Time of the measurement of the concentrations
#' @param sorted_time Must the time be unique and monotonically increasing?
#' @returns `time` or give an informative error
#' @rdname assert_conc_time
assert_time <- function(time, sorted_time = TRUE) {
  if (length(time) == 0) {
    rlang::warn("No time data given", class = "pknca_warning_no_time")
  } else {
    checkmate::assert_numeric(time, any.missing = FALSE, sorted = sorted_time, unique = sorted_time)
  }
  time
}

#' Verify that the concentrations and times are valid
#'
#' If the concentrations or times are invalid, will provide an error.
#' Reasons for being invalid are
#' \itemize{
#'   \item `time` is not a number
#'   \item `conc` is not a number
#'   \item Any `time` value is NA
#'   \item `time` is not monotonically increasing
#'   \item `conc` and `time` are not the same length
#' }
#'
#' Some cases may generate warnings but allow the data to proceed.
#' \itemize{
#'   \item A negative concentration is often but not always an
#'     error; it will generate a warning.
#' }
#'
#' @returns A data.frame with columns named "conc" and "time" or an informative
#'   error
assert_conc_time <- function(conc, time, any_missing_conc = TRUE, sorted_time = TRUE) {
  assert_conc(conc, any_missing_conc = any_missing_conc)
  assert_time(time, sorted_time = sorted_time)
  checkmate::assert_numeric(conc, len = length(time))
  data.frame(conc = conc, time = time)
}

#' Confirm that a value is greater than another value
#'
#' @inheritParams checkmate::assert_numeric
#' @param lower_eq,upper_eq Values where equality is not allowed
#' @param ... Passed to `checkmate::assert_numeric()`
#' @returns `x`
assert_numeric_between <- function(x, any.missing = FALSE, null.ok = FALSE, lower_eq = -Inf, lower = -Inf, upper = Inf, upper_eq = Inf, ..., .var.name = checkmate::vname(x)) {
  checkmate::assert_numeric(x, any.missing = any.missing, null.ok = null.ok, lower = lower_eq, upper = upper_eq, ..., .var.name = .var.name)
  if (is.null(x) && null.ok) {
    # do nothing
  } else {
    # disallowed missing will have been previously caught
    mask_na <- is.na(x)
    mask_lower <- !mask_na & !is.infinite(lower) & x <= lower
    mask_upper <- !mask_na & !is.infinite(upper) & x >= upper
    msg <- NULL
    if (any(mask_lower)) {
      msg <-
        c(
          msg,
          sprintf("Assertion on '%s' failed: %s is not > %g", .var.name, element_find(mask_lower), lower)
        )
    }
    if (any(mask_upper)) {
      msg <-
        c(
          msg,
          sprintf("Assertion on '%s' failed: %s is not < %g", .var.name, element_find(mask_upper), upper)
        )
    }
    if (length(msg) > 0) {
      rlang::abort(paste(msg, collapse = "\n"), class = "pknca_error_numeric_between")
    }
  }
  x
}

element_find <- function(x) {
  values <- which(x)
  ret_values <-
    if (length(values) > 6) {
      paste(values[1:5], collapse = ", ")
    } else {
      paste(values, collapse = ", ")
    }
  paste(
    ngettext(length(values), msg1 = "Element", msg2 = "Elements"),
    ret_values
  )
}

#' Confirm that a value is greater than another value
#'
#' @inheritParams checkmate::assert_number
#' @param len Ignored (must be 1)
#' @param ... Passed to `assert_numeric_between()`
#' @returns `x` or an informative error
assert_number_between <- function(x, ..., na.ok = FALSE, len = 1, .var.name = checkmate::vname(x)) {
  assert_numeric_between(x, len = 1, .var.name = .var.name, ..., any.missing = na.ok)
}

#' Assert that a value is a dosing interval
#'
#' @param tau The dosing interval
#' @returns `tau` or an informative error
assert_dosetau <- function(tau) {
  assert_number_between(x = tau, lower = 0, .var.name = checkmate::vname(tau), finite = TRUE)
}

#' Assert that a lambda.z value is valid
#'
#' @inheritParams assert_numeric_between
#' @param lambda.z The elimination rate (in units of inverse time) for
#'   extrapolation
#' @returns `lambda.z` or an informative error
assert_lambdaz <- function(lambda.z, any.missing = TRUE, .var.name = checkmate::vname(lambda.z)) {
  assert_numeric_between(x = lambda.z, lower = 0, any.missing = any.missing, .var.name = .var.name, finite = TRUE)
}

#' Assert that a value is a valid AUC method
#'
#' @param method The method for integration (one of 'lin up/log down',
#'   'lin-log', or 'linear')
#' @returns `method` or an informative error
assert_aucmethod <- function(method = c("lin up/log down", "linear", "lin-log")) {
  match.arg(method)
}

#' Assert that a character vector only contains PKNCA parameter names
#'
#' @param param A vector of parameter names to check
#' @returns `param` or give an informative error
#' @keywords Internal
assert_param_name <- function(param) {
  checkmate::assert_character(param, any.missing = FALSE, min.chars = 1)
  missing_param <- setdiff(param, names(get.interval.cols()))
  if (length(missing_param) > 0) {
    rlang::abort(
      sprintf(
        ngettext(
          length(missing_param),
          msg1 = "%s is not a valid PKNCA parameter name",
          msg2 = "%s are not valid PKNCA parameter names"
        ),
        paste(missing_param, collapse = ", ")
      ),
      class = "pknca_error_invalid_param_name"
    )
  }
  param
}

#' Assert that an object is a PKNCAdata object
#' @param object The PKNCAdata object
#' @returns The object
assert_PKNCAdata <- function(object) {
  if (!inherits(object, "PKNCAdata")) {
    rlang::abort("Must be a PKNCAdata object", class = "pknca_error_not_PKNCAdata")
  }
  if (nrow(object$intervals) == 0) {
    rlang::warn("No intervals given; no calculations will be done.", class = "pknca_warning_no_intervals")
  }
  assert_PKNCAconc(object$conc)
  object
}

#' @describeIn assert_PKNCAdata Assert that an object is a PKNCAresults object
#' @param object The PKNCAresults object
#' @export
assert_PKNCAresults <- function(object) {
  if (!inherits(object, "PKNCAresults")) {
    rlang::abort("Must be a PKNCAresults object", class = "pknca_error_not_pkncaresults")
  }
  object
}

#' @describeIn assert_PKNCAdata Assert that an object is a PKNCAconc object
#' @param object The PKNCAconc object
#' @export
assert_PKNCAconc <- function(object) {
  if (!inherits(object, "PKNCAconc")) {
    rlang::abort("Must be a PKNCAconc object", class = "pknca_error_not_concdata")
  }
  # A half-life point selection column of any other type selects nothing
  # rather than erroring, so require logical here.  PKNCAconc() validates at
  # construction and pk.nca() re-checks, catching a column replaced after.
  data_name <- getDataName(object)
  for (attr_name in c("exclude_half.life", "include_half.life")) {
    col_name <- object$columns[[attr_name]]
    if (!is.null(col_name) && all(col_name %in% names(object[[data_name]]))) {
      current_col <- object[[data_name]][[col_name]]
      if (!is.logical(current_col)) {
        rlang::abort(
          sprintf(
            "The %s column ('%s') must be a logical (TRUE/FALSE/NA) column, not %s",
            attr_name, col_name, class(current_col)[1]
          ),
          class = "pknca_error_half_life_column_not_logical"
        )
      }
    }
  }
  object
}

#' @describeIn assert_PKNCAdata Assert that an object is a PKNCAdose object
#' @param object The PKNCAdose object
#' @export
assert_PKNCAdose <- function(object) {
  if (!inherits(object, "PKNCAdose")) {
    rlang::abort("Must be a PKNCAdose object", class = "pknca_error_not_dosedata")
  }
  object
}

#' @describeIn assert_unit Assert that a column name contains a character string
#'   (that could be a unit specification)
assert_unit_col <- function(unit, data) {
  checkmate::assert_character(unit, len = 1)
  checkmate::assert_data_frame(data)
  checkmate::assert_names(names(data), must.include = unit)
  checkmate::assert_character(data[[unit]])
  structure(unit, unit_type = "column")
}

#' @describeIn assert_unit Assert that a value may be a single unit
#'
#' The function does not verify that it is a real unit like "ng/mL" only that it
#' is a single character string.
assert_unit_value <- function(unit) {
  if (is.null(unit)) {
    return(unit)
  }

  checkmate::assert_character(unit, len = 1)

  structure(unit, unit_type = "value")
}

#' Assert that a value may either be a column name in the data (first) or a
#' single unit value (second)
#'
#' @param unit The column name or unit value
#' @param data The data.frame that contains a column named `unit`
#' @returns `unit` with an attribute of "unit_type" that is either "column" or
#'   "value", or `NULL` if `is.null(unit)`
assert_unit <- function(unit, data) {
  unit_col <- try(assert_unit_col(unit = unit, data = data), silent = TRUE)
  unit_value <- try(assert_unit_value(unit = unit), silent = TRUE)
  if (!inherits(unit_col, "try-error")) {
    unit_col
  } else if (!inherits(unit_value, "try-error")) {
    unit_value
  } else {
    # Re-raise the unit_col error. That is better than unit_value since it is
    # stricter.
    rlang::abort(unit_col, class = "pknca_error_invalid_unit")
  }
}
