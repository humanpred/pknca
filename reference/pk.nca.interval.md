# Compute all PK parameters for a single concentration-time data set

For one subject/time range, compute all available PK parameters. All the
internal options should be set by
[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md)
prior to running. The only part that changes with a call to this
function is the `conc`entration and `time`.

## Usage

``` r
pk.nca.interval(
  conc,
  time,
  volume,
  duration.conc,
  dose,
  time.dose,
  duration.dose,
  route,
  conc.group = NULL,
  time.group = NULL,
  volume.group = NULL,
  duration.conc.group = NULL,
  dose.group = NULL,
  time.dose.group = NULL,
  duration.dose.group = NULL,
  route.group = NULL,
  conc.sparse = NULL,
  time.sparse = NULL,
  conc.sparse.group = NULL,
  time.sparse.group = NULL,
  impute_method = NA_character_,
  include_half.life = NULL,
  exclude_half.life = NULL,
  lloq = NULL,
  subject = NULL,
  interval,
  options = list()
)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- volume, volume.group:

  The volume (or mass) of the concentration measurement for the current
  interval or all data for the group (typically for urine and fecal
  measurements)

- duration.conc, duration.conc.group:

  The duration of the concentration measurement for the current interval
  or all data for the group (typically for urine and fecal measurements)

- dose, dose.group:

  Dose amount (may be a scalar or vector) for the current interval or
  all data for the group

- time.dose:

  Time of the dose for the current interval (must be the same length as
  `dose`)

- duration.dose:

  The duration of the dose administration for the current interval
  (typically zero for extravascular and intravascular bolus and nonzero
  for intravascular infusion)

- route, route.group:

  The route of dosing for the current interval or all data for the group

- conc.group:

  All concentrations measured for the group

- time.group:

  Time of all concentrations measured for the group

- time.dose.group:

  Time of the dose for all data for the group (must be the same length
  as `dose.group`)

- duration.dose.group:

  The duration of the dose administration for all data for the group
  (typically zero for extravascular and intravascular bolus and nonzero
  for intravascular infusion)

- conc.sparse, time.sparse:

  The pooled individual concentrations and their times for the current
  interval with sparse PK (`conc` and `time` are the arithmetic-mean
  profile built from them). `NULL` for dense PK.

- conc.sparse.group, time.sparse.group:

  The pooled individual concentrations and their times for all data for
  the group with sparse PK. `NULL` for dense PK.

- impute_method:

  The method to use for imputation as a character string

- exclude_half.life, include_half.life:

  Manual half-life point selection, given as a logical value per
  concentration measurement (or, in
  [`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md),
  the name of such a column in the data). `exclude_half.life` drops the
  flagged points; automatic curve-stripping point selection is still
  performed on the remaining (non-excluded) points and is not bypassed.
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

  An optional scalar or vector (the same length as `conc`) with the
  lower limit of quantification passed to
  [`pk.calc.half.life()`](https://humanpred.github.io/pknca/reference/pk.calc.half.life.md)
  for the Tobit half-life method.

- subject:

  Subject identifiers for the pooled sparse samples

- interval:

  One row of an interval definition (see
  [`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md)
  for how to define the interval.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

A data frame with one row per result, with columns `PPTESTCD`,
`PPORRES`, `PPANMETH`, and `exclude`. Its "sparse" attribute is a
logical vector saying, for each row, whether the parameter that produced
it is registered as a sparse PK parameter.

## See also

[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md)
