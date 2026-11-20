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

# The bases of the ratio rule, in the order of get.interval.cols()
ratio_bases_expected <-
  c(
    "auclast", "aucall", "aucint.last", "aucint.all", "aucivint.last", "aucivint.all", "c0", "cmax",
    "cmin", "clast.obs", "cav.last", "cav.int.last", "cav.int.all", "cav.all", "cav.ivint.last",
    "cav.ivint.all", "ctrough", "cstart", "ceoi", "aucabove.predose.all", "aucabove.trough.all", "ae",
    "aucivlast", "aucivall", "cav.iv.last", "cav.iv.all", "aucinf.obs", "aucinf.pred",
    "aucint.inf.obs", "aucint.inf.pred", "aucivint.inf.obs", "aucivint.inf.pred", "aucivinf.obs",
    "aucivinf.pred", "cav.int.inf.obs", "cav.int.inf.pred", "cav.ivint.inf.obs", "cav.ivint.inf.pred"
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

test_that("pknca_parameter_rules() lists the ratio rule and exactly its 38 bases", {
  rules <- pknca_parameter_rules()
  expect_equal(rules$prefix, "ratio")
  expect_equal(strsplit(rules$bases, split = ", ", fixed = TRUE)[[1]], ratio_bases_expected)
})

test_that("every ratio is registered when PKNCA is loaded, after the parameters and before the earlier names", {
  all_intervals <- get.interval.cols()
  all_names <- names(all_intervals)
  members <- paste0("ratio.", ratio_bases_expected)
  expect_true(all(members %in% all_names))
  expect_equal(sum(startsWith(all_names, "ratio.")), 38L)
  # The 32 that were not registered one by one come right before the earlier
  # names, in the order of their bases; the six keep their places among the
  # parameters
  is_alias <- vapply(X = all_intervals, FUN = function(x) !is.null(x$historical_of), FUN.VALUE = TRUE)
  first_alias <- which(is_alias)[1]
  expect_true(all(is_alias[first_alias:length(all_names)]))
  new_members <- setdiff(members, paste0("ratio.", ratio_six_expected$base))
  expect_equal(all_names[(first_alias - 32):(first_alias - 1)], new_members)
  for (member in members) {
    spec <- all_intervals[[member]]
    base <- sub("^ratio[.]", "", member)
    expect_equal(spec$FUN, "pk.calc.ratio", info = member)
    expect_equal(spec$depends, base, info = member)
    expect_equal(spec$unit_type, "fraction", info = member)
    expect_equal(spec$formalsmap, list(test = base, reference = pknca_ref(base)), info = member)
    expect_equal(spec$tier, "uncommon", info = member)
    # The member's own concept, and the route, dosing, and sample type its base
    # declares
    base_selection <- all_intervals[[base]]$selection
    base_selection$concept <- NULL
    expect_equal(spec$selection, c(list(concept = "parameter_ratio"), base_selection), info = member)
    # SDTM limits PPTEST to 40 characters
    expect_lte(nchar(spec$desc), 40)
  }
  spec_cmin <- all_intervals[["ratio.cmin"]]
  expect_equal(spec_cmin$pretty_name, "Ratio of Cmin to reference")
  expect_equal(spec_cmin$pptestcd_cdisc, "ratio.cmin")
  expect_equal(
    PKNCA.set.summary()[["ratio.cmin"]]$description,
    "geometric mean and geometric coefficient of variation"
  )
})

test_that("no generated interval requests a ratio", {
  members <- paste0("ratio.", ratio_bases_expected)
  for (dosing in c("single", "multiple", "steady_state")) {
    interval_table <- pknca_interval_table(start = 0, end = 24, dosing = dosing, route = "extravascular")
    expect_true(all(members %in% names(interval_table)), info = dosing)
    expect_false(any(unlist(interval_table[members])), info = dosing)
  }
  d_dose <- data.frame(subject = 1, time = 0, dose = 1)
  o_data <-
    suppressWarnings(PKNCAdata(
      PKNCAconc(d_conc_rule[d_conc_rule$period == "test", ], conc ~ time | subject),
      PKNCAdose(d_dose, dose ~ time | subject)
    ))
  expect_false(any(unlist(o_data$intervals[members])))
})

test_that("a ratio of a base other than the six calculates", {
  intervals <- intervals_rule
  intervals$cmin <- TRUE
  intervals$ratio.cmin <- c(FALSE, TRUE)
  intervals$ratio.cmin_ref <- c(NA, "ref")
  o_data <- PKNCAdata(PKNCAconc(d_conc_rule, conc~time|period+subject), intervals = intervals)
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

test_that("a name the rule does not make says why", {
  o_conc <- PKNCAconc(d_conc_rule, conc~time|period+subject)
  refused <-
    c(
      ratio.aumclast = "'aumclast' is an AUMC",
      ratio.cmax.dn = "'cmax.dn' is dose-normalized",
      ratio.ratio.cmax = "'ratio.cmax' is calculated with a value from a reference interval",
      ratio.cav = "'cav' is an earlier name of 'cav.last', and a ratio is made only of the current name \\('ratio.cav.last'\\)",
      ratio.auclast_se = "'auclast_se' is not calculated by a function of its own",
      ratio.tmax = "'tmax' is not a concentration, an AUC, or an amount \\(its unit type is 'time'\\)"
    )
  for (current_name in names(refused)) {
    intervals <- intervals_rule
    intervals[[current_name]] <- c(FALSE, TRUE)
    expect_error(
      PKNCAdata(o_conc, intervals = intervals),
      class = "pknca_error_parameter_rule_ineligible",
      regexp = paste0("'", current_name, "' is not a parameter:  ", refused[[current_name]]),
      info = current_name
    )
    # Still the error for a column that is not allowed
    expect_error(
      PKNCAdata(o_conc, intervals = intervals),
      class = "pknca_error_invalid_interval_columns",
      info = current_name
    )
    expect_error(
      interval_add_param(data.frame(start = 0, end = 24), param = current_name),
      class = "pknca_error_parameter_rule_ineligible",
      regexp = refused[[current_name]],
      info = current_name
    )
    expect_false(current_name %in% names(get.interval.cols()), info = current_name)
  }
  # A name that is not of the form ratio.<parameter> gets the plain error
  intervals <- intervals_rule
  intervals$ratio.notaparameter <- c(FALSE, TRUE)
  err <- expect_error(PKNCAdata(o_conc, intervals = intervals), class = "pknca_error_invalid_interval_columns")
  expect_false(inherits(err, "pknca_error_parameter_rule_ineligible"))
})

test_that("a parameter registered after PKNCA is loaded gets no ratio", {
  local_interval_cols()
  add.interval.col(
    "conc_mean_rule", FUN = "mean", values = c(FALSE, TRUE), unit_type = "conc",
    pretty_name = "Mean concentration", desc = "Mean concentration", formalsmap = list(x = "conc")
  )
  expect_false("ratio.conc_mean_rule" %in% names(get.interval.cols()))
  expect_false("conc_mean_rule" %in% strsplit(pknca_parameter_rules()$bases, split = ", ", fixed = TRUE)[[1]])
  intervals <- intervals_rule
  intervals$ratio.conc_mean_rule <- c(FALSE, TRUE)
  expect_error(
    PKNCAdata(PKNCAconc(d_conc_rule, conc~time|period+subject), intervals = intervals),
    class = "pknca_error_parameter_rule_ineligible",
    regexp = "'conc_mean_rule' was registered after PKNCA was loaded"
  )
})

test_that("the registry, the interval table, and the units table do not depend on the ratios requested before", {
  registry_names <- function() names(get.interval.cols())
  table_names <- function() names(pknca_interval_table(start = 0, end = 24))
  o_units <-
    PKNCAdata(
      PKNCAconc(d_conc_rule, conc~time|period+subject, concu = "ng/mL", timeu = "hr"),
      intervals = data.frame(start = 0, end = 8, cmax = TRUE)
    )
  before <- list(registry = registry_names(), table = table_names(), units = pknca_units_table(o_units))
  expect_true(all(c("ratio.cmin", "ratio.ctrough", "ratio.cstart") %in% o_units$units$PPTESTCD))
  # Ratios requested through the data object, pk.nca(), and the interval helpers
  intervals <- intervals_rule
  intervals$cmin <- TRUE
  intervals$ratio.cmin <- c(FALSE, TRUE)
  intervals$ratio.cmin_ref <- c(NA, "ref")
  pk.nca(PKNCAdata(PKNCAconc(d_conc_rule, conc~time|period+subject), intervals = intervals))
  interval_add_param(data.frame(start = 0, end = 24, ctrough = TRUE), param = "ratio.ctrough")
  pknca_interval_table(start = 0, end = 24, include = "ratio.cstart")
  after <- list(registry = registry_names(), table = table_names(), units = pknca_units_table(o_units))
  expect_identical(after, before)
})

test_that("set_intervals() adds units rows for a parameter registered after the data object was built", {
  local_interval_cols()
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc_rule, conc~time|period+subject, concu = "ng/mL", timeu = "hr"),
      intervals = data.frame(start = 0, end = 8, cmax = TRUE)
    )
  add.interval.col(
    "conc_mean_units", FUN = "mean", values = c(FALSE, TRUE), unit_type = "conc",
    pretty_name = "Mean concentration", desc = "Mean concentration", formalsmap = list(x = "conc")
  )
  expect_false("conc_mean_units" %in% o_data$units$PPTESTCD)
  o_data_set <- set_intervals(o_data, data.frame(start = 0, end = 8, conc_mean_units = TRUE))
  expect_equal(
    o_data_set$units[o_data_set$units$PPTESTCD %in% "conc_mean_units", "PPORRESU"],
    "ng/mL"
  )
  # The other rows are unchanged
  expect_equal(o_data_set$units[seq_len(nrow(o_data$units)), ], o_data$units, ignore_attr = "row.names")
  d_res <- as.data.frame(pk.nca(o_data_set))
  expect_equal(d_res$PPORRESU[d_res$PPTESTCD == "conc_mean_units"], c("ng/mL", "ng/mL"))

  # A units table given to PKNCAdata() is kept as given
  units_given <- o_data$units[o_data$units$PPTESTCD %in% "cmax", ]
  o_data_given <-
    PKNCAdata(
      PKNCAconc(d_conc_rule, conc~time|period+subject, concu = "ng/mL", timeu = "hr"),
      intervals = data.frame(start = 0, end = 8, cmax = TRUE),
      units = units_given
    )
  o_data_given_set <- set_intervals(o_data_given, data.frame(start = 0, end = 8, conc_mean_units = TRUE))
  expect_identical(o_data_given_set$units, o_data_given$units)
  expect_equal(o_data_given_set$units$PPTESTCD, "cmax")

  # So is a built table that was edited:  the deleted row is not put back, and
  # the requested parameter without a row is the usual units error
  units_edited <- o_data$units[o_data$units$PPTESTCD != "cmin", ]
  o_data_edited <- o_data
  o_data_edited$units <- units_edited
  intervals_cmin <- data.frame(start = 0, end = 8, cmin = TRUE)
  o_data_edited_set <- set_intervals(o_data_edited, intervals_cmin)
  expect_identical(o_data_edited_set$units, units_edited)
  expect_error(pk.nca(o_data_edited_set), class = "pknca_error_units_partial_missing")
  # The unedited table needs no rows for cmin, and is left alone
  expect_identical(set_intervals(o_data, intervals_cmin)$units, o_data$units)
})

test_that("a ratio with no row in a units table given to PKNCAdata() is an error, or NA units when allowed", {
  intervals <- intervals_rule
  intervals$cmin <- TRUE
  intervals$ratio.cmin <- c(FALSE, TRUE)
  intervals$ratio.cmin_ref <- c(NA, "ref")
  o_conc <- PKNCAconc(d_conc_rule, conc~time|period+subject, concu = "ng/mL", timeu = "hr")
  units_built <- PKNCAdata(o_conc, intervals = intervals)$units
  units_given <- units_built[units_built$PPTESTCD != "ratio.cmin", ]
  o_data <- PKNCAdata(o_conc, intervals = intervals, units = units_given)
  # The table is kept as given, without the row
  expect_false("ratio.cmin" %in% o_data$units$PPTESTCD)
  expect_error(
    pk.nca(o_data),
    class = "pknca_error_units_partial_missing",
    regexp = "missing for: ratio.cmin"
  )
  o_data_allowed <- PKNCAdata(o_conc, intervals = intervals, units = units_given, options = list(allow_partial_missing_units = TRUE))
  expect_warning(
    d_res <- as.data.frame(pk.nca(o_data_allowed)),
    class = "pknca_warning_units_partial_missing"
  )
  expect_true(is.na(d_res$PPORRESU[d_res$PPTESTCD == "ratio.cmin"]))
  # cmin is 0 in the reference interval, so the ratio is NA too
  expect_true(is.na(d_res$PPORRES[d_res$PPTESTCD == "ratio.cmin"]))
  expect_equal(unique(d_res$PPORRESU[d_res$PPTESTCD == "cmin"]), "ng/mL")
})

test_that("interval_add_param(), interval_add_secondary(), and pknca_interval_table() use a ratio they are given", {
  ret <- interval_add_param(data.frame(start = 0, end = 24, cmin = TRUE), param = "ratio.cmin")
  expect_true(ret$ratio.cmin)

  ret_secondary <-
    interval_add_secondary(
      data.frame(period = c("reference", "test"), start = 0, end = 24, ctrough = TRUE),
      param = "ratio.ctrough", reference = data.frame(period = "reference")
    )
  expect_equal(ret_secondary$ratio.ctrough_ref, c(NA, ret_secondary$interval_id[1]))

  ret_table <- pknca_interval_table(start = 0, end = 24, dosing = "multiple", route = "extravascular", include = "ratio.cstart")
  expect_true(ret_table$ratio.cstart)
})

test_that("param_pattern selects what it selected before the new ratios were registered", {
  all_params <- setdiff(names(get.interval.cols()), c("start", "end"))
  new_members <- names(PKNCA:::parameter_rule_members_new())
  expect_equal(length(new_members), 32)
  before <- setdiff(all_params, new_members)
  for (base in strsplit(pknca_parameter_rules()$bases, split = ", ", fixed = TRUE)[[1]]) {
    for (pattern in c(base, paste0("^", gsub(".", "[.]", base, fixed = TRUE), "$"))) {
      expect_equal(
        PKNCA:::parameter_pattern_match(pattern, all_params),
        grep(pattern, x = before, value = TRUE),
        info = pattern
      )
    }
  }
  # A pattern aimed at the ratios selects them, including the new ones
  expect_setequal(
    PKNCA:::parameter_pattern_match("^ratio[.]", all_params),
    grep("^ratio[.]", x = all_params, value = TRUE)
  )
  expect_length(PKNCA:::parameter_pattern_match("^ratio[.]", all_params), 38)
  # Through interval_add_param(), as the review found
  for (pattern in c("ctrough", "clast.obs", "cmin")) {
    ret <- interval_add_param(data.frame(start = 0, end = 24, tmax = TRUE), param_pattern = pattern)
    requested <- setdiff(names(ret)[vapply(ret, isTRUE, TRUE)], "tmax")
    expect_equal(sort(requested), sort(grep(pattern, x = before, value = TRUE)), info = pattern)
    expect_false(any(startsWith(requested, "ratio.")), info = pattern)
  }
})

test_that("a ratio has its base's route, sample type, dosing, and sparse classification", {
  tbl <- pknca_parameter_table()
  rownames(tbl) <- tbl$parameter
  for (base in strsplit(pknca_parameter_rules()$bases, split = ", ", fixed = TRUE)[[1]]) {
    member <- paste0("ratio.", base)
    for (field in c("route", "sample_type", "dosing", "sparse")) {
      expect_identical(tbl[member, field], tbl[base, field], info = paste(member, field))
    }
  }
  expect_equal(tbl["ratio.ceoi", "route"], "iv_infusion")
})
