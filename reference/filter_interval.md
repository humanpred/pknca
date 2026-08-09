# Subset data to the rows used for calculations within an interval

Rows are selected by their `time` falling within the interval:
`start <= time` and `time <= end` (or `time < end` when
`include_end=FALSE`). For duration data (for example, urine collections
or intravenous infusions), `time` is the start of the collection or
administration, and the `duration` column is not consulted during
selection: a record whose duration starts within the interval and ends
after the interval `end` is selected and contributes its full amount to
calculations within the interval. For the simplest interpretation of
results, align collection start and end times with interval boundaries.

## Usage

``` r
filter_interval(data, start, end, include_na = FALSE, include_end = TRUE)
```

## Arguments

- data:

  A data.frame with a column named `time` (and, for duration data, a
  column named `duration`, which is ignored during selection)

- start, end:

  The beginning and end times of the interval

- include_na:

  Should rows with an `NA` `time` be kept?

- include_end:

  Should a row with `time == end` be kept?

## Value

The rows of `data` selected for the interval
