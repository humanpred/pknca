# Generate a sparse_pk object

Generate a sparse_pk object

## Usage

``` r
as_sparse_pk(conc, time, subject)
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

## Value

A sparse_pk object which is a list of lists. The inner lists have
elements named: "time", The time of measurement; "conc", The
concentration measured; "subject", The subject identifiers; "imputed",
Whether the concentration at that time is imputed (known). The object
will usually be modified by future functions to add more named elements
to the inner list.

## See also

Other Sparse Methods:
[`pk.calc.aucinf.obs_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucinf.obs_sparse.md),
[`pk.calc.aucivlast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucivlast_sparse.md),
[`pk.calc.auclast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.auclast_sparse.md),
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`pk.calc.sparse_aumc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_aumc.md),
[`sparse_auc_weight_linear()`](https://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md),
[`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md),
[`sparse_mean()`](https://humanpred.github.io/pknca/reference/sparse_mean.md),
[`summary.PKNCAresults_sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/summary.PKNCAresults_sparse_bootstrap.md)
