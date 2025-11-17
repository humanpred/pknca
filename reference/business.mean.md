# Generate functions to do the named function (e.g. mean) applying the business rules.

Generate functions to do the named function (e.g. mean) applying the
business rules.

## Usage

``` r
business.mean(x, ...)

business.sd(x, ...)

business.cv(x, ...)

business.geomean(x, ...)

business.geocv(x, ...)

business.min(x, ...)

business.max(x, ...)

business.median(x, ...)

business.range(x, ...)
```

## Arguments

- x:

  vector to be passed to the various functions

- ...:

  Additional arguments to be passed to the underlying function.

## Value

The value of the various functions or NA if too many values are missing

## Functions

- `business.sd()`: Compute the standard deviation with business rules.

- `business.cv()`: Compute the coefficient of variation with business
  rules.

- `business.geomean()`: Compute the geometric mean with business rules.

- `business.geocv()`: Compute the geometric coefficient of variation
  with business rules.

- `business.min()`: Compute the minimum with business rules.

- `business.max()`: Compute the maximum with business rules.

- `business.median()`: Compute the median with business rules.

- `business.range()`: Compute the range with business rules.

## See also

[`pk.business()`](http://humanpred.github.io/pknca/reference/pk.business.md)
