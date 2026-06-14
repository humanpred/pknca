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
  impute_method = NA_character_,
  include_half.life = NULL,
  exclude_half.life = NULL,
  lloq = NULL,
  subject,
  sparse,
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
  mechanism should not apply. Only one of `exclude_half.life` and
  `include_half.life` may be in use for a given interval. See the
  "Half-Life Calculation" vignette for more details on the use of these
  arguments.

- lloq:

  An optional scalar or vector (the same length as `conc`) with the
  lower limit of quantification passed to
  [`pk.calc.half.life()`](https://humanpred.github.io/pknca/reference/pk.calc.half.life.md)
  for the Tobit half-life method.

- subject:

  Subject identifiers (used for sparse calculations)

- sparse:

  Should only sparse calculations be performed (TRUE) or only dense
  calculations (FALSE)?

- interval:

  One row of an interval definition (see
  [`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md)
  for how to define the interval.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

A data frame with the start and end time along with all PK parameters
for the `interval`

## See also

[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md)
