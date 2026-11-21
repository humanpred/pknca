test_that("all units have been defined", {
  all_units <- pknca_units_table(concu="conc", doseu="dose", amountu="amount", timeu="time")
  expect_equal(
    setdiff(names(get.interval.cols()), c(all_units$PPTESTCD, "start", "end")),
    character()
  )
})

test_that("pknca_find_units_param expected errors", {
  expect_error(
    pknca_find_units_param(unit_type=1:2)
  )
  expect_error(
    pknca_find_units_param(unit_type=1)
  )
  expect_error(
    pknca_find_units_param(unit_type="foo"),
    regexp="No parameters found for unit_type"
  )
})

test_that("pknca_find_units_param", {
  expect_true(
    "cmax" %in% pknca_find_units_param(unit_type="conc")
  )
})

test_that("unit conversion tables are created correctly", {
  skip_if_not_installed("units")
  expect_true(
    all(
      pknca_units_table(
        concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr"
      )$conversion_factor == 1
    )
  )
  automatic_conversion <-
    pknca_units_table(
      concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr",
      conversions=data.frame(
        PPORRESU=c("(mg/kg)/(hr*ng/mL)", "(mg/kg)/(ng/mL)"),
        PPSTRESU=c("mL/hr/kg", "mL/kg")
      )
    )
  expect_equal(
    unique(automatic_conversion$conversion_factor[automatic_conversion$PPSTRESU %in% "mL/hr/kg"]),
    1e6,
    tolerance=.Machine$double.eps
  )
  expect_equal(
    unique(automatic_conversion$conversion_factor[automatic_conversion$PPSTRESU %in% "mL/kg"]),
    1e6,
    tolerance=.Machine$double.eps
  )
  expect_equal(
    unique(automatic_conversion$conversion_factor[!(automatic_conversion$PPSTRESU %in% c("mL/hr/kg", "mL/kg"))]),
    1
  )

  mixed_conversion <-
    pknca_units_table(
      concu="mg/L", doseu="mg/kg", amountu="mg", timeu="hr",
      # Convert clearance and volume units to molar units (assuming
      conversions=data.frame(
        PPORRESU=c("mg/L", "(mg/kg)/(hr*mg/L)", "(mg/kg)/(mg/L)"),
        PPSTRESU=c("mmol/L", "mL/hr/kg", "mL/kg"),
        # Manual conversion of concentration units from ng/mL to mmol/L (assuming
        # a molecular weight of 138.121 g/mol)
        conversion_factor=c(1/138.121, NA, NA)
      )
    )
  expect_equal(
    unique(mixed_conversion$conversion_factor[mixed_conversion$PPSTRESU %in% "mL/hr/kg"]),
    1000,
    tolerance=1e-10
  )
  expect_equal(
    unique(mixed_conversion$conversion_factor[mixed_conversion$PPSTRESU %in% "mL/kg"]),
    1000,
    tolerance=1e-10
  )
  expect_equal(
    unique(mixed_conversion$conversion_factor[mixed_conversion$PPSTRESU %in% "mmol/L"]),
    1/138.121,
    tolerance=1e-10
  )
  expect_equal(
    unique(mixed_conversion$conversion_factor[!(mixed_conversion$PPSTRESU %in% c("mL/hr/kg", "mL/kg", "mmol/L"))]),
    1
  )
})

test_that("pknca_units_table", {
  skip_if_not_installed("units")
  expect_warning(
      pknca_units_table(
        concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr",
        conversions=data.frame(PPORRESU="foo", PPSTRESU="bar", conversion_factor=1)
      ),
      regexp="The following unit conversions were supplied but do not match any units to convert"
  )
  # units library errors occur, if units are not convertible
  expect_error(
    pknca_units_table(
      concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr",
      conversions=data.frame(PPORRESU="ng/mL", PPSTRESU="mol/L")
    ),
    regexp="cannot convert ng/mL into mol/L"
  )
  expect_error(
    pknca_units_table(
      concu=c("ng/mL", "umol/L"), doseu="mg/kg", amountu="mg", timeu="hr",
      conversions=data.frame(PPORRESU="ng/mL", PPSTRESU="mol/L")
    ),
    regexp = "Only one unit may be provided at a time: ng/mL, umol/L"
  )
  # fraction excreted now has units of amount/dose
  unit_fe_kg <-
    pknca_units_table(
      doseu="mg/kg", amountu="ng",
      conversions=data.frame(PPORRESU="ng/(mg/kg)", PPSTRESU="kg")
    )
  expect_equal(
    unit_fe_kg$conversion_factor[unit_fe_kg$PPTESTCD == "fe"],
    1e-6
  )
  unit_fe_fraction <-
    pknca_units_table(
      doseu="mg", amountu="ng",
      conversions=data.frame(PPORRESU="ng/mg", PPSTRESU="fraction")
    )
  expect_equal(
    unit_fe_fraction$conversion_factor[unit_fe_fraction$PPTESTCD == "fe"],
    1e-6
  )
})

test_that("pknca_units_add_paren", {
  expect_equal(pknca_units_add_paren("mg"), "mg")
  expect_equal(pknca_units_add_paren("mg/kg"), "(mg/kg)")
  expect_equal(pknca_units_add_paren("mg*kg"), "(mg*kg)")
})

test_that("pknca_units_quotient divides one unit by another", {
  expect_equal(pknca_units_quotient("mg", "hr*ng/mL"), "mg/(hr*ng/mL)")
  expect_equal(pknca_units_quotient("ng/mL", "mg/L"), "(ng/mL)/(mg/L)")
  # Units that are not known compose into units that are not known
  expect_equal(pknca_units_quotient(NA_character_, "mg"), NA_character_)
  expect_equal(pknca_units_quotient("mg", NA_character_), NA_character_)
})

