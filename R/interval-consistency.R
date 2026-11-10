# Whether the parameters an interval requests are calculated on one basis
#
# pknca_interval_table() builds an interval on one set of AUCs (see
# context_auc_basis()):  a single dose on AUClast (or AUCall) and the
# extrapolation to infinity with the observed (or predicted) last
# concentration, and a repeated dose on the AUCint family with the same
# choices.  A parameter calculated from AUCs is on a basis when an AUC it is
# calculated from is in that basis (as pknca_interval_table() chooses them; the
# percent extrapolated is calculated from AUClast and AUCinf, for example), and
# two parameters are consistent when one basis holds both.  So `aucint.all` (a
# repeated-dose basis with AUCall) and `cav.last` (calculated from AUClast) are
# not, nor are `cl.obs` (AUCinf,obs) and `vz.pred` (AUCinf,pred).  The
# multiple-dose mean residence time is calculated from the single-dose AUCs, so
# it is consistent with them.
#
# The AUCs and AUMCs, and their percent extrapolated (the AUC reports), are not
# judged against each other, because reporting AUClast with AUCall, or
# AUCinf,obs with AUCinf,pred, is common; for the same reason, an AUC report is
# judged against a parameter calculated from AUCs only on whether they are
# single-dose or interval AUCs and AUClast or AUCall, not on AUCinf,obs or
# AUCinf,pred.  A parameter calculated from no AUC (Cmax, Ctrough, the swing) is
# consistent with every basis, and so, as pknca_interval_table() treats them,
# is a parameter that applies only to repeated dosing:  the multiple-dose mean
# residence time combines the AUC over the dosing interval with the
# extrapolation to infinity by its definition.  The route and the sample type are
# not judged:  one interval commonly applies to IV and oral groups of a
# crossover, or to plasma and urine, and each parameter is only calculated for
# the profiles it applies to.
#
# Every requested parameter is also judged against the end of its interval:  a
# parameter that needs a finite end (see finite_interval_params()) cannot be
# requested for an interval that ends at infinity.

# The concepts of the AUC reports, which are not judged against each other
auc_report_concepts <- c("auc", "aumc", "auc_extrapolation")

# How a mixture of the values of each dimension of the basis is described
consistency_dimensions <-
  c(
    dosing = "single-dose AUCs (AUClast, AUCall, AUCinf) mixed with interval AUCs (AUCint)",
    auc_type = "AUClast mixed with AUCall",
    clast_type = "AUCinf,obs mixed with AUCinf,pred",
    end = "a parameter that needs a finite interval end"
  )

# The most problems listed in one warning
max_consistency_problems <- 20

# The IV bolus AUC (or AUMC) that back-extrapolates the given one, when
# registered:  auclast -> aucivlast, aucint.inf.obs -> aucivint.inf.obs
auc_iv_counterpart <- function(x) {
  intersect(sub("^au(m?)c", "au\\1civ", x), names(get.interval.cols()))
}

# The AUC bases, which parameters fit each, and which parameters are judged.
# Cached, and dropped when the registry changes, because it is built from the
# whole registry.
interval_consistent_sets <- function() {
  key <- names(get.interval.cols())
  cached <- get0("interval_consistent_sets", envir = .PKNCAEnv)
  if (!is.null(cached) && identical(cached$key, key)) {
    return(cached$value)
  }
  bases <-
    expand.grid(
      dosing = c("single", "multiple"),
      auc_type = c("last", "all"),
      clast_type = c("obs", "pred"),
      stringsAsFactors = FALSE
    )
  basis_aucs <-
    lapply(
      X = seq_len(nrow(bases)),
      FUN = basis_aucs_for,
      bases = bases
    )
  aucs_of <- parameter_basis_aucs()
  params <- names(aucs_of)
  # Which bases hold an AUC of each parameter
  fits <- matrix(FALSE, nrow = length(params), ncol = nrow(bases), dimnames = list(params, NULL))
  for (p in params) {
    for (i in seq_len(nrow(bases))) {
      fits[p, i] <- any(aucs_of[[p]] %in% basis_aucs[[i]])
    }
  }
  # A parameter that applies only to repeated dosing is not judged (see above)
  classification <- parameter_classification()
  repeated_only <-
    params[!vapply(X = classification$dosing[params], FUN = `%in%`, x = "single", FUN.VALUE = TRUE)]
  judged <- setdiff(params[rowSums(fits) > 0], repeated_only)
  fits <- fits[judged, , drop = FALSE]
  # Which bases each parameter fits when AUCinf,obs and AUCinf,pred are not
  # told apart
  basis_without_clast <- paste(bases$dosing, bases$auc_type)
  fits_without_clast <-
    vapply(
      X = unique(basis_without_clast),
      FUN = fits_any_basis,
      fits = fits, basis_group = basis_without_clast,
      FUN.VALUE = logical(length(judged))
    )
  fits_without_clast <-
    matrix(fits_without_clast, nrow = length(judged), dimnames = list(judged, NULL))
  value <-
    list(
      bases = bases,
      fits = fits,
      compatible = tcrossprod(fits * 1) > 0,
      compatible_with_report = tcrossprod(fits_without_clast * 1) > 0,
      judged = judged,
      is_report = stats::setNames(classification$concept[judged] %in% auc_report_concepts, judged),
      finite_only = finite_interval_params()
    )
  assign("interval_consistent_sets", list(key = key, value = value), envir = .PKNCAEnv)
  value
}

