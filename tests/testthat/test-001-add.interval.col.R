# Save the original state
original_state <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)

test_that("sparse-derived parameters are each registered exactly once", {
  cols <- get.interval.cols()
  sparse_derived <-
    c("cl.sparse.last", "kel.sparse.last", "mrt.sparse.last",
      "vss.sparse.last", "vz.sparse.last")
  for (param in sparse_derived) {
    expect_equal(sum(names(cols) == param), 1L, info=param)
    # Sparse-only is derived from the registration, not stored:  no dense
    # function, and a sparse estimator
    expect_true(spec_is_sparse_only(cols[[param]]), info=param)
    expect_true(is.na(cols[[param]]$FUN), info=param)
    expect_null(cols[[param]]$sparse, info=param)
  }
  # No parameter name may appear twice in the registry
  expect_equal(anyDuplicated(names(cols)), 0L)
  # Pin the registry size so that a lost or accumulating registration is
  # caught; update the value when a parameter is added or removed.
  expect_length(cols, 237)
})

test_that("add.interval.col", {
  # Invalid inputs fail
  # name
  expect_error(
    add.interval.col(name = 1),
    regexp = "Must be of type 'character'"
  )
  expect_error(
    add.interval.col(name = c("a", "b")),
    regexp = "Must have length 1"
  )
  expect_error(
    add.interval.col(name = ""),
    regexp = "at least 1 character"
  )
  expect_error(
    add.interval.col(name = NA_character_),
    regexp = "may not contain missing values|Contains missing values"
  )
  
  # FUN
  expect_error(
    add.interval.col(name = "a", FUN = c("a", "b")),
    regexp = "Must have length 1"
  )
  expect_error(
    add.interval.col(name = "a", FUN = 1),
    regexp = "Must be of type 'character'"
  )
  expect_error(
    add.interval.col(name = "a", FUN = "this function does not exist", unit_type = "conc", pretty_name = "foo", datatype = "interval", desc = "test addition"),
    class = "pknca_error_fun_not_found"
  )
  
  # unit_type
  expect_error(
    add.interval.col(name = "a", FUN = NA, pretty_name = "a", datatype = "interval", desc = "test addition"),
    regexp = 'argument "unit_type" is missing, with no default'
  )
  expect_error(
    add.interval.col(name = "a", FUN = NA, pretty_name = "a", unit_type = "foo", datatype = "interval", desc = "test addition"),
    regexp = "should be one of .*inverse_time"
  )
  
  # pretty_name checks
  expect_error(
    add.interval.col(name = "a", FUN = NA, unit_type = "conc", pretty_name = 1:2, datatype = "interval", desc = 1),
    regexp = "Must be of type 'character'"
  )
  expect_error(
    add.interval.col(name = "a", FUN = NA, unit_type = "conc", pretty_name = 1, datatype = "interval", desc = 1),
    regexp = "Must be of type 'character'"
  )
  expect_error(
    add.interval.col(name = "a", FUN = NA, unit_type = "conc", pretty_name = "", datatype = "interval", desc = 1),
    regexp = "All elements must have at least 1 characters"
  )
  
  # datatype
  expect_error(
    add.interval.col(name = "a", FUN = NA, unit_type = "conc", pretty_name = "a", datatype = "individual"),
    regexp = "Must be element of set \\{'interval'\\}"
  )
  
  # description
  ## validates desc
  # ---- Valid boundary: exactly 40 characters ----
  expect_no_warning(
    add.interval.col(
      name="a", FUN=NA, unit_type="conc", pretty_name="a", datatype="interval", desc = paste(rep("a", 40), collapse = "") )
  )
  
  # ---- Over-length: 41 characters warns, but still registers ----
  expect_warning(
    add.interval.col(name="a", FUN=NA, unit_type="conc", pretty_name="a", datatype="interval", desc = paste(rep("a", 41), collapse = "") ),
    regexp = "`desc` is 41 characters; SDTM requires <=40",
    class = "pknca_warning_desc_too_long"
  )
  expect_equal(
    PKNCA::get.interval.cols()[["a"]]$desc,
    paste(rep("a", 41), collapse = "")
  )
  
  # ---- NA ----
  expect_error(
    add.interval.col(name="a", FUN=NA, unit_type="conc", pretty_name="a", datatype="interval", desc = NA_character_  )  
  )
  
  # ---- Zero-length character ----
  expect_error(
    add.interval.col(name="a", FUN=NA, unit_type="conc", pretty_name="a", datatype="interval", desc = character(0) )
  )
  
  # ---- Length > 1 ----
  expect_error(
    add.interval.col(name="a", FUN=NA, unit_type="conc", pretty_name="a", datatype="interval", desc = c("a", "b") )
  )
  
  # ---- Wrong type (numeric, not character) ----
  expect_error(
    add.interval.col(name="a", FUN=NA, unit_type="conc", pretty_name="a", datatype="interval", desc = 123 )
  )
  
  expect_error(
    add.interval.col(name="a", FUN=NA, depends = 1, unit_type="conc", pretty_name="a", datatype="interval", desc=1),
    regexp="Must be of type 'character'",
    info="depends column must be a NULL or a character string"
  )
  
  expect_error(
    add.interval.col(name = "a", FUN = NA, unit_type = "conc", pretty_name = "a", datatype = "interval", desc = c("a", "b")),
    regexp = "Must have length 1"
  )
  
  # depends
  expect_error(
    add.interval.col(name = "a", FUN = NA, depends = 1, unit_type = "conc", pretty_name = "a", datatype = "interval", desc = "a"),
    regexp = "Must be of type 'character'"
  )
  
  # values
  expect_error(
    add.interval.col(name = "a", FUN = NA, unit_type = "conc", pretty_name = "a", datatype = "interval", desc = "a", values = NULL),
    class = "pknca_error_values_invalid"
  )
  expect_error(
    add.interval.col(name = "a", FUN = NA, unit_type = "conc", pretty_name = "a", datatype = "interval", desc = "a", values = quote(x) ),
    class = "pknca_error_values_invalid"
  )
  
  # formalsmap
  expect_error(
    add.interval.col(name = "a", FUN = "mean", unit_type = "conc", pretty_name = "foo", formalsmap = NA),
    regexp = "Must be of type 'list'"
  )
  expect_error(
    add.interval.col(name = "a", FUN = "mean", unit_type = "conc", pretty_name = "foo", formalsmap = list(1)),
    regexp = "Must have names"
  )
  expect_error(
    add.interval.col(name = "a", FUN = NA, unit_type = "conc", pretty_name = "foo", formalsmap = list(A = "b")),
    class = "pknca_error_formalsmap_with_na_fun"
  )
  expect_error(
    add.interval.col(name = "a", FUN = "mean", unit_type = "conc", pretty_name = "foo", formalsmap = list(A = "a", "b")),
    regexp = "Must have names"
  )
  expect_error(
    add.interval.col(name = "a", FUN = "mean", unit_type = "conc", pretty_name = "a", formalsmap = list(y = "a")),
    class = "pknca_error_formalsmap_invalid_names"
  )
  expect_error(
    add.interval.col(name = "a", FUN = "mean", unit_type = "conc", pretty_name = "foo", formalsmap = list(x = "a", x = "b")),
    regexp = "Must have unique names"
  )
  
  expect_equal(
    {
      add.interval.col(name="a", FUN=NA, unit_type="conc", pretty_name="a", datatype="interval", desc="test addition")
      get("interval.cols", PKNCA:::.PKNCAEnv)[["a"]]
    },
    list(
      FUN=NA,
      FUN_sparse=NA_character_,
      values=c(FALSE, TRUE),
      unit_type="conc",
      pretty_name="a",
      desc="test addition",
      formalsmap=list(),
      formalsmap_sparse=list(),
      depends=NULL,
      datatype="interval",
      pptestcd_cdisc="a",
      pptest_cdisc="test addition",
      formula=NULL,
      formula_note=NULL,
      tier="uncommon",
      selection=list()
    )
  )
  expect_equal(
    {
      add.interval.col(name="a", FUN="mean", unit_type="conc", pretty_name="a", datatype="interval", desc="test addition")
      get("interval.cols", PKNCA:::.PKNCAEnv)[["a"]]
    },
    list(
      FUN="mean",
      FUN_sparse=NA_character_,
      values=c(FALSE, TRUE),
      unit_type="conc",
      pretty_name="a",
      desc="test addition",
      formalsmap=list(),
      formalsmap_sparse=list(),
      depends=NULL,
      datatype="interval",
      pptestcd_cdisc="a",
      pptest_cdisc="test addition",
      formula=NULL,
      formula_note=NULL,
      tier="uncommon",
      selection=list()
    )
  )
  expect_equal(
    {
      add.interval.col(name="a", FUN="mean", unit_type="conc", pretty_name="a", formalsmap=list(x="values"), desc="test addition")
      get("interval.cols", PKNCA:::.PKNCAEnv)[["a"]]
    },
    list(
      FUN="mean",
      FUN_sparse=NA_character_,
      values=c(FALSE, TRUE),
      unit_type="conc",
      pretty_name="a",
      desc="test addition",
      formalsmap=list(x="values"),
      formalsmap_sparse=list(),
      depends=NULL,
      datatype="interval",
      pptestcd_cdisc="a",
      pptest_cdisc="test addition",
      formula=NULL,
      formula_note=NULL,
      tier="uncommon",
      selection=list()
    )
  )
})

