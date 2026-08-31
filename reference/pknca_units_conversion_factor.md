# Find the factor converting a value from one unit to another

Find the factor converting a value from one unit to another

## Usage

``` r
pknca_units_conversion_factor(from, to)
```

## Arguments

- from, to:

  Single unit strings, as they appear in the "PPORRESU" and "PPSTRESU"
  columns of a unit conversion table

## Value

The number that a value in `from` units is multiplied by to express it
in `to` units. Units that the `units` package cannot convert between are
an error.
