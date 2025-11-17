# Calculate amount excreted (typically in urine or feces)

Calculate amount excreted (typically in urine or feces)

## Usage

``` r
pk.calc.ae(conc, volume, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- volume:

  The volume (or mass) of the sample

- check:

  Should the concentration and volume data be checked?

## Value

The amount excreted during the interval

## Details

ae is `sum(conc*volume)`.

The units for the concentration and volume should match such that
`sum(conc*volume)` has units of mass or moles.

## See also

[`pk.calc.clr()`](http://humanpred.github.io/pknca/reference/pk.calc.clr.md),
[`pk.calc.fe()`](http://humanpred.github.io/pknca/reference/pk.calc.fe.md)
