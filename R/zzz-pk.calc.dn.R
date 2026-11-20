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
              "cmax", "cmin", "clast.obs", "clast.pred", "cav.last", "ctrough")) {
    if (parameter_spec_is_secondary(get.interval.cols()[[n]])) {
      # A dose-normalized ratio has no meaning; a secondary base would make one
      rlang::abort(sprintf("%s is secondary and cannot be dose-normalized", n), class = "pknca_error_dn_secondary")  # nocov
    }
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
    # Add the column to the interval specification
    add.interval.col(
      name=paste(n, "dn", sep="."),
      FUN="pk.calc.dn",
      values=c(FALSE, TRUE),
      unit_type=paste0(current_unit_type, "_dose"),
      pretty_name=paste(current_pretty_name, "(dose-normalized)"),
      desc=paste("Dose-normalized", n),
      formalsmap=list(parameter=n),
      depends=c(n),
      formula=dn_formula,
      pptestcd_cdisc=dn_pptestcd,
      pptest_cdisc=dn_pptest,
      # The earlier names of the base parameter give the earlier names of its
      # dose-normalized form (cav for cav.last gives cav.dn for cav.last.dn)
      historical_names=
        if (length(get.interval.cols()[[n]]$historical_names) > 0) {
          paste(get.interval.cols()[[n]]$historical_names, "dn", sep=".")
        }
    )
    PKNCA.set.summary(
      name=paste(n, "dn", sep="."),
      description="geometric mean and geometric coefficient of variation",
      point=business.geomean,
      spread=business.geocv)
  }
})

# Every parameter a rule makes (such as `ratio.<base>`; see
# R/parameter-rules.R) is registered here, once every base is, so that the
# registry does not depend on what a session has requested.  This file is
# sourced last.
register_parameter_rule_members()

# The parameters of the package itself, as opposed to those registered after it
# is loaded (see set_intervals())
assign("interval.cols_package", names(get("interval.cols", envir = .PKNCAEnv)), envir = .PKNCAEnv)
