# One expected row of the regimen table
regimen_expected <- function(segment = 1L, start, end, n_doses, interval, label,
                             source, n_intervals_used, n_missed = 0L,
                             n_irregular = 0L, note = "", offsets = 0) {
  ret <-
    data.frame(
      segment = segment, start = start, end = end, n_doses = n_doses,
      interval = interval, label = label, source = source,
      n_intervals_used = n_intervals_used, n_missed = n_missed,
      n_irregular = n_irregular, note = note
    )
  ret$offsets <- list(offsets)
  ret
}

test_that("find.dose.regimen describes a single dose", {
  expect_equal(
    find.dose.regimen(5, timeu = "hr"),
    regimen_expected(
      start = 5, end = 5, n_doses = 1L, interval = NA_real_, label = NA_character_,
      source = NA_character_, n_intervals_used = 0L, note = "single dose"
    )
  )
})

test_that("find.dose.regimen handles degenerate input", {
  empty <- find.dose.regimen(numeric(0), timeu = "hr")
  expect_equal(nrow(empty), 0)
  expect_equal(
    names(empty),
    c("segment", "start", "end", "n_doses", "interval", "label", "source",
      "n_intervals_used", "n_missed", "n_irregular", "note", "offsets")
  )
  expect_error(find.dose.regimen(c(0, NA, 24)), regexp = "missing")
  expect_error(find.dose.regimen(c(0, Inf)), regexp = "finite")
  expect_error(find.dose.regimen("0"), regexp = "numeric")
  expect_error(find.dose.regimen(Sys.time()), class = "pknca_error_regimen_time_class")
  expect_error(find.dose.regimen(as.difftime(1, units = "hours")), class = "pknca_error_regimen_time_class")
  # Two doses give the spacing between them
  expect_equal(
    find.dose.regimen(c(0, 24), timeu = "hr"),
    regimen_expected(
      start = 0, end = 24, n_doses = 2L, interval = 24, label = "QD",
      source = "nominal", n_intervals_used = 1L
    )
  )
  # A dose recorded twice is one dose
  expect_equal(find.dose.regimen(c(24, 0, 0, 24), timeu = "hr")$n_doses, 2L)
})

test_that("find.dose.regimen checks its arguments", {
  expect_error(find.dose.regimen(0:3, timeu = 1), regexp = "timeu")
  expect_error(find.dose.regimen(0:3, tol = -1), regexp = "tol")
  expect_error(find.dose.regimen(0:3, snap.tol = NA), regexp = "snap.tol")
  expect_error(find.dose.regimen(0:3, min.run = 0), regexp = "min.run")
  expect_error(find.dose.regimen(0:3, max.missed = 1.5), regexp = "max.missed")
})

test_that("find.dose.regimen finds regular daily and twice-daily dosing", {
  expect_equal(
    find.dose.regimen(seq(0, 144, by = 24), timeu = "hr"),
    regimen_expected(
      start = 0, end = 144, n_doses = 7L, interval = 24, label = "QD",
      source = "nominal", n_intervals_used = 6L
    )
  )
  expect_equal(
    find.dose.regimen(seq(0, 72, by = 12), timeu = "hr"),
    regimen_expected(
      start = 0, end = 72, n_doses = 7L, interval = 12, label = "BID",
      source = "nominal", n_intervals_used = 6L
    )
  )
})

