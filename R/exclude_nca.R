#' Exclude NCA parameters based on examining the parameter set.
#'
#' @param min.span.ratio The minimum acceptable span ratio (uses
#'   `PKNCA.options("min.span.ratio")` if not provided).
#' @param max.aucinf.pext The maximum acceptable percent AUC extrapolation (uses
#'   `PKNCA.options("max.aucinf.pext")` if not provided).
#' @param min.hl.r.squared The minimum acceptable r-squared value for half-life
#'   (uses `PKNCA.options("min.hl.r.squared")` if not provided).
#' @param min.hl.adj.r.squared The minimum acceptable adjusted r-squared for half-life
#'   (uses 0.9 if not provided).
#' @examples
#' my_conc <- PKNCAconc(data.frame(conc=1.1^(3:0),
#'                                 time=0:3,
#'                                 subject=1),
#'                      conc~time|subject)
#' my_data <- PKNCAdata(my_conc,
#'                      intervals=data.frame(start=0, end=Inf,
#'                                           aucinf.obs=TRUE,
#'                                           aucpext.obs=TRUE))
#' my_result <- pk.nca(my_data)
#' my_result_excluded <- exclude(my_result,
#'                               FUN=exclude_nca_max.aucinf.pext())
#' as.data.frame(my_result_excluded)
#' @name exclude_nca
#' @family Result exclusions
NULL

#' @describeIn exclude_nca Exclude based on span.ratio
#' @export
exclude_nca_span.ratio <- function(min.span.ratio) {
  affected_parameters <- get.parameter.deps("half.life")
  missing_min.span.ratio <- missing(min.span.ratio)
  function(x, ...) {
    if (missing_min.span.ratio) {
      min.span.ratio <- PKNCA.options("min.span.ratio")
    }
    ret <- rep(NA_character_, nrow(x))
    if (!is.na(min.span.ratio)) {
      idx_span.ratio <- which(x$PPTESTCD %in% "span.ratio")
      if (length(idx_span.ratio) == 0) {
        # Do nothing, it wasn't calculated
      } else if (length(idx_span.ratio) == 1) {
        current_span.ratio <- x$PPORRES[idx_span.ratio]
        drop_span_ratio <-
          !is.na(current_span.ratio) &
          current_span.ratio < min.span.ratio
        if (drop_span_ratio) {
          ret[x$PPTESTCD %in% affected_parameters] <-
            sprintf("Span ratio < %g", min.span.ratio)
        }
      } else if (length(idx_span.ratio) > 1) { # nocov
        stop("Should not see more than one span.ratio (please report this as a bug)") # nocov
      }
    }
    ret
  }
}

#' @describeIn exclude_nca Exclude based on AUC percent extrapolated (both
#'   observed and predicted)
#' @export
exclude_nca_max.aucinf.pext <-  function(max.aucinf.pext) {
  affected_parameters <-
    list(obs=get.parameter.deps("aucinf.obs"),
         pred=get.parameter.deps("aucinf.pred"))
  missing_max.aucinf.pext <- missing(max.aucinf.pext)
  function(x, ...) {
    if (missing_max.aucinf.pext) {
      max.aucinf.pext <- PKNCA.options("max.aucinf.pext")
    }
    ret <- rep(NA_character_, nrow(x))
    if (!is.na(max.aucinf.pext)) {
      for (ext_type in c("obs", "pred")) {
        idx_pext <- which(x$PPTESTCD %in% paste0("aucpext.", ext_type))
        if (length(idx_pext) == 0) {
          # Do nothing, it wasn't calculated
        } else if (length(idx_pext) == 1) {
          current_pext <- x$PPORRES[idx_pext]
          drop_pext <-
            !is.na(current_pext) &
            current_pext > max.aucinf.pext
          if (drop_pext) {
            ret[x$PPTESTCD %in% affected_parameters[[ext_type]]] <-
              sprintf("AUC percent extrapolated > %g", max.aucinf.pext)
          }
        } else if (length(idx_pext) > 1) { # nocov
          stop("Should not see more than one aucpext.", ext_type, " (please report this as a bug)") # nocov
        }
      }
    }
    ret
  }
}

