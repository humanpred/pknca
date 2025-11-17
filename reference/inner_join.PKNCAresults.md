# dplyr joins for PKNCA

dplyr joins for PKNCA

## Usage

``` r
# S3 method for class 'PKNCAresults'
inner_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAresults'
left_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAresults'
right_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAresults'
full_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAconc'
inner_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAconc'
left_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAconc'
right_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAconc'
full_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAdose'
inner_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAdose'
left_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAdose'
right_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)

# S3 method for class 'PKNCAdose'
full_join(
  x,
  y,
  by = NULL,
  copy = FALSE,
  suffix = c(".x", ".y"),
  ...,
  keep = FALSE
)
```

## Arguments

- x, y:

  A pair of data frames, data frame extensions (e.g. a tibble), or lazy
  data frames (e.g. from dbplyr or dtplyr). See *Methods*, below, for
  more details.

- by:

  A join specification created with
  [`join_by()`](https://dplyr.tidyverse.org/reference/join_by.html), or
  a character vector of variables to join by.

  If `NULL`, the default, `*_join()` will perform a natural join, using
  all variables in common across `x` and `y`. A message lists the
  variables so that you can check they're correct; suppress the message
  by supplying `by` explicitly.

  To join on different variables between `x` and `y`, use a
  [`join_by()`](https://dplyr.tidyverse.org/reference/join_by.html)
  specification. For example, `join_by(a == b)` will match `x$a` to
  `y$b`.

  To join by multiple variables, use a
  [`join_by()`](https://dplyr.tidyverse.org/reference/join_by.html)
  specification with multiple expressions. For example,
  `join_by(a == b, c == d)` will match `x$a` to `y$b` and `x$c` to
  `y$d`. If the column names are the same between `x` and `y`, you can
  shorten this by listing only the variable names, like `join_by(a, c)`.

  [`join_by()`](https://dplyr.tidyverse.org/reference/join_by.html) can
  also be used to perform inequality, rolling, and overlap joins. See
  the documentation at
  [?join_by](https://dplyr.tidyverse.org/reference/join_by.html) for
  details on these types of joins.

  For simple equality joins, you can alternatively specify a character
  vector of variable names to join by. For example, `by = c("a", "b")`
  joins `x$a` to `y$a` and `x$b` to `y$b`. If variable names differ
  between `x` and `y`, use a named character vector like
  `by = c("x_a" = "y_a", "x_b" = "y_b")`.

  To perform a cross-join, generating all combinations of `x` and `y`,
  see
  [`cross_join()`](https://dplyr.tidyverse.org/reference/cross_join.html).

- copy:

  If `x` and `y` are not from the same data source, and `copy` is
  `TRUE`, then `y` will be copied into the same src as `x`. This allows
  you to join tables across srcs, but it is a potentially expensive
  operation so you must opt into it.

- suffix:

  If there are non-joined duplicate variables in `x` and `y`, these
  suffixes will be added to the output to disambiguate them. Should be a
  character vector of length 2.

- ...:

  Other parameters passed onto methods.

- keep:

  Should the join keys from both `x` and `y` be preserved in the output?

  - If `NULL`, the default, joins on equality retain only the keys from
    `x`, while joins on inequality retain the keys from both inputs.

  - If `TRUE`, all keys from both inputs are retained.

  - If `FALSE`, only keys from `x` are retained. For right and full
    joins, the data in key columns corresponding to rows that only exist
    in `y` are merged into the key columns from `x`. Can't be used when
    joining on inequality conditions.

## See also

Other dplyr verbs:
[`filter.PKNCAresults()`](http://humanpred.github.io/pknca/reference/filter.PKNCAresults.md),
[`group_by.PKNCAresults()`](http://humanpred.github.io/pknca/reference/group_by.PKNCAresults.md),
[`mutate.PKNCAresults()`](http://humanpred.github.io/pknca/reference/mutate.PKNCAresults.md)
