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
          treatment = trt, PK = exp(logPK), stringsAsFactors = FALSE
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
    PPORRESU = units,
    stringsAsFactors = FALSE
  )
}
