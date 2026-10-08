# Choose intervals to compute AUCs from time and dosing information

Intervals are selected by the following metrics:

1.  If there are no dose times, no intervals are generated and a
    `"pknca_warning_no_dose_times_for_group"` warning is given.

2.  If only one dose is administered and any sample follows it, the
    interval runs from the dose to infinity with the parameters
    [`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md)
    gives for a single dose.

3.  If more than one dose is administered, an interval is generated
    between any two consecutive doses that have samples at both dose
    times and at least one sample between them. It is a dosing interval
    when the samples run up to the next dose, and a single-dose profile
    bounded by the next dose when they stop partway and leave a washout.

4.  For the final dose, the dosing interval (\\\tau\\) is found with
    [`find.tau()`](https://humanpred.github.io/pknca/reference/find.tau.md).
    An interval one \\\tau\\ long is generated when a sample was taken
    at its end, with the parameters for a dose at steady state. It
    starts at the first dose of the last complete cycle, which is the
    last dose itself unless the regimen gives more than one dose per
    \\\tau\\, so that the interval never contains a dose that was not
    recorded.

5.  If samples continue beyond \\\tau\\ after the last dose, the
    half-life is calculated from the last dose onward. If the last dose
    has samples after it but gets neither of these, its profile is
    calculated to infinity as a single dose.

## Usage

``` r
choose.auc.intervals(
  time.conc,
  time.dosing,
  options = list(),
  single.dose.aucs = NULL,
  route = "extravascular",
  sparse = FALSE,
  timeu = NULL,
  time.conc.nominal = NULL,
  time.dosing.nominal = NULL,
  dense.samples = 3,
  conc = NULL
)
```

## Arguments

- time.conc:

  Time of concentration measurement

- time.dosing:

  Time of dosing

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- single.dose.aucs:

  The AUC specification for single dosing.

- route:

  How the drug was given, as one of
  [`pknca_routes()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md).

- sparse:

  Is this a sparse sampling design? A sparse design imputes nothing; see
  [`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md).

- timeu:

  The time unit of `time.conc` and `time.dosing`; `NULL` when it is not
  known, which is taken to be hours; or `NA` when it cannot be used (see
  [`find.dose.regimen()`](https://humanpred.github.io/pknca/reference/find.dose.regimen.md)).
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  gives the time unit of its concentration data.

- time.conc.nominal, time.dosing.nominal:

  Nominal times of the samples and of the doses, on the same scale as
  `time.conc` and `time.dosing` and the same length, or `NULL`. They are
  used, and checked to be numeric, only to judge whether a dose is
  sampled densely after a change of regimen.
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  gives the `time.nominal` columns of
  [`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
  and
  [`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md).

- dense.samples:

  The fewest samples within one dosing period after a dose that make it
  sampled densely, which gives it an interval after a change of regimen

- conc:

  The concentrations at `time.conc`, or `NULL`. Used only to leave
  samples without a concentration out of the dense-sampling count.

## Value

A data frame with columns for `start`, `end`, and the parameters to
calculate. See
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md)
for column definitions. The data frame may have zero rows if no
intervals could be found.

## Details

When
[`find.dose.regimen()`](https://humanpred.github.io/pknca/reference/find.dose.regimen.md)
finds a change of regimen in the dose times (more than one segment) and
the design is not sparse, the intervals follow the segments instead:

- One steady-state interval for each segment, when a sample ends it. An
  earlier segment's interval is its last complete cycle, from the
  cycle's first dose to the recorded dose one period later (the dose
  that starts the next segment, unless a dose was missed before it), so
  it never contains a later dose. The last segment's interval is its
  last cycle, one period at the segment's own period. Like the interval
  after the last dose, a steady-state interval needs only a sample at
  its end, so it may have as few as two samples.

- The interval after the first dose, as above.

- The interval after any other dose only when the dose is sampled
  densely: at least `dense.samples` samples (3 by default) strictly
  within one period of its segment after the dose. A sample counts by
  its nominal time when it has one (`time.conc.nominal`), from the
  dose's nominal time when that is given (`time.dosing.nominal`), so
  that a sample drawn a little late counts where it was scheduled; a
  sample without a nominal time counts by its actual time. Samples at
  the same time count once, and samples without a concentration (`conc`
  is `NA`) do not count; samples below the limit of quantification do.
  Nominal times must share the actual times' origin (time since the
  first dose, for example). When they restart instead, as times since
  the latest dose do, the actual times are used with a
  `"pknca_warning_intervals_nominal_restart"` warning.

- The last dose gets the intervals above at the period of the last
  segment, even when an earlier segment has more doses.

A `"pknca_warning_intervals_by_segment"` warning names the segments and
the intervals chosen. It is also a `"pknca_warning_tau_regimen_change"`
warning, which it replaces.

\\\tau\\ is matched to the nominal dosing intervals of
[`find.dose.regimen()`](https://humanpred.github.io/pknca/reference/find.dose.regimen.md)
in the time unit `timeu`, taken to be hours when it is not given: dose
times recorded a little early or late give the nominal interval, and an
interval that matches none of them, such as dosing every hour, gives a
`"pknca_warning_tau_not_nominal"` warning. With `timeu = NA` (a unit
PKNCA cannot use), \\\tau\\ is found from the dose times alone.

Times are matched within a tolerance rather than exactly, so a sample
drawn a little before its nominal time still bounds the interval it
belongs to. The window is the `auto.interval.tolerance` option as a
fraction of the interval's length, and it only reaches backward: a
sample drawn after a boundary belongs to what follows that boundary, so
a concentration drawn after a dose cannot stand in for the predose
sample.

Setting the `auto.interval.method` option to `"legacy"` calculates the
parameter lists PKNCA used before
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md)
was available: the `single.dose.aucs` option for single-dose data, and
AUClast, Cmax, and Tmax for each interval of multiple-dose data. The
intervals themselves are found the same way either way.

## See also

[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pk.calc.auc()`](https://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.half.life()`](https://humanpred.github.io/pknca/reference/pk.calc.half.life.md),
[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md)

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md),
[`pknca_cdisc_codes()`](https://humanpred.github.io/pknca/reference/pknca_cdisc_codes.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_match_route()`](https://humanpred.github.io/pknca/reference/pknca_match_route.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)

Other Interval determination:
[`find.dose.regimen()`](https://humanpred.github.io/pknca/reference/find.dose.regimen.md),
[`find.tau()`](https://humanpred.github.io/pknca/reference/find.tau.md),
[`resolve_dose_tau()`](https://humanpred.github.io/pknca/reference/resolve_dose_tau.md)

## Examples

``` r
# A single dose gives one profile to infinity
choose.auc.intervals(c(0, 1, 2, 4, 8, 24), 0)[, c("start", "end")]
#>   start end
#> 1     0 Inf

# Daily dosing with a dense profile on the first and last day
choose.auc.intervals(
  c(0, 1, 2, 4, 8, 12, 24, 48, 72, 96, 120, 144, 145, 146, 148, 152, 156, 168, 192),
  seq(0, 144, by = 24)
)[, c("start", "end")]
#>   start end
#> 1     0  24
#> 2   144 168
#> 3   144 Inf
```