test_that("find.dose.regimen gives uneven twice-daily dosing a daily period", {
  # Doses at 08:00 and 16:00 repeat every 24 hours, 8 hours apart
  expect_equal(
    find.dose.regimen(c(8, 16, 32, 40, 56, 64, 80, 88), timeu = "hr"),
    regimen_expected(
      start = 8, end = 88, n_doses = 8L, interval = 24, label = "BID",
      source = "nominal", n_intervals_used = 7L, offsets = c(0, 8)
    )
  )
  # Breakfast and dinner, 10 hours apart:  a 10 hour spacing is at the edge of
  # the tolerance of 12 hours, and the repeating daily pattern is found first
  expect_equal(
    find.dose.regimen(c(0, 10, 24, 34, 48, 58, 72, 82), timeu = "hr"),
    regimen_expected(
      start = 0, end = 82, n_doses = 8L, interval = 24, label = "BID",
      source = "nominal", n_intervals_used = 7L, offsets = c(0, 10)
    )
  )
  # Three times a day with an overnight gap is a daily pattern, not a 6 hour
  # interval with missed doses
  expect_no_warning(
    tid <- find.dose.regimen(c(0, 6, 12, 24, 30, 36, 48, 54, 60), timeu = "hr")
  )
  expect_equal(
    tid,
    regimen_expected(
      start = 0, end = 60, n_doses = 9L, interval = 24, label = "TID",
      source = "nominal", n_intervals_used = 8L, offsets = c(0, 6, 12)
    )
  )
})

test_that("find.dose.regimen reads a missed daily dose", {
  expect_warning(
    ret <- find.dose.regimen(c(0, 24, 48, 96, 120, 144), timeu = "hr"),
    regexp = "Doses appear to be missing after time 48[.]$",
    class = "pknca_warning_tau_irregular_dosing"
  )
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 144, n_doses = 6L, interval = 24, label = "QD",
      source = "nominal", n_intervals_used = 4L, n_missed = 1L,
      note = "missed doses after 48"
    )
  )
})

test_that("find.dose.regimen gives one segment per regimen", {
  doses <- c(0, 24, 48, 72, 84, 96, 108, 120)
  expect_warning(
    ret <- find.dose.regimen(doses, timeu = "hr"),
    regexp = "regimen changes within the dose times",
    class = "pknca_warning_tau_regimen_change"
  )
  expect_equal(
    ret,
    rbind(
      regimen_expected(
        segment = 1L, start = 0, end = 72, n_doses = 4L, interval = 24,
        label = "QD", source = "nominal", n_intervals_used = 3L,
        note = "regimen change"
      ),
      regimen_expected(
        segment = 2L, start = 72, end = 120, n_doses = 5L, interval = 12,
        label = "BID", source = "nominal", n_intervals_used = 4L,
        note = "regimen change"
      )
    )
  )
  # The table is in the message so that a caller can show it
  expect_warning(
    find.dose.regimen(doses, timeu = "hr"),
    regexp = "72 120       5       12   BID"
  )
  # find.tau() gives the segment with the most doses
  expect_warning(
    expect_equal(find.tau(doses, timeu = "hr"), 12),
    class = "pknca_warning_tau_regimen_change"
  )
  # and the later one when segments have as many doses
  expect_warning(
    expect_equal(find.tau(c(0, 24, 48, 60, 72), timeu = "hr"), 12),
    class = "pknca_warning_tau_regimen_change"
  )
})

test_that("find.dose.regimen snaps scattered dose times to the nominal interval", {
  expect_no_warning(
    ret <- find.dose.regimen(c(0, 23.6, 48, 72.4, 96), timeu = "hr")
  )
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 96, n_doses = 5L, interval = 24, label = "QD",
      source = "nominal", n_intervals_used = 4L
    )
  )
  # Without a unit the times are taken to be hours, so they snap the same way;
  # with a unit that cannot be used, the interval is the median spacing
  expect_equal(find.dose.regimen(c(0, 23.6, 48, 72.4, 96))$interval, 24)
  expect_equal(find.dose.regimen(c(0, 23.5, 47, 71.5, 95))$interval, 24)
  expect_equal(find.dose.regimen(c(0, 23.5, 47, 71.5, 95), timeu = NA)$interval, 23.5)
})

