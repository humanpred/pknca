# Run any function with a maximum missing fraction of X and 0s possibly counting as missing. The maximum fraction missing comes from `PKNCA.options("max.missing")`.

Note that all missing values are removed prior to calling the function.

## Usage

``` r
pk.business(FUN, zero.missing = FALSE, max.missing)
```

## Arguments

- FUN:

  function to run. The function is called as `FUN(x, ...)` with missing
  values removed.

- zero.missing:

  Are zeros counted as missing? If `TRUE` then include them in the
  missing count.

- max.missing:

  The maximum fraction of the data allowed to be missing (a number
  between 0 and 1, inclusive).

## Value

A version of FUN that can be called with parameters that are checked for
missingness (and zeros) with missing (and zeros) removed before the
call. If `max.missing` is exceeded, then NA is returned.

## Examples

``` r
my_mean <- pk.business(FUN=mean)
mean(c(1:3, NA))
#> [1] NA
# Less than half missing results in the summary statistic of the available
# values.
my_mean(c(1:3, NA))
#> [1] 2
#> attr(,"n")
#> [1] 3
# More than half missing results in a missing value
my_mean(c(1:3, rep(NA, 4)))
#> [1] NA
```
