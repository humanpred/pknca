# Check the formatting of a calculation interval specification data frame.

Calculation interval specifications are data frames defining what
calculations will be required and summarized from all time intervals.
Note: parameters which are not requested may be calculated if it is
required for (or computed at the same time as) a requested parameter.

## Usage

``` r
check.interval.specification(x)
```

## Arguments

- x:

  The data frame specifying what to calculate during each time interval

## Value

x The potentially updated data frame with the interval calculation
specification.

## Details

`start` and `end` time must always be given as columns, and the `start`
must be before the `end`. Other columns define the parameters to be
calculated and the groupings to apply the intervals to.

## See also

The vignette "Selection of Calculation Intervals"

Other Interval specifications:
[`add.interval.col()`](http://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.deps()`](http://humanpred.github.io/pknca/reference/check.interval.deps.md),
[`choose.auc.intervals()`](http://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](http://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](http://humanpred.github.io/pknca/reference/get.parameter.deps.md)
