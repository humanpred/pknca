#' List the automatic NCA result exclusion rules
#'
#' The list is built when called from the package itself:  every exported
#' function whose name starts with `exclude_nca_` is a rule; its arguments and
#' defaults come from [formals()], the [PKNCA.options()] entry that a missing
#' argument falls back to comes from the function body, the descriptions come
#' from the installed documentation, and the parameters that a rule can exclude
#' come from applying the rule to a small synthetic result.  A new rule
#' therefore appears here without any change to this function.
#'
#' @returns A tibble with one row per rule and the columns:
#' \describe{
#'   \item{rule}{The function name (for example, `"exclude_nca_span.ratio"`)}
#'   \item{description}{The one-line description from the documentation}
#'   \item{arguments}{A list column of data.frames with one row per argument and
#'   the columns `argument`, `default` (the deparsed default, or `NA` when there
#'   is none), `option` (the `PKNCA.options()` name used when the argument is
#'   not given, or `NA`), and `description`}
#'   \item{callable_with_defaults}{Can the rule be created without giving any
#'   arguments?}
#'   \item{affected_parameters}{A list column of the NCA parameters that the
#'   rule (created with its defaults) can exclude, or `NULL` when the rule
#'   cannot be created without arguments}
#' }
#' @seealso [exclude_nca], [exclude()]
#' @family Result exclusions
#' @examples
#' rules <- pknca_exclude_rules()
#' rules[, c("rule", "description")]
#' @export
pknca_exclude_rules <- function() {
  rule_names <- sort(grep("^exclude_nca_", getNamespaceExports("PKNCA"), value = TRUE))
  rd <- pknca_rd_db()
  fixture <- pknca_exclude_rules_fixture()
  rows <-
    lapply(
      X = rule_names,
      FUN = pknca_exclude_rule_row,
      rd = rd,
      fixture = fixture
    )
  tibble::tibble(
    rule = rule_names,
    description = vapply(X = rows, FUN = "[[", "description", FUN.VALUE = ""),
    arguments = lapply(X = rows, FUN = "[[", "arguments"),
    callable_with_defaults = vapply(X = rows, FUN = "[[", "callable_with_defaults", FUN.VALUE = TRUE),
    affected_parameters = lapply(X = rows, FUN = "[[", "affected_parameters")
  )
}

#' Describe one exclusion rule
#'
#' @param rule The name of the exported rule factory
#' @param rd The Rd database from `pknca_rd_db()`
#' @param fixture The PKNCAresults object from `pknca_exclude_rules_fixture()`
#' @returns A list with the elements `description`, `arguments`,
#'   `callable_with_defaults`, and `affected_parameters`
#' @keywords Internal
#' @noRd
pknca_exclude_rule_row <- function(rule, rd, fixture) {
  fun <- getExportedValue("PKNCA", rule)
  fmls <- formals(fun)
  arg_names <- names(fmls)
  if (is.null(arg_names)) {
    arg_names <- character()
  }
  has_default <-
    vapply(
      X = arg_names,
      FUN = function(nm) !identical(fmls[[nm]], quote(expr = )),
      FUN.VALUE = TRUE
    )
  defaults <-
    vapply(
      X = arg_names,
      FUN = function(nm) {
        if (identical(fmls[[nm]], quote(expr = ))) {
          NA_character_
        } else {
          paste(trimws(deparse(fmls[[nm]])), collapse = " ")
        }
      },
      FUN.VALUE = ""
    )
  option_fallback <- pknca_find_option_fallbacks(body(fun))
  rd_page <- pknca_rd_page(rd, alias = rule)
  arg_desc <- pknca_rd_arguments(rd_page)
  arguments <-
    data.frame(
      argument = arg_names,
      default = unname(defaults),
      option = unname(option_fallback[arg_names]),
      description = unname(arg_desc[arg_names]),
      stringsAsFactors = FALSE
    )
  callable <- all(has_default | !is.na(arguments$option))
  list(
    description = pknca_rd_function_description(rd_page, name = rule),
    arguments = arguments,
    callable_with_defaults = callable,
    affected_parameters =
      if (callable) pknca_exclude_rule_affected(fun(), fixture) else NULL
  )
}

