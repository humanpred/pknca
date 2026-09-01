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
# =============================================================================


# =============================================================================
# 1.  Column Role Patterns
# =============================================================================

#' Get Default PK Column Patterns
#'
#' Returns a named list of regex patterns used to identify concentration,
#' dose, subject, and time columns.
#'
#' @return Named list with patterns for \code{conc}, \code{dose},
#'   \code{subject}, and \code{time}.
#' @keywords internal
get_pk_patterns <- function() {
  list(
    conc = c(
      "^conc$", "^aval$", "^pcstresn$", "^dv$", "^concentration$",
      "^conc\\b",        # starts with "conc" (e.g. R-mangled "Conc..ng.mL.")
      "^conc_",          # conc_ prefix (e.g. conc_plasma)
      "_conc$",          # _conc suffix
      "\\bconcentration\\b",
      "\\b(ng|mg|ug)[^a-z0-9]{0,3}ml\\b"  # ng/mL, mg/mL, ug/mL, or with _ . space as separator (e.g. "(ng/mL)" -> "..ng.mL.")
    ),
    dose = c(
      "^dose$", "^amount$", "^exdose$", "^amt$",
      "^dose\\b",        # starts with "dose" (e.g. R-mangled "Dose..mg.")
      "^dose_",          # dose_ prefix
      "_dose$",          # _dose suffix
      "\\b(mg|ug)[^a-z0-9]*$"   # mg or ug, optionally with trailing punctuation (e.g. "..mg.")
    ),
    subject = c(
      "^usubjid$", "^id$", "^subject$", "^subjectid$", "^ptno$",
      "^subj$", "^subj_id$", "^subject_id$",
      "^subject\\b",         # starts with "subject" (e.g. R-mangled "Subject.ID.")
      "^usubjid\\b"          # starts with "usubjid" (e.g. R-mangled "USUBJID.")
    ),
    time = c(
      "^time$", "^pctptnum$", "^atptn$", "^tad$", "^tafd$", "^hr$",
      "^hours$", "^time_h$", "^time_hr$",
      "^time\\b",           # starts with "time" (e.g. R-mangled "Time..hr.")
      "\\btime\\s*\\(.*\\)"   # e.g. "Time (h)"
    )
  )
}


#' Resolve PK Column Roles
#'
#' Matches column names against PK role patterns.
#'
#' @param file              Character. Optional file path for error messages.
#' @param names_vec         Character vector (or data frame) of column names.
#' @param patterns          Named list of regex patterns.
#' @param mode              One of \code{"match"}, \code{"detect"},
#'   \code{"detect_all"}.
#' @param stop_on_ambiguous Logical. Abort if multiple columns match one role?
#'
#' @keywords internal
resolve_pk_column_roles <- function(file              = NULL,
                                    names_vec,
                                    patterns,
                                    mode              = c("match", "detect", "detect_all"),
                                    stop_on_ambiguous = TRUE) {
  
  mode <- match.arg(mode)
  
  if (is.data.frame(names_vec)) {
    if (is.null(names_vec) || nrow(names_vec) == 0) {
      return(switch(mode,
                    detect     = FALSE,
                    detect_all = FALSE,
                    lapply(patterns, function(x) logical(0))))
    }
    names_vec <- names(names_vec)
  }
  
  lower_names <- tolower(names_vec)
  
  # Duplicate column check
  dupes <- lower_names[duplicated(lower_names)]
  if (length(dupes) > 0) {
    rlang::abort(sprintf(
      "%sDuplicate column names (case-insensitive): %s",
      if (!is.null(file)) sprintf("File '%s': ", basename(file)) else "",
      paste(unique(dupes), collapse = ", ")
    ))
  }
  
  if (length(lower_names) == 0) {
    return(switch(mode,
                  detect     = FALSE,
                  detect_all = FALSE,
                  lapply(patterns, function(x) logical(0))))
  }
  
  # Match each role
  role_hits <- lapply(patterns, function(pats) {
    combined_pat <- paste0("(", paste(pats, collapse = "|"), ")")
    grepl(combined_pat, lower_names, ignore.case = TRUE, perl = TRUE)
  })
  
  # Ambiguity check
  if (stop_on_ambiguous) {
    ambiguous_roles <- names(role_hits)[vapply(role_hits, sum, integer(1)) > 1L]
    if (length(ambiguous_roles) > 0) {
      details <- vapply(ambiguous_roles, function(r) {
        hits <- which(role_hits[[r]])
        sprintf("%s \u2190 %s", r, paste(names_vec[hits], collapse = ", "))
      }, character(1))
      rlang::abort(sprintf(
        "%sAmbiguous column matches:\n  %s\n\nFix: Rename columns or supply custom patterns.",
        if (!is.null(file)) sprintf("File '%s': ", basename(file)) else "",
        paste(details, collapse = "\n  ")
      ))
    }
  }
  
  switch(mode,
         detect     = any(vapply(role_hits, any, logical(1))),
         detect_all = vapply(role_hits, any, logical(1)),
         role_hits   # "match" -- return the full logical list
  )
}


