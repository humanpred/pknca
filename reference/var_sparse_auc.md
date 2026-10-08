# Calculate the variance for the AUC of sparsely sampled PK

Equation 7.vii in Nedelman and Jia, 1998 is used for this calculation:

## Usage

``` r
var_sparse_auc(sparse_pk)
```

## Arguments

- sparse_pk:

  A sparse_pk object from
  [`as_sparse_pk()`](https://humanpred.github.io/pknca/reference/as_sparse_pk.md)

## Value

The variance of the AUC estimate with a `"df"` attribute containing its
degrees of freedom.

## Details

\$\$var\left(\hat{AUC}\right) = \sum\limits\_{i=0}^m\left(\frac{w_i^2
s_i^2}{r_i}\right) + 2\sum\limits\_{i\<j}\left(\frac{w_i w_j r\_{ij}
s\_{ij}}{r_i r_j}\right)\$\$

The degrees of freedom are the Satterthwaite approximation of equation 6
of the same paper for any sampling design, including subjects with more
than one sample (see the `"df"` attribute of the return value and
Details of
[`cov_holder()`](https://humanpred.github.io/pknca/reference/cov_holder.md)
for the covariance).

When the animals form groups sampled at exactly the same times, with no
time sampled in more than one group (serial sacrifice, batch, and
complete designs), the same variance and degrees of freedom are
calculated from the weighted sum of each animal's samples, which is much
faster for many animals. For serial sacrifice, the degrees of freedom
are then equation 6a of Nedelman, Gibiansky, and Lau (1995).

## References

Nedelman JR, Jia X. An extension of Satterthwaite’s approximation
applied to pharmacokinetics. Journal of Biopharmaceutical Statistics.
1998;8(2):317-328. doi:10.1080/10543409808835241

Holder DJ. Comments on Nedelman and Jia’s Extension of Satterthwaite’s
Approximation Applied to Pharmacokinetics. Journal of Biopharmaceutical
Statistics. 2001;11(1-2):75-79. doi:10.1081/BIP-100104199

Nedelman JR, Gibiansky E, Lau DTW. Applying Bailer's method for AUC
confidence intervals to sparse sampling. Pharmaceutical Research.
1995;12(1):124-128.
