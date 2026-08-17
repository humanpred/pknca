# Get the impute function from either the intervals column or from the method

Get the impute function from either the intervals column or from the
method

## Usage

``` r
get_impute_method(intervals, impute)
```

## Arguments

- intervals:

  the data.frame of intervals

- impute:

  the imputation definition – either the name of a column in `intervals`
  (character scalar) or `NA` to look for a generic `"impute"` column.
  Must be an atomic scalar; a list (even of length 1) is rejected.

## Value

The imputation function vector
