# dplyr grouping for PKNCA

dplyr grouping for PKNCA

## Usage

``` r
# S3 method for class 'PKNCAresults'
group_by(.data, ..., .add = FALSE, .drop = dplyr::group_by_drop_default(.data))

# S3 method for class 'PKNCAconc'
group_by(.data, ..., .add = FALSE, .drop = dplyr::group_by_drop_default(.data))

# S3 method for class 'PKNCAdose'
group_by(.data, ..., .add = FALSE, .drop = dplyr::group_by_drop_default(.data))

# S3 method for class 'PKNCAresults'
ungroup(x, ...)

# S3 method for class 'PKNCAconc'
ungroup(x, ...)

# S3 method for class 'PKNCAdose'
ungroup(x, ...)
```

## Arguments

- .data:

  A data frame, data frame extension (e.g. a tibble), or a lazy data
  frame (e.g. from dbplyr or dtplyr). See *Methods*, below, for more
  details.

- ...:

  In
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html),
  variables or computations to group by. Computations are always done on
  the ungrouped data frame. To perform computations on the grouped data,
  you need to use a separate
  [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) step
  before the
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html).
  Computations are not allowed in `nest_by()`. In
  [`ungroup()`](https://dplyr.tidyverse.org/reference/group_by.html),
  variables to remove from the grouping.

- .add:

  When `FALSE`, the default,
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
  will override existing groups. To add to the existing groups, use
  `.add = TRUE`.

  This argument was previously called `add`, but that prevented creating
  a new grouping variable called `add`, and conflicts with our naming
  conventions.

- .drop:

  Drop groups formed by factor levels that don't appear in the data? The
  default is `TRUE` except when `.data` has been previously grouped with
  `.drop = FALSE`. See
  [`group_by_drop_default()`](https://dplyr.tidyverse.org/reference/group_by_drop_default.html)
  for details.

- x:

  A [`tbl()`](https://dplyr.tidyverse.org/reference/tbl.html)

## See also

Other dplyr verbs:
[`filter.PKNCAresults()`](http://humanpred.github.io/pknca/reference/filter.PKNCAresults.md),
[`inner_join.PKNCAresults()`](http://humanpred.github.io/pknca/reference/inner_join.PKNCAresults.md),
[`mutate.PKNCAresults()`](http://humanpred.github.io/pknca/reference/mutate.PKNCAresults.md)
