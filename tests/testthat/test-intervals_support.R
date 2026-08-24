# Shared fixtures --------------------------------------------------------

d_conc <- data.frame(
  conc = c(1, 0.6, 0.2, 0.1, 0.09, 0.04, 1.2, 0.8, 0.3, 0.2, 0.11, 0.05),
  time = rep(0:5, 2),
  analyte = rep(c("Analyte1", "Analyte2"), each = 6),
  ID = rep(1:2, each = 6)
)

d_dose <- data.frame(dose = c(100, 200), time = c(0, 0), ID = c(1, 2))

intervals <- data.frame(
  start = c(0, 0, 0),
  end = c(24, 48, Inf),
  half.life = c(TRUE, TRUE, TRUE),
  cmax = c(TRUE, TRUE, TRUE),
  impute = c("start_conc0,start_predose", "start_predose", "start_conc0"),
  analyte = c("Analyte1", "Analyte2", "Analyte1"),
  ID = c(1, 2, 1)
)

o_conc <- PKNCA::PKNCAconc(d_conc, conc ~ time | ID / analyte)
o_dose <- PKNCA::PKNCAdose(d_dose, dose ~ time | ID)
o_data <- PKNCA::PKNCAdata(o_conc, o_dose, intervals = intervals)

# The columns of interest for most comparisons
cols_check <- c("analyte", "half.life", "cmax", "impute")

# interval_longer() / interval_wider() -----------------------------------

describe("interval_longer and interval_wider", {
  it("round trip without changing anything", {
    expect_equal(interval_wider(interval_longer(intervals), intervals), intervals)
  })

  it("give one long row per interval and requested parameter", {
    long <- interval_longer(intervals)
    expect_equal(nrow(long), 6L)
    expect_equal(sort(unique(long$param)), c("cmax", "half.life"))
  })

  it("drop parameters that are not requested", {
    ivl <- data.frame(start = 0, end = 24, cmax = TRUE, tmax = FALSE)
    expect_equal(interval_longer(ivl)$param, "cmax")
  })

  it("normalize NA to FALSE, which is required for the result to be usable", {
    # NA in a parameter column is rejected by check.interval.specification()
    # and stops pk.nca()
    ivl <- data.frame(start = 0, end = 24, cmax = TRUE, tmax = NA)
    expect_equal(interval_wider(interval_longer(ivl), ivl)$tmax, FALSE)
  })

  it("keep a parameter column that no longer has any TRUE value", {
    ivl <- data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE)
    long <- interval_longer(ivl)
    ret <- interval_wider(long[long$param != "tmax", ], ivl)
    expect_equal(ret$tmax, FALSE)
  })

  it("preserve the input column order", {
    ivl <- data.frame(cmax = TRUE, impute = c("", "m0"))
    expect_equal(names(interval_wider(interval_longer(ivl), ivl)), c("cmax", "impute"))
  })

  it("error when there are no parameter columns", {
    expect_error(
      interval_longer(data.frame(start = 0, end = 24)),
      class = "pknca_error_interval_no_param_cols"
    )
  })

  it("error when the impute column is not character", {
    expect_error(
      interval_longer(data.frame(start = 0, end = 24, cmax = TRUE, impute = 1)),
      class = "pknca_error_interval_impute_not_character"
    )
  })

  it("error when nothing remains to calculate", {
    ivl <- data.frame(start = 0, end = 24, cmax = TRUE)
    expect_error(
      interval_wider(interval_longer(ivl)[0, ], ivl),
      class = "pknca_error_interval_nothing_remains"
    )
  })
})

# Imputation string helpers ----------------------------------------------

