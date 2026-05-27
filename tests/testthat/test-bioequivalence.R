# Deterministic long-format BE data mimicking as.data.frame(PKNCAresults)
make_be_df <- function(nsub = 24, seed = 123, test_effect = 0, endpoint = "auclast") {
  set.seed(seed)
  sequence <- rep(c("RT", "TR"), length.out = nsub)
  subj_effect <- stats::rnorm(nsub, sd = 0.3)
  do.call(rbind, lapply(seq_len(nsub), function(i) {
    forms <- if (sequence[i] == "RT") c("R", "T") else c("T", "R")
    mu <- log(100) + subj_effect[i] + ifelse(forms == "T", test_effect, 0)
    data.frame(
      subject = i,
      sequence = sequence[i],
      period = c(1, 2),
      form = forms,
      PPTESTCD = endpoint,
      PPORRES = exp(mu + stats::rnorm(2, sd = 0.1)),
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

# Validation (does not require the modeling packages) ------------------------

test_that("fitbe_models rejects non-data input", {
  expect_error(
    fitbe_models(1:10, reference_col = "form", reference_value = "R"),
    "must be a PKNCAresults object or a data.frame"
  )
})

test_that("fitbe_models requires a PPTESTCD column", {
  d <- data.frame(form = c("R", "T"), PPORRES = c(1, 2))
  expect_error(
    fitbe_models(d, reference_col = "form", reference_value = "R",
                 fixed = "form", random = "(1|form)"),
    "PPTESTCD"
  )
})

test_that("fitbe_models requires reference_col to be a column", {
  d <- make_be_df()
  expect_error(
    fitbe_models(d, reference_col = "not_a_col", reference_value = "R",
                 fixed = "form", random = "(1|subject)"),
    "reference_col"
  )
})

test_that("fitbe_models errors when reference_value is absent", {
  d <- make_be_df()
  expect_error(
    fitbe_models(d, reference_col = "form", reference_value = "Z",
                 fixed = "form", random = "(1|subject)"),
    'Reference value, "Z", not found'
  )
})

test_that("fitbe_models needs a result column", {
  d <- make_be_df()
  d$PPORRES <- NULL
  expect_error(
    fitbe_models(d, reference_col = "form", reference_value = "R",
                 fixed = "form", random = "(1|subject)"),
    "PPORRES.*PPSTRES"
  )
})

test_that("fitbe_models requires explicit fixed effects for a data.frame", {
  d <- make_be_df()
  expect_error(
    fitbe_models(d, reference_col = "form", reference_value = "R",
                 random = "(1|subject)"),
    "Could not determine the fixed effects"
  )
})

test_that("fitbe_models errors when the subject column cannot be found", {
  d <- make_be_df()
  names(d)[names(d) == "subject"] <- "patient"
  expect_error(
    fitbe_models(d, reference_col = "form", reference_value = "R",
                 fixed = "form"),
    "Could not determine the subject column"
  )
})

test_that("fitbe_table validates its inputs without modeling packages", {
  expect_error(fitbe_table(list()), "fitbe_models")
  fake <- structure(list(models = list()), class = "fitbe_models")
  expect_error(fitbe_table(fake, alpha = 1.5))
  expect_error(fitbe_table(fake, alpha = -0.1))
})

# Model fitting and summary (require the modeling packages) ------------------

test_that("fitbe_models returns the expected structure", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  d <- make_be_df()
  fit <- fitbe_models(
    d, endpoints = "auclast", reference_col = "form", reference_value = "R",
    fixed = "sequence + period + form", random = "(1|subject)"
  )
  expect_s3_class(fit, "fitbe_models")
  expect_named(fit$models, "auclast")
  expect_true(all(c("term", "endpoint") %in% names(fit$fixed)))
  expect_true("Residual" %in% fit$variance$grp)
  expect_identical(fit$reference_value, "R")
  expect_identical(fit$value_col, "PPORRES")
})

test_that("fitbe_models warns about and skips a missing endpoint", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  d <- make_be_df(endpoint = "auclast")
  expect_warning(
    fit <- fitbe_models(
      d, endpoints = c("auclast", "cmax"), reference_col = "form",
      reference_value = "R", fixed = "form", random = "(1|subject)"
    ),
    "No data found for endpoint: cmax"
  )
  expect_named(fit$models, "auclast")
})

test_that("fitbe_models prefers PPSTRES over PPORRES", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  d <- make_be_df()
  d$PPSTRES <- d$PPORRES
  fit <- fitbe_models(
    d, endpoints = "auclast", reference_col = "form", reference_value = "R",
    fixed = "form", random = "(1|subject)"
  )
  expect_identical(fit$value_col, "PPSTRES")
})

test_that("fitbe_table produces a tidy bioequivalence summary", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- make_be_df(test_effect = 0)
  fit <- fitbe_models(
    d, endpoints = "auclast", reference_col = "form", reference_value = "R",
    fixed = "sequence + period + form", random = "(1|subject)"
  )
  tab <- fitbe_table(fit)
  expect_equal(
    names(tab),
    c("endpoint", "test", "reference", "gm_test", "gm_reference",
      "gmr_percent", "ci_lower", "ci_upper", "df", "cv_intra_percent")
  )
  expect_identical(tab$endpoint, "auclast")
  expect_identical(tab$test, "T")
  expect_identical(tab$reference, "R")
  # truly-equivalent data: GMR near 100% with the CI bracketing the point estimate
  expect_true(tab$ci_lower < tab$gmr_percent)
  expect_true(tab$gmr_percent < tab$ci_upper)
  expect_gt(tab$gmr_percent, 85)
  expect_lt(tab$gmr_percent, 117)
  expect_gt(tab$df, 0)
  expect_gt(tab$cv_intra_percent, 0)
  expect_match(attr(tab, "method"), "least-squares means")
})

test_that("fitbe_table confidence interval widens with smaller alpha", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  fit <- fitbe_models(
    make_be_df(), endpoints = "auclast", reference_col = "form",
    reference_value = "R", fixed = "sequence + period + form",
    random = "(1|subject)"
  )
  ci90 <- fitbe_table(fit, alpha = 0.10)
  ci95 <- fitbe_table(fit, alpha = 0.05)
  expect_lt(ci95$ci_lower, ci90$ci_lower)
  expect_gt(ci95$ci_upper, ci90$ci_upper)
})

test_that("fitbe_calculate wraps fitting and summarising", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  res <- fitbe_calculate(
    make_be_df(), endpoints = "auclast", reference_col = "form",
    reference_value = "R", fixed = "sequence + period + form",
    random = "(1|subject)"
  )
  expect_named(res, c("table", "fit"))
  expect_s3_class(res$fit, "fitbe_models")
  expect_s3_class(res$table, "data.frame")
})

test_that("fitbe_calculate works end-to-end from a PKNCAresults object", {
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

  # small simulated samples can give benign singular fits; quiet those messages
  res <- suppressMessages(fitbe_calculate(
    o_res, endpoints = c("cmax", "auclast"),
    reference_col = "form", reference_value = "R"
  ))
  expect_setequal(res$table$endpoint, c("cmax", "auclast"))
  expect_true(all(is.finite(res$table$gmr_percent)))
  expect_true(all(res$table$gmr_percent > 0))
  expect_true(all(res$table$ci_lower < res$table$ci_upper))
})
