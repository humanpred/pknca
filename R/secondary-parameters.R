# Secondary parameters: NCA parameters whose calculation needs a result from a
# different interval (the "reference" interval).  The interval specification
# links the two with an `interval_id` column naming the reference row and a
# `<parameter>_ref` pointer column on the row requesting the parameter.
#
# `pknca_ref()` and `is_pknca_ref()` are defined in R/001-add.interval.col.R so
# that the registrations using them can run while the package is sourced.

# What a secondary parameter's registration says about its inputs.
#
# ref_args:  named character vector, formal name -> parameter taken from the
#            reference interval.
# home_args: named character vector, formal name -> parameter taken from the
#            home interval.
# Errors (classed) when the registration cannot be computed by the secondary
# pass: a formal that is neither covered by formalsmap nor named after a
# parameter, an unregistered ref target, or a home argument not listed in
# `depends`.
secondary_param_info <- function(param) {
  all_intervals <- get.interval.cols()
  spec <- all_intervals[[param]]
  fm <- spec$formalsmap
  is_ref <- vapply(X = fm, FUN = is_pknca_ref, FUN.VALUE = TRUE)
  ref_args <- vapply(X = fm[is_ref], FUN = function(x) x$param, FUN.VALUE = "")
  plain <- fm[!is_ref]
  # An I()-wrapped value is a constant and a NULL drops the argument; neither is
  # a parameter result, and pk.nca.interval() handles both the same way.
  plain <- plain[!vapply(X = plain, FUN = inherits, FUN.VALUE = TRUE, what = "AsIs")]
  plain <- plain[!vapply(X = plain, FUN = is.null, FUN.VALUE = TRUE)]
  home_args <- unlist(plain)   # named character vector (may be empty)
  if (is.null(home_args)) {
    home_args <- stats::setNames(character(0), character(0))
  }
  # Every formal (minus ...) must resolve to a parameter result so that the pass
  # only ever needs parameter results as inputs.  A formal that formalsmap does
  # not mention keeps pk.nca.interval()'s identity mapping, so it is a home
  # argument when a parameter of the same name is registered (`ae` for `clr.*`).
  fun_formals <- setdiff(names(formals(get(spec$FUN))), "...")
  unmentioned <- setdiff(fun_formals, names(fm))
  implicit <- unmentioned[unmentioned %in% names(all_intervals)]
  home_args <- c(home_args, stats::setNames(implicit, implicit))
  uncovered <-
    unique(c(
      setdiff(unmentioned, implicit),
      names(home_args)[!(home_args %in% names(all_intervals))]
    ))
  if (length(uncovered) > 0) {
    rlang::abort(
      sprintf(
        "The secondary parameter '%s' has arguments not covered by formalsmap (%s); a secondary parameter's calculation function may only take NCA parameter values as inputs",
        param, paste(uncovered, collapse = ", ")
      ),
      class = "pknca_error_secondary_registration"
    )
  }
  unregistered <- setdiff(ref_args, names(all_intervals))
  if (length(unregistered) > 0) {
    rlang::abort(
      sprintf(
        "pknca_ref() target(s) for parameter '%s' are not registered NCA parameters: %s",
        param, paste(unregistered, collapse = ", ")
      ),
      class = "pknca_error_secondary_target_unregistered"
    )
  }
  # The home-interval values are read from what the interval already calculated,
  # so they have to be calculated first.
  missing_depends <- setdiff(home_args, spec$depends)
  if (length(missing_depends) > 0) {
    rlang::abort(
      sprintf(
        "The secondary parameter '%s' uses home-interval parameter(s) not listed in `depends`: %s",
        param, paste(missing_depends, collapse = ", ")
      ),
      class = "pknca_error_secondary_registration"
    )
  }
  list(fun = spec$FUN, ref_args = ref_args, home_args = home_args)
}

# Names of all registered secondary parameters
secondary_parameter_names <- function() {
  cls <- parameter_classification()
  names(cls$secondary)[cls$secondary]
}

#' Calculate the ratio of a parameter between two intervals
#'
#' @param test The parameter value in the current (test) interval
#' @param reference The parameter value in the reference interval
#' @returns `test/reference`, or `NA` where the reference is missing or is not
#'   above zero (a ratio to a zero or negative reference is not interpretable).
#' @seealso [interval_add_secondary()], [interval_add_accumulation_ratio()],
#'   [interval_add_metabolite_ratio()]
#' @examples
#' pk.calc.ratio(test = 10, reference = 20)
#' @export
pk.calc.ratio <- function(test, reference) {
  ret <- test/reference
  mask_invalid <- is.na(reference) | (reference <= 0)
  if (any(mask_invalid)) {
    ret[mask_invalid] <- NA_real_
  }
  ret
}