describe("add_impute_method", {
  it("appends to an empty, NA, or populated specification", {
    expect_equal(
      add_impute_method(c("", NA_character_, "m0", "m0,m1"), "mlast"),
      c("mlast", "mlast", "m0,mlast", "m0,m1,mlast")
    )
  })

  it("honors `after`", {
    expect_equal(add_impute_method("m0,m1", "mnew", after = 0), "mnew,m0,m1")
    expect_equal(add_impute_method("m0,m1", "mnew", after = 1), "m0,mnew,m1")
    expect_equal(add_impute_method("m0,m1", "mnew", after = Inf), "m0,m1,mnew")
  })

  it("moves rather than duplicates a method that is already present", {
    expect_equal(add_impute_method("m0,m1", "m0", after = Inf), "m1,m0")
    expect_equal(add_impute_method("m0", "m0", after = Inf), "m0")
  })

  it("splits on spaces as well as commas", {
    expect_equal(add_impute_method("m0, m1", "mnew"), "m0,m1,mnew")
  })

  it("returns the empty vector unchanged", {
    expect_equal(add_impute_method(character(), "mnew"), character())
  })
})

describe("remove_impute_method", {
  it("removes a method and gives NA when none remains", {
    expect_equal(
      remove_impute_method(c("m0", "m0,m1", "m1"), "m0"),
      c(NA_character_, "m1", "m1")
    )
  })

  it("removes every occurrence when a method is repeated", {
    expect_equal(remove_impute_method("m0,m1,m0", "m0"), "m1")
  })

  it("leaves a specification without the method alone", {
    expect_equal(remove_impute_method("m1", "m0"), "m1")
  })

  it("returns the empty vector unchanged", {
    expect_equal(remove_impute_method(character(), "mnew"), character())
  })
})

# Group matching ---------------------------------------------------------

describe("interval_match_groups", {
  d_groups <- data.frame(
    analyte = c("A1", "A2", "A1", "A2"),
    route = c("iv", "iv", "ev", "ev"),
    stringsAsFactors = FALSE
  )

  it("matches on a single column", {
    expect_equal(
      interval_match_groups(d_groups, data.frame(analyte = "A1")),
      c(TRUE, FALSE, TRUE, FALSE)
    )
  })

  it("requires every column to match (and), not any of them (or)", {
    expect_equal(
      interval_match_groups(d_groups, data.frame(analyte = "A1", route = "ev")),
      c(FALSE, FALSE, TRUE, FALSE)
    )
  })

  it("matches any row of target_groups (or)", {
    target <- data.frame(analyte = c("A1", "A2"), route = c("ev", "iv"))
    expect_equal(
      interval_match_groups(d_groups, target),
      c(FALSE, TRUE, TRUE, FALSE)
    )
  })

  it("errors for a column that is not in the intervals", {
    expect_error(
      interval_match_groups(d_groups, data.frame(nonexistent = "A1")),
      class = "pknca_error_interval_target_groups_cols"
    )
  })
})

# interval_add_impute() --------------------------------------------------

