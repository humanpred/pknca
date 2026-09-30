# Get the default values of PKNCA options without changing them

Unlike `PKNCA.options(default = TRUE)`, which resets the current options
to their defaults, this only reads the default values.

## Usage

``` r
PKNCA_options_defaults(name = NULL)
```

## Arguments

- name:

  The option name(s) requested, or `NULL` for all options.

## Value

For one `name`, the default value of that option; otherwise, a named
list of default values (all options when `name` is `NULL`).

## See also

[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md),
[`PKNCA.options.describe()`](https://humanpred.github.io/pknca/reference/PKNCA.options.describe.md)

Other PKNCA calculation and summary settings:
[`PKNCA.choose.option()`](https://humanpred.github.io/pknca/reference/PKNCA.choose.option.md),
[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md),
[`PKNCA.set.summary()`](https://humanpred.github.io/pknca/reference/PKNCA.set.summary.md)

## Examples

``` r
PKNCA_options_defaults("min.span.ratio")
#> [1] 2
# The current options are not changed
PKNCA.options(min.span.ratio = 3)
PKNCA_options_defaults("min.span.ratio")
#> [1] 2
PKNCA.options("min.span.ratio")
#> [1] 3
PKNCA.options(default = TRUE)
```
