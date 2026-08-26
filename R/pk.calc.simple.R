# Calculate the simple parameters for PK.

#' Calculate the adjusted r-squared value
#'
#' @param r.sq The r-squared value
#' @param n The number of points
#' @return The numeric adjusted r-squared value
#' @family Half-life and elimination
#' @export
adj.r.squared <- function(r.sq, n) {
  if (n <= 2) {
    rlang::warn("n must be > 2 for adj.r.squared", class = "pknca_warning_adjr2_2points")
    structure(NA_real_, exclude="n must be > 2")
  } else {
    1-(1-r.sq)*(n-1)/(n-2)
  }
}

#' Determine maximum observed PK concentration
#'
#' @inheritParams assert_conc_time
#' @param check Run [assert_conc()]?
#' @return a number for the maximum concentration or NA if all concentrations
#'   are missing
#' @family NCA parameters for concentrations during the intervals
#' @export
pk.calc.cmax <- function(conc, check=TRUE) {
  if (check) {
    assert_conc(conc = conc)
  }
  if (length(conc) == 0 || all(is.na(conc))) {
    NA
  } else {
    max(conc, na.rm=TRUE)
  }
}

pknca_concept(pk.calc.cmax) <- "peak_conc"
# Add the column to the interval specification
add.interval.col("cmax",
                 FUN="pk.calc.cmax",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Cmax",
                 desc="Maximum observed concentration",
                 depends=NULL,
                 pptestcd_cdisc="CMAX",
                 pptest_cdisc="Max Conc",
                 formula="$C_{\\max} = \\max_i C_i$",
                 tier = "common")

#' @describeIn pk.calc.cmax Determine the minimum observed PK
#'   concentration
#' @family NCA parameters for concentrations during the intervals
#' @examples
#' conc_data <- Theoph[Theoph$Subject == 1,]
#' pk.calc.cmin(conc_data$conc)
#' @export
pk.calc.cmin <- function(conc, check=TRUE) {
  if (check) {
    assert_conc(conc=conc)
  }
  if (length(conc) == 0 || all(is.na(conc))) {
    NA
  } else {
    min(conc, na.rm=TRUE)
  }
}

pknca_concept(pk.calc.cmin) <- "min_conc"
# Add the column to the interval specification
add.interval.col("cmin",
                 FUN="pk.calc.cmin",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Cmin",
                 desc="Minimum observed concentration",
                 depends=NULL,
                 pptestcd_cdisc="CMIN",
                 pptest_cdisc="Min Conc",
                 formula="$C_{\\min} = \\min_i C_i$")

#' Determine time of maximum observed PK concentration
#'
#' Input restrictions are:
#' \enumerate{
#'   \item the `conc` and `time` must be the same length,
#'   \item the `time` may have no NAs,
#' }
#' `NA` will be returned if:
#' \enumerate{
#'   \item the length of `conc` and `time` is 0
#'   \item all `conc` is 0 or `NA`
#' }
#'
#' @inheritParams assert_conc_time
#' @inheritParams PKNCA.choose.option
#' @inheritParams clean.conc.blq
#' @param first.tmax If there is more than one time point with the maximum value (Cmax or ERmax),
#'   which time should be selected for Tmax/ERTmax?  If 'TRUE', the first will be selected. If not, then the
#'   last is considered Tmax/ERTmax.
#' @returns The time of the maximum concentration
#' @family NCA time parameters
#' @examples
#' conc_data <- Theoph[Theoph$Subject == 1,]
#' pk.calc.tmax(conc = conc_data$conc, time = conc_data$Time)
#' @export
pk.calc.tmax <- function(conc, time,
                         options=list(),
                         first.tmax=NULL,
                         check=TRUE) {
  first.tmax <- PKNCA.choose.option(name="first.tmax", value=first.tmax, options=options)
  if (check) {
    assert_conc_time(conc = conc, time = time)
  }
  if (length(conc) == 0 || all(conc %in% c(NA, 0))) {
    NA
  } else {
    ret <- time[conc %in% pk.calc.cmax(conc, check=FALSE)]
    if (first.tmax) {
      ret[1]
    } else {
      ret[length(ret)]
    }
  }
}

pknca_concept(pk.calc.tmax) <- "peak_time"
# Add the column to the interval specification
add.interval.col("tmax",
                 FUN="pk.calc.tmax",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tmax",
                 desc="Time of maximum observed conc",
                 depends=NULL,
                 pptestcd_cdisc="TMAX",
                 pptest_cdisc="Time of CMAX",
                 formula="$T_{\\max} = t_{i: C_i = C_{\\max}}$",
                 tier = "common")

#' Determine time of minimum observed PK concentration
#'
#' Input restrictions are:
#' \enumerate{
#'   \item the `conc` and `time` must be the same length,
#'   \item the `time` may have no NAs,
#' }
#' `NA` will be returned if:
#' \enumerate{
#'   \item the length of `conc` and `time` is 0
#'   \item all `conc` is `NA`
#' }
#'
#' @inheritParams assert_conc_time
#' @inheritParams PKNCA.choose.option
#' @inheritParams clean.conc.blq
#' @param first.tmin If there is more than one time point with the minimum value (Cmin),
#'   which time should be selected for Tmin?  If 'TRUE', the first will be selected. If not,
#'   then the last is considered Tmin.
#' @returns The time of the minimum concentration
#' @family NCA time parameters
#' @examples
#' conc_data <- Theoph[Theoph$Subject == 1,]
#' pk.calc.tmin(conc = conc_data$conc, time = conc_data$Time)
#' @export
pk.calc.tmin <- function(conc, time,
                         options=list(),
                         first.tmin=NULL,
                         check=TRUE) {
  first.tmin <- PKNCA.choose.option(name="first.tmin", value=first.tmin, options=options)
  if (check) {
    assert_conc_time(conc = conc, time = time)
  }
  if (length(conc) == 0 || all(is.na(conc))) {
    NA
  } else {
    ret <- time[conc %in% pk.calc.cmin(conc, check=FALSE)]
    if (first.tmin) {
      ret[1]
    } else {
      ret[length(ret)]
    }
  }
}

pknca_concept(pk.calc.tmin) <- "min_time"
# Add the column to the interval specification
add.interval.col("tmin",
                 FUN="pk.calc.tmin",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tmin",
                 desc="Time of minimum observed conc",
                 depends=NULL,
                 pptestcd_cdisc="TMIN",
                 pptest_cdisc="Time of CMIN Observation")


#' Determine time of last observed concentration above the limit of
#' quantification.
#'
#' `NA` will be returned if all `conc` are `NA` or 0.
#'
#' @inheritParams assert_conc_time
#' @inheritParams clean.conc.blq
#' @returns The time of the last observed concentration measurement
#' @family NCA time parameters
#' @export
pk.calc.tlast <- function(conc, time, check=TRUE) {
  if (check) {
    assert_conc_time(conc = conc, time = time)
  }
  if (all(conc %in% c(NA, 0))) {
    NA
  } else {
    max(time[!(conc %in% c(NA, 0))])
  }
}

pknca_concept(pk.calc.tlast) <- "last_time"
# Add the column to the interval specification
add.interval.col("tlast",
                 FUN="pk.calc.tlast",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tlast",
                 desc="Time of last conc above LOQ",
                 depends=NULL,
                 pptestcd_cdisc="TLST",
                 pptest_cdisc="Time of Last Nonzero Conc",
                 formula="$T_{\\text{last}} = t_{i: C_i > 0, i = \\max}$")

#' @describeIn pk.calc.tlast Determine the first concentration above
#'   the limit of quantification.
#' @export
pk.calc.tfirst <- function(conc, time, check=TRUE) {
  if (check) {
    assert_conc_time(conc, time)
  }
  if (all(conc %in% c(NA, 0))) {
    NA
  } else {
    min(time[!(conc %in% c(NA, 0))])
  }
}

pknca_concept(pk.calc.tfirst) <- "first_time"
# Add the column to the interval specification
add.interval.col("tfirst",
                 FUN="pk.calc.tfirst",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tfirst",
                 desc="Time of first conc above LOQ",
                 depends=NULL,
                 pptestcd_cdisc="TFIRST",
                 pptest_cdisc="Time of First Nonzero Conc",
                 formula="$T_{\\text{first}} = t_{i: C_i > 0, i = \\min}$")

#' Determine the last observed concentration above the limit of quantification
#' (LOQ).
#'
#' If all concentrations are missing, `NA_real_` is returned.  If all
#' concentrations are zero (below the limit of quantification) or missing, zero
#' is returned.  If Tlast is NA (due to no non-missing above LOQ measurements),
#' this will return `NA_real_`.
#'
#' @inheritParams assert_conc_time
#' @inheritParams clean.conc.blq
#' @returns The last observed concentration above the LOQ
#' @family NCA parameters for concentrations during the intervals
#' @export
pk.calc.clast.obs <- function(conc, time, check=TRUE) {
  if (check) {
    assert_conc_time(conc = conc, time = time)
  }
  if (all(is.na(conc))) {
    NA_real_
  } else if (all(conc %in% c(0, NA))) {
    0
  } else {
    tlast <- pk.calc.tlast(conc, time, check = FALSE)
    if (!is.na(tlast)) {
      conc[time %in% tlast]
    } else {
      NA_real_
    }
  }
}

pknca_concept(pk.calc.clast.obs) <- "last_conc"
# Add the column to the interval specification
add.interval.col("clast.obs",
                 FUN="pk.calc.clast.obs",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Clast",
                 desc="Last conc observed above LOQ",
                 depends=NULL,
                 pptestcd_cdisc="CLST",
                 pptest_cdisc="Last Nonzero Conc",
                 formula="$C_{\\text{last,obs}} = C_{i: t_i = T_{\\text{last}}}$")

#' Calculate the effective half-life
#'
#' @details thalf.eff is `log(2)*mrt`.
#'
#' @param mrt the mean residence time to infinity
#' @return the numeric value of the effective half-life
#' @family Half-life and elimination
#' @export
pk.calc.thalf.eff <- function(mrt) {
  log(2)*mrt
}

pknca_concept(pk.calc.thalf.eff) <- "effective_half_life"
# Add the columns to the interval specification
add.interval.col("thalf.eff.obs",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 desc="Effective half-life, MRTobs",
                 unit_type="time",
                 pretty_name="Effective half-life (based on MRT,obs)",
                 formalsmap=list(mrt="mrt.obs"),
                 depends="mrt.obs",
                 pptestcd_cdisc="EFFOHL",
                 pptest_cdisc="Effective Half-Life Obs",
                 formula="$t_{1/2,\\text{eff,obs}} = \\ln(2) \\cdot MRT_{\\text{obs}}$")

