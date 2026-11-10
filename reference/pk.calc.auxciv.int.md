# Calculate AUXC (AUC or AUMC) over an interval for IV bolus dosing with C0 back-extrapolation

Calculate AUXC (AUC or AUMC) over an interval for IV bolus dosing with
C0 back-extrapolation

## Usage

``` r
pk.calc.auxciv.int(
  conc,
  time,
  start,
  end,
  time.dose,
  route = "extravascular",
  duration.dose = 0,
  auxc,
  fun_auxcint_last,
  options = list()
)

pk.calc.auciv.int(
  conc,
  time,
  start,
  end,
  time.dose,
  route = "extravascular",
  duration.dose = 0,
  auc,
  options = list()
)

pk.calc.aumciv.int(
  conc,
  time,
  start,
  end,
  time.dose,
  route = "extravascular",
  duration.dose = 0,
  aumc,
  options = list()
)
```

## Arguments

- conc, time:

  All concentrations and their times for the group

- start, end:

  The start and end of the interval

- time.dose, route, duration.dose:

  The dose times, routes, and durations for the group (`route` and
  `duration.dose` default to an extravascular dose, as for
  [`pk.calc.aucint()`](https://humanpred.github.io/pknca/reference/pk.calc.auxcint.md),
  so a bolus must be given as `"intravascular"` with a duration of zero)

- auxc:

  The AUXC over the interval from the AUCint or AUMCint family

- fun_auxcint_last:

  The AUClast-type AUXCint function
  ([`pk.calc.aucint.last()`](https://humanpred.github.io/pknca/reference/pk.calc.auxcint.md)
  or
  [`pk.calc.aumcint.last()`](https://humanpred.github.io/pknca/reference/pk.calc.auxcint.md))
  used for the segment that is replaced

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- auc:

  The AUC over the interval from the AUCint family

- aumc:

  The AUMC over the interval from the AUMCint family

## Value

The AUXC over the interval with C0 back-extrapolated

## Details

The interval must start at an IV bolus dose. The AUXC over the interval
from the AUCint or AUMCint family (`auxc`) estimates the concentration
at the start of the interval from the profile before the dose (see
[`pk.calc.auxcint()`](https://humanpred.github.io/pknca/reference/pk.calc.auxcint.md)),
which is the trough rather than the concentration just after the bolus.
The segment from the start of the interval to the first concentration
after the dose is replaced by the one starting from \\C_0\\, which is
back-extrapolated with the methods of
[`pk.calc.c0()`](https://humanpred.github.io/pknca/reference/pk.calc.c0.md)
from the concentrations after the dose that are within the interval and
before the next dose (with BLQ and missing concentrations handled as the
AUCint handles them). A concentration measured at the dose time is taken
to be measured before the dose, as for
[`interp.extrap.conc.dose()`](https://humanpred.github.io/pknca/reference/interp.extrap.conc.md),
so it is not used as \\C_0\\.

An interval that starts at an IV infusion has nothing to
back-extrapolate, so the AUXCint is returned unchanged; an interval that
does not start at an IV dose gives `NA`.

## Functions

- `pk.calc.auciv.int()`: Calculate AUC over an interval for IV bolus
  dosing with C0 back-extrapolation

- `pk.calc.aumciv.int()`: Calculate AUMC over an interval for IV bolus
  dosing with C0 back-extrapolation

## See also

Other AUC calculations:
[`pk.calc.auxc()`](https://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
[`pk.calc.auxcint()`](https://humanpred.github.io/pknca/reference/pk.calc.auxcint.md),
[`pk.calc.auxciv()`](https://humanpred.github.io/pknca/reference/pk.calc.auxciv.md)

Other AUMC calculations:
[`pk.calc.auxcint()`](https://humanpred.github.io/pknca/reference/pk.calc.auxcint.md),
[`pk.calc.auxciv()`](https://humanpred.github.io/pknca/reference/pk.calc.auxciv.md)
