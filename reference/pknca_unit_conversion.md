# Perform unit conversion (if possible) on PKNCA results

Perform unit conversion (if possible) on PKNCA results

## Usage

``` r
pknca_unit_conversion(result, units, allow_partial_missing_units = FALSE)
```

## Arguments

- result:

  The results data.frame

- units:

  The unit conversion table

- allow_partial_missing_units:

  Should missing units be allowed for some but not all parameters?

## Value

The result table with units converted
