#' Compute the time to steady state using nonlinear, mixed-effects modeling of
#' trough concentrations.
#'
#' Trough concentrations are selected as concentrations at the time of dosing.
#' An exponential curve is then fit through the data with a different magnitude
#' by treatment (as a factor) and a random steady-state concentration and time
#' to stead-state by subject (see `random.effects` argument).
#'
#' The population model is selected by AIC from several candidates (Ctrough,ss
#' and Tss for all treatments or by treatment, with random effects on either
#' or both).  The warnings of nlme are kept with each candidate:  those of the
#' selected model are given as one `pknca_warning_tss_population_fit_warning`
#' that quotes them, and those of the other candidates are not given because
#' they do not bear on the estimate.  The gnls fits of the `individual` and
#' `single` outputs give `pknca_warning_tss_individual_fit_failed` when a fit
#' fails (its estimate is `NA`) and `pknca_warning_tss_individual_fit_warning`
#' when a fit that gives an estimate warns.
#'
#' @param \dots See [pk.tss.data.prep()]
#' @param tss.fraction The fraction of steady-state required for calling
#'   steady-state
#' @param output Which types of outputs should be produced? `population` is the
#'   population estimate for time to steady-state (from an nlme model), `popind`
#'   is the individual estimate (from an nlme model), `individual` fits each
#'   individual separately with a gnls model (requires more than one individual;
#'   use `single` for one individual), and `single` fits all the data of each
#'   treatment (or all the data, without treatment) to one gnls model.
#' @param check See [pk.tss.data.prep()].
#' @param verbose Describe models as they are run, show convergence of the model
#'   (passed to the nlme function), and additional details while running.
#' @param level The confidence level of the intervals of the estimates (in the
#'   `"estimates"` attribute).  With [pk.tss()], `level` is also the level of
#'   the stepwise linear test.
#'
#' @section Confidence intervals:
#'
#' The `"estimates"` attribute gives a confidence interval (`lower` and
#' `upper`) where one can be defended:
#'
#' \describe{
#'   \item{population}{The approximate (Wald) interval of `nlme::intervals()`
#'     for the fixed effect of Tss:  the estimate plus or minus a t quantile
#'     (with the nlme degrees of freedom for the fixed effects, which count the
#'     observations, so it is close to a normal quantile) times the standard
#'     error from the linearized covariance of nlme (`vcov()` of the fit, without
#'     the small-sample factor that `summary()` gives the standard errors of a
#'     maximum likelihood fit).  It assumes that the
#'     monoexponential model is right, that the random effects and residuals
#'     are normal and the residuals have constant variance, and that the
#'     linearization holds near the estimate.  It is symmetric on the Tss
#'     scale, so with poor data it can include zero or negative values; it is
#'     reported as computed.}
#'   \item{individual, and single with one subject}{The approximate (Wald)
#'     interval of `nlme::intervals()` for the gnls fit:  a t quantile with the
#'     number of troughs less two degrees of freedom.  It assumes independent,
#'     normal residuals with constant variance; with few troughs, its coverage
#'     is approximate.}
#'   \item{popind}{None:  these are predictions of random effects, for which
#'     nlme gives no standard errors.}
#'   \item{single with several subjects}{None:  the troughs of a subject are
#'     correlated, so an interval that treats them as independent is too
#'     narrow.  Without `subject`, the number of subjects is not known, so there
#'     is no interval either.}
#' }
#'
#' @returns A data frame with the requested `tss.monoexponential.*` columns,
#'   and `subject` and `treatment` columns for the outputs that are by subject
#'   or by treatment.  The population output has one row per subject (and
#'   treatment).  A monoexponential Tss is estimated from the fitted curve, so
#'   it can be later than the last trough; `NA` means that the fit failed.  The
#'   attribute `"estimates"` says how each estimate came about (see
#'   [pk.tss()]).
#' @family Time to steady-state calculations
#' @references
#' Maganti, L., Panebianco, D.L. & Maes, A.L. Evaluation of Methods for
#' Estimating Time to Steady State with Examples from Phase 1 Studies. AAPS J
#' 10, 141–147 (2008). https://doi.org/10.1208/s12248-008-9014-y
#' @export
pk.tss.monoexponential <- function(...,
                                   tss.fraction=0.9,
                                   output=c(
                                     "population",
                                     "popind",
                                     "individual",
                                     "single"),
                                   check=TRUE,
                                   verbose=FALSE,
                                   level=0.95) {
  # Check inputs
  modeldata <- pk.tss.data.prep(..., check=check)
  # Without a subject column, the data have one subject only when a subject
  # was given (pk.tss.data.prep() drops the column for one subject).  The
  # arguments are matched as pk.tss.data.prep() matches them, so a subject
  # given by position counts.
  subject_given <-
    "subject" %in%
    names(match.call(pk.tss.data.prep, call=quote(pk.tss.data.prep(...)), envir=environment()))
  if (length(level) > 1) {
    rlang::warn("Only first value of level is being used", class = "pknca_warning_tss_level_multiple")
    level <- level[1]
  }
  checkmate::assert_number(level, na.ok = FALSE)
  if (level <= 0 || level >= 1) {
    rlang::abort("level must be between 0 and 1, exclusive", class = "pknca_error_tss_level_range")
  }
  if (length(tss.fraction) > 1) {
    rlang::warn("Only first value of tss.fraction is being used", class = "pknca_warning_tss_fraction_multiple")
    tss.fraction <- tss.fraction[1]
  }
  checkmate::assert_number(tss.fraction, na.ok = FALSE)

  if (tss.fraction <= 0 || tss.fraction >= 1) {
    rlang::abort("tss.fraction must be between 0 and 1, exclusive", class = "pknca_error_tss_fraction_range")
  } else if (tss.fraction < 0.8) {
    rlang::warn("tss.fraction is usually >= 0.8", class = "pknca_warning_tss_fraction_small")
  }
  # Note that this will by default choose "population" if nothing is
  # requested.
  output <- match.arg(output, several.ok=TRUE)
  # The outputs that need more than one subject, when the data have one (or
  # no subject was given)
  output_no_subjects <- character()
  if (!("subject" %in% names(modeldata))) {
    output_no_subjects <- intersect(c("population", "popind", "individual"), output)
    if (length(output_no_subjects) > 0) {
      msg_no_subjects <-
        "Cannot give 'population', 'popind', or 'individual' output without multiple subjects of data"
      rlang::warn(msg_no_subjects, class = "pknca_warning_tss_output_no_subjects")
      output <- setdiff(output, output_no_subjects)
    }
  }
  estimates_no_subjects <-
    if (length(output_no_subjects) > 0) {
      tss_estimates_table(
        type="monoexponential", output=output_no_subjects, estimate=NA_real_, level=level,
        status="insufficient_data", message=msg_no_subjects
      )
    }
  # Set the tss.constant so that exp(tss.constant) == tss.fraction so
  # that the model below solves for the requested tss.
  modeldata$tss.constant <- log(1-tss.fraction)
  ret_population <-
    if (any(c("population", "popind") %in% output)) {
      pk.tss.monoexponential.population(
        modeldata,
        output=intersect(c("population", "popind"), output),
        verbose=verbose,
        level=level)
    } else {
      NA
    }
  ret_individual <-
    if (any(c("individual", "single") %in% output)) {
      pk.tss.monoexponential.individual(
        modeldata,
        output=intersect(c("individual", "single"), output),
        verbose=verbose,
        level=level,
        subject_given=subject_given)
    } else {
      NA
    }
  ret <-
    if (!identical(NA, ret_population) && !identical(NA, ret_individual)) {
      merge(ret_population, ret_individual)
    } else if (!identical(NA, ret_population)) {
      ret_population
    } else if (!identical(NA, ret_individual)) {
      ret_individual
    } else if (length(output_no_subjects) > 0) {
      # Every requested output needs more than one subject:  one row of NA
      stats::setNames(
        as.data.frame(as.list(rep(NA_real_, length(output_no_subjects)))),
        paste("tss.monoexponential", output_no_subjects, sep=".")
      )
    } else {
      rlang::abort("Error in selection of return values for pk.tss.monoexponential. This is likely a bug.", class = "pknca_error_internal_tss_return_selection")  # nocov
    }
  tss_set_estimates(
    ret,
    rbind(
      attr(ret_population, "estimates"),
      attr(ret_individual, "estimates"),
      estimates_no_subjects
    )
  )
}

