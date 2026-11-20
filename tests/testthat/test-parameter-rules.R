# The six ratios that were registered one by one before ratios were made by
# rule:  every field that is not the same for all ratios
ratio_six_expected <-
  rbind(
    data.frame(base = "cmax", label = "Cmax", pptestcd = "RCMAX"),
    data.frame(base = "auclast", label = "AUClast", pptestcd = "RAUCLST"),
    data.frame(base = "aucinf.obs", label = "AUCinf,obs", pptestcd = "RAUCIFO"),
    data.frame(base = "aucinf.pred", label = "AUCinf,pred", pptestcd = "RAUCIFP"),
    data.frame(base = "aucint.last", label = "AUCint,last", pptestcd = "RAUCINL"),
    data.frame(base = "aucint.all", label = "AUCint,all", pptestcd = "RAUCINA")
  )

d_conc_rule <-
  data.frame(
    subject = 1,
    period = rep(c("test", "reference"), each = 5),
    time = rep(c(0, 1, 2, 4, 8), times = 2),
    conc = c(0, 6, 8, 4, 2, 0, 3, 4, 2, 1)
  )
intervals_rule <-
  data.frame(
    period = c("reference", "test"),
    start = 0, end = 8,
    interval_id = c("ref", NA)
  )

test_that("the six earlier ratios are made by the rule with their fields unchanged", {
  all_intervals <- get.interval.cols()
  for (i in seq_len(nrow(ratio_six_expected))) {
    base <- ratio_six_expected$base[i]
    label <- ratio_six_expected$label[i]
    spec <- all_intervals[[paste0("ratio.", base)]]
    expect_equal(spec$FUN, "pk.calc.ratio", info = base)
    expect_equal(spec$FUN_sparse, NA_character_, info = base)
    expect_equal(spec$values, c(FALSE, TRUE), info = base)
    expect_equal(spec$unit_type, "fraction", info = base)
    expect_equal(spec$pretty_name, sprintf("Ratio of %s to reference", label), info = base)
    expect_equal(spec$desc, sprintf("Ratio of %s to reference", label), info = base)
    expect_equal(spec$formalsmap, list(test = base, reference = pknca_ref(base)), info = base)
    expect_equal(spec$formalsmap_sparse, list(), info = base)
    expect_equal(spec$depends, base, info = base)
    expect_equal(spec$datatype, "interval", info = base)
    expect_equal(spec$pptestcd_cdisc, ratio_six_expected$pptestcd[i], info = base)
    expect_equal(spec$pptest_cdisc, sprintf("Ratio of %s to Reference", label), info = base)
    expect_null(spec$formula, info = base)
    expect_null(spec$formula_note, info = base)
    expect_equal(spec$tier, "uncommon", info = base)
    expect_equal(spec$selection, list(concept = "parameter_ratio"), info = base)
    expect_equal(
      PKNCA.set.summary()[[paste0("ratio.", base)]]$description,
      "geometric mean and geometric coefficient of variation",
      info = base
    )
  }
})

test_that("a ratio of any eligible base is made when it is first requested", {
  local_interval_cols()
  expect_false("ratio.cmin" %in% names(get.interval.cols()))
  intervals <- intervals_rule
  intervals$cmin <- TRUE
  intervals$ratio.cmin <- c(FALSE, TRUE)
  intervals$ratio.cmin_ref <- c(NA, "ref")
  o_data <- PKNCAdata(PKNCAconc(d_conc_rule, conc~time|period+subject), intervals = intervals)
  spec <- get.interval.cols()[["ratio.cmin"]]
  expect_equal(spec$FUN, "pk.calc.ratio")
  expect_equal(spec$unit_type, "fraction")
  expect_equal(spec$pretty_name, "Ratio of Cmin to reference")
  expect_equal(spec$pptestcd_cdisc, "ratio.cmin")
  expect_equal(spec$depends, "cmin")
  expect_equal(spec$formalsmap, list(test = "cmin", reference = pknca_ref("cmin")))
  expect_equal(spec$selection, list(concept = "parameter_ratio"))
  expect_equal(
    PKNCA.set.summary()[["ratio.cmin"]]$description,
    "geometric mean and geometric coefficient of variation"
  )
  # cmin is 0 in the reference interval, and a ratio to zero is NA
  d_res <- as.data.frame(pk.nca(o_data))
  expect_true(is.na(d_res$PPORRES[d_res$PPTESTCD %in% "ratio.cmin"]))

  intervals_clast <- intervals_rule
  intervals_clast$clast.obs <- TRUE
  intervals_clast$ratio.clast.obs <- c(FALSE, TRUE)
  intervals_clast$ratio.clast.obs_ref <- c(NA, "ref")
  d_res_clast <-
    as.data.frame(pk.nca(PKNCAdata(PKNCAconc(d_conc_rule, conc~time|period+subject), intervals = intervals_clast)))
  # clast.obs is 2 (test) and 1 (reference)
  expect_equal(d_res_clast$PPORRES[d_res_clast$PPTESTCD %in% "ratio.clast.obs"], 2)
})

