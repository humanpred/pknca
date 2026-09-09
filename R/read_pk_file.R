# =============================================================================
# PK Data Toolkit -- read_pk_file()
# =============================================================================
# Loads ONE pharmacokinetic data file (XPT, XLSX, XLS, CSV, TXT, SAS7BDAT)
# that may contain concentration data, dose data, or both (a "combined"
# file), and returns the matching PKNCA object:
#
#   both conc + dose columns present -> a PKNCAdata object
#   only conc columns present        -> a PKNCAconc object
#   only dose columns present        -> a PKNCAdose object
#
# Column roles (subject/time/conc/dose) are auto-detected from the file's
# header via regex patterns, and the PKNCA formula(s) are built
# automatically from those roles unless supplied explicitly.
#
# NOTE ON COLUMN NAMING: pattern matching here is intentionally strict.
# Column headers are expected to be clean and unambiguous (e.g. "conc",
# "dose", "usubjid") -- we do not try to guess at mangled or partial names
# (e.g. an R-mangled "Conc..ng.mL." or a bare "mg" column). Clean up column
# names in your data before calling this function if needed.
# =============================================================================


# =============================================================================
# 1.  Column Role Patterns
# =============================================================================

#' Get Default PK Column Patterns
#'
#' Returns a named list of regex patterns used to identify concentration,
#' dose, subject, and time columns. Patterns are deliberately strict:
#' columns must clearly and unambiguously indicate their role. We do not
#' guess based on partial/mangled names (e.g. a column that merely starts
#' with "dose", or a bare "mg"/"ug" unit column), since that risks silently
#' picking the wrong column.
#'
#' @return Named list with patterns for \code{conc}, \code{dose},
#'   \code{subject}, and \code{time}.
#' @keywords internal
get_pk_patterns <- function() {
  list(
    conc = c(
      "^conc$", "^aval$", "^pcstresn$", "^dv$", "^concentration$"
    ),
    dose = c(
      "^dose$", "^amount$", "^exdose$", "^amt$", "^ecdose$"
    ),
    subject = c(
      "^usubjid$", "^id$", "^subject$", "^subjectid$", "^ptno$",
      "^subj$", "^subj_id$", "^subject_id$"
    ),
    time = c(
      "^time$", "^pctptnum$", "^atptn$", "^tad$", "^tafd$", "^hr$",
      "^hours$", "^time_h$", "^time_hr$"
    )
  )
}


#' Check Whether Ambiguously-Matched Columns Are Equivalent
#'
#' Used to decide whether more than one column matching the same role is
#' actually a problem. For most roles, "equivalent" means the columns hold
#' identical values. For the \code{subject} role, two columns are also
#' considered equivalent if they induce the same grouping of rows once each
#' is treated as a factor in its observed order (i.e. two different
#' subject-identifier schemes for the same subjects).
#'
#' @param cols_df Data frame containing just the ambiguously-matched columns.
#' @param role    Character. The role that matched more than one column.
#' @keywords internal
columns_equivalent <- function(cols_df, role) {
  if (ncol(cols_df) < 2) return(TRUE)
  
  first <- cols_df[[1]]
  identical_vals <- vapply(
    cols_df[-1],
    function(x) isTRUE(all.equal(x, first)),
    logical(1)
  )
  if (all(identical_vals)) return(TRUE)
  
  if (identical(role, "subject")) {
    first_grp <- as.integer(factor(first, levels = unique(first)))
    same_grp <- vapply(cols_df[-1], function(x) {
      isTRUE(all.equal(as.integer(factor(x, levels = unique(x))), first_grp))
    }, logical(1))
    return(all(same_grp))
  }
  
  FALSE
}


