# Calculate the last measurable excretion rate

Calculate the last measurable excretion rate

## Usage

``` r
pk.calc.erlst(conc, volume, time, duration.conc, check = TRUE)
```

## Arguments

- conc:

  The concentration in the excreta (e.g., urine or feces)

- volume:

  The volume (or mass) of the sample

- time:

  The starting time of the collection interval

- duration.conc:

  The duration of the collection interval

- check:

  Should the concentration data be checked?

## Value

The last measurable (positive) excretion rate, or `NA` if not available

## Details

Collections are ordered by their midpoint time, matching
[`pk.calc.ertlst()`](https://humanpred.github.io/pknca/reference/pk.calc.ertlst.md),
which gives the midpoint time of this same collection. When no
collection has a positive excretion rate, the result is 0.

## See also

[`pk.calc.ertlst()`](https://humanpred.github.io/pknca/reference/pk.calc.ertlst.md),
[`pk.calc.ermax()`](https://humanpred.github.io/pknca/reference/pk.calc.ermax.md)

Other Urine/Excretion parameters:
[`pk.calc.ae()`](https://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.clr()`](https://humanpred.github.io/pknca/reference/pk.calc.clr.md),
[`pk.calc.erint()`](https://humanpred.github.io/pknca/reference/pk.calc.erint.md),
[`pk.calc.ermax()`](https://humanpred.github.io/pknca/reference/pk.calc.ermax.md),
[`pk.calc.ertlst()`](https://humanpred.github.io/pknca/reference/pk.calc.ertlst.md),
[`pk.calc.ertmax()`](https://humanpred.github.io/pknca/reference/pk.calc.ertmax.md),
[`pk.calc.fe()`](https://humanpred.github.io/pknca/reference/pk.calc.fe.md),
[`pk.calc.volpk()`](https://humanpred.github.io/pknca/reference/pk.calc.volpk.md)
