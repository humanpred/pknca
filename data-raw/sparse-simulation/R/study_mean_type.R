# The arithmetic and geometric mean profiles for sparse NCA:  relative bias and
# precision of AUClast, AUCinf, Cmax (C0 for IV bolus), AUMClast, AUMCinf, and
# half-life.
#
# Each replicate forms the arithmetic and the geometric mean profile and runs
# pk.nca() on each profile.  The arithmetic mean profile estimates the
# population mean curve, so its target is the arithmetic mean of the individual
# parameters; the geometric mean profile approximates the typical animal, so
# its target is the geometric mean of the individual parameters.  Both targets
# come from a large virtual population of the true individual parameters (no
# residual error).  This study has its own data seeds.

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
  profile <- mean_profile(list(conc = d$conc_reported, time = d$time, subject = d$subject))
  geometric <- numeric(nrow(profile))
  for (i in seq_len(nrow(profile))) {
    rows <- d$time == profile$time[i]
    geometric[i] <- geometric_mean_time(d$conc_reported[rows], d$blq[rows], lloq)
  }
  data.frame(time = profile$time, arithmetic = profile$mean, geometric = geometric)
}

mean_type_parameters <- c("auclast", "aucinf", "cmax", "aumclast", "aumcinf", "half.life")

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
    PKNCA::PKNCAdata(
      PKNCA::PKNCAconc(d_conc, conc ~ time | id),
      PKNCA::PKNCAdose(d_dose, dose ~ time | id, route = if (route == "oral") "extravascular" else "intravascular"),
      intervals = intervals,
      impute = if (route == "oral") "start_conc0" else NA_character_,
      options = list(auc.method = "linear")
    )
  res <- as.data.frame(suppressWarnings(suppressMessages(PKNCA::pk.nca(o_data))))
  values <- stats::setNames(res$PPORRES, res$PPTESTCD)
  stats::setNames(unname(values[params]), names(params))
}

# The mean-profile study on the data sets of one scenario
run_mean_type_study <- function(datasets, scenario_row) {
  started <- Sys.time()
  lloq <- scenario_lloq(scenario_row)
  data_list <- split_datasets(datasets)
  out <- vector("list", length(data_list))
  for (i in seq_along(data_list)) {
    profiles <- mean_profiles(data_list[[i]], lloq)
    replicate <- as.integer(names(data_list)[i])
    out[[i]] <-
      rbind(
        data.frame(
          scenario = scenario_row$scenario, replicate = replicate, mean_type = "arithmetic",
          parameter = mean_type_parameters,
          estimate = nca_profile(profiles$time, profiles$arithmetic, scenario_row$route)
        ),
        data.frame(
          scenario = scenario_row$scenario, replicate = replicate, mean_type = "geometric",
          parameter = mean_type_parameters,
          estimate = nca_profile(profiles$time, profiles$geometric, scenario_row$route)
        )
      )
  }
  with_branch_seconds(do.call(rbind, out), started)
}

summarize_mean_type <- function(results, targets, scenarios) {
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
