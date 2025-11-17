# Determine the last observed concentration above the limit of quantification (LOQ).

If all concentrations are missing, `NA_real_` is returned. If all
concentrations are zero (below the limit of quantification) or missing,
zero is returned. If Tlast is NA (due to no non-missing above LOQ
measurements), this will return `NA_real_`.

## Usage

``` r
pk.calc.clast.obs(conc, time, check = TRUE)
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

The last observed concentration above the LOQ

## See also

Other NCA parameters for concentrations during the intervals:
[`pk.calc.cmax()`](http://humanpred.github.io/pknca/reference/pk.calc.cmax.md),
[`pk.calc.count_conc()`](http://humanpred.github.io/pknca/reference/pk.calc.count_conc.md),
[`pk.calc.cstart()`](http://humanpred.github.io/pknca/reference/pk.calc.cstart.md),
[`pk.calc.ctrough()`](http://humanpred.github.io/pknca/reference/pk.calc.ctrough.md)
