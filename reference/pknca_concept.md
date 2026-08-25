# The concept a parameter calculation function computes

The concept is the kind of quantity a user asks for – "clearance" rather
than the fifteen registered clearance parameters. It is stored as an
attribute on the calculation function so that it sits with the code that
computes it, and so that a parameter added by another package can carry
one too.

## Usage

``` r
pknca_concept(x)

pknca_concept(x) <- value
```

## Arguments

- x:

  A parameter calculation function (for example `pk.calc.cmax`).

- value:

  A concept name; see
  [`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md)
  for the ones PKNCA uses.

## Value

`pknca_concept()` gives the concept, or `NULL` when none is set. The
replacement form gives the function with the attribute set.

## Details

A function that computes different concepts depending on which parameter
it is registered for –
[`pk.calc.dn()`](https://humanpred.github.io/pknca/reference/pk.calc.dn.md)
is the example within PKNCA – should have no concept. Those parameters
take the concept of the parameter they depend on. When neither applies,
set the concept for the individual parameter with the `selection`
argument of
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md).

## See also

[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
and the vignette "Writing Parameter Functions"

## Examples

``` r
pknca_concept(pk.calc.cmax)
#> [1] "peak_conc"
```
