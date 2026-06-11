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
#' @family Bioequivalence
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
#' @family Bioequivalence
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
#' @family Bioequivalence
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

# Regulatory reference-scaling and decision layer -----------------------------
#
# The functions below extend the average-bioequivalence (ABE) foundation above
# with reference-scaling and a regulatory pass/fail decision for every major
# framework: ABE, EMA average bioequivalence with expanding limits (ABEL),
# Health Canada (HC), the Gulf Cooperation Council (GCC), and the FDA
# reference-scaled average bioequivalence (RSABE) family (RSABE, narrow
# therapeutic index drugs (NTID), and highly variable NTID (HVNTID)).
#
# Every regulatory constant and formula is internalized here with a citation to
# the source guidance; PKNCA does not depend on PowerTOST or replicateBE.  The
# constants were cross-checked against those packages during development.

#' Regulatory framework constants for bioequivalence assessment
#'
#' `be_regulator()` returns the scaling type, switching and capping rules, and
#' regulatory constants that define a bioequivalence (BE) assessment framework.
#' It is the single source of truth for these values: [be_assess()] and the
#' internal decision functions pull every constant from here rather than
#' hard-coding it.
#'
#' @details
#' The supported frameworks and their constants are:
#'
#' * **ABE** -- average bioequivalence; the universal unscaled criterion that
#'   the 90% confidence interval fall within 80.00-125.00%.  No reference
#'   scaling.
#' * **EMA** -- average bioequivalence with expanding limits (ABEL).  Scaling
#'   begins when the within-reference coefficient of variation (`CVwR`) exceeds
#'   30% (`cvswitch = 0.30`); the limits widen as `exp(+/- k * swR)` with the
#'   regulatory constant `k = 0.76` and the expansion is capped at `CVwR = 50%`
#'   (limits 69.84-143.19%).  The constant 0.76 is
#'   `log(1.25) / sqrt(log(1 + 0.30^2))` rounded to two decimals, as fixed by
#'   the EMA bioequivalence guideline.
#' * **HC** -- Health Canada; ABEL with the same `k = 0.76` but the expansion is
#'   capped at `CVwR = 57.382%` (upper limit 150%).
#' * **GCC** -- Gulf Cooperation Council; fixed widened limits of
#'   75.00-133.33% whenever `CVwR > 30%` (not CV-dependent).
#' * **FDA** -- reference-scaled average bioequivalence (RSABE).  The linearized
#'   (Howe/Hyslop) criterion uses `r_const = log(1.25) / 0.25 = 0.8926`
#'   (`theta = r_const^2`) and switches from unscaled ABE when `swR >= 0.294`
#'   (`CVwR` of about 30%).
#' * **NTID** -- FDA narrow therapeutic index drugs; uses
#'   `r_const = -log(0.9) / 0.1 = 1.0536` and always applies the scaled
#'   criterion (a fully replicated design is required).
#' * **HVNTID** -- FDA highly variable narrow therapeutic index drugs; the
#'   RSABE-style scaled criterion with the NTID constant and the within-subject
#'   standard deviation ratio constraint.
#'
#' All frameworks additionally impose the point-estimate constraint that the
#' geometric mean ratio fall within 80.00-125.00%.
#'
#' @param name The regulatory framework, one of `"ABE"`, `"EMA"`, `"HC"`,
#'   `"GCC"`, `"FDA"`, `"NTID"`, or `"HVNTID"`.
#' @returns An object of class `be_regulator`: a list with elements `name`,
#'   `scaling` (one of `"none"`, `"abel"`, `"rsabe"`, `"ntid"`, `"hvntid"`),
#'   `cvswitch`, `r_const`, `cvcap`, `switch_swr`, `pe_constr`, `est_method`
#'   (`"anova"` or `"isc"`), and `switch_basis`.
#' @family Bioequivalence
#' @seealso [be_expand_limits()] for the ABEL acceptance limits and [be_assess()]
#'   for the full assessment.
#' @examples
#' be_regulator("EMA")
#' be_regulator("FDA")
#' @export
be_regulator <- function(name = c("ABE", "EMA", "HC", "GCC", "FDA", "NTID", "HVNTID")) {
  name <- match.arg(name)
  # Regulatory constants, each with its source.  These are intentionally
  # internalized (not pulled from PowerTOST) so PKNCA stands alone.
  reg <-
    switch(
      name,
      ABE = list(
        scaling = "none", cvswitch = NA_real_, r_const = NA_real_,
        cvcap = NA_real_, switch_swr = NA_real_, est_method = "anova"
      ),
      # EMA Guideline on the Investigation of Bioequivalence (CPMP/EWP/QWP/1401/98
      # Rev. 1, 2010) and the EMA Q&A: k = 0.76, scale above CVwR 30%, cap at 50%.
      EMA = list(
        scaling = "abel", cvswitch = 0.30, r_const = 0.76,
        cvcap = 0.50, switch_swr = NA_real_, est_method = "anova"
      ),
      # Health Canada Guidance (Comparative Bioavailability Standards): k = 0.76,
      # cap at CVwR 57.382% (upper limit 150.0%).
      HC = list(
        scaling = "abel", cvswitch = 0.30, r_const = 0.76,
        cvcap = 0.57382, switch_swr = NA_real_, est_method = "anova"
      ),
      # GCC Guidelines for Bioequivalence: fixed 75.00-133.33% above CVwR 30%.
      GCC = list(
        scaling = "abel", cvswitch = 0.30, r_const = NA_real_,
        cvcap = 0.30, switch_swr = NA_real_, est_method = "anova"
      ),
      # FDA Draft Guidance on Progesterone (RSABE): r_const = log(1.25)/0.25,
      # switch to scaling when swR >= 0.294 (regulatory sigma_w0 = 0.25).
      FDA = list(
        scaling = "rsabe", cvswitch = 0.30, r_const = log(1.25) / 0.25,
        cvcap = Inf, switch_swr = 0.294, est_method = "isc"
      ),
      # FDA Draft Guidance on Warfarin (NTID): r_const = -log(0.9)/0.1, the
      # scaled criterion always applies, plus a swT/swR ratio constraint.
      NTID = list(
        scaling = "ntid", cvswitch = NA_real_, r_const = -log(0.9) / 0.1,
        cvcap = Inf, switch_swr = NA_real_, est_method = "isc"
      ),
      # FDA highly variable NTID: RSABE-style scaling with the NTID constant.
      HVNTID = list(
        scaling = "hvntid", cvswitch = 0.30, r_const = -log(0.9) / 0.1,
        cvcap = Inf, switch_swr = 0.294, est_method = "isc"
      )
    )
  structure(
    c(
      list(name = name),
      reg,
      list(
        pe_constr = TRUE,
        switch_basis = switch(
          reg$scaling,
          none = NA_character_,
          abel = "cvwr",
          rsabe = "swr",
          ntid = "always",
          hvntid = "swr"
        )
      )
    ),
    class = "be_regulator"
  )
}

