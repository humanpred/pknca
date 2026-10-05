# Extract the parameter results from a PKNCAresults and return them as a data.frame.

Extract the parameter results from a PKNCAresults and return them as a
data.frame.

## Usage

``` r
# S3 method for class 'PKNCAresults'
as.data.frame(
  x,
  ...,
  out_format = c("long", "wide", "cdisc"),
  filter_requested = FALSE,
  filter_excluded = FALSE,
  grpid_cols = NULL,
  grpid_numeric = NULL,
  out.format = deprecated()
)
```

## Arguments

- x:

  The object to extract results from

- ...:

  Ignored (for compatibility with generic
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html))

- out_format:

  Should the output be 'long' (default), 'wide', or 'cdisc'? When
  'cdisc', the original PKNCA parameter name is kept in a new
  `pknca_parameter` column (lowercase so it cannot be mistaken for an
  SDTM PP variable; drop it before submission), the PPTESTCD column is
  translated to CDISC standard codes, and a PPTEST column with the CDISC
  test name is added. The translation is many-to-one – several PKNCA
  parameters can resolve to the same PPTESTCD (every AUCint variant to
  "AUCINT", for example) – so `pknca_parameter` is the only column that
  still identifies which PKNCA calculation produced a row.
  Route-dependent parameters (e.g. CL, VZ, MRT) are resolved using the
  route information from the dose data.

  Each row also gets its time point reference, as SDTMIG 3.4 defines it:
  PPSTINT and PPENINT give the interval start and end as ISO 8601
  durations relative to the reference named in PPTPTREF, and PPRFTDTC
  gives that reference's date-time. The reference is the dose that
  starts the interval: the last included dose at or before the interval
  start for that subject and group (PPTPTREF
  `"LAST DOSE PRIOR TO INTERVAL"`), so a steady-state dosing interval
  reads `"PT0H"` to `"PT24H"`. A subject (or group) without an included
  dose uses its first concentration instead (PPTPTREF
  `"FIRST OBSERVATION"`), as the date-time references of
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  do. The durations are in the preferred time unit (`timeu_pref`) when
  it is given; PPENINT is `NA` for an interval to infinity, and PPSTINT,
  PPENINT, and PPTPTREF are `NA` when the subject has doses but none at
  or before the interval start. PPRFTDTC is only given when the
  concentration and dose times were date-times (see
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)),
  and it can differ between the intervals of one subject.

  PPGRPID, the record group identifier, is built from the grouping
  columns named in `grpid_cols` and the number of the row's interval, as
  `"<prefix1><value1>.<prefix2><value2>.I<nn>"` (for example
  `"A.P1.I01"`, `"P2.I01"`, or just `"I01"` without `grpid_cols`).
  Within each combination of the subject, the analyte, and the
  `grpid_cols` columns, the intervals are numbered from 1 by start and
  then end; the rows of one interval (one per parameter) share the
  number. Other grouping columns (a treatment or a matrix, for example)
  do not enter PPGRPID: they stay as their own output columns, and
  intervals with the same window in different values of them share a
  number. The number is written with at least two digits, and with as
  many as the largest interval number needs, so that the text sorts in
  time order. The numbers, the width, and the checks of the values use
  every row of the results, so `filter_requested` and `filter_excluded`
  never renumber an interval or hide a bad value; an interval with no
  rows in the results has no number. The grouping columns also remain in
  the output.

- filter_requested:

  Only return rows with parameters that were specifically requested?

- filter_excluded:

  Should excluded values be removed?

- grpid_cols:

  For `out_format = "cdisc"`, the grouping columns that prefix the
  interval number in PPGRPID: a named character vector of grouping
  columns of the
  [`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
  object, in prefix order, other than the subject and the analyte. Each
  name is a column, and each value is the text written before that
  column's value, such as `c(Part = "", Period = "P")`. The text before
  a value and the values may not contain `"."`, and a value may not be
  empty, and distinct values of a column may not give the same text.
  `NULL` (the default) uses the `grpid_cols` of the
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  object, and [`character()`](https://rdrr.io/r/base/character.html)
  gives an interval-only identifier regardless of that default.

- grpid_numeric:

  For `out_format = "cdisc"`, the names of columns in `grpid_cols` whose
  values are whole numbers of at least 1 (such as the period), which are
  written as that number, so `"01"` becomes `1`. A value that is not a
  finite whole number of at least 1 is an error. `NULL` (the default)
  uses the `grpid_numeric` of the
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  object for the columns of `grpid_cols` that it names, and
  [`character()`](https://rdrr.io/r/base/character.html) means no
  columns regardless of that default.

- out.format:

  Deprecated in favor of `out_format`

## Value

A data.frame (or usually a tibble) of results
