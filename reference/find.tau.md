# Find the repeating interval within a vector of doses

The dose times are sorted and times that repeat are dropped, so the
order they arrive in and a dose recorded twice do not change the answer.
The interval is then found in this order:

1.  If all values are `NA`, or there are no values, `NA` is returned.

2.  If all values are the same, then 0 is returned.

3.  If all doses are equally spaced, that spacing is returned. Two doses
    give the spacing between them.

4.  Otherwise each candidate interval is tested, smallest first, and the
    first one that the whole pattern of doses repeats over is returned.
    The candidates are `tau.choices` when it is given and every spacing
    between two doses when it is `NA`. The pattern must repeat over at
    least two complete intervals, so a regimen giving more than one dose
    per interval is found while a length that merely spans the doses is
    not.

5.  If nothing repeats, and every spacing is a whole number of the
    smallest spacing, and the smallest spacing is seen twice in a row,
    the smallest spacing is returned with a
    `"pknca_warning_tau_irregular_dosing"` warning naming the longer
    gaps, which are what a missed dose looks like.

6.  If none of that fits, `NA` is returned.
    [`resolve_dose_tau()`](https://humanpred.github.io/pknca/reference/resolve_dose_tau.md)
    turns that into a warning where a dosing interval is required.

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
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- tau.choices:

  the intervals to look for if the doses are not all equally spaced.
  `NA` (the default) tests every spacing between two doses.

## Value

A scalar indicating the repeating interval, or `NA` when no interval
fits the doses.

## Details

Looking for a repeating pattern before reading anything as a missed dose
is what keeps a regimen with a regular gap in it, such as dosing three
times a day at 0, 6, and 12 hours, from being reported as a 6 hour
interval with a dose missing overnight.

## See also

Other Interval determination:
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`resolve_dose_tau()`](https://humanpred.github.io/pknca/reference/resolve_dose_tau.md)

## Examples

``` r
# Equally spaced doses give their spacing
find.tau(c(0, 24, 48, 72))
#> [1] 24
# Twice-daily dosing repeats daily although no two doses are a day apart
find.tau(c(0, 10, 24, 34, 48, 58), tau.choices = c(12, 24))
#> [1] 24
```
