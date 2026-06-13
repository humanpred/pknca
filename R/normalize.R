
#' Normalize parameters in a PKNCAresults object or data.frame
#'
#' @param object A PKNCAresults object or result data.frame
#' @param norm_table data.frame with group columns, normalization values (`normalization`), and units (`unit`)
#' @param parameters character vector of parameter names to normalize
#' @param suffix character value to add for the normalized parameter names
#' @return A data.frame with normalized parameters
#' @export
normalize <- function(object, norm_table, parameters, suffix) {
  UseMethod("normalize", object)
}

#' @export
normalize.PKNCAresults <- function(object, norm_table, parameters, suffix) {
  norm_parameters <- normalize(as.data.frame(object), norm_table, parameters, suffix)
  object$result <- rbind(object$result, norm_parameters)
  object
}

#' @export
normalize.data.frame <- function(object, norm_table, parameters, suffix) {
  
  # Identify common columns for grouping
  common_colnames <- setdiff(
    intersect(names(object), names(norm_table)),
    c("unit", "normalization")
  )
  
  # ---- Validate norm_table ----
  if (length(common_colnames) > 0) {
    
    # Check for missing groups
    missing_groups <- dplyr::anti_join(norm_table, object, by = common_colnames)
    if (nrow(missing_groups) > 0) {
      df_error_string <- paste(
        paste(names(missing_groups), collapse = "\t"),
        paste(apply(missing_groups, 1, paste, collapse = "\t"), collapse = "\n"),
        sep = "\n"
      )
      stop(
        "The normalization table contains groups not present in the data:\n",
        df_error_string
      )
    }
    
    # Check for duplicate groups
    if (any(duplicated(norm_table[, common_colnames, drop = FALSE]))) {
      stop("The normalization table contains duplicate groups.")
    }
    
  } else {
    # Ungrouped case
    if (nrow(norm_table) != 1) {
      stop("Normalization table must be a single row for ungrouped data.")
    }
  }
  
  # ---- Filter relevant parameters (base R) ----
  df <- object[object$PPTESTCD %in% parameters, , drop = FALSE]
  
  # ---- Join normalization values ----
  if (length(common_colnames) == 0) {
    # Cartesian join
    df <- merge(df, norm_table, by = NULL)
  } else {
    df <- dplyr::inner_join(df, norm_table, by = common_colnames)
  }
  
  # ---- Apply normalization (base R) ----
  df$PPORRES <- df$PPORRES / df$normalization
  df$PPTESTCD <- paste0(df$PPTESTCD, suffix)
  
  if ("PPORRESU" %in% names(df)) {
    df$PPORRESU <- sprintf(
      "%s/%s",
      pknca_units_add_paren(df$PPORRESU),
      pknca_units_add_paren(df$unit)
    )
  }
  
  if ("PPSTRES" %in% names(df)) {
    df$PPSTRES <- df$PPSTRES / df$normalization
    
    if ("PPSTRESU" %in% names(df)) {
      df$PPSTRESU <- sprintf(
        "%s/%s",
        pknca_units_add_paren(df$PPSTRESU),
        pknca_units_add_paren(df$unit)
      )
    }
  }
  
  # ---- Return original column order ----
  df[, names(object), drop = FALSE]
}

#' Internal function to normalize by a specified column
#' @param object A PKNCAresults object
#' @param col The column name from PKNCAconc to use for the normalization groups
#' @param unit The unit of the previous column for normalization. Can be a column name in PKNCAconc or a single value.
#' @param parameters Character vector of parameter names to normalize
#' @param suffix Suffix to add to the normalized parameter code names
#' @importFrom dplyr group_vars
#' @return A data.frame with normalized parameters
#' @export
normalize_by_col <- function(object, col, unit, parameters, suffix){
  if (!inherits(object, "PKNCAresults")) {
    stop("The object must be a PKNCAresults object")
  }
  obj_conc_cols <- names(as.data.frame(as_PKNCAconc(object)))
  if (!col %in% obj_conc_cols) {
    stop("Column ", col, " not found in the PKNCAconc of the PKNCAresults object")
  }
  conc_groups <- dplyr::group_vars(object$data$conc)
  if (unit %in% obj_conc_cols) {
    norm_table <- unique(object$data$conc$data[, c(conc_groups, col, unit)])
    names(norm_table)[names(norm_table) == col] <- "normalization"
    names(norm_table)[names(norm_table) == unit] <- "unit"
  } else {
    norm_table <- unique(object$data$conc$data[, c(conc_groups, col)])
    names(norm_table)[names(norm_table) == col] <- "normalization"
    norm_table$unit <- unit
  }
  # Check there are no duplicate groups with different normalization values
  if (any(duplicated(norm_table[, conc_groups, drop = FALSE]))) {
    stop("There is at least one concentration group with multiple normalization values")
  }
  normalize(object, norm_table, parameters, suffix)
}
