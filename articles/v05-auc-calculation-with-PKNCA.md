# AUC Calculation with PKNCA

Area Under the Curve (AUC) is a commonly-used metric for assessing
exposure to a drug. Many variants of AUC exist, and the information
below will assist in determining both the appropriate AUC and how to
calculate it.

## Preparation

For the below examples, the following data will be used.

``` r

suppressPackageStartupMessages({
  library(PKNCA)
  library(dplyr)
  library(cowplot)
  library(knitr)
  library(ggplot2)
})
scale_colour_discrete <- scale_colour_hue
scale_fill_discrete <- scale_fill_hue

my_conc <- data.frame(conc=c(0, 2.5, 3, 2, 1.5, 1.2, 1.1, 0, 0),
                      time=c(0:5, 8, 12, 24),
                      subject=1)
my_conc$BLQ <- my_conc$conc == 0
my_conc$measured <- TRUE
```

``` r

ggplot(my_conc,
       aes(x=time,
           y=conc,
           shape=BLQ,
           group=subject)) +
  geom_line() +
  geom_point(size=4) +
  scale_x_continuous(breaks=my_conc$time) +
  theme(legend.position=c(0.8, 0.8))
```

![](v05-auc-calculation-with-PKNCA_files/figure-html/setup-visualization-1.png)

For the purpose of illustration, NCA parameters will also be calculated
for each of the AUC types below. Note that in the results, more
parameters are returned than were requested. The additional parameters
are the set of parameters required to calculate the requested
parameters.

``` r

conc_obj <- PKNCAconc(my_conc, conc~time|subject)
data_obj <- PKNCAdata(data.conc=conc_obj,
                      intervals=data.frame(start=0,
                                           end=24,
                                           aucall=TRUE,
                                           auclast=TRUE,
                                           aucinf.pred=TRUE,
                                           aucinf.obs=TRUE))
results_obj <- pk.nca(data_obj)
kable(as.data.frame(results_obj))
```

| subject | start | end | PPTESTCD            |    PPORRES | PPANMETH             | exclude |
|--------:|------:|----:|:--------------------|-----------:|:---------------------|:--------|
|       1 |     0 |  24 | auclast             | 12.9965842 | AUC: lin up/log down | NA      |
|       1 |     0 |  24 | aucall              | 15.1965842 | AUC: lin up/log down | NA      |
|       1 |     0 |  24 | tmax                |  2.0000000 |                      | NA      |
|       1 |     0 |  24 | tlast               |  8.0000000 |                      | NA      |
|       1 |     0 |  24 | clast.obs           |  1.1000000 |                      | NA      |
|       1 |     0 |  24 | lambda.z            |  0.1075592 |                      | NA      |
|       1 |     0 |  24 | r.squared           |  0.7580245 |                      | NA      |
|       1 |     0 |  24 | adj.r.squared       |  0.6370368 |                      | NA      |
|       1 |     0 |  24 | lambda.z.corrxy     | -0.8706460 |                      | NA      |
|       1 |     0 |  24 | lambda.z.time.first |  3.0000000 |                      | NA      |
|       1 |     0 |  24 | lambda.z.time.last  |  8.0000000 |                      | NA      |
|       1 |     0 |  24 | lambda.z.n.points   |  4.0000000 |                      | NA      |
|       1 |     0 |  24 | clast.pred          |  1.0216136 |                      | NA      |
|       1 |     0 |  24 | half.life           |  6.4443313 |                      | NA      |
|       1 |     0 |  24 | span.ratio          |  0.7758757 |                      | NA      |
|       1 |     0 |  24 | aucinf.obs          | 23.2235095 | AUC: lin up/log down | NA      |
|       1 |     0 |  24 | aucinf.pred         | 22.4947355 | AUC: lin up/log down | NA      |

## AUC to the Last Value Above the Limit of Quantification (AUC_(last))

AUC_(0-last) calculates the AUC from time 0 to the last value above the
limit of quantification, `tlast` (within PKNCA, this is the last value
above 0). In the figure below, AUC_(0-last) integrates the shaded
region. Integration after `tlast` is 0.

