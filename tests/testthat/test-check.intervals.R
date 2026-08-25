test_that("check.interval.specification", {

  # Get the current name order of the expected results
  nameorder <- names(check.interval.specification(data.frame(start=0, end=1, cmax=TRUE)))

  d1 <- data.frame(start=0, end=1)
  r1 <- data.frame(start=0, end=1)
  r1[,setdiff(nameorder, names(r1))] <- FALSE
  expect_warning(expect_warning(
    check.interval.specification(as.matrix(d1)),
    regexp="Interval specification must be a data.frame",
    info="Interval must be a data.frame or coercable into a data frame"),
    regexp="Nothing to be calculated in interval specification number\\(s\\): 1"
  )
  expect_warning(
    d1.check <- check.interval.specification(d1),
    regexp="Nothing to be calculated in interval specification number\\(s\\): 1",
    info="Warn if nothing is to be calculated in an interval specification"
  )
  expect_equal(
    d1.check, r1[,nameorder],
    info="Expand a minimal data frame for interval specification"
  )

  # Giving one parameter will fill in everything else as false
  d2 <- data.frame(start=0, end=1, auclast=TRUE)
  r2 <- data.frame(start=0, end=1, auclast=TRUE)
  r2[,setdiff(nameorder, names(r2))] <- FALSE
  expect_equal(
    check.interval.specification(d2),
    r2[,nameorder],
    info="Expand a data frame interval specification with only one request given"
  )

  # start and end must both be specified
  d3 <- data.frame(start=0)
  expect_error(
    check.interval.specification(d3),
    regexp="Column\\(s\\) 'end' missing from interval specification",
    info="Confirm end column is in interval specification"
  )
  d4 <- data.frame(end=1)
  expect_error(
    check.interval.specification(d4),
    regexp="Column\\(s\\) 'start' missing from interval specification",
    info="Confirm start column is in interval specification"
  )
  d5 <- data.frame(blah=5)
  expect_error(
    check.interval.specification(d5),
    regexp="Column\\(s\\) 'start', 'end' missing from interval specification",
    info="Confirm start and end columns are in interval specification"
  )

  # Ensure that there are data
  d6 <- data.frame()
  expect_error(
    check.interval.specification(d6),
    regexp="interval specification has no rows",
    info="It is an error to have an interval specification with no rows"
  )

  # Confirm specific column values required
  d7 <- data.frame(start=NA_real_, end=1)
  expect_error(
    check.interval.specification(d7),
    regexp="Interval specification may not have NA for the starting time",
    info="Interval specification may not have NA for the starting time"
  )
  d8 <- data.frame(start=0, end = NA_real_)
  expect_error(
    check.interval.specification(d8),
    regexp="Interval specification may not have NA for the end time",
    info="Interval specification may not have NA for the end time"
  )
  d9 <- data.frame(start=1, end=1)
  expect_error(
    check.interval.specification(d9),
    regexp="start must be < end",
    info="In interval specification, start must be < end (they are equal)."
  )
  d10 <- data.frame(start=1, end=0)
  expect_error(
    check.interval.specification(d10),
    regexp="start must be < end",
    info="In interval specification, start must be < end (end is less)."
  )
  d11 <- data.frame(start=Inf, end=1)
  expect_error(
    check.interval.specification(d11),
    regexp="start may not be infinite",
    info="In interval specification, start may not be infinite (positive infinity)."
  )

  d12 <- data.frame(start=-Inf, end=1)
  expect_error(
    check.interval.specification(d12),
    regexp="start may not be infinite",
    info="In interval specification, start may not be infinite (negative infinity)."
  )

  # But it is OK to have an infinite end
  d13 <- data.frame(start=0, end=Inf)
  r13 <- data.frame(start=0, end=Inf)
  r13[,setdiff(nameorder, names(r13))] <- FALSE
  expect_warning(d13.check <- check.interval.specification(d13))
  expect_equal(
    d13.check, r13[,nameorder],
    info="In interval specification, end may be infinite (positive infinity)."
  )
  expect_error(
    check.interval.specification(data.frame(start=0, end=-Inf)),
    info="In interval specification, end may not be negative infinity (start is 0)."
  )
  expect_error(
    check.interval.specification(data.frame(start=-Inf, end=-Inf)),
    info="In interval specification, end may not be negative infinity (start is -Inf)."
  )

  # When the no-calculation interval specification is not the first,
  # ensure that is warned correctly
  d14 <- data.frame(start=0, end=24, auclast=c(rep(FALSE, 3), TRUE))
  expect_warning(
    check.interval.specification(d14),
    regexp="Nothing to be calculated in interval specification number\\(s\\): 1, 2, 3",
    info="Warn when nothing is to be calculated in all rows of the specification."
  )

  d14 <- data.frame(start=0, end=24, auclast=c(rep(TRUE, 3), FALSE))
  expect_warning(
    check.interval.specification(d14),
    regexp="Nothing to be calculated in interval specification number\\(s\\): 4",
    info="Warn when nothing is to be calculated in one but not all rows of the specification."
  )

  # Other information is passed through untouched after all the
  # calculation columns
  d15 <- data.frame(start=0, end=Inf, treatment="foo")
  r15 <- data.frame(start=0, end=Inf, treatment="foo")
  r15[,setdiff(nameorder, names(r15))] <- FALSE
  expect_warning(v15 <- check.interval.specification(d15))
  expect_equal(
    v15, r15[,c(nameorder, "treatment")],
    info="Extra information is maintained in the interval specification."
  )

  d16 <- data.frame(start=factor(0), end=1)
  expect_error(
    check.interval.specification(d16),
    regexp="Interval column 'start' should not be a factor",
    info="Start must be numeric and not a factor."
  )

  d17 <- data.frame(start=0, end=factor(1))
  expect_error(
    check.interval.specification(d17),
    regexp="Interval column 'end' should not be a factor",
    info="End must be numeric and not a factor."
  )
})