#' @export
print.be_regulator <- function(x, ...) {
  cat(sprintf("Bioequivalence regulator: %s\n", x$name))
  cat(sprintf("  Scaling:            %s\n", x$scaling))
  if (!is.na(x$cvswitch)) {
    cat(sprintf("  CV switch:          %.4g%%\n", x$cvswitch * 100))
  }
  if (!is.na(x$switch_swr)) {
    cat(sprintf("  swR switch:         %.4g\n", x$switch_swr))
  }
  if (!is.na(x$r_const)) {
    cat(sprintf("  Regulatory const.:  %.7g\n", x$r_const))
  }
  if (!is.na(x$cvcap) && is.finite(x$cvcap)) {
    cat(sprintf("  CV cap:             %.5g%%\n", x$cvcap * 100))
  }
  cat(sprintf("  PE constraint:      %s\n", if (x$pe_constr) "80.00-125.00%" else "none"))
  cat(sprintf("  Point estimate:     %s\n", x$est_method))
  invisible(x)
}

#' Reference-scaled acceptance limits for bioequivalence
#'
#' `be_expand_limits()` computes the (possibly widened) bioequivalence
#' acceptance limits for a scaled-ABE framework given the within-reference
#' standard deviation.  For EMA and Health Canada the limits widen
#' geometrically with `swR` and are capped; for the GCC they jump to a fixed
#' wider band; below the switching variability they remain the conventional
#' 80.00-125.00%.
#'
#' @param swR The within-reference standard deviation of the log-transformed
#'   endpoint (for example from [be_within_var()]).
#' @param regulator A regulator name (see [be_regulator()]) or a `be_regulator`
#'   object.  Only the ABEL frameworks (`"EMA"`, `"HC"`, `"GCC"`) widen; `"ABE"`
#'   always returns 80.00-125.00%.
#' @returns A named numeric vector `c(lower, upper)` of acceptance limits as
#'   percentages.
#' @family Bioequivalence
#' @seealso [be_regulator()], [be_assess()]
#' @examples
#' be_expand_limits(0.485, "EMA") # capped expansion
#' be_expand_limits(0.20, "EMA")  # below the switch: 80-125%
#' be_expand_limits(0.40, "GCC")  # fixed GCC band
#' @export
be_expand_limits <- function(swR, regulator) {
  reg <- if (inherits(regulator, "be_regulator")) regulator else be_regulator(regulator)
  checkmate::assert_number(swR, lower = 0, finite = TRUE)
  default <- c(lower = 80, upper = 125)
  # Only the expanding-limits frameworks widen; everything else uses 80-125%.
  if (!identical(reg$scaling, "abel")) {
    return(default)
  }
  cvwr <- sqrt(exp(swR^2) - 1)
  if (cvwr <= reg$cvswitch) {
    return(default)
  }
  if (identical(reg$name, "GCC")) {
    # Fixed widened band, independent of CVwR.
    return(c(lower = 75, upper = 400 / 3))
  }
  # EMA/HC: widen as exp(+/- k * swR), capping swR at the value implied by the
  # framework's CV cap.
  swr_cap <- sqrt(log(1 + reg$cvcap^2))
  swr_eff <- min(swR, swr_cap)
  c(lower = exp(-reg$r_const * swr_eff) * 100, upper = exp(reg$r_const * swr_eff) * 100)
}

# Build a subject's treatment pattern (for example "TRTR"), ordering the
# subject's rows by period.  `idx` are the subject's row indices into the
# period (`per`) and treatment (`trt`) vectors.
.be_subject_pattern <- function(idx, per, trt) {
  idx <- idx[order(per[idx])]
  paste(trt[idx], collapse = "")
}

#' Classify a bioequivalence crossover design
#'
#' `be_design()` inspects the treatment-by-period pattern of a crossover study
#' and reports the design type, the replication of the reference and test
#' formulations, and which regulatory frameworks are feasible.  Reference
#' scaling (EMA/HC/GCC/FDA) requires the reference to be replicated; the narrow
#' therapeutic index frameworks additionally require the test to be replicated.
#'
#' @param data A long data.frame with one row per concentration-derived
#'   observation (subject, period, treatment).
#' @param subject,sequence,period,treatment Column names (length-1 character)
#'   identifying the subject, randomization sequence, period, and treatment.
#'   `sequence` may be `NA` to derive it from the treatment-by-period pattern.
#' @param reference_value The value of `treatment` that is the reference
#'   formulation.
#' @returns An object of class `be_design`: a list with elements `design` (one
#'   of `"2x2x2"`, `"full_replicate"`, `"partial_replicate"`, `"other"`),
#'   `n_sequences`, `n_periods`, `n_treatments`, `n_subjects`, `sequences`,
#'   `treatments`, `reference`, `replicate_reference`, `replicate_test`,
#'   `reps_reference`, `reps_test`, `balanced`, and `feasible` (a named logical
#'   vector for `abe`, `abel`, `rsabe`, `ntid`, `hvntid`).
#' @family Bioequivalence
#' @seealso [be_assess()]
#' @examples
#' d <- data.frame(
#'   subject = rep(1:4, each = 4),
#'   period = rep(1:4, times = 4),
#'   sequence = rep(c("TRTR", "RTRT"), each = 8),
#'   treatment = c("T", "R", "T", "R", "R", "T", "R", "T",
#'                 "T", "R", "T", "R", "R", "T", "R", "T")
#' )
#' be_design(d, "subject", "sequence", "period", "treatment", reference_value = "R")
#' @export
be_design <- function(data, subject, sequence, period, treatment, reference_value) {
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(subject)
  checkmate::assert_string(sequence, na.ok = TRUE)
  checkmate::assert_string(period)
  checkmate::assert_string(treatment)
  for (col in c(subject, period, treatment, if (!is.na(sequence)) sequence)) {
    checkmate::assert_choice(col, choices = names(data))
  }
  reference_value <- as.character(reference_value)
  treatments <- sort(unique(as.character(data[[treatment]])))
  if (!(reference_value %in% treatments)) {
    stop("Reference value, \"", reference_value, "\", not found in column, \"", treatment, "\".")
  }

  subj <- as.character(data[[subject]])
  trt <- as.character(data[[treatment]])
  per <- data[[period]]
  # Per-subject treatment pattern, ordered by period -- the realized sequence.
  patterns <- tapply(seq_len(nrow(data)), subj, .be_subject_pattern, per = per, trt = trt)
  # Per-subject replication counts of each formulation.
  reps_ref_by_subj <- tapply(trt == reference_value, subj, sum)
  reps_test_by_subj <- tapply(!is.na(trt) & trt != reference_value, subj, sum)

  n_subjects <- length(unique(subj))
  n_periods <- length(unique(per))
  n_treatments <- length(treatments)
  seq_values <-
    if (!is.na(sequence)) {
      sort(unique(as.character(data[[sequence]])))
    } else {
      sort(unique(as.character(patterns)))
    }
  n_sequences <- length(seq_values)

  reps_reference <- as.numeric(stats::median(reps_ref_by_subj, na.rm = TRUE))
  reps_test <- as.numeric(stats::median(reps_test_by_subj, na.rm = TRUE))
  replicate_reference <- reps_reference >= 2
  replicate_test <- reps_test >= 2

  design <-
    if (n_treatments != 2) {
      "other"
    } else if (replicate_reference && replicate_test) {
      "full_replicate"
    } else if (replicate_reference && !replicate_test) {
      "partial_replicate"
    } else if (n_periods == 2) {
      "2x2x2"
    } else {
      "other"
    }

  # Balanced when every sequence has the same number of subjects and every
  # subject contributes the modal number of observations.
  subj_seq <-
    if (!is.na(sequence)) {
      tapply(as.character(data[[sequence]]), subj, `[`, 1)
    } else {
      patterns
    }
  seq_sizes <- table(subj_seq)
  obs_per_subj <- table(subj)
  balanced <-
    length(unique(as.numeric(seq_sizes))) == 1 &&
    length(unique(as.numeric(obs_per_subj))) == 1

  feasible <- c(
    abe = n_treatments >= 2,
    abel = replicate_reference,
    rsabe = replicate_reference,
    ntid = replicate_reference && replicate_test,
    hvntid = replicate_reference && replicate_test
  )

  structure(
    list(
      design = design,
      n_sequences = n_sequences,
      n_periods = n_periods,
      n_treatments = n_treatments,
      n_subjects = n_subjects,
      sequences = seq_values,
      treatments = treatments,
      reference = reference_value,
      replicate_reference = replicate_reference,
      replicate_test = replicate_test,
      reps_reference = reps_reference,
      reps_test = reps_test,
      balanced = balanced,
      feasible = feasible
    ),
    class = "be_design"
  )
}

