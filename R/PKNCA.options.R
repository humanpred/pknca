# Options for use within the code for setting and getting PKNCA default options. ####

.PKNCA.option.check <- list(
  adj.r.squared.factor=function(x, default=FALSE, description=FALSE) {
    if (description)
      return(paste(
        "The adjusted r^2 for the calculation of lambda.z has this factor",
        "times the number of data points added to it.  It allows for more",
        "data points to be preferred in the calculation of half-life."))
    if (default)
      return(0.0001)
    
    checkmate::assert_number(x, .var.name = "adj.r.squared.factor")
    # Must be between 0 and 1, exclusive
    if (x <= 0 || x >= 1) {
      rlang::abort(
        message = "adj.r.squared.factor must be between 0 and 1, exclusive",
        class = "pknca_error_adj.r.squared.factor_out_of_bounds"
      )
    }
    
    if (x > 0.01){
      rlang::warn(
        message = "adj.r.squared.factor is usually <0.01",
        class = "pknca_warning_adj_r2_factor_large"
      )
    }
    x
  },
  max.missing=function(x, default=FALSE, description=FALSE) {
    if (description)
      return(paste(
        "The maximum fraction of the data that may be missing ('NA') to",
        "calculate summary statistics with the business.* functions."))
    if (default)
      return(0.5)
    
    checkmate::assert_number(x, .var.name = "max.missing")
    # Must be between 0 and 1, inclusive
    if (x < 0 || x >= 1) {
      rlang::abort(
        message = "max.missing must be between 0 and 1",
        class = "pknca_error_max.missing_out_of_bounds"
      )
    }
    #checkmate::assert_number(x, lower = 0, upper = 1, .var.name = "max.missing")
    if (x > 0.5) {
      rlang::warn(
        message = "max.missing is usually <= 0.5",
        class = "pknca_warning_max_missing_large"
      )
    }
    x
  },
  auc.method=function(x, default=FALSE, description=FALSE) {
    choices <- eval(formals(assert_aucmethod)$method)
    if (description)
      return(paste(
        "The method used to calculate the AUC and related statistics.",
        "Options are:",
        paste0('"', choices, '"', collapse = ", ")
      ))
    if (default)
      return(choices[1])
    assert_aucmethod(x)
  },
  conc.na=function(x, default=FALSE, description=FALSE) {
    if (description)
      return(paste(
        "How should missing ('NA') concentration values be handled?  See",
        "help for 'clean.conc.na' for how to use this option."))
    if (default)
      return("drop")
    if (is.na(x)) {
      rlang::abort(
        message = "conc.na must not be NA",
        class = "pknca_error_conc_na_is_na"
      )
    }
    if (is.factor(x)) {
      rlang::warn(
        message = "conc.na may not be a factor; attempting conversion",
        class = "pknca_warning_conc_na_factor"
      )
      x <- as.character(x)
    }
    if (tolower(x) %in% "drop") {
      x <- tolower(x)
    } else if (is.numeric(x)) {
      if (is.infinite(x)) {
        rlang::abort(
          message = "When a number, conc.na must be finite",
          class = "pknca_error_conc_na_infinite"
        )
      } else if (x < 0) {
        rlang::warn(
          message = "conc.na is usually not < 0",
          class = "pknca_warning_conc_na_negative"
        )
      }
    } else {
      rlang::abort(
        message = "conc.na must either be a finite number or the text 'drop'",
        class = "pknca_error_conc_na_invalid"
      )
    }
    x
  },
  conc.blq=function(x, default=FALSE, description=FALSE) {
    if (description)
      return(paste(
        "How should below the limit of quantification (zero, 0) concentration",
        "values be handled?  See help for 'clean.conc.blq' for how to use",
        "this option."))
    if (default)
      return(list(first="keep",
                  middle="drop",
                  last="keep"))
    check.element <- function(x) {
      checkmate::assert_scalar(x, na.ok = FALSE)
      if (is.factor(x)) {
        rlang::warn(
          message = "conc.blq may not be a factor; attempting conversion",
          class = "pknca_warning_conc_blq_factor"
        )
        x <- as.character(x)
      }
      if (tolower(x) %in% c("drop", "keep")) {
        x <- tolower(x)
      } else if (is.numeric(x)) {
        if (is.infinite(x)) {
          rlang::abort(
            message = "When a number, conc.blq must be finite",
            class = "pknca_error_conc_blq_infinite"
          )
        } else if (x < 0) {
          rlang::warn(
            message = "conc.blq is usually not < 0",
            class = "pknca_warning_conc_blq_negative"
          )
        }
      } else {
        rlang::abort(
          message = "conc.blq must either be a finite number or the text 'drop' or 'keep'",
          class = "pknca_error_conc_blq_invalid"
        )
      }
      x
    }
    if (is.list(x)) {
      tfirst_names <- c("first", "last", "middle")
      tmax_names <- c("before.tmax", "after.tmax")

      are.names.mixed <- any(names(x) %in% tfirst_names) & any(names(x) %in% tmax_names)
      extra.names <- setdiff(names(x), c(tfirst_names, tmax_names))
      missing.names <- if (any(names(x) %in% tfirst_names)) setdiff(tfirst_names, names(x)) else setdiff(tmax_names, names(x))
      duplicated.names <- names(x)[duplicated(names(x))]
      if (are.names.mixed){
        rlang::abort(
          message = "When given as a list, prevent mixing arguments of different BLQ strategies.\n Either define 'first', 'middle' and 'last' or 'before.tmax' and 'after.tmax'.",
          class = "pknca_error_conc_blq_mixed_names"
        )
      }
      if (length(extra.names) != 0)
        rlang::abort(
          message = "When given as a list, conc.blq must only have elements named 'first', 'middle' and 'last' or 'before.tmax' and 'after.tmax'.",
          class = "pknca_error_conc_blq_extra_names"
        )
      if (length(missing.names) != 0)
        rlang::abort(
          message = "When given as a list, conc.blq must include all elements named 'first', 'middle' and 'last' or 'before.tmax' and 'after.tmax'.",
          class = "pknca_error_conc_blq_missing_names"
        )
      if (length(duplicated.names) != 0)
        rlang::abort(
          message = "When given as a list, conc.blq should not have duplicated names",
          class = "pknca_error_conc_blq_duplicated_names"
        )
      # After the names are confirmed, confirm each value.
      x <- lapply(x, check.element)
    } else {
      x <- check.element(x)
    }
    x
  },
  debug = function(x, default = FALSE, description = FALSE) {
    if (description) {
      return("Enable PKNCA debugging mode (not for production use)")
    }
    if (default) {
      return(NULL)
    }
    x
  },
  first.tmax=function(x, default=FALSE, description=FALSE) {
    if (description)
      return(paste(
        "If there is more than one time point with the maximum value (Cmax or ERmax),",
        "which time should be selected for Tmax/ERTmax?  If 'TRUE', the first will be selected.",
        "If 'FALSE', the last will be selected."
      ))
    if (default)
      return(TRUE)
    
    checkmate::assert_scalar(x, na.ok = FALSE, .var.name = "first.tmax")
    
    if (!is.logical(x)) {
      x <- as.logical(x)
      if (is.na(x)) {
        rlang::abort(
          message = "Could not convert first.tmax to a logical value",
          class = "pknca_error_first_tmax_not_logical"
        )
      } else {
        rlang::warn(
          message = paste("Converting first.tmax to a logical value:", x),
          class = "pknca_warning_first_tmax_converted"
        )
      }
    }
    x
  },
  first.tmin=function(x, default=FALSE, description=FALSE) {
    if (description)
      return(paste(
        "If there is more than one time point with the minimum value (Cmin),",
        "which time should be selected for Tmin?  If 'TRUE', the first will be selected.",
        "If 'FALSE', the last will be selected."
      ))
    if (default)
      return(TRUE)
    checkmate::assert_scalar(x, na.ok = FALSE, .var.name = "first.tmin")
    if (!is.logical(x)) {
      x <- as.logical(x)
      if (is.na(x)) {
        rlang::abort(
          message = "Could not convert first.tmin to a logical value",
          class = "pknca_error_first_tmin_not_logical"
        )
      } else {
        rlang::warn(
          message = paste("Converting first.tmin to a logical value:", x),
          class = "pknca_warning_first_tmin_converted"
        )
      }
    }
    x
  },
  allow.tmax.in.half.life=function(x, default=FALSE, description=FALSE) {
    if (description)
      return(paste(
        "Should the concentration and time at Tmax be allowed in the",
        "half-life calculation?  'TRUE' is yes and 'FALSE' is no."))
    if (default)
      return(FALSE)
    checkmate::assert_scalar(x, na.ok = FALSE, .var.name = "allow.tmax.in.half.life")
    if (!is.logical(x)) {
      x <- as.logical(x)
      if (is.na(x)) {
        rlang::abort(
          message = "Could not convert allow.tmax.in.half.life to a logical value",
          class = "pknca_error_allow_tmax_hl_not_logical"
        )
      } else {
        rlang::warn(
          message = paste("Converting allow.tmax.in.half.life to a logical value:", x),
          class = "pknca_warning_allow_tmax_hl_converted"
        )
      }
    }
    x
  },

  keep_interval_cols = function(x, default = FALSE, description = FALSE) {
    if (description)
      return("What additional columns from the intervals should be kept in the results?")
    if (default)
      return(NULL)
    checkmate::assert_names(x)
    x
  },

  min.hl.points=function(x, default=FALSE, description=FALSE) {
    if (description)
      return("What is the minimum number of points required to calculate half-life?")
    if (default)
      return(3)
    checkmate::assert_number(x, lower = 2, na.ok = FALSE, .var.name = "min.hl.points")

    if (min(x %% 1, 1 - (x %% 1)) >
        100*.Machine$double.eps) {
      rlang::warn(
        message = "Non-integer given for min.hl.points; rounding to nearest integer",
        class = "pknca_warning_min_hl_points_noninteger"
      )
      x <- round(x)
    }
    x
  },
  min.span.ratio=function(x, default=FALSE, description=FALSE) {
    if (description)
      return("What is the minimum span ratio required to consider a half-life valid?")
    if (default)
      return(2)
    checkmate::assert_number(x, na.ok = FALSE, .var.name = "min.span.ratio")
    if (x <= 0)
      rlang::abort(
        message = "min.span.ratio must be > 0",
        class = "pknca_error_min_span_ratio_range"
      )
    if (x < 2)
      rlang::warn(
        message = "min.span.ratio is usually >= 2",
        class = "pknca_warning_min_span_ratio_small"
      )
    x
  },
  max.aucinf.pext=function(x, default=FALSE, description=FALSE) {
    if (description)
      return("What is the maximum percent extrapolation to consider an AUCinf valid?")
    if (default)
      return(20)
    checkmate::assert_number(x, na.ok = FALSE, .var.name = "max.aucinf.pext")
    if (x <= 0) {
      rlang::abort(
        message = "max.aucinf.pext must be > 0",
        class = "pknca_error_max_aucinf_pext_range"
      )
    }
    if (x > 25) {
      rlang::warn(
        message = "max.aucinf.pext is usually <=25",
        class = "pknca_warning_max_aucinf_pext_large"
      )
    }
    if (x < 1) {
      rlang::warn(
        message = "max.aucinf.pext is on the percent not ratio scale, value given is <1%",
        class = "pknca_warning_max_aucinf_pext_small"
      )
    }
    x
  },
  min.hl.r.squared=function(x, default=FALSE, description=FALSE) {
    if (description)
      return("What is the minimum r-squared value to consider a half-life calculation valid?")
    if (default)
      return(0.9)
    
    checkmate::assert_number(x, .var.name = "min.hl.r.squared")
    if (x <= 0 || x >= 1) {
      rlang::abort(
        message = "min.hl.r.squared must be between 0 and 1, exclusive",
        class = "pknca_error_min_hl_r2_out_of_bounds"
      )
    }
    
    if (x < 0.9){
      rlang::warn(
        message = "min.hl.r.squared is usually >= 0.9",
        class = "pknca_warning_min_hl_r2_small"
      )
    }
    x
  },

  progress = function(x, default = FALSE, description = FALSE) {
    if (description)
      return("A value to pass to purrr::pmap(.progress = ) to create a progress bar while running")
    if (default) {
      return(TRUE)
    }
    x
  },

  tau.choices=function(x, default=FALSE, description=FALSE) {
    if (description)
      return(paste(
        "What values for tau (repeating interdose interval) should be",
        "considered when attempting to automatically determine the intervals",
        "for multiple dosing?  See 'choose.auc.intervals' and 'find.tau' for",
        "more information.  'NA' means automatically look at any potential",
        "interval."))
    if (default)
      return(NA)
    
    # NA mixed into a numeric vector is not allowed
    if (length(x) > 1 && anyNA(x)){
      rlang::abort(
        message = "tau.choices may not include NA and be a vector",
        class = "pknca_error_tau_choices_na_in_vector"
      )
    }
    
    # Only validate non-NA cases
    if (!identical(x, NA)) {
      checkmate::assert_numeric(x, .var.name = "tau.choices")
      
      if (!is.vector(x)) {
        rlang::warn(
          message = "tau.choices must be a vector, converting",
          class = "pknca_warning_tau_choices_not_vector"
        )
        x <- as.vector(x)
      }
    }
    x
  },
  single.dose.aucs=function(x, default=FALSE, description=FALSE) {
    if (description)
      return("When data is single-dose, what intervals should be used?")
    if (default) {
      # It is good to put this through the specification checker in case they
      # get out of sync during development.  (A free test case!)
      x <- data.frame(
        start=0,
        end=c(24, Inf),
        auclast=c(TRUE, FALSE),
        aucinf.obs=c(FALSE, TRUE),
        half.life=c(FALSE, TRUE),
        tmax=c(FALSE, TRUE),
        cmax=c(FALSE, TRUE))
    }
    check.interval.specification(x)
  },
  allow_partial_missing_units = function(x, default = FALSE, description = FALSE) {
    if (description)
      return("When using unit assignment and conversions, should some units be allowed to be missing?")
    if (default) {
      return(FALSE)
    }
    checkmate::assert_logical(x, any.missing = FALSE, len = 1)
    x
  },

  hl_method = function(x, default = FALSE, description = FALSE) {
    choices <- c("log-linear", "tobit")
    if (description)
      return(paste(
        "The method used to calculate the half-life and related parameters.",
        "Options are:",
        paste0('"', choices, '"', collapse = ", ")
      ))
    if (default)
      return(choices[1])
    checkmate::assert_string(x, .var.name = "hl_method")
    x <- match.arg(x, choices)
    x
  },

  tobit_n_points_penalty = function(x, default = FALSE, description = FALSE) {
    if (description)
      return(paste(
        "The penalty exponent applied to the number of points when selecting the best",
        "Tobit regression half-life fit.  The selection criterion is",
        "tobit_residual * n_points ^ tobit_n_points_penalty, and the window",
        "minimizing this criterion is selected.  A value of 0 (the default)",
        "uses the raw Tobit residual with no point-count penalty."))
    if (default)
      return(0)
    checkmate::assert_number(x, lower = 0, na.ok = FALSE, .var.name = "tobit_n_points_penalty"
    )
    x
  },

  tobit_optim_control = function(x, default = FALSE, description = FALSE) {
    if (description)
      return(paste(
        "A list of control parameters passed to stats::optim() when fitting the",
        "Tobit regression half-life.  See ?stats::optim for available options."))
    if (default)
      return(list())
    checkmate::assert_list(x, .var.name = "tobit_optim_control")
    x
  }
)

