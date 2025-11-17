# Choose either the value from an option list or the current set value for an option.

Choose either the value from an option list or the current set value for
an option.

## Usage

``` r
PKNCA.choose.option(name, value = NULL, options = list())
```

## Arguments

- name:

  The option name requested.

- value:

  A value to check for the option (`NULL` to choose not to check the
  value).

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

The value of the option first from the `options` list and if it is not
there then from the current settings.

## See also

Other PKNCA calculation and summary settings:
[`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md),
[`PKNCA.set.summary()`](http://humanpred.github.io/pknca/reference/PKNCA.set.summary.md)
