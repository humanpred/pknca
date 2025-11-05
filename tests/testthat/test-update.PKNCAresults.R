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

expect_equal("update() keeps concentration data", {
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
  o_nca_update <- suppressWarnings(update(o_nca, o_data_update))
  expect_equal(
    o_nca_update$data$conc,
    o_conc_update
  )
})
