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
                 rep("span.ratio < 2", 12)))
  my_result_excluded <- exclude(my_result, FUN=exclude_nca_span.ratio(1))
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("span.ratio < 1", 12)))

  my_result_excluded <- exclude(my_result, FUN=exclude_nca_min.hl.r.squared())
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("r.squared < 0.9", 12)))
  my_result_excluded <- exclude(my_result, FUN=exclude_nca_min.hl.r.squared(0.95))
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("r.squared < 0.95", 12)))

  my_result_excluded <- exclude(my_result, FUN=exclude_nca_min.hl.adj.r.squared())
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("adj.r.squared < 0.9", 12)))
  my_result_excluded <- exclude(my_result, FUN=exclude_nca_min.hl.adj.r.squared(0.95))
  expect_equal(as.data.frame(my_result_excluded)$exclude,
               c(rep(NA_character_, 4),
                 rep("adj.r.squared < 0.95", 12)))

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
    rep(NA_character_, 17)
  )
  my_result_exclude5 <- exclude(my_result, FUN = exclude_nca_count_conc_measured(min_count = 5))
  expect_equal(
    as.data.frame(my_result_exclude5)$exclude,
    rep(NA_character_, 17)
  )
  my_result_exclude10 <- exclude(my_result, FUN = exclude_nca_count_conc_measured(min_count = 10))
  expect_equal(
    as.data.frame(my_result_exclude10)$exclude,
    c("count_conc_measured < 10", rep(NA_character_, 14), rep("count_conc_measured < 10", 2))
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
    c(rep(NA, 11), "span.ratio < 100")
  )

  # does not exclude rows when min_thr is not met
  res_min_not_excluded <- PKNCA::exclude(
    my_result,
    FUN = exclude_nca_by_param("span.ratio", min_thr = 0.01)
  )
  expect_equal(
    as.data.frame(res_min_not_excluded)$exclude,
    rep(NA_character_, 12)
  )

  # excludes rows based on max_thr
  res_max_excluded <- PKNCA::exclude(
    my_result,
    FUN = exclude_nca_by_param("span.ratio", max_thr = 0.01)
  )
  expect_equal(
    as.data.frame(res_max_excluded)$exclude,
    c(rep(NA, 11), "span.ratio > 0.01")
  )

  # does not exclude rows when max_thr is not exceeded
  res_max_not_excluded <- PKNCA::exclude(
    my_result,
    FUN = exclude_nca_by_param("span.ratio", max_thr = 100)
  )
  expect_equal(
    as.data.frame(res_max_not_excluded)$exclude,
    rep(NA_character_, 12)
  )

  # throws an error for invalid min_thr
  expect_error(
    exclude_nca_by_param("span.ratio", min_thr = "invalid"),
    "Assertion on 'min_thr' failed: Must be of type 'number'"
  )

  # throws an error for invalid max_thr
  expect_error(
    exclude_nca_by_param(parameter = "span.ratio", max_thr = c(1, 2)),
    "Assertion on 'max_thr' failed: Must have length 1"
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

test_that("a half-life exclusion only reaches an AUCint that used the half-life (#270)", {
  d_conc <-
    data.frame(
      subject = 1,
      time = c(0, 0.5, 1, 2, 4, 8, 12, 24),
      conc = c(0, 8, 10, 7, 4, 2, 1.2, 0.4)
    )
  d_dose <- data.frame(subject = 1, time = 0, dose = 100)
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
  # The first interval ends before tlast (24), so it only interpolates; the
  # second reaches past tlast and has to extrapolate with the half-life.
  intervals <-
    data.frame(
      start = c(0, 0),
      end = c(12, 36),
      aucint.inf.obs = TRUE,
      aucint.inf.pred = TRUE,
      half.life = TRUE,
      span.ratio = TRUE
    )
  o_data <- PKNCAdata(o_conc, o_dose, intervals = intervals)
  my_result <- pk.nca(o_data)
  # The span ratio is well below the threshold, so the half-life is excluded in
  # both intervals
  excluded <- as.data.frame(exclude(my_result, FUN = exclude_nca_span.ratio(min.span.ratio = 5)))
  exclusion <- function(param, interval_end) {
    excluded$exclude[excluded$PPTESTCD %in% param & excluded$end %in% interval_end]
  }
  expect_equal(exclusion("half.life", 12), "span.ratio < 5")
  expect_equal(exclusion("half.life", 36), "span.ratio < 5")
  expect_equal(exclusion("aucint.inf.obs", 12), NA_character_)
  expect_equal(exclusion("aucint.inf.pred", 12), NA_character_)
  expect_equal(exclusion("aucint.inf.obs", 36), "span.ratio < 5")
  expect_equal(exclusion("aucint.inf.pred", 36), "span.ratio < 5")

  # The same split for the other half-life exclusions
  for (FUN in list(exclude_nca_min.hl.r.squared(1), exclude_nca_min.hl.adj.r.squared(1))) {
    excluded <- as.data.frame(exclude(my_result, FUN = FUN))
    expect_true(is.na(exclusion("aucint.inf.obs", 12)))
    expect_false(is.na(exclusion("aucint.inf.obs", 36)))
  }
})

test_that("a result with no extrapolation reported keeps a half-life exclusion (#270)", {
  # aucinf.obs and the rest of the half-life family do not report an
  # extrapolation, so they are excluded with the half-life as they always were
  my_conc <- PKNCAconc(data.frame(conc = c(1.1^(3:0), 1.1), time = 0:4, subject = 1), conc~time|subject)
  my_data <- PKNCAdata(my_conc, intervals = data.frame(start = 0, end = Inf, aucinf.obs = TRUE))
  suppressMessages(my_result <- pk.nca(my_data))
  excluded <- as.data.frame(exclude(my_result, FUN = exclude_nca_span.ratio()))
  expect_equal(
    excluded$exclude[excluded$PPTESTCD %in% "aucinf.obs"],
    "span.ratio < 2"
  )
})

test_that("a half-life exclusion is kept when the method column is not there (#270)", {
  # exclude() always passes the method column, but the returned function is
  # usable on its own, and without the column there is nothing to say that the
  # half-life was unused
  expect_equal(
    exclude_nca_span.ratio(2)(
      data.frame(PPTESTCD = c("span.ratio", "aucint.inf.obs"), PPORRES = c(1, 5))
    ),
    rep("span.ratio < 2", 2)
  )
})

test_that("exclude_nca_by_param() checks thresholds without testthat", {
  # A bad threshold is an ordinary error, not a failed testthat expectation
  err <- tryCatch(exclude_nca_by_param("cmax", min_thr = "a"), error = function(e) e)
  expect_s3_class(err, "error")
  expect_false(inherits(err, "expectation"))
  expect_match(conditionMessage(err), "Assertion on 'min_thr' failed", fixed = TRUE)
})

test_that("exclusion rules do not load testthat", {
  # A separate R session with the installed package, where testthat is not
  # already loaded
  pknca_path <- getNamespaceInfo("PKNCA", "path")
  skip_if(
    dir.exists(file.path(pknca_path, "man")),
    "The installed package is needed (run under R CMD check, not devtools::load_all())"
  )
  code <-
    sprintf(
      "suppressMessages(library(PKNCA, lib.loc = '%s')); invisible(pknca_exclude_rules()); invisible(exclude_nca_by_param('cmax', min_thr = 1)); cat(isNamespaceLoaded('testthat'))",
      normalizePath(dirname(pknca_path), winslash = "/")
    )
  out <- system2(file.path(R.home("bin"), "Rscript"), args = c("-e", shQuote(code)), stdout = TRUE, stderr = TRUE)
  expect_equal(utils::tail(out, 1), "FALSE")
})

# Collect the conditions of one class while evaluating an expression
collect_conditions <- function(expr, class) {
  acc <- new.env(parent = emptyenv())
  acc$conditions <- list()
  value <-
    withCallingHandlers(
      expr,
      condition = function(cnd) {
        if (inherits(cnd, class)) {
          acc$conditions[[length(acc$conditions) + 1]] <- cnd
          if (inherits(cnd, "warning")) invokeRestart("muffleWarning")
          if (inherits(cnd, "message")) invokeRestart("muffleMessage")
        }
      }
    )
  list(value = value, conditions = acc$conditions)
}

# The main fixture's Tmax values 1, 1, 2, 2, 2, and 8 have quartiles 1.25 and
# 2:  the inner fences are 0.125 and 3.125 hours, and the outer fences -1 and
# 4.25 hours
tmax_coverage_reason_nominal <-
  "no sample in the outer Tmax range of the group (nominal time 0 to 4.25 hr after the interval start, nearest sample at 8 hr)"

test_that("exclude_nca_tmax_coverage excludes a subject with no sample within the outer fences and tells of one missing some", {
  o_nca <- tmax_coverage_results()
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "pknca_message_tmax_coverage_partial")
  result <- as.data.frame(collected$value)
  # Every parameter of subject 6, and nothing else, is excluded
  expect_equal(
    result$exclude,
    c(rep(NA_character_, 15), rep(tmax_coverage_reason_nominal, 3))
  )
  expect_equal(result$subject[!is.na(result$exclude)], rep(6, 3))
  # Subject 5 gets a message, once, and is not excluded
  expect_length(collected$conditions, 1)
  partial <- collected$conditions[[1]]
  expect_equal(
    conditionMessage(partial),
    "Cmax and Tmax may be unreliable for start=0, end=24, subject=5:  no usable sample at nominal time 1 hr, within the inner Tmax range of the group (nominal time 0.125 to 3.125 hr after the interval start)"
  )
  expect_equal(partial$group, data.frame(start = 0, end = 24, subject = 5))
  expect_equal(partial$tmax_range, c(0.125, 3.125))
  expect_equal(partial$time_nominal_missing, 1)
  expect_equal(partial$reason, "NA concentration")
})

