# Two study parts with two subjects each; subject ids are unique across parts.
make_part_results <- function(dose_groups = c("part", "ID"), intervals_part = TRUE) {
  d_conc <- generate.conc(4, 1, 0:24)
  d_conc$part <- ifelse(d_conc$ID <= 2, "SAD", "MAD")
  d_dose <- generate.dose(d_conc)
  d_dose$part <- ifelse(d_dose$ID <= 2, "SAD", "MAD")
  if (!("part" %in% dose_groups)) {
    d_dose$part <- NULL
  }
  intervals <- data.frame(
    part = rep(c("SAD", "MAD"), each = 2),
    ID = 1:4,
    start = 0,
    end = 24,
    cmax = TRUE,
    auclast = TRUE
  )
  if (!intervals_part) {
    intervals$part <- NULL
  }
  my_conc <- PKNCAconc(d_conc, conc~time|part+ID)
  my_dose <- PKNCAdose(
    d_dose,
    stats::as.formula(sprintf("dose~time|%s", paste(dose_groups, collapse = "+")))
  )
  pk.nca(PKNCAdata(my_conc, my_dose, intervals = intervals))
}

# The provenance of `expected` as it should be after an operation named by
# `verb` was applied to `original`
set_provenance_marker <- function(expected, verb, original) {
  attr(expected, "provenance")$hash <-
    paste(verb, "from", attr(original, "provenance", exact = TRUE)$hash)
  expected
}
