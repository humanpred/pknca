test_that("PKNCAresults object creation", {
  minimal_result <- PKNCAresults(data.frame(a=1), data=list())
  expect_equal(minimal_result$columns$exclude, "exclude")
  result_with_exclude_col <- PKNCAresults(data.frame(exclude=1), data=list())
  expect_equal(result_with_exclude_col$columns$exclude, "exclude.exclude")
})

test_that("PKNCAresults generation", {
  # Note that generate.conc sets the random seed, so it doesn't have
  # to happen here.
  d_conc <- generate.conc(2, 1, 0:24)
  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(d_dose, formula=dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose)
  o_result <- pk.nca(o_data)

  expect_equal(
    names(o_result),
    c("result", "data", "columns"),
    info="Make sure that the result has the expected names (and only the expected names) in it."
  )
  expect_true(
    checkProvenance(o_result),
    info="Provenance exists and can be confirmed on results"
  )

  # Test each of the pieces for o_result for accuracy
  expect_equal(
    o_result$data, {
      tmp <- o_data
      # The options should be the default options after the
      # calculations are done.
      tmp$options <- PKNCA.options()
      tmp
    }, info="The data is just a copy of the input data plus an instantiation of the PKNCA.options"
  )

  verify.result <-
    tibble::tibble(
      treatment="Trt 1",
      ID=as.integer(rep(c(1, 2), each=16)),
      start=0,
      end=c(24, rep(Inf, 15),
            24, rep(Inf, 15)),
      PPTESTCD=rep(c("auclast", "cmax", "tmax", "tlast", "clast.obs",
                     "lambda.z", "r.squared", "adj.r.squared", "lambda.z.corrxy",
                     "lambda.z.time.first", "lambda.z.time.last", "lambda.z.n.points",
                     "clast.pred", "half.life", "span.ratio", "aucinf.obs"),
                   times=2),
      PPORRES=c(13.54, 0.9998, 4.000, 24.00, 0.3441,
                0.04297, 0.9072, 0.9021, -0.9521, 5.000, 24.00,
                20.00, 0.3356, 16.13, 1.178,
                21.55, 14.03, 0.9410, 2.000,
                24.00, 0.3148, 0.05689, 0.9000,
                0.8944, -0.9487, 5.000, 24.00, 20.00, 0.3011,
                12.18, 1.560, 19.56),
      PPANMETH=c(
        "AUC: lin up/log down",
        rep("", 4),
        rep("", 10),
        "AUC: lin up/log down",
        "AUC: lin up/log down",
        rep("", 4),
        rep("", 10),
        "AUC: lin up/log down"
      ),
      exclude=NA_character_
    )
  expect_equal(
    o_result$result,
    verify.result,
    tolerance=0.001,
    info="The specific order of the levels isn't important-- the fact that they are factors and that the set doesn't change is important."
  )

  # Test conversion to a data.frame
  expect_equal(
    as.data.frame(o_result),
    verify.result,
    tolerance=0.001,
    info="Conversion of PKNCAresults to a data.frame in long format (default long format)"
  )
  expect_equal(
    as.data.frame(o_result, out_format="long"),
    verify.result,
    tolerance=0.001,
    info="Conversion of PKNCAresults to a data.frame in long format (specifying long format)"
  )
  expect_equal(
    as.data.frame(o_result, out_format="wide"),
    tidyr::spread(verify.result[names(verify.result) != "PPANMETH"], key="PPTESTCD", value="PPORRES"),
    tolerance=0.001,
    info="Conversion of PKNCAresults to a data.frame in wide format (specifying wide format)"
  )

  d_conc <- generate.conc(2, 1, 0:24)
  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(d_dose, formula=dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose, intervals=data.frame(start=0, end=12, aucint.inf.obs=TRUE))
  o_result <- pk.nca(o_data)

  d_conc12 <- d_conc
  d_conc12$time <- d_conc$time + 12
  d_dose12 <- generate.dose(d_conc12)
  o_conc12 <- PKNCAconc(d_conc12, formula=conc~time|treatment+ID)
  o_dose12 <- PKNCAdose(d_dose12, formula=dose~time|treatment+ID)
  o_data12 <- PKNCAdata(o_conc12, o_dose12, intervals=data.frame(start=12, end=24, aucint.inf.obs=TRUE))
  o_result12 <- pk.nca(o_data12)
  comparison_orig <- as.data.frame(o_result)
  comparison_12 <- as.data.frame(o_result12)
  expect_equal(
    comparison_orig$PPORRES[comparison_orig$PPTESTCD %in% "aucint.inf.obs"],
    comparison_12$PPORRES[comparison_12$PPTESTCD %in% "aucint.inf.obs"],
    info="Time shift does not affect aucint calculations."
  )
})