#' Resolve PK Column Roles
#'
#' Matches column names against PK role patterns. If more than one column
#' matches the same role, this is an error -- UNLESS \code{data} is supplied
#' and the matching columns are equivalent (see \code{\link{columns_equivalent}}).
#'
#' @param file      Character. Optional file path for error messages.
#' @param names_vec Character vector of column names (always a plain
#'   character vector in practice -- every call site passes \code{names(df)}
#'   -- but may legitimately be length 0 if every column was dropped as
#'   empty).
#' @param patterns  Named list of regex patterns.
#' @param data      Optional data frame used to check whether ambiguous
#'   matches are actually equivalent columns. If omitted, any role matched
#'   by more than one column is always an error.
#' @return Named list with logical vectors indicating matches for each role.
#' @keywords internal
resolve_pk_column_roles <- function(file      = NULL,
                                    names_vec,
                                    patterns,
                                    data      = NULL) {
  
  checkmate::assert_list(patterns, names = "named", min.len = 1)
  checkmate::assert_character(names_vec, null.ok = TRUE)
  
  # No columns to match against -- return the "nothing matched" shape.
  if (is.null(names_vec) || length(names_vec) == 0) {
    return(lapply(patterns, function(x) logical(0)))
  }
  
  lower_names <- tolower(names_vec)
  
  # Duplicate column check. Compare case-insensitively, but report the
  # original (non-lowercased) names so the user sees exactly what to fix.
  dupes <- names_vec[duplicated(lower_names)]
  if (length(dupes) > 0) {
    rlang::abort(sprintf(
      "%sDuplicate column names (case-insensitive): %s",
      if (!is.null(file)) sprintf("File '%s': ", basename(file)) else "",
      paste(dupes, collapse = ", ")
    ))
  }
  
  # Match each role
  role_hits <- lapply(patterns, function(pats) {
    combined_pat <- paste0("(", paste(pats, collapse = "|"), ")")
    grepl(combined_pat, lower_names, ignore.case = TRUE, perl = TRUE)
  })
  
  # Ambiguity check: more than one column matching a role is only
  # acceptable when those columns are equivalent.
  ambiguous_roles <- names(role_hits)[vapply(role_hits, sum, integer(1)) > 1L]
  if (length(ambiguous_roles) > 0) {
    details <- character(0)
    for (r in ambiguous_roles) {
      hits <- which(role_hits[[r]])
      cols <- names_vec[hits]
      equivalent <- !is.null(data) && columns_equivalent(data[cols], role = r)
      if (!equivalent) {
        details <- c(details, sprintf("%s -> %s", r, paste(cols, collapse = ", ")))
      }
    }
    if (length(details) > 0) {
      rlang::abort(sprintf(
        "%sAmbiguous column matches:\n  %s\n\nFix: Rename columns or supply custom patterns.",
        if (!is.null(file)) sprintf("File '%s': ", basename(file)) else "",
        paste(details, collapse = "\n  ")
      ))
    }
  }
  
  role_hits
}


#' Create Column Mapping from a Data Frame
#'
#' @param df       Data frame whose columns are to be mapped to PK roles.
#' @param patterns Named list of regex patterns.
#' @keywords internal
create_column_mapping <- function(df, patterns) {
  original_names <- names(df)
  matches <- resolve_pk_column_roles(
    names_vec = original_names,
    patterns  = patterns,
    data      = df
  )
  mapping <- vector("list", length(patterns))
  names(mapping) <- names(patterns)
  for (role in names(patterns)) {
    idx <- which(matches[[role]])
    mapping[[role]] <- if (length(idx) > 0) original_names[idx[1L]] else NA_character_
  }
  mapping
}


#' Get Mapped Column Name
#'
#' Returns the actual column name for a given PK role.
#'
#' @param data A data frame carrying a \code{column_mapping} attribute
#'   (i.e. one produced internally by \code{read_pk_file()}).
#' @param role Character. One of \code{"subject"}, \code{"time"},
#'   \code{"conc"}, or \code{"dose"}.
#'
#' @return Character string -- the matched column name.
#' @keywords internal
get_mapped_column <- function(data, role) {
  
  mapping <- attr(data, "column_mapping")
  if (is.null(mapping)) {
    rlang::abort(
      message = "Missing column mapping.",
      body = c(
        "i" = "This data frame was not produced by read_pk_file().",
        ">" = "Use read_pk_file() to load and map your data."
      )
    )
  }
  
  col <- mapping[[role]]
  if (is.na(col)) {
    available <- names(mapping)[!is.na(unlist(mapping))]
    rlang::abort(
      message = sprintf("Role '%s' not found in column mapping.", role),
      body = c(
        "i" = sprintf("Available roles: %s", paste(available, collapse = ", ")),
        ">" = "Check your data or adjust column patterns via get_pk_patterns()."
      )
    )
  }
  col
}


# =============================================================================
# 2.  File Reading & Role Detection
# =============================================================================

