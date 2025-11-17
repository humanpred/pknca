# Add an attribute to an object where the attribute is added as a name to the names of the object.

Add an attribute to an object where the attribute is added as a name to
the names of the object.

## Usage

``` r
setAttributeColumn(
  object,
  attr_name,
  col_or_value,
  col_name,
  default_value,
  stop_if_default,
  warn_if_default,
  message_if_default
)
```

## Arguments

- object:

  The object to set the attribute column on.

- attr_name:

  The attribute name to set

- col_or_value:

  If this exists as a column in the data, it is used as the `col_name`.
  If not, this becomes the `default_value`.

- col_name:

  The name of the column within the dataset to use (if missing, uses
  `attr_name`)

- default_value:

  The value to fill in the column if the column does not exist (the
  column is filled with `NA` if it does not exist and no value is
  provided).

- stop_if_default, warn_if_default, message_if_default:

  A character string to provide as an error, a warning, or a message to
  the user if the `default_value` is used. They are tested in order (if
  stop, the code stops; if warning, the message is ignored; and message
  last).

## Value

The object with the attribute column added to the data.

## See also

[`getAttributeColumn()`](http://humanpred.github.io/pknca/reference/getAttributeColumn.md)