#' @describeIn exclude_nca Exclude AUC measurements based on count of
#'   concentrations measured and not below the lower limit of quantification
#' @param min_count Minimum number of measured concentrations
#' @param exclude_param_pattern Character vector of regular expression patterns
#'   to exclude
#' @export
exclude_nca_count_conc_measured <-  function(min_count, exclude_param_pattern = c("^aucall", "^aucinf", "^aucint", "^auciv", "^auclast", "^aumc", "^sparse_auc")) {
  all_parameters <- names(PKNCA::get.interval.cols())
  affected_parameters_base <-
    sort(unique(unlist(
      lapply(
        X = exclude_param_pattern,
        FUN = grep,
        x = all_parameters,
        value = TRUE
      )
    )))
  affected_parameters <-
    sort(unique(unlist(
      lapply(
        X = affected_parameters_base,
        FUN = get.parameter.deps
      )
    )))
  force(min_count)
  function(x, ...) {
    ret <- rep(NA_character_, nrow(x))
    if (!is.na(min_count)) {
      idx_count <- which(x$PPTESTCD %in% "count_conc_measured")
      if (length(idx_count) == 0) {
        # Do nothing, it wasn't calculated
      } else if (length(idx_count) == 1) {
        current_count <- x$PPORRES[idx_count]
        drop_count <-
          !is.na(current_count) &
          current_count < min_count
        if (drop_count) {
          ret[x$PPTESTCD %in% affected_parameters] <-
            sprintf("Number of measured concentrations is < %g", min_count)
        }
      } else { # nocov
        stop("Should not see more than one count_conc_measured (please report this as a bug)") # nocov
      }
    }
    ret
  }
}

#' @describeIn exclude_nca Exclude based on half-life r-squared
#' @export
exclude_nca_min.hl.r.squared <- function(min.hl.r.squared) {
  affected_parameters <- get.parameter.deps("half.life")
  missing_min.hl.r.squared <- missing(min.hl.r.squared)
  function(x, ...) {
    if (missing_min.hl.r.squared) {
      min.hl.r.squared <- PKNCA.options("min.hl.r.squared")
    }
    ret <- rep(NA_character_, nrow(x))
    if (!is.na(min.hl.r.squared)) {
      idx_r.squared <- which(x$PPTESTCD %in% "r.squared")
      if (length(idx_r.squared) == 0) {
        # Do nothing, it wasn't calculated
      } else if (length(idx_r.squared) == 1) {
        current_r.squared <- x$PPORRES[idx_r.squared]
        drop_r.squared <-
          !is.na(current_r.squared) &
          current_r.squared < min.hl.r.squared
        if (drop_r.squared) {
          ret[x$PPTESTCD %in% affected_parameters] <-
            sprintf("Half-life r-squared < %g", min.hl.r.squared)
        }
      } else if (length(idx_r.squared) > 1) { # nocov
        stop("Should not see more than one r.squared (please report this as a bug)") # nocov
      }
    }
    ret
  }
}

#' @describeIn exclude_nca Exclude based on half-life adjusted r-squared
#' @export
exclude_nca_min.hl.adj.r.squared <- function(min.hl.adj.r.squared = 0.9) {
  affected_parameters <- get.parameter.deps("half.life")
  function(x, ...) {
    ret <- rep(NA_character_, nrow(x))
    if (!is.na(min.hl.adj.r.squared)) {
      idx_adj.r.squared <- which(x$PPTESTCD %in% "adj.r.squared")
      if (length(idx_adj.r.squared) == 0) {
        # Do nothing, it wasn't calculated
      } else if (length(idx_adj.r.squared) == 1) {
        current_adj.r.squared <- x$PPORRES[idx_adj.r.squared]
        drop_adj.r.squared <-
          !is.na(current_adj.r.squared) &
          current_adj.r.squared < min.hl.adj.r.squared
        if (drop_adj.r.squared) {
          ret[x$PPTESTCD %in% affected_parameters] <-
            sprintf("Half-life adj. r-squared < %g", min.hl.adj.r.squared)
        }
      } else if (length(idx_adj.r.squared) > 1) { # nocov
        stop("Should not see more than one adj.r.squared (please report this as a bug)") # nocov
      }
    }
    ret
  }
}

