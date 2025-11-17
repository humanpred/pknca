# Calculate the average concentration during an interval.

Calculate the average concentration during an interval.

## Usage

``` r
pk.calc.cav(auc, start, end)
```

## Arguments

- auc:

  The area under the curve during the interval

- start:

  The start time of the interval

- end:

  The end time of the interval

## Value

The Cav (average concentration during the interval)

## Details

cav is `auc/(end-start)`.