#' @export
print.be_design <- function(x, ...) {
  cat(sprintf("Bioequivalence design: %s\n", x$design))
  cat(sprintf(
    "  %d sequence(s) (%s), %d period(s), %d treatment(s), %d subject(s)%s\n",
    x$n_sequences, paste(x$sequences, collapse = ", "), x$n_periods,
    x$n_treatments, x$n_subjects, if (x$balanced) ", balanced" else ", unbalanced"
  ))
  cat(sprintf(
    "  Reference \"%s\" replicated: %s (%g/subject); test replicated: %s (%g/subject)\n",
    x$reference, x$replicate_reference, x$reps_reference,
    x$replicate_test, x$reps_test
  ))
  feasible_names <- toupper(names(x$feasible))[x$feasible]
  cat(sprintf("  Feasible frameworks: %s\n", paste(feasible_names, collapse = ", ")))
  invisible(x)
}

# Empty within-formulation variance, used when a formulation is not replicated.
.be_arm_var_na <- function() {
  list(s2w = NA_real_, sw = NA_real_, df = NA_real_, cv = NA_real_)
}

# ANOVA within-formulation variance: lm(log(value) ~ subject + period) on a
# single formulation's replicate rows.  The subject factor absorbs sequence, so
# the residual mean square is the within-subject variance; this reproduces
# replicateBE's CV.calc exactly.  `arm` carries the `.subject`, `.period`, and
# `.logval` columns.
.be_arm_var <- function(arm) {
  if (nrow(arm) == 0 || max(table(arm$.subject)) < 2) {
    return(.be_arm_var_na())
  }
  arm$.subject <- droplevels(arm$.subject)
  arm$.period <- droplevels(arm$.period)
  fit_formula <-
    if (nlevels(arm$.period) > 1) .logval ~ .subject + .period else .logval ~ .subject
  a <- stats::anova(stats::lm(fit_formula, data = arm))
  s2w <- a["Residuals", "Mean Sq"]
  df <- a["Residuals", "Df"]
  if (is.na(df) || df < 1) {
    return(.be_arm_var_na())
  }
  list(s2w = s2w, sw = sqrt(s2w), df = df, cv = sqrt(exp(s2w) - 1) * 100)
}

