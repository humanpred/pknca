# Set the dosing route

Set the dosing route

## Usage

``` r
setRoute(object, ...)

# S3 method for class 'PKNCAdose'
setRoute(object, route, ...)
```

## Arguments

- object:

  A PKNCAdose object

- ...:

  Arguments passed to another setRoute function

- route:

  A character string indicating one of the following: the column from
  the data which indicates the route of administration, a scalar
  indicating the route of administration for all subjects, or a vector
  indicating the route of administration for each dose in the dataset.

## Value

The object with an updated route
