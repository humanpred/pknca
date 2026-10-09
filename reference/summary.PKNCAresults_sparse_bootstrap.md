# Summarize the results of a sparse bootstrap

The bootstrap replicates (see
[`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md))
are summarized the way subjects are for dense data (see
[`summary.PKNCAresults()`](https://humanpred.github.io/pknca/reference/summary.PKNCAresults.md)),
with each parameter's summary statistics from
[`PKNCA.set.summary()`](https://humanpred.github.io/pknca/reference/PKNCA.set.summary.md):
for example, the geometric mean and geometric coefficient of variation
of the replicates' AUClast. `N` is the number of animals in the study,
and the caption gives the number of bootstrap replicates and the random
seed. The original data and the sparse standard errors of single
replicates are not part of the summary. For confidence intervals and
comparisons between groups, see
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md).

## Usage

``` r
# S3 method for class 'PKNCAresults_sparse_bootstrap'
summary(object, ..., drop_group = character(), summarize_n = NA)
```

## Arguments

- object:

  The results to summarize

- ...:

  Ignored.

- drop_group:

  Groups to drop from the summary, in addition to the bootstrap
  replicate

- summarize_n:

  Should a column for `N`, the number of animals in the study, be added?
  `NA` (the default) and `TRUE` add it.

## Value

A data frame of the summarized bootstrap results (see
[`summary.PKNCAresults()`](https://humanpred.github.io/pknca/reference/summary.PKNCAresults.md))

## See also

Other Sparse Methods:
[`as_sparse_pk()`](https://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`pk.calc.aucinf.obs_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucinf.obs_sparse.md),
[`pk.calc.aucivlast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucivlast_sparse.md),
[`pk.calc.auclast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.auclast_sparse.md),
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`pk.calc.sparse_aumc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_aumc.md),
[`sparse_auc_weight_linear()`](https://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md),
[`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md),
[`sparse_mean()`](https://humanpred.github.io/pknca/reference/sparse_mean.md)
