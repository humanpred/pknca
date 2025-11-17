# Calculate the weight for sparse AUC calculation with the linear-trapezoidal rule

The weight is used as the \\w_i\\ parameter in
[`pk.calc.sparse_auc()`](http://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md)

## Usage

``` r
sparse_auc_weight_linear(sparse_pk)
```

## Arguments

- sparse_pk:

  A sparse_pk object from
  [`as_sparse_pk()`](http://humanpred.github.io/pknca/reference/as_sparse_pk.md)

## Value

A numeric vector of weights for sparse AUC calculations the same length
as `sparse_pk`

## Details

\$\$w_i = \frac{\delta\_{time,i-1,i} + \delta\_{time,i,i+1}}{2}\$\$
\$\$\delta\_{time,i,i+1} = t\_{i+1} - t_i\$\$

Where:

- \\w_i\\:

  is the weight at time i

- \\\delta\_{time,i-1,i}\\ and \\\delta\_{time,i,i+1}\\:

  are the changes between time i-1 and i or i and i+1 (zero outside of
  the time range)

- \\t_i\\:

  is the time at time i

## See also

Other Sparse Methods:
[`as_sparse_pk()`](http://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`pk.calc.sparse_auc()`](http://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`sparse_mean()`](http://humanpred.github.io/pknca/reference/sparse_mean.md)
