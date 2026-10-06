#' Find the samples missing from each subject's nominal sampling schedule
#'
#' The schedule of a group is every nominal time that has a row in the
#' concentration data of that group, where the group is every grouping variable
#' of the concentration data except the subject (for example, the study,
#' treatment, and analyte).  Each subject of the group is expected to have a
#' usable concentration at every time of its group's schedule, and a time
#' without one is reported.  Missing samples are therefore found only when
#' some subject of the group has a row at that nominal time; a time that no
#' subject has a row for is not part of the schedule.  Recording a missed
#' sample as a row with an `NA` concentration keeps the time in the schedule
#' even when every subject missed it.
#'
#' A nominal time of a subject's schedule is reported with one of these reasons:
#'
#' * `"no row"`: the subject has no row at that nominal time.
#' * `"NA concentration"`: every row of the subject at that nominal time has an
#'   `NA` concentration.
#' * `"excluded"`: the subject has a concentration at that nominal time, but
#'   every row with one is excluded (with the `exclude` column of
#'   [PKNCAconc()] or with [exclude()]), so the calculations do not use it.
#'
#' A concentration below the limit of quantification (zero) is a usable
#' sample.  Rows with an `NA` nominal time (unscheduled samples) are not part
#' of any schedule, and they neither add a time to it nor fill one.  Nominal
#' times are compared as they are, so they may be in any unit.
#'
#' Sparse data (see the `sparse` argument of [PKNCAconc()]) have no schedule
#' that each subject follows:  each subject gives a few of the group's
#' samples by design.  For sparse data, only the rows that exist are checked
#' (reasons `"NA concentration"` and `"excluded"`), and a message says that
#' absent rows are not reported.
#'
#' @param object A PKNCAconc, PKNCAdata, or PKNCAresults object (the
#'   concentration data of a PKNCAdata or PKNCAresults object are checked).
#'   Its concentration data must have a nominal time (the `time.nominal`
#'   argument of [PKNCAconc()]).
#' @returns A data.frame with one row per missing sample and the columns:  the
#'   grouping columns of the concentration data other than the subject, the
#'   subject column, the nominal time column (with the names they have in the
#'   concentration data), and `reason`.  It is sorted by those columns and has
#'   no rows when no sample is missing.
#' @family Result exclusions
#' @seealso [exclude_nca_tmax_coverage()], which excludes the results of a
#'   subject whose samples miss the Tmax range of its group
#' @examples
#' d_conc <-
#'   data.frame(
#'     subject = rep(1:3, each = 4),
#'     time_nominal = rep(c(0, 1, 2, 4), 3),
#'     time = rep(c(0, 1, 2, 4), 3),
#'     conc = c(0, 5, 3, 1, 0, 4, NA, 1, 0, 6, 2, 1)
#'   )
#' # Subject 3 has no sample at 4 hours
#' d_conc <- d_conc[-12, ]
#' o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal")
#' pknca_missing_samples(o_conc)
#' @export
pknca_missing_samples <- function(object) {
  checkmate::assert_multi_class(object, c("PKNCAconc", "PKNCAdata", "PKNCAresults"))
  o_conc <- as_PKNCAconc(object)
  nominal_col <- o_conc$columns$time.nominal
  if (is.null(nominal_col)) {
    rlang::abort(
      "Missing samples are found from the nominal times, and the concentration data have none; give the nominal time column as the `time.nominal` argument of PKNCAconc()",
      class = "pknca_error_missing_samples_no_time_nominal"
    )
  }
  data <- as.data.frame(o_conc)
  if (!any(!is.na(data[[nominal_col]]))) {
    rlang::abort(
      sprintf(
        "Missing samples are found from the nominal times, and the nominal time column ('%s') has no values",
        nominal_col
      ),
      class = "pknca_error_missing_samples_no_nominal_values"
    )
  }
  sparse <- is_sparse_pk(o_conc)
  if (sparse) {
    rlang::inform(
      "The concentration data are sparse, so each subject has no schedule of its own:  only rows with an NA concentration or an exclusion are reported, not absent rows",
      class = "pknca_message_missing_samples_sparse"
    )
  }
  subject_col <- o_conc$columns$subject
  status <-
    pknca_nominal_sample_status(
      data = data,
      group_cols = setdiff(group_vars(o_conc), subject_col),
      subject_col = subject_col,
      nominal_col = nominal_col,
      conc_col = o_conc$columns$concentration,
      excluded = !is.na(normalize_exclude(o_conc)),
      complete = !sparse
    )
  ret <- status[status$status != "present", , drop = FALSE]
  names(ret)[names(ret) == "status"] <- "reason"
  rownames(ret) <- NULL
  ret
}

