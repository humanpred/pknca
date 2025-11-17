# Interpolate or extrapolate concentrations using the provided method

Interpolate or extrapolate concentrations using the provided method

## Usage

``` r
interpolate_conc_linear(conc_1, conc_2, time_1, time_2, time_out)

interpolate_conc_log(conc_1, conc_2, time_1, time_2, time_out)

extrapolate_conc_lambdaz(clast, lambda.z, tlast, time_out)
```

## Arguments

- conc_1, conc_2:

  The concentration at time1 and time2

- time_1, time_2:

  The time value associated with conc1 and conc2

- time_out:

  Time when interpolation is requested

- clast:

  The concentration at the last time above the lower LOQ

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- tlast:

  The time of the last concentration above the lower limit of
  quantification (LOQ)

## Value

The interpolated or extrapolated value using the correct method
