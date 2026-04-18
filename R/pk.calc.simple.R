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
    rlang::warn(
      message = "n must be > 2 for adj.r.squared",
      class = "pknca_adjr2_2points"
    )
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
# Add the column to the interval specification
add.interval.col("cmax",
                 FUN="pk.calc.cmax",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Cmax",
                 desc="Maximum observed concentration",
                 depends=NULL,
                 formula="$C_{\\max} = \\max_i C_i$")
PKNCA.set.summary(
  name="cmax",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
# Add the column to the interval specification
add.interval.col("cmin",
                 FUN="pk.calc.cmin",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Cmin",
                 desc="Minimum observed concentration",
                 depends=NULL,
                 formula="$C_{\\min} = \\min_i C_i$")
PKNCA.set.summary(
  name="cmin",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
# Add the column to the interval specification
add.interval.col("tmax",
                 FUN="pk.calc.tmax",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tmax",
                 desc="Time of the maximum observed concentration",
                 depends=NULL,
                 formula="$T_{\\max} = t_{i: C_i = C_{\\max}}$")
PKNCA.set.summary(
  name="tmax",
  description="median and range",
  point=business.median,
  spread=business.range
)

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
# Add the column to the interval specification
add.interval.col("tmin",
                 FUN="pk.calc.tmin",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tmin",
                 desc="Time of the minimum observed concentration",
                 depends=NULL)
PKNCA.set.summary(
  name="tmin",
  description="median and range",
  point=business.median,
  spread=business.range
)

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
# Add the column to the interval specification
add.interval.col("tlast",
                 FUN="pk.calc.tlast",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tlast",
                 desc="Time of the last concentration observed above the limit of quantification",
                 depends=NULL,
                 formula="$T_{\\text{last}} = t_{i: C_i > 0, i = \\max}$")
PKNCA.set.summary(
  name="tlast",
  description="median and range",
  point=business.median,
  spread=business.range
)

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
# Add the column to the interval specification
add.interval.col("tfirst",
                 FUN="pk.calc.tfirst",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tfirst",
                 desc="Time of the first concentration above the limit of quantification",
                 depends=NULL,
                 formula="$T_{\\text{first}} = t_{i: C_i > 0, i = \\min}$")
PKNCA.set.summary(
  name="tfirst",
  description="median and range",
  point=business.median,
  spread=business.range
)

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
# Add the column to the interval specification
add.interval.col("clast.obs",
                 FUN="pk.calc.clast.obs",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Clast",
                 desc="The last concentration observed above the limit of quantification",
                 depends=NULL,
                 formula="$C_{\\text{last,obs}} = C_{i: t_i = T_{\\text{last}}}$")
PKNCA.set.summary(
  name="clast.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
# Add the columns to the interval specification
add.interval.col("thalf.eff.obs",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 desc="The effective half-life (as determined from the MRTobs)",
                 unit_type="time",
                 pretty_name="Effective half-life (based on MRT,obs)",
                 formalsmap=list(mrt="mrt.obs"),
                 depends="mrt.obs",
                 formula="$t_{1/2,\\text{eff,obs}} = \\ln(2) \\cdot MRT_{\\text{obs}}$")
PKNCA.set.summary(
  name="thalf.eff.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("thalf.eff.pred",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (based on MRT,pred)",
                 desc="The effective half-life (as determined from the MRTpred)",
                 formalsmap=list(mrt="mrt.pred"),
                 depends="mrt.pred",
                 formula="$t_{1/2,\\text{eff,pred}} = \\ln(2) \\cdot MRT_{\\text{pred}}$")
PKNCA.set.summary(
  name="thalf.eff.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("thalf.eff.last",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (based on MRT,last)",
                 desc="The effective half-life (as determined from the MRTlast)",
                 formalsmap=list(mrt="mrt.last"),
                 depends="mrt.last",
                 formula="$t_{1/2,\\text{eff,last}} = \\ln(2) \\cdot MRT_{\\text{last}}$")
PKNCA.set.summary(
  name="thalf.eff.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("thalf.eff.iv.obs",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (for IV dosing, based on MRT,obs)",
                 desc="The effective half-life (as determined from the intravenous MRTobs)",
                 formalsmap=list(mrt="mrt.iv.obs"),
                 depends="mrt.iv.obs",
                 formula="$t_{1/2,\\text{eff,iv,obs}} = \\ln(2) \\cdot MRT_{\\text{iv,obs}}$")
PKNCA.set.summary(
  name="thalf.eff.iv.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("thalf.eff.iv.pred",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (for IV dosing, based on MRT,pred)",
                 desc="The effective half-life (as determined from the intravenous MRTpred)",
                 formalsmap=list(mrt="mrt.iv.pred"),
                 depends="mrt.iv.pred",
                 formula="$t_{1/2,\\text{eff,iv,pred}} = \\ln(2) \\cdot MRT_{\\text{iv,pred}}$")
PKNCA.set.summary(
  name="thalf.eff.iv.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("thalf.eff.iv.last",
                 FUN="pk.calc.thalf.eff",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Effective half-life (for IV dosing, based on MRTlast)",
                 desc="The effective half-life (as determined from the intravenous MRTlast)",
                 formalsmap=list(mrt="mrt.iv.last"),
                 depends="mrt.iv.last",
                 formula="$t_{1/2,\\text{eff,iv,last}} = \\ln(2) \\cdot MRT_{\\text{iv,last}}$")
PKNCA.set.summary(
  name="thalf.eff.iv.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
    stop("auclast and aucinf must either be a scalar or the same length.")
  }
  ret <- rep(NA_real_, max(c(length(auclast), length(aucinf))))
  mask_na <-
    is.na(auclast) | is.na(aucinf)
  mask_negative <-
    (!mask_na) & ((aucinf <= 0) | (auclast <= 0))
  mask_greater <-
    !mask_na &
    (auclast >= aucinf)
  mask_calc <- !mask_na & !(aucinf %in% 0)
  if (any(mask_greater))
    rlang::warn(
      message = "aucpext is typically only calculated when aucinf is greater than auclast.",
      class = "pknca_aucpext_aucinf_le_auclast"
    )
  if (any(mask_negative))
    rlang::warn(
      message = "aucpext is typically only calculated when both aucinf and auclast are positive.",
      class = "pknca_aucpext_aucinf_auclast_positive"
    )
  ret[mask_calc] <-
    100*(1-auclast[mask_calc]/aucinf[mask_calc])
  ret
}

# Add the columns to the interval specification
add.interval.col("aucpext.obs",
                 FUN="pk.calc.aucpext",
                 values=c(FALSE, TRUE),
                 unit_type="%",
                 pretty_name="AUCpext (based on AUCinf,obs)",
                 desc="Percent of the AUCinf that is extrapolated after Tlast calculated from the observed Clast",
                 formalsmap=list(aucinf="aucinf.obs"),
                 depends=c("auclast", "aucinf.obs"),
                 formula="$\\%AUC_{\\text{ext,obs}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{last}}}{AUC_{\\infty,\\text{obs}}}\\right)$")
PKNCA.set.summary(
  name="aucpext.obs",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)
add.interval.col("aucpext.pred",
                 FUN="pk.calc.aucpext",
                 values=c(FALSE, TRUE),
                 unit_type="%",
                 pretty_name="AUCpext (based on AUCinf,pred)",
                 desc="Percent of the AUCinf that is extrapolated after Tlast calculated from the predicted Clast",
                 formalsmap=list(aucinf="aucinf.pred"),
                 depends=c("auclast", "aucinf.pred"),
                 formula="$\\%AUC_{\\text{ext,pred}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{last}}}{AUC_{\\infty,\\text{pred}}}\\right)$")
PKNCA.set.summary(
  name="aucpext.pred",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)

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
# Add the columns to the interval specification
add.interval.col("kel.obs",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (based on AUCinf,obs)",
                 desc="Elimination rate (as calculated from the MRT with observed Clast)",
                 formalsmap=list(mrt="mrt.obs"),
                 depends="mrt.obs",
                 formula="$k_{el,\\text{obs}} = \\frac{1}{MRT_{\\text{obs}}}$")
PKNCA.set.summary(
  name="kel.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("kel.pred",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (based on AUCinf,pred)",
                 desc="Elimination rate (as calculated from the MRT with predicted Clast)",
                 formalsmap=list(mrt="mrt.pred"),
                 depends="mrt.pred",
                 formula="$k_{el,\\text{pred}} = \\frac{1}{MRT_{\\text{pred}}}$")
PKNCA.set.summary(
  name="kel.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("kel.last",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (based on AUClast)",
                 desc="Elimination rate (as calculated from the MRT using AUClast)",
                 formalsmap=list(mrt="mrt.last"),
                 depends="mrt.last",
                 formula="$k_{el,\\text{last}} = \\frac{1}{MRT_{\\text{last}}}$")
PKNCA.set.summary(
  name="kel.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("kel.iv.obs",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (for IV dosing, based on AUCinf,obs)",
                 desc="Elimination rate (as calculated from the intravenous MRTobs)",
                 formalsmap=list(mrt="mrt.iv.obs"),
                 depends="mrt.iv.obs",
                 formula="$k_{el,\\text{iv,obs}} = \\frac{1}{MRT_{\\text{iv,obs}}}$")
PKNCA.set.summary(
  name="kel.iv.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("kel.iv.pred",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (for IV dosing, based on AUCinf,pred)",
                 desc="Elimination rate (as calculated from the intravenous MRTpred)",
                 formalsmap=list(mrt="mrt.iv.pred"),
                 depends="mrt.iv.pred",
                 formula="$k_{el,\\text{iv,pred}} = \\frac{1}{MRT_{\\text{iv,pred}}}$")
PKNCA.set.summary(
  name="kel.iv.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("kel.iv.last",
                 FUN="pk.calc.kel",
                 values=c(FALSE, TRUE),
                 unit_type="inverse_time",
                 pretty_name="Kel (for IV dosing, based on AUClast)",
                 desc="Elimination rate (as calculated from the intravenous MRTlast)",
                 formalsmap=list(mrt="mrt.iv.last"),
                 depends="mrt.iv.last",
                 formula="$k_{el,\\text{iv,last}} = \\frac{1}{MRT_{\\text{iv,last}}}$")
add.interval.col("kel.all",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCall)",
                 desc = "Elimination rate (as calculated from the MRTall)",
                 formalsmap = list(mrt = "mrt.all"),
                 depends = "mrt.all",
                 formula="$k_{el,\\text{all}} = \\frac{1}{MRT_{\\text{all}}}$")

add.interval.col("kel.int.all",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCint.all)",
                 desc = "Elimination rate (as calculated from the MRTint.all)",
                 formalsmap = list(mrt = "mrt.int.all"),
                 depends = "mrt.int.all",
                 formula="$k_{el,\\text{int,all}} = \\frac{1}{MRT_{\\text{int,all}}}$")

