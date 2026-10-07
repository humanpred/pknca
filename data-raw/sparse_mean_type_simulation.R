# Simulation-estimation comparison of the arithmetic and geometric mean
# profiles for sparse NCA:  relative bias and precision of AUClast, AUCinf,
# Cmax (C0 for IV bolus), AUMClast, AUMCinf, and half-life.
#
# Each replicate simulates sparse samples from a one- or two-compartment model
# (oral first-order absorption or IV bolus) with log-normal between-animal
# variability, forms the arithmetic and the geometric mean profile, and runs
# pk.nca() on each profile.  The arithmetic mean profile estimates the
# population mean curve, so its target is the arithmetic mean of the individual
# parameters; the geometric mean profile approximates the typical animal, so
# its target is the geometric mean of the individual parameters.  Both targets
# come from a large virtual population of the true individual parameters (no
# residual error).
#
# The design is in data-raw/sparse_simulation_design.R; every replicate runs
# inside withr::with_seed() with its own seed.
#
#   Rscript data-raw/sparse_mean_type_simulation.R
#
# writes vignettes/v24-sparse-auc-to-infinity-mean-type.rds (the summary), used by
# vignette("v24-sparse-auc-to-infinity").

library(PKNCA)

n_replicates <- as.integer(Sys.getenv("SIM_REPLICATES", "2000"))
n_virtual <- as.integer(Sys.getenv("SIM_VIRTUAL", "50000"))
seed_base <- 20261008
n_cores <- as.integer(Sys.getenv("SIM_CORES", "16"))

source("data-raw/sparse_simulation_design.R")

# True parameters of the virtual population ####

individual_parameters <- function(animal, route) {
  auc_to_24 <- stats::integrate(conc_moment, 0, 24, route = route, animal = animal, moment = 0, rel.tol = 1e-8)$value
  aumc_to_24 <- stats::integrate(conc_moment, 0, 24, route = route, animal = animal, moment = 1, rel.tol = 1e-8)$value
  inf <- animal_inf_parameters(animal, route)
  peak <-
    if (route == "oral") {
      stats::optimize(conc_animal, c(0, 24), route = route, animal = animal, maximum = TRUE, tol = 1e-10)$objective
    } else {
      conc_animal(0, route, animal)
    }
  c(
    auclast = auc_to_24, aucinf = inf[["aucinf"]], cmax = peak,
    aumclast = aumc_to_24, aumcinf = inf[["aumcinf"]], half.life = inf[["half.life"]]
  )
}

# The individual parameters of a block of virtual animals
individual_parameters_block <- function(rows, animals, route) {
  params <- matrix(NA_real_, length(rows), 6)
  for (i in seq_along(rows)) {
    params[i, ] <- individual_parameters(animals[rows[i], ], route)
  }
  params
}

true_targets <- function(scenario_row, seed) {
  route <- scenario_row$route
  # The animals are drawn under the seed; the parameters are then deterministic
  animals <- withr::with_seed(seed, draw_animals(n_virtual, scenario_row))
  blocks <- split(seq_len(n_virtual), cut(seq_len(n_virtual), n_cores, labels = FALSE))
  params <-
    do.call(rbind, parallel::mclapply(blocks, individual_parameters_block, animals = animals, route = route, mc.cores = n_cores))
  colnames(params) <- c("auclast", "aucinf", "cmax", "aumclast", "aumcinf", "half.life")
  data.frame(
    parameter = colnames(params),
    arithmetic = colMeans(params),
    geometric = exp(colMeans(log(params))),
    typical = individual_parameters(typical_animal(scenario_row), route)
  )
}

# Estimation ####

# The geometric mean at one time:  a time with more than half of its samples
# BLQ is BLQ (as for PKNCA's arithmetic sparse mean), and otherwise BLQ samples
# count as LLOQ/2
geometric_mean_time <- function(conc, blq, lloq) {
  if (mean(blq) > 0.5) {
    return(0)
  }
  if (all(conc[!blq] == 0)) {
    return(0)
  }
  exp(mean(log(ifelse(blq, lloq/2, conc))))
}

mean_profiles <- function(d, lloq) {
  sparse_pk <- sparse_mean(as_sparse_pk(conc = d$conc_reported, time = d$time, subject = d$subject))
  times <- vapply(sparse_pk, `[[`, "time", FUN.VALUE = 1)
  arithmetic <- vapply(sparse_pk, `[[`, "mean", FUN.VALUE = 1)
  geometric <- numeric(length(times))
  for (i in seq_along(times)) {
    rows <- d$time == times[i]
    geometric[i] <- geometric_mean_time(d$conc_reported[rows], d$blq[rows], lloq)
  }
  data.frame(time = times, arithmetic = arithmetic, geometric = geometric)
}

# NCA of one mean profile with pk.nca() (linear trapezoidal rule)
nca_profile <- function(time, conc, route) {
  d_conc <- data.frame(id = 1, time = time, conc = conc)
  d_dose <- data.frame(id = 1, time = 0, dose = model$dose)
  params <-
    if (route == "oral") {
      c(auclast = "auclast", aucinf = "aucinf.obs", cmax = "cmax", aumclast = "aumclast", aumcinf = "aumcinf.obs", half.life = "half.life")
    } else {
      c(auclast = "aucivlast", aucinf = "aucivinf.obs", cmax = "c0", aumclast = "aumcivlast", aumcinf = "aumcivinf.obs", half.life = "half.life")
    }
  intervals <- data.frame(start = 0, end = Inf)
  intervals[unname(params)] <- TRUE
  # There is no sample at the dose:  the oral concentration at time 0 is
  # imputed as zero, and the IV parameters back-extrapolate C0
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | id),
      PKNCAdose(d_dose, dose ~ time | id, route = if (route == "oral") "extravascular" else "intravascular"),
      intervals = intervals,
      impute = if (route == "oral") "start_conc0" else NA_character_,
      options = list(auc.method = "linear")
    )
  res <- as.data.frame(suppressWarnings(suppressMessages(pk.nca(o_data))))
  values <- stats::setNames(res$PPORRES, res$PPTESTCD)
  stats::setNames(unname(values[params]), names(params))
}

