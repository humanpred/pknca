# Shared fixture for the renal-clearance linkage.  `auc.method = "linear"` so
# that the trapezoids are hand-computable:
#   auclast  = (10+6)/2*12 + (6+2)/2*12 = 144
#   ae       = 2*100 + 1*150            = 350
#   clr.last = 350/144
d_conc_sec <- data.frame(
  subject = 1,
  PCSPEC = rep(c("plasma", "urine"), times = c(3, 2)),
  time = c(0, 12, 24, 0, 12),
  conc = c(10, 6, 2, 2, 1),
  vol  = c(NA, NA, NA, 100, 150)
)
o_conc_sec <- PKNCAconc(d_conc_sec, conc~time|PCSPEC+subject, volume = "vol")
iv_sec <- data.frame(
  PCSPEC = c("plasma", "urine"),
  start = 0, end = 24,
  interval_id = c("plasma024", NA),
  auclast = c(TRUE, FALSE),
  ae = c(FALSE, TRUE),
  clr.last = c(FALSE, TRUE),
  clr.last_ref = c(NA, "plasma024")
)
o_data_sec <-
  PKNCAdata(
    o_conc_sec, intervals = iv_sec,
    options = list(auc.method = "linear")
  )

# An error raised while one interval is calculated is re-raised by
# pk.nca.intervals() and wrapped again by purrr, so the class that identifies it
# is only reachable through the chain of parents.
condition_classes <- function(cnd) {
  ret <- character(0)
  while (!is.null(cnd)) {
    ret <- c(ret, class(cnd))
    cnd <- cnd$parent
  }
  unique(ret)
}

# 1: pknca_ref() is a validated marker object
test_that("pknca_ref() marks a parameter and validates its input", {
  x <- pknca_ref("aucinf.obs")
  expect_s3_class(x, "pknca_ref")
  expect_equal(x$param, "aucinf.obs")
  expect_true(is_pknca_ref(x))
  expect_false(is_pknca_ref("aucinf.obs"))
  expect_false(is_pknca_ref(NULL))
  expect_error(pknca_ref(NA_character_))
  expect_error(pknca_ref(""))
  expect_error(pknca_ref(c("a", "b")))
})

# 2: the re-registrations do not change which parameters are secondary (the
# pinned list in test-parameter-classification.R must keep passing unchanged)
test_that("declaring pknca_ref() arguments does not change the secondary set", {
  tbl <- pknca_parameter_table()
  expect_equal(
    sort(tbl$parameter[tbl$secondary]),
    sort(c(
      "f.obs", "f.pred", "f.last", "f.int.last", "f.int.all",
      "clr.last", "clr.obs", "clr.pred",
      "clr.last.dn", "clr.obs.dn", "clr.pred.dn",
      "ratio.cmax", "ratio.auclast", "ratio.aucinf.obs", "ratio.aucinf.pred",
      "ratio.aucint.last", "ratio.aucint.all"
    ))
  )
  # A pknca_ref() in the formalsmap is by itself enough to be secondary
  expect_true(
    any(vapply(get.interval.cols()$clr.last$formalsmap, is_pknca_ref, TRUE))
  )
})

# 3: every rule of the interval-specification validation (spec 3.6)
test_that("check.interval.specification() validates interval_id and pointers", {
  # An unknown reference id
  expect_error(
    check.interval.specification(
      data.frame(
        start = 0, end = 24, interval_id = c("a", NA),
        auclast = c(TRUE, FALSE), ae = c(FALSE, TRUE),
        clr.last = c(FALSE, TRUE), clr.last_ref = c(NA, "nowhere")
      )
    ),
    class = "pknca_error_secondary_ref_unknown"
  )
  # A pointer on a row that does not request the parameter
  expect_error(
    check.interval.specification(
      data.frame(
        start = 0, end = 24, interval_id = c("a", NA),
        auclast = c(TRUE, TRUE), ae = c(FALSE, TRUE),
        clr.last = c(FALSE, FALSE), clr.last_ref = c(NA, "a")
      )
    ),
    class = "pknca_error_secondary_ref_without_request"
  )
  # A pointer column for a parameter that is not secondary
  expect_error(
    check.interval.specification(
      data.frame(start = 0, end = 24, cmax = TRUE, cmax_ref = NA_character_)
    ),
    class = "pknca_error_secondary_ref_not_secondary"
  )
  # Identifiers may be any comparable class; factors keep their levels
  checked_factor <-
    check.interval.specification(
      data.frame(
        start = 0, end = 24, auclast = TRUE,
        interval_id = factor("a")
      )
    )
  expect_identical(checked_factor$interval_id, factor("a"))
  checked_factor_ref <-
    check.interval.specification(
      data.frame(
        start = 0, end = 24, interval_id = factor(c("a", NA), levels = "a"),
        auclast = c(TRUE, FALSE), ae = c(FALSE, TRUE),
        clr.last = c(FALSE, TRUE),
        clr.last_ref = factor(c(NA, "a"), levels = "a")
      )
    )
  expect_identical(checked_factor_ref$clr.last_ref, factor(c(NA, "a"), levels = "a"))
  # ... but the id and pointer columns must be comparable to each other
  expect_error(
    check.interval.specification(
      data.frame(
        start = 0, end = 24, interval_id = c("a", NA),
        auclast = c(TRUE, FALSE), ae = c(FALSE, TRUE),
        clr.last = c(FALSE, TRUE), clr.last_ref = c(NA, 1)
      )
    ),
    class = "pknca_error_secondary_ref_class_mismatch"
  )
  expect_error(
    check.interval.specification(
      data.frame(
        start = 0, end = 24, interval_id = factor(c("a", NA), levels = c("a", "b")),
        auclast = c(TRUE, FALSE), ae = c(FALSE, TRUE),
        clr.last = c(FALSE, TRUE),
        clr.last_ref = factor(c(NA, "a"), levels = "a")
      )
    ),
    class = "pknca_error_secondary_ref_class_mismatch"
  )
  # Without an interval_id column the pointer columns must agree among
  # themselves
  expect_error(
    check.interval.specification(
      data.frame(
        start = 0, end = 24, auclast = TRUE, ae = TRUE, aucinf.obs = TRUE,
        clr.last = TRUE, clr.obs = TRUE,
        clr.last_ref = "x", clr.obs_ref = 1
      )
    ),
    class = "pknca_error_secondary_ref_class_mismatch"
  )
  # A column that cannot hold identifiers at all is rejected
  invalid_list_col <- data.frame(start = 0, end = 24, auclast = TRUE)
  invalid_list_col$interval_id <- list("a")
  expect_error(
    check.interval.specification(invalid_list_col),
    class = "pknca_error_secondary_interval_id_invalid"
  )
  # An all-NA logical column is an unfilled column, compatible with anything
  checked <-
    check.interval.specification(
      data.frame(
        start = 0, end = 24, ae = TRUE, auclast = TRUE,
        interval_id = NA, clr.last_ref = NA
      )
    )
  expect_true(all(is.na(checked$interval_id)))
  expect_true(all(is.na(checked$clr.last_ref)))
  # One id must name one interval
  expect_error(
    check.interval.specification(
      data.frame(
        start = c(0, 12), end = 24, interval_id = "a",
        auclast = TRUE
      )
    ),
    class = "pknca_error_secondary_id_conflict"
  )
  # A row may not be its own reference
  expect_error(
    check.interval.specification(
      data.frame(
        start = 0, end = 24, interval_id = "a",
        auclast = TRUE, ae = TRUE, clr.last = TRUE, clr.last_ref = "a"
      )
    ),
    class = "pknca_error_secondary_ref_self",
    regexp = "must reference a different interval"
  )
  # A `_ref` column whose prefix is not a parameter is the user's own data
  expect_no_error(
    check.interval.specification(
      data.frame(start = 0, end = 24, auclast = TRUE, mycol_ref = "anything")
    )
  )
})

