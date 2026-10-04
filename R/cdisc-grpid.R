# The CDISC PPGRPID column: the record group identifier of a PP row, built from
# caller-named grouping columns and the number of the row's interval

# Check the `grpid_cols` and `grpid_numeric` arguments
#
# `grpid_cols` names the PKNCAconc grouping columns that prefix the interval
# number in PPGRPID, in prefix order, each with the text written before that
# column's value.  The subject and the analyte identify what was measured, not
# which group of records a row belongs to, so they cannot be named.
# `grpid_numeric` names the columns, among those of `grpid_cols`, whose values
# are written as whole numbers.
#
# @param grpid_cols `NULL`, or a named character vector (see above)
# @param o_conc The PKNCAconc object that defines the grouping columns
# @param grpid_numeric `NULL`, or a character vector of names in `grpid_cols`
# @returns `grpid_cols`, unchanged (`NULL` stays `NULL`); an error when an
#   argument is invalid
# @keywords Internal
# @noRd
assert_grpid_cols <- function(grpid_cols, o_conc, grpid_numeric = NULL) {
  if (is.null(grpid_numeric)) {
    grpid_numeric <- character()
  }
  if (!is.null(grpid_cols)) {
    assert_grpid_cols_form(grpid_cols)
    subject_analyte <- c(o_conc$columns$subject, o_conc$columns$groups$group_analyte)
    mask_subject_analyte <- names(grpid_cols) %in% subject_analyte
    if (any(mask_subject_analyte)) {
      rlang::abort(
        sprintf(
          "`grpid_cols` may not name the subject or analyte column: %s",
          paste(names(grpid_cols)[mask_subject_analyte], collapse = ", ")
        ),
        class = "pknca_error_grpid_cols_subject_analyte"
      )
    }
    not_group <- setdiff(names(grpid_cols), unlist(o_conc$columns$groups))
    if (length(not_group) > 0) {
      rlang::abort(
        sprintf(
          "`grpid_cols` must name grouping columns of the concentration data; not grouping columns: %s",
          paste(not_group, collapse = ", ")
        ),
        class = "pknca_error_grpid_cols_not_group"
      )
    }
  }
  if (!is.character(grpid_numeric) || anyNA(grpid_numeric)) {
    rlang::abort(
      "`grpid_numeric` must be a character vector of column names without missing values",
      class = "pknca_error_grpid_numeric_invalid"
    )
  }
  not_named <- setdiff(grpid_numeric, names(grpid_cols))
  if (length(not_named) > 0) {
    rlang::abort(
      sprintf(
        "`grpid_numeric` must name columns that are also in `grpid_cols`; not in `grpid_cols`: %s",
        paste(not_named, collapse = ", ")
      ),
      class = "pknca_error_grpid_numeric_invalid"
    )
  }
  grpid_cols
}

# The form of `grpid_cols` (not yet checked against the data): a character
# vector with a unique, non-empty name and text without '.' for every column
#
# @param grpid_cols The argument
# @returns `NULL`, invisibly, or an error
# @keywords Internal
# @noRd
assert_grpid_cols_form <- function(grpid_cols) {
  if (!is.character(grpid_cols)) {
    rlang::abort(
      sprintf(
        "`grpid_cols` must be NULL or a character vector (a named one:  column names as the names, the text before each value as the values), not %s",
        paste(class(grpid_cols), collapse = "/")
      ),
      class = "pknca_error_grpid_cols_invalid"
    )
  }
  if (anyNA(grpid_cols)) {
    rlang::abort(
      sprintf(
        "`grpid_cols` has a missing value (the text before the values) for column(s): %s",
        paste(names(grpid_cols)[is.na(grpid_cols)], collapse = ", ")
      ),
      class = "pknca_error_grpid_cols_invalid"
    )
  }
  if (length(grpid_cols) > 0) {
    col_names <- names(grpid_cols)
    if (is.null(col_names) || anyNA(col_names) || any(!nzchar(col_names))) {
      rlang::abort(
        sprintf(
          "`grpid_cols` must have a column name for every value; the names are: %s",
          if (is.null(col_names)) "none" else paste0("'", col_names, "'", collapse = ", ")
        ),
        class = "pknca_error_grpid_cols_invalid"
      )
    }
    if (anyDuplicated(col_names)) {
      rlang::abort(
        sprintf(
          "`grpid_cols` must name each column once; repeated: %s",
          paste(unique(col_names[duplicated(col_names)]), collapse = ", ")
        ),
        class = "pknca_error_grpid_cols_invalid"
      )
    }
  }
  mask_dot <- grepl(pattern = ".", x = grpid_cols, fixed = TRUE)
  if (any(mask_dot)) {
    rlang::abort(
      sprintf(
        "The text written before the values in `grpid_cols` may not contain '.', because '.' separates the parts of the group identifier; column '%s' has '%s'",
        names(grpid_cols)[mask_dot][1], grpid_cols[mask_dot][1]
      ),
      class = "pknca_error_grpid_cols_invalid"
    )
  }
  invisible(NULL)
}

