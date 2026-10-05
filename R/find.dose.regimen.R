# Nominal dosing intervals in hours, named the way protocols name them
dose_interval_nominal_hours <- function() {
  c(
    q4h = 4, QID = 6, TID = 8, BID = 12, QD = 24, QOD = 48, Q72H = 72,
    QW = 168, Q2W = 336, Q3W = 504, Q4W = 672, Q6W = 1008, Q8W = 1344,
    Q12W = 2016
  )
}

# The nominal intervals that detected intervals are matched to, in the time
# unit of the dose times.  `tau.choices` is the set when it is given.  Otherwise
# the built-in set applies when the time unit is known, converted from hours;
# with no unit, or one that cannot be converted, there is nothing to match, and
# the intervals come from the data.
regimen_candidates <- function(tau.choices, timeu) {
  if (!identical(tau.choices, NA)) {
    ret <- sort(tau.choices[tau.choices > 0])
    return(ret[c(TRUE, !time_same(ret[-1], ret[-length(ret)]))[seq_along(ret)]])
  }
  if (is.null(timeu)) {
    return(numeric(0))
  }
  hours <- pknca_hours_factor(timeu)
  if (is.na(hours)) {
    return(numeric(0))
  }
  dose_interval_nominal_hours() / hours
}

# The index of the nearest candidate on the log scale for each `x`, or NA when
# none is within `log_tolerance`
regimen_nearest <- function(x, candidates, log_tolerance) {
  if (length(candidates) == 0) {
    return(rep(NA_integer_, length(x)))
  }
  distance <- abs(outer(log(x), log(candidates), "-"))
  best <- max.col(-distance, ties.method = "first")
  ifelse(distance[cbind(seq_along(x), best)] <= log_tolerance, best, NA_integer_)
}

# The interval, label, and source of a regimen repeating every `period` with
# `n_per_period` doses in each period.  The period is snapped to a candidate
# when one is near; the label names the evenly spaced regimen with that many
# doses per period, so twice-daily doses at 0 and 10 hours are "BID" with a 24
# hour period.
regimen_describe <- function(period, n_per_period, candidates, log_snap) {
  match_period <- regimen_nearest(period, candidates, log_snap)
  match_each <- regimen_nearest(period / n_per_period, candidates, log_snap)
  label <- NA_character_
  if (!is.na(match_each) && !is.null(names(candidates)) &&
      nzchar(names(candidates)[match_each])) {
    label <- names(candidates)[match_each]
  }
  if (is.na(match_period)) {
    list(interval = period, label = label, source = "auto")
  } else {
    list(interval = unname(candidates[match_period]), label = label, source = "nominal")
  }
}

# One row of the regimen table
regimen_row <- function(segment, start, end, n_doses, description, offsets,
                        n_intervals_used, n_missed, n_irregular, note) {
  data.frame(
    segment = segment, start = start, end = end, n_doses = n_doses,
    interval = description$interval, label = description$label,
    source = description$source, n_intervals_used = n_intervals_used,
    n_missed = n_missed, n_irregular = n_irregular, note = note,
    offsets = I(list(offsets))
  )
}

# A row with no repeating interval
regimen_row_undetermined <- function(t, note) {
  regimen_row(
    segment = 1L, start = min(t), end = max(t), n_doses = length(t),
    description = list(interval = NA_real_, label = NA_character_, source = NA_character_),
    offsets = 0, n_intervals_used = 0L, n_missed = 0L,
    n_irregular = max(0L, length(t) - 1L), note = note
  )
}

# Does every dose recur `k` doses later, with the spacing at each position in
# the cycle the same from cycle to cycle?
#
# Two complete cycles are required so that the pattern is seen to repeat.  The
# spacings at the positions in the cycle must differ from one another by more
# than `log_tolerance`; otherwise the doses are evenly spaced with some scatter,
# and adding spacings together would hide the scatter rather than find a cycle.
regimen_cycle_fits <- function(t, k, log_tolerance, log_snap) {
  n <- length(t)
  if (n < 2 * k + 1) {
    return(FALSE)
  }
  span <- t[(1 + k):n] - t[seq_len(n - k)]
  if (any(abs(log(span / stats::median(span))) > log_snap)) {
    return(FALSE)
  }
  spacing <- diff(t)
  position <- (seq_along(spacing) - 1L) %% k
  position_median <- vapply(split(spacing, position), stats::median, numeric(1))
  all(abs(log(spacing / position_median[position + 1L])) <= log_tolerance) &&
    log(max(position_median) / min(position_median)) > log_tolerance
}

