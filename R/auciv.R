#' Calculate AUXC (AUC or AUMC) for IV dosing with C0 back-extrapolation
#'
#' Calculates AUC or AUMC for intravenous dosing, with optional back-extrapolation
#' to C0.
#'
#' @details
#' The AUXC for intravenous (IV) dosing extrapolates the AUXC back from the first
#' measurement to time 0 using `c0` and the AUXC calculated by another method
#' (e.g., auclast or aumclast).
#'
#' How the calculation proceeds depends on what is measured at `time = 0`:
#'
#' \describe{
#'   \item{A concentration is measured at `time = 0`}{The AUXC between `time = 0`
#'     and the next time point is calculated with the measured concentration
#'     (`auxc_first`) and with `c0` (`auxc_second`).  The final AUXC is
#'     `auxc + auxc_second - auxc_first`.}
#'   \item{No concentration at `time = 0` and `auxc` was calculated}{`auxc` comes
#'     from a method that extrapolates back to `time = 0` with `conc.origin`
#'     (zero; the `aucint` family), so that segment is replaced by the one using
#'     `c0` in the same way.}
#'   \item{No concentration at `time = 0` and `auxc` is `NA`}{`auxc` is `NA`
#'     because an AUXC may not start before the first measurement.  `c0` supplies
#'     that measurement, so the AUXC is calculated here from `c0` and the
#'     measured data using `fun_auxc` and `auc.type`.}
#' }
#'
#' @inheritParams pk.calc.auxc
#' @inheritParams PKNCA.choose.option
#' @param c0 The concentration at time 0, typically calculated using [pk.calc.c0()]
#' @param auxc The AUXC calculated using `conc` and `time` without `c0`
#'   (it may be calculated using any method)
#' @param fun_auxc_last Function to calculate the AUXC for the last interval
#'   (e.g., `pk.calc.auc.last` or `pk.calc.aumc.last`)
#' @param fun_auxc Function to calculate the AUXC over the full interval when
#'   `auxc` could not be calculated (e.g., `pk.calc.auc` or `pk.calc.aumc`)
#' @param auc.type The type of AUXC for `fun_auxc` to calculate.  `NULL` (the
#'   default) means that the AUXC will not be calculated from `c0` and the
#'   measured data, so `NA` is returned when `auxc` is `NA`.
#' @param clast The last concentration above the limit of quantification, used
#'   by `fun_auxc` when `auc.type` is `"AUCinf"` (`clast.obs` gives AUCinf,obs
#'   and `clast.pred` gives AUCinf,pred)
#'
#' @return The AUXC calculated using `c0`
#'
#' @family AUC calculations
#' @family AUMC calculations
#' @export
pk.calc.auxciv <- function(conc, time, c0, auxc, fun_auxc_last, fun_auxc,
                           auc.type = NULL, lambda.z = NA, clast = NA,
                           ..., options = list(), check = TRUE) {
  if (check) {
    assert_conc_time(conc = conc, time = time)
    data <-
      clean.conc.blq(
        conc, time,
        options = options,
        check = FALSE
      )
  } else {
    data <- data.frame(conc = conc, time = time)
  }
  if (nrow(data) == 0) {
    return(structure(NA_real_, exclude = "No data for AUC calculation"))
  } else if (is.na(c0)) {
    return(structure(NA_real_, exclude = "c0 is not calculated"))
  }
  if (0 %in% data$time) {
    auxc_first <- fun_auxc_last(conc = data$conc[1:2], time = data$time[1:2], ..., check = FALSE)
    auxc_second <- fun_auxc_last(conc = c(c0, data$conc[2]), time = data$time[1:2], ..., check = FALSE)
    auxc + auxc_second - auxc_first
  } else if (data$time[1] < 0) {
    structure(NA_real_, exclude = "No time 0 in data")
  } else if (!is.na(auxc)) {
    # auxc extrapolated back to time 0 with conc.origin (zero); replace that
    # segment with the one starting from c0.
    auxc_first <- fun_auxc_last(conc = c(0, data$conc[1]), time = c(0, data$time[1]), ..., check = FALSE)
    auxc_second <- fun_auxc_last(conc = c(c0, data$conc[1]), time = c(0, data$time[1]), ..., check = FALSE)
    auxc + auxc_second - auxc_first
  } else if (is.null(auc.type)) {
    structure(NA_real_, exclude = "No time 0 in data")
  } else {
    auxc_args <-
      list(
        conc = c(c0, data$conc), time = c(0, data$time),
        auc.type = auc.type,
        ...,
        options = options, check = FALSE
      )
    if (identical(auc.type, "AUCinf")) {
      auxc_args$clast <- clast
      auxc_args$lambda.z <- lambda.z
    }
    ret <- do.call(fun_auxc, auxc_args)
    if (!is.na(ret)) {
      # auxc is NA here, and its reason for exclusion does not apply to a value
      # that was calculated from c0.
      attr(ret, "exclude") <- "DO NOT EXCLUDE"
    }
    ret
  }
}


