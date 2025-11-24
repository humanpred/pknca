# Post-Processing

## Introduction

Once a calculation is complete, the steps to extract the desired results
from the results object are described below.

## Setup

To extract results, first results must be available. The example below
comes from the Introduction and Usage vignette and is reproduced here
simply to have results available. See that vignette for more details
about running PKNCA.

``` r
library(PKNCA)
suppressPackageStartupMessages(library(dplyr))

d_conc <-
  as.data.frame(datasets::Theoph) %>%
  mutate(Subject=as.numeric(as.character(Subject)))
## Generate the dosing data
d_dose <- d_conc[d_conc$Time == 0,]
d_dose$Time <- 0

conc_obj <-
  PKNCAconc(
    d_conc,
    conc~Time|Subject
  )
dose_obj <-
  PKNCAdose(
    d_dose,
    Dose~Time|Subject
  )
data_obj <- PKNCAdata(conc_obj, dose_obj)
results_obj <- pk.nca(data_obj)
```

## Modifying Results

### Exclusion of Select Results

In many scenarios, individual results may need to be excluded from
summaries. To exclude results, use the
[`exclude()`](http://humanpred.github.io/pknca/reference/exclude.md)
function.

#### Exclusion Functions

Several exclusion functions are built into PKNCA. The built-in functions
will exclude all results that either apply to the current value or are
dependencies of the current value. For example, $AUC_{\infty}$ depends
on $\lambda_{z}$, and excluding based on span ratio will exclude all
parameters that depend on $\lambda_{z}$, including $AUC_{\infty}$.

To see the built-in functions, type
[`?exclude_nca`](http://humanpred.github.io/pknca/reference/exclude_nca.md)
at the R command line and review that help page. To use them, provide
the function to the `FUN` argument of
[`exclude()`](http://humanpred.github.io/pknca/reference/exclude.md) as
illustrated below.

``` r
results_excl_span <- exclude(results_obj, FUN=exclude_nca_span.ratio())
```

    ## Loading required namespace: testthat

``` r
# Without any exclusions applied, the 'exclude' column is all NA.
as.data.frame(results_obj) %>%
  filter(Subject == 1)
```

    ## # A tibble: 16 × 6
    ##    Subject start   end PPTESTCD             PPORRES exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>  
    ##  1       1     0    24 auclast              92.4    NA     
    ##  2       1     0   Inf cmax                 10.5    NA     
    ##  3       1     0   Inf tmax                  1.12   NA     
    ##  4       1     0   Inf tlast                24.4    NA     
    ##  5       1     0   Inf clast.obs             3.28   NA     
    ##  6       1     0   Inf lambda.z              0.0485 NA     
    ##  7       1     0   Inf r.squared             1.000  NA     
    ##  8       1     0   Inf adj.r.squared         1.000  NA     
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  NA     
    ## 10       1     0   Inf lambda.z.time.first   9.05   NA     
    ## 11       1     0   Inf lambda.z.time.last   24.4    NA     
    ## 12       1     0   Inf lambda.z.n.points     3      NA     
    ## 13       1     0   Inf clast.pred            3.28   NA     
    ## 14       1     0   Inf half.life            14.3    NA     
    ## 15       1     0   Inf span.ratio            1.07   NA     
    ## 16       1     0   Inf aucinf.obs          215.     NA

``` r
# With exclusions applied, the 'exclude' column has the reason for exclusion.
as.data.frame(results_excl_span) %>%
  filter(Subject == 1)
```

    ## # A tibble: 16 × 6
    ##    Subject start   end PPTESTCD             PPORRES exclude       
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>         
    ##  1       1     0    24 auclast              92.4    NA            
    ##  2       1     0   Inf cmax                 10.5    NA            
    ##  3       1     0   Inf tmax                  1.12   NA            
    ##  4       1     0   Inf tlast                24.4    NA            
    ##  5       1     0   Inf clast.obs             3.28   NA            
    ##  6       1     0   Inf lambda.z              0.0485 span.ratio < 2
    ##  7       1     0   Inf r.squared             1.000  span.ratio < 2
    ##  8       1     0   Inf adj.r.squared         1.000  span.ratio < 2
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  span.ratio < 2
    ## 10       1     0   Inf lambda.z.time.first   9.05   span.ratio < 2
    ## 11       1     0   Inf lambda.z.time.last   24.4    span.ratio < 2
    ## 12       1     0   Inf lambda.z.n.points     3      span.ratio < 2
    ## 13       1     0   Inf clast.pred            3.28   span.ratio < 2
    ## 14       1     0   Inf half.life            14.3    span.ratio < 2
    ## 15       1     0   Inf span.ratio            1.07   span.ratio < 2
    ## 16       1     0   Inf aucinf.obs          215.     span.ratio < 2

You may also write your own exclusion function. The exclusion functions
built-into PKNCA are a bit more complex than required because they
handle options and manage general functionality that may not apply to a
user-specific need. To write your own exclusion function, it should
follow the description of how to write your own exclusion function as
described in the details section of
[`?exclude`](http://humanpred.github.io/pknca/reference/exclude.md).

#### Excluding Specific Results

Excluding specific results has the benefit that full control is
provided. But, excluding specific points allows for errors to also enter
the analysis because parameters that depend on the excluded parameter
will not be excluded.

``` r
mask_exclude_cmax <-
  results_obj %>%
  as.data.frame() %>%
  dplyr::mutate(
    mask_exclude=Subject == 1 & PPTESTCD == "cmax"
  ) %>%
  "[["("mask_exclude")
results_excl_specific <-
  exclude(
    results_obj,
    mask=mask_exclude_cmax,
    reason="Cmax was actually above the ULOQ"
  )

# Without any exclusions applied, the 'exclude' column is all NA.
results_obj %>%
  as.data.frame() %>%
  filter(Subject == 1)
```

    ## # A tibble: 16 × 6
    ##    Subject start   end PPTESTCD             PPORRES exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>  
    ##  1       1     0    24 auclast              92.4    NA     
    ##  2       1     0   Inf cmax                 10.5    NA     
    ##  3       1     0   Inf tmax                  1.12   NA     
    ##  4       1     0   Inf tlast                24.4    NA     
    ##  5       1     0   Inf clast.obs             3.28   NA     
    ##  6       1     0   Inf lambda.z              0.0485 NA     
    ##  7       1     0   Inf r.squared             1.000  NA     
    ##  8       1     0   Inf adj.r.squared         1.000  NA     
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  NA     
    ## 10       1     0   Inf lambda.z.time.first   9.05   NA     
    ## 11       1     0   Inf lambda.z.time.last   24.4    NA     
    ## 12       1     0   Inf lambda.z.n.points     3      NA     
    ## 13       1     0   Inf clast.pred            3.28   NA     
    ## 14       1     0   Inf half.life            14.3    NA     
    ## 15       1     0   Inf span.ratio            1.07   NA     
    ## 16       1     0   Inf aucinf.obs          215.     NA

``` r
# With exclusions applied, the 'exclude' column has the reason for exclusion.
results_excl_specific %>%
  as.data.frame() %>%
  filter(Subject == 1)
```

    ## # A tibble: 16 × 6
    ##    Subject start   end PPTESTCD             PPORRES exclude                     
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>                       
    ##  1       1     0    24 auclast              92.4    NA                          
    ##  2       1     0   Inf cmax                 10.5    Cmax was actually above the…
    ##  3       1     0   Inf tmax                  1.12   NA                          
    ##  4       1     0   Inf tlast                24.4    NA                          
    ##  5       1     0   Inf clast.obs             3.28   NA                          
    ##  6       1     0   Inf lambda.z              0.0485 NA                          
    ##  7       1     0   Inf r.squared             1.000  NA                          
    ##  8       1     0   Inf adj.r.squared         1.000  NA                          
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  NA                          
    ## 10       1     0   Inf lambda.z.time.first   9.05   NA                          
    ## 11       1     0   Inf lambda.z.time.last   24.4    NA                          
    ## 12       1     0   Inf lambda.z.n.points     3      NA                          
    ## 13       1     0   Inf clast.pred            3.28   NA                          
    ## 14       1     0   Inf half.life            14.3    NA                          
    ## 15       1     0   Inf span.ratio            1.07   NA                          
    ## 16       1     0   Inf aucinf.obs          215.     NA

#### Multiple Exclusions

More than one exclusion can be applied sequentially to results as in the
example below.

``` r
mask_exclude_lz <-
  results_obj %>%
  as.data.frame() %>%
  dplyr::mutate(
    mask_exclude=Subject == 1 & PPTESTCD == "lambda.z"
  ) %>%
  "[["("mask_exclude")

# Starting from the exclusion example above where short span ratios were
# excluded, exclude Cmax for Subject 1, too.
results_excl_multi <-
  exclude(
    results_excl_span,
    mask=mask_exclude_cmax,
    reason="Cmax was actually above the ULOQ"
  )
results_excl_multi <-
  exclude(
    results_excl_multi,
    mask=mask_exclude_lz,
    reason="Issue with lambda.z fit"
  )

# With exclusions applied, the 'exclude' column has the reason for exclusion.
# More than one reason may appear if more than one exclusion is applied.
results_excl_multi %>%
  as.data.frame() %>%
  filter(Subject == 1)
```

    ## # A tibble: 16 × 6
    ##    Subject start   end PPTESTCD             PPORRES exclude                     
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>                       
    ##  1       1     0    24 auclast              92.4    NA                          
    ##  2       1     0   Inf cmax                 10.5    Cmax was actually above the…
    ##  3       1     0   Inf tmax                  1.12   NA                          
    ##  4       1     0   Inf tlast                24.4    NA                          
    ##  5       1     0   Inf clast.obs             3.28   NA                          
    ##  6       1     0   Inf lambda.z              0.0485 span.ratio < 2; Issue with …
    ##  7       1     0   Inf r.squared             1.000  span.ratio < 2              
    ##  8       1     0   Inf adj.r.squared         1.000  span.ratio < 2              
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  span.ratio < 2              
    ## 10       1     0   Inf lambda.z.time.first   9.05   span.ratio < 2              
    ## 11       1     0   Inf lambda.z.time.last   24.4    span.ratio < 2              
    ## 12       1     0   Inf lambda.z.n.points     3      span.ratio < 2              
    ## 13       1     0   Inf clast.pred            3.28   span.ratio < 2              
    ## 14       1     0   Inf half.life            14.3    span.ratio < 2              
    ## 15       1     0   Inf span.ratio            1.07   span.ratio < 2              
    ## 16       1     0   Inf aucinf.obs          215.     span.ratio < 2

## Normalizing Results

PKNCA provides functions to normalize calculated parameters by columns
in your data or by using normalization tables.

### Example: Normalize by a column in the concentration data

The function
[`normalize_by_col()`](http://humanpred.github.io/pknca/reference/normalize_by_col.md)
allows you to normalize parameters by any column present in the
concentration data of your PKNCAresults object. You can also specify the
unit as another column in the concentration data or as a constant value.

Suppose your concentration data includes a column for body weight, and
you want to normalize Cmax by each subject’s weight:

``` r
# Add a weight column to the concentration data
d_conc2 <- d_conc
d_conc2$weight <- unname(setNames(60:71, 1:12)[d_conc2$Subject])
d_conc2$weight_unit <- "kg"

# Recreate the PKNCA objects with the new column
conc_obj2 <- PKNCAconc(
  d_conc2,
  conc~Time|Subject
)
dose_obj2 <- PKNCAdose(
  d_dose,
  Dose~Time|Subject
)
data_obj2 <- PKNCAdata(conc_obj2, dose_obj2)
results_obj2 <- pk.nca(data_obj2)

# Normalize Cmax by the 'weight' column
results_norm_by_col <- normalize_by_col(
  results_obj2,
  col = "weight",
  unit = "weigth_unit",
  parameters = "cmax",
  suffix = ".wn"
)

# Show the normalized results appended
as.data.frame(results_norm_by_col) %>% filter(PPTESTCD == "cmax.wn")
```

    ## # A tibble: 12 × 6
    ##    Subject start   end PPTESTCD PPORRES exclude
    ##      <dbl> <dbl> <dbl> <chr>      <dbl> <chr>  
    ##  1       1     0   Inf cmax.wn   0.175  NA     
    ##  2       2     0   Inf cmax.wn   0.137  NA     
    ##  3       3     0   Inf cmax.wn   0.132  NA     
    ##  4       4     0   Inf cmax.wn   0.137  NA     
    ##  5       5     0   Inf cmax.wn   0.178  NA     
    ##  6       6     0   Inf cmax.wn   0.0991 NA     
    ##  7       7     0   Inf cmax.wn   0.107  NA     
    ##  8       8     0   Inf cmax.wn   0.113  NA     
    ##  9       9     0   Inf cmax.wn   0.133  NA     
    ## 10      10     0   Inf cmax.wn   0.148  NA     
    ## 11      11     0   Inf cmax.wn   0.114  NA     
    ## 12      12     0   Inf cmax.wn   0.137  NA

### Doing custom normalizations

If your data does not have the normalization column explicitly, you can
perform the same normalization using the
[`normalize()`](http://humanpred.github.io/pknca/reference/normalize.md)
function by providing a normalization table. Below, we use the same
subject weights as above to normalize Cmax, but without adding the
weight column to the concentration data:

``` r
# Use the same subject_weights as above
norm_table <- data.frame(Subject = unique(d_conc$Subject), normalization = 60:71, unit = "kg")
results_norm_custom <- normalize(
  results_obj,
  norm_table = norm_table,
  parameters = "cmax",
  suffix = ".wn"
)
as.data.frame(results_norm_custom) %>% filter(PPTESTCD == "cmax.wn")
```

    ## # A tibble: 12 × 6
    ##    Subject start   end PPTESTCD PPORRES exclude
    ##      <dbl> <dbl> <dbl> <chr>      <dbl> <chr>  
    ##  1       1     0   Inf cmax.wn   0.175  NA     
    ##  2       2     0   Inf cmax.wn   0.137  NA     
    ##  3       3     0   Inf cmax.wn   0.132  NA     
    ##  4       4     0   Inf cmax.wn   0.137  NA     
    ##  5       5     0   Inf cmax.wn   0.178  NA     
    ##  6       6     0   Inf cmax.wn   0.0991 NA     
    ##  7       7     0   Inf cmax.wn   0.107  NA     
    ##  8       8     0   Inf cmax.wn   0.113  NA     
    ##  9       9     0   Inf cmax.wn   0.133  NA     
    ## 10      10     0   Inf cmax.wn   0.148  NA     
    ## 11      11     0   Inf cmax.wn   0.114  NA     
    ## 12      12     0   Inf cmax.wn   0.137  NA

## Extracting Results

### Summary Results

Summary results are obtained using the aptly named
[`summary()`](https://rdrr.io/r/base/summary.html) function. It will
output a `summary_PKNCAresults` object that is simply a data.frame with
an attribute of `caption`. The summary is generated by evaluating
summary statistics on each requested parameter. Which summary statistics
are calculated for each parameter are set with
[`PKNCA.set.summary()`](http://humanpred.github.io/pknca/reference/PKNCA.set.summary.md),
and they are described in the caption. When a parameter is not requested
for a given interval, it is illustrated with a period (`.`), by default
(customizable with the `not.requested.string` argument to
[`summary()`](https://rdrr.io/r/base/summary.html)). When a parameter is
required to calculate another parameter, but it is not specifically
requested, it will not be shown in the summary.

The summary will have one column for each grouping variable other than
the subject grouping variable; one column each for the start and end
time; and one column per parameter calculated.

``` r
summary(results_obj)
```

    ##  start end  N     auclast        cmax               tmax   half.life aucinf.obs
    ##      0  24 12 74.6 [24.3]           .                  .           .          .
    ##      0 Inf 12           . 8.65 [17.0] 1.14 [0.630, 3.55] 8.18 [2.12] 115 [28.4]
    ## 
    ## Caption: auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects

When values are excluded as described above, the excluded values are not
included in the summary (note that half.life and aucinf.obs differ).

``` r
summary(results_excl_span)
```

    ##  start end  N     auclast        cmax               tmax         half.life
    ##      0  24 12 74.6 [24.3]           .                  .                 .
    ##      0 Inf 12           . 8.65 [17.0] 1.14 [0.630, 3.55] 7.36 [0.742], n=9
    ##       aucinf.obs
    ##                .
    ##  105 [16.4], n=9
    ## 
    ## Caption: auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects; n: number of measurements included in summary

### Listing of Results

A listing of all calculated values is available using
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html).

``` r
as.data.frame(results_obj) %>%
  head(20)
```

    ## # A tibble: 20 × 6
    ##    Subject start   end PPTESTCD             PPORRES exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>  
    ##  1       1     0    24 auclast              92.4    NA     
    ##  2       1     0   Inf cmax                 10.5    NA     
    ##  3       1     0   Inf tmax                  1.12   NA     
    ##  4       1     0   Inf tlast                24.4    NA     
    ##  5       1     0   Inf clast.obs             3.28   NA     
    ##  6       1     0   Inf lambda.z              0.0485 NA     
    ##  7       1     0   Inf r.squared             1.000  NA     
    ##  8       1     0   Inf adj.r.squared         1.000  NA     
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  NA     
    ## 10       1     0   Inf lambda.z.time.first   9.05   NA     
    ## 11       1     0   Inf lambda.z.time.last   24.4    NA     
    ## 12       1     0   Inf lambda.z.n.points     3      NA     
    ## 13       1     0   Inf clast.pred            3.28   NA     
    ## 14       1     0   Inf half.life            14.3    NA     
    ## 15       1     0   Inf span.ratio            1.07   NA     
    ## 16       1     0   Inf aucinf.obs          215.     NA     
    ## 17       2     0    24 auclast              67.2    NA     
    ## 18       2     0   Inf cmax                  8.33   NA     
    ## 19       2     0   Inf tmax                  1.92   NA     
    ## 20       2     0   Inf tlast                24.3    NA

Excluded values remain in the listing.

``` r
as.data.frame(results_excl_span) %>%
  head(20)
```

    ## # A tibble: 20 × 6
    ##    Subject start   end PPTESTCD             PPORRES exclude       
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>         
    ##  1       1     0    24 auclast              92.4    NA            
    ##  2       1     0   Inf cmax                 10.5    NA            
    ##  3       1     0   Inf tmax                  1.12   NA            
    ##  4       1     0   Inf tlast                24.4    NA            
    ##  5       1     0   Inf clast.obs             3.28   NA            
    ##  6       1     0   Inf lambda.z              0.0485 span.ratio < 2
    ##  7       1     0   Inf r.squared             1.000  span.ratio < 2
    ##  8       1     0   Inf adj.r.squared         1.000  span.ratio < 2
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  span.ratio < 2
    ## 10       1     0   Inf lambda.z.time.first   9.05   span.ratio < 2
    ## 11       1     0   Inf lambda.z.time.last   24.4    span.ratio < 2
    ## 12       1     0   Inf lambda.z.n.points     3      span.ratio < 2
    ## 13       1     0   Inf clast.pred            3.28   span.ratio < 2
    ## 14       1     0   Inf half.life            14.3    span.ratio < 2
    ## 15       1     0   Inf span.ratio            1.07   span.ratio < 2
    ## 16       1     0   Inf aucinf.obs          215.     span.ratio < 2
    ## 17       2     0    24 auclast              67.2    NA            
    ## 18       2     0   Inf cmax                  8.33   NA            
    ## 19       2     0   Inf tmax                  1.92   NA            
    ## 20       2     0   Inf tlast                24.3    NA
