# A compute the Area Under the (Moment) Curve

Compute the area under the curve (AUC) and the area under the moment
curve (AUMC) for pharmacokinetic (PK) data. AUC and AUMC are used for
many purposes when analyzing PK in drug development.

## Usage

``` r
pk.calc.auxc(
  conc,
  time,
  interval = c(0, Inf),
  clast = pk.calc.clast.obs(conc, time, check = FALSE),
  lambda.z = NA,
  auc.type = c("AUClast", "AUCinf", "AUCall"),
  options = list(),
  method = NULL,
  conc.blq = NULL,
  conc.na = NULL,
  check = TRUE,
  fun_linear,
  fun_log,
  fun_inf
)

pk.calc.auc(conc, time, ..., options = list())

pk.calc.auc.last(conc, time, ..., options = list())

pk.calc.auc.inf(conc, time, ..., options = list(), lambda.z)

pk.calc.auc.inf.obs(conc, time, clast.obs, ..., options = list(), lambda.z)

pk.calc.auc.inf.pred(conc, time, clast.pred, ..., options = list(), lambda.z)

pk.calc.auc.all(conc, time, ..., options = list())

pk.calc.aumc(conc, time, ..., options = list())

pk.calc.aumc.last(conc, time, ..., options = list())

pk.calc.aumc.inf(conc, time, ..., options = list(), lambda.z)

pk.calc.aumc.inf.obs(conc, time, clast.obs, ..., options = list(), lambda.z)

pk.calc.aumc.inf.pred(conc, time, clast.pred, ..., options = list(), lambda.z)

pk.calc.aumc.all(conc, time, ..., options = list())
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- interval:

  Numeric vector of two numbers for the start and end time of
  integration

- clast, clast.obs, clast.pred:

  The last concentration above the limit of quantification; this is used
  for AUCinf calculations. If provided as clast.obs (observed clast
  value, default), AUCinf is AUCinf,obs. If provided as clast.pred,
  AUCinf is AUCinf,pred.

- lambda.z:

  The elimination rate (in units of inverse time) for extrapolation

- auc.type:

  The type of AUC to compute. Choices are 'AUCinf', 'AUClast', and
  'AUCall'.

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

- method:

  The method for integration (one of 'lin up/log down', 'lin-log', or
  'linear')

- conc.blq:

  How to handle BLQ values in between the first and last above LOQ
  concentrations. (See
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md)
  for usage instructions.)

- conc.na:

  How to handle missing concentration values. (See
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)
  for usage instructions.)

- check:

  Run
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md),
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md),
  and
  [`clean.conc.na()`](http://humanpred.github.io/pknca/reference/clean.conc.na.md)?

- fun_linear:

  The function to use for integration of the linear part of the curve
  (not required for AUC or AUMC functions)

- fun_log:

  The function to use for integration of the logarithmic part of the
  curve (if log integration is used; not required for AUC or AUMC
  functions)

- fun_inf:

  The function to use for extrapolation from the final measurement to
  infinite time (not required for AUC or AUMC functions.

- ...:

  For functions other than `pk.calc.auxc`, these values are passed to
  `pk.calc.auxc`

## Value

A numeric value for the AU(M)C.

## Details

`pk.calc.auc.last` is simply a shortcut setting the `interval` parameter
to `c(0, "last")`.

Extrapolation beyond Clast occurs using the half-life and Clast,obs;
Clast,pred is not yet supported.

If all conc input are zero, then the AU(M)C is zero.

You probably do not want to call `pk.calc.auxc()`. Usually, you will
call one of the other functions for calculating AUC like
`pk.calc.auc.last()`, `pk.calc.auc.inf.obs()`, etc.

## Functions

- `pk.calc.auc()`: Compute the area under the curve

- `pk.calc.auc.last()`: Compute the AUClast.

- `pk.calc.auc.inf()`: Compute the AUCinf

- `pk.calc.auc.inf.obs()`: Compute the AUCinf with the observed Clast.

- `pk.calc.auc.inf.pred()`: Compute the AUCinf with the predicted Clast.

- `pk.calc.auc.all()`: Compute the AUCall.

- `pk.calc.aumc()`: Compute the area under the moment curve

- `pk.calc.aumc.last()`: Compute the AUMClast.

- `pk.calc.aumc.inf()`: Compute the AUMCinf

- `pk.calc.aumc.inf.obs()`: Compute the AUMCinf with the observed Clast.

- `pk.calc.aumc.inf.pred()`: Compute the AUMCinf with the predicted
  Clast.

- `pk.calc.aumc.all()`: Compute the AUMCall.

## References

Gabrielsson J, Weiner D. "Section 2.8.1 Computation methods - Linear
trapezoidal rule." Pharmacokinetic & Pharmacodynamic Data Analysis:
Concepts and Applications, 4th Edition. Stockholm, Sweden: Swedish
Pharmaceutical Press, 2000. 162-4.

Gabrielsson J, Weiner D. "Section 2.8.3 Computation methods - Log-linear
trapezoidal rule." Pharmacokinetic & Pharmacodynamic Data Analysis:
Concepts and Applications, 4th Edition. Stockholm, Sweden: Swedish
Pharmaceutical Press, 2000. 164-7.

## See also

[`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md)

Other AUC calculations:
[`pk.calc.aucint()`](http://humanpred.github.io/pknca/reference/pk.calc.aucint.md)

## Examples

``` r
myconc <- c(0, 1, 2, 1, 0.5, 0.25, 0)
mytime <- c(0, 1, 2, 3, 4,   5,    6)
pk.calc.auc(myconc, mytime, interval=c(0, 6))
#> [1] 4.524716
pk.calc.auc(myconc, mytime, interval=c(0, Inf))
#> [1] 4.524716
```
