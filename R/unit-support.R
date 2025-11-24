#' Create a unit assignment and conversion table
#'
#' This data.frame is typically used for the `units` argument for [PKNCAdata()].
#' If a unit is not given, then all of the units derived from that unit will be
#' `NA`.
#'
#' @param concu,doseu,amountu,timeu Units for concentration, dose, amount, and
#'   time in the source data
#' @param concu_pref,doseu_pref,amountu_pref,timeu_pref Preferred units for
#'   reporting; `conversions` will be automatically.
#' @param conversions An optional data.frame with columns of c("PPORRESU",
#'   "PPSTRESU", "conversion_factor") for the original calculation units, the
#'   standardized units, and a conversion factor to multiply the initial value
#'   by to get a standardized value.  This argument overrides any preferred unit
#'   conversions from `concu_pref`, `doseu_pref`, `amountu_pref`, or
#'   `timeu_pref`.
#' @param ... Additional arguments (not used)
#' @returns A unit conversion table with columns for "PPTESTCD" and "PPORRESU"
#'   if `conversions` is not given, and adding "PPSTRESU" and
#'   "conversion_factor" if `conversions` is given.
#' @seealso The `units` argument for [PKNCAdata()]
#' @examples
#' pknca_units_table() # only parameters that are unitless
#' pknca_units_table(
#'   concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr"
#' )
#' pknca_units_table(
#'   concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr",
#'   # Convert clearance and volume units to more understandable units with
#'   # automatic unit conversion
#'   conversions=data.frame(
#'     PPORRESU=c("(mg/kg)/(hr*ng/mL)", "(mg/kg)/(ng/mL)"),
#'     PPSTRESU=c("mL/hr/kg", "mL/kg")
#'   )
#' )
#' pknca_units_table(
#'   concu="mg/L", doseu="mg/kg", amountu="mg", timeu="hr",
#'   # Convert clearance and volume units to molar units (assuming
#'   conversions=data.frame(
#'     PPORRESU=c("mg/L", "(mg/kg)/(hr*ng/mL)", "(mg/kg)/(ng/mL)"),
#'     PPSTRESU=c("mmol/L", "mL/hr/kg", "mL/kg"),
#'     # Manual conversion of concentration units from ng/mL to mmol/L (assuming
#'     # a molecular weight of 138.121 g/mol)
#'     conversion_factor=c(1/138.121, NA, NA)
#'   )
#' )
#'
#' # This will make all time-related parameters use "day" even though the
#' # original units are "hr"
#' pknca_units_table(
#'   concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
#'   timeu_pref = "day"
#' )
#'
#' @export
pknca_units_table <- function(concu, ...) {
  UseMethod("pknca_units_table")
}

