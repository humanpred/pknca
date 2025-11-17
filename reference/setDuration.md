# Set the duration of dosing or measurement

Set the duration of dosing or measurement

## Usage

``` r
# S3 method for class 'PKNCAconc'
setDuration(object, duration, ...)

setDuration(object, ...)

# S3 method for class 'PKNCAdose'
setDuration(object, duration, rate, dose, ...)
```

## Arguments

- object:

  An object to set a duration on

- duration:

  The value to set for the duration or the name of the column in the
  data to use for the duration.

- ...:

  Arguments passed to another setDuration function

- rate:

  (for PKNCAdose objects only) The rate of infusion

- dose:

  (for PKNCAdose objects only) The dose amount

## Value

The object with duration set