#' A helper function to generate the formula and starting values for the
#' parameters in monoexponential models.
#'
#' @param data The data used for the model
#' @returns a list with elements for each of the variables
tss.monoexponential.generate.formula <- function(data) {
  # Setup the correct ctrough.ss by treatment or not.
  if ("treatment" %in% names(data)) {
    ctrough_by <-
      list(
        "Ctrough.ss by treatment"=
          list(
            formula=ctrough.ss~treatment-1,
            # Set the starting values for the ctrough.ss as the mean
            # concentration by treatment
            start=dplyr::summarize(
              dplyr::grouped_df(data, vars = "treatment"),
              dplyr::across(.cols=dplyr::all_of("conc"), .fns = mean)
            )$conc
          )
      )
  } else {
    ctrough_by <-
      list("Single Ctrough.ss"=list(
        formula=ctrough.ss~1,
        # Set the starting values for the ctrough.ss as the mean
        # concentration.
        start=mean(data$conc)))
  }
  # Try all combinations of Tss by treatment and single value
  tss.by <- list(
    "Single value for Tss"=list(
      formula=tss~1,
      start=stats::median(unique(data$time))))
  # Without an intercept, each treatment's Tss is its own coefficient
  # ("tss.treatmentA", ...), so its estimate and interval are read directly.
  if ("treatment" %in% names(data))
    tss.by[["Tss by treatment"]] <- list(
      formula=tss~treatment-1,
      start=rep(stats::median(unique(data$time)),
        length(unique(data$treatment))))
  # Try combinations of random effects with Ctrough.ss and
  # Tss. (These are returned even if they aren't always used)
  ranef.by <-
    list("Ctrough.ss and Tss"=list(formula=ctrough.ss+tss~1|subject),
         "Tss"=list(formula=tss~1|subject),
         "Ctrough.ss"=list(formula=ctrough.ss~1|subject))
  # Return the list of parameters to test
  list(
    ctrough.by=ctrough_by,
    tss.by=tss.by,
    ranef.by=ranef.by
  )
}

