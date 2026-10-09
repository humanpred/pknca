#' Bootstrap resampling of sparse PK data
#'
#' `sparse_bootstrap()` makes a new sparse [PKNCAconc()] object holding the
#' original data and `n_boot` bootstrap replicates of it, following the
#' stratified nonparametric bootstrap of Shen and Machado (2017).  Each
#' replicate resamples the animals with replacement within each stratum, where
#' the stratum is the set of times an animal was sampled:  each sampling time
#' with serial sacrifice, or each batch in a batch design.  An animal's samples
#' stay together, so the correlation between samples from the same animal is
#' kept.  [pk.nca()] then calculates every parameter for every replicate the
#' same way as for the original data (from the arithmetic-mean profile, or with
#' the sparse estimators).  Its results summarize the replicates with
#' [summary()][summary.PKNCAresults_sparse_bootstrap()], and [be_assess()]
#' compares groups with the percentile intervals of the replicates.
#'
#' The replicates are a new group (`replicate_col`) with the values
#' `"original"` (the data as given) and `"bootstrap1"` through
#' `"bootstrap<n_boot>"`.  A resampled animal gets a new subject identifier
#' (`<replicate_col>_subject`, the original subject with the draw number) so
#' that an animal drawn twice counts as two animals.
#'
#' Groups named in `paired`, and the analytes (the groups after `/` in the
#' formula), are resampled together:  an animal drawn for a replicate brings
#' its samples from every level of those groups.  Use `paired` for a crossover,
#' where each animal (or eye, as in Shen and Machado 2017) receives each
#' treatment.  Other groups (such as the treatment of a parallel design) are
#' resampled independently.
#'
#' The `"original"` replicate holds the data as given, so the same [pk.nca()]
#' run also gives the estimates.
#'
#' @param object A sparse `PKNCAconc` object
#' @param n_boot The number of bootstrap replicates.  The default of 200 is
#'   enough for the mean and standard deviation of the parameters (Takemoto et
#'   al. 2006); percentile confidence intervals need more replicates to be
#'   stable.
#' @param seed The random seed for the resampling.  When `NULL`, one is drawn
#'   (from the current random number stream) and stored in the result, so the
#'   replicates can always be reproduced.  The random number state of the
#'   session is restored afterward.
#' @param paired Group columns whose levels each animal has, so they are
#'   resampled together (for example, the treatment of a crossover design)
#' @param replicate_col The name of the replicate group column to add
#' @returns A sparse `PKNCAconc` object with the original data and the
#'   replicates.  Its `bootstrap` element records `n_boot`, `seed`, `paired`,
#'   `replicate_col`, and the original `subject` column.
#' @references
#' Shen M, Machado SG.  Bioequivalence evaluation of sparse sampling
#' pharmacokinetics data using bootstrap resampling method.  Journal of
#' Biopharmaceutical Statistics.  2017;27(2):257-264.
#' doi:10.1080/10543406.2016.1265543
#'
#' Takemoto S, Yamaoka K, Nishikawa M, Takakura Y.  Histogram analysis of
#' pharmacokinetic parameters by bootstrap resampling from one-point sampling
#' data in animal experiments.  Drug Metabolism and Pharmacokinetics.
#' 2006;21(6):458-464.  doi:10.2133/dmpk.21.458
#' @examples
#' d_sparse <-
#'   data.frame(
#'     time = rep(c(0, 1, 2, 4, 8, 24), each = 3),
#'     conc = c(0, 0, 0, 5, 6, 4, 8, 7, 9, 6, 5, 7, 3, 2.5, 3.5, 0.6, 0.4, 0.5)
#'   )
#' d_sparse$animal <- seq_len(nrow(d_sparse))
#' o_conc <- PKNCAconc(d_sparse, conc ~ time | animal, sparse = TRUE)
#' o_conc_boot <- sparse_bootstrap(o_conc, n_boot = 20, seed = 1)
#' o_data_boot <-
#'   PKNCAdata(o_conc_boot, intervals = data.frame(start = 0, end = 24, auclast = TRUE, cmax = TRUE))
#' summary(pk.nca(o_data_boot))
#' @family Sparse Methods
#' @export
sparse_bootstrap <- function(object, n_boot = 200, seed = NULL, paired = NULL,
                             replicate_col = "bootstrap") {
  checkmate::assert_class(object, "PKNCAconc")
  if (!is_sparse_pk(object)) {
    rlang::abort(
      "sparse_bootstrap() resamples sparse data; give `sparse = TRUE` to PKNCAconc()",
      class = "pknca_error_bootstrap_not_sparse"
    )
  }
  if (!is.null(object$bootstrap)) {
    rlang::abort(
      "The PKNCAconc object is already a bootstrap; resample the original data instead",
      class = "pknca_error_bootstrap_already"
    )
  }
  checkmate::assert_count(n_boot, positive = TRUE)
  checkmate::assert_count(seed, null.ok = TRUE)
  checkmate::assert_string(replicate_col, min.chars = 1)
  subject_col <- object$columns$subject
  group_cols <- object$columns$groups$group_vars
  analyte_cols <- object$columns$groups$group_analyte
  checkmate::assert_subset(paired, choices = setdiff(group_cols, subject_col))
  subject_col_new <- paste0(replicate_col, "_subject")
  data <- as.data.frame(object)
  clash <- intersect(c(replicate_col, subject_col_new), names(data))
  if (length(clash) > 0) {
    rlang::abort(
      sprintf("The data already have the column(s) %s; choose another `replicate_col`", paste(clash, collapse = ", ")),
      class = "pknca_error_bootstrap_column_exists"
    )
  }
  if (is.null(seed)) {
    seed <- sample.int(.Machine$integer.max, 1)
  }
  # Each resampling group is resampled on its own; the paired groups and the
  # analytes travel with the animal
  resample_cols <- setdiff(group_cols, c(subject_col, paired))
  resample_key <-
    if (length(resample_cols) > 0) {
      do.call(paste, c(unname(as.list(data[resample_cols])), sep = "\r"))
    } else {
      rep("", nrow(data))
    }
  rows_by_group <- split(seq_len(nrow(data)), resample_key)
  strata <- lapply(rows_by_group, sparse_bootstrap_strata, data = data, subject_col = subject_col, time_col = object$columns$time)

  original <- data
  original[[replicate_col]] <- "original"
  original[[subject_col_new]] <- as.character(data[[subject_col]])
  replicates <-
    withr::with_seed(
      seed,
      lapply(
        X = seq_len(n_boot), FUN = sparse_bootstrap_draw,
        data = data, strata = strata, replicate_col = replicate_col, subject_col_new = subject_col_new
      )
    )
  ret <- object
  ret$data_sparse <- do.call(rbind, c(list(original), replicates))
  rownames(ret$data_sparse) <- NULL
  idx_subject <- which(group_cols == subject_col)
  ret$columns$groups$group_vars <-
    append(group_cols[-idx_subject], c(replicate_col, subject_col_new), after = idx_subject - 1)
  ret$columns$subject <- subject_col_new
  ret$formula <-
    stats::as.formula(
      paste0(
        ret$columns$concentration, "~", ret$columns$time, "|",
        paste(ret$columns$groups$group_vars, collapse = "+"),
        if (length(analyte_cols) > 0) paste0("/", paste(analyte_cols, collapse = "+"))
      )
    )
  ret$bootstrap <-
    list(
      n_boot = n_boot, seed = seed, paired = paired,
      replicate_col = replicate_col, subject = subject_col
    )
  ret
}

