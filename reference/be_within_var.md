# Within-subject variability for reference-scaled bioequivalence

`be_within_var()` estimates the within-subject standard deviations of
the log-transformed endpoint separately for the reference (`swR`) and
test (`swT`) formulations, the quantities that reference-scaling
frameworks need. The default `model_type = "anova"` is an analysis of
variance (ANOVA) of the replicate observations within each formulation;
this is the estimator used by both Method A and Method B of the EMA
`replicateBE` reference implementation and by the FDA moment-based
approach, and it works for full and partial replicate designs.
`model_type = "nlme"` instead fits a single mixed model with
treatment-specific residual variances and requires a fully replicated
design; it is provided as the alternative described in the FDA
progesterone guidance and can differ slightly from `"anova"`.

## Usage

``` r
be_within_var(
  data,
  value,
  subject,
  period,
  treatment,
  reference_value,
  model_type = c("anova", "nlme"),
  alpha = 0.1
)
```

## Arguments

- data:

  A long data.frame with one row per observation for a *single* endpoint
  (subject, period, treatment, and the endpoint value).

- value:

  The column name of the (untransformed) endpoint value; it is
  log-transformed internally.

- subject, period, treatment:

  Column names identifying the subject, period, and treatment.

- reference_value:

  The value of `treatment` that is the reference.

- model_type:

  `"anova"` (the default and the regulatory standard) or `"nlme"` (mixed
  model with treatment-specific residual variances; full replicate
  only).

- alpha:

  The significance level for the `swT`/`swR` ratio confidence bound
  (default `0.10` gives the 90% upper bound used for narrow therapeutic
  index drugs).

## Value

An object of class `be_within_var`: a list with `swR`, `swT`, `s2wR`,
`s2wT`, `cvwr_percent`, `cvwt_percent`, `df_wR`, `df_wT`, `sw_ratio` (=
`swT`/`swR`), `sw_ratio_ci_upper` (the upper `1 - alpha` confidence
bound of the ratio), `model_type`, and `alpha`. `swT` and the ratio are
`NA` when the test formulation is not replicated (for example a partial
replicate design).

## See also

[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md),
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md),
[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md),
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md),
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md),
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md)
