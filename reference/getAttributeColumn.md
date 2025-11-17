# Retrieve the value of an attribute column.

Retrieve the value of an attribute column.

## Usage

``` r
getAttributeColumn(object, attr_name, warn_missing = c("attr", "column"))
```

## Arguments

- object:

  The object to extract the attribute value from.

- attr_name:

  The name of the attribute to extract

- warn_missing:

  Give a warning if the "attr"ibute or "column" is missing. Character
  vector with zero, one, or both of "attr" and "column".

## Value

The value of the attribute (or `NULL` if the attribute is not set or the
column does not exist)
