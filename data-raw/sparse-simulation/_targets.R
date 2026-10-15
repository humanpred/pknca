# The simulation-estimation studies of vignette("v24-sparse-auc-to-infinity").
# Run with targets::tar_make() from this directory; see README.md.

library(targets)
library(tarchetypes)

tar_source("R")
settings <- simulation_settings()

tar_option_set(
  packages = "PKNCA",
  memory = "transient",
  garbage_collection = TRUE,
  controller = crew::crew_controller_local(workers = settings$workers, seconds_idle = 120)
)

# The static branches:  the scenarios of each study, known when the pipeline is
# defined, with the target that holds each one's data sets
all_scenarios <- design_scenarios()
profile_values <- profile_grid(all_scenarios, settings$n_per_time)
profile_blq_scenario <- profile_values$scenario[all_scenarios$blq[profile_values$scenario] == "moderate"][1]
blq_scenarios <- all_scenarios$scenario[all_scenarios$blq == "moderate"]
serial_scenarios <- all_scenarios$scenario[all_scenarios$design == "serial"]
batch_scenarios <- all_scenarios$scenario[all_scenarios$design == "batch"]

datasets_symbol <- function(prefix, ...) {
  rlang::syms(paste(prefix, ..., sep = "_"))
}

values_all <- data.frame(scenario = all_scenarios$scenario)
# The profile's BLQ scenario has the Tobit study at every number of animals,
# from the profile's data sets
values_tobit <- data.frame(scenario = setdiff(blq_scenarios, profile_blq_scenario))
values_tobit$datasets <- datasets_symbol("datasets_se", values_tobit$scenario)
values_blq <- data.frame(scenario = blq_scenarios)
values_blq$datasets <- datasets_symbol("datasets_se", values_blq$scenario)
values_n3 <- data.frame(scenario = serial_scenarios)
values_comparison <-
  rbind(
    data.frame(scenario = serial_scenarios, n = 3),
    data.frame(scenario = c(serial_scenarios, batch_scenarios), n = 4)
  )
values_comparison$datasets <-
  datasets_symbol(ifelse(values_comparison$n == 4, "datasets_se", "datasets_n3"), values_comparison$scenario)
values_profile <- data.frame(scenario = profile_values$scenario, n = profile_values$n_per_time)
values_tobit_profile <- values_profile[values_profile$scenario == profile_blq_scenario, ]
values_large_n <- data.frame(scenario = all_scenarios$scenario[all_scenarios$design == "serial" & all_scenarios$blq == "none"])
values_tobit_profile$datasets <- datasets_symbol("datasets_profile", values_tobit_profile$scenario, values_tobit_profile$n)

# Data sets of the standard error study and every study that reuses them
n_se_datasets <-
  with(settings, max(n_se_replicates, n_boot_replicates, n_tobit_se_replicates, n_comparison_replicates, n_blq_replicates))
n_profile_datasets <- with(settings, max(n_profile_replicates, n_tobit_profile_replicates, n_boott_profile_replicates))

mapped_scenarios <-
  tar_map(
    values = values_all,
    names = "scenario",
    tar_target(datasets_se, simulate_datasets(scenario_row(scenarios, scenario), seq_len(n_se_datasets), settings$seed_base)),
    tar_target(results_se, run_se_study(datasets_se, scenario_row(scenarios_truth, scenario), settings$n_se_replicates)),
    tar_target(results_bootstrap, run_bootstrap_study(datasets_se, scenario_row(scenarios_truth, scenario), settings)),
    tar_target(
      datasets_mean_type,
      simulate_datasets(scenario_row(scenarios, scenario), seq_len(settings$n_mean_type_replicates), settings$seed_base_mean_type)
    ),
    tar_target(results_mean_type, run_mean_type_study(datasets_mean_type, scenario_row(scenarios, scenario)))
  )

mapped_tobit <-
  tar_map(
    values = values_tobit,
    names = "scenario",
    tar_target(
      results_tobit,
      run_tobit_study(datasets, scenario_row(scenarios_truth, scenario), n_serial, settings$n_tobit_se_replicates, settings)
    )
  )

mapped_blq <-
  tar_map(
    values = values_blq,
    names = "scenario",
    tar_target(results_blq, run_blq_study(datasets, scenario_row(scenarios_truth, scenario), settings))
  )

mapped_n3 <-
  tar_map(
    values = values_n3,
    names = "scenario",
    tar_target(
      datasets_n3,
      simulate_datasets(scenario_row(scenarios, scenario), seq_len(settings$n_comparison_replicates), settings$seed_base, n_per_time = 3)
    )
  )

mapped_comparison <-
  tar_map(
    values = values_comparison,
    names = c("scenario", "n"),
    tar_target(
      results_comparison,
      run_comparison_study(
        datasets, scenario_row(scenarios_truth, scenario), n, settings$n_comparison_replicates, settings,
        include = c("pknca", "pk", "wj2005")
      )
    )
  )

mapped_profile <-
  tar_map(
    values = values_profile,
    names = c("scenario", "n"),
    tar_target(
      datasets_profile,
      simulate_datasets(scenario_row(scenarios, scenario), seq_len(n_profile_datasets), settings$seed_base, n_per_time = n)
    ),
    tar_target(results_profile, run_profile_study(datasets_profile, scenario_row(scenarios_truth, scenario), n, settings)),
    tar_target(
      results_boott_profile,
      run_comparison_study(
        datasets_profile, scenario_row(scenarios_truth, scenario), n, settings$n_boott_profile_replicates, settings,
        include = "pknca"
      )
    )
  )

