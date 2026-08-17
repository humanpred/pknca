# Sparse NCA Calculations

## Sparse NCA Calculations

Sparse noncompartmental analysis (NCA) is performed when multiple
individuals contribute to a single concentration-time profile due to the
fact that there are only one or a subset of the full profile samples
taken per animal. A typical example is when three mice have PK drawn per
time point, but no animals have more than one sample drawn. Another
typical example is when animals may have two or three samples during an
interval, but no animal has the full profile.

### Sparse NCA Setup

Sparse NCA is setup similarly to how normal, dense PK sampling is setup
with PKNCA. The only difference are that you give the `sparse` option to
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md),
and in your interval calculations, you will request the sparse variants
of the parameters. The sparse parameters for calculation are
`sparse_auclast` and `sparse_aumclast` (each with an accompanying
standard error and degrees of freedom) along with parameters derived
from them (described below). Any of the non-sparse parameters will be
calculated based on the mean profile of the animals in a group.

The example below uses data extracted from Holder D. J., Hsuan F., Dixit
R. and Soper K. (1999). A method for estimating and testing area under
the curve in serial sacrifice, batch, and complete data designs. Journal
of Biopharmaceutical Statistics, 9(3):451-464.

``` r

# Setup the data
d_sparse <-
    data.frame(
      id = c(1L, 2L, 3L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 4L, 5L, 6L, 7L, 8L, 9L, 7L, 8L, 9L),
      conc = c(0, 0, 0,  1.75, 2.2, 1.58, 4.63, 2.99, 1.52, 3.03, 1.98, 2.22, 3.34, 1.3, 1.22, 3.54, 2.84, 2.55, 0.3, 0.0421, 0.231),
      time = c(0, 0, 0, 1, 1, 1, 6, 6, 6, 2, 2, 2, 10, 10, 10, 4, 4, 4, 24, 24, 24),
      dose = c(100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100)
    )
```

Look at your data. (This is not technically a required step, but it’s
good practice.)

``` r

library(ggplot2)
ggplot(d_sparse, aes(x=time, y=conc, group=id)) +
  geom_point() +
  geom_line() +
  scale_x_continuous(breaks=seq(0, 24, by=6))
```

![](v04-sparse_files/figure-html/unnamed-chunk-2-1.png)

### Data Setup Note

Sparse NCA requires that subject numbers (or animal numbers) are given,
even if each subject only contributes a single sample. The reason for
this requirement is that which subject contributes to which time point
changes the standard error calculation. If all individuals contribute a
single sample, a simple way to handle this is by setting a column with
sequential numbers and giving that as the subject identifier:

``` r

d_sparse$id <- 1:nrow(d_sparse)
```

### How Subjects Are Grouped for Sparse Calculations

With dense (normal) PK, every subject has a full concentration-time
profile, so NCA parameters are calculated one subject at a time. Sparse
parameters are different: they are calculated from the *pooled* samples
of every subject that belongs to the same group. Knowing what defines a
“group” is therefore important.

The groups are taken from the grouping variables on the right of the `|`
in the
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
formula, **with the subject column removed**. Every subject that shares
the same combination of the remaining (non-subject) grouping variables
contributes to a single pooled sparse concentration-time profile.

In the simple example above, the formula is `conc~time|id`. Here `id` is
the subject, and removing it leaves no other grouping variables, so all
of the data form a single sparse group.

The behavior is easier to see with more grouping variables. Suppose the
concentration and dose objects are created with the formulas below
(illustrative code; not run here):

``` r

o_conc_sparse <- PKNCAconc(d_conc, conc~time|matrix+drug+usubjid/analyte, sparse=TRUE)
o_dose_sparse <- PKNCAdose(d_dose, dose~time|drug+usubjid)
```

`usubjid` is the subject because, by default, the subject is the last
grouping variable before any `/` (or the last grouping variable when
there is no `/`). After dropping the subject, the grouping variables
that remain are `matrix`, `drug`, and `analyte`. Sparse parameters are
therefore calculated by combining all subjects within each unique
combination of `matrix`, `drug`, and `analyte`.

