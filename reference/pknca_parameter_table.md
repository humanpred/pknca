# How each NCA parameter is classified for interval selection

How each NCA parameter is classified for interval selection

## Usage

``` r
pknca_parameter_table(param = NULL)
```

## Arguments

- param:

  Parameter names to describe. The default is every registered
  parameter.

## Value

A data.frame with one row per parameter and columns for the `concept`,
`tier`, `sample_type`, whether it is `sparse`, `dose_normalized`, or
`secondary` (needing inputs from more than one profile), and the `route`
and `dosing` contexts it applies to (comma-separated).

## Details

A parameter whose concept could not be resolved has `NA` for `concept`.
That is not an error: it is calculated normally when asked for by name,
but it is never selected automatically.

## See also

[`pknca_concept()`](https://humanpred.github.io/pknca/reference/pknca_concept.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md)

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md)

## Examples

``` r
head(pknca_parameter_table())
#>          parameter concept     tier sample_type sparse secondary
#> 1          auclast     auc   common        spot  FALSE     FALSE
#> 2           aucall     auc uncommon        spot  FALSE     FALSE
#> 3         aumclast    aumc uncommon        spot  FALSE     FALSE
#> 4          aumcall    aumc uncommon        spot  FALSE     FALSE
#> 5      aucint.last     auc   common        spot  FALSE     FALSE
#> 6 aucint.last.dose     auc uncommon        spot  FALSE     FALSE
#>   dose_normalized                                                     route
#> 1           FALSE extravascular,iv_bolus,iv_infusion,iv_continuous_infusion
#> 2           FALSE extravascular,iv_bolus,iv_infusion,iv_continuous_infusion
#> 3           FALSE extravascular,iv_bolus,iv_infusion,iv_continuous_infusion
#> 4           FALSE extravascular,iv_bolus,iv_infusion,iv_continuous_infusion
#> 5           FALSE extravascular,iv_bolus,iv_infusion,iv_continuous_infusion
#> 6           FALSE extravascular,iv_bolus,iv_infusion,iv_continuous_infusion
#>                         dosing
#> 1 single,multiple,steady_state
#> 2 single,multiple,steady_state
#> 3 single,multiple,steady_state
#> 4 single,multiple,steady_state
#> 5 single,multiple,steady_state
#> 6 single,multiple,steady_state
```
