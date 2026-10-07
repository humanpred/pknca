# Sparse estimators for the AUC and AUMC to the last measured concentration

These are the `FUN_sparse` of `auclast` and `aumclast`: with sparse PK,
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
estimates those parameters from the pooled individual samples with the
Bailer point estimate and the Nedelman-Jia/Holder standard error rather
than integrating the arithmetic-mean profile. They wrap
[`pk.calc.sparse_auclast()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md)
and
[`pk.calc.sparse_aumclast()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_aumc.md),
reporting the results under the unified parameter names.

## Usage

``` r
pk.calc.auclast_sparse(conc, time, subject, ..., options = list())

pk.calc.aumclast_sparse(conc, time, subject, ..., options = list())
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

## Value

A data.frame with the point estimate, its standard error, and the
degrees of freedom, named for the parameter (`auclast`, `auclast_se`,
and `auclast_df`, or the `aumclast` equivalents)

## Details

The sparse variance theory is defined for the linear trapezoidal rule
only, so these ignore the `auc.method` option;
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md) says
so when the option is set to anything else.

## Functions

- `pk.calc.aumclast_sparse()`: Sparse AUMClast

## See also

Other Sparse Methods:
[`as_sparse_pk()`](https://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`pk.calc.aucinf.obs_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucinf.obs_sparse.md),
[`pk.calc.aucivlast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucivlast_sparse.md),
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`pk.calc.sparse_aumc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_aumc.md),
[`sparse_auc_weight_linear()`](https://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md),
[`sparse_mean()`](https://humanpred.github.io/pknca/reference/sparse_mean.md)