In other words, with that formula PKNCA does **not** keep each `usubjid`
separate, and it does **not** group by `matrix`, `drug`, or `analyte`
alone. It pools subjects using the full set of non-subject grouping
variables together (`matrix` + `drug` + `analyte`).

Because subjects are pooled within a group, all subjects in a group must
share the same dosing. If subjects in the same group have different
dosing information (for example, different dose amounts or dose times),
PKNCA stops with an error identifying the inconsistent group.

## Calculate!

Setup PKNCA for calculations and then calculate!

``` r

library(PKNCA)
```

    ## 
    ## Attaching package: 'PKNCA'

    ## The following object is masked from 'package:stats':
    ## 
    ##     filter

``` r

o_conc_sparse <- PKNCAconc(d_sparse, conc~time|id, sparse=TRUE)
d_intervals <-
  data.frame(
    start=0,
    end=24,
    aucinf.obs=TRUE,
    cmax=TRUE,
    sparse_auclast=TRUE
  )
o_data_sparse <- PKNCAdata(o_conc_sparse, intervals=d_intervals)
o_nca <- pk.nca(o_data_sparse)
```

    ## No dose information provided, calculations requiring dose will return NA.

    ## Warning: Too few points for half-life calculation (min.hl.points=3 with only 2
    ## points)

    ## Warning: Cannot yet calculate sparse degrees of freedom for multiple samples
    ## per subject

## Results

As with any other PKNCA result, the data are available through the
[`summary()`](https://rdrr.io/r/base/summary.html) function:

``` r

summary(o_nca)
```

    ##  start end cmax sparse_auclast aucinf.obs
    ##      0  24 3.05           39.5         NC
    ## 
    ## Caption: cmax, sparse_auclast, aucinf.obs: geometric mean and geometric coefficient of variation

or individual results are available through the
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) function:

``` r

as.data.frame(o_nca)
```

    ## # A tibble: 18 × 6
    ##    start   end PPTESTCD            PPORRES PPANMETH               exclude       
    ##    <dbl> <dbl> <chr>                 <dbl> <chr>                  <chr>         
    ##  1     0    24 cmax                  3.05  ""                     NA            
    ##  2     0    24 tmax                  6     ""                     NA            
    ##  3     0    24 tlast                24     ""                     NA            
    ##  4     0    24 clast.obs             0.191 ""                     NA            
    ##  5     0    24 lambda.z             NA     ""                     Too few point…
    ##  6     0    24 r.squared            NA     ""                     Too few point…
    ##  7     0    24 adj.r.squared        NA     ""                     Too few point…
    ##  8     0    24 lambda.z.corrxy      NA     ""                     Too few point…
    ##  9     0    24 lambda.z.time.first  NA     ""                     Too few point…
    ## 10     0    24 lambda.z.time.last   NA     ""                     Too few point…
    ## 11     0    24 lambda.z.n.points    NA     ""                     Too few point…
    ## 12     0    24 clast.pred           NA     ""                     Too few point…
    ## 13     0    24 half.life            NA     ""                     Too few point…
    ## 14     0    24 span.ratio           NA     ""                     Too few point…
    ## 15     0    24 aucinf.obs           NA     "AUC: lin up/log down" Too few point…
    ## 16     0    24 sparse_auclast       39.5   ""                     NA            
    ## 17     0    24 sparse_auc_se         7.31  ""                     NA            
    ## 18     0    24 sparse_auc_df        NA     ""                     NA

## Sparse AUMC and Derived Parameters

In addition to `sparse_auclast` (with its standard error,
`sparse_auc_se`, and degrees of freedom, `sparse_auc_df`), the area
under the first moment curve is available as `sparse_aumclast` (with
`sparse_aumc_se` and `sparse_aumc_df`). Five parameters derived from the
sparse AUC and AUMC are also available:

