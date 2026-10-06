# Deterministic generator for replicate-design bioequivalence data.
#
# It draws a between-subject random effect plus treatment-specific
# within-subject errors so that the within-reference and within-test
# coefficients of variation are controllable.  The expected values pinned in
# test-bioequivalence-assess.R were computed from the data this function
# produces and were cross-checked against PowerTOST and replicateBE during
# development (those packages are not dependencies of PKNCA).
generate_be_replicate <- function(nsub = 24, seed = 20240501,
                                  design = c("full", "partial", "2x2"),
                                  cv_wr = 0.45, cv_wt = 0.40, gmr = 1.05,
                                  bsv = 0.40, mu = log(100)) {
  design <- match.arg(design)
  seqs <- switch(
    design,
    full = c("TRTR", "RTRT"),
    partial = c("TRR", "RTR", "RRT"),
    "2x2" = c("TR", "RT")
  )
  set.seed(seed)
  swR <- sqrt(log(cv_wr^2 + 1))
  swT <- sqrt(log(cv_wt^2 + 1))
  seq_assign <- rep(seqs, length.out = nsub)
  b <- stats::rnorm(nsub, sd = bsv)
  rows <- list()
  for (i in seq_len(nsub)) {
    trts <- strsplit(seq_assign[i], "")[[1]]
    for (p in seq_along(trts)) {
      trt <- trts[p]
      sw <- if (trt == "R") swR else swT
      eff <- if (trt == "T") log(gmr) else 0
      logPK <- mu + eff + b[i] + stats::rnorm(1, sd = sw)
      rows[[length(rows) + 1]] <-
        data.frame(
          subject = i, sequence = seq_assign[i], period = p,
          treatment = trt, PK = exp(logPK)
        )
    }
  }
  out <- do.call(rbind, rows)
  out$subject <- factor(out$subject)
  out$sequence <- factor(out$sequence)
  out$period <- factor(out$period)
  out$treatment <- factor(out$treatment, levels = c("R", "T"))
  out
}

# Convert generate_be_replicate() output into the long PPTESTCD/PPORRES format
# that be_assess() consumes, with a per-endpoint units column (PPORRESU).
be_replicate_long <- function(d, endpoint = "auclast", units = if (endpoint == "cmax") "ng/mL" else "h*ng/mL") {
  data.frame(
    subject = d$subject, sequence = d$sequence, period = d$period,
    treatment = d$treatment, PPTESTCD = endpoint, PPORRES = d$PK,
    PPORRESU = units
  )
}

# Deterministic parallel-design data (one observation per subject) with
# arm-specific log-scale means and standard deviations and a body-weight
# covariate with a known log-linear effect (`wt_slope` per kg from 70 kg).
generate_be_parallel <- function(n_per_arm = 20, seed = 20260927,
                                 effect = c(R = 0, T1 = log(1.10), T2 = log(0.90)),
                                 sd = c(R = 0.20, T1 = 0.50, T2 = 0.30),
                                 wt_slope = 0.01, mu = log(100)) {
  set.seed(seed)
  arm <- rep(names(effect), each = n_per_arm)
  wt <- round(stats::rnorm(length(arm), mean = 70, sd = 10))
  data.frame(
    subject = seq_along(arm), period = 1L, treatment = arm, WT = wt,
    PPTESTCD = "auclast",
    PPORRES = exp(mu + effect[arm] + wt_slope * (wt - 70) + stats::rnorm(length(arm), sd = sd[arm])),
    PPORRESU = "h*ng/mL"
  )
}

# Deterministic three-period, three-treatment Williams-type crossover (each
# subject receives R, T1, and T2 once) with treatment-specific within-subject
# standard deviations.
generate_be_williams <- function(nsub = 18, seed = 20260928,
                                 effect = c(R = 0, T1 = log(1.05), T2 = log(0.85)),
                                 sd = c(R = 0.15, T1 = 0.35, T2 = 0.25),
                                 bsv = 0.3, mu = log(100)) {
  set.seed(seed)
  seqs <- list(
    c("R", "T1", "T2"), c("T1", "T2", "R"), c("T2", "R", "T1"),
    c("R", "T2", "T1"), c("T1", "R", "T2"), c("T2", "T1", "R")
  )
  b <- stats::rnorm(nsub, sd = bsv)
  rows <- list()
  for (i in seq_len(nsub)) {
    trts <- seqs[[(i - 1) %% length(seqs) + 1]]
    rows[[i]] <- data.frame(
      subject = i, sequence = paste(trts, collapse = "-"), period = seq_along(trts),
      treatment = trts, PPTESTCD = "auclast",
      PPORRES = exp(mu + effect[trts] + b[i] + stats::rnorm(length(trts), sd = sd[trts])),
      PPORRESU = "h*ng/mL"
    )
  }
  do.call(rbind, rows)
}
