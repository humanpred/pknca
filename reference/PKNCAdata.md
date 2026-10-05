# Create a PKNCAdata object.

`PKNCAdata()` combines `PKNCAconc` and `PKNCAdose` objects and adds in
the intervals for PK calculations.

## Usage

``` r
PKNCAdata(data.conc, data.dose, ...)

# S3 method for class 'PKNCAconc'
PKNCAdata(data.conc, data.dose, ...)

# S3 method for class 'PKNCAdose'
PKNCAdata(data.conc, data.dose, ...)

# Default S3 method
PKNCAdata(
  data.conc,
  data.dose,
  ...,
  formula.conc,
  formula.dose,
  impute = NA_character_,
  intervals,
  units,
  options = list(),
  group_ref = NULL,
  grpid_cols = NULL,
  grpid_numeric = NULL
)
```

## Arguments

- data.conc:

  Concentration data as a `PKNCAconc` object or a data frame

- data.dose:

  Dosing data as a `PKNCAdose` object (see details)

- ...:

  arguments passed to `PKNCAdata.default`

- formula.conc:

  Formula for making a `PKNCAconc` object with `data.conc`. This must be
  given if `data.conc` is a data.frame, and it must not be given if
  `data.conc` is a `PKNCAconc` object.

- formula.dose:

  Formula for making a `PKNCAdose` object with `data.dose`. This must be
  given if `data.dose` is a data.frame, and it must not be given if
  `data.dose` is a `PKNCAdose` object.

