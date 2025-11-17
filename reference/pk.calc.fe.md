# Calculate fraction excreted (typically in urine or feces)

Calculate fraction excreted (typically in urine or feces)

## Usage

``` r
pk.calc.fe(ae, dose)
```

## Arguments

- ae:

  The amount excreted (as a numeric scalar or vector)

- dose:

  The dose (as a numeric scalar or vector)

## Value

The fraction of dose excreted

## Details

fe is `sum(ae)/dose`

The units for `ae` and `dose` should be the same so that `ae/dose` is a
unitless fraction.

## See also

[`pk.calc.ae()`](http://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.clr()`](http://humanpred.github.io/pknca/reference/pk.calc.clr.md)
