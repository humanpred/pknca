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
#' @section Secondary parameters and reference groups:
#'
#'   A secondary parameter (renal clearance, bioavailability, a ratio; see
#'   `vignette("v09-secondary-parameters")`) takes one value from the interval
#'   requesting it and another from a reference interval, so its units are a
#'   quotient of the two groups' units.  When the `PKNCAdata` method finds more
#'   than one set of units among the groups, the table therefore gains a
#'   `<group column>_ref` column for each of its group columns and, for each
#'   secondary parameter, one row per pair of (own group, reference group) with
#'   "PPORRESU" composed from the correct side of each.  Rows describing a
#'   result that names no reference -- every primary parameter, and a secondary
#'   parameter calculated without a reference -- hold `NA` in the `_ref`
#'   columns, and results carrying no reference group join to them.  A quotient
#'   whose two sides are convertible into one another is dimensionless, and such
#'   a row also gets "PPSTRESU" of "fraction" with the "conversion_factor" that
#'   turns the raw quotient into that number.
#'
#'   With one set of units for every group there is no reference side to name
#'   and no `_ref` column is added.
#'
#'   The standardized value of a secondary result is the quotient of its two
#'   sides' standardized values, each converted with its own group's
#'   "conversion_factor".  A table given to [PKNCAdata()] with group columns
#'   (a table per analyte, each from `pknca_units_table()` with the analyte
#'   column added, bound together) is treated in the same way:  it is stored as
#'   given, and the rows for each pair of its groups are built when [pk.nca()]
#'   reports the results.
#'
#'   A metabolite ratio (`mr.<parameter>`) is a ratio of masses, `"g/g"`, or of
#'   amounts of substance, `"mol/mol"`, as its parameter's units say.  When the units
#'   of one analyte are a mass and of the other an amount of substance, the
#'   ratio is an error (`pknca_error_mr_units_mixed`), and so is one whose two
#'   analytes a given table does not both describe
#'   (`pknca_error_units_secondary_missing`).  With each analyte converted to
#'   moles with its own molecular weight, the standardized metabolite ratio is
#'   the molar ratio; see `vignette("v09-secondary-parameters")`.
#' @seealso The `units` argument for [PKNCAdata()]
#' @examples
#' pknca_units_table() # only parameters that are unitless
#' pknca_units_table(
#'   concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr"
#' )
#' @examplesIf requireNamespace("units", quietly = TRUE)
#' # Automatic unit conversion needs the units package
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
      pknca_units_table_time_amount(timeu=timeu, amountu=amountu),
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
    # A metabolite ratio takes its standardized units from its base
    # (pknca_units_table_mr()) rather than from a conversion of its own
    conversions_pref <-
      dplyr::left_join(
        ret[!units_rows_mr(ret), , drop = FALSE],
        ret_pref[!units_rows_mr(ret_pref), , drop = FALSE],
        by = "PPTESTCD"
      )
    conversions_pref$PPTESTCD <- NULL
    conversions_pref <- unique(conversions_pref)
    # Drop units that are not converted
    conversions_pref <- conversions_pref[conversions_pref$PPORRESU != conversions_pref$PPSTRESU, ]
    # Drop units that are not provided
    conversions_pref <- conversions_pref[!is.na(conversions_pref$PPORRESU), ]
    conversions_pref$conversion_factor <- rep(NA_real_, nrow(conversions_pref))
    for (idx in seq_len(nrow(conversions))) {
      # Use the original conversions argument over `conversions_pref`
      mask_pref <- conversions_pref$PPORRESU %in% conversions$PPORRESU[idx]
      if (!any(mask_pref)) {
        rlang::abort(
          "Cannot find PPORRESU match between conversions and preferred unit conversions.  Check PPORRESU values in 'conversions' argument.",
          class = "pknca_error_units_pporresu_no_match"
        )
      }
      conversions_pref$PPSTRESU[mask_pref] <- conversions$PPSTRESU[idx]
      conversions_pref$conversion_factor[mask_pref] <- conversions$conversion_factor[idx]
    }
    conversions <- conversions_pref
  }

  extra_cols <- setdiff(ret$PPTESTCD, names(get.interval.cols()))
  if (length(extra_cols) > 0) {
    rlang::abort(sprintf("Please report a bug. Unknown NCA parameters have units defined: %s", paste(extra_cols, collapse = ", ")), class = "pknca_error_internal_unknown_nca_units")  # nocov
  }

  # Apply conversion factors
  if (nrow(conversions) > 0) {
    if (any(duplicated(conversions$PPORRESU)))
      rlang::abort(
        "conversions$PPORRESU must not have duplicated values",
        class = "pknca_error_units_pporresu_duplicated"
      )
    # PPSTRESU may be duplicated because some differing original units may
    # converge (e.g. cmax.dn and vss)
    if (length(setdiff(names(conversions), c("PPORRESU", "PPSTRESU", "conversion_factor"))) != 0)
      rlang::abort(
        "conversions must only have columns named 'PPORRESU', 'PPSTRESU', and 'conversion_factor'",
        class = "pknca_error_units_conversions_extra_cols"
      )
    if (any(is.na(conversions$conversion_factor)) && !requireNamespace("units", quietly=TRUE)) {
      rlang::abort("The units package is required for automatic unit conversion", class = "pknca_error_missing_units_package")  # nocov
    }
    for (idx in which(is.na(conversions$conversion_factor))) {
      conversions$conversion_factor[idx] <-
        pknca_units_conversion_factor(
          from = conversions$PPORRESU[idx],
          to = conversions$PPSTRESU[idx]
        )
    }
    unexpected_conversions <- setdiff(conversions$PPORRESU, ret$PPORRESU)
    if (length(unexpected_conversions) > 0) {
      rlang::warn(
        sprintf(
          "The following unit conversions were supplied but do not match any units to convert: %s",
          paste0("'", unexpected_conversions, "'", collapse = ", ")
        ),
        class = "pknca_warning_units_unexpected_conversions"
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
  pknca_units_table_mr(ret)
}

#' @rdname pknca_units_table
#' @export
pknca_units_table.PKNCAdata <- function(concu, ..., conversions = data.frame()) {

  # concu is the PKNCAdata object
  o_conc <- as_PKNCAconc(concu)
  o_dose <- as_PKNCAdose(concu)

  has_dose <- !is.null(o_dose) && !all(is.na(o_dose))

  # If needed, ensure that the PKNCA objects have the required unit columns
  o_conc <- ensure_column_unit_exists(o_conc, c("concu", "timeu", "amountu"))

  # Extract relevant columns from o_conc
  group_conc_cols <- dplyr::group_vars(o_conc)
  concu_col <- o_conc$columns$concu
  amountu_col <- o_conc$columns$amountu
  timeu_col <- o_conc$columns$timeu

  d_concu <- o_conc$data %>%
    dplyr::select(dplyr::any_of(c(group_conc_cols, concu_col, amountu_col, timeu_col))) %>%
    unique()

  if (has_dose) {
    # When a dose is present, join dose units with concentration unit columns
    o_dose <- ensure_column_unit_exists(o_dose, c("doseu"))
    group_dose_cols <- dplyr::group_vars(o_dose)
    doseu_col <- o_dose$columns$doseu
    d_doseu <- o_dose$data %>%
      dplyr::select(dplyr::any_of(c(group_dose_cols, doseu_col))) %>%
      unique()
    join_cols <- intersect(names(d_concu), names(d_doseu))
    groups_units_tbl <-
      if (length(join_cols) == 0) {
        dplyr::cross_join(d_concu, d_doseu)
      } else {
        join_unify_factor_keys(d_concu, d_doseu, by = join_cols, join_fun = dplyr::left_join)
      } %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), ~ as.character(.))) %>%
      unique()
    all_unit_cols <- c(concu_col, amountu_col, timeu_col, doseu_col)
  } else {
    # When no dose is present, dose-related parameters are excluded entirely
    doseu_col <- NULL
    groups_units_tbl <- d_concu %>%
      dplyr::mutate(dplyr::across(dplyr::everything(), ~ as.character(.))) %>%
      unique()
    all_unit_cols <- c(concu_col, amountu_col, timeu_col)
  }

  # Check that at least for each concentration group units are uniform
  if (length(group_conc_cols) == 0) {
    # No grouping columns: all rows must collapse to a single unique unit set
    mismatching_units_groups <-
      if (nrow(groups_units_tbl) > 1) groups_units_tbl else groups_units_tbl[0, , drop = FALSE]
  } else {
    mask_duplicated_groups <- duplicated(groups_units_tbl[group_conc_cols]) |
      duplicated(groups_units_tbl[group_conc_cols], fromLast = TRUE)
    mismatching_units_groups <- groups_units_tbl[mask_duplicated_groups, , drop = FALSE]
  }
  if (nrow(mismatching_units_groups) > 0) {
    mismatching_units_groups_msg <- name_value_text(mismatching_units_groups)
    rlang::abort(
      sprintf(
        "Units should be uniform at least across concentration groups. Review the units for the next group(s):\n%s",
        paste(mismatching_units_groups_msg, collapse = "\n")
      ),
      class = "pknca_error_units_nonuniform_groups"
    )
  }

  # Check that at least one unit column is not NA
  units.are.all.na <- all(is.na(groups_units_tbl[, all_unit_cols]))
  if (units.are.all.na) return(NULL)

  # Reduce to the minimal set of grouping columns that identify each unique unit
  # combination.  A simpler alternative would be to retain all grouping columns
  # (treatment, subject, analyte, specimen, ...) and skip this step entirely,
  # but that causes the output table to scale with the number of subjects rather
  # than the number of distinct unit strata.  For a study with 200 subjects x 4
  # analytes x 2 specimens and unit variation only by analyte x specimen,
  # retaining all group columns produces ~400,000 rows (200 * 8 * N_params)
  # versus ~1,000 rows (8 * N_params) here.  The combinatorial search in
  # select_minimal_grouping_cols is O(2^k) in the number of candidate grouping
  # columns k, but k is typically small (2-5) in practice.
  groups_units_tbl <- unique(select_minimal_grouping_cols(groups_units_tbl, all_unit_cols))
  groups_cols <- setdiff(names(groups_units_tbl), all_unit_cols)

  ret <- vector(mode = "list", length = nrow(groups_units_tbl))
  # The same tables without their group columns, which is how the secondary
  # composition below reads one unit set's answer for a source parameter
  unit_tables <- vector(mode = "list", length = nrow(groups_units_tbl))
  for (i in seq_len(nrow(groups_units_tbl))) {
    pknca_units_tbl_args <- list(
      concu = groups_units_tbl[[concu_col]][i],
      amountu = groups_units_tbl[[amountu_col]][i],
      timeu = groups_units_tbl[[timeu_col]][i],
      # Preferred units are always one value (pknca_set_units()), so every unit
      # set, including one from unit columns, converts to the same units.
      concu_pref = o_conc$units$concu_pref[1],
      amountu_pref = o_conc$units$amountu_pref[1],
      timeu_pref = o_conc$units$timeu_pref[1],
      conversions = conversions
    )
    if (has_dose) {
      pknca_units_tbl_args$doseu <- groups_units_tbl[[doseu_col]][i]
      pknca_units_tbl_args$doseu_pref <- o_dose$units$doseu_pref[1]
    }
    pknca_units_tbl_i <- do.call(pknca_units_table, pknca_units_tbl_args)
    if (!has_dose) {
      # Remove parameters that require dose units since no dose was provided
      pknca_units_tbl_i <- pknca_units_tbl_i[!is.na(pknca_units_tbl_i$PPORRESU), ]
    }
    unit_tables[[i]] <- pknca_units_tbl_i
  }
  # A unit set whose units are already the preferred ones has no conversions,
  # so its table lacks the standardization columns that another set's table
  # has.  As in pknca_units_table(), its units are the ones to report, with a
  # factor of 1.
  has_std <- vapply(X = unit_tables, FUN = function(x) "PPSTRESU" %in% names(x), FUN.VALUE = TRUE)
  for (i in which(!has_std & any(has_std))) {
    unit_tables[[i]]$PPSTRESU <- unit_tables[[i]]$PPORRESU
    unit_tables[[i]]$conversion_factor <- rep(1, nrow(unit_tables[[i]]))
  }
  for (i in seq_along(unit_tables)) {
    if (length(groups_cols) > 0) {
      groups_values <- groups_units_tbl[i, groups_cols, drop = FALSE]
      row.names(groups_values) <- NULL
      ret[[i]] <- cbind(groups_values, unit_tables[[i]])
    } else {
      ret[[i]] <- unit_tables[[i]]
    }
  }

  ret <- as.data.frame(dplyr::bind_rows(ret))
  # A secondary parameter takes one of its values from another group, so its
  # units are only knowable once the groups can differ.  With a single unit set
  # they cannot, and the table is exactly what it has always been.
  if (length(groups_cols) > 0 && nrow(groups_units_tbl) > 1) {
    groups_values <- groups_units_tbl[, groups_cols, drop = FALSE]
    row.names(groups_values) <- NULL
    ret <- pknca_units_table_secondary(ret, unit_tables, groups_values)
  }
  ret
}

