# The settings of the pipeline.  The defaults are those of the results in the
# vignette; each can be set with an environment variable for a smaller trial
# run (for example, SIM_SE_REPLICATES=20).

setting_integer <- function(name, default) {
  value <- Sys.getenv(name, "")
  if (value == "") {
    return(default)
  }
  ret <- suppressWarnings(as.integer(value))
  if (is.na(ret) || ret < 1) {
    stop("The environment variable ", name, " must be a positive integer, not '", value, "'")
  }
  ret
}

simulation_settings <- function() {
  list(
    # Data seeds:  data_seed() adds 100000 times the scenario number and the
    # replicate number to the base
    seed_base = 20261007,
    seed_base_mean_type = 20261008,
    # Offsets from the data seed of a data set for its other random draws
    boot_seed_offset = 1e9,
    pk_seed_offset = 5e8,
    wj_seed_offset = 6e8,
    blq_seed_offset = 7e8,
    # Standard error study and its truth
    n_se_replicates = setting_integer("SIM_SE_REPLICATES", 5000),
    n_virtual = setting_integer("SIM_VIRTUAL", 100000),
    # Arithmetic and geometric mean profiles
    n_mean_type_replicates = setting_integer("SIM_MEAN_TYPE_REPLICATES", 2000),
    n_virtual_mean_type = setting_integer("SIM_MEAN_TYPE_VIRTUAL", 50000),
    # Bootstrap (sparse_bootstrap()) replicates per data set, and the data
    # sets of the bootstrap studies
    n_boot = setting_integer("SIM_BOOT", 200),
    n_boot_replicates = setting_integer("SIM_BOOT_REPLICATES", 2000),
    n_per_time = c(4, 6, 10, 20, 50, 100),
    n_profile_replicates = setting_integer("SIM_PROFILE_REPLICATES", 2000),
    # Tobit half-life
    n_tobit_se_replicates = setting_integer("SIM_TOBIT_SE_REPLICATES", 1000),
    n_tobit_profile_replicates = setting_integer("SIM_TOBIT_PROFILE_REPLICATES", 2000),
    # Comparisons with the PK package and Wolfsegger and Jaki (2005):  data
    # sets per scenario and number of animals, and bootstrap-t replicates
    comparison_n_per_time = c(3, 4),
    n_comparison_replicates = setting_integer("SIM_COMPARISON_REPLICATES", 500),
    pk_nsample = setting_integer("SIM_PK_NSAMPLE", 1000),
    wj_nsample = setting_integer("SIM_WJ_NSAMPLE", 1000),
    # PKNCA's bootstrap-t over the number of animals per time
    n_boott_profile_replicates = setting_integer("SIM_BOOTT_PROFILE_REPLICATES", 500),
    # BLQ methods (BLOQ package)
    n_blq_replicates = setting_integer("SIM_BLQ_REPLICATES", 1000),
    # Parallel workers (crew)
    workers = setting_integer("SIM_WORKERS", max(1L, parallel::detectCores() - 1L))
  )
}

# Results with the elapsed time of the branch that produced them
with_branch_seconds <- function(results, started) {
  results$branch_seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  results
}

# The total compute time (minutes) of results with `branch_seconds`, one value
# per branch identified by `key_columns`
compute_minutes <- function(results, key_columns) {
  key <- do.call(paste, unname(as.list(results[key_columns])))
  sum(results$branch_seconds[!duplicated(key)])/60
}

# The versions recorded with every result file
run_versions <- function(packages = character()) {
  ret <- list(
    pknca_version = as.character(utils::packageVersion("PKNCA")),
    pmxtools_version = as.character(utils::packageVersion("pmxTools")),
    r_version = R.version.string,
    run_date = format(Sys.Date())
  )
  for (current in packages) {
    ret[[paste0(tolower(current), "_version")]] <- as.character(utils::packageVersion(current))
  }
  ret
}

# Write a result file for the vignette and return its path (a file target)
write_vignette_rds <- function(object, file) {
  directory <- file.path("..", "..", "vignettes")
  if (!dir.exists(directory)) {
    stop("Run the pipeline from data-raw/sparse-simulation/ in the PKNCA source:  ", normalizePath(directory, mustWork = FALSE), " does not exist")
  }
  path <- file.path(directory, file)
  saveRDS(object, path)
  path
}
