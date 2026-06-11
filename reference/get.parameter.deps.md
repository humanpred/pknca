# Get all columns that depend on a parameter

Get all columns that depend on a parameter

## Usage

``` r
get.parameter.deps(x)
```

## Arguments

- x:

  The parameter name (as a character string)

## Value

A character vector of parameter names that depend on the parameter `x`.
If none depend on `x`, then the result will be an empty vector.

## See also

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md)