# The two sides of the quotient a secondary parameter's units compose into,
# named by the formal arguments of its calculation function:  the requesting
# interval's own side over the reference interval's side.  A side naming two
# formals is itself a quotient (bioavailability divides an AUC by a dose on each
# side).  Any other secondary parameter -- one registered elsewhere, or one that
# is secondary only because it depends on another -- has no known composition
# and keeps the single-sided row of its own group.
secondary_unit_sides <- function(param) {
  switch(
    get.interval.cols()[[param]]$FUN,
    pk.calc.clr = list(own = "ae", ref = "auc"),
    pk.calc.ratio = list(own = "test", ref = "reference"),
    pk.calc.f = list(own = c("auc2", "dose2"), ref = c("auc1", "dose1")),
    NULL
  )
}

# One unit string divided by another, in the style of the rest of the table
pknca_units_quotient <- function(numerator, denominator) {
  if (is.na(numerator) || is.na(denominator)) {
    NA_character_
  } else {
    sprintf(
      "%s/%s",
      pknca_units_add_paren(numerator), pknca_units_add_paren(denominator)
    )
  }
}

# The units of one side of a secondary parameter's quotient under one unit set.
# `unit_table` is that unit set's table, `formals_used` names the side's formal
# arguments, `args` maps every formal of that side to the parameter it takes its
# value from, and `unit_column` chooses the original or the standardized units.
secondary_unit_side <- function(unit_table, formals_used, args, unit_column) {
  values <-
    vapply(
      X = args[formals_used],
      FUN = function(target) {
        ret <- unit_table[[unit_column]][unit_table$PPTESTCD %in% target]
        if (length(ret) == 1) as.character(ret) else NA_character_
      },
      FUN.VALUE = ""
    )
  if (anyNA(values)) {
    NA_character_
  } else if (length(values) == 1) {
    unname(values)
  } else {
    pknca_units_quotient(values[[1]], values[[2]])
  }
}

