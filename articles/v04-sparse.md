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

Two things happen behind that flag. For the AUC and AUMC parameters with
a sparse estimator, PKNCA calculates them from the pooled samples of all
the animals in a group with the Bailer point estimate and the
Nedelman-Jia/Holder standard error, and reports the standard error and
degrees of freedom alongside the estimate with the suffixes `_se` and
`_df` (for example, `auclast_se` and `auclast_df`). Those parameters are
`auclast`, `aucall`, `aucinf.obs`, `aumclast`, `aumcall`, and
`aumcinf.obs`, and after an IV bolus `aucivlast`, `aucivall`,
`aucivinf.obs`, `aumcivlast`, `aumcivall`, and `aumcivinf.obs` (see
[`vignette("v24-sparse-auc-to-infinity")`](https://humanpred.github.io/pknca/articles/v24-sparse-auc-to-infinity.md)
for the AUC to infinity and the IV bolus $`C_0`$). Every other parameter
is calculated from the arithmetic-mean profile of the animals in the
group.

As for any AUC in PKNCA, the sparse AUCs need a concentration at the
start of the interval, measured or imputed. Animals are rarely sampled
at the dose in sacrificial designs, so after an extravascular dose
impute zero with `impute = "start_conc0"`; the imputed zero is known, so
it adds nothing to the variance.

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
    ## ("lin up/log down") does not apply to: auclast, aucinf.obs

    ## Warning: Too few points for half-life calculation (min.hl.points=3 with only 2
    ## points)

[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md)
builds the same kind of specification from a description of the study,
and its `sparse_single_dose` preset is the single-dose set with a zero
imputed at the start (`start_conc0`), the one imputation the sparse
estimators accept:

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
    ## Caption: auclast, aucinf.obs: estimate and standard error; auclast_df: arithmetic mean and standard deviation; cmax: geometric mean and geometric coefficient of variation; NC: not calculated

In the summary, the sparse `auclast` is the estimate with its standard
error in brackets (from the `auclast_se` result), as the caption says;
`auclast_se` has no column of its own.

or individual results are available through the
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) function:

``` r

as.data.frame(o_nca)
```

    ## # A tibble: 20 × 6
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
    ## 15     0    24 auclast              39.5   "AUC: linear. Sparse: arithm… NA     
    ## 16     0    24 auclast_se            7.31  "AUC: linear. Sparse: arithm… NA     
    ## 17     0    24 auclast_df            2.75  "AUC: linear. Sparse: arithm… NA     
    ## 18     0    24 aucinf.obs           NA     "AUC: linear. Sparse: arithm… Too fe…
    ## 19     0    24 aucinf.obs_se        NA     "AUC: linear. Sparse: arithm… Too fe…
    ## 20     0    24 aucinf.obs_df        NA     "AUC: linear. Sparse: arithm… Too fe…

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

## Bootstrap

The sparse standard errors above come from the variance of the means at
each time. A nonparametric bootstrap (Shen and Machado 2017) is an
alternative that applies to every parameter, including Cmax, the
half-life, and ratios between groups:
[`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md)
resamples the animals with replacement within each set of sampling times
(each time with serial sacrifice, each batch in a batch design, keeping
an animal’s samples together), and every replicate is calculated just as
the original data are. It stores the random seed so the replicates can
be reproduced, and the default of 200 replicates is enough for the mean
and standard deviation (Takemoto et al. 2006).

``` r

o_conc_boot <- sparse_bootstrap(o_conc_sparse, seed=20261007)
o_data_boot <-
  PKNCAdata(
    o_conc_boot,
    intervals=data.frame(start=0, end=24, auclast=TRUE, cmax=TRUE, tmax=TRUE),
    # Many replicate groups would otherwise show a progress bar
    options=list(progress=FALSE)
  )
o_nca_boot <- pk.nca(o_data_boot)
```

    ## The sparse estimators use the linear trapezoidal rule, so the auc.method option
    ## ("lin up/log down") does not apply to: auclast

``` r

summary(o_nca_boot)
```

    ##  start end N     auclast        cmax              tmax
    ##      0  24 9 39.2 [15.4] 3.29 [13.0] 6.00 [2.00, 10.0]
    ## 
    ## Caption: auclast, cmax: geometric mean and geometric coefficient of variation; tmax: median and range; N: number of animals in the study; summarized over 200 bootstrap replicates (seed 20261007)

The summary treats the replicates the way the summary of dense data
treats subjects, with each parameter’s usual summary statistics; `N` is
the number of animals in the study, and the caption gives the number of
replicates. The `"original"` replicate holds the data as given, so
`as.data.frame(o_nca_boot)` has the estimates as well as every
replicate. The standard deviation of the replicates is the standard
error of the estimate: with only three animals at each time, it is
smaller for `auclast` than the Nedelman-Jia/Holder standard error
(`auclast_se` above), because resampling three values understates their
variance by a factor of 2/3;
[`vignette("v24-sparse-auc-to-infinity")`](https://humanpred.github.io/pknca/articles/v24-sparse-auc-to-infinity.md)
compares the methods.

To compare groups, such as a test and a reference formulation in a
parallel design,
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
takes the bootstrap results like any other: the ratio of the estimates
is the point estimate, and its confidence interval is the percentile
interval of the replicate ratios (90% by default), judged against the
acceptance limits. For a crossover, where each animal receives every
treatment, give the treatment column as `paired` to
[`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md)
so that each replicate draws the same animals for every treatment.

