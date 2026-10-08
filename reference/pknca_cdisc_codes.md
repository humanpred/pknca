# Every registered CDISC PPTESTCD/PPTEST code, with CT membership

Enumerates the `pptestcd_cdisc`/`pptest_cdisc` values registered on
every NCA parameter (see
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md)
and
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md)),
expanding a route- or sparse-keyed mapping into one row per variant, and
flags whether each code is a real CDISC PKPARMCD term. Generated from
the registry at call time; never hand-written, so it always reflects the
parameters actually registered (including by another package).

## Usage

``` r
pknca_cdisc_codes()
```

## Value

A data.frame with one row per parameter/variant and columns `parameter`,
`tier`, `variant` (`"single"`, a route, or `"dense"`/ `"sparse"`),
`pptestcd_cdisc`, `pptest_cdisc`, and `in_ct` (whether `pptestcd_cdisc`
is a code in the CDISC PKPARMCD codelist, checked against the installed
cdiscdata package; `NA` for every row, with a message, if cdiscdata is
not installed).

## Details

A parameter with no CDISC PKPARMCD equivalent (for example a sample
count or a standard error, neither of which CDISC assigns its own PP
parameter code) keeps a sponsor-defined code with `in_ct` `FALSE`; that
is expected for some `"uncommon"` tier parameters and, for a few
documented exceptions, for `"common"` tier ones as well (see the
comments at their
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md)
registrations).

## See also

[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
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
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_match_route()`](https://humanpred.github.io/pknca/reference/pknca_match_route.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)

## Examples

``` r
head(pknca_cdisc_codes())
#>    parameter     tier variant pptestcd_cdisc                      pptest_cdisc
#> 1    auclast   common  single         AUCLST          AUC to Last Nonzero Conc
#> 2 auclast_se uncommon  single       SPARSEAS     Sparse AUClast standard error
#> 3 auclast_df uncommon  single       SPARSEAD Sparse AUClast degrees of freedom
#> 4     aucall uncommon  single         AUCALL                           AUC All
#> 5  aucall_se uncommon  single       AUCALLSE      Sparse AUCall standard error
#> 6  aucall_df uncommon  single       AUCALLDF  Sparse AUCall degrees of freedom
#>   in_ct
#> 1  TRUE
#> 2 FALSE
#> 3 FALSE
#> 4  TRUE
#> 5 FALSE
#> 6 FALSE
```
