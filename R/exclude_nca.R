#' Exclude NCA parameters based on examining the parameter set.
#'
#' @returns A function to give to [exclude()] as `FUN`.  Its
#'   `pknca_affected_parameters` attribute lists the parameters it can exclude,
#'   and its `pknca_options` attribute lists the [PKNCA.options()] entries its
#'   thresholds came from (see [pknca_exclude_rules()]).
#' @section Tmax coverage:
#'
#'   `exclude_nca_tmax_coverage()` compares each subject's samples with the
#'   Tmax values of its group; it flags a subject whose samples miss the usual
#'   Tmax times, and excludes only beyond the outer fences.  The group is the
#'   summary group of [summary.PKNCAresults()]:  every grouping column except
#'   the subject, with the interval start and end (so each part, treatment,
#'   analyte, and interval is its own group).  From the first and third
#'   quartiles of the Tmax values of every subject in the group (the subject
#'   being judged included), Tukey's inner fences are the quartiles extended
#'   by `k_warn` times the interquartile range, and the outer fences by
#'   `k_exclude` times it.  The quartiles are those of
#'   `stats::quantile(type = 7)`, the default type; with few subjects, the
#'   types differ (Tmax values of 1, 1, 2, 2, 1, and 8 give a third quartile
#'   of 2 with type 7, 3.5 with type 6, and 2.5 with type 8).  Tmax values
#'   that are missing or already excluded are not used.  The ranges never
#'   start before the interval start, where a reported range starts when its
#'   lower fence is below it.  A sample at the interval start counts only when
#'   the subject's dose at or before the interval start is an intravascular
#'   bolus (route intravascular and no duration or a duration of zero in
#'   [PKNCAdose()]), so a predose sample does not count after an extravascular
#'   dose or when the results have no dose data.
#'
#'   The samples are the concentration rows with an actual time within the
#'   interval (the rows that [pk.nca()] used) that have a concentration and
#'   are not excluded.  When the concentration data have a nominal time
#'   (`time.nominal` in [PKNCAconc()]), the samples are placed by their
#'   nominal time minus the interval start, so the nominal times must share
#'   the origin of the interval times (for example, the nominal time since the
#'   first dose); otherwise, they are placed by their actual time.  Times are
#'   never converted between units, and the time unit is only used in the
#'   text.
#'
#'   * A subject with no sample within the outer fences is excluded:  every
#'     parameter of that interval is excluded with a reason that gives the
#'     outer range and the subject's sample nearest to it.
#'   * A subject with a sample within the outer fences but none within the
#'     inner fences is flagged as a possible data issue and not excluded:  a
#'     `pknca_warning_tmax_coverage_outlier` warning has the fields `group` (a
#'     one-row data.frame with the group and subject), `tmax_range` (the inner
#'     range, relative to the interval start), and `nearest_sample` (the
#'     subject's sample nearest to it, relative to the interval start).
#'   * With nominal times, a subject with a sample within the inner fences
#'     that is missing some of the group's nominal times within them (see
#'     [pknca_missing_samples()]) gets a `pknca_message_tmax_coverage_partial`
#'     message that Cmax and Tmax may be unreliable.  Its fields are `group`,
#'     `tmax_range`, `time_nominal_missing`, and `reason` (as in
#'     [pknca_missing_samples()]).  Without nominal times, there is no
#'     schedule to compare with, and no message is given.
#'   * The warnings and messages can be caught with [withCallingHandlers()].
#'   * A group with fewer than `min_subjects` subjects with a Tmax (one subject,
#'     for example) is not checked, and a
#'     `pknca_message_tmax_coverage_few_subjects` message says so once per
#'     group.  Quartiles of fewer than four values describe the spread of the
#'     group poorly.
#'   * When the nominal times disagree with the interval, the group is not
#'     checked, and a `pknca_warning_tmax_coverage_no_nominal` warning says so
#'     once per group.  They disagree when no nominal time of the group is
#'     after the interval start, when most samples of the group with an
#'     actual time in the interval have a nominal time outside it, or when a
#'     subject's nominal times decrease while its actual times increase within
#'     the interval, as when the nominal times restart at each dose.
#'   * Sparse data have one Tmax per group, from the mean profile, so they are
#'     not checked, and a `pknca_message_tmax_coverage_sparse` message says so
#'     once per call to [exclude()].
#' @examples
#' my_conc <- PKNCAconc(data.frame(conc=1.1^(3:0),
#'                                 time=0:3,
#'                                 subject=1),
#'                      conc~time|subject)
#' my_data <- PKNCAdata(my_conc,
#'                      intervals=data.frame(start=0, end=Inf,
#'                                           aucinf.obs=TRUE,
#'                                           aucpext.obs=TRUE))
#' my_result <- pk.nca(my_data)
#' my_result_excluded <- exclude(my_result,
#'                               FUN=exclude_nca_max.aucinf.pext())
#' as.data.frame(my_result_excluded)
#' @name exclude_nca
#' @family Result exclusions
NULL

