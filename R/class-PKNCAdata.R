#' Create a PKNCAdata object.
#'
#' `PKNCAdata()` combines `PKNCAconc` and `PKNCAdose` objects and adds in the
#' intervals for PK calculations.
#'
#' @inheritParams PKNCA.choose.option
#' @param data.conc Concentration data as a `PKNCAconc` object or a data frame
#' @param data.dose Dosing data as a `PKNCAdose` object (see details)
#' @param impute Methods for imputation.  `NA` for to search for the column
#'   named "impute" in the intervals or no imputation if that column does not
#'   exist, a comma-or space-separated list of names, or the name of a column in
#'   the `intervals` data.frame (any column name works, not only `"impute"`, and
#'   the column must be character).  [get_impute_method()] gives the exact rule.
#'   See `vignette("v08-data-imputation", package="PKNCA")` for more details.
#' @param formula.conc Formula for making a `PKNCAconc` object with `data.conc`.
#'   This must be given if `data.conc` is a data.frame, and it must not be given
#'   if `data.conc` is a `PKNCAconc` object.
#' @param formula.dose Formula for making a `PKNCAdose` object with `data.dose`.
#'   This must be given if `data.dose` is a data.frame, and it must not be given
#'   if `data.dose` is a `PKNCAdose` object.
#' @param intervals A data frame with the AUC interval specifications as defined
#'   in [check.interval.specification()].  If missing, this will be
#'   automatically chosen by [choose.auc.intervals()]. (see details)  With
#'   date-time data, `start` and `end` may be date-times (see the "Date-time
#'   input" section).
#' @param units A data.frame of unit assignments and conversions as created by
#'   [pknca_units_table()]
#' @param group_ref The reference profiles for automatically-linked secondary
#'   parameters, as a data.frame of group values, optionally
#'   parameter-specific (see Details).  `NULL` (the default) derives the
#'   reference from the data.
#' @param grpid_cols The grouping columns that prefix the interval number in
#'   the PPGRPID column of `as.data.frame(results, out_format = "cdisc")`, as a
#'   named character vector of [PKNCAconc()] grouping columns (other than the
#'   subject and analyte), each with the text written before its value (see
#'   [as.data.frame.PKNCAresults()]).  It is the default for the `grpid_cols`
#'   argument there, so every output of one analysis agrees.  `NULL` (the
#'   default) gives an interval-only identifier.
#' @param grpid_numeric The names of the columns in `grpid_cols` whose values
#'   are whole numbers of at least 1, such as the period, written as that
#'   number in PPGRPID.  It is the default for the `grpid_numeric` argument of
#'   [as.data.frame.PKNCAresults()].  `NULL` (the default) names no columns.
#' @param ... arguments passed to `PKNCAdata.default`
#' @returns A PKNCAdata object with concentration, dose, interval, and
#'   calculation options stored (note that PKNCAdata objects can also have
#'   results after a NCA calculations are done to the data).
#' @details If `data.dose` is not given or is `NA`, then the `intervals` must be
#'   given.  At least one of `data.dose` and `intervals` must be given.
#'
#'   A secondary parameter is calculated from a result in another interval, and
#'   the interval specification links the two with an `interval_id` column and a
#'   `<parameter>_ref` pointer (see [interval_add_secondary()]).  An
#'   `interval_id` identifies one interval:  rows that share it (an interval
#'   split by imputation, for example) may differ only in the parameters they
#'   request, never in `start`, `end`, or the groups.  Where a request
#'   has no pointer and could not otherwise be calculated, [pk.nca()] derives the
#'   reference profile from the data:  a parameter measured on an interval
#'   collection whose inputs are spot samples (renal clearance) takes the nearest
#'   profile with no collection volume, and `group_ref` restricts -- or, for
#'   anything else, supplies -- the profiles that may be used.  The derived
#'   reference interval is created for the calculation only and is not added to
#'   the intervals in the result.  When more than one profile is equally close,
#'   the affected results are `NA` with the reason in the `exclude` column and a
#'   `pknca_warning_secondary_auto_reference` warning.
#'
#'   `group_ref` takes three forms.  A data.frame of group values applies to
#'   every secondary parameter:  its columns must be group columns of the
#'   concentration data, every column must match (and) for at least one of its
#'   rows (or), and every value must appear in the data -- for example, with
#'   groups crossing `TRTP`, `PCTEST`, and `PCSPEC`,
#'   `group_ref = data.frame(PCSPEC = "PLASMA")` directs renal-clearance
#'   references to the plasma profiles and
#'   `group_ref = data.frame(PCTEST = "midazolam")` directs metabolite ratios
#'   to the parent analyte.  The same data.frame with a `parameter` column
#'   applies each row only to the secondary parameter it names, and the columns
#'   a parameter's rows leave `NA` do not apply to it, so one table can steer
#'   renal clearance by `PCSPEC` and a metabolite ratio by `PCTEST`:
#'   `group_ref = data.frame(parameter = c("clr.obs", "ratio.aucinf.obs"),
#'   PCSPEC = c("PLASMA", NA), PCTEST = c(NA, "midazolam"))`.  A named list of
#'   data.frames, one per parameter, says the same thing:
#'   `group_ref = list(clr.obs = data.frame(PCSPEC = "PLASMA"),
#'   ratio.aucinf.obs = data.frame(PCTEST = "midazolam"))`.
#' @section Date-time input:
#'
#'   The concentration and dose times may be date-times (POSIXct) or dates
#'   (Date).  `PKNCAdata()` checks them and keeps them as they are, and
#'   [pk.nca()] converts them to numeric time before it calculates, so the
#'   intervals can still be changed after `PKNCAdata()`:
#'
#'   * The time reference is the first dose (ignoring excluded doses) within
#'     each combination of the grouping variables (and the subject) shared by
#'     the concentration and dose formulas.  With `dose~time|Part+Subject`,
#'     each subject's first dose in each study part (or period, for a
#'     crossover) is time 0; with `dose~time|Subject`, each subject's first
#'     dose of the study is time 0.  The dose formula must include the subject,
#'     so that one reference is never shared by several subjects.
#'   * A subject (group) without an included dose time uses its first
#'     concentration (the first one not excluded) as the reference, with a
#'     warning.  Without dosing data, every reference is the first
#'     concentration, within each combination of the concentration grouping
#'     variables to the left of any `/` (so analytes share their subject's
#'     reference).
#'   * Sparse data use one reference per group rather than per subject, because
#'     every subject in a sparse group shares the group's dosing.
#'   * Numeric time is in the time unit of the [PKNCAconc()] object:
#'     `timeu_pref` when given, otherwise `timeu`, otherwise hours (without
#'     units).  Numeric concentration collection and dosing durations are in
#'     that unit, and difftime durations are converted to it.
#'   * Manually specified `intervals` may be numeric times relative to the
#'     time reference, in that unit, or date-times.  Date-time `start` and
#'     `end` (POSIXct, or Date for 08:00, with a warning) are converted
#'     relative to the reference of the group each row applies to.  A row that
#'     does not name every reference group (for example, a row without
#'     `Subject`) applies to every matching group and becomes one row per
#'     group, because one absolute window is a different relative window for
#'     each subject.  A date-time `start` may pair with `end = Inf` (or a
#'     POSIXct `Inf`), which stays infinite; the start must be finite, both
#'     bounds must otherwise be date-times, and the time zone must match the
#'     data.  `PKNCAdata()` and [set_intervals()] check date-time intervals,
#'     and [pk.nca()] converts them; converted intervals have an
#'     `interval_time_kind` column (`"datetime"`, or `"relative"` for numeric
#'     rows added later).  The conversion gives the window only:  a window
#'     starting before a subject's first measurement still needs an
#'     imputation rule (`impute`) for a concentration at its start.
#'   * The results of [pk.nca()] keep the converted data that the calculation
#'     used (`results$data`), with the time reference of each group in its
#'     `time_reference` element and the `time_reference_type` column saying
#'     whether it is the `"first_dose"` or the `"first_conc"`;
#'     `as.data.frame(results, out_format = "cdisc")` gives, in the PPRFTDTC
#'     column, the date-time of the reference of each row:  the dose that
#'     starts its interval, or the first concentration for a `"first_conc"`
#'     group (see [as.data.frame.PKNCAresults()]).
#'
#'   Both times must be date-times (or dates), not one numeric and one
#'   date-time; date-times must have the same time zone; and the dose formula
#'   must include the subject of dense data.  Otherwise, it is an error.
#'   Differences are elapsed time, so a change to or from daylight saving time
#'   is handled correctly when the time zone is a named zone (like
#'   `"America/New_York"`).
#' @family PKNCA objects
#' @seealso [choose.auc.intervals()], [pk.nca()], [pknca_units_table()]
#' @export
PKNCAdata <- function(data.conc, data.dose, ...) {
  UseMethod("PKNCAdata", data.conc)
}