#' @describeIn pk.calc.auxciv Calculate AUC for intravenous dosing with C0 back-extrapolation
#' @param auc The AUC calculated using `conc` and `time` without `c0`
#' @export
pk.calc.auciv <- function(conc, time, c0, auc, auc.type = NULL,
                          lambda.z = NA, clast = NA, ..., options = list(),
                          check = TRUE) {
  pk.calc.auxciv(
    conc = conc, time = time,
    c0 = c0, auxc = auc,
    fun_auxc_last = pk.calc.auc.last,
    fun_auxc = pk.calc.auc,
    auc.type = auc.type,
    lambda.z = lambda.z,
    clast = clast,
    ...,
    options = options,
    check = check
  )
}


add.interval.col(
  name = "aucivlast",
  FUN = "pk.calc.auciv",
  unit_type = "auc",
  pretty_name = "AUClast (IV dosing)",
  depends = c("auclast", "c0"),
  desc = "AUClast, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(auc="auclast", auc.type=I("AUClast"), lambda.z=NULL, clast=NULL),
  pptestcd_cdisc="AUCIVLST",
  pptest_cdisc="AUClast (IV dosing)",
  formula = "$AUC_{\\text{iv,last}} = AUC_{\\text{last}} + AUC(C_0, t_1) - AUC(C(0), t_1)$")

add.interval.col(
  name = "aucivall",
  FUN = "pk.calc.auciv",
  unit_type = "auc",
  pretty_name = "AUCall (IV dosing)",
  depends = c("aucall", "c0"),
  desc = "AUCall, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(auc="aucall", auc.type=I("AUCall"), lambda.z=NULL, clast=NULL),
  pptestcd_cdisc="AUCIVA",
  pptest_cdisc="AUCall (IV dosing)",
  formula = "$AUC_{\\text{iv,all}} = AUC_{\\text{all}} + AUC(C_0, t_1) - AUC(C(0), t_1)$")

add.interval.col(
  name = "aucivint.last",
  FUN = "pk.calc.auciv",
  unit_type = "auc",
  pretty_name = "AUCint,last (IV dosing)",
  depends = c("aucint.last", "c0"),
  desc = "AUCint.last, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(auc="aucint.last", auc.type=NULL, lambda.z=NULL, clast=NULL),
  pptestcd_cdisc="AUCIVILT",
  pptest_cdisc="AUCint,last (IV dosing)",
  formula = "$AUC_{\\text{iv,int,last}} = AUC_{\\text{int,last}} + AUC(C_0, t_1) - AUC(C(0), t_1)$")

add.interval.col(
  name = "aucivint.all",
  FUN = "pk.calc.auciv",
  unit_type = "auc",
  pretty_name = "AUCint,all (IV dosing)",
  depends = c("aucint.all", "c0"),
  desc = "AUCint.all, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(auc="aucint.all", auc.type=NULL, lambda.z=NULL, clast=NULL),
  pptestcd_cdisc="AUCIVINA",
  pptest_cdisc="AUCint,all (IV dosing)",
  formula = "$AUC_{\\text{iv,int,all}} = AUC_{\\text{int,all}} + AUC(C_0, t_1) - AUC(C(0), t_1)$")

add.interval.col(
  name = "aucivinf.obs",
  FUN = "pk.calc.auciv",
  unit_type = "auc",
  pretty_name = "AUCinf,obs (IV dosing)",
  depends = c("aucinf.obs", "c0", "lambda.z", "clast.obs"),
  desc = "AUCinf.obs, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(auc="aucinf.obs", auc.type=I("AUCinf"), clast="clast.obs"),
  pptestcd_cdisc="AUCIVIS",
  pptest_cdisc="AUCinf,obs (IV dosing)",
  formula = "$AUC_{\\text{iv,}\\infty\\text{,obs}} = AUC_{\\infty,\\text{obs}} + AUC(C_0, t_1) - AUC(C(0), t_1)$")

add.interval.col(
  name = "aucivinf.pred",
  FUN = "pk.calc.auciv",
  unit_type = "auc",
  pretty_name = "AUCinf,pred (IV dosing)",
  depends = c("aucinf.pred", "c0", "lambda.z", "clast.pred"),
  desc = "AUCinf.pred, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(auc="aucinf.pred", auc.type=I("AUCinf"), clast="clast.pred"),
  pptestcd_cdisc="AUCIVIP",
  pptest_cdisc="AUCinf,pred (IV dosing)",
  formula = "$AUC_{\\text{iv,}\\infty\\text{,pred}} = AUC_{\\infty,\\text{pred}} + AUC(C_0, t_1) - AUC(C(0), t_1)$")


