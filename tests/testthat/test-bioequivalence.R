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
      PPORRESU = if (endpoint == "cmax") "ng/mL" else "h*ng/mL"
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
          time = times, conc = conc
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
  # a 2x2 crossover has repeated measures per subject, so be_design steers it to
  # the mixed model (lmer); the fixed-effects ANOVA is for parallel designs
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
  o_conc <- PKNCAconc(conc_data, conc ~ time | sequence + period + form + subject,
                      concu = "ng/mL", timeu = "h", amountu = "mg")
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

# Descriptive framework ---------------------------------------------------------

test_that("be_regulator marks only the descriptive framework as making no decision", {
  # Enumerate every framework so a new one must declare its decision flag.
  all_regs <- eval(formals(be_regulator)$name)
  for (nm in all_regs) {
    reg <- be_regulator(nm)
    expect_identical(reg$decision, nm != "descriptive", info = nm)
  }
  desc <- be_regulator("descriptive")
  expect_identical(desc$scaling, "none")
  expect_identical(desc$est_method, "anova")
  expect_false(desc$pe_constr)
  expect_output(print(desc), "Decision:\\s+none \\(descriptive")
  expect_error(be_expand_limits(0.3, "descriptive"), class = "pknca_error_be_expand_limits_descriptive")
})

test_that("descriptive mode returns the ABE estimates with no decision columns", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- make_be_df(test_effect = 0.2)
  abe <- be_assess(d, "form", "R", "auclast", regulator = "ABE")
  desc <- be_assess(d, "form", "R", "auclast", regulator = "descriptive")
  expect_identical(
    names(desc),
    c("endpoint", "test", "n", "design", "units", "gm_reference", "gm_reference_lower",
      "gm_reference_upper", "gm_test", "gm_test_lower", "gm_test_upper", "gmr_percent",
      "ci_lower", "ci_upper", "cvwr_percent", "cvwt_percent", "swr", "regulator", "model_type")
  )
  shared <- setdiff(names(desc), "regulator")
  expect_equal(as.data.frame(desc)[shared], as.data.frame(abe)[shared])
  expect_identical(desc$regulator, "descriptive")
  expect_match(attr(desc, "caption"), "^Descriptive treatment comparison \\(90% CI\\)\\.")
  expect_match(attr(desc, "caption"), "No regulatory decision was applied", fixed = TRUE)
  expect_output(print(desc), "Treatment comparison: descriptive, no regulatory decision")
  s <- summary(desc)
  expect_identical(names(s), c("endpoint", "test", "gmr_percent", "ci_lower", "ci_upper"))
  expect_match(attr(s, "caption"), "no regulatory decision was applied", fixed = TRUE)
})

test_that("be_compare stacks descriptive rows with missing decision columns", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- make_be_df(test_effect = 0.2)
  cmp <- be_compare(d, "form", "R", "auclast", regulators = c("ABE", "descriptive"))
  expect_identical(cmp$regulator, c("ABE", "descriptive"))
  expect_equal(cmp$gmr_percent[1], cmp$gmr_percent[2])
  expect_identical(cmp$pass[2], NA)
  expect_true(is.na(cmp$limit_lower[2]) && is.na(cmp$limit_upper[2]))
  expect_equal(cmp$limit_lower[1], 80)
  grid <- summary(cmp)
  expect_identical(names(grid), c("endpoint", "ABE", "descriptive"))
  expect_identical(grid$descriptive, NA)
  only_desc <- be_compare(d, "form", "R", "auclast", regulators = "descriptive")
  expect_false("pass" %in% names(only_desc))
  expect_identical(summary(only_desc)$descriptive, NA)
})

# Covariates ------------------------------------------------------------------

test_that("be_dataset standardizes covariate columns", {
  d <- generate_be_parallel()
  d$SEX <- rep(c("F", "M"), length.out = nrow(d))
  d$.cov_stale <- 1
  ds <- be_dataset(d, "treatment", "R", "auclast", covariates = c("WT", "SEX"))
  expect_identical(ds$columns$covariates, c("WT", "SEX"))
  expect_identical(ds$data$.cov_WT, d$WT)
  expect_identical(ds$data$.cov_SEX, factor(d$SEX))
  # a `.cov_` column that was not requested is not carried as a covariate
  expect_false(".cov_stale" %in% names(ds$data))
  expect_identical(be_dataset(d, "treatment", "R", "auclast")$columns$covariates, character())
})

