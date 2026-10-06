# Classification of NCA parameters for interval selection
#
# Choosing the parameters to calculate for an interval needs to know, for each
# parameter, what it *is* (the concept), how commonly it is reported (the
# tier), and which contexts it applies to (route, dosing, sample type).
#
# Most of that is already implied by the registry and is derived here rather
# than declared:
#
#   sample type  requires_volume, cached by set_requires_inputs()
#   route        the parameters downstream of `c0` plus those needing a dose
#                duration are the intravenous family
#   dosing       the parameters downstream of an extrapolation to infinity are
#                single-dose; the ones downstream of the multiple-dose seeds
#                are multiple-dose
#   AUC basis    get.parameter.deps() of each AUC
#
# What cannot be derived is declared:  the concept lives on the calculation
# function as an attribute, and `tier` plus the handful of route and dosing
# exceptions are arguments to add.interval.col().
#
# Nothing here raises an error for a parameter it cannot classify.  A parameter
# registered by another package is simply never selected automatically; it
# remains available by name.  The completeness of PKNCA's own classification is
# enforced by its test suite, not at run time.

# The roots of extrapolation to infinity.  Everything calculated from one of
# these needs data after the last dose, so it belongs to single-dose analysis.
#
# The aucint parameters are deliberately absent.  The "inf" in aucint.inf.obs
# names the extrapolation used for the tail, not the end of the interval:  over
# a bounded interval it extrapolates to the interval end, which is how AUCtau
# is calculated at steady state.
pknca_infinity_roots <- c(
  "aucinf.obs", "aucinf.pred",
  "aucivinf.obs", "aucivinf.pred"
)

# Union of get.parameter.deps() over several parameters, skipping any that are
# not registered (another package may have removed one).
deps_union <- function(params, all_intervals) {
  params <- intersect(params, names(all_intervals))
  if (length(params) == 0) {
    return(character(0))
  }
  sort(unique(unlist(lapply(X = params, FUN = get.parameter.deps))))
}

# Resolve the concept for every parameter at once:  the declared concept, then
# the calculation function's attribute, then the concept of what it depends on
# (which is how the dose-normalized parameters and the half-life diagnostics
# get theirs).
classify_concepts <- function(all_intervals) {
  ret <- stats::setNames(rep(NA_character_, length(all_intervals)), names(all_intervals))
  for (n in names(all_intervals)) {
    declared <- all_intervals[[n]]$selection$concept
    if (!is.null(declared)) {
      ret[[n]] <- declared
      next
    }
    fun_name <- interval_col_fun(all_intervals[[n]])
    if (length(fun_name) == 1 && !is.na(fun_name)) {
      fun <- tryCatch(get(fun_name), error = function(e) NULL)
      from_fun <- if (is.null(fun)) NULL else pknca_concept(fun)
      if (!is.null(from_fun)) {
        ret[[n]] <- from_fun
      }
    }
  }
  # Inherit from `depends` for anything still unresolved.  Repeat so that a
  # chain (a diagnostic of a dose-normalized parameter, say) settles.
  for (i in seq_len(3)) {
    unresolved <- names(ret)[is.na(ret)]
    if (length(unresolved) == 0) {
      break
    }
    for (n in unresolved) {
      inherited <- unique(stats::na.omit(ret[all_intervals[[n]]$depends]))
      if (length(inherited) == 1) {
        ret[[n]] <- inherited
      }
    }
  }
  ret
}