test_that("a name the rule cannot make is refused as an unknown column", {
  local_interval_cols()
  o_conc <- PKNCAconc(d_conc_rule, conc~time|period+subject)
  for (current_name in c("ratio.aumclast", "ratio.cmax.dn", "ratio.ratio.cmax", "ratio.cav", "ratio.auclast_se", "ratio.notaparameter")) {
    intervals <- intervals_rule
    intervals[[current_name]] <- c(FALSE, TRUE)
    expect_error(PKNCAdata(o_conc, intervals = intervals), info = current_name)
    expect_false(current_name %in% names(get.interval.cols()), info = current_name)
  }
})

test_that("pknca_parameter_rules() lists the ratio rule and its bases", {
  rules <- pknca_parameter_rules()
  expect_equal(rules$prefix, "ratio")
  bases <- strsplit(rules$bases, split = ", ", fixed = TRUE)[[1]]
  expect_true(all(c("cmax", "cmin", "auclast", "aucinf.obs", "aucint.last", "clast.obs", "ae") %in% bases))
  expect_false(any(c("aumclast", "cmax.dn", "ratio.cmax", "cav", "auclast_se", "tmax", "cl.last") %in% bases))
})

test_that("every base the ratio rule lists makes a member that depends on it", {
  local_interval_cols()
  bases <- strsplit(pknca_parameter_rules()$bases, split = ", ", fixed = TRUE)[[1]]
  expect_gt(length(bases), 6)
  for (base in bases) {
    member <- paste0("ratio.", base)
    PKNCA:::resolve_parameter_name(member)
    spec <- get.interval.cols()[[member]]
    expect_equal(spec$depends, base, info = member)
    expect_equal(spec$unit_type, "fraction", info = member)
    expect_equal(spec$formalsmap$reference, pknca_ref(base), info = member)
    # SDTM limits PPTEST to 40 characters
    expect_lte(nchar(spec$desc), 40)
  }
  # Members are not bases:  the rule does not make ratios of ratios
  expect_equal(strsplit(pknca_parameter_rules()$bases, split = ", ", fixed = TRUE)[[1]], bases)
})

test_that("a results object read in a session without its rule-made parameters registers them", {
  local_interval_cols()
  intervals <- intervals_rule
  intervals$clast.obs <- TRUE
  intervals$ratio.clast.obs <- c(FALSE, TRUE)
  intervals$ratio.clast.obs_ref <- c(NA, "ref")
  o_nca <- pk.nca(PKNCAdata(PKNCAconc(d_conc_rule, conc~time|period+subject), intervals = intervals))
  # Unregister the member, as in a new session
  current <- get("interval.cols", envir = PKNCA:::.PKNCAEnv)
  current[["ratio.clast.obs"]] <- NULL
  assign("interval.cols", current, envir = PKNCA:::.PKNCAEnv)
  rm("interval.cols_sorted", envir = PKNCA:::.PKNCAEnv)
  expect_false("ratio.clast.obs" %in% names(get.interval.cols()))
  d_res <- as.data.frame(o_nca)
  expect_true("ratio.clast.obs" %in% names(get.interval.cols()))
  expect_equal(d_res$PPORRES[d_res$PPTESTCD %in% "ratio.clast.obs"], 2)
  expect_s3_class(summary(o_nca), "summary_PKNCAresults")
})

test_that("interval_add_param(), interval_add_secondary(), and pknca_interval_table() make a ratio they are given", {
  local_interval_cols()
  expect_false("ratio.cmin" %in% names(get.interval.cols()))
  ret <- interval_add_param(data.frame(start = 0, end = 24, cmin = TRUE), param = "ratio.cmin")
  expect_true(ret$ratio.cmin)
  expect_true("ratio.cmin" %in% names(get.interval.cols()))

  expect_false("ratio.ctrough" %in% names(get.interval.cols()))
  ret_secondary <-
    interval_add_secondary(
      data.frame(period = c("reference", "test"), start = 0, end = 24, ctrough = TRUE),
      param = "ratio.ctrough", reference = data.frame(period = "reference")
    )
  expect_equal(ret_secondary$ratio.ctrough_ref, c(NA, ret_secondary$interval_id[1]))
  expect_true("ratio.ctrough" %in% names(get.interval.cols()))

  expect_false("ratio.cstart" %in% names(get.interval.cols()))
  ret_table <- pknca_interval_table(start = 0, end = 24, dosing = "multiple", route = "extravascular", include = "ratio.cstart")
  expect_true("ratio.cstart" %in% names(get.interval.cols()))
  expect_true("ratio.cstart" %in% names(ret_table))
})