add.interval.col("thalf.eff.pred",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (based on MRT,pred)",
                 desc="Effective half-life, MRTpred",
                 formalsmap=list(mrt="mrt.pred"),
                 depends="mrt.pred",
                 pptestcd_cdisc="EFFPHL",
                 pptest_cdisc="Effective Half-Life Pred",
                 formula="$t_{1/2,\\text{eff,pred}} = \\ln(2) \\cdot MRT_{\\text{pred}}$")

add.interval.col("thalf.eff.last",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (based on MRT,last)",
                 desc="Effective half-life, MRTlast",
                 formalsmap=list(mrt="mrt.last"),
                 depends="mrt.last",
                 pptestcd_cdisc="EFFHL",
                 pptest_cdisc="Effective Half-Life (based on AUClast)",
                 formula="$t_{1/2,\\text{eff,last}} = \\ln(2) \\cdot MRT_{\\text{last}}$")

add.interval.col("thalf.eff.iv.obs",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (for IV dosing, based on MRT,obs)",
                 desc="Effective half-life, IV MRTobs",
                 formalsmap=list(mrt="mrt.iv.obs"),
                 depends="mrt.iv.obs",
                 pptestcd_cdisc="EFFIVOHL",
                 pptest_cdisc="Effective Half-Life (for IV dosing, based on MRT Obs)",
                 formula="$t_{1/2,\\text{eff,iv,obs}} = \\ln(2) \\cdot MRT_{\\text{iv,obs}}$")

add.interval.col("thalf.eff.iv.pred",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (for IV dosing, based on MRT,pred)",
                 desc="Effective half-life, IV MRTpred",
                 formalsmap=list(mrt="mrt.iv.pred"),
                 depends="mrt.iv.pred",
                 pptestcd_cdisc="EFFIVPHL",
                 pptest_cdisc="Effective Half-Life (for IV dosing, based on MRT Pred)",
                 formula="$t_{1/2,\\text{eff,iv,pred}} = \\ln(2) \\cdot MRT_{\\text{iv,pred}}$")

add.interval.col("thalf.eff.iv.last",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (for IV dosing, based on MRTlast)",
                 desc="Effective half-life, IV MRTlast",
                 formalsmap=list(mrt="mrt.iv.last"),
                 depends="mrt.iv.last",
                 pptestcd_cdisc="EFFIVLHL",
                 pptest_cdisc="Effective Half-Life (for IV dosing, based on AUClast)",
                 formula="$t_{1/2,\\text{eff,iv,last}} = \\ln(2) \\cdot MRT_{\\text{iv,last}}$")


#' Calculate the AUC percent extrapolated
#'
#' @details aucpext is `100*(1-auclast/aucinf)`.
#'
#' @param auclast the area under the curve from time 0 to the last measurement
#'   above the limit of quantification
#' @param aucinf the area under the curve from time 0 to infinity
#' @returns The numeric value of the AUC percent extrapolated or `NA_real_` if
#'   any of the following are true `is.na(aucinf)`, `is.na(auclast)`,
#'   `aucinf <= 0`, or `auclast <= 0`.
#' @family Half-life and elimination
#' @export
pk.calc.aucpext <- function(auclast, aucinf) {
  scalar_auclast <- length(auclast) == 1
  scalar_aucinf <- length(aucinf) == 1
  if (scalar_auclast || scalar_aucinf) {
    # no length checking needs to occur
  } else if ((!scalar_auclast && !scalar_aucinf) &&
             length(auclast) != length(aucinf)) {
    rlang::abort(
      "auclast and aucinf must either be a scalar or the same length.",
      class = "pknca_error_auclast_aucinf_length"
    )
  }
  ret <- rep(NA_real_, max(c(length(auclast), length(aucinf))))
  mask_na <-
    is.na(auclast) |
    is.na(aucinf)
  mask_negative <-
    !mask_na &
    (aucinf <= 0 |
       auclast <= 0)
  mask_greater <-
    !mask_na &
    (auclast >= aucinf)
  mask_calc <- !mask_na & !(aucinf %in% 0)
  if (any(mask_greater))
    rlang::warn(
      "aucpext is typically only calculated when aucinf is greater than auclast.",
      class = "pknca_warning_aucpext_aucinf_le_auclast"
    )
  if (any(mask_negative))
    rlang::warn(
      "aucpext is typically only calculated when both aucinf and auclast are positive.",
      class = "pknca_warning_aucpext_aucinf_auclast_positive"
    )
  ret[mask_calc] <-
    100*(1-auclast[mask_calc]/aucinf[mask_calc])
  ret
}

pknca_concept(pk.calc.aucpext) <- "auc_extrapolation"

# Add the columns to the interval specification
add.interval.col("aucpext.obs",
                 FUN="pk.calc.aucpext",
                 values=c(FALSE, TRUE),
                 unit_type="%",
                 pretty_name="AUCpext (based on AUCinf,obs)",
                 desc="% AUCinf extrap after Tlast, obs",
                 formalsmap=list(aucinf="aucinf.obs"),
                 depends=c("auclast", "aucinf.obs"),
                 pptestcd_cdisc="AUCPEO",
                 pptest_cdisc="AUC %Extrapolation Obs",
                 formula="$\\%AUC_{\\text{ext,obs}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{last}}}{AUC_{\\infty,\\text{obs}}}\\right)$",
                 tier = "common")

add.interval.col("aucpext.pred",
                 FUN="pk.calc.aucpext",
                 values=c(FALSE, TRUE),
                 unit_type="%",
                 pretty_name="AUCpext (based on AUCinf,pred)",
                 desc="% AUCinf extrap after Tlast, pred",
                 formalsmap=list(aucinf="aucinf.pred"),
                 depends=c("auclast", "aucinf.pred"),
                 pptestcd_cdisc="AUCPEP",
                 pptest_cdisc="AUC %Extrapolation Pred",
                 formula="$\\%AUC_{\\text{ext,pred}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{last}}}{AUC_{\\infty,\\text{pred}}}\\right)$")


#' Calculate the elimination rate (Kel)
#'
#' @param kel is `1/mrt`, not to be confused with lambda.z.
#'
#' @param mrt the mean residence time
#' @returns the numeric value of the elimination rate
#' @family Clearance and volume parameters
#' @export
pk.calc.kel <- function(mrt) {
  1/mrt
}

pknca_concept(pk.calc.kel) <- "elimination_rate"
# Add the columns to the interval specification
add.interval.col("kel.obs",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (based on AUCinf,obs)",
                 desc="Elim rate, MRT w/ obs Clast",
                 formalsmap=list(mrt="mrt.obs"),
                 depends="mrt.obs",
                 pptestcd_cdisc="KELOS",
                 pptest_cdisc="Kel (based on AUCinf,obs)",
                 formula="$k_{el,\\text{obs}} = \\frac{1}{MRT_{\\text{obs}}}$")

add.interval.col("kel.pred",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (based on AUCinf,pred)",
                 desc="Elim rate, MRT w/ pred Clast",
                 formalsmap=list(mrt="mrt.pred"),
                 depends="mrt.pred",
                 pptestcd_cdisc="KELP",
                 pptest_cdisc="Kel (based on AUCinf,pred)",
                 formula="$k_{el,\\text{pred}} = \\frac{1}{MRT_{\\text{pred}}}$")

add.interval.col("kel.last",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (based on AUClast)",
                 desc="Elim rate, MRT via AUClast",
                 formalsmap=list(mrt="mrt.last"),
                 depends="mrt.last",
                 pptestcd_cdisc="KELLST",
                 pptest_cdisc="Kel (based on AUClast)",
                 formula="$k_{el,\\text{last}} = \\frac{1}{MRT_{\\text{last}}}$")

add.interval.col("kel.iv.obs",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (for IV dosing, based on AUCinf,obs)",
                 desc="Elim rate, IV MRTobs",
                 formalsmap=list(mrt="mrt.iv.obs"),
                 depends="mrt.iv.obs",
                 pptestcd_cdisc="KELIVOS",
                 pptest_cdisc="Kel (for IV dosing, based on AUCinf,obs)",
                 formula="$k_{el,\\text{iv,obs}} = \\frac{1}{MRT_{\\text{iv,obs}}}$")

add.interval.col("kel.iv.pred",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (for IV dosing, based on AUCinf,pred)",
                 desc="Elim rate, IV MRTpred",
                 formalsmap=list(mrt="mrt.iv.pred"),
                 depends="mrt.iv.pred",
                 pptestcd_cdisc="KELIVP",
                 pptest_cdisc="Kel (for IV dosing, based on AUCinf,pred)",
                 formula="$k_{el,\\text{iv,pred}} = \\frac{1}{MRT_{\\text{iv,pred}}}$")

add.interval.col("kel.iv.last",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (for IV dosing, based on AUClast)",
                 desc="Elim rate, IV MRTlast",
                 formalsmap=list(mrt="mrt.iv.last"),
                 depends="mrt.iv.last",
                 pptestcd_cdisc="KELIVLT",
                 pptest_cdisc="Kel (for IV dosing, based on AUClast)",
                 formula="$k_{el,\\text{iv,last}} = \\frac{1}{MRT_{\\text{iv,last}}}$")

add.interval.col("kel.all",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCall)",
                 desc = "Elim rate, MRTall",
                 formalsmap = list(mrt = "mrt.all"),
                 depends = "mrt.all",
                 formula = "$k_{el,\\text{all}} = \\frac{1}{MRT_{\\text{all}}}$")

add.interval.col("kel.int.all",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCint.all)",
                 desc = "Elim rate, MRTint.all",
                 formalsmap = list(mrt = "mrt.int.all"),
                 depends = "mrt.int.all",
                 formula = "$k_{el,\\text{int,all}} = \\frac{1}{MRT_{\\text{int,all}}}$")

add.interval.col("kel.int.inf.obs",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCint.inf.obs)",
                 desc = "Elim rate, MRTint.inf.obs",
                 formalsmap = list(mrt = "mrt.int.inf.obs"),
                 depends = "mrt.int.inf.obs",
                 formula = "$k_{el,\\text{int,}\\infty\\text{,obs}} = \\frac{1}{MRT_{\\text{int,}\\infty\\text{,obs}}}$")

add.interval.col("kel.int.inf.pred",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCint.inf.pred)",
                 desc = "Elim rate, MRTint.inf.pred",
                 formalsmap = list(mrt = "mrt.int.inf.pred"),
                 depends = "mrt.int.inf.pred",
                 formula = "$k_{el,\\text{int,}\\infty\\text{,pred}} = \\frac{1}{MRT_{\\text{int,}\\infty\\text{,pred}}}$")

