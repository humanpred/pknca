# A results object with the subjects in `subjects` and one analyte in every
# combination of `parts` and `periods`, each with the interval windows in
# `windows` (a list of c(start, end)), requesting Cmax and Tmax for every
# interval
grpid_results <- function(parts = "A", periods = 1:2, windows = list(c(0, 4), c(0, 2)), subjects = 1, ...) {
  groups <- expand.grid(Part = parts, Period = periods, subject = subjects, stringsAsFactors = FALSE)
  d_conc <- merge(groups, data.frame(time = 0:101), by = NULL)
  d_conc$analyte <- "DRUG"
  d_conc$conc <- rep(c(0, 2, 1, 0.5, 0.25, 0.1), length.out = nrow(d_conc))
  d_dose <- groups
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
  ret <- ret[order(ret$Part, ret$Period, ret$subject, ret$end, ret$PPTESTCD), ]
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
  # Without grpid_cols, the groups have the same windows and so the same numbers
  expect_equal(
    grpid_text(o_nca_parts),
    rep(c("I01", "I02"), each = 2, times = 4)
  )
})

test_that("grouping columns outside grpid_cols do not enter the numbering", {
  # Plasma and urine have the same two windows, and the same numbers
  o_nca <- grpid_results(parts = c("plasma", "urine"), periods = 1)
  ret <- as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Period = "P"))
  ret <- ret[order(ret$Part, ret$end, ret$PPTESTCD), ]
  expect_equal(ret$Part, rep(c("plasma", "urine"), each = 4))
  expect_equal(ret$PPGRPID, rep(c("P1.I01", "P1.I02"), each = 2, times = 2))
  # A window that only urine has takes the next number among the windows of
  # the subject, wherever it came from
  o_nca_extra <-
    grpid_results(
      parts = c("plasma", "urine"), periods = 1,
      windows = list(c(0, 2), c(0, 4))
    )
  o_nca_extra$result <-
    o_nca_extra$result[!(o_nca_extra$result$Part %in% "plasma" & o_nca_extra$result$end == 4), ]
  ret_extra <- as.data.frame(o_nca_extra, out_format = "cdisc")
  ret_extra <- ret_extra[order(ret_extra$Part, ret_extra$end, ret_extra$PPTESTCD), ]
  expect_equal(ret_extra$Part, rep(c("plasma", "urine", "urine"), each = 2))
  expect_equal(ret_extra$end, rep(c(2, 2, 4), each = 2))
  expect_equal(ret_extra$PPGRPID, rep(c("I01", "I01", "I02"), each = 2))
})

test_that("records of one interval share its number, whatever the order of the specification", {
  o_nca <- grpid_results(periods = 1, windows = list(c(1, 5), c(0, Inf), c(0, 3), c(0, 2)))
  ret <- as.data.frame(o_nca, out_format = "cdisc")
  ret <- ret[order(ret$start, ret$end, ret$PPTESTCD), ]
  expect_equal(ret$start, rep(c(0, 0, 0, 1), each = 2))
  expect_equal(ret$end, rep(c(2, 3, Inf, 5), each = 2))
  expect_equal(ret$PPGRPID, rep(c("I01", "I02", "I03", "I04"), each = 2))
})

test_that("each subject numbers its own intervals", {
  o_nca <- grpid_results(periods = 1, subjects = 1:2)
  # The same windows have the same numbers for every subject, and different
  # windows of one subject differ
  expect_equal(grpid_text(o_nca), rep(c("I01", "I02"), each = 2, times = 2))
  # A window that only the second subject has is the first of that subject
  o_nca$result <- o_nca$result[!(o_nca$result$subject == 2 & o_nca$result$end == 2), ]
  ret <- as.data.frame(o_nca, out_format = "cdisc")
  ret <- ret[order(ret$subject, ret$end, ret$PPTESTCD), ]
  expect_equal(ret$subject, rep(1:2, times = c(4, 2)))
  expect_equal(ret$PPGRPID, c("I01", "I01", "I02", "I02", "I01", "I01"))
})

