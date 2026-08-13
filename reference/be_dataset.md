# Build and validate a bioequivalence dataset

`be_dataset()` prepares a noncompartmental result for bioequivalence
calculation: it accepts a `PKNCAresults` object or a tidy long
data.frame, resolves the value column, drops excluded/invalid rows,
detects the subject/sequence/period columns, validates the reference,
and sets the reference formulation as the first factor level. It
standardizes the modeling columns (`.subject`, `.sequence`, `.period`,
`.trt`, `.logval`) used by the downstream fitters.

## Usage

``` r
be_dataset(
  object,
  reference_col,
  reference_value,
  endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
  subject = NULL,
  sequence = NULL,
  period = NULL
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

- subject, sequence, period:

  Column names for the subject, randomization sequence, and period. When
  `NULL` they are taken from the `PKNCAresults` object or detected from
  common column names. `sequence` may be absent.

## Value

An object of class `be_dataset`: a list with `data` (the standardized
long frame, including a `.units` column), `columns` (the resolved column
names, including `units`), `reference_value`, `test_levels`, and
`endpoints` (those present).

## Details

The endpoint value is taken from the `PPSTRES` column when present,
otherwise `PPORRES`. The measurement units are read from the matching
units column – `PPSTRESU` for `PPSTRES`, or `PPORRESU` for `PPORRES` –
which a `PKNCAresults` object provides automatically; a plain data.frame
supplies units the same way by including the corresponding
`PPSTRESU`/`PPORRESU` column. When no units column is present, units are
unavailable and the `units` column is omitted from the assessment table.

## See also

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md),
[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md),
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md),
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md),
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md),
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)
