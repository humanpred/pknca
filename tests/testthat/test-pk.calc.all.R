test_that("pk.nca", {
  # Note that generate.conc sets the random seed, so it doesn't have to happen
  # here.
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose)
  myresult <- pk.nca(mydata)

  expect_equal(names(myresult),
               c("result", "data", "columns"),
               info="Make sure that the result has the expected names (and only the expected names) in it.")
  expect_true(checkProvenance(myresult),
              info="Provenance works on results")

  mydata.failure <- mydata
  # There's no way to automatically make a PKNCAdata object with no intervals,
  # but we want to ensure that users cannot cause this error by playing in the
  # internals.
  mydata.failure$intervals <- data.frame()
  expect_warning(myresult.failure <- pk.nca(mydata.failure),
                 regexp="No intervals given; no calculations will be done.",
                 info="An empty result is returned if there are no intervals")

  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose.nodose <- PKNCAdose(tmpdose, formula=~time|treatment+ID)
  mydata.nodose <- PKNCAdata(myconc, mydose.nodose)
  expect_equal(
    pk.nca(mydata.nodose)$result,
    myresult$result,
    info="missing dose information is handled without an issue"
  )

  # Test each of the pieces for myresult for accuracy

  expect_equal(myresult$data, {
    tmp <- mydata
    # The options should be the default options after the calculations are done.
    tmp$options <- PKNCA.options()
    tmp
  }, info="The data is just a copy of the input data plus an instantiation of the PKNCA.options")

  verify.result <-
    tibble::tibble(
      treatment="Trt 1",
      ID=rep(c(1, 2), each=16),
      start=0,
      end=c(24, rep(Inf, 15),
            24, rep(Inf, 15)),
      PPTESTCD=rep(c("auclast", "cmax", "tmax", "tlast", "clast.obs",
                     "lambda.z", "r.squared", "adj.r.squared", "lambda.z.corrxy",
                     "lambda.z.time.first", "lambda.z.time.last",
                     "lambda.z.n.points", "clast.pred", "half.life",
                     "span.ratio", "aucinf.obs"),
                   times=2),
      PPORRES=c(13.54, 0.9998, 4.000, 24.00, 0.3441,
                0.04297, 0.9072, 0.9021, -0.952, 5.000, 24.00,
                20.00, 0.3356, 16.13, 1.178,
                21.55, 14.03, 0.9410, 2.000,
                24.00, 0.3148, 0.05689, 0.9000, 0.8944, -0.952,
                5.000, 24.00, 20.00, 0.3011, 12.18,
                1.560, 19.56),
      PPANMETH = c(
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
    myresult$result,
    verify.result,
    tolerance=0.001,
    info=paste("The specific order of the levels isn't important--",
               "the fact that they are factors and that the set",
               "doesn't change is important.")
  )

  # Specifying new intervals
  mydata.newinterval <-
      PKNCAdata(myconc, mydose,
                intervals=data.frame(start=0, end=c(24, Inf),
                                     auclast=c(TRUE, FALSE),
                                     aucinf.obs=c(FALSE, TRUE),
                                     cmax=c(FALSE, TRUE),
                                     tmax=c(FALSE, TRUE),
                                     half.life=c(FALSE, TRUE)))
  myresult.newinterval <- pk.nca(mydata)
  expect_equal(myresult.newinterval$result,
               myresult$result,
               info="Intervals can be specified manually, and will apply across appropriate parts of the grouping variables.")


  # Dosing not at time 0
  tmpconc.multi <- generate.conc(2, 1, 0:24)
  tmpdose.multi <- generate.dose(tmpconc.multi)
  tmpconc.multi$time <- tmpconc.multi$time + 2
  tmpdose.multi$time <- tmpdose.multi$time + 2
  myconc.multi <- PKNCAconc(tmpconc.multi, conc~time|treatment+ID)
  mydose.multi <- PKNCAdose(tmpdose.multi, dose~time|treatment+ID)
  mydata.multi <- PKNCAdata(myconc.multi, mydose.multi)
  myresult.multi <- pk.nca(mydata.multi)

  verify.result.multi <- verify.result
  verify.result.multi$start <- verify.result.multi$start + 2
  verify.result.multi$end <- verify.result.multi$end + 2
  expect_equal(myresult.multi$result, verify.result.multi,
               tolerance=0.001,
               info="Shifted dosing works the same as un-shifted where time parameters like tmax and tlast are reported relative to the start of the interval")

  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=0, end=Inf, cmax=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(myresult$result$PPORRES,
               c(0.99981, 0.94097), tolerance=0.00001,
               info="Calculations work with a single row of intervals and a single parameter requested")

  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=0, end=Inf, cl.obs=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(subset(myresult$result, PPTESTCD %in% "cl.obs")$PPORRES,
               c(0.04640, 0.05111), tolerance=0.0001,
               info="PK intervals work with passing in dose as a parameter")

  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=0, end=24, cmax=TRUE, cav=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(subset(myresult$result, PPTESTCD %in% "cav")$PPORRES,
               c(0.5642, 0.5846), tolerance=0.0001,
               info="PK intervals work with passing in start and end as parameters")

  # Ensure that the correct number of doses are included in parameters that use dosing.
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  tmpdose$time <- NULL
  tmpdose <- merge(tmpdose, data.frame(time=c(0, 6, 12, 18, 24)))
  myconc <- PKNCAconc(tmpconc, conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=0, end=24, cl.obs=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(myresult$result$PPORRES[myresult$result$PPTESTCD %in% "cl.obs"],
               4/myresult$result$PPORRES[myresult$result$PPTESTCD %in% "aucinf.obs"],
               tolerance=0.0001,
               info="The correct number of doses is selected for an interval (>=start and <end), 4 doses and not 5")

  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=0, end=6, cl.last=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(myresult$result$PPORRES[myresult$result$PPTESTCD %in% "cl.last"],
               1/myresult$result$PPORRES[myresult$result$PPTESTCD %in% "auclast"],
               tolerance=0.0001,
               info="The correct number of doses is selected for an interval (>=start and <end), 1 dose and not 5")

  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=1, end=6, cl.last=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(myresult$result$PPORRES[myresult$result$PPTESTCD %in% "cl.last"],
               NA/myresult$result$PPORRES[myresult$result$PPTESTCD %in% "auclast"],
               tolerance=0.0001,
               info="The correct number of doses is selected for an interval (>=start and <end), no doses selected")

})

test_that("verbose pk.nca", {
  tmpconc <- generate.conc(nsub=1, ntreat=1, 0:4)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time)
  mydose <- PKNCAdose(tmpdose, formula=dose~time)
  mydata <- PKNCAdata(myconc, mydose)
  expect_message(expect_message(expect_message(
    suppressWarnings(pk.nca(mydata, verbose=TRUE)),
    regexp = "Setting up options"),
    regexp = "Starting dense PK NCA calculations"),
    regexp = "Combining completed dense PK calculation results"
  )
  expect_message(
    suppressWarnings(pk.nca(mydata, verbose=FALSE)),
    NA
  )
})

test_that("pk.nca warnings", {
  tmpconc <- generate.conc(nsub=1, ntreat=1, 0:4)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time)
  mydose <- PKNCAdose(tmpdose, formula=dose~time)
  mydata <- PKNCAdata(myconc, mydose, intervals=data.frame(start=24, end=48, cmax=TRUE))
  expect_warning(
    pk.nca(mydata),
    regexp="No data for interval"
  )
})

test_that("pk.nca.interval errors", {
  expect_error(
    pk.nca.interval(interval="A"),
    regexp="Please report a bug.  Interval must be a one-row data.frame",
    class = "pknca_error_internal_interval_not_one_row_df"
  )
  expect_error(
    pk.nca.interval(interval=data.frame()),
    regexp="Please report a bug.  Interval must be a one-row data.frame",
    class = "pknca_error_internal_interval_not_one_row_df"
  )
})

