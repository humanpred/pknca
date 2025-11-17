# Perform the half-life fit given the data. The function simply fits the data without any validation. No selection of points or any other components are done.

Perform the half-life fit given the data. The function simply fits the
data without any validation. No selection of points or any other
components are done.

## Usage

``` r
fit_half_life(data, tlast, conc_units)
```

## Arguments

- data:

  The data to fit. Must have two columns named "log_conc" and "time"

- tlast:

  The time of last observed concentration above the limit of
  quantification.

- conc_units:

  NULL or the units to set for concentration measures

## Value

A data.frame with one row and columns named "r.squared",
"adj.r.squared", "PROB", "lambda.z", "clast.pred", "lambda.z.n.points",
"half.life", "span.ratio"

## See also

[`pk.calc.half.life()`](http://humanpred.github.io/pknca/reference/pk.calc.half.life.md)
