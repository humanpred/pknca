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
[`add.interval.col()`](http://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.deps()`](http://humanpred.github.io/pknca/reference/check.interval.deps.md),
[`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](http://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](http://humanpred.github.io/pknca/reference/get.interval.cols.md)
