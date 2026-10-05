#' @importFrom dplyr inner_join
#' @export
dplyr::inner_join
#' @importFrom dplyr left_join
#' @export
dplyr::left_join
#' @importFrom dplyr right_join
#' @export
dplyr::right_join
#' @importFrom dplyr full_join
#' @export
dplyr::full_join

#' @importFrom dplyr filter
#' @export
dplyr::filter

#' @importFrom dplyr group_by
#' @export
dplyr::group_by

#' @importFrom dplyr ungroup
#' @export
dplyr::ungroup

#' @importFrom dplyr mutate
#' @export
dplyr::mutate

join_maker_PKNCA <- function(join_fun, verb) {
  function(x, y, by = NULL, copy = FALSE, suffix = c(".x", ".y"), ..., keep = FALSE) { # nocov start
    dataname <- getDataName(x)
    ret <- x
    ret[[dataname]] <- join_fun(x=x[[dataname]], y=y, by = by, copy = copy, suffix = suffix, ..., keep = keep)
    mark_provenance_modified(ret, x, verb)
  } # nocov end
}
filter_PKNCA <- function(.data, ..., .by = NULL, .preserve=FALSE) {
  dataname <- getDataName(.data)
  ret <- .data
  ret[[dataname]] <- dplyr::filter(.data[[dataname]], ..., .by = {{ .by }}, .preserve=.preserve)
  mark_provenance_modified(ret, .data, "filtered")
}

# Columns that the expressions of a dplyr verb name and that the table has.
# Symbols that are not columns of the table (variables of the calling
# environment, functions) are not references to the data.  The `.by` argument
# is one of the expressions, so its columns count as referenced.
filter_referenced_columns <- function(quos, table) {
  vars <- unlist(lapply(quos, function(q) all.vars(rlang::quo_get_expr(q))))
  intersect(unique(vars), names(table))
}

# Functions that choose columns by name or by selection helper; the columns
# they choose cannot be known from the expression.
filter_indirect_functions <- c(
  "across", "if_any", "if_all", "pick", "c_across", "all_of", "any_of",
  "starts_with", "ends_with", "contains", "matches", "everything", "last_col",
  "num_range", "where", "one_of"
)

# Does the expression choose columns without naming them as symbols
# (`.data[[var]]` or a tidyselect helper)?
filter_expr_is_indirect <- function(expr) {
  if (!is.call(expr)) {
    return(FALSE)
  }
  head <- expr[[1]]
  if (is.call(head) && as.character(head[[1]])[1] %in% c("::", ":::")) {
    head <- head[[3]]
  }
  if (is.symbol(head)) {
    fun_name <- as.character(head)
    if (fun_name %in% filter_indirect_functions) {
      return(TRUE)
    }
    if (fun_name == "[[" && length(expr) >= 2 && identical(expr[[2]], quote(.data))) {
      return(TRUE)
    }
  }
  for (idx in seq_along(expr)) {
    child <- expr[[idx]]
    # Skip empty arguments, as in x[1, ]
    if (!identical(child, quote(expr = )) && filter_expr_is_indirect(child)) {
      return(TRUE)
    }
  }
  FALSE
}

# Keep the rows of a slot's table whose values in the columns shared with
# `keep` (the groups that survived the filter) are in `keep`.  A slot that
# shares no column with `keep` is returned whole.
filter_results_slot <- function(slot, keep) {
  dataname <- getDataName(slot)
  tbl <- if (is.null(dataname)) slot else slot[[dataname]]
  shared <- intersect(names(keep), names(tbl))
  if (length(shared) == 0) {
    return(slot)
  }
  kept <- semi_join_by_value(tbl, unique(keep[, shared, drop = FALSE]), by = shared)
  if (is.null(dataname)) {
    kept
  } else {
    slot[[dataname]] <- kept
    slot
  }
}

