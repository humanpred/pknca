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

# The cycle of each of the sorted dose times `x` of a regimen that repeats
# every `tau` with doses at `offsets` within the period (from the first dose,
# as find.dose.regimen() reports them).  Each dose is matched to its nearest
# offset, so a dose recorded a little early stays in its own cycle rather than
# falling into the one before it.
dose_cycle_index <- function(x, tau, offsets = 0) {
  since_first <- x - x[1]
  phase <- since_first %% tau
  distance <- abs(outer(phase, offsets, "-"))
  distance <- pmin(distance, tau - distance)
  nearest <- max.col(-distance, ties.method = "first")
  round((since_first - offsets[nearest]) / tau)
}

# The dose that starts the last dosing cycle.
#
# A regimen giving more than one dose per interval ends its record partway
# through a cycle, and the interval to summarize is the whole cycle, not the
# last `tau` of the record:  twice-daily doses ending at 106 hours have their
# last cycle running from 96 to 120 hours, and an interval from 106 to 130
# would contain the unrecorded dose at 120.
last_cycle_start <- function(x, tau, offsets = 0) {
  index <- dose_cycle_index(x, tau, offsets)
  min(x[index == max(index)])
}

# How far the spacing from one cycle to the next may be from the period for the
# cycle to be complete, as a fraction of the period (the `tol` of
# find.dose.regimen())
interval_cycle_tolerance <- 0.2

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
  regimen_tau(find.dose.regimen(x, tau.choices=tau.choices, timeu=timeu, options=options))
}