add.interval.col("kel.int.last",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCint.last)",
                 desc = "Elim rate, MRTint.last",
                 formalsmap = list(mrt = "mrt.int.last"),
                 depends = "mrt.int.last",
                 formula = "$k_{el,\\text{int,last}} = \\frac{1}{MRT_{\\text{int,last}}}$")

add.interval.col("kel.iv.all",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (for IV dosing,  based on AUCall)",
                 desc = "Elim rate, IV MRTall",
                 formalsmap = list(mrt = "mrt.iv.all"),
                 depends = "mrt.iv.all")

add.interval.col("kel.ivint.all",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (IV dose interval, based on AUCint.all)",
                 desc = "Elim rate, IV MRTint.all",
                 formalsmap = list(mrt = "mrt.ivint.all"),
                 depends = "mrt.ivint.all")

add.interval.col("kel.ivint.last",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (IV dose interval, based on AUCint.last)",
                 desc = "Elim rate, IV MRTint.last",
                 formalsmap = list(mrt = "mrt.ivint.last"),
                 depends = "mrt.ivint.last")

add.interval.col("kel.sparse.last",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (for sparse data, based on AUClast)",
                 desc = "Elim rate, sparse MRTlast",
                 sparse = TRUE,
                 formalsmap = list(mrt = "mrt.sparse.last"),
                 depends = "mrt.sparse.last")


#' Calculate the (observed oral) clearance
#'
#' @details cl is `dose/auc`.
#'
#' @param dose the dose administered
#' @param auc The area under the concentration-time curve.
#' @returns the numeric value of the total (CL) or observed oral clearance
#'   (CL/F)
#' @details If `dose` is the same length as the other inputs, then the output
#'   will be the same length as all of the inputs; the function assumes that you
#'   are calculating for multiple intervals simultaneously.  If the inputs other
#'   than `dose` are scalars and `dose` is a vector, then the function assumes
#'   multiple doses were given in a single interval, and the sum of the `dose`s
#'   will be used for the calculation.
#' @references Gabrielsson J, Weiner D. "Section 2.5.1 Derivation of clearance."
#'   Pharmacokinetic & Pharmacodynamic Data Analysis: Concepts and Applications,
#'   4th Edition.  Stockholm, Sweden: Swedish Pharmaceutical Press, 2000. 86-7.
#' @family Clearance and volume parameters
#' @export
pk.calc.cl <- function(dose, auc) {
  # sum() of nothing is 0, which would be a wrong answer, not a missing one
  if (length(dose) == 0) {
    return(NA_real_)
  }
  if (length(auc) == 1) {
    dose <- sum(dose)
  }
  ret <- dose/auc
  mask_zero <- !is.na(auc) & (auc <= 0)
  if (any(mask_zero)) {
    ret[mask_zero] <- NA_real_
  }
  ret
}

pknca_concept(pk.calc.cl) <- "clearance"

# Add the columns to the interval specification
add.interval.col("cl.last",
                 FUN="pk.calc.cl",
                 values=c(FALSE, TRUE),
                 unit_type="clearance",
                 pretty_name="CL (based on AUClast)",
                 desc="Clearance, AUClast",
                 formalsmap=list(auc="auclast"),
                 depends="auclast",
                 pptestcd_cdisc=list(route=list(extravascular="CLF/FLST", intravascular="CLLST")),
                 pptest_cdisc=list(route=list(extravascular="CL by F (based on AUClast)", intravascular="CL (based on AUClast)")),
                 formula="$CL_{\\text{last}} = \\frac{Dose}{AUC_{\\text{last}}}$")

add.interval.col("cl.all",
                 FUN="pk.calc.cl",
                 values=c(FALSE, TRUE),
                 unit_type="clearance",
                 pretty_name="CL (based on AUCall)",
                 desc="Clearance, AUCall",
                 formalsmap=list(auc="aucall"),
                 depends="aucall",
                 pptestcd_cdisc=list(route=list(extravascular="CLF/FALL", intravascular="CLALL")),
                 pptest_cdisc=list(route=list(extravascular="CL by F (based on AUCall)", intravascular="CL (based on AUCall)")),
                 formula="$CL_{\\text{all}} = \\frac{Dose}{AUC_{\\text{all}}}$")

add.interval.col("cl.obs",
                 FUN="pk.calc.cl",
                 values=c(FALSE, TRUE),
                 unit_type="clearance",
                 pretty_name="CL (based on AUCinf,obs)",
                 desc="Clearance, observed Clast",
                 formalsmap=list(auc="aucinf.obs"),
                 depends="aucinf.obs",
                 pptestcd_cdisc=list(route=list(extravascular="CLF/FO", intravascular="CLO")),
                 pptest_cdisc=list(route=list(extravascular="Total CL Obs by F", intravascular="Total CL Obs")),
                 formula="$CL_{\\text{obs}} = \\frac{Dose}{AUC_{\\infty,\\text{obs}}}$",
                 tier = "common")

add.interval.col("cl.pred",
                 FUN="pk.calc.cl",
                 values=c(FALSE, TRUE),
                 unit_type="clearance",
                 pretty_name="CL (based on AUCinf,pred)",
                 desc="Clearance, predicted Clast",
                 formalsmap=list(auc="aucinf.pred"),
                 depends="aucinf.pred",
                 pptestcd_cdisc=list(route=list(extravascular="CLF/FP", intravascular="CLP")),
                 pptest_cdisc=list(route=list(extravascular="Total CL Pred by F", intravascular="Total CL Pred")),
                 formula="$CL_{\\text{pred}} = \\frac{Dose}{AUC_{\\infty,\\text{pred}}}$")

add.interval.col("cl.int.all",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (based on AUCint.all)",
                 desc = "Clearance, AUCint.all",
                 formalsmap = list(auc = "aucint.all"),
                 depends = "aucint.all",
                 formula = "$CL_{\\text{int,all}} = \\frac{Dose}{AUC_{\\text{int,all}}}$")

add.interval.col("cl.int.inf.obs",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (based on AUCint.inf.obs)",
                 desc = "Clearance, AUCint.inf.obs",
                 formalsmap = list(auc = "aucint.inf.obs"),
                 depends = "aucint.inf.obs",
                 formula = "$CL_{\\text{int,}\\infty\\text{,obs}} = \\frac{Dose}{AUC_{\\text{int,}\\infty\\text{,obs}}}$",
                 tier = "common")

add.interval.col("cl.int.inf.pred",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (based on AUCint.inf.pred)",
                 desc = "Clearance, AUCint.inf.pred",
                 formalsmap = list(auc = "aucint.inf.pred"),
                 depends = "aucint.inf.pred",
                 formula = "$CL_{\\text{int,}\\infty\\text{,pred}} = \\frac{Dose}{AUC_{\\text{int,}\\infty\\text{,pred}}}$")

add.interval.col("cl.int.last",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (based on AUCint.last)",
                 desc = "Clearance, AUCint.last",
                 formalsmap = list(auc = "aucint.last"),
                 depends = "aucint.last",
                 formula = "$CL_{\\text{int,last}} = \\frac{Dose}{AUC_{\\text{int,last}}}$")

add.interval.col("cl.iv.all",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for IV dosing,  based on AUCall)",
                 desc = "IV clearance, AUCall",
                 formalsmap = list(auc = "aucivall"),
                 depends = "aucivall",
                 formula = "$CL_{\\text{iv,all}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,all}}}$")

add.interval.col("cl.iv.last",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for IV dosing,  based on AUClast)",
                 desc = "IV clearance, AUClast",
                 formalsmap = list(auc = "aucivlast"),
                 depends = "aucivlast",
                 formula = "$CL_{\\text{iv,last}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,last}}}$")

add.interval.col("cl.iv.obs",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for IV dosing,  based on AUCinf,obs)",
                 desc = "IV clearance, AUCinf.obs",
                 formalsmap = list(auc = "aucivinf.obs"),
                 depends = "aucivinf.obs",
                 formula = "$CL_{\\text{iv,obs}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,}\\infty\\text{,obs}}}$")

add.interval.col("cl.iv.pred",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for IV dosing,  based on AUCinf,pred)",
                 desc = "IV clearance, AUCinf.pred",
                 formalsmap = list(auc = "aucivinf.pred"),
                 depends = "aucivinf.pred",
                 formula = "$CL_{\\text{iv,pred}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,}\\infty\\text{,pred}}}$")

add.interval.col("cl.ivint.all",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (IV dose interval, based on AUCint.all)",
                 desc = "IV clearance, AUCint.all",
                 formalsmap = list(auc = "aucivint.all"),
                 depends = "aucivint.all",
                 formula = "$CL_{\\text{iv,int,all}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,int,all}}}$")

add.interval.col("cl.ivint.last",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (IV dose interval, based on AUCint.last)",
                 desc = "IV clearance, AUCint.last",
                 formalsmap = list(auc = "aucivint.last"),
                 depends = "aucivint.last",
                 formula = "$CL_{\\text{iv,int,last}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,int,last}}}$")

add.interval.col("cl.sparse.last",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for sparse data, based on AUClast)",
                 desc = "Clearance, sparse AUClast",
                 sparse = TRUE,
                 formalsmap = list(auc = "sparse_auclast"),
                 depends = "sparse_auclast",
                 formula = "$CL_{\\text{sparse,last}} = \\frac{Dose}{AUC_{\\text{sparse,last}}}$")


#' Calculate the absolute (or relative) bioavailability
#'
#' @details f is `(auc2/dose2)/(auc1/dose1)`.
#'
#' @param dose1 The dose administered in route or method 1
#' @param dose2 The dose administered in route or method 2
#' @param auc1 The AUC from 0 to infinity or 0 to tau administered in route or
#'   method 1
#' @param auc2 The AUC from 0 to infinity or 0 to tau administered in route or
#'   method 2
#' @export
pk.calc.f <- function(dose1, auc1, dose2, auc2) {
  ret <- (auc2/dose2)/(auc1/dose1)
  mask_zero <-
    is.na(auc1)  | (auc1 <= 0) |
    is.na(dose2) | (dose2 <= 0) |
    is.na(dose1) | (dose1 <= 0)
  if (any(mask_zero)) {
    ret[mask_zero] <- NA_real_
  }
  ret
}

pknca_concept(pk.calc.f) <- "bioavailability"
add.interval.col("f",
                 FUN="pk.calc.f",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Bioavailability",
                 desc="Bioavailability (absolute or relative)",
                 depends=NULL,
                 pptestcd_cdisc="FAB",
                 pptest_cdisc="Absolute Bioavailability",
                 formula="$F = \\frac{AUC_2 / Dose_2}{AUC_1 / Dose_1}$",
                 selection = list(secondary = TRUE))


