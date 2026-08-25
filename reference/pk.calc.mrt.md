# Calculate the mean residence time (MRT) for single-dose data or linear multiple-dose data.

Calculate the mean residence time (MRT) for single-dose data or linear
multiple-dose data.

## Usage

``` r
pk.calc.mrt(auc, aumc)

pk.calc.mrt.iv(auc, aumc, duration.dose)

pk.calc.mrt.md(auctau, aumctau, aucinf, tau)

pk.calc.mrt.md.iv(auctau, aumctau, aucinf, tau, duration.dose)
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

These are the parameters to use when PK are nonlinear. With linear PK,
MRT and Vss can be measured from a single dose and the single-dose
parameters (`mrt.obs`, `vss.obs`, and similar) describe steady state as
well. When PK are nonlinear they do not, so MRT and Vss have to be
measured over a steady-state dosing interval, which is what these
parameters do. The ratio `aumctau/auctau` on its own (`mrt.last` over a
dosing interval) is not MRT at steady state and underestimates it
substantially; the `tau*(aucinf-auctau)/auctau` term accounts for the
drug still in the body at the end of the interval.

Within
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md),
`tau` is detected from the dose times of the group with
[`find.tau()`](https://humanpred.github.io/pknca/reference/find.tau.md).
When the dosing data hold a single dose (a common steady-state design
where only the profiled dose is recorded), nothing repeats and nothing
can be detected, so give `tau` as a column of the interval specification
instead; a `tau` column always takes precedence over detection. If `tau`
can be neither given nor detected, the parameter is `NA` with a warning.

mrt.ivmd is mrt.md less half of the infusion duration, the same
correction that mrt.iv applies to the single-dose MRT. Without it, MRT
and everything derived from it are high by `duration.dose/2`.

## Functions

- `pk.calc.mrt.iv()`: MRT for an IV infusion

- `pk.calc.mrt.md()`: MRT for multiple-dose data with nonlinear kinetics

- `pk.calc.mrt.md.iv()`: MRT for multiple-dose data with nonlinear
  kinetics given as an IV infusion