add.interval.col("ratio.cmax",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of cmax",
                 desc="Ratio of cmax vs reference",
                 formalsmap=list(test="cmax",
                                 reference=pknca_ref("cmax")),
                 depends="cmax",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.auclast",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of auclast",
                 desc="Ratio of auclast vs reference",
                 formalsmap=list(test="auclast",
                                 reference=pknca_ref("auclast")),
                 depends="auclast",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.aucinf.obs",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of aucinf.obs",
                 desc="Ratio of aucinf.obs vs reference",
                 formalsmap=list(test="aucinf.obs",
                                 reference=pknca_ref("aucinf.obs")),
                 depends="aucinf.obs",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.aucinf.pred",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of aucinf.pred",
                 desc="Ratio of aucinf.pred vs reference",
                 formalsmap=list(test="aucinf.pred",
                                 reference=pknca_ref("aucinf.pred")),
                 depends="aucinf.pred",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.aucint.last",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of aucint.last",
                 desc="Ratio of aucint.last vs reference",
                 formalsmap=list(test="aucint.last",
                                 reference=pknca_ref("aucint.last")),
                 depends="aucint.last",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.aucint.all",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of aucint.all",
                 desc="Ratio of aucint.all vs reference",
                 formalsmap=list(test="aucint.all",
                                 reference=pknca_ref("aucint.all")),
                 depends="aucint.all",
                 selection = list(concept = "parameter_ratio"))

PKNCA.set.summary(
  name = paste0(
    "ratio.",
    c("cmax", "auclast", "aucinf.obs", "aucinf.pred", "aucint.last", "aucint.all")
  ),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)

# Parameters in this one-row interval that are deferred to the cross-interval
# pass: requested, and with a non-NA reference pointer.
interval_deferred_params <- function(interval) {
  params <- intersect(names(interval), names(get.interval.cols()))
  ref_cols <- paste0(params, "_ref")
  has_ref <- ref_cols %in% names(interval)
  params <- params[has_ref]
  ref_cols <- ref_cols[has_ref]
  keep <-
    vapply(
      X = seq_along(params),
      FUN = function(i) isTRUE(interval[[params[i]]]) && !is.na(interval[[ref_cols[i]]]),
      FUN.VALUE = TRUE
    )
  params[keep]
}

# Ensure every pointed-at reference interval requests the source parameters the
# link needs.  Operates on (and returns) a working copy; pk.nca() never stores
# the modified intervals in the returned PKNCAresults.
#
# Silent by design: adding a needed source parameter to a reference interval is
# dependency calculation, which PKNCA never announces.
expand_secondary_intervals <- function(data) {
  current_intervals <- data$intervals
  params <- intersect(names(current_intervals), names(get.interval.cols()))
  ref_cols <- paste0(params, "_ref")
  present <- ref_cols %in% names(current_intervals)
  if (!any(present)) {
    return(data)
  }
  if (is_sparse_pk(data)) {
    rlang::abort(
      "Secondary parameters are not yet supported with sparse data",
      class = "pknca_error_secondary_sparse_unsupported"
    )
  }
  for (i in which(present)) {
    p <- params[i]
    rc <- ref_cols[i]
    rows <-
      which(
        !is.na(current_intervals[[rc]]) &
          vapply(X = current_intervals[[p]], FUN = isTRUE, FUN.VALUE = TRUE)
      )
    for (r in rows) {
      info <- secondary_param_info(p)
      ref_rows <-
        which(
          !is.na(current_intervals$interval_id) &
            current_intervals$interval_id == current_intervals[[rc]][r]
        )
      for (target in info$ref_args) {
        target_requested <-
          vapply(
            X = current_intervals[[target]][ref_rows],
            FUN = isTRUE,
            FUN.VALUE = TRUE
          )
        if (!any(target_requested)) {
          # First reference row only: when the reference interval is
          # impute-split, the source parameter is calculated under the first
          # split row's imputation.  A user needing a different imputation
          # requests the source parameter on the appropriate row explicitly.
          current_intervals[[target]][ref_rows[1]] <- TRUE
        }
      }
    }
  }
  data$intervals <- current_intervals
  data
}

# Clear reference pointers whose parameter is no longer requested on the row.
# interval_remove_param() calls this so that removing a secondary parameter
# also removes its linkage instead of leaving a pointer that fails
# check.interval.specification().
clear_orphan_ref_pointers <- function(intervals) {
  params <- intersect(names(intervals), names(get.interval.cols()))
  for (current_param in params) {
    ref_col <- paste0(current_param, "_ref")
    if (ref_col %in% names(intervals)) {
      orphan <-
        !is.na(intervals[[ref_col]]) &
        !vapply(X = intervals[[current_param]], FUN = isTRUE, FUN.VALUE = TRUE)
      intervals[[ref_col]][orphan] <- NA_character_
    }
  }
  intervals
}

