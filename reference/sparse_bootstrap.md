# Bootstrap resampling of sparse PK data

`sparse_bootstrap()` makes a new sparse
[`PKNCAconc()`](https://humanpred.github.io/pknca/reference/PKNCAconc.md)
object holding the original data and `n_boot` bootstrap replicates of
it, following the stratified nonparametric bootstrap of Shen and Machado
(2017). Each replicate resamples the animals with replacement within
each stratum, where the stratum is the set of times an animal was
sampled: each sampling time with serial sacrifice, or each batch in a
batch design. An animal's samples stay together, so the correlation
between samples from the same animal is kept.
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md) then
calculates every parameter for every replicate the same way as for the
original data (from the arithmetic-mean profile, or with the sparse
estimators). Its results summarize the replicates with
[summary()](https://humanpred.github.io/pknca/reference/summary.PKNCAresults_sparse_bootstrap.md),
and
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
compares groups with the percentile intervals of the replicates.

## Usage

``` r
sparse_bootstrap(
  object,
  n_boot = 200,
  seed = NULL,
  paired = NULL,
  replicate_col = "bootstrap"
)
```

## Arguments

- object:

  A sparse `PKNCAconc` object

- n_boot:

  The number of bootstrap replicates. The default of 200 is enough for
  the mean and standard deviation of the parameters (Takemoto et al.
  2006); percentile confidence intervals need more replicates to be
  stable.

- seed:

  The random seed for the resampling. When `NULL`, one is drawn (from
  the current random number stream) and stored in the result, so the
  replicates can always be reproduced. The random number state of the
  session is restored afterward.

- paired:

  Group columns whose levels each animal has, so they are resampled
  together (for example, the treatment of a crossover design)

- replicate_col:

  The name of the replicate group column to add

## Value

A sparse `PKNCAconc` object with the original data and the replicates.
Its `bootstrap` element records `n_boot`, `seed`, `paired`,
`replicate_col`, and the original `subject` column.

## Details

The replicates are a new group (`replicate_col`) with the values
`"original"` (the data as given) and `"bootstrap1"` through
`"bootstrap<n_boot>"`. A resampled animal gets a new subject identifier
(`<replicate_col>_subject`, the original subject with the draw number)
so that an animal drawn twice counts as two animals.

Groups named in `paired`, and the analytes (the groups after `/` in the
formula), are resampled together: an animal drawn for a replicate brings
its samples from every level of those groups. Use `paired` for a
crossover, where each animal (or eye, as in Shen and Machado 2017)
receives each treatment. Other groups (such as the treatment of a
parallel design) are resampled independently.

The `"original"` replicate holds the data as given, so the same
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md) run
also gives the estimates.

## References

Shen M, Machado SG. Bioequivalence evaluation of sparse sampling
pharmacokinetics data using bootstrap resampling method. Journal of
Biopharmaceutical Statistics. 2017;27(2):257-264.
doi:10.1080/10543406.2016.1265543

Takemoto S, Yamaoka K, Nishikawa M, Takakura Y. Histogram analysis of
pharmacokinetic parameters by bootstrap resampling from one-point
sampling data in animal experiments. Drug Metabolism and
Pharmacokinetics. 2006;21(6):458-464. doi:10.2133/dmpk.21.458

## See also

Other Sparse Methods:
[`as_sparse_pk()`](https://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`pk.calc.aucinf.obs_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucinf.obs_sparse.md),
[`pk.calc.aucivlast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.aucivlast_sparse.md),
[`pk.calc.auclast_sparse()`](https://humanpred.github.io/pknca/reference/pk.calc.auclast_sparse.md),
[`pk.calc.sparse_auc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`pk.calc.sparse_aumc()`](https://humanpred.github.io/pknca/reference/pk.calc.sparse_aumc.md),
[`sparse_auc_weight_linear()`](https://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md),
[`sparse_mean()`](https://humanpred.github.io/pknca/reference/sparse_mean.md),
[`summary.PKNCAresults_sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/summary.PKNCAresults_sparse_bootstrap.md)

## Examples

``` r
d_sparse <-
  data.frame(
    time = rep(c(0, 1, 2, 4, 8, 24), each = 3),
    conc = c(0, 0, 0, 5, 6, 4, 8, 7, 9, 6, 5, 7, 3, 2.5, 3.5, 0.6, 0.4, 0.5)
  )
d_sparse$animal <- seq_len(nrow(d_sparse))
o_conc <- PKNCAconc(d_sparse, conc ~ time | animal, sparse = TRUE)
o_conc_boot <- sparse_bootstrap(o_conc, n_boot = 20, seed = 1)
o_data_boot <-
  PKNCAdata(o_conc_boot, intervals = data.frame(start = 0, end = 24, auclast = TRUE, cmax = TRUE))
summary(pk.nca(o_data_boot))
#> The sparse estimators use the linear trapezoidal rule, so the auc.method option ("lin up/log down") does not apply to: auclast
#>  start end  N     auclast        cmax
#>      0  24 18 68.3 [5.01] 8.09 [5.61]
#> 
#> Caption: auclast, cmax: geometric mean and geometric coefficient of variation; N: number of animals in the study; summarized over 20 bootstrap replicates (seed 1)
#> 
```
