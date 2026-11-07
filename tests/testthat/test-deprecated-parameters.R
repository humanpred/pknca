# Every deprecated parameter name is a copy of the parameter that replaced it,
# so it keeps giving the values it always has

test_that("every deprecated name is registered as a copy of its replacement", {
  cols <- get.interval.cols()
  summary_instructions <- get("summary", envir = PKNCA:::.PKNCAEnv)
  # The replacements are registered and are not themselves deprecated
  expect_true(all(names(deprecated_renamed_parameters) %in% names(cols)))
  expect_true(all(deprecated_renamed_parameters %in% names(cols)))
  expect_false(any(deprecated_renamed_parameters %in% names(deprecated_renamed_parameters)))
  # The tier is the one field that differs (a deprecated name is never
  # common)
  compared_fields <- setdiff(union(names(cols[["cl.inf.obs"]]), names(cols[["cl.obs"]])), "tier")
  for (old in names(deprecated_renamed_parameters)) {
    new <- deprecated_renamed_parameters[[old]]
    expect_equal(cols[[old]][compared_fields], cols[[new]][compared_fields], info = old)
    expect_equal(cols[[old]]$tier, "uncommon", info = old)
    expect_equal(summary_instructions[[old]], summary_instructions[[new]], info = old)
  }
})

test_that("a deprecated name gives the value of its replacement and warns", {
  d_conc <- data.frame(conc = c(0, 2, 4, 3, 2, 1, 0.5), time = c(0, 0.5, 1, 2, 4, 8, 12))
  d_dose <- data.frame(dose = 10, time = 0)
  pairs <- c(cl.obs = "cl.inf.obs", vz.obs = "vz.inf.obs", aucpext.obs = "aucpext.inf.obs")
  intervals <- data.frame(start = 0, end = Inf)
  intervals[c(names(pairs), pairs)] <- TRUE
  # The warning is given once per session for each set of deprecated names
  rlang::reset_warning_verbosity(
    paste(c("pknca_deprecated_renamed", sort(names(pairs))), collapse = "_")
  )
  expect_warning(
    o_data <-
      PKNCAdata(
        PKNCAconc(d_conc, conc ~ time),
        PKNCAdose(d_dose, dose ~ time),
        intervals = intervals
      ),
    regexp = "aucpext.obs.*cl.obs.*vz.obs",
    class = "pknca_warning_deprecated_parameter"
  )
  o_nca <- suppressWarnings(pk.nca(o_data))
  value <- stats::setNames(as.data.frame(o_nca)$PPORRES, as.data.frame(o_nca)$PPTESTCD)
  for (old in names(pairs)) {
    expect_true(is.finite(value[[old]]), info = old)
    expect_equal(value[[old]], value[[pairs[[old]]]], info = old)
  }
})
