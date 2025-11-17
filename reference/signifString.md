# Round a value to a defined number of significant digits printing out trailing zeros, if applicable.

Round a value to a defined number of significant digits printing out
trailing zeros, if applicable.

## Usage

``` r
signifString(x, ...)

# S3 method for class 'data.frame'
signifString(x, ...)

# Default S3 method
signifString(x, digits = 6, sci_range = 6, sci_sep = "e", si_range, ...)
```

## Arguments

- x:

  The number to round

- ...:

  Arguments passed to methods.

- digits:

  integer indicating the number of significant digits

- sci_range:

  integer (or `Inf`) indicating when to switch to scientific notation
  instead of floating point. Zero indicates always use scientific; `Inf`
  indicates to never use scientific notation; otherwise, scientific
  notation is used when `abs(log10(x)) > si_range`.

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

[`signif()`](https://rdrr.io/r/base/Round.html),
[`roundString()`](http://humanpred.github.io/pknca/reference/roundString.md)
