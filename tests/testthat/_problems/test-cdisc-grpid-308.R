# Extracted from test-cdisc-grpid.R:308

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "PKNCA", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
grpid_results <- function(parts = "A", periods = 1:2, windows = list(c(0, 4), c(0, 2)), subjects = 1, ...) {
  groups <- expand.grid(Part = parts, Period = periods, subject = subjects, stringsAsFactors = FALSE)
  d_conc <- merge(groups, data.frame(time = 0:101), by = NULL)
  d_conc$analyte <- "DRUG"
  d_conc$conc <- rep(c(0, 2, 1, 0.5, 0.25, 0.1), length.out = nrow(d_conc))
  d_dose <- groups
  d_dose$time <- 0
  d_dose$dose <- 10
  d_intervals <-
    merge(
      groups,
      data.frame(
        start = vapply(windows, FUN = function(x) x[1], FUN.VALUE = 1),
        end = vapply(windows, FUN = function(x) x[2], FUN.VALUE = 1),
        cmax = TRUE,
        tmax = TRUE
      ),
      by = NULL
    )
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | Part + Period + subject / analyte),
      PKNCAdose(d_dose, dose ~ time | Part + Period + subject),
      intervals = d_intervals,
      ...
    )
  suppressMessages(pk.nca(o_data))
}
grpid_text <- function(results, ...) {
  ret <- as.data.frame(results, out_format = "cdisc", ...)
  ret <- ret[order(ret$Part, ret$Period, ret$subject, ret$end, ret$PPTESTCD), ]
  ret$PPGRPID
}

# test -------------------------------------------------------------------------
o_nca <- grpid_results(parts = c("A", "B.1"), periods = 1)
expect_error(
    as.data.frame(o_nca, out_format = "cdisc", grpid_cols = c(Part = "")),
    class = "pknca_error_grpid_value_invalid",
    regexp = "Part.*'\\.'.*\"B\\.1\""
  )
o_nca_empty <- grpid_results(parts = c("A", ""), periods = 1)
expect_error(
    as.data.frame(o_nca_empty, out_format = "cdisc", grpid_cols = c(Part = "")),
    class = "pknca_error_grpid_value_invalid",
    regexp = "Part.*empty.*\"A\", \"\""
  )
o_nca_na <- grpid_results(periods = 1)
o_nca_na$result$Part[1] <- NA
expect_error(
    as.data.frame(o_nca_na, out_format = "cdisc", grpid_cols = c(Part = "")),
    class = "pknca_error_grpid_value_invalid",
    regexp = "Part.*missing.*\"A\", NA"
  )
