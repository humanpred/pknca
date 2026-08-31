# Secondary Parameters (Renal Clearance, Bioavailability, and Ratios)

``` r

library(PKNCA)
#> 
#> Attaching package: 'PKNCA'
#> The following object is masked from 'package:stats':
#> 
#>     filter
library(knitr)
```

## What a secondary parameter is

Almost every NCA parameter is calculated from the concentrations and
doses within one interval of one profile. A few cannot be:

- Renal clearance divides the amount excreted into a urine collection by
  the plasma AUC over the same times. The amount and the AUC are
  measured on different profiles.
- Bioavailability compares the dose-normalized exposure of one
  administration with a reference administration.
- A ratio (an accumulation ratio, a metabolite ratio) compares a
  parameter with the same parameter somewhere else.

PKNCA calls these **secondary parameters** and calculates them by
linking two intervals together.
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md)
says which parameters are secondary:

``` r

d_params <- pknca_parameter_table()
kable(
  d_params[d_params$secondary, c("parameter", "concept", "sample_type")],
  row.names = FALSE
)
```

| parameter         | concept         | sample_type |
|:------------------|:----------------|:------------|
| clr.last          | renal_clearance | interval    |
| clr.obs           | renal_clearance | interval    |
| clr.pred          | renal_clearance | interval    |
| ratio.cmax        | parameter_ratio | spot        |
| ratio.auclast     | parameter_ratio | spot        |
| ratio.aucint.last | parameter_ratio | spot        |
| ratio.aucint.all  | parameter_ratio | spot        |
| f.last            | bioavailability | spot        |
| f.int.last        | bioavailability | spot        |
| f.int.all         | bioavailability | spot        |
| f.obs             | bioavailability | spot        |
| f.pred            | bioavailability | spot        |
| f.int.obs         | bioavailability | spot        |
| f.int.pred        | bioavailability | spot        |
| ratio.aucinf.obs  | parameter_ratio | spot        |
| ratio.aucinf.pred | parameter_ratio | spot        |
| clr.last.dn       | renal_clearance | interval    |
| clr.obs.dn        | renal_clearance | interval    |
| clr.pred.dn       | renal_clearance | interval    |

Two words are used throughout:

- The **requesting interval** is the intervals row that asks for the
  parameter. The result is reported there: on that row’s group and that
  row’s times.
- The **reference interval** is the row that supplies the value from the
  other profile.

Secondary parameters are never selected automatically by
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md)
or the default interval specification, because one interval cannot say
what the other profile is. They are requested by name, like any other
parameter.

## Linking two intervals by hand

Two columns of the interval specification make the link:

| Column | Meaning |
|----|----|
| `interval_id` | A name for this row, so that another row can point at it. `NA` on rows nothing points at. |
| `<parameter>_ref` | The `interval_id` of the interval supplying the cross-profile value for `<parameter>`. |

The identifiers may be character names, factors, or numbers such as row
indices. Whatever they are, `interval_id` and the pointer columns must
be comparable with each other, so that a pointer can be matched to an
identifier.

### Renal clearance, start to finish

These data have one subject with a plasma profile and a urine
collection. For the urine rows, `conc` is the concentration measured in
the collection and `vol` is the collection volume:

``` r

d_conc <- data.frame(
  subject = 1,
  PCSPEC = rep(c("plasma", "urine"), times = c(3, 2)),
  time = c(0, 12, 24, 0, 12),
  conc = c(10, 6, 2, 2, 1),
  vol  = c(NA, NA, NA, 100, 150)
)
o_conc <- PKNCAconc(d_conc, conc~time|PCSPEC+subject, volume = "vol")
```

The plasma row is given an `interval_id`, and the urine row requests
`clr.last` pointing at it:

``` r

intervals_linked <-
  data.frame(
    PCSPEC = c("plasma", "urine"),
    start = 0, end = 24,
    interval_id = c("plasma024", NA),
    auclast = c(TRUE, FALSE),
    ae = c(FALSE, TRUE),
    clr.last = c(FALSE, TRUE),
    clr.last_ref = c(NA, "plasma024")
  )
kable(intervals_linked)
```

| PCSPEC | start | end | interval_id | auclast | ae    | clr.last | clr.last_ref |
|:-------|------:|----:|:------------|:--------|:------|:---------|:-------------|
| plasma |     0 |  24 | plasma024   | TRUE    | FALSE | FALSE    | NA           |
| urine  |     0 |  24 | NA          | FALSE   | TRUE  | TRUE     | plasma024    |

