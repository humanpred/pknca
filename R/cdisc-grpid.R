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
# @param grpid_numeric A character vector of names in `grpid_cols`
# @param o_conc The PKNCAconc object that defines the grouping columns
# @returns `grpid_cols`, unchanged (`NULL` stays `NULL`)
# @keywords Internal
# @noRd
assert_grpid_cols <- function(grpid_cols, o_conc, grpid_numeric = character()) {
  if (!is.null(grpid_cols)) {
    if (
      !is.character(grpid_cols) ||
        anyNA(grpid_cols) ||
        (length(grpid_cols) > 0 && !checkmate::test_names(names(grpid_cols), type = "unique"))
    ) {
      rlang::abort(
        "`grpid_cols` must be NULL or a character vector with a unique name for each value: the grouping column names, with the text written before each column's value as the values",
        class = "pknca_error_grpid_cols_invalid"
      )
    }
    if (any(grepl(pattern = ".", x = grpid_cols, fixed = TRUE))) {
      rlang::abort(
        "The text written before a value in `grpid_cols` may not contain '.', because '.' separates the parts of the group identifier",
        class = "pknca_error_grpid_cols_invalid"
      )
    }
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
      "`grpid_numeric` must be a character vector of column names",
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

# Number the intervals of every combination of the grouping columns
#
# Within each combination of the grouping columns, the distinct intervals are
# numbered from 1 by numeric start and then end, so rows of one interval (one
# per parameter) share a number.  The numbering only uses the interval windows,
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
  # One integer per distinct group combination, in order of first appearance
  group_id <-
    if (length(group_cols) == 0) {
      rep(1L, nrow(data))
    } else {
      group_key <- do.call(paste, c(lapply(data[, group_cols, drop = FALSE], as.character), sep = "\r"))
      match(group_key, unique(group_key))
    }
  # Integer ids, not the numbers' text, identify a window so that windows never
  # collide through text rounding
  window_key <- paste(group_id, match(start, unique(start)), match(end, unique(end)))
  windows <- data.frame(group_id = group_id, start = start, end = end)
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
# column is written as its text, which may not be empty or contain the '.' that
# separates the parts of the identifier.  Distinct values of a column must be
# distinguishable in the text.
#
# @param values The values of one grouping column
# @param col The name of the column (for the messages)
# @param numeric Is the column in `grpid_numeric`?
# @returns A character vector the length of `values`
# @keywords Internal
# @noRd
pknca_grpid_value_text <- function(values, col, numeric) {
  distinct <- unique(values)
  text <- as.character(distinct)
  if (numeric) {
    number <- suppressWarnings(as.numeric(text))
    if (anyNA(number) || any(!is.finite(number)) || any(number < 1) || any(number != round(number))) {
      rlang::abort(
        sprintf(
          "Column '%s' is in `grpid_numeric`, so its values must be whole numbers of at least 1; the values are: %s",
          col, paste(text, collapse = ", ")
        ),
        class = "pknca_error_grpid_numeric_invalid"
      )
    }
    text <- sprintf("%.0f", number)
  } else {
    if (anyNA(text) || any(!nzchar(text))) {
      rlang::abort(
        sprintf("Column '%s' has an empty or missing value, which cannot be part of a group identifier", col),
        class = "pknca_error_grpid_value_invalid"
      )
    }
    if (any(grepl(pattern = ".", x = text, fixed = TRUE))) {
      rlang::abort(
        sprintf(
          "Column '%s' has a value containing '.', which separates the parts of a group identifier; values: %s",
          col, paste(text[grepl(pattern = ".", x = text, fixed = TRUE)], collapse = ", ")
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
# The interval numbers and their width come from every row of the results, not
# only the rows in the output, so that filtering the output does not renumber
# an interval.  The width is at least 2 digits, and grows with the largest
# interval number so that the text sorts in time order.
#
# @param ret The cdisc result data.frame (with `start` and the grouping columns)
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
  assert_grpid_cols(grpid_cols, o_conc, grpid_numeric)
  group_cols <- intersect(unlist(o_conc$columns$groups), names(ret))
  key_cols <- c(group_cols, "start", "end")
  all_rows <- as.data.frame(x$result)[, key_cols, drop = FALSE]
  rows <- as.data.frame(ret)[, key_cols, drop = FALSE]
  number_all <- pknca_interval_number(rbind(all_rows, rows), group_cols)
  number <- number_all[length(number_all) - nrow(rows) + seq_len(nrow(rows))]
  width <- max(2L, nchar(as.character(max(number_all, 1L))))
  group_text <- list()
  for (col in names(grpid_cols)) {
    group_text[[col]] <-
      paste0(
        grpid_cols[[col]],
        pknca_grpid_value_text(
          values = as.data.frame(ret)[[col]],
          col = col,
          numeric = col %in% grpid_numeric
        )
      )
  }
  ret$PPGRPID <- pknca_grpid_format(group_text, number, width)
  ret
}