# The strata of one resampling group:  the animals grouped by the set of times
# they were sampled, each with the rows of every animal
sparse_bootstrap_strata <- function(rows, data, subject_col, time_col) {
  subjects <- as.character(data[[subject_col]][rows])
  rows_by_subject <- split(rows, factor(subjects, levels = unique(subjects)))
  signature <- stats::setNames(character(length(rows_by_subject)), names(rows_by_subject))
  for (current_subject in names(rows_by_subject)) {
    signature[current_subject] <-
      paste(sort(unique(data[[time_col]][rows_by_subject[[current_subject]]])), collapse = "\r")
  }
  ret <- list()
  for (current_signature in sort(unique(signature))) {
    stratum_subjects <- names(signature)[signature == current_signature]
    ret[[length(ret) + 1]] <-
      list(subjects = stratum_subjects, rows = rows_by_subject[stratum_subjects])
  }
  ret
}

# One bootstrap replicate:  in each resampling group and stratum, as many
# animals as the stratum has are drawn with replacement, each with all of its
# rows and a new subject identifier for the draw
sparse_bootstrap_draw <- function(current_boot, data, strata, replicate_col, subject_col_new) {
  rows <- integer()
  draws <- character()
  for (group_strata in strata) {
    for (current_stratum in group_strata) {
      drawn <- current_stratum$subjects[sample.int(length(current_stratum$subjects), replace = TRUE)]
      for (current_draw in seq_along(drawn)) {
        subject_rows <- current_stratum$rows[[drawn[current_draw]]]
        rows <- c(rows, subject_rows)
        draws <- c(draws, rep(paste0(drawn[current_draw], "_", current_draw), length(subject_rows)))
      }
    }
  }
  ret <- data[rows, , drop = FALSE]
  ret[[replicate_col]] <- paste0("bootstrap", current_boot)
  ret[[subject_col_new]] <- draws
  ret
}