# Functions controlling and modifying options ####

#' Set default options for PKNCA functions
#'
#' This function will set the default PKNCA options.  If given no inputs, it
#' will provide the current option set.  If given name/value pairs, it will set
#' the option (as in the [options()] function).  If given a name, it will return
#' the value for the parameter.  If given the `default` option as true, it will
#' provide the default options.
#'
#' Options are either for calculation or summary functions. Calculation options
#' are required for a calculation function to report a result (otherwise the
#' reported value will be `NA`). Summary options are used during summarization
#' and are used for assessing what values are included in the summary.
#'
#' See the vignette 'Options for Controlling PKNCA' for a current list of
#' options (`vignette("Options-for-Controlling-PKNCA", package="PKNCA")`).
#'
#' @param \dots options to set or get the value for
#' @param default (re)sets all default options
#' @param check check a single option given, but do not set it (for validation
#'   of the values when used in another function)
#' @param name An option name to use with the `value`.
#' @param value An option value (paired with the `name`) to set or check (if
#'   `NULL`, the current value of the option is returned).
#' @returns If...
#' \describe{
#'   \item{no arguments are given}{returns the current options.}
#'   \item{a value is set (including the defaults)}{returns `NULL`}
#'   \item{a single value is requested}{the current value of that option is returned as a scalar}
#'   \item{multiple values are requested}{the current values of those options are returned as a list}
#' }
#' @family PKNCA calculation and summary settings
#' @seealso [PKNCA.options.describe()]
#' @examples
#'
#' PKNCA.options()
#' PKNCA.options(default=TRUE)
#' PKNCA.options("auc.method")
#' PKNCA.options(name="auc.method")
#' PKNCA.options(auc.method="lin up/log down", min.hl.points=3)
#' @export
PKNCA.options <- function(..., default=FALSE, check=FALSE, name, value) {
  current <- get("options", envir=.PKNCAEnv)
  # If the options have not been initialized, initialize them and then proceed.
  if (is.null(current) && !default) {
    PKNCA.options(default=TRUE)
    current <- get("options", envir=.PKNCAEnv)
  }
  args <- list(...)
  # Put the name/value pair into the args as if they were specified
  # like another argument.
  if (missing(name)) {
    if (!missing(value))
      rlang::abort(
        message = "Cannot have a value without a name",
        class = "pknca_error_value_without_name"
      )
  } else {
    if (name %in% names(args))
      rlang::abort(
        message = "Cannot give an option name both with the name argument and as a named argument.",
        class = "pknca_error_duplicate_option_name"
      )
    if (!missing(value)) {
      args[[name]] <- value
    } else {
      args <- append(args, name)
    }
  }
  if (default && check)
    rlang::abort(
      message = "Cannot request both default and check",
      class = "pknca_error_default_and_check"
    )
  if (default) {
    if (length(args) > 0)
      rlang::abort(
        message = "Cannot set default and set new options at the same time.",
        class = "pknca_error_default_with_options"
      )
    # Extract all the default values
    defaults <- lapply(.PKNCA.option.check,
                       FUN=function(x) x(default=TRUE))
    # Set the default options
    assign("options", defaults, envir=.PKNCAEnv)
  } else if (check) {
    # Check an option for accuracy, but don't set it
    if (length(args) != 1) {
      rlang::abort(
        message = "Must give exactly one option to check",
        class = "pknca_error_check_not_scalar"
      )
    }
    n <- names(args)
    if (!(n %in% names(.PKNCA.option.check))){
      rlang::abort(
        message = paste("Invalid setting for PKNCA:", n),
        class = "pknca_error_invalid_option"
      )
    }
    # Verify the option, and return the sanitized version
    return(.PKNCA.option.check[[n]](args[[n]]))
  } else if (length(args) > 0) {
    if (is.null(names(args))) {
      # Confirm that the settings exist
      bad.args <- setdiff(unlist(args), names(current))
      if (length(bad.args) > 0){
        rlang::abort(
          message = sprintf(
            "PKNCA.options does not have value(s) for %s.",
            paste(bad.args, collapse = ", ")
          ),
          class = "pknca_error_unknown_options"
        )
      }
      # Get the setting(s)
      if (length(args) == 1) {
        ret <- current[[args[[1]]]]
      } else {
        ret <- list()
        for (i in seq_len(length(args))) {
          ret[[ args[[i]] ]] <- current[[ args[[i]] ]]
        }
      }
      return(ret)
    } else {
      # Set a value
      # Verify values are viable and then set them.
      for (n in names(args)) {
        if (!(n %in% names(.PKNCA.option.check))){
          rlang::abort(
            message = paste("Invalid setting for PKNCA:", n),
            class = "pknca_error_invalid_option"
          )
        }
        # Verify and set the option value
        current[[n]] <- .PKNCA.option.check[[n]](args[[n]])
      }
      # Assign current into the setting environment
      assign("options", current, envir=.PKNCAEnv)
    }
  } else {
    return(current)
  }
}

