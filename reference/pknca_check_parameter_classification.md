# Report parameters that PKNCA cannot classify for automatic selection

Intended for packages that register their own NCA parameters: call it in
your tests to find parameters that will never be selected automatically
because they carry no concept.

## Usage

``` r
pknca_check_parameter_classification(param = NULL)
```

## Arguments

- param:

  Parameter names to describe. The default is every registered
  parameter.

## Value

A data.frame of the unclassifiable parameters, with the same columns as
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md).
Zero rows means everything is classified.

## See also

[`pknca_concept()`](https://humanpred.github.io/pknca/reference/pknca_concept.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md)

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)

## Examples

``` r
pknca_check_parameter_classification()
#> [1] parameter       concept         tier            sample_type    
#> [5] sparse          secondary       dose_normalized route          
#> [9] dosing         
#> <0 rows> (or 0-length row.names)
```
