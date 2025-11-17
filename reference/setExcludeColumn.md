# Set the exclude parameter on an object

This function adds the exclude column to an object. To change the
exclude value, use the
[`exclude()`](http://humanpred.github.io/pknca/reference/exclude.md)
function.

## Usage

``` r
setExcludeColumn(object, exclude = NULL, dataname = "data")
```

## Arguments

- object:

  The object to set the exclude column on.

- exclude:

  The column name to set as the exclude value.

- dataname:

  The name of the data.frame within the object to add the exclude column
  to.

## Value

The object with an exclude column and attribute