#' A helper function to estimate population and popind outputs for
#' monoexponential time to steady-state.
#'
#' This function is not intended to be called directly.  Please use
#' `pk.tss.monoexponential`.
#'
#' If no model converges, then the `tss.monoexponential.population` column will
#' be set to NA. If the best model does not include a random effect for subject
#' on Tss then the `tss.monoexponential.popind` column of the output will be set
#' to NA.
#'
#' @param data a data frame as prepared by [pk.tss.data.prep()].  It must
#'   contain at least columns for `subject`, `time`, `conc`, and `tss.constant`.
#' @param output a character vector requesting the output types.
#' @param verbose Show verbose output.
#' @param level The confidence level of the interval of the population Tss
#' @returns A data frame with one row per subject (and treatment, when the
#'   data have more than one), with columns `subject`, `treatment` (when the
#'   data have it), and `tss.monoexponential.population` and/or
#'   `tss.monoexponential.popind`.  When the selected model has a Tss by
#'   treatment, `tss.monoexponential.population` is the Tss of the row's
#'   treatment.
pk.tss.monoexponential.population <- function(data,
                                              output=c(
                                                "population",
                                                "popind"),
                                              verbose=FALSE,
                                              level=0.95) {
  output <- match.arg(output, several.ok=TRUE)
  test.formula <- tss.monoexponential.generate.formula(data)
  # Loop over creating all models
  models <- list()
  for (myctrough.ss in names(test.formula$ctrough.by)) {
    for (mytss in names(test.formula$tss.by)) {
      for (myranef in names(test.formula$ranef.by)) {
        # Describe the current model
        current.desc <-
          sprintf("Fixed effects of %s and %s; random effects of %s",
                  myctrough.ss, mytss, myranef)
        if (verbose)
          print(current.desc)
        # Be prepared for failure
        current.model <- NA
        current.aic <- NA
        current.model.summary <- "Did not converge"
        # The warnings of each candidate are kept with it:  only those of the
        # selected model bear on the estimate.
        current.warnings <- pknca_condition_collector()
        try({
          # Test the current model
          current.model <-
            pknca_collect_warnings(
              nlme::nlme(conc~ctrough.ss*(1-exp(tss.constant*time/tss)),
                         fixed=list(
                           test.formula$ctrough.by[[myctrough.ss]]$formula,
                           test.formula$tss.by[[mytss]]$formula),
                         random=test.formula$ranef.by[[myranef]]$formula,
                         start=c(
                           test.formula$ctrough.by[[myctrough.ss]]$start,
                           test.formula$tss.by[[mytss]]$start),
                         data=data,
                         verbose=verbose),
              current.warnings
            )
          # If the model converges, get the summary and AIC out.
          if (!is.null(current.model)) {
            current.model.summary <- summary(current.model)
            current.aic <- stats::AIC(current.model)
          }
        }, silent=!verbose)
        # Put the current model (or model attempt) into the list of
        # models.
        models <-
          append(
            models,
            list(
              list(
                desc=current.desc,
                model=current.model,
                summary=current.model.summary,
                AIC=current.aic,
                warnings=
                  vapply(
                    X=current.warnings$conditions, FUN=conditionMessage, FUN.VALUE="",
                    USE.NAMES=FALSE
                  )
              )
            )
          )
      }
    }
  }
  # Find the best model of the set and return the output from that one.
  all.model.summary <- AIC.list(lapply(models, function(x) x$model))
  rownames(all.model.summary) <-
    vapply(
      X = models,
      FUN = function(x) x$desc,
      FUN.VALUE = ""
    )
  if (verbose)
    print(all.model.summary)
  # One row per subject (and treatment, so that a subject's row joins the rows
  # of its treatment in other outputs)
  ret <- tss_population_rows(data)
  if (all(is.na(all.model.summary$AIC)) ||
      length(all.model.summary) == 0) {
    msg_no_convergence <- "No population model for monoexponential Tss converged, no results given"
    rlang::warn(
      msg_no_convergence,
      class = "pknca_warning_tss_population_no_convergence"
    )
    ret$tss.monoexponential.population <- NA_real_
    ret$tss.monoexponential.popind <- NA_real_
    estimates_population <-
      tss_estimates_table(
        type="monoexponential", output="population", estimate=NA_real_, level=level,
        status="fit_failed", message=msg_no_convergence
      )
    estimates_popind <-
      tss_estimates_table(
        type="monoexponential", output="popind",
        treatment=ret$treatment %||% NA, subject=ret$subject, estimate=NA_real_, level=level,
        status="fit_failed", message=msg_no_convergence
      )
  } else {
    best <-
      models[all.model.summary$AIC %in%
             min(all.model.summary$AIC, na.rm=TRUE)][[1]]
    best.model <- best$model
    if (length(best$warnings) > 0) {
      rlang::warn(
        sprintf(
          "The selected population model for monoexponential Tss (%s) gave warnings while fitting: %s",
          best$desc, paste(best$warnings, collapse="; ")
        ),
        class = "pknca_warning_tss_population_fit_warning"
      )
    }
    ret$tss.monoexponential.population <-
      tss_population_fixef(best.model, treatment = ret$treatment)
    best.ranef <- nlme::ranef(best.model)
    # The random effect is "tss" with one Tss and "tss.(Intercept)" with a Tss
    # by treatment
    col_ranef_tss <- grep("^tss", names(best.ranef), value=TRUE)
    fit_warning <-
      if (length(best$warnings) > 0) {
        paste(best$warnings, collapse="; ")
      } else {
        NA_character_
      }
    estimates_population <-
      tss_population_estimates(best.model, data=data, fit_warning=fit_warning, level=level)
    if (length(col_ranef_tss) == 1) {
      ret$tss.monoexponential.popind <-
        ret$tss.monoexponential.population +
        best.ranef[as.character(ret$subject), col_ranef_tss]
      last_time <- tss_last_time(data, treatment=ret$treatment %||% NA, subject=ret$subject)
      status_popind <- tss_estimate_status(ret$tss.monoexponential.popind, last_time)
      estimates_popind <-
        tss_estimates_table(
          type="monoexponential", output="popind",
          treatment=ret$treatment %||% NA, subject=ret$subject,
          estimate=ret$tss.monoexponential.popind, level=level,
          status=status_popind, fit_warning=fit_warning,
          message=
            tss_join_messages(
              tss_not_reached_message(status_popind, last_time),
              "No confidence interval: individual estimates of a mixed-effects model are predictions of random effects, for which nlme gives no standard errors"
            )
        )
    } else {
      if ("popind" %in% output) {
        rlang::warn(
          "tss.monoexponential.popind was requested, but the best model did not include a random effect for tss.  Set to NA.",
          class = "pknca_warning_tss_popind_no_random_effect"
        )
      }
      ret$tss.monoexponential.popind <- NA_real_
      estimates_popind <-
        tss_estimates_table(
          type="monoexponential", output="popind",
          treatment=ret$treatment %||% NA, subject=ret$subject, estimate=NA_real_, level=level,
          status="no_random_effect", fit_warning=fit_warning,
          message="The selected population model has no random effect on Tss, so there are no individual estimates"
        )
    }
  }
  # Return the requested columns
  ret <-
    ret[,intersect(c("subject", "treatment",
                     paste("tss.monoexponential", output, sep=".")),
                   names(ret)),
        drop=FALSE]
  tss_set_estimates(
    ret,
    rbind(
      if ("population" %in% output) estimates_population,
      if ("popind" %in% output) estimates_popind
    )
  )
}