# Add the reference-keyed unit rows that describe secondary parameters
#
# A secondary parameter combines a value from the interval requesting it with
# one from a reference interval, so where units are group-stratified its units
# are a quotient of the two groups' units rather than either group's alone.
# Every row built from a single group therefore gains `<group column>_ref`
# columns holding `NA` -- "this row describes a result that names no reference"
# -- and one row per (own group, reference group) pair is added for each
# secondary parameter whose composition is known.  [pknca_unit_conversion()]
# joins on the `_ref` columns along with everything else, so a result finds the
# row describing the pair of groups it actually came from.
#
# A quotient of two convertible sides is dimensionless, and that row also gets
# `PPSTRESU` of "fraction" with the factor that turns the raw quotient into it.
# A quotient of two sides that are not convertible (an `mg` dose against a
# `mg/kg` dose) is reported in the composite units, which is the honest answer.
#
# @param units The table built from each unit set on its own
# @param unit_tables That same table per unit set, without the group columns
# @param group_values One row of group values per unit set, in the same order as
#   `unit_tables`
# @param pairs The pairs of unit sets to describe, a data.frame of the indexes
#   `own` and `ref` into `unit_tables`; every pair when NULL
# @returns `units` with the `_ref` columns and the reference-keyed rows added
# @keywords Internal
# @noRd
pknca_units_table_secondary <- function(units, unit_tables, group_values, pairs = NULL) {
  ref_cols <- paste0(names(group_values), "_ref")
  units[ref_cols] <- NA_character_
  classification <- parameter_classification()
  params <- names(classification$secondary)[classification$secondary]
  has_composition <-
    vapply(
      X = params,
      FUN = function(p) !is.null(secondary_unit_sides(p)),
      FUN.VALUE = TRUE
    )
  params <- params[has_composition]
  n_sets <- nrow(group_values)
  if (is.null(pairs)) {
    pairs <- data.frame(own = rep(seq_len(n_sets), each = n_sets), ref = rep(seq_len(n_sets), times = n_sets))
  }
  has_std <- all(c("PPSTRESU", "conversion_factor") %in% names(units))
  std_column <- if (has_std) "PPSTRESU" else "PPORRESU"
  # The factor between one pair of unit strings is the same answer for every
  # parameter and group pair that composes them
  factor_cache <- new.env(parent = emptyenv())
  new_rows <- list()
  for (current_param in params) {
    info <- secondary_param_info(current_param)
    sides <- secondary_unit_sides(current_param)
    is_mr <- is_metabolite_ratio(current_param)
    side_units <- list()
    for (unit_column in unique(c("PPORRESU", std_column))) {
      side_units[[unit_column]] <-
        list(
          own =
            vapply(
              X = unit_tables, FUN = secondary_unit_side, FUN.VALUE = "",
              formals_used = sides$own, args = info$own_args, unit_column = unit_column
            ),
          ref =
            vapply(
              X = unit_tables, FUN = secondary_unit_side, FUN.VALUE = "",
              formals_used = sides$ref, args = info$ref_args, unit_column = unit_column
            )
        )
    }
    own_factors <-
      vapply(
        X = unit_tables, FUN = secondary_unit_side_factor, FUN.VALUE = 1,
        formals_used = sides$own, args = info$own_args, has_std = has_std
      )
    ref_factors <-
      vapply(
        X = unit_tables, FUN = secondary_unit_side_factor, FUN.VALUE = 1,
        formals_used = sides$ref, args = info$ref_args, has_std = has_std
      )
    for (pair_i in seq_len(nrow(pairs))) {
      own_i <- pairs$own[pair_i]
      ref_i <- pairs$ref[pair_i]
      own_table <- unit_tables[[own_i]]
      base <- own_table[own_table$PPTESTCD %in% current_param, , drop = FALSE]
      if (nrow(base) != 1) {
        # The parameter has no units at all in this unit set (no dose data),
        # and a composed quotient would have none either
        next
      }
      u <- c(side_units$PPORRESU$own[[own_i]], side_units$PPORRESU$ref[[ref_i]])
      s <- c(side_units[[std_column]]$own[[own_i]], side_units[[std_column]]$ref[[ref_i]])
      if (is_mr && (pknca_units_amount_mixed(u[1], u[2]) || pknca_units_amount_mixed(s[1], s[2]))) {
        # A mass over an amount of substance is not a metabolite ratio, so the
        # pair has no row, and pknca_unit_conversion() stops when a result
        # needs it
        next
      }
      current <-
        secondary_pair_units(
          param = current_param, base = base, u = u, s = s,
          side_factor = own_factors[[own_i]] / ref_factors[[ref_i]],
          is_mr = is_mr, has_std = has_std, factor_cache = factor_cache
        )
      own_values <- group_values[own_i, , drop = FALSE]
      ref_values <- group_values[ref_i, , drop = FALSE]
      names(ref_values) <- ref_cols
      row.names(own_values) <- row.names(ref_values) <- NULL
      new_rows[[length(new_rows) + 1L]] <- cbind(own_values, ref_values, current)
    }
  }
  if (length(new_rows) == 0) {
    # No pair of groups to describe:  only the `_ref` columns are added, so
    # that a result naming a reference finds no row
    return(as.data.frame(units))
  }
  new_rows <- dplyr::bind_rows(new_rows)
  if (!has_std && all(is.na(new_rows$PPSTRESU))) {
    # Nothing standardizes, so the table keeps the two columns it never had
    new_rows$PPSTRESU <- NULL
    new_rows$conversion_factor <- NULL
  } else {
    if (!has_std) {
      units$PPSTRESU <- units$PPORRESU
      units$conversion_factor <- 1
    }
    # As in pknca_units_table(): units without a conversion of their own -- and
    # composites with no conversion to be had -- are already the units to
    # report, and a factor of 1 keeps them
    mask_unconverted <- is.na(new_rows$PPSTRESU) | is.na(new_rows$conversion_factor)
    new_rows$PPSTRESU[mask_unconverted] <- new_rows$PPORRESU[mask_unconverted]
    new_rows$conversion_factor[mask_unconverted] <- 1
  }
  as.data.frame(dplyr::bind_rows(units, new_rows))
}

