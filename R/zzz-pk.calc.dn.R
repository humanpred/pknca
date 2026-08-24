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
    current_unit_type <- get.interval.cols()[[n]]$unit_type
    current_pretty_name <- get.interval.cols()[[n]]$pretty_name
    current_pptestcd_cdisc <- get.interval.cols()[[n]]$pptestcd_cdisc
    current_pptest_cdisc <- get.interval.cols()[[n]]$pptest_cdisc
    current_formula <- get.interval.cols()[[n]]$formula
    # Derive dose-normalized CDISC codes from the base parameter
    dn_pptestcd <- if (is.character(current_pptestcd_cdisc)) {
      paste0(current_pptestcd_cdisc, "D")
    } else {
      current_pptestcd_cdisc
    }
    dn_pptest <- if (is.character(current_pptest_cdisc)) {
      paste(current_pptest_cdisc, "by Dose")
    } else {
      current_pptest_cdisc
    }
    # Dose-normalize the base parameter's formula by dividing its left-hand
    # side by the dose and marking that side with a "dn" subscript
    dn_formula <- "$X_{dn} = \\frac{X}{Dose}$"
    if (!is.null(current_formula)) {
      lhs <- sub("^\\$(.+?) =.*", "\\1", current_formula)
      if (grepl("_\\{", lhs)) {
        lhs_dn <- sub("\\}$", ",dn}", lhs)
      } else if (grepl("_.", lhs)) {
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
      formula=dn_formula,
      pptestcd_cdisc=dn_pptestcd,
      pptest_cdisc=dn_pptest
    )
    PKNCA.set.summary(
      name=paste(n, "dn", sep="."),
      description="geometric mean and geometric coefficient of variation",
      point=business.geomean,
      spread=business.geocv)
  }
})