test_that("a parameter needing an interval column says so instead of asking for a bug report", {
  d_conc <- data.frame(conc = 2^(0:-5), time = 0:5)
  o_conc <- PKNCAconc(d_conc, conc~time)
  # `conc_above` for time_above has to be given by the user as an interval
  # column, and `f` needs a reference interval to take its comparator from.
  # `tau` does not belong here: it is detected from the dose times when it is
  # not given, and is NA with a warning when it can be neither given nor
  # detected.
  needs_interval_col <-
    list(
      time_above = "Cannot find argument 'conc_above' for NCA parameter 'time_above' (calculated by 'pk.calc.time_above'); give it as a column in the interval specification",
      f.obs = "The secondary parameter 'f.obs' needs a reference interval for its 'dose1' argument (the value of 'totdose' from another interval). Set the 'f.obs_ref' column in the interval specification to the 'interval_id' of the reference interval, give `group_ref` to PKNCAdata(), or use interval_add_secondary()."
    )
  for (current_param in names(needs_interval_col)) {
    d_interval <- data.frame(start = 0, end = Inf)
    d_interval[[current_param]] <- TRUE
    o_data <- PKNCAdata(o_conc, intervals = d_interval)
    # purrr wraps the error it gets from pk.nca(), so the text is checked in the
    # whole chain rather than in the top condition
    current_message <-
      conditionMessage(tryCatch(
        suppressMessages(suppressWarnings(pk.nca(o_data))),
        error = function(e) e
      ))
    expect_true(grepl(needs_interval_col[[current_param]], current_message, fixed = TRUE))
    expect_false(grepl("report a bug", current_message, fixed = TRUE))
  }
  # Supplying the column makes the parameter calculable
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, time_above = TRUE, conc_above = 0.2))
  suppressMessages(suppressWarnings(o_nca <- pk.nca(o_data)))
  expect_equal(as.data.frame(o_nca)$PPTESTCD, "time_above")
})

test_that("interval_calculation_error asks for a bug report only when PKNCA did not diagnose the error", {
  preamble <- "Error with interval start=0, end=Inf"
  # Diagnosed by PKNCA: the message already says what to change
  err_diagnosed <-
    tryCatch(
      interval_calculation_error(
        rlang::catch_cnd(rlang::abort("say what to change", class = "pknca_error_invalid_route")),
        error_preamble = preamble
      ),
      error = function(e) e
    )
  expect_s3_class(err_diagnosed, "pknca_error_interval_calculation")
  expect_equal(err_diagnosed$message, paste0(preamble, ": say what to change"))
  # Internal: PKNCA did not expect this
  err_internal <-
    tryCatch(
      interval_calculation_error(
        rlang::catch_cnd(rlang::abort("should not happen", class = "pknca_error_internal_tlast")),
        error_preamble = preamble
      ),
      error = function(e) e
    )
  expect_equal(
    err_internal$message,
    paste0("Please report a bug.\n", preamble, ": should not happen")
  )
  # Unclassed errors from outside PKNCA are also unexpected
  err_unclassed <-
    tryCatch(
      interval_calculation_error(
        rlang::catch_cnd(stop("from somewhere else")),
        error_preamble = preamble
      ),
      error = function(e) e
    )
  expect_equal(
    err_unclassed$message,
    paste0("Please report a bug.\n", preamble, ": from somewhere else")
  )
})

test_that("Calculations when dose time is missing", {
  # Ensure that the correct number of doses are included in parameters that use dosing.
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, dose~.|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=0, end=24, cl.obs=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(
    myresult$result$PPORRES[myresult$result$PPTESTCD %in% "cl.obs"],
    1/myresult$result$PPORRES[myresult$result$PPTESTCD %in% "aucinf.obs"],
    info="The correct number of doses is selected for an interval (>=start and <end), 4 doses and not 5"
  )
})

test_that("Calculations when no dose info is given", {
  tmpconc <- generate.conc(2, 1, 0:24)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydata <- PKNCAdata(myconc, intervals=data.frame(start=0, end=24, cmax=TRUE, cl.last=TRUE))
  # cmax needs no dosing information, cl.last needs the dose amount (#538)
  expect_message(
    myresult <- pk.nca(mydata),
    regexp="these parameters will not be calculated: cl.last",
    fixed=TRUE
  )
  expect_equal(
    myresult$result,
    tibble::tibble(
      treatment="Trt 1",
      ID=rep(1:2, each=3),
      start=0,
      end=24,
      PPTESTCD=rep(c("auclast", "cmax", "cl.last"), 2),
      PPORRES=c(13.5417297156528, 0.999812606062292, NA,
                14.0305397438242, 0.94097296083447, NA),
      PPANMETH = c(
        "AUC: lin up/log down",
        rep("", 2),
        "AUC: lin up/log down",
        rep("", 2)
      ),
      exclude=NA_character_
    )
  )
})

test_that("pk.nca with exclusions", {
  # Note that generate.conc sets the random seed, so it doesn't have to happen
  # here.
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose)
  myresult <- pk.nca(mydata)
  tmpconc.excl <- tmpconc
  tmpconc.excl$excl <- NA_character_
  tmpconc.excl$excl[5] <- "test exclusion"
  myconc.excl <- PKNCAconc(tmpconc.excl,
                           formula=conc~time|treatment+ID,
                           exclude="excl")
  mydata.excl <- PKNCAdata(myconc.excl, mydose)
  myresult.excl <- pk.nca(mydata.excl)
  expect_true(identical(myresult$result[myresult$result$ID %in% 2,],
                        myresult.excl$result[myresult.excl$result$ID %in% 2,]),
               info="Results are unchanged for the subject who has the same data")
  expect_false(identical(myresult$result[myresult$result$ID %in% 1,],
                         myresult.excl$result[myresult.excl$result$ID %in% 1,]),
               info="Results are changed for the subject who has the same data")
  expect_equal(myresult.excl$result$PPORRES[myresult.excl$result$ID %in% 1 & myresult.excl$result$PPTESTCD %in% "cmax"],
               max(tmpconc.excl$conc[tmpconc.excl$ID %in% 1 & is.na(tmpconc.excl$excl)]),
               info="Cmax is affected by the exclusion")
})

test_that("pk.calc.all with duration.dose required", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  tmpdose$duration_dose <- 0.1
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID, duration="duration_dose", route="intravascular")
  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=0, end=24,
                                           mrt.iv.last=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(myresult$result$PPORRES[myresult$result$PPTESTCD %in% "mrt.iv.last"],
               c(10.36263, 10.12515),
               tolerance=1e-5,
               info="duration.dose is used when requested")
})

test_that("pk.calc.all with duration.conc required", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  tmpconc$duration_conc <- 0.1
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID, duration="duration_conc")
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID, route="intravascular")
  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=0, end=24,
                                           mrt.iv.last=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(myresult$result$PPORRES[myresult$result$PPTESTCD %in% "mrt.iv.last"],
               c(10.41263, 10.17515),
               tolerance=1e-5,
               info="duration.conc is used when requested")
})

test_that("half life inclusion and exclusion", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  tmpconc$include_hl <- tmpconc$time <= 22
  tmpconc$exclude_hl <- tmpconc$time == 22
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  myconc_incl <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID,
                           include_half.life="include_hl")
  myconc_excl <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID,
                           exclude_half.life="exclude_hl")
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <-  PKNCAdata(myconc, mydose,
                       intervals=data.frame(start=0, end=24, half.life=TRUE))
  mydata_incl <- PKNCAdata(myconc_incl, mydose,
                           intervals=data.frame(start=0, end=24, half.life=TRUE))
  mydata_excl <- PKNCAdata(myconc_excl, mydose,
                           intervals=data.frame(start=0, end=24, half.life=TRUE))
  myresult <- pk.nca(mydata)
  myresult_incl <- pk.nca(mydata_incl)
  myresult_excl <- pk.nca(mydata_excl)
  expect_false(identical(myresult$result, myresult_excl$result))
  expect_false(identical(myresult$result, myresult_incl$result))
})

