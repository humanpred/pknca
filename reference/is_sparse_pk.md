# Is a PKNCA object used for sparse PK?

Is a PKNCA object used for sparse PK?

## Usage

``` r
# S3 method for class 'PKNCAconc'
is_sparse_pk(object)

# S3 method for class 'PKNCAdata'
is_sparse_pk(object)

# S3 method for class 'PKNCAresults'
is_sparse_pk(object)

is_sparse_pk(object)
```

## Arguments

- object:

  The object to see if it includes sparse PK

## Value

`TRUE` if sparse and `FALSE` if dense (not sparse)
