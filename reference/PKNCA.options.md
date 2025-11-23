# Set default options for PKNCA functions

This function will set the default PKNCA options. If given no inputs, it
will provide the current option set. If given name/value pairs, it will
set the option (as in the
[`options()`](https://rdrr.io/r/base/options.html) function). If given a
name, it will return the value for the parameter. If given the `default`
option as true, it will provide the default options.

## Usage

``` r
PKNCA.options(..., default = FALSE, check = FALSE, name, value)
```

## Arguments

- ...:

  options to set or get the value for

- default:

  (re)sets all default options

- check:

  check a single option given, but do not set it (for validation of the
  values when used in another function)

- name:

  An option name to use with the `value`.

- value:

  An option value (paired with the `name`) to set or check (if `NULL`,
  ).

## Value

If...

- no arguments are given:

  returns the current options.

- a value is set (including the defaults):

  returns `NULL`

- a single value is requested:

  the current value of that option is returned as a scalar

- multiple values are requested:

  the current values of those options are returned as a list

## Details

Options are either for calculation or summary functions. Calculation
options are required for a calculation function to report a result
(otherwise the reported value will be `NA`). Summary options are used
during summarization and are used for assessing what values are included
in the summary.

See the vignette 'Options for Controlling PKNCA' for a current list of
options (`vignette("Options-for-Controlling-PKNCA", package="PKNCA")`).

## See also

[`PKNCA.options.describe()`](http://humanpred.github.io/pknca/reference/PKNCA.options.describe.md)

Other PKNCA calculation and summary settings:
[`PKNCA.choose.option()`](http://humanpred.github.io/pknca/reference/PKNCA.choose.option.md),
[`PKNCA.set.summary()`](http://humanpred.github.io/pknca/reference/PKNCA.set.summary.md)

## Examples

``` r
PKNCA.options()
#> $adj.r.squared.factor
#> [1] 1e-04
#> 
#> $max.missing
#> [1] 0.5
#> 
#> $auc.method
#> [1] "lin up/log down"
#> 
#> $conc.na
#> [1] "drop"
#> 
#> $conc.blq
#> $conc.blq$first
#> [1] "keep"
#> 
#> $conc.blq$middle
#> [1] "drop"
#> 
#> $conc.blq$last
#> [1] "keep"
#> 
#> 
#> $debug
#> NULL
#> 
#> $first.tmax
#> [1] TRUE
#> 
#> $allow.tmax.in.half.life
#> [1] FALSE
#> 
#> $keep_interval_cols
#> NULL
#> 
#> $min.hl.points
#> [1] 3
#> 
#> $min.span.ratio
#> [1] 2
#> 
#> $max.aucinf.pext
#> [1] 20
#> 
#> $min.hl.r.squared
#> [1] 0.9
#> 
#> $progress
#> [1] TRUE
#> 
#> $tau.choices
#> [1] NA
#> 
#> $single.dose.aucs
#>   start end auclast aucall aumclast aumcall aucint.last aucint.last.dose
#> 1     0  24    TRUE  FALSE    FALSE   FALSE       FALSE            FALSE
#> 2     0 Inf   FALSE  FALSE    FALSE   FALSE       FALSE            FALSE
#>   aucint.all aucint.all.dose    c0  cmax  cmin  tmax tlast tfirst clast.obs
#> 1      FALSE           FALSE FALSE FALSE FALSE FALSE FALSE  FALSE     FALSE
#> 2      FALSE           FALSE FALSE  TRUE FALSE  TRUE FALSE  FALSE     FALSE
#>   cl.last cl.all     f mrt.last mrt.iv.last vss.last vss.iv.last   cav
#> 1   FALSE  FALSE FALSE    FALSE       FALSE    FALSE       FALSE FALSE
#> 2   FALSE  FALSE FALSE    FALSE       FALSE    FALSE       FALSE FALSE
#>   cav.int.last cav.int.all ctrough cstart   ptr  tlag deg.fluc swing  ceoi
#> 1        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
#> 2        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
#>   aucabove.predose.all aucabove.trough.all count_conc count_conc_measured
#> 1                FALSE               FALSE      FALSE               FALSE
#> 2                FALSE               FALSE      FALSE               FALSE
#>   totdose volpk    ae clr.last clr.obs clr.pred    fe sparse_auclast
#> 1   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE          FALSE
#> 2   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE          FALSE
#>   sparse_auc_se sparse_auc_df time_above aucivlast aucivall aucivint.last
#> 1         FALSE         FALSE      FALSE     FALSE    FALSE         FALSE
#> 2         FALSE         FALSE      FALSE     FALSE    FALSE         FALSE
#>   aucivint.all aucivpbextlast aucivpbextall aucivpbextint.last
#> 1        FALSE          FALSE         FALSE              FALSE
#> 2        FALSE          FALSE         FALSE              FALSE
#>   aucivpbextint.all half.life r.squared adj.r.squared lambda.z.corrxy lambda.z
#> 1             FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
#> 2             FALSE      TRUE     FALSE         FALSE           FALSE    FALSE
#>   lambda.z.time.first lambda.z.time.last lambda.z.n.points clast.pred
#> 1               FALSE              FALSE             FALSE      FALSE
#> 2               FALSE              FALSE             FALSE      FALSE
#>   span.ratio thalf.eff.last thalf.eff.iv.last kel.last kel.iv.last aucinf.obs
#> 1      FALSE          FALSE             FALSE    FALSE       FALSE      FALSE
#> 2      FALSE          FALSE             FALSE    FALSE       FALSE       TRUE
#>   aucinf.pred aumcinf.obs aumcinf.pred aucint.inf.obs aucint.inf.obs.dose
#> 1       FALSE       FALSE        FALSE          FALSE               FALSE
#> 2       FALSE       FALSE        FALSE          FALSE               FALSE
#>   aucint.inf.pred aucint.inf.pred.dose aucivinf.obs aucivinf.pred
#> 1           FALSE                FALSE        FALSE         FALSE
#> 2           FALSE                FALSE        FALSE         FALSE
#>   aucivpbextinf.obs aucivpbextinf.pred aucpext.obs aucpext.pred cl.obs cl.pred
#> 1             FALSE              FALSE       FALSE        FALSE  FALSE   FALSE
#> 2             FALSE              FALSE       FALSE        FALSE  FALSE   FALSE
#>   mrt.obs mrt.pred mrt.iv.obs mrt.iv.pred mrt.md.obs mrt.md.pred vz.obs vz.pred
#> 1   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE  FALSE   FALSE
#> 2   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE  FALSE   FALSE
#>   vss.obs vss.pred vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred
#> 1   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
#> 2   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
#>   cav.int.inf.obs cav.int.inf.pred thalf.eff.obs thalf.eff.pred
#> 1           FALSE            FALSE         FALSE          FALSE
#> 2           FALSE            FALSE         FALSE          FALSE
#>   thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs kel.iv.pred
#> 1            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
#> 2            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
#>   auclast.dn aucall.dn aucinf.obs.dn aucinf.pred.dn aumclast.dn aumcall.dn
#> 1      FALSE     FALSE         FALSE          FALSE       FALSE      FALSE
#> 2      FALSE     FALSE         FALSE          FALSE       FALSE      FALSE
#>   aumcinf.obs.dn aumcinf.pred.dn cmax.dn cmin.dn clast.obs.dn clast.pred.dn
#> 1          FALSE           FALSE   FALSE   FALSE        FALSE         FALSE
#> 2          FALSE           FALSE   FALSE   FALSE        FALSE         FALSE
#>   cav.dn ctrough.dn clr.last.dn clr.obs.dn clr.pred.dn
#> 1  FALSE      FALSE       FALSE      FALSE       FALSE
#> 2  FALSE      FALSE       FALSE      FALSE       FALSE
#> 
#> $allow_partial_missing_units
#> [1] FALSE
#> 
PKNCA.options(default=TRUE)
PKNCA.options("auc.method")
#> [1] "lin up/log down"
PKNCA.options(name="auc.method")
#> [1] "lin up/log down"
PKNCA.options(auc.method="lin up/log down", min.hl.points=3)
```