# 4: the linkage columns are allowed in an intervals data.frame
test_that("assert_intervals() allows interval_id and pointer columns", {
  o_data_plain <- PKNCAdata(o_conc_sec, intervals = data.frame(start = 0, end = 24, cmax = TRUE))
  expect_no_error(assert_intervals(iv_sec, o_data_plain))
  expect_error(
    assert_intervals(
      data.frame(start = 0, end = 24, cmax = TRUE, clr.last_reff = "a"),
      o_data_plain
    ),
    class = "pknca_error_invalid_interval_columns"
  )
})

# 5: the linked calculation gives the hand-computed value on the home row
test_that("an explicitly linked secondary parameter is calculated", {
  res <- pk.nca(o_data_sec)
  d_res <- as.data.frame(res)
  d_clr <- d_res[d_res$PPTESTCD %in% "clr.last", ]
  expect_equal(nrow(d_clr), 1L)
  expect_equal(d_clr$PPORRES, 350/144)
  expect_equal(d_clr$PCSPEC, "urine")
  expect_equal(d_clr$start, 0)
  expect_equal(d_clr$end, 24)
  # ... from the hand-computed inputs
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "auclast"], 144)
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "ae"], 350)
})

# 5b: the linkage also works when the data have no group columns at all, where
# the home and reference intervals are distinguished only by their times
test_that("a secondary parameter links across intervals of ungrouped data", {
  d_flat <- data.frame(time = c(0, 12, 24), conc = c(2, 1, 0.5), vol = c(100, 150, 200))
  o_flat <- PKNCAconc(d_flat, conc~time, volume = "vol")
  iv_flat <-
    data.frame(
      start = c(0, 12), end = c(12, 24),
      interval_id = c("early", NA),
      auclast = c(TRUE, FALSE),
      ae = c(FALSE, TRUE),
      clr.last = c(FALSE, TRUE),
      clr.last_ref = c(NA, "early")
    )
  o_data_flat <- PKNCAdata(o_flat, intervals = iv_flat, options = list(auc.method = "linear"))
  res <- pk.nca(o_data_flat)
  d_res <- as.data.frame(res)
  # early auclast = (2+1)/2*12 = 18; late ae = 1*150 + 0.5*200 = 250
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "auclast"], 18)
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "ae"], 250)
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "clr.last"], 250/18)
  expect_equal(
    d_res$PPANMETH[d_res$PPTESTCD %in% "clr.last"],
    "Reference interval: 0-12"
  )
})

# 5c: identifiers of any comparable class link intervals; row numbers are as
# good as names
test_that("numeric interval ids link intervals", {
  iv_num <- iv_sec
  iv_num$interval_id <- c(1, NA)
  iv_num$clr.last_ref <- c(NA, 1)
  o_data_num <-
    PKNCAdata(o_conc_sec, intervals = iv_num, options = list(auc.method = "linear"))
  d_res <- as.data.frame(pk.nca(o_data_num))
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "clr.last"], 350/144)
})

# 6: the reference interval is disclosed in PPANMETH by how it differs (the
# interval_id is tracking information, not part of the analysis method)
test_that("PPANMETH names the reference interval and how it differs", {
  res <- pk.nca(o_data_sec)
  d_res <- as.data.frame(res)
  expect_equal(
    d_res$PPANMETH[d_res$PPTESTCD %in% "clr.last"],
    "Reference interval: PCSPEC=plasma, 0-24"
  )
})

# 7: the engine's working copy of the intervals never reaches the user
test_that("the cross-interval expansion is ephemeral", {
  res <- pk.nca(o_data_sec)
  expect_identical(res$data$intervals, check.interval.specification(iv_sec))
  # The home-side `depends` still ran
  d_res <- as.data.frame(res)
  expect_equal(sum(d_res$PPTESTCD %in% "ae"), 1L)
})

# 8: completing a reference interval with the source parameter is silent
test_that("a reference interval gains the source parameter without announcement", {
  iv_silent <- iv_sec
  iv_silent$auclast <- c(FALSE, FALSE)
  expect_warning(
    o_data_silent <-
      PKNCAdata(o_conc_sec, intervals = iv_silent, options = list(auc.method = "linear")),
    class = "pknca_warning_interval_nothing_calculated"
  )
  expect_no_condition(res <- pk.nca(o_data_silent))
  d_res <- as.data.frame(res)
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "clr.last"], 350/144)
  # The machinery result is visible but is not one of the requested parameters
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "auclast"], 144)
  d_requested <- as.data.frame(res, filter_requested = TRUE)
  expect_false("auclast" %in% d_requested$PPTESTCD)
  expect_true("clr.last" %in% d_requested$PPTESTCD)
})

# 9: bioavailability across a crossover is self-consistent with its inputs
test_that("f.obs takes dose and AUC from the reference interval", {
  d_conc_f <- data.frame(
    treatment = rep(c("ref", "test"), each = 5),
    subject = 1,
    time = rep(c(0, 1, 2, 4, 8), 2),
    conc = c(0, 10, 8, 5, 2, 0, 6, 5, 3, 1)
  )
  d_dose_f <- data.frame(treatment = c("ref", "test"), subject = 1, time = 0, dose = c(100, 50))
  o_conc_f <- PKNCAconc(d_conc_f, conc~time|treatment+subject)
  o_dose_f <- PKNCAdose(d_dose_f, dose~time|treatment+subject)
  iv_f <- data.frame(
    treatment = c("ref", "test"),
    start = 0, end = Inf,
    interval_id = c("refprofile", NA),
    aucinf.obs = TRUE,
    totdose = TRUE,
    f.obs = c(FALSE, TRUE),
    f.obs_ref = c(NA, "refprofile")
  )
  o_data_f <- PKNCAdata(o_conc_f, o_dose_f, intervals = iv_f)
  res <- pk.nca(o_data_f)
  d_res <- as.data.frame(res)
  value_of <- function(param, trt) {
    d_res$PPORRES[d_res$PPTESTCD %in% param & d_res$treatment %in% trt]
  }
  expect_equal(
    c(value_of("totdose", "ref"), value_of("totdose", "test")),
    c(100, 50)
  )
  expect_equal(
    value_of("f.obs", "test"),
    (value_of("aucinf.obs", "test")/value_of("totdose", "test")) /
      (value_of("aucinf.obs", "ref")/value_of("totdose", "ref"))
  )
  expect_equal(length(value_of("f.obs", "ref")), 0L)
})