``` r

o_data <-
  PKNCAdata(
    o_conc, intervals = intervals_linked,
    options = list(auc.method = "linear")
  )
results_linked <- pk.nca(o_data)
kable(as.data.frame(results_linked))
```

| PCSPEC | subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude | PCSPEC_ref | subject_ref |
|:---|---:|---:|---:|:---|---:|:---|:---|:---|---:|
| plasma | 1 | 0 | 24 | auclast | 144.000000 | AUC: linear | NA | NA | NA |
| urine | 1 | 0 | 24 | ae | 350.000000 |  | NA | NA | NA |
| urine | 1 | 0 | 24 | clr.last | 2.430556 | Reference interval: PCSPEC=plasma, 0-24 | NA | plasma | 1 |

Every number can be checked by hand. With linear trapezoids the plasma
AUC is $`(10+6)/2 \times 12 + (6+2)/2 \times 12 = 144`$, the amount
excreted is $`2 \times 100 + 1 \times 150 = 350`$, and the renal
clearance is $`350/144 = 2.431`$.

Note where the result is reported: on the urine row, which requested it,
and not on the plasma row that supplied the AUC.

### The reference interval gains what the link needs

`auclast` was requested explicitly above to make the arithmetic visible,
but it did not have to be. A reference interval gains whatever the link
reads from it, the same way any parameter’s dependencies are calculated,
and without announcement:

``` r

intervals_implicit <- intervals_linked
intervals_implicit$auclast <- c(FALSE, FALSE)
intervals_implicit$cmax <- c(TRUE, FALSE)
o_data_implicit <-
  PKNCAdata(
    o_conc, intervals = intervals_implicit,
    options = list(auc.method = "linear")
  )
results_implicit <- pk.nca(o_data_implicit)
kable(as.data.frame(results_implicit))
```

| PCSPEC | subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude | PCSPEC_ref | subject_ref |
|:---|---:|---:|---:|:---|---:|:---|:---|:---|---:|
| plasma | 1 | 0 | 24 | auclast | 144.000000 | AUC: linear | NA | NA | NA |
| plasma | 1 | 0 | 24 | cmax | 10.000000 |  | NA | NA | NA |
| urine | 1 | 0 | 24 | ae | 350.000000 |  | NA | NA | NA |
| urine | 1 | 0 | 24 | clr.last | 2.430556 | Reference interval: PCSPEC=plasma, 0-24 | NA | plasma | 1 |

The `auclast` row is in the results because it was calculated, but it
was not one of the parameters asked for. `filter_requested = TRUE`
reports only the requests:

``` r

d_requested <- as.data.frame(results_implicit, filter_requested = TRUE)
kable(d_requested[, c("PCSPEC", "subject", "start", "end", "PPTESTCD", "PPORRES")])
```

| PCSPEC | subject | start | end | PPTESTCD |    PPORRES |
|:-------|--------:|------:|----:|:---------|-----------:|
| plasma |       1 |     0 |  24 | cmax     |  10.000000 |
| urine  |       1 |     0 |  24 | ae       | 350.000000 |
| urine  |       1 |     0 |  24 | clr.last |   2.430556 |

## Letting PKNCA find the reference interval

Naming the reference by hand is not usually necessary. When a secondary
parameter is requested with no pointer and no way to calculate it within
its own interval, PKNCA derives the reference from the data. Here the
specification asks only about the urine collection:

``` r

intervals_urine <-
  data.frame(PCSPEC = "urine", start = 0, end = 24, ae = TRUE, clr.last = TRUE)
o_data_auto <-
  PKNCAdata(
    o_conc, intervals = intervals_urine,
    options = list(auc.method = "linear")
  )
results_auto <- pk.nca(o_data_auto)
#> Secondary parameter 'clr.last': created reference interval 'autoref1'
#> (PCSPEC=plasma, 0-24).
kable(as.data.frame(results_auto))
```

| PCSPEC | subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude | PCSPEC_ref | subject_ref |
|:---|---:|---:|---:|:---|---:|:---|:---|:---|---:|
| plasma | 1 | 0 | 24 | auclast | 144.000000 | AUC: linear | NA | NA | NA |
| urine | 1 | 0 | 24 | ae | 350.000000 |  | NA | NA | NA |
| urine | 1 | 0 | 24 | clr.last | 2.430556 | Reference interval: PCSPEC=plasma, 0-24 | NA | plasma | 1 |

The message reports the interval that was derived, and the answer is the
one the hand-written linkage gives. The derivation is mechanical rather
than a list of special cases: the parameter is measured over an interval
collection while everything it references is a spot sample (this is what
renal clearance is), the concentration data declare a collection
`volume`, and so the reference is looked for among the profiles that
have no collection volume. Of those, each interval takes the one
differing from its own group in the fewest columns.