#' Remove Empty Rows and Columns
#'
#' Drops rows and columns that are entirely \code{NA} (or, for character
#' columns, entirely blank/whitespace), preserving any custom attributes
#' already attached to the data frame (e.g. \code{column_mapping}).
#'
#' @keywords internal
remove_empty_data <- function(df, verbose = FALSE) {
  
  orig_rows <- nrow(df)
  orig_cols <- ncol(df)
  
  # Check each column for blank/NA cells -- column by column, so character
  # and non-character columns are each handled with the right rule (avoids
  # coercing the whole data frame to a matrix, which can silently mangle
  # mixed-type columns).
  blank_cols <- lapply(df, function(col) {
    if (is.character(col)) {
      is.na(col) | trimws(col) == ""
    } else {
      is.na(col)
    }
  })
  blank_mat <- do.call(cbind, blank_cols)
  
  row_keep <- rowSums(!blank_mat) > 0
  col_keep <- colSums(!blank_mat) > 0
  
  cleaned <- df[row_keep, col_keep, drop = FALSE]
  
  removed_rows <- orig_rows - nrow(cleaned)
  removed_cols <- orig_cols - ncol(cleaned)
  
  if ((removed_rows > 0 || removed_cols > 0) && verbose) {
    rlang::inform(sprintf("  - Removed %d empty row(s), %d empty col(s)", removed_rows, removed_cols))
  }
  
  # Preserve any custom attributes already present (e.g. column_mapping)
  keep_attrs <- setdiff(names(attributes(df)), c("names", "row.names", "class"))
  for (a in keep_attrs) attr(cleaned, a) <- attr(df, a)
  class(cleaned) <- class(df)
  
  cleaned
}


#' Read a Single PK File
#'
#' Uses \code{rio::import()} to read the file, drops entirely empty rows and
#' columns, and attaches a \code{column_mapping} attribute.
#'
#' @param ... Additional arguments passed on to \code{rio::import()} (e.g.
#'   \code{sheet}, \code{which}, \code{col_types}, encoding options, etc.).
#' @keywords internal
read_one_pk_file <- function(filepath, patterns, verbose = TRUE, ...) {
  
  if (verbose) rlang::inform(sprintf("Loading: %s", basename(filepath)))
  
  df <- tryCatch(
    rio::import(file = filepath, ...),
    error = function(e) rlang::abort(sprintf("Failed to read '%s': %s", filepath, e$message))
  )
  
  if (nrow(df) == 0) rlang::abort(sprintf("Empty file: %s", basename(filepath)))
  
  df <- remove_empty_data(df, verbose = verbose)
  
  mapping <- create_column_mapping(df, patterns)
  attr(df, "column_mapping") <- mapping
  class(df) <- c("pk_data", class(df))
  df
}


# =============================================================================
# 3.  Public API -- read_pk_file()
# =============================================================================