test_that("PKNCAresults has exclude, when applicable", {
  d_conc <- generate.conc(2, 1, 0:24)
  d_conc$conc[d_conc$ID %in% 2] <- 0
  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, conc~time|treatment+ID)
  o_dose <- PKNCAdose(d_dose, dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose)
  # Not capturing the warning due to R bug
  # https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=17122
  #expect_warning(o_result <- pk.nca(o_data),
  #               regexp="Too few points for half-life calculation")
  suppressWarnings(o_result <- pk.nca(o_data))
  o_result_df <- as.data.frame(o_result)
  expect_true(
    all(o_result_df$PPTESTCD %in%
          c(
            "adj.r.squared", "lambda.z.corrxy", "aucinf.obs", "auclast", "clast.obs",
            "clast.pred", "cmax", "half.life", "lambda.z", "lambda.z.n.points",
            "lambda.z.time.first", "lambda.z.time.last", "r.squared",
            "span.ratio", "tlast", "tmax"
          )
    ),
    info="verify that only expected results are present"
  )
  expect_equal(
    unique(
      o_result_df$exclude[
        o_result_df$ID == 2 &
          o_result_df$PPTESTCD %in%
          c(
            "lambda.z", "r.squared", "adj.r.squared", "lambda.z.corrxy",
            "lambda.z.time.first", "lambda.z.time.last",
            "lambda.z.n.points", "clast.pred", "half.life", "span.ratio"
          )
        ]
    ),
    "Too few points for half-life calculation (min.hl.points=3 with only 0 points)",
    info="exclusions are propogated to results"
  )
  expect_equal(
    unique(
      o_result_df$exclude[
        !(o_result_df$ID == 2 &
            o_result_df$PPTESTCD %in%
            c("lambda.z", "r.squared", "adj.r.squared", "lambda.z.corrxy", "lambda.z.time.first",
              "lambda.z.time.last", "lambda.z.n.points", "clast.pred", "half.life", "span.ratio")
        )
        ]
    ),
    NA_character_,
    info="exclusions are propogated to results only when applicable"
  )
})

test_that("ptr works as a parameter", {
  d_conc <- generate.conc(2, 1, 0:24)
  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(d_dose, formula=dose~time|treatment+ID)
  myinterval <- data.frame(start=0, end=24, ptr=TRUE)
  o_data <- PKNCAdata(o_conc, o_dose, intervals=myinterval)
  o_result <- pk.nca(o_data)
  ptr_result <- as.data.frame(o_result)
  expect_equal(
    ptr_result$PPORRES[ptr_result$PPTESTCD %in% "ptr"],
    c(2.9055, 2.9885),
    tolerance=0.0001
  )
})

test_that("exclude values are maintained in derived parameters during automatic calculation (#112)", {
  my_conc <-
    data.frame(
      conc = c(0, 2.5, 3, 2.7, 2.3),
      time = 0:4,
      subject = 1
    )

  conc_obj <- PKNCAconc(my_conc, conc~time|subject)
  data_obj <-
    PKNCAdata(
      data.conc=conc_obj,
      intervals=
        data.frame(
          start=0,
          end=Inf,
          aucinf.obs=TRUE
        )
    )
  expect_message(
    expect_warning(
      results_obj <- pk.nca(data_obj),
      regexp="Too few points for half-life"
    ),
    regexp="No dose information provided"
  )
  d_results <- as.data.frame(results_obj)
  expect_equal(
    d_results$exclude[d_results$PPTESTCD == "aucinf.obs"],
    d_results$exclude[d_results$PPTESTCD == "half.life"]
  )
})

