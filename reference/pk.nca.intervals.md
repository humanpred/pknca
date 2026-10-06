# Compute NCA for multiple intervals

Compute NCA for multiple intervals

## Usage

``` r
pk.nca.intervals(
  data_conc,
  data_dose,
  data_intervals,
  options,
  impute,
  data_sparse_conc = NULL,
  verbose = FALSE,
  timeu = NULL,
  warning_prefix = ""
)
```

## Arguments

- data_conc:

  A data.frame or tibble with standardized column names as output from
  `prepare_PKNCAconc()`. With sparse PK this is the arithmetic-mean
  profile.

- data_dose:

  A data.frame or tibble with standardized column names as output from
  `prepare_PKNCAdose()`

- data_intervals:

  A data.frame or tibble with standardized column names as output from
  `prepare_PKNCAintervals()`

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- impute:

  The column name in `data_intervals` to use for imputation

- data_sparse_conc:

  For sparse PK, a data.frame or tibble of the pooled individual samples
  (including a `subject` column) as output from `prepare_PKNCAconc()`;
  `NULL` for dense PK

- verbose:

  Indicate, by [`message()`](https://rdrr.io/r/base/message.html), the
  current state of calculation.

- timeu:

  The time unit of the group's times, or `NULL` when it is not known. A
  \\\tau\\ detected from the dose times is matched to the nominal dosing
  intervals for that unit (see
  [`find.tau()`](https://humanpred.github.io/pknca/reference/find.tau.md)).

- warning_prefix:

  The text naming the group, put before each dose regimen warning

## Value

A list with elements "dense" and "sparse", each a data.frame of the NCA
results calculated from that concentration representation (or, when no
calculation was possible at all, the warning condition saying why)
