test_that("PKNCAdata", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.conc.analyte <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                    nanalytes=2)
  tmp.conc.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                  nstudies=2)
  tmp.conc.analyte.study <- generate.conc(nsub=5, ntreat=2, time.points=0:24,
                                          nanalytes=2, nstudies=2)
  tmp.dose <- generate.dose(tmp.conc)
  tmp.dose.analyte <- generate.dose(tmp.conc.analyte)
  tmp.dose.study <- generate.dose(tmp.conc.study)
  tmp.dose.analyte.study <- generate.dose(tmp.conc.analyte.study)
  obj.conc <-
    PKNCAconc(tmp.conc, formula=conc~time|treatment+ID)
  obj.conc.analyte <-
    PKNCAconc(tmp.conc.analyte,
              formula=conc~time|treatment+ID/analyte)
  obj.conc.study <-
    PKNCAconc(tmp.conc.study,
              formula=conc~time|study+treatment+ID)
  obj.conc.analyte.study <-
    PKNCAconc(tmp.conc.analyte.study,
              formula=conc~time|study+treatment+ID/analyte)

  obj.dose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  obj.dose.analyte <- PKNCAdose(tmp.dose.analyte, formula=dose~time|treatment+ID)
  obj.dose.study <- PKNCAdose(tmp.dose.study, formula=dose~time|study+treatment+ID)
  obj.dose.analyte.study <- PKNCAdose(tmp.dose.analyte.study, formula=dose~time|study+treatment+ID)

  expect_equal(PKNCAdata(obj.conc, obj.dose),
               PKNCAdata(obj.dose, obj.conc),
               info="Input arguments are reversible")
  expect_equal(PKNCAdata(obj.conc.analyte, obj.dose),
               PKNCAdata(obj.dose, obj.conc.analyte),
               info="Combination of dose and analyte works")
  expect_equal(PKNCAdata(data.conc=tmp.conc, formula.conc=conc~time|treatment+ID,
                         data.dose=tmp.dose, formula.dose=dose~time|treatment+ID),
               PKNCAdata(obj.conc, obj.dose),
               info="Concentration and dose data can be created on the fly")

  # Input checking
  expect_error(
    PKNCAdata(obj.conc, obj.dose, options="a"),
    regexp="Must be of type 'list'"
  )
  expect_error(
    PKNCAdata(obj.conc, obj.dose, options=list(1)),
    regexp="Must have names"
  )
  expect_error(PKNCAdata(obj.conc, obj.dose, options=list(foo=1)),
               regexp="Invalid setting for PKNCA.*foo",
               info="Option names")

  # Single dose intervals are appropriately selected.  They come from
  # pknca_interval_table() rather than the single.dose.aucs option now, so a
  # single dose gives one interval to infinity.
  expect_equal(
    PKNCAdata(obj.conc, obj.dose),
    {
      tmp.intervals <-
        tibble::as_tibble(merge(pknca_interval_table(0, Inf, dosing="single"), tmp.dose))
      tmp.intervals <- tmp.intervals[order(tmp.intervals$treatment, tmp.intervals$ID),]
      tmp.intervals$time <- NULL
      tmp.intervals$dose <- NULL
      # The group columns come before the impute column in what is generated
      tmp.intervals <-
        tmp.intervals[, c(setdiff(names(tmp.intervals), "impute"), "impute")]
      tmp <- list(
        conc=obj.conc,
        dose=obj.dose,
        options=list(),
        intervals=tmp.intervals,
        impute=NA_character_
      )
      class(tmp) <- c("PKNCAdata", "list")
      tmp
    },
    ignore_attr=FALSE,
    info="Selection of single dose AUCs"
  )

  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  tmp.conc <- tmp.conc[!(tmp.conc$ID %in% 1),]
  obj.conc <-
    PKNCAconc(tmp.conc, formula=conc~time|treatment+ID)
  obj.dose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  expect_warning(expect_warning(
    PKNCAdata(obj.conc, obj.dose),
    class = "pknca_warning_no_intervals_generated"),
    class = "pknca_warning_no_intervals_generated",
    info="No intervals generated due to no concentration data."
  )

  expect_warning(expect_warning(expect_warning(
    PKNCAdata(obj.conc, obj.dose, formula.conc=a~b),
    class = "pknca_warning_dataconc_formulaconc"),
    class = "pknca_warning_no_intervals_generated"),
    class = "pknca_warning_no_intervals_generated"
  )
  expect_warning(expect_warning(expect_warning(
    PKNCAdata(obj.conc, obj.dose, formula.dose=a~b),
    class = "pknca_warning_dataconc_formuladose"),
    class = "pknca_warning_no_intervals_generated"),
    class = "pknca_warning_no_intervals_generated"
  )
})

