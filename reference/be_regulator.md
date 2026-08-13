# Regulatory framework constants for bioequivalence assessment

`be_regulator()` returns the scaling type, switching and capping rules,
and regulatory constants that define a bioequivalence (BE) assessment
framework. It is the single source of truth for these values:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
and the internal decision functions pull every constant from here rather
than hard-coding it.

## Usage

``` r
be_regulator(name = c("ABE", "EMA", "HC", "GCC", "FDA", "NTID", "HVNTID"))
```

## Arguments

- name:

  The regulatory framework, one of `"ABE"`, `"EMA"`, `"HC"`, `"GCC"`,
  `"FDA"`, `"NTID"`, or `"HVNTID"`.

## Value

An object of class `be_regulator`: a list with elements `name`,
`scaling` (one of `"none"`, `"abel"`, `"rsabe"`, `"ntid"`, `"hvntid"`),
`cvswitch`, `r_const`, `cvcap`, `switch_swr`, `pe_constr`, `est_method`
(`"anova"` or `"isc"`), and `switch_basis`.

## Details

The supported frameworks and their constants are:

- **ABE** – average bioequivalence; the universal unscaled criterion
  that the 90% confidence interval fall within 80.00-125.00%. No
  reference scaling.

- **EMA** – average bioequivalence with expanding limits (ABEL). Scaling
  begins when the within-reference coefficient of variation (`CVwR`)
  exceeds 30% (`cvswitch = 0.30`); the limits widen as
  `exp(+/- k * swR)` with the regulatory constant `k = 0.76` and the
  expansion is capped at `CVwR = 50%` (limits 69.84-143.19%). The
  constant 0.76 is `log(1.25) / sqrt(log(1 + 0.30^2))` rounded to two
  decimals, as fixed by the EMA bioequivalence guideline.

- **HC** – Health Canada; ABEL with the same `k = 0.76` but the
  expansion is capped at `CVwR = 57.382%` (upper limit 150%).

- **GCC** – Gulf Cooperation Council; fixed widened limits of
  75.00-133.33% whenever `CVwR > 30%` (not CV-dependent).

- **FDA** – reference-scaled average bioequivalence (RSABE). The
  linearized (Howe/Hyslop) criterion uses
  `r_const = log(1.25) / 0.25 = 0.8926` (`theta = r_const^2`) and
  switches from unscaled ABE when `swR >= 0.294` (`CVwR` of about 30%).

- **NTID** – FDA narrow therapeutic index drugs; uses
  `r_const = -log(0.9) / 0.1 = 1.0536` and always applies the scaled
  criterion (a fully replicated design is required).

- **HVNTID** – FDA highly variable narrow therapeutic index drugs; the
  RSABE-style scaled criterion with the NTID constant and the
  within-subject standard deviation ratio constraint.

All frameworks additionally impose the point-estimate constraint that
the geometric mean ratio fall within 80.00-125.00%.

## See also

[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md)
for the ABEL acceptance limits and
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
for the full assessment.

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md),
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md),
[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md),
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md),
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md),
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md),
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)

## Examples

``` r
be_regulator("EMA")
#> Bioequivalence regulator: EMA
#>   Scaling:            abel
#>   CV switch:          30%
#>   Regulatory const.:  0.76
#>   CV cap:             50%
#>   PE constraint:      80.00-125.00%
#>   Point estimate:     anova
be_regulator("FDA")
#> Bioequivalence regulator: FDA
#>   Scaling:            rsabe
#>   CV switch:          30%
#>   swR switch:         0.294
#>   Regulatory const.:  0.8925742
#>   PE constraint:      80.00-125.00%
#>   Point estimate:     isc
```
