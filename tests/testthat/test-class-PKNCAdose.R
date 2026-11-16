test_that("PKNCAdose", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.conc.analyte <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                    nanalytes=2)
  tmp.conc.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                  nstudies=2)
  tmp.conc.analyte.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                          nanalytes=2, nstudies=2)
  tmp.dose <- generate.dose(tmp.conc)
  rownames(tmp.dose) <- NULL
  tmp.dose.analyte <- generate.dose(tmp.conc.analyte)
  tmp.dose.study <- generate.dose(tmp.conc.study)
  tmp.dose.analyte.study <- generate.dose(tmp.conc.analyte.study)

  # Data exists
  expect_error(PKNCAdose(data.frame()),
               regexp="Must have at least 1 rows",
               info="PKNCAconc requires data"
  )
  
  # Variables present
  expect_error(PKNCAdose(tmp.dose, formula=dosea~time|treatment+ID),
               regexp="The left side formula must be a variable in the data, empty, or '.'.",
               info="All formula parameters must be in the data (LHS)")
  expect_error(PKNCAdose(tmp.dose, formula=dose~timea|treatment+ID),
               regexp="The right side formula must be a variable in the data or '.'.",
               info="All formula parameters must be in the data (RHS)")
  expect_error(PKNCAdose(tmp.dose, formula=dose~time|treatmenta+ID),
               regexp="All of the variables in the groups must be in the data",
               info="All formula parameters must be in the data (groups)")
  expect_error(PKNCAdose(tmp.dose, formula=dosea~time|treatment/ID),
               regexp="formula for PKNCAdose may not include a slash",
               info="The formula string must not contain any slashes")

  # Number of variables
  expect_error(PKNCAdose(tmp.dose, formula=dose+ID~time|treatment+ID),
               regexp="The left side of the formula must have zero or one variable",
               info="The right number of parameters in the formula (LHS)")
  expect_error(PKNCAdose(tmp.dose, formula=dose~time+ID|treatment+ID),
               regexp="The right side of the formula \\(excluding groups\\) must have exactly one variable",
               info="The right number of parameters in the formula (RHS)")
  expect_error(PKNCAdose(tmp.dose, formula=~time+ID|treatment+ID),
               regexp="The right side of the formula \\(excluding groups\\) must have exactly one variable",
               info="The right number of parameters in the formula (RHS)")

  # Accept "." on either side of the ~
  expect_equal(
    PKNCAdose(tmp.dose, formula=.~time|treatment+ID),
    structure(
      list(
        data =
          cbind(
            tmp.dose,
            data.frame(
              exclude = NA_character_,
              route = "extravascular",
              duration = 0
            )
          ),
        formula = . ~ time | treatment + ID,
        columns =
          list(
            dose = character(),
            time = "time",
            groups =
              list(
                group_vars = c("treatment", "ID"),
                group_analyte = character()
              ),
            exclude = "exclude",
            route = "route",
            duration = "duration"
          ),
        units = list()
      ),
      class = c("PKNCAdose", "list")
    ),
    info="PKNCAdose accepts . on the left side of the formula"
  )
  expect_equal(
    PKNCAdose(tmp.dose, formula = dose~.|treatment+ID),
    structure(
      list(
        data =
          cbind(
            tmp.dose,
            data.frame(
              exclude = NA_character_,
              route = "extravascular",
              duration = 0
            )
          ),
        formula = dose ~ . | treatment + ID,
        columns =
          list(
            dose = "dose",
            time = character(),
            groups =
              list(
                group_vars = c("treatment", "ID"),
                group_analyte = character()
              ),
            exclude = "exclude",
            route = "route",
            duration = "duration"
          ),
        units = list()
      ),
      class = c("PKNCAdose", "list")
    ),
    info = "PKNCAdose accepts . on the right side of the formula"
  )

  tmp.dose.na <- tmp.dose
  tmp.dose.na$time[1] <- NA
  expect_error(PKNCAdose(tmp.dose.na, formula=dose~time|treatment+ID),
               regexp="Some but not all values are missing for the independent variable",
               info="Dose time must either all or none be NA.")
  # Keys must be unique
  bad.dose.analyte <- unique(tmp.conc.analyte[,c("treatment", "ID", "analyte")])
  bad.dose.analyte$dose <- 1
  bad.dose.analyte$time <- 0
  expect_error(
    PKNCAdose(bad.dose.analyte, formula=dose~time|treatment+ID),
    regexp="Rows that are not unique per group and time"
  )

  expect_equal(
    PKNCAdose(
      tmp.dose,
      formula=dose~time|treatment+ID
    ),
    PKNCAdose(
      dplyr::as_tibble(tmp.dose),
      formula=dose~time|treatment+ID
    ),
    info="tibble and data.frame classes both work and create identical objects"
  )
})