filter_PKNCAresults <- function(.data, ..., .by = NULL, .preserve=FALSE) {
  by_quo <- rlang::enquo(.by)
  quos <- c(rlang::enquos(...), list(by_quo))
  referenced <- filter_referenced_columns(quos, .data$result)
  group_cols <- dplyr::group_vars(.data$data$conc)
  indirect <- any(vapply(quos, function(q) filter_expr_is_indirect(rlang::quo_get_expr(q)), logical(1)))
  if (indirect) {
    rlang::inform(
      "The filter chooses columns with .data[[]] or a tidyselect helper; only the result table was filtered, not the concentration data, dose data, or intervals.",
      class = "pknca_message_filter_indirect_columns"
    )
  }
  ret <- .data
  ret$result <- dplyr::filter(
    .data$result, ..., .by = !!by_quo, .preserve = .preserve
  )
  # A filter that uses a column only the result table has (or no column at
  # all) cannot be applied to the data slots.  Otherwise the filter is
  # evaluated once, on the results, and the data slots keep the groups that
  # survived.
  if (!indirect && length(referenced) > 0 && all(referenced %in% group_cols)) {
    keep <- ret$result[, intersect(group_cols, names(ret$result)), drop = FALSE]
    ret$data$conc <- filter_results_slot(.data$data$conc, keep)
    if (inherits(.data$data$dose, "PKNCAdose")) {
      ret$data$dose <- filter_results_slot(.data$data$dose, keep)
    }
    if (is.data.frame(.data$data$intervals)) {
      ret$data$intervals <- filter_results_slot(.data$data$intervals, keep)
    }
  }
  mark_provenance_modified(ret, .data, "filtered")
}
mutate_PKNCA <- function(.data, ...) {
  dataname <- getDataName(.data)
  ret <- .data
  ret[[dataname]] <- dplyr::mutate(.data[[dataname]], ...)
  mark_provenance_modified(ret, .data, "mutated")
}
group_by_PKNCA <- function(.data, ..., .add = FALSE, .drop = dplyr::group_by_drop_default(.data)) {
  dataname <- getDataName(.data)
  ret <- .data
  ret[[dataname]] <- dplyr::group_by(.data[[dataname]], ..., .add = FALSE, .drop = .drop)
  mark_provenance_modified(ret, .data, "grouped")
}
ungroup_PKNCA <- function(x, ...) {
  dataname <- getDataName(x)
  ret <- x
  ret[[dataname]] <- dplyr::ungroup(x[[dataname]], ...)
  mark_provenance_modified(ret, x, "ungrouped")
}

#' dplyr joins for PKNCA
#'
#' @inheritParams dplyr::inner_join
#' @family dplyr verbs
#' @export
inner_join.PKNCAresults <- join_maker_PKNCA(dplyr::inner_join, "inner-joined")
#' @rdname inner_join.PKNCAresults
#' @export
left_join.PKNCAresults <- join_maker_PKNCA(dplyr::left_join, "left-joined")
#' @rdname inner_join.PKNCAresults
#' @export
right_join.PKNCAresults <- join_maker_PKNCA(dplyr::right_join, "right-joined")
#' @rdname inner_join.PKNCAresults
#' @export
full_join.PKNCAresults <- join_maker_PKNCA(dplyr::full_join, "full-joined")

#' @rdname inner_join.PKNCAresults
#' @export
inner_join.PKNCAconc <- join_maker_PKNCA(dplyr::inner_join, "inner-joined")
#' @rdname inner_join.PKNCAresults
#' @export
left_join.PKNCAconc <- join_maker_PKNCA(dplyr::left_join, "left-joined")
#' @rdname inner_join.PKNCAresults
#' @export
right_join.PKNCAconc <- join_maker_PKNCA(dplyr::right_join, "right-joined")
#' @rdname inner_join.PKNCAresults
#' @export
full_join.PKNCAconc <- join_maker_PKNCA(dplyr::full_join, "full-joined")

#' @rdname inner_join.PKNCAresults
#' @export
inner_join.PKNCAdose <- join_maker_PKNCA(dplyr::inner_join, "inner-joined")
#' @rdname inner_join.PKNCAresults
#' @export
left_join.PKNCAdose <- join_maker_PKNCA(dplyr::left_join, "left-joined")
#' @rdname inner_join.PKNCAresults
#' @export
right_join.PKNCAdose <- join_maker_PKNCA(dplyr::right_join, "right-joined")
#' @rdname inner_join.PKNCAresults
#' @export
full_join.PKNCAdose <- join_maker_PKNCA(dplyr::full_join, "full-joined")

