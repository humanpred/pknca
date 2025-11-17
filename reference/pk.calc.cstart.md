# Determine the concentration at the beginning of the interval

Determine the concentration at the beginning of the interval

## Usage

``` r
pk.calc.cstart(conc, time, start)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- start:

  The start time of the interval

## Value

The concentration when `time == end`. If none match, then `NA`

## See also

Other NCA parameters for concentrations during the intervals:
[`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.cmax()`](http://humanpred.github.io/pknca/reference/pk.calc.cmax.md),
[`pk.calc.count_conc()`](http://humanpred.github.io/pknca/reference/pk.calc.count_conc.md),
[`pk.calc.ctrough()`](http://humanpred.github.io/pknca/reference/pk.calc.ctrough.md)
