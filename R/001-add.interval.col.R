# Setup the default options
.PKNCAEnv <- new.env(parent=emptyenv())
assign("options", NULL, envir=.PKNCAEnv)
assign("summary", list(), envir=.PKNCAEnv)
assign("interval.cols", list(), envir=.PKNCAEnv)

# Validate a CDISC pptestcd/pptest argument: must be a character string, or a
# named list with a "route" element containing a named list of
# route-specific values (e.g. list(route = list(extravascular = ...))).
# Not exported -- internal helper shared by add.interval.col().
#' @param x The CDISC argument value to validate.
#' @param arg_name The argument name used in error messages.
#'
#' @keywords internal
#' @noRd
validate_cdisc_arg <- function(x, arg_name) {
  if (is.character(x)) {
    if (!checkmate::test_string(x, na.ok = FALSE)) {
      rlang::abort(
        sprintf(
          "`%s`, when a character string, must be length 1 and non-missing",
          arg_name
        ),
        class = "pknca_error_cdisc_character_invalid"
      )
    }
  } else if (is.list(x)) {
    # `identical(names(x), "route")` also confirms that x has length 1
    if (!identical(names(x), "route") ||
        !is.list(x$route) ||
        !checkmate::test_names(names(x$route), type = "named")) {
      rlang::abort(
        sprintf(
          "`%s`, when a list, must have exactly one named element, \"route\", whose value is itself a named list mapping route to value.",
          arg_name
        ),
        class = "pknca_error_cdisc_route_mapping_invalid"
      )
    }
  } else {
    rlang::abort(
      sprintf(
        "`%s` must be a character string or a list",
        arg_name
      ),
      class = "pknca_error_cdisc_invalid_type"
    )
  }
}