test_that("pknca_units_table treats missing, NULL, and NA the same", {
  expect_equal(
    pknca_units_table(),
    pknca_units_table(concu = NULL, doseu = NULL, amountu = NULL, timeu = NULL)
  )
  expect_equal(
    pknca_units_table(),
    pknca_units_table(concu = NA, doseu = NULL, amountu = NULL, timeu = NULL)
  )
  expect_equal(
    pknca_units_table(),
    pknca_units_table(concu = NA, doseu = NA, amountu = NULL, timeu = NULL)
  )
  expect_equal(
    pknca_units_table(),
    pknca_units_table(concu = NA, doseu = NA, amountu = NA, timeu = NULL)
  )
  expect_equal(
    pknca_units_table(),
    pknca_units_table(concu = NA, doseu = NULL, amountu = NULL, timeu = NA)
  )
  expect_true(all(is.na(
    pknca_units_table(concu = "ng/mL", doseu = "mg", amountu = "umol", timeu = NULL) %>%
      dplyr::filter(PPTESTCD %in% c("start", "lambda.z", "auclast", "aumclast", "auclast.dn", "aumclast.dn", "cl.last", "clr.last")) %>%
      dplyr::pull("PPORRESU")
  )))
  expect_true(all(is.na(
    pknca_units_table(concu = "ng/mL", doseu = "mg", amountu = NULL, timeu = "hr") %>%
      dplyr::filter(PPTESTCD %in% c("ae", "clr.last")) %>%
      dplyr::pull("PPORRESU")
  )))
  expect_true(all(is.na(
    pknca_units_table(concu = "ng/mL", doseu = NULL, amountu = "umol", timeu = "hr") %>%
      dplyr::filter(PPTESTCD %in% c("cmax.dn", "vss.last", "cl.last", "auclast.dn", "aumclast.dn")) %>%
      dplyr::pull("PPORRESU")
  )))
  expect_true(all(is.na(
    pknca_units_table(concu = NULL, doseu = "mg", amountu = "umol", timeu = "hr") %>%
      dplyr::filter(PPTESTCD %in% c("cmax", "cmax.dn", "vss.last", "auclast", "aumclast", "auclast.dn", "aumclast.dn", "cl.last", "clr.last")) %>%
      dplyr::pull("PPORRESU")
  )))
})

test_that("allow duplicate PPSTRESU units", {
  skip_if_not_installed("units")
  d_conversion <-
    data.frame(
      PPORRESU = c("ng/mL", "(ng/mL)/(mg/kg)", "(mg/kg)/(hr*ng/mL)", "(mg/kg)/(ng/mL)"),
      PPSTRESU = c("mg/mL", "mL/kg", "mL/(h*kg)", "mL/kg")
    )
  # No error for consistent volume conversion
  expect_silent(
    pknca_units_table(concu = "ng/mL", doseu = "mg/kg", timeu = "hr", conversions = d_conversion)
  )
})

test_that("Use preferred units (#197)", {
  skip_if_not_installed("units")
  prep <-
    pknca_units_table(
      concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
      concu_pref = "ug/mL"
    )
  expect_equal(prep$conversion_factor[prep$PPTESTCD == "cmax"], 0.001)
  prep <-
    pknca_units_table(
      concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
      doseu_pref = "ug/kg"
    )
  expect_equal(prep$conversion_factor[prep$PPTESTCD == "cmax.dn"], 0.001)
  prep <-
    pknca_units_table(
      concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
      timeu_pref = "day"
    )
  expect_equal(prep$conversion_factor[prep$PPTESTCD == "tmax"], 1/24)
  prep <-
    pknca_units_table(
      concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
      amountu_pref = "kg"
    )
  expect_equal(prep$conversion_factor[prep$PPTESTCD == "clr.inf.obs"], 1e-6)

  # conversions can override the preferred units parameter
  prep <-
    pknca_units_table(
      concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
      timeu_pref = "day",
      conversions = data.frame(PPORRESU = "hr^2*ng/mL", PPSTRESU = "min^2*ng/mL")
    )
  prep_no_conversions <-
    pknca_units_table(
      concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
      timeu_pref = "day"
    )
  expect_equal(prep$conversion_factor[prep$PPTESTCD == "tmax"], 1/24)
  expect_equal(prep$conversion_factor[prep$PPTESTCD == "aumcall"], 3600)
  expect_equal(prep_no_conversions$conversion_factor[prep_no_conversions$PPTESTCD == "aumcall"], 24^-2)

  expect_error(
    pknca_units_table(
      concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
      timeu_pref = "day",
      conversions = data.frame(PPORRESU = "A", PPSTRESU = "B")
    ),
    regexp = "Cannot find PPORRESU match between conversions and preferred unit conversions.  Check PPORRESU values in 'conversions' argument.",
    fixed = TRUE
  )

  # Not all arguments are required
  expect_silent(
    pknca_units_table(
      concu = "ng/mL",
      doseu = "mg",
      timeu = "hr",
      timeu_pref = "day"
    )
  )
})

test_that("mcg is accepted as an alias of ug", {
  skip_if_not_installed("units")
  expect_equal(pknca_units_conversion_factor("mcg/mL", "ng/mL"), 1000)
  expect_equal(pknca_units_conversion_factor("mcg", "ug"), 1)
  expect_equal(pknca_units_conversion_factor("min*mcg/mL", "hr*ng/mL"), 1000/60)

  prep <-
    pknca_units_table(
      concu = "mcg/mL", doseu = "mg", timeu = "min", amountu = "mcg",
      concu_pref = "ng/mL", timeu_pref = "hr"
    )
  expect_equal(prep$conversion_factor[prep$PPTESTCD == "cmax"], 1000)
  expect_equal(prep$conversion_factor[prep$PPTESTCD == "tmax"], 1/60)
  expect_equal(prep$conversion_factor[prep$PPTESTCD == "auclast"], 1000/60)

  # Installing the units again (a second load of the package) is not an error
  expect_no_error(pknca_install_units())
  expect_equal(pknca_units_conversion_factor("mcg", "ug"), 1)
  expect_equal(pknca_units_conversion_factor("fraction", "1"), 1)
})

test_that("pknca_units_table expected errors", {
  expect_error(
    pknca_units_table(conversions = "A")
  )
  expect_error(
    pknca_units_table(conversions = data.frame(A = 1)),
    # Generate the error to match (in case its text changes)
    regexp =
      attr(
        try(
          checkmate::assert_names("A", subset.of = c("PPORRESU", "PPSTRESU", "conversion_factor"), .var.name = "names(conversions)"),
          silent = TRUE
        ),
        "condition"
      )$message,
    fixed = TRUE
  )
})