# The single result value of `param` for one instance.  Returns
# list(value, exclude, n) with n the number of matching rows; the caller decides
# what n != 1 means.
secondary_lookup <- function(results, group_values, start, end, param, group_cols) {
  m <- results$PPTESTCD %in% param & results$start %in% start & results$end %in% end
  for (col in group_cols) {
    m <- m & (results[[col]] %in% group_values[[col]])
  }
  idx <- which(m)
  list(
    value = if (length(idx) == 1) results$PPORRES[idx] else NA_real_,
    exclude = if (length(idx) == 1) results$exclude[idx] else NA_character_,
    n = length(idx)
  )
}

# "Reference interval: PCSPEC=plasma, 0-24" -- how the reference differs from
# the home instance, and its times.  The interval_id is tracking information
# rather than part of the analysis method, so it is not part of PPANMETH.
secondary_ppanmeth <- function(override_cols, g_home, g_ref, ref_start, ref_end) {
  differing <-
    override_cols[
      vapply(
        X = override_cols,
        FUN = function(col) !(g_ref[[col]] %in% g_home[[col]]),
        FUN.VALUE = TRUE
      )
    ]
  details <-
    c(
      if (length(differing) > 0) name_value_text(g_ref[differing]),
      sprintf("%s-%s", format(ref_start), format(ref_end))
    )
  sprintf("Reference interval: %s", paste(details, collapse = ", "))
}

stop_secondary_ambiguous <- function(param, target, group_values) {
  rlang::abort(
    sprintf(
      "More than one result found for '%s' (needed by secondary parameter '%s') for group %s. Differentiate the intervals (for example with distinct start/end or groups) so the reference is unique; if the reference interval is split for imputation, request '%s' on only one of its rows.",
      target, param, name_value_text(group_values), target
    ),
    class = "pknca_error_secondary_ambiguous_reference"
  )
}

stop_secondary_value_missing <- function(param, target, ref_id, group_values, side) {
  source_text <-
    if (identical(side, "reference")) {
      sprintf("the reference interval ('%s')", ref_id)
    } else {
      "this interval"
    }
  rlang::abort(
    sprintf(
      "The secondary parameter '%s' could not be calculated for group %s: the value '%s' from %s is not available. Calculate it in the linked intervals, restrict the interval rows to groups that have the data, or remove the request.",
      param, name_value_text(group_values), target, source_text
    ),
    class = "pknca_error_secondary_ref_value_missing"
  )
}

# The units assigned to `param` for one group, or NA when the units table
# cannot answer.  Deliberately forgiving: an absent table, an absent parameter
# row, and an ambiguous match all give NA so that the interim mismatch warning
# never turns a units gap into an error.
secondary_units_lookup <- function(units, group_values, param) {
  if (!is.data.frame(units) || !all(c("PPTESTCD", "PPORRESU") %in% names(units))) {
    return(NA_character_)
  }
  m <- units$PPTESTCD %in% param
  for (col in intersect(names(units), names(group_values))) {
    m <- m & (units[[col]] %in% group_values[[col]])
  }
  ret <- unique(units$PPORRESU[m])
  if (length(ret) == 1) as.character(ret) else NA_character_
}

# Interim warning for group-stratified units that differ between the home and
# the reference group.  PR 4 replaces this with reconciliation of the
# reference-side values; until then a difference means the reported units (which
# come from the home group) do not describe the reference-side input.
#
# `seen` is the set of "<param>|<u_ref>|<u_home>" keys already warned about in
# this run; the updated set is returned.
secondary_warn_units <- function(units, param, targets, g_home, g_ref, seen) {
  for (target in targets) {
    u_home <- secondary_units_lookup(units, g_home, target)
    u_ref <- secondary_units_lookup(units, g_ref, target)
    if (!is.na(u_home) && !is.na(u_ref) && !identical(u_home, u_ref)) {
      key <- paste(param, u_ref, u_home, sep = "|")
      if (!(key %in% seen)) {
        seen <- c(seen, key)
        rlang::warn(
          sprintf(
            "Secondary parameter '%s': the units of '%s' differ between the reference group ('%s') and the interval's own group ('%s'); the reported result uses the interval's own units without converting the reference value.",
            param, target, u_ref, u_home
          ),
          class = "pknca_warning_secondary_units"
        )
      }
    }
  }
  seen
}

