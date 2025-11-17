# Estimate the concentration at dosing time for an IV bolus dose.

Estimate the concentration at dosing time for an IV bolus dose.

## Usage

``` r
pk.calc.c0(
  conc,
  time,
  time.dose = 0,
  method = c("c0", "logslope", "c1", "cmin", "set0"),
  check = TRUE
)

pk.calc.c0.method.logslope(conc, time, time.dose = 0, check = TRUE)

pk.calc.c0.method.c0(conc, time, time.dose = 0, check = TRUE)

pk.calc.c0.method.c1(conc, time, time.dose = 0, check = TRUE)

pk.calc.c0.method.set0(conc, time, time.dose = 0, check = TRUE)

pk.calc.c0.method.cmin(conc, time, time.dose = 0, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- time.dose:

  The time when dosing occurred

- method:

  The order of methods to test (see details)

- check:

  Check the `conc` and `time` inputs

## Value

The estimated concentration at time 0.

## Details

Methods available for interpolation are below, and each has its own
specific function.

- `c0`:

  If the observed `conc` at `time.dose` is nonzero, return that. This
  method should usually be used first for single-dose IV bolus data in
  case nominal time zero is measured.

- `logslope`:

  Compute the semilog line between the first two measured times, and use
  that line to extrapolate backward to `time.dose`

- `c1`:

  Use the first point after `time.dose`

- `cmin`:

  Set c0 to cmin during the interval. This method should usually be used
  for multiple-dose oral data and IV infusion data.

- `set0`:

  Set c0 to zero (regardless of any other data). This method should
  usually be used first for single-dose oral data.

## Functions

- `pk.calc.c0.method.logslope()`: Semilog regress the first and second
  points after time.dose. This method will return `NA` if the second
  `conc` after `time.dose` is 0 or greater than the first.

- `pk.calc.c0.method.c0()`: Use `C0` = `conc[time %in% time.dose]` if it
  is nonzero.

- `pk.calc.c0.method.c1()`: Use `C0` = `C1`.

- `pk.calc.c0.method.set0()`: Use `C0` = 0 (typically used for single
  dose oral and IV infusion)

- `pk.calc.c0.method.cmin()`: Use `C0` = Cmin (typically used for
  multiple dose oral and IV infusion but not IV bolus)
