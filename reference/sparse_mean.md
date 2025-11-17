# Calculate the mean concentration at all time points for use in sparse NCA calculations

Choices for the method of calculation (the argument
`sparse_mean_method`) are:

## Usage

``` r
sparse_mean(
  sparse_pk,
  sparse_mean_method = c("arithmetic mean, <=50% BLQ", "arithmetic mean")
)
```

## Arguments

- sparse_pk:

  A sparse_pk object from
  [`as_sparse_pk()`](http://humanpred.github.io/pknca/reference/as_sparse_pk.md)

- sparse_mean_method:

  The method used to calculate the sparse mean (see details)

## Value

A vector the same length as `sparse_pk` with the mean concentration at
each of those times.

## Details

- "arithmetic mean":

  Arithmetic mean (ignoring number of BLQ samples)

- "arithmetic mean, \<=50% BLQ":

  If \>= 50% of the measurements are BLQ, zero. Otherwise, the
  arithmetic mean of all samples (including the BLQ as zero).

## See also

Other Sparse Methods:
[`as_sparse_pk()`](http://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`pk.calc.sparse_auc()`](http://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`sparse_auc_weight_linear()`](http://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md)