#' The population Tss estimates of the selected model, as estimate rows
#'
#' @param model The selected `nlme` model
#' @param data The data of [pk.tss.monoexponential.population()]
#' @param fit_warning The warnings of the model, or `NA`
#' @param level The confidence level of the interval
#' @returns The `tss_estimates_table()` rows of the population output:  one
#'   with a `NA` treatment when the model has one Tss for all treatments, or
#'   one per treatment when the model has one by treatment
#' @keywords Internal
#' @noRd
tss_population_estimates <- function(model, data, fit_warning, level) {
  fixef <- nlme::fixef(model)
  if ("tss" %in% names(fixef)) {
    treatment <- NA_character_
    name <- "tss"
  } else {
    treatment <- as.character(sort(unique(data$treatment)))
    name <- paste0("tss.treatment", treatment)
  }
  estimate <- unname(fixef[name])
  interval <- tss_model_interval(model, name=name, level=level)
  last_time <- tss_last_time(data, treatment=treatment)
  status <- tss_estimate_status(estimate, last_time)
  tss_estimates_table(
    type="monoexponential", output="population", treatment=treatment,
    estimate=estimate, lower=interval$lower, upper=interval$upper, level=level,
    status=status, fit_warning=fit_warning,
    message=tss_join_messages(tss_not_reached_message(status, last_time), interval$message)
  )
}

