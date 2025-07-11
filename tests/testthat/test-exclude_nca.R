test_that("exclude_nca", {
  my_conc <- PKNCAconc(data.frame(conc=c(1.1^(3:0), 1.1), time=0:4, subject=1), conc~time|subject)
  my_data <- PKNCAdata(my_conc, intervals=data.frame(start=0, end=Inf, aucinf.obs=TRUE, aucpext.obs=TRUE))
  suppressMessages(
    my_result <- pk.nca(my_data)
  )

  my_result_excluded <- exclude(my_result, FUN=exclude_nca_max.aucinf.pext())
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, nrow(my_result_excluded$result)-2),
                 rep("aucpext > 20", 2)))

  my_result_excluded <- exclude(my_result, FUN=exclude_nca_max.aucinf.pext(50))
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, nrow(my_result_excluded$result)-2),
                 rep("aucpext > 50", 2)))

  my_result_excluded <- exclude(my_result, FUN=exclude_nca_span.ratio())
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("span.ratio < 2", 11)))
  my_result_excluded <- exclude(my_result, FUN=exclude_nca_span.ratio(1))
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("span.ratio < 1", 11)))

  my_result_excluded <- exclude(my_result, FUN=exclude_nca_min.hl.r.squared())
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("r.squared < 0.9", 11)))
  my_result_excluded <- exclude(my_result, FUN=exclude_nca_min.hl.r.squared(0.95))
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("r.squared < 0.95", 11)))

  my_result_excluded <- exclude(my_result, FUN=exclude_nca_min.hl.adj.r.squared())
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("adj.r.squared < 0.9", 11)))
  my_result_excluded <- exclude(my_result, FUN=exclude_nca_min.hl.adj.r.squared(0.95))
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("adj.r.squared < 0.95", 11)))

  my_data <- PKNCAdata(my_conc, intervals=data.frame(start=0, end=Inf, cmax=TRUE))
  suppressMessages(
    my_result <- pk.nca(my_data)
  )
  expect_equal(my_result,
               exclude(my_result, FUN=exclude_nca_max.aucinf.pext()),
               info="Result is ignored when not calculated")
  expect_equal(my_result,
               exclude(my_result, FUN=exclude_nca_span.ratio()),
               info="Result is ignored when not calculated")
  expect_equal(my_result,
               exclude(my_result, FUN=exclude_nca_min.hl.r.squared()),
               info="Result is ignored when not calculated")
  expect_equal(my_result,
               exclude(my_result, FUN=exclude_nca_min.hl.adj.r.squared()),
               info="Result is ignored when not calculated")
})

test_that("exclude_nca_max.aucinf.pext", {
  my_conc <- PKNCAconc(data.frame(conc=c(1.1^(3:0), 1.1), time=0:4, subject=1), conc~time|subject)
  my_data <- PKNCAdata(my_conc, intervals=data.frame(start=0, end=Inf, aucpext.pred=TRUE, aucpext.obs=TRUE))
  suppressMessages(
    my_result <- pk.nca(my_data)
  )
  expect_equal(
    as.data.frame(my_result)$exclude,
    rep(NA_character_, nrow(as.data.frame(my_result)))
  )
  my_result_exclude_20 <- exclude(my_result, FUN = exclude_nca_max.aucinf.pext(max.aucinf.pext = 20))
  expect_equal(
    as.data.frame(my_result_exclude_20)$exclude,
    c(rep(NA_character_, nrow(as.data.frame(my_result_exclude_20))-4), rep("aucpext > 20", 4))
  )
  my_result_exclude_50 <- exclude(my_result, FUN = exclude_nca_max.aucinf.pext(max.aucinf.pext = 50))
  expect_equal(
    as.data.frame(my_result_exclude_50)$exclude,
    c(rep(NA_character_, nrow(as.data.frame(my_result_exclude_50))-4), rep("aucpext > 50", 4))
  )
})

test_that("exclude_nca_count_conc_measured", {
  my_conc <- PKNCAconc(data.frame(conc=c(1.1^(c(3:0, -Inf)), 1.1), time=0:5, subject = 1), conc~time|subject)
  my_data <- PKNCAdata(my_conc, intervals=data.frame(start=0, end=Inf, aucinf.obs=TRUE, aucpext.obs=TRUE, count_conc_measured = TRUE))
  suppressMessages(
    my_result <- pk.nca(my_data)
  )
  expect_equal(
    as.data.frame(my_result)$exclude,
    rep(NA_character_, 16)
  )
  my_result_exclude5 <- exclude(my_result, FUN = exclude_nca_count_conc_measured(min_count = 5))
  expect_equal(
    as.data.frame(my_result_exclude5)$exclude,
    rep(NA_character_, 16)
  )
  my_result_exclude10 <- exclude(my_result, FUN = exclude_nca_count_conc_measured(min_count = 10))
  expect_equal(
    as.data.frame(my_result_exclude10)$exclude,
    c("count_conc_measured < 10", rep(NA_character_, 13), rep("count_conc_measured < 10", 2))
  )
})

