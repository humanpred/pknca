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

#' Dose-normalized renal clearance
#'
#' Renal clearance is a secondary parameter:  the amount excreted comes from
#' the urine interval and the AUC from a plasma interval.  Secondary
#' parameters are calculated from NCA parameter values only, so the
#' dose-normalized form takes everything renal clearance does plus the
#' interval's total dose (`totdose`), and is linked to its plasma interval
#' the same way.
#'
#' @inheritParams pk.calc.clr
#' @inheritParams pk.calc.dn
#' @returns The renal clearance divided by the dose
#' @keywords Internal
#' @noRd
pk.calc.clr.dn <- function(ae, auc, dose) {
  pk.calc.dn(parameter = pk.calc.clr(ae = ae, auc = auc), dose = dose)
}
pknca_concept(pk.calc.clr.dn) <- "renal_clearance"

# The calculation function for the dose-normalized form of each secondary
# parameter that has one, by the calculation function of the parameter
pknca_secondary_dn_fun <- c(pk.calc.clr = "pk.calc.clr.dn")

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
    # Derive dose-normalized CDISC codes from the base parameter.  A
    # dense/sparse mapping gets the suffix on each code so the dose-normalized
    # rows stay distinguishable from the base parameter's rows.
    dn_pptestcd <- if (is.character(current_pptestcd_cdisc)) {
      paste0(current_pptestcd_cdisc, "D")
    } else if (is.list(current_pptestcd_cdisc) &&
               setequal(names(current_pptestcd_cdisc), c("dense", "sparse"))) {
      lapply(current_pptestcd_cdisc, paste0, "D")
    } else {
      current_pptestcd_cdisc
    }
    dn_pptest <- if (is.character(current_pptest_cdisc)) {
      paste(current_pptest_cdisc, "by Dose")
    } else if (is.list(current_pptest_cdisc) &&
               setequal(names(current_pptest_cdisc), c("dense", "sparse"))) {
      lapply(current_pptest_cdisc, paste, "by Dose")
    } else {
      current_pptest_cdisc
    }
    # Dose-normalize the base parameter's formula by dividing its left-hand
    # side by the dose and marking that side with a "dn" subscript
    dn_formula <- "$X_{dn} = \\frac{X}{Dose}$"
    if (!is.null(current_formula) && grepl("^\\$.+? =", current_formula)) {
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
    current_spec <- get.interval.cols()[[n]]
    if (isTRUE(current_spec$selection$secondary)) {
      # A secondary parameter is calculated from NCA parameter values only, so
      # its dose-normalized form is a secondary parameter of its own with the
      # same inputs and reference, and with the dose from `totdose`.
      current_fun <- pknca_secondary_dn_fun[[current_spec$FUN]]
      current_formalsmap <- c(current_spec$formalsmap, list(dose="totdose"))
      current_depends <- c(current_spec$depends, "totdose")
      current_selection <- current_spec$selection
    } else {
      current_fun <- "pk.calc.dn"
      current_formalsmap <- list(parameter=n)
      current_depends <- n
      current_selection <- NULL
    }
    # Add the column to the interval specification
    add.interval.col(
      name=paste(n, "dn", sep="."),
      FUN=current_fun,
      values=c(FALSE, TRUE),
      unit_type=paste0(current_unit_type, "_dose"),
      pretty_name=paste(current_pretty_name, "(dose-normalized)"),
      desc=paste("Dose-normalized", n),
      formalsmap=current_formalsmap,
      depends=current_depends,
      formula=dn_formula,
      pptestcd_cdisc=dn_pptestcd,
      pptest_cdisc=dn_pptest,
      selection=current_selection
    )
    PKNCA.set.summary(
      name=paste(n, "dn", sep="."),
      description="geometric mean and geometric coefficient of variation",
      point=business.geomean,
      spread=business.geocv)
  }
})
