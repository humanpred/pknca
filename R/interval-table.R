# Building an interval specification from a description of the analysis
#
# The classification in parameter-classification.R says what each parameter is
# and where it applies.  This turns a description of an analysis -- when the
# interval runs, how the drug was given, how often, and what was collected --
# into the interval specification that describes it.
#
# Three things follow from the context rather than being asked for:
#
#   the AUC a bounded interval uses, and therefore which clearance, volume, and
#   mean residence time follow from it;
#
#   whether concentrations are back-extrapolated to the time of a bolus;
#
#   which imputation is appropriate, and which parameters must not receive it.

# The AUCs an interval is built on.  A single dose is summarized by the AUC to
# the last measurable concentration and by the extrapolation to infinity.  A
# repeated dose is summarized over the interval itself, which needs the
# concentration at both boundaries, so it uses the AUCint family.
context_auc_basis <- function(dosing, clast_type) {
  inf_suffix <- paste0("inf.", clast_type)
  ret <-
    if (identical(dosing, "single")) {
      c("auclast", paste0("auc", inf_suffix))
    } else {
      c("aucint.last", paste0("aucint.", inf_suffix))
    }
  # The moment curve follows the same basis as the area, so that the mean
  # residence time and the volume at steady state have one to be built on
  c(ret, sub("^auc", "aumc", ret))
}

# What each AUC root is the basis for, cached because walking the dependency
# graph for every root is too slow to redo per interval.  Dropped when the
# registry changes, alongside the classification; the recorded parameter names
# additionally invalidate it when a registry is restored by assigning a saved
# copy, which bypasses add.interval.col().
auc_basis_families <- function() {
  key <- names(get.interval.cols())
  cached <- get0("auc_basis_families", envir = .PKNCAEnv)
  if (!is.null(cached) && identical(cached$key, key)) {
    return(cached$value)
  }
  roots <- pknca_auc_roots()
  ret <- stats::setNames(lapply(X = roots, FUN = get.parameter.deps), roots)
  assign("auc_basis_families", list(key = key, value = ret), envir = .PKNCAEnv)
  ret
}

# Every AUC and AUMC a parameter could be built on.  A parameter downstream of
# one of these is only offered when that one was chosen; a parameter downstream
# of none of them is offered whatever the basis.
pknca_auc_roots <- function() {
  ret <-
    c(
      "auclast", "aucall", "aucinf.obs", "aucinf.pred",
      "aucint.last", "aucint.all", "aucint.inf.obs", "aucint.inf.pred",
      "aucivlast", "aucivall", "aucivinf.obs", "aucivinf.pred",
      "aucivint.last", "aucivint.all"
    )
  intersect(c(ret, sub("^auc", "aumc", ret)), names(get.interval.cols()))
}

# The imputation an interval needs, assuming it starts at a dose.  An interval
# that starts partway through a profile has nothing to impute to, and an
# excreta or sparse analysis has no concentration to impute.
context_impute <- function(dosing, sample_type, sparse) {
  if (!identical(sample_type, "spot") || isTRUE(sparse)) {
    return(NA_character_)
  }
  switch(
    dosing,
    single = "start_predose_conc0",
    multiple = "start_cmin",
    steady_state = "start_predose"
  )
}

# Parameters that must not be calculated from an imputed concentration, because
# the imputed point would become the value they report.
#
# This is not every parameter an imputation changes.  Imputation changes the
# AUC and everything downstream of it, and that is the point of imputing.  What
# is listed here is the case where the answer is the imputation itself.
impute_exclusions <- function(impute, dosing) {
  if (is.na(impute)) {
    return(character(0))
  }
  ret <-
    switch(
      impute,
      # The imputed value is a measurement carried to the start time or a
      # fabricated one; either way it was not measured there
      start_predose = "count_conc_measured",
      start_predose_conc0 = "count_conc_measured",
      # start_cmin imputes the minimum, so a minimum calculated afterward is
      # the imputed value
      start_cmin = c("count_conc_measured", "tfirst", "cmin", "tmin"),
      # Dropping the concentration at the end of the interval removes exactly
      # the sample the trough reports
      end_conc_drop = "ctrough",
      character(0)
    )
  if (identical(dosing, "single") &&
      impute %in% c("start_predose", "start_predose_conc0")) {
    # A predose concentration is the C0 of the current dose only once a
    # previous dose has been given; before the first dose it is contamination
    ret <- c(ret, "c0")
  }
  intersect(ret, names(get.interval.cols()))
}