- `mrt.sparse.last`: Mean residence time
  (`sparse_aumclast`/`sparse_auclast`)
- `cl.sparse.last`: Clearance (dose/`sparse_auclast`)
- `kel.sparse.last`: Elimination rate (1/`mrt.sparse.last`)
- `vss.sparse.last`: Steady-state volume of distribution
  (`cl.sparse.last`\*`mrt.sparse.last`)
- `vz.sparse.last`: Terminal volume of distribution
  (`cl.sparse.last`/`kel.sparse.last`)

The example below calculates all of them from the same data with
intravenous dose information added. Note that because `kel.sparse.last`
is calculated as 1/MRT rather than from a terminal log-linear
($`\lambda_z`$) fit, `vz.sparse.last` is numerically equal to
`vss.sparse.last`.

``` r

d_dose <- data.frame(id=unique(d_sparse$id), dose=100, time=0)
o_dose <- PKNCAdose(d_dose, dose~time|id, route="intravascular")
d_intervals_derived <-
  data.frame(
    start=0,
    end=24,
    sparse_auclast=TRUE,
    sparse_aumclast=TRUE,
    mrt.sparse.last=TRUE,
    cl.sparse.last=TRUE,
    kel.sparse.last=TRUE,
    vss.sparse.last=TRUE,
    vz.sparse.last=TRUE
  )
o_data_derived <- PKNCAdata(o_conc_sparse, o_dose, intervals=d_intervals_derived)
o_nca_derived <- pk.nca(o_data_derived)
```

    ## Warning: Cannot yet calculate sparse degrees of freedom for multiple samples
    ## per subject

    ## Warning: Cannot yet calculate sparse degrees of freedom for multiple samples
    ## per subject

``` r

as.data.frame(o_nca_derived)
```

    ## # A tibble: 11 × 6
    ##    start   end PPTESTCD        PPORRES PPANMETH exclude
    ##    <dbl> <dbl> <chr>             <dbl> <chr>    <chr>  
    ##  1     0    24 sparse_auclast   39.5   ""       NA     
    ##  2     0    24 sparse_auc_se     7.31  ""       NA     
    ##  3     0    24 sparse_auc_df    NA     ""       NA     
    ##  4     0    24 sparse_aumclast 296.    ""       NA     
    ##  5     0    24 sparse_aumc_se   66.9   ""       NA     
    ##  6     0    24 sparse_aumc_df   NA     ""       NA     
    ##  7     0    24 cl.sparse.last    2.53  ""       NA     
    ##  8     0    24 mrt.sparse.last   7.49  ""       NA     
    ##  9     0    24 vss.sparse.last  19.0   ""       NA     
    ## 10     0    24 kel.sparse.last   0.134 ""       NA     
    ## 11     0    24 vz.sparse.last   19.0   ""       NA

## Notes on Sparse Calculation Behavior

### Degrees of freedom with multiple samples per subject

The degrees of freedom (`sparse_auc_df` and `sparse_aumc_df`) can only
be calculated when each subject contributes a single sample to the
profile (as in a serial sacrifice design). When any subject contributes
more than one sample, as in the example data here, PKNCA warns that it
“Cannot yet calculate sparse degrees of freedom for multiple samples per
subject”, and the degrees of freedom are `NA`. That warning is the
source of the warnings in the results above. The point estimates and
standard errors are still calculated.

### More than half of the measurements below the limit of quantification

When calculating the mean concentration at a time point (see
[`sparse_mean()`](https://humanpred.github.io/pknca/reference/sparse_mean.md)),
if strictly more than 50% of the measurements at that time point are
below the limit of quantification (BLQ), the mean for that time point is
set to zero. At exactly 50% BLQ, the mean is calculated normally
(including the BLQ values as zero).

### Only the linear trapezoidal method is supported

Sparse AUC and AUMC are only defined with the linear trapezoidal method
in PKNCA. Calling
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md)
with any other `method` is an error, and sparse calculations within
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
always use the linear method (the `auc.method` option does not apply to
them).