# Reset the original state
assign("interval.cols", original_state, envir=PKNCA:::.PKNCAEnv)

test_that("add.interval.col validates FUN_sparse and formalsmap_sparse", {
  local_interval_cols()
  expect_error(
    add.interval.col(name = "a", FUN = "mean", unit_type = "conc", pretty_name = "a", FUN_sparse = 1),
    regexp = "Must be of type 'character'"
  )
  expect_error(
    add.interval.col(name = "a", FUN = "mean", unit_type = "conc", pretty_name = "a", FUN_sparse = c("mean", "median")),
    regexp = "Must have length 1"
  )
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc", pretty_name = "a",
      FUN_sparse = "this function does not exist"
    ),
    class = "pknca_error_fun_not_found"
  )
  # formalsmap_sparse needs a FUN_sparse to map onto
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc", pretty_name = "a",
      formalsmap_sparse = list(x = "conc")
    ),
    regexp = "`formalsmap_sparse` may not be provided when `FUN_sparse` is NA",
    class = "pknca_error_formalsmap_with_na_fun"
  )
  # and may only name formals of FUN_sparse
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc", pretty_name = "a",
      FUN_sparse = "mean", formalsmap_sparse = list(not_a_formal = "conc")
    ),
    regexp = "All names in `formalsmap_sparse` must be arguments to the function 'mean'",
    class = "pknca_error_formalsmap_invalid_names"
  )
  # A valid pair is stored
  add.interval.col(
    name = "a", FUN = "mean", unit_type = "conc", pretty_name = "a", desc = "test addition",
    FUN_sparse = "mean", formalsmap_sparse = list(x = "conc.sparse")
  )
  stored <- get.interval.cols()[["a"]]
  expect_equal(stored$FUN_sparse, "mean")
  expect_equal(stored$formalsmap_sparse, list(x = "conc.sparse"))
})

