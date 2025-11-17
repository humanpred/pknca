# Times relative to an event (typically dosing)

Times relative to an event (typically dosing)

## Usage

``` r
time_calc(time_event, time_obs, units = NULL)
```

## Arguments

- time_event:

  A vector of times for events

- time_obs:

  A vector of times for observations

- units:

  Passed to `base::as.numeric.difftime()`

## Value

A data.frame with columns for:

- event_number_before:

  The index of `time_event` that is the last one before `time_obs` or
  `NA` if none are before.

- event_number_after:

  The index of `time_event` that is the first one after `time_obs` or
  `NA` if none are after.

- time_before:

  The minimum time that the current `time_obs` is before a `time_event`,
  0 if at least one `time_obs == time_event`.

- time_after:

  The minimum time that the current `time_obs` is after a `time_event`,
  0 if at least one `time_obs == time_event`.

- time_after_first:

  The time after the first event (may be negative or positive).

`time_after` and `time_before` are calculated if they are at the same
time as a dose, they equal zero, and otherwise, they are calculated
relative to the dose number in the `event_number_*` columns.
