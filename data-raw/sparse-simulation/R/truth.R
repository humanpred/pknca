# The true values that the estimates are compared with.  Each comes from a
# large virtual population drawn under its own seed, and depends only on the
# route, the elimination rate, and the number of compartments (a "truth key").

# The truth keys, in the order whose index sets the seed of each
truth_keys <- function(scenarios) {
  ret <- unique(scenarios[, c("route", "elimination", "compartments")])
  rownames(ret) <- NULL
  ret$truth_index <- seq_len(nrow(ret))
  ret
}

# The first scenario of a truth key (the truth does not depend on the others)
truth_key_scenario <- function(scenarios, key) {
  rows <- which(
    scenarios$route == key$route & scenarios$elimination == key$elimination &
      scenarios$compartments == key$compartments
  )
  scenarios[rows[1], ]
}

# The AUC and AUMC of the population mean curve, with the Monte Carlo standard
# error of each (in percent), for the standard error studies:  the mean of the
# individual values over `n_virtual` animals
true_values <- function(scenarios, key, seed, n_virtual) {
  scenario_row <- truth_key_scenario(scenarios, key)
  route <- scenario_row$route
  animals <- withr::with_seed(seed, draw_animals(n_virtual, scenario_row))
  values <- matrix(NA_real_, n_virtual, 2)
  for (i in seq_len(n_virtual)) {
    values[i, ] <- animal_inf_parameters(animals[i, ], route)[c("aucinf", "aumcinf")]
  }
  truth <- colMeans(values)
  mcse_percent <- 100*apply(values, 2, stats::sd)/sqrt(n_virtual)/truth
  data.frame(
    key[, c("route", "elimination", "compartments")],
    truth_auc = truth[[1]], truth_aumc = truth[[2]],
    mcse_auc = mcse_percent[[1]], mcse_aumc = mcse_percent[[2]],
    row.names = NULL
  )
}

# The scenarios with the truth of their key
add_truth <- function(scenarios, truth) {
  ret <- merge(scenarios, truth[, c("route", "elimination", "compartments", "truth_auc", "truth_aumc")])
  ret <- ret[order(ret$scenario), c(names(scenarios), "truth_auc", "truth_aumc")]
  rownames(ret) <- NULL
  ret
}

# The individual parameters of one animal for the mean-profile study:  the AUC
# and AUMC to 24 hours and to infinity, Cmax (C0 for IV bolus), and the
# terminal half-life
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

# The arithmetic and geometric means of the individual parameters of
# `n_virtual` animals, and the typical animal's parameters
true_targets <- function(scenarios, key, seed, n_virtual) {
  scenario_row <- truth_key_scenario(scenarios, key)
  route <- scenario_row$route
  # The animals are drawn under the seed; the parameters are then deterministic
  animals <- withr::with_seed(seed, draw_animals(n_virtual, scenario_row))
  params <- matrix(NA_real_, n_virtual, 6)
  for (i in seq_len(n_virtual)) {
    params[i, ] <- individual_parameters(animals[i, ], route)
  }
  colnames(params) <- c("auclast", "aucinf", "cmax", "aumclast", "aumcinf", "half.life")
  data.frame(
    route = key$route, elimination = key$elimination, compartments = key$compartments,
    parameter = colnames(params),
    arithmetic = colMeans(params),
    geometric = exp(colMeans(log(params))),
    typical = individual_parameters(typical_animal(scenario_row), route),
    row.names = NULL
  )
}