#' Add columns for calculations within PKNCA intervals
#'
#' @param name The column name as a non-empty character string (length 1,
#'   may not be `NA` or `""`).
#' @param FUN The function to run (as a character string) or `NA` if the
#'   parameter is automatically calculated when calculating another parameter.
#' @param values Valid values for the column: either a function used to
#'   coerce/validate values (e.g. `as.numeric`) or a vector of allowed values
#'   (e.g. `c(FALSE, TRUE)`).
#' @param unit_type The type of units to use for assigning and converting
#'   units. Must be one of the pre-defined unit types (see Details). This
#'   argument is required and has no default; omitting it raises an error.
#' @param pretty_name The name of the parameter to use for printing in summary
#'   tables with units.  (If an analysis does not include units, then the normal
#'   name is used.)
#' @param depends Character vector of columns that must be run before this
#'   column.
#' @param desc A human-readable description of the parameter (<=40 characters to
#'   comply with SDTM)
#' @param sparse Is the calculation for sparse PK?
#' @param formalsmap A named list mapping parameter names in the function call
#'   to NCA parameter names.  See the details for information on use of
#'   `formalsmap`.
#' @param datatype The data type used for the calculation. The default is
#'   `"interval"`, which is currently the only supported value. The
#'   `"individual"` and `"population"` data types are reserved for future
#'   use and will currently raise an error if selected.
#' @param pptestcd_cdisc The CDISC PPTESTCD code for this parameter.  Can be a
#'   character string for simple mappings, or a named list for route-dependent
#'   mappings with a `route` element whose value is itself a named list keyed
#'   by route (e.g. `list(route = list(extravascular = "CLF/FO", intravascular
#'   = "CLO"))`).  Defaults to `name` if not provided.
#' @param pptest_cdisc The CDISC PPTEST name for this parameter.  Can be a
#'   character string or a named list (same structure as `pptestcd_cdisc`).
#'   Defaults to `desc` if not provided.
#' @returns NULL (Calling this function has a side effect of changing the
#'   available intervals for calculations)
#'
#' @details The `formalsmap` argument enables mapping some alternate formal
#' argument names to parameters.  It is used to generalize functions that may
#' use multiple similar arguments (such as the variants of mean residence time).
#' The names of the list should correspond to function formal parameter names
#' and the values should be one of the following:
#'
#' \itemize{
#'   \item{For the current interval:}
#'   \describe{
#'     \item{character strings of NCA parameter name}{The value of the parameter calculated for the current interval.}
#'     \item{"conc"}{Concentration measurements for the current interval.}
#'     \item{"time"}{Times associated with concentration measurements for the current interval (values start at 0 at the beginning of the current interval).}
#'     \item{"volume"}{Volume associated with concentration measurements for the current interval (typically applies for excretion parameters like urine).}
#'     \item{"duration.conc"}{Durations associated with concentration measurements for the current interval.}
#'     \item{"dose"}{Dose amounts assocuated with the current interval.}
#'     \item{"time.dose"}{Time of dose start associated with the current interval (values start at 0 at the beginning of the current interval).}
#'     \item{"duration.dose"}{Duration of dose (typically infusion duration) for doses in the current interval.}
#'     \item{"route"}{Route of dosing for the current interval.}
#'     \item{"start"}{Time of interval start.}
#'     \item{"end"}{Time of interval end.}
#'     \item{"options"}{PKNCA.options governing calculations.}
#'   }
#'   \item{For the current group:}
#'   \describe{
#'     \item{"conc.group"}{Concentration measurements for the current group.}
#'     \item{"time.group"}{Times associated with concentration measurements for the current group (values start at 0 at the beginning of the current interval).}
#'     \item{"volume.group"}{Volume associated with concentration measurements for the current interval (typically applies for excretion parameters like urine).}
#'     \item{"duration.conc.group"}{Durations assocuated with concentration measurements for the current group.}
#'     \item{"dose.group"}{Dose amounts assocuated with the current group.}
#'     \item{"time.dose.group"}{Time of dose start associated with the current group (values start at 0 at the beginning of the current interval).}
#'     \item{"duration.dose.group"}{Duration of dose (typically infusion duration) for doses in the current group.}
#'     \item{"route.group"}{Route of dosing for the current group.}
#'   }
#' }
#' @examples
#' \dontrun{
#' add.interval.col("cmax",
#'                  FUN="pk.calc.cmax",
#'                  values=c(FALSE, TRUE),
#'                  unit_type="conc",
#'                  pretty_name="Cmax",
#'                  desc="Maximum observed concentration")
#' add.interval.col("cmax.dn",
#'                  FUN="pk.calc.dn",
#'                  values=c(FALSE, TRUE),
#'                  unit_type="conc_dosenorm",
#'                  pretty_name="Cmax (dose-normalized)",
#'                  desc="Maximum observed concentration, dose normalized",
#'                  formalsmap=list(parameter="cmax"),
#'                  depends="cmax")
#' }
#' @family Interval specifications
#' @export
add.interval.col <- function(name,
                             FUN,
                             values=c(FALSE, TRUE),
                             unit_type,
                             pretty_name,
                             depends=NULL,
                             desc="",
                             sparse=FALSE,
                             formalsmap=list(),
                             datatype=c("interval",
                                        "individual",
                                        "population"),
                             pptestcd_cdisc=NULL,
                             pptest_cdisc=NULL) {
  # Check inputs
  checkmate::assert_character(x = name, len = 1, min.chars = 1, any.missing = FALSE)
  checkmate::assert_character(x = FUN, len = 1, any.missing = TRUE) # allows NA
  checkmate::assert_logical(x = sparse, len = 1, any.missing=FALSE)
  checkmate::assert_character(x = pretty_name, len = 1, min.chars = 1, any.missing=FALSE)
  checkmate::assert_character(x = desc, len = 1, any.missing=FALSE)
  checkmate::assert_character(x = depends, null.ok = TRUE)

  # `values` must be either a function (used to validate/coerce) or a vector
  # of allowed values -- both are acceptable, so just ensure it was supplied
  # and is one of those two forms.
  if (!is.function(values) && !is.vector(values)) {
    rlang::abort("`values` must be a function or a vector of allowed values", class = "pknca_error_values_invalid")
  }

  unit_type <-
    match.arg(
      unit_type,
      choices=c(
        "unitless", "fraction", "%", "count",
        "time", "inverse_time",
        "amount", "amount_dose", "amount_time",
        "conc", "conc_dosenorm",
        "dose",
        "volume",
        "auc", "aumc",
        "auc_dosenorm", "aumc_dosenorm",
        "clearance", "renal_clearance", "renal_clearance_dosenorm"
      )
    )

  # Validate datatype (only "interval" is currently supported)
  datatype <- match.arg(datatype)
  checkmate::assert_choice(x = datatype, choices = "interval")

  # Validate formalsmap
  checkmate::assert_list(x = formalsmap, names = "unique")

  # Validate formalsmap and function compatibility
  if (length(formalsmap) > 0) {
    # Ensure FUN exists
    if (is.na(FUN)) {
      rlang::abort("`formalsmap` may not be provided when `FUN` is NA", class = "pknca_error_formalsmap_with_na_fun")
    }
    # Ensure formalsmap names are unique
    checkmate::assert_character(x = names(formalsmap), min.chars = 1, any.missing = FALSE)
  }

  # Ensure that the function exists
  if (!is.na(FUN)) {
    # Ensure that the function exists
    fun_obj <- utils::getAnywhere(FUN)
    if (length(fun_obj$objs) == 0) {
      rlang::abort(
        sprintf(
          "The function named '%s' is not defined. Please define it before calling add.interval.col().",
          FUN
        ),
        class = "pknca_error_fun_not_found"
      )
    }

    # Validate formalsmap parameters match function formals
    if (length(formalsmap) > 0) {
      fun_formals <- names(formals(fun_obj$objs[[1]]))
      invalid_formals <- setdiff(names(formalsmap), fun_formals)
      if (length(invalid_formals) > 0) {
        rlang::abort(
          sprintf(
            "All names in `formalsmap` must be arguments to the function '%s'. Invalid names: %s",
            FUN,
            paste(dQuote(invalid_formals), collapse = ", ")
          ),
          class = "pknca_error_formalsmap_invalid_names"
        )
      }
    }

  }

  # Default CDISC mappings to name/desc when not provided
  if (is.null(pptestcd_cdisc)) {
    pptestcd_cdisc <- name
  }
  if (is.null(pptest_cdisc)) {
    pptest_cdisc <- desc
  }
  # Validate CDISC arguments: must be a character string or a named list
  # with a "route" element containing named sub-elements
  validate_cdisc_arg(pptestcd_cdisc, "pptestcd_cdisc")
  validate_cdisc_arg(pptest_cdisc, "pptest_cdisc")

  current <- get("interval.cols", envir=.PKNCAEnv)
  current[[name]] <-
    list(
      FUN=FUN,
      values=values,
      unit_type=unit_type,
      pretty_name=pretty_name,
      desc=desc,
      sparse=sparse,
      formalsmap=formalsmap,
      depends=depends,
      datatype=datatype,
      pptestcd_cdisc=pptestcd_cdisc,
      pptest_cdisc=pptest_cdisc
    )
  assign("interval.cols", current, envir=.PKNCAEnv)
}

