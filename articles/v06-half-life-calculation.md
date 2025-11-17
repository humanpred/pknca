# Half-Life Calculation

## Introduction

Half-life is calculated by fitting the natural logarithm of
concentration by time. The default calculation method is curve stripping
(described in more detail below). Manual half-life points with no
automated half-life selection can be performed, or specific points can
be excluded while still performing curve stripping.

## Curve Stripping Method

When automatic point selection is performed for curve stripping, the
algorithm described below is used.

### Select the Points

All sets of points that are applicable according to the current options
are selected.

- Drop all BLQ values, then
- Drop all points at or before the end of the last dose administration,
  including infusion duration (if dosing information is provided), then
- Choose all sets of points that start from the $T_{last}$ and step
  back:
  - at least 3 points (customizable with
    `PKNCA.options("min.hl.points")`)
  - Not including $T_{max}$ (customizable with
    `PKNCA.options("allow.tmax.in.half.life")`)

As a specific example, if measurements were at 0, 1, 2, 3, 4, 6, 8, 12,
and 24 hours; if $T_{last}$ is 12 hours; and if $T_{max}$ is 1 hour then
the default point sets that would be fit are:

1.  6, 8, and 12 hours;
2.  4, 6, 8, and 12 hours;
3.  3, 4, 6, 8, and 12 hours; and
4.  2, 3, 4, 6, 8, and 12 hours.

If `PKNCA.options("min.hl.points")` were set to `4`, then the 6, 8, and
12 hour set would not be fit. If
`PKNCA.options("allow.tmax.in.half.life")` were set to `TRUE`, then 1,
2, 3, 4, 6, 8, and 12 hours would be fit.

### Select the Best Fit

After fitting all points, the best fit among the set of possible fit is
selected by the following rules:

1.  $\lambda_{z} > 0$ and at the same time the maximum r-squared must be
    within an adjusted $r^{2}$ factor of the best.
    1.  The adjusted $r^{2}$ factor is controlled by
        `PKNCA.options("adj.r.squared.factor")` and it defaults to
        10^{-4}.
    2.  These rules must be met simultaneously, so if the maximum
        adjusted $r^{2}$ is for a line with $\lambda_{z} \leq 0$, the
        half-life may end up being unreportable.
2.  If fitting the log-linear concentration-time line fails, then it is
    not the best line.
3.  If more than one fit still meets the criteria above, then choose the
    fit with the most points included.

### Example

``` r
# Perform calculations for subject 1, only
data_conc <- as.data.frame(datasets::Theoph)[datasets::Theoph$Subject == 1, ]

# Keep all points
conc_obj <-
  PKNCAconc(
    data_conc,
    conc~Time|Subject
  )

# Only calculate half-life and parameters required for half-life
current_intervals <- data.frame(start=0, end=Inf, half.life=TRUE)
data_obj <- PKNCAdata(conc_obj, intervals=current_intervals)
result_obj <- pk.nca(data_obj)
```

    ## No dose information provided, calculations requiring dose will return NA.

``` r
# Extract the results for subject 1 
as.data.frame(result_obj)
```

    ## # A tibble: 12 × 6
    ##    Subject start   end PPTESTCD            PPORRES exclude
    ##    <ord>   <dbl> <dbl> <chr>                 <dbl> <chr>  
    ##  1 1           0   Inf tmax                 1.12   NA     
    ##  2 1           0   Inf tlast               24.4    NA     
    ##  3 1           0   Inf lambda.z             0.0485 NA     
    ##  4 1           0   Inf r.squared            1.000  NA     
    ##  5 1           0   Inf adj.r.squared        1.000  NA     
    ##  6 1           0   Inf lambda.z.corrxy     -1.000  NA     
    ##  7 1           0   Inf lambda.z.time.first  9.05   NA     
    ##  8 1           0   Inf lambda.z.time.last  24.4    NA     
    ##  9 1           0   Inf lambda.z.n.points    3      NA     
    ## 10 1           0   Inf clast.pred           3.28   NA     
    ## 11 1           0   Inf half.life           14.3    NA     
    ## 12 1           0   Inf span.ratio           1.07   NA

## Manual Point Selection

For both exclusion and inclusion methods below, the same `NA` handling
rules apply on a per-interval basis. If all values are `NA`, then no
inclusion or exclusion is applied (the interval is treated as-is, like
the argument had not been given). If some values are `NA` for the
interval, those are treated as `FALSE`.

