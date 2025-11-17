# Assert Intervals

Verifies that an interval definition is valid for a PKNCAdata object.
Valid means that intervals are a data.frame (or data.frame-like object),
that the column names are either the groupings of the PKNCAconc part of
the PKNCAdata object or that they are one of the NCA parameters allowed
(i.e. names(get.interval.cols())). It will return the intervals argument
unchanged, or it will raise an error.

## Usage

``` r
assert_intervals(intervals, data)
```

## Arguments

- intervals:

  Proposed intervals

- data:

  PKNCAdata object

## Value

The intervals argument unchanged, or it will raise an error.
