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

test_that("a deprecated name for an output of another calculation gives its replacement's rows", {
  # Every deprecated name without a calculation function of its own is an
  # output of the half-life calculation; one that is not would be missing from
  # these results and fail below
  output_names <- deprecated_output_names(names(deprecated_renamed_parameters))
  expect_setequal(output_names, c("adj_tobit_residual", "lambda.z.n.points_blq", "tobit_residual"))
  lloq <- 1
  conc_true <- c(10, 5, 2.5, 1.25, 0.5, 0.2)
  d_conc <- data.frame(subject = 1L, time = 0:5, conc = ifelse(conc_true < lloq, 0, conc_true))
  d_dose <- data.frame(subject = 1L, time = 0, dose = 100)
  intervals <- data.frame(start = 0, end = Inf)
  intervals[output_names] <- TRUE
  o_data <-
    suppressWarnings(PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | subject, lloq = lloq),
      PKNCAdose(d_dose, dose ~ time | subject),
      intervals = intervals,
      options = list(hl_method = "tobit", allow.tmax.in.half.life = TRUE, min.hl.points = 3)
    ))
  o_nca <- suppressMessages(pk.nca(o_data))
  res <- as.data.frame(o_nca)
  for (old in output_names) {
    new <- deprecated_renamed_parameters[[old]]
    expect_equal(sum(res$PPTESTCD == old), 1L, info = old)
    expect_true(is.finite(res$PPORRES[res$PPTESTCD == old]), info = old)
    expect_equal(res[res$PPTESTCD == old, setdiff(names(res), "PPTESTCD")], res[res$PPTESTCD == new, setdiff(names(res), "PPTESTCD")], ignore_attr = TRUE, info = old)
  }
  expect_equal(res$PPORRES[res$PPTESTCD == "lambda.z.n.points_blq"], 2)
  # Only what was requested is kept when filtering, and the summary has a value
  res_requested <- as.data.frame(o_nca, filter_requested = TRUE)
  expect_setequal(intersect(res_requested$PPTESTCD, output_names), output_names)
  summary_text <- as.data.frame(summary(o_nca))
  expect_false(any(summary_text[, output_names] %in% "NC"))
})

test_that("exclusion rules read a parameter requested only by a deprecated name", {
  d_conc <- data.frame(conc = c(1.1^(3:0), 1.1), time = 0:4, subject = 1)
  o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
  o_data_new <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, aucpext.inf.obs = TRUE, aucinf.obs = TRUE))
  o_data_old <- suppressWarnings(PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, aucpext.obs = TRUE, aucinf.obs = TRUE)))
  excluded_new <- as.data.frame(exclude(suppressMessages(pk.nca(o_data_new)), FUN = exclude_nca_max.aucinf.pext(20)))
  excluded_old <- as.data.frame(exclude(suppressMessages(pk.nca(o_data_old)), FUN = exclude_nca_max.aucinf.pext(20)))
  expect_equal(excluded_old$exclude[excluded_old$PPTESTCD == "aucinf.obs"], "aucpext > 20")
  expect_equal(excluded_old$exclude[excluded_old$PPTESTCD == "aucpext.obs"], "aucpext > 20")
  expect_equal(excluded_old$exclude, excluded_new$exclude)

  o_data_count <- suppressWarnings(PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, count_conc_measured = TRUE, auclast = TRUE)))
  excluded_count <-
    as.data.frame(exclude(suppressMessages(pk.nca(o_data_count)), FUN = exclude_nca_count_conc_measured(min_count = 20)))
  expect_equal(excluded_count$exclude[excluded_count$PPTESTCD == "auclast"], "count.conc.measured < 20")
  # With both names requested, the parameter's own name is read, and both
  # rows are excluded
  expect_equal(parameter_and_deprecated_names("count.conc.measured"), c("count.conc.measured", "count_conc_measured"))
  o_data_both <-
    suppressWarnings(PKNCAdata(
      o_conc,
      intervals = data.frame(start = 0, end = Inf, aucpext.obs = TRUE, aucpext.inf.obs = TRUE, aucinf.obs = TRUE)
    ))
  excluded_both <- as.data.frame(exclude(suppressMessages(pk.nca(o_data_both)), FUN = exclude_nca_max.aucinf.pext(20)))
  expect_equal(
    excluded_both$exclude[excluded_both$PPTESTCD %in% c("aucpext.obs", "aucpext.inf.obs", "aucinf.obs")],
    rep("aucpext > 20", 3)
  )
  # A rule built on the new name reads, and excludes, a parameter requested
  # only by its old name
  result_old <- suppressMessages(pk.nca(o_data_old))
  excluded_by_param <-
    as.data.frame(exclude(result_old, FUN = exclude_nca_by_param("aucpext.inf.obs", max_thr = 1)))
  expect_equal(excluded_by_param$exclude[excluded_by_param$PPTESTCD == "aucpext.obs"], "aucpext.inf.obs > 1")
  expect_true(is.na(excluded_by_param$exclude[excluded_by_param$PPTESTCD == "aucinf.obs"]))
})

test_that("each CDISC PPTESTCD code names one PPTEST", {
  # Parameters may share a code only when they are one CDISC parameter (the
  # bioavailability family is FAB), so one code with two PPTEST texts is a
  # collision
  codes <- pknca_cdisc_codes()
  codes <- codes[!is.na(codes$pptestcd_cdisc), ]
  n_test <- tapply(codes$pptest_cdisc, codes$pptestcd_cdisc, function(x) length(unique(x)))
  expect_equal(names(n_test)[n_test > 1], character())
})
