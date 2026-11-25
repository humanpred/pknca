# Determine the observed lag time (time before the first concentration above the limit of quantification or above the first concentration in the interval)

Missing concentrations are skipped, as in
[`pk.calc.cmax()`](https://humanpred.github.io/pknca/reference/pk.calc.cmax.md)
and the other simple parameters: the increase is looked for among the
measured concentrations. `NA` is returned when no measured concentration
increases (including when every concentration is missing). Because the
lag is found among the measured samples only, a missing sample between
the last zero and the first increase can move it:
`pk.calc.tlag(c(0, NA, 5, 8), c(0, 1, 2, 4))` is 0, the time of the last
measured zero.

## Usage

``` r
pk.calc.tlag(conc, time, check = TRUE)
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

The time associated with the first increasing concentration, or `NA`
with the reason in its "exclude" attribute when concentrations never
increase

## See also

Other NCA time parameters:
[`pk.calc.tlast()`](https://humanpred.github.io/pknca/reference/pk.calc.tlast.md),
[`pk.calc.tmax()`](https://humanpred.github.io/pknca/reference/pk.calc.tmax.md),
[`pk.calc.tmin()`](https://humanpred.github.io/pknca/reference/pk.calc.tmin.md)
