# Named argument sets for building an interval specification

Named argument sets for building an interval specification

## Usage

``` r
pknca_presets()
```

## Value

A named list of the arguments each preset gives to
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md).
Arguments given to that function directly override the preset.

## See also

[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md)

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
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md)

## Examples

``` r
names(pknca_presets())
#> [1] "single_dose"        "steady_state"       "bioequivalence"    
#> [4] "first_in_human"     "mass_balance"       "sparse_single_dose"
pknca_presets()$bioequivalence
#> $dosing
#> [1] "single"
#> 
#> $route
#> [1] "extravascular"
#> 
#> $include
#> [1] "aucall"    "clast.obs" "tlast"    
#> 
```