# Text that identifies a value in a key, with missing values distinct from any
# text (including "NA")
#
# @param values A vector
# @returns A character vector
# @keywords Internal
# @noRd
pknca_grpid_key_text <- function(values) {
  text <- as.character(values)
  text[is.na(values)] <- "\001NA\001"
  text
}

# The key of the group combination of each row
#
# @param data A data.frame
# @param group_cols The names of the grouping columns in `data`
# @returns A character vector with one key per row of `data`
# @keywords Internal
# @noRd
pknca_interval_group_key <- function(data, group_cols) {
  if (length(group_cols) == 0) {
    return(rep("", nrow(data)))
  }
  do.call(
    paste,
    c(unname(lapply(data[, group_cols, drop = FALSE], pknca_grpid_key_text)), sep = "\r")
  )
}

# The key of the interval window (group combination, start, and end) of each
# row; 17 significant digits tell apart every pair of different doubles
#
# @inheritParams pknca_interval_group_key
# @returns A character vector with one key per row of `data`
# @keywords Internal
# @noRd
pknca_interval_window_key <- function(data, group_cols) {
  paste(
    pknca_interval_group_key(data, group_cols),
    sprintf("%.17g", as.numeric(data$start)),
    sprintf("%.17g", as.numeric(data$end)),
    sep = "\r"
  )
}

# Number the intervals of every combination of the grouping columns
#
# Within each combination of the grouping columns, the distinct intervals are
# numbered from 1 by start and then end, so rows of one interval (one per
# parameter) share a number.  The numbering only uses the interval windows,
# so it does not need an `interval_id`.
#
# @param data A data.frame with the grouping columns, `start`, and `end`
# @param group_cols The names of the grouping columns in `data`
# @returns An integer vector with the interval number of each row of `data`
# @keywords Internal
# @noRd
pknca_interval_number <- function(data, group_cols) {
  if (nrow(data) == 0) {
    return(integer())
  }
  start <- as.numeric(data$start)
  end <- as.numeric(data$end)
  if (anyNA(start) || anyNA(end)) {
    rlang::abort(
      "Every interval must have a start and an end to number the intervals; the interval start or end is missing in the results",
      class = "pknca_error_grpid_interval_missing"
    )
  }
  group_key <- pknca_interval_group_key(data, group_cols)
  window_key <- pknca_interval_window_key(data, group_cols)
  windows <- data.frame(group_id = match(group_key, unique(group_key)), start = start, end = end)
  first <- !duplicated(window_key)
  distinct <- windows[first, , drop = FALSE]
  distinct_key <- window_key[first]
  distinct_order <- order(distinct$group_id, distinct$start, distinct$end)
  distinct <- distinct[distinct_order, , drop = FALSE]
  distinct_key <- distinct_key[distinct_order]
  distinct$number <- stats::ave(distinct$group_id, distinct$group_id, FUN = seq_along)
  distinct$number[match(window_key, distinct_key)]
}

# The text of a column's values in PPGRPID
#
# A numeric column (named in `grpid_numeric`) must hold finite whole numbers of
# at least 1, and is written as the number, so "01" becomes "1".  Any other
# column is written as its text (a number without an exponent), which may not
# be empty or contain the '.' that separates the parts of the identifier.
# Distinct values of a column must be distinguishable in the text.
#
# @param values The values of one grouping column
# @param col The name of the column (for the messages)
# @param numeric Is the column in `grpid_numeric`?
# @returns A character vector the length of `values`
# @keywords Internal
# @noRd
pknca_grpid_value_text <- function(values, col, numeric) {
  distinct <- unique(values)
  text <- pknca_grpid_value_as_text(distinct)
  if (numeric) {
    number <- suppressWarnings(as.numeric(text))
    mask_bad <- is.na(number) | !is.finite(number) | number < 1 | number != round(number)
    if (any(mask_bad)) {
      rlang::abort(
        sprintf(
          "Column '%s' is in `grpid_numeric`, so its values must be whole numbers of at least 1; not whole numbers of at least 1: %s",
          col, paste(encodeString(text[mask_bad], quote = "\"", na.encode = TRUE), collapse = ", ")
        ),
        class = "pknca_error_grpid_numeric_invalid"
      )
    }
    text <- sprintf("%.0f", number)
  } else {
    if (anyNA(text) || any(!nzchar(text))) {
      rlang::abort(
        sprintf(
          "Column '%s' has an empty or missing value, which cannot be part of a group identifier; its distinct values are: %s",
          col, paste(encodeString(text, quote = "\"", na.encode = TRUE), collapse = ", ")
        ),
        class = "pknca_error_grpid_value_invalid"
      )
    }
    mask_dot <- grepl(pattern = ".", x = text, fixed = TRUE)
    if (any(mask_dot)) {
      rlang::abort(
        sprintf(
          "Column '%s' has a value containing '.', which separates the parts of a group identifier; values: %s",
          col, paste(encodeString(text[mask_dot], quote = "\""), collapse = ", ")
        ),
        class = "pknca_error_grpid_value_invalid"
      )
    }
  }
  if (anyDuplicated(text)) {
    rlang::abort(
      sprintf(
        "Column '%s' has distinct values that give the same group identifier text: %s",
        col, paste(unique(text[duplicated(text)]), collapse = ", ")
      ),
      class = "pknca_error_grpid_value_collision"
    )
  }
  text[match(values, distinct)]
}