test_that("find.dose.regimen reports an interval that matches no nominal one", {
  expect_warning(
    ret <- find.dose.regimen(seq(0, 150, by = 30), timeu = "hr"),
    regexp = "not one of the nominal intervals",
    class = "pknca_warning_tau_not_nominal"
  )
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 150, n_doses = 6L, interval = 30, label = NA_character_,
      source = "auto", n_intervals_used = 5L
    )
  )
  # Without a unit the times are taken to be hours, so it is said then too
  expect_warning(
    ret_no_unit <- find.dose.regimen(seq(0, 150, by = 30)),
    class = "pknca_warning_tau_not_nominal"
  )
  expect_equal(ret_no_unit, ret)
  # With a unit that cannot be used there is nothing to match, so there is no
  # warning
  expect_no_warning(ret_unusable <- find.dose.regimen(seq(0, 150, by = 30), timeu = NA))
  expect_equal(ret_unusable$source, "auto")
  expect_equal(ret_unusable$interval, 30)
})

test_that("find.dose.regimen matches tau.choices instead of the built-in set", {
  bid <- c(0, 10, 24, 34, 48, 58, 72, 82, 96, 106)
  # A 48 hour choice selects two days of the daily pattern
  expect_equal(
    find.dose.regimen(bid, tau.choices = 48, timeu = "hr"),
    regimen_expected(
      start = 0, end = 106, n_doses = 10L, interval = 48, label = NA_character_,
      source = "nominal", n_intervals_used = 9L, offsets = c(0, 10, 24, 34)
    )
  )
  # Named choices label the regimen
  expect_equal(
    find.dose.regimen(bid, tau.choices = c(twice = 12, daily = 24))$label,
    "twice"
  )
  # The option is used when the argument is not given
  expect_equal(find.dose.regimen(bid, options = list(tau.choices = 48))$interval, 48)
  # Daily dosing with only a weekly choice is not nominal
  expect_warning(
    ret_weekly <- find.dose.regimen(seq(0, 96, by = 24), tau.choices = 168),
    class = "pknca_warning_tau_not_nominal"
  )
  expect_equal(ret_weekly$interval, 24)
  expect_equal(ret_weekly$source, "auto")
})

test_that("find.dose.regimen converts the built-in set to the time unit", {
  skip_if_not_installed("units")
  expect_equal(
    find.dose.regimen(0:6, timeu = "day"),
    regimen_expected(
      start = 0, end = 6, n_doses = 7L, interval = 1, label = "QD",
      source = "nominal", n_intervals_used = 6L
    )
  )
  # A unit that cannot be converted to hours is an error rather than silently
  # losing the nominal set
  expect_error(
    find.dose.regimen(0:6, timeu = "furlong"),
    regexp = "timeu [(]'furlong'[)] cannot be converted to hours",
    class = "pknca_error_regimen_time_unit"
  )
  expect_error(find.dose.regimen(0:6, timeu = "foo"), class = "pknca_error_regimen_time_unit")
})

test_that("find.dose.regimen treats an empty time unit as unknown", {
  # An unknown unit is taken to be hours
  expect_equal(find.dose.regimen(c(0, 24, 50), timeu = ""), find.dose.regimen(c(0, 24, 50)))
  expect_equal(find.dose.regimen(c(0, 24, 50), timeu = "")$interval, 24)
  # NA, of either type, is a unit that cannot be used
  expect_equal(find.dose.regimen(c(0, 24, 50), timeu = NA)$interval, 25)
  expect_equal(find.dose.regimen(c(0, 24, 50), timeu = NA_character_)$interval, 25)
})

test_that("find.dose.regimen follows a cycle that most of the doses keep", {
  # 08:00 and 16:00 with the dose at 56 hours missed:  no run of spacings forms,
  # and every other dose keeps its time of day
  expect_warning(
    ret <- find.dose.regimen(c(0, 8, 24, 32, 48, 72, 80, 96, 104), timeu = "hr"),
    regexp = "Doses appear to be missing after time 48[.]$",
    class = "pknca_warning_tau_irregular_dosing"
  )
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 104, n_doses = 9L, interval = 24, label = "BID",
      source = "nominal", n_intervals_used = 8L, n_missed = 1L,
      note = "missed doses after 48", offsets = c(0, 8)
    )
  )
})