Derived intervals are used for the calculation only. The intervals that
come back with the results are the ones that went in:

``` r

identical(results_auto$data$intervals, check.interval.specification(intervals_urine))
#> [1] TRUE
```

### When more than one profile could be the reference

Adding a second spot-sample profile leaves no single nearest reference.
Rather than guessing or stopping the analysis, PKNCA reports `NA` with
the reason:

``` r

d_conc_serum <-
  rbind(
    d_conc,
    data.frame(
      subject = 1, PCSPEC = "serum", time = c(0, 12, 24), conc = c(9, 5, 2),
      vol = NA_real_
    )
  )
o_conc_serum <-
  PKNCAconc(d_conc_serum, conc~time|PCSPEC+subject, volume = "vol")
intervals_three <-
  data.frame(
    PCSPEC = c("urine", "plasma", "serum"),
    start = 0, end = 24,
    ae = c(TRUE, FALSE, FALSE),
    auclast = c(FALSE, TRUE, TRUE),
    clr.last = c(TRUE, FALSE, FALSE)
  )
o_data_ambiguous <-
  PKNCAdata(
    o_conc_serum, intervals = intervals_three,
    options = list(auc.method = "linear")
  )
d_ambiguous <- as.data.frame(pk.nca(o_data_ambiguous))
#> Warning: Secondary parameter 'clr.last': no reference value could be determined
#> for 1 interval(s), so the results are NA (see the exclude column).  More than
#> one reference profile is equally close ((PCSPEC=plasma), (PCSPEC=serum)).  Set
#> 'clr.last_ref' in the interval specification, give `group_ref` to PKNCAdata(),
#> or use interval_add_secondary().
kable(d_ambiguous[d_ambiguous$PPTESTCD %in% "clr.last", ])
```

| PCSPEC | subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude | PCSPEC_ref | subject_ref |
|:---|---:|---:|---:|:---|---:|:---|:---|:---|---:|
| urine | 1 | 0 | 24 | clr.last | NA | NA | More than one reference profile is equally close ((PCSPEC=plasma), (PCSPEC=serum)) | NA | NA |

Everything else in the analysis is still calculated. One warning is
raised per parameter, however many intervals it affected, and the reason
for each result is in its `exclude` column.

### Steering the choice with `group_ref`

`PKNCAdata(group_ref = )` says which profiles may be references. It
settles the ambiguity above:

``` r

o_data_steered <-
  PKNCAdata(
    o_conc_serum, intervals = intervals_three,
    options = list(auc.method = "linear"),
    group_ref = data.frame(PCSPEC = "plasma")
  )
d_steered <- as.data.frame(pk.nca(o_data_steered))
#> Secondary parameter 'clr.last': using (PCSPEC=plasma, 0-24) as the reference
#> interval 'autoref1'.
kable(d_steered[d_steered$PPTESTCD %in% "clr.last", ])
```

| PCSPEC | subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude | PCSPEC_ref | subject_ref |
|:---|---:|---:|---:|:---|---:|:---|:---|:---|---:|
| urine | 1 | 0 | 24 | clr.last | 2.430556 | Reference interval: PCSPEC=plasma, 0-24 | NA | plasma | 1 |

`group_ref` also directs comparisons that the data cannot tell apart at
all. Nothing in a data set says which analyte is the parent and which
the metabolite, so a metabolite ratio has to be told:

``` r

d_conc_two <-
  rbind(
    data.frame(
      Analyte = rep(c("parent", "metabolite"), each = 5),
      PCSPEC = "plasma", subject = 1,
      time = rep(c(0, 1, 2, 4, 8), 2),
      conc = c(0, 10, 8, 5, 2, 0, 4, 3.5, 2, 0.8),
      vol = NA_real_, dur = 0
    ),
    data.frame(
      Analyte = rep(c("parent", "metabolite"), each = 2),
      PCSPEC = "urine", subject = 1,
      time = rep(c(0, 12), 2),
      conc = c(2, 1, 1, 0.5),
      vol = rep(c(100, 150), 2), dur = 12
    )
  )
o_conc_two <-
  PKNCAconc(
    d_conc_two, conc~time|Analyte+PCSPEC+subject,
    volume = "vol", duration = "dur"
  )
intervals_two <-
  data.frame(
    Analyte = c("parent", "metabolite", "parent", "metabolite"),
    PCSPEC = c("urine", "urine", "plasma", "plasma"),
    start = 0,
    end = c(24, 24, Inf, Inf),
    ae = c(TRUE, TRUE, FALSE, FALSE),
    clr.last = c(TRUE, TRUE, FALSE, FALSE),
    aucinf.obs = c(FALSE, FALSE, TRUE, FALSE),
    ratio.aucinf.obs = c(FALSE, FALSE, FALSE, TRUE)
  )
```

