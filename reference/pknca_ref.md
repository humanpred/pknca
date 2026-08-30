# Mark a formalsmap entry as coming from the reference interval

Used in the `formalsmap` argument of
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md)
to declare that an argument takes the value of `param` calculated in the
*reference* interval (the interval named by the `<parameter>_ref` column
of the interval specification) rather than in the current interval.

## Usage

``` r
pknca_ref(param)

is_pknca_ref(x)
```

## Arguments

- param:

  The name of the NCA parameter to take from the reference interval (a
  single non-missing character string). It does not need to be
  registered yet when `pknca_ref()` is called; it is validated when the
  parameter is calculated.

- x:

  An object to test.

## Value

An object of class `pknca_ref`.

## See also

[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
the vignette "Secondary parameters"

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md)

## Examples

``` r
pknca_ref("aucinf.obs")
#> $param
#> [1] "aucinf.obs"
#> 
#> attr(,"class")
#> [1] "pknca_ref"
```
