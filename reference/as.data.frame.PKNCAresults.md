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
  route information from the dose data. When the concentration and dose
  times were date-times (see
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)),
  a PPRFTDTC column gives the ISO 8601 date-time of the time reference
  (the first dose of the group).

- filter_requested:

  Only return rows with parameters that were specifically requested?

- filter_excluded:

  Should excluded values be removed?

- out.format:

  Deprecated in favor of `out_format`

## Value

A data.frame (or usually a tibble) of results