test_that("PKNCAdata with no or limited dose information", {
  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  obj.conc <-
    PKNCAconc(tmp.conc, formula=conc~time|treatment+ID)

  expect_error(PKNCAdata(obj.conc),
               regexp="If data.dose is not given, intervals must be given",
               info="One of dose and intervals is required (no dose)")
  expect_error(PKNCAdata(obj.conc, data.dose=NA),
               regexp="If data.dose is not given, intervals must be given",
               info="One of dose and intervals is required (NA dose)")
  expect_equal(
    PKNCAdata(obj.conc, intervals=data.frame(start=0, end=24, aucinf.obs=TRUE)),
    {
      tmp <-
        list(
          conc=obj.conc,
          dose=NA,
          options=list(),
          intervals=check.interval.specification(
            data.frame(start=0, end=24, aucinf.obs=TRUE)),
          impute=NA_character_
        )
      class(tmp) <- c("PKNCAdata", "list")
      tmp
    }
  )

  tmp.conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  obj.conc <-
    PKNCAconc(tmp.conc, formula=conc~time|treatment+ID)
  obj.dose <- PKNCAdose(tmp.dose, formula=dose~.|treatment+ID)
  expect_error(PKNCAdata(obj.conc, obj.dose),
               regexp="Dose times were not given, so intervals must be manually specified.",
               info="No dose times requires intervals.")
})

test_that("print.PKNCAdata shows group_ref", {
  tmp.conc <- generate.conc(nsub=2, ntreat=2, time.points=0:24)
  obj.conc <- PKNCAconc(tmp.conc, formula=conc~time|treatment+ID)
  obj.data.ref <-
    PKNCAdata(
      obj.conc,
      intervals = data.frame(start = 0, end = 24, aucinf.obs = TRUE),
      group_ref = data.frame(treatment = "Trt 1")
    )
  expect_output(
    print(obj.data.ref),
    regexp = "With reference profiles for secondary parameters (group_ref): treatment=Trt 1",
    fixed = TRUE
  )
  # Parameter-specific forms print one entry per parameter with only the
  # columns that apply to it
  obj.data.ref.param <-
    PKNCAdata(
      obj.conc,
      intervals = data.frame(start = 0, end = 24, aucinf.obs = TRUE),
      group_ref = data.frame(parameter = "clr.obs", treatment = "Trt 1")
    )
  expect_output(
    print(obj.data.ref.param),
    regexp = "(group_ref): clr.obs: treatment=Trt 1",
    fixed = TRUE
  )
  obj.data.ref.list <-
    PKNCAdata(
      obj.conc,
      intervals = data.frame(start = 0, end = 24, aucinf.obs = TRUE),
      group_ref = list(clr.obs = data.frame(treatment = "Trt 1"))
    )
  expect_output(
    print(obj.data.ref.list),
    regexp = "(group_ref): clr.obs: treatment=Trt 1",
    fixed = TRUE
  )
})

