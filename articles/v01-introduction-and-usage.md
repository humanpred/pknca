# Introduction to PKNCA and Usage Instructions

PKNCA provides functions to complete noncompartmental analysis (NCA) for
pharmacokinetic (PK) data. Its intent is to provide a complete R-based
solution enabling data provenance for NCA. This will include the
tracking of data cleaning, enabling of calculations, exporting of
results, and general reporting. The library is designed to give a
reasonable answer without user intervention (load, calculate, and
summarize), but it allows the user to override the automatic selections
at any point.

The library design is modular to allow expansion based on needs
unforeseen by the authors including new NCA parameters, novel data
cleaning methods, and modular summarization decisions. Expanding the
library will be discussed in a separate vignette.

## Quick Start

The simplest analysis requires concentration data at a minimum; adding
dosing data enables automatic interval determination and dose-dependent
parameters (without dosing data, `intervals` must be provided to
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)).
Given concentration and dosing data, it then takes five function calls
to provide summarized results. (This example runs as-is; a few later
examples in this document– the grouping and manual-interval sketches–
only illustrate the workflow without running. For another complete
example, please see [the theophylline
example](https://humanpred.github.io/pknca/articles/v02-example-theophylline.md).)

``` r

library(PKNCA)
library(dplyr, quietly = TRUE)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r

## Load the PK concentration data
d_conc <- as.data.frame(datasets::Theoph)
## Generate the dosing data
d_dose <- d_conc[d_conc$Time == 0,]

## Create a concentration object specifying the concentration, time, and
## subject columns.  (Note that any number of grouping levels is
## supported; you are not restricted to just grouping by subject.)
o_conc <-
  PKNCAconc(
    d_conc,
    conc~Time|Subject
  )
## Create a dosing object specifying the dose, time, and subject
## columns.  (Note that the grouping factors should be the same as or a
## subset of the grouping factors for concentration, and the grouping
## columns must have the same names between concentration and dose
## objects.)
o_dose <-
  PKNCAdose(
    d_dose,
    Dose~Time|Subject
  )
## Combine the concentration and dosing information both to
## automatically define the intervals for NCA calculation and provide
## doses for calculations requiring dose.
o_data <- PKNCAdata(o_conc, o_dose)

## Calculate the NCA parameters
o_nca <- pk.nca(o_data)

## Summarize the results
summary(o_nca)
```

    ##  start end  N     auclast        cmax               tmax                 tlag
    ##      0 Inf 12 98.7 [22.5] 8.65 [17.0] 1.14 [0.630, 3.55] 0.000 [0.000, 0.000]
    ##         count.conc   half.life aucinf.obs aucpext.inf.obs    cl.inf.obs
    ##  11.0 [11.0, 11.0] 8.18 [2.12] 115 [28.4]     13.8 [6.34] 0.0398 [29.4]
    ## 
    ## Caption: auclast, cmax, aucinf.obs, cl.inf.obs: geometric mean and geometric coefficient of variation; tmax, tlag, count.conc: median and range; half.life, aucpext.inf.obs: arithmetic mean and standard deviation; N: number of subjects

Note that
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
also accepts a `route` argument (`"extravascular"` or
`"intravascular"`); when it is not given, extravascular administration
is assumed.

## Data Handling

After loading data, it must be in the right form. The minimum
requirements are that concentration, dose, and time must all be numeric
(and not factors). Grouping variables have no specific requirements;
they can be any mode.

Values below the limit of quantification are coded as zeros (`0`), and
missing values are coded as `NA`. If the limit of quantification itself
is available, it can be given with the `lloq` argument to
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
(a value or a column name), and it is carried through to the
censored-likelihood (Tobit) half-life method (`hl_method = "tobit"`);
see the [Tobit half-life
vignette](https://humanpred.github.io/pknca/articles/v06-half-life-calculation-tobit.md)
for details.

Units may be assigned when creating the input objects with the unit
arguments to
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
and
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
(`concu`, `timeu`, `amountu`, `doseu`, and their `*_pref` counterparts
for automatic conversion). When units are given, a units table is
automatically created during
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
construction so that calculated parameters carry their units. See the
[unit assignment and conversion
vignette](https://humanpred.github.io/pknca/articles/v07-unit-conversion.md)
for details.

## Options: Make PKNCA Work Your Way

### Calculation Options: the PKNCA.options Function

Different organizations have different requirements for computation and
summarization of NCA. Options for how to perform calculations and
summaries are handled by the `PKNCA.options` command.

Default options have been set to commonly-used standard parameters. The
current value for options can be found by running the command with no
arguments:

``` r

PKNCA.options()
```

    ## $adj.r.squared.factor
    ## [1] 1e-04
    ## 
    ## $r.squared.factor
    ## [1] NA
    ## 
    ## $max.missing
    ## [1] 0.5
    ## 
    ## $auc.method
    ## [1] "lin up/log down"
    ## 
    ## $conc.na
    ## [1] "drop"
    ## 
    ## $conc.blq
    ## $conc.blq$first
    ## [1] "keep"
    ## 
    ## $conc.blq$middle
    ## [1] "drop"
    ## 
    ## $conc.blq$last
    ## [1] "keep"
    ## 
    ## 
    ## $debug
    ## NULL
    ## 
    ## $first.tmax
    ## [1] TRUE
    ## 
    ## $first.tmin
    ## [1] TRUE
    ## 
    ## $allow.tmax.in.half.life
    ## [1] FALSE
    ## 
    ## $keep_interval_cols
    ## NULL
    ## 
    ## $min.hl.points
    ## [1] 3
    ## 
    ## $max.hl.points
    ## [1] Inf
    ## 
    ## $min.hl.start.time
    ## [1] 0
    ## 
    ## $min.span.ratio
    ## [1] 2
    ## 
    ## $max.aucinf.pext
    ## [1] 20
    ## 
    ## $min.hl.r.squared
    ## [1] 0.9
    ## 
    ## $progress
    ## [1] TRUE
    ## 
    ## $tau.choices
    ## [1] NA
    ## 
    ## $auto.interval.method
    ## [1] "builder"
    ## 
    ## $auto.interval.tolerance
    ## [1] 0.05
    ## 
    ## $single.dose.aucs
    ##   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
    ## 1     0  24    TRUE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
    ## 2     0 Inf   FALSE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
    ##   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
    ## 1       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
    ## 2       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
    ##   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbext.int.last
    ## 1        FALSE       FALSE         FALSE        FALSE               FALSE
    ## 2        FALSE       FALSE         FALSE        FALSE               FALSE
    ##   aucivpbext.int.all aumcivint.last aumcivint.all    c0  cmax  cmin  tmax  tmin
    ## 1              FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
    ## 2              FALSE          FALSE         FALSE FALSE  TRUE FALSE  TRUE FALSE
    ##   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
    ## 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
    ## 2 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
    ##   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
    ## 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
    ## 2         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
    ##   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
    ## 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
    ## 2         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
    ##   vss.int.last vss.ivint.all vss.ivint.last cav.last cav.int.last cav.int.all
    ## 1        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
    ## 2        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
    ##   cav.all cav.ivint.last cav.ivint.all ctrough cstart   ptr  tlag deg.fluc
    ## 1   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE    FALSE
    ## 2   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE    FALSE
    ##   swing  ceoi aucabove.predose.all aucabove.trough.all count.conc
    ## 1 FALSE FALSE                FALSE               FALSE      FALSE
    ## 2 FALSE FALSE                FALSE               FALSE      FALSE
    ##   count.conc.measured totdose volpk    ae clr.last clr.int.inf.pred
    ## 1               FALSE   FALSE FALSE FALSE    FALSE            FALSE
    ## 2               FALSE   FALSE FALSE FALSE    FALSE            FALSE
    ##   clr.int.inf.obs clr.int.all clr.int.last clr.all clr.inf.obs clr.inf.pred
    ## 1           FALSE       FALSE        FALSE   FALSE       FALSE        FALSE
    ## 2           FALSE       FALSE        FALSE   FALSE       FALSE        FALSE
    ##      fe ertlst ermax ertmax erint erlst ratio.cmax ratio.auclast
    ## 1 FALSE  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE
    ## 2 FALSE  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE
    ##   ratio.aucint.last ratio.aucint.all sparse_auclast sparse_auc_se sparse_auc_df
    ## 1             FALSE            FALSE          FALSE         FALSE         FALSE
    ## 2             FALSE            FALSE          FALSE         FALSE         FALSE
    ##   sparse_aumclast sparse_aumc_se sparse_aumc_df time.above aucivlast
    ## 1           FALSE          FALSE          FALSE      FALSE     FALSE
    ## 2           FALSE          FALSE          FALSE      FALSE     FALSE
    ##   aucivlast_se aucivlast_df aucivall aucivall_se aucivall_df aucivpbext.last
    ## 1        FALSE        FALSE    FALSE       FALSE       FALSE           FALSE
    ## 2        FALSE        FALSE    FALSE       FALSE       FALSE           FALSE
    ##   aucivpbext.all aumcivlast aumcivlast_se aumcivlast_df aumcivall aumcivall_se
    ## 1          FALSE      FALSE         FALSE         FALSE     FALSE        FALSE
    ## 2          FALSE      FALSE         FALSE         FALSE     FALSE        FALSE
    ##   aumcivall_df half.life r.squared adj.r.squared lambda.z.corrxy lambda.z
    ## 1        FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
    ## 2        FALSE      TRUE     FALSE         FALSE           FALSE    FALSE
    ##   lambda.z.time.first lambda.z.time.last lambda.z.n.points clast.pred
    ## 1               FALSE              FALSE             FALSE      FALSE
    ## 2               FALSE              FALSE             FALSE      FALSE
    ##   span.ratio tobit.residual adj.tobit.residual lambda.z.n.points.blq
    ## 1      FALSE          FALSE              FALSE                 FALSE
    ## 2      FALSE          FALSE              FALSE                 FALSE
    ##   thalf.eff.last thalf.eff.int.all thalf.eff.int.last thalf.eff.all
    ## 1          FALSE             FALSE              FALSE         FALSE
    ## 2          FALSE             FALSE              FALSE         FALSE
    ##   thalf.eff.iv.last thalf.eff.ivint.all thalf.eff.ivint.last kel.last
    ## 1             FALSE               FALSE                FALSE    FALSE
    ## 2             FALSE               FALSE                FALSE    FALSE
    ##   kel.iv.last kel.all kel.int.all kel.int.last kel.ivint.all kel.ivint.last
    ## 1       FALSE   FALSE       FALSE        FALSE         FALSE          FALSE
    ## 2       FALSE   FALSE       FALSE        FALSE         FALSE          FALSE
    ##   cl.iv.all cl.iv.last cl.sparse.last f.last f.all f.int.last f.int.all
    ## 1     FALSE      FALSE          FALSE  FALSE FALSE      FALSE     FALSE
    ## 2     FALSE      FALSE          FALSE  FALSE FALSE      FALSE     FALSE
    ##   mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last vz.iv.all vz.iv.last
    ## 1           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
    ## 2           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
    ##   vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.sparse.last cav.iv.last
    ## 1        FALSE         FALSE   FALSE      FALSE           FALSE       FALSE
    ## 2        FALSE         FALSE   FALSE      FALSE           FALSE       FALSE
    ##   cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred aumcinf.obs
    ## 1      FALSE      FALSE         FALSE         FALSE       FALSE       FALSE
    ## 2      FALSE       TRUE         FALSE         FALSE       FALSE       FALSE
    ##   aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs aucint.inf.pred
    ## 1          FALSE          FALSE        FALSE          FALSE           FALSE
    ## 2          FALSE          FALSE        FALSE          FALSE           FALSE
    ##   aumcint.inf.obs aumcint.inf.pred aucivint.inf.obs aucivint.inf.pred
    ## 1           FALSE            FALSE            FALSE             FALSE
    ## 2           FALSE            FALSE            FALSE             FALSE
    ##   aucivinf.obs aucivinf.obs_se aucivinf.obs_df aucivinf.pred aucivpbext.inf.obs
    ## 1        FALSE           FALSE           FALSE         FALSE              FALSE
    ## 2        FALSE           FALSE           FALSE         FALSE              FALSE
    ##   aucivpbext.inf.pred aumcivint.inf.pred aumcivint.inf.obs aumcivinf.obs
    ## 1               FALSE              FALSE             FALSE         FALSE
    ## 2               FALSE              FALSE             FALSE         FALSE
    ##   aumcivinf.obs_se aumcivinf.obs_df aumcivinf.pred thalf.eff.iv.all
    ## 1            FALSE            FALSE          FALSE            FALSE
    ## 2            FALSE            FALSE          FALSE            FALSE
    ##   aucpext.inf.obs aucpext.inf.pred kel.iv.all kel.sparse.last cl.inf.obs
    ## 1           FALSE            FALSE      FALSE           FALSE      FALSE
    ## 2           FALSE            FALSE      FALSE           FALSE      FALSE
    ##   cl.inf.pred cl.int.inf.obs cl.int.inf.pred cl.iv.inf.obs cl.iv.inf.pred
    ## 1       FALSE          FALSE           FALSE         FALSE          FALSE
    ## 2       FALSE          FALSE           FALSE         FALSE          FALSE
    ##   cl.ivint.inf.pred cl.ivint.inf.obs f.inf.obs f.inf.pred f.int.inf.obs
    ## 1             FALSE            FALSE     FALSE      FALSE         FALSE
    ## 2             FALSE            FALSE     FALSE      FALSE         FALSE
    ##   f.int.inf.pred mrt.inf.obs mrt.inf.pred mrt.int.inf.obs mrt.int.inf.pred
    ## 1          FALSE       FALSE        FALSE           FALSE            FALSE
    ## 2          FALSE       FALSE        FALSE           FALSE            FALSE
    ##   mrt.iv.inf.obs mrt.iv.inf.pred mrt.ivint.inf.pred mrt.ivint.inf.obs
    ## 1          FALSE           FALSE              FALSE             FALSE
    ## 2          FALSE           FALSE              FALSE             FALSE
    ##   mrt.md.inf.obs mrt.md.inf.pred mrt.ivmd.inf.obs mrt.ivmd.inf.pred vz.inf.obs
    ## 1          FALSE           FALSE            FALSE             FALSE      FALSE
    ## 2          FALSE           FALSE            FALSE             FALSE      FALSE
    ##   vz.inf.pred vz.int.inf.obs vz.int.inf.pred vz.iv.inf.obs vz.iv.inf.pred
    ## 1       FALSE          FALSE           FALSE         FALSE          FALSE
    ## 2       FALSE          FALSE           FALSE         FALSE          FALSE
    ##   vz.ivint.inf.pred vz.ivint.inf.obs vz.sparse.last vss.inf.obs vss.inf.pred
    ## 1             FALSE            FALSE          FALSE       FALSE        FALSE
    ## 2             FALSE            FALSE          FALSE       FALSE        FALSE
    ##   vss.iv.inf.obs vss.iv.inf.pred vss.md.inf.obs vss.md.inf.pred
    ## 1          FALSE           FALSE          FALSE           FALSE
    ## 2          FALSE           FALSE          FALSE           FALSE
    ##   vss.ivmd.inf.obs vss.ivmd.inf.pred vss.int.inf.obs vss.int.inf.pred
    ## 1            FALSE             FALSE           FALSE            FALSE
    ## 2            FALSE             FALSE           FALSE            FALSE
    ##   vss.ivint.inf.pred vss.ivint.inf.obs cav.int.inf.obs cav.int.inf.pred
    ## 1              FALSE             FALSE           FALSE            FALSE
    ## 2              FALSE             FALSE           FALSE            FALSE
    ##   cav.ivint.inf.obs cav.ivint.inf.pred ratio.aucinf.obs ratio.aucinf.pred
    ## 1             FALSE              FALSE            FALSE             FALSE
    ## 2             FALSE              FALSE            FALSE             FALSE
    ##   thalf.eff.inf.obs thalf.eff.inf.pred thalf.eff.int.inf.pred
    ## 1             FALSE              FALSE                  FALSE
    ## 2             FALSE              FALSE                  FALSE
    ##   thalf.eff.int.inf.obs thalf.eff.iv.inf.obs thalf.eff.iv.inf.pred
    ## 1                 FALSE                FALSE                 FALSE
    ## 2                 FALSE                FALSE                 FALSE
    ##   thalf.eff.ivint.inf.pred thalf.eff.ivint.inf.obs kel.inf.obs kel.inf.pred
    ## 1                    FALSE                   FALSE       FALSE        FALSE
    ## 2                    FALSE                   FALSE       FALSE        FALSE
    ##   kel.iv.inf.obs kel.iv.inf.pred kel.int.inf.obs kel.int.inf.pred
    ## 1          FALSE           FALSE           FALSE            FALSE
    ## 2          FALSE           FALSE           FALSE            FALSE
    ##   kel.ivint.inf.pred kel.ivint.inf.obs auclast.dn aucall.dn aucinf.obs.dn
    ## 1              FALSE             FALSE      FALSE     FALSE         FALSE
    ## 2              FALSE             FALSE      FALSE     FALSE         FALSE
    ##   aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn
    ## 1          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
    ## 2          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
    ##   cmin.dn clast.obs.dn clast.pred.dn cav.last.dn ctrough.dn adj_tobit_residual
    ## 1   FALSE        FALSE         FALSE       FALSE      FALSE              FALSE
    ## 2   FALSE        FALSE         FALSE       FALSE      FALSE              FALSE
    ##   aucivpbextall aucivpbextinf.obs aucivpbextinf.pred aucivpbextint.all
    ## 1         FALSE             FALSE              FALSE             FALSE
    ## 2         FALSE             FALSE              FALSE             FALSE
    ##   aucivpbextint.last aucivpbextlast aucpext.obs aucpext.pred   cav cav.dn
    ## 1              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
    ## 2              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
    ##   cl.iv.obs cl.iv.pred cl.obs cl.pred clr.obs clr.pred count_conc
    ## 1     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
    ## 2     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
    ##   count_conc_measured f.int.obs f.int.pred f.obs f.pred kel.iv.obs kel.iv.pred
    ## 1               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
    ## 2               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
    ##   kel.obs kel.pred lambda.z.n.points_blq mrt.iv.obs mrt.iv.pred mrt.ivmd.obs
    ## 1   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
    ## 2   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
    ##   mrt.ivmd.pred mrt.md.obs mrt.md.pred mrt.obs mrt.pred thalf.eff.iv.obs
    ## 1         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
    ## 2         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
    ##   thalf.eff.iv.pred thalf.eff.obs thalf.eff.pred time_above tobit_residual
    ## 1             FALSE         FALSE          FALSE      FALSE          FALSE
    ## 2             FALSE         FALSE          FALSE      FALSE          FALSE
    ##   vss.iv.obs vss.iv.pred vss.ivmd.obs vss.ivmd.pred vss.md.obs vss.md.pred
    ## 1      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
    ## 2      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
    ##   vss.obs vss.pred vz.iv.obs vz.iv.pred vz.obs vz.pred
    ## 1   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE
    ## 2   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE
    ## 
    ## $allow_partial_missing_units
    ## [1] FALSE
    ## 
    ## $hl_method
    ## [1] "log-linear"
    ## 
    ## $sparse_lambda_z_se
    ## [1] "delta"
    ## 
    ## $tobit_n_points_penalty
    ## [1] 0
    ## 
    ## $tobit_optim_control
    ## list()

And, to reset the current values to the library defaults, run the
function with the default argument set to `TRUE`.

``` r

PKNCA.options(default = TRUE)
```

Each of the options is documented where it is used; for example, the
first.tmax option is documented in the `pk.calc.tmax` function.

### Summarization Options: the PKNCA.set.summary Function

On top of methods of calculation, summarization method preferences
differ. Typical summarization preferences include selection of the
measurement of central tendency and dispersion, handling of missing
values, handling of values below the limit of quantification, and more.
Beyond the method for summarization, presentation is managed through
user preferences. Presentation is typically controlled by rounding to
either a defined number of decimal places or significant figures.

An example is that C_(max) may be summarized by the geometric mean with
the geometric CV using three significant figures, and having a summary
result requires that at least half of the available values are present
(not missing). The code below will set this example.

``` r

PKNCA.set.summary(
  name = "cmax",
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv,
  rounding = list(signif = 3)
)
```

Another example is that T_(max) is usually summarized by the median and
range, and as measurements are often taken with minute resolution and
recorded in hours, reporting is usually to the second decimal place.

``` r

PKNCA.set.summary(
  name = "tmax",
  description = "median and range",
  point = business.median,
  spread = business.range,
  rounding = list(round = 2)
)
```

If the functions or default rounding options provided in the library do
not meet the summarization needs, a user-supplied function can be used
for rounding.

``` r

median_na <- function(x) {
  median(x, na.rm = TRUE)
}
quantprob_na <- function(x) {
  quantile(x, probs = c(0.05, 0.95), na.rm = TRUE)
}
PKNCA.set.summary(
  name = "auclast",
  description = "median and 5th to 95th percentile",
  point = median_na,
  spread = quantprob_na,
  rounding = list(signif = 3)
)
```

In some cases multiple parameters may need the same summary functions
(as often occurs with simulated data). Many parameters can be set
simultaneously by specifying a vector of `name`s.

``` r

median_na <- function(x) {
  median(x, na.rm = TRUE)
}
quantprob_na <- function(x) {
  quantile(x, probs = c(0.05, 0.95), na.rm = TRUE)
}
PKNCA.set.summary(
  name = c("auclast", "cmax", "tmax", "half.life", "aucinf.pred"),
  description = "median and 5th to 95th percentile",
  point = median_na,
  spread = quantprob_na,
  rounding = list(signif = 3)
)
```

## Grouping NCA Data

As described in the [quick start](#quick-start), concentration and dose
data are generally grouped to identify how to separate the data. Typical
groups for concentration data include study, treatment, subject, and
analyte. Typical groups for dose data include study, treatment, and
subject. By default, summaries are produced based on the concentration
groups dropping the subject (so that averages are taken across subjects
within the other parameters).

The quick start example can be extended to include multiple analytes as
follows. The only difference is the `/analyte` formula element in the
concentration data. The reason for the slash instead of the plus is that
the last element before a slash is assumed to be the subject, and as
noted before, the subject is (by default) excluded from the summary
grouping (so that summaries are grouped by study, treatment, etc., but
not by subject).

``` r

## Generate a faux multi-study, multi-analyte dataset.
d_conc_parent <- d_conc
d_conc_parent$Subject <- as.numeric(as.character(d_conc_parent$Subject))
d_conc_parent$Study <- d_conc_parent$Subject <= 6
d_conc_parent$Analyte <- "Parent"
d_conc_metabolite <- d_conc_parent
d_conc_metabolite$conc <- d_conc_metabolite$conc/2
d_conc_metabolite$Analyte <- "Metabolite"
d_conc_both <- rbind(d_conc_parent, d_conc_metabolite)
d_conc_both <- d_conc_both[with(d_conc_both, order(Study, Subject, Time, Analyte)),]
d_dose_both <- d_conc_both[d_conc_both$Time == 0 & d_conc_both$Analyte %in% "Parent",
                           c("Study", "Subject", "Dose", "Time")]

## Create a concentration object specifying the concentration, time,
## study, and subject columns.  (Note that any number of grouping
## levels is supported; you are not restricted to this list.)
o_conc <- PKNCAconc(d_conc_both, conc~Time|Study+Subject/Analyte)
## Create a dosing object specifying the dose, time, study, and
## subject columns.  (Note that the grouping factors should be a
## subset of the grouping factors for concentration, and the columns
## must have the same names between concentration and dose objects.)
o_dose <- PKNCAdose(d_dose_both, Dose~Time|Study+Subject)

# Perform and summarize the PK data as previously described
o_data <- PKNCAdata(o_conc, o_dose)
o_nca <- pk.nca(o_data)
summary(o_nca)
```

## Selecting Calculation Intervals

All NCA calculations require the interval over which they are
calculated. When the concentration and dosing information are combined
to the PKNCAdata object, intervals are automatically determined. The
exception to this automatic determination is if the user provides
intervals.

When selected either automatically or manually, intervals define at
minimum a start time, an end time, and the parameters to be calculated.
The parameter list is available from the `get.interval.cols` function.
The parameters requested are specified by setting the entry in a
data.frame as requested.

``` r

intervals <-
  data.frame(
    start=0, end=c(24, Inf),
    cmax=c(FALSE, TRUE),
    tmax=c(FALSE, TRUE),
    auclast=TRUE,
    aucinf.obs=c(FALSE, TRUE)
  )
```

Intervals like the one above are sufficient for designs with a single
type of treatment– such as single doses. For more complex treatments in
a single analysis, like the combination of single and multiple doses,
include a treatment column matching the treatment column name from the
concentration data set. See the [Manual Interval
Specification](#manual-interval-specification) section below for more
details.

### Selection of Data Used for Calculation

When choosing which data is used for a calculation, PKNCA will never
look beyond the data specified in the group and interval. Groups are
defined by the call to the `PKNCAconc` function, and they will typically
define the measurement of a single analyte from a single individual
receiving a single treatment. Intervals are subsets within a group by
start and end time. PKNCA never examines data outside of the group and
interval for standard NCA calculations. As an example, with data from 0
to 48 hours and an interval set to `start` at 0 and `end` at 24 with the
calculation of `aucinf.obs`, any data after 24 hours will not be used
for the half-life or AUC_(inf) calculations.

A few functions look at data outside of a single interval, but these
functions do not look at data outside of a single group, and these
functions are typically used during preparation for NCA calculations not
for the calculations themselves. Functions that look at a group as a
whole include `choose.auc.intervals`, `find.tau`, and `pk.tss`.

### Automatic Interval Determination

If intervals are not specified when combining the concentration and
dosing data, they will automatically be found from the concentration and
dosing data.

Single dose data has a simple interval selection: the option
`single.dose.aucs` is used from the `PKNCA.options`.

| start | end | auclast | auclast_se | auclast_df | aucall | aucall_se | aucall_df | aumclast | aumclast_se | aumclast_df | aumcall | aumcall_se | aumcall_df | aucint.last | aucint.all | aumcint.last | aumcint.all | aucivint.last | aucivint.all | aucivpbext.int.last | aucivpbext.int.all | aumcivint.last | aumcivint.all | c0 | cmax | cmin | tmax | tmin | tlast | tfirst | clast.obs | cl.last | cl.all | cl.int.all | cl.int.last | cl.ivint.all | cl.ivint.last | mrt.last | mrt.all | mrt.int.all | mrt.int.last | mrt.iv.last | mrt.ivint.all | mrt.ivint.last | vss.last | vss.iv.last | vss.all | vss.int.all | vss.int.last | vss.ivint.all | vss.ivint.last | cav.last | cav.int.last | cav.int.all | cav.all | cav.ivint.last | cav.ivint.all | ctrough | cstart | ptr | tlag | deg.fluc | swing | ceoi | aucabove.predose.all | aucabove.trough.all | count.conc | count.conc.measured | totdose | volpk | ae | clr.last | clr.int.inf.pred | clr.int.inf.obs | clr.int.all | clr.int.last | clr.all | clr.inf.obs | clr.inf.pred | fe | ertlst | ermax | ertmax | erint | erlst | ratio.cmax | ratio.auclast | ratio.aucint.last | ratio.aucint.all | sparse_auclast | sparse_auc_se | sparse_auc_df | sparse_aumclast | sparse_aumc_se | sparse_aumc_df | time.above | aucivlast | aucivlast_se | aucivlast_df | aucivall | aucivall_se | aucivall_df | aucivpbext.last | aucivpbext.all | aumcivlast | aumcivlast_se | aumcivlast_df | aumcivall | aumcivall_se | aumcivall_df | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | tobit.residual | adj.tobit.residual | lambda.z.n.points.blq | thalf.eff.last | thalf.eff.int.all | thalf.eff.int.last | thalf.eff.all | thalf.eff.iv.last | thalf.eff.ivint.all | thalf.eff.ivint.last | kel.last | kel.iv.last | kel.all | kel.int.all | kel.int.last | kel.ivint.all | kel.ivint.last | cl.iv.all | cl.iv.last | cl.sparse.last | f.last | f.all | f.int.last | f.int.all | mrt.sparse.last | mrt.iv.all | vz.all | vz.int.all | vz.int.last | vz.iv.all | vz.iv.last | vz.ivint.all | vz.ivint.last | vz.last | vss.iv.all | vss.sparse.last | cav.iv.last | cav.iv.all | aucinf.obs | aucinf.obs_se | aucinf.obs_df | aucinf.pred | aumcinf.obs | aumcinf.obs_se | aumcinf.obs_df | aumcinf.pred | aucint.inf.obs | aucint.inf.pred | aumcint.inf.obs | aumcint.inf.pred | aucivint.inf.obs | aucivint.inf.pred | aucivinf.obs | aucivinf.obs_se | aucivinf.obs_df | aucivinf.pred | aucivpbext.inf.obs | aucivpbext.inf.pred | aumcivint.inf.pred | aumcivint.inf.obs | aumcivinf.obs | aumcivinf.obs_se | aumcivinf.obs_df | aumcivinf.pred | thalf.eff.iv.all | aucpext.inf.obs | aucpext.inf.pred | kel.iv.all | kel.sparse.last | cl.inf.obs | cl.inf.pred | cl.int.inf.obs | cl.int.inf.pred | cl.iv.inf.obs | cl.iv.inf.pred | cl.ivint.inf.pred | cl.ivint.inf.obs | f.inf.obs | f.inf.pred | f.int.inf.obs | f.int.inf.pred | mrt.inf.obs | mrt.inf.pred | mrt.int.inf.obs | mrt.int.inf.pred | mrt.iv.inf.obs | mrt.iv.inf.pred | mrt.ivint.inf.pred | mrt.ivint.inf.obs | mrt.md.inf.obs | mrt.md.inf.pred | mrt.ivmd.inf.obs | mrt.ivmd.inf.pred | vz.inf.obs | vz.inf.pred | vz.int.inf.obs | vz.int.inf.pred | vz.iv.inf.obs | vz.iv.inf.pred | vz.ivint.inf.pred | vz.ivint.inf.obs | vz.sparse.last | vss.inf.obs | vss.inf.pred | vss.iv.inf.obs | vss.iv.inf.pred | vss.md.inf.obs | vss.md.inf.pred | vss.ivmd.inf.obs | vss.ivmd.inf.pred | vss.int.inf.obs | vss.int.inf.pred | vss.ivint.inf.pred | vss.ivint.inf.obs | cav.int.inf.obs | cav.int.inf.pred | cav.ivint.inf.obs | cav.ivint.inf.pred | ratio.aucinf.obs | ratio.aucinf.pred | thalf.eff.inf.obs | thalf.eff.inf.pred | thalf.eff.int.inf.pred | thalf.eff.int.inf.obs | thalf.eff.iv.inf.obs | thalf.eff.iv.inf.pred | thalf.eff.ivint.inf.pred | thalf.eff.ivint.inf.obs | kel.inf.obs | kel.inf.pred | kel.iv.inf.obs | kel.iv.inf.pred | kel.int.inf.obs | kel.int.inf.pred | kel.ivint.inf.pred | kel.ivint.inf.obs | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.last.dn | ctrough.dn | adj_tobit_residual | aucivpbextall | aucivpbextinf.obs | aucivpbextinf.pred | aucivpbextint.all | aucivpbextint.last | aucivpbextlast | aucpext.obs | aucpext.pred | cav | cav.dn | cl.iv.obs | cl.iv.pred | cl.obs | cl.pred | clr.obs | clr.pred | count_conc | count_conc_measured | f.int.obs | f.int.pred | f.obs | f.pred | kel.iv.obs | kel.iv.pred | kel.obs | kel.pred | lambda.z.n.points_blq | mrt.iv.obs | mrt.iv.pred | mrt.ivmd.obs | mrt.ivmd.pred | mrt.md.obs | mrt.md.pred | mrt.obs | mrt.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | thalf.eff.obs | thalf.eff.pred | time_above | tobit_residual | vss.iv.obs | vss.iv.pred | vss.ivmd.obs | vss.ivmd.pred | vss.md.obs | vss.md.pred | vss.obs | vss.pred | vz.iv.obs | vz.iv.pred | vz.obs | vz.pred |
|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 0 | 24 | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE |
| 0 | Inf | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE |

For multiple-dose studies, PKNCA selects one group at a time and
compares the concentration and dosing times. When there is a
concentration measurement between doses, an interval row is added. The
dosing interval ($`\tau`$) is determined by looking for pattern repeats
within the dosing data using the `find.tau` function.

``` r

## find.tau can work when all doses have the same interval...
dose_times <- seq(0, 168, by=24)
print(dose_times)
```

    ## [1]   0  24  48  72  96 120 144 168

``` r

PKNCA::find.tau(dose_times)
```

    ## [1] 24

``` r

## or when the doses have mixed intervals (10 and 24 hours).
dose_times <- sort(c(seq(0, 168, by=24),
                     seq(10, 178, by=24)))
print(dose_times)
```

    ##  [1]   0  10  24  34  48  58  72  82  96 106 120 130 144 154 168 178

``` r

PKNCA::find.tau(dose_times)
```

    ## [1] 24

After finding $`\tau`$, PKNCA will also look after the last dose (or the
beginning of the last dosing interval), and two additional intervals may
be added:

- one interval for the dosing interval after the beginning of the last
  dosing interval (if there are concentrations measured in the interval)
- one interval for the half-life after the last dosing interval (if
  there are concentration more than $`\tau`$ after the beginning of the
  last interval).

One consequence of automatic interval selection is that many rows are
generated for intervals; one row is generated per interval per subject.
The benefit of the method producing a large number of rows is that it is
fully flexible to the actual study results. If a subject has a different
schedule than the others for the same treatment (e.g. measurements that
were nominally scheduled for day 14 occurred on day 13), those
differences will be found.

### Manual Interval Specification

Intervals can also be specified manually. Two use cases are common for
manual specification: fully manual (never requesting the automatic
intervals) and updating the automatic intervals.

Fully manual intervals can be specified by providing it to the
`PKNCAdata` call.

``` r

intervals_manual <-
  data.frame(
    start=0, end=c(24, Inf),
    cmax=c(FALSE, TRUE),
    tmax=c(FALSE, TRUE),
    auclast=TRUE,
    aucinf.obs=c(FALSE, TRUE)
  )
o_data <-
  PKNCAdata(
    o_conc, o_dose, 
    intervals=intervals_manual
  )
```

To update the automatically-selected intervals, extract the intervals,
modify them, and put them back.

``` r

o_data <- PKNCAdata(o_conc, o_dose)
intervals_manual <- o_data$intervals
intervals_manual$aucinf.obs[1] <- TRUE
o_data$intervals <- intervals_manual
```

### Keeping a column from intervals

When computing NCA using actual times, grouping by start and end time in
summaries (see later) is less helpful because everyone could have
different start and end times. So, you may keep the interval columns
using the option `"keep_interval_cols"` as follows (where “dosetype”
must be a column name in the intervals):

``` r

o_data <- PKNCAdata(o_conc, o_dose, options = list(keep_interval_cols = "dosetype"))
```

## Summarizing results

When NCA has been calculated, you can summarize the results with the
[`summary()`](https://rdrr.io/r/base/summary.html) function, and the
row-level (individual) results are available with
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) (which
can also generate CDISC PP-style output with
`as.data.frame(o_nca, out_format = "cdisc")`).

``` r

summary(o_nca)
```

By default, it will count the number of unique subjects (`N`) in the
summary, and when the number of subjects differs from the number of
measurements included in a summary (`n`), it will summarize `n` for the
given parameters. Note that counting of “n” includes all non-missing
values that were not excluded from summarization; this will include all
zeros that are e.g. excluded from geometric statistics.

Edge cases like two unique subjects where one has an excluded value and
one has duplicated values (`N = 2` and `n = 2` even though both
measurements come from a single subject) are to be handled by the user.

## Updating existing results

Updating existing results is most helpful if you are writing a `shiny`
or other user interface for PKNCA. If you are using PKNCA from a script,
this is not the preferred way to perform analysis.

If you need to rerun analyses with minor updates– changing half-life
point selection, for instance– you can use
[`update()`](https://rdrr.io/r/stats/update.html) on a `PKNCAresults`
object (`o_nca` in the example above). Using
[`update()`](https://rdrr.io/r/stats/update.html) will recalculate the
minimum-required number of calculations for the data that are changed.
Only changes to the concentration or dose data are recalculated
selectively; any other change (for example, to the intervals or options)
triggers a full recalculation with a warning.

To use [`update()`](https://rdrr.io/r/stats/update.html), give it your
existing results and the new `PKNCAdata` object you want to use.

Starting from the theophylline example in the [Quick
Start](#quick-start) section above:

``` r

d_conc <- as.data.frame(datasets::Theoph)
d_dose <- d_conc[d_conc$Time == 0,]
o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
o_data <- PKNCAdata(o_conc, o_dose)
o_nca <- pk.nca(o_data)
summary(o_nca)
```

    ##  start end  N     auclast        cmax               tmax                 tlag
    ##      0 Inf 12 98.7 [22.5] 8.65 [17.0] 1.14 [0.630, 3.55] 0.000 [0.000, 0.000]
    ##         count.conc   half.life aucinf.obs aucpext.inf.obs    cl.inf.obs
    ##  11.0 [11.0, 11.0] 8.18 [2.12] 115 [28.4]     13.8 [6.34] 0.0398 [29.4]
    ## 
    ## Caption: auclast, cmax, aucinf.obs, cl.inf.obs: geometric mean and geometric coefficient of variation; tmax, tlag, count.conc: median and range; half.life, aucpext.inf.obs: arithmetic mean and standard deviation; N: number of subjects

In these data, some participants have a nonzero predose concentration.
Assume that we want to manually change those concentrations to zero and
then recalculate. You can change the concentration data, and use
[`update()`](https://rdrr.io/r/stats/update.html) to recalculate only
for the changed participants.

``` r

d_conc_setzero <- as.data.frame(datasets::Theoph)
d_conc_setzero$conc[d_conc$Time == 0] <- 0
o_conc_update <- PKNCAconc(d_conc_setzero, conc~Time|Subject)
o_data_update <- PKNCAdata(o_conc_update, o_dose)
o_nca_update <- update(o_nca, o_data_update)
summary(o_nca_update)
```

    ##  start end  N     auclast        cmax               tmax                 tlag
    ##      0 Inf 12 98.6 [22.5] 8.65 [17.0] 1.14 [0.630, 3.55] 0.000 [0.000, 0.000]
    ##         count.conc   half.life aucinf.obs aucpext.inf.obs    cl.inf.obs
    ##  11.0 [11.0, 11.0] 8.18 [2.12] 115 [28.4]     13.8 [6.34] 0.0398 [29.3]
    ## 
    ## Caption: auclast, cmax, aucinf.obs, cl.inf.obs: geometric mean and geometric coefficient of variation; tmax, tlag, count.conc: median and range; half.life, aucpext.inf.obs: arithmetic mean and standard deviation; N: number of subjects

Only the participants whose concentration data changed are recalculated;
results for all other participants are carried over unchanged.

Now, assume that instead of calculating `auclast`, we want to calculate
`aucall`. We can change the intervals to create a new `PKNCAdata`
object:

``` r

d_intervals <- o_data$intervals
d_intervals$aucall <- d_intervals$auclast
d_intervals$auclast <- FALSE
o_data_update <- PKNCAdata(o_conc, o_dose, intervals = d_intervals)
```

Then, we can update the `PKNCAresults`:

``` r

o_nca_update <- update(o_nca, o_data_update)
```

    ## Warning: Full recalculation: changes detected in data other than source
    ## concentration or dose data

``` r

summary(o_nca_update)
```

    ##  start end  N      aucall        cmax               tmax                 tlag
    ##      0 Inf 12 98.7 [22.5] 8.65 [17.0] 1.14 [0.630, 3.55] 0.000 [0.000, 0.000]
    ##         count.conc   half.life aucinf.obs aucpext.inf.obs    cl.inf.obs
    ##  11.0 [11.0, 11.0] 8.18 [2.12] 115 [28.4]     13.8 [6.34] 0.0398 [29.4]
    ## 
    ## Caption: aucall, cmax, aucinf.obs, cl.inf.obs: geometric mean and geometric coefficient of variation; tmax, tlag, count.conc: median and range; half.life, aucpext.inf.obs: arithmetic mean and standard deviation; N: number of subjects