#' Within-subject variability for reference-scaled bioequivalence
#'
#' `be_within_var()` estimates the within-subject standard deviations of the
#' log-transformed endpoint separately for the reference (`swR`) and test
#' (`swT`) formulations, the quantities that reference-scaling frameworks need.
#' The default `method = "A"` is an analysis of variance (ANOVA) of the
#' replicate observations within each formulation; this is the estimator used by
#' both Method A and Method B of the EMA `replicateBE` reference implementation
#' and by the FDA moment-based approach, and it works for full and partial
#' replicate designs.  `method = "B"` instead fits a single mixed model with
#' treatment-specific residual variances and requires a fully replicated design;
#' it is provided as the alternative described in the FDA progesterone guidance
#' and can differ slightly from `method = "A"`.
#'
#' @param data A long data.frame with one row per observation for a *single*
#'   endpoint (subject, period, treatment, and the endpoint value).
#' @param value The column name of the (untransformed) endpoint value; it is
#'   log-transformed internally.
#' @param subject,period,treatment Column names identifying the subject, period,
#'   and treatment.
#' @param reference_value The value of `treatment` that is the reference.
#' @param method `"A"` (ANOVA, the default and the regulatory standard) or `"B"`
#'   (mixed model with treatment-specific residual variances; full replicate
#'   only).
#' @param alpha The significance level for the `swT`/`swR` ratio confidence
#'   bound (default `0.10` gives the 90% upper bound used for narrow therapeutic
#'   index drugs).
#' @returns An object of class `be_within_var`: a list with `swR`, `swT`,
#'   `s2wR`, `s2wT`, `cvwr_percent`, `cvwt_percent`, `df_wR`, `df_wT`,
#'   `sw_ratio` (= `swT`/`swR`), `sw_ratio_ci_upper` (the upper `1 - alpha`
#'   confidence bound of the ratio), `method`, and `alpha`.  `swT` and the ratio
#'   are `NA` when the test formulation is not replicated (for example a partial
#'   replicate design).
#' @family Bioequivalence
#' @seealso [be_assess()]
#' @export
be_within_var <- function(data, value, subject, period, treatment, reference_value,
                          method = c("A", "B"), alpha = 0.10) {
  method <- match.arg(method)
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_string(value)
  checkmate::assert_string(subject)
  checkmate::assert_string(period)
  checkmate::assert_string(treatment)
  for (col in c(value, subject, period, treatment)) {
    checkmate::assert_choice(col, choices = names(data))
  }
  assert_numeric_between(alpha, lower = 0, upper = 1)
  reference_value <- as.character(reference_value)

  work <- data.frame(
    .subject = factor(as.character(data[[subject]])),
    .period = factor(as.character(data[[period]])),
    .trt = as.character(data[[treatment]]),
    .val = data[[value]],
    stringsAsFactors = FALSE
  )
  work <- work[!is.na(work$.val) & work$.val > 0, , drop = FALSE]
  work$.logval <- log(work$.val)
  if (!(reference_value %in% work$.trt)) {
    stop("Reference value, \"", reference_value, "\", not found in column, \"", treatment, "\".")
  }
  test_levels <- setdiff(unique(work$.trt), reference_value)

  # ANOVA within-formulation variance on each formulation's replicate rows
  # (see .be_arm_var).
  ref_v <- .be_arm_var(work[work$.trt == reference_value, , drop = FALSE])
  test_v <-
    if (length(test_levels) == 1) {
      .be_arm_var(work[work$.trt == test_levels, , drop = FALSE])
    } else {
      # Multiple test formulations: swT (and the ratio) are not defined for a
      # single test arm; report reference variability only.
      .be_arm_var_na()
    }

  if (method == "B") {
    # Mixed model with treatment-specific residual variances (full replicate
    # only).  Variances come from the model; degrees of freedom are kept from
    # the ANOVA above (the design-based within-subject replication).
    if (is.na(ref_v$sw) || is.na(test_v$sw)) {
      stop("Method B (mixed model) requires a fully replicated design with both formulations replicated; use method = \"A\".")
    }
    mixed <- .be_within_var_mixed(work, reference_value, test_levels)
    ref_v$s2w <- mixed$s2wR
    ref_v$sw <- sqrt(mixed$s2wR)
    ref_v$cv <- sqrt(exp(mixed$s2wR) - 1) * 100
    test_v$s2w <- mixed$s2wT
    test_v$sw <- sqrt(mixed$s2wT)
    test_v$cv <- sqrt(exp(mixed$s2wT) - 1) * 100
  }

  sw_ratio <-
    if (!is.na(test_v$sw) && !is.na(ref_v$sw) && ref_v$sw > 0) test_v$sw / ref_v$sw else NA_real_
  sw_ratio_ci_upper <-
    if (!is.na(sw_ratio) && !is.na(test_v$df) && !is.na(ref_v$df)) {
      sw_ratio / sqrt(stats::qf(1 - alpha / 2, test_v$df, ref_v$df, lower.tail = FALSE))
    } else {
      NA_real_
    }

  structure(
    list(
      swR = ref_v$sw, swT = test_v$sw,
      s2wR = ref_v$s2w, s2wT = test_v$s2w,
      cvwr_percent = ref_v$cv, cvwt_percent = test_v$cv,
      df_wR = ref_v$df, df_wT = test_v$df,
      sw_ratio = sw_ratio, sw_ratio_ci_upper = sw_ratio_ci_upper,
      method = method, alpha = alpha
    ),
    class = "be_within_var"
  )
}

# Mixed model with treatment-specific residual variances (nlme::lme +
# varIdent).  Returns the within-subject variances for the reference and the
# single test formulation.  nlme is a hard dependency of PKNCA (in Imports).
.be_within_var_mixed <- function(work, reference_value, test_levels) {
  work$.trt <- factor(work$.trt)
  model <-
    nlme::lme(
      .logval ~ .trt + .period,
      random = ~ 1 | .subject,
      weights = nlme::varIdent(form = ~ 1 | .trt),
      data = work,
      control = nlme::lmeControl(opt = "optim", returnObject = TRUE)
    )
  sigma <- model$sigma
  mult <- stats::coef(model$modelStruct$varStruct, unconstrained = FALSE, allCoef = TRUE)
  list(
    s2wR = (sigma * mult[[reference_value]])^2,
    s2wT = (sigma * mult[[test_levels[1]]])^2
  )
}

#' @export
print.be_within_var <- function(x, ...) {
  cat(sprintf("Within-subject variability (method %s):\n", x$method))
  cat(sprintf("  Reference: swR = %.5f, CVwR = %.4g%% (df = %g)\n",
              x$swR, x$cvwr_percent, x$df_wR))
  if (!is.na(x$swT)) {
    cat(sprintf("  Test:      swT = %.5f, CVwT = %.4g%% (df = %g)\n",
                x$swT, x$cvwt_percent, x$df_wT))
    cat(sprintf("  swT/swR = %.5f (upper %g%% confidence bound = %.5f)\n",
                x$sw_ratio, (1 - x$alpha) * 100, x$sw_ratio_ci_upper))
  } else {
    cat("  Test:      not replicated (swT unavailable)\n")
  }
  invisible(x)
}

# Per-framework decision functions --------------------------------------------
#
# Each `.be_*` decider takes the average-BE estimate `est` (a list with
# `pe_log`, `se`, `df`, `n`, `gmr_percent`, `ci_lower`, `ci_upper`), a
# `be_within_var` object `wv`, a `be_regulator` object `reg`, and `alpha`, and
# returns the decision fragment `list(limit_lower, limit_upper, criterion,
# pass)` that becomes one row of the [be_assess()] result.

# Intra-subject contrasts (ISC) point estimate, the FDA reference-scaled
# approach: within each subject form the mean log test minus mean log reference,
# then average across subjects.  `work` carries `.subject`, `.trt`, `.logval`.
# Within-subject contrast for one subject: mean log test minus mean log
# reference, or NA if the subject lacks either formulation.  `s` carries the
# `.trt` and `.logval` columns.
.be_subject_ilat <- function(s, reference_value, test_level) {
  t_val <- s$.logval[s$.trt == test_level]
  r_val <- s$.logval[s$.trt == reference_value]
  if (length(t_val) == 0 || length(r_val) == 0) {
    NA_real_
  } else {
    mean(t_val) - mean(r_val)
  }
}

