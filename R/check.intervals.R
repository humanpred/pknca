#' Check the formatting of a calculation interval specification data frame.
#'
#' Calculation interval specifications are data frames defining what
#' calculations will be required and summarized from all time intervals. Note:
#' parameters which are not requested may be calculated if it is required for
#' (or computed at the same time as) a requested parameter.
#'
#' `start` and `end` time must always be given as columns, and the `start` must
#' be before the `end`.  Other columns define the parameters to be calculated
#' and the groupings to apply the intervals to.
#'
#' Data are selected for calculation within an interval by the time of the
#' measurement or dose: a row is included when its time is at or after `start`
#' and at or before `end` (a dose exactly at `end` is not included in the
#' interval).  For duration data (for example, urine collections or intravenous
#' infusions), the time is the start of the collection or administration, and
#' the duration is not considered during selection: a collection that starts
#' within the interval and ends after `end` is included and contributes its
#' full amount to the interval.  For the simplest interpretation of results,
#' align collection start and end times with interval boundaries.
#'
#' @param x The data frame specifying what to calculate during each time
#'   interval
#' @returns x The potentially updated data frame with the interval calculation
#'   specification.
#'
#' @family Interval specifications
#' @seealso The vignette "Selection of Calculation Intervals"
#' @export
check.interval.specification <- function(x) {
  if (!is.data.frame(x)) {
    # Just a warning and let as.data.frame make it an error if it can't be
    # coerced.
    rlang::warn("Interval specification must be a data.frame", class = "pknca_warning_interval_not_df")
    x <- as.data.frame(x)
  }
  if (nrow(x) == 0) {
    rlang::abort("interval specification has no rows", class = "pknca_error_interval_no_rows")
  }
  # Confirm that the minimal columns (start and end) exist
  if (length(missing.required.cols <- setdiff(c("start", "end"), names(x))) > 0) {
    rlang::abort(
      sprintf(
        "Column(s) %s missing from interval specification",
        paste0("'", missing.required.cols, "'", collapse = ", ")
      ),
      class = "pknca_error_interval_missing_cols"
    )
  }
  interval_cols <- get.interval.cols()
  # Check the edit of each column
  for (n in names(interval_cols)) {
    if (!(n %in% names(x))) {
      if (is.vector(interval_cols[[n]]$values)) {
        # Set missing columns to the default value
        x[[n]] <- interval_cols[[n]]$values[1]
      } else {
        # It would probably take malicious code to get here (altering
        # the intervals without using add.interval.col
        rlang::abort(sprintf("Cannot assign default value for interval column %s", n), class = "pknca_error_interval_default_value")  # nocov
      }
    } else {
      # Confirm the edits of the given columns
      if (is.vector(interval_cols[[n]]$values)) {
        if (!all(x[[n]] %in% interval_cols[[n]]$values)) {
          invalid_vals <- unique(setdiff(x[[n]], interval_cols[[n]]$values))
          rlang::abort(
            sprintf(
              "Invalid value(s) in column %s:%s", n,
              paste(invalid_vals, collapse = ", ")
            ),
            class = "pknca_error_interval_invalid_value"
          )
        }

      } else if (is.function(interval_cols[[n]]$values)) {
        if (is.factor(x[[n]])) {
          rlang::abort(
            sprintf("Interval column '%s' should not be a factor", n),
            class = "pknca_error_interval_factor_col"
          )
        }
        interval_cols[[n]]$values(x[[n]])
      } else {
        rlang::abort(sprintf("Invalid 'values' for column specification %s (please report this as a bug).", n), class = "pknca_error_interval_invalid_col_spec")  # nocov
      }
    }
  }
  # Now check specific columns
  # start and end
  if (anyNA(x$start)) {
    rlang::abort(
      "Interval specification may not have NA for the starting time",
      class = "pknca_error_interval_na_start"
    )
  }
  if (anyNA(x$end)) {
    rlang::abort("Interval specification may not have NA for the end time", class = "pknca_error_interval_na_end")
  }
  if (any(is.infinite(x$start))) {
    rlang::abort("start may not be infinite", class = "pknca_error_interval_infinite_start")
  }
  if (any(x$start >= x$end)) {
    rlang::abort("start must be < end", class = "pknca_error_interval_start_gte_end")
  }
  # interval_id and the <parameter>_ref pointers that link a secondary parameter
  # to its reference interval
  x <- check_interval_secondary_cols(x)
  # Confirm that something is being calculated for each interval (and warn if not)
  mask_calculated <- rep(FALSE, nrow(x))
  for (n in setdiff(names(interval_cols), c("start", "end"))) {
    mask_calculated <-
      (mask_calculated |
       !(x[[n]] %in% c(NA, FALSE)))
  }
  if (any(!mask_calculated)) {
    rlang::warn(
      sprintf(
        "Nothing to be calculated in interval specification number(s): %s",
        paste(seq_len(nrow(x))[!mask_calculated], collapse = ", ")
      ),
      class = "pknca_warning_interval_nothing_calculated"
    )
  }
  # Put the columns in the right order and return the checked data frame
  x[,
    c(names(interval_cols), setdiff(names(x), names(interval_cols))),
    drop=FALSE
    ]
}