#' @describeIn exclude_nca Exclude based on implausibly early Tmax (often used
#'   for extravascular dosing with a Tmax value of 0)
#' @param tmax_early The time for Tmax which is considered too early to be a
#'   valid NCA result
#' @export
exclude_nca_tmax_early <- function(tmax_early = 0) {
  force(tmax_early)
  function(x, ...) {
    ret <- rep(NA_character_, nrow(x))
    idx_tmax <- which(x$PPTESTCD %in% "tmax")
    if (length(idx_tmax) == 1) {
      current_tmax <- x$PPORRES[idx_tmax]
      drop <- !is.na(current_tmax) & current_tmax <= tmax_early
      if (drop) {
        ret <- rep(sprintf("Tmax is <=%g (likely missed dose, insufficient PK samples, or PK sample swap)", tmax_early), nrow(x))
      }
    } else if (length(idx_tmax) != 0) {
      stop("Should not see more than one tmax (please report this as a bug)") # nocov
    }
    ret
  }
}

#' @describeIn exclude_nca Exclude based on implausibly early Tmax (special case
#'   for `tmax_early = 0`)
#' @export
exclude_nca_tmax_0 <- function() {
  exclude_nca_tmax_early()
}


#' Exclude NCA Results Based on Parameter Thresholds
#'
#' Exclude rows from NCA results based on specified thresholds for a given parameter.
#' This function allows users to define minimum and/or maximum acceptable values
#' for a parameter and excludes rows that fall outside these thresholds.
#'
#' @param parameter The name of the PKNCA parameter to evaluate (e.g., "span.ratio").
#' @param min_thr The minimum acceptable value for the parameter. If not provided, is not applied.
#' @param max_thr The maximum acceptable value for the parameter. If not provided, is not applied.
#' @param affected_parameters Character vector of PKNCA parameters that will be marked as excluded.
#'                            By default is the defined parameter.
#' @returns A function that can be used with `PKNCA::exclude` to mark through the 'exclude'  column
#'          the rows in the PKNCA results based on the specified thresholds for a parameter.
#' @examples
#' # Example dataset
#' my_data <- PKNCA::PKNCAdata(
#'   PKNCA::PKNCAconc(data.frame(conc = c(1, 2, 3, 4),
#'                               time = c(0, 1, 2, 3),
#'                               subject = 1),
#'                    conc ~ time | subject),
#'   PKNCA::PKNCAdose(data.frame(subject = 1, dose = 100, time = 0),
#'                    dose ~ time | subject)
#' )
#' my_result <- PKNCA::pk.nca(my_data)
#'
#' # Exclude rows where span.ratio is less than 100
#' excluded_result <- PKNCA::exclude(
#'   my_result,
#'   FUN = exclude_nca_by_param("span.ratio", min_thr = 100)
#' )
#' as.data.frame(excluded_result)
#'
#' @export

exclude_nca_by_param <- function(
  parameter,
  min_thr = NULL,
  max_thr = NULL,
  affected_parameters = parameter
) {
  # Determine if thresholds are defined and if so check they are single numeric objects
  is_min_thr <- is_single_numeric(min_thr, "min_thr")
  is_max_thr <- is_single_numeric(max_thr, "max_thr")

  if (isTRUE(min_thr > max_thr))
    stop("if both defined min_thr must be less than max_thr")

  function(x, ...) {
    ret <- rep(NA_character_, nrow(x))
    idx_param <- which(x$PPTESTCD == parameter)
    idx_aff_params <- which(x$PPTESTCD %in% affected_parameters)

    if (length(idx_param) > 1)
      stop("Should not see more than one ", parameter, " (please report this as a bug)")

    if (length(idx_param) == 1 && !is.na(x$PPORRES[idx_param]) && length(idx_aff_params) > 0) {
      current_value <- x$PPORRES[idx_param]
      pretty_name <- parameter # Pretty name did not convince me for some parameters (e.g, "r.squared")
      if (is_min_thr && current_value < min_thr) {
        ret[idx_aff_params] <- sprintf("%s < %g", pretty_name, min_thr)
      } else if (is_max_thr && current_value > max_thr) {
        ret[idx_aff_params] <- sprintf("%s > %g", pretty_name, max_thr)
      }
    }
    ret
  }
}

# Helper function to validate if a value is a single numeric and check if it is defined
is_single_numeric <- function(value, name) {
  is_val <- any(!is.null(value) & !is.na(value) & !missing(value))
  if (is_val && (length(value) != 1 || !is.numeric(value))) {
    stop(sprintf("when defined %s must be a single numeric value", name))
  }
  is_val
}

