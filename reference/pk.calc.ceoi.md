# Determine the concentration at the end of infusion

Determine the concentration at the end of infusion

## Usage

``` r
pk.calc.ceoi(conc, time, duration.dose = NA, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- duration.dose:

  The duration for the dosing administration (typically from IV
  infusion)

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

The concentration at the end of the infusion, `NA` if `duration.dose` is
`NA`, or `NA` if all `time != duration.dose`
