# Calculate AUC for intravenous dosing

Calculate AUC for intravenous dosing

## Usage

``` r
pk.calc.auciv(conc, time, c0, auc, ..., options = list(), check = TRUE)

pk.calc.auciv_pbext(auc, auciv)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- c0:

  The concentration at time 0, typically calculated using
  [`pk.calc.c0()`](http://humanpred.github.io/pknca/reference/pk.calc.c0.md)

- auc:

  The AUC calculated using `conc` and `time` without `c0` (it may be
  calculated using any method)

- ...:

  For functions other than `pk.calc.auxc`, these values are passed to
  `pk.calc.auxc`

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md),
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md),
  and
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)?

- auciv:

  The AUC calculated using `c0`

## Value

`pk.calc.auciv`: The AUC calculated using `c0`

`pk.calc.auciv_pctbackextrap`: The AUC percent back-extrapolated

## Details

The AUC for intravenous (IV) dosing extrapolates the AUC back from the
first measurement to time 0 using c0 and the AUC calculated by another
method (for example the auclast).

The calculation method takes the following steps:

- `time = 0` must be present in the data with a measured concentration.

- The AUC between `time = 0` and the next time point is calculated
  (`auc_first`).

- The AUC between `time = 0` with `c0` and the next time point is
  calculated (`auc_second`).

- The final AUC is the initial AUC plus the difference between the two
  AUCs (`auc_final <- auc + auc_second - auc_first`).

The calculation for back-extrapolation is `100*(1 - auc/auciv)`.

## Functions

- `pk.calc.auciv_pbext()`: Calculate the percent back-extrapolated AUC
  for IV administration
