# Add or remove an imputation method within an impute specification

Add or remove an imputation method within an impute specification

## Usage

``` r
add_impute_method(impute_vals, target_impute, after = Inf)

remove_impute_method(impute_vals, target_impute)
```

## Arguments

- impute_vals:

  Character vector of impute specifications (comma- or space-separated
  method names).

- target_impute:

  The imputation method to add or remove.

- after:

  Position for the added method, following
  [`base::append()`](https://rdrr.io/r/base/append.html): `0` makes it
  first and `Inf` makes it last. An existing occurrence is removed
  before inserting, so adding a method that is already present moves it.

## Value

A character vector of impute specifications. Removing the last method
gives `NA_character_`.