#' Calculate the mean residence time (MRT) for single-dose data or linear
#' multiple-dose data.
#'
#' @details mrt is `aumc/auc - duration.dose/2` where `duration.dose =
#'   0` for oral administration.
#'
#' @param auc the AUC from 0 to infinity or 0 to tau
#' @param aumc the AUMC from 0 to infinity or 0 to tau
#' @param duration.dose The duration of the dose (usually an infusion duration
#'   for an IV infusion)
#' @returns the numeric value of the mean residence time
#' @family Mean residence time
#' @export
pk.calc.mrt <- function(auc, aumc) {
  pk.calc.mrt.iv(auc, aumc, duration.dose=0)
}

pknca_concept(pk.calc.mrt) <- "mrt"
# Add the columns to the interval specification
add.interval.col("mrt.obs",
                 FUN="pk.calc.mrt",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (based on AUCinf,obs)",
                 desc="MRT to inf, observed Clast",
                 formalsmap=list(auc="aucinf.obs", aumc="aumcinf.obs"),
                 depends=c("aucinf.obs", "aumcinf.obs"),
                 pptestcd_cdisc=list(route=list(extravascular="MRTEVFO", intravascular="MRTICFO")),
                 pptest_cdisc=list(route=list(extravascular="MRT Extravasc Infinity Obs", intravascular="MRT IV Cont Inf Infinity Obs")),
                 formula="$MRT_{\\text{obs}} = \\frac{AUMC_{\\infty,\\text{obs}}}{AUC_{\\infty,\\text{obs}}}$")

add.interval.col("mrt.pred",
                 FUN="pk.calc.mrt",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (based on AUCinf,pred)",
                 desc="MRT to inf, predicted Clast",
                 formalsmap=list(auc="aucinf.pred", aumc="aumcinf.pred"),
                 depends=c("aucinf.pred", "aumcinf.pred"),
                 pptestcd_cdisc=list(route=list(extravascular="MRTEVFP", intravascular="MRTICFP")),
                 pptest_cdisc=list(route=list(extravascular="MRT Extravasc Infinity Pred", intravascular="MRT IV Cont Inf Infinity Pred")),
                 formula="$MRT_{\\text{pred}} = \\frac{AUMC_{\\infty,\\text{pred}}}{AUC_{\\infty,\\text{pred}}}$")

add.interval.col("mrt.last",
                 FUN="pk.calc.mrt",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (based on AUClast)",
                 desc="MRT, AUClast/AUMClast",
                 formalsmap=list(auc="auclast", aumc="aumclast"),
                 depends=c("auclast", "aumclast"),
                 pptestcd_cdisc=list(route=list(extravascular="MRTEVLST", intravascular="MRTICLST")),
                 pptest_cdisc=list(route=list(extravascular="MRT Extravasc to Last Nonzero Conc", intravascular="MRT IV Cont Inf to Last Nonzero Conc")),
                 formula="$MRT_{\\text{last}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}}$")

add.interval.col("mrt.all",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCall)",
                 desc = "MRT, AUCall/AUMCall",
                 formalsmap = list(auc = "aucall", aumc = "aumcall"),
                 depends = c("aucall", "aumcall"),
                 formula = "$MRT_{\\text{all}} = \\frac{AUMC_{\\text{all}}}{AUC_{\\text{all}}}$")

add.interval.col("mrt.int.all",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCint.all)",
                 desc = "MRT, interval AUCall/AUMCall",
                 formalsmap = list(auc = "aucint.all", aumc = "aumcint.all"),
                 depends = c("aucint.all", "aumcint.all"),
                 formula = "$MRT_{\\text{int,all}} = \\frac{AUMC_{\\text{int,all}}}{AUC_{\\text{int,all}}}$")

add.interval.col("mrt.int.inf.obs",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCint.inf.obs)",
                 desc = "MRT, interval AUC/AUMCinf obs",
                 formalsmap = list(auc = "aucint.inf.obs", aumc = "aumcint.inf.obs"),
                 depends = c("aucint.inf.obs", "aumcint.inf.obs"),
                 formula = "$MRT_{\\text{int,}\\infty\\text{,obs}} = \\frac{AUMC_{\\text{int,}\\infty\\text{,obs}}}{AUC_{\\text{int,}\\infty\\text{,obs}}}$")

add.interval.col("mrt.int.inf.pred",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCint.inf.pred)",
                 desc = "MRT, interval AUC/AUMCinf pred",
                 formalsmap = list(auc = "aucint.inf.pred", aumc = "aumcint.inf.pred"),
                 depends = c("aucint.inf.pred", "aumcint.inf.pred"),
                 formula = "$MRT_{\\text{int,}\\infty\\text{,pred}} = \\frac{AUMC_{\\text{int,}\\infty\\text{,pred}}}{AUC_{\\text{int,}\\infty\\text{,pred}}}$")

add.interval.col("mrt.int.last",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCint.last)",
                 desc = "MRT, interval AUClast/AUMClast",
                 formalsmap = list(auc = "aucint.last", aumc = "aumcint.last"),
                 depends = c("aucint.last", "aumcint.last"),
                 formula = "$MRT_{\\text{int,last}} = \\frac{AUMC_{\\text{int,last}}}{AUC_{\\text{int,last}}}$")

add.interval.col("mrt.sparse.last",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (for sparse data, based on AUClast)",
                 desc = "MRT, sparse AUClast/AUMClast",
                 sparse = TRUE,
                 formalsmap = list(auc = "sparse_auclast", aumc = "sparse_aumclast"),
                 depends = c("sparse_auclast", "sparse_aumclast"))


#' @describeIn pk.calc.mrt MRT for an IV infusion
#' @export
pk.calc.mrt.iv <- function(auc, aumc, duration.dose) {
  ret <- aumc/auc - duration.dose/2
  mask_zero <- is.na(auc) | auc <= 0
  if (any(mask_zero)) {
    ret[mask_zero] <- NA_real_
  }
  ret
}

pknca_concept(pk.calc.mrt.iv) <- "mrt"

# Add the columns to the interval specification
add.interval.col("mrt.iv.obs",
                 FUN="pk.calc.mrt.iv",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for IV dosing, based on AUCinf,obs)",
                 desc="IV MRT, AUCinf.obs/AUMCinf.obs",
                 formalsmap=list(auc="aucinf.obs", aumc="aumcinf.obs"),
                 depends=c("aucinf.obs", "aumcinf.obs"),
                 pptestcd_cdisc="MRTIBIFO",
                 pptest_cdisc="MRT Intravasc Infinity Obs",
                 formula="$MRT_{\\text{iv,obs}} = \\frac{AUMC_{\\infty,\\text{obs}}}{AUC_{\\infty,\\text{obs}}} - \\frac{T_{\\text{inf}}}{2}$")

add.interval.col("mrt.iv.pred",
                 FUN="pk.calc.mrt.iv",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for IV dosing, based on AUCinf,pred)",
                 desc="IV MRT, AUCinf.pred/AUMCinf.pred",
                 formalsmap=list(auc="aucinf.pred", aumc="aumcinf.pred"),
                 depends=c("aucinf.pred", "aumcinf.pred"),
                 pptestcd_cdisc="MRTIBIFP",
                 pptest_cdisc="MRT Intravasc Infinity Pred",
                 formula="$MRT_{\\text{iv,pred}} = \\frac{AUMC_{\\infty,\\text{pred}}}{AUC_{\\infty,\\text{pred}}} - \\frac{T_{\\text{inf}}}{2}$")

add.interval.col("mrt.iv.last",
                 FUN="pk.calc.mrt.iv",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for IV dosing, based on AUClast)",
                 desc="IV MRT, AUClast/AUMClast",
                 formalsmap=list(auc="auclast", aumc="aumclast"),
                 depends=c("auclast", "aumclast"),
                 pptestcd_cdisc="MRTIBLST",
                 pptest_cdisc="MRT Intravasc to Last Nonzero Conc",
                 formula="$MRT_{\\text{iv,last}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} - \\frac{T_{\\text{inf}}}{2}$")

add.interval.col("mrt.iv.all",
                 FUN = "pk.calc.mrt.iv",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (for IV dosing, based on AUCall)",
                 desc = "IV MRT, AUCall/AUMCall",
                 formalsmap = list(auc = "aucivall", aumc = "aumcivall"),
                 depends = c("aucivall", "aumcivall"))

add.interval.col("mrt.ivint.all",
                 FUN = "pk.calc.mrt.iv",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (IV dose interval, based on AUCint.all)",
                 desc = "IV MRT, interval AUC/AUMCall",
                 formalsmap = list(auc = "aucivint.all", aumc = "aumcivint.all"),
                 depends = c("aucivint.all", "aumcivint.all"))

add.interval.col("mrt.ivint.last",
                 FUN = "pk.calc.mrt.iv",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (IV dose interval, based on AUCint.last)",
                 desc = "IV MRT, interval AUC/AUMClast",
                 formalsmap = list(auc = "aucivint.last", aumc = "aumcivint.last"),
                 depends = c("aucivint.last", "aumcivint.last"))


#' @describeIn pk.calc.mrt MRT for multiple-dose data with nonlinear kinetics
#'
#' @details mrt.md is `aumctau/auctau + tau*(aucinf-auctau)/auctau` and should
#'   only be used for multiple dosing with equal intervals between doses.
#'   Note that if `aucinf == auctau` (as would be the assumption with
#'   linear kinetics), the equation becomes the same as the single-dose MRT.
#'
#'   These are the parameters to use when PK are nonlinear.  With linear PK,
#'   MRT and Vss can be measured from a single dose and the single-dose
#'   parameters (`mrt.obs`, `vss.obs`, and similar) describe steady state as
#'   well.  When PK are nonlinear they do not, so MRT and Vss have to be
#'   measured over a steady-state dosing interval, which is what these
#'   parameters do.  The ratio `aumctau/auctau` on its own (`mrt.last` over a
#'   dosing interval) is not MRT at steady state and underestimates it
#'   substantially; the `tau*(aucinf-auctau)/auctau` term accounts for the drug
#'   still in the body at the end of the interval.
#'
#'   Within [pk.nca()], `tau` is detected from the dose times of the group with
#'   [find.tau()].  When the dosing data hold a single dose (a common
#'   steady-state design where only the profiled dose is recorded), nothing
#'   repeats and nothing can be detected, so give `tau` as a column of the
#'   interval specification instead; a `tau` column always takes precedence
#'   over detection.  If `tau` can be neither given nor detected, the parameter
#'   is `NA` with a warning.
#'
#' @param auctau the AUC from time 0 to the end of the dosing interval (tau).
#' @param aumctau the AUMC from time 0 to the end of the dosing interval (tau).
#' @param aucinf the AUC from time 0 to infinity (typically using single-dose
#'   data)
#' @inheritParams assert_dosetau
#' @export
pk.calc.mrt.md <- function(auctau, aumctau, aucinf, tau) {
  pk.calc.mrt.md.iv(
    auctau=auctau, aumctau=aumctau, aucinf=aucinf, tau=tau, duration.dose=0
  )
}

