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
#'   When 'cdisc', the PPTESTCD column is translated to CDISC standard codes
#'   and a PPTEST column with the CDISC test name is added.  Route-dependent
#'   parameters (e.g. CL, VZ, MRT) are resolved using the route information
#'   from the dose data.
#' @param filter_requested Only return rows with parameters that were
#'   specifically requested?
#' @param filter_excluded Should excluded values be removed?
#' @param out.format Deprecated in favor of `out_format`
#' @returns A data.frame (or usually a tibble) of results
#' @export
as.data.frame.PKNCAresults <- function(x, ..., out_format = c('long', 'wide', 'cdisc'), filter_requested = FALSE, filter_excluded = FALSE, out.format = deprecated()) {
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
    ret <- pknca_cdisc_translate(ret, x)
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
    # conversion columns to allow spread to work.
    ret <- ret[, setdiff(names(ret), c("PPSTRES", "PPSTRESU", "PPORRESU", "PPANMETH"))]
    ret <- tidyr::spread(ret, key="PPTESTCD", value="PPORRES")
  }
  ret
}

# Translate PPTESTCD to CDISC standard codes and add PPTEST column
#
# Also adds PPSTINT and PPENINT columns (ISO 8601 durations relative to the
# last dose time) when any resolved PPTESTCD contains "INT".
#
# @param ret The long-format result data.frame
# @param x The PKNCAresults object (for accessing dose/route data)
# @returns The data.frame with PPTESTCD translated and PPTEST added
# @keywords Internal
# @noRd
pknca_cdisc_translate <- function(ret, x) {
  all_intervals <- get.interval.cols()
  # Determine route for each result row
  route_per_row <- pknca_cdisc_get_route(ret, x)
  # Build CDISC PPTESTCD and PPTEST for each row
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
    cdisc_pptestcd[i] <- resolve_cdisc_value(col_def$pptestcd_cdisc, route)
    cdisc_pptest[i] <- resolve_cdisc_value(col_def$pptest_cdisc, route)
  }
  ret$PPTESTCD <- cdisc_pptestcd
  # Insert PPTEST after PPTESTCD
  pptestcd_pos <- which(names(ret) == "PPTESTCD")
  if (length(pptestcd_pos) == 1) {
    before <- ret[, seq_len(pptestcd_pos), drop = FALSE]
    after <- ret[, seq(pptestcd_pos + 1, ncol(ret)), drop = FALSE]
    ret <- cbind(before, PPTEST = cdisc_pptest, after)
  } else {
    ret$PPTEST <- cdisc_pptest
  }
  # Add PPSTINT/PPENINT if any PPTESTCD contains "INT"
  has_int <- grepl("INT", cdisc_pptestcd, fixed = TRUE)
  if (any(has_int)) {
    ret <- pknca_cdisc_add_interval_columns(ret, x, has_int)
  }
  ret
}

# Add PPSTINT and PPENINT columns for interval-based parameters
#
# These columns express the interval start and end as ISO 8601 durations
# relative to the last dose time for each subject/group.
#
# @param ret The result data.frame (already has PPTESTCD translated)
# @param x The PKNCAresults object
# @param has_int Logical vector indicating which rows have INT parameters
# @returns The data.frame with PPSTINT and PPENINT columns added
# @keywords Internal
# @noRd
pknca_cdisc_add_interval_columns <- function(ret, x, has_int) {
  timeu <- pknca_cdisc_get_timeu(x)
  last_dose_times <- pknca_cdisc_get_last_dose_time(ret, x)
  ppstint <- rep(NA_character_, nrow(ret))
  ppenint <- rep(NA_character_, nrow(ret))
  for (i in which(has_int)) {
    dose_time <- last_dose_times[i]
    if (is.na(dose_time)) next
    start_rel <- ret$start[i] - dose_time
    end_rel <- ret$end[i] - dose_time
    ppstint[i] <- format_iso8601_duration(start_rel, timeu)
    ppenint[i] <- format_iso8601_duration(end_rel, timeu)
  }
  ret$PPSTINT <- ppstint
  ret$PPENINT <- ppenint
  ret
}

