# Extract the parameter results from a PKNCAresults and return them as a data.frame.

Extract the parameter results from a PKNCAresults and return them as a
data.frame.

## Usage

``` r
# S3 method for class 'PKNCAresults'
as.data.frame(
  x,
  ...,
  out_format = c("long", "wide"),
  filter_requested = FALSE,
  filter_excluded = FALSE,
  out.format = deprecated()
)
```

## Arguments

- x:

  The object to extract results from

- ...:

  Ignored (for compatibility with generic
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html))

- out_format:

  Should the output be 'long' (default) or 'wide'?

- filter_requested:

  Only return rows with parameters that were specifically requested?

- filter_excluded:

  Should excluded values be removed?

- out.format:

  Deprecated in favor of `out_format`

## Value

A data.frame (or usually a tibble) of results
