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
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- single.dose.aucs:

  The AUC specification for single dosing.

## Value

A data frame with columns for `start`, `end`, `auc.type`, and
`half.life`. See
[`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md)
for column definitions. The data frame may have zero rows if no
intervals could be found.

## See also

[`pk.calc.auc()`](http://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.aumc()`](http://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.half.life()`](http://humanpred.github.io/pknca/reference/pk.calc.half.life.md),
[`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md)

Other Interval specifications:
[`add.interval.col()`](http://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.deps()`](http://humanpred.github.io/pknca/reference/check.interval.deps.md),
[`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`get.interval.cols()`](http://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](http://humanpred.github.io/pknca/reference/get.parameter.deps.md)

Other Interval determination:
[`find.tau()`](http://humanpred.github.io/pknca/reference/find.tau.md)
