# Secondary parameters: NCA parameters whose calculation needs a result from a
# different interval (the "reference" interval).  The interval specification
# links the two with an `interval_id` column naming the reference row and a
# `<parameter>_ref` pointer column on the row requesting the parameter.
#
# `pknca_ref()` and `is_pknca_ref()` are defined in R/001-add.interval.col.R so
# that the registrations using them can run while the package is sourced.

# What a secondary parameter's registration says about its inputs.
#
# ref_args:  named character vector, formal name -> parameter taken from the
#            reference interval.
# own_args: named character vector, formal name -> parameter taken from the
#            requesting interval's own results.
# Errors (classed) when the registration cannot be computed by the secondary
# pass: a formal that is neither covered by formalsmap nor named after a
# parameter, an unregistered ref target, or an own-interval argument not listed
# in `depends`.
secondary_param_info <- function(param) {
  all_intervals <- get.interval.cols()
  spec <- all_intervals[[param]]
  fm <- spec$formalsmap
  is_ref <- vapply(X = fm, FUN = is_pknca_ref, FUN.VALUE = TRUE)
  ref_args <- vapply(X = fm[is_ref], FUN = function(x) x$param, FUN.VALUE = "")
  plain <- fm[!is_ref]
  # An I()-wrapped value is a constant and a NULL drops the argument; neither is
  # a parameter result, and pk.nca.interval() handles both the same way.
  plain <- plain[!vapply(X = plain, FUN = inherits, FUN.VALUE = TRUE, what = "AsIs")]
  plain <- plain[!vapply(X = plain, FUN = is.null, FUN.VALUE = TRUE)]
  own_args <- unlist(plain)   # named character vector (may be empty)
  if (is.null(own_args)) {
    own_args <- stats::setNames(character(0), character(0))
  }
  # Every formal (minus ...) must resolve to a parameter result so that the pass
  # only ever needs parameter results as inputs.  A formal that formalsmap does
  # not mention keeps pk.nca.interval()'s identity mapping, so it is an own
  # argument when a parameter of the same name is registered (`ae` for `clr.*`).
  fun_formals <- setdiff(names(formals(get(spec$FUN))), "...")
  unmentioned <- setdiff(fun_formals, names(fm))
  implicit <- unmentioned[unmentioned %in% names(all_intervals)]
  own_args <- c(own_args, stats::setNames(implicit, implicit))
  uncovered <-
    unique(c(
      setdiff(unmentioned, implicit),
      names(own_args)[!(own_args %in% names(all_intervals))]
    ))
  if (length(uncovered) > 0) {
    rlang::abort(
      sprintf(
        "The secondary parameter '%s' has arguments not covered by formalsmap (%s); a secondary parameter's calculation function may only take NCA parameter values as inputs",
        param, paste(uncovered, collapse = ", ")
      ),
      class = "pknca_error_secondary_registration"
    )
  }
  unregistered <- setdiff(ref_args, names(all_intervals))
  if (length(unregistered) > 0) {
    rlang::abort(
      sprintf(
        "pknca_ref() target(s) for parameter '%s' are not registered NCA parameters: %s",
        param, paste(unregistered, collapse = ", ")
      ),
      class = "pknca_error_secondary_target_unregistered"
    )
  }
  # The interval's own values are read from what it already calculated, so they
  # have to be calculated first.
  missing_depends <- setdiff(own_args, spec$depends)
  if (length(missing_depends) > 0) {
    rlang::abort(
      sprintf(
        "The secondary parameter '%s' uses parameter(s) from its own interval not listed in `depends`: %s",
        param, paste(missing_depends, collapse = ", ")
      ),
      class = "pknca_error_secondary_registration"
    )
  }
  list(fun = spec$FUN, ref_args = ref_args, own_args = own_args)
}

# Names of all registered secondary parameters
secondary_parameter_names <- function() {
  cls <- parameter_classification()
  names(cls$secondary)[cls$secondary]
}

# Validate PKNCAdata(group_ref=) against the concentration data.  A typo in a
# column or a value would otherwise silently steer the automatic reference
# finder nowhere, so both are checked when the object is built.
#
# Three forms are accepted (see the PKNCAdata() documentation):  a data.frame
# of group values applying to every secondary parameter; a data.frame with a
# `parameter` column applying each row to the secondary parameter it names; or
# a named list of data.frames, one per parameter.
assert_group_ref <- function(group_ref, o_conc) {
  if (is.null(group_ref)) {
    return(NULL)
  }
  if (is.data.frame(group_ref)) {
    return(assert_group_ref_frame(group_ref, o_conc))
  }
  if (!is.list(group_ref)) {
    rlang::abort(
      "`group_ref` must be a data.frame or a named list of data.frames",
      class = "pknca_error_group_ref_invalid"
    )
  }
  if (!checkmate::test_names(names(group_ref), type = "unique")) {
    rlang::abort(
      "`group_ref`, when a list, must have unique names, each the name of a secondary parameter",
      class = "pknca_error_group_ref_invalid"
    )
  }
  assert_group_ref_parameters(names(group_ref))
  for (current_param in names(group_ref)) {
    current <- group_ref[[current_param]]
    if (!is.data.frame(current) || "parameter" %in% names(current)) {
      rlang::abort(
        sprintf(
          "`group_ref[[\"%s\"]]` must be a data.frame of group values without a `parameter` column",
          current_param
        ),
        class = "pknca_error_group_ref_invalid"
      )
    }
    assert_group_ref_frame(current, o_conc)
  }
  group_ref
}

# The parameters a parameter-specific group_ref names must be secondary
# parameters, or nothing would ever read their entries
assert_group_ref_parameters <- function(params) {
  assert_param_name(params)
  cls <- parameter_classification()
  not_secondary <-
    params[
      !vapply(X = params, FUN = function(p) isTRUE(cls$secondary[[p]]), FUN.VALUE = TRUE)
    ]
  if (length(not_secondary) > 0) {
    rlang::abort(
      sprintf(
        "`group_ref` steers secondary parameters only; not secondary: %s",
        paste(not_secondary, collapse = ", ")
      ),
      class = "pknca_error_group_ref_invalid"
    )
  }
  invisible(params)
}

# One data.frame of the group_ref, possibly carrying a `parameter` column.  The
# rows for one parameter must fill the same columns (their non-NA column sets
# must match), because the columns a parameter's rows leave NA do not apply to
# it and an NA that applied would match NA group values literally.
assert_group_ref_frame <- function(group_ref, o_conc) {
  if (nrow(group_ref) < 1 || ncol(group_ref) < 1) {
    rlang::abort(
      "`group_ref` must be a data.frame with at least one row and one column",
      class = "pknca_error_group_ref_invalid"
    )
  }
  has_parameter <- "parameter" %in% names(group_ref)
  if (has_parameter) {
    if (ncol(group_ref) < 2) {
      rlang::abort(
        "`group_ref` must have at least one group column besides `parameter`",
        class = "pknca_error_group_ref_invalid"
      )
    }
    if (anyNA(group_ref$parameter)) {
      rlang::abort(
        "The `parameter` column of `group_ref` may not be NA; drop the `parameter` column to steer every secondary parameter",
        class = "pknca_error_group_ref_invalid"
      )
    }
    assert_group_ref_parameters(unique(as.character(group_ref$parameter)))
    for (current_param in unique(as.character(group_ref$parameter))) {
      resolved <- group_ref_for_param(group_ref, current_param)
      if (is.null(resolved) || anyNA(resolved)) {
        rlang::abort(
          sprintf(
            "The `group_ref` rows for parameter '%s' must fill the same group column(s)",
            current_param
          ),
          class = "pknca_error_group_ref_invalid"
        )
      }
    }
  }
  group_cols <- unlist(o_conc$columns$groups)
  invalid <- setdiff(setdiff(names(group_ref), "parameter"), group_cols)
  if (length(invalid) > 0) {
    rlang::abort(
      sprintf(
        "Column(s) in `group_ref` must be group columns of the concentration data: %s",
        paste(invalid, collapse = ", ")
      ),
      class = "pknca_error_group_ref_invalid"
    )
  }
  conc_data <- as.data.frame(o_conc)
  for (col in setdiff(names(group_ref), "parameter")) {
    unknown <-
      setdiff(
        as.character(stats::na.omit(group_ref[[col]])),
        as.character(conc_data[[col]])
      )
    if (length(unknown) > 0) {
      rlang::abort(
        sprintf(
          "`group_ref` column '%s' has value(s) that are not in the concentration data: %s",
          col, paste(unknown, collapse = ", ")
        ),
        class = "pknca_error_group_ref_value"
      )
    }
  }
  group_ref
}

