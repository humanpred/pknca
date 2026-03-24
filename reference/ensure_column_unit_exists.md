# Ensure Unit Columns Exist in PKNCA Object

Checks if specified unit columns exist in a PKNCA object (either
PKNCAconc or PKNCAdose). If the columns do not exist, it creates them
and assigns default values (NA or existing units).

## Usage

``` r
ensure_column_unit_exists(pknca_obj, unit_name)
```

## Arguments

- pknca_obj:

  A PKNCA object (either PKNCAconc or PKNCAdose).

- unit_name:

  A character vector of unit column names to ensure (concu, amountu,
  timeu...).

## Value

The updated PKNCA object with ensured unit columns.

## Details

The function performs the following steps:

1.  Checks if the specified unit columns exist in the PKNCA object.

2.  If a column does not exist, it creates the column and assigns
    default values.

3.  If not default values are provided, it assigns NA to the new column.