# Which routes each parameter applies to.  Declared wins.  Otherwise a
# parameter is intravenous when it is calculated from `c0` or needs a dose
# duration, and which intravenous routes it applies to follows from why:
#
#   `c0` is the concentration back-extrapolated to the time of an intravenous
#   bolus.  There is no back-extrapolated triangle for an infusion, so what is
#   calculated from `c0` alone -- the auciv, aumciv, and aucivpbext families
#   and the clearances and volumes taken from them -- is bolus-only.
#
#   A dose duration makes a parameter infusion-capable, and it still applies
#   to a bolus because the duration is then zero.  So anything needing one
#   applies to every intravenous route, whether or not it also uses `c0`.
#
# `ceoi` declares itself, because a continuous infusion never reaches an end
# of infusion.
classify_routes <- function(all_intervals) {
  specs <- set_requires_inputs(names(all_intervals))
  needs_duration <-
    names(specs)[vapply(specs, function(x) isTRUE(x$requires_dose_dur), TRUE)]
  back_extrapolated <- deps_union("c0", all_intervals)
  iv_routes <- setdiff(pknca_routes(), "extravascular")
  lapply(
    X = stats::setNames(names(all_intervals), names(all_intervals)),
    FUN = function(n) {
      declared <- all_intervals[[n]]$selection$route
      if (!is.null(declared)) {
        declared
      } else if (n %in% needs_duration) {
        iv_routes
      } else if (n %in% back_extrapolated) {
        "iv_bolus"
      } else {
        pknca_routes()
      }
    }
  )
}

# Which dosing patterns each parameter applies to.  Declared wins and
# propagates to everything calculated from the declared parameter, so the small
# set of multiple-dose seeds carries its whole family.
classify_dosing <- function(all_intervals) {
  declared <-
    vapply(
      X = all_intervals,
      FUN = function(x) !is.null(x$selection$dosing),
      FUN.VALUE = TRUE
    )
  seeds <- names(all_intervals)[declared]
  multiple_seeds <-
    seeds[vapply(
      X = seeds,
      FUN = function(n) !("single" %in% all_intervals[[n]]$selection$dosing),
      FUN.VALUE = TRUE
    )]
  multiple_family <- deps_union(multiple_seeds, all_intervals)
  infinity_family <- deps_union(pknca_infinity_roots, all_intervals)
  lapply(
    X = stats::setNames(names(all_intervals), names(all_intervals)),
    FUN = function(n) {
      if (!is.null(all_intervals[[n]]$selection$dosing)) {
        all_intervals[[n]]$selection$dosing
      } else if (n %in% multiple_family) {
        c("multiple", "steady_state")
      } else if (n %in% infinity_family) {
        "single"
      } else {
        pknca_dosing()
      }
    }
  )
}

# Spot (blood, plasma, serum) or interval (urine, feces) collection.  A
# parameter that needs a sample volume is an interval collection.
classify_sample_types <- function(all_intervals) {
  specs <- set_requires_inputs(names(all_intervals))
  vapply(
    X = stats::setNames(names(all_intervals), names(all_intervals)),
    FUN = function(n) if (isTRUE(specs[[n]]$requires_volume)) "interval" else "spot",
    FUN.VALUE = ""
  )
}

# Needs sparse data:  the parameters only sparse data can produce (see
# sparse_only_params()), plus anything calculated from one of them -- a
# clearance built on a sparse AUC needs sparse data as much as the AUC does.
#
# A parameter with a sparse estimator *and* a dense function (`auclast`) is not
# sparse:  it is calculated for dense data too, just by a different function.
classify_sparse <- function(all_intervals) {
  sparse_only <- sparse_only_params()
  # Only the parameters with an estimator of their own are followed downstream.
  # A companion borrows the calculation function of the parameter it annotates,
  # so get.parameter.deps() would reach that parameter and its whole downstream
  # family; nothing is calculated from a standard error or a degrees of freedom
  # anyway, so there is nothing downstream of a companion to find.
  with_own_estimator <-
    names(all_intervals)[vapply(all_intervals, spec_is_sparse_only, FUN.VALUE = TRUE)]
  from_sparse <- union(deps_union(with_own_estimator, all_intervals), sparse_only)
  vapply(
    X = stats::setNames(names(all_intervals), names(all_intervals)),
    FUN = function(n) n %in% from_sparse,
    FUN.VALUE = TRUE
  )
}