# The group_ref that applies to `param`.  A plain data.frame applies to every
# secondary parameter; a data.frame with a `parameter` column applies its
# matching rows, dropping the columns those rows leave all-NA so that one table
# can carry different columns for different parameters; a named list applies
# its `param` element.  NULL when nothing steers `param`.
group_ref_for_param <- function(group_ref, param) {
  if (is.null(group_ref)) {
    return(NULL)
  }
  if (!is.data.frame(group_ref)) {
    return(group_ref[[param]])
  }
  if (!("parameter" %in% names(group_ref))) {
    return(group_ref)
  }
  ret <-
    group_ref[
      group_ref$parameter %in% param,
      setdiff(names(group_ref), "parameter"),
      drop = FALSE
    ]
  keep <- vapply(X = ret, FUN = function(values) !all(is.na(values)), FUN.VALUE = TRUE)
  ret <- ret[, keep, drop = FALSE]
  if (nrow(ret) == 0 || ncol(ret) == 0) {
    NULL
  } else {
    ret
  }
}

#' Calculate the ratio of a parameter between two intervals
#'
#' @param test The parameter value in the current (test) interval
#' @param reference The parameter value in the reference interval
#' @returns `test/reference`, or `NA` where the reference is missing or is not
#'   above zero (a ratio to a zero or negative reference is not interpretable).
#' @seealso [interval_add_secondary()]
#' @examples
#' pk.calc.ratio(test = 10, reference = 20)
#' @export
pk.calc.ratio <- function(test, reference) {
  ret <- test/reference
  mask_invalid <- is.na(reference) | (reference <= 0)
  if (any(mask_invalid)) {
    ret[mask_invalid] <- NA_real_
  }
  ret
}

add.interval.col("ratio.cmax",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of Cmax to reference",
                 desc="Ratio of Cmax to reference",
                 formalsmap=list(test="cmax",
                                 reference=pknca_ref("cmax")),
                 depends="cmax",
                 pptest_cdisc="Ratio of Cmax to Reference",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.auclast",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of AUClast to reference",
                 desc="Ratio of AUClast to reference",
                 formalsmap=list(test="auclast",
                                 reference=pknca_ref("auclast")),
                 depends="auclast",
                 pptest_cdisc="Ratio of AUClast to Reference",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.aucinf.obs",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of AUCinf,obs to reference",
                 desc="Ratio of AUCinf,obs to reference",
                 formalsmap=list(test="aucinf.obs",
                                 reference=pknca_ref("aucinf.obs")),
                 depends="aucinf.obs",
                 pptest_cdisc="Ratio of AUCinf,obs to Reference",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.aucinf.pred",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of AUCinf,pred to reference",
                 desc="Ratio of AUCinf,pred to reference",
                 formalsmap=list(test="aucinf.pred",
                                 reference=pknca_ref("aucinf.pred")),
                 depends="aucinf.pred",
                 pptest_cdisc="Ratio of AUCinf,pred to Reference",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.aucint.last",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of AUCint,last to reference",
                 desc="Ratio of AUCint,last to reference",
                 formalsmap=list(test="aucint.last",
                                 reference=pknca_ref("aucint.last")),
                 depends="aucint.last",
                 pptest_cdisc="Ratio of AUCint,last to Reference",
                 selection = list(concept = "parameter_ratio"))

add.interval.col("ratio.aucint.all",
                 FUN="pk.calc.ratio",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Ratio of AUCint,all to reference",
                 desc="Ratio of AUCint,all to reference",
                 formalsmap=list(test="aucint.all",
                                 reference=pknca_ref("aucint.all")),
                 depends="aucint.all",
                 pptest_cdisc="Ratio of AUCint,all to Reference",
                 selection = list(concept = "parameter_ratio"))

PKNCA.set.summary(
  name = paste0(
    "ratio.",
    c("cmax", "auclast", "aucinf.obs", "aucinf.pred", "aucint.last", "aucint.all")
  ),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)

# Parameters in this one-row interval that are deferred to the cross-interval
# pass: requested, and with a non-NA reference pointer.
interval_deferred_params <- function(interval) {
  params <- intersect(names(interval), names(get.interval.cols()))
  ref_cols <- paste0(params, "_ref")
  has_ref <- ref_cols %in% names(interval)
  params <- params[has_ref]
  ref_cols <- ref_cols[has_ref]
  keep <-
    vapply(
      X = seq_along(params),
      FUN = function(i) isTRUE(interval[[params[i]]]) && !is.na(interval[[ref_cols[i]]]),
      FUN.VALUE = TRUE
    )
  params[keep]
}

# The reference interval gains whatever the link reads from it.  Silent by
# design:  adding a needed source parameter to a reference interval is
# dependency calculation, which PKNCA never announces.
#
# One reference interval can span several rows (an impute-split reference).  The
# source parameter goes on the first row only, because calculating it under each
# split's imputation would make the reference lookup ambiguous; a user needing a
# different imputation requests the source parameter explicitly.
interval_complete_source_params <- function(intervals, ref_rows, source_params) {
  for (target in source_params) {
    target_requested <-
      vapply(X = intervals[[target]][ref_rows], FUN = isTRUE, FUN.VALUE = TRUE)
    if (!any(target_requested)) {
      intervals[[target]][ref_rows[1]] <- TRUE
    }
  }
  intervals
}

# The secondary parameters an intervals data.frame requests anywhere
interval_requested_secondary <- function(intervals) {
  candidates <- intersect(names(intervals), secondary_parameter_names())
  candidates[
    vapply(
      X = candidates,
      FUN = function(p) any(vapply(X = intervals[[p]], FUN = isTRUE, FUN.VALUE = TRUE)),
      FUN.VALUE = TRUE
    )
  ]
}

# Ensure every pointed-at reference interval requests the source parameters the
# link needs, and derive a reference for every request that has none.  Operates
# on (and returns) a working copy; pk.nca() never stores the modified intervals
# in the returned PKNCAresults.
#
# The automatic linkage is recorded in `data$secondary_auto`, a plain list
# element of the working copy (never an attribute on the intervals, which
# subsetting or joining could silently strip) that pk_nca_secondary() reads.
expand_secondary_intervals <- function(data) {
  current_intervals <- data$intervals
  requested_secondary <- interval_requested_secondary(current_intervals)
  if (length(requested_secondary) == 0) {
    return(data)
  }
  # Sparse data cannot supply a cross-interval reference at all, so any request
  # for a secondary parameter stops here whether or not it names a reference.
  if (is_sparse_pk(data)) {
    rlang::abort(
      "Secondary parameters are not yet supported with sparse data",
      class = "pknca_error_secondary_sparse_unsupported"
    )
  }
  for (p in requested_secondary) {
    rc <- paste0(p, "_ref")
    if (!(rc %in% names(current_intervals))) {
      next
    }
    rows <-
      which(
        !is.na(current_intervals[[rc]]) &
          vapply(X = current_intervals[[p]], FUN = isTRUE, FUN.VALUE = TRUE)
      )
    for (r in rows) {
      info <- secondary_param_info(p)
      ref_rows <-
        which(
          !is.na(current_intervals$interval_id) &
            current_intervals$interval_id == current_intervals[[rc]][r]
        )
      current_intervals <-
        interval_complete_source_params(
          current_intervals, ref_rows, unname(info$ref_args)
        )
    }
  }
  found <-
    expand_secondary_auto(
      current_intervals, requested_secondary, conc = data$conc,
      group_ref = data$group_ref
    )
  data$intervals <- found$intervals
  data$secondary_auto <- found$secondary_auto
  data
}

