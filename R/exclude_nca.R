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

#' Register an automatic NCA result exclusion rule
#'
#' Each `exclude_nca_*()` factory is registered right after its definition
#' (so this is defined first in the file),
#' the way interval columns are registered with [add.interval.col()], so that
#' [pknca_exclude_rules()] can describe every rule without reading code or
#' documentation.
#'
#' @param name The name of the exported factory function
#' @param description The one-line description (the same text as the
#'   factory's documentation, "Exclude based on ...")
#' @param option A named character vector:  the names are factory arguments,
#'   and the values are the [PKNCA.options()] entries they use when not given
#' @param affects A function returning the NCA parameters the rule can
#'   exclude.  Its arguments, if any, are factory arguments and receive the
#'   factory's defaults.  `NULL` when the parameters depend on an argument
#'   without a default.
#' @returns `NULL`, invisibly
#' @keywords Internal
#' @noRd
pknca_register_exclude_rule <- function(name, description, option = character(), affects = NULL) {
  checkmate::assert_string(name, pattern = "^exclude_nca_")
  checkmate::assert_string(description, pattern = "^Exclude based on ")
  checkmate::assert_character(option, any.missing = FALSE, names = if (length(option) > 0) "unique" else NULL)
  checkmate::assert_function(affects, null.ok = TRUE)
  current <- get("exclude_rules", envir = .PKNCAEnv)
  current[[name]] <- list(description = description, option = option, affects = affects)
  assign("exclude_rules", current, envir = .PKNCAEnv)
  invisible(NULL)
}

# The parameters that exclusion rules can exclude.  The factories and their
# registrations share these, so the registry cannot drift from the rules.
exclude_nca_affected_halflife <- function() {
  get.parameter.deps("half.life")
}

exclude_nca_affected_aucinf <- function() {
  sort(unique(c(get.parameter.deps("aucinf.obs"), get.parameter.deps("aucinf.pred"))))
}

exclude_nca_affected_count_conc <- function(exclude_param_pattern) {
  all_parameters <- names(get.interval.cols())
  affected_parameters_base <-
    sort(unique(unlist(
      lapply(
        X = exclude_param_pattern,
        FUN = grep,
        x = all_parameters,
        value = TRUE
      )
    )))
  sort(unique(unlist(
    lapply(
      X = affected_parameters_base,
      FUN = get.parameter.deps
    )
  )))
}

exclude_nca_affected_all <- function() {
  setdiff(names(get.interval.cols()), c("start", "end"))
}

# A parameter that depends on the half-life is excluded with it, but a
# calculation that could have used the half-life and did not must not be (#270):
# an AUCint over an interval that ends at or before Tlast is interpolated
# throughout, so no exclusion of the half-life reaches it.  pk.calc.auxcint()
# reports the extrapolation it used in the method column, and that is what says
# whether the half-life entered the result.  A result that reports no
# extrapolation says nothing either way, so it keeps the exclusion.
exclude_nca_halflife_dependent <- function(FUN) {
  function(x, ...) {
    ret <- FUN(x, ...)
    if ("PPANMETH" %in% names(x)) {
      reports_extrapolation <-
        grepl(pattern = pknca_extrap_method_prefix, x = x$PPANMETH, fixed = TRUE)
      used_halflife <-
        grepl(
          pattern = paste0(pknca_extrap_method_prefix, pknca_extrap_method_halflife),
          x = x$PPANMETH,
          fixed = TRUE
        )
      ret[reports_extrapolation & !used_halflife] <- NA_character_
    }
    ret
  }
}

