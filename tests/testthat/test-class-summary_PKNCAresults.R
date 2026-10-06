# These tests are about how results are summarized, so the intervals are given
# explicitly as the single.dose.aucs option:  that is what PKNCAdata() used to
# generate automatically for single-dose data, and it keeps the two-interval
# layout these expectations were written for.  The intervals PKNCAdata() now
# generates come from pknca_interval_table() and are tested in
# test-choose-intervals.R and test-class-PKNCAresults.R.

test_that("PKNCAresults summary", {
  # Note that generate.conc sets the random seed, so it doesn't have
  # to happen here.
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  myresult <- pk.nca(mydata)

  # Testing the summarization
  mysummary <- summary(myresult)
  expect_true(is.data.frame(mysummary))
  expect_equal(
    mysummary,
    as_summary_PKNCAresults(
      data.frame(
        start = 0,
        end = c(24, Inf),
        treatment = "Trt 1",
        N = "2",
        auclast = c("13.8 [2.51]", "."),
        cmax = c(".", "0.970 [4.29]"),
        tmax = c(".", "3.00 [2.00, 4.00]"),
        half.life = c(".", "14.2 [2.79]"),
        aucinf.obs = c(".", "20.5 [6.84]")
      ),
      caption = "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects"
    ),
    info = "simple summary of PKNCAresults performs as expected"
  )

  tmpconc <- generate.conc(2, 1, 0:24)
  tmpconc$conc[tmpconc$ID %in% 2] <- 0
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  # Not capturing the warning due to R bug
  # https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=17122
  # expect_warning(myresult <- pk.nca(mydata),
  #               regexp="Too few points for half-life calculation")
  suppressWarnings(myresult <- pk.nca(mydata))
  mysummary <- summary(myresult)
  expect_equal(
    mysummary,
    as_summary_PKNCAresults(
      data.frame(
        start = 0,
        end = c(24, Inf),
        treatment = "Trt 1",
        N = "2",
        auclast = c("13.5 [NC]", "."),
        cmax = c(".", "1.00 [NC]"),
        tmax = c(".", "4.00, n=1"),
        half.life = c(".", "16.1, n=1"),
        aucinf.obs = c(".", "21.5 [NC]")
      ),
      caption = "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects; n: number of measurements included in summary; NC: not calculated"
    ),
    info = "summary of PKNCAresults with some missing values results in NA for spread"
  )

  tmpconc <- generate.conc(2, 1, 0:24)
  tmpconc$conc <- 0
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  # Not capturing the warning due to R bug
  # https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=17122
  # expect_warning(myresult <- pk.nca(mydata),
  #               regexp="Too few points for half-life calculation")
  suppressWarnings(myresult <- pk.nca(mydata))
  mysummary <- summary(myresult)
  expect_equal(
    mysummary,
    as_summary_PKNCAresults(
      data.frame(
        start = 0,
        end = c(24, Inf),
        treatment = "Trt 1",
        N = "2",
        auclast = c("NC", "."),
        cmax = c(".", "NC"),
        tmax = c(".", "NC"),
        half.life = c(".", "NC"),
        aucinf.obs = c(".", "NC")
      ),
      caption = "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects; NC: not calculated"
    ),
    info = "summary of PKNCAresults without most results gives NC"
  )

  mysummary <- summary(myresult,
    not_requested = "NR",
    not_calculated = "NoCalc"
  )
  expect_equal(
    mysummary,
    as_summary_PKNCAresults(
      data.frame(
        start = 0,
        end = c(24, Inf),
        treatment = "Trt 1",
        N = "2",
        auclast = c("NoCalc", "NR"),
        cmax = c("NR", "NoCalc"),
        tmax = c("NR", "NoCalc"),
        half.life = c("NR", "NoCalc"),
        aucinf.obs = c("NR", "NoCalc")
      ),
      caption = "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects; NoCalc: not calculated"
    ),
    info = "Summary respects the not.requested.string and not.calculated.string"
  )

  mysummary <- summary(myresult,
    summarize_n = FALSE,
    not_requested = "NR",
    not_calculated = "NoCalc"
  )
  expect_equal(
    mysummary,
    as_summary_PKNCAresults(
      data.frame(
        start = 0,
        end = c(24, Inf),
        treatment = "Trt 1",
        auclast = c("NoCalc", "NR"),
        cmax = c("NR", "NoCalc"),
        tmax = c("NR", "NoCalc"),
        half.life = c("NR", "NoCalc"),
        aucinf.obs = c("NR", "NoCalc")
      ),
      caption = "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; NoCalc: not calculated"
    ),
    info = "N is optionally omitted"
  )
})

