# Fit the bioequivalence model(s) for one endpoint

`be_fit_model_single()` fits the average-BE model for a single endpoint
and dispatches on `model_type` to `be_fit_model_lmer()`,
`be_fit_model_nlme()`, or `be_fit_model_anova()`. This is the only place
model fitting happens. For the `"lmer"`, `"anova"`, and `"isc"` types
the within-formulation ANOVA variances are also fit here; for `"nlme"`
they come from the single mixed model.

## Usage

``` r
be_fit_model_single(
  ds_ep,
  model_type = c("lmer", "nlme", "anova", "isc"),
  scaling = TRUE
)
```

## Arguments

- ds_ep:

  The standardized single-endpoint data.frame from
  [`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md)
  (`be_dataset(...)$data` filtered to one endpoint).

- model_type:

  One of `"lmer"`, `"nlme"`, `"anova"`, or `"isc"` (the
  intra-subject-contrast path, fit like `"anova"`).

- scaling:

  Logical; whether reference scaling is needed (controls whether the
  within-formulation variances are estimated).

## Value

An object of class `be_fit`: a list with `model_type`, the fitted
`model`, and (for lmer/anova/isc) `ref_var`/`test_var`
within-formulation ANOVA variances. The endpoint's measurement units are
attached as a `units` attribute (`NULL` when not provided).

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