# The parameters a context can calculate, before include/exclude
context_parameters <- function(dosing, route, sample_type, sparse, tier, auc_basis) {
  classification <- parameter_classification()
  params <- names(classification$concept)
  keep <-
    vapply(
      X = params,
      FUN = function(n) {
        route %in% classification$route[[n]] &&
          dosing %in% classification$dosing[[n]] &&
          identical(classification$sample_type[[n]], sample_type) &&
          identical(classification$sparse[[n]], sparse) &&
          # A secondary parameter needs inputs from another profile, which one
          # interval cannot supply; it is reached by name through `include`
          !classification$secondary[[n]]
      },
      FUN.VALUE = TRUE
    )
  params <- params[keep]
  if (identical(tier, "common")) {
    params <- params[classification$tier[params] %in% "common"]
  }
  # Restrict to the chosen AUC basis:  a parameter built on an AUC that was not
  # chosen would duplicate one that was.
  #
  # The parameters that declare themselves multiple-dose are exempt.  The mean
  # residence time and volume at steady state after repeated dosing are built
  # on the single-dose AUCs by design -- they combine the extrapolation to
  # infinity with the area over the interval -- so the basis of the interval
  # does not decide between them.
  families <- auc_basis_families()
  basis_dependent <- sort(unique(unlist(families)))
  chosen <- sort(unique(unlist(families[intersect(auc_basis, names(families))])))
  multiple_dose <-
    params[vapply(
      X = params,
      FUN = function(n) !("single" %in% classification$dosing[[n]]),
      FUN.VALUE = TRUE
    )]
  params[!(params %in% basis_dependent) | params %in% chosen | params %in% multiple_dose]
}

# Turn `include`/`exclude` into parameter names.  A concept expands to the
# parameters of that concept the context can calculate; a parameter name is
# taken as-is.
resolve_selection <- function(x, available, arg_name) {
  if (is.null(x)) {
    return(character(0))
  }
  checkmate::assert_character(x, any.missing = FALSE, min.chars = 1)
  classification <- parameter_classification()
  known_params <- names(classification$concept)
  unknown <- setdiff(x, c(known_params, pknca_concepts()))
  if (length(unknown) > 0) {
    rlang::abort(
      sprintf(
        "`%s` must name NCA parameters or concepts; unknown: %s",
        arg_name, paste(unknown, collapse = ", ")
      ),
      class = "pknca_error_interval_unknown_selection"
    )
  }
  concepts <- intersect(x, pknca_concepts())
  from_concepts <-
    available[classification$concept[available] %in% concepts]
  unique(c(intersect(x, known_params), from_concepts))
}

