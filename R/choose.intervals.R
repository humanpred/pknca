# Comparing times
#
# Times in PK data are arithmetic on nominal values:  a dose every third of a
# day, a sample twenty minutes after it, a nominal hour converted from minutes.
# Two times that the protocol calls the same time can therefore differ in the
# last few bits, so equality is tested within a relative tolerance.  The
# tolerance scales with the magnitude because the spacing of representable
# doubles does; `pmax(1, ...)` keeps it from collapsing to zero near time 0.
time_tolerance <- function(x, y = x) {
  sqrt(.Machine$double.eps) * pmax(1, abs(x), abs(y))
}

# Are these the same time, up to floating-point representation?
time_same <- function(x, y) {
  dplyr::near(x, y, tol = time_tolerance(x, y))
}

# Sort times and drop the ones that repeat, treating times that differ only by
# floating-point representation as one time.
sort_unique_time <- function(x) {
  x <- sort(x)
  if (length(x) < 2) {
    return(x)
  }
  x[c(TRUE, !time_same(x[-1], x[-length(x)]))]
}

# Is there a sample that bounds an interval at this time?
#
# The window only reaches backward.  A sample drawn after the boundary belongs
# to what follows it rather than to the boundary:  a concentration drawn after a
# dose is not the predose concentration, and a sample drawn after the dose that
# ends a dosing interval carries that dose's drug, so neither can stand in for
# the sample at the boundary.  A sample drawn a little early can, which is what
# a predose sample at -0.05 hours and a trough at 167.5 instead of 168 are.
time_has_boundary_sample <- function(boundary, time.conc, window = 0) {
  if (length(time.conc) == 0) {
    return(FALSE)
  }
  any(
    time_same(time.conc, boundary) |
      (time.conc < boundary & (boundary - time.conc) <= window)
  )
}

# floor() that does not fall to the integer below when its argument is an
# integer reached by division, where the result may be a hair under it
floor_tolerant <- function(x) {
  floor(x + time_tolerance(x))
}

# The dose that starts the last complete dosing cycle.
#
# A regimen giving more than one dose per interval ends its record partway
# through a cycle, and the interval to summarize is the whole cycle, not the
# last `tau` of the record:  twice-daily doses ending at 106 hours have their
# last cycle running from 96 to 120 hours, and an interval from 106 to 130
# would contain the unrecorded dose at 120.
last_cycle_start <- function(x, tau) {
  index <- floor_tolerant((x - min(x)) / tau)
  min(x[index == max(index)])
}

#' Find the repeating interval within a vector of doses
#'
#' The regimen is found with [find.dose.regimen()], and the interval is the
#' period of its segment with the most doses (the latest of those when segments
#' tie).  In brief, the dose times are sorted and times that repeat are dropped;
#' equally spaced doses give their spacing; a pattern of more than one dose per
#' interval that repeats over at least two complete intervals gives the interval
#' it repeats over; doses scattered within a tolerance of one spacing give their
#' median spacing; and otherwise runs of the same spacing form the regimen, with
#' the gaps between them read as missed doses (a whole number of intervals) or
#' doses off schedule.  Times are compared on the log scale within `tol` and
#' `snap.tol` of [find.dose.regimen()], so a dose recorded at 23.6 hours is a
#' daily dose.
#'
#' Looking for a repeating pattern before reading anything as a missed dose is
#' what keeps a regimen with a regular gap in it, such as dosing three times a
#' day at 0, 6, and 12 hours, from being reported as a 6 hour interval with a
#' dose missing overnight.
#'
#' The intervals are matched to `tau.choices` when it is given.  When it is `NA`
#' (the default), they are matched to the built-in nominal intervals listed in
#' [find.dose.regimen()], in the unit `timeu`.  **Without a time unit, the times
#' are taken to be hours**, so `find.tau(c(0, 24, 50))` is 24 (once daily)
#' rather than the median spacing of 25; times in another unit should give
#' `timeu`, or they are compared with intervals in hours and an interval that
#' matches none of them gives a `"pknca_warning_tau_not_nominal"` warning.
#' The warnings of [find.dose.regimen()] are given here as well, notably
#' `"pknca_warning_tau_irregular_dosing"` for missed doses or doses off schedule.
#'
#' @inheritParams find.dose.regimen
#' @param x the vector to find the interval within
#' @param na.action What to do with NAs in `x`
#' @returns `NA` when there are no dose times or no interval repeats, 0 for a
#'   single dose time, and otherwise the repeating interval.
#' @family Interval determination
#' @examples
#' # Equally spaced doses give their spacing
#' find.tau(c(0, 24, 48, 72))
#' # Twice-daily dosing repeats daily although no two doses are a day apart
#' find.tau(c(0, 10, 24, 34, 48, 58), tau.choices = c(12, 24))
#' # Dose times as recorded, with the unit known
#' find.tau(c(0, 23.6, 48, 72.4, 96), timeu = "hr")
#' @export
find.tau <- function(x, na.action=stats::na.omit,
                     options=list(),
                     tau.choices=NULL,
                     timeu=NULL) {
  x <- na.action(x)
  # An na.action that keeps NA, such as na.pass, leaves no NA to detect from
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NA)
  }
  regimen <- find.dose.regimen(x, tau.choices=tau.choices, timeu=timeu, options=options)
  primary <- regimen_primary(regimen)
  if (regimen$n_doses[primary] == 1) {
    return(0)
  }
  ret <- regimen$interval[primary]
  if (is.na(ret)) {
    return(NA)
  }
  ret
}

