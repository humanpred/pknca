# Determine which concentrations were used for half-life calculation

Determine which concentrations were used for half-life calculation

## Usage

``` r
get_halflife_points(object)
```

## Arguments

- object:

  A PKNCAresults object

## Value

A logical vector with `TRUE` if the point was used for half-life
(including concentrations below the limit of quantification within the
range of times for calculation), `FALSE` if it was not used for
half-life but the half-life was calculated for the interval, and `NA` if
half-life was not calculated for the interval. If a row is excluded from
all calculations, it is set to `NA` as well.

## Examples

``` r
o_conc <- PKNCAconc(Theoph, conc~Time|Subject)
o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
o_nca <- pk.nca(o_data)
#> No dose information provided, calculations requiring dose will return NA.
get_halflife_points(o_nca)
#> No dose information provided, calculations requiring dose will return NA.
#>   [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE  TRUE FALSE
#>  [13] FALSE FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE  TRUE  TRUE FALSE FALSE
#>  [25] FALSE FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE  TRUE FALSE FALSE FALSE
#>  [37] FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE  TRUE FALSE FALSE FALSE FALSE
#>  [49] FALSE FALSE FALSE  TRUE  TRUE  TRUE  TRUE FALSE FALSE FALSE FALSE  TRUE
#>  [61]  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE
#>  [73] FALSE  TRUE  TRUE  TRUE  TRUE FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE
#>  [85]  TRUE  TRUE  TRUE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#>  [97]  TRUE  TRUE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE
#> [109]  TRUE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE
#> [121]  TRUE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE  TRUE
```
