# Assert that a lambda.z value is valid

Assert that a lambda.z value is valid

## Usage

``` r
assert_lambdaz(
  lambda.z,
  any.missing = TRUE,
  .var.name = checkmate::vname(lambda.z)
)
```

## Arguments

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- any.missing:

  \[`logical(1)`\]  
  Are vectors with missing values allowed? Default is `TRUE`.

- .var.name:

  \[`character(1)`\]  
  Name of the checked object to print in assertions. Defaults to the
  heuristic implemented in
  [`vname`](https://mllg.github.io/checkmate/reference/vname.html).

## Value

`lambda.z` or an informative error