test_that("find.dose.regimen keeps a cycle with one dose not given", {
  tid <- c(0, 6, 12) + rep(0:6 * 24, each = 3)
  # Removing a dose from any position of the cycle leaves the daily cycle; the
  # dose before the gap is named
  for (dropped in c(48, 54, 60)) {
    doses <- setdiff(tid, dropped)
    expect_warning(
      ret <- find.dose.regimen(doses, timeu = "hr"),
      regexp = "Doses appear to be missing after time",
      class = "pknca_warning_tau_irregular_dosing"
    )
    expect_equal(
      ret,
      regimen_expected(
        start = 0, end = 156, n_doses = 20L, interval = 24, label = "TID",
        source = "nominal", n_intervals_used = 19L, n_missed = 1L,
        note = paste("missed doses after", max(doses[doses < dropped])),
        offsets = c(0, 6, 12)
      )
    )
  }
  bid <- setdiff(c(0, 10) + rep(0:6 * 24, each = 2), 58)
  expect_warning(
    ret_bid <- find.dose.regimen(bid, timeu = "hr"),
    regexp = "Doses appear to be missing after time 48[.]$",
    class = "pknca_warning_tau_irregular_dosing"
  )
  expect_equal(
    ret_bid,
    regimen_expected(
      start = 0, end = 154, n_doses = 13L, interval = 24, label = "BID",
      source = "nominal", n_intervals_used = 12L, n_missed = 1L,
      note = "missed doses after 48", offsets = c(0, 10)
    )
  )
  expect_warning(
    expect_equal(find.tau(bid), 24),
    class = "pknca_warning_tau_irregular_dosing"
  )
})

test_that("find.dose.regimen finds no interval when nothing repeats", {
  expect_no_warning(ret <- find.dose.regimen(c(0, 1, 3, 5, 9)))
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 9, n_doses = 5L, interval = NA_real_,
      label = NA_character_, source = NA_character_, n_intervals_used = 0L,
      n_irregular = 4L, note = "no repeating interval"
    )
  )
  expect_equal(find.tau(c(0, 1, 3, 5, 9)), NA)
})

test_that("find.tau passes the time unit through", {
  expect_equal(find.tau(c(0, 23.6, 48, 72.4, 96), timeu = "hr"), 24)
  expect_equal(find.tau(c(0, 10, 24, 34, 48, 58), timeu = "hr"), 24)
})

test_that("find.dose.regimen notes a missed dose within a regimen change", {
  doses <- c(0, 24, 48, 96, 120, 144, 156, 168, 180, 192)
  expect_warning(
    expect_warning(
      ret <- find.dose.regimen(doses, timeu = "hr"),
      class = "pknca_warning_tau_irregular_dosing"
    ),
    class = "pknca_warning_tau_regimen_change"
  )
  expect_equal(ret$start, c(0, 144))
  expect_equal(ret$end, c(144, 192))
  expect_equal(ret$interval, c(24, 12))
  expect_equal(ret$n_missed, c(1L, 0L))
  expect_equal(ret$note, c("regimen change; missed doses after 48", "regimen change"))
})

test_that("a cycle needs two complete periods", {
  rules <-
    regimen_rules(
      list(values = numeric(0), explicit = FALSE), tol = 0.2, snap_tol = 0.1,
      min_run = 2, max_missed = 4
    )
  # Doses at 0 and 10 hours for two days hold one complete daily cycle and the
  # start of a second
  expect_null(regimen_cycle_pattern(c(0, 10, 24, 34), k = 2, rules = rules))
  expect_equal(regimen_cycle_pattern(c(0, 10, 24, 34, 48), k = 2, rules = rules)$period, 24)
})

test_that("find.dose.regimen finds the cycle within a segment", {
  # Breakfast and dinner, then once daily
  expect_warning(
    ret <- find.dose.regimen(c(0, 10, 24, 34, 48, 58, 72, 96, 120, 144), timeu = "hr"),
    class = "pknca_warning_tau_regimen_change"
  )
  expect_equal(
    ret,
    rbind(
      regimen_expected(
        segment = 1L, start = 0, end = 72, n_doses = 7L, interval = 24,
        label = "BID", source = "nominal", n_intervals_used = 6L,
        note = "regimen change", offsets = c(0, 10)
      ),
      regimen_expected(
        segment = 2L, start = 72, end = 144, n_doses = 4L, interval = 24,
        label = "QD", source = "nominal", n_intervals_used = 3L,
        note = "regimen change"
      )
    )
  )
})