test_that("pknca_unit_conversion", {
  results <- data.frame(PPORRES = 1, PPTESTCD = "cmax")

  # No change when no unit conversion occurs
  expect_equal(pknca_unit_conversion(results, units = NULL), results)

  # Adding units with no conversion
  d_u <- data.frame(PPTESTCD = "cmax", PPORRESU = "ng/mL")
  results_u <- data.frame(PPORRES = 1, PPTESTCD = "cmax", PPORRESU = "ng/mL")
  expect_equal(pknca_unit_conversion(results, units = d_u), results_u)

  # Adding units with conversion
  d_u_conv <- data.frame(PPTESTCD = "cmax", PPORRESU = "ng/mL", conversion_factor = 0.001, PPSTRESU = "ug/mL")
  results_u_conv <- data.frame(PPORRES = 1, PPTESTCD = "cmax", PPORRESU = "ng/mL", PPSTRESU = "ug/mL", PPSTRES = 0.001)
  expect_equal(pknca_unit_conversion(results, units = d_u_conv), results_u_conv)

  # Adding units with some units missing gives an error
  d_u_missing <- data.frame(PPTESTCD = "cmax", PPORRESU = NA_character_)
  results_u_missing <- data.frame(PPORRES = 1, PPTESTCD = "cmax", PPORRESU = NA_character_)
  expect_error(
    pknca_unit_conversion(results, units = d_u_missing),
    regexp = "Units are provided for some but not all parameters; missing for: cmax\nThis error can be converted to a warning using `PKNCA.options(allow_partial_missing_units = TRUE)`",
    fixed = TRUE
  )

  # Adding units with some units missing gives an error; that error can be converted to a warning
  d_u_missing <- data.frame(PPTESTCD = "cmax", PPORRESU = NA_character_)
  results_u_missing <- data.frame(PPORRES = 1, PPTESTCD = "cmax", PPORRESU = NA_character_)
  expect_warning(
    pknca_unit_conversion(results, units = d_u_missing, allow_partial_missing_units = TRUE),
    regexp = "Units are provided for some but not all parameters; missing for: cmax",
    fixed = TRUE
  )

  # Fully-integrated test
  d_conc <- as.data.frame(Theoph[Theoph$Subject %in% Theoph$Subject[1], ])
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
  o_dose <- PKNCAdose(d_conc[d_conc$Time == 0, ], Dose~Time|Subject)
  # Do not give dose units
  d_units <- pknca_units_table(concu = "mg/L", timeu = "hr")
  d_interval <- data.frame(start = 0, end = Inf, cmax = TRUE, cl.inf.obs = TRUE)
  o_data <- PKNCAdata(o_conc, o_dose, intervals = d_interval, units = d_units)
  expect_error(
    pk.nca(o_data),
    regexp = "Units are provided for some but not all parameters; missing for: cl.inf.obs\nThis error can be converted to a warning using `PKNCA.options(allow_partial_missing_units = TRUE)`",
    fixed = TRUE
  )
  o_data_warn <- PKNCAdata(o_conc, o_dose, intervals = d_interval, units = d_units, options = list(allow_partial_missing_units = TRUE))
  expect_warning(
    pk.nca(o_data_warn),
    regexp = "Units are provided for some but not all parameters; missing for: cl.inf.obs",
    fixed = TRUE
  )
})