test_that("the sparse estimators and the parameters only they can produce are enumerated", {
  # Every parameter that ships with a sparse estimator, and every parameter only
  # such an estimator can produce.  A new registration of either kind must be
  # added here deliberately, because a sparse-only parameter is refused for
  # dense data (see assert_intervals()).
  iv_params <- c("aucivlast", "aucivall", "aucivinf.obs", "aumcivlast", "aumcivall", "aumcivinf.obs")
  iv_companions <- c(paste0(iv_params, "_se"), paste0(iv_params, "_df"))
  expect_setequal(
    fun_sparse_params(),
    c(
      # Both a dense function and a sparse estimator
      "auclast", "aumclast", "aucall", "aumcall", "aucinf.obs", "aumcinf.obs",
      "aucivlast", "aucivall", "aucivinf.obs", "aumcivlast", "aumcivall", "aumcivinf.obs",
      # A sparse estimator and no dense function
      "sparse_auclast", "sparse_aumclast", "cl.sparse.last", "mrt.sparse.last",
      "kel.sparse.last", "vss.sparse.last", "vz.sparse.last"
    )
  )
  expect_setequal(
    sparse_only_params(),
    c(
      # A sparse estimator and no dense function
      "sparse_auclast", "sparse_aumclast", "cl.sparse.last", "mrt.sparse.last",
      "kel.sparse.last", "vss.sparse.last", "vz.sparse.last",
      # Companions:  columns of a sparse estimator's result
      "sparse_auc_se", "sparse_auc_df", "sparse_aumc_se", "sparse_aumc_df",
      "auclast_se", "auclast_df", "aumclast_se", "aumclast_df",
      "aucall_se", "aucall_df", "aumcall_se", "aumcall_df",
      "aucinf.obs_se", "aucinf.obs_df", "aumcinf.obs_se", "aumcinf.obs_df",
      iv_companions
    )
  )
  # A parameter with a dense function as well as an estimator is not sparse-only
  expect_false(any(c("auclast", "aumclast", "aucall", "aumcall", "aucinf.obs", "aumcinf.obs", iv_params) %in% sparse_only_params()))
  # Only the non-deprecated sparse-only parameters are refused for dense data;
  # the deprecated ones are still skipped
  expect_setequal(
    setdiff(sparse_only_params(), names(deprecated_sparse_parameters)),
    c(
      "auclast_se", "auclast_df", "aumclast_se", "aumclast_df",
      "aucall_se", "aucall_df", "aumcall_se", "aumcall_df",
      "aucinf.obs_se", "aucinf.obs_df", "aumcinf.obs_se", "aumcinf.obs_df",
      iv_companions
    )
  )
})

