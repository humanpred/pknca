# Reference-scaled acceptance limits for bioequivalence

`be_expand_limits()` computes the (possibly widened) bioequivalence
acceptance limits for a scaled-ABE framework given the within-reference
standard deviation. For EMA and Health Canada the limits widen
geometrically with `swR` and are capped; for the GCC they jump to a
fixed wider band; below the switching variability they remain the
conventional 80.00-125.00%.

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
  `"GCC"`) widen; `"ABE"` always returns 80.00-125.00%.

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
be_expand_limits(0.485, "EMA") # capped expansion
#>     lower     upper 
#>  69.83678 143.19102 
be_expand_limits(0.20, "EMA")  # below the switch: 80-125%
#> lower upper 
#>    80   125 
be_expand_limits(0.40, "GCC")  # fixed GCC band
#>    lower    upper 
#>  75.0000 133.3333 
```