# The time unit of one group's times, for matching its dosing interval to the
# nominal intervals of find.dose.regimen():  the unit given to PKNCAconc() as a
# value; or the one unit in the group's unit column, read from the group's
# columns when the unit column is a grouping column and otherwise from its rows
# (the pooled samples, with sparse PK).  NULL when no unit is given, which
# find.dose.regimen() takes to be hours (as date-times are converted to hours).
# NA when a unit is given but cannot be used:  the group's rows give more than
# one unit, or the unit cannot be converted to hours (a unit may be any label,
# and without the units package only "hr" can be converted).
pknca_group_timeu <- function(o_conc, data_conc = NULL, data_sparse_conc = NULL,
                              group = NULL) {
  timeu <- o_conc$units$timeu
  column <- o_conc$columns$timeu
  if (is.null(timeu) && !is.null(column)) {
    rows <- if (column %in% names(group)) group else if (is.null(data_sparse_conc)) data_conc else data_sparse_conc
    timeu <- unique(as.character(rows[[column]]))
    timeu <- timeu[!is.na(timeu)]
    if (length(timeu) == 0) {
      return(NULL)
    }
  }
  if (is.null(timeu)) {
    return(NULL)
  }
  timeu <- as.vector(timeu)
  if (length(timeu) != 1) {
    return(NA_character_)
  }
  if (!identical(timeu, "hr") && !requireNamespace("units", quietly = TRUE)) {
    return(NA_character_) # nocov
  }
  if (is.na(pknca_hours_factor(timeu))) {
    return(NA_character_)
  }
  timeu
}

# The unit column to carry with each group's concentration data, so that
# pknca_group_timeu() can read it:  none when the unit is a value, and none
# when the column is already carried as a grouping column or a column that the
# calculations use, where carrying it twice would collide.
pknca_timeu_extra_col <- function(o_conc) {
  column <- o_conc$columns$timeu
  carried <-
    c(
      unlist(o_conc$columns$groups), o_conc$columns$subject,
      o_conc$columns$concentration, o_conc$columns$time, o_conc$columns$volume,
      o_conc$columns$duration, o_conc$columns$include_half.life,
      o_conc$columns$exclude_half.life, o_conc$columns$lloq
    )
  if (is.null(column) || column %in% carried) {
    return(character(0))
  }
  as.character(column)
}

