#' Get the impute function from either the intervals column or from the method
#'
#' @param intervals the data.frame of intervals
#' @param impute the imputation definition -- either the name of a column in
#'   `intervals` (character scalar) or `NA` to look for a generic `"impute"`
#'   column. Must be an atomic scalar; a list (even of length 1) is rejected.
#' @return The imputation function vector
get_impute_method <- function(intervals, impute) {
  checkmate::assert_scalar(impute, na.ok = TRUE)
  checkmate::assert_data_frame(intervals)
  if (impute %in% names(intervals)) {
    impute_funs <- intervals[[impute]]
  } else if (is.na(impute) && "impute" %in% names(intervals)) {
    impute_funs <- intervals$impute
  } else {
    impute_funs <- impute
  }
  checkmate::assert_character(impute_funs)
  impute_funs
}

#' Methods for imputation of data with PKNCA
#' @name PKNCA_impute_method
#' @return A data.frame with one column named conc with imputed concentrations
#'   and one column named time with the times.
NULL

#' @describeIn PKNCA_impute_method Set the concentration at the start time to
#'   0, even if a nonzero concentration exists at that time (usually used with
#'   single-dose data).  Forcing the start concentration to zero is
#'   intentional:  an existing start-time value is replaced with 0, including
#'   a nonzero predose measurement shifted to the start time by
#'   `start_predose`, so the imputation chain `"start_predose,start_conc0"`
#'   gives the same result as `"start_conc0"` alone.  To carry a predose
#'   measurement to the start time, use `start_predose` without
#'   `start_conc0`.  When no observation exists at the start time, a new row
#'   with a concentration of 0 is added.
#' @inheritParams pk.calc.auxc
#' @inheritParams assert_intervaltime_single
#' @param ... ignored
#' @export
PKNCA_impute_method_start_conc0 <- function(conc, time, start=0, ..., options = list()) {
  ret <- data.frame(conc = conc, time = time)
  mask_start <- time %in% start
  if (any(mask_start)) {
    ret$conc[mask_start] <- 0
  } else {
    ret <- rbind(ret, data.frame(time = start, conc = 0))
    ret <- ret[order(ret$time), ]
  }
  ret
}

#' @describeIn PKNCA_impute_method Add a new concentration of the minimum during
#'   the interval at the start time (usually used with multiple-dose data)
#' @export
PKNCA_impute_method_start_cmin <- function(conc, time, start, end, ..., options = list()) {
  ret <- data.frame(conc = conc, time = time)
  mask_start <- time %in% start
  if (!any(mask_start)) {
    all_concs <- conc[start <= time & time <= end]
    if (!all(is.na(all_concs))) {
      cmin <- min(all_concs, na.rm = TRUE)
      ret <- rbind(ret, data.frame(time = start, conc = cmin))
      ret <- ret[order(ret$time), ]
    }
  }
  ret
}

#' @describeIn PKNCA_impute_method Shift a predose concentration to become the
#'   time zero concentration (only if a time zero concentration does not exist).
#'   A predose concentration that is `NA` is not shifted.
#' @param max_shift The maximum amount of time to shift a concentration forward
#'   (defaults to 5% of the interval duration, i.e. `0.05*(end - start)`, if
#'   `is.finite(end)`, and when `is.infinite(end)`, defaults to 5% of the time
#'   from start to `max(time)`)
#' @inheritParams pk.nca.interval
#' @export
PKNCA_impute_method_start_predose <- function(conc, time, start, end, conc.group, time.group, ..., max_shift = NA_real_, options = list()) {
  ret <- data.frame(conc = conc, time = time)
  if (is.na(max_shift)) {
    if (is.infinite(end)) {
      # A measurement at an unknown time cannot bound the shift window, so
      # fall back to the start when no time is known
      time_known <- time[!is.na(time)]
      shift_end <- if (length(time_known) > 0) max(time_known) else start
    } else {
      shift_end <- end
    }
    max_shift <- 0.05 * (shift_end - start)
  }
  # determine if the start time is already in the
  mask_start <- time %in% start
  if (!any(mask_start)) {
    # A measurement at an unknown time cannot be known to be predose, so it is
    # neither selected as the predose sample nor carried along with one
    mask_predose <- !is.na(time.group) & time.group < start
    if (any(mask_predose)) {
      time_predose <- max(time.group[mask_predose])
      if ((-time_predose) <= max_shift) {
        # A missing predose concentration carries no information, so shifting it
        # would only add a missing value at the start time
        mask_predose_change <- time.group %in% time_predose & !is.na(conc.group)
        if (any(mask_predose_change)) {
          ret_predose <- data.frame(conc = conc.group[mask_predose_change], time = start)
          ret <- dplyr::bind_rows(ret_predose, ret)
        }
      }
    }
  }
  ret
}

#' @describeIn PKNCA_impute_method Drop a concentration measured exactly at the
#'   end of the interval, if one is present (usually used with multiple-dose data
#'   when a point at the interval boundary belongs to the next dose, e.g. an
#'   imputed C0)
#' @export
PKNCA_impute_method_end_conc_drop <- function(conc, time, end, ..., options = list()) {
  ret <- data.frame(conc = conc, time = time)
  mask_end <- time %in% end
  if (any(mask_end)) {
    ret <- ret[!mask_end, , drop = FALSE]
  }
  ret
}

#' Separate out a vector of PKNCA imputation methods into a list of functions
#'
#' An error will be raised if the functions are not found.
#'
#' This function is not for use by users of PKNCA.
#'
#' @param x The character vector of PKNCA imputation method functions (without
#'   the `PKNCA_impute_method_` part)
#' @return A list of character vectors of functions to run.
#' @keywords Internal
PKNCA_impute_fun_list <- function(x) {
  if (all(is.na(x))) {
    x <- rep(NA_character_, length(x))
  }
  ret <- strsplit(x = x, split = "[, ]+", perl = TRUE)
  mask_none <- vapply(X = ret, FUN = length, FUN.VALUE = 1L) == 0
  ret[mask_none] <- NA_character_
  ret <- lapply(X = ret, FUN = PKNCA_impute_fun_list_paste)
  # Confirm that the functions exist and are functions
  # Sort will ensure that the results are not NA
  all_funs <- sort(unlist(ret))
  bad_fun <- character()
  for (idx in seq_along(all_funs)) {
    found_fun <- utils::getAnywhere(all_funs[[idx]])
    if (length(found_fun$objs) == 0) {
      bad_fun <- c(bad_fun, all_funs[[idx]])
    } else if (!is.function(found_fun$objs[[1]])) {
      bad_fun <- c(bad_fun, all_funs[[idx]])
    }
  }
  if (length(bad_fun) > 0) {
    rlang::abort(
      sprintf(
        "The following imputation functions were not found: %s",
        paste(bad_fun, collapse = ", ")
      ),
      class = "pknca_error_impute_funs_not_found"
    )
  }
  ret
}

# A helper for PKNCA_impute_fun_list that pastes PKNCA_impute_method_ to the
# beginning of everything but NA
PKNCA_impute_fun_list_paste <- function(x) {
  mask_paste <- !is.na(x) & !startsWith(x, "PKNCA_impute_method_")
  if (any(mask_paste)) {
    x[mask_paste] <- paste0("PKNCA_impute_method_", x[mask_paste])
  }
  x
}