# Get the time unit string for ISO 8601 formatting
#
# Uses timeu_pref if available, otherwise timeu.
#
# @param x The PKNCAresults object
# @returns A character string with the time unit (e.g. "hr", "min", "day"),
#   or NA_character_ if not set
# @keywords Internal
# @noRd
pknca_cdisc_get_timeu <- function(x) {
  if (is.null(x$data$conc) || !inherits(x$data$conc, "PKNCAconc")) {
    return(NA_character_)
  }
  # Prefer timeu_pref, fall back to timeu
  timeu_pref <- x$data$conc$units$timeu_pref
  if (!is.null(timeu_pref) && !is.na(timeu_pref)) {
    return(timeu_pref)
  }
  timeu <- x$data$conc$units$timeu
  if (!is.null(timeu) && !is.na(timeu)) {
    return(timeu)
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
# @param value Numeric duration value
# @param timeu The time unit (e.g. "hr", "h", "min", "day", "d", "s", "sec")
# @returns An ISO 8601 duration string (e.g. "PT0H", "PT24H", "P1D")
# @keywords Internal
# @noRd
format_iso8601_duration <- function(value, timeu) {
  if (is.na(value) || is.infinite(value)) return(NA_character_)
  timeu_lower <- tolower(timeu)
  if (is.na(timeu_lower)) {
    # No unit info: assume hours
    timeu_lower <- "hr"
  }
  # Map time unit to ISO 8601 designator
  if (timeu_lower %in% c("hr", "h", "hour", "hours")) {
    paste0("PT", value, "H")
  } else if (timeu_lower %in% c("min", "minute", "minutes")) {
    paste0("PT", value, "M")
  } else if (timeu_lower %in% c("s", "sec", "second", "seconds")) {
    paste0("PT", value, "S")
  } else if (timeu_lower %in% c("day", "days", "d")) {
    paste0("P", value, "D")
  } else {
    # Unknown unit: default to hours
    paste0("PT", value, "H")
  }
}

# Get the last dose time for each row in the results
#
# For each result row, finds the most recent dose time that is <= the interval
# start, matching on group variables.
#
# @param ret The result data.frame
# @param x The PKNCAresults object
# @returns A numeric vector of last dose times, one per row (NA if unavailable)
# @keywords Internal
# @noRd
pknca_cdisc_get_last_dose_time <- function(ret, x) {
  result <- rep(NA_real_, nrow(ret))
  if (is.null(x$data$dose) || identical(x$data$dose, NA) ||
      !inherits(x$data$dose, "PKNCAdose")) {
    return(result)
  }
  dose_df <- x$data$dose$data
  time_col <- x$data$dose$columns$time
  if (length(time_col) == 0) return(result)
  group_cols <- unlist(x$data$dose$columns$groups)
  merge_cols <- intersect(group_cols, names(ret))
  for (i in seq_len(nrow(ret))) {
    interval_start <- ret$start[i]
    # Filter dose data to matching groups
    dose_subset <- dose_df
    if (length(merge_cols) > 0) {
      mask <- rep(TRUE, nrow(dose_subset))
      for (gc in merge_cols) {
        mask <- mask & (dose_subset[[gc]] == ret[[gc]][i])
      }
      dose_subset <- dose_subset[mask, , drop = FALSE]
    }
    # Find the last dose time <= interval start
    dose_times <- dose_subset[[time_col]]
    valid_times <- dose_times[!is.na(dose_times) & dose_times <= interval_start]
    if (length(valid_times) > 0) {
      result[i] <- max(valid_times)
    }
  }
  result
}

# Resolve a CDISC value that may be a simple string or a route-dependent list
#
# @param value A character string or a list with a "route" element
# @param route The route for the current row ("extravascular" or "intravascular")
# @returns A character string with the resolved CDISC value
# @keywords Internal
# @noRd
resolve_cdisc_value <- function(value, route) {
  if (is.character(value)) {
    return(value)
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
      if (any(!(level %in% grpnames)))
        stop("Not all levels are listed in the group names.  Missing levels are: ",
             paste(setdiff(level, grpnames), collapse=", "))
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
  group_vars.PKNCAconc(as_PKNCAconc(x))
}
