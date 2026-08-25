# Determine the dosing interval (tau) to use for a calculation interval

A `tau` column in the interval specification takes precedence over
detection so that designs where only the steady-state dose is present in
the dosing data (nothing repeats, so nothing can be detected) can still
be calculated. Otherwise `tau` is detected from the group's dose times
with
[`find.tau()`](https://humanpred.github.io/pknca/reference/find.tau.md).

## Usage

``` r
resolve_dose_tau(interval, time.dose, options = list())
```

## Arguments

- interval:

  One row of an interval definition (see
  [`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md))

- time.dose:

  The dose times for the whole group (not just the interval; an interval
  one `tau` long contains a single dose, so nothing repeats within it)

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

The dosing interval, or `NA_real_` when it cannot be determined

## See also

Other Interval determination:
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`find.tau()`](https://humanpred.github.io/pknca/reference/find.tau.md)
