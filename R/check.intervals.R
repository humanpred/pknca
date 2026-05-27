#' Check the formatting of a calculation interval specification data frame.
#'
#' Calculation interval specifications are data frames defining what
#' calculations will be required and summarized from all time intervals. Note:
#' parameters which are not requested may be calculated if it is required for
#' (or computed at the same time as) a requested parameter.
#'
#' `start` and `end` time must always be given as columns, and the `start` must
#' be before the `end`.  Other columns define the parameters to be calculated
#' and the groupings to apply the intervals to.
#'
#' @param x The data frame specifying what to calculate during each time
#'   interval
#' @returns x The potentially updated data frame with the interval calculation
#'   specification.
#'
#' @family Interval specifications
#' @seealso The vignette "Selection of Calculation Intervals"
#' @export
check.interval.specification <- function(x) {
  if (!is.data.frame(x)) {
    # Just a warning and let as.data.frame make it an error if it can't be
    # coerced.
    rlang::warn(
      message = "Interval specification must be a data.frame",
      class = "pknca_warning_interval_not_df"
    )
    x <- as.data.frame(x, stringsAsFactors=FALSE)
  }
  if (nrow(x) == 0) {
    rlang::abort(
      message = "interval specification has no rows",
      class = "pknca_error_interval_no_rows"
    )
  }
  # Confirm that the minimal columns (start and end) exist
  if (length(missing.required.cols <- setdiff(c("start", "end"), names(x))) > 0) {
    rlang::abort(
      message = sprintf(
        "Column(s) %s missing from interval specification",
        paste0("'", missing.required.cols, "'", collapse = ", ")
      ),
      class = "pknca_error_interval_missing_cols"
    )
  }
  interval_cols <- get.interval.cols()
  # Check the edit of each column
  for (n in names(interval_cols)) {
    if (!(n %in% names(x))) {
      if (is.vector(interval_cols[[n]]$values)) {
        # Set missing columns to the default value
        x[[n]] <- interval_cols[[n]]$values[1]
      } else {
        # It would probably take malicious code to get here (altering
        # the intervals without using add.interval.col
        rlang::abort(
          message = paste("Cannot assign default value for interval column", n),
          class = "pknca_error_interval_default_value"
        ) # nocov
      }
    } else {
      # Confirm the edits of the given columns
      if (is.vector(interval_cols[[n]]$values)) {
        if (!all(x[[n]] %in% interval_cols[[n]]$values)){
          invalid_vals <- unique(setdiff(x[[n]], interval_cols[[n]]$values))
          rlang::abort(
            message = paste0(
              sprintf("Invalid value(s) in column %s:", n),
              paste(invalid_vals, collapse = ", ")
            ),
            class = "pknca_error_interval_invalid_value"
          )
        }
         
      } else if (is.function(interval_cols[[n]]$values)) {
        if (is.factor(x[[n]])) {
          rlang::abort(
            message = sprintf("Interval column '%s' should not be a factor", n),
            class = "pknca_error_interval_factor_col"
          )
        }
        interval_cols[[n]]$values(x[[n]])
      } else {
        rlang::abort(
          message = paste("Invalid 'values' for column specification", n, "(please report this as a bug)."),
          class = "pknca_error_interval_invalid_col_spec"
        ) # nocov
      }
    }
  }
  # Now check specific columns
  # start and end
  #checkmate::assertNumeric(x$start, any.missing = FALSE)
  if (anyNA(x$start)) {
    rlang::abort(
      message = "Interval specification may not have NA for the starting time",
      class = "pknca_error_interval_na_start"
    )
  }
  if (anyNA(x$end)) {
    rlang::abort(
      message = "Interval specification may not have NA for the end time",
      class = "pknca_error_interval_na_end"
    )
  }
  if (any(is.infinite(x$start))) {
    rlang::abort(
      message = "start may not be infinite",
      class = "pknca_error_interval_infinite_start"
    )
  }
  if (any(x$start >= x$end)) {
    rlang::abort(
      message = "start must be < end",
      class = "pknca_error_interval_start_gte_end"
    )
  }
  # Confirm that something is being calculated for each interval (and warn if
  # not)
  mask_calculated <- rep(FALSE, nrow(x))
  for (n in setdiff(names(interval_cols), c("start", "end"))) {
    mask_calculated <-
      (mask_calculated |
       !(x[[n]] %in% c(NA, FALSE)))
  }
  if (any(!mask_calculated)) {
    rlang::warn(
      message = paste0(
        "Nothing to be calculated in interval specification number(s): ",
        paste(seq_len(nrow(x))[!mask_calculated], collapse = ", ")
      ),
      class = "pknca_warning_interval_nothing_calculated"
    )
  }
  # Put the columns in the right order and return the checked data frame
  x[,
    c(names(interval_cols), setdiff(names(x), names(interval_cols))),
    drop=FALSE
    ]
}

