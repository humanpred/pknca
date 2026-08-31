#' Compute NCA parameters for each interval for each subject.
#'
#' The `pk.nca` function computes the NCA parameters from a `PKNCAdata` object.
#' All options for the calculation and input data are set in prior functions
#' (`PKNCAconc`, `PKNCAdose`, and `PKNCAdata`).  Options for calculations are
#' set either in `PKNCAdata` or with the current default options in
#' `PKNCA.options`.
#'
#' When performing calculations, all time results are relative to the start of
#' the interval.  For example, if an interval starts at 168 hours, ends at 192
#' hours, and and the maximum concentration is at 169 hours, `tmax=169-168=1`.
#'
#' Data are selected for each interval by the measurement or dose time: rows
#' with a time at or after the interval `start` and at or before the interval
#' `end` are included (a dose exactly at the interval `end` is not included in
#' the interval).  For duration data (for example, urine collections or
#' intravenous infusions), the time is the start of the collection or
#' administration, and the duration is not considered during selection: a
#' collection that starts within the interval and ends after the interval `end`
#' contributes its full amount to the interval.  For the simplest
#' interpretation of results, align collection start and end times with
#' interval boundaries.
#'
#' @param data A PKNCAdata object
#' @param verbose Indicate, by `message()`, the current state of calculation.
#' @returns A `PKNCAresults` object.
#' @seealso [PKNCAdata()], [PKNCA.options()], [summary.PKNCAresults()],
#'   [as.data.frame.PKNCAresults()], [exclude()]
#' @export
pk.nca <- function(data, verbose=FALSE) {
  assert_PKNCAdata(data)
  results <- data.frame()
  if (nrow(data$intervals) > 0) {
    if (verbose) {
      rlang::inform("Setting up options", class = "pknca_message_setup_options")
    }
    # Merge the options into the default options.
    tmp_options <- PKNCA.options()
    tmp_options[names(data$options)] <- data$options
    data$options <- tmp_options
    # A working copy: reference intervals gain the source parameters their links
    # need.  The PKNCAresults below keeps the user's own `data`, so the
    # expansion never becomes visible in `x$data$intervals`.
    data_calc <- expand_secondary_intervals(data)
    splitdata <- full_join_PKNCAdata(data_calc)
    group_info <-
      splitdata[
        ,
        setdiff(names(splitdata), c("data_conc", "data_sparse_conc", "data_dose", "data_intervals")),
        drop=FALSE
      ]
    # Calculate the results
    if (verbose) {
      rlang::inform("Starting dense PK NCA calculations.", class = "pknca_message_dense_pk_start")
    }
    results_dense <-
      purrr::pmap(
        .l = list(
          data_conc = splitdata$data_conc,
          data_dose = splitdata$data_dose,
          data_intervals = splitdata$data_intervals
        ),
        .f = pk.nca.intervals,
        options = data$options,
        impute = data$impute,
        verbose = verbose,
        sparse = FALSE,
        .progress = data$options$progress
      )
    if (verbose) {
      rlang::inform("Combining completed dense PK calculation results.", class = "pknca_message_dense_pk_combine")
    }
    results <- pk_nca_result_to_df(group_info, results_dense)
    if (is_sparse_pk(data)) {
      if (verbose) {
        rlang::inform("Starting sparse PK NCA calculations.", class = "pknca_message_sparse_pk_start")
      }
      results_sparse <-
        purrr::pmap(
          .l=list(
            data_conc=splitdata$data_sparse_conc,
            data_dose=splitdata$data_dose,
            data_intervals=splitdata$data_intervals
          ),
          .f=pk.nca.intervals,
          options=data$options,
          impute=data$impute,
          verbose=verbose,
          sparse=TRUE
        )
      if (verbose) {
        rlang::inform("Combining completed sparse PK calculation results.", class = "pknca_message_sparse_pk_combine")
      }
      results <-
        dplyr::bind_rows(
          results,
          pk_nca_result_to_df(group_info, results_sparse)
        )
    }
    results <- pk_nca_secondary(results, data_calc)
  }
  PKNCAresults(
    result=results,
    data=data,
    exclude="exclude"
  )
}

