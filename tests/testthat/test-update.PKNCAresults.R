test_that("filter_changed_inner_join returns all data when no column overlap", {
  data <- data.frame(a = 1:3, b = letters[1:3])
  changed <- data.frame(x = 10:12)
  # nrow(changed) > 0, intersect(names(data), names(changed)) == character(0)
  # → the function returns all of data unchanged
  expect_identical(PKNCA:::filter_changed_inner_join(data, changed), data)
})

test_that("update.PKNCAresults", {
  d_conc <- generate.conc(2, 1, c(0, 2, 6, 12, 24))
  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(d_dose, formula=dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_result <- pk.nca(o_data)

  expect_message(
    update(o_result, o_data),
    regexp = "No changes detected in data"
  )
  o_data_changed <-
    PKNCAdata(
      o_conc, o_dose,
      intervals = data.frame(start = 0, end = Inf, half.life = TRUE),
      units = pknca_units_table(concu = "foo", doseu = "bar", timeu = "baz")
    )

  expect_warning(
    update(o_result, o_data_changed),
    regexp = "changes detected in data other than source concentration or dose data"
  )

  # Change concentration ----
  d_conc_changed <- d_conc
  d_conc_changed$conc[2] <- 1
  d_dose_changed <- d_dose
  d_dose_changed$dose[2] <- 2
  o_conc_changed <- PKNCAconc(d_conc_changed, formula=conc~time|treatment+ID)
  o_dose_changed <- PKNCAdose(d_dose_changed, formula=dose~time|treatment+ID)

  o_data_chconc <- PKNCAdata(o_conc_changed, o_dose, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_data_chdose <- PKNCAdata(o_conc, o_dose_changed, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))

  o_conc_changed_reordered <- PKNCAconc(d_conc_changed[order(-d_conc_changed$ID), ], formula=conc~time|treatment+ID)
  o_data_chconc_reordered <- PKNCAdata(o_conc_changed_reordered, o_dose, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))

  o_nca_chconc_reordered <- pk.nca(o_data_chconc_reordered)
  result_reorder <- o_nca_chconc_reordered$result
  result_update <- update(o_result, o_data_chconc)$result
  expect_equal(
    result_update[order(result_update$treatment, result_update$ID, result_update$start, result_update$end, result_update$PPTESTCD), ],
    result_reorder[order(result_reorder$treatment, result_reorder$ID, result_reorder$start, result_reorder$end, result_reorder$PPTESTCD), ]
  )
})

test_that("update() keeps concentration data", {
  d_conc <- as.data.frame(datasets::Theoph)
  d_dose <- d_conc[d_conc$Time == 0,]
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
  o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
  o_data <- PKNCAdata(o_conc, o_dose)
  o_nca <- pk.nca(o_data)

  d_conc_setzero <- as.data.frame(datasets::Theoph)
  d_conc_setzero$conc[d_conc$Time == 0] <- 0
  o_conc_update <- PKNCAconc(d_conc_setzero, conc~Time|Subject)
  o_data_update <- PKNCAdata(o_conc_update, o_dose)
  # Unchanged subjects are not recalculated, so they raise no
  # missing-concentration warning (issue 581)
  expect_no_warning(o_nca_update <- update(o_nca, o_data_update))
  expect_equal(
    o_nca_update$data$conc,
    o_conc_update
  )
})

# Sort results for row-order-insensitive comparison
sort_update_results <- function(d) {
  d <- as.data.frame(d)
  d$Subject <- as.character(d$Subject)
  d <- d[order(d$Subject, d$start, d$end, d$PPTESTCD), , drop = FALSE]
  rownames(d) <- NULL
  d
}

