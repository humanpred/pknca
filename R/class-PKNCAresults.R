#' Generate a PKNCAresults object
#'
#' This function should not be run directly.  The object is created for
#' summarization.
#'
#' @param result a data frame with NCA calculation results and groups. Each row
#'   is one interval and each column is a group name or the name of an NCA
#'   parameter.
#' @param data The PKNCAdata used to generate the result
#' @param exclude (optional) The name of a column with concentrations to exclude
#'   from calculations and summarization.  If given, the column should have
#'   values of `NA` or `""` for concentrations to include and non-empty text for
#'   concentrations to exclude.
#' @returns A PKNCAresults object with each of the above within.
#' @family PKNCA objects
#' @export
PKNCAresults <- function(result, data, exclude = NULL) {
  result <-
    pknca_unit_conversion(
      result = result,
      units = data$units,
      allow_partial_missing_units = data$options$allow_partial_missing_units
    )
  # Add all the parts into the object
  ret <- list(result=result,
              data=data)
  ret <- setExcludeColumn(ret, exclude = exclude, dataname = "result")
  class(ret) <- c("PKNCAresults", class(ret))
  addProvenance(ret)
}

#' Extract the parameter results from a PKNCAresults and return them as a
#' data.frame.
#'
#' @param x The object to extract results from
#' @param ... Ignored (for compatibility with generic [as.data.frame()])
#' @param out_format Should the output be 'long' (default), 'wide', or 'cdisc'?
#'   When 'cdisc', the original PKNCA parameter name is kept in a new
#'   `pknca_parameter` column (lowercase so it cannot be mistaken for an SDTM
#'   PP variable; drop it before submission), the PPTESTCD column is
#'   translated to CDISC standard codes, and a PPTEST column with the CDISC
#'   test name is added.  The translation is many-to-one -- several PKNCA
#'   parameters can resolve to the same PPTESTCD (every AUCint variant to
#'   "AUCINT", for example) -- so `pknca_parameter` is the only column that
#'   still identifies which PKNCA calculation produced a row.
#'   Route-dependent parameters (e.g. CL, VZ, MRT) are resolved using the
#'   route information from the dose data.
#'
#'   Each row also gets its time point reference, as SDTMIG 3.4 defines it:
#'   PPSTINT and PPENINT give the interval start and end as ISO 8601
#'   durations relative to the reference named in PPTPTREF, and PPRFTDTC gives
#'   that reference's date-time.  The reference is the dose that starts the
#'   interval:  the last included dose at or before the interval start for
#'   that subject and group (PPTPTREF `"LAST DOSE PRIOR TO INTERVAL"`), so a
#'   steady-state dosing interval reads `"PT0H"` to `"PT24H"`.  A subject (or
#'   group) without an included dose uses its first concentration instead
#'   (PPTPTREF `"FIRST OBSERVATION"`), as the date-time references of
#'   [PKNCAdata()] do.  The durations are in the preferred time unit
#'   (`timeu_pref`) when it is given; PPENINT is `NA` for an interval to
#'   infinity, and PPSTINT, PPENINT, and PPTPTREF are `NA` when the subject
#'   has doses but none at or before the interval start.  PPRFTDTC is only
#'   given when the concentration and dose times were date-times (see
#'   [PKNCAdata()]), and it can differ between the intervals of one subject.
#'
#'   PPGRPID, the record group identifier, is built from the grouping columns
#'   named in `grpid_cols` and the number of the row's interval, as
#'   `"<prefix1><value1>.<prefix2><value2>.I<nn>"` (for example `"A.P1.I01"`,
#'   `"P2.I01"`, or just `"I01"` without `grpid_cols`).  Within each
#'   combination of the concentration grouping columns (the subject, the
#'   analyte, and the `grpid_cols`), the intervals are numbered from 1 by start
#'   and then end; the rows of one interval (one per parameter) share the
#'   number.  The number is written with at least two digits, and with as many
#'   as the largest interval number needs, so that the text sorts in time
#'   order.  The numbers and the width come from every interval of the results,
#'   so `filter_requested` and `filter_excluded` never renumber an interval.
#'   The grouping columns also remain in the output.
#' @param filter_requested Only return rows with parameters that were
#'   specifically requested?
#' @param filter_excluded Should excluded values be removed?
#' @param grpid_cols For `out_format = "cdisc"`, the grouping columns that
#'   prefix the interval number in PPGRPID:  a named character vector of
#'   grouping columns of the [PKNCAconc()] object, in prefix order, other than
#'   the subject and the analyte.  Each name is a column, and each value is the
#'   text written before that column's value, such as
#'   `c(Part = "", Period = "P")`.  The text before a value and the values may
#'   not contain `"."`, and a value may not be empty, and distinct values of a
#'   column may not give the same text.  `NULL` (the default) uses the
#'   `grpid_cols` of the [PKNCAdata()] object, and `character()` gives an
#'   interval-only identifier regardless of that default.
#' @param grpid_numeric For `out_format = "cdisc"`, the names of columns in
#'   `grpid_cols` whose values are whole numbers of at least 1 (such as the
#'   period), which are written as that number, so `"01"` becomes `1`.  A value
#'   that is not a finite whole number of at least 1 is an error.  `NULL` (the
#'   default) uses the `grpid_numeric` of the [PKNCAdata()] object for the
#'   columns of `grpid_cols` that it names, and `character()` means no
#'   columns regardless of that default.
#' @param out.format Deprecated in favor of `out_format`
#' @returns A data.frame (or usually a tibble) of results
#' @export
as.data.frame.PKNCAresults <- function(x, ..., out_format = c('long', 'wide', 'cdisc'), filter_requested = FALSE, filter_excluded = FALSE, grpid_cols = NULL, grpid_numeric = NULL, out.format = deprecated()) {
  if (!filter_excluded) {
    ret <- x$result
  } else {
    ret <- summarize_PKNCAresults_clean_exclude(x)
    ret <- ret[is.na(ret[[x$columns$exclude]]), ]
  }
  # nocov start
  if (lifecycle::is_present(out.format)) {
    lifecycle::deprecate_warn(
      when = "0.11.0",
      what = "PKNCA::as.data.frame.PKNCAresults(out.format = )",
      with = "PKNCA::as.data.frame.PKNCAresults(out_format = )"
    )
    out_format <- out.format
  }
  # nocov end
  out_format <- match.arg(out_format)

  if (filter_requested) {
    intervals_long <-
      tidyr::pivot_longer(
        x$data$intervals,
        cols = setdiff(names(get.interval.cols()), c("start", "end")),
        names_to = "PPTESTCD",
        values_to = "keep_interval"
      )
    intervals_long_filtered <- intervals_long[intervals_long$keep_interval, , drop = FALSE]
    intervals_long_filtered$keep_interval <- NULL
    ret <-
      dplyr::inner_join(
        ret, intervals_long_filtered,
        by = intersect(names(ret), names(intervals_long_filtered))
      )
  }

  if (out_format %in% 'cdisc') {
    ret <- pknca_cdisc_translate(ret, x, grpid_cols = grpid_cols, grpid_numeric = grpid_numeric)
  } else if (out_format %in% 'wide') {
    if ("PPSTRESU" %in% names(ret)) {
      # Use standardized results
      ret$PPTESTCD <- sprintf("%s (%s)", ret$PPTESTCD, ret$PPSTRESU)
      ret$PPORRES <- ret$PPSTRES
    } else if ("PPORRESU" %in% names(ret)) {
      # Use original results
      ret$PPTESTCD <- sprintf("%s (%s)", ret$PPTESTCD, ret$PPORRESU)
    }
    # Since we moved the results into PPTESTCD and PPORRES regardless of what
    # they really are in the source data, remove the extra units and unit
    # conversion columns to allow spread to work.  The reference group of a
    # secondary result (a `<group column>_ref` twin) describes that one
    # parameter, so keeping it would split its interval's row in two.
    ref_group_cols <- intersect(paste0(names(ret), "_ref"), names(ret))
    ret <-
      ret[, setdiff(
        names(ret),
        c("PPSTRES", "PPSTRESU", "PPORRESU", "PPANMETH", ref_group_cols)
      )]
    ret <- tidyr::spread(ret, key="PPTESTCD", value="PPORRES")
  }
  ret
}

