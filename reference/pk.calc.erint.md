# Calculate the excretion rate over the interval

Calculate the excretion rate over the interval

## Usage

``` r
pk.calc.erint(ae, start, end)
```

## Arguments

- ae:

  The amount excreted during the interval (see
  [`pk.calc.ae()`](https://humanpred.github.io/pknca/reference/pk.calc.ae.md))

- start:

  The start time of the interval

- end:

  The end time of the interval

## Value

The excretion rate during the interval

## Details

The excretion rate is the amount recovered during the interval divided
by the duration of the interval, `ae/(end - start)`. It uses the
interval rather than the sum of the collection durations, so a gap
between collections lowers the rate. An interval ending at infinity has
no duration to divide by and gives `NA`.

## See also

[`pk.calc.ae()`](https://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.ermax()`](https://humanpred.github.io/pknca/reference/pk.calc.ermax.md)

Other Urine/Excretion parameters:
[`pk.calc.ae()`](https://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.clr()`](https://humanpred.github.io/pknca/reference/pk.calc.clr.md),
[`pk.calc.erlst()`](https://humanpred.github.io/pknca/reference/pk.calc.erlst.md),
[`pk.calc.ermax()`](https://humanpred.github.io/pknca/reference/pk.calc.ermax.md),
[`pk.calc.ertlst()`](https://humanpred.github.io/pknca/reference/pk.calc.ertlst.md),
[`pk.calc.ertmax()`](https://humanpred.github.io/pknca/reference/pk.calc.ertmax.md),
[`pk.calc.fe()`](https://humanpred.github.io/pknca/reference/pk.calc.fe.md),
[`pk.calc.volpk()`](https://humanpred.github.io/pknca/reference/pk.calc.volpk.md)