# The time unit of each group of a split PKNCAdata object (see
# full_join_PKNCAdata()), as a list with one element per row
pknca_split_timeu <- function(splitdata, group_info, o_conc) {
  ret <- vector("list", nrow(splitdata))
  for (idx in seq_len(nrow(splitdata))) {
    timeu <-
      pknca_group_timeu(
        o_conc = o_conc,
        data_conc = splitdata$data_conc[[idx]],
        data_sparse_conc = splitdata[["data_sparse_conc"]][[idx]],
        group = group_info[idx, , drop = FALSE]
      )
    if (!is.null(timeu)) {
      ret[[idx]] <- timeu
    }
  }
  ret
}

# Gathering the dose regimen warnings of one group (the
# "pknca_warning_dose_regimen" class of find.dose.regimen() and
# resolve_dose_tau()) so that each is given once for the group, with the group
# named, rather than once for every interval and every parameter that needed
# tau.
pknca_regimen_warning_collector <- function() {
  collector <- new.env(parent = emptyenv())
  collector$conditions <- list()
  collector
}

# Evaluate `expr`, keeping its dose regimen warnings in `collector`
pknca_collect_regimen_warnings <- function(expr, collector) {
  withCallingHandlers(
    expr,
    pknca_warning_dose_regimen = function(cnd) pknca_keep_regimen_warning(cnd, collector)
  )
}

# Keep one dose regimen warning (by class and message) and muffle it
pknca_keep_regimen_warning <- function(cnd, collector) {
  key <- paste(class(cnd)[1], conditionMessage(cnd))
  collector$conditions[[key]] <- cnd
  invokeRestart("muffleWarning")
}

# Evaluate `expr` for one group, giving its dose regimen warnings once each,
# prefixed with the group.  They are given on the way out, so an error in
# `expr` does not lose the warnings that came before it.
pknca_with_regimen_warnings <- function(expr, prefix) {
  collector <- pknca_regimen_warning_collector()
  on.exit(pknca_emit_regimen_warnings(collector, prefix), add = TRUE)
  pknca_collect_regimen_warnings(expr, collector)
}

# Give the kept dose regimen warnings, each once, prefixed with the group
pknca_emit_regimen_warnings <- function(collector, prefix) {
  for (cnd in collector$conditions) {
    rlang::warn(
      paste0(prefix, conditionMessage(cnd)),
      class = setdiff(class(cnd), c("rlang_warning", "warning", "condition"))
    )
  }
  invisible(NULL)
}

# The route to build an interval for, from the route and duration recorded with
# the doses.  `PKNCAdose()` records the route as extravascular or intravascular
# and the way the drug entered the vein as a duration, while the parameter
# classification names the two separately (see `pknca_routes()`).  A group
# giving more than one route is described by the route of its first dose.
dose_route_for_intervals <- function(route=NULL, duration=NULL) {
  if (is.null(route) || length(route) == 0 || all(is.na(route))) {
    return("extravascular")
  }
  route <- tolower(route[!is.na(route)])
  if (length(unique(route)) > 1) {
    rlang::warn(
      sprintf(
        "More than one dosing route in a group (%s); the first dose's route (%s) was used to choose the parameters",
        paste(unique(route), collapse=", "), route[1]
      ),
      class = "pknca_warning_multiple_dose_routes"
    )
  }
  route <- route[1]
  if (!identical(route, "intravascular")) {
    return("extravascular")
  }
  bolus <-
    is.null(duration) || length(duration) == 0 ||
    is.na(duration[1]) || isTRUE(duration[1] == 0)
  if (bolus) "iv_bolus" else "iv_infusion"
}

# The parameters PKNCA chose for an automatically generated interval before
# `pknca_interval_table()` was used, reachable through the
# `auto.interval.method` option so that an analysis written against them can
# still be reproduced.  The single-dose case is the `single.dose.aucs` option
# and is handled by the caller, because it describes the whole analysis rather
# than one interval.
legacy_interval_table <- function(start, end) {
  check.interval.specification(
    data.frame(start=start, end=end, auclast=TRUE, cmax=TRUE, tmax=TRUE)
  )
}

# An interval specification with the right columns and classes but no rows
empty_interval_specification <- function() {
  check.interval.specification(data.frame(start=0, end=1, auclast=TRUE))[-1, ]
}

