# Assert Intervals

Verifies that an interval definition is valid for a PKNCAdata object.
Valid means that intervals are a data.frame (or data.frame-like object),
that the column names are either the groupings of the PKNCAconc part of
the PKNCAdata object or that they are one of the NCA parameters allowed
(i.e. names(get.interval.cols())). The column that the `impute` setting
of the PKNCAdata object names (see
[`get_impute_method()`](https://humanpred.github.io/pknca/reference/get_impute_method.md))
is also allowed, and it must be a character column, or a
`pknca_error_interval_impute_not_character` error is raised. An
`interval_id` identifies one interval: rows that share it may differ
only in the parameters they request (and `impute`), not in `start`,
`end`, or the groups, or a `pknca_error_secondary_id_conflict` error is
raised. It will return the intervals argument unchanged, or it will
raise an error.

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