#' @describeIn exclude_nca Exclude based on the half-life span ratio
#' @export
exclude_nca_span.ratio <- function(min.span.ratio) {
  missing_min.span.ratio <- missing(min.span.ratio)
  if (missing_min.span.ratio) {
    min.span.ratio <- PKNCA.options("min.span.ratio")
  }
  exclude_nca_halflife_dependent(
    exclude_nca_by_param(
      parameter = "span.ratio",
      min_thr = min.span.ratio,
      affected_parameters = exclude_nca_affected_halflife()
    )
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_span.ratio",
  description = "Exclude based on the half-life span ratio",
  option = c(min.span.ratio = "min.span.ratio"),
  affects = exclude_nca_affected_halflife
)

#' @describeIn exclude_nca Exclude based on the percent of AUC extrapolated to
#'   infinity (both observed and predicted)
#' @export
exclude_nca_max.aucinf.pext <- function(max.aucinf.pext) {
  missing_max.aucinf.pext <- missing(max.aucinf.pext)
  if (missing_max.aucinf.pext) {
    max.aucinf.pext <- PKNCA.options("max.aucinf.pext")
  }
  # Exclude for both obs and pred
  function(x, ...) {
    res_obs <- exclude_nca_by_param(
      parameter = "aucpext.obs",
      max_thr = max.aucinf.pext,
      affected_parameters = get.parameter.deps("aucinf.obs")
    )(x, ...)
    res_pred <- exclude_nca_by_param(
      parameter = "aucpext.pred",
      max_thr = max.aucinf.pext,
      affected_parameters = get.parameter.deps("aucinf.pred")
    )(x, ...)
    # Combine results, prioritizing non-NA from either
    is.obs <- grepl(paste0("aucpext.obs > ", max.aucinf.pext), res_obs)
    is.pred <- grepl(paste0("aucpext.pred > ", max.aucinf.pext), res_pred)
    ret <- ifelse(
      is.obs | is.pred,
      gsub(
        pattern = paste0("aucpext...+ > ", max.aucinf.pext),
        replacement = paste0("aucpext > ", max.aucinf.pext),
        x = dplyr::coalesce(res_obs, res_pred)
      ),
      res_obs
    )
    ret
  }
}
pknca_register_exclude_rule(
  name = "exclude_nca_max.aucinf.pext",
  description = "Exclude based on the percent of AUC extrapolated to infinity (both observed and predicted)",
  option = c(max.aucinf.pext = "max.aucinf.pext"),
  affects = exclude_nca_affected_aucinf
)

#' @describeIn exclude_nca Exclude based on the count of concentrations measured
#'   and not below the lower limit of quantification (affects AUC and AUMC
#'   parameters)
#' @param min_count Minimum number of measured concentrations
#' @param exclude_param_pattern Character vector of regular expression patterns to exclude
#' @export
exclude_nca_count_conc_measured <- function(min_count, exclude_param_pattern = c("^aucall", "^aucinf", "^aucint", "^auciv", "^auclast", "^aumc", "^sparse_auc")) {
  exclude_nca_by_param(
    parameter = "count_conc_measured",
    min_thr = min_count,
    affected_parameters = exclude_nca_affected_count_conc(exclude_param_pattern)
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_count_conc_measured",
  description = "Exclude based on the count of concentrations measured and not below the lower limit of quantification (affects AUC and AUMC parameters)",
  affects = exclude_nca_affected_count_conc
)

#' @describeIn exclude_nca Exclude based on half-life r-squared
#' @export
exclude_nca_min.hl.r.squared <- function(min.hl.r.squared) {
  missing_min.hl.r.squared <- missing(min.hl.r.squared)
  if (missing_min.hl.r.squared) {
    min.hl.r.squared <- PKNCA.options("min.hl.r.squared")
  }
  exclude_nca_halflife_dependent(
    exclude_nca_by_param(
      parameter = "r.squared",
      min_thr = min.hl.r.squared,
      affected_parameters = exclude_nca_affected_halflife()
    )
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_min.hl.r.squared",
  description = "Exclude based on half-life r-squared",
  option = c(min.hl.r.squared = "min.hl.r.squared"),
  affects = exclude_nca_affected_halflife
)

#' @describeIn exclude_nca Exclude based on half-life adjusted r-squared
#' @export
exclude_nca_min.hl.adj.r.squared <- function(min.hl.adj.r.squared = 0.9) {
  exclude_nca_halflife_dependent(
    exclude_nca_by_param(
      parameter = "adj.r.squared",
      min_thr = min.hl.adj.r.squared,
      affected_parameters = exclude_nca_affected_halflife()
    )
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_min.hl.adj.r.squared",
  description = "Exclude based on half-life adjusted r-squared",
  affects = exclude_nca_affected_halflife
)

#' @describeIn exclude_nca Exclude based on implausibly early Tmax (often used for extravascular dosing with a Tmax value of 0)
#' @param tmax_early The time for Tmax which is considered too early to be a valid NCA result
#' @export
exclude_nca_tmax_early <- function(tmax_early = 0) {
    
    exc_fun <- exclude_nca_by_param(
      parameter = "tmax",
      min_thr = tmax_early,
      affected_parameters = exclude_nca_affected_all()
    )

    function(x, ...) {
    # Get the exclusion messages
    ret <- exc_fun(x, ...)
    # Add the special annotation for tmax_early cases (if not already annotated)
    tmax_cases <- grepl(pattern = "^tmax < ", x = ret)
    tmax_already_annotated <- grepl("(likely missed dose, insufficient PK samples, or PK sample swap)", x = ret, fixed = TRUE)
    ret <- ifelse(
        test = tmax_cases & !tmax_already_annotated & !is.na(ret),
        yes = gsub(
          pattern = paste0("^tmax < ", tmax_early),
          replacement = paste0("tmax < ", tmax_early, " (likely missed dose, insufficient PK samples, or PK sample swap)"),
          x = ret
        ),
        no = ret
      )
    ret
    }
}
pknca_register_exclude_rule(
  name = "exclude_nca_tmax_early",
  description = "Exclude based on implausibly early Tmax (often used for extravascular dosing with a Tmax value of 0)",
  affects = exclude_nca_affected_all
)

#' @describeIn exclude_nca Exclude based on implausibly early Tmax (special case for `tmax_early = 0`)
#' @export
exclude_nca_tmax_0 <- function() {
  exc_fun <- exclude_nca_tmax_early(1e-99)
  function(x, ...) {
    ret <- exc_fun(x, ...)

    # Replace the messages
    ret <- gsub(
      pattern = "^tmax < 1e-99",
      replacement = "tmax <= 0",
      x = ret
    )
    ret
  }
}
pknca_register_exclude_rule(
  name = "exclude_nca_tmax_0",
  description = "Exclude based on implausibly early Tmax (special case for tmax_early = 0)",
  affects = exclude_nca_affected_all
)


#' Exclude based on NCA parameter thresholds
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
#'   PKNCA::PKNCAconc(data.frame(conc = 5:1,
#'                               time = 0:4,
#'                               subject = 1),
#'                    conc ~ time | subject),
#'   PKNCA::PKNCAdose(data.frame(subject = 1, dose = 100, time = 0),
#'                    dose ~ time | subject)
#' )
#' my_result <- PKNCA::pk.nca(my_data)
#'
#' # Exclude rows where span.ratio is less than 2
#' excluded_result <- PKNCA::exclude(
#'   my_result,
#'   FUN = exclude_nca_by_param("span.ratio", min_thr = 2)
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
  # Check that defined thresholds are single numeric objects
  checkmate::expect_number(min_thr, finite = TRUE, null.ok = TRUE)
  checkmate::expect_number(max_thr, finite = TRUE, null.ok = TRUE)

  if (isTRUE(min_thr > max_thr)) {
    rlang::abort("if both defined min_thr must be less than max_thr", class = "pknca_error_min_thr_gt_max_thr")
  }

  function(x, ...) {
    ret <- rep(NA_character_, nrow(x))
    idx_param <- which(x$PPTESTCD == parameter)
    idx_aff_params <- which(x$PPTESTCD %in% affected_parameters)

    if (length(idx_param) > 1) {
      rlang::abort(
        sprintf(
          "Should not see more than one %s (please report this as a bug)",
          parameter
        ),
        class = "pknca_error_internal_duplicate_parameter"
      )
    }

    if (length(idx_param) == 1 && !is.na(x$PPORRES[idx_param]) && length(idx_aff_params) > 0) {
      current_value <- x$PPORRES[idx_param]
      pretty_name <- parameter # Pretty name did not convince me for some parameters (e.g, "r.squared")
      if (isTRUE(current_value < min_thr)) {
        ret[idx_aff_params] <- sprintf("%s < %g", pretty_name, min_thr)
      } else if (isTRUE(current_value > max_thr)) {
        ret[idx_aff_params] <- sprintf("%s > %g", pretty_name, max_thr)
      }
    }
    ret
  }
}
pknca_register_exclude_rule(
  name = "exclude_nca_by_param",
  description = "Exclude based on NCA parameter thresholds"
)