#' Whether each subject has a usable sample at each nominal time
#'
#' @param data The concentration data
#' @param group_cols The grouping columns other than the subject
#' @param subject_col The subject column (`NULL` or empty without one)
#' @param nominal_col The nominal time column
#' @param conc_col The concentration column
#' @param excluded A logical vector, one value per row of `data`:  is the row
#'   excluded?
#' @param complete Give every time of each group's schedule for every subject
#'   of the group (`TRUE`), or only the subjects and times with rows
#'   (`FALSE`)?
#' @returns A data.frame with the columns `group_cols`, `subject_col`,
#'   `nominal_col`, and `status` (`"present"` when a row has a concentration
#'   and is not excluded, otherwise `"excluded"`, `"NA concentration"`, or
#'   `"no row"`, in that order of precedence among the subject's rows at the
#'   time), sorted by the other columns
#' @keywords Internal
#' @noRd
pknca_nominal_sample_status <- function(data, group_cols, subject_col, nominal_col, conc_col, excluded, complete = TRUE) {
  status_levels <- c("present", "excluded", "NA concentration", "no row")
  id_cols <- c(group_cols, subject_col)
  key_cols <- c(id_cols, nominal_col)
  scheduled <- !is.na(data[[nominal_col]])
  rows <- data[scheduled, key_cols, drop = FALSE]
  rows$status_code <-
    ifelse(
      is.na(data[[conc_col]][scheduled]),
      3L,
      ifelse(excluded[scheduled], 2L, 1L)
    )
  ret <-
    dplyr::summarise(
      dplyr::grouped_df(rows, key_cols),
      status_code = min(.data$status_code),
      .groups = "drop"
    )
  if (complete) {
    schedule <- unique(rows[, c(group_cols, nominal_col), drop = FALSE])
    grid <-
      if (length(id_cols) == 0) {
        schedule
      } else if (length(group_cols) == 0) {
        dplyr::cross_join(unique(data[, id_cols, drop = FALSE]), schedule)
      } else {
        dplyr::inner_join(
          unique(data[, id_cols, drop = FALSE]),
          schedule,
          by = group_cols,
          relationship = "many-to-many"
        )
      }
    ret <- dplyr::left_join(grid, ret, by = key_cols)
    ret$status_code[is.na(ret$status_code)] <- 4L
  }
  ret <- dplyr::arrange(ret, dplyr::across(dplyr::all_of(key_cols)))
  ret$status <- status_levels[ret$status_code]
  as.data.frame(ret[, c(key_cols, "status"), drop = FALSE])
}

#' Keep the rows of one data.frame that match a row of another
#'
#' @param x,y data.frames
#' @param by The columns to match on; with none, every row of `x` matches
#'   (when `y` has a row)
#' @returns The rows of `x` that match a row of `y`
#' @keywords Internal
#' @noRd
pknca_semi_join <- function(x, y, by) {
  if (length(by) == 0) {
    if (nrow(y) > 0) x else x[0, , drop = FALSE]
  } else {
    dplyr::semi_join(x, y, by = by)
  }
}