# The AUCs each parameter is calculated from (an AUC is calculated from
# itself).  auc_basis_families() follows `depends`; a parameter that takes an
# AUC through pknca_ref() (renal clearance) and the parameters calculated from
# it are added by following every parameter's references until none is added.
parameter_basis_aucs <- function() {
  all_intervals <- get.interval.cols()
  families <- auc_basis_families()
  ret <- list()
  for (root in names(families)) {
    for (p in families[[root]]) {
      ret[[p]] <- union(ret[[p]], root)
    }
  }
  refs <-
    lapply(
      X = stats::setNames(nm = names(all_intervals)),
      FUN = parameter_direct_refs,
      all_intervals = all_intervals, optional_dose = TRUE
    )
  repeat {
    added <- FALSE
    for (p in names(refs)) {
      inherited <- unique(unlist(ret[intersect(refs[[p]], names(ret))], use.names = FALSE))
      new_aucs <- setdiff(inherited, ret[[p]])
      if (length(new_aucs) > 0) {
        ret[[p]] <- c(ret[[p]], new_aucs)
        added <- TRUE
      }
    }
    if (!added) {
      break
    }
  }
  ret[sort(names(ret))]
}

# Whether each parameter fits any basis in one group of bases
fits_any_basis <- function(group, fits, basis_group) {
  rowSums(fits[, basis_group == group, drop = FALSE]) > 0
}

# The AUCs and AUMCs of one basis, with their IV bolus counterparts
basis_aucs_for <- function(i, bases) {
  ret <-
    context_auc_basis(
      dosing = bases$dosing[i], clast_type = bases$clast_type[i], auc_type = bases$auc_type[i]
    )
  ret <- intersect(ret, names(get.interval.cols()))
  c(ret, auc_iv_counterpart(ret))
}

# The problems with the parameters of one interval, as text
interval_param_problems <- function(params, infinite_end, consistent) {
  ret <- character()
  if (infinite_end) {
    needs_finite <- intersect(params, consistent$finite_only)
    if (length(needs_finite) > 0) {
      ret <-
        sprintf(
          "%s (%s)", paste(needs_finite, collapse = ", "), consistency_dimensions[["end"]]
        )
    }
  }
  judged <- intersect(params, consistent$judged)
  for (a in seq_along(judged)) {
    for (b in seq_along(judged)[-seq_len(a)]) {
      pair <- judged[c(a, b)]
      any_report <- any(consistent$is_report[pair])
      if (all(consistent$is_report[pair])) {
        next
      }
      compatible <- if (any_report) consistent$compatible_with_report else consistent$compatible
      if (compatible[pair[1], pair[2]]) {
        next
      }
      pair <- sort(pair)
      reason <- pair_reason(pair, consistent, any_report)
      ret <- c(ret, sprintf("%s with %s (%s)", pair[1], pair[2], reason))
    }
  }
  ret
}

# The dimensions on which the bases that one parameter fits and the bases that
# the other fits do not overlap
pair_reason <- function(pair, consistent, any_report) {
  fits_first <- consistent$fits[pair[1], ]
  fits_second <- consistent$fits[pair[2], ]
  dims <- if (any_report) c("dosing", "auc_type") else c("dosing", "auc_type", "clast_type")
  disjoint <-
    dims[vapply(
      X = dims,
      FUN = dimension_disjoint,
      bases = consistent$bases, fits_first = fits_first, fits_second = fits_second,
      FUN.VALUE = TRUE
    )]
  if (length(disjoint) == 0) {
    return("not calculated on one basis")
  }
  paste(consistency_dimensions[disjoint], collapse = "; ")
}

dimension_disjoint <- function(dim, bases, fits_first, fits_second) {
  length(intersect(bases[[dim]][fits_first], bases[[dim]][fits_second])) == 0
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
  params <- intersect(union(consistent$judged, consistent$finite_only), names(intervals))
  if (length(params) == 0) {
    return(invisible(NULL))
  }
  requested <-
    matrix(FALSE, nrow = nrow(intervals), ncol = length(params), dimnames = list(NULL, params))
  for (p in params) {
    requested[, p] <- intervals[[p]] %in% TRUE
  }
  infinite_end <- is.infinite(pknca_interval_bound_number(intervals$end))
  pattern <- paste(infinite_end, apply(requested, 1, paste, collapse = ""))
  # The number of intervals with each problem
  problems <- integer()
  for (current in unique(pattern)) {
    rows <- which(pattern == current)
    row_problems <-
      interval_param_problems(
        params = params[requested[rows[1], ]],
        infinite_end = infinite_end[rows[1]],
        consistent = consistent
      )
    for (problem in row_problems) {
      problems[problem] <- sum(problems[problem], length(rows), na.rm = TRUE)
    }
  }
  if (length(problems) == 0) {
    return(invisible(NULL))
  }
  lines <-
    sprintf(
      "%s (%d %s)", names(problems), problems,
      ifelse(problems == 1, "interval", "intervals")
    )
  if (length(lines) > max_consistency_problems) {
    lines <-
      c(
        lines[seq_len(max_consistency_problems)],
        sprintf("... and %d more", length(lines) - max_consistency_problems)
      )
  }
  rlang::warn(
    paste0(
      "Some intervals request parameters that are not calculated on one basis, ",
      "so they may not describe the same thing:\n",
      paste0("  ", lines, collapse = "\n")
    ),
    class = "pknca_warning_interval_inconsistent_parameters"
  )
  invisible(NULL)
}
