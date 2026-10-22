# Fit the bioequivalence model(s) for one endpoint

`be_fit_model_single()` fits the average-BE model for a single endpoint
and dispatches on `model_type` to `be_fit_model_lmer()`,
`be_fit_model_nlme()`, `be_fit_model_gls()`, or `be_fit_model_anova()`.
This is the only place model fitting happens. For the `"lmer"`,
`"anova"`, and `"isc"` types the within-formulation ANOVA variances are
also fit here; for `"nlme"` they come from the single mixed model. The
`"isc"` type, the FDA path, also fits the FDA mixed-effects model for
the unscaled ratio (treatment-specific between- and within-subject
variances, Satterthwaite degrees of freedom, as in the FDA progesterone
and warfarin guidance SAS code). Covariate columns carried by
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md)
(`.cov_<name>`) enter every model as additive fixed effects.

## Usage

``` r
be_fit_model_single(
  ds_ep,
  model_type = c("lmer", "nlme", "anova", "isc", "gls"),
  scaling = TRUE
)
```

## Arguments

- ds_ep:

  The standardized single-endpoint data.frame from
  [`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md)
  (`be_dataset(...)$data` filtered to one endpoint).

- model_type:

  One of `"lmer"`, `"nlme"`, `"anova"`, `"isc"` (the FDA path: `"anova"`
  for the geometric means plus, for a replicate design, the FDA
  mixed-effects model for the ratio), or `"gls"` (generalized least
  squares with treatment-specific residual variances, for parallel
  designs).

- scaling:

  Logical; whether reference scaling is needed (controls whether the
  within-formulation variances are estimated).

## Value

An object of class `be_fit`: a list with `model_type`, the fitted
`model`, (for lmer/anova/isc) `ref_var`/`test_var` within-formulation
ANOVA variances, and (for isc with repeated measures) `fda`, the FDA
mixed-model estimates. The endpoint's measurement units are attached as
a `units` attribute (`NULL` when not provided).

## See also

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md),
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md),
[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md),
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md),
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md),
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)
