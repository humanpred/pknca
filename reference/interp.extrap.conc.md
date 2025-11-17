# Interpolate concentrations between measurements or extrapolate concentrations after the last measurement.

`interpolate.conc()` and `extrapolate.conc()` returns an interpolated
(or extrapolated) concentration. `interp.extrap.conc()` will choose
whether interpolation or extrapolation is required and will also operate
on many concentrations. These will typically be used to estimate the
concentration between two measured concentrations or after the last
measured concentration. Of note, these functions will not extrapolate
prior to the first point.

## Usage

``` r
interp.extrap.conc(
  conc,
  time,
  time.out,
  lambda.z = NA,
  clast = pk.calc.clast.obs(conc, time),
  options = list(),
  method = NULL,
  auc.type = "AUCinf",
  interp.method,
  extrap.method,
  ...,
  conc.blq = NULL,
  conc.na = NULL,
  check = TRUE
)

interpolate.conc(
  conc,
  time,
  time.out,
  options = list(),
  method = NULL,
  interp.method,
  conc.blq = NULL,
  conc.na = NULL,
  conc.origin = 0,
  ...,
  check = TRUE
)

extrapolate.conc(
  conc,
  time,
  time.out,
  lambda.z = NA,
  clast = pk.calc.clast.obs(conc, time),
  auc.type = "AUCinf",
  extrap.method,
  options = list(),
  conc.na = NULL,
  conc.blq = NULL,
  ...,
  check = TRUE
)

interp.extrap.conc.dose(
  conc,
  time,
  time.dose,
  route.dose = "extravascular",
  duration.dose = NA,
  time.out,
  out.after = FALSE,
  options = list(),
  conc.blq = NULL,
  conc.na = NULL,
  ...,
  check = TRUE
)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- time.out:

  Time when interpolation is requested (vector for
  `interp.extrap.conc()`, scalar otherwise)

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- clast:

  The last observed concentration above the limit of quantification. If
  not given, `clast` is calculated from
  [`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md)

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- method:

  The method for integration (one of 'lin up/log down', 'lin-log', or
  'linear')

- auc.type:

  The type of AUC to compute. Choices are 'AUCinf', 'AUClast', and
  'AUCall'.

- interp.method, extrap.method:

  deprecated in favor of method and auc.type

- ...:

  Additional arguments passed to `interpolate.conc()` or
  `extrapolate.conc()`.

- conc.blq:

  How to handle BLQ values. (See
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md)
  for usage instructions.)

- conc.na:

  How to handle NA concentrations. (See
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md))

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md),
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md),
  and
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)?

- conc.origin:

  The concentration before the first measurement. `conc.origin` is
  typically used to set predose values to zero (default), set a predose
  concentration for endogenous compounds, or set predose concentrations
  to `NA` if otherwise unknown.

- time.dose:

  Time of the dose

- route.dose:

  What is the route of administration ("intravascular" or
  "extravascular"). See the details for how this parameter is used.

- duration.dose:

  What is the duration of administration? See the details for how this
  parameter is used.

- out.after:

  Should interpolation occur from the data before (`FALSE`) or after
  (`TRUE`) the interpolated point? See the details for how this
  parameter is used. It only has a meaningful effect at the instant of
  an IV bolus dose.

## Value

The interpolated or extrapolated concentration value as a scalar double
(or vector for `interp.extrap.conc()`).

## Details

An `NA` value for the `lambda.z` parameter will prevent extrapolation.

- extrap.method:

  'AUCinf'

  :   Use lambda.z to extrapolate beyond the last point with the
      half-life.

  'AUCall'

  :   If the last point is above the limit of quantification or missing,
      this is identical to 'AUCinf'. If the last point is below the
      limit of quantification, then linear interpolation between the
      Clast and the next BLQ is used for that interval and all
      additional points are extrapolated as 0.

  'AUClast'

  :   Extrapolates all points after the last above the limit of
      quantification as 0.

`duration.dose` and `direction.out` are ignored if
`route.dose == "extravascular"`. `direction.out` is ignored if
`duration.dose > 0`.

`route.dose` and `duration.dose` affect how interpolation/extrapolation
of the concentration occurs at the time of dosing. If
`route.dose == "intravascular"` and `duration.dose == 0` then
extrapolation occurs for an IV bolus using
[`pk.calc.c0()`](http://humanpred.github.io/pknca/reference/pk.calc.c0.md)
with the data after dosing. Otherwise (either
`route.dose == "extravascular"` or `duration.dose > 0`), extrapolation
occurs using the concentrations before dosing and estimating the
half-life (or more precisely, estimating `lambda.z`). Finally,
`direction.out` can change the direction of interpolation in cases with
`route.dose == "intravascular"` and `duration.dose == 0`. When
`direction.out == "before"` interpolation occurs only with data before
the dose (as is the case for `route.dose == "extravascular"`), but if
`direction.out == "after"` interpolation occurs from the data after
dosing.

## Functions

- `interpolate.conc()`: Interpolate concentrations through Tlast
  (inclusive)

- `extrapolate.conc()`: Extrapolate concentrations after Tlast

- `interp.extrap.conc.dose()`: Interpolate and extrapolate
  concentrations without interpolating or extrapolating beyond doses.

## See also

[`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.half.life()`](http://humanpred.github.io/pknca/reference/pk.calc.half.life.md),
[`pk.calc.c0()`](http://humanpred.github.io/pknca/reference/pk.calc.c0.md)
