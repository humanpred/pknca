# Determine the degree of fluctuation

Determine the degree of fluctuation

## Usage

``` r
pk.calc.deg.fluc(cmax, cmin, cav)

pk.calc.swing(cmax, cmin)
```

## Arguments

- cmax:

  The maximum observed concentration

- cmin:

  The minimum observed concentration

- cav:

  The average concentration in the interval

## Value

The degree of fluctuation around the average concentration. A result of
length one that is `NA` because of missing or unusable data has the
reason in its "exclude" attribute, which
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
reports.

The swing above the minimum concentration, one value for each pair of
`cmax` and `cmin`. If `cmin` is zero, then the result is infinity; if
`cmin` or `cmax` is missing, it is `NA`.

## Details

deg.fluc is `100*(cmax - cmin)/cav`.

swing is `100*(cmax - cmin)/cmin`.

## Functions

- `pk.calc.swing()`: PK swing

## See also

Other Multiple-dose PK parameters:
[`pk.calc.ptr()`](https://humanpred.github.io/pknca/reference/pk.calc.ptr.md)