# Derive a reference interval for every request that has no pointer, creating or
# reusing the interval it needs.  Returns the working-copy intervals and the
# automatic-linkage ledgers.
#
# A request the finder cannot resolve is un-requested here so that the
# in-interval `pknca_error_secondary_needs_ref` abort never fires for it; the
# ledger carries the reason to pk_nca_secondary(), which reports it as an NA
# result (decision 5:  explicit links fail loud, automatic links degrade).
expand_secondary_auto <- function(intervals, requested_secondary, conc, group_ref) {
  links <- data.frame(param = character(0), ref_id = character(0))
  failures <- list()
  original_rows <- seq_len(nrow(intervals))
  for (p in requested_secondary) {
    ref_col <- paste0(p, "_ref")
    info <- secondary_param_info(p)
    for (r in original_rows) {
      unlinked <-
        isTRUE(intervals[[p]][r]) &&
        (!(ref_col %in% names(intervals)) || is.na(intervals[[ref_col]][r]))
      if (!unlinked || secondary_legacy_resolvable(intervals[r, , drop = FALSE], info)) {
        next
      }
      found <-
        find_secondary_reference(
          intervals, r, p, info, conc,
          group_ref = group_ref_for_param(group_ref, p)
        )
      if (is.null(found)) {
        # Not applicable:  the in-interval abort tells the user to give a
        # reference, because there is nothing in the data to derive one from.
        next
      } else if (is.character(found)) {
        failures[[length(failures) + 1L]] <-
          cbind(
            intervals[r, interval_describe_cols(intervals), drop = FALSE],
            data.frame(param = p, reason = found)
          )
        intervals[[p]][r] <- FALSE
      } else {
        linked <-
          interval_link_found_reference(
            intervals, r, p, found, unname(info$ref_args), conc, prefix = "autoref"
          )
        intervals <- linked$intervals
        links <-
          rbind(
            links,
            data.frame(
              param = p, ref_id = as.character(linked$id)
            )
          )
        rlang::inform(
          secondary_ref_created_text(p, linked),
          class = "pknca_message_secondary_ref_created"
        )
      }
    }
  }
  failures <-
    if (length(failures) == 0) {
      cbind(
        intervals[0, interval_describe_cols(intervals), drop = FALSE],
        data.frame(param = character(0), reason = character(0))
      )
    } else {
      do.call(rbind, failures)
    }
  rownames(failures) <- NULL
  list(intervals = intervals, secondary_auto = list(links = links, failures = failures))
}

# How the automatic linkage is announced.  Creating a whole reference interval
# is a change to the analysis, so it is disclosed (decision 4); adding a source
# parameter to it is not.
secondary_ref_created_text <- function(param, linked) {
  details <-
    paste(
      c(
        if (length(linked$override) > 0) {
          name_value_text(as.data.frame(linked$override))
        },
        sprintf("%s-%s", format(linked$start), format(linked$end))
      ),
      collapse = ", "
    )
  if (linked$created) {
    sprintf(
      "Secondary parameter '%s': created reference interval '%s' (%s).",
      param, as.character(linked$id), details
    )
  } else {
    sprintf(
      "Secondary parameter '%s': using (%s) as the reference interval '%s'.",
      param, details, as.character(linked$id)
    )
  }
}

# The parameters a one-row interval will calculate, including the dependencies
# that pk.nca.interval() expands before its calculation loop.
interval_expanded_params <- function(interval_row) {
  all_intervals <- get.interval.cols()
  for (n in rev(names(all_intervals))) {
    if (isTRUE(interval_row[[n]]) && length(all_intervals[[n]]$depends) > 0) {
      interval_row[all_intervals[[n]]$depends] <- TRUE
    }
  }
  interval_row
}

# TRUE when the parameter can be calculated on this row without any
# cross-interval linkage.  It mirrors the argument-resolution ladder of
# pk.nca.interval():  a column named after the formal supplies the value
# directly, or the reference target is calculated in this same interval (the
# historical same-interval renal clearance), which is disallowed when the target
# is also an own argument because test and reference would then be one value.
# The finder may only fire where that ladder would abort.
secondary_legacy_resolvable <- function(interval_row, info) {
  expanded <- interval_expanded_params(interval_row)
  all(vapply(
    X = seq_along(info$ref_args),
    FUN = function(i) {
      formal <- names(info$ref_args)[i]
      target <- info$ref_args[[i]]
      !is.null(interval_row[[formal]]) ||
        (!(target %in% info$own_args) && isTRUE(expanded[[target]]))
    },
    FUN.VALUE = TRUE
  ))
}

# Rows of `data` belonging to group combination `i` of `groups`
group_row_mask <- function(data, groups, i, group_cols) {
  ret <- rep(TRUE, nrow(data))
  for (col in group_cols) {
    ret <- ret & (data[[col]] %in% groups[[col]][i])
  }
  ret
}

# The group columns where candidate group `j` differs from the requesting
# group `i`
group_differing_cols <- function(groups, group_cols, i, j) {
  group_cols[
    !vapply(
      X = group_cols,
      FUN = function(col) groups[[col]][j] %in% groups[[col]][i],
      FUN.VALUE = TRUE
    )
  ]
}

# The reference group's values as they have to be written into the intervals:  a
# factor in the concentration data becomes the character the intervals hold.
interval_override_values <- function(groups, j, cols) {
  ret <- list()
  for (col in cols) {
    value <- groups[[col]][j]
    ret[[col]] <- if (is.factor(value)) as.character(value) else value
  }
  ret
}

# For one requesting intervals row and secondary parameter, derive the reference
# group's values from the data.  Returns a named list of group-column overrides
# on success, a character string holding the failure reason when there is no one
# reference to use, or NULL when the finder does not apply (the caller then
# leaves the request alone for the in-interval needs-reference abort).
#
# The rule is mechanical, never a list of parameter names:  the finder applies
# where the parameter measures an interval collection while everything it
# references is a spot sample (renal clearance) and the concentration data
# declare the collection volume that tells the two kinds of profile apart, or
# wherever `group_ref` names the reference profiles itself.
find_secondary_reference <- function(intervals, row, param, info, conc, group_ref) {
  st_applicable <-
    !is.null(conc) &&
    !is.null(conc$columns$volume) &&
    secondary_interval_over_spot(param)
  if (is.null(conc) || (is.null(group_ref) && !st_applicable)) {
    return(NULL)
  }
  group_cols <- unlist(conc$columns$groups)
  if (length(group_cols) == 0) {
    return("The concentration data have no groups, so no reference profile can be distinguished")
  }
  conc_data <- as.data.frame(conc)
  groups <- unique(conc_data[, group_cols, drop = FALSE])
  rownames(groups) <- NULL
  pool <- rep(TRUE, nrow(groups))
  if (st_applicable) {
    # A profile with a collection volume is an interval collection, so it is
    # what the parameter is calculated on rather than what it references.  Only
    # the sample-type rule reads the volume, and it applies only where the
    # concentration data declare one.
    has_volume <-
      vapply(
        X = seq_len(nrow(groups)),
        FUN = function(i) {
          volume <-
            conc_data[[conc$columns$volume]][group_row_mask(conc_data, groups, i, group_cols)]
          any(!is.na(volume) & volume > 0)
        },
        FUN.VALUE = TRUE
      )
    pool <- pool & !has_volume
  }
  if (!is.null(group_ref)) {
    pool <- pool & interval_match_groups(groups, group_ref)
  }
  if (!any(pool)) {
    return(
      if (is.null(group_ref)) {
        "No candidate reference profile is available in the data"
      } else {
        "No profile in the data matches `group_ref`"
      }
    )
  }
  own_mask <- rep(TRUE, nrow(groups))
  for (col in intersect(group_cols, names(intervals))) {
    own_mask <- own_mask & (groups[[col]] %in% intervals[[col]][row])
  }
  own_idx <- which(own_mask)
  if (length(own_idx) == 0) {
    return("The interval matches no group in the concentration data")
  }
  if (!is.null(group_ref) &&
      any(interval_match_groups(groups[own_idx, , drop = FALSE], group_ref))) {
    return("The interval's own group matches `group_ref`, so there is no distinct reference")
  }
  overrides <- list()
  reasons <- character(0)
  for (i in own_idx) {
    candidates <- setdiff(which(pool), i)
    if (length(candidates) == 0) {
      reasons <-
        c(
          reasons,
          sprintf(
            "No reference profile is available for %s",
            name_value_text(groups[i, , drop = FALSE])
          )
        )
      next
    }
    distance <-
      vapply(
        X = candidates,
        FUN = function(j) length(group_differing_cols(groups, group_cols, i, j)),
        FUN.VALUE = 1L
      )
    nearest <- candidates[distance %in% min(distance)]
    if (length(nearest) > 1) {
      tied_cols <-
        unique(unlist(lapply(
          X = nearest,
          FUN = function(j) group_differing_cols(groups, group_cols, i, j)
        )))
      reasons <-
        c(
          reasons,
          sprintf(
            "More than one reference profile is equally close (%s)",
            paste(
              sprintf("(%s)", name_value_text(groups[nearest, tied_cols, drop = FALSE])),
              collapse = ", "
            )
          )
        )
      next
    }
    differing <- group_differing_cols(groups, group_cols, i, nearest)
    inexpressible <- setdiff(differing, names(intervals))
    if (length(inexpressible) > 0) {
      reasons <-
        c(
          reasons,
          sprintf(
            "Add %s to the intervals so the reference can be expressed, or set '%s_ref'",
            paste(sprintf("'%s'", inexpressible), collapse = ", "), param
          )
        )
      next
    }
    overrides[[length(overrides) + 1L]] <- interval_override_values(groups, nearest, differing)
  }
  if (length(reasons) > 0) {
    return(paste(unique(reasons), collapse = "; "))
  }
  # One row carries one pointer, so every group the row applies to has to reach
  # the same reference.
  signatures <-
    vapply(
      X = overrides,
      FUN = function(x) name_value_text(as.data.frame(x)),
      FUN.VALUE = ""
    )
  if (length(unique(signatures)) > 1) {
    return(
      sprintf(
        "The interval's groups need different reference profiles (%s); set '%s_ref' or give `group_ref` to PKNCAdata()",
        paste(unique(signatures), collapse = "; "), param
      )
    )
  }
  overrides[[1]]
}