##' Default method for pknca_units_table
#'
#' @rdname pknca_units_table
#' @export
pknca_units_table.default <- function(concu, doseu, amountu, timeu,
                              concu_pref = NULL, doseu_pref = NULL, amountu_pref = NULL, timeu_pref = NULL,
                              conversions = data.frame(), ...) {
  checkmate::assert_data_frame(conversions)
  if (nrow(conversions) > 0) {
    checkmate::assert_names(
      names(conversions),
      subset.of = c("PPORRESU", "PPSTRESU", "conversion_factor"),
      must.include = c("PPORRESU", "PPSTRESU")
    )
    if (!("conversion_factor" %in% names(conversions))) {
      conversions$conversion_factor <- NA_real_
    }
  }

  # The unit conversions are grouped by the type of inputs required
  ret <-
    rbind(
      pknca_units_table_unitless(),
      pknca_units_table_time(timeu=timeu),
      pknca_units_table_conc(concu=concu),
      pknca_units_table_amount(amountu=amountu),
      pknca_units_table_amount_dose(amountu = amountu, doseu = doseu),
      pknca_units_table_dose(doseu = doseu),
      pknca_units_table_conc_dose(concu=concu, doseu=doseu),
      pknca_units_table_conc_time(concu=concu, timeu=timeu),
      pknca_units_table_conc_time_dose(concu=concu, timeu=timeu, doseu=doseu),
      pknca_units_table_conc_time_amount(concu=concu, timeu=timeu, amountu=amountu)
    )

  # Generate preferred units and merge them into `conversions`
  if (any(!is.null(concu_pref), !is.null(doseu_pref), !is.null(amountu_pref), !is.null(timeu_pref))) {
    ret_pref <-
      pknca_units_table(
        concu = choose_first(concu_pref, concu),
        doseu = choose_first(doseu_pref, doseu),
        amountu = choose_first(amountu_pref, amountu),
        timeu = choose_first(timeu_pref, timeu)
      )
    ret_pref <- dplyr::rename(ret_pref, PPSTRESU = "PPORRESU")
    conversions_pref <- dplyr::left_join(ret, ret_pref, by = "PPTESTCD")
    conversions_pref$PPTESTCD <- NULL
    conversions_pref <- unique(conversions_pref)
    # Drop units that are not converted
    conversions_pref <- conversions_pref[conversions_pref$PPORRESU != conversions_pref$PPSTRESU, ]
    # Drop units that are not provided
    conversions_pref <- conversions_pref[!is.na(conversions_pref$PPORRESU), ]
    conversions_pref$conversion_factor <- NA_real_
    for (idx in seq_len(nrow(conversions))) {
      # Use the original conversions argument over `conversions_pref`
      mask_pref <- conversions_pref$PPORRESU %in% conversions$PPORRESU[idx]
      if (!any(mask_pref)) {
        stop("Cannot find PPORRESU match between conversions and preferred unit conversions.  Check PPORRESU values in 'conversions' argument.")
      }
      conversions_pref$PPSTRESU[mask_pref] <- conversions$PPSTRESU[idx]
      conversions_pref$conversion_factor[mask_pref] <- conversions$conversion_factor[idx]
    }
    conversions <- conversions_pref
  }

  extra_cols <- setdiff(ret$PPTESTCD, names(get.interval.cols()))
  if (length(extra_cols) > 0) {
    stop("Please report a bug.  Unknown NCA parameters have units defined: ", paste(extra_cols, collapse=", ")) # nocov
  }

  # Apply conversion factors
  if (nrow(conversions) > 0) {
    stopifnot(!duplicated(conversions$PPORRESU))
    # PPSTRESU may be duplicated because some differing original units may
    # converge (e.g. cmax.dn and vss)
    stopifnot(length(setdiff(names(conversions), c("PPORRESU", "PPSTRESU", "conversion_factor"))) == 0)
    if (any(is.na(conversions$conversion_factor)) && !requireNamespace("units", quietly=TRUE)) {
      stop("The units package is required for automatic unit conversion") # nocov
    }
    for (idx in which(is.na(conversions$conversion_factor))) {
      conversions$conversion_factor[idx] <-
        as.numeric(
          units::set_units(
            units::set_units(
              1,
              conversions$PPORRESU[idx], mode="standard"
            ),
            conversions$PPSTRESU[idx], mode="standard"
          )
        )
    }
    unexpected_conversions <- setdiff(conversions$PPORRESU, ret$PPORRESU)
    if (length(unexpected_conversions) > 0) {
      warning(
        "The following unit conversions were supplied but do not match any units to convert: ",
        paste0("'", unexpected_conversions, "'", collapse=", ")
      )
    }
    ret <-
      dplyr::left_join(
        ret, conversions,
        by=intersect(names(ret), names(conversions))
      )
    # anything that does not have a specific conversion factor is assumed to be
    # in the correct units, and a unit conversion factor is used to keep the
    # units the same.
    ret$PPSTRESU[is.na(ret$PPSTRESU)] <- ret$PPORRESU[is.na(ret$PPSTRESU)]
    ret$conversion_factor[is.na(ret$conversion_factor)] <- 1
  }
  ret
}

##' Method for PKNCAdata objects
#'
#' @rdname pknca_units_table
#' @importFrom dplyr across any_of bind_rows case_when filter group_by mutate n select ungroup group_vars
#' @importFrom tidyr fill unnest
#' @importFrom rlang syms
#' @export
pknca_units_table.PKNCAdata <- function(concu, ..., conversions = data.frame()) {

  # concu is the PKNCAdata object
  o_conc <- as_PKNCAconc(concu)
  o_dose <- as_PKNCAdose(concu)

  # PKNCAdose can optionally be no present, being unit undefining
  if (is.null(o_dose) || all(is.na(o_dose))) o_dose <- o_conc

  # If needed, ensure that the PKNCA objects have the required unit columns
  o_conc <- ensure_column_unit_exists(o_conc, c("concu", "timeu", "amountu"))
  o_dose <- ensure_column_unit_exists(o_dose, c("doseu"))

  # Extract relevant columns from o_conc and o_dose
  group_dose_cols <- dplyr::group_vars(o_dose)
  group_conc_cols <- dplyr::group_vars(o_conc)
  concu_col <- o_conc$columns$concu
  amountu_col <- o_conc$columns$amountu
  timeu_col <- o_conc$columns$timeu
  doseu_col <- o_dose$columns$doseu
  all_unit_cols <- c(concu_col, amountu_col, timeu_col, doseu_col)

  # Join dose units with concentration group columns and units
  d_concu <- o_conc$data %>%
    dplyr::select(dplyr::any_of(c(group_conc_cols, concu_col, amountu_col, timeu_col))) %>%
    unique()
  d_doseu <- o_dose$data %>%
    dplyr::select(dplyr::any_of(c(group_dose_cols, doseu_col))) %>%
    unique()

  groups_units_tbl <- merge(d_concu, d_doseu, all.x = TRUE) %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), ~ as.character(.))) %>%
    dplyr::group_by(!!!rlang::syms(group_conc_cols)) %>%
    tidyr::fill(!!!rlang::syms(all_unit_cols), .direction = "downup") %>%
    dplyr::ungroup() %>%
    unique()

  # Check that at least for each concentration group units are uniform
  mismatching_units_groups <- groups_units_tbl %>%
    dplyr::add_count(!!!rlang::syms(group_conc_cols), name = "n") %>%
    dplyr::filter(n > 1) %>%
    dplyr::select(-n)
  if (nrow(mismatching_units_groups) > 0) {
    stop(
      "Units should be uniform at least across concentration groups. ",
      "Review the units for the next group(s):\n",
      paste(utils::capture.output(print(mismatching_units_groups)), collapse = "\n")
    )
  }

  # Check that at least one unit column is not NA
  units.are.all.na <- all(is.na(groups_units_tbl[,all_unit_cols]))
  if (units.are.all.na) return(NULL)

  groups_units_tbl %>%
    select_minimal_grouping_cols(all_unit_cols) %>%
    unique() %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      pknca_units_tbl = list(
        pknca_units_table(
          concu = !!rlang::sym(concu_col),
          doseu = !!rlang::sym(doseu_col),
          amountu = !!rlang::sym(amountu_col),
          timeu = !!rlang::sym(timeu_col),
          concu_pref = o_conc$units$concu_pref[1],
          doseu_pref = o_dose$units$doseu_pref[1],
          amountu_pref = o_conc$units$amountu_pref[1],
          timeu_pref = o_conc$units$timeu_pref[1],
          conversions = conversions
        )
      )
    ) %>%
    tidyr::unnest(cols = c(pknca_units_tbl)) %>%
    dplyr::select(-dplyr::any_of(all_unit_cols)) %>%
    as.data.frame()
}

pknca_units_table_unitless <- function() {
  rbind(
    data.frame(
      PPORRESU="unitless",
      PPTESTCD=pknca_find_units_param(unit_type="unitless"),
      stringsAsFactors=FALSE
    ),
    data.frame(
      PPORRESU="fraction",
      PPTESTCD=pknca_find_units_param(unit_type="fraction"),
      stringsAsFactors=FALSE
    ),
    data.frame(
      PPORRESU="%",
      PPTESTCD=pknca_find_units_param(unit_type="%"),
      stringsAsFactors=FALSE
    ),
    data.frame(
      PPORRESU="count",
      PPTESTCD=pknca_find_units_param(unit_type="count"),
      stringsAsFactors=FALSE
    )
  )
}

