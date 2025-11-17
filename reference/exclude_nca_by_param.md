# Exclude NCA Results Based on Parameter Thresholds

Exclude rows from NCA results based on specified thresholds for a given
parameter. This function allows users to define minimum and/or maximum
acceptable values for a parameter and excludes rows that fall outside
these thresholds.

## Usage

``` r
exclude_nca_by_param(
  parameter,
  min_thr = NULL,
  max_thr = NULL,
  affected_parameters = parameter
)
```

## Arguments

- parameter:

  The name of the PKNCA parameter to evaluate (e.g., "span.ratio").

- min_thr:

  The minimum acceptable value for the parameter. If not provided, is
  not applied.

- max_thr:

  The maximum acceptable value for the parameter. If not provided, is
  not applied.

- affected_parameters:

  Character vector of PKNCA parameters that will be marked as excluded.
  By default is the defined parameter.

## Value

A function that can be used with
[`PKNCA::exclude`](http://humanpred.github.io/pknca/reference/exclude.md)
to mark through the 'exclude' column the rows in the PKNCA results based
on the specified thresholds for a parameter.

## Examples

``` r
# Example dataset
my_data <- PKNCA::PKNCAdata(
  PKNCA::PKNCAconc(data.frame(conc = 5:1,
                              time = 0:4,
                              subject = 1),
                   conc ~ time | subject),
  PKNCA::PKNCAdose(data.frame(subject = 1, dose = 100, time = 0),
                   dose ~ time | subject)
)
my_result <- PKNCA::pk.nca(my_data)

# Exclude rows where span.ratio is less than 2
excluded_result <- PKNCA::exclude(
  my_result,
  FUN = exclude_nca_by_param("span.ratio", min_thr = 2)
)
as.data.frame(excluded_result)
#> # A tibble: 16 × 6
#>    subject start   end PPTESTCD            PPORRES exclude       
#>      <dbl> <dbl> <dbl> <chr>                 <dbl> <chr>         
#>  1       1     0    24 auclast              11.9   NA            
#>  2       1     0   Inf cmax                  5     NA            
#>  3       1     0   Inf tmax                  0     NA            
#>  4       1     0   Inf tlast                 4     NA            
#>  5       1     0   Inf clast.obs             1     NA            
#>  6       1     0   Inf lambda.z              0.549 NA            
#>  7       1     0   Inf r.squared             0.978 NA            
#>  8       1     0   Inf adj.r.squared         0.955 NA            
#>  9       1     0   Inf lambda.z.corrxy      -0.989 NA            
#> 10       1     0   Inf lambda.z.time.first   2     NA            
#> 11       1     0   Inf lambda.z.time.last    4     NA            
#> 12       1     0   Inf lambda.z.n.points     3     NA            
#> 13       1     0   Inf clast.pred            1.05  NA            
#> 14       1     0   Inf half.life             1.26  NA            
#> 15       1     0   Inf span.ratio            1.58  span.ratio < 2
#> 16       1     0   Inf aucinf.obs           13.7   NA            
```
