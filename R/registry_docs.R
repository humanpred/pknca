#' Documentation for an exclusion rule, from its registration
#'
#' Used with roxygen2's `@eval` in the rule's documentation block, so that the
#' registration (see `pknca_register_exclude_rule()`) is the only place the
#' description and the argument descriptions are written.
#'
#' @param rule The rule (factory) name
#' @param describe_in The documentation page that the rule is described in
#'   (with `@describeIn`), or `NULL` when the rule has its own page (and the
#'   description is the title)
#' @returns A character vector of roxygen2 tags
#' @keywords Internal
#' @noRd
pknca_rd_exclude_rule <- function(rule, describe_in = "exclude_nca") {
  registered <- get("exclude_rules", envir = .PKNCAEnv)[[rule]]
  if (is.null(registered)) {
    rlang::abort(paste("The exclusion rule is not registered:", rule), class = "pknca_error_rule_not_registered")
  }
  description_tag <-
    if (is.null(describe_in)) {
      paste("@title", registered$description)
    } else {
      paste("@describeIn", describe_in, registered$description)
    }
  c(
    description_tag,
    paste("@param", names(registered$arguments), registered$arguments, recycle0 = TRUE)
  )
}

#' Documentation for an imputation method, from its registration
#'
#' Used with roxygen2's `@eval` in the method's documentation block, so that
#' the registration (see `pknca_register_impute_method()`) is the only place
#' the description is written.
#'
#' @param fun The method function name
#' @returns A roxygen2 `@describeIn` tag for the `PKNCA_impute_method` page
#' @keywords Internal
#' @noRd
pknca_rd_impute_method <- function(fun) {
  registered <- get("impute_methods", envir = .PKNCAEnv)[[fun]]
  if (is.null(registered)) {
    rlang::abort(paste("The imputation method is not registered:", fun), class = "pknca_error_impute_method_not_registered")
  }
  paste(c("@describeIn PKNCA_impute_method", registered$description, registered$details), collapse = " ")
}

#' A documentation section with a markdown table
#'
#' @param title The section title
#' @param data A data.frame of character columns, one row per table row
#' @returns A character vector of roxygen2 lines
#' @keywords Internal
#' @noRd
pknca_rd_table_section <- function(title, data) {
  rows <- apply(X = as.matrix(data), MARGIN = 1, FUN = paste, collapse = " | ")
  c(
    paste0("@section ", title, ":"),
    "",
    paste0("| ", paste(names(data), collapse = " | "), " |"),
    paste0("|", paste(rep(" --- |", ncol(data)), collapse = "")),
    paste0("| ", rows, " |")
  )
}

#' The table of exclusion rules for the `pknca_exclude_rules()` documentation
#'
#' @returns A character vector of roxygen2 lines
#' @keywords Internal
#' @noRd
pknca_rd_exclude_rules_table <- function() {
  rules <- pknca_exclude_rules()
  options_used <-
    vapply(
      X = rules$options,
      FUN = function(x) {
        if (is.null(x)) {
          "(set by its arguments)"
        } else if (length(x) == 0) {
          "(none)"
        } else {
          paste0("`", x, "`", collapse = ", ")
        }
      },
      FUN.VALUE = ""
    )
  pknca_rd_table_section(
    title = "Rules",
    data =
      data.frame(
        Rule = sprintf("[%s()]", rules$rule),
        Description = rules$description,
        `PKNCA.options() used` = options_used,
        check.names = FALSE
      )
  )
}

#' The table of imputation methods for the `pknca_impute_methods()`
#' documentation
#'
#' @returns A character vector of roxygen2 lines
#' @keywords Internal
#' @noRd
pknca_rd_impute_methods_table <- function() {
  methods <- pknca_impute_methods()
  pknca_rd_table_section(
    title = "Methods",
    data =
      data.frame(
        Method = sprintf('`"%s"`', methods$method),
        Description = methods$description
      )
  )
}