test_that("get.parameter.deps", {
  expect_error(
    get.parameter.deps("foo"),
    regexp="`x` must be the name of an NCA parameter listed by the function `get.interval.cols()`",
    info="The argument must be a parameter.",
    fixed=TRUE
  )
  expect_equal(
    get.parameter.deps("kel.obs"),
    "kel.obs",
    info="Parameters that have nothing that depend on them return themselves only."
  )
  expect_equal(
    get.parameter.deps("ctrough"),
    c("aucabove.trough.all", "ctrough", "ctrough.dn", "ptr"),
    info="Parameters with formalsmap-related dependencies return themselves and the formalsmap-related dependencies."
  )
  expect_equal(
    get.parameter.deps("start"),
    character(0),
    info="Special columns that are not actually parameters have no dependencies (including themselves)."
  )
  expect_equal(
    get.parameter.deps("cl.obs"),
    c("cl.obs", "vss.iv.obs", "vss.obs", "vz.obs"),
    info="Parameters with dependencies return them."
  )
})

test_that("check.intervals requires a valid value", {
  expect_error(
    check.interval.specification(data.frame(start=0, end=1, cmax="A")),
    regexp="Invalid value(s) in column cmax:A",
    fixed=TRUE
  )
})

test_that("check.intervals works with tibble input (fix #141)", {
  d_dat <-
    data.frame(
      conc = c(
        0.5, 2, 5, 9.2, 12, 2, 1.85, 1.08, 0.5, 0.3, 2.4, 4.5, 10.2, 15, 2.6, 1.65, 1.1,
        0.5, 2, 5, 9.2, 12, 2, 1.85, 1.08, NA, 0.3, 2.4, 4.5, 10.2, 15, 2.6, 1.65, 1.1
      ),
      time = c(seq(264.2, 312.2, 3), seq(264, 312, 3)),
      ARM = rep(c(rep(1, 8), rep(2, 9)), 2),
      SUBJ = c(rep(1, 17), rep(2, 17)),
      Dose = c(rep(5, 17)), rep(5, 17)
    )

  intervals_manual_first <-
    d_dat %>%
    dplyr::group_by(SUBJ) %>%
    dplyr::summarize(
      start=time[dplyr::between(time, 264, 265)],
      end=time[dplyr::between(time, 288, 289)]
    )
  intervals_manual_second <-
    d_dat %>%
    dplyr::group_by(SUBJ) %>%
    dplyr::summarize(
      start=time[dplyr::between(time, 288, 289)],
      end=time[dplyr::between(time, 312, 313)]
    )
  intervals_manual <-
    dplyr::bind_rows(
      intervals_manual_first,
      intervals_manual_second
    ) %>%
    dplyr::mutate(
      auclast=TRUE,
      aucall=TRUE,
      tlast=TRUE
    )
  # There is some other issue here where intervals are having an issue being a tibble
  expect_equal(
    check.interval.specification(intervals_manual)$start,
    intervals_manual$start
  )
})

