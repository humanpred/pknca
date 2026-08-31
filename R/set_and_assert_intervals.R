#'  Set Intervals
#'
#'  Takes in two objects, the PKNCAdata object and the proposed intervals.
#'  It will then check that the intervals are valid, given the data object.
#'  If the intervals are valid, it will set them in the object.
#'  It will return the data object with the intervals set.
#'  
#' @param data PKNCAdata object
#' @param intervals Proposed intervals
#' @returns The data object with the intervals set.
#'   
#' @export
set_intervals <- function(data, intervals) {
  valid_intervals <- assert_intervals(intervals, data)
  
  data$intervals <- valid_intervals
  
  data
}

#'  Assert Intervals
#'
#'  Verifies that an interval definition is valid for a PKNCAdata object.
#'  Valid means that intervals are a data.frame (or data.frame-like object), 
#'  that the column names are either the groupings of the PKNCAconc part of 
#'  the PKNCAdata object or that they are one of the NCA parameters allowed 
#'  (i.e. names(get.interval.cols())). 
#'  It will return the intervals argument unchanged, or it will raise an error.
#'  
#' @param intervals Proposed intervals
#' @param data PKNCAdata object
#' @returns The intervals argument unchanged, or it will raise an error.
#'   
#' @export
assert_intervals <- function(intervals, data) {
  checkmate::assert_data_frame(intervals)
  checkmate::assert_class(data, classes = "PKNCAdata")

  allowed_columns <-
    c(
      names(getGroups.PKNCAdata(data)),
      names(get.interval.cols()),
      "conc_above",
      "time_above",
      "impute",
      "tau",
      "interval_id",
      paste0(secondary_parameter_names(), "_ref"),
      # If not used, data$options$keep_interval_cols will be NULL
      data$options$keep_interval_cols
    )
  
  invalid_columns <- setdiff(names(intervals), allowed_columns)

  if (length(invalid_columns) > 0) {
    # A renamed parameter gets a pointer to its new name instead of a bare
    # rejection
    renamed <- c(f = "f.obs")
    hints <- renamed[intersect(names(renamed), invalid_columns)]
    hint_text <-
      if (length(hints) > 0) {
        paste0(
          "  ",
          paste(sprintf("'%s' is now named '%s'.", names(hints), hints), collapse = "  ")
        )
      } else {
        ""
      }
    rlang::abort(
      sprintf(
        "The following columns in 'intervals' are not allowed: %s%s",
        paste(invalid_columns, collapse = ", "),
        hint_text
      ),
      class = "pknca_error_invalid_interval_columns"
    )
  }

  # A standard error or degrees of freedom that only a sparse estimator produces
  # would silently give nothing with dense data, so say so instead
  if (!is_sparse_pk(data)) {
    requested_sparse_only <-
      intersect(sparse_only_params(), interval_requested_params(intervals))
    if (length(requested_sparse_only) > 0) {
      rlang::abort(
        sprintf(
          "%s only calculated for sparse PK; give `sparse = TRUE` to `PKNCAconc()` or drop %s from the intervals: %s",
          ngettext(length(requested_sparse_only), msg1="This parameter is", msg2="These parameters are"),
          ngettext(length(requested_sparse_only), msg1="it", msg2="them"),
          paste(requested_sparse_only, collapse=", ")
        ),
        class = "pknca_error_sparse_only_parameter"
      )
    }
  }

  intervals
}