test_that("ctrough is correctly calculated", {
  my_conc <- data.frame(time=0:6, conc=2^(0:-6), subject=1)
  conc_obj <- PKNCAconc(my_conc, conc~time|subject)
  data_obj <-
    PKNCAdata(
      data.conc=conc_obj,
      intervals=
        data.frame(
          start=0,
          end=c(6, Inf),
          ctrough=TRUE
        )
    )
  expect_message(
    expect_equal(
      as.data.frame(pk.nca(data_obj))$PPORRES,
      c(2^-6, NA_real_)
    ),
    regexp="No dose information provided"
  )
})

test_that("single subject, ungrouped data works (#74)", {
  my_conc <- data.frame(time=0:6, conc=2^(0:-6))
  conc_obj <- PKNCAconc(my_conc, conc~time)
  data_obj <-
    PKNCAdata(
      data.conc=conc_obj,
      intervals=
        data.frame(
          start=0,
          end=Inf,
          cmax=TRUE
        )
    )
  expect_message(
    expect_equal(
      as.data.frame(pk.nca(data_obj))$PPORRES,
      1
    ),
    regexp="No dose information provided",
  )
})

test_that("units work for calculations and summaries with one set of units across all analytes", {
  d_conc <- generate.conc(2, 1, 0:24)
  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(d_dose, formula=dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose)
  o_result <- pk.nca(o_data)

  d_units_orig <- pknca_units_table(concu="ng/mL", doseu="mg", amountu="mg", timeu="hr")
  d_units_std <-
    pknca_units_table(
      concu="ng/mL", doseu="mg", amountu="mg", timeu="hr",
      conversions=data.frame(PPORRESU="ng/mL", PPSTRESU="mg/mL")
    )
  o_data_orig <- PKNCAdata(o_conc, o_dose, units=d_units_orig)
  o_result_units_orig <- pk.nca(o_data_orig)
  o_data_std <- PKNCAdata(o_conc, o_dose, units=d_units_std)
  o_result_units_std <- pk.nca(o_data_std)

  # Summaries are the same except for the column names
  expect_equal(
    unname(summary(o_result)),
    unname(summary(o_result_units_orig)),
    # The caption attribute will differ
    ignore_attr = TRUE
  )
  expect_equal(
    summary(o_result_units_orig) %>% dplyr::select(-`Cmax (ng/mL)`),
    summary(o_result_units_std) %>% dplyr::select(-`Cmax (mg/mL)`)
  )
  # The units are converted to standard units, if requested
  expect_equal(
    summary(o_result_units_orig)$`Cmax (ng/mL)`,
    c(".", "0.970 [4.29]")
  )
  expect_equal(
    summary(o_result_units_std)$`Cmax (mg/mL)`,
    c(".", "9.70e-7 [4.29]")
  )
  # Wide conversion works for original and standardized units
  df_wide_orig <- as.data.frame(o_result_units_orig, out_format="wide")
  df_wide_std <- as.data.frame(o_result_units_std, out_format="wide")
  expect_equal(
    as.data.frame(o_result, out_format="wide"),
    # The difference is the addition of units to the column names
    df_wide_orig %>%
      dplyr::rename_with(.fn=gsub, pattern=" \\(.*$", replacement="")
  )
  expect_true(
    all(
      names(df_wide_orig) %in% c("treatment", "ID", "start", "end", "exclude") |
        grepl(x=names(df_wide_orig), pattern=" (", fixed=TRUE)
    )
  )
  # Everything is the same unless it is a concentration which has been converted
  expect_equal(
    df_wide_orig %>% dplyr::select(-`cmax (ng/mL)`, -`clast.obs (ng/mL)`, -`clast.pred (ng/mL)`),
    df_wide_std %>% dplyr::select(-`cmax (mg/mL)`, -`clast.obs (mg/mL)`, -`clast.pred (mg/mL)`)
  )
  # Concentration conversion works correctly
  expect_equal(
    df_wide_orig$`cmax (ng/mL)`,
    df_wide_std$`cmax (mg/mL)`*1e6
  )
})

