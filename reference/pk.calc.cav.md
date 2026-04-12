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

## See also

Other NCA parameters for concentrations during the intervals:
[`pk.calc.c0()`](http://humanpred.github.io/pknca/reference/pk.calc.c0.md),
[`pk.calc.ceoi()`](http://humanpred.github.io/pknca/reference/pk.calc.ceoi.md),
[`pk.calc.clast.obs()`](http://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.cmax()`](http://humanpred.github.io/pknca/reference/pk.calc.cmax.md),
[`pk.calc.count_conc()`](http://humanpred.github.io/pknca/reference/pk.calc.count_conc.md),
[`pk.calc.ctrough()`](http://humanpred.github.io/pknca/reference/pk.calc.ctrough.md)
