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
  the current value of the option is returned).

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

[`PKNCA.options.describe()`](https://humanpred.github.io/pknca/reference/PKNCA.options.describe.md)

Other PKNCA calculation and summary settings:
[`PKNCA.choose.option()`](https://humanpred.github.io/pknca/reference/PKNCA.choose.option.md),
[`PKNCA.set.summary()`](https://humanpred.github.io/pknca/reference/PKNCA.set.summary.md),
[`PKNCA_options_defaults()`](https://humanpred.github.io/pknca/reference/PKNCA_options_defaults.md)

## Examples

``` r

PKNCA.options()
#> $adj.r.squared.factor
#> [1] 1e-04
#> 
#> $r.squared.factor
#> [1] NA
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
#> $first.tmin
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
#> $max.hl.points
#> [1] Inf
#> 
#> $min.hl.start.time
#> [1] 0
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
#> $auto.interval.method
#> [1] "builder"
#> 
#> $auto.interval.tolerance
#> [1] 0.05
#> 
#> $single.dose.aucs
#>   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
#> 1     0  24    TRUE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#> 2     0 Inf   FALSE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#>   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
#> 1       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
#> 2       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
#>   aumcint.last aumcint.all    c0  cmax  cmin  tmax  tmin tlast tfirst clast.obs
#> 1        FALSE       FALSE FALSE FALSE FALSE FALSE FALSE FALSE  FALSE     FALSE
#> 2        FALSE       FALSE FALSE  TRUE FALSE  TRUE FALSE FALSE  FALSE     FALSE
#>   cl.last cl.all cl.int.all cl.int.last mrt.last mrt.all mrt.int.all
#> 1   FALSE  FALSE      FALSE       FALSE    FALSE   FALSE       FALSE
#> 2   FALSE  FALSE      FALSE       FALSE    FALSE   FALSE       FALSE
#>   mrt.int.last mrt.iv.last vss.last vss.iv.last vss.all vss.int.all
#> 1        FALSE       FALSE    FALSE       FALSE   FALSE       FALSE
#> 2        FALSE       FALSE    FALSE       FALSE   FALSE       FALSE
#>   vss.int.last   cav cav.int.last cav.int.all ctrough cstart   ptr  tlag
#> 1        FALSE FALSE        FALSE       FALSE   FALSE  FALSE FALSE FALSE
#> 2        FALSE FALSE        FALSE       FALSE   FALSE  FALSE FALSE FALSE
#>   deg.fluc swing  ceoi aucabove.predose.all aucabove.trough.all count_conc
#> 1    FALSE FALSE FALSE                FALSE               FALSE      FALSE
#> 2    FALSE FALSE FALSE                FALSE               FALSE      FALSE
#>   count_conc_measured totdose volpk    ae clr.last clr.obs clr.pred    fe
#> 1               FALSE   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE
#> 2               FALSE   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE
#>   ertlst ermax ertmax erint erlst ratio.cmax ratio.auclast ratio.aucint.last
#> 1  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE             FALSE
#> 2  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE             FALSE
#>   ratio.aucint.all sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast
#> 1            FALSE          FALSE         FALSE         FALSE           FALSE
#> 2            FALSE          FALSE         FALSE         FALSE           FALSE
#>   sparse_aumc_se sparse_aumc_df time_above aucivlast aucivlast_se aucivlast_df
#> 1          FALSE          FALSE      FALSE     FALSE        FALSE        FALSE
#> 2          FALSE          FALSE      FALSE     FALSE        FALSE        FALSE
#>   aucivall aucivall_se aucivall_df aucivint.last aucivint.all aucivpbextlast
#> 1    FALSE       FALSE       FALSE         FALSE        FALSE          FALSE
#> 2    FALSE       FALSE       FALSE         FALSE        FALSE          FALSE
#>   aucivpbextall aucivpbextint.last aucivpbextint.all aumcivlast aumcivlast_se
#> 1         FALSE              FALSE             FALSE      FALSE         FALSE
#> 2         FALSE              FALSE             FALSE      FALSE         FALSE
#>   aumcivlast_df aumcivall aumcivall_se aumcivall_df aumcivint.last
#> 1         FALSE     FALSE        FALSE        FALSE          FALSE
#> 2         FALSE     FALSE        FALSE        FALSE          FALSE
#>   aumcivint.all half.life r.squared adj.r.squared lambda.z.corrxy lambda.z
#> 1         FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
#> 2         FALSE      TRUE     FALSE         FALSE           FALSE    FALSE
#>   lambda.z.time.first lambda.z.time.last lambda.z.n.points clast.pred
#> 1               FALSE              FALSE             FALSE      FALSE
#> 2               FALSE              FALSE             FALSE      FALSE
#>   span.ratio tobit_residual adj_tobit_residual lambda.z.n.points_blq
#> 1      FALSE          FALSE              FALSE                 FALSE
#> 2      FALSE          FALSE              FALSE                 FALSE
#>   thalf.eff.last thalf.eff.iv.last kel.last kel.iv.last kel.all kel.int.all
#> 1          FALSE             FALSE    FALSE       FALSE   FALSE       FALSE
#> 2          FALSE             FALSE    FALSE       FALSE   FALSE       FALSE
#>   kel.int.last cl.iv.all cl.iv.last cl.ivint.all cl.ivint.last cl.sparse.last
#> 1        FALSE     FALSE      FALSE        FALSE         FALSE          FALSE
#> 2        FALSE     FALSE      FALSE        FALSE         FALSE          FALSE
#>   f.last f.int.last f.int.all mrt.sparse.last mrt.iv.all mrt.ivint.all
#> 1  FALSE      FALSE     FALSE           FALSE      FALSE         FALSE
#> 2  FALSE      FALSE     FALSE           FALSE      FALSE         FALSE
#>   mrt.ivint.last vz.all vz.int.all vz.int.last vz.iv.all vz.iv.last
#> 1          FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
#> 2          FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
#>   vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.ivint.all vss.ivint.last
#> 1        FALSE         FALSE   FALSE      FALSE         FALSE          FALSE
#> 2        FALSE         FALSE   FALSE      FALSE         FALSE          FALSE
#>   vss.sparse.last aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred
#> 1           FALSE      FALSE         FALSE         FALSE       FALSE
#> 2           FALSE       TRUE         FALSE         FALSE       FALSE
#>   aumcinf.obs aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs
#> 1       FALSE          FALSE          FALSE        FALSE          FALSE
#> 2       FALSE          FALSE          FALSE        FALSE          FALSE
#>   aucint.inf.pred aumcint.inf.obs aumcint.inf.pred aucivinf.obs aucivinf.obs_se
#> 1           FALSE           FALSE            FALSE        FALSE           FALSE
#> 2           FALSE           FALSE            FALSE        FALSE           FALSE
#>   aucivinf.obs_df aucivinf.pred aucivpbextinf.obs aucivpbextinf.pred
#> 1           FALSE         FALSE             FALSE              FALSE
#> 2           FALSE         FALSE             FALSE              FALSE
#>   aumcivinf.obs aumcivinf.obs_se aumcivinf.obs_df aumcivinf.pred aucpext.obs
#> 1         FALSE            FALSE            FALSE          FALSE       FALSE
#> 2         FALSE            FALSE            FALSE          FALSE       FALSE
#>   aucpext.pred kel.iv.all kel.ivint.all kel.ivint.last kel.sparse.last cl.obs
#> 1        FALSE      FALSE         FALSE          FALSE           FALSE  FALSE
#> 2        FALSE      FALSE         FALSE          FALSE           FALSE  FALSE
#>   cl.pred cl.int.inf.obs cl.int.inf.pred cl.iv.obs cl.iv.pred f.obs f.pred
#> 1   FALSE          FALSE           FALSE     FALSE      FALSE FALSE  FALSE
#> 2   FALSE          FALSE           FALSE     FALSE      FALSE FALSE  FALSE
#>   f.int.obs f.int.pred mrt.obs mrt.pred mrt.int.inf.obs mrt.int.inf.pred
#> 1     FALSE      FALSE   FALSE    FALSE           FALSE            FALSE
#> 2     FALSE      FALSE   FALSE    FALSE           FALSE            FALSE
#>   mrt.iv.obs mrt.iv.pred mrt.md.obs mrt.md.pred mrt.ivmd.obs mrt.ivmd.pred
#> 1      FALSE       FALSE      FALSE       FALSE        FALSE         FALSE
#> 2      FALSE       FALSE      FALSE       FALSE        FALSE         FALSE
#>   vz.obs vz.pred vz.int.inf.obs vz.int.inf.pred vz.iv.obs vz.iv.pred
#> 1  FALSE   FALSE          FALSE           FALSE     FALSE      FALSE
#> 2  FALSE   FALSE          FALSE           FALSE     FALSE      FALSE
#>   vz.sparse.last vss.obs vss.pred vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred
#> 1          FALSE   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
#> 2          FALSE   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
#>   vss.ivmd.obs vss.ivmd.pred vss.int.inf.obs vss.int.inf.pred cav.int.inf.obs
#> 1        FALSE         FALSE           FALSE            FALSE           FALSE
#> 2        FALSE         FALSE           FALSE            FALSE           FALSE
#>   cav.int.inf.pred ratio.aucinf.obs ratio.aucinf.pred thalf.eff.obs
#> 1            FALSE            FALSE             FALSE         FALSE
#> 2            FALSE            FALSE             FALSE         FALSE
#>   thalf.eff.pred thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs
#> 1          FALSE            FALSE             FALSE   FALSE    FALSE      FALSE
#> 2          FALSE            FALSE             FALSE   FALSE    FALSE      FALSE
#>   kel.iv.pred kel.int.inf.obs kel.int.inf.pred auclast.dn aucall.dn
#> 1       FALSE           FALSE            FALSE      FALSE     FALSE
#> 2       FALSE           FALSE            FALSE      FALSE     FALSE
#>   aucinf.obs.dn aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn
#> 1         FALSE          FALSE       FALSE      FALSE          FALSE
#> 2         FALSE          FALSE       FALSE      FALSE          FALSE
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
#> $hl_method
#> [1] "log-linear"
#> 
#> $sparse_lambda_z_se
#> [1] "delta"
#> 
#> $tobit_n_points_penalty
#> [1] 0
#> 
#> $tobit_optim_control
#> list()
#> 
PKNCA.options(default=TRUE)
PKNCA.options("auc.method")
#> [1] "lin up/log down"
PKNCA.options(name="auc.method")
#> [1] "lin up/log down"
PKNCA.options(auc.method="lin up/log down", min.hl.points=3)
```
