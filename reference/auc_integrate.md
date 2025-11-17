# Support function for AUC integration

Support function for AUC integration

## Usage

``` r
auc_integrate(
  conc,
  time,
  clast,
  tlast,
  lambda.z,
  interval_method,
  fun_linear,
  fun_log,
  fun_inf
)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- clast:

  The last concentration above the limit of quantification

- tlast:

  Time of last concentration above the limit of quantification (will be
  calculated, if not provided)

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- interval_method:

  The method for integrating each interval of `conc`

- fun_linear:

  The function to use for integration of the linear part of the curve
  (not required for AUC or AUMC functions)

- fun_log:

  The function to use for integration of the logarithmic part of the
  curve (if log integration is used; not required for AUC or AUMC
  functions)

- fun_inf:

  The function to use for extrapolation from the final measurement to
  infinite time (not required for AUC or AUMC functions.