# The units row of one secondary parameter for one pair of unit sets.
#
# `u` and `s` are the original and the standardized units of the own and the
# reference side, `base` is the parameter's row in the own unit set's table,
# and `side_factor` is the own side's conversion factor over the reference
# side's.  The standardized value is the quotient of the two sides'
# standardized values, so it is the raw quotient times `side_factor`; when the
# two sides' standardized units are convertible into one another, it is also
# multiplied by that conversion, which leaves a pure number.
#
# A metabolite ratio (`is_mr`) of two masses is in "g/g" and of two amounts of
# substance in "mol/mol"; the raw quotient carries that label when the two
# sides are in the same units, and the quotient of the two units otherwise.
secondary_pair_units <- function(param, base, u, s, side_factor, is_mr, has_std, factor_cache) {
  if (anyNA(u)) {
    # Units the two sides do not both know say nothing the parameter's
    # registered units do not
    return(
      data.frame(
        PPORRESU = base$PPORRESU,
        PPTESTCD = param,
        PPSTRESU = if (has_std) base$PPSTRESU else NA_character_,
        conversion_factor = if (has_std) base$conversion_factor else NA_real_
      )
    )
  }
  label <- label_std <- NA_character_
  if (is_mr) {
    label <- pknca_units_amount_ratio(u[1], u[2])
    label_std <- pknca_units_amount_ratio(s[1], s[2])
  }
  std_factor <- side_factor * pknca_unit_reconcile_factor_cached(factor_cache, from = s[1], to = s[2])
  if (identical(u[1], u[2])) {
    ret_orig <- if (is.na(label)) base$PPORRESU else label
    if (!has_std) {
      ret_std <- NA_character_
      ret_factor <- NA_real_
    } else if (is.na(std_factor)) {
      ret_std <- pknca_units_quotient(s[1], s[2])
      ret_factor <- side_factor
    } else if (!is.na(label_std)) {
      ret_std <- label_std
      ret_factor <- std_factor
    } else {
      ret_std <- base$PPSTRESU
      ret_factor <- base$conversion_factor * std_factor
    }
  } else {
    ret_orig <- pknca_units_quotient(u[1], u[2])
    if (!is.na(std_factor)) {
      ret_std <- if (is.na(label_std)) "fraction" else label_std
      ret_factor <- std_factor
    } else if (has_std) {
      # Not a pure number, but the sides may still have standardized units of
      # their own, and the quotient of those is the composite's
      ret_std <- pknca_units_quotient(s[1], s[2])
      ret_factor <- side_factor
    } else {
      ret_std <- NA_character_
      ret_factor <- NA_real_
    }
  }
  data.frame(
    PPORRESU = ret_orig,
    PPTESTCD = param,
    PPSTRESU = ret_std,
    conversion_factor = ret_factor
  )
}

