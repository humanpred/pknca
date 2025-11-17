# Clean up the time to steady-state parameters and return a data frame for use by the tss calculators.

Clean up the time to steady-state parameters and return a data frame for
use by the tss calculators.

## Usage

``` r
pk.tss.data.prep(
  conc,
  time,
  subject,
  treatment,
  subject.dosing,
  time.dosing,
  options = list(),
  conc.blq = NULL,
  conc.na = NULL,
  check = TRUE,
  ...
)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- subject:

  Subject identifiers (used as a random effect in the model)

- treatment:

  Treatment description (if missing, all subjects are assumed to be on
  the same treatment)

- subject.dosing:

  Subject number for dosing

- time.dosing:

  Time of dosing

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- conc.blq:

  See
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md)

- conc.na:

  See
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

- ...:

  Discarded inputs to allow generic calls between tss methods.

## Value

a data frame with columns for `conc`entration, `time`, `subject`, and
`treatment`.