test_that("PKNCAdose without a data.frame as input", {
  tmp <- structure(list(), class="foo")
  captured_message <- tryCatch(as.data.frame(tmp), error=function(e) e$message)
  expect_error(PKNCAdose(tmp, formula=.~time|treatment+ID),
               regexp=captured_message,
               fixed=TRUE,
               info="PKNCAdose tries to make arbitrary data into a data.frame")
})

test_that("PKNCAdose model.frame", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp_conc_single <- generate.conc(nsub=1, ntreat=1, time.points=0:24)
  tmp.conc.analyte <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                    nanalytes=2)
  tmp.conc.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                  nstudies=2)
  tmp.conc.analyte.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                          nanalytes=2, nstudies=2)
  tmp.dose <- generate.dose(tmp.conc)
  tmp_dose_single <- generate.dose(tmp_conc_single)

  mydose1 <- PKNCAdose(formula=dose~time|treatment+ID, data=tmp.dose)
  expect_equal(getDepVar.PKNCAdose(mydose1),
               rep(1:2, each=5),
               info="getDepVar.PKNCAdose works with two-sided formula")
  expect_equal(getIndepVar.PKNCAdose(mydose1),
               rep(0, 10),
               info="getIndepVar.PKNCAdose works with two-sided formula")
  expect_equal(model.frame.PKNCAdose(mydose1),
               data.frame("getDepVar.PKNCAdose(formula)"=rep(1:2, each=5),
                          "getIndepVar.PKNCAdose(formula)"=0,
                          treatment=rep(c("Trt 1", "Trt 2"), each=5),
                          ID=rep(1:5, 2)),
               ignore_attr=TRUE,
               info="model.frame.PKNCAdose works with two-sided formula")

  mydose2 <- PKNCAdose(formula=~time|treatment+ID, data=tmp.dose)
  expect_equal(getDepVar.PKNCAdose(mydose2),
               rep(NA_integer_, 10),
               info="getDepVar.PKNCAdose works with one-sided formula")
  expect_equal(getIndepVar.PKNCAdose(mydose2),
               rep(0, 10),
               info="getIndepVar.PKNCAdose works with one-sided formula")
  expect_equal(model.frame.PKNCAdose(mydose2),
               data.frame("getDepVar.PKNCAdose(formula)"=NA_integer_,
                          "getIndepVar.PKNCAdose(formula)"=0,
                          treatment=rep(c("Trt 1", "Trt 2"), each=5),
                          ID=rep(1:5, 2)),
               ignore_attr=TRUE,
               info="model.frame.PKNCAdose works with one-sided formula")

  mydose3 <- PKNCAdose(formula=.~time|treatment+ID, data=tmp.dose)
  expect_equal(getDepVar.PKNCAdose(mydose3),
               rep(NA_integer_, 10),
               info="getDepVar.PKNCAdose works with one-sided formula ('.' on LHS)")
  expect_equal(getIndepVar.PKNCAdose(mydose3),
               rep(0, 10),
               info="getIndepVar.PKNCAdose works with one-sided formula ('.' on LHS)")
  expect_equal(model.frame.PKNCAdose(mydose3),
               data.frame("getDepVar.PKNCAdose(formula)"=NA_integer_,
                          "getIndepVar.PKNCAdose(formula)"=0,
                          treatment=rep(c("Trt 1", "Trt 2"), each=5),
                          ID=rep(1:5, 2)),
               ignore_attr=TRUE,
               info="model.frame.PKNCAdose works with one-sided formula ('.' on LHS)")

  mydose4 <- PKNCAdose(formula=dose~.|treatment+ID, data=tmp.dose)
  expect_equal(getDepVar.PKNCAdose(mydose4),
               rep(1:2, each=5),
               info="getDepVar.PKNCAdose works with one-sided formula ('.' on RHS)")
  expect_equal(getIndepVar.PKNCAdose(mydose4),
               rep(NA_integer_, 10),
               info="getIndepVar.PKNCAdose works with one-sided formula ('.' on RHS)")
  expect_equal(model.frame.PKNCAdose(mydose4),
               data.frame("getDepVar.PKNCAdose(formula)"=rep(1:2, each=5),
                          "getIndepVar.PKNCAdose(formula)"=NA_integer_,
                          treatment=rep(c("Trt 1", "Trt 2"), each=5),
                          ID=rep(1:5, 2)),
               ignore_attr=TRUE,
               info="model.frame.PKNCAdose works with one-sided formula ('.' on RHS)")

  # You can't give multiple rows per group if you don't give time.
  expect_error(PKNCAdose(formula=dose~.|treatment+ID, data=rbind(tmp.dose, tmp.dose)),
               regexp="Rows that are not unique per group and time.*found within dosing data",
               info="Dosing must have unique values with time and group")

  expect_equal(
    group_vars.PKNCAdose(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)),
    c("treatment", "ID")
  )
  expect_equal(
    group_vars.PKNCAdose(PKNCAdose(tmp_dose_single, formula=dose~time)),
    character(0),
    info="Ungrouped data works with group_vars"
  )
})