test_that("get.parameter.deps(recursive=TRUE) reaches the inputs a parameter is calculated from (#538)", {
  # cmax is calculated from the concentrations alone; tmax also needs the times
  expect_true("conc" %in% get.parameter.deps("cmax", recursive = TRUE))
  expect_false("time" %in% get.parameter.deps("cmax", recursive = TRUE))
  expect_true(all(c("conc", "time") %in% get.parameter.deps("tmax", recursive = TRUE)))
  # cl.obs needs the dose amount; vz.obs needs it only through cl.obs
  expect_true("dose" %in% get.parameter.deps("cl.obs", recursive = TRUE))
  expect_true("dose" %in% get.parameter.deps("vz.obs", recursive = TRUE))
  # The default direction is unchanged: parameters calculated from cmax
  expect_true("cmax.dn" %in% get.parameter.deps("cmax"))
  expect_false("cmax.dn" %in% get.parameter.deps("cmax", recursive = TRUE))
  expect_error(
    get.parameter.deps("not a parameter", recursive = TRUE),
    class = "pknca_error_invalid_parameter"
  )
})

test_that("dose amount, time, and duration are required separately (#538)", {
  expect_equal(
    unlist(set_requires_inputs("c0")[["c0"]][c("requires_dose_amt", "requires_dose_time", "requires_dose_dur")]),
    c(requires_dose_amt = FALSE, requires_dose_time = TRUE, requires_dose_dur = FALSE)
  )
  expect_equal(
    unlist(set_requires_inputs("ceoi")[["ceoi"]][c("requires_dose_amt", "requires_dose_time", "requires_dose_dur")]),
    c(requires_dose_amt = FALSE, requires_dose_time = FALSE, requires_dose_dur = TRUE)
  )
  expect_true(set_requires_inputs("cl.obs")[["cl.obs"]]$requires_dose_amt)
  # pk.calc.half.life() uses the dose timing when present but does not need
  # it, so neither it nor anything downstream of it is reported
  for (param in c("half.life", "lambda.z", "aucinf.obs", "mrt.obs", "span.ratio")) {
    expect_false(any(unlist(set_requires_inputs(param)[[param]][
      c("requires_dose_amt", "requires_dose_time", "requires_dose_dur")
    ])), info = param)
  }
})

test_that("every derived dose requirement matches what pk.nca() can calculate (#538)", {
  # Enumerating guard: a parameter whose flags are wrong, or a newly added
  # parameter, is caught here rather than producing a wrong message.
  d_conc <- data.frame(conc = c(2, 1, 0.5, 0.25, 0.125), time = 0:4, subject = 1)
  d_dose <- data.frame(dose = 100, time = 0, subject = 1)
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  o_dose <- PKNCAdose(d_dose, dose~time|subject)
  check_params <-
    c("cmax", "tmax", "auclast", "aucinf.obs", "half.life", "mrt.last", "cav",
      "cl.last", "cl.obs", "vz.obs", "vss.obs", "cmax.dn", "auclast.dn", "totdose")
  ivl <- data.frame(start = 0, end = Inf)
  for (param in check_params) ivl[[param]] <- TRUE
  res_with <-
    suppressWarnings(suppressMessages(
      as.data.frame(pk.nca(PKNCAdata(o_conc, o_dose, intervals = ivl)))
    ))
  res_without <-
    suppressWarnings(suppressMessages(
      as.data.frame(pk.nca(PKNCAdata(o_conc, intervals = ivl)))
    ))
  all_na <- function(d, param) {
    v <- d$PPORRES[d$PPTESTCD %in% param]
    length(v) == 0 || all(is.na(v))
  }
  for (param in check_params) {
    spec <- set_requires_inputs(param)[[param]]
    derived <- any(unlist(spec[c("requires_dose_amt", "requires_dose_time", "requires_dose_dur")]))
    observed <- !all_na(res_with, param) && all_na(res_without, param)
    expect_equal(derived, observed, info = param)
  }
})