# Dose times within one period, relative to the first dose of each cycle and
# averaged over the complete cycles
regimen_cycle_offsets <- function(t, k) {
  n_cycles <- length(t) %/% k
  cycle <- matrix(t[seq_len(n_cycles * k)], nrow = k)
  rowMeans(cycle - rep(cycle[1, ], each = k))
}

# A whole history that repeats every k > 1 doses.  The smallest such k is the
# regimen; when its period is not a candidate and a whole number of periods is,
# the shortest such multiple is used instead, which is how a `tau.choices` of 48
# selects two days of twice-daily doses.
regimen_find_cycle <- function(t, candidates, log_tolerance, log_snap) {
  k_max <- (length(t) - 1L) %/% 2L
  if (k_max < 2) {
    return(NULL)
  }
  k_found <- NA_integer_
  for (k in seq(2L, k_max)) {
    if (regimen_cycle_fits(t, k, log_tolerance, log_snap)) {
      k_found <- k
      break
    }
  }
  if (is.na(k_found)) {
    return(NULL)
  }
  n <- length(t)
  k_use <- k_found
  period <- stats::median(t[(1 + k_found):n] - t[seq_len(n - k_found)])
  if (length(candidates) > 0 && is.na(regimen_nearest(period, candidates, log_snap))) {
    for (k in k_found * seq_len(k_max %/% k_found)[-1]) {
      period_k <- stats::median(t[(1 + k):n] - t[seq_len(n - k)])
      if (!is.na(regimen_nearest(period_k, candidates, log_snap)) &&
          regimen_cycle_fits(t, k, log_tolerance, log_snap)) {
        k_use <- k
        period <- period_k
        break
      }
    }
  }
  regimen_row(
    segment = 1L, start = t[1], end = t[n], n_doses = n,
    description = regimen_describe(period, k_use, candidates, log_snap),
    offsets = regimen_cycle_offsets(t, k_use),
    n_intervals_used = n - 1L, n_missed = 0L, n_irregular = 0L, note = ""
  )
}

# Label each spacing with the candidate it is near, or with a cluster of
# spacings near one another on the log scale.  A gap wider than
# `log_tolerance` between sorted spacings starts a new cluster.
regimen_label_spacing <- function(spacing, candidates, log_tolerance) {
  nominal <- regimen_nearest(spacing, candidates, log_tolerance)
  label <- ifelse(is.na(nominal), NA_character_, paste0("nominal", nominal))
  other <- which(is.na(nominal))
  if (length(other) > 0) {
    ordered <- other[order(spacing[other])]
    cluster <- cumsum(c(TRUE, diff(log(spacing[ordered])) > log_tolerance))
    label[ordered] <- paste0("cluster", cluster)
  }
  label
}

# Regimen segments from runs of same-labeled spacings.
#
# A run of at least `min.run` spacings anchors a segment, and the runs must hold
# most of the spacings, or there is no regimen to report.  A shorter run joins
# the anchor before it (or after it, at the start) as a missed dose when it is
# a whole number of the segment's interval and as an irregular spacing when it
# is not.  Anchors with the same label next to one another are one segment.
regimen_segments <- function(t, candidates, log_tolerance, log_snap, min.run, max.missed) {
  spacing <- diff(t)
  n <- length(spacing)
  runs <- rle(regimen_label_spacing(spacing, candidates, log_tolerance))
  anchor <- runs$lengths >= min(min.run, n)
  if (!any(anchor) || sum(runs$lengths[anchor]) <= n / 2) {
    return(NULL)
  }
  run_of <- rep(seq_along(runs$lengths), runs$lengths)
  anchor_index <- which(anchor)
  previous_anchor <- findInterval(seq_along(runs$lengths), anchor_index)
  assigned_run <-
    ifelse(previous_anchor == 0, anchor_index[1], anchor_index[pmax(previous_anchor, 1L)])
  assigned <- assigned_run[run_of]
  anchor_label <- runs$values[assigned]
  segment <- cumsum(c(TRUE, anchor_label[-1] != anchor_label[-n]))
  rows <- list()
  missed_after <- numeric(0)
  irregular_after <- numeric(0)
  for (current in unique(segment)) {
    within <- which(segment == current)
    member <- within[run_of[within] == assigned[within]]
    base <- stats::median(spacing[member])
    other <- setdiff(within, member)
    multiple <- round(spacing[other] / base)
    missed <-
      multiple >= 2 & multiple <= max.missed &
      abs(log(spacing[other] / (multiple * base))) <= log_tolerance
    missed_after <- c(missed_after, t[other[missed]])
    irregular_after <- c(irregular_after, t[other[!missed]])
    note <- character(0)
    if (any(missed)) {
      note <- c(note, paste("missed doses after", paste(t[other[missed]], collapse = ", ")))
    }
    if (any(!missed)) {
      note <- c(note, paste("off schedule after", paste(t[other[!missed]], collapse = ", ")))
    }
    row <-
      regimen_row(
        segment = current, start = t[min(within)], end = t[max(within) + 1L],
        n_doses = length(within) + 1L,
        description = regimen_describe(base, 1L, candidates, log_snap),
        offsets = 0, n_intervals_used = length(member),
        n_missed = sum(missed), n_irregular = sum(!missed),
        note = paste(note, collapse = "; ")
      )
    # A segment with nothing missed or off schedule may itself repeat over more
    # than one dose, as twice-daily doses at breakfast and dinner do
    if (length(other) == 0) {
      cycle <- regimen_find_cycle(t[c(within, max(within) + 1L)], candidates, log_tolerance, log_snap)
      if (!is.null(cycle)) {
        row[, c("interval", "label", "source", "offsets")] <-
          cycle[, c("interval", "label", "source", "offsets")]
      }
    }
    rows[[length(rows) + 1L]] <- row
  }
  table <- do.call(rbind, rows)
  if (nrow(table) > 1) {
    table$note <- ifelse(nzchar(table$note), paste0("regimen change; ", table$note), "regimen change")
  }
  list(table = table, missed_after = missed_after, irregular_after = irregular_after)
}

