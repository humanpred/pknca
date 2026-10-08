# Sparse AUC and AUMC for IV bolus dosing with C0 back-extrapolation

These are the `FUN_sparse` of `aucivlast`, `aucivall`, `aucivinf.obs`,
`aumcivlast`, `aumcivall`, and `aumcivinf.obs`: with sparse PK and no
concentration at time 0, \\C_0\\ is back-extrapolated from the mean
profile with the methods of
[`pk.calc.c0()`](https://humanpred.github.io/pknca/reference/pk.calc.c0.md)
(log-linear from the first two means when the profile declines), and the
area from time 0 to the first sample is added to the sparse AUC (see
[`pk.calc.auclast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.auclast_sparse.md),
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md)
for AUCall, and
[`pk.calc.aucinf.obs_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucinf.obs_sparse.md)).
\\C_0\\ is a function of the means, so its uncertainty is added to the
standard error with the delta method. With the linear trapezoidal rule,
the AUMC from time 0 to the first sample does not depend on \\C_0\\. A
nonzero concentration measured at time 0 is used as \\C_0\\; a zero
there, measured or imputed (as by the `start_conc0` imputation), is not,
as for
[`pk.calc.c0()`](https://humanpred.github.io/pknca/reference/pk.calc.c0.md).

## Usage

``` r
pk.calc.aucivlast_sparse(conc, time, subject, ..., options = list())

pk.calc.aucivall_sparse(conc, time, subject, ..., options = list())

pk.calc.aucivinf.obs_sparse(
  conc,
  time,
  subject,
  lambda.z,
  lambda.z.time.first,
  lambda.z.time.last,
  lambda.z.n.points,
  ...,
  options = list()
)

pk.calc.aumcivlast_sparse(conc, time, subject, ..., options = list())

pk.calc.aumcivall_sparse(conc, time, subject, ..., options = list())

pk.calc.aumcivinf.obs_sparse(
  conc,
  time,
  subject,
  lambda.z,
  lambda.z.time.first,
  lambda.z.time.last,
  lambda.z.n.points,
  ...,
  options = list()
)
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- subject:

  Subject identifiers (may be any class; may not be null). A missing
  subject marks an imputed concentration (such as the zero that the
  `start_conc0` imputation adds at the start of an interval): a time
  where every subject is missing has a known concentration, which enters
  sparse estimates but not their variance.

- ...:

  For functions other than `pk.calc.auxc`, these values are passed to
  `pk.calc.auxc`

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

- lambda.z:

  The elimination rate of the mean profile

- lambda.z.time.first, lambda.z.time.last, lambda.z.n.points:

  The first and last time and the number of points of the half-life fit
  to the mean profile

## Value

A data.frame with the point estimate, its standard error, and the
degrees of freedom, named for the parameter (for example, `aucivlast`,
`aucivlast_se`, and `aucivlast_df`)

## Functions

- `pk.calc.aucivall_sparse()`: Sparse AUCall for IV bolus dosing

- `pk.calc.aucivinf.obs_sparse()`: Sparse AUCinf,obs for IV bolus dosing

- `pk.calc.aumcivlast_sparse()`: Sparse AUMClast for IV bolus dosing

- `pk.calc.aumcivall_sparse()`: Sparse AUMCall for IV bolus dosing

- `pk.calc.aumcivinf.obs_sparse()`: Sparse AUMCinf,obs for IV bolus
  dosing

## See also

Other Sparse Methods:
[`as_sparse_pk()`](https://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`pk.calc.aucinf.obs_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucinf.obs_sparse.md),
[`pk.calc.auclast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.auclast_sparse.md),
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`pk.calc.sparse_aumc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_aumc.md),
[`sparse_auc_weight_linear()`](https://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md),
[`sparse_mean()`](https://humanpred.github.io/pknca/reference/sparse_mean.md)
