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

Data are selected for calculation within an interval by the time of the
measurement or dose: a row is included when its time is at or after
`start` and at or before `end` (a dose exactly at `end` is not included
in the interval). For duration data (for example, urine collections or
intravenous infusions), the time is the start of the collection or
administration, and the duration is not considered during selection: a
collection that starts within the interval and ends after `end` is
included and contributes its full amount to the interval. For the
simplest interpretation of results, align collection start and end times
with interval boundaries.

## See also

The vignette "Selection of Calculation Intervals"

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md)