# 10: an exclusion on a source value reaches the secondary result unchanged
test_that("exclusions on the source values carry through the linkage", {
  # Two points after tmax is below the default min.hl.points, so the terminal
  # phase (and with it aucinf.obs) is excluded
  d_conc_x <- data.frame(
    subject = 1,
    PCSPEC = rep(c("plasma", "urine"), times = c(3, 2)),
    time = c(0, 2, 4, 0, 6),
    conc = c(10, 8, 7, 2, 1),
    vol  = c(NA, NA, NA, 100, 150)
  )
  o_conc_x <- PKNCAconc(d_conc_x, conc~time|PCSPEC+subject, volume = "vol")
  iv_x <- data.frame(
    PCSPEC = c("plasma", "urine"),
    start = 0, end = 6,
    interval_id = c("plasma06", NA),
    aucinf.obs = c(TRUE, FALSE),
    ae = c(FALSE, TRUE),
    clr.obs = c(FALSE, TRUE),
    clr.obs_ref = c(NA, "plasma06")
  )
  o_data_x <- PKNCAdata(o_conc_x, intervals = iv_x, options = list(auc.method = "linear"))
  res <- suppressWarnings(pk.nca(o_data_x))
  d_res <- as.data.frame(res)
  exclude_auc <- d_res$exclude[d_res$PPTESTCD %in% "aucinf.obs"]
  expect_false(is.na(exclude_auc))
  expect_match(exclude_auc, "half-life")
  expect_equal(d_res$exclude[d_res$PPTESTCD %in% "clr.obs"], exclude_auc)
  # Every exclusion PKNCA sets during a calculation leaves the value NA, so what
  # crosses the linkage here is the reason rather than a number
  expect_true(is.na(d_res$PPORRES[d_res$PPTESTCD %in% "clr.obs"]))
})

# 11: an explicit link that cannot find its reference instance fails loud
test_that("an explicit link aborts when the reference instance is missing", {
  d_conc_m <-
    rbind(
      d_conc_sec,
      data.frame(
        subject = 2, PCSPEC = "urine", time = c(0, 12), conc = c(2, 1),
        vol = c(100, 150)
      )
    )
  o_conc_m <- PKNCAconc(d_conc_m, conc~time|PCSPEC+subject, volume = "vol")
  o_data_m <- PKNCAdata(o_conc_m, intervals = iv_sec, options = list(auc.method = "linear"))
  err <- expect_error(pk.nca(o_data_m), class = "pknca_error_secondary_ref_value_missing")
  expect_match(conditionMessage(err), "clr.last", fixed = TRUE)
  expect_match(conditionMessage(err), "auclast", fixed = TRUE)
  expect_match(conditionMessage(err), "plasma024", fixed = TRUE)
  expect_match(conditionMessage(err), "subject=2", fixed = TRUE)
})

# 12: a reference that matches more than one result is an error, not a guess
test_that("an ambiguous reference lookup aborts", {
  iv_dup <- rbind(iv_sec, transform(iv_sec[1, ], interval_id = NA_character_))
  o_data_dup <- PKNCAdata(o_conc_sec, intervals = iv_dup, options = list(auc.method = "linear"))
  expect_error(
    pk.nca(o_data_dup),
    class = "pknca_error_secondary_ambiguous_reference"
  )
})

# 13: a secondary parameter with nothing to reference says what to set
test_that("a secondary parameter with no reference says how to give one", {
  d_conc <- data.frame(conc = 2^(0:-5), time = 0:5)
  o_conc <- PKNCAconc(d_conc, conc~time)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, f.obs = TRUE))
  err <-
    rlang::catch_cnd(
      suppressMessages(suppressWarnings(pk.nca(o_data))),
      classes = "error"
    )
  expect_true("pknca_error_secondary_needs_ref" %in% condition_classes(err))
  expect_match(conditionMessage(err), "f.obs_ref", fixed = TRUE)
  expect_match(conditionMessage(err), "group_ref", fixed = TRUE)
})

# 14: the historical same-interval renal clearance keeps working
test_that("clr requested with its AUC in the same interval keeps calculating", {
  d_leg <- data.frame(subject = 1, time = c(0, 12, 24), conc = c(2, 1, 0.5), vol = c(100, 150, 200))
  o_leg <- PKNCAconc(d_leg, conc~time|subject, volume = "vol")
  iv_leg <- data.frame(start = 0, end = 24, ae = TRUE, auclast = TRUE, clr.last = TRUE)
  o_data_leg <- PKNCAdata(o_leg, intervals = iv_leg, options = list(auc.method = "linear"))
  res <- pk.nca(o_data_leg)
  d_res <- as.data.frame(res)
  # ae = 2*100 + 1*150 + 0.5*200 = 450; auclast = 3/2*12 + 1.5/2*12 = 27
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "ae"], 450)
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "auclast"], 27)
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "clr.last"], 450/27)
})

# 15: the same-interval fallback may not make test and reference the same value
test_that("f.obs is not resolved from its own interval", {
  d_conc_f <- data.frame(treatment = "test", subject = 1, time = c(0, 1, 2, 4, 8),
                         conc = c(0, 6, 5, 3, 1))
  d_dose_f <- data.frame(treatment = "test", subject = 1, time = 0, dose = 50)
  o_conc_f <- PKNCAconc(d_conc_f, conc~time|treatment+subject)
  o_dose_f <- PKNCAdose(d_dose_f, dose~time|treatment+subject)
  o_data_f <-
    PKNCAdata(
      o_conc_f, o_dose_f,
      intervals = data.frame(start = 0, end = Inf, aucinf.obs = TRUE, totdose = TRUE, f.obs = TRUE)
    )
  err <- rlang::catch_cnd(pk.nca(o_data_f), classes = "error")
  expect_true("pknca_error_secondary_needs_ref" %in% condition_classes(err))
})

# 16: clr without its AUC used to divide by the request flag and give Inf
test_that("clr without its AUC and without a reference is an error", {
  d_leg <- data.frame(subject = 1, time = c(0, 12, 24), conc = c(2, 1, 0.5), vol = c(100, 150, 200))
  o_leg <- PKNCAconc(d_leg, conc~time|subject, volume = "vol")
  o_data_inf <-
    PKNCAdata(
      o_leg, intervals = data.frame(start = 0, end = 24, ae = TRUE, clr.last = TRUE),
      options = list(auc.method = "linear")
    )
  err <- rlang::catch_cnd(pk.nca(o_data_inf), classes = "error")
  expect_true("pknca_error_secondary_needs_ref" %in% condition_classes(err))
})

# 17: a secondary result takes the units of its own (home) group
test_that("a linked secondary result is given units", {
  o_conc_u <-
    PKNCAconc(
      d_conc_sec, conc~time|PCSPEC+subject, volume = "vol",
      concu = "ng/mL", timeu = "hr", amountu = "mg"
    )
  o_data_u <- PKNCAdata(o_conc_u, intervals = iv_sec, options = list(auc.method = "linear"))
  res <- pk.nca(o_data_u)
  d_res <- as.data.frame(res)
  expect_equal(d_res$PPORRESU[d_res$PPTESTCD %in% "clr.last"], "mg/(hr*ng/mL)")
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "clr.last"], 350/144)
})

# 17b: group-stratified units that differ between the two sides are announced
# (PR 4 replaces the warning with conversion of the reference-side value)
test_that("units differing between the home and reference groups warn", {
  d_conc_u <- d_conc_sec
  d_conc_u$cu <- ifelse(d_conc_u$PCSPEC %in% "plasma", "ng/mL", "mg/L")
  d_conc_u$tu <- "hr"
  d_conc_u$au <- "mg"
  o_conc_u <-
    PKNCAconc(
      d_conc_u, conc~time|PCSPEC+subject, volume = "vol",
      concu = "cu", timeu = "tu", amountu = "au"
    )
  o_data_u <- PKNCAdata(o_conc_u, intervals = iv_sec, options = list(auc.method = "linear"))
  expect_warning(pk.nca(o_data_u), class = "pknca_warning_secondary_units")
})