# The animals in the original data of a bootstrap PKNCAconc object, with the
# `groups` columns
sparse_bootstrap_animals <- function(conc, groups) {
  bootstrap <- conc$bootstrap
  data <- as.data.frame(conc)
  data <- data[data[[bootstrap$replicate_col]] == "original", , drop = FALSE]
  unique(data.frame(data[groups], .subject = data[[bootstrap$subject]]))
}

# The number of animals for each combination of `key_cols` in `animals` (from
# sparse_bootstrap_animals()), as a table named by sparse_bootstrap_key().  An
# animal is a subject within its unpaired groups, which may reuse subject
# identifiers for different animals; a paired group (such as a crossover's
# treatment) has the same animals in each level, so it does not count them
# again.
sparse_bootstrap_count_animals <- function(animals, key_cols, paired) {
  identity_cols <- c(setdiff(names(animals), c(".subject", paired)), ".subject")
  counted <-
    unique(data.frame(
      key = sparse_bootstrap_key(animals, key_cols),
      identity = sparse_bootstrap_key(animals, identity_cols)
    ))
  table(counted$key)
}

# A key identifying the combination of `cols` in each row of `data` ("" when
# there are no columns)
sparse_bootstrap_key <- function(data, cols) {
  if (length(cols) > 0) {
    do.call(paste, c(unname(as.list(data[cols])), sep = "\r"))
  } else {
    rep("", nrow(data))
  }
}

#' Summarize the results of a sparse bootstrap
#'
#' The bootstrap replicates (see [sparse_bootstrap()]) are summarized the way
#' subjects are for dense data (see [summary.PKNCAresults()]), with each
#' parameter's summary statistics from [PKNCA.set.summary()]:  for example, the
#' geometric mean and geometric coefficient of variation of the replicates'
#' AUClast.  `N` is the number of animals in the study, and the caption gives
#' the number of bootstrap replicates and the random seed.  The original data
#' and the sparse standard errors of single replicates are not part of the
#' summary.  For confidence intervals and comparisons between groups, see
#' [be_assess()].
#'
#' @inheritParams summary.PKNCAresults
#' @param drop_group Groups to drop from the summary, in addition to the
#'   bootstrap replicate
#' @param summarize_n Should a column for `N`, the number of animals in the
#'   study, be added?  `NA` (the default) and `TRUE` add it.
#' @returns A data frame of the summarized bootstrap results (see
#'   [summary.PKNCAresults()])
#' @family Sparse Methods
#' @export
summary.PKNCAresults_sparse_bootstrap <- function(object, ..., drop_group = character(), summarize_n = NA) {
  conc <- as_PKNCAconc(object)
  bootstrap <- conc$bootstrap
  replicate_col <- bootstrap$replicate_col
  # The animals are counted first:  filtering the replicate column also drops
  # the original data from the concentrations
  animals <-
    sparse_bootstrap_animals(
      conc, setdiff(dplyr::group_vars(conc), c(replicate_col, conc$columns$subject))
    )
  # The replicates are summarized like subjects; the original data and the
  # sparse standard errors of single replicates are not part of that
  replicate_sym <- rlang::sym(replicate_col)
  parameter_sym <- rlang::sym("PPTESTCD")
  object <-
    dplyr::filter(
      object, !!replicate_sym != "original", !(!!parameter_sym %in% sparse_only_params())
    )
  drop_group <- union(replicate_col, drop_group)
  ret <- summary.PKNCAresults(object, ..., drop_group = drop_group, summarize_n = FALSE)
  caption <- attr(ret, "caption")
  if (!isFALSE(summarize_n)) {
    group_cols <- intersect(get_summary_PKNCAresults_drop_group(object = object, drop_group = drop_group), names(ret))
    n_cols <- intersect(group_cols, names(animals))
    n_study <- sparse_bootstrap_count_animals(animals, n_cols, bootstrap$paired)
    n_value <- as.character(as.vector(n_study[match(sparse_bootstrap_key(ret, n_cols), names(n_study))]))
    # N follows the groups, as in summary.PKNCAresults()
    n_position <- max(c(0L, match(group_cols, names(ret))))
    ret <-
      data.frame(
        ret[seq_len(n_position)], N = n_value, ret[setdiff(seq_along(ret), seq_len(n_position))],
        check.names = FALSE
      )
    caption <- paste0(caption, "; N: number of animals in the study")
  }
  as_summary_PKNCAresults(
    ret,
    caption =
      paste0(
        caption,
        sprintf("; summarized over %d bootstrap replicates (seed %d)", bootstrap$n_boot, bootstrap$seed)
      )
  )
}