# Translate PPTESTCD to CDISC standard codes and add PPTEST column
#
# Also adds a `pknca_parameter` column carrying the original PKNCA interval
# column name (the CDISC translation is many-to-one -- several PKNCA
# parameters can resolve to the same PPTESTCD, e.g. every AUCint variant to
# "AUCINT" -- so this is the only column that still identifies which PKNCA
# calculation produced a row), and the time point reference columns of each
# row (see pknca_cdisc_add_interval_reference()) and PPGRPID (see
# pknca_cdisc_add_grpid()).
#
# `pknca_parameter` is lowercase and snake_case specifically so it cannot be
# mistaken for an SDTM PP variable (which are always uppercase); it is a
# PKNCA-internal column, not part of the CDISC standard, and downstream
# datasets built from this output should drop it before submission.
#
# @param ret The long-format result data.frame
# @param x The PKNCAresults object (for accessing dose/route data)
# @param grpid_cols,grpid_numeric See pknca_cdisc_add_grpid()
# @returns The data.frame with `pknca_parameter` added, PPTESTCD translated,
#   PPTEST added, the time point reference columns, and PPGRPID
# @keywords Internal
# @noRd
pknca_cdisc_translate <- function(ret, x, grpid_cols = NULL, grpid_numeric = NULL) {
  all_intervals <- get.interval.cols()
  # Determine route for each result row
  route_per_row <- pknca_cdisc_get_route(ret, x)
  # A PKNCAconc is entirely sparse or entirely dense, and a parameter with a
  # sparse estimator used it throughout a sparse analysis, so sparseness is
  # settled once for the whole result
  sparse <- is_sparse_pk(x)
  # Build CDISC PPTESTCD and PPTEST for each row
  pknca_parameter <- ret$PPTESTCD
  cdisc_pptestcd <- character(nrow(ret))
  cdisc_pptest <- character(nrow(ret))
  for (i in seq_len(nrow(ret))) {
    pknca_name <- ret$PPTESTCD[i]
    col_def <- all_intervals[[pknca_name]]
    if (is.null(col_def) || is.null(col_def$pptestcd_cdisc)) {
      # No mapping available, keep original
      cdisc_pptestcd[i] <- pknca_name
      cdisc_pptest[i] <- if (!is.null(col_def$desc)) col_def$desc else ""
      next
    }
    route <- route_per_row[i]
    cdisc_pptestcd[i] <- resolve_cdisc_value(col_def$pptestcd_cdisc, route, sparse = sparse)
    cdisc_pptest[i] <- resolve_cdisc_value(col_def$pptest_cdisc, route, sparse = sparse)
  }
  ret$PPTESTCD <- cdisc_pptestcd
  # Insert pknca_parameter before PPTESTCD and PPTEST after it
  pptestcd_pos <- which(names(ret) == "PPTESTCD")
  if (length(pptestcd_pos) == 1) {
    before <- ret[, seq_len(pptestcd_pos - 1), drop = FALSE]
    after <- ret[, seq(pptestcd_pos + 1, ncol(ret)), drop = FALSE]
    ret <- cbind(before, pknca_parameter = pknca_parameter, ret[, "PPTESTCD", drop = FALSE], PPTEST = cdisc_pptest, after)
  } else {
    ret$pknca_parameter <- pknca_parameter
    ret$PPTEST <- cdisc_pptest
  }
  ret <- pknca_cdisc_add_interval_reference(ret, x)
  pknca_cdisc_add_grpid(ret, x, grpid_cols = grpid_cols, grpid_numeric = grpid_numeric)
}

