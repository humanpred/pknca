# Exclude data points or results from calculations or summarization.

Exclude data points or results from calculations or summarization.

## Usage

``` r
exclude(object, reason, mask, FUN)

# Default S3 method
exclude(object, reason, mask, FUN)
```

## Arguments

- object:

  The object to exclude data from.

- reason:

  The reason to add as a reason for exclusion.

- mask:

  A logical vector or numeric index of values to exclude (see details).

- FUN:

  A function to operate on the data (one group at a time) to select
  reasons for exclusions (see details).

## Value

The object with updated information in the exclude column. The exclude
column will contain the `reason` if `mask` or `FUN` indicate. If a
previous reason for exclusion was given, then subsequent reasons for
exclusion will be added to the first with a semicolon space ("; ")
separator.

## Details

Only one of `mask` or `FUN` may be given. If `FUN` is given, it will be
called with two arguments: a data.frame (or similar object) that
consists of a single group of the data and the full object (e.g. the
PKNCAconc object), `FUN(current_group, object)`, and it must return a
logical vector equivalent to `mask` or a character vector with the
reason text given when data should be excluded or `NA_character_` when
the data should be included (for the current exclusion test).

## Methods (by class)

- `exclude(default)`: The general case for data exclusion

## See also

Other Result exclusions:
[`exclude_nca`](http://humanpred.github.io/pknca/reference/exclude_nca.md)

## Examples

``` r
myconc <- PKNCAconc(data.frame(subject=1,
                               time=0:6,
                               conc=c(1, 2, 3, 2, 1, 0.5, 0.25)),
                    conc~time|subject)
exclude(myconc,
        reason="Carryover",
        mask=c(TRUE, rep(FALSE, 6)))
#> Formula for concentration:
#>  conc ~ time | subject
#> <environment: 0x5589cb8413a0>
#> Data are dense PK.
#> With 1 subjects defined in the 'subject' column.
#> Nominal time column is not specified.
#> 
#> First 6 rows of concentration data:
#>  subject time conc   exclude volume duration
#>        1    0  1.0 Carryover     NA        0
#>        1    1  2.0      <NA>     NA        0
#>        1    2  3.0      <NA>     NA        0
#>        1    3  2.0      <NA>     NA        0
#>        1    4  1.0      <NA>     NA        0
#>        1    5  0.5      <NA>     NA        0
```