#' @describeIn be_dataset The replicates of a sparse bootstrap, one row per
#'   replicate, treatment, and endpoint
#' @export
be_dataset.PKNCAresults_sparse_bootstrap <- function(object, reference_col, reference_value,
                                                     endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
                                                     subject = NULL, sequence = NULL, period = NULL,
                                                     covariates = NULL, ...) {
  conc <- as_PKNCAconc(object)
  bootstrap <- conc$bootstrap
  given <- c(subject = !is.null(subject), sequence = !is.null(sequence), period = !is.null(period), covariates = !is.null(covariates))
  if (any(given)) {
    rlang::abort(
      sprintf(
        "A sparse bootstrap has no subject-level model, so %s cannot be given",
        paste(names(given)[given], collapse = ", ")
      ),
      class = "pknca_error_be_bootstrap_argument"
    )
  }
  data <- as.data.frame(as.data.frame(object, filter_excluded = TRUE))
  data <- data[!(data$PPTESTCD %in% sparse_only_params()), , drop = FALSE]
  group_cols <- setdiff(names(getGroups(object)), c("start", "end", bootstrap$replicate_col))
  checkmate::assert_string(reference_col)
  checkmate::assert_choice(reference_col, choices = group_cols)
  value_unit_cols <- .be_value_unit_cols(data)
  reference_value <- .be_check_reference(data, reference_col, reference_value)
  other_cols <- setdiff(group_cols, reference_col)
  other_levels <- unique(data[, other_cols, drop = FALSE])
  if (nrow(other_levels) > 1) {
    rlang::abort(
      sprintf(
        "A sparse bootstrap comparison needs one level of the groups other than `reference_col`; filter the results to one level of %s",
        paste(other_cols, collapse = ", ")
      ),
      class = "pknca_error_be_bootstrap_groups"
    )
  }
  data <- data[!is.na(data[[value_unit_cols$value]]) & data[[value_unit_cols$value]] > 0, , drop = FALSE]
  present <- .be_check_endpoints(data, endpoints)
  data <- data[data$PPTESTCD %in% present, , drop = FALSE]
  intervals <- unique(data[, c("PPTESTCD", "start", "end")])
  if (anyDuplicated(intervals$PPTESTCD) > 0) {
    rlang::abort(
      "A sparse bootstrap comparison needs one interval per endpoint; filter the results to one interval",
      class = "pknca_error_be_bootstrap_intervals"
    )
  }
  data$.trt <- stats::relevel(factor(as.character(data[[reference_col]])), ref = reference_value)
  data$.replicate <- data[[bootstrap$replicate_col]]
  data$.value <- data[[value_unit_cols$value]]
  data$.units <- if (!is.na(value_unit_cols$units)) as.character(data[[value_unit_cols$units]]) else NA_character_
  structure(
    list(
      data = data,
      columns = list(
        treatment = reference_col, value = value_unit_cols$value,
        units = value_unit_cols$units, replicate = bootstrap$replicate_col
      ),
      reference_value = reference_value,
      test_levels = setdiff(levels(data$.trt), reference_value),
      endpoints = present,
      animals = sparse_bootstrap_animals(conc, reference_col),
      design = if (reference_col %in% bootstrap$paired) "crossover" else "parallel",
      bootstrap = bootstrap
    ),
    class = c("be_dataset_sparse_bootstrap", "be_dataset")
  )
}

# The estimate (from the original data) and the percentile interval of the
# replicates of one treatment and endpoint, or of a ratio; `values` are named
# by replicate
sparse_bootstrap_interval <- function(values, probs) {
  boot <- values[names(values) != "original"]
  boot <- boot[is.finite(boot)]
  interval <-
    if (length(boot) > 0) {
      unname(stats::quantile(boot, probs = probs, names = FALSE))
    } else {
      c(NA_real_, NA_real_)
    }
  list(estimate = unname(values["original"]), lower = interval[1], upper = interval[2])
}