test_that("the retired `sparse` argument of add.interval.col is an error", {
  local_interval_cols()
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc", pretty_name = "a", desc = "test",
      sparse = TRUE
    ),
    regexp = "`sparse` argument is retired.*Register 'a' with `FUN = NA` and `FUN_sparse = ",
    class = "pknca_error_sparse_argument_retired"
  )
  # The default and an explicit FALSE are both accepted, and neither is stored
  expect_no_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc", pretty_name = "a", desc = "test",
      sparse = FALSE
    )
  )
  expect_null(get.interval.cols()[["a"]]$sparse)
  # The replacement the message points at works
  expect_no_error(
    add.interval.col(
      name = "b", FUN = NA, FUN_sparse = "mean", unit_type = "conc",
      pretty_name = "b", desc = "test"
    )
  )
  expect_true(spec_is_sparse_only(get.interval.cols()[["b"]]))
})

test_that("add.interval.col accepts a dense/sparse CDISC mapping", {
  local_interval_cols()
  add.interval.col(
    name = "a", FUN = "mean", unit_type = "conc",
    pretty_name = "a", desc = "test",
    pptestcd_cdisc = list(dense = "AUCLST", sparse = "SPARSEAL"),
    pptest_cdisc = list(dense = "AUC to Last", sparse = "Sparse AUClast")
  )
  stored <- get.interval.cols()[["a"]]
  expect_equal(stored$pptestcd_cdisc$sparse, "SPARSEAL")
  expect_equal(stored$pptest_cdisc$dense, "AUC to Last")
  # aumclast ships with a dense/sparse pptest_cdisc mapping (CDISC has no
  # separate code for a sparsely estimated AUMClast, so only the test name
  # distinguishes it; see R/auc.R)
  expect_equal(
    get.interval.cols()[["aumclast"]]$pptest_cdisc,
    list(dense = "AUMC to Last Nonzero Conc", sparse = "Sparse AUMClast")
  )
})