pknca_concept(pk.calc.mrt.md) <- "mrt"

add.interval.col("mrt.md.obs",
                 FUN="pk.calc.mrt.md",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for multiple dosing, based on AUCinf,obs)",
                 desc="MRT, multi-dose AUCinf.obs/AUMCinf.obs",
                 formalsmap=list(auctau="auclast", aumctau="aumclast", aucinf="aucinf.obs"),
                 depends=c("auclast", "aumclast", "aucinf.obs"),
                 pptestcd_cdisc="MRTMDO",
                 pptest_cdisc="MRT (for multiple dosing, based on AUCinf,obs)",
                 formula="$MRT_{\\text{md,obs}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{obs}} - AUC_{\\text{last}}}{AUC_{\\text{last}}}$",
                 selection = list(dosing = c("multiple", "steady_state")))

add.interval.col("mrt.md.pred",
                 FUN="pk.calc.mrt.md",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for multiple dosing, based on AUCinf,pred)",
                 desc="MRT, multi-dose AUCinf.pred/AUMCinf.pred",
                 formalsmap=list(auctau="auclast", aumctau="aumclast", aucinf="aucinf.pred"),
                 depends=c("auclast", "aumclast", "aucinf.pred"),
                 pptestcd_cdisc="MRTMDP",
                 pptest_cdisc="MRT (for multiple dosing, based on AUCinf,pred)",
                 formula="$MRT_{\\text{md,pred}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{pred}} - AUC_{\\text{last}}}{AUC_{\\text{last}}}$",
                 selection = list(dosing = c("multiple", "steady_state")))


#' @describeIn pk.calc.mrt MRT for multiple-dose data with nonlinear kinetics
#'   given as an IV infusion
#'
#' @details mrt.ivmd is mrt.md less half of the infusion duration, the same
#'   correction that mrt.iv applies to the single-dose MRT.  Without it, MRT
#'   and everything derived from it are high by `duration.dose/2`.
#'
#' @export
pk.calc.mrt.md.iv <- function(auctau, aumctau, aucinf, tau, duration.dose) {
  ret <- aumctau/auctau + tau*(aucinf-auctau)/auctau - duration.dose/2
  mask_zero <- is.na(auctau) | auctau <= 0
  if (any(mask_zero)) {
    ret[mask_zero] <- NA_real_
  }
  ret
}

pknca_concept(pk.calc.mrt.md.iv) <- "mrt"

add.interval.col("mrt.ivmd.obs",
                 FUN="pk.calc.mrt.md.iv",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for multiple dosing of an IV infusion, based on AUCinf,obs)",
                 desc="IV MRT, multi-dose, AUCinf.obs",
                 formalsmap=list(auctau="auclast", aumctau="aumclast", aucinf="aucinf.obs"),
                 depends=c("auclast", "aumclast", "aucinf.obs"),
                 formula="$MRT_{\\text{ivmd,obs}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{obs}} - AUC_{\\text{last}}}{AUC_{\\text{last}}} - \\frac{T_{\\text{inf}}}{2}$",
                 selection = list(dosing = c("multiple", "steady_state")))

add.interval.col("mrt.ivmd.pred",
                 FUN="pk.calc.mrt.md.iv",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for multiple dosing of an IV infusion, based on AUCinf,pred)",
                 desc="IV MRT, multi-dose, AUCinf.pred",
                 formalsmap=list(auctau="auclast", aumctau="aumclast", aucinf="aucinf.pred"),
                 depends=c("auclast", "aumclast", "aucinf.pred"),
                 formula="$MRT_{\\text{ivmd,pred}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{pred}} - AUC_{\\text{last}}}{AUC_{\\text{last}}} - \\frac{T_{\\text{inf}}}{2}$",
                 selection = list(dosing = c("multiple", "steady_state")))


#' Calculate the terminal volume of distribution (Vz)
#'
#' @details vz is `cl/lambda.z`.
#'
#' @inheritParams assert_lambdaz
#' @param cl the clearance (or apparent observed clearance)
#' @family Clearance and volume parameters
#' @export
pk.calc.vz <- function(cl, lambda.z) {
  assert_lambdaz(lambda.z)
  # Ensure that cl is either a scalar or the same length as AUC
  # (more complex repeating patterns while valid for general R are
  # likely errors here).
  if (!(length(cl) %in% c(1, length(lambda.z))) ||
      !(length(lambda.z) %in% c(1, length(cl))))
    rlang::abort("'cl' and 'lambda.z' must be the same length", class = "pknca_error_cl_lambdaz_length")
  cl/lambda.z
}

pknca_concept(pk.calc.vz) <- "volume_z"

# Add the columns to the interval specification
add.interval.col("vz.obs",
                 FUN="pk.calc.vz",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vz (based on AUCinf,obs)",
                 desc="Vz, observed Clast",
                 formalsmap=list(cl="cl.obs"),
                 depends=c("cl.obs", "lambda.z"),
                 pptestcd_cdisc=list(route=list(extravascular="VZF/FO", intravascular="VZO")),
                 pptest_cdisc=list(route=list(extravascular="Vz by F Obs", intravascular="Vz Obs")),
                 formula="$V_{z,\\text{obs}} = \\frac{CL_{\\text{obs}}}{\\lambda_z}$")

add.interval.col("vz.pred",
                 FUN="pk.calc.vz",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vz (based on AUCinf,pred)",
                 desc="Vz, predicted Clast",
                 formalsmap=list(cl="cl.pred"),
                 depends=c("cl.pred", "lambda.z"),
                 pptestcd_cdisc=list(route=list(extravascular="VZF/FP", intravascular="VZP")),
                 pptest_cdisc=list(route=list(extravascular="Vz by F Pred", intravascular="Vz Pred")),
                 formula="$V_{z,\\text{pred}} = \\frac{CL_{\\text{pred}}}{\\lambda_z}$")

add.interval.col("vz.all",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCall)",
                 desc = "Vz, AUCall-based CL",
                 formalsmap = list(cl = "cl.all"),
                 depends = c("cl.all", "lambda.z"),
                 formula = "$V_{z,\\text{all}} = \\frac{CL_{\\text{all}}}{\\lambda_z}$")

add.interval.col("vz.int.all",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCint.all)",
                 desc = "Vz, interval AUCint.all",
                 formalsmap = list(cl = "cl.int.all"),
                 depends = c("cl.int.all", "lambda.z"),
                 formula = "$V_{z,\\text{int,all}} = \\frac{CL_{\\text{int,all}}}{\\lambda_z}$")

add.interval.col("vz.int.inf.obs",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCint.inf.obs)",
                 desc = "Vz, interval AUCint.inf.obs",
                 formalsmap = list(cl = "cl.int.inf.obs"),
                 depends = c("cl.int.inf.obs", "lambda.z"),
                 formula = "$V_{z,\\text{int,}\\infty\\text{,obs}} = \\frac{CL_{\\text{int,}\\infty\\text{,obs}}}{\\lambda_z}$")

add.interval.col("vz.int.inf.pred",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCint.inf.pred)",
                 desc = "Vz, interval AUCint.inf.pred",
                 formalsmap = list(cl = "cl.int.inf.pred"),
                 depends = c("cl.int.inf.pred", "lambda.z"),
                 formula = "$V_{z,\\text{int,}\\infty\\text{,pred}} = \\frac{CL_{\\text{int,}\\infty\\text{,pred}}}{\\lambda_z}$")

add.interval.col("vz.int.last",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCint.last)",
                 desc = "Vz, interval AUCint.last",
                 formalsmap = list(cl = "cl.int.last"),
                 depends = c("cl.int.last", "lambda.z"),
                 formula = "$V_{z,\\text{int,last}} = \\frac{CL_{\\text{int,last}}}{\\lambda_z}$")

add.interval.col("vz.iv.all",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (for IV dosing,  based on AUCall)",
                 desc = "IV Vz, AUCall",
                 formalsmap = list(cl = "cl.iv.all"),
                 depends = c("cl.iv.all", "lambda.z"),
                 formula = "$V_{z,\\text{iv,all}} = \\frac{CL_{\\text{iv,all}}}{\\lambda_z}$")

add.interval.col("vz.iv.last",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (for IV dosing,  based on AUClast)",
                 desc = "IV Vz, AUClast",
                 formalsmap = list(cl = "cl.iv.last"),
                 depends = c("cl.iv.last", "lambda.z"),
                 formula = "$V_{z,\\text{iv,last}} = \\frac{CL_{\\text{iv,last}}}{\\lambda_z}$")

add.interval.col("vz.iv.obs",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (for IV dosing,  based on AUCinf,obs)",
                 desc = "IV Vz, observed AUCinf",
                 formalsmap = list(cl = "cl.iv.obs"),
                 depends = c("cl.iv.obs", "lambda.z"),
                 formula = "$V_{z,\\text{iv,obs}} = \\frac{CL_{\\text{iv,obs}}}{\\lambda_z}$")

add.interval.col("vz.iv.pred",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (for IV dosing,  based on AUCinf,pred)",
                 desc = "IV Vz, predicted AUCinf",
                 formalsmap = list(cl = "cl.iv.pred"),
                 depends = c("cl.iv.pred", "lambda.z"),
                 formula = "$V_{z,\\text{iv,pred}} = \\frac{CL_{\\text{iv,pred}}}{\\lambda_z}$")

add.interval.col("vz.ivint.all",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (IV dose interval, based on AUCint.all)",
                 desc = "IV Vz, interval AUCint.all",
                 formalsmap = list(cl = "cl.ivint.all"),
                 depends = c("cl.ivint.all", "lambda.z"),
                 formula = "$V_{z,\\text{iv,int,all}} = \\frac{CL_{\\text{iv,int,all}}}{\\lambda_z}$")

add.interval.col("vz.ivint.last",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (IV dose interval, based on AUCint.last)",
                 desc = "IV Vz, interval AUCint.last",
                 formalsmap = list(cl = "cl.ivint.last"),
                 depends = c("cl.ivint.last", "lambda.z"),
                 formula = "$V_{z,\\text{iv,int,last}} = \\frac{CL_{\\text{iv,int,last}}}{\\lambda_z}$")