Renal clearance and the metabolite ratio need to be steered by different
columns: the renal clearance of each analyte belongs with the plasma
profile of the same analyte, while the ratio compares one analyte with
the other. A `parameter` column says which rows apply to which
parameter, and the columns a parameter’s row leaves `NA` do not
constrain it:

``` r

group_ref_by_param <-
  data.frame(
    parameter = c("clr.last", "ratio.aucinf.obs"),
    PCSPEC = c("plasma", NA),
    Analyte = c(NA, "parent")
  )
kable(group_ref_by_param)
```

| parameter        | PCSPEC | Analyte |
|:-----------------|:-------|:--------|
| clr.last         | plasma | NA      |
| ratio.aucinf.obs | NA     | parent  |

``` r

o_data_two <-
  PKNCAdata(
    o_conc_two, intervals = intervals_two,
    options = list(auc.method = "linear"),
    group_ref = group_ref_by_param
  )
d_two <- as.data.frame(pk.nca(o_data_two))
#> Secondary parameter 'clr.last': created reference interval 'autoref1' (PCSPEC=plasma, 0-24).
#> Secondary parameter 'clr.last': created reference interval 'autoref2' (PCSPEC=plasma, 0-24).
#> Secondary parameter 'ratio.aucinf.obs': using (Analyte=parent, 0-Inf) as the reference interval 'autoref3'.
kable(d_two[d_two$PPTESTCD %in% c("clr.last", "ratio.aucinf.obs"), ])
```

| Analyte | PCSPEC | subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude | Analyte_ref | PCSPEC_ref | subject_ref |
|:---|:---|---:|---:|---:|:---|---:|:---|:---|:---|:---|---:|
| parent | urine | 1 | 0 | 24 | clr.last | 8.5365854 | Reference interval: PCSPEC=plasma, 0-24 | NA | parent | plasma | 1 |
| metabolite | urine | 1 | 0 | 24 | clr.last | 10.3857567 | Reference interval: PCSPEC=plasma, 0-24 | NA | metabolite | plasma | 1 |
| metabolite | plasma | 1 | 0 | Inf | ratio.aucinf.obs | 0.4053918 | Reference interval: Analyte=parent, 0-Inf | NA | parent | plasma | 1 |

A named list of data.frames, one per parameter, says the same thing:

``` r

PKNCAdata(
  o_conc_two, intervals = intervals_two,
  options = list(auc.method = "linear"),
  group_ref =
    list(
      clr.last = data.frame(PCSPEC = "plasma"),
      ratio.aucinf.obs = data.frame(Analyte = "parent")
    )
)
```

A plain data.frame with no `parameter` column applies to every secondary
parameter.

## Writing the linkage into the intervals

[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md)
writes the same linkage the engine derives, but visibly, into the
intervals it returns. Use it to see the linkage, to edit it, or to link
something the derivation cannot reach.

What it returns has been through
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
which fills in every registered parameter, so it is a few hundred
columns wide. These examples show only the columns that say something:

``` r

kable_intervals <- function(intervals) {
  says_something <-
    vapply(
      X = intervals,
      FUN = function(x) !is.logical(x) || any(x, na.rm = TRUE),
      FUN.VALUE = TRUE
    )
  kable(intervals[, says_something, drop = FALSE])
}
```

``` r

intervals_plain <-
  data.frame(
    PCSPEC = c("plasma", "urine"),
    start = 0, end = 24,
    auclast = c(TRUE, FALSE),
    ae = c(FALSE, TRUE)
  )
kable_intervals(
  interval_add_secondary(
    intervals_plain,
    param = "clr.last",
    reference = data.frame(PCSPEC = "plasma")
  )
)
```

| start | end | auclast | ae    | clr.last | PCSPEC | interval_id | clr.last_ref |
|------:|----:|:--------|:------|:---------|:-------|:------------|:-------------|
|     0 |  24 | TRUE    | FALSE | FALSE    | plasma | ref1        | NA           |
|     0 |  24 | FALSE   | TRUE  | TRUE     | urine  | NA          | ref1         |

The plasma row was given an identifier, the urine row was given the
request and the pointer, and nothing else changed.

`reference` is a data.frame describing the reference interval: each of
its columns must match (and), and any of its rows may match (or). When
nothing matches, the reference interval is created and the creation is
reported:

