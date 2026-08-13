# Build the regulatory bioequivalence table

`be_table()` takes the parameters from
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md)
and a regulatory framework and produces the final per-endpoint pass/fail
table. It selects the regulator-appropriate statistic (the model
contrast for the expanding-limits frameworks, intra-subject contrasts
for the FDA family) and calls the per-framework decision functions; it
is the only place regulator decisions are made.

## Usage

``` r
be_table(
  params,
  regulator,
  alpha = 0.1,
  design = NA_character_,
  model_type = NA_character_
)
```

## Arguments

- params:

  A data.frame of parameters from
  [`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md)
  (with an `endpoint` column added per endpoint).

- regulator:

  A regulator name or a `be_regulator` object.

- alpha:

  The significance level.

- design:

  The design label (character) for the `design` column.

- model_type:

  The model type label for the `model_type` column.

## Value

A data.frame with one row per endpoint and test formulation and the
pass/fail decision columns.

## See also

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
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)