add.interval.col("kel.int.inf.obs",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCint.inf.obs)",
                 desc = "Elimination rate (as calculated from the MRTint.inf.obs)",
                 formalsmap = list(mrt = "mrt.int.inf.obs"),
                 depends = "mrt.int.inf.obs",
                 formula="$k_{el,\\text{int,}\\infty\\text{,obs}} = \\frac{1}{MRT_{\\text{int,}\\infty\\text{,obs}}}$")

add.interval.col("kel.int.inf.pred",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCint.inf.pred)",
                 desc = "Elimination rate (as calculated from the MRTint.inf.pred)",
                 formalsmap = list(mrt = "mrt.int.inf.pred"),
                 depends = "mrt.int.inf.pred",
                 formula="$k_{el,\\text{int,}\\infty\\text{,pred}} = \\frac{1}{MRT_{\\text{int,}\\infty\\text{,pred}}}$")

add.interval.col("kel.int.last",
                 FUN = "pk.calc.kel",
                 values = c(FALSE, TRUE),
                 unit_type = "inverse_time",
                 pretty_name = "Kel (based on AUCint.last)",
                 desc = "Elimination rate (as calculated from the MRTint.last)",
                 formalsmap = list(mrt = "mrt.int.last"),
                 depends = "mrt.int.last",
                 formula="$k_{el,\\text{int,last}} = \\frac{1}{MRT_{\\text{int,last}}}$")


PKNCA.set.summary(
  name = c("kel.all", "kel.int.all", "kel.int.inf.obs", "kel.int.inf.pred",
           "kel.int.last"),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)
