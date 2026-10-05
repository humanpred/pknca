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
  # Without a unit, the interval is the median spacing
  expect_equal(find.dose.regimen(c(0, 23.6, 48, 72.4, 96))$interval, 24)
  expect_equal(find.dose.regimen(c(0, 23.5, 47, 71.5, 95))$interval, 23.5)
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
  # With no unit there is nothing to match, so there is no warning
  expect_no_warning(ret_no_unit <- find.dose.regimen(seq(0, 150, by = 30)))
  expect_equal(ret_no_unit$source, "auto")
  expect_equal(ret_no_unit$interval, 30)
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
  # A unit that is not a time unit gives no nominal set
  expect_no_warning(ret <- find.dose.regimen(0:6, timeu = "furlong"))
  expect_equal(ret$source, "auto")
  expect_equal(ret$interval, 1)
})

test_that("find.dose.regimen follows a cycle that most of the doses keep", {
  # 08:00 and 16:00 with the dose at 56 hours missed:  no run of spacings forms,
  # and most doses recur 24 hours later
  expect_warning(
    ret <- find.dose.regimen(c(0, 8, 24, 32, 48, 72, 80, 96, 104), timeu = "hr"),
    regexp = "off schedule after times 32, 48[.]$",
    class = "pknca_warning_tau_irregular_dosing"
  )
  expect_equal(
    ret,
    regimen_expected(
      start = 0, end = 104, n_doses = 9L, interval = 24, label = "BID",
      source = "nominal", n_intervals_used = 5L, n_irregular = 2L,
      note = "off schedule after 32, 48", offsets = c(0, 8)
    )
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
  # Doses at 0 and 10 hours for two days hold one complete daily cycle and the
  # start of a second
  expect_false(regimen_cycle_fits(c(0, 10, 24, 34), k = 2, log_tolerance = log1p(0.2), log_snap = log1p(0.1)))
  expect_true(regimen_cycle_fits(c(0, 10, 24, 34, 48), k = 2, log_tolerance = log1p(0.2), log_snap = log1p(0.1)))
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