# The PPTPTREF text for each kind of time point reference (see
# pknca_cdisc_interval_reference())
pknca_cdisc_tptref <- c(
  dose = "LAST DOSE PRIOR TO INTERVAL",
  first_conc = "FIRST OBSERVATION"
)

# Add the time point reference columns:  PPSTINT, PPENINT, PPTPTREF, and (for
# date-time input) PPRFTDTC
#
# SDTMIG 3.4 defines PPSTINT and PPENINT as the start and end of the interval
# relative to the time point reference named by PPTPTREF, whose date-time is
# PPRFTDTC.  The reference of each row is the dose that starts its interval
# (see pknca_cdisc_interval_reference()), so all four columns describe the
# same reference and a steady-state interval reads PT0H to PT24H.
#
# PPSTINT and PPENINT are ISO 8601 durations in the preferred time unit
# (`timeu_pref`, when it can be converted to); PPENINT is NA for an interval to
# infinity, and both are NA for a row without a reference.  PPRFTDTC is only
# added when the concentration and dose times were date-times, because numeric
# times have no date-time to report.
#
# @param ret The result data.frame (already has PPTESTCD translated)
# @param x The PKNCAresults object
# @returns The data.frame with the reference columns added
# @keywords Internal
# @noRd
pknca_cdisc_add_interval_reference <- function(ret, x) {
  ref <- pknca_cdisc_interval_reference(ret, x)
  # Interval times are in the time unit of the analysis; report them in the
  # preferred one.
  timeu_report <- pknca_cdisc_get_timeu(x)
  start_rel <- (ret$start - ref$time) * timeu_report$factor
  end_rel <- (ret$end - ref$time) * timeu_report$factor
  ret$PPSTINT <- vapply(X = start_rel, FUN = format_iso8601_duration, FUN.VALUE = "", timeu = timeu_report$unit)
  ret$PPENINT <- vapply(X = end_rel, FUN = format_iso8601_duration, FUN.VALUE = "", timeu = timeu_report$unit)
  ret$PPTPTREF <- unname(pknca_cdisc_tptref[ref$type])
  time_reference <- x$data$time_reference
  if (!is.null(time_reference)) {
    # Date-time times were converted to the time unit of the analysis relative
    # to each group's time reference, so the date-time of a row's reference is
    # the group's time reference plus the reference's converted time.
    ref_groups <- setdiff(names(time_reference), c("time_reference", "time_reference_type"))
    group_reference <-
      pknca_datetime_match_reference(
        groups_data = as.data.frame(ret)[, ref_groups, drop = FALSE],
        time_reference = time_reference
      )
    seconds_per_unit <- 3600 * pknca_hours_factor(pknca_datetime_time_unit(as_PKNCAconc(x)))
    # Rounding drops the floating-point noise of the unit conversion (a second
    # dose 24 hours later must not print as 23:59:59).
    ret$PPRFTDTC <-
      lubridate::format_ISO8601(
        group_reference + round(ref$time * seconds_per_unit, 6),
        precision = "ymdhms"
      )
  }
  ret
}

