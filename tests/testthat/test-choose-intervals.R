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
  # It overrides tau.choices if everything is equally spaced.
  expect_equal(find.tau(0:10, tau.choices=c(24, 168)), 1)
  expect_equal(find.tau(seq(0, 100, by=10),
                        tau.choices=c(24, 168)), 10)
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

test_that("find.tau gives no interval when the doses do not repeat over one", {
  # A single dose off schedule leaves gaps of 32 and 16 hours among otherwise
  # daily doses.  96 hours spans the doses seen so far and so used to be
  # reported, although no two doses are 96 hours apart and the drug was given
  # daily; requiring two complete intervals rules it out.
  expect_equal(find.tau(c(0, 24, 48, 80, 96, 120, 144)), NA)
  expect_equal(find.tau(c(0, 24, 48, 80, 96, 120, 144), tau.choices=24), NA)
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
  # Every gap that is longer than the interval is named
  expect_warning(
    tau_two <- find.tau(c(0, 24, 48, 96, 120, 144, 192, 216, 240)),
    regexp="missing after times 48, 144",
    class="pknca_warning_tau_irregular_dosing"
  )
  expect_equal(tau_two, 24)
  # A gap that is not a whole number of intervals is not a missed dose
  expect_equal(find.tau(c(0, 24, 48, 60, 84, 108), tau.choices=24), NA)
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

test_that("choose.auc.intervals keeps single.dose.aucs when it is set", {
  # Setting the option is the documented way back to the previous intervals
  tmp_single_dose_auc <-
    check.interval.specification(
      data.frame(start=0,
                 end=c(24, Inf),
                 auclast=c(TRUE, FALSE),
                 aucinf.obs=c(FALSE, TRUE),
                 half.life=c(FALSE, TRUE)))
  expect_equal(
    choose.auc.intervals(c(1, 2, 3), 1, single.dose.aucs=tmp_single_dose_auc),
    check.interval.specification(
      data.frame(start=1,
                 end=c(25, Inf),
                 auclast=c(TRUE, FALSE),
                 aucinf.obs=c(FALSE, TRUE),
                 half.life=c(FALSE, TRUE)))
  )
  # And through the options list
  expect_equal(
    choose.auc.intervals(c(1, 2, 3), 1, options=list(single.dose.aucs=tmp_single_dose_auc)),
    check.interval.specification(
      data.frame(start=1,
                 end=c(25, Inf),
                 auclast=c(TRUE, FALSE),
                 aucinf.obs=c(FALSE, TRUE),
                 half.life=c(FALSE, TRUE)))
  )
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
  # An irregular gap that is not a whole number of intervals gives no tau, so
  # no interval is anchored on the last dose
  doses_gap <- c(0, 24, 48, 80, 96, 120, 144)
  ret_gap <- choose.auc.intervals(sort(unique(c(doses_gap, 144 + dense, 192, 216))), doses_gap)
  expect_false(any(is.infinite(ret_gap$end) & ret_gap$start == 144 & ret_gap$aucint.last))
  expect_equal(ret_gap$start, 144)
  expect_equal(ret_gap$end, Inf)
})

test_that("choose.auc.intervals uses tau.choices from the options", {
  # The option reaches find.tau(), which anchors the last dose's interval
  doses <- c(0, 10, 24, 34, 48, 58, 72, 82, 96, 106)
  conc <- sort(unique(c(doses, 106 + c(1, 2, 4, 8, 12, 24, 48), 106 + 72)))
  expect_equal(
    choose.auc.intervals(conc, doses)$end,
    c(130, Inf)
  )
  expect_equal(
    choose.auc.intervals(conc, doses, options=list(tau.choices=48))$end,
    c(154, Inf)
  )
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
  # A dose off schedule among daily doses gives no interval rather than the
  # length of the whole dosing period
  expect_warning(
    off_schedule <-
      resolve_dose_tau(interval=data.frame(start=144, end=168),
                       time.dose=c(0, 24, 48, 80, 96, 120, 144)),
    class="pknca_warning_tau_undetermined"
  )
  expect_equal(off_schedule, NA_real_)
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
  expect_equal(dose_route_for_intervals(c("intravascular", "extravascular"), c(0, 0)), "iv_bolus")
})