test_that("include_half.life and exclude_half.life work with NAs treated as missing for all NA and as FALSE for partial NA (#372)", {
  # Partial NA include_hl is used
  d_conc_incl <- data.frame(conc = c(1, 0.6, 0.3, 0.25, 0.15, 0.1), time = 0:5, include_hl = c(FALSE, NA, TRUE, TRUE, TRUE, TRUE))
  o_conc_incl <- PKNCAconc(d_conc_incl, conc~time, include_half.life = "include_hl")
  o_data_incl <- PKNCAdata(o_conc_incl, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  suppressMessages(o_nca_incl <- pk.nca(o_data_incl))
  expect_equal(as.data.frame(o_nca_incl, out_format = "wide")$half.life, 1.820879, tolerance = 0.00001)

  # All FALSE include_hl is used
  d_conc_false <- data.frame(conc = c(1, 0.6, 0.3, 0.25, 0.15, 0.1), time = 0:5, include_hl = FALSE)
  o_conc_false <- PKNCAconc(d_conc_false, conc~time, include_half.life = "include_hl")
  o_data_false <- PKNCAdata(o_conc_false, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  suppressWarnings(suppressMessages(o_nca_false <- pk.nca(o_data_false)))
  d_nca_false <- as.data.frame(o_nca_false)
  expect_equal(d_nca_false$PPORRES[d_nca_false$PPTESTCD %in% "half.life"], NA_real_)

  # All NA include_hl is ignored
  d_conc <- data.frame(conc = c(1, 0.6, 0.3, 0.25, 0.15, 0.1), time = 0:5, include_hl = NA)
  o_conc <- PKNCAconc(d_conc, conc~time, include_half.life = "include_hl")
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  suppressMessages(o_nca <- pk.nca(o_data))
  expect_equal(as.data.frame(o_nca, out_format = "wide")$half.life, 1.512942, tolerance = 0.00001)

  # Partial NA include_hl is used
  d_conc_excl <- data.frame(conc = c(1, 0.6, 0.3, 0.25, 0.15, 0.1), time = 0:5, exclude_hl = c(FALSE, NA, TRUE, TRUE, TRUE, TRUE))
  o_conc_excl <- PKNCAconc(d_conc_excl, conc~time, exclude_half.life = "exclude_hl")
  o_data_excl <- PKNCAdata(o_conc_excl, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  suppressWarnings(suppressMessages(o_nca_excl <- pk.nca(o_data_excl)))
  d_nca_excl <- as.data.frame(o_nca_excl)
  expect_equal(d_nca_excl$PPORRES[d_nca_excl$PPTESTCD %in% "half.life"], NA_real_)

  # All NA exclude_hl is ignored
  d_conc <- data.frame(conc = c(1, 0.6, 0.3, 0.25, 0.15, 0.1), time = 0:5, exclude_hl = NA)
  o_conc <- PKNCAconc(d_conc, conc~time, exclude_half.life = "exclude_hl")
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  suppressMessages(o_nca <- pk.nca(o_data))
  expect_equal(as.data.frame(o_nca, out_format = "wide")$half.life, 1.512942, tolerance = 0.00001)

  # All FALSE exclude_hl is used
  d_conc_false <- data.frame(conc = c(1, 0.6, 0.3, 0.25, 0.15, 0.1), time = 0:5, exclude_hl = FALSE)
  o_conc_false <- PKNCAconc(d_conc_false, conc~time, exclude_half.life = "exclude_hl")
  o_data_false <- PKNCAdata(o_conc_false, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  suppressWarnings(suppressMessages(o_nca_false <- pk.nca(o_data_false)))
  d_nca_false <- as.data.frame(o_nca_false)
  expect_equal(d_nca_false$PPORRES[d_nca_false$PPTESTCD %in% "half.life"], 1.512942, tolerance = 0.00001)
})

test_that("non-logical half-life point columns fail loud at calculation time (#583)", {
  # PKNCAconc() validates at construction, so replace the column afterward to
  # reach the check in pk.nca()
  d_conc <-
    data.frame(
      conc = c(1, 0.5, 0.25, 0.125, 0.06),
      time = 0:4,
      excl = c(NA, NA, NA, TRUE, NA),
      incl = c(NA, TRUE, TRUE, TRUE, NA),
      subject = 1
    )
  o_conc_excl <- PKNCAconc(d_conc, conc ~ time | subject, exclude_half.life = "excl")
  o_data_excl <- PKNCAdata(o_conc_excl, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_data_excl$conc$data$excl <- ifelse(is.na(d_conc$excl), NA_character_, "yes")
  expect_error(
    suppressMessages(pk.nca(o_data_excl)),
    regexp = "The exclude_half.life column ('excl') must be a logical (TRUE/FALSE/NA) column, not character",
    fixed = TRUE
  )

  o_conc_incl <- PKNCAconc(d_conc, conc ~ time | subject, include_half.life = "incl")
  o_data_incl <- PKNCAdata(o_conc_incl, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_data_incl$conc$data$incl <- ifelse(is.na(d_conc$incl), NA_character_, "yes")
  expect_error(
    suppressMessages(pk.nca(o_data_incl)),
    regexp = "The include_half.life column ('incl') must be a logical (TRUE/FALSE/NA) column, not character",
    fixed = TRUE
  )
})

test_that("No interval requested (e.g. for placebo)", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <-
    PKNCAdata(
      myconc, mydose,
      intervals=
        data.frame(
          treatment="Trt 3", start=0, end=24, cmax=TRUE
        )
    )
  expect_warning(expect_warning(expect_warning(expect_warning(
    myresult <- pk.nca(mydata),
    class = "pknca_warning_no_intervals"),
    class = "pknca_warning_no_intervals"),
    class = "pknca_warning_no_conc_data"),
    class = "pknca_warning_no_results"
  )
  expect_equal(
    nrow(as.data.frame(myresult)),
    0,
    info="No rows were generated when no intervals applied"
  )
})

test_that("Volume-related calculations", {
  tmpconc <- generate.conc(2, 1, c(4, 12, 24))
  tmpconc$conc <- seq_len(nrow(tmpconc))
  tmpconc$vol <- 2
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID, volume="vol")
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <-  PKNCAdata(myconc, mydose,
                       intervals=data.frame(treatment="Trt 1", start=0, end=24,
                                            ae=TRUE, fe=TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(as.data.frame(myresult)[["PPORRES"]], c(12, 12, 30, 30),
              info="ae and fe are correctly calculated")
  tmpdose2 <- tmpdose
  tmpdose2$dose <- 2
  mydose2 <- PKNCAdose(tmpdose2, formula=dose~time|treatment+ID)
  mydata2 <-  PKNCAdata(myconc, mydose2,
                       intervals=data.frame(treatment="Trt 1", start=0, end=24,
                                            ae=TRUE, fe=TRUE))
  myresult2 <- pk.nca(mydata2)
  expect_equal(as.data.frame(myresult2)[["PPORRES"]], c(12, 6, 30, 15),
               info="fe respects dose")
})

test_that("pk.nca can calculate values with group-level data", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  tmpdose$time <- 0.5

  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  # aucint reads the group-level concentrations, so an interval ending between
  # two measurements interpolates the concentration at its end; auclast, which
  # only sees the interval's own data, stops at the last measurement within it.
  mydata_part <-
    PKNCAdata(myconc, mydose,
              intervals=data.frame(treatment="Trt 1", start=0, end=4.5,
                                   auclast=TRUE, aucint.last=TRUE))
  res_part <- as.data.frame(pk.nca(mydata_part))
  auclast_part <- res_part$PPORRES[res_part$PPTESTCD %in% "auclast"]
  aucint_part <- res_part$PPORRES[res_part$PPTESTCD %in% "aucint.last"]
  expect_true(all(aucint_part > auclast_part))

  # Over the whole profile there is nothing outside the interval to look at, and
  # the dose at 0.5 within the interval is integrated across rather than
  # estimated at, so the two agree
  mydata_full <-
    PKNCAdata(myconc, mydose,
              intervals=data.frame(treatment="Trt 1", start=0, end=24,
                                   auclast=TRUE, aucint.last=TRUE))
  res_full <- as.data.frame(pk.nca(mydata_full))
  expect_equal(
    res_full$PPORRES[res_full$PPTESTCD %in% "aucint.last"],
    res_full$PPORRES[res_full$PPTESTCD %in% "auclast"],
    info="A dose within the interval does not add a point to integrate to"
  )
})

test_that("Missing dose info for some subjects gives a warning, not a difficult-to-interpret error", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)[1,]
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <-  PKNCAdata(myconc, mydose,
                       intervals=data.frame(start=0, end=24,
                                            cl.last=TRUE))
  myresult <- pk.nca(mydata)
  expect_true(all(is.na(myresult$result[["PPORRES"]]) == c(FALSE, FALSE, FALSE, TRUE)) &
                all(myresult$result[["PPTESTCD"]] == rep(c("auclast", "cl.last"), 2)),
              info="cl.last is not calculated when dose information is missing, but only for the subject where dose info is missing.")
})

# Fix issue #68
test_that("Ensure that options are respected during pk.nca call", {
  doses <- data.frame(ID=1:2, Time=0, Dose=0.5)

  conc.data <- c(0, 1, 2, 1.3, 0.4, 0.35, 0.125)
  time.data <- c(0, 1, 2, 4,   8,   24,   48)
  concs <- merge(doses["ID"], data.frame(Conc=conc.data, Time=time.data))

  myconc <- PKNCA::PKNCAconc(concs, formula=Conc~Time|ID)
  mydose <- PKNCA::PKNCAdose(doses, formula=Dose~Time|ID)

  myintervals <- data.frame(start=c(0,0,0),
                            end=c(24,48,Inf),
                            auclast=TRUE,
                            aucinf.obs=TRUE,
                            aucinf.pred=TRUE,
                            aumclast=TRUE,
                            aumcall=TRUE,
                            half.life=TRUE)

  linear.mydata <- PKNCA::PKNCAdata(myconc, mydose, intervals = myintervals,
                                    options = list(auc.method = "linear"))
  linear.results <- PKNCA::pk.nca(linear.mydata)

  linlog.mydata <- PKNCA::PKNCAdata(myconc, mydose, intervals = myintervals,
                                    options = list(auc.method = "lin up/log down"))
  linlog.results <- PKNCA::pk.nca(linlog.mydata)
  expect_true(
    all.equal(
      linear.results$result$PPORRES[linear.results$result$PPTESTCD %in% "aucinf.obs" &
                                      linear.results$result$ID %in% 1 &
                                      linear.results$result$end %in% Inf],
      24.54319,
      tolerance=0.0001) &
      all.equal(
        linlog.results$result$PPORRES[linlog.results$result$PPTESTCD %in% "aucinf.obs" &
                                        linlog.results$result$ID %in% 1 &
                                        linlog.results$result$end %in% Inf],
        23.68317,
        tolerance=0.0001),
    info="linear and loglinear effects are calculated differently."
  )
})

test_that("Can calculate parameters requiring extra arguments", {
  o_conc <- PKNCAconc(conc~time, data=data.frame(conc=c(1:3, 2:1), time=0:4))
  d_intervals <- data.frame(start=0, end=4, time_above=TRUE, conc_above=2)
  o_data <- PKNCAdata(o_conc, intervals=d_intervals, options=list(auc.method="linear"))
  o_nca <- suppressMessages(pk.nca(o_data))
  expect_equal(as.data.frame(o_nca)$PPORRES, 2)
})

test_that("calculate with sparse data", {
  d_sparse <-
    data.frame(
      id = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 4L, 5L, 6L, 7L, 8L, 9L, 7L, 8L, 9L),
      conc = c(0, 0, 0,  1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 3.03, 1.98, 2.22, 3.34, 1.3, 1.22, 3.54, 2.84, 2.55, 0.3, 0.0421, 0.231),
      time = c(0, 0, 0, 1, 1, 1, 6, 6, 6, 2, 2, 2, 10, 10, 10, 4, 4, 4, 24, 24, 24),
      dose = c(100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100)
    )
  o_conc_sparse <- PKNCAconc(d_sparse, conc~time|id, sparse=TRUE)

  d_intervals <-
    data.frame(
      start=0,
      end=24,
      aucinf.obs=TRUE,
      cmax=TRUE,
      sparse_auclast=TRUE
    )
  o_data_sparse <- PKNCAdata(o_conc_sparse, intervals=d_intervals)
  suppressMessages(
    expect_warning(expect_warning(
      o_nca <- pk.nca(o_data_sparse),
      class = "pknca_warning_sparse_df_multi"),
      class = "pknca_warning_halflife_too_few_points"
    )
  )
  df_result <- as.data.frame(o_nca)
  expect_true("sparse_auclast" %in% df_result$PPTESTCD)
  expect_equal(df_result$PPORRES[df_result$PPTESTCD %in% "sparse_auclast"], 39.4689)
  sum_o_nca <- summary(o_nca)
  expect_s3_class(sum_o_nca, "summary_PKNCAresults")

  # Mixed sparse and dense calculations when only one type is requested in an
  # interval works The example below has dense-only; sparse and dense; and and
  # sparse-only.
  d_intervals_mixed <-
    data.frame(
      start=0,
      end=c(23, 24, 25),
      cmax=c(TRUE, TRUE, FALSE),
      sparse_auclast=c(FALSE, TRUE, TRUE)
    )
  o_data_sparse_mixed <- PKNCAdata(o_conc_sparse, intervals=d_intervals_mixed)
  suppressMessages(
    expect_warning(expect_warning(
      o_nca_sparse_mixed <- pk.nca(o_data_sparse_mixed),
      class = "pknca_warning_sparse_df_multi"),
      class = "pknca_warning_sparse_df_multi"
    )
  )
  df_result_sparse_mixed <- as.data.frame(o_nca_sparse_mixed)
  expect_true("sparse_auclast" %in% df_result_sparse_mixed$PPTESTCD)
  expect_equal(df_result_sparse_mixed$PPORRES[df_result_sparse_mixed$PPTESTCD %in% "sparse_auclast"], rep(39.4689, 2))
  suppressMessages(
    expect_message(
      expect_warning(expect_warning(
        o_nca_sparse_mixed <- pk.nca(o_data_sparse_mixed, verbose=TRUE),
        class = "pknca_warning_sparse_df_multi"),
        class = "pknca_warning_sparse_df_multi"
      ),
      regexp="No sparse calculations requested for an interval"
    )
  )

  # Sparse data with multiple treatments, confirm the correct number of rows of
  # outputs are created.
  d_sparse_200 <- d_sparse
  d_sparse_200$dose <- 200
  d_sparse_multi_trt <- rbind(d_sparse, d_sparse_200)
  d_sparse_multi_trt$dose_grp <- d_sparse_multi_trt$dose
  o_conc_sparse_multi_trt <- PKNCAconc(d_sparse_multi_trt, conc~time|dose_grp+id, sparse=TRUE)
  d_intervals_mixed <-
    data.frame(
      start=0,
      end=c(23, 24, 25),
      cmax=c(TRUE, TRUE, FALSE),
      sparse_auclast=c(FALSE, TRUE, TRUE)
    )
  d_dose_sparse_multi_trt <- unique(d_sparse_multi_trt[, c("id", "dose")])
  d_dose_sparse_multi_trt$time <- 0
  d_dose_sparse_multi_trt$dose_grp <- d_dose_sparse_multi_trt$dose
  o_dose_sparse_multi_trt <- PKNCAdose(d_dose_sparse_multi_trt, dose~time|dose_grp+id)
  o_data_sparse_multi_trt <- PKNCAdata(o_conc_sparse_multi_trt, o_dose_sparse_multi_trt, intervals=d_intervals_mixed)
  suppressMessages(
    expect_warning(expect_warning(expect_warning(expect_warning(
      o_nca_sparse_multi_trt <- pk.nca(o_data_sparse_multi_trt),
      class = "pknca_warning_sparse_df_multi"),
      class = "pknca_warning_sparse_df_multi"),
      class = "pknca_warning_sparse_df_multi"),
      class = "pknca_warning_sparse_df_multi"
    )
  )
  expect_equal(nrow(as.data.frame(o_nca_sparse_multi_trt)), 16)

  # Correct detection of mixed doses within a sparse dose group when there are
  # no grouping columns other than subject
  d_sparse_multi_trt_bad_dose_single <- d_sparse_multi_trt[d_sparse_multi_trt$dose == 100, ]
  d_dose_sparse_multi_trt_bad_dose_single <- unique(d_sparse_multi_trt_bad_dose_single[, c("id", "dose")])
  d_dose_sparse_multi_trt_bad_dose_single$time <- 0
  d_dose_sparse_multi_trt_bad_dose_single$dose[1] <- d_dose_sparse_multi_trt_bad_dose_single$dose[1] + 1
  o_conc_sparse_multi_trt_bad_dose_single <- PKNCAconc(d_sparse_multi_trt_bad_dose_single, conc~time|id, sparse=TRUE)
  o_dose_sparse_multi_trt_bad_dose_single <- PKNCAdose(d_dose_sparse_multi_trt_bad_dose_single, dose~time|id)
  o_data_sparse_multi_trt_bad_dose_single <- PKNCAdata(o_conc_sparse_multi_trt_bad_dose_single, o_dose_sparse_multi_trt_bad_dose_single, intervals=d_intervals_mixed)
  expect_error(
    pk.nca(o_data_sparse_multi_trt_bad_dose_single),
    regexp="With sparse PK, all subjects in a group must have the same dosing information.*Not all subjects have the same dosing information"
  )

  # Correct detection of mixed doses within a sparse dose group
  d_dose_sparse_multi_trt_bad_dose <- d_dose_sparse_multi_trt
  d_dose_sparse_multi_trt_bad_dose$dose[1] <- d_dose_sparse_multi_trt$dose[1] + 1
  o_dose_sparse_multi_trt_bad_dose <- PKNCAdose(d_dose_sparse_multi_trt_bad_dose, dose~time|dose_grp+id)
  o_data_sparse_multi_trt_bad_dose <- PKNCAdata(o_conc_sparse_multi_trt, o_dose_sparse_multi_trt_bad_dose, intervals=d_intervals_mixed)
  expect_error(
    pk.nca(o_data_sparse_multi_trt_bad_dose),
    regexp="With sparse PK, all subjects in a group must have the same dosing information.*Not all subjects have the same dosing information for this group: +dose_grp=100"
  )
  # Correct detection of mixed doses within a sparse dose group when there are no groups
})

test_that("Unexpected interval columns now not cause an error (#238)", {
  d_conc <-
    data.frame(
      ID = 1L,
      time = 0:6,
      conc = c(0, 0.7, 0.71, 0.85, 1, 0.76, 0.74)
    )
  d_dose <- data.frame(dose = 1)
  d_intervals <- data.frame(start = 0, end = 6, cmax = TRUE, aucinf = TRUE)
  o_conc <- PKNCAconc(d_conc, formula = conc~time|ID)
  o_dose <- PKNCAdose(d_dose, formula = dose~.)
  expect_error(PKNCAdata(o_conc, o_dose, intervals = d_intervals),
               "The following columns in 'intervals' are not allowed:"
  )
})

test_that("aucint works within pk.calc.all for all zero concentrations with interpolated or extrapolated concentrations", {
  # AUCint.inf.obs
  d_interval <- data.frame(start = 0, end = 4, aucint.inf.obs = TRUE)
  d_conctime <- data.frame(conc = c(0, 0, 0, 0), time = 0:3)
  o_conc <- PKNCAconc(d_conctime, conc~time)
  o_data <- PKNCAdata(o_conc, intervals = d_interval)
  suppressWarnings(suppressMessages(
    o_nca <- pk.nca(o_data)
  ))
  results <- setNames(as.data.frame(o_nca)$PPORRES, nm = as.data.frame(o_nca)$PPTESTCD)
  zero_names <- c("clast.obs", "aucint.inf.obs")
  na_names <- setdiff(names(results), zero_names)
  expect_equal(
    results[zero_names],
    setNames(rep(0, length(zero_names)), zero_names)
  )
  expect_equal(
    results[na_names],
    setNames(rep(NA_real_, length(na_names)), na_names)
  )

  # AUCint.inf.pred
  d_interval <- data.frame(start = 0, end = 4, aucint.inf.pred = TRUE)
  d_conctime <- data.frame(conc = c(0, 0, 0, 0), time = 0:3)
  o_conc <- PKNCAconc(d_conctime, conc~time)
  o_data <- PKNCAdata(o_conc, intervals = d_interval)
  suppressWarnings(suppressMessages(
    o_nca <- pk.nca(o_data)
  ))
  expect_equal(
    as.data.frame(o_nca)$PPORRES,
    c(rep(NA_real_, 12), 0)
  )
})

test_that("The option keep_interval_cols is respected", {
  d_interval <- data.frame(start = 0, end = 4, cmax = TRUE, foo = "A")
  d_conctime <- data.frame(conc = c(0, 0, 0, 0), time = 0:3)
  o_conc <- PKNCAconc(d_conctime, conc~time)
 expect_error(PKNCAdata(o_conc, intervals = d_interval),
              "The following columns in 'intervals' are not allowed:")

  o_data <- PKNCAdata(o_conc, intervals = d_interval, options = list(keep_interval_cols = "foo"))
  suppressWarnings(suppressMessages(
    o_nca <- pk.nca(o_data)
  ))
  expect_equal(o_nca$result$foo, "A")
  expect_true("foo" %in% names(summary(o_nca)))
})

test_that("dose is calculable", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = data.frame(start = 0, end = Inf, totdose = TRUE))
  myresult <- pk.nca(mydata)

  # One dose in the interval
  expect_equal(as.data.frame(myresult)$PPORRES, rep(1, 2))
  expect_equal(as.data.frame(myresult)$PPTESTCD, rep("totdose", 2))

  # Don't give dose data
  mydata <- PKNCAdata(myconc, intervals = data.frame(start = 0, end = Inf, totdose = TRUE))
  suppressMessages(myresult <- pk.nca(mydata))
  expect_equal(as.data.frame(myresult)$PPORRES, rep(NA_real_, 2))
  expect_equal(as.data.frame(myresult)$PPTESTCD, rep("totdose", 2))

  # Multiple doses in the interval
  tmpdose_second <- tmpdose
  tmpdose_second$time <- 1
  mydose <- PKNCAdose(rbind(tmpdose, tmpdose_second), formula=dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = data.frame(start = 0, end = Inf, totdose = TRUE))
  myresult <- pk.nca(mydata)
  expect_equal(as.data.frame(myresult)$PPORRES, rep(2, 2))
  expect_equal(as.data.frame(myresult)$PPTESTCD, rep("totdose", 2))
})

