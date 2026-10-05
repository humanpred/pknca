# Check the hash of an object to confirm its provenance.

Check the hash of an object to confirm its provenance.

## Usage

``` r
checkProvenance(object)
```

## Arguments

- object:

  The object to check provenance for

## Value

`TRUE` if the provenance is confirmed to be consistent, `FALSE` if the
provenance is not consistent, or `NA` if provenance is not present. An
object that was modified after it was created by a PKNCA function that
marks provenance (for example
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html),
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
[`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md),
or
[`normalize()`](https://humanpred.github.io/pknca/reference/normalize.md)
on a `PKNCAresults` object) has a hash such as `"filtered from <hash>"`
instead of the original hash and always gives `FALSE`.

## See also

[`addProvenance()`](https://humanpred.github.io/pknca/reference/addProvenance.md)
