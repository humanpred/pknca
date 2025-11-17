# Extract the best model from a list of models using the AIC.

Extract the best model from a list of models using the AIC.

## Usage

``` r
get.best.model(object, ...)
```

## Arguments

- object:

  the list of models

- ...:

  Parameters passed to AIC.list

## Value

The model which is assessed as best. If more than one are equal, the
first is chosen.
