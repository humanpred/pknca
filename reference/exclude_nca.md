# Exclude NCA parameters based on examining the parameter set.

Exclude NCA parameters based on examining the parameter set.

## Usage

``` r
exclude_nca_span.ratio(min.span.ratio)

exclude_nca_max.aucinf.pext(max.aucinf.pext)

exclude_nca_count_conc_measured(
  min_count,
  exclude_param_pattern = c("^aucall", "^aucinf", "^aucint", "^auciv", "^auclast",
    "^aumc", "^sparse_auc")
)

exclude_nca_min.hl.r.squared(min.hl.r.squared)

exclude_nca_min.hl.adj.r.squared(min.hl.adj.r.squared = 0.9)

exclude_nca_tmax_early(tmax_early = 0)

exclude_nca_tmax_0()

exclude_nca_tmax_coverage(min_subjects = 4, k_warn = 1.5, k_exclude = 3)
```

## Arguments

- min.span.ratio:

  The minimum acceptable span ratio (uses
  PKNCA.options("min.span.ratio") if not provided).

- max.aucinf.pext:

  The maximum acceptable percent AUC extrapolation (uses
  PKNCA.options("max.aucinf.pext") if not provided).

- min_count:

  Minimum number of measured concentrations

- exclude_param_pattern:

  Character vector of regular expression patterns to exclude

- min.hl.r.squared:

  The minimum acceptable r-squared value for half-life (uses
  PKNCA.options("min.hl.r.squared") if not provided).

- min.hl.adj.r.squared:

  The minimum acceptable adjusted r-squared for half-life (uses 0.9 if
  not provided).

- tmax_early:

  The time for Tmax which is considered too early to be a valid NCA
  result

- min_subjects:

  The fewest subjects with a Tmax in a group for the group to be checked
  (smaller groups are not checked, with a message)

- k_warn:

  The multiple of the interquartile range that sets the inner fences; a
  subject with no sample within them gets a warning

- k_exclude:

  The multiple of the interquartile range that sets the outer fences (at
  least k_warn); a subject with no sample within them is excluded

## Value

A function to give to
[`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md) as
`FUN`. Its `pknca_affected_parameters` attribute lists the parameters it
can exclude, and its `pknca_options` attribute lists the
[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md)
entries its thresholds came from (see
[`pknca_exclude_rules()`](https://humanpred.github.io/pknca/reference/pknca_exclude_rules.md)).

## Functions

- `exclude_nca_span.ratio()`: Exclude based on the half-life span ratio

- `exclude_nca_max.aucinf.pext()`: Exclude based on the percent of AUC
  extrapolated to infinity (both observed and predicted)

- `exclude_nca_count_conc_measured()`: Exclude based on the count of
  concentrations measured and not below the lower limit of
  quantification (affects AUC and AUMC parameters)

- `exclude_nca_min.hl.r.squared()`: Exclude based on half-life r-squared

- `exclude_nca_min.hl.adj.r.squared()`: Exclude based on half-life
  adjusted r-squared

- `exclude_nca_tmax_early()`: Exclude based on implausibly early Tmax
  (often used for extravascular dosing with a Tmax value of 0)

- `exclude_nca_tmax_0()`: Exclude based on implausibly early Tmax
  (special case for tmax_early = 0)

- `exclude_nca_tmax_coverage()`: Exclude based on whether a subject has
  a sample within Tukey's fences around the Tmax values of its group;
  the rule flags a subject with no sample within the inner fences, and
  excludes only a subject with no sample within the outer fences

## Tmax coverage

`exclude_nca_tmax_coverage()` compares each subject's samples with the
Tmax values of its group; it flags a subject whose samples miss the
usual Tmax times, and excludes only beyond the outer fences. The group
is the summary group of
[`summary.PKNCAresults()`](https://humanpred.github.io/pknca/reference/summary.PKNCAresults.md):
every grouping column except the subject, with the interval start and
end (so each part, treatment, analyte, and interval is its own group).
From the first and third quartiles of the Tmax values of every subject
in the group (the subject being judged included), Tukey's inner fences
are the quartiles extended by `k_warn` times the interquartile range,
and the outer fences by `k_exclude` times it. The quartiles are those of
`stats::quantile(type = 7)`, the default type; with few subjects, the
types differ (Tmax values of 1, 1, 2, 2, 1, and 8 give a third quartile
of 2 with type 7, 3.5 with type 6, and 2.5 with type 8). Tmax values
that are missing or already excluded are not used. The ranges never
start before the interval start, where a reported range starts when its
lower fence is below it. A sample at the interval start counts only when
the subject's dose at or before the interval start is an intravascular
bolus (route intravascular and no duration or a duration of zero in
[`PKNCAdose()`](https://humanpred.github.io/pknca/reference/PKNCAdose.md)),
so a predose sample does not count after an extravascular dose or when
the results have no dose data.

The samples are the concentration rows with an actual time within the
interval (the rows that
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
used) that have a concentration and are not excluded. When the
concentration data have a nominal time (`time.nominal` in
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)),
the samples are placed by their nominal time minus the interval start,
so the nominal times must share the origin of the interval times (for
example, the nominal time since the first dose); otherwise, they are
placed by their actual time. The Tmax values are placed the same way:
with nominal times, a subject's Tmax is the nominal time of the sample
it was found at, so an offset between the actual and nominal times moves
the fences and the samples together. A subject whose Tmax sample has no
nominal time does not enter the fences, and a subject whose samples in
the interval have no nominal time at all is not judged, with a
`pknca_message_tmax_coverage_no_nominal_subject` message. Times are
never converted between units, and the time unit is only used in the
text.

- A subject with no sample within the outer fences is excluded: every
  parameter of that interval is excluded with a reason that gives the
  outer range and the subject's sample nearest to it.

- A subject with a sample within the outer fences but none within the
  inner fences is flagged as a possible data issue and not excluded: a
  `pknca_warning_tmax_coverage_outlier` warning has the fields `group`
  (a one-row data.frame with the group and subject), `tmax_range` (the
  inner range, relative to the interval start), and `nearest_sample`
  (the subject's sample nearest to it, relative to the interval start).

- With nominal times, a subject with a sample within the inner fences
  that is missing some of the group's nominal times within them (see
  [`pknca_missing_samples()`](https://humanpred.github.io/pknca/reference/pknca_missing_samples.md))
  gets a `pknca_message_tmax_coverage_partial` message that Cmax and
  Tmax may be unreliable. Its fields are `group`, `tmax_range`,
  `time_nominal_missing`, and `reason` (as in
  [`pknca_missing_samples()`](https://humanpred.github.io/pknca/reference/pknca_missing_samples.md)).
  Without nominal times, there is no schedule to compare with, and no
  message is given.

- The warnings and messages can be caught with
  [`withCallingHandlers()`](https://rdrr.io/r/base/conditions.html).

- A group with fewer than `min_subjects` subjects with a Tmax on the
  basis of the fences (one subject, for example) is not checked, and a
  `pknca_message_tmax_coverage_few_subjects` message says so once per
  group. Quartiles of fewer than four values describe the spread of the
  group poorly.

- When the nominal times disagree with the interval, the group is not
  checked, and a `pknca_warning_tmax_coverage_no_nominal` warning says
  so once per group. They disagree when no nominal time of the group is
  after the interval start, when most samples of the group with an
  actual time in the interval have a nominal time outside it, or when a
  subject's nominal times go back to the start of its schedule while its
  actual times increase within the interval, as when the nominal times
  restart at each dose.

- Sparse data have one Tmax per group, from the mean profile, so they
  are not checked, and a `pknca_message_tmax_coverage_sparse` message
  says so once per call to
  [`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md).