# The tau of a regimen table from find.dose.regimen():  the period of the
# segment with the most doses, 0 for a single dose, and NA when nothing repeats
regimen_tau <- function(regimen) {
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
#' When [find.dose.regimen()] finds a change of regimen in the dose times (more
#' than one segment) and the design is not sparse, the intervals follow the
#' segments instead:
#' \itemize{
#'   \item One steady-state interval for each segment, when a sample ends it.
#'         An earlier segment's interval is its last complete cycle, from the
#'         cycle's first dose to the recorded dose one period later (the dose
#'         that starts the next segment, unless a dose was missed before it), so
#'         it never contains a later dose.  The last segment's interval is its
#'         last cycle, one period at the segment's own period.  Like the
#'         interval after the last dose, a steady-state interval needs only a
#'         sample at its end, so it may have as few as two samples.
#'   \item The interval after the first dose, as above.
#'   \item The interval after any other dose only when the dose is sampled
#'         densely:  at least `dense.samples` samples (3 by default) strictly
#'         within one period of its segment after the dose.  A sample counts by
#'         its nominal time when it has one (`time.conc.nominal`), from the
#'         dose's nominal time when that is given (`time.dosing.nominal`), so
#'         that a sample drawn a little late counts where it was scheduled; a
#'         sample without a nominal time counts by its actual time.  Samples at
#'         the same time count once, and samples without a concentration
#'         (`conc` is `NA`) do not count; samples below the limit of
#'         quantification do.  Nominal times must share the actual times'
#'         origin (time since the first dose, for example).  When they restart
#'         instead, as times since the latest dose do, the actual times are
#'         used with a `"pknca_warning_intervals_nominal_restart"` warning.
#'   \item The last dose gets the intervals above at the period of the last
#'         segment, even when an earlier segment has more doses.
#' }
#' A `"pknca_warning_intervals_by_segment"` warning names the segments and the
#' intervals chosen.  It is also a `"pknca_warning_tau_regimen_change"` warning,
#' which it replaces.
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
#' @param time.conc.nominal,time.dosing.nominal Nominal times of the samples
#'   and of the doses, on the same scale as `time.conc` and `time.dosing` and
#'   the same length, or `NULL`.  They are used, and checked to be numeric, only
#'   to judge whether a dose is sampled densely after a change of regimen.
#'   [PKNCAdata()] gives the `time.nominal` columns of [PKNCAconc()] and
#'   [PKNCAdose()].
#' @param dense.samples The fewest samples within one dosing period after a
#'   dose that make it sampled densely, which gives it an interval after a
#'   change of regimen
#' @param conc The concentrations at `time.conc`, or `NULL`.  Used only to leave
#'   samples without a concentration out of the dense-sampling count.
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
                                 timeu=NULL,
                                 time.conc.nominal=NULL,
                                 time.dosing.nominal=NULL,
                                 dense.samples=3,
                                 conc=NULL) {
  # Check inputs
  single.dose.aucs <- PKNCA.choose.option(name="single.dose.aucs", value=single.dose.aucs, options=options)
  tolerance_fraction <-
    PKNCA.choose.option(name="auto.interval.tolerance", value=NULL, options=options)
  method <-
    PKNCA.choose.option(name="auto.interval.method", value=NULL, options=options)
  route <- match.arg(route, choices=pknca_routes())
  checkmate::assert_flag(sparse)
  checkmate::assert_count(dense.samples, positive=TRUE)
  if (anyNA(time.conc)) {
    rlang::abort("time.conc may not have any NA values", class = "pknca_error_timeconc_na")
  }

  if (anyNA(time.dosing)) {
    rlang::abort("time.dosing may not have any NA values", class = "pknca_error_timedosing_na")
  }
  # The samples as given, for judging dense sampling after a change of regimen
  samples_given <- list(time=as.numeric(time.conc), nominal=time.conc.nominal, conc=conc)
  time_dosing_given <- as.numeric(time.dosing)
  time.dosing <- interval_dose_times(time_dosing_given)$time
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

  found <- interval_dose_regimen(time.dosing, options=options, timeu=timeu)
  if (!sparse && nrow(found$regimen) > 1) {
    density <-
      interval_density_inputs(
        samples_given=samples_given, time_dosing_given=time_dosing_given,
        time_dosing_nominal=time.dosing.nominal
      )
    return(
      choose_intervals_by_segment(
        time.conc=time.conc, time.dosing=time.dosing, density=density,
        regimen=found$regimen, build=build,
        tolerance_fraction=tolerance_fraction, dense.samples=dense.samples
      )
    )
  }
  if (!is.null(found$change_warning)) {
    rlang::cnd_signal(found$change_warning)
  }
  pieces <- list(ret)
  for (n in seq_len(length(time.dosing) - 1)) {
    pieces <-
      c(pieces, list(interval_between_doses(time.conc, time.dosing, n, build, tolerance_fraction)))
  }
  last_dose <-
    interval_last_dose(
      time.conc=time.conc, time.dosing=time.dosing, cycle_doses=time.dosing,
      tau=regimen_tau(found$regimen),
      offsets=found$regimen$offsets[[regimen_primary(found$regimen)]],
      build=build, tolerance_fraction=tolerance_fraction
    )
  if (last_dose$no_tau) {
    rlang::warn(
      "The dosing interval could not be determined from the dose times, so no interval was generated for one dosing interval after the last dose",
      class = "pknca_warning_no_tau_for_intervals"
    )
  }
  ret <- dplyr::bind_rows(c(pieces, last_dose$pieces))
  if (nrow(ret) == 0) {
    return(ret)
  }
  check.interval.specification(ret)
}

# Sorted, unique dose times (see sort_unique_time()), with the nominal time of
# each when the nominal times are given (NULL otherwise)
interval_dose_times <- function(time, nominal = NULL) {
  dose_order <- order(time)
  sorted <- time[dose_order]
  keep <- c(TRUE, !time_same(sorted[-1], sorted[-length(sorted)]))[seq_along(sorted)]
  list(
    time = sorted[keep],
    nominal = if (is.null(nominal)) NULL else nominal[dose_order][keep]
  )
}

# The regimen of the dose times, holding back its warning that the regimen
# changes:  choose_intervals_by_segment() gives that warning with the
# intervals it chose, and the other paths give it as it is
interval_dose_regimen <- function(time.dosing, options, timeu) {
  held <- new.env(parent = emptyenv())
  held$change <- NULL
  regimen <-
    withCallingHandlers(
      find.dose.regimen(time.dosing, options = options, timeu = timeu),
      pknca_warning_tau_regimen_change = function(cnd) interval_hold_warning(cnd, held)
    )
  list(regimen = regimen, change_warning = held$change)
}

# Keep a warning in `held` and muffle it
interval_hold_warning <- function(cnd, held) {
  held$change <- cnd
  invokeRestart("muffleWarning")
}

