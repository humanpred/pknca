# Build the regulatory bioequivalence table

`be_table()` takes the parameters from
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md)
and a regulatory framework and produces the final per-endpoint pass/fail
table. It selects the regulator-appropriate statistic (the model
contrast for the expanding-limits frameworks; for the FDA family,
intra-subject contrasts for the reference-scaled criterion and the model
contrast for the unscaled 80.00-125.00% criterion) and calls the
per-framework decision functions; it is the only place regulator
decisions are made. Each row shows the ratio and confidence interval
that its decision used. The expanding-limits frameworks decide each
endpoint by its own rule (see
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md));
an endpoint that is neither a PKNCA parameter nor a CDISC code cannot be
classified, so it keeps 80.00-125.00% with a warning unless it is named
in `widen_endpoints`.

## Usage

``` r
be_table(
  params,
  regulator,
  alpha = 0.1,
  design = NA_character_,
  model_type = NA_character_,
  widen_endpoints = NULL,
  widen_default = TRUE
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

- widen_endpoints:

  For the expanding-limits frameworks (`"EMA"`, `"HC"`, and `"GCC"`),
  endpoints whose acceptance limits widen in addition to the framework's
  own choice (the endpoints judged like Cmax for the EMA and GCC, like
  AUC for Health Canada; see
  [`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md)).
  Use it for an endpoint that the guidance widens but PKNCA cannot
  recognize from its name, such as a partial AUC of a modified-release
  product (EMA), or an endpoint that is neither a PKNCA parameter nor a
  CDISC code. Naming an endpoint for another framework is an error;
  [`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md)
  passes it to the expanding-limits frameworks only, and each adds it to
  its own choice.

- widen_default:

  For the expanding-limits frameworks, whether the framework's own
  choice of endpoints widens (the default, `TRUE`). With `FALSE` only
  the endpoints in `widen_endpoints` widen, for example none when the
  protocol did not specify widening in advance; Health Canada still
  judges Cmax by its point estimate. `FALSE` for another framework is an
  error;
  [`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md)
  applies it to the expanding-limits frameworks only.

## Value

A data.frame with one row per endpoint and test formulation and the
pass/fail decision columns, including `rule`, the criterion each row's
decision used. For the `"descriptive"` framework the decision columns
(`rule`, `limit_lower`, `limit_upper`, `criterion`, and `pass`) are
omitted.

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
