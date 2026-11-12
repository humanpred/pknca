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
#'   and/or `pk.tss.stepwise.linear`.
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
      ret <- merge(ret, ret_stepwise, all=TRUE)
    }
  }
  ret
}
