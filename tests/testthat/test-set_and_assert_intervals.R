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
