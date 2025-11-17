# Find the repeating interval within a vector of doses

This is intended to find the interval over which x repeats by the rule
`unique(mod(x, interval))` is minimized.

## Usage

``` r
find.tau(x, na.action = stats::na.omit, options = list(), tau.choices = NULL)
```

## Arguments

- x:

  the vector to find the interval within

- na.action:

  What to do with NAs in `x`

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- tau.choices:

  the intervals to look for if the doses are not all equally spaced.

## Value

A scalar indicating the repeating interval with the most repetition.

1.  If all values are `NA` then NA is returned.

2.  If all values are the same, then 0 is returned.

3.  If all values are equally spaced, then that spacing is returned.

4.  If one of the `choices` can minimize the number of unique values,
    then that is returned.

5.  If none of the `choices` can minimize the number of unique values,
    then -1 is returned.

## See also

Other Interval determination:
[`choose.auc.intervals()`](http://humanpred.github.io/pknca/reference/choose.auc.intervals.md)
