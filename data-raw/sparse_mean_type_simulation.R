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
# Concentrations come from pmxTools; every replicate runs inside
# withr::with_seed() with its own seed.
#
#   Rscript data-raw/sparse_mean_type_simulation.R
#
# writes data-raw/sparse_mean_type_simulation.rds (the summary).

library(PKNCA)

n_replicates <- as.integer(Sys.getenv("SIM_REPLICATES", "2000"))
n_virtual <- as.integer(Sys.getenv("SIM_VIRTUAL", "50000"))
seed_base <- 20261008
n_cores <- as.integer(Sys.getenv("SIM_CORES", "16"))

# Model and scenarios ####

# Dose 100 and a multiplicative residual error with mean 1, with log-normal
# between-animal variability (omega 0.3) on each structural parameter.
#
# One compartment:  V 10 and ke 0.15/hr (fast) or 0.07/hr (slow); typical ka
# 5/hr gives an oral Tmax of 0.72 hr (fast) and 0.87 hr (slow).
# Two compartments:  V1 10, V2 15, Q 6, and CL 5.1 (fast) or 1.97 (slow), which
# give the same terminal half-lives (4.6 and 9.9 hr) after a distribution phase
# with a half-life of about 0.5 hr; typical ka 2.5/hr gives an oral Tmax of
# 0.62 hr (fast) and 0.72 hr (slow).
model <- list(dose = 100, omega = 0.3, sigma = 0.15)
model_1cmt <- list(ka = 5, v = 10)
model_2cmt <- list(ka = 2.5, v1 = 10, v2 = 15, q = 6)

scenarios <-
  expand.grid(
    route = c("oral", "iv"),
    design = c("serial", "batch"),
    blq = c("none", "moderate"),
    elimination = c("fast", "slow"),
    compartments = c(1, 2),
    stringsAsFactors = FALSE
  )
scenarios$scenario <- seq_len(nrow(scenarios))
# ke for one compartment and CL for two
scenarios$ke <- ifelse(scenarios$elimination == "fast", 0.15, 0.07)
scenarios$cl_2cmt <- ifelse(scenarios$elimination == "fast", 5.1, 1.97)

# Sampling:  oral with a predose sample, IV bolus with an early sample.  The
# batch designs sample three batches of four animals at a third of the times
# each (and predose for oral).
sampling_times <- list(oral = c(0, 0.25, 0.5, 1, 2, 4, 6, 8, 12, 24), iv = c(1/12, 0.25, 0.5, 1, 2, 4, 8, 12, 24))
batch_times <-
  list(
    oral = list(c(0, 0.25, 2, 8), c(0, 0.5, 4, 12), c(0, 1, 6, 24)),
    iv = list(c(1/12, 1, 8), c(0.25, 2, 12), c(0.5, 4, 24))
  )
n_serial <- 4
n_batch <- 4

# The concentration of one animal (one row of animal parameters) at the given
# times (pmxTools)
conc_animal <- function(time, route, animal) {
  if (is.null(animal$v2)) {
    if (route == "oral") {
      pmxTools::calc_sd_1cmt_linear_oral_1(t = time, CL = animal$cl, V = animal$v1, ka = animal$ka, dose = model$dose)
    } else {
      pmxTools::calc_sd_1cmt_linear_bolus(t = time, CL = animal$cl, V = animal$v1, dose = model$dose)
    }
  } else {
    if (route == "oral") {
      pmxTools::calc_sd_2cmt_linear_oral_1(t = time, CL = animal$cl, V1 = animal$v1, Q = animal$q, V2 = animal$v2, ka = animal$ka, dose = model$dose)
    } else {
      pmxTools::calc_sd_2cmt_linear_bolus(t = time, CL = animal$cl, V1 = animal$v1, Q = animal$q, V2 = animal$v2, dose = model$dose)
    }
  }
}

# The typical animal of a scenario
typical_animal <- function(scenario_row) {
  if (scenario_row$compartments == 1) {
    data.frame(ka = model_1cmt$ka, cl = scenario_row$ke*model_1cmt$v, v1 = model_1cmt$v)
  } else {
    data.frame(ka = model_2cmt$ka, cl = scenario_row$cl_2cmt, v1 = model_2cmt$v1, q = model_2cmt$q, v2 = model_2cmt$v2)
  }
}

# The LLOQ for moderate BLQ:  70% of the typical concentration at 24 hours
scenario_lloq <- function(scenario_row) {
  if (scenario_row$blq == "none") 0 else 0.7*conc_animal(24, scenario_row$route, typical_animal(scenario_row))
}

