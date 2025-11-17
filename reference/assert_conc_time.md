# Verify that concentration measurements are valid

If the concentrations or times are invalid, will provide an error.
Reasons for being invalid are

- `time` is not a number

- `conc` is not a number

- Any `time` value is NA

- `time` is not monotonically increasing

- `conc` and `time` are not the same length

## Usage

``` r
assert_conc(conc, any_missing_conc = TRUE)

assert_time(time, sorted_time = TRUE)

assert_conc_time(conc, time, any_missing_conc = TRUE, sorted_time = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- any_missing_conc:

  Are any concentration values allowed to be `NA`?

- time:

  Time of the measurement of the concentrations

- sorted_time:

  Must the time be unique and monotonically increasing?

## Value

`conc` or give an informative error

`time` or give an informative error

A data.frame with columns named "conc" and "time" or an informative
error

## Details

Some cases may generate warnings but allow the data to proceed.

- A negative concentration is often but not always an error; it will
  generate a warning.
