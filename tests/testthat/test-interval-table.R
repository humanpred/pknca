# Helper:  the parameters an interval specification asks for, per row
params_of <- function(x, row = 1) {
  cols <- intersect(names(x), names(get.interval.cols()))
  sort(cols[unlist(x[row, cols]) %in% TRUE])
}

# ... and across every row
params_of_all <- function(x) {
  cols <- intersect(names(x), names(get.interval.cols()))
  sort(cols[vapply(cols, function(n) any(x[[n]] %in% TRUE), TRUE)])
}

# Golden contexts ---------------------------------------------------------
#
# The exact parameter set for each common context.  Changing one of these
# changes what a default analysis reports, so it is deliberate.

test_that("single dose, extravascular", {
  ret <- pknca_interval_table(0, 24, dosing = "single", route = "extravascular")
  expect_equal(nrow(ret), 1L)
  expect_equal(
    params_of(ret),
    sort(c("auclast", "aucinf.obs", "aucpext.obs", "cl.obs", "cmax", "tmax",
           "count_conc", "half.life", "tlag"))
  )
  expect_equal(ret$impute, "start_predose_conc0")
})

test_that("single dose, IV bolus, splits c0 out of the imputation", {
  ret <- pknca_interval_table(0, 24, dosing = "single", route = "iv_bolus")
  expect_equal(nrow(ret), 2L)
  # tlag is extravascular, so it is gone; c0 appears and is calculated from the
  # unimputed data
  expect_equal(
    params_of(ret, 1),
    sort(c("auclast", "aucinf.obs", "aucpext.obs", "cl.obs", "cmax", "tmax",
           "count_conc", "half.life"))
  )
  expect_equal(params_of(ret, 2), "c0")
  expect_equal(ret$impute, c("start_predose_conc0", NA_character_))
})

test_that("single dose, IV infusion, adds ceoi and no c0", {
  ret <- pknca_interval_table(0, 24, dosing = "single", route = "iv_infusion")
  expect_equal(nrow(ret), 1L)
  expect_true("ceoi" %in% params_of(ret))
  expect_false("c0" %in% params_of(ret))
})

test_that("a continuous infusion has no end of infusion concentration", {
  ret <-
    pknca_interval_table(0, 24, dosing = "single", route = "iv_continuous_infusion")
  expect_false("ceoi" %in% params_of(ret))
})

test_that("steady state uses the interval AUCs and their clearance", {
  ret <-
    pknca_interval_table(144, 168, dosing = "steady_state", route = "extravascular")
  expect_equal(
    params_of(ret),
    sort(c("aucint.last", "aucint.inf.obs", "cl.int.inf.obs", "cmax", "tmax",
           "ctrough", "count_conc", "half.life", "tlag"))
  )
  # Not the single-dose AUCs, which would need data past the last dose
  expect_false(any(c("auclast", "aucinf.obs", "cl.obs") %in% params_of(ret)))
  expect_equal(ret$impute, "start_predose")
})

test_that("multiple dosing without steady state uses the minimum to impute", {
  ret <- pknca_interval_table(24, 48, dosing = "multiple", route = "extravascular")
  expect_equal(ret$impute, "start_cmin")
})

test_that("an interval collection gives the excreta parameters and no imputation", {
  ret <-
    pknca_interval_table(
      0, 24, dosing = "single", route = "extravascular", sample_type = "interval"
    )
  # Renal clearance needs a plasma AUC as well as the amount excreted, so it
  # is secondary and is not chosen automatically
  expect_equal(params_of(ret), sort(c("ae", "fe", "volpk")))
  expect_false("impute" %in% names(ret))
})

test_that("a sparse design gives only sparse parameters", {
  ret <-
    pknca_interval_table(0, 24, dosing = "single", route = "extravascular", sparse = TRUE)
  expect_equal(params_of(ret), sort(c("sparse_auclast", "sparse_auc_se")))
  expect_false("impute" %in% names(ret))
})