# Tests for pknca_units_table for PKNCAdata
test_that("pknca_units_table for PKNCAdata", {
  skip_if_not_installed("units")

  # Subset the data to only include USUBJID 8 (2 analytes, A & B)
  d_conc <- data.frame(
    subject = 1,
    time = rep(1:10, times = 4),
    conc = rep(c(0:5, 4:1), times = 4),
    analyte = rep(c("A", "B"), each = 20),
    specimen = rep(c("blood", "urine"), each = 10, times = 4),
    dose = 100,
    treatment = rep(c("drug1", "drug2"), each = 10 * 4)
  )
  d_dose <- unique(d_conc[d_conc$time %in% c(0, 5), c("dose", "time", "subject", "treatment")])

  # Creates a stratified units table when PKNCAconc has a unit-stratifying group column
  for (strat_var in c("specimen", "analyte")) {
    d_conc$concu_col <- ifelse(d_conc[[strat_var]] == d_conc[[strat_var]][1], "ng/mL", "ug/mL")

    o_conc <- PKNCAconc(d_conc, conc ~ time | treatment + specimen + subject / analyte, concu = "concu_col")
    o_dose <- PKNCAdose(d_dose, dose ~ time | treatment + subject)
    o_data <- PKNCAdata(o_conc, o_dose)
    units_table <- expect_no_error(pknca_units_table(o_data))

    expect_equal(
      units_table[units_table$PPTESTCD == "cmax", c(strat_var, "PPORRESU")],
      data.frame(
        specimen = c(unique(d_conc[[strat_var]])[1], unique(d_conc[[strat_var]])[2]),
        PPORRESU = c("ng/mL", "ug/mL")
      ), ignore_attr = TRUE
    )
  }

  # Creates a stratified units table when PKNCAconc has two unit-stratifying group columns
  d_conc$concu_col <- ifelse(d_conc$analyte == "A", "ng/mL", "ug/mL")
  d_conc$concu_col <- ifelse(d_conc$specimen == "blood", d_conc$concu_col, "pg/mL")
  o_conc <- PKNCAconc(d_conc, conc ~ time | treatment + specimen + subject / analyte, concu = "concu_col")
  o_dose <- PKNCAdose(d_dose, dose ~ time | treatment + subject)
  o_data <- PKNCAdata(o_conc, o_dose)
  units_table <- expect_no_error(pknca_units_table(o_data))

  # A primary parameter is described by one row per stratum, naming no
  # reference group.  The standardization columns come from the secondary
  # parameters whose composed units reduce to a fraction.
  expect_equal(
    units_table[units_table$PPTESTCD == "cmax",],
    data.frame(
      specimen = c("blood", "urine", "blood", "urine"),
      analyte = rep(c("A", "B"), each = 2),
      PPORRESU = c("ng/mL", "pg/mL", "ug/mL", "pg/mL"),
      PPTESTCD = "cmax",
      specimen_ref = NA_character_,
      analyte_ref = NA_character_,
      PPSTRESU = c("ng/mL", "pg/mL", "ug/mL", "pg/mL"),
      conversion_factor = 1
    ), ignore_attr = TRUE
  )

  # Creates a stratified units table when PKNCAdose has a unit-stratifying group column
  d_dose$doseu_col <- ifelse(d_dose$treatment == d_dose$treatment[1], "mg", "ug")
  o_conc <- PKNCAconc(d_conc, conc ~ time | treatment + specimen + subject / analyte)
  o_dose <- PKNCAdose(d_dose, dose ~ time | treatment + subject, doseu = "doseu_col")
  o_data <- PKNCAdata(o_conc, o_dose)
  units_table <- expect_no_error(pknca_units_table(o_data))

  expect_equal(
      units_table[units_table$PPTESTCD == "totdose",],
      data.frame(
        treatment = c("drug1", "drug2"),
        PPORRESU = c("mg", "ug"),
        PPTESTCD = "totdose",
        treatment_ref = NA_character_
      ), ignore_attr = TRUE
    )

  # Creates an uniform units table when units are not defined as columns
  o_conc <- PKNCAconc(
    d_conc, conc ~ time | treatment + specimen + subject / analyte,
    concu = "ng/mL", timeu = "h"
  )
  o_dose <- PKNCAdose(
    d_dose, dose ~ time | treatment + subject,
    doseu = "mg"
  )
  o_data <- PKNCAdata(o_conc, o_dose)
  units_table <- expect_no_error(pknca_units_table(o_data))
  expect_equal(
    units_table[units_table$PPTESTCD == "cmax.dn",],
    data.frame(
      PPORRESU = c("(ng/mL)/mg"),
      PPTESTCD = c("cmax.dn")
    ), ignore_attr = TRUE
  )

  # Returns NULL when no units are defined anywhere
  o_conc <- PKNCAconc(d_conc, conc ~ time | treatment + specimen + subject / analyte)
  o_dose <- PKNCAdose(d_dose, dose ~ time | treatment + subject)
  o_data <- PKNCAdata(o_conc, o_dose)
  units_table <- expect_no_error(pknca_units_table(o_data))

  expect_true(is.null(units_table))

  # Errors when units are not uniform within a concentration group
  d_conc$concu_col <- "ng/mL"
  d_conc$concu_col[1] <- "pg/L"  # Introduce inconsistency
  o_conc <- PKNCAconc(d_conc, conc ~ time | treatment + specimen + subject / analyte, concu = "concu_col")
  o_dose <- PKNCAdose(d_dose, dose ~ time | treatment + subject)
  expect_error(
    PKNCAdata(o_conc, o_dose),
    regexp = "Units should be uniform at least across concentration groups.*"
  )

  # The conversions argument is passed through to the per-group unit tables
  o_conc <- PKNCAconc(
    d_conc, conc ~ time | treatment + specimen + subject / analyte,
    concu = "ng/mL", timeu = "h"
  )
  o_dose <- PKNCAdose(
    d_dose, dose ~ time | treatment + subject,
    doseu = "mg"
  )
  o_data <- PKNCAdata(o_conc, o_dose)
  my_conversions <- data.frame(
    PPORRESU = "(ng/mL)/mg",
    PPSTRESU = "nmol/L/mg",
    conversion_factor = 1 / 138.121  # hypothetical molecular weight
  )
  units_table_converted <- expect_no_error(
    pknca_units_table(o_data, conversions = my_conversions)
  )
  # PPSTRESU and conversion_factor columns appear when conversions are supplied
  expect_true(all(c("PPSTRESU", "conversion_factor") %in% names(units_table_converted)))
  # The specified conversion is applied to the matching PPORRESU row
  expect_equal(
    units_table_converted$PPSTRESU[units_table_converted$PPTESTCD == "cmax.dn"],
    "nmol/L/mg"
  )
  expect_equal(
    units_table_converted$conversion_factor[units_table_converted$PPTESTCD == "cmax.dn"],
    1 / 138.121
  )

  # When no dose is provided, dose-related parameters are excluded from the unit
  # table (they do not appear with NA units)
  o_conc <- PKNCAconc(
    d_conc, conc ~ time | treatment + specimen + subject / analyte,
    concu = "ng/mL", timeu = "h"
  )
  o_data <- PKNCAdata(
    o_conc,
    intervals = data.frame(start = 0, end = Inf, cmax = TRUE, totdose = FALSE)
  )
  units_table <- expect_no_error(pknca_units_table(o_data))
  # Non-dose-related parameters have units
  expect_true("cmax" %in% units_table$PPTESTCD)
  expect_false(anyNA(units_table$PPORRESU[units_table$PPTESTCD == "cmax"]))
  # Dose-related parameters are absent entirely
  expect_false("totdose" %in% units_table$PPTESTCD)
  expect_false("cmax.dn" %in% units_table$PPTESTCD)
})

test_that("select_minimal_grouping_cols returns df unchanged when strata_cols is empty", {
  df <- data.frame(a = 1:3, b = letters[1:3])
  expect_identical(select_minimal_grouping_cols(df, character(0)), df)
  expect_identical(select_minimal_grouping_cols(df, c()), df)
})

test_that("select_minimal_grouping_cols", {
  # Make a dataset where a variable `d` depends on `a` & `b`
  data <- data.frame(
    a = rep(letters[c(1, 2, 3)], each = 4),
    b = rep(letters[c(1, 2)], each = 3),
    c = letters[1]
  )
  data$d <- paste0(data$a, data$b)

  # Returns the minimal grouping_columns (a, b) for one target columns
  result <- select_minimal_grouping_cols(data, "d")
  expect_equal(result, data[c("a", "b", "d")])

  # Returns the original data if all grouping columns are needed
  result <- select_minimal_grouping_cols(data, c("c", "d"))
  expect_equal(result, data)

  # Returns just the strata columns if no stratification groups are found
  data[, "a"] <- 10
  result <- select_minimal_grouping_cols(data, "d")
  expect_equal(result, data["d"])
})

test_that("A preferred unit equal to the original unit needs no conversion (and no units package)", {
  # Only preferred units that differ from the original ones become conversions,
  # so when none differ there is no conversion at all.
  units_same <- pknca_units_table(concu = "ng/mL", doseu = "mg", amountu = "mg", timeu = "hr", timeu_pref = "hr")
  units_none <- pknca_units_table(concu = "ng/mL", doseu = "mg", amountu = "mg", timeu = "hr")
  expect_equal(units_same, units_none)
})

