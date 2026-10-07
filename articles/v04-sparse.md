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

Sparse NCA is setup the same way as normal, dense PK sampling is setup
with PKNCA. The only difference is that you give the `sparse` option to
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md);
the parameters are requested by their usual names.

Two things happen behind that flag. For `auclast` and `aumclast`, PKNCA
uses the sparse estimators – the Bailer point estimate with the
Nedelman-Jia/Holder standard error – calculated from the pooled samples
of all the animals in a group, and reports the standard error and
degrees of freedom alongside the estimate as `auclast_se`/`auclast_df`
and `aumclast_se`/`aumclast_df`. Every other parameter is calculated
from the arithmetic-mean profile of the animals in the group.

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
    auclast=TRUE,
    auclast_se=TRUE,
    auclast_df=TRUE,
    aucinf.obs=TRUE,
    cmax=TRUE
  )
o_data_sparse <- PKNCAdata(o_conc_sparse, intervals=d_intervals)
o_nca <- pk.nca(o_data_sparse)
```

    ## The sparse estimators use the linear trapezoidal rule, so the auc.method option
    ## ("lin up/log down") does not apply to: auclast

    ## Warning: Too few points for half-life calculation (min.hl.points=3 with only 2
    ## points)

[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md)
builds the same kind of specification from a description of the study,
and its `sparse_single_dose` preset is the single-dose set with no
imputation (there is no individual profile to impute into):

``` r

pknca_interval_table(0, 24, preset="sparse_single_dose")
```

## Results

As with any other PKNCA result, the data are available through the
[`summary()`](https://rdrr.io/r/base/summary.html) function:

``` r

summary(o_nca)
```

    ##  start end     auclast auclast_df cmax aucinf.obs
    ##      0  24 39.5 [7.31]       2.75 3.05         NC
    ## 
    ## Caption: auclast: estimate and standard error; auclast_df: arithmetic mean and standard deviation; cmax, aucinf.obs: geometric mean and geometric coefficient of variation; NC: not calculated

In the summary, the sparse `auclast` is the estimate with its standard
error in brackets (from the `auclast_se` result), as the caption says;
`auclast_se` has no column of its own.

or individual results are available through the
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) function:

``` r

as.data.frame(o_nca)
```

    ## # A tibble: 18 × 6
    ##    start   end PPTESTCD            PPORRES PPANMETH                      exclude
    ##    <dbl> <dbl> <chr>                 <dbl> <chr>                         <chr>  
    ##  1     0    24 cmax                  3.05  ""                            NA     
    ##  2     0    24 tmax                  6     ""                            NA     
    ##  3     0    24 tlast                24     ""                            NA     
    ##  4     0    24 clast.obs             0.191 ""                            NA     
    ##  5     0    24 lambda.z             NA     ""                            Too fe…
    ##  6     0    24 r.squared            NA     ""                            Too fe…
    ##  7     0    24 adj.r.squared        NA     ""                            Too fe…
    ##  8     0    24 lambda.z.corrxy      NA     ""                            Too fe…
    ##  9     0    24 lambda.z.time.first  NA     ""                            Too fe…
    ## 10     0    24 lambda.z.time.last   NA     ""                            Too fe…
    ## 11     0    24 lambda.z.n.points    NA     ""                            Too fe…
    ## 12     0    24 clast.pred           NA     ""                            Too fe…
    ## 13     0    24 half.life            NA     ""                            Too fe…
    ## 14     0    24 span.ratio           NA     ""                            Too fe…
    ## 15     0    24 aucinf.obs           NA     "AUC: lin up/log down"        Too fe…
    ## 16     0    24 auclast              39.5   "AUC: linear. Sparse: arithm… NA     
    ## 17     0    24 auclast_se            7.31  "AUC: linear. Sparse: arithm… NA     
    ## 18     0    24 auclast_df            2.75  "AUC: linear. Sparse: arithm… NA

`auclast_se` and `auclast_df` are reported whether or not they were
requested, because the sparse estimator returns all three together. They
are only calculable from sparse data: requesting one for a dense
`PKNCAconc` is an error.

## Sparse AUC, AUMC, and Derived Parameters

Because the sparse estimate is stored under the standard parameter name,
every parameter derived from an AUC is available for sparse data with no
extra work. `cl.last` divides the dose by `auclast`, `mrt.last` divides
`aumclast` by `auclast`, and so on down the usual derived graph.

``` r

d_dose <- data.frame(id=unique(d_sparse$id), dose=100, time=0)
o_dose <- PKNCAdose(d_dose, dose~time|id, route="intravascular")
d_intervals_derived <-
  data.frame(
    start=0,
    end=24,
    auclast=TRUE,
    aumclast=TRUE,
    mrt.last=TRUE,
    cl.last=TRUE,
    kel.last=TRUE,
    vss.last=TRUE,
    vz.last=TRUE
  )