PKNCA.set.summary(
  name="kel.iv.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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

# Add the columns to the interval specification
add.interval.col("cl.last",
                 FUN="pk.calc.cl",
                 values=c(FALSE, TRUE),
                 unit_type="clearance",
                 pretty_name="CL (based on AUClast)",
                 desc="Clearance or observed oral clearance calculated to Clast",
                 formalsmap=list(auc="auclast"),
                 depends="auclast",
                 formula="$CL_{\\text{last}} = \\frac{Dose}{AUC_{\\text{last}}}$")
PKNCA.set.summary(
  name="cl.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("cl.all",
                 FUN="pk.calc.cl",
                 values=c(FALSE, TRUE),
                 unit_type="clearance",
                 pretty_name="CL (based on AUCall)",
                 desc="Clearance or observed oral clearance calculated with AUCall",
                 formalsmap=list(auc="aucall"),
                 depends="aucall",
                 formula="$CL_{\\text{all}} = \\frac{Dose}{AUC_{\\text{all}}}$")
PKNCA.set.summary(
  name="cl.all",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("cl.obs",
                 FUN="pk.calc.cl",
                 values=c(FALSE, TRUE),
                 unit_type="clearance",
                 pretty_name="CL (based on AUCinf,obs)",
                 desc="Clearance or observed oral clearance calculated with observed Clast",
                 formalsmap=list(auc="aucinf.obs"),
                 depends="aucinf.obs",
                 formula="$CL_{\\text{obs}} = \\frac{Dose}{AUC_{\\infty,\\text{obs}}}$")
PKNCA.set.summary(
  name="cl.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("cl.pred",
                 FUN="pk.calc.cl",
                 values=c(FALSE, TRUE),
                 unit_type="clearance",
                 pretty_name="CL (based on AUCinf,pred)",
                 desc="Clearance or observed oral clearance calculated with predicted Clast",
                 formalsmap=list(auc="aucinf.pred"),
                 depends="aucinf.pred",
                 formula="$CL_{\\text{pred}} = \\frac{Dose}{AUC_{\\infty,\\text{pred}}}$")

add.interval.col("cl.int.all",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (based on AUCint.all)",
                 desc = "Clearance or observed oral clearance calculated with AUCint.all",
                 formalsmap = list(auc = "aucint.all"),
                 depends = "aucint.all",
                 formula="$CL_{\\text{int,all}} = \\frac{Dose}{AUC_{\\text{int,all}}}$")

add.interval.col("cl.int.inf.obs",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (based on AUCint.inf.obs)",
                 desc = "Clearance or observed oral clearance calculated with AUCint.inf.obs",
                 formalsmap = list(auc = "aucint.inf.obs"),
                 depends = "aucint.inf.obs",
                 formula="$CL_{\\text{int,}\\infty\\text{,obs}} = \\frac{Dose}{AUC_{\\text{int,}\\infty\\text{,obs}}}$")

add.interval.col("cl.int.inf.pred",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (based on AUCint.inf.pred)",
                 desc = "Clearance or observed oral clearance calculated with AUCint.inf.pred",
                 formalsmap = list(auc = "aucint.inf.pred"),
                 depends = "aucint.inf.pred",
                 formula="$CL_{\\text{int,}\\infty\\text{,pred}} = \\frac{Dose}{AUC_{\\text{int,}\\infty\\text{,pred}}}$")

add.interval.col("cl.int.last",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (based on AUCint.last)",
                 desc = "Clearance or observed oral clearance calculated with AUCint.last",
                 formalsmap = list(auc = "aucint.last"),
                 depends = "aucint.last",
                 formula="$CL_{\\text{int,last}} = \\frac{Dose}{AUC_{\\text{int,last}}}$")

add.interval.col("cl.iv.all",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for IV dosing,  based on AUCall)",
                 desc = "Clearance for intravenous dosing calculated with AUCall",
                 formalsmap = list(auc = "aucivall"),
                 depends = "aucivall",
                 formula="$CL_{\\text{iv,all}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,all}}}$")

add.interval.col("cl.iv.last",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for IV dosing,  based on AUClast)",
                 desc = "Clearance for intravenous dosing calculated with AUClast",
                 formalsmap = list(auc = "aucivlast"),
                 depends = "aucivlast",
                 formula="$CL_{\\text{iv,last}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,last}}}$")

add.interval.col("cl.iv.obs",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for IV dosing,  based on AUCinf,obs)",
                 desc = "Clearance for intravenous dosing calculated with AUCinf,obs",
                 formalsmap = list(auc = "aucivinf.obs"),
                 depends = "aucivinf.obs",
                 formula="$CL_{\\text{iv,obs}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,}\\infty\\text{,obs}}}$")

add.interval.col("cl.iv.pred",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for IV dosing,  based on AUCinf,pred)",
                 desc = "Clearance for intravenous dosing calculated with AUCinf,pred",
                 formalsmap = list(auc = "aucivinf.pred"),
                 depends = "aucivinf.pred",
                 formula="$CL_{\\text{iv,pred}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,}\\infty\\text{,pred}}}$")

add.interval.col("cl.ivint.all",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (IV dose interval, based on AUCint.all)",
                 desc = "Clearance for intravenous dosing calculated with interval AUCint.all",
                 formalsmap = list(auc = "aucivint.all"),
                 depends = "aucivint.all",
                 formula="$CL_{\\text{iv,int,all}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,int,all}}}$")

add.interval.col("cl.ivint.last",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (IV dose interval, based on AUCint.last)",
                 desc = "Clearance for intravenous dosing calculated with interval AUCint.last",
                 formalsmap = list(auc = "aucivint.last"),
                 depends = "aucivint.last",
                 formula="$CL_{\\text{iv,int,last}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,int,last}}}$")

add.interval.col("cl.sparse.last",
                 FUN = "pk.calc.cl",
                 values = c(FALSE, TRUE),
                 unit_type = "clearance",
                 pretty_name = "CL (for sparse data, based on AUClast)",
                 desc = "Clearance from sparse sampling calculated with population AUClast",
                 sparse = TRUE,
                 formalsmap = list(auc = "sparse_auclast"),
                 depends = "sparse_auclast",
                 formula="$CL_{\\text{sparse,last}} = \\frac{Dose}{AUC_{\\text{sparse,last}}}$")

PKNCA.set.summary(
  name = c("cl.int.all", "cl.int.inf.obs", "cl.int.inf.pred", "cl.int.last",
           "cl.iv.all", "cl.iv.last", "cl.iv.obs", "cl.iv.pred",
           "cl.ivint.all", "cl.ivint.last", "cl.sparse.last"),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)