# The share of an interval that may pass with no samples in it before the
# interval is read as a washout rather than as a dosing interval.  A routine
# steady-state profile leaves a long stretch before the trough -- samples at 0,
# 1, 2, 4, 8, and 24 hours leave two thirds of the interval empty -- while two
# treatment periods leave far more:  a two week washout sampled for three days
# leaves nearly four fifths of it.
interval_washout_fraction <- 0.75

# Do the samples carry on to the end of the interval, or do they stop partway
# and leave a washout before the next dose?
#
# Two treatment periods in one group have a dose at the start of each and a
# predose sample before the second, which looks like a dosing interval from its
# boundaries alone.  What tells them apart is the stretch with no samples in it.
# The trough that ends a dosing interval is not counted as filling that stretch,
# because the predose sample of the next period is exactly the sample a washout
# also has.
interval_samples_reach_end <- function(time.conc, start, end) {
  inside <-
    time.conc[
      time.conc > start & time.conc < end &
        !time_same(time.conc, start) & !time_same(time.conc, end)
    ]
  if (length(inside) == 0) {
    return(FALSE)
  }
  (end - max(inside)) <=
    interval_washout_fraction * (end - start) + time_tolerance(end)
}

#' Choose intervals to compute AUCs from time and dosing information
#'
#' Intervals are selected by the following metrics:
#' \enumerate{
#'   \item If there are no dose times, no intervals are generated and a
#'         `"pknca_warning_no_dose_times_for_group"` warning is given.
#'   \item If only one dose is administered and any sample follows it, the
#'         interval runs from the dose to infinity with the parameters
#'         [pknca_interval_table()] gives for a single dose.
#'   \item If more than one dose is administered, an interval is generated
#'         between any two consecutive doses that have samples at both dose
#'         times and at least one sample between them.  It is a dosing interval
#'         when the samples run up to the next dose, and a single-dose profile
#'         bounded by the next dose when they stop partway and leave a washout.
#'   \item For the final dose, the dosing interval (\eqn{\tau}) is found with
#'         [find.tau()].  An interval one \eqn{\tau} long is generated when a
#'         sample was taken at its end, with the parameters for a dose at steady
#'         state.  It starts at the first dose of the last complete cycle, which
#'         is the last dose itself unless the regimen gives more than one dose
#'         per \eqn{\tau}, so that the interval never contains a dose that was
#'         not recorded.
#'   \item If samples continue beyond \eqn{\tau} after the last dose, the
#'         half-life is calculated from the last dose onward.  If the last dose
#'         has samples after it but gets neither of these, its profile is
#'         calculated to infinity as a single dose.
#'  }
#'
#' \eqn{\tau} is matched to the nominal dosing intervals of
#' [find.dose.regimen()] in the time unit `timeu`, taken to be hours when it is
#' not given:  dose times recorded a little early or late give the nominal
#' interval, and an interval that matches none of them, such as dosing every
#' hour, gives a `"pknca_warning_tau_not_nominal"` warning.  With `timeu = NA`
#' (a unit PKNCA cannot use), \eqn{\tau} is found from the dose times alone.
#'
#' Times are matched within a tolerance rather than exactly, so a sample drawn a
#' little before its nominal time still bounds the interval it belongs to.  The
#' window is the `auto.interval.tolerance` option as a fraction of the
#' interval's length, and it only reaches backward:  a sample drawn after a
#' boundary belongs to what follows that boundary, so a concentration drawn
#' after a dose cannot stand in for the predose sample.
#'
#' Setting the `auto.interval.method` option to `"legacy"` calculates the
#' parameter lists PKNCA used before [pknca_interval_table()] was available:
#' the `single.dose.aucs` option for single-dose data, and AUClast, Cmax, and
#' Tmax for each interval of multiple-dose data.  The intervals themselves are
#' found the same way either way.
#'
#' @inheritParams PKNCA.choose.option
#' @param time.conc Time of concentration measurement
#' @param time.dosing Time of dosing
#' @param single.dose.aucs The AUC specification for single dosing.
#' @param route How the drug was given, as one of [pknca_routes()].
#' @param timeu The time unit of `time.conc` and `time.dosing`; `NULL` when it is
#'   not known, which is taken to be hours; or `NA` when it cannot be used (see
#'   [find.dose.regimen()]).  [PKNCAdata()] gives the time unit of its
#'   concentration data.
#' @param sparse Is this a sparse sampling design?  A sparse design imputes
#'   nothing; see [pknca_interval_table()].
#' @returns A data frame with columns for `start`, `end`, and the parameters to
#'   calculate.  See [check.interval.specification()] for column definitions.
#'   The data frame may have zero rows if no intervals could be found.
#' @family Interval specifications
#' @family Interval determination
#' @seealso [pknca_interval_table()], [pk.calc.auc()], [pk.calc.half.life()],
#'   [PKNCA.options()]
#' @examples
#' # A single dose gives one profile to infinity
#' choose.auc.intervals(c(0, 1, 2, 4, 8, 24), 0)[, c("start", "end")]
#'
#' # Daily dosing with a dense profile on the first and last day
#' choose.auc.intervals(
#'   c(0, 1, 2, 4, 8, 12, 24, 48, 72, 96, 120, 144, 145, 146, 148, 152, 156, 168, 192),
#'   seq(0, 144, by = 24)
#' )[, c("start", "end")]
#' @export
choose.auc.intervals <- function(time.conc, time.dosing,
                                 options=list(),
                                 single.dose.aucs=NULL,
                                 route="extravascular",
                                 sparse=FALSE,
                                 timeu=NULL) {
  # Check inputs
  single.dose.aucs <- PKNCA.choose.option(name="single.dose.aucs", value=single.dose.aucs, options=options)
  tolerance_fraction <-
    PKNCA.choose.option(name="auto.interval.tolerance", value=NULL, options=options)
  method <-
    PKNCA.choose.option(name="auto.interval.method", value=NULL, options=options)
  route <- match.arg(route, choices=pknca_routes())
  checkmate::assert_flag(sparse)
  if (anyNA(time.conc)) {
    rlang::abort("time.conc may not have any NA values", class = "pknca_error_timeconc_na")
  }

  if (anyNA(time.dosing)) {
    rlang::abort("time.dosing may not have any NA values", class = "pknca_error_timedosing_na")
  }
  time.dosing <- sort_unique_time(as.numeric(time.dosing))
  time.conc <- sort_unique_time(as.numeric(time.conc))
  ret <- empty_interval_specification()
  if (length(time.dosing) == 0) {
    rlang::warn(
      "No dose times are available, so no intervals can be generated",
      class = "pknca_warning_no_dose_times_for_group"
    )
    return(ret)
  }
  # Every interval needs a sample within it, so a group with no samples after
  # its first dose has nothing to calculate
  if (!any(time.conc > min(time.dosing) & !time_same(time.conc, min(time.dosing)))) {
    return(ret)
  }
  build <- function(start, end, dosing) {
    if (identical(method, "legacy")) {
      return(legacy_interval_table(start=start, end=end))
    }
    pknca_interval_table(
      start=start, end=end, dosing=dosing, route=route, sparse=sparse, tier="common"
    )
  }
  if (length(time.dosing) == 1) {
    if (identical(method, "legacy")) {
      # The single.dose.aucs option describes the whole single-dose analysis,
      # offset by the dose time so that a dose at a time other than zero still
      # has those intervals relative to itself.
      ret <- check.interval.specification(single.dose.aucs)
      ret$start <- ret$start + time.dosing
      ret$end <- ret$end + time.dosing
      return(ret)
    }
    return(build(start=time.dosing, end=Inf, dosing="single"))
  }

  pieces <- list(ret)
  for (n in seq_len(length(time.dosing) - 1)) {
    start <- time.dosing[n]
    end <- time.dosing[n + 1]
    window <- tolerance_fraction * (end - start)
    has_sample_between <-
      any(
        time.conc > start & time.conc < end &
          !time_same(time.conc, start) & !time_same(time.conc, end)
      )
    if (time_has_boundary_sample(start, time.conc, window) &&
        time_has_boundary_sample(end, time.conc, window) &&
        has_sample_between) {
      dosing <-
        if (interval_samples_reach_end(time.conc, start, end)) "multiple" else "single"
      pieces <- c(pieces, list(build(start=start, end=end, dosing=dosing)))
    }
  }
  # The last dose:  the whole of the last complete dosing cycle when a sample
  # ends it, the half-life when samples carry on past it, and the whole profile
  # when neither applies but samples were taken after it.
  last_dose <- max(time.dosing)
  tau <- find.tau(time.dosing, options=options, timeu=timeu)
  samples_after_last_dose <-
    any(time.conc > last_dose & !time_same(time.conc, last_dose))
  last_dose_interval <- FALSE
  if (!is.na(tau) && tau > 0) {
    cycle_start <- last_cycle_start(time.dosing, tau)
    interval_end <- cycle_start + tau
    window <- tolerance_fraction * tau
    if (time_has_boundary_sample(interval_end, time.conc, window)) {
      pieces <-
        c(pieces, list(build(start=cycle_start, end=interval_end, dosing="steady_state")))
      last_dose_interval <- TRUE
    }
    # A sample within the window of the end of the interval is the sample that
    # ends it, not one beyond it
    if (any(time.conc > interval_end & !time_same(time.conc, interval_end) &
            (time.conc - interval_end) > window)) {
      pieces <-
        c(
          pieces,
          list(check.interval.specification(
            data.frame(start=last_dose, end=Inf, half.life=TRUE)
          ))
        )
      last_dose_interval <- TRUE
    }
  } else if (samples_after_last_dose) {
    rlang::warn(
      "The dosing interval could not be determined from the dose times, so no interval was generated for one dosing interval after the last dose",
      class = "pknca_warning_no_tau_for_intervals"
    )
  }
  if (!last_dose_interval && samples_after_last_dose) {
    pieces <- c(pieces, list(build(start=last_dose, end=Inf, dosing="single")))
  }
  ret <- dplyr::bind_rows(pieces)
  if (nrow(ret) == 0) {
    return(ret)
  }
  check.interval.specification(ret)
}

