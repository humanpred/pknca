#' Parse ISO 8601 date-time strings with mixed precision
#'
#' Handles full datetime, datetime without seconds, datetime with hour only,
#' and date-only formats. Returns POSIXct in UTC.
#'
#' @param dtc Character vector of ISO 8601 date-time strings
#' @return POSIXct vector in UTC
#' @keywords internal
std_dtc_to_rdate <- function(dtc) {
  formats <- c(
    "%Y-%m-%dT%H:%M:%S",
    "%Y-%m-%dT%H:%M",
    "%Y-%m-%dT%H",
    "%Y-%m-%d"
  )
  dtc_to_dt <- list()
  for (fmt in formats) {
    dtc_to_dt[[fmt]] <- as.POSIXct(dtc, format = fmt, tz = "UTC")
  }
  dplyr::coalesce(
    dtc_to_dt[[formats[1]]], dtc_to_dt[[formats[2]]],
    dtc_to_dt[[formats[3]]], dtc_to_dt[[formats[4]]]
  )
}

#' Parse an ISO 8601 duration string to numeric hours
#'
#' Supports durations in the form \code{PT<number>H}, \code{PT<number>M},
#' \code{PT<number>S}, or combinations like \code{PT1H30M}. Also handles
#' negative durations (e.g. \code{PT-0.5H}). Returns the total duration in
#' hours as a numeric value.
#'
#' @param x Character vector of ISO 8601 duration strings (e.g. \code{"PT2H"},
#'   \code{"PT1H30M"}, \code{"PT90M"})
#' @return Numeric vector of durations in hours
#' @keywords internal
parse_iso8601_duration <- function(x) {
  vapply(x, function(val) {
    if (is.na(val) || !grepl("^PT", val)) return(NA_real_)
    hours <- 0
    h_match <- regmatches(val, regexpr("-?[0-9.]+(?=H)", val, perl = TRUE))
    if (length(h_match) == 1) hours <- hours + as.numeric(h_match)
    m_match <- regmatches(val, regexpr("-?[0-9.]+(?=M)", val, perl = TRUE))
    if (length(m_match) == 1) hours <- hours + as.numeric(m_match) / 60
    s_match <- regmatches(val, regexpr("-?[0-9.]+(?=S)", val, perl = TRUE))
    if (length(s_match) == 1) hours <- hours + as.numeric(s_match) / 3600
    hours
  }, numeric(1), USE.NAMES = FALSE)
}

#' Map CDISC route of administration to PKNCA route
#'
#' @param route Character vector of CDISC route values
#' @return Character vector of \code{"intravascular"} or
#'   \code{"extravascular"}
#' @keywords internal
route_cdisc_to_pknca <- function(route) {
  intravascular_pattern <- paste0(
    "(INFUS|DRIP|IV|INTRAVEN|IVADMIN|BOLUS|INTRAVASCULAR|INTRA-?ARTERIAL|",
    "INTRACARDIAC|INTRACORONARY)"
  )
  ifelse(
    grepl(intravascular_pattern, gsub("[^[:alnum:]]", "", toupper(route))),
    "intravascular",
    "extravascular"
  )
}

# --- EX to PKNCAdose ---------------------------------------------------------

