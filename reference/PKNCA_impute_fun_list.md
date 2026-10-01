# Separate out a vector of PKNCA imputation methods into a list of functions

Each imputation string is split at commas and spaces, and each method
name is expanded to its function name by adding `PKNCA_impute_method_`
to the beginning. An error will be raised if the functions are not
found.

## Usage

``` r
PKNCA_impute_fun_list(x)
```

## Arguments

- x:

  The character vector of PKNCA imputation method strings (without the
  `PKNCA_impute_method_` part, like `"start_predose,start_conc0"`)

## Value

A list with one element per element of `x`, each a character vector of
function names to run in order (or `NA_character_` for no imputation).

## See also

[`assert_impute_method()`](https://humanpred.github.io/pknca/reference/assert_impute_method.md),
[PKNCA_impute_method](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md)

Other Imputation:
[`PKNCA_impute_method`](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md),
[`assert_impute_method()`](https://humanpred.github.io/pknca/reference/assert_impute_method.md),
[`pknca_impute_methods()`](https://humanpred.github.io/pknca/reference/pknca_impute_methods.md)

## Examples

``` r
PKNCA_impute_fun_list(c("start_predose,start_conc0", NA))
#> [[1]]
#> [1] "PKNCA_impute_method_start_predose" "PKNCA_impute_method_start_conc0"  
#> 
#> [[2]]
#> [1] NA
#> 
```
