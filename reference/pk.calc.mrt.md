# Calculate the mean residence time (MRT) for single-dose data or linear multiple-dose data.

Calculate the mean residence time (MRT) for single-dose data or linear
multiple-dose data.

## Usage

``` r
pk.calc.mrt(auc, aumc)

pk.calc.mrt.iv(auc, aumc, duration.dose)

pk.calc.mrt.md(auctau, aumctau, aucinf, tau)
```

## Arguments

- auc:

  the AUC from 0 to infinity or 0 to tau

- aumc:

  the AUMC from 0 to infinity or 0 to tau

- duration.dose:

  The duration of the dose (usually an infusion duration for an IV
  infusion)

- auctau:

  the AUC from time 0 to the end of the dosing interval (tau).

- aumctau:

  the AUMC from time 0 to the end of the dosing interval (tau).

- aucinf:

  the AUC from time 0 to infinity (typically using single-dose data)

- tau:

  The dosing interval

## Value

the numeric value of the mean residence time

## Details

mrt is `aumc/auc - duration.dose/2` where `duration.dose = 0` for oral
administration.

mrt.md is `aumctau/auctau + tau*(aucinf-auctau)/auctau` and should only
be used for multiple dosing with equal intervals between doses. Note
that if `aucinf == auctau` (as would be the assumption with linear
kinetics), the equation becomes the same as the single-dose MRT.

## Functions

- `pk.calc.mrt.iv()`: MRT for an IV infusion

- `pk.calc.mrt.md()`: MRT for multiple-dose data with nonlinear kinetics