# Ensure that arguments are reversible
#' @rdname PKNCAdata
#' @export
PKNCAdata.PKNCAconc <- function(data.conc, data.dose, ...) {
  PKNCAdata.default(data.conc=data.conc, data.dose=data.dose, ...)
}

#' @rdname PKNCAdata
#' @export
PKNCAdata.PKNCAdose <- function(data.conc, data.dose, ...) {
  # Swap the arguments
  PKNCAdata.default(data.dose=data.conc, data.conc=data.dose, ...)
}

#' @rdname PKNCAdata
#' @export
PKNCAdata.default <- function(data.conc, data.dose, ...,
                              formula.conc, formula.dose,
                              impute = NA_character_,
                              intervals, units, options=list(), group_ref = NULL,
                              grpid_cols = NULL, grpid_numeric = NULL) {
  if (length(list(...))) {
    rlang::abort(
      "Unknown argument provided to PKNCAdata.  All arguments other than `data.conc` and `data.dose` must be named.",
      class = "pknca_error_unknown_argument"
    )
  }
  ret <- list()
  # Generate the conc element
  if (inherits(data.conc, "PKNCAconc")) {
    if (!missing(formula.conc)) {
      rlang::warn(
        "data.conc was given as a PKNCAconc object.  Ignoring formula.conc",
        class = "pknca_warning_dataconc_formulaconc"
      )
    }
    ret$conc <- data.conc
  } else {
    ret$conc <- PKNCAconc(data.conc, formula=formula.conc)
  }
  # Generate the dose element
  if (missing(data.dose)) {
    ret$dose <- NA
  } else if (identical(data.dose, NA)) {
    ret$dose <- NA
  } else if (inherits(data.dose, "PKNCAdose")) {
    if (!missing(formula.dose))
      rlang::warn(
        "data.dose was given as a PKNCAdose object.  Ignoring formula.dose",
        class = "pknca_warning_dataconc_formuladose"
      )
    ret$dose <- data.dose
  } else {
    ret$dose <- PKNCAdose(data.dose, formula.dose)
  }
  # Check the options
  checkmate::assert_list(
    x = options,
    names = if (length(options) > 0) "named" else NULL
  )

  if (length(options) > 0) {
    checkmate::assert_named(options)
    for (n in names(options)) {
      tmp.opt <- list(options[[n]], TRUE)
      names(tmp.opt) <- c(n, "check")
      do.call(PKNCA.options, tmp.opt)
    }
  }
  ret$options <- options

  # Which profiles the automatic reference finder may use for secondary
  # parameters
  ret$group_ref <- assert_group_ref(group_ref, ret$conc)

  # Which grouping columns prefix the CDISC PPGRPID
  ret$grpid_cols <- assert_grpid_cols(grpid_cols, ret$conc, grpid_numeric)
  ret$grpid_numeric <- grpid_numeric

  # Assign the class and give it all back to the user.
  class(ret) <- c("PKNCAdata", class(ret))

  # The object keeps date-time times and difftime durations, and pk.nca()
  # converts them to numbers.  Converting a copy here checks them now and gives
  # the numeric times that automatic intervals are chosen from.
  ret_numeric <- pknca_datetime_convert(ret, warn = FALSE)

  # Check the intervals
  if (missing(intervals) && identical(ret$dose, NA)) {
    rlang::abort("If data.dose is not given, intervals must be given", class = "pknca_error_missing_intervals")
  } else if (missing(intervals)) {
    # Generate the intervals for each grouping of concentration and
    # dosing.
    if (length(ret$dose$columns$time) == 0) {
      rlang::abort(
        "Dose times were not given, so intervals must be manually specified.",
        class = "pknca_error_missing_dose_times"
      )
    }
    o_conc_numeric <- as_PKNCAconc(ret_numeric)
    # The unit column comes along so that each group's dosing interval can be
    # matched to the nominal intervals for its time unit
    n_conc_dose <-
      full_join_PKNCAconc_PKNCAdose(
        o_conc = o_conc_numeric,
        o_dose = as_PKNCAdose(ret_numeric),
        extra_cols_conc = pknca_timeu_extra_col(o_conc_numeric)
      )
    n_conc_dose$data_intervals <- rep(list(NULL), nrow(n_conc_dose))
    # The single.dose.aucs option is only consulted by the legacy method; the
    # builder gives a single dose one interval to infinity, with no 24 in it to
    # be in the wrong unit.
    auto_interval_method <-
      PKNCA.choose.option(name = "auto.interval.method", options = options)
    used_single_dose_aucs <- FALSE
    for (idx in seq_len(nrow(n_conc_dose))) {
      current_conc <- n_conc_dose$data_conc[[idx]]
      current_dose <- n_conc_dose$data_dose[[idx]]
      current_group <-
        n_conc_dose[
          idx,
          setdiff(names(n_conc_dose), c("data_conc", "data_dose", "data_sparse_conc", "data_intervals")),
          drop=FALSE
        ]
      warning_prefix <- pknca_group_warning_prefix(current_group)
      if (!is.null(current_conc)) {
        generated_intervals <-
          pknca_with_regimen_warnings(
            prefix = warning_prefix,
            choose.auc.intervals(
            current_conc$time,
            current_dose$time,
            options=options,
            route=
              dose_route_for_intervals(
                route=current_dose$route,
                duration=current_dose$duration
              ),
            sparse=is_sparse_pk(ret$conc),
            time.conc.nominal=current_conc[["time.nominal"]],
            time.dosing.nominal=current_dose[["time.nominal"]],
            timeu=
              pknca_group_timeu(
                o_conc=o_conc_numeric,
                data_conc=current_conc,
                data_sparse_conc=n_conc_dose[["data_sparse_conc"]][[idx]],
                group=current_group
              )
            )
          )
        # choose.auc.intervals() uses single.dose.aucs for one dose time
        used_single_dose_aucs <-
          used_single_dose_aucs ||
          (identical(auto_interval_method, "legacy") &&
             length(unique(current_dose$time)) == 1)
        if (nrow(generated_intervals) > 0) {
          n_conc_dose$data_intervals[[idx]] <- generated_intervals
        } else {
          rlang::warn(
            sprintf(
              "%sNo intervals generated likely due to limited concentration data",
              warning_prefix
            ),
            class = "pknca_warning_no_intervals_limited_data"
          )
        }
      } else {
        rlang::warn(
          sprintf(
            "%sNo intervals generated due to no concentration data",
            warning_prefix
          ),
          class = "pknca_warning_no_intervals_generated"
        )
      }
    }
    intervals <-
      tidyr::unnest(
        n_conc_dose[, setdiff(names(n_conc_dose), c("data_conc", "data_dose", "data_sparse_conc")), drop=FALSE],
        cols="data_intervals"
      )
    if (used_single_dose_aucs) {
      pknca_warn_single_dose_aucs_unit(o_conc = ret$conc, options = options)
    }
  }
  # The intervals check allows the column that the imputation setting names, so
  # it sees the setting; the setting itself is stored after the units
  ret_with_impute <- ret
  if (!identical(NA, impute)) {
    checkmate::assert_character(impute, len = 1)
    ret_with_impute$impute <- impute
  }
  # Date-time interval bounds are checked here and converted by pk.nca()
  ret$intervals <- set_intervals(data = ret_with_impute, intervals = intervals)$intervals
  ret$intervals <- check.interval.specification(ret$intervals, impute = impute)
  # Verify that either everything or nothing is using units
  units_interval_start <- inherits(ret$intervals$start, "units")
  units_interval_end <- inherits(ret$intervals$end, "units")

  # Insert the unit conversion table
  if (missing(units)) {
    # Use the new automatic units table builder
    ret$units <- pknca_units_table(ret)
  } else {

    checkmate::assert_data_frame(units)

    missing_unit_cols <- setdiff(c("PPTESTCD", "PPORRESU"), names(units))
    if (length(missing_unit_cols) > 0) {
      rlang::abort(
        "`units` data.frame must have at least names 'PPTESTCD' and 'PPORRESU'",
        class = "pknca_error_units_missing_cols"
      )
    }

    checkmate::assert_data_frame(units, min.rows = 1)

    ret$units <- units
  }

  # Insert the imputation methods, if applicable
  if (!identical(NA, impute)) {
    ret$impute <- ret_with_impute$impute
  }

  ret
}


