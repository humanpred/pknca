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
  route = "extravascular",
  duration.dose = 0,
  ...,
  options = list()
)

pk.calc.aucint.all(
  conc,
  time,
  start = NULL,
  end = NULL,
  time.dose,
  route = "extravascular",
  duration.dose = 0,
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
  route = "extravascular",
  duration.dose = 0,
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
  route = "extravascular",
  duration.dose = 0,
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
  route = "extravascular",
  duration.dose = 0,
  ...,
  options = list()
)

pk.calc.aumcint.all(
  conc,
  time,
  start = NULL,
  end = NULL,
  time.dose,
  route = "extravascular",
  duration.dose = 0,
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
  route = "extravascular",
  duration.dose = 0,
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
  route = "extravascular",
  duration.dose = 0,
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
  [`interp.extrap.conc.dose()`](https://humanpred.github.io/pknca/reference/interp.extrap.conc.md)).
  If `NULL` or if every `time.dose` is `NA` (an analysis with no dosing
  data),
  [`interp.extrap.conc()`](https://humanpred.github.io/pknca/reference/interp.extrap.conc.md)
  is used instead and the calculation is not dose-aware. If only some
  `time.dose` values are `NA`, the result is `NA` because that dose
  cannot be placed on the timeline.

- auc.type:

  The type of AUC to compute. Choices are 'AUCinf', 'AUClast', and
  'AUCall'.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- method:

  The method for integration (one of 'lin up/log down', 'lin-log', or
  'linear')

- conc.blq:

  How to handle a BLQ value that is between above LOQ values? See
  details for description.

- conc.na:

  How to handle NA concentrations. (See
  [`clean.conc.na()`](https://humanpred.github.io/pknca/reference/clean.conc.na.md))

- check:

  Run
  [`assert_conc_time()`](https://humanpred.github.io/pknca/reference/assert_conc_time.md)?

- fun_linear, fun_log, fun_inf:

  Integration functions for linear, logarithmic, and infinite
  extrapolation methods.

- ...:

  Additional arguments passed to `pk.calc.auxc` and `interp.extrap.conc`

## Value

The AUXC for an interval of time as a number

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

## Doses bound the profile

When dose times are given, the concentrations used to extrapolate the
profile being integrated, if extrapolation is required, end at the first
dose at or after `end`: a concentration measured after that dose is
affected by the dose and is neither integrated nor used for
interpolation/extrapolation into this interval. Concentrations from
before the interval are used to estimate the concentration at `start`,
and that estimate does not interpolate across a dose either (see
[`interp.extrap.conc.dose()`](https://humanpred.github.io/pknca/reference/interp.extrap.conc.md)).

Only `start` and `end` are estimated. A dose within the interval is
integrated across using the concentrations measured on either side of
it, because the interval asks for the profiles on both sides of that
dose to be integrated together.

## The region after Tlast

The region of the interval after the last measurable concentration is
handled the same way as the matching AUC parameter:

- `AUClast`:

  contributes zero.

- `AUCall`:

  contributes the triangle from `clast` to the first
  below-the-limit-of-quantification measurement and zero after that.

- `AUCinf`:

  is extrapolated with `lambda.z` (in other words, with the half-life),
  always using the logarithmic trapezoidal rule to align with the
  exponential decay that the half-life describes. When `lambda.z` is not
  estimable and the interval is finite, `AUCall` is used instead.

When the interval ends at or before Tlast, no extrapolation happens and
`lambda.z` is not used at all. The extrapolation that was used is
reported in the method (`PPANMETH`) column.

## See also

[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md),
[`interp.extrap.conc.dose()`](https://humanpred.github.io/pknca/reference/interp.extrap.conc.md)

Other AUC calculations:
[`pk.calc.auxc()`](https://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.auxciv()`](https://humanpred.github.io/pknca/reference/pk.calc.auxciv.md)

Other AUMC calculations:
[`pk.calc.auxciv()`](https://humanpred.github.io/pknca/reference/pk.calc.auxciv.md)
