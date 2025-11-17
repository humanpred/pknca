# Compute the time to steady-state (tss)

Compute the time to steady-state (tss)

## Usage

``` r
pk.tss(..., type = c("monoexponential", "stepwise.linear"), check = TRUE)
```

## Arguments

- ...:

  Passed to
  [`pk.tss.monoexponential()`](http://humanpred.github.io/pknca/reference/pk.tss.monoexponential.md)
  or
  [`pk.tss.stepwise.linear()`](http://humanpred.github.io/pknca/reference/pk.tss.stepwise.linear.md).

- type:

  The type of Tss to calculate, either `stepwise.linear` or
  `monoexponential`

- check:

  See
  [`pk.tss.data.prep()`](http://humanpred.github.io/pknca/reference/pk.tss.data.prep.md)

## Value

A data frame with columns as defined from `pk.tss.monoexponential`
and/or `pk.tss.stepwise.linear`.

## See also

Other Time to steady-state calculations:
[`pk.tss.monoexponential()`](http://humanpred.github.io/pknca/reference/pk.tss.monoexponential.md),
[`pk.tss.stepwise.linear()`](http://humanpred.github.io/pknca/reference/pk.tss.stepwise.linear.md)
