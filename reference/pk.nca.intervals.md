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
  verbose = FALSE
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

## Value

A list with elements "dense" and "sparse", each a data.frame of the NCA
results calculated from that concentration representation (or, when no
calculation was possible at all, the warning condition saying why)