test_that("units work for calculations and summaries with one set of units across all analytes", {
  d_conc1 <- generate.conc(2, 1, 0:24)
  d_conc1$analyte <- "drug1"
  d_conc2 <- d_conc1
  d_conc2$analyte <- "drug2"
  d_conc <- rbind(d_conc1, d_conc2)

  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, formula=conc~time|treatment+ID/analyte)
  o_dose <- PKNCAdose(d_dose, formula=dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose)
  o_result <- pk.nca(o_data)

  d_units_std1 <-
    pknca_units_table(
      concu="ng/mL", doseu="mg", amountu="mg", timeu="hr",
      conversions=data.frame(PPORRESU="ng/mL", PPSTRESU="mg/mL")
    )
  d_units_std1$analyte <- "drug1"
  d_units_std2 <-
    pknca_units_table(
      concu="ng/mL", doseu="mg", amountu="mg", timeu="hr",
      conversions=data.frame(PPORRESU="ng/mL", PPSTRESU="mmol/L", conversion_factor=2)
    )
  d_units_std2$analyte <- "drug2"
  d_units_std <- rbind(d_units_std1, d_units_std2)
  o_data_std <- PKNCAdata(o_conc, o_dose, units=d_units_std)
  o_result_units_std <- pk.nca(o_data_std)
  summary_o_result_units_std <- summary(o_result_units_std)
  # Everything is the same between analytes except for "cmax"
  for (nm in setdiff(names(summary_o_result_units_std), c("analyte", "Cmax"))) {
    expect_equal(
      summary_o_result_units_std[[nm]][1:2],
      summary_o_result_units_std[[nm]][3:4]
    )
  }
  # Different units in the same column are shown in the cell
  expect_equal(
    summary_o_result_units_std$Cmax,
    c(".", "9.70e-7 [4.29] mg/mL", ".", "1.94 [4.29] mmol/L")
  )

  # I can't think of a way to trigger this error without explicit manipulation.
  o_result_units_manipulated <- o_result_units_std
  o_result_units_manipulated$result$PPSTRESU[o_result_units_manipulated$result$PPTESTCD %in% "auclast"][1] <- "foo"
  expect_error(
    summary(o_result_units_manipulated),
    regexp="Multiple units cannot be summarized together.  For auclast, trying to combine: foo, hr*ng/mL",
    fixed=TRUE
  )
})

test_that("getGroups.PKNCAresults", {
  d_conc <- generate.conc(2, 1, 0:24)
  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(d_dose, formula=dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose)
  o_result <- pk.nca(o_data)

  expect_equal(
    getGroups(o_result, level="treatment"),
    o_result$result[, "treatment", drop=FALSE]
  )
  expect_equal(
    getGroups(o_result, level=factor("treatment")),
    o_result$result[, "treatment", drop=FALSE]
  )
  expect_error(
    getGroups(o_result, level="foo"),
    regexp="Not all levels are listed in the group names.  Missing levels are: foo"
  )
  expect_equal(
    getGroups(o_result, level=2),
    o_result$result[, c("treatment", "ID")]
  )
  expect_equal(
    getGroups(o_result, level=2:3),
    o_result$result[, c("ID", "start")]
  )
  expect_equal(
    getGroups(o_result, level=3:4),
    o_result$result[, c("start", "end")]
  )
})

