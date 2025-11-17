# Calculate the covariance for two time points with sparse sampling

The calculation follows equation A3 in Holder 2001 (see references
below):

## Usage

``` r
cov_holder(sparse_pk)
```

## Arguments

- sparse_pk:

  A sparse_pk object from
  [`as_sparse_pk()`](http://humanpred.github.io/pknca/reference/as_sparse_pk.md)

## Value

A matrix with one row and one column for each element of
`sparse_pk_attribute`. The covariances are on the off diagonals, and for
simplicity of use, it also calculates the variance on the diagonal
elements.

## Details

\$\$\hat{\sigma}\_{ij} =
\sum\limits\_{k=1}^{r\_{ij}}{\frac{\left(x\_{ik} -
\bar{x}\_i\right)\left(x\_{jk} - \bar{x}\_j\right)}{\left(r\_{ij} -
1\right) + \left(1 - \frac{r\_{ij}}{r_i}\right)\left(1 -
\frac{r\_{ij}}{r_j}\right)}}\$\$

If \\r\_{ij} = 0\\, then \\\hat{\sigma}\_{ij}\\ is defined as zero
(rather than dividing by zero).

Where:

- \\\hat{\sigma}\_{ij}\\:

  The covariance of times i and j

- \\r_i\\ and \\r_j\\:

  The number of subjects (usually animals) at times i and j,
  respectively

- \\r\_{ij}{r_ij}\\:

  The number of subjects (usually animals) at both times i and j

- \\x\_{ik}\\ and \\x\_{jk}\\:

  The concentration measured for animal k at times i and j, respectively

- \\\bar{x}\_i\\ and \\\bar{x}\_j\\:

  The mean of the concentrations at times i and j, respectively

The Cauchy-Schwartz inequality is enforced for covariances to keep
correlation coefficients between -1 and 1, inclusive, as described in
equations 8 and 9 of Nedelman and Jia 1998.

## References

Holder DJ. Comments on Nedelman and Jia’s Extension of Satterthwaite’s
Approximation Applied to Pharmacokinetics. Journal of Biopharmaceutical
Statistics. 2001;11(1-2):75-79. doi:10.1081/BIP-100104199

Nedelman JR, Jia X. An extension of Satterthwaite’s approximation
applied to pharmacokinetics. Journal of Biopharmaceutical Statistics.
1998;8(2):317-328. doi:10.1080/10543409808835241
