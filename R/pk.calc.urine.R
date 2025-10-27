#' Calculate amount excreted (typically in urine or feces)
#'
#' @details ae is `sum(conc*volume)`.
#'
#' @inheritParams assert_conc_time
#' @param volume The volume (or mass) of the sample
#' @param check Should the concentration and volume data be checked?
#' @return The amount excreted during the interval
#' @details The units for the concentration and volume should match such that
#'   `sum(conc*volume)` has units of mass or moles.
#' @seealso [pk.calc.clr()], [pk.calc.fe()]
#' @export
pk.calc.ae <- function(conc, volume, check=TRUE) {
  mask_missing_conc <- is.na(conc)
  mask_missing_vol <- is.na(volume)
  mask_missing_both <- mask_missing_conc & mask_missing_vol
  mask_missing_conc <- mask_missing_conc & !mask_missing_both
  mask_missing_vol <- mask_missing_vol & !mask_missing_both
  message_both <- message_conc <- message_vol <- NA_character_
  if (all(mask_missing_both)) {
    message_both <- "All concentrations and volumes are missing"
  } else if (any(mask_missing_both)) {
    message_both <- sprintf("%g of %g concentrations and volumes are missing", sum(mask_missing_both), length(conc))
  }
  if (all(mask_missing_conc)) {
    message_conc <- "All concentrations are missing"
  } else if (any(mask_missing_conc)) {
    message_conc <- sprintf("%g of %g concentrations are missing", sum(mask_missing_conc), length(conc))
  }
  if (all(mask_missing_vol)) {
    message_vol <- "All volumes are missing"
  } else if (any(mask_missing_vol)) {
    message_vol <- sprintf("%g of %g volumes are missing", sum(mask_missing_vol), length(conc))
  }
  message_all <- stats::na.omit(c(message_both, message_conc, message_vol))
  ret <- sum(conc*volume)
  if (length(message_all) != 0) {
    message <- paste(message_all, collapse = "; ")
    ret <- structure(ret, exclude = message)
  }
  ret
}
add.interval.col("ae",
                 FUN="pk.calc.ae",
                 values=c(FALSE, TRUE),
                 unit_type="amount",
                 pretty_name="Amount excreted",
                 desc="The amount excreted (typically into urine or feces)")
