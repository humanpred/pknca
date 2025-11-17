# Separate out a vector of PKNCA imputation methods into a list of functions

An error will be raised if the functions are not found.

## Usage

``` r
PKNCA_impute_fun_list(x)
```

## Arguments

- x:

  The character vector of PKNCA imputation method functions (without the
  `PKNCA_impute_method_` part)

## Value

A list of character vectors of functions to run.

## Details

This function is not for use by users of PKNCA.
