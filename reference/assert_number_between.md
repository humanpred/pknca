# Confirm that a value is greater than another value

Confirm that a value is greater than another value

## Usage

``` r
assert_number_between(
  x,
  ...,
  na.ok = FALSE,
  len = 1,
  .var.name = checkmate::vname(x)
)
```

## Arguments

- x:

  \[`any`\]  
  Object to check.

- ...:

  Passed to
  [`assert_numeric_between()`](http://humanpred.github.io/pknca/reference/assert_numeric_between.md)

- na.ok:

  \[`logical(1)`\]  
  Are missing values allowed? Default is `FALSE`.

- len:

  Ignored (must be 1)

- .var.name:

  \[`character(1)`\]  
  Name of the checked object to print in assertions. Defaults to the
  heuristic implemented in
  [`vname`](https://mllg.github.io/checkmate/reference/vname.html).

## Value

`x` or an informative error