choose_first <- function(x, y, .default = NA) {
  if (!useless(x)) {
    x
  } else if (!useless(y)) {
    y
  } else {
    .default
  }
}

useless <- function(x) {
  if (missing(x)) {
    return(TRUE)
  } else if (length(x) > 1) {
    stop("Only one unit may be provided at a time: ", paste(x, collapse = ", "))
  }
  is.null(x) || is.na(x)
}

pknca_units_table_time <- function(timeu) {
  if (useless(timeu)) {
    timeu <- NA_character_
  }
  inverse_timeu <-
    if (is.na(timeu)) {
      NA_character_
    } else {
      sprintf("1/%s", pknca_units_add_paren(timeu))
    }
  rbind(
    data.frame(
      PPORRESU=timeu,
      PPTESTCD=pknca_find_units_param(unit_type="time"),
      stringsAsFactors=FALSE
    ),
    data.frame(
      PPORRESU=inverse_timeu,
      PPTESTCD=pknca_find_units_param(unit_type="inverse_time"),
      stringsAsFactors=FALSE
    )
  )
}

pknca_units_table_conc <- function(concu) {
  if (useless(concu)) {
    concu <- NA_character_
  }
  data.frame(
    PPORRESU=concu,
    PPTESTCD=pknca_find_units_param(unit_type="conc"),
    stringsAsFactors=FALSE
  )
}

pknca_units_table_amount <- function(amountu) {
  if (useless(amountu)) {
    amountu <- NA_character_
  }
  data.frame(
    PPORRESU=amountu,
    PPTESTCD=pknca_find_units_param(unit_type="amount"),
    stringsAsFactors=FALSE
  )
}

pknca_units_table_amount_dose <- function(amountu, doseu) {
  if (useless(amountu) || useless(doseu)) {
    amount_doseu <- NA_character_
  } else {
    amount_doseu <- sprintf("%s/%s", pknca_units_add_paren(amountu), pknca_units_add_paren(doseu))
  }
  data.frame(
    PPORRESU=amount_doseu,
    PPTESTCD=pknca_find_units_param(unit_type="amount_dose"),
    stringsAsFactors=FALSE
  )
}

pknca_units_table_dose <- function(doseu) {
  if (useless(doseu)) {
    doseu <- NA_character_
  }
  data.frame(
    PPORRESU=doseu,
    PPTESTCD=pknca_find_units_param(unit_type="dose"),
    stringsAsFactors=FALSE
  )
}

pknca_units_table_conc_dose <- function(concu, doseu) {
  if (useless(concu) || useless(doseu)) {
    conc_dosenorm <- NA_character_
    volume <- NA_character_
  } else {
    conc_dosenorm <- sprintf("%s/%s", pknca_units_add_paren(concu), pknca_units_add_paren(doseu))
    volume <- sprintf("%s/%s", pknca_units_add_paren(doseu), pknca_units_add_paren(concu))
  }
  rbind(
    data.frame(
      PPORRESU=conc_dosenorm,
      PPTESTCD=pknca_find_units_param(unit_type="conc_dosenorm"),
      stringsAsFactors=FALSE
    ),
    data.frame(
      # Volume units
      PPORRESU=volume,
      PPTESTCD=pknca_find_units_param(unit_type="volume"),
      stringsAsFactors=FALSE
    )
  )
}

pknca_units_table_conc_time <- function(concu, timeu) {
  if (useless(concu) || useless(timeu)) {
    auc <- NA_character_
    aumc <- NA_character_
  } else {
    auc <- sprintf("%s*%s", timeu, concu)
    aumc <- sprintf("%s^2*%s", pknca_units_add_paren(timeu), concu)
  }
  rbind(
    data.frame(
      # AUC units
      PPORRESU=auc,
      PPTESTCD=pknca_find_units_param(unit_type="auc"),
      stringsAsFactors=FALSE
    ),
    data.frame(
      # AUMC units
      PPORRESU=aumc,
      PPTESTCD=pknca_find_units_param(unit_type="aumc"),
      stringsAsFactors=FALSE
    )
  )
}