test_that("exclude_nca_tmax_coverage treats NA concentrations at the nominal times as missing samples", {
  d_conc <- tmax_coverage_conc()
  # Subject 6 gets rows at the nominal times it missed, with NA concentrations
  d_conc <-
    rbind(
      d_conc,
      data.frame(subject = 6, time_nominal = c(0.5, 1, 2, 4), time = c(0.5, 1, 2, 4), conc = NA_real_)
    )
  o_nca <- tmax_coverage_results(d_conc)
  result <- as.data.frame(suppressMessages(exclude(o_nca, FUN = exclude_nca_tmax_coverage())))
  expect_equal(result$exclude[result$subject == 6], rep(tmax_coverage_reason_nominal, 3))
  expect_true(all(is.na(result$exclude[result$subject != 6])))
  missing_samples <- pknca_missing_samples(o_nca)
  expect_equal(missing_samples$reason[missing_samples$subject == 6], rep("NA concentration", 4))
})

test_that("exclude_nca_tmax_coverage treats excluded concentrations as missing samples", {
  d_conc <- tmax_coverage_conc()
  d_conc$excl <- NA_character_
  # Subject 4 has its samples within the Tmax range excluded
  d_conc$excl[d_conc$subject == 4 & d_conc$time_nominal %in% c(0.5, 1, 2)] <- "Swap"
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal", exclude = "excl", timeu = "hr", concu = "ng/mL")
  o_nca <- suppressMessages(pk.nca(PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE))))
  collected <- collect_conditions(suppressWarnings(exclude(o_nca, FUN = exclude_nca_tmax_coverage())), "pknca_message_tmax_coverage_partial")
  outliers <- collect_conditions(suppressMessages(exclude(o_nca, FUN = exclude_nca_tmax_coverage())), "pknca_warning_tmax_coverage_outlier")
  result <- as.data.frame(collected$value)
  # Subject 4 now has Tmax at 4 hours:  the Tmax values 1, 1, 2, 4, 2, and 8
  # have quartiles 1.25 and 3.5, so the inner range is 0 to 6.875 hours and the
  # outer range 0 to 10.25 hours.  Without dose data, the predose sample of
  # subject 6 does not count, and its 8-hour sample is only within the outer
  # range, so it is flagged and not excluded.
  expect_equal(result$PPORRES[result$subject == 4 & result$PPTESTCD == "tmax"], 4)
  expect_true(all(is.na(result$exclude)))
  expect_length(outliers$conditions, 1)
  expect_equal(outliers$conditions[[1]]$group$subject, 6)
  expect_equal(outliers$conditions[[1]]$nearest_sample, 8)
  # Subjects 4 (excluded samples) and 5 (an NA concentration) are missing
  # samples in the inner range
  expect_equal(
    vapply(collected$conditions, function(x) x$group$subject, FUN.VALUE = 1),
    c(4, 5)
  )
  expect_equal(collected$conditions[[1]]$time_nominal_missing, c(0.5, 1, 2))
  expect_equal(collected$conditions[[1]]$reason, rep("excluded", 3))
  expect_match(
    conditionMessage(collected$conditions[[1]]),
    "no usable sample at nominal time 0.5, 1, 2 hr, within the inner Tmax range of the group (nominal time 0 to 6.875 hr after the interval start)",
    fixed = TRUE
  )
})

