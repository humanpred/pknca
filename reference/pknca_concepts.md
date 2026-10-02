# Concepts, tiers, and contexts used to classify NCA parameters

Concepts, tiers, and contexts used to classify NCA parameters

## Usage

``` r
pknca_concepts()

pknca_tiers()

pknca_routes(synonyms = FALSE)

pknca_dosing()

pknca_sample_types()
```

## Arguments

- synonyms:

  If `TRUE`, `pknca_routes()` returns the table of spellings that data
  may use for a route instead of the route names (see Route synonyms).

## Value

`pknca_concepts()` gives the concept names PKNCA uses, `pknca_tiers()`
the reporting tiers, `pknca_routes()` the routes of administration,
`pknca_dosing()` the dosing patterns, and `pknca_sample_types()` the
sample collection types.

## Details

A `tier` of `"common"` marks a parameter that belongs in a default
report for at least one context; `"uncommon"` marks one that is
calculated only when asked for by name. `"uncommon"` is the default, so
a parameter registered without a tier is never selected automatically.

## Route synonyms

`pknca_routes(synonyms = TRUE)` returns a data.frame with one row per
spelling and the columns

- `synonym`: The spelling, in lower case with single spaces, as it may
  appear in data (for example `"po"`, `"intravenous bolus"`). It
  includes the common abbreviations and the CDISC SDTM `ROUTE`
  controlled terminology terms that are extravascular or intravascular
  routes.

- `route`: One of `pknca_routes()`, or `"iv"` when the spelling is
  intravascular but does not say which intravascular route it is (for
  example `"intravenous"` does not say bolus or infusion). `"iv"` is not
  a value of `pknca_routes()` without `synonyms`, because PKNCA cannot
  calculate with a route that does not say how the drug entered.

- `dose_route`: `"extravascular"` or `"intravascular"`, the values that
  [`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
  accepts for `route`.

[`pknca_match_route()`](https://humanpred.github.io/pknca/reference/pknca_match_route.md)
looks spellings up in this table.

## See also

[`pknca_concept()`](https://humanpred.github.io/pknca/reference/pknca_concept.md),
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md)

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md),
[`pknca_cdisc_codes()`](https://humanpred.github.io/pknca/reference/pknca_cdisc_codes.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_match_route()`](https://humanpred.github.io/pknca/reference/pknca_match_route.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)

## Examples

``` r
pknca_concepts()
#>  [1] "auc"                 "aumc"                "auc_above_conc"     
#>  [4] "auc_extrapolation"   "peak_conc"           "min_conc"           
#>  [7] "last_conc"           "average_conc"        "trough_conc"        
#> [10] "start_conc"          "initial_conc"        "eoi_conc"           
#> [13] "peak_time"           "min_time"            "last_time"          
#> [16] "first_time"          "lag_time"            "time_above_conc"    
#> [19] "clearance"           "renal_clearance"     "volume_z"           
#> [22] "volume_ss"           "mrt"                 "half_life"          
#> [25] "effective_half_life" "elimination_rate"    "fluctuation"        
#> [28] "excreted_amount"     "excreted_fraction"   "excretion_rate"     
#> [31] "collected_volume"    "bioavailability"     "total_dose"         
#> [34] "observation_count"   "parameter_ratio"    
```
