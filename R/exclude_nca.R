#' Exclude NCA parameters based on examining the parameter set.
#'
#' @returns A function to give to [exclude()] as `FUN`.  Its
#'   `pknca_affected_parameters` attribute lists the parameters it can exclude,
#'   and its `pknca_options` attribute lists the [PKNCA.options()] entries its
#'   thresholds came from (see [pknca_exclude_rules()]).
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
#' Each `exclude_nca_*()` factory is registered right after its definition (so
#' this is defined first in the file), the way interval columns are registered
#' with [add.interval.col()].  The registry holds only what the factory cannot
#' say about itself, its descriptions; the parameters a rule can exclude and
#' the options it uses are read from the function the factory returns (see
#' `exclude_nca_describe()`).
#'
#' The registration is the only place the descriptions are written:  the
#' factory's documentation is generated from it with
#' `@eval pknca_rd_exclude_rule()`, so the descriptions are plain text (they
#' are shown as they are by [pknca_exclude_rules()]).
#'
#' @param name The name of the exported factory function
#' @param description The one-line description ("Exclude based on ...")
#' @param arguments A named character vector with the description of each
#'   argument of the factory, named by argument
#' @returns `NULL`, invisibly
#' @keywords Internal
#' @noRd
pknca_register_exclude_rule <- function(name, description, arguments = character()) {
  checkmate::assert_string(name, pattern = "^exclude_nca_")
  checkmate::assert_string(description, pattern = "^Exclude based on ")
  checkmate::assert_character(arguments, min.chars = 1, any.missing = FALSE, names = "unique")
  current <- get("exclude_rules", envir = .PKNCAEnv)
  current[[name]] <- list(description = description, arguments = arguments)
  assign("exclude_rules", current, envir = .PKNCAEnv)
  invisible(NULL)
}

#' Get a threshold from PKNCA.options(), remembering which option it came from
#'
#' @param name The option name
#' @returns The option value, with the option name in its `pknca_option`
#'   attribute, which [exclude_nca_by_param()] records on the exclusion
#'   function
#' @keywords Internal
#' @noRd
exclude_nca_option <- function(name) {
  structure(PKNCA.options(name), pknca_option = name)
}

#' Record what an exclusion function can exclude and the options it uses
#'
#' @param fun The exclusion function that a factory returns
#' @param affected The parameters it can exclude
#' @param options The `PKNCA.options()` names its thresholds came from
#' @returns `fun` with the attributes `pknca_affected_parameters` and
#'   `pknca_options`
#' @keywords Internal
#' @noRd
exclude_nca_describe <- function(fun, affected, options = character()) {
  attr(fun, "pknca_affected_parameters") <- sort(unique(as.character(affected)))
  attr(fun, "pknca_options") <- sort(unique(as.character(options)))
  fun
}

#' The parameters an exclusion function can exclude
#'
#' @param fun A function returned by an `exclude_nca_*()` factory
#' @returns A sorted character vector of parameter names
#' @keywords Internal
#' @noRd
exclude_nca_affected_parameters <- function(fun) {
  attr(fun, "pknca_affected_parameters", exact = TRUE)
}

#' The PKNCA options that an exclusion function's thresholds came from
#'
#' @inheritParams exclude_nca_affected_parameters
#' @returns A sorted character vector of option names (empty when every
#'   threshold was given)
#' @keywords Internal
#' @noRd
exclude_nca_options_used <- function(fun) {
  attr(fun, "pknca_options", exact = TRUE)
}