#' Convert the grouping info and list of results for each group into a results
#' data.frame
#'
#' @param group_info A data.frame of grouping columns
#' @param result A list of data.frames with the results from NCA parameter
#'   calculations
#' @return A data.frame with group_info and result combined, warnings filtered
#'   out, and results unnested.
#' @keywords Internal
pk_nca_result_to_df <- function(group_info, result) {
  ret <- group_info
  ret$data_result <- result
  # Gather, report, and remove warnings
  mask_warning <- vapply(X=ret$data_result, inherits, what="warning", TRUE)
  ret_warnings <- ret[mask_warning, ]
  if (nrow(ret_warnings) > 0) {
    group_names <- setdiff(names(ret_warnings), "data_result")
    # Tell the user where the warning comes from
    warning_preamble <- name_value_text(ret_warnings[group_names], collapse="; ")
    invisible(lapply(
      X=seq_along(warning_preamble),
      FUN=function(idx) {
        warning_prep <- ret_warnings$data_result[[idx]]
        warning_prep$message <- sprintf("%s: %s", warning_preamble[idx], warning_prep$message)
        rlang::warn(warning_prep$message, class = c("pknca_warning_parameter_calculation", class(warning_prep)))
      }
    ))
  }
  ret_nowarning <- ret[!mask_warning, ]
  # Generate the outputs
  if (nrow(ret_nowarning) == 0) {
    rlang::warn("All results generated warnings or errors; no results generated", class = "pknca_warning_no_results")
    results <- data.frame()
  } else {
    results <- tidyr::unnest(ret_nowarning, cols="data_result")
    rownames(results) <- NULL
  }
  results
}

#' Subset data to the rows used for calculations within an interval
#'
#' Rows are selected by their `time` falling within the interval: `start <=
#' time` and `time <= end` (or `time < end` when `include_end=FALSE`).  For
#' duration data (for example, urine collections or intravenous infusions),
#' `time` is the start of the collection or administration, and the `duration`
#' column is not consulted during selection: a record whose duration starts
#' within the interval and ends after the interval `end` is selected and
#' contributes its full amount to calculations within the interval.  For the
#' simplest interpretation of results, align collection start and end times
#' with interval boundaries.
#'
#' @param data A data.frame with a column named `time` (and, for duration data,
#'   a column named `duration`, which is ignored during selection)
#' @param start,end The beginning and end times of the interval
#' @param include_na Should rows with an `NA` `time` be kept?
#' @param include_end Should a row with `time == end` be kept?
#' @returns The rows of `data` selected for the interval
#' @keywords Internal
filter_interval <- function(data, start, end, include_na=FALSE, include_end=TRUE) {
  mask_na <- include_na & is.na(data$time)
  mask_keep_start <- start <= data$time
  mask_keep_end <-
    if (include_end) {
      data$time <= end
    } else {
      data$time < end
    }
  mask_time <- mask_keep_start & mask_keep_end
  data[mask_na | mask_time, ]
}

#' Determine if there are any sparse or dense calculations requested within an interval
#'
#' @param interval An interval specification
#' @inheritParams PKNCAconc
#' @return A logical value indicating if the interval requests any sparse (if
#'   `sparse=TRUE`) or dense (if `sparse=FALSE`) calculations.
#' @keywords Internal
any_sparse_dense_in_interval <- function(interval, sparse) {
  all_intervals <- get.interval.cols()
  interval_subset <- interval[, names(interval) %in% names(all_intervals)]
  requested <- vapply(X = interval_subset, FUN = isTRUE, FUN.VALUE = TRUE)
  # Extract if the parameters to be calculated (`names(requested[requested])`)
  # are sparse, and compare that to if the request is for sparse or dense
  any(
    vapply(
      X=all_intervals[names(requested[requested])],
      FUN="[[",
      "sparse",
      FUN.VALUE = TRUE
    ) %in% sparse
  )
}