#' @describeIn pk.calc.auxciv Calculate the percent back-extrapolated AUC for IV
#'   administration
#' @details The calculation for back-extrapolation is `100*(1 - auc/auciv)`.
#' @param auc The AUC calculated without C0 back-extrapolation 
#' @param auciv The AUC calculated using `c0`
#' @returns `pk.calc.auciv_pctbackextrap`: The AUC percent back-extrapolated
#' @export
pk.calc.auciv_pbext <- function(auc, auciv) {
  if (!is.na(auciv) && !is.na(auc) && auciv < auc){rlang::abort("auciv must be >= auc; back-extrapolation cannot be negative.")}
  100*(1 - auc/auciv)
}

add.interval.col(
  name = "aucivpbextlast",
  FUN = "pk.calc.auciv_pbext",
  unit_type = "%",
  pretty_name = "AUCbext (based on AUClast)",
  depends = c("auclast", "aucivlast"),
  desc = "Back-extrap %, IV, AUClast",
  sparse = FALSE,
  formalsmap = list(auc="auclast", auciv="aucivlast"),
  pptestcd_cdisc="AUCIVPLT",
  pptest_cdisc="AUCbext (based on AUClast)",
  formula = "$\\%AUC_{\\text{bext,last}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{last}}}{AUC_{\\text{iv,last}}}\\right)$")

add.interval.col(
  name = "aucivpbextall",
  FUN = "pk.calc.auciv_pbext",
  unit_type = "%",
  pretty_name = "AUCbext (based on AUCall)",
  depends = c("aucall", "aucivall"),
  desc = "Back-extrap %, IV, AUCall",
  sparse = FALSE,
  formalsmap = list(auc="aucall", auciv="aucivall"),
  pptestcd_cdisc="AUCIVPEA",
  pptest_cdisc="AUCbext (based on AUCall)",
  formula = "$\\%AUC_{\\text{bext,all}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{all}}}{AUC_{\\text{iv,all}}}\\right)$")

add.interval.col(
  name = "aucivpbextint.last",
  FUN = "pk.calc.auciv_pbext",
  unit_type = "%",
  pretty_name = "AUCbext (based on AUCint,last)",
  depends = c("aucint.last", "aucivint.last"),
  desc = "Back-extrap %, IV, AUCint.last",
  sparse = FALSE,
  formalsmap = list(auc="aucint.last", auciv="aucivint.last"),
  pptestcd_cdisc="AUCIVPIL",
  pptest_cdisc="AUCbext (based on AUCint,last)",
  formula = "$\\%AUC_{\\text{bext,int,last}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{int,last}}}{AUC_{\\text{iv,int,last}}}\\right)$")

add.interval.col(
  name = "aucivpbextint.all",
  FUN = "pk.calc.auciv_pbext",
  unit_type = "%",
  pretty_name = "AUCbext (based on AUCint,all)",
  depends = c("aucint.all", "aucivint.all"),
  desc = "Back-extrap %, IV, AUCint.all",
  sparse = FALSE,
  formalsmap = list(auc="aucint.all", auciv="aucivint.all"),
  pptestcd_cdisc="AUCIVPIA",
  pptest_cdisc="AUCbext (based on AUCint,all)",
  formula = "$\\%AUC_{\\text{bext,int,all}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{int,all}}}{AUC_{\\text{iv,int,all}}}\\right)$")

add.interval.col(
  name = "aucivpbextinf.obs",
  FUN = "pk.calc.auciv_pbext",
  unit_type = "%",
  pretty_name = "AUCbext (based on AUCinf,obs)",
  depends = c("aucinf.obs", "aucivinf.obs"),
  desc = "Back-extrap %, IV, AUCinf.obs",
  sparse = FALSE,
  formalsmap = list(auc="aucinf.obs", auciv="aucivinf.obs"),
  pptestcd_cdisc="AUCIVPEI",
  pptest_cdisc="AUCbext (based on AUCinf,obs)",
  formula = "$\\%AUC_{\\text{bext,}\\infty\\text{,obs}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\infty,\\text{obs}}}{AUC_{\\text{iv,}\\infty\\text{,obs}}}\\right)$")