PKNCA.set.summary(
  name="ae",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

#' Calculate renal clearance
#'
#' @details clr is `sum(ae)/auc`.
#'
#' @param ae The amount excreted in urine (as a numeric scalar or vector)
#' @param auc The area under the curve (as a numeric scalar or vector)
#' @returns The renal clearance as a number
#' @details The units for the `ae` and `auc` should match such that `ae/auc` has
#'   units of volume/time.
#' @seealso [pk.calc.ae()], [pk.calc.fe()]
#' @export
pk.calc.clr <- function(ae, auc) {
  sum(ae)/auc
}
add.interval.col("clr.last",
                 FUN="pk.calc.clr",
                 values=c(FALSE, TRUE),
                 unit_type="renal_clearance",
                 pretty_name="Renal clearance (from AUClast)",
                 formalsmap=list(auc="auclast"),
                 desc="The renal clearance calculated using AUClast")
PKNCA.set.summary(
  name="clr.last",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("clr.obs",
                 FUN="pk.calc.clr",
                 values=c(FALSE, TRUE),
                 unit_type="renal_clearance",
                 pretty_name="Renal clearance (from AUCinf,obs)",
                 formalsmap=list(auc="aucinf.obs"),
                 desc="The renal clearance calculated using AUCinf,obs")
PKNCA.set.summary(
  name="clr.obs",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)
add.interval.col("clr.pred",
                 FUN="pk.calc.clr",
                 values=c(FALSE, TRUE),
                 unit_type="renal_clearance",
                 pretty_name="Renal clearance (from AUCinf,pred)",
                 formalsmap=list(auc="aucinf.pred"),
                 desc="The renal clearance calculated using AUCinf,pred")
PKNCA.set.summary(
  name="clr.pred",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

#' Calculate fraction excreted (typically in urine or feces)
#'
#' @details fe is `sum(ae)/dose`
#'
#' @param ae The amount excreted (as a numeric scalar or vector)
#' @param dose The dose (as a numeric scalar or vector)
#' @returns The fraction of dose excreted
#' @details   The units for `ae` and `dose` should be the same so that `ae/dose`
#'   is a unitless fraction.
#' @seealso [pk.calc.ae()], [pk.calc.clr()]
#' @export
pk.calc.fe <- function(ae, dose) {
  sum(ae)/dose
}
add.interval.col("fe",
                 FUN="pk.calc.fe",
                 unit_type="amount_dose",
                 pretty_name="Fraction excreted",
                 values=c(FALSE, TRUE),
                 desc="The fraction of the dose excreted")
PKNCA.set.summary(
  name="fe",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

#' Calculate the midpoint collection time of the last measurable excretion rate
#'
#' @param conc The concentration in the excreta (e.g., urine or feces)
#' @param volume The volume (or mass) of the sample
#' @param time The starting time of the collection interval
#' @param duration.conc The duration of the collection interval
#' @param check Should the concentration and time data be checked?
#' @return The midpoint collection time of the last measurable excretion rate, or NA/0 if not available
#' @export
pk.calc.ertlst <- function(conc, volume, time, duration.conc, check = TRUE) {
  if (check) {
    assert_conc_time(conc = conc, time = time)
  }
  if (all(is.na(conc))) {
    NA_real_
  } else if (all(conc %in% c(0, NA))) {
    0
  } else {
    er <- conc * volume / duration.conc
    midtime <- time + duration.conc / 2
    max(midtime[!(conc %in% c(NA, 0))])
  }
}

# Add the column to the interval specification
add.interval.col("ertlst",
                 FUN="pk.calc.ertlst",
                 unit_type="time",
                 pretty_name="Tlast excretion rate",
                 desc="The midpoint collection time of the last measurable excretion rate (typically in urine or feces)")

PKNCA.set.summary(
  name="ertlst",
  description="median and range",
  point=business.median,
  spread=business.range
)

#' Calculate the maximum excretion rate
#'
#' @param conc The concentration in the excreta (e.g., urine or feces)
#' @param volume The volume (or mass) of the sample
#' @param time The starting time of the collection interval
#' @param duration.conc The duration of the collection interval
#' @param check Should the concentration data be checked?
#' @return The maximum excretion rate, or NA if not available
#' @export
pk.calc.ermax <- function(conc, volume, time, duration.conc, check = TRUE) {
  if (check) {
    assert_conc(conc = conc)
  }
  if (length(conc) == 0 | all(is.na(conc))) {
    NA
  } else {
    er <- conc * volume / duration.conc
    max(er, na.rm=TRUE)
  }
}

add.interval.col("ermax",
                 FUN="pk.calc.ermax",
                 unit_type="amount_time",
                 pretty_name="Maximum excretion rate",
                 desc="The maximum excretion rate (typically in urine or feces)")

PKNCA.set.summary(
  name="ermax",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

#' Calculate the midpoint collection time of the maximum excretion rate
#'
#' @param conc The concentration in the excreta (e.g., urine or feces)
#' @param volume The volume (or mass) of the sample
#' @param time The starting time of the collection interval
#' @param duration.conc The duration of the collection interval
#' @param check Should the concentration and time data be checked?
#' @param first.tmax If TRUE, return the first time of maximum excretion rate; otherwise, return the last
#' @return The midpoint collection time of the maximum excretion rate, or NA if not available
#' @export
pk.calc.ertmax <- function(conc, volume, time, duration.conc, check = TRUE, first.tmax = NULL) {

  if (check) {
    assert_conc_time(conc = conc, time = time)
  }

  if (length(conc) == 0 | all(conc %in% c(NA, 0))) {
    NA
  } else {
    er <- conc * volume / duration.conc
    ermax <- pk.calc.ermax(conc, volume, time, duration.conc, check = FALSE)
    midtime <- time + duration.conc / 2
    ret <- midtime[er %in% ermax]

    if (first.tmax) {
      ret[1]
    } else {
      ret[length(ret)]
    }
  }
}

add.interval.col("ertmax",
                 FUN="pk.calc.ertmax",
                 unit_type="time",
                 pretty_name="Tmax excretion rate",
                 desc="The midpoint collection time of the maximum excretion rate (typically in urine or feces)")

PKNCA.set.summary(
  name="ertmax",
  description="median and range",
  point=business.median,
  spread=business.range
)
