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

test_that("pknca_parameter_rules() lists the ratio and metabolite ratio rules and exactly their 38 bases", {
  rules <- pknca_parameter_rules()
  expect_equal(rules$prefix, c("ratio", "mr"))
  expect_equal(strsplit(rules$bases[1], split = ", ", fixed = TRUE)[[1]], ratio_bases_expected)
  expect_equal(strsplit(rules$bases[2], split = ", ", fixed = TRUE)[[1]], ratio_bases_expected)
})

test_that("every ratio is registered when PKNCA is loaded, after the parameters and before the earlier names", {
  all_intervals <- get.interval.cols()
  all_names <- names(all_intervals)
  members <- paste0("ratio.", ratio_bases_expected)
  expect_true(all(members %in% all_names))
  expect_equal(sum(startsWith(all_names, "ratio.")), 38L)
  # The 32 that were not registered one by one come after the parameters, then
  # the 38 metabolite ratios, then the earlier names, each in the order of their
  # bases; the six keep their places among the parameters
  is_alias <- vapply(X = all_intervals, FUN = function(x) !is.null(x$historical_of), FUN.VALUE = TRUE)
  first_alias <- which(is_alias)[1]
  expect_true(all(is_alias[first_alias:length(all_names)]))
  new_members <- setdiff(members, paste0("ratio.", ratio_six_expected$base))
  expect_equal(
    all_names[(first_alias - 70):(first_alias - 1)],
    c(new_members, paste0("mr.", ratio_bases_expected))
  )
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
  members <- c(paste0("ratio.", ratio_bases_expected), paste0("mr.", ratio_bases_expected))
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

# mr.<base> ####

d_conc_mr <-
  data.frame(
    subject = rep(1:2, each = 10),
    analyte = rep(rep(c("parent", "metab"), each = 5), 2),
    time = rep(c(0, 1, 2, 4, 8), 4),
    conc = c(0, 10, 8, 4, 2, 0, 2, 3, 2, 1, 0, 12, 9, 5, 2, 0, 3, 4, 2, 1)
  )
intervals_mr <-
  data.frame(
    analyte = c("parent", "metab"), start = 0, end = 8,
    auclast = TRUE, cmax = TRUE, mr.auclast = c(FALSE, TRUE), mr.cmax = c(FALSE, TRUE)
  )

test_that("every metabolite ratio is registered, with its own concept and names", {
  all_intervals <- get.interval.cols()
  for (base in ratio_bases_expected) {
    member <- paste0("mr.", base)
    spec <- all_intervals[[member]]
    expect_equal(spec$FUN, "pk.calc.ratio", info = member)
    expect_equal(spec$depends, base, info = member)
    expect_equal(spec$unit_type, "fraction", info = member)
    expect_equal(spec$formalsmap, list(test = base, reference = pknca_ref(base)), info = member)
    expect_equal(spec$tier, "uncommon", info = member)
    base_selection <- all_intervals[[base]]$selection
    base_selection$concept <- NULL
    expect_equal(spec$selection, c(list(concept = "metabolite_ratio"), base_selection), info = member)
    expect_equal(spec$pptestcd_cdisc, member, info = member)
    expect_equal(spec$pptest_cdisc, spec$desc, info = member)
    expect_equal(
      spec$pretty_name,
      sprintf("Metabolite to parent ratio of %s", all_intervals[[base]]$pretty_name),
      info = member
    )
    # SDTM limits PPTEST to 40 characters
    expect_lte(nchar(spec$desc), 40)
    expect_equal(
      PKNCA.set.summary()[[member]]$description,
      "geometric mean and geometric coefficient of variation",
      info = member
    )
  }
  expect_equal(all_intervals[["mr.auclast"]]$desc, "Metabolite to parent ratio of AUClast")
  expect_equal(all_intervals[["mr.aucabove.predose.all"]]$desc, "Met/parent ratio of aucabove.predose.all")
  expect_true("metabolite_ratio" %in% pknca_concepts())
})

test_that("a metabolite ratio uses the parent named by group_ref", {
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc_mr, conc ~ time | subject / analyte, concu = "ng/mL", timeu = "hr"),
      intervals = intervals_mr,
      group_ref = data.frame(analyte = "parent")
    )
  expect_message(
    d_res <- as.data.frame(pk.nca(o_data)),
    class = "pknca_message_secondary_ref_created"
  )
  d_mr <- d_res[startsWith(d_res$PPTESTCD, "mr."), ]
  d_parent <- d_res[d_res$analyte == "parent", ]
  d_metab <- d_res[d_res$analyte == "metab", ]
  for (current_subject in 1:2) {
    for (base in c("auclast", "cmax")) {
      expect_equal(
        d_mr$PPORRES[d_mr$subject == current_subject & d_mr$PPTESTCD == paste0("mr.", base)],
        d_metab$PPORRES[d_metab$subject == current_subject & d_metab$PPTESTCD == base] /
          d_parent$PPORRES[d_parent$subject == current_subject & d_parent$PPTESTCD == base],
        info = paste(current_subject, base)
      )
    }
  }
  expect_equal(d_mr$PPORRES[d_mr$PPTESTCD == "mr.cmax"], c(3 / 10, 4 / 12))
  expect_equal(unique(d_mr$analyte), "metab")
  expect_equal(unique(d_mr$analyte_ref), "parent")
  # Both analytes are in ng/mL, so the ratio is one of masses
  expect_equal(unique(d_mr$PPORRESU), "g/g")
})