describe("interval_add_impute", {
  it("adds the method to a bare intervals data.frame", {
    simple_df <- data.frame(cmax = TRUE, impute = c("", "m0", "m0,m1"))
    expect_equal(
      interval_add_impute(simple_df, target_impute = "mlast"),
      data.frame(cmax = TRUE, impute = c("mlast", "m0,mlast", "m0,m1,mlast"))
    )
  })

  it("errors when target_impute is missing", {
    expect_error(interval_add_impute(o_data))
  })

  it("errors for a non-character target_impute", {
    expect_error(interval_add_impute(o_data, target_impute = 123))
  })

  it("errors for an unknown target_params", {
    expect_error(
      interval_add_impute(o_data, target_impute = "start_conc0", target_params = "nonexistent"),
      class = "pknca_error_invalid_param_name"
    )
  })

  it("warns and makes no change when target_impute is NA or empty", {
    expect_warning(
      expect_equal(interval_add_impute(o_data, target_impute = NA_character_), o_data),
      class = "pknca_warning_interval_impute_none_specified"
    )
    expect_warning(
      expect_equal(interval_add_impute(o_data, target_impute = ""), o_data),
      class = "pknca_warning_interval_impute_none_specified"
    )
  })

  it("creates the impute column when it is missing", {
    d_no_imp <- o_data
    d_no_imp$intervals$impute <- NULL
    res <- interval_add_impute(d_no_imp, target_impute = "new_impute")
    expect_equal(res$intervals$impute, rep("new_impute", 3))
  })

  it("applies to all parameters when target_params is not given", {
    result <- interval_add_impute(o_data, target_impute = "new_impute")
    expect_equal(
      result$intervals[, cols_check],
      data.frame(
        analyte = c("Analyte1", "Analyte2", "Analyte1"),
        half.life = TRUE,
        cmax = TRUE,
        impute = c(
          "start_conc0,start_predose,new_impute",
          "start_predose,new_impute",
          "start_conc0,new_impute"
        )
      )
    )
  })

  it("splits an interval when only some parameters get the imputation", {
    result <- interval_add_impute(o_data, target_impute = "new_impute", target_params = "cmax")
    expect_equal(nrow(result$intervals), 6L)
    expect_equal(
      result$intervals$impute,
      c(
        "start_conc0,start_predose,new_impute", "start_conc0,start_predose",
        "start_predose,new_impute", "start_predose",
        "start_conc0,new_impute", "start_conc0"
      )
    )
    expect_equal(result$intervals$cmax, rep(c(TRUE, FALSE), 3))
    expect_equal(result$intervals$half.life, rep(c(FALSE, TRUE), 3))
  })

  it("does not split when the targeted parameters end up with the same imputation", {
    intervals_shared <- data.frame(
      start = 0, end = c(24, 48),
      half.life = TRUE, cmax = TRUE,
      impute = c("start_conc0,start_predose", "start_predose"),
      analyte = c("Analyte1", "Analyte2"), ID = c(1, 2)
    )
    o_shared <- PKNCA::PKNCAdata(o_conc, o_dose, intervals = intervals_shared)
    result <- suppressWarnings(
      interval_add_impute(
        o_shared, target_impute = "start_predose", target_params = "cmax", after = Inf
      )
    )
    expect_equal(nrow(result$intervals), 2L)
  })

  it("moves an existing method rather than duplicating it", {
    result <- interval_add_impute(o_data, target_impute = "start_conc0", after = Inf)
    expect_equal(
      result$intervals$impute,
      c("start_predose,start_conc0", "start_predose,start_conc0", "start_conc0")
    )
  })

  it("restricts the change to target_groups", {
    result <- interval_add_impute(
      o_data, target_impute = "new_impute",
      target_groups = data.frame(analyte = "Analyte1")
    )
    expect_equal(
      result$intervals$impute,
      c(
        "start_conc0,start_predose,new_impute",
        "start_predose",
        "start_conc0,new_impute"
      )
    )
  })

  it("requires every target_groups column to match", {
    ivl <- data.frame(
      start = 0, end = 24, cmax = TRUE, half.life = TRUE, impute = NA_character_,
      analyte = c("Analyte1", "Analyte2", "Analyte1", "Analyte2"),
      ID = c(1, 1, 2, 2)
    )
    result <- interval_add_impute(
      ivl, target_impute = "start_conc0",
      target_groups = data.frame(analyte = "Analyte1", ID = 2)
    )
    expect_equal(result$impute, c(NA, NA, "start_conc0", NA))
  })

  it("warns and makes no change when nothing matches", {
    expect_warning(
      expect_equal(
        interval_add_impute(
          o_data, target_impute = "start_conc0",
          target_groups = data.frame(analyte = "Analyte3")
        ),
        o_data
      ),
      class = "pknca_warning_interval_impute_no_change"
    )
  })
})

# interval_remove_impute() -----------------------------------------------