PKNCA.set.summary(
  name="cl.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
add.interval.col("f",
                 FUN="pk.calc.f",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Bioavailability",
                 desc="Bioavailability or relative bioavailability",
                 depends=NULL,
                 formula="$F = \\frac{AUC_2 / Dose_2}{AUC_1 / Dose_1}$")
PKNCA.set.summary(
  name="f",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
# Add the columns to the interval specification
add.interval.col("mrt.obs",
                 FUN="pk.calc.mrt",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (based on AUCinf,obs)",
                 desc="The mean residence time to infinity using observed Clast",
                 formalsmap=list(auc="aucinf.obs", aumc="aumcinf.obs"),
                 depends=c("aucinf.obs", "aumcinf.obs"),
                 formula="$MRT_{\\text{obs}} = \\frac{AUMC_{\\infty,\\text{obs}}}{AUC_{\\infty,\\text{obs}}}$")
PKNCA.set.summary(
  name="mrt.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("mrt.pred",
                 FUN="pk.calc.mrt",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (based on AUCinf,pred)",
                 desc="The mean residence time to infinity using predicted Clast",
                 formalsmap=list(auc="aucinf.pred", aumc="aumcinf.pred"),
                 depends=c("aucinf.pred", "aumcinf.pred"),
                 formula="$MRT_{\\text{pred}} = \\frac{AUMC_{\\infty,\\text{pred}}}{AUC_{\\infty,\\text{pred}}}$")
PKNCA.set.summary(
  name="mrt.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("mrt.last",
                 FUN="pk.calc.mrt",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (based on AUClast)",
                 desc="The mean residence time to the last observed concentration above the LOQ",
                 formalsmap=list(auc="auclast", aumc="aumclast"),
                 depends=c("auclast", "aumclast"),
                 formula="$MRT_{\\text{last}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}}$")

add.interval.col("mrt.all",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCall)",
                 desc = "Mean residence time calculated with AUCall/AUMCall",
                 formalsmap = list(auc = "aucall", aumc = "aumcall"),
                 depends = c("aucall", "aumcall"),
                 formula="$MRT_{\\text{all}} = \\frac{AUMC_{\\text{all}}}{AUC_{\\text{all}}}$")

add.interval.col("mrt.int.all",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCint.all)",
                 desc = "Mean residence time over interval calculated with AUCint.all/AUMCint.all",
                 formalsmap = list(auc = "aucint.all", aumc = "aumcint.all"),
                 depends = c("aucint.all", "aumcint.all"),
                 formula="$MRT_{\\text{int,all}} = \\frac{AUMC_{\\text{int,all}}}{AUC_{\\text{int,all}}}$")

add.interval.col("mrt.int.inf.obs",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCint.inf.obs)",
                 desc = "Mean residence time over interval calculated with AUCint.inf.obs/AUMCint.inf.obs",
                 formalsmap = list(auc = "aucint.inf.obs", aumc = "aumcint.inf.obs"),
                 depends = c("aucint.inf.obs", "aumcint.inf.obs"),
                 formula="$MRT_{\\text{int,}\\infty\\text{,obs}} = \\frac{AUMC_{\\text{int,}\\infty\\text{,obs}}}{AUC_{\\text{int,}\\infty\\text{,obs}}}$")

add.interval.col("mrt.int.inf.pred",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCint.inf.pred)",
                 desc = "Mean residence time over interval calculated with AUCint.inf.pred/AUMCint.inf.pred",
                 formalsmap = list(auc = "aucint.inf.pred", aumc = "aumcint.inf.pred"),
                 depends = c("aucint.inf.pred", "aumcint.inf.pred"),
                 formula="$MRT_{\\text{int,}\\infty\\text{,pred}} = \\frac{AUMC_{\\text{int,}\\infty\\text{,pred}}}{AUC_{\\text{int,}\\infty\\text{,pred}}}$")

add.interval.col("mrt.int.last",
                 FUN = "pk.calc.mrt",
                 values = c(FALSE, TRUE),
                 unit_type = "time",
                 pretty_name = "MRT (based on AUCint.last)",
                 desc = "Mean residence time over interval calculated with AUCint.last/AUMCint.last",
                 formalsmap = list(auc = "aucint.last", aumc = "aumcint.last"),
                 depends = c("aucint.last", "aumcint.last"),
                 formula="$MRT_{\\text{int,last}} = \\frac{AUMC_{\\text{int,last}}}{AUC_{\\text{int,last}}}$")

PKNCA.set.summary(
  name = c("mrt.all", "mrt.int.all", "mrt.int.inf.obs", "mrt.int.inf.pred",
           "mrt.int.last"),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)
PKNCA.set.summary(
  name="mrt.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
# Add the columns to the interval specification
add.interval.col("mrt.iv.obs",
                 FUN="pk.calc.mrt.iv",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for IV dosing, based on AUCinf,obs)",
                 desc="The mean residence time to infinity using observed Clast correcting for dosing duration",
                 formalsmap=list(auc="aucinf.obs", aumc="aumcinf.obs"),
                 depends=c("aucinf.obs", "aumcinf.obs"),
                 formula="$MRT_{\\text{iv,obs}} = \\frac{AUMC_{\\infty,\\text{obs}}}{AUC_{\\infty,\\text{obs}}} - \\frac{T_{\\text{inf}}}{2}$")
PKNCA.set.summary(
  name="mrt.iv.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("mrt.iv.pred",
                 FUN="pk.calc.mrt.iv",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for IV dosing, based on AUCinf,pred)",
                 desc="The mean residence time to infinity using predicted Clast correcting for dosing duration",
                 formalsmap=list(auc="aucinf.pred", aumc="aumcinf.pred"),
                 depends=c("aucinf.pred", "aumcinf.pred"),
                 formula="$MRT_{\\text{iv,pred}} = \\frac{AUMC_{\\infty,\\text{pred}}}{AUC_{\\infty,\\text{pred}}} - \\frac{T_{\\text{inf}}}{2}$")