``` r

intervals_urine_only <-
  data.frame(PCSPEC = "urine", start = 0, end = 24, ae = TRUE)
kable_intervals(
  interval_add_secondary(
    intervals_urine_only,
    param = "clr.last",
    reference = data.frame(PCSPEC = "plasma")
  )
)
#> Created reference interval(s) for 'clr.last': PCSPEC=plasma, start=0, end=24
```

| start | end | auclast | ae    | clr.last | PCSPEC | interval_id | clr.last_ref |
|------:|----:|:--------|:------|:---------|:-------|:------------|:-------------|
|     0 |  24 | FALSE   | TRUE  | TRUE     | urine  | NA          | ref1         |
|     0 |  24 | TRUE    | FALSE | FALSE    | plasma | ref1        | NA           |

The created plasma row requests `auclast`, which is what the link reads
from it.

Because `reference` can name `start` and `end`, the same call links
intervals in time rather than across groups. An accumulation ratio
compares a dosing interval with the first one:

``` r

d_conc_acc <-
  data.frame(
    subject = 1,
    time = c(0, 6, 12, 24, 30, 36, 48),
    conc = c(0, 8, 5, 2, 12, 8, 3)
  )
d_dose_acc <- data.frame(subject = 1, time = c(0, 24), dose = 100)
intervals_acc <-
  interval_add_secondary(
    data.frame(start = c(0, 24), end = c(24, 48), aucint.last = TRUE),
    param = "ratio.aucint.last",
    reference = data.frame(start = 0, end = 24)
  )
kable_intervals(intervals_acc)
```

| start | end | aucint.last | ratio.aucint.last | interval_id | ratio.aucint.last_ref |
|------:|----:|:------------|:------------------|:------------|:----------------------|
|     0 |  24 | TRUE        | FALSE             | ref1        | NA                    |
|    24 |  48 | TRUE        | TRUE              | NA          | ref1                  |

``` r

o_data_acc <-
  PKNCAdata(
    PKNCAconc(d_conc_acc, conc~time|subject),
    PKNCAdose(d_dose_acc, dose~time|subject),
    intervals = intervals_acc,
    options = list(auc.method = "linear")
  )
kable(as.data.frame(pk.nca(o_data_acc)))
```

| subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude | subject_ref |
|---:|---:|---:|:---|---:|:---|:---|---:|
| 1 | 0 | 24 | aucint.last | 105.0 | AUC: linear | NA | NA |
| 1 | 24 | 48 | aucint.last | 168.0 | AUC: linear | NA | NA |
| 1 | 24 | 48 | ratio.aucint.last | 1.6 | Reference interval: 0-24 | NA | 1 |

An interval that already names a different reference is left alone with
a warning, so the helper never silently re-points an analysis.

## Bioavailability

Bioavailability compares two administrations, so its reference is the
other treatment rather than another specimen. Both the dose and the AUC
come from the reference interval:

``` r

d_conc_f <-
  data.frame(
    treatment = rep(c("ref", "test"), each = 5),
    subject = 1,
    time = rep(c(0, 1, 2, 4, 8), 2),
    conc = c(0, 10, 8, 5, 2, 0, 4, 3.5, 2, 0.8)
  )
d_dose_f <-
  data.frame(treatment = c("ref", "test"), subject = 1, time = 0, dose = c(100, 50))
intervals_f <-
  data.frame(
    treatment = c("ref", "test"),
    start = 0, end = Inf,
    interval_id = c("refprofile", NA),
    aucinf.obs = TRUE,
    totdose = TRUE,
    f.obs = c(FALSE, TRUE),
    f.obs_ref = c(NA, "refprofile")
  )
o_data_f <-
  PKNCAdata(
    PKNCAconc(d_conc_f, conc~time|treatment+subject),
    PKNCAdose(d_dose_f, dose~time|treatment+subject),
    intervals = intervals_f
  )
d_f <- as.data.frame(pk.nca(o_data_f))
kable(d_f[d_f$PPTESTCD %in% c("totdose", "aucinf.obs", "f.obs"), ])
```

| treatment | subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude | treatment_ref | subject_ref |
|:---|---:|---:|---:|:---|---:|:---|:---|:---|---:|
| ref | 1 | 0 | Inf | totdose | 100.000000 |  | NA | NA | NA |
| ref | 1 | 0 | Inf | aucinf.obs | 48.491740 | AUC: lin up/log down | NA | NA | NA |
| test | 1 | 0 | Inf | totdose | 50.000000 |  | NA | NA | NA |
| test | 1 | 0 | Inf | aucinf.obs | 19.628268 | AUC: lin up/log down | NA | NA | NA |
| test | 1 | 0 | Inf | f.obs | 0.809551 | Reference interval: treatment=ref, 0-Inf | NA | ref | 1 |

