# Extract the columns used in the formula (in order) from a PKNCAconc or PKNCAdose object.

Extract the columns used in the formula (in order) from a PKNCAconc or
PKNCAdose object.

## Usage

``` r
# S3 method for class 'PKNCAconc'
model.frame(formula, ...)

# S3 method for class 'PKNCAdose'
model.frame(formula, ...)
```

## Arguments

- formula:

  The object to use (parameter name is `formula` to use the generic
  function)

- ...:

  Unused

## Value

A data frame with the columns from the object in formula order.