test_that("be_dataset validates covariates", {
  d <- generate_be_parallel()
  expect_error(be_dataset(d, "treatment", "R", "auclast", covariates = "AGE"), "AGE")
  expect_error(be_dataset(d, "treatment", "R", "auclast", covariates = 1), "character")
  expect_error(
    be_dataset(d, "treatment", "R", "auclast", covariates = c("WT", "WT")),
    "duplicated"
  )
  expect_error(
    be_dataset(d, "treatment", "R", "auclast", covariates = "treatment"),
    class = "pknca_error_be_covariate_design_col"
  )
  d$WT[3] <- NA
  expect_error(
    be_dataset(d, "treatment", "R", "auclast", covariates = "WT"),
    class = "pknca_error_be_covariate_missing"
  )
  # a missing covariate on a row that is dropped (missing value) is not an error
  d$PPORRES[3] <- NA
  expect_s3_class(be_dataset(d, "treatment", "R", "auclast", covariates = "WT"), "be_dataset")
})

test_that("a covariate with a single value is an error", {
  d <- generate_be_parallel()
  d$SITE <- "A"
  expect_error(
    be_assess(d, "treatment", "R", "auclast", covariates = "SITE"),
    class = "pknca_error_be_covariate_constant"
  )
})

test_that("a covariate aliased with treatment is an error, not a silent NA", {
  d <- generate_be_parallel()
  d$ARM <- d$treatment
  expect_error(
    be_assess(d, "treatment", "R", "auclast", covariates = "ARM"),
    class = "pknca_error_be_covariate_aliased"
  )
})

test_that("the fixed-effects contrast refuses a treatment nested within subject", {
  # Each subject receives one formulation twice, so the subject fixed effect
  # absorbs the treatment effect.
  w <- data.frame(
    .subject = factor(rep(1:4, each = 2)), .period = factor(rep(1:2, 4)),
    .trt = rep(c("R", "T"), each = 4), .logval = log(c(100, 110, 90, 95, 120, 105, 98, 101))
  )
  expect_error(
    .be_anova_est(w, "R", "T", alpha = 0.1),
    class = "pknca_error_be_trt_not_estimable"
  )
})

test_that("covariates enter the fixed-effects parallel model as additive terms", {
  skip_if_not_installed("emmeans")
  d <- generate_be_parallel()
  res <- be_assess(d, "treatment", "R", "auclast", covariates = "WT")
  expect_identical(res$model_type, c("anova", "anova"))
  for (tl in c("T1", "T2")) {
    dd <- d[d$treatment %in% c("R", tl), ]
    dd$treatment <- factor(dd$treatment, levels = c("R", tl))
    cf <- stats::coef(stats::lm(log(PPORRES) ~ treatment + WT, data = dd))
    expect_equal(res$gmr_percent[res$test == tl], unname(100 * exp(cf[paste0("treatment", tl)])))
  }
  expect_match(attr(res, "caption"), "includes WT as additive covariate", fixed = TRUE)
  # without the covariate the estimate differs
  res0 <- be_assess(d, "treatment", "R", "auclast")
  expect_false(isTRUE(all.equal(res0$gmr_percent, res$gmr_percent)))
})

test_that("covariates enter the lmer crossover model", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  skip_if_not_installed("emmeans")
  d <- make_be_df(test_effect = 0.1)
  # a period-varying covariate (for example a baseline measured each period)
  set.seed(5)
  d$BASE <- stats::rnorm(nrow(d))
  res <- be_assess(d, "form", "R", "auclast", covariates = "BASE")
  d$form <- factor(d$form, levels = c("R", "T"))
  d$period <- factor(d$period)
  fit <- lmerTest::lmer(log(PPORRES) ~ sequence + period + form + BASE + (1 | subject), data = d)
  emm <- emmeans::emmeans(fit, ~form, lmer.df = "satterthwaite")
  ctr <- as.data.frame(summary(emmeans::contrast(emm, "trt.vs.ctrl1"), infer = TRUE, level = 0.9))
  expect_equal(res$gmr_percent, 100 * exp(ctr$estimate))
  expect_equal(res$ci_lower, 100 * exp(ctr$lower.CL))
  expect_equal(res$ci_upper, 100 * exp(ctr$upper.CL))
})

