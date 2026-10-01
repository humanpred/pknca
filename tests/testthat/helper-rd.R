# Reading the installed help, to check that registered descriptions (of
# exclusion rules and imputation methods) match the documentation.  The Rd is
# read from the installed package, which devtools::load_all() does not
# provide, so the tests that use these run under R CMD check.

skip_without_installed_help <- function() {
  testthat::skip_if(
    dir.exists(file.path(getNamespaceInfo("PKNCA", "path"), "man")),
    "The installed help is needed (run under R CMD check, not devtools::load_all())"
  )
}

installed_rd <- function() {
  tools::Rd_db(package = "PKNCA", lib.loc = dirname(getNamespaceInfo("PKNCA", "path")))
}

# The installed Rd keeps words but not always the spaces at line breaks, so
# comparisons ignore white space.
squish <- function(x) {
  gsub(pattern = "\\s+", replacement = "", x = x)
}

rd_text <- function(x) {
  raw <-
    if (identical(attr(x, "Rd_tag"), "COMMENT")) {
      ""
    } else if (is.list(x)) {
      paste(vapply(X = x, FUN = rd_text, FUN.VALUE = ""), collapse = "")
    } else {
      paste(x, collapse = "")
    }
  trimws(gsub(pattern = "\\s+", replacement = " ", x = raw))
}

rd_tagged <- function(x, tag) {
  x[vapply(X = x, FUN = function(el) identical(attr(el, "Rd_tag"), tag), FUN.VALUE = TRUE)]
}

# The "Functions" section items of an Rd page (from @describeIn), named by
# function
rd_function_descriptions <- function(page) {
  ret <- character()
  for (section in rd_tagged(page, "\\section")) {
    if (identical(rd_text(section[[1]]), "Functions")) {
      for (itemize in rd_tagged(section[[2]], "\\itemize")) {
        is_item <- vapply(X = itemize, FUN = function(el) identical(attr(el, "Rd_tag"), "\\item"), FUN.VALUE = TRUE)
        item_id <- cumsum(is_item)
        for (current_id in unique(item_id[item_id > 0])) {
          item_text <- rd_text(itemize[item_id == current_id & !is_item])
          ret[sub("\\(\\):.*$", "", item_text)] <- sub("^[^:]*:\\s*", "", item_text)
        }
      }
    }
  }
  ret
}
