# Restore the parameter registry after a test that registers something
restore_interval_cols <- function(env = parent.frame()) {
  saved <- get("interval.cols", envir = PKNCA:::.PKNCAEnv)
  withr::defer(
    {
      assign("interval.cols", saved, envir = PKNCA:::.PKNCAEnv)
      if (exists("parameter_classification", envir = PKNCA:::.PKNCAEnv)) {
        rm("parameter_classification", envir = PKNCA:::.PKNCAEnv)
      }
    },
    envir = env
  )
}

# Completeness ------------------------------------------------------------
#
# These are the gates:  a parameter added without a concept, or promoted into
# or out of the default report, fails here until the change is deliberate.

test_that("every PKNCA parameter resolves to a concept in the vocabulary", {
  expect_equal(
    pknca_check_parameter_classification()$parameter,
    character(0)
  )
})

test_that("every concept in the vocabulary is used by at least one parameter", {
  used <- unique(pknca_parameter_table()$concept)
  expect_equal(setdiff(pknca_concepts(), used), character(0))
})

test_that("no concept name collides with a parameter name", {
  # `include`/`exclude` accept either, so the two namespaces must not overlap
  expect_equal(
    intersect(pknca_concepts(), names(get.interval.cols())),
    character(0)
  )
})

test_that("the common tier is exactly the reviewed set", {
  # Changing this list changes what a default report contains, so it is
  # deliberate rather than incidental.
  tbl <- pknca_parameter_table()
  expect_equal(
    sort(tbl$parameter[tbl$tier == "common"]),
    sort(c(
      # Concentrations and times
      "cmax", "tmax", "ctrough", "tlag", "count_conc",
      # Exposure
      "auclast", "aucint.last", "aucinf.obs", "aucint.inf.obs", "aucpext.obs",
      # Terminal phase
      "half.life",
      # Disposition
      "cl.obs", "cl.int.inf.obs",
      # Intravenous
      "c0", "ceoi",
      # Excreta
      "ae", "fe", "clr.obs", "volpk",
      # Sparse
      "sparse_auclast", "sparse_auc_se"
    ))
  )
})

test_that("every parameter has a non-empty route and dosing within the vocabulary", {
  classification <- PKNCA:::parameter_classification()
  bad_route <-
    names(classification$route)[
      vapply(
        classification$route,
        function(x) length(x) == 0 || !all(x %in% pknca_routes()),
        TRUE
      )
    ]
  expect_equal(bad_route, character(0))
  bad_dosing <-
    names(classification$dosing)[
      vapply(
        classification$dosing,
        function(x) length(x) == 0 || !all(x %in% pknca_dosing()),
        TRUE
      )
    ]
  expect_equal(bad_dosing, character(0))
})

# Declared and derived must agree ----------------------------------------

test_that("sample_type is interval exactly when a volume is required", {
  tbl <- pknca_parameter_table()
  specs <- PKNCA:::set_requires_inputs(tbl$parameter)
  needs_volume <- vapply(specs, function(x) isTRUE(x$requires_volume), TRUE)
  expect_equal(
    sort(tbl$parameter[tbl$sample_type == "interval"]),
    sort(names(needs_volume)[needs_volume])
  )
})

test_that("nothing calculated from c0 is available extravascularly", {
  classification <- PKNCA:::parameter_classification()
  from_c0 <- intersect(get.parameter.deps("c0"), names(classification$route))
  extravascular <-
    from_c0[vapply(classification$route[from_c0], function(x) "extravascular" %in% x, TRUE)]
  expect_equal(extravascular, character(0))
})

test_that("anything needing a dose duration is intravenous", {
  classification <- PKNCA:::parameter_classification()
  specs <- PKNCA:::set_requires_inputs(names(classification$route))
  needs_duration <-
    names(specs)[vapply(specs, function(x) isTRUE(x$requires_dose_dur), TRUE)]
  extravascular <-
    needs_duration[
      vapply(classification$route[needs_duration], function(x) "extravascular" %in% x, TRUE)
    ]
  expect_equal(extravascular, character(0))
})

test_that("the multiple-dose family is the closure of the declared seeds", {
  tbl <- pknca_parameter_table()
  expect_equal(
    sort(tbl$parameter[tbl$dosing == "multiple,steady_state"]),
    sort(c(
      "ctrough", "ctrough.dn", "ptr", "deg.fluc", "swing",
      "aucabove.trough.all",
      "mrt.md.obs", "mrt.md.pred", "vss.md.obs", "vss.md.pred"
    ))
  )
})

test_that("dose_normalized marks exactly the pk.calc.dn parameters", {
  tbl <- pknca_parameter_table()
  all_intervals <- get.interval.cols()
  from_dn <-
    names(all_intervals)[
      vapply(all_intervals, function(x) identical(x$FUN, "pk.calc.dn"), TRUE)
    ]
  expect_equal(sort(tbl$parameter[tbl$dose_normalized]), sort(from_dn))
})

test_that("a dose-normalized parameter takes the concept of its base parameter", {
  expect_equal(
    pknca_parameter_table("auclast.dn")$concept,
    pknca_parameter_table("auclast")$concept
  )
  expect_equal(
    pknca_parameter_table("cmax.dn")$concept,
    pknca_parameter_table("cmax")$concept
  )
})

test_that("clast.pred is a concentration, not a half-life diagnostic", {
  # It is returned by pk.calc.half.life(), so it would otherwise inherit the
  # half-life concept from `depends`
  expect_equal(pknca_parameter_table("clast.pred")$concept, "last_conc")
  expect_equal(pknca_parameter_table("lambda.z")$concept, "half_life")
})

