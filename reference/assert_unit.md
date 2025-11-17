# Assert that a value may either be a column name in the data (first) or a single unit value (second)

Assert that a value may either be a column name in the data (first) or a
single unit value (second)

## Usage

``` r
assert_unit_col(unit, data)

assert_unit_value(unit)

assert_unit(unit, data)
```

## Arguments

- unit:

  The column name or unit value

- data:

  The data.frame that contains a column named `unit`

## Value

`unit` with an attribute of "unit_type" that is either "column" or
"value", or `NULL` if `is.null(unit)`

## Functions

- `assert_unit_col()`: Assert that a column name contains a character
  string (that could be a unit specification)

- `assert_unit_value()`: Assert that a value may be a single unit

  The function does not verify that it is a real unit like "ng/mL" only
  that it is a single character string.