# Needs inputs from more than one profile.  Declared, and propagated to
# everything calculated from a declared parameter.
classify_secondary <- function(all_intervals) {
  declared <-
    names(all_intervals)[
      vapply(
        all_intervals,
        function(x) {
          isTRUE(x$selection$secondary) ||
            any(vapply(interval_col_formalsmap(x), is_pknca_ref, TRUE))
        },
        TRUE
      )
    ]
  from_secondary <- deps_union(declared, all_intervals)
  vapply(
    X = stats::setNames(names(all_intervals), names(all_intervals)),
    FUN = function(n) n %in% from_secondary,
    FUN.VALUE = TRUE
  )
}

# Classify every registered parameter, caching the result until the registry
# changes.  add.interval.col() drops the cache, but a registry restored by
# assigning a saved copy back into the package environment (tests and other
# packages do this) bypasses it, so the cache also records the parameter names
# it was computed from and is recomputed when they differ.
parameter_classification <- function() {
  all_intervals <- get.interval.cols()
  all_intervals <- all_intervals[setdiff(names(all_intervals), c("start", "end"))]
  cached <- get0("parameter_classification", envir = .PKNCAEnv)
  if (!is.null(cached) && identical(cached$key, names(all_intervals))) {
    return(cached$value)
  }
  ret <-
    list(
      concept = classify_concepts(all_intervals),
      tier = vapply(all_intervals, function(x) x$tier %||% "uncommon", ""),
      route = classify_routes(all_intervals),
      dosing = classify_dosing(all_intervals),
      sample_type = classify_sample_types(all_intervals),
      sparse = classify_sparse(all_intervals),
      secondary = classify_secondary(all_intervals),
      dose_normalized =
        vapply(
          all_intervals,
          function(x) identical(x$FUN, "pk.calc.dn"),
          TRUE
        )
    )
  assign(
    "parameter_classification",
    list(key = names(all_intervals), value = ret),
    envir = .PKNCAEnv
  )
  ret
}

#' How each NCA parameter is classified for interval selection
#'
#' @param param Parameter names to describe.  The default is every registered
#'   parameter.
#' @returns A data.frame with one row per parameter and columns for the
#'   `concept`, `tier`, `sample_type`, whether it is `sparse`,
#'   `dose_normalized`, or `secondary` (needing inputs from more than one
#'   profile), and the `route` and `dosing` contexts it applies to
#'   (comma-separated).
#' @details A parameter whose concept could not be resolved has `NA` for
#'   `concept`.  That is not an error:  it is calculated normally when asked
#'   for by name, but it is never selected automatically.
#' @seealso [pknca_concept()], [get.interval.cols()]
#' @examples
#' head(pknca_parameter_table())
#' @family Interval specifications
#' @export
pknca_parameter_table <- function(param = NULL) {
  classification <- parameter_classification()
  if (is.null(param)) {
    param <- names(classification$concept)
  } else {
    assert_param_name(param)
    param <- intersect(param, names(classification$concept))
  }
  data.frame(
    parameter = param,
    concept = unname(classification$concept[param]),
    tier = unname(classification$tier[param]),
    sample_type = unname(classification$sample_type[param]),
    sparse = unname(classification$sparse[param]),
    secondary = unname(classification$secondary[param]),
    dose_normalized = unname(classification$dose_normalized[param]),
    route = vapply(classification$route[param], paste, collapse = ",", FUN.VALUE = ""),
    dosing = vapply(classification$dosing[param], paste, collapse = ",", FUN.VALUE = ""),
    row.names = NULL
  )
}

#' Report parameters that PKNCA cannot classify for automatic selection
#'
#' Intended for packages that register their own NCA parameters:  call it in
#' your tests to find parameters that will never be selected automatically
#' because they carry no concept.
#'
#' @inheritParams pknca_parameter_table
#' @returns A data.frame of the unclassifiable parameters, with the same
#'   columns as [pknca_parameter_table()].  Zero rows means everything is
#'   classified.
#' @seealso [pknca_concept()], [pknca_parameter_table()]
#' @examples
#' pknca_check_parameter_classification()
#' @family Interval specifications
#' @export
pknca_check_parameter_classification <- function(param = NULL) {
  ret <- pknca_parameter_table(param = param)
  ret[is.na(ret$concept) | !(ret$concept %in% pknca_concepts()), , drop = FALSE]
}
