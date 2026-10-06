# Concentration data for the missing-sample and Tmax-coverage tests:  six
# subjects sampled at the same nominal times (in hours), with the actual time
# equal to the nominal time.
#
# * Subjects 1 to 4 have every sample, with Tmax at 1, 1, 2, and 2 hours.
# * Subject 5 has Tmax at 2 hours and an NA concentration at 1 hour.
# * Subject 6 has samples only at 0, 8, and 12 hours, so its Tmax is 8 hours.
#
# The Tmax values 1, 1, 2, 2, 2, and 8 have quartiles 1.25 and 2, so the Tmax
# range is 0.125 to 3.125 hours:  subject 6 has no sample in it, and subject 5
# is missing the 1-hour sample within it.
tmax_coverage_conc <- function() {
  nominal <- c(0, 0.5, 1, 2, 4, 8, 12)
  peak <- c(1, 1, 2, 2, 2)
  ret <- data.frame()
  for (current_subject in seq_along(peak)) {
    ret <-
      rbind(
        ret,
        data.frame(
          subject = current_subject,
          time_nominal = nominal,
          time = nominal,
          conc = ifelse(nominal == 0, 0, 10 / (1 + abs(nominal - peak[current_subject])))
        )
      )
  }
  ret$conc[ret$subject == 5 & ret$time_nominal == 1] <- NA
  rbind(
    ret,
    data.frame(subject = 6, time_nominal = c(0, 8, 12), time = c(0, 8, 12), conc = c(0, 3, 1))
  )
}

# NCA results of tmax_coverage_conc() over 0 to 24 hours
tmax_coverage_results <- function(d_conc = tmax_coverage_conc(), time.nominal = "time_nominal", timeu = "hr") {
  o_conc <-
    if (is.null(time.nominal)) {
      PKNCAconc(d_conc, conc ~ time | subject, timeu = timeu, concu = "ng/mL")
    } else {
      PKNCAconc(d_conc, conc ~ time | subject, time.nominal = time.nominal, timeu = timeu, concu = "ng/mL")
    }
  o_data <-
    PKNCAdata(
      o_conc,
      intervals = data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE, auclast = TRUE)
    )
  suppressMessages(pk.nca(o_data))
}
