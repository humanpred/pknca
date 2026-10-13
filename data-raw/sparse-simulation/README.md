# Sparse AUC to infinity: the simulation pipeline

This directory holds the simulation-estimation studies behind
`vignette("v24-sparse-auc-to-infinity")`, as a
[targets](https://docs.ropensci.org/targets/) pipeline. The pipeline writes the
`vignettes/v24-sparse-auc-to-infinity-*.rds` files that the vignette reads. CRAN
cannot run the simulations, so the vignette only reads the stored summaries.

## Layout

| File | Contents |
|------|----------|
| `_targets.R` | The pipeline: the design, the data sets of each scenario, each study's results, the summaries, and the result files |
| `R/design.R` | The models, the 32 scenarios, and the simulation of one data set (`simulate_data()`, `simulate_datasets()`) |
| `R/truth.R` | The true values, from large virtual populations |
| `R/settings.R` | The settings (replicates, seeds, workers) and helpers for timing and versions |
| `R/tobit_fit.R` | The Tobit regression of the individual samples |
| `R/study_se.R` | Yuan's, the delta-method, and the individual-sample standard errors |
| `R/study_bootstrap.R` | The bootstrap of Shen and Machado (`sparse_bootstrap()`) |
| `R/study_profile.R` | The bootstrap and analytical intervals over the number of animals per time |
| `R/study_tobit.R` | The Tobit half-life with BLQ samples |
| `R/study_mean_type.R` | Arithmetic and geometric mean profiles |
| `R/wolfsegger_jaki_2005.R` | The estimator of Wolfsegger and Jaki (2005), written from the paper |
| `R/study_comparisons.R` | PKNCA against the PK package and Wolfsegger and Jaki (2005), with PKNCA's bootstrap-t |
| `R/study_blq.R` | The BLQ treatments of Barnett et al. (2021) from the BLOQ package |
| `R/outputs.R` | The contents of each result file |
| `_targets/` | The pipeline's store (not in git) |

## Running it

Install the PKNCA of this source tree first, since the studies use functions
that may not be released yet. The pipeline also needs targets, tarchetypes,
crew, withr, pmxTools, PK, and BLOQ.

```r
# From the root of the PKNCA source
install.packages(".", repos = NULL, type = "source")
# Then from this directory
setwd("data-raw/sparse-simulation")
targets::tar_make()
```

`targets::tar_make(names = rds_blq)` builds one result file and only what it
needs. `targets::tar_visnetwork()` draws the pipeline. `targets::tar_read()`
returns any target, including the replicate-level results (for example,
`results_se_all`), which are not stored in git.

Every data set has its own seed (`data_seed()`), and every other random draw
for it is a fixed offset from that seed. So a result does not depend on the
number of workers or the order the targets run in. The data sets of a scenario
are shared by every study that analyses it. The pipeline reproduces exactly,
replicate by replicate, the results of the scripts it replaced.

## Settings and cost

The defaults are the settings of the results in the vignette. An environment
variable sets each one for a smaller trial run. `SIM_WORKERS` sets the number
of parallel workers (default: one fewer than the cores).

| Variable | Default | What it sets |
|----------|---------|--------------|
| `SIM_SE_REPLICATES` | 5000 | Data sets per scenario, standard error study |
| `SIM_VIRTUAL` | 100000 | Virtual animals for the true AUC and AUMC |
| `SIM_MEAN_TYPE_REPLICATES` | 2000 | Data sets per scenario, mean-profile study |
| `SIM_MEAN_TYPE_VIRTUAL` | 50000 | Virtual animals for the mean-profile targets |
| `SIM_BOOT` | 200 | `sparse_bootstrap()` replicates per data set |
| `SIM_BOOT_REPLICATES` | 2000 | Data sets per scenario, bootstrap study |
| `SIM_PROFILE_REPLICATES` | 2000 | Data sets per number of animals, profile |
| `SIM_TOBIT_SE_REPLICATES` | 1000 | Data sets per BLQ scenario, Tobit study |
| `SIM_TOBIT_PROFILE_REPLICATES` | 2000 | Data sets per number of animals, Tobit study |
| `SIM_COMPARISON_REPLICATES` | 500 | Data sets per scenario and number of animals, PK and Wolfsegger-Jaki comparisons |
| `SIM_PK_NSAMPLE` | 1000 | PK's bootstrap-t replicates (its default) |
| `SIM_WJ_NSAMPLE` | 1000 | Wolfsegger-Jaki bootstrap-t replicates (as in the paper) |
| `SIM_BOOTT_PROFILE_REPLICATES` | 500 | Data sets per number of animals, PKNCA's bootstrap-t |
| `SIM_BLQ_REPLICATES` | 1000 | Data sets per BLQ scenario, BLOQ comparison |

A trial run of every study takes a couple of minutes:

```sh
SIM_SE_REPLICATES=6 SIM_VIRTUAL=300 SIM_BOOT=20 SIM_BOOT_REPLICATES=3 \
  SIM_PROFILE_REPLICATES=2 SIM_TOBIT_SE_REPLICATES=2 SIM_TOBIT_PROFILE_REPLICATES=2 \
  SIM_MEAN_TYPE_REPLICATES=3 SIM_MEAN_TYPE_VIRTUAL=200 SIM_COMPARISON_REPLICATES=4 \
  SIM_PK_NSAMPLE=50 SIM_WJ_NSAMPLE=50 SIM_BLQ_REPLICATES=3 SIM_BOOTT_PROFILE_REPLICATES=2 \
  Rscript -e "targets::tar_make()"
```

It writes its small results over the result files in `vignettes/`, so restore
them with git afterward.

The full pipeline cannot run on a laptop in an hour; it takes days.  The
comparisons added with the pipeline (the result files
`v24-sparse-auc-to-infinity-comparisons.rds` and
`v24-sparse-auc-to-infinity-blq.rds`) took 10.5 hours with 6 workers on an
8-core laptop (Intel Core Ultra 7 268V), or 64 core-hours by the targets'
timings:

| Targets | Core-hours |
|---------|-----------:|
| PK and Wolfsegger-Jaki comparisons, with PKNCA's bootstrap (`results_comparison_*`) | 49 |
| PKNCA's bootstrap-t over animals per time (`results_boott_profile_*`) | 7 |
| BLQ treatments (`results_blq_*`) | 0.7 |
| Data sets and truth | 0.5 |

The five earlier studies took 17 hours on 16 cores when last run (the sum of
the `run_minutes` recorded in their result files); the individual-sample Tobit
study was 10 of those hours.  Timing single data sets on the laptop gives a
similar total, about 260 core-hours, so the whole pipeline needs about three
days with 7 workers on such a laptop.  Each result file records `run_minutes`,
the summed compute time of its targets.

## Adding a scenario or an estimator

**A scenario** is a row of `design_scenarios()` in `R/design.R`. Add new values
to its `expand.grid()` *after* the existing ones, or append rows, so the
existing scenarios keep their numbers; the data seeds depend on the number.
The static branches in `_targets.R` pick the scenarios of each study by their
columns, so a new scenario joins every study whose filter it matches.

**An estimator** is a function of one data set that returns rows with the
columns `interval`, `parameter`, `estimate`, `se`, `lower`, and `upper` (see
`comparison_intervals()` in `R/study_comparisons.R`). Add it to
`comparison_intervals()` (with a name in `include`) or to `blq_intervals()`.
Then `summarize_intervals()` gives its coverage, width, and bias with no other
change. If it draws random numbers, give it a seed offset in
`simulation_settings()` and run it under `withr::with_seed()`, as
`pk_intervals()` does. A new study gets its own `tar_map()` in `_targets.R`,
an output function in `R/outputs.R`, and a result file; add the file and the
columns the vignette reads to `tests/testthat/test-sparse-vignette-results.R`.
