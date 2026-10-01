#' List the automatic NCA result exclusion rules
#'
#' Every `exclude_nca_*()` rule is registered with its description.  Its
#' arguments and their defaults come from the factory function, and the
#' parameters it can exclude and the [PKNCA.options()] entries it uses come
#' from the exclusion function that the factory returns when called with its
#' defaults (an argument without a default falls back to its option, as it
#' does in use).
#'
#' @returns A tibble with one row per rule and the columns:
#' \describe{
#'   \item{rule}{The function name (for example, `"exclude_nca_span.ratio"`)}
#'   \item{description}{The one-line description}
#'   \item{arguments}{A list column of data.frames with one row per argument and
#'   the columns `argument` and `default` (the deparsed default, or `NA` when
#'   there is none)}
#'   \item{callable_with_defaults}{Can the rule be created without giving any
#'   arguments?}
#'   \item{options}{A list column of the `PKNCA.options()` names that the rule
#'   uses when created with its defaults, or `NULL` when it cannot be}
#'   \item{affected_parameters}{A list column of the NCA parameters that the
#'   rule, created with its defaults, can exclude, or `NULL` when it cannot be
#'   created without arguments}
#' }
#' @seealso [exclude_nca], [exclude()]
#' @family Result exclusions
#' @examples
#' rules <- pknca_exclude_rules()
#' rules[, c("rule", "description")]
#' @export
pknca_exclude_rules <- function() {
  registry <- get("exclude_rules", envir = .PKNCAEnv)
  rule_names <- sort(names(registry))
  rule_funs <- lapply(X = rule_names, FUN = pknca_exclude_rule_default)
  tibble::tibble(
    rule = rule_names,
    description = vapply(X = registry[rule_names], FUN = "[[", "description", FUN.VALUE = "", USE.NAMES = FALSE),
    arguments = lapply(X = rule_names, FUN = pknca_function_arguments),
    callable_with_defaults = !vapply(X = rule_funs, FUN = is.null, FUN.VALUE = TRUE),
    options = lapply(X = rule_funs, FUN = function(x) if (!is.null(x)) exclude_nca_options_used(x)),
    affected_parameters = lapply(X = rule_funs, FUN = function(x) if (!is.null(x)) exclude_nca_affected_parameters(x))
  )
}

#' Create an exclusion rule with its defaults
#'
#' @param rule The rule (factory) name
#' @returns The exclusion function, or `NULL` when the factory has an argument
#'   without a default that it needs (and so cannot be called without
#'   arguments)
#' @keywords Internal
#' @noRd
pknca_exclude_rule_default <- function(rule) {
  factory <- getExportedValue("PKNCA", rule)
  arguments <- pknca_function_arguments(rule)
  # An argument without a default either falls back to a PKNCA option inside
  # the factory or is required; only calling the factory can tell.
  tryCatch(
    factory(),
    error = function(e) {
      if (any(is.na(arguments$default))) {
        NULL
      } else {
        stop(e) # nocov
      }
    }
  )
}
