# List the automatic NCA result exclusion rules

Every `exclude_nca_*()` rule is registered with its description and the
descriptions of its arguments. Its arguments and their defaults come
from the factory function, and the parameters it can exclude and the
[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md)
entries it uses come from the exclusion function that the factory
returns when called with its defaults (an argument without a default
falls back to its option, as it does in use).

## Usage

``` r
pknca_exclude_rules()
```

## Value

A tibble with one row per rule and the columns:

- rule:

  The function name (for example, `"exclude_nca_span.ratio"`)

- description:

  The one-line description

- arguments:

  A list column of data.frames with one row per argument and the columns
  `argument`, `default` (the deparsed default, or `NA` when there is
  none), and `description`

- callable_with_defaults:

  Can the rule be created without giving any arguments?

- options:

  A list column of the
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md)
  names that the rule uses when created with its defaults, or `NULL`
  when it cannot be

- affected_parameters:

  A list column of the NCA parameters that the rule, created with its
  defaults, can exclude, or `NULL` when it cannot be created without
  arguments

## Rules

|  |  |  |
|----|----|----|
| Rule | Description | PKNCA.options() used |
| [`exclude_nca_by_param()`](https://humanpred.github.io/pknca/reference/exclude_nca_by_param.md) | Exclude based on NCA parameter thresholds | (set by its arguments) |
| [`exclude_nca_count_conc_measured()`](https://humanpred.github.io/pknca/reference/exclude_nca.md) | Exclude based on the count of concentrations measured and not below the lower limit of quantification (affects AUC and AUMC parameters) | (set by its arguments) |
| [`exclude_nca_max.aucinf.pext()`](https://humanpred.github.io/pknca/reference/exclude_nca.md) | Exclude based on the percent of AUC extrapolated to infinity (both observed and predicted) | `max.aucinf.pext` |
| [`exclude_nca_min.hl.adj.r.squared()`](https://humanpred.github.io/pknca/reference/exclude_nca.md) | Exclude based on half-life adjusted r-squared | (none) |
| [`exclude_nca_min.hl.r.squared()`](https://humanpred.github.io/pknca/reference/exclude_nca.md) | Exclude based on half-life r-squared | `min.hl.r.squared` |
| [`exclude_nca_span.ratio()`](https://humanpred.github.io/pknca/reference/exclude_nca.md) | Exclude based on the half-life span ratio | `min.span.ratio` |
| [`exclude_nca_tmax_0()`](https://humanpred.github.io/pknca/reference/exclude_nca.md) | Exclude based on implausibly early Tmax (special case for tmax_early = 0) | (none) |
| [`exclude_nca_tmax_early()`](https://humanpred.github.io/pknca/reference/exclude_nca.md) | Exclude based on implausibly early Tmax (often used for extravascular dosing with a Tmax value of 0) | (none) |

## See also

[exclude_nca](https://humanpred.github.io/pknca/reference/exclude_nca.md),
[`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md)

Other Result exclusions:
[`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md),
[`exclude_nca`](https://humanpred.github.io/pknca/reference/exclude_nca.md)

## Examples

``` r
rules <- pknca_exclude_rules()
rules[, c("rule", "description")]
#> # A tibble: 8 × 2
#>   rule                             description                                  
#>   <chr>                            <chr>                                        
#> 1 exclude_nca_by_param             Exclude based on NCA parameter thresholds    
#> 2 exclude_nca_count_conc_measured  Exclude based on the count of concentrations…
#> 3 exclude_nca_max.aucinf.pext      Exclude based on the percent of AUC extrapol…
#> 4 exclude_nca_min.hl.adj.r.squared Exclude based on half-life adjusted r-squared
#> 5 exclude_nca_min.hl.r.squared     Exclude based on half-life r-squared         
#> 6 exclude_nca_span.ratio           Exclude based on the half-life span ratio    
#> 7 exclude_nca_tmax_0               Exclude based on implausibly early Tmax (spe…
#> 8 exclude_nca_tmax_early           Exclude based on implausibly early Tmax (oft…
```