test_that("exclude_nca_tmax_coverage uses the actual times without nominal times", {
  d_conc <- tmax_coverage_conc()
  d_conc$time <- d_conc$time + 0.05 * (d_conc$time > 0)
  o_nca <- tmax_coverage_results(d_conc, time.nominal = NULL)
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), c("warning", "message"))
  result <- as.data.frame(collected$value)
  expect_equal(
    result$exclude[result$subject == 6],
    rep("no sample in the outer Tmax range of the group (actual time 0 to 4.3 hr after the interval start, nearest sample at 8.05 hr)", 3)
  )
  expect_true(all(is.na(result$exclude[result$subject != 6])))
  # Without a schedule, a subject missing some samples gets no message
  expect_length(collected$conditions, 0)
})

test_that("exclude_nca_tmax_coverage does not check a group with too few subjects", {
  d_conc <- tmax_coverage_conc()
  o_nca <- tmax_coverage_results(d_conc[d_conc$subject %in% c(1, 2, 6), ])
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "pknca_message_tmax_coverage_few_subjects")
  expect_true(all(is.na(as.data.frame(collected$value)$exclude)))
  # One message for the group, not one per subject
  expect_length(collected$conditions, 1)
  expect_equal(
    conditionMessage(collected$conditions[[1]]),
    "Tmax coverage is not checked for start=0, end=24:  3 subject(s) have a Tmax, fewer than the 4 needed (min_subjects)"
  )
  # The group is checked when min_subjects allows it:  the Tmax values 1, 1,
  # and 8 have quartiles 1 and 4.5, so the inner range is 0 to 9.75 hours, and
  # subject 6 has a sample in it but is missing the others
  expect_message(
    result_min3 <- as.data.frame(exclude(o_nca, FUN = exclude_nca_tmax_coverage(min_subjects = 3))),
    regexp = "subject=6:  no usable sample at nominal time 0.5, 1, 2, 4 hr, within the inner Tmax range of the group (nominal time 0 to 9.75 hr after the interval start)",
    fixed = TRUE,
    class = "pknca_message_tmax_coverage_partial"
  )
  expect_true(all(is.na(result_min3$exclude)))
  # A single-subject group is never checked
  o_nca_one <- tmax_coverage_results(d_conc[d_conc$subject == 6, ])
  expect_message(
    result_one <- exclude(o_nca_one, FUN = exclude_nca_tmax_coverage()),
    regexp = "1 subject(s) have a Tmax, fewer than the 4 needed",
    fixed = TRUE,
    class = "pknca_message_tmax_coverage_few_subjects"
  )
  expect_true(all(is.na(as.data.frame(result_one)$exclude)))
  expect_error(exclude_nca_tmax_coverage(min_subjects = 1))
  expect_error(exclude_nca_tmax_coverage(min_subjects = 4.5))
  expect_error(exclude_nca_tmax_coverage(k_warn = -1))
  expect_error(exclude_nca_tmax_coverage(k_warn = 3, k_exclude = 1.5))
})

