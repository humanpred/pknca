# Data and helpers for the time-to-steady-state tests

# Theoph superposed every 12 hours for 14 doses with 10% log-normal noise
# (seed 5), as in nca.reporter's example; subjects 1-6 are treatment A and
# 7-12 treatment B
tss_test_theoph <- function() {
  theoph <- as.data.frame(datasets::Theoph)
  theoph$conc[theoph$Time == 0] <- 0
  o_single <- PKNCAconc(theoph, conc ~ Time | Subject)
  d_conc <- superposition(o_single, dose.times = tss_test_dose_times(), tau = 168, n.tau = 1)
  set.seed(5)
  d_conc$conc <- d_conc$conc * exp(stats::rnorm(nrow(d_conc), sd = 0.1))
  d_conc$treatment <- ifelse(as.integer(as.character(d_conc$Subject)) <= 6, "A", "B")
  d_conc$Subject <- as.character(d_conc$Subject)
  d_conc
}

tss_test_dose_times <- function() {
  seq(0, 156, by = 12)
}

# Two treatments whose true Tss differ (5 and 15), with troughs at 0 to 30
tss_test_two_tss <- function() {
  set.seed(5)
  d <-
    merge(
      data.frame(
        subject = factor(1:10), css.re = stats::rnorm(10, sd = 0.2), tss.re = stats::rnorm(10, sd = 0.2),
        treatment = rep(c("A", "B"), each = 5)
      ),
      data.frame(treatment = c("A", "B"), css.mean = c(5, 10), tss.mean = c(5, 15))
    )
  d <- merge(d, data.frame(time = 0:30))
  d$conc <-
    with(d, css.mean * exp(css.re + stats::rnorm(nrow(d), sd = 0.05)) * (1 - exp(log(0.1) * time / (tss.mean * exp(tss.re)))))
  d
}

# Troughs still rising at the last dose: the true Tss is about 60, and the
# troughs are at 0 to 14
tss_test_rising <- function() {
  set.seed(6)
  d <- merge(data.frame(subject = factor(1:8), re = stats::rnorm(8, sd = 0.2)), data.frame(time = 0:14))
  d$conc <- 10 * exp(d$re + stats::rnorm(nrow(d), sd = 0.05)) * (1 - exp(log(0.1) * d$time / 60))
  d
}

# Troughs that rise linearly for the whole study
tss_test_linear_rise <- function() {
  set.seed(7)
  d <- merge(data.frame(subject = factor(1:8)), data.frame(time = 0:14))
  d$conc <- d$time * (1 + stats::rnorm(nrow(d), sd = 0.02))
  d
}

# Evaluate `expr`, returning its value and the warnings it gave (muffled)
tss_test_with_warnings <- function(expr) {
  acc <- new.env(parent = emptyenv())
  acc$warnings <- list()
  value <-
    withCallingHandlers(
      expr,
      warning = function(cnd) tss_test_keep_warning(cnd, acc)
    )
  list(value = value, warnings = acc$warnings)
}

tss_test_keep_warning <- function(cnd, acc) {
  acc$warnings[[length(acc$warnings) + 1]] <- cnd
  invokeRestart("muffleWarning")
}

# The first class of each warning kept by tss_test_with_warnings()
tss_test_warning_classes <- function(x) {
  vapply(x$warnings, function(w) class(w)[1], "")
}

# Check the "estimates" attribute of a pk.tss() result:  its columns and status
# values, and that each estimate is the value of its column in the result for
# its treatment and subject
tss_test_check_estimates <- function(fit) {
  est <- attr(fit, "estimates", exact = TRUE)
  testthat::expect_s3_class(est, "data.frame")
  testthat::expect_named(
    est,
    c("type", "output", "treatment", "subject", "estimate", "lower", "upper", "level", "status", "fit_warning", "message")
  )
  testthat::expect_gt(nrow(est), 0)
  testthat::expect_true(
    all(est$status %in% c("estimated", "not_reached", "fit_failed", "insufficient_data", "no_random_effect"))
  )
  for (idx in seq_len(nrow(est))) {
    col <-
      if (est$type[idx] == "stepwise.linear") {
        "tss.stepwise.linear"
      } else {
        paste0("tss.monoexponential.", est$output[idx])
      }
    mask <- rep(TRUE, nrow(fit))
    if (!is.na(est$treatment[idx])) {
      mask <- mask & as.character(fit$treatment) %in% est$treatment[idx]
    }
    if (!is.na(est$subject[idx])) {
      mask <- mask & as.character(fit$subject) %in% est$subject[idx]
    }
    testthat::expect_equal(unique(fit[[col]][mask]), est$estimate[idx])
  }
  invisible(est)
}

# Fit each candidate population model with one Tss for one treatment of
# tss_test_theoph(), as pk.tss.monoexponential.population() does, keeping each
# candidate's AIC, Tss, and number of warnings
tss_test_candidates <- function(trt) {
  d <- tss_test_theoph()
  d <- d[d$treatment == trt, ]
  n_sub <- length(unique(d$Subject))
  modeldata <-
    pk.tss.data.prep(
      conc = d$conc, time = d$time, subject = d$Subject,
      subject.dosing = rep(unique(d$Subject), each = length(tss_test_dose_times())),
      time.dosing = rep(tss_test_dose_times(), n_sub)
    )
  modeldata$tss.constant <- log(1 - 0.9)
  formulas <- tss.monoexponential.generate.formula(modeldata)
  ret <- list()
  for (ranef in names(formulas$ranef.by)) {
    fit <-
      tss_test_with_warnings(
        nlme::nlme(
          conc ~ ctrough.ss * (1 - exp(tss.constant * time / tss)),
          fixed = list(formulas$ctrough.by[[1]]$formula, formulas$tss.by[[1]]$formula),
          random = formulas$ranef.by[[ranef]]$formula,
          start = c(formulas$ctrough.by[[1]]$start, formulas$tss.by[[1]]$start),
          data = modeldata
        )
      )
    ret[[ranef]] <-
      data.frame(
        ranef = ranef, AIC = stats::AIC(fit$value), tss = nlme::fixef(fit$value)[["tss"]],
        n_warnings = length(fit$warnings)
      )
  }
  do.call(rbind, unname(ret))
}
