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

Other Urine/Excretion parameters:
[`pk.calc.ae()`](http://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.ermax()`](http://humanpred.github.io/pknca/reference/pk.calc.ermax.md),
[`pk.calc.ertlst()`](http://humanpred.github.io/pknca/reference/pk.calc.ertlst.md),
[`pk.calc.ertmax()`](http://humanpred.github.io/pknca/reference/pk.calc.ertmax.md),
[`pk.calc.fe()`](http://humanpred.github.io/pknca/reference/pk.calc.fe.md),
[`pk.calc.volpk()`](http://humanpred.github.io/pknca/reference/pk.calc.volpk.md)
