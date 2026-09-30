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

# Is there a sample at this time?  `window` is the half-width of the window a
# sample may fall in and still count as being at `target`, which is how an
# off-nominal collection (a predose sample drawn at -0.05 hours, a trough drawn
# at 167.5 instead of 168) is recognized as the boundary sample it is.
time_has_sample <- function(target, time.conc, window = 0) {
  if (length(time.conc) == 0) {
    return(rep(FALSE, length(target)))
  }
  vapply(
    X = target,
    FUN = function(tt) {
      any(time_same(time.conc, tt) | abs(time.conc - tt) <= window)
    },
    FUN.VALUE = TRUE
  )
}

# floor() that does not fall to the integer below when its argument is an
# integer reached by division, where the result may be a hair under it
floor_tolerant <- function(x) {
  floor(x + time_tolerance(x))
}

# Does the whole pattern of doses repeat every `tau`?
#
# This is the criterion for a `tau.choices` entry, and it is a statement about
# the pattern rather than about the spacings, because a regimen may give more
# than one dose per interval:  doses at 0, 10, 24, and 34 hours repeat every 24
# hours although no two doses are 24 hours apart.
#
# Two complete intervals are required.  A single complete interval followed by a
# partial one can be read as a repeat of anything long enough to hold the doses
# seen so far, which is how a stretch of daily doses with one dose off schedule
# used to be reported as repeating over its whole length.
tau_repeats <- function(x, tau) {
  span <- max(x) - min(x)
  n_complete <- floor_tolerant(span / tau)
  if (n_complete < 2) {
    return(FALSE)
  }
  index <- floor_tolerant((x - min(x)) / tau)
  offset <- (x - min(x)) - index * tau
  pattern <- sort_unique_time(offset)
  same_offsets <- function(a, b) {
    length(a) == length(b) && all(time_same(a, b))
  }
  for (i in seq_len(n_complete) - 1) {
    if (!same_offsets(sort_unique_time(offset[index == i]), pattern)) {
      return(FALSE)
    }
  }
  # Dosing stops partway through the last interval, so the doses in it are the
  # start of the pattern rather than all of it
  trailing <- sort_unique_time(offset[index == n_complete])
  if (length(trailing) > 0) {
    limit <- span - n_complete * tau
    expected <- pattern[pattern <= limit + time_tolerance(limit)]
    if (!same_offsets(trailing, expected)) {
      return(FALSE)
    }
  }
  TRUE
}

# Is the smallest spacing the one the regimen is built on?
#
# A missed dose leaves a gap that is a whole number of intervals, and the doses
# either side of it are still one interval apart, so the interval is seen twice
# in a row somewhere in the data.  A regimen giving two doses per interval also
# has spacings that divide one another -- doses at 0, 10, 12, and 22 hours are
# spaced 10, 2, and 10 -- but its short spacing never repeats back to back, and
# the interval it repeats over is not the short spacing.
smallest_spacing_repeats <- function(spacing) {
  if (length(spacing) < 2) {
    return(FALSE)
  }
  at_smallest <- time_same(spacing, min(spacing))
  any(at_smallest[-1] & at_smallest[-length(at_smallest)])
}

# Every positive difference between two doses, as the candidate intervals to
# test when the user has not named any.  An interval longer than half the span
# cannot repeat twice, so it is not a candidate.
all_dose_spacings <- function(x) {
  differences <- as.vector(outer(x, x, FUN = "-"))
  ret <- sort_unique_time(differences[differences > 0])
  ret[ret <= (max(x) - min(x)) / 2 + time_tolerance(max(x))]
}

