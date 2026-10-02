# Match spellings of a route of administration to the route PKNCA uses

Match spellings of a route of administration to the route PKNCA uses

## Usage

``` r
pknca_match_route(x)
```

## Arguments

- x:

  A character vector (or factor) of route spellings, such as `"PO"` or
  `"INTRAVENOUS BOLUS"`. Matching ignores case and leading, trailing,
  and repeated white space.

## Value

A data.frame with one row for each element of `x` and the columns
`route` (one of
[`pknca_routes()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
or `"iv"` when the spelling is intravascular but does not say which
intravascular route it is) and `dose_route` (`"extravascular"` or
`"intravascular"`, the values
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
accepts for `route`). Both are `NA` when the spelling is not known or
`x` is `NA`.

## See also

The Route synonyms section of
[`pknca_routes()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md)
for the spellings that are known.

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md),
[`pknca_cdisc_codes()`](https://humanpred.github.io/pknca/reference/pknca_cdisc_codes.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)

## Examples

``` r
pknca_match_route(c("PO", "Intravenous", "IV BOLUS", "unknown"))
#>           route    dose_route
#> 1 extravascular extravascular
#> 2            iv intravascular
#> 3      iv_bolus intravascular
#> 4          <NA>          <NA>
```
