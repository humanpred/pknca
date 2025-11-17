# Generate a PKNCAresults object

This function should not be run directly. The object is created for
summarization.

## Usage

``` r
PKNCAresults(result, data, exclude = NULL)
```

## Arguments

- result:

  a data frame with NCA calculation results and groups. Each row is one
  interval and each column is a group name or the name of an NCA
  parameter.

- data:

  The PKNCAdata used to generate the result

- exclude:

  (optional) The name of a column with concentrations to exclude from
  calculations and summarization. If given, the column should have
  values of `NA` or `""` for concentrations to include and non-empty
  text for concentrations to exclude.

## Value

A PKNCAresults object with each of the above within.

## See also

Other PKNCA objects:
[`PKNCAconc()`](http://humanpred.github.io/pknca/reference/PKNCAconc.md),
[`PKNCAdata()`](http://humanpred.github.io/pknca/reference/PKNCAdata.md),
[`PKNCAdose()`](http://humanpred.github.io/pknca/reference/PKNCAdose.md)