# Helper function to get.parameter.deps to determine the function map
get.parameter.deps_helper_funmap <- function(x, all_intervals) {
  if (is.na(x$FUN) &
      is.null(x$depends)) {
    # For columnns like "start" and "end"
    retfun <- NA
  } else if (is.na(x$FUN)) {
    if (length(x$depends) == 1) {
      # When the value is calculated by the same function as
      # another parameter.
      retfun <- all_intervals[[x$depends]]$FUN
    } else {
      # It would probably take malicious code to get here (an
      # example of malicious code could be altering the
      # intervals without using add.interval.col)
      rlang::abort(
        message = "Invalid interval definition with no function and multiple dependencies.",
        class = "pknca_error_interval_invalid_def"
      ) # nocov
    }
  } else {
    retfun <- x$FUN
  }
  # Define a function call by its function name and the
  # changes to the formal arguments made.
  append(list(retfun), x$formalsmap)
}
# Helper function to get.parameter.deps to find all parameters that are defined
# by the same function
get.parameter.deps_helper_samefun <- function(n, funmap) {
  mask.funmap <- rep(FALSE, length(funmap))
  for (current in n) {
    for (i in seq_len(length(funmap))) {
      mask.funmap[i] <-
        mask.funmap[i] |
        !any(
          is.na(funmap[[current]][[1]]),
          is.na(funmap[[i]][[1]])
        ) &
        identical(funmap[[current]], funmap[[i]])
    }
  }
  names(funmap)[mask.funmap]
}
# Helper function to get.parameter.deps to search all dependencies
get.parameter.deps_helper_searchdeps <- function(current, funmap, all_intervals) {
  # Find any parameters using the same function
  start <- get.parameter.deps_helper_samefun(current, funmap)
  # Find any parameters that depend on the current parameter
  ret <-
    vapply(
      X = all_intervals,
      FUN = function(x) {
        any(x$depends %in% start)
      },
      FUN.VALUE = TRUE
    )
  # Extract their names
  added <- setdiff(names(ret)[ret], start)
  if (length(added) > 0) {
    # Find any parameters that depend on any of those parameters
    unique(
      c(start, added,
        get.parameter.deps_helper_searchdeps(added, funmap, all_intervals))
    )
  } else {
    c(start, added)
  }
}

#' Get all columns that depend on a parameter
#'
#' @param x The parameter name (as a character string)
#' @returns A character vector of parameter names that depend on the parameter
#'   `x`.  If none depend on `x`, then the result will be an empty vector.
#' @family Interval specifications
#' @export
get.parameter.deps <- function(x) {
  all_intervals <- get.interval.cols()
  if (!(x %in% names(all_intervals))) {
    rlang::abort(
      message = "`x` must be the name of an NCA parameter listed by the function `get.interval.cols()`",
      class = "pknca_error_invalid_parameter"
    )
  }
  funmap <-
    lapply(
      X=all_intervals,
      FUN=get.parameter.deps_helper_funmap,
      all_intervals=all_intervals
    )
  sort(get.parameter.deps_helper_searchdeps(x, funmap, all_intervals))
}
