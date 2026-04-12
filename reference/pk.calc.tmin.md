# Determine time of minimum observed PK concentration

Input restrictions are:

1.  the `conc` and `time` must be the same length,

2.  the `time` may have no NAs,

`NA` will be returned if:

1.  the length of `conc` and `time` is 0

2.  all `conc` is `NA`

## Usage

``` r
pk.calc.tmin(conc, time, options = list(), first.tmin = NULL, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- first.tmin:

  If there is more than one time point with the minimum value (Cmin),
  which time should be selected for Tmin? If 'TRUE', the first will be
  selected. If not, then the last is considered Tmin.

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

The time of the minimum concentration

## See also

Other NCA time parameters:
[`pk.calc.tlag()`](http://humanpred.github.io/pknca/reference/pk.calc.tlag.md),
[`pk.calc.tlast()`](http://humanpred.github.io/pknca/reference/pk.calc.tlast.md),
[`pk.calc.tmax()`](http://humanpred.github.io/pknca/reference/pk.calc.tmax.md)

## Examples

``` r
conc_data <- Theoph[Theoph$Subject == 1,]
pk.calc.tmin(conc = conc_data$conc, time = conc_data$Time)
#> [1] 0
```
