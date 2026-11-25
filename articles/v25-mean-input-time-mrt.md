# MRT and Vss for IV Infusions

## Introduction

Mean residence time (MRT) is the average time a drug molecule remains in
the body. When calculated as the ratio of the area under the first
moment curve (AUMC) to the area under the concentration-time curve
(AUC), it also includes the time required for the drug to enter the
systemic circulation.

For intravenous (IV) infusions, this input time must be accounted for to
obtain the corrected MRT. PKNCA provides the following parameters for IV
dosing:

- **`mrt.iv.*`** calculates MRT for IV administration (`mrt.iv.obs`,
  `mrt.iv.pred`, `mrt.iv.last`, and `mrt.iv.all`), as well as
  `mrt.ivint.all` and `mrt.ivint.last` for intervals within the
  concentration-time profile.
- **`vss.iv.*`** calculates the steady-state volume of distribution
  (Vss) as clearance multiplied by the corresponding `mrt.iv.*`
  parameter.
- **`kel.iv.*`** and **`thalf.eff.iv.*`** calculate the elimination rate
  and effective half-life, respectively, using `mrt.iv.*`.
- **`mrt.ivmd.*`** and **`vss.ivmd.*`** calculate MRT and Vss for
  multiple-dose IV infusions (see
  [`?pk.calc.mrt.md.iv`](https://humanpred.github.io/pknca/reference/pk.calc.mrt.md)).

The correction is based on the **mean input time (MIT)** of all
administration events within the interval. This approach accounts for
variable-rate infusions (represented by one dose row for each
constant-rate segment), a bolus followed by an infusion, and infusions
that start after the interval start.

For a single infusion beginning at the interval start, the calculation
reduces to the familiar correction of half the infusion duration.

### How the calculation works

The corrected MRT is calculated by subtracting MIT from the ratio of
AUMC to AUC:

``` math
MRT = \frac{AUMC}{AUC} - MIT
```

For a single constant-rate infusion lasting *d* hours, the drug enters
the systemic circulation uniformly throughout the infusion. Therefore,
the average input time is the midpoint of the infusion:

``` math
MIT = \frac{d}{2}
```

For a bolus, the entire dose enters the systemic circulation at the
administration time.

When multiple administration events occur within an interval, MIT is
calculated as the dose-weighted mean of the midpoint of each input:

``` math
MIT = \frac{\sum_i Dose_i \left(t_i + d_i/2\right)}{\sum_i Dose_i}
```

where:

- *Dose_i* is the amount administered in dose event *i*.
- *t_i* is the administration time relative to the interval start.
- *d_i* is the duration of dose event *i* (zero for a bolus).

All administration times are measured relative to the interval start,
using the same time origin as the AUMC calculation.

The resulting MIT for common dosing scenarios is summarized below:

| Dosing in the interval | MIT |
|:---|:---|
| One infusion at the interval start | *d*/2 |
| One infusion starting *t* after the interval start | *t* + *d*/2 |
| One bolus administered *t* after the interval start | *t* |
| Multiple bolus and infusion events | Dose-weighted mean of *t_i* + *d_i*/2 |

Within
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md), the
calculation proceeds through the following steps:

1.  The dose events within the interval are selected from the
    [`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
    data, and their administration times are converted to times relative
    to the interval start.
2.  The dose amounts, relative administration times, and infusion
    durations are passed to
    [`pk.calc.mrt.iv()`](https://humanpred.github.io/pknca/reference/pk.calc.mrt.md)
    (or
    [`pk.calc.mrt.md.iv()`](https://humanpred.github.io/pknca/reference/pk.calc.mrt.md)
    for multiple dosing).
3.  The dose information is validated to ensure that the dose amounts,
    administration times, and durations have matching lengths.
4.  MIT is calculated using all administration events within the
    interval.
5.  The corrected MRT is calculated as AUMC/AUC minus MIT, returning one
    value for the interval.
6.  `vss.iv.*`, `kel.iv.*`, and `thalf.eff.iv.*` are calculated using
    the resulting `mrt.iv.*` value.

When the information required for dose weighting is incomplete, the
result is `NA` rather than an assumed value. For intervals containing
multiple dose events, a missing dose amount, administration time, or
infusion duration results in `NA`. A total administered dose of zero
also results in `NA`.

For a single dose event, the dose amount is not required to calculate
MIT because there is no need to determine relative dose weights.

The calculation must return a single result for each interval. If the
available dose information would produce more than one result for an
interval, an error is returned.

### Requesting the parameters

The IV parameters can be requested in the `intervals` data frame, just
like other PKNCA parameters. Their dependencies, including `aucinf.obs`
and `aumcinf.obs`, are added automatically.

The dose data must include the infusion duration. For bolus
administration, the duration should be zero.

``` r

o_dose <-
  PKNCAdose(
    d_dose, dose~time|ID, route = "intravascular", duration = "dur"
  )
o_data <-
  PKNCAdata(
    o_conc, o_dose,
    intervals = data.frame(
      start = 0, end = Inf,
      mrt.iv.obs = TRUE, vss.iv.obs = TRUE
    )
  )
```

### A variable-rate infusion

Consider a one-compartment drug with an elimination rate constant of 0.2
per hour and a volume of distribution of 10 L.

The expected pharmacokinetic parameters are:

    - True MRT: 1/0.2 = 5 hours.
    - True clearance: 0.2 × 10 = 2 L/hour.
    - True Vss: 2 × 5 = 10 L.

The drug is administered at 10 mg/hour for 1 hour, followed by 5 mg/hour
for 2 hours.

This administration schedule consists of two constant-rate infusion
segments, each delivering 10 mg. Therefore, the dose data contain two
rows.

``` r

k <- 0.2
V <- 10
segments <- data.frame(
  start = c(0, 1),
  dur = c(1, 2),
  dose = c(10, 10)
)

# The concentration after a sum of constant-rate segments (and boluses, which
# have a duration of 0)
conc_segments <- function(time, segments) {
  vapply(
    X = time,
    FUN.VALUE = 1,
    FUN = function(t) {
      sum(mapply(
        FUN = function(start, dur, dose) {
          if (t <= start) return(0)
          if (dur == 0) return(dose/V*exp(-k*(t - start)))
          end <- min(t, start + dur)
          dose/dur/(k*V)*(1 - exp(-k*(end - start)))*exp(-k*(t - end))
        },
        segments$start, segments$dur, segments$dose
      ))
    }
  )
}

sample_time <- c(0, 0.25, 0.5, 1, 1.5, 2, 3, 4, 6, 8, 12, 16, 24, 36, 48)
d_conc <-
  data.frame(
    ID = 1,
    time = sample_time,
    conc = conc_segments(sample_time, segments)
  )
```

The NCA uses the linear trapezoidal rule so that the example does not
depend on the default method:

``` r

run_nca <- function(d_conc, d_dose, start = 0) {
  o_conc <- PKNCAconc(d_conc, conc~time|ID)
  o_dose <-
    PKNCAdose(
      d_dose, dose~time|ID, route = "intravascular", duration = "dur"
    )
  o_data <-
    PKNCAdata(
      o_conc, o_dose,
      intervals = data.frame(
        start = start, end = Inf,
        aucinf.obs = TRUE, aumcinf.obs = TRUE, cl.obs = TRUE,
        mrt.iv.obs = TRUE, vss.iv.obs = TRUE
      ),
      options = list(auc.method = "linear")
    )
  as.data.frame(pk.nca(o_data))
}
# Show the parameters that are discussed (the dependencies are also calculated)
show_results <- function(results) {
  shown <- c("aucinf.obs", "aumcinf.obs", "cl.obs", "mrt.iv.obs", "vss.iv.obs")
  results[results$PPTESTCD %in% shown, c("PPTESTCD", "PPORRES")]
}
```

The following code creates the dose data with one row for each infusion
segment and performs the NCA.

``` r

d_dose <-
  data.frame(
    ID = 1, time = segments$start, dose = segments$dose, dur = segments$dur
  )
results_segments <- run_nca(d_conc, d_dose)
#> Warning: These NCA parameters are deprecated and will be an error in the next minor release of PKNCA; use the new names instead:
#>   cl.obs -> cl.inf.obs
#>   mrt.iv.obs -> mrt.iv.inf.obs
#>   vss.iv.obs -> vss.iv.inf.obs
#> This warning is displayed once per session.
show_results(results_segments)
#> # A tibble: 5 × 2
#>   PPTESTCD    PPORRES
#>   <chr>         <dbl>
#> 1 aucinf.obs    10.3 
#> 2 aumcinf.obs   64.2 
#> 3 cl.obs         1.94
#> 4 mrt.iv.obs     4.99
#> 5 vss.iv.obs     9.71
```

The results contain one value for each requested parameter, even though
the interval contains two dose rows.

The MIT for this schedule is the dose-weighted mean of the midpoints of
the two infusion segments. The corrected MRT is therefore AUMC/AUC minus
this MIT.

``` r

mit <- with(segments, sum(dose*(start + dur/2))/sum(dose))
value <- setNames(results_segments$PPORRES, results_segments$PPTESTCD)
c(
  mit = mit,
  mrt_from_parts = unname(value["aumcinf.obs"]/value["aucinf.obs"] - mit),
  mrt_reported = unname(value["mrt.iv.obs"])
)
#>            mit mrt_from_parts   mrt_reported 
#>       1.250000       4.992758       4.992758
```

The calculated MRT (approximately 5 hours) and Vss (approximately 9.7 L)
are close to their expected values of 5 hours and 10 L, respectively.

The remaining difference is due to the linear trapezoidal rule applied
to the relatively sparse concentration-time sampling schedule.

Combining the two infusion segments into a single dose row (20 mg
administered over 3 hours) would assume a constant infusion rate
throughout the entire 3-hour period. This changes the MIT from 1.25
hours to 1.5 hours and moves the calculated results further from the
expected values.

``` r

results_one_row <-
  run_nca(d_conc, data.frame(ID = 1, time = 0, dose = 20, dur = 3))
show_results(results_one_row)
#> # A tibble: 5 × 2
#>   PPTESTCD    PPORRES
#>   <chr>         <dbl>
#> 1 aucinf.obs    10.3 
#> 2 aumcinf.obs   64.2 
#> 3 cl.obs         1.94
#> 4 mrt.iv.obs     4.74
#> 5 vss.iv.obs     9.22
```

### A bolus followed by an infusion

A bolus has a duration of zero, so its contribution to MIT is its
administration time.

Consider a 10 mg bolus administered at time zero, followed by a 10 mg
infusion lasting 2 hours and starting at time 2 hours.

The MIT is calculated as:

``` math
MIT = \frac{(10 \times 0) + (10 \times (2 + 2/2))}{20} = 1.5\ hours
```

The following example demonstrates this calculation in PKNCA.

``` r

segments_bolus <- data.frame(start = c(0, 2), dur = c(0, 2), dose = c(10, 10))
sample_time_bolus <-
  c(0, 0.25, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 8, 12, 16, 24, 36, 48)
d_conc_bolus <-
  data.frame(
    ID = 1,
    time = sample_time_bolus,
    conc = conc_segments(sample_time_bolus, segments_bolus)
  )
results_bolus <-
  run_nca(
    d_conc_bolus,
    data.frame(
      ID = 1, time = segments_bolus$start, dose = segments_bolus$dose,
      dur = segments_bolus$dur
    )
  )
show_results(results_bolus)
#> # A tibble: 5 × 2
#>   PPTESTCD    PPORRES
#>   <chr>         <dbl>
#> 1 aucinf.obs    10.2 
#> 2 aumcinf.obs   66.9 
#> 3 cl.obs         1.97
#> 4 mrt.iv.obs     5.08
#> 5 vss.iv.obs    10.0
```

### An interval that starts before the dose

Administration times are measured relative to the interval start.
Therefore, any delay between the interval start and the first
administration event contributes to MIT.

Consider an interval starting at 10 hours, with a 2-hour infusion
beginning at 12 hours.

The infusion starts 2 hours after the interval start, so its MIT is:

``` math
MIT = 2 + \frac{2}{2} = 3\ hours
```

The following example demonstrates how PKNCA accounts for this delay.

``` r

segments_late <- data.frame(start = 12, dur = 2, dose = 20)
sample_time_late <- 10 + c(0, 1, 2, 2.5, 3, 3.5, 4, 5, 6, 8, 12, 16, 24, 36, 48)
d_conc_late <-
  data.frame(
    ID = 1,
    time = sample_time_late,
    conc = conc_segments(sample_time_late, segments_late)
  )
results_late <-
  run_nca(
    d_conc_late,
    data.frame(ID = 1, time = 12, dose = 20, dur = 2),
    start = 10
  )
value_late <- setNames(results_late$PPORRES, results_late$PPTESTCD)
mrt_from_parts_late <-
  value_late["aumcinf.obs"]/value_late["aucinf.obs"] - 3
c(
  mrt_from_parts = unname(mrt_from_parts_late),
  mrt_reported = unname(value_late["mrt.iv.obs"])
)
#> mrt_from_parts   mrt_reported 
#>       4.958559       4.958559
```

### Calling the functions directly

The function
[`pk.calc.mrt.iv()`](https://humanpred.github.io/pknca/reference/pk.calc.mrt.md)
accepts AUC, AUMC, and dose administration information.

For a single infusion, the dose amount and administration time are
optional. If they are not supplied, the infusion is assumed to start at
the interval start.

``` r

# AUMC/AUC is 6, and the infusion lasts 4 hr, so MRT = 6 - 4/2
pk.calc.mrt.iv(auc = 10, aumc = 60, duration.dose = 4)
#> [1] 4
```

For multiple administration events, provide the dose amount,
administration time (relative to the interval start), and duration for
every event.

``` r

pk.calc.mrt.iv(
  auc = 10, aumc = 62.4,
  duration.dose = c(1, 2), dose = c(10, 10), time.dose = c(0, 1)
)
#> [1] 4.99
```

The dose amounts, administration times, and durations must contain one
value per dose event. If their lengths do not match, an error is
returned. If a required value is missing, the result is `NA`.

``` r

tryCatch(
  pk.calc.mrt.iv(
    auc = 10, aumc = 62.4,
    duration.dose = c(1, 2), dose = c(10, 10), time.dose = 0
  ),
  error = function(e) conditionMessage(e)
)
#> [1] "Assertion on 'time.dose' failed: Must have length 2, but has length 1."
pk.calc.mrt.iv(
  auc = 10, aumc = 62.4,
  duration.dose = c(1, 2), dose = c(10, NA), time.dose = c(0, 1)
)
#> [1] NA
#> attr(,"exclude")
#> [1] "A dose amount is missing, or the doses sum to zero"
```

For multiple dosing,
[`pk.calc.mrt.md.iv()`](https://humanpred.github.io/pknca/reference/pk.calc.mrt.md)
calculates steady-state MRT. The calculation uses the steady-state
AUMC/AUC expression and subtracts the same dose-weighted MIT:

``` math
MRT_{ss} = \frac{AUMC_{\tau} + \tau(AUC_{\infty} - AUC_{\tau})}{AUC_{\tau}} - MIT
```

``` r

pk.calc.mrt.md.iv(
  auctau = 10, aumctau = 40, aucinf = 12, tau = 12,
  duration.dose = c(1, 2), dose = c(10, 10), time.dose = c(0, 1)
)
#> [1] 5.15
```

### Comparison with other software

As part of this development, we reviewed the documentation and, where
available, source code for the commercial and open-source NCA software
we are aware of.

The review focused on how MIT, MRT, and Vss are handled, particularly
when multiple bolus and infusion events occur within the same dosing
interval.

We did not execute each software program independently. Therefore, the
following observations describe the documented approaches we identified
and should not be interpreted as a definitive statement about every
software implementation.

Several patterns emerged from the review:

- Infusion corrections are commonly documented using a single infusion
  duration, with half of that duration subtracted from AUMC/AUC.
- For profiles containing multiple dose records, some documented
  approaches use only the last dose. Vendor support discussions
  identified during the review also describe combining multiple inputs
  into one constant infusion or using compartmental modelling as
  alternatives.
- Some approaches do not document an infusion correction, while others
  restrict steady-state volume of distribution calculations to IV bolus
  administration.
- We did not identify documentation describing a dose-weighted mean
  input time calculated across multiple bolus and infusion events within
  the same profile.

The underlying mathematical concept is not new. Watari and Benet (1989)
described a general approach for determining mean input time, MRT, and
Vss following multiple simultaneous or consecutive drug inputs.

The mean input time equation used here follows that general approach.
For example, it reproduces the published result of 2.5 hours for an
infusion administered at 250 mg/hour for 2 hours, followed by an
infusion at 125 mg/hour for 4 hours.

The distinction is that, in the software documentation reviewed, we did
not identify an implementation that calculates MIT directly from
multiple dose records using dose weighting.

### Reporting checklist

The IV parameters support common reporting requirements. The following
points should be considered when preparing the analysis:

1.  **Dose records:** Enter each constant-rate infusion segment and each
    bolus as a separate row in the
    [`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)
    data. Use `route = "intravascular"` and specify the infusion
    `duration` (zero for a bolus).
2.  **Assumptions:** The correction applies to IV bolus and
    constant-rate infusion inputs under linear pharmacokinetic
    assumptions. Extravascular input is not corrected because the
    absorption time is part of the extravascular MRT (`mrt.obs` and
    related parameters).
3.  **Quality of the result:** MRT and Vss depend on the accuracy of
    AUMC, which is influenced by the concentration-time sampling
    schedule and extrapolation to infinity.
4.  **Missing results:** An `NA` for `mrt.iv.*` when multiple dose
    events are present indicates that a required dose amount,
    administration time, or infusion duration is missing, or that the
    total dose is zero.

### References

- Watari N, Benet LZ. Determination of mean input time, mean residence
  time, and steady-state volume of distribution with multiple drug
  inputs. *J Pharmacokinet Biopharm.* 1989;17(5):593-599.
  <doi:10.1007/BF01071351>
- Yamaoka K, Nakagawa T, Uno T. Statistical moments in pharmacokinetics.
  *J Pharmacokinet Biopharm.* 1978;6(6):547-558.
