# Determine the PK swing

Determine the PK swing

## Usage

``` r
pk.calc.swing(cmax, cmin)
```

## Arguments

- cmax:

  The maximum observed concentration

- cmin:

  The minimum observed concentration

## Value

The swing above the minimum concentration. If `cmin` is zero, then the
result is infinity.

## Details

swing is `100*(cmax - cmin)/cmin`.