# Re-raise an error from a single interval calculation with the interval named.
#
# PKNCA raises a `pknca_error_*` condition wherever it has diagnosed the problem
# itself, and those messages already say what the user has to change.  A
# `pknca_error_internal_*` condition, or anything unclassed arriving from base R
# or another package, is a case PKNCA did not anticipate, so only those ask for a
# bug report.
interval_calculation_error <- function(e, error_preamble) {
  diagnosed <-
    any(grepl("^pknca_error_", class(e))) &&
    !any(grepl("^pknca_error_internal_", class(e)))
  msg <- sprintf("%s: %s", error_preamble, e$message)
  if (!diagnosed) {
    msg <- paste("Please report a bug.", msg, sep = "\n")
  }
  rlang::abort(msg, class = "pknca_error_interval_calculation", parent = e)
}

# Subset data down to just the times of interest and then pass it
# further to the calculation routines.
#
# This is simply a helper for pk.nca
#' Compute NCA for multiple intervals
#'
#' @param data_conc A data.frame or tibble with standardized column names as
#'   output from `prepare_PKNCAconc()`
#' @param data_dose A data.frame or tibble with standardized column names as
#'   output from `prepare_PKNCAdose()`
#' @param data_intervals A data.frame or tibble with standardized column names
#'   as output from `prepare_PKNCAintervals()`
#' @param impute The column name in `data_intervals` to use for imputation
#' @inheritParams PKNCAdata
#' @inheritParams pk.nca
#' @inheritParams pk.nca.interval
#' @return A data.frame with all NCA results
pk.nca.intervals <- function(data_conc, data_dose, data_intervals, sparse,
                             options, impute, verbose=FALSE) {
  if (is.null(data_conc) || (nrow(data_conc) == 0)) {
    # No concentration data; potentially placebo data
    return(rlang::warning_cnd(class="pknca_warning_no_conc_data", message="No concentration data"))
  } else if (is.null(data_intervals) || (nrow(data_intervals) == 0)) {
    # No intervals; potentially placebo data
    return(rlang::warning_cnd(class="pknca_warning_no_intervals", message="No intervals for data"))
  }
  # Sort the group-level concentration data in time order.  The interval-level
  # data are sorted below (per interval), but the group-level data are passed
  # as-is to parameters that use `conc.group`/`time.group` (e.g. aucint*), and
  # several of those (via interp.extrap.conc()) require time-sorted input.  See
  # https://github.com/humanpred/pknca/issues/568.
  data_conc <- data_conc[order(data_conc$time), , drop=FALSE]
  # Hoist the debug check: options is already the fully-merged options object
  # (merged at the top of pk.nca()), so there is no need to re-query
  # PKNCA.options() from the environment on every iteration.
  use_debug <- !is.null(options$debug)
  ret_list <- list()
  for (i in seq_len(nrow(data_intervals))) {
    current_interval <- data_intervals[i, , drop=FALSE]
    has_calc_sparse_dense <- any_sparse_dense_in_interval(current_interval, sparse=sparse)
    # Choose only times between the start and end.
    conc_data_interval <- filter_interval(data_conc, start=data_intervals$start[i], end=data_intervals$end[i])
    # Sort the data in time order
    conc_data_interval <- conc_data_interval[order(conc_data_interval$time),]
    NA_data_dose_ <- data.frame(dose=NA_real_, time=NA_real_, duration=NA_real_, route=NA_real_)
    if (is.null(data_dose) || identical(data_dose, NA)) {
      data_dose <- dose_data_interval <- NA_data_dose_
    } else {
      # include_end=FALSE so that a dose at the end of an interval is not included
      dose_data_interval <-
        filter_interval(
          data_dose,
          start=data_intervals$start[i],
          end=data_intervals$end[i],
          include_na=TRUE, include_end=FALSE
        )
    }
    if (nrow(dose_data_interval) > 0) {
      dose_data_interval <- dose_data_interval[order(dose_data_interval$time),]
    } else {
      # When all data are filtered out
      dose_data_interval <- NA_data_dose_
    }
    # Setup for detailed error reporting in case it's needed
    error_preamble <-
      paste(
        "Error with interval",
        name_value_text(current_interval[, c("start", "end")])
      )
    if (nrow(conc_data_interval) == 0) {
      rlang::warn(sprintf("%s: No data for interval", error_preamble), class = "pknca_warning_no_data_for_interval")
    } else if (!has_calc_sparse_dense) {
      if (verbose) {
        rlang::inform(
          sprintf(
            "No %s calculations requested for an interval",
            if (sparse) "sparse" else "dense"
          ),
          class = "pknca_message_no_interval_calculations"
        )
      }
    } else {
      impute_method <- get_impute_method(intervals = current_interval, impute = impute)
      # volume and duration are read with `[[` rather than the `$` used for
      # every column around them because they are the only ones that may not be
      # there: PKNCAconc() adds them to the data only when the user gives them.
      # Both accessors give NULL for an absent column, but `$` on a tibble also
      # warns.  NULL is the right answer here -- a parameter that needs either
      # one stops the calculation in full_join_PKNCAdata() long before this.
      args <- list(
        # Interval-level data
        conc=conc_data_interval$conc,
        time=conc_data_interval$time,
        volume=conc_data_interval[["volume"]],
        duration.conc=conc_data_interval[["duration"]],
        dose=dose_data_interval$dose,
        time.dose=dose_data_interval$time,
        duration.dose=dose_data_interval$duration,
        route=dose_data_interval$route,
        impute_method=impute_method,
        # Group-level data
        conc.group=data_conc$conc,
        time.group=data_conc$time,
        volume.group=data_conc[["volume"]],
        duration.conc.group=data_conc[["duration"]],
        dose.group=data_dose$dose,
        time.dose.group=data_dose$time,
        duration.dose.group=data_dose$duration,
        route.group=data_dose$route,
        # Generic data
        sparse=sparse,
        interval=current_interval,
        options=options)
      if ("subject" %in% names(conc_data_interval)) {
        args$subject <- conc_data_interval$subject
      }
      uses_include_hl <- FALSE
      if ("include_half.life" %in% names(conc_data_interval)) {
        args$include_half.life <- conc_data_interval$include_half.life
        uses_include_hl <- !is.null(args$include_half.life) && !all(is.na(args$include_half.life))
      }
      uses_exclude_hl <- FALSE
      if ("exclude_half.life" %in% names(conc_data_interval)) {
        args$exclude_half.life <- conc_data_interval$exclude_half.life
        uses_exclude_hl <- !is.null(args$exclude_half.life) && !all(is.na(args$exclude_half.life))
      }
      if ("lloq" %in% names(conc_data_interval)) {
        args$lloq <- conc_data_interval$lloq
      }
      if (uses_include_hl && uses_exclude_hl) {
        rlang::abort(
          "Cannot both include and exclude half-life points for the same interval",
          class = "pknca_error_include_exclude_halflife"
        )
      }
      # Try the calculation
      if (use_debug) {
        # debugging mode does not need coverage
        calculated_interval <- do.call(pk.nca.interval, args) # nocov
      } else {
        calculated_interval <-
          tryCatch(
            do.call(pk.nca.interval, args),
            error = function(e) interval_calculation_error(e, error_preamble = error_preamble)
          )
      }
      # Add all the new data into the output
      new_ret <-
        cbind(
          # The rep(1, ...) is to fix #381 where attributes on an interval
          # column cause cbind to fail
          current_interval[
            rep(1, nrow(calculated_interval)),
            c("start", "end", options$keep_interval_cols)
          ],
          calculated_interval,
          row.names=NULL
        )
      ret_list[[length(ret_list) + 1L]] <- new_ret
    }
  }
  if (length(ret_list) == 0L) data.frame() else dplyr::bind_rows(ret_list)
}