test_that("print.PKNCAdose", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  mydose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  tmp.conc.nogroup <- generate.conc(nsub=1, ntreat=1, time.points=0:24)
  tmp.dose.nogroup <- generate.dose(tmp.conc.nogroup)
  mydose.nogroup <- PKNCAdose(tmp.dose.nogroup, formula=dose~time)

  expect_output(print(mydose),
                regexp="Formula for dosing:
 dose ~ time | treatment + ID
Nominal time column is not specified.

First 6 rows of dosing data:
 treatment ID dose time exclude         route duration
     Trt 1  1    1    0    <NA> extravascular        0
     Trt 1  2    1    0    <NA> extravascular        0
     Trt 1  3    1    0    <NA> extravascular        0
     Trt 1  4    1    0    <NA> extravascular        0
     Trt 1  5    1    0    <NA> extravascular        0
     Trt 2  1    2    0    <NA> extravascular        0",
                fixed=TRUE,
                info="Generic print.PKNCAdose works")
  expect_output(print(mydose.nogroup),
                regexp="Formula for dosing:
 dose ~ time
Nominal time column is not specified.

Data for dosing:
 treatment ID dose time exclude         route duration
     Trt 1  1    1    0    <NA> extravascular        0",
                fixed=TRUE,
                info="Generic print.PKNCAdose works with no groups")

  expect_output(print(mydose, n=-5),
                regexp="Formula for dosing:
 dose ~ time | treatment + ID
Nominal time column is not specified.

First 5 rows of dosing data:
 treatment ID dose time exclude         route duration
     Trt 1  1    1    0    <NA> extravascular        0
     Trt 1  2    1    0    <NA> extravascular        0
     Trt 1  3    1    0    <NA> extravascular        0
     Trt 1  4    1    0    <NA> extravascular        0
     Trt 1  5    1    0    <NA> extravascular        0",
                fixed=TRUE,
                info="Generic print.PKNCAdose works")

  expect_output(print(mydose, summarize=TRUE),
                regexp="Formula for dosing:
 dose ~ time | treatment + ID
Nominal time column is not specified.

Number unique entries in each group:
 treatment ID
         2  5",
                fixed=TRUE,
                info="Summary print.PKNCAdose works")

  expect_output(
    print(mydose.nogroup, summarize=TRUE),
    regexp="No groups"
  )
})

