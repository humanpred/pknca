# Calculate the terminal volume of distribution (Vz)

Calculate the terminal volume of distribution (Vz)

## Usage

``` r
pk.calc.vz(cl, lambda.z)

pk.calc.vss(cl, mrt)
```

## Arguments

- cl:

  the clearance (or apparent observed clearance)

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- mrt:

  the mean residence time

## Value

the volume of distribution at steady-state

## Details

vz is `cl/lambda.z`.

vss is `cl*mrt`.

## Functions

- `pk.calc.vss()`: Steady-state volume of distribution (Vss)

## See also

Other Clearance and volume parameters:
[`pk.calc.cl()`](http://humanpred.github.io/pknca/reference/pk.calc.cl.md),
[`pk.calc.kel()`](http://humanpred.github.io/pknca/reference/pk.calc.kel.md)
