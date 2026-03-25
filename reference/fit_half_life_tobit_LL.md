# Negative log-likelihood for Tobit half-life regression

Helper function used by
[`fit_half_life_tobit()`](http://humanpred.github.io/pknca/reference/fit_half_life_tobit.md)
via [`stats::optim()`](https://rdrr.io/r/stats/optim.html). For
observations above the LLOQ, the normal density contributes to the
likelihood. For censored (BLQ) observations, the normal CDF up to the
LLOQ contributes.

## Usage

``` r
fit_half_life_tobit_LL(par, log_conc, time, mask_blq, log_lloq)
```

## Arguments

- par:

  A 3-element numeric vector: `c(log_c0, lambda_z, log_resid_error)`

- log_conc:

  Natural log of observed concentration (may be `-Inf` for BLQ; those
  values are not used when `mask_blq` is `TRUE`)

- time:

  Numeric time vector

- mask_blq:

  Logical vector; `TRUE` where the observation is below the LLOQ

- log_lloq:

  Natural log of the lower limit of quantification

## Value

The negative sum of the log-likelihood (a scalar)

## See also

[`fit_half_life_tobit()`](http://humanpred.github.io/pknca/reference/fit_half_life_tobit.md)