#' Determine the dosing interval (tau) to use for a calculation interval
#'
#' A `tau` column in the interval specification takes precedence over
#' detection so that designs where only the steady-state dose is present in the
#' dosing data (nothing repeats, so nothing can be detected) can still be
#' calculated.  Otherwise `tau` is detected from the group's dose times with
#' [find.tau()], which gives a `"pknca_warning_tau_irregular_dosing"` warning
#' when the doses are spaced as though one was missed.
#'
#' @inheritParams PKNCA.choose.option
#' @param interval One row of an interval definition (see
#'   [check.interval.specification()])
#' @param timeu The time unit of `time.dose` (see [choose.auc.intervals()])
#' @param time.dose The dose times for the whole group (not just the interval;
#'   an interval one `tau` long contains a single dose, so nothing repeats
#'   within it)
#' @returns The dosing interval, or `NA_real_` when it cannot be determined
#' @family Interval determination
#' @keywords Internal
resolve_dose_tau <- function(interval, time.dose, options=list(), timeu=NULL) {
  tau_manual <- interval[["tau"]]
  if (!is.null(tau_manual) && !is.na(tau_manual[1])) {
    return(assert_dosetau(as.numeric(tau_manual[1])))
  }
  ret <- find.tau(time.dose, options=options, timeu=timeu)
  # find.tau() gives 0 for a single dose time and NA when no interval repeats.
  # Neither is a dosing interval, and a tau of 0 would silently reduce a
  # multiple-dose parameter to its single-dose equivalent rather than failing.
  if (is.na(ret) || ret <= 0) {
    rlang::warn(
      "Cannot determine tau from the dose times; add a 'tau' column to the intervals to calculate multiple-dose parameters",
      class = c("pknca_warning_tau_undetermined", "pknca_warning_dose_regimen")
    )
    return(NA_real_)
  }
  as.numeric(ret)
}
