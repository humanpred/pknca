# Confirm that a value is greater than another value

Confirm that a value is greater than another value

## Usage

``` r
assert_numeric_between(
  x,
  any.missing = FALSE,
  null.ok = FALSE,
  lower_eq = -Inf,
  lower = -Inf,
  upper = Inf,
  upper_eq = Inf,
  ...,
  .var.name = checkmate::vname(x)
)
```

## Arguments

- x:

  \[`any`\]  
  Object to check.

- any.missing:

  \[`logical(1)`\]  
  Are vectors with missing values allowed? Default is `TRUE`.

- null.ok:

  \[`logical(1)`\]  
  If set to `TRUE`, `x` may also be `NULL`. In this case only a type
  check of `x` is performed, all additional checks are disabled.

- lower_eq, upper_eq:

  Values where equality is not allowed

- lower:

  \[`numeric(1)`\]  
  Lower value all elements of `x` must be greater than or equal to.

- upper:

  \[`numeric(1)`\]  
  Upper value all elements of `x` must be lower than or equal to.

- ...:

  Passed to
  [`checkmate::assert_numeric()`](https://mllg.github.io/checkmate/reference/checkNumeric.html)

- .var.name:

  \[`character(1)`\]  
  Name of the checked object to print in assertions. Defaults to the
  heuristic implemented in
  [`vname`](https://mllg.github.io/checkmate/reference/vname.html).

## Value

`x`
