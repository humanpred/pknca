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
  [`assert_conc_time()`](https://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

The time of the last (`pk.calc.tlast()`) or first (`pk.calc.tfirst()`)
observed concentration measurement, or `NA` with the reason in its
"exclude" attribute when no concentration is above zero

## Functions

- `pk.calc.tfirst()`: Determine the first concentration above the limit
  of quantification.

## See also

Other NCA time parameters:
[`pk.calc.tlag()`](https://humanpred.github.io/pknca/reference/pk.calc.tlag.md),
[`pk.calc.tmax()`](https://humanpred.github.io/pknca/reference/pk.calc.tmax.md),
[`pk.calc.tmin()`](https://humanpred.github.io/pknca/reference/pk.calc.tmin.md)
