# Create a PKNCAdose object

Create a PKNCAdose object

## Usage

``` r
PKNCAdose(data, ...)

# Default S3 method
PKNCAdose(data, ...)

# S3 method for class 'tbl_df'
PKNCAdose(data, ...)

# S3 method for class 'data.frame'
PKNCAdose(
  data,
  formula,
  route,
  rate,
  duration,
  time.nominal,
  exclude = NULL,
  ...,
  doseu = NULL,
  doseu_pref = NULL
)
```

## Arguments

- data:

  A data frame with time and the groups defined in `formula`.

- ...:

  Ignored.

- formula:

  The formula defining the `dose.amount~time|groups` where `time` is the
  time of the dosing and `dose.amount` is the amount administered at
  that time (see Details).

- route:

  Define the route of administration. The value may be either a column
  name from the `data` (checked first) or a character string of either
  `"extravascular"` or `"intravascular"` (checked second). If given as a
  column name, then every value of the column must be either
  `"extravascular"` or `"intravascular"`.

- rate, duration:

  (optional) for `"intravascular"` dosing, the rate or duration of
  dosing. If given as a character string, it is the name of a column
  from the `data`, and if given as a number, it is the value for all
  doses. Only one may be given, and if neither is given, then the dose
  is assumed to be a bolus (`duration=0`). If `rate` is given, then the
  dose amount must be given (the left hand side of the `formula`).

- time.nominal:

  (optional) The name of the nominal time column (if the main time
  variable is actual time. The `time.nominal` is not used during
  calculations; it is available to assist with data summary and
  checking.

- exclude:

  (optional) The name of a column with concentrations to exclude from
  calculations and summarization. If given, the column should have
  values of `NA` or `""` for concentrations to include and non-empty
  text for concentrations to exclude.

- doseu:

  Either unit values (e.g. "mg") or column names within the data where
  units are provided.

- doseu_pref:

  Preferred units for reporting (not column names)

## Value

A PKNCAconc object that can be used for automated NCA.

## Details

The `formula` for a `PKNCAdose` object can be given three ways:
one-sided (missing left side), one-sided (missing right side), or
two-sided. Each of the three ways can be given with or without groups.
When given one-sided missing the left side, the left side can either be
omitted or can be given as a period (`.`): `~time|treatment+subject` and
`.~time|treatment+subject` are identical, and dose-related NCA
parameters will all be reported as not calculable (for example,
clearance). When given one-sided missing the right side, the right side
must be specified as a period (`.`): `dose~.|treatment+subject`, and
only a single row may be given per group. When the right side is
missing, PKNCA assumes that the same dose is given in every interval.
When given as a two-sided formula

## See also

Other PKNCA objects:
[`PKNCAconc()`](http://humanpred.github.io/pknca/reference/PKNCAconc.md),
[`PKNCAdata()`](http://humanpred.github.io/pknca/reference/PKNCAdata.md),
[`PKNCAresults()`](http://humanpred.github.io/pknca/reference/PKNCAresults.md)
