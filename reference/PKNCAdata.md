# Create a PKNCAdata object.

`PKNCAdata()` combines `PKNCAconc` and `PKNCAdose` objects and adds in
the intervals for PK calculations.

## Usage

``` r
PKNCAdata(data.conc, data.dose, ...)

# S3 method for class 'PKNCAconc'
PKNCAdata(data.conc, data.dose, ...)

# S3 method for class 'PKNCAdose'
PKNCAdata(data.conc, data.dose, ...)

# Default S3 method
PKNCAdata(
  data.conc,
  data.dose,
  ...,
  formula.conc,
  formula.dose,
  impute = NA_character_,
  intervals,
  units,
  options = list()
)
```

## Arguments

- data.conc:

  Concentration data as a `PKNCAconc` object or a data frame

- data.dose:

  Dosing data as a `PKNCAdose` object (see details)

- ...:

  arguments passed to `PKNCAdata.default`

- formula.conc:

  Formula for making a `PKNCAconc` object with `data.conc`. This must be
  given if `data.conc` is a data.frame, and it must not be given if
  `data.conc` is a `PKNCAconc` object.

- formula.dose:

  Formula for making a `PKNCAdose` object with `data.dose`. This must be
  given if `data.dose` is a data.frame, and it must not be given if
  `data.dose` is a `PKNCAdose` object.

- impute:

  Methods for imputation. `NA` for to search for the column named
  "impute" in the intervals or no imputation if that column does not
  exist, a comma-or space-separated list of names, or the name of a
  column in the `intervals` data.frame. See
  [`vignette("v08-data-imputation", package="PKNCA")`](http://humanpred.github.io/pknca/articles/v08-data-imputation.md)
  for more details.

- intervals:

  A data frame with the AUC interval specifications as defined in
  [`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md).
  If missing, this will be automatically chosen by
  [`choose.auc.intervals()`](http://humanpred.github.io/pknca/reference/choose.auc.intervals.md).
  (see details)

- units:

  A data.frame of unit assignments and conversions as created by
  [`pknca_units_table()`](http://humanpred.github.io/pknca/reference/pknca_units_table.md)

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

A PKNCAdata object with concentration, dose, interval, and calculation
options stored (note that PKNCAdata objects can also have results after
a NCA calculations are done to the data).

## Details

If `data.dose` is not given or is `NA`, then the `intervals` must be
given. At least one of `data.dose` and `intervals` must be given.

## See also

[`choose.auc.intervals()`](http://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`pk.nca()`](http://humanpred.github.io/pknca/reference/pk.nca.md),
[`pknca_units_table()`](http://humanpred.github.io/pknca/reference/pknca_units_table.md)

Other PKNCA objects:
[`PKNCAconc()`](http://humanpred.github.io/pknca/reference/PKNCAconc.md),
[`PKNCAdose()`](http://humanpred.github.io/pknca/reference/PKNCAdose.md),
[`PKNCAresults()`](http://humanpred.github.io/pknca/reference/PKNCAresults.md)
