#' Compute noncompartmental pharmacokinetics
#'
#' Compute pharmacokinetic (PK) noncompartmental analysis (NCA)
#' parameters.
#'
#' PKNCA has been cross-validated with both Phoenix WinNonlin(R) and Pumas
#' (click here for the
#' [cross-validation
#' article](http://www.humanpredictions.com/wp-content/uploads/2020/01/ACOP_2019_T102_NCA_performance_evaluation_Yingbo_revised.pdf))
#'
#' A common workflow would load data from a file or database into a
#' data.frame then run the following code.
#' @examples
#' \dontrun{
#' # Load concentration-time data into a data.frame called d.conc
#' # with columns named "conc", "time", and "subject".
#' my.conc <- PKNCAconc(d.conc, conc~time|subject)
#' # Load dose-time data into a data.frame called d.dose
#' # with columns named "dose", "time", and "subject".
#' my.dose <- PKNCAdose(d.dose, dose~time|subject)
#' # Combine the concentration-time and dose-time data into an object
#' # ready for calculations.
#' my.data <- PKNCAdata(my.conc, my.dose)
#' # Perform the calculations
#' my.results <- pk.nca(my.data)
#' # Look at summary results
#' summary(my.results)
#' # Look at a listing of results
#' as.data.frame(my.results)
#' }
#' @docType package
#' @name PKNCA
"_PACKAGE"

# To work with the use of dplyr's pipe within the exclude function
utils::globalVariables(".")

.onLoad <- function(...) { # nocov start
  if (requireNamespace("units", quietly = TRUE)) {
    pknca_install_units()
  }
} # nocov end

#' Add the units that PKNCA accepts beyond those of udunits
#'
#' Adds `"fraction"` (a dimensionless unit, for fraction excreted) and `"mcg"`
#' (an alias of `"ug"`, the spelling clinical data commonly use) to the
#' `units` package.  `units::install_unit()` changes the udunits database of the
#' R session, so these units are also available to every other package that uses
#' `units` once PKNCA is loaded.  Installing a unit again with the same
#' definition does nothing, and `"mcg"` is not installed when udunits already
#' defines it.
#'
#' @returns `NULL`, invisibly
#' @keywords Internal
pknca_install_units <- function() {
  units::install_unit(symbol = "fraction", def = "1")
  if (!units::ud_are_convertible("mcg", "ug")) {
    units::install_unit(symbol = "mcg", def = "ug")
  }
  invisible(NULL)
}
