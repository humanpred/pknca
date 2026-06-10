# Save the original state
original_state <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)

test_that("add.interval.col", {
  # Invalid inputs fail

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
      datatype="interval"
    ),
    info="interval column assignment works with FUN=NA"
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
      datatype="interval"
    ),
    info="interval column assignment works with FUN=a character string"
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
      datatype="interval"
    ),
    info="interval column assignment works with FUN=NA"
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
    sort.interval.cols(),
    regexp="Invalid dependencies for interval column \\(please report this as a bug\\): fake_parameter The following dependencies are missing: does_not_exist"
  )
})

# Reset the original state
assign("interval.cols", original_state, envir=PKNCA:::.PKNCAEnv)