test_that("find.dose.regimen reads scattered daily doses as daily, not as a cycle", {
  spacing <-
    c(27.4, 23.8, 20.5, 25.7, 23.5, 26.1, 22.2, 25.6, 23.6, 24.3, 22.3, 25.2,
      21.3, 27.3, 20.7, 24.8, 26.8, 22.8, 23.1, 24.2)
  doses <- c(0, cumsum(spacing))
  expect_no_warning(ret <- find.dose.regimen(doses, timeu = "hr"))
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = sum(spacing), n_doses = 21L, interval = 24, label = "QD",
      source = "nominal", n_intervals_used = 20L
    )
  )
  # Without a unit the interval is the median spacing, with no warning
  expect_no_warning(tau <- find.tau(doses))
  expect_equal(tau, stats::median(spacing))
  # Scatter of up to 3 hours, whether it carries forward from dose to dose or
  # is around each nominal time, is still daily dosing with one dose a day.
  # Around nominal times, neighboring spacings can differ by 6 hours, which is
  # beyond the tolerance, so those doses are named as off schedule.
  for (seed in 1:5) {
    set.seed(seed)
    carried <- c(0, cumsum(24 + stats::runif(20, -3, 3)))
    expect_no_warning(ret_carried <- find.dose.regimen(carried, timeu = "hr"))
    expect_equal(ret_carried$interval, 24)
    expect_equal(ret_carried$offsets, list(0))
    around <- 24 * 0:20 + stats::runif(21, -3, 3)
    ret_around <-
      withCallingHandlers(
        find.dose.regimen(around, timeu = "hr"),
        pknca_warning_tau_irregular_dosing = function(w) invokeRestart("muffleWarning")
      )
    expect_equal(ret_around$interval, 24)
    expect_equal(ret_around$offsets, list(0))
    expect_equal(nrow(ret_around), 1)
  }
})

test_that("find.dose.regimen runs in linear time", {
  set.seed(1)
  doses <- 24 * 0:1999 + stats::runif(2000, -2, 2)
  elapsed <- system.time(ret <- find.dose.regimen(doses, timeu = "hr"))[["elapsed"]]
  expect_equal(ret$interval, 24)
  expect_lt(elapsed, 1)
})

test_that("the built-in nominal set does not choose a longer period", {
  # Doses 12 and 24 hours apart repeat every 36 hours; Q72H is two periods and
  # is not chosen because the doses repeat over 36
  doses <- c(0, 12, 36, 48, 72, 84, 108, 120, 144, 156)
  expect_warning(
    ret <- find.dose.regimen(doses, timeu = "hr"),
    class = "pknca_warning_tau_not_nominal"
  )
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 156, n_doses = 10L, interval = 36, label = NA_character_,
      source = "auto", n_intervals_used = 9L, offsets = c(0, 12)
    )
  )
  expect_warning(expect_equal(find.tau(doses), 36), class = "pknca_warning_tau_not_nominal")
  # A user's choice does select the multiple
  expect_equal(find.tau(doses, tau.choices = 72), 72)
})

test_that("find.dose.regimen names one dose off schedule once", {
  # The dose at 90 hours should have been at 96
  expect_warning(
    ret <- find.dose.regimen(c(0, 24, 48, 72, 90, 120, 144, 168), timeu = "hr"),
    regexp = "Doses are off schedule at time 90[.]$",
    class = "pknca_warning_tau_irregular_dosing"
  )
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 168, n_doses = 8L, interval = 24, label = "QD",
      source = "nominal", n_intervals_used = 5L, n_irregular = 1L,
      note = "off schedule at 90"
    )
  )
})

