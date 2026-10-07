#' Exclude data points or results from calculations or summarization.
#'
#' @param object The object to exclude data from.
#' @param reason The reason to add as a reason for exclusion.
#' @param mask A logical vector or numeric index of values to exclude (see
#'   details).
#' @param FUN A function to operate on the data (one group at a time) to select
#'   reasons for exclusions (see details).
#' @returns The object with updated information in the exclude column. The
#'   exclude column will contain the `reason` if `mask` or `FUN` indicate.  If a
#'   previous reason for exclusion was given, then subsequent reasons for
#'   exclusion will be added to the first with a semicolon space ("; ")
#'   separator.
#'
#' @details Only one of `mask` or `FUN` may be given.  If `FUN` is given, it
#'   will be called with two arguments:  a data.frame (or similar object) that
#'   consists of a single group of the data and the full object (e.g. the
#'   PKNCAconc object), `FUN(current_group, object)`, and it must return a
#'   logical vector equivalent to `mask` or a character vector with the reason
#'   text given when data should be excluded or `NA_character_` when the data
#'   should be included (for the current exclusion test).
#' @examples
#' myconc <- PKNCAconc(data.frame(subject=1,
#'                                time=0:6,
#'                                conc=c(1, 2, 3, 2, 1, 0.5, 0.25)),
#'                     conc~time|subject)
#' exclude(myconc,
#'         reason="Carryover",
#'         mask=c(TRUE, rep(FALSE, 6)))
#' @export
#' @family Result exclusions
#' @importFrom dplyr "%>%"
exclude <- function(object, reason, mask, FUN)
  UseMethod("exclude")

#' @describeIn exclude The general case for data exclusion
#' @export
exclude.default <- function(object, reason, mask, FUN) {
  dataname <- getDataName(object)
  # Check inputs
  if (missing(mask) && !missing(FUN)) {
    # operate on one group at a time
    groupnames <-
      unique(c(
        names(getGroups(object)),
        intersect(names(object[[dataname]]),
                  c("start", "end"))
      ))
    mask <- exclude_by_group(object = object, dataname = dataname, groupnames = groupnames, FUN = FUN)
    if (is.character(mask)) {
      reason <- mask
      mask <- !is.na(reason)
    }
  } else if (!xor(missing(mask), missing(FUN))) {
    rlang::abort("Either mask or FUN must be given (but not both).", class = "pknca_error_mask_or_fun")
  }
  if (!(length(reason) %in% c(1, nrow(object[[dataname]])))) {
    rlang::abort("reason must be a scalar or have the same length as the data.", class = "pknca_error_reason_length")
  } else if (!is.character(reason)) {
    rlang::abort("reason must be a character vector.", class = "pknca_error_reason_type")
  }

  if (!("exclude" %in% names(object$columns))) {
    rlang::abort("object must have an exclude column specified.", class = "pknca_error_no_exclude_col")
  } else if (!(object$columns$exclude %in% names(object[[dataname]]))) {
    rlang::abort(
      sprintf(
        "exclude column must exist in object[['%s']].",
        dataname
      ),
      class = "pknca_error_exclude_col_missing"
    )
  }
  # Make a scalar reason a vector
  if (length(reason) == 1)
    reason <- rep(reason, length(mask))
  # Find the original value of the 'exclude' column.
  orig <- object[[dataname]][[object$columns$exclude]]
  if (length(mask) != length(orig)) {
    rlang::abort("mask must match the length of the data.", class = "pknca_error_mask_length")
  }
  # No current value for exclude
  mask.none <- orig %in% c(NA, "")
  # Replace the empty value with the reason
  mask.one <- mask & mask.none
  # Add the new reason to an existing reason
  mask.multiple <- mask & (!mask.one)
  ret <- orig
  if (any(mask.one)) {
    ret[mask.one] <- reason[mask.one]
  }
  if (any(mask.multiple)) {
    ret[mask.multiple] <- paste(ret[mask.multiple], reason[mask.multiple], sep="; ")
  }
  ret_object <- object
  ret_object[[dataname]][,object$columns$exclude] <- ret
  mark_provenance_modified(ret_object, object, "excluded")
}

