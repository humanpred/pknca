test_that("assert_intervals works with valid intervals", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  
  result <- assert_intervals(intervals = data.frame(start = 0, end = 1, cmax = TRUE), data = o_data)
  expect_equal(result, expected = data.frame(start = 0, end = 1, cmax = TRUE))
})

test_that("assert_intervals works with valid intervals (ungrouped)", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph)[datasets::Theoph$Subject == 1,], conc~Time)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  
  result <- assert_intervals(intervals = data.frame(start = 0, end = 1, cmax = TRUE), data = o_data)
  expect_equal(result, expected = data.frame(start = 0, end = 1, cmax = TRUE))
})

test_that("assert_intervals errors with non-data frame intervals", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  non_df_intervals <- list(a = 1, b = 2)
  
  expect_error(assert_intervals(non_df_intervals, data = o_data), 
               regex = "Must be of type 'data.frame'",
               fixed = TRUE)
})

test_that("assert_intervals errors with non-data frame intervals (ungrouped)", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph)[datasets::Theoph$Subject == 1,], conc~Time)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  non_df_intervals <- list(a = 1, b = 2)
  
  expect_error(assert_intervals(intervals = non_df_intervals, data = o_data), 
               regex = "Must be of type 'data.frame'",
               fixed = TRUE)
})

test_that("assert_intervals errors with non-PKNCAdata data object", {
  expect_error(assert_intervals(intervals = data.frame(start = 0, end = 1, cmax = TRUE), 
                                data = data.frame(a = 1, b = 2)),
               regex = "Must inherit from class 'PKNCAdata'",
               fixed = TRUE)
})

test_that("assert_intervals errors with invalid columns", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  
  invalid_intervals <- data.frame(
    mean = TRUE,  # Not allowed NCA params
    median = TRUE
  )
  
  expect_error(assert_intervals(intervals = invalid_intervals, data = o_data), 
               regex = "The following columns in 'intervals' are not allowed:",
               fixed = TRUE)
})

test_that("assert_intervals errors with invalid columns", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph)[datasets::Theoph$Subject == 1,], conc~Time)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  
  invalid_intervals <- data.frame(
    mean = TRUE,  # Not allowed NCA params
    median = TRUE
  )
  
  expect_error(assert_intervals(intervals = invalid_intervals, data = o_data), 
               regex = "The following columns in 'intervals' are not allowed:",
               fixed = TRUE)
})

test_that("set_intervals works with valid intervals", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  
  result <- set_intervals(data = o_data, intervals = data.frame(start = 0, end = 1, cmin = TRUE))
  
  expect_equal(result$intervals, data.frame(start = 0, end = 1, cmin = TRUE))
})

test_that("set_intervals works with valid intervals (ungrouped)", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph)[datasets::Theoph$Subject == 1,], conc~Time)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  
  result <- set_intervals(data = o_data, intervals = data.frame(start = 0, end = 1, cmin = TRUE))
  
  expect_equal(result$intervals, data.frame(start = 0, end = 1, cmin = TRUE))
})

test_that("set_intervals fails with invalid intervals", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  
  expect_error(set_intervals(data = o_data, intervals = data.frame(start = 0, end = 1, cmedian = TRUE)), 
               regex = "The following columns in 'intervals' are not allowed:",
               fixed = TRUE)
})

test_that("set_intervals fails when not using PKNCAdata", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  
  expect_error(set_intervals(data = o_conc, intervals = data.frame(start = 0, end = 1, cmin = TRUE)), 
               regex = "Must inherit from class 'PKNCAdata'")
})

test_that("assert_intervals allows a tau column for multiple-dose parameters", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  intervals <- data.frame(start = 0, end = 24, tau = 24, mrt.md.obs = TRUE)

  expect_equal(assert_intervals(intervals = intervals, data = o_data), expected = intervals)
})

test_that("assert_intervals points a renamed parameter at its new name", {
  o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  err <-
    expect_error(
      assert_intervals(
        intervals = data.frame(start = 0, end = 24, f = TRUE),
        data = o_data
      ),
      class = "pknca_error_invalid_interval_columns"
    )
  expect_match(conditionMessage(err), "'f' is now named 'f.obs'", fixed = TRUE)
})

