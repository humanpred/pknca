# Calculate the mean residence time (MRT) for single-dose data or linear multiple-dose data.

Calculate the mean residence time (MRT) for single-dose data or linear
multiple-dose data.

## Usage

``` r
pk.calc.mrt(auc, aumc)

pk.calc.mrt.iv(auc, aumc, duration.dose)
```

## Arguments

- auc:

  the AUC from 0 to infinity or 0 to tau

- aumc:

  the AUMC from 0 to infinity or 0 to tau

- duration.dose:

  The duration of the dose (usually an infusion duration for an IV
  infusion)

## Value

the numeric value of the mean residence time

## Details

mrt is `aumc/auc - duration.dose/2` where `duration.dose = 0` for oral
administration.

## Functions

- `pk.calc.mrt.iv()`: MRT for an IV infusion

## See also

[`pk.calc.mrt.md()`](http://humanpred.github.io/pknca/reference/pk.calc.mrt.md.md)