#' Choose either the value from an option list or the current set value for an
#' option.
#'
#' @param name The option name requested.
#' @param value A value to check for the option (`NULL` to choose not to check
#'   the value).
#' @param options List of changes to the default PKNCA options (see
#'   `PKNCA.options()`)
#' @returns The value of the option first from the `options` list and if it is
#'   not there then from the current settings.
#' @family PKNCA calculation and summary settings
#' @export
PKNCA.choose.option <- function(name, value=NULL, options=list()) {
  if (!is.null(value)) {
    PKNCA.options(name=name, value=value, check=TRUE)
  } else if (name %in% names(options)) {
    PKNCA.options(name=name, value=options[[name]], check=TRUE)
  } else {
    PKNCA.options(name)
  }
}

#' Describe a PKNCA.options option by name.
#'
#' @param name The option name requested.
#' @return A character string of the description.
#' @seealso [PKNCA.options()]
#' @export
PKNCA.options.describe <- function(name) {
  .PKNCA.option.check[[name]](description=TRUE)
}

#' Define how NCA parameters are summarized.
#'
#' @param name The parameter name or a vector of parameter names.  It must have
#'   already been defined (see [add.interval.col()]).
#' @param description A single-line description of the summary
#' @param point The function to calculate the point estimate for the summary.
#'   The function will be called as `point(x)` and must return a scalar value
#'   (typically a number, NA, or a string).
#' @param spread Optional.  The function to calculate the spread (or
#'   variability).  The function will be called as `spread(x)` and must return a
#'   scalar or two-long vector (typically a number, NA, or a string).
#' @param rounding Instructions for how to round the value of point and spread.
#'   It may either be a list or a function.  If it is a list, then it must have
#'   a single entry with a name of either "signif" or "round" and a value of the
#'   digits to round.  If a function, it is expected to return a scalar number
#'   or character string with the correct results for an input of either a
#'   scalar or a two-long vector.
#' @param reset Reset all the summary instructions to no instruction (this is
#'   not intended for general use)
#' @returns All current summary settings (invisibly)
#' @seealso [summary.PKNCAresults()]
#' @family PKNCA calculation and summary settings
#' @examples
#' \dontrun{
#' PKNCA.set.summary(
#'   name="half.life",
#'   description="arithmetic mean and standard deviation",
#'   point=business.mean,
#'   spread=business.sd,
#'   rounding=list(signif=3)
#' )
#' }
#' @export
PKNCA.set.summary <- function(name, description, point, spread,
                              rounding=list(signif=3), reset=FALSE) {
  if (reset) {
    rlang::warn(
      message = "`reset = TRUE` is not intended for general use, summary() may not work after resetting summary instructions",
      class = "pknca_warning_summary_reset"
    )
    current <- list()
  } else {
    current <- get("summary", envir=.PKNCAEnv)
  }
  if (missing(name) && missing(point) && missing(spread)) {
    if (reset)
      assign("summary", current, envir=.PKNCAEnv)
    return(invisible(current))
  }
  # Confirm that the name exists
  if (!all(found_names <- name %in% names(get("interval.cols", envir=.PKNCAEnv)))) {
    rlang::abort(
      message = paste(
        "You must first define the parameter name with add.interval.col.  Parameters not yet defined are:",
        paste(name[!found_names], collapse = ", ")
      ),
      class = "pknca_error_undefined_parameter"
    )
  }
  # Reset all names to prep for settings below
  for (current_name in name) {
    current[[current_name]] <- list()
  }
  # Confirm that description is a scalar character string
  checkmate::assert_string(description, .var.name = "description")
  for (current_name in name) {
    current[[current_name]]$description <- description
  }
  # Confirm that point is a function
  checkmate::assert_function(point, .var.name = "point")
  for (current_name in name) {
    current[[current_name]]$point <- point
  }
  # Confirm that spread is a function (if given)
  if (!missing(spread)) {
    checkmate::assert_function(spread, .var.name = "spread")
    for (current_name in name) {
      current[[current_name]]$spread <- spread
    }
  }
  # Confirm that rounding is either a single-entry list or a function
  if (is.list(rounding)) {
    checkmate::assert_list(rounding, len = 1, .var.name = "rounding")

    if (!(names(rounding) %in% c("signif", "round"))) {
      rlang::abort(
        message = "When a list, rounding must have a name of either 'signif' or 'round'",
        class = "pknca_error_rounding_list_name"
      )
    }
    for (current_name in name) {
      current[[current_name]]$rounding <- rounding
    }
  } else if (is.function(rounding)) {
    for (current_name in name) {
      current[[current_name]]$rounding <- rounding
    }
  } else {
    rlang::abort(
      message = "rounding must be either a list or a function",
      class = "pknca_error_rounding_invalid"
    )
  }
  # Set the summary parameters
  assign("summary", current, envir=.PKNCAEnv)
  invisible(current)
}