PKNCA.set.summary(
  name="mrt.iv.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("mrt.iv.last",
                 FUN="pk.calc.mrt.iv",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for IV dosing, based on AUClast)",
                 desc="The mean residence time to the last observed concentration above the LOQ correcting for dosing duration",
                 formalsmap=list(auc="auclast", aumc="aumclast"),
                 depends=c("auclast", "aumclast"),
                 formula="$MRT_{\\text{iv,last}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} - \\frac{T_{\\text{inf}}}{2}$")
PKNCA.set.summary(
  name="mrt.iv.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

#' @describeIn pk.calc.mrt MRT for multiple-dose data with nonlinear kinetics
#'
#' @details mrt.md is `aumctau/auctau + tau*(aucinf-auctau)/auctau` and should
#'   only be used for multiple dosing with equal intervals between doses.
#'   Note that if `aucinf == auctau` (as would be the assumption with
#'   linear kinetics), the equation becomes the same as the single-dose MRT.
#'
#' @param auctau the AUC from time 0 to the end of the dosing interval (tau).
#' @param aumctau the AUMC from time 0 to the end of the dosing interval (tau).
#' @param aucinf the AUC from time 0 to infinity (typically using single-dose
#'   data)
#' @inheritParams assert_dosetau
#' @export
pk.calc.mrt.md <- function(auctau, aumctau, aucinf, tau) {
  ret <- aumctau/auctau + tau*(aucinf-auctau)/auctau
  mask_zero <- is.na(auctau) | auctau <= 0
  if (any(mask_zero)) {
    ret[mask_zero] <- NA_real_
  }
  ret
}
add.interval.col("mrt.md.obs",
                 FUN="pk.calc.mrt.md",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for multiple dosing, based on AUCinf,obs)",
                 desc="The mean residence time with multiple dosing and nonlinear kinetics using observed Clast",
                 formalsmap=list(auctau="auclast", aumctau="aumclast", aucinf="aucinf.obs"),
                 depends=c("auclast", "aumclast", "aucinf.obs"),
                 formula="$MRT_{\\text{md,obs}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{obs}} - AUC_{\\text{last}}}{AUC_{\\text{last}}}$")
PKNCA.set.summary(
  name="mrt.md.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("mrt.md.pred",
                 FUN="pk.calc.mrt.md",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="MRT (for multiple dosing, based on AUCinf,pred)",
                 desc="The mean residence time with multiple dosing and nonlinear kinetics using predicted Clast",
                 formalsmap=list(auctau="auclast", aumctau="aumclast", aucinf="aucinf.pred"),
                 depends=c("auclast", "aumclast", "aucinf.pred"),
                 formula="$MRT_{\\text{md,pred}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{pred}} - AUC_{\\text{last}}}{AUC_{\\text{last}}}$")
PKNCA.set.summary(
  name="mrt.md.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
    stop("'cl' and 'lambda.z' must be the same length")
  cl/lambda.z
}
# Add the columns to the interval specification
add.interval.col("vz.obs",
                 FUN="pk.calc.vz",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vz (based on AUCinf,obs)",
                 desc="The terminal volume of distribution using observed Clast",
                 formalsmap=list(cl="cl.obs"),
                 depends=c("cl.obs", "lambda.z"),
                 formula="$V_{z,\\text{obs}} = \\frac{CL_{\\text{obs}}}{\\lambda_z}$")
PKNCA.set.summary(
  name="vz.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("vz.pred",
                 FUN="pk.calc.vz",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vz (based on AUCinf,pred)",
                 desc="The terminal volume of distribution using predicted Clast",
                 formalsmap=list(cl="cl.pred"),
                 depends=c("cl.pred", "lambda.z"),
                 formula="$V_{z,\\text{pred}} = \\frac{CL_{\\text{pred}}}{\\lambda_z}$")

add.interval.col("vz.all",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCall)",
                 desc = "Terminal volume of distribution calculated with AUCall-based CL",
                 formalsmap = list(cl = "cl.all"),
                 depends = c("cl.all", "lambda.z"),
                 formula="$V_{z,\\text{all}} = \\frac{CL_{\\text{all}}}{\\lambda_z}$")

add.interval.col("vz.int.all",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCint.all)",
                 desc = "Terminal volume of distribution using interval AUCint.all",
                 formalsmap = list(cl = "cl.int.all"),
                 depends = c("cl.int.all", "lambda.z"),
                 formula="$V_{z,\\text{int,all}} = \\frac{CL_{\\text{int,all}}}{\\lambda_z}$")

add.interval.col("vz.int.inf.obs",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCint.inf.obs)",
                 desc = "Terminal volume of distribution using interval AUCint.inf.obs",
                 formalsmap = list(cl = "cl.int.inf.obs"),
                 depends = c("cl.int.inf.obs", "lambda.z"),
                 formula="$V_{z,\\text{int,}\\infty\\text{,obs}} = \\frac{CL_{\\text{int,}\\infty\\text{,obs}}}{\\lambda_z}$")

add.interval.col("vz.int.inf.pred",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCint.inf.pred)",
                 desc = "Terminal volume of distribution using interval AUCint.inf.pred",
                 formalsmap = list(cl = "cl.int.inf.pred"),
                 depends = c("cl.int.inf.pred", "lambda.z"),
                 formula="$V_{z,\\text{int,}\\infty\\text{,pred}} = \\frac{CL_{\\text{int,}\\infty\\text{,pred}}}{\\lambda_z}$")

add.interval.col("vz.int.last",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUCint.last)",
                 desc = "Terminal volume of distribution using interval AUCint.last",
                 formalsmap = list(cl = "cl.int.last"),
                 depends = c("cl.int.last", "lambda.z"),
                 formula="$V_{z,\\text{int,last}} = \\frac{CL_{\\text{int,last}}}{\\lambda_z}$")

add.interval.col("vz.iv.all",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (for IV dosing,  based on AUCall)",
                 desc = "Terminal volume of distribution for IV dosing using AUCall",
                 formalsmap = list(cl = "cl.iv.all"),
                 depends = c("cl.iv.all", "lambda.z"),
                 formula="$V_{z,\\text{iv,all}} = \\frac{CL_{\\text{iv,all}}}{\\lambda_z}$")

add.interval.col("vz.iv.last",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (for IV dosing,  based on AUClast)",
                 desc = "Terminal volume of distribution for IV dosing using AUClast",
                 formalsmap = list(cl = "cl.iv.last"),
                 depends = c("cl.iv.last", "lambda.z"),
                 formula="$V_{z,\\text{iv,last}} = \\frac{CL_{\\text{iv,last}}}{\\lambda_z}$")