# Sort the interval columns by dependencies.
#
# Columns are always to the right of columns that they depend on.
sort_interval_cols <- function() {
  current <- get("interval.cols", envir=.PKNCAEnv)
  # Only sort if necessary
  sort_order <- get0("interval.cols_sorted", envir=.PKNCAEnv)
  if (identical(sort_order, names(current))) {
    # It is already sorted
    return(sort_order)
  }
  # Build a dependency tree
  myorder <- rep(NA, length(current))
  names(myorder) <- names(current)
  nextnum <- 1
  while (anyNA(myorder)) {
    for (nextorder in seq_along(myorder)[is.na(myorder)]) {
      if (length(current[[nextorder]]$depends) == 0) {
        # If it doesn't depend on anything then it can go next in order.
        myorder[nextorder] <- nextnum
        nextnum <- nextnum + 1
      } else {
        # If all of its dependencies already have values, then it can be next.
        deps <- unique(unlist(current[[nextorder]]$depends))
        missing_deps <- deps[!(deps %in% names(myorder))]
        if (length(missing_deps) > 0) {
          rlang::abort(
            sprintf(
              "Invalid dependencies for interval column (please report this as a bug): %s The following dependencies are missing: %s",
              names(myorder)[nextorder],
              paste(missing_deps, collapse = ", ")
            ),
            class = "pknca_error_invalid_dependency"
          )
        }
        if (!anyNA(myorder[deps])) {
          myorder[nextorder] <- nextnum
          nextnum <- nextnum + 1
        }
      }
    }
  }
  current <- current[names(sort(myorder))]
  assign("interval.cols_sorted", names(current), envir=.PKNCAEnv)
  assign("interval.cols", current, envir=.PKNCAEnv)
  invisible(myorder)
}

#' Get the columns that can be used in an interval specification
#'
#' @returns A list with named elements for each parameter.  Each list element
#'   contains the parameter definition.
#' @seealso [check.interval.specification()] and the vignette "Selection of
#'   Calculation Intervals"
#' @examples
#' get.interval.cols()
#' @family Interval specifications
#' @export
get.interval.cols <- function() {
  sort_interval_cols()
  get("interval.cols", envir=.PKNCAEnv)
}

# Add the start and end interval columns
add.interval.col(
  "start",
  FUN = NA,
  values = as.numeric,
  unit_type="time",
  pretty_name="Interval Start",
  desc = "Starting time of the interval"
)
add.interval.col(
  "end",
  FUN = NA,
  values = as.numeric,
  unit_type="time",
  pretty_name="Interval End",
  desc = "Ending time of the interval (potentially infinity)"
)
