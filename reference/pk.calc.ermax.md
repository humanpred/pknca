# Calculate the maximum excretion rate

Calculate the maximum excretion rate

## Usage

``` r
pk.calc.ermax(conc, volume, time, duration.conc, check = TRUE)
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

The maximum excretion rate, or NA if not available

## See also

Other Urine/Excretion parameters:
[`pk.calc.ae()`](http://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.clr()`](http://humanpred.github.io/pknca/reference/pk.calc.clr.md),
[`pk.calc.ertlst()`](http://humanpred.github.io/pknca/reference/pk.calc.ertlst.md),
[`pk.calc.ertmax()`](http://humanpred.github.io/pknca/reference/pk.calc.ertmax.md),
[`pk.calc.fe()`](http://humanpred.github.io/pknca/reference/pk.calc.fe.md),
[`pk.calc.volpk()`](http://humanpred.github.io/pknca/reference/pk.calc.volpk.md)
