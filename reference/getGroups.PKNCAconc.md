# Get the groups (right hand side after the `|` from a PKNCA object).

Get the groups (right hand side after the `|` from a PKNCA object).

Get the groups (right hand side after the `|` from a PKNCA object).

## Usage

``` r
# S3 method for class 'PKNCAconc'
getGroups(
  object,
  form = stats::formula(object),
  level,
  data = as.data.frame(object),
  sep
)

# S3 method for class 'PKNCAdata'
getGroups(object, ...)

# S3 method for class 'PKNCAdose'
getGroups(...)

# S3 method for class 'PKNCAresults'
getGroups(
  object,
  form = formula(object$data$conc),
  level,
  data = object$result,
  sep
)
```

## Arguments

- object:

  The object to extract the data from

- form:

  The formula to extract the data from (defaults to the formula from
  `object`)

- level:

  optional. If included, this specifies the level(s) of the groups to
  include. If a numeric scalar, include the first `level` number of
  groups. If a numeric vector, include each of the groups specified by
  the number. If a character vector, include the named group levels.

- data:

  The data to extract the groups from (defaults to the data from
  `object`)

- sep:

  Unused (kept for compatibility with the nlme package)

- ...:

  Arguments passed to other getGroups functions

## Value

A data frame with the (selected) group columns.

A data frame with the (selected) group columns.
