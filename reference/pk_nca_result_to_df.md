# Convert the grouping info and list of results for each group into a results data.frame

Convert the grouping info and list of results for each group into a
results data.frame

## Usage

``` r
pk_nca_result_to_df(group_info, result)
```

## Arguments

- group_info:

  A data.frame of grouping columns

- result:

  A list of data.frames with the results from NCA parameter calculations

## Value

A data.frame with group_info and result combined, warnings filtered out,
and results unnested.
