#' Fit bioequivalence mixed-effects models for NCA endpoints
#'
#' `fitbe_models()` fits a linear mixed-effects model to the log-transformed
#' value of each requested NCA endpoint, the standard analysis for average
#' bioequivalence of a crossover study.  The reference formulation is set as the
#' first factor level so that downstream contrasts estimate test-versus-reference
#' ratios.
#'
#' The model fit for each endpoint is `log(value) ~ <fixed> + <random>` using
#' [lmerTest::lmer()] so that Satterthwaite degrees of freedom are available.
#' When `fixed` and `random` are not supplied, they are derived from the grouping
#' structure of a `PKNCAresults` object: the subject column becomes the random
#' intercept (`(1|subject)`) and the remaining grouping columns (always including
#' `reference_col`) become the fixed effects.  Automatic derivation requires a
#' `PKNCAresults` object; when a plain data.frame is supplied, `fixed` (and
#' usually `random`) must be given.
#'
#' @param object A `PKNCAresults` object (preferred) or a data.frame in the long
#'   format produced by calling `as.data.frame()` on a `PKNCAresults` object (a
#'   `PPTESTCD` column of parameter names and a `PPORRES` or `PPSTRES` column of
#'   values, alongside the grouping columns).
#' @param endpoints Character vector of NCA parameters (matched against
#'   `PPTESTCD`) to model.
#' @param reference_col The name of the column identifying the
#'   formulation/treatment.
#' @param reference_value The value of `reference_col` that is the reference
#'   formulation.
#' @param fixed Optional fixed-effects right-hand side as a single string (for
#'   example `"sequence + period + treatment"`).  When `NULL`, it is derived from
#'   the grouping variables of a `PKNCAresults` object.
#' @param random Optional random-effects specification as a single string (for
#'   example `"(1|subject)"`).  When `NULL`, it is derived from the subject
#'   column.
#' @returns An object of class `fitbe_models`: a list with elements `models` (the
#'   per-endpoint [lmerTest::lmer()] fits), `fixed` (a data.frame of fixed-effect
#'   coefficients with Satterthwaite degrees of freedom), `variance` (a
#'   data.frame of variance components from [lme4::VarCorr()]), and the
#'   `reference_col`, `reference_value`, and `value_col` that were used.
#' @family bioequivalence
#' @seealso [fitbe_table()] to summarize the fits and [fitbe_calculate()] for a
#'   one-step wrapper.
#' @export
fitbe_models <- function(object,
                         endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
                         reference_col,
                         reference_value,
                         fixed = NULL,
                         random = NULL) {
  # Extract the long-format results and grouping metadata.  The subject and
  # grouping columns can only be derived automatically from a PKNCAresults
  # object; for a plain data.frame the user must describe the model.
  subject_col <- NULL
  group_cols <- NULL
  if (inherits(object, "PKNCAresults")) {
    assert_PKNCAresults(object)
    data <- as.data.frame(as.data.frame(object, filter_excluded = TRUE))
    subject_col <- as_PKNCAconc(object)$columns$subject
    group_cols <- setdiff(names(getGroups(object)), c("start", "end"))
  } else if (is.data.frame(object)) {
    data <- as.data.frame(object)
  } else {
    stop("`object` must be a PKNCAresults object or a data.frame.")
  }

  # Cheap input validation first, so that argument errors do not depend on the
  # suggested modeling packages being installed.
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_character(endpoints, min.len = 1, any.missing = FALSE)
  checkmate::assert_subset("PPTESTCD", choices = names(data))
  checkmate::assert_string(reference_col)
  checkmate::assert_choice(reference_col, choices = names(data))
  checkmate::assert_scalar(reference_value)
  checkmate::assert_string(fixed, null.ok = TRUE)
  checkmate::assert_string(random, null.ok = TRUE)
  reference_value <- as.character(reference_value)
  if (!(reference_value %in% as.character(data[[reference_col]]))) {
    stop("Reference value, \"", reference_value, "\", not found in column, \"", reference_col, "\".")
  }

  # The value column is the standardized result when units are present,
  # otherwise the original result.
  value_col <-
    if ("PPSTRES" %in% names(data)) {
      "PPSTRES"
    } else if ("PPORRES" %in% names(data)) {
      "PPORRES"
    } else {
      stop("The data must contain a `PPORRES` or `PPSTRES` column of results.")
    }

  # Derive the random effect from the subject column when not supplied.
  if (is.null(random)) {
    if (is.null(subject_col) || is.na(subject_col)) {
      possible_subjects <- c("USUBJID", "subject", "Subject", "ID", "id")
      subject_col <- possible_subjects[possible_subjects %in% names(data)][1]
    }
    if (is.null(subject_col) || is.na(subject_col)) {
      stop("Could not determine the subject column for the random effect; supply `random` (e.g. \"(1|subject)\").")
    }
    random <- sprintf("(1|%s)", subject_col)
  }

  # Derive the fixed effects from the grouping variables when not supplied,
  # always retaining the formulation column so the treatment effect is
  # estimable.
  if (is.null(fixed)) {
    if (is.null(group_cols)) {
      stop("Could not determine the fixed effects automatically; supply `fixed` (e.g. \"sequence + period + treatment\").")
    }
    auto_fixed <- union(setdiff(group_cols, subject_col), reference_col)
    fixed <- paste(auto_fixed, collapse = " + ")
  }

  if (!requireNamespace("lme4", quietly = TRUE) || !requireNamespace("lmerTest", quietly = TRUE)) {
    stop("The 'lme4' and 'lmerTest' packages are required for bioequivalence model fitting; install them with install.packages(c(\"lme4\", \"lmerTest\")).")
  }

  model_formula <- stats::as.formula(sprintf("log(%s) ~ %s + %s", value_col, fixed, random))

  models <- list()
  fixed_effects <- list()
  variance <- list()
  for (ep in endpoints) {
    data_ep <- data[!is.na(data$PPTESTCD) & data$PPTESTCD == ep, , drop = FALSE]
    data_ep <- data_ep[!is.na(data_ep[[value_col]]), , drop = FALSE]
    if (nrow(data_ep) == 0) {
      warning("No data found for endpoint: ", ep)
      next
    }
    if (!(reference_value %in% as.character(data_ep[[reference_col]]))) {
      warning("Reference value not present for endpoint: ", ep, "; skipping.")
      next
    }
    data_ep[[reference_col]] <-
      stats::relevel(factor(as.character(data_ep[[reference_col]])), ref = reference_value)
    mod <- lmerTest::lmer(model_formula, data = data_ep)
    models[[ep]] <- mod

    fe <- as.data.frame(stats::coef(summary(mod)))
    fe$term <- rownames(fe)
    fe$endpoint <- ep
    rownames(fe) <- NULL
    fixed_effects[[ep]] <- fe

    vc <- as.data.frame(lme4::VarCorr(mod))
    vc$endpoint <- ep
    variance[[ep]] <- vc
  }

  if (length(models) == 0) {
    stop("No endpoints could be fit; check `endpoints` against the `PPTESTCD` values in the data.")
  }

  structure(
    list(
      models = models,
      fixed = do.call(rbind, fixed_effects),
      variance = do.call(rbind, variance),
      reference_col = reference_col,
      reference_value = reference_value,
      value_col = value_col
    ),
    class = "fitbe_models"
  )
}

#' Summarize bioequivalence model fits
#'
#' `fitbe_table()` turns the model fits from [fitbe_models()] into a tidy
#' bioequivalence summary: the geometric mean of each formulation, the geometric
#' mean ratio (test/reference) as a percentage, its confidence interval, the
#' Satterthwaite degrees of freedom, and the intra-subject coefficient of
#' variation.  Confidence intervals are obtained by exponentiating the
#' differences in least-squares means, the standard method for average
#' bioequivalence.
#'
#' @param fit A `fitbe_models` object from [fitbe_models()].
#' @param alpha The significance level; the confidence interval has confidence
#'   level `1 - alpha` (the default `0.10` gives a 90% interval, as used for
#'   average bioequivalence).
#' @returns A data.frame with one row per endpoint and test formulation, with
#'   columns `endpoint`, `test`, `reference`, `gm_test`, `gm_reference`,
#'   `gmr_percent`, `ci_lower`, `ci_upper`, `df`, and `cv_intra_percent`.  A
#'   `method` attribute records the CI method and the software versions used.
#' @family bioequivalence
#' @export
fitbe_table <- function(fit, alpha = 0.10) {
  if (!inherits(fit, "fitbe_models")) {
    stop("`fit` must be a `fitbe_models` object from `fitbe_models()`.")
  }
  assert_numeric_between(alpha, lower = 0, upper = 1)
  if (!requireNamespace("emmeans", quietly = TRUE)) {
    stop("The 'emmeans' package is required for bioequivalence tables; install it with install.packages(\"emmeans\").")
  }
  reference_col <- fit$reference_col
  reference_value <- fit$reference_value

  rows <- list()
  for (ep in names(fit$models)) {
    model <- fit$models[[ep]]
    emm <- emmeans::emmeans(model, specs = reference_col, lmer.df = "satterthwaite")
    gm <- as.data.frame(summary(emm, type = "response"))
    gm_col <- if ("response" %in% names(gm)) "response" else "emmean"
    ctr <- emmeans::contrast(emm, method = "revpairwise", adjust = "none")
    ctr_summary <-
      as.data.frame(summary(ctr, infer = c(TRUE, TRUE), level = 1 - alpha, type = "response"))
    ratio_col <- if ("ratio" %in% names(ctr_summary)) "ratio" else "estimate"

    resid_mask <- fit$variance$endpoint == ep & fit$variance$grp == "Residual"
    resid_sd <- fit$variance$sdcor[resid_mask][1]
    cv_intra <- sqrt(exp(resid_sd^2) - 1) * 100

    gm_reference <- gm[[gm_col]][as.character(gm[[reference_col]]) == reference_value][1]
    test_levels <- setdiff(as.character(gm[[reference_col]]), reference_value)
    for (tl in test_levels) {
      gm_test <- gm[[gm_col]][as.character(gm[[reference_col]]) == tl][1]
      crow <-
        if (length(test_levels) == 1) {
          ctr_summary[1, , drop = FALSE]
        } else {
          ctr_summary[grepl(tl, ctr_summary$contrast, fixed = TRUE), , drop = FALSE][1, ]
        }
      rows[[length(rows) + 1]] <-
        data.frame(
          endpoint = ep,
          test = tl,
          reference = reference_value,
          gm_test = gm_test,
          gm_reference = gm_reference,
          gmr_percent = crow[[ratio_col]] * 100,
          ci_lower = crow$lower.CL * 100,
          ci_upper = crow$upper.CL * 100,
          df = crow$df,
          cv_intra_percent = cv_intra,
          stringsAsFactors = FALSE
        )
    }
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  attr(out, "method") <-
    sprintf(
      "%g%% CI by exponentiated differences in least-squares means; lmerTest %s, lme4 %s, emmeans %s",
      100 * (1 - alpha),
      utils::packageVersion("lmerTest"),
      utils::packageVersion("lme4"),
      utils::packageVersion("emmeans")
    )
  out
}

#' Calculate bioequivalence statistics in one step
#'
#' `fitbe_calculate()` is a convenience wrapper that fits the bioequivalence
#' models with [fitbe_models()] and summarizes them with [fitbe_table()].
#'
#' @inheritParams fitbe_models
#' @param alpha The significance level passed to [fitbe_table()]; the confidence
#'   interval has confidence level `1 - alpha`.
#' @returns A list with elements `table` (the [fitbe_table()] data.frame) and
#'   `fit` (the [fitbe_models()] object).
#' @family bioequivalence
#' @examplesIf requireNamespace("lme4", quietly = TRUE) && requireNamespace("lmerTest", quietly = TRUE) && requireNamespace("emmeans", quietly = TRUE)
#' # A small 2x2 crossover example in PKNCAresults long format
#' set.seed(1)
#' n <- 12
#' sequence <- rep(c("RT", "TR"), length.out = n)
#' subj_effect <- stats::rnorm(n, sd = 0.3)
#' be_data <- do.call(rbind, lapply(seq_len(n), function(i) {
#'   forms <- if (sequence[i] == "RT") c("R", "T") else c("T", "R")
#'   mu <- log(100) + subj_effect[i] + ifelse(forms == "T", 0.05, 0)
#'   data.frame(
#'     subject = i, sequence = sequence[i], period = c(1, 2), form = forms,
#'     PPTESTCD = "auclast", PPORRES = exp(mu + stats::rnorm(2, sd = 0.1)),
#'     stringsAsFactors = FALSE
#'   )
#' }))
#' fitbe_calculate(
#'   be_data,
#'   endpoints = "auclast",
#'   reference_col = "form",
#'   reference_value = "R",
#'   fixed = "sequence + period + form",
#'   random = "(1|subject)"
#' )$table
#' @export
fitbe_calculate <- function(object,
                            endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
                            reference_col,
                            reference_value,
                            fixed = NULL,
                            random = NULL,
                            alpha = 0.10) {
  fit <-
    fitbe_models(
      object = object,
      endpoints = endpoints,
      reference_col = reference_col,
      reference_value = reference_value,
      fixed = fixed,
      random = random
    )
  table <- fitbe_table(fit, alpha = alpha)
  list(table = table, fit = fit)
}