#' The rows of the population output: one per subject and treatment
#'
#' @param data The data of [pk.tss.monoexponential.population()]
#' @returns A data frame with the `subject` (and `treatment`) columns of
#'   `data`, one row for each combination in the data, ordered by subject
#' @keywords Internal
#' @noRd
tss_population_rows <- function(data) {
  ret <- unique(data[, intersect(c("subject", "treatment"), names(data)), drop=FALSE])
  ret <- ret[do.call(order, unname(as.list(ret))), , drop=FALSE]
  rownames(ret) <- NULL
  ret
}

#' The population Tss of each row from the selected model
#'
#' @param model The selected `nlme` model
#' @param treatment The treatment of each row (`NULL` without treatment)
#' @returns The Tss of each row:  the one Tss when the model has one, or the
#'   Tss of the row's treatment when the model has one by treatment
#' @keywords Internal
#' @noRd
tss_population_fixef <- function(model, treatment) {
  fixef <- nlme::fixef(model)
  if ("tss" %in% names(fixef)) {
    rep(fixef[["tss"]], max(1, length(treatment)))
  } else {
    unname(fixef[paste0("tss.treatment", as.character(treatment))])
  }
}

#' A helper function to estimate individual and single outputs for
#' monoexponential time to steady-state.
#'
#' This function is not intended to be called directly.  Please use
#' `pk.tss.monoexponential`.
#'
#' If no model converges, then the `tss.monoexponential.single` and/or
#' `tss.monoexponential.individual` column will be set to NA.
#'
#' @param data a data frame as prepared by [pk.tss.data.prep()].  It must
#'   contain at least columns for `subject`, `time`, `conc`, and `tss.constant`.
#' @param output a character vector requesting the output types.
#' @param verbose Show verbose output.
#' @param level The confidence level of the intervals
#' @param subject_given Was a subject given?  (Without a `subject` column in
#'   `data`, this says whether the data have one subject or an unknown number.)
#' @returns A data frame with one row per treatment (or one row, without
#'   treatment) for `single`, and one row per subject (and treatment) for
#'   `individual`, with columns `tss.monoexponential.single` and/or
#'   `tss.monoexponential.individual`.
#' @importFrom rlang .data %||%
pk.tss.monoexponential.individual <- function(data,
                                              output=c(
                                                "individual",
                                                "single"),
                                              verbose=FALSE,
                                              level=0.95,
                                              subject_given=TRUE) {
  output <- match.arg(output, several.ok=TRUE)
  if (!("subject" %in% names(data))) {
    output <- setdiff(output, "individual")
  }
  if (length(output) == 0) {
    rlang::abort("Please report a bug. Subject must be specified to have subject-level fitting", class = "pknca_error_internal_tss_no_subject_for_individual")  # nocov
  }
  ret <- NULL
  failures <- character()
  fit_warnings <- character()
  estimates <- NULL
  if ("single" %in% output) {
    # Fit each treatment (or all the data, without treatment)
    fits <-
      tss_fit_gnls_groups(
        data, cols=intersect("treatment", names(data)), verbose=verbose
      )
    ret <- fits$groups
    ret$tss.monoexponential.single <- fits$estimate
    failures <- tss_gnls_failures(fits, output="single")
    fit_warnings <- tss_gnls_warnings(fits, output="single")
    estimates <-
      tss_gnls_estimates(fits, data=data, output="single", level=level, subject_given=subject_given)
  }
  if ("individual" %in% output) {
    fits_sub <-
      tss_fit_gnls_groups(
        data, cols=intersect(c("treatment", "subject"), names(data)), verbose=verbose
      )
    ret_sub <- fits_sub$groups
    ret_sub$tss.monoexponential.individual <- fits_sub$estimate
    ret <- if (is.null(ret)) ret_sub else merge(ret, ret_sub, all=TRUE)
    failures <- c(failures, tss_gnls_failures(fits_sub, output="individual"))
    fit_warnings <- c(fit_warnings, tss_gnls_warnings(fits_sub, output="individual"))
    estimates <-
      rbind(
        estimates,
        tss_gnls_estimates(fits_sub, data=data, output="individual", level=level, subject_given=subject_given)
      )
  }
  if (length(failures) > 0) {
    rlang::warn(
      paste0(
        "A monoexponential gnls fit for Tss failed, so its estimate is NA:\n",
        paste(failures, collapse="\n")
      ),
      class="pknca_warning_tss_individual_fit_failed"
    )
  }
  if (length(fit_warnings) > 0) {
    rlang::warn(
      paste0(
        "A monoexponential gnls fit for Tss gave warnings while fitting:\n",
        paste(fit_warnings, collapse="\n")
      ),
      class="pknca_warning_tss_individual_fit_warning"
    )
  }
  # Return the requested columns
  ret <-
    as.data.frame(
      ret[,c(intersect(names(ret), c("subject", "treatment")),
             paste("tss.monoexponential", output, sep=".")),
          drop=FALSE]
    )
  tss_set_estimates(ret, estimates)
}