test_that("PKNCAresults summary counts N correctly", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = data.frame(start = 0, end = c(24, Inf), cmax = TRUE))
  myresult <- pk.nca(mydata)

  # Testing the summarization
  mysummary_two_row <- summary(myresult)
  expect_warning(
    expect_warning(
      mysummary_one_row <- summary(myresult, drop_group = c("ID", "end")),
      "Some subjects may have more than one result for cmax"
    ),
    "drop.group including start or end may result in incorrect groupings"
  )
  expect_equal(mysummary_two_row$N, c("2", "2"))
  expect_equal(mysummary_one_row$N, "2")

  # No subject identifier
  tmpconc <- generate.conc(1, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time)
  mydata <- PKNCAdata(myconc, mydose, intervals = data.frame(start = 0, end = c(24, Inf), cmax = TRUE))
  myresult <- pk.nca(mydata)

  mysummary_one_subject <- summary(myresult)
  expect_false("N" %in% names(mysummary_one_subject))
  expect_warning(
    mysummary_one_subject_askn <- summary(myresult, summarize_n = TRUE),
    "summarize_n was requested, but no subject column exists"
  )
  expect_false("N" %in% names(mysummary_one_subject_askn))
})

test_that("dropping `start` and `end` from groups is allowed with a warning.", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  myresult <- pk.nca(mydata)

  expect_warning(
    current_summary <- summary(myresult, drop_group = c("ID", "start")),
    regexp = "drop.group including start or end may result", fixed = TRUE
  )
  expect_false("start" %in% names(current_summary))
})

test_that("summary.PKNCAresults manages exclusions as missing not as non-existent.", {
  # Note that generate.conc sets the random seed, so it doesn't have
  # to happen here.
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  myresult <- pk.nca(mydata)
  myresult_excluded <-
    exclude(
      myresult,
      reason = "testing",
      mask = with(
        as.data.frame(myresult),
        PPTESTCD %in% "auclast" & ID %in% 1
      )
    )
  myresult_excluded2 <-
    exclude(
      myresult,
      reason = "testing",
      mask = with(
        as.data.frame(myresult),
        PPTESTCD %in% "auclast"
      )
    )
  # Testing the summarization
  mysummary <- summary(myresult)
  mysummary_excluded <- summary(myresult_excluded)
  mysummary_excluded2 <- summary(myresult_excluded2)
  expect_equal(
    mysummary,
    as_summary_PKNCAresults(
      data.frame(
        start = 0,
        end = c(24, Inf),
        treatment = "Trt 1",
        N = "2",
        auclast = c("13.8 [2.51]", "."),
        cmax = c(".", "0.970 [4.29]"),
        tmax = c(".", "3.00 [2.00, 4.00]"),
        half.life = c(".", "14.2 [2.79]"),
        aucinf.obs = c(".", "20.5 [6.84]")
      ),
      caption = "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects"
    ),
    info = "simple summary of PKNCAresults performs as expected"
  )
  expect_equal(
    mysummary_excluded,
    as_summary_PKNCAresults(
      data.frame(
        start = 0,
        end = c(24, Inf),
        treatment = "Trt 1",
        N = "2",
        auclast = c("14.0, n=1", "."),
        cmax = c(".", "0.970 [4.29]"),
        tmax = c(".", "3.00 [2.00, 4.00]"),
        half.life = c(".", "14.2 [2.79]"),
        aucinf.obs = c(".", "20.5 [6.84]")
      ),
      caption = "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects; n: number of measurements included in summary"
    ),
    info = "summary of PKNCAresults correctly excludes auclast when requested"
  )
  expect_equal(
    mysummary_excluded2,
    as_summary_PKNCAresults(
      data.frame(
        start = 0,
        end = c(24, Inf),
        treatment = "Trt 1",
        N = "2",
        auclast = c("NC", "."),
        cmax = c(".", "0.970 [4.29]"),
        tmax = c(".", "3.00 [2.00, 4.00]"),
        half.life = c(".", "14.2 [2.79]"),
        aucinf.obs = c(".", "20.5 [6.84]")
      ),
      caption = "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects; NC: not calculated"
    ),
    info = "summary of PKNCAresults correctly excludes all of auclast when requested"
  )
})

