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
  options = list(),
  group_ref = NULL
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
  [`vignette("v08-data-imputation", package="PKNCA")`](https://humanpred.github.io/pknca/articles/v08-data-imputation.md)
  for more details.

- intervals:

  A data frame with the AUC interval specifications as defined in
  [`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md).
  If missing, this will be automatically chosen by
  [`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md).
  (see details)

- units:

  A data.frame of unit assignments and conversions as created by
  [`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md)

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- group_ref:

  The reference profiles for automatically-linked secondary parameters,
  as a data.frame of group values, optionally parameter-specific (see
  Details). `NULL` (the default) derives the reference from the data.

## Value

A PKNCAdata object with concentration, dose, interval, and calculation
options stored (note that PKNCAdata objects can also have results after
a NCA calculations are done to the data).

## Details

If `data.dose` is not given or is `NA`, then the `intervals` must be
given. At least one of `data.dose` and `intervals` must be given.

A secondary parameter is calculated from a result in another interval,
and the interval specification links the two with an `interval_id`
column and a `<parameter>_ref` pointer (see
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md)).
Where a request has no pointer and could not otherwise be calculated,
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
derives the reference profile from the data: a parameter measured on an
interval collection whose inputs are spot samples (renal clearance)
takes the nearest profile with no collection volume, and `group_ref`
restricts – or, for anything else, supplies – the profiles that may be
used. The derived reference interval is created for the calculation only
and is not added to the intervals in the result. When more than one
profile is equally close, the affected results are `NA` with the reason
in the `exclude` column and a `pknca_warning_secondary_auto_reference`
warning.

`group_ref` takes three forms. A data.frame of group values applies to
every secondary parameter: its columns must be group columns of the
concentration data, every column must match (and) for at least one of
its rows (or), and every value must appear in the data – for example,
with groups crossing `TRTP`, `PCTEST`, and `PCSPEC`,
`group_ref = data.frame(PCSPEC = "PLASMA")` directs renal-clearance
references to the plasma profiles and
`group_ref = data.frame(PCTEST = "midazolam")` directs metabolite ratios
to the parent analyte. The same data.frame with a `parameter` column
applies each row only to the secondary parameter it names, and the
columns a parameter's rows leave `NA` do not apply to it, so one table
can steer renal clearance by `PCSPEC` and a metabolite ratio by
`PCTEST`:
`group_ref = data.frame(parameter = c("clr.obs", "ratio.aucinf.obs"), PCSPEC = c("PLASMA", NA), PCTEST = c(NA, "midazolam"))`.
A named list of data.frames, one per parameter, says the same thing:
`group_ref = list(clr.obs = data.frame(PCSPEC = "PLASMA"), ratio.aucinf.obs = data.frame(PCTEST = "midazolam"))`.

## See also

[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md),
[`pknca_units_table()`](https://humanpred.github.io/pknca/reference/pknca_units_table.md)

Other PKNCA objects:
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md),
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md),
[`PKNCAresults()`](https://humanpred.github.io/pknca/reference/PKNCAresults.md)