describe("interval_remove_impute", {
  it("removes the method from a bare intervals data.frame", {
    simple_df <- data.frame(cmax = TRUE, impute = c("m0", "m0,m1"))
    expect_equal(
      interval_remove_impute(simple_df, target_impute = "m0"),
      data.frame(cmax = TRUE, impute = c(NA_character_, "m1"))
    )
  })

  it("applies to all parameters when target_params is not given", {
    result <- interval_remove_impute(o_data, target_impute = "start_conc0")
    expect_equal(
      result$intervals[, cols_check],
      data.frame(
        analyte = c("Analyte1", "Analyte2", "Analyte1"),
        half.life = TRUE,
        cmax = TRUE,
        impute = c("start_predose", "start_predose", NA_character_)
      )
    )
  })

  it("removes every occurrence when a method is repeated", {
    o_repeat <- o_data
    o_repeat$intervals$impute <- "start_conc0,start_predose,start_conc0"
    result <- interval_remove_impute(o_repeat, target_impute = "start_conc0")
    expect_equal(result$intervals$impute, rep("start_predose", 3))
  })

  it("splits an interval when only some parameters lose the imputation", {
    result <- interval_remove_impute(o_data, target_impute = "start_conc0", target_params = "cmax")
    expect_equal(nrow(result$intervals), 5L)
    expect_equal(
      result$intervals$impute,
      c("start_predose", "start_conc0,start_predose", "start_predose", NA_character_, "start_conc0")
    )
  })

  it("edits the whole-dataset imputation when the change applies everywhere", {
    o_global <- o_data
    o_global$intervals$impute <- NULL
    o_global$impute <- "start_conc0, start_predose"
    result <- interval_remove_impute(o_global, target_impute = "start_conc0")
    expect_equal(result$impute, "start_predose")
    expect_false("impute" %in% names(result$intervals))
  })

  it("moves the whole-dataset imputation into a column for a targeted change", {
    o_global <- o_data
    o_global$intervals$impute <- NULL
    o_global$impute <- "start_conc0, start_predose"
    result <- interval_remove_impute(
      o_global, target_impute = "start_conc0",
      target_groups = data.frame(analyte = "Analyte1")
    )
    expect_equal(
      result$intervals$impute,
      c("start_predose", "start_conc0, start_predose", "start_predose")
    )
  })

  it("warns when there is no imputation at all", {
    d_no_imp <- o_data
    d_no_imp$intervals$impute <- NULL
    d_no_imp$impute <- NA_character_
    expect_warning(
      expect_equal(interval_remove_impute(d_no_imp, target_impute = "start_conc0"), d_no_imp),
      class = "pknca_warning_interval_impute_absent"
    )
  })

  it("warns and makes no change when the method is not present", {
    expect_warning(
      expect_equal(interval_remove_impute(o_data, target_impute = "not_used"), o_data),
      class = "pknca_warning_interval_impute_no_change"
    )
  })
})

describe("interval_add_impute and interval_remove_impute", {
  it("are inverses of each other", {
    result_add <- interval_add_impute(o_data, target_impute = "new_impute")
    expect_equal(interval_remove_impute(result_add, target_impute = "new_impute"), o_data)
  })
})

# interval_add_param() / interval_remove_param() -------------------------

