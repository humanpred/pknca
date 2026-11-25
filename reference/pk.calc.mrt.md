# Calculate the mean residence time (MRT) for single-dose data or linear multiple-dose data.

Calculate the mean residence time (MRT) for single-dose data or linear
multiple-dose data.

## Usage

``` r
pk.calc.mrt(auc, aumc)

pk.calc.mrt.iv(auc, aumc, duration.dose, dose = NULL, time.dose = NULL)

pk.calc.mrt.md(auctau, aumctau, aucinf, tau)

pk.calc.mrt.md.iv(
  auctau,
  aumctau,
  aucinf,
  tau,
  duration.dose,
  dose = NULL,
  time.dose = NULL
)
```

## Arguments

- auc:

  the AUC from 0 to infinity or 0 to tau

- aumc:

  the AUMC from 0 to infinity or 0 to tau

- duration.dose:

  The duration of the dose (usually an infusion duration for an IV
  infusion). May be a vector with one value per dose in the interval.

- dose:

  The dose amount(s) in the interval, used to weight the mean input time
  when there is more than one dose. It is required when `duration.dose`
  has more than one value; with a single dose it does not affect the
  result.

- time.dose:

  The time(s) of the dose(s) relative to the start of the interval (the
  same origin as `aumc`). When missing, the dose is assumed to be at the
  interval start (time 0).

- auctau:

  the AUC from time 0 to the end of the dosing interval (tau).

- aumctau:

  the AUMC from time 0 to the end of the dosing interval (tau).

- aucinf:

  the AUC from time 0 to infinity (typically using single-dose data)

- tau:

  The dosing interval

## Value

the numeric value of the mean residence time. A result of length one
that is `NA` because of missing or unusable data has the reason in its
"exclude" attribute, which
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
reports.

The mean residence time. A result of length one that is `NA` because of
missing or unusable data has the reason in its "exclude" attribute,
which
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
reports.

## Details

mrt is `aumc/auc - MIT` where `MIT` is the mean input time of the dose.
`MIT = 0` for oral administration. For an IV infusion that starts at the
beginning of the interval, `MIT = duration.dose/2`.

When an interval holds more than one dose row (for example, a
variable-rate infusion given as one row per constant-rate segment, or a
bolus plus an infusion), the mean input time is the dose-weighted mean
of the midpoints of the inputs, with times relative to the interval
start (the same origin as the AUMC):
`MIT = sum(dose*(time.dose + duration.dose/2))/sum(dose)`. A bolus
(`duration.dose = 0`) contributes its dose time. The result is a single
value per interval.

mrt.md is `aumctau/auctau + tau*(aucinf-auctau)/auctau` and should only
be used for multiple dosing with equal intervals between doses. Note
that if `aucinf == auctau` (as would be the assumption with linear
kinetics), the equation becomes the same as the single-dose MRT.

These are the parameters to use when PK are nonlinear. With linear PK,
MRT and Vss can be measured from a single dose and the single-dose
parameters (`mrt.inf.obs`, `vss.inf.obs`, and similar) describe steady
state as well. When PK are nonlinear they do not, so MRT and Vss have to
be measured over a steady-state dosing interval, which is what these
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

mrt.ivmd is mrt.md less the mean input time, the same correction that
mrt.iv applies to the single-dose MRT (half of the infusion duration for
a single infusion at the start of the interval). Without it, MRT and
everything derived from it are high by the mean input time.

## Functions

- `pk.calc.mrt.iv()`: MRT for an IV infusion

- `pk.calc.mrt.md()`: MRT for multiple-dose data with nonlinear kinetics

- `pk.calc.mrt.md.iv()`: MRT for multiple-dose data with nonlinear
  kinetics given as an IV infusion