test_that("find.dose.regimen reads an extra dose as an extra dose, not a regimen", {
  doses <- c(0:20 * 24, 252)
  expect_warning(
    ret <- find.dose.regimen(doses, timeu = "hr"),
    regexp = "Doses are off schedule at time 252[.]$",
    class = "pknca_warning_tau_irregular_dosing"
  )
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 480, n_doses = 22L, interval = 24, label = "QD",
      source = "nominal", n_intervals_used = 20L, n_irregular = 1L,
      note = "extra dose at 252"
    )
  )
})

test_that("find.tau drops NA that na.action keeps", {
  expect_equal(find.tau(c(0, 24, NA, 48), na.action = stats::na.pass), 24)
  expect_equal(find.tau(c(NA_real_, NA_real_), na.action = stats::na.pass), NA)
})

test_that("a user's choice that no multiple of the period matches is not used", {
  # Doses at 0 and 10 hours for four days repeat daily; a 168 hour choice would
  # need seven days to hold two weeks of the pattern
  doses <- c(0, 10) + rep(0:3 * 24, each = 2)
  expect_warning(
    ret <- find.dose.regimen(doses, tau.choices = 168),
    class = "pknca_warning_tau_not_nominal"
  )
  expect_equal(ret$interval, 24)
  expect_equal(ret$offsets, list(c(0, 10)))
})

test_that("gradually lengthening spacings form one run", {
  # Each spacing is within the tolerance of the next, though not all are within
  # it of their median, so they are one segment at the median spacing (taken
  # as data here, with a unit that cannot be used)
  doses <- cumsum(c(0, 20, 23, 26.5, 30))
  expect_no_warning(ret <- find.dose.regimen(doses, timeu = NA))
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 99.5, n_doses = 5L, interval = 24.75, label = NA_character_,
      source = "auto", n_intervals_used = 4L
    )
  )
})

test_that("find.dose.regimen reads two missed doses in a short history", {
  doses <- setdiff(0:6 * 24, c(72, 96))
  expect_warning(
    ret <- find.dose.regimen(doses, timeu = "hr"),
    regexp = "Doses appear to be missing after time 48[.]$",
    class = "pknca_warning_tau_irregular_dosing"
  )
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 144, n_doses = 5L, interval = 24, label = "QD",
      source = "nominal", n_intervals_used = 3L, n_missed = 2L,
      note = "missed doses after 48"
    )
  )
  expect_warning(
    expect_equal(find.tau(doses), 24),
    class = "pknca_warning_tau_irregular_dosing"
  )
})

test_that("find.dose.regimen keeps a jittered twice-daily cycle", {
  # Doses at 0 and 10 hours each day for a week, each up to an hour early or
  # late:  the 10 and 14 hour spacings scatter about 12, while the doses stay
  # near their two times of day
  lost <- 0
  for (seed in 1:20) {
    set.seed(seed)
    doses <- c(0, 10) + rep(0:6 * 24, each = 2) + stats::runif(14, -1, 1)
    ret <- find.dose.regimen(doses, timeu = "hr")
    if (!(nrow(ret) == 1 && ret$interval == 24 && length(ret$offsets[[1]]) == 2)) {
      lost <- lost + 1
    }
  }
  expect_lte(lost, 1)
})

test_that("find.dose.regimen rarely reads jittered daily dosing as a cycle", {
  # Daily doses each up to 3 hours early or late, in short histories where a
  # few doses per position can look uneven by chance.  The warnings describe the
  # scatter (and, for the few read as a cycle, its period), so they are muffled
  # while the readings are counted.
  for (n_dose in c(7, 11)) {
    as_cycle <- 0
    for (seed in 1:200) {
      set.seed(seed)
      doses <- 24 * seq_len(n_dose) + stats::runif(n_dose, -3, 3)
      ret <-
        withCallingHandlers(
          find.dose.regimen(doses, timeu = "hr"),
          pknca_warning_tau_irregular_dosing = function(w) invokeRestart("muffleWarning"),
          pknca_warning_tau_regimen_change = function(w) invokeRestart("muffleWarning"),
          pknca_warning_tau_not_nominal = function(w) invokeRestart("muffleWarning")
        )
      if (any(lengths(ret$offsets) > 1)) {
        as_cycle <- as_cycle + 1
      }
    }
    expect_lte(as_cycle, 10)
  }
})

