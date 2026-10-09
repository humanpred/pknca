# Sparse estimators for the AUC and AUMC to infinity

These are the `FUN_sparse` of `aucinf.obs` and `aumcinf.obs`: with
sparse PK,
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
estimates them as the sparse AUClast or AUMClast (see
[`pk.calc.auclast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.auclast_sparse.md))
plus the extrapolation from the mean concentration at tlast with the
`lambda.z` of the mean profile, with the standard error of Yuan (1993)
and its extension to the AUMC. The `sparse_lambda_z_se` option of
[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md)
chooses whether the standard error adds the uncertainty of `lambda.z`
with the delta method (`"delta"`, the default) or treats it as known
(`"none"`, Yuan's method); see
[`vignette("v24-sparse-auc-to-infinity")`](https://humanpred.github.io/pknca/articles/v24-sparse-auc-to-infinity.md).

## Usage

``` r
pk.calc.aucinf.obs_sparse(
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

pk.calc.aumcinf.obs_sparse(
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

- lambda.z:

  The elimination rate of the mean profile

- lambda.z.time.first, lambda.z.time.last, lambda.z.n.points:

  The first and last time and the number of points of the half-life fit
  to the mean profile

- ...:

  For functions other than `pk.calc.auxc`, these values are passed to
  `pk.calc.auxc`

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

A data.frame with the point estimate, its standard error, and the
degrees of freedom, named for the parameter (`aucinf.obs`,
`aucinf.obs_se`, and `aucinf.obs_df`, or the `aumcinf.obs` equivalents)

## Functions

- `pk.calc.aumcinf.obs_sparse()`: Sparse AUMCinf,obs

## References

Yuan J. Estimation of variance for AUC in animal studies. Journal of
Pharmaceutical Sciences. 1993;82(7):761-763. doi:10.1002/jps.2600820718

## See also

Other Sparse Methods:
[`as_sparse_pk()`](https://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`pk.calc.aucivlast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucivlast_sparse.md),
[`pk.calc.auclast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.auclast_sparse.md),
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`pk.calc.sparse_aumc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_aumc.md),
[`sparse_auc_weight_linear()`](https://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md),
[`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md),
[`sparse_mean()`](https://humanpred.github.io/pknca/reference/sparse_mean.md),
[`summary.PKNCAresults_sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/summary.PKNCAresults_sparse_bootstrap.md)
