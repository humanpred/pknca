# Print and/or summarize a PKNCAconc or PKNCAdose object.

Print and/or summarize a PKNCAconc or PKNCAdose object.

## Usage

``` r
# S3 method for class 'PKNCAconc'
print(x, n = 6, summarize = FALSE, ...)

# S3 method for class 'PKNCAconc'
summary(object, n = 0, summarize = TRUE, ...)

# S3 method for class 'PKNCAdose'
print(x, n = 6, summarize = FALSE, ...)

# S3 method for class 'PKNCAdose'
summary(object, n = 0, summarize = TRUE, ...)
```

## Arguments

- x:

  The object to print

- n:

  The number of rows of data to show (see
  [`head()`](https://rdrr.io/r/utils/head.html))

- summarize:

  Summarize the nested number of groups

- ...:

  Arguments passed to `print.formula` and `print.data.frame`

- object:

  The object to summarize