test_that("print.summary_PKNCAresults works", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  myresult <- pk.nca(mydata)

  expect_output(
    print(summary(myresult)),
    paste(
      " start end treatment N     auclast         cmax              tmax   half.life.*",
      "     0  24     Trt 1 2 13.8 \\[2.51\\]            .                 .           ..*",
      "     0 Inf     Trt 1 2           . 0.970 \\[4.29\\] 3.00 \\[2.00, 4.00\\] 14.2 \\[2.79\\].*",
      "",
      "Caption: auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation",
      sep = "\n"
    )
  )
})

test_that("print.summary_PKNCAresults supports caption_prefix", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  myresult <- pk.nca(mydata)
  
  expect_output(
    print(summary(myresult, caption_prefix = "Summary:")),
    paste(
      " start end treatment N     auclast         cmax              tmax   half.life.*",
      "     0  24     Trt 1 2 13.8 \\[2.51\\]            .                 .           ..*",
      "     0 Inf     Trt 1 2           . 0.970 \\[4.29\\] 3.00 \\[2.00, 4.00\\] 14.2 \\[2.79\\].*",
      "",
      "Caption: Summary: auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation",
      sep = "\n"
    )
  )
})


test_that("the not calculated abbreviation is described in the caption only when it is used", {
  caption_args <-
    list(
      param_names = "cmax",
      pretty_names = FALSE,
      footnote_N = FALSE,
      footnote_n = FALSE,
      not_calculated = "NC",
      caption_prefix = NULL
    )
  expect_equal(
    do.call(get_summary_PKNCAresults_caption, c(caption_args, footnote_not_calculated = FALSE)),
    "cmax: geometric mean and geometric coefficient of variation",
    info = "no value was not calculated, so the abbreviation is omitted"
  )
  expect_equal(
    do.call(get_summary_PKNCAresults_caption, c(caption_args, footnote_not_calculated = TRUE)),
    "cmax: geometric mean and geometric coefficient of variation; NC: not calculated"
  )
  caption_args$not_calculated <- "NoCalc"
  expect_equal(
    do.call(get_summary_PKNCAresults_caption, c(caption_args, footnote_not_calculated = TRUE)),
    "cmax: geometric mean and geometric coefficient of variation; NoCalc: not calculated",
    info = "the user's not_calculated string is what is described"
  )
  caption_args$not_calculated <- "NC"
  caption_args$footnote_N <- TRUE
  caption_args$footnote_n <- TRUE
  expect_equal(
    do.call(get_summary_PKNCAresults_caption, c(caption_args, footnote_not_calculated = TRUE)),
    "cmax: geometric mean and geometric coefficient of variation; N: number of subjects; n: number of measurements included in summary; NC: not calculated",
    info = "the abbreviation comes after the N and n footnotes"
  )
})


test_that("summary pretty_name control", {
  skip_if_not_installed("units")
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  myresult <- pk.nca(mydata)

  d_units_orig <- pknca_units_table(concu = "ng/mL", doseu = "mg", amountu = "mg", timeu = "hr")
  d_units_std <-
    pknca_units_table(
      concu = "ng/mL", doseu = "mg", amountu = "mg", timeu = "hr",
      conversions = data.frame(PPORRESU = "ng/mL", PPSTRESU = "mg/mL")
    )
  mydata_orig <- PKNCAdata(myconc, mydose, units = d_units_orig,
                           intervals = PKNCA.options("single.dose.aucs"))
  myresult_units_orig <- pk.nca(mydata_orig)

  s_plain <- summary(myresult)
  s_pretty <- summary(myresult, pretty_names = TRUE)
  s_plain_units <- summary(myresult_units_orig, pretty_names = FALSE)
  s_pretty_units <- summary(myresult_units_orig)
  expect_equal(
    names(s_plain),
    c("start", "end", "treatment", "N", "auclast", "cmax", "tmax", "half.life", "aucinf.obs")
  )
  expect_equal(
    names(s_pretty),
    c(
      "Interval Start", "Interval End", "treatment", "N", "AUClast",
      "Cmax", "Tmax", "Half-life", "AUCinf,obs"
    )
  )
  expect_equal(
    names(s_plain_units),
    c(
      "start", "end", "treatment", "N", "auclast (hr*ng/mL)", "cmax (ng/mL)",
      "tmax (hr)", "half.life (hr)", "aucinf.obs (hr*ng/mL)"
    )
  )
  expect_equal(
    names(s_pretty_units),
    c(
      "Interval Start", "Interval End", "treatment", "N", "AUClast (hr*ng/mL)",
      "Cmax (ng/mL)", "Tmax (hr)", "Half-life (hr)", "AUCinf,obs (hr*ng/mL)"
    )
  )
  # Captions use the pretty_names, if requested
  expect_equal(
    attr(s_plain, "caption"),
    "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects"
  )
  expect_equal(
    attr(s_pretty, "caption"),
    "AUClast, Cmax, AUCinf,obs: geometric mean and geometric coefficient of variation; Tmax: median and range; Half-life: arithmetic mean and standard deviation; N: number of subjects"
  )
  # Default for pretty_names are kept
  expect_equal(
    names(s_plain),
    names(summary(myresult, pretty_names = FALSE))
  )
  expect_equal(
    names(s_pretty_units),
    names(summary(myresult_units_orig, pretty_names = TRUE))
  )
})

