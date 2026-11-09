# What the sparse estimates converge to with infinitely many animals.  For the
# serial-sacrifice scenarios, the population mean concentration at each
# sampling time (the mean over a large virtual population) goes through the
# estimator that the standard error study applies to a data set's means
# (sparse_inputs(), mean_profile(), and the sparse AUC to infinity), with
# sampling to 24 hours (the design) and extended to 48 and 72 hours.  With BLQ
# samples (24 hours only), the population mean at a time counts BLQ samples as
# zero and is zero when more than half of its samples are BLQ, as sparse_mean()
# does; with the log-normal residual error of mean 1, the expected mean of the
# concentrations above the LLOQ and the fraction BLQ have closed forms for each
# animal.
#
# The converged half-life is compared with the typical animal's terminal
# half-life, the local half-life of the population mean curve at tlast
# (log(2)/(-d log(mean)/dt)), and the effective half-life that extrapolates the
# true area after tlast exactly (log(2)*(area after tlast)/(mean at tlast)).
# The true AUC to infinity is the mean of dose/CL.
# The bias of the converged AUC to infinity is split into three parts that sum
# to it:  the AUC to tlast against the exact area, the mean at tlast against
# the population mean there (BLQ samples counted as zero), and the
# extrapolation with the fitted lambda.z against the exact area after tlast.

converged_durations <- c(24, 48, 72)
# The times added to the design's for the longer sampling
converged_extra_times <- c(36, 48, 72)
# The step (hours) of the central difference for the local slope
converged_slope_step <- 1e-3

# The concentrations of every animal (rows) at the times (columns)
conc_matrix <- function(times, route, animals) {
  ret <- matrix(NA_real_, nrow(animals), length(times))
  for (i in seq_len(nrow(animals))) {
    ret[i, ] <- conc_animal(times, route, animals[i, ])
  }
  ret
}

# The population mean at each time (column of `conc`) of samples with the
# residual error of simulate_data(), with BLQ samples counted as zero and a time
# with more than half of its samples BLQ set to zero.  For one animal with
# concentration c and error e (log-normal, mean 1, log sd s), the expected
# value of c*e when c*e >= lloq is c*pnorm((log(c/lloq) + s^2/2)/s), and the
# probability that c*e < lloq is pnorm((log(lloq/c) + s^2/2)/s).
population_blq_mean <- function(conc, lloq) {
  s <- model$sigma
  above <- conc*stats::pnorm((log(conc/lloq) + s^2/2)/s)
  fraction_blq <- colMeans(stats::pnorm((log(lloq/conc) + s^2/2)/s))
  ret <- colMeans(above)
  ret[fraction_blq > 0.5] <- 0
  ret
}

# The area under the population mean curve after a time:  the mean of each
# animal's area, integrated directly so that a small tail keeps its precision
converged_tail_area <- function(animals, route, time) {
  tails <- numeric(nrow(animals))
  for (i in seq_len(nrow(animals))) {
    tails[i] <-
      stats::integrate(conc_moment, time, Inf, route = route, animal = animals[i, ], moment = 0, rel.tol = 1e-10)$value
  }
  mean(tails)
}

# Minus the log slope of the population mean curve at a time (central
# difference)
converged_local_lambda <- function(animals, route, time) {
  means <- colMeans(conc_matrix(time + c(-1, 1)*converged_slope_step, route, animals))
  -(log(means[2]) - log(means[1]))/(2*converged_slope_step)
}

