# Choose how to interpolate, extrapolate, or integrate data in each concentration interval

Choose how to interpolate, extrapolate, or integrate data in each
concentration interval

## Usage

``` r
choose_interval_method(conc, time, tlast, method, auc.type, options)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- tlast:

  Time of last concentration above the limit of quantification (will be
  calculated, if not provided)

- method:

  The method for integration (one of 'lin up/log down', 'lin-log', or
  'linear')

- auc.type:

  The type of AUC to compute. Choices are 'AUCinf', 'AUClast', and
  'AUCall'.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

A character vector of methods for interpolation/extrapolation methods
that is the same length as `conc` which indicates how to
interpolate/integrate between each of the concentrations (all but the
last value in the vector) and how to extrapolate after `tlast` (the last
item in the vector). Possible values in the vector are: 'zero',
'linear', 'log', and 'extrap_log'
