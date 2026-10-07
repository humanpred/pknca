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
#' the sparse estimators), and [sparse_bootstrap_summary()] and
#' [sparse_bootstrap_compare()] summarize the replicates.
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
#' sparse_bootstrap_summary(pk.nca(o_data_boot))
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
  data <- object$data_sparse
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

  previous_seed <- sparse_bootstrap_get_seed()
  on.exit(sparse_bootstrap_set_seed(previous_seed), add = TRUE)
  set.seed(seed)
  replicates <- vector(mode = "list", length = n_boot + 1)
  original <- data
  original[[replicate_col]] <- "original"
  original[[subject_col_new]] <- as.character(data[[subject_col]])
  replicates[[1]] <- original
  for (current_boot in seq_len(n_boot)) {
    rows <- integer()
    draws <- character()
    # By position:  a single group's name is "", which [[ cannot look up
    for (current_group in seq_along(rows_by_group)) {
      for (current_stratum in strata[[current_group]]) {
        drawn <- current_stratum$subjects[sample.int(length(current_stratum$subjects), replace = TRUE)]
        for (current_draw in seq_along(drawn)) {
          subject_rows <- current_stratum$rows[[drawn[current_draw]]]
          rows <- c(rows, subject_rows)
          draws <- c(draws, rep(paste0(drawn[current_draw], "_", current_draw), length(subject_rows)))
        }
      }
    }
    current_data <- data[rows, , drop = FALSE]
    current_data[[replicate_col]] <- paste0("bootstrap", current_boot)
    current_data[[subject_col_new]] <- draws
    replicates[[current_boot + 1]] <- current_data
  }
  ret <- object
  ret$data_sparse <- do.call(rbind, replicates)
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

# The random number state of the session (NULL if none), so that it can be
# restored after the resampling
sparse_bootstrap_get_seed <- function() {
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
    get(".Random.seed", envir = globalenv(), inherits = FALSE)
  } else {
    NULL
  }
}

sparse_bootstrap_set_seed <- function(seed) {
  if (is.null(seed)) {
    if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  } else {
    assign(".Random.seed", seed, envir = globalenv())
  }
}

# The long results of a bootstrap pk.nca() run, with an excluded result set to
# NA and the sparse standard errors and degrees of freedom (which describe one
# replicate, not the bootstrap) dropped
sparse_bootstrap_results <- function(object) {
  checkmate::assert_class(object, "PKNCAresults")
  bootstrap <- object$data$conc$bootstrap
  if (is.null(bootstrap)) {
    rlang::abort(
      "The results are not from a bootstrap; calculate them from the PKNCAconc object that sparse_bootstrap() returns",
      class = "pknca_error_bootstrap_not_bootstrap"
    )
  }
  ret <- as.data.frame(object, filter_excluded = FALSE)
  exclude_col <- object$columns$exclude
  if (!is.null(exclude_col) && exclude_col %in% names(ret)) {
    ret$PPORRES[!is.na(ret[[exclude_col]]) & nzchar(ret[[exclude_col]])] <- NA_real_
  }
  ret <- ret[!(ret$PPTESTCD %in% sparse_only_params()), , drop = FALSE]
  # The columns that identify a result (the groups, the interval, and the
  # parameter), apart from the replicate
  value_cols <- c("PPORRES", "PPORRESU", "PPSTRES", "PPSTRESU", "PPANMETH", exclude_col)
  attr(ret, "key_cols") <- setdiff(names(ret), c(value_cols, bootstrap$replicate_col))
  attr(ret, "bootstrap") <- bootstrap
  ret
}