test_that("the missing dose message names only what cannot be calculated (#538)", {
  d_conc <- data.frame(conc = c(2, 1, 0.5, 0.25, 0.125), time = 0:4, subject = 1)
  d_dose <- data.frame(dose = 100, time = 0, subject = 1)
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  mk <- function(params) {
    ivl <- data.frame(start = 0, end = Inf)
    for (param in params) ivl[[param]] <- TRUE
    ivl
  }
  # Nothing requested needs dosing, so nothing is reported
  expect_no_message(
    suppressWarnings(pk.nca(PKNCAdata(o_conc, intervals = mk(c("cmax", "auclast"))))),
    class = "pknca_message_missing_dose"
  )
  # Only the affected parameter is named
  expect_message(
    suppressWarnings(pk.nca(PKNCAdata(o_conc, intervals = mk(c("cmax", "cl.last"))))),
    regexp = "will not be calculated: cl.last",
    fixed = TRUE
  )
  # Dose timing without an amount covers c0 but not cl.last
  expect_message(
    suppressWarnings(pk.nca(PKNCAdata(
      o_conc, PKNCAdose(d_dose, ~time|subject), intervals = mk(c("c0", "cl.last"))
    ))),
    regexp = "will not be calculated: cl.last",
    fixed = TRUE
  )
  # A dose amount without timing covers cl.last but not c0
  expect_message(
    suppressWarnings(pk.nca(PKNCAdata(
      o_conc, PKNCAdose(d_dose, dose~.|subject), intervals = mk(c("c0", "cl.last"))
    ))),
    regexp = "will not be calculated: c0",
    fixed = TRUE
  )
})

test_that("volume is required only by the parameters that use it (#194)", {
  expect_true(set_requires_inputs("volpk")[["volpk"]]$requires_volume)
  expect_true(set_requires_inputs("ae")[["ae"]]$requires_volume)
  # clr.last and fe reach volume only through ae
  expect_true(set_requires_inputs("clr.last")[["clr.last"]]$requires_volume)
  expect_true(set_requires_inputs("fe")[["fe"]]$requires_volume)
  for (param in c("cmax", "tmax", "auclast", "half.life", "cl.obs", "totdose")) {
    expect_false(set_requires_inputs(param)[[param]]$requires_volume, info = param)
  }
})

test_that("the collection duration is required only by the parameters that use it (#166)", {
  for (param in c("ertlst", "ermax", "ertmax")) {
    expect_true(set_requires_inputs(param)[[param]]$requires_conc_dur, info = param)
  }
  # ae and volpk use the volume without needing the collection duration
  for (param in c("ae", "volpk", "cmax", "tmax", "auclast", "half.life", "cl.obs")) {
    expect_false(set_requires_inputs(param)[[param]]$requires_conc_dur, info = param)
  }
})

test_that("every parameter's cached concentration requirements match a fresh walk (#194, #166)", {
  # Enumerating guard on the caching in set_requires_inputs(): a newly added
  # parameter, or a flag left stale by re-registration, is caught here rather
  # than by a wrong error when the calculation is requested.  The dose inputs
  # are left out because pknca_optional_dose_args makes them deliberately
  # differ from a plain dependency walk.
  for (param in names(get.interval.cols())) {
    deps <- get.parameter.deps(param, recursive = TRUE)
    for (current_input in c("volume", "conc_dur")) {
      expect_equal(
        set_requires_inputs(param)[[param]][[paste0("requires_", current_input)]],
        any(pknca_requires_inputs[[current_input]] %in% deps),
        info = paste(param, current_input)
      )
    }
  }
})

