# Calculate the AUC above a given concentration

Concentrations below the given concentration (`conc_above`) will be set
to zero.

## Usage

``` r
pk.calc.aucabove(conc, time, conc_above = NA_real_, ..., options = list())
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- conc_above:

  The concentration to be above

- ...:

  Extra arguments. Currently, the only extra argument that is used is
  `method` as described in the details section.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

The AUC of the concentration above the limit