mapped_tobit_profile <-
  tar_map(
    values = values_tobit_profile,
    names = c("scenario", "n"),
    tar_target(
      results_tobit_profile,
      run_tobit_study(datasets, scenario_row(scenarios_truth, scenario), n, settings$n_tobit_profile_replicates, settings)
    )
  )

mapped_large_n <-
  tar_map(
    values = values_large_n,
    names = "scenario",
    tar_target(results_large_n, run_large_n_check(scenario_row(scenarios_truth, scenario), settings))
  )

list(
  # The known-answer tests of the 2005 estimator and of the coverage summary
  tar_target(known_answer_test_files, list.files("tests/testthat", pattern = "^test-.*[.]R$", full.names = TRUE), format = "file"),
  tar_target(known_answers, run_known_answer_tests(known_answer_test_files)),
  # The design and the truth
  tar_target(scenarios, design_scenarios()),
  tar_target(truth_key_table, truth_keys(scenarios)),
  tar_target(
    truth,
    true_values(scenarios, truth_key_table, settings$seed_base + truth_key_table$truth_index, settings$n_virtual),
    pattern = map(truth_key_table)
  ),
  tar_target(
    mean_type_targets,
    true_targets(scenarios, truth_key_table, settings$seed_base_mean_type + truth_key_table$truth_index, settings$n_virtual_mean_type),
    pattern = map(truth_key_table)
  ),
  tar_target(scenarios_truth, add_truth(scenarios, truth)),
  # The data sets and each study's results
  mapped_scenarios,
  mapped_tobit,
  mapped_blq,
  mapped_n3,
  mapped_comparison,
  mapped_profile,
  mapped_tobit_profile,
  mapped_large_n,
  tar_combine(results_se_all, mapped_scenarios[["results_se"]], command = bind_results(!!!.x)),
  tar_combine(results_bootstrap_all, mapped_scenarios[["results_bootstrap"]], command = bind_results(!!!.x)),
  tar_combine(results_mean_type_all, mapped_scenarios[["results_mean_type"]], command = bind_results(!!!.x)),
  tar_combine(results_profile_all, mapped_profile[["results_profile"]], command = bind_results(!!!.x)),
  tar_combine(
    results_tobit_all,
    mapped_tobit[["results_tobit"]], mapped_tobit_profile[["results_tobit_profile"]],
    command = bind_results(!!!.x)
  ),
  tar_combine(results_comparison_all, mapped_comparison[["results_comparison"]], command = bind_results(!!!.x)),
  tar_combine(results_boott_profile_all, mapped_profile[["results_boott_profile"]], command = bind_results(!!!.x)),
  tar_combine(results_blq_all, mapped_blq[["results_blq"]], command = bind_results(!!!.x)),
  tar_combine(results_large_n_all, mapped_large_n[["results_large_n"]], command = bind_results(!!!.x)),
  # The summaries the vignette reads, written to vignettes/
  tar_target(output_se_list, output_se(results_se_all, scenarios_truth, truth, settings)),
  tar_target(output_bootstrap_list, output_bootstrap(results_bootstrap_all, scenarios_truth, settings)),
  tar_target(output_mean_type_list, output_mean_type(results_mean_type_all, mean_type_targets, scenarios, settings)),
  tar_target(output_profile_list, output_profile(results_profile_all, scenarios_truth, profile_values$scenario[1], settings)),
  tar_target(output_tobit_list, output_tobit(results_tobit_all, scenarios_truth, profile_blq_scenario, settings)),
  tar_target(
    output_comparisons_list,
    output_comparisons(
      results_comparison_all, results_boott_profile_all, results_large_n_all, scenarios_truth, settings, known_answers
    )
  ),
  tar_target(output_blq_list, output_blq(results_blq_all, scenarios_truth, settings)),
  tar_target(rds_se, write_vignette_rds(output_se_list, "v24-sparse-auc-to-infinity-simulation.rds", settings$output_dir), format = "file"),
  tar_target(rds_bootstrap, write_vignette_rds(output_bootstrap_list, "v24-sparse-auc-to-infinity-bootstrap.rds", settings$output_dir), format = "file"),
  tar_target(rds_mean_type, write_vignette_rds(output_mean_type_list, "v24-sparse-auc-to-infinity-mean-type.rds", settings$output_dir), format = "file"),
  tar_target(rds_profile, write_vignette_rds(output_profile_list, "v24-sparse-auc-to-infinity-bootstrap-n.rds", settings$output_dir), format = "file"),
  tar_target(rds_tobit, write_vignette_rds(output_tobit_list, "v24-sparse-auc-to-infinity-tobit.rds", settings$output_dir), format = "file"),
  tar_target(rds_comparisons, write_vignette_rds(output_comparisons_list, "v24-sparse-auc-to-infinity-comparisons.rds", settings$output_dir), format = "file"),
  tar_target(rds_blq, write_vignette_rds(output_blq_list, "v24-sparse-auc-to-infinity-blq.rds", settings$output_dir), format = "file")
)