test_that("an interval without rows in the results has no number", {
  o_nca <- grpid_results(periods = 1)
  o_nca$result <- o_nca$result[o_nca$result$end != 2, ]
  expect_equal(grpid_text(o_nca), c("I01", "I01"))
})

test_that("sparse results are numbered by their groups", {
  d_sparse <-
    data.frame(
      id = rep(1:8, 2), trt = rep(c("A", "B"), each = 8),
      time = rep(rep(c(0, 1, 2, 4), each = 2), 2) + rep(c(0, 24), each = 8),
      conc = rep(c(0, 0, 2, 3, 1, 1.5, 0.4, 0.6), 2)
    )
  o_nca <-
    suppressMessages(pk.nca(
      PKNCAdata(
        PKNCAconc(d_sparse, conc ~ time | trt + id, sparse = TRUE),
        PKNCAdose(data.frame(trt = c("A", "B"), time = c(0, 24), dose = 10), dose ~ time | trt),
        intervals = data.frame(trt = c("A", "B"), start = c(0, 24), end = c(4, 28), auclast = TRUE)
      )
    ))
  ret <- as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(trt = "T"))
  expect_equal(unique(ret[, c("trt", "PPGRPID")]), data.frame(trt = c("A", "B"), PPGRPID = c("TA.I01", "TB.I01")), ignore_attr = TRUE)
  # trt is not in the numbering without grpid_cols, so the two windows of the
  # study are the first and second
  ret_no_cols <- as.data.frame(o_nca, out_format = "cdisc")
  expect_equal(unique(ret_no_cols[, c("trt", "PPGRPID")]), data.frame(trt = c("A", "B"), PPGRPID = c("I01", "I02")), ignore_attr = TRUE)
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

test_that("grpid_numeric of PKNCAdata is the default and as.data.frame overrides it", {
  o_nca <-
    grpid_results(
      periods = c("01", "02"),
      grpid_cols = c(Part = "", Period = "P"),
      grpid_numeric = "Period"
    )
  expect_equal(o_nca$data$grpid_numeric, "Period")
  expect_equal(
    grpid_text(o_nca),
    c("A.P1.I01", "A.P1.I01", "A.P1.I02", "A.P1.I02", "A.P2.I01", "A.P2.I01", "A.P2.I02", "A.P2.I02")
  )
  # character() turns the default off, so the text is kept as it is
  expect_equal(
    grpid_text(o_nca, grpid_numeric = character()),
    rep(c("A.P01.I01", "A.P01.I02", "A.P02.I01", "A.P02.I02"), each = 2)
  )
  # The default applies to the columns that are in use
  expect_equal(
    grpid_text(o_nca, grpid_cols = c(Part = "S")),
    rep(c("SA.I01", "SA.I02"), each = 2, times = 2)
  )
  expect_equal(
    grpid_text(o_nca, grpid_cols = c(Period = "Q")),
    rep(c("Q1.I01", "Q1.I02", "Q2.I01", "Q2.I02"), each = 2)
  )
  # An explicit value must be in the grpid_cols that are in use
  expect_error(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Part = ""), grpid_numeric = "Period"),
    class = "pknca_error_grpid_numeric_invalid"
  )
  # Without a default, the PKNCAdata object has none
  expect_null(grpid_results(periods = 1)$data$grpid_numeric)
})