# Reuse or create the reference interval the finder derived, give it an
# identifier, and point `row` at it.  A created interval-over-spot reference
# spans the requesting row's collections whole, as a reference created by
# interval_add_secondary() does.
interval_link_found_reference <- function(intervals, row, param, override, source_params,
                                          conc, prefix = "ref") {
  ref_end <-
    if (!is.null(conc) && secondary_interval_over_spot(param)) {
      interval_collection_ends(intervals, row, conc)
    } else {
      NULL
    }
  if (is.null(ref_end)) {
    ref_end <- intervals$end[row]
  }
  match_mask <- intervals$start %in% intervals$start[row] & intervals$end %in% ref_end
  for (col in names(override)) {
    match_mask <- match_mask & (intervals[[col]] %in% override[[col]])
  }
  group_cols <- if (is.null(conc)) character(0) else unlist(conc$columns$groups)
  for (col in setdiff(intersect(group_cols, names(intervals)), names(override))) {
    match_mask <- match_mask & (intervals[[col]] %in% intervals[[col]][row])
  }
  match_mask[row] <- FALSE
  ref_rows <- which(match_mask)
  created <- length(ref_rows) == 0
  if (created) {
    new_rows <-
      interval_create_reference(
        intervals, row, as.data.frame(override), ends = ref_end
      )
    new_rows <- interval_complete_reference(new_rows, intervals, source_params)
    intervals <- rbind(intervals, new_rows)
    rownames(intervals) <- NULL
    ref_rows <- seq(to = nrow(intervals), length.out = nrow(new_rows))
  }
  assigned <- interval_assign_ref_ids(intervals, list(ref_rows), ref_id = NULL, prefix = prefix)
  intervals <- interval_sync_ref_cols(assigned$intervals, param)
  intervals[[param]][row] <- TRUE
  intervals[[paste0(param, "_ref")]][row] <- assigned$ids[[1]]
  intervals <- interval_complete_source_params(intervals, ref_rows, source_params)
  list(
    intervals = intervals,
    id = assigned$ids[[1]],
    created = created,
    ref_rows = ref_rows,
    override = override,
    start = intervals$start[ref_rows[1]],
    end = intervals$end[ref_rows[1]]
  )
}

# Clear reference pointers whose parameter is no longer requested on the row.
# interval_remove_param() calls this so that removing a secondary parameter
# also removes its linkage instead of leaving a pointer that fails
# check.interval.specification().
clear_orphan_ref_pointers <- function(intervals) {
  params <- intersect(names(intervals), names(get.interval.cols()))
  for (current_param in params) {
    ref_col <- paste0(current_param, "_ref")
    if (ref_col %in% names(intervals)) {
      orphan <-
        !is.na(intervals[[ref_col]]) &
        !vapply(X = intervals[[current_param]], FUN = isTRUE, FUN.VALUE = TRUE)
      intervals[[ref_col]][orphan] <- NA_character_
    }
  }
  intervals
}

# The single result value of `param` for one instance.  Returns
# list(value, exclude, n) with n the number of matching rows; the caller decides
# what n != 1 means.
secondary_lookup <- function(results, group_values, start, end, param, group_cols) {
  m <- results$PPTESTCD %in% param & results$start %in% start & results$end %in% end
  for (col in group_cols) {
    m <- m & (results[[col]] %in% group_values[[col]])
  }
  idx <- which(m)
  list(
    value = if (length(idx) == 1) results$PPORRES[idx] else NA_real_,
    exclude = if (length(idx) == 1) results$exclude[idx] else NA_character_,
    n = length(idx)
  )
}

# The distinct group combinations a secondary result is reported for:  one per
# group with any result in the requesting interval's selection `mask`.
secondary_instances <- function(results, mask, result_group_cols) {
  if (length(result_group_cols) > 0) {
    unique(results[mask, result_group_cols, drop = FALSE])
  } else if (any(mask)) {
    # Ungrouped data has one anonymous instance.  unique() cannot produce it:
    # duplicated() on a zero-column data.frame returns length zero before R 4.5,
    # and tibble refuses the zero-length subscript.
    data.frame(row.names = 1L)
  } else {
    data.frame()
  }
}

# The results row a secondary result is reported on:  the first row of the requesting
# instance, whose group values, times, and kept interval columns it copies.
secondary_template <- function(results, mask, group_values, result_group_cols) {
  ret <- results[mask, , drop = FALSE]
  ret[
    Reduce(
      `&`,
      lapply(result_group_cols, function(col) ret[[col]] %in% group_values[[col]]),
      # Ungrouped data has no group columns to match on, and every row of the
      # interval's selection is then the instance.
      rep(TRUE, nrow(ret))
    ), ,
    drop = FALSE
  ][1, , drop = FALSE]
}

# "Reference interval: PCSPEC=plasma, 0-24" -- how the reference differs from
# the requesting interval's own values, and its times.  The interval_id is tracking information
# rather than part of the analysis method, so it is not part of PPANMETH.
secondary_ppanmeth <- function(override_cols, own_group, ref_group, ref_start, ref_end) {
  differing <-
    override_cols[
      vapply(
        X = override_cols,
        FUN = function(col) !(ref_group[[col]] %in% own_group[[col]]),
        FUN.VALUE = TRUE
      )
    ]
  details <-
    c(
      if (length(differing) > 0) name_value_text(ref_group[differing]),
      sprintf("%s-%s", format(ref_start), format(ref_end))
    )
  sprintf("Reference interval: %s", paste(details, collapse = ", "))
}

stop_secondary_ambiguous <- function(param, target, group_values) {
  rlang::abort(
    sprintf(
      "More than one result found for '%s' (needed by secondary parameter '%s') for group %s. Differentiate the intervals (for example with distinct start/end or groups) so the reference is unique; if the reference interval is split for imputation, request '%s' on only one of its rows.",
      target, param, name_value_text(group_values), target
    ),
    class = "pknca_error_secondary_ambiguous_reference"
  )
}

stop_secondary_value_missing <- function(param, target, ref_id, group_values, side) {
  source_text <-
    if (identical(side, "reference")) {
      sprintf("the reference interval ('%s')", ref_id)
    } else {
      "this interval"
    }
  rlang::abort(
    sprintf(
      "The secondary parameter '%s' could not be calculated for group %s: the value '%s' from %s is not available. Calculate it in the linked intervals, restrict the interval rows to groups that have the data, or remove the request.",
      param, name_value_text(group_values), target, source_text
    ),
    class = "pknca_error_secondary_ref_value_missing"
  )
}

# The units assigned to `param` for one group, or NA when the units table
# cannot answer.  Deliberately forgiving: an absent table, an absent parameter
# row, and an ambiguous match all give NA, which reconciliation reads as "no
# units to reconcile" rather than turning a units gap into an error.
secondary_units_lookup <- function(units, group_values, param) {
  if (!is.data.frame(units) || !all(c("PPTESTCD", "PPORRESU") %in% names(units))) {
    return(NA_character_)
  }
  m <- units$PPTESTCD %in% param
  for (col in intersect(names(units), names(group_values))) {
    m <- m & (units[[col]] %in% group_values[[col]])
  }
  ret <- unique(units$PPORRESU[m])
  if (length(ret) == 1) as.character(ret) else NA_character_
}