add.interval.col("vz.last",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUClast)",
                 desc = "Vz, AUClast-based CL",
                 formalsmap = list(cl = "cl.last"),
                 depends = c("cl.last", "lambda.z"),
                 formula = "$V_{z,\\text{last}} = \\frac{CL_{\\text{last}}}{\\lambda_z}$")

add.interval.col("vz.sparse.last",
                 FUN         = "pk.calc.vz",
                 values      = c(FALSE, TRUE),
                 unit_type   = "volume",
                 pretty_name = "Vz (for sparse data, based on AUClast)",
                 desc        = "Vz from sparse sampling",
                 sparse      = TRUE,
                 formalsmap  = list(cl = "cl.sparse.last", lambda.z = "kel.sparse.last"),
                 depends     = c("cl.sparse.last", "kel.sparse.last"),
                 formula = "$V_{z,\\text{sparse,last}} = \\frac{CL_{\\text{sparse,last}}}{\\lambda_z}$")


#' @describeIn pk.calc.vz Steady-state volume of distribution (Vss)
#'
#' @details vss is `cl*mrt`.
#' @param mrt the mean residence time
#' @return the volume of distribution at steady-state
#' @export
pk.calc.vss <- function(cl, mrt) {
  cl*mrt
}

pknca_concept(pk.calc.vss) <- "volume_ss"
# Add the columns to the interval specification
add.interval.col("vss.obs",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (based on AUCinf,obs)",
                 desc="Vss, observed Clast",
                 formalsmap=list(cl="cl.obs", mrt="mrt.obs"),
                 depends=c("cl.obs", "mrt.obs"),
                 pptestcd_cdisc=list(route=list(extravascular="VSSF/FO", intravascular="VSSO")),
                 pptest_cdisc=list(route=list(extravascular="Vss by F Obs", intravascular="Vol Dist Steady State Obs")),
                 formula="$V_{ss,\\text{obs}} = CL_{\\text{obs}} \\cdot MRT_{\\text{obs}}$")

add.interval.col("vss.pred",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (based on AUCinf,pred)",
                 desc="Vss, predicted Clast",
                 formalsmap=list(cl="cl.pred", mrt="mrt.pred"),
                 depends=c("cl.pred", "mrt.pred"),
                 pptestcd_cdisc=list(route=list(extravascular="VSSF/FP", intravascular="VSSP")),
                 pptest_cdisc=list(route=list(extravascular="Vss by F Pred", intravascular="Vol Dist Steady State Pred")),
                 formula="$V_{ss,\\text{pred}} = CL_{\\text{pred}} \\cdot MRT_{\\text{pred}}$")

add.interval.col("vss.last",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (based on AUClast)",
                 desc="Vss, calc'd through Tlast",
                 formalsmap=list(cl="cl.last", mrt="mrt.last"),
                 depends=c("cl.last", "mrt.last"),
                 pptestcd_cdisc=list(route=list(extravascular="VSSF/FLST", intravascular="VSSLST")),
                 pptest_cdisc=list(route=list(extravascular="Vss by F (based on AUClast)", intravascular="Vss (based on AUClast)")),
                 formula="$V_{ss,\\text{last}} = CL_{\\text{last}} \\cdot MRT_{\\text{last}}$")

add.interval.col("vss.iv.obs",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for IV dosing, based on AUCinf,obs)",
                 desc="IV Vss, observed Clast",
                 formalsmap=list(cl="cl.obs", mrt="mrt.iv.obs"),
                 depends=c("cl.obs", "mrt.iv.obs"),
                 pptestcd_cdisc="VSSIVO",
                 pptest_cdisc="Vss (for IV dosing, based on AUCinf,obs)",
                 formula="$V_{ss,\\text{iv,obs}} = CL_{\\text{obs}} \\cdot MRT_{\\text{iv,obs}}$")

add.interval.col("vss.iv.pred",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for IV dosing, based on AUCinf,pred)",
                 desc="IV Vss, predicted Clast",
                 formalsmap=list(cl="cl.pred", mrt="mrt.iv.pred"),
                 depends=c("cl.pred", "mrt.iv.pred"),
                 pptestcd_cdisc="VSSIVP",
                 pptest_cdisc="Vss (for IV dosing, based on AUCinf,pred)",
                 formula="$V_{ss,\\text{iv,pred}} = CL_{\\text{pred}} \\cdot MRT_{\\text{iv,pred}}$")

add.interval.col("vss.iv.last",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for IV dosing, based on AUClast)",
                 desc="IV Vss, calc from AUClast",
                 formalsmap=list(cl="cl.last", mrt="mrt.iv.last"),
                 depends=c("cl.last", "mrt.iv.last"),
                 pptestcd_cdisc="VSSIVLST",
                 pptest_cdisc="Vss (for IV dosing, based on AUClast)",
                 formula="$V_{ss,\\text{iv,last}} = CL_{\\text{last}} \\cdot MRT_{\\text{iv,last}}$")

add.interval.col("vss.md.obs",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for multiple-dose, based on Clast,obs)",
                 desc="Vss, multi-dose, obs",
                 formalsmap=list(cl="cl.last", mrt="mrt.md.obs"),
                 depends=c("cl.last", "mrt.md.obs"),
                 pptestcd_cdisc="VSSMDO",
                 pptest_cdisc="Vss (for multiple-dose, based on AUCinf,obs)",
                 formula="$V_{ss,\\text{md,obs}} = CL_{\\text{last}} \\cdot MRT_{\\text{md,obs}}$",
                 selection = list(dosing = c("multiple", "steady_state")))

add.interval.col("vss.md.pred",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for multiple-dose, based on Clast,pred)",
                 desc="Vss, multi-dose, pred",
                 formalsmap=list(cl="cl.last", mrt="mrt.md.pred"),
                 depends=c("cl.last", "mrt.md.pred"),
                 pptestcd_cdisc="VSSMDP",
                 pptest_cdisc="Vss (for multiple-dose, based on AUCinf,pred)",
                 formula="$V_{ss,\\text{md,pred}} = CL_{\\text{last}} \\cdot MRT_{\\text{md,pred}}$",
                 selection = list(dosing = c("multiple", "steady_state")))

add.interval.col("vss.ivmd.obs",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for multiple-dose IV infusion, based on Clast,obs)",
                 desc="IV Vss, multi-dose, obs",
                 formalsmap=list(cl="cl.last", mrt="mrt.ivmd.obs"),
                 depends=c("cl.last", "mrt.ivmd.obs"),
                 formula="$V_{ss,\\text{ivmd,obs}} = CL_{\\text{last}} \\cdot MRT_{\\text{ivmd,obs}}$",
                 selection = list(dosing = c("multiple", "steady_state")))

add.interval.col("vss.ivmd.pred",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for multiple-dose IV infusion, based on Clast,pred)",
                 desc="IV Vss, multi-dose, pred",
                 formalsmap=list(cl="cl.last", mrt="mrt.ivmd.pred"),
                 depends=c("cl.last", "mrt.ivmd.pred"),
                 formula="$V_{ss,\\text{ivmd,pred}} = CL_{\\text{last}} \\cdot MRT_{\\text{ivmd,pred}}$",
                 selection = list(dosing = c("multiple", "steady_state")))

add.interval.col("vss.all",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCall)",
                 desc = "Vss, calc from AUCall",
                 formalsmap = list(cl = "cl.all", mrt = "mrt.all"),
                 depends = c("cl.all", "mrt.all"),
                 formula = "$V_{ss,\\text{all}} = CL_{\\text{all}} \\cdot MRT_{\\text{all}}$")

add.interval.col("vss.int.all",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCint.all)",
                 desc = "Vss, calc from interval AUCint.all",
                 formalsmap = list(cl = "cl.int.all", mrt = "mrt.int.all"),
                 depends = c("cl.int.all", "mrt.int.all"),
                 formula = "$V_{ss,\\text{int,all}} = CL_{\\text{int,all}} \\cdot MRT_{\\text{int,all}}$")

add.interval.col("vss.int.inf.obs",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCint.inf.obs)",
                 desc = "Vss, calc from interval AUCint.inf.obs",
                 formalsmap = list(cl = "cl.int.inf.obs", mrt = "mrt.int.inf.obs"),
                 depends = c("cl.int.inf.obs", "mrt.int.inf.obs"),
                 formula = "$V_{ss,\\text{int,}\\infty\\text{,obs}} = CL_{\\text{int,}\\infty\\text{,obs}} \\cdot MRT_{\\text{int,}\\infty\\text{,obs}}$")

add.interval.col("vss.int.inf.pred",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCint.inf.pred)",
                 desc = "Vss, calc from interval AUCint.inf.pred",
                 formalsmap = list(cl = "cl.int.inf.pred", mrt = "mrt.int.inf.pred"),
                 depends = c("cl.int.inf.pred", "mrt.int.inf.pred"),
                 formula = "$V_{ss,\\text{int,}\\infty\\text{,pred}} = CL_{\\text{int,}\\infty\\text{,pred}} \\cdot MRT_{\\text{int,}\\infty\\text{,pred}}$")

add.interval.col("vss.int.last",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCint.last)",
                 desc = "Vss, calc from interval AUCint.last",
                 formalsmap = list(cl = "cl.int.last", mrt = "mrt.int.last"),
                 depends = c("cl.int.last", "mrt.int.last"),
                 formula = "$V_{ss,\\text{int,last}} = CL_{\\text{int,last}} \\cdot MRT_{\\text{int,last}}$")

add.interval.col("vss.iv.all",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (for IV dosing,  based on AUCall)",
                 desc = "IV Vss, calc from AUCall",
                 formalsmap = list(cl = "cl.iv.all", mrt = "mrt.iv.all"),
                 depends = c("cl.iv.all", "mrt.iv.all"))

add.interval.col("vss.ivint.all",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (IV dose interval, based on AUCint.all)",
                 desc = "IV Vss, calc from interval AUCint.all",
                 formalsmap = list(cl = "cl.ivint.all", mrt = "mrt.ivint.all"),
                 depends = c("cl.ivint.all", "mrt.ivint.all"))

add.interval.col("vss.ivint.last",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (IV dose interval, based on AUCint.last)",
                 desc = "IV Vss, calc from interval AUCint.last",
                 formalsmap = list(cl = "cl.ivint.last", mrt = "mrt.ivint.last"),
                 depends = c("cl.ivint.last", "mrt.ivint.last"))

add.interval.col("vss.sparse.last",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (for sparse data, based on AUClast)",
                 desc = "Vss, calc from sparse AUClast",
                 sparse = TRUE,
                 formalsmap = list(cl = "cl.sparse.last", mrt = "mrt.sparse.last"),
                 depends = c("cl.sparse.last", "mrt.sparse.last"))