test_that("exclude_nca_tmax_coverage checks each summary group on its own", {
  d_conc_a <- tmax_coverage_conc()
  d_conc_a$treatment <- "A"
  # In treatment B, every subject has its Tmax at 8 hours, so subject 6 is
  # within the range
  d_conc_b <- d_conc_a[d_conc_a$subject == 6, ]
  d_conc_b <- d_conc_b[rep(seq_len(nrow(d_conc_b)), 4), ]
  d_conc_b$subject <- rep(c(1, 2, 3, 6), each = 3)
  d_conc_b$treatment <- "B"
  o_conc <-
    PKNCAconc(
      rbind(d_conc_a, d_conc_b),
      conc ~ time | treatment + subject,
      time.nominal = "time_nominal", timeu = "hr", concu = "ng/mL"
    )
  o_nca <- suppressMessages(pk.nca(PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE))))
  result <- as.data.frame(suppressMessages(exclude(o_nca, FUN = exclude_nca_tmax_coverage())))
  excluded <- as.data.frame(unique(result[!is.na(result$exclude), c("treatment", "subject")]))
  rownames(excluded) <- NULL
  expect_equal(excluded, data.frame(treatment = "A", subject = 6))
})

test_that("exclude_nca_tmax_coverage warns and does not exclude when no nominal time is in the interval", {
  d_conc <- tmax_coverage_conc()
  # Actual times are a week later, and the nominal times are relative to the
  # dose
  d_conc$time <- d_conc$time + 168
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal", timeu = "hr", concu = "ng/mL")
  o_nca <- suppressMessages(pk.nca(PKNCAdata(o_conc, intervals = data.frame(start = 168, end = 192, cmax = TRUE, tmax = TRUE))))
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "pknca_warning_tmax_coverage_no_nominal")
  expect_true(all(is.na(as.data.frame(collected$value)$exclude)))
  expect_length(collected$conditions, 1)
  expect_equal(
    conditionMessage(collected$conditions[[1]]),
    "Tmax coverage is not checked for start=168, end=192:  no nominal time of the group is after the interval start, so the nominal times may not share the origin of the actual times and the interval (168 to 192 hr)"
  )
})

test_that("exclude_nca_tmax_coverage does not judge a subject without a usable Tmax, and does not use excluded Tmax values", {
  o_nca <- tmax_coverage_results()
  # With the Tmax of subject 6 excluded, five subjects remain, and subject 6 is
  # not judged
  o_nca_excl <- exclude(o_nca, reason = "Manual", mask = o_nca$result$subject == 6 & o_nca$result$PPTESTCD == "tmax")
  result <- as.data.frame(suppressWarnings(exclude(o_nca_excl, FUN = exclude_nca_tmax_coverage())))
  expect_equal(result$exclude[!is.na(result$exclude)], "Manual")
  # A missing Tmax is not judged either
  o_nca_na <- o_nca
  o_nca_na$result$PPORRES[o_nca_na$result$subject == 6 & o_nca_na$result$PPTESTCD == "tmax"] <- NA
  result_na <- as.data.frame(suppressWarnings(exclude(o_nca_na, FUN = exclude_nca_tmax_coverage())))
  expect_true(all(is.na(result_na$exclude)))
})

test_that("exclude_nca_tmax_coverage reports a subject with no sample in the interval", {
  o_nca <- tmax_coverage_results()
  # Subject 6 loses every concentration after the calculation, so its Tmax has
  # no sample to place it by and it does not enter the fences:  the Tmax values
  # 1, 1, 2, 2, and 2 give the outer range 0 to 5 hours
  o_nca$data$conc$data$conc[o_nca$data$conc$data$subject == 6] <- NA
  result <- as.data.frame(suppressWarnings(exclude(o_nca, FUN = exclude_nca_tmax_coverage())))
  expect_equal(
    result$exclude[result$subject == 6],
    rep("no sample in the outer Tmax range of the group (nominal time 0 to 5 hr after the interval start, no sample after the interval start)", 3)
  )
})

test_that("exclude_nca_tmax_coverage leaves the time unit out of the text when there is none", {
  d_conc <- tmax_coverage_conc()
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal")
  o_nca <- suppressMessages(pk.nca(PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE))))
  result <- as.data.frame(suppressWarnings(exclude(o_nca, FUN = exclude_nca_tmax_coverage())))
  expect_equal(
    result$exclude[result$subject == 6],
    rep("no sample in the outer Tmax range of the group (nominal time 0 to 4.25 after the interval start, nearest sample at 8)", 2)
  )
})

test_that("exclude_nca_tmax_coverage does not check sparse data", {
  d_conc <-
    rbind(
      data.frame(subject = 1, time_nominal = c(0, 2), time = c(0, 2), conc = c(0, 2)),
      data.frame(subject = 2, time_nominal = c(1, 4), time = c(1, 4), conc = c(3, 1)),
      data.frame(subject = 3, time_nominal = c(0, 4), time = c(0, 4), conc = c(0, 1.5)),
      data.frame(subject = 4, time_nominal = c(1, 2), time = c(1, 2), conc = c(2.5, 2))
    )
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal", sparse = TRUE)
  o_nca <- suppressWarnings(suppressMessages(pk.nca(PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 4, cmax = TRUE, tmax = TRUE)))))
  expect_message(
    result <- exclude(o_nca, FUN = exclude_nca_tmax_coverage()),
    class = "pknca_message_tmax_coverage_sparse"
  )
  expect_true(all(is.na(as.data.frame(result)$exclude)))
})

test_that("exclude_nca_tmax_coverage only checks NCA results", {
  o_conc <- PKNCAconc(tmax_coverage_conc(), conc ~ time | subject)
  expect_error(
    exclude(o_conc, FUN = exclude_nca_tmax_coverage()),
    class = "pknca_error_tmax_coverage_not_results"
  )
  # This should never happen in real code
  o_nca <- tmax_coverage_results()
  expect_error(
    exclude_nca_tmax_coverage()(data.frame(PPTESTCD = "tmax", PPORRES = 1:2), o_nca),
    regexp = "Should not see more than one tmax (please report this as a bug)",
    fixed = TRUE
  )
})

