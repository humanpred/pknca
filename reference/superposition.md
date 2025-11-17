# Compute noncompartmental superposition for repeated dosing

Compute noncompartmental superposition for repeated dosing

## Usage

``` r
superposition(conc, ...)

# S3 method for class 'PKNCAconc'
superposition(conc, ...)

# S3 method for class 'numeric'
superposition(
  conc,
  time,
  dose.input = NULL,
  tau,
  dose.times = 0,
  dose.amount,
  n.tau = Inf,
  options = list(),
  lambda.z,
  clast.pred = FALSE,
  tlast,
  additional.times = numeric(),
  check.blq = TRUE,
  method = NULL,
  auc.type = "AUCinf",
  steady.state.tol = 0.001,
  ...
)
```

## Arguments

- conc:

  Measured concentrations

- ...:

  Additional arguments passed to the `half.life` function if required to
  compute `lambda.z`.

- time:

  Time of the measurement of the concentrations

- dose.input:

  The dose given to generate the `conc` and `time` inputs. If missing,
  output doses will be assumed to be equal to the input dose.

- tau:

  The dosing interval

- dose.times:

  The time of dosing within the dosing interval. The `min(dose.times)`
  must be \>= 0, and the `max(dose.times)` must be \< `tau`. There may
  be more than one dose times given as a vector.

- dose.amount:

  The doses given for the output. Linear proportionality will be used
  from the input to output if they are not equal. The length of
  dose.amount must be either 1 or matching the length of `dose.times`.

- n.tau:

  The number of tau dosing intervals to simulate or `Inf` for
  steady-state.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- clast.pred:

  To use predicted as opposed to observed Clast, either give the value
  for clast.pred here or set it to true (for automatic calculation from
  the half-life).

- tlast:

  The time of last observed concentration above the limit of
  quantification. This is calculated if not provided.

- additional.times:

  Times to include in the final outputs in addition to the standard
  times (see details). All `min(additional.times)` must be \>= 0, and
  the `max(additional.times)` must be \<= `tau`.

- check.blq:

  Must the first concentration measurement be below the limit of
  quantification?

- method:

  The method for integration (one of 'lin up/log down', 'lin-log', or
  'linear')

- auc.type:

  The type of AUC to compute. Choices are 'AUCinf', 'AUClast', and
  'AUCall'.

- steady.state.tol:

  The tolerance for assessing if steady-state has been achieved (between
  0 and 1, exclusive).

## Value

A data frame with columns named "conc" and "time".

## Details

The returned superposition times will include all of the following
times: 0 (zero), `dose.times`, `time modulo tau` (shifting `time` for
each dose time as well), `additional.times`, and `tau`.

## See also

[`interp.extrap.conc()`](http://humanpred.github.io/pknca/reference/interp.extrap.conc.md)
