# Compute NCA for multiple intervals

Compute NCA for multiple intervals

## Usage

``` r
pk.nca.intervals(
  data_conc,
  data_dose,
  data_intervals,
  sparse,
  options,
  impute,
  verbose = FALSE
)
```

## Arguments

- data_conc:

  A data.frame or tibble with standardized column names as output from
  `prepare_PKNCAconc()`

- data_dose:

  A data.frame or tibble with standardized column names as output from
  `prepare_PKNCAdose()`

- data_intervals:

  A data.frame or tibble with standardized column names as output from
  `prepare_PKNCAintervals()`

- sparse:

  Should only sparse calculations be performed (TRUE) or only dense
  calculations (FALSE)?

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- impute:

  The column name in `data_intervals` to use for imputation

- verbose:

  Indicate, by [`message()`](https://rdrr.io/r/base/message.html), the
  current state of calculation.

## Value

A data.frame with all NCA results
