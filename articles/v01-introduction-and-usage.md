# Introduction to PKNCA and Usage Instructions

PKNCA provides functions to complete noncompartmental analysis (NCA) for
pharmacokinetic (PK) data. Its intent is to provide a complete R-based
solution-enabling data provenance for NCA. This will include the
tracking of data cleaning, enabling of calculations, exporting of
results, and general reporting. The library is designed to give a
reasonable answer without user intervention (load, calculate, and
summarize), but it allows the user to override the automatic selections
at any point.

The library design is modular to allow expansion based on needs
unforseen by the authors including new NCA parameters, novel data
cleaning methods, and modular summarization decisions. Expanding the
library will be discussed in a separate vignette.

## Quick Start

The simplest analysis requires concentration and dosing data at a
minimum. Given this, it then takes five function calls to provide
summarized results. (Please note that this and the other examples in
this document are intended to show the typical workflow, but they are
not intended to run directly. For an example to run directly, please see
[the theophylline
example](http://humanpred.github.io/pknca/articles/v02-example-theophylline.md).)

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

    ##  start end  N     auclast        cmax               tmax   half.life aucinf.obs
    ##      0  24 12 74.6 [24.3]           .                  .           .          .
    ##      0 Inf 12           . 8.65 [17.0] 1.14 [0.630, 3.55] 8.18 [2.12] 115 [28.4]
    ## 
    ## Caption: auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects

## Data Handling

After loading data, it must be in the right form. The minimum
requirements are that concentration, dose, and time must all be numeric
(and not factors). Grouping variables have no specific requirements;
they can be any mode.

Values below the limit of quantification are coded as zeros (`0`), and
missing values are coded as `NA`.

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
    ## $allow.tmax.in.half.life
    ## [1] FALSE
    ## 
    ## $keep_interval_cols
    ## NULL
    ## 
    ## $min.hl.points
    ## [1] 3
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
    ## $single.dose.aucs
    ##   start end auclast aucall aumclast aumcall aucint.last aucint.last.dose
    ## 1     0  24    TRUE  FALSE    FALSE   FALSE       FALSE            FALSE
    ## 2     0 Inf   FALSE  FALSE    FALSE   FALSE       FALSE            FALSE
    ##   aucint.all aucint.all.dose    c0  cmax  cmin  tmax tlast tfirst clast.obs
    ## 1      FALSE           FALSE FALSE FALSE FALSE FALSE FALSE  FALSE     FALSE
    ## 2      FALSE           FALSE FALSE  TRUE FALSE  TRUE FALSE  FALSE     FALSE
    ##   cl.last cl.all     f mrt.last mrt.iv.last vss.last vss.iv.last   cav
    ## 1   FALSE  FALSE FALSE    FALSE       FALSE    FALSE       FALSE FALSE
    ## 2   FALSE  FALSE FALSE    FALSE       FALSE    FALSE       FALSE FALSE
    ##   cav.int.last cav.int.all ctrough cstart   ptr  tlag deg.fluc swing  ceoi
    ## 1        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
    ## 2        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
    ##   aucabove.predose.all aucabove.trough.all count_conc count_conc_measured
    ## 1                FALSE               FALSE      FALSE               FALSE
    ## 2                FALSE               FALSE      FALSE               FALSE
    ##   totdose    ae clr.last clr.obs clr.pred    fe sparse_auclast sparse_auc_se
    ## 1   FALSE FALSE    FALSE   FALSE    FALSE FALSE          FALSE         FALSE
    ## 2   FALSE FALSE    FALSE   FALSE    FALSE FALSE          FALSE         FALSE
    ##   sparse_auc_df time_above aucivlast aucivall aucivint.last aucivint.all
    ## 1         FALSE      FALSE     FALSE    FALSE         FALSE        FALSE
    ## 2         FALSE      FALSE     FALSE    FALSE         FALSE        FALSE
    ##   aucivpbextlast aucivpbextall aucivpbextint.last aucivpbextint.all half.life
    ## 1          FALSE         FALSE              FALSE             FALSE     FALSE
    ## 2          FALSE         FALSE              FALSE             FALSE      TRUE
    ##   r.squared adj.r.squared lambda.z.corrxy lambda.z lambda.z.time.first
    ## 1     FALSE         FALSE           FALSE    FALSE               FALSE
    ## 2     FALSE         FALSE           FALSE    FALSE               FALSE
    ##   lambda.z.time.last lambda.z.n.points clast.pred span.ratio thalf.eff.last
    ## 1              FALSE             FALSE      FALSE      FALSE          FALSE
    ## 2              FALSE             FALSE      FALSE      FALSE          FALSE
    ##   thalf.eff.iv.last kel.last kel.iv.last aucinf.obs aucinf.pred aumcinf.obs
    ## 1             FALSE    FALSE       FALSE      FALSE       FALSE       FALSE
    ## 2             FALSE    FALSE       FALSE       TRUE       FALSE       FALSE
    ##   aumcinf.pred aucint.inf.obs aucint.inf.obs.dose aucint.inf.pred
    ## 1        FALSE          FALSE               FALSE           FALSE
    ## 2        FALSE          FALSE               FALSE           FALSE
    ##   aucint.inf.pred.dose aucivinf.obs aucivinf.pred aucivpbextinf.obs
    ## 1                FALSE        FALSE         FALSE             FALSE
    ## 2                FALSE        FALSE         FALSE             FALSE
    ##   aucivpbextinf.pred aucpext.obs aucpext.pred cl.obs cl.pred mrt.obs mrt.pred
    ## 1              FALSE       FALSE        FALSE  FALSE   FALSE   FALSE    FALSE
    ## 2              FALSE       FALSE        FALSE  FALSE   FALSE   FALSE    FALSE
    ##   mrt.iv.obs mrt.iv.pred mrt.md.obs mrt.md.pred vz.obs vz.pred vss.obs vss.pred
    ## 1      FALSE       FALSE      FALSE       FALSE  FALSE   FALSE   FALSE    FALSE
    ## 2      FALSE       FALSE      FALSE       FALSE  FALSE   FALSE   FALSE    FALSE
    ##   vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred cav.int.inf.obs
    ## 1      FALSE       FALSE      FALSE       FALSE           FALSE
    ## 2      FALSE       FALSE      FALSE       FALSE           FALSE
    ##   cav.int.inf.pred thalf.eff.obs thalf.eff.pred thalf.eff.iv.obs
    ## 1            FALSE         FALSE          FALSE            FALSE
    ## 2            FALSE         FALSE          FALSE            FALSE
    ##   thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs kel.iv.pred auclast.dn
    ## 1             FALSE   FALSE    FALSE      FALSE       FALSE      FALSE
    ## 2             FALSE   FALSE    FALSE      FALSE       FALSE      FALSE
    ##   aucall.dn aucinf.obs.dn aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn
    ## 1     FALSE         FALSE          FALSE       FALSE      FALSE          FALSE
    ## 2     FALSE         FALSE          FALSE       FALSE      FALSE          FALSE
    ##   aumcinf.pred.dn cmax.dn cmin.dn clast.obs.dn clast.pred.dn cav.dn ctrough.dn
    ## 1           FALSE   FALSE   FALSE        FALSE         FALSE  FALSE      FALSE
    ## 2           FALSE   FALSE   FALSE        FALSE         FALSE  FALSE      FALSE
    ## 
    ## $allow_partial_missing_units
    ## [1] FALSE

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
## levels is supporting; you are not restricted to this list.)
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

| start | end | auclast | aucall | aumclast | aumcall | aucint.last | aucint.last.dose | aucint.all | aucint.all.dose | c0    | cmax  | cmin  | tmax  | tlast | tfirst | clast.obs | cl.last | cl.all | f     | mrt.last | mrt.iv.last | vss.last | vss.iv.last | cav   | cav.int.last | cav.int.all | ctrough | cstart | ptr   | tlag  | deg.fluc | swing | ceoi  | aucabove.predose.all | aucabove.trough.all | count_conc | count_conc_measured | totdose | ae    | clr.last | clr.obs | clr.pred | fe    | sparse_auclast | sparse_auc_se | sparse_auc_df | time_above | aucivlast | aucivall | aucivint.last | aucivint.all | aucivpbextlast | aucivpbextall | aucivpbextint.last | aucivpbextint.all | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | thalf.eff.last | thalf.eff.iv.last | kel.last | kel.iv.last | aucinf.obs | aucinf.pred | aumcinf.obs | aumcinf.pred | aucint.inf.obs | aucint.inf.obs.dose | aucint.inf.pred | aucint.inf.pred.dose | aucivinf.obs | aucivinf.pred | aucivpbextinf.obs | aucivpbextinf.pred | aucpext.obs | aucpext.pred | cl.obs | cl.pred | mrt.obs | mrt.pred | mrt.iv.obs | mrt.iv.pred | mrt.md.obs | mrt.md.pred | vz.obs | vz.pred | vss.obs | vss.pred | vss.iv.obs | vss.iv.pred | vss.md.obs | vss.md.pred | cav.int.inf.obs | cav.int.inf.pred | thalf.eff.obs | thalf.eff.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | kel.obs | kel.pred | kel.iv.obs | kel.iv.pred | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.dn | ctrough.dn |
|------:|----:|:--------|:-------|:---------|:--------|:------------|:-----------------|:-----------|:----------------|:------|:------|:------|:------|:------|:-------|:----------|:--------|:-------|:------|:---------|:------------|:---------|:------------|:------|:-------------|:------------|:--------|:-------|:------|:------|:---------|:------|:------|:---------------------|:--------------------|:-----------|:--------------------|:--------|:------|:---------|:--------|:---------|:------|:---------------|:--------------|:--------------|:-----------|:----------|:---------|:--------------|:-------------|:---------------|:--------------|:-------------------|:------------------|:----------|:----------|:--------------|:----------------|:---------|:--------------------|:-------------------|:------------------|:-----------|:-----------|:---------------|:------------------|:---------|:------------|:-----------|:------------|:------------|:-------------|:---------------|:--------------------|:----------------|:---------------------|:-------------|:--------------|:------------------|:-------------------|:------------|:-------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:----------------|:-----------------|:--------------|:---------------|:-----------------|:------------------|:--------|:---------|:-----------|:------------|:-----------|:----------|:--------------|:---------------|:------------|:-----------|:---------------|:----------------|:--------|:--------|:-------------|:--------------|:-------|:-----------|
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      |

For multiple-dose studies, PKNCA selects one group at a time and
compares the concentration and dosing times. When there is a
concentration measurement between doses, an interval row is added. The
dosing interval ($\tau$) is determined by looking for pattern repeats
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

After finding $\tau$, PKNCA will also look after the last dose (or the
beginning of the last dosing interval), and two additional intervals may
be added:

- one interval for the dosing interval after the beginning of the last
  dosing interval (if there are concentrations measured in the interval)
- one interval for the half-life after the last dosing interval (if
  there are concentration more than $\tau$ after the beginning of the
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
summaries (see layer) is less helpful because everyone could have
different start and end times. So, you may keep the interval columns
using the option `"keep_interval_cols"` as follows (where “dosetype”
must be a column name in the intervals):

``` r
o_data <- PKNCAdata(o_conc, o_dose, options = list(keep_interval_cols = "dosetype"))
```

## Summarizing results

When NCA has been calculated, you can summarize the results with the
[`summary()`](https://rdrr.io/r/base/summary.html) function.

``` r
summary(o_nca)
```

By default, it will count the number of unique subjects (`N`) in the
summary, and when the number of subjects differs from the number of
measurements included in a summary (`n`), it will summarize `n` for the
given parameters. Note that counting of “n” includes all non-missing
values that were not excluded from summarization; this will included all
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

To use [`update()`](https://rdrr.io/r/stats/update.html), give it your
existing results and the new `PKNCAdata` object you want to use.

Starting from the theophylline example in the [Quick
Start](http://humanpred.github.io/pknca/articles/Quick%20Start) section
above:

``` r
d_conc <- as.data.frame(datasets::Theoph)
d_dose <- d_conc[d_conc$Time == 0,]
o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
o_dose <- PKNCAdose(d_dose, Dose~Time|Subject)
o_data <- PKNCAdata(o_conc, o_dose)
o_nca <- pk.nca(o_data)
summary(o_nca)
```

    ##  start end  N     auclast        cmax               tmax   half.life aucinf.obs
    ##      0  24 12 74.6 [24.3]           .                  .           .          .
    ##      0 Inf 12           . 8.65 [17.0] 1.14 [0.630, 3.55] 8.18 [2.12] 115 [28.4]
    ## 
    ## Caption: auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects

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
```

    ## Warning: Subject=2: No concentration data

    ## Warning: Subject=3: No concentration data

    ## Warning: Subject=4: No concentration data

    ## Warning: Subject=5: No concentration data

    ## Warning: Subject=6: No concentration data

    ## Warning: Subject=8: No concentration data

    ## Warning: Subject=9: No concentration data

    ## Warning: Subject=11: No concentration data

    ## Warning: Subject=12: No concentration data

``` r
summary(o_nca_update)
```

    ##  start end  N     auclast        cmax               tmax   half.life aucinf.obs
    ##      0  24 12 74.6 [24.2]           .                  .           .          .
    ##      0 Inf 12           . 8.65 [17.0] 1.14 [0.630, 3.55] 8.18 [2.12] 115 [28.4]
    ## 
    ## Caption: auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects

Now, assume that instead of calculating `auclast` from time 0 to 24, we
want to calculate `aucint.inf.obs`. We can change the intervals to
create a new `PKNCAdata` object:

``` r
d_intervals <- o_data$intervals
d_intervals$aucint.inf.obs <- d_intervals$auclast
d_intervals$auclast <- FALSE
o_data_update <- PKNCAdata(o_conc, o_dose, intervals = d_intervals)
```

Then, we can update the `PKNCAresults`:

``` r
o_nca_update <- update(o_nca, o_data_update)
```

    ## Warning in update.PKNCAresults(o_nca, o_data_update): Full recalculation:
    ## changes detected in data other than source concentration or dose data

``` r
summary(o_nca_update)
```

    ##  start end  N        cmax               tmax   half.life aucinf.obs
    ##      0  24 12           .                  .           .          .
    ##      0 Inf 12 8.65 [17.0] 1.14 [0.630, 3.55] 8.18 [2.12] 115 [28.4]
    ##  aucint.inf.obs
    ##     98.4 [22.5]
    ##               .
    ## 
    ## Caption: cmax, aucinf.obs, aucint.inf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects
