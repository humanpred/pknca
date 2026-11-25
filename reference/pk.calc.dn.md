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

a number for dose normalized AUC. A result of length one has the reason
in its "exclude" attribute when it is `NA` because the dose is missing,
or `NaN` because the parameter and the dose are both zero.

## Examples

``` r
pk.calc.dn(90, 10)
#> [1] 9
```
