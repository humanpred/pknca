# Summarize PKNCA results

Summarize PKNCA results

## Usage

``` r
# S3 method for class 'PKNCAresults'
summary(
  object,
  ...,
  drop_group = as_PKNCAconc(object)$columns$subject,
  drop_param = character(),
  summarize_n = NA,
  not_requested = ".",
  not_calculated = "NC",
  drop.group = deprecated(),
  summarize.n.per.group = deprecated(),
  not.requested.string = deprecated(),
  not.calculated.string = deprecated(),
  pretty_names = NULL,
  caption_prefix = NULL
)
```

## Arguments

- object:

  The results to summarize

- ...:

  Ignored.

- drop_group:

  Which group(s) should be dropped from the formula?

- drop_param:

  Which parameters should be excluded from the summary?

- summarize_n:

  Should a column for `N` be added (`TRUE` or `FALSE`)? `NA` means to
  automatically detect adding `N` if the data has a subject column
  indicated. Note that `N` is maximum number of parameter results for
  any parameter; if no parameters are requested for a group, then `N`
  will be `NA`.

- not_requested:

  A character string to use when a parameter summary was not requested
  for a parameter within an interval.

- not_calculated:

  A character string to use when a parameter summary was requested, but
  the point estimate AND spread calculations (if applicable) returned
  `NA`. It is described in the caption when it is used.

- drop.group, summarize.n.per.group, not.requested.string,
  not.calculated.string:

  Deprecated use `drop_group`, `not_requested`, `not_calculated`, or
  `summarize_n`, instead

- pretty_names:

  Should pretty names (easier to understand in a report) be used? `TRUE`
  is yes, `FALSE` is no, and `NULL` is yes if units are used and no if
  units are not used.

- caption_prefix:

  Prefix to prepend to the generated table caption.

## Value

A data frame of NCA parameter results summarized according to the
summarization settings.

## Details

Excluded results will not be included in the summary.

A parameter whose summary instructions name it as the spread of another
parameter (`spread_for` in
[`PKNCA.set.summary()`](https://humanpred.github.io/pknca/reference/PKNCA.set.summary.md),
such as the standard error of a sparse AUClast) has no column of its
own. Where its results are present, the other parameter is summarized
with its instructions instead: for a sparse AUClast, the estimate with
its standard error. The caption gives the summary used. A summary row
with more than one sparse estimate is an error, since each standard
error describes one estimate.

## See also

[`PKNCA.set.summary()`](https://humanpred.github.io/pknca/reference/PKNCA.set.summary.md),
[`print.summary_PKNCAresults()`](https://humanpred.github.io/pknca/reference/print.summary_PKNCAresults.md)

## Examples

``` r
conc_obj <- PKNCAconc(as.data.frame(datasets::Theoph), conc ~ Time | Subject)
d_dose <-
  unique(datasets::Theoph[
    datasets::Theoph$Time == 0,
    c("Dose", "Time", "Subject")
  ])
dose_obj <- PKNCAdose(d_dose, Dose ~ Time | Subject)
data_obj_automatic <- PKNCAdata(conc_obj, dose_obj)
results_obj_automatic <- pk.nca(data_obj_automatic)
# To get standard results run summary
summary(results_obj_automatic)
#>  start end  N     auclast        cmax               tmax                 tlag
#>      0 Inf 12 98.7 [22.5] 8.65 [17.0] 1.14 [0.630, 3.55] 0.000 [0.000, 0.000]
#>         count_conc   half.life aucinf.obs aucpext.obs        cl.obs
#>  11.0 [11.0, 11.0] 8.18 [2.12] 115 [28.4] 13.8 [6.34] 0.0398 [29.4]
#> 
#> Caption: auclast, cmax, aucinf.obs, cl.obs: geometric mean and geometric coefficient of variation; tmax, tlag, count_conc: median and range; half.life, aucpext.obs: arithmetic mean and standard deviation; N: number of subjects
#> 
# To enable numeric conversion and extraction, do not give a spread function
# and subsequently run as.numeric on the result columns.
PKNCA.set.summary(
  name = c("auclast", "cmax", "half.life", "aucinf.obs"),
  point = business.geomean,
  description = "geometric mean"
)
PKNCA.set.summary(
  name = c("tmax"),
  point = business.median,
  description = "median"
)
summary(results_obj_automatic, not_requested = "NA")
#>  start end  N auclast cmax tmax                 tlag        count_conc
#>      0 Inf 12    98.7 8.65 1.14 0.000 [0.000, 0.000] 11.0 [11.0, 11.0]
#>  half.life aucinf.obs aucpext.obs        cl.obs
#>       7.99        115 13.8 [6.34] 0.0398 [29.4]
#> 
#> Caption: auclast, cmax, half.life, aucinf.obs: geometric mean; tmax: median; tlag, count_conc: median and range; aucpext.obs: arithmetic mean and standard deviation; cl.obs: geometric mean and geometric coefficient of variation; N: number of subjects
#> 
```