test_that("find.dose.regimen says when the units package is needed to compare", {
  local_mocked_bindings(is_installed = function(...) FALSE, .package = "rlang")
  # A unit other than hours cannot be converted, so the interval is the one in
  # the data, with one message naming the unit
  messages <- testthat::capture_messages(ret <- find.dose.regimen(c(0, 24, 50), timeu = "min"))
  expect_length(messages, 1)
  expect_match(messages, "times in 'min' cannot be compared with the nominal dosing intervals")
  expect_match(messages, "Installing the units package")
  expect_equal(ret$interval, 25)
  expect_equal(ret$source, "auto")
  expect_message(
    tau <- find.tau(c(0, 24, 50), timeu = "day"),
    class = "pknca_message_tau_units_fallback"
  )
  expect_equal(tau, 25)
  # Hours, stated or taken, need no conversion
  expect_no_message(tau_hr <- find.tau(c(0, 24, 50), timeu = "hr"))
  expect_equal(tau_hr, 24)
  expect_no_message(tau_none <- find.tau(c(0, 24, 50)))
  expect_equal(tau_none, 24)
})

test_that("PKNCAdata says once per group when the units package is needed", {
  local_mocked_bindings(is_installed = function(...) FALSE, .package = "rlang")
  doses <- c(0, 24.5, 49, 73, 97.5)
  times <- sort(unique(c(doses, 97.5 + c(0.5, 1, 2, 4, 8, 12, 24, 36, 48))))
  d_conc <- data.frame(subject = rep(1:2, each = length(times)), time = rep(times, 2))
  d_conc$conc <- exp(-0.1 * d_conc$time) + 1
  d_dose <- data.frame(subject = rep(1:2, each = length(doses)), time = rep(doses, 2), dose = 1)
  messages <-
    testthat::capture_messages(
      ret <-
        PKNCAdata(
          PKNCAconc(d_conc, conc~time|subject, timeu = "min"),
          PKNCAdose(d_dose, dose~time|subject)
        )
    )
  fallback <- grep("cannot be compared with the nominal dosing intervals", messages, value = TRUE)
  expect_length(fallback, 2)
  expect_equal(substr(fallback, 1, 11), paste0("subject=", 1:2, ": "))
  # The interval is the median spacing found in the data
  expect_equal(unique(ret$intervals$end), c(122, Inf))
})

test_that("without the units package, the interval found in the data is used, not converted", {
  local_mocked_bindings(is_installed = function(...) FALSE, .package = "rlang")
  # The conversion to hours must not be reached
  local_mocked_bindings(pknca_hours_factor = function(...) stop("the conversion was reached"))
  # Doses 1470 minutes apart:  in hours that would snap to once daily (1440
  # minutes); without units it is the 1470 found in the data
  doses <- c(0, 1470, 2940)
  expect_message(tau <- find.tau(doses, timeu = "min"), class = "pknca_message_tau_units_fallback")
  expect_equal(tau, 1470)
  expect_message(
    ret <- find.dose.regimen(doses, timeu = "zzz"),
    class = "pknca_message_tau_units_fallback"
  )
  expect_equal(ret$interval, 1470)
  expect_equal(ret$source, "auto")
  # Through PKNCAdata(), the interval for the last dose ends one data interval
  # after it
  times <- sort(unique(c(doses, 2940 + c(30, 60, 120, 240, 480, 1470))))
  d_conc <- data.frame(subject = 1, time = times, conc = exp(-0.001 * times) + 1)
  d_dose <- data.frame(subject = 1, time = doses, dose = 1)
  expect_message(
    o_data <-
      PKNCAdata(
        PKNCAconc(d_conc, conc~time|subject, timeu = "min"),
        PKNCAdose(d_dose, dose~time|subject)
      ),
    class = "pknca_message_tau_units_fallback"
  )
  expect_equal(o_data$intervals$start, 2940)
  expect_equal(o_data$intervals$end, 4410)
})
