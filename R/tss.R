#' Clean up the time to steady-state parameters and return a data frame for use
#' by the tss calculators.
#'
#' @inheritParams assert_conc_time
#' @inheritParams PKNCA.choose.option
#' @param subject Subject identifiers (used as a random effect in the model)
#' @param treatment Treatment description (if missing, all subjects are assumed
#'   to be on the same treatment)
#' @param subject.dosing Subject number for dosing
#' @param time.dosing Time of dosing
#' @inheritParams clean.conc.blq
#' @param \dots Discarded inputs to allow generic calls between tss methods.
#' @details When `subject` is given and `check` is `TRUE`, two concentrations
#'   for the same subject, treatment (if given), and time are an error
#'   (`pknca_error_tss_duplicate_rows`, also of class
#'   `pknca_error_duplicate_rows`): they are usually records that another
#'   group column separates (such as plasma and blood), and fitting them
#'   together gives a wrong estimate.  Without `subject`, repeated times are
#'   pooled troughs and are allowed (with `treatment`).  A dose recorded more
#'   than once for a subject and time selects its trough once.
#' @returns a data frame with columns for `conc`entration, `time`, `subject`,
#'   and `treatment`.
pk.tss.data.prep <- function(conc, time, subject, treatment,
                             subject.dosing, time.dosing,
                             options=list(),
                             conc.blq=NULL,
                             conc.na=NULL,
                             check=TRUE, ...) {
  if (check) {
    # When subject and time are not given, then monotonicity tests for
    # time are not required.
    sorted_time <- missing(subject) & missing(treatment)
    assert_conc_time(conc = conc, time = time, sorted_time = sorted_time)
  }
  if (!missing(subject.dosing) && missing(subject)) {
    rlang::abort("Cannot give subject.dosing without subject", class = "pknca_error_tss_subject_dosing_without_subject")
  }
  if (anyNA(time.dosing)) {
    rlang::abort("time.dosing may not contain any NA values", class = "pknca_error_tss_time_dosing_na")
  }
  if (check && !missing(subject)) {
    # Without a subject, repeated times are pooled (or sparse) troughs; with a
    # subject, they are records that need a group to tell them apart (such as
    # plasma and blood).
    key_data <-
      if (missing(treatment)) {
        data.frame(time = time, subject = subject)
      } else {
        data.frame(time = time, subject = subject, treatment = treatment)
      }
    abort_duplicate_rows(
      mask_dup = duplicated(key_data),
      key_cols = c(setdiff(names(key_data), "time"), "time"),
      data_type = "time to steady-state concentration",
      class = "pknca_error_tss_duplicate_rows"
    )
  }
  if (!missing(subject)) {
    if (!missing(treatment)) {
      ret <-
        clean.conc.blq(
          conc = conc, time = time,
          conc.blq = conc.blq, conc.na = conc.na, options = options,
          check = FALSE,
          subject, treatment
        )
    } else {
      ret <-
        clean.conc.blq(
          conc = conc, time = time,
          conc.blq = conc.blq, conc.na = conc.na, options = options,
          check = FALSE,
          subject
        )
    }
  } else if (missing(treatment)) {
    ret <-
      clean.conc.blq(
        conc = conc, time = time,
        conc.blq = conc.blq, conc.na = conc.na, options = options,
        check = FALSE
      )
  } else {
    ret <-
      clean.conc.blq(
        conc = conc, time = time,
        conc.blq = conc.blq, conc.na = conc.na, options = options,
        check = FALSE,
        treatment
      )
  }
  if (missing(subject.dosing)) {
    # Shrink the data to just the predose data
    ret <- subset(ret, time %in% time.dosing)
  } else {
    # A dose time only marks a trough, so repeated dose records (such as two
    # tablets recorded as two rows) select the trough once.
    dosing <-
      unique(data.frame(
        subject=subject.dosing,
        time=time.dosing
      ))
    # Shrink the data to just the predose data (by subject)
    ret <- merge(ret, dosing)
  }
  # Clean out unnecessary parts of the output data frame
  if ("subject" %in% names(ret)) {
    if (length(unique(ret$subject)) == 1) {
      # Drop the "subject" column from single-subject data
      ret$subject <- NULL
    } else if (!is.factor(ret$subject)) {
      # Make sure that it is a factor made from a character vector because the
      # output subject numbering will come from row.names of the random
      # effects.
      ret$subject <- factor(as.character(ret$subject))
    }
  }
  if ("treatment" %in% names(ret)) {
    if (length(unique(ret$treatment)) == 1) {
      # Drop the "treatment" column from single-treatment data
      ret$treatment <- NULL
    } else if (!is.factor(ret$treatment)) {
      # Make sure that it is a factor otherwise
      ret$treatment <- factor(ret$treatment)
    }
  }
  ret
}