#' Find the repeating interval within a vector of doses
#'
#' The dose times are sorted and times that repeat are dropped, so the order
#' they arrive in and a dose recorded twice do not change the answer.  The
#' interval is then found from the spacings between consecutive doses:
#' \enumerate{
#'   \item If all values are `NA`, or there are no values, `NA` is returned.
#'   \item If all values are the same, then 0 is returned.
#'   \item If all doses are equally spaced, that spacing is returned.  Two doses
#'         give the spacing between them.
#'   \item If every spacing is a whole number of the smallest spacing and most
#'         of the doses have the smallest spacing, the smallest spacing is
#'         returned with a `"pknca_warning_tau_irregular_dosing"` warning naming
#'         the longer gaps, which are what a missed dose looks like.
#'   \item Otherwise each of `tau.choices` is tested, smallest first, and the
#'         first one the whole pattern of doses repeats over is returned.  The
#'         pattern must repeat over at least two complete intervals, so a
#'         regimen giving more than one dose per interval is found while a
#'         length that merely spans the doses is not.
#'   \item If none of them fits, `NA` is returned.  [resolve_dose_tau()] turns
#'         that into a warning where a dosing interval is required.
#' }
#'
#' @inheritParams PKNCA.choose.option
#' @param x the vector to find the interval within
#' @param na.action What to do with NAs in `x`
#' @param tau.choices the intervals to look for if the doses are not all equally
#'   spaced.  `NA` (the default) tests every spacing between two doses.
#' @returns A scalar indicating the repeating interval, or `NA` when no interval
#'   fits the doses.
#' @family Interval determination
#' @examples
#' # Equally spaced doses give their spacing
#' find.tau(c(0, 24, 48, 72))
#' # Twice-daily dosing repeats daily although no two doses are a day apart
#' find.tau(c(0, 10, 24, 34, 48, 58), tau.choices = c(12, 24))
#' @export
find.tau <- function(x, na.action=stats::na.omit,
                     options=list(),
                     tau.choices=NULL) {
  # Check inputs
  tau.choices <- PKNCA.choose.option(name="tau.choices", value=tau.choices, options=options)
  x <- sort_unique_time(na.action(x))
  if (length(x) == 0) {
    return(NA)
  } else if (length(x) == 1) {
    # Single dose, no more effort needed
    return(0)
  }
  spacing <- diff(x)
  if (all(time_same(spacing, spacing[1]))) {
    # One interval through the full data set
    return(spacing[1])
  }
  smallest <- min(spacing)
  multiples <- spacing / smallest
  if (all(time_same(multiples, round(multiples))) && smallest_spacing_repeats(spacing)) {
    gaps <- x[-length(x)][!time_same(spacing, smallest)]
    rlang::warn(
      sprintf(
        paste(
          "Dosing is not equally spaced; using the most common interval of %s.",
          "Doses appear to be missing after time%s %s."
        ),
        format(smallest, trim=TRUE),
        if (length(gaps) > 1) "s" else "",
        paste(format(gaps, trim=TRUE), collapse=", ")
      ),
      class = "pknca_warning_tau_irregular_dosing"
    )
    return(smallest)
  }
  if (identical(tau.choices, NA)) {
    tau.choices <- all_dose_spacings(x)
  }
  tau.choices <- sort_unique_time(tau.choices[tau.choices > 0])
  for (tau in tau.choices) {
    if (tau_repeats(x, tau)) {
      return(tau)
    }
  }
  NA
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
  route <- tolower(route[!is.na(route)][1])
  if (!identical(route, "intravascular")) {
    return("extravascular")
  }
  bolus <-
    is.null(duration) || length(duration) == 0 ||
    is.na(duration[1]) || isTRUE(duration[1] == 0)
  if (bolus) "iv_bolus" else "iv_infusion"
}

# Is `single.dose.aucs` still the table the package ships with?  A user who set
# it is asking for those intervals, so the builder is not consulted.
single_dose_aucs_is_default <- function(x) {
  isTRUE(all.equal(x, .PKNCA.option.check$single.dose.aucs(default=TRUE)))
}

# An interval specification with the right columns and classes but no rows
empty_interval_specification <- function() {
  check.interval.specification(data.frame(start=0, end=1, auclast=TRUE))[-1, ]
}

# Do the samples carry on to the end of the interval, or do they stop partway
# and leave a washout before the next dose?
#
# Two treatment periods in one group have a dose at the start of each and a
# predose sample before the second, which looks like a dosing interval from its
# boundaries alone.  What tells them apart is the stretch with no samples in it:
# the profile of a dosing interval runs up to the next dose, while a washout
# ends long before it.  Half the interval is the dividing line, which the
# densest routine designs reach exactly (a sample at 12 and the next at 24).
interval_samples_reach_end <- function(time.conc, start, end) {
  inside <- time.conc[time.conc > start & time.conc < end & !time_same(time.conc, end)]
  if (length(inside) == 0) {
    return(FALSE)
  }
  (end - max(inside)) <= (end - start) / 2 + time_tolerance(end)
}

