# Check that the conversion to a data type does not change the number of NA values

Check that the conversion to a data type does not change the number of
NA values

## Usage

``` r
check.conversion(x, FUN, ...)
```

## Arguments

- x:

  the value to convert

- FUN:

  the function to use for conversion

- ...:

  arguments passed to `FUN`

## Value

`FUN(x, ...)` or an error if the set of NAs change.
