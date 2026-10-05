# Check an imputation specification

The specification is resolved the way
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
and [`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
resolve it: the name of a column in `intervals`, `NA` to use the
`"impute"` column of `intervals` when there is one, or otherwise a
string of imputation methods. Every method named must exist.

## Usage

``` r
assert_impute_method(impute, intervals = data.frame())
```

## Arguments

- impute:

  The imputation specification (a character scalar or `NA`)

- intervals:

  The intervals data.frame (if the specification may name one of its
  columns)

## Value

The resolved imputation strings (one per interval when read from a
column), invisibly, or an error

## See also

[`PKNCA_impute_fun_list()`](https://humanpred.github.io/pknca/reference/PKNCA_impute_fun_list.md),
[PKNCA_impute_method](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md)

Other Imputation:
[`PKNCA_impute_fun_list()`](https://humanpred.github.io/pknca/reference/PKNCA_impute_fun_list.md),
[`PKNCA_impute_method`](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md),
[`get_impute_method()`](https://humanpred.github.io/pknca/reference/get_impute_method.md),
[`pknca_impute_methods()`](https://humanpred.github.io/pknca/reference/pknca_impute_methods.md)

## Examples

``` r
assert_impute_method("start_predose,start_conc0")
assert_impute_method(
  "method",
  intervals = data.frame(start = 0, end = 24, method = "start_conc0")
)
try(assert_impute_method("start_misspelled"))
#> Error in PKNCA_impute_fun_list(ret) : 
#>   The following imputation functions were not found: PKNCA_impute_method_start_misspelled.  The imputation setting must be an imputation method or a column of the intervals.
```
