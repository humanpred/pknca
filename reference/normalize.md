# Normalize parameters in a PKNCAresults object or data.frame

Normalize parameters in a PKNCAresults object or data.frame

## Usage

``` r
normalize(object, norm_table, parameters, suffix)
```

## Arguments

- object:

  A PKNCAresults object or result data.frame

- norm_table:

  data.frame with group columns, normalization values (`normalization`),
  and units (`unit`)

- parameters:

  character vector of parameter names to normalize

- suffix:

  character value to add for the normalized parameter names

## Value

A data.frame with normalized parameters
