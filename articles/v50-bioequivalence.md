# Bioequivalence Calculations

After noncompartmental analysis (NCA) parameters such as the area under
the curve (AUC) and maximum concentration (C_(max)) have been
calculated, average bioequivalence (BE) of a test formulation relative
to a reference formulation is assessed with inferential statistics.
PKNCA provides a single function for the whole assessment:

- **[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)**
  takes the results of
  [`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
  (or a tidy data.frame), a regulatory framework, and the reference
  formulation, and returns a table with the geometric mean ratio (GMR),
  its confidence interval, the within-subject variability, the (possibly
  scaled) acceptance limits or criterion, and the pass/fail decision for
  each endpoint.
- **[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md)**
  runs the same study under several frameworks side by side.

These consume the results of
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
directly, so the same workflow that produces NCA parameters flows into
the bioequivalence assessment.

## How the calculation works

[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
(and
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md))
are thin verbs over a single calculation path, the coordinator
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
which runs these stages in order:

1.  **[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md)**
    – validate the data, resolve the value column, drop excluded rows,
    detect the subject/sequence/period columns, and set the reference as
    the first factor level.
2.  **[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md)**
    – classify the design (parallel, 2x2x2 crossover, full or partial
    replicate) and report which frameworks it can support.
3.  **[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md)**
    – fit the average-BE model (this is the only place models are fit),
    dispatching on the model type to `be_fit_model_lmer()`,
    `be_fit_model_nlme()`, or `be_fit_model_anova()`.
4.  **[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md)**
    – extract the geometric means, the GMR and its confidence interval,
    and the within-formulation standard deviations.
5.  **[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md)**
    – apply the regulatory limits or criterion and decide pass/fail
    (using the constants from
    [`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md)).

The model type is selected automatically from the **design and the
regulator**; pass `model_type` to
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
to override it. A parallel study (one measurement per subject) is
analyzed by a fixed-effects ANOVA, while a crossover or replicate study
(repeated measures per subject) uses the mixed model. The FDA
reference-scaled family always uses intra-subject contrasts (`"isc"`)
regardless of design.

| Regulator | Design required | Auto `model_type` | Notes |
|----|----|----|----|
| `ABE` | any (test & reference) | `lmer` (crossover/replicate) / `anova` (parallel) | unscaled 80.00-125.00% |
| `EMA` / `HC` / `GCC` | replicated reference | `lmer` | expanding limits (ABEL) |
| `FDA` (RSABE) | replicated reference | `isc` | intra-subject contrasts + linearized bound |
| `NTID` / `HVNTID` | full replicate (test & reference) | `isc` | adds a swT/swR ratio constraint |
| *(override)* | full replicate | `nlme` | treatment-specific variances from one mixed model |

The table also reports, on the measurement scale, the reference and test
geometric means with their 90% confidence intervals
(`gm_reference`/`gm_test` and their `_lower`/`_upper` bounds) and the
endpoint `units` (taken from the `PKNCAresults` object; `NA` when not
provided, and a column because they differ between C_(max) and AUC).

## Optional packages