#' Create Column Mapping from Column Names
#'
#' @keywords internal
create_column_mapping <- function(original_names, patterns) {
  matches <- resolve_pk_column_roles(
    names_vec         = tolower(original_names),
    patterns          = patterns,
    mode              = "match",
    stop_on_ambiguous = FALSE
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
#' @export
#' @examples
#' \dontrun{
#'   time_col <- get_mapped_column(df, "time")
#' }
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

#' Read Only Column Names from a File
#'
#' Attempts a zero-row or one-row read to obtain column names without loading
#' the full dataset. Some formats/readers (e.g. XPT, SAS7BDAT) ignore
#' \code{n_max}; in that case this falls back to a full import just to get
#' the names. Uses \code{rio::import()} exclusively (which delegates to
#' \code{haven} internally for XPT/SAS7BDAT), so no direct \code{haven}
#' dependency is needed here.
#'
#' @keywords internal
read_column_names_only <- function(f, verbose = FALSE) {
  
  col_names <- tryCatch({
    tmp <- rio::import(file = f, which = 1, n_max = 1L)
    names(tmp)
  }, error = function(e) {
    # n_max wasn't honored (or some other read hiccup) -- fall back to a
    # full import just to get the column names.
    tryCatch({
      tmp <- rio::import(file = f, which = 1)
      names(tmp)
    }, error = function(e2) {
      if (verbose) rlang::inform(sprintf("  Could not read columns from '%s': %s", basename(f), e2$message))
      NULL
    })
  })
  
  col_names
}


#' Detect the PK Role of a File
#'
#' Classifies a file as \code{"conc"}, \code{"dose"}, \code{"combined"}, or
#' \code{"unknown"} based on which PK column roles are present in its header.
#'
#' @keywords internal
detect_role <- function(f, patterns, verbose = FALSE) {
  
  col_names <- read_column_names_only(f, verbose = verbose)
  if (is.null(col_names)) return("unknown")
  
  if (verbose) rlang::inform(sprintf("  Columns in %s: %s", basename(f), paste(col_names, collapse = ", ")))
  
  role_matches <- resolve_pk_column_roles(
    names_vec         = col_names,
    patterns          = patterns,
    mode              = "detect_all",
    stop_on_ambiguous = FALSE
  )
  
  has_conc <- isTRUE(role_matches["conc"])
  has_dose <- isTRUE(role_matches["dose"])
  
  if (has_conc && has_dose) return("combined")
  if (has_conc)             return("conc")
  if (has_dose)             return("dose")
  
  if (verbose) rlang::inform(sprintf("  %s \u2192 no PK columns found", basename(f)))
  
  "unknown"
}


#' Remove Empty Rows and Columns
#'
#' Thin wrapper around \code{janitor::remove_empty()} that preserves any
#' custom attributes already attached to the data frame (e.g.
#' \code{column_mapping}).
#'
#' @keywords internal
remove_empty_data <- function(df, verbose = FALSE) {
  
  orig_rows <- nrow(df)
  orig_cols <- ncol(df)
  
  cleaned <- janitor::remove_empty(dat = df, which = c("rows", "cols"))
  
  removed_rows <- orig_rows - nrow(cleaned)
  removed_cols <- orig_cols - ncol(cleaned)
  
  if ((removed_rows > 0 || removed_cols > 0) && verbose) {
    rlang::inform(sprintf("  \u2022 Removed %d empty row(s), %d empty col(s)", removed_rows, removed_cols))
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
#' @keywords internal
read_one_pk_file <- function(filepath, patterns, verbose = TRUE) {
  
  if (verbose) rlang::inform(sprintf("Loading: %s", basename(filepath)))
  
  df <- tryCatch(
    rio::import(file = filepath, which = 1),
    error = function(e) rlang::abort(sprintf("Failed to read '%s': %s", filepath, e$message))
  )
  
  if (nrow(df) == 0) rlang::abort(sprintf("Empty file: %s", basename(filepath)))
  
  df <- remove_empty_data(df, verbose = verbose)
  
  mapping <- create_column_mapping(names(df), patterns)
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
#' \strong{On the conc-only case:} per \code{PKNCA::PKNCAdata.default()},
#' dose is only treated as genuinely absent when the \code{data.dose}
#' argument is omitted entirely (not passed as \code{NULL}) -- and in that
#' case \code{PKNCAdata()} cannot auto-generate AUC intervals from dose
#' times, so \code{intervals} must be supplied by hand. This function
#' mirrors that: if the file has no dose columns and you pass
#' \code{intervals}, you get a full \code{PKNCAdata} object built by
#' calling \code{PKNCAdata(data.conc = <conc>, intervals = intervals)}
#' (with \code{data.dose} genuinely omitted from the call, matching
#' PKNCA's own \code{missing(data.dose)} branch). If you don't pass
#' \code{intervals}, you just get the \code{PKNCAconc} object back.
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
#' @param intervals    Optional. A data frame of AUC intervals, in the
#'   format \code{PKNCAdata()} expects. Only used when the file has
#'   concentration columns but \strong{no} dose columns -- in that case
#'   \code{PKNCAdata()} cannot infer intervals automatically, so supplying
#'   this lets the function still return a full \code{PKNCAdata} object
#'   instead of a bare \code{PKNCAconc}. Ignored when dose columns are
#'   present (intervals are auto-derived from dose times as usual).
#' @param conc_options Optional named list of extra arguments passed on to
#'   \code{PKNCAconc()} (e.g. \code{list(exclude = "excl", sparse = TRUE)}).
#' @param dose_options Optional named list of extra arguments passed on to
#'   \code{PKNCAdose()} (e.g. \code{list(route = "extravascular")}).
#' @param verbose      Logical. Print progress messages? Default \code{TRUE}.
#'
#' @return A \code{PKNCAdata}, \code{PKNCAconc}, or \code{PKNCAdose} object,
#'   depending on what was found in the file (and whether \code{intervals}
#'   was supplied for the conc-only case).
#'
#' @export
#' @examples
#' \dontrun{
#' # A single file that has both concentration and dose columns
#' o_data <- read_pk_file("combined_pk.csv")
#' nca_result <- PKNCA::pk.nca(o_data)
#'
#' # A file with only concentration columns -> PKNCAconc object
#' o_conc <- read_pk_file("conc_only.xlsx")
#'
#' # Same file, but with intervals supplied -> full PKNCAdata object,
#' # since dose is genuinely absent and PKNCA needs manual intervals
#' o_data <- read_pk_file(
#'   "conc_only.xlsx",
#'   intervals = data.frame(start = 0, end = 24, auclast = TRUE)
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
#' }
read_pk_file <- function(path,
                         patterns     = get_pk_patterns(),
                         conc_formula = NULL,
                         dose_formula = NULL,
                         intervals    = NULL,
                         conc_options = list(),
                         dose_options = list(),
                         verbose      = TRUE) {
  
  # ---- argument validation --------------------------------------------------
  checkmate::assert_string(path, min.chars = 1)
  checkmate::assert_file_exists(path)
  checkmate::assert_list(patterns, min.len = 1, names = "named")
  checkmate::assert_data_frame(intervals, null.ok = TRUE, min.rows = 1)
  checkmate::assert_list(conc_options, names = "named")
  checkmate::assert_list(dose_options, names = "named")
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
  
  # ---- 1. detect what's in the file ------------------------------------------
  role <- detect_role(path, patterns = patterns, verbose = verbose)
  
  if (role == "unknown") {
    rlang::abort(sprintf(
      "Could not detect concentration or dose columns in '%s'.\n%s",
      basename(path),
      "Ensure the file has recognizable column names, or adjust `patterns`."
    ))
  }
  
  has_conc <- role %in% c("conc", "combined")
  has_dose <- role %in% c("dose", "combined")
  
  if (verbose) {
    rlang::inform(
      sprintf(
        "  \u2022 %s \u2192 %s (%s)",
        basename(path), role,
        paste(c(if (has_conc) "concentration", if (has_dose) "dose"), collapse = " + ")
      )
    )
  }
  
  # ---- 2. read the file once and map columns ---------------------------------
  df <- read_one_pk_file(path, patterns = patterns, verbose = verbose)
  
  mapping  <- attr(df, "column_mapping")
  time_col <- mapping$time
  
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
      if (verbose) rlang::inform(sprintf("  \u2022 Auto-built conc_formula: %s", deparse(conc_formula)))
    }
    
    o_conc <- do.call(PKNCA::PKNCAconc, c(list(data = df, formula = conc_formula), conc_options))
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
      if (verbose) rlang::inform(sprintf("  \u2022 Auto-built dose_formula: %s", deparse(dose_formula)))
    }
    
    o_dose <- do.call(PKNCA::PKNCAdose, c(list(data = df, formula = dose_formula), dose_options))
  }
  
  # ---- 5. return the appropriate object ----------------------------------------
  if (has_conc && has_dose) {
    if (verbose) rlang::inform("File has both concentration and dose columns -> returning a PKNCAdata object.")
    # Both data.conc and data.dose are supplied -- PKNCAdata() auto-derives
    # intervals from the dose times, exactly like PKNCAdata.default's
    # normal (non-missing dose) branch.
    return(PKNCA::PKNCAdata(o_conc, o_dose))
  }
  if (has_conc) {
    if (!is.null(intervals)) {
      if (verbose) {
        rlang::inform(
          "No dose columns found; `data.dose` is genuinely omitted from the PKNCAdata() call (per PKNCAdata.default's missing(data.dose) branch), and the supplied `intervals` is used since PKNCA can't auto-derive it without dose times."
        )
      }
      # NOTE: data.dose is deliberately NOT passed here (not even as NULL) --
      # PKNCAdata.default() distinguishes missing(data.dose) from an explicit
      # NULL, and only the former triggers its `ret$dose <- NA` branch.
      return(PKNCA::PKNCAdata(data.conc = o_conc, intervals = intervals))
    }
    if (verbose) {
      rlang::inform("File has concentration columns only -> returning a PKNCAconc object. Pass `intervals` to get a full PKNCAdata object instead.")
    }
    return(o_conc)
  }
  if (has_dose) {
    if (verbose) rlang::inform("File has dose columns only -> returning a PKNCAdose object.")
    return(o_dose)
  }
}