test_that("a metabolite ratio with no parent named is pknca_error_mr_needs_parent", {
  o_conc <- PKNCAconc(d_conc_mr, conc ~ time | subject / analyte)
  expect_error(
    pk.nca(PKNCAdata(o_conc, intervals = intervals_mr)),
    class = "pknca_error_mr_needs_parent",
    regexp = "The metabolite ratio 'mr.auclast' needs its parent analyte as the reference"
  )
  # The class is also the general one for a secondary parameter without a
  # reference
  expect_error(
    pk.nca(PKNCAdata(o_conc, intervals = intervals_mr)),
    class = "pknca_error_secondary_needs_ref"
  )
  # A group_ref for other parameters only does not name the parent
  expect_error(
    pk.nca(PKNCAdata(
      o_conc, intervals = intervals_mr,
      group_ref = data.frame(parameter = "ratio.auclast", analyte = "parent")
    )),
    class = "pknca_error_mr_needs_parent"
  )
  # interval_add_secondary() with no reference and nothing to derive one from
  expect_error(
    interval_add_secondary(intervals_mr, param = "mr.auclast"),
    class = "pknca_error_mr_needs_parent"
  )
})

test_that("a metabolite ratio may name the parent's interval with its _ref column", {
  intervals <- intervals_mr
  intervals$interval_id <- c("parent", NA)
  intervals$mr.auclast_ref <- c(NA, "parent")
  intervals$mr.cmax <- FALSE
  d_res <-
    as.data.frame(pk.nca(PKNCAdata(PKNCAconc(d_conc_mr, conc ~ time | subject / analyte), intervals = intervals)))
  expect_equal(
    d_res$PPORRES[d_res$PPTESTCD == "mr.auclast"],
    d_res$PPORRES[d_res$PPTESTCD == "auclast" & d_res$analyte == "metab"] /
      d_res$PPORRES[d_res$PPTESTCD == "auclast" & d_res$analyte == "parent"]
  )
})

test_that("a name the metabolite ratio rule does not make says why", {
  intervals <- intervals_mr
  intervals$mr.aumclast <- c(FALSE, TRUE)
  expect_error(
    PKNCAdata(PKNCAconc(d_conc_mr, conc ~ time | subject / analyte), intervals = intervals),
    class = "pknca_error_parameter_rule_ineligible",
    regexp = "'mr.aumclast' is not a parameter:  'aumclast' is an AUMC"
  )
  intervals_cav <- intervals_mr
  intervals_cav$mr.cav <- c(FALSE, TRUE)
  expect_error(
    PKNCAdata(PKNCAconc(d_conc_mr, conc ~ time | subject / analyte), intervals = intervals_cav),
    class = "pknca_error_parameter_rule_ineligible",
    regexp = "the current name \\('mr.cav.last'\\)"
  )
})