test_that("a dense design gives no sparse parameters", {
  # sparse_auc_se is produced alongside sparse_auclast and is not flagged in
  # the registry, so it has to be classified through what it depends on
  for (d in pknca_dosing()) {
    ret <- pknca_interval_table(0, 24, dosing = d, route = "extravascular", tier = "all")
    expect_false(any(grepl("sparse", params_of(ret))), info = d)
  }
})

# Intervals and extra columns --------------------------------------------

test_that("start and end may be vectors", {
  ret <- pknca_interval_table(c(0, 144), c(24, 168), dosing = "single")
  expect_equal(ret$start, c(0, 144))
  expect_equal(ret$end, c(24, 168))
  expect_equal(params_of(ret, 1), params_of(ret, 2))
})

test_that("extra columns are carried onto every row", {
  ret <-
    pknca_interval_table(
      0, 24, dosing = "single", route = "iv_bolus", analyte = "parent"
    )
  expect_equal(ret$analyte, rep("parent", nrow(ret)))
})

test_that("the result is a valid interval specification", {
  for (d in pknca_dosing()) {
    for (r in pknca_routes()) {
      ret <- pknca_interval_table(0, 24, dosing = d, route = r)
      expect_no_error(check.interval.specification(ret))
      expect_no_warning(check.interval.specification(ret))
    }
  }
})

# include and exclude ----------------------------------------------------

test_that("include accepts a concept", {
  ret <-
    pknca_interval_table(
      144, 168, dosing = "steady_state", route = "extravascular",
      include = "fluctuation"
    )
  expect_true(all(c("ptr", "swing") %in% params_of(ret)))
})

test_that("include accepts a parameter name", {
  ret <- pknca_interval_table(0, 24, dosing = "single", include = "aucall")
  expect_true("aucall" %in% params_of(ret))
})

test_that("exclude removes a parameter and a concept", {
  ret <- pknca_interval_table(0, 24, dosing = "single", exclude = "tlag")
  expect_false("tlag" %in% params_of(ret))
  ret2 <- pknca_interval_table(0, 24, dosing = "single", exclude = "half_life")
  expect_false("half.life" %in% params_of(ret2))
})

test_that("naming something in both include and exclude is an error", {
  expect_error(
    pknca_interval_table(0, 24, dosing = "single", include = "aucall", exclude = "aucall"),
    class = "pknca_error_interval_include_exclude_conflict"
  )
})

test_that("an unknown name in include or exclude is an error", {
  expect_error(
    pknca_interval_table(0, 24, dosing = "single", include = "nonexistent"),
    class = "pknca_error_interval_unknown_selection"
  )
  expect_error(
    pknca_interval_table(0, 24, dosing = "single", exclude = "nonexistent"),
    class = "pknca_error_interval_unknown_selection"
  )
})

test_that("excluding everything is an error", {
  expect_error(
    pknca_interval_table(
      0, 24, dosing = "single", route = "extravascular",
      exclude = c("auclast", "aucinf.obs", "aucpext.obs", "cl.obs", "cmax",
                  "tmax", "count_conc", "half.life", "tlag")
    ),
    class = "pknca_error_interval_no_parameters"
  )
})

# tier -------------------------------------------------------------------

test_that("tier = all gives more than tier = common", {
  common <- params_of(pknca_interval_table(0, 24, dosing = "single"))
  all_of <- params_of(pknca_interval_table(0, 24, dosing = "single", tier = "all"))
  expect_true(all(common %in% all_of))
  expect_gt(length(all_of), length(common))
})

# Imputation pairing -----------------------------------------------------

test_that("impute may be given explicitly or turned off", {
  expect_equal(
    pknca_interval_table(0, 24, dosing = "single", impute = "start_conc0")$impute,
    "start_conc0"
  )
  expect_false(
    "impute" %in% names(pknca_interval_table(0, 24, dosing = "single", impute = NA))
  )
})

test_that("start_cmin does not calculate the minimum from the imputed minimum", {
  ret <-
    pknca_interval_table(
      24, 48, dosing = "multiple", route = "extravascular", tier = "all"
    )
  expect_equal(ret$impute[params_of_row <- 1], "start_cmin")
  cols <- intersect(names(ret), names(get.interval.cols()))
  row_of <- function(p) which(unlist(ret[, p]) %in% TRUE)
  # cmin and tmin are calculated on a row with no imputation
  expect_true(is.na(ret$impute[row_of("cmin")]))
  expect_true(is.na(ret$impute[row_of("tmin")]))
  # ... while the AUC is calculated with it
  expect_equal(ret$impute[row_of("aucint.last")], "start_cmin")
})

test_that("count_conc_measured is never calculated from imputed data", {
  for (d in pknca_dosing()) {
    ret <- pknca_interval_table(0, 24, dosing = d, tier = "all")
    row <- which(unlist(ret[, "count_conc_measured"]) %in% TRUE)
    expect_true(is.na(ret$impute[row]), info = d)
  }
})

test_that("c0 is not calculated from a predose concentration for a single dose", {
  # Before the first dose there is no residual drug, so a predose measurement
  # shifted to the start would be taken as C0
  ret <- pknca_interval_table(0, 24, dosing = "single", route = "iv_bolus")
  row <- which(unlist(ret[, "c0"]) %in% TRUE)
  expect_true(is.na(ret$impute[row]))
})

test_that("c0 is calculated from the predose concentration at steady state", {
  # At steady state the predose concentration is the C0 of the current dose
  ret <- pknca_interval_table(144, 168, dosing = "steady_state", route = "iv_bolus",
                              tier = "all")
  row <- which(unlist(ret[, "c0"]) %in% TRUE)
  expect_equal(ret$impute[row], "start_predose")
})

# Presets ----------------------------------------------------------------

test_that("presets are named argument sets", {
  expect_true(all(c("single_dose", "steady_state", "bioequivalence",
                    "first_in_human", "mass_balance") %in% names(pknca_presets())))
})

test_that("a preset supplies arguments and explicit arguments win", {
  be <- pknca_interval_table(0, 24, preset = "bioequivalence")
  expect_true(all(c("aucall", "clast.obs", "tlast") %in% params_of(be)))
  # The preset is extravascular; asking for IV bolus overrides it
  iv <- pknca_interval_table(0, 24, preset = "bioequivalence", route = "iv_bolus")
  expect_false("tlag" %in% params_of(iv))
})

test_that("an unknown preset is an error", {
  expect_error(
    pknca_interval_table(0, 24, preset = "nonexistent"),
    class = "pknca_error_interval_unknown_preset"
  )
})

# Reachability -----------------------------------------------------------

test_that("every parameter is reachable from some context, or documented as not", {
  emitted <- character(0)
  for (d in pknca_dosing()) {
    for (r in pknca_routes()) {
      for (s in pknca_sample_types()) {
        for (sp in c(FALSE, TRUE)) {
          ret <-
            tryCatch(
              pknca_interval_table(
                0, 24, dosing = d, route = r, sample_type = s, sparse = sp,
                tier = "all", clast_type = "obs"
              ),
              error = function(e) NULL
            )
          if (!is.null(ret)) emitted <- union(emitted, params_of_all(ret))
          ret_pred <-
            tryCatch(
              pknca_interval_table(
                0, 24, dosing = d, route = r, sample_type = s, sparse = sp,
                tier = "all", clast_type = "pred"
              ),
              error = function(e) NULL
            )
          if (!is.null(ret_pred)) emitted <- union(emitted, params_of_all(ret_pred))
        }
      }
    }
  }
  unreachable <- sort(setdiff(setdiff(names(get.interval.cols()), c("start", "end")), emitted))
  # Everything built on AUCall.  Whether AUCall differs from AUClast depends on
  # whether there are values below the limit of quantification after the last
  # measurable one, which is a property of the data rather than of the
  # analysis, so no context chooses it.  It is still available by name through
  # `include`.
  expect_equal(
    unreachable,
    sort(c(
      "aucall", "aucall.dn", "aumcall", "aumcall.dn",
      "aucint.all", "aumcint.all",
      "aucivall", "aumcivall", "aucivpbextall",
      "aucivint.all", "aumcivint.all", "aucivpbextint.all",
      "cav.int.all",
      "cl.all", "cl.int.all", "cl.iv.all", "cl.ivint.all",
      "kel.all", "kel.int.all", "kel.iv.all", "kel.ivint.all",
      "mrt.all", "mrt.int.all", "mrt.iv.all", "mrt.ivint.all",
      "vss.all", "vss.int.all", "vss.iv.all", "vss.ivint.all",
      "vz.all", "vz.int.all", "vz.iv.all", "vz.ivint.all",
      # Secondary parameters need inputs from more than one profile, which one
      # interval cannot supply
      "f",
      "clr.last", "clr.obs", "clr.pred",
      "clr.last.dn", "clr.obs.dn", "clr.pred.dn"
    ))
  )
  # Asking for it by name works
  expect_true(
    "aucall" %in% params_of(pknca_interval_table(0, 24, dosing = "single", include = "aucall"))
  )
})

