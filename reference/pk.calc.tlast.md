# Determine time of last observed concentration above the limit of quantification.

`NA` will be returned if all `conc` are `NA` or 0.

## Usage

``` r
pk.calc.tlast(conc, time, check = TRUE)

pk.calc.tfirst(conc, time, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

The time of the last observed concentration measurement

## Functions

- `pk.calc.tfirst()`: Determine the first concentration above the limit
  of quantification.
