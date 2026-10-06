# Convert a difftime to a number in a time unit

`pknca_difftime_to_unit()` expresses a duration in the time unit of an
analysis, such as a collection duration that is the difference of two
date-times, so that it can be used with
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
and
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
times and durations given in that unit. The same conversion turns
date-times and `difftime` durations into numbers in
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md).

## Usage

``` r
pknca_difftime_to_unit(x, unit)
```

## Arguments

- x:

  A `difftime` vector (`NA` values stay `NA`, and a zero-length vector
  gives a zero-length result)

- unit:

  The time unit to express `x` in, a single string such as `"hr"` or
  `"day"`

## Value

A numeric vector the length of `x`: the duration in `unit`, with no unit
or other attributes

## Details

A `difftime` of any of its units (seconds, minutes, hours, days, or
weeks) is converted exactly, through seconds. `unit` may be any time
unit that the units package knows, such as `"hr"`, `"min"`, `"day"`, or
`"week"`. Hours (`"hr"`) need no conversion, so they work without the
units package; every other unit needs the units package installed, which
stops with an error from rlang if it is missing.

To convert a number that is not a `difftime`, say its unit first with
[`base::as.difftime()`](https://rdrr.io/r/base/difftime.html).

## Errors

An `x` that is not a `difftime` stops with the class
`pknca_error_difftime_not_difftime`, because a plain number has no unit
to convert from. A `unit` that is not a single string, or that is not a
time unit the units package can convert hours to, stops with the class
`pknca_error_difftime_unit`.

## Examples

``` r
# Hours need no conversion beyond the difftime's own unit
pknca_difftime_to_unit(as.difftime(90, units = "mins"), unit = "hr")
#> [1] 1.5
# Any other unit needs the units package
pknca_difftime_to_unit(as.difftime(36, units = "hours"), unit = "day")
#> [1] 1.5
# The difference of two date-times
start <- as.POSIXct("2026-10-05 08:00:00", tz = "UTC")
end <- as.POSIXct("2026-10-05 20:30:00", tz = "UTC")
pknca_difftime_to_unit(difftime(end, start), unit = "min")
#> [1] 750
```