# Animals with log-normal variability around the typical values.  For one
# compartment the draws are ka, ke, and V (in that order); for two, ka, CL, V1,
# Q, and V2.
draw_animals <- function(n, scenario_row) {
  typical <- typical_animal(scenario_row)
  if (scenario_row$compartments == 1) {
    ka <- typical$ka*exp(stats::rnorm(n, sd = model$omega))
    ke <- scenario_row$ke*exp(stats::rnorm(n, sd = model$omega))
    v <- typical$v1*exp(stats::rnorm(n, sd = model$omega))
    data.frame(ka = ka, cl = ke*v, v1 = v)
  } else {
    data.frame(
      ka = typical$ka*exp(stats::rnorm(n, sd = model$omega)),
      cl = typical$cl*exp(stats::rnorm(n, sd = model$omega)),
      v1 = typical$v1*exp(stats::rnorm(n, sd = model$omega)),
      q = typical$q*exp(stats::rnorm(n, sd = model$omega)),
      v2 = typical$v2*exp(stats::rnorm(n, sd = model$omega))
    )
  }
}

# True parameters of the virtual population ####

# Integrand of the AUC (moment = 0) or AUMC (moment = 1) of one animal
conc_moment <- function(time, route, animal, moment) {
  time^moment*conc_animal(time, route, animal)
}

individual_parameters <- function(animal, route) {
  auc_to_24 <- stats::integrate(conc_moment, 0, 24, route = route, animal = animal, moment = 0, rel.tol = 1e-8)$value
  aumc_to_24 <- stats::integrate(conc_moment, 0, 24, route = route, animal = animal, moment = 1, rel.tol = 1e-8)$value
  auc_inf <- model$dose/animal$cl
  if (is.null(animal$v2)) {
    # Mean residence time Vss/CL (absorption adds 1/ka) and the half-life
    mrt <- animal$v1/animal$cl
    half_life <- log(2)*animal$v1/animal$cl
  } else {
    mrt <- (animal$v1 + animal$v2)/animal$cl
    half_life <- pmxTools::calc_derived_2cpt(CL = animal$cl, V1 = animal$v1, Q = animal$q, V2 = animal$v2)$thalf_beta
  }
  if (route == "oral") {
    mrt <- mrt + 1/animal$ka
  }
  peak <-
    if (route == "oral") {
      stats::optimize(conc_animal, c(0, 24), route = route, animal = animal, maximum = TRUE, tol = 1e-10)$objective
    } else {
      conc_animal(0, route, animal)
    }
  c(
    auclast = auc_to_24, aucinf = auc_inf, cmax = peak,
    aumclast = aumc_to_24, aumcinf = auc_inf*mrt, half.life = half_life
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

# Simulation and estimation ####

simulate_data <- function(scenario_row, lloq) {
  route <- scenario_row$route
  design <- scenario_row$design
  if (design == "serial") {
    times <- sampling_times[[route]]
    sampling <- data.frame(subject = seq_len(length(times)*n_serial), time = rep(times, each = n_serial))
  } else {
    batches <- list()
    for (b in seq_along(batch_times[[route]])) {
      batches[[b]] <- expand.grid(subject = (b - 1)*n_batch + seq_len(n_batch), time = batch_times[[route]][[b]])
    }
    sampling <- do.call(rbind, batches)
  }
  subjects <- sort(unique(sampling$subject))
  animals <- draw_animals(length(subjects), scenario_row)
  # Samples in order of animal, then time:  the residual errors are drawn in
  # this order
  d <- sampling[order(sampling$subject, sampling$time), ]
  d$conc <- NA_real_
  for (i in seq_along(subjects)) {
    rows <- d$subject == subjects[i]
    d$conc[rows] <- conc_animal(d$time[rows], route, animals[i, ])
  }
  d$conc <- d$conc*exp(stats::rnorm(nrow(d), mean = -model$sigma^2/2, sd = model$sigma))
  d$blq <- d$conc < lloq
  d$conc_reported <- ifelse(d$blq, 0, d$conc)
  d[order(d$time, d$subject), c("subject", "time", "conc_reported", "blq")]
}

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
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | id),
      PKNCAdose(d_dose, dose ~ time | id, route = if (route == "oral") "extravascular" else "intravascular"),
      intervals = intervals,
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
  saveRDS(simulation, "data-raw/sparse_mean_type_simulation.rds")
  saveRDS(results, "data-raw/sparse_mean_type_simulation_replicates.rds")
  print(simulation$summary[, c("compartments", "route", "design", "blq", "elimination", "mean_type", "parameter", "n_ok", "bias_natural", "bias_typical", "cv", "robust_cv")], digits = 3)
}
