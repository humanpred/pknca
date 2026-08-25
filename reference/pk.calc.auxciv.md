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
  fun_auxc,
  auc.type = NULL,
  lambda.z = NA,
  clast = NA,
  ...,
  options = list(),
  check = TRUE
)

pk.calc.auciv(
  conc,
  time,
  c0,
  auc,
  auc.type = NULL,
  lambda.z = NA,
  clast = NA,
  ...,
  options = list(),
  check = TRUE
)

pk.calc.auciv_pbext(
  conc,
  time,
  auc,
  auciv,
  ...,
  options = list(),
  check = TRUE
)

pk.calc.aumciv(
  conc,
  time,
  c0,
  aumc,
  auc.type = NULL,
  lambda.z = NA,
  clast = NA,
  ...,
  options = list(),
  check = TRUE
)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- c0:

  The concentration at time 0, typically calculated using
  [`pk.calc.c0()`](https://humanpred.github.io/pknca/reference/pk.calc.c0.md)

- auxc:

  The AUXC calculated using `conc` and `time` without `c0` (it may be
  calculated using any method)

- fun_auxc_last:

  Function to calculate the AUXC for the last interval (e.g.,
  `pk.calc.auc.last` or `pk.calc.aumc.last`)

- fun_auxc:

  Function to calculate the AUXC over the full interval when `auxc`
  could not be calculated (e.g., `pk.calc.auc` or `pk.calc.aumc`)

- auc.type:

  The type of AUXC for `fun_auxc` to calculate. `NULL` (the default)
  means that the AUXC will not be calculated from `c0` and the measured
  data, so `NA` is returned when `auxc` is `NA`.

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- clast:

  The last concentration above the limit of quantification, used by
  `fun_auxc` when `auc.type` is `"AUCinf"` (`clast.obs` gives AUCinf,obs
  and `clast.pred` gives AUCinf,pred)

- ...:

  For functions other than `pk.calc.auxc`, these values are passed to
  `pk.calc.auxc`

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- check:

  Run
  [`assert_conc_time()`](https://humanpred.github.io/pknca/reference/assert_conc_time.md)?

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

How the calculation proceeds depends on what is measured at `time = 0`:

- A concentration is measured at `time = 0`:

  The AUXC between `time = 0` and the next time point is calculated with
  the measured concentration (`auxc_first`) and with `c0`
  (`auxc_second`). The final AUXC is `auxc + auxc_second - auxc_first`.

- No concentration at `time = 0` and `auxc` was calculated:

  `auxc` comes from a method that extrapolates back to `time = 0` with
  `conc.origin` (zero; the `aucint` family), so that segment is replaced
  by the one using `c0` in the same way.

- No concentration at `time = 0` and `auxc` is `NA`:

  `auxc` is `NA` because an AUXC may not start before the first
  measurement. `c0` supplies that measurement, so the AUXC is calculated
  here from `c0` and the measured data using `fun_auxc` and `auc.type`.

The calculation for back-extrapolation is `100*(1 - auc/auciv)`. It
requires a measured concentration at time 0; without one, `auc` does not
describe the observed part of `auciv` (it either cannot be calculated
or, for the `aucint` family, already extrapolates back to time 0 with
`conc.origin`), so `NA` is returned.

## Functions

- `pk.calc.auciv()`: Calculate AUC for intravenous dosing with C0
  back-extrapolation

- `pk.calc.auciv_pbext()`: Calculate the percent back-extrapolated AUC
  for IV administration

- `pk.calc.aumciv()`: Calculate AUMC for intravenous dosing with C0
  back-extrapolation

## See also

Other AUC calculations:
[`pk.calc.auxc()`](https://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.auxcint()`](https://humanpred.github.io/pknca/reference/pk.calc.auxcint.md)

Other AUMC calculations:
[`pk.calc.auxcint()`](https://humanpred.github.io/pknca/reference/pk.calc.auxcint.md)