#' Choose intervals to compute AUCs from time and dosing information
#'
#' Intervals are selected by the following metrics:
#' \enumerate{
#'   \item If there are no dose times, no intervals are generated and a
#'         `"pknca_warning_no_dose_times_for_group"` warning is given.
#'   \item If only one dose is administered and any sample follows it, the
#'         interval runs from the dose to infinity with the parameters
#'         [pknca_interval_table()] gives for a single dose.  Setting the
#'         `single.dose.aucs` option to anything other than its default uses
#'         that table instead, offset by the time of the dose.
#'   \item If more than one dose is administered, an interval is generated
#'         between any two consecutive doses that have samples at both dose
#'         times and at least one sample between them.  It is a dosing interval
#'         when the samples run up to the next dose, and a single-dose profile
#'         bounded by the next dose when they stop partway and leave a washout.
#'   \item For the final dose, the dosing interval (\eqn{\tau}) is found with
#'         [find.tau()] and an interval one \eqn{\tau} long is generated when a
#'         sample was taken at its end, with the parameters for a dose at steady
#'         state.
#'   \item If samples continue beyond \eqn{\tau} after the last dose, the
#'         half-life is calculated from the last dose onward.  If the last dose
#'         has samples after it but gets neither of these, its profile is
#'         calculated to infinity as a single dose.
#'  }
#'
#' Times are matched within a tolerance rather than exactly, so a sample drawn
#' off its nominal time still bounds the interval it belongs to.  The window is
#' the `auto.interval.tolerance` option as a fraction of the interval's length.
#'
#' @inheritParams PKNCA.choose.option
#' @param time.conc Time of concentration measurement
#' @param time.dosing Time of dosing
#' @param single.dose.aucs The AUC specification for single dosing.
#' @param route How the drug was given, as one of [pknca_routes()].
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
                                 sparse=FALSE) {
  # Check inputs
  single.dose.aucs <- PKNCA.choose.option(name="single.dose.aucs", value=single.dose.aucs, options=options)
  tolerance_fraction <-
    PKNCA.choose.option(name="auto.interval.tolerance", value=NULL, options=options)
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
    pknca_interval_table(
      start=start, end=end, dosing=dosing, route=route, sparse=sparse, tier="common"
    )
  }
  if (length(time.dosing) == 1) {
    if (single_dose_aucs_is_default(single.dose.aucs)) {
      return(build(start=time.dosing, end=Inf, dosing="single"))
    }
    # The user asked for these intervals; give them, offset by the dose time so
    # that a dose at a time other than zero still has them relative to itself.
    ret <- check.interval.specification(single.dose.aucs)
    ret$start <- ret$start + time.dosing
    ret$end <- ret$end + time.dosing
    return(ret)
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
    if (time_has_sample(start, time.conc, window) &&
        time_has_sample(end, time.conc, window) &&
        has_sample_between) {
      dosing <-
        if (interval_samples_reach_end(time.conc, start, end)) "multiple" else "single"
      pieces <- c(pieces, list(build(start=start, end=end, dosing=dosing)))
    }
  }
  # The last dose:  an interval one tau long when a sample ends it, the
  # half-life when samples carry on past it, and the whole profile when neither
  # applies but samples were taken after it.
  last_dose <- max(time.dosing)
  tau <- find.tau(time.dosing, options=options)
  samples_after_last_dose <-
    any(time.conc > last_dose & !time_same(time.conc, last_dose))
  last_dose_interval <- FALSE
  if (!is.na(tau) && tau > 0) {
    window <- tolerance_fraction * tau
    interval_end <- last_dose + tau
    if (time_has_sample(interval_end, time.conc, window)) {
      pieces <- c(pieces, list(build(start=last_dose, end=interval_end, dosing="steady_state")))
      last_dose_interval <- TRUE
    }
    # A sample within the window of the end of the interval is the sample that
    # ends it, not one beyond it
    if (any(time.conc > interval_end & !time_same(time.conc, interval_end) &
            abs(time.conc - interval_end) > window)) {
      pieces <-
        c(
          pieces,
          list(check.interval.specification(
            data.frame(start=last_dose, end=Inf, half.life=TRUE)
          ))
        )
      last_dose_interval <- TRUE
    }
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
#' @param time.dose The dose times for the whole group (not just the interval;
#'   an interval one `tau` long contains a single dose, so nothing repeats
#'   within it)
#' @returns The dosing interval, or `NA_real_` when it cannot be determined
#' @family Interval determination
#' @keywords Internal
resolve_dose_tau <- function(interval, time.dose, options=list()) {
  tau_manual <- interval[["tau"]]
  if (!is.null(tau_manual) && !is.na(tau_manual[1])) {
    return(assert_dosetau(as.numeric(tau_manual[1])))
  }
  ret <- find.tau(time.dose, options=options)
  # find.tau() gives 0 for a single dose time and NA when no interval repeats.
  # Neither is a dosing interval, and a tau of 0 would silently reduce a
  # multiple-dose parameter to its single-dose equivalent rather than failing.
  if (is.na(ret) || ret <= 0) {
    rlang::warn(
      "Cannot determine tau from the dose times; add a 'tau' column to the intervals to calculate multiple-dose parameters",
      class = "pknca_warning_tau_undetermined"
    )
    return(NA_real_)
  }
  as.numeric(ret)
}