# Combine exclusion reasons from a calculation's inputs with the exclusion the
# calculation itself set (the "exclude" attribute).  "DO NOT EXCLUDE" on the
# result wins and clears everything.  Documented in
# vignettes/v80-writing-parameter-functions.Rmd.
combine_exclude_reasons <- function(from_inputs, from_result) {
  reasons <- stats::na.omit(c(from_inputs, from_result))
  if (identical(from_result, "DO NOT EXCLUDE")) {
    NA_character_
  } else if (length(reasons) > 0) {
    paste(reasons, collapse = "; ")
  } else {
    NA_character_
  }
}

# How a parameter's calculation function is called: `arglist` maps each of its
# formals to the name of the data source or parameter that supplies the value
# (`...` removed, and the formals that `formalsmap` sets to NULL dropped), and
# `required` names the formals that have no default, so that an argument which
# cannot be found can be told from an optional one.
#
# Both depend only on the registry entry, so they are worked out on first use
# and cached there, the same way `requires_*` is (see set_requires_inputs()).
# Re-registering a parameter replaces its whole entry, cache included.
parameter_arg_spec <- function(param) {
  all_intervals <- get.interval.cols()
  cached <- all_intervals[[param]]$arg_spec
  if (!is.null(cached)) {
    return(cached)
  }
  fun_formals <- formals(get(all_intervals[[param]]$FUN))
  formalsmap <- all_intervals[[param]]$formalsmap
  arg_names <- setdiff(names(fun_formals), "...")
  arglist <- stats::setNames(object = as.list(arg_names), arg_names)
  arglist[names(formalsmap)] <- formalsmap
  # Drop arguments that were set to NULL by the formalsmap
  arglist <- arglist[!vapply(X = arglist, FUN = is.null, FUN.VALUE = TRUE)]
  has_no_default <-
    vapply(
      X = names(arglist),
      FUN = function(x) inherits(fun_formals[[x]], "name"),
      FUN.VALUE = TRUE
    )
  ret <- list(arglist = arglist, required = names(arglist)[has_no_default])
  all_intervals[[param]]$arg_spec <- ret
  assign("interval.cols", all_intervals, envir = .PKNCAEnv)
  ret
}

