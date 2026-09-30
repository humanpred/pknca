# Create a PKNCAconc object

Create a PKNCAconc object

## Usage

``` r
PKNCAconc(data, ...)

# Default S3 method
PKNCAconc(data, ...)

# S3 method for class 'tbl_df'
PKNCAconc(data, ...)

# S3 method for class 'data.frame'
PKNCAconc(
  data,
  formula,
  subject,
  time.nominal,
  exclude = NULL,
  duration,
  volume,
  exclude_half.life,
  include_half.life,
  lloq,
  sparse = FALSE,
  ...,
  concu = NULL,
  amountu = NULL,
  timeu = NULL,
  concu_pref = NULL,
  amountu_pref = NULL,
  timeu_pref = NULL
)
```

## Arguments

- data:

  A data frame with concentration (or amount for urine/feces), time, and
  the groups defined in `formula`.

- ...:

  Ignored.

- formula:

  The formula defining the `concentration~time|groups` or
  `amount~time|groups` for urine/feces (In the remainder of the
  documentation, "concentration" will be used to describe concentration
  or amount.) One special aspect of the `groups` part of the formula is
  that the last group to the left of any `/` is assumed to be the
  `subject` unless the `subject` argument is given. The `time` may be
  numeric, or it may be a date-time (POSIXct) or a date (Date); see the
  "Date-time input" section.

- subject:

  The column indicating the subject number. If not provided, this
  defaults to the last grouping variable to the left of a `/` (for
  example, `Subject` with `concentration~time|Study+Subject/Analyte`),
  or the last grouping variable when there is no `/` (for example,
  `Subject` with `concentration~time|Study+Subject`). When there are no
  grouping variables (single-subject data), no subject column is set.

- time.nominal:

  (optional) The name of the nominal time column (if the main time
  variable is actual time. The `time.nominal` is not used during
  calculations; it is available to assist with data summary and
  checking.

- exclude:

  (optional) The name of a column with concentrations to exclude from
  calculations and summarization. If given, the column should have
  values of `NA` or `""` for concentrations to include and non-empty
  text for concentrations to exclude.

- duration:

  (optional) The duration of collection as is typically used for
  concentration measurements in urine or feces. The `time` of a
  measurement is the start of the collection, and only the `time` is
  used when selecting data for a calculation interval; the duration is
  not considered. A collection starting within an interval and ending
  after the interval `end` contributes its full amount to that interval,
  so for the simplest interpretation of results, align collection start
  and end times with interval boundaries. A `duration` column is added
  to the data only when this is given; requesting an excretion rate
  parameter (`ermax`, `ertmax`, `ertlst`) without it is an error. A
  numeric duration is in the time unit of the analysis; a difftime
  duration is converted to that unit in
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md).

- volume:

  (optional) The volume (or mass) of collection as is typically used for
  urine or feces measurements. A `volume` column is added to the data
  only when this is given; requesting a parameter that needs it (`ae`,
  `fe`, `volpk`, and similar) without it is an error.

- exclude_half.life, include_half.life:

  Manual half-life point selection, given as a logical value per
  concentration measurement (or, in `PKNCAconc()`, the name of such a
  column in the data). `exclude_half.life` drops the flagged points;
  automatic curve-stripping point selection is still performed on the
  remaining (non-excluded) points and is not bypassed.
  `include_half.life` names the exact points to use, bypassing automatic
  curve-stripping point selection. Each value is `TRUE`, `FALSE`, or
  `NA` (undefined); the column/vector is treated as "in use" for an
  interval unless it is entirely `NA` (so an all-`FALSE` column still
  counts as in use), so leave it `NA` (rather than `FALSE`) where the
  mechanism should not apply. The column must be logical and must exist
  in the data; anything else is an error. Only one of
  `exclude_half.life` and `include_half.life` may be in use for a given
  interval. See the "Half-Life Calculation" vignette for more details on
  the use of these arguments.

- lloq:

  (optional) The lower limit of quantification used by the Tobit
  half-life method (`hl_method = "tobit"`). Either the name of a column
  in `data` giving the per-observation LLOQ or a numeric scalar applied
  to all observations. When provided, it is passed through to
  [`pk.calc.half.life()`](https://humanpred.github.io/pknca/reference/pk.calc.half.life.md).
  See the "Half-Life Calculation with Tobit Regression" vignette for
  more details.

- sparse:

  Are the concentration-time data sparse PK (commonly used in small
  nonclinical species or with terminal or difficult sampling) or dense
  PK (commonly used in clinical studies or larger nonclinical species)?

- concu, amountu, timeu:

  Either unit values (e.g. "ng/mL") or column names within the data
  where units are provided. For a date-time (POSIXct or Date) time
  column, `timeu` must be a unit value, and `timeu_pref` takes
  precedence over it (see the "Date-time input" section).

- concu_pref, amountu_pref, timeu_pref:

  Preferred units for reporting (not column names). For a date-time time
  column, the times are converted directly to `timeu_pref`, which then
  is also `timeu`.

## Value

A PKNCAconc object that can be used for automated NCA.

## Date-time input

The concentration time (and the dose time in
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md))
may be a date-time (POSIXct) or a date (Date; a date is taken as 08:00
on that date, a typical time of a first PK sample, with a warning).
Date-times have no numeric unit, so they are converted directly to the
time unit used for calculations and reports: `timeu_pref` when given (it
takes precedence over `timeu`, and `timeu` is set to it), otherwise
`timeu`, otherwise hours (without units). The unit must be a single time
unit value (like `"hr"` or `"day"`), not a column name. A numeric
`duration` (here or in
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md))
is in that unit, and a difftime `duration` is converted to it exactly.

The times remain date-times in the `PKNCAconc`, `PKNCAdose`, and
`PKNCAdata` objects.
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
converts them to numeric time relative to the first dose (or first
concentration) in each group; see the "Date-time input" section of
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md).
The nominal time (`time.nominal`) is not converted and usually stays
numeric.

## See also

Other PKNCA objects:
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md),
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md),
[`PKNCAresults()`](https://humanpred.github.io/pknca/reference/PKNCAresults.md)
