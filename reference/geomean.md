# Compute the geometric mean, sd, and CV

Compute the geometric mean, sd, and CV

## Usage

``` r
geomean(x, na.rm = FALSE)

geosd(x, na.rm = FALSE)

geocv(x, na.rm = FALSE)
```

## Arguments

- x:

  A vector to compute the geometric mean of

- na.rm:

  Should missing values be removed?

## Value

The scalar value of the geometric mean, geometric standard deviation, or
geometric coefficient of variation.

## Functions

- `geosd()`: Compute the geometric standard deviation,
  `exp(sd(log(x)))`.

- `geocv()`: Compute the geometric coefficient of variation,
  `sqrt(exp(sd(log(x))^2)-1)*100`.

## References

Kirkwood T. B.L. Geometric means and measures of dispersion. Biometrics
1979; 35: 908-909

## Examples

``` r
geomean(1:3)
#> [1] 1.817121
geosd(1:3)
#> [1] 1.742896
geocv(1:3)
#> [1] 60.13019
```
