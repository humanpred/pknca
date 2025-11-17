# Get the first model from a list of models

Get the first model from a list of models

## Usage

``` r
get.first.model(object)
```

## Arguments

- object:

  the list of (lists of, ...) models

## Value

The first item in the `object` that is not a list or `NA`. If `NA` is
passed in or the list (of lists) is all `NA`, then `NA` is returned.