#' Compute the time to steady-state (tss)
#'
#' @param \dots Passed to [pk.tss.monoexponential()] or
#'   [pk.tss.stepwise.linear()].
#' @param check See [pk.tss.data.prep()]
#' @param type The type of Tss to calculate, either `stepwise.linear` or
#'   `monoexponential`
#' @returns A data frame with columns as defined from `pk.tss.monoexponential`
#'   and/or `pk.tss.stepwise.linear`, with an attribute `"estimates"` that
#'   says how each estimate came about (see below).
#'
#' @section The estimates attribute:
#'
#' `attr(result, "estimates")` is a data frame with one row per estimate:  one
#' for each output of the monoexponential method (one row for the population
#' Tss, or one per treatment when the selected model has a Tss by treatment;
#' one per subject for `popind` and `individual`; one per treatment for
#' `single`) and one for the stepwise linear method.  Its columns are:
#'
#' \describe{
#'   \item{type}{`"monoexponential"` or `"stepwise.linear"`}
#'   \item{output}{The monoexponential output (`"population"`, `"popind"`,
#'     `"individual"`, or `"single"`), `NA` for stepwise linear}
#'   \item{treatment, subject}{The treatment and subject of the estimate, or
#'     `NA` when it is for all of them (the stepwise linear estimate is always
#'     for all treatments)}
#'   \item{estimate}{The time to steady state, the value in the result's
#'     column}
#'   \item{lower, upper}{The confidence interval of the estimate, `NA` where
#'     there is none (see the section "Confidence intervals" of
#'     [pk.tss.monoexponential()]; there is none for stepwise linear)}
#'   \item{level}{The confidence level:  of the interval, or for stepwise
#'     linear, of its test}
#'   \item{status}{Why the estimate is or is not there:
#'     \describe{
#'       \item{`"estimated"`}{Steady state is estimated within the data.}
#'       \item{`"not_reached"`}{Steady state is not observed in the data.  A
#'         monoexponential estimate is still given:  it is extrapolated from
#'         the fitted curve beyond the last trough.  The stepwise linear
#'         estimate is `NA`:  the slope of the troughs is significant from every
#'         start time.}
#'       \item{`"fit_failed"`}{The model could not be fit (for stepwise linear,
#'         from at least one start time, so steady state may have been missed);
#'         the estimate is `NA`.}
#'       \item{`"insufficient_data"`}{Fewer dose times than `min.points`
#'         (stepwise linear), or troughs from one subject for the
#'         `population`, `popind`, or `individual` output, which need several;
#'         the estimate is `NA`.  When another output is requested, those
#'         outputs are left out of the result and are only in this table.}
#'       \item{`"no_random_effect"`}{`popind` was requested, but the selected
#'         population model has no random effect on Tss; the estimate is `NA`.}
#'     }}
#'   \item{fit_warning}{The warnings from fitting the model that gave the
#'     estimate (separated by "; "), or `NA`.  An estimate with a warning is
#'     still given; whether to report it is the caller's choice.}
#'   \item{message}{Why there is no estimate or no interval, or what the
#'     status means for the estimate, or `NA`}
#' }
#'
#' The `level` argument (passed through `...`) is both the confidence level of
#' the monoexponential intervals and the level of the stepwise linear test.
#'
#' An `NA` estimate never means "steady state not reached" by itself:  use
#' `status`.  Read the attribute from the result of the call:  some later
#' operations drop it (`merge()`, selecting columns, `subset()`, `cbind()`)
#' and others keep it unchanged (selecting rows, `rbind()`, and dplyr verbs),
#' so after any operation it may be missing or describe rows that are no
#' longer there.
#' @family Time to steady-state calculations
#' @export
pk.tss <- function(...,
                   type=c("monoexponential", "stepwise.linear"),
                   check=TRUE) {
  type <- match.arg(type, several.ok=TRUE)
  ret <- NA
  if ("monoexponential" %in% type) {
    ret_monoexponential <- pk.tss.monoexponential(..., check=check)
    if (identical(NA, ret)) {
      ret <- ret_monoexponential
    } else {
      rlang::abort("Bug in pk.tss where ret is set to non-NA too early. Please report the bug with a reproducible example.", class = "pknca_error_internal_pk_tss_ret_non_na")  # nocov
    }
    # Set check to FALSE if it has already been checked (so that it
    # doesn't happen again in stepwise.linear)
    check <- FALSE
  }
  if ("stepwise.linear" %in% type) {
    ret_stepwise <- pk.tss.stepwise.linear(..., check=check)
    if (identical(NA, ret)) {
      ret <- ret_stepwise
    } else {
      # merge() drops the "estimates" attribute, so it is set again below
      estimates <- rbind(attr(ret, "estimates"), attr(ret_stepwise, "estimates"))
      ret <- tss_set_estimates(merge(ret, ret_stepwise, all=TRUE), estimates)
    }
  }
  ret
}