add.interval.col("vz.iv.obs",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (for IV dosing,  based on AUCinf,obs)",
                 desc = "Terminal volume of distribution for IV dosing using observed AUCinf",
                 formalsmap = list(cl = "cl.iv.obs"),
                 depends = c("cl.iv.obs", "lambda.z"),
                 formula="$V_{z,\\text{iv,obs}} = \\frac{CL_{\\text{iv,obs}}}{\\lambda_z}$")

add.interval.col("vz.iv.pred",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (for IV dosing,  based on AUCinf,pred)",
                 desc = "Terminal volume of distribution for IV dosing using predicted AUCinf",
                 formalsmap = list(cl = "cl.iv.pred"),
                 depends = c("cl.iv.pred", "lambda.z"),
                 formula="$V_{z,\\text{iv,pred}} = \\frac{CL_{\\text{iv,pred}}}{\\lambda_z}$")

add.interval.col("vz.ivint.all",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (IV dose interval, based on AUCint.all)",
                 desc = "Terminal volume of distribution for IV interval using AUCint.all",
                 formalsmap = list(cl = "cl.ivint.all"),
                 depends = c("cl.ivint.all", "lambda.z"),
                 formula="$V_{z,\\text{iv,int,all}} = \\frac{CL_{\\text{iv,int,all}}}{\\lambda_z}$")

add.interval.col("vz.ivint.last",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (IV dose interval, based on AUCint.last)",
                 desc = "Terminal volume of distribution for IV interval using AUCint.last",
                 formalsmap = list(cl = "cl.ivint.last"),
                 depends = c("cl.ivint.last", "lambda.z"),
                 formula="$V_{z,\\text{iv,int,last}} = \\frac{CL_{\\text{iv,int,last}}}{\\lambda_z}$")

add.interval.col("vz.last",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (based on AUClast)",
                 desc = "Terminal volume of distribution calculated with AUClast-based CL",
                 formalsmap = list(cl = "cl.last"),
                 depends = c("cl.last", "lambda.z"),
                 formula="$V_{z,\\text{last}} = \\frac{CL_{\\text{last}}}{\\lambda_z}$")

add.interval.col("vz.sparse.last",
                 FUN = "pk.calc.vz",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vz (for sparse data, based on AUClast)",
                 desc = "Terminal volume of distribution from sparse sampling",
                 sparse = TRUE,
                 formalsmap = list(cl = "cl.sparse.last"),
                 depends = c("cl.sparse.last", "lambda.z"),
                 formula="$V_{z,\\text{sparse,last}} = \\frac{CL_{\\text{sparse,last}}}{\\lambda_z}$")

PKNCA.set.summary(
  name = c("vz.all", "vz.int.all", "vz.int.inf.obs", "vz.int.inf.pred",
           "vz.int.last", "vz.iv.all", "vz.iv.last", "vz.iv.obs",
           "vz.iv.pred", "vz.ivint.all", "vz.ivint.last", "vz.last",
           "vz.sparse.last"),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)
PKNCA.set.summary(
  name="vz.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

#' @describeIn pk.calc.vz Steady-state volume of distribution (Vss)
#'
#' @details vss is `cl*mrt`.
#' @param mrt the mean residence time
#' @return the volume of distribution at steady-state
#' @export
pk.calc.vss <- function(cl, mrt) {
  cl*mrt
}
# Add the columns to the interval specification
add.interval.col("vss.obs",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (based on AUCinf,obs)",
                 desc="The steady-state volume of distribution using observed Clast",
                 formalsmap=list(cl="cl.obs", mrt="mrt.obs"),
                 depends=c("cl.obs", "mrt.obs"),
                 formula="$V_{ss,\\text{obs}} = CL_{\\text{obs}} \\cdot MRT_{\\text{obs}}$")
PKNCA.set.summary(
  name="vss.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

add.interval.col("vss.pred",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (based on AUCinf,pred)",
                 desc="The steady-state volume of distribution using predicted Clast",
                 formalsmap=list(cl="cl.pred", mrt="mrt.pred"),
                 depends=c("cl.pred", "mrt.pred"),
                 formula="$V_{ss,\\text{pred}} = CL_{\\text{pred}} \\cdot MRT_{\\text{pred}}$")
PKNCA.set.summary(
  name="vss.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("vss.last",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (based on AUClast)",
                 desc="The steady-state volume of distribution calculating through Tlast",
                 formalsmap=list(cl="cl.last", mrt="mrt.last"),
                 depends=c("cl.last", "mrt.last"),
                 formula="$V_{ss,\\text{last}} = CL_{\\text{last}} \\cdot MRT_{\\text{last}}$")
PKNCA.set.summary(
  name="vss.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("vss.iv.obs",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for IV dosing, based on AUCinf,obs)",
                 desc="The steady-state volume of distribution with intravenous infusion using observed Clast",
                 formalsmap=list(cl="cl.obs", mrt="mrt.iv.obs"),
                 depends=c("cl.obs", "mrt.iv.obs"),
                 formula="$V_{ss,\\text{iv,obs}} = CL_{\\text{obs}} \\cdot MRT_{\\text{iv,obs}}$")
PKNCA.set.summary(
  name="vss.iv.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("vss.iv.pred",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for IV dosing, based on AUCinf,pred)",
                 desc="The steady-state volume of distribution with intravenous infusion using predicted Clast",
                 formalsmap=list(cl="cl.pred", mrt="mrt.iv.pred"),
                 depends=c("cl.pred", "mrt.iv.pred"),
                 formula="$V_{ss,\\text{iv,pred}} = CL_{\\text{pred}} \\cdot MRT_{\\text{iv,pred}}$")
PKNCA.set.summary(
  name="vss.iv.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("vss.iv.last",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for IV dosing, based on AUClast)",
                 desc="The steady-state volume of distribution with intravenous infusion calculating through Tlast",
                 formalsmap=list(cl="cl.last", mrt="mrt.iv.last"),
                 depends=c("cl.last", "mrt.iv.last"),
                 formula="$V_{ss,\\text{iv,last}} = CL_{\\text{last}} \\cdot MRT_{\\text{iv,last}}$")
PKNCA.set.summary(
  name="vss.iv.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("vss.md.obs",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for multiple-dose, based on Clast,obs)",
                 desc="The steady-state volume of distribution for nonlinear multiple-dose data using observed Clast",
                 formalsmap=list(cl="cl.last", mrt="mrt.md.obs"),
                 depends=c("cl.last", "mrt.md.obs"),
                 formula="$V_{ss,\\text{md,obs}} = CL_{\\text{last}} \\cdot MRT_{\\text{md,obs}}$")
PKNCA.set.summary(
  name="vss.md.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("vss.md.pred",
                 FUN="pk.calc.vss",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Vss (for multiple-dose, based on Clast,pred)",
                 desc="The steady-state volume of distribution for nonlinear multiple-dose data using predicted Clast",
                 formalsmap=list(cl="cl.last", mrt="mrt.md.pred"),
                 depends=c("cl.last", "mrt.md.pred"),
                 formula="$V_{ss,\\text{md,pred}} = CL_{\\text{last}} \\cdot MRT_{\\text{md,pred}}$")

add.interval.col("vss.all",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCall)",
                 desc = "Steady-state volume of distribution calculated with AUCall-based CL and MRT",
                 formalsmap = list(cl = "cl.all", mrt = "mrt.all"),
                 depends = c("cl.all", "mrt.all"),
                 formula="$V_{ss,\\text{all}} = CL_{\\text{all}} \\cdot MRT_{\\text{all}}$")

add.interval.col("vss.int.all",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCint.all)",
                 desc = "Steady-state volume of distribution using interval AUCint.all",
                 formalsmap = list(cl = "cl.int.all", mrt = "mrt.int.all"),
                 depends = c("cl.int.all", "mrt.int.all"),
                 formula="$V_{ss,\\text{int,all}} = CL_{\\text{int,all}} \\cdot MRT_{\\text{int,all}}$")

