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
  reset = FALSE,
  spread_for = NULL
)
```

## Arguments

- name:

  The parameter name or a vector of parameter names. It must have
  already been defined (see
  [`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md)).

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

- spread_for:

  Optional. The name of another parameter that `name` gives the spread
  of, such as `"auclast"` for `"auclast_se"`. Where results for `name`
  are present,
  [`summary.PKNCAresults()`](https://humanpred.github.io/pknca/reference/summary.PKNCAresults.md)
  summarizes `spread_for` with these instructions: `point` is applied to
  the values of `spread_for`, `spread` to the values of `name`, and
  `description` describes the summary. `name` then has no summary column
  of its own. `spread` must be given.

## Value

All current summary settings (invisibly)

## See also

[`summary.PKNCAresults()`](https://humanpred.github.io/pknca/reference/summary.PKNCAresults.md)

Other PKNCA calculation and summary settings:
[`PKNCA.choose.option()`](https://humanpred.github.io/pknca/reference/PKNCA.choose.option.md),
[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md),
[`PKNCA_options_defaults()`](https://humanpred.github.io/pknca/reference/PKNCA_options_defaults.md)

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