test_that("an intervals row covering every analyte gives the metabolite its ratio and the parent NA", {
  # The row is judged group by group:  the metabolite's reference is the
  # parent within the same row, and the parent is the reference itself
  intervals_all <- data.frame(start = 0, end = 8, auclast = TRUE, cmax = TRUE, mr.cmax = TRUE)
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc_mr, conc ~ time | subject / analyte),
      intervals = intervals_all,
      group_ref = data.frame(analyte = "parent")
    )
  expect_no_warning(
    expect_message(
      d_res <- as.data.frame(pk.nca(o_data)),
      regexp = "Secondary parameter 'mr.cmax': using (analyte=parent, 0-8) as the reference interval 'autoref1'.",
      fixed = TRUE,
      class = "pknca_message_secondary_ref_created"
    )
  )
  # Nothing is calculated that the row did not request
  expect_setequal(unique(d_res$PPTESTCD), c("auclast", "cmax", "mr.cmax"))
  d_mr <- d_res[d_res$PPTESTCD == "mr.cmax", ]
  d_mr <- d_mr[order(d_mr$subject, d_mr$analyte), ]
  expect_equal(d_mr$analyte, c("metab", "parent", "metab", "parent"))
  # cmax:  subject 1, parent 10 and metabolite 3; subject 2, 12 and 4
  expect_equal(d_mr$PPORRES, c(3/10, NA, 4/12, NA))
  expect_equal(d_mr$analyte_ref, c("parent", NA, "parent", NA))
  expect_equal(
    d_mr$PPANMETH,
    c("Reference interval: analyte=parent, 0-8", NA, "Reference interval: analyte=parent, 0-8", NA)
  )
  expect_equal(
    d_mr$exclude,
    c(NA, "The profile is the reference itself (it matches `group_ref`)",
      NA, "The profile is the reference itself (it matches `group_ref`)")
  )
  # The same values as with one row per analyte
  o_data_split <-
    PKNCAdata(
      PKNCAconc(d_conc_mr, conc ~ time | subject / analyte),
      intervals = intervals_mr,
      group_ref = data.frame(analyte = "parent")
    )
  d_split <- suppressMessages(as.data.frame(pk.nca(o_data_split)))
  d_split_mr <- d_split[d_split$PPTESTCD == "mr.cmax", ]
  expect_equal(
    d_split_mr$PPORRES[order(d_split_mr$subject)],
    d_mr$PPORRES[d_mr$analyte == "metab"]
  )
})

test_that("an intervals row covering only the parent gives NA metabolite ratios with a warning", {
  intervals_parent <- data.frame(analyte = "parent", start = 0, end = 8, cmax = TRUE, mr.cmax = TRUE)
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc_mr[d_conc_mr$analyte == "parent", ], conc ~ time | subject / analyte),
      intervals = intervals_parent,
      group_ref = data.frame(analyte = "parent")
    )
  expect_warning(
    d_res <- as.data.frame(pk.nca(o_data)),
    regexp = "The profile is the reference itself (it matches `group_ref`)",
    fixed = TRUE,
    class = "pknca_warning_secondary_auto_reference"
  )
  d_mr <- d_res[d_res$PPTESTCD == "mr.cmax", ]
  expect_equal(d_mr$PPORRES, c(NA_real_, NA_real_))
  expect_equal(d_mr$exclude, rep("The profile is the reference itself (it matches `group_ref`)", 2))
})

test_that("a metabolite ratio requested alone on a row with no reference gives NA rows and its base", {
  # Nothing else is requested on the row, so the failure is reported on the
  # base, which is calculated as it is for a linked request
  intervals_alone <- data.frame(analyte = "parent", start = 0, end = 8, mr.cmax = TRUE)
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc_mr[d_conc_mr$analyte == "parent", ], conc ~ time | subject / analyte),
      intervals = intervals_alone,
      group_ref = data.frame(analyte = "parent")
    )
  expect_warning(
    d_res <- as.data.frame(pk.nca(o_data)),
    class = "pknca_warning_secondary_auto_reference"
  )
  expect_equal(sort(unique(d_res$PPTESTCD)), c("cmax", "mr.cmax"))
  d_mr <- d_res[d_res$PPTESTCD == "mr.cmax", ]
  expect_equal(d_mr$PPORRES, c(NA_real_, NA_real_))
  expect_equal(d_mr$exclude, rep("The profile is the reference itself (it matches `group_ref`)", 2))
  expect_equal(d_res$PPORRES[d_res$PPTESTCD == "cmax"], c(10, 12))
})