test_that("do not give rbind error when interval columns have attributes (#381)", {
  o_conc <- PKNCAconc(data = data.frame(conc = 1, time = 0), conc~time)
  d_interval <- data.frame(start = 0, end = Inf, cmax = TRUE, tmax = TRUE)
  attr(d_interval$start, "label") <- "start"
  o_data <- PKNCAdata(o_conc, intervals = d_interval)
  suppressMessages(o_nca <- pk.nca(o_data))
  # interval attributes are preserved
  expect_equal(
    attributes(as.data.frame(o_nca)$start),
    list(label = "start")
  )
})

test_that("pk.nca produces the PPANMETH column", {
  # --- Setup shared concentration and dose data ---
  tmpconc <- generate.conc(1, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)

  # --- PPANMETH differentiates based on the AUC method used ---
  mydata_linear <- PKNCAdata(myconc, mydose, intervals=data.frame(start=0, end=24, auclast=TRUE), options=list(auc.method="linear"))
  mydata_linlog <- PKNCAdata(myconc, mydose, intervals=data.frame(start=0, end=24, auclast=TRUE), options=list(auc.method="lin up/log down"))
  res_linear <- pk.nca(mydata_linear)
  res_linlog <- pk.nca(mydata_linlog)
  expect_true("PPANMETH" %in% names(res_linear$result))
  expect_true("PPANMETH" %in% names(res_linlog$result))
  expect_true(any(grepl("AUC: linear", res_linear$result$PPANMETH, fixed=TRUE)))
  expect_true(any(grepl("AUC: lin up/log down", res_linlog$result$PPANMETH, fixed=TRUE)))

  # --- PPANMETH distinguishes how the half.life was adjusted ---
  tmpconc$include_hl <- tmpconc$time <= 22
  tmpconc$exclude_hl <- tmpconc$time == 22
  myconc_base <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  myconc_incl <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID, include_half.life="include_hl")
  myconc_excl <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID, exclude_half.life="exclude_hl")
  mydata_base <- PKNCAdata(myconc_base, mydose, intervals=data.frame(start=0, end=24, lambda.z=TRUE))
  mydata_incl <- PKNCAdata(myconc_incl, mydose, intervals=data.frame(start=0, end=24, lambda.z=TRUE))
  mydata_excl <- PKNCAdata(myconc_excl, mydose, intervals=data.frame(start=0, end=24, lambda.z=TRUE))
  res_base <- pk.nca(mydata_base)
  res_incl <- pk.nca(mydata_incl)
  res_excl <- pk.nca(mydata_excl)
  expect_true("PPANMETH" %in% names(res_base$result))
  expect_true("PPANMETH" %in% names(res_incl$result))
  expect_true("PPANMETH" %in% names(res_excl$result))
  expect_equal(
    unique(res_base$result$PPANMETH[res_base$result$PPTESTCD %in% c("lambda.z", "half.life", "r.squared")]),
    ""
  )
  expect_equal(
    unique(res_incl$result$PPANMETH[res_incl$result$PPTESTCD %in% c("lambda.z", "half.life", "r.squared")]),
    "Lambda Z: Manual selection"
  )
  expect_equal(
    unique(res_excl$result$PPANMETH[res_excl$result$PPTESTCD %in% c("lambda.z", "half.life", "r.squared")]),
    ""
  )
  expect_equal(
    unique(res_base$result$PPANMETH[res_base$result$PPTESTCD %in% c("tmax", "cmax")]),
    ""
  )
  expect_equal(
    unique(res_incl$result$PPANMETH[res_incl$result$PPTESTCD %in% c("tmax", "cmax")]),
    ""
  )
  expect_equal(
    unique(res_excl$result$PPANMETH[res_excl$result$PPTESTCD %in% c("tmax", "cmax")]),
    ""
  )

  # --- PPANMETH specifies if an imputation method was used in the interval ---
  o_data <- PKNCAdata(myconc, mydose, intervals=data.frame(start=0, end=24, c0=TRUE))
  o_data_impute <- PKNCAdata(myconc, mydose, intervals=data.frame(start=0, end=24, c0=TRUE), impute="start_conc0")
  res <- pk.nca(o_data)
  res_impute <- pk.nca(o_data_impute)
  expect_equal(res$result$PPANMETH, "")
  expect_true("PPANMETH" %in% names(res$result))
  expect_equal(res$result$PPANMETH, "")
  expect_equal(res_impute$result$PPANMETH, "Imputation: start_conc0")

  # --- PPANMETH reports based on the parameter dependencies ---
  mydata <- PKNCAdata(
    myconc_incl, mydose,
    intervals=data.frame(start=0, end=24, c0 = TRUE, half.life = TRUE, aucinf.pred=TRUE),
    impute = "start_conc0"
  )
  res <- pk.nca(mydata)
  expect_equal(
    res$result$PPANMETH[res$result$PPTESTCD == "c0"],
    "Imputation: start_conc0"
  )
  expect_equal(
    res$result$PPANMETH[res$result$PPTESTCD == "half.life"],
    "Imputation: start_conc0. Lambda Z: Manual selection"
  )
  expect_equal(
    res$result$PPANMETH[res$result$PPTESTCD == "aucinf.pred"],
    "Imputation: start_conc0. AUC: lin up/log down"
  )
})