# 18: a linked secondary parameter is summarized like any other
test_that("summary() reports the secondary parameter on its home row", {
  res <- pk.nca(o_data_sec)
  d_summary <- as.data.frame(summary(res))
  expect_true("clr.last" %in% names(d_summary))
  value_urine <- d_summary$clr.last[d_summary$PCSPEC %in% "urine"]
  expect_equal(value_urine, "2.43")
  expect_false(value_urine %in% c("NC", "."))
})

# 19: sparse data cannot yet supply a cross-interval reference
test_that("secondary parameters abort with sparse data", {
  d_sparse <-
    data.frame(
      id = rep(1:6, each = 2),
      time = rep(c(1, 4), 6),
      conc = c(1.4, 0.8, 1.6, 0.9, 1.2, 0.7, 1.5, 0.85, 1.3, 0.75, 1.45, 0.82),
      vol = 100
    )
  o_sparse <- PKNCAconc(d_sparse, conc~time|id, sparse = TRUE, volume = "vol")
  iv_sparse <-
    data.frame(
      start = 0, end = 8,
      interval_id = c("sp1", NA),
      auclast = c(TRUE, FALSE),
      ae = c(FALSE, TRUE),
      clr.last = c(FALSE, TRUE),
      clr.last_ref = c(NA, "sp1")
    )
  o_data_sparse <- PKNCAdata(o_sparse, intervals = iv_sparse)
  expect_error(
    pk.nca(o_data_sparse),
    class = "pknca_error_secondary_sparse_unsupported"
  )
})

# A malformed secondary registration is reported when the parameter is used
test_that("secondary_param_info() rejects registrations it cannot calculate", {
  local_interval_cols()
  fn_name <- "pknca_test_secondary_fun_"
  assign(fn_name, function(other, reference) other/reference, envir = .GlobalEnv)
  withr::defer(rm(list = fn_name, envir = .GlobalEnv))
  # A formal that is neither in formalsmap nor a parameter name
  add.interval.col(
    "pknca_test_secondary_col_",
    FUN = fn_name,
    unit_type = "fraction",
    pretty_name = "Test: secondary registration",
    desc = "Coverage test for registration checks",
    formalsmap = list(reference = pknca_ref("cmax")),
    depends = "cmax"
  )
  expect_error(
    PKNCA:::secondary_param_info("pknca_test_secondary_col_"),
    class = "pknca_error_secondary_registration",
    regexp = "other"
  )
  # A pknca_ref() target that is not a registered parameter
  add.interval.col(
    "pknca_test_secondary_col_",
    FUN = fn_name,
    unit_type = "fraction",
    pretty_name = "Test: secondary registration",
    desc = "Coverage test for registration checks",
    formalsmap = list(other = "cmax", reference = pknca_ref("nosuchparam")),
    depends = "cmax"
  )
  expect_error(
    PKNCA:::secondary_param_info("pknca_test_secondary_col_"),
    class = "pknca_error_secondary_target_unregistered",
    regexp = "nosuchparam"
  )
  # A home argument that is not listed in `depends`
  add.interval.col(
    "pknca_test_secondary_col_",
    FUN = fn_name,
    unit_type = "fraction",
    pretty_name = "Test: secondary registration",
    desc = "Coverage test for registration checks",
    formalsmap = list(other = "cmax", reference = pknca_ref("cmax"))
  )
  expect_error(
    PKNCA:::secondary_param_info("pknca_test_secondary_col_"),
    class = "pknca_error_secondary_registration",
    regexp = "depends"
  )
})

# The home-side wording of the missing-value error (defensive in the engine,
# where `depends` guarantees the home value for an explicit link)
test_that("stop_secondary_value_missing() names the interval a value is missing from", {
  err_home <-
    expect_error(
      PKNCA:::stop_secondary_value_missing(
        "clr.last", "ae", "plasma024", data.frame(subject = 1), side = "home"
      ),
      class = "pknca_error_secondary_ref_value_missing"
    )
  expect_match(conditionMessage(err_home), "from this interval", fixed = TRUE)
  expect_false(grepl("plasma024", conditionMessage(err_home), fixed = TRUE))
})

# Duplicate home rows make the home-side lookup ambiguous, not silently doubled
test_that("a duplicated home interval row is an ambiguity error", {
  iv_home_dup <- rbind(iv_sec, iv_sec[2, ])
  o_data_dup <-
    PKNCAdata(o_conc_sec, intervals = iv_home_dup, options = list(auc.method = "linear"))
  expect_error(
    pk.nca(o_data_dup),
    class = "pknca_error_secondary_ambiguous_reference"
  )
})

# A home interval with no data produces no secondary row and no error; the
# per-interval no-data warning is the only signal
test_that("a linked interval without data is skipped like any other empty interval", {
  d_flat <- data.frame(time = c(0, 6, 12), conc = c(2, 1, 0.5), vol = c(100, 150, 200))
  o_flat <- PKNCAconc(d_flat, conc~time, volume = "vol")
  iv_nodata <-
    data.frame(
      start = c(0, 30), end = c(12, 40),
      interval_id = c("early", NA),
      auclast = c(TRUE, FALSE),
      ae = c(FALSE, TRUE),
      clr.last = c(FALSE, TRUE),
      clr.last_ref = c(NA, "early")
    )
  o_data_nodata <-
    PKNCAdata(o_flat, intervals = iv_nodata, options = list(auc.method = "linear"))
  expect_warning(
    res <- pk.nca(o_data_nodata),
    class = "pknca_warning_no_data_for_interval"
  )
  d_res <- as.data.frame(res)
  expect_false("clr.last" %in% d_res$PPTESTCD)
  expect_true("auclast" %in% d_res$PPTESTCD)
})

# Removing a secondary parameter also removes its reference pointer, so the
# edited intervals still validate
test_that("interval_remove_param() clears the pointer of a removed secondary parameter", {
  edited <- interval_remove_param(iv_sec, param = "clr.last")
  expect_false(any(vapply(X = edited$clr.last, FUN = isTRUE, FUN.VALUE = TRUE)))
  expect_identical(edited$clr.last_ref, rep(NA_character_, nrow(edited)))
  expect_no_error(check.interval.specification(edited))
  # Removing an unrelated parameter leaves the linkage alone
  kept <- interval_remove_param(iv_sec, param = "ae")
  expect_identical(kept$clr.last_ref, iv_sec$clr.last_ref)
  expect_no_error(check.interval.specification(kept))
})

# The authoring API, the ratio parameters, and the bioavailability bases ------

# The hero-table intervals without the linkage that interval_add_secondary()
# writes
iv_sec_bare <-
  data.frame(
    PCSPEC = c("plasma", "urine"),
    start = 0, end = 24,
    auclast = c(TRUE, FALSE),
    ae = c(FALSE, TRUE)
  )

