#' Calculate the total urine volume
#'
#' @param volume The volume (or mass) of the sample
#' @return The sum of urine volumes for the interval
#' @export
pk.calc.volpk <- function(volume) {
  if (length(volume) == 0) return(NA_real_)
  sum(volume)
}
add.interval.col("volpk",
                 FUN="pk.calc.volpk",
                 values=c(FALSE, TRUE),
                 unit_type="volume",
                 pretty_name="Total Urine Volume",
                 desc="The sum of urine volumes for the interval")
PKNCA.set.summary(
  name="volpk",
  description="geometric mean and geometric coefficient of variation",
  point=business.geomean,
  spread=business.geocv
)

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
  # Generate combined missing-data messages for conc/volume using helper
  message_all <- generate_missing_messages(conc, volume,
                                           name_a = "concentrations",
                                           name_b = "volumes")

  ret <- sum(conc * volume)
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
                 depends = c("ae", "auclast"),
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
                 depends = c("ae", "aucinf.obs"),
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
                 depends = c("ae", "aucinf.pred"),
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
                 depends = "ae",
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

  # Generate messages about missing concentrations/volumes
  message_all <- generate_missing_messages(conc, volume,
                                           name_a = "concentrations",
                                           name_b = "volumes")

  if (all(is.na(conc))) {
    ret <- NA_real_
  } else if (all(conc %in% c(0, NA))) {
    ret <- 0
  } else {
      midtime <- time + duration.conc / 2
    midtime <- time + duration.conc / 2
    ret <- max(midtime[!(conc %in% c(NA, 0))])
  }

  if (length(message_all) != 0) {
    message <- paste(message_all, collapse = "; ")
    ret <- structure(ret, exclude = message)
  }
  ret
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

  # Generate messages about missing concentrations/volumes
  message_all <- generate_missing_messages(conc, volume,
                                           name_a = "concentrations",
                                           name_b = "volumes")

  if (length(conc) == 0 || all(is.na(conc))) {
    ret <- NA
  } else {
    er <- conc * volume / duration.conc
    ret <- max(er, na.rm=TRUE)
  }

  if (length(message_all) != 0) {
    message <- paste(message_all, collapse = "; ")
    ret <- structure(ret, exclude = message)
  }
  ret
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

  # Generate messages about missing concentrations/volumes
  message_all <- generate_missing_messages(conc, volume,
                                           name_a = "concentrations",
                                           name_b = "volumes")

  if (length(conc) == 0 || all(conc %in% c(NA, 0))) {
    ret <- NA
  } else {
    er <- conc * volume / duration.conc
    ermax <- pk.calc.ermax(conc, volume, time, duration.conc, check = FALSE)
    midtime <- time + duration.conc / 2
    ret <- midtime[er %in% ermax]

    if (first.tmax) {
      ret <- ret[1]
    } else {
      ret <- ret[length(ret)]
    }
  }

  if (length(message_all) != 0) {
    message <- paste(message_all, collapse = "; ")
    ret <- structure(ret, exclude = message)
  }
  ret
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



# Helper to generate missing-data checking messages for paired vectors
#
# This function accepts two columns/vectors (for example, concentrations
# and volumes). It computes missingness internally and produces a character
# vector of human-readable messages describing the missingness that matches
# the style used in the package (used previously in `pk.calc.ae`).
generate_missing_messages <- function(a, b,
                    name_a = deparse(substitute(a)),
                    name_b = deparse(substitute(b))) {

  mask_a <- is.na(a)
  mask_b <- is.na(b)
  
  mask_both <- mask_a & mask_b
  mask_a_only <- mask_a & !mask_both
  mask_b_only <- mask_b & !mask_both
  
  msg_both <- msg_a <- msg_b <- NA_character_
  n <- length(mask_a)
  
  if (all(mask_both)) {
    msg_both <- sprintf("All %s and %s are missing", name_a, name_b)
  } else if (any(mask_both)) {
    msg_both <- sprintf("%g of %g %s and %s are missing", sum(mask_both), n, name_a, name_b)
  }
  
  if (all(mask_a_only)) {
    msg_a <- sprintf("All %s are missing", name_a)
  } else if (any(mask_a_only)) {
    msg_a <- sprintf("%g of %g %s are missing", sum(mask_a_only), n, name_a)
  }
  
  if (all(mask_b_only)) {
    msg_b <- sprintf("All %s are missing", name_b)
  } else if (any(mask_b_only)) {
    msg_b <- sprintf("%g of %g %s are missing", sum(mask_b_only), n, name_b)
  }
  
  # Return non-NA messages
  stats::na.omit(c(msg_both, msg_a, msg_b))
}
