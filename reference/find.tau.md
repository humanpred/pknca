# Find the repeating interval within a vector of doses

The regimen is found with
[`find.dose.regimen()`](https://humanpred.github.io/pknca/reference/find.dose.regimen.md),
and the interval is the period of its segment with the most doses (the
latest of those when segments tie). In brief, the dose times are sorted
and times that repeat are dropped; equally spaced doses give their
spacing; a pattern of more than one dose per interval that repeats over
at least two complete intervals gives the interval it repeats over;
doses scattered within a tolerance of one spacing give their median
spacing; and otherwise runs of the same spacing form the regimen, with
the gaps between them read as missed doses (a whole number of intervals)
or doses off schedule. Times are compared on the log scale within `tol`
and `snap.tol` of
[`find.dose.regimen()`](https://humanpred.github.io/pknca/reference/find.dose.regimen.md),
so a dose recorded at 23.6 hours is a daily dose.

## Usage

``` r
find.tau(
  x,
  na.action = stats::na.omit,
  options = list(),
  tau.choices = NULL,
  timeu = NULL
)
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

  The nominal intervals to match, in the unit of `x`, or `NA` to use the
  built-in set. Names are used as labels. `NULL` takes the `tau.choices`
  option.

- timeu:

  The time unit of `x` (such as `"hr"` or `"day"`); `NULL` (or `""`)
  when it is not known, which is taken to be hours; or `NA` when it is
  known not to be a unit PKNCA can use, which leaves the intervals to
  the data. Any other unit that cannot be converted to hours is an
  error.

## Value

`NA` when there are no dose times or no interval repeats, 0 for a single
dose time, and otherwise the repeating interval.

## Details

Looking for a repeating pattern before reading anything as a missed dose
is what keeps a regimen with a regular gap in it, such as dosing three
times a day at 0, 6, and 12 hours, from being reported as a 6 hour
interval with a dose missing overnight.

The intervals are matched to `tau.choices` when it is given. When it is
`NA` (the default), they are matched to the built-in nominal intervals
listed in
[`find.dose.regimen()`](https://humanpred.github.io/pknca/reference/find.dose.regimen.md),
in the unit `timeu`. **Without a time unit, the times are taken to be
hours**, so `find.tau(c(0, 24, 50))` is 24 (once daily) rather than the
median spacing of 25; times in another unit should give `timeu`, or they
are compared with intervals in hours and an interval that matches none
of them gives a `"pknca_warning_tau_not_nominal"` warning. The warnings
of
[`find.dose.regimen()`](https://humanpred.github.io/pknca/reference/find.dose.regimen.md)
are given here as well, notably `"pknca_warning_tau_irregular_dosing"`
for missed doses or doses off schedule.

## See also

Other Interval determination:
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`find.dose.regimen()`](https://humanpred.github.io/pknca/reference/find.dose.regimen.md),
[`resolve_dose_tau()`](https://humanpred.github.io/pknca/reference/resolve_dose_tau.md)

## Examples

``` r
# Equally spaced doses give their spacing
find.tau(c(0, 24, 48, 72))
#> [1] 24
# Twice-daily dosing repeats daily although no two doses are a day apart
find.tau(c(0, 10, 24, 34, 48, 58), tau.choices = c(12, 24))
#> [1] 24
# Dose times as recorded, with the unit known
find.tau(c(0, 23.6, 48, 72.4, 96), timeu = "hr")
#> [1] 24
```