test_that("pk.nca can be run for each parameter independently (#473)", {
  
  # ── Dense data setup ──────────────────────────────────────────────────────
  d_conc <- Theoph[Theoph$Subject %in% "1", ]
  d_conc <- rbind(d_conc, mutate(d_conc, Time = Time + 25))
  d_conc$volume   <- 1
  d_conc$duration <- 1
  d_dose <- data.frame(
    Subject  = "1",
    Time     = c(0, 25),
    Dose     = 5,
    duration = 1
  )
  o_conc_dense <- PKNCAconc(
    d_conc,
    formula  = conc~Time|Subject,
    volume   = "volume",
    duration = "duration"
  )
  o_dose_dense <- PKNCAdose(
    d_dose,
    formula  = Dose~Time|Subject,
    route    = "intravascular",
    duration = "duration"
  )
  
  # ── Sparse data setup ─────────────────────────────────────────────────────
  # Each subject measured at DIFFERENT time points
  # → no shared times → off-diagonal covariance = 0
  # → no warning fires → df calculable (NA only when n=1, silently)
  d_sparse <- data.frame(
    conc = c(
      1.0, 3.0, 2.0, 0.5,    # Subject A
      2.0, 2.5, 1.5, 0.8,    # Subject B
      1.5, 3.5, 1.8, 0.6     # Subject C
    ),
    time = c(
      0,  3,  7, 11,          # Subject A — unique times
      1,  4,  8, 12,          # Subject B — unique times
      2,  5,  9, 10           # Subject C — unique times
    ),
    Subject = c(rep("A", 4), rep("B", 4), rep("C", 4))
  )
  d_dose_sparse <- data.frame(
    Subject  = c("A", "B", "C"),
    time     = c(0, 0, 0),
    Dose     = c(5, 5, 5),
    duration = c(1, 1, 1)
  )
  
  o_conc_sparse <- PKNCAconc(
    d_sparse,
    formula = conc~time|Subject,
    sparse  = TRUE
  )
  o_dose_sparse <- PKNCAdose(
    d_dose_sparse,
    formula  = Dose~time|Subject,
    route    = "extravascular",
    duration = "duration"
  )
  
  # ── Params that cannot be tested independently ────────────────────────────
  # These require special data structures or multi-dose designs
  # and are tested in dedicated tests elsewhere
  # A secondary parameter needs a reference interval to take its comparator
  # from, so one interval alone cannot calculate any of them; they are covered
  # in test-secondary-parameters.R.  Derived from the classification so that a
  # newly registered secondary parameter is excluded without editing this list.
  parameter_table <- pknca_parameter_table()
  non_pknca_covered_params <- c(
    "time_above",
    "sparse_auc_se", "sparse_auc_df",
    "sparse_aumc_se", "sparse_aumc_df",
    "ceoi",
    parameter_table$parameter[parameter_table$secondary]
  )
  
  all_params <- setdiff(
    names(get.interval.cols()),
    c("start", "end", non_pknca_covered_params)
  )
  
  # ── Classify params as sparse or dense ───────────────────────────────────
  all_interval_cols <- get.interval.cols()
  sparse_params <- Filter(
    function(p) isTRUE(all_interval_cols[[p]]$sparse),
    all_params
  )
  dense_params <- setdiff(all_params, sparse_params)
  
  # ── Intervals ─────────────────────────────────────────────────────────────
  intervals_dense  <- data.frame(start = c(0, 25), end = c(25, Inf))
  
  # sparse_auclast and sparse_aumclast must be TRUE so that
  # dependent params (cl.sparse.last, mrt.sparse.last etc.)
  # have their dependencies available in the pipeline
  intervals_sparse <- data.frame(
    start           = 0,
    end             = 12,
    sparse_auclast  = TRUE,
    sparse_aumclast = TRUE
  )
  
  # ── Test dense params with dense data ────────────────────────────────────
  for (param in dense_params) {
    intervals_with_param <- intervals_dense
    intervals_with_param[[param]] <- TRUE
    o_data <- PKNCAdata(o_conc_dense, o_dose_dense,
                        intervals = intervals_with_param)
    expect_no_error(
      param_res <- pk.nca(o_data)
    )
    expect_false(
      all(is.na(param_res$result$PPORRES)),
      info = paste0("Parameter ", param, " can be calculated independently")
    )
  }
  
  # ── Test sparse params with sparse data ──────────────────────────────────
  for (param in sparse_params) {
    intervals_with_param <- intervals_sparse
    intervals_with_param[[param]] <- TRUE
    o_data <- PKNCAdata(o_conc_sparse, o_dose_sparse,
                        intervals = intervals_with_param)
    expect_no_error(
      param_res <- pk.nca(o_data)
    )
    expect_false(
      all(is.na(param_res$result$PPORRES)),
      info = paste0("Parameter ", param, " can be calculated independently")
    )
  }
})


