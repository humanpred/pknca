# Determine time of maximum observed PK concentration

Input restrictions are:

1.  the `conc` and `time` must be the same length,

2.  the `time` may have no NAs,

`NA` will be returned if:

1.  the length of `conc` and `time` is 0

2.  all `conc` is 0 or `NA`

## Usage

``` r
pk.calc.tmax(conc, time, options = list(), first.tmax = NULL, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- first.tmax:

  If there is more than time that matches the maximum concentration,
  should the first be considered as Tmax? If not, then the last is
  considered Tmax.

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

The time of the maximum concentration

## Examples

``` r
conc_data <- Theoph[Theoph$Subject == 1,]
pk.calc.tmax(conc = conc_data$conc, time = conc_data$Time)
#> [1] 1.12
```
