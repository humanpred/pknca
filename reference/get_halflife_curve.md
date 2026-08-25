# Interpolate and extrapolate concentrations along the half-life fit

Concentrations are given as concentrations, not log-concentrations. Take
the natural log of `conc` if the log-concentration is wanted.

## Usage

``` r
get_halflife_curve(
  object,
  tout = NULL,
  n = 50,
  extrapolate_earlier = FALSE,
  extrapolate_later = TRUE
)
```

## Arguments

- object:

  A PKNCAresults or PKNCAdata object

- tout:

  Times for output. The same times are used for every group and
  interval. If `NULL` (the default), `n` equally-spaced times spanning
  the concentrations used for the fit are used instead.

- n:

  The number of equally-spaced times to generate when `tout` is `NULL`.
  It is ignored when `tout` is given.

- extrapolate_earlier, extrapolate_later:

  Should concentrations be extrapolated before the first
  (`extrapolate_earlier`) or after the last (`extrapolate_later`)
  concentration used for the fit? Times outside the fit that are not
  extrapolated give an `NA` concentration.

## Value

A data.frame with the grouping columns, the interval `start` and `end`
times, and the columns:

- `time`: the time of the concentration, on the same scale as the times
  in the concentration data

- `conc`: the concentration on the half-life fit at that time

`conc` is `NA` where the half-life could not be calculated or was
excluded, and where extrapolation was requested but not allowed. Groups
without a fit give a single row with an `NA` `time` when `tout` is
`NULL`, since no times can be generated for them.

## Details

Like [`stats::approx()`](https://rdrr.io/r/stats/approxfun.html), give
either `tout` for specific times or `n` for equally-spaced times. With
`n`, the times span the concentrations used for the fit (`time_first` to
`time_last` from
[`get_halflife_fit()`](https://humanpred.github.io/pknca/reference/get_halflife_fit.md)),
so `tout` is required to extrapolate.

## See also

[`get_halflife_fit()`](https://humanpred.github.io/pknca/reference/get_halflife_fit.md)
for the slope and intercept of the fit, and
[`get_halflife_points()`](https://humanpred.github.io/pknca/reference/get_halflife_points.md)
for the concentrations used for it

## Examples

``` r
o_conc <- PKNCAconc(Theoph, conc~Time|Subject)
o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
o_nca <- pk.nca(o_data)
# Equally-spaced times across the fit
head(get_halflife_curve(o_nca))
#>   Subject start end     time     conc
#> 1       6     0 Inf 2.030000 6.392843
#> 2       6     0 Inf 2.475306 6.147731
#> 3       6     0 Inf 2.920612 5.912017
#> 4       6     0 Inf 3.365918 5.685341
#> 5       6     0 Inf 3.811224 5.467356
#> 6       6     0 Inf 4.256531 5.257729
# Specific times, extrapolating past the last concentration used
get_halflife_curve(o_nca, tout = c(12, 24, 36))
#>    Subject start end time      conc
#> 1        6     0 Inf   12 2.6640713
#> 2        6     0 Inf   24 0.9289565
#> 3        6     0 Inf   36 0.3239253
#> 4        7     0 Inf   12 3.4161419
#> 5        7     0 Inf   24 1.1834973
#> 6        7     0 Inf   36 0.4100139
#> 7        8     0 Inf   12 3.2969449
#> 8        8     0 Inf   24 1.2405933
#> 9        8     0 Inf   36 0.4668176
#> 10      11     0 Inf   12 2.7239734
#> 11      11     0 Inf   24 0.8663978
#> 12      11     0 Inf   36 0.2755699
#> 13       3     0 Inf   12 3.6706903
#> 14       3     0 Inf   24 1.0736327
#> 15       3     0 Inf   36 0.3140246
#> 16       2     0 Inf   12 3.1969589
#> 17       2     0 Inf   24 0.9168262
#> 18       2     0 Inf   36 0.2629281
#> 19       4     0 Inf   12 4.0605207
#> 20       4     0 Inf   24 1.2335140
#> 21       4     0 Inf   36 0.3747196
#> 22       9     0 Inf   12 3.1116231
#> 23       9     0 Inf   24 1.1567807
#> 24       9     0 Inf   36 0.4300462
#> 25      12     0 Inf   12 4.4878763
#> 26      12     0 Inf   24 1.1951429
#> 27      12     0 Inf   36 0.3182722
#> 28      10     0 Inf   12 5.8019123
#> 29      10     0 Inf   24 2.3600191
#> 30      10     0 Inf   36 0.9599748
#> 31       1     0 Inf   12 5.9733095
#> 32       1     0 Inf   24 3.3394869
#> 33       1     0 Inf   36 1.8670006
#> 34       5     0 Inf   12 4.5342772
#> 35       5     0 Inf   24 1.6035807
#> 36       5     0 Inf   36 0.5671182
```