# How a linkage column's class reads in an error message
interval_id_class_text <- function(value) {
  if (is.factor(value)) {
    sprintf("a factor with levels %s", paste(levels(value), collapse = ", "))
  } else {
    class(value)[1]
  }
}

# The linkage columns hold identifiers of any comparable class -- character
# names, numbers (such as row indices), or factors -- so what is required is
# not one specific class but that the values can be compared to each other:
# `interval_id` and every pointer column share one class, and factors share one
# level set.  An all-NA logical column is what an intervals data.frame gets
# from an unfilled column and is compatible with anything.
check_interval_id_classes <- function(x, ref_cols) {
  cols <- intersect(c("interval_id", ref_cols), names(x))
  for (col in cols) {
    if (!is.atomic(x[[col]])) {
      rlang::abort(
        sprintf(
          "Interval column '%s' must be an atomic vector of interval identifiers; it is of class '%s'",
          col, class(x[[col]])[1]
        ),
        class = "pknca_error_secondary_interval_id_invalid"
      )
    }
  }
  is_wildcard <-
    vapply(
      X = x[cols],
      FUN = function(value) is.logical(value) && all(is.na(value)),
      FUN.VALUE = TRUE
    )
  compare_cols <- cols[!is_wildcard]
  if (length(compare_cols) > 1) {
    first_col <- compare_cols[1]
    for (col in compare_cols[-1]) {
      compatible <-
        if (is.factor(x[[first_col]]) || is.factor(x[[col]])) {
          is.factor(x[[first_col]]) && is.factor(x[[col]]) &&
            identical(levels(x[[first_col]]), levels(x[[col]]))
        } else if (is.numeric(x[[first_col]])) {
          is.numeric(x[[col]])
        } else {
          identical(class(x[[first_col]])[1], class(x[[col]])[1])
        }
      if (!compatible) {
        rlang::abort(
          sprintf(
            "Interval linkage columns must hold comparable identifiers: '%s' is %s and '%s' is %s",
            first_col, interval_id_class_text(x[[first_col]]),
            col, interval_id_class_text(x[[col]])
          ),
          class = "pknca_error_secondary_ref_class_mismatch"
        )
      }
    }
  }
  x
}

