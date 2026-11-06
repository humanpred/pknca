# Whether the parameters an interval requests are calculated on one basis
#
# pknca_interval_table() chooses the parameters of an interval from its context:
# a single dose uses AUClast (or AUCall) and the extrapolation to infinity with
# the observed (or predicted) last concentration, a repeated dose uses the
# AUCint family on the same choices, and an interval that ends at infinity has
# no parameter that needs a finite end.  The parameters that one context can
# give together are consistent with each other.  An interval specification that
# requests parameters no context gives together mixes bases:  AUCint,all with a
# clearance from AUClast, say, or a clearance from AUCinf,obs with a volume from
# AUCinf,pred.
#
# The route and the sample type are not judged:  one interval commonly applies
# to IV and oral groups of a crossover, or to plasma and urine, and each
# parameter is only calculated for the profiles it applies to.
#
# Nor are the AUCs and AUMCs, and their percent extrapolated, judged against
# each other:  reporting AUClast with AUCall, or AUCinf,obs with AUCinf,pred, is
# common.  What is judged is a parameter calculated from an AUC (a clearance,
# volume, mean residence time, or average concentration, say) against every
# other parameter of the interval.

# The concepts of the AUC reports, which are not judged against each other
auc_report_concepts <- c("auc", "aumc", "auc_extrapolation")

# The dimensions of a context that decide the basis of its parameters, with how
# a mixture of their values is described
consistency_dimensions <-
  c(
    dosing = "single-dose AUCs (AUClast, AUCall, AUCinf) mixed with interval AUCs (AUCint)",
    auc_type = "AUClast mixed with AUCall",
    clast_type = "AUCinf,obs mixed with AUCinf,pred",
    end = "a parameter that needs a finite interval end"
  )

# The parameter set of each context, with the context's values of the
# dimensions.  Cached, and dropped when the registry changes, because it is
# built from the whole classification.
interval_consistent_sets <- function() {
  key <- names(get.interval.cols())
  cached <- get0("interval_consistent_sets", envir = .PKNCAEnv)
  if (!is.null(cached) && identical(cached$key, key)) {
    return(cached$value)
  }
  contexts <-
    expand.grid(
      dosing = pknca_dosing(),
      auc_type = c("last", "all"),
      clast_type = c("obs", "pred"),
      end = c("finite", "infinite"),
      stringsAsFactors = FALSE
    )
  finite_only <- finite_interval_params()
  sets <-
    lapply(
      X = seq_len(nrow(contexts)),
      FUN = consistent_set_for_context,
      contexts = contexts,
      finite_only = finite_only
    )
  value <- list(contexts = contexts, sets = sets, governed = sort(unique(unlist(sets))))
  assign("interval_consistent_sets", list(key = key, value = value), envir = .PKNCAEnv)
  value
}

# The parameters pknca_interval_table() can give for one context, over every
# route and sample type
consistent_set_for_context <- function(i, contexts, finite_only) {
  auc_basis <-
    context_auc_basis(
      dosing = contexts$dosing[i], clast_type = contexts$clast_type[i],
      auc_type = contexts$auc_type[i]
    )
  ret <-
    context_parameters(
      dosing = contexts$dosing[i], route = NULL, sample_type = NULL,
      tier = "all", auc_basis = auc_basis
    )
  if (contexts$end[i] == "infinite") {
    ret <- setdiff(ret, finite_only)
  }
  sort(ret)
}

# Every parameter that the requested parameters are calculated from, so that
# requesting a parameter together with its own inputs is never a mixture (the
# degree of fluctuation is calculated from Cav, for example)
interval_param_inputs <- function(params, all_intervals) {
  ret <- character()
  current <- params
  while (length(current) > 0) {
    deps <- unlist(lapply(X = all_intervals[current], FUN = `[[`, "depends"))
    current <- setdiff(deps, ret)
    ret <- union(ret, current)
  }
  ret
}

# Which sets contain every one of the parameters
sets_containing <- function(params, sets) {
  vapply(X = sets, FUN = function_all_in, params = params, FUN.VALUE = TRUE)
}

function_all_in <- function(set, params) {
  all(params %in% set)
}

# Why the parameters of one interval are not consistent:  each pair that no
# context gives together, described by the dimensions whose values differ, and
# each parameter that no context with the interval's end gives
describe_inconsistency <- function(params, infinite_end, consistent) {
  end_rows <- consistent$contexts$end == if (infinite_end) "infinite" else "finite"
  sets <- consistent$sets[end_rows]
  contexts <- consistent$contexts[end_rows, , drop = FALSE]
  ret <- character()
  alone <- params[!vapply(X = params, FUN = function_any_set_has, sets = sets, FUN.VALUE = TRUE)]
  if (length(alone) > 0) {
    ret <-
      c(ret, sprintf("%s (%s)", paste(alone, collapse = ", "), consistency_dimensions[["end"]]))
  }
  together <- setdiff(params, alone)
  is_report <- parameter_classification()$concept[together] %in% auc_report_concepts
  for (a in seq_along(together)) {
    for (b in seq_along(together)[-seq_len(a)]) {
      pair <- together[c(a, b)]
      if (!(is_report[a] && is_report[b]) && !any(sets_containing(pair, sets))) {
        ret <- c(ret, sprintf("%s with %s (%s)", pair[1], pair[2], pair_reason(pair, sets, contexts)))
      }
    }
  }
  if (length(ret) == 0) {
    # No single parameter or pair explains it; name them all
    ret <- sprintf("%s (no single basis gives all of them)", paste(params, collapse = ", "))
  }
  ret
}