#' Call an exclusion function on each group of an object's data
#'
#' The groups are those of [dplyr::grouped_df()], so a missing group value is
#' its own group.  `FUN` is called outside of any dplyr verb so that the
#' conditions it signals reach the caller with their classes and fields (a
#' grouped `dplyr::mutate()` collects warnings and signals one summary warning
#' in their place).
#'
#' @inheritParams exclude
#' @param dataname The name of the data.frame within `object`
#' @param groupnames The columns that define the groups
#' @returns The values `FUN` returned, one per row of the data in the order of
#'   the data (a value of length one for a group is used for every row of it)
#' @keywords Internal
#' @noRd
exclude_by_group <- function(object, dataname, groupnames, FUN) {
  data <- object[[dataname]]
  group_rows <- dplyr::group_rows(dplyr::grouped_df(data, groupnames))
  ret <- rep(NA, nrow(data))
  for (current_rows in group_rows) {
    current_value <- FUN(as.data.frame(data[current_rows, , drop = FALSE]), object)
    if (length(current_value) == 1) {
      current_value <- rep(current_value, length(current_rows))
    } else if (length(current_value) != length(current_rows)) {
      rlang::abort(
        sprintf(
          "The exclusion function must return one value or one value per row of the group; it returned %d values for a group of %d rows.",
          length(current_value), length(current_rows)
        ),
        class = "pknca_error_exclude_fun_length"
      )
    }
    ret[current_rows] <- current_value
  }
  ret
}

#' Set the exclude parameter on an object
#'
#' This function adds the exclude column to an object.  To change the
#' exclude value, use the [exclude()] function.
#'
#' @param object The object to set the exclude column on.
#' @param exclude The column name to set as the exclude value.
#' @param dataname The name of the data.frame within the object to add the
#'   exclude column to.
#' @returns The object with an exclude column and attribute
setExcludeColumn <- function(object, exclude = NULL, dataname = "data") {
  add.exclude <- FALSE
  if (missing(exclude) || is.null(exclude)) {
    # Exclude is not provided.
    if ("exclude" %in% names(object$columns)) {
      # If exclude is already given, then do nothing.
    } else {
      add.exclude <- TRUE
    }
  } else if ("exclude" %in% names(object$columns)) {
    # If exclude is already in the object, then make sure it matches
    # (and do nothing).
    if (!(object$columns$exclude == exclude)) {
      rlang::abort("exclude is already set for the object.", class = "pknca_error_exclude_already_set")
    }
  } else {
    # If exclude is not already in the object and it is given, then add
    # the column.
    add.exclude <- TRUE
  }
  if (add.exclude) {
    if (missing(exclude) || is.null(exclude)) {
      # Generate the column name
      exclude <-
        setdiff(c("exclude", paste0("exclude.", max(names(object[[dataname]])))),
                names(object[[dataname]]))[1]
      object[[dataname]][[exclude]] <- rep(NA_character_, nrow(object[[dataname]]))
    } else if (nrow(object[[dataname]]) == 0) {
      object[[dataname]][[exclude]] <- rep(NA_character_, nrow(object[[dataname]]))
    } else if (!(exclude %in% names(object[[dataname]]))) {
      rlang::abort(
        "exclude, if given, must be a column name in the input data.",
        class = "pknca_error_exclude_not_in_data"
      )
    } else {
      if (is.factor(object[[dataname]][[exclude]])) {
        object[[dataname]][[exclude]] <- as.character(object[[dataname]][[exclude]])
      } else if (is.logical(object[[dataname]][[exclude]]) &&
                 all(is.na(object[[dataname]][[exclude]]))) {
        object[[dataname]][[exclude]] <- rep(NA_character_, nrow(object[[dataname]]))
      } else if (!is.character(object[[dataname]][[exclude]])) {
        rlang::abort(
          "exclude column must be character vector or something convertable to character without loss of information.",
          class = "pknca_error_exclude_not_character"
        )
      }
    }
    object$columns$exclude <- exclude
  }
  object
}

#' Normalize the exclude column by setting blanks to NA
#'
#' @param object The object to extract the exclude column from
#' @returns The exclude vector where `NA` indicates not to exclude and anything
#'   else indicates to exclude.
normalize_exclude <- function(object) {
  dataname <- getDataName(object)
  if (is.null(dataname)) {
    ret <- object
  } else {
    ret <- object[[dataname]][[object$columns$exclude]]
  }
  mask_blank <- ret %in% ""
  if (any(mask_blank)) {
    ret[mask_blank] <- NA
  }
  ret
}