test_that("a subject with no parent profile has no ratio, in one row or in a row per analyte", {
  # Subject 2 has only the metabolite.  Its reference is not the parent of
  # subject 1, which the row covering every subject also covers:  a reference
  # is always the subject's own profile.
  d_conc <-
    rbind(
      data.frame(subject = 1, analyte = "parent", time = c(0, 1, 2, 4), conc = c(0, 10, 8, 4)),
      data.frame(subject = 1, analyte = "M1", time = c(0, 1, 2, 4), conc = c(0, 3, 2, 1)),
      data.frame(subject = 2, analyte = "M1", time = c(0, 1, 2, 4), conc = c(0, 30, 20, 10))
    )
  for (param in c("mr.cmax", "ratio.cmax")) {
    intervals_one <- data.frame(start = 0, end = 24, cmax = TRUE)
    intervals_one[[param]] <- TRUE
    intervals_split <- rbind(cbind(analyte = "parent", intervals_one), cbind(analyte = "M1", intervals_one))
    for (layout in c("one row", "row per analyte")) {
      o_data <-
        PKNCAdata(
          PKNCAconc(d_conc, conc ~ time | analyte + subject),
          intervals = if (layout == "one row") intervals_one else intervals_split,
          group_ref = data.frame(analyte = "parent")
        )
      expect_warning(
        expect_message(
          d_res <- as.data.frame(pk.nca(o_data)),
          class = "pknca_message_secondary_ref_created"
        ),
        class = "pknca_warning_secondary_auto_reference"
      )
      d_ratio <- d_res[d_res$PPTESTCD == param, ]
      d_ratio <- d_ratio[order(d_ratio$subject, d_ratio$analyte), ]
      info <- paste(param, layout)
      expect_equal(d_ratio$analyte, c("M1", "parent", "M1"), info = info)
      expect_equal(d_ratio$PPORRES, c(0.3, NA, NA), info = info)
      expect_equal(
        d_ratio$exclude,
        c(
          NA,
          "The profile is the reference itself (it matches `group_ref`)",
          "No reference profile is available for analyte=M1, subject=2 (a reference is the subject's own profile)"
        ),
        info = info
      )
      expect_equal(d_ratio$subject_ref, c(1, NA, NA), info = info)
    }
  }
})

test_that("a metabolite whose nearest parent differs in a column group_ref does not name has no ratio", {
  d_conc <-
    rbind(
      data.frame(subject = 1, analyte = "parent", time = c(0, 1, 2, 4), conc = c(0, 10, 8, 4)),
      data.frame(subject = 1, analyte = "M1", time = c(0, 1, 2, 4), conc = c(0, 3, 2, 1)),
      data.frame(subject = 2, analyte = "M1", time = c(0, 1, 2, 4), conc = c(0, 30, 20, 10))
    )
  intervals_one <- data.frame(start = 0, end = 24, cmax = TRUE, mr.cmax = TRUE)
  # Grouped by subject then analyte, the subject column is the analyte, which
  # group_ref names; subject 2's nearest parent is subject 1's
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | subject + analyte),
      intervals = intervals_one, group_ref = data.frame(analyte = "parent")
    )
  d_res <- as.data.frame(suppressWarnings(suppressMessages(pk.nca(o_data))))
  d_mr <- d_res[d_res$PPTESTCD == "mr.cmax" & d_res$analyte == "M1", ]
  d_mr <- d_mr[order(d_mr$subject), ]
  expect_equal(d_mr$PPORRES, c(0.3, NA))
  expect_equal(
    d_mr$exclude[2],
    "No reference profile is available for subject=2, analyte=M1:  the nearest (subject=1, analyte=parent) also differs in 'subject', which `group_ref` does not name (a column belongs in `ref_vary` only when the same subject's profile at another value of it is a valid reference, as another period of a crossover is)"
  )
  # Study B's subject 2 has no parent, and study A's subject 2 does
  d_studies <-
    rbind(
      cbind(study = "A", d_conc[d_conc$subject == 1, ]),
      cbind(study = "B", d_conc[d_conc$subject == 2, ])
    )
  d_studies$subject <- 2
  o_data_studies <-
    PKNCAdata(
      PKNCAconc(d_studies, conc ~ time | study + analyte + subject),
      intervals = intervals_one, group_ref = data.frame(analyte = "parent")
    )
  d_res <- as.data.frame(suppressWarnings(suppressMessages(pk.nca(o_data_studies))))
  d_mr <- d_res[d_res$PPTESTCD == "mr.cmax" & d_res$analyte == "M1", ]
  d_mr <- d_mr[order(d_mr$study), ]
  expect_equal(d_mr$PPORRES, c(0.3, NA))
  expect_equal(
    d_mr$exclude[2],
    "No reference profile is available for study=B, analyte=M1, subject=2:  the nearest (study=A, analyte=parent) also differs in 'study', which `group_ref` does not name (a column belongs in `ref_vary` only when the same subject's profile at another value of it is a valid reference, as another period of a crossover is)"
  )
})