test_that("PKNCAdata checks grpid_numeric against grpid_cols", {
  expect_error(
    grpid_results(grpid_cols = c(Part = ""), grpid_numeric = "Period"),
    class = "pknca_error_grpid_numeric_invalid"
  )
  expect_error(
    grpid_results(grpid_numeric = "Period"),
    class = "pknca_error_grpid_numeric_invalid"
  )
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

test_that("numbers are written in full, without an exponent", {
  expect_equal(pknca_grpid_value_text(c(100000, 2), col = "Period", numeric = FALSE), c("100000", "2"))
  expect_equal(pknca_grpid_value_text(c(100000, 2), col = "Period", numeric = TRUE), c("100000", "2"))
  o_nca <- grpid_results(periods = c(100000, 1), windows = list(c(0, 4)))
  expect_equal(
    grpid_text(o_nca, grpid_cols = c(Period = "P")),
    rep(c("P1.I01", "P100000.I01"), each = 2)
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
  # The message lists only the offending values
  o_nca <- grpid_results(periods = c("1", "2", "x"))
  expect_error(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Period = "P"), grpid_numeric = "Period"),
    class = "pknca_error_grpid_numeric_invalid",
    regexp = "Period.*: \"x\"$"
  )
  expect_equal(pknca_grpid_value_text(c("01", "02", "01"), col = "Period", numeric = TRUE), c("1", "2", "1"))
  expect_equal(pknca_grpid_value_text(c(3, 10), col = "Period", numeric = TRUE), c("3", "10"))
})

test_that("two values that give the same text are an error", {
  # Two spellings of one number cannot be told apart
  o_nca <- grpid_results(periods = c("01", "1"))
  expect_error(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Period = "P"), grpid_numeric = "Period"),
    class = "pknca_error_grpid_value_collision",
    regexp = "Period.*same group identifier text: 1"
  )
  # Without grpid_numeric they are different texts
  expect_equal(
    grpid_text(o_nca, grpid_cols = c(Period = "P"))[c(1, 5)],
    c("P01.I01", "P1.I01")
  )
})

test_that("grpid values with the separator or without text are errors", {
  o_nca <- grpid_results(parts = c("A", "B.1"), periods = 1)
  expect_error(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Part = "")),
    class = "pknca_error_grpid_value_invalid",
    regexp = "Part.*'\\.'.*\"B\\.1\""
  )
  o_nca_empty <- grpid_results(parts = c("A", ""), periods = 1)
  expect_error(
    as.data.frame(o_nca_empty, out_format = "cdisc", grpid_cols = c(Part = "")),
    class = "pknca_error_grpid_value_invalid",
    regexp = "Part.*empty.*\"A\", \"\""
  )
  # A missing value in a text column
  o_nca_na <- grpid_results(periods = 1)
  o_nca_na$result$Part[1] <- NA
  expect_error(
    as.data.frame(o_nca_na, out_format = "cdisc", grpid_cols = c(Part = "")),
    class = "pknca_error_grpid_value_invalid",
    regexp = "Part.*missing.*NA, \"A\""
  )
  # The separator is not allowed in the prefix either, and the message says
  # which column and prefix
  expect_error(
    as.data.frame(grpid_results(periods = 1), out_format = "cdisc", grpid_cols = c(Period = "P.")),
    class = "pknca_error_grpid_cols_invalid",
    regexp = "column 'Period' has 'P\\.'"
  )
})

