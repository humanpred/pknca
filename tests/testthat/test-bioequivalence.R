# Bioequivalence pipeline: be_dataset validation and the average-BE end-to-end
# path (be_fit_models/be_assess).  Regulatory reference-scaling pins live in
# test-bioequivalence-assess.R.

# Deterministic 2x2 crossover long data (ABE only, reference not replicated).
make_be_df <- function(nsub = 24, seed = 123, test_effect = 0, endpoint = "auclast") {
  set.seed(seed)
  sequence <- rep(c("RT", "TR"), length.out = nsub)
  subj_effect <- stats::rnorm(nsub, sd = 0.3)
  do.call(rbind, lapply(seq_len(nsub), function(i) {
    forms <- if (sequence[i] == "RT") c("R", "T") else c("T", "R")
    mu <- log(100) + subj_effect[i] + ifelse(forms == "T", test_effect, 0)
    data.frame(
      subject = i, sequence = sequence[i], period = c(1, 2), form = forms,
      PPTESTCD = endpoint, PPORRES = exp(mu + stats::rnorm(2, sd = 0.1)),
      stringsAsFactors = FALSE
    )
  }))
}

# Simulate crossover concentration-time data for a full-pipeline integration test
simulate_be_conc <- function(nsub = 8, seed = 42) {
  set.seed(seed)
  times <- c(0, 0.5, 1, 1.5, 2, 4, 6, 8, 12, 24)
  sequence <- rep(c("RT", "TR"), length.out = nsub)
  subj_cl <- stats::rnorm(nsub, mean = log(5), sd = 0.25)
  dose <- 100
  v <- 50
  ka <- 1.0
  rows <- list()
  for (i in seq_len(nsub)) {
    forms <- if (sequence[i] == "RT") c("R", "T") else c("T", "R")
    for (p in 1:2) {
      form <- forms[p]
      cl <- exp(subj_cl[i] + ifelse(form == "T", -0.05, 0) + stats::rnorm(1, sd = 0.05))
      ke <- cl / v
      conc <- (dose * ka / (v * (ka - ke))) * (exp(-ke * times) - exp(-ka * times))
      conc <- conc * exp(stats::rnorm(length(times), sd = 0.05))
      conc[times == 0] <- 0
      rows[[length(rows) + 1]] <-
        data.frame(
          subject = i, sequence = sequence[i], period = p, form = form,
          time = times, conc = conc, stringsAsFactors = FALSE
        )
    }
  }
  do.call(rbind, rows)
}

# be_dataset validation (no modeling packages required) ----------------------

test_that("be_dataset rejects non-data input", {
  expect_error(
    be_dataset(1:10, reference_col = "form", reference_value = "R"),
    "must be a PKNCAresults object or a data.frame"
  )
})

test_that("be_dataset requires a PPTESTCD column", {
  d <- data.frame(form = c("R", "T"), PPORRES = c(1, 2))
  expect_error(be_dataset(d, reference_col = "form", reference_value = "R"), "PPTESTCD")
})

test_that("be_dataset requires reference_col to be a column", {
  expect_error(
    be_dataset(make_be_df(), reference_col = "not_a_col", reference_value = "R"),
    "not_a_col"
  )
})

test_that("be_dataset errors when reference_value is absent", {
  expect_error(
    be_dataset(make_be_df(), reference_col = "form", reference_value = "Z"),
    'Reference value, "Z", not found'
  )
})

test_that("be_dataset needs a result column", {
  d <- make_be_df()
  d$PPORRES <- NULL
  expect_error(
    be_dataset(d, reference_col = "form", reference_value = "R", endpoints = "auclast"),
    "PPORRES.*PPSTRES"
  )
})

test_that("be_dataset errors when the subject column cannot be found", {
  d <- make_be_df()
  names(d)[names(d) == "subject"] <- "patient"
  expect_error(
    be_dataset(d, reference_col = "form", reference_value = "R", endpoints = "auclast"),
    "Could not determine the subject column"
  )
})

