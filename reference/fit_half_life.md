# Perform the half-life fit given the data. The function simply fits the data without any validation. No selection of points or any other components are done.

Perform the half-life fit given the data. The function simply fits the
data without any validation. No selection of points or any other
components are done.

## Usage

``` r
fit_half_life(data, tlast)
```

## Arguments

- data:

  The data to fit. Must have two columns named "log_conc" and "time"

- tlast:

  The time of last observed concentration above the limit of
  quantification.

## Value

A named list with one value each for "r.squared", "adj.r.squared",
"lambda.z.corrxy", "lambda.z", "clast.pred", "lambda.z.time.first",
"lambda.z.time.last", "lambda.z.n.points", "half.life", and
"span.ratio".
[`pk.calc.half.life()`](https://humanpred.github.io/pknca/reference/pk.calc.half.life.md)
fits one candidate per span of terminal points and builds a data.frame
from the candidate it selects.

## See also

[`pk.calc.half.life()`](https://humanpred.github.io/pknca/reference/pk.calc.half.life.md)