# The values of one treatment and endpoint, named by replicate
sparse_bootstrap_values <- function(data, treatment, endpoint) {
  rows <- data$.trt == treatment & data$PPTESTCD == endpoint
  stats::setNames(data$.value[rows], data$.replicate[rows])
}

# The number of animals in a comparison of a test with the reference
sparse_bootstrap_n_compared <- function(ds, test) {
  treatments <- c(ds$reference_value, test)
  animals <- ds$animals[as.character(ds$animals[[ds$columns$treatment]]) %in% treatments, , drop = FALSE]
  sum(sparse_bootstrap_count_animals(animals, character(), ds$bootstrap$paired))
}

#' @describeIn be_assess Bioequivalence from the percentile intervals of a
#'   sparse bootstrap (Shen and Machado 2017)
#' @export
be_assess.PKNCAresults_sparse_bootstrap <- function(object, reference_col, reference_value,
                                                    endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
                                                    regulator = "ABE", model_type = NULL, alpha = 0.10,
                                                    subject = NULL, sequence = NULL, period = NULL, design = NULL,
                                                    covariates = NULL, heteroscedastic = FALSE, ...) {
  assert_numeric_between(alpha, lower = 0, upper = 1)
  reg <- be_regulator(regulator)
  if (!identical(reg$scaling, "none")) {
    rlang::abort(
      sprintf(
        "The %s framework scales by the within-subject variability, which a sparse bootstrap does not have; use \"ABE\" or \"descriptive\"",
        reg$name
      ),
      class = "pknca_error_be_bootstrap_scaled"
    )
  }
  if (!is.null(model_type) && !identical(model_type, "bootstrap")) {
    rlang::abort(
      "The results of a sparse bootstrap are assessed with `model_type = \"bootstrap\"`",
      class = "pknca_error_be_bootstrap_model_type"
    )
  }
  if (!is.null(design) || !isFALSE(heteroscedastic)) {
    rlang::abort(
      "A sparse bootstrap has no subject-level model, so `design` and `heteroscedastic` cannot be given",
      class = "pknca_error_be_bootstrap_argument"
    )
  }
  ds <- be_dataset(object, reference_col, reference_value, endpoints, subject, sequence, period, covariates)
  probs <- c(alpha/2, 1 - alpha/2)
  params <- list()
  for (current_endpoint in ds$endpoints) {
    reference <- sparse_bootstrap_values(ds$data, ds$reference_value, current_endpoint)
    reference_interval <- sparse_bootstrap_interval(reference, probs)
    for (current_test in ds$test_levels) {
      test <- sparse_bootstrap_values(ds$data, current_test, current_endpoint)
      test_interval <- sparse_bootstrap_interval(test, probs)
      both <- intersect(names(test), names(reference))
      ratio_interval <- sparse_bootstrap_interval(test[both]/reference[both], probs)
      units <- unique(ds$data$.units[ds$data$PPTESTCD == current_endpoint])
      # The columns that be_table() reads for a framework without reference
      # scaling, with no within-subject variances
      params[[length(params) + 1]] <-
        data.frame(
          endpoint = current_endpoint, test = current_test,
          n = sparse_bootstrap_n_compared(ds, current_test),
          units = units[1],
          gm_reference = reference_interval$estimate,
          gm_reference_lower = reference_interval$lower,
          gm_reference_upper = reference_interval$upper,
          gm_test = test_interval$estimate,
          gm_test_lower = test_interval$lower,
          gm_test_upper = test_interval$upper,
          model_gmr_percent = 100*ratio_interval$estimate,
          model_ci_lower = 100*ratio_interval$lower,
          model_ci_upper = 100*ratio_interval$upper,
          model_df = NA_real_,
          swr = NA_real_, swt = NA_real_, cvwr_percent = NA_real_, cvwt_percent = NA_real_,
          df_wr = NA_real_, df_wt = NA_real_, sw_ratio = NA_real_, sw_ratio_ci_upper = NA_real_
        )
    }
  }
  tbl <- be_table(do.call(rbind, params), reg, alpha, design = ds$design, model_type = "bootstrap")
  tbl <-
    .be_table_finish(
      tbl, ds,
      caption = .be_caption(reg, "bootstrap", alpha, n_boot = ds$bootstrap$n_boot)
    )
  .be_assess_object(tbl, alpha)
}