test_that("Cannot include and exclude half-life points at the same time (#406)", {
  o_conc <- PKNCAconc(data = data.frame(conc = 1, time = 0, inex = TRUE), conc~time, include_half.life = "inex", exclude_half.life = "inex")
  d_interval <- data.frame(start = 0, end = Inf, half.life = TRUE)
  o_data <- PKNCAdata(o_conc, intervals = d_interval)
  expect_error(
    suppressMessages(pk.nca(o_data)),
    regexp = "Cannot both include and exclude half-life points for the same interval"
  )
})

test_that("pk.nca.interval covers route, volume.group, duration.conc.group, dose.group, duration.dose.group, route.group branches", {
  # Lines 449, 457, 459, 461, 467, 469 in pk.calc.all.R are only reached when a
  # registered NCA function has one of these names as a formal argument.
  # Register a temporary test function that accepts all six, save and restore state.
  fn_name <- "pknca_test_grp_args_cov_fn_"
  assign(
    fn_name,
    function(conc, time, route, volume.group, duration.conc.group,
             dose.group, duration.dose.group, route.group) {
      sum(conc, na.rm = TRUE)
    },
    envir = .GlobalEnv
  )
  local_interval_cols()
  on.exit(rm(list = fn_name, envir = .GlobalEnv), add = TRUE)

  add.interval.col(
    "pknca_test_grp_args_cov_col_",
    FUN = fn_name,
    unit_type = "conc",
    pretty_name = "Test: group arg branches",
    desc = "Coverage test for group arg branches"
  )

  d <- as.data.frame(datasets::Theoph[datasets::Theoph$Subject == "1", ])
  d$volume <- 1
  d$duration <- 1
  d_dose <- d[d$Time == 0, , drop = FALSE]

  o_conc <- PKNCAconc(d, formula = conc~Time|Subject, volume = "volume", duration = "duration")
  o_dose <- PKNCAdose(d_dose, formula = Dose~Time|Subject, route = "intravascular", duration = "duration")
  o_data <- PKNCAdata(
    o_conc, o_dose,
    intervals = data.frame(start = 0, end = 24, pknca_test_grp_args_cov_col_ = TRUE)
  )
  result <- pk.nca(o_data)
  expect_true("pknca_test_grp_args_cov_col_" %in% as.data.frame(result)$PPTESTCD)
})

