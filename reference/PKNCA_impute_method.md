# Methods for imputation of data with PKNCA

Methods for imputation of data with PKNCA

## Usage

``` r
PKNCA_impute_method_start_conc0(conc, time, start = 0, ..., options = list())

PKNCA_impute_method_start_cmin(conc, time, start, end, ..., options = list())

PKNCA_impute_method_start_predose(
  conc,
  time,
  start,
  end,
  conc.group,
  time.group,
  ...,
  max_shift = NA_real_,
  options = list()
)

PKNCA_impute_method_end_conc_drop(conc, time, end, ..., options = list())
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- start:

  The start time of the interval

- ...:

  ignored

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- end:

  The end time of the interval

- conc.group:

  All concentrations measured for the group

- time.group:

  Time of all concentrations measured for the group

- max_shift:

  The maximum amount of time to shift a concentration forward (defaults
  to 5% of the interval duration, i.e. `0.05*(end - start)`, if
  `is.finite(end)`, and when `is.infinite(end)`, defaults to 5% of the
  time from start to `max(time)`)

## Value

A data.frame with one column named conc with imputed concentrations and
one column named time with the times.

## Functions

- `PKNCA_impute_method_start_conc0()`: Set the concentration at the
  start time to 0, even if a nonzero concentration exists at that time
  (usually used with single-dose data). Forcing the start concentration
  to zero is intentional: an existing start-time value is replaced with
  0, including a nonzero predose measurement shifted to the start time
  by `start_predose`, so the imputation chain
  `"start_predose,start_conc0"` gives the same result as `"start_conc0"`
  alone. To carry a predose measurement to the start time, use
  `start_predose` without `start_conc0`. When no observation exists at
  the start time, a new row with a concentration of 0 is added.

- `PKNCA_impute_method_start_cmin()`: Add a new concentration of the
  minimum during the interval at the start time (usually used with
  multiple-dose data)

- `PKNCA_impute_method_start_predose()`: Shift a predose concentration
  to become the time zero concentration (only if a time zero
  concentration does not exist)

- `PKNCA_impute_method_end_conc_drop()`: Drop a concentration measured
  exactly at the end of the interval, if one is present (usually used
  with multiple-dose data when a point at the interval boundary belongs
  to the next dose, e.g. an imputed C0)
