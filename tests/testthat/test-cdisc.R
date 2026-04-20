test_that("add.interval.col stores pptestcd_cdisc and pptest_cdisc", {
  # Save and restore state
  original_state <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)
  on.exit(assign("interval.cols", original_state, envir=PKNCA:::.PKNCAEnv))

  add.interval.col(
    "test_cdisc_simple",
    FUN=NA,
    values=c(FALSE, TRUE),
    unit_type="conc",
    pretty_name="Test",
    desc="Test parameter",
    pptestcd_cdisc="TSTCD",
    pptest_cdisc="Test Name"
  )
  cols <- get.interval.cols()
  expect_equal(cols$test_cdisc_simple$pptestcd_cdisc, "TSTCD")
  expect_equal(cols$test_cdisc_simple$pptest_cdisc, "Test Name")
})

test_that("add.interval.col defaults pptestcd_cdisc to name and pptest_cdisc to desc", {
  original_state <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)
  on.exit(assign("interval.cols", original_state, envir=PKNCA:::.PKNCAEnv))

  add.interval.col(
    "test_cdisc_default",
    FUN=NA,
    values=c(FALSE, TRUE),
    unit_type="conc",
    pretty_name="Test",
    desc="A test description"
  )
  cols <- get.interval.cols()
  expect_equal(cols$test_cdisc_default$pptestcd_cdisc, "test_cdisc_default")
  expect_equal(cols$test_cdisc_default$pptest_cdisc, "A test description")
})

test_that("add.interval.col stores route-dependent CDISC mappings", {
  original_state <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)
  on.exit(assign("interval.cols", original_state, envir=PKNCA:::.PKNCAEnv))

  add.interval.col(
    "test_cdisc_route",
    FUN=NA,
    values=c(FALSE, TRUE),
    unit_type="clearance",
    pretty_name="Test CL",
    desc="Test clearance",
    pptestcd_cdisc=list(route=list(extravascular="CLF", intravascular="CL")),
    pptest_cdisc=list(route=list(extravascular="CL by F", intravascular="Total CL"))
  )
  cols <- get.interval.cols()
  expect_equal(cols$test_cdisc_route$pptestcd_cdisc$route$extravascular, "CLF")
  expect_equal(cols$test_cdisc_route$pptestcd_cdisc$route$intravascular, "CL")
})

test_that("add.interval.col validates pptestcd_cdisc and pptest_cdisc types", {
  original_state <- get("interval.cols", envir=PKNCA:::.PKNCAEnv)
  on.exit(assign("interval.cols", original_state, envir=PKNCA:::.PKNCAEnv))

  expect_error(
    add.interval.col(
      "test_bad_cdisc",
      FUN=NA,
      values=c(FALSE, TRUE),
      unit_type="conc",
      pretty_name="Test",
      desc="Test",
      pptestcd_cdisc=123
    ),
    regexp="pptestcd_cdisc must be a character string or a list"
  )
  expect_error(
    add.interval.col(
      "test_bad_cdisc2",
      FUN=NA,
      values=c(FALSE, TRUE),
      unit_type="conc",
      pretty_name="Test",
      desc="Test",
      pptest_cdisc=123
    ),
    regexp="pptest_cdisc must be a character string or a list"
  )
})

test_that("CDISC mappings are registered for standard parameters", {
  cols <- get.interval.cols()
  # Simple mapping
  expect_equal(cols$cmax$pptestcd_cdisc, "CMAX")
  expect_equal(cols$cmax$pptest_cdisc, "Max Conc")
  expect_equal(cols$auclast$pptestcd_cdisc, "AUCLST")
  expect_equal(cols$half.life$pptestcd_cdisc, "LAMZHL")
  # Route-dependent mapping
  expect_true(is.list(cols$cl.obs$pptestcd_cdisc))
  expect_equal(cols$cl.obs$pptestcd_cdisc$route$extravascular, "CLF/FO")
  expect_equal(cols$cl.obs$pptestcd_cdisc$route$intravascular, "CLO")
  expect_true(is.list(cols$mrt.obs$pptestcd_cdisc))
  expect_equal(cols$mrt.obs$pptestcd_cdisc$route$extravascular, "MRTEVFO")
  expect_equal(cols$mrt.obs$pptestcd_cdisc$route$intravascular, "MRTICFO")
})

test_that("resolve_cdisc_value works for simple and route-dependent values", {
  # Simple string
  expect_equal(PKNCA:::resolve_cdisc_value("CMAX", "extravascular"), "CMAX")
  # Route-dependent list
  route_list <- list(route=list(extravascular="CLF", intravascular="CL"))
  expect_equal(PKNCA:::resolve_cdisc_value(route_list, "extravascular"), "CLF")
  expect_equal(PKNCA:::resolve_cdisc_value(route_list, "intravascular"), "CL")
  # Unknown route defaults to first element
  expect_equal(PKNCA:::resolve_cdisc_value(route_list, "unknown"), "CLF")
})

