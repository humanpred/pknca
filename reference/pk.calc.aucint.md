# Calculate the AUC over an interval with interpolation and/or extrapolation of concentrations for the beginning and end of the interval.

Calculate the AUC over an interval with interpolation and/or
extrapolation of concentrations for the beginning and end of the
interval.

## Usage

``` r
pk.calc.aucint(
  conc,
  time,
  interval = NULL,
  start = NULL,
  end = NULL,
  clast = pk.calc.clast.obs(conc, time),
  lambda.z = NA,
  time.dose = NULL,
  route = "extravascular",
  duration.dose = 0,
  method = NULL,
  auc.type = "AUClast",
  conc.blq = NULL,
  conc.na = NULL,
  check = TRUE,
  ...,
  options = list()
)

pk.calc.aucint.last(
  conc,
  time,
  start = NULL,
  end = NULL,
  time.dose,
  ...,
  options = list()
)

pk.calc.aucint.all(
  conc,
  time,
  start = NULL,
  end = NULL,
  time.dose,
  ...,
  options = list()
)

pk.calc.aucint.inf.obs(
  conc,
  time,
  start = NULL,
  end = NULL,
  time.dose,
  lambda.z,
  clast.obs,
  ...,
  options = list()
)

pk.calc.aucint.inf.pred(
  conc,
  time,
  start = NULL,
  end = NULL,
  time.dose,
  lambda.z,
  clast.pred,
  ...,
  options = list()
)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- interval:

  Numeric vector of two numbers for the start and end time of
  integration

- start:

  The start time of the interval

- end:

  The end time of the interval

- clast, clast.obs, clast.pred:

  The last concentration above the limit of quantification; this is used
  for AUCinf calculations. If provided as clast.obs (observed clast
  value, default), AUCinf is AUCinf,obs. If provided as clast.pred,
  AUCinf is AUCinf,pred.

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- time.dose, route, duration.dose:

  The time of doses, route of administration, and duration of dose used
  with interpolation and extrapolation of concentration data (see
  [`interp.extrap.conc.dose()`](http://humanpred.github.io/pknca/reference/interp.extrap.conc.md)).
  If `NULL`,
  [`interp.extrap.conc()`](http://humanpred.github.io/pknca/reference/interp.extrap.conc.md)
  will be used instead (assuming that no doses affecting concentrations
  are in the interval).

- method:

  The method for integration (one of 'lin up/log down', 'lin-log', or
  'linear')

- auc.type:

  The type of AUC to compute. Choices are 'AUCinf', 'AUClast', and
  'AUCall'.

- conc.blq:

  How to handle BLQ values in between the first and last above LOQ
  concentrations. (See
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md)
  for usage instructions.)

- conc.na:

  How to handle missing concentration values. (See
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)
  for usage instructions.)

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md),
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md),
  and
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)?

- ...:

  Additional arguments passed to `pk.calc.auxc` and `interp.extrap.conc`

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

The AUC for an interval of time as a number

## Details

When `pk.calc.aucint()` needs to extrapolate using `lambda.z` (in other
words, using the half-life), it will always extrapolate using the
logarithmic trapezoidal rule to align with using a half-life calculation
for the extrapolation.

## Functions

- `pk.calc.aucint.last()`: Interpolate or extrapolate concentrations for
  AUClast

- `pk.calc.aucint.all()`: Interpolate or extrapolate concentrations for
  AUCall

- `pk.calc.aucint.inf.obs()`: Interpolate or extrapolate concentrations
  for AUCinf.obs

- `pk.calc.aucint.inf.pred()`: Interpolate or extrapolate concentrations
  for AUCinf.pred

## See also

[`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md),
[`interp.extrap.conc.dose()`](http://humanpred.github.io/pknca/reference/interp.extrap.conc.md)

Other AUC calculations:
[`pk.calc.auxc()`](http://humanpred.github.io/pknca/reference/pk.calc.auxc.md)
