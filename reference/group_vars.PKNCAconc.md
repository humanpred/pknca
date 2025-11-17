# Get grouping variables for a PKNCA object

Get grouping variables for a PKNCA object

## Usage

``` r
# S3 method for class 'PKNCAconc'
group_vars(x)

# S3 method for class 'PKNCAdata'
group_vars(x)

# S3 method for class 'PKNCAdose'
group_vars(x)

# S3 method for class 'PKNCAresults'
group_vars(x)
```

## Arguments

- x:

  The PKNCA object

## Value

A character vector (possibly empty) of the grouping variables

## Functions

- `group_vars(PKNCAdata)`: Get group_vars for a PKNCAdata object from
  the PKNCAconc object within

- `group_vars(PKNCAdose)`: Get group_vars for a PKNCAdose object

- `group_vars(PKNCAresults)`: Get group_vars for a PKNCAresults object
  from the PKNCAconc object within
