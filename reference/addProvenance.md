# Add a hash and associated information to enable checking object provenance.

Add a hash and associated information to enable checking object
provenance.

## Usage

``` r
addProvenance(object, replace = FALSE)
```

## Arguments

- object:

  The object to add provenance

- replace:

  Replace provenance if the object already has a provenance attribute.
  (If the object already has provenance and `replace` is `FALSE`, then
  an error will be raised.)

## Value

The object with provenance as an added item

## See also

[`checkProvenance()`](http://humanpred.github.io/pknca/reference/checkProvenance.md)