#' The prefix that names a group in a warning
#'
#' @param group A one-row data.frame of the group columns
#' @returns `"name=value; name=value: "`, or `""` without group columns
#' @keywords Internal
#' @noRd
pknca_group_warning_prefix <- function(group) {
  if (ncol(group) == 0) {
    return("")
  }
  paste0(
    paste(names(group), unlist(lapply(group, as.character)), sep="=", collapse="; "),
    ": "
  )
}

#' Warn when the default single-dose intervals are used with a time unit that is
#' not hours
#'
#' The default `single.dose.aucs` option is written for hours (0 to 24 and 0 to
#' infinity), so with another time unit its 24 means 24 of that unit.  Only the
#' `"legacy"` value of the `auto.interval.method` option consults that table;
#' the intervals built for a single dose otherwise run from the dose to
#' infinity and assume no time unit.
#'
#' @param o_conc The PKNCAconc object (after any date-time conversion)
#' @param options The `options` argument given to [PKNCAdata()]
#' @returns `NULL`, invisibly (after a warning, when it applies)
#' @keywords Internal
#' @noRd
pknca_warn_single_dose_aucs_unit <- function(o_conc, options) {
  single_dose_aucs <- PKNCA.choose.option(name = "single.dose.aucs", options = options)
  if (!identical(single_dose_aucs, PKNCA_options_defaults("single.dose.aucs"))) {
    return(invisible(NULL))
  }
  timeu <-
    if (!is.null(o_conc$units$timeu)) {
      as.vector(o_conc$units$timeu)
    } else if (!is.null(o_conc$columns$timeu)) {
      unique(as.character(as.data.frame(o_conc)[[o_conc$columns$timeu]]))
    }
  timeu <- timeu[!is.na(timeu)]
  if (!requireNamespace("units", quietly = TRUE)) {
    # Without the units package, only "hr" is recognized, which never warns
    return(invisible(NULL)) # nocov
  }
  # Units that are not recognizable as time units cannot be judged
  hours_factor <- vapply(X = timeu, FUN = pknca_hours_factor, FUN.VALUE = 1)
  not_hours <- timeu[!is.na(hours_factor) & abs(hours_factor - 1) > 1e-8]
  if (length(not_hours) > 0) {
    rlang::warn(
      sprintf(
        paste(
          "The default single-dose intervals (the `single.dose.aucs` option, from 0 to 24 and 0 to Inf) assume hours, but the time unit is %s, so they end at 24 %s.",
          "Give `intervals` or set the `single.dose.aucs` option for this time unit."
        ),
        paste0("'", not_hours, "'", collapse = ", "),
        not_hours[1]
      ),
      class = "pknca_warning_single_dose_aucs_unit"
    )
  }
  invisible(NULL)
}

