# A results object with one subject and analyte in every combination of
# `parts` and `periods`, each with the interval windows in `windows` (a list
# of c(start, end)), requesting Cmax and Tmax for every interval
grpid_results <- function(parts = "A", periods = 1:2, windows = list(c(0, 4), c(0, 2)), ...) {
  groups <- expand.grid(Part = parts, Period = periods, stringsAsFactors = FALSE)
  d_conc <- merge(groups, data.frame(time = 0:101), by = NULL)
  d_conc$subject <- 1
  d_conc$analyte <- "DRUG"
  d_conc$conc <- rep(c(0, 2, 1, 0.5, 0.25, 0.1), length.out = nrow(d_conc))
  d_dose <- groups
  d_dose$subject <- 1
  d_dose$time <- 0
  d_dose$dose <- 10
  d_intervals <-
    merge(
      groups,
      data.frame(
        start = vapply(windows, FUN = function(x) x[1], FUN.VALUE = 1),
        end = vapply(windows, FUN = function(x) x[2], FUN.VALUE = 1),
        cmax = TRUE,
        tmax = TRUE
      ),
      by = NULL
    )
  d_intervals$subject <- 1
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | Part + Period + subject / analyte),
      PKNCAdose(d_dose, dose ~ time | Part + Period + subject),
      intervals = d_intervals,
      ...
    )
  suppressMessages(pk.nca(o_data))
}

# The PPGRPID of each row, ordered by group, interval end, and parameter
grpid_text <- function(results, ...) {
  ret <- as.data.frame(results, out_format = "cdisc", ...)
  ret <- ret[order(ret$Part, ret$Period, ret$end, ret$PPTESTCD), ]
  ret$PPGRPID
}

test_that("PPGRPID is interval-only without grpid_cols, and follows the time point reference columns", {
  o_nca <- grpid_results(periods = 1)
  ret <- as.data.frame(o_nca, out_format = "cdisc")
  # The windows are given out of order; the shorter one is the first interval
  expect_equal(grpid_text(o_nca), c("I01", "I01", "I02", "I02"))
  expect_equal(names(ret)[ncol(ret)], "PPGRPID")
  expect_equal(names(ret)[ncol(ret) - 1], "PPTPTREF")
  expect_type(ret$PPGRPID, "character")
  # The grouping columns stay in the output
  expect_true(all(c("Part", "Period", "subject") %in% names(ret)))
  # Other output formats are unchanged
  expect_false("PPGRPID" %in% names(as.data.frame(o_nca)))
  expect_false("PPGRPID" %in% names(as.data.frame(o_nca, out_format = "wide")))
})

test_that("PPGRPID has the prefixed grouping columns and the interval", {
  o_nca <- grpid_results()
  expect_equal(
    grpid_text(o_nca, grpid_cols = c(Period = "P")),
    c(rep(c("P1.I01", "P1.I02"), each = 2), rep(c("P2.I01", "P2.I02"), each = 2))
  )
  o_nca_parts <- grpid_results(parts = c("A", "B"))
  expect_equal(
    grpid_text(o_nca_parts, grpid_cols = c(Part = "", Period = "P")),
    rep(
      c("A.P1.I01", "A.P1.I02", "A.P2.I01", "A.P2.I02", "B.P1.I01", "B.P1.I02", "B.P2.I01", "B.P2.I02"),
      each = 2
    )
  )
  # The order of grpid_cols is the order of the text, and the prefix is only
  # text
  expect_equal(
    grpid_text(o_nca_parts, grpid_cols = c(Period = "Per", Part = "Study ")),
    rep(
      c(
        "Per1.Study A.I01", "Per1.Study A.I02", "Per2.Study A.I01", "Per2.Study A.I02",
        "Per1.Study B.I01", "Per1.Study B.I02", "Per2.Study B.I01", "Per2.Study B.I02"
      ),
      each = 2
    )
  )
  # Without grpid_cols, the intervals of every group are still numbered within
  # the group
  expect_equal(
    grpid_text(o_nca_parts),
    rep(c("I01", "I02"), each = 2, times = 4)
  )
})

test_that("records of one interval share its number, whatever the order of the specification", {
  o_nca <- grpid_results(periods = 1, windows = list(c(1, 5), c(0, Inf), c(0, 3), c(0, 2)))
  ret <- as.data.frame(o_nca, out_format = "cdisc")
  ret <- ret[order(ret$start, ret$end, ret$PPTESTCD), ]
  expect_equal(ret$start, rep(c(0, 0, 0, 1), each = 2))
  expect_equal(ret$end, rep(c(2, 3, Inf, 5), each = 2))
  expect_equal(ret$PPGRPID, rep(c("I01", "I02", "I03", "I04"), each = 2))
})

