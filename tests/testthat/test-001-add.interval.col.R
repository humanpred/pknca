# Save the original state
original_state <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)

test_that("sparse-derived parameters are each registered exactly once", {
  cols <- get.interval.cols()
  sparse_derived <-
    c("cl.sparse.last", "kel.sparse.last", "mrt.sparse.last",
      "vss.sparse.last", "vz.sparse.last")
  for (param in sparse_derived) {
    expect_equal(sum(names(cols) == param), 1L, info=param)
    expect_true(cols[[param]]$sparse, info=param)
  }
  # No parameter name may appear twice in the registry
  expect_equal(anyDuplicated(names(cols)), 0L)
  # Pin the registry size so that a lost or accumulating registration is
  # caught; update the value when a parameter is added or removed.
  expect_length(cols, 225)
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
      sparse=FALSE,
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
      sparse=FALSE,
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
      sparse=FALSE,
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
  # Every parameter that ships with a sparse estimator, and every companion that
  # only such an estimator returns.  A new registration of either kind must be
  # added here deliberately, because a sparse-only parameter is refused for
  # dense data (see assert_intervals()).
  expect_equal(fun_sparse_params(), c("auclast", "aumclast"))
  expect_setequal(
    sparse_only_params(),
    c("auclast_se", "auclast_df", "aumclast_se", "aumclast_df")
  )
  # The older sparse-only registrations keep the `sparse` flag and are not
  # treated as companions
  expect_false(any(c("sparse_auc_se", "sparse_aumc_se") %in% sparse_only_params()))
})

test_that("add.interval.col accepts a sparse-keyed CDISC mapping", {
  local_interval_cols()
  add.interval.col(
    name = "a", FUN = "mean", unit_type = "conc",
    pretty_name = "a", desc = "test",
    pptestcd_cdisc = list(sparse = list(dense = "AUCLST", sparse = "SPARSEAL")),
    pptest_cdisc = list(sparse = list(dense = "AUC to Last", sparse = "Sparse AUClast"))
  )
  stored <- get.interval.cols()[["a"]]
  expect_equal(stored$pptestcd_cdisc$sparse$sparse, "SPARSEAL")
  expect_equal(stored$pptest_cdisc$sparse$dense, "AUC to Last")
  # auclast ships with one
  expect_equal(
    get.interval.cols()[["auclast"]]$pptestcd_cdisc,
    list(sparse = list(dense = "AUCLST", sparse = "SPARSEAL"))
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

  # invalid sparse mappings: unlike routes, both keys must be given
  for (bad in list(list(sparse = "SPARSEAL"),
                   list(sparse = list(sparse = "SPARSEAL")),
                   list(sparse = list(dense = "AUCLST", sparse = "SPARSEAL", other = "X")))) {
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