#' Calculate the average concentration during an interval.
#'
#' @details cav is `auc/(end-start)`.
#'
#' @param auc The area under the curve during the interval
#' @inheritParams assert_intervaltime_single
#' @returns The Cav (average concentration during the interval)
#' @family NCA parameters for concentrations during the intervals
#' @export
pk.calc.cav <- function(auc, start, end) {
  ret <- auc/(end-start)
  mask_zero <- is.na(end) | is.na(start) | end == start
  if (any(mask_zero)) {
    ret[mask_zero] <- NA_real_
  }
  ret
}

pknca_concept(pk.calc.cav) <- "average_conc"
add.interval.col(
  "cav",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "Avg conc in interval (AUClast)",
  depends = "auclast",
  formalsmap = list(auc = "auclast"),
  pptestcd_cdisc="CAVG",
  pptest_cdisc="Average Conc",
  formula = "$C_{av} = \\frac{AUC_{\\text{last}}}{t_{end} - t_{start}}$")

add.interval.col(
  "cav.int.last",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "Avg conc in interval (AUCint.last)",
  depends = "aucint.last",
  formalsmap = list(auc = "aucint.last"),
  pptestcd_cdisc="CAVGINT",
  pptest_cdisc="Average Conc from T1 to T2",
  formula = "$C_{av,\\text{int,last}} = \\frac{AUC_{\\text{int,last}}}{t_{end} - t_{start}}$")
add.interval.col(
  "cav.int.all",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "Avg conc in interval (AUCint.all)",
  depends = "aucint.all",
  formalsmap = list(auc = "aucint.all"),
  pptestcd_cdisc="CAVGINA",
  pptest_cdisc="Cavg All",
  formula = "$C_{av,\\text{int,all}} = \\frac{AUC_{\\text{int,all}}}{t_{end} - t_{start}}$")
add.interval.col(
  "cav.int.inf.obs",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "Avg conc in interval (AUCint.inf.obs)",
  depends = "aucint.inf.obs",
  formalsmap = list(auc = "aucint.inf.obs"),
  pptestcd_cdisc="CAVGINO",
  pptest_cdisc="Cavg Infinity Obs",
  formula = "$C_{av,\\text{int,}\\infty\\text{,obs}} = \\frac{AUC_{\\text{int,}\\infty\\text{,obs}}}{t_{end} - t_{start}}$")
add.interval.col(
  "cav.int.inf.pred",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "Avg conc in interval (AUCint.inf.pred)",
  depends = "aucint.inf.pred",
  formalsmap = list(auc = "aucint.inf.pred"),
  pptestcd_cdisc="CAVGINP",
  pptest_cdisc="Cavg Infinity Pred",
  formula = "$C_{av,\\text{int,}\\infty\\text{,pred}} = \\frac{AUC_{\\text{int,}\\infty\\text{,pred}}}{t_{end} - t_{start}}$")


#' Determine the trough (end of interval) concentration
#'
#' @inheritParams assert_conc_time
#' @inheritParams assert_intervaltime_single
#' @returns The concentration when `time == end`.  If none match, then `NA`
#' @family NCA parameters for concentrations during the intervals
#' @export
pk.calc.ctrough <- function(conc, time, end) {
  assert_conc_time(conc = conc, time = time)
  mask_end <- time %in% end
  if (sum(mask_end) == 1) {
    conc[mask_end]
  } else if (sum(mask_end) == 0) {
    NA_real_
  } else {
    # This should be impossible as assert_conc_time should catch
    # duplicates.
    rlang::abort("More than one time matches the starting time.  Please report this as a bug with a reproducible example.", class = "pknca_error_ctrough_multiple_start_times")  # nocov
  }
}

pknca_concept(pk.calc.ctrough) <- "trough_conc"
add.interval.col("ctrough",
                 FUN="pk.calc.ctrough",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Ctrough",
                 desc="Trough (end of interval) conc",
                 depends=NULL,
                 pptestcd_cdisc="CTROUGH",
                 pptest_cdisc="Conc Trough",
                 formula="$C_{\\text{trough}} = C(t_{\\text{end}})$",
                 tier = "common",
                 selection = list(dosing = c("multiple", "steady_state")))


#' @describeIn pk.calc.ctrough Concentration at the beginning of the interval
#'
#' @family NCA parameters for concentrations during the intervals
#' @export
pk.calc.cstart <- function(conc, time, start) {
  assert_conc_time(conc = conc, time = time)
  mask_start <- time %in% start
  if (sum(mask_start) == 1) {
    conc[mask_start]
  } else if (sum(mask_start) == 0) {
    NA_real_
  } else {
    # This should be impossible as assert_conc_time should catch
    # duplicates.
    rlang::abort("More than one time matches the starting time.  Please report this as a bug with a reproducible example.", class = "pknca_error_cstart_multiple_start_times")  # nocov
  }
}

pknca_concept(pk.calc.cstart) <- "start_conc"
add.interval.col("cstart",
                 FUN="pk.calc.cstart",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Cstart",
                 desc="The predose concentration",
                 depends=NULL,
                 pptestcd_cdisc="CSTART",
                 pptest_cdisc="Cstart",
                 formula="$C_{\\text{start}} = C(t_{\\text{start}})$")


#' Determine the peak-to-trough ratio
#'
#' @details ptr is `cmax/ctrough`.
#'
#' @param cmax The maximum observed concentration
#' @param ctrough The last concentration in an interval
#' @return The ratio of cmax to ctrough (if ctrough == 0, NA)
#' @family Multiple-dose PK parameters
#' @export
pk.calc.ptr <- function(cmax, ctrough) {
  ret <- cmax/ctrough
  ret[ctrough %in% 0] <- NA_real_
  ret
}

pknca_concept(pk.calc.ptr) <- "fluctuation"
add.interval.col("ptr",
                 FUN="pk.calc.ptr",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Peak-to-trough ratio",
                 desc="Peak-to-trough ratio",
                 depends=c("cmax", "ctrough"),
                 pptestcd_cdisc="PTROUGHR",
                 pptest_cdisc="Peak Trough Ratio",
                 formula="$PTR = \\frac{C_{\\max}}{C_{\\text{trough}}}$")


#' Determine the observed lag time (time before the first
#' concentration above the limit of quantification or above the first
#' concentration in the interval)
#'
#' @inheritParams assert_conc_time
#' @returns The time associated with the first increasing concentration
#' @family NCA time parameters
#' @export
pk.calc.tlag <- function(conc, time) {
  assert_conc_time(conc = conc, time = time)
  mask.increase <- c(conc[-1] > conc[-length(conc)], FALSE)
  if (any(mask.increase)) {
    time[mask.increase][1]
  } else {
    NA_real_
  }
}

pknca_concept(pk.calc.tlag) <- "lag_time"
add.interval.col("tlag",
                 FUN="pk.calc.tlag",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tlag",
                 desc="Lag time",
                 depends=NULL,
                 pptestcd_cdisc="TLAG",
                 pptest_cdisc="Time to First Nonzero Conc",
                 formula="$T_{\\text{lag}} = t_{i: C_{i+1} > C_i, i = \\min}$",
                 tier = "common",
                 selection = list(route = "extravascular"))


#' Determine the degree of fluctuation
#'
#' @details deg.fluc is `100*(cmax - cmin)/cav`.
#'
#' @param cmax The maximum observed concentration
#' @param cmin The minimum observed concentration
#' @param cav The average concentration in the interval
#' @returns The degree of fluctuation around the average concentration.
#' @family Multiple-dose PK parameters
#' @export
pk.calc.deg.fluc <- function(cmax, cmin, cav) {
  ret <- 100*(cmax - cmin)/cav
  mask_zero <- is.na(cav) | cav == 0
  if (any(mask_zero)) {
    ret[mask_zero] <- NA_real_
  }
  ret
}

pknca_concept(pk.calc.deg.fluc) <- "fluctuation"
add.interval.col("deg.fluc",
                 FUN="pk.calc.deg.fluc",
                 unit_type="%",
                 pretty_name="Degree of fluctuation",
                 desc="Degree of fluctuation",
                 depends=c("cmax", "cmin", "cav"),
                 pptestcd_cdisc="DEGFLUC",
                 pptest_cdisc="Degree of fluctuation",
                 formula="$DF = 100 \\cdot \\frac{C_{\\max} - C_{\\min}}{C_{av}}$",
                 selection = list(dosing = c("multiple", "steady_state")))


#' @describeIn pk.calc.deg.fluc PK swing
#'
#' @details swing is `100*(cmax - cmin)/cmin`.
#'
#' @returns The swing above the minimum concentration.  If `cmin` is zero, then
#'   the result is infinity.
#' @export
pk.calc.swing <- function(cmax, cmin) {
  if (cmin > 0) {
    100*(cmax - cmin)/cmin
  } else {
    Inf
  }
}

pknca_concept(pk.calc.swing) <- "fluctuation"
add.interval.col("swing",
                 FUN="pk.calc.swing",
                 unit_type="%",
                 pretty_name="Swing",
                 desc="Swing relative to Cmin",
                 depends=c("cmax", "cmin"),
                 pptestcd_cdisc="SWING",
                 pptest_cdisc="Swing",
                 formula="$Swing = 100 \\cdot \\frac{C_{\\max} - C_{\\min}}{C_{\\min}}$",
                 selection = list(dosing = c("multiple", "steady_state")))


#' Determine the concentration at the end of infusion
#'
#' @inheritParams assert_conc_time
#' @inheritParams clean.conc.blq
#' @param duration.dose The duration for the dosing administration (typically
#'   from IV infusion)
#' @returns The concentration at the end of the infusion, `NA` if
#'   `duration.dose` is `NA`, or `NA` if all `time != duration.dose`
#' @family NCA parameters for concentrations during the intervals
#' @export
pk.calc.ceoi <- function(conc, time, duration.dose=NA, check=TRUE) {
  if (check) {
    assert_conc_time(conc = conc, time = time)
  }
  if (is.na(duration.dose)) {
    NA_real_
  } else if (all(time != duration.dose)) {
    NA_real_
  } else {
    conc[time == duration.dose][1]
  }
}

pknca_concept(pk.calc.ceoi) <- "eoi_conc"
add.interval.col("ceoi",
                 FUN="pk.calc.ceoi",
                 unit_type="conc",
                 pretty_name="Ceoi",
                 desc="Concentration at the end of infusion",
                 depends=NULL,
                 pptestcd_cdisc="CEOI",
                 pptest_cdisc="Ceoi",
                 formula="$C_{\\text{eoi}} = C(t = T_{\\text{inf}})$",
                 tier = "common",
                 selection = list(route = "iv_infusion"))


