# dplyr filtering for PKNCA

dplyr filtering for PKNCA

## Usage

``` r
# S3 method for class 'PKNCAresults'
filter(.data, ..., .preserve = FALSE)

# S3 method for class 'PKNCAconc'
filter(.data, ..., .preserve = FALSE)

# S3 method for class 'PKNCAdose'
filter(.data, ..., .preserve = FALSE)
```

## Arguments

- .data:

  A data frame, data frame extension (e.g. a tibble), or a lazy data
  frame (e.g. from dbplyr or dtplyr). See *Methods*, below, for more
  details.

- ...:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Expressions that return a logical value, and are defined in terms of
  the variables in `.data`. If multiple expressions are included, they
  are combined with the `&` operator. Only rows for which all conditions
  evaluate to `TRUE` are kept.

- .preserve:

  Relevant when the `.data` input is grouped. If `.preserve = FALSE`
  (the default), the grouping structure is recalculated based on the
  resulting data, otherwise the grouping is kept as is.

## See also

Other dplyr verbs:
[`group_by.PKNCAresults()`](http://humanpred.github.io/pknca/reference/group_by.PKNCAresults.md),
[`inner_join.PKNCAresults()`](http://humanpred.github.io/pknca/reference/inner_join.PKNCAresults.md),
[`mutate.PKNCAresults()`](http://humanpred.github.io/pknca/reference/mutate.PKNCAresults.md)
