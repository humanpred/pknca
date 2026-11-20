# Every earlier parameter name is an alias of the parameter that replaced it,
# so it keeps giving the values it always has

test_that("every earlier name is registered as an alias of its replacement", {
  cols <- get.interval.cols()
  summary_instructions <- get("summary", envir = PKNCA:::.PKNCAEnv)
  # The replacements are registered and are not themselves deprecated
  expect_true(all(names(parameter_renames()) %in% names(cols)))
  expect_true(all(parameter_renames() %in% names(cols)))
  expect_false(any(parameter_renames() %in% names(parameter_renames())))
  # The tier is the one field that differs (an earlier name is never common),
  # beside the fields that link the two
  alias_fields <- c("tier", "historical_names", "historical_of")
  for (old in pknca_parameter_renames()$historical) {
    new <- parameter_renames()[[old]]
    # Every field of either entry, so a field one of them lacks is a difference
    compared_fields <- setdiff(union(names(cols[[old]]), names(cols[[new]])), alias_fields)
    expect_equal(cols[[old]][compared_fields], cols[[new]][compared_fields], info = old)
    expect_equal(cols[[old]]$historical_of, new, info = old)
    expect_null(cols[[old]]$historical_names, info = old)
    expect_true(old %in% cols[[new]]$historical_names, info = old)
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
    regexp = paste0(
      "^These NCA parameters are deprecated, and the old names keep working; use the new names instead:\n",
      "  aucpext[.]obs -> aucpext[.]inf[.]obs\n  cl[.]obs -> cl[.]inf[.]obs\n  vz[.]obs -> vz[.]inf[.]obs"
    ),
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
  output_names <- deprecated_output_names(names(parameter_renames()))
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
    new <- parameter_renames()[[old]]
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

test_that("pknca_parameter_renames() lists the 54 earlier names from the registry", {
  renames <- pknca_parameter_renames()
  expect_named(renames, c("historical", "current"))
  expect_equal(nrow(renames), 54L)
  expect_equal(renames$historical, sort(renames$historical, method = "radix"))
  expect_equal(renames[renames$historical %in% c("cav", "cav.dn", "count_conc"), "current"], c("cav.last", "cav.last.dn", "count.conc"))
  # Each current name declares its earlier names, and the dose-normalized one
  # takes them from its base by rule
  cols <- get.interval.cols()
  for (i in seq_len(nrow(renames))) {
    expect_true(renames$historical[i] %in% cols[[renames$current[i]]]$historical_names, info = renames$historical[i])
  }
  expect_equal(cols[["cav.last.dn"]]$historical_names, "cav.dn")
  # The aliases are the last entries of the registry, in sorted order
  n <- length(cols)
  expect_equal(names(cols)[(n - 53):n], renames$historical)
})

test_that("add.interval.col() checks earlier names and keeps them when a parameter is registered again", {
  saved <- get("interval.cols", envir = PKNCA:::.PKNCAEnv)
  withr::defer(assign("interval.cols", saved, envir = PKNCA:::.PKNCAEnv))
  add.interval.col("test.renamed", FUN = NA, unit_type = "unitless", pretty_name = "Test", historical_names = "test_old")
  expect_equal(get.interval.cols()[["test_old"]]$historical_of, "test.renamed")
  # Registered again without the argument, it keeps its earlier name
  add.interval.col("test.renamed", FUN = NA, unit_type = "unitless", pretty_name = "Test again")
  expect_equal(get.interval.cols()[["test_old"]]$historical_of, "test.renamed")
  expect_equal(get.interval.cols()[["test_old"]]$pretty_name, "Test again")
  # An earlier name that is a parameter, an earlier name of another parameter,
  # or the parameter itself
  expect_error(
    add.interval.col("test.other", FUN = NA, unit_type = "unitless", pretty_name = "Test", historical_names = "auclast"),
    class = "pknca_error_historical_name_conflict"
  )
  expect_error(
    add.interval.col("test.other", FUN = NA, unit_type = "unitless", pretty_name = "Test", historical_names = "test_old"),
    class = "pknca_error_historical_name_conflict"
  )
  expect_error(
    add.interval.col("test.other", FUN = NA, unit_type = "unitless", pretty_name = "Test", historical_names = "test.other"),
    class = "pknca_error_historical_name_conflict"
  )
  # An earlier name given twice, or not as non-empty names
  expect_error(
    add.interval.col("test.other", FUN = NA, unit_type = "unitless", pretty_name = "Test", historical_names = c("a", "a")),
    class = "pknca_error_historical_name_conflict",
    regexp = "'a' given more than once as an earlier name of 'test.other'"
  )
  for (bad in list(1, NA_character_, "", c("b", NA))) {
    expect_error(
      add.interval.col("test.other", FUN = NA, unit_type = "unitless", pretty_name = "Test", historical_names = bad),
      class = "pknca_error_historical_names_invalid"
    )
  }
  expect_false("test.other" %in% names(get.interval.cols()))
})

test_that("a parameter registered under an earlier name replaces the alias for the session", {
  local_interval_cols()
  cols_before <- get.interval.cols()
  position <- match("cl.obs", names(cols_before))
  expect_equal(cols_before[["cl.obs"]]$historical_of, "cl.inf.obs")
  expect_message(
    add.interval.col(
      "cl.obs", FUN = "mean", values = c(FALSE, TRUE), unit_type = "conc",
      pretty_name = "My clearance", desc = "My clearance", formalsmap = list(x = "conc")
    ),
    class = "pknca_message_historical_name_replaced",
    regexp = "'cl.obs' was an earlier name of 'cl.inf.obs'"
  )
  cols <- get.interval.cols()
  # The user's parameter, in the place the alias had
  expect_equal(match("cl.obs", names(cols)), position)
  expect_equal(names(cols), names(cols_before))
  expect_null(cols[["cl.obs"]]$historical_of)
  expect_equal(cols[["cl.obs"]]$FUN, "mean")
  expect_equal(cols[["cl.obs"]]$pretty_name, "My clearance")
  # cl.obs was the one earlier name of cl.inf.obs, which now has none
  expect_equal(cols_before[["cl.inf.obs"]]$historical_names, "cl.obs")
  expect_null(cols[["cl.inf.obs"]]$historical_names)
  expect_false("cl.obs" %in% pknca_parameter_renames()$historical)
  expect_equal(nrow(pknca_parameter_renames()), 53L)
  # Registering cl.inf.obs again does not bring the alias back
  spec <- cols[["cl.inf.obs"]]
  do.call(add.interval.col, c(list(name = "cl.inf.obs"), spec[setdiff(names(spec), c("historical_names", "historical_of"))]))
  expect_equal(get.interval.cols()[["cl.obs"]]$FUN, "mean")

  # pk.nca() calculates the user's parameter, without the deprecation warning
  d_conc <- data.frame(conc = c(0, 2, 4, 3, 2, 1, 0.5), time = c(0, 0.5, 1, 2, 4, 8, 12))
  intervals <- data.frame(start = 0, end = Inf, cl.obs = TRUE)
  expect_no_warning(
    d_res <- as.data.frame(pk.nca(PKNCAdata(PKNCAconc(d_conc, conc~time), intervals = intervals)))
  )
  expect_equal(d_res$PPTESTCD, "cl.obs")
  expect_equal(d_res$PPORRES, mean(d_conc$conc))
})

test_that("a parameter registered after the package is loaded comes after the earlier names", {
  local_interval_cols()
  cols_before <- names(get.interval.cols())
  add.interval.col(
    "test.after.load", FUN = "mean", values = c(FALSE, TRUE), unit_type = "conc",
    pretty_name = "Test", desc = "Test", formalsmap = list(x = "conc")
  )
  expect_equal(names(get.interval.cols()), c(cols_before, "test.after.load"))
  # Its own earlier names follow it, and the package's aliases stay in place
  add.interval.col(
    "test.after.load.2", FUN = "mean", values = c(FALSE, TRUE), unit_type = "conc",
    pretty_name = "Test", desc = "Test", formalsmap = list(x = "conc"),
    historical_names = c("test_z_old", "test_a_old")
  )
  expect_equal(
    names(get.interval.cols()),
    c(cols_before, "test.after.load", "test.after.load.2", "test_a_old", "test_z_old")
  )
})

test_that("interval_cols_aliases_last() puts the aliases after the parameters, sorted", {
  current <-
    list(
      a = list(), b_old = list(historical_of = "b"), b = list(), a_old = list(historical_of = "a"), c = list()
    )
  expect_named(PKNCA:::interval_cols_aliases_last(current), c("a", "b", "c", "a_old", "b_old"))
})

test_that("interval_cols_clear_caches() clears every cache of the registry, and results do not change", {
  d_conc <- data.frame(conc = c(0, 2, 4, 3, 2, 1, 0.5), time = c(0, 0.5, 1, 2, 4, 8, 12))
  o_data <- PKNCAdata(PKNCAconc(d_conc, conc~time), intervals = data.frame(start = 0, end = Inf, cl.inf.obs = TRUE, auclast = TRUE))
  d_before <- suppressWarnings(as.data.frame(pk.nca(o_data)))
  # Fill every cache
  PKNCA:::parameter_classification()
  PKNCA:::interval_consistent_sets()
  cache_names <- PKNCA:::interval_cols_cache_names()
  expect_equal(
    cache_names,
    c("parameter_classification", "auc_basis_families", "interval.cols_derived", "interval_consistent_sets")
  )
  for (cache_name in cache_names) {
    if (!exists(cache_name, envir = PKNCA:::.PKNCAEnv, inherits = FALSE)) {
      # A placeholder, which the clearing below removes
      assign(cache_name, "filled", envir = PKNCA:::.PKNCAEnv)
    }
  }
  PKNCA:::interval_cols_clear_caches()
  for (cache_name in cache_names) {
    expect_false(exists(cache_name, envir = PKNCA:::.PKNCAEnv, inherits = FALSE), info = cache_name)
  }
  expect_identical(suppressWarnings(as.data.frame(pk.nca(o_data))), d_before)
})