pknca_units_table_conc_time_dose <- function(concu, timeu, doseu) {
  if (useless(concu) || useless(timeu) || useless(doseu)) {
    auc_dosenorm <-
      aumc_dosenorm <-
      clearance <-
      NA_character_
  } else {
    auc_dosenorm <- sprintf("(%s*%s)/%s", timeu, concu, pknca_units_add_paren(doseu))
    aumc_dosenorm <- sprintf("(%s^2*%s)/%s", pknca_units_add_paren(timeu), concu, pknca_units_add_paren(doseu))
    clearance <- sprintf("%s/(%s*%s)", pknca_units_add_paren(doseu), timeu, concu)
  }
  rbind(
    data.frame(
      # AUC units, dose-normalized
      PPORRESU=auc_dosenorm,
      PPTESTCD=pknca_find_units_param(unit_type="auc_dosenorm"),
      stringsAsFactors=FALSE
    ),
    data.frame(
      # AUMC units, dose-normalized
      PPORRESU=aumc_dosenorm,
      PPTESTCD=pknca_find_units_param(unit_type="aumc_dosenorm"),
      stringsAsFactors=FALSE
    ),
    data.frame(
      # Clearance units
      PPORRESU=clearance,
      PPTESTCD=pknca_find_units_param(unit_type="clearance"),
      stringsAsFactors=FALSE
    )
  )
}

pknca_units_table_conc_time_amount <- function(concu, timeu, amountu) {
  if (useless(concu) || useless(timeu) || useless(amountu)) {
    renal_clearance <- NA_character_
  } else {
    renal_clearance <- sprintf("%s/(%s*%s)", pknca_units_add_paren(amountu), timeu, concu)
  }
  data.frame(
    # Renal clearance units
    PPORRESU=renal_clearance,
    PPTESTCD=pknca_find_units_param(unit_type="renal_clearance"),
    stringsAsFactors=FALSE
  )
}

#' Find NCA parameters with a given unit type
#'
#' @param unit_type The type of unit as assigned with `add.interval.col`
#' @returns A character vector of parameters with a given unit type
#' @keywords Internal
pknca_find_units_param <- function(unit_type) {
  stopifnot(length(unit_type) == 1)
  stopifnot(is.character(unit_type))
  all_intervals <- get.interval.cols()
  ret <- character()
  for (nm in names(all_intervals)) {
    if (all_intervals[[nm]]$unit_type == unit_type) {
      ret <- c(ret, nm)
    }
  }
  if (length(ret) == 0) {
    stop("No parameters found for unit_type=", unit_type)
  }
  ret
}

#' Add parentheses to a unit value, if needed
#'
#' @param unit The text of the unit
#' @returns The unit with parentheses around it, if needed
#' @keywords Internal
pknca_units_add_paren <- function(unit) {
  mask_paren <- grepl(x=unit, pattern="[*/]")
  ifelse(mask_paren, yes=paste0("(", unit, ")"), no=unit)
}

#' Perform unit conversion (if possible) on PKNCA results
#'
#' @param result The results data.frame
#' @param units The unit conversion table
#' @param allow_partial_missing_units Should missing units be allowed for some
#'   but not all parameters?
#' @returns The result table with units converted
#' @keywords Internal
pknca_unit_conversion <- function(result, units, allow_partial_missing_units = FALSE) {
  ret <- result
  if (!is.null(units)) {
    ret <-
      dplyr::left_join(
        ret, units,
        by=intersect(names(ret), names(units))
      )
    mask_missing_units <- is.na(ret$PPORRESU)
    if (any(mask_missing_units)) {
      msg_missing <-
        paste(
          "Units are provided for some but not all parameters; missing for:",
          paste(sort(unique(ret$PPTESTCD[mask_missing_units])), collapse = ", ")
        )
      if (allow_partial_missing_units) {
        warning(msg_missing)
      } else {
        stop(msg_missing, "\nThis error can be converted to a warning using `PKNCA.options(allow_partial_missing_units = TRUE)`")
      }
    }
    if ("conversion_factor" %in% names(units)) {
      ret$PPSTRES <- ret$PPORRES * ret$conversion_factor
      # Drop the conversion factor column, since it shouldn't be in the output.
      ret <- ret[, setdiff(names(ret), "conversion_factor")]
    }
  }
  ret
}