test_that("PKNCAdose with exclusions", {
  tmp.conc <- generate.conc(nsub=2, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  tmp.dose$excl <- NA_character_
  mydose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, exclude="excl")
  expect_equal(
    mydose,
    structure(
      list(
        data =
          cbind(
            tmp.dose,
            data.frame(
              route = "extravascular",
              duration = 0
            )
          ),
        formula = dose~time|treatment+ID,
        columns =
          list(
            dose = "dose",
            time = "time",
            groups =
              list(
                group_vars = c("treatment", "ID"),
                group_analyte = character()
              ),
            exclude = "excl",
            route = "route",
            duration = "duration"
          ),
        units = list()
      ),
      class=c("PKNCAdose", "list")
    )
  )
})

test_that("PKNCAdose route and duration", {
  tmp.conc <- generate.conc(nsub=2, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  expect_equal(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID),
               PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, route="extravascular"),
               info="route is assumed as extravascular")
  expect_equal(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID),
               PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0),
               info="duration is assumed as 0")
  expect_equal(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID),
               PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="extravascular"),
               info="route and duration are correctly assumed")
  dose.iv <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="intravascular")
  dose.ev <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="extravascular")
  expect_equal(dose.iv,
               {
                 tmp <- dose.ev
                 tmp$data$route <- "intravascular"
                 tmp
               },
               info="Intravascular route works")
  expect_error(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="foo"),
               regexp="route must have values of either 'extravascular' or 'intravascular'.  Please set to one of those values and retry.",
               info="route must be an accepted value")
  tmp.dose.iv <- tmp.dose
  tmp.dose.iv$route <- "intravascular"
  # Note that the column names are in a different order when specified
  # in the input data.frame or not.
  expect_equal(
    {
      tmp <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID, duration=0, route="intravascular")
      tmp$data <- tmp$data[,sort(names(tmp$data))]
      tmp
    },
    {
      tmp <- PKNCAdose(tmp.dose.iv, formula=dose~time|treatment+ID, duration=0, route="route")
      tmp$data <- tmp$data[,sort(names(tmp$data))]
      tmp
    },
    ignore_attr=TRUE
  )

})

test_that("time.nominal within PKNCAdose", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  tmp.dose$nom_time <- tmp.dose$time
  rownames(tmp.dose) <- NULL
  expect_equal(
    PKNCAdose(tmp.dose, formula=dose~time|treatment+ID,
              time.nominal="nom_time"),
    structure(list(
      data=
        cbind(
          tmp.dose,
          data.frame(
            exclude=NA_character_,
            route="extravascular",
            duration=0
          )
        ),
      formula = dose ~ time | treatment + ID,
      columns =
        list(
          dose = "dose",
          time = "time",
          groups = list(group_vars = c("treatment", "ID"), group_analyte = character()),
          exclude = "exclude",
          route = "route",
          duration = "duration",
          time.nominal = "nom_time"
        ),
      units = list()
    ),
    class = c("PKNCAdose", "list")),
    info="PKNCAdose accepts time.nominal"
  )
  expect_error(PKNCAdose(tmp.dose, formula=dose~time|treatment+ID,
                         time.nominal="foo"),
               regexp="time.nominal, if given, must be a column name in the input data",
               info="PKNCAdose time.nominal must be a column in the data")
  # Test printing
  dose_with_nom_time <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID,
                                  time.nominal="nom_time")
  expect_output(print(dose_with_nom_time),
                regexp="Formula for dosing:
 dose ~ time | treatment + ID
Nominal time column is: nom_time

First 6 rows of dosing data:
 treatment ID dose time nom_time exclude         route duration
     Trt 1  1    1    0        0    <NA> extravascular        0
     Trt 1  2    1    0        0    <NA> extravascular        0
     Trt 1  3    1    0        0    <NA> extravascular        0
     Trt 1  4    1    0        0    <NA> extravascular        0
     Trt 1  5    1    0        0    <NA> extravascular        0
     Trt 2  1    2    0        0    <NA> extravascular        0",
                fixed=TRUE,
                info="Generic print.PKNCAdose works")
})