#' Register an automatic NCA result exclusion rule
#'
#' Each `exclude_nca_*()` factory is registered right after its definition (so
#' this is defined first in the file), the way interval columns are registered
#' with [add.interval.col()].  The registry holds only what the factory cannot
#' say about itself, its descriptions; the parameters a rule can exclude and
#' the options it uses are read from the function the factory returns (see
#' `exclude_nca_describe()`).
#'
#' The registration is the only place the descriptions are written:  the
#' factory's documentation is generated from it with
#' `@eval pknca_rd_exclude_rule()`, so the descriptions are plain text (they
#' are shown as they are by [pknca_exclude_rules()]).
#'
#' @param name The name of the exported factory function
#' @param description The one-line description ("Exclude based on ...")
#' @param arguments A named character vector with the description of each
#'   argument of the factory, named by argument
#' @returns `NULL`, invisibly
#' @keywords Internal
#' @noRd
pknca_register_exclude_rule <- function(name, description, arguments = character()) {
  checkmate::assert_string(name, pattern = "^exclude_nca_")
  checkmate::assert_string(description, pattern = "^Exclude based on ")
  checkmate::assert_character(arguments, min.chars = 1, any.missing = FALSE, names = "unique")
  current <- get("exclude_rules", envir = .PKNCAEnv)
  current[[name]] <- list(description = description, arguments = arguments)
  assign("exclude_rules", current, envir = .PKNCAEnv)
  invisible(NULL)
}

#' Get a threshold from PKNCA.options(), remembering which option it came from
#'
#' @param name The option name
#' @returns The option value, with the option name in its `pknca_option`
#'   attribute, which [exclude_nca_by_param()] records on the exclusion
#'   function
#' @keywords Internal
#' @noRd
exclude_nca_option <- function(name) {
  structure(PKNCA.options(name), pknca_option = name)
}

#' Record what an exclusion function can exclude and the options it uses
#'
#' @param fun The exclusion function that a factory returns
#' @param affected The parameters it can exclude
#' @param options The `PKNCA.options()` names its thresholds came from
#' @returns `fun` with the attributes `pknca_affected_parameters` and
#'   `pknca_options`
#' @keywords Internal
#' @noRd
exclude_nca_describe <- function(fun, affected, options = character()) {
  attr(fun, "pknca_affected_parameters") <- sort(unique(as.character(affected)))
  attr(fun, "pknca_options") <- sort(unique(as.character(options)))
  fun
}

#' The parameters an exclusion function can exclude
#'
#' @param fun A function returned by an `exclude_nca_*()` factory
#' @returns A sorted character vector of parameter names
#' @keywords Internal
#' @noRd
exclude_nca_affected_parameters <- function(fun) {
  attr(fun, "pknca_affected_parameters", exact = TRUE)
}

#' The PKNCA options that an exclusion function's thresholds came from
#'
#' @inheritParams exclude_nca_affected_parameters
#' @returns A sorted character vector of option names (empty when every
#'   threshold was given)
#' @keywords Internal
#' @noRd
exclude_nca_options_used <- function(fun) {
  attr(fun, "pknca_options", exact = TRUE)
}

# A parameter that depends on the half-life is excluded with it, but a
# calculation that could have used the half-life and did not must not be (#270):
# an AUCint over an interval that ends at or before Tlast is interpolated
# throughout, so no exclusion of the half-life reaches it.  pk.calc.auxcint()
# reports the extrapolation it used in the method column, and that is what says
# whether the half-life entered the result.  A result that reports no
# extrapolation says nothing either way, so it keeps the exclusion.
exclude_nca_halflife_dependent <- function(FUN) {
  ret_fun <- function(x, ...) {
    ret <- FUN(x, ...)
    if ("PPANMETH" %in% names(x)) {
      reports_extrapolation <-
        grepl(pattern = pknca_extrap_method_prefix, x = x$PPANMETH, fixed = TRUE)
      used_halflife <-
        grepl(
          pattern = paste0(pknca_extrap_method_prefix, pknca_extrap_method_halflife),
          x = x$PPANMETH,
          fixed = TRUE
        )
      ret[reports_extrapolation & !used_halflife] <- NA_character_
    }
    ret
  }
  exclude_nca_describe(
    ret_fun,
    affected = exclude_nca_affected_parameters(FUN),
    options = exclude_nca_options_used(FUN)
  )
}

