#' Determine dose normalized NCA parameter
#'
#' @param parameter Parameter to dose normalize
#' @param dose Dose in units compatible with the area under the curve
#' @returns a number for dose normalized AUC
#' @examples
#' pk.calc.dn(90, 10)
#' @export
pk.calc.dn <- function(parameter, dose) {
  parameter/dose
}

local({
  for (n in c("auclast", "aucall", "aucinf.obs", "aucinf.pred",
              "aumclast", "aumcall", "aumcinf.obs", "aumcinf.pred",
              "cmax", "cmin", "clast.obs", "clast.pred", "cav", "ctrough",
              "clr.last", "clr.obs", "clr.pred")) {
    current_cols <- get.interval.cols()[[n]]
    current_unit_type <- current_cols$unit_type
    current_pretty_name <- current_cols$pretty_name
    # Build a parameter-specific formula from the base parameter's formula
    current_formula <- current_cols$formula
    dn_formula <- "$X_{dn} = \\frac{X}{Dose}$"
    if (!is.null(current_formula)) {
      # Extract the LHS symbol (between leading "$" and " =")
      lhs <- sub("^\\$(.+?) =.*", "\\1", current_formula)
      # Add ",dn" into the subscript: X_{...} -> X_{...,dn}
      if (grepl("_\\{", lhs)) {
        lhs_dn <- sub("\\}$", ",dn}", lhs)
      } else if (grepl("_.", lhs)) {
        # Single-char subscript like CL_R -> CL_{R,dn}
        lhs_dn <- sub("_(.)", "_{\\1,dn}", lhs)
      } else {
        lhs_dn <- paste0(lhs, "_{dn}")
      }
      dn_formula <- paste0("$", lhs_dn, " = \\frac{", lhs, "}{Dose}$")
    }
    # Add the column to the interval specification
    add.interval.col(
      name=paste(n, "dn", sep="."),
      FUN="pk.calc.dn",
      values=c(FALSE, TRUE),
      unit_type=paste0(current_unit_type, "_dose"),
      pretty_name=paste(current_pretty_name, "(dose-normalized)"),
      desc=paste("Dose normalized", n),
      formalsmap=list(parameter=n),
      depends=c(n),
      formula=dn_formula
    )
    PKNCA.set.summary(
      name=paste(n, "dn", sep="."),
      description="geometric mean and geometric coefficient of variation",
      point=business.geomean,
      spread=business.geocv)
  }
})
