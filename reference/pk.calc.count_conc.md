# Count the number of concentration measurements in an interval

`count_conc` and `count_conc_measured` are typically used for quality
control on the data to ensure that there are a sufficient number of
non-missing samples for a calculation and to ensure that data are
consistent between individuals.

## Usage

``` r
pk.calc.count_conc(conc, check = TRUE)

pk.calc.count_conc_measured(conc, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- check:

  Run
  [`assert_conc()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

a count of the non-missing concentrations (0 if all concentrations are
missing)

a count of the non-missing, measured (not below or above the limit of
quantification) concentrations (0 if all concentrations are missing)

## Functions

- `pk.calc.count_conc_measured()`: Count the number of concentration
  measurements that are not missing, above, or below the limit of
  quantification in an interval

## See also

Other NCA parameters for concentrations during the intervals:
[`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.cmax()`](http://humanpred.github.io/pknca/reference/pk.calc.cmax.md),
[`pk.calc.cstart()`](http://humanpred.github.io/pknca/reference/pk.calc.cstart.md),
[`pk.calc.ctrough()`](http://humanpred.github.io/pknca/reference/pk.calc.ctrough.md)