add.interval.col(
  name = "aucivpbextinf.pred",
  FUN = "pk.calc.auciv_pbext",
  unit_type = "%",
  pretty_name = "AUCbext (based on AUCinf,pred)",
  depends = c("aucinf.pred", "aucivinf.pred"),
  desc = "Back-extrap %, IV, AUCinf.pred",
  sparse = FALSE,
  formalsmap = list(auc="aucinf.pred", auciv="aucivinf.pred"),
  pptestcd_cdisc="AUCIVPEP",
  pptest_cdisc="AUCbext (based on AUCinf,pred)",
  formula = "$\\%AUC_{\\text{bext,}\\infty\\text{,pred}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\infty,\\text{pred}}}{AUC_{\\text{iv,}\\infty\\text{,pred}}}\\right)$")


#' @describeIn pk.calc.auxciv Calculate AUMC for intravenous dosing with C0 back-extrapolation
#' @param aumc The AUMC calculated using `conc` and `time` without `c0`
#' @export
pk.calc.aumciv <- function(conc, time, c0, aumc, auc.type = NULL,
                           lambda.z = NA, clast = NA, ..., options = list(),
                           check = TRUE) {
  pk.calc.auxciv(
    conc = conc, time = time,
    c0 = c0, auxc = aumc,
    fun_auxc_last = pk.calc.aumc.last,
    fun_auxc = pk.calc.aumc,
    auc.type = auc.type,
    lambda.z = lambda.z,
    clast = clast,
    ...,
    options = options,
    check = check
  )
}
# Register all standard AUMC IV versions
add.interval.col(
  name = "aumcivlast",
  FUN = "pk.calc.aumciv",
  unit_type = "aumc",
  pretty_name = "AUMClast (IV dosing)",
  depends = c("aumclast", "c0"),
  desc = "AUMClast, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(aumc = "aumclast", auc.type = I("AUClast"), lambda.z = NULL, clast = NULL)
)

add.interval.col(
  name = "aumcivall",
  FUN = "pk.calc.aumciv",
  unit_type = "aumc",
  pretty_name = "AUMCall (IV dosing)",
  depends = c("aumcall", "c0"),
  desc = "AUMCall, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(aumc = "aumcall", auc.type = I("AUCall"), lambda.z = NULL, clast = NULL)
)

add.interval.col(
  name = "aumcivint.last",
  FUN = "pk.calc.aumciv",
  unit_type = "aumc",
  pretty_name = "AUMCint,last (IV dosing)",
  depends = c("aumcint.last", "c0"),
  desc = "AUMCint.last, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(aumc = "aumcint.last", auc.type = NULL, lambda.z = NULL, clast = NULL)
)

add.interval.col(
  name = "aumcivint.all",
  FUN = "pk.calc.aumciv",
  unit_type = "aumc",
  pretty_name = "AUMCint,all (IV dosing)",
  depends = c("aumcint.all", "c0"),
  desc = "AUMCint.all, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(aumc = "aumcint.all", auc.type = NULL, lambda.z = NULL, clast = NULL)
)

add.interval.col(
  name = "aumcivinf.obs",
  FUN = "pk.calc.aumciv",
  unit_type = "aumc",
  pretty_name = "AUMCinf,obs (IV dosing)",
  depends = c("aumcinf.obs", "c0", "lambda.z", "clast.obs"),
  desc = "AUMCinf.obs, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(aumc = "aumcinf.obs", auc.type = I("AUCinf"), clast = "clast.obs")
)

add.interval.col(
  name = "aumcivinf.pred",
  FUN = "pk.calc.aumciv",
  unit_type = "aumc",
  pretty_name = "AUMCinf,pred (IV dosing)",
  depends = c("aumcinf.pred", "c0", "lambda.z", "clast.pred"),
  desc = "AUMCinf.pred, IV back-extrap C0",
  sparse = FALSE,
  formalsmap = list(aumc = "aumcinf.pred", auc.type = I("AUCinf"), clast = "clast.pred")
)


#===============================================================================
# PKNCA.set.summary - Count: 18
# Ordered: base → int (last → all) → inf (obs → pred)
#===============================================================================
# Geometric summaries for AUC and AUMC IV
PKNCA.set.summary(
  name = c(
    "aucivlast", "aucivall", "aucivint.last", "aucivint.all", "aucivinf.obs", "aucivinf.pred",
    "aumcivlast", "aumcivall", "aumcivint.last", "aumcivint.all", "aumcivinf.obs", "aumcivinf.pred"
  ),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)

# Arithmetic summaries for percent back-extrapolation
PKNCA.set.summary(
  name = c(
    "aucivpbextlast", "aucivpbextall", "aucivpbextint.last", "aucivpbextint.all", "aucivpbextinf.obs", "aucivpbextinf.pred"
  ),
  description = "arithmetic mean and standard deviation",
  point = business.mean,
  spread = business.sd
)