test_that("assert_intervals refuses a sparse-only parameter for dense data", {
  d_conc <- data.frame(id = 1L, conc = c(0, 2, 1, 0.5), time = c(0, 1, 2, 4))
  o_data_dense <- PKNCAdata(PKNCAconc(d_conc, conc~time|id), intervals = data.frame(start = 0, end = 4, cmax = TRUE))
  expect_error(
    assert_intervals(data.frame(start = 0, end = 4, auclast_se = TRUE, auclast_df = TRUE), o_data_dense),
    regexp = "These parameters are only calculated for sparse PK.*auclast_se, auclast_df",
    class = "pknca_error_sparse_only_parameter"
  )
  # Requesting it as FALSE is not a request
  expect_no_error(
    assert_intervals(data.frame(start = 0, end = 4, cmax = TRUE, auclast_se = FALSE), o_data_dense)
  )

  d_sparse <- data.frame(id = 1:8, conc = c(0, 0, 2, 3, 1, 1.5, 0.4, 0.6), time = rep(c(0, 1, 2, 4), each = 2))
  o_data_sparse <-
    PKNCAdata(
      PKNCAconc(d_sparse, conc~time|id, sparse = TRUE),
      intervals = data.frame(start = 0, end = 4, cmax = TRUE)
    )
  expect_no_error(
    assert_intervals(data.frame(start = 0, end = 4, auclast_se = TRUE), o_data_sparse)
  )
})

test_that("the conflicting interval_ids are named, at most five", {
  intervals_many <-
    data.frame(
      interval_id = rep(letters[1:6], each = 2),
      start = 0, end = rep(c(24, 48), times = 6), cmax = TRUE
    )
  expect_error(
    check.interval.specification(intervals_many),
    class = "pknca_error_secondary_id_conflict",
    regexp = "'a', 'b', 'c', 'd', 'e', ... must describe",
    fixed = TRUE
  )
  expect_error(
    check.interval.specification(intervals_many[1:10, ]),
    class = "pknca_error_secondary_id_conflict",
    regexp = "'a', 'b', 'c', 'd', 'e' must describe",
    fixed = TRUE
  )
})

test_that("rows of one interval may point at different references", {
  intervals_pointers <-
    data.frame(
      interval_id = c("a", "a", "r1", "r2"),
      start = c(0, 0, 100, 150), end = c(24, 24, 124, 174),
      cmax = TRUE, ratio.cmax = c(TRUE, TRUE, FALSE, FALSE),
      ratio.cmax_ref = c("r1", "r2", NA, NA)
    )
  expect_no_error(check.interval.specification(intervals_pointers))
  expect_identical(
    check.interval.specification(intervals_pointers)$ratio.cmax_ref,
    c("r1", "r2", NA, NA)
  )
  # The same id with another window is still a conflict
  intervals_pointers$end[2] <- 48
  expect_error(
    check.interval.specification(intervals_pointers),
    class = "pknca_error_secondary_id_conflict"
  )
})

test_that("one interval_id identifies one interval in every entry point", {
  d_conc <- data.frame(id = 1L, conc = c(0, 2, 1, 0.5), time = c(0, 1, 2, 4))
  o_conc <- PKNCAconc(d_conc, conc~time|id)
  intervals_ok <- data.frame(start = 0, end = 4, cmax = TRUE)
  o_data <- PKNCAdata(o_conc, intervals = intervals_ok)
  # The id is reused for a different window
  intervals_reused <-
    data.frame(interval_id = "a", start = c(0, 2), end = c(2, 4), cmax = TRUE)
  expect_error(
    assert_intervals(intervals_reused, o_data),
    class = "pknca_error_secondary_id_conflict",
    regexp = "'a'"
  )
  expect_error(
    set_intervals(o_data, intervals_reused),
    class = "pknca_error_secondary_id_conflict"
  )
  expect_error(
    PKNCAdata(o_conc, intervals = intervals_reused),
    class = "pknca_error_secondary_id_conflict"
  )
  o_data_reused <- o_data
  o_data_reused$intervals <- intervals_reused
  expect_error(
    pk.nca(o_data_reused),
    class = "pknca_error_secondary_id_conflict"
  )
  # ... and for a different group
  d_conc_groups <- data.frame(id = rep(1:2, each = 3), conc = c(0, 2, 1, 0, 3, 1), time = rep(c(0, 1, 2), 2))
  o_data_groups <- PKNCAdata(PKNCAconc(d_conc_groups, conc~time|id), intervals = data.frame(start = 0, end = 2, cmax = TRUE))
  expect_error(
    assert_intervals(
      data.frame(interval_id = "a", id = 1:2, start = 0, end = 2, cmax = TRUE),
      o_data_groups
    ),
    class = "pknca_error_secondary_id_conflict"
  )
  # Rows of one interval, which differ only in what they calculate or impute,
  # share an id, and distinct intervals have distinct ids
  intervals_split <-
    data.frame(
      interval_id = c("a", "a", "b", NA), start = c(0, 0, 2, 2), end = c(2, 2, 4, 4),
      cmax = c(TRUE, FALSE, TRUE, TRUE), cmin = c(FALSE, TRUE, FALSE, FALSE)
    )
  expect_identical(assert_intervals(intervals_split, o_data), intervals_split)
  expect_s3_class(PKNCAdata(o_conc, intervals = intervals_split), "PKNCAdata")
})