#' Build an interval specification from a description of the analysis
#'
#' Chooses the NCA parameters to calculate for an interval, and the imputation
#' to calculate them from, given when the interval runs and how the drug was
#' given.  The result is a data.frame suitable for the `intervals` argument of
#' [PKNCAdata()].
#'
#' @param start,end The start and end time of the interval.  Both may be
#'   vectors, giving one set of rows per interval.
#' @param dosing Was the drug given once (`"single"`), repeatedly without
#'   assuming steady state (`"multiple"`), or repeatedly at steady state
#'   (`"steady_state"`)?  Asking for `"steady_state"` also gives the parameters
#'   that apply to any repeated dose.  See [pknca_dosing()].
#' @param route How the drug was given; see [pknca_routes()].
#' @param sample_type Were concentrations measured in samples taken at a point
#'   in time (`"spot"`, the usual case for blood, plasma, and serum) or in a
#'   collection over an interval (`"interval"`, the usual case for urine and
#'   feces)?  See [pknca_sample_types()].
#' @param sparse Is this a sparse sampling design?
#' @param tier `"common"` (the default) gives the parameters usually reported
#'   for the context; `"all"` gives every parameter it can calculate.
#' @param include,exclude NCA parameters or concepts (see [pknca_concepts()])
#'   to add to or remove from what the context gives.  A parameter named in
#'   both is an error.
#' @param impute The imputation to use, as for [PKNCAdata()].  The default of
#'   `NULL` chooses one from the context; `NA` uses none.
#' @param preset A named set of arguments to start from; see
#'   [pknca_presets()].  Arguments given explicitly override the preset.
#' @param clast_type Should the extrapolation to infinity use the observed
#'   (`"obs"`) or predicted (`"pred"`) last concentration?
#' @param ... Columns to add to every row, typically the groups the interval
#'   applies to.
#' @returns A data.frame with one or more rows per interval:  `start`, `end`, a
#'   logical column per parameter, an `impute` column when any imputation
#'   applies, and any columns given in `...`.  An interval is split into more
#'   than one row when some of its parameters must not be calculated from the
#'   imputed data.
#' @details The interval is assumed to start at a dose, which is what makes an
#'   imputation at the start meaningful.  Pass `impute = NA` for an interval
#'   that starts partway through a profile.
#'
#'   Which AUC the interval is built on follows from `dosing`:  a single dose
#'   uses AUClast and the extrapolation to infinity, and a repeated dose uses
#'   the AUCint family, which interpolates at both interval boundaries.  The
#'   clearance, volume, and mean residence time that follow from that AUC are
#'   chosen to match.
#' @seealso [pknca_parameter_table()] for how each parameter is classified,
#'   [PKNCAdata()], and the vignette "Selection of Calculation Intervals"
#' @examples
#' # A single oral dose
#' pknca_interval_table(0, 24, dosing = "single", route = "extravascular")
#'
#' # At steady state, with the fluctuation parameters added
#' pknca_interval_table(
#'   144, 168,
#'   dosing = "steady_state", route = "extravascular",
#'   include = "fluctuation"
#' )
#'
#' # A urine collection
#' pknca_interval_table(0, 24, dosing = "single", route = "extravascular",
#'                      sample_type = "interval")
#' @family Interval specifications
#' @export
pknca_interval_table <- function(start, end,
                                 dosing = "single",
                                 route = "extravascular",
                                 sample_type = "spot",
                                 sparse = FALSE,
                                 tier = "common",
                                 include = NULL,
                                 exclude = NULL,
                                 impute = NULL,
                                 preset = NULL,
                                 clast_type = "obs",
                                 ...) {
  if (!is.null(preset)) {
    args <- pknca_preset_args(preset)
    given <- names(as.list(match.call())[-1])
    for (n in setdiff(names(args), given)) {
      assign(n, args[[n]])
    }
  }
  checkmate::assert_numeric(start, any.missing = FALSE, finite = TRUE, min.len = 1)
  checkmate::assert_numeric(end, any.missing = FALSE, min.len = 1)
  dosing <- match.arg(dosing, choices = pknca_dosing())
  route <- match.arg(route, choices = pknca_routes())
  sample_type <- match.arg(sample_type, choices = pknca_sample_types())
  tier <- match.arg(tier, choices = c("common", "all"))
  clast_type <- match.arg(clast_type, choices = c("obs", "pred"))
  checkmate::assert_flag(sparse)

  conflict <- intersect(include, exclude)
  if (length(conflict) > 0) {
    rlang::abort(
      sprintf(
        "The following are in both `include` and `exclude`: %s",
        paste(conflict, collapse = ", ")
      ),
      class = "pknca_error_interval_include_exclude_conflict"
    )
  }

  auc_basis <- context_auc_basis(dosing = dosing, clast_type = clast_type)
  available <-
    context_parameters(
      dosing = dosing, route = route, sample_type = sample_type,
      sparse = sparse, tier = "all", auc_basis = auc_basis
    )
  params <-
    context_parameters(
      dosing = dosing, route = route, sample_type = sample_type,
      sparse = sparse, tier = tier, auc_basis = auc_basis
    )
  params <- union(params, resolve_selection(include, available, "include"))
  params <- setdiff(params, resolve_selection(exclude, available, "exclude"))
  if (length(params) == 0) {
    rlang::abort(
      "No parameters are left to calculate",
      class = "pknca_error_interval_no_parameters"
    )
  }

  if (is.null(impute)) {
    impute <- context_impute(dosing = dosing, sample_type = sample_type, sparse = sparse)
  }
  checkmate::assert_string(impute, na.ok = TRUE)
  excluded_from_impute <- intersect(params, impute_exclusions(impute, dosing = dosing))

  n_intervals <- max(length(start), length(end))
  interval_starts <- rep(start, length.out = n_intervals)
  interval_ends <- rep(end, length.out = n_intervals)
  # One row per interval and parameter, which interval_wider() collapses into
  # as many rows as the imputation needs
  long <-
    data.frame(
      start = rep(interval_starts, each = length(params)),
      end = rep(interval_ends, each = length(params)),
      param = rep(params, times = n_intervals)
    )
  long$impute <- ifelse(long$param %in% excluded_from_impute, NA_character_, impute)
  long[[pknca_interval_row_col]] <- rep(seq_len(n_intervals), each = length(params))
  extra <- list(...)
  for (n in names(extra)) {
    long[[n]] <- extra[[n]]
  }
  template <- data.frame(start = interval_starts, end = interval_ends)
  ret <- interval_wider(long, template)
  # An interval with no imputation anywhere does not need the column
  if ("impute" %in% names(ret) && all(is.na(ret$impute))) {
    ret$impute <- NULL
  }
  check.interval.specification(ret)
}

#' Named argument sets for building an interval specification
#'
#' @returns A named list of the arguments each preset gives to
#'   [pknca_interval_table()].  Arguments given to that function directly
#'   override the preset.
#' @seealso [pknca_interval_table()]
#' @examples
#' names(pknca_presets())
#' pknca_presets()$bioequivalence
#' @family Interval specifications
#' @export
pknca_presets <- function() {
  list(
    single_dose =
      list(dosing = "single", route = "extravascular"),
    steady_state =
      list(dosing = "steady_state", route = "extravascular"),
    bioequivalence =
      list(
        dosing = "single", route = "extravascular",
        include = c("aucall", "clast.obs", "tlast")
      ),
    first_in_human =
      list(
        dosing = "single", route = "extravascular",
        include = c("clast.obs", "tlast", "span.ratio")
      ),
    mass_balance =
      list(
        dosing = "single", route = "extravascular", sample_type = "interval",
        include = "excretion_rate"
      ),
    sparse_single_dose =
      list(dosing = "single", route = "extravascular", sparse = TRUE)
  )
}

pknca_preset_args <- function(preset) {
  checkmate::assert_string(preset)
  definitions <- pknca_presets()
  if (!(preset %in% names(definitions))) {
    rlang::abort(
      sprintf(
        "`preset` must be one of: %s",
        paste(names(definitions), collapse = ", ")
      ),
      class = "pknca_error_interval_unknown_preset"
    )
  }
  definitions[[preset]]
}
