test_that("pknca_rd_exclude_rule writes the registered descriptions as roxygen2 tags", {
  expect_equal(
    pknca_rd_exclude_rule("exclude_nca_span.ratio"),
    c(
      "@describeIn exclude_nca Exclude based on the half-life span ratio",
      '@param min.span.ratio The minimum acceptable span ratio (uses PKNCA.options("min.span.ratio") if not provided).'
    )
  )
  # A rule without arguments has only its description
  expect_equal(
    pknca_rd_exclude_rule("exclude_nca_tmax_0"),
    "@describeIn exclude_nca Exclude based on implausibly early Tmax (special case for tmax_early = 0)"
  )
  # A rule with its own page has its description as the title
  by_param <- pknca_rd_exclude_rule("exclude_nca_by_param", describe_in = NULL)
  expect_equal(by_param[1], "@title Exclude based on NCA parameter thresholds")
  expect_equal(
    by_param[-1],
    paste("@param", c("parameter", "min_thr", "max_thr", "affected_parameters"), pknca_exclude_rules()$arguments[[1]]$description)
  )
  expect_error(pknca_rd_exclude_rule("exclude_nca_not_a_rule"), class = "pknca_error_rule_not_registered")
})

test_that("pknca_rd_impute_method writes the registered description and details", {
  expect_equal(
    pknca_rd_impute_method("PKNCA_impute_method_start_cmin"),
    "@describeIn PKNCA_impute_method Add a new concentration of the minimum during the interval at the start time (usually used with multiple-dose data)"
  )
  expect_equal(
    pknca_rd_impute_method("PKNCA_impute_method_start_predose"),
    paste(
      "@describeIn PKNCA_impute_method",
      "Shift a predose concentration to become the time zero concentration (only if a time zero concentration does not exist).",
      "The most recent predose sample with a measured concentration is shifted; samples with a missing concentration are skipped."
    )
  )
  expect_error(
    pknca_rd_impute_method("PKNCA_impute_method_not_a_method"),
    class = "pknca_error_impute_method_not_registered"
  )
})

test_that("the registry tables are markdown tables with one row per entry", {
  expect_equal(
    pknca_rd_table_section(title = "Things", data = data.frame(A = c("a1", "a2"), B = c("b1", "b2"))),
    c("@section Things:", "", "| A | B |", "| --- | --- |", "| a1 | b1 |", "| a2 | b2 |")
  )
  rules_table <- pknca_rd_exclude_rules_table()
  rules <- pknca_exclude_rules()
  expect_equal(rules_table[1:4], c("@section Rules:", "", "| Rule | Description | PKNCA.options() used |", "| --- | --- | --- |"))
  expect_length(rules_table, 4 + nrow(rules))
  expect_equal(
    rules_table[startsWith(rules_table, "| [exclude_nca_span.ratio()]")],
    "| [exclude_nca_span.ratio()] | Exclude based on the half-life span ratio | `min.span.ratio` |"
  )
  # A rule with no options used, and a rule that needs its arguments
  expect_true("| [exclude_nca_tmax_0()] | Exclude based on implausibly early Tmax (special case for tmax_early = 0) | (none) |" %in% rules_table)
  expect_true(any(startsWith(rules_table, "| [exclude_nca_by_param()] | Exclude based on NCA parameter thresholds | (set by its arguments) |")))
  methods_table <- pknca_rd_impute_methods_table()
  expect_equal(methods_table[1:4], c("@section Methods:", "", "| Method | Description |", "| --- | --- |"))
  expect_length(methods_table, 4 + nrow(pknca_impute_methods()))
  expect_true(
    paste(
      '| `"start_cmin"` |',
      "Add a new concentration of the minimum during the interval at the start time (usually used with multiple-dose data) |"
    ) %in% methods_table
  )
})

# The roxygen2 documentation of each registered exclusion rule and imputation
# method is generated from its registration by an `@eval` line in the
# function's own documentation block.  The source is only available when
# testing from the source package (as with devtools), not under R CMD check.
test_that("every registered rule and method is documented by an @eval line in its own block", {
  r_dir <- test_path("..", "..", "R")
  skip_if_not(file.exists(file.path(r_dir, "registry_docs.R")), "The package source is needed")
  documented <- character()
  for (current_file in list.files(r_dir, pattern = "\\.R$", full.names = TRUE)) {
    current_lines <- readLines(current_file, warn = FALSE)
    eval_lines <- grep(pattern = "^#' @eval pknca_rd_(exclude_rule|impute_method)\\(\"", x = current_lines)
    for (idx in eval_lines) {
      current_name <- sub(pattern = "^[^\"]*\"([^\"]+)\".*$", replacement = "\\1", x = current_lines[idx])
      # The first line after the documentation block defines the function
      after_block <- current_lines[-seq_len(idx)]
      definition <- after_block[!startsWith(after_block, "#'") & nzchar(trimws(after_block))][1]
      expect_true(startsWith(definition, paste(current_name, "<- function(")), info = current_name)
      documented <- c(documented, current_name)
    }
  }
  expect_equal(
    sort(documented[startsWith(documented, "exclude_nca_")]),
    sort(pknca_exclude_rules()$rule)
  )
  expect_equal(
    sort(documented[startsWith(documented, "PKNCA_impute_method_")]),
    sort(pknca_impute_methods()$fun)
  )
  # Each is documented once
  expect_false(anyDuplicated(documented) > 0)
})

