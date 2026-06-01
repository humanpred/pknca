# Calculate AUXC (AUC or AUMC) over an interval with interpolation/extrapolation

Calculates AUC or AUMC over a given interval, optionally interpolating
or extrapolating concentrations.

## Usage

``` r
pk.calc.auxcint(
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
  auc.type = c("AUClast", "AUCinf", "AUCall"),
  options = list(),
  method = NULL,
  conc.blq = NULL,
  conc.na = NULL,
  check = TRUE,
  fun_linear,
  fun_log,
  fun_inf,
  ...
)

pk.calc.aucint(conc, time, ..., options = list())

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

pk.calc.aumcint(conc, time, ..., options = list())

pk.calc.aumcint.last(
  conc,
  time,
  start = NULL,
  end = NULL,
  time.dose,
  ...,
  options = list()
)

pk.calc.aumcint.all(
  conc,
  time,
  start = NULL,
  end = NULL,
  time.dose,
  ...,
  options = list()
)

pk.calc.aumcint.inf.obs(
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

pk.calc.aumcint.inf.pred(
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
  for AUCinf calculations. If provided as `clast.obs` (observed clast
  value, default), AUCinf is AUCinf,obs. If provided as `clast.pred`,
  AUCinf is AUCinf,pred.

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- time.dose, route, duration.dose:

  The time of doses, route of administration, and duration of dose used
  with interpolation and extrapolation of concentration data (see
  [`interp.extrap.conc.dose()`](http://humanpred.github.io/pknca/reference/interp.extrap.conc.md)).
  If `NULL`,
  [`interp.extrap.conc()`](http://humanpred.github.io/pknca/reference/interp.extrap.conc.md)
  will be used instead.

- auc.type:

  The type of AUC to compute. Choices are 'AUCinf', 'AUClast', and
  'AUCall'.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- method:

  The method for integration (one of 'lin up/log down', 'lin-log', or
  'linear')

- conc.blq:

  How to handle a BLQ value that is between above LOQ values? See
  details for description.

- conc.na:

  How to handle NA concentrations. (See
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md))

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

- fun_linear, fun_log, fun_inf:

  Integration functions for linear, logarithmic, and infinite
  extrapolation methods.

- ...:

  Additional arguments passed to `pk.calc.auxc` and `interp.extrap.conc`

## Value

The AUXC for an interval of time as a number

## Details

When `pk.calc.auxcint()` needs to extrapolate using `lambda.z` (in other
words, using the half-life), it will always extrapolate using the
logarithmic trapezoidal rule to align with using a half-life calculation
for the extrapolation.

## Functions

- `pk.calc.aucint()`: Calculate AUC over an interval

- `pk.calc.aucint.last()`: Interpolate or extrapolate concentrations for
  AUClast

- `pk.calc.aucint.all()`: Interpolate or extrapolate concentrations for
  AUCall

- `pk.calc.aucint.inf.obs()`: Interpolate or extrapolate concentrations
  for AUCinf.obs

- `pk.calc.aucint.inf.pred()`: Interpolate or extrapolate concentrations
  for AUCinf.pred

- `pk.calc.aumcint()`: Calculate AUMC over an interval

- `pk.calc.aumcint.last()`: Interpolate or extrapolate concentrations
  for AUMClast

- `pk.calc.aumcint.all()`: Interpolate or extrapolate concentrations for
  AUMCall

- `pk.calc.aumcint.inf.obs()`: Interpolate or extrapolate concentrations
  for AUMCinf.obs

- `pk.calc.aumcint.inf.pred()`: Interpolate or extrapolate
  concentrations for AUMCinf.pred

## See also

[`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md),
[`interp.extrap.conc.dose()`](http://humanpred.github.io/pknca/reference/interp.extrap.conc.md)

Other AUC calculations:
[`pk.calc.auxc()`](http://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.auxciv()`](http://humanpred.github.io/pknca/reference/pk.calc.auxciv.md)

Other AUMC calculations:
[`pk.calc.auxciv()`](http://humanpred.github.io/pknca/reference/pk.calc.auxciv.md)