test_that("grpid_cols of PKNCAdata is the default and as.data.frame overrides it", {
  o_nca <- grpid_results(periods = 1, grpid_cols = c(Part = ""))
  expect_equal(o_nca$data$grpid_cols, c(Part = ""))
  expect_equal(grpid_text(o_nca), c("A.I01", "A.I01", "A.I02", "A.I02"))
  expect_equal(
    grpid_text(o_nca, grpid_cols = c(Period = "P")),
    c("P1.I01", "P1.I01", "P1.I02", "P1.I02")
  )
  # An empty vector asks for the interval-only identifier
  expect_equal(grpid_text(o_nca, grpid_cols = character()), c("I01", "I01", "I02", "I02"))
  # Without a default, the PKNCAdata object has none
  expect_null(grpid_results(periods = 1)$data$grpid_cols)
})

test_that("the period is a number with grpid_numeric", {
  o_nca <- grpid_results(periods = c("01", "02"))
  expect_equal(
    grpid_text(o_nca, grpid_cols = c(Period = "P"), grpid_numeric = "Period"),
    c(rep(c("P1.I01", "P1.I02"), each = 2), rep(c("P2.I01", "P2.I02"), each = 2))
  )
  # Without it, the text is kept as it is
  expect_equal(
    grpid_text(o_nca, grpid_cols = c(Period = "P"))[1],
    "P01.I01"
  )
  # A number stored as a number is written as that number
  o_nca_num <- grpid_results(periods = c(1, 12))
  expect_equal(
    grpid_text(o_nca_num, grpid_cols = c(Period = "P"), grpid_numeric = "Period")[c(1, 5)],
    c("P1.I01", "P12.I01")
  )
})

test_that("grpid_numeric values that are not whole numbers of at least 1 are errors", {
  for (period in c("Screening", "0", "-1", "1.5", "Inf", NA_character_)) {
    o_nca <- grpid_results(periods = c("1", "2"))
    o_nca$result$Period[o_nca$result$Period %in% "2"] <- period
    expect_error(
      as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Period = "P"), grpid_numeric = "Period"),
      class = "pknca_error_grpid_numeric_invalid",
      info = as.character(period)
    )
  }
  # Two spellings of one number cannot be told apart
  expect_error(
    pknca_grpid_value_text(c("01", "1"), col = "Period", numeric = TRUE),
    class = "pknca_error_grpid_value_collision",
    regexp = "Period.*same group identifier text: 1"
  )
  expect_equal(pknca_grpid_value_text(c("01", "02", "01"), col = "Period", numeric = TRUE), c("1", "2", "1"))
  expect_equal(pknca_grpid_value_text(c(3, 10), col = "Period", numeric = TRUE), c("3", "10"))
})

test_that("grpid values with the separator or without text are errors", {
  o_nca <- grpid_results(parts = c("A", "B.1"), periods = 1)
  expect_error(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Part = "")),
    class = "pknca_error_grpid_value_invalid",
    regexp = "Part.*'\\.'.*B\\.1"
  )
  o_nca_empty <- grpid_results(parts = c("A", ""), periods = 1)
  expect_error(
    as.data.frame(o_nca_empty, out_format = "cdisc", grpid_cols = c(Part = "")),
    class = "pknca_error_grpid_value_invalid",
    regexp = "Part.*empty"
  )
  expect_error(
    pknca_grpid_value_text(c("A", NA), col = "Part", numeric = FALSE),
    class = "pknca_error_grpid_value_invalid"
  )
  # The separator is not allowed in the prefix either
  expect_error(
    as.data.frame(grpid_results(periods = 1), out_format = "cdisc", grpid_cols = c(Period = "P.")),
    class = "pknca_error_grpid_cols_invalid"
  )
})

test_that("grpid_cols may not name the subject or analyte, or a column that is not a group", {
  o_nca <- grpid_results(periods = 1)
  expect_error(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Part = "", subject = "S")),
    class = "pknca_error_grpid_cols_subject_analyte",
    regexp = "subject"
  )
  expect_error(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(analyte = "A")),
    class = "pknca_error_grpid_cols_subject_analyte",
    regexp = "analyte"
  )
  expect_error(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(dose = "D")),
    class = "pknca_error_grpid_cols_not_group",
    regexp = "dose"
  )
  # PKNCAdata() checks the argument too
  expect_error(
    grpid_results(grpid_cols = c(subject = "S")),
    class = "pknca_error_grpid_cols_subject_analyte"
  )
})