# Express every reference-side input in the units of the requesting interval's
# own group, which are the units the result is reported in.  Group-stratified
# units let the two sides differ (a plasma AUC in hr*ng/mL feeding a renal
# clearance reported in mg/(hr*mg/L)), and the value must be converted before
# the calculation for the reported units to describe it.
#
# Returns the converted `inputs`, the reasons the instance cannot be calculated
# (empty when it can), the updated set of unit pairs already warned about, and
# the updated conversion factors already looked up.
#
# `seen` is the set of "<param>|<target>|<u_ref>|<u_own>" keys already warned
# about in this run, so that one non-convertible pair warns once however many
# instances it affects.  `factors` memoizes `pknca_unit_reconcile_factor()`,
# which is the same answer for every instance of a unit pair.
secondary_reconcile_units <- function(units, param, ref_args, inputs, own_group, ref_group, seen, factors) {
  reasons <- character(0)
  for (formal in names(ref_args)) {
    target <- ref_args[[formal]]
    u_own <- secondary_units_lookup(units, own_group, target)
    u_ref <- secondary_units_lookup(units, ref_group, target)
    if (is.na(u_own) || is.na(u_ref) || identical(u_own, u_ref)) {
      next
    }
    key <- paste(param, target, u_ref, u_own, sep = "|")
    if (!(key %in% names(factors))) {
      factors[[key]] <- pknca_unit_reconcile_factor(from = u_ref, to = u_own)
    }
    if (is.na(factors[[key]])) {
      # Fail loud:  a number reported in units that do not describe it is worse
      # than no number.
      reasons <-
        c(
          reasons,
          sprintf(
            "Units of '%s' differ between the reference ('%s') and this interval ('%s') and are not convertible",
            target, u_ref, u_own
          )
        )
      if (!(key %in% seen)) {
        seen <- c(seen, key)
        rlang::warn(
          sprintf(
            "Secondary parameter '%s': the units of '%s' differ between the reference ('%s') and the interval calculating it ('%s') and cannot be converted, so the results are NA (see the exclude column).",
            param, target, u_ref, u_own
          ),
          class = "pknca_warning_secondary_units"
        )
      }
    } else {
      inputs[[formal]] <- inputs[[formal]] * factors[[key]]
    }
  }
  list(inputs = inputs, reasons = reasons, seen = seen, factors = factors)
}

# Compute deferred secondary parameters from the combined results and append
# their rows.  `results` is the data.frame produced inside pk.nca() (group
# columns + start/end + keep_interval_cols + PPTESTCD/PPORRES/PPANMETH/exclude);
# `data_calc` is the PKNCAdata whose intervals carry the pointers (the expanded
# working copy).
pk_nca_secondary <- function(results, data_calc) {
  if (nrow(results) == 0 || !("PPTESTCD" %in% names(results))) {
    return(results)
  }
  current_intervals <- data_calc$intervals
  # The automatic-linkage ledger arrives as a list element of the working-copy
  # PKNCAdata (never as an attribute, which subsetting could strip); NULL when
  # no secondary parameter was requested at all.
  auto <- data_calc$secondary_auto
  params <- intersect(names(current_intervals), names(get.interval.cols()))
  ref_cols <- paste0(params, "_ref")
  present <- ref_cols %in% names(current_intervals)
  if (!any(present) && is.null(auto)) {
    return(results)
  }
  keep_cols <- data_calc$options$keep_interval_cols
  result_group_cols <-
    setdiff(
      names(results),
      c("start", "end", "PPTESTCD", "PPORRES", "PPANMETH", "exclude", keep_cols)
    )
  override_cols <- intersect(names(current_intervals), result_group_cols)
  # A reference-side value can only be in different units than the interval
  # calculating it when the units table assigns units by a group column that the
  # reference overrides; uniform units are the fast path.
  units_stratified <-
    is.data.frame(data_calc$units) &&
    length(intersect(names(data_calc$units), override_cols)) > 0
  units_seen <- character(0)
  units_factors <- list()
  # Reasons an automatically linked parameter could not be calculated, by
  # parameter:  one warning per parameter is raised for all of them together.
  auto_reasons <- list()
  new_rows <- list()
  for (i in which(present)) {
    p <- params[i]
    rc <- ref_cols[i]
    requested_rows <-
      which(
        !is.na(current_intervals[[rc]]) &
          vapply(X = current_intervals[[p]], FUN = isTRUE, FUN.VALUE = TRUE)
      )
    for (r in requested_rows) {
      info <- secondary_param_info(p)
      ref_id <- current_intervals[[rc]][r]
      is_auto <-
        !is.null(auto) &&
        any(auto$links$param %in% p & auto$links$ref_id %in% as.character(ref_id))
      ref_row <-
        which(
          !is.na(current_intervals$interval_id) &
            current_intervals$interval_id == ref_id
        )[1]
      # Home instances: distinct group combinations with any result for this
      # row's scope and times
      own_rows <-
        results$start %in% current_intervals$start[r] &
        results$end %in% current_intervals$end[r]
      for (col in override_cols) {
        own_rows <- own_rows & (results[[col]] %in% current_intervals[[col]][r])
      }
      instances <- secondary_instances(results, own_rows, result_group_cols)
      for (k in seq_len(nrow(instances))) {
        own_group <- instances[k, , drop = FALSE]
        ref_group <- own_group
        for (col in override_cols) {
          ref_group[[col]] <- current_intervals[[col]][ref_row]
        }
        inputs <- list()      # formal -> value
        excludes <- character(0)
        failed_reason <- NULL
        for (formal in names(info$own_args)) {
          found <-
            secondary_lookup(
              results, own_group,
              current_intervals$start[r], current_intervals$end[r],
              info$own_args[[formal]], result_group_cols
            )
          if (found$n > 1) stop_secondary_ambiguous(p, info$own_args[[formal]], own_group)
          if (found$n == 0) {
            # `depends` puts the interval's own value in the same interval, so an
            # instance with no own-side value has no result rows at all and is not
            # an instance:  the explicit-link abort defends a results table that
            # no calculation produces, while the automatic reason below is
            # reached through a results table built by hand.
            # nocov start
            if (!is_auto) {
              stop_secondary_value_missing(
                p, info$own_args[[formal]], ref_id, own_group, side = "own"
              )
            }
            # nocov end
            failed_reason <-
              sprintf(
                "Value '%s' is not available for the interval",
                info$own_args[[formal]]
              )
          }
          inputs[[formal]] <- found$value
          excludes <- c(excludes, found$exclude)
        }
        for (formal in names(info$ref_args)) {
          found <-
            secondary_lookup(
              results, ref_group,
              current_intervals$start[ref_row], current_intervals$end[ref_row],
              info$ref_args[[formal]], result_group_cols
            )
          if (found$n > 1) stop_secondary_ambiguous(p, info$ref_args[[formal]], ref_group)
          if (found$n == 0) {
            if (!is_auto) {
              stop_secondary_value_missing(
                p, info$ref_args[[formal]], ref_id, own_group, side = "reference"
              )
            }
            # An explicit link aborted just above, so a recorded reason belongs
            # to an automatic link, which degrades to NA instead (decision 5).
            failed_reason <-
              sprintf(
                "Reference value '%s' is not available from the reference interval",
                info$ref_args[[formal]]
              )
          }
          inputs[[formal]] <- found$value
          excludes <- c(excludes, found$exclude)
        }
        units_reasons <- character(0)
        if (units_stratified) {
          reconciled <-
            secondary_reconcile_units(
              data_calc$units, p, info$ref_args, inputs, own_group, ref_group,
              units_seen, units_factors
            )
          inputs <- reconciled$inputs
          units_reasons <- reconciled$reasons
          units_seen <- reconciled$seen
          units_factors <- reconciled$factors
        }
        if (is.null(failed_reason) && length(units_reasons) == 0) {
          value <- do.call(info$fun, inputs)
          excl <- combine_exclude_reasons(excludes, attr(value, "exclude"))
          value <- as.numeric(value)
        } else {
          # An automatic link with a value missing, or a reference value that
          # cannot be expressed in this interval's units, degrades to NA with the
          # reason.  Only the first is a linkage failure to warn about below; the
          # units gap has already warned for itself.
          value <- NA_real_
          excl <- combine_exclude_reasons(c(excludes, failed_reason, units_reasons), NULL)
          if (!is.null(failed_reason)) {
            auto_reasons[[p]] <- c(auto_reasons[[p]], failed_reason)
          }
        }
        template <- secondary_template(results, own_rows, own_group, result_group_cols)
        template$PPTESTCD <- p
        template$PPORRES <- value
        template$PPANMETH <-
          secondary_ppanmeth(
            override_cols, own_group, ref_group,
            current_intervals$start[ref_row], current_intervals$end[ref_row]
          )
        template$exclude <- excl
        new_rows[[length(new_rows) + 1L]] <- template
      }
    }
  }
  # Requests the finder could not resolve were un-requested on the working copy,
  # so nothing calculated them; they are reported as NA with the reason.
  if (!is.null(auto) && nrow(auto$failures) > 0) {
    for (i in seq_len(nrow(auto$failures))) {
      failure <- auto$failures[i, , drop = FALSE]
      p <- failure$param
      auto_reasons[[p]] <- c(auto_reasons[[p]], failure$reason)
      own_rows <- results$start %in% failure$start & results$end %in% failure$end
      for (col in intersect(setdiff(names(failure), c("param", "reason")), result_group_cols)) {
        own_rows <- own_rows & (results[[col]] %in% failure[[col]])
      }
      instances <- secondary_instances(results, own_rows, result_group_cols)
      for (k in seq_len(nrow(instances))) {
        template <-
          secondary_template(
            results, own_rows, instances[k, , drop = FALSE], result_group_cols
          )
        template$PPTESTCD <- p
        template$PPORRES <- NA_real_
        template$PPANMETH <- NA_character_
        template$exclude <- failure$reason
        new_rows[[length(new_rows) + 1L]] <- template
      }
    }
  }
  for (p in names(auto_reasons)) {
    rlang::warn(
      sprintf(
        "Secondary parameter '%s': no reference value could be determined for %d interval(s), so the results are NA (see the exclude column).  %s.  Set '%s_ref' in the interval specification, give `group_ref` to PKNCAdata(), or use interval_add_secondary().",
        p, length(auto_reasons[[p]]), paste(unique(auto_reasons[[p]]), collapse = ".  "), p
      ),
      class = "pknca_warning_secondary_auto_reference"
    )
  }
  if (length(new_rows) == 0) results else dplyr::bind_rows(results, new_rows)
}

