# Data Imputation

Imputation may be required for noncompartmental analysis (NCA)
calculations. Typical imputations may require setting the concentration
before the first dose to zero or shifting actual time predose
concentrations to the beginning of the dosing interval.

PKNCA supports imputation either for the full analysis dataset or per
calculation interval.

The current list of imputation methods built into PKNCA can be found by
looking at
[`?PKNCA_impute_method`](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md):

``` r

library(PKNCA)
#> 
#> Attaching package: 'PKNCA'
#> The following object is masked from 'package:stats':
#> 
#>     filter
cat(paste(
  "*", ls("package:PKNCA", pattern = "^PKNCA_impute_method")
), sep = "\n")
#> * PKNCA_impute_method_end_conc_drop
#> * PKNCA_impute_method_start_cmin
#> * PKNCA_impute_method_start_conc0
#> * PKNCA_impute_method_start_predose
#> * PKNCA_impute_method_start_predose_conc0
```

In brief, the built-in methods work as follows:

- `start_conc0` sets the concentration at the interval start time to 0.
  If an observation exists at the start time, its value is replaced with
  0; otherwise, a new row is added (usually used with single-dose data).
- `start_predose` shifts the most recent observation with a measured
  concentration before the interval start to the interval start time. It
  applies only when no start-time observation exists, only when such a
  pre-start observation exists, and only when the shift is no more than
  `max_shift` (by default, 5% of the interval duration or, for intervals
  with an infinite end, 5% of the time from the interval start to the
  last sample). Observations with a missing concentration are skipped,
  so an earlier measured observation is used when the nearest one is
  missing.
- `start_cmin` adds the minimum concentration within the interval at the
  interval start time when no start-time observation exists (usually
  used with multiple-dose data).

The development version of PKNCA also adds
`PKNCA_impute_method_end_conc_drop` (used as `"end_conc_drop"`), which
drops a concentration observed exactly at the interval end – such as a
predose sample for the next dose – from that interval’s calculation.

## How does imputation occur?

(You can skip this section if you don’t desire the details of the
methods of imputation.)

Imputation occurs just before calculations are performed within PKNCA.
Imputation occurs only on a single interval definition at a time, so the
same group (usually meaning the same subject with the same analyte) at
the same time range can have different imputations for different
parameter calculations.

The reason that this is done is to ensure that there are no
unintentional modifications to the data. As an example, if an AUC₀₋₂₄
were calculated on Day 1 and Day 2 of a study with actual times, the
nominal 24 hour sample may be collected at 23.5 hours. It may be
preferable to keep the 23.5 hour sample at 23.5 hours for the Day 1
calculation, and at the same time, it may be preferred to shift the same
23.5 hr sample to 24 hours (time 0 on Day 2) for the Day 2 calculation.

## How to select imputation methods to use

The selection of imputation methods uses a string of text with commas or
spaces (or both) separating the imputation methods to use. No imputation
will be performed if the imputation method is requested as `NA` or `""`.

- To select no imputation (the default), indicate the imputation by `NA`
  or `""`.
- To set imputation on the full dataset, use the `impute` argument to
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  to specify the methods to use.
- To set imputation by interval, use the `impute` argument to
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  to specify the column in the intervals dataset to use for imputation.
- You cannot specify imputation for both the full dataset and by
  interval at the same time. And, if a column name in the dataset
  matches the `impute` argument to
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md),
  that will be used.

Imputation method functions are named
`PKNCA_impute_method_[method name]`. For example, the method to impute a
concentration of 0 at time 0 is named `PKNCA_impute_method_start_conc0`.
When specifying the imputation method to use, give the `[method name]`
part of the function name. So for the example above, use
`"start_conc0"`.

To specify more than one, give all the methods in order with a comma or
space separating them (for example, `"start_predose,start_conc0"`), and
the methods will be applied in order, each to the output of the previous
method. Note that because `start_conc0` sets the start-time
concentration to 0 even when a start-time value already exists, the
`"start_predose,start_conc0"` chain produces the same results as
`"start_conc0"` alone: the concentration that `start_predose` shifts to
the start time is then overwritten with 0. This overwriting is by
design; the intent of `start_conc0` is to force the start concentration
to zero, and that can remove a nonzero predose concentration, too. To
carry a predose concentration to the start time, use `"start_predose"`
alone; to force the start concentration to zero, use `"start_conc0"`;
and to use the predose concentration when one exists and 0 otherwise,
use `"start_predose_conc0"`. `start_predose_conc0` also keeps a
concentration that was measured at the start time, which matters after
an intravenous bolus dose where that measurement is the C₀ for the dose.

