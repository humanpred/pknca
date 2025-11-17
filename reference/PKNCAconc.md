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
  that the last group is typically assumed to be the `subject`; see the
  documentation for the `subject` argument for exceptions to this
  assumption.

- subject:

  The column indicating the subject number. If not provided, this
  defaults to the beginning of the inner groups: For example with
  `concentration~time|Study+Subject/Analyte`, the inner groups start
  with the first grouping variable before a `/`, `Subject`. If there is
  only one grouping variable, it is assumed to be the subject (e.g.
  `concentration~time|Subject`), and if there are multiple grouping
  variables without a `/`, subject is assumed to be the last one. For
  single-subject data, it is assigned as `NULL`.

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
  concentration measurements in urine or feces.

- volume:

  (optional) The volume (or mass) of collection as is typically used for
  urine or feces measurements.

- exclude_half.life, include_half.life:

  A character scalar for the column name in the dataset of the points to
  exclude from the half-life calculation (still using normal
  curve-stripping selection rules for the other points) or to include
  for the half-life (using specifically those points and bypassing
  automatic curve-stripping point selection). See the "Half-Life
  Calculation" vignette for more details on the use of these arguments.

- sparse:

  Are the concentration-time data sparse PK (commonly used in small
  nonclinical species or with terminal or difficult sampling) or dense
  PK (commonly used in clinical studies or larger nonclinical species)?

- concu, amountu, timeu:

  Either unit values (e.g. "ng/mL") or column names within the data
  where units are provided.

- concu_pref, amountu_pref, timeu_pref:

  Preferred units for reporting (not column names)

## Value

A PKNCAconc object that can be used for automated NCA.

## See also

Other PKNCA objects:
[`PKNCAdata()`](http://humanpred.github.io/pknca/reference/PKNCAdata.md),
[`PKNCAdose()`](http://humanpred.github.io/pknca/reference/PKNCAdose.md),
[`PKNCAresults()`](http://humanpred.github.io/pknca/reference/PKNCAresults.md)