#' Load a Single PK File and Return the Matching PKNCA Object
#'
#' Reads \strong{one} file that may contain concentration data, dose data,
#' or both (a "combined" file), auto-detects which columns are present, and
#' returns the corresponding PKNCA object:
#' \itemize{
#'   \item Both conc + dose columns present -> a \code{\link[PKNCA]{PKNCAdata}} object.
#'   \item Only conc columns present        -> a \code{\link[PKNCA]{PKNCAconc}} object.
#'   \item Only dose columns present        -> a \code{\link[PKNCA]{PKNCAdose}} object.
#' }
#'
#' Column roles (\code{subject}/\code{time}/\code{conc}/\code{dose}) are
#' auto-detected from the header via \code{patterns} (see
#' \code{\link{get_pk_patterns}}), and the PKNCA formula(s) are built
#' automatically from those roles (as \code{value ~ time | subject}) unless
#' you supply \code{conc_formula}/\code{dose_formula} yourself -- useful if
#' you need custom grouping, e.g. \code{conc ~ time | treatment + subject}.
#' The file must already contain a recognizable subject column -- no
#' default subject ID is created, and concentration values are used as-is
#' (no BLQ string conversion -- PKNCA handles BLQ itself via its
#' \code{conc.blq} options at \code{pk.nca()} time); pre-process the file
#' first if needed.
#'
#' \strong{On the conc-only case:} per \code{PKNCAdata.default()}, dose is
#' only treated as genuinely absent when the \code{data.dose} argument is
#' omitted entirely (not passed as \code{NULL}) -- and in that case
#' \code{PKNCAdata()} cannot auto-generate AUC intervals from dose times, so
#' \code{intervals} must be supplied by hand (via \code{data_args}). This
#' function mirrors that: if the file has no dose columns and you pass
#' \code{data_args} (e.g. \code{list(intervals = ...)}), you get a full
#' \code{PKNCAdata} object with \code{data.dose} genuinely omitted from the
#' call, matching PKNCA's own \code{missing(data.dose)} branch. If you
#' don't pass \code{data_args}, you just get the \code{PKNCAconc} object
#' back.
#'
#' @param path         Path to a single PK file (.xpt, .xlsx, .xls, .csv,
#'   .txt, .sas7bdat) -- may hold concentration data, dose data, or both.
#' @param patterns     Named list of regex patterns for PK column roles.
#'   Must contain all four roles -- \code{conc}, \code{dose},
#'   \code{subject}, \code{time} -- since the rest of the toolkit relies
#'   on each being resolvable. If you want to override this, start from
#'   \code{\link{get_pk_patterns}} and modify the role(s) you need, e.g.
#'   \code{p <- get_pk_patterns(); p$conc <- c(p$conc, "^pcorres$")} to
#'   extend, or \code{p$conc <- "Concen"} to replace outright -- either
#'   way, pass the complete \code{p} back in. Partial lists (missing a
#'   role) are rejected with an error rather than silently falling back,
#'   so you always know exactly what's being matched.
#' @param conc_formula Optional. Formula for \code{PKNCAconc()}. Auto-built
#'   from detected columns if omitted (and conc columns are present).
#' @param dose_formula Optional. Formula for \code{PKNCAdose()}. Auto-built
#'   from detected columns if omitted (and dose columns are present).
#' @param conc_args    Optional named list of extra arguments passed on to
#'   \code{PKNCAconc()} (e.g. \code{list(exclude = "excl", sparse = TRUE)}).
#' @param dose_args    Optional named list of extra arguments passed on to
#'   \code{PKNCAdose()} (e.g. \code{list(route = "extravascular")}).
#' @param data_args    Optional named list of extra arguments passed on to
#'   \code{PKNCAdata()} (e.g. \code{list(intervals = ...)}). Only relevant
#'   when the file has concentration columns and no dose columns, since
#'   otherwise \code{PKNCAdata()} auto-derives intervals from dose times.
#' @param verbose      Logical. Print progress messages? Default \code{TRUE}.
#' @param ...          Additional arguments passed on to \code{rio::import()}
#'   for reading the file (e.g. \code{sheet}, \code{col_types}, etc.).
#'
#' @return A \code{PKNCAdata}, \code{PKNCAconc}, or \code{PKNCAdose} object,
#'   depending on what was found in the file.
#'
#' @export
#' @examples
#' \dontrun{
#' # A single file that has both concentration and dose columns
#' o_data <- read_pk_file("combined_pk.csv")
#' nca_result <- pk.nca(o_data)
#'
#' # A file with only concentration columns -> PKNCAconc object
#' o_conc <- read_pk_file("conc_only.xlsx")
#'
#' # Same file, but with intervals supplied -> full PKNCAdata object,
#' # since dose is genuinely absent and PKNCA needs manual intervals
#' o_data <- read_pk_file(
#'   "conc_only.xlsx",
#'   data_args = list(intervals = data.frame(start = 0, end = 24, auclast = TRUE))
#' )
#'
#' # Force custom grouping instead of auto-built "value ~ time | subject"
#' o_data <- read_pk_file(
#'   "combined_pk.csv",
#'   conc_formula = conc ~ time | treatment + subject,
#'   dose_formula = dose ~ time | treatment + subject
#' )
#'
#' # Override conc/dose patterns for one oddly-named file -- must still
#' # supply subject/time (here, kept as the defaults) since partial
#' # patterns lists are rejected.
#' p <- get_pk_patterns()
#' p$conc <- "Concen"
#' p$dose <- "Dosemg"
#' o_data <- read_pk_file("odd_headers.csv", patterns = p)
#'
#' # Read a specific sheet from an Excel file
#' o_data <- read_pk_file("data.xlsx", sheet = "Concentration Data")
#' }
read_pk_file <- function(path,
                         patterns     = get_pk_patterns(),
                         conc_formula = NULL,
                         dose_formula = NULL,
                         conc_args    = list(),
                         dose_args    = list(),
                         data_args    = list(),
                         verbose      = TRUE,
                         ...) {
  
  # ---- argument validation --------------------------------------------------
  checkmate::assert_string(path, min.chars = 1)
  checkmate::assert_file_exists(path)
  checkmate::assert_list(patterns, min.len = 1, names = "named")
  checkmate::assert_list(conc_args, names = "named")
  checkmate::assert_list(dose_args, names = "named")
  checkmate::assert_list(data_args, names = "named")
  checkmate::assert_flag(verbose)
  
  required_roles <- c("conc", "dose", "subject", "time")
  missing_roles  <- setdiff(required_roles, names(patterns))
  if (length(missing_roles) > 0) {
    rlang::abort(c(
      sprintf("`patterns` is missing role(s): %s", paste(missing_roles, collapse = ", ")),
      "i" = "All four roles (conc, dose, subject, time) must be present.",
      ">" = "Start from get_pk_patterns() and modify only the role(s) you need to change."
    ))
  }
  lapply(patterns, function(p) {
    if (!is.character(p)) rlang::abort("Each entry in `patterns` must be a character vector.")
  })
  
  # ---- 1. read the file once (columns are mapped as part of this) -----------
  df <- read_one_pk_file(path, patterns = patterns, verbose = verbose, ...)
  
  mapping  <- attr(df, "column_mapping")
  time_col <- mapping$time
  
  # ---- 2. determine what's in the file, from the mapping already built ------
  # (create_column_mapping() -- via resolve_pk_column_roles() -- already did
  # the matching, including the ambiguity/equivalence check with access to
  # the actual data. Re-deriving role from `mapping` avoids re-running that
  # match a second time without `data`, which would incorrectly re-reject
  # ambiguous-but-equivalent columns that were already accepted above.)
  has_conc <- !is.na(mapping$conc)
  has_dose <- !is.na(mapping$dose)
  
  if (!has_conc && !has_dose) {
    rlang::abort(sprintf(
      "Could not detect concentration or dose columns in '%s'.\n%s",
      basename(path),
      "Ensure the file has recognizable column names, or adjust `patterns`."
    ))
  }
  
  role <- if (has_conc && has_dose) "combined" else if (has_conc) "conc" else "dose"
  
  if (verbose) {
    rlang::inform(
      sprintf(
        "  - %s -> %s (%s)",
        basename(path), role,
        paste(c(if (has_conc) "concentration", if (has_dose) "dose"), collapse = " + ")
      )
    )
  }
  
  # ---- 3. concentration side --------------------------------------------------
  o_conc <- NULL
  if (has_conc) {
    if (is.null(conc_formula)) {
      conc_col <- get_mapped_column(df, "conc")
      subj_col <- get_mapped_column(df, "subject")
      if (is.na(time_col)) {
        rlang::abort("No time column detected -- cannot auto-build `conc_formula`. Supply it explicitly.")
      }
      conc_formula <- stats::as.formula(sprintf("%s ~ %s | %s", conc_col, time_col, subj_col))
      if (verbose) rlang::inform(sprintf("  - Auto-built conc_formula: %s", deparse(conc_formula)))
    }
    
    o_conc <- do.call(PKNCAconc, c(list(data = df, formula = conc_formula), conc_args))
  }
  
  # ---- 4. dose side -------------------------------------------------------------
  o_dose <- NULL
  if (has_dose) {
    if (is.null(dose_formula)) {
      dose_col <- get_mapped_column(df, "dose")
      subj_col <- get_mapped_column(df, "subject")
      if (is.na(time_col)) {
        rlang::abort("No time column detected -- cannot auto-build `dose_formula`. Supply it explicitly.")
      }
      dose_formula <- stats::as.formula(sprintf("%s ~ %s | %s", dose_col, time_col, subj_col))
      if (verbose) rlang::inform(sprintf("  - Auto-built dose_formula: %s", deparse(dose_formula)))
    }
    
    o_dose <- do.call(PKNCAdose, c(list(data = df, formula = dose_formula), dose_args))
  }
  
  # ---- 5. return the appropriate object ----------------------------------------
  if (has_conc && has_dose) {
    if (verbose) rlang::inform("File has both concentration and dose columns -> returning a PKNCAdata object.")
    # Both data.conc and data.dose are supplied -- PKNCAdata() auto-derives
    # intervals from the dose times, exactly like PKNCAdata.default's
    # normal (non-missing dose) branch.
    return(do.call(PKNCAdata, c(list(data.conc = o_conc, data.dose = o_dose), data_args)))
  }
  if (has_conc) {
    if (length(data_args) > 0) {
      if (verbose) {
        rlang::inform(
          "No dose columns found; `data.dose` is genuinely omitted from the PKNCAdata() call (per PKNCAdata.default's missing(data.dose) branch), and `data_args` (e.g. intervals) is used since PKNCA can't auto-derive it without dose times."
        )
      }
      # NOTE: data.dose is deliberately NOT passed here (not even as NULL) --
      # PKNCAdata.default() distinguishes missing(data.dose) from an explicit
      # NULL, and only the former triggers its `ret$dose <- NA` branch.
      return(do.call(PKNCAdata, c(list(data.conc = o_conc), data_args)))
    }
    if (verbose) {
      rlang::inform("File has concentration columns only -> returning a PKNCAconc object. Pass `data_args` (e.g. intervals) to get a full PKNCAdata object instead.")
    }
    return(o_conc)
  }
  if (has_dose) {
    if (verbose) rlang::inform("File has dose columns only -> returning a PKNCAdose object.")
    return(o_dose)
  }
}