#' The estimates of gnls fits, as estimate rows
#'
#' The interval of a gnls fit is given only for the troughs of one subject:  a
#' subject's troughs are correlated, so an interval that treats the troughs of
#' several subjects as independent is too narrow.
#'
#' @inheritParams tss_gnls_group_text
#' @inheritParams pk.tss.monoexponential.individual
#' @param data The data that was fit
#' @returns The `tss_estimates_table()` rows of the fits, one per group
#' @keywords Internal
#' @noRd
tss_gnls_estimates <- function(fits, data, output, level, subject_given) {
  groups <- fits$groups
  treatment <- if ("treatment" %in% names(groups)) groups$treatment else NA
  subject <- if ("subject" %in% names(groups)) groups$subject else NA
  last_time <- tss_last_time(data, treatment=treatment, subject=subject)
  status <- tss_estimate_status(fits$estimate, last_time)
  fit_warning <- vapply(X=fits$warnings, FUN=paste, FUN.VALUE="", collapse="; ")
  fit_warning[!nzchar(fit_warning)] <- NA_character_
  # Without a subject column, there is one subject when one was given and an
  # unknown number otherwise
  n_subject <- fits$n_subject
  n_subject[is.na(n_subject) & subject_given] <- 1L
  lower <- upper <- rep(NA_real_, nrow(groups))
  message_interval <- rep(NA_character_, nrow(groups))
  for (idx in seq_len(nrow(groups))) {
    if (is.null(fits$model[[idx]])) {
      # The failure is the message
    } else if (is.na(n_subject[idx])) {
      message_interval[idx] <-
        "No confidence interval: without subject, the troughs may come from several subjects, and the troughs of a subject are correlated"
    } else if (n_subject[idx] > 1) {
      message_interval[idx] <-
        "No confidence interval: the troughs of several subjects are pooled, and the troughs of a subject are correlated"
    } else {
      interval <- tss_model_interval(fits$model[[idx]], name="tss", level=level)
      lower[idx] <- interval$lower
      upper[idx] <- interval$upper
      message_interval[idx] <- interval$message
    }
  }
  tss_estimates_table(
    type="monoexponential", output=output, treatment=treatment, subject=subject,
    estimate=fits$estimate, lower=lower, upper=upper, level=level,
    status=status, fit_warning=fit_warning,
    message=
      ifelse(
        is.na(fits$failure),
        tss_join_messages(tss_not_reached_message(status, last_time), message_interval),
        fits$failure
      )
  )
}