add.interval.col("vss.int.inf.obs",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCint.inf.obs)",
                 desc = "Steady-state volume of distribution using interval AUCint.inf.obs",
                 formalsmap = list(cl = "cl.int.inf.obs", mrt = "mrt.int.inf.obs"),
                 depends = c("cl.int.inf.obs", "mrt.int.inf.obs"),
                 formula="$V_{ss,\\text{int,}\\infty\\text{,obs}} = CL_{\\text{int,}\\infty\\text{,obs}} \\cdot MRT_{\\text{int,}\\infty\\text{,obs}}$")

add.interval.col("vss.int.inf.pred",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCint.inf.pred)",
                 desc = "Steady-state volume of distribution using interval AUCint.inf.pred",
                 formalsmap = list(cl = "cl.int.inf.pred", mrt = "mrt.int.inf.pred"),
                 depends = c("cl.int.inf.pred", "mrt.int.inf.pred"),
                 formula="$V_{ss,\\text{int,}\\infty\\text{,pred}} = CL_{\\text{int,}\\infty\\text{,pred}} \\cdot MRT_{\\text{int,}\\infty\\text{,pred}}$")

add.interval.col("vss.int.last",
                 FUN = "pk.calc.vss",
                 values = c(FALSE, TRUE),
                 unit_type = "volume",
                 pretty_name = "Vss (based on AUCint.last)",
                 desc = "Steady-state volume of distribution using interval AUCint.last",
                 formalsmap = list(cl = "cl.int.last", mrt = "mrt.int.last"),
                 depends = c("cl.int.last", "mrt.int.last"),
                 formula="$V_{ss,\\text{int,last}} = CL_{\\text{int,last}} \\cdot MRT_{\\text{int,last}}$")

PKNCA.set.summary(
  name = c("vss.all", "vss.int.all", "vss.int.inf.obs", "vss.int.inf.pred",
           "vss.int.last"),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)
PKNCA.set.summary(
  name="vss.md.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
add.interval.col(
  "cav",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "The average concentration during an interval (calculated with AUClast)",
  depends = "auclast",
  formalsmap = list(auc = "auclast"),
  formula = "$C_{av} = \\frac{AUC_{\\text{last}}}{t_{end} - t_{start}}$"
)
add.interval.col(
  "cav.int.last",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "The average concentration during an interval (calculated with AUCint.last)",
  depends = "aucint.last",
  formalsmap = list(auc = "aucint.last"),
  formula = "$C_{av,\\text{int,last}} = \\frac{AUC_{\\text{int,last}}}{t_{end} - t_{start}}$"
)
add.interval.col(
  "cav.int.all",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "The average concentration during an interval (calculated with AUCint.all)",
  depends = "aucint.all",
  formalsmap = list(auc = "aucint.all"),
  formula = "$C_{av,\\text{int,all}} = \\frac{AUC_{\\text{int,all}}}{t_{end} - t_{start}}$"
)
add.interval.col(
  "cav.int.inf.obs",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "The average concentration during an interval (calculated with AUCint.inf.obs)",
  depends = "aucint.inf.obs",
  formalsmap = list(auc = "aucint.inf.obs"),
  formula = "$C_{av,\\text{int,}\\infty\\text{,obs}} = \\frac{AUC_{\\text{int,}\\infty\\text{,obs}}}{t_{end} - t_{start}}$"
)
add.interval.col(
  "cav.int.inf.pred",
  FUN = "pk.calc.cav",
  values = c(FALSE, TRUE),
  unit_type = "conc",
  pretty_name = "Cav",
  desc = "The average concentration during an interval (calculated with AUCint.inf.pred)",
  depends = "aucint.inf.pred",
  formalsmap = list(auc = "aucint.inf.pred"),
  formula = "$C_{av,\\text{int,}\\infty\\text{,pred}} = \\frac{AUC_{\\text{int,}\\infty\\text{,pred}}}{t_{end} - t_{start}}$"
)

PKNCA.set.summary(
  name = c("cav", "cav.int.last", "cav.int.all", "cav.int.inf.obs", "cav.int.inf.pred"),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)

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
    stop("More than one time matches the starting time.  Please report this as a bug with a reproducible example.") # nocov
  }
}
add.interval.col("ctrough",
                 FUN="pk.calc.ctrough",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Ctrough",
                 desc="The trough (end of interval) concentration",
                 depends=NULL,
                 formula="$C_{\\text{trough}} = C(t_{\\text{end}})$")
PKNCA.set.summary(
  name="ctrough",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
    stop("More than one time matches the starting time.  Please report this as a bug with a reproducible example.") # nocov
  }
}
add.interval.col("cstart",
                 FUN="pk.calc.cstart",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Cstart",
                 desc="The predose concentration",
                 depends=NULL,
                 formula="$C_{\\text{start}} = C(t_{\\text{start}})$")
