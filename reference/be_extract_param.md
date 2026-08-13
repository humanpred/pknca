# Extract bioequivalence parameters from a fitted model

`be_extract_param()` turns a
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md)
fit into the parameters the regulatory decision needs. It always
computes the intra-subject-contrast (ISC) point estimate, then
dispatches on the model type to extract the model-based geometric means,
the geometric mean ratio and its confidence interval, and the
within-formulation standard deviations.

## Usage

``` r
be_extract_param(fit, ds_ep, alpha = 0.1)
```

## Arguments

- fit:

  A `be_fit` object from
  [`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md).

- ds_ep:

  The standardized single-endpoint data.frame from
  [`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md).

- alpha:

  The significance level; the confidence interval has level `1 - alpha`.

## Value

A data.frame with one row per test formulation, carrying the model and
ISC point estimates/intervals, geometric means, and within-formulation
variances.

## See also

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md),
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md),
[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md),
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md),
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md),
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)