#' Convert an EX (Exposure) SDTM domain to a PKNCAdose object
#'
#' Transforms a CDISC SDTM EX domain data frame into a \code{PKNCAdose} object
#' suitable for NCA analysis with PKNCA. Handles date-time parsing, duration
#' derivation, elapsed time derivation, route mapping, and relative time
#' computation.
#'
#' @section NFRLT derivation:
#' When \code{EXRFTDTC} and \code{EXELTM} are available, the function derives
#' \code{NFRLT} (nominal time from reference) for each dose record:
#' \enumerate{
#'   \item \code{EXELTM} is parsed from ISO 8601 duration to numeric hours
#'     (if character), or used as-is (if already numeric).
#'   \item Per dose grouping (e.g. \code{EXTRT + USUBJID}):
#'     \code{nominal_ref = min(EXRFTDTC)}
#'   \item \code{NFRLT = (EXRFTDTC + EXELTM) - nominal_ref} (in hours)
#' }
#' \code{NFRLT} is used as \code{time.nominal} in the PKNCAdose object.
#' If \code{EXRFTDTC} or \code{EXELTM} are not available, \code{NFRLT} is
#' not derived and \code{time.nominal} is omitted.
#'
#' @param ex A data.frame containing the EX (Exposure) SDTM domain
#' @param USUBJID Column name for the unique subject identifier
#' @param EXTRT Column name for the treatment name
#' @param EXSTDTC Column name for the start date/time of treatment (ISO 8601)
#' @param EXDUR Column name for the duration of treatment. If the column is
#'   absent, it is derived from \code{EXSTDTC} and \code{EXENDTC}.
#' @param EXENDTC Column name for the end date/time of treatment (ISO 8601).
#'   Used to derive \code{EXDUR} when not available.
#' @param EXELTM Column name for the planned elapsed time since first dose.
#'   Can be numeric (hours) or ISO 8601 duration (e.g. \code{"PT2H"}).
#'   If absent, derived from \code{EXSTDTC} and \code{EXRFTDTC}.
#' @param EXTPTNUM Column name for the planned time point number
#' @param EXRFTDTC Column name for the reference date/time (ISO 8601).
#'   Used to derive \code{EXELTM} when not available, and to compute
#'   \code{NFRLT}.
#' @param EXDOSE Column name for the dose per administration
#' @param EXDOSU Column name for the dose units
#' @param EXROUTE Column name for the route of administration
#' @return A \code{PKNCAdose} object
#' @importFrom dplyr mutate group_by ungroup coalesce
#' @importFrom rlang sym
#' @export
ex_to_PKNCAdose <- function(
  ex,
  USUBJID = "USUBJID",
  EXTRT = "EXTRT",

  # Time variables to determine dose
  EXSTDTC = "EXSTDTC",
  EXDUR = "EXDUR",
  # In case EXDUR is not derived
  EXENDTC = "EXENDTC",

  # Nominal time variables
  EXELTM = "EXELTM",
  # In case EXELTM is not derived
  EXTPTNUM = "EXTPTNUM",
  EXRFTDTC = "EXRFTDTC",

  EXDOSE = "EXDOSE",
  EXDOSU = "EXDOSU",
  EXROUTE = "EXROUTE"
) {

  # Grouping variables for the dose formula
  group_vars <- c(EXTRT, USUBJID)

  ex2 <- ex %>%

    # Standardise all dates to R date-time format
    mutate(
      !!sym(EXSTDTC) := if (!!EXSTDTC %in% names(ex)) {
        std_dtc_to_rdate(!!sym(EXSTDTC))
      } else {
        as.POSIXct(NA)
      },
      !!sym(EXENDTC) := if (!!EXENDTC %in% names(ex)) {
        std_dtc_to_rdate(!!sym(EXENDTC))
      } else {
        as.POSIXct(NA)
      },
      !!sym(EXRFTDTC) := if (!!EXRFTDTC %in% names(ex)) {
        std_dtc_to_rdate(!!sym(EXRFTDTC))
      } else {
        NULL
      }
    ) %>%
    # Derive EXDUR if missing
    mutate(
      !!sym(EXDUR) := if (!!EXDUR %in% names(ex)) {
        !!sym(EXDUR)
      } else {
        dur <- as.numeric(difftime(
          !!sym(EXENDTC),
          !!sym(EXSTDTC),
          units = "hours"
        ))
        # When EXENDTC is NA (e.g. oral/instantaneous doses), duration defaults to 0
        ifelse(is.na(dur), 0, dur)
      }
    ) %>%
    # Derive EXELTM if missing; parse ISO 8601 duration if character
    mutate(
      !!sym(EXELTM) := if (!!EXELTM %in% names(ex)) {
        eltm <- !!sym(EXELTM)
        if (is.character(eltm)) parse_iso8601_duration(eltm) else eltm
      } else if (!!EXRFTDTC %in% names(ex)) {
        as.numeric(difftime(
          !!sym(EXSTDTC),
          !!sym(EXRFTDTC),
          units = "hours"
        ))
      } else {
        NULL
      }
    ) %>%
    # Determine for each subject the reference (first) dose date-time
    group_by(!!sym(USUBJID)) %>%
    mutate(
      EX_reference = min(!!sym(EXSTDTC), na.rm = TRUE)
    ) %>%
    ungroup() %>%
    # Determine dose time in hours from reference
    mutate(
      AFRLT = as.numeric(difftime(
        !!sym(EXSTDTC),
        EX_reference,
        units = "hours"
      ))
    )

  # Derive NFRLT from EXRFTDTC + EXELTM when both are available
  has_nfrlt <- EXRFTDTC %in% names(ex2) && EXELTM %in% names(ex2)
  if (has_nfrlt) {
    ex2 <- ex2 %>%
      group_by(!!!syms(group_vars)) %>%
      mutate(
        NFRLT = as.numeric(difftime(
          !!sym(EXRFTDTC) + !!sym(EXELTM) * 3600,
          min(!!sym(EXRFTDTC), na.rm = TRUE),
          units = "hours"
        ))
      ) %>%
      ungroup()
  }

  PKNCAdose_args <- list(
    data = ex2,
    formula = as.formula(
      paste(EXDOSE, "~", "AFRLT", "|", paste(group_vars, collapse = "+"))
    ),
    route = if (EXROUTE %in% names(ex)) route_cdisc_to_pknca(ex2[[EXROUTE]]) else NULL,
    time.nominal = if (has_nfrlt) "NFRLT" else NULL,
    duration = if (EXDUR %in% names(ex2)) EXDUR else NULL,
    doseu = if (EXDOSU %in% names(ex2)) EXDOSU else NULL
  )
  # Remove NULL entries
  PKNCAdose_args <- PKNCAdose_args[!sapply(PKNCAdose_args, is.null)]
  do.call(PKNCA::PKNCAdose, PKNCAdose_args)
}