test_that("covariates with an intra-subject-contrast framework warn that they do not affect the ratio", {
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  d$WT <- as.numeric(d$subject) + 60
  expect_warning(
    res <- be_assess(d, "treatment", "R", "auclast", regulator = "FDA", covariates = "WT"),
    class = "pknca_warning_be_covariates_isc"
  )
  plain <- be_assess(d, "treatment", "R", "auclast", regulator = "FDA")
  expect_equal(res$gmr_percent, plain$gmr_percent)
  expect_equal(res$criterion, plain$criterion)
  expect_match(attr(res, "caption"), "Covariates do not enter the intra-subject contrasts.", fixed = TRUE)
})

# Heteroscedastic models ------------------------------------------------------

test_that("the heteroscedastic 2x2 crossover reproduces the model_compare_nca() ratio", {
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 11, "2x2", cv_wr = 0.2, cv_wt = 0.4))
  res <- be_assess(d, "treatment", "R", "auclast", heteroscedastic = TRUE)
  expect_identical(res$model_type, "nlme")
  expect_identical(res$design, "2x2x2")
  # a non-replicated formulation has no within-subject variance to report
  expect_true(is.na(res$swr) && is.na(res$cvwt_percent))
  # The core of nca.reporter::model_compare_nca(): nlme::lme with
  # varIdent(~ 1 | treatment), a subject random intercept, and the emmeans
  # treatment-versus-reference contrast, with nlme's default optimizer.
  fit <- nlme::lme(
    log(PPORRES) ~ sequence + period + treatment, random = ~ 1 | subject,
    weights = nlme::varIdent(form = ~ 1 | treatment), data = d
  )
  emm <- emmeans::emmeans(fit, specs = ~treatment, level = 0.9, data = d)
  ci <- as.data.frame(stats::confint(emmeans::contrast(emm, method = "trt.vs.ctrl1"), level = 0.9))
  expect_equal(res$gmr_percent, 100 * exp(ci$estimate), tolerance = 1e-5)
  expect_equal(res$ci_lower, 100 * exp(ci$lower.CL), tolerance = 1e-5)
  expect_equal(res$ci_upper, 100 * exp(ci$upper.CL), tolerance = 1e-5)
  arm <- as.data.frame(emm)
  expect_equal(res$gm_reference, exp(arm$emmean[arm$treatment == "R"]), tolerance = 1e-5)
  expect_equal(res$gm_test, exp(arm$emmean[arm$treatment == "T"]), tolerance = 1e-5)
  expect_match(attr(res, "caption"), "treatment-specific residual variances (nlme::lme)", fixed = TRUE)
})

test_that("heteroscedastic = TRUE refuses homoscedastic model types", {
  d <- make_be_df()
  expect_error(
    be_assess(d, "form", "R", "auclast", heteroscedastic = TRUE, model_type = "lmer"),
    class = "pknca_error_be_heteroscedastic_lmer"
  )
  for (mt in c("anova", "isc")) {
    expect_error(
      be_assess(d, "form", "R", "auclast", heteroscedastic = TRUE, model_type = mt),
      class = "pknca_error_be_heteroscedastic_model_type"
    )
  }
  expect_error(be_assess(d, "form", "R", "auclast", heteroscedastic = NA), "heteroscedastic")
})

test_that("nlme is for repeated measures and gls is for parallel designs", {
  expect_error(
    be_assess(generate_be_parallel(), "treatment", "R", "auclast", model_type = "nlme"),
    class = "pknca_error_be_nlme_parallel"
  )
  expect_error(
    be_assess(make_be_df(), "form", "R", "auclast", model_type = "gls"),
    class = "pknca_error_be_gls_repeated"
  )
})