test_that("pknca_units_table for PKNCAdata joins ordered factor groups whose levels differ", {
  ord <- function(x, levels) factor(x, levels = levels, ordered = TRUE)
  d_conc <-
    data.frame(
      subject = ord(rep(c("a", "b"), each = 3), c("b", "a")),
      time = rep(0:2, 2),
      conc = c(0, 2, 1, 0, 3, 1)
    )
  d_dose <-
    data.frame(
      subject = ord(c("a", "b"), c("c", "b", "a")),
      time = 0, dose = 10, doseu = c("mg", "ug")
    )
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|subject, concu = "ng/mL", timeu = "hr", amountu = "mg"),
      PKNCAdose(d_dose, dose~time|subject, doseu = "doseu"),
      intervals = data.frame(start = 0, end = 2, cmax = TRUE, cmax.dn = TRUE)
    )
  units_table <- o_data$units
  expect_equal(
    units_table$PPORRESU[units_table$PPTESTCD == "cmax.dn" & is.na(units_table$subject_ref)],
    c("(ng/mL)/mg", "(ng/mL)/ug")
  )
  expect_equal(
    units_table$subject[units_table$PPTESTCD == "cmax.dn" & is.na(units_table$subject_ref)],
    c("a", "b")
  )
})

test_that("unit conversion joins results to the units table by group value, keeping the group column types", {
  # Subject 2 has no dose, so the units differ by subject and the units table
  # keeps the subject column (as character, while the data have integers)
  d_conc <-
    data.frame(
      subject = rep(1:2, each = 3), time = rep(0:2, 2),
      conc = c(0, 2, 1, 0, 3, 1)
    )
  o_data <-
    suppressWarnings(PKNCAdata(
      PKNCAconc(d_conc, conc~time|subject, concu = "ng/mL", timeu = "hr", amountu = "mg"),
      PKNCAdose(data.frame(subject = 1L, time = 0, dose = 10), dose~time|subject, doseu = "mg"),
      intervals = data.frame(start = 0, end = 2, cmax = TRUE)
    ))
  expect_type(o_data$units$subject, "character")
  expect_equal(
    o_data$units$PPORRESU[o_data$units$PPTESTCD == "cmax.dn"],
    c("(ng/mL)/mg", NA)
  )
  df_nca <- as.data.frame(pk.nca(o_data))
  expect_identical(df_nca$subject, 1:2)
  expect_equal(df_nca$PPORRES, c(2, 3))
  expect_equal(df_nca$PPORRESU, c("ng/mL", "ng/mL"))

  # A factor group column stays a factor with its levels
  d_conc_fct <- d_conc
  d_conc_fct$subject <- factor(d_conc_fct$subject, levels = 2:1)
  d_conc_fct$concu <- rep(c("ng/mL", "ug/mL"), each = 3)
  o_data_fct <-
    PKNCAdata(
      PKNCAconc(d_conc_fct, conc~time|subject, concu = "concu", timeu = "hr"),
      intervals = data.frame(start = 0, end = 2, cmax = TRUE)
    )
  df_nca_fct <- as.data.frame(pk.nca(o_data_fct))
  # Results are in the order of the factor levels
  expect_identical(df_nca_fct$subject, factor(c(2, 1), levels = 2:1))
  expect_equal(df_nca_fct$PPORRES, c(3, 2))
  expect_equal(df_nca_fct$PPORRESU, c("ug/mL", "ng/mL"))
})

test_that("unit conversion matches integer reference group columns of secondary parameters", {
  d_conc <-
    data.frame(
      subject = 1L, spec = rep(1:2, times = c(3, 2)),
      time = c(0, 12, 24, 0, 12), conc = c(10, 6, 2, 2, 1), vol = c(NA, NA, NA, 100, 150),
      cu = rep(c("mg/L", "mg/mL"), times = c(3, 2))
    )
  o_conc <- PKNCAconc(d_conc, conc~time|spec + subject, volume = "vol", concu = "cu", timeu = "hr", amountu = "mg")
  o_dose <- PKNCAdose(data.frame(subject = 1L, time = 0, dose = 50), dose~time|subject, doseu = "mg")
  intervals <-
    data.frame(
      spec = 1:2, start = 0, end = 24, interval_id = c("p", NA),
      auclast = c(TRUE, FALSE), clr.last = c(FALSE, TRUE), clr.last_ref = c(NA, "p")
    )
  df_nca <- as.data.frame(pk.nca(PKNCAdata(o_conc, o_dose, intervals = intervals)))
  expect_equal(df_nca$PPTESTCD, c("auclast", "ae", "clr.last"))
  expect_identical(df_nca$spec_ref, c(NA, NA, 1L))
  expect_equal(df_nca$PPORRESU, c("hr*mg/L", "mg", "mg/(hr*mg/L)"))
})

test_that("left_join_by_value matches keys of different types by value", {
  x <- data.frame(g = c(2L, 1L, 2L, 3L), f = factor(c("b", "a", "b", "c"), levels = c("c", "b", "a")), v = 1:4)
  y <- data.frame(g = c("1", "2"), f = c("a", "b"), w = c("one", "two"))
  expect_identical(
    left_join_by_value(x, y, by = c("g", "f")),
    data.frame(x, w = c("two", "one", "two", NA))
  )
  # A row of x with several matches in y is repeated
  y_dup <- data.frame(g = c("2", "2"), w = c("a", "b"))
  expect_identical(
    left_join_by_value(x[1, c("g", "v")], y_dup, by = "g"),
    data.frame(g = c(2L, 2L), v = c(1L, 1L), w = c("a", "b"))
  )
})

