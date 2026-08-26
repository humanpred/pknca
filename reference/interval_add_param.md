# Add or remove parameters in the intervals of a PKNCAdata object

Add or remove parameters in the intervals of a PKNCAdata object

## Usage

``` r
interval_add_param(
  data,
  param = NULL,
  param_pattern = NULL,
  target_groups = NULL,
  ...
)

interval_remove_param(
  data,
  param = NULL,
  param_pattern = NULL,
  target_groups = NULL,
  ...
)
```

## Arguments

- data:

  A `PKNCAdata` object or a data.frame of intervals.

- param:

  A character vector of NCA parameter names.

- param_pattern:

  A character vector of regular expressions matching NCA parameter
  names. One or both of `param` and `param_pattern` must be given.

- target_groups:

  A data.frame of group values restricting the change to matching
  intervals. Every column must match (and) for at least one row of
  `target_groups` (or). `NULL` (the default) applies the change to all
  intervals.

- ...:

  Ignored.

## Value

The input with the parameters added or removed.

## See also

[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md)

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md)

## Examples

``` r
intervals <- data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE)
interval_add_param(intervals, param = c("auclast", "half.life"))
#>   start end cmax tmax auclast half.life
#> 1     0  24 TRUE TRUE    TRUE      TRUE
# At least one parameter must remain, so removing every one is an error
interval_remove_param(intervals, param_pattern = "^tmax$")
#>   start end cmax  tmax
#> 1     0  24 TRUE FALSE
```
