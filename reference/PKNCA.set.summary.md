# Define how NCA parameters are summarized.

Define how NCA parameters are summarized.

## Usage

``` r
PKNCA.set.summary(
  name,
  description,
  point,
  spread,
  rounding = list(signif = 3),
  reset = FALSE
)
```

## Arguments

- name:

  The parameter name or a vector of parameter names. It must have
  already been defined (see
  [`add.interval.col()`](http://humanpred.github.io/pknca/reference/add.interval.col.md)).

- description:

  A single-line description of the summary

- point:

  The function to calculate the point estimate for the summary. The
  function will be called as `point(x)` and must return a scalar value
  (typically a number, NA, or a string).

- spread:

  Optional. The function to calculate the spread (or variability). The
  function will be called as `spread(x)` and must return a scalar or
  two-long vector (typically a number, NA, or a string).

- rounding:

  Instructions for how to round the value of point and spread. It may
  either be a list or a function. If it is a list, then it must have a
  single entry with a name of either "signif" or "round" and a value of
  the digits to round. If a function, it is expected to return a scalar
  number or character string with the correct results for an input of
  either a scalar or a two-long vector.

- reset:

  Reset all the summary instructions to no instruction (this is not
  intended for general use)

## Value

All current summary settings (invisibly)

## See also

[`summary.PKNCAresults()`](http://humanpred.github.io/pknca/reference/summary.PKNCAresults.md)

Other PKNCA calculation and summary settings:
[`PKNCA.choose.option()`](http://humanpred.github.io/pknca/reference/PKNCA.choose.option.md),
[`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md)

## Examples

``` r
if (FALSE) { # \dontrun{
PKNCA.set.summary(
  name="half.life",
  description="arithmetic mean and standard deviation",
  point=business.mean,
  spread=business.sd,
  rounding=list(signif=3)
)
} # }
```