test_that("exclude_nca_tmax_early", {
  my_conc <- PKNCAconc(data.frame(conc=c(1.1^(c(3:0, -Inf)), 1.1), time=0:5, subject = 1), conc~time|subject)
  my_data <- PKNCAdata(my_conc, intervals=data.frame(start=0, end=Inf, auclast = TRUE, half.life = TRUE))
  suppressMessages(
    my_result <- pk.nca(my_data)
  )
  expect_equal(
    as.data.frame(my_result)$exclude,
    rep(NA_character_, nrow(as.data.frame(my_result)))
  )
  my_result_exclude_1 <- exclude(my_result, FUN = exclude_nca_tmax_early(tmax_early = 1))
  expect_equal(
    as.data.frame(my_result_exclude_1)$exclude,
    rep("tmax < 1 (likely missed dose, insufficient PK samples, or PK sample swap)", nrow(as.data.frame(my_result_exclude_1)))
  )
  my_result_exclude_0 <- exclude(my_result, FUN = exclude_nca_tmax_0())
  expect_equal(
    as.data.frame(my_result_exclude_0)$exclude,
    rep("tmax <= 0 (likely missed dose, insufficient PK samples, or PK sample swap)", nrow(as.data.frame(my_result_exclude_0)))
  )
  # This should never happen in real code
  expect_error(
    exclude_nca_tmax_early()(data.frame(PPTESTCD = "tmax", PPORRES = 1:2)),
    regexp = "Should not see more than one tmax (please report this as a bug)",
    fixed = TRUE
  )
})

test_that("exclude_nca_by_param works as expected", {
  # Define the input
  my_conc <- PKNCAconc(data.frame(conc=c(1.1^(3:0), 1.1), time=0:4, subject=1), conc~time|subject)
  my_data <- PKNCAdata(my_conc, intervals=data.frame(start=0, end=Inf, span.ratio=TRUE))
  suppressMessages(
    my_result <- pk.nca(my_data)
  )

  # excludes rows based on min_thr
  res_min_excluded <- PKNCA::exclude(
    my_result,
    FUN = exclude_nca_by_param("span.ratio", min_thr = 100)
  )
  expect_equal(
    as.data.frame(res_min_excluded)$exclude,
    c(rep(NA, 10), "span.ratio < 100")
  )

  # does not exclude rows when min_thr is not met
  res_min_not_excluded <- PKNCA::exclude(
    my_result,
    FUN = exclude_nca_by_param("span.ratio", min_thr = 0.01)
  )
  expect_equal(
    as.data.frame(res_min_not_excluded)$exclude,
    rep(NA_character_, 11)
  )

  # excludes rows based on max_thr
  res_max_excluded <- PKNCA::exclude(
    my_result,
    FUN = exclude_nca_by_param("span.ratio", max_thr = 0.01)
  )
  expect_equal(
    as.data.frame(res_max_excluded)$exclude,
    c(rep(NA, 10), "span.ratio > 0.01")
  )

  # does not exclude rows when max_thr is not exceeded
  res_max_not_excluded <- PKNCA::exclude(
    my_result,
    FUN = exclude_nca_by_param("span.ratio", max_thr = 100)
  )
  expect_equal(
    as.data.frame(res_max_not_excluded)$exclude,
    rep(NA_character_, 11)
  )

  # throws an error for invalid min_thr
  expect_error(
    exclude_nca_by_param("span.ratio", min_thr = "invalid"),
    "Check on 'min_thr' failed: Must be of type 'number'"
  )

  # throws an error for invalid max_thr
  expect_error(
    exclude_nca_by_param(parameter = "span.ratio", max_thr = c(1, 2)),
    "Check on 'max_thr' failed: Must have length 1"
  )

  # throws an error when min_thr is greater than max_thr
  expect_error(
    exclude_nca_by_param("span.ratio", min_thr = 10, max_thr = 5),
    "if both defined min_thr must be less than max_thr"
  )

  # returns the original object when the parameter is not found
  res <- PKNCA::exclude(my_result, FUN = exclude_nca_by_param("nonexistent", min_thr = 0))
  expect_true(all(is.na(as.data.frame(res)$exclude)))

  # returns the object when the parameter's value is NA
  my_result_na <- my_result
  my_result_na$result$PPORRES <- NA
  res <- PKNCA::exclude(
    my_result_na,
    FUN = exclude_nca_by_param("span.ratio", min_thr = 0)
  )
  expect_true(all(is.na(as.data.frame(res)$exclude)))

  # marks records associated with the affected_parameters
  res <- PKNCA::exclude(
    my_result,
    FUN = exclude_nca_by_param(
      "span.ratio", min_thr = 0.01, affected_parameters = c("lambda.z", "span.ratio")
    )
  )
  # All span.ratio records should be NA (not excluded)
  expect_true(all(is.na(as.data.frame(res)$exclude[res$result$PPTESTCD == "span.ratio"])))
  expect_true(all(is.na(as.data.frame(res)$exclude[res$result$PPTESTCD == "lambda.z"])))

  # produces an error when more than 1 PPORRES is per parameter (should never happen in real code)
  expect_error(
    exclude_nca_by_param(
      param = "r.squared",
      min_thr = 0.7
    )(data.frame(PPTESTCD = "r.squared", PPORRES = c(1, 1))),
    regexp = "Should not see more than one r.squared (please report this as a bug)",
    fixed = TRUE
  )
})