test_that("exclude_nca_tmax_coverage does not exclude when the nominal times restart at each dose", {
  # Doses at 0 and 24 hours; the nominal times are relative to the most recent
  # dose, so the second dose's samples have nominal times of 1 to 24 hours
  peaks <- c(1, 1, 2, 2, 1, 4)
  nominal_first <- c(0, 1, 2, 4, 8, 24)
  nominal_second <- c(1, 2, 4, 8, 24)
  d_conc <- data.frame()
  for (current_subject in seq_along(peaks)) {
    d_conc <-
      rbind(
        d_conc,
        data.frame(
          subject = current_subject,
          time_nominal = c(nominal_first, nominal_second),
          time = c(nominal_first, 24 + nominal_second),
          conc =
            c(
              ifelse(nominal_first == 0, 0, 10 / (1 + abs(nominal_first - peaks[current_subject]))),
              2 + 10 / (1 + abs(nominal_second - peaks[current_subject]))
            )
        )
      )
  }
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal", timeu = "hr", concu = "ng/mL")
  o_nca <-
    suppressMessages(pk.nca(PKNCAdata(
      o_conc,
      intervals = data.frame(start = c(0, 24), end = c(24, 48), cmax = TRUE, tmax = TRUE)
    )))
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "warning")
  expect_true(all(is.na(as.data.frame(collected$value)$exclude)))
  # One warning, for the second interval, and no other warning
  expect_length(collected$conditions, 1)
  expect_s3_class(collected$conditions[[1]], "pknca_warning_tmax_coverage_no_nominal")
  expect_equal(
    conditionMessage(collected$conditions[[1]]),
    "Tmax coverage is not checked for start=24, end=48:  no nominal time of the group is after the interval start, so the nominal times may not share the origin of the actual times and the interval (24 to 48 hr)"
  )

  # With doses at 0 and 12 hours and samples to 24 hours after the second, some
  # nominal times are after the start of the second interval, but most samples
  # in it have nominal times before its start
  nominal_first <- c(0, 1, 2, 4, 8, 12)
  nominal_second <- c(1, 2, 4, 8, 12, 24)
  d_conc_12 <- data.frame()
  for (current_subject in seq_along(peaks)) {
    d_conc_12 <-
      rbind(
        d_conc_12,
        data.frame(
          subject = current_subject,
          time_nominal = c(nominal_first, nominal_second),
          time = c(nominal_first, 12 + nominal_second),
          conc =
            c(
              ifelse(nominal_first == 0, 0, 10 / (1 + abs(nominal_first - peaks[current_subject]))),
              2 + 10 / (1 + abs(nominal_second - peaks[current_subject]))
            )
        )
      )
  }
  o_conc_12 <- PKNCAconc(d_conc_12, conc ~ time | subject, time.nominal = "time_nominal", timeu = "hr", concu = "ng/mL")
  o_nca_12 <-
    suppressMessages(pk.nca(PKNCAdata(
      o_conc_12,
      intervals = data.frame(start = c(0, 12), end = c(12, 36), cmax = TRUE, tmax = TRUE)
    )))
  collected_12 <- collect_conditions(exclude(o_nca_12, FUN = exclude_nca_tmax_coverage()), "warning")
  expect_true(all(is.na(as.data.frame(collected_12$value)$exclude)))
  expect_length(collected_12$conditions, 1)
  expect_equal(
    conditionMessage(collected_12$conditions[[1]]),
    "Tmax coverage is not checked for start=12, end=36:  24 of the 36 samples of the group with an actual time in the interval have a nominal time outside it, so the nominal times may not share the origin of the actual times and the interval (12 to 36 hr)"
  )
})

# Concentration data where subjects 1 to 5 have Tmax at `peaks` (in hours) and
# subject 6 has samples only at 0, 8, and 24 hours (Tmax at 8 hours)
tmax_coverage_start_conc <- function(peaks) {
  nominal <- c(0, 0.5, 1, 2, 4, 8, 24)
  ret <- data.frame()
  for (current_subject in seq_along(peaks)) {
    conc <- ifelse(nominal == 0, 0, 10 / (1 + abs(nominal - peaks[current_subject])))
    if (peaks[current_subject] == 0) {
      conc[nominal == 0] <- 20
    }
    ret <- rbind(ret, data.frame(subject = current_subject, time_nominal = nominal, time = nominal, conc = conc))
  }
  rbind(
    ret,
    data.frame(subject = length(peaks) + 1, time_nominal = c(0, 8, 24), time = c(0, 8, 24), conc = c(0, 3, 1))
  )
}

test_that("an exclude_nca_tmax_coverage rule can be used again, on the same or another object", {
  d_conc <- tmax_coverage_conc()
  o_nca_small <- tmax_coverage_results(d_conc[d_conc$subject %in% c(1, 2, 6), ])
  o_nca <- tmax_coverage_results()
  rule_fun <- exclude_nca_tmax_coverage()
  # The group-level message is given in every call
  expect_message(exclude(o_nca_small, FUN = rule_fun), class = "pknca_message_tmax_coverage_few_subjects")
  expect_message(exclude(o_nca_small, FUN = rule_fun), class = "pknca_message_tmax_coverage_few_subjects")
  # Another object gets its own verdicts, and the same object gets the same ones
  first <- suppressMessages(exclude(o_nca, FUN = rule_fun))
  second <- suppressMessages(exclude(o_nca, FUN = rule_fun))
  expect_equal(as.data.frame(first)$exclude, c(rep(NA_character_, 15), rep(tmax_coverage_reason_nominal, 3)))
  expect_equal(second, first)
  # The subject message is given in every call, too
  expect_message(exclude(o_nca, FUN = rule_fun), class = "pknca_message_tmax_coverage_partial")
})

