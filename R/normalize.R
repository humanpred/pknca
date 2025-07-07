
#' Normalize parameters in a PKNCAresults object or data.frame
#'
#' @param object A PKNCAresults object or data.frame
#' @param norm_table data.frame with group columns, normalization values (`normalization`), and units (`unit`)
#' @param parameters character vector of parameter names to normalize
#' @param suffix character value to add for the normalized parameter names
#' @return A data.frame with normalized parameters
#' @export
normalize <- function(object, norm_table, parameters, suffix) {
  UseMethod("normalize")
}

#' @export
normalize.PKNCAresults <- function(object, norm_table, parameters, suffix) {
  if (!"PPSTRES" %in% names(object$result)) {
    object$result$PPSTRES <- object$result$PPORRES
    if (!"PPORRESU" %in% names(object$result)) {
      object$result$PPORRESU <- NA_character_
    }
    object$result$PPSTRESU <- object$result$PPORRESU
  }
  norm_parameters <- normalize(as.data.frame(object), norm_table, parameters, suffix)
  object$result <- dplyr::bind_rows(object$result, norm_parameters)
  object
}

#' @export
normalize.data.frame <- function(object, norm_table, parameters, suffix) {
  data <- object
  common_colnames <- setdiff(
    intersect(names(data), names(norm_table)),
    c("unit", "normalization")
  )
  not_common_groups <- dplyr::anti_join(norm_table, data, by = common_colnames)
  if (nrow(not_common_groups) > 0) {
    stop(
      "The normalization table contains groups not present in the data: ",
      paste(utils::capture.output(print(not_common_groups)), collapse = ", ")
    )
  }
  if (any(duplicated(norm_table[, common_colnames, drop = FALSE]))) {
    stop("The normalization table contains duplicate groups.")
  }
  df <- data[data$PPTESTCD %in% parameters, ]
  df <- merge(df, norm_table, by = common_colnames)
  if (!"PPSTRES" %in% names(df)) {
    df$PPSTRES <- df$PPORRES
    if (!"PPORRESU" %in% names(df)) {
      df$PPORRESU <- NA_character_
    }
    df$PPSTRESU <- df$PPORRESU
  }
  df$PPSTRES <- df$PPSTRES / df$normalization
  df$PPSTRESU <- paste0(df$PPSTRESU, "/", df$unit)
  df$PPTESTCD <- paste0(df$PPTESTCD, suffix)
  df[, unique(c(colnames(data), "PPSTRES", "PPSTRESU")), drop = FALSE]
}


#' Normalize parameters by a grouping column in a PKNCAresults object
#'
#' @param object A PKNCAresults object
#' @param column_type The type of grouping column (e.g., "subject", "analyte")
#' @param column_values The values for the grouping column
#' @param normalization_values The normalization values corresponding to each group
#' @param unit The unit for normalization
#' @param parameters Character vector of parameter names to normalize
#' @param suffix Suffix to add to normalized parameter names
#' @return A PKNCAresults object with normalized parameters appended
normalize_by_column <- function(object, column_type, column_values, normalization_values, unit, parameters, suffix) {
    if (!inherits(object, "PKNCAresults")) {
        stop("The object must be a PKNCAresults object.")
    }
    colname <- unlist(object$data$conc$columns)[[column_type]]
    if (is.null(colname)) {
        stop("Column ", column_type, " not found in the PKNCAresults object.")
    }
    if (length(column_values) != length(normalization_values)) {
        stop("The length of ", column_type, " values and normalization_values must be the same.")
    }
    if (any(duplicated(column_values))) {
        stop(paste0("The ", column_type, " values must not contain duplicates."))
    }
    norm_table <- data.frame(
        group_column = column_values,
        normalization = normalization_values,
        unit = unit
    )
    names(norm_table)[1] <- colname

    normalize(object, norm_table, parameters, suffix = suffix)
}


#' Normalize parameters by subject weight
#'
#' @param object A PKNCAresults object
#' @param subject Vector of subject IDs
#' @param weight Vector of weights corresponding to each subject
#' @param unit The unit for weight normalization (e.g., "kg")
#' @param parameters Character vector of parameter names to normalize
#' @return A PKNCAresults object with normalized parameters appended (suffix ".wn")
normalize_weight <- function(object, subject, weight, unit, parameters) {
    normalize_by_column(
        object = object,
        column_type = "subject",
        column_values = subject,
        normalization_values = weight,
        unit = unit,
        parameters = parameters,
        suffix = ".wn"
    )
}

#' Normalize parameters by subject BMI
#'
#' @param object A PKNCAresults object
#' @param subject Vector of subject IDs
#' @param bmi Vector of BMI values corresponding to each subject
#' @param unit The unit for BMI normalization (e.g., "kg/m^2")
#' @param parameters Character vector of parameter names to normalize
#' @return A PKNCAresults object with normalized parameters appended (suffix ".bmin")
normalize_bmi <- function(object, subject, bmi, unit, parameters) {
    normalize_by_column(
        object = object,
        column_type = "subject",
        column_values = subject,
        normalization_values = bmi,
        unit = unit,
        parameters = parameters,
        suffix = ".bmin"
    )
}

#' Normalize parameters by subject surface area
#'
#' @param object A PKNCAresults object
#' @param subject Vector of subject IDs
#' @param sa Vector of surface area values corresponding to each subject
#' @param unit The unit for surface area normalization (e.g., "m^2")
#' @param parameters Character vector of parameter names to normalize
#' @return A PKNCAresults object with normalized parameters appended (suffix ".san")
normalize_sa <- function(object, subject, sa, unit, parameters) {
    normalize_by_column(
        object = object,
        column_type = "subject",
        column_values = subject,
        normalization_values = sa,
        unit = unit,
        parameters = parameters,
        suffix = ".san"
    )
}

#' Normalize parameters by analyte molecular weight
#'
#' @param object A PKNCAresults object
#' @param analyte Vector of analyte names/IDs
#' @param mw Vector of molecular weights corresponding to each analyte
#' @param unit The unit for molecular weight normalization (e.g., "g/mol")
#' @param parameters Character vector of parameter names to normalize
#' @return A PKNCAresults object with normalized parameters appended (suffix ".mwn")
normalize_mw <- function(object, analyte, mw, unit, parameters) {
    normalize_by_column(
        object = object,
        column_type = "groups.group_analyte",
        column_values = analyte,
        normalization_values = mw,
        unit = unit,
        parameters = parameters,
        suffix = ".mwn"
    )
}