# A cycle of k = 2 to 4 doses that most, but not all, of the history follows,
# such as twice-daily doses at 08:00 and 16:00 with one dose missed.  The k
# with the largest share of doses recurring one period later is used, the
# smallest k among ties, and it must hold at least `min_share` of them.
regimen_partial_cycle <- function(t, candidates, log_snap, min_share = 0.7) {
  n <- length(t)
  best <- NULL
  for (k in seq_len(min(4L, (n - 1L) %/% 2L))[-1]) {
    span <- t[(1 + k):n] - t[seq_len(n - k)]
    ok <- abs(log(span / stats::median(span))) <= log_snap
    if (mean(ok) >= min_share && (is.null(best) || mean(ok) > mean(best$ok))) {
      best <- list(k = k, span = span, ok = ok)
    }
  }
  if (is.null(best)) {
    return(NULL)
  }
  irregular_after <- t[which(!best$ok)]
  row <-
    regimen_row(
      segment = 1L, start = t[1], end = t[n], n_doses = n,
      description = regimen_describe(stats::median(best$span[best$ok]), best$k, candidates, log_snap),
      offsets = t[seq_len(best$k)] - t[1],
      n_intervals_used = sum(best$ok), n_missed = 0L, n_irregular = sum(!best$ok),
      note = paste("off schedule after", paste(irregular_after, collapse = ", "))
    )
  list(table = row, missed_after = numeric(0), irregular_after = irregular_after)
}

# The regimen table for sorted, unique dose times, with the times that precede
# a missed dose or an irregular spacing
regimen_detect <- function(t, candidates, tol, snap.tol, min.run, max.missed) {
  none <- list(missed_after = numeric(0), irregular_after = numeric(0))
  if (length(t) == 1) {
    return(c(list(table = regimen_row_undetermined(t, note = "single dose")), none))
  }
  log_tolerance <- log1p(tol)
  log_snap <- log1p(snap.tol)
  spacing <- diff(t)
  if (all(time_same(spacing, spacing[1]))) {
    period <- spacing[1]
  } else {
    cycle <- regimen_find_cycle(t, candidates, log_tolerance, log_snap)
    if (!is.null(cycle)) {
      return(c(list(table = cycle), none))
    }
    period <- NA_real_
    if (all(abs(log(spacing / stats::median(spacing))) <= log_tolerance)) {
      period <- stats::median(spacing)
    }
  }
  if (!is.na(period)) {
    row <-
      regimen_row(
        segment = 1L, start = t[1], end = t[length(t)], n_doses = length(t),
        description = regimen_describe(period, 1L, candidates, log_snap),
        offsets = 0, n_intervals_used = length(spacing), n_missed = 0L,
        n_irregular = 0L, note = ""
      )
    return(c(list(table = row), none))
  }
  segments <- regimen_segments(t, candidates, log_tolerance, log_snap, min.run, max.missed)
  if (!is.null(segments)) {
    return(segments)
  }
  partial <- regimen_partial_cycle(t, candidates, log_snap)
  if (!is.null(partial)) {
    return(partial)
  }
  c(list(table = regimen_row_undetermined(t, note = "no repeating interval")), none)
}