# The interval between dose `n` and the next one, when samples bound it at both
# doses and fall between them; an empty list otherwise.  It is a dosing
# interval when the samples run up to the next dose and a single-dose profile
# when they stop partway and leave a washout.
interval_between_doses <- function(time.conc, time.dosing, n, build, tolerance_fraction) {
  start <- time.dosing[n]
  end <- time.dosing[n + 1]
  window <- tolerance_fraction * (end - start)
  has_sample_between <-
    any(
      time.conc > start & time.conc < end &
        !time_same(time.conc, start) & !time_same(time.conc, end)
    )
  if (!(time_has_boundary_sample(start, time.conc, window) &&
        time_has_boundary_sample(end, time.conc, window) &&
        has_sample_between)) {
    return(list())
  }
  dosing <-
    if (interval_samples_reach_end(time.conc, start, end)) "multiple" else "single"
  build(start=start, end=end, dosing=dosing)
}

# The intervals for the last dose:  the whole of the last complete dosing cycle
# of `cycle_doses` when a sample ends it, the half-life when samples carry on
# past it, and the whole profile when neither applies but samples were taken
# after it.  `no_tau` says that samples followed the last dose but no tau was
# found.
interval_last_dose <- function(time.conc, time.dosing, cycle_doses, tau, offsets, build, tolerance_fraction) {
  pieces <- list()
  last_dose <- max(time.dosing)
  samples_after_last_dose <-
    any(time.conc > last_dose & !time_same(time.conc, last_dose))
  last_dose_interval <- FALSE
  no_tau <- FALSE
  if (!is.na(tau) && tau > 0) {
    # No dose follows the last cycle, so it ends one period after it starts
    cycle_start <- last_cycle_start(cycle_doses, tau, offsets)
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
    no_tau <- TRUE
  }
  if (!last_dose_interval && samples_after_last_dose) {
    pieces <- c(pieces, list(build(start=last_dose, end=Inf, dosing="single")))
  }
  list(pieces = pieces, no_tau = no_tau)
}

# Is a dose followed by at least `dense.samples` samples within one `tau`?  The
# nominal sample times are counted when there are any, from the dose's nominal
# time when it has one, so that a sample drawn a little late is still counted
# where it was scheduled; otherwise the actual sample times are counted.
interval_dense_after_dose <- function(dose, dose_nominal, tau, samples, dense.samples) {
  by_nominal <- !is.na(samples$nominal)
  reference <- if (is.null(dose_nominal) || is.na(dose_nominal)) dose else dose_nominal
  since_dose <- ifelse(by_nominal, samples$nominal - reference, samples$time - dose)
  since_dose <- sort_unique_time(since_dose)
  inside <-
    since_dose > 0 & since_dose < tau &
    !time_same(since_dose, 0) & !time_same(since_dose, tau)
  sum(inside) >= dense.samples
}

# Check a nominal time vector given to choose.auc.intervals(), when it is used
interval_check_nominal <- function(nominal, n_expected, name) {
  if (is.null(nominal)) {
    return(invisible(NULL))
  }
  if (!is.numeric(nominal)) {
    rlang::abort(
      sprintf(
        "`%s` (the `time.nominal` column, from PKNCAdata()) must be numeric to judge dense sampling after a change of regimen; it is %s",
        name, class(nominal)[1]
      ),
      class = "pknca_error_intervals_nominal_type"
    )
  }
  if (length(nominal) != n_expected) {
    rlang::abort(
      sprintf(
        "`%s` must have one value for each time (%d), not %d",
        name, n_expected, length(nominal)
      ),
      class = "pknca_error_intervals_nominal_length"
    )
  }
  invisible(NULL)
}

# Do nominal sample times restart, falling back to the start of the schedule
# while the actual times increase, as times since the latest dose do?  This is
# the rule of pknca_nominal_restart_keys() in the missing-samples code, for the
# samples of one group.
interval_nominal_restarts <- function(actual, nominal) {
  keep <- !is.na(actual) & !is.na(nominal)
  actual <- actual[keep]
  nominal <- nominal[keep]
  n_time <- length(nominal)
  if (n_time < 2) {
    return(FALSE)
  }
  # Ties in actual time are ordered by nominal time, so that they never look
  # like a decrease
  nominal <- nominal[order(actual, nominal)]
  positive <- nominal[nominal > 0]
  schedule_start <- if (length(positive) > 0) positive[1] else 0
  any(nominal[-1] < nominal[-n_time] & nominal[-1] <= schedule_start)
}

