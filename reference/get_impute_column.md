# Get the name of the intervals column that the imputation methods come from

`get_impute_column()` applies the first two of the three readings of
`impute` described in
[`get_impute_method()`](https://humanpred.github.io/pknca/reference/get_impute_method.md)
and says which column
[`get_impute_method()`](https://humanpred.github.io/pknca/reference/get_impute_method.md)
reads the methods from. It does not read the column, so it does not
check that the column is character.

## Usage

``` r
get_impute_column(intervals, impute)
```

## Arguments

- intervals:

  the data.frame of intervals

- impute:

  the imputation definition – either the name of a column in `intervals`
  (character scalar), `NA` to look for a generic `"impute"` column, or
  the imputation method string. Must be an atomic scalar; a list (even
  of length 1) is rejected.

## Value

The name of the column of `intervals` that the methods come from
(character scalar): `impute` when it names a column of `intervals`, or
`"impute"` when `impute` is `NA` and `intervals` has a column named
`"impute"`. `NULL` when `impute` is itself the method string, or is `NA`
and there is no `"impute"` column, so there is no column.

## See also

Other Imputation:
[`PKNCA_impute_fun_list()`](https://humanpred.github.io/pknca/reference/PKNCA_impute_fun_list.md),
[`PKNCA_impute_method`](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md),
[`assert_impute_method()`](https://humanpred.github.io/pknca/reference/assert_impute_method.md),
[`get_impute_method()`](https://humanpred.github.io/pknca/reference/get_impute_method.md),
[`pknca_impute_methods()`](https://humanpred.github.io/pknca/reference/pknca_impute_methods.md)

## Examples

``` r
intervals <- data.frame(start = 0, end = 24, impute = "start_conc0", my_impute = "start_cmin")
get_impute_column(intervals, impute = "my_impute")
#> [1] "my_impute"
get_impute_column(intervals, impute = NA)
#> [1] "impute"
# A method string is not a column
get_impute_column(intervals, impute = "start_predose")
#> NULL
# NA without an "impute" column is not a column either
get_impute_column(intervals[, c("start", "end")], impute = NA)
#> NULL
```
