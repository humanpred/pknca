# Find the conversion factor between two units, when there is one

The conversions of
[`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md)
are requested by the user and so fail loudly when they cannot be made.
This answers the different question of whether two units PKNCA derived
itself can be reconciled – units that are unrelated (a concentration and
an amount) or outside udunits (`"IU/mL"`) are an expected answer of "no"
rather than a mistake.

## Usage

``` r
pknca_unit_reconcile_factor(from, to)
```

## Arguments

- from, to:

  Single unit strings, as they appear in the "PPORRESU" and "PPSTRESU"
  columns of a unit conversion table

## Value

The number that a value in `from` units is multiplied by to express it
in `to` units, or `NA_real_` when the two are not convertible or the
`units` package is not installed.

## See also

[`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md)
