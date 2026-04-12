# Calculate the midpoint collection time of the last measurable excretion rate

Calculate the midpoint collection time of the last measurable excretion
rate

## Usage

``` r
pk.calc.ertlst(conc, volume, time, duration.conc, check = TRUE)
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

  Should the concentration and time data be checked?

## Value

The midpoint collection time of the last measurable excretion rate, or
NA/0 if not available

## See also

Other Urine/Excretion parameters:
[`pk.calc.ae()`](http://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.clr()`](http://humanpred.github.io/pknca/reference/pk.calc.clr.md),
[`pk.calc.ermax()`](http://humanpred.github.io/pknca/reference/pk.calc.ermax.md),
[`pk.calc.ertmax()`](http://humanpred.github.io/pknca/reference/pk.calc.ertmax.md),
[`pk.calc.fe()`](http://humanpred.github.io/pknca/reference/pk.calc.fe.md),
[`pk.calc.volpk()`](http://humanpred.github.io/pknca/reference/pk.calc.volpk.md)
