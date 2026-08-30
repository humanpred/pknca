# Calculate the ratio of a parameter between two intervals

Calculate the ratio of a parameter between two intervals

## Usage

``` r
pk.calc.ratio(test, reference)
```

## Arguments

- test:

  The parameter value in the current (test) interval

- reference:

  The parameter value in the reference interval

## Value

`test/reference`, or `NA` where the reference is missing or is not above
zero (a ratio to a zero or negative reference is not interpretable).

## See also

[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md)

## Examples

``` r
pk.calc.ratio(test = 10, reference = 20)
#> [1] 0.5
```