#' Fit the monoexponential gnls model to each group of the data
#'
#' @param data The data of [pk.tss.monoexponential.individual()]
#' @param cols The columns that define a group (none for all the data)
#' @param verbose Passed to [nlme::gnls()], and show the errors of failed fits
#' @returns A list with `groups` (a data frame of the `cols` with one row per
#'   group, ordered by them; one row and no columns without `cols`) and, with
#'   one element per group, `model` (the fit, or `NULL` when it failed),
#'   `estimate` (the Tss, `NA` when the fit failed), `failure` (the error of a
#'   failed fit, or `NA`), `warnings` (the warnings of the fit), and
#'   `n_subject` (the number of subjects in the group, `NA` without a `subject`
#'   column)
#' @keywords Internal
#' @noRd
tss_fit_gnls_groups <- function(data, cols, verbose) {
  if (length(cols) == 0) {
    groups <- data.frame(row.names=1L)
  } else {
    groups <- unique(data[, cols, drop=FALSE])
    groups <- groups[do.call(order, unname(as.list(groups))), , drop=FALSE]
    rownames(groups) <- NULL
  }
  ret <-
    list(
      groups=groups, model=list(), estimate=numeric(), failure=character(), warnings=list(),
      n_subject=integer()
    )
  for (idx in seq_len(nrow(groups))) {
    mask <- rep(TRUE, nrow(data))
    for (col in cols) {
      mask <- mask & data[[col]] %in% groups[[col]][idx]
    }
    fit <- tss_fit_gnls(data[mask, , drop=FALSE], verbose=verbose)
    ret$model[idx] <- list(fit$model)
    ret$estimate[idx] <- fit$estimate
    ret$failure[idx] <- fit$failure
    ret$warnings[[idx]] <- fit$warnings
    ret$n_subject[idx] <-
      if ("subject" %in% names(data)) {
        length(unique(data$subject[mask]))
      } else {
        NA_integer_
      }
  }
  ret
}