# Validate the cross-interval linkage columns of an interval specification:
# `interval_id` and the `<parameter>_ref` pointers naming it.  Called from
# check.interval.specification() after every registered parameter column exists.
# Returns the (possibly coerced) interval specification.
check_interval_secondary_cols <- function(x) {
  interval_cols <- get.interval.cols()
  candidate <- grep(pattern = "_ref$", x = names(x), value = TRUE)
  # A `<something>_ref` column whose prefix is not a parameter is the user's own
  # data and is left alone.
  ref_cols <-
    candidate[
      sub(pattern = "_ref$", replacement = "", x = candidate) %in% names(interval_cols)
    ]
  if (length(ref_cols) == 0 && !("interval_id" %in% names(x))) {
    return(x)
  }
  secondary_params <- secondary_parameter_names()
  for (col in ref_cols) {
    prefix <- sub(pattern = "_ref$", replacement = "", x = col)
    if (!(prefix %in% secondary_params)) {
      rlang::abort(
        sprintf(
          "Column '%s' is a reference pointer for '%s', which is not a secondary parameter",
          col, prefix
        ),
        class = "pknca_error_secondary_ref_not_secondary"
      )
    }
  }
  x <- check_interval_id_classes(x, ref_cols)
  if (length(ref_cols) > 0 && !("interval_id" %in% names(x))) {
    # Every non-NA pointer then fails the unknown-id check below, which is the
    # correct error: the intervals say what to reference but nothing carries
    # the id.  The created column takes the pointer columns' class (including
    # factor levels) so it stays comparable.
    x$interval_id <- x[[ref_cols[1]]][rep(NA_integer_, nrow(x))]
  }
  # An id names one logical interval, so rows sharing it may differ only in what
  # they calculate:  the parameter request columns and `impute`.
  request_cols <- setdiff(intersect(names(x), names(interval_cols)), c("start", "end"))
  compare_cols <- setdiff(names(x), c(request_cols, "impute"))
  for (current_id in unique(stats::na.omit(x$interval_id))) {
    rows <- which(x$interval_id %in% current_id)
    if (!all(duplicated(x[rows, compare_cols, drop = FALSE])[-1])) {
      rlang::abort(
        sprintf(
          "Rows sharing interval_id '%s' must describe the same interval; they differ outside the parameter and impute columns",
          current_id
        ),
        class = "pknca_error_secondary_id_conflict"
      )
    }
  }
  for (col in ref_cols) {
    prefix <- sub(pattern = "_ref$", replacement = "", x = col)
    unknown <- setdiff(stats::na.omit(x[[col]]), stats::na.omit(x$interval_id))
    if (length(unknown) > 0) {
      rlang::abort(
        sprintf(
          "Column '%s' references interval_id value(s) that no interval has: %s",
          col, paste(unique(unknown), collapse = ", ")
        ),
        class = "pknca_error_secondary_ref_unknown"
      )
    }
    mask_pointer <- !is.na(x[[col]])
    mask_requested <- vapply(X = x[[prefix]], FUN = isTRUE, FUN.VALUE = TRUE)
    if (any(mask_pointer & !mask_requested)) {
      rlang::abort(
        sprintf(
          "Column '%s' gives a reference interval in row(s) %s where '%s' is not requested. Request the parameter or clear the pointer.",
          col, paste(which(mask_pointer & !mask_requested), collapse = ", "), prefix
        ),
        class = "pknca_error_secondary_ref_without_request"
      )
    }
    mask_self <- mask_pointer & !is.na(x$interval_id) & (x$interval_id == x[[col]])
    if (any(mask_self)) {
      rlang::abort(
        sprintf(
          "Column '%s' in row(s) %s must reference a different interval than the row's own interval_id",
          col, paste(which(mask_self), collapse = ", ")
        ),
        class = "pknca_error_secondary_ref_self"
      )
    }
  }
  x
}

# Helper function to get.parameter.deps to determine the function map
get.parameter.deps_helper_funmap <- function(x, all_intervals) {
  if (is.na(x$FUN) &
      is.null(x$depends)) {
    # For columnns like "start" and "end"
    retfun <- NA
  } else if (is.na(x$FUN)) {
    if (length(x$depends) == 1) {
      # When the value is calculated by the same function as
      # another parameter.
      retfun <- all_intervals[[x$depends]]$FUN
    } else {
      # It would probably take malicious code to get here (an
      # example of malicious code could be altering the
      # intervals without using add.interval.col)
      rlang::abort("Invalid interval definition with no function and multiple dependencies.", class = "pknca_error_interval_invalid_def")  # nocov
    }
  } else {
    retfun <- x$FUN
  }
  # Define a function call by its function name and the
  # changes to the formal arguments made.
  append(list(retfun), x$formalsmap)
}
# Helper function to get.parameter.deps to find all parameters that are defined
# by the same function
get.parameter.deps_helper_samefun <- function(n, funmap) {
  mask.funmap <- rep(FALSE, length(funmap))
  for (current in n) {
    for (i in seq_len(length(funmap))) {
      mask.funmap[i] <-
        mask.funmap[i] |
        !any(
          is.na(funmap[[current]][[1]]),
          is.na(funmap[[i]][[1]])
        ) &
        identical(funmap[[current]], funmap[[i]])
    }
  }
  names(funmap)[mask.funmap]
}
# Helper function to get.parameter.deps to search all dependencies
get.parameter.deps_helper_searchdeps <- function(current, funmap, all_intervals) {
  # Find any parameters using the same function
  start <- get.parameter.deps_helper_samefun(current, funmap)
  # Find any parameters that depend on the current parameter
  ret <-
    vapply(
      X = all_intervals,
      FUN = function(x) {
        any(x$depends %in% start)
      },
      FUN.VALUE = TRUE
    )
  # Extract their names
  added <- setdiff(names(ret)[ret], start)
  if (length(added) > 0) {
    # Find any parameters that depend on any of those parameters
    unique(
      c(start, added,
        get.parameter.deps_helper_searchdeps(added, funmap, all_intervals))
    )
  } else {
    c(start, added)
  }
}

