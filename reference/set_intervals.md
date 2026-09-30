# Set Intervals

Takes in two objects, the PKNCAdata object and the proposed intervals.
It will then check that the intervals are valid, given the data object.
If the intervals are valid, it will set them in the object. It will
return the data object with the intervals set.

## Usage

``` r
set_intervals(data, intervals)
```

## Arguments

- data:

  PKNCAdata object

- intervals:

  Proposed intervals

## Value

The data object with the intervals set.

## Details

With date-time data, `start` and `end` may be date-times; they are kept
as given and converted to numeric time relative to each group's time
reference by
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md) (see
the "Date-time input" section of
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)).
