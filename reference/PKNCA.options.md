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
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbextint.last
#> 1        FALSE       FALSE         FALSE        FALSE              FALSE
#> 2        FALSE       FALSE         FALSE        FALSE              FALSE
#>   aucivpbextint.all aumcivint.last aumcivint.all    c0  cmax  cmin  tmax  tmin
#> 1             FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
#> 2             FALSE          FALSE         FALSE FALSE  TRUE FALSE  TRUE FALSE
#>   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
#> 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#> 2 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#>   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
#> 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#> 2         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#>   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
#> 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#> 2         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#>   vss.int.last vss.ivint.all vss.ivint.last   cav cav.last cav.int.last
#> 1        FALSE         FALSE          FALSE FALSE    FALSE        FALSE
#> 2        FALSE         FALSE          FALSE FALSE    FALSE        FALSE
#>   cav.int.all cav.all cav.ivint.last cav.ivint.all ctrough cstart   ptr  tlag
#> 1       FALSE   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE
#> 2       FALSE   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE
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
#>   aucivall aucivall_se aucivall_df aucivpbextlast aucivpbextall aumcivlast
#> 1    FALSE       FALSE       FALSE          FALSE         FALSE      FALSE
#> 2    FALSE       FALSE       FALSE          FALSE         FALSE      FALSE
#>   aumcivlast_se aumcivlast_df aumcivall aumcivall_se aumcivall_df half.life
#> 1         FALSE         FALSE     FALSE        FALSE        FALSE     FALSE
#> 2         FALSE         FALSE     FALSE        FALSE        FALSE      TRUE
#>   r.squared adj.r.squared lambda.z.corrxy lambda.z lambda.z.time.first
#> 1     FALSE         FALSE           FALSE    FALSE               FALSE
#> 2     FALSE         FALSE           FALSE    FALSE               FALSE
#>   lambda.z.time.last lambda.z.n.points clast.pred span.ratio tobit_residual
#> 1              FALSE             FALSE      FALSE      FALSE          FALSE
#> 2              FALSE             FALSE      FALSE      FALSE          FALSE
#>   adj_tobit_residual lambda.z.n.points_blq thalf.eff.last thalf.eff.iv.last
#> 1              FALSE                 FALSE          FALSE             FALSE
#> 2              FALSE                 FALSE          FALSE             FALSE
#>   kel.last kel.iv.last kel.all kel.int.all kel.int.last kel.ivint.all
#> 1    FALSE       FALSE   FALSE       FALSE        FALSE         FALSE
#> 2    FALSE       FALSE   FALSE       FALSE        FALSE         FALSE
#>   kel.ivint.last cl.iv.all cl.iv.last cl.sparse.last f.last f.int.last
#> 1          FALSE     FALSE      FALSE          FALSE  FALSE      FALSE
#> 2          FALSE     FALSE      FALSE          FALSE  FALSE      FALSE
#>   f.int.all mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last vz.iv.all
#> 1     FALSE           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE
#> 2     FALSE           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE
#>   vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.sparse.last
#> 1      FALSE        FALSE         FALSE   FALSE      FALSE           FALSE
#> 2      FALSE        FALSE         FALSE   FALSE      FALSE           FALSE
#>   cav.iv.last cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred
#> 1       FALSE      FALSE      FALSE         FALSE         FALSE       FALSE
#> 2       FALSE      FALSE       TRUE         FALSE         FALSE       FALSE
#>   aumcinf.obs aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs
#> 1       FALSE          FALSE          FALSE        FALSE          FALSE
#> 2       FALSE          FALSE          FALSE        FALSE          FALSE
#>   aucint.inf.pred aumcint.inf.obs aumcint.inf.pred aucivint.inf.obs
#> 1           FALSE           FALSE            FALSE            FALSE
#> 2           FALSE           FALSE            FALSE            FALSE
#>   aucivint.inf.pred aucivinf.obs aucivinf.obs_se aucivinf.obs_df aucivinf.pred
#> 1             FALSE        FALSE           FALSE           FALSE         FALSE
#> 2             FALSE        FALSE           FALSE           FALSE         FALSE
#>   aucivpbextinf.obs aucivpbextinf.pred aumcivinf.obs aumcivinf.obs_se
#> 1             FALSE              FALSE         FALSE            FALSE
#> 2             FALSE              FALSE         FALSE            FALSE
#>   aumcivinf.obs_df aumcivinf.pred aucpext.obs aucpext.pred kel.iv.all
#> 1            FALSE          FALSE       FALSE        FALSE      FALSE
#> 2            FALSE          FALSE       FALSE        FALSE      FALSE
#>   kel.sparse.last cl.obs cl.pred cl.int.inf.obs cl.int.inf.pred cl.iv.obs
#> 1           FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#> 2           FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#>   cl.iv.pred f.obs f.pred f.int.obs f.int.pred mrt.obs mrt.pred mrt.int.inf.obs
#> 1      FALSE FALSE  FALSE     FALSE      FALSE   FALSE    FALSE           FALSE
#> 2      FALSE FALSE  FALSE     FALSE      FALSE   FALSE    FALSE           FALSE
#>   mrt.int.inf.pred mrt.iv.obs mrt.iv.pred mrt.md.obs mrt.md.pred mrt.ivmd.obs
#> 1            FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#> 2            FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#>   mrt.ivmd.pred vz.obs vz.pred vz.int.inf.obs vz.int.inf.pred vz.iv.obs
#> 1         FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#> 2         FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#>   vz.iv.pred vz.sparse.last vss.obs vss.pred vss.iv.obs vss.iv.pred vss.md.obs
#> 1      FALSE          FALSE   FALSE    FALSE      FALSE       FALSE      FALSE
#> 2      FALSE          FALSE   FALSE    FALSE      FALSE       FALSE      FALSE
#>   vss.md.pred vss.ivmd.obs vss.ivmd.pred vss.int.inf.obs vss.int.inf.pred
#> 1       FALSE        FALSE         FALSE           FALSE            FALSE
#> 2       FALSE        FALSE         FALSE           FALSE            FALSE
#>   cav.int.inf.obs cav.int.inf.pred cav.ivint.inf.obs cav.ivint.inf.pred
#> 1           FALSE            FALSE             FALSE              FALSE
#> 2           FALSE            FALSE             FALSE              FALSE
#>   ratio.aucinf.obs ratio.aucinf.pred thalf.eff.obs thalf.eff.pred
#> 1            FALSE             FALSE         FALSE          FALSE
#> 2            FALSE             FALSE         FALSE          FALSE
#>   thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs kel.iv.pred
#> 1            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
#> 2            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
#>   kel.int.inf.obs kel.int.inf.pred auclast.dn aucall.dn aucinf.obs.dn
#> 1           FALSE            FALSE      FALSE     FALSE         FALSE
#> 2           FALSE            FALSE      FALSE     FALSE         FALSE
#>   aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn
#> 1          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
#> 2          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
#>   cmin.dn clast.obs.dn clast.pred.dn cav.dn cav.last.dn ctrough.dn clr.last.dn
#> 1   FALSE        FALSE         FALSE  FALSE       FALSE      FALSE       FALSE
#> 2   FALSE        FALSE         FALSE  FALSE       FALSE      FALSE       FALSE
#>   clr.obs.dn clr.pred.dn
#> 1      FALSE       FALSE
#> 2      FALSE       FALSE
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