# Authoring the linkage ---------------------------------------------------
#
# interval_add_secondary() writes the `interval_id` and `<parameter>_ref`
# columns the engine above reads.  Unlike the engine's expansion, everything it
# does is visible in the intervals it returns.

# The columns that say *which* interval a row is:  not the parameter requests,
# not the linkage columns, and not the imputation.
interval_describe_cols <- function(intervals) {
  all_params <- names(get.interval.cols())
  setdiff(
    names(intervals),
    c(
      setdiff(all_params, c("start", "end")),
      paste0(all_params, "_ref"),
      "interval_id", "impute"
    )
  )
}

# The value an interval column takes when it is not requested, as
# check.interval.specification() assigns it for an absent column.  `start` and
# `end` are the only columns validated by a function instead of a set of allowed
# values, and neither is ever defaulted here.
interval_default_value <- function(param) {
  get.interval.cols()[[param]]$values[1]
}

# Ensure the named parameter columns exist, unrequested
interval_ensure_param_cols <- function(intervals, params) {
  for (current_param in setdiff(params, names(intervals))) {
    intervals[[current_param]] <- interval_default_value(current_param)
  }
  intervals
}

# Keep the pointer columns comparable with `interval_id`:  create the one for
# `param` when it is absent or unfilled, and give every pointer column the
# identifier column's levels, since generating an identifier adds one.
interval_sync_ref_cols <- function(intervals, param) {
  ref_col <- paste0(param, "_ref")
  if (!(ref_col %in% names(intervals)) ||
      (is.logical(intervals[[ref_col]]) && all(is.na(intervals[[ref_col]])))) {
    intervals[[ref_col]] <- intervals$interval_id[rep(NA_integer_, nrow(intervals))]
  }
  if (is.factor(intervals$interval_id)) {
    all_ref_cols <- intersect(paste0(names(get.interval.cols()), "_ref"), names(intervals))
    for (col in all_ref_cols) {
      if (is.factor(intervals[[col]]) &&
          !identical(levels(intervals[[col]]), levels(intervals$interval_id))) {
        intervals[[col]] <-
          factor(as.character(intervals[[col]]), levels = levels(intervals$interval_id))
      }
    }
  }
  intervals
}

# "ref1", "ref2", ... skipping any identifier already in use.  `prefix` is
# "autoref" for the identifiers the automatic reference finder generates, so
# that an engine-generated identifier is told apart from a user-visible one.
interval_next_ref_names <- function(used, n, prefix = "ref") {
  ret <- character(0)
  k <- 0L
  while (length(ret) < n) {
    k <- k + 1L
    candidate <- paste0(prefix, k)
    if (!(candidate %in% used)) {
      ret <- c(ret, candidate)
    }
  }
  ret
}

# `n` new interval identifiers matching the class of the `interval_id` column,
# because identifiers may be of any comparable class:  "ref1", "ref2", ... for
# character (skipping ids already in use), `max + 1` for numbers, and new levels
# for a factor.  An absent or unfilled (all-NA logical) column takes character
# identifiers, and is created here so the caller can assign into it.
interval_new_ids <- function(intervals, n, prefix = "ref") {
  existing <- intervals$interval_id
  if (is.null(existing) || (is.logical(existing) && all(is.na(existing)))) {
    intervals$interval_id <- NA_character_
    existing <- character(0)
  }
  if (is.factor(existing)) {
    ids <-
      interval_next_ref_names(
        unique(c(levels(existing), as.character(stats::na.omit(existing)))), n,
        prefix = prefix
      )
    # Appending keeps every existing level at its position, so the values in
    # this and every other linkage column are unchanged; the pointer columns
    # gain the new levels in interval_sync_ref_cols(), which runs after every
    # id assignment, so the shared-levels comparability rule of
    # check_interval_id_classes() still holds.
    levels(intervals$interval_id) <- c(levels(existing), ids)
  } else if (is.numeric(existing)) {
    highest <- if (all(is.na(existing))) 0 else max(existing, na.rm = TRUE)
    ids <- highest + seq_len(n)
  } else {
    ids <- interval_next_ref_names(as.character(stats::na.omit(existing)), n, prefix = prefix)
  }
  list(intervals = intervals, ids = ids)
}

# Give every reference interval an identifier:  `ref_id` when the user named
# one, the identifier the rows already share, or a newly generated one.
#
# `ref_id = NULL` (the default) takes the third branch for any reference
# interval with no identifier:  `need_new` marks it and interval_new_ids()
# generates one, creating the `interval_id` column itself when the intervals
# have none.  The `!is.null(ref_id)` block below only covers the user-named
# case, where the column must exist (matching `ref_id`'s class) before the
# assignment loop writes into it.
interval_assign_ref_ids <- function(intervals, ref_groups, ref_id, prefix = "ref") {
  ids <- vector(mode = "list", length = length(ref_groups))
  need_new <- rep(FALSE, length(ref_groups))
  for (i in seq_along(ref_groups)) {
    current <-
      if (is.null(intervals$interval_id)) {
        NULL
      } else {
        stats::na.omit(intervals$interval_id[ref_groups[[i]]])
      }
    if (!is.null(ref_id)) {
      ids[[i]] <- ref_id
    } else if (length(current) > 0) {
      ids[[i]] <- current[1]
    } else {
      need_new[i] <- TRUE
    }
  }
  if (!is.null(ref_id) &&
      (is.null(intervals$interval_id) ||
       (is.logical(intervals$interval_id) && all(is.na(intervals$interval_id))))) {
    intervals$interval_id <- ref_id[rep(NA_integer_, nrow(intervals))]
  }
  if (any(need_new)) {
    generated <- interval_new_ids(intervals, sum(need_new), prefix = prefix)
    intervals <- generated$intervals
    ids[need_new] <- as.list(generated$ids)
  }
  for (i in seq_along(ref_groups)) {
    rows <- ref_groups[[i]]
    blank_rows <- if (is.null(ref_id)) rows[is.na(intervals$interval_id[rows])] else rows
    intervals$interval_id[blank_rows] <- ids[[i]]
  }
  list(intervals = intervals, ids = ids)
}

# The reference rows grouped into the distinct intervals they describe
interval_reference_groups <- function(intervals, ref_rows) {
  describe_cols <- interval_describe_cols(intervals)
  signature <-
    do.call(
      paste,
      c(
        lapply(X = intervals[ref_rows, describe_cols, drop = FALSE], FUN = as.character),
        sep = "\r"
      )
    )
  lapply(X = unique(signature), FUN = function(x) ref_rows[signature %in% x])
}