test_that("pk.nca sorts group data by time so unsorted input works (#568)", {
  conc_data <-
    data.frame(
      MRRLT = c(16, -0.8, 3, 6, 8, 12, 20, 25),
      AVAL = c(120, 260, 340, 300, 210, 150, 110, 90)
    )
  conc_sorted <- conc_data[order(conc_data$MRRLT), ]
  dose_data <- data.frame(EXDOSE = 1)

  run_nca <- function(cdat) {
    o_conc <- PKNCAconc(cdat, AVAL ~ MRRLT)
    o_dose <- PKNCAdose(dose_data, EXDOSE ~ .)
    intervals <-
      data.frame(
        start = 0, end = 24,
        aucint.all = TRUE, aucint.last = TRUE, aucint.inf.obs = TRUE,
        cmax = TRUE, half.life = TRUE
      )
    o_data <-
      PKNCAdata(
        o_conc, o_dose, intervals = intervals,
        options = list(auc.method = "linear")
      )
    as.data.frame(suppressWarnings(pk.nca(o_data)))
  }

  # Previously errored with "Assertion on 'time' failed: Must be sorted."
  res_unsorted <- expect_no_error(run_nca(conc_data))
  res_sorted <- run_nca(conc_sorted)

  # aucint* parameters (which use the group-level time/conc) are calculable and
  # identical regardless of the input ordering.
  expect_equal(
    res_unsorted$PPORRES[res_unsorted$PPTESTCD == "aucint.all"],
    4523.263157894737
  )
  # Every parameter matches the pre-sorted calculation.
  merged <-
    merge(
      res_unsorted[, c("PPTESTCD", "PPORRES")],
      res_sorted[, c("PPTESTCD", "PPORRES")],
      by = "PPTESTCD", suffixes = c(".uns", ".srt")
    )
  expect_equal(merged$PPORRES.uns, merged$PPORRES.srt)
})

test_that("mrt.md and vss.md get tau from the intervals or the dose times (#151)", {
  # Steady-state profile for a one-compartment IV bolus with CL=0.5, V=10
  # (k=0.05) dosed 100 every 24 hours, so the true MRT is 1/k = 20 and the true
  # Vss is V = 10.
  tau <- 24
  d_time <- c(0, 0.5, 1, 2, 4, 6, 8, 12, 18, 24)
  d_conc <- 10/(1 - exp(-0.05*tau))*exp(-0.05*d_time)

  # A single dose in the dosing data (the common steady-state design): tau
  # cannot be detected, so it comes from the interval specification.
  o_conc_1 <- PKNCAconc(data.frame(subj=1, time=d_time, conc=d_conc), conc~time|subj)
  o_dose_1 <- PKNCAdose(data.frame(subj=1, time=0, dose=100), dose~time|subj, route="intravascular")
  interval_tau <-
    data.frame(
      start=0, end=tau, tau=tau,
      auclast=TRUE, aumclast=TRUE, aucinf.obs=TRUE, cl.last=TRUE,
      mrt.md.obs=TRUE, vss.md.obs=TRUE
    )
  res_1 <- as.data.frame(pk.nca(PKNCAdata(o_conc_1, o_dose_1, intervals=interval_tau)))
  value_1 <- stats::setNames(res_1$PPORRES, res_1$PPTESTCD)

  # The multiple-dose equation recovers the model's true MRT and Vss exactly
  # here; the single-dose parameters over the same interval do not (mrt.last is
  # AUMClast/AUClast = 9.66).
  expect_equal(value_1[["mrt.md.obs"]], 20, tolerance=1e-8)
  expect_equal(value_1[["vss.md.obs"]], 10, tolerance=1e-8)
  # The wiring is what is under test: confirm the reported value is the
  # multiple-dose equation applied to this interval's own AUC and AUMC.
  expect_equal(
    value_1[["mrt.md.obs"]],
    value_1[["aumclast"]]/value_1[["auclast"]] +
      tau*(value_1[["aucinf.obs"]] - value_1[["auclast"]])/value_1[["auclast"]]
  )
  expect_equal(value_1[["vss.md.obs"]], value_1[["cl.last"]]*value_1[["mrt.md.obs"]])

  # The same profile as the last of four q24h doses: tau is detected from the
  # dose times, so no tau column is needed.
  o_conc_4 <-
    PKNCAconc(data.frame(subj=1, time=3*tau + d_time, conc=d_conc), conc~time|subj)
  o_dose_4 <-
    PKNCAdose(
      data.frame(subj=1, time=(0:3)*tau, dose=100),
      dose~time|subj, route="intravascular"
    )
  interval_detect <-
    data.frame(
      start=3*tau, end=4*tau,
      auclast=TRUE, aumclast=TRUE, aucinf.obs=TRUE, cl.last=TRUE,
      mrt.md.obs=TRUE, vss.md.obs=TRUE
    )
  res_4 <- as.data.frame(pk.nca(PKNCAdata(o_conc_4, o_dose_4, intervals=interval_detect)))
  value_4 <- stats::setNames(res_4$PPORRES, res_4$PPTESTCD)
  expect_equal(value_4[["mrt.md.obs"]], value_1[["mrt.md.obs"]])
  expect_equal(value_4[["vss.md.obs"]], value_1[["vss.md.obs"]])

  # A tau column overrides detection
  interval_override <- interval_detect
  interval_override$tau <- 12
  res_override <-
    as.data.frame(pk.nca(PKNCAdata(o_conc_4, o_dose_4, intervals=interval_override)))
  value_override <- stats::setNames(res_override$PPORRES, res_override$PPTESTCD)
  expect_equal(
    value_override[["mrt.md.obs"]],
    value_1[["aumclast"]]/value_1[["auclast"]] +
      12*(value_1[["aucinf.obs"]] - value_1[["auclast"]])/value_1[["auclast"]]
  )

  # Without a tau column and without repeating doses, the parameter is NA
  # rather than silently falling back to the single-dose equation.
  interval_no_tau <- interval_tau
  interval_no_tau$tau <- NULL
  expect_warning(
    res_na <- as.data.frame(pk.nca(PKNCAdata(o_conc_1, o_dose_1, intervals=interval_no_tau))),
    class="pknca_warning_tau_undetermined"
  )
  value_na <- stats::setNames(res_na$PPORRES, res_na$PPTESTCD)
  expect_equal(value_na[["mrt.md.obs"]], NA_real_)
  expect_equal(value_na[["vss.md.obs"]], NA_real_)
  # The single-dose parameters in the same interval are unaffected
  expect_equal(value_na[["auclast"]], value_1[["auclast"]])
})