# The crossover fixture of PR 1 test 9, with `auc.method = "linear"` so that the
# trapezoids are hand-computable:
#   auclast(ref)  = (0+10)/2*1 + (10+8)/2*1 + (8+5)/2*2 + (5+2)/2*4 = 41
#   auclast(test) = (0+6)/2*1  + (6+5)/2*1  + (5+3)/2*2 + (3+1)/2*4 = 24.5
d_conc_cross <-
  data.frame(
    treatment = rep(c("ref", "test"), each = 5),
    subject = 1,
    time = rep(c(0, 1, 2, 4, 8), 2),
    conc = c(0, 10, 8, 5, 2, 0, 6, 5, 3, 1)
  )
d_dose_cross <-
  data.frame(treatment = c("ref", "test"), subject = 1, time = 0, dose = c(100, 50))
o_conc_cross <- PKNCAconc(d_conc_cross, conc~time|treatment+subject)
o_dose_cross <- PKNCAdose(d_dose_cross, dose~time|treatment+subject)

# The parameters PR 2 registers
new_secondary_params <-
  c(
    paste0(
      "ratio.",
      c("cmax", "auclast", "aucinf.obs", "aucinf.pred", "aucint.last", "aucint.all")
    ),
    "f.pred", "f.last", "f.int.last", "f.int.all"
  )

# 4.4.1: the ratio calculation itself
test_that("pk.calc.ratio() divides the test value by the reference value", {
  expect_equal(pk.calc.ratio(10, 20), 0.5)
  expect_equal(pk.calc.ratio(3, 1.5), 2)
  # A ratio to a reference that is not above zero is not interpretable
  expect_equal(pk.calc.ratio(10, 0), NA_real_)
  expect_equal(pk.calc.ratio(10, -5), NA_real_)
  expect_equal(pk.calc.ratio(10, NA_real_), NA_real_)
  expect_equal(pk.calc.ratio(NA_real_, 20), NA_real_)
})

# 4.4.2: the helper writes the hand-written specification
test_that("interval_add_secondary() writes the linkage of the hand-written intervals", {
  expected <- iv_sec
  expected$interval_id <- c("ref1", NA)
  expected$clr.last_ref <- c(NA, "ref1")
  expect_equal(
    interval_add_secondary(
      iv_sec_bare, param = "clr.last", reference = data.frame(PCSPEC = "plasma")
    ),
    check.interval.specification(expected)
  )
  # A named list is coerced for convenience
  expect_equal(
    interval_add_secondary(
      iv_sec_bare, param = "clr.last", reference = list(PCSPEC = "plasma")
    ),
    check.interval.specification(expected)
  )
  # Linking what is already linked the same way changes nothing
  expect_equal(
    interval_add_secondary(
      check.interval.specification(expected), param = "clr.last",
      reference = data.frame(PCSPEC = "plasma")
    ),
    check.interval.specification(expected)
  )
  # ... and the PKNCAdata method edits the object's own intervals
  o_data_bare <-
    PKNCAdata(o_conc_sec, intervals = iv_sec_bare, options = list(auc.method = "linear"))
  o_data_linked <-
    interval_add_secondary(
      o_data_bare, param = "clr.last", reference = data.frame(PCSPEC = "plasma")
    )
  expect_s3_class(o_data_linked, "PKNCAdata")
  expect_equal(o_data_linked$intervals, check.interval.specification(expected))
  d_res <- as.data.frame(pk.nca(o_data_linked))
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "clr.last"], 350/144)
})

# 4.4.3: a named identifier reproduces the hand-written fixture exactly
test_that("interval_add_secondary() uses the requested interval_id", {
  expect_equal(
    interval_add_secondary(
      iv_sec_bare, param = "clr.last", reference = data.frame(PCSPEC = "plasma"),
      ref_id = "plasma024"
    ),
    check.interval.specification(iv_sec)
  )
})

# 4.4.4: a reference interval that does not exist yet is created
test_that("interval_add_secondary() creates the reference interval it needs", {
  iv_urine <- data.frame(PCSPEC = "urine", start = 0, end = 24, ae = TRUE)
  expect_message(
    iv_created <-
      interval_add_secondary(
        iv_urine, param = "clr.last", reference = data.frame(PCSPEC = "plasma")
      ),
    class = "pknca_message_secondary_created_interval"
  )
  expect_equal(nrow(iv_created), 2L)
  expect_equal(iv_created$PCSPEC, c("urine", "plasma"))
  expect_equal(iv_created$interval_id, c(NA, "ref1"))
  expect_equal(iv_created$clr.last_ref, c("ref1", NA))
  # The created interval calculates the source parameter and nothing else
  expect_equal(iv_created$auclast, c(FALSE, TRUE))
  expect_equal(iv_created$ae, c(TRUE, FALSE))
  expect_equal(iv_created$clr.last, c(TRUE, FALSE))
  o_data_created <-
    PKNCAdata(o_conc_sec, intervals = iv_created, options = list(auc.method = "linear"))
  d_res <- as.data.frame(pk.nca(o_data_created))
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "clr.last"], 350/144)
  # The renal clearance wrapper is the same call with the parameter filled in
  expect_message(
    iv_wrapped <-
      interval_add_renal_clearance(
        data.frame(PCSPEC = "urine", start = 0, end = 24, ae = TRUE),
        reference = data.frame(PCSPEC = "plasma"), param = "clr.last"
      ),
    class = "pknca_message_secondary_created_interval"
  )
  expect_equal(iv_wrapped, iv_created)
})

# Each interval keeps its own reference, so a created reference follows the
# times of the interval that needs it
test_that("interval_add_secondary() creates one reference per test interval", {
  iv_windows <- data.frame(PCSPEC = "urine", start = c(0, 24), end = c(24, 48), ae = TRUE)
  expect_message(
    iv_linked <-
      interval_add_secondary(
        iv_windows, param = "clr.last", reference = data.frame(PCSPEC = "plasma")
      ),
    class = "pknca_message_secondary_created_interval"
  )
  expect_equal(nrow(iv_linked), 4L)
  expect_equal(iv_linked$PCSPEC, c("urine", "urine", "plasma", "plasma"))
  expect_equal(iv_linked$start, c(0, 24, 0, 24))
  expect_equal(iv_linked$interval_id, c(NA, NA, "ref1", "ref2"))
  expect_equal(iv_linked$clr.last_ref, c("ref1", "ref2", NA, NA))
})

# A created reference row is a new interval:  it carries the columns of the
# intervals it was built from but none of their bookkeeping
test_that("a created reference interval takes no identifier or imputation of its own", {
  iv_ids <-
    data.frame(
      PCSPEC = "urine", start = 0, end = 24, interval_id = "urine024",
      impute = "start_conc0", note = "collection", ae = TRUE
    )
  expect_message(
    iv_created <-
      interval_add_secondary(
        iv_ids, param = "clr.last", reference = data.frame(PCSPEC = "plasma")
      ),
    class = "pknca_message_secondary_created_interval"
  )
  expect_equal(iv_created$interval_id, c("urine024", "ref1"))
  expect_equal(iv_created$clr.last_ref, c("ref1", NA))
  # The whole-dataset imputation applies to the created row instead
  expect_equal(iv_created$impute, c("start_conc0", NA))
  # A column of the user's own describes the interval, so it is carried over
  expect_equal(iv_created$note, c("collection", "collection"))
})

