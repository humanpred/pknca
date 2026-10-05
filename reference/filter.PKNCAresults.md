# dplyr filtering for PKNCA

Filtering a `PKNCAconc` or `PKNCAdose` object filters its data.
Filtering a `PKNCAresults` object filters the result table and, when the
filter only uses group columns (the columns after the `|` in the
`PKNCAconc` formula), the concentration data, the dose data, and the
intervals of `x$data` as well, so that the filtered results are
consistent with their data. Only those three are filtered; `group_ref`
and `units` of the `PKNCAdata` are not.

## Usage

``` r
# S3 method for class 'PKNCAresults'
filter(.data, ..., .by = NULL, .preserve = FALSE)

# S3 method for class 'PKNCAconc'
filter(.data, ..., .by = NULL, .preserve = FALSE)

# S3 method for class 'PKNCAdose'
filter(.data, ..., .by = NULL, .preserve = FALSE)
```

## Arguments

- .data:

  A data frame, data frame extension (e.g. a tibble), or a lazy data
  frame (e.g. from dbplyr or dtplyr). See *Methods*, below, for more
  details.

- ...:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Expressions that return a logical vector, defined in terms of the
  variables in `.data`. If multiple expressions are included, they are
  combined with the `&` operator. To combine expressions using `|`
  instead, wrap them in
  [`when_any()`](https://dplyr.tidyverse.org/reference/when-any-all.html).
  Only rows for which all expressions evaluate to `TRUE` are kept (for
  [`filter()`](https://dplyr.tidyverse.org/reference/filter.html)) or
  dropped (for `filter_out()`).

- .by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optionally, a selection of columns to group by for just this
  operation, functioning as an alternative to
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html).
  For details and examples, see
  [?dplyr_by](https://dplyr.tidyverse.org/reference/dplyr_by.html).

- .preserve:

  Relevant when the `.data` input is grouped. If `.preserve = FALSE`
  (the default), the grouping structure is recalculated based on the
  resulting data, otherwise the grouping is kept as is.

## Details

The filter is evaluated once, on the result table. The groups that
remain there are the groups kept: the rows of the concentration data,
dose data, and intervals are kept when their values in the group columns
that they share with the result table match a remaining group. A table
that has none of those group columns (for example, intervals with no
group columns) is left whole, and groups that have no rows in the result
table are dropped from the data. Because the filter is evaluated only on
the results, any filter that aggregates over rows (such as
`ID == max(ID)`) keeps the same groups in every table.

A filter that uses any other column of the result table (such as
`PPTESTCD`, `PPORRES`, or `exclude`), or that uses no column of the
result table, filters the result table only. Columns are recognized when
the expressions name them (`part == "SAD"`, `.data$part == "SAD"`, and
the columns of `.by`). Variables of the calling environment are not
treated as columns. Filters that choose columns without naming them
(`.data[[var]]`, `across()`, `if_any()`, `if_all()`, `pick()`, and
tidyselect helpers such as `all_of()` or `starts_with()`) filter the
result table only, with a message that the data were not filtered. The
columns `start` and `end` belong to the result table, so a filter on
them leaves the data unchanged.

[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) and the
joins change only the result table; assigning into the object directly
is the caller's responsibility and is not tracked.

A `PKNCAresults` object that a PKNCA dplyr verb changes
([`filter()`](https://dplyr.tidyverse.org/reference/filter.html),
[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
[`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html),
[`ungroup()`](https://dplyr.tidyverse.org/reference/group_by.html), and
the joins) no longer matches the hash that
[`checkProvenance()`](https://humanpred.github.io/pknca/reference/checkProvenance.md)
verifies: the hash is replaced by a marker such as
`"filtered from <hash>"` and
[`checkProvenance()`](https://humanpred.github.io/pknca/reference/checkProvenance.md)
returns `FALSE`. A call that leaves the object identical keeps its
provenance.

## See also

Other dplyr verbs:
[`group_by.PKNCAresults()`](https://humanpred.github.io/pknca/reference/group_by.PKNCAresults.md),
[`inner_join.PKNCAresults()`](https://humanpred.github.io/pknca/reference/inner_join.PKNCAresults.md),
[`mutate.PKNCAresults()`](https://humanpred.github.io/pknca/reference/mutate.PKNCAresults.md)
