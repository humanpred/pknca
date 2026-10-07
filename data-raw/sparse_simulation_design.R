# The simulation design shared by data-raw/sparse_aucinf_simulation.R and
# data-raw/sparse_mean_type_simulation.R:  the models, the scenarios, and the
# simulation of one sparse data set.  Concentrations come from pmxTools.

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

# Sampling:  no sample at the dose (as usual for sacrificial designs), so the
# oral concentration at time 0 is imputed as zero and the IV bolus C0 is
# back-extrapolated; IV bolus has an early sample for that.  The batch designs
# sample three batches of four animals at a third of the times each.
sampling_times <- list(oral = c(0.25, 0.5, 1, 2, 4, 6, 8, 12, 24), iv = c(1/12, 0.25, 0.5, 1, 2, 4, 8, 12, 24))
batch_times <-
  list(
    oral = list(c(0.25, 2, 8), c(0.5, 4, 12), c(1, 6, 24)),
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

# The AUC and AUMC from 0 to infinity and the terminal half-life of one animal
animal_inf_parameters <- function(animal, route) {
  auc_inf <- model$dose/animal$cl
  if (is.null(animal$v2)) {
    # Mean residence time Vss/CL (absorption adds 1/ka)
    mrt <- animal$v1/animal$cl
    half_life <- log(2)*animal$v1/animal$cl
  } else {
    mrt <- (animal$v1 + animal$v2)/animal$cl
    half_life <- pmxTools::calc_derived_2cpt(CL = animal$cl, V1 = animal$v1, Q = animal$q, V2 = animal$v2)$thalf_beta
  }
  if (route == "oral") {
    mrt <- mrt + 1/animal$ka
  }
  c(aucinf = auc_inf, aumcinf = auc_inf*mrt, half.life = half_life)
}

# Integrand of the AUC (moment = 0) or AUMC (moment = 1) of one animal
conc_moment <- function(time, route, animal, moment) {
  time^moment*conc_animal(time, route, animal)
}

# One sparse data set:  BLQ samples are reported as 0
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
