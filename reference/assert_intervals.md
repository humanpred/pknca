# Assert Intervals

Verifies that an interval definition is valid for a PKNCAdata object.
Valid means that intervals are a data.frame (or data.frame-like object),
that the column names are either the groupings of the PKNCAconc part of
the PKNCAdata object or that they are one of the NCA parameters allowed
(i.e. names(get.interval.cols())). An `interval_id` identifies one
interval: rows that share it may differ only in the parameters they
request (and `impute`), not in `start`, `end`, or the groups, or a
`pknca_error_secondary_id_conflict` error is raised. It will return the
intervals argument unchanged, or it will raise an error.

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