#' Find the PKNCA options that missing arguments fall back to
#'
#' Looks for assignments of the form `arg <- PKNCA.options("name")` or
#' `arg <- PKNCA.choose.option(name = "name", ...)` anywhere in a function
#' body.
#'
#' @param expr A function body (or any language object)
#' @returns A named character vector with names of the assigned variables and
#'   values of the option names
#' @keywords Internal
#' @noRd
pknca_find_option_fallbacks <- function(expr) {
  ret <- character()
  if (is.call(expr)) {
    is_assign <-
      identical(expr[[1]], as.name("<-")) || identical(expr[[1]], as.name("="))
    if (is_assign && length(expr) == 3 && is.name(expr[[2]]) && is.call(expr[[3]])) {
      opt <- pknca_option_call_name(expr[[3]])
      if (!is.na(opt)) {
        ret[as.character(expr[[2]])] <- opt
      }
    }
    for (idx in seq_along(expr)[-1]) {
      # An empty argument (as in `x[, 1]`) is the missing symbol, which cannot be
      # passed on.
      if (!identical(expr[[idx]], quote(expr = ))) {
        ret <- c(ret, pknca_find_option_fallbacks(expr[[idx]]))
      }
    }
  }
  ret
}

#' Get the option name from a call to PKNCA.options() or PKNCA.choose.option()
#'
#' @param call_expr A call
#' @returns The option name when `call_expr` reads one option by a literal name,
#'   otherwise `NA_character_`
#' @keywords Internal
#' @noRd
pknca_option_call_name <- function(call_expr) {
  fn <- call_expr[[1]]
  if (is.call(fn) && identical(fn[[1]], as.name("::"))) {
    fn <- fn[[3]]
  }
  if (!is.name(fn) || !(as.character(fn) %in% c("PKNCA.options", "PKNCA.choose.option"))) {
    return(NA_character_)
  }
  args <- as.list(call_expr)[-1]
  arg_names <- names(args)
  if (is.null(arg_names)) {
    arg_names <- rep("", length(args))
  }
  opt <-
    if ("name" %in% arg_names) {
      args[["name"]]
    } else if (any(arg_names == "")) {
      args[[which(arg_names == "")[1]]]
    } else {
      NULL
    }
  if (is.character(opt) && length(opt) == 1) {
    opt
  } else {
    NA_character_
  }
}

#' Find the parameters that an exclusion rule can exclude
#'
#' @param rule_fun The function returned by an `exclude_nca_*()` factory
#' @param fixture The PKNCAresults object from `pknca_exclude_rules_fixture()`
#' @returns A sorted character vector of parameter names
#' @keywords Internal
#' @noRd
pknca_exclude_rule_affected <- function(rule_fun, fixture) {
  # Every rule compares a parameter to a threshold, so one of an extremely low
  # and an extremely high value of every parameter triggers it.
  affected <- character()
  for (current_value in c(-1e300, 1e300)) {
    current_fixture <- fixture
    current_fixture$result$PPORRES <- current_value
    excluded <- exclude(current_fixture, FUN = rule_fun)
    affected <-
      c(affected, excluded$result$PPTESTCD[!is.na(excluded$result$exclude)])
  }
  sort(unique(affected))
}

#' A synthetic PKNCAresults object with one row for every NCA parameter
#'
#' @returns A PKNCAresults object for one subject and one interval
#' @keywords Internal
#' @noRd
pknca_exclude_rules_fixture <- function() {
  o_conc <- PKNCAconc(data.frame(conc = c(1, 2, 1), time = 0:2, subject = 1), conc ~ time | subject)
  o_data <-
    PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, cmax = TRUE))
  parameters <- setdiff(names(get.interval.cols()), c("start", "end"))
  result <-
    data.frame(
      subject = 1,
      start = 0,
      end = Inf,
      PPTESTCD = parameters,
      PPORRES = 0,
      exclude = NA_character_,
      stringsAsFactors = FALSE
    )
  PKNCAresults(result = result, data = o_data, exclude = "exclude")
}

#' Get the Rd database for PKNCA
#'
#' Under development (loaded from a source directory with `man/`), the source
#' Rd files are used; otherwise, the installed documentation is used.
#'
#' @returns A list of parsed Rd objects (see [tools::Rd_db()])
#' @keywords Internal
#' @noRd
pknca_rd_db <- function() {
  path <- getNamespaceInfo("PKNCA", "path")
  rd <-
    if (dir.exists(file.path(path, "man"))) {
      tools::Rd_db(dir = path)
    } else {
      tools::Rd_db(package = "PKNCA", lib.loc = dirname(path))
    }
  if (length(rd) == 0) {
    rlang::abort(
      "The PKNCA documentation (Rd) could not be found, so the exclusion rules cannot be described.",
      class = "pknca_error_rd_missing"
    )
  }
  rd
}