``` r

tlast <- pk.calc.tlast(conc=my_conc$conc,
                       time=my_conc$time)
tlast
```

    ## [1] 8

``` r

my_conc$include_auclast <- my_conc$time <= tlast
```

``` r

ggplot(my_conc,
       aes(x=time,
           y=conc,
           shape=BLQ,
           group=subject)) +
  geom_ribbon(data=my_conc[my_conc$include_auclast,],
              aes(ymin=0, ymax=conc),
              fill="lightblue") +
  geom_line() +
  geom_point(size=4) +
  scale_x_continuous(breaks=my_conc$time) +
  theme(legend.position=c(0.8, 0.8))
```

![](v05-auc-calculation-with-PKNCA_files/figure-html/auclast-visualization-1.png)

## AUC_(all)

AUC_(all) starts with AUC_(0-last) and then integrates from `tlast` to
the first point after `tlast` with a linear interpolation to zero. From
the second point after `tlast` to $`\infty`$ is considered zero.

``` r

first_after_tlast <- my_conc$time[my_conc$time > tlast][1]
first_after_tlast
```

    ## [1] 12

``` r

my_conc$include_aucall <- my_conc$time <= first_after_tlast
```

``` r

ggplot(my_conc,
       aes(x=time,
           y=conc,
           shape=BLQ,
           group=subject)) +
  geom_ribbon(data=my_conc[my_conc$include_aucall,],
              aes(ymin=0, ymax=conc),
              fill="lightblue") +
  geom_line() +
  geom_point(size=4) +
  scale_x_continuous(breaks=my_conc$time) +
  theme(legend.position=c(0.8, 0.8))
```

![](v05-auc-calculation-with-PKNCA_files/figure-html/aucall-visualization-1.png)

## AUC to Infinity (AUC_($`\infty`$))

AUC_(0-$`\infty`$) is commonly used for single-dose data. It calculates
the AUC_(0-last) and then extrapolates to $`\infty`$ using the estimated
half-life. Two starting points are used to estimate from `tlast` to
$`\infty`$, the observed or half-life predicted concentration at `tlast`
(`clast.obs` and `clast.pred`).

The two figures below illustrate the integration with
AUC_(0-$`\infty`$,obs) and AUC_(0-$`\infty`$,pred). The difference
between the two figures is most evident at time=8 where there is a
discontinuity in integration at `tlast` due to using `clast.pred` after
that point and `clast.obs` before that point. (To illustrate the
integration differences, BLQ indicator shapes have been removed. BLQ is
handled identically to previous figures.)

``` r

# Add one row to illustrate extrapolation beyond observed data
my_conc <-
  rbind(my_conc,
        data.frame(conc=NA,
                   time=36,
                   subject=1,
                   BLQ=NA,
                   measured=FALSE,
                   include_auclast=FALSE,
                   include_aucall=FALSE))
# Extrapolate concentrations for aucinf.obs
my_conc$conc_aucinf.obs <- my_conc$conc
my_conc$conc_aucinf.obs[my_conc$BLQ | is.na(my_conc$BLQ)] <-
  interp.extrap.conc(conc=my_conc$conc,
                     time=my_conc$time,
                     time.out=my_conc$time[my_conc$BLQ | is.na(my_conc$BLQ)],
                     lambda.z=as.data.frame(results_obj)$PPORRES[as.data.frame(results_obj)$PPTESTCD %in% "lambda.z"])

# Extrapolate concentrations for aucinf.pred
my_conc$conc_aucinf.pred <- my_conc$conc
my_conc$conc_aucinf.pred[my_conc$BLQ | is.na(my_conc$BLQ)] <-
  interp.extrap.conc(conc=my_conc$conc,
                     time=my_conc$time,
                     time.out=my_conc$time[my_conc$BLQ | is.na(my_conc$BLQ)],
                     lambda.z=as.data.frame(results_obj)$PPORRES[as.data.frame(results_obj)$PPTESTCD %in% "lambda.z"],
                     clast=as.data.frame(results_obj)$PPORRES[as.data.frame(results_obj)$PPTESTCD %in% "clast.pred"])
my_conc$conc_aucinf.pred[my_conc$time == tlast] <-
  as.data.frame(results_obj)$PPORRES[as.data.frame(results_obj)$PPTESTCD %in% "clast.pred"]
```