#' @eval pknca_rd_exclude_rule("exclude_nca_span.ratio")
#' @export
exclude_nca_span.ratio <- function(min.span.ratio) {
  if (missing(min.span.ratio)) {
    min.span.ratio <- exclude_nca_option("min.span.ratio")
  }
  exclude_nca_halflife_dependent(
    exclude_nca_by_param(
      parameter = "span.ratio",
      min_thr = min.span.ratio,
      affected_parameters = get.parameter.deps("half.life")
    )
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_span.ratio",
  description = "Exclude based on the half-life span ratio",
  arguments =
    c(min.span.ratio = 'The minimum acceptable span ratio (uses PKNCA.options("min.span.ratio") if not provided).')
)

#' @eval pknca_rd_exclude_rule("exclude_nca_max.aucinf.pext")
#' @export
exclude_nca_max.aucinf.pext <- function(max.aucinf.pext) {
  if (missing(max.aucinf.pext)) {
    max.aucinf.pext <- exclude_nca_option("max.aucinf.pext")
  }
  # Exclude for both obs and pred
  exc_obs <-
    exclude_nca_by_param(
      parameter = "aucpext.obs",
      max_thr = max.aucinf.pext,
      affected_parameters = get.parameter.deps("aucinf.obs")
    )
  exc_pred <-
    exclude_nca_by_param(
      parameter = "aucpext.pred",
      max_thr = max.aucinf.pext,
      affected_parameters = get.parameter.deps("aucinf.pred")
    )
  ret_fun <- function(x, ...) {
    res_obs <- exc_obs(x, ...)
    res_pred <- exc_pred(x, ...)
    # Combine results, prioritizing non-NA from either
    is.obs <- grepl(paste0("aucpext.obs > ", max.aucinf.pext), res_obs)
    is.pred <- grepl(paste0("aucpext.pred > ", max.aucinf.pext), res_pred)
    ret <- ifelse(
      is.obs | is.pred,
      gsub(
        pattern = paste0("aucpext...+ > ", max.aucinf.pext),
        replacement = paste0("aucpext > ", max.aucinf.pext),
        x = dplyr::coalesce(res_obs, res_pred)
      ),
      res_obs
    )
    ret
  }
  exclude_nca_describe(
    ret_fun,
    affected = c(exclude_nca_affected_parameters(exc_obs), exclude_nca_affected_parameters(exc_pred)),
    options = c(exclude_nca_options_used(exc_obs), exclude_nca_options_used(exc_pred))
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_max.aucinf.pext",
  description = "Exclude based on the percent of AUC extrapolated to infinity (both observed and predicted)",
  arguments =
    c(max.aucinf.pext = 'The maximum acceptable percent AUC extrapolation (uses PKNCA.options("max.aucinf.pext") if not provided).')
)

#' @eval pknca_rd_exclude_rule("exclude_nca_count_conc_measured")
#' @export
exclude_nca_count_conc_measured <- function(min_count, exclude_param_pattern = c("^aucall", "^aucinf", "^aucint", "^auciv", "^auclast", "^aumc", "^sparse_auc")) {
  all_parameters <- names(get.interval.cols())
  affected_parameters_base <-
    sort(unique(unlist(
      lapply(
        X = exclude_param_pattern,
        FUN = grep,
        x = all_parameters,
        value = TRUE
      )
    )))
  affected_parameters <-
    sort(unique(unlist(
      lapply(
        X = affected_parameters_base,
        FUN = get.parameter.deps
      )
    )))
  exclude_nca_by_param(
    parameter = "count_conc_measured",
    min_thr = min_count,
    affected_parameters = affected_parameters
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_count_conc_measured",
  description = "Exclude based on the count of concentrations measured and not below the lower limit of quantification (affects AUC and AUMC parameters)",
  arguments =
    c(
      min_count = "Minimum number of measured concentrations",
      exclude_param_pattern = "Character vector of regular expression patterns to exclude"
    )
)

#' @eval pknca_rd_exclude_rule("exclude_nca_min.hl.r.squared")
#' @export
exclude_nca_min.hl.r.squared <- function(min.hl.r.squared) {
  if (missing(min.hl.r.squared)) {
    min.hl.r.squared <- exclude_nca_option("min.hl.r.squared")
  }
  exclude_nca_halflife_dependent(
    exclude_nca_by_param(
      parameter = "r.squared",
      min_thr = min.hl.r.squared,
      affected_parameters = get.parameter.deps("half.life")
    )
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_min.hl.r.squared",
  description = "Exclude based on half-life r-squared",
  arguments =
    c(min.hl.r.squared = 'The minimum acceptable r-squared value for half-life (uses PKNCA.options("min.hl.r.squared") if not provided).')
)

#' @eval pknca_rd_exclude_rule("exclude_nca_min.hl.adj.r.squared")
#' @export
exclude_nca_min.hl.adj.r.squared <- function(min.hl.adj.r.squared = 0.9) {
  exclude_nca_halflife_dependent(
    exclude_nca_by_param(
      parameter = "adj.r.squared",
      min_thr = min.hl.adj.r.squared,
      affected_parameters = get.parameter.deps("half.life")
    )
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_min.hl.adj.r.squared",
  description = "Exclude based on half-life adjusted r-squared",
  arguments =
    c(min.hl.adj.r.squared = "The minimum acceptable adjusted r-squared for half-life (uses 0.9 if not provided).")
)

#' @eval pknca_rd_exclude_rule("exclude_nca_tmax_early")
#' @export
exclude_nca_tmax_early <- function(tmax_early = 0) {

    exc_fun <- exclude_nca_by_param(
      parameter = "tmax",
      min_thr = tmax_early,
      # start and end are interval columns, never result parameters
      affected_parameters = setdiff(names(get.interval.cols()), c("start", "end"))
    )

    ret_fun <- function(x, ...) {
    # Get the exclusion messages
    ret <- exc_fun(x, ...)
    # Add the special annotation for tmax_early cases (if not already annotated)
    tmax_cases <- grepl(pattern = "^tmax < ", x = ret)
    tmax_already_annotated <- grepl("(likely missed dose, insufficient PK samples, or PK sample swap)", x = ret, fixed = TRUE)
    ret <- ifelse(
        test = tmax_cases & !tmax_already_annotated & !is.na(ret),
        yes = gsub(
          pattern = paste0("^tmax < ", tmax_early),
          replacement = paste0("tmax < ", tmax_early, " (likely missed dose, insufficient PK samples, or PK sample swap)"),
          x = ret
        ),
        no = ret
      )
    ret
    }
    exclude_nca_describe(
      ret_fun,
      affected = exclude_nca_affected_parameters(exc_fun),
      options = exclude_nca_options_used(exc_fun)
    )
}
pknca_register_exclude_rule(
  name = "exclude_nca_tmax_early",
  description = "Exclude based on implausibly early Tmax (often used for extravascular dosing with a Tmax value of 0)",
  arguments =
    c(tmax_early = "The time for Tmax which is considered too early to be a valid NCA result")
)

#' @eval pknca_rd_exclude_rule("exclude_nca_tmax_0")
#' @export
exclude_nca_tmax_0 <- function() {
  exc_fun <- exclude_nca_tmax_early(1e-99)
  ret_fun <- function(x, ...) {
    ret <- exc_fun(x, ...)

    # Replace the messages
    ret <- gsub(
      pattern = "^tmax < 1e-99",
      replacement = "tmax <= 0",
      x = ret
    )
    ret
  }
  exclude_nca_describe(
    ret_fun,
    affected = exclude_nca_affected_parameters(exc_fun),
    options = exclude_nca_options_used(exc_fun)
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_tmax_0",
  description = "Exclude based on implausibly early Tmax (special case for tmax_early = 0)"
)


#' @eval pknca_rd_exclude_rule("exclude_nca_tmax_coverage")
#' @export
exclude_nca_tmax_coverage <- function(min_subjects = 4, k_warn = 1.5, k_exclude = 3) {
  checkmate::assert_int(min_subjects, lower = 2)
  checkmate::assert_number(k_warn, lower = 0, finite = TRUE)
  checkmate::assert_number(k_exclude, lower = k_warn, finite = TRUE)
  affected_parameters <- setdiff(names(get.interval.cols()), c("start", "end"))
  # The inputs shared by the subjects of one exclude() call, and each group's
  # verdicts, are kept here so that each is computed once per call
  cache <- new.env(parent = emptyenv())
  ret_fun <- function(x, object, ...) {
    exclude_nca_tmax_coverage_subject(
      x = x,
      object = object,
      settings = list(min_subjects = min_subjects, k_warn = k_warn, k_exclude = k_exclude),
      affected_parameters = affected_parameters,
      cache = cache
    )
  }
  exclude_nca_describe(ret_fun, affected = affected_parameters)
}
pknca_register_exclude_rule(
  name = "exclude_nca_tmax_coverage",
  description = "Exclude based on whether a subject has a sample within Tukey's fences around the Tmax values of its group; the rule flags a subject with no sample within the inner fences, and excludes only a subject with no sample within the outer fences",
  arguments =
    c(
      min_subjects = "The fewest subjects with a Tmax in a group for the group to be checked (smaller groups are not checked, with a message)",
      k_warn = "The multiple of the interquartile range that sets the inner fences; a subject with no sample within them gets a warning",
      k_exclude = "The multiple of the interquartile range that sets the outer fences (at least k_warn); a subject with no sample within them is excluded"
    )
)

#' Judge the Tmax coverage of one subject and interval
#'
#' [exclude()] calls the rule once for each subject and interval.  The inputs
#' that every subject shares are prepared on the first call for an object, and
#' the verdicts of a whole group on the first call for a subject of that group;
#' later calls look their verdict up.  A call for a subject and interval that
#' was already seen starts a new [exclude()] call, so the cache is prepared
#' again and the group-level messages and warnings are given again.
#'
#' @param x The results of one subject and interval (one group of
#'   [exclude()])
#' @param object The PKNCAresults object
#' @param settings A list of the `min_subjects`, `k_warn`, and `k_exclude`
#'   arguments of [exclude_nca_tmax_coverage()]
#' @param affected_parameters The parameters that an exclusion applies to
#' @param cache The environment that holds the prepared inputs and verdicts
#' @returns The exclusion reasons for the rows of `x`
#' @keywords Internal
#' @noRd
exclude_nca_tmax_coverage_subject <- function(x, object, settings, affected_parameters, cache) {
  if (!inherits(object, "PKNCAresults")) {
    rlang::abort(
      "exclude_nca_tmax_coverage() checks NCA results; use it with exclude() on a PKNCAresults object",
      class = "pknca_error_tmax_coverage_not_results"
    )
  }
  ret <- rep(NA_character_, nrow(x))
  idx_tmax <- which(x$PPTESTCD == "tmax")
  if (length(idx_tmax) > 1) {
    rlang::abort(
      "Should not see more than one tmax (please report this as a bug)",
      class = "pknca_error_internal_duplicate_parameter"
    )
  }
  # identical() first compares the objects' addresses, so it is quick for the
  # object that exclude() gives to every call
  if (!identical(cache$object, object)) {
    exclude_nca_tmax_coverage_prepare(object = object, cache = cache)
  }
  call_key <- pknca_interval_group_key(x[1, , drop = FALSE], cache$call_cols)
  if (exists(call_key, envir = cache$seen, inherits = FALSE)) {
    exclude_nca_tmax_coverage_prepare(object = object, cache = cache)
  }
  assign(call_key, TRUE, envir = cache$seen)
  if (cache$sparse) {
    return(ret)
  }
  # A subject without a usable Tmax of its own is not judged
  if (length(idx_tmax) == 0 || is.na(x$PPORRES[idx_tmax]) || !(x[[object$columns$exclude]][idx_tmax] %in% c(NA, ""))) {
    return(ret)
  }
  current <- x[idx_tmax, , drop = FALSE]
  group_key <- pknca_interval_group_key(current, cache$summary_group_cols)
  if (is.null(cache$groups[[group_key]])) {
    cache$groups[[group_key]] <-
      exclude_nca_tmax_coverage_group(current = current, group_key = group_key, settings = settings, cache = cache)
  }
  verdict <- cache$groups[[group_key]][[pknca_interval_group_key(current, cache$conc_group_cols)]]
  if (!is.null(verdict$reason)) {
    ret[x$PPTESTCD %in% affected_parameters] <- verdict$reason
  }
  if (!is.null(verdict$warning)) {
    do.call(rlang::warn, verdict$warning)
  }
  if (!is.null(verdict$message)) {
    do.call(rlang::inform, verdict$message)
  }
  ret
}

#' Prepare the inputs that every subject of an exclude() call shares
#'
#' @inheritParams exclude_nca_tmax_coverage_subject
#' @returns `NULL`, invisibly; `cache` is filled in
#' @keywords Internal
#' @noRd
exclude_nca_tmax_coverage_prepare <- function(object, cache) {
  rm(list = ls(cache), envir = cache)
  cache$object <- object
  cache$seen <- new.env(parent = emptyenv())
  cache$groups <- list()
  o_conc <- as_PKNCAconc(object)
  cache$sparse <- is_sparse_pk(object)
  # The groups that exclude() calls the rule with (see exclude.default())
  cache$call_cols <-
    unique(c(names(getGroups(object)), intersect(names(object$result), c("start", "end"))))
  if (cache$sparse) {
    rlang::inform(
      "Tmax coverage is not checked for sparse data:  each group has one Tmax, from its mean profile",
      class = "pknca_message_tmax_coverage_sparse"
    )
    return(invisible(NULL))
  }
  cache$subject_col <- o_conc$columns$subject
  cache$conc_group_cols <- group_vars(o_conc)
  cache$conc_peer_cols <- setdiff(cache$conc_group_cols, cache$subject_col)
  cache$summary_group_cols <- get_summary_PKNCAresults_drop_group(object = object, drop_group = cache$subject_col)

  all_tmax <- object$result[object$result$PPTESTCD == "tmax", , drop = FALSE]
  all_tmax <- all_tmax[!is.na(all_tmax$PPORRES) & all_tmax[[object$columns$exclude]] %in% c(NA, ""), , drop = FALSE]
  cache$all_tmax <- all_tmax
  cache$all_tmax_key <- pknca_interval_group_key(all_tmax, cache$summary_group_cols)

  conc_data <- as.data.frame(o_conc)
  cache$conc_data <- conc_data
  cache$conc_excluded <- !is.na(normalize_exclude(o_conc))
  cache$conc_peer_key <- pknca_interval_group_key(conc_data, cache$conc_peer_cols)
  cache$conc_col <- o_conc$columns$concentration
  cache$actual_col <- o_conc$columns$time
  cache$nominal_col <- o_conc$columns$time.nominal
  cache$use_nominal <- !is.null(cache$nominal_col)
  cache$time_col <- if (cache$use_nominal) cache$nominal_col else cache$actual_col
  cache$time_type <- if (cache$use_nominal) "nominal" else "actual"
  timeu <- pknca_cdisc_get_timeu_orig(object)
  cache$unit_text <- if (is.na(timeu)) "" else paste0(" ", timeu)

  # The doses, to find each subject's route at the interval start
  o_dose <- as_PKNCAdose(object)
  cache$has_dose <- !identical(o_dose, NA) && length(o_dose$columns$time) == 1
  if (cache$has_dose) {
    dose_data <- as.data.frame(o_dose)
    cache$dose_key_cols <- intersect(unlist(o_dose$columns$groups), cache$conc_group_cols)
    cache$dose_key <- pknca_interval_group_key(dose_data, cache$dose_key_cols)
    cache$dose_time <- dose_data[[o_dose$columns$time]]
    cache$dose_route <- getAttributeColumn(o_dose, attr_name = "route", warn_missing = character())[[1]]
    cache$dose_duration <- getAttributeColumn(o_dose, attr_name = "duration", warn_missing = character())[[1]]
  }
  invisible(NULL)
}

#' Does a sample at the interval start count toward a subject's coverage?
#'
#' It does when the dose at or before the interval start is an intravascular
#' bolus (as [PKNCAdose()] records it:  route intravascular with no duration
#' or a duration of zero), since the concentration then peaks at the start.
#' Without dose data, it does not.
#'
#' @param subject The subject's Tmax row of the results
#' @param start The interval start
#' @param tolerance The tolerance for comparing times
#' @inheritParams exclude_nca_tmax_coverage_subject
#' @returns `TRUE` or `FALSE`
#' @keywords Internal
#' @noRd
exclude_nca_tmax_coverage_start_counts <- function(subject, start, tolerance, cache) {
  if (!cache$has_dose) {
    return(FALSE)
  }
  subject_key <- pknca_interval_group_key(subject, cache$dose_key_cols)
  candidates <- which(cache$dose_key == subject_key & !is.na(cache$dose_time) & cache$dose_time <= start + tolerance)
  if (length(candidates) == 0) {
    return(FALSE)
  }
  last_dose <- candidates[which.max(cache$dose_time[candidates])]
  identical(
    dose_route_for_intervals(route = cache$dose_route[last_dose], duration = cache$dose_duration[last_dose]),
    "iv_bolus"
  )
}

#' The verdicts for every subject of one group and interval
#'
#' Messages and warnings about the whole group are given here, so once per
#' group in an exclude() call.
#'
#' @param current The tmax row of the first subject of the group to be judged
#' @param group_key The key of the group (see `pknca_interval_group_key()`)
#' @inheritParams exclude_nca_tmax_coverage_subject
#' @returns A list named by the subject's key (of the concentration grouping
#'   columns) with, for each subject, `reason` (the exclusion reason),
#'   `warning` (the arguments to [rlang::warn()]), and `message` (the arguments
#'   to [rlang::inform()]), each `NULL` when there is none; an empty list when
#'   the group is not checked
#' @keywords Internal
#' @noRd
exclude_nca_tmax_coverage_group <- function(current, group_key, settings, cache) {
  peers <- cache$all_tmax[cache$all_tmax_key == group_key, , drop = FALSE]
  group_text <- name_value_text(current[, cache$summary_group_cols, drop = FALSE])
  unit_text <- cache$unit_text
  if (nrow(peers) < settings$min_subjects) {
    rlang::inform(
      sprintf(
        "Tmax coverage is not checked for %s:  %d subject(s) have a Tmax, fewer than the %d needed (min_subjects)",
        group_text, nrow(peers), settings$min_subjects
      ),
      class = "pknca_message_tmax_coverage_few_subjects"
    )
    return(list())
  }
  # Type 7 is the default of stats::quantile(); with few subjects, the types
  # give different quartiles, so it is fixed here and in the documentation
  quartiles <- stats::quantile(peers$PPORRES, probs = c(0.25, 0.75), names = FALSE, type = 7)
  iqr <- quartiles[2] - quartiles[1]
  # Samples before the interval start are not in the interval, so the ranges
  # start at the interval start at the earliest
  inner_range <- c(max(quartiles[1] - settings$k_warn * iqr, 0), quartiles[2] + settings$k_warn * iqr)
  outer_range <- c(max(quartiles[1] - settings$k_exclude * iqr, 0), quartiles[2] + settings$k_exclude * iqr)
  # Times relative to the interval start are differences, which can differ
  # from the Tmax values in the last bits
  tolerance <- sqrt(.Machine$double.eps) * max(1, abs(outer_range))

  start <- current$start
  end <- current$end
  time_col <- cache$time_col
  conc_data <- cache$conc_data
  peer_key <- pknca_interval_group_key(current, cache$conc_peer_cols)
  is_group <- cache$conc_peer_key == peer_key
  # The samples of the interval are those that pk.nca() used, selected by
  # their actual time; with nominal times, they are then placed by those
  actual <- conc_data[[cache$actual_col]]
  in_interval <- is_group & !is.na(actual) & actual >= start - tolerance & actual <= end + tolerance
  if (cache$use_nominal) {
    mismatch <-
      exclude_nca_tmax_coverage_nominal_mismatch(
        cache = cache, is_group = is_group, in_interval = in_interval,
        start = start, end = end, tolerance = tolerance
      )
    if (!is.null(mismatch)) {
      rlang::warn(
        sprintf(
          "Tmax coverage is not checked for %s:  %s, so the nominal times may not share the origin of the actual times and the interval (%g to %g%s)",
          group_text, mismatch, start, end, unit_text
        ),
        class = "pknca_warning_tmax_coverage_no_nominal"
      )
      return(list())
    }
  }
  group_conc <- conc_data[in_interval, , drop = FALSE]
  group_excluded <- cache$conc_excluded[in_interval]
  subject_rows <- split(seq_len(nrow(group_conc)), pknca_interval_group_key(group_conc, cache$conc_group_cols))
  inner_text <-
    sprintf("%s time %g to %g%s after the interval start", cache$time_type, inner_range[1], inner_range[2], unit_text)
  outer_text <-
    sprintf("%s time %g to %g%s after the interval start", cache$time_type, outer_range[1], outer_range[2], unit_text)
  status_rows <- list()
  if (cache$use_nominal) {
    status <-
      pknca_nominal_sample_status(
        data = group_conc,
        group_cols = cache$conc_peer_cols,
        subject_col = cache$subject_col,
        nominal_col = cache$nominal_col,
        conc_col = cache$conc_col,
        excluded = group_excluded,
        complete = TRUE
      )
    status_rows <- split(seq_len(nrow(status)), pknca_interval_group_key(status, cache$conc_group_cols))
  }

  peer_subject_key <- pknca_interval_group_key(peers, cache$conc_group_cols)
  ret <- list()
  for (idx_peer in seq_len(nrow(peers))) {
    current_key <- peer_subject_key[idx_peer]
    subject_group <- as.data.frame(peers[idx_peer, unique(c(cache$summary_group_cols, cache$subject_col)), drop = FALSE])
    rownames(subject_group) <- NULL
    start_counts <- exclude_nca_tmax_coverage_start_counts(subject = peers[idx_peer, , drop = FALSE], start = start, tolerance = tolerance, cache = cache)
    rows <- subject_rows[[current_key]]
    if (is.null(rows)) rows <- integer()
    usable <- !is.na(group_conc[[cache$conc_col]][rows]) & !group_excluded[rows]
    position <- group_conc[[time_col]][rows][usable] - start
    # Unscheduled samples have no nominal time to place them by
    position <- position[!is.na(position)]
    if (!start_counts) {
      position <- position[position > tolerance]
    }
    nearest <- exclude_nca_tmax_coverage_nearest(position, outer_range)
    nearest_text <-
      if (length(position) == 0 && !start_counts) {
        "no sample after the interval start"
      } else if (length(position) == 0) {
        "no sample in the interval"
      } else {
        sprintf("nearest sample at %g%s", nearest, unit_text)
      }
    verdict <- list(reason = NULL, warning = NULL, message = NULL)
    if (!any(exclude_nca_tmax_in_range(position, tmax_range = outer_range, start_counts = start_counts, tolerance = tolerance))) {
      verdict$reason <- sprintf("no sample in the outer Tmax range of the group (%s, %s)", outer_text, nearest_text)
    } else if (!any(exclude_nca_tmax_in_range(position, tmax_range = inner_range, start_counts = start_counts, tolerance = tolerance))) {
      nearest_inner <- exclude_nca_tmax_coverage_nearest(position, inner_range)
      verdict$warning <-
        list(
          message =
            sprintf(
              "Possible data issue for %s:  no sample in the inner Tmax range of the group (%s, nearest sample at %g%s); not excluded, since a sample is in the outer range",
              name_value_text(subject_group), inner_text, nearest_inner, unit_text
            ),
          class = "pknca_warning_tmax_coverage_outlier",
          group = subject_group,
          tmax_range = inner_range,
          nearest_sample = nearest_inner
        )
    } else if (cache$use_nominal) {
      current_status <- status[status_rows[[current_key]], , drop = FALSE]
      missing_in_range <-
        current_status$status != "present" &
        exclude_nca_tmax_in_range(current_status[[cache$nominal_col]] - start, tmax_range = inner_range, start_counts = start_counts, tolerance = tolerance)
      if (any(missing_in_range)) {
        missing_times <- current_status[[cache$nominal_col]][missing_in_range]
        verdict$message <-
          list(
            message =
              sprintf(
                "Cmax and Tmax may be unreliable for %s:  no usable sample at nominal time %s%s, within the inner Tmax range of the group (%s)",
                name_value_text(subject_group),
                paste(sprintf("%g", missing_times), collapse = ", "),
                unit_text,
                inner_text
              ),
            class = "pknca_message_tmax_coverage_partial",
            group = subject_group,
            tmax_range = inner_range,
            time_nominal_missing = missing_times,
            reason = current_status$status[missing_in_range]
          )
      }
    }
    ret[[current_key]] <- verdict
  }
  ret
}

#' The sample time nearest to a range
#'
#' @param position Sample times relative to the interval start
#' @param tmax_range The lower and upper bounds of the range
#' @returns The time in `position` nearest to the range (the first of equally
#'   near times), or `NA` when there is none
#' @keywords Internal
#' @noRd
exclude_nca_tmax_coverage_nearest <- function(position, tmax_range) {
  if (length(position) == 0) {
    return(NA_real_)
  }
  distance <- pmax(tmax_range[1] - position, position - tmax_range[2], 0)
  position[which.min(distance)]
}

#' Do the nominal times of a group disagree with its interval?
#'
#' The nominal times are compared with the interval as they are, so they must
#' share the origin of the actual times.  Nominal times relative to each dose
#' instead (restarting at every dose) disagree:  most samples whose actual time
#' is after the interval start then have a nominal time outside the interval,
#' no nominal time of the group is after the interval start at all, or, for an
#' interval with more than one dose, a subject's nominal times decrease while
#' its actual times increase (see `pknca_nominal_restart_keys()`).
#'
#' @param is_group A logical vector:  is the concentration row in the group?
#' @param in_interval A logical vector:  is the concentration row in the group
#'   and the interval (by its actual time)?
#' @param start,end The interval
#' @param tolerance The tolerance for comparing times
#' @inheritParams exclude_nca_tmax_coverage_subject
#' @returns `NULL` when they agree, or text describing the disagreement
#' @keywords Internal
#' @noRd
exclude_nca_tmax_coverage_nominal_mismatch <- function(cache, is_group, in_interval, start, end, tolerance) {
  nominal <- cache$conc_data[[cache$nominal_col]][is_group]
  actual <- cache$conc_data[[cache$actual_col]][is_group]
  nominal_after_start <- !is.na(nominal) & nominal > start + tolerance & nominal <= end + tolerance
  if (!any(nominal_after_start)) {
    return("no nominal time of the group is after the interval start")
  }
  actual_after_start <- !is.na(actual) & actual > start + tolerance & actual <= end + tolerance
  outside <- actual_after_start & !is.na(nominal) & (nominal < start - tolerance | nominal > end + tolerance)
  # A few samples drawn near the interval bounds can disagree when the doses
  # were not given at their nominal times; most of them disagree when the
  # origins differ
  if (sum(outside) > sum(actual_after_start) / 2) {
    return(
      sprintf(
        "%d of the %d samples of the group with an actual time in the interval have a nominal time outside it",
        sum(outside), sum(actual_after_start)
      )
    )
  }
  restarts <-
    pknca_nominal_restart_keys(
      data = cache$conc_data[in_interval, , drop = FALSE],
      id_cols = cache$conc_group_cols,
      actual_col = cache$actual_col,
      nominal_col = cache$nominal_col
    )
  if (length(restarts) > 0) {
    return(
      sprintf(
        "the nominal times of %d subject(s) decrease while the actual times increase within the interval",
        length(restarts)
      )
    )
  }
  NULL
}

#' Which times are within the Tmax range
#'
#' @param position Times relative to the interval start
#' @param tmax_range The lower and upper bounds of the range
#' @param start_counts Does a time at the interval start count (see
#'   `exclude_nca_tmax_coverage_start_counts()`)?
#' @param tolerance The tolerance for comparing times
#' @returns A logical vector, one value per `position`
#' @keywords Internal
#' @noRd
exclude_nca_tmax_in_range <- function(position, tmax_range, start_counts, tolerance) {
  position >= tmax_range[1] - tolerance &
    position <= tmax_range[2] + tolerance &
    (start_counts | position > tolerance)
}

#' @eval pknca_rd_exclude_rule("exclude_nca_by_param", describe_in = NULL)
#' @description
#' Exclude rows from NCA results based on specified thresholds for a given parameter.
#' This function allows users to define minimum and/or maximum acceptable values
#' for a parameter and excludes rows that fall outside these thresholds.
#'
#' @returns A function that can be used with `PKNCA::exclude` to mark through the 'exclude'  column
#'          the rows in the PKNCA results based on the specified thresholds for a parameter.
#'          Its `pknca_affected_parameters` attribute lists the parameters it can mark
#'          (see [pknca_exclude_rules()]).
#' @examples
#' # Example dataset
#' my_data <- PKNCA::PKNCAdata(
#'   PKNCA::PKNCAconc(data.frame(conc = 5:1,
#'                               time = 0:4,
#'                               subject = 1),
#'                    conc ~ time | subject),
#'   PKNCA::PKNCAdose(data.frame(subject = 1, dose = 100, time = 0),
#'                    dose ~ time | subject)
#' )
#' my_result <- PKNCA::pk.nca(my_data)
#'
#' # Exclude rows where span.ratio is less than 2
#' excluded_result <- PKNCA::exclude(
#'   my_result,
#'   FUN = exclude_nca_by_param("span.ratio", min_thr = 2)
#' )
#' as.data.frame(excluded_result)
#'
#' @export

exclude_nca_by_param <- function(
  parameter,
  min_thr = NULL,
  max_thr = NULL,
  affected_parameters = parameter
) {
  # Check that defined thresholds are single numeric objects (assert_*, not
  # expect_*:  checkmate's expect_* functions are testthat expectations)
  checkmate::assert_number(min_thr, finite = TRUE, null.ok = TRUE)
  checkmate::assert_number(max_thr, finite = TRUE, null.ok = TRUE)

  if (isTRUE(min_thr > max_thr)) {
    rlang::abort("if both defined min_thr must be less than max_thr", class = "pknca_error_min_thr_gt_max_thr")
  }

  ret_fun <- function(x, ...) {
    ret <- rep(NA_character_, nrow(x))
    idx_param <- which(x$PPTESTCD == parameter)
    idx_aff_params <- which(x$PPTESTCD %in% affected_parameters)

    if (length(idx_param) > 1) {
      rlang::abort(
        sprintf(
          "Should not see more than one %s (please report this as a bug)",
          parameter
        ),
        class = "pknca_error_internal_duplicate_parameter"
      )
    }

    if (length(idx_param) == 1 && !is.na(x$PPORRES[idx_param]) && length(idx_aff_params) > 0) {
      current_value <- x$PPORRES[idx_param]
      pretty_name <- parameter # Pretty name did not convince me for some parameters (e.g, "r.squared")
      if (isTRUE(current_value < min_thr)) {
        ret[idx_aff_params] <- sprintf("%s < %g", pretty_name, min_thr)
      } else if (isTRUE(current_value > max_thr)) {
        ret[idx_aff_params] <- sprintf("%s > %g", pretty_name, max_thr)
      }
    }
    ret
  }
  exclude_nca_describe(
    ret_fun,
    affected = affected_parameters,
    options = c(attr(min_thr, "pknca_option", exact = TRUE), attr(max_thr, "pknca_option", exact = TRUE))
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_by_param",
  description = "Exclude based on NCA parameter thresholds",
  arguments =
    c(
      parameter = 'The name of the PKNCA parameter to evaluate (e.g., "span.ratio").',
      min_thr = "The minimum acceptable value for the parameter. If not provided, is not applied.",
      max_thr = "The maximum acceptable value for the parameter. If not provided, is not applied.",
      affected_parameters = "Character vector of PKNCA parameters that will be marked as excluded. By default is the defined parameter."
    )
)