test_that("ceoi is infusion-only and c0 is not infusion-only", {
  expect_equal(pknca_parameter_table("ceoi")$route, "iv_infusion")
  expect_equal(pknca_parameter_table("c0")$route, "iv_bolus,iv_infusion")
})

test_that("tlag is extravascular", {
  # tlag is measured from spot samples.  The equivalent for an interval
  # collection is a different calculation that PKNCA does not have.
  expect_equal(pknca_parameter_table("tlag")$route, "extravascular")
  expect_equal(pknca_parameter_table("tlag")$sample_type, "spot")
})

# pknca_concept() ---------------------------------------------------------

test_that("pknca_concept() reads the attribute from the calculation function", {
  expect_equal(pknca_concept(pk.calc.cmax), "peak_conc")
  expect_equal(pknca_concept(pk.calc.cl), "clearance")
})

test_that("a function with no concept gives NULL", {
  # pk.calc.dn() computes whatever its base parameter is, so it has none
  expect_null(pknca_concept(pk.calc.dn))
})

test_that("the replacement form sets the attribute and validates", {
  f <- function(conc) max(conc)
  pknca_concept(f) <- "peak_conc"
  expect_equal(pknca_concept(f), "peak_conc")
  expect_error(pknca_concept(f) <- 1)
  expect_error(pknca_concept(f) <- c("a", "b"))
  expect_error(pknca_concept(f) <- NA_character_)
})

# add.interval.col() validation ------------------------------------------

test_that("tier must be one of the tiers", {
  restore_interval_cols()
  expect_error(
    add.interval.col(
      "test_tier", FUN = "pk.calc.cmax", unit_type = "conc",
      pretty_name = "Test", tier = "sometimes"
    )
  )
})

test_that("selection must be a named list of known elements", {
  restore_interval_cols()
  expect_error(
    add.interval.col(
      "test_sel", FUN = "pk.calc.cmax", unit_type = "conc",
      pretty_name = "Test", selection = "peak_conc"
    ),
    class = "pknca_error_selection_not_list"
  )
  expect_error(
    add.interval.col(
      "test_sel", FUN = "pk.calc.cmax", unit_type = "conc",
      pretty_name = "Test", selection = list(nonexistent = "x")
    ),
    class = "pknca_error_selection_unknown_element"
  )
  expect_error(
    add.interval.col(
      "test_sel", FUN = "pk.calc.cmax", unit_type = "conc",
      pretty_name = "Test", selection = list(route = "oral")
    )
  )
  expect_error(
    add.interval.col(
      "test_sel", FUN = "pk.calc.cmax", unit_type = "conc",
      pretty_name = "Test", selection = list(dosing = "sometimes")
    )
  )
})

# Third-party parameters --------------------------------------------------

test_that("a parameter with no concept registers and calculates, but is not classified", {
  restore_interval_cols()
  other_package_fun <- function(conc) max(conc)
  assign("other_package_fun", other_package_fun, envir = globalenv())
  withr::defer(rm("other_package_fun", envir = globalenv()))

  expect_no_error(
    add.interval.col(
      "other_package_param", FUN = "other_package_fun", unit_type = "conc",
      pretty_name = "Other package parameter"
    )
  )
  tbl <- pknca_parameter_table("other_package_param")
  expect_true(is.na(tbl$concept))
  expect_equal(tbl$tier, "uncommon")
  expect_equal(
    pknca_check_parameter_classification()$parameter,
    "other_package_param"
  )
})

test_that("a third-party parameter can declare its concept on its function", {
  restore_interval_cols()
  other_package_fun2 <- function(conc) max(conc)
  pknca_concept(other_package_fun2) <- "peak_conc"
  assign("other_package_fun2", other_package_fun2, envir = globalenv())
  withr::defer(rm("other_package_fun2", envir = globalenv()))

  add.interval.col(
    "other_package_param2", FUN = "other_package_fun2", unit_type = "conc",
    pretty_name = "Other package parameter"
  )
  expect_equal(pknca_parameter_table("other_package_param2")$concept, "peak_conc")
  expect_equal(pknca_check_parameter_classification()$parameter, character(0))
})

test_that("registering a parameter invalidates the cached classification", {
  restore_interval_cols()
  before <- nrow(pknca_parameter_table())
  other_package_fun3 <- function(conc) max(conc)
  assign("other_package_fun3", other_package_fun3, envir = globalenv())
  withr::defer(rm("other_package_fun3", envir = globalenv()))
  add.interval.col(
    "other_package_param3", FUN = "other_package_fun3", unit_type = "conc",
    pretty_name = "Other package parameter"
  )
  expect_equal(nrow(pknca_parameter_table()), before + 1)
})

# pknca_parameter_table() -------------------------------------------------

test_that("pknca_parameter_table() describes the requested parameters", {
  ret <- pknca_parameter_table(c("cmax", "cl.obs"))
  expect_equal(ret$parameter, c("cmax", "cl.obs"))
  expect_equal(ret$concept, c("peak_conc", "clearance"))
  expect_equal(
    names(ret),
    c(
      "parameter", "concept", "tier", "sample_type", "sparse",
      "dose_normalized", "route", "dosing"
    )
  )
})

test_that("pknca_parameter_table() errors for a name that is not a parameter", {
  expect_error(
    pknca_parameter_table("nonexistent"),
    class = "pknca_error_invalid_param_name"
  )
})