test_that("as.data.frame.PKNCAresults with out_format='cdisc' translates PPTESTCD", {
  # Build a minimal PKNCAresults object
  d_conc <- data.frame(
    subject=rep(1, 4),
    time=0:3,
    conc=c(0, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  d_dose <- data.frame(subject=1, time=0, dose=10)
  o_dose <- PKNCAdose(d_dose, dose~time|subject)
  o_data <- PKNCAdata(o_conc, o_dose, intervals=data.frame(
    start=0, end=3, cmax=TRUE, auclast=TRUE, tmax=TRUE
  ))
  suppressMessages(o_nca <- pk.nca(o_data))

  result_cdisc <- as.data.frame(o_nca, out_format="cdisc")
  # Check that PPTESTCD was translated
  expect_true("PPTEST" %in% names(result_cdisc))
  expect_true("CMAX" %in% result_cdisc$PPTESTCD)
  expect_true("AUCLST" %in% result_cdisc$PPTESTCD)
  expect_true("TMAX" %in% result_cdisc$PPTESTCD)
  # Check PPTEST values
  cmax_row <- result_cdisc[result_cdisc$PPTESTCD == "CMAX", ]
  expect_equal(cmax_row$PPTEST, "Max Conc")
})

test_that("as.data.frame.PKNCAresults with out_format='cdisc' handles route-dependent params", {
  # Extravascular route
  d_conc <- data.frame(
    subject=rep(1, 5),
    time=0:4,
    conc=c(0, 2, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  d_dose <- data.frame(subject=1, time=0, dose=10)
  o_dose <- PKNCAdose(d_dose, dose~time|subject, route="extravascular")
  o_data <- PKNCAdata(o_conc, o_dose, intervals=data.frame(
    start=0, end=Inf, cl.obs=TRUE, aucinf.obs=TRUE, half.life=TRUE
  ))
  suppressMessages(suppressWarnings(o_nca <- pk.nca(o_data)))

  result_ev <- as.data.frame(o_nca, out_format="cdisc")
  cl_rows <- result_ev[result_ev$PPTESTCD %in% c("CLF/FO", "CLO"), ]
  # Extravascular should use CLF/FO
  expect_true("CLF/FO" %in% result_ev$PPTESTCD)
  expect_false("CLO" %in% result_ev$PPTESTCD)

  # Intravascular route
  o_dose_iv <- PKNCAdose(d_dose, dose~time|subject, route="intravascular")
  o_data_iv <- PKNCAdata(o_conc, o_dose_iv, intervals=data.frame(
    start=0, end=Inf, cl.obs=TRUE, aucinf.obs=TRUE, half.life=TRUE
  ))
  suppressMessages(suppressWarnings(o_nca_iv <- pk.nca(o_data_iv)))

  result_iv <- as.data.frame(o_nca_iv, out_format="cdisc")
  # Intravascular should use CLO
  expect_true("CLO" %in% result_iv$PPTESTCD)
  expect_false("CLF/FO" %in% result_iv$PPTESTCD)
})

test_that("as.data.frame.PKNCAresults with out_format='cdisc' defaults to extravascular when no route", {
  d_conc <- data.frame(
    subject=rep(1, 5),
    time=0:4,
    conc=c(0, 2, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  d_dose <- data.frame(subject=1, time=0, dose=10)
  # Default route (extravascular)
  suppressMessages(o_dose <- PKNCAdose(d_dose, dose~time|subject))
  o_data <- PKNCAdata(o_conc, o_dose, intervals=data.frame(
    start=0, end=Inf, cl.obs=TRUE, aucinf.obs=TRUE, half.life=TRUE
  ))
  suppressMessages(suppressWarnings(o_nca <- pk.nca(o_data)))

  result <- as.data.frame(o_nca, out_format="cdisc")
  # Default route is extravascular, so CL should be CLF/FO
  expect_true("CLF/FO" %in% result$PPTESTCD)
})

test_that("PPTEST column is placed after PPTESTCD", {
  d_conc <- data.frame(
    subject=rep(1, 4),
    time=0:3,
    conc=c(0, 1, 0.5, 0.25)
  )
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  d_dose <- data.frame(subject=1, time=0, dose=10)
  o_dose <- PKNCAdose(d_dose, dose~time|subject)
  o_data <- PKNCAdata(o_conc, o_dose, intervals=data.frame(
    start=0, end=3, cmax=TRUE
  ))
  suppressMessages(o_nca <- pk.nca(o_data))

  result <- as.data.frame(o_nca, out_format="cdisc")
  pptestcd_pos <- which(names(result) == "PPTESTCD")
  pptest_pos <- which(names(result) == "PPTEST")
  expect_equal(pptest_pos, pptestcd_pos + 1)
})
