# Calculate the mean residence time (MRT) for multiple-dose data with nonlinear kinetics.

Calculate the mean residence time (MRT) for multiple-dose data with
nonlinear kinetics.

## Usage

``` r
pk.calc.mrt.md(auctau, aumctau, aucinf, tau)
```

## Arguments

- auctau:

  the AUC from time 0 to the end of the dosing interval (tau).

- aumctau:

  the AUMC from time 0 to the end of the dosing interval (tau).

- aucinf:

  the AUC from time 0 to infinity (typically using single-dose data)

- tau:

  The dosing interval

## Details

mrt.md is `aumctau/auctau + tau*(aucinf-auctau)/auctau` and should only
be used for multiple dosing with equal intervals between doses.

Note that if `aucinf == auctau` (as would be the assumption with linear
kinetics), the equation becomes the same as the single-dose MRT.

## See also

[`pk.calc.mrt()`](http://humanpred.github.io/pknca/reference/pk.calc.mrt.md)
