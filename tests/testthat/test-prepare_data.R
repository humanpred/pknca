# prepare_* ####

test_that("prepare_*", {
  tmp_conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp_dose <- generate.dose(tmp_conc)
  o_conc <- PKNCAconc(tmp_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(tmp_dose, formula=dose~time|treatment+ID)

  expect_equal(
    prepare_PKNCAconc(o_conc),
    tidyr::nest(
      tmp_conc[, c("treatment", "ID", "conc", "time")],
      data_conc=!c("treatment", "ID")
    )
  )
  expect_equal(
    prepare_PKNCAdose(o_dose, sparse=FALSE, subject_col=""),
    tidyr::nest(
      dplyr::mutate(
        tmp_dose,
        duration=0,
        route="extravascular"
      ),
      data_dose=!c("treatment", "ID")
    )
  )
  # No groups
  expect_equal(
    prepare_PKNCAintervals(.dat=PKNCA.options("single.dose.aucs")),
    tibble::tibble(
      data_intervals=list(tibble::as_tibble(PKNCA.options("single.dose.aucs")))
    )
  )
  # With groups
  tmp_intervals <- PKNCA.options("single.dose.aucs")
  tmp_intervals$g <- "A"
  expect_equal(
    prepare_PKNCAintervals(.dat=tmp_intervals, vars="g"),
    tibble::tibble(
      g="A",
      data_intervals=list(tibble::as_tibble(PKNCA.options("single.dose.aucs")))
    )
  )
})

# full_join for PKNCAconc, PKNCAdose, and PKNCAdata ####

test_that("full_join for PKNCAconc, PKNCAdose, and PKNCAdata", {
  tmp_conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp_dose <- generate.dose(tmp_conc)
  o_conc <- PKNCAconc(tmp_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(tmp_dose, formula=dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose)

  expect_equal(
    full_join_PKNCAconc_PKNCAdose(o_conc, o_dose),
    dplyr::full_join(
      prepare_PKNCAconc(o_conc),
      prepare_PKNCAdose(o_dose, sparse=FALSE, subject_col=""),
      by=c("treatment", "ID")
    )
  )
  expect_equal(
    full_join_PKNCAdata(o_data),
    tidyr::crossing(
      dplyr::full_join(
        prepare_PKNCAconc(o_conc),
        prepare_PKNCAdose(o_dose, sparse=FALSE, subject_col=""),
        by=c("treatment", "ID")
      ),
      data_intervals=list(tibble::as_tibble(PKNCA.options("single.dose.aucs")))
    )
  )
  # When intervals have no groups
  o_data_manual_interval <-
    PKNCAdata(
      o_conc,
      o_dose,
      intervals=PKNCA.options("single.dose.aucs")[1,]
    )
  expect_equal(
    full_join_PKNCAdata(o_data_manual_interval),
    tidyr::crossing(
      dplyr::full_join(
        prepare_PKNCAconc(o_conc),
        prepare_PKNCAdose(o_dose, sparse=FALSE, subject_col=""),
        by=c("treatment", "ID")
      ),
      data_intervals=list(tibble::as_tibble(PKNCA.options("single.dose.aucs")[1,]))
    )
  )
  # When dosing is not provided
  o_data_no_dose <- PKNCAdata(o_conc, intervals=PKNCA.options("single.dose.aucs")[1,])
  suppressMessages(
    expect_equal(
      full_join_PKNCAdata(o_data_no_dose),
      tidyr::crossing(
        prepare_PKNCAconc(o_conc),
        tibble::tibble(data_dose=list(NA)),
        data_intervals=list(tibble::as_tibble(PKNCA.options("single.dose.aucs")[1,]))
      )
    )
  )
})

test_that("check_reserved_column_names", {
  expect_null(
    check_reserved_column_names(data.frame())
  )
  expect_error(
    check_reserved_column_names(data.frame(data_dose=1)),
    regexp="The column 'data_dose' is reserved for internal use in PKNCA.  Change the name and retry.",
    fixed=TRUE
  )
  expect_error(
    check_reserved_column_names(data.frame(data_dose=1, data_conc=1, data_intervals=1)),
    regexp="The columns 'data_conc', 'data_dose', 'data_intervals' are reserved for internal use in PKNCA.  Change the names and retry.",
    fixed=TRUE
  )
})

# standardize_column_names ####

test_that("standardize_column_names", {
  # One column works
  expect_equal(
    standardize_column_names(data.frame(a=1), cols=list(b="a")),
    data.frame(b=1)
  )
  # Two columns work
  expect_equal(
    standardize_column_names(data.frame(a=1, b=2), cols=list(c="a", d="b")),
    data.frame(c=1, d=2)
  )
  # group_cols overlap with cols values fails
  expect_error(
    standardize_column_names(data.frame(a=1, b=2), cols=list(c="a", d="b"), group_cols="b"),
    regexp="group_cols must not overlap with other column names. Change the name of the following groups: b"
  )
  # group_cols overlap with cols names fails
  expect_error(
    standardize_column_names(data.frame(a=1, b=2), cols=list(c="a", d="b"), group_cols="c"),
    regexp="group_cols must not overlap with standardized column names. Change the name of the following groups: c"
  )
  # group_cols works
  expect_equal(
    standardize_column_names(data.frame(a=1, b=2), cols=list(d="b"), group_cols="a"),
    data.frame(group1=1, d=2)
  )
  # Missing values are inserted correctly
  expect_equal(
    standardize_column_names(
      data.frame(a=1, b=2),
      cols=list(d="b"),
      group_cols="a",
      insert_if_missing=list(dose=1)
    ),
    data.frame(group1=1, d=2, dose=1)
  )
  # Missing values are not inserted when something is already in the data for
  # that column
  expect_equal(
    standardize_column_names(
      data.frame(a=1, b=2, c=3),
      cols=list(d="b", dose="c"),
      group_cols="a",
      insert_if_missing=list(dose=2)
    ),
    data.frame(group1=1, d=2, dose=3)
  )
})

# restore_group_col_names ####

test_that("restore_group_col_names", {
  d <- data.frame(a=1, group1=2)
  # zero group cols
  expect_equal(
    restore_group_col_names(d),
    d
  )
  # One group col
  expect_equal(
    restore_group_col_names(d, group_cols="b"),
    data.frame(a=1, b=2)
  )
  # More than one group col
  expect_equal(
    restore_group_col_names(data.frame(a=1, group1=2, group2=3), c("b", "c")),
    data.frame(a=1, b=2, c=3)
  )
  expect_error(
    restore_group_col_names(d, group_cols=c("b", "c")),
    regexp="missing intermediate group_cols names"
  )
  expect_error(
    restore_group_col_names(data.frame(a=1, group2=3, group1=2), c("b", "c")),
    regexp="Intermediate group_cols are out of order"
  )
})

test_that("requesting a parameter that needs volume without one is an error (#194)", {
  d_conc <- data.frame(conc = c(2, 1, 0.5, 0.25, 0.125), time = 0:4, subject = 1)
  d_dose <- data.frame(dose = 100, time = 0, subject = 1)
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  o_dose <- PKNCAdose(d_dose, dose~time|subject)
  expect_error(
    pk.nca(PKNCAdata(o_conc, o_dose, intervals = data.frame(start = 0, end = Inf, ae = TRUE))),
    regexp = "No sample volume was given.*`volume` argument.*cannot be calculated: ae",
    class = "pknca_error_missing_conc_input"
  )
  # Parameters downstream of ae are named, and those needing no volume are not
  expect_error(
    pk.nca(PKNCAdata(
      o_conc, o_dose,
      intervals = data.frame(start = 0, end = Inf, ae = TRUE, fe = TRUE, cmax = TRUE)
    )),
    regexp = "cannot be calculated: ae, fe$",
    class = "pknca_error_missing_conc_input"
  )
  # With a volume the calculation proceeds
  o_conc_vol <- PKNCAconc(cbind(d_conc, vol = 10), conc~time|subject, volume = "vol")
  res <-
    suppressMessages(pk.nca(PKNCAdata(
      o_conc_vol, o_dose, intervals = data.frame(start = 0, end = Inf, ae = TRUE)
    )))
  expect_equal(as.data.frame(res)$PPORRES, sum(d_conc$conc * 10))
})

test_that("requesting a parameter that needs a collection duration without one is an error (#166)", {
  d_conc <- data.frame(conc = c(2, 1, 0.5, 0.25, 0.125), time = 0:4, subject = 1, vol = 10)
  d_dose <- data.frame(dose = 100, time = 0, subject = 1)
  o_dose <- PKNCAdose(d_dose, dose~time|subject)
  o_conc_vol <- PKNCAconc(d_conc, conc~time|subject, volume = "vol")
  expect_error(
    pk.nca(PKNCAdata(
      o_conc_vol, o_dose, intervals = data.frame(start = 0, end = Inf, ermax = TRUE)
    )),
    regexp = "No sample duration was given.*`duration` argument.*cannot be calculated: ermax",
    class = "pknca_error_missing_conc_input"
  )
  # Both are reported together when both are absent
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  expect_error(
    pk.nca(PKNCAdata(
      o_conc, o_dose, intervals = data.frame(start = 0, end = Inf, ermax = TRUE)
    )),
    regexp = "No sample volume or duration was given .see the `volume` and `duration` arguments",
    class = "pknca_error_missing_conc_input"
  )
  # With both, the calculation proceeds
  o_conc_both <-
    PKNCAconc(cbind(d_conc, dur = 1), conc~time|subject, volume = "vol", duration = "dur")
  res <-
    suppressMessages(pk.nca(PKNCAdata(
      o_conc_both, o_dose, intervals = data.frame(start = 0, end = Inf, ermax = TRUE)
    )))
  expect_equal(as.data.frame(res)$PPORRES, max(d_conc$conc * 10 / 1))
})
