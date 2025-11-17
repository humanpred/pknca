# Compute the time to steady state using nonlinear, mixed-effects modeling of trough concentrations.

Trough concentrations are selected as concentrations at the time of
dosing. An exponential curve is then fit through the data with a
different magnitude by treatment (as a factor) and a random steady-state
concentration and time to stead-state by subject (see `random.effects`
argument).

## Usage

``` r
pk.tss.monoexponential(
  ...,
  tss.fraction = 0.9,
  output = c("population", "popind", "individual", "single"),
  check = TRUE,
  verbose = FALSE
)
```

## Arguments

- ...:

  See
  [`pk.tss.data.prep()`](http://humanpred.github.io/pknca/reference/pk.tss.data.prep.md)

- tss.fraction:

  The fraction of steady-state required for calling steady-state

- output:

  Which types of outputs should be produced? `population` is the
  population estimate for time to steady-state (from an nlme model),
  `popind` is the individual estimate (from an nlme model), `individual`
  fits each individual separately with a gnls model (requires more than
  one individual; use `single` for one individual), and `single` fits
  all the data to a single gnls model.

- check:

  See
  [`pk.tss.data.prep()`](http://humanpred.github.io/pknca/reference/pk.tss.data.prep.md).

- verbose:

  Describe models as they are run, show convergence of the model (passed
  to the nlme function), and additional details while running.

## Value

A scalar float for the first time when steady-state is achieved or `NA`
if it is not observed.

## References

Maganti, L., Panebianco, D.L. & Maes, A.L. Evaluation of Methods for
Estimating Time to Steady State with Examples from Phase 1 Studies. AAPS
J 10, 141–147 (2008). https://doi.org/10.1208/s12248-008-9014-y

## See also

Other Time to steady-state calculations:
[`pk.tss()`](http://humanpred.github.io/pknca/reference/pk.tss.md),
[`pk.tss.stepwise.linear()`](http://humanpred.github.io/pknca/reference/pk.tss.stepwise.linear.md)