test_that("fake parameters", {
  add.interval.col(
    name="fake_parameter",
    FUN="mean",
    unit_type="conc",
    pretty_name="a",
    formalsmap=list(x="values"),
    desc="test addition",
    depends="does_not_exist"
  )
  expect_error(
    sort_interval_cols(),
    regexp="Invalid dependencies for interval column \\(please report this as a bug\\): fake_parameter The following dependencies are missing: does_not_exist"
  )
})

test_that("add.interval.col rejects pptestcd_cdisc types", {
  
  # invalid types
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptestcd_cdisc = 123
    ),
    class = "pknca_error_cdisc_invalid_type"
  )
  
  # invalid character values
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptestcd_cdisc = c("PCMAX", "PCMIN")
    ),
    class = "pknca_error_cdisc_character_invalid"
  )
  
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptestcd_cdisc = NA_character_
    ),
    class = "pknca_error_cdisc_character_invalid"
  )
  
  # invalid route mappings
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptestcd_cdisc = list(foo = "PCMAX")
    ),
    class = "pknca_error_cdisc_route_mapping_invalid"
  )
  
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptestcd_cdisc = list(route = "PCMAX")
    ),
    class = "pknca_error_cdisc_route_mapping_invalid"
  )

  # invalid dense/sparse mappings: unlike routes, both keys must be given,
  # each a single code, with nothing else -- including the wrapped
  # list(sparse = list(...)) form that the flat mapping replaced
  for (bad in list(list(sparse = "SPARSEAL"),
                   list(dense = "AUCLST"),
                   list(dense = "AUCLST", sparse = NA_character_),
                   list(dense = "AUCLST", sparse = list("SPARSEAL")),
                   list(sparse = list(dense = "AUCLST", sparse = "SPARSEAL")),
                   list(dense = "AUCLST", sparse = "SPARSEAL", other = "X"))) {
    expect_error(
      add.interval.col(
        name = "a", FUN = "mean", unit_type = "conc",
        pretty_name = "a", desc = "test",
        pptestcd_cdisc = bad
      ),
      class = "pknca_error_cdisc_sparse_mapping_invalid"
    )
  }
})


test_that("add.interval.col rejects pptest_cdisc types", {
  
  # invalid types
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptest_cdisc = 123
    ),
    class = "pknca_error_cdisc_invalid_type"
  )
  
  # invalid character values
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptest_cdisc = c("PCMAX", "PCMIN")
    ),
    class = "pknca_error_cdisc_character_invalid"
  )
  
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptest_cdisc = NA_character_
    ),
    class = "pknca_error_cdisc_character_invalid"
  )
  
  # invalid route mappings
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptest_cdisc = list(foo = "PCMAX")
    ),
    class = "pknca_error_cdisc_route_mapping_invalid"
  )
  
  expect_error(
    add.interval.col(
      name = "a", FUN = "mean", unit_type = "conc",
      pretty_name = "a", desc = "test",
      pptest_cdisc = list(route = "PCMAX")
    ),
    class = "pknca_error_cdisc_route_mapping_invalid"
  )
})

test_that("add.interval.col accepts list for pptestcd_cdisc", {
  add.interval.col(name="a", FUN="mean", unit_type="conc", pretty_name="a",
                   desc="test",
                   pptestcd_cdisc=list(route=list(extravascular="EV", intravascular="IV")),
                   pptest_cdisc="test desc")
  result <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)[["a"]]
  expect_true(is.list(result$pptestcd_cdisc))
  expect_equal(result$pptestcd_cdisc$route$extravascular, "EV")
  expect_equal(result$pptestcd_cdisc$route$intravascular, "IV")
})

test_that("add.interval.col accepts list for pptest_cdisc", {
  add.interval.col(name="a", FUN="mean", unit_type="conc", pretty_name="a",
                   desc="test",
                   pptestcd_cdisc="a",
                   pptest_cdisc=list(route=list(extravascular="Route Test EV", intravascular="Route Test IV")))
  result <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)[["a"]]
  expect_true(is.list(result$pptest_cdisc))
  expect_equal(result$pptest_cdisc$route$extravascular, "Route Test EV")
  expect_equal(result$pptest_cdisc$route$intravascular, "Route Test IV")
})