# The inputs a calculation can require, each mapped to the source-input names
# that show the requirement.  Every entry becomes a cached `requires_<name>`
# value on the registry entry, so a new input type is added here and nowhere
# else.
pknca_requires_inputs <-
  list(
    dose_amt = c("dose", "dose.group"),
    dose_time = c("time.dose", "time.dose.group"),
    dose_dur = c("duration.dose", "duration.dose.group"),
    volume = c("volume", "volume.group"),
    conc_dur = c("duration.conc", "duration.conc.group")
  )

# Fill in the requires_* values for `params` and cache them in the registry,
# computing only the ones that are not already known.  Deferred to first use
# because a parameter may be registered before what it depends on.
set_requires_inputs <- function(params) {
  all_intervals <- get.interval.cols()
  params <- intersect(params, names(all_intervals))
  requires_names <- paste0("requires_", names(pknca_requires_inputs))
  unknown <-
    params[vapply(
      X = params,
      FUN = function(x) !all(requires_names %in% names(all_intervals[[x]])),
      FUN.VALUE = TRUE
    )]
  if (length(unknown) > 0) {
    for (current_param in unknown) {
      current_src <-
        parameter_source_inputs(
          current_param, all_intervals = all_intervals, optional_dose = FALSE
        )
      for (current_input in names(pknca_requires_inputs)) {
        all_intervals[[current_param]][[paste0("requires_", current_input)]] <-
          any(pknca_requires_inputs[[current_input]] %in% current_src)
      }
    }
    assign("interval.cols", all_intervals, envir = .PKNCAEnv)
  }
  all_intervals[params]
}

# The parameters requested by at least one interval
requested_parameters <- function(intervals) {
  candidates <- intersect(names(intervals), names(get.interval.cols()))
  keep <-
    vapply(
      X = candidates,
      FUN = function(x) any(intervals[[x]] %in% TRUE),
      FUN.VALUE = TRUE
    )
  candidates[keep]
}

# Which requested parameters need any of `absent`, the inputs that were not
# given.  Names are those of `pknca_requires_inputs`.
uncalculable_without <- function(intervals, absent) {
  checkmate::assert_subset(absent, names(pknca_requires_inputs))
  params <- requested_parameters(intervals)
  if (length(params) == 0 || length(absent) == 0) {
    return(character(0))
  }
  specs <- set_requires_inputs(params)
  keep <-
    vapply(
      X = specs,
      FUN = function(x) any(unlist(x[paste0("requires_", absent)])),
      FUN.VALUE = TRUE
    )
  sort(names(specs)[keep])
}

# Dose inputs that were not given.  Amount, time, and duration are supplied
# independently (e.g. `PKNCAdose(data, ~time)` gives timing without an amount),
# so each is reported separately: c0 needs the dose time but not the amount,
# and ceoi needs the duration.
absent_dose_inputs <- function(o_dose) {
  has_dose <- !identical(o_dose, NA)
  present <-
    c(
      dose_amt = has_dose && length(o_dose$columns$dose) > 0,
      dose_time = has_dose && length(o_dose$columns$time) > 0,
      dose_dur = has_dose && length(o_dose$columns$duration) > 0
    )
  names(present)[!present]
}

# Concentration inputs a calculation can require, each mapped to the
# `PKNCAconc()` argument (and attribute column name) that supplies it.
pknca_conc_input_args <- c(volume = "volume", conc_dur = "duration")

# Concentration inputs that were not given.  An all-NA column is treated the
# same as a column that was never set, since neither can be calculated from.
# Values missing for only some measurements are reported per-interval by the
# calculations themselves.
absent_conc_inputs <- function(o_conc) {
  present <-
    vapply(
      X = pknca_conc_input_args,
      FUN = function(x) {
        current <- getAttributeColumn(o_conc, attr_name = x, warn_missing = character())
        !is.null(current) && !all(is.na(current[[1]]))
      },
      FUN.VALUE = TRUE
    )
  names(present)[!present]
}

# The inputs pk.nca.interval() supplies directly rather than calculating, so a
# backward dependency search ends when it reaches one of these.
pknca_source_inputs <- c(
  "conc", "time", "volume", "duration.conc", "dose", "time.dose", "duration.dose",
  "route", "subject", "options", "lloq", "interval", "start", "end",
  paste0(
    c("conc", "time", "volume", "duration.conc", "dose", "time.dose", "duration.dose", "route"),
    ".group"
  ),
  # The pooled individual samples for sparse PK
  "conc.sparse", "time.sparse", "conc.sparse.group", "time.sparse.group"
)