.be_isc <- function(work, reference_value, test_level, alpha = 0.10) {
  byid <- split(work, work$.subject)
  ilat <- vapply(byid, .be_subject_ilat, numeric(1), reference_value, test_level)
  ilat <- ilat[!is.na(ilat)]
  n <- length(ilat)
  if (n < 2) {
    stop("The intra-subject contrast estimate needs at least 2 subjects with both formulations.")
  }
  pe_log <- mean(ilat)
  se <- stats::sd(ilat) / sqrt(n)
  df <- n - 1
  ci <- exp(pe_log + c(-1, 1) * stats::qt(1 - alpha / 2, df) * se) * 100
  list(
    pe_log = pe_log, se = se, df = df, n = n,
    gmr_percent = exp(pe_log) * 100, ci_lower = ci[1], ci_upper = ci[2]
  )
}

# Linearized (Howe/Hyslop) reference-scaled criterion.  The one-sided 95% upper
# bound of (point-estimate^2 - theta * s2wR) must be <= 0.  This uses the FDA's
# one-sided alpha = 0.05 regardless of the user's confidence-interval alpha.
.be_rsabe_bound <- function(pe_log, se, s2wR, dfRR, r_const, alpha = 0.05) {
  hw <- stats::qt(1 - alpha, dfRR) * se
  Em <- pe_log^2 - se^2
  Es <- r_const^2 * s2wR
  Cm <- (abs(pe_log) + hw)^2
  Cs <- Es * dfRR / stats::qchisq(alpha, dfRR)
  Em - Es + sqrt((Cm - Em)^2 + (Cs - Es)^2)
}

# Whether the geometric mean ratio satisfies the point-estimate constraint.
.be_pe_ok <- function(reg, gmr_percent) {
  !reg$pe_constr || (gmr_percent >= 80 & gmr_percent <= 125)
}

# Average bioequivalence: conventional 80-125% on the 90% confidence interval.
.be_abe <- function(est, wv, reg, alpha) {
  list(
    limit_lower = 80, limit_upper = 125, criterion = NA_real_,
    pass = isTRUE(est$ci_lower >= 80 && est$ci_upper <= 125)
  )
}

# Average bioequivalence with expanding limits (EMA / HC / GCC).
.be_abel <- function(est, wv, reg, alpha) {
  if (is.na(wv$swR)) {
    stop("Reference scaling requires a replicated reference; the reference is not replicated.")
  }
  lim <- be_expand_limits(wv$swR, reg)
  ci_ok <- est$ci_lower >= lim[["lower"]] && est$ci_upper <= lim[["upper"]]
  list(
    limit_lower = unname(lim[["lower"]]), limit_upper = unname(lim[["upper"]]),
    criterion = NA_real_,
    pass = isTRUE(ci_ok && .be_pe_ok(reg, est$gmr_percent))
  )
}

# FDA reference-scaled average bioequivalence (RSABE).  Below the switching
# variability (swR < 0.294) it falls back to unscaled average bioequivalence.
.be_rsabe <- function(est, wv, reg, alpha) {
  if (is.na(wv$swR)) {
    stop("Reference scaling requires a replicated reference; the reference is not replicated.")
  }
  pe_ok <- .be_pe_ok(reg, est$gmr_percent)
  if (!is.na(reg$switch_swr) && wv$swR < reg$switch_swr) {
    # Unscaled average bioequivalence fallback.
    list(
      limit_lower = 80, limit_upper = 125, criterion = NA_real_,
      pass = isTRUE(est$ci_lower >= 80 && est$ci_upper <= 125 && pe_ok)
    )
  } else {
    bound <- .be_rsabe_bound(est$pe_log, est$se, wv$s2wR, wv$df_wR, reg$r_const)
    list(
      limit_lower = NA_real_, limit_upper = NA_real_, criterion = bound,
      pass = isTRUE(bound <= 0 && pe_ok)
    )
  }
}

# FDA narrow therapeutic index drugs (NTID): the scaled criterion must pass, the
# conventional 90% CI must lie within 80-125%, and the upper 90% confidence
# bound of swT/swR must be at most 2.5.
.be_ntid <- function(est, wv, reg, alpha) {
  if (is.na(wv$swT)) {
    stop("NTID assessment requires a fully replicated design (both formulations replicated).")
  }
  bound <- .be_rsabe_bound(est$pe_log, est$se, wv$s2wR, wv$df_wR, reg$r_const)
  list(
    limit_lower = 80, limit_upper = 125, criterion = bound,
    pass = isTRUE(
      bound <= 0 &&
        est$ci_lower >= 80 && est$ci_upper <= 125 &&
        !is.na(wv$sw_ratio_ci_upper) && wv$sw_ratio_ci_upper <= 2.5 &&
        .be_pe_ok(reg, est$gmr_percent)
    )
  )
}

# FDA highly variable narrow therapeutic index drugs (HVNTID): the scaled
# criterion plus the swT/swR ratio constraint and the point-estimate constraint
# (no separate unscaled-CI gate, reflecting the high variability).  The HVNTID
# decision wording is the least settled of the frameworks; this implements the
# RSABE-style scaled bound with the NTID constant.
.be_hvntid <- function(est, wv, reg, alpha) {
  if (is.na(wv$swT)) {
    stop("HVNTID assessment requires a fully replicated design (both formulations replicated).")
  }
  bound <- .be_rsabe_bound(est$pe_log, est$se, wv$s2wR, wv$df_wR, reg$r_const)
  list(
    limit_lower = NA_real_, limit_upper = NA_real_, criterion = bound,
    pass = isTRUE(
      bound <= 0 &&
        !is.na(wv$sw_ratio_ci_upper) && wv$sw_ratio_ci_upper <= 2.5 &&
        .be_pe_ok(reg, est$gmr_percent)
    )
  )
}

# Dispatch to the decider for a regulator's scaling type.
.be_decide <- function(est, wv, reg, alpha) {
  switch(
    reg$scaling,
    none = .be_abe(est, wv, reg, alpha),
    abel = .be_abel(est, wv, reg, alpha),
    rsabe = .be_rsabe(est, wv, reg, alpha),
    ntid = .be_ntid(est, wv, reg, alpha),
    hvntid = .be_hvntid(est, wv, reg, alpha)
  )
}

# Find a column name: use `given` if supplied, otherwise the first of
# `candidates` present in the data.
.be_find_col <- function(given, data, candidates, what, required = TRUE) {
  if (!is.null(given) && !is.na(given)) {
    checkmate::assert_choice(given, choices = names(data))
    return(given)
  }
  hit <- candidates[candidates %in% names(data)]
  if (length(hit) >= 1) {
    return(hit[1])
  }
  if (required) {
    stop(
      "Could not determine the ", what, " column; supply it explicitly (tried: ",
      paste(candidates, collapse = ", "), ")."
    )
  }
  NA_character_
}

