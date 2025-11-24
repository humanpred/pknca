
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
  common_colnames <- setdiff(
    intersect(names(object), names(norm_table)),
    c("unit", "normalization")
  )
  not_common_groups <- dplyr::anti_join(norm_table, object, by = common_colnames)
  if (nrow(not_common_groups) > 0) {
    df_error_string <- paste(
      paste(names(not_common_groups), collapse = "\t"),
      paste(apply(not_common_groups, 1, paste, collapse = "\t"), collapse = "\n"),
      sep = "\n"
    )
    stop(
      "The normalization table contains groups not present in the data:\n",
      df_error_string
    )
  }
  if (any(duplicated(norm_table[, common_colnames, drop = FALSE]))) {
    stop("The normalization table contains duplicate groups.")
  }
  df <- object[object$PPTESTCD %in% parameters, ]
  df <- merge(df, norm_table, by = common_colnames)

  df$PPORRES <- df$PPORRES / df$normalization
  if ("PPORRESU" %in% names(df)) {
    df$PPORRESU <- sprintf("%s/%s", pknca_units_add_paren(df$PPORRESU), pknca_units_add_paren(df$unit))
  }
  if ("PPSTRES" %in% names(df)) {
    df$PPSTRES <- df$PPSTRES / df$normalization
    if ("PPSTRESU" %in% names(df)) {
      df$PPSTRESU <- sprintf("%s/%s", pknca_units_add_paren(df$PPSTRESU), pknca_units_add_paren(df$unit))
    }
  }
  df$PPTESTCD <- paste0(df$PPTESTCD, suffix)
  df[, colnames(object), drop = FALSE]
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
  obj_conc_cols <- names(object$data$conc$data)
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
