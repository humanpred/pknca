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

tmax_coverage_reason_nominal <-
  "no sample in the Tmax range of the group (nominal time 0.125 to 3.125 hr after the interval start, nearest sample at 8 hr)"

test_that("exclude_nca_tmax_coverage excludes a subject with no sample in the Tmax range and warns for one missing some", {
  o_nca <- tmax_coverage_results()
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "pknca_warning_tmax_coverage_partial")
  result <- as.data.frame(collected$value)
  # Every parameter of subject 6, and nothing else, is excluded
  expect_equal(
    result$exclude,
    c(rep(NA_character_, 15), rep(tmax_coverage_reason_nominal, 3))
  )
  expect_equal(result$subject[!is.na(result$exclude)], rep(6, 3))
  # Subject 5 is warned about, once, and not excluded
  expect_length(collected$conditions, 1)
  partial <- collected$conditions[[1]]
  expect_equal(
    conditionMessage(partial),
    "Cmax and Tmax may be unreliable for start=0, end=24, subject=5:  no usable sample at nominal time 1 hr, within the Tmax range of the group (nominal time 0.125 to 3.125 hr after the interval start)"
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
  result <- as.data.frame(suppressWarnings(exclude(o_nca, FUN = exclude_nca_tmax_coverage())))
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
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "pknca_warning_tmax_coverage_partial")
  result <- as.data.frame(collected$value)
  # Subject 4 now has Tmax at 4 hours:  the Tmax values 1, 1, 2, 4, 2, and 8
  # have quartiles 1.25 and 3.5, so Tukey's fences are -2.125 and 6.875 hours.
  # No Tmax is at the interval start, so the range starts after it, and the
  # predose sample of subject 6 does not count.
  expect_equal(result$PPORRES[result$subject == 4 & result$PPTESTCD == "tmax"], 4)
  expect_equal(
    result$exclude,
    c(
      rep(NA_character_, 10),
      rep("no sample in the Tmax range of the group (nominal time 0 to 6.875 hr after the interval start, nearest sample at 8 hr)", 2)
    )
  )
  expect_equal(result$subject[!is.na(result$exclude)], c(6, 6))
  # Subjects 4 (excluded samples) and 5 (an NA concentration) are missing
  # samples in the range
  expect_equal(
    vapply(collected$conditions, function(x) x$group$subject, FUN.VALUE = 1),
    c(4, 5)
  )
  expect_equal(collected$conditions[[1]]$time_nominal_missing, c(0.5, 1, 2))
  expect_equal(collected$conditions[[1]]$reason, rep("excluded", 3))
  expect_match(
    conditionMessage(collected$conditions[[1]]),
    "no usable sample at nominal time 0.5, 1, 2 hr, within the Tmax range of the group (nominal time 0 to 6.875 hr after the interval start)",
    fixed = TRUE
  )
})

test_that("exclude_nca_tmax_coverage uses the actual times without nominal times", {
  d_conc <- tmax_coverage_conc()
  d_conc$time <- d_conc$time + 0.05 * (d_conc$time > 0)
  o_nca <- tmax_coverage_results(d_conc, time.nominal = NULL)
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "warning")
  result <- as.data.frame(collected$value)
  expect_equal(
    result$exclude[result$subject == 6],
    rep("no sample in the Tmax range of the group (actual time 0.175 to 3.175 hr after the interval start, nearest sample at 8.05 hr)", 3)
  )
  expect_true(all(is.na(result$exclude[result$subject != 6])))
  # Without a schedule, a subject missing some samples is not warned about
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
  # and 8 have quartiles 1 and 4.5, so the range is after the interval start
  # up to 9.75 hours, and subject 6 has a sample in it but is missing the others
  expect_warning(
    result_min3 <- as.data.frame(exclude(o_nca, FUN = exclude_nca_tmax_coverage(min_subjects = 3))),
    regexp = "subject=6:  no usable sample at nominal time 0.5, 1, 2, 4 hr, within the Tmax range of the group (nominal time 0 to 9.75 hr after the interval start)",
    fixed = TRUE,
    class = "pknca_warning_tmax_coverage_partial"
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
  result <- as.data.frame(suppressWarnings(exclude(o_nca, FUN = exclude_nca_tmax_coverage())))
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
    "Tmax coverage is not checked for start=168, end=192:  no nominal time of the group is within the interval (168 to 192 hr); the nominal times may not share the origin of the actual times"
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
  # Subject 6 loses every concentration after the calculation
  o_nca$data$conc$data$conc[o_nca$data$conc$data$subject == 6] <- NA
  result <- as.data.frame(suppressWarnings(exclude(o_nca, FUN = exclude_nca_tmax_coverage())))
  expect_equal(
    result$exclude[result$subject == 6],
    rep("no sample in the Tmax range of the group (nominal time 0.125 to 3.125 hr after the interval start, no sample after the interval start)", 3)
  )
})

test_that("exclude_nca_tmax_coverage leaves the time unit out of the text when there is none", {
  d_conc <- tmax_coverage_conc()
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal")
  o_nca <- suppressMessages(pk.nca(PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE))))
  result <- as.data.frame(suppressWarnings(exclude(o_nca, FUN = exclude_nca_tmax_coverage())))
  expect_equal(
    result$exclude[result$subject == 6],
    rep("no sample in the Tmax range of the group (nominal time 0.125 to 3.125 after the interval start, nearest sample at 8)", 2)
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

test_that("exclude_nca_tmax_coverage counts a sample at the interval start when a subject has its Tmax there", {
  d_conc <- tmax_coverage_conc()
  # Subjects 1 and 2 have Tmax at the interval start:  the Tmax values 0, 0, 2,
  # 2, 2, and 8 have quartiles 0.5 and 2, so the range is -1.75 to 4.25 hours,
  # and the predose sample of subject 6 is in it
  d_conc$conc[d_conc$subject %in% 1:2 & d_conc$time == 0] <- 20
  o_nca <- tmax_coverage_results(d_conc)
  collected <- collect_conditions(exclude(o_nca, FUN = exclude_nca_tmax_coverage()), "pknca_warning_tmax_coverage_partial")
  expect_true(all(is.na(as.data.frame(collected$value)$exclude)))
  expect_equal(
    vapply(collected$conditions, function(x) x$group$subject, FUN.VALUE = 1),
    c(5, 6)
  )
  expect_equal(collected$conditions[[2]]$tmax_range, c(-1.75, 4.25))
  expect_equal(collected$conditions[[2]]$time_nominal_missing, c(0.5, 1, 2, 4))
})