# Extract the long-format data and the subject/sequence/period/value columns
# from a PKNCAresults object or a tidy data.frame, mirroring fitbe_models().
.be_extract <- function(object, reference_col, subject, sequence, period) {
  if (inherits(object, "PKNCAresults")) {
    assert_PKNCAresults(object)
    data <- as.data.frame(as.data.frame(object, filter_excluded = TRUE))
    if (is.null(subject)) {
      subject <- as_PKNCAconc(object)$columns$subject
    }
  } else if (is.data.frame(object)) {
    data <- as.data.frame(object)
  } else {
    stop("`object` must be a PKNCAresults object or a data.frame.")
  }
  checkmate::assert_data_frame(data, min.rows = 1)
  checkmate::assert_subset("PPTESTCD", choices = names(data))
  checkmate::assert_choice(reference_col, choices = names(data))
  value_col <-
    if ("PPSTRES" %in% names(data)) {
      "PPSTRES"
    } else if ("PPORRES" %in% names(data)) {
      "PPORRES"
    } else {
      stop("The data must contain a `PPORRES` or `PPSTRES` column of results.")
    }
  subject <- .be_find_col(subject, data, c("USUBJID", "subject", "Subject", "ID", "id"), "subject")
  period <- .be_find_col(period, data, c("period", "Period", "PERIOD", "PER", "per"), "period")
  sequence <-
    .be_find_col(sequence, data, c("sequence", "Sequence", "SEQUENCE", "SEQ", "seq"), "sequence", required = FALSE)
  list(
    data = data, value_col = value_col,
    subject = subject, sequence = sequence, period = period
  )
}

# An empty within-variance result for the unscaled ABE framework.
.be_empty_wv <- function(alpha) {
  structure(
    list(
      swR = NA_real_, swT = NA_real_, s2wR = NA_real_, s2wT = NA_real_,
      cvwr_percent = NA_real_, cvwt_percent = NA_real_, df_wR = NA_real_, df_wT = NA_real_,
      sw_ratio = NA_real_, sw_ratio_ci_upper = NA_real_, method = NA_character_, alpha = alpha
    ),
    class = "be_within_var"
  )
}

# Fixed-effects ANOVA average-BE estimate (Method A): subject as a fixed effect,
# reproducing replicateBE::method.A's geometric mean ratio and CI.
.be_anova_est <- function(work, reference_value, test_level, alpha) {
  w <- work[work$.trt %in% c(reference_value, test_level), , drop = FALSE]
  w$.trt <- stats::relevel(factor(w$.trt), ref = reference_value)
  w$.subject <- droplevels(w$.subject)
  w$.period <- droplevels(w$.period)
  fit_formula <-
    if (nlevels(w$.period) > 1) .logval ~ .subject + .period + .trt else .logval ~ .subject + .trt
  model <- stats::lm(fit_formula, data = w)
  cf <- summary(model)$coefficients
  term <- paste0(".trt", test_level)
  est <- cf[term, "Estimate"]
  se <- cf[term, "Std. Error"]
  df <- model$df.residual
  ci <- exp(est + c(-1, 1) * stats::qt(1 - alpha / 2, df) * se) * 100
  list(
    pe_log = est, se = se, df = df, n = NA_integer_,
    gmr_percent = exp(est) * 100, ci_lower = ci[1], ci_upper = ci[2]
  )
}

# Confirm the design supports the chosen framework.
.be_check_feasible <- function(reg, design) {
  key <- switch(
    reg$scaling,
    none = "abe", abel = "abel", rsabe = "rsabe", ntid = "ntid", hvntid = "hvntid"
  )
  if (!isTRUE(design$feasible[[key]])) {
    need <-
      if (key %in% c("ntid", "hvntid")) {
        "a fully replicated design (both formulations replicated)"
      } else if (key %in% c("abel", "rsabe")) {
        "a replicated reference"
      } else {
        "both a test and reference formulation"
      }
    stop(sprintf(
      "The %s framework requires %s, which the %s design does not provide.",
      reg$name, need, design$design
    ))
  }
}