# The sparse estimate from the population means at the sampling times:  the
# means are given as two animals per time with the same concentration, so the
# mean profile is the population means, and the estimate is what the standard
# error study calculates from a data set's means
converged_estimate <- function(times, means, route) {
  d <- data.frame(subject = seq_len(2*length(times)), time = rep(times, each = 2), conc_reported = rep(means, each = 2))
  inputs <- sparse_inputs(d, route)
  profile <- mean_profile(inputs)
  hl <- suppressWarnings(PKNCA::pk.calc.half.life(conc = profile$mean, time = profile$time))
  idx_last <- max(which(profile$mean > 0))
  args <-
    c(
      inputs,
      list(
        lambda.z = hl$lambda.z, lambda.z.time.first = hl$lambda.z.time.first,
        lambda.z.time.last = hl$lambda.z.time.last, lambda.z.n.points = hl$lambda.z.n.points,
        options = list(sparse_lambda_z_se = "none")
      )
    )
  aucinf <- unlist(suppressWarnings(do.call(sparse_inf_functions[[route]]$auc, args)))[[1]]
  clast <- profile$mean[idx_last]
  list(
    lambda.z = hl$lambda.z, time_first = hl$lambda.z.time.first, n_points = hl$lambda.z.n.points,
    aucinf = aucinf, auclast = aucinf - clast/hl$lambda.z,
    clast = clast, tlast = profile$time[idx_last]
  )
}

# One row of the results:  `means` are the sparse means at `times` (BLQ samples
# counted as zero, when there are any), `means_true` the population means there
converged_row <- function(animals, scenario_row, blq, duration, times, means, means_true, aucinf_true) {
  route <- scenario_row$route
  e <- converged_estimate(times, means, route)
  tail_from_tlast <- converged_tail_area(animals, route, e$tlast)
  cbar_tlast <- means_true[times == e$tlast]
  data.frame(
    scenario = scenario_row$scenario, compartments = scenario_row$compartments, route = scenario_row$route,
    elimination = scenario_row$elimination, blq = blq, duration = duration, tlast = e$tlast,
    half_life_typical = animal_inf_parameters(typical_animal(scenario_row), scenario_row$route)[["half.life"]],
    half_life_local = log(2)/converged_local_lambda(animals, route, e$tlast),
    half_life_effective = log(2)*tail_from_tlast/cbar_tlast,
    half_life_converged = log(2)/e$lambda.z,
    half_life_time_first = e$time_first, half_life_n_points = e$n_points,
    percent_extrapolated = 100*tail_from_tlast/aucinf_true,
    bias_trapezoid = 100*(e$auclast - (aucinf_true - tail_from_tlast))/aucinf_true,
    bias_clast = 100*(e$clast - cbar_tlast)/e$lambda.z/aucinf_true,
    bias_lambda_z = 100*(cbar_tlast/e$lambda.z - tail_from_tlast)/aucinf_true,
    bias_total = 100*(e$aucinf - aucinf_true)/aucinf_true
  )
}

# The converged estimates of a population of animals:  one row for each
# sampling duration, and one with BLQ samples (at the scenario's moderate LLOQ)
# for sampling to 24 hours
converged_population <- function(animals, scenario_row) {
  route <- scenario_row$route
  aucinf_true <- mean(model$dose/animals$cl)
  all_times <- c(sampling_times[[route]], converged_extra_times)
  conc <- conc_matrix(all_times, route, animals)
  blq_row <- scenario_row
  blq_row$blq <- "moderate"
  ret <- list()
  for (duration in converged_durations) {
    keep <- all_times <= duration
    times <- all_times[keep]
    means_true <- colMeans(conc[, keep, drop = FALSE])
    ret[[length(ret) + 1]] <- converged_row(animals, scenario_row, "none", duration, times, means_true, means_true, aucinf_true)
    if (duration == 24) {
      means_blq <- population_blq_mean(conc[, keep, drop = FALSE], scenario_lloq(blq_row))
      ret[[length(ret) + 1]] <- converged_row(animals, scenario_row, "moderate", duration, times, means_blq, means_true, aucinf_true)
    }
  }
  do.call(rbind, ret)
}

# The study of one scenario (serial sacrifice without BLQ samples; the BLQ
# rows use the moderate LLOQ of the same route, elimination, and model)
run_converged_study <- function(scenario_row, settings) {
  started <- Sys.time()
  animals <-
    withr::with_seed(
      settings$seed_base_converged + scenario_row$scenario,
      draw_animals(settings$n_converged_animals, scenario_row)
    )
  results <- converged_population(animals, scenario_row)
  with_branch_seconds(results, started)
}
