# Determine if there are any sparse or dense calculations requested within an interval

A calculation is sparse when only sparse data can produce it, which is a
property of the registration rather than a flag; see
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md).

## Usage

``` r
any_sparse_dense_in_interval(interval, sparse)
```

## Arguments

- interval:

  An interval specification

- sparse:

  Are the concentration-time data sparse PK (commonly used in small
  nonclinical species or with terminal or difficult sampling) or dense
  PK (commonly used in clinical studies or larger nonclinical species)?

## Value

A logical value indicating if the interval requests any sparse (if
`sparse=TRUE`) or dense (if `sparse=FALSE`) calculations.