- impute:

  Methods for imputation. `NA` for to search for the column named
  "impute" in the intervals or no imputation if that column does not
  exist, a comma-or space-separated list of names, or the name of a
  column in the `intervals` data.frame (any column name works, not only
  `"impute"`, and the column must be character).
  [`get_impute_method()`](https://humanpred.github.io/pknca/reference/get_impute_method.md)
  gives the exact rule. See
  [`vignette("v08-data-imputation", package="PKNCA")`](https://humanpred.github.io/pknca/articles/v08-data-imputation.md)
  for more details.

- intervals:

  A data frame with the AUC interval specifications as defined in
  [`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md).
  If missing, this will be automatically chosen by
  [`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md).
  (see details) With date-time data, `start` and `end` may be date-times
  (see the "Date-time input" section).

- units:

  A data.frame of unit assignments and conversions as created by
  [`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md)

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- group_ref:

  The reference profiles for automatically-linked secondary parameters,
  as a data.frame of group values, optionally parameter-specific (see
  Details). `NULL` (the default) derives the reference from the data.

- grpid_cols:

  The grouping columns that prefix the interval number in the PPGRPID
  column of `as.data.frame(results, out_format = "cdisc")`, as a named
  character vector of
  [`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
  grouping columns (other than the subject and analyte), each with the
  text written before its value (see
  [`as.data.frame.PKNCAresults()`](https://humanpred.github.io/pknca/reference/as.data.frame.PKNCAresults.md)).
  It is the default for the `grpid_cols` argument there, so every output
  of one analysis agrees. `NULL` (the default) gives an interval-only
  identifier.

- grpid_numeric:

  The names of the columns in `grpid_cols` whose values are whole
  numbers of at least 1, such as the period, written as that number in
  PPGRPID. It is the default for the `grpid_numeric` argument of
  [`as.data.frame.PKNCAresults()`](https://humanpred.github.io/pknca/reference/as.data.frame.PKNCAresults.md).
  `NULL` (the default) names no columns.

## Value

A PKNCAdata object with concentration, dose, interval, and calculation
options stored (note that PKNCAdata objects can also have results after
a NCA calculations are done to the data).

## Details

If `data.dose` is not given or is `NA`, then the `intervals` must be
given. At least one of `data.dose` and `intervals` must be given.

A secondary parameter is calculated from a result in another interval,
and the interval specification links the two with an `interval_id`
column and a `<parameter>_ref` pointer (see
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md)).
An `interval_id` identifies one interval: rows that share it (an
interval split by imputation, for example) may differ only in the
parameters they request, never in `start`, `end`, or the groups. Where a
request has no pointer and could not otherwise be calculated,
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
derives the reference profile from the data: a parameter measured on an
interval collection whose inputs are spot samples (renal clearance)
takes the nearest profile with no collection volume, and `group_ref`
restricts – or, for anything else, supplies – the profiles that may be
used. The derived reference interval is created for the calculation only
and is not added to the intervals in the result. When more than one
profile is equally close, the affected results are `NA` with the reason
in the `exclude` column and a `pknca_warning_secondary_auto_reference`
warning.

`group_ref` takes three forms. A data.frame of group values applies to
every secondary parameter: its columns must be group columns of the
concentration data, every column must match (and) for at least one of
its rows (or), and every value must appear in the data – for example,
with groups crossing `TRTP`, `PCTEST`, and `PCSPEC`,
`group_ref = data.frame(PCSPEC = "PLASMA")` directs renal-clearance
references to the plasma profiles and
`group_ref = data.frame(PCTEST = "midazolam")` directs metabolite ratios
to the parent analyte. The same data.frame with a `parameter` column
applies each row only to the secondary parameter it names, and the
columns a parameter's rows leave `NA` do not apply to it, so one table
can steer renal clearance by `PCSPEC` and a metabolite ratio by
`PCTEST`:
`group_ref = data.frame(parameter = c("clr.obs", "ratio.aucinf.obs"), PCSPEC = c("PLASMA", NA), PCTEST = c(NA, "midazolam"))`.
A named list of data.frames, one per parameter, says the same thing:
`group_ref = list(clr.obs = data.frame(PCSPEC = "PLASMA"), ratio.aucinf.obs = data.frame(PCTEST = "midazolam"))`.

## Date-time input

The concentration and dose times may be date-times (POSIXct) or dates
(Date). `PKNCAdata()` checks them and keeps them as they are, and
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
converts them to numeric time before it calculates, so the intervals can
still be changed after `PKNCAdata()`:

- The time reference is the first dose (ignoring excluded doses) within
  each combination of the grouping variables (and the subject) shared by
  the concentration and dose formulas. With `dose~time|Part+Subject`,
  each subject's first dose in each study part (or period, for a
  crossover) is time 0; with `dose~time|Subject`, each subject's first
  dose of the study is time 0. The dose formula must include the
  subject, so that one reference is never shared by several subjects.

- A subject (group) without an included dose time uses its first
  concentration (the first one not excluded) as the reference, with a
  warning. Without dosing data, every reference is the first
  concentration, within each combination of the concentration grouping
  variables to the left of any `/` (so analytes share their subject's
  reference).

- Sparse data use one reference per group rather than per subject,
  because every subject in a sparse group shares the group's dosing.

- Numeric time is in the time unit of the
  [`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
  object: `timeu_pref` when given, otherwise `timeu`, otherwise hours
  (without units). Numeric concentration collection and dosing durations
  are in that unit, and difftime durations are converted to it.

- Manually specified `intervals` may be numeric times relative to the
  time reference, in that unit, or date-times. Date-time `start` and
  `end` (POSIXct, or Date for 08:00, with a warning) are converted
  relative to the reference of the group each row applies to. A row that
  does not name every reference group (for example, a row without
  `Subject`) applies to every matching group and becomes one row per
  group, because one absolute window is a different relative window for
  each subject. A date-time `start` may pair with `end = Inf` (or a
  POSIXct `Inf`), which stays infinite; the start must be finite, both
  bounds must otherwise be date-times, and the time zone must match the
  data. `PKNCAdata()` and
  [`set_intervals()`](https://humanpred.github.io/pknca/reference/set_intervals.md)
  check date-time intervals, and
  [`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
  converts them; converted intervals have an `interval_time_kind` column
  (`"datetime"`, or `"relative"` for numeric rows added later). The
  conversion gives the window only: a window starting before a subject's
  first measurement still needs an imputation rule (`impute`) for a
  concentration at its start.

- The results of
  [`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
  keep the converted data that the calculation used (`results$data`),
  with the time reference of each group in its `time_reference` element
  and the `time_reference_type` column saying whether it is the
  `"first_dose"` or the `"first_conc"`;
  `as.data.frame(results, out_format = "cdisc")` gives, in the PPRFTDTC
  column, the date-time of the reference of each row: the dose that
  starts its interval, or the first concentration for a `"first_conc"`
  group (see
  [`as.data.frame.PKNCAresults()`](https://humanpred.github.io/pknca/reference/as.data.frame.PKNCAresults.md)).

Both times must be date-times (or dates), not one numeric and one
date-time; date-times must have the same time zone; and the dose formula
must include the subject of dense data. Otherwise, it is an error.
Differences are elapsed time, so a change to or from daylight saving
time is handled correctly when the time zone is a named zone (like
`"America/New_York"`).

## See also

[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md),
[`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md)

Other PKNCA objects:
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md),
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md),
[`PKNCAresults()`](https://humanpred.github.io/pknca/reference/PKNCAresults.md)