# The best of three elapsed times of applying exclude_nca_tmax_coverage() to
# `n_subjects` subjects
time_tmax_coverage <- function(n_subjects) {
  nominal <- c(0, 0.5, 1, 2, 4, 8, 12, 24)
  d_conc <- data.frame(subject = rep(seq_len(n_subjects), each = length(nominal)), time_nominal = nominal, time = nominal)
  d_conc$conc <- ifelse(d_conc$time == 0, 0, 10 / (1 + abs(d_conc$time - (1 + d_conc$subject %% 3))))
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal")
  o_nca <- suppressMessages(pk.nca(PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE))))
  times <- replicate(3, system.time(exclude(o_nca, FUN = exclude_nca_tmax_coverage()))[["elapsed"]])
  min(times)
}

test_that("exclude_nca_tmax_coverage takes time in proportion to the number of subjects", {
  skip_on_cran()
  # Each group is judged once per call, so eight times the subjects take
  # about eight times as long; judging each subject against its whole group
  # on every call would take about 64 times as long.  The floor on the
  # smaller time keeps timer resolution from deciding the ratio.
  ratio <- time_tmax_coverage(800) / max(time_tmax_coverage(100), 0.02)
  expect_lt(ratio, 16)
})

test_that("exclude_nca_tmax_coverage judges the first dose by its own samples when the nominal times restart", {
  d_conc <- restart_conc(peaks = c(1, 1, 2, 2, 1, 1))
  # Subject 6 has no sample from 0.5 to 4 hours after the first dose, but has
  # them after the second dose, at the same nominal times
  d_conc <- d_conc[!(d_conc$subject == 6 & d_conc$time %in% c(1, 2, 4)), ]
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal", timeu = "hr", concu = "ng/mL")
  o_nca <-
    suppressMessages(pk.nca(PKNCAdata(
      o_conc,
      intervals = data.frame(start = c(0, 24), end = c(24, 48), cmax = TRUE, tmax = TRUE)
    )))
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "warning")
  result <- as.data.frame(collected$value)
  # In the first interval, subject 6 has Tmax at 8 hours:  the Tmax values 1,
  # 1, 2, 2, 1, and 8 give the outer range 0 to 5 hours, which subject 6 has
  # no sample in
  expect_equal(result$PPORRES[result$start == 0 & result$PPTESTCD == "tmax"], c(1, 1, 2, 2, 1, 8))
  expect_equal(
    result$exclude[!is.na(result$exclude)],
    rep("no sample in the outer Tmax range of the group (nominal time 0 to 5 hr after the interval start, nearest sample at 8 hr)", 2)
  )
  expect_equal(unique(result[!is.na(result$exclude), c("subject", "start")]), data.frame(subject = 6, start = 0), ignore_attr = TRUE)
  # The second interval is not checked
  expect_length(collected$conditions, 1)
  expect_s3_class(collected$conditions[[1]], "pknca_warning_tmax_coverage_no_nominal")
  expect_match(conditionMessage(collected$conditions[[1]]), "Tmax coverage is not checked for start=24, end=48:", fixed = TRUE)
})

test_that("exclude_nca_tmax_coverage does not check an interval with more than one dose when the nominal times restart", {
  o_conc <- PKNCAconc(restart_conc(peaks = c(1, 1, 2, 2, 1, 4)), conc ~ time | subject, time.nominal = "time_nominal", timeu = "hr", concu = "ng/mL")
  o_nca <- suppressMessages(pk.nca(PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 48, cmax = TRUE, tmax = TRUE))))
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "warning")
  expect_true(all(is.na(as.data.frame(collected$value)$exclude)))
  expect_length(collected$conditions, 1)
  expect_equal(
    conditionMessage(collected$conditions[[1]]),
    "Tmax coverage is not checked for start=0, end=48:  the nominal times of 6 subject(s) go back to the start of the schedule while the actual times increase within the interval, so the nominal times may not share the origin of the actual times and the interval (0 to 48 hr)"
  )
})

test_that("exclude_nca_tmax_coverage flags, and does not exclude, a subject with a sample only within the outer fences", {
  d_conc <- tmax_coverage_conc()
  # Subject 6 has samples at 0, 4, and 12 hours, so its Tmax is 4 hours:  the
  # Tmax values 1, 1, 2, 2, 2, and 4 have quartiles 1.25 and 2, so the inner
  # range is 0.125 to 3.125 hours and the outer range 0 to 4.25 hours
  d_conc <- d_conc[d_conc$subject != 6, ]
  d_conc <- rbind(d_conc, data.frame(subject = 6, time_nominal = c(0, 4, 12), time = c(0, 4, 12), conc = c(0, 3, 1)))
  o_nca <- tmax_coverage_results(d_conc)
  collected <- collect_conditions(suppressMessages(exclude(o_nca, FUN = exclude_nca_tmax_coverage())), "pknca_warning_tmax_coverage_outlier")
  expect_true(all(is.na(as.data.frame(collected$value)$exclude)))
  expect_length(collected$conditions, 1)
  outlier <- collected$conditions[[1]]
  expect_equal(
    conditionMessage(outlier),
    "Possible data issue for start=0, end=24, subject=6:  no sample in the inner Tmax range of the group (nominal time 0.125 to 3.125 hr after the interval start, nearest sample at 4 hr); not excluded, since a sample is in the outer range"
  )
  expect_equal(outlier$group, data.frame(start = 0, end = 24, subject = 6))
  expect_equal(outlier$tmax_range, c(0.125, 3.125))
  expect_equal(outlier$nearest_sample, 4)
  # With the outer fences at the inner fences, the same subject is excluded
  result_equal <- as.data.frame(suppressMessages(exclude(o_nca, FUN = exclude_nca_tmax_coverage(k_exclude = 1.5))))
  expect_equal(
    result_equal$exclude[!is.na(result_equal$exclude)],
    rep("no sample in the outer Tmax range of the group (nominal time 0.125 to 3.125 hr after the interval start, nearest sample at 4 hr)", 3)
  )
  expect_equal(result_equal$subject[!is.na(result_equal$exclude)], rep(6, 3))
})