# The text of each value, with numbers written in full (never "1e+05"), and
# NA for a missing value
#
# @param values A vector
# @returns A character vector
# @keywords Internal
# @noRd
pknca_grpid_value_as_text <- function(values) {
  if (!is.numeric(values)) {
    return(as.character(values))
  }
  text <- vapply(X = values, FUN = format, FUN.VALUE = "", scientific = FALSE, trim = TRUE, digits = 15)
  text[is.na(values)] <- NA_character_
  text
}

# Assemble PPGRPID text from its parts
#
# @param group_text A list with one character vector per grpid column, in
#   prefix order, each already written with its prefix
# @param number The interval number of each row (integer)
# @param width The minimum number of digits of the interval number
# @returns A character vector with `"<group 1>.<group 2>.I<nn>"`, or `"I<nn>"`
#   without grpid columns
# @keywords Internal
# @noRd
pknca_grpid_format <- function(group_text, number, width) {
  interval_text <- sprintf("I%0*d", width, as.integer(number))
  do.call(paste, c(unname(group_text), list(interval_text), sep = "."))
}

# Add the PPGRPID column
#
# The interval numbers, their width, and the checks of the values use every row
# of the results (`x$result`), not only the rows in the output, so filtering
# the output never renumbers an interval or hides a bad value.  An interval
# that produced no rows has no number.  The numbers count within each
# combination of the subject, the analyte, and the `grpid_cols` columns; other
# grouping columns do not enter PPGRPID.  The width is at least 2 digits, and
# grows with the largest interval number so that the text sorts in time order.
#
# @param ret The cdisc result data.frame (with `start` and `end` and the
#   grouping columns)
# @param x The PKNCAresults object
# @param grpid_cols,grpid_numeric See [as.data.frame.PKNCAresults()]
# @returns `ret` with the PPGRPID column added last
# @keywords Internal
# @noRd
pknca_cdisc_add_grpid <- function(ret, x, grpid_cols, grpid_numeric) {
  o_conc <- as_PKNCAconc(x)
  if (is.null(grpid_cols)) {
    grpid_cols <- x$data$grpid_cols
  }
  if (is.null(grpid_numeric)) {
    # The columns that PKNCAdata() marked numeric apply to the columns in use
    grpid_numeric <- intersect(x$data$grpid_numeric, names(grpid_cols))
  }
  assert_grpid_cols(grpid_cols, o_conc, grpid_numeric)
  all_rows <- as.data.frame(x$result)
  if (nrow(all_rows) == 0) {
    ret$PPGRPID <- character()
    return(ret)
  }
  # The subject is not a grouping column of sparse data, and a sparse result
  # has no subject column
  number_cols <-
    intersect(
      c(o_conc$columns$subject, o_conc$columns$groups$group_analyte, names(grpid_cols)),
      names(all_rows)
    )
  number <- pknca_interval_number(all_rows, number_cols)
  width <- max(2L, nchar(as.character(max(number))))
  group_text <- list()
  for (col in names(grpid_cols)) {
    group_text[[col]] <-
      paste0(
        grpid_cols[[col]],
        pknca_grpid_value_text(
          values = all_rows[[col]],
          col = col,
          numeric = col %in% grpid_numeric
        )
      )
  }
  grpid_all <- pknca_grpid_format(group_text, number, width)
  # Every returned row is a row of the results, so it finds its own window
  row_match <-
    match(
      pknca_interval_window_key(as.data.frame(ret), number_cols),
      pknca_interval_window_key(all_rows, number_cols)
    )
  if (anyNA(row_match)) {
    rlang::abort( # nocov start
      "A row of the output is not a row of the results, so its interval cannot be numbered.  This is likely a bug.",
      class = "pknca_error_internal_grpid_row"
    ) # nocov end
  }
  ret$PPGRPID <- grpid_all[row_match]
  ret
}
