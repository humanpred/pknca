# Determine dose normalized NCA parameter

Determine dose normalized NCA parameter

## Usage

``` r
pk.calc.dn(parameter, dose)
```

## Arguments

- parameter:

  Parameter to dose normalize

- dose:

  Dose in units compatible with the area under the curve

## Value

a number for dose normalized AUC

## Examples

``` r
pk.calc.dn(90, 10)
#> [1] 9
```
