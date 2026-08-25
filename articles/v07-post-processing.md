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
[`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md)
function.

#### Exclusion Functions

Several exclusion functions are built into PKNCA. The built-in functions
will exclude all results that either apply to the current value or are
dependents of the current value (parameters that depend on it). For
example, $`AUC_\infty`$ depends on $`\lambda_z`$, and excluding based on
span ratio will exclude all parameters that depend on $`\lambda_z`$,
including $`AUC_\infty`$.

To see the built-in functions, type
[`?exclude_nca`](https://humanpred.github.io/pknca/reference/exclude_nca.md)
and
[`?exclude_nca_by_param`](https://humanpred.github.io/pknca/reference/exclude_nca_by_param.md)
at the R command line and review those help pages. The built-in rules
exclude based on a low span ratio
([`exclude_nca_span.ratio()`](https://humanpred.github.io/pknca/reference/exclude_nca.md)),
a high percent AUC extrapolated
([`exclude_nca_max.aucinf.pext()`](https://humanpred.github.io/pknca/reference/exclude_nca.md)),
too few measured concentrations for AUC calculation
([`exclude_nca_count_conc_measured()`](https://humanpred.github.io/pknca/reference/exclude_nca.md)),
a low half-life r-squared or adjusted r-squared
([`exclude_nca_min.hl.r.squared()`](https://humanpred.github.io/pknca/reference/exclude_nca.md)
and
[`exclude_nca_min.hl.adj.r.squared()`](https://humanpred.github.io/pknca/reference/exclude_nca.md)),
and an implausibly early $`T_{max}`$
([`exclude_nca_tmax_early()`](https://humanpred.github.io/pknca/reference/exclude_nca.md)
and
[`exclude_nca_tmax_0()`](https://humanpred.github.io/pknca/reference/exclude_nca.md)).
They are built on the more general
[`exclude_nca_by_param()`](https://humanpred.github.io/pknca/reference/exclude_nca_by_param.md),
which excludes results when a single parameter is below a minimum
threshold and/or above a maximum threshold, and which can also be used
directly for any parameter. To use them, provide the function to the
`FUN` argument of
[`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md) as
illustrated below. When an exclusion function returns its own reason
text (as the built-in functions do), that text is used as the reason for
exclusion, overriding the `reason` argument to
[`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md).

``` r

results_excl_span <- exclude(results_obj, FUN=exclude_nca_span.ratio())
```

    ## Loading required namespace: testthat

``` r

# Without any exclusions applied, the 'exclude' column is all NA.
as.data.frame(results_obj) %>%
  filter(Subject == 1)
```

    ## # A tibble: 16 × 7
    ##    Subject start   end PPTESTCD             PPORRES PPANMETH             exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>                <chr>  
    ##  1       1     0    24 auclast              92.4    "AUC: lin up/log do… NA     
    ##  2       1     0   Inf cmax                 10.5    ""                   NA     
    ##  3       1     0   Inf tmax                  1.12   ""                   NA     
    ##  4       1     0   Inf tlast                24.4    ""                   NA     
    ##  5       1     0   Inf clast.obs             3.28   ""                   NA     
    ##  6       1     0   Inf lambda.z              0.0485 ""                   NA     
    ##  7       1     0   Inf r.squared             1.000  ""                   NA     
    ##  8       1     0   Inf adj.r.squared         1.000  ""                   NA     
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  ""                   NA     
    ## 10       1     0   Inf lambda.z.time.first   9.05   ""                   NA     
    ## 11       1     0   Inf lambda.z.time.last   24.4    ""                   NA     
    ## 12       1     0   Inf lambda.z.n.points     3      ""                   NA     
    ## 13       1     0   Inf clast.pred            3.28   ""                   NA     
    ## 14       1     0   Inf half.life            14.3    ""                   NA     
    ## 15       1     0   Inf span.ratio            1.07   ""                   NA     
    ## 16       1     0   Inf aucinf.obs          215.     "AUC: lin up/log do… NA

``` r

# With exclusions applied, the 'exclude' column has the reason for exclusion.
as.data.frame(results_excl_span) %>%
  filter(Subject == 1)
```

    ## # A tibble: 16 × 7
    ##    Subject start   end PPTESTCD             PPORRES PPANMETH             exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>                <chr>  
    ##  1       1     0    24 auclast              92.4    "AUC: lin up/log do… NA     
    ##  2       1     0   Inf cmax                 10.5    ""                   NA     
    ##  3       1     0   Inf tmax                  1.12   ""                   NA     
    ##  4       1     0   Inf tlast                24.4    ""                   NA     
    ##  5       1     0   Inf clast.obs             3.28   ""                   NA     
    ##  6       1     0   Inf lambda.z              0.0485 ""                   span.r…
    ##  7       1     0   Inf r.squared             1.000  ""                   span.r…
    ##  8       1     0   Inf adj.r.squared         1.000  ""                   span.r…
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  ""                   span.r…
    ## 10       1     0   Inf lambda.z.time.first   9.05   ""                   span.r…
    ## 11       1     0   Inf lambda.z.time.last   24.4    ""                   span.r…
    ## 12       1     0   Inf lambda.z.n.points     3      ""                   span.r…
    ## 13       1     0   Inf clast.pred            3.28   ""                   span.r…
    ## 14       1     0   Inf half.life            14.3    ""                   span.r…
    ## 15       1     0   Inf span.ratio            1.07   ""                   span.r…
    ## 16       1     0   Inf aucinf.obs          215.     "AUC: lin up/log do… span.r…

You may also write your own exclusion function. The exclusion functions
built-into PKNCA are a bit more complex than required because they
handle options and manage general functionality that may not apply to a
user-specific need. To write your own exclusion function, it should
follow the description of how to write your own exclusion function as
described in the details section of
[`?exclude`](https://humanpred.github.io/pknca/reference/exclude.md).

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

    ## # A tibble: 16 × 7
    ##    Subject start   end PPTESTCD             PPORRES PPANMETH             exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>                <chr>  
    ##  1       1     0    24 auclast              92.4    "AUC: lin up/log do… NA     
    ##  2       1     0   Inf cmax                 10.5    ""                   NA     
    ##  3       1     0   Inf tmax                  1.12   ""                   NA     
    ##  4       1     0   Inf tlast                24.4    ""                   NA     
    ##  5       1     0   Inf clast.obs             3.28   ""                   NA     
    ##  6       1     0   Inf lambda.z              0.0485 ""                   NA     
    ##  7       1     0   Inf r.squared             1.000  ""                   NA     
    ##  8       1     0   Inf adj.r.squared         1.000  ""                   NA     
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  ""                   NA     
    ## 10       1     0   Inf lambda.z.time.first   9.05   ""                   NA     
    ## 11       1     0   Inf lambda.z.time.last   24.4    ""                   NA     
    ## 12       1     0   Inf lambda.z.n.points     3      ""                   NA     
    ## 13       1     0   Inf clast.pred            3.28   ""                   NA     
    ## 14       1     0   Inf half.life            14.3    ""                   NA     
    ## 15       1     0   Inf span.ratio            1.07   ""                   NA     
    ## 16       1     0   Inf aucinf.obs          215.     "AUC: lin up/log do… NA

``` r

# With exclusions applied, the 'exclude' column has the reason for exclusion.
results_excl_specific %>%
  as.data.frame() %>%
  filter(Subject == 1)
```

    ## # A tibble: 16 × 7
    ##    Subject start   end PPTESTCD             PPORRES PPANMETH             exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>                <chr>  
    ##  1       1     0    24 auclast              92.4    "AUC: lin up/log do… NA     
    ##  2       1     0   Inf cmax                 10.5    ""                   Cmax w…
    ##  3       1     0   Inf tmax                  1.12   ""                   NA     
    ##  4       1     0   Inf tlast                24.4    ""                   NA     
    ##  5       1     0   Inf clast.obs             3.28   ""                   NA     
    ##  6       1     0   Inf lambda.z              0.0485 ""                   NA     
    ##  7       1     0   Inf r.squared             1.000  ""                   NA     
    ##  8       1     0   Inf adj.r.squared         1.000  ""                   NA     
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  ""                   NA     
    ## 10       1     0   Inf lambda.z.time.first   9.05   ""                   NA     
    ## 11       1     0   Inf lambda.z.time.last   24.4    ""                   NA     
    ## 12       1     0   Inf lambda.z.n.points     3      ""                   NA     
    ## 13       1     0   Inf clast.pred            3.28   ""                   NA     
    ## 14       1     0   Inf half.life            14.3    ""                   NA     
    ## 15       1     0   Inf span.ratio            1.07   ""                   NA     
    ## 16       1     0   Inf aucinf.obs          215.     "AUC: lin up/log do… NA

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

    ## # A tibble: 16 × 7
    ##    Subject start   end PPTESTCD             PPORRES PPANMETH             exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>                <chr>  
    ##  1       1     0    24 auclast              92.4    "AUC: lin up/log do… NA     
    ##  2       1     0   Inf cmax                 10.5    ""                   Cmax w…
    ##  3       1     0   Inf tmax                  1.12   ""                   NA     
    ##  4       1     0   Inf tlast                24.4    ""                   NA     
    ##  5       1     0   Inf clast.obs             3.28   ""                   NA     
    ##  6       1     0   Inf lambda.z              0.0485 ""                   span.r…
    ##  7       1     0   Inf r.squared             1.000  ""                   span.r…
    ##  8       1     0   Inf adj.r.squared         1.000  ""                   span.r…
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  ""                   span.r…
    ## 10       1     0   Inf lambda.z.time.first   9.05   ""                   span.r…
    ## 11       1     0   Inf lambda.z.time.last   24.4    ""                   span.r…
    ## 12       1     0   Inf lambda.z.n.points     3      ""                   span.r…
    ## 13       1     0   Inf clast.pred            3.28   ""                   span.r…
    ## 14       1     0   Inf half.life            14.3    ""                   span.r…
    ## 15       1     0   Inf span.ratio            1.07   ""                   span.r…
    ## 16       1     0   Inf aucinf.obs          215.     "AUC: lin up/log do… span.r…

## Normalizing Results

PKNCA provides functions to normalize calculated parameters by columns
in your data or by using normalization tables.

### Example: Normalize by a column in the concentration data

The function
[`normalize_by_col()`](https://humanpred.github.io/pknca/reference/normalize_by_col.md)
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
  unit = "weight_unit",
  parameters = "cmax",
  suffix = ".wn"
)

# Show the normalized results appended
as.data.frame(results_norm_by_col) %>% filter(PPTESTCD == "cmax.wn")
```

    ## # A tibble: 12 × 7
    ##    Subject start   end PPTESTCD PPORRES PPANMETH exclude
    ##      <dbl> <dbl> <dbl> <chr>      <dbl> <chr>    <chr>  
    ##  1       1     0   Inf cmax.wn   0.175  ""       NA     
    ##  2       2     0   Inf cmax.wn   0.137  ""       NA     
    ##  3       3     0   Inf cmax.wn   0.132  ""       NA     
    ##  4       4     0   Inf cmax.wn   0.137  ""       NA     
    ##  5       5     0   Inf cmax.wn   0.178  ""       NA     
    ##  6       6     0   Inf cmax.wn   0.0991 ""       NA     
    ##  7       7     0   Inf cmax.wn   0.107  ""       NA     
    ##  8       8     0   Inf cmax.wn   0.113  ""       NA     
    ##  9       9     0   Inf cmax.wn   0.133  ""       NA     
    ## 10      10     0   Inf cmax.wn   0.148  ""       NA     
    ## 11      11     0   Inf cmax.wn   0.114  ""       NA     
    ## 12      12     0   Inf cmax.wn   0.137  ""       NA

### Doing custom normalizations

If your data does not have the normalization column explicitly, you can
perform the same normalization using the
[`normalize()`](https://humanpred.github.io/pknca/reference/normalize.md)
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

    ## # A tibble: 12 × 7
    ##    Subject start   end PPTESTCD PPORRES PPANMETH exclude
    ##      <dbl> <dbl> <dbl> <chr>      <dbl> <chr>    <chr>  
    ##  1       1     0   Inf cmax.wn   0.175  ""       NA     
    ##  2       2     0   Inf cmax.wn   0.137  ""       NA     
    ##  3       3     0   Inf cmax.wn   0.132  ""       NA     
    ##  4       4     0   Inf cmax.wn   0.137  ""       NA     
    ##  5       5     0   Inf cmax.wn   0.178  ""       NA     
    ##  6       6     0   Inf cmax.wn   0.0991 ""       NA     
    ##  7       7     0   Inf cmax.wn   0.107  ""       NA     
    ##  8       8     0   Inf cmax.wn   0.113  ""       NA     
    ##  9       9     0   Inf cmax.wn   0.133  ""       NA     
    ## 10      10     0   Inf cmax.wn   0.148  ""       NA     
    ## 11      11     0   Inf cmax.wn   0.114  ""       NA     
    ## 12      12     0   Inf cmax.wn   0.137  ""       NA

## Extracting Results

### Summary Results

Summary results are obtained using the aptly named
[`summary()`](https://rdrr.io/r/base/summary.html) function. It will
output a `summary_PKNCAresults` object that is simply a data.frame with
an attribute of `caption`. The summary is generated by evaluating
summary statistics on each requested parameter. Which summary statistics
are calculated for each parameter are set with
[`PKNCA.set.summary()`](https://humanpred.github.io/pknca/reference/PKNCA.set.summary.md),
and they are described in the caption. When a parameter is not requested
for a given interval, it is illustrated with a period (`.`), by default
(customizable with the `not_requested` argument to
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

    ## # A tibble: 20 × 7
    ##    Subject start   end PPTESTCD             PPORRES PPANMETH             exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>                <chr>  
    ##  1       1     0    24 auclast              92.4    "AUC: lin up/log do… NA     
    ##  2       1     0   Inf cmax                 10.5    ""                   NA     
    ##  3       1     0   Inf tmax                  1.12   ""                   NA     
    ##  4       1     0   Inf tlast                24.4    ""                   NA     
    ##  5       1     0   Inf clast.obs             3.28   ""                   NA     
    ##  6       1     0   Inf lambda.z              0.0485 ""                   NA     
    ##  7       1     0   Inf r.squared             1.000  ""                   NA     
    ##  8       1     0   Inf adj.r.squared         1.000  ""                   NA     
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  ""                   NA     
    ## 10       1     0   Inf lambda.z.time.first   9.05   ""                   NA     
    ## 11       1     0   Inf lambda.z.time.last   24.4    ""                   NA     
    ## 12       1     0   Inf lambda.z.n.points     3      ""                   NA     
    ## 13       1     0   Inf clast.pred            3.28   ""                   NA     
    ## 14       1     0   Inf half.life            14.3    ""                   NA     
    ## 15       1     0   Inf span.ratio            1.07   ""                   NA     
    ## 16       1     0   Inf aucinf.obs          215.     "AUC: lin up/log do… NA     
    ## 17       2     0    24 auclast              67.2    "AUC: lin up/log do… NA     
    ## 18       2     0   Inf cmax                  8.33   ""                   NA     
    ## 19       2     0   Inf tmax                  1.92   ""                   NA     
    ## 20       2     0   Inf tlast                24.3    ""                   NA

Excluded values remain in the listing.

``` r

as.data.frame(results_excl_span) %>%
  head(20)
```

    ## # A tibble: 20 × 7
    ##    Subject start   end PPTESTCD             PPORRES PPANMETH             exclude
    ##      <dbl> <dbl> <dbl> <chr>                  <dbl> <chr>                <chr>  
    ##  1       1     0    24 auclast              92.4    "AUC: lin up/log do… NA     
    ##  2       1     0   Inf cmax                 10.5    ""                   NA     
    ##  3       1     0   Inf tmax                  1.12   ""                   NA     
    ##  4       1     0   Inf tlast                24.4    ""                   NA     
    ##  5       1     0   Inf clast.obs             3.28   ""                   NA     
    ##  6       1     0   Inf lambda.z              0.0485 ""                   span.r…
    ##  7       1     0   Inf r.squared             1.000  ""                   span.r…
    ##  8       1     0   Inf adj.r.squared         1.000  ""                   span.r…
    ##  9       1     0   Inf lambda.z.corrxy      -1.000  ""                   span.r…
    ## 10       1     0   Inf lambda.z.time.first   9.05   ""                   span.r…
    ## 11       1     0   Inf lambda.z.time.last   24.4    ""                   span.r…
    ## 12       1     0   Inf lambda.z.n.points     3      ""                   span.r…
    ## 13       1     0   Inf clast.pred            3.28   ""                   span.r…
    ## 14       1     0   Inf half.life            14.3    ""                   span.r…
    ## 15       1     0   Inf span.ratio            1.07   ""                   span.r…
    ## 16       1     0   Inf aucinf.obs          215.     "AUC: lin up/log do… span.r…
    ## 17       2     0    24 auclast              67.2    "AUC: lin up/log do… NA     
    ## 18       2     0   Inf cmax                  8.33   ""                   NA     
    ## 19       2     0   Inf tmax                  1.92   ""                   NA     
    ## 20       2     0   Inf tlast                24.3    ""                   NA

### Concentrations Used for Half-Life Estimation

To find which concentration measurements were used for the half-life
($`\lambda_z`$) estimation, use
[`get_halflife_points()`](https://humanpred.github.io/pknca/reference/get_halflife_points.md).
It returns a logical vector with one value per row of the concentration
data: `TRUE` if the point was used in the half-life fit, `FALSE` if it
was not used but a half-life was calculated for the interval, and `NA`
if no half-life was calculated for the interval (or if the row is
excluded from all calculations). It accepts either a PKNCAresults or a
PKNCAdata object (with a PKNCAdata object, the half-life is calculated
first), and the intervals do not need to start at time 0.

``` r

d_conc_hl <- d_conc
d_conc_hl$hl_used <- get_halflife_points(results_obj)
# The points used for the half-life fit are the later time points
d_conc_hl %>%
  filter(Subject == 1)
```

    ##    Subject   Wt Dose  Time  conc hl_used
    ## 1        1 79.6 4.02  0.00  0.74   FALSE
    ## 2        1 79.6 4.02  0.25  2.84   FALSE
    ## 3        1 79.6 4.02  0.57  6.57   FALSE
    ## 4        1 79.6 4.02  1.12 10.50   FALSE
    ## 5        1 79.6 4.02  2.02  9.66   FALSE
    ## 6        1 79.6 4.02  3.82  8.58   FALSE
    ## 7        1 79.6 4.02  5.10  8.36   FALSE
    ## 8        1 79.6 4.02  7.03  7.47   FALSE
    ## 9        1 79.6 4.02  9.05  6.89    TRUE
    ## 10       1 79.6 4.02 12.12  5.94    TRUE
    ## 11       1 79.6 4.02 24.37  3.28    TRUE

### The Half-Life Fit

[`get_halflife_fit()`](https://humanpred.github.io/pknca/reference/get_halflife_fit.md)
gives the log-linear fit itself, one row per group and interval, as the
slope and intercept of `log(conc) = intercept + slope*time`. The slope
is $`-\lambda_z`$.

``` r

get_halflife_fit(results_obj)
```

    ##    Subject start end intercept       slope time_first time_last
    ## 1        1     0 Inf  2.368785 -0.04845700       9.05     24.37
    ## 2        2     0 Inf  2.411237 -0.10408644       7.03     24.30
    ## 3        3     0 Inf  2.529712 -0.10244431       9.00     24.17
    ## 4        4     0 Inf  2.592755 -0.09928702       9.02     24.65
    ## 5        5     0 Inf  2.551092 -0.08661888       7.02     24.35
    ## 6        6     0 Inf  2.033404 -0.08779574       2.03     23.85
    ## 7        7     0 Inf  2.288550 -0.08833650       6.98     24.22
    ## 8        8     0 Inf  2.170403 -0.08145054       3.53     24.12
    ## 9        9     0 Inf  2.124648 -0.08245863       8.80     24.43
    ## 10      10     0 Inf  2.657705 -0.07495982       9.38     23.70
    ## 11      11     0 Inf  2.147594 -0.09545856       9.03     24.08
    ## 12      12     0 Inf  2.824493 -0.11025949       9.03     24.15

Times in a PKNCAresults object are relative to the start of the
interval, but `time_first`, `time_last`, and the time scale of
`intercept` are all on the same scale as the times in the concentration
data. The fitted line can therefore be drawn with the observed
concentrations without shifting anything. `intercept` and `slope` are
`NA` when the half-life could not be calculated or was excluded.

### Concentrations Along the Half-Life Fit

[`get_halflife_curve()`](https://humanpred.github.io/pknca/reference/get_halflife_curve.md)
gives concentrations along that line. As with
[`stats::approx()`](https://rdrr.io/r/stats/approxfun.html), give either
`n` for equally-spaced times or `tout` for specific times.
Concentrations are returned as concentrations, not log-concentrations.

With `n`, the times span the concentrations used for the fit:

``` r

get_halflife_curve(results_obj, n = 5) %>%
  filter(Subject == 1)
```

    ##   Subject start end  time     conc
    ## 1       1     0 Inf  9.05 6.891228
    ## 2       1     0 Inf 12.88 5.723949
    ## 3       1     0 Inf 16.71 4.754391
    ## 4       1     0 Inf 20.54 3.949063
    ## 5       1     0 Inf 24.37 3.280146

With `tout`, any times may be requested. Extrapolation after the last
concentration used for the fit is done by default, and extrapolation
before the first is not, so early times give `NA`:

``` r

get_halflife_curve(results_obj, tout = c(0, 12, 48)) %>%
  filter(Subject == 1)
```

    ##   Subject start end time     conc
    ## 1       1     0 Inf    0       NA
    ## 2       1     0 Inf   12 5.973310
    ## 3       1     0 Inf   48 1.043781

Both defaults can be changed with the `extrapolate_earlier` and
`extrapolate_later` arguments:

``` r

get_halflife_curve(
  results_obj,
  tout = c(0, 12, 48),
  extrapolate_earlier = TRUE,
  extrapolate_later = FALSE
) %>%
  filter(Subject == 1)
```

    ##   Subject start end time     conc
    ## 1       1     0 Inf    0 10.68440
    ## 2       1     0 Inf   12  5.97331
    ## 3       1     0 Inf   48       NA