## See also

Other Result exclusions:
[`exclude()`](https://humanpred.github.io/pknca/reference/exclude.md),
[`pknca_exclude_rules()`](https://humanpred.github.io/pknca/reference/pknca_exclude_rules.md),
[`pknca_missing_samples()`](https://humanpred.github.io/pknca/reference/pknca_missing_samples.md)

## Examples

``` r
my_conc <- PKNCAconc(data.frame(conc=1.1^(3:0),
                                time=0:3,
                                subject=1),
                     conc~time|subject)
my_data <- PKNCAdata(my_conc,
                     intervals=data.frame(start=0, end=Inf,
                                          aucinf.obs=TRUE,
                                          aucpext.obs=TRUE))
my_result <- pk.nca(my_data)
my_result_excluded <- exclude(my_result,
                              FUN=exclude_nca_max.aucinf.pext())
as.data.frame(my_result_excluded)
#> # A tibble: 16 × 7
#>    subject start   end PPTESTCD            PPORRES PPANMETH              exclude
#>      <dbl> <dbl> <dbl> <chr>                 <dbl> <chr>                 <chr>  
#>  1       1     0   Inf auclast              3.47   "AUC: lin up/log dow… NA     
#>  2       1     0   Inf tmax                 0      ""                    NA     
#>  3       1     0   Inf tlast                3      ""                    NA     
#>  4       1     0   Inf clast.obs            1      ""                    NA     
#>  5       1     0   Inf lambda.z             0.0953 ""                    NA     
#>  6       1     0   Inf r.squared            1      ""                    NA     
#>  7       1     0   Inf adj.r.squared        1      ""                    NA     
#>  8       1     0   Inf lambda.z.corrxy     -1      ""                    NA     
#>  9       1     0   Inf lambda.z.time.first  1      ""                    NA     
#> 10       1     0   Inf lambda.z.time.last   3      ""                    NA     
#> 11       1     0   Inf lambda.z.n.points    3      ""                    NA     
#> 12       1     0   Inf clast.pred           1      ""                    NA     
#> 13       1     0   Inf half.life            7.27   ""                    NA     
#> 14       1     0   Inf span.ratio           0.275  ""                    NA     
#> 15       1     0   Inf aucinf.obs          14.0    "AUC: lin up/log dow… aucpex…
#> 16       1     0   Inf aucpext.obs         75.1    ""                    aucpex…
```
