# Calculate AUC and related parameters using sparse NCA methods

The AUC is calculated as:

## Usage

``` r
pk.calc.sparse_auc(
  conc,
  time,
  subject,
  method = NULL,
  auc.type = "AUClast",
  ...,
  options = list()
)

pk.calc.sparse_auclast(conc, time, subject, ..., options = list())
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

## Details

\$\$AUC=\sum\limits\_{i} w_i \bar{C}\_i\$\$

Where:

- \\AUC\\:

  is the estimated area under the concentration-time curve

- \\w_i\\:

  is the weight applied to the concentration at time i (related to the
  time which it affects, see
  [`sparse_auc_weight_linear()`](http://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md))

- \\\bar{C}\_i\\:

  is the average concentration at time i

## Functions

- `pk.calc.sparse_auclast()`: Compute the AUClast for sparse PK

## See also

Other Sparse Methods:
[`as_sparse_pk()`](http://humanpred.github.io/pknca/reference/as_sparse_pk.md),
[`sparse_auc_weight_linear()`](http://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md),
[`sparse_mean()`](http://humanpred.github.io/pknca/reference/sparse_mean.md)
