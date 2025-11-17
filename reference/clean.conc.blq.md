# Handle BLQ values in the concentration measurements as requested by the user.

Handle BLQ values in the concentration measurements as requested by the
user.

## Usage

``` r
clean.conc.blq(
  conc,
  time,
  ...,
  options = list(),
  conc.blq = NULL,
  conc.na = NULL,
  check = TRUE
)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- ...:

  Additional arguments passed to clean.conc.na

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- conc.blq:

  How to handle a BLQ value that is between above LOQ values? See
  details for description.

- conc.na:

  How to handle NA concentrations. (See
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md))

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

The concentration and time measurements (data frame) filtered and
cleaned as requested relative to BLQ in the middle.

## Details

`NA` concentrations (and their associated times) will be handled as
described in
[`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)
before working with the BLQ values. The method for handling NA
concentrations can affect the output of which points are considered BLQ
and which are considered "middle". Values are considered BLQ if they are
0.

`conc.blq` can be set either a scalar indicating what should be done for
all BLQ values or a list with elements either named "first", "middle"
and "last" or "before.tmax" and "after.tmax" each set to a scalar.

The meaning of each of the list elements is:

- first:

  Values up to the first non-BLQ value. Note that if all values are BLQ,
  this includes all values.

- middle:

  Values that are BLQ between the first and last non-BLQ values.

- last:

  Values that are BLQ after the last non-BLQ value

- before.tmax:

  Values that are BLQ before the time at first maximum concentration

- after.tmax:

  Values that are BLQ after the time at first maximum concentration

The valid settings for each are:

- "drop":

  Drop the BLQ values

- "keep":

  Keep the BLQ values

- a number:

  Set the BLQ values to that number

## See also

Other Data cleaners:
[`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)