# Do nominal dose times fail to increase while the actual dose times do?  Each
# dose has its own scheduled time, so a nominal time that repeats or falls (all
# doses at nominal 0, for example) is not on the actual times' scale.
interval_dose_nominal_restarts <- function(actual, nominal) {
  keep <- !is.na(nominal)
  nominal <- nominal[keep]
  n_time <- length(nominal)
  n_time >= 2 && any(nominal[-1] <= nominal[-n_time])
}

# The samples and dose nominal times used to judge dense sampling:  samples with
# a concentration (BLQ included), each counted by its nominal time when it has
# one and by its actual time otherwise.  Nominal times that restart, as times
# since the latest dose do, are not on the actual times' scale, so with a
# warning only the actual times are used.
interval_density_inputs <- function(samples_given, time_dosing_given, time_dosing_nominal) {
  n_sample <- length(samples_given$time)
  interval_check_nominal(samples_given$nominal, n_sample, "time.conc.nominal")
  interval_check_nominal(time_dosing_nominal, length(time_dosing_given), "time.dosing.nominal")
  checkmate::assert_numeric(samples_given$conc, len = n_sample, null.ok = TRUE, .var.name = "conc")
  usable <- if (is.null(samples_given$conc)) rep(TRUE, n_sample) else !is.na(samples_given$conc)
  sample_nominal <-
    if (is.null(samples_given$nominal)) rep(NA_real_, n_sample) else samples_given$nominal
  dose_nominal <- interval_dose_times(time_dosing_given, time_dosing_nominal)$nominal
  doses <- interval_dose_times(time_dosing_given)$time
  if (interval_nominal_restarts(samples_given$time, sample_nominal) ||
      (!is.null(dose_nominal) && interval_dose_nominal_restarts(doses, dose_nominal))) {
    rlang::warn(
      paste(
        "The nominal times restart (fall back to the start of the schedule while the actual times increase), as times since the latest dose do,",
        "so dense sampling is judged from the actual times.  Nominal times must share the actual times' origin."
      ),
      class = c("pknca_warning_intervals_nominal_restart", "pknca_warning_dose_regimen")
    )
    sample_nominal <- rep(NA_real_, n_sample)
    dose_nominal <- NULL
  }
  list(
    samples = data.frame(time = samples_given$time[usable], nominal = sample_nominal[usable]),
    dose_nominal = dose_nominal
  )
}

# The dose times of segment `segment` of a regimen table.  A dose where the
# regimen changes starts the next segment, so it belongs to an earlier segment
# only as the end of its last cycle.
interval_segment_doses <- function(time.dosing, regimen, segment) {
  from <- time.dosing > regimen$start[segment] | time_same(time.dosing, regimen$start[segment])
  if (segment == nrow(regimen)) {
    return(time.dosing[from])
  }
  before <- time.dosing < regimen$end[segment] & !time_same(time.dosing, regimen$end[segment])
  time.dosing[from & before]
}

# The steady-state cycle of a segment that a later segment follows:  the last
# complete cycle of its doses whose next cycle starts with a recorded dose one
# period later (within interval_cycle_tolerance), which for the last cycle is
# the dose that starts the next segment.  It runs from the cycle's first dose to
# that dose, so it never contains a later dose.  NULL when no cycle qualifies;
# a missed dose before the next segment leaves the gap to that segment without
# a steady-state interval, and the cycle before the gap is used.
interval_segment_cycle <- function(segment_doses, boundary, period, offsets) {
  index <- dose_cycle_index(segment_doses, period, offsets)
  following <- c(segment_doses, boundary)
  for (cycle in sort(unique(index), decreasing = TRUE)) {
    in_cycle <- segment_doses[index == cycle]
    if (length(in_cycle) != length(offsets)) {
      next
    }
    cycle_start <- min(in_cycle)
    after <- following[following > max(in_cycle) & !time_same(following, max(in_cycle))]
    next_start <- min(after)
    if (abs(next_start - cycle_start - period) <= interval_cycle_tolerance * period) {
      return(c(start = cycle_start, end = next_start))
    }
  }
  NULL
}

