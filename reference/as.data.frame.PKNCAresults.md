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

- filter_requested:

  Only return rows with parameters that were specifically requested?

- filter_excluded:

  Should excluded values be removed?

- out.format:

  Deprecated in favor of `out_format`

## Value

A data.frame (or usually a tibble) of results
