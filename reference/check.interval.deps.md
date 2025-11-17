# Take in a single row of an interval specification and return that row updated with any additional calculations that must be done to fulfill all dependencies.

Take in a single row of an interval specification and return that row
updated with any additional calculations that must be done to fulfill
all dependencies.

## Usage

``` r
check.interval.deps(x)
```

## Arguments

- x:

  A data frame with one or more rows of the PKNCA interval

## Value

The interval specification with additional calculations added where
requested outputs require them.

## See also

Other Interval specifications:
[`add.interval.col()`](http://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](http://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](http://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](http://humanpred.github.io/pknca/reference/get.parameter.deps.md)