test_that("setDuration", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  tmp.dose$nom_time <- tmp.dose$time
  rownames(tmp.dose) <- NULL
  mydose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  expect_message(
    expect_equal(
      setDuration(mydose),
      mydose,
      info="No changes with no arguments"
    ),
    class = "pknca_message_foundcolumn_duration"
  )
  expect_error(setDuration(mydose, duration="foo", rate="bar"),
               regexp="Both duration and rate cannot be given at the same time",
               fixed=TRUE,
               info="Cannot give both duration and rate")
  expect_message(expect_error(
    setDuration(mydose, duration="foobar"),
    regexp="duration must be numeric without missing (NA) or infinite values, and all values must be >= 0",
    fixed=TRUE,
    info="Cannot give both duration as non-numeric",
    class = "pknca_error_dose_invalid_duration"),
    class = "pknca_message_foundcolumn_duration"
    
  )

  duration_example <- suppressMessages(setDuration(mydose, rate=2))
  expect_true(all(mydose$data$duration == 0))
  expect_equal(
    duration_example$data$duration,
    duration_example$data$dose/2
  )
  expect_equal(duration_example$columns$duration, "duration")
})

test_that("Test uniqueness after excluding rows (#298)", {
  repeated_with_exclusion <-
    data.frame(
      dose = 1,
      time = c(0, 0),
      id = 1,
      exclude = c(NA, "duplicate")
    )
  expect_error(
    PKNCAdose(repeated_with_exclusion, formula=dose~time|id),
    regexp="Rows that are not unique per group and time.*dosing"
  )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion, formula=dose~time|id, exclude = "exclude"),
    class = "PKNCAdose"
  )
  repeated_with_exclusion_firstrow <-
    data.frame(
      dose = 1,
      time = c(0, 0),
      id = 1,
      exclude = c("duplicate", NA)
    )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion_firstrow, formula=dose~time|id, exclude = "exclude"),
    class = "PKNCAdose"
  )

  repeated_with_exclusion_nogroup <-
    data.frame(
      dose = 1,
      time = c(0, 0),
      id = 1,
      exclude = c("duplicate", NA)
    )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion_firstrow, formula=dose~., exclude = "exclude"),
    class = "PKNCAdose"
  )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion_firstrow, formula=dose~.|id, exclude = "exclude"),
    class = "PKNCAdose"
  )
  repeated_with_exclusion_row2 <-
    data.frame(
      dose = 1,
      time = c(0, 0),
      id = 1,
      exclude = c(NA, "duplicate")
    )
  expect_s3_class(
    PKNCAdose(repeated_with_exclusion_row2, formula=dose~.|id, exclude = "exclude"),
    class = "PKNCAdose"
  )
})