# Reading the installed help, which devtools::load_all() does not provide, so
# the test below runs under R CMD check.

# The text of an Rd element, without its markup and with white space collapsed
rd_text <- function(x) {
  raw <-
    if (identical(attr(x, "Rd_tag"), "COMMENT")) {
      ""
    } else if (is.list(x)) {
      paste(vapply(X = x, FUN = rd_text, FUN.VALUE = ""), collapse = "")
    } else {
      paste(x, collapse = "")
    }
  normalize_space(raw)
}

normalize_space <- function(x) {
  trimws(gsub(pattern = "\\s+", replacement = " ", x = x))
}

rd_tagged <- function(x, tag) {
  x[vapply(X = x, FUN = function(el) identical(attr(el, "Rd_tag"), tag), FUN.VALUE = TRUE)]
}

# The section of an Rd page with the given title
rd_section <- function(page, title) {
  for (section in rd_tagged(page, "\\section")) {
    if (identical(rd_text(section[[1]]), title)) {
      return(section[[2]])
    }
  }
  NULL
}

# The "Functions" section items of an Rd page (from @describeIn), named by
# function
rd_function_descriptions <- function(page) {
  ret <- character()
  for (itemize in rd_tagged(rd_section(page, "Functions"), "\\itemize")) {
    is_item <- vapply(X = itemize, FUN = function(el) identical(attr(el, "Rd_tag"), "\\item"), FUN.VALUE = TRUE)
    item_id <- cumsum(is_item)
    for (current_id in unique(item_id[item_id > 0])) {
      item_text <- rd_text(itemize[item_id == current_id & !is_item])
      ret[sub("\\(\\):.*$", "", item_text)] <- sub("^[^:]*:\\s*", "", item_text)
    }
  }
  ret
}

# The arguments of an Rd page, named by argument
rd_arguments <- function(page) {
  ret <- character()
  for (arguments in rd_tagged(page, "\\arguments")) {
    for (item in rd_tagged(arguments, "\\item")) {
      ret[rd_text(item[[1]])] <- rd_text(item[[2]])
    }
  }
  ret
}

test_that("the installed help has the registered descriptions as they are written", {
  skip_if(
    dir.exists(file.path(getNamespaceInfo("PKNCA", "path"), "man")),
    "The installed help is needed (run under R CMD check, not devtools::load_all())"
  )
  rd <- tools::Rd_db(package = "PKNCA", lib.loc = dirname(getNamespaceInfo("PKNCA", "path")))

  # Exclusion rules:  the descriptions, the argument descriptions, and the table
  rules <- pknca_exclude_rules()
  documented <-
    c(
      rd_function_descriptions(rd[["exclude_nca.Rd"]]),
      exclude_nca_by_param = rd_text(rd_tagged(rd[["exclude_nca_by_param.Rd"]], "\\title"))
    )
  expect_equal(documented[rules$rule], stats::setNames(rules$description, rules$rule))
  documented_arguments <- c(rd_arguments(rd[["exclude_nca.Rd"]]), rd_arguments(rd[["exclude_nca_by_param.Rd"]]))
  registered_arguments <- do.call(rbind, rules$arguments)
  expect_equal(
    documented_arguments[registered_arguments$argument],
    stats::setNames(registered_arguments$description, registered_arguments$argument)
  )
  rules_section <- rd_text(rd_section(rd[["pknca_exclude_rules.Rd"]], "Rules"))
  for (current_description in rules$description) {
    expect_true(grepl(pattern = current_description, x = rules_section, fixed = TRUE), info = current_description)
  }

  # Imputation methods:  the description and details, and the table.  The
  # details' only markup is code, which the installed Rd keeps without the
  # spaces around it, so these are compared without markup or white space.
  methods <- pknca_impute_methods()
  registry <- get("impute_methods", envir = .PKNCAEnv)
  expected_methods <-
    vapply(
      X = methods$fun,
      FUN = function(fun) {
        gsub(pattern = "[`[:space:]]", replacement = "", x = paste(registry[[fun]]$description, registry[[fun]]$details))
      },
      FUN.VALUE = ""
    )
  documented_methods <- rd_function_descriptions(rd[["PKNCA_impute_method.Rd"]])
  expect_equal(
    gsub(pattern = "[[:space:]]", replacement = "", x = documented_methods[methods$fun]),
    expected_methods
  )
  methods_section <- rd_text(rd_section(rd[["pknca_impute_methods.Rd"]], "Methods"))
  for (current_description in methods$description) {
    expect_true(grepl(pattern = current_description, x = methods_section, fixed = TRUE), info = current_description)
  }
})
