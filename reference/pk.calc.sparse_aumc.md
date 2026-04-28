# Calculate AUMC and related parameters using sparse NCA methods

The AUMC is calculated as:

## Usage

``` r
pk.calc.sparse_aumc(
  conc,
  time,
  subject,
  method = NULL,
  auc.type = "AUClast",
  ...,
  options = list()
)

pk.calc.sparse_aumclast(conc, time, subject, ..., options = list())
```

## Arguments

- conc:

  Measured concentrations

- time:

  Time of the measurement of the concentrations

- subject:

  Subject identifiers (may be any class; may not be null)

- method:

  The method for integration (one of 'lin up/log down', 'lin-log', or
  'linear')

- auc.type:

  The type of AUC to compute. Choices are 'AUCinf', 'AUClast', and
  'AUCall'.

- ...:

  For functions other than `pk.calc.auxc`, these values are passed to
  `pk.calc.auxc`

- options:

  List of changes to the default PKNCA options (see
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md))

## Value

A data.frame with columns:

- sparse_aumc:

  The estimated AUMC

- sparse_aumc_se:

  Standard error of the AUMC estimate

- sparse_aumc_df:

  Degrees of freedom for the variance estimate

## Details

\$\$AUMC=\sum\limits\_{i} w_i \overline{t_i C_i}\$\$

Where:

- \\AUMC\\:

  is the estimated area under the first moment curve

- \\w_i\\:

  is the weight applied to time i (same as for AUC, see
  [`sparse_auc_weight_linear()`](http://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md))

- \\\overline{t_i C_i}\\:

  is the average of the moment (time × concentration) at time i

## Functions

- `pk.calc.sparse_aumclast()`: Compute the AUMClast for sparse PK

## See also

Other Sparse Methods:
[`as_sparse_pk()`](http://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`pk.calc.sparse_auc()`](http://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`sparse_auc_weight_linear()`](http://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md),
[`sparse_mean()`](http://humanpred.github.io/pknca/reference/sparse_mean.md)
