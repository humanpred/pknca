# The warning for an interval specification whose parameters are not
# calculated on one basis

inconsistency_message <- function(intervals) {
  tryCatch(
    {
      warn_inconsistent_interval_parameters(intervals)
      NA_character_
    },
    pknca_warning_interval_inconsistent_parameters = conditionMessage
  )
}

test_that("a parameter from a single-dose AUC with an interval AUC warns", {
  expect_warning(
    warn_inconsistent_interval_parameters(data.frame(start = 0, end = 24, aucint.all = TRUE, cav = TRUE)),
    regexp = paste0(
      "aucint.all with cav [(]single-dose AUCs [(]AUClast, AUCall, AUCinf[)] mixed with interval AUCs [(]AUCint[)]; ",
      "AUClast mixed with AUCall[)] [(]1 interval[)]"
    ),
    class = "pknca_warning_interval_inconsistent_parameters"
  )
  expect_match(
    inconsistency_message(data.frame(start = 0, end = 24, aucint.last = TRUE, cl.last = TRUE)),
    "aucint.last with cl.last (single-dose AUCs (AUClast, AUCall, AUCinf) mixed with interval AUCs (AUCint))",
    fixed = TRUE
  )
})

test_that("parameters from AUCinf,obs and AUCinf,pred warn", {
  expect_match(
    inconsistency_message(data.frame(start = 0, end = Inf, cl.obs = TRUE, vz.pred = TRUE)),
    "cl.obs with vz.pred (AUCinf,obs mixed with AUCinf,pred)",
    fixed = TRUE
  )
  expect_match(
    inconsistency_message(data.frame(start = 0, end = Inf, aucinf.obs = TRUE, mrt.pred = TRUE)),
    "aucinf.obs with mrt.pred (AUCinf,obs mixed with AUCinf,pred)",
    fixed = TRUE
  )
})

test_that("parameters from AUClast and AUCall warn", {
  expect_match(
    inconsistency_message(data.frame(start = 0, end = 24, cl.last = TRUE, vz.all = TRUE)),
    "cl.last with vz.all (AUClast mixed with AUCall)",
    fixed = TRUE
  )
})

test_that("a parameter that needs a finite end warns at an infinite end", {
  expect_match(
    inconsistency_message(data.frame(start = 0, end = Inf, cav = TRUE)),
    "cav (a parameter that needs a finite interval end)",
    fixed = TRUE
  )
  expect_match(
    inconsistency_message(data.frame(start = 0, end = Inf, deg.fluc = TRUE)),
    "deg.fluc (a parameter that needs a finite interval end)",
    fixed = TRUE
  )
  # The same parameters with a finite end are consistent
  expect_true(is.na(inconsistency_message(data.frame(start = 0, end = 24, cav = TRUE))))
  expect_true(is.na(inconsistency_message(data.frame(start = 0, end = 24, deg.fluc = TRUE))))
})

test_that("consistent specifications do not warn", {
  # The usual single dose
  expect_no_warning(
    warn_inconsistent_interval_parameters(
      data.frame(
        start = 0, end = Inf, cmax = TRUE, tmax = TRUE, auclast = TRUE, aucinf.obs = TRUE,
        half.life = TRUE, cl.obs = TRUE, vz.obs = TRUE, mrt.obs = TRUE
      )
    )
  )
  # Several AUCs (and AUMCs and percent extrapolated) are reported together
  expect_no_warning(
    warn_inconsistent_interval_parameters(
      data.frame(
        start = 0, end = Inf, auclast = TRUE, aucall = TRUE, aucinf.obs = TRUE, aucinf.pred = TRUE,
        aumclast = TRUE, aucpext.obs = TRUE, aucpext.pred = TRUE
      )
    )
  )
  # A parameter with its own inputs:  deg.fluc is calculated from cav
  expect_no_warning(
    warn_inconsistent_interval_parameters(
      data.frame(start = 0, end = 24, deg.fluc = TRUE, cav = TRUE, cmax = TRUE, cmin = TRUE)
    )
  )
  # Multiple-dose MRT and Vss combine the AUCint over the interval with the
  # extrapolation to infinity by design
  expect_no_warning(
    warn_inconsistent_interval_parameters(
      data.frame(
        start = 0, end = 24, aucint.last = TRUE, aucint.inf.obs = TRUE, cl.int.last = TRUE,
        mrt.md.obs = TRUE, vss.md.obs = TRUE
      )
    )
  )
  # Routes and sample types are not judged:  one interval often covers the IV
  # and oral arms of a crossover, or plasma and urine
  expect_no_warning(
    warn_inconsistent_interval_parameters(
      data.frame(start = 0, end = Inf, c0 = TRUE, tlag = TRUE, ae = TRUE, fe = TRUE, auclast = TRUE)
    )
  )
  # Parameters that no context judges (secondary parameters) are not judged
  expect_no_warning(
    warn_inconsistent_interval_parameters(data.frame(start = 0, end = Inf, f.obs = TRUE, cl.pred = TRUE))
  )
})

test_that("every interval that pknca_interval_table() gives is consistent", {
  # The check and the context selection are built from the same contexts, so a
  # disagreement between them is a bug in one of them
  for (dosing in pknca_dosing()) {
    for (route in pknca_routes()) {
      for (sample_type in pknca_sample_types()) {
        for (clast_type in c("obs", "pred")) {
          for (auc_type in c("last", "all")) {
            for (end in c(24, Inf)) {
              intervals <-
                tryCatch(
                  pknca_interval_table(
                    0, end,
                    dosing = dosing, route = route, sample_type = sample_type,
                    tier = "all", clast_type = clast_type, auc_type = auc_type
                  ),
                  pknca_error_interval_no_parameters = function(e) NULL
                )
              if (!is.null(intervals)) {
                expect_true(
                  is.na(inconsistency_message(intervals)),
                  info = paste(dosing, route, sample_type, clast_type, auc_type, end)
                )
              }
            }
          }
        }
      }
    }
  }
})

test_that("one warning gives every inconsistency with the number of intervals", {
  intervals <-
    data.frame(
      start = c(0, 24, 48, 72),
      end = c(24, 48, 72, Inf),
      aucint.last = TRUE,
      cl.last = TRUE,
      deg.fluc = c(TRUE, TRUE, FALSE, TRUE)
    )
  warnings <- testthat::capture_warnings(warn_inconsistent_interval_parameters(intervals))
  expect_length(warnings, 1)
  msg <- warnings[[1]]
  # The rows with the same problem are counted together, whatever their end;
  # at the infinite end, deg.fluc is reported for needing a finite end rather
  # than paired with cl.last
  expect_match(msg, "aucint.last with cl.last (single-dose AUCs (AUClast, AUCall, AUCinf) mixed with interval AUCs (AUCint)) (4 intervals)", fixed = TRUE)
  expect_match(msg, "cl.last with deg.fluc (single-dose AUCs (AUClast, AUCall, AUCinf) mixed with interval AUCs (AUCint)) (2 intervals)", fixed = TRUE)
  expect_match(msg, "deg.fluc (a parameter that needs a finite interval end) (1 interval)", fixed = TRUE)
})

test_that("PKNCAdata() and pk.nca() each warn once for the whole specification", {
  d_conc <- data.frame(conc = c(0, 2, 4, 3, 1, 0.5), time = c(0, 1, 2, 4, 8, 12))
  d_dose <- data.frame(dose = 10, time = 0)
  intervals <-
    data.frame(start = c(0, 0, 0), end = c(12, 24, Inf), cl.obs = TRUE, vz.pred = TRUE)
  expect_warning(
    o_data <- PKNCAdata(PKNCAconc(d_conc, conc~time), PKNCAdose(d_dose, dose~time), intervals = intervals),
    regexp = "cl.obs with vz.pred [(]AUCinf,obs mixed with AUCinf,pred[)] [(]3 intervals[)]",
    class = "pknca_warning_interval_inconsistent_parameters"
  )
  # One warning for the three intervals, not one per interval
  warnings <- testthat::capture_warnings(pk.nca(o_data))
  expect_equal(sum(grepl("not calculated on one basis", warnings, fixed = TRUE)), 1)
})

test_that("the consistent sets follow the registry", {
  sets <- interval_consistent_sets()
  expect_true(all(c("auclast", "cl.obs", "cav", "deg.fluc") %in% sets$governed))
  # Secondary and sparse-only parameters are never chosen by a context
  expect_false(any(c("f.obs", "sparse_auclast", "auclast_se") %in% sets$governed))
  # A new registration drops the cache, and the next call includes the new
  # parameter wherever its dependencies go
  original <- get("interval.cols", envir = PKNCA:::.PKNCAEnv)
  on.exit({
    assign("interval.cols", original, envir = PKNCA:::.PKNCAEnv)
    for (cache_name in c("parameter_classification", "auc_basis_families", "interval.cols_derived", "interval_consistent_sets")) {
      if (exists(cache_name, envir = PKNCA:::.PKNCAEnv)) rm(list = cache_name, envir = PKNCA:::.PKNCAEnv)
    }
  })
  add.interval.col(
    "cl.test.consistency",
    FUN = "pk.calc.cl",
    values = c(FALSE, TRUE),
    unit_type = "clearance",
    pretty_name = "Test clearance",
    desc = "Test clearance from AUCinf,pred",
    depends = "aucinf.pred",
    formalsmap = list(auc = "aucinf.pred")
  )
  expect_false(exists("interval_consistent_sets", envir = PKNCA:::.PKNCAEnv))
  expect_match(
    inconsistency_message(data.frame(start = 0, end = Inf, cl.test.consistency = TRUE, vz.obs = TRUE)),
    "cl.test.consistency with vz.obs (AUCinf,obs mixed with AUCinf,pred)",
    fixed = TRUE
  )
})