#' Rows of the table of time-to-steady-state estimates
#'
#' The table is the "estimates" attribute of the result of [pk.tss()] and its
#' methods.  The arguments are recycled to the same length.
#'
#' @param type The method (`"monoexponential"` or `"stepwise.linear"`)
#' @param output The monoexponential output (`"population"`, `"popind"`,
#'   `"individual"`, or `"single"`), or `NA` for stepwise linear
#' @param treatment,subject The treatment and subject of the estimate, or `NA`
#'   when the estimate is for all of them
#' @param estimate The time to steady state, or `NA` when there is none
#' @param lower,upper The confidence interval of the estimate, or `NA` when
#'   there is none
#' @param level The confidence level (of the interval, or of the stepwise
#'   linear test)
#' @param status Why the estimate is or is not there:  `"estimated"`,
#'   `"not_reached"` (steady state is not observed in the data),
#'   `"fit_failed"`, `"insufficient_data"`, or `"no_random_effect"`
#' @param fit_warning The warnings from fitting the model that gave the
#'   estimate, or `NA`
#' @param message Why there is no estimate or no interval, or what the status
#'   means for the estimate, or `NA`
#' @returns A data frame with one row per estimate and the arguments as columns
#'   (`treatment` and `subject` as character)
#' @keywords Internal
#' @noRd
tss_estimates_table <- function(type, output=NA_character_, treatment=NA, subject=NA, estimate,
                                lower=NA_real_, upper=NA_real_, level,
                                status, fit_warning=NA_character_, message=NA_character_) {
  data.frame(
    type=type,
    output=as.character(output),
    treatment=as.character(treatment),
    subject=as.character(subject),
    estimate=as.numeric(estimate),
    lower=as.numeric(lower),
    upper=as.numeric(upper),
    level=as.numeric(level),
    status=status,
    fit_warning=as.character(fit_warning),
    message=as.character(message)
  )
}