## Imputation for the full dataset

If an imputation applies to the full dataset, it can be provided in the
`impute` argument to
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md):

``` r

library(PKNCA)
# Remove time 0 to illustrate that imputation works
d_conc <- as.data.frame(datasets::Theoph)[!datasets::Theoph$Time == 0, ]
conc_obj <- PKNCAconc(d_conc, conc~Time|Subject)
d_dose <- unique(datasets::Theoph[datasets::Theoph$Time == 0,
                                  c("Dose", "Time", "Subject")])
dose_obj <- PKNCAdose(d_dose, Dose~Time|Subject)
data_obj <- PKNCAdata(conc_obj, dose_obj, impute = "start_predose,start_conc0")
nca_obj <- pk.nca(data_obj)
summary(nca_obj)
#>  start end  N     auclast        cmax               tmax   half.life aucinf.obs
#>      0  24 12 74.6 [24.2]           .                  .           .          .
#>      0 Inf 12           . 8.65 [17.0] 1.14 [0.630, 3.55] 8.18 [2.12] 115 [28.4]
#> 
#> Caption: auclast, cmax, aucinf.obs: geometric mean and geometric coefficient of variation; tmax: median and range; half.life: arithmetic mean and standard deviation; N: number of subjects
```

## Imputation by calculation interval

If an imputation applies to specific intervals, the column in the
interval data.frame can be provided in the `impute` argument to
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md):

``` r

library(PKNCA)
# Remove time 0 to illustrate that imputation works
d_conc <- as.data.frame(datasets::Theoph)[!datasets::Theoph$Time == 0, ]
conc_obj <- PKNCAconc(d_conc, conc~Time|Subject)
d_dose <- unique(datasets::Theoph[datasets::Theoph$Time == 0,
                                  c("Dose", "Time", "Subject")])
dose_obj <- PKNCAdose(d_dose, Dose~Time|Subject)

d_intervals <-
  data.frame(
    start=0, end=c(24, 24.1),
    auclast=TRUE,
    impute=c(NA, "start_conc0")
  )

data_obj <- PKNCAdata(conc_obj, dose_obj, intervals = d_intervals, impute = "impute")
nca_obj <- pk.nca(data_obj)
#> Warning: Requesting an AUC range starting (0) before the first measurement
#> (0.27) is not allowed
#> Warning: Requesting an AUC range starting (0) before the first measurement (0.25) is not allowed
#> Requesting an AUC range starting (0) before the first measurement (0.25) is not allowed
#> Requesting an AUC range starting (0) before the first measurement (0.25) is not allowed
#> Warning: Requesting an AUC range starting (0) before the first measurement (0.27) is not allowed
#> Requesting an AUC range starting (0) before the first measurement (0.27) is not allowed
#> Warning: Requesting an AUC range starting (0) before the first measurement
#> (0.35) is not allowed
#> Warning: Requesting an AUC range starting (0) before the first measurement
#> (0.3) is not allowed
#> Warning: Requesting an AUC range starting (0) before the first measurement
#> (0.25) is not allowed
#> Warning: Requesting an AUC range starting (0) before the first measurement
#> (0.37) is not allowed
#> Warning: Requesting an AUC range starting (0) before the first measurement
#> (0.25) is not allowed
#> Warning: Requesting an AUC range starting (0) before the first measurement
#> (0.3) is not allowed
# PKNCA does not impute time 0 by default, so AUClast in the 0-24 interval is
# not calculated
summary(nca_obj)
#>  start  end  N     auclast
#>      0 24.0 12          NC
#>      0 24.1 12 76.4 [23.0]
#> 
#> Caption: auclast: geometric mean and geometric coefficient of variation; N: number of subjects; NC: not calculated
```

## Advanced: Writing your own imputation functions

Writing your own imputation function is intended to be a simple process.
To create an imputation function requires the following steps:

1.  Write a function where the name starts with `PKNCA_impute_method_`
    and the remainder of the function name is a brief description of the
    method. (Such as `PKNCA_impute_method_start_conc0`.)
2.  The function should have 4 arguments: `conc`, `time`, `...`, and
    `options`.
3.  The function should return a single data.frame with two columns
    named `conc` and `time`. The rows in the data.frame must be sorted
    by `time`.

In addition to the above, the function may take named arguments of:

- `start` and `end` to indicate the start and end time of the interval,
  and
- `conc.group` and `time.group` to indicate the concentrations and times
  that have not been filtered for the interval.
