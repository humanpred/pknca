# Interval support functions
#
# The intervals data.frame is a wide representation:  one row per interval,
# one logical column per NCA parameter, and a single `impute` value shared by
# every parameter in the row.  Editing it in place is awkward because a change
# that applies to some parameters but not others requires splitting the row.
#
# These functions convert to a long representation (one row per interval and
# parameter), make the edit with ordinary filtering and mutation, and convert
# back.  Splitting and merging of rows falls out of the conversion:  two
# parameters land in the same row when every non-parameter value matches, and
# in different rows when they do not.

# The column holding the originating wide row while in long form.  Part of the
# key, so parameters from different source rows are never merged together.
pknca_interval_row_col <- ".pknca_interval_row"

# Parameter columns present in an intervals data.frame
interval_param_cols <- function(intervals) {
  intersect(names(intervals), setdiff(names(get.interval.cols()), c("start", "end")))
}

# Ensure the columns the long form needs exist:  a character `impute` and the
# originating row index.
interval_prepare <- function(intervals) {
  checkmate::assert_data_frame(intervals, min.rows = 1)
  if (!"impute" %in% names(intervals)) {
    intervals$impute <- NA_character_
  } else if (!is.character(intervals$impute)) {
    rlang::abort(
      "The 'impute' column in the intervals data.frame must be a character column",
      class = "pknca_error_interval_impute_not_character"
    )
  }
  intervals[[pknca_interval_row_col]] <- seq_len(nrow(intervals))
  intervals
}

#' Convert intervals between the wide and long representations
#'
#' @param intervals A data.frame of intervals (the wide representation).
#' @param long The long representation, as returned by `interval_longer()`.
#' @param template The intervals data.frame the long form came from; used to
#'   restore the column order and any parameter columns that are no longer
#'   requested anywhere.
#' @returns `interval_longer()` gives one row per interval and requested
#'   parameter with a `param` column naming the parameter.  `interval_wider()`
#'   gives the wide representation back.
#' @details Only parameters requested as `TRUE` become rows in the long form.
#'   Round-tripping therefore normalizes `NA` to `FALSE`, which is required:
#'   `NA` in a parameter column is rejected by
#'   [check.interval.specification()] and stops [pk.nca()].
#' @keywords internal
interval_longer <- function(intervals) {
  param_cols <- interval_param_cols(intervals)
  if (length(param_cols) == 0) {
    rlang::abort(
      "`intervals` has no NCA parameter columns",
      class = "pknca_error_interval_no_param_cols"
    )
  }
  intervals <- interval_prepare(intervals)
  ret <-
    tidyr::pivot_longer(
      intervals,
      cols = dplyr::all_of(param_cols),
      names_to = "param",
      values_to = "calculate"
    )
  ret <- ret[ret$calculate %in% TRUE, setdiff(names(ret), "calculate"), drop = FALSE]
  as.data.frame(ret, stringsAsFactors = FALSE)
}

#' @rdname interval_longer
#' @keywords internal
interval_wider <- function(long, template) {
  if (nrow(long) == 0) {
    rlang::abort(
      "No parameters remain to calculate in any interval",
      class = "pknca_error_interval_nothing_remains"
    )
  }
  long$calculate <- TRUE
  ret <-
    tidyr::pivot_wider(
      long,
      names_from = "param",
      values_from = "calculate",
      values_fill = FALSE
    )
  ret <- as.data.frame(ret, stringsAsFactors = FALSE)
  # Parameters that are no longer requested anywhere lose their column in the
  # pivot; restore them as FALSE so the caller's columns are preserved.
  for (n in setdiff(interval_param_cols(template), names(ret))) {
    ret[[n]] <- FALSE
  }
  ret <- ret[order(ret[[pknca_interval_row_col]]), , drop = FALSE]
  ret[[pknca_interval_row_col]] <- NULL
  # `impute` is added on the way to the long form; drop it again when the
  # caller did not have it and nothing set it.
  if (!"impute" %in% names(template) && all(is.na(ret$impute))) {
    ret$impute <- NULL
  }
  # Original column order first, then anything newly added
  col_order <- c(intersect(names(template), names(ret)), setdiff(names(ret), names(template)))
  ret <- ret[, col_order, drop = FALSE]
  rownames(ret) <- NULL
  ret
}

