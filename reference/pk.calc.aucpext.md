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

The numeric value of the AUC percent extrapolated or `NA_real_` if any
of the following are true `is.na(aucinf)`, `is.na(auclast)`,
`aucinf <= 0`, or `auclast <= 0`.

## Details

aucpext is `100*(1-auclast/aucinf)`.
