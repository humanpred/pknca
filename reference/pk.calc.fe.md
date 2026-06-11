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

[`pk.calc.ae()`](https://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.clr()`](https://humanpred.github.io/pknca/reference/pk.calc.clr.md)

Other Urine/Excretion parameters:
[`pk.calc.ae()`](https://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.clr()`](https://humanpred.github.io/pknca/reference/pk.calc.clr.md),
[`pk.calc.ermax()`](https://humanpred.github.io/pknca/reference/pk.calc.ermax.md),
[`pk.calc.ertlst()`](https://humanpred.github.io/pknca/reference/pk.calc.ertlst.md),
[`pk.calc.ertmax()`](https://humanpred.github.io/pknca/reference/pk.calc.ertmax.md),
[`pk.calc.volpk()`](https://humanpred.github.io/pknca/reference/pk.calc.volpk.md)