#' Compute all PK parameters for a single concentration-time data set
#'
#' For one subject/time range, compute all available PK parameters. All the
#' internal options should be set by [PKNCA.options()] prior to running.  The
#' only part that changes with a call to this function is the `conc`entration
#' and `time`.
#'
#' @inheritParams assert_conc_time
#' @inheritParams PKNCA.choose.option
#' @inheritParams PKNCAconc
#' @param conc.group All concentrations measured for the group
#' @param time.group Time of all concentrations measured for the group
#' @param volume,volume.group The volume (or mass) of the concentration
#'   measurement for the current interval or all data for the group (typically
#'   for urine and fecal measurements)
#' @param duration.conc,duration.conc.group The duration of the concentration
#'   measurement for the current interval or all data for the group (typically
#'   for urine and fecal measurements)
#' @param dose,dose.group Dose amount (may be a scalar or vector) for the
#'   current interval or all data for the group
#' @param time.dose Time of the dose for the current interval (must be the same
#'   length as `dose`)
#' @param time.dose.group Time of the dose for all data for the group (must be
#'   the same length as `dose.group`)
#' @param duration.dose The duration of the dose administration for the current
#'   interval (typically zero for extravascular and intravascular bolus and
#'   nonzero for intravascular infusion)
#' @param duration.dose.group The duration of the dose administration for all
#'   data for the group (typically zero for extravascular and intravascular
#'   bolus and nonzero for intravascular infusion)
#' @param route,route.group The route of dosing for the current interval or all
#'   data for the group
#' @param impute_method The method to use for imputation as a character string
#' @param interval One row of an interval definition (see
#'   [check.interval.specification()] for how to define the interval.
#' @param lloq An optional scalar or vector (the same length as `conc`) with the
#'   lower limit of quantification passed to [pk.calc.half.life()] for the Tobit
#'   half-life method.
#' @param subject Subject identifiers (used for sparse calculations)
#' @param sparse Should only sparse calculations be performed (TRUE) or only
#'   dense calculations (FALSE)?
#' @returns A data frame with the start and end time along with all PK
#'   parameters for the `interval`
#'
#' @seealso [check.interval.specification()]
#' @export
#' @importFrom stats na.omit
pk.nca.interval <- function(conc, time, volume, duration.conc,
                            dose, time.dose, duration.dose, route,
                            conc.group=NULL, time.group=NULL, volume.group=NULL, duration.conc.group=NULL,
                            dose.group=NULL, time.dose.group=NULL, duration.dose.group=NULL, route.group=NULL,
                            impute_method=NA_character_,
                            include_half.life=NULL, exclude_half.life=NULL, lloq=NULL,
                            subject, sparse, interval, options=list()) {
  if (!checkmate::test_data_frame(interval, nrows = 1)) {
    rlang::abort(
      "Please report a bug.  Interval must be a one-row data.frame",
      class = "pknca_error_internal_interval_not_one_row_df"
    )
  }

  if (!all(is.na(impute_method))) {
    impute_funs <- PKNCA_impute_fun_list(impute_method)
    stopifnot(length(impute_funs) == 1)
    impute_data <- data.frame(conc=conc, time=time)
    for (current_fun_nm in impute_funs[[1]]) {
      impute_args <- as.list(impute_data)
      impute_args$start <- interval$start[1]
      impute_args$end <- interval$end[1]
      impute_args$conc.group <- conc.group
      impute_args$time.group <- time.group
      impute_args$options <- options
      impute_data <- do.call(current_fun_nm, args=impute_args)
    }
    conc <- impute_data$conc
    time <- impute_data$time
    tmp_imp_method <- paste0("Imputation: ", paste(na.omit(impute_method), collapse = ", "))
  } else {
    tmp_imp_method <- character()
  }
  # Results accumulate as parallel vectors, one element per result row, and
  # become the returned data.frame (with SDTM names) at the end.  The argument
  # resolution below reads them for the parameters already calculated in this
  # interval, so they grow in calculation order.
  result_testcd <- NULL
  result_value <- NULL
  result_method <- NULL
  result_exclude <- NULL
  # Determine exactly what needs to be calculated in what order. Start with the
  # interval specification and find any dependencies that are not listed for
  # calculation.  Then loop over the calculations in order confirming what needs
  # to be passed from a previous calculation to a later calculation.
  all_intervals <- get.interval.cols()
  # Set the dose to NA if its length is zero
  if (length(dose) == 0) {
    rlang::abort("Please report a bug. Length of dose should not be zero.", class = "pknca_error_internal_dose_length_zero")  # nocov
  }
  # What the interval requests, as a logical vector over the parameters (start
  # and end are times, not requests).  The expansion below and the calculation
  # loop after it read it instead of the interval's columns, and an interval
  # typically requests a handful of the few hundred registered parameters.
  param_names <- setdiff(names(all_intervals), c("start", "end"))
  requested <- vapply(X = interval[param_names], FUN = as.logical, FUN.VALUE = TRUE)
  # Make sure that we calculate all of the dependencies.  Do this in
  # reverse order for dependencies of dependencies.
  for (n in rev(param_names)) {
    if (requested[[n]]) {
      depends <- all_intervals[[n]]$depends
      requested[depends] <- TRUE
      interval[depends] <- TRUE
    }
  }
  # Parameters linked to a reference interval are calculated across intervals by
  # pk_nca_secondary() after every interval has been calculated.  Their
  # dependencies are still expanded above, because the requesting interval's own half of the
  # calculation (`ae`, `totdose`, ...) is computed here.
  deferred <- interval_deferred_params(interval)
  # Do the calculations
  for (n in setdiff(names(requested)[requested], deferred)) {
    has_calculation_function <- !is.na(all_intervals[[n]]$FUN)
    is_correct_sparse_dense <- all_intervals[[n]]$sparse == sparse
    if (has_calculation_function && is_correct_sparse_dense) {
      call_args <- list()
      exclude_from_argument <- character(0)
      # Prepare to call the function by setting up its arguments.
      arg_spec <- parameter_arg_spec(n)
      arglist <- arg_spec$arglist
      for (arg_formal in names(arglist)) {
        arg_mapped <- arglist[[arg_formal]]
        if (is_pknca_ref(arg_mapped)) {
          # A secondary parameter reaching here was requested without a
          # reference pointer, so only the historical same-interval sources can
          # supply the value.
          info <- secondary_param_info(n)
          target <- arg_mapped$param
          if (!is.null(interval[[arg_formal]])) {
            # Historical escape hatch: a value column named by the formal (e.g.
            # `dose1` for f), passed through via keep_interval_cols
            call_args[[arg_formal]] <- interval[[arg_formal]]
          } else if (!(target %in% info$own_args) &&
                     any(mask_arg <- result_testcd %in% target)) {
            # Historical same-interval behavior (e.g. clr with auclast requested
            # in the same interval).  Disallowed when the target is also an own
            # argument, because test and reference would then be the same value
            # and the result degenerate (f would always be 1).
            call_args[[arg_formal]] <- result_value[mask_arg]
            exclude_from_argument <- c(exclude_from_argument, result_exclude[mask_arg])
          } else {
            rlang::abort(
              sprintf(
                "The secondary parameter '%s' needs a reference interval for its '%s' argument (the value of '%s' from another interval). Set the '%s_ref' column in the interval specification to the 'interval_id' of the reference interval, give `group_ref` to PKNCAdata(), or use interval_add_secondary().",
                n, arg_formal, target, n
              ),
              class = "pknca_error_secondary_needs_ref"
            )
          }
        } else if (inherits(arg_mapped, "AsIs")) {
          # An I()-wrapped formalsmap value is the argument itself rather than
          # the name of a data source or another parameter.
          call_args[[arg_formal]] <- unclass(arg_mapped)
        } else if (arg_mapped == "conc") {
          call_args[[arg_formal]] <- conc
        } else if (arg_mapped == "time") {
          # Realign the time to be relative to the start of the
          # interval
          call_args[[arg_formal]] <- time - interval$start[1]
        } else if (arg_mapped == "volume") {
          call_args[[arg_formal]] <- volume
        } else if (arg_mapped == "duration.conc") {
          call_args[[arg_formal]] <- duration.conc
        } else if (arg_mapped == "dose") {
          call_args[[arg_formal]] <- dose
        } else if (arg_mapped == "time.dose") {
          # Realign the time to be relative to the start of the
          # interval
          call_args[[arg_formal]] <- time.dose - interval$start[1]
        } else if (arg_mapped == "duration.dose") {
          call_args[[arg_formal]] <- duration.dose
        } else if (arg_mapped == "route") {
          call_args[[arg_formal]] <- route
        } else if (arg_mapped == "conc.group") {
          call_args[[arg_formal]] <- conc.group
        } else if (arg_mapped == "time.group") {
          # Don't realign the time to be relative to the start of the
          # interval
          call_args[[arg_formal]] <- time.group
        } else if (arg_mapped == "volume.group") {
          call_args[[arg_formal]] <- volume.group
        } else if (arg_mapped == "duration.conc.group") {
          call_args[[arg_formal]] <- duration.conc.group
        } else if (arg_mapped == "dose.group") {
          call_args[[arg_formal]] <- dose.group
        } else if (arg_mapped == "time.dose.group") {
          # Realign the time to be relative to the start of the
          # interval
          call_args[[arg_formal]] <- time.dose.group
        } else if (arg_mapped == "duration.dose.group") {
          call_args[[arg_formal]] <- duration.dose.group
        } else if (arg_mapped == "route.group") {
          call_args[[arg_formal]] <- route.group
        } else if (arg_mapped == "subject") {
          call_args[[arg_formal]] <- subject
        } else if (arg_mapped == "lloq") {
          call_args[[arg_formal]] <- lloq
        } else if (arg_mapped == "tau") {
          call_args[[arg_formal]] <-
            resolve_dose_tau(
              interval=interval,
              time.dose=time.dose.group,
              options=options
            )
        } else if (arg_mapped %in% c("start", "end")) {
          # Provide the start and end of the interval if they are requested
          call_args[[arg_formal]] <- interval[[arg_mapped]]
        } else if (arg_mapped == "options") {
          call_args[[arg_formal]] <- options
        } else if (any(mask_arg <- result_testcd %in% arg_mapped)) {
          call_args[[arg_formal]] <- result_value[mask_arg]
          exclude_from_argument <-
            c(exclude_from_argument, result_exclude[mask_arg])
        } else if (!is.null(interval[[arg_mapped]])) {
          call_args[[arg_formal]] <- interval[[arg_mapped]]
        } else {
          # Give an error if there is not a default argument.
          if (arg_formal %in% arg_spec$required) {
            arg_text <-
              if (arg_formal == arg_mapped) {
                sprintf("'%s'", arg_formal)
              } else {
                # Every formalsmap name resolves to a source input or to a
                # parameter calculated first, so reaching here means the
                # add.interval.col() registration is wrong, not the interval
                sprintf("'%s' mapped to '%s'", arg_formal, arg_mapped)  # nocov
              }
            # The interval specification is the last place an argument is looked
            # for, so that is where the user has to supply it.
            rlang::abort(
              sprintf(
                "Cannot find argument %s for NCA parameter '%s' (calculated by '%s'); give it as a column in the interval specification",
                arg_text, n, all_intervals[[n]]$FUN
              ),
              class = "pknca_error_missing_nca_argument"
            )
          }
        }
      }
      # Apply manual inclusion and exclusion
      if (n %in% "half.life") {
        uses_include_hl <- !is.null(include_half.life) && !all(is.na(include_half.life))
        uses_exclude_hl <- !is.null(exclude_half.life) && !all(is.na(exclude_half.life))
        # Keep a per-observation lloq aligned with conc when points are manually
        # included or excluded (a scalar lloq is broadcast by pk.calc.half.life).
        lloq_is_vector <-
          !is.null(call_args$lloq) && length(call_args$lloq) == length(call_args$conc)
        if (uses_include_hl) {
          include_tf <- include_half.life %in% TRUE
          call_args$conc <- call_args$conc[include_tf]
          call_args$time <- call_args$time[include_tf]
          if (lloq_is_vector) call_args$lloq <- call_args$lloq[include_tf]
          call_args$manually.selected.points <- TRUE
        } else if (uses_exclude_hl) {
          exclude_tf <- exclude_half.life %in% TRUE
          call_args$conc <- call_args$conc[!exclude_tf]
          call_args$time <- call_args$time[!exclude_tf]
          if (lloq_is_vector) call_args$lloq <- call_args$lloq[!exclude_tf]
        }
      }
      # Do the calculation
      tmp_result <- do.call(all_intervals[[n]]$FUN, call_args)
      # The handling of the exclude column is documented in the
      # "vignettes/v80-writing-parameter-functions.Rmd" vignette.  Document any
      # changes to this section of code there.
      exclude_reason <-
        combine_exclude_reasons(exclude_from_argument, attr(tmp_result, "exclude"))
      # The handling of the method column (PPANMETH)
      tmp_method <- c(tmp_imp_method, attr(tmp_result, "method"))
      attr(tmp_result, "method") <- NULL

      # If the function returns a data frame, save all the returned values,
      # otherwise, save the value returned.
      if (is.data.frame(tmp_result)) {
        tmp_testcd <- names(tmp_result)
        tmp_result <- unlist(tmp_result, use.names=FALSE, recursive=FALSE)
      } else {
        tmp_testcd <- n
      }
      # A calculation function returning a data.frame gives one result row per
      # column of it.  The method and the exclusion belong to the calculation,
      # so they apply to every row it produced.
      n_result <- max(length(tmp_testcd), length(tmp_result))
      result_testcd <- c(result_testcd, rep_len(tmp_testcd, n_result))
      result_value <- c(result_value, rep_len(tmp_result, n_result))
      result_method <- c(result_method, rep(paste(tmp_method, collapse=". "), n_result))
      result_exclude <- c(result_exclude, rep(exclude_reason, n_result))
    }
  }
  if (length(result_testcd) == 0) {
    # Nothing was calculated for this interval
    data.frame(PPTESTCD=NA, PPORRES=NA)[-1,]
  } else {
    data.frame(
      PPTESTCD=result_testcd,
      PPORRES=result_value,
      PPANMETH=result_method,
      exclude=result_exclude
    )
  }
}