# Rows of `long` matching the requested parameters and groups.  NULL for either
# means "no restriction on that axis".
interval_target_rows <- function(long, target_params = NULL, target_groups = NULL) {
  ret <- rep(TRUE, nrow(long))
  if (!is.null(target_params)) {
    ret <- ret & long$param %in% target_params
  }
  if (!is.null(target_groups)) {
    ret <- ret & interval_match_groups(long, target_groups)
  }
  ret
}

# Match rows against a data.frame of group values:  all columns must match
# (AND) for at least one row of `target_groups` (OR).
interval_match_groups <- function(data, target_groups) {
  target_groups <- as.data.frame(target_groups, stringsAsFactors = FALSE)
  checkmate::assert_data_frame(target_groups, min.rows = 1, min.cols = 1)
  missing_cols <- setdiff(names(target_groups), names(data))
  if (length(missing_cols) > 0) {
    rlang::abort(
      sprintf(
        "Column(s) in `target_groups` not found in the intervals: %s",
        paste(missing_cols, collapse = ", ")
      ),
      class = "pknca_error_interval_target_groups_cols"
    )
  }
  match_one_row <- function(idx) {
    Reduce(
      `&`,
      lapply(names(target_groups), function(n) data[[n]] %in% target_groups[[n]][idx])
    )
  }
  Reduce(`|`, lapply(seq_len(nrow(target_groups)), match_one_row))
}

# Split an impute specification into its component method names
impute_split <- function(impute_vals) {
  strsplit(ifelse(is.na(impute_vals), "", impute_vals), split = "[ ,]+")
}

# Paste impute method names back into a specification, optionally mapping the
# empty result to NA
impute_paste <- function(impute_list, empty_na) {
  ret <- vapply(X = impute_list, FUN = paste, collapse = ",", FUN.VALUE = "")
  if (empty_na) {
    ret[ret %in% ""] <- NA_character_
  }
  ret
}

#' Add or remove an imputation method within an impute specification
#'
#' @param impute_vals Character vector of impute specifications (comma- or
#'   space-separated method names).
#' @param target_impute The imputation method to add or remove.
#' @param after Position for the added method, following [base::append()]:  `0`
#'   makes it first and `Inf` makes it last.  An existing occurrence is removed
#'   before inserting, so adding a method that is already present moves it.
#' @returns A character vector of impute specifications.  Removing the last
#'   method gives `NA_character_`.
#' @keywords internal
add_impute_method <- function(impute_vals, target_impute, after = Inf) {
  if (length(impute_vals) == 0) {
    return(impute_vals)
  }
  impute_paste(
    lapply(
      X = impute_split(impute_vals),
      FUN = function(x) append(setdiff(x, target_impute), values = target_impute, after = after)
    ),
    empty_na = FALSE
  )
}

#' @rdname add_impute_method
#' @keywords internal
remove_impute_method <- function(impute_vals, target_impute) {
  if (length(impute_vals) == 0) {
    return(impute_vals)
  }
  impute_paste(
    lapply(X = impute_split(impute_vals), FUN = setdiff, target_impute),
    empty_na = TRUE
  )
}

# Resolve the `param`/`param_pattern` pair into parameter names
interval_resolve_params <- function(param, param_pattern) {
  if (is.null(param) && is.null(param_pattern)) {
    rlang::abort(
      "One or both of `param` and `param_pattern` must be given",
      class = "pknca_error_interval_param_missing"
    )
  }
  all_params <- setdiff(names(get.interval.cols()), c("start", "end"))
  ret <- character(0)
  if (!is.null(param)) {
    ret <- c(ret, assert_param_name(param))
  }
  if (!is.null(param_pattern)) {
    checkmate::assert_character(param_pattern, any.missing = FALSE, min.chars = 1)
    matched <- unique(unlist(lapply(param_pattern, grep, x = all_params, value = TRUE)))
    if (length(matched) == 0) {
      rlang::warn(
        sprintf(
          "No parameters matched `param_pattern`: %s",
          paste(param_pattern, collapse = ", ")
        ),
        class = "pknca_warning_interval_param_pattern_no_match"
      )
    }
    ret <- c(ret, matched)
  }
  unique(ret)
}