# pknca_unit_reconcile_factor(), remembered in the environment `cache`
pknca_unit_reconcile_factor_cached <- function(cache, from, to) {
  key <- paste(from, to, sep = "|")
  if (is.null(cache[[key]])) {
    cache[[key]] <- pknca_unit_reconcile_factor(from = from, to = to)
  }
  cache[[key]]
}

# The conversion factor of one side of a secondary parameter's quotient under
# one unit set (1 when the table converts nothing), with the same arguments as
# secondary_unit_side()
secondary_unit_side_factor <- function(unit_table, formals_used, args, has_std) {
  if (!has_std) {
    return(1)
  }
  values <-
    vapply(
      X = args[formals_used],
      FUN = function(target) {
        ret <- unit_table$conversion_factor[unit_table$PPTESTCD %in% target]
        if (length(ret) == 1) as.numeric(ret) else NA_real_
      },
      FUN.VALUE = 1
    )
  if (length(values) == 1) {
    unname(values)
  } else {
    values[[1]] / values[[2]]
  }
}

# The kind of amount a unit measures:  "g" for a mass, "mol" for an amount of
# substance, and NA when it names neither or both (an activity such as "IU",
# or a missing unit).  It is read from the unit's own symbols, a mass or an
# amount of substance with an optional SI prefix ("ng", "mcg", "nmol", and
# "nM" for nmol/L), so that it does not need the units package.
pknca_units_amount_basis <- function(unit) {
  if (length(unit) != 1 || is.na(unit)) {
    return(NA_character_)
  }
  symbols <- strsplit(as.character(unit), split = "[^A-Za-z\u00b5\u03bc]+")[[1]]
  prefix <- "(Y|Z|E|P|T|G|M|k|h|da|d|c|m|u|\u00b5|\u03bc|n|p|f|a|z|y)?"
  is_mass <- any(grepl(paste0("^", prefix, "g$"), symbols) | symbols %in% "mcg")
  is_molar <- any(grepl(paste0("^", prefix, "(mol|M)$"), symbols))
  if (is_mass && !is_molar) {
    "g"
  } else if (is_molar && !is_mass) {
    "mol"
  } else {
    NA_character_
  }
}

# The units of a ratio of two amounts in the units `own` and `ref`:  "g/g" for
# two masses, "mol/mol" for two amounts of substance, and NA when either kind
# is unknown or they differ
pknca_units_amount_ratio <- function(own, ref) {
  basis <- c(pknca_units_amount_basis(own), pknca_units_amount_basis(ref))
  if (anyNA(basis) || basis[1] != basis[2]) {
    NA_character_
  } else {
    sprintf("%s/%s", basis[1], basis[1])
  }
}