# Dose inputs a calculation accepts but does not require.  pk.calc.half.life()
# refines its point selection with the dose timing when it is available and
# returns the same answer without it, so treating it as required would report
# the whole terminal-phase family as uncalculable whenever dosing is absent.
pknca_optional_dose_args <- list(
  pk.calc.half.life = c("time.dose", "duration.dose")
)

# What a single parameter is calculated from: its function's formals after the
# formalsmap is applied, plus the parameters it declares a dependency on.  A
# parameter with `FUN = NA` is produced by another parameter's function, so the
# chain continues through `depends`.
parameter_direct_refs <- function(x, all_intervals, optional_dose) {
  spec <- all_intervals[[x]]
  if (is.null(spec)) {
    return(character(0))
  }
  if (length(spec$FUN) != 1 || is.na(spec$FUN)) {
    return(unique(spec$depends))
  }
  fun <- tryCatch(get(spec$FUN), error = function(e) NULL)
  if (is.null(fun)) {
    return(unique(spec$depends))  # nocov
  }
  arg_names <- setdiff(names(formals(fun)), "...")
  args <- stats::setNames(as.list(arg_names), arg_names)
  if (length(spec$formalsmap) > 0) {
    args[names(spec$formalsmap)] <- spec$formalsmap
  }
  args <- args[!vapply(X = args, FUN = is.null, FUN.VALUE = TRUE)]
  # I()-wrapped formalsmap values are constants, not references to a data source
  # or another parameter.
  args <- args[!vapply(X = args, FUN = inherits, FUN.VALUE = TRUE, what = "AsIs")]
  # A pknca_ref() value names a parameter like a plain reference does; the
  # interval it comes from does not change what the calculation is made of.
  args <- lapply(X = args, FUN = function(a) if (is_pknca_ref(a)) a$param else a)
  if (!optional_dose) {
    drop_args <- pknca_optional_dose_args[[spec$FUN]]
    if (!is.null(drop_args)) {
      args <- args[!(names(args) %in% drop_args)]
    }
  }
  unique(c(unlist(args, use.names = FALSE), spec$depends))
}

# Everything `x` is calculated from, following each reference to a source input.
parameter_source_inputs <- function(x, all_intervals = get.interval.cols(),
                                    optional_dose = TRUE, seen = character(0)) {
  if (x %in% seen) {
    return(character(0))
  }
  seen <- c(seen, x)
  ret <- character(0)
  for (current_ref in parameter_direct_refs(x, all_intervals, optional_dose)) {
    if (current_ref %in% names(all_intervals)) {
      ret <-
        c(
          ret,
          parameter_source_inputs(
            current_ref, all_intervals = all_intervals,
            optional_dose = optional_dose, seen = seen
          )
        )
    } else {
      ret <- c(ret, current_ref)
    }
  }
  unique(ret)
}

#' Get all columns that depend on a parameter
#'
#' @param x The parameter name (as a character string)
#' @param recursive Search backward to the inputs `x` is calculated from,
#'   rather than forward to the parameters calculated from `x`.  See the
#'   details.
#' @returns With `recursive = FALSE` (default), a character vector of
#'   parameter names that depend on the parameter `x`; empty if none do.
#'   With `recursive = TRUE`, the unique set of everything `x` is calculated
#'   from, following each dependency to the end.
#' @details The two directions answer different questions.  The default
#'   answers "what becomes invalid if `x` changes?".  `recursive = TRUE`
#'   answers "what does `x` need?", and its result mixes parameter names
#'   with the raw inputs the calculation ends at, such as `"conc"`,
#'   `"time"`, `"dose"`, and `"time.dose"`.
#' @family Interval specifications
#' @export
get.parameter.deps <- function(x, recursive = FALSE) {
  checkmate::assert_flag(recursive)
  all_intervals <- get.interval.cols()
  if (!(x %in% names(all_intervals))) {
    rlang::abort(
      "`x` must be the name of an NCA parameter listed by the function `get.interval.cols()`",
      class = "pknca_error_invalid_parameter"
    )
  }
  if (recursive) {
    return(sort(parameter_source_inputs(x, all_intervals = all_intervals, optional_dose = TRUE)))
  }
  funmap <-
    lapply(
      X=all_intervals,
      FUN=get.parameter.deps_helper_funmap,
      all_intervals=all_intervals
    )
  sort(get.parameter.deps_helper_searchdeps(x, funmap, all_intervals))
}