# Compute deferred secondary parameters from the combined results and append
# their rows.  `results` is the data.frame produced inside pk.nca() (group
# columns + start/end + keep_interval_cols + PPTESTCD/PPORRES/PPANMETH/exclude);
# `data_calc` is the PKNCAdata whose intervals carry the pointers (the expanded
# working copy).
pk_nca_secondary <- function(results, data_calc) {
  if (nrow(results) == 0 || !("PPTESTCD" %in% names(results))) {
    return(results)
  }
  current_intervals <- data_calc$intervals
  # The automatic-linkage ledger arrives as a list element of the working-copy
  # PKNCAdata (never as an attribute, which subsetting could strip); NULL until
  # the automatic reference finder exists.
  auto <- data_calc$secondary_auto
  params <- intersect(names(current_intervals), names(get.interval.cols()))
  ref_cols <- paste0(params, "_ref")
  present <- ref_cols %in% names(current_intervals)
  if (!any(present) && is.null(auto)) {
    return(results)
  }
  keep_cols <- data_calc$options$keep_interval_cols
  result_group_cols <-
    setdiff(
      names(results),
      c("start", "end", "PPTESTCD", "PPORRES", "PPANMETH", "exclude", keep_cols)
    )
  override_cols <- intersect(names(current_intervals), result_group_cols)
  units_seen <- character(0)
  new_rows <- list()
  for (i in which(present)) {
    p <- params[i]
    rc <- ref_cols[i]
    requested_rows <-
      which(
        !is.na(current_intervals[[rc]]) &
          vapply(X = current_intervals[[p]], FUN = isTRUE, FUN.VALUE = TRUE)
      )
    for (r in requested_rows) {
      info <- secondary_param_info(p)
      ref_id <- current_intervals[[rc]][r]
      is_auto <-
        !is.null(auto) &&
        any(auto$links$param %in% p & auto$links$ref_id %in% ref_id)
      ref_row <-
        which(
          !is.na(current_intervals$interval_id) &
            current_intervals$interval_id == ref_id
        )[1]
      # Home instances: distinct group combinations with any result for this
      # row's scope and times
      m_home <-
        results$start %in% current_intervals$start[r] &
        results$end %in% current_intervals$end[r]
      for (col in override_cols) {
        m_home <- m_home & (results[[col]] %in% current_intervals[[col]][r])
      }
      instances <-
        if (length(result_group_cols) > 0) {
          unique(results[m_home, result_group_cols, drop = FALSE])
        } else if (any(m_home)) {
          # Ungrouped data has one anonymous instance.  unique() cannot produce
          # it: duplicated() on a zero-column data.frame returns length zero
          # before R 4.5, and tibble refuses the zero-length subscript.
          data.frame(row.names = 1L)
        } else {
          data.frame()
        }
      for (k in seq_len(nrow(instances))) {
        g_home <- instances[k, , drop = FALSE]
        g_ref <- g_home
        for (col in override_cols) {
          g_ref[[col]] <- current_intervals[[col]][ref_row]
        }
        inputs <- list()      # formal -> value
        excludes <- character(0)
        failed_reason <- NULL
        for (formal in names(info$home_args)) {
          found <-
            secondary_lookup(
              results, g_home,
              current_intervals$start[r], current_intervals$end[r],
              info$home_args[[formal]], result_group_cols
            )
          if (found$n > 1) stop_secondary_ambiguous(p, info$home_args[[formal]], g_home)
          if (found$n == 0) {
            # The home-side value is guaranteed by `depends` for an explicit
            # link, so this branch defends the automatic linkage, which cannot
            # arise until the reference finder exists.
            # nocov start
            if (!is_auto) {
              stop_secondary_value_missing(
                p, info$home_args[[formal]], ref_id, g_home, side = "home"
              )
            }
            failed_reason <-
              sprintf(
                "Value '%s' is not available for the interval",
                info$home_args[[formal]]
              )
            # nocov end
          }
          inputs[[formal]] <- found$value
          excludes <- c(excludes, found$exclude)
        }
        for (formal in names(info$ref_args)) {
          found <-
            secondary_lookup(
              results, g_ref,
              current_intervals$start[ref_row], current_intervals$end[ref_row],
              info$ref_args[[formal]], result_group_cols
            )
          if (found$n > 1) stop_secondary_ambiguous(p, info$ref_args[[formal]], g_ref)
          if (found$n == 0) {
            if (!is_auto) {
              stop_secondary_value_missing(
                p, info$ref_args[[formal]], ref_id, g_home, side = "reference"
              )
            }
            # An explicit link aborted just above, so recording the reason is
            # for automatic links only, which cannot arise until the reference
            # finder exists.
            # nocov start
            failed_reason <-
              sprintf(
                "Reference value '%s' is not available from reference interval '%s'",
                info$ref_args[[formal]], ref_id
              )
            # nocov end
          }
          inputs[[formal]] <- found$value
          excludes <- c(excludes, found$exclude)
        }
        units_seen <-
          secondary_warn_units(
            data_calc$units, p, info$ref_args, g_home, g_ref, units_seen
          )
        # PR 4 inserts unit reconciliation of the ref-side inputs here.
        if (is.null(failed_reason)) {
          value <- do.call(info$fun, inputs)
          excl <- combine_exclude_reasons(excludes, attr(value, "exclude"))
          value <- as.numeric(value)
        } else {
          # A failed_reason is only recorded for automatic links, which cannot
          # arise until the reference finder exists.
          # nocov start
          value <- NA_real_
          excl <- combine_exclude_reasons(c(excludes, failed_reason), NULL)
          # nocov end
        }
        template <- results[m_home, , drop = FALSE]
        template <-
          template[
            Reduce(
              `&`,
              lapply(result_group_cols, function(col) template[[col]] %in% g_home[[col]]),
              # Ungrouped data has no group columns to match on, and every row
              # of the home selection is then the instance.
              rep(TRUE, nrow(template))
            ), ,
            drop = FALSE
          ][1, , drop = FALSE]
        template$PPTESTCD <- p
        template$PPORRES <- value
        template$PPANMETH <-
          secondary_ppanmeth(
            override_cols, g_home, g_ref,
            current_intervals$start[ref_row], current_intervals$end[ref_row]
          )
        template$exclude <- excl
        new_rows[[length(new_rows) + 1L]] <- template
      }
    }
  }
  # PR 3 adds here: NA rows from auto$failures, plus one
  # pknca_warning_secondary_auto_reference per parameter that had any automatic
  # failure (finder failure or missing auto-linked value).
  if (length(new_rows) == 0) results else dplyr::bind_rows(results, new_rows)
}

