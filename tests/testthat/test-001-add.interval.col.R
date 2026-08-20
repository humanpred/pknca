# Save the original state
original_state <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)

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
  expect_no_error(
    add.interval.col(
      name="a", FUN=NA, unit_type="conc", pretty_name="a", datatype="interval", desc = paste(rep("a", 40), collapse = "") )
  )
  
  # ---- Invalid boundary: 41 characters ----
  expect_error(
    add.interval.col(name="a", FUN=NA, unit_type="conc", pretty_name="a", datatype="interval", desc = paste(rep("a", 41), collapse = "") )
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
      values=c(FALSE, TRUE),
      unit_type="conc",
      pretty_name="a",
      desc="test addition",
      sparse=FALSE,
      formalsmap=list(),
      depends=NULL,
      datatype="interval",
      pptestcd_cdisc="a",
      pptest_cdisc="test addition"
    )
  )
  expect_equal(
    {
      add.interval.col(name="a", FUN="mean", unit_type="conc", pretty_name="a", datatype="interval", desc="test addition")
      get("interval.cols", PKNCA:::.PKNCAEnv)[["a"]]
    },
    list(
      FUN="mean",
      values=c(FALSE, TRUE),
      unit_type="conc",
      pretty_name="a",
      desc="test addition",
      sparse=FALSE,
      formalsmap=list(),
      depends=NULL,
      datatype="interval",
      pptestcd_cdisc="a",
      pptest_cdisc="test addition"
    )
  )
  expect_equal(
    {
      add.interval.col(name="a", FUN="mean", unit_type="conc", pretty_name="a", formalsmap=list(x="values"), desc="test addition")
      get("interval.cols", PKNCA:::.PKNCAEnv)[["a"]]
    },
    list(
      FUN="mean",
      values=c(FALSE, TRUE),
      unit_type="conc",
      pretty_name="a",
      desc="test addition",
      sparse=FALSE,
      formalsmap=list(x="values"),
      depends=NULL,
      datatype="interval",
      pptestcd_cdisc="a",
      pptest_cdisc="test addition"
    )
  )
})

# Reset the original state
assign("interval.cols", original_state, envir=PKNCA:::.PKNCAEnv)

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

# Reset the original state
assign("interval.cols", original_state, envir=PKNCA:::.PKNCAEnv)