test_that("mrt.md.pred and vss.md.pred get tau the same way (#151)", {
  tau <- 12
  d_time <- c(0, 0.5, 1, 2, 4, 6, 9, 12)
  d_conc <- 10/(1 - exp(-0.1*tau))*exp(-0.1*d_time)
  o_conc <- PKNCAconc(data.frame(subj=1, time=d_time, conc=d_conc), conc~time|subj)
  o_dose <- PKNCAdose(data.frame(subj=1, time=0, dose=50), dose~time|subj, route="intravascular")
  interval <-
    data.frame(
      start=0, end=tau, tau=tau,
      auclast=TRUE, aumclast=TRUE, aucinf.pred=TRUE, cl.last=TRUE,
      mrt.md.pred=TRUE, vss.md.pred=TRUE
    )
  res <- as.data.frame(pk.nca(PKNCAdata(o_conc, o_dose, intervals=interval)))
  value <- stats::setNames(res$PPORRES, res$PPTESTCD)
  expect_equal(
    value[["mrt.md.pred"]],
    value[["aumclast"]]/value[["auclast"]] +
      tau*(value[["aucinf.pred"]] - value[["auclast"]])/value[["auclast"]]
  )
  expect_equal(value[["vss.md.pred"]], value[["cl.last"]]*value[["mrt.md.pred"]])
  expect_false(is.na(value[["mrt.md.pred"]]))
})

test_that("mrt.ivmd and vss.ivmd correct the multiple-dose MRT for the infusion duration (#151)", {
  # The same steady-state one-compartment profile as above (CL=0.5, V=10,
  # k=0.05, 100 q24h) given as a 4 hour infusion instead of a bolus.  The true
  # MRT is still 1/k = 20 and the true Vss is still V = 10.
  tau <- 24
  duration <- 4
  d_time <- c(0, 1, 2, 3, 4, 5, 6, 8, 12, 18, 24)
  # Superposition of the single-dose infusion profile over many prior doses
  conc_single <- function(t) {
    rate <- 100/duration
    ifelse(
      t <= duration,
      rate/0.5*(1 - exp(-0.05*t)),
      rate/0.5*(1 - exp(-0.05*duration))*exp(-0.05*(t - duration))
    )
  }
  d_conc <- rowSums(sapply(0:400, function(i) conc_single(d_time + i*tau)))

  o_conc <- PKNCAconc(data.frame(subj=1, time=d_time, conc=d_conc), conc~time|subj)
  o_dose <-
    PKNCAdose(
      data.frame(subj=1, time=0, dose=100, duration=duration),
      dose~time|subj, route="intravascular", duration="duration"
    )
  interval <-
    data.frame(
      start=0, end=tau, tau=tau, cl.last=TRUE,
      mrt.md.obs=TRUE, vss.md.obs=TRUE,
      mrt.ivmd.obs=TRUE, vss.ivmd.obs=TRUE,
      mrt.ivmd.pred=TRUE, vss.ivmd.pred=TRUE
    )
  res <- as.data.frame(pk.nca(PKNCAdata(o_conc, o_dose, intervals=interval)))
  value <- stats::setNames(res$PPORRES, res$PPTESTCD)

  # The IV form hits the true MRT and Vss; the non-IV form is high by
  # duration/2 and by cl.last*duration/2 respectively.
  expect_equal(value[["mrt.ivmd.obs"]], 20, tolerance=1e-3)
  expect_equal(value[["vss.ivmd.obs"]], 10, tolerance=1e-3)
  expect_equal(value[["mrt.ivmd.obs"]], value[["mrt.md.obs"]] - duration/2)
  expect_equal(
    value[["vss.md.obs"]] - value[["vss.ivmd.obs"]],
    value[["cl.last"]]*duration/2
  )
  expect_equal(value[["vss.ivmd.obs"]], value[["cl.last"]]*value[["mrt.ivmd.obs"]])
  expect_equal(value[["vss.ivmd.pred"]], value[["cl.last"]]*value[["mrt.ivmd.pred"]])

  # tau reaches the IV form the same way it reaches the non-IV form.  One
  # warning is raised per requested parameter that takes tau, so collect them
  # all rather than letting the ones expect_warning() does not take escape.
  interval_no_tau <- interval
  interval_no_tau$tau <- NULL
  warn_class <- character()
  res_na <-
    withCallingHandlers(
      as.data.frame(pk.nca(PKNCAdata(o_conc, o_dose, intervals=interval_no_tau))),
      warning = function(w) {
        warn_class <<- c(warn_class, class(w)[1])
        invokeRestart("muffleWarning")
      }
    )
  expect_equal(warn_class, rep("pknca_warning_tau_undetermined", 3),
               info="one warning per requested parameter taking tau")
  value_na <- stats::setNames(res_na$PPORRES, res_na$PPTESTCD)
  expect_equal(value_na[["mrt.ivmd.obs"]], NA_real_)
  expect_equal(value_na[["vss.ivmd.obs"]], NA_real_)
  expect_equal(value_na[["mrt.ivmd.pred"]], NA_real_)
  expect_equal(value_na[["vss.ivmd.pred"]], NA_real_)
})

test_that("an I()-wrapped formalsmap value is passed to the function as a constant", {
  fn_name <- "pknca_test_formalsmap_constant_"
  assign(
    fn_name,
    function(conc, time, multiplier) {
      multiplier * length(conc)
    },
    envir = .GlobalEnv
  )
  local_interval_cols()
  on.exit(rm(list = fn_name, envir = .GlobalEnv), add = TRUE)

  add.interval.col(
    "pknca_test_formalsmap_constant_col_",
    FUN = fn_name,
    unit_type = "conc",
    pretty_name = "Test: formalsmap constant",
    desc = "Coverage test for a formalsmap constant",
    formalsmap = list(multiplier = I(10))
  )
  # A constant is the value itself, not a reference to another parameter
  expect_equal(
    get.parameter.deps("pknca_test_formalsmap_constant_col_", recursive = TRUE),
    c("conc", "time")
  )

  d_conc <- data.frame(conc = c(1, 2, 3), time = c(0, 1, 2))
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time),
      PKNCAdose(data.frame(dose = 1, time = 0), dose~time),
      intervals =
        data.frame(start = 0, end = 24, pknca_test_formalsmap_constant_col_ = TRUE)
    )
  result <- as.data.frame(pk.nca(o_data))
  expect_equal(
    result$PPORRES[result$PPTESTCD == "pknca_test_formalsmap_constant_col_"],
    30
  )
})

test_that("a calculation function returning names without values errors instead of recycling", {
  fn_name <- "pknca_test_zero_row_result_"
  assign(
    fn_name,
    function(conc, time) {
      data.frame(a = numeric(0), b = numeric(0), c = numeric(0))
    },
    envir = .GlobalEnv
  )
  local_interval_cols()
  on.exit(rm(list = fn_name, envir = .GlobalEnv), add = TRUE)

  add.interval.col(
    "pknca_test_zero_row_result_col_",
    FUN = fn_name,
    unit_type = "conc",
    pretty_name = "Test: zero-row result",
    desc = "Shape check for a zero-row result"
  )
  o_data <-
    PKNCAdata(
      PKNCAconc(data.frame(conc = c(1, 2, 3), time = c(0, 1, 2)), conc~time),
      PKNCAdose(data.frame(dose = 1, time = 0), dose~time),
      intervals =
        data.frame(start = 0, end = 24, pknca_test_zero_row_result_col_ = TRUE)
    )
  # A zero-row data.frame gives 3 names and 0 values; padding it out would
  # report NA results under real parameter names, so it must be an error.
  expect_error(
    pk.nca(o_data),
    regexp = "returned 3 result name\\(s\\) and 0 value\\(s\\); it must return one value per name",
    class = "pknca_error_interval_calculation"
  )
})