# 4.4.5: every way the specification can be unusable
test_that("interval_add_secondary() rejects what it cannot link", {
  # A parameter that does not need a second profile
  expect_error(
    interval_add_secondary(
      iv_sec_bare, param = "cmax", reference = data.frame(PCSPEC = "plasma")
    ),
    class = "pknca_error_secondary_not_secondary_param",
    regexp = "interval_add_param"
  )
  # PR 3 replaces this with the automatic reference finder
  expect_error(
    interval_add_secondary(iv_sec_bare, param = "clr.last"),
    regexp = "reference must be given"
  )
  # A reference column that is not part of the intervals
  expect_error(
    interval_add_secondary(
      iv_sec_bare, param = "clr.last", reference = data.frame(nosuchcolumn = "plasma")
    ),
    class = "pknca_error_interval_target_groups_cols",
    regexp = "nosuchcolumn"
  )
  # ... including a parameter request column, which does not identify an
  # interval
  expect_error(
    interval_add_secondary(
      iv_sec_bare, param = "clr.last", reference = data.frame(auclast = TRUE)
    ),
    class = "pknca_error_interval_target_groups_cols"
  )
  # An interval that already names a different reference is left alone
  iv_pointed <-
    data.frame(
      PCSPEC = c("plasma", "serum", "urine"),
      start = 0, end = 24,
      interval_id = c("plasma024", "serum024", NA),
      auclast = c(TRUE, TRUE, FALSE),
      ae = c(FALSE, FALSE, TRUE),
      clr.last = c(FALSE, FALSE, TRUE),
      clr.last_ref = c(NA, NA, "serum024")
    )
  expect_warning(
    iv_kept <-
      interval_add_secondary(
        iv_pointed, param = "clr.last", reference = data.frame(PCSPEC = "plasma"),
        target_groups = data.frame(PCSPEC = "urine")
      ),
    class = "pknca_warning_secondary_ref_exists"
  )
  expect_equal(iv_kept$clr.last_ref, c(NA, NA, "serum024"))
  # More than one reference interval and no way to choose between them
  iv_two_plasma <-
    data.frame(
      PCSPEC = c("plasma", "plasma", "urine"),
      start = c(0, 24, 0), end = c(24, 48, 48),
      auclast = c(TRUE, TRUE, FALSE),
      ae = c(FALSE, FALSE, TRUE)
    )
  expect_error(
    interval_add_secondary(
      iv_two_plasma, param = "clr.last", reference = data.frame(PCSPEC = "plasma")
    ),
    class = "pknca_error_secondary_ref_ambiguous_spec",
    regexp = "start"
  )
  # ... and `ref_id` names exactly one of them, so it cannot be used either
  expect_error(
    interval_add_secondary(
      iv_two_plasma, param = "clr.last", reference = data.frame(PCSPEC = "plasma"),
      ref_id = "plasma"
    ),
    class = "pknca_error_secondary_ref_ambiguous_spec",
    regexp = "ref_id"
  )
  # Nothing is left to calculate the parameter on
  expect_warning(
    iv_unchanged <-
      interval_add_secondary(
        iv_sec_bare, param = "clr.last", reference = data.frame(PCSPEC = "plasma"),
        target_groups = data.frame(PCSPEC = "nothing")
      ),
    class = "pknca_warning_interval_no_target_rows"
  )
  expect_identical(iv_unchanged, iv_sec_bare)
})

# Identifiers may be of any comparable class, so a generated one has to match
# what the intervals already use
test_that("interval_add_secondary() generates ids matching the existing class", {
  iv_numeric <- iv_sec_bare
  iv_numeric$interval_id <- c(7, NA)
  expect_equal(
    interval_add_secondary(
      iv_numeric, param = "clr.last", reference = data.frame(PCSPEC = "urine")
    )$clr.last_ref,
    c(8, NA)
  )
  iv_numeric_empty <- iv_sec_bare
  iv_numeric_empty$interval_id <- c(NA_real_, NA_real_)
  expect_equal(
    interval_add_secondary(
      iv_numeric_empty, param = "clr.last", reference = data.frame(PCSPEC = "plasma")
    )$interval_id,
    c(1, NA)
  )
  iv_factor <- iv_sec_bare
  iv_factor$interval_id <- factor(c("ref1", NA), levels = "ref1")
  iv_factor$auclast <- c(TRUE, TRUE)
  linked_factor <-
    interval_add_secondary(
      iv_factor, param = "clr.last", reference = data.frame(PCSPEC = "urine")
    )
  expect_identical(levels(linked_factor$interval_id), c("ref1", "ref2"))
  expect_identical(
    linked_factor$clr.last_ref,
    factor(c("ref2", NA), levels = c("ref1", "ref2"))
  )
  # A generated level has to reach the pointer columns that already exist, or
  # the linkage columns stop being comparable
  iv_factor_pointed <- iv_factor
  iv_factor_pointed$aucinf.obs <- c(TRUE, FALSE)
  iv_factor_pointed$clr.obs <- c(FALSE, TRUE)
  iv_factor_pointed$clr.obs_ref <- factor(c(NA, "ref1"), levels = "ref1")
  linked_both <-
    interval_add_secondary(
      iv_factor_pointed, param = "clr.last", reference = data.frame(PCSPEC = "urine")
    )
  expect_identical(
    linked_both$clr.obs_ref,
    factor(c(NA, "ref1"), levels = c("ref1", "ref2"))
  )
  expect_no_error(check.interval.specification(linked_both))
  # An unfilled logical column is not an identifier of any class yet
  iv_unfilled <- iv_sec_bare
  iv_unfilled$interval_id <- NA
  iv_unfilled$clr.last_ref <- NA
  iv_linked_unfilled <-
    interval_add_secondary(
      iv_unfilled, param = "clr.last", reference = data.frame(PCSPEC = "plasma")
    )
  expect_equal(iv_linked_unfilled$interval_id, c("ref1", NA))
  expect_equal(iv_linked_unfilled$clr.last_ref, c(NA, "ref1"))
})

# 4.4.6: accumulation ratio across two dosing intervals
test_that("interval_add_accumulation_ratio() links the later interval to the first", {
  d_conc_acc <-
    data.frame(
      subject = 1,
      time = c(0, 6, 12, 24, 30, 36, 48),
      conc = c(0, 8, 5, 2, 12, 8, 3)
    )
  d_dose_acc <- data.frame(subject = 1, time = c(0, 24), dose = 100)
  o_conc_acc <- PKNCAconc(d_conc_acc, conc~time|subject)
  o_dose_acc <- PKNCAdose(d_dose_acc, dose~time|subject)
  iv_acc <-
    interval_add_accumulation_ratio(
      data.frame(start = c(0, 24), end = c(24, 48), aucint.last = TRUE),
      ref_start = 0, ref_end = 24
    )
  expect_equal(iv_acc$interval_id, c("ref1", NA))
  expect_equal(iv_acc$ratio.aucint.last, c(FALSE, TRUE))
  expect_equal(iv_acc$ratio.aucint.last_ref, c(NA, "ref1"))
  o_data_acc <-
    PKNCAdata(
      o_conc_acc, o_dose_acc, intervals = iv_acc,
      options = list(auc.method = "linear")
    )
  d_res <- as.data.frame(pk.nca(o_data_acc))
  auc_first <- d_res$PPORRES[d_res$PPTESTCD %in% "aucint.last" & d_res$start %in% 0]
  auc_second <- d_res$PPORRES[d_res$PPTESTCD %in% "aucint.last" & d_res$start %in% 24]
  d_ratio <- d_res[d_res$PPTESTCD %in% "ratio.aucint.last", ]
  expect_equal(nrow(d_ratio), 1L)
  expect_equal(d_ratio$PPORRES, auc_second/auc_first)
  expect_equal(d_ratio$start, 24)
  # No group column differs, so only the reference times are reported
  expect_equal(d_ratio$PPANMETH, "Reference interval: 0-24")
  # ... and it is summarized on the interval that requested it
  d_summary <- as.data.frame(summary(pk.nca(o_data_acc)))
  expect_equal(d_summary$ratio.aucint.last, c(".", "1.60"))
})

