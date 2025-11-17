# Calculate renal clearance

Calculate renal clearance

## Usage

``` r
pk.calc.clr(ae, auc)
```

## Arguments

- ae:

  The amount excreted in urine (as a numeric scalar or vector)

- auc:

  The area under the curve (as a numeric scalar or vector)

## Value

The renal clearance as a number

## Details

clr is `sum(ae)/auc`.

The units for the `ae` and `auc` should match such that `ae/auc` has
units of volume/time.

## See also

[`pk.calc.ae()`](http://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.fe()`](http://humanpred.github.io/pknca/reference/pk.calc.fe.md)
