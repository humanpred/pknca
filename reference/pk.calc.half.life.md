# Compute the half-life and associated parameters

The terminal elimination half-life is estimated from the final points in
the concentration-time curve using semi-log regression
(`log(conc)~time`) with automated selection of the points for
calculation (unless `manually.selected.points` is `TRUE`).

## Usage

``` r
pk.calc.half.life(
  conc,
  time,
  tmax,
  tlast,
  time.dose = NULL,
  duration.dose = 0,
  manually.selected.points = FALSE,
  options = list(),
  min.hl.points = NULL,
  adj.r.squared.factor = NULL,
  conc.blq = NULL,
  conc.na = NULL,
  first.tmax = NULL,
  allow.tmax.in.half.life = NULL,
  check = TRUE
)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- tmax:

  Time of maximum concentration (will be calculated and included in the
  return data frame if not given)

- tlast:

  Time of last concentration above the limit of quantification (will be
  calculated and included in the return data frame if not given)

- time.dose:

  Time of the dose for the current interval (must be the same length as
  `dose`)

- duration.dose:

  The duration of the dose administration for the current interval
  (typically zero for extravascular and intravascular bolus and nonzero
  for intravascular infusion)

- manually.selected.points:

  Have the input points (`conc` and `time`) been manually selected? The
  impact of setting this to `TRUE` is that no selection for the best
  points will be done. When `TRUE`, this option causes the options of
  `adj.r.squared.factor`, `min.hl.points`, and `allow.tmax.in.half.life`
  to be ignored.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- min.hl.points:

  The minimum number of points that must be included to calculate the
  half-life

- adj.r.squared.factor:

  The allowance in adjusted r-squared for adding another point.

- conc.blq:

  See
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md)

- conc.na:

  See
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)

- first.tmax:

  See
  [`pk.calc.tmax()`](http://humanpred.github.io/pknca/reference/pk.calc.tmax.md).

- allow.tmax.in.half.life:

  Allow the concentration point for tmax to be included in the half-life
  slope calculation.

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md),
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md),
  and
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)?

## Value

A data frame with one row and columns for

- tmax:

  Time of maximum observed concentration (only included if not given as
  an input)

- tlast:

  Time of last observed concentration above the LOQ (only included if
  not given as an input)

- r.squared:

  coefficient of determination

- adj.r.squared:

  adjusted coefficient of determination

- lambda.z:

  elimination rate

- lambda.z.corrxy:

  correlation between time and log-conc half-life points

- lambda.z.time.first:

  first time for half-life calculation

- lambda.z.time.last:

  last time for half-life calculation

- lambda.z.n.points:

  number of points in half-life calculation

- clast.pred:

  Concentration at tlast as predicted by the half-life line

- half.life:

  half-life

- span.ratio:

  span ratio \[ratio of half-life to time used for half-life calculation

## Details

See the "Half-Life Calculation" vignette for more details on the
calculation methods used.

If `manually.selected.points` is `FALSE` (default), the half-life is
calculated by computing the best fit line for all points at or after
tmax (based on the value of `allow.tmax.in.half.life`). The best
half-life is chosen by the following rules in order:

- At least `min.hl.points` points included

- A `lambda.z` \> 0 and at the same time the best adjusted r-squared
  (within `adj.r.squared.factor`)

- The one with the most points included

If `manually.selected.points` is `TRUE`, the `conc` and `time` data are
used as-is without any form of selection for the best-fit half-life.

## References

Gabrielsson J, Weiner D. "Section 2.8.4 Strategies for estimation of
lambda-z." Pharmacokinetic & Pharmacodynamic Data Analysis: Concepts and
Applications, 4th Edition. Stockholm, Sweden: Swedish Pharmaceutical
Press, 2000. 167-9.