test_that("Preferred units with unit columns convert the groups that need it and keep the others", {
  skip_if_not_installed("units")
  d_conc <-
    data.frame(
      analyte = rep(c("parent", "metabolite"), each = 3), subject = 1,
      time = rep(c(0, 12, 24), 2), conc = c(4, 10, 2, 8000, 20000, 4000),
      cu = rep(c("mg/L", "ng/mL"), each = 3), tu = "hr"
    )
  o_conc <- PKNCAconc(d_conc, conc~time|analyte + subject, concu = "cu", timeu = "tu", concu_pref = "mg/L")
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 24, cmax = TRUE))
  units_cmax <- o_data$units[o_data$units$PPTESTCD == "cmax", ]
  expect_equal(units_cmax$analyte, c("parent", "metabolite"))
  expect_equal(units_cmax$PPORRESU, c("mg/L", "ng/mL"))
  # The parent is already in the preferred units
  expect_equal(units_cmax$PPSTRESU, c("mg/L", "mg/L"))
  expect_equal(units_cmax$conversion_factor, c(1, 0.001))
  df_nca <- as.data.frame(pk.nca(o_data))
  expect_equal(df_nca$analyte, c("metabolite", "parent"))
  expect_equal(df_nca$PPORRES, c(20000, 10))
  expect_equal(df_nca$PPSTRES, c(20, 10))
  expect_equal(df_nca$PPSTRESU, c("mg/L", "mg/L"))

  # The same with a dose unit column and preferred dose units
  d_conc_dose <- data.frame(treatment = rep(c("A", "B"), each = 3), time = rep(c(0, 12, 24), 2), conc = c(4, 10, 2, 4, 10, 2))
  d_dose <- data.frame(treatment = c("A", "B"), time = 0, dose = c(1, 1000), du = c("mg", "ug"))
  o_data_dose <-
    PKNCAdata(
      PKNCAconc(d_conc_dose, conc~time|treatment, concu = "mg/L", timeu = "hr"),
      PKNCAdose(d_dose, dose~time|treatment, doseu = "du", doseu_pref = "mg"),
      intervals = data.frame(start = 0, end = 24, cmax.dn = TRUE)
    )
  units_cmax_dn <- o_data_dose$units[o_data_dose$units$PPTESTCD == "cmax.dn" & is.na(o_data_dose$units$treatment_ref), ]
  expect_equal(units_cmax_dn$PPORRESU, c("(mg/L)/mg", "(mg/L)/ug"))
  expect_equal(units_cmax_dn$PPSTRESU, c("(mg/L)/mg", "(mg/L)/mg"))
  expect_equal(units_cmax_dn$conversion_factor, c(1, 1000))
  df_nca_dose <- as.data.frame(pk.nca(o_data_dose))
  expect_equal(df_nca_dose$PPSTRES[df_nca_dose$PPTESTCD == "cmax.dn"], c(10, 10))
})

# Metabolite ratios:  masses, amounts of substance, and each side's conversion

test_that("pknca_units_amount_basis() reads the kind of amount from the unit's symbols", {
  known <-
    rbind(
      data.frame(unit = "ng/mL", basis = "g"),
      data.frame(unit = "hr*ng/mL", basis = "g"),
      data.frame(unit = "(hr^2)*ug/L", basis = "g"),
      data.frame(unit = "mg", basis = "g"),
      data.frame(unit = "mcg/mL", basis = "g"),
      data.frame(unit = "\u00b5g/mL", basis = "g"),
      data.frame(unit = "\u03bcmol/L", basis = "mol"),
      data.frame(unit = "nmol/L", basis = "mol"),
      data.frame(unit = "hr*mmol/L", basis = "mol"),
      data.frame(unit = "nM", basis = "mol"),
      data.frame(unit = "IU/mL", basis = NA_character_),
      data.frame(unit = "fraction", basis = NA_character_),
      data.frame(unit = "ng/nmol", basis = NA_character_),
      data.frame(unit = NA_character_, basis = NA_character_)
    )
  for (i in seq_len(nrow(known))) {
    expect_equal(pknca_units_amount_basis(known$unit[i]), known$basis[i], info = known$unit[i])
  }
  expect_equal(pknca_units_amount_ratio("ng/mL", "ug/L"), "g/g")
  expect_equal(pknca_units_amount_ratio("nmol/L", "nM"), "mol/mol")
  expect_equal(pknca_units_amount_ratio("ng/mL", "nmol/L"), NA_character_)
  expect_equal(pknca_units_amount_ratio("IU/mL", "IU/mL"), NA_character_)
  expect_true(pknca_units_amount_mixed("ng/mL", "nmol/L"))
  expect_false(pknca_units_amount_mixed("IU/mL", "nmol/L"))
})

test_that("every metabolite ratio is a ratio of masses or of amounts of substance", {
  mr_params <- grep("^mr[.]", names(get.interval.cols()), value = TRUE)
  mr_params <- mr_params[is_metabolite_ratio(mr_params)]
  expect_equal(length(mr_params), 38)
  mass <- pknca_units_table(concu = "ng/mL", doseu = "mg", amountu = "mg", timeu = "hr")
  molar <- pknca_units_table(concu = "nmol/L", doseu = "mg", amountu = "mmol", timeu = "hr")
  for (param in mr_params) {
    expect_equal(mass$PPORRESU[mass$PPTESTCD == param], "g/g", info = param)
    expect_equal(molar$PPORRESU[molar$PPTESTCD == param], "mol/mol", info = param)
  }
  # Every other parameter keeps its units
  other <- !(mass$PPTESTCD %in% mr_params)
  before <- pknca_units_table(concu = "ng/mL", doseu = "mg", amountu = "mg", timeu = "hr")
  expect_equal(mass$PPORRESU[other], before$PPORRESU[other])
  expect_equal(mass$PPORRESU[mass$PPTESTCD == "ratio.cmax"], "fraction")
  # Units that are neither keep the ratio a fraction
  activity <- pknca_units_table(concu = "IU/mL", timeu = "hr")
  expect_equal(activity$PPORRESU[activity$PPTESTCD == "mr.cmax"], "fraction")
})

test_that("a metabolite ratio's standardized units follow its base's", {
  pref <- pknca_units_table(concu = "nmol/L", timeu = "hr", concu_pref = "umol/L")
  mask <- pref$PPTESTCD == "mr.cmax"
  expect_equal(pref$PPORRESU[mask], "mol/mol")
  expect_equal(pref$PPSTRESU[mask], "mol/mol")
  expect_equal(pref$conversion_factor[mask], 1)
  # A conversion of "fraction" itself is kept
  percent <-
    pknca_units_table(
      concu = "ng/mL", timeu = "hr",
      conversions = data.frame(PPORRESU = "fraction", PPSTRESU = "%")
    )
  mask <- percent$PPTESTCD == "mr.cmax"
  expect_equal(percent$PPORRESU[mask], "g/g")
  expect_equal(percent$PPSTRESU[mask], "%")
  expect_equal(percent$conversion_factor[mask], 100)
})

