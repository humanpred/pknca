# Find the dosing regimen from the dose times of one subject

The dose times are sorted and times that repeat are dropped. The regimen
is then described as one or more segments, each a stretch of dosing that
repeats over a period, found in this order:

1.  Equally spaced doses repeat over their spacing.

2.  A cycle of 2 to 4 doses per period that every dose follows is looked
    for next. The period is the median span of that many spacings,
    refined by least squares, and each dose's time within the period
    falls into one of the positions of the cycle. The spacings between
    the positions must differ from one another by more than `tol`, every
    dose must be within `snap.tol` of the period of its position, and
    every position must hold at least two doses (two complete periods).
    The positions must also explain the scatter of the doses: the doses
    sit at most half as far from their positions as the spacings sit
    from their median, and the positions fit the doses better than
    evenly spaced positions by more than chance (an F test at the 0.999
    level). Daily doses recorded a few hours early or late are therefore
    daily dosing, not a cycle. Twice-daily doses at 08:00 and 16:00
    repeat every 24 hours with offsets 0 and 8. When the period is not
    one of the given `tau.choices` and a whole number of periods is,
    that multiple is used if the doses hold two complete repeats of it
    (so a 48 hour choice selects two days of twice-daily dosing only
    when there are at least nine doses); the built-in nominal set never
    selects a longer period.

3.  Doses whose spacings are all within `tol` of their median are evenly
    spaced with scatter, and repeat over the median spacing.

4.  Otherwise, each spacing is labeled with the candidate it is within
    `tol` of (on the log scale), and the rest are clustered on the log
    scale. Doses squeezed into one interval between two runs of the
    regimen are set aside as extra doses. Runs of at least `min.run`
    spacings with one label anchor segments, and the runs must hold most
    of the spacings. A spacing outside the runs is a missed dose when it
    is a whole number (up to `max.missed`) of the segment's interval and
    is irregular when it is not; a dose given early or late is the dose
    between two irregular spacings. Neighboring anchors with the same
    label are one segment, so a change of regimen gives several
    segments.

5.  When that reading has missed or irregular doses or more than one
    segment, a cycle of 2 to 4 doses that at least 70% of the doses
    follow is used instead if it explains more spacings, or as many with
    no more missed, off-schedule, or extra doses and changes of regimen.
    This keeps three-times-daily dosing with a dose not given as three
    times daily, and daily dosing after twice-daily dosing as a change
    of regimen.

6.  If none of that fits, there is no repeating interval.

## Usage

``` r
find.dose.regimen(
  x,
  tau.choices = NULL,
  timeu = NULL,
  options = list(),
  tol = 0.2,
  snap.tol = 0.1,
  min.run = 2,
  max.missed = 4
)
```

## Arguments

- x:

  Dose times for one subject, as numbers

- tau.choices:

  The nominal intervals to match, in the unit of `x`, or `NA` to use the
  built-in set (when `timeu` is given) or none. Names are used as
  labels. `NULL` takes the `tau.choices` option.

- timeu:

  The time unit of `x` (such as `"hr"` or `"day"`), or `NULL` (or `""`)
  when it is not known. A unit that cannot be converted to hours is an
  error.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- tol:

  Relative tolerance for grouping spacings with one another and with a
  candidate

- snap.tol:

  Relative tolerance for reporting an interval as a candidate and for a
  dose to be on a cycle's pattern

- min.run:

  The fewest consecutive spacings with one label that form a segment

- max.missed:

  The largest multiple of the interval that is read as missed doses

## Value

A data frame with one row per segment and the columns:

- `segment`:

  The segment number

- `start`, `end`:

  The first and last dose time of the segment; a dose where the regimen
  changes ends one segment and starts the next

- `n_doses`:

  The number of doses in the segment

- `interval`:

  The period that the dose pattern repeats over, `NA` for a single dose
  or when nothing repeats

- `label`:

  The name of the candidate for an evenly spaced regimen with the
  segment's number of doses per period (twice-daily doses at 0 and 10
  hours are `"BID"`), or `NA`

- `source`:

  `"nominal"` when `interval` is a candidate and `"auto"` when it was
  found in the data

- `n_intervals_used`:

  The spacings that set the interval

- `n_missed`:

  Doses read as missed

- `n_irregular`:

  Doses off schedule or extra

- `note`:

  A description of anything unusual

- `offsets`:

  A list column of the dose times within one period, relative to the
  first dose of the period

With no dose times, the data frame has no rows.

## Details

The interval of a segment is snapped to the nearest candidate within
`snap.tol` (source `"nominal"`), and is otherwise the value found in the
data (source `"auto"`). The value found in the data is the median of the
spacings (or spans) that set it, so scatter in the recorded times does
not move it. The candidates are `tau.choices` when it is given.
Otherwise, when `timeu` is given, they are the built-in nominal
intervals converted from hours to `timeu`: Q4H (4 hours), QID (6), TID
(8), BID (12), QD (24), QOD (48), Q72H (72), QW (168), Q2W (336), Q3W
(504), Q4W (672), Q6W (1008), Q8W (1344), and Q12W (2016). Without
either, PKNCA cannot know what the numbers mean, so the intervals come
from the data alone and every source is `"auto"`. Converting a unit
other than `"hr"` needs the units package; without it,
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
and [`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
match only data in hours to the nominal intervals, so their results for
data in other units can differ between installations with and without
that package.

## Conditions

- `pknca_warning_tau_irregular_dosing`:

  A segment has missed doses (the message names the dose times before
  them) or doses off schedule (the message names those doses).

- `pknca_warning_tau_not_nominal`:

  There were candidates to match and a segment matched none of them. The
  message includes the regimen table.

- `pknca_warning_tau_regimen_change`:

  More than one segment was found. The message includes the regimen
  table.

- `pknca_warning_dose_regimen`:

  The parent class of the three warnings above, to handle them together.

- `pknca_error_regimen_time_unit`:

  `timeu` cannot be converted to hours.

- `pknca_error_regimen_time_class`:

  `x` is a date-time or difftime rather than a number.

## See also

[`find.tau()`](https://humanpred.github.io/pknca/reference/find.tau.md),
which gives the interval of the segment with the most doses

Other Interval determination:
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`find.tau()`](https://humanpred.github.io/pknca/reference/find.tau.md),
[`resolve_dose_tau()`](https://humanpred.github.io/pknca/reference/resolve_dose_tau.md)

## Examples

``` r
# Daily dosing with the times as recorded
find.dose.regimen(c(0, 23.6, 48, 72.4, 96), timeu = "hr")
#>   segment start end n_doses interval label  source n_intervals_used n_missed
#> 1       1     0  96       5       24    QD nominal                4        0
#>   n_irregular note offsets
#> 1           0            0
# Twice daily at breakfast and dinner repeats daily
find.dose.regimen(c(0, 10, 24, 34, 48, 58), timeu = "hr")
#>   segment start end n_doses interval label  source n_intervals_used n_missed
#> 1       1     0  58       6       24   BID nominal                5        0
#>   n_irregular note offsets
#> 1           0        0, 10
# Daily, then twice daily
suppressWarnings(
  find.dose.regimen(c(0, 24, 48, 72, 84, 96, 108, 120), timeu = "hr")
)
#>   segment start end n_doses interval label  source n_intervals_used n_missed
#> 1       1     0  72       4       24    QD nominal                3        0
#> 2       2    72 120       5       12   BID nominal                4        0
#>   n_irregular           note offsets
#> 1           0 regimen change       0
#> 2           0 regimen change       0
```
