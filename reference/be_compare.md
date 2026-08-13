# Compare a bioequivalence dataset across regulatory frameworks

`be_compare()` runs
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
under several regulatory frameworks and stacks the results, so the same
study can be judged side by side under the different reference-scaling
rules. Frameworks that the design does not support (for example NTID on
a partial replicate) are skipped with a warning.

## Usage

``` r
be_compare(
  object,
  reference_col,
  reference_value,
  endpoints = c("cmax", "aucinf.obs", "aucinf.pred", "auclast"),
  regulators = c("ABE", "EMA", "HC", "GCC", "FDA"),
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

- regulators:

  A character vector of regulatory frameworks to compare (see
  [`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md)).

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

An object of class `be_compare` (a data.frame) with the
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
columns for every endpoint, test formulation, and regulator.

## See also

[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
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
be_compare(d, reference_col = "treatment", reference_value = "R",
           endpoints = "auclast", regulators = c("EMA", "HC", "GCC", "FDA"))
#> Warning: Units were not found in the data; omitting the `units` column. Supply units via a PKNCAresults object or `PPSTRESU`/`PPORRESU` columns.
#> Bioequivalence comparison across EMA, HC, GCC, FDA (90% CI)
#> 
#>  regulator endpoint test gmr_percent ci_lower ci_upper cvwr_percent limit_lower
#>        EMA  auclast    T          98    85.72   112.04        34.11       77.71
#>         HC  auclast    T          98    85.72   112.04        34.11       77.71
#>        GCC  auclast    T          98    85.72   112.04        34.11       75.00
#>        FDA  auclast    T          98    85.75   112.00        34.11          NA
#>  limit_upper criterion pass
#>       128.68        NA TRUE
#>       128.68        NA TRUE
#>       133.33        NA TRUE
#>           NA  -0.05081 TRUE
```