#' Join messages, leaving out the missing ones
#'
#' @param ... Character vectors of messages (`NA` for none), recycled to the
#'   same length
#' @returns The non-missing messages of each element joined with "; ", or `NA`
#'   when all are missing
#' @keywords Internal
#' @noRd
tss_join_messages <- function(...) {
  parts <- list(...)
  n <- max(lengths(parts))
  ret <- rep(NA_character_, n)
  for (part in parts) {
    part <- rep_len(as.character(part), n)
    mask_part <- !is.na(part)
    ret[mask_part] <- ifelse(is.na(ret[mask_part]), part[mask_part], paste(ret[mask_part], part[mask_part], sep="; "))
  }
  ret
}

#' The confidence interval of a fitted Tss from nlme::intervals()
#'
#' @param model An `nlme` or `gnls` model
#' @param name The names of the Tss coefficients
#' @param level The confidence level
#' @returns A list with `lower` and `upper` (one per `name`) and `message` (`NA`
#'   or why the interval could not be computed)
#' @keywords Internal
#' @noRd
tss_model_interval <- function(model, name, level) {
  tryCatch(
    {
      ci <-
        if (inherits(model, "gnls")) {
          nlme::intervals(model, level=level)$coef
        } else {
          nlme::intervals(model, level=level, which="fixed")$fixed
        }
      list(lower=unname(ci[name, "lower"]), upper=unname(ci[name, "upper"]), message=NA_character_)
    },
    error=function(e) {
      list(
        lower=rep(NA_real_, length(name)), upper=rep(NA_real_, length(name)),
        message=paste("The confidence interval could not be computed:", conditionMessage(e))
      )
    }
  )
}

#' Set the "estimates" attribute of a time-to-steady-state result
#'
#' @param ret The result
#' @param estimates The `tss_estimates_table()` rows
#' @returns `ret` with the attribute
#' @keywords Internal
#' @noRd
tss_set_estimates <- function(ret, estimates) {
  rownames(estimates) <- NULL
  attr(ret, "estimates") <- estimates
  ret
}

#' The status of monoexponential estimates
#'
#' @param estimate The Tss estimates
#' @param last_time The time of the last trough that each estimate came from
#' @returns `"fit_failed"` for a missing estimate, `"not_reached"` for an
#'   estimate later than the last trough (steady state is extrapolated from the
#'   fitted curve, not observed), and `"estimated"` otherwise
#' @keywords Internal
#' @noRd
tss_estimate_status <- function(estimate, last_time) {
  ifelse(
    is.na(estimate), "fit_failed",
    ifelse(estimate > last_time, "not_reached", "estimated")
  )
}

#' The message for a monoexponential estimate that is not reached
#'
#' @inheritParams tss_estimate_status
#' @param status The status from `tss_estimate_status()`
#' @returns The message for each `"not_reached"` status, `NA` for the others
#' @keywords Internal
#' @noRd
tss_not_reached_message <- function(status, last_time) {
  ifelse(
    status %in% "not_reached",
    sprintf("The estimate is later than the last trough (time %g), so steady state was not observed", last_time),
    NA_character_
  )
}

#' The time of the last trough of each group
#'
#' @param data The data prepared by [pk.tss.data.prep()]
#' @param treatment,subject The treatment and subject of each group (recycled
#'   to the same length); `NA` is all treatments or all subjects
#' @returns The latest `time` of each group
#' @keywords Internal
#' @noRd
tss_last_time <- function(data, treatment=NA, subject=NA) {
  n <- max(length(treatment), length(subject))
  treatment <- rep_len(as.character(treatment), n)
  subject <- rep_len(as.character(subject), n)
  ret <- numeric(n)
  for (idx in seq_len(n)) {
    mask <- rep(TRUE, nrow(data))
    if (!is.na(treatment[idx])) {
      mask <- mask & as.character(data$treatment) %in% treatment[idx]
    }
    if (!is.na(subject[idx])) {
      mask <- mask & as.character(data$subject) %in% subject[idx]
    }
    ret[idx] <- max(data$time[mask])
  }
  ret
}