The result is the ratio of the dose-normalized exposures:

``` r

value_of <- function(param, trt) {
  d_f$PPORRES[d_f$PPTESTCD %in% param & d_f$treatment %in% trt]
}
(value_of("aucinf.obs", "test")/value_of("totdose", "test")) /
  (value_of("aucinf.obs", "ref")/value_of("totdose", "ref"))
#> [1] 0.809551
```

Bioavailability names the AUC it is built on, because which AUC was used
changes the answer and is not recoverable from the number:

``` r

f_params <-
  c("f.obs", "f.pred", "f.last", "f.int.obs", "f.int.pred",
    "f.int.last", "f.int.all")
kable(
  data.frame(
    parameter = f_params,
    `AUC basis` =
      vapply(
        X = f_params,
        FUN = function(x) get.interval.cols()[[x]]$formalsmap$auc2,
        FUN.VALUE = ""
      ),
    check.names = FALSE
  ),
  row.names = FALSE
)
```

| parameter  | AUC basis       |
|:-----------|:----------------|
| f.obs      | aucinf.obs      |
| f.pred     | aucinf.pred     |
| f.last     | auclast         |
| f.int.obs  | aucint.inf.obs  |
| f.int.pred | aucint.inf.pred |
| f.int.last | aucint.last     |
| f.int.all  | aucint.all      |

The `ratio.*` parameters are named the same way: `ratio.cmax`,
`ratio.auclast`, `ratio.aucinf.obs`, `ratio.aucinf.pred`,
`ratio.aucint.last`, and `ratio.aucint.all` each compare the parameter
they are named for.

## Exclusions cross the link

An exclusion on a value that feeds a secondary parameter reaches the
result. Here the plasma profile has too few points for a half-life, so
the `aucinf.obs` that extrapolates with it is excluded, and the renal
clearance built on that AUC inherits the reason:

``` r

d_conc_x <-
  data.frame(
    subject = 1,
    PCSPEC = rep(c("plasma", "urine"), times = c(3, 2)),
    time = c(0, 2, 4, 0, 6),
    conc = c(10, 8, 7, 2, 1),
    vol  = c(NA, NA, NA, 100, 150)
  )
intervals_x <-
  data.frame(
    PCSPEC = c("plasma", "urine"),
    start = 0, end = 6,
    interval_id = c("plasma06", NA),
    aucinf.obs = c(TRUE, FALSE),
    ae = c(FALSE, TRUE),
    clr.obs = c(FALSE, TRUE),
    clr.obs_ref = c(NA, "plasma06")
  )
o_data_x <-
  PKNCAdata(
    PKNCAconc(d_conc_x, conc~time|PCSPEC+subject, volume = "vol"),
    intervals = intervals_x,
    options = list(auc.method = "linear")
  )
d_x <- as.data.frame(pk.nca(o_data_x))
#> Warning: Too few points for half-life calculation (min.hl.points=3 with only 2
#> points)
kable(
  d_x[
    d_x$PPTESTCD %in% c("half.life", "aucinf.obs", "ae", "clr.obs"),
    c("PCSPEC", "PPTESTCD", "PPORRES", "exclude")
  ]
)
```

| PCSPEC | PPTESTCD | PPORRES | exclude |
|:---|:---|---:|:---|
| plasma | half.life | NA | Too few points for half-life calculation (min.hl.points=3 with only 2 points) |
| plasma | aucinf.obs | NA | Too few points for half-life calculation (min.hl.points=3 with only 2 points) |
| urine | ae | 350 | NA |
| urine | clr.obs | NA | Too few points for half-life calculation (min.hl.points=3 with only 2 points) |

This is the property that post-hoc division of a results table does not
have: an excluded input cannot quietly become a reported clearance.

## Units that differ between the two profiles

A secondary parameter takes one value from the interval requesting it
and another from the reference interval, so when units are given per
group its units are a quotient of the two groups’ units. The urine
collection below is reported in mg/L and the plasma profile in ng/mL:

``` r

d_conc_u <- d_conc
d_conc_u$cu <- ifelse(d_conc_u$PCSPEC %in% "plasma", "ng/mL", "mg/L")
d_conc_u$tu <- "hr"
d_conc_u$au <- "mg"
o_conc_u <-
  PKNCAconc(
    d_conc_u, conc~time|PCSPEC+subject, volume = "vol",
    concu = "cu", timeu = "tu", amountu = "au"
  )
o_data_u <-
  PKNCAdata(
    o_conc_u, intervals = intervals_linked,
    options = list(auc.method = "linear")
  )
d_u <- as.data.frame(pk.nca(o_data_u))
kable(d_u[, c("PCSPEC", "PCSPEC_ref", "PPTESTCD", "PPORRES", "PPORRESU")])
```