#' Assess bioequivalence against a regulatory framework
#'
#' `be_assess()` performs a complete bioequivalence (BE) assessment of one or
#' more noncompartmental endpoints against a regulatory framework, including
#' reference scaling and the pass/fail decision.  It accepts the results of
#' [pk.nca()] directly (a `PKNCAresults` object) or a tidy long data.frame, so
#' the same workflow that produces NCA parameters flows into the regulatory
#' decision.
#'
#' For average bioequivalence and the expanding-limits frameworks (EMA, HC,
#' GCC) the geometric mean ratio and its confidence interval come from the
#' average-BE model (see [fitbe_models()]); the `method` argument selects the
#' fixed-effects ANOVA (`"A"`) or the mixed model (`"B"`).  For the FDA
#' reference-scaled frameworks (FDA RSABE, NTID, HVNTID) the point estimate and
#' the linearized criterion are computed from intra-subject contrasts, as the
#' guidances specify.  Within-subject variability is always estimated by the
#' regulatory ANOVA method (see [be_within_var()]).
#'
#' @inheritParams be_within_var
#' @param object A `PKNCAresults` object or a tidy long data.frame with a
#'   `PPTESTCD` column of parameter names, a `PPORRES`/`PPSTRES` column of
#'   values, and subject/sequence/period/treatment columns.
#' @param reference_col The column identifying the formulation/treatment.
#' @param endpoints Character vector of NCA parameters (matched against
#'   `PPTESTCD`) to assess.
#' @param regulator The regulatory framework (see [be_regulator()]); one of
#'   `"ABE"`, `"EMA"`, `"HC"`, `"GCC"`, `"FDA"`, `"NTID"`, or `"HVNTID"`.
#' @param method `"A"` (fixed-effects ANOVA, the `replicateBE` Method A
#'   convention) or `"B"` (mixed model, the default) for the average-BE
#'   geometric mean ratio and confidence interval.
#' @param subject,sequence,period Column names for the subject, randomization
#'   sequence, and period.  When `NULL` they are taken from the `PKNCAresults`
#'   object or detected from common column names.  `sequence` may be absent.
#' @param design An optional [be_design()] object; computed from the data when
#'   `NULL`.
#' @returns An object of class `be_assess` (a data.frame) with one row per
#'   endpoint and test formulation and the columns `endpoint`, `test`, `n`,
#'   `design`, `gmr_percent`, `ci_lower`, `ci_upper`, `cvwr_percent`,
#'   `cvwt_percent`, `swr`, `limit_lower`, `limit_upper`, `criterion`,
#'   `regulator`, `method`, and `pass`.  `limit_*` are `NA` for the RSABE
#'   criterion and `criterion` is `NA` for the limit-based frameworks.
#' @family Bioequivalence
#' @seealso [be_compare()] to assess one dataset under several frameworks,
#'   [be_within_var()], and [be_regulator()].
#' @examplesIf requireNamespace("lme4", quietly = TRUE) && requireNamespace("lmerTest", quietly = TRUE) && requireNamespace("emmeans", quietly = TRUE)
#' # A replicate-design crossover in long (PPTESTCD/PPORRES) format
#' set.seed(1)
#' nsub <- 24
#' seqs <- rep(c("TRTR", "RTRT"), length.out = nsub)
#' b <- stats::rnorm(nsub, sd = 0.4)
#' d <- do.call(rbind, lapply(seq_len(nsub), function(i) {
#'   trt <- strsplit(seqs[i], "")[[1]]
#'   data.frame(
#'     subject = i, sequence = seqs[i], period = seq_along(trt), treatment = trt,
#'     PPTESTCD = "auclast",
#'     PPORRES = exp(log(100) + ifelse(trt == "T", 0.04, 0) + b[i] +
#'                     stats::rnorm(length(trt), sd = 0.45)),
#'     stringsAsFactors = FALSE
#'   )
#' }))
#' be_assess(d, reference_col = "treatment", reference_value = "R",
#'           endpoints = "auclast", regulator = "EMA")
#' @export
be_assess <- function(object, reference_col, reference_value,
                      endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
                      regulator = "FDA", method = c("B", "A"), alpha = 0.10,
                      subject = NULL, sequence = NULL, period = NULL, design = NULL) {
  method <- match.arg(method)
  checkmate::assert_string(reference_col)
  checkmate::assert_character(endpoints, min.len = 1, any.missing = FALSE)
  assert_numeric_between(alpha, lower = 0, upper = 1)
  reg <- be_regulator(regulator)

  ext <- .be_extract(object, reference_col, subject, sequence, period)
  data <- ext$data
  value_col <- ext$value_col
  subject <- ext$subject
  sequence <- ext$sequence
  period <- ext$period

  reference_value <- as.character(reference_value)
  if (!(reference_value %in% as.character(data[[reference_col]]))) {
    stop("Reference value, \"", reference_value, "\", not found in column, \"", reference_col, "\".")
  }

  if (is.null(design)) {
    design <- be_design(data, subject, sequence, period, reference_col, reference_value)
  } else if (!inherits(design, "be_design")) {
    stop("`design` must be a `be_design` object from `be_design()`.")
  }
  .be_check_feasible(reg, design)

  present <- intersect(endpoints, unique(as.character(data$PPTESTCD)))
  if (length(present) == 0) {
    stop("None of the requested endpoints were found in the data.")
  }
  missing_eps <- setdiff(endpoints, present)
  if (length(missing_eps) > 0) {
    warning("Endpoints not found and skipped: ", paste(missing_eps, collapse = ", "))
  }

  # Average-BE point estimates via the mixed model (Method B), fit once for all
  # endpoints, when the framework uses the ANOVA/mixed point estimate.
  fitbe_tbl <- NULL
  if (reg$est_method == "anova" && method == "B") {
    fixed <- paste(c(sequence, period, reference_col), collapse = " + ")
    random <- sprintf("(1|%s)", subject)
    fitbe_tbl <-
      fitbe_calculate(
        data, endpoints = present, reference_col = reference_col,
        reference_value = reference_value, fixed = fixed, random = random, alpha = alpha
      )$table
  }

  rows <- list()
  for (ep in present) {
    data_ep <- data[!is.na(data$PPTESTCD) & data$PPTESTCD == ep, , drop = FALSE]
    data_ep <- data_ep[!is.na(data_ep[[value_col]]) & data_ep[[value_col]] > 0, , drop = FALSE]
    work <- data.frame(
      .subject = factor(as.character(data_ep[[subject]])),
      .period = factor(as.character(data_ep[[period]])),
      .trt = as.character(data_ep[[reference_col]]),
      .logval = log(data_ep[[value_col]]),
      stringsAsFactors = FALSE
    )
    test_levels <- setdiff(unique(work$.trt), reference_value)
    wv <-
      if (reg$scaling != "none") {
        be_within_var(data_ep, value_col, subject, period, reference_col, reference_value, alpha = alpha)
      } else {
        .be_empty_wv(alpha)
      }

    for (tl in test_levels) {
      est <-
        if (reg$est_method == "isc") {
          .be_isc(work, reference_value, tl, alpha)
        } else if (method == "B") {
          fr <- fitbe_tbl[fitbe_tbl$endpoint == ep & fitbe_tbl$test == tl, , drop = FALSE]
          list(
            pe_log = log(fr$gmr_percent / 100), se = NA_real_, df = fr$df, n = NA_integer_,
            gmr_percent = fr$gmr_percent, ci_lower = fr$ci_lower, ci_upper = fr$ci_upper
          )
        } else {
          .be_anova_est(work, reference_value, tl, alpha)
        }
      dec <- .be_decide(est, wv, reg, alpha)
      n_ep <- length(unique(work$.subject[work$.trt %in% c(reference_value, tl)]))
      rows[[length(rows) + 1]] <-
        data.frame(
          endpoint = ep, test = tl, n = n_ep, design = design$design,
          gmr_percent = est$gmr_percent, ci_lower = est$ci_lower, ci_upper = est$ci_upper,
          cvwr_percent = wv$cvwr_percent, cvwt_percent = wv$cvwt_percent, swr = wv$swR,
          limit_lower = dec$limit_lower, limit_upper = dec$limit_upper, criterion = dec$criterion,
          regulator = reg$name, method = method, pass = dec$pass,
          stringsAsFactors = FALSE
        )
    }
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  structure(
    out,
    class = c("be_assess", "data.frame"),
    regulator = reg$name, method = method, design = design$design, alpha = alpha
  )
}

#' @export
as.data.frame.be_assess <- function(x, ...) {
  for (a in c("regulator", "method", "design", "alpha")) {
    attr(x, a) <- NULL
  }
  class(x) <- "data.frame"
  x
}

#' @export
format.be_assess <- function(x, digits = 2, ...) {
  d <- as.data.frame(x)
  round_cols <- c(
    "gmr_percent", "ci_lower", "ci_upper", "cvwr_percent", "cvwt_percent",
    "swr", "limit_lower", "limit_upper"
  )
  for (cc in intersect(round_cols, names(d))) {
    d[[cc]] <- round(d[[cc]], digits)
  }
  if ("criterion" %in% names(d)) {
    d$criterion <- signif(d$criterion, 4)
  }
  d
}

#' @export
print.be_assess <- function(x, ...) {
  cat(sprintf(
    "Bioequivalence assessment: %s (method %s, %g%% CI)\n",
    attr(x, "regulator"), attr(x, "method"), (1 - attr(x, "alpha")) * 100
  ))
  cat(sprintf("Design: %s\n\n", attr(x, "design")))
  print.data.frame(format(x), row.names = FALSE, ...)
  invisible(x)
}

#' @export
summary.be_assess <- function(object, ...) {
  d <- as.data.frame(object)
  keep <- c("endpoint", "test", "gmr_percent", "ci_lower", "ci_upper", "pass")
  out <- d[, intersect(keep, names(d)), drop = FALSE]
  out$gmr_percent <- round(out$gmr_percent, 2)
  out$ci_lower <- round(out$ci_lower, 2)
  out$ci_upper <- round(out$ci_upper, 2)
  caption <- sprintf(
    "%s assessment (method %s, %g%% CI); pass = bioequivalent.",
    attr(object, "regulator"), attr(object, "method"), (1 - attr(object, "alpha")) * 100
  )
  structure(out, class = c("summary_be_assess", "data.frame"), caption = caption)
}

#' @export
print.summary_be_assess <- function(x, ...) {
  print.data.frame(as.data.frame(x), row.names = FALSE, ...)
  cat(paste0("\nCaption: ", attr(x, "caption"), "\n"))
  invisible(x)
}

#' Compare a bioequivalence dataset across regulatory frameworks
#'
#' `be_compare()` runs [be_assess()] under several regulatory frameworks and
#' stacks the results, so the same study can be judged side by side under the
#' different reference-scaling rules.  Frameworks that the design does not
#' support (for example NTID on a partial replicate) are skipped with a warning.
#'
#' @inheritParams be_assess
#' @param regulators A character vector of regulatory frameworks to compare (see
#'   [be_regulator()]).
#' @returns An object of class `be_compare` (a data.frame) with the [be_assess()]
#'   columns for every endpoint, test formulation, and regulator.
#' @family Bioequivalence
#' @seealso [be_assess()]
#' @examplesIf requireNamespace("lme4", quietly = TRUE) && requireNamespace("lmerTest", quietly = TRUE) && requireNamespace("emmeans", quietly = TRUE)
#' set.seed(1)
#' nsub <- 24
#' seqs <- rep(c("TRTR", "RTRT"), length.out = nsub)
#' b <- stats::rnorm(nsub, sd = 0.4)
#' d <- do.call(rbind, lapply(seq_len(nsub), function(i) {
#'   trt <- strsplit(seqs[i], "")[[1]]
#'   data.frame(
#'     subject = i, sequence = seqs[i], period = seq_along(trt), treatment = trt,
#'     PPTESTCD = "auclast",
#'     PPORRES = exp(log(100) + ifelse(trt == "T", 0.04, 0) + b[i] +
#'                     stats::rnorm(length(trt), sd = 0.45)),
#'     stringsAsFactors = FALSE
#'   )
#' }))
#' be_compare(d, reference_col = "treatment", reference_value = "R",
#'            endpoints = "auclast", regulators = c("EMA", "HC", "GCC", "FDA"))
#' @export
be_compare <- function(object, reference_col, reference_value,
                       endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
                       regulators = c("FDA", "EMA", "HC", "GCC"),
                       method = c("B", "A"), alpha = 0.10,
                       subject = NULL, sequence = NULL, period = NULL, design = NULL) {
  method <- match.arg(method)
  checkmate::assert_character(regulators, min.len = 1, any.missing = FALSE)
  results <- list()
  for (rg in regulators) {
    res <- try(
      be_assess(
        object, reference_col = reference_col, reference_value = reference_value,
        endpoints = endpoints, regulator = rg, method = method, alpha = alpha,
        subject = subject, sequence = sequence, period = period, design = design
      ),
      silent = TRUE
    )
    if (inherits(res, "try-error")) {
      warning(sprintf("Skipping %s: %s", rg, conditionMessage(attr(res, "condition"))))
    } else {
      results[[rg]] <- as.data.frame(res)
    }
  }
  if (length(results) == 0) {
    stop("No regulatory framework could be assessed for this design.")
  }
  out <- do.call(rbind, results)
  rownames(out) <- NULL
  structure(
    out,
    class = c("be_compare", "data.frame"),
    regulators = names(results), alpha = alpha
  )
}

#' @export
as.data.frame.be_compare <- function(x, ...) {
  for (a in c("regulators", "alpha")) {
    attr(x, a) <- NULL
  }
  class(x) <- "data.frame"
  x
}

#' @export
print.be_compare <- function(x, ...) {
  cat(sprintf(
    "Bioequivalence comparison across %s (%g%% CI)\n\n",
    paste(attr(x, "regulators"), collapse = ", "), (1 - attr(x, "alpha")) * 100
  ))
  d <- as.data.frame(x)
  show <- c(
    "regulator", "endpoint", "test", "gmr_percent", "ci_lower", "ci_upper",
    "cvwr_percent", "limit_lower", "limit_upper", "criterion", "pass"
  )
  d <- d[, intersect(show, names(d)), drop = FALSE]
  for (cc in intersect(c("gmr_percent", "ci_lower", "ci_upper", "cvwr_percent", "limit_lower", "limit_upper"), names(d))) {
    d[[cc]] <- round(d[[cc]], 2)
  }
  if ("criterion" %in% names(d)) {
    d$criterion <- signif(d$criterion, 4)
  }
  print.data.frame(d, row.names = FALSE, ...)
  invisible(x)
}

#' @export
summary.be_compare <- function(object, ...) {
  d <- as.data.frame(object)
  # Pivot to an endpoint x regulator grid of pass/fail.
  grid <- tapply(
    d$pass,
    list(paste(d$endpoint, d$test, sep = ":"), d$regulator),
    FUN = `[`, 1
  )
  grid <- as.data.frame.matrix(grid)
  grid <- cbind(endpoint = rownames(grid), grid)
  rownames(grid) <- NULL
  # Order regulators as supplied.
  reg_order <- intersect(attr(object, "regulators"), names(grid))
  grid <- grid[, c("endpoint", reg_order), drop = FALSE]
  structure(
    grid,
    class = c("summary_be_compare", "data.frame"),
    caption = "Pass/fail by endpoint and regulator."
  )
}

#' @export
print.summary_be_compare <- function(x, ...) {
  print.data.frame(as.data.frame(x), row.names = FALSE, ...)
  cat(paste0("\nCaption: ", attr(x, "caption"), "\n"))
  invisible(x)
}
