#' Earlier names of the NCA parameters
#'
#' Parameters that were renamed (most so that the suffix names the AUC the
#' parameter is calculated from, as `cl.inf.obs` from `aucinf.obs`, and that
#' words are separated by dots, as `count.conc`) keep their earlier names:
#' each still calculates, under its old name, the value of the parameter that
#' replaced it, and requesting one warns
#' (`pknca_warning_deprecated_parameter`); the old name keeps working.  The
#' earlier names are declared with the `historical_names` argument of
#' [add.interval.col()].
#'
#' @returns A data.frame with one row per earlier name:  `historical` (the
#'   earlier name) and `current` (the parameter that replaced it), sorted by
#'   `historical`
#' @examples
#' head(pknca_parameter_renames())
#' @family Interval specifications
#' @export
pknca_parameter_renames <- function() {
  renames <- parameter_renames()
  data.frame(historical = names(renames), current = unname(renames))
}

# The earlier names of the parameters as a named character vector (the names
# are the earlier names and the values the current ones), from the alias
# entries of the registry
parameter_renames <- function(all_intervals = get.interval.cols()) {
  current <- vapply(X = all_intervals, FUN = function(x) if (is.null(x$historical_of)) NA_character_ else x$historical_of, FUN.VALUE = "")
  current[!is.na(current)]
}

# Warn once per session for each set of deprecated names an interval
# specification requests
warn_deprecated_renamed_parameters <- function(requested) {
  warn_deprecated_parameter_names(
    requested = requested,
    replacements = parameter_renames(),
    new_name = c("the new name", "the new names"),
    class = "pknca_warning_deprecated_parameter",
    frequency_id = "pknca_deprecated_renamed"
  )
}

# The requested deprecated names that are not calculated by a function of their
# own but given by the calculation of another parameter (as tobit_residual is
# by half.life)
deprecated_output_names <- function(requested, all_intervals = get.interval.cols()) {
  old <- intersect(requested, names(parameter_renames(all_intervals)))
  old[vapply(X = all_intervals[old], FUN = function(x) is.na(interval_col_fun(x)), FUN.VALUE = TRUE)]
}

# The names an exclusion rule looks a parameter up by:  the parameter, then the
# deprecated names that it replaced, which give the same value
parameter_and_deprecated_names <- function(parameter) {
  renames <- parameter_renames()
  c(parameter, names(renames)[renames %in% parameter])
}
