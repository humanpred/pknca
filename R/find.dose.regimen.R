# Detecting the dosing regimen from the dose times of one subject.
#
# The exported find.dose.regimen() takes its arguments in PKNCA's dot style, as
# find.tau() does; the internal helpers here use snake case.  The helpers share
# `rules`, the settings built by regimen_rules().

# Nominal dosing intervals in hours, named the way protocols name them
dose_interval_nominal_hours <- function() {
  c(
    q4h = 4, QID = 6, TID = 8, BID = 12, QD = 24, QOD = 48, Q72H = 72,
    QW = 168, Q2W = 336, Q3W = 504, Q4W = 672, Q6W = 1008, Q8W = 1344,
    Q12W = 2016
  )
}

# The nominal intervals that detected intervals are matched to, in the time
# unit of the dose times, and whether the user named them.  `tau.choices` is
# the set when it is given.  Otherwise the built-in set applies when the time
# unit is known, converted from hours; with no unit there is nothing to match,
# and the intervals come from the data.
regimen_candidates <- function(tau.choices, timeu) {
  if (!identical(tau.choices, NA)) {
    values <- sort(tau.choices[tau.choices > 0])
    keep <- c(TRUE, !time_same(values[-1], values[-length(values)]))[seq_along(values)]
    return(list(values = values[keep], explicit = TRUE))
  }
  if (is.null(timeu)) {
    return(list(values = numeric(0), explicit = FALSE))
  }
  hours <- pknca_hours_factor(timeu)
  if (is.na(hours)) {
    rlang::abort(
      sprintf("timeu ('%s') cannot be converted to hours", timeu),
      class = "pknca_error_regimen_time_unit"
    )
  }
  list(values = dose_interval_nominal_hours() / hours, explicit = FALSE)
}

# The settings that every detection step uses
regimen_rules <- function(candidates, tol, snap_tol, min_run, max_missed) {
  list(
    candidates = candidates, log_tolerance = log1p(tol), snap_tol = snap_tol,
    log_snap = log1p(snap_tol), min_run = min_run, max_missed = max_missed
  )
}

# The index of the nearest candidate on the log scale for each `x`, or NA when
# none is within `log_tolerance`
regimen_nearest <- function(x, candidates, log_tolerance) {
  values <- candidates$values
  if (length(values) == 0) {
    return(rep(NA_integer_, length(x)))
  }
  distance <- abs(outer(log(x), log(values), "-"))
  best <- max.col(-distance, ties.method = "first")
  ifelse(distance[cbind(seq_along(x), best)] <= log_tolerance, best, NA_integer_)
}