test_that("roundingSummarize", {
  expect_error(
    roundingSummarize(1, "foo"),
    regexp = "foo is not in the summarization instructions from PKNCA.set.summary"
  )

  PKNCA.set.summary(name = "lambda.z.n.points", description = "not a real parameter", point = mean, spread = sd, rounding = function(x) round(x, 1))
  expect_equal(roundingSummarize(1.2345, "lambda.z.n.points"), "1.2")
  PKNCA.set.summary(name = "lambda.z.n.points", description = "not a real parameter", point = mean, spread = sd, rounding = list(round = 1))
  expect_equal(roundingSummarize(1.2345, "lambda.z.n.points"), "1.2")

  # reset it
  PKNCA.set.summary(
    name = "lambda.z.n.points",
    description = "median and range",
    point = business.median,
    spread = business.range
  )
})

test_that("PKNCAresults summary counts N and n", {
  tmpconc <- generate.conc(2, 1, 0:6)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  suppressWarnings(
    myresult <- pk.nca(mydata)
  )
  o_summary <- summary(myresult)
  expect_equal(o_summary$half.life, c(".", "85.0, n=1"))
  expect_equal(
    attr(o_summary, "caption"),
    "auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects; n: number of measurements included in summary"
  )
})

test_that("summary.PKNCAresults drop_param argument works", {
  tmpconc <- generate.conc(2, 1, 0:6)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula = conc ~ time | treatment + ID)
  mydose <- PKNCAdose(tmpdose, formula = dose ~ time | treatment + ID)
  mydata <- PKNCAdata(myconc, mydose, intervals = PKNCA.options("single.dose.aucs"))
  suppressWarnings(
    myresult <- pk.nca(mydata)
  )
  o_summary <- summary(myresult)
  expect_true("auclast" %in% names(o_summary))
  o_summary_noauclast <- summary(myresult, drop_param = "auclast")
  expect_false("auclast" %in% names(o_summary_noauclast))
})

# Sparse results with one sample per animal at each time and two treatments.
# A sparse AUClast is one estimate per treatment, with its standard error on
# the auclast_se row.
sparse_summary_results <- function(intervals = data.frame(start = 0, end = 24, auclast = TRUE, cmax = TRUE),
                                   options = list()) {
  d_conc <- expand.grid(time = c(0, 1, 2, 4, 8, 24), rep = 1:3, treatment = c("A", "B"))
  d_conc$id <- paste(d_conc$treatment, d_conc$time, d_conc$rep)
  d_conc$conc <-
    10 * exp(-0.2 * d_conc$time) * (1 - exp(-2 * d_conc$time)) *
    (1 + c(-0.1, 0, 0.1)[d_conc$rep]) * c(A = 1, B = 0.8)[as.character(d_conc$treatment)]
  d_dose <- data.frame(treatment = c("A", "B"), time = 0, dose = 1)
  # Requesting a deprecated sparse name warns once per session
  o_data <-
    suppressWarnings(PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | treatment + id, sparse = TRUE),
      PKNCAdose(d_dose, dose ~ time | treatment),
      intervals = intervals,
      options = options
    ))
  suppressWarnings(suppressMessages(pk.nca(o_data)))
}

test_that("summary combines a sparse AUClast with its standard error from another row (#170)", {
  res <- sparse_summary_results()
  d_res <- as.data.frame(res)
  auc <- d_res$PPORRES[d_res$PPTESTCD == "auclast"]
  se <- d_res$PPORRES[d_res$PPTESTCD == "auclast_se"]
  o_summary <- summary(res)
  expect_equal(names(o_summary), c("start", "end", "treatment", "auclast", "cmax"))
  expect_equal(
    o_summary$auclast,
    sprintf("%s [%s]", signifString(auc, 3), signifString(se, 3))
  )
  # Dense-style parameters in the same summary keep their own summary
  expect_equal(
    o_summary$cmax,
    signifString(d_res$PPORRES[d_res$PPTESTCD == "cmax"], 3)
  )
  expect_equal(
    attr(o_summary, "caption"),
    "auclast: arithmetic mean and standard error; cmax: geometric mean and geometric coefficient of variation"
  )
})

