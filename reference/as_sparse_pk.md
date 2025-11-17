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

  Subject identifiers (may be any class; may not be null)

## Value

A sparse_pk object which is a list of lists. The inner lists have
elements named: "time", The time of measurement; "conc", The
concentration measured; "subject", The subject identifiers. The object
will usually be modified by future functions to add more named elements
to the inner list.

## See also

Other Sparse Methods:
[`pk.calc.sparse_auc()`](http://humanpred.github.io/pknca/reference/pk.calc.sparse_auc.md),
[`sparse_auc_weight_linear()`](http://humanpred.github.io/pknca/reference/sparse_auc_weight_linear.md),
[`sparse_mean()`](http://humanpred.github.io/pknca/reference/sparse_mean.md)