# Authoring the linkage ---------------------------------------------------
#
# interval_add_secondary() writes the `interval_id` and `<parameter>_ref`
# columns the engine above reads.  Unlike the engine's expansion, everything it
# does is visible in the intervals it returns.

# The columns that say *which* interval a row is:  not the parameter requests,
# not the linkage columns, and not the imputation.
interval_describe_cols <- function(intervals) {
  all_params <- names(get.interval.cols())
  setdiff(
    names(intervals),
    c(
      setdiff(all_params, c("start", "end")),
      paste0(all_params, "_ref"),
      "interval_id", "impute"
    )
  )
}

# The value an interval column takes when it is not requested, as
# check.interval.specification() assigns it for an absent column.  `start` and
# `end` are the only columns validated by a function instead of a set of allowed
# values, and neither is ever defaulted here.
interval_default_value <- function(param) {
  get.interval.cols()[[param]]$values[1]
}

# Ensure the named parameter columns exist, unrequested
interval_ensure_param_cols <- function(intervals, params) {
  for (current_param in setdiff(params, names(intervals))) {
    intervals[[current_param]] <- interval_default_value(current_param)
  }
  intervals
}

# Keep the pointer columns comparable with `interval_id`:  create the one for
# `param` when it is absent or unfilled, and give every pointer column the
# identifier column's levels, since generating an identifier adds one.
interval_sync_ref_cols <- function(intervals, param) {
  ref_col <- paste0(param, "_ref")
  if (!(ref_col %in% names(intervals)) ||
      (is.logical(intervals[[ref_col]]) && all(is.na(intervals[[ref_col]])))) {
    intervals[[ref_col]] <- intervals$interval_id[rep(NA_integer_, nrow(intervals))]
  }
  if (is.factor(intervals$interval_id)) {
    all_ref_cols <- intersect(paste0(names(get.interval.cols()), "_ref"), names(intervals))
    for (col in all_ref_cols) {
      if (is.factor(intervals[[col]]) &&
          !identical(levels(intervals[[col]]), levels(intervals$interval_id))) {
        intervals[[col]] <-
          factor(as.character(intervals[[col]]), levels = levels(intervals$interval_id))
      }
    }
  }
  intervals
}

# "ref1", "ref2", ... skipping any identifier already in use
interval_next_ref_names <- function(used, n) {
  ret <- character(0)
  k <- 0L
  while (length(ret) < n) {
    k <- k + 1L
    candidate <- paste0("ref", k)
    if (!(candidate %in% used)) {
      ret <- c(ret, candidate)
    }
  }
  ret
}

# `n` new interval identifiers matching the class of the `interval_id` column,
# because identifiers may be of any comparable class:  "ref1", "ref2", ... for
# character (skipping ids already in use), `max + 1` for numbers, and new levels
# for a factor.  An absent or unfilled (all-NA logical) column takes character
# identifiers, and is created here so the caller can assign into it.
interval_new_ids <- function(intervals, n) {
  existing <- intervals$interval_id
  if (is.null(existing) || (is.logical(existing) && all(is.na(existing)))) {
    intervals$interval_id <- NA_character_
    existing <- character(0)
  }
  if (is.factor(existing)) {
    ids <-
      interval_next_ref_names(
        unique(c(levels(existing), as.character(stats::na.omit(existing)))), n
      )
    levels(intervals$interval_id) <- c(levels(existing), ids)
  } else if (is.numeric(existing)) {
    highest <- if (all(is.na(existing))) 0 else max(existing, na.rm = TRUE)
    ids <- highest + seq_len(n)
  } else {
    ids <- interval_next_ref_names(as.character(stats::na.omit(existing)), n)
  }
  list(intervals = intervals, ids = ids)
}

