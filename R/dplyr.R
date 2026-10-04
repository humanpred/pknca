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

join_maker_PKNCA <- function(join_fun) {
  function(x, y, by = NULL, copy = FALSE, suffix = c(".x", ".y"), ..., keep = FALSE) { # nocov start
    dataname <- getDataName(x)
    x[[dataname]] <- join_fun(x=x[[dataname]], y=y, by = by, copy = copy, suffix = suffix, ..., keep = keep)
    x
  } # nocov end
}
filter_PKNCA <- function(.data, ..., .preserve=FALSE) {
  dataname <- getDataName(.data)
  .data[[dataname]] <- dplyr::filter(.data[[dataname]], ..., .preserve=.preserve)
  .data
}

# Columns that the expressions of a dplyr verb name and that the table has.
# Symbols that are not columns of the table (variables of the calling
# environment, functions) are not references to the data.
filter_referenced_columns <- function(quos, table) {
  vars <- unlist(lapply(quos, function(q) all.vars(rlang::quo_get_expr(q))))
  intersect(unique(vars), names(table))
}

# Filter a slot of a PKNCAresults when it has every referenced column; a slot
# that lacks one is returned whole so that no rows are dropped by a column the
# slot does not have.
filter_results_slot <- function(slot, quos, referenced, .preserve) {
  if (all(referenced %in% names(as.data.frame(slot)))) {
    dplyr::filter(slot, !!!quos, .preserve = .preserve)
  } else {
    slot
  }
}

filter_PKNCAresults <- function(.data, ..., .preserve=FALSE) {
  quos <- rlang::enquos(...)
  referenced <- filter_referenced_columns(quos, .data$result)
  group_cols <- dplyr::group_vars(.data$data$conc)
  .data$result <- dplyr::filter(.data$result, !!!quos, .preserve = .preserve)
  # Expressions that reference a column only the result table has (or no
  # column at all) cannot be applied to the data slots.
  if (length(referenced) == 0 || !all(referenced %in% group_cols)) {
    return(.data)
  }
  .data$data$conc <-
    filter_results_slot(.data$data$conc, quos, referenced, .preserve)
  if (inherits(.data$data$dose, "PKNCAdose")) {
    .data$data$dose <-
      filter_results_slot(.data$data$dose, quos, referenced, .preserve)
  }
  if (is.data.frame(.data$data$intervals)) {
    .data$data$intervals <-
      filter_results_slot(.data$data$intervals, quos, referenced, .preserve)
  }
  .data
}
mutate_PKNCA <- function(.data, ...) {
  dataname <- getDataName(.data)
  .data[[dataname]] <- dplyr::mutate(.data[[dataname]], ...)
  .data
}
group_by_PKNCA <- function(.data, ..., .add = FALSE, .drop = dplyr::group_by_drop_default(.data)) {
  dataname <- getDataName(.data)
  .data[[dataname]] <- dplyr::group_by(.data[[dataname]], ..., .add = FALSE, .drop = .drop)
  .data
}
ungroup_PKNCA <- function(x, ...) {
  dataname <- getDataName(x)
  x[[dataname]] <- dplyr::ungroup(x[[dataname]], ...)
  x
}

#' dplyr joins for PKNCA
#'
#' @inheritParams dplyr::inner_join
#' @family dplyr verbs
#' @export
inner_join.PKNCAresults <- join_maker_PKNCA(dplyr::inner_join)
#' @rdname inner_join.PKNCAresults
#' @export
left_join.PKNCAresults <- join_maker_PKNCA(dplyr::left_join)
#' @rdname inner_join.PKNCAresults
#' @export
right_join.PKNCAresults <- join_maker_PKNCA(dplyr::right_join)
#' @rdname inner_join.PKNCAresults
#' @export
full_join.PKNCAresults <- join_maker_PKNCA(dplyr::full_join)

#' @rdname inner_join.PKNCAresults
#' @export
inner_join.PKNCAconc <- join_maker_PKNCA(dplyr::inner_join)
#' @rdname inner_join.PKNCAresults
#' @export
left_join.PKNCAconc <- join_maker_PKNCA(dplyr::left_join)
#' @rdname inner_join.PKNCAresults
#' @export
right_join.PKNCAconc <- join_maker_PKNCA(dplyr::right_join)
#' @rdname inner_join.PKNCAresults
#' @export
full_join.PKNCAconc <- join_maker_PKNCA(dplyr::full_join)

#' @rdname inner_join.PKNCAresults
#' @export
inner_join.PKNCAdose <- join_maker_PKNCA(dplyr::inner_join)
#' @rdname inner_join.PKNCAresults
#' @export
left_join.PKNCAdose <- join_maker_PKNCA(dplyr::left_join)
#' @rdname inner_join.PKNCAresults
#' @export
right_join.PKNCAdose <- join_maker_PKNCA(dplyr::right_join)
#' @rdname inner_join.PKNCAresults
#' @export
full_join.PKNCAdose <- join_maker_PKNCA(dplyr::full_join)

#' dplyr filtering for PKNCA
#'
#' Filtering a `PKNCAconc` or `PKNCAdose` object filters its data.  Filtering a
#' `PKNCAresults` object filters the result table and, when the filter only
#' uses group columns (the columns after the `|` in the `PKNCAconc` formula), the
#' concentration data, the dose data, and the intervals of `x$data` as well, so
#' that the filtered results are consistent with their data.  A filter that uses
#' any other column of the result table (such as `PPTESTCD`, `PPORRES`, or
#' `exclude`), or that uses no column of the result table, filters the result
#' table only.
#'
#' Each of the concentration data, the dose data, and the intervals is filtered
#' by the same rule: it is filtered when it has every column that the filter
#' uses, and it is left unfiltered otherwise.  For example, with a filter on
#' `part` and dose data that were not grouped by `part`, the dose data remain
#' whole; rows are never dropped by a column that the data do not have.
#' Symbols that are not columns of the result table (such as variables in the
#' calling environment) are not treated as references to the data.  The
#' expressions are evaluated separately for each table, so a filter that
#' depends on row position (such as `row_number()`) is not applied to the data
#' slots unless it also names group columns, and then it acts within each
#' table.
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
