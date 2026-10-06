test_that("find.tau", {
  # Regularly spaced intervals give the regular spacing
  expect_equal(
    find.tau(sort(unique(c(seq(0, 168, 12),
                           seq(4, 168, 12)))),
             tau.choices=NA),
    12)
  expect_equal(
    find.tau(sort(unique(c(seq(0, 168, 12),
                           seq(4, 168+12, 12)))),
             tau.choices=NA),
    12)
  expect_equal(find.tau(0:10, tau.choices=NA), 1)
  # It overrides tau.choices if everything is equally spaced, and says that the
  # interval is not one of the choices
  expect_warning(
    tau_hourly <- find.tau(0:10, tau.choices=c(24, 168)),
    class="pknca_warning_tau_not_nominal"
  )
  expect_equal(tau_hourly, 1)
  expect_warning(
    tau_ten <- find.tau(seq(0, 100, by=10), tau.choices=c(24, 168)),
    class="pknca_warning_tau_not_nominal"
  )
  expect_equal(tau_ten, 10)
  expect_equal(find.tau(seq(0, 48, by=24),
                        tau.choices=c(24, 168)), 24)
  # Alternatively spaced intervals give the alternative spacing
  expect_equal(find.tau(c(seq(0, 48, by=24),
                          seq(10, 48, by=24)),
                        tau.choices=c(24, 168)),
               24)
  # Smaller interval spacing adheres to tau.choices with unequal
  # spacing.
  expect_equal(find.tau(c(seq(0, 48, by=12),
                          seq(10, 48, by=12)),
                        tau.choices=c(24, 168)),
               24)
  # It works with more complex spacing and many intervals
  expect_equal(find.tau(
    sort(unique(c(seq(0, 168, by=24),
                  seq(4, 168, by=24),
                  seq(10, 168, by=24)))),
    tau.choices=c(24, 168)),
    24)
  expect_equal(find.tau(c(0, 5, 19, 30) + rep((0:5)*168, each=4),
                        tau.choices=c(24, 168)),
               168)
  # If there is only one dosing time, return 0-- regardless of the
  # option.
  expect_equal(find.tau(rep(5, 5), tau.choices=c(24, 168)), 0)
  expect_equal(find.tau(rep(0, 5), tau.choices=c(24, 168)), 0)
  # If everything is NA, return NA
  expect_equal(find.tau(NA,
                        tau.choices=c(24, 168)),
               NA)
  expect_equal(find.tau(rep(NA, 10),
                        tau.choices=c(24, 168)),
               NA)
  # If there is no sequence, return NA
  expect_equal(find.tau(c(0, 1, 3, 5, 9),
                        tau.choices=c(24, 168)),
               NA)
  expect_equal(find.tau(c(0, 1, 3, 5, 9, 24),
                        tau.choices=NA),
               NA)
})

