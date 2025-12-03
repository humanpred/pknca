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
#>   aucint.all aucint.all.dose aumcint.last aumcint.last.dose aumcint.all
#> 1      FALSE           FALSE        FALSE             FALSE       FALSE
#> 2      FALSE           FALSE        FALSE             FALSE       FALSE
#>   aumcint.all.dose    c0  cmax  cmin  tmax tlast tfirst clast.obs cl.last
#> 1            FALSE FALSE FALSE FALSE FALSE FALSE  FALSE     FALSE   FALSE
#> 2            FALSE FALSE  TRUE FALSE  TRUE FALSE  FALSE     FALSE   FALSE
#>   cl.all cl.int.all cl.int.last     f mrt.last mrt.all mrt.int.all mrt.int.last
#> 1  FALSE      FALSE       FALSE FALSE    FALSE   FALSE       FALSE        FALSE
#> 2  FALSE      FALSE       FALSE FALSE    FALSE   FALSE       FALSE        FALSE
#>   mrt.iv.last vss.last vss.iv.last vss.all vss.int.all vss.int.last   cav
#> 1       FALSE    FALSE       FALSE   FALSE       FALSE        FALSE FALSE
#> 2       FALSE    FALSE       FALSE   FALSE       FALSE        FALSE FALSE
#>   cav.int.last cav.int.all ctrough cstart   ptr  tlag deg.fluc swing  ceoi
#> 1        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
#> 2        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
#>   aucabove.predose.all aucabove.trough.all count_conc count_conc_measured
#> 1                FALSE               FALSE      FALSE               FALSE
#> 2                FALSE               FALSE      FALSE               FALSE
#>   totdose volpk    ae clr.last clr.obs clr.pred    fe ertlst ermax ertmax
#> 1   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE  FALSE FALSE  FALSE
#> 2   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE  FALSE FALSE  FALSE
#>   sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast sparse_aumc_se
#> 1          FALSE         FALSE         FALSE           FALSE          FALSE
#> 2          FALSE         FALSE         FALSE           FALSE          FALSE
#>   sparse_aumc_df time_above aucivlast aucivall aucivint.last aucivint.all
#> 1          FALSE      FALSE     FALSE    FALSE         FALSE        FALSE
#> 2          FALSE      FALSE     FALSE    FALSE         FALSE        FALSE
#>   aucivpbextlast aucivpbextall aucivpbextint.last aucivpbextint.all aumcivlast
#> 1          FALSE         FALSE              FALSE             FALSE      FALSE
#> 2          FALSE         FALSE              FALSE             FALSE      FALSE
#>   aumcivall aumcivint.last aumcivint.all half.life r.squared adj.r.squared
#> 1     FALSE          FALSE         FALSE     FALSE     FALSE         FALSE
#> 2     FALSE          FALSE         FALSE      TRUE     FALSE         FALSE
#>   lambda.z.corrxy lambda.z lambda.z.time.first lambda.z.time.last
#> 1           FALSE    FALSE               FALSE              FALSE
#> 2           FALSE    FALSE               FALSE              FALSE
#>   lambda.z.n.points clast.pred span.ratio thalf.eff.last thalf.eff.iv.last
#> 1             FALSE      FALSE      FALSE          FALSE             FALSE
#> 2             FALSE      FALSE      FALSE          FALSE             FALSE
#>   kel.last kel.iv.last kel.all kel.int.all kel.int.last cl.iv.all cl.iv.last
#> 1    FALSE       FALSE   FALSE       FALSE        FALSE     FALSE      FALSE
#> 2    FALSE       FALSE   FALSE       FALSE        FALSE     FALSE      FALSE
#>   cl.ivint.all cl.ivint.last cl.sparse.last mrt.sparse.last mrt.iv.all
#> 1        FALSE         FALSE          FALSE           FALSE      FALSE
#> 2        FALSE         FALSE          FALSE           FALSE      FALSE
#>   mrt.ivint.all mrt.ivint.last vz.all vz.int.all vz.int.last vz.iv.all
#> 1         FALSE          FALSE  FALSE      FALSE       FALSE     FALSE
#> 2         FALSE          FALSE  FALSE      FALSE       FALSE     FALSE
#>   vz.iv.last vz.ivint.all vz.ivint.last vz.last vz.sparse.last vss.iv.all
#> 1      FALSE        FALSE         FALSE   FALSE          FALSE      FALSE
#> 2      FALSE        FALSE         FALSE   FALSE          FALSE      FALSE
#>   vss.ivint.all vss.ivint.last vss.sparse.last aucinf.obs aucinf.pred
#> 1         FALSE          FALSE           FALSE      FALSE       FALSE
#> 2         FALSE          FALSE           FALSE       TRUE       FALSE
#>   aumcinf.obs aumcinf.pred aucint.inf.obs aucint.inf.obs.dose aucint.inf.pred
#> 1       FALSE        FALSE          FALSE               FALSE           FALSE
#> 2       FALSE        FALSE          FALSE               FALSE           FALSE
#>   aucint.inf.pred.dose aumcint.inf.obs aumcint.inf.obs.dose aumcint.inf.pred
#> 1                FALSE           FALSE                FALSE            FALSE
#> 2                FALSE           FALSE                FALSE            FALSE
#>   aumcint.inf.pred.dose aucivinf.obs aucivinf.pred aucivpbextinf.obs
#> 1                 FALSE        FALSE         FALSE             FALSE
#> 2                 FALSE        FALSE         FALSE             FALSE
#>   aucivpbextinf.pred aumcivinf.obs aumcivinf.pred aucpext.obs aucpext.pred
#> 1              FALSE         FALSE          FALSE       FALSE        FALSE
#> 2              FALSE         FALSE          FALSE       FALSE        FALSE
#>   kel.iv.all kel.ivint.all kel.ivint.last kel.sparse.last cl.obs cl.pred
#> 1      FALSE         FALSE          FALSE           FALSE  FALSE   FALSE
#> 2      FALSE         FALSE          FALSE           FALSE  FALSE   FALSE
#>   cl.int.inf.obs cl.int.inf.pred cl.iv.obs cl.iv.pred mrt.obs mrt.pred
#> 1          FALSE           FALSE     FALSE      FALSE   FALSE    FALSE
#> 2          FALSE           FALSE     FALSE      FALSE   FALSE    FALSE
#>   mrt.int.inf.obs mrt.int.inf.pred mrt.iv.obs mrt.iv.pred mrt.md.obs
#> 1           FALSE            FALSE      FALSE       FALSE      FALSE
#> 2           FALSE            FALSE      FALSE       FALSE      FALSE
#>   mrt.md.pred vz.obs vz.pred vz.int.inf.obs vz.int.inf.pred vz.iv.obs
#> 1       FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#> 2       FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#>   vz.iv.pred vss.obs vss.pred vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred
#> 1      FALSE   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
#> 2      FALSE   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
#>   vss.int.inf.obs vss.int.inf.pred cav.int.inf.obs cav.int.inf.pred
#> 1           FALSE            FALSE           FALSE            FALSE
#> 2           FALSE            FALSE           FALSE            FALSE
#>   thalf.eff.obs thalf.eff.pred thalf.eff.iv.obs thalf.eff.iv.pred kel.obs
#> 1         FALSE          FALSE            FALSE             FALSE   FALSE
#> 2         FALSE          FALSE            FALSE             FALSE   FALSE
#>   kel.pred kel.iv.obs kel.iv.pred kel.int.inf.obs kel.int.inf.pred auclast.dn
#> 1    FALSE      FALSE       FALSE           FALSE            FALSE      FALSE
#> 2    FALSE      FALSE       FALSE           FALSE            FALSE      FALSE
#>   aucall.dn aucinf.obs.dn aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn
#> 1     FALSE         FALSE          FALSE       FALSE      FALSE          FALSE
#> 2     FALSE         FALSE          FALSE       FALSE      FALSE          FALSE
#>   aumcinf.pred.dn cmax.dn cmin.dn clast.obs.dn clast.pred.dn cav.dn ctrough.dn
#> 1           FALSE   FALSE   FALSE        FALSE         FALSE  FALSE      FALSE
#> 2           FALSE   FALSE   FALSE        FALSE         FALSE  FALSE      FALSE
#>   clr.last.dn clr.obs.dn clr.pred.dn
#> 1       FALSE      FALSE       FALSE
#> 2       FALSE      FALSE       FALSE
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
