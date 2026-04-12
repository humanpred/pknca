# Calculate the midpoint collection time of the maximum excretion rate

Calculate the midpoint collection time of the maximum excretion rate

## Usage

``` r
pk.calc.ertmax(
  conc,
  volume,
  time,
  duration.conc,
  options = list(),
  check = TRUE,
  first.tmax = NULL
)
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

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- check:

  Should the concentration and time data be checked?

- first.tmax:

  If TRUE, return the first time of maximum excretion rate; otherwise,
  return the last

## Value

The midpoint collection time of the maximum excretion rate, or NA if not
available

## See also

Other Urine/Excretion parameters:
[`pk.calc.ae()`](http://humanpred.github.io/pknca/reference/pk.calc.ae.md),
[`pk.calc.clr()`](http://humanpred.github.io/pknca/reference/pk.calc.clr.md),
[`pk.calc.ermax()`](http://humanpred.github.io/pknca/reference/pk.calc.ermax.md),
[`pk.calc.ertlst()`](http://humanpred.github.io/pknca/reference/pk.calc.ertlst.md),
[`pk.calc.fe()`](http://humanpred.github.io/pknca/reference/pk.calc.fe.md),
[`pk.calc.volpk()`](http://humanpred.github.io/pknca/reference/pk.calc.volpk.md)