test_that("a summary row with more than one sparse estimate is an error (#170)", {
  # Dropping the group that separates the estimates
  res <- sparse_summary_results()
  expect_error(
    summary(res, drop_group = c("id", "treatment")),
    regexp = "Cannot summarize 2 results of auclast_se in one summary row",
    class = "pknca_error_summary_multiple_spread"
  )
  # Intervals with the same start and end that nothing in the summary tells apart
  res_dup <-
    sparse_summary_results(
      intervals = data.frame(start = 0, end = 24, auclast = TRUE, impute = c(NA, "start_conc0"))
    )
  expect_error(summary(res_dup), class = "pknca_error_summary_multiple_spread")
  # A kept interval column tells them apart, so each row has one estimate
  res_kept <-
    sparse_summary_results(
      intervals = data.frame(start = 0, end = 24, auclast = TRUE, label = c("a", "b")),
      options = list(keep_interval_cols = "label")
    )
  expect_equal(nrow(summary(res_kept)), 4)
})

test_that("a requested standard error gets no summary column of its own (#170)", {
  res <-
    sparse_summary_results(
      intervals = data.frame(start = 0, end = 24, auclast = TRUE, auclast_se = TRUE)
    )
  o_summary <- summary(res)
  expect_equal(names(o_summary), c("start", "end", "treatment", "auclast"))
})

test_that("an excluded sparse standard error is not calculated in the summary (#170)", {
  res <- sparse_summary_results()
  res_excl <- exclude(res, reason = "SE excluded", mask = res$result$PPTESTCD == "auclast_se")
  d_res <- as.data.frame(res)
  auc <- d_res$PPORRES[d_res$PPTESTCD == "auclast"]
  o_summary <- summary(res_excl)
  expect_equal(o_summary$auclast, paste(signifString(auc, 3), "[NC]"))
  expect_match(attr(o_summary, "caption"), "NC: not calculated", fixed = TRUE)
})

test_that("the caption describes each summary a parameter used (#170)", {
  expect_equal(
    get_summary_PKNCAresults_caption(
      param_names = c("auclast", "cmax"),
      pretty_names = FALSE,
      footnote_N = FALSE,
      footnote_n = FALSE,
      footnote_not_calculated = FALSE,
      not_calculated = "NC",
      caption_prefix = NULL,
      descriptions_used =
        list(
          auclast =
            c(
              "geometric mean and geometric coefficient of variation",
              "arithmetic mean and standard error"
            )
        )
    ),
    "auclast, cmax: geometric mean and geometric coefficient of variation; auclast: arithmetic mean and standard error"
  )
})

test_that("PKNCA.set.summary checks spread_for (#170)", {
  expect_error(
    PKNCA.set.summary(
      name = "auclast_se", description = "x", point = business.mean,
      spread = business.mean, spread_for = "not_a_parameter"
    ),
    class = "pknca_error_undefined_parameter"
  )
  expect_error(
    PKNCA.set.summary(
      name = "auclast_se", description = "x", point = business.mean,
      spread_for = "auclast"
    ),
    class = "pknca_error_spread_for_needs_spread"
  )
  expect_error(
    PKNCA.set.summary(
      name = "auclast_se", description = "x", point = business.mean,
      spread = business.mean, spread_for = c("auclast", "aumclast")
    ),
    regexp = "Must have length 1"
  )
  # The failed calls left the registered instructions in place
  expect_equal(PKNCA.set.summary()$auclast_se$spread_for, "auclast")
  expect_equal(PKNCA.set.summary()$auclast_se$description, "arithmetic mean and standard error")
})

test_that("the deprecated sparse_auclast is summarized with sparse_auc_se (#170)", {
  res <- sparse_summary_results(intervals = data.frame(start = 0, end = 24, sparse_auclast = TRUE))
  d_res <- as.data.frame(res)
  auc <- d_res$PPORRES[d_res$PPTESTCD == "sparse_auclast"]
  se <- d_res$PPORRES[d_res$PPTESTCD == "sparse_auc_se"]
  o_summary <- summary(res)
  expect_equal(names(o_summary), c("start", "end", "treatment", "sparse_auclast"))
  expect_equal(
    o_summary$sparse_auclast,
    sprintf("%s [%s]", signifString(auc, 3), signifString(se, 3))
  )
  expect_equal(attr(o_summary, "caption"), "sparse_auclast: arithmetic mean and standard error")
})