# The interval, label, and source of a regimen repeating every `period` with
# `n_per_period` doses in each period.  The period is snapped to a candidate
# when one is near; the label names the evenly spaced regimen with that many
# doses per period, so twice-daily doses at 0 and 10 hours are "BID" with a 24
# hour period.
regimen_describe <- function(period, n_per_period, rules) {
  values <- rules$candidates$values
  match_period <- regimen_nearest(period, rules$candidates, rules$log_snap)
  match_each <- regimen_nearest(period / n_per_period, rules$candidates, rules$log_snap)
  label <- NA_character_
  if (!is.na(match_each) && !is.null(names(values)) && nzchar(names(values)[match_each])) {
    label <- names(values)[match_each]
  }
  if (is.na(match_period)) {
    list(interval = period, label = label, source = "auto")
  } else {
    list(interval = unname(values[match_period]), label = label, source = "nominal")
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
regimen_row_undetermined <- function(times, note) {
  regimen_row(
    segment = 1L, start = min(times), end = max(times), n_doses = length(times),
    description = list(interval = NA_real_, label = NA_character_, source = NA_character_),
    offsets = 0, n_intervals_used = 0L, n_missed = 0L,
    n_irregular = max(0L, length(times) - 1L), note = note
  )
}

# The result of a detection step:  the regimen table, the dose times followed
# by a missed dose, the dose times off schedule, and the number of spacings the
# regimen explains (which is how competing readings are compared)
regimen_detection <- function(regimen, missed_after = numeric(0),
                              off_schedule = numeric(0), explained = 0L) {
  list(
    regimen = regimen, missed_after = missed_after,
    off_schedule = off_schedule, explained = explained
  )
}

# A note listing dose times after a description, or nothing when there are none
regimen_note <- function(description, dose_times) {
  if (length(dose_times) == 0) {
    return(character(0))
  }
  paste(description, paste(dose_times, collapse = ", "))
}

# Doses given evenly every `period`
regimen_regular <- function(times, period, rules) {
  n_spacing <- length(times) - 1L
  regimen_detection(
    regimen_row(
      segment = 1L, start = times[1], end = times[length(times)],
      n_doses = length(times), description = regimen_describe(period, 1L, rules),
      offsets = 0, n_intervals_used = n_spacing, n_missed = 0L,
      n_irregular = 0L, note = ""
    ),
    explained = n_spacing
  )
}

# Where each dose falls within a cycle of `k` doses.
#
# The period is the median span of k consecutive spacings.  Each dose's phase
# within the period is clustered into k positions, which survives a missing
# dose because a dose keeps its phase when an earlier dose is not given.  The
# cycle is only a cycle when the spacings between its positions differ from
# one another by more than `log_tolerance`:  evenly spaced doses with some
# scatter also fall into k positions, one period apart, and adding spacings
# together would hide their scatter rather than find a cycle.  A dose is on the
# pattern when it is within `snap_tol` of the shortest spacing of its position,
# and every position needs two doses on the pattern (two complete periods).
#
# Returns NULL when there is no such cycle, and otherwise the period, the
# offsets of the positions from the position of the first dose, which doses are
# on the pattern, and the missed doses.
regimen_cycle_pattern <- function(times, k, rules) {
  n_dose <- length(times)
  if (n_dose < 2 * k + 1) {
    return(NULL)
  }
  period <- stats::median(times[(1 + k):n_dose] - times[seq_len(n_dose - k)])
  phase <- (times - times[1]) %% period
  phase[period - phase <= time_tolerance(period)] <- 0
  # Rotate the phases so that the widest gap between them is the wrap point, and
  # no position straddles it
  sorted <- sort(phase)
  circular_gap <- c(diff(sorted), sorted[1] + period - sorted[n_dose])
  origin <- sorted[which.max(circular_gap) %% n_dose + 1L]
  rotated <- (phase - origin) %% period
  rotated[period - rotated <= time_tolerance(period)] <- 0
  ordered <- order(rotated)
  cut_after <- sort(order(diff(rotated[ordered]), decreasing = TRUE)[seq_len(k - 1L)])
  position <- integer(n_dose)
  position[ordered] <- 1L + findInterval(seq_len(n_dose) - 1L, cut_after)
  center <- vapply(split(rotated, position), stats::median, numeric(1))
  position_gap <- diff(c(center, center[1] + period))
  if (log(max(position_gap) / min(position_gap)) <= rules$log_tolerance) {
    return(NULL)
  }
  on_pattern <- abs(rotated - center[position]) <= rules$snap_tol * min(position_gap)
  slot <- round((times - times[1] - origin - center[position]) / period) * k + position - 1L
  on_index <- which(on_pattern)
  on_pattern[on_index[duplicated(slot[on_index])]] <- FALSE
  if (any(tabulate(position[on_pattern], k) < 2)) {
    return(NULL)
  }
  slot_on <- slot[on_pattern]
  missing_slot <- setdiff(seq(min(slot_on), max(slot_on)), slot_on)
  times_on <- times[on_pattern][order(slot_on)]
  first_position <- position[which(on_pattern)[1]]
  list(
    k = k, period = period,
    offsets = unname(sort((center - center[first_position]) %% period)),
    on_pattern = on_pattern,
    missed_after = unique(times_on[findInterval(missing_slot, sort(slot_on))]),
    n_missed = length(missing_slot),
    explained = sum(on_pattern[-1] & on_pattern[-n_dose])
  )
}

# Does a cycle pattern hold every dose, with none missing?
regimen_cycle_complete <- function(pattern) {
  !is.null(pattern) && all(pattern$on_pattern) && pattern$n_missed == 0
}

# A cycle of 2 to 4 doses that every dose follows with none missing.  When its
# period is not one of the user's `tau.choices` and a whole number of periods
# is, that multiple is used, which is how a `tau.choices` of 48 selects two days
# of twice-daily doses.  The built-in nominal set only labels and snaps; it
# never selects a period longer than the one the doses repeat over.
regimen_full_cycle <- function(times, rules) {
  pattern <- NULL
  for (k in 2:4) {
    candidate <- regimen_cycle_pattern(times, k, rules)
    if (regimen_cycle_complete(candidate)) {
      pattern <- candidate
      break
    }
  }
  if (is.null(pattern) || !rules$candidates$explicit ||
      !is.na(regimen_nearest(pattern$period, rules$candidates, rules$log_snap))) {
    return(pattern)
  }
  multiple <- round(rules$candidates$values / pattern$period)
  for (m in sort(unique(multiple[multiple >= 2]))) {
    longer <- regimen_cycle_pattern(times, pattern$k * m, rules)
    if (regimen_cycle_complete(longer) &&
        !is.na(regimen_nearest(longer$period, rules$candidates, rules$log_snap))) {
      return(longer)
    }
  }
  pattern
}

# A cycle of 2 to 4 doses that at least `min_share` of the doses follow, such as
# three-times-daily doses with one dose not given.  The cycle explaining the
# most spacings is used, and the smallest k among ties.
regimen_partial_cycle <- function(times, rules, min_share = 0.7) {
  best <- NULL
  for (k in 2:4) {
    pattern <- regimen_cycle_pattern(times, k, rules)
    if (!is.null(pattern) && mean(pattern$on_pattern) >= min_share &&
        (is.null(best) || pattern$explained > best$explained)) {
      best <- pattern
    }
  }
  best
}

# The regimen table row and the flagged doses for a cycle pattern
regimen_cycle_detection <- function(times, pattern, rules) {
  off_schedule <- times[!pattern$on_pattern]
  note <-
    c(
      regimen_note("missed doses after", pattern$missed_after),
      regimen_note("off schedule at", off_schedule)
    )
  regimen_detection(
    regimen_row(
      segment = 1L, start = times[1], end = times[length(times)],
      n_doses = length(times),
      description = regimen_describe(pattern$period, pattern$k, rules),
      offsets = pattern$offsets, n_intervals_used = pattern$explained,
      n_missed = pattern$n_missed, n_irregular = length(off_schedule),
      note = paste(note, collapse = "; ")
    ),
    missed_after = pattern$missed_after, off_schedule = off_schedule,
    explained = pattern$explained
  )
}

# Label each spacing with the candidate it is near, or with a cluster of
# spacings near one another on the log scale.  A gap wider than
# `log_tolerance` between sorted spacings starts a new cluster.
regimen_label_spacing <- function(spacing, rules) {
  nominal <- regimen_nearest(spacing, rules$candidates, rules$log_tolerance)
  label <- ifelse(is.na(nominal), NA_character_, paste0("nominal", nominal))
  other <- which(is.na(nominal))
  if (length(other) > 0) {
    ordered <- other[order(spacing[other])]
    cluster <- cumsum(c(TRUE, diff(log(spacing[ordered])) > rules$log_tolerance))
    label[ordered] <- paste0("cluster", cluster)
  }
  label
}

# Doses squeezed into one scheduled interval:  a run of short spacings between
# two runs of the regimen (each long enough to be a segment) whose spacings add
# up to the regimen's interval.  Those doses are extra doses rather than a
# change of regimen.  Returns a logical vector over the doses.
regimen_extra_doses <- function(times, rules) {
  extra <- rep(FALSE, length(times))
  spacing <- diff(times)
  runs <- rle(regimen_label_spacing(spacing, rules))
  n_run <- length(runs$lengths)
  if (n_run < 3) {
    return(extra)
  }
  run_end <- cumsum(runs$lengths)
  run_start <- run_end - runs$lengths + 1L
  anchor <- runs$lengths >= rules$min_run
  for (current in seq(2L, n_run - 1L)) {
    before <- current - 1L
    after <- current + 1L
    if (!anchor[before] || !anchor[after] || runs$values[before] != runs$values[after]) {
      next
    }
    around <-
      stats::median(spacing[c(run_start[before]:run_end[before], run_start[after]:run_end[after])])
    inside <- run_start[current]:run_end[current]
    if (abs(log(sum(spacing[inside]) / around)) <= rules$log_tolerance) {
      extra[inside[-1]] <- TRUE
    }
  }
  extra
}

# Runs of same-labeled spacings, and the segment each spacing belongs to.
#
# A run of at least `min_run` spacings anchors a segment, and the anchors must
# hold most of the spacings, or there is no regimen to report (NULL).  A shorter
# run joins the anchor before it (or after it, at the start).  Anchors with the
# same label next to one another are one segment.
regimen_segment_runs <- function(spacing, rules) {
  n_spacing <- length(spacing)
  runs <- rle(regimen_label_spacing(spacing, rules))
  anchor <- runs$lengths >= min(rules$min_run, n_spacing)
  if (!any(anchor) || sum(runs$lengths[anchor]) <= n_spacing / 2) {
    return(NULL)
  }
  run_of <- rep(seq_along(runs$lengths), runs$lengths)
  anchor_index <- which(anchor)
  previous_anchor <- findInterval(seq_along(runs$lengths), anchor_index)
  assigned_run <- anchor_index[pmax(previous_anchor, 1L)]
  assigned <- assigned_run[run_of]
  anchor_label <- runs$values[assigned]
  list(
    member = run_of == assigned,
    segment = cumsum(c(TRUE, anchor_label[-1] != anchor_label[-n_spacing]))
  )
}

# The doses that are off schedule, from the spacings that fit neither the
# interval nor a missed dose.  A dose given early or late leaves two irregular
# spacings in a row, and it is the dose between them; a lone irregular spacing
# is the dose that ends it, after which the schedule continues from that dose.
regimen_off_schedule_doses <- function(times, irregular) {
  if (length(irregular) == 0) {
    return(numeric(0))
  }
  stretch <- split(irregular, cumsum(c(1L, diff(irregular) != 1L)))
  times[unlist(lapply(stretch, regimen_off_schedule_stretch), use.names = FALSE)]
}

# The dose indices off schedule within one stretch of consecutive irregular
# spacings (see regimen_off_schedule_doses())
regimen_off_schedule_stretch <- function(spacing_index) {
  if (length(spacing_index) == 1) {
    spacing_index + 1L
  } else {
    spacing_index[-1]
  }
}

# One segment from its spacings.  Spacings that are not in the segment's runs
# are missed doses when they are a whole number (up to `max_missed`) of the
# segment's interval and are irregular otherwise.  A segment with nothing
# missed or off schedule may itself repeat over more than one dose, as
# twice-daily doses at breakfast and dinner do.
regimen_segment <- function(times, spacing, within, member, segment_id, rules) {
  in_run <- within[member[within]]
  other <- within[!member[within]]
  base <- stats::median(spacing[in_run])
  multiple <- round(spacing[other] / base)
  missed <-
    multiple >= 2 & multiple <= rules$max_missed &
    abs(log(spacing[other] / (multiple * base))) <= rules$log_tolerance
  missed_after <- times[other[missed]]
  off_schedule <- regimen_off_schedule_doses(times, other[!missed])
  description <- regimen_describe(base, 1L, rules)
  offsets <- 0
  segment_times <- times[c(within, max(within) + 1L)]
  if (length(other) == 0) {
    pattern <- regimen_full_cycle(segment_times, rules)
    if (!is.null(pattern)) {
      description <- regimen_describe(pattern$period, pattern$k, rules)
      offsets <- pattern$offsets
    }
  }
  note <-
    c(
      regimen_note("missed doses after", missed_after),
      regimen_note("off schedule at", off_schedule)
    )
  regimen_detection(
    regimen_row(
      segment = segment_id, start = min(segment_times), end = max(segment_times),
      n_doses = length(segment_times), description = description,
      offsets = offsets, n_intervals_used = length(in_run),
      n_missed = sum(missed), n_irregular = length(off_schedule),
      note = paste(note, collapse = "; ")
    ),
    missed_after = missed_after, off_schedule = off_schedule,
    explained = length(in_run) + sum(missed)
  )
}

# Bind detections of one segment each into one detection
regimen_bind <- function(detections) {
  regimen <- do.call(rbind, lapply(detections, getElement, "regimen"))
  if (nrow(regimen) > 1) {
    regimen$note <-
      ifelse(nzchar(regimen$note), paste0("regimen change; ", regimen$note), "regimen change")
  }
  regimen_detection(
    regimen,
    missed_after = unlist(lapply(detections, getElement, "missed_after")),
    off_schedule = unlist(lapply(detections, getElement, "off_schedule")),
    explained = sum(vapply(detections, getElement, numeric(1), "explained"))
  )
}

# Count extra doses (see regimen_extra_doses()) in the segment that holds them
regimen_add_extra_doses <- function(detection, extra_times) {
  if (length(extra_times) == 0) {
    return(detection)
  }
  regimen <- detection$regimen
  for (row in seq_len(nrow(regimen))) {
    inside <- extra_times[extra_times > regimen$start[row] & extra_times < regimen$end[row]]
    if (length(inside) > 0) {
      regimen$n_doses[row] <- regimen$n_doses[row] + length(inside)
      regimen$n_irregular[row] <- regimen$n_irregular[row] + length(inside)
      existing <- regimen$note[row][nzchar(regimen$note[row])]
      regimen$note[row] <- paste(c(existing, regimen_note("extra dose at", inside)), collapse = "; ")
    }
  }
  detection$regimen <- regimen
  detection$off_schedule <- sort(c(detection$off_schedule, extra_times))
  detection
}

# Regimen segments from runs of same-labeled spacings, after setting aside
# extra doses.  NULL when the runs do not hold most of the spacings.
regimen_segments <- function(times, rules) {
  extra <- regimen_extra_doses(times, rules)
  kept <- times[!extra]
  spacing <- diff(kept)
  runs <- regimen_segment_runs(spacing, rules)
  if (is.null(runs)) {
    return(NULL)
  }
  detections <- list()
  for (segment_id in unique(runs$segment)) {
    within <- which(runs$segment == segment_id)
    detections[[length(detections) + 1L]] <-
      regimen_segment(kept, spacing, within, runs$member, segment_id, rules)
  }
  regimen_add_extra_doses(regimen_bind(detections), times[extra])
}

# The number of things a reading has to explain away:  missed doses, doses off
# schedule or extra, and changes of regimen.  Zero is a clean reading.
regimen_anomalies <- function(detection) {
  regimen <- detection$regimen
  sum(regimen$n_missed) + sum(regimen$n_irregular) + nrow(regimen) - 1L
}

# Should a cycle reading replace a reading by runs?  The cycle must explain more
# spacings, or as many with no more anomalies.  Daily dosing that follows
# twice-daily dosing therefore stays a change of regimen rather than twice-daily
# dosing with every evening dose missed, while doses at 0 and 10 hours with one
# dose not given stay a daily cycle; the runs read the 10 and 14 hour spacings
# as one spacing, which a cycle describes more fully.
regimen_cycle_preferred <- function(cycle, segments) {
  is.null(segments) ||
    cycle$explained > segments$explained ||
    (cycle$explained == segments$explained &&
       regimen_anomalies(cycle) <= regimen_anomalies(segments))
}

# Doses that are not evenly spaced and not a complete cycle.  Runs of one
# spacing are the first reading.  When that reading has missed doses, doses off
# schedule, or more than one segment, a cycle of 2 to 4 doses is tried, so
# three-times-daily dosing with a dose not given stays three times daily rather
# than becoming a change between every-6-hour and twice-daily dosing.
regimen_detect_irregular <- function(times, rules) {
  segments <- regimen_segments(times, rules)
  if (!is.null(segments) && regimen_anomalies(segments) == 0) {
    return(segments)
  }
  pattern <- regimen_partial_cycle(times, rules)
  if (!is.null(pattern)) {
    cycle <- regimen_cycle_detection(times, pattern, rules)
    if (regimen_cycle_preferred(cycle, segments)) {
      return(cycle)
    }
  }
  if (!is.null(segments)) {
    return(segments)
  }
  regimen_detection(regimen_row_undetermined(times, note = "no repeating interval"))
}

# The regimen for sorted, unique dose times:  evenly spaced doses, then a
# complete cycle of more than one dose, then evenly spaced doses with scatter,
# then the readings of regimen_detect_irregular()
regimen_detect <- function(times, rules) {
  if (length(times) == 1) {
    return(regimen_detection(regimen_row_undetermined(times, note = "single dose")))
  }
  spacing <- diff(times)
  if (all(time_same(spacing, spacing[1]))) {
    return(regimen_regular(times, spacing[1], rules))
  }
  pattern <- regimen_full_cycle(times, rules)
  if (!is.null(pattern)) {
    return(regimen_cycle_detection(times, pattern, rules))
  }
  if (all(abs(log(spacing / stats::median(spacing))) <= rules$log_tolerance)) {
    return(regimen_regular(times, stats::median(spacing), rules))
  }
  regimen_detect_irregular(times, rules)
}

# The regimen table as text for a condition message
regimen_table_text <- function(regimen) {
  regimen$offsets <- vapply(regimen$offsets, paste, character(1), collapse = ", ")
  paste(utils::capture.output(print(regimen, row.names = FALSE)), collapse = "\n")
}

# The row of the regimen table that describes the subject:  the segment with
# the most doses, and the latest of those when segments tie
regimen_primary <- function(regimen) {
  max(which(regimen$n_doses == max(regimen$n_doses)))
}

# A list of dose times for a message, with "time" or "times" before it
regimen_times_text <- function(dose_times) {
  sprintf(
    "time%s %s",
    if (length(dose_times) > 1) "s" else "",
    paste(format(dose_times, trim = TRUE), collapse = ", ")
  )
}

# Give the warnings for a detection:  missed doses and doses off schedule, an
# interval that matches no candidate (only when there were candidates to
# match), and a change of regimen
regimen_warn <- function(detection, has_candidates) {
  regimen <- detection$regimen
  missed_after <- sort(detection$missed_after)
  off_schedule <- sort(detection$off_schedule)
  if (length(missed_after) + length(off_schedule) > 0) {
    msg <-
      sprintf(
        "Dosing is not equally spaced; using the most common interval of %s.",
        format(regimen$interval[regimen_primary(regimen)], trim = TRUE)
      )
    if (length(missed_after) > 0) {
      msg <- paste0(msg, " Doses appear to be missing after ", regimen_times_text(missed_after), ".")
    }
    if (length(off_schedule) > 0) {
      msg <- paste0(msg, " Doses are off schedule at ", regimen_times_text(off_schedule), ".")
    }
    rlang::warn(msg, class = "pknca_warning_tau_irregular_dosing")
  }
  if (has_candidates && any(regimen$source %in% "auto")) {
    rlang::warn(
      paste0(
        "The dosing interval is not one of the nominal intervals, so it is reported as found in the data:\n",
        regimen_table_text(regimen)
      ),
      class = "pknca_warning_tau_not_nominal"
    )
  }
  if (nrow(regimen) > 1) {
    rlang::warn(
      paste0("The dosing regimen changes within the dose times:\n", regimen_table_text(regimen)),
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
#'   \item A cycle of 2 to 4 doses per period that every dose follows is looked
#'         for next.  The period is the median span of that many spacings, and
#'         each dose's time within the period falls into one of the positions
#'         of the cycle.  The spacings between the positions must differ from
#'         one another by more than `tol`, every dose must be within `snap.tol`
#'         of its position, and every position must hold at least two doses
#'         (two complete periods).  Twice-daily doses at 08:00 and 16:00 repeat
#'         every 24 hours with offsets 0 and 8.  When the period is not one of
#'         the given `tau.choices` and a whole number of periods is, that
#'         multiple is used; the built-in nominal set never selects a longer
#'         period.
#'   \item Doses whose spacings are all within `tol` of their median are evenly
#'         spaced with scatter, and repeat over the median spacing.
#'   \item Otherwise, each spacing is labeled with the candidate it is within
#'         `tol` of (on the log scale), and the rest are clustered on the log
#'         scale.  Doses squeezed into one interval between two runs of the
#'         regimen are set aside as extra doses.  Runs of at least `min.run`
#'         spacings with one label anchor segments, and the runs must hold most
#'         of the spacings.  A spacing outside the runs is a missed dose when it
#'         is a whole number (up to `max.missed`) of the segment's interval and
#'         is irregular when it is not; a dose given early or late is the dose
#'         between two irregular spacings.  Neighboring anchors with the same
#'         label are one segment, so a change of regimen gives several segments.
#'   \item When that reading has missed or irregular doses or more than one
#'         segment, a cycle of 2 to 4 doses that at least 70% of the doses follow
#'         is used instead if it explains more spacings, or as many with no more
#'         missed, off-schedule, or extra doses and changes of regimen.  This
#'         keeps three-times-daily dosing with a dose not given as three times
#'         daily, and daily dosing after twice-daily dosing as a change of
#'         regimen.
#'   \item If none of that fits, there is no repeating interval.
#' }
#'
#' The interval of a segment is snapped to the nearest candidate within
#' `snap.tol` (source `"nominal"`), and is otherwise the value found in the data
#' (source `"auto"`).  The value found in the data is the median of the
#' spacings (or spans) that set it, so scatter in the recorded times does not
#' move it.  The candidates are `tau.choices` when it is given.  Otherwise, when
#' `timeu` is given, they are the built-in nominal intervals converted from hours
#' to `timeu`:  q4h (4 hours), QID (6), TID (8), BID (12), QD (24), QOD (48),
#' Q72H (72), QW (168), Q2W (336), Q3W (504), Q4W (672), Q6W (1008), Q8W (1344),
#' and Q12W (2016).  Without either, PKNCA cannot know what the numbers mean, so
#' the intervals come from the data alone and every source is `"auto"`.
#'
#' @section Conditions:
#' \describe{
#'   \item{`pknca_warning_tau_irregular_dosing`}{A segment has missed doses
#'     (the message names the dose times before them) or doses off schedule
#'     (the message names those doses).}
#'   \item{`pknca_warning_tau_not_nominal`}{There were candidates to match and
#'     a segment matched none of them.  The message includes the regimen table.}
#'   \item{`pknca_warning_tau_regimen_change`}{More than one segment was found.
#'     The message includes the regimen table.}
#'   \item{`pknca_error_regimen_time_unit`}{`timeu` cannot be converted to
#'     hours.}
#'   \item{`pknca_error_regimen_time_class`}{`x` is a date-time or difftime
#'     rather than a number.}
#' }
#'
#' @inheritParams PKNCA.choose.option
#' @param x Dose times for one subject, as numbers
#' @param tau.choices The nominal intervals to match, in the unit of `x`, or
#'   `NA` to use the built-in set (when `timeu` is given) or none.  Names are used
#'   as labels.  `NULL` takes the `tau.choices` option.
#' @param timeu The time unit of `x` (such as `"hr"` or `"day"`), or `NULL` (or
#'   `""`) when it is not known.  A unit that cannot be converted to hours is an
#'   error.
#' @param tol Relative tolerance for grouping spacings with one another and with
#'   a candidate
#' @param snap.tol Relative tolerance for reporting an interval as a candidate
#'   and for a dose to be on a cycle's pattern
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
#'   \item{`n_intervals_used`}{The spacings that set the interval}
#'   \item{`n_missed`}{Doses read as missed}
#'   \item{`n_irregular`}{Doses off schedule or extra}
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
  if (identical(timeu, "")) {
    timeu <- NULL
  }
  tau.choices <- PKNCA.choose.option(name = "tau.choices", value = tau.choices, options = options)
  candidates <- regimen_candidates(tau.choices, timeu)
  times <- sort_unique_time(as.vector(x))
  if (length(times) == 0) {
    ret <- regimen_row_undetermined(0, note = "")[0, ]
  } else {
    rules <-
      regimen_rules(
        candidates, tol = tol, snap_tol = snap.tol, min_run = min.run,
        max_missed = max.missed
      )
    detection <- regimen_detect(times, rules)
    regimen_warn(detection, has_candidates = length(candidates$values) > 0)
    ret <- detection$regimen
  }
  rownames(ret) <- NULL
  ret$offsets <- unclass(ret$offsets)
  ret
}