# NCA results of tmax_coverage_start_conc() over 0 to 24 hours, with a dose at
# time 0 given as `...` to PKNCAdose(), or without dose data when `...` is
# empty
tmax_coverage_start_results <- function(peaks, ...) {
  d_conc <- tmax_coverage_start_conc(peaks)
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal", timeu = "hr", concu = "ng/mL")
  intervals <- data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE)
  o_data <-
    if (...length() == 0) {
      PKNCAdata(o_conc, intervals = intervals)
    } else {
      d_dose <- data.frame(subject = unique(d_conc$subject), time = 0, dose = 1)
      PKNCAdata(o_conc, PKNCAdose(d_dose, dose ~ time | subject, ...), intervals = intervals)
    }
  suppressMessages(pk.nca(o_data))
}

test_that("exclude_nca_tmax_coverage counts a sample at the interval start only after an intravascular bolus", {
  # Subjects 1 to 5 have Tmax at 0, 1, 1, 2, and 2 hours, and subject 6 has
  # samples only at 0, 8, and 24 hours (Tmax at 8 hours).  The quartiles are 1
  # and 2, so the inner range is 0 to 3.5 hours and the outer range 0 to 5
  # hours.
  peaks <- c(0, 1, 1, 2, 2)
  excluded_reason <-
    rep("no sample in the outer Tmax range of the group (nominal time 0 to 5 hr after the interval start, nearest sample at 8 hr)", 2)
  # After an extravascular dose, the predose sample does not count, even with a
  # Tmax at the interval start in the group
  o_nca_ev <- tmax_coverage_start_results(peaks, route = "extravascular")
  result_ev <- as.data.frame(exclude(o_nca_ev, FUN = exclude_nca_tmax_coverage()))
  expect_equal(result_ev$PPORRES[result_ev$PPTESTCD == "tmax"], c(0, 1, 1, 2, 2, 8))
  expect_equal(result_ev$exclude[!is.na(result_ev$exclude)], excluded_reason)
  expect_equal(result_ev$subject[!is.na(result_ev$exclude)], c(6, 6))
  # Without dose data, the route is unknown, and it is treated as extravascular
  o_nca_none <- tmax_coverage_start_results(peaks)
  result_none <- as.data.frame(exclude(o_nca_none, FUN = exclude_nca_tmax_coverage()))
  expect_equal(result_none$exclude, result_ev$exclude)
  # An infusion is not a bolus
  o_nca_infusion <- tmax_coverage_start_results(peaks, route = "intravascular", duration = 0.5)
  result_infusion <- as.data.frame(exclude(o_nca_infusion, FUN = exclude_nca_tmax_coverage()))
  expect_equal(result_infusion$exclude[!is.na(result_infusion$exclude)], excluded_reason)
  # After an intravascular bolus, the sample at the interval start counts, so
  # subject 6 has a sample within the inner range and only gets a message for
  # the samples it is missing
  o_nca_bolus <- tmax_coverage_start_results(peaks, route = "intravascular")
  collected <- collect_conditions(exclude(o_nca_bolus, FUN = exclude_nca_tmax_coverage()), "pknca_message_tmax_coverage_partial")
  expect_true(all(is.na(as.data.frame(collected$value)$exclude)))
  expect_length(collected$conditions, 1)
  expect_equal(
    conditionMessage(collected$conditions[[1]]),
    "Cmax and Tmax may be unreliable for start=0, end=24, subject=6:  no usable sample at nominal time 0.5, 1, 2 hr, within the inner Tmax range of the group (nominal time 0 to 3.5 hr after the interval start)"
  )
  expect_equal(collected$conditions[[1]]$tmax_range, c(0, 3.5))
})

test_that("exclude_nca_tmax_coverage uses the last dose at or before the interval start for the route", {
  cache <- new.env(parent = emptyenv())
  cache$has_dose <- TRUE
  cache$dose_key_cols <- "subject"
  cache$dose_key <- pknca_interval_group_key(data.frame(subject = c(1, 1, 2)), "subject")
  cache$dose_time <- c(0, 24, 0)
  cache$dose_route <- c("intravascular", "extravascular", "intravascular")
  cache$dose_duration <- c(0, 0, 0)
  subject_1 <- data.frame(subject = 1)
  expect_true(exclude_nca_tmax_coverage_start_counts(subject_1, start = 0, tolerance = 1e-8, cache = cache))
  expect_true(exclude_nca_tmax_coverage_start_counts(subject_1, start = 12, tolerance = 1e-8, cache = cache))
  expect_false(exclude_nca_tmax_coverage_start_counts(subject_1, start = 24, tolerance = 1e-8, cache = cache))
  # No dose at or before the interval start
  expect_false(exclude_nca_tmax_coverage_start_counts(subject_1, start = -1, tolerance = 1e-8, cache = cache))
  # No dose for the subject
  expect_false(exclude_nca_tmax_coverage_start_counts(data.frame(subject = 3), start = 0, tolerance = 1e-8, cache = cache))
  expect_true(exclude_nca_tmax_coverage_start_counts(data.frame(subject = 2), start = 0, tolerance = 1e-8, cache = cache))
})