#' Ensure Unit Columns Exist in PKNCA Object
#'
#' Checks if specified unit columns exist in a PKNCA object (either PKNCAconc or PKNCAdose).
#' If the columns do not exist, it creates them and assigns default values (NA or existing units).
#'
#' @param pknca_obj A PKNCA object (either PKNCAconc or PKNCAdose).
#' @param unit_name A character vector of unit column names to ensure (concu, amountu, timeu...).
#' @returns The updated PKNCA object with ensured unit columns.
#'
#' @details
#' The function performs the following steps:
#' 1. Checks if the specified unit columns exist in the PKNCA object.
#' 2. If a column does not exist, it creates the column and assigns default values.
#' 3. If not default values are provided, it assigns NA to the new column.
#' @keywords Internal
ensure_column_unit_exists <- function(pknca_obj, unit_name) {
  for (unit in unit_name) {
    if (is.null(pknca_obj$columns[[unit]])) {
      unit_colname <- make.unique(c(names(pknca_obj$data), unit))[ncol(pknca_obj$data) + 1]
      pknca_obj$columns[[unit]] <- unit_colname
      if (!is.null(pknca_obj$units[[unit]])) {
        pknca_obj$data[[unit_colname]] <- pknca_obj$units[[unit]]
      } else {
        pknca_obj$data[[unit_colname]] <- NA_character_
      }
    }
  }
  pknca_obj
}

#' Find Minimal Grouping Columns for Strata Reconstruction
#'
#' This function identifies the smallest set of columns in a data frame whose unique combinations
#' can reconstruct the grouping structure defined by the specified strata columns.
#' It removes duplicate, constant, and redundant columns, then searches for the minimal combination
#' that uniquely identifies each stratum.
#'
#' @param df A data frame.
#' @param strata_cols Column names in df whose unique combination defines the strata.
#' @returns A data frame containing the strata columns and their minimal set of grouping columns.
#' @importFrom dplyr mutate select any_of
#' @importFrom rlang syms
#' @importFrom utils combn
#' @keywords Internal
select_minimal_grouping_cols <- function(df, strata_cols) {
  # If there is no strata_cols specified, simply return the original df
  if (length(strata_cols) == 0) return(df)

  # Obtain the comb_vals values of the target column(s)
  strata_vals <- df %>%
    mutate(strata_cols_comb = paste(!!!rlang::syms(strata_cols), sep = "_")) %>%
    .[["strata_cols_comb"]]
  
  # If the target column(s) only has one level, there are no relevant columns
  if (length(unique(strata_vals)) == 1) {
    return(df[strata_cols])
  }

  candidate_cols <- setdiff(names(df), strata_cols)
  # 1. Remove columns that are duplicates in levels terms
  candidate_levels <- lapply(
    df[candidate_cols], function(x) as.numeric(factor(x, levels = unique(x)))
  )
  candidate_cols <- candidate_cols[!duplicated(candidate_levels)]

  # 2. Remove columns with only 1 level
  candidate_n_levels <- sapply(df[candidate_cols], function(x) length(unique(x)))
  candidate_cols <- candidate_cols[candidate_n_levels > 1]

  # 3. Check combinations of columns to find minimal key combination to level group strata_cols
  for (n in seq_len(length(candidate_cols))) {
    all_candidate_combs <- combn(candidate_cols, n, simplify = FALSE)
    for (comb in all_candidate_combs) {
      comb_vals <- apply(df[, comb, drop = FALSE], 1, paste, collapse = "_")
      if (all(tapply(strata_vals, comb_vals, FUN = \(x) length(unique(x)) == 1))) {
        return(df[c(comb, strata_cols)])
      }
    }
  }
  df[strata_cols]
}

# Add globalVariables for NSE/dplyr/rlang/tidyr usage
utils::globalVariables(c(
  "group_vars", "select", "any_of", "across", "everything", "add_count", "syms", "rowwise", "unnest", "pull",
  "n", "pknca_units_tbl", "PPORRESU", "PPTESTCD", "PPSTRESU", "conversion_factor", "strata_cols_comb"
))
