# Get the name of the element containing the data for the current object.

Get the name of the element containing the data for the current object.

## Usage

``` r
# S3 method for class 'PKNCAconc'
getDataName(object)

# S3 method for class 'PKNCAdose'
getDataName(object)

# S3 method for class 'PKNCAresults'
getDataName(object)

getDataName(object)

# Default S3 method
getDataName(object)
```

## Arguments

- object:

  The object to get the data name from.

## Value

A character scalar with the name of the data object (or `NULL` if the
method does not apply).

## Methods (by class)

- `getDataName(default)`: If no data name exists, returns NULL.

## See also

Other PKNCA object extractors:
[`getDepVar()`](http://humanpred.github.io/pknca/reference/getDepVar.md),
[`getIndepVar()`](http://humanpred.github.io/pknca/reference/getIndepVar.md)