run_replicate <- function(scenario_row, replicate) {
  withr::with_seed(seed_base + 100000*scenario_row$scenario + replicate, {
    lloq <- scenario_lloq(scenario_row)
    d <- simulate_data(scenario_row, lloq)
    profiles <- mean_profiles(d, lloq)
    rbind(
      data.frame(
        scenario = scenario_row$scenario, replicate = replicate, mean_type = "arithmetic",
        parameter = c("auclast", "aucinf", "cmax", "aumclast", "aumcinf", "half.life"),
        estimate = nca_profile(profiles$time, profiles$arithmetic, scenario_row$route)
      ),
      data.frame(
        scenario = scenario_row$scenario, replicate = replicate, mean_type = "geometric",
        parameter = c("auclast", "aucinf", "cmax", "aumclast", "aumcinf", "half.life"),
        estimate = nca_profile(profiles$time, profiles$geometric, scenario_row$route)
      )
    )
  })
}

run_job <- function(i, jobs) {
  run_replicate(scenarios[jobs$scenario[i], ], jobs$replicate[i])
}

# Summary ####

summarize_results <- function(results, targets) {
  keys <- unique(results[, c("scenario", "mean_type", "parameter")])
  rows <- list()
  for (i in seq_len(nrow(keys))) {
    k <- keys[i, ]
    sc <- scenarios[scenarios$scenario == k$scenario, ]
    tg <- targets[targets$route == sc$route & targets$elimination == sc$elimination & targets$compartments == sc$compartments & targets$parameter == k$parameter, ]
    est <- results$estimate[results$scenario == k$scenario & results$mean_type == k$mean_type & results$parameter == k$parameter]
    ok <- is.finite(est) & est > 0
    natural <- if (k$mean_type == "arithmetic") tg$arithmetic else tg$geometric
    rows[[i]] <- data.frame(
      k,
      n_ok = sum(ok),
      n = length(est),
      target_arithmetic = tg$arithmetic,
      target_geometric = tg$geometric,
      target_typical = tg$typical,
      median_estimate = stats::median(est[ok]),
      # Bias against the natural target of the mean type, and against the
      # typical animal
      bias_natural = 100*(stats::median(est[ok]) - natural)/natural,
      bias_typical = 100*(stats::median(est[ok]) - tg$typical)/tg$typical,
      mean_bias_natural = 100*(mean(est[ok]) - natural)/natural,
      # Relative precision:  the coefficient of variation of the estimate, and
      # a robust version from the interquartile range (IQR/1.349 estimates the
      # standard deviation for a normal distribution)
      cv = 100*stats::sd(est[ok])/mean(est[ok]),
      robust_cv = 100*(stats::IQR(est[ok])/1.349)/stats::median(est[ok]),
      rmse_natural = 100*sqrt(mean((est[ok] - natural)^2))/natural
    )
  }
  merge(scenarios, do.call(rbind, rows), by = "scenario")
}

if (sys.nframe() == 0) {
  started <- Sys.time()
  target_keys <- unique(scenarios[, c("route", "elimination", "compartments")])
  targets <- list()
  for (i in seq_len(nrow(target_keys))) {
    tk <- target_keys[i, ]
    scenario_row <- merge(tk, scenarios)[1, ]
    targets[[i]] <-
      data.frame(
        route = tk$route, elimination = tk$elimination, compartments = tk$compartments,
        true_targets(scenario_row, seed = seed_base + i), row.names = NULL
      )
  }
  targets <- do.call(rbind, targets)
  jobs <- expand.grid(scenario = scenarios$scenario, replicate = seq_len(n_replicates))
  results <- parallel::mclapply(seq_len(nrow(jobs)), run_job, jobs = jobs, mc.cores = n_cores, mc.preschedule = TRUE)
  failed <- vapply(results, inherits, "try-error", FUN.VALUE = TRUE)
  if (any(failed)) {
    stop("Replicates failed:  ", paste(unique(vapply(results[failed], as.character, "")), collapse = "; "))
  }
  results <- do.call(rbind, results)
  simulation <-
    list(
      summary = summarize_results(results, targets),
      targets = targets,
      scenarios = scenarios,
      model = model,
      sampling_times = sampling_times,
      batch_times = batch_times,
      n_replicates = n_replicates,
      n_virtual = n_virtual,
      seed_base = seed_base,
      pknca_version = as.character(utils::packageVersion("PKNCA")),
      pmxtools_version = as.character(utils::packageVersion("pmxTools")),
      run_date = format(Sys.Date()),
      run_minutes = as.numeric(difftime(Sys.time(), started, units = "mins"))
    )
  saveRDS(simulation, "vignettes/v24-sparse-auc-to-infinity-mean-type.rds")
  saveRDS(results, "data-raw/sparse_mean_type_simulation_replicates.rds")
  print(simulation$summary[, c("compartments", "route", "design", "blq", "elimination", "mean_type", "parameter", "n_ok", "bias_natural", "bias_typical", "cv", "robust_cv")], digits = 3)
}