# 4.4.7: metabolite ratio across an analyte group
test_that("interval_add_metabolite_ratio() links a metabolite to its parent", {
  d_conc_met <-
    data.frame(
      subject = 1,
      Analyte = rep(c("parent", "metabolite"), each = 5),
      time = rep(c(0, 1, 2, 4, 8), 2),
      conc = c(0, 10, 8, 5, 2, 0, 4, 3.5, 2, 0.8)
    )
  o_conc_met <- PKNCAconc(d_conc_met, conc~time|Analyte+subject)
  iv_met <-
    interval_add_metabolite_ratio(
      data.frame(
        Analyte = c("parent", "metabolite"), start = 0, end = Inf, aucinf.obs = TRUE
      ),
      reference = data.frame(Analyte = "parent")
    )
  expect_equal(iv_met$interval_id, c("ref1", NA))
  expect_equal(iv_met$ratio.aucinf.obs_ref, c(NA, "ref1"))
  o_data_met <-
    PKNCAdata(o_conc_met, intervals = iv_met, options = list(auc.method = "linear"))
  d_res <- as.data.frame(pk.nca(o_data_met))
  auc_of <- function(analyte) {
    d_res$PPORRES[d_res$PPTESTCD %in% "aucinf.obs" & d_res$Analyte %in% analyte]
  }
  d_ratio <- d_res[d_res$PPTESTCD %in% "ratio.aucinf.obs", ]
  expect_equal(nrow(d_ratio), 1L)
  expect_equal(d_ratio$Analyte, "metabolite")
  expect_equal(d_ratio$PPORRES, auc_of("metabolite")/auc_of("parent"))
  expect_equal(d_ratio$PPANMETH, "Reference interval: Analyte=parent, 0-Inf")
  # An exclusion on the parent AUC marks the ratio with the same reason
  d_conc_met_x <-
    rbind(
      data.frame(subject = 1, Analyte = "parent", time = c(0, 1, 2), conc = c(0, 10, 8)),
      data.frame(
        subject = 1, Analyte = "metabolite", time = c(0, 1, 2, 4, 8),
        conc = c(0, 4, 3.5, 2, 0.8)
      )
    )
  o_conc_met_x <- PKNCAconc(d_conc_met_x, conc~time|Analyte+subject)
  d_res_x <-
    as.data.frame(suppressWarnings(pk.nca(
      PKNCAdata(o_conc_met_x, intervals = iv_met, options = list(auc.method = "linear"))
    )))
  exclude_parent <-
    d_res_x$exclude[d_res_x$PPTESTCD %in% "aucinf.obs" & d_res_x$Analyte %in% "parent"]
  expect_false(is.na(exclude_parent))
  expect_match(exclude_parent, "half-life")
  expect_equal(d_res_x$exclude[d_res_x$PPTESTCD %in% "ratio.aucinf.obs"], exclude_parent)
  expect_true(is.na(d_res_x$PPORRES[d_res_x$PPTESTCD %in% "ratio.aucinf.obs"]))
})

# 4.4.8: bioavailability is the ratio of the dose-normalized AUCs
test_that("f.obs equals the ratio of the dose-normalized AUCinf,obs", {
  iv_f <-
    interval_add_secondary(
      data.frame(
        treatment = c("ref", "test"), start = 0, end = Inf,
        aucinf.obs = TRUE, aucinf.obs.dn = TRUE, totdose = TRUE
      ),
      param = "f.obs", reference = data.frame(treatment = "ref")
    )
  o_data_f <-
    PKNCAdata(
      o_conc_cross, o_dose_cross, intervals = iv_f,
      options = list(auc.method = "linear")
    )
  d_res <- as.data.frame(pk.nca(o_data_f))
  dn_of <- function(trt) {
    d_res$PPORRES[d_res$PPTESTCD %in% "aucinf.obs.dn" & d_res$treatment %in% trt]
  }
  expect_equal(
    d_res$PPORRES[d_res$PPTESTCD %in% "f.obs"],
    dn_of("test")/dn_of("ref")
  )
})

# 4.4.9: the AUC basis a bioavailability is built on is the user's choice
test_that("the bioavailability basis variants use their own AUC", {
  basis_of <-
    c(
      f.last = "auclast", f.pred = "aucinf.pred",
      f.int.last = "aucint.last", f.int.all = "aucint.all"
    )
  iv_basis <- data.frame(treatment = c("ref", "test"), start = 0, end = Inf, totdose = TRUE)
  iv_basis[unname(basis_of)] <- TRUE
  for (current_param in names(basis_of)) {
    iv_basis <-
      interval_add_secondary(
        iv_basis, param = current_param, reference = data.frame(treatment = "ref")
      )
  }
  # One reference interval serves every link
  expect_equal(iv_basis$interval_id, c("ref1", NA))
  for (current_param in names(basis_of)) {
    expect_equal(
      iv_basis[[paste0(current_param, "_ref")]], c(NA, "ref1"),
      info = current_param
    )
  }
  o_data_basis <-
    PKNCAdata(
      o_conc_cross, o_dose_cross, intervals = iv_basis,
      options = list(auc.method = "linear")
    )
  d_res <- as.data.frame(pk.nca(o_data_basis))
  value_of <- function(param, trt) {
    d_res$PPORRES[d_res$PPTESTCD %in% param & d_res$treatment %in% trt]
  }
  # The hand-computed trapezoids and the given doses
  expect_equal(value_of("auclast", "ref"), 41)
  expect_equal(value_of("auclast", "test"), 24.5)
  expect_equal(c(value_of("totdose", "ref"), value_of("totdose", "test")), c(100, 50))
  expect_equal(value_of("f.last", "test"), (24.5/50)/(41/100))
  expect_equal(length(value_of("f.last", "ref")), 0L)
  for (current_param in names(basis_of)) {
    expect_equal(
      value_of(current_param, "test"),
      (value_of(basis_of[[current_param]], "test")/50) /
        (value_of(basis_of[[current_param]], "ref")/100),
      info = current_param
    )
  }
})

