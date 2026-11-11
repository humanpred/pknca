# Add the units that PKNCA accepts beyond those of udunits

Adds `"fraction"` (a dimensionless unit, for fraction excreted) and
`"mcg"` (an alias of `"ug"`, the spelling clinical data commonly use) to
the `units` package.
[`units::install_unit()`](https://r-quantities.github.io/units/reference/install_unit.html)
changes the udunits database of the R session, so these units are also
available to every other package that uses `units` once PKNCA is loaded.
Installing a unit again with the same definition does nothing, and
`"mcg"` is not installed when udunits already defines it.

## Usage

``` r
pknca_install_units()
```

## Value

`NULL`, invisibly