#' Summarize the parameters of a sparse bootstrap
#'
#' For each parameter of each group and interval, the estimate from the
#' original data is given with the arithmetic mean, standard deviation,
#' geometric mean, and geometric coefficient of variation of the bootstrap
#' replicates and their percentile confidence interval.  The bootstrap standard
#' deviation is the standard error of the estimate.
#'
#' @param object The [pk.nca()] results from the `PKNCAconc` object that
#'   [sparse_bootstrap()] returns
#' @param conf_level The confidence level of the percentile interval
#' @returns A data.frame with the groups (without the replicate column),
#'   `start`, `end`, `PPTESTCD`, the `estimate` from the original data, the
#'   number of replicates (`n_boot`) and of those with a value (`n`), `mean`,
#'   `sd`, `geomean`, `geocv` (percent), and the percentile interval
#'   (`ci_lower` and `ci_upper`).  The geometric statistics use the positive
#'   values (with [business.geomean()] and [business.geocv()]).
#' @family Sparse Methods
#' @export
sparse_bootstrap_summary <- function(object, conf_level = 0.95) {
  checkmate::assert_number(conf_level, lower = 0, upper = 1)
  results <- sparse_bootstrap_results(object)
  bootstrap <- attr(results, "bootstrap")
  key_cols <- attr(results, "key_cols")
  key <- do.call(paste, c(unname(as.list(results[key_cols])), sep = "\r"))
  probs <- c((1 - conf_level)/2, 1 - (1 - conf_level)/2)
  rows <- list()
  for (current_rows in split(seq_len(nrow(results)), factor(key, levels = unique(key)))) {
    current <- results[current_rows, , drop = FALSE]
    is_original <- current[[bootstrap$replicate_col]] == "original"
    boot_values <- current$PPORRES[!is_original]
    boot_ok <- boot_values[!is.na(boot_values)]
    boot_positive <- boot_ok[boot_ok > 0]
    interval <-
      if (length(boot_ok) > 0) {
        unname(stats::quantile(boot_ok, probs = probs, names = FALSE))
      } else {
        c(NA_real_, NA_real_)
      }
    rows[[length(rows) + 1]] <-
      data.frame(
        current[1, key_cols, drop = FALSE],
        estimate = if (any(is_original)) current$PPORRES[is_original][1] else NA_real_,
        n_boot = bootstrap$n_boot,
        n = length(boot_ok),
        mean = if (length(boot_ok) > 0) mean(boot_ok) else NA_real_,
        sd = if (length(boot_ok) > 1) stats::sd(boot_ok) else NA_real_,
        geomean = if (length(boot_positive) > 0) business.geomean(boot_positive) else NA_real_,
        geocv = if (length(boot_positive) > 1) business.geocv(boot_positive) else NA_real_,
        ci_lower = interval[1],
        ci_upper = interval[2],
        check.names = FALSE
      )
  }
  ret <- do.call(rbind, rows)
  rownames(ret) <- NULL
  attr(ret, "conf_level") <- conf_level
  attr(ret, "seed") <- bootstrap$seed
  ret
}

