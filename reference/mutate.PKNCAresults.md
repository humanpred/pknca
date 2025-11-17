# dplyr mutate-based modification for PKNCA

dplyr mutate-based modification for PKNCA

## Usage

``` r
# S3 method for class 'PKNCAresults'
mutate(.data, ...)

# S3 method for class 'PKNCAconc'
mutate(.data, ...)

# S3 method for class 'PKNCAdose'
mutate(.data, ...)
```

## Arguments

- .data:

  A data frame, data frame extension (e.g. a tibble), or a lazy data
  frame (e.g. from dbplyr or dtplyr). See *Methods*, below, for more
  details.

- ...:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Name-value pairs. The name gives the name of the column in the output.

  The value can be:

  - A vector of length 1, which will be recycled to the correct length.

  - A vector the same length as the current group (or the whole data
    frame if ungrouped).

  - `NULL`, to remove the column.

  - A data frame or tibble, to create multiple columns in the output.

## See also

Other dplyr verbs:
[`filter.PKNCAresults()`](http://humanpred.github.io/pknca/reference/filter.PKNCAresults.md),
[`group_by.PKNCAresults()`](http://humanpred.github.io/pknca/reference/group_by.PKNCAresults.md),
[`inner_join.PKNCAresults()`](http://humanpred.github.io/pknca/reference/inner_join.PKNCAresults.md)
