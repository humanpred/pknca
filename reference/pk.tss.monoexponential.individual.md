# A helper function to estimate individual and single outputs for monoexponential time to steady-state.

This function is not intended to be called directly. Please use
`pk.tss.monoexponential`.

## Usage

``` r
pk.tss.monoexponential.individual(
  data,
  output = c("individual", "single"),
  verbose = FALSE
)
```

## Arguments

- data:

  a data frame as prepared by
  [`pk.tss.data.prep()`](http://humanpred.github.io/pknca/reference/pk.tss.data.prep.md).
  It must contain at least columns for `subject`, `time`, `conc`, and
  `tss.constant`.

- output:

  a character vector requesting the output types.

- verbose:

  Show verbose output.

## Value

A data frame with either one row (if `population` output is provided) or
one row per subject (if `popind` is provided). The columns will be named
`tss.monoexponential.population` and/or `tss.monoexponential.popind`.

## Details

If no model converges, then the `tss.monoexponential.single` and/or
`tss.monoexponential.individual` column will be set to NA.
