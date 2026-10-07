# Find the samples missing from each subject's nominal sampling schedule

The schedule of a group is every nominal time that has a row in the
concentration data of that group, where the group is every grouping
variable of the concentration data except the subject (for example, the
study, treatment, and analyte). Each subject of the group is expected to
have a usable concentration at every time of its group's schedule, and a
time without one is reported. Missing samples are therefore found only
when some subject of the group has a row at that nominal time; a time
that no subject has a row for is not part of the schedule. Recording a
missed sample as a row with an `NA` concentration keeps the time in the
schedule even when every subject missed it.

## Usage

``` r
pknca_missing_samples(object)
```

## Arguments

- object:

  A PKNCAconc, PKNCAdata, or PKNCAresults object (the concentration data
  of a PKNCAdata or PKNCAresults object are checked). Its concentration
  data must have a nominal time (the `time.nominal` argument of
  [`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)).

## Value

A data.frame with one row per missing sample and the columns: the
grouping columns of the concentration data other than the subject, the
subject column, the nominal time column (with the names they have in the
concentration data), and `reason`. It is sorted by those columns and has
no rows when no sample is missing.

## Details

A nominal time of a subject's schedule is reported with one of these
reasons:

- `"no row"`: the subject has no row at that nominal time.

- `"NA concentration"`: every row of the subject at that nominal time
  has an `NA` concentration.

- `"excluded"`: the subject has a concentration at that nominal time,
  but every row with one is excluded (with the `exclude` column of
  [`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
  or with
  [`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md)),
  so the calculations do not use it.

A concentration below the limit of quantification (zero) is a usable
sample. Rows with an `NA` nominal time (unscheduled samples) are not
part of any schedule, and they neither add a time to it nor fill one.
Nominal times are compared as they are, so they may be in any unit.

The nominal times must share one origin for each subject (for example,
the time since the first dose). Nominal times that restart at each dose
repeat for each dose, so one dose's samples would fill another dose's
missing times. They are found when a subject's nominal times go back to
the start of its schedule (its first nominal time after zero, or
earlier) while its actual times increase; two samples drawn out of order
are not a restart. The groups with such a subject are not reported, and
a `pknca_warning_missing_samples_nominal_restart` warning names them.

Sparse data (see the `sparse` argument of
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md))
have no schedule that each subject follows: each subject gives a few of
the group's samples by design. For sparse data, only the rows that exist
are checked (reasons `"NA concentration"` and `"excluded"`), and a
message says that absent rows are not reported.

## See also

[`exclude_nca_tmax_coverage()`](https://humanpred.github.io/pknca/reference/exclude_nca.md),
which excludes the results of a subject whose samples miss the Tmax
range of its group

Other Result exclusions:
[`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md),
[`exclude_nca`](https://humanpred.github.io/pknca/reference/exclude_nca.md),
[`pknca_exclude_rules()`](https://humanpred.github.io/pknca/reference/pknca_exclude_rules.md)

## Examples

``` r
d_conc <-
  data.frame(
    subject = rep(1:3, each = 4),
    time_nominal = rep(c(0, 1, 2, 4), 3),
    time = rep(c(0, 1, 2, 4), 3),
    conc = c(0, 5, 3, 1, 0, 4, NA, 1, 0, 6, 2, 1)
  )
# Subject 3 has no sample at 4 hours
d_conc <- d_conc[-12, ]
o_conc <- PKNCAconc(d_conc, conc ~ time | subject, time.nominal = "time_nominal")
pknca_missing_samples(o_conc)
#>   subject time_nominal           reason
#> 1       2            2 NA concentration
#> 2       3            4           no row
```
