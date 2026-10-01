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
#' @seealso [pknca_impute_methods()] lists the methods.
#' @family Imputation
NULL

#' Register an imputation method
#'
#' Each `PKNCA_impute_method_*()` function is registered right after its
#' definition (so this is defined first in the file), the way interval columns
#' are registered with [add.interval.col()], so that [pknca_impute_methods()]
#' describes every method without reading the documentation.
#'
#' @param fun The name of the exported method function
#' @param description The one-line description (the first sentence of the
#'   function's documentation)
#' @returns `NULL`, invisibly
#' @keywords Internal
#' @noRd
pknca_register_impute_method <- function(fun, description) {
  checkmate::assert_string(fun, pattern = "^PKNCA_impute_method_")
  checkmate::assert_string(description, min.chars = 1)
  current <- get("impute_methods", envir = .PKNCAEnv)
  current[[fun]] <- list(description = description)
  assign("impute_methods", current, envir = .PKNCAEnv)
  invisible(NULL)
}

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
pknca_register_impute_method(
  fun = "PKNCA_impute_method_start_conc0",
  description = "Set the concentration at the start time to 0, even if a nonzero concentration exists at that time (usually used with single-dose data)."
)

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
pknca_register_impute_method(
  fun = "PKNCA_impute_method_start_cmin",
  description = "Add a new concentration of the minimum during the interval at the start time (usually used with multiple-dose data)"
)

#' @describeIn PKNCA_impute_method Shift a predose concentration to become the
#'   time zero concentration (only if a time zero concentration does not exist).
#'   The most recent predose sample with a measured concentration is shifted;
#'   samples with a missing concentration are skipped.
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
    # A measurement at an unknown time cannot be known to be predose, and a
    # missing concentration carries nothing to shift, so the predose sample is
    # the most recent one with both a known time and a measured concentration
    mask_predose <- !is.na(time.group) & !is.na(conc.group) & time.group < start
    if (any(mask_predose)) {
      time_predose <- max(time.group[mask_predose])
      if ((-time_predose) <= max_shift) {
        mask_predose_change <- time.group %in% time_predose & !is.na(conc.group)
        ret_predose <- data.frame(conc = conc.group[mask_predose_change], time = start)
        ret <- dplyr::bind_rows(ret_predose, ret)
      }
    }
  }
  ret
}
pknca_register_impute_method(
  fun = "PKNCA_impute_method_start_predose",
  description = "Shift a predose concentration to become the time zero concentration (only if a time zero concentration does not exist)."
)

#' @describeIn PKNCA_impute_method Use a predose concentration as the start
#'   concentration when one is available and 0 when it is not.  A concentration
#'   measured at the start time is kept as-is, which is what distinguishes this
#'   from `start_conc0`:  a measured concentration at the time of an
#'   intravenous bolus dose is the C0 for that dose, and `start_conc0` would
#'   replace it with 0.  The chain `"start_predose,start_conc0"` cannot express
#'   this, because `start_conc0` overwrites whatever `start_predose` shifted.
#' @export
PKNCA_impute_method_start_predose_conc0 <- function(conc, time, start, end,
                                                    conc.group, time.group, ...,
                                                    max_shift = NA_real_,
                                                    options = list()) {
  ret <-
    PKNCA_impute_method_start_predose(
      conc = conc, time = time, start = start, end = end,
      conc.group = conc.group, time.group = time.group,
      max_shift = max_shift, options = options
    )
  if (!any(ret$time %in% start)) {
    # No measurement at the start and no predose sample to shift there
    ret <-
      PKNCA_impute_method_start_conc0(
        conc = ret$conc, time = ret$time, start = start, options = options
      )
  }
  ret
}
pknca_register_impute_method(
  fun = "PKNCA_impute_method_start_predose_conc0",
  description = "Use a predose concentration as the start concentration when one is available and 0 when it is not."
)

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
pknca_register_impute_method(
  fun = "PKNCA_impute_method_end_conc_drop",
  description = "Drop a concentration measured exactly at the end of the interval, if one is present (usually used with multiple-dose data when a point at the interval boundary belongs to the next dose, e.g. an imputed C0)"
)

