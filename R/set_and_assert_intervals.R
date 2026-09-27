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
    renamed <-
      c(
        f = "f.obs",
        # The AUCint parameters are all dose-aware now, so the `.dose` variants
        # calculate what the parameter they were named after calculates (#508)
        aucint.last.dose = "aucint.last",
        aucint.all.dose = "aucint.all",
        aucint.inf.obs.dose = "aucint.inf.obs",
        aucint.inf.pred.dose = "aucint.inf.pred",
        aumcint.last.dose = "aumcint.last",
        aumcint.all.dose = "aumcint.all",
        aumcint.inf.obs.dose = "aumcint.inf.obs",
        aumcint.inf.pred.dose = "aumcint.inf.pred"
      )
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
  
  intervals
}