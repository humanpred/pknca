# Perform a Tobit half-life fit given the data. The function fits the data using maximum likelihood without any point selection or validation.

Perform a Tobit half-life fit given the data. The function fits the data
using maximum likelihood without any point selection or validation.

## Usage

``` r
fit_half_life_tobit(data, tlast, optim_control = list())
```

## Arguments

- data:

  The data to fit. Must have columns named `"log_conc"`, `"time"`,
  `"log_lloq"`, and `"mask_blq"`. `log_conc` for BLQ observations is not
  used (the likelihood uses `log_lloq` instead).

- tlast:

  The time of last observed concentration above the lower limit of
  quantification.

- optim_control:

  A list of control parameters passed to
  [`stats::optim()`](https://rdrr.io/r/stats/optim.html).

## Value

A data.frame with one row and columns named `"lambda.z"`,
`"clast.pred"`, `"lambda.z.time.first"`, `"lambda.z.time.last"`,
`"lambda.z.n.points"`, `"lambda.z.n.points_blq"`, `"half.life"`,
`"span.ratio"`, `"tobit_residual"`, and `"adj_tobit_residual"`. Returns
`NA` for all columns if
[`stats::optim()`](https://rdrr.io/r/stats/optim.html) does not
converge, and emits a warning.

## See also

[`pk.calc.half.life()`](http://humanpred.github.io/pknca/reference/pk.calc.half.life.md),
[`fit_half_life_tobit_LL()`](http://humanpred.github.io/pknca/reference/fit_half_life_tobit_LL.md)
