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
be_dataset(object, ...)

# Default S3 method
be_dataset(
  object,
  reference_col,
  reference_value,
  endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
  subject = NULL,
  sequence = NULL,
  period = NULL,
  covariates = NULL,
  ...
)

# S3 method for class 'PKNCAresults_sparse_bootstrap'
be_dataset(
  object,
  reference_col,
  reference_value,
  endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
  subject = NULL,
  sequence = NULL,
  period = NULL,
  covariates = NULL,
  ...
)
```

## Arguments

- object:

  A `PKNCAresults` object or a tidy long data.frame with a `PPTESTCD`
  column of parameter names, a `PPORRES`/`PPSTRES` column of values, and
  subject/sequence/period/treatment columns. The results of a sparse
  bootstrap (from a `PKNCAconc` object made by
  [`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md))
  are compared with the percentile intervals of the bootstrap replicates
  (Shen and Machado 2017); see Details.

- ...:

  Arguments passed to the methods

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

- covariates:

  An optional character vector of column names added to every model as
  additive fixed effects (numeric columns as linear terms, character or
  factor columns as factors). They must not be missing in any analyzed
  row. For a `PKNCAresults` object they must be columns of
  `as.data.frame(object)`, which means grouping columns. The
  within-subject variances used for reference scaling and the
  intra-subject contrasts do not use covariates.

## Value

An object of class `be_dataset`: a list with `data` (the standardized
long frame, including a `.units` column and one `.cov_<name>` column per
covariate), `columns` (the resolved column names, including `units` and
`covariates`), `reference_value`, `test_levels`, and `endpoints` (those
present). For the results of a sparse bootstrap (see
[`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md)),
`data` has one row per bootstrap replicate, group, and endpoint instead
of one per subject and period.

## Details

The endpoint value is taken from the `PPSTRES` column when present,
otherwise `PPORRES`. The measurement units are read from the matching
units column – `PPSTRESU` for `PPSTRES`, or `PPORRESU` for `PPORRES` –
which a `PKNCAresults` object provides automatically; a plain data.frame
supplies units the same way by including the corresponding
`PPSTRESU`/`PPORRESU` column. When no units column is present, units are
unavailable and the `units` column is omitted from the assessment table.

Each covariate is copied to a standardized column named `.cov_<name>`
(character columns become factors). A covariate may not be one of the
subject, sequence, period, treatment, or value columns, and it may not
be missing in any row that is analyzed.

## Methods (by class)

- `be_dataset(PKNCAresults_sparse_bootstrap)`: The replicates of a
  sparse bootstrap, one row per replicate, treatment, and endpoint

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
