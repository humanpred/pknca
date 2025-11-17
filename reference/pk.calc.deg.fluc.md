# Determine the degree of fluctuation

Determine the degree of fluctuation

## Usage

``` r
pk.calc.deg.fluc(cmax, cmin, cav)
```

## Arguments

- cmax:

  The maximum observed concentration

- cmin:

  The minimum observed concentration

- cav:

  The average concentration in the interval

## Value

The degree of fluctuation around the average concentration.

## Details

deg.fluc is `100*(cmax - cmin)/cav`.
