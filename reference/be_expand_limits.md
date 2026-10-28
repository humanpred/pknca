# Reference-scaled acceptance limits for bioequivalence

`be_expand_limits()` computes the (possibly widened) bioequivalence
acceptance limits for a scaled-ABE framework given the within-reference
standard deviation. The limits widen geometrically with `swR` as
`exp(+/- k * swR)` and are capped; below the switching variability they
remain the conventional 80.00-125.00%. They apply to the endpoints the
framework widens (Cmax for the EMA and GCC, AUC for Health Canada; see
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md)
for the sources);
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
keeps the other endpoints at 80.00-125.00%.

## Usage

``` r
be_expand_limits(swR, regulator)
```

## Arguments

- swR:

  The within-reference standard deviation of the log-transformed
  endpoint (for example from
  [`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)).

- regulator:

  A regulator name (see
  [`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md))
  or a `be_regulator` object. Only the ABEL frameworks (`"EMA"`, `"HC"`,
  `"GCC"`) widen; `"ABE"` always returns 80.00-125.00%, and
  `"descriptive"` (which has no limits) is an error.

## Value

A named numeric vector `c(lower, upper)` of acceptance limits as
percentages.

## See also

[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md),
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md),
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md),
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md),
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md),
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
[`be_regulator()`](https://humanpred.github.io/pknca/reference/be_regulator.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md),
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)

## Examples

``` r
be_expand_limits(0.485, "EMA") # capped expansion (69.84-143.19%)
#>     lower     upper 
#>  69.83678 143.19102 
be_expand_limits(0.20, "EMA")  # below the switch: 80-125%
#> lower upper 
#>    80   125 
be_expand_limits(0.60, "HC")   # Health Canada cap (66.7-150.0%)
#>     lower     upper 
#>  66.66666 150.00000 
```