# Which of the reference intervals a test row uses.  One reference serves every
# test row; several are told apart by matching the test row's own times, or by
# a single reference covering them (a created reference can be wider than its
# test interval when it spans whole collections).
interval_pick_reference <- function(intervals, row, ref_groups, param) {
  if (length(ref_groups) == 1) {
    return(1L)
  }
  same_time <-
    which(vapply(
      X = ref_groups,
      FUN = function(rows) {
        (intervals$start[rows[1]] %in% intervals$start[row]) &&
          (intervals$end[rows[1]] %in% intervals$end[row])
      },
      FUN.VALUE = TRUE
    ))
  if (length(same_time) == 1) {
    return(same_time)
  }
  covering <-
    which(vapply(
      X = ref_groups,
      FUN = function(rows) {
        (intervals$start[rows[1]] <= intervals$start[row]) &&
          (intervals$end[rows[1]] >= intervals$end[row])
      },
      FUN.VALUE = TRUE
    ))
  if (length(covering) == 1) {
    return(covering)
  }
  rlang::abort(
    sprintf(
      "`reference` matched %d reference intervals and none of them is the single reference for '%s' in interval row %d. Narrow `reference` (for example by adding `start` and `end` columns) so that each interval has one reference.",
      length(ref_groups), param, row
    ),
    class = "pknca_error_secondary_ref_ambiguous_spec"
  )
}

# Does `param` pair an interval collection with spot-sample references?  Renal
# clearance is the case in PKNCA:  an amount excreted against a plasma AUC.
secondary_interval_over_spot <- function(param) {
  cls <- parameter_classification()
  targets <- unname(secondary_param_info(param)$ref_args)
  identical(cls$sample_type[[param]], "interval") &&
    length(targets) > 0 &&
    all(vapply(
      X = targets,
      FUN = function(x) identical(cls$sample_type[[x]], "spot"),
      FUN.VALUE = TRUE
    ))
}

# The end each test interval's spot-sample reference must reach so that it
# spans the test interval's collections whole.  A collection that begins inside
# the interval contributes its full amount (see filter_interval()), so a
# collection running past `end` extends what the paired spot-sample
# calculations must cover.
interval_collection_ends <- function(intervals, test_rows, conc) {
  duration_col <- conc$columns$duration
  time_col <- conc$columns$time
  if (is.null(duration_col) || is.null(time_col)) {
    return(NULL)
  }
  conc_data <- conc$data[is.na(normalize_exclude(conc)), , drop = FALSE]
  scope_cols <-
    intersect(
      setdiff(interval_describe_cols(intervals), c("start", "end")),
      names(conc_data)
    )
  ret <- intervals$end[test_rows]
  for (i in seq_along(test_rows)) {
    r <- test_rows[i]
    m <-
      !is.na(conc_data[[time_col]]) &
      conc_data[[time_col]] >= intervals$start[r] &
      conc_data[[time_col]] <= intervals$end[r] &
      !is.na(conc_data[[duration_col]]) &
      conc_data[[duration_col]] > 0
    for (col in scope_cols) {
      m <- m & (conc_data[[col]] %in% intervals[[col]][r])
    }
    if (any(m)) {
      ret[i] <-
        max(ret[i], max(conc_data[[time_col]][m] + conc_data[[duration_col]][m]))
    }
  }
  ret
}

# Build the reference rows for an interval specification that has none:  the
# test rows with the `reference` values applied.  `impute` is dropped, so a
# created row takes the whole-dataset imputation.  `ends` (when given) widens
# each created row to span the test row's collections; an explicit `end` in
# `reference` still overrides it below.
interval_create_reference <- function(intervals, test_rows, reference, ends = NULL) {
  base <- intervals[test_rows, interval_describe_cols(intervals), drop = FALSE]
  if (!is.null(ends)) {
    base$end <- ends
  }
  ret_list <- list()
  for (i in seq_len(nrow(reference))) {
    current <- base
    for (col in names(reference)) {
      current[[col]] <- reference[[col]][i]
    }
    ret_list[[i]] <- current
  }
  ret <- unique(do.call(rbind, ret_list))
  rownames(ret) <- NULL
  ret
}

# Fill the columns a created reference row does not have:  nothing is
# calculated on it but the source parameters the linkage needs.
interval_complete_reference <- function(created, intervals, source_params) {
  for (col in setdiff(names(intervals), names(created))) {
    created[[col]] <-
      if (col %in% names(get.interval.cols())) {
        interval_default_value(col)
      } else if (identical(col, "impute")) {
        NA_character_
      } else {
        intervals[[col]][rep(NA_integer_, nrow(created))]
      }
  }
  for (target in source_params) {
    created[[target]] <- TRUE
  }
  created[, names(intervals), drop = FALSE]
}

assert_secondary_param <- function(intervals, param) {
  checkmate::assert_data_frame(intervals, min.rows = 1)
  checkmate::assert_character(param, len = 1, any.missing = FALSE)
  assert_param_name(param)
  if (!isTRUE(parameter_classification()$secondary[[param]])) {
    rlang::abort(
      sprintf(
        "'%s' is not a secondary parameter; use interval_add_param() instead",
        param
      ),
      class = "pknca_error_secondary_not_secondary_param"
    )
  }
  invisible(param)
}

interval_secondary_validate <- function(intervals, param, reference, ref_id) {
  reference <- as.data.frame(reference)
  checkmate::assert_data_frame(reference, min.rows = 1, min.cols = 1)
  invalid <- setdiff(names(reference), interval_describe_cols(intervals))
  if (length(invalid) > 0) {
    rlang::abort(
      sprintf(
        "Column(s) in `reference` must be `start`, `end`, or a group column of the intervals: %s",
        paste(invalid, collapse = ", ")
      ),
      class = "pknca_error_interval_target_groups_cols"
    )
  }
  checkmate::assert_scalar(ref_id, na.ok = FALSE, null.ok = TRUE)
  reference
}

# Link `param` on the test rows to the reference the automatic finder derives
# from the data.  Everything the finder decides is written into the returned
# intervals, and a test row it cannot resolve is an error:  this is an explicit
# request for the linkage, not the engine's opportunistic pass, so there is no
# result to degrade to NA.
interval_secondary_auto <- function(intervals, param, target_groups, conc) {
  info <- secondary_param_info(param)
  source_params <- unname(info$ref_args)
  test_rows <-
    if (is.null(target_groups)) {
      seq_len(nrow(intervals))
    } else {
      which(interval_match_groups(intervals, target_groups))
    }
  if (length(test_rows) == 0) {
    rlang::warn(
      sprintf("No intervals are left to calculate '%s' on.  No changes made.", param),
      class = "pknca_warning_interval_no_target_rows"
    )
    return(intervals)
  }
  intervals <- interval_ensure_param_cols(intervals, c(param, source_params))
  created_text <- character(0)
  for (row in test_rows) {
    found <- find_secondary_reference(intervals, row, param, info, conc, group_ref = NULL)
    if (is.null(found) || is.character(found)) {
      rlang::abort(
        sprintf(
          "The reference interval for '%s' could not be determined from the data for interval row %d%s. Give `reference`, give `group_ref` to PKNCAdata(), or restrict the rows with `target_groups`.",
          param, row,
          if (is.character(found)) sprintf(": %s", found) else ""
        ),
        class = "pknca_error_secondary_needs_ref"
      )
    }
    linked <-
      interval_link_found_reference(intervals, row, param, found, source_params, conc)
    intervals <- linked$intervals
    if (linked$created) {
      created_text <-
        c(
          created_text,
          name_value_text(
            intervals[linked$ref_rows, interval_describe_cols(intervals), drop = FALSE]
          )
        )
    }
  }
  if (length(created_text) > 0) {
    rlang::inform(
      sprintf(
        "Created reference interval(s) for '%s': %s",
        param, paste(unique(created_text), collapse = "; ")
      ),
      class = "pknca_message_secondary_created_interval"
    )
  }
  rownames(intervals) <- NULL
  check.interval.specification(intervals)
}

