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

test_that("choose.auc.intervals", {
  tmp.single.dose.auc <-
    check.interval.specification(
      data.frame(start=0,
                 end=c(24, Inf),
                 auclast=c(TRUE, FALSE),
                 aucinf=c(FALSE, TRUE),
                 half.life=c(FALSE, TRUE),
                 stringsAsFactors=FALSE))

  # Check the inputs
  expect_error(choose.auc.intervals(NA, 1, tmp.single.dose.auc),
               regexp="time.conc may not have any NA values")
  expect_error(choose.auc.intervals(1, NA, tmp.single.dose.auc),
               regexp="time.dosing may not have any NA values")
  # The below test is a bit of a non-sequeter-- essentially, it just
  # needs to return a 0-row data frame.
  expect_error(choose.auc.intervals(1, 1,
                                    single.dose.aucs=data.frame()),
               regexp="interval specification has no rows")
  # It adjusts single dose AUCs by the starting time
  expect_equal(choose.auc.intervals(1, 1,
                                    single.dose.aucs=tmp.single.dose.auc),
               check.interval.specification(
                 data.frame(start=1,
                            end=c(25, Inf),
                            auclast=c(TRUE, FALSE),
                            aucinf=c(FALSE, TRUE),
                            half.life=c(FALSE, TRUE))))

  # Find intervals for two doses with PK at both points and one in
  # between.
  expect_equal(choose.auc.intervals(c(1, 2, 3), c(1, 3),
                                    single.dose.aucs=tmp.single.dose.auc),
               check.interval.specification(
                 data.frame(start=1,
                            end=3,
                            cmax=TRUE,
                            tmax=TRUE,
                            auclast=TRUE)))
  # Find intervals for two doses with PK at both points, one in
  # between, and one after asking for AUClast after the second dose
  # but no half-life.
  expect_equal(choose.auc.intervals(1:5, c(1, 3),
                                    single.dose.aucs=tmp.single.dose.auc),
               check.interval.specification(
                 data.frame(start=c(1, 3),
                            end=c(3, 5),
                            cmax=TRUE,
                            tmax=TRUE,
                            auclast=TRUE)))
  # Find intervals for two doses with PK at both points, one in
  # between, and one after asking for AUClast after the second dose
  # with half-life.
  expect_equal(choose.auc.intervals(1:6, c(1, 3),
                                    single.dose.aucs=tmp.single.dose.auc),
               check.interval.specification(
                 data.frame(start=c(1, 3, 3),
                            end=c(3, 5, Inf),
                            auclast=c(TRUE, TRUE, FALSE),
                            cmax=c(TRUE, TRUE, FALSE),
                            tmax=c(TRUE, TRUE, FALSE),
                            half.life=c(FALSE, FALSE, TRUE))))
  # Some doses have PK betwen them, some not.
  expect_equal(choose.auc.intervals(1:6, c(1, 3, 5, 7, 9),
                                    single.dose.aucs=tmp.single.dose.auc),
               check.interval.specification(
                 data.frame(start=c(1, 3),
                            end=c(3, 5),
                            auclast=TRUE,
                            cmax=TRUE,
                            tmax=TRUE)))
  # Find intervals when some doses do not have AUCs between them
  # (pairs of doses with trough but no PK between)  
  expect_equal(choose.auc.intervals(c(1, 2, 3, 5, 6, 7),
                                    c(1, 3, 5, 7, 9),
                                    single.dose.aucs=tmp.single.dose.auc),
               check.interval.specification(
                 data.frame(start=c(1, 5),
                            end=c(3, 7),
                            cmax=TRUE,
                            tmax=TRUE,
                            auclast=TRUE)))
  # Find intervals for two doses with PK at both points, one in
  # between, and one after asking for AUClast after the second dose
  # with half-life.  Since tau is not detectable, no half-life at the
  # end.
  expect_equal(choose.auc.intervals(1:6, c(1, 3, 5, 9),
                                    single.dose.aucs=tmp.single.dose.auc),
               check.interval.specification(
                 data.frame(start=c(1, 3),
                            end=c(3, 5),
                            auclast=TRUE,
                            cmax=TRUE,
                            tmax=TRUE)))
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