# Add or remove an imputation method on the targeted interval rows
interval_edit_impute <- function(intervals, target_impute, after, target_params,
                                 target_groups, add) {
  checkmate::assert_character(target_impute, len = 1)
  if (is.na(target_impute) || target_impute %in% "") {
    rlang::warn(
      "No impute method specified.  No changes made.",
      class = "pknca_warning_interval_impute_none_specified"
    )
    return(intervals)
  }
  if (!is.null(target_params)) {
    assert_param_name(target_params)
  }
  long <- interval_longer(intervals)
  target <- interval_target_rows(long, target_params, target_groups)
  before <- long$impute
  long$impute[target] <-
    if (add) {
      add_impute_method(long$impute[target], target_impute, after = after)
    } else {
      remove_impute_method(long$impute[target], target_impute)
    }
  if (identical(before, long$impute)) {
    rlang::warn(
      sprintf(
        "No intervals needed a change for impute method '%s'.  No changes made.",
        target_impute
      ),
      class = "pknca_warning_interval_impute_no_change"
    )
    return(intervals)
  }
  interval_wider(long, intervals)
}

# Add or remove parameters on the targeted interval rows
interval_edit_param <- function(intervals, param, param_pattern, target_groups, add) {
  params <- interval_resolve_params(param, param_pattern)
  long <- interval_longer(intervals)
  if (add) {
    base <- interval_prepare(intervals)
    base <- base[, setdiff(names(base), interval_param_cols(intervals)), drop = FALSE]
    if (!is.null(target_groups)) {
      base <- base[interval_match_groups(base, target_groups), , drop = FALSE]
    }
    if (nrow(base) == 0) {
      rlang::warn(
        "No intervals matched `target_groups`.  No changes made.",
        class = "pknca_warning_interval_no_target_rows"
      )
      return(intervals)
    }
    added <- do.call(rbind, lapply(params, function(x) cbind(base, param = x)))
    long <- unique(rbind(long, added[, names(long), drop = FALSE]))
    long <- long[order(long[[pknca_interval_row_col]]), , drop = FALSE]
  } else {
    target <- interval_target_rows(long, target_params = params, target_groups = target_groups)
    if (!any(target)) {
      rlang::warn(
        "No intervals matched the requested parameters and groups.  No changes made.",
        class = "pknca_warning_interval_no_target_rows"
      )
      return(intervals)
    }
    long <- long[!target, , drop = FALSE]
  }
  ret <- interval_wider(long, intervals)
  if (!add) {
    # Removing a secondary parameter also removes its reference pointer, so
    # that the result does not fail validation with a pointer to an
    # unrequested parameter.
    ret <- clear_orphan_ref_pointers(ret)
  }
  ret
}

# Move a PKNCAdata object's whole-dataset imputation into an intervals column so
# that per-parameter or per-group edits can apply to it.
interval_hoist_impute <- function(data) {
  if (!"impute" %in% names(data$intervals) &&
      !is.null(data$impute) &&
      !all(is.na(data$impute))) {
    data$intervals$impute <- data$impute
    data$impute <- NA_character_
  }
  data
}

#' Add or remove an imputation method in the intervals of a PKNCAdata object
#'
#' @param data A `PKNCAdata` object or a data.frame of intervals.
#' @param target_impute The imputation method to add or remove, as a character
#'   string (see [PKNCA_impute_method]).
#' @param after Where to insert the method within any imputation already
#'   present, following [base::append()]:  `0` makes it first and `Inf` (the
#'   default) makes it last.  A method that is already present is moved to the
#'   requested position rather than duplicated.
#' @param target_params Restrict the change to these NCA parameters.  `NULL`
#'   (the default) applies it to every parameter being calculated.
#' @param target_groups A data.frame of group values restricting the change to
#'   matching intervals.  Every column must match (and) for at least one row of
#'   `target_groups` (or).  `NULL` (the default) applies the change to all
#'   intervals.
#' @param ... Ignored.
#' @returns The input with the imputation updated.  An interval is split into
#'   more than one row when its parameters no longer share the same imputation,
#'   and rows that come to share every value are merged.
#' @seealso [interval_add_param()], [PKNCAdata()], and the vignette
#'   "Data Imputation"
#' @family Interval specifications
#' @examples
#' intervals <- data.frame(start = 0, end = 24, cmax = TRUE, half.life = TRUE)
#' # Impute a starting concentration for everything in the interval
#' interval_add_impute(intervals, target_impute = "start_conc0")
#' # ... but not for half-life, which splits the interval into two rows
#' interval_add_impute(intervals, target_impute = "start_conc0", target_params = "cmax")
#' @export
interval_add_impute <- function(data, target_impute, after = Inf, target_params = NULL,
                                target_groups = NULL, ...) {
  UseMethod("interval_add_impute", data)
}

