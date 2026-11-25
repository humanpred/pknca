# Calculate the AUC percent extrapolated

Calculate the AUC percent extrapolated

## Usage

``` r
pk.calc.aucpext(auclast, aucinf)
```

## Arguments

- auclast:

  the area under the curve from time 0 to the last measurement above the
  limit of quantification

- aucinf:

  the area under the curve from time 0 to infinity

## Value

The numeric value of the AUC percent extrapolated, or `NA_real_` if
`aucinf` or `auclast` is `NA` or `aucinf` is zero (a negative value is
calculated, with a warning). A result of length one that is `NA` because
of missing or unusable data has the reason in its "exclude" attribute,
which
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
reports.

## Details

aucpext is `100*(1-auclast/aucinf)`.

## See also

Other Half-life and elimination:
[`adj.r.squared()`](https://humanpred.github.io/pknca/reference/adj.r.squared.md),
[`pk.calc.half.life()`](https://humanpred.github.io/pknca/reference/pk.calc.half.life.md),
[`pk.calc.thalf.eff()`](https://humanpred.github.io/pknca/reference/pk.calc.thalf.eff.md)
