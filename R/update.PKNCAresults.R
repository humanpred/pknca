#' Update existing PKNCAresults with new data
#'
#' The only thing that can change in the update is the concentration or dose
#' data. All other items (column definitions, etc) must remain the same. If
#' options are not set in `data`, then the default PKNCA options will be
#' considered identical.
#'
#' If more than the allowed settings change, then a full recalculation will
#' occur.
#'
#' This function is typically used with Shiny apps which may repeat analyses
#' with small changes (e.g. point exclusion).
#'
#' @param object The PKNCAresults data
#' @param data The new PKNCAdata object
#' @param ... Ignored
#' @returns The PKNCAresults with updated new data
#' @export
update.PKNCAresults <- function(object, data, ...) {
  # Ensure that the right types of inputs are given
  assert_PKNCAresults(object)
  assert_PKNCAdata(data)
  if (length(data$options) == 0) {
    data$options <- PKNCA.options()
  }
  if (identical(as_PKNCAdata(object), data)) {
    message("No changes detected in data")
    return(object)
  }
  if (!identical(strip_source_data(as_PKNCAdata(object)), strip_source_data(data))) {
    warning("Full recalculation: changes detected in data other than source concentration or dose data")
    return(pk.nca(data))
  }
  # detect changed groups
  groups_changed <- find_changed_group(old = as_PKNCAdata(object), new = data)
  if ((nrow(groups_changed$conc) + nrow(groups_changed$dose)) == 0) {
    # The data differ (e.g. group order), but no group's data changed, so the
    # results are unchanged.
    message("No changes detected within any group; keeping existing results")
    ret <- object
    ret$data <- data
    return(addProvenance(ret, replace = TRUE))
  }
  conc_changed <- filter_changed(as.data.frame(as_PKNCAconc(data)), changed = groups_changed)
  dose_changed <- filter_changed(as.data.frame(as_PKNCAdose(data)), changed = groups_changed)
  intervals_changed <- filter_changed(data$intervals, changed = groups_changed)
  # insert the changed data into the old data as new data!  The intervals are
  # filtered to the changed groups, too, so that unchanged groups are not
  # calculated and do not warn about their (intentionally) missing
  # concentration data.
  data_new <- data
  data_new$conc$data <- conc_changed
  data_new$dose$data <- dose_changed
  data_new$intervals <- intervals_changed
  result_new <- pk.nca(data_new)
  result_new_df <- as.data.frame(result_new)
  result_old_df <- as.data.frame(object)
  drop_old_groups <- unique(getGroups(result_new))
  result_old_df_keep <-
    anti_join_by_value(result_old_df, drop_old_groups, by = names(drop_old_groups))
  ret <- object
  ret$data <- data
  ret$result <- rbind(result_old_df_keep, result_new_df)
  addProvenance(ret, replace = TRUE)
}

#' Convert factor join-key columns to character so that joins match by value
#'
#' Factor group columns can differ in their levels between the old and new data
#' (e.g. ordered factors after re-leveling or dropping levels), and dplyr joins
#' error on factors with mismatched levels rather than matching by value.  The
#' coerced data are only used for matching; the data returned to the user keep
#' their original classes and factor levels.
#'
#' @param data A data.frame
#' @param cols Column names to coerce when they are factors
#' @returns `data` with any factor columns in `cols` converted to character
#' @noRd
coerce_factor_join_keys <- function(data, cols) {
  for (nm in cols) {
    if (is.factor(data[[nm]])) {
      data[[nm]] <- as.character(data[[nm]])
    }
  }
  data
}

#' `dplyr::anti_join()` matching factor key columns by value, not by levels
#'
#' @param x,y Data.frames to anti-join
#' @param by Column names to join by
#' @returns The rows of `x` (unmodified, in their original order) that have no
#'   match in `y`
#' @noRd
anti_join_by_value <- function(x, y, by) {
  rowid_col <- paste0(max(names(x)), "X")
  tracking <- coerce_factor_join_keys(x, cols = by)
  tracking[[rowid_col]] <- seq_len(nrow(x))
  kept <- dplyr::anti_join(tracking, coerce_factor_join_keys(y, cols = by), by = by)
  x[kept[[rowid_col]], , drop = FALSE]
}

# remove the original data.frames from the source data to enable comparison for
# updates
strip_source_data <- function(data) {
  assert_PKNCAdata(data)
  ret <- data
  # These are no longer valid PKNCAconc or PKNCAdose objects
  ret$conc$data <- NULL
  ret$dose$data <- NULL
  ret
}

#' Find subject identifiers that have changes
#' @param old,new Two PKNCAconc, PKNCAdose, or PKNCAdata objects (must be the
#'   same class)
#' @returns A data.frame of groups that have changed (PKNCAconc or PKNCAdose) or
#'   a list of data.frames (PKNCAdata)
#' @noRd
find_changed_group <- function(old, new) {
  stopifnot(all(class(old) == class(new)))
  if (inherits(old, "PKNCAdata")) {
    # Find subjects that changed (for PKNCAdata by going into conc and dose)
    list(
      conc = find_changed_group(old = as_PKNCAconc(old), new = as_PKNCAconc(new)),
      dose = find_changed_group(old = as_PKNCAdose(old), new = as_PKNCAdose(new))
    )
  } else {
    # Find subjects that changed (for PKNCAconc or PKNCAdose).  Group columns
    # are matched by value (factors as character) so that factor level
    # differences between the old and new data do not prevent joining.
    group_col <- unlist(old$columns$groups, use.names = FALSE)
    d_nest_old <-
      tidyr::nest(
        coerce_factor_join_keys(old$data, cols = group_col),
        data_old = !tidyr::all_of(group_col)
      )
    d_nest_new <-
      tidyr::nest(
        coerce_factor_join_keys(new$data, cols = group_col),
        data_new = !tidyr::all_of(group_col)
      )
    d_nest_combo <- dplyr::full_join(d_nest_old, d_nest_new, by = group_col)
    mask_changed_id <-
      vapply(
        X = seq_len(nrow(d_nest_combo)),
        FUN = function(idx) !identical(d_nest_combo$data_old[[idx]], d_nest_combo$data_new[[idx]]),
        FUN.VALUE = TRUE
      )
    # Find the unique set of groups that changed
    unique(d_nest_combo[mask_changed_id, group_col, drop = FALSE])
  }
}

filter_changed <- function(data, changed) {
  rowid_col <- paste0(max(names(data)), "X")
  tracking <- data
  tracking[[rowid_col]] <- seq_len(nrow(data))
  # Find rows that are of interest from concentration or dose
  tracking_conc <- filter_changed_inner_join(tracking, changed$conc)
  tracking_dose <- filter_changed_inner_join(tracking, changed$dose)
  # filter to rows of interest
  ret <- tracking[tracking[[rowid_col]] %in% c(tracking_conc[[rowid_col]], tracking_dose[[rowid_col]]), ]
  ret[, names(data)]
}

filter_changed_inner_join <- function(data, changed) {
  by_cols <- intersect(names(data), names(changed))
  if (nrow(changed) == 0) {
    # Return a zero-row data.frame if nothing changed
    data[0,]
  } else if (length(by_cols) == 0) {
    # Return all the data if there is not an intersection in column names
    data
  } else {
    # Match by value (factors as character) so that factor level differences do
    # not prevent joining.  The result is only used for row selection, so the
    # coercion does not affect the data returned by filter_changed().
    dplyr::inner_join(
      coerce_factor_join_keys(data, cols = by_cols),
      coerce_factor_join_keys(changed, cols = by_cols),
      by = by_cols
    )
  }
}
