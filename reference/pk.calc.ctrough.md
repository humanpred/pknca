# Determine the trough (end of interval) concentration

Determine the trough (end of interval) concentration

## Usage

``` r
pk.calc.ctrough(conc, time, end)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- end:

  The end time of the interval

## Value

The concentration when `time == end`. If none match, then `NA`

## See also

Other NCA parameters for concentrations during the intervals:
[`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.cmax()`](http://humanpred.github.io/pknca/reference/pk.calc.cmax.md),
[`pk.calc.count_conc()`](http://humanpred.github.io/pknca/reference/pk.calc.count_conc.md),
[`pk.calc.cstart()`](http://humanpred.github.io/pknca/reference/pk.calc.cstart.md)