PKNCA.set.summary(
  name="cstart",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
add.interval.col("ptr",
                 FUN="pk.calc.ptr",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Peak-to-trough ratio",
                 desc="Peak-to-Trough ratio (fraction)",
                 depends=c("cmax", "ctrough"),
                 formula="$PTR = \\frac{C_{\\max}}{C_{\\text{trough}}}$")
PKNCA.set.summary(
  name="ptr",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
add.interval.col("tlag",
                 FUN="pk.calc.tlag",
                 values=c(FALSE, TRUE),
                 unit_type="time",
                 pretty_name="Tlag",
                 desc="Lag time",
                 depends=NULL,
                 formula="$T_{\\text{lag}} = t_{i: C_{i+1} > C_i, i = \\min}$")
PKNCA.set.summary(
  name="tlag",
  description="median and range",
  point=business.median,
  spread=business.range
)

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
add.interval.col("deg.fluc",
                 FUN="pk.calc.deg.fluc",
                 unit_type="%",
                 pretty_name="Degree of fluctuation",
                 desc="Degree of fluctuation",
                 depends=c("cmax", "cmin", "cav"),
                 formula="$DF = 100 \\cdot \\frac{C_{\\max} - C_{\\min}}{C_{av}}$")
PKNCA.set.summary(
  name="deg.fluc",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)

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
add.interval.col("swing",
                 FUN="pk.calc.swing",
                 unit_type="%",
                 pretty_name="Swing",
                 desc="Swing relative to Cmin",
                 depends=c("cmax", "cmin"),
                 formula="$Swing = 100 \\cdot \\frac{C_{\\max} - C_{\\min}}{C_{\\min}}$")
PKNCA.set.summary(
  name="swing",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd
)

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
add.interval.col("ceoi",
                 FUN="pk.calc.ceoi",
                 unit_type="conc",
                 pretty_name="Ceoi",
                 desc="Concentration at the end of infusion",
                 depends=NULL,
                 formula="$C_{\\text{eoi}} = C(t = T_{\\text{inf}})$")
PKNCA.set.summary(
  name="ceoi",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

#' Calculate the AUC above a given concentration
#'
#' Concentrations below the given concentration (`conc_above`) will be set
#' to zero.
#' @inheritParams pk.calc.time_above
#' @returns The AUC of the concentration above the limit
#' @export
pk.calc.aucabove <- function(conc, time, conc_above = NA_real_, ..., options=list()) {
  stopifnot(length(conc_above) == 1)
  stopifnot(is.numeric(conc_above))
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
add.interval.col(
  "aucabove.predose.all",
  FUN="pk.calc.aucabove",
  unit_type="auc",
  pretty_name="AUC,above",
  desc="The area under the concentration time the beginning of the interval to the last concentration above the limit of quantification plus the triangle from that last concentration to 0 at the first concentration below the limit of quantification, with a concentration subtracted from all concentrations and values below zero after subtraction set to zero",
  depends="cstart",
  formalsmap = list(conc_above = "cstart"),
  formula="$AUC_{\\text{above}} = \\int \\max(C(t) - C_{\\text{ref}},\\; 0)\\; dt$"
)
PKNCA.set.summary(
  name="aucabove.predose.all",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col(
  "aucabove.trough.all",
  FUN="pk.calc.aucabove",
  unit_type="auc",
  pretty_name="AUC,above",
  desc="The area under the concentration time the beginning of the interval to the last concentration above the limit of quantification plus the triangle from that last concentration to 0 at the first concentration below the limit of quantification, with a concentration subtracted from all concentrations and values below zero after subtraction set to zero",
  depends="ctrough",
  formalsmap = list(conc_above = "ctrough"),
  formula="$AUC_{\\text{above}} = \\int \\max(C(t) - C_{\\text{ref}},\\; 0)\\; dt$"
)
PKNCA.set.summary(
  name="aucabove.trough.all",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

#' Count the number of concentration measurements in an interval
#'
#' `count_conc` and `count_conc_measured` are typically used for quality control
#' on the data to ensure that there are a sufficient number of non-missing
#' samples for a calculation and to ensure that data are consistent between
#' individuals.
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
# Add the column to the interval specification
add.interval.col(
  "count_conc",
  FUN = "pk.calc.count_conc",
  values = c(FALSE, TRUE),
  unit_type = "count",
  pretty_name = "Concentration count",
  desc = "Number of non-missing concentrations for an interval",
  depends = NULL,
  formula = "$n = \\sum_{i} \\mathbf{1}(C_i \\neq NA)$"
)

#' @describeIn pk.calc.count_conc Count the number of concentration measurements
#'   that are not missing, above, or below the limit of quantification in an
#'   interval
#'
#' @returns a count of the non-missing, measured (not below or above the limit
#'   of quantification) concentrations (0 if all concentrations are missing)
#' @export
pk.calc.count_conc_measured <- function(conc, check=TRUE) {
  if (check) {
    assert_conc(conc)
  }
  sum(!is.na(conc) & is.finite(conc) & conc > 0)
}
# Add the column to the interval specification
add.interval.col(
  "count_conc_measured",
  FUN="pk.calc.count_conc_measured",
  values=c(FALSE, TRUE),
  unit_type="count",
  pretty_name="Measured concentration count",
  desc="Number of measured and non BLQ/ALQ concentrations for an interval",
  depends=NULL,
  formula="$n = \\sum_{i} \\mathbf{1}(C_i > 0)$"
)
PKNCA.set.summary(
  name=c("count_conc", "count_conc_measured"),
  description="median and range",
  point=business.median,
  spread=business.range
)

#' Extract the dose used for calculations
#'
#' @inheritParams pk.calc.cl
#' @returns The total dose for an interval
#' @export
pk.calc.totdose <- function(dose) {
  sum(dose)
}
add.interval.col(
  "totdose",
  FUN="pk.calc.totdose",
  values=c(FALSE, TRUE),
  unit_type="dose",
  pretty_name="Total dose",
  desc="Total dose administered during an interval",
  formula="$Dose_{\\text{total}} = \\sum_i Dose_i$"
)
PKNCA.set.summary(
  name="totdose",
  description="median and range",
  point=business.median,
  spread=business.range
)