# Give every reference interval an identifier:  `ref_id` when the user named
# one, the identifier the rows already share, or a newly generated one.
interval_assign_ref_ids <- function(intervals, ref_groups, ref_id) {
  ids <- vector(mode = "list", length = length(ref_groups))
  need_new <- rep(FALSE, length(ref_groups))
  for (i in seq_along(ref_groups)) {
    current <-
      if (is.null(intervals$interval_id)) {
        NULL
      } else {
        stats::na.omit(intervals$interval_id[ref_groups[[i]]])
      }
    if (!is.null(ref_id)) {
      ids[[i]] <- ref_id
    } else if (length(current) > 0) {
      ids[[i]] <- current[1]
    } else {
      need_new[i] <- TRUE
    }
  }
  if (!is.null(ref_id) &&
      (is.null(intervals$interval_id) ||
       (is.logical(intervals$interval_id) && all(is.na(intervals$interval_id))))) {
    intervals$interval_id <- ref_id[rep(NA_integer_, nrow(intervals))]
  }
  if (any(need_new)) {
    generated <- interval_new_ids(intervals, sum(need_new))
    intervals <- generated$intervals
    ids[need_new] <- as.list(generated$ids)
  }
  for (i in seq_along(ref_groups)) {
    rows <- ref_groups[[i]]
    blank_rows <- if (is.null(ref_id)) rows[is.na(intervals$interval_id[rows])] else rows
    intervals$interval_id[blank_rows] <- ids[[i]]
  }
  list(intervals = intervals, ids = ids)
}

# The reference rows grouped into the distinct intervals they describe
interval_reference_groups <- function(intervals, ref_rows) {
  describe_cols <- interval_describe_cols(intervals)
  signature <-
    do.call(
      paste,
      c(
        lapply(X = intervals[ref_rows, describe_cols, drop = FALSE], FUN = as.character),
        sep = "\r"
      )
    )
  lapply(X = unique(signature), FUN = function(x) ref_rows[signature %in% x])
}

# Which of the reference intervals a test row uses.  One reference serves every
# test row; several are told apart by matching the test row's own times.
interval_pick_reference <- function(intervals, row, ref_groups, param) {
  if (length(ref_groups) == 1) {
    return(1L)
  }
  same_time <-
    which(vapply(
      X = ref_groups,
      FUN = function(rows) {
        (intervals$start[rows[1]] %in% intervals$start[row]) &&
          (intervals$end[rows[1]] %in% intervals$end[row])
      },
      FUN.VALUE = TRUE
    ))
  if (length(same_time) == 1) {
    return(same_time)
  }
  rlang::abort(
    sprintf(
      "`reference` matched %d reference intervals and none of them is the single reference for '%s' in interval row %d. Narrow `reference` (for example by adding `start` and `end` columns) so that each interval has one reference.",
      length(ref_groups), param, row
    ),
    class = "pknca_error_secondary_ref_ambiguous_spec"
  )
}

# Build the reference rows for an interval specification that has none:  the
# test rows with the `reference` values applied.  `impute` is dropped, so a
# created row takes the whole-dataset imputation.
interval_create_reference <- function(intervals, test_rows, reference) {
  base <- intervals[test_rows, interval_describe_cols(intervals), drop = FALSE]
  ret_list <- list()
  for (i in seq_len(nrow(reference))) {
    current <- base
    for (col in names(reference)) {
      current[[col]] <- reference[[col]][i]
    }
    ret_list[[i]] <- current
  }
  ret <- unique(do.call(rbind, ret_list))
  rownames(ret) <- NULL
  ret
}

# Fill the columns a created reference row does not have:  nothing is
# calculated on it but the source parameters the linkage needs.
interval_complete_reference <- function(created, intervals, source_params) {
  for (col in setdiff(names(intervals), names(created))) {
    created[[col]] <-
      if (col %in% names(get.interval.cols())) {
        interval_default_value(col)
      } else if (identical(col, "impute")) {
        NA_character_
      } else {
        intervals[[col]][rep(NA_integer_, nrow(created))]
      }
  }
  for (target in source_params) {
    created[[target]] <- TRUE
  }
  created[, names(intervals), drop = FALSE]
}

