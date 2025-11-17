# Compute the time to steady state using stepwise test of linear trend

A linear slope is fit through the data to find when it becomes
non-significant. Note that this is less preferred than the
`pk.tss.monoexponential` due to the fact that with more time or more
subjects the performance of the test changes (see reference).

## Usage

``` r
pk.tss.stepwise.linear(
  ...,
  min.points = 3,
  level = 0.95,
  verbose = FALSE,
  check = TRUE
)
```

## Arguments

- ...:

  See
  [`pk.tss.data.prep()`](http://humanpred.github.io/pknca/reference/pk.tss.data.prep.md)

- min.points:

  The minimum number of points required for the fit

- level:

  The confidence level required for assessment of steady-state

- verbose:

  Describe models as they are run, show convergence of the model (passed
  to the nlme function), and additional details while running.

- check:

  See
  [`pk.tss.data.prep()`](http://humanpred.github.io/pknca/reference/pk.tss.data.prep.md)

## Value

A scalar float for the first time when steady-state is achieved or `NA`
if it is not observed.

## Details

The model is fit with a different magnitude by treatment (as a factor,
if given) and a random slope by subject (if given). A minimum of
`min.points` is required to fit the model.

## References

Maganti L, Panebianco DL, Maes AL. Evaluation of Methods for Estimating
Time to Steady State with Examples from Phase 1 Studies. AAPS Journal
10(1):141-7. doi:10.1208/s12248-008-9014-y

## See also

Other Time to steady-state calculations:
[`pk.tss()`](http://humanpred.github.io/pknca/reference/pk.tss.md),
[`pk.tss.monoexponential()`](http://humanpred.github.io/pknca/reference/pk.tss.monoexponential.md)
