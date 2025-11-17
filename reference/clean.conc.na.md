# Handle NA values in the concentration measurements as requested by the user.

NA concentrations (and their associated times) will be removed then the
BLQ values in the middle

## Usage

``` r
clean.conc.na(conc, time, ..., options = list(), conc.na = NULL, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- ...:

  Additional items to add to the data frame

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- conc.na:

  How to handle NA concentrations? Either 'drop' or a number to impute.

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

The concentration and time measurements (data frame) filtered and
cleaned as requested relative to NA in the concentration.

## See also

Other Data cleaners:
[`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md)