#' @rdname interval_add_impute
#' @export
interval_remove_impute <- function(data, target_impute, target_params = NULL,
                                   target_groups = NULL, ...) {
  UseMethod("interval_remove_impute", data)
}

#' @export
interval_add_impute.data.frame <- function(data, target_impute, after = Inf,
                                           target_params = NULL, target_groups = NULL, ...) {
  interval_edit_impute(
    data, target_impute = target_impute, after = after, target_params = target_params,
    target_groups = target_groups, add = TRUE
  )
}

#' @export
interval_remove_impute.data.frame <- function(data, target_impute, target_params = NULL,
                                              target_groups = NULL, ...) {
  interval_edit_impute(
    data, target_impute = target_impute, after = Inf, target_params = target_params,
    target_groups = target_groups, add = FALSE
  )
}

#' @export
interval_add_impute.PKNCAdata <- function(data, target_impute, after = Inf,
                                          target_params = NULL, target_groups = NULL, ...) {
  data <- interval_hoist_impute(data)
  data$intervals <-
    interval_add_impute.data.frame(
      data$intervals, target_impute = target_impute, after = after,
      target_params = target_params, target_groups = target_groups
    )
  data
}

#' @export
interval_remove_impute.PKNCAdata <- function(data, target_impute, target_params = NULL,
                                             target_groups = NULL, ...) {
  if (!"impute" %in% names(data$intervals)) {
    if (is.null(data$impute) || all(is.na(data$impute))) {
      rlang::warn(
        "No imputation is specified, so there is none to remove.",
        class = "pknca_warning_interval_impute_absent"
      )
      return(data)
    }
    if (is.null(target_params) && is.null(target_groups)) {
      # The change applies everywhere, so edit the whole-dataset imputation
      data$impute <- remove_impute_method(data$impute, target_impute)
      return(data)
    }
  }
  data <- interval_hoist_impute(data)
  data$intervals <-
    interval_remove_impute.data.frame(
      data$intervals, target_impute = target_impute,
      target_params = target_params, target_groups = target_groups
    )
  data
}

#' Add or remove parameters in the intervals of a PKNCAdata object
#'
#' @inheritParams interval_add_impute
#' @param param A character vector of NCA parameter names.
#' @param param_pattern A character vector of regular expressions matching NCA
#'   parameter names.  One or both of `param` and `param_pattern` must be given.
#' @returns The input with the parameters added or removed.
#' @seealso [interval_add_impute()], [get.interval.cols()]
#' @family Interval specifications
#' @examples
#' intervals <- data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE)
#' interval_add_param(intervals, param = c("auclast", "half.life"))
#' # At least one parameter must remain, so removing every one is an error
#' interval_remove_param(intervals, param_pattern = "^tmax$")
#' @export
interval_add_param <- function(data, param = NULL, param_pattern = NULL,
                               target_groups = NULL, ...) {
  UseMethod("interval_add_param", data)
}

#' @rdname interval_add_param
#' @export
interval_remove_param <- function(data, param = NULL, param_pattern = NULL,
                                  target_groups = NULL, ...) {
  UseMethod("interval_remove_param", data)
}

#' @export
interval_add_param.data.frame <- function(data, param = NULL, param_pattern = NULL,
                                          target_groups = NULL, ...) {
  interval_edit_param(data, param, param_pattern, target_groups, add = TRUE)
}

#' @export
interval_remove_param.data.frame <- function(data, param = NULL, param_pattern = NULL,
                                             target_groups = NULL, ...) {
  interval_edit_param(data, param, param_pattern, target_groups, add = FALSE)
}

#' @export
interval_add_param.PKNCAdata <- function(data, param = NULL, param_pattern = NULL,
                                         target_groups = NULL, ...) {
  data$intervals <-
    interval_add_param.data.frame(data$intervals, param, param_pattern, target_groups)
  data
}

#' @export
interval_remove_param.PKNCAdata <- function(data, param = NULL, param_pattern = NULL,
                                            target_groups = NULL, ...) {
  data$intervals <-
    interval_remove_param.data.frame(data$intervals, param, param_pattern, target_groups)
  data
}
