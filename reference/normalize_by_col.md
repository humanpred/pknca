# Internal function to normalize by a specified column

Internal function to normalize by a specified column

## Usage

``` r
normalize_by_col(object, col, unit, parameters, suffix)
```

## Arguments

- object:

  A PKNCAresults object

- col:

  The column name from PKNCAconc to use for the normalization groups

- unit:

  The unit of the previous column for normalization. Can be a column
  name in PKNCAconc or a single value.

- parameters:

  Character vector of parameter names to normalize

- suffix:

  Suffix to add to the normalized parameter code names

## Value

A data.frame with normalized parameters
