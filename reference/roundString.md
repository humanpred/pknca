# Round a value to a defined number of digits printing out trailing zeros, if applicable.

Round a value to a defined number of digits printing out trailing zeros,
if applicable.

## Usage

``` r
roundString(x, digits = 0, sci_range = Inf, sci_sep = "e", si_range)
```

## Arguments

- x:

  The number to round

- digits:

  integer indicating the number of decimal places

- sci_range:

  See help for
  [`signifString()`](http://humanpred.github.io/pknca/reference/signifString.md)
  (and you likely want to round with `signifString` if you want to use
  this argument)

- sci_sep:

  The separator to use for scientific notation strings (typically this
  will be either "e" or "x10^" for computer- or human-readable output).

- si_range:

  Deprecated, please use `sci_range`

## Value

A string with the value

## Details

Values that are not standard numbers like `Inf`, `NA`, and `NaN` are
returned as `"Inf"`, `"NA"`, and `NaN`.

## See also

[`round()`](https://rdrr.io/r/base/Round.html),
[`signifString()`](http://humanpred.github.io/pknca/reference/signifString.md)