test_that("absent_dose_inputs and absent_conc_inputs report what was not given (#194)", {
  d_conc <- data.frame(conc = c(2, 1, 0.5, 0.25, 0.125), time = 0:4, subject = 1)
  d_dose <- data.frame(dose = 100, time = 0, subject = 1)
  expect_equal(absent_dose_inputs(PKNCAdose(d_dose, dose~time|subject)), character(0))
  expect_equal(absent_dose_inputs(suppressMessages(PKNCAdose(d_dose, ~time|subject))), "dose_amt")
  expect_equal(absent_dose_inputs(suppressMessages(PKNCAdose(d_dose, dose~.|subject))), "dose_time")
  expect_equal(absent_dose_inputs(NA), c("dose_amt", "dose_time", "dose_dur"))
  expect_equal(absent_conc_inputs(PKNCAconc(d_conc, conc~time|subject)), c("volume", "conc_dur"))
  expect_equal(
    absent_conc_inputs(PKNCAconc(cbind(d_conc, vol = 10), conc~time|subject, volume = "vol")),
    "conc_dur"
  )
  expect_equal(
    absent_conc_inputs(PKNCAconc(
      cbind(d_conc, vol = 10, dur = 1), conc~time|subject, volume = "vol", duration = "dur"
    )),
    character(0)
  )
  # A volume that is missing for only some measurements is left to the
  # per-interval missing-data exclusions
  expect_equal(
    absent_conc_inputs(PKNCAconc(
      cbind(d_conc, vol = c(10, NA, 10, NA, 10), dur = 1),
      conc~time|subject, volume = "vol", duration = "dur"
    )),
    character(0)
  )
})

test_that("uncalculable_without selects on the inputs it is given (#194)", {
  ivl <- data.frame(start = 0, end = Inf, ae = TRUE, cmax = TRUE, c0 = TRUE, cl.obs = TRUE)
  expect_equal(uncalculable_without(ivl, "volume"), "ae")
  expect_equal(uncalculable_without(ivl, "conc_dur"), character(0))
  expect_equal(uncalculable_without(ivl, "dose_amt"), "cl.obs")
  expect_equal(uncalculable_without(ivl, "dose_time"), "c0")
  expect_equal(uncalculable_without(ivl, c("volume", "dose_amt")), c("ae", "cl.obs"))
  # Nothing absent, requested as FALSE, and nothing requested at all
  expect_equal(uncalculable_without(ivl, character(0)), character(0))
  expect_equal(
    uncalculable_without(data.frame(start = 0, end = Inf, ae = FALSE), "volume"),
    character(0)
  )
  expect_equal(uncalculable_without(data.frame(start = 0, end = Inf), "volume"), character(0))
  expect_error(uncalculable_without(ivl, "nope"), regexp = "Must be a subset of")
})

test_that("re-registering a parameter drops every cached requirement (#194)", {
  # A parameter registered later can change what an earlier one needs, so a
  # cached value left behind would be wrong with nothing else failing.
  original_state <- get("interval.cols", envir = .PKNCAEnv)
  on.exit(assign("interval.cols", original_state, envir = .PKNCAEnv))
  cached <- function(param) any(startsWith(names(get.interval.cols()[[param]]), "requires_"))
  expect_true(set_requires_inputs("ae")[["ae"]]$requires_volume)
  # A name that is not already registered is not a redefinition
  add.interval.col(name = "zz", FUN = "mean", unit_type = "conc", pretty_name = "zz")
  expect_true(cached("ae"))
  add.interval.col(name = "zz", FUN = "mean", unit_type = "conc", pretty_name = "zz")
  expect_false(cached("ae"))
  expect_true(set_requires_inputs("ae")[["ae"]]$requires_volume)
})