#' Get the Rd page that documents an alias
#'
#' @param rd The Rd database from `pknca_rd_db()`
#' @param alias The alias (function name) to find
#' @returns The parsed Rd object
#' @keywords Internal
#' @noRd
pknca_rd_page <- function(rd, alias) {
  for (page in rd) {
    aliases <-
      vapply(
        X = pknca_rd_tagged(page, "\\alias"),
        FUN = pknca_rd_text,
        FUN.VALUE = ""
      )
    if (alias %in% aliases) {
      return(page)
    }
  }
  rlang::abort(
    sprintf("No documentation page was found for %s", alias),
    class = "pknca_error_rd_alias_missing"
  )
}

#' Get the elements of an Rd object with a tag
#'
#' @param x A parsed Rd object (or part of one)
#' @param tag The Rd tag (for example `"\\alias"`)
#' @returns A list of the elements with that tag
#' @keywords Internal
#' @noRd
pknca_rd_tagged <- function(x, tag) {
  x[vapply(X = x, FUN = function(el) identical(attr(el, "Rd_tag"), tag), FUN.VALUE = TRUE)]
}

#' Convert part of an Rd object to plain text
#'
#' Markup is dropped (`\code{x}` becomes `x`), and white space is collapsed.
#'
#' @param x A parsed Rd object (or part of one)
#' @returns A character scalar
#' @keywords Internal
#' @noRd
pknca_rd_text <- function(x) {
  trimws(gsub(pattern = "\\s+", replacement = " ", x = pknca_rd_text_raw(x)))
}

pknca_rd_text_raw <- function(x) {
  if (identical(attr(x, "Rd_tag"), "COMMENT")) {
    ""
  } else if (is.list(x)) {
    paste(vapply(X = x, FUN = pknca_rd_text_raw, FUN.VALUE = ""), collapse = "")
  } else {
    paste(x, collapse = "")
  }
}

#' Get the argument descriptions from an Rd page
#'
#' @param page A parsed Rd object
#' @returns A named character vector of argument descriptions (an argument
#'   documented together with others, as in `\item{x,y}{...}`, gets the shared
#'   description)
#' @keywords Internal
#' @noRd
pknca_rd_arguments <- function(page) {
  ret <- character()
  for (arguments in pknca_rd_tagged(page, "\\arguments")) {
    for (item in pknca_rd_tagged(arguments, "\\item")) {
      arg_names <- trimws(strsplit(pknca_rd_text(item[[1]]), split = ",", fixed = TRUE)[[1]])
      ret[arg_names] <- pknca_rd_text(item[[2]])
    }
  }
  ret
}

#' Get the one-line description of a function from an Rd page
#'
#' A function documented with `@describeIn` is described by its item in the
#' "Functions" section; a function with its own page is described by the title.
#'
#' @param page A parsed Rd object
#' @param name The function name
#' @returns A character scalar
#' @keywords Internal
#' @noRd
pknca_rd_function_description <- function(page, name) {
  for (section in pknca_rd_tagged(page, "\\section")) {
    if (identical(pknca_rd_text(section[[1]]), "Functions")) {
      for (itemize in pknca_rd_tagged(section[[2]], "\\itemize")) {
        # In an itemize list, `\item` is a marker, and the item's text is the
        # elements up to the next marker.
        is_item <- vapply(X = itemize, FUN = function(el) identical(attr(el, "Rd_tag"), "\\item"), FUN.VALUE = TRUE)
        item_id <- cumsum(is_item)
        for (current_id in unique(item_id[item_id > 0])) {
          item_text <- pknca_rd_text(itemize[item_id == current_id & !is_item])
          prefix <- paste0(name, "():")
          if (startsWith(item_text, prefix)) {
            return(trimws(substring(item_text, nchar(prefix) + 1)))
          }
        }
      }
    }
  }
  pknca_rd_text(pknca_rd_tagged(page, "\\title"))
}
