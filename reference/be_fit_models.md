# Coordinate the bioequivalence calculation path

`be_fit_models()` runs the single bioequivalence calculation path and
returns the regulatory pass/fail table. It coordinates the stages in
order:
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md)
to prepare the data,
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md)
to classify the design and choose the model,
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md)
to fit,
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md)
to extract the parameters, and
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md)
to apply the regulatory decision.
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
and
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md)
are thin verbs over it.

## Usage

``` r
be_fit_models(
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

A data.frame with one row per endpoint and test formulation (the columns
described in
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)).

## See also

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md),
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md),
[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md),
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md),
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md),
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md),
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)