``` r

d_sparse_formulations <-
  rbind(
    data.frame(d_sparse, formulation="reference"),
    data.frame(
      id=d_sparse$id + 100, conc=d_sparse$conc*c(0.9, 1.05, 1.1), time=d_sparse$time,
      dose=d_sparse$dose, formulation="test"
    )
  )
o_conc_formulations <-
  PKNCAconc(
    d_sparse_formulations, conc~time|formulation+id, sparse=TRUE,
    concu="ng/mL", timeu="hr"
  )
o_nca_formulations <-
  pk.nca(PKNCAdata(
    sparse_bootstrap(o_conc_formulations, seed=20261008),
    intervals=data.frame(start=0, end=24, auclast=TRUE, cmax=TRUE),
    options=list(progress=FALSE)
  ))
```

    ## The sparse estimators use the linear trapezoidal rule, so the auc.method option
    ## ("lin up/log down") does not apply to: auclast

``` r

be_assess(
  o_nca_formulations, reference_col="formulation", reference_value="reference",
  endpoints=c("auclast", "cmax")
)
```

    ## Bioequivalence assessment: ABE (model_type bootstrap, 90% CI)
    ## Design: parallel
    ## 
    ##  endpoint test  n   design    units gm_reference gm_reference_lower
    ##   auclast test 18 parallel hr*ng/mL        39.47              30.51
    ##      cmax test 18 parallel    ng/mL         3.05               2.65
    ##  gm_reference_upper gm_test gm_test_lower gm_test_upper gmr_percent ci_lower
    ##               48.68   38.92         31.99         46.63       98.62    72.97
    ##                4.08    2.99          2.92          3.82       98.23    73.29
    ##  ci_upper cvwr_percent cvwt_percent swr limit_lower limit_upper criterion
    ##    133.54           NA           NA  NA          80         125        NA
    ##    126.14           NA           NA  NA          80         125        NA
    ##  regulator model_type  pass
    ##        ABE  bootstrap FALSE
    ##        ABE  bootstrap FALSE
    ## 
    ## Caption: ABE bioequivalence assessment (90% CI). The estimates and their ratio come from the sparse data of each treatment; each 90% CI is the percentile interval of 200 replicates of a stratified nonparametric bootstrap (Shen and Machado 2017). Bioequivalence requires the confidence interval within 80.00-125.00%.

The bootstrap methods are from Shen M. and Machado S. G. (2017).
Bioequivalence evaluation of sparse sampling pharmacokinetics data using
bootstrap resampling method. Journal of Biopharmaceutical Statistics,
27(2):257-264, and Takemoto S., Yamaoka K., Nishikawa M. and Takakura Y.
(2006). Histogram analysis of pharmacokinetic parameters by bootstrap
resampling from one-point sampling data in animal experiments. Drug
Metabolism and Pharmacokinetics, 21(6):458-464.

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