# Each ratio compares the parameter it is named for, and no other
test_that("every ratio parameter divides its own basis", {
  ratio_bases <-
    c("cmax", "auclast", "aucinf.obs", "aucinf.pred", "aucint.last", "aucint.all")
  iv_ratio <- data.frame(treatment = c("ref", "test"), start = 0, end = Inf)
  iv_ratio[ratio_bases] <- TRUE
  for (current_basis in ratio_bases) {
    iv_ratio <-
      interval_add_secondary(
        iv_ratio, param = paste0("ratio.", current_basis),
        reference = data.frame(treatment = "ref")
      )
  }
  o_data_ratio <-
    PKNCAdata(
      o_conc_cross, o_dose_cross, intervals = iv_ratio,
      options = list(auc.method = "linear")
    )
  d_res <- as.data.frame(pk.nca(o_data_ratio))
  value_of <- function(param, trt) {
    d_res$PPORRES[d_res$PPTESTCD %in% param & d_res$treatment %in% trt]
  }
  # Cmax is 10 and 6, so the ratio is exactly 0.6
  expect_equal(value_of("ratio.cmax", "test"), 0.6)
  for (current_basis in ratio_bases) {
    expect_equal(
      value_of(paste0("ratio.", current_basis), "test"),
      value_of(current_basis, "test")/value_of(current_basis, "ref"),
      info = current_basis
    )
    # The ratio is reported on the interval that requested it, not the reference
    expect_equal(
      length(value_of(paste0("ratio.", current_basis), "ref")), 0L,
      info = current_basis
    )
  }
})

# 4.4.10: the new parameters are summarized like the ratios they are
test_that("the ratio and bioavailability variants are summarized geometrically", {
  summary_settings <- PKNCA.set.summary()
  for (current_param in new_secondary_params) {
    expect_equal(
      summary_settings[[current_param]]$description,
      "geometric mean and geometric coefficient of variation",
      info = current_param
    )
    # Compared by behavior rather than function identity, which coverage
    # instrumentation would break; the values distinguish the geometric mean
    # and CV from their arithmetic counterparts and from the median
    expect_equal(
      summary_settings[[current_param]]$point(c(1, 4, 32)),
      business.geomean(c(1, 4, 32)),
      info = current_param
    )
    expect_equal(
      summary_settings[[current_param]]$spread(c(1, 4, 32)),
      business.geocv(c(1, 4, 32)),
      info = current_param
    )
  }
})

# 4.4.11: SDTM allows 40 characters for a parameter description
test_that("the new parameter descriptions fit in an SDTM submission", {
  all_intervals <- get.interval.cols()
  for (current_param in new_secondary_params) {
    expect_lte(nchar(all_intervals[[current_param]]$desc), 40, label = current_param)
  }
})

# A created spot-sample reference spans the excreta collections whole:  a
# collection beginning inside the interval contributes its full amount, so the
# paired plasma AUC must cover its full duration
test_that("a created reference interval spans the collections' durations", {
  d_conc_span <- data.frame(
    subject = 1,
    PCSPEC = rep(c("plasma", "urine"), times = c(4, 2)),
    time = c(0, 12, 24, 36, 0, 12),
    conc = c(10, 6, 4, 2, 2, 1),
    vol  = c(NA, NA, NA, NA, 100, 150),
    dur  = c(0, 0, 0, 0, 12, 24)
  )
  o_conc_span <-
    PKNCAconc(d_conc_span, conc~time|PCSPEC+subject, volume = "vol", duration = "dur")
  iv_span <- data.frame(PCSPEC = "urine", start = 0, end = 24, ae = TRUE)
  o_data_span <-
    PKNCAdata(o_conc_span, intervals = iv_span, options = list(auc.method = "linear"))
  expect_message(
    o_data_linked <-
      interval_add_renal_clearance(
        o_data_span, reference = data.frame(PCSPEC = "plasma"), param = "clr.last"
      ),
    class = "pknca_message_secondary_created_interval"
  )
  created <- o_data_linked$intervals[o_data_linked$intervals$PCSPEC %in% "plasma", ]
  # The last collection begins at 12 and runs 24 more: the reference reaches 36
  expect_equal(created$start, 0)
  expect_equal(created$end, 36)
  d_res <- as.data.frame(pk.nca(o_data_linked))
  # auclast(0-36) = (10+6)/2*12 + (6+4)/2*12 + (4+2)/2*12 = 192; ae = 350
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "auclast"], 192)
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "clr.last"], 350/192)
  # The wider reference still serves the narrower test interval
  expect_equal(
    d_res$PPANMETH[d_res$PPTESTCD %in% "clr.last"],
    "Reference interval: PCSPEC=plasma, 0-36"
  )

  # The data.frame method has no concentration data, so the created interval
  # copies the test interval's times unchanged
  iv_df <-
    suppressMessages(
      interval_add_renal_clearance(
        iv_span, reference = data.frame(PCSPEC = "plasma"), param = "clr.last"
      )
    )
  expect_equal(iv_df$end[iv_df$PCSPEC %in% "plasma"], 24)

  # An explicit `end` in `reference` overrides the extension
  o_data_explicit <-
    suppressMessages(
      interval_add_renal_clearance(
        o_data_span,
        reference = data.frame(PCSPEC = "plasma", end = 48), param = "clr.last"
      )
    )
  expect_equal(
    o_data_explicit$intervals$end[o_data_explicit$intervals$PCSPEC %in% "plasma"],
    48
  )
})

# Several created references are told apart by covering their test intervals
test_that("collection-spanning references link to the intervals they cover", {
  d_conc_two <- data.frame(
    subject = 1,
    PCSPEC = rep(c("plasma", "urine"), times = c(6, 4)),
    time = c(0, 12, 24, 36, 48, 60, 0, 12, 24, 36),
    conc = c(10, 6, 4, 2, 1, 0.5, 2, 1, 1.5, 0.8),
    vol  = c(rep(NA, 6), 100, 150, 120, 130),
    dur  = c(rep(0, 6), 12, 24, 12, 24)
  )
  o_conc_two <-
    PKNCAconc(d_conc_two, conc~time|PCSPEC+subject, volume = "vol", duration = "dur")
  iv_two <- data.frame(PCSPEC = "urine", start = c(0, 24), end = c(24, 48), ae = TRUE)
  o_data_two <-
    PKNCAdata(o_conc_two, intervals = iv_two, options = list(auc.method = "linear"))
  o_data_linked <-
    suppressMessages(
      interval_add_renal_clearance(
        o_data_two, reference = data.frame(PCSPEC = "plasma"), param = "clr.last"
      )
    )
  linked <- o_data_linked$intervals
  plasma_rows <- linked[linked$PCSPEC %in% "plasma", ]
  expect_equal(plasma_rows$end[order(plasma_rows$start)], c(36, 60))
  urine_rows <- linked[linked$PCSPEC %in% "urine", ]
  # Each urine interval points at the reference that covers it
  expect_equal(
    urine_rows$clr.last_ref[order(urine_rows$start)],
    plasma_rows$interval_id[order(plasma_rows$start)]
  )
  expect_no_error(pk.nca(o_data_linked))
})

# 20: the extracted exclusion combiner keeps the documented precedence
test_that("combine_exclude_reasons() combines and clears exclusion reasons", {
  expect_equal(combine_exclude_reasons(NULL, NULL), NA_character_)
  expect_equal(combine_exclude_reasons(NA_character_, NULL), NA_character_)
  expect_equal(combine_exclude_reasons("a", NULL), "a")
  expect_equal(combine_exclude_reasons(NULL, "b"), "b")
  expect_equal(combine_exclude_reasons(c("a", "b"), "c"), "a; b; c")
  expect_equal(combine_exclude_reasons(c("a", NA, "b"), NULL), "a; b")
  expect_equal(combine_exclude_reasons(c("a", "b"), "DO NOT EXCLUDE"), NA_character_)
  expect_equal(combine_exclude_reasons(NULL, "DO NOT EXCLUDE"), NA_character_)
})