### Exclusion of Specific Points with Curve Stripping

In some cases, specific points will be known outliers, or there may be
another reason to exclude specific points. And, with those points
excluded, the half-life should be calculated using the normal curve
stripping methods described above.

To exclude specific points but otherwise use curve stripping, use the
`exclude_half.life` option as the column name in the concentration
dataset for
[`PKNCAconc()`](http://humanpred.github.io/pknca/reference/PKNCAconc.md)
as illustrated below.

``` r
data_conc$exclude_hl <- data_conc$Time == 12.12
# Confirm that we will be excluding exactly one point
stopifnot(sum(data_conc$exclude_hl) == 1)

# Drop one point
conc_obj_exclude1 <-
  PKNCAconc(
    data_conc,
    conc~Time|Subject,
    exclude_half.life="exclude_hl"
  )

data_obj_exclude1 <- PKNCAdata(conc_obj_exclude1, intervals=current_intervals)

# Perform the calculations
result_obj_exclude1 <- pk.nca(data_obj_exclude1)
```

    ## No dose information provided, calculations requiring dose will return NA.

``` r
# Results differ when excluding the 12-hour point for subject 1 (compare to
# example in the previous section)
as.data.frame(result_obj_exclude1)
```

    ## # A tibble: 12 × 6
    ##    Subject start   end PPTESTCD            PPORRES exclude
    ##    <ord>   <dbl> <dbl> <chr>                 <dbl> <chr>  
    ##  1 1           0   Inf tmax                 1.12   NA     
    ##  2 1           0   Inf tlast               24.4    NA     
    ##  3 1           0   Inf lambda.z             0.0482 NA     
    ##  4 1           0   Inf r.squared            1.000  NA     
    ##  5 1           0   Inf adj.r.squared        0.999  NA     
    ##  6 1           0   Inf lambda.z.corrxy     -1.000  NA     
    ##  7 1           0   Inf lambda.z.time.first  5.1    NA     
    ##  8 1           0   Inf lambda.z.time.last  24.4    NA     
    ##  9 1           0   Inf lambda.z.n.points    4      NA     
    ## 10 1           0   Inf clast.pred           3.28   NA     
    ## 11 1           0   Inf half.life           14.4    NA     
    ## 12 1           0   Inf span.ratio           1.34   NA

### Specification of the Exact Points for Analysis

In other cases, the exact points to use for half-life calculation are
known, and automatic point selection with curve stripping should not be
performed.

To exclude specific points but otherwise use curve stripping, use the
`include_half.life` option as the column name in the concentration
dataset for
[`PKNCAconc()`](http://humanpred.github.io/pknca/reference/PKNCAconc.md)
as illustrated below.

``` r
data_conc$include_hl <- data_conc$Time > 3
# Confirm that we will be excluding exactly one point
stopifnot(sum(data_conc$include_hl) == 6)

# Drop one point
conc_obj_include6 <-
  PKNCAconc(
    data_conc,
    conc~Time|Subject,
    include_half.life="include_hl"
  )

data_obj_include6 <- PKNCAdata(conc_obj_include6, intervals=current_intervals)

# Perform the calculations
result_obj_include6 <- pk.nca(data_obj_include6)
```

    ## No dose information provided, calculations requiring dose will return NA.

``` r
# Results differ when including 6 points (compare to example in the previous
# section)
as.data.frame(result_obj_include6)
```

    ## # A tibble: 12 × 6
    ##    Subject start   end PPTESTCD            PPORRES exclude
    ##    <ord>   <dbl> <dbl> <chr>                 <dbl> <chr>  
    ##  1 1           0   Inf tmax                 1.12   NA     
    ##  2 1           0   Inf tlast               24.4    NA     
    ##  3 1           0   Inf lambda.z             0.0475 NA     
    ##  4 1           0   Inf r.squared            0.999  NA     
    ##  5 1           0   Inf adj.r.squared        0.998  NA     
    ##  6 1           0   Inf lambda.z.corrxy     -0.999  NA     
    ##  7 1           0   Inf lambda.z.time.first  3.82   NA     
    ##  8 1           0   Inf lambda.z.time.last  24.4    NA     
    ##  9 1           0   Inf lambda.z.n.points    6      NA     
    ## 10 1           0   Inf clast.pred           3.30   NA     
    ## 11 1           0   Inf half.life           14.6    NA     
    ## 12 1           0   Inf span.ratio           1.41   NA
