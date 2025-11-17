# Compute all PK parameters for a single concentration-time data set

For one subject/time range, compute all available PK parameters. All the
internal options should be set by
[`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md)
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

- include_half.life:

  An optional boolean vector of the concentration measurements to
  include in the half-life calculation. If given, no half-life point
  selection will occur.

- exclude_half.life:

  An optional boolean vector of the concentration measurements to
  exclude from the half-life calculation.

- subject:

  Subject identifiers (used for sparse calculations)

- sparse:

  Should only sparse calculations be performed (TRUE) or only dense
  calculations (FALSE)?

- interval:

  One row of an interval definition (see
  [`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md)
  for how to define the interval.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

A data frame with the start and end time along with all PK parameters
for the `interval`

## See also

[`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md)