interval_secondary_validate <- function(intervals, param, reference, ref_id) {
  checkmate::assert_data_frame(intervals, min.rows = 1)
  checkmate::assert_character(param, len = 1, any.missing = FALSE)
  assert_param_name(param)
  if (!isTRUE(parameter_classification()$secondary[[param]])) {
    rlang::abort(
      sprintf(
        "'%s' is not a secondary parameter; use interval_add_param() instead",
        param
      ),
      class = "pknca_error_secondary_not_secondary_param"
    )
  }
  if (is.null(reference)) {
    # PR 3 replaces this branch with the automatic reference finder (and, for
    # the PKNCAdata method, with `data$group_ref` as the default).
    rlang::abort("reference must be given")
  }
  reference <- as.data.frame(reference, stringsAsFactors = FALSE)
  checkmate::assert_data_frame(reference, min.rows = 1, min.cols = 1)
  invalid <- setdiff(names(reference), interval_describe_cols(intervals))
  if (length(invalid) > 0) {
    rlang::abort(
      sprintf(
        "Column(s) in `reference` must be `start`, `end`, or a group column of the intervals: %s",
        paste(invalid, collapse = ", ")
      ),
      class = "pknca_error_interval_target_groups_cols"
    )
  }
  checkmate::assert_scalar(ref_id, na.ok = FALSE, null.ok = TRUE)
  reference
}

# Link `param` on the test rows to the reference interval `reference` describes,
# creating that interval when the specification does not have it yet.
interval_edit_secondary <- function(intervals, param, reference, target_groups, ref_id) {
  reference <- interval_secondary_validate(intervals, param, reference, ref_id)
  source_params <- unname(secondary_param_info(param)$ref_args)
  ref_rows <- which(interval_match_groups(intervals, reference))
  test_rows <-
    if (is.null(target_groups)) {
      setdiff(seq_len(nrow(intervals)), ref_rows)
    } else {
      setdiff(which(interval_match_groups(intervals, target_groups)), ref_rows)
    }
  if (length(test_rows) == 0) {
    rlang::warn(
      sprintf("No intervals are left to calculate '%s' on.  No changes made.", param),
      class = "pknca_warning_interval_no_target_rows"
    )
    return(intervals)
  }
  intervals <- interval_ensure_param_cols(intervals, c(param, source_params))
  if (length(ref_rows) == 0) {
    created <- interval_create_reference(intervals, test_rows, reference)
    created <- interval_complete_reference(created, intervals, source_params)
    rlang::inform(
      sprintf(
        "Created reference interval(s) for '%s': %s",
        param,
        paste(
          name_value_text(created[, interval_describe_cols(created), drop = FALSE]),
          collapse = "; "
        )
      ),
      class = "pknca_message_secondary_created_interval"
    )
    intervals <- rbind(intervals, created)
    rownames(intervals) <- NULL
    ref_rows <- seq(to = nrow(intervals), length.out = nrow(created))
  }
  ref_groups <- interval_reference_groups(intervals, ref_rows)
  if (!is.null(ref_id) && length(ref_groups) > 1) {
    rlang::abort(
      sprintf(
        "`ref_id` names one reference interval, but `reference` matched %d of them. Narrow `reference` (for example by adding `start` and `end` columns) or leave `ref_id` unset.",
        length(ref_groups)
      ),
      class = "pknca_error_secondary_ref_ambiguous_spec"
    )
  }
  assigned <- interval_assign_ref_ids(intervals, ref_groups, ref_id)
  intervals <- interval_sync_ref_cols(assigned$intervals, param)
  ref_col <- paste0(param, "_ref")
  used_groups <- integer(0)
  for (row in test_rows) {
    current_group <- interval_pick_reference(intervals, row, ref_groups, param)
    current_id <- assigned$ids[[current_group]]
    current_pointer <- intervals[[ref_col]][row]
    if (!is.na(current_pointer) &&
        !identical(as.character(current_pointer), as.character(current_id))) {
      rlang::warn(
        sprintf(
          "Interval row %d already gives a reference interval ('%s') for '%s'; it was left unchanged.",
          row, as.character(current_pointer), param
        ),
        class = "pknca_warning_secondary_ref_exists"
      )
      next
    }
    intervals[[param]][row] <- TRUE
    intervals[[ref_col]][row] <- current_id
    used_groups <- c(used_groups, current_group)
  }
  # The reference interval gains what the link reads from it.  Silent, as
  # calculating a dependency always is.
  for (current_group in unique(used_groups)) {
    rows <- ref_groups[[current_group]]
    for (target in source_params) {
      if (!any(vapply(X = intervals[[target]][rows], FUN = isTRUE, FUN.VALUE = TRUE))) {
        intervals[[target]][rows[1]] <- TRUE
      }
    }
  }
  rownames(intervals) <- NULL
  check.interval.specification(intervals)
}

