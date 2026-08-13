# Assess bioequivalence against a regulatory framework

`be_assess()` performs a complete bioequivalence (BE) assessment of one
or more noncompartmental endpoints against a regulatory framework,
including reference scaling and the pass/fail decision. It accepts the
results of
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
directly (a `PKNCAresults` object) or a tidy long data.frame, so the
same workflow that produces NCA parameters flows into the regulatory
decision. It is a thin wrapper over
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md)
that adds the `be_assess` class and its print/summary methods.

## Usage

``` r
be_assess(
  object,
  reference_col,
  reference_value,
  endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
  regulator = "ABE",
  model_type = NULL,
  alpha = 0.1,
  subject = NULL,
  sequence = NULL,
  period = NULL,
  design = NULL
)
```

## Arguments

- object:

  A `PKNCAresults` object or a tidy long data.frame with a `PPTESTCD`
  column of parameter names, a `PPORRES`/`PPSTRES` column of values, and
  subject/sequence/period/treatment columns.

- reference_col:

  The column identifying the formulation/treatment.

- reference_value:

  The value of `reference_col` that is the reference formulation.

- endpoints:

  Character vector of NCA parameters (matched against `PPTESTCD`) to
  assess.

- regulator:

  The regulatory framework (see
  [`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md));
  one of `"ABE"`, `"EMA"`, `"HC"`, `"GCC"`, `"FDA"`, `"NTID"`, or
  `"HVNTID"`.

- model_type:

  The model for the average-BE point estimate, one of `"lmer"` (mixed
  model, for crossover/replicate designs), `"anova"` (fixed-effects, for
  parallel designs), `"isc"` (intra-subject contrasts, the FDA
  reference-scaled path), or `"nlme"` (treatment-specific mixed model).
  When `NULL` (default) it is chosen from the design and regulator.

- alpha:

  The significance level; the confidence interval has level `1 - alpha`
  (default `0.10` gives the 90% interval).

- subject, sequence, period:

  Column names for the subject, randomization sequence, and period. When
  `NULL` they are taken from the `PKNCAresults` object or detected from
  common column names. `sequence` may be absent.

- design:

  An optional
  [`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md)
  object; computed from the data when `NULL`.

## Value

An object of class `be_assess` (a data.frame), ordered by endpoint (in
the order requested) then by test formulation (reference-first), with
one row per endpoint and test formulation and the columns `endpoint`,
`test`, `n`, `design`, `units` (the endpoint's measurement units; the
column is omitted with a warning when units are not provided), the
reference and test geometric means with their 90% confidence intervals
on the measurement scale (`gm_reference`, `gm_reference_lower`,
`gm_reference_upper`, `gm_test`, `gm_test_lower`, `gm_test_upper`),
`gmr_percent`, `ci_lower`, `ci_upper`, `cvwr_percent`, `cvwt_percent`,
`swr`, `limit_lower`, `limit_upper`, `criterion`, `regulator`,
`model_type`, and `pass`. `limit_*` are `NA` for the RSABE criterion and
`criterion` is `NA` for the limit-based frameworks. A `caption`
attribute documents the model and the decision rule.

## Details

The model type is selected automatically from the design and the
regulator. By design, a parallel study (one measurement per subject)
uses a fixed-effects ANOVA (`"anova"`), while a crossover or replicate
study (repeated measures per subject) uses the mixed model (`"lmer"`)
for the geometric mean ratio and its confidence interval. The FDA
reference-scaled frameworks (FDA RSABE, NTID, HVNTID) always use
intra-subject contrasts (`"isc"`), as the guidances specify, regardless
of design. Pass `model_type` to override (`"lmer"`, `"anova"`, `"isc"`,
or `"nlme"`). Within-subject variability uses the regulatory ANOVA
estimator for the `"lmer"`/`"anova"`/`"isc"` paths and the
treatment-specific mixed-model estimator for `"nlme"`.

## See also

[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md)
to assess one dataset under several frameworks,
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md),
and
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md).

Other Bioequivalence:
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md),
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md),
[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md),
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md),
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md),
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md),
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)

## Examples

``` r
# A replicate-design crossover in long (PPTESTCD/PPORRES) format
set.seed(1)
nsub <- 24
seqs <- rep(c("TRTR", "RTRT"), length.out = nsub)
b <- stats::rnorm(nsub, sd = 0.4)
d <- do.call(rbind, lapply(seq_len(nsub), function(i) {
  trt <- strsplit(seqs[i], "")[[1]]
  data.frame(
    subject = i, sequence = seqs[i], period = seq_along(trt), treatment = trt,
    PPTESTCD = "auclast",
    PPORRES = exp(log(100) + ifelse(trt == "T", 0.04, 0) + b[i] +
                    stats::rnorm(length(trt), sd = 0.45)),
    stringsAsFactors = FALSE
  )
}))
be_assess(d, reference_col = "treatment", reference_value = "R",
          endpoints = "auclast", regulator = "EMA")
#> Warning: Units were not found in the data; omitting the `units` column. Supply units via a PKNCAresults object or `PPSTRESU`/`PPORRESU` columns.
#> Bioequivalence assessment: EMA (model_type lmer, 90% CI)
#> Design: full_replicate
#> 
#>  endpoint test  n         design gm_reference gm_reference_lower
#>   auclast    T 24 full_replicate       114.44              95.46
#>  gm_reference_upper gm_test gm_test_lower gm_test_upper gmr_percent ci_lower
#>               137.2  112.15         93.55        134.46          98    85.72
#>  ci_upper cvwr_percent cvwt_percent  swr limit_lower limit_upper criterion
#>    112.04        34.11        47.67 0.33       77.71      128.68        NA
#>  regulator model_type pass
#>        EMA       lmer TRUE
#> 
#> Caption: EMA bioequivalence assessment (90% CI). Geometric means and the geometric mean ratio are least-squares means from a mixed-effects model (lmerTest::lmer, Satterthwaite degrees of freedom); the 90% CI comes from exponentiated least-squares-mean differences (emmeans). Acceptance limits are widened by the within-reference variability (ABEL) and capped per the regulator. Within-formulation variances (swR, swT) are estimated by ANOVA on each formulation's replicates.
#> 
```