# Whether the parameters of one interval are consistent:  the AUC reports may be
# on any mixture of bases, so the parameters must be consistent with each
# report separately, together with every parameter calculated from an AUC
interval_params_consistent <- function(params, infinite_end, consistent) {
  sets <- consistent$sets[consistent$contexts$end == if (infinite_end) "infinite" else "finite"]
  is_report <- parameter_classification()$concept[params] %in% auc_report_concepts
  derived <- params[!is_report]
  reports <- params[is_report]
  if (length(reports) == 0) {
    return(any(sets_containing(derived, sets)))
  }
  all(vapply(
    X = reports,
    FUN = function_consistent_with_report,
    derived = derived, sets = sets,
    FUN.VALUE = TRUE
  ))
}

function_consistent_with_report <- function(report, derived, sets) {
  any(sets_containing(c(report, derived), sets))
}

function_any_set_has <- function(param, sets) {
  any(sets_containing(param, sets))
}

# The dimensions on which the contexts that give one parameter and the contexts
# that give the other do not overlap
pair_reason <- function(pair, sets, contexts) {
  has_first <- sets_containing(pair[1], sets)
  has_second <- sets_containing(pair[2], sets)
  dims <- c("dosing", "auc_type", "clast_type")
  disjoint <-
    dims[vapply(
      X = dims,
      FUN = dimension_disjoint,
      contexts = contexts, has_first = has_first, has_second = has_second,
      FUN.VALUE = TRUE
    )]
  if (length(disjoint) == 0) {
    return("not calculated on one basis")
  }
  paste(consistency_dimensions[disjoint], collapse = "; ")
}

dimension_disjoint <- function(dim, contexts, has_first, has_second) {
  first <- contexts[[dim]][has_first]
  second <- contexts[[dim]][has_second]
  # "single" against the repeated-dose contexts, which share their parameters
  if (identical(dim, "dosing")) {
    first <- first == "single"
    second <- second == "single"
  }
  length(intersect(first, second)) == 0
}

#' Warn when an interval requests parameters calculated on different bases
#'
#' Every interval (row) of `intervals` is judged once; rows that request the
#' same parameters with the same kind of end are judged together, and all the
#' problems are given in one warning.
#'
#' @param intervals An interval specification
#' @returns `NULL`, invisibly, after warning with the class
#'   `pknca_warning_interval_inconsistent_parameters` when any interval mixes
#'   bases
#' @keywords Internal
#' @noRd
warn_inconsistent_interval_parameters <- function(intervals) {
  if (nrow(intervals) == 0 || !("end" %in% names(intervals))) {
    return(invisible(NULL))
  }
  consistent <- interval_consistent_sets()
  params <- intersect(consistent$governed, names(intervals))
  if (length(params) == 0) {
    return(invisible(NULL))
  }
  requested <- matrix(FALSE, nrow = nrow(intervals), ncol = length(params), dimnames = list(NULL, params))
  for (p in params) {
    requested[, p] <- intervals[[p]] %in% TRUE
  }
  infinite_end <- is.infinite(pknca_interval_bound_number(intervals$end))
  pattern <- paste(infinite_end, apply(requested, 1, paste, collapse = ""))
  all_intervals <- get.interval.cols()
  # The number of intervals with each problem
  problems <- integer()
  for (current in unique(pattern)) {
    rows <- which(pattern == current)
    row_params <- params[requested[rows[1], ]]
    # A parameter requested along with one calculated from it is not judged
    # against it
    row_params <- setdiff(row_params, interval_param_inputs(row_params, all_intervals))
    if (length(row_params) == 0) {
      next
    }
    if (interval_params_consistent(row_params, infinite_end[rows[1]], consistent)) {
      next
    }
    for (reason in describe_inconsistency(row_params, infinite_end[rows[1]], consistent)) {
      problems[reason] <- sum(problems[reason], length(rows), na.rm = TRUE)
    }
  }
  if (length(problems) == 0) {
    return(invisible(NULL))
  }
  problems <-
    sprintf(
      "%s (%d %s)", names(problems), problems,
      ifelse(problems == 1, "interval", "intervals")
    )
  rlang::warn(
    paste0(
      "Some intervals request parameters that are not calculated on one basis, ",
      "so they may not describe the same thing:\n",
      paste0("  ", problems, collapse = "\n")
    ),
    class = "pknca_warning_interval_inconsistent_parameters"
  )
  invisible(NULL)
}