test_that("be_dataset standardizes columns and relevels the reference first", {
  ds <- be_dataset(make_be_df(), reference_col = "form", reference_value = "R", endpoints = "auclast")
  expect_s3_class(ds, "be_dataset")
  expect_identical(levels(ds$data$.trt)[1], "R")
  expect_identical(ds$reference_value, "R")
  expect_identical(ds$test_levels, "T")
  expect_identical(ds$endpoints, "auclast")
  expect_true(all(c(".subject", ".period", ".trt", ".logval") %in% names(ds$data)))
})

test_that("be_dataset prefers PPSTRES over PPORRES", {
  d <- make_be_df()
  d$PPSTRES <- d$PPORRES
  ds <- be_dataset(d, reference_col = "form", reference_value = "R", endpoints = "auclast")
  expect_identical(ds$columns$value, "PPSTRES")
})

test_that("be_dataset warns about and skips a missing endpoint", {
  expect_warning(
    ds <- be_dataset(make_be_df(), reference_col = "form", reference_value = "R",
                     endpoints = c("auclast", "cmax")),
    "not found and skipped: cmax"
  )
  expect_identical(ds$endpoints, "auclast")
})

# Average-BE end-to-end (requires the modeling packages) ---------------------

test_that("be_assess (ABE) returns the expected structure for a 2x2 crossover", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  res <- be_assess(make_be_df(test_effect = 0), reference_col = "form", reference_value = "R",
                   endpoints = "auclast", regulator = "ABE")
  expect_s3_class(res, "be_assess")
  expect_identical(res$endpoint, "auclast")
  expect_identical(res$test, "T")
  expect_identical(res$regulator, "ABE")
  expect_identical(res$model_type, "lmer")
  expect_true(res$ci_lower < res$gmr_percent && res$gmr_percent < res$ci_upper)
  expect_gt(res$gmr_percent, 85)
  expect_lt(res$gmr_percent, 117)
  expect_true(is.na(res$swr))
})

test_that("be_fit_models is the engine and matches be_assess values", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- make_be_df()
  tbl <- be_fit_models(d, reference_col = "form", reference_value = "R",
                       endpoints = "auclast", regulator = "ABE")
  expect_s3_class(tbl, "data.frame")
  expect_false(inherits(tbl, "be_assess"))
  res <- be_assess(d, reference_col = "form", reference_value = "R",
                   endpoints = "auclast", regulator = "ABE")
  expect_equal(as.data.frame(res), tbl)
})

test_that("be_assess confidence interval widens with smaller alpha", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- make_be_df()
  ci90 <- be_assess(d, reference_col = "form", reference_value = "R",
                    endpoints = "auclast", regulator = "ABE", alpha = 0.10)
  ci95 <- be_assess(d, reference_col = "form", reference_value = "R",
                    endpoints = "auclast", regulator = "ABE", alpha = 0.05)
  expect_lt(ci95$ci_lower, ci90$ci_lower)
  expect_gt(ci95$ci_upper, ci90$ci_upper)
})

test_that("be_assess works end-to-end from a PKNCAresults object", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  conc_data <- simulate_be_conc()
  dose_data <- conc_data[conc_data$time == 0, c("subject", "sequence", "period", "form")]
  dose_data$dose <- 100
  dose_data$time <- 0
  o_conc <- PKNCAconc(conc_data, conc ~ time | sequence + period + form + subject)
  o_dose <- PKNCAdose(dose_data, dose ~ time | sequence + period + form + subject)
  o_data <- PKNCAdata(
    o_conc, o_dose,
    intervals = data.frame(start = 0, end = Inf, cmax = TRUE, auclast = TRUE)
  )
  o_res <- suppressWarnings(pk.nca(o_data))

  res <- suppressMessages(be_assess(
    o_res, reference_col = "form", reference_value = "R",
    endpoints = c("cmax", "auclast"), regulator = "ABE"
  ))
  expect_setequal(res$endpoint, c("cmax", "auclast"))
  expect_true(all(is.finite(res$gmr_percent)))
  expect_true(all(res$gmr_percent > 0))
  expect_true(all(res$ci_lower < res$ci_upper))
})