| PCSPEC | PCSPEC_ref | PPTESTCD |    PPORRES | PPORRESU       |
|:-------|:-----------|:---------|-----------:|:---------------|
| plasma | NA         | auclast  | 144.000000 | hr\*ng/mL      |
| urine  | NA         | ae       | 350.000000 | mg             |
| urine  | plasma     | clr.last |   2.430556 | mg/(hr\*ng/mL) |

The renal clearance is still $`350/144 = 2.431`$ – no value is converted
– and its units are `mg/(hr*ng/mL)`: the `mg` from the urine collection
that supplied the amount, and the `hr*ng/mL` from the plasma profile
that supplied the AUC. Reporting it as `mg/(hr*mg/L)`, the urine group’s
own units, would describe a different number.

Two things make that work. Each secondary result names the group its
reference came from in a `<group column>_ref` column (above,
`PCSPEC_ref` is `plasma` on the renal clearance and `NA` on everything
else), and the units table carries a row for each pair of groups:

``` r

u <- o_data_u$units
kable(u[u$PPTESTCD %in% c("auclast", "ae", "clr.last"), ], row.names = FALSE)
```

| PCSPEC | PPORRESU       | PPTESTCD | PCSPEC_ref | PPSTRESU       | conversion_factor |
|:-------|:---------------|:---------|:-----------|:---------------|------------------:|
| plasma | mg             | ae       | NA         | mg             |                 1 |
| plasma | hr\*ng/mL      | auclast  | NA         | hr\*ng/mL      |                 1 |
| plasma | mg/(hr\*ng/mL) | clr.last | NA         | mg/(hr\*ng/mL) |                 1 |
| urine  | mg             | ae       | NA         | mg             |                 1 |
| urine  | hr\*mg/L       | auclast  | NA         | hr\*mg/L       |                 1 |
| urine  | mg/(hr\*mg/L)  | clr.last | NA         | mg/(hr\*mg/L)  |                 1 |
| plasma | mg/(hr\*ng/mL) | clr.last | plasma     | mg/(hr\*ng/mL) |                 1 |
| plasma | mg/(hr\*mg/L)  | clr.last | urine      | mg/(hr\*mg/L)  |                 1 |
| urine  | mg/(hr\*ng/mL) | clr.last | plasma     | mg/(hr\*ng/mL) |                 1 |
| urine  | mg/(hr\*mg/L)  | clr.last | urine      | mg/(hr\*mg/L)  |                 1 |

The rows with `NA` in `PCSPEC_ref` describe results that took nothing
from another interval; the rest describe each pair. The table is an
ordinary `PKNCAdata(units = )` argument, so these rows can be edited or
replaced like any other unit assignment.

### A ratio standardizes to a fraction

When both sides of the quotient are convertible into one another the
quotient is dimensionless, and the table also gives it a `PPSTRESU` of
`fraction` with the factor that turns the raw quotient into the number
it stands for. Here the metabolite is reported in ng/mL and the parent
in mg/L:

``` r

d_conc_r <-
  data.frame(
    subject = 1,
    Analyte = rep(c("parent", "metabolite"), each = 3),
    time = rep(c(0, 12, 24), times = 2),
    conc = c(4, 10, 2, 8000, 20000, 4000),
    cu = rep(c("mg/L", "ng/mL"), each = 3),
    tu = "hr"
  )
intervals_r <-
  data.frame(
    Analyte = c("parent", "metabolite"),
    start = 0, end = 24,
    interval_id = c("parent024", NA),
    cmax = TRUE,
    ratio.cmax = c(FALSE, TRUE),
    ratio.cmax_ref = c(NA, "parent024")
  )
o_data_r <-
  PKNCAdata(
    PKNCAconc(d_conc_r, conc~time|Analyte+subject, concu = "cu", timeu = "tu"),
    intervals = intervals_r,
    options = list(auc.method = "linear")
  )
d_r <- as.data.frame(pk.nca(o_data_r))
kable(
  d_r[, c("Analyte", "Analyte_ref", "PPTESTCD", "PPORRES", "PPORRESU",
          "PPSTRES", "PPSTRESU")]
)
```