test_that("find.tau reads a dose off schedule as irregular daily dosing", {
  # A single dose off schedule leaves gaps of 32 and 16 hours among otherwise
  # daily doses.  The daily runs either side of it hold most of the spacings, so
  # the interval is daily and the dose between the two gaps is named.  The 96 hours that the
  # doses span is not an interval:  no two doses are 96 hours apart.
  expect_warning(
    tau <- find.tau(c(0, 24, 48, 80, 96, 120, 144)),
    regexp="Doses are off schedule at time 80[.]$",
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(tau, 24)
  expect_warning(
    tau_choice <- find.tau(c(0, 24, 48, 80, 96, 120, 144), tau.choices=24),
    regexp="Doses are off schedule at time 80[.]$",
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(tau_choice, 24)
  # The same doses, without the one that is off schedule, do repeat
  expect_equal(find.tau(c(0, 24, 48, 72, 96, 120, 144)), 24)
})

test_that("find.tau reports a missed dose rather than the length of the gap", {
  expect_warning(
    tau <- find.tau(c(0, 24, 48, 96, 120, 144)),
    regexp="Doses appear to be missing after time 48",
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(tau, 24)
  # Every gap that is longer than the interval is named.  The gaps here fall
  # after 48 and 168 hours, which is not itself a repeating pattern; doses at
  # 0, 24, 48, 96, 120, 144, 192, 216, and 240 hours are three days on and one
  # day off, and that repeats over 96 hours, so it is reported as the regimen
  # it is rather than as missed doses.
  expect_warning(
    tau_two <- find.tau(c(0, 24, 48, 96, 120, 144, 168, 216)),
    regexp="missing after times 48, 168",
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(tau_two, 24)
  expect_equal(find.tau(c(0, 24, 48, 96, 120, 144, 192, 216, 240)), 96)
  # A gap that is not a whole number of intervals is not a missed dose; the dose
  # that ends it is off schedule, and the schedule continues from it
  expect_warning(
    tau_early <- find.tau(c(0, 24, 48, 60, 84, 108), tau.choices=24),
    regexp="using the most common interval of 24[.] Doses are off schedule at time 60[.]$",
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(tau_early, 24)
})

test_that("find.tau prefers a repeating pattern to a missed dose", {
  # Three times a day with an overnight gap:  the doses repeat daily, and the
  # 12 hour overnight gap is the regimen rather than two doses that were not
  # given.  Reading it as a 6 hour interval with missed doses would put the
  # multiple-dose parameters on the wrong interval.
  expect_equal(find.tau(c(0, 6, 12, 24, 30, 36, 48, 54, 60)), 24)
  # Every four hours during the day, with the same overnight gap
  expect_equal(find.tau(c(0, 4, 8, 24, 28, 32, 48, 52, 56)), 24)
  # Neither gives the irregular-dosing warning, because nothing is missing
  expect_no_warning(find.tau(c(0, 6, 12, 24, 30, 36, 48, 54, 60)))
  expect_no_warning(find.tau(c(0, 4, 8, 24, 28, 32, 48, 52, 56)))
  # Twice a day at 0 and 10 hours, which repeats daily
  expect_equal(find.tau(c(0, 10, 24, 34, 48, 58)), 24)
})

test_that("find.tau sorts and de-duplicates the dose times", {
  # The order the dose times arrive in and a dose recorded twice must not
  # change the interval.
  expect_equal(find.tau(c(48, 24, 0)), 24)
  expect_equal(find.tau(c(0, 0, 24)), 24)
  expect_equal(find.tau(c(48, 0, 24, 24, 0)), 24)
  expect_equal(find.tau(c(144, 0, 24, 48, 72, 96, 120)), 24)
})

test_that("find.tau matches times within a tolerance", {
  # Dosing three times a day with time in days:  the spacings differ in the
  # last bits, so exact comparison gave no interval at all.
  expect_equal(find.tau(seq(0, 2, by=1/3)), 1/3)
  expect_equal(find.tau(c(0, 1/3, 2/3, 1)), 1/3)
  # Dosing every twenty minutes with time in hours
  expect_equal(find.tau((0:5)*20/60), 20/60)
  expect_equal(find.tau(seq(0, 0.5, by=0.1)), 0.1)
  # Twice daily in days, where the interval repeats but no two doses are a day
  # apart
  expect_equal(find.tau(c(0, 1/3, 1, 4/3, 2, 7/3), tau.choices=1), 1)
})

test_that("find.tau handles two doses and no doses", {
  # Two doses give the spacing between them
  expect_equal(find.tau(c(0, 24)), 24)
  expect_equal(find.tau(c(0, 336)), 336)
  expect_equal(find.tau(c(336, 0)), 336)
  # No doses at all is not an error
  expect_equal(find.tau(numeric(0)), NA)
  expect_equal(find.tau(c(NA, NA)), NA)
})

test_that("find.tau uses tau.choices from the options", {
  # Twice-daily dosing for five days repeats every 24 hours, and also every 48;
  # naming 48 as the only choice selects it, which is how the option reaches
  # find.tau() from PKNCAdata(options=).
  doses <- c(0, 10, 24, 34, 48, 58, 72, 82, 96, 106)
  expect_equal(find.tau(doses), 24)
  expect_equal(find.tau(doses, tau.choices=48), 48)
  expect_equal(find.tau(doses, options=list(tau.choices=48)), 48)
  # An explicit argument wins over the option
  expect_equal(find.tau(doses, options=list(tau.choices=48), tau.choices=24), 24)
})

test_that("choose.auc.intervals checks its inputs", {
  expect_error(choose.auc.intervals(NA, 1),
               regexp="time.conc may not have any NA values",
               class="pknca_error_timeconc_na")
  expect_error(choose.auc.intervals(1, NA),
               regexp="time.dosing may not have any NA values",
               class="pknca_error_timedosing_na")
  # The single-dose table is validated while the option is resolved
  expect_error(choose.auc.intervals(1, 1, single.dose.aucs=data.frame()),
               regexp="interval specification has no rows")
  expect_error(choose.auc.intervals(c(0, 1), 0, route="subcutaneous"),
               regexp="'arg' should be one of")
})

test_that("choose.auc.intervals gives no intervals when a group has no doses", {
  # A concentration group with no dose rows used to abort in seq_len(-1)
  expect_warning(
    ret <- choose.auc.intervals(c(0, 1, 2), numeric(0)),
    regexp="No dose times are available",
    class="pknca_warning_no_dose_times_for_group"
  )
  expect_equal(nrow(ret), 0)
  expect_true(all(c("start", "end") %in% names(ret)))
  expect_warning(
    ret_null <- choose.auc.intervals(c(0, 1, 2), NULL),
    class="pknca_warning_no_dose_times_for_group"
  )
  expect_equal(nrow(ret_null), 0)
})

test_that("choose.auc.intervals requires a sample after the dose", {
  # Nothing can be calculated from samples that all precede the dose, so the
  # single-dose branch gives no intervals just as the multiple-dose branch does
  expect_equal(nrow(choose.auc.intervals(c(-2, -1), 0)), 0)
  expect_equal(nrow(choose.auc.intervals(-2, 0)), 0)
  expect_equal(nrow(choose.auc.intervals(c(-2, -1), c(0, 24))), 0)
  # A sample at the dose time is not a sample after it
  expect_equal(nrow(choose.auc.intervals(c(-1, 0), 0)), 0)
})

test_that("choose.auc.intervals builds the single-dose interval from the builder", {
  # The interval is the whole profile rather than a hard-coded 24 hour window
  expect_equal(
    choose.auc.intervals(c(0, 1, 2, 4, 8, 24, 48), 0),
    pknca_interval_table(0, Inf, dosing="single")
  )
  # The dose time offsets it
  expect_equal(
    choose.auc.intervals(c(5, 6, 7, 9, 13, 29), 5),
    pknca_interval_table(5, Inf, dosing="single")
  )
  # Time in days rather than hours no longer forces a 24 day interval
  expect_equal(
    choose.auc.intervals(c(0, 0.25, 0.5, 1, 2, 7), 0),
    pknca_interval_table(0, Inf, dosing="single")
  )
  # The route comes through to the parameters:  a bolus is back-extrapolated
  # c0 is split onto its own row because it must not come from the imputed
  # concentration at the start of the interval
  expect_true(any(choose.auc.intervals(c(0, 1, 2, 4, 8, 24), 0, route="iv_bolus")$c0))
  expect_false(any(choose.auc.intervals(c(0, 1, 2, 4, 8, 24), 0, route="extravascular")$c0))
  # A sparse design imputes nothing
  expect_false(
    "impute" %in% names(choose.auc.intervals(c(0, 1, 2, 4, 8, 24), 0, sparse=TRUE))
  )
})

test_that("auto.interval.method chooses the parameter lists", {
  # "legacy" gives the parameter lists PKNCA used before pknca_interval_table()
  # was available, which is the documented way back to them.
  legacy <- list(auto.interval.method="legacy")
  expect_equal(
    choose.auc.intervals(c(0, 1, 2, 4, 8, 24, 48), 0, options=legacy),
    check.interval.specification(PKNCA.options("single.dose.aucs"))
  )
  # The single-dose table is offset by the dose time
  expect_equal(
    choose.auc.intervals(c(5, 6, 7, 9, 13, 29), 5, options=legacy)$end,
    c(29, Inf)
  )
  # A user-supplied single.dose.aucs is used under "legacy"
  tmp_single_dose_auc <-
    check.interval.specification(
      data.frame(start=0,
                 end=c(12, Inf),
                 auclast=c(TRUE, FALSE),
                 aucinf.obs=c(FALSE, TRUE),
                 half.life=c(FALSE, TRUE)))
  expect_equal(
    choose.auc.intervals(c(1, 2, 3), 1,
                         single.dose.aucs=tmp_single_dose_auc, options=legacy),
    check.interval.specification(
      data.frame(start=1,
                 end=c(13, Inf),
                 auclast=c(TRUE, FALSE),
                 aucinf.obs=c(FALSE, TRUE),
                 half.life=c(FALSE, TRUE)))
  )
  # Multiple-dose intervals get AUClast, Cmax, and Tmax under "legacy"
  dense <- c(0, 0.5, 1, 2, 4, 8, 12, 24)
  conc <- sort(unique(c(dense, 48, 72, 96, 120, 144 + dense, 144 + c(48, 72, 96))))
  ret_legacy <- choose.auc.intervals(conc, seq(0, 144, by=24), options=legacy)
  expect_equal(ret_legacy$start, c(0, 144, 144))
  expect_equal(ret_legacy$end, c(24, 168, Inf))
  expect_equal(ret_legacy$auclast, c(TRUE, TRUE, FALSE))
  expect_equal(ret_legacy$cmax, c(TRUE, TRUE, FALSE))
  expect_equal(ret_legacy$tmax, c(TRUE, TRUE, FALSE))
  expect_equal(ret_legacy$half.life, c(FALSE, FALSE, TRUE))
  expect_false("aucint.last" %in% names(ret_legacy)[vapply(ret_legacy, isTRUE, TRUE)])
  # "builder" is the default and is unaffected by single.dose.aucs being set to
  # the value the package ships with
  expect_equal(
    choose.auc.intervals(c(0, 1, 2, 4, 8, 24, 48), 0,
                         single.dose.aucs=PKNCA.options("single.dose.aucs")),
    pknca_interval_table(0, Inf, dosing="single")
  )
  expect_equal(
    choose.auc.intervals(c(0, 1, 2, 4, 8, 24, 48), 0,
                         options=list(auto.interval.method="builder")),
    pknca_interval_table(0, Inf, dosing="single")
  )
})

test_that("auto.interval.method is a documented option", {
  expect_equal(PKNCA.options("auto.interval.method"), "builder")
  expect_true(grepl("legacy", PKNCA.options.describe("auto.interval.method")))
  expect_error(PKNCA.options(auto.interval.method="nope"))
  expect_error(PKNCA.options(auto.interval.method=1))
})

test_that("choose.auc.intervals finds the intervals between doses", {
  # The interval boundaries are unchanged from before the parameters came from
  # pknca_interval_table(); the parameters within them are not, so these pin
  # the boundaries and one parameter set is checked in full below.
  bounds <- function(...) {
    ret <- choose.auc.intervals(...)
    data.frame(start=ret$start, end=ret$end)
  }
  # Two doses with samples at both and one between
  expect_equal(bounds(c(1, 2, 3), c(1, 3)), data.frame(start=1, end=3))
  # A sample after the second dose adds its dosing interval
  expect_equal(bounds(1:5, c(1, 3)), data.frame(start=c(1, 3), end=c(3, 5)))
  # Samples beyond the last dosing interval add the half-life
  expect_equal(
    bounds(1:6, c(1, 3)),
    data.frame(start=c(1, 3, 3), end=c(3, 5, Inf))
  )
  # Doses with no samples between them are skipped
  expect_equal(bounds(1:6, c(1, 3, 5, 7, 9)), data.frame(start=c(1, 3), end=c(3, 5)))
  expect_equal(
    bounds(c(1, 2, 3, 5, 6, 7), c(1, 3, 5, 7, 9)),
    data.frame(start=c(1, 5), end=c(3, 7))
  )
  # Dose times that repeat or arrive out of order give the same intervals
  expect_equal(
    bounds(c(0, 4, 24, 28, 48, 72), c(24, 0, 0)),
    bounds(c(0, 4, 24, 28, 48, 72), c(0, 24))
  )
  expect_equal(
    bounds(c(0, 4, 24, 28, 48, 72), c(24, 0, 0)),
    data.frame(start=c(0, 24, 24), end=c(24, 48, Inf))
  )
})

test_that("choose.auc.intervals gives the parameters for each kind of interval", {
  # A dosing interval is built on the AUCint family, the last dose is at steady
  # state, and the terminal interval is the half-life alone.
  conc <- sort(unique(c(c(0, 0.5, 1, 2, 4, 8, 12, 24), 48, 72, 96, 120,
                        144 + c(0, 0.5, 1, 2, 4, 8, 12, 24), 144 + c(48, 72, 96))))
  ret <- choose.auc.intervals(conc, seq(0, 144, by=24))
  expect_equal(ret$start, c(0, 144, 144))
  expect_equal(ret$end, c(24, 168, Inf))
  expect_equal(ret$impute, c("start_cmin", "start_predose", NA_character_))
  expect_equal(ret$aucint.last, c(TRUE, TRUE, FALSE))
  expect_equal(ret$auclast, c(FALSE, FALSE, FALSE))
  expect_equal(ret$half.life, c(TRUE, TRUE, TRUE))
  expect_equal(ret$cmax, c(TRUE, TRUE, FALSE))
  expect_equal(ret$ctrough, c(TRUE, TRUE, FALSE))
  # The first two rows are what the builder gives for those contexts
  expect_equal(
    ret[1, , drop=FALSE],
    pknca_interval_table(0, 24, dosing="multiple"),
    ignore_attr="row.names"
  )
  expect_equal(
    ret[2, , drop=FALSE],
    pknca_interval_table(144, 168, dosing="steady_state"),
    ignore_attr="row.names"
  )
})

test_that("choose.auc.intervals matches sample times within a tolerance", {
  doses <- seq(0, 144, by=24)
  dense <- c(0, 0.5, 1, 2, 4, 8, 12, 24)
  # A trough drawn at 167.5 rather than 168 still ends the dosing interval;
  # exact matching dropped the interval entirely.
  conc_early_trough <-
    sort(unique(c(dense, 48, 72, 96, 120,
                  144 + c(0, 0.5, 1, 2, 4, 8, 12, 23.5), 144 + c(48, 72, 96))))
  ret <- choose.auc.intervals(conc_early_trough, doses)
  expect_equal(ret$start, c(0, 144, 144))
  expect_equal(ret$end, c(24, 168, Inf))
  # A predose sample drawn slightly before the dose still starts the interval
  ret_predose <- choose.auc.intervals(c(-0.05, 2, 23.95, 26, 47.95, 50, 72, 100), c(0, 24, 48))
  expect_equal(ret_predose$start, c(0, 24, 48, 48))
  expect_equal(ret_predose$end, c(24, 48, 72, Inf))
  # Outside the window the sample no longer bounds the interval
  expect_equal(
    nrow(choose.auc.intervals(c(-5, 2, 19, 26, 43, 50, 72, 100), c(0, 24, 48))),
    2
  )
  # The window is the auto.interval.tolerance option as a fraction of tau
  expect_equal(
    choose.auc.intervals(conc_early_trough, doses,
                         options=list(auto.interval.tolerance=0.001))$end,
    c(24, Inf)
  )
})

test_that("choose.auc.intervals handles non-integer dosing times", {
  # Dosing three times a day with time in days, sampled every four hours
  ret <- choose.auc.intervals(sort(unique(round(seq(0, 3, by=1/6), 10))), seq(0, 2, by=1/3))
  expect_equal(ret$start, c(0, 1/3, 2/3, 1, 4/3, 5/3, 2, 2))
  expect_equal(ret$end, c(1/3, 2/3, 1, 4/3, 5/3, 2, 7/3, Inf))
  # Dosing every twenty minutes with time in hours
  ret_minutes <- choose.auc.intervals((0:11)*10/60, (0:3)*20/60)
  expect_equal(ret_minutes$start, c(0, 20, 40, 60, 60)/60)
  expect_equal(ret_minutes$end, c(20/60, 40/60, 60/60, 80/60, Inf))
})

test_that("choose.auc.intervals gives each dose an interval across a washout", {
  # Two treatment periods in one group:  a dose, a profile, a long washout, and
  # the next period.  One AUClast across the washout describes neither period.
  dense <- c(0, 0.5, 1, 2, 4, 8, 12, 24)
  ret <- choose.auc.intervals(sort(c(dense, 48, 72, 336 + dense, 336 + c(48, 72))), c(0, 336))
  expect_equal(ret$start, c(0, 336))
  expect_equal(ret$end, c(336, Inf))
  # Each is a single-dose profile, not a dosing interval
  expect_equal(ret$auclast, c(TRUE, TRUE))
  expect_equal(ret$aucinf.obs, c(TRUE, TRUE))
  expect_equal(ret$aucint.last, c(FALSE, FALSE))
  expect_equal(ret$half.life, c(TRUE, TRUE))
  # When the samples do run up to the next dose it is a dosing interval again
  ret_dosing <-
    choose.auc.intervals(
      sort(unique(c(seq(0, 336, by=24), 336 + dense))),
      c(0, 336)
    )
  expect_equal(ret_dosing$aucint.last, c(TRUE, FALSE))
  expect_equal(ret_dosing$start, c(0, 336))
  expect_equal(ret_dosing$end, c(336, Inf))
})

test_that("choose.auc.intervals reports irregular dosing while still choosing intervals", {
  dense <- c(0, 0.5, 1, 2, 4, 8, 12, 24)
  conc <- sort(unique(c(0, 24, 48, 96, 120, 144 + dense, 144 + c(48, 72))))
  expect_warning(
    ret <- choose.auc.intervals(conc, c(0, 24, 48, 96, 120, 144)),
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(ret$start, c(144, 144))
  expect_equal(ret$end, c(168, Inf))
  # A dose off schedule among daily doses still gives the daily tau, so the last
  # dose is anchored on it
  doses_gap <- c(0, 24, 48, 80, 96, 120, 144)
  expect_warning(
    ret_gap <- choose.auc.intervals(sort(unique(c(doses_gap, 144 + dense, 192, 216))), doses_gap),
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(ret_gap$start, c(144, 144))
  expect_equal(ret_gap$end, c(168, Inf))
  # Two spacings, one twice the other, give no tau, so no interval is anchored
  # on the last dose
  doses_none <- c(0, 24, 72)
  conc_none <- sort(unique(c(doses_none, 72 + dense, 120, 144)))
  expect_warning(
    ret_none <- choose.auc.intervals(conc_none, doses_none),
    class="pknca_warning_no_tau_for_intervals"
  )
  expect_equal(ret_none$start, 72)
  expect_equal(ret_none$end, Inf)
  # Dropping the steady-state interval is reported, with its own class so that
  # it is not confused with resolve_dose_tau()'s warning
  expect_warning(
    choose.auc.intervals(conc_none, doses_none),
    regexp="dosing interval could not be determined",
    class="pknca_warning_no_tau_for_intervals"
  )
})

test_that("choose.auc.intervals uses tau.choices from the options", {
  # The option reaches find.tau(), which sets the last dose's interval.  Twice
  # daily at 0 and 10 hours repeats every 24 hours, and also every 48, so
  # naming 48 selects the longer one.
  doses <- c(0, 10, 24, 34, 48, 58, 72, 82, 96, 106)
  conc <- sort(unique(c(doses, 96 + c(1, 2, 4, 8, 12, 24, 36, 48, 72))))
  # The first row is the dosing interval between the two doses of the last
  # cycle; the second is the cycle itself, which the option moves.
  expect_equal(choose.auc.intervals(conc, doses)$end, c(106, 120, Inf))
  expect_equal(
    choose.auc.intervals(conc, doses, options=list(tau.choices=48))$end,
    c(106, 144, Inf)
  )
})

test_that("choose.auc.intervals gives the last dose a whole dosing cycle", {
  # Twice-daily dosing that stops at 106 hours has its last complete cycle
  # running from 96 to 120 hours.  An interval from 106 to 130 would span one
  # tau but would contain the dose at 120 that was never recorded.
  doses <- c(0, 10, 24, 34, 48, 58, 72, 82, 96, 106)
  conc <- sort(unique(c(doses, 96 + c(1, 2, 4, 8, 12, 24, 36, 48, 72))))
  ret <- choose.auc.intervals(conc, doses)
  # The 10 hour span between the last two doses is a dosing interval in its own
  # right; the cycle it belongs to runs from 96 to 120.
  expect_equal(ret$start, c(96, 96, 106))
  expect_equal(ret$end, c(106, 120, Inf))
  # One dose per interval already starts the cycle at the last dose
  dense <- c(0, 0.5, 1, 2, 4, 8, 12, 24)
  ret_qd <-
    choose.auc.intervals(
      sort(unique(c(dense, 48, 72, 96, 120, 144 + dense, 144 + c(48, 72)))),
      seq(0, 144, by=24)
    )
  expect_equal(ret_qd$start, c(0, 144, 144))
})

test_that("choose.auc.intervals gives the last dose a profile when tau ends nothing", {
  # Daily doses, then samples that stop before the next dose would have been
  # given, so no dosing interval and no terminal phase beyond one:  the dose
  # still has a profile worth calculating.
  ret <- choose.auc.intervals(c(0, 24, 48, 49, 50, 52, 56, 60), c(0, 24, 48))
  expect_equal(ret$start, 48)
  expect_equal(ret$end, Inf)
  expect_true(ret$auclast)
  expect_true(ret$aucinf.obs)
})

test_that("PKNCAdata generates intervals for the groups that have doses", {
  # A concentration group with no dose rows used to abort the whole call
  d_conc <-
    data.frame(
      id=rep(1:2, each=5),
      time=rep(c(0, 1, 2, 4, 8), 2),
      conc=c(0, 5, 4, 2, 1, 0, 6, 5, 3, 1)
    )
  d_dose <- data.frame(id=1, time=0, dose=1)
  expect_warning(
    expect_warning(
      ret <-
        PKNCAdata(
          PKNCAconc(d_conc, conc~time|id),
          PKNCAdose(d_dose, dose~time|id)
        ),
      class="pknca_warning_no_dose_times_for_group"
    ),
    class="pknca_warning_no_intervals_limited_data"
  )
  expect_equal(ret$intervals$id, 1)
  expect_equal(ret$intervals$start, 0)
  expect_equal(ret$intervals$end, Inf)
})

test_that("PKNCAdata passes the dosing route into the generated intervals", {
  d_conc <- data.frame(time=c(0, 1, 2, 4, 8, 24), conc=c(0, 5, 4, 3, 2, 1))
  d_dose <- data.frame(time=0, dose=1, rt="intravascular", dur=0)
  ret <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time),
      PKNCAdose(d_dose, dose~time, route="rt", duration="dur")
    )
  # A bolus is back-extrapolated to C0; extravascular dosing is not
  expect_true(any(ret$intervals$c0))
  d_dose_ev <- data.frame(time=0, dose=1)
  ret_ev <-
    PKNCAdata(PKNCAconc(d_conc, conc~time), PKNCAdose(d_dose_ev, dose~time))
  expect_false(any(ret_ev$intervals$c0))
})

test_that("auto.interval.tolerance is a documented option", {
  expect_equal(PKNCA.options("auto.interval.tolerance"), 0.05)
  expect_true(grepl("boundary", PKNCA.options.describe("auto.interval.tolerance")))
  expect_error(
    PKNCA.options(auto.interval.tolerance=-1),
    regexp="auto.interval.tolerance"
  )
  expect_error(
    PKNCA.options(auto.interval.tolerance=2),
    regexp="auto.interval.tolerance"
  )
})

test_that("resolve_dose_tau prefers the interval column over detection", {
  # The interval column wins even when the dose times say otherwise, because
  # only the user knows the regimen when the data hold one dose per profile.
  expect_equal(
    resolve_dose_tau(interval=data.frame(start=0, end=24, tau=12), time.dose=c(0, 24, 48)),
    12
  )
  expect_equal(
    resolve_dose_tau(interval=data.frame(start=0, end=24, tau=24), time.dose=0),
    24
  )
})

test_that("resolve_dose_tau detects tau from repeated dose times", {
  expect_equal(
    resolve_dose_tau(interval=data.frame(start=96, end=120), time.dose=c(0, 24, 48, 72, 96)),
    24
  )
  # An NA tau column falls through to detection
  expect_equal(
    resolve_dose_tau(interval=data.frame(start=0, end=12, tau=NA_real_), time.dose=c(0, 12, 24)),
    12
  )
  # Dose times that repeat or arrive out of order are still detected
  expect_equal(
    resolve_dose_tau(interval=data.frame(start=24, end=48), time.dose=c(0, 0, 24, 48)),
    24
  )
  expect_equal(
    resolve_dose_tau(interval=data.frame(start=24, end=48), time.dose=c(48, 24, 0)),
    24
  )
  # Time in days, where exact comparison gave no tau at all
  expect_equal(
    resolve_dose_tau(interval=data.frame(start=2, end=7/3), time.dose=seq(0, 2, by=1/3)),
    1/3
  )
})

test_that("resolve_dose_tau warns about a tau that spans a missed dose", {
  # The gap reads as a missed dose, so the interval is still the daily one and
  # the multiple-dose parameters are calculated from it with a warning
  expect_warning(
    tau <- resolve_dose_tau(interval=data.frame(start=144, end=168),
                            time.dose=c(0, 24, 48, 96, 120, 144)),
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(tau, 24)
})

test_that("resolve_dose_tau gives NA with a warning when tau is undetermined", {
  # find.tau() reports 0 for a single dose time; that is not a dosing interval
  expect_warning(
    single_dose <- resolve_dose_tau(interval=data.frame(start=0, end=24), time.dose=0),
    regexp="Cannot determine tau from the dose times",
    class="pknca_warning_tau_undetermined"
  )
  expect_equal(single_dose, NA_real_)
  expect_warning(
    no_dose <- resolve_dose_tau(interval=data.frame(start=0, end=24), time.dose=NA_real_),
    class="pknca_warning_tau_undetermined"
  )
  expect_equal(no_dose, NA_real_)
  # Unequally-spaced doses with no repeating interval
  expect_warning(
    irregular <- resolve_dose_tau(interval=data.frame(start=0, end=24), time.dose=c(0, 5, 17)),
    class="pknca_warning_tau_undetermined"
  )
  expect_equal(irregular, NA_real_)
  # A dose off schedule among daily doses gives the daily interval with a
  # warning, rather than the length of the whole dosing period
  expect_warning(
    off_schedule <-
      resolve_dose_tau(interval=data.frame(start=144, end=168),
                       time.dose=c(0, 24, 48, 80, 96, 120, 144)),
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(off_schedule, 24)
})

test_that("resolve_dose_tau rejects an invalid tau column", {
  # A given tau is validated rather than quietly detected around
  expect_error(
    resolve_dose_tau(interval=data.frame(start=0, end=24, tau=0), time.dose=c(0, 24)),
    regexp="is not > 0",
    class="pknca_error_numeric_between"
  )
  expect_error(
    resolve_dose_tau(interval=data.frame(start=0, end=24, tau=-1), time.dose=c(0, 24)),
    regexp="is not > 0",
    class="pknca_error_numeric_between"
  )
  expect_error(
    resolve_dose_tau(interval=data.frame(start=0, end=24, tau=Inf), time.dose=c(0, 24)),
    regexp="Must be finite"
  )
})

test_that("dose_route_for_intervals maps the recorded route to the parameter route", {
  expect_equal(dose_route_for_intervals(), "extravascular")
  expect_equal(dose_route_for_intervals(NULL, NULL), "extravascular")
  expect_equal(dose_route_for_intervals(character(0)), "extravascular")
  expect_equal(dose_route_for_intervals(NA_character_), "extravascular")
  expect_equal(dose_route_for_intervals("extravascular"), "extravascular")
  # A dose given into a vein with no duration is a bolus, which is the
  # documented default in PKNCAdose()
  expect_equal(dose_route_for_intervals("intravascular"), "iv_bolus")
  expect_equal(dose_route_for_intervals("intravascular", 0), "iv_bolus")
  expect_equal(dose_route_for_intervals("intravascular", NA_real_), "iv_bolus")
  expect_equal(dose_route_for_intervals("intravascular", 2), "iv_infusion")
  # Case and a group giving more than one route
  expect_equal(dose_route_for_intervals("Intravascular", 0), "iv_bolus")
  expect_warning(
    mixed <- dose_route_for_intervals(c("intravascular", "extravascular"), c(0, 0)),
    regexp="More than one dosing route",
    class="pknca_warning_multiple_dose_routes"
  )
  expect_equal(mixed, "iv_bolus")
})

test_that("choose.auc.intervals needs a sample at or before each boundary", {
  # Every two weeks, with the profile starting at the Cmax sample and no
  # predose sample.  A sample 4 hours after the dose is not the sample at the
  # dose, even though it falls inside a window that is 5% of 336 hours.
  ret_no_predose <-
    choose.auc.intervals(c(4, 8, 24, 48, 72, 336 + c(4, 8, 24, 48)), c(0, 336))
  expect_equal(ret_no_predose$start, 336)
  expect_equal(ret_no_predose$end, Inf)
  # The same design with a predose sample does get the first dose's interval
  ret_predose <-
    choose.auc.intervals(c(0, 4, 8, 24, 48, 72, 336 + c(0, 4, 8, 24, 48)), c(0, 336))
  expect_equal(ret_predose$start, c(0, 336))
  expect_equal(ret_predose$end, c(336, Inf))
  # Daily dosing whose first sample is an hour after the dose, with no predose
  # sample anywhere
  expect_equal(
    nrow(choose.auc.intervals(c(1, 2, 4, 8, 12, 25, 26, 28, 48), c(0, 24, 48))),
    0
  )
  # A trough drawn after the next dose is contaminated by it, so it does not
  # end the interval; one drawn a little early does
  dense <- c(0, 0.5, 1, 2, 4, 8, 12)
  doses <- seq(0, 144, by=24)
  conc_late <- sort(unique(c(dense, 24, 48, 72, 96, 120, 144 + dense, 168.05, 192)))
  ret_late <- choose.auc.intervals(conc_late, doses)
  expect_equal(ret_late$start, c(0, 144))
  expect_equal(ret_late$end, c(24, Inf))
  conc_early <- sort(unique(c(dense, 24, 48, 72, 96, 120, 144 + dense, 167.5, 192)))
  ret_early <- choose.auc.intervals(conc_early, doses)
  expect_equal(ret_early$start, c(0, 144, 144))
  expect_equal(ret_early$end, c(24, 168, Inf))
  # A predose sample drawn at -0.05 hours starts the interval at the dose
  ret_predose_early <-
    choose.auc.intervals(c(-0.05, 2, 23.95, 26, 47.95, 50, 72, 100), c(0, 24, 48))
  expect_equal(ret_predose_early$start, c(0, 24, 48, 48))
  expect_equal(ret_predose_early$end, c(24, 48, 72, Inf))
})

test_that("choose.auc.intervals reads a long empty stretch as a washout", {
  dense <- c(0, 0.5, 1, 2, 4, 8, 12, 24)
  # A steady-state profile whose last sample before the trough is at 8 hours is
  # still a dosing interval; two thirds of the interval with no samples in it
  # is ordinary for a daily regimen.
  conc_sparse <- sort(unique(c(outer(seq(0, 96, by=24), c(0, 1, 2, 4, 8), FUN="+"), 120, 144)))
  ret_sparse <- choose.auc.intervals(conc_sparse, seq(0, 96, by=24))
  expect_equal(ret_sparse$start, c(0, 24, 48, 72, 96, 96))
  expect_equal(ret_sparse$end, c(24, 48, 72, 96, 120, Inf))
  expect_equal(ret_sparse$aucint.last, c(rep(TRUE, 5), FALSE))
  # The last sample at exactly half the interval
  ret_half <-
    choose.auc.intervals(sort(unique(c(0, 1, 2, 4, 8, 12, 24, 25, 26, 28, 36, 48, 72))), c(0, 24, 48))
  expect_true(ret_half$aucint.last[1])
  # Twice daily with the last sample at 6 hours of a 12 hour interval
  ret_bid <-
    choose.auc.intervals(sort(unique(c(0, 1, 2, 4, 6, 12, 13, 14, 16, 18, 24, 36))), c(0, 12, 24))
  expect_true(ret_bid$aucint.last[1])
  # Two treatment periods, where nearly four fifths of the span is empty
  ret_washout <-
    choose.auc.intervals(sort(c(dense, 48, 72, 336 + dense, 336 + c(48, 72))), c(0, 336))
  expect_equal(ret_washout$auclast, c(TRUE, TRUE))
  expect_equal(ret_washout$aucint.last, c(FALSE, FALSE))
})

test_that("find.tau matches at the edges of its tolerance", {
  # Spacings that differ only in the last bits are the same spacing
  spacing <- 1/3
  doses <- c(0, spacing, 2*spacing, 3*spacing, 4*spacing)
  expect_equal(find.tau(doses), spacing)
  expect_equal(find.tau(cumsum(c(0, rep(spacing, 4)))), spacing)
  # A spacing half an hour long is scatter within the tolerance, and the
  # interval is the median spacing
  nudged <- c(0, 24, 48, 72.5, 96.5)
  expect_no_warning(tau_nudged <- find.tau(nudged))
  expect_equal(tau_nudged, 24)
  # A difference within the tolerance is not
  eps <- sqrt(.Machine$double.eps)
  expect_equal(find.tau(c(0, 24, 48 + 24*eps/2, 72)), 24)
  # Large times, where the representable spacing is coarser
  expect_equal(find.tau(c(0, 1e6, 2e6, 3e6)), 1e6)
  # Very small times
  expect_equal(find.tau(c(0, 1e-6, 2e-6, 3e-6)), 1e-6)
})

test_that("find.tau gives no interval for a missed dose in a short history", {
  # Two spacings, one of them twice the other, is not enough to say that a dose
  # was missed rather than that the regimen changed
  expect_equal(find.tau(c(0, 24, 72)), NA)
  expect_warning(
    tau <- resolve_dose_tau(interval=data.frame(start=48, end=72), time.dose=c(0, 24, 72)),
    class="pknca_warning_tau_undetermined"
  )
  expect_equal(tau, NA_real_)
  # Seeing the interval twice in a row is what makes the longer gap read as a
  # missed dose rather than a different regimen
  expect_warning(
    tau_ok <- resolve_dose_tau(interval=data.frame(start=48, end=72),
                               time.dose=c(0, 24, 48, 96)),
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(tau_ok, 24)
})

test_that("choose.auc.intervals handles a sparse design", {
  ret <- choose.auc.intervals(c(0, 1, 2, 4, 8, 24), 0, sparse=TRUE)
  expect_equal(ret$start, 0)
  expect_equal(ret$end, Inf)
  # A sparse design imputes nothing, so there is no impute column at all
  expect_false("impute" %in% names(ret))
  expect_equal(ret, pknca_interval_table(0, Inf, dosing="single", sparse=TRUE))
  # The dense version of the same design does impute
  expect_true("impute" %in% names(choose.auc.intervals(c(0, 1, 2, 4, 8, 24), 0)))
})

test_that("PKNCAdata passes an infusion route and sparseness into the intervals", {
  d_conc <- data.frame(time=c(0, 1, 2, 4, 8, 24), conc=c(0, 5, 4, 3, 2, 1))
  d_dose_inf <- data.frame(time=0, dose=1, rt="intravascular", dur=2)
  ret_inf <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time),
      PKNCAdose(d_dose_inf, dose~time, route="rt", duration="dur")
    )
  # An infusion is not back-extrapolated to C0, but a bolus is
  expect_false(any(ret_inf$intervals$c0))
  d_dose_bolus <- data.frame(time=0, dose=1, rt="intravascular", dur=0)
  ret_bolus <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time),
      PKNCAdose(d_dose_bolus, dose~time, route="rt", duration="dur")
    )
  expect_true(any(ret_bolus$intervals$c0))
  # A sparse design imputes nothing
  d_conc_sparse <-
    data.frame(
      id=rep(1:3, each=6),
      time=rep(c(0, 1, 2, 4, 8, 24), 3),
      conc=c(0, 5, 4, 3, 2, 1, 0, 6, 5, 3, 2, 1, 0, 4, 4, 2, 1, 0.5)
    )
  d_dose_sparse <- data.frame(id=1:3, time=0, dose=1)
  ret_sparse <-
    PKNCAdata(
      PKNCAconc(d_conc_sparse, conc~time|id, sparse=TRUE),
      PKNCAdose(d_dose_sparse, dose~time|id)
    )
  expect_false("impute" %in% names(ret_sparse$intervals))
})

test_that("a two-day twice-daily regimen gives the intervals it should", {
  # Doses at 0, 12, 24, and 36 hours with a profile on the first and last
  # interval and troughs between
  doses <- c(0, 12, 24, 36)
  conc <-
    sort(unique(c(
      c(0, 0.5, 1, 2, 4, 8, 12),
      24, 36,
      36 + c(0, 0.5, 1, 2, 4, 8, 12),
      36 + c(24, 36)
    )))
  ret <- choose.auc.intervals(conc, doses)
  expect_equal(ret$start, c(0, 36, 36))
  expect_equal(ret$end, c(12, 48, Inf))
  # The first interval is a dosing interval, the last is at steady state, and
  # the terminal phase gives the half-life
  expect_equal(ret$aucint.last, c(TRUE, TRUE, FALSE))
  expect_equal(ret$impute, c("start_cmin", "start_predose", NA_character_))
  expect_equal(ret$half.life, c(TRUE, TRUE, TRUE))
  # The 12 to 24 and 24 to 36 intervals have no samples between their doses
  expect_false(any(ret$start %in% c(12, 24)))
})

test_that("choose.auc.intervals matches tau to the nominal intervals for its time unit", {
  # Daily doses recorded up to half an hour late:  the median spacing is 24.5
  # hours, and with the unit known it snaps to the daily interval
  doses <- c(0, 24.5, 49, 73, 97.5)
  conc <- sort(unique(c(doses, 97.5 + c(0.5, 1, 2, 4, 8, 12, 24, 36, 48))))
  expect_equal(choose.auc.intervals(conc, doses)$end, c(122, Inf))
  expect_equal(choose.auc.intervals(conc, doses, timeu = "hr")$end, c(121.5, Inf))
  # Dosing every hour matches no nominal interval, which is said only when the
  # unit is known
  doses_hourly <- 0:5
  conc_hourly <- sort(unique(c(doses_hourly, 5 + c(0.25, 0.5, 1, 2, 4))))
  expect_no_warning(ret_hourly <- choose.auc.intervals(conc_hourly, doses_hourly))
  expect_warning(
    ret_hourly_unit <- choose.auc.intervals(conc_hourly, doses_hourly, timeu = "hr"),
    class = "pknca_warning_tau_not_nominal"
  )
  expect_equal(ret_hourly_unit$start, ret_hourly$start)
  expect_equal(ret_hourly_unit$end, ret_hourly$end)
})

test_that("resolve_dose_tau matches tau to the nominal intervals for its time unit", {
  doses <- c(0, 24.5, 49, 73, 97.5)
  interval <- data.frame(start = 97.5, end = 121.5)
  expect_equal(resolve_dose_tau(interval = interval, time.dose = doses), 24.5)
  expect_equal(resolve_dose_tau(interval = interval, time.dose = doses, timeu = "hr"), 24)
})

test_that("pknca_group_timeu finds the time unit of a group", {
  d_conc <- data.frame(subject = rep(1:2, each = 3), time = rep(0:2, 2), conc = 1, tu = "hr")
  # A unit given as a value applies to every group
  o_value <- PKNCAconc(d_conc, conc~time|subject, timeu = "hr")
  expect_equal(pknca_group_timeu(o_value), "hr")
  # A unit given as a column is read from the group's rows
  o_column <- PKNCAconc(d_conc, conc~time|subject, timeu = "tu")
  expect_equal(pknca_group_timeu(o_column, data_conc = d_conc[1:3, ]), "hr")
  expect_equal(
    pknca_group_timeu(o_column, data_conc = NULL, data_sparse_conc = d_conc[1:3, ]),
    "hr"
  )
  # Rows that give more than one unit, or none, give no unit
  d_mixed <- d_conc[1:3, ]
  d_mixed$tu <- c("hr", "hr", "min")
  expect_null(pknca_group_timeu(o_column, data_conc = d_mixed))
  expect_null(pknca_group_timeu(o_column, data_conc = d_conc[0, ]))
  # A unit column that is also a grouping column is read from the group
  o_group <- PKNCAconc(d_conc, conc~time|tu+subject, timeu = "tu")
  expect_equal(
    pknca_group_timeu(o_group, data_conc = d_conc[1:3, c("time", "conc")], group = data.frame(tu = "hr", subject = 1)),
    "hr"
  )
  # Date-times without a unit were converted to hours
  expect_equal(pknca_group_timeu(PKNCAconc(d_conc, conc~time|subject), datetime = TRUE), "hr")
  # No unit at all, or one that is not a time unit, gives no unit
  expect_null(pknca_group_timeu(PKNCAconc(d_conc, conc~time|subject)))
  expect_null(pknca_group_timeu(PKNCAconc(d_conc, conc~time|subject, timeu = "not_a_unit")))
})

test_that("PKNCAdata matches tau to the nominal intervals for the concentration time unit", {
  doses <- c(0, 24.5, 49, 73, 97.5)
  d_conc <- data.frame(time = sort(unique(c(doses, 97.5 + c(0.5, 1, 2, 4, 8, 12, 24, 36, 48)))))
  d_conc$conc <- exp(-0.1 * d_conc$time) + 1
  o_dose <- PKNCAdose(data.frame(time = doses, dose = 1), dose~time)
  # Without a unit, as before:  tau is the median spacing
  ret_none <- PKNCAdata(PKNCAconc(d_conc, conc~time), o_dose)
  expect_equal(ret_none$intervals$start, c(97.5, 97.5))
  expect_equal(ret_none$intervals$end, c(122, Inf))
  # With hours, tau snaps to the daily interval
  ret_hr <- PKNCAdata(PKNCAconc(d_conc, conc~time, timeu = "hr"), o_dose)
  expect_equal(ret_hr$intervals$start, c(97.5, 97.5))
  expect_equal(ret_hr$intervals$end, c(121.5, Inf))
  # A unit given as a column is used the same way
  d_conc$tu <- "hr"
  ret_column <- PKNCAdata(PKNCAconc(d_conc, conc~time, timeu = "tu"), o_dose)
  expect_equal(ret_column$intervals$end, c(121.5, Inf))
})

test_that("PKNCAdata says when hourly dosing matches no nominal interval", {
  doses <- 0:5
  d_conc <- data.frame(time = sort(unique(c(doses, 5 + c(0.25, 0.5, 1, 2, 4)))))
  d_conc$conc <- exp(-0.3 * d_conc$time) + 1
  o_dose <- PKNCAdose(data.frame(time = doses, dose = 1), dose~time)
  expect_no_warning(ret_none <- PKNCAdata(PKNCAconc(d_conc, conc~time), o_dose))
  expect_warning(
    ret_hr <- PKNCAdata(PKNCAconc(d_conc, conc~time, timeu = "hr"), o_dose),
    class = "pknca_warning_tau_not_nominal"
  )
  # The interval found is the same; only the warning differs
  expect_equal(ret_hr$intervals$start, ret_none$intervals$start)
  expect_equal(ret_hr$intervals$end, ret_none$intervals$end)
  expect_equal(ret_hr$intervals$end, c(6, Inf))
})

test_that("PKNCAdata matches tau to the nominal intervals in days", {
  skip_if_not_installed("units")
  # Daily doses in days, recorded a little late:  the median spacing is 1.02
  # days, and with the unit known it snaps to one day
  doses <- c(0, 1.02, 2.04, 3, 4.02)
  d_conc <- data.frame(time = sort(unique(c(doses, 4.02 + c(0.05, 0.1, 0.25, 0.5, 1, 1.5, 2)))))
  d_conc$conc <- exp(-2 * d_conc$time) + 1
  o_dose <- PKNCAdose(data.frame(time = doses, dose = 1), dose~time)
  ret_none <- PKNCAdata(PKNCAconc(d_conc, conc~time), o_dose)
  expect_equal(ret_none$intervals$end, c(5.04, Inf))
  ret_day <- PKNCAdata(PKNCAconc(d_conc, conc~time, timeu = "day"), o_dose)
  expect_equal(ret_day$intervals$end, c(5.02, Inf))
})

test_that("pknca_timeu_extra_col carries a unit column only when it is not carried already", {
  d_conc <- data.frame(subject = 1, time = 0:2, conc = 1, tu = "hr")
  expect_equal(pknca_timeu_extra_col(PKNCAconc(d_conc, conc~time|subject, timeu = "hr")), character(0))
  expect_equal(pknca_timeu_extra_col(PKNCAconc(d_conc, conc~time|subject, timeu = "tu")), "tu")
  expect_equal(pknca_timeu_extra_col(PKNCAconc(d_conc, conc~time|tu+subject, timeu = "tu")), character(0))
})

test_that("PKNCAdata uses a time unit column that is also a grouping column", {
  doses <- c(0, 24.5, 49, 73, 97.5)
  times <- sort(unique(c(doses, 97.5 + c(0.5, 1, 2, 4, 8, 12, 24, 36, 48))))
  d_conc <- data.frame(tu = "hr", subject = rep(1:2, each = length(times)), time = rep(times, 2))
  d_conc$conc <- exp(-0.1 * d_conc$time) + 1
  d_dose <- data.frame(tu = "hr", subject = rep(1:2, each = length(doses)), time = rep(doses, 2), dose = 1)
  expect_no_warning(
    ret <-
      PKNCAdata(
        PKNCAconc(d_conc, conc~time|tu+subject, timeu = "tu"),
        PKNCAdose(d_dose, dose~time|tu+subject)
      )
  )
  expect_equal(ret$intervals$end, c(121.5, Inf, 121.5, Inf))
})

test_that("PKNCAdata names the group in each dose regimen warning, once per group", {
  doses <- 0:5
  times <- sort(unique(c(doses, 5 + c(0.25, 0.5, 1, 2, 4))))
  d_conc <- data.frame(subject = rep(1:2, each = length(times)), time = rep(times, 2))
  d_conc$conc <- exp(-0.3 * d_conc$time) + 1
  d_dose <- data.frame(subject = rep(1:2, each = length(doses)), time = rep(doses, 2), dose = 1)
  warnings <-
    testthat::capture_warnings(
      PKNCAdata(PKNCAconc(d_conc, conc~time|subject, timeu = "hr"), PKNCAdose(d_dose, dose~time|subject))
    )
  expect_length(warnings, 2)
  expect_match(warnings[1], "^subject=1: The dosing interval is not one of the nominal intervals")
  expect_match(warnings[2], "^subject=2: The dosing interval is not one of the nominal intervals")
  # The class is kept, with the common parent class
  expect_warning(
    PKNCAdata(PKNCAconc(d_conc[d_conc$subject == 1, ], conc~time|subject, timeu = "hr"), PKNCAdose(d_dose[d_dose$subject == 1, ], dose~time|subject)),
    class = "pknca_warning_dose_regimen"
  )
})

test_that("PKNCAdata reads date-times without a unit as hours", {
  doses <- c(0, 24.5, 49, 73, 97.5)
  times <- sort(unique(c(doses, 97.5 + c(0.5, 1, 2, 4, 8, 12, 24, 36, 48))))
  first_dose <- as.POSIXct("2026-01-01 08:00", tz = "UTC")
  d_conc <- data.frame(time = first_dose + times * 3600, conc = exp(-0.1 * times) + 1)
  d_dose <- data.frame(time = first_dose + doses * 3600, dose = 1)
  ret <- PKNCAdata(PKNCAconc(d_conc, conc~time), PKNCAdose(d_dose, dose~time))
  expect_equal(ret$intervals$end, c(121.5, Inf))
})

# A group's interval selection that gives a dose regimen warning and then fails
regimen_warned_then_failed <- function() {
  rlang::warn("tau warning", class = c("pknca_warning_tau_not_nominal", "pknca_warning_dose_regimen"))
  rlang::abort("failed", class = "pknca_error_test_group")
}

# A group's interval selection that gives the same dose regimen warning twice
regimen_warned_twice <- function() {
  rlang::warn("tau warning", class = c("pknca_warning_tau_not_nominal", "pknca_warning_dose_regimen"))
  rlang::warn("tau warning", class = c("pknca_warning_tau_not_nominal", "pknca_warning_dose_regimen"))
  "value"
}

test_that("dose regimen warnings of a group are given even when the group errors", {
  # The warning is reported, prefixed, before the error
  expect_warning(
    expect_error(
      pknca_with_regimen_warnings(regimen_warned_then_failed(), prefix = "subject=1: "),
      class = "pknca_error_test_group"
    ),
    regexp = "^subject=1: tau warning$",
    class = "pknca_warning_tau_not_nominal"
  )
  # Without an error, each warning is given once
  warnings <- testthat::capture_warnings(ret <- pknca_with_regimen_warnings(regimen_warned_twice(), prefix = "g: "))
  expect_equal(warnings, "g: tau warning")
  expect_equal(ret, "value")
})