# The segment of a regimen table that the spacing after dose `n` belongs to
interval_segment_of_spacing <- function(time.dosing, regimen, n) {
  after_start <- time.dosing[n] > regimen$start | time_same(time.dosing[n], regimen$start)
  before_end <- time.dosing[n + 1] < regimen$end | time_same(time.dosing[n + 1], regimen$end)
  which(after_start & before_end)[1]
}

# Intervals after a change of regimen:  one steady-state interval for each
# segment of the regimen (the last complete cycle of the segment, at its own
# period), the interval after the first dose, and the interval after any other
# dose that is sampled densely.  The last segment's period sets the intervals
# for the last dose even when an earlier segment has more doses.  A warning
# names the segments and the intervals chosen.
choose_intervals_by_segment <- function(time.conc, time.dosing, density, regimen, build,
                                        tolerance_fraction, dense.samples) {
  n_segment <- nrow(regimen)
  steady_state <- list()
  for (segment in seq_len(n_segment - 1L)) {
    period <- regimen$interval[segment]
    cycle <-
      interval_segment_cycle(
        segment_doses = interval_segment_doses(time.dosing, regimen, segment),
        boundary = regimen$end[segment], period = period,
        offsets = regimen$offsets[[segment]]
      )
    if (!is.null(cycle) &&
        time_has_boundary_sample(cycle[["end"]], time.conc, tolerance_fraction * period)) {
      steady_state <-
        c(steady_state, list(build(start=cycle[["start"]], end=cycle[["end"]], dosing="steady_state")))
    }
  }
  last_dose <-
    interval_last_dose(
      time.conc=time.conc, time.dosing=time.dosing,
      cycle_doses=interval_segment_doses(time.dosing, regimen, n_segment),
      tau=regimen$interval[n_segment], offsets=regimen$offsets[[n_segment]],
      build=build, tolerance_fraction=tolerance_fraction
    )
  chosen <- c(steady_state, last_dose$pieces)
  between <- list()
  for (n in seq_len(length(time.dosing) - 1L)) {
    period <- regimen$interval[interval_segment_of_spacing(time.dosing, regimen, n)]
    if (n > 1 &&
        !interval_dense_after_dose(
          dose=time.dosing[n], dose_nominal=density$dose_nominal[n], tau=period,
          samples=density$samples, dense.samples=dense.samples
        )) {
      next
    }
    between <- c(between, list(interval_between_doses(time.conc, time.dosing, n, build, tolerance_fraction)))
  }
  ret <- dplyr::bind_rows(c(between, chosen))
  if (nrow(ret) == 0) {
    interval_warn_by_segment(regimen, ret)
    return(empty_interval_specification())
  }
  # A dosing interval that is also a segment's steady-state interval is kept
  # once, as the steady-state interval.  Both end at the same recorded dose, so
  # their bounds match exactly.
  ret <- ret[!duplicated(as.data.frame(ret)[, c("start", "end")], fromLast=TRUE), , drop=FALSE]
  ret <- ret[order(ret$start, ret$end), , drop=FALSE]
  rownames(ret) <- NULL
  interval_warn_by_segment(regimen, ret)
  check.interval.specification(ret)
}

# The warning that a change of regimen chose the intervals by segment, naming
# the segments and the intervals.  It is also a regimen-change warning, which
# it replaces.
interval_warn_by_segment <- function(regimen, intervals) {
  chosen <-
    if (nrow(intervals) == 0) {
      "none"
    } else {
      paste(
        paste(format(intervals$start, trim = TRUE), "to", format(intervals$end, trim = TRUE)),
        collapse = "; "
      )
    }
  rlang::warn(
    paste0(
      "The dosing regimen changes within the dose times, so intervals are chosen for each segment of it:\n",
      regimen_table_text(regimen),
      "\nIntervals chosen: ", chosen
    ),
    class = c(
      "pknca_warning_intervals_by_segment", "pknca_warning_tau_regimen_change",
      "pknca_warning_dose_regimen"
    )
  )
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