#' dplyr filtering for PKNCA
#'
#' Filtering a `PKNCAconc` or `PKNCAdose` object filters its data.  Filtering a
#' `PKNCAresults` object filters the result table and, when the filter only
#' uses group columns (the columns after the `|` in the `PKNCAconc` formula), the
#' concentration data, the dose data, and the intervals of `x$data` as well, so
#' that the filtered results are consistent with their data.  Only those three
#' are filtered; `group_ref` and `units` of the `PKNCAdata` are not.
#'
#' The filter is evaluated once, on the result table.  The groups that remain
#' there are the groups kept: the rows of the concentration data, dose data, and
#' intervals are kept when their values in the group columns that they share
#' with the result table match a remaining group.  A table that has none of
#' those group columns (for example, intervals with no group columns) is left
#' whole, and groups that have no rows in the result table are dropped from the
#' data.  Because the filter is evaluated only on the results, any filter that
#' aggregates over rows (such as `ID == max(ID)`) keeps the same groups in every
#' table.
#'
#' A filter that uses any other column of the result table (such as `PPTESTCD`,
#' `PPORRES`, or `exclude`), or that uses no column of the result table, filters
#' the result table only.  Columns are recognized when the expressions name them
#' (`part == "SAD"`, `.data$part == "SAD"`, and the columns of `.by`).
#' Variables of the calling environment are not treated as columns.  Filters
#' that choose columns without naming them (`.data[[var]]`, `across()`,
#' `if_any()`, `if_all()`, `pick()`, and tidyselect helpers such as `all_of()`
#' or `starts_with()`) filter the result table only, with a message that the
#' data were not filtered.  The columns `start` and `end` belong to the result
#' table, so a filter on them leaves the data unchanged.
#'
#' `mutate()` and the joins change only the result table; assigning into the
#' object directly is the caller's responsibility and is not tracked.
#'
#' A `PKNCAresults` object that a PKNCA dplyr verb changes (`filter()`,
#' `mutate()`, `group_by()`, `ungroup()`, and the joins) no longer matches the
#' hash that [checkProvenance()] verifies: the hash is replaced by a marker such
#' as `"filtered from <hash>"` and [checkProvenance()] returns `FALSE`.  A call
#' that leaves the object identical keeps its provenance.
#'
#' @inheritParams dplyr::filter
#' @family dplyr verbs
#' @export
filter.PKNCAresults <- filter_PKNCAresults
#' @rdname filter.PKNCAresults
#' @export
filter.PKNCAconc <- filter_PKNCA
#' @rdname filter.PKNCAresults
#' @export
filter.PKNCAdose <- filter_PKNCA

#' dplyr mutate-based modification for PKNCA
#'
#' @inheritParams dplyr::mutate
#' @family dplyr verbs
#' @export
mutate.PKNCAresults <- mutate_PKNCA
#' @rdname mutate.PKNCAresults
#' @export
mutate.PKNCAconc <- mutate_PKNCA
#' @rdname mutate.PKNCAresults
#' @export
mutate.PKNCAdose <- mutate_PKNCA

#' dplyr grouping for PKNCA
#'
#' @inheritParams dplyr::group_by
#' @family dplyr verbs
#' @export
group_by.PKNCAresults <- group_by_PKNCA
#' @rdname group_by.PKNCAresults
#' @export
group_by.PKNCAconc <- group_by_PKNCA
#' @rdname group_by.PKNCAresults
#' @export
group_by.PKNCAdose <- group_by_PKNCA
#' @rdname group_by.PKNCAresults
#' @inheritParams dplyr::ungroup
#' @export
ungroup.PKNCAresults <- ungroup_PKNCA
#' @rdname group_by.PKNCAresults
#' @export
ungroup.PKNCAconc <- ungroup_PKNCA
#' @rdname group_by.PKNCAresults
#' @export
ungroup.PKNCAdose <- ungroup_PKNCA