test_that("print.PKNCAdata", {
  tmp.conc <- generate.conc(nsub=2, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  obj.conc <- PKNCAconc(tmp.conc, formula=conc~time|treatment+ID)
  obj.dose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  obj.data.nodose <- PKNCAdata(obj.conc,
                               intervals=data.frame(start=0, end=24, aucinf.obs=TRUE))
  obj.data.nodose.opt <-
    PKNCAdata(obj.conc,
              intervals=data.frame(start=0, end=24, aucinf.obs=TRUE),
              options=list(min.hl.r.squared=0.95))
  obj.data.dose <- PKNCAdata(obj.conc, data.dose=obj.dose)
  obj.data.units <- PKNCAdata(obj.conc,
                               intervals=data.frame(start=0, end=24, aucinf.obs=TRUE))
  obj.data.units$units <- "mg"

  # These were previously matched with unescaped regexp text (an unescaped
  # "|", among other regex metacharacters, in "conc ~ time | treatment + ID"
  # is alternation, not a literal pipe), so the test passed against nearly
  # any output.  print(formula) also emits an "<environment: 0x...>" tag
  # whenever the formula's enclosing environment prints as more than
  # `<environment: R_GlobalEnv>` (as it does when the package is loaded via
  # `devtools::load_all()`/tested via `devtools::test()`, the documented dev
  # workflow for this package -- see R/class-PKNCAconc.R, out of scope for
  # this change), so it is matched with a wildcard rather than pinned to a
  # specific address.
  escape_regex <- function(x) gsub("([.\\|()\\[\\]{}^$*+?])", "\\\\\\1", x, perl = TRUE)
  optional_env_tag <- "(<environment: 0x[0-9a-f]+>\n)?"
  conc_block <- paste0(
    escape_regex("Formula for concentration:\n conc ~ time | treatment + ID\n"),
    optional_env_tag,
    escape_regex(
"Data are dense PK.
With 2 subjects defined in the 'ID' column.
Nominal time column is not specified.

First 6 rows of concentration data:
 treatment ID time      conc exclude
     Trt 1  1    0 0.0000000    <NA>
     Trt 1  1    1 0.7052248    <NA>
     Trt 1  1    2 0.7144320    <NA>
     Trt 1  1    3 0.8596094    <NA>
     Trt 1  1    4 0.9998126    <NA>
     Trt 1  1    5 0.7651474    <NA>
"
    )
  )

  expect_output(
    print.PKNCAdata(obj.data.nodose),
    regexp = paste0(
      conc_block,
      escape_regex(
"No dosing information.

With 1 rows of interval specifications.
No options are set differently than default."
      )
    ),
    info="Generic print.PKNCAdata works with no dosing"
  )
  expect_output(
    print.PKNCAdata(obj.data.dose),
    regexp = paste0(
      conc_block,
      escape_regex(
"Formula for dosing:
 dose ~ time | treatment + ID
Nominal time column is not specified.

Data for dosing:
 treatment ID dose time exclude         route duration
     Trt 1  1    1    0    <NA> extravascular        0
     Trt 1  2    1    0    <NA> extravascular        0
     Trt 2  1    2    0    <NA> extravascular        0
     Trt 2  2    2    0    <NA> extravascular        0

With 4 rows of interval specifications.
No options are set differently than default."
      )
    ),
    info="Generic print.PKNCAdata works with dosing"
  )

  expect_output(
    print.PKNCAdata(obj.data.nodose.opt),
    regexp = paste0(
      conc_block,
      escape_regex(
"No dosing information.

With 1 rows of interval specifications.
Options changed from default are:
$min.hl.r.squared
[1] 0.95"
      )
    ),
    info="Generic print.PKNCAdata works with no dosing and with options changed"
  )
  expect_output(
    print.PKNCAdata(obj.data.units),
    regexp = paste0(
      conc_block,
      escape_regex(
"No dosing information.

With 1 rows of interval specifications.
With units
No options are set differently than default."
      )
    ),
    info="Generic print.PKNCAdata works with units"
  )
})

test_that("summary.PKNCAdata", {
  tmp.conc <- generate.conc(nsub=2, ntreat=2, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  obj.conc <- PKNCAconc(tmp.conc, formula=conc~time|treatment+ID)
  obj.dose <- PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  obj.data.nodose <- PKNCAdata(obj.conc,
                               intervals=data.frame(start=0, end=24, aucinf.obs=TRUE))

  expect_output(summary(obj.data.nodose),
                regexp="Formula for concentration:
 conc ~ time | treatment + ID
With 2 subjects defined in the 'ID' column.
Nominal time column is not specified.

Group summary:
 Group Name Count
  treatment     2
         ID     4

First 6 rows of concentration data:
 treatment ID time      conc exclude
     Trt 1  1    0 0.0000000    <NA>
     Trt 1  1    1 0.7052248    <NA>
     Trt 1  1    2 0.7144320    <NA>
     Trt 1  1    3 0.8596094    <NA>
     Trt 1  1    4 0.9998126    <NA>
     Trt 1  1    5 0.7651474    <NA>
No dosing information.

With 1 rows of interval specifications.
No options are set differently than default.",
                info="Generic summary.PKNCAdata works.")
})

test_that("no intervals auto-determined (Fix GitHub issue #84)", {
  tmp_conc <-
    data.frame(
      Subject=1,
      Treatment=c(1, rep(2, 6)),
      Time=c(0, 1:6),
      Conc=1
    )
  tmp_dose <-
    data.frame(
      Subject=1,
      Treatment=c(1, 2),
      Time=c(0, 1),
      Dose=1
    )

  # Treatment 1 has its only concentration at the time of its dose, so there is
  # nothing after the dose to calculate and it gets no interval at all; it used
  # to be given the single.dose.aucs intervals regardless.  Treatment 2 has a
  # profile after its dose at time 1.
  interval_1 <- pknca_interval_table(1, Inf, dosing="single")
  interval_1 <-
    cbind(
      interval_1[, setdiff(names(interval_1), "impute")],
      data.frame(Treatment=2, Subject=1),
      interval_1[, "impute", drop=FALSE]
    )
  expect_warning(
    two_single_dose_treatments <-
      PKNCAdata(
        PKNCAconc(data=tmp_conc, Conc~Time|Treatment+Subject),
        PKNCAdose(data=tmp_dose, Dose~Time|Treatment+Subject)
      ),
    regexp="No intervals generated"
  )
  expect_equal(
    two_single_dose_treatments$intervals,
    interval_1,
    ignore_attr=TRUE
  )
  # Grouping the doses by subject alone puts both doses in one group, so the
  # last dose gets an interval one tau long and the half-life beyond it.  The
  # boundaries are unchanged; the parameters within them come from
  # pknca_interval_table() now.
  interval_2_ss <- pknca_interval_table(1, 2, dosing="steady_state")
  interval_2 <-
    check.interval.specification(
      dplyr::bind_rows(
        interval_2_ss[, setdiff(names(interval_2_ss), "impute")],
        check.interval.specification(data.frame(start=1, end=Inf, half.life=TRUE))
      )
    )
  interval_2$Treatment <- 2
  interval_2$Subject <- 1
  interval_2$impute <- c(interval_2_ss$impute, NA_character_)
  expect_warning(
    two_multiple_dose_treatments <-
      PKNCAdata(
        PKNCAconc(data=tmp_conc, Conc~Time|Treatment+Subject),
        PKNCAdose(data=tmp_dose, Dose~Time|Subject)
      ),
    regexp="No intervals generated"
  )
  expect_equal(
    two_multiple_dose_treatments$intervals,
    interval_2,
    ignore_attr=TRUE
  )
})

test_that("Ensure that unexpected arguments to PKNCAdata give an error (related to issue #83)", {
  tmp.conc <- generate.conc(nsub=2, ntreat=1, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  obj.conc <-
    PKNCAconc(tmp.conc, formula=conc~time|treatment+ID)
  obj.dose <-
    PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  expect_error(mydata <- PKNCAdata(obj.conc, obj.dose, 1),
               regexp="Unknown argument")
})

test_that("intervals may be a tibble", {
  tmp.conc <- generate.conc(nsub=2, ntreat=1, time.points=0:24)
  tmp.dose <- generate.dose(tmp.conc)
  obj.conc <-
    PKNCAconc(tmp.conc, formula=conc~time|treatment+ID)
  obj.dose <-
    PKNCAdose(tmp.dose, formula=dose~time|treatment+ID)
  intervals <- data.frame(start=0, end=24, aucinf.obs=TRUE)
  mydata_tibble <- PKNCAdata(obj.conc, obj.dose, intervals=dplyr::as_tibble(intervals))
  mydata <- PKNCAdata(obj.conc, obj.dose, intervals=intervals)
  expect_equal(
    as.data.frame(pk.nca(mydata_tibble)),
    as.data.frame(pk.nca(mydata))
  )
})

test_that("PKNCAdata units (#336)", {
  # Typical use
  # More than one concentration, and one of them after the dose, so that an
  # interval can be generated at all; this test is about the units.
  d_conc <-
    data.frame(
      conc = c(1, 2, 1), time = 0:2, concu_x = "A", timeu_x = "B", amountu_x = "C"
    )
  d_dose <- data.frame(dose = 1, time = 0, doseu_x = "D")

  o_conc <- PKNCAconc(data = d_conc, conc~time, concu = "concu_x", timeu = "timeu_x")
  o_dose <- PKNCAdose(data = d_dose, dose~time, doseu = "doseu_x")
  o_data <- PKNCAdata(o_conc, o_dose)
  expect_equal(
    o_data$units,
    pknca_units_table(concu = "A", doseu = "D", timeu = "B")
  )
  suppressWarnings(o_nca <- pk.nca(o_data))
  expect_true("Cmax (A)" %in% names(summary(o_nca)))

  # multiple unit values cause an error
  d_conc <- data.frame(conc = 1, time = 0:1, concu_x = c("A", "C"), timeu_x = "B", amountu_x = "C")
  d_dose <- data.frame(dose = 1, time = 0, doseu_x = "B")

  o_conc <- PKNCAconc(data = d_conc, conc~time, concu = "concu_x")
  o_dose <- PKNCAdose(data = d_dose, dose~time, doseu = "doseu_x")
  expect_error(
    PKNCAdata(o_conc, o_dose),
    regexp = "Units should be uniform at least across concentration groups"
  )
})

test_that("getGroups works", {
  # Check that it works with grouping [contains only the grouping column(s)]
  o_conc_group <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  data_group <- as.data.frame(datasets::Theoph)
  expected_group <- data.frame(Subject = data_group$Subject)
  o_data_group <- PKNCAdata(o_conc_group, intervals = data.frame(start = 0, end = 1, cmax = TRUE))
  expect_equal(getGroups(o_data_group), expected_group)

  # Check that it works without groupings as expected [empty]
  o_conc_nongroup <- PKNCAconc(as.data.frame(datasets::Theoph)[datasets::Theoph$Subject == 1,], conc~Time)
  o_data_nogroup <- PKNCAdata(o_conc_nongroup, intervals = data.frame(start = 0, end = 1, cmax = TRUE))

  # It should be an empty data.frame with 11 rows
  expect_equal(getGroups(o_data_nogroup), data.frame(A = 1:11)[, -1])
})

test_that("PKNCAdata auto-interval generation works with no grouping variables", {
  d <- as.data.frame(datasets::Theoph[datasets::Theoph$Subject == 1, ])
  o_conc <- PKNCAconc(d, conc~Time)
  d_dose <- d[d$Time == 0, , drop = FALSE]
  o_dose <- PKNCAdose(d_dose, Dose~Time)
  o_data <- PKNCAdata(o_conc, o_dose)
  expect_true(nrow(o_data$intervals) > 0)
})

test_that("group_vars.PKNCAdata", {
  o_conc_group <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
  o_data_group <- PKNCAdata(o_conc_group, intervals = data.frame(start = 0, end = 1, cmax = TRUE))

  expect_equal(dplyr::group_vars(o_data_group), "Subject")

  # Check that it works without groupings as expected [empty]
  o_conc_nongroup <- PKNCAconc(as.data.frame(datasets::Theoph)[datasets::Theoph$Subject == 1,], conc~Time)
  o_data_nogroup <- PKNCAdata(o_conc_nongroup, intervals = data.frame(start = 0, end = 1, cmax = TRUE))

  expect_equal(dplyr::group_vars(o_data_nogroup), character(0))
})

test_that("print.PKNCAdata reports imputation only when it is requested", {
  o_conc <- PKNCAconc(data.frame(conc = c(1, 2, 1), time = 0:2, subject = 1), conc~time|subject)
  intervals <- data.frame(start = 0, end = 2, auclast = TRUE)
  # PKNCAdata() stores NA_character_ when no imputation is given
  o_data_none <- PKNCAdata(o_conc, intervals = intervals)
  expect_equal(o_data_none$impute, NA_character_)
  output_none <- capture.output(print(o_data_none))
  expect_false(any(grepl("With imputation", output_none, fixed = TRUE)))
  o_data_impute <- PKNCAdata(o_conc, intervals = intervals, impute = "start_conc0")
  output_impute <- capture.output(print(o_data_impute))
  expect_equal(sum(output_impute == "With imputation: start_conc0"), 1)
})

test_that("The legacy single-dose intervals warn for a time unit other than hours", {
  d_conc <- data.frame(subject = 1, time = c(0, 30, 60, 120), conc = c(0, 2, 1, 0.5))
  d_dose <- data.frame(subject = 1, time = 0, dose = 1)
  o_dose <- PKNCAdose(d_dose, dose~time|subject)
  o_conc_min <- PKNCAconc(d_conc, conc~time|subject, timeu = "min")
  # The 24 in the single.dose.aucs table is only used by the legacy method; the
  # intervals generated otherwise run from the dose to infinity, so there is no
  # 24 to be in the wrong unit and nothing to warn about.
  legacy <- list(auto.interval.method = "legacy")
  expect_warning(
    o_data_min <- PKNCAdata(o_conc_min, o_dose, options = legacy),
    regexp = "the time unit is 'min', so they end at 24 min",
    class = "pknca_warning_single_dose_aucs_unit"
  )
  # The table is not changed
  expect_equal(o_data_min$intervals$end, c(24, Inf))
  # The builder does not assume hours, so it does not warn, and its interval
  # carries no 24
  expect_no_warning(o_data_builder <- PKNCAdata(o_conc_min, o_dose))
  expect_equal(o_data_builder$intervals$end, Inf)
  # No warning for hours, an unknown unit, no unit, manual intervals, a
  # non-default single.dose.aucs, or multiple doses
  expect_no_warning(
    PKNCAdata(PKNCAconc(d_conc, conc~time|subject, timeu = "hr"), o_dose, options = legacy)
  )
  expect_no_warning(
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|subject, timeu = "not_a_unit"), o_dose, options = legacy
    )
  )
  expect_no_warning(
    PKNCAdata(PKNCAconc(d_conc, conc~time|subject), o_dose, options = legacy)
  )
  expect_no_warning(
    PKNCAdata(
      o_conc_min, o_dose, intervals = data.frame(start = 0, end = 120, cmax = TRUE),
      options = legacy
    )
  )
  expect_no_warning(
    PKNCAdata(
      o_conc_min, o_dose,
      options =
        list(
          auto.interval.method = "legacy",
          single.dose.aucs = data.frame(start = 0, end = 120, auclast = TRUE)
        )
    )
  )
  o_dose_multi <- PKNCAdose(data.frame(subject = 1, time = c(0, 60), dose = 1), dose~time|subject)
  expect_no_warning(PKNCAdata(o_conc_min, o_dose_multi, options = legacy))
  # A time unit given as a column is checked, too
  d_conc$timeu_col <- "day"
  expect_warning(
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|subject, timeu = "timeu_col"), o_dose, options = legacy
    ),
    regexp = "'day'",
    class = "pknca_warning_single_dose_aucs_unit"
  )
})

test_that("pknca_hours_factor converts time units with the units package", {
  # "hr" needs no conversion (and no units package)
  expect_equal(pknca_hours_factor("hr"), 1)
  skip_if_not_installed("units")
  expect_equal(pknca_hours_factor("min"), 1/60)
  expect_equal(pknca_hours_factor("day"), 24)
  expect_equal(pknca_hours_factor("not_a_unit"), NA_real_)
})