#' Fit the monoexponential gnls model to one set of troughs
#'
#' @inheritParams tss_fit_gnls_groups
#' @returns A list with `model`, `estimate`, `failure`, and `warnings` as
#'   described in `tss_fit_gnls_groups()`
#' @keywords Internal
#' @noRd
tss_fit_gnls <- function(data, verbose) {
  collector <- pknca_condition_collector()
  if (verbose) {
    model <- tss_try_gnls(data, verbose=verbose, collector=collector)
  } else {
    # gnls() prints why it returns NULL; the reason is in `failure` instead
    utils::capture.output(model <- tss_try_gnls(data, verbose=verbose, collector=collector))
  }
  warnings <- vapply(X=collector$conditions, FUN=conditionMessage, FUN.VALUE="", USE.NAMES=FALSE)
  if (inherits(model, "try-error")) {
    list(
      model=NULL, estimate=NA_real_,
      failure=conditionMessage(attr(model, "condition")), warnings=warnings
    )
  } else if (is.null(model)) {
    # The only reason that nlme::gnls() returns NULL
    list(
      model=NULL, estimate=NA_real_,
      failure="approximate covariance matrix for parameter estimates not of full rank",
      warnings=warnings
    )
  } else {
    list(
      model=model, estimate=stats::coef(model)[["tss"]],
      failure=NA_character_, warnings=warnings
    )
  }
}

#' Try the monoexponential gnls fit, keeping its warnings
#'
#' @inheritParams tss_fit_gnls
#' @param collector Where to keep the warnings (`pknca_condition_collector()`)
#' @returns The `gnls` fit, `NULL` (when gnls() gives none), or a `try-error`
#' @keywords Internal
#' @noRd
tss_try_gnls <- function(data, verbose, collector) {
  try(
    pknca_collect_warnings(
      nlme::gnls(
        conc~ctrough.ss*(1-exp(tss.constant*time/tss)),
        params=list(
          ctrough.ss~1,
          tss~1),
        start=c(
          mean(data$conc),
          stats::median(unique(data$time))),
        data=data,
        verbose=verbose
      ),
      collector
    ),
    silent=!verbose
  )
}

#' Describe the group of each gnls fit
#'
#' @param fits The result of `tss_fit_gnls_groups()`
#' @param output The output that the fits are for ("single" or "individual")
#' @returns A character vector with one description per group, such as
#'   "single (treatment A)" or "individual (subject 3)"
#' @keywords Internal
#' @noRd
tss_gnls_group_text <- function(fits, output) {
  groups <- fits$groups
  if (ncol(groups) == 0) {
    rep(output, nrow(groups))
  } else {
    labels <- rep("", nrow(groups))
    for (col in names(groups)) {
      labels <- paste0(labels, ifelse(nzchar(labels), ", ", ""), col, " ", as.character(groups[[col]]))
    }
    sprintf("%s (%s)", output, labels)
  }
}

#' The failed gnls fits, described for a warning
#'
#' @inheritParams tss_gnls_group_text
#' @returns A character vector with one line per failed fit
#' @keywords Internal
#' @noRd
tss_gnls_failures <- function(fits, output) {
  mask <- !is.na(fits$failure)
  sprintf("%s: %s", tss_gnls_group_text(fits, output)[mask], fits$failure[mask])
}

#' The warnings of the gnls fits that gave an estimate, described for a warning
#'
#' @inheritParams tss_gnls_group_text
#' @returns A character vector with one line per fit with warnings
#' @keywords Internal
#' @noRd
tss_gnls_warnings <- function(fits, output) {
  text <- vapply(X=fits$warnings, FUN=paste, FUN.VALUE="", collapse="; ")
  mask <- is.na(fits$failure) & nzchar(text)
  sprintf("%s: %s", tss_gnls_group_text(fits, output)[mask], text[mask])
}