test_that("a factor column is written as its labels", {
  o_nca <- grpid_results(parts = c("A", "B"), periods = 1)
  o_nca$result$Part <- factor(o_nca$result$Part, levels = c("B", "A"))
  expect_equal(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Part = "S"))$PPGRPID,
    paste0("S", o_nca$result$Part, ".I0", ifelse(o_nca$result$end == 2, 1, 2))
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
  bad <-
    list(
      list(1, "not numeric"),
      list(list(Part = "A"), "not list"),
      list("P", "names are: none"),
      list(c("P", "Q"), "names are: none"),
      list(c(Part = "A", "Q"), "names are: 'Part', ''"),
      list(c(Part = "A", Part = "B"), "repeated: Part"),
      list(c(Part = NA_character_), "missing value.*: Part")
    )
  for (current in bad) {
    expect_error(
      assert_grpid_cols(current[[1]], o_conc),
      class = "pknca_error_grpid_cols_invalid",
      info = current[[2]]
    )
  }
  expect_error(assert_grpid_cols(1, o_conc), regexp = "not numeric")
  expect_error(assert_grpid_cols(list(Part = "A"), o_conc), regexp = "not list")
  expect_error(assert_grpid_cols(c(Part = "A", Part = "B"), o_conc), regexp = "repeated: Part")
  expect_error(
    assert_grpid_cols(c(Part = "", Period = NA_character_), o_conc),
    regexp = "missing value.*: Period"
  )
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
  # A missing group value is its own group, not the text "NA"
  data_na <- data.frame(g = c(NA, "NA"), start = c(0, 1), end = 2)
  expect_equal(pknca_interval_number(data_na, "g"), c(1L, 1L))
  expect_equal(pknca_interval_number(data.frame(g = "NA", start = c(0, 1), end = 2), "g"), 1:2)
  # Windows that differ in the last digits are different windows
  expect_equal(
    pknca_interval_number(data.frame(g = "a", start = c(0, 1e-12), end = 1), "g"),
    1:2
  )
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

test_that("excluded and unrequested rows do not change the numbers or the width", {
  windows <- lapply(0:99, function(i) c(i, i + 2))
  o_nca <- grpid_results(periods = 1, windows = windows)
  # Only the last three intervals are left, and they keep their numbers and
  # the three digits of the 100 intervals
  o_nca$result$exclude[o_nca$result$start < 97] <- "excluded for the test"
  ret <- as.data.frame(o_nca, out_format = "cdisc", filter_excluded = TRUE)
  ret <- ret[order(ret$start, ret$PPTESTCD), ]
  expect_equal(ret$start, rep(97:99, each = 2))
  expect_equal(ret$PPGRPID, rep(c("I098", "I099", "I100"), each = 2))
  # Intervals that are not requested are not in the output, and the rest keep
  # their numbers
  o_nca_requested <- grpid_results(periods = 1)
  o_nca_requested$data$intervals$cmax[o_nca_requested$data$intervals$end == 2] <- FALSE
  o_nca_requested$data$intervals$tmax[o_nca_requested$data$intervals$end == 2] <- FALSE
  ret_requested <- as.data.frame(o_nca_requested, out_format = "cdisc", filter_requested = TRUE)
  expect_equal(unique(ret_requested$end), 4)
  expect_equal(ret_requested$PPGRPID, c("I02", "I02"))
  # A bad value in an excluded row is still an error
  o_nca_bad <- grpid_results(parts = c("A", "B.1"), periods = 1)
  o_nca_bad$result$exclude[o_nca_bad$result$Part %in% "B.1"] <- "excluded for the test"
  expect_error(
    as.data.frame(o_nca_bad, out_format = "cdisc", grpid_cols = c(Part = ""), filter_excluded = TRUE),
    class = "pknca_error_grpid_value_invalid"
  )
})

test_that("an output without rows has a PPGRPID column without rows", {
  o_nca <- grpid_results(periods = 1)
  o_nca$data$intervals$cmax <- FALSE
  o_nca$data$intervals$tmax <- FALSE
  for (grpid_cols in list(NULL, c(Part = "", Period = "P"))) {
    ret <- as.data.frame(o_nca, out_format = "cdisc", filter_requested = TRUE, grpid_cols = grpid_cols)
    expect_equal(nrow(ret), 0)
    expect_equal(ret$PPGRPID, character())
  }
  # The arguments are still checked
  expect_error(
    as.data.frame(o_nca, out_format = "cdisc", filter_requested = TRUE, grpid_cols = c(subject = "S")),
    class = "pknca_error_grpid_cols_subject_analyte"
  )
  # Results without rows
  o_nca$result <- o_nca$result[0, ]
  expect_equal(as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Part = ""))$PPGRPID, character())
})