test_that("parameter names that would collide with the interval-linkage columns are rejected", {
  expect_error(
    add.interval.col(name="myparam_ref", FUN="mean", unit_type="conc",
                     pretty_name="colliding", desc="test"),
    class = "pknca_error_param_name_reserved"
  )
  expect_error(
    add.interval.col(name="interval_id", FUN="mean", unit_type="conc",
                     pretty_name="colliding", desc="test"),
    class = "pknca_error_param_name_reserved"
  )
})

# Reset the original state
assign("interval.cols", original_state, envir=PKNCA:::.PKNCAEnv)

test_that("every parameter's pretty name and description follow the naming rules", {
  cols <- get.interval.cols()
  pretty <- vapply(X = cols, FUN = "[[", "pretty_name", FUN.VALUE = "")
  desc <- vapply(X = cols, FUN = "[[", "desc", FUN.VALUE = "")
  # The symbol for lambda.z is written as math in a pretty name, and as the
  # PKNCA name in a description
  mentions_lambda <- grepl(pattern = "lambda", x = pretty, ignore.case = TRUE)
  expect_true(all(grepl(pattern = "$\\lambda_z$", x = pretty[mentions_lambda], fixed = TRUE)))
  pretty_without_math <- gsub(pattern = "$\\lambda_z$", replacement = "", x = pretty, fixed = TRUE)
  expect_equal(names(pretty)[grepl(pattern = "lambda", x = pretty_without_math, ignore.case = TRUE)], character())
  desc_without_name <- gsub(pattern = "lambda.z", replacement = "", x = desc, fixed = TRUE)
  expect_equal(names(desc)[grepl(pattern = "lambda", x = desc_without_name, ignore.case = TRUE)], character())
  # Each pretty name tells its parameter apart in a summary
  expect_equal(names(pretty)[duplicated(pretty) | duplicated(pretty, fromLast = TRUE)], character())
  # One space between words, no trailing period, and descriptions short enough
  # for SDTM
  expect_equal(names(pretty)[grepl(pattern = "  ", x = pretty, fixed = TRUE)], character())
  expect_equal(names(desc)[grepl(pattern = "  ", x = desc, fixed = TRUE)], character())
  expect_equal(names(pretty)[grepl(pattern = "\\.$", x = pretty)], character())
  expect_equal(names(desc)[grepl(pattern = "\\.$", x = desc)], character())
  expect_equal(names(desc)[nchar(desc) > 40], character())
  # The display form of the AUC, AUMC, and MRT variants joins the qualifiers
  # with commas (AUCinf,obs and AUCint,last), and last and all attach directly
  # (AUClast and AUMCall)
  display_dots <- "(AUM?C|MRT)(int|inf)\\.(inf|obs|pred|last|all)"
  expect_equal(names(pretty)[grepl(pattern = display_dots, x = pretty)], character())
  expect_equal(names(desc)[grepl(pattern = display_dots, x = desc)], character())
  expect_equal(names(pretty)[grepl(pattern = "(AUM?C|MRT),(last|all)", x = pretty)], character())
})

