# Convert intervals between the wide and long representations

Convert intervals between the wide and long representations

## Usage

``` r
interval_longer(intervals)

interval_wider(long, template)
```

## Arguments

- intervals:

  A data.frame of intervals (the wide representation).

- long:

  The long representation, as returned by `interval_longer()`.

- template:

  The intervals data.frame the long form came from; used to restore the
  column order and any parameter columns that are no longer requested
  anywhere.

## Value

`interval_longer()` gives one row per interval and requested parameter
with a `param` column naming the parameter. `interval_wider()` gives the
wide representation back.

## Details

Only parameters requested as `TRUE` become rows in the long form.
Round-tripping therefore normalizes `NA` to `FALSE`, which is required:
`NA` in a parameter column is rejected by
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md)
and stops
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md).