| Analyte    | Analyte_ref | PPTESTCD   | PPORRES | PPORRESU       | PPSTRES | PPSTRESU |
|:-----------|:------------|:-----------|--------:|:---------------|--------:|:---------|
| metabolite | NA          | cmax       |   20000 | ng/mL          |   20000 | ng/mL    |
| parent     | NA          | cmax       |      10 | mg/L           |      10 | mg/L     |
| metabolite | parent      | ratio.cmax |    2000 | (ng/mL)/(mg/L) |       2 | fraction |

`PPORRES` is 20000 divided by 10, in `(ng/mL)/(mg/L)`. One ng/mL is
0.001 mg/L, so the ratio those measurements stand for is
$`20000/10 \times 0.001 = 2`$, which is `PPSTRES`.

### A quotient that is not a fraction

Calling every ratio a fraction hides a real mistake. A bioavailability
between a dose in mg and a dose in mg/kg is not dimensionless, and the
units say so instead of reporting the number as a `fraction`:

``` r

d_conc_fu <- d_conc_f
d_conc_fu$cu <- "ng/mL"
d_conc_fu$tu <- "hr"
d_dose_fu <- d_dose_f
d_dose_fu$du <- c("mg", "mg/kg")
o_data_fu <-
  PKNCAdata(
    PKNCAconc(d_conc_fu, conc~time|treatment+subject, concu = "cu", timeu = "tu"),
    PKNCAdose(d_dose_fu, dose~time|treatment+subject, doseu = "du"),
    intervals = intervals_f
  )
d_fu <- as.data.frame(pk.nca(o_data_fu))
kable(d_fu[d_fu$PPTESTCD %in% "f.obs", c("treatment", "treatment_ref", "PPORRES", "PPORRESU")])
```

| treatment | treatment_ref |  PPORRES | PPORRESU                             |
|:----------|:--------------|---------:|:-------------------------------------|
| test      | ref           | 0.809551 | ((hr*ng/mL)/(mg/kg))/((hr*ng/mL)/mg) |

The number is the same one
[`pk.calc.f()`](https://humanpred.github.io/pknca/reference/pk.calc.f.md)
has always computed; the units are now what it is a number of. Dividing
a mg/kg dose by a mg dose needs a body weight that PKNCA was never
given.

Units the `units` package cannot reconcile – `IU/mL` against `mg/L`, or
two units of different dimensions – behave the same way: the value is
reported and the composite units stand. Nothing is `NA` for unit
reasons.

## Reporting

`PPANMETH` discloses the reference interval on every linked result: how
it differs from the interval reporting the result, and its times.

``` r

d_linked <- as.data.frame(results_linked)
d_linked$PPANMETH[d_linked$PPTESTCD %in% "clr.last"]
#> [1] "Reference interval: PCSPEC=plasma, 0-24"
```

Secondary parameters are summarized like any other parameter, on the
interval that requested them. Rows that did not request the parameter
are `.`:

``` r

kable(as.data.frame(summary(results_linked)))
```

| start | end | PCSPEC | N   | auclast | ae  | clr.last |
|------:|----:|:-------|:----|:--------|:----|:---------|
|     0 |  24 | plasma | 1   | 144     | .   | .        |
|     0 |  24 | urine  | 1   | .       | 350 | 2.43     |

`as.data.frame(filter_requested = TRUE)` reports only the parameters the
interval specification asked for, dropping the source values calculated
to support a link.

## Limitations

- Sparse concentration data (`PKNCAconc(sparse = TRUE)`) with any
  secondary parameter requested is an error. Supporting it is planned.
- The reference for an absolute bioavailability is not yet derived from
  the route of administration; give it with `group_ref`, a `f.obs_ref`
  pointer, or
  [`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md).
- The CDISC `PPTESTCD` of a ratio does not yet depend on what the ratio
  compares (accumulation against metabolite ratio).
- [`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md)
  and the `exclude_nca_*()` functions work on a finished `PKNCAresults`
  and cannot reach across groups, so an exclusion applied after the
  calculation does not propagate along a link the way one set during the
  calculation does.
- Molecular-weight adjustment of a metabolite ratio (a molar conversion)
  is a units-layer feature that is not yet available.

## See also

- [`vignette("v03-selection-of-calculation-intervals")`](https://humanpred.github.io/pknca/articles/v03-selection-of-calculation-intervals.md)
  for interval specifications generally.
- [`vignette("v07-unit-conversion")`](https://humanpred.github.io/pknca/articles/v07-unit-conversion.md)
  for how units are assigned and converted.
- [`vignette("v80-writing-parameter-functions")`](https://humanpred.github.io/pknca/articles/v80-writing-parameter-functions.md)
  for writing a parameter that needs another interval.
