# Determine time at or above a set value

Interpolation is performed aligning with `PKNCA.options("auc.method")`.
Extrapolation outside of the measured times is not yet implemented. The
`method` may be changed by giving a named `method` argument, as well.

## Usage

``` r
pk.calc.time_above(conc, time, conc_above, ..., options = list(), check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- conc_above:

  The concentration to be above

- ...:

  Extra arguments. Currently, the only extra argument that is used is
  `method` as described in the details section.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md),
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md),
  and
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)?

## Value

the time above the given concentration

## Details

For `'lin up/log down'`, if `clast` is above `conc_above` and there are
concentrations BLQ after that, linear down is used to extrapolate to the
BLQ concentration (equivalent to AUCall).
