# Find Minimal Grouping Columns for Strata Reconstruction

This function identifies the smallest set of columns in a data frame
whose unique combinations can reconstruct the grouping structure defined
by the specified strata columns. It removes duplicate, constant, and
redundant columns, then searches for the minimal combination that
uniquely identifies each stratum.

## Usage

``` r
select_minimal_grouping_cols(df, strata_cols)
```

## Arguments

- df:

  A data frame.

- strata_cols:

  Column names in df whose unique combination defines the strata.

## Value

A data frame containing the strata columns and their minimal set of
grouping columns.
