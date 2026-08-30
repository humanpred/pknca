# Get all columns that depend on a parameter

Get all columns that depend on a parameter

## Usage

``` r
get.parameter.deps(x, recursive = FALSE)
```

## Arguments

- x:

  The parameter name (as a character string)

- recursive:

  Search backward to the inputs `x` is calculated from, rather than
  forward to the parameters calculated from `x`. See the details.

## Value

With `recursive = FALSE` (default), a character vector of parameter
names that depend on the parameter `x`; empty if none do. With
`recursive = TRUE`, the unique set of everything `x` is calculated from,
following each dependency to the end.

## Details

The two directions answer different questions. The default answers "what
becomes invalid if `x` changes?". `recursive = TRUE` answers "what does
`x` need?", and its result mixes parameter names with the raw inputs the
calculation ends at, such as `"conc"`, `"time"`, `"dose"`, and
`"time.dose"`.

## See also

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)