# The regimen table as text for a condition message
regimen_table_text <- function(table) {
  table$offsets <- vapply(table$offsets, paste, character(1), collapse = ", ")
  paste(utils::capture.output(print(table, row.names = FALSE)), collapse = "\n")
}

# The row of the regimen table that describes the subject:  the segment with
# the most doses, and the latest of those when segments tie
regimen_primary <- function(table) {
  max(which(table$n_doses == max(table$n_doses)))
}

regimen_warn <- function(detected, has_candidates) {
  table <- detected$table
  missed_after <- sort(detected$missed_after)
  irregular_after <- sort(detected$irregular_after)
  if (length(missed_after) + length(irregular_after) > 0) {
    message <-
      sprintf(
        "Dosing is not equally spaced; using the most common interval of %s.",
        format(table$interval[regimen_primary(table)], trim = TRUE)
      )
    if (length(missed_after) > 0) {
      message <-
        paste(
          message,
          sprintf(
            "Doses appear to be missing after time%s %s.",
            if (length(missed_after) > 1) "s" else "",
            paste(format(missed_after, trim = TRUE), collapse = ", ")
          )
        )
    }
    if (length(irregular_after) > 0) {
      message <-
        paste(
          message,
          sprintf(
            "Doses are off schedule after time%s %s.",
            if (length(irregular_after) > 1) "s" else "",
            paste(format(irregular_after, trim = TRUE), collapse = ", ")
          )
        )
    }
    rlang::warn(message, class = "pknca_warning_tau_irregular_dosing")
  }
  if (has_candidates && any(table$source %in% "auto")) {
    rlang::warn(
      paste0(
        "The dosing interval is not one of the nominal intervals, so it is reported as found in the data:\n",
        regimen_table_text(table)
      ),
      class = "pknca_warning_tau_not_nominal"
    )
  }
  if (nrow(table) > 1) {
    rlang::warn(
      paste0("The dosing regimen changes within the dose times:\n", regimen_table_text(table)),
      class = "pknca_warning_tau_regimen_change"
    )
  }
  invisible(NULL)
}