test_that("PKNCAdose units (#336)", {
  d <- data.frame(dose = 1, time = 0, doseu_x = "A")

  # No units
  o_dose <- PKNCAdose(data = d, dose~time)
  expect_equal(o_dose$units, list())
  expect_null(o_dose$columns$doseu)

  # Each unit column individually
  o_dose <- PKNCAdose(data = d, dose~time, doseu = "doseu_x")
  expect_equal(o_dose$units, list())
  expect_equal(o_dose$columns$doseu, structure("doseu_x", unit_type = "column"))

  # Each unit as a value, not a column
  o_dose <- PKNCAdose(data = d, dose~time, doseu = "doseu_y")
  expect_equal(o_dose$units, list(doseu = structure("doseu_y", unit_type = "value")))
  expect_null(o_dose$columns$doseu)

  # Preferred units
  expect_error(
    PKNCAdose(data = d, dose~time, doseu_pref = "doseu_z"),
    regexp = "Preferred units may not be set unless original units are set: doseu_pref"
  )
  o_dose <- PKNCAdose(data = d, dose~time, doseu = "doseu_y", doseu_pref = "doseu_z")
  expect_equal(
    o_dose$units,
    list(
      doseu = structure("doseu_y", unit_type = "value"),
      doseu_pref = structure("doseu_z", unit_type = "value")
    )
  )
  expect_null(o_dose$columns$doseu)

  o_dose <- PKNCAdose(data = d, dose~time, doseu = "doseu_x", doseu_pref = "doseu_z")
  expect_equal(o_dose$units, list(doseu_pref = structure("doseu_z", unit_type = "value")))
  expect_equal(
    o_dose$columns$doseu,
    structure("doseu_x", unit_type = "column")
  )
})

test_that("PKNCAdose does not error for excluded, invalid times (#310)", {
  # Missing time points that are excluded are not checked
  tmp.dose <- data.frame(time = c(1, NA), dose = c(1, NA), exclude = c(NA, "foo"))
  expect_no_error(PKNCAdose(tmp.dose, formula = dose~time, exclude = "exclude"))

  # Exclude column can be not defined (NULL)
  tmp.dose <- data.frame(time = c(1, 2), dose = c(1, 2))
  expect_no_error(PKNCAdose(tmp.dose, formula = dose~time, exclude = NULL))
})

test_that("a negative dose amount is an error naming the rows", {
  d_dose <- data.frame(id = 1:8, time = 0, dose = c(1, -1, 2, -2, -3, -4, -5, -6))
  expect_error(
    PKNCAdose(d_dose, dose ~ time | id),
    regexp = "Dose amounts (column 'dose') must not be negative; 6 row(s) of the dose data are: 2, 4, 5, 6, 7, ...",
    fixed = TRUE,
    class = "pknca_error_dose_negative"
  )
  # Exactly five rows are all named, with no "..."
  cnd <-
    expect_error(
      PKNCAdose(data.frame(id = 1:6, time = 0, dose = c(1, -1, -2, -3, -4, -5)), dose ~ time | id),
      class = "pknca_error_dose_negative"
    )
  expect_equal(
    conditionMessage(cnd),
    "Dose amounts (column 'dose') must not be negative; 5 row(s) of the dose data are: 2, 3, 4, 5, 6"
  )
  # One dose per group for every interval (`dose ~ .`)
  expect_error(
    PKNCAdose(data.frame(id = 1:2, dose = c(5, -5)), dose ~ . | id),
    regexp = "Dose amounts (column 'dose') must not be negative; 1 row(s) of the dose data are: 2",
    fixed = TRUE,
    class = "pknca_error_dose_negative"
  )
  # A units column
  expect_error(
    PKNCAdose(data.frame(id = 1, time = 0, dose = units::set_units(-5, "mg")), dose ~ time | id),
    class = "pknca_error_dose_negative"
  )
  # Through PKNCAdata() with a data.frame and formula.dose
  expect_error(
    PKNCAdata(
      data.frame(id = 1, time = 0:2, conc = c(0, 2, 1)), data.frame(id = 1, time = 0, dose = -1),
      formula.conc = conc ~ time | id, formula.dose = dose ~ time | id
    ),
    class = "pknca_error_dose_negative"
  )
})