test_that("with three group levels, each subject's ratio is to its own parent", {
  # Study A:  subject 1 has the parent and the metabolite, subject 2 only the
  # metabolite; study B:  subject 3 has both.  One row covers everything.
  d_conc <-
    rbind(
      data.frame(study = "A", subject = 1, analyte = "parent", time = c(0, 1, 2), conc = c(0, 10, 5)),
      data.frame(study = "A", subject = 1, analyte = "M1", time = c(0, 1, 2), conc = c(0, 3, 2)),
      data.frame(study = "A", subject = 2, analyte = "M1", time = c(0, 1, 2), conc = c(0, 30, 20)),
      data.frame(study = "B", subject = 3, analyte = "parent", time = c(0, 1, 2), conc = c(0, 20, 10)),
      data.frame(study = "B", subject = 3, analyte = "M1", time = c(0, 1, 2), conc = c(0, 5, 4))
    )
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | study + analyte + subject),
      intervals = data.frame(start = 0, end = 24, cmax = TRUE, mr.cmax = TRUE),
      group_ref = data.frame(analyte = "parent")
    )
  expect_warning(
    expect_message(
      d_res <- as.data.frame(pk.nca(o_data)),
      regexp = "Secondary parameter 'mr.cmax': using (analyte=parent, 0-24) as the reference interval 'autoref1'.",
      fixed = TRUE,
      class = "pknca_message_secondary_ref_created"
    ),
    regexp = "No reference profile is available for study=A, analyte=M1, subject=2 (a reference is the subject's own profile)",
    fixed = TRUE,
    class = "pknca_warning_secondary_auto_reference"
  )
  d_mr <- d_res[d_res$PPTESTCD == "mr.cmax" & d_res$analyte == "M1", ]
  d_mr <- d_mr[order(d_mr$subject), ]
  expect_equal(d_mr$PPORRES, c(3/10, NA, 5/20))
  expect_equal(
    d_mr$exclude,
    c(NA, "No reference profile is available for study=A, analyte=M1, subject=2 (a reference is the subject's own profile)", NA)
  )
})

test_that("param_pattern selects what it selected before the new ratios were registered", {
  all_params <- setdiff(names(get.interval.cols()), c("start", "end"))
  new_members <- names(PKNCA:::parameter_rule_members_new())
  expect_equal(length(new_members), 70)
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
  # interval_remove_param() removes what it removed before, for every base:
  # from a table requesting every parameter, the pattern of the base's exact
  # name removes the parameters it matched before
  full <- data.frame(start = 0, end = 24)
  for (p in all_params) {
    full[[p]] <- TRUE
  }
  full <- check.interval.specification(full)
  for (base in strsplit(pknca_parameter_rules()$bases, split = ", ", fixed = TRUE)[[1]]) {
    removed <- suppressWarnings(interval_remove_param(full, param_pattern = base))
    now_false <- all_params[!vapply(all_params, function(p) isTRUE(removed[[p]]), TRUE)]
    expect_equal(sort(now_false), sort(grep(base, x = before, value = TRUE)), info = base)
  }
  # The six ratios registered by name before still follow their base's pattern
  expect_true("ratio.cmax" %in% PKNCA:::parameter_pattern_match("cmax", all_params))
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
  rules <- pknca_parameter_rules()
  for (i in seq_len(nrow(rules))) {
    for (base in strsplit(rules$bases[i], split = ", ", fixed = TRUE)[[1]]) {
      member <- paste0(rules$prefix[i], ".", base)
      for (field in c("route", "sample_type", "dosing", "sparse")) {
        expect_identical(tbl[member, field], tbl[base, field], info = paste(member, field))
      }
    }
  }
  expect_equal(tbl["ratio.ceoi", "route"], "iv_infusion")
  expect_equal(tbl["mr.ceoi", "route"], "iv_infusion")
})