# Find the time point reference of each result row
#
# The reference of a row is the dose that starts its interval:  the last
# included dose at or before the interval start, within the row's groups.  A
# row whose groups have no included dose (including all rows when there are no
# dose times) uses the first concentration of its groups instead:  the first
# included one, or the first one when all are excluded.  The groups and the
# fallback are those of the date-time references (pknca_datetime_ref_groups()
# and pknca_datetime_reference()), so for date-time input a row's reference
# type agrees with its group's `time_reference_type`.  A row whose groups have
# doses, but none at or before its start, has no reference.
#
# @param ret The result data.frame
# @param x The PKNCAresults object
# @returns A data.frame with one row per row of `ret`:  `time`, the time of the
#   reference on the same scale as `ret$start` (NA without a reference), and
#   `type`, `"dose"`, `"first_conc"`, or NA (the names of
#   `pknca_cdisc_tptref`)
# @keywords Internal
# @noRd
pknca_cdisc_interval_reference <- function(ret, x) {
  o_conc <- as_PKNCAconc(x)
  o_dose <- as_PKNCAdose(x)
  has_dose_time <-
    !is.null(o_dose) && !identical(o_dose, NA) && length(o_dose$columns$time) == 1
  groups <-
    intersect(
      pknca_datetime_ref_groups(o_conc, o_dose, has_dose_time = has_dose_time, check_subject = FALSE),
      names(ret)
    )
  rows <- as.data.frame(ret)[, groups, drop = FALSE]
  rows$.row_id <- seq_len(nrow(rows))
  rows$.start <- ret$start
  ref <- data.frame(time = rep(NA_real_, nrow(rows)), type = rep(NA_character_, nrow(rows)))
  has_dose <- rep(FALSE, nrow(rows))
  if (has_dose_time) {
    dose_data <- as.data.frame(o_dose)
    doses <- dose_data[, groups, drop = FALSE]
    doses$.dose_time <- dose_data[[o_dose$columns$time]]
    doses <- doses[is.na(normalize_exclude(o_dose)) & !is.na(doses$.dose_time), , drop = FALSE]
    # merge() with no groups pairs every row with every dose
    row_doses <- merge(rows, doses, by = groups)
    has_dose[row_doses$.row_id] <- TRUE
    prior_doses <- row_doses[row_doses$.dose_time <= row_doses$.start, , drop = FALSE]
    if (nrow(prior_doses) > 0) {
      last_dose <- stats::aggregate(.dose_time ~ .row_id, data = prior_doses, FUN = max)
      ref$time[last_dose$.row_id] <- last_dose$.dose_time
      ref$type[last_dose$.row_id] <- "dose"
    }
  }
  if (!all(has_dose)) {
    conc_data <- as.data.frame(o_conc)
    concs <- conc_data[, groups, drop = FALSE]
    concs$time_reference <- conc_data[[o_conc$columns$time]]
    mask_time <- !is.na(concs$time_reference)
    first_conc <-
      pknca_datetime_first_included(
        concs[mask_time, , drop = FALSE],
        groups,
        included = is.na(normalize_exclude(o_conc))[mask_time]
      )
    ref$time[!has_dose] <-
      pknca_datetime_match_reference(rows[!has_dose, groups, drop = FALSE], first_conc)
    ref$type[!has_dose & !is.na(ref$time)] <- "first_conc"
  }
  ref
}

