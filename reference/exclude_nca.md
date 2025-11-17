# Exclude NCA parameters based on examining the parameter set.

Exclude NCA parameters based on examining the parameter set.

## Usage

``` r
exclude_nca_span.ratio(min.span.ratio)

exclude_nca_max.aucinf.pext(max.aucinf.pext)

exclude_nca_count_conc_measured(
  min_count,
  exclude_param_pattern = c("^aucall", "^aucinf", "^aucint", "^auciv", "^auclast",
    "^aumc", "^sparse_auc")
)

exclude_nca_min.hl.r.squared(min.hl.r.squared)

exclude_nca_min.hl.adj.r.squared(min.hl.adj.r.squared = 0.9)

exclude_nca_tmax_early(tmax_early = 0)

exclude_nca_tmax_0()
```

## Arguments

- min.span.ratio:

  The minimum acceptable span ratio (uses
  `PKNCA.options("min.span.ratio")` if not provided).

- max.aucinf.pext:

  The maximum acceptable percent AUC extrapolation (uses
  `PKNCA.options("max.aucinf.pext")` if not provided).

- min_count:

  Minimum number of measured concentrations

- exclude_param_pattern:

  Character vector of regular expression patterns to exclude

- min.hl.r.squared:

  The minimum acceptable r-squared value for half-life (uses
  `PKNCA.options("min.hl.r.squared")` if not provided).

- min.hl.adj.r.squared:

  The minimum acceptable adjusted r-squared for half-life (uses 0.9 if
  not provided).

- tmax_early:

  The time for Tmax which is considered too early to be a valid NCA
  result

## Functions

- `exclude_nca_span.ratio()`: Exclude based on span.ratio

- `exclude_nca_max.aucinf.pext()`: Exclude based on AUC percent
  extrapolated (both observed and predicted)

- `exclude_nca_count_conc_measured()`: Exclude AUC measurements based on
  count of concentrations measured and not below the lower limit of
  quantification

- `exclude_nca_min.hl.r.squared()`: Exclude based on half-life r-squared

- `exclude_nca_min.hl.adj.r.squared()`: Exclude based on half-life
  adjusted r-squared

- `exclude_nca_tmax_early()`: Exclude based on implausibly early Tmax
  (often used for extravascular dosing with a Tmax value of 0)

- `exclude_nca_tmax_0()`: Exclude based on implausibly early Tmax
  (special case for `tmax_early = 0`)

## See also

Other Result exclusions:
[`exclude()`](http://humanpred.github.io/pknca/reference/exclude.md)

## Examples

``` r
my_conc <- PKNCAconc(data.frame(conc=1.1^(3:0),
                                time=0:3,
                                subject=1),
                     conc~time|subject)
my_data <- PKNCAdata(my_conc,
                     intervals=data.frame(start=0, end=Inf,
                                          aucinf.obs=TRUE,
                                          aucpext.obs=TRUE))
my_result <- pk.nca(my_data)
#> No dose information provided, calculations requiring dose will return NA.
my_result_excluded <- exclude(my_result,
                              FUN=exclude_nca_max.aucinf.pext())
#> Loading required namespace: testthat
as.data.frame(my_result_excluded)
#> # A tibble: 16 × 6
#>    subject start   end PPTESTCD            PPORRES exclude     
#>      <dbl> <dbl> <dbl> <chr>                 <dbl> <chr>       
#>  1       1     0   Inf auclast              3.47   NA          
#>  2       1     0   Inf tmax                 0      NA          
#>  3       1     0   Inf tlast                3      NA          
#>  4       1     0   Inf clast.obs            1      NA          
#>  5       1     0   Inf lambda.z             0.0953 NA          
#>  6       1     0   Inf r.squared            1      NA          
#>  7       1     0   Inf adj.r.squared        1      NA          
#>  8       1     0   Inf lambda.z.corrxy     -1      NA          
#>  9       1     0   Inf lambda.z.time.first  1      NA          
#> 10       1     0   Inf lambda.z.time.last   3      NA          
#> 11       1     0   Inf lambda.z.n.points    3      NA          
#> 12       1     0   Inf clast.pred           1      NA          
#> 13       1     0   Inf half.life            7.27   NA          
#> 14       1     0   Inf span.ratio           0.275  NA          
#> 15       1     0   Inf aucinf.obs          14.0    aucpext > 20
#> 16       1     0   Inf aucpext.obs         75.1    aucpext > 20
```
