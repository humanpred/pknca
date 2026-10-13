# The result files of vignette("v24-sparse-auc-to-infinity") come from the
# targets pipeline in data-raw/sparse-simulation/.  The vignette reads their
# fields and summary columns by name, so a pipeline change that renames one
# fails here rather than in the vignette build.  The files are read from the
# source tree's vignettes/ directory, so the test runs with devtools::test()
# and skips under R CMD check, as the other source-tree tests do.

# For each file:  the fields of the list, the columns of each summary, and the
# intervals or methods the vignette looks up
sparse_vignette_results <- list(
  "v24-sparse-auc-to-infinity-simulation.rds" = list(
    fields = c(
      "summary", "scenarios", "model", "model_1cmt", "model_2cmt", "sampling_times", "batch_times",
      "n_serial", "n_batch", "n_replicates", "n_virtual", "truth_mcse_percent", "seed_base",
      "pknca_version", "pmxtools_version", "r_version", "run_date"
    ),
    summaries = list(
      summary = c(
        "scenario", "route", "design", "blq", "elimination", "compartments", "method", "parameter",
        "relative_bias", "rmse", "median_absolute_error", "median_ci_width", "coverage", "coverage_mcse",
        "percent_extrapolated"
      )
    ),
    values = list(summary = list(method = c("delta", "individual", "yuan")))
  ),
  "v24-sparse-auc-to-infinity-bootstrap.rds" = list(
    fields = c("summary", "n_boot", "n_replicates", "seed_base", "pknca_version", "r_version", "run_date"),
    summaries = list(
      summary = c(
        "scenario", "route", "design", "blq", "elimination", "compartments", "parameter",
        "coverage_percentile", "coverage_normal", "median_ci_width_percentile"
      )
    ),
    values = list()
  ),
  "v24-sparse-auc-to-infinity-bootstrap-n.rds" = list(
    fields = c("summary", "n_per_time", "n_boot", "n_replicates", "truth", "pknca_version", "r_version", "run_date"),
    summaries = list(
      summary = c("n_per_time", "blq", "method", "parameter", "coverage", "median_ci_width", "median_bias")
    ),
    values = list(summary = list(method = c("boot_se", "delta", "percentile", "yuan")))
  ),
  "v24-sparse-auc-to-infinity-tobit.rds" = list(
    fields = c(
      "summary", "scenarios", "n_per_time", "profile_scenario", "n_boot", "n_se_replicates",
      "n_profile_replicates", "pknca_version", "r_version", "run_date"
    ),
    summaries = list(
      summary = c(
        "scenario", "n_per_time", "interval", "lambda_z_method", "parameter", "coverage", "median_bias",
        "median_absolute_error"
      )
    ),
    values = list(
      summary = list(
        interval = c(
          "log-linear bootstrap", "log-linear delta", "log-linear yuan", "tobit-individual bootstrap",
          "tobit-individual yuan+var", "tobit-mean bootstrap", "tobit-mean yuan"
        )
      )
    )
  ),
  "v24-sparse-auc-to-infinity-mean-type.rds" = list(
    fields = c("summary", "targets", "n_replicates", "n_virtual", "pknca_version", "pmxtools_version", "run_date"),
    summaries = list(
      summary = c(
        "scenario", "route", "design", "blq", "elimination", "compartments", "mean_type", "parameter",
        "bias_natural", "bias_typical", "robust_cv"
      )
    ),
    values = list(summary = list(mean_type = c("arithmetic", "geometric")))
  ),
  "v24-sparse-auc-to-infinity-comparisons.rds" = list(
    fields = c(
      "summary", "profile_summary", "n_per_time", "n_replicates", "n_profile_replicates", "n_boot",
      "pk_nsample", "wj_nsample", "n_tail", "large_n_summary", "n_large_replicates", "large_n_per_time",
      "pknca_version", "pk_version", "r_version", "run_date"
    ),
    summaries = list(
      summary = c(
        "scenario", "route", "design", "blq", "elimination", "compartments", "n_per_time", "interval",
        "parameter", "n_attempted", "n", "coverage", "coverage_mcse", "median_ci_width", "relative_bias",
        "median_bias", "percent_fallback"
      ),
      profile_summary = c("scenario", "blq", "n_per_time", "interval", "parameter", "coverage", "median_ci_width"),
      large_n_summary = c("scenario", "elimination", "estimator", "relative_bias", "relative_bias_mcse")
    ),
    values = list(
      summary = list(
        interval = c(
          "pk boot-t", "pk z", "pknca boot-t", "pknca delta", "pknca percentile", "pknca yuan",
          "wj2005 boot-t", "wj2005 z"
        ),
        parameter = c("auc", "aumc", "cl", "half_life_nc", "mrt", "vss")
      ),
      profile_summary = list(interval = c("pknca boot-t", "pknca delta", "pknca percentile", "pknca yuan")),
      large_n_summary = list(estimator = c("pknca", "wj2005"))
    )
  ),
  "v24-sparse-auc-to-infinity-blq.rds" = list(
    fields = c("summary", "fallbacks", "n_replicates", "pknca_version", "bloq_version", "r_version", "run_date"),
    summaries = list(
      summary = c(
        "scenario", "route", "design", "elimination", "compartments", "interval", "coverage",
        "median_ci_width", "median_bias", "percent_fallback"
      ),
      fallbacks = c("scenario", "interval", "percent_with_fallback", "percent_with_negative")
    ),
    values = list(
      summary = list(
        interval = c(
          "cml_direct z", "cml_impute delta", "half_lloq delta", "kernel delta", "ros delta", "zero delta"
        )
      )
    )
  )
)

test_that("the sparse vignette's result files have the fields, columns, and versions it reads", {
  vignette_dir <- test_path("..", "..", "vignettes")
  skip_if_not(dir.exists(vignette_dir), "The package source is needed")
  for (current_file in names(sparse_vignette_results)) {
    spec <- sparse_vignette_results[[current_file]]
    path <- file.path(vignette_dir, current_file)
    expect_true(file.exists(path), label = current_file)
    result <- readRDS(path)
    expect_type(result, "list")
    expect_equal(setdiff(spec$fields, names(result)), character(), label = paste(current_file, "missing fields"))
    for (current_summary in names(spec$summaries)) {
      expect_s3_class(result[[current_summary]], "data.frame")
      expect_equal(
        setdiff(spec$summaries[[current_summary]], names(result[[current_summary]])),
        character(),
        label = paste(current_file, current_summary, "missing columns")
      )
      expect_gt(nrow(result[[current_summary]]), 0)
    }
    for (current_summary in names(spec$values)) {
      for (current_column in names(spec$values[[current_summary]])) {
        expect_setequal(
          unique(result[[current_summary]][[current_column]]),
          spec$values[[current_summary]][[current_column]]
        )
      }
    }
    # Every version field is a version string, and the run date a date
    for (current_field in grep("_version$", names(result), value = TRUE)) {
      expect_match(result[[current_field]], "^[0-9]+([.-][0-9]+)+$|^R version [0-9.]+ ", label = paste(current_file, current_field))
    }
    expect_match(result$run_date, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", label = paste(current_file, "run_date"))
  }
})