#' @rdname is_sparse_pk
#' @export
is_sparse_pk.PKNCAdata <- function(object) {
  is_sparse_pk(object$conc)
}

#' Print a PKNCAdata object
#' @param x The object to print
#' @param ... Arguments passed on to [print.PKNCAconc()] and [print.PKNCAdose()]
#' @export
print.PKNCAdata <- function(x, ...) {
  print.PKNCAconc(x$conc, ...)
  if (identical(NA, x$dose)) {
    cat("No dosing information.\n")
  } else {
    print.PKNCAdose(x$dose, ...)
  }
  cat(sprintf("\nWith %d rows of interval specifications.\n",
              nrow(x$intervals)))
  times <- pknca_datetime_times(x)
  if (times$is_datetime) {
    group_cols <-
      pknca_datetime_ref_groups(
        as_PKNCAconc(x), as_PKNCAdose(x),
        has_dose_time = !is.null(times$dose_time)
      )
    cat(sprintf(
      "Times are date-times; pk.nca() makes them relative to the first dose (or first concentration)%s.\n",
      if (length(group_cols) > 0) paste0(" within each ", paste(group_cols, collapse = "+")) else ""
    ))
  } else if (!is.null(x$time_reference)) {
    group_cols <- setdiff(names(x$time_reference), c("time_reference", "time_reference_type"))
    n_first_conc <- sum(x$time_reference$time_reference_type %in% "first_conc")
    cat(sprintf(
      "Times are relative to the first dose%s (date-time input)%s.\n",
      if (length(group_cols) > 0) paste0(" within each ", paste(group_cols, collapse = "+")) else "",
      if (n_first_conc > 0) {
        sprintf(
          "; %d of %d groups have no dose and use the first concentration",
          n_first_conc, nrow(x$time_reference)
        )
      } else {
        ""
      }
    ))
  }
  if (!is.null(x$units)) {
    cat("With units\n")
  }
  # PKNCAdata() stores NA_character_ when no imputation is requested
  if (!is.null(x$impute) && !all(is.na(x$impute))) {
    cat(sprintf("With imputation: %s\n", x$impute))
  }
  if (!is.null(x$group_ref)) {
    group_ref_text <-
      if (is.data.frame(x$group_ref) && !("parameter" %in% names(x$group_ref))) {
        paste(name_value_text(x$group_ref), collapse = "; ")
      } else {
        # Parameter-specific forms print one entry per parameter, dropping the
        # columns that do not apply to it
        params <-
          if (is.data.frame(x$group_ref)) {
            unique(as.character(x$group_ref$parameter))
          } else {
            names(x$group_ref)
          }
        paste(
          vapply(
            X = params,
            FUN = function(p) {
              sprintf(
                "%s: %s",
                p,
                paste(name_value_text(group_ref_for_param(x$group_ref, p)), collapse = "; ")
              )
            },
            FUN.VALUE = ""
          ),
          collapse = "; "
        )
      }
    cat(
      sprintf(
        "With reference profiles for secondary parameters (group_ref): %s\n",
        group_ref_text
      )
    )
  }
  if (length(x$options) == 0) {
    cat("No options are set differently than default.\n")
  } else {
    cat("Options changed from default are:\n")
    print(x$options)
  }
}

#' Summarize a PKNCAdata object showing important details about the
#' concentration, dosing, and interval information.
#' @param object The PKNCAdata object to summarize.
#' @param ... arguments passed on to [print.PKNCAdata()]
#' @export
summary.PKNCAdata <- function(object, ...) {
  print.PKNCAdata(object, summarize=TRUE, ...)
}

#' Get the groups (right hand side after the `|` from a PKNCA
#' object).
#'
#' @rdname getGroups.PKNCAconc
#' @param object The object to extract the data from
#' @param ... Arguments passed to other getGroups functions
#' @returns A data frame with the (selected) group columns.
#' @export
getGroups.PKNCAdata <- function(object, ...) {
  getGroups(as_PKNCAconc(object), ...)
}

#' @describeIn group_vars.PKNCAconc Get group_vars for a PKNCAdata object
#'   from the PKNCAconc object within
#' @exportS3Method dplyr::group_vars
group_vars.PKNCAdata <- function(x) {
  group_vars.PKNCAconc(as_PKNCAconc(x))
}
