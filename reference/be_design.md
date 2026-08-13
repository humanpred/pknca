# Classify a bioequivalence crossover design

`be_design()` inspects the treatment-by-period pattern of a crossover
study and reports the design type, the replication of the reference and
test formulations, and which regulatory frameworks are feasible.
Reference scaling (EMA/HC/GCC/FDA) requires the reference to be
replicated; the narrow therapeutic index frameworks additionally require
the test to be replicated.

## Usage

``` r
be_design(data, subject, sequence, period, treatment, reference_value)
```

## Arguments

- data:

  A long data.frame with one row per concentration-derived observation
  (subject, period, treatment).

- subject, sequence, period, treatment:

  Column names (length-1 character) identifying the subject,
  randomization sequence, period, and treatment. `sequence` may be `NA`
  to derive it from the treatment-by-period pattern.

- reference_value:

  The value of `treatment` that is the reference formulation.

## Value

An object of class `be_design`: a list with elements `design` (one of
`"parallel"`, `"2x2x2"`, `"full_replicate"`, `"partial_replicate"`,
`"other"`), `n_sequences`, `n_periods`, `n_treatments`, `n_subjects`,
`sequences`, `treatments`, `reference`, `replicate_reference`,
`replicate_test`, `reps_reference`, `reps_test`, `balanced`, and
`feasible` (a named logical vector for `abe`, `abel`, `rsabe`, `ntid`,
`hvntid`).

## See also

[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md),
[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md),
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md),
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md),
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md),
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)

## Examples

``` r
d <- data.frame(
  subject = rep(1:4, each = 4),
  period = rep(1:4, times = 4),
  sequence = rep(c("TRTR", "RTRT"), each = 8),
  treatment = c("T", "R", "T", "R", "R", "T", "R", "T",
                "T", "R", "T", "R", "R", "T", "R", "T")
)
be_design(d, "subject", "sequence", "period", "treatment", reference_value = "R")
#> Bioequivalence design: full_replicate
#>   2 sequence(s) (RTRT, TRTR), 4 period(s), 2 treatment(s), 4 subject(s), balanced
#>   Reference "R" replicated: TRUE (2/subject); test replicated: TRUE (2/subject)
#>   Feasible frameworks: ABE, ABEL, RSABE, NTID, HVNTID
```