The bioequivalence calculations use
[`lme4`](https://cran.r-project.org/package=lme4),
[`lmerTest`](https://cran.r-project.org/package=lmerTest), and
[`emmeans`](https://cran.r-project.org/package=emmeans) to fit the mixed
model and estimate least-squares means. They are *Suggested* packages,
so install them if they are not already present:

``` r

install.packages(c("lme4", "lmerTest", "emmeans"))
```

## Simulating a 2x2 crossover study

A classic average-bioequivalence study uses a two-sequence, two-period
crossover design: each subject receives both the test (T) and reference
(R) formulations, in an order determined by their randomized sequence
(RT or TR). We simulate concentration-time data from a one-compartment
model with first-order absorption, with between-subject variability on
clearance and a small difference between formulations.

``` r

simulate_crossover <- function(nsub = 24, seed = 20251201) {
  set.seed(seed)
  times <- c(0, 0.25, 0.5, 1, 1.5, 2, 3, 4, 6, 8, 12, 16, 24)
  sequence <- rep(c("RT", "TR"), length.out = nsub)
  subj_cl <- stats::rnorm(nsub, mean = log(5), sd = 0.25)
  dose <- 100
  v <- 50
  ka <- 1.1
  rows <- list()
  for (i in seq_len(nsub)) {
    forms <- if (sequence[i] == "RT") c("R", "T") else c("T", "R")
    for (p in 1:2) {
      form <- forms[p]
      # The test formulation has slightly higher exposure (lower clearance)
      cl <- exp(subj_cl[i] + ifelse(form == "T", -0.05, 0) + stats::rnorm(1, sd = 0.06))
      ke <- cl / v
      conc <- (dose * ka / (v * (ka - ke))) * (exp(-ke * times) - exp(-ka * times))
      conc <- conc * exp(stats::rnorm(length(times), sd = 0.05))
      conc[times == 0] <- 0
      rows[[length(rows) + 1]] <-
        data.frame(
          subject = i, sequence = sequence[i], period = p, formulation = form,
          time = times, conc = conc
        )
    }
  }
  do.call(rbind, rows)
}

conc_data <- simulate_crossover()
head(conc_data)
#>   subject sequence period formulation time      conc
#> 1       1       RT      1           R 0.00 0.0000000
#> 2       1       RT      1           R 0.25 0.5054207
#> 3       1       RT      1           R 0.50 0.8116205
#> 4       1       RT      1           R 1.00 1.1486459
#> 5       1       RT      1           R 1.50 1.5238739
#> 6       1       RT      1           R 2.00 1.5782127
```

## Noncompartmental analysis

The crossover structure is described in the grouping formula. The
grouping variables are the sequence, period, and formulation, with the
subject as the final grouping variable.

``` r

dose_data <- conc_data[conc_data$time == 0, c("subject", "sequence", "period", "formulation")]
dose_data$dose <- 100
dose_data$time <- 0

o_conc <- PKNCAconc(conc_data, conc ~ time | sequence + period + formulation + subject)
o_dose <- PKNCAdose(dose_data, dose ~ time | sequence + period + formulation + subject)

intervals <-
  data.frame(start = 0, end = Inf, cmax = TRUE, auclast = TRUE, aucinf.obs = TRUE)
o_data <- PKNCAdata(o_conc, o_dose, intervals = intervals)

o_results <- pk.nca(o_data)
```

The NCA parameters are available with
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) as usual:

``` r

knitr::kable(head(as.data.frame(o_results)), digits = 2)
```

| sequence | period | formulation | subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude |
|:---|---:|:---|---:|---:|---:|:---|---:|:---|:---|
| RT | 1 | R | 1 | 0 | Inf | auclast | 20.83 | AUC: lin up/log down | NA |
| RT | 1 | R | 1 | 0 | Inf | cmax | 1.77 |  | NA |
| RT | 1 | R | 1 | 0 | Inf | tmax | 4.00 |  | NA |
| RT | 1 | R | 1 | 0 | Inf | tlast | 24.00 |  | NA |
| RT | 1 | R | 1 | 0 | Inf | clast.obs | 0.31 |  | NA |
| RT | 1 | R | 1 | 0 | Inf | lambda.z | 0.08 |  | NA |

## Bioequivalence assessment

[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
takes the `PKNCAresults` object, the column that identifies the
formulation (`reference_col`), the value of that column that is the
reference (`reference_value`), and the regulatory framework. This 2x2
study is not replicated, so only average bioequivalence
(`regulator = "ABE"`) is feasible.

``` r

be <- be_assess(
  o_results,
  endpoints = c("cmax", "auclast", "aucinf.obs"),
  reference_col = "formulation",
  reference_value = "R",
  regulator = "ABE"
)
#> Warning: Units were not found in the data; omitting the `units` column. Supply
#> units via a PKNCAresults object or `PPSTRESU`/`PPORRESU` columns.

knitr::kable(as.data.frame(be), digits = 2)
```

| endpoint | test | n | design | gm_reference | gm_reference_lower | gm_reference_upper | gm_test | gm_test_lower | gm_test_upper | gmr_percent | ci_lower | ci_upper | cvwr_percent | cvwt_percent | swr | limit_lower | limit_upper | criterion | regulator | model_type | pass |
|:---|:---|---:|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:---|:---|:---|
| cmax | T | 24 | full_replicate | 1.59 | 1.55 | 1.62 | 1.58 | 1.55 | 1.62 | 99.68 | 97.21 | 102.20 | NA | NA | NA | 80 | 125 | NA | ABE | lmer | TRUE |
| auclast | T | 24 | full_replicate | 16.90 | 15.86 | 18.00 | 17.55 | 16.47 | 18.69 | 103.83 | 100.83 | 106.93 | NA | NA | NA | 80 | 125 | NA | ABE | lmer | TRUE |
| aucinf.obs | T | 24 | full_replicate | 18.66 | 17.12 | 20.34 | 19.61 | 17.99 | 21.38 | 105.09 | 101.26 | 109.07 | NA | NA | NA | 80 | 125 | NA | ABE | lmer | TRUE |

## Interpreting the results

For each endpoint and test formulation the table reports:

- `units`: the measurement units of the endpoint (e.g. `ng/mL` for
  C_(max), `hr*ng/mL` for AUC), taken from the `PKNCAresults` object,
- `gm_reference`, `gm_test` (with `_lower`/`_upper` bounds): the
  reference and test geometric means and their 90% confidence intervals,
  on the measurement scale (in `units`),
- `gmr_percent`: the geometric mean ratio (test / reference), as a
  percentage,
- `ci_lower`, `ci_upper`: the bounds of the confidence interval for the
  GMR (90% by default, controlled by `alpha`),
- `cvwr_percent`, `swr`: the within-reference coefficient of variation
  and standard deviation (used by the reference-scaling frameworks; `NA`
  for unscaled ABE),
- `limit_lower`, `limit_upper`: the acceptance limits, and `criterion`
  for the FDA reference-scaled bound, and
- `pass`: the regulatory decision.

Two formulations are declared bioequivalent under ABE when the 90%
confidence interval for the geometric mean ratio falls entirely within
80.00%-125.00% for the primary endpoints (commonly AUC and C_(max)).

For ABE the average-BE model fit for each endpoint is

``` math
\log(\text{value}) = \text{sequence} + \text{period} + \text{formulation} + (1 \mid \text{subject})
```

fit with
[`lmerTest::lmer()`](https://rdrr.io/pkg/lmerTest/man/lmer.html) so that
Satterthwaite degrees of freedom are available, and the confidence
interval is obtained by exponentiating the difference in least-squares
means between the test and reference formulations.

## Reference scaling and regulatory frameworks

Highly variable drugs (within-subject coefficient of variation above
30%) are difficult to show bioequivalent against the fixed 80.00-125.00%
limits, so regulators allow the limits to be *scaled* by the
within-reference variability, estimated from a replicate design in which
the reference is given more than once. PKNCA implements the major
frameworks through
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md):

- **ABE** – average bioequivalence, the unscaled 80.00-125.00%
  criterion.
- **EMA**, **Health Canada (HC)**, and **GCC** – average bioequivalence
  with expanding limits (ABEL); the limits widen with the
  within-reference standard deviation, with framework-specific caps.
- **FDA RSABE** – reference-scaled average bioequivalence using the
  linearized Howe/Hyslop criterion.
- **FDA NTID** and **HVNTID** – the (highly variable) narrow therapeutic
  index drug frameworks, which add a constraint on the ratio of
  within-subject standard deviations.

All regulatory constants are built into PKNCA (see
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md));
no external package is required.

### A replicate-design study

Reference scaling needs the reference replicated, so we simulate a
four-period, two-sequence full replicate design (`TRTR`/`RTRT`) with
high within-subject variability.

``` r

simulate_replicate <- function(nsub = 24, seed = 20251015, cv_wr = 0.45, cv_wt = 0.40) {
  set.seed(seed)
  seqs <- rep(c("TRTR", "RTRT"), length.out = nsub)
  swR <- sqrt(log(cv_wr^2 + 1))
  swT <- sqrt(log(cv_wt^2 + 1))
  subj <- stats::rnorm(nsub, sd = 0.4)
  rows <- list()
  for (i in seq_len(nsub)) {
    trt <- strsplit(seqs[i], "")[[1]]
    for (p in seq_along(trt)) {
      sw <- if (trt[p] == "R") swR else swT
      eff <- if (trt[p] == "T") log(1.05) else 0
      rows[[length(rows) + 1]] <- data.frame(
        subject = i, sequence = seqs[i], period = p, treatment = trt[p],
        PPTESTCD = "auclast",
        PPORRES = exp(log(100) + eff + subj[i] + stats::rnorm(1, sd = sw))
      )
    }
  }
  do.call(rbind, rows)
}

rep_data <- simulate_replicate()
```

[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
takes the long data (or a `PKNCAresults` object), the column that
identifies the formulation, the reference value, and the framework. It
returns one row per endpoint and test formulation with the geometric
mean ratio, the confidence interval, the within-subject variability, the
(possibly scaled) acceptance limits or criterion, and the pass/fail
decision.

``` r

ema <- be_assess(rep_data, reference_col = "treatment", reference_value = "R",
                 endpoints = "auclast", regulator = "EMA")
#> Warning: Units were not found in the data; omitting the `units` column. Supply
#> units via a PKNCAresults object or `PPSTRESU`/`PPORRESU` columns.
knitr::kable(as.data.frame(ema), digits = 3)
```

| endpoint | test | n | design | gm_reference | gm_reference_lower | gm_reference_upper | gm_test | gm_test_lower | gm_test_upper | gmr_percent | ci_lower | ci_upper | cvwr_percent | cvwt_percent | swr | limit_lower | limit_upper | criterion | regulator | model_type | pass |
|:---|:---|---:|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|:---|:---|:---|
| auclast | T | 24 | full_replicate | 110.423 | 93.1 | 130.969 | 103.353 | 87.139 | 122.584 | 93.598 | 81.783 | 107.12 | 52.289 | 30.063 | 0.492 | 69.837 | 143.191 | NA | EMA | lmer | TRUE |

For this dataset the within-reference CV is about 50%, so the EMA limits
expand from 80.00-125.00% toward their cap. The FDA reference-scaled
criterion instead reports the linearized bound (`criterion`), which
passes when it is at most zero:

``` r

fda <- be_assess(rep_data, reference_col = "treatment", reference_value = "R",
                 endpoints = "auclast", regulator = "FDA")
#> Warning: Units were not found in the data; omitting the `units` column. Supply
#> units via a PKNCAresults object or `PPSTRESU`/`PPORRESU` columns.
knitr::kable(as.data.frame(fda)[, c("gmr_percent", "ci_lower", "ci_upper",
                                    "cvwr_percent", "swr", "criterion", "pass")],
             digits = 4)
```

| gmr_percent | ci_lower | ci_upper | cvwr_percent |    swr | criterion | pass |
|------------:|---------:|---------:|-------------:|-------:|----------:|:-----|
|     93.5978 |  82.4596 | 106.2405 |      52.2889 | 0.4916 |   -0.1159 | TRUE |

### Comparing frameworks side by side

[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md)
runs the same study under several frameworks at once; frameworks the
design cannot support are skipped with a warning.

``` r

cmp <- be_compare(rep_data, reference_col = "treatment", reference_value = "R",
                  endpoints = "auclast",
                  regulators = c("EMA", "HC", "GCC", "FDA", "NTID", "HVNTID"))
#> Warning: Units were not found in the data; omitting the `units` column. Supply
#> units via a PKNCAresults object or `PPSTRESU`/`PPORRESU` columns.
summary(cmp)
#>   endpoint  EMA   HC  GCC  FDA NTID HVNTID
#>  auclast:T TRUE TRUE TRUE TRUE TRUE   TRUE
#> 
#> Caption: Pass/fail by endpoint and regulator.
```

The pass/fail decision can differ between frameworks for the same data.
The narrow therapeutic index frameworks are the strictest: **NTID**
requires the reference-scaled bound, the conventional 90% confidence
interval within 80.00-125.00%, *and* the upper 90% bound of the
within-subject standard-deviation ratio swT/swR at most 2.5; **HVNTID**
(highly variable NTID) drops the reference-scaled bound but keeps the
conventional interval and the swT/swR constraint. These FDA criteria
match those in `PowerTOST`’s `power.NTID()` / `power.HVNTID()`.

> **Note on the geometric-mean intervals.** `gm_reference`/`gm_test` and
> their bounds are the marginal least-squares-mean intervals, so they
> include between-subject variability and are wider than the
> (within-subject) confidence interval for the ratio in
> `ci_lower`/`ci_upper`.

> **Planning vs. assessment.** PKNCA *assesses* a completed study. Power
> and sample-size *planning* for these designs is not in PKNCA; the
> [`PowerTOST`](https://cran.r-project.org/package=PowerTOST) package
> covers that complementary need.

## Reporting checklist

The assessment table supports common bioequivalence reporting
requirements:

1.  **Framework and model**: the `regulator` and `model_type` columns
    record the framework and the average-BE model used, and the table’s
    `caption` attribute gives a one-sentence methods statement (model,
    confidence-interval method, within-subject variability, and the
    decision rule).
2.  **%GMR, confidence interval, within-subject CV, limits/criterion,
    and the pass/fail decision**: one row per endpoint and test
    formulation in `as.data.frame(be_assess(...))`.
3.  **Cross-regulator comparison**: `summary(be_compare(...))` gives an
    endpoint-by-regulator pass/fail grid.
4.  **Individual data**: available from `as.data.frame(o_results)` for
    listings and figures.
