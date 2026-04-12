# Determine the trough (end of interval) concentration

Determine the trough (end of interval) concentration

## Usage

``` r
pk.calc.ctrough(conc, time, end)

pk.calc.cstart(conc, time, start)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- end:

  The end time of the interval

- start:

  The start time of the interval

## Value

The concentration when `time == end`. If none match, then `NA`

## Functions

- `pk.calc.cstart()`: Concentration at the beginning of the interval

## See also

Other NCA parameters for concentrations during the intervals:
[`pk.calc.c0()`](http://humanpred.github.io/pknca/reference/pk.calc.c0.md),
[`pk.calc.cav()`](http://humanpred.github.io/pknca/reference/pk.calc.cav.md),
[`pk.calc.ceoi()`](http://humanpred.github.io/pknca/reference/pk.calc.ceoi.md),
[`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.cmax()`](http://humanpred.github.io/pknca/reference/pk.calc.cmax.md),
[`pk.calc.count_conc()`](http://humanpred.github.io/pknca/reference/pk.calc.count_conc.md)

Other NCA parameters for concentrations during the intervals:
[`pk.calc.c0()`](http://humanpred.github.io/pknca/reference/pk.calc.c0.md),
[`pk.calc.cav()`](http://humanpred.github.io/pknca/reference/pk.calc.cav.md),
[`pk.calc.ceoi()`](http://humanpred.github.io/pknca/reference/pk.calc.ceoi.md),
[`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.cmax()`](http://humanpred.github.io/pknca/reference/pk.calc.cmax.md),
[`pk.calc.count_conc()`](http://humanpred.github.io/pknca/reference/pk.calc.count_conc.md)