# Whether one of `own` and `ref` is a mass and the other an amount of substance
pknca_units_amount_mixed <- function(own, ref) {
  basis <- c(pknca_units_amount_basis(own), pknca_units_amount_basis(ref))
  !anyNA(basis) && basis[1] != basis[2]
}

# The rows of a units table that describe metabolite ratios
units_rows_mr <- function(units) {
  ret <- startsWith(units$PPTESTCD, "mr.")
  ret[ret] <- is_metabolite_ratio(units$PPTESTCD[ret])
  ret
}

# A metabolite ratio (`mr.<base>`) within one unit set divides two values in
# the same units, so it is a ratio of masses ("g/g") or of amounts of substance
# ("mol/mol"), as its base's units say, rather than a "fraction".  Its
# standardized units follow its base's standardized units in the same way,
# unless a conversion of "fraction" itself was asked for.  A base whose kind
# of amount is unknown leaves the row as it is.
pknca_units_table_mr <- function(units) {
  mr_params <- unique(units$PPTESTCD[units_rows_mr(units)])
  has_std <- all(c("PPSTRESU", "conversion_factor") %in% names(units))
  for (current_param in mr_params) {
    base <- unname(secondary_param_info(current_param)$own_args[[1]])
    mask <- units$PPTESTCD %in% current_param
    mask_base <- units$PPTESTCD %in% base
    if (sum(mask) != 1 || sum(mask_base) != 1) {
      next
    }
    label <- pknca_units_amount_ratio(units$PPORRESU[mask_base], units$PPORRESU[mask_base])
    if (is.na(label)) {
      next
    }
    units$PPORRESU[mask] <- label
    if (has_std && units$PPSTRESU[mask] %in% "fraction") {
      label_std <- pknca_units_amount_ratio(units$PPSTRESU[mask_base], units$PPSTRESU[mask_base])
      units$PPSTRESU[mask] <- if (is.na(label_std)) label else label_std
    }
  }
  units
}

pknca_units_table_unitless <- function() {
  rbind(
    data.frame(
      PPORRESU="unitless",
      PPTESTCD=pknca_find_units_param(unit_type="unitless")
    ),
    data.frame(
      PPORRESU="fraction",
      PPTESTCD=pknca_find_units_param(unit_type="fraction")
    ),
    data.frame(
      PPORRESU="%",
      PPTESTCD=pknca_find_units_param(unit_type="%")
    ),
    data.frame(
      PPORRESU="count",
      PPTESTCD=pknca_find_units_param(unit_type="count")
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
    rlang::abort(
      sprintf(
        "Only one unit may be provided at a time: %s",
        paste(x, collapse = ", ")
      ),
      class = "pknca_error_units_multiple_provided"
    )
  } else if (length(x) == 0 && !is.null(x)) {
    # NULL and NA say that there is no unit; an empty vector says nothing
    rlang::abort(
      sprintf("A unit must be one value, NA, or NULL, not a zero-length %s", class(x)[1]),
      class = "pknca_error_units_zero_length"
    )
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
      PPTESTCD=pknca_find_units_param(unit_type="time")
    ),
    data.frame(
      PPORRESU=inverse_timeu,
      PPTESTCD=pknca_find_units_param(unit_type="inverse_time")
    )
  )
}

pknca_units_table_conc <- function(concu) {
  if (useless(concu)) {
    concu <- NA_character_
  }
  data.frame(
    PPORRESU=concu,
    PPTESTCD=pknca_find_units_param(unit_type="conc")
  )
}

pknca_units_table_amount <- function(amountu) {
  if (useless(amountu)) {
    amountu <- NA_character_
  }
  data.frame(
    PPORRESU=amountu,
    PPTESTCD=pknca_find_units_param(unit_type="amount")
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
    PPTESTCD=pknca_find_units_param(unit_type="amount_dose")
  )
}

pknca_units_table_dose <- function(doseu) {
  if (useless(doseu)) {
    doseu <- NA_character_
  }
  data.frame(
    PPORRESU=doseu,
    PPTESTCD=pknca_find_units_param(unit_type="dose")
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
      PPTESTCD=pknca_find_units_param(unit_type="conc_dosenorm")
    ),
    data.frame(
      # Volume units
      PPORRESU=volume,
      PPTESTCD=pknca_find_units_param(unit_type="volume")
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
      PPTESTCD=pknca_find_units_param(unit_type="auc")
    ),
    data.frame(
      # AUMC units
      PPORRESU=aumc,
      PPTESTCD=pknca_find_units_param(unit_type="aumc")
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
      PPTESTCD=pknca_find_units_param(unit_type="auc_dosenorm")
    ),
    data.frame(
      # AUMC units, dose-normalized
      PPORRESU=aumc_dosenorm,
      PPTESTCD=pknca_find_units_param(unit_type="aumc_dosenorm")
    ),
    data.frame(
      # Clearance units
      PPORRESU=clearance,
      PPTESTCD=pknca_find_units_param(unit_type="clearance")
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
    PPTESTCD=pknca_find_units_param(unit_type="renal_clearance")
  )
}

pknca_units_table_time_amount <- function(timeu, amountu) {
  if (useless(timeu) || useless(amountu)) {
    time_amount <- NA_character_
  } else {
    time_amount <- sprintf("%s/%s", pknca_units_add_paren(amountu), pknca_units_add_paren(timeu))
  }
  data.frame(
    PPORRESU = time_amount,
    PPTESTCD = pknca_find_units_param(unit_type = "amount_time")
  )
}