# Parent MW 325.8 g/mol and metabolite MW 341.8 g/mol, in ng/mL:  1 ng/mL is
# 1000/MW nmol/L
units_mr_molar <- function(analyte, mw) {
  cbind(
    analyte = analyte,
    pknca_units_table(
      concu = "ng/mL", timeu = "hr",
      conversions =
        data.frame(
          PPORRESU = c("ng/mL", "hr*ng/mL"),
          PPSTRESU = c("nmol/L", "hr*nmol/L"),
          conversion_factor = 1000 / mw
        )
    )
  )
}

d_conc_mr_units <-
  rbind(
    data.frame(subject = 1, analyte = "parent", time = c(0, 1, 2, 4, 8), conc = c(0, 100, 80, 40, 10)),
    data.frame(subject = 1, analyte = "M1", time = c(0, 1, 2, 4, 8), conc = c(0, 30, 40, 20, 5))
  )
# The secondary parameters are requested for the metabolite only
intervals_mr_units <-
  rbind(
    data.frame(analyte = "parent", start = 0, end = 8, cmax = TRUE, auclast = TRUE, mr.auclast = FALSE, ratio.cmax = FALSE),
    data.frame(analyte = "M1", start = 0, end = 8, cmax = TRUE, auclast = TRUE, mr.auclast = TRUE, ratio.cmax = TRUE)
  )

# The result of `param` for `analyte`
mr_units_row <- function(d_res, analyte, param) {
  d_res[d_res$analyte == analyte & d_res$PPTESTCD == param, ]
}

test_that("a molar metabolite ratio comes from a units table per analyte (MW 325.8 and 341.8)", {
  units_molar <- rbind(units_mr_molar("parent", 325.8), units_mr_molar("M1", 341.8))
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc_mr_units, conc ~ time | subject / analyte),
      intervals = intervals_mr_units,
      group_ref = data.frame(analyte = "parent"),
      units = units_molar
    )
  # The table given is stored as it was given
  expect_identical(o_data$units, units_molar)
  d_res <- as.data.frame(suppressMessages(pk.nca(o_data)))
  mass_ratio <- mr_units_row(d_res, "M1", "auclast")$PPORRES / mr_units_row(d_res, "parent", "auclast")$PPORRES
  d_mr <- mr_units_row(d_res, "M1", "mr.auclast")
  expect_equal(d_mr$PPORRES, mass_ratio)
  expect_equal(d_mr$PPORRESU, "g/g")
  expect_equal(d_mr$PPSTRES, mass_ratio * 325.8 / 341.8, tolerance = 1e-12)
  expect_equal(d_mr$PPSTRESU, "mol/mol")
  # The molar ratio is the ratio of the two molar AUCs
  expect_equal(
    d_mr$PPSTRES,
    mr_units_row(d_res, "M1", "auclast")$PPSTRES / mr_units_row(d_res, "parent", "auclast")$PPSTRES,
    tolerance = 1e-12
  )
  # A ratio is standardized from each side's conversion as well, and stays a
  # fraction
  d_ratio <- mr_units_row(d_res, "M1", "ratio.cmax")
  expect_equal(d_ratio$PPORRES, 40 / 100)
  expect_equal(d_ratio$PPSTRES, 40 / 100 * 325.8 / 341.8, tolerance = 1e-12)
  expect_equal(d_ratio$PPSTRESU, "fraction")
})

test_that("a metabolite ratio of a mass and an amount of substance is an error", {
  units_m1 <- cbind(analyte = "M1", pknca_units_table(concu = "ng/mL", timeu = "hr"))
  units_m1$PPSTRESU <- units_m1$PPORRESU
  units_m1$conversion_factor <- 1
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc_mr_units, conc ~ time | subject / analyte),
      intervals = intervals_mr_units,
      group_ref = data.frame(analyte = "parent"),
      units = rbind(units_mr_molar("parent", 325.8), units_m1)
    )
  expect_error(
    suppressMessages(pk.nca(o_data)),
    regexp = "Metabolite ratio 'mr.auclast' would divide a mass by an amount of substance:  'auclast' of analyte=M1 is in 'hr*ng/mL' and of analyte=parent in 'hr*ng/mL' (standardized 'hr*nmol/L')",
    fixed = TRUE,
    class = "pknca_error_mr_units_mixed"
  )
  # The same in the table PKNCAdata() builds from unit columns
  d_conc <- d_conc_mr_units
  d_conc$concu <- ifelse(d_conc$analyte == "parent", "ng/mL", "nmol/L")
  o_data_built <-
    PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | subject / analyte, concu = "concu", timeu = "hr"),
      intervals = intervals_mr_units,
      group_ref = data.frame(analyte = "parent")
    )
  expect_error(
    suppressMessages(pk.nca(o_data_built)),
    regexp = "'auclast' of analyte=M1 is in 'hr*nmol/L' and of analyte=parent in 'hr*ng/mL'",
    fixed = TRUE,
    class = "pknca_error_mr_units_mixed"
  )
})

test_that("a units table per analyte without one of the pair is an error for a metabolite ratio", {
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc_mr_units, conc ~ time | subject / analyte),
      intervals = intervals_mr_units,
      group_ref = data.frame(analyte = "parent"),
      units = units_mr_molar("parent", 325.8)
    )
  expect_error(
    suppressMessages(pk.nca(o_data)),
    regexp = "The units table has no units for metabolite ratio 'mr.auclast' of analyte=M1 to analyte=parent:  it needs the units of 'auclast' for both.",
    fixed = TRUE,
    class = "pknca_error_units_secondary_missing"
  )
})