test_that("heteroscedastic nlme fits several test levels in a non-replicated crossover", {
  skip_if_not_installed("emmeans")
  d <- generate_be_williams()
  res <- be_assess(d, "treatment", "R", "auclast", heteroscedastic = TRUE)
  expect_identical(res$test, c("T1", "T2"))
  expect_identical(res$model_type, c("nlme", "nlme"))
  expect_identical(res$n, c(18L, 18L))
  d$treatment <- factor(d$treatment, levels = c("R", "T1", "T2"))
  d$period <- factor(d$period)
  fit <- nlme::lme(
    log(PPORRES) ~ sequence + period + treatment, random = ~ 1 | subject,
    weights = nlme::varIdent(form = ~ 1 | treatment), data = d,
    control = nlme::lmeControl(opt = "optim")
  )
  emm <- emmeans::emmeans(fit, ~treatment, data = d)
  ctr <- as.data.frame(summary(
    emmeans::contrast(emm, "trt.vs.ctrl1", adjust = "none"), infer = TRUE, level = 0.9
  ))
  expect_equal(res$gmr_percent, 100 * exp(ctr$estimate), tolerance = 1e-6)
  expect_equal(res$ci_lower, 100 * exp(ctr$lower.CL), tolerance = 1e-6)
  expect_equal(res$ci_upper, 100 * exp(ctr$upper.CL), tolerance = 1e-6)
})

test_that("heteroscedastic nlme keeps the full-replicate requirement only when scaling", {
  skip_if_not_installed("emmeans")
  dp <- be_replicate_long(generate_be_replicate(30, 505, "partial", cv_wr = 0.40))
  # no scaling: a partial replicate is accepted, and the replicated reference
  # varIdent variance is a within-subject variance while the test variance is not
  abe <- be_assess(dp, "treatment", "R", "auclast", heteroscedastic = TRUE)
  expect_identical(abe$model_type, "nlme")
  expect_false(is.na(abe$swr))
  expect_true(is.na(abe$cvwt_percent))
  expect_error(
    be_assess(dp, "treatment", "R", "auclast", regulator = "EMA", heteroscedastic = TRUE),
    class = "pknca_error_be_resolve_model_nlme_not_replicated"
  )
  # several test levels with scaling requested is an error in the fitter
  ds <- be_dataset(generate_be_williams(), "treatment", "R", "auclast")
  expect_error(
    be_fit_model_single(ds$data, "nlme", scaling = TRUE),
    class = "pknca_error_be_nlme_multiple_test"
  )
})

test_that("heteroscedastic = TRUE on a full replicate matches model_type = 'nlme'", {
  skip_if_not_installed("emmeans")
  d <- be_replicate_long(generate_be_replicate(24, 20240501, "full"))
  het <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", heteroscedastic = TRUE)
  nl <- be_assess(d, "treatment", "R", "auclast", regulator = "EMA", model_type = "nlme")
  expect_equal(as.data.frame(het), as.data.frame(nl))
  # the varIdent within-subject variances carry the design-based ANOVA degrees
  # of freedom, as in be_within_var(), so the NTID ratio bound is available
  ds <- be_dataset(d, "treatment", "R", "auclast")
  p <- be_extract_param(be_fit_model_single(ds$data, "nlme"), ds$data)
  wv <- be_within_var(generate_be_replicate(24, 20240501, "full"), "PK", "subject", "period",
                      "treatment", "R", model_type = "anova")
  expect_equal(p$df_wr, wv$df_wR)
  expect_equal(p$df_wt, wv$df_wT)
  expect_false(is.na(p$sw_ratio_ci_upper))
})

# Parallel designs ------------------------------------------------------------

test_that("the homoscedastic parallel design reproduces the pooled two-sample t interval", {
  skip_if_not_installed("emmeans")
  d <- generate_be_parallel()
  res <- be_assess(d, "treatment", "R", "auclast")
  expect_identical(res$test, c("T1", "T2"))
  expect_identical(res$model_type, c("anova", "anova"))
  expect_identical(res$n, c(40L, 40L))
  for (tl in c("T1", "T2")) {
    dd <- d[d$treatment %in% c("R", tl), ]
    tt <- stats::t.test(log(dd$PPORRES[dd$treatment == tl]), log(dd$PPORRES[dd$treatment == "R"]),
                        var.equal = TRUE, conf.level = 0.9)
    row <- res[res$test == tl, ]
    expect_equal(row$gmr_percent, 100 * exp(unname(tt$estimate[1] - tt$estimate[2])))
    expect_equal(c(row$ci_lower, row$ci_upper), 100 * exp(tt$conf.int[1:2]))
  }
  # intra-subject contrasts do not exist in a parallel design
  ds <- be_dataset(d, "treatment", "R", "auclast")
  p <- be_extract_param(be_fit_model_single(ds$data, "anova", scaling = FALSE), ds$data)
  expect_true(all(is.na(p$isc_gmr_percent)))
})

