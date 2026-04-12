# Compute the half-life and associated parameters

The terminal elimination half-life is estimated from the final points in
the concentration-time curve using semi-log regression
(`log(conc)~time`, the `"log-linear"` method) or Tobit regression
(`"tobit"` method) with automated selection of the points for
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
  lloq = NULL,
  hl_method = c("log-linear", "tobit"),
  manually.selected.points = FALSE,
  options = list(),
  min.hl.points = NULL,
  adj.r.squared.factor = NULL,
  tobit_n_points_penalty = NULL,
  tobit_optim_control = NULL,
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

- lloq:

  Lower limit of quantification. A scalar or a vector the same length as
  `conc`. Required when `hl_method = "tobit"`.

- hl_method:

  The method used to estimate the half-life. `"log-linear"` (default)
  uses ordinary least-squares regression on log-transformed
  concentrations. `"tobit"` uses maximum-likelihood Tobit regression
  that properly accounts for BLQ observations. The global default can be
  changed via `PKNCA.options(hl_method = "tobit")`.

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
  half-life. For `hl_method = "tobit"` this counts only above-LLOQ
  points.

- adj.r.squared.factor:

  The allowance in adjusted r-squared for adding another point
  (log-linear method only).

- tobit_n_points_penalty:

  The penalty exponent on the number of points for Tobit window
  selection. See
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md).

- tobit_optim_control:

  A list of control parameters passed to
  [`stats::optim()`](https://rdrr.io/r/stats/optim.html) for the Tobit
  fit. See
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md).

- conc.blq:

  How to handle a BLQ value that is between above LOQ values? See
  details for description.

- conc.na:

  How to handle NA concentrations. (See
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md))

- first.tmax:

  If there is more than one time point with the maximum value (Cmax or
  ERmax), which time should be selected for Tmax/ERTmax? If 'TRUE', the
  first will be selected. If not, then the last is considered
  Tmax/ERTmax.

- allow.tmax.in.half.life:

  Allow the concentration point for tmax to be included in the half-life
  slope calculation.

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

A data frame with one row. Columns depend on `hl_method`:

Columns returned by both methods:

- tmax:

  Time of maximum observed concentration (only included if not given as
  an input)

- tlast:

  Time of last observed concentration above the LOQ (only included if
  not given as an input)

- lambda.z:

  elimination rate

- lambda.z.time.first:

  first time for half-life calculation

- lambda.z.time.last:

  last time for half-life calculation

- lambda.z.n.points:

  number of points in half-life calculation (all points for Tobit,
  including BLQ)

- clast.pred:

  Concentration at tlast as predicted by the half-life line

- half.life:

  half-life

- span.ratio:

  ratio of the above-LLOQ time span to the half-life

Additional columns for `hl_method = "log-linear"`:

- r.squared:

  coefficient of determination

- adj.r.squared:

  adjusted coefficient of determination

- lambda.z.corrxy:

  correlation between time and log-conc for the half-life points

Additional columns for `hl_method = "tobit"`:

- lambda.z.n.points_blq:

  number of BLQ points included in the fit

- tobit_residual:

  estimated residual standard deviation from the Tobit fit (on the
  log-concentration scale)

- adj_tobit_residual:

  adjusted Tobit residual (analogous to adjusted r-squared; penalizes
  smaller windows)

## Details

See the "Half-Life Calculation" and "Half-Life Calculation with Tobit
Regression" vignettes for more details on the calculation methods.

If `manually.selected.points` is `FALSE` (default), the half-life is
calculated by computing the best fit line for all points at or after
tmax (based on the value of `allow.tmax.in.half.life`).

For `hl_method = "log-linear"`, the best half-life is chosen by the
following rules in order:

- At least `min.hl.points` points included

- A `lambda.z` \> 0 and at the same time the best adjusted r-squared
  (within `adj.r.squared.factor`)

- The one with the most points included

For `hl_method = "tobit"`, BLQ observations are retained and treated as
left-censored. The best window is the one minimizing
`tobit_residual * n ^ tobit_n_points_penalty` (default: raw
`tobit_residual`) among windows with `lambda.z > 0` and at least
`min.hl.points` above-LLOQ points. On ties the largest window (most
total points) is preferred.

If `manually.selected.points` is `TRUE`, the `conc` and `time` data are
used as-is without any form of point selection. When `TRUE`,
`adj.r.squared.factor`, `min.hl.points`, and `allow.tmax.in.half.life`
are ignored.

## References

Gabrielsson J, Weiner D. "Section 2.8.4 Strategies for estimation of
lambda-z." Pharmacokinetic & Pharmacodynamic Data Analysis: Concepts and
Applications, 4th Edition. Stockholm, Sweden: Swedish Pharmaceutical
Press, 2000. 167-9.

## See also

Other Half-life and elimination:
[`adj.r.squared()`](http://humanpred.github.io/pknca/reference/adj.r.squared.md),
[`pk.calc.aucpext()`](http://humanpred.github.io/pknca/reference/pk.calc.aucpext.md),
[`pk.calc.thalf.eff()`](http://humanpred.github.io/pknca/reference/pk.calc.thalf.eff.md)