test_that("an excluded negative dose, a zero dose, and a missing dose are allowed", {
  d_dose <- data.frame(id = 1:2, time = 0, dose = c(1, -1), excl = c(NA, "bad dose"))
  expect_no_error(PKNCAdose(d_dose, dose ~ time | id, exclude = "excl"))
  # No dose amount at all
  expect_no_error(PKNCAdose(data.frame(id = 1, time = 0), ~ time | id))
  # A dose column that is not numeric is not checked here
  expect_no_error(PKNCAdose(data.frame(id = 1:2, time = 0, dose = c("1", "-2")), dose ~ time | id))
  # Zero and missing amounts give what they gave before negative amounts were
  # refused:  a zero dose divides to Inf, and a missing one gives NA
  d_conc <- data.frame(id = 1, time = c(0, 1, 2, 4, 8), conc = c(0, 10, 8, 4, 2))
  intervals <- data.frame(start = 0, end = Inf, cl.last = TRUE, auclast.dn = TRUE, cmax.dn = TRUE, totdose = TRUE)
  for (current in list(list(dose = 0, expected = c(cl.last = 0, auclast.dn = Inf, cmax.dn = Inf, totdose = 0)),
                       list(dose = NA_real_, expected = c(cl.last = NA_real_, auclast.dn = NA_real_, cmax.dn = NA_real_, totdose = NA_real_)))) {
    o_data <-
      PKNCAdata(
        PKNCAconc(d_conc, conc ~ time | id),
        PKNCAdose(data.frame(id = 1, time = 0, dose = current$dose), dose ~ time | id),
        intervals = intervals
      )
    res <- as.data.frame(suppressMessages(pk.nca(o_data)))
    value <- stats::setNames(res$PPORRES, res$PPTESTCD)
    expect_equal(value[names(current$expected)], current$expected, info = as.character(current$dose))
  }
})

test_that("pk.nca refuses a dose made negative after PKNCAdose", {
  o_dose <- PKNCAdose(data.frame(id = 1, time = 0, dose = 1), dose ~ time | id)
  o_data <-
    PKNCAdata(
      PKNCAconc(data.frame(id = 1, time = 0:2, conc = c(0, 2, 1)), conc ~ time | id),
      dplyr::mutate(o_dose, dose = -dose),
      intervals = data.frame(start = 0, end = Inf, cmax.dn = TRUE)
    )
  expect_error(
    pk.nca(o_data),
    regexp = "Dose amounts (column 'dose') must not be negative; 1 row(s) of the dose data are: 1",
    fixed = TRUE,
    class = "pknca_error_dose_negative"
  )
})

# The durations of the doses, from PKNCAdose(rate = ) on `d_dose`
rate_durations <- function(d_dose, formula = dose ~ time | id, rate = "rate") {
  o_dose <- PKNCAdose(d_dose, formula, route = "intravascular", rate = rate)
  as.data.frame(o_dose)[[o_dose$columns$duration]]
}

test_that("a rate column gives each dose its own duration, with any number of rows", {
  expect_equal(rate_durations(data.frame(id = 1, time = 0, dose = 10, rate = 5)), 2)
  expect_equal(rate_durations(data.frame(id = 1:2, time = 0, dose = c(10, 20), rate = c(5, 4))), c(2, 5))
  expect_equal(rate_durations(data.frame(id = 1:3, time = 0, dose = c(10, 20, 30), rate = c(5, 4, 3))), c(2, 5, 10))
  # One rate for every dose
  expect_equal(rate_durations(data.frame(id = 1:2, time = 0, dose = c(10, 20)), rate = 2), c(5, 10))
  # A missing rate, a rate of zero, or a missing dose amount gives no valid
  # duration
  for (d_dose in list(
    data.frame(id = 1:2, time = 0, dose = c(10, 20), rate = c(5, NA)),
    data.frame(id = 1:2, time = 0, dose = c(10, 20), rate = c(5, 0)),
    data.frame(id = 1:2, time = 0, dose = c(10, NA), rate = c(5, 4))
  )) {
    expect_error(rate_durations(d_dose), class = "pknca_error_dose_invalid_duration")
  }
  # Without a dose amount, a rate cannot give a duration
  for (n in 1:2) {
    expect_error(
      rate_durations(data.frame(id = seq_len(n), time = 0, rate = 5), formula = ~ time | id),
      regexp = "`rate` needs the dose amount",
      class = "pknca_error_rate_without_dose"
    )
  }
})
