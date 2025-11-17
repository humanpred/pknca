# Update existing PKNCAresults with new data

The only thing that can change in the update is the concentration or
dose data. All other items (column definitions, etc) must remain the
same. If options are not set in `data`, then the default PKNCA options
will be considered identical.

## Usage

``` r
# S3 method for class 'PKNCAresults'
update(object, data, ...)
```

## Arguments

- object:

  The PKNCAresults data

- data:

  The new PKNCAdata object

- ...:

  Ignored

## Value

The PKNCAresults with updated new data

## Details

If more than the allowed settings change, then a full recalculation will
occur.

This function is typically used with Shiny apps which may repeat
analyses with small changes (e.g. point exclusion).