test_that("group_vars.PKNCAresult", {
  o_conc_group <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data_group <- PKNCAdata(o_conc_group, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  suppressMessages(o_nca_group <- pk.nca(o_data_group))

  expect_equal(dplyr::group_vars(o_nca_group), "Subject")

  # Check that it works without groupings as expected [empty]
  o_conc_nongroup <- PKNCAconc(as.data.frame(datasets::Theoph)[datasets::Theoph$Subject == 1,], conc~Time)
  o_data_nogroup <- PKNCAdata(o_conc_nongroup, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  suppressMessages(o_nca_nogroup <- pk.nca(o_data_nogroup))

  expect_equal(dplyr::group_vars(o_nca_nogroup), character(0))
})

test_that("as.data.frame.PKNCAresults can filter for only requested parameters", {
  d_conc <- generate.conc(2, 1, 0:24)
  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(d_dose, formula=dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_result <- pk.nca(o_data)

  expect_equal(nrow(as.data.frame(o_result)), 24)
  expect_equal(nrow(as.data.frame(o_result, filter_requested = TRUE)), 2)
})

test_that("as.data.frame.PKNCAresults can filter to remove excluded parameters", {
  d_conc <- generate.conc(2, 1, c(0, 2, 6, 12, 24))
  d_dose <- generate.dose(d_conc)
  o_conc <- PKNCAconc(d_conc, formula=conc~time|treatment+ID)
  o_dose <- PKNCAdose(d_dose, formula=dose~time|treatment+ID)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_result <- exclude(pk.nca(o_data), FUN = exclude_nca_span.ratio(1))

  expect_equal(nrow(as.data.frame(o_result)), 24)
  expect_equal(nrow(as.data.frame(o_result, filter_excluded = TRUE)), 14)
})

# CDISC output format tests ----

test_that("as.data.frame.PKNCAresults with out_format='cdisc' adds PPTESTCD and PPTEST", {
  d_conc <- data.frame(
    subject = rep(1, 4),
    time = 0:3,
    conc = c(0, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  d_dose <- data.frame(subject = 1, time = 0, dose = 10)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(
    start = 0, end = 3, cmax = TRUE, auclast = TRUE, tmax = TRUE
  ))
  suppressMessages(o_nca <- pk.nca(o_data))

  result_cdisc <- as.data.frame(o_nca, out_format = "cdisc")

  expect_true("PPTESTCD" %in% names(result_cdisc))
  expect_true("PPTEST" %in% names(result_cdisc))
  expect_true("CMAX" %in% result_cdisc$PPTESTCD)
  expect_true("AUCLST" %in% result_cdisc$PPTESTCD)
  expect_true("TMAX" %in% result_cdisc$PPTESTCD)
  # PPTEST should be placed right after PPTESTCD
  pptestcd_pos <- which(names(result_cdisc) == "PPTESTCD")
  pptest_pos <- which(names(result_cdisc) == "PPTEST")
  expect_equal(pptest_pos, pptestcd_pos + 1)
  # Check PPTEST values
  cmax_row <- result_cdisc[result_cdisc$PPTESTCD == "CMAX", ]
  expect_equal(cmax_row$PPTEST, "Max Conc")
})

test_that("as.data.frame.PKNCAresults with out_format='cdisc' resolves route-dependent params", {
  d_conc <- data.frame(
    subject = rep(1, 5),
    time = 0:4,
    conc = c(0, 2, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  d_dose <- data.frame(subject = 1, time = 0, dose = 10)

  # Extravascular
  o_dose_ev <- PKNCAdose(d_dose, dose ~ time | subject, route = "extravascular")
  o_data_ev <- PKNCAdata(o_conc, o_dose_ev, intervals = data.frame(
    start = 0, end = Inf, cl.obs = TRUE, aucinf.obs = TRUE, half.life = TRUE
  ))
  suppressMessages(suppressWarnings(o_nca_ev <- pk.nca(o_data_ev)))
  result_ev <- as.data.frame(o_nca_ev, out_format = "cdisc")
  expect_true("CLF/FO" %in% result_ev$PPTESTCD)
  expect_false("CLO" %in% result_ev$PPTESTCD)

  # Intravascular
  o_dose_iv <- PKNCAdose(d_dose, dose ~ time | subject, route = "intravascular")
  o_data_iv <- PKNCAdata(o_conc, o_dose_iv, intervals = data.frame(
    start = 0, end = Inf, cl.obs = TRUE, aucinf.obs = TRUE, half.life = TRUE
  ))
  suppressMessages(suppressWarnings(o_nca_iv <- pk.nca(o_data_iv)))
  result_iv <- as.data.frame(o_nca_iv, out_format = "cdisc")
  expect_true("CLO" %in% result_iv$PPTESTCD)
  expect_false("CLF/FO" %in% result_iv$PPTESTCD)
})

test_that("as.data.frame.PKNCAresults with out_format='cdisc' does not add PPSTINT/PPENINT without INT params", {
  d_conc <- data.frame(
    subject = rep(1, 4),
    time = 0:3,
    conc = c(0, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  d_dose <- data.frame(subject = 1, time = 0, dose = 10)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(
    start = 0, end = 3, cmax = TRUE
  ))
  suppressMessages(o_nca <- pk.nca(o_data))

  result_cdisc <- as.data.frame(o_nca, out_format = "cdisc")
  expect_false("PPSTINT" %in% names(result_cdisc))
  expect_false("PPENINT" %in% names(result_cdisc))
})

test_that("as.data.frame.PKNCAresults with out_format='cdisc' adds PPSTINT/PPENINT for INT params", {
  d_conc <- data.frame(
    subject = rep(1, 5),
    time = 0:4,
    conc = c(0, 2, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, timeu = "hr")
  d_dose <- data.frame(subject = 1, time = 0, dose = 10)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(
    start = 0, end = 4, cmax = TRUE, aucint.last = TRUE
  ), options = list(allow_partial_missing_units = TRUE))
  expect_warning(
    suppressMessages(o_nca <- pk.nca(o_data)),
    regexp = "Units are provided for some"
  )

  result_cdisc <- as.data.frame(o_nca, out_format = "cdisc")

  # PPSTINT and PPENINT columns should exist
  expect_true("PPSTINT" %in% names(result_cdisc))
  expect_true("PPENINT" %in% names(result_cdisc))

  # INT rows should have values, non-INT rows should be NA
  int_rows <- grepl("INT", result_cdisc$PPTESTCD, fixed = TRUE)
  expect_true(any(int_rows), info = "At least one INT parameter should be present")
  expect_true(all(!is.na(result_cdisc$PPSTINT[int_rows])))
  expect_true(all(!is.na(result_cdisc$PPENINT[int_rows])))
  expect_true(all(is.na(result_cdisc$PPSTINT[!int_rows])))
  expect_true(all(is.na(result_cdisc$PPENINT[!int_rows])))

  # Values should be ISO 8601 durations relative to dose time (0)
  # start=0, dose_time=0 -> PT0H; end=4, dose_time=0 -> PT4H
  int_result <- result_cdisc[int_rows, ]
  expect_equal(int_result$PPSTINT[1], "PT0H")
  expect_equal(int_result$PPENINT[1], "PT4H")
})

test_that("PPSTINT/PPENINT uses timeu_pref when available", {
  d_conc <- data.frame(
    subject = rep(1, 5),
    time = 0:4,
    conc = c(0, 2, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, timeu = "hr", timeu_pref = "min")
  d_dose <- data.frame(subject = 1, time = 0, dose = 10)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(
    start = 0, end = 4, aucint.last = TRUE
  ), options = list(allow_partial_missing_units = TRUE))
  expect_warning(
    suppressMessages(o_nca <- pk.nca(o_data)),
    regexp = "Units are provided for some"
  )

  result_cdisc <- as.data.frame(o_nca, out_format = "cdisc")
  int_rows <- grepl("INT", result_cdisc$PPTESTCD, fixed = TRUE)
  # timeu_pref is "min", so durations should use M designator
  expect_equal(result_cdisc$PPSTINT[int_rows][1], "PT0M")
  expect_equal(result_cdisc$PPENINT[int_rows][1], "PT4M")
})

test_that("PPSTINT/PPENINT computes relative to last dose time", {
  d_conc <- data.frame(
    subject = rep(1, 10),
    time = 0:9,
    conc = c(0, 2, 1, 0.5, 0.25, 0, 3, 1.5, 0.75, 0.3)
  )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, timeu = "hr")
  # Two doses: at time 0 and time 5
  d_dose <- data.frame(subject = c(1, 1), time = c(0, 5), dose = c(10, 10))
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(
    start = c(0, 5), end = c(5, 9), aucint.last = TRUE
  ), options = list(allow_partial_missing_units = TRUE))
  expect_warning(
    suppressMessages(o_nca <- pk.nca(o_data)),
    regexp = "Units are provided for some"
  )

  result_cdisc <- as.data.frame(o_nca, out_format = "cdisc")
  int_rows <- grepl("INT", result_cdisc$PPTESTCD, fixed = TRUE)
  int_result <- result_cdisc[int_rows, ]

  # First interval: start=0, end=5, last_dose=0 -> PT0H, PT5H
  row1 <- int_result[int_result$start == 0, ]
  expect_equal(row1$PPSTINT[1], "PT0H")
  expect_equal(row1$PPENINT[1], "PT5H")

  # Second interval: start=5, end=9, last_dose=5 -> PT0H, PT4H
  row2 <- int_result[int_result$start == 5, ]
  expect_equal(row2$PPSTINT[1], "PT0H")
  expect_equal(row2$PPENINT[1], "PT4H")
})

test_that("PPSTINT/PPENINT uses day designator for day units", {
  d_conc <- data.frame(
    subject = rep(1, 4),
    time = c(0, 1, 2, 3),
    conc = c(0, 2, 1, 0.5)
  )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, timeu = "day")
  d_dose <- data.frame(subject = 1, time = 0, dose = 10)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(
    start = 0, end = 3, aucint.last = TRUE
  ), options = list(allow_partial_missing_units = TRUE))
  expect_warning(
    suppressMessages(o_nca <- pk.nca(o_data)),
    regexp = "Units are provided for some"
  )

  result_cdisc <- as.data.frame(o_nca, out_format = "cdisc")
  int_rows <- grepl("INT", result_cdisc$PPTESTCD, fixed = TRUE)
  expect_equal(result_cdisc$PPSTINT[int_rows][1], "P0D")
  expect_equal(result_cdisc$PPENINT[int_rows][1], "P3D")
})

test_that("format_iso8601_duration handles edge cases", {
  expect_equal(PKNCA:::format_iso8601_duration(0, "hr"), "PT0H")
  expect_equal(PKNCA:::format_iso8601_duration(24, "hr"), "PT24H")
  expect_equal(PKNCA:::format_iso8601_duration(1.5, "hr"), "PT1.5H")
  expect_equal(PKNCA:::format_iso8601_duration(30, "min"), "PT30M")
  expect_equal(PKNCA:::format_iso8601_duration(3600, "s"), "PT3600S")
  expect_equal(PKNCA:::format_iso8601_duration(7, "day"), "P7D")
  expect_true(is.na(PKNCA:::format_iso8601_duration(NA, "hr")))
  expect_true(is.na(PKNCA:::format_iso8601_duration(Inf, "hr")))
})

test_that("as.data.frame.PKNCAresults default format does not include PPSTINT/PPENINT", {
  d_conc <- data.frame(
    subject = rep(1, 5),
    time = 0:4,
    conc = c(0, 2, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, timeu = "hr")
  d_dose <- data.frame(subject = 1, time = 0, dose = 10)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(
    start = 0, end = 4, aucint.last = TRUE
  ), options = list(allow_partial_missing_units = TRUE))
  expect_warning(
    suppressMessages(o_nca <- pk.nca(o_data)),
    regexp = "Units are provided for some"
  )

  # Default (long) format should not have PPSTINT/PPENINT
  result_long <- as.data.frame(o_nca)
  expect_false("PPSTINT" %in% names(result_long))
  expect_false("PPENINT" %in% names(result_long))
})

test_that("pknca_cdisc_get_route falls back to extravascular when no dose data", {
  d_conc <- data.frame(subject = rep(1, 4), time = 0:3, conc = c(0, 1, 0.5, 0.25))
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 3, cmax = TRUE))
  suppressMessages(o_nca <- pk.nca(o_data))

  result_cdisc <- as.data.frame(o_nca, out_format = "cdisc")
  expect_true("PPTESTCD" %in% names(result_cdisc))
  expect_true("CMAX" %in% result_cdisc$PPTESTCD)
})

test_that("resolve_cdisc_value falls back to first route when route not matched", {
  # Route-dependent list with unknown route should fall back to first element
  val <- list(route = list(extravascular = "EV_CODE", intravascular = "IV_CODE"))
  expect_equal(PKNCA:::resolve_cdisc_value(val, "unknown_route"), "EV_CODE")
  # Non-list, non-character fallback
  expect_equal(PKNCA:::resolve_cdisc_value(42, "extravascular"), "42")
})

test_that("format_iso8601_duration falls back to hours for unknown unit", {
  expect_equal(PKNCA:::format_iso8601_duration(5, "fortnights"), "PT5H")
  expect_equal(PKNCA:::format_iso8601_duration(10, NA), "PT10H")
})

test_that("pknca_cdisc_get_timeu returns NA when no conc data", {
  # Minimal PKNCAresults with no conc object
  minimal <- PKNCAresults(data.frame(a = 1), data = list())
  expect_true(is.na(PKNCA:::pknca_cdisc_get_timeu(minimal)))
})

test_that("pknca_cdisc_get_last_dose_time returns NA when no dose data", {
  d_conc <- data.frame(subject = rep(1, 4), time = 0:3, conc = c(0, 1, 0.5, 0.25))
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 3, cmax = TRUE))
  suppressMessages(o_nca <- pk.nca(o_data))

  ret <- as.data.frame(o_nca)
  result <- PKNCA:::pknca_cdisc_get_last_dose_time(ret, o_nca)
  expect_true(all(is.na(result)))
})