test_that("assert_intervals allows the column that the impute setting names", {
  d_conc <- data.frame(subject = 1, time = c(0, 1, 2), conc = c(0, 2, 1))
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 2, cmax = TRUE))
  intervals <- data.frame(start = 0, end = 2, cmax = TRUE, my_impute = "start_conc0")
  # The column is not allowed unless the setting names it
  expect_error(
    assert_intervals(intervals, o_data),
    class = "pknca_error_invalid_interval_columns",
    regexp = "my_impute"
  )
  o_data$impute <- "my_impute"
  expect_identical(assert_intervals(intervals, o_data), intervals)
  expect_identical(set_intervals(o_data, intervals)$intervals, intervals)
  # Only the column that is named is allowed
  expect_error(
    assert_intervals(cbind(intervals, other = "x"), o_data),
    class = "pknca_error_invalid_interval_columns",
    regexp = "other"
  )
  # The named column must be character, whatever its name
  intervals_numeric <- intervals
  intervals_numeric$my_impute <- 1
  expect_error(
    assert_intervals(intervals_numeric, o_data),
    class = "pknca_error_interval_impute_not_character",
    regexp = "my_impute"
  )
  expect_error(
    PKNCAdata(o_conc, intervals = intervals_numeric, impute = "my_impute"),
    class = "pknca_error_interval_impute_not_character"
  )
  intervals_factor <- intervals
  intervals_factor$my_impute <- factor("start_conc0")
  expect_error(
    assert_intervals(intervals_factor, o_data),
    class = "pknca_error_interval_impute_not_character",
    regexp = "my_impute"
  )
  # A column of only NA is no imputation, whatever its type and name
  for (empty in list(NA, NA_character_)) {
    intervals_empty <- intervals
    intervals_empty$my_impute <- empty
    expect_identical(assert_intervals(intervals_empty, o_data), intervals_empty)
  }
  # The generic column is held to the same rule when it is the one read
  o_data$impute <- NA_character_
  expect_error(
    assert_intervals(data.frame(start = 0, end = 2, cmax = TRUE, impute = 1), o_data),
    class = "pknca_error_interval_impute_not_character",
    regexp = "'impute'"
  )
  for (empty in list(NA, NA_character_)) {
    intervals_empty <- data.frame(start = 0, end = 2, cmax = TRUE, impute = empty)
    expect_identical(assert_intervals(intervals_empty, o_data), intervals_empty)
    expect_s3_class(PKNCAdata(o_conc, intervals = intervals_empty), "PKNCAdata")
  }
  # The default setting and the method-string setting still allow only "impute"
  expect_identical(
    assert_intervals(data.frame(start = 0, end = 2, cmax = TRUE, impute = "start_conc0"), o_data),
    data.frame(start = 0, end = 2, cmax = TRUE, impute = "start_conc0")
  )
  o_data$impute <- "start_conc0"
  expect_error(
    assert_intervals(intervals, o_data),
    class = "pknca_error_invalid_interval_columns",
    regexp = "my_impute"
  )
})

test_that("rows sharing an interval_id may differ in the named impute column", {
  d_conc <- data.frame(subject = 1, time = c(0, 1, 2), conc = c(0, 2, 1))
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  intervals <-
    data.frame(
      interval_id = "a", start = 0, end = 2, cmax = c(TRUE, FALSE), cmin = c(FALSE, TRUE),
      my_impute = c("start_conc0", "start_predose")
    )
  expect_s3_class(PKNCAdata(o_conc, intervals = intervals, impute = "my_impute"), "PKNCAdata")
  expect_error(
    PKNCAdata(o_conc, intervals = intervals, impute = "other_name"),
    class = "pknca_error_invalid_interval_columns"
  )
  expect_error(
    check.interval.specification(intervals),
    class = "pknca_error_secondary_id_conflict"
  )
  expect_identical(
    check.interval.specification(intervals, impute = "my_impute")[, names(intervals)],
    intervals
  )
})
