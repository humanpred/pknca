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
            failed_reason <-
              sprintf(
                "Reference value '%s' is not available from reference interval '%s'",
                info$ref_args[[formal]], ref_id
              )
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
          value <- NA_real_
          excl <- combine_exclude_reasons(c(excludes, failed_reason), NULL)
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
