# List the imputation methods

Every `PKNCA_impute_method_*()` function is registered with its
description; its arguments and their defaults come from the function
itself. The `method` names are what imputation strings use (see
[`PKNCA_impute_fun_list()`](https://humanpred.github.io/pknca/reference/PKNCA_impute_fun_list.md)
and the `impute` argument of
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)).

## Usage

``` r
pknca_impute_methods()
```

## Value

A tibble with one row per method, sorted by method, and the columns:

- method:

  The name used in imputation strings (for example, `"start_conc0"`)

- fun:

  The function name (for example, `"PKNCA_impute_method_start_conc0"`)

- description:

  The one-line description

- arguments:

  A list column of data.frames with one row per argument and the columns
  `argument` and `default` (the deparsed default, or `NA` when there is
  none)

## Details

Registration only describes PKNCA's own methods. A method is still found
by its function name: a user-defined `PKNCA_impute_method_<name>()`
function that PKNCA can see (for example, in the global environment) is
used by the imputation string `"<name>"` without being registered, and
it is not listed here.

## Methods

|  |  |
|----|----|
| Method | Description |
| `"end_conc_drop"` | Drop a concentration measured exactly at the end of the interval, if one is present (usually used with multiple-dose data when a point at the interval boundary belongs to the next dose, e.g. an imputed C0) |
| `"start_cmin"` | Add a new concentration of the minimum during the interval at the start time (usually used with multiple-dose data) |
| `"start_conc0"` | Set the concentration at the start time to 0, even if a nonzero concentration exists at that time (usually used with single-dose data). |
| `"start_predose"` | Shift a predose concentration to become the time zero concentration (only if a time zero concentration does not exist). |
| `"start_predose_conc0"` | Use a predose concentration as the start concentration when one is available and 0 when it is not. |

## See also

Other Imputation:
[`PKNCA_impute_fun_list()`](https://humanpred.github.io/pknca/reference/PKNCA_impute_fun_list.md),
[`PKNCA_impute_method`](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md),
[`assert_impute_method()`](https://humanpred.github.io/pknca/reference/assert_impute_method.md),
[`get_impute_column()`](https://humanpred.github.io/pknca/reference/get_impute_column.md),
[`get_impute_method()`](https://humanpred.github.io/pknca/reference/get_impute_method.md)

## Examples

``` r
pknca_impute_methods()[, c("method", "description")]
#> # A tibble: 5 × 2
#>   method              description                                               
#>   <chr>               <chr>                                                     
#> 1 end_conc_drop       Drop a concentration measured exactly at the end of the i…
#> 2 start_cmin          Add a new concentration of the minimum during the interva…
#> 3 start_conc0         Set the concentration at the start time to 0, even if a n…
#> 4 start_predose       Shift a predose concentration to become the time zero con…
#> 5 start_predose_conc0 Use a predose concentration as the start concentration wh…
```