describe("interval_add_param", {
  it("adds parameters named by `param`", {
    expect_equal(
      interval_add_param(
        data.frame(start = 0, end = 24, cmax = TRUE),
        param = c("tmax", "auclast")
      ),
      data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE, auclast = TRUE)
    )
  })

  it("adds parameters matching `param_pattern`", {
    ret <-
      interval_add_param(
        data.frame(start = 0, end = 24, cmax = TRUE),
        param_pattern = "^aucinf\\."
      )
    expect_true(all(c("aucinf.obs", "aucinf.pred") %in% names(ret)))
    expect_true(ret$aucinf.obs)
  })

  it("does not add an impute column that was not there", {
    ret <- interval_add_param(data.frame(start = 0, end = 24, cmax = TRUE), param = "tmax")
    expect_false("impute" %in% names(ret))
  })

  it("keeps the imputation of the interval it is added to", {
    ret <- interval_add_param(o_data, param = "tmax")
    expect_equal(ret$intervals$tmax, rep(TRUE, 3))
    expect_equal(ret$intervals$impute, intervals$impute)
  })

  it("restricts the addition to target_groups", {
    ret <-
      interval_add_param(
        o_data, param = "tmax",
        target_groups = data.frame(analyte = "Analyte2")
      )
    expect_equal(ret$intervals$tmax, c(FALSE, TRUE, FALSE))
  })

  it("adds to an interval that currently calculates nothing", {
    ivl <- data.frame(start = 0, end = c(24, 48), cmax = c(TRUE, FALSE))
    expect_equal(interval_add_param(ivl, param = "tmax")$tmax, c(TRUE, TRUE))
  })

  it("errors when neither param nor param_pattern is given", {
    expect_error(
      interval_add_param(data.frame(start = 0, end = 24, cmax = TRUE)),
      class = "pknca_error_interval_param_missing"
    )
  })

  it("errors for an unknown parameter name", {
    expect_error(
      interval_add_param(data.frame(start = 0, end = 24, cmax = TRUE), param = "nonexistent"),
      class = "pknca_error_invalid_param_name"
    )
  })

  it("warns when a pattern matches nothing", {
    expect_warning(
      interval_add_param(
        data.frame(start = 0, end = 24, cmax = TRUE),
        param = "tmax", param_pattern = "zzz_no_match"
      ),
      class = "pknca_warning_interval_param_pattern_no_match"
    )
  })
})

describe("interval_remove_param", {
  it("removes parameters named by `param`", {
    expect_equal(
      interval_remove_param(
        data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE),
        param = "tmax"
      ),
      data.frame(start = 0, end = 24, cmax = TRUE, tmax = FALSE)
    )
  })

  it("removes parameters matching `param_pattern`", {
    ret <-
      interval_remove_param(
        data.frame(start = 0, end = 24, cmax = TRUE, cmin = TRUE, tmax = TRUE),
        param_pattern = "^cm"
      )
    expect_equal(
      ret[, c("cmax", "cmin", "tmax")],
      data.frame(cmax = FALSE, cmin = FALSE, tmax = TRUE)
    )
  })

  it("restricts the removal to target_groups", {
    ret <-
      interval_remove_param(
        o_data, param = "cmax",
        target_groups = data.frame(analyte = "Analyte1")
      )
    expect_equal(ret$intervals$cmax, c(FALSE, TRUE, FALSE))
  })

  it("errors when nothing would remain to calculate", {
    expect_error(
      interval_remove_param(data.frame(start = 0, end = 24, cmax = TRUE), param = "cmax"),
      class = "pknca_error_interval_nothing_remains"
    )
  })

  it("warns and makes no change when nothing matches", {
    ivl <- data.frame(start = 0, end = 24, cmax = TRUE)
    expect_warning(
      expect_equal(interval_remove_param(ivl, param = "tmax"), ivl),
      class = "pknca_warning_interval_no_target_rows"
    )
  })
})

# The results have to be usable ------------------------------------------

describe("edited intervals are usable by PKNCA", {
  # A row-splitting edit used to leave NA in the parameter columns, which
  # check.interval.specification() rejects and pk.nca() stops on.
  it("pass check.interval.specification() after a row-splitting edit", {
    result <- interval_add_impute(o_data, target_impute = "start_conc0", target_params = "cmax")
    expect_no_error(check.interval.specification(result$intervals))
  })

  it("can be calculated by pk.nca() after a row-splitting edit", {
    result <- interval_add_impute(o_data, target_impute = "start_conc0", target_params = "cmax")
    expect_no_error(suppressWarnings(suppressMessages(pk.nca(result))))
  })

  it("pass assert_intervals() after adding a parameter", {
    result <- interval_add_param(o_data, param = "tmax")
    expect_no_error(assert_intervals(result$intervals, result))
  })

  it("have no NA in any parameter column", {
    result <- interval_remove_impute(o_data, target_impute = "start_conc0", target_params = "cmax")
    param_cols <- intersect(names(result$intervals), names(get.interval.cols()))
    expect_false(anyNA(result$intervals[, param_cols]))
  })
})
