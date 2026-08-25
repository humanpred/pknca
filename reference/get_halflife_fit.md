# Get the half-life fit line for each interval

The half-life fit is the log-linear regression of concentration on time,
`log(conc) = intercept + slope*time`. Concentrations along the line are
`exp(intercept + slope*time)`.

## Usage

``` r
get_halflife_fit(object)
```

## Arguments

- object:

  A PKNCAresults or PKNCAdata object

## Value

A data.frame with one row for each group and interval where half-life
was calculated. Along with the grouping columns and the interval `start`
and `end` times, it has the columns:

- `intercept`: the natural log of the concentration where the line
  crosses time 0

- `slope`: the slope of the line, `-lambda.z`

- `time_first`, `time_last`: the first and last times of the
  concentrations used for the fit

`intercept` and `slope` are `NA` when the half-life could not be
calculated or was excluded.

## Details

Times in a `PKNCAresults` object are relative to the start of the
interval, but `time_first`, `time_last`, and the time scale of
`intercept` are on the same scale as the times in the concentration data
so that the line can be drawn with the observed concentrations.

## See also

[`get_halflife_points()`](https://humanpred.github.io/pknca/reference/get_halflife_points.md)
to see which concentrations were used for the fit

## Examples

``` r
o_conc <- PKNCAconc(Theoph, conc~Time|Subject)
o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
o_nca <- pk.nca(o_data)
get_halflife_fit(o_nca)
#>    Subject start end intercept       slope time_first time_last
#> 1        6     0 Inf  2.033404 -0.08779574       2.03     23.85
#> 2        7     0 Inf  2.288550 -0.08833650       6.98     24.22
#> 3        8     0 Inf  2.170403 -0.08145054       3.53     24.12
#> 4       11     0 Inf  2.147594 -0.09545856       9.03     24.08
#> 5        3     0 Inf  2.529712 -0.10244431       9.00     24.17
#> 6        2     0 Inf  2.411237 -0.10408644       7.03     24.30
#> 7        4     0 Inf  2.592755 -0.09928702       9.02     24.65
#> 8        9     0 Inf  2.124648 -0.08245863       8.80     24.43
#> 9       12     0 Inf  2.824493 -0.11025949       9.03     24.15
#> 10      10     0 Inf  2.657705 -0.07495982       9.38     23.70
#> 11       1     0 Inf  2.368785 -0.04845700       9.05     24.37
#> 12       5     0 Inf  2.551092 -0.08661888       7.02     24.35
```
