# Get the imputation methods for the intervals

`get_impute_method()` is the rule
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md) uses
to find the imputation methods for each interval, from the `impute`
argument of
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
and the intervals. It reads `impute` one of three ways, in this order:

## Usage

``` r
get_impute_method(intervals, impute)
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

A character vector of imputation specifications: one per row of
`intervals` when read from a column, and of length one otherwise (the
method string, or `NA_character_` for no imputation). A column that is
not character is an error, except that a column of only `NA` (which is
logical when made with `NA`) is read as no imputation.

## Details

1.  If `impute` is the name of a column in `intervals`, the methods are
    that column's values, one per interval. The name may be any column
    name, not only `"impute"`.

2.  Otherwise, if `impute` is `NA` and `intervals` has a column named
    `"impute"`, the methods are that column's values, one per interval.

3.  Otherwise `impute` is itself the method (or comma- or
    space-separated methods) for every interval, and the result is
    `impute` as a single value. An `NA` that finds no `"impute"` column
    therefore gives a single `NA_character_`, meaning no imputation.

`get_impute_method()` only reads the specification. It does not check
that the methods exist;
[`assert_impute_method()`](https://humanpred.github.io/pknca/reference/assert_impute_method.md)
does.

## See also

Other Imputation:
[`PKNCA_impute_fun_list()`](https://humanpred.github.io/pknca/reference/PKNCA_impute_fun_list.md),
[`PKNCA_impute_method`](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md),
[`assert_impute_method()`](https://humanpred.github.io/pknca/reference/assert_impute_method.md),
[`pknca_impute_methods()`](https://humanpred.github.io/pknca/reference/pknca_impute_methods.md)

## Examples

``` r
intervals <- data.frame(start = 0, end = 24, impute = "start_conc0")
# The column named by `impute`
get_impute_method(intervals, impute = "impute")
#> [1] "start_conc0"
# NA finds the column named "impute"
get_impute_method(intervals, impute = NA)
#> [1] "start_conc0"
# NA without an "impute" column means no imputation
get_impute_method(intervals[, c("start", "end")], impute = NA)
#> [1] NA
# Anything else is the method for every interval
get_impute_method(intervals, impute = "start_predose")
#> [1] "start_predose"
```
