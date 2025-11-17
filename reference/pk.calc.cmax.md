# Determine maximum observed PK concentration

Determine maximum observed PK concentration

## Usage

``` r
pk.calc.cmax(conc, check = TRUE)

pk.calc.cmin(conc, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- check:

  Run
  [`assert_conc()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

a number for the maximum concentration or NA if all concentrations are
missing

## Functions

- `pk.calc.cmin()`: Determine the minimum observed PK concentration

## See also

Other NCA parameters for concentrations during the intervals:
[`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.count_conc()`](http://humanpred.github.io/pknca/reference/pk.calc.count_conc.md),
[`pk.calc.cstart()`](http://humanpred.github.io/pknca/reference/pk.calc.cstart.md),
[`pk.calc.ctrough()`](http://humanpred.github.io/pknca/reference/pk.calc.ctrough.md)

Other NCA parameters for concentrations during the intervals:
[`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.count_conc()`](http://humanpred.github.io/pknca/reference/pk.calc.count_conc.md),
[`pk.calc.cstart()`](http://humanpred.github.io/pknca/reference/pk.calc.cstart.md),
[`pk.calc.ctrough()`](http://humanpred.github.io/pknca/reference/pk.calc.ctrough.md)

## Examples

``` r
conc_data <- Theoph[Theoph$Subject == 1,]
pk.calc.cmin(conc_data$conc)
#> [1] 0.74
```