#' Compare groups with a sparse bootstrap (bioequivalence)
#'
#' The ratio of each test group to the reference group is calculated for every
#' bootstrap replicate, and its percentile interval is the confidence interval
#' for the ratio (Shen and Machado 2017).  With a parallel design, the groups
#' are resampled independently; with a crossover, give the treatment column as
#' `paired` to [sparse_bootstrap()] so that each replicate draws the same
#' animals for every treatment.  The ratio of the estimates from the original
#' data is the point estimate.
#'
#' @param object The [pk.nca()] results from the `PKNCAconc` object that
#'   [sparse_bootstrap()] returns
#' @param reference_col The group column with the treatments to compare
#' @param reference_value The reference level of `reference_col`
#' @param parameters The parameters (`PPTESTCD`) to compare; `NULL` compares all
#' @param conf_level The confidence level of the percentile interval; 0.90 for
#'   the usual bioequivalence assessment
#' @param limits The acceptance limits for the ratio, in percent
#' @returns A data.frame with one row per parameter, test level, interval, and
#'   other group:  the other groups, `start`, `end`, `endpoint` (the
#'   parameter), `test`, `reference`, the estimates from the original data
#'   (`estimate_test` and `estimate_reference`), the number of replicates with
#'   a ratio (`n`), the ratio and its percentile interval in percent
#'   (`ratio_percent`, `ci_lower`, and `ci_upper`), `limit_lower`,
#'   `limit_upper`, and `pass` (the interval is within the limits).
#' @references
#' Shen M, Machado SG.  Bioequivalence evaluation of sparse sampling
#' pharmacokinetics data using bootstrap resampling method.  Journal of
#' Biopharmaceutical Statistics.  2017;27(2):257-264.
#' doi:10.1080/10543406.2016.1265543
#' @family Sparse Methods
#' @family Bioequivalence
#' @export
sparse_bootstrap_compare <- function(object, reference_col, reference_value,
                                     parameters = NULL, conf_level = 0.90,
                                     limits = be_expand_limits(0, "ABE")) {
  results <- sparse_bootstrap_results(object)
  bootstrap <- attr(results, "bootstrap")
  checkmate::assert_string(reference_col)
  checkmate::assert_choice(reference_col, choices = setdiff(attr(results, "key_cols"), c("start", "end", "PPTESTCD")))
  checkmate::assert_choice(as.character(reference_value), choices = as.character(unique(results[[reference_col]])))
  checkmate::assert_character(parameters, any.missing = FALSE, null.ok = TRUE)
  checkmate::assert_number(conf_level, lower = 0, upper = 1)
  checkmate::assert_numeric(limits, len = 2, any.missing = FALSE, sorted = TRUE)
  if (!is.null(parameters)) {
    results <- results[results$PPTESTCD %in% parameters, , drop = FALSE]
  }
  other_cols <- setdiff(attr(results, "key_cols"), reference_col)
  is_reference <- as.character(results[[reference_col]]) == as.character(reference_value)
  reference <- results[is_reference, , drop = FALSE]
  test <- results[!is_reference, , drop = FALSE]
  match_cols <- c(other_cols, bootstrap$replicate_col)
  reference_key <- do.call(paste, c(unname(as.list(reference[match_cols])), sep = "\r"))
  test$reference_value <- reference$PPORRES[match(do.call(paste, c(unname(as.list(test[match_cols])), sep = "\r")), reference_key)]
  test$ratio <- test$PPORRES/test$reference_value
  key <- do.call(paste, c(unname(as.list(test[c(other_cols, reference_col)])), sep = "\r"))
  probs <- c((1 - conf_level)/2, 1 - (1 - conf_level)/2)
  rows <- list()
  for (current_rows in split(seq_len(nrow(test)), factor(key, levels = unique(key)))) {
    current <- test[current_rows, , drop = FALSE]
    is_original <- current[[bootstrap$replicate_col]] == "original"
    boot_ratio <- current$ratio[!is_original]
    boot_ratio <- boot_ratio[is.finite(boot_ratio)]
    interval <-
      if (length(boot_ratio) > 0) {
        100*unname(stats::quantile(boot_ratio, probs = probs, names = FALSE))
      } else {
        c(NA_real_, NA_real_)
      }
    original <- current[is_original, , drop = FALSE]
    rows[[length(rows) + 1]] <-
      data.frame(
        current[1, setdiff(other_cols, "PPTESTCD"), drop = FALSE],
        endpoint = current$PPTESTCD[1],
        test = as.character(current[[reference_col]][1]),
        reference = as.character(reference_value),
        estimate_test = if (nrow(original) > 0) original$PPORRES[1] else NA_real_,
        estimate_reference = if (nrow(original) > 0) original$reference_value[1] else NA_real_,
        n = length(boot_ratio),
        ratio_percent = if (nrow(original) > 0) 100*original$ratio[1] else NA_real_,
        ci_lower = interval[1],
        ci_upper = interval[2],
        limit_lower = unname(limits[1]),
        limit_upper = unname(limits[2]),
        pass = interval[1] >= limits[1] & interval[2] <= limits[2],
        check.names = FALSE
      )
  }
  ret <- do.call(rbind, rows)
  rownames(ret) <- NULL
  attr(ret, "conf_level") <- conf_level
  attr(ret, "seed") <- bootstrap$seed
  ret
}