#' Link a secondary parameter to the interval it is calculated against
#'
#' A secondary parameter needs a result from a second profile:  renal clearance
#' divides an amount excreted in urine by a plasma AUC, an accumulation ratio
#' compares one dosing interval with another, and a metabolite ratio compares
#' two analytes.  This adds the request and the linkage columns
#' (`interval_id` on the reference interval and `<param>_ref` on the intervals
#' calculating the parameter) that [pk.nca()] reads.
#'
#' @inheritParams interval_add_impute
#' @param param The name of one secondary NCA parameter (see
#'   [pknca_parameter_table()] for which parameters are secondary).
#' @param reference A data.frame describing the reference interval:  its
#'   columns are `start`, `end`, and/or group columns of the intervals, every
#'   column must match (and) for at least one of its rows (or).  A named list is
#'   accepted and coerced.  When no interval matches, one is created and the
#'   creation is reported with a `pknca_message_secondary_created_interval`
#'   message.
#' @param target_groups A data.frame of group values restricting the parameter
#'   request to matching intervals, with the same matching rules as `reference`.
#'   `NULL` (the default) requests it on every interval that is not a reference
#'   interval.
#' @param ref_id The `interval_id` to give the reference interval.  The default
#'   of `NULL` keeps an identifier the reference rows already have and
#'   otherwise generates one matching the class of the `interval_id` column.
#' @returns The input with the parameter requested and the linkage columns set,
#'   after [check.interval.specification()].
#' @details The reference interval gains whatever the linked calculation reads
#'   from it (the plasma AUC for a renal clearance, for example) without being
#'   announced, as calculating any dependency is.
#'
#'   An interval that already names a different reference for `param` is left
#'   alone with a `pknca_warning_secondary_ref_exists` warning, so that the
#'   helper never silently re-points an analysis.
#' @seealso [interval_add_param()], [pknca_ref()], [pk.nca()]
#' @family Interval specifications
#' @examples
#' intervals <-
#'   data.frame(
#'     PCSPEC = c("plasma", "urine"),
#'     start = 0, end = 24,
#'     auclast = c(TRUE, FALSE),
#'     ae = c(FALSE, TRUE)
#'   )
#' interval_add_secondary(
#'   intervals,
#'   param = "clr.last",
#'   reference = data.frame(PCSPEC = "plasma")
#' )
#' @export
interval_add_secondary <- function(data, param, reference = NULL,
                                   target_groups = NULL, ref_id = NULL, ...) {
  UseMethod("interval_add_secondary", data)
}

#' @export
interval_add_secondary.data.frame <- function(data, param, reference = NULL,
                                              target_groups = NULL, ref_id = NULL, ...) {
  interval_edit_secondary(
    data, param = param, reference = reference, target_groups = target_groups,
    ref_id = ref_id
  )
}

#' @export
interval_add_secondary.PKNCAdata <- function(data, param, reference = NULL,
                                             target_groups = NULL, ref_id = NULL, ...) {
  data$intervals <-
    interval_edit_secondary(
      data$intervals, param = param, reference = reference,
      target_groups = target_groups, ref_id = ref_id
    )
  data
}

#' Link the common secondary parameters to their reference intervals
#'
#' Each of these is [interval_add_secondary()] with the reference specification
#' the analysis implies:  the profile the drug is cleared from for a renal
#' clearance, the first dosing interval for an accumulation ratio, and the
#' parent analyte for a metabolite ratio.
#'
#' @inheritParams interval_add_secondary
#' @param reference A data.frame of group values identifying the reference
#'   profile (for example `data.frame(PCSPEC = "plasma")` or
#'   `data.frame(Analyte = "parent")`).
#' @param ref_start,ref_end The start and end times of the reference dosing
#'   interval.
#' @param ... Passed to [interval_add_secondary()], which accepts `ref_id`.
#' @returns The input with the parameter requested and the linkage columns set.
#' @seealso [interval_add_secondary()]
#' @family Interval specifications
#' @examples
#' intervals <-
#'   data.frame(
#'     PCSPEC = c("plasma", "urine"),
#'     start = 0, end = 24,
#'     aucinf.obs = c(TRUE, FALSE),
#'     ae = c(FALSE, TRUE)
#'   )
#' interval_add_renal_clearance(intervals, reference = data.frame(PCSPEC = "plasma"))
#' @export
interval_add_renal_clearance <- function(data, reference, param = "clr.obs",
                                         target_groups = NULL, ...) {
  interval_add_secondary(
    data, param = param, reference = reference, target_groups = target_groups, ...
  )
}

#' @rdname interval_add_renal_clearance
#' @export
interval_add_accumulation_ratio <- function(data, ref_start, ref_end,
                                            param = "ratio.aucint.last",
                                            target_groups = NULL, ...) {
  interval_add_secondary(
    data, param = param, reference = data.frame(start = ref_start, end = ref_end),
    target_groups = target_groups, ...
  )
}

#' @rdname interval_add_renal_clearance
#' @export
interval_add_metabolite_ratio <- function(data, reference,
                                          param = "ratio.aucinf.obs",
                                          target_groups = NULL, ...) {
  interval_add_secondary(
    data, param = param, reference = reference, target_groups = target_groups, ...
  )
}