test_that("update() with ordered-factor groups recalculates only changed subjects without warnings (issue 581)", {
  # datasets::Theoph$Subject is an ordered factor
  d_conc <- as.data.frame(datasets::Theoph)
  d_dose <- d_conc[d_conc$Time == 0, ]
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
  o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
  o_data <- PKNCAdata(o_conc, o_dose)
  o_nca <- pk.nca(o_data)

  d_conc_new <- as.data.frame(datasets::Theoph)
  idx_change <- which(d_conc_new$Subject == "1")[3]
  d_conc_new$conc[idx_change] <- d_conc_new$conc[idx_change] * 2
  o_conc_new <- PKNCAconc(d_conc_new, conc~Time|Subject)
  o_data_new <- PKNCAdata(o_conc_new, o_dose)

  # Ordered-factor groups join without error, and unchanged subjects do not
  # warn about missing concentration data
  expect_no_warning(o_nca_update <- update(o_nca, data = o_data_new))

  # The updated result equals a full recalculation on the modified data
  o_nca_full <- pk.nca(o_data_new)
  expect_identical(
    sort_update_results(as.data.frame(o_nca_update)),
    sort_update_results(as.data.frame(o_nca_full))
  )
  # Guard against the comparison above being vacuous
  expect_false(
    identical(
      sort_update_results(as.data.frame(o_nca)),
      sort_update_results(as.data.frame(o_nca_full))
    )
  )

  # The ordered factor keeps its class and levels in the returned results
  df_update <- as.data.frame(o_nca_update)
  expect_true(is.ordered(df_update$Subject))
  expect_identical(levels(df_update$Subject), levels(d_conc$Subject))

  # Unchanged subjects are byte-identical to the original results
  df_orig <- as.data.frame(o_nca)
  unchanged_update <- as.data.frame(df_update[df_update$Subject != "1", , drop = FALSE])
  unchanged_orig <- as.data.frame(df_orig[df_orig$Subject != "1", , drop = FALSE])
  rownames(unchanged_update) <- NULL
  rownames(unchanged_orig) <- NULL
  expect_identical(unchanged_update, unchanged_orig)
})

test_that("update() with character groups recalculates only changed subjects without warnings (issue 581)", {
  d_conc <- as.data.frame(datasets::Theoph)
  d_conc$Subject <- as.character(d_conc$Subject)
  d_dose <- d_conc[d_conc$Time == 0, ]
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
  o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
  o_data <- PKNCAdata(o_conc, o_dose)
  o_nca <- pk.nca(o_data)

  d_conc_new <- d_conc
  idx_change <- which(d_conc_new$Subject == "1")[3]
  d_conc_new$conc[idx_change] <- d_conc_new$conc[idx_change] * 2
  o_conc_new <- PKNCAconc(d_conc_new, conc~Time|Subject)
  o_data_new <- PKNCAdata(o_conc_new, o_dose)

  expect_no_warning(o_nca_update <- update(o_nca, data = o_data_new))
  o_nca_full <- pk.nca(o_data_new)
  expect_identical(
    sort_update_results(as.data.frame(o_nca_update)),
    sort_update_results(as.data.frame(o_nca_full))
  )
})

test_that("update() joins ordered-factor groups by value when levels differ (issue 581)", {
  d_conc <- as.data.frame(datasets::Theoph)
  d_dose <- d_conc[d_conc$Time == 0, ]
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
  o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
  manual_int <- data.frame(start = 0, end = 24, auclast = TRUE)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = manual_int)
  o_nca <- pk.nca(o_data)

  # Same subjects, but the ordered factor is re-leveled to numeric order
  relevel_sorted <- function(d) {
    d$Subject <- factor(as.character(d$Subject), levels = as.character(1:12), ordered = TRUE)
    d
  }
  d_conc_new <- relevel_sorted(d_conc)
  idx_change <- which(d_conc_new$Subject == "1")[3]
  d_conc_new$conc[idx_change] <- d_conc_new$conc[idx_change] * 2
  d_dose_new <- relevel_sorted(d_dose)
  o_data_new <-
    PKNCAdata(
      PKNCAconc(d_conc_new, conc~Time|Subject),
      PKNCAdose(d_dose_new, Dose~Time|Subject),
      intervals = manual_int
    )

  # Ordered-factor levels differing between the two objects must not block
  # the join
  expect_no_warning(o_nca_update <- update(o_nca, data = o_data_new))
  o_nca_full <- pk.nca(o_data_new)
  expect_identical(
    sort_update_results(as.data.frame(o_nca_update)),
    sort_update_results(as.data.frame(o_nca_full))
  )
  # The results keep an ordered factor with a full set of levels
  df_update <- as.data.frame(o_nca_update)
  expect_true(is.ordered(df_update$Subject))
  expect_setequal(levels(df_update$Subject), levels(d_conc$Subject))
})

test_that("update() without changes in any group keeps the results as-is (issue 581)", {
  d_conc <- as.data.frame(datasets::Theoph)
  d_dose <- d_conc[d_conc$Time == 0, ]
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
  o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
  manual_int <- data.frame(start = 0, end = 24, auclast = TRUE)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = manual_int)
  o_nca <- pk.nca(o_data)

  # Reorder the subject blocks without changing any subject's data
  d_conc_new <- d_conc[order(as.integer(d_conc$Subject)), ]
  o_data_new <- PKNCAdata(PKNCAconc(d_conc_new, conc~Time|Subject), o_dose, intervals = manual_int)
  expect_message(
    o_nca_update <- update(o_nca, data = o_data_new),
    regexp = "No changes detected within any group"
  )
  expect_identical(o_nca_update$result, o_nca$result)
  expect_identical(o_nca_update$data$conc$data, o_data_new$conc$data)
})
