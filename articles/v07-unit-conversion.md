# Unit Assignment and Conversion with PKNCA

``` r

suppressPackageStartupMessages(
  library(PKNCA)
)
```

## Introduction

PKNCA can assign and convert units for reporting. There are two ways to
provide units to PKNCA: via the `units` argument to
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
or by specifying units with
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
and/or
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md).
If you provide the units argument to
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md),
units given to
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
or
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
are ignored.

## Examples of each way to add units

### Steps to add units to an NCA analysis from the data

For more details on parts of this NCA calculation example unrelated to
units, see the [theophylline example
vignette](https://humanpred.github.io/pknca/articles/v02-example-theophylline.md).

Provide the units for concentration (`concu`), time (`timeu`), and
amount (`amountu`) to the
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
function and for dose (`doseu`) to the
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
function.

``` r

d_conc <- as.data.frame(datasets::Theoph)
d_conc$concu_col <- "mg/L"
d_conc$timeu_col <- "hr"
d_dose <- datasets::Theoph[datasets::Theoph$Time == 0, c("Dose", "Time", "Subject")]
d_dose$doseu_col <- "mg/kg"
o_conc <- PKNCAconc(d_conc, conc~Time|Subject, concu = "concu_col", timeu = "timeu_col")
o_dose <- PKNCAdose(d_dose, Dose~Time|Subject, doseu = "doseu_col")
```

Then, create the data object the same way as typical. Results will have
units.

``` r

o_data <- PKNCAdata(o_conc, o_dose)
o_nca <- pk.nca(o_data)
summary(o_nca)
#>  Interval Start Interval End  N AUClast (hr*mg/L) Cmax (mg/L)
#>               0          Inf 12       98.7 [22.5] 8.65 [17.0]
#>           Tmax (hr)            Tlag (hr) Concentration count (count)
#>  1.14 [0.630, 3.55] 0.000 [0.000, 0.000]           11.0 [11.0, 11.0]
#>  Half-life (hr) AUCinf,obs (hr*mg/L) AUCpext (based on AUCinf,obs) (%)
#>     8.18 [2.12]           115 [28.4]                       13.8 [6.34]
#>  CL (based on AUCinf,obs) ((mg/kg)/(hr*mg/L))
#>                                 0.0398 [29.4]
#> 
#> Caption: AUClast, Cmax, AUCinf,obs, CL (based on AUCinf,obs): geometric mean and geometric coefficient of variation; Tmax, Tlag, Concentration count: median and range; Half-life, AUCpext (based on AUCinf,obs): arithmetic mean and standard deviation; N: number of subjects
```

When units are provided through
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
and
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
like this,
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
builds the units table automatically during construction by calling
[`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md)
on the `PKNCAdata` object. You can also call
[`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md)
on a `PKNCAdata` object yourself to build or inspect that units table
directly.

It is also possible to specify the units without them coming from
columns in the data.

``` r

d_conc <- as.data.frame(datasets::Theoph)
d_dose <- datasets::Theoph[datasets::Theoph$Time == 0, c("Dose", "Time", "Subject")]
o_conc <- PKNCAconc(d_conc, conc~Time|Subject, concu = "mg/L", timeu = "hr")
o_dose <- PKNCAdose(d_dose, Dose~Time|Subject, doseu = "mg/kg")
o_data <- PKNCAdata(o_conc, o_dose)
o_nca <- pk.nca(o_data)
summary(o_nca)
#>  Interval Start Interval End  N AUClast (hr*mg/L) Cmax (mg/L)
#>               0          Inf 12       98.7 [22.5] 8.65 [17.0]
#>           Tmax (hr)            Tlag (hr) Concentration count (count)
#>  1.14 [0.630, 3.55] 0.000 [0.000, 0.000]           11.0 [11.0, 11.0]
#>  Half-life (hr) AUCinf,obs (hr*mg/L) AUCpext (based on AUCinf,obs) (%)
#>     8.18 [2.12]           115 [28.4]                       13.8 [6.34]
#>  CL (based on AUCinf,obs) ((mg/kg)/(hr*mg/L))
#>                                 0.0398 [29.4]
#> 
#> Caption: AUClast, Cmax, AUCinf,obs, CL (based on AUCinf,obs): geometric mean and geometric coefficient of variation; Tmax, Tlag, Concentration count: median and range; Half-life, AUCpext (based on AUCinf,obs): arithmetic mean and standard deviation; N: number of subjects
```

And, you can perform automatic unit conversions as long as the unit
conversions are defined without more information (e.g. convert between
mass or time units). For more complex conversions, see the information
below.

``` r

d_conc <- as.data.frame(datasets::Theoph)
d_dose <- datasets::Theoph[datasets::Theoph$Time == 0, c("Dose", "Time", "Subject")]
o_conc <- PKNCAconc(d_conc, conc~Time|Subject, concu = "mg/L", timeu = "hr", concu_pref = "ug/L", timeu_pref = "day")
o_dose <- PKNCAdose(d_dose, Dose~Time|Subject, doseu = "mg/kg")
o_data <- PKNCAdata(o_conc, o_dose)
o_nca <- pk.nca(o_data)
summary(o_nca)
#>  Interval Start Interval End  N AUClast (day*ug/L) Cmax (ug/L)
#>               0          Inf 12        4110 [22.5] 8650 [17.0]
#>              Tmax (day)           Tlag (day) Concentration count (count)
#>  0.0473 [0.0262, 0.148] 0.000 [0.000, 0.000]           11.0 [11.0, 11.0]
#>  Half-life (day) AUCinf,obs (day*ug/L) AUCpext (based on AUCinf,obs) (%)
#>   0.341 [0.0881]           4780 [28.4]                       13.8 [6.34]
#>  CL (based on AUCinf,obs) ((mg/kg)/(day*ug/L))
#>                                0.000955 [29.4]
#> 
#> Caption: AUClast, Cmax, AUCinf,obs, CL (based on AUCinf,obs): geometric mean and geometric coefficient of variation; Tmax, Tlag, Concentration count: median and range; Half-life, AUCpext (based on AUCinf,obs): arithmetic mean and standard deviation; N: number of subjects
```

### Steps to manually add units to an NCA analysis

For more details on parts of this NCA calculation example unrelated to
units, see the [theophylline example
vignette](https://humanpred.github.io/pknca/articles/v02-example-theophylline.md).

``` r

o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
d_dose <- datasets::Theoph[datasets::Theoph$Time == 0, c("Dose", "Time", "Subject")]
o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
```

The difference from a calculation without units comes when setting up
the `PKNCAdata` object. You will add the units with the `units`
argument.

Since no urine or other similar collection is performed, the `amountu`
argument is omitted for
[`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md).

``` r

d_units <-
  pknca_units_table(
    concu="mg/L", doseu="mg/kg", timeu="hr",
    # use molar units for concentrations and AUCs
    conversions=
      data.frame(
        PPORRESU=c("(mg/kg)/(hr*mg/L)", "(mg/kg)/(mg/L)", "mg/L", "hr*mg/L"),
        PPSTRESU=c("L/hr/kg", "L/kg", "mmol/L", "hr*mmol/L"),
        conversion_factor=c(NA, NA, 1/180.164, 1/180.164)
      )
  )

o_data <- PKNCAdata(o_conc, o_dose, units=d_units)
o_nca <- pk.nca(o_data)
summary(o_nca)
#>  Interval Start Interval End  N AUClast (hr*mmol/L) Cmax (mmol/L)
#>               0          Inf 12        0.548 [22.5] 0.0480 [17.0]
#>           Tmax (hr)            Tlag (hr) Concentration count (count)
#>  1.14 [0.630, 3.55] 0.000 [0.000, 0.000]           11.0 [11.0, 11.0]
#>  Half-life (hr) AUCinf,obs (hr*mmol/L) AUCpext (based on AUCinf,obs) (%)
#>     8.18 [2.12]           0.637 [28.4]                       13.8 [6.34]
#>  CL (based on AUCinf,obs) (L/hr/kg)
#>                       0.0398 [29.4]
#> 
#> Caption: AUClast, Cmax, AUCinf,obs, CL (based on AUCinf,obs): geometric mean and geometric coefficient of variation; Tmax, Tlag, Concentration count: median and range; Half-life, AUCpext (based on AUCinf,obs): arithmetic mean and standard deviation; N: number of subjects
```

## Prepare a Unit Assignment and Conversion Table

A unit assignment and conversion table can be generated as a data.frame
to use with the
[`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md)
function or manually.

The simplest method takes each of the types of units for inputs and
automatically generates the units for each NCA parameter.

``` r

d_units_auto <- pknca_units_table(concu="ng/mL", doseu="mg", amountu="mg", timeu="hr")
# Show a selection of the units generated
d_units_auto[d_units_auto$PPTESTCD %in% c("cmax", "tmax", "auclast", "cl.obs", "vd.obs"), ]
#>          PPORRESU PPTESTCD
#> 41             hr     tmax
#> 94          ng/mL     cmax
#> 150      hr*ng/mL  auclast
#> 206 mg/(hr*ng/mL)   cl.obs
```

As you see above, the default units table has a column for the
`PPTESTCD` indicating the parameter. And, the column `PPORRESU`
indicates what the default units are.

Without unit conversion, the units for some parameters (notably
clearances and volumes) are not so useful. You can add a conversion
table to make any units into the desired units. For automatic conversion
to work, the units must always be convertible (by the `units` library).
Notably for automatic conversion, you cannot go from mass to molar units
since there is not a unique conversion from mass to moles.

Loading the PKNCA package adds a unit of `"fraction"` so that it is
usable for fraction excreted (`fe`).

``` r

d_units_clean <-
  pknca_units_table(
    concu="ng/mL", doseu="mg", amountu="ng", timeu="hr",
    conversions=
      data.frame(
        PPORRESU=c("mg/(hr*ng/mL)", "mg/(ng/mL)", "hr", "ng/mg"),
        PPSTRESU=c("L/hr", "L", "day", "fraction")
      )
  )
# Show a selection of the units generated
d_units_clean[d_units_clean$PPTESTCD %in% c("cmax", "tmax", "auclast", "cl.obs", "vd.obs", "fe"), ]
#>          PPORRESU PPTESTCD PPSTRESU conversion_factor
#> 41             hr     tmax      day      4.166667e-02
#> 94          ng/mL     cmax    ng/mL      1.000000e+00
#> 107         ng/mg       fe fraction      1.000000e-06
#> 150      hr*ng/mL  auclast hr*ng/mL      1.000000e+00
#> 206 mg/(hr*ng/mL)   cl.obs     L/hr      1.000000e+03
```

Now, the units are much cleaner to look at.

To do a conversion that is not possible directly with the `units`
library, you can add the conversion factor manually by adding the
`conversion_factor` column. You can mix-and-match manual and automatic
modification by setting the `conversion_factor` column to `NA` when you
want automatic conversion. In the example below, we convert
concentration units to molar. Note that AUC units are not set to molar
because we did not specify that conversion; all conversions must be
specified.

``` r

d_units_clean_manual <-
  pknca_units_table(
    concu="ng/mL", doseu="mg", amountu="mg", timeu="hr",
    conversions=
      data.frame(
        PPORRESU=c("mg/(hr*ng/mL)", "mg/(ng/mL)", "hr", "ng/mL"),
        PPSTRESU=c("L/hr", "L", "day", "nmol/L"),
        conversion_factor=c(NA, NA, NA, 1000/123)
      )
  )
# Show a selection of the units generated
d_units_clean_manual[d_units_clean_manual$PPTESTCD %in% c("cmax", "tmax", "auclast", "cl.obs", "vd.obs"), ]
#>          PPORRESU PPTESTCD PPSTRESU conversion_factor
#> 41             hr     tmax      day      4.166667e-02
#> 94          ng/mL     cmax   nmol/L      8.130081e+00
#> 150      hr*ng/mL  auclast hr*ng/mL      1.000000e+00
#> 206 mg/(hr*ng/mL)   cl.obs     L/hr      1.000000e+03
```

## What happens when units are missing for some parameters?

A hand-made or hand-edited units table may not have a row for every
parameter that an analysis requests. By default,
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
raises an error when units are provided for some but not all requested
parameters so that results are not unintentionally reported without
units. Setting the `allow_partial_missing_units` option to `TRUE`
converts that error to a warning naming the parameters without units,
and those parameters are reported without units. The option can be set
for a single analysis with the `options` argument to
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
(as below) or globally with
`PKNCA.options(allow_partial_missing_units = TRUE)`.

``` r

o_conc <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
d_dose <- datasets::Theoph[datasets::Theoph$Time == 0, c("Dose", "Time", "Subject")]
o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
d_units_full <- pknca_units_table(concu="mg/L", doseu="mg/kg", timeu="hr")
# Drop the tmax row to simulate an incomplete units table
d_units_partial <- d_units_full[!d_units_full$PPTESTCD %in% "tmax", ]
o_data_partial <-
  PKNCAdata(
    o_conc, o_dose,
    units=d_units_partial,
    options=list(allow_partial_missing_units=TRUE)
  )
o_nca_partial <- pk.nca(o_data_partial)
#> Warning: Units are provided for some but not all parameters; missing for: tmax
summary(o_nca_partial)
#>  Interval Start Interval End  N AUClast (hr*mg/L) Cmax (mg/L)
#>               0          Inf 12       98.7 [22.5] 8.65 [17.0]
#>                Tmax            Tlag (hr) Concentration count (count)
#>  1.14 [0.630, 3.55] 0.000 [0.000, 0.000]           11.0 [11.0, 11.0]
#>  Half-life (hr) AUCinf,obs (hr*mg/L) AUCpext (based on AUCinf,obs) (%)
#>     8.18 [2.12]           115 [28.4]                       13.8 [6.34]
#>  CL (based on AUCinf,obs) ((mg/kg)/(hr*mg/L))
#>                                 0.0398 [29.4]
#> 
#> Caption: AUClast, Cmax, AUCinf,obs, CL (based on AUCinf,obs): geometric mean and geometric coefficient of variation; Tmax, Tlag, Concentration count: median and range; Half-life, AUCpext (based on AUCinf,obs): arithmetic mean and standard deviation; N: number of subjects
```

## How do I add different unit conversions for different analytes?

Sometimes, when multiple analytes are used and, for example, molar
outputs are desired while inputs are in mass units. Different unit
conversions may be required for different inputs.

Different unit conversions can be used by adding the grouping column to
the units specification.

Start by setting up a concentration dataset with two analytes. Since the
dosing doesn’t have an “Analyte” column, it will be matched to all
concentration measures for the subject.

``` r

d_conc_theoph <- as.data.frame(datasets::Theoph)
d_conc_theoph$Analyte <- "Theophylline"
# Approximately 6% of theophylline is metabolized to caffeine
# (https://www.pharmgkb.org/pathway/PA165958541).  Let's pretend that means it
# has 6% of the theophylline concentration at all times.
d_conc_caffeine <- as.data.frame(datasets::Theoph)
d_conc_caffeine$conc <- 0.06*d_conc_caffeine$conc
d_conc_caffeine$Analyte <- "Caffeine"
d_conc <- rbind(d_conc_theoph, d_conc_caffeine)

d_dose <- unique(datasets::Theoph[datasets::Theoph$Time == 0,
                                  c("Dose", "Time", "Subject")])
```

Setup the units with an “Analyte” column to separate the units used.

``` r

d_units_theoph <-
  pknca_units_table(
    concu="mg/L", doseu="mg/kg", timeu="hr",
    # use molar units for concentrations and AUCs
    conversions=
      data.frame(
        PPORRESU=c("(mg/kg)/(hr*mg/L)", "(mg/kg)/(mg/L)", "mg/L", "hr*mg/L"),
        PPSTRESU=c("L/hr/kg", "L/kg", "mmol/L", "hr*mmol/L"),
        conversion_factor=c(NA, NA, 1/180.164, 1/180.164)
      )
  )
d_units_theoph$Analyte <- "Theophylline"
d_units_caffeine <-
  pknca_units_table(
    concu="mg/L", doseu="mg/kg", timeu="hr",
    # use molar units for concentrations and AUCs
    conversions=
      data.frame(
        PPORRESU=c("(mg/kg)/(hr*mg/L)", "(mg/kg)/(mg/L)", "mg/L", "hr*mg/L"),
        PPSTRESU=c("L/hr/kg", "L/kg", "mmol/L", "hr*mmol/L"),
        conversion_factor=c(NA, NA, 1/194.19, 1/194.19)
      )
  )
d_units_caffeine$Analyte <- "Caffeine"
d_units <- rbind(d_units_theoph, d_units_caffeine)
```

Now, calculate adding the different units per analyte to the data
object.

``` r

o_conc <- PKNCAconc(d_conc, conc~Time|Subject/Analyte)
o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
o_data <- PKNCAdata(o_conc, o_dose, units=d_units)
o_nca <- pk.nca(o_data)
summary(o_nca)
#>  Interval Start Interval End      Analyte  N AUClast (hr*mmol/L)  Cmax (mmol/L)
#>               0          Inf Theophylline 12        0.548 [22.5]  0.0480 [17.0]
#>               0          Inf     Caffeine 12       0.0305 [22.5] 0.00267 [17.0]
#>           Tmax (hr)            Tlag (hr) Concentration count (count)
#>  1.14 [0.630, 3.55] 0.000 [0.000, 0.000]           11.0 [11.0, 11.0]
#>  1.14 [0.630, 3.55] 0.000 [0.000, 0.000]           11.0 [11.0, 11.0]
#>  Half-life (hr) AUCinf,obs (hr*mmol/L) AUCpext (based on AUCinf,obs) (%)
#>     8.18 [2.12]           0.637 [28.4]                       13.8 [6.34]
#>     8.18 [2.12]          0.0355 [28.4]                       13.8 [6.34]
#>  CL (based on AUCinf,obs) (L/hr/kg)
#>                       0.0398 [29.4]
#>                        0.663 [29.4]
#> 
#> Caption: AUClast, Cmax, AUCinf,obs, CL (based on AUCinf,obs): geometric mean and geometric coefficient of variation; Tmax, Tlag, Concentration count: median and range; Half-life, AUCpext (based on AUCinf,obs): arithmetic mean and standard deviation; N: number of subjects
```

## Date and time (POSIXct) input

Concentration and dose times may be given as date-times (POSIXct)
instead of numbers, as they often are in clinical data (for example, the
SDTM `--DTC` variables after parsing). Date-times are converted directly
to the time unit for calculations and reporting: `timeu_pref` when given
(it takes precedence over `timeu`), otherwise `timeu`, otherwise hours.
Numeric durations are in that unit, and durations given as difftime are
converted to it.
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
checks the times and keeps them, and
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
converts them to numbers relative to the first dose in each group: the
groups are the grouping variables shared by the concentration and dose
formulas, so with `Subject` as the group, time 0 is each subject’s first
dose. For studies with several parts (or crossover periods), add the
part (or period) to both formulas, and each subject’s first dose in each
part is time 0.

``` r

d_conc <- as.data.frame(datasets::Theoph)
d_dose <- datasets::Theoph[datasets::Theoph$Time == 0, c("Dose", "Time", "Subject")]
# Each subject was dosed at 08:00 on a different day
first_dose <- as.POSIXct("2024-01-15 08:00", tz = "UTC") + (as.numeric(as.character(d_dose$Subject)) - 1) * 86400
names(first_dose) <- as.character(d_dose$Subject)
d_conc$datetime <- first_dose[as.character(d_conc$Subject)] + d_conc$Time * 3600
d_dose$datetime <- first_dose[as.character(d_dose$Subject)]
o_conc <- PKNCAconc(d_conc, conc~datetime|Subject, concu = "mg/L", timeu_pref = "hr")
o_dose <- PKNCAdose(d_dose, Dose~datetime|Subject, doseu = "mg/kg")
o_data <- PKNCAdata(o_conc, o_dose)
o_nca <- pk.nca(o_data)
# The results keep the converted data, with the time reference for each subject
head(o_nca$data$time_reference)
#>   Subject      time_reference time_reference_type
#> 1       6 2024-01-20 08:00:00          first_dose
#> 2       7 2024-01-21 08:00:00          first_dose
#> 3       8 2024-01-22 08:00:00          first_dose
#> 4      11 2024-01-25 08:00:00          first_dose
#> 5       3 2024-01-17 08:00:00          first_dose
#> 6       2 2024-01-16 08:00:00          first_dose
# The concentration times the calculation used are hours after the first dose
head(o_nca$data$conc$data[, c("Subject", "datetime", "conc")])
#>   Subject datetime  conc
#> 1       1     0.00  0.74
#> 2       1     0.25  2.84
#> 3       1     0.57  6.57
#> 4       1     1.12 10.50
#> 5       1     2.02  9.66
#> 6       1     3.82  8.58
```

Automatic intervals are chosen as for numeric times. Manually specified
intervals may be numeric times relative to the time reference, in the
preferred time unit, or date-times. A date-time window is converted
relative to the reference of each group it applies to, so a window
without a `Subject` column becomes one row per subject, each with that
subject’s relative start and end, and the converted intervals are marked
with `interval_time_kind = "datetime"`. An `end` of `Inf` stays
infinite. The conversion supplies the window, not concentrations at its
edges: a window that starts before a subject’s first measurement still
needs an imputation rule (the `impute` argument) to give a concentration
at its start.

``` r

# 12:00 to 20:00 on each subject's dosing day, one row per subject
intervals_dt <-
  data.frame(
    Subject = d_dose$Subject,
    start = first_dose[as.character(d_dose$Subject)] + 4 * 3600,
    end = first_dose[as.character(d_dose$Subject)] + 12 * 3600,
    aucint.last = TRUE
  )
o_data_dt <- PKNCAdata(o_conc, o_dose, intervals = intervals_dt)
o_nca_dt <- pk.nca(o_data_dt)
# The intervals the calculation used, relative to each subject's first dose
head(o_nca_dt$data$intervals[, c("Subject", "start", "end", "interval_time_kind")], 3)
#>   Subject start end interval_time_kind
#> 1       1     4  12           datetime
#> 2       2     4  12           datetime
#> 3       3     4  12           datetime
head(as.data.frame(o_nca_dt)[, c("Subject", "start", "end", "PPTESTCD", "PPORRES")], 3)
#> # A tibble: 3 × 5
#>   Subject start   end PPTESTCD    PPORRES
#>   <ord>   <dbl> <dbl> <chr>         <dbl>
#> 1 1           4    12 aucint.last    58.0
#> 2 2           4    12 aucint.last    38.9
#> 3 3           4    12 aucint.last    41.3
```

The default single-dose intervals (the `single.dose.aucs` option, 0 to
24 and 0 to infinity) are written for hours, so with a preferred time
unit such as `"day"` or `"min"` they would end at 24 days or 24 minutes;
PKNCA warns when that happens, and you should give `intervals` or set
`single.dose.aucs` for that unit. Results formatted for CDISC give each
row its time point reference: PPTPTREF names it (the dose that starts
the interval), PPRFTDTC is its date-time, and PPSTINT and PPENINT are
the interval start and end relative to it, in the preferred time unit.

``` r

o_nca <- pk.nca(o_data)
d_cdisc <- as.data.frame(o_nca, out_format = "cdisc")
head(d_cdisc[, c("Subject", "PPTESTCD", "PPORRES", "PPORRESU", "PPSTINT", "PPENINT", "PPTPTREF", "PPRFTDTC")])
#>   Subject PPTESTCD  PPORRES PPORRESU PPSTINT PPENINT
#> 1       1   AUCLST 147.2347  hr*mg/L    PT0H    <NA>
#> 2       1     CMAX  10.5000     mg/L    PT0H    <NA>
#> 3       1     TMAX   1.1200       hr    PT0H    <NA>
#> 4       1     TLST  24.3700       hr    PT0H    <NA>
#> 5       1     CLST   3.2800     mg/L    PT0H    <NA>
#> 6       1     TLAG   0.0000       hr    PT0H    <NA>
#>                      PPTPTREF            PPRFTDTC
#> 1 LAST DOSE PRIOR TO INTERVAL 2024-01-15T08:00:00
#> 2 LAST DOSE PRIOR TO INTERVAL 2024-01-15T08:00:00
#> 3 LAST DOSE PRIOR TO INTERVAL 2024-01-15T08:00:00
#> 4 LAST DOSE PRIOR TO INTERVAL 2024-01-15T08:00:00
#> 5 LAST DOSE PRIOR TO INTERVAL 2024-01-15T08:00:00
#> 6 LAST DOSE PRIOR TO INTERVAL 2024-01-15T08:00:00
```

A few rules keep the conversion unambiguous:

- Concentration and dose times must both be date-times; mixing numeric
  and date-time times is an error.
- All date-times must have the same time zone. Differences are elapsed
  time, so a daylight saving time change within a named time zone (like
  `"America/New_York"`) is handled correctly.
- Dates (Date) are taken as 08:00 on that date (a typical time of a
  first PK sample), with a warning.
- The dose formula must include the subject (as with `Subject` above),
  so that each subject has its own reference. Sparse data are the
  exception: every subject in a sparse group shares the group’s dosing,
  so the reference is per group.
- Excluded doses are not used as the time reference. A subject without
  an included dose time uses its first (not excluded) concentration
  instead, with a warning, and without dosing data every subject uses
  its first concentration. The `time_reference_type` column of
  `time_reference` says which kind of reference each group has
  (`"first_dose"` or `"first_conc"`).
- Nominal times (`time.nominal`) are not converted.
