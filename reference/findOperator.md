# Find the first occurrence of an operator in a formula and return the left, right, or both sides of the operator.

Find the first occurrence of an operator in a formula and return the
left, right, or both sides of the operator.

## Usage

``` r
findOperator(x, op, side)
```

## Arguments

- x:

  The formula to parse

- op:

  The operator to search for (e.g. `+`, `-`, `*`, `/`, ...)

- side:

  Which side of the operator would you like to see: 'left', 'right', or
  'both'.

## Value

The side of the operator requested, NA if requesting the left side of a
unary operator, and NULL if the operator is not found.

## See also

Other Formula parsing:
[`parse_formula_to_cols()`](http://humanpred.github.io/pknca/reference/parse_formula_to_cols.md)
