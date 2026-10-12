# The result files that the vignette reads, as lists of their summaries, the
# settings that produced them, and the versions of R and the packages.  The
# vignette reads these by name, so renaming a field or a summary column breaks
# tests/testthat/test-sparse-vignette-results.R in the PKNCA source.

# Results combined from the branches of a static branch (tar_combine())
bind_results <- function(...) {
  ret <- do.call(rbind, unname(list(...)))
  rownames(ret) <- NULL
  ret
}

output_se <- function(results, scenarios_truth, truth, settings) {
  c(
    list(
      summary = summarize_se(results, scenarios_truth),
      scenarios = scenarios_truth,
      model = model,
      model_1cmt = model_1cmt,
      model_2cmt = model_2cmt,
      sampling_times = sampling_times,
      batch_times = batch_times,
      n_serial = n_serial,
      n_batch = n_batch,
      n_replicates = settings$n_se_replicates,
      n_virtual = settings$n_virtual,
      truth_mcse_percent =
        data.frame(
          truth[, c("route", "elimination", "compartments")],
          auc = truth$mcse_auc, aumc = truth$mcse_aumc
        ),
      seed_base = settings$seed_base
    ),
    run_versions(),
    list(run_minutes = compute_minutes(results, "scenario"))
  )
}

output_mean_type <- function(results, targets, scenarios, settings) {
  c(
    list(
      summary = summarize_mean_type(results, targets, scenarios),
      targets = targets,
      scenarios = scenarios,
      model = model,
      sampling_times = sampling_times,
      batch_times = batch_times,
      n_replicates = settings$n_mean_type_replicates,
      n_virtual = settings$n_virtual_mean_type,
      seed_base = settings$seed_base_mean_type
    ),
    run_versions(),
    list(run_minutes = compute_minutes(results, "scenario"))
  )
}

output_bootstrap <- function(results, scenarios_truth, settings) {
  c(
    list(
      summary = summarize_bootstrap(results, scenarios_truth),
      n_boot = settings$n_boot,
      n_replicates = settings$n_boot_replicates,
      seed_base = settings$seed_base,
      boot_seed_offset = settings$boot_seed_offset
    ),
    run_versions(),
    list(run_minutes = compute_minutes(results, "scenario"))
  )
}

# The truth is that of the scenario without BLQ samples (the same for both)
output_profile <- function(results, scenarios_truth, truth_scenario, settings) {
  profile_scenario <- scenario_row(scenarios_truth, truth_scenario)
  c(
    list(
      summary = summarize_profile(results),
      n_per_time = settings$n_per_time,
      n_boot = settings$n_boot,
      n_replicates = settings$n_profile_replicates,
      truth = c(auc = profile_scenario$truth_auc, aumc = profile_scenario$truth_aumc),
      seed_base = settings$seed_base,
      boot_seed_offset = settings$boot_seed_offset
    ),
    run_versions(),
    list(run_minutes = compute_minutes(results, c("blq", "n_per_time")))
  )
}

output_tobit <- function(results, scenarios_truth, profile_scenario, settings) {
  c(
    list(
      summary = summarize_tobit(results),
      scenarios = scenarios_truth,
      n_per_time = settings$n_per_time,
      profile_scenario = profile_scenario,
      n_boot = settings$n_boot,
      n_se_replicates = settings$n_tobit_se_replicates,
      n_profile_replicates = settings$n_tobit_profile_replicates,
      seed_base = settings$seed_base,
      boot_seed_offset = settings$boot_seed_offset
    ),
    run_versions(),
    list(run_minutes = compute_minutes(results, c("scenario", "n_per_time")))
  )
}

output_comparisons <- function(results, results_profile, scenarios_truth, settings) {
  c(
    list(
      summary = summarize_intervals(results, scenarios_truth),
      profile_summary = summarize_intervals(results_profile, scenarios_truth),
      n_per_time = settings$comparison_n_per_time,
      n_replicates = settings$n_comparison_replicates,
      n_profile_replicates = settings$n_boott_profile_replicates,
      profile_n_per_time = settings$n_per_time,
      n_boot = settings$n_boot,
      pk_nsample = settings$pk_nsample,
      wj_nsample = settings$wj_nsample,
      n_tail = 3,
      seed_base = settings$seed_base,
      boot_seed_offset = settings$boot_seed_offset,
      pk_seed_offset = settings$pk_seed_offset,
      wj_seed_offset = settings$wj_seed_offset
    ),
    run_versions("PK"),
    list(
      run_minutes =
        compute_minutes(results, c("scenario", "n_per_time")) +
        compute_minutes(results_profile, c("scenario", "n_per_time"))
    )
  )
}

output_blq <- function(results, scenarios_truth, settings) {
  c(
    list(
      summary = summarize_intervals(results, scenarios_truth),
      fallbacks = summarize_blq_fallbacks(results),
      n_replicates = settings$n_blq_replicates,
      seed_base = settings$seed_base,
      blq_seed_offset = settings$blq_seed_offset
    ),
    run_versions("BLOQ"),
    list(run_minutes = compute_minutes(results, "scenario"))
  )
}