test_that("the heteroscedastic parallel design uses gls with a Welch-type interval", {
  skip_if_not_installed("emmeans")
  d <- generate_be_parallel()
  res <- be_assess(d, "treatment", "R", "auclast", heteroscedastic = TRUE)
  expect_identical(res$model_type, c("gls", "gls"))
  expect_identical(res$test, c("T1", "T2"))
  expect_true(all(is.na(res$swr)))
  expect_match(attr(res, "caption"), "nlme::gls, Satterthwaite degrees of freedom", fixed = TRUE)
  # With treatment as the only fixed effect, gls with varIdent estimates each
  # arm mean and variance separately, so the ratio is the ratio of geometric
  # means and its interval is the Welch interval.
  for (tl in c("T1", "T2")) {
    x <- log(d$PPORRES[d$treatment == tl])
    y <- log(d$PPORRES[d$treatment == "R"])
    tt <- stats::t.test(x, y, var.equal = FALSE, conf.level = 0.9)
    row <- res[res$test == tl, ]
    expect_equal(row$gmr_percent, 100 * exp(mean(x) - mean(y)), tolerance = 1e-6)
    expect_equal(row$gm_test, exp(mean(x)), tolerance = 1e-6)
    expect_equal(c(row$ci_lower, row$ci_upper), 100 * exp(tt$conf.int[1:2]), tolerance = 1e-3)
  }
  # the homoscedastic and heteroscedastic ratios agree; the intervals differ
  hom <- be_assess(d, "treatment", "R", "auclast")
  expect_equal(res$gmr_percent, hom$gmr_percent, tolerance = 1e-6)
  expect_false(isTRUE(all.equal(res$ci_lower, hom$ci_lower)))
})

test_that("gls with a covariate matches a direct gls fit", {
  skip_if_not_installed("emmeans")
  d <- generate_be_parallel()
  res <- be_assess(d, "treatment", "R", "auclast", heteroscedastic = TRUE,
                   covariates = "WT", regulator = "descriptive")
  d$treatment <- factor(d$treatment, levels = c("R", "T1", "T2"))
  fit <- nlme::gls(log(PPORRES) ~ treatment + WT, weights = nlme::varIdent(form = ~ 1 | treatment), data = d)
  cf <- stats::coef(fit)
  expect_equal(res$gmr_percent, unname(100 * exp(cf[c("treatmentT1", "treatmentT2")])), tolerance = 1e-6)
  expect_false("pass" %in% names(res))
})

test_that("a test level whose name is inside another level name gets its own contrast", {
  skip_if_not_installed("emmeans")
  # Levels sort as R, AT, T, so a substring search for "T" meets "AT - R" first.
  d <- generate_be_parallel(effect = c(R = 0, AT = log(1.3), T = log(0.7)), sd = c(R = 0.2, AT = 0.5, T = 0.3))
  res <- be_assess(d, "treatment", "R", "auclast", heteroscedastic = TRUE)
  expect_identical(res$test, c("AT", "T"))
  for (tl in c("AT", "T")) {
    expect_equal(
      res$gmr_percent[res$test == tl],
      100 * exp(mean(log(d$PPORRES[d$treatment == tl])) - mean(log(d$PPORRES[d$treatment == "R"]))),
      tolerance = 1e-6
    )
  }
})

test_that("an intra-subject-contrast regulator errors when no subject has both formulations", {
  skip_if_not_installed("emmeans")
  d <- generate_be_parallel()
  ds <- be_dataset(d, "treatment", "R", "auclast")
  p <- be_extract_param(be_fit_model_single(ds$data, "anova", scaling = FALSE), ds$data)
  p$endpoint <- "auclast"
  expect_error(be_table(p, "FDA"), class = "pknca_error_be_isc_insufficient")
})