test_that("grpid_cols and grpid_numeric must be the right type", {
  o_conc <- as_PKNCAconc(grpid_results(periods = 1))
  expect_null(assert_grpid_cols(NULL, o_conc))
  expect_equal(assert_grpid_cols(character(), o_conc), character())
  expect_equal(assert_grpid_cols(c(Part = "", Period = "P"), o_conc), c(Part = "", Period = "P"))
  for (bad in list("P", c("P", "Q"), c(Part = "A", Part = "B"), c(Part = NA_character_), 1, list(Part = "A"))) {
    expect_error(
      assert_grpid_cols(bad, o_conc),
      class = "pknca_error_grpid_cols_invalid",
      info = deparse(bad)
    )
  }
  expect_error(
    assert_grpid_cols(c(Part = ""), o_conc, grpid_numeric = "Period"),
    class = "pknca_error_grpid_numeric_invalid",
    regexp = "Period"
  )
  expect_error(
    assert_grpid_cols(c(Part = ""), o_conc, grpid_numeric = 1),
    class = "pknca_error_grpid_numeric_invalid"
  )
  expect_error(
    assert_grpid_cols(c(Part = ""), o_conc, grpid_numeric = NA_character_),
    class = "pknca_error_grpid_numeric_invalid"
  )
})

test_that("the interval number is dense within each group, by start and then end", {
  data <-
    data.frame(
      g = c("b", "a", "a", "a", "a", "b", "a"),
      start = c(0, 5, 0, 0, 0, 0, 5),
      end = c(Inf, 8, 24, 12, 24, 6, 8)
    )
  # Group a: (0, 12) 1, (0, 24) 2, (5, 8) 3; group b: (0, 6) 1, (0, Inf) 2
  expect_equal(pknca_interval_number(data, "g"), c(2L, 3L, 2L, 1L, 2L, 1L, 3L))
  # Without groups, every row is in one group
  expect_equal(pknca_interval_number(data, character()), c(4L, 5L, 3L, 2L, 3L, 1L, 5L))
  expect_equal(pknca_interval_number(data[0, ], "g"), integer())
})

test_that("a missing interval start or end is an error", {
  expect_error(
    pknca_interval_number(data.frame(g = "a", start = NA_real_, end = 1), "g"),
    class = "pknca_error_grpid_interval_missing"
  )
  expect_error(
    pknca_interval_number(data.frame(g = "a", start = 0, end = NA_real_), "g"),
    class = "pknca_error_grpid_interval_missing"
  )
})

test_that("the interval number is padded to the digits of the largest number, and at least two", {
  expect_equal(pknca_grpid_format(list("A"), c(1L, 99L), width = 2), c("A.I01", "A.I99"))
  expect_equal(pknca_grpid_format(list("A", "P1"), c(1L, 100L), width = 3), c("A.P1.I001", "A.P1.I100"))
  expect_equal(pknca_grpid_format(list(), c(1L, 12L), width = 2), c("I01", "I12"))
  expect_equal(pknca_grpid_format(list(Part = "A"), 1000L, width = 4), "A.I1000")

  windows <- lapply(0:99, function(i) c(i, i + 2))
  o_nca <- grpid_results(periods = 1, windows = windows)
  ret <- as.data.frame(o_nca, out_format = "cdisc")
  ret <- ret[order(ret$start, ret$PPTESTCD), ]
  expect_equal(ret$PPGRPID, rep(sprintf("I%03d", 1:100), each = 2))
  # Text order is time order
  expect_equal(order(ret$PPGRPID), seq_len(nrow(ret)))
  # 99 intervals stay at two digits
  o_nca_99 <- grpid_results(periods = 1, windows = windows[1:99])
  ret_99 <- as.data.frame(o_nca_99, out_format = "cdisc")
  expect_equal(sort(unique(ret_99$PPGRPID)), sprintf("I%02d", 1:99))
})

test_that("the numbering and width come from every interval of the results", {
  o_nca <- grpid_results(periods = 1)
  long <- as.data.frame(o_nca)
  last_interval <- long[long$end == 4 & long$PPTESTCD %in% "cmax", ]
  expect_equal(nrow(last_interval), 1)
  # The row of the later interval is numbered I02 even when the output does not
  # have the earlier interval
  expect_equal(
    pknca_cdisc_add_grpid(last_interval, o_nca, grpid_cols = c(Part = ""), grpid_numeric = character())$PPGRPID,
    "A.I02"
  )
})