test_that("a metabolite ratio between analytes in different mass units standardizes to g/g", {
  d_conc <- d_conc_mr_units
  d_conc$concu <- ifelse(d_conc$analyte == "parent", "ng/mL", "ug/mL")
  o_data <-
    PKNCAdata(
      PKNCAconc(d_conc, conc ~ time | subject / analyte, concu = "concu", timeu = "hr"),
      intervals = intervals_mr_units,
      group_ref = data.frame(analyte = "parent")
    )
  d_res <- as.data.frame(suppressMessages(pk.nca(o_data)))
  d_mr <- d_res[d_res$analyte == "M1" & d_res$PPTESTCD == "mr.auclast", ]
  # The raw quotient is in the quotient of the two units
  expect_equal(d_mr$PPORRESU, "(hr*ug/mL)/(hr*ng/mL)")
  expect_equal(d_mr$PPSTRESU, "g/g")
  expect_equal(d_mr$PPSTRES, d_mr$PPORRES * 1000)
  d_ratio <- d_res[d_res$analyte == "M1" & d_res$PPTESTCD == "ratio.cmax", ]
  expect_equal(d_ratio$PPORRESU, "(ug/mL)/(ng/mL)")
  expect_equal(d_ratio$PPSTRESU, "fraction")
  expect_equal(d_ratio$PPSTRES, 400)
})

test_that("a given units table gains rows only for the pairs of groups the results name", {
  units_given <- rbind(units_mr_molar("parent", 325.8), units_mr_molar("M1", 341.8), units_mr_molar("M2", 300))
  result <-
    data.frame(
      analyte = c("M1", "parent", "M1"), analyte_ref = c("parent", NA, NA),
      PPTESTCD = c("mr.auclast", "auclast", "auclast"), PPORRES = 1
    )
  joined <- pknca_units_table_join_pairs(units_given, result)
  pair_rows <- joined[!is.na(joined$analyte_ref), ]
  expect_equal(unique(pair_rows$analyte), "M1")
  expect_equal(unique(pair_rows$analyte_ref), "parent")
  expect_equal(nrow(joined) - nrow(units_given), nrow(pair_rows))
  # The rows of the given table are kept, with no reference group
  expect_equal(joined[is.na(joined$analyte_ref), names(units_given)], units_given, ignore_attr = TRUE)
  # Results with no reference columns leave the table as given
  expect_identical(pknca_units_table_join_pairs(units_given, result[, c("analyte", "PPTESTCD", "PPORRES")]), units_given)
})

# secondary_pair_units() with a fresh cache of conversion factors
pair_units_fresh <- function(...) {
  secondary_pair_units(factor_cache = new.env(parent = emptyenv()), ...)
}

test_that("secondary_pair_units() composes each kind of pair", {
  base <- data.frame(PPORRESU = "fraction", PPTESTCD = "ratio.cmax", PPSTRESU = "%", conversion_factor = 100)
  base_mr <- data.frame(PPORRESU = "g/g", PPTESTCD = "mr.cmax", PPSTRESU = "g/g", conversion_factor = 1)
  # Units a side does not know keep the base row
  expect_equal(
    pair_units_fresh(param = "ratio.cmax", base = base, u = c("ng/mL", NA), s = c("ng/mL", NA), side_factor = 1, is_mr = FALSE, has_std = TRUE),
    base
  )
  # The same units on both sides, with no standardized units
  expect_equal(
    pair_units_fresh(param = "ratio.cmax", base = base, u = c("ng/mL", "ng/mL"), s = c("ng/mL", "ng/mL"), side_factor = 1, is_mr = FALSE, has_std = FALSE),
    data.frame(PPORRESU = "fraction", PPTESTCD = "ratio.cmax", PPSTRESU = NA_character_, conversion_factor = NA_real_)
  )
  # ... standardized into units that are not convertible:  their quotient
  expect_equal(
    pair_units_fresh(param = "ratio.cmax", base = base, u = c("ng/mL", "ng/mL"), s = c("IU/mL", "ng/mL"), side_factor = 2, is_mr = FALSE, has_std = TRUE),
    data.frame(PPORRESU = "fraction", PPTESTCD = "ratio.cmax", PPSTRESU = "(IU/mL)/(ng/mL)", conversion_factor = 2)
  )
  # ... a ratio keeps its base's standardized units, with each side's conversion
  expect_equal(
    pair_units_fresh(param = "ratio.cmax", base = base, u = c("ng/mL", "ng/mL"), s = c("nmol/L", "nmol/L"), side_factor = 0.5, is_mr = FALSE, has_std = TRUE),
    data.frame(PPORRESU = "fraction", PPTESTCD = "ratio.cmax", PPSTRESU = "%", conversion_factor = 50)
  )
  # ... a metabolite ratio is labelled from the sides
  expect_equal(
    pair_units_fresh(param = "mr.cmax", base = base_mr, u = c("ng/mL", "ng/mL"), s = c("nmol/L", "nmol/L"), side_factor = 0.5, is_mr = TRUE, has_std = TRUE),
    data.frame(PPORRESU = "g/g", PPTESTCD = "mr.cmax", PPSTRESU = "mol/mol", conversion_factor = 0.5)
  )
  # Different, convertible units
  expect_equal(
    pair_units_fresh(param = "ratio.cmax", base = base, u = c("ug/mL", "ng/mL"), s = c("ug/mL", "ng/mL"), side_factor = 1, is_mr = FALSE, has_std = FALSE),
    data.frame(PPORRESU = "(ug/mL)/(ng/mL)", PPTESTCD = "ratio.cmax", PPSTRESU = "fraction", conversion_factor = 1000)
  )
  expect_equal(
    pair_units_fresh(param = "mr.cmax", base = base_mr, u = c("ug/mL", "ng/mL"), s = c("ug/mL", "ng/mL"), side_factor = 1, is_mr = TRUE, has_std = FALSE),
    data.frame(PPORRESU = "(ug/mL)/(ng/mL)", PPTESTCD = "mr.cmax", PPSTRESU = "g/g", conversion_factor = 1000)
  )
  # Different units that are not convertible
  expect_equal(
    pair_units_fresh(param = "ratio.cmax", base = base, u = c("mg", "mg/kg"), s = c("g", "mg/kg"), side_factor = 0.001, is_mr = FALSE, has_std = TRUE),
    data.frame(PPORRESU = "mg/(mg/kg)", PPTESTCD = "ratio.cmax", PPSTRESU = "g/(mg/kg)", conversion_factor = 0.001)
  )
  expect_equal(
    pair_units_fresh(param = "ratio.cmax", base = base, u = c("mg", "mg/kg"), s = c("mg", "mg/kg"), side_factor = 1, is_mr = FALSE, has_std = FALSE),
    data.frame(PPORRESU = "mg/(mg/kg)", PPTESTCD = "ratio.cmax", PPSTRESU = NA_character_, conversion_factor = NA_real_)
  )
})
