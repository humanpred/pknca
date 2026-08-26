# Choose intervals to compute AUCs from time and dosing information

Intervals for AUC are selected by the following metrics:

1.  If only one dose is administered, use the
    `PKNCA.options("single.dose.aucs")`

2.  If more than one dose is administered, estimate the AUC between any
    two doses that have PK taken at both of the dosing times and at
    least one time between the doses.

3.  For the final dose of multiple doses, try to determine the dosing
    interval (\\\tau\\) and estimate the AUC in that interval if
    multiple samples are taken in the interval.

4.  If there are samples \\\> \tau\\ after the last dose, calculate the
    half life after the last dose.

## Usage

``` r
choose.auc.intervals(
  time.conc,
  time.dosing,
  options = list(),
  single.dose.aucs = NULL
)
```

## Arguments

- time.conc:

  Time of concentration measurement

- time.dosing:

  Time of dosing

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- single.dose.aucs:

  The AUC specification for single dosing.

## Value

A data frame with columns for `start`, `end`, `auc.type`, and
`half.life`. See
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md)
for column definitions. The data frame may have zero rows if no
intervals could be found.

## See also

[`pk.calc.auc()`](https://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.aumc()`](https://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.half.life()`](https://humanpred.github.io/pknca/reference/pk.calc.half.life.md),
[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md)

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md)

Other Interval determination:
[`find.tau()`](https://humanpred.github.io/pknca/reference/find.tau.md),
[`resolve_dose_tau()`](https://humanpred.github.io/pknca/reference/resolve_dose_tau.md)