# Link `param` on the test rows to the reference interval `reference` describes,
# creating that interval when the specification does not have it yet.  `conc`
# (a PKNCAconc, given by the PKNCAdata method) lets a created spot-sample
# reference span the test rows' collections whole, and `group_ref` (from the
# same object) names the reference profiles when `reference` does not.
interval_edit_secondary <- function(intervals, param, reference, target_groups, ref_id,
                                    conc = NULL, group_ref = NULL) {
  assert_secondary_param(intervals, param)
  if (is.null(reference) && !is.null(group_ref)) {
    group_ref <- group_ref_for_param(group_ref, param)
  }
  if (is.null(reference) && !is.null(group_ref)) {
    # `group_ref` steers the engine's finder; naming it here is the same
    # statement, so it describes the reference interval directly.
    reference <- group_ref
  }
  if (is.null(reference)) {
    return(interval_secondary_auto(intervals, param, target_groups, conc))
  }
  reference <- interval_secondary_validate(intervals, param, reference, ref_id)
  source_params <- unname(secondary_param_info(param)$ref_args)
  ref_rows <- which(interval_match_groups(intervals, reference))
  test_rows <-
    if (is.null(target_groups)) {
      setdiff(seq_len(nrow(intervals)), ref_rows)
    } else {
      setdiff(which(interval_match_groups(intervals, target_groups)), ref_rows)
    }
  if (length(test_rows) == 0) {
    rlang::warn(
      sprintf("No intervals are left to calculate '%s' on.  No changes made.", param),
      class = "pknca_warning_interval_no_target_rows"
    )
    return(intervals)
  }
  intervals <- interval_ensure_param_cols(intervals, c(param, source_params))
  if (length(ref_rows) == 0) {
    creation_ends <-
      if (!is.null(conc) && secondary_interval_over_spot(param)) {
        interval_collection_ends(intervals, test_rows, conc)
      } else {
        NULL
      }
    created <-
      interval_create_reference(intervals, test_rows, reference, ends = creation_ends)
    created <- interval_complete_reference(created, intervals, source_params)
    rlang::inform(
      sprintf(
        "Created reference interval(s) for '%s': %s",
        param,
        paste(
          name_value_text(created[, interval_describe_cols(created), drop = FALSE]),
          collapse = "; "
        )
      ),
      class = "pknca_message_secondary_created_interval"
    )
    intervals <- rbind(intervals, created)
    rownames(intervals) <- NULL
    ref_rows <- seq(to = nrow(intervals), length.out = nrow(created))
  }
  ref_groups <- interval_reference_groups(intervals, ref_rows)
  if (!is.null(ref_id) && length(ref_groups) > 1) {
    rlang::abort(
      sprintf(
        "`ref_id` names one reference interval, but `reference` matched %d of them. Narrow `reference` (for example by adding `start` and `end` columns) or leave `ref_id` unset.",
        length(ref_groups)
      ),
      class = "pknca_error_secondary_ref_ambiguous_spec"
    )
  }
  assigned <- interval_assign_ref_ids(intervals, ref_groups, ref_id)
  intervals <- interval_sync_ref_cols(assigned$intervals, param)
  ref_col <- paste0(param, "_ref")
  used_groups <- integer(0)
  for (row in test_rows) {
    current_group <- interval_pick_reference(intervals, row, ref_groups, param)
    current_id <- assigned$ids[[current_group]]
    current_pointer <- intervals[[ref_col]][row]
    if (!is.na(current_pointer) &&
        !identical(as.character(current_pointer), as.character(current_id))) {
      rlang::warn(
        sprintf(
          "Interval row %d already gives a reference interval ('%s') for '%s'; it was left unchanged.",
          row, as.character(current_pointer), param
        ),
        class = "pknca_warning_secondary_ref_exists"
      )
      next
    }
    intervals[[param]][row] <- TRUE
    intervals[[ref_col]][row] <- current_id
    used_groups <- c(used_groups, current_group)
  }
  # An impute-split reference interval spans several rows:
  # interval_reference_groups() groups by everything except the parameter
  # requests and `impute`, so all of its rows arrive together here.
  for (current_group in unique(used_groups)) {
    intervals <-
      interval_complete_source_params(intervals, ref_groups[[current_group]], source_params)
  }
  rownames(intervals) <- NULL
  check.interval.specification(intervals)
}

#' Link a secondary parameter to the interval it is calculated against
#'
#' A secondary parameter needs a result from a second profile:  renal clearance
#' divides an amount excreted in urine by a plasma AUC, an accumulation ratio
#' compares one dosing interval with another, and a metabolite ratio compares
#' two analytes.  This adds the request and the linkage columns
#' (`interval_id` on the reference interval and `<param>_ref` on the intervals
#' calculating the parameter) that [pk.nca()] reads.
#'
#' @inheritParams interval_add_impute
#' @param param The name of one secondary NCA parameter (see
#'   [pknca_parameter_table()] for which parameters are secondary).
#' @param reference A data.frame describing the reference interval:  its
#'   columns are `start`, `end`, and/or group columns of the intervals, every
#'   column must match (and) for at least one of its rows (or).  A named list is
#'   accepted and coerced.  When no interval matches, one is created and the
#'   creation is reported with a `pknca_message_secondary_created_interval`
#'   message.  `NULL` (the default) takes the `group_ref` given to
#'   [PKNCAdata()] (resolved for `param` when it is parameter-specific), or
#'   derives the reference from the data (see Details).
#' @param target_groups A data.frame of group values restricting the parameter
#'   request to matching intervals, with the same matching rules as `reference`.
#'   `NULL` (the default) requests it on every interval that is not a reference
#'   interval.
#' @param ref_id The `interval_id` to give the reference interval.  The default
#'   of `NULL` keeps an identifier the reference rows already have and
#'   otherwise generates one matching the class of the `interval_id` column.
#' @returns The input with the parameter requested and the linkage columns set,
#'   after [check.interval.specification()].
#' @details The reference interval gains whatever the linked calculation reads
#'   from it (the plasma AUC for a renal clearance, for example) without being
#'   announced, as calculating any dependency is.
#'
#'   An interval that already names a different reference for `param` is left
#'   alone with a `pknca_warning_secondary_ref_exists` warning, so that the
#'   helper never silently re-points an analysis.
#'
#'   With `reference = NULL` the reference is derived from the data, which needs
#'   a `PKNCAdata` object (a bare intervals data.frame carries no concentrations
#'   to derive it from).  The `group_ref` given to [PKNCAdata()] is used when it
#'   is set.  Otherwise the derivation applies where the parameter is measured on
#'   an interval collection while everything it references is a spot sample
#'   (renal clearance) and the concentration data declare a collection `volume`:
#'   each interval takes the profile with no collection volume that differs from
#'   its own in the fewest group columns.  This is the same derivation
#'   [pk.nca()] makes on its own, written out into the returned intervals
#'   instead of being ephemeral.  Anything the derivation cannot resolve is an
#'   error here (`pknca_error_secondary_needs_ref`) rather than the `NA` result
#'   the automatic path gives, so narrow the request with `target_groups` when
#'   some intervals are not meant to calculate `param`.
#'
#'   When the parameter pairs an interval collection with spot-sample
#'   references (renal clearance:  an amount excreted against a plasma AUC)
#'   and the reference interval is created by the `PKNCAdata` method, the
#'   created interval spans the collections whole:  a collection that begins
#'   inside the interval contributes its full amount (see [pk.nca()]), so a
#'   collection running past the interval's `end` extends the created
#'   reference's `end` to `time + duration` of the latest collection.  An
#'   explicit `end` in `reference` overrides the extension, and the data.frame
#'   method (which has no concentration data) copies the test interval's times
#'   unchanged.
#' @seealso [interval_add_param()], [pknca_ref()], [pk.nca()]
#' @family Interval specifications
#' @examples
#' intervals <-
#'   data.frame(
#'     PCSPEC = c("plasma", "urine"),
#'     start = 0, end = 24,
#'     auclast = c(TRUE, FALSE),
#'     ae = c(FALSE, TRUE)
#'   )
#' interval_add_secondary(
#'   intervals,
#'   param = "clr.last",
#'   reference = data.frame(PCSPEC = "plasma")
#' )
#' @export
interval_add_secondary <- function(data, param, reference = NULL,
                                   target_groups = NULL, ref_id = NULL, ...) {
  UseMethod("interval_add_secondary", data)
}

#' @export
interval_add_secondary.data.frame <- function(data, param, reference = NULL,
                                              target_groups = NULL, ref_id = NULL, ...) {
  interval_edit_secondary(
    data, param = param, reference = reference, target_groups = target_groups,
    ref_id = ref_id
  )
}

#' @export
interval_add_secondary.PKNCAdata <- function(data, param, reference = NULL,
                                             target_groups = NULL, ref_id = NULL, ...) {
  data$intervals <-
    interval_edit_secondary(
      data$intervals, param = param, reference = reference,
      target_groups = target_groups, ref_id = ref_id,
      conc = data$conc, group_ref = data$group_ref
    )
  data
}