``` r

ggplot(my_conc[!is.na(my_conc$conc),],
       aes(x=time,
           y=conc,
           #shape=BLQ,
           group=subject)) +
  geom_ribbon(data=my_conc,
              aes(ymin=0, ymax=conc_aucinf.obs),
              fill="lightblue") +
  geom_line() +
  #geom_point(size=2) +
  scale_x_continuous(breaks=my_conc$time) +
  theme(legend.position=c(0.8, 0.8)) +
  labs(title="Extrapolation using AUCinf,obs")
```

![](v05-auc-calculation-with-PKNCA_files/figure-html/aucinf-visualization-1.png)

``` r

ggplot(my_conc[!is.na(my_conc$conc),],
       aes(x=time,
           y=conc,
           #shape=BLQ,
           group=subject)) +
  geom_ribbon(
    data=arrange(
      bind_rows(mutate(my_conc,
                       before=FALSE),
                mutate(filter(my_conc, time == tlast),
                       conc_aucinf.pred=conc,
                       before=TRUE)),
      time, desc(before)),
    aes(ymin=0,
        ymax=conc_aucinf.pred),
    fill="lightblue") +
  geom_line() +
  #geom_point(size=2) +
  scale_x_continuous(breaks=my_conc$time) +
  theme(legend.position=c(0.8, 0.8)) +
  labs(title="Extrapolation using AUCinf,pred")
```

![](v05-auc-calculation-with-PKNCA_files/figure-html/aucinf-visualization-2.png)

## Partial AUCs

Partial AUCs integrate part of the area within a time range of interest.
Partial AUCs are often of interest to assess bioequivalence with more
detail than AUC_(0-$`\infty`$) or AUC_(0-last) may indicate. Within
PKNCA, partial AUCs are calculated with the interval AUC (`aucint`)
family of parameters: `aucint.last`, `aucint.all`, `aucint.inf.obs`, and
`aucint.inf.pred` integrate over the full interval from `start` to `end`
while handling the region after `tlast` the same way as `auclast`,
`aucall`, `aucinf.obs`, and `aucinf.pred`, respectively. (The `.dose`
variants of each, such as `aucint.last.dose`, additionally interpolate
concentrations at dose times within the interval.)

Request an `aucint` parameter like any other interval parameter with the
`start` and `end` of the interval defining the range of integration.
When the interval boundaries do not match observed time points,
concentrations at the boundaries are automatically interpolated (or
extrapolated, according to the method of the specific parameter), so no
manual data preparation is required. In the example below, the
concentration at the end time of 1.5 is not in the observed data, and it
is interpolated automatically during the calculation.

``` r

data_aucint_obj <-
  PKNCAdata(conc_obj,
            intervals=data.frame(start=0, end=c(2, 1.5), aucint.last=TRUE))
results_aucint_obj <- pk.nca(data_aucint_obj)
kable(as.data.frame(results_aucint_obj))
```

| subject | start | end | PPTESTCD    | PPORRES | PPANMETH             | exclude |
|--------:|------:|----:|:------------|--------:|:---------------------|:--------|
|       1 |     0 | 2.0 | aucint.last |  4.0000 | AUC: lin up/log down | NA      |
|       1 |     0 | 1.5 | aucint.last |  2.5625 | AUC: lin up/log down | NA      |

The area under the first moment curve (AUMC) has matching interval
parameters (`aumcint.last`, `aumcint.all`, and the other `aumcint*`
parameters), as do the intravenous C₀ back-extrapolated AUMC parameters
(`aumciv*`), in the development version of PKNCA.
