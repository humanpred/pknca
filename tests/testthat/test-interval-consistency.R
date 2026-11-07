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
    inconsistency_message(data.frame(start = 0, end = Inf, vss.obs = TRUE, mrt.pred = TRUE)),
    "mrt.pred with vss.obs (AUCinf,obs mixed with AUCinf,pred)",
    fixed = TRUE
  )
  # An AUC report with a parameter from the other extrapolation is common (the
  # percent extrapolated is reported both ways, for example)
  expect_true(is.na(inconsistency_message(data.frame(start = 0, end = Inf, aucinf.pred = TRUE, aucpext.pred = TRUE, cl.obs = TRUE))))
})

test_that("secondary parameters are judged by the AUCs they are calculated from", {
  expect_match(
    inconsistency_message(data.frame(start = 0, end = Inf, f.obs = TRUE, cl.pred = TRUE)),
    "cl.pred with f.obs (AUCinf,obs mixed with AUCinf,pred)",
    fixed = TRUE
  )
  expect_true(is.na(inconsistency_message(data.frame(start = 0, end = Inf, f.obs = TRUE, cl.obs = TRUE, ratio.auclast = TRUE))))
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
  # The multiple-dose MRT and Vss are calculated from the single-dose AUCs
  expect_no_warning(
    warn_inconsistent_interval_parameters(
      data.frame(start = 0, end = 24, auclast = TRUE, aucinf.obs = TRUE, cl.last = TRUE, mrt.md.obs = TRUE, vss.md.obs = TRUE)
    )
  )
  # A parameter that no AUC is involved in is consistent with every basis, so
  # a steady-state interval may report AUClast and Cav with the trough
  for (with_auc in list(
    c("cmax", "tmax", "auclast", "ctrough"),
    c("auclast", "ptr", "swing"),
    c("cmax", "tmax", "auclast", "cav", "ctrough"),
    c("cmax", "ctrough", "cl.obs"),
    c("cmax", "ctrough", "half.life", "aucinf.obs")
  )) {
    intervals <- data.frame(start = 0, end = 24)
    intervals[with_auc] <- TRUE
    expect_no_warning(warn_inconsistent_interval_parameters(intervals))
  }
})

test_that("a parameter and its own inputs are judged by the same AUCs", {
  # deg.fluc is calculated from cav, so both are judged against aucint.last
  expect_match(
    inconsistency_message(data.frame(start = 0, end = 24, aucint.last = TRUE, cav = TRUE, deg.fluc = TRUE)),
    "aucint.last with cav (single-dose AUCs (AUClast, AUCall, AUCinf) mixed with interval AUCs (AUCint))",
    fixed = TRUE
  )
  # Every pair is reported:  vz.obs is calculated from cl.obs, and both are
  # judged against mrt.pred
  msg <- inconsistency_message(data.frame(start = 0, end = Inf, cl.obs = TRUE, vz.obs = TRUE, mrt.pred = TRUE))
  expect_match(msg, "cl.obs with mrt.pred (AUCinf,obs mixed with AUCinf,pred)", fixed = TRUE)
  expect_match(msg, "mrt.pred with vz.obs (AUCinf,obs mixed with AUCinf,pred)", fixed = TRUE)
})

test_that("a long list of problems is cut short", {
  # Each row mixes cl.obs with a different AUCinf,pred-based parameter, so each
  # gives its own problem
  pred_params <- c("cl.pred", "vz.pred", "mrt.pred", "vss.pred", "kel.pred", "aucinf.pred", "aumcinf.pred")
  intervals <- data.frame(start = 0, end = Inf, cl.obs = TRUE)
  intervals <- intervals[rep(1, length(pred_params)), ]
  for (i in seq_along(pred_params)) {
    intervals[[pred_params[i]]] <- seq_along(pred_params) == i
  }
  # aucinf.pred and aumcinf.pred are AUC reports, which are not judged on
  # AUCinf,obs and AUCinf,pred
  expect_length(strsplit(inconsistency_message(intervals), "\n")[[1]], 1 + length(pred_params) - 2)
  # Many distinct problems:  every pair of AUCinf,obs and AUCinf,pred parameters
  obs_params <- c("cl.obs", "vz.obs", "mrt.obs", "vss.obs", "kel.obs")
  many <- data.frame(start = 0, end = Inf)
  many[c(obs_params, pred_params)] <- TRUE
  lines <- strsplit(inconsistency_message(many), "\n")[[1]]
  expect_length(lines, 1 + 20 + 1)
  expect_match(lines[length(lines)], "^  [.][.][.] and [0-9]+ more$")
})

test_that("every preset gives a consistent interval", {
  for (preset in names(pknca_presets())) {
    for (end in c(24, Inf)) {
      intervals <- suppressWarnings(pknca_interval_table(0, end, preset = preset))
      expect_true(is.na(inconsistency_message(intervals)), info = paste(preset, end))
    }
  }
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
  # The rows with the same problem are counted together, whatever their end
  expect_match(msg, "aucint.last with cl.last (single-dose AUCs (AUClast, AUCall, AUCinf) mixed with interval AUCs (AUCint)) (4 intervals)", fixed = TRUE)
  # deg.fluc applies only to repeated dosing, so (as in pknca_interval_table())
  # it is not judged against an AUC basis
  expect_false(grepl("with deg.fluc", msg, fixed = TRUE))
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
  expect_true(all(c("auclast", "cl.obs", "cav", "f.obs", "aucpext.obs") %in% sets$judged))
  # A parameter calculated from no AUC, and one that applies only to repeated
  # dosing, is not judged
  expect_false(any(c("cmax", "ctrough", "sparse_auclast", "deg.fluc", "mrt.md.obs") %in% sets$judged))
  expect_true(all(c("cav", "ctrough", "deg.fluc") %in% sets$finite_only))
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