o_data_derived <- PKNCAdata(o_conc_sparse, o_dose, intervals=d_intervals_derived)
o_nca_derived <- pk.nca(o_data_derived)
```

    ## The sparse estimators use the linear trapezoidal rule, so the auc.method option
    ## ("lin up/log down") does not apply to: auclast, aumclast

    ## Warning: Too few points for half-life calculation (min.hl.points=3 with only 2
    ## points)

``` r

as.data.frame(o_nca_derived)
```

    ## # A tibble: 23 × 6
    ##    start   end PPTESTCD            PPORRES PPANMETH exclude                     
    ##    <dbl> <dbl> <chr>                 <dbl> <chr>    <chr>                       
    ##  1     0    24 tmax                   6    ""       NA                          
    ##  2     0    24 tlast                 24    ""       NA                          
    ##  3     0    24 cl.last                2.53 ""       NA                          
    ##  4     0    24 mrt.last               7.49 ""       NA                          
    ##  5     0    24 vss.last              19.0  ""       NA                          
    ##  6     0    24 lambda.z              NA    ""       Too few points for half-lif…
    ##  7     0    24 r.squared             NA    ""       Too few points for half-lif…
    ##  8     0    24 adj.r.squared         NA    ""       Too few points for half-lif…
    ##  9     0    24 lambda.z.corrxy       NA    ""       Too few points for half-lif…
    ## 10     0    24 lambda.z.time.first   NA    ""       Too few points for half-lif…
    ## # ℹ 13 more rows

Note what `vz.last` does here. It is the clearance divided by
$`\lambda_z`$, the terminal rate constant fitted on the mean profile,
which is the standard toxicokinetic approach. These data have only two
time points after the mean profile’s peak, which is too few for a
terminal fit, so $`\lambda_z`$ and therefore `vz.last` are `NA`. That is
the honest answer: the retired `vz.sparse.last` divided the clearance by
`1/MRT` instead, which always produced a number but made Vz numerically
identical to Vss.

`kel.last`, like the rest of PKNCA’s `kel` family, is `1/MRT`, so it is
unchanged from the retired `kel.sparse.last`. Ask for `lambda.z` when
you want the terminal rate constant itself.

## Deprecated Parameter Names

Sparse calculations were originally requested through a parallel set of
names. All eleven still calculate and still give the values they always
gave, but each now warns and **will be an error in the next minor
release of PKNCA**:

| Deprecated        | Use instead   |
|-------------------|---------------|
| `sparse_auclast`  | `auclast`     |
| `sparse_auc_se`   | `auclast_se`  |
| `sparse_auc_df`   | `auclast_df`  |
| `sparse_aumclast` | `aumclast`    |
| `sparse_aumc_se`  | `aumclast_se` |
| `sparse_aumc_df`  | `aumclast_df` |
| `cl.sparse.last`  | `cl.last`     |
| `mrt.sparse.last` | `mrt.last`    |
| `kel.sparse.last` | `kel.last`    |
| `vss.sparse.last` | `vss.last`    |
| `vz.sparse.last`  | `vz.last`     |

Every replacement but the last gives the same number as the name it
replaces. `vz.last` is $`\lambda_z`$-based, as described above, so it
differs from `vz.sparse.last` by design.

The functions behind the sparse estimators –
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`pk.calc.sparse_auclast()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`pk.calc.sparse_aumc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_aumc.md),
[`pk.calc.sparse_aumclast()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_aumc.md),
[`as_sparse_pk()`](https://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`sparse_mean()`](https://humanpred.github.io/pknca/reference/sparse_mean.md),
[`var_sparse_auc()`](https://humanpred.github.io/pknca/reference/var_sparse_auc.md),
and
[`cov_holder()`](https://humanpred.github.io/pknca/reference/cov_holder.md)
– are not deprecated. They are what the unified estimators call, and
they remain available for calculations outside
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md).

## Notes on Sparse Calculation Behavior

### Degrees of freedom with multiple samples per subject

The degrees of freedom (`auclast_df` and `aumclast_df`) are the
Satterthwaite approximation of Nedelman and Jia (1998), which accounts
for the correlation between samples from the same subject, so they are
calculated whether each subject contributes one sample (as in a serial
sacrifice design) or several (as in the example data here and in batch
designs). They are `NA` when a time point has a single subject, because
its variance cannot be estimated.

### More than half of the measurements below the limit of quantification

When calculating the mean concentration at a time point (see
[`sparse_mean()`](https://humanpred.github.io/pknca/reference/sparse_mean.md)),
if strictly more than 50% of the measurements at that time point are
below the limit of quantification (BLQ), the mean for that time point is
set to zero. At exactly 50% BLQ, the mean is calculated normally
(including the BLQ values as zero).

### Only the linear trapezoidal method is supported

The sparse variance theory is derived for a fixed-weight linear
combination of the per-time-point means, so the sparse estimators are
defined with the linear trapezoidal method only. Calling
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md)
with any other `method` is an error, and within
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md) the
sparse estimators always use the linear method: the `auc.method` option
does not apply to them, and
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md) says
so once per run when the option asks for anything else. Parameters that
fall back to the mean profile, such as `aucinf.obs`, do follow
`auc.method`.
