# Calculate AUXC (AUC or AUMC) for IV dosing with C0 back-extrapolation

Calculates AUC or AUMC for intravenous dosing, with optional
back-extrapolation to C0.

## Usage

``` r
pk.calc.auxciv(
  conc,
  time,
  c0,
  auxc,
  fun_auxc_last,
  ...,
  options = list(),
  check = TRUE
)

pk.calc.auciv(conc, time, c0, auc, ..., options = list(), check = TRUE)

pk.calc.auciv_pbext(auc, auciv)

pk.calc.aumciv(conc, time, c0, aumc, ..., options = list(), check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- c0:

  The concentration at time 0, typically calculated using
  [`pk.calc.c0()`](http://humanpred.github.io/pknca/reference/pk.calc.c0.md)

- auxc:

  The AUXC calculated using `conc` and `time` without `c0` (it may be
  calculated using any method)

- fun_auxc_last:

  Function to calculate the AUXC for the last interval (e.g.,
  `pk.calc.auc.last` or `pk.calc.aumc.last`)

- ...:

  For functions other than `pk.calc.auxc`, these values are passed to
  `pk.calc.auxc`

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)?

- auc:

  The AUC calculated without C0 back-extrapolation

- auciv:

  The AUC calculated using `c0`

- aumc:

  The AUMC calculated using `conc` and `time` without `c0`

## Value

The AUXC calculated using `c0`

`pk.calc.auciv_pctbackextrap`: The AUC percent back-extrapolated

## Details

The AUXC for intravenous (IV) dosing extrapolates the AUXC back from the
first measurement to time 0 using `c0` and the AUXC calculated by
another method (e.g., auclast or aumclast).

The calculation method takes the following steps:

1.  `time = 0` must be present in the data with a measured
    concentration.

2.  The AUXC between `time = 0` and the next time point is calculated
    (`auxc_first`).

3.  The AUXC between `time = 0` with `c0` and the next time point is
    calculated (`auxc_second`).

4.  The final AUXC is the initial AUXC plus the difference between the
    two AUXCs (`auxc_final <- auxc + auxc_second - auxc_first`).

The calculation for back-extrapolation is `100*(1 - auc/auciv)`.

## Functions

- `pk.calc.auciv()`: Calculate AUC for intravenous dosing with C0
  back-extrapolation

- `pk.calc.auciv_pbext()`: Calculate the percent back-extrapolated AUC
  for IV administration

- `pk.calc.aumciv()`: Calculate AUMC for intravenous dosing with C0
  back-extrapolation

## See also

Other AUC calculations:
[`pk.calc.auxc()`](http://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.auxcint()`](http://humanpred.github.io/pknca/reference/pk.calc.auxcint.md)

Other AUMC calculations:
[`pk.calc.auxcint()`](http://humanpred.github.io/pknca/reference/pk.calc.auxcint.md)
