# Add or remove an imputation method in the intervals of a PKNCAdata object

Add or remove an imputation method in the intervals of a PKNCAdata
object

## Usage

``` r
interval_add_impute(
  data,
  target_impute,
  after = Inf,
  target_params = NULL,
  target_groups = NULL,
  ...
)

interval_remove_impute(
  data,
  target_impute,
  target_params = NULL,
  target_groups = NULL,
  ...
)
```

## Arguments

- data:

  A `PKNCAdata` object or a data.frame of intervals.

- target_impute:

  The imputation method to add or remove, as a character string (see
  [PKNCA_impute_method](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md)).

- after:

  Where to insert the method within any imputation already present,
  following [`base::append()`](https://rdrr.io/r/base/append.html): `0`
  makes it first and `Inf` (the default) makes it last. A method that is
  already present is moved to the requested position rather than
  duplicated.

- target_params:

  Restrict the change to these NCA parameters. `NULL` (the default)
  applies it to every parameter being calculated.

- target_groups:

  A data.frame of group values restricting the change to matching
  intervals. Every column must match (and) for at least one row of
  `target_groups` (or). `NULL` (the default) applies the change to all
  intervals.

- ...:

  Ignored.

## Value

The input with the imputation updated. An interval is split into more
than one row when its parameters no longer share the same imputation,
and rows that come to share every value are merged.

## See also

[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md),
and the vignette "Data Imputation"

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)

## Examples

``` r
intervals <- data.frame(start = 0, end = 24, cmax = TRUE, half.life = TRUE)
# Impute a starting concentration for everything in the interval
interval_add_impute(intervals, target_impute = "start_conc0")
#>   start end cmax half.life      impute
#> 1     0  24 TRUE      TRUE start_conc0
# ... but not for half-life, which splits the interval into two rows
interval_add_impute(intervals, target_impute = "start_conc0", target_params = "cmax")
#>   start end  cmax half.life      impute
#> 1     0  24  TRUE     FALSE start_conc0
#> 2     0  24 FALSE      TRUE        <NA>
```