#' Find the dosing regimen from the dose times of one subject
#'
#' The dose times are sorted and times that repeat are dropped.  The regimen is
#' then described as one or more segments, each a stretch of dosing that repeats
#' over a period, found in this order:
#' \enumerate{
#'   \item Equally spaced doses repeat over their spacing.
#'   \item A cycle of more than one dose per period is looked for next:  every
#'         dose recurs a fixed number of doses later, at a span within
#'         `snap.tol` of the others, and the spacing at each position of the
#'         cycle is the same from cycle to cycle within `tol`.  Two complete
#'         cycles are required.  Twice-daily doses at 08:00 and 16:00 repeat
#'         every 24 hours with offsets 0 and 8.  When the period is not a
#'         candidate and a whole number of periods is, that multiple is used.
#'   \item Doses whose spacings are all within `tol` of their median are evenly
#'         spaced with scatter, and repeat over the median spacing.
#'   \item Otherwise, each spacing is labeled with the candidate it is within
#'         `tol` of (on the log scale), and the rest are clustered on the log
#'         scale.  Runs of at least `min.run` spacings with one label anchor
#'         segments, and the runs must hold most of the spacings.  A shorter run
#'         is a missed dose when it is a whole number (up to `max.missed`) of
#'         the segment's interval and is irregular when it is not.  Neighboring
#'         anchors with the same label are one segment, so a change of regimen
#'         gives several segments.
#'   \item If no segment forms, a cycle of 2 to 4 doses that at least 70% of
#'         the doses follow is used, with the rest irregular.
#'   \item If none of that fits, there is no repeating interval.
#' }
#'
#' The interval of a segment is snapped to the nearest candidate within
#' `snap.tol` (source `"nominal"`), and is otherwise the value found in the data
#' (source `"auto"`).  The value found in the data is the median of the
#' spacings (or spans) that set it, so scatter in the recorded times does not
#' move it.  The candidates are `tau.choices` when it is given.
#' Otherwise, when `timeu` is given, they are the built-in nominal intervals
#' converted from hours to `timeu`:  q4h (4 hours), QID (6), TID (8), BID (12),
#' QD (24), QOD (48), Q72H (72), QW (168), Q2W (336), Q3W (504), Q4W (672), Q6W
#' (1008), Q8W (1344), and Q12W (2016).  Without either, or when `timeu` cannot
#' be converted to hours, PKNCA cannot know what the numbers mean, so the
#' intervals come from the data alone and every source is `"auto"`.
#'
#' @section Conditions:
#' \describe{
#'   \item{`pknca_warning_tau_irregular_dosing`}{A segment has missed doses or
#'     doses off schedule; the message names the dose times before them.}
#'   \item{`pknca_warning_tau_not_nominal`}{There were candidates to match and
#'     a segment matched none of them.  The message includes the regimen table.}
#'   \item{`pknca_warning_tau_regimen_change`}{More than one segment was found.
#'     The message includes the regimen table.}
#' }
#'
#' @inheritParams PKNCA.choose.option
#' @param x Dose times for one subject, as numbers
#' @param tau.choices The nominal intervals to match, in the unit of `x`, or
#'   `NA` to use the built-in set (when `timeu` is given) or none.  Names are used
#'   as labels.  `NULL` takes the `tau.choices` option.
#' @param timeu The time unit of `x` (such as `"hr"` or `"day"`), or `NULL` when
#'   it is not known
#' @param tol Relative tolerance for grouping spacings with one another and with
#'   a candidate
#' @param snap.tol Relative tolerance for reporting an interval as a candidate
#'   and for the spans of a cycle
#' @param min.run The fewest consecutive spacings with one label that form a
#'   segment
#' @param max.missed The largest multiple of the interval that is read as missed
#'   doses
#' @returns A data frame with one row per segment and the columns:
#' \describe{
#'   \item{`segment`}{The segment number}
#'   \item{`start`, `end`}{The first and last dose time of the segment; a dose
#'     where the regimen changes ends one segment and starts the next}
#'   \item{`n_doses`}{The number of doses in the segment}
#'   \item{`interval`}{The period that the dose pattern repeats over, `NA` for a
#'     single dose or when nothing repeats}
#'   \item{`label`}{The name of the candidate for an evenly spaced regimen with
#'     the segment's number of doses per period (twice-daily doses at 0 and 10
#'     hours are `"BID"`), or `NA`}
#'   \item{`source`}{`"nominal"` when `interval` is a candidate and `"auto"` when
#'     it was found in the data}
#'   \item{`n_intervals_used`}{The spacings (or for a partial cycle, the spans)
#'     that set the interval}
#'   \item{`n_missed`}{Spacings read as missed doses}
#'   \item{`n_irregular`}{Spacings (or spans) that fit no interval}
#'   \item{`note`}{A description of anything unusual}
#'   \item{`offsets`}{A list column of the dose times within one period,
#'     relative to the first dose of the period}
#' }
#' With no dose times, the data frame has no rows.
#' @family Interval determination
#' @seealso [find.tau()], which gives the interval of the segment with the most
#'   doses
#' @examples
#' # Daily dosing with the times as recorded
#' find.dose.regimen(c(0, 23.6, 48, 72.4, 96), timeu = "hr")
#' # Twice daily at breakfast and dinner repeats daily
#' find.dose.regimen(c(0, 10, 24, 34, 48, 58), timeu = "hr")
#' # Daily, then twice daily
#' suppressWarnings(
#'   find.dose.regimen(c(0, 24, 48, 72, 84, 96, 108, 120), timeu = "hr")
#' )
#' @export
find.dose.regimen <- function(x, tau.choices = NULL, timeu = NULL, options = list(),
                              tol = 0.2, snap.tol = 0.1, min.run = 2, max.missed = 4) {
  if (inherits(x, c("POSIXt", "Date", "difftime"))) {
    rlang::abort(
      "Dose times must be numbers; convert date-times to a time since a reference first",
      class = "pknca_error_regimen_time_class"
    )
  }
  checkmate::assert_numeric(x, any.missing = FALSE, finite = TRUE)
  checkmate::assert_string(timeu, null.ok = TRUE)
  checkmate::assert_number(tol, lower = 0, finite = TRUE)
  checkmate::assert_number(snap.tol, lower = 0, finite = TRUE)
  checkmate::assert_count(min.run, positive = TRUE)
  checkmate::assert_count(max.missed, positive = TRUE)
  tau.choices <- PKNCA.choose.option(name = "tau.choices", value = tau.choices, options = options)
  candidates <- regimen_candidates(tau.choices, timeu)
  t <- sort_unique_time(as.vector(x))
  if (length(t) == 0) {
    ret <- regimen_row_undetermined(0, note = "")[0, ]
  } else {
    detected <- regimen_detect(t, candidates, tol, snap.tol, min.run, max.missed)
    regimen_warn(detected, has_candidates = length(candidates) > 0)
    ret <- detected$table
  }
  rownames(ret) <- NULL
  ret$offsets <- unclass(ret$offsets)
  ret
}