# The text of a line of R or R Markdown that is prose:  comments and roxygen,
# and the string literals of R code (messages, warnings, and other text).
# Inline code, math, and identifiers that only contain a spelling of lambda.z
# as part of a longer name (an option, a function, a condition class) are
# removed, as are CDISC terms, which follow the CDISC spelling.
prose_text <- function(line) {
  if (grepl(pattern = "pptest_cdisc", x = line, fixed = TRUE)) {
    return("")
  }
  text <-
    if (grepl(pattern = "^\\s*#", x = line)) {
      line
    } else {
      paste(regmatches(line, gregexpr(pattern = "\"(?:[^\"\\\\]|\\\\.)*\"", text = line, perl = TRUE))[[1]], collapse = " ")
    }
  text <- gsub(pattern = "`[^`]*`", replacement = "", x = text)
  text <- gsub(pattern = "\\$[^$]*\\$", replacement = "", x = text)
  text <- gsub(pattern = "[[:alnum:]_.]+lambda_?z[[:alnum:]_.]*|lambda_?z[[:alnum:]_.]+", replacement = "", x = text, ignore.case = TRUE)
  # The name of an element of the Tobit fit's parameters
  text <- gsub(pattern = "\"lambda_z\"", replacement = "", x = text, fixed = TRUE)
  # The CDISC spelling in the PPANMETH method text
  gsub(pattern = "Lambda z: ", replacement = "", x = text, fixed = TRUE)
}

# The prose lines of an R Markdown file:  the text outside code chunks
rmd_prose_lines <- function(lines) {
  in_chunk <- cumsum(grepl(pattern = "^\\s*```", x = lines)) %% 2 == 1
  is_fence <- grepl(pattern = "^\\s*```", x = lines)
  ifelse(in_chunk | is_fence, "", lines)
}

test_that("prose spells the parameter lambda.z, or as math, and never lambda_z, lambdaz, or Lambda z", {
  pkg_dir <- test_path("..", "..")
  skip_if_not(dir.exists(file.path(pkg_dir, "R")), "The package source is needed")
  # The math form (with a backslash) is allowed, also inside display math
  bad_spelling <- "(?<!\\\\)lambda_z|lambdaz|lambda\\s+z"
  found <- character()
  for (current_file in list.files(file.path(pkg_dir, "R"), pattern = "\\.R$", full.names = TRUE)) {
    current_lines <- readLines(current_file, warn = FALSE)
    prose <- vapply(X = current_lines, FUN = prose_text, FUN.VALUE = "", USE.NAMES = FALSE)
    bad <- grepl(pattern = bad_spelling, x = prose, ignore.case = TRUE, perl = TRUE)
    found <- c(found, sprintf("%s:%d: %s", basename(current_file), which(bad), current_lines[bad]))
  }
  for (current_file in list.files(file.path(pkg_dir, "vignettes"), pattern = "\\.Rmd$", full.names = TRUE)) {
    current_lines <- readLines(current_file, warn = FALSE)
    prose <- rmd_prose_lines(current_lines)
    prose <- gsub(pattern = "`[^`]*`", replacement = "", x = prose)
    prose <- gsub(pattern = "\\$[^$]*\\$", replacement = "", x = prose)
    bad <- grepl(pattern = bad_spelling, x = prose, ignore.case = TRUE, perl = TRUE)
    found <- c(found, sprintf("%s:%d: %s", basename(current_file), which(bad), current_lines[bad]))
  }
  expect_equal(found, character())
})

test_that("the prose check finds the spellings it is meant to find", {
  expect_equal(prose_text("#' The lambda_z of the fit"), "#' The lambda_z of the fit")
  expect_equal(prose_text("  rlang::warn(\"Lambda z is missing\")"), "\"Lambda z is missing\"")
  # Identifiers, inline code, math, CDISC terms, and code outside strings are
  # not prose
  expect_equal(prose_text("#' The `sparse_lambda_z_se` option"), "#' The  option")
  expect_equal(prose_text("#' Uses sparse_lambda_z_se and assert_lambdaz"), "#' Uses  and ")
  expect_equal(prose_text("  pretty_name=\"First time for $\\\\lambda_z$\","), "\"First time for \"")
  expect_equal(prose_text("  pptest_cdisc=\"Lambda z\","), "")
  expect_equal(prose_text("  lambda_z <- 2"), "")
  expect_equal(prose_text("  attr(ret, \"method\") <- \"Lambda z: Manual selection\""), "\"method\" \"Manual selection\"")
  expect_equal(rmd_prose_lines(c("text lambda z", "```{r}", "lambda_z <- 1", "```", "after")), c("text lambda z", "", "", "", "after"))
})