# Concentration data for subjects with identical profiles peaking at the
# nominal time of 1 hour, with every post-dose sample drawn `offset` hours
# from its nominal time (one value, or one per row)
tmax_coverage_offset_conc <- function(n_subjects, offset) {
  nominal <- c(0, 0.5, 1, 2, 4, 8, 12)
  ret <-
    data.frame(
      subject = rep(seq_len(n_subjects), each = length(nominal)),
      time_nominal = nominal,
      conc = ifelse(nominal == 0, 0, 10 / (1 + abs(nominal - 1)))
    )
  ret$time <- ret$time_nominal + offset * (ret$time_nominal > 0)
  ret
}

test_that("exclude_nca_tmax_coverage places the Tmax and the samples on the same basis", {
  # With nominal times, the Tmax is placed at the nominal time of its sample,
  # so an offset between the actual and nominal times moves nothing
  for (current_offset in c(-0.001, -0.05, -0.1)) {
    o_nca <- tmax_coverage_results(tmax_coverage_offset_conc(n_subjects = 6, offset = current_offset))
    collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), c("warning", "message"))
    expect_true(all(is.na(as.data.frame(collected$value)$exclude)), info = current_offset)
    expect_length(collected$conditions, 0)
  }
  set.seed(5)
  d_conc_random <- tmax_coverage_offset_conc(n_subjects = 20, offset = -0.05 + stats::rnorm(20 * 7, sd = 0.01))
  o_nca_random <- tmax_coverage_results(d_conc_random)
  collected_random <- collect_conditions(exclude(o_nca_random, FUN = exclude_nca_tmax_coverage()), c("warning", "message"))
  expect_true(all(is.na(as.data.frame(collected_random$value)$exclude)))
  expect_length(collected_random$conditions, 0)
})

test_that("two samples drawn out of order are not a restart of the nominal times", {
  d_conc <- tmax_coverage_conc()
  # Subject 1's 1-hour sample was drawn after its 2-hour sample
  d_conc$time[d_conc$subject == 1 & d_conc$time_nominal == 1] <- 2.05
  d_conc$time[d_conc$subject == 1 & d_conc$time_nominal == 2] <- 1.95
  expect_equal(
    pknca_nominal_restart_keys(d_conc, id_cols = "subject", actual_col = "time", nominal_col = "time_nominal"),
    character()
  )
  o_nca <- tmax_coverage_results(d_conc)
  # Subject 1's Tmax is at an actual time of 2.05 hours, the 1-hour nominal
  # sample, so the fences and subject 6's exclusion are as without the swap
  result <- as.data.frame(suppressMessages(exclude(o_nca, FUN = exclude_nca_tmax_coverage())))
  expect_equal(result$PPORRES[result$subject == 1 & result$PPTESTCD == "tmax"], 2.05)
  expect_equal(result$exclude, c(rep(NA_character_, 15), rep(tmax_coverage_reason_nominal, 3)))
  expect_equal(nrow(pknca_missing_samples(o_nca)), 5)
})

test_that("exclude_nca_tmax_coverage does not judge a subject whose samples have no nominal time", {
  d_conc <- tmax_coverage_conc()
  d_conc$time_nominal[d_conc$subject == 3] <- NA
  o_nca <- tmax_coverage_results(d_conc)
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "pknca_message_tmax_coverage_no_nominal_subject")
  result <- as.data.frame(collected$value)
  expect_length(collected$conditions, 1)
  expect_equal(
    conditionMessage(collected$conditions[[1]]),
    "Tmax coverage is not checked for start=0, end=24, subject=3:  its samples in the interval have no nominal time"
  )
  expect_equal(collected$conditions[[1]]$group, data.frame(start = 0, end = 24, subject = 3))
  # Subject 3 is not excluded and does not enter the fences:  the Tmax values
  # 1, 1, 2, 2, and 8 give the outer range 0 to 5 hours
  expect_true(all(is.na(result$exclude[result$subject != 6])))
  expect_equal(
    result$exclude[result$subject == 6],
    rep("no sample in the outer Tmax range of the group (nominal time 0 to 5 hr after the interval start, nearest sample at 8 hr)", 3)
  )
})

test_that("an error while an exclude_nca_tmax_coverage rule prepares leaves it usable", {
  o_nca <- tmax_coverage_results()
  rule_fun <- exclude_nca_tmax_coverage()
  testthat::local_mocked_bindings(
    pknca_cdisc_get_timeu_orig = function(x) stop("transient failure")
  )
  expect_error(exclude(o_nca, FUN = rule_fun), regexp = "transient failure")
  testthat::local_mocked_bindings(
    pknca_cdisc_get_timeu_orig = function(x) "hr"
  )
  expect_equal(
    as.data.frame(suppressMessages(exclude(o_nca, FUN = rule_fun)))$exclude,
    c(rep(NA_character_, 15), rep(tmax_coverage_reason_nominal, 3))
  )
})