# Secondary parameters ---------------------------------------------------

test_that("a secondary parameter is not chosen automatically", {
  for (tier in c("common", "all")) {
    expect_false(
      "f" %in% params_of_all(pknca_interval_table(0, 24, dosing = "single", tier = tier)),
      info = tier
    )
    expect_false(
      "clr.obs" %in%
        params_of_all(pknca_interval_table(
          0, 24, dosing = "single", sample_type = "interval", tier = tier
        )),
      info = tier
    )
  }
})

test_that("a secondary parameter is still available by name", {
  expect_true(
    "f" %in% params_of_all(pknca_interval_table(0, 24, dosing = "single", include = "f"))
  )
  expect_true(
    "clr.obs" %in%
      params_of_all(pknca_interval_table(
        0, 24, dosing = "single", sample_type = "interval", include = "clr.obs"
      ))
  )
})

# End to end -------------------------------------------------------------

test_that("a generated specification calculates in pk.nca", {
  d_conc <-
    data.frame(
      subject = 1,
      time = c(0, 1, 2, 4, 8, 12, 24),
      conc = c(0, 50, 40, 30, 15, 8, 2)
    )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_dose <- PKNCAdose(data.frame(subject = 1, dose = 100, time = 0), dose ~ time | subject)
  intervals <- pknca_interval_table(0, 24, dosing = "single", route = "extravascular")
  o_data <- suppressMessages(PKNCAdata(o_conc, o_dose, intervals = intervals))
  res <- as.data.frame(suppressMessages(suppressWarnings(pk.nca(o_data))))
  # Every requested parameter is calculated
  expect_true(all(params_of(intervals) %in% res$PPTESTCD))
  # ... and produces a value
  requested <- res[res$PPTESTCD %in% params_of(intervals), ]
  expect_false(anyNA(requested$PPORRES))
})

test_that("a parameter kept out of the imputation gives the unimputed answer", {
  # The point of splitting the rows:  c0 must not see the imputed start
  d_conc <-
    data.frame(subject = 1, time = c(-0.5, 1, 2, 4, 8, 12, 24),
               conc = c(2, 50, 40, 30, 15, 8, 2))
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_dose <-
    PKNCAdose(data.frame(subject = 1, dose = 100, time = 0), dose ~ time | subject,
              route = "intravascular")
  c0_from <- function(intervals) {
    o_data <- suppressMessages(PKNCAdata(o_conc, o_dose, intervals = intervals))
    res <- as.data.frame(suppressMessages(suppressWarnings(pk.nca(o_data))))
    res$PPORRES[res$PPTESTCD == "c0"]
  }
  generated <- pknca_interval_table(0, 24, dosing = "single", route = "iv_bolus")
  unimputed <- data.frame(start = 0, end = 24, c0 = TRUE)
  expect_equal(c0_from(generated), c0_from(unimputed))
})