# A parameter that depends on the half-life is excluded with it, but a
# calculation that could have used the half-life and did not must not be (#270):
# an AUCint over an interval that ends at or before Tlast is interpolated
# throughout, so no exclusion of the half-life reaches it.  pk.calc.auxcint()
# reports the extrapolation it used in the method column, and that is what says
# whether the half-life entered the result.  A result that reports no
# extrapolation says nothing either way, so it keeps the exclusion.
exclude_nca_halflife_dependent <- function(FUN) {
  ret_fun <- function(x, ...) {
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
  exclude_nca_describe(
    ret_fun,
    affected = exclude_nca_affected_parameters(FUN),
    options = exclude_nca_options_used(FUN)
  )
}

#' @eval pknca_rd_exclude_rule("exclude_nca_span.ratio")
#' @export
exclude_nca_span.ratio <- function(min.span.ratio) {
  if (missing(min.span.ratio)) {
    min.span.ratio <- exclude_nca_option("min.span.ratio")
  }
  exclude_nca_halflife_dependent(
    exclude_nca_by_param(
      parameter = "span.ratio",
      min_thr = min.span.ratio,
      affected_parameters = get.parameter.deps("half.life")
    )
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_span.ratio",
  description = "Exclude based on the half-life span ratio",
  arguments =
    c(min.span.ratio = 'The minimum acceptable span ratio (uses PKNCA.options("min.span.ratio") if not provided).')
)

#' @eval pknca_rd_exclude_rule("exclude_nca_max.aucinf.pext")
#' @export
exclude_nca_max.aucinf.pext <- function(max.aucinf.pext) {
  if (missing(max.aucinf.pext)) {
    max.aucinf.pext <- exclude_nca_option("max.aucinf.pext")
  }
  # Exclude for both obs and pred
  exc_obs <-
    exclude_nca_by_param(
      parameter = "aucpext.obs",
      max_thr = max.aucinf.pext,
      affected_parameters = get.parameter.deps("aucinf.obs")
    )
  exc_pred <-
    exclude_nca_by_param(
      parameter = "aucpext.pred",
      max_thr = max.aucinf.pext,
      affected_parameters = get.parameter.deps("aucinf.pred")
    )
  ret_fun <- function(x, ...) {
    res_obs <- exc_obs(x, ...)
    res_pred <- exc_pred(x, ...)
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
  exclude_nca_describe(
    ret_fun,
    affected = c(exclude_nca_affected_parameters(exc_obs), exclude_nca_affected_parameters(exc_pred)),
    options = c(exclude_nca_options_used(exc_obs), exclude_nca_options_used(exc_pred))
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_max.aucinf.pext",
  description = "Exclude based on the percent of AUC extrapolated to infinity (both observed and predicted)",
  arguments =
    c(max.aucinf.pext = 'The maximum acceptable percent AUC extrapolation (uses PKNCA.options("max.aucinf.pext") if not provided).')
)

#' @eval pknca_rd_exclude_rule("exclude_nca_count_conc_measured")
#' @export
exclude_nca_count_conc_measured <- function(min_count, exclude_param_pattern = c("^aucall", "^aucinf", "^aucint", "^auciv", "^auclast", "^aumc", "^sparse_auc")) {
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
  affected_parameters <-
    sort(unique(unlist(
      lapply(
        X = affected_parameters_base,
        FUN = get.parameter.deps
      )
    )))
  exclude_nca_by_param(
    parameter = "count_conc_measured",
    min_thr = min_count,
    affected_parameters = affected_parameters
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_count_conc_measured",
  description = "Exclude based on the count of concentrations measured and not below the lower limit of quantification (affects AUC and AUMC parameters)",
  arguments =
    c(
      min_count = "Minimum number of measured concentrations",
      exclude_param_pattern = "Character vector of regular expression patterns to exclude"
    )
)

#' @eval pknca_rd_exclude_rule("exclude_nca_min.hl.r.squared")
#' @export
exclude_nca_min.hl.r.squared <- function(min.hl.r.squared) {
  if (missing(min.hl.r.squared)) {
    min.hl.r.squared <- exclude_nca_option("min.hl.r.squared")
  }
  exclude_nca_halflife_dependent(
    exclude_nca_by_param(
      parameter = "r.squared",
      min_thr = min.hl.r.squared,
      affected_parameters = get.parameter.deps("half.life")
    )
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_min.hl.r.squared",
  description = "Exclude based on half-life r-squared",
  arguments =
    c(min.hl.r.squared = 'The minimum acceptable r-squared value for half-life (uses PKNCA.options("min.hl.r.squared") if not provided).')
)

#' @eval pknca_rd_exclude_rule("exclude_nca_min.hl.adj.r.squared")
#' @export
exclude_nca_min.hl.adj.r.squared <- function(min.hl.adj.r.squared = 0.9) {
  exclude_nca_halflife_dependent(
    exclude_nca_by_param(
      parameter = "adj.r.squared",
      min_thr = min.hl.adj.r.squared,
      affected_parameters = get.parameter.deps("half.life")
    )
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_min.hl.adj.r.squared",
  description = "Exclude based on half-life adjusted r-squared",
  arguments =
    c(min.hl.adj.r.squared = "The minimum acceptable adjusted r-squared for half-life (uses 0.9 if not provided).")
)

#' @eval pknca_rd_exclude_rule("exclude_nca_tmax_early")
#' @export
exclude_nca_tmax_early <- function(tmax_early = 0) {

    exc_fun <- exclude_nca_by_param(
      parameter = "tmax",
      min_thr = tmax_early,
      # start and end are interval columns, never result parameters
      affected_parameters = setdiff(names(get.interval.cols()), c("start", "end"))
    )

    ret_fun <- function(x, ...) {
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
    exclude_nca_describe(
      ret_fun,
      affected = exclude_nca_affected_parameters(exc_fun),
      options = exclude_nca_options_used(exc_fun)
    )
}
pknca_register_exclude_rule(
  name = "exclude_nca_tmax_early",
  description = "Exclude based on implausibly early Tmax (often used for extravascular dosing with a Tmax value of 0)",
  arguments =
    c(tmax_early = "The time for Tmax which is considered too early to be a valid NCA result")
)

#' @eval pknca_rd_exclude_rule("exclude_nca_tmax_0")
#' @export
exclude_nca_tmax_0 <- function() {
  exc_fun <- exclude_nca_tmax_early(1e-99)
  ret_fun <- function(x, ...) {
    ret <- exc_fun(x, ...)

    # Replace the messages
    ret <- gsub(
      pattern = "^tmax < 1e-99",
      replacement = "tmax <= 0",
      x = ret
    )
    ret
  }
  exclude_nca_describe(
    ret_fun,
    affected = exclude_nca_affected_parameters(exc_fun),
    options = exclude_nca_options_used(exc_fun)
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_tmax_0",
  description = "Exclude based on implausibly early Tmax (special case for tmax_early = 0)"
)


#' @eval pknca_rd_exclude_rule("exclude_nca_by_param", describe_in = NULL)
#' @description
#' Exclude rows from NCA results based on specified thresholds for a given parameter.
#' This function allows users to define minimum and/or maximum acceptable values
#' for a parameter and excludes rows that fall outside these thresholds.
#'
#' @returns A function that can be used with `PKNCA::exclude` to mark through the 'exclude'  column
#'          the rows in the PKNCA results based on the specified thresholds for a parameter.
#'          Its `pknca_affected_parameters` attribute lists the parameters it can mark
#'          (see [pknca_exclude_rules()]).
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
  # Check that defined thresholds are single numeric objects (assert_*, not
  # expect_*:  checkmate's expect_* functions are testthat expectations)
  checkmate::assert_number(min_thr, finite = TRUE, null.ok = TRUE)
  checkmate::assert_number(max_thr, finite = TRUE, null.ok = TRUE)

  if (isTRUE(min_thr > max_thr)) {
    rlang::abort("if both defined min_thr must be less than max_thr", class = "pknca_error_min_thr_gt_max_thr")
  }

  ret_fun <- function(x, ...) {
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
  exclude_nca_describe(
    ret_fun,
    affected = affected_parameters,
    options = c(attr(min_thr, "pknca_option", exact = TRUE), attr(max_thr, "pknca_option", exact = TRUE))
  )
}
pknca_register_exclude_rule(
  name = "exclude_nca_by_param",
  description = "Exclude based on NCA parameter thresholds",
  arguments =
    c(
      parameter = 'The name of the PKNCA parameter to evaluate (e.g., "span.ratio").',
      min_thr = "The minimum acceptable value for the parameter. If not provided, is not applied.",
      max_thr = "The maximum acceptable value for the parameter. If not provided, is not applied.",
      affected_parameters = "Character vector of PKNCA parameters that will be marked as excluded. By default is the defined parameter."
    )
)
