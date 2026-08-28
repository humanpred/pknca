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
      "f",
      "clr.last", "clr.obs", "clr.pred",
      "clr.last.dn", "clr.obs.dn", "clr.pred.dn"
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
  # interval_id must hold identifiers, so a factor is rejected
  expect_error(
    check.interval.specification(
      data.frame(
        start = 0, end = 24, auclast = TRUE,
        interval_id = factor("a")
      )
    ),
    class = "pknca_error_secondary_interval_id_invalid"
  )
  # An all-NA logical pointer column is coerced rather than rejected
  checked <-
    check.interval.specification(
      data.frame(
        start = 0, end = 24, ae = TRUE, auclast = TRUE,
        interval_id = NA, clr.last_ref = NA
      )
    )
  expect_true(is.character(checked$interval_id))
  expect_true(is.character(checked$clr.last_ref))
  expect_equal(checked$clr.last_ref, NA_character_)
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
    "Reference interval: early (0-12)"
  )
})

# 6: the reference interval is disclosed in PPANMETH
test_that("PPANMETH names the reference interval and how it differs", {
  res <- pk.nca(o_data_sec)
  d_res <- as.data.frame(res)
  expect_equal(
    d_res$PPANMETH[d_res$PPTESTCD %in% "clr.last"],
    "Reference interval: plasma024 (PCSPEC=plasma, 0-24)"
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
test_that("f takes dose and AUC from the reference interval", {
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
    f = c(FALSE, TRUE),
    f_ref = c(NA, "refprofile")
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
    value_of("f", "test"),
    (value_of("aucinf.obs", "test")/value_of("totdose", "test")) /
      (value_of("aucinf.obs", "ref")/value_of("totdose", "ref"))
  )
  expect_equal(length(value_of("f", "ref")), 0L)
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
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, f = TRUE))
  err <-
    rlang::catch_cnd(
      suppressMessages(suppressWarnings(pk.nca(o_data))),
      classes = "error"
    )
  expect_true("pknca_error_secondary_needs_ref" %in% condition_classes(err))
  expect_match(conditionMessage(err), "f_ref", fixed = TRUE)
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
test_that("f is not resolved from its own interval", {
  d_conc_f <- data.frame(treatment = "test", subject = 1, time = c(0, 1, 2, 4, 8),
                         conc = c(0, 6, 5, 3, 1))
  d_dose_f <- data.frame(treatment = "test", subject = 1, time = 0, dose = 50)
  o_conc_f <- PKNCAconc(d_conc_f, conc~time|treatment+subject)
  o_dose_f <- PKNCAdose(d_dose_f, dose~time|treatment+subject)
  o_data_f <-
    PKNCAdata(
      o_conc_f, o_dose_f,
      intervals = data.frame(start = 0, end = Inf, aucinf.obs = TRUE, totdose = TRUE, f = TRUE)
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
