# Exclude based on NCA parameter thresholds

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
[`PKNCA::exclude`](https://humanpred.github.io/pknca/reference/exclude.md)
to mark through the 'exclude' column the rows in the PKNCA results based
on the specified thresholds for a parameter. Its
`pknca_affected_parameters` attribute lists the parameters it can mark
(see
[`pknca_exclude_rules()`](https://humanpred.github.io/pknca/reference/pknca_exclude_rules.md)).

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
#> # A tibble: 20 × 7
#>    subject start   end PPTESTCD            PPORRES PPANMETH              exclude
#>      <dbl> <dbl> <dbl> <chr>                 <dbl> <chr>                 <chr>  
#>  1       1     0   Inf auclast              11.9   Imputation: start_pr… NA     
#>  2       1     0   Inf cmax                  5     Imputation: start_pr… NA     
#>  3       1     0   Inf tmax                  0     Imputation: start_pr… NA     
#>  4       1     0   Inf tlast                 4     Imputation: start_pr… NA     
#>  5       1     0   Inf clast.obs             1     Imputation: start_pr… NA     
#>  6       1     0   Inf tlag                 NA     Imputation: start_pr… NA     
#>  7       1     0   Inf count_conc            5     Imputation: start_pr… NA     
#>  8       1     0   Inf lambda.z              0.549 Imputation: start_pr… NA     
#>  9       1     0   Inf r.squared             0.978 Imputation: start_pr… NA     
#> 10       1     0   Inf adj.r.squared         0.955 Imputation: start_pr… NA     
#> 11       1     0   Inf lambda.z.corrxy      -0.989 Imputation: start_pr… NA     
#> 12       1     0   Inf lambda.z.time.first   2     Imputation: start_pr… NA     
#> 13       1     0   Inf lambda.z.time.last    4     Imputation: start_pr… NA     
#> 14       1     0   Inf lambda.z.n.points     3     Imputation: start_pr… NA     
#> 15       1     0   Inf clast.pred            1.05  Imputation: start_pr… NA     
#> 16       1     0   Inf half.life             1.26  Imputation: start_pr… NA     
#> 17       1     0   Inf span.ratio            1.58  Imputation: start_pr… span.r…
#> 18       1     0   Inf aucinf.obs           13.7   Imputation: start_pr… NA     
#> 19       1     0   Inf aucpext.obs          13.3   Imputation: start_pr… NA     
#> 20       1     0   Inf cl.obs                7.31  Imputation: start_pr… NA     
```