#' Calculate the AUC above a given concentration
#'
#' Concentrations below the given concentration (`conc_above`) will be set
#' to zero.
#' @inheritParams pk.calc.time_above
#' @param conc_above The concentration threshold to calculate AUC above.
#'   Must be finite (`Inf`/`-Inf` are not allowed); if `NA`, no AUC is
#'   calculated.
#' @returns The AUC of the concentration above the limit
#' @export
pk.calc.aucabove <- function(conc, time, conc_above = NA_real_, ..., options=list()) {
  checkmate::assert_number(conc_above, na.ok = TRUE, finite = TRUE)
  if (is.na(conc_above)) {
    ret <- structure(NA_real_, exclude = "Missing concentration to be above")
  } else {
    ret <-
      pk.calc.auc(
        conc=pmax(conc - conc_above, 0), time=time, ..., options=options,
        auc.type="AUCall",
        lambda.z=NA
      )
  }
  ret
}

pknca_concept(pk.calc.aucabove) <- "auc_above_conc"
add.interval.col(
  "aucabove.predose.all",
  FUN="pk.calc.aucabove",
  unit_type="auc",
  pretty_name="AUC,above",
  desc="AUC above predose, floor at 0",
  depends="cstart",
  formalsmap = list(conc_above = "cstart"),
  pptestcd_cdisc="AUCABVPA",
  pptest_cdisc="AUC above predose",
  formula="$AUC_{\\text{above,predose}} = \\int \\max(C(t) - C_{\\text{start}},\\; 0)\\; dt$")

add.interval.col(
  "aucabove.trough.all",
  FUN="pk.calc.aucabove",
  unit_type="auc",
  pretty_name="AUC,above",
  desc="AUC above trough, floor at 0",
  depends="ctrough",
  formalsmap = list(conc_above = "ctrough"),
  pptestcd_cdisc="AUCABVTA",
  pptest_cdisc="AUC above trough",
  formula="$AUC_{\\text{above,trough}} = \\int \\max(C(t) - C_{\\text{trough}},\\; 0)\\; dt$")


#' Count the number of concentration measurements in an interval
#'
#' `count_conc` and `count_conc_measured` are typically used for quality control
#' on the data to ensure that there are a sufficient number of non-missing
#' samples for a calculation and to ensure that data are consistent between
#' individuals.
#'
#' @section Imputed concentrations:
#'
#' Both counts are taken after imputation, and neither distinguishes an imputed
#' concentration from a measured one.  `count_conc` counts every non-missing
#' concentration, so any imputation that adds a point increases it.
#' `count_conc_measured` counts concentrations above the limit of
#' quantification, so whether an imputed point is counted depends on its value
#' rather than on its being imputed:  the zero added by
#' [PKNCA_impute_method_start_conc0()] is not counted, while the concentration
#' carried to the start time by [PKNCA_impute_method_start_predose()] and the
#' minimum added by [PKNCA_impute_method_start_cmin()] are.
#'
#' To count only measured samples, calculate the counts in an interval with no
#' imputation.
#'
#' @inheritParams pk.calc.cmax
#' @returns a count of the non-missing concentrations (0 if all concentrations
#'   are missing)
#' @family NCA parameters for concentrations during the intervals
#' @export
pk.calc.count_conc <- function(conc, check=TRUE) {
  if (check) {
    assert_conc(conc)
  }
  sum(!is.na(conc))
}

pknca_concept(pk.calc.count_conc) <- "observation_count"
# Add the column to the interval specification
add.interval.col(
  "count_conc",
  FUN = "pk.calc.count_conc",
  values = c(FALSE, TRUE),
  unit_type = "count",
  pretty_name = "Concentration count",
  desc = "Count of non-missing conc",
  depends = NULL,
  pptestcd_cdisc="CNTCONC",
  pptest_cdisc="Concentration count",
  formula = "$n_{\\text{conc}} = \\sum_{i} \\mathbf{1}(C_i \\neq NA)$",
  tier = "common")

#' @describeIn pk.calc.count_conc Count the number of concentration measurements
#'   that are not missing, above, or below the limit of quantification in an
#'   interval
#'
#' @returns a count of the non-missing, measured (not below or above the limit
#'   of quantification) concentrations (0 if all concentrations are missing).
#'   "Measured" here means above the limit of quantification; an imputed
#'   concentration above it is counted (see the "Imputed concentrations"
#'   section).
#' @export
pk.calc.count_conc_measured <- function(conc, check=TRUE) {
  if (check) {
    assert_conc(conc)
  }
  sum(!is.na(conc) & is.finite(conc) & conc > 0)
}

pknca_concept(pk.calc.count_conc_measured) <- "observation_count"
# Add the column to the interval specification
add.interval.col(
  "count_conc_measured",
  FUN="pk.calc.count_conc_measured",
  values=c(FALSE, TRUE),
  unit_type="count",
  pretty_name="Measured concentration count",
  desc="Count of measured, non-BLQ conc",
  depends=NULL,
  formula="$n_{\\text{measured}} = \\sum_{i} \\mathbf{1}(C_i > 0)$")


#' Extract the dose used for calculations
#'
#' @inheritParams pk.calc.cl
#' @returns The total dose for an interval
#' @export
pk.calc.totdose <- function(dose) {
  if (length(dose) == 0) {
    return(NA_real_)
  }
  sum(dose)
}

pknca_concept(pk.calc.totdose) <- "total_dose"
add.interval.col(
  "totdose",
  FUN="pk.calc.totdose",
  values=c(FALSE, TRUE),
  unit_type="dose",
  pretty_name="Total dose",
  desc="Total dose given in interval",  
  pptestcd_cdisc="TDOSE",
  pptest_cdisc="Total dose administered",
  formula="$Dose_{\\text{total}} = \\sum_i Dose_i$")

# =============================================================================
# SET SUMMARY STATISTICS
# =============================================================================
#===============================================================================
# CONCENTRATION PARAMETERS - count: 13
# Ordered: base → trough/start → average → interval → special
#===============================================================================
PKNCA.set.summary(
  name = c(
    # Base concentrations  - count: 3
    "cmax", "cmin", "clast.obs",
    
    # Trough and start  - count: 3
    "ctrough", "cstart", "ceoi",
    
    # Average concentrations  - count: 5
    "cav", "cav.int.all", "cav.int.last", "cav.int.inf.obs", "cav.int.inf.pred",
    
    # Special AUC above  - count: 2
    "aucabove.predose.all", "aucabove.trough.all"
  ),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)

#===============================================================================
# TIME PARAMETERS - count: 5
# Ordered: chronological
#===============================================================================
PKNCA.set.summary(
  name = c(
    "tfirst", "tlag", "tmin", "tmax", "tlast"
  ),
  description = "median and range",
  point = business.median,
  spread = business.range
)

#===============================================================================
# PERCENTAGE / FLUCTUATION PARAMETERS   - count: 4
#===============================================================================
PKNCA.set.summary(
  name = c(
    "aucpext.obs", "aucpext.pred",
    "deg.fluc", "swing"
  ),
  description = "arithmetic mean and standard deviation",
  point = business.mean,
  spread = business.sd
)

#===============================================================================
# RATIO PARAMETERS   - count: 2
#===============================================================================
PKNCA.set.summary(
  name = c(
    "ptr", "f"
  ),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)

#===============================================================================
# EFFECTIVE HALF-LIFE   - count: 6
# Ordered: base → IV
#===============================================================================
PKNCA.set.summary(
  name = c(
    "thalf.eff.obs", "thalf.eff.pred", "thalf.eff.last",
    "thalf.eff.iv.obs", "thalf.eff.iv.pred", "thalf.eff.iv.last"
  ),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)

#===============================================================================
# COUNT PARAMETERS   - count: 3
#===============================================================================
PKNCA.set.summary(
  name = c(
    "count_conc", "count_conc_measured", "totdose"
  ),
  description = "median and range",
  point = business.median,
  spread = business.range
)

#===============================================================================
# BASIC PK PARAMETERS (CL, KEL, MRT, VZ, VSS) - count: 79
# Ordered: base → int → inf → iv → ivint → sparse → md (if applicable)
#===============================================================================
PKNCA.set.summary(
  name = c(
    
    # Clearance (CL) - count: 15
    "cl.obs", "cl.pred", "cl.last", "cl.all",
    "cl.int.all", "cl.int.last", "cl.int.inf.obs", "cl.int.inf.pred",
    "cl.iv.obs", "cl.iv.pred", "cl.iv.last", "cl.iv.all",
    "cl.ivint.all", "cl.ivint.last",
    "cl.sparse.last",
    
    # Elimination rate constant (KEL) - count: 15
    "kel.obs", "kel.pred", "kel.last", "kel.all",
    "kel.int.all", "kel.int.last", "kel.int.inf.obs", "kel.int.inf.pred",
    "kel.iv.obs", "kel.iv.pred", "kel.iv.last", "kel.iv.all",
    "kel.ivint.all", "kel.ivint.last",
    "kel.sparse.last",
    
    # Mean residence time (MRT) - count: 19
    "mrt.obs", "mrt.pred", "mrt.last", "mrt.all",
    "mrt.int.all", "mrt.int.last", "mrt.int.inf.obs", "mrt.int.inf.pred",
    "mrt.iv.obs", "mrt.iv.pred", "mrt.iv.last", "mrt.iv.all",
    "mrt.ivint.all", "mrt.ivint.last",
    "mrt.sparse.last",
    "mrt.md.obs", "mrt.md.pred",
    "mrt.ivmd.obs", "mrt.ivmd.pred",
    
    # Volume of distribution at steady state (VSS) - count: 19
    "vss.obs", "vss.pred", "vss.last", "vss.all",
    "vss.int.all", "vss.int.last", "vss.int.inf.obs", "vss.int.inf.pred",
    "vss.iv.obs", "vss.iv.pred", "vss.iv.last", "vss.iv.all",
    "vss.ivint.all", "vss.ivint.last",
    "vss.sparse.last",
    "vss.md.obs", "vss.md.pred",
    "vss.ivmd.obs", "vss.ivmd.pred",
    
    # Volume of distribution (VZ) - count: 15
    "vz.obs", "vz.pred", "vz.last", "vz.all",
    "vz.int.all", "vz.int.last", "vz.int.inf.obs", "vz.int.inf.pred",
    "vz.iv.obs", "vz.iv.pred", "vz.iv.last", "vz.iv.all",
    "vz.ivint.all", "vz.ivint.last",
    "vz.sparse.last"
  ),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)