# Get the time unit for ISO 8601 formatting and the factor converting interval
# times (which are in the original time unit, timeu) to it
#
# The unit is timeu_pref when it is set and timeu can be converted to it, and
# otherwise timeu.
#
# @param x The PKNCAresults object
# @returns A list with `unit`, a character string with the time unit (e.g.
#   "hr", "min", "day") or NA_character_ if not set, and `factor`, the number
#   that interval times are multiplied by to express them in `unit`
# @keywords Internal
# @noRd
pknca_cdisc_get_timeu <- function(x) {
  timeu <- pknca_cdisc_get_timeu_orig(x)
  timeu_pref <- x$data$conc$units$timeu_pref
  factor <-
    if (is.null(timeu_pref) || is.na(timeu_pref)) {
      NA_real_
    } else {
      pknca_unit_reconcile_factor(from = timeu, to = timeu_pref)
    }
  if (is.na(factor)) {
    list(unit = timeu, factor = 1)
  } else {
    list(unit = as.vector(timeu_pref), factor = factor)
  }
}

# Get the original time unit (timeu) of the concentration data
#
# @param x The PKNCAresults object
# @returns A character string with the time unit or NA_character_ if not set
#   (or not the same for all concentration data)
# @keywords Internal
# @noRd
pknca_cdisc_get_timeu_orig <- function(x) {
  if (is.null(x$data$conc) || !inherits(x$data$conc, "PKNCAconc")) {
    return(NA_character_)
  }
  timeu <- x$data$conc$units$timeu
  if (!is.null(timeu) && !is.na(timeu)) {
    return(as.vector(timeu))
  }
  # Check if timeu is stored as a column attribute
  timeu_col <- x$data$conc$columns$timeu
  if (!is.null(timeu_col) && length(timeu_col) > 0) {
    # Column-based: take the first value
    vals <- unique(x$data$conc$data[[timeu_col]])
    vals <- vals[!is.na(vals)]
    if (length(vals) == 1) return(vals)
  }
  NA_character_
}

# Format a numeric duration as an ISO 8601 duration string
#
# A negative duration (an interval that starts before its time point
# reference, as one can before a first observation) takes a leading minus sign,
# the ISO 8601-2 form SDTM uses ("-PT0.5H").
#
# @param value Numeric duration value
# @param timeu The time unit (e.g. "hr", "h", "min", "day", "d", "s", "sec")
# @returns An ISO 8601 duration string (e.g. "PT0H", "PT24H", "P1D")
# @keywords Internal
# @noRd
format_iso8601_duration <- function(value, timeu) {
  if (is.na(value) || is.infinite(value)) return(NA_character_)
  # Unit conversion leaves floating-point noise (120 minutes as
  # 1.9999999999999998 hours) that must not reach the text.
  value <- round(value, 10)
  sign <- if (value < 0) "-" else ""
  # format() rather than as.character(), which writes 100000 as "1e+05"
  value <- format(abs(value), scientific = FALSE, digits = 15, trim = TRUE)
  timeu_lower <- tolower(timeu)
  if (is.na(timeu_lower)) {
    # No unit info: assume hours
    timeu_lower <- "hr"
  }
  # Map time unit to ISO 8601 designator
  if (timeu_lower %in% c("hr", "h", "hour", "hours")) {
    paste0(sign, "PT", value, "H")
  } else if (timeu_lower %in% c("min", "minute", "minutes")) {
    paste0(sign, "PT", value, "M")
  } else if (timeu_lower %in% c("s", "sec", "second", "seconds")) {
    paste0(sign, "PT", value, "S")
  } else if (timeu_lower %in% c("day", "days", "d")) {
    paste0(sign, "P", value, "D")
  } else {
    # Unknown unit: default to hours
    paste0(sign, "PT", value, "H")
  }
}

# Resolve a CDISC value that may be a simple string, a route-dependent list, or
# a list keyed by whether the analysis is sparse
#
# @param value A character string, a list with a "route" element, or a list
#   with exactly the elements "dense" and "sparse"
# @param route The route for the current row ("extravascular" or "intravascular")
# @param sparse Is the analysis sparse PK?  A parameter with a sparse estimator
#   used it for every row of a sparse analysis, so this is a property of the
#   analysis rather than of the row.
# @returns A character string with the resolved CDISC value
# @keywords Internal
# @noRd
resolve_cdisc_value <- function(value, route, sparse = FALSE) {
  if (is.character(value)) {
    return(value)
  }
  if (is.list(value) && setequal(names(value), c("dense", "sparse"))) {
    return(value[[if (isTRUE(sparse)) "sparse" else "dense"]])
  }
  if (is.list(value) && !is.null(value$route)) {
    route_lower <- tolower(route)
    if (route_lower %in% names(value$route)) {
      return(value$route[[route_lower]])
    }
    # Default to first element (extravascular) if route not found
    return(value$route[[1]])
  }
  # Fallback
  as.character(value)
}

# Get the route of administration for each row in the results
#
# @param ret The long-format result data.frame
# @param x The PKNCAresults object
# @returns A character vector of routes, one per row
# @keywords Internal
# @noRd
pknca_cdisc_get_route <- function(ret, x) {
  default_route <- "extravascular"
  # Check if dose data is available
  if (is.null(x$data$dose) || identical(x$data$dose, NA) ||
      !inherits(x$data$dose, "PKNCAdose")) {
    return(rep(default_route, nrow(ret)))
  }
  route_data <- getAttributeColumn(
    object = x$data$dose, attr_name = "route", warn_missing = character()
  )
  if (is.null(route_data)) {
    return(rep(default_route, nrow(ret)))
  }
  # Get the dose data with route and group columns
  dose_df <- x$data$dose$data
  route_col <- x$data$dose$columns$route
  group_cols <- unlist(x$data$dose$columns$groups)
  # If route is a scalar (same for all), return it for all rows
  if (length(unique(route_data[[1]])) == 1) {
    return(rep(tolower(route_data[[1]][1]), nrow(ret)))
  }
  # Route varies by group: merge with results on group columns
  # Use only group columns that exist in both datasets
  merge_cols <- intersect(group_cols, names(ret))
  if (length(merge_cols) == 0) {
    return(rep(default_route, nrow(ret)))
  }
  # Get unique route per group combination
  dose_route <- unique(dose_df[, c(merge_cols, route_col), drop = FALSE])
  names(dose_route)[names(dose_route) == route_col] <- ".route_cdisc"
  merged <- merge(
    data.frame(.row_id = seq_len(nrow(ret)), ret[, merge_cols, drop = FALSE]),
    dose_route,
    by = merge_cols,
    all.x = TRUE,
    sort = FALSE
  )
  merged <- merged[order(merged$.row_id), ]
  routes <- tolower(as.character(merged$.route_cdisc))
  routes[is.na(routes)] <- default_route
  routes
}

#' @rdname getDataName
#' @export
getDataName.PKNCAresults <- function(object) {
  "result"
}

#' @rdname is_sparse_pk
#' @export
is_sparse_pk.PKNCAresults <- function(object) {
  is_sparse_pk(object$data)
}

#' @rdname getGroups.PKNCAconc
#' @export
getGroups.PKNCAresults <- function(object,
                                   form=formula(object$data$conc), level,
                                   data=object$result, sep) {
  # Include the start time as a group; this may be dropped later
  grpnames <- c(unlist(object$data$conc$columns$groups), "start", "end")
  if (is_sparse_pk(object)) {
    grpnames <- setdiff(grpnames, object$data$conc$columns$subject)
  }
  if (!missing(level))
    if (is.factor(level) || is.character(level)) {
      level <- as.character(level)
      if (any(!(level %in% grpnames))) {
        rlang::abort(
          sprintf(
            "Not all levels are listed in the group names. Missing levels are: %s",
            paste(setdiff(level, grpnames), collapse = ", ")
          ),
          class = "pknca_error_results_missing_group_levels"
        )
      }
      grpnames <- level
    } else if (is.numeric(level)) {
      if (length(level) == 1) {
        grpnames <- grpnames[1:level]
      } else {
        grpnames <- grpnames[level]
      }
    }
  data[, grpnames, drop=FALSE]
}

#' @describeIn group_vars.PKNCAconc Get group_vars for a PKNCAresults object
#'   from the PKNCAconc object within
#' @exportS3Method dplyr::group_vars
group_vars.PKNCAresults <- function(x) {
  c("start","end",group_vars.PKNCAconc(as_PKNCAconc(x))) 
}
