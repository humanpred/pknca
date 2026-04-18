# Generate vignettes/parameters-available.Rmd
#
# Run from the package root:
#   Rscript data-raw/write_param_table_md.R

devtools::load_all()

# ---------------------------------------------------------------------------
# Utility: write a data.frame as a markdown pipe table
# ---------------------------------------------------------------------------

#' Write a data.frame as a markdown pipe table
#'
#' @param df A data.frame to render.
#' @param con A connection or character file path. Lines are appended.
#' @param align Column alignments: "l", "r", or "c". Recycled to ncol(df).
write_md_table <- function(df, con, align = NULL) {
  if (!is.data.frame(df)) stop("df must be a data.frame")
  if (nrow(df) == 0) stop("df must have at least one row")

  nc <- ncol(df)

  if (is.null(align)) {
    align <- rep("l", nc)
  } else {
    align <- rep_len(align, nc)
  }
  align_sep <- vapply(align, function(a) {
    switch(a, l = ":---", r = "---:", c = ":---:", "---")
  }, FUN.VALUE = "")

  escape_pipe <- function(x) gsub("|", "\\|", x, fixed = TRUE)

  make_row <- function(vals) {
    paste0("| ", paste(escape_pipe(vals), collapse = " | "), " |")
  }

  lines <- character(nrow(df) + 2L)
  lines[1] <- make_row(colnames(df))
  lines[2] <- make_row(align_sep)
  for (i in seq_len(nrow(df))) {
    lines[i + 2L] <- make_row(vapply(df[i, ], as.character, FUN.VALUE = ""))
  }

  cat(lines, file = con, sep = "\n", append = TRUE)
}

# ---------------------------------------------------------------------------
# Utility: write an Rmd YAML header
# ---------------------------------------------------------------------------

write_rmd_header <- function(con, title, author = "PKNCA Developers") {
  cat(
    "---",
    paste0('title: "', title, '"'),
    paste0('author: "', author, '"'),
    "output:",
    "  rmarkdown::html_vignette:",
    "    toc: yes",
    "    toc_depth: 2",
    "vignette: >",
    paste0("  %\\VignetteIndexEntry{", title, "}"),
    "  %\\VignetteEngine{knitr::rmarkdown}",
    "  %\\VignetteEncoding{UTF-8}",
    "---",
    "",
    sep = "\n",
    file = con,
    append = FALSE
  )
}

# ---------------------------------------------------------------------------
# Build the parameter table from get.interval.cols()
# ---------------------------------------------------------------------------

interval_spec <- get.interval.cols()
interval_spec <- interval_spec[sort(names(interval_spec))]

get_formula <- function(x) {
  if (is.null(x$formula) || identical(x$formula, "")) "" else x$formula
}

get_formula_note <- function(x) {
  if (is.null(x$formula_note) || identical(x$formula_note, "")) "" else x$formula_note
}

get_function_for_calc <- function(x) {
  if (is.na(x$FUN)) {
    if (is.null(x$depends)) "(none)" else paste("See:", x$depends)
  } else {
    x$FUN
  }
}

param_table <- data.frame(
  Parameter = names(interval_spec),
  Formula = vapply(interval_spec, get_formula, FUN.VALUE = ""),
  `Formula Note` = vapply(interval_spec, get_formula_note, FUN.VALUE = ""),
  `Unit Type` = vapply(interval_spec, "[[", "unit_type", FUN.VALUE = ""),
  Description = vapply(interval_spec, "[[", "desc", FUN.VALUE = ""),
  Function = vapply(interval_spec, get_function_for_calc, FUN.VALUE = ""),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

# "Also Uses This Function" — other parameters that share the same FUN
fun_groups <- split(param_table$Parameter, param_table$Function)
param_table[["Also Uses This Function"]] <- vapply(
  seq_len(nrow(param_table)), function(i) {
    fn <- param_table$Function[i]
    if (fn == "(none)" || grepl("^See:", fn)) return("")
    siblings <- setdiff(fun_groups[[fn]], param_table$Parameter[i])
    if (length(siblings) == 0) return("")
    paste(siblings, collapse = ", ")
  },
  FUN.VALUE = ""
)

# ---------------------------------------------------------------------------
# Write the .Rmd
# ---------------------------------------------------------------------------

outfile <- file.path("vignettes", "parameters-available.Rmd")
write_rmd_header(outfile, title = "Parameters Available in PKNCA")
write_md_table(param_table, con = outfile)
message("Done: ", outfile)
