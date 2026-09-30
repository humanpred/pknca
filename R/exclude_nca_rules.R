#' List the automatic NCA result exclusion rules
#'
#' Every `exclude_nca_*()` rule is registered with its description, the
#' [PKNCA.options()] entries its arguments fall back to, and the parameters it
#' can exclude; the arguments and their defaults come from the functions
#' themselves.
#'
#' @returns A tibble with one row per rule and the columns:
#' \describe{
#'   \item{rule}{The function name (for example, `"exclude_nca_span.ratio"`)}
#'   \item{description}{The one-line description}
#'   \item{arguments}{A list column of data.frames with one row per argument and
#'   the columns `argument`, `default` (the deparsed default, or `NA` when there
#'   is none), and `option` (the `PKNCA.options()` name used when the argument
#'   is not given, or `NA`)}
#'   \item{callable_with_defaults}{Can the rule be created without giving any
#'   arguments?}
#'   \item{affected_parameters}{A list column of the NCA parameters that the
#'   rule (created with its defaults) can exclude, or `NULL` when they depend
#'   on an argument without a default}
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
  arguments <- lapply(X = rule_names, FUN = pknca_exclude_rule_arguments, registry = registry)
  tibble::tibble(
    rule = rule_names,
    description = vapply(X = registry[rule_names], FUN = "[[", "description", FUN.VALUE = "", USE.NAMES = FALSE),
    arguments = arguments,
    callable_with_defaults =
      vapply(
        X = arguments,
        FUN = function(x) all(!is.na(x$default) | !is.na(x$option)),
        FUN.VALUE = TRUE
      ),
    affected_parameters =
      lapply(X = rule_names, FUN = pknca_exclude_rule_affected, registry = registry)
  )
}

#' Describe the arguments of a registered exclusion rule
#'
#' @param rule The rule name
#' @param registry The exclusion rule registry
#' @returns A data.frame with the columns `argument`, `default`, and `option`
#' @keywords Internal
#' @noRd
pknca_exclude_rule_arguments <- function(rule, registry) {
  fmls <- formals(getExportedValue("PKNCA", rule))
  arg_names <- as.character(names(fmls))
  data.frame(
    argument = arg_names,
    default =
      vapply(
        X = arg_names,
        FUN = function(nm) {
          if (identical(fmls[[nm]], quote(expr = ))) {
            NA_character_
          } else {
            paste(trimws(deparse(fmls[[nm]])), collapse = " ")
          }
        },
        FUN.VALUE = "",
        USE.NAMES = FALSE
      ),
    option = unname(registry[[rule]]$option[arg_names])
  )
}

#' Find the parameters a registered exclusion rule can exclude
#'
#' @inheritParams pknca_exclude_rule_arguments
#' @returns A sorted character vector, or `NULL` when the rule's `affects`
#'   function needs an argument that the factory has no default for
#' @keywords Internal
#' @noRd
pknca_exclude_rule_affected <- function(rule, registry) {
  affects <- registry[[rule]]$affects
  if (is.null(affects)) {
    return(NULL)
  }
  fmls <- formals(getExportedValue("PKNCA", rule))
  args <- list()
  for (nm in names(formals(affects))) {
    if (identical(fmls[[nm]], quote(expr = ))) {
      return(NULL)
    }
    args[[nm]] <- eval(fmls[[nm]], envir = asNamespace("PKNCA"))
  }
  sort(unique(do.call(affects, args)))
}