#' List the imputation methods
#'
#' Every `PKNCA_impute_method_*()` function is registered with its
#' description; its arguments and their defaults come from the function
#' itself.  The `method` names are what imputation strings use (see
#' [PKNCA_impute_fun_list()] and the `impute` argument of [PKNCAdata()]).
#'
#' Registration only describes PKNCA's own methods.  A method is still found by
#' its function name:  a user-defined `PKNCA_impute_method_<name>()` function
#' that PKNCA can see (for example, in the global environment) is used by the
#' imputation string `"<name>"` without being registered, and it is not listed
#' here.
#'
#' @returns A tibble with one row per method, sorted by method, and the
#'   columns:
#' \describe{
#'   \item{method}{The name used in imputation strings (for example,
#'   `"start_conc0"`)}
#'   \item{fun}{The function name (for example,
#'   `"PKNCA_impute_method_start_conc0"`)}
#'   \item{description}{The one-line description}
#'   \item{arguments}{A list column of data.frames with one row per argument
#'   and the columns `argument` and `default` (the deparsed default, or `NA`
#'   when there is none)}
#' }
#' @examples
#' pknca_impute_methods()[, c("method", "description")]
#' @family Imputation
#' @export
pknca_impute_methods <- function() {
  registry <- get("impute_methods", envir = .PKNCAEnv)
  funs <- names(registry)
  methods <- sub(pattern = "^PKNCA_impute_method_", replacement = "", x = funs)
  ord <- order(methods)
  funs <- funs[ord]
  tibble::tibble(
    method = methods[ord],
    fun = funs,
    description = vapply(X = registry[funs], FUN = "[[", "description", FUN.VALUE = "", USE.NAMES = FALSE),
    arguments = lapply(X = funs, FUN = pknca_function_arguments)
  )
}

#' Describe the arguments of an exported PKNCA function
#'
#' @param fun The function name
#' @returns A data.frame with the columns `argument` and `default` (the
#'   deparsed default, or `NA` when there is none)
#' @keywords Internal
#' @noRd
pknca_function_arguments <- function(fun) {
  fmls <- formals(getExportedValue("PKNCA", fun))
  arg_names <- as.character(names(fmls))
  data.frame(
    argument = arg_names,
    default =
      vapply(
        X = arg_names,
        FUN = function(nm) {
          if (identical(fmls[[nm]], quote(expr = ))) {
            NA_character_
          } else {
            paste(trimws(deparse(fmls[[nm]])), collapse = " ")
          }
        },
        FUN.VALUE = "",
        USE.NAMES = FALSE
      )
  )
}

#' Separate out a vector of PKNCA imputation methods into a list of functions
#'
#' Each imputation string is split at commas and spaces, and each method name
#' is expanded to its function name by adding `PKNCA_impute_method_` to the
#' beginning.  An error will be raised if the functions are not found.
#'
#' @param x The character vector of PKNCA imputation method strings (without
#'   the `PKNCA_impute_method_` part, like `"start_predose,start_conc0"`)
#' @return A list with one element per element of `x`, each a character vector
#'   of function names to run in order (or `NA_character_` for no imputation).
#' @seealso [assert_impute_method()], [PKNCA_impute_method]
#' @examples
#' PKNCA_impute_fun_list(c("start_predose,start_conc0", NA))
#' @family Imputation
#' @export
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
  bad_fun <- all_funs[!vapply(X = all_funs, FUN = PKNCA_impute_fun_exists, FUN.VALUE = TRUE)]
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

#' Check an imputation specification
#'
#' The specification is resolved the way [PKNCAdata()] and [pk.nca()] resolve
#' it:  the name of a column in `intervals`, `NA` to use the `"impute"` column
#' of `intervals` when there is one, or otherwise a string of imputation
#' methods.  Every method named must exist.
#'
#' @param impute The imputation specification (a character scalar or `NA`)
#' @param intervals The intervals data.frame (if the specification may name one
#'   of its columns)
#' @returns The resolved imputation strings (one per interval when read from a
#'   column), invisibly, or an error
#' @seealso [PKNCA_impute_fun_list()], [PKNCA_impute_method]
#' @examples
#' assert_impute_method("start_predose,start_conc0")
#' assert_impute_method(
#'   "method",
#'   intervals = data.frame(start = 0, end = 24, method = "start_conc0")
#' )
#' try(assert_impute_method("start_misspelled"))
#' @family Imputation
#' @export
assert_impute_method <- function(impute, intervals = data.frame()) {
  ret <- get_impute_method(intervals = intervals, impute = impute)
  PKNCA_impute_fun_list(ret)
  invisible(ret)
}

# A helper for PKNCA_impute_fun_list that reports whether an imputation method
# name resolves to a function.  The name is looked up starting from PKNCA's
# namespace and working outward through the imports, base, the global
# environment, and the attached packages, which is the same search that
# pk.nca.interval() uses when it calls the method by name.
PKNCA_impute_fun_exists <- function(x) {
  exists(x, mode = "function")
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
