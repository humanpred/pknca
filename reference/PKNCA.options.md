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
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbext.int.last
#> 1        FALSE       FALSE         FALSE        FALSE               FALSE
#> 2        FALSE       FALSE         FALSE        FALSE               FALSE
#>   aucivpbext.int.all aumcivint.last aumcivint.all    c0  cmax  cmin  tmax  tmin
#> 1              FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
#> 2              FALSE          FALSE         FALSE FALSE  TRUE FALSE  TRUE FALSE
#>   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
#> 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#> 2 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#>   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
#> 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#> 2         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#>   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
#> 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#> 2         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#>   vss.int.last vss.ivint.all vss.ivint.last cav.last cav.int.last cav.int.all
#> 1        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
#> 2        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
#>   cav.all cav.ivint.last cav.ivint.all ctrough cstart   ptr  tlag deg.fluc
#> 1   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE    FALSE
#> 2   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE    FALSE
#>   swing  ceoi aucabove.predose.all aucabove.trough.all count.conc
#> 1 FALSE FALSE                FALSE               FALSE      FALSE
#> 2 FALSE FALSE                FALSE               FALSE      FALSE
#>   count.conc.measured totdose volpk    ae clr.last clr.int.inf.pred
#> 1               FALSE   FALSE FALSE FALSE    FALSE            FALSE
#> 2               FALSE   FALSE FALSE FALSE    FALSE            FALSE
#>   clr.int.inf.obs clr.int.all clr.int.last clr.all clr.inf.obs clr.inf.pred
#> 1           FALSE       FALSE        FALSE   FALSE       FALSE        FALSE
#> 2           FALSE       FALSE        FALSE   FALSE       FALSE        FALSE
#>      fe ertlst ermax ertmax erint erlst ratio.cmax ratio.auclast
#> 1 FALSE  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE
#> 2 FALSE  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE
#>   ratio.aucint.last ratio.aucint.all sparse_auclast sparse_auc_se sparse_auc_df
#> 1             FALSE            FALSE          FALSE         FALSE         FALSE
#> 2             FALSE            FALSE          FALSE         FALSE         FALSE
#>   sparse_aumclast sparse_aumc_se sparse_aumc_df time.above aucivlast
#> 1           FALSE          FALSE          FALSE      FALSE     FALSE
#> 2           FALSE          FALSE          FALSE      FALSE     FALSE
#>   aucivlast_se aucivlast_df aucivall aucivall_se aucivall_df aucivpbext.last
#> 1        FALSE        FALSE    FALSE       FALSE       FALSE           FALSE
#> 2        FALSE        FALSE    FALSE       FALSE       FALSE           FALSE
#>   aucivpbext.all aumcivlast aumcivlast_se aumcivlast_df aumcivall aumcivall_se
#> 1          FALSE      FALSE         FALSE         FALSE     FALSE        FALSE
#> 2          FALSE      FALSE         FALSE         FALSE     FALSE        FALSE
#>   aumcivall_df half.life r.squared adj.r.squared lambda.z.corrxy lambda.z
#> 1        FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
#> 2        FALSE      TRUE     FALSE         FALSE           FALSE    FALSE
#>   lambda.z.time.first lambda.z.time.last lambda.z.n.points clast.pred
#> 1               FALSE              FALSE             FALSE      FALSE
#> 2               FALSE              FALSE             FALSE      FALSE
#>   span.ratio tobit.residual adj.tobit.residual lambda.z.n.points.blq
#> 1      FALSE          FALSE              FALSE                 FALSE
#> 2      FALSE          FALSE              FALSE                 FALSE
#>   thalf.eff.last thalf.eff.int.all thalf.eff.int.last thalf.eff.all
#> 1          FALSE             FALSE              FALSE         FALSE
#> 2          FALSE             FALSE              FALSE         FALSE
#>   thalf.eff.iv.last thalf.eff.ivint.all thalf.eff.ivint.last kel.last
#> 1             FALSE               FALSE                FALSE    FALSE
#> 2             FALSE               FALSE                FALSE    FALSE
#>   kel.iv.last kel.all kel.int.all kel.int.last kel.ivint.all kel.ivint.last
#> 1       FALSE   FALSE       FALSE        FALSE         FALSE          FALSE
#> 2       FALSE   FALSE       FALSE        FALSE         FALSE          FALSE
#>   cl.iv.all cl.iv.last cl.sparse.last f.last f.all f.int.last f.int.all
#> 1     FALSE      FALSE          FALSE  FALSE FALSE      FALSE     FALSE
#> 2     FALSE      FALSE          FALSE  FALSE FALSE      FALSE     FALSE
#>   mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last vz.iv.all vz.iv.last
#> 1           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
#> 2           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
#>   vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.sparse.last cav.iv.last
#> 1        FALSE         FALSE   FALSE      FALSE           FALSE       FALSE
#> 2        FALSE         FALSE   FALSE      FALSE           FALSE       FALSE
#>   cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred aumcinf.obs
#> 1      FALSE      FALSE         FALSE         FALSE       FALSE       FALSE
#> 2      FALSE       TRUE         FALSE         FALSE       FALSE       FALSE
#>   aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs aucint.inf.pred
#> 1          FALSE          FALSE        FALSE          FALSE           FALSE
#> 2          FALSE          FALSE        FALSE          FALSE           FALSE
#>   aumcint.inf.obs aumcint.inf.pred aucivint.inf.obs aucivint.inf.pred
#> 1           FALSE            FALSE            FALSE             FALSE
#> 2           FALSE            FALSE            FALSE             FALSE
#>   aucivinf.obs aucivinf.obs_se aucivinf.obs_df aucivinf.pred aucivpbext.inf.obs
#> 1        FALSE           FALSE           FALSE         FALSE              FALSE
#> 2        FALSE           FALSE           FALSE         FALSE              FALSE
#>   aucivpbext.inf.pred aumcivint.inf.pred aumcivint.inf.obs aumcivinf.obs
#> 1               FALSE              FALSE             FALSE         FALSE
#> 2               FALSE              FALSE             FALSE         FALSE
#>   aumcivinf.obs_se aumcivinf.obs_df aumcivinf.pred thalf.eff.iv.all
#> 1            FALSE            FALSE          FALSE            FALSE
#> 2            FALSE            FALSE          FALSE            FALSE
#>   aucpext.inf.obs aucpext.inf.pred kel.iv.all kel.sparse.last cl.inf.obs
#> 1           FALSE            FALSE      FALSE           FALSE      FALSE
#> 2           FALSE            FALSE      FALSE           FALSE      FALSE
#>   cl.inf.pred cl.int.inf.obs cl.int.inf.pred cl.iv.inf.obs cl.iv.inf.pred
#> 1       FALSE          FALSE           FALSE         FALSE          FALSE
#> 2       FALSE          FALSE           FALSE         FALSE          FALSE
#>   cl.ivint.inf.pred cl.ivint.inf.obs f.inf.obs f.inf.pred f.int.inf.obs
#> 1             FALSE            FALSE     FALSE      FALSE         FALSE
#> 2             FALSE            FALSE     FALSE      FALSE         FALSE
#>   f.int.inf.pred mrt.inf.obs mrt.inf.pred mrt.int.inf.obs mrt.int.inf.pred
#> 1          FALSE       FALSE        FALSE           FALSE            FALSE
#> 2          FALSE       FALSE        FALSE           FALSE            FALSE
#>   mrt.iv.inf.obs mrt.iv.inf.pred mrt.ivint.inf.pred mrt.ivint.inf.obs
#> 1          FALSE           FALSE              FALSE             FALSE
#> 2          FALSE           FALSE              FALSE             FALSE
#>   mrt.md.inf.obs mrt.md.inf.pred mrt.ivmd.inf.obs mrt.ivmd.inf.pred vz.inf.obs
#> 1          FALSE           FALSE            FALSE             FALSE      FALSE
#> 2          FALSE           FALSE            FALSE             FALSE      FALSE
#>   vz.inf.pred vz.int.inf.obs vz.int.inf.pred vz.iv.inf.obs vz.iv.inf.pred
#> 1       FALSE          FALSE           FALSE         FALSE          FALSE
#> 2       FALSE          FALSE           FALSE         FALSE          FALSE
#>   vz.ivint.inf.pred vz.ivint.inf.obs vz.sparse.last vss.inf.obs vss.inf.pred
#> 1             FALSE            FALSE          FALSE       FALSE        FALSE
#> 2             FALSE            FALSE          FALSE       FALSE        FALSE
#>   vss.iv.inf.obs vss.iv.inf.pred vss.md.inf.obs vss.md.inf.pred
#> 1          FALSE           FALSE          FALSE           FALSE
#> 2          FALSE           FALSE          FALSE           FALSE
#>   vss.ivmd.inf.obs vss.ivmd.inf.pred vss.int.inf.obs vss.int.inf.pred
#> 1            FALSE             FALSE           FALSE            FALSE
#> 2            FALSE             FALSE           FALSE            FALSE
#>   vss.ivint.inf.pred vss.ivint.inf.obs cav.int.inf.obs cav.int.inf.pred
#> 1              FALSE             FALSE           FALSE            FALSE
#> 2              FALSE             FALSE           FALSE            FALSE
#>   cav.ivint.inf.obs cav.ivint.inf.pred ratio.aucinf.obs ratio.aucinf.pred
#> 1             FALSE              FALSE            FALSE             FALSE
#> 2             FALSE              FALSE            FALSE             FALSE
#>   thalf.eff.inf.obs thalf.eff.inf.pred thalf.eff.int.inf.pred
#> 1             FALSE              FALSE                  FALSE
#> 2             FALSE              FALSE                  FALSE
#>   thalf.eff.int.inf.obs thalf.eff.iv.inf.obs thalf.eff.iv.inf.pred
#> 1                 FALSE                FALSE                 FALSE
#> 2                 FALSE                FALSE                 FALSE
#>   thalf.eff.ivint.inf.pred thalf.eff.ivint.inf.obs kel.inf.obs kel.inf.pred
#> 1                    FALSE                   FALSE       FALSE        FALSE
#> 2                    FALSE                   FALSE       FALSE        FALSE
#>   kel.iv.inf.obs kel.iv.inf.pred kel.int.inf.obs kel.int.inf.pred
#> 1          FALSE           FALSE           FALSE            FALSE
#> 2          FALSE           FALSE           FALSE            FALSE
#>   kel.ivint.inf.pred kel.ivint.inf.obs auclast.dn aucall.dn aucinf.obs.dn
#> 1              FALSE             FALSE      FALSE     FALSE         FALSE
#> 2              FALSE             FALSE      FALSE     FALSE         FALSE
#>   aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn
#> 1          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
#> 2          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
#>   cmin.dn clast.obs.dn clast.pred.dn cav.last.dn ctrough.dn adj_tobit_residual
#> 1   FALSE        FALSE         FALSE       FALSE      FALSE              FALSE
#> 2   FALSE        FALSE         FALSE       FALSE      FALSE              FALSE
#>   aucivpbextall aucivpbextinf.obs aucivpbextinf.pred aucivpbextint.all
#> 1         FALSE             FALSE              FALSE             FALSE
#> 2         FALSE             FALSE              FALSE             FALSE
#>   aucivpbextint.last aucivpbextlast aucpext.obs aucpext.pred   cav cav.dn
#> 1              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
#> 2              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
#>   cl.iv.obs cl.iv.pred cl.obs cl.pred clr.obs clr.pred count_conc
#> 1     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
#> 2     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
#>   count_conc_measured f.int.obs f.int.pred f.obs f.pred kel.iv.obs kel.iv.pred
#> 1               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
#> 2               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
#>   kel.obs kel.pred lambda.z.n.points_blq mrt.iv.obs mrt.iv.pred mrt.ivmd.obs
#> 1   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
#> 2   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
#>   mrt.ivmd.pred mrt.md.obs mrt.md.pred mrt.obs mrt.pred thalf.eff.iv.obs
#> 1         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
#> 2         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
#>   thalf.eff.iv.pred thalf.eff.obs thalf.eff.pred time_above tobit_residual
#> 1             FALSE         FALSE          FALSE      FALSE          FALSE
#> 2             FALSE         FALSE          FALSE      FALSE          FALSE
#>   vss.iv.obs vss.iv.pred vss.ivmd.obs vss.ivmd.pred vss.md.obs vss.md.pred
#> 1      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
#> 2      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
#>   vss.obs vss.pred vz.iv.obs vz.iv.pred vz.obs vz.pred
#> 1   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE
#> 2   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE
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
