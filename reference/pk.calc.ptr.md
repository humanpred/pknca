# Determine the peak-to-trough ratio

Determine the peak-to-trough ratio

## Usage

``` r
pk.calc.ptr(cmax, ctrough)
```

## Arguments

- cmax:

  The maximum observed concentration

- ctrough:

  The last concentration in an interval

## Value

The ratio of cmax to ctrough (if ctrough == 0, NA)

## Details

ptr is `cmax/ctrough`.
