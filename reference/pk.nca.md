# Compute NCA parameters for each interval for each subject.

The `pk.nca` function computes the NCA parameters from a `PKNCAdata`
object. All options for the calculation and input data are set in prior
functions (`PKNCAconc`, `PKNCAdose`, and `PKNCAdata`). Options for
calculations are set either in `PKNCAdata` or with the current default
options in `PKNCA.options`.

## Usage

``` r
pk.nca(data, verbose = FALSE)
```

## Arguments

- data:

  A PKNCAdata object

- verbose:

  Indicate, by [`message()`](https://rdrr.io/r/base/message.html), the
  current state of calculation.

## Value

A `PKNCAresults` object.

## Details

When performing calculations, all time results are relative to the start
of the interval. For example, if an interval starts at 168 hours, ends
at 192 hours, and and the maximum concentration is at 169 hours,
`tmax=169-168=1`.

## See also

[`PKNCAdata()`](http://humanpred.github.io/pknca/reference/PKNCAdata.md),
[`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md),
[`summary.PKNCAresults()`](http://humanpred.github.io/pknca/reference/summary.PKNCAresults.md),
[`as.data.frame.PKNCAresults()`](http://humanpred.github.io/pknca/reference/as.data.frame.PKNCAresults.md),
[`exclude()`](http://humanpred.github.io/pknca/reference/exclude.md)