#' Find NCA parameters with a given unit type
#'
#' @param unit_type The type of unit as assigned with `add.interval.col`
#' @returns A character vector of parameters with a given unit type
#' @keywords Internal
pknca_find_units_param <- function(unit_type) {
  checkmate::assert_string(unit_type)
  all_intervals <- get.interval.cols()
  ret <- character()
  for (nm in names(all_intervals)) {
    if (all_intervals[[nm]]$unit_type == unit_type) {
      ret <- c(ret, nm)
    }
  }
  if (length(ret) == 0) {
    rlang::abort(
      sprintf(
        "No parameters found for unit_type=%s",
        unit_type
      ),
      class = "pknca_error_units_no_params_for_type"
    )
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

#' Find the factor converting a value from one unit to another
#'
#' @param from,to Single unit strings, as they appear in the "PPORRESU" and
#'   "PPSTRESU" columns of a unit conversion table
#' @returns The number that a value in `from` units is multiplied by to express
#'   it in `to` units.  Units that the `units` package cannot convert between
#'   are an error.
#' @keywords Internal
pknca_units_conversion_factor <- function(from, to) {
  as.numeric(
    units::set_units(
      units::set_units(1, from, mode = "standard"),
      to, mode = "standard"
    )
  )
}

#' Find the conversion factor between two units, when there is one
#'
#' The conversions of [pknca_units_table()] are requested by the user and so
#' fail loudly when they cannot be made.  This answers the different question of
#' whether two units PKNCA derived itself can be reconciled -- units that are
#' unrelated (a concentration and an amount) or outside udunits (`"IU/mL"`) are
#' an expected answer of "no" rather than a mistake.
#'
#' @inheritParams pknca_units_conversion_factor
#' @returns The number that a value in `from` units is multiplied by to express
#'   it in `to` units, or `NA_real_` when the two are not convertible or the
#'   `units` package is not installed.
#' @seealso [pknca_units_table()]
#' @keywords Internal
pknca_unit_reconcile_factor <- function(from, to) {
  if (length(from) != 1 || length(to) != 1 || is.na(from) || is.na(to)) {
    NA_real_
  } else if (identical(as.character(from), as.character(to))) {
    # Identical units need no conversion, so an analysis whose two sides already
    # agree does not need the `units` package installed.
    1
  } else if (!requireNamespace("units", quietly = TRUE)) {
    # Reached only where the Suggests-level `units` package is not installed
    NA_real_ # nocov
  } else {
    ret <- try(pknca_units_conversion_factor(from = from, to = to), silent = TRUE)
    if (inherits(ret, "try-error") || length(ret) != 1 || !is.finite(ret)) {
      NA_real_
    } else {
      ret
    }
  }
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
    units <- pknca_units_table_join_pairs(units, ret)
    # A result that names no reference group (nothing linked two intervals, or a
    # secondary parameter was calculated within one interval) can only be
    # described by the rows that name no reference either.  Matching it against
    # the reference-keyed rows as well would give it one row per reference group.
    for (col in setdiff(grep("_ref$", names(units), value = TRUE), names(ret))) {
      units <- units[is.na(units[[col]]), setdiff(names(units), col), drop = FALSE]
    }
    # The units table that PKNCAdata() builds holds group values as character
    ret <- left_join_by_value(ret, units, by = intersect(names(ret), names(units)))
    abort_mr_units_unmatched(ret, units)
    mask_missing_units <- is.na(ret$PPORRESU)
    if (any(mask_missing_units)) {
      msg_missing <-
        paste(
          "Units are provided for some but not all parameters; missing for:",
          paste(sort(unique(ret$PPTESTCD[mask_missing_units])), collapse = ", ")
        )
      if (allow_partial_missing_units) {
        rlang::warn(msg_missing, class = "pknca_warning_units_partial_missing")
      } else {
        rlang::abort(
          sprintf(
            "%s\nThis error can be converted to a warning using `PKNCA.options(allow_partial_missing_units = TRUE)`",
            msg_missing
          ),
          class = "pknca_error_units_partial_missing"
        )
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

# The units table to join to `result`, with the reference-keyed rows of the
# secondary parameters added to a table given to PKNCAdata() that has group
# columns but no `_ref` columns.  Each distinct combination of its group values
# is a unit set, as in the table PKNCAdata() builds, so that a secondary result
# finds the units of the pair of groups it came from.  The table stored in the
# PKNCAdata object is not changed.
pknca_units_table_join_pairs <- function(units, result) {
  group_cols <- setdiff(names(units), c("PPTESTCD", "PPORRESU", "PPSTRESU", "conversion_factor"))
  needs_pairs <-
    length(group_cols) > 0 &&
    !any(endsWith(group_cols, "_ref")) &&
    all(paste0(group_cols, "_ref") %in% names(result))
  if (!needs_pairs) {
    return(units)
  }
  group_values <- unique(units[, group_cols, drop = FALSE])
  row.names(group_values) <- NULL
  # Only the pairs of groups that secondary results came from, since a table
  # given per subject would otherwise describe every pair of subjects
  set_keys <- units_group_keys(group_values, group_cols)
  with_ref <- rowSums(!is.na(result[, paste0(group_cols, "_ref"), drop = FALSE])) > 0
  ref_groups <- stats::setNames(result[with_ref, paste0(group_cols, "_ref"), drop = FALSE], group_cols)
  pairs <-
    unique(data.frame(
      own = match(units_group_keys(result[with_ref, group_cols, drop = FALSE], group_cols), set_keys),
      ref = match(units_group_keys(ref_groups, group_cols), set_keys)
    ))
  pairs <- pairs[!is.na(pairs$own) & !is.na(pairs$ref), , drop = FALSE]
  unit_tables <-
    lapply(
      X = seq_len(nrow(group_values)),
      FUN = function(i) {
        units[
          group_row_mask(units, group_values, i, group_cols),
          setdiff(names(units), group_cols),
          drop = FALSE
        ]
      }
    )
  pknca_units_table_secondary(units, unit_tables, group_values, pairs = pairs)
}

# One text key per row of `data`, from its values in `cols`
units_group_keys <- function(data, cols) {
  do.call(paste, c(lapply(X = data[cols], FUN = as.character), sep = "\r"))
}

# A metabolite ratio result that found no units row names a pair of groups the
# units table cannot describe:  the two analytes' units are a mass and an amount
# of substance (`pknca_error_mr_units_mixed`), or the table lacks the units of
# one of them (`pknca_error_units_secondary_missing`).  Either is an error, not
# a ratio reported in the wrong units.
abort_mr_units_unmatched <- function(result, units) {
  ref_cols <- grep("_ref$", names(units), value = TRUE)
  if (length(ref_cols) == 0) {
    return(invisible(NULL))
  }
  mask <- is.na(result$PPORRESU) & units_rows_mr(result)
  mask <- mask & rowSums(!is.na(result[, ref_cols, drop = FALSE])) > 0
  if (!any(mask)) {
    return(invisible(NULL))
  }
  i <- which(mask)[1]
  param <- result$PPTESTCD[i]
  group_cols <- sub("_ref$", "", ref_cols)
  own_group <- result[i, group_cols, drop = FALSE]
  ref_group <- stats::setNames(result[i, ref_cols, drop = FALSE], group_cols)
  base <- unname(secondary_param_info(param)$own_args[[1]])
  single <- units[rowSums(!is.na(units[, ref_cols, drop = FALSE])) == 0, , drop = FALSE]
  own_units <- units_of_group(single, own_group, base)
  ref_units <- units_of_group(single, ref_group, base)
  own_text <- name_value_text(own_group)
  ref_text <- name_value_text(ref_group)
  if (!is.na(own_units[["PPORRESU"]]) && !is.na(ref_units[["PPORRESU"]])) {
    mixed <-
      pknca_units_amount_mixed(own_units[["PPORRESU"]], ref_units[["PPORRESU"]]) ||
      pknca_units_amount_mixed(own_units[["PPSTRESU"]], ref_units[["PPSTRESU"]])
    if (mixed) {
      rlang::abort(
        sprintf(
          "Metabolite ratio '%s' would divide a mass by an amount of substance:  '%s' of %s is in %s and of %s in %s.  Give both analytes mass units or both molar units.",
          param, base, own_text, units_text(own_units), ref_text, units_text(ref_units)
        ),
        class = "pknca_error_mr_units_mixed"
      )
    }
  }
  rlang::abort(
    sprintf(
      "The units table has no units for metabolite ratio '%s' of %s to %s:  it needs the units of '%s' for both.",
      param, own_text, ref_text, base
    ),
    class = "pknca_error_units_secondary_missing"
  )
}

# The original and standardized units of `param` for the group `group` in a
# units table of rows that name no reference group:  a character vector named
# PPORRESU and PPSTRESU (the latter NA when the table converts nothing), or NA
# when the table has no single row for it
units_of_group <- function(units, group, param) {
  mask <- units$PPTESTCD %in% param
  for (col in intersect(names(group), names(units))) {
    mask <- mask & as.character(units[[col]]) %in% as.character(group[[col]])
  }
  if (sum(mask) != 1) {
    return(c(PPORRESU = NA_character_, PPSTRESU = NA_character_))
  }
  c(
    PPORRESU = as.character(units$PPORRESU[mask]),
    PPSTRESU = if ("PPSTRESU" %in% names(units)) as.character(units$PPSTRESU[mask]) else NA_character_
  )
}

# The units from units_of_group() as text
units_text <- function(units) {
  if (is.na(units[["PPSTRESU"]]) || identical(units[["PPSTRESU"]], units[["PPORRESU"]])) {
    sprintf("'%s'", units[["PPORRESU"]])
  } else {
    sprintf("'%s' (standardized '%s')", units[["PPORRESU"]], units[["PPSTRESU"]])
  }
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
#' @keywords Internal
select_minimal_grouping_cols <- function(df, strata_cols) {
  # If there is no strata_cols specified, simply return the original df
  if (length(strata_cols) == 0) return(df)

  # Obtain the comb_vals values of the target column(s)
  strata_vals <- do.call(paste, c(df[strata_cols], sep = "_"))

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
    all_candidate_combs <- utils::combn(candidate_cols, n, simplify = FALSE)
    for (comb in all_candidate_combs) {
      comb_vals <- apply(df[, comb, drop = FALSE], 1, paste, collapse = "_")
      if (all(tapply(strata_vals, comb_vals, FUN = function(x) length(unique(x)) == 1))) {
        return(df[c(comb, strata_cols)])
      }
    }
  }
  df[strata_cols]
}
