# Build an interval specification from a description of the analysis

Chooses the NCA parameters to calculate for an interval, and the
imputation to calculate them from, given when the interval runs and how
the drug was given. The result is a data.frame suitable for the
`intervals` argument of
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md).

## Usage

``` r
pknca_interval_table(
  start,
  end,
  dosing = "single",
  route = "extravascular",
  sample_type = "spot",
  sparse = FALSE,
  tier = "common",
  include = NULL,
  exclude = NULL,
  impute = NULL,
  preset = NULL,
  clast_type = "obs",
  ...
)
```

## Arguments

- start, end:

  The start and end time of the interval. Both may be vectors, giving
  one set of rows per interval.

- dosing:

  Was the drug given once (`"single"`), repeatedly without assuming
  steady state (`"multiple"`), or repeatedly at steady state
  (`"steady_state"`)? Asking for `"steady_state"` also gives the
  parameters that apply to any repeated dose. See
  [`pknca_dosing()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md).

- route:

  How the drug was given; see
  [`pknca_routes()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md).

- sample_type:

  Were concentrations measured in samples taken at a point in time
  (`"spot"`, the usual case for blood, plasma, and serum) or in a
  collection over an interval (`"interval"`, the usual case for urine
  and feces)? See
  [`pknca_sample_types()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md).

- sparse:

  Is this a sparse sampling design?

- tier:

  `"common"` (the default) gives the parameters usually reported for the
  context; `"all"` gives every parameter it can calculate.

- include, exclude:

  NCA parameters or concepts (see
  [`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md))
  to add to or remove from what the context gives. A parameter named in
  both is an error.

- impute:

  The imputation to use, as for
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md).
  The default of `NULL` chooses one from the context; `NA` uses none.

- preset:

  A named set of arguments to start from; see
  [`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md).
  Arguments given explicitly override the preset.

- clast_type:

  Should the extrapolation to infinity use the observed (`"obs"`) or
  predicted (`"pred"`) last concentration?

- ...:

  Columns to add to every row, typically the groups the interval applies
  to.

## Value

A data.frame with one or more rows per interval: `start`, `end`, a
logical column per parameter, an `impute` column when any imputation
applies, and any columns given in `...`. An interval is split into more
than one row when some of its parameters must not be calculated from the
imputed data.

## Details

The interval is assumed to start at a dose, which is what makes an
imputation at the start meaningful. Pass `impute = NA` for an interval
that starts partway through a profile.

Which AUC the interval is built on follows from `dosing`: a single dose
uses AUClast and the extrapolation to infinity, and a repeated dose uses
the AUCint family, which interpolates at both interval boundaries. The
clearance, volume, and mean residence time that follow from that AUC are
chosen to match.

## See also

[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md)
for how each parameter is classified,
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md),
and the vignette "Selection of Calculation Intervals"

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`interval_add_secondary()`](https://humanpred.github.io/pknca/reference/interval_add_secondary.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)

## Examples

``` r
# A single oral dose
pknca_interval_table(0, 24, dosing = "single", route = "extravascular")
#>   start end auclast aucall aumclast aumcall aucint.last aucint.last.dose
#> 1     0  24    TRUE  FALSE    FALSE   FALSE       FALSE            FALSE
#>   aucint.all aucint.all.dose aumcint.last aumcint.last.dose aumcint.all
#> 1      FALSE           FALSE        FALSE             FALSE       FALSE
#>   aumcint.all.dose    c0 cmax  cmin tmax  tmin tlast tfirst clast.obs cl.last
#> 1            FALSE FALSE TRUE FALSE TRUE FALSE FALSE  FALSE     FALSE   FALSE
#>   cl.all cl.int.all cl.int.last mrt.last mrt.all mrt.int.all mrt.int.last
#> 1  FALSE      FALSE       FALSE    FALSE   FALSE       FALSE        FALSE
#>   mrt.iv.last vss.last vss.iv.last vss.all vss.int.all vss.int.last   cav
#> 1       FALSE    FALSE       FALSE   FALSE       FALSE        FALSE FALSE
#>   cav.int.last cav.int.all ctrough cstart   ptr tlag deg.fluc swing  ceoi
#> 1        FALSE       FALSE   FALSE  FALSE FALSE TRUE    FALSE FALSE FALSE
#>   aucabove.predose.all aucabove.trough.all count_conc count_conc_measured
#> 1                FALSE               FALSE       TRUE               FALSE
#>   totdose volpk    ae clr.last clr.obs clr.pred    fe ertlst ermax ertmax erint
#> 1   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE  FALSE FALSE  FALSE FALSE
#>   erlst ratio.cmax ratio.auclast ratio.aucint.last ratio.aucint.all
#> 1 FALSE      FALSE         FALSE             FALSE            FALSE
#>   sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast sparse_aumc_se
#> 1          FALSE         FALSE         FALSE           FALSE          FALSE
#>   sparse_aumc_df time_above aucivlast aucivall aucivint.last aucivint.all
#> 1          FALSE      FALSE     FALSE    FALSE         FALSE        FALSE
#>   aucivpbextlast aucivpbextall aucivpbextint.last aucivpbextint.all aumcivlast
#> 1          FALSE         FALSE              FALSE             FALSE      FALSE
#>   aumcivall aumcivint.last aumcivint.all half.life r.squared adj.r.squared
#> 1     FALSE          FALSE         FALSE      TRUE     FALSE         FALSE
#>   lambda.z.corrxy lambda.z lambda.z.time.first lambda.z.time.last
#> 1           FALSE    FALSE               FALSE              FALSE
#>   lambda.z.n.points clast.pred span.ratio tobit_residual adj_tobit_residual
#> 1             FALSE      FALSE      FALSE          FALSE              FALSE
#>   lambda.z.n.points_blq thalf.eff.last thalf.eff.iv.last kel.last kel.iv.last
#> 1                 FALSE          FALSE             FALSE    FALSE       FALSE
#>   kel.all kel.int.all kel.int.last cl.iv.all cl.iv.last cl.ivint.all
#> 1   FALSE       FALSE        FALSE     FALSE      FALSE        FALSE
#>   cl.ivint.last cl.sparse.last f.last f.int.last f.int.all mrt.sparse.last
#> 1         FALSE          FALSE  FALSE      FALSE     FALSE           FALSE
#>   mrt.iv.all mrt.ivint.all mrt.ivint.last vz.all vz.int.all vz.int.last
#> 1      FALSE         FALSE          FALSE  FALSE      FALSE       FALSE
#>   vz.iv.all vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all
#> 1     FALSE      FALSE        FALSE         FALSE   FALSE      FALSE
#>   vss.ivint.all vss.ivint.last vss.sparse.last aucinf.obs aucinf.pred
#> 1         FALSE          FALSE           FALSE       TRUE       FALSE
#>   aumcinf.obs aumcinf.pred aucint.inf.obs aucint.inf.obs.dose aucint.inf.pred
#> 1       FALSE        FALSE          FALSE               FALSE           FALSE
#>   aucint.inf.pred.dose aumcint.inf.obs aumcint.inf.obs.dose aumcint.inf.pred
#> 1                FALSE           FALSE                FALSE            FALSE
#>   aumcint.inf.pred.dose aucivinf.obs aucivinf.pred aucivpbextinf.obs
#> 1                 FALSE        FALSE         FALSE             FALSE
#>   aucivpbextinf.pred aumcivinf.obs aumcivinf.pred aucpext.obs aucpext.pred
#> 1              FALSE         FALSE          FALSE        TRUE        FALSE
#>   kel.iv.all kel.ivint.all kel.ivint.last kel.sparse.last cl.obs cl.pred
#> 1      FALSE         FALSE          FALSE           FALSE   TRUE   FALSE
#>   cl.int.inf.obs cl.int.inf.pred cl.iv.obs cl.iv.pred f.obs f.pred f.int.obs
#> 1          FALSE           FALSE     FALSE      FALSE FALSE  FALSE     FALSE
#>   f.int.pred mrt.obs mrt.pred mrt.int.inf.obs mrt.int.inf.pred mrt.iv.obs
#> 1      FALSE   FALSE    FALSE           FALSE            FALSE      FALSE
#>   mrt.iv.pred mrt.md.obs mrt.md.pred mrt.ivmd.obs mrt.ivmd.pred vz.obs vz.pred
#> 1       FALSE      FALSE       FALSE        FALSE         FALSE  FALSE   FALSE
#>   vz.int.inf.obs vz.int.inf.pred vz.iv.obs vz.iv.pred vz.sparse.last vss.obs
#> 1          FALSE           FALSE     FALSE      FALSE          FALSE   FALSE
#>   vss.pred vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred vss.ivmd.obs
#> 1    FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#>   vss.ivmd.pred vss.int.inf.obs vss.int.inf.pred cav.int.inf.obs
#> 1         FALSE           FALSE            FALSE           FALSE
#>   cav.int.inf.pred ratio.aucinf.obs ratio.aucinf.pred thalf.eff.obs
#> 1            FALSE            FALSE             FALSE         FALSE
#>   thalf.eff.pred thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs
#> 1          FALSE            FALSE             FALSE   FALSE    FALSE      FALSE
#>   kel.iv.pred kel.int.inf.obs kel.int.inf.pred auclast.dn aucall.dn
#> 1       FALSE           FALSE            FALSE      FALSE     FALSE
#>   aucinf.obs.dn aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn
#> 1         FALSE          FALSE       FALSE      FALSE          FALSE
#>   aumcinf.pred.dn cmax.dn cmin.dn clast.obs.dn clast.pred.dn cav.dn ctrough.dn
#> 1           FALSE   FALSE   FALSE        FALSE         FALSE  FALSE      FALSE
#>   clr.last.dn clr.obs.dn clr.pred.dn              impute
#> 1       FALSE      FALSE       FALSE start_predose_conc0

# At steady state, with the fluctuation parameters added
pknca_interval_table(
  144, 168,
  dosing = "steady_state", route = "extravascular",
  include = "fluctuation"
)
#>   start end auclast aucall aumclast aumcall aucint.last aucint.last.dose
#> 1   144 168   FALSE  FALSE    FALSE   FALSE        TRUE            FALSE
#>   aucint.all aucint.all.dose aumcint.last aumcint.last.dose aumcint.all
#> 1      FALSE           FALSE        FALSE             FALSE       FALSE
#>   aumcint.all.dose    c0 cmax  cmin tmax  tmin tlast tfirst clast.obs cl.last
#> 1            FALSE FALSE TRUE FALSE TRUE FALSE FALSE  FALSE     FALSE   FALSE
#>   cl.all cl.int.all cl.int.last mrt.last mrt.all mrt.int.all mrt.int.last
#> 1  FALSE      FALSE       FALSE    FALSE   FALSE       FALSE        FALSE
#>   mrt.iv.last vss.last vss.iv.last vss.all vss.int.all vss.int.last   cav
#> 1       FALSE    FALSE       FALSE   FALSE       FALSE        FALSE FALSE
#>   cav.int.last cav.int.all ctrough cstart  ptr tlag deg.fluc swing  ceoi
#> 1        FALSE       FALSE    TRUE  FALSE TRUE TRUE     TRUE  TRUE FALSE
#>   aucabove.predose.all aucabove.trough.all count_conc count_conc_measured
#> 1                FALSE               FALSE       TRUE               FALSE
#>   totdose volpk    ae clr.last clr.obs clr.pred    fe ertlst ermax ertmax erint
#> 1   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE  FALSE FALSE  FALSE FALSE
#>   erlst ratio.cmax ratio.auclast ratio.aucint.last ratio.aucint.all
#> 1 FALSE      FALSE         FALSE             FALSE            FALSE
#>   sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast sparse_aumc_se
#> 1          FALSE         FALSE         FALSE           FALSE          FALSE
#>   sparse_aumc_df time_above aucivlast aucivall aucivint.last aucivint.all
#> 1          FALSE      FALSE     FALSE    FALSE         FALSE        FALSE
#>   aucivpbextlast aucivpbextall aucivpbextint.last aucivpbextint.all aumcivlast
#> 1          FALSE         FALSE              FALSE             FALSE      FALSE
#>   aumcivall aumcivint.last aumcivint.all half.life r.squared adj.r.squared
#> 1     FALSE          FALSE         FALSE      TRUE     FALSE         FALSE
#>   lambda.z.corrxy lambda.z lambda.z.time.first lambda.z.time.last
#> 1           FALSE    FALSE               FALSE              FALSE
#>   lambda.z.n.points clast.pred span.ratio tobit_residual adj_tobit_residual
#> 1             FALSE      FALSE      FALSE          FALSE              FALSE
#>   lambda.z.n.points_blq thalf.eff.last thalf.eff.iv.last kel.last kel.iv.last
#> 1                 FALSE          FALSE             FALSE    FALSE       FALSE
#>   kel.all kel.int.all kel.int.last cl.iv.all cl.iv.last cl.ivint.all
#> 1   FALSE       FALSE        FALSE     FALSE      FALSE        FALSE
#>   cl.ivint.last cl.sparse.last f.last f.int.last f.int.all mrt.sparse.last
#> 1         FALSE          FALSE  FALSE      FALSE     FALSE           FALSE
#>   mrt.iv.all mrt.ivint.all mrt.ivint.last vz.all vz.int.all vz.int.last
#> 1      FALSE         FALSE          FALSE  FALSE      FALSE       FALSE
#>   vz.iv.all vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all
#> 1     FALSE      FALSE        FALSE         FALSE   FALSE      FALSE
#>   vss.ivint.all vss.ivint.last vss.sparse.last aucinf.obs aucinf.pred
#> 1         FALSE          FALSE           FALSE      FALSE       FALSE
#>   aumcinf.obs aumcinf.pred aucint.inf.obs aucint.inf.obs.dose aucint.inf.pred
#> 1       FALSE        FALSE           TRUE               FALSE           FALSE
#>   aucint.inf.pred.dose aumcint.inf.obs aumcint.inf.obs.dose aumcint.inf.pred
#> 1                FALSE           FALSE                FALSE            FALSE
#>   aumcint.inf.pred.dose aucivinf.obs aucivinf.pred aucivpbextinf.obs
#> 1                 FALSE        FALSE         FALSE             FALSE
#>   aucivpbextinf.pred aumcivinf.obs aumcivinf.pred aucpext.obs aucpext.pred
#> 1              FALSE         FALSE          FALSE       FALSE        FALSE
#>   kel.iv.all kel.ivint.all kel.ivint.last kel.sparse.last cl.obs cl.pred
#> 1      FALSE         FALSE          FALSE           FALSE  FALSE   FALSE
#>   cl.int.inf.obs cl.int.inf.pred cl.iv.obs cl.iv.pred f.obs f.pred f.int.obs
#> 1           TRUE           FALSE     FALSE      FALSE FALSE  FALSE     FALSE
#>   f.int.pred mrt.obs mrt.pred mrt.int.inf.obs mrt.int.inf.pred mrt.iv.obs
#> 1      FALSE   FALSE    FALSE           FALSE            FALSE      FALSE
#>   mrt.iv.pred mrt.md.obs mrt.md.pred mrt.ivmd.obs mrt.ivmd.pred vz.obs vz.pred
#> 1       FALSE      FALSE       FALSE        FALSE         FALSE  FALSE   FALSE
#>   vz.int.inf.obs vz.int.inf.pred vz.iv.obs vz.iv.pred vz.sparse.last vss.obs
#> 1          FALSE           FALSE     FALSE      FALSE          FALSE   FALSE
#>   vss.pred vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred vss.ivmd.obs
#> 1    FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#>   vss.ivmd.pred vss.int.inf.obs vss.int.inf.pred cav.int.inf.obs
#> 1         FALSE           FALSE            FALSE           FALSE
#>   cav.int.inf.pred ratio.aucinf.obs ratio.aucinf.pred thalf.eff.obs
#> 1            FALSE            FALSE             FALSE         FALSE
#>   thalf.eff.pred thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs
#> 1          FALSE            FALSE             FALSE   FALSE    FALSE      FALSE
#>   kel.iv.pred kel.int.inf.obs kel.int.inf.pred auclast.dn aucall.dn
#> 1       FALSE           FALSE            FALSE      FALSE     FALSE
#>   aucinf.obs.dn aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn
#> 1         FALSE          FALSE       FALSE      FALSE          FALSE
#>   aumcinf.pred.dn cmax.dn cmin.dn clast.obs.dn clast.pred.dn cav.dn ctrough.dn
#> 1           FALSE   FALSE   FALSE        FALSE         FALSE  FALSE      FALSE
#>   clr.last.dn clr.obs.dn clr.pred.dn        impute
#> 1       FALSE      FALSE       FALSE start_predose

# A urine collection
pknca_interval_table(0, 24, dosing = "single", route = "extravascular",
                     sample_type = "interval")
#>   start end auclast aucall aumclast aumcall aucint.last aucint.last.dose
#> 1     0  24   FALSE  FALSE    FALSE   FALSE       FALSE            FALSE
#>   aucint.all aucint.all.dose aumcint.last aumcint.last.dose aumcint.all
#> 1      FALSE           FALSE        FALSE             FALSE       FALSE
#>   aumcint.all.dose    c0  cmax  cmin  tmax  tmin tlast tfirst clast.obs cl.last
#> 1            FALSE FALSE FALSE FALSE FALSE FALSE FALSE  FALSE     FALSE   FALSE
#>   cl.all cl.int.all cl.int.last mrt.last mrt.all mrt.int.all mrt.int.last
#> 1  FALSE      FALSE       FALSE    FALSE   FALSE       FALSE        FALSE
#>   mrt.iv.last vss.last vss.iv.last vss.all vss.int.all vss.int.last   cav
#> 1       FALSE    FALSE       FALSE   FALSE       FALSE        FALSE FALSE
#>   cav.int.last cav.int.all ctrough cstart   ptr  tlag deg.fluc swing  ceoi
#> 1        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
#>   aucabove.predose.all aucabove.trough.all count_conc count_conc_measured
#> 1                FALSE               FALSE      FALSE               FALSE
#>   totdose volpk   ae clr.last clr.obs clr.pred   fe ertlst ermax ertmax erint
#> 1   FALSE  TRUE TRUE    FALSE   FALSE    FALSE TRUE  FALSE FALSE  FALSE FALSE
#>   erlst ratio.cmax ratio.auclast ratio.aucint.last ratio.aucint.all
#> 1 FALSE      FALSE         FALSE             FALSE            FALSE
#>   sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast sparse_aumc_se
#> 1          FALSE         FALSE         FALSE           FALSE          FALSE
#>   sparse_aumc_df time_above aucivlast aucivall aucivint.last aucivint.all
#> 1          FALSE      FALSE     FALSE    FALSE         FALSE        FALSE
#>   aucivpbextlast aucivpbextall aucivpbextint.last aucivpbextint.all aumcivlast
#> 1          FALSE         FALSE              FALSE             FALSE      FALSE
#>   aumcivall aumcivint.last aumcivint.all half.life r.squared adj.r.squared
#> 1     FALSE          FALSE         FALSE     FALSE     FALSE         FALSE
#>   lambda.z.corrxy lambda.z lambda.z.time.first lambda.z.time.last
#> 1           FALSE    FALSE               FALSE              FALSE
#>   lambda.z.n.points clast.pred span.ratio tobit_residual adj_tobit_residual
#> 1             FALSE      FALSE      FALSE          FALSE              FALSE
#>   lambda.z.n.points_blq thalf.eff.last thalf.eff.iv.last kel.last kel.iv.last
#> 1                 FALSE          FALSE             FALSE    FALSE       FALSE
#>   kel.all kel.int.all kel.int.last cl.iv.all cl.iv.last cl.ivint.all
#> 1   FALSE       FALSE        FALSE     FALSE      FALSE        FALSE
#>   cl.ivint.last cl.sparse.last f.last f.int.last f.int.all mrt.sparse.last
#> 1         FALSE          FALSE  FALSE      FALSE     FALSE           FALSE
#>   mrt.iv.all mrt.ivint.all mrt.ivint.last vz.all vz.int.all vz.int.last
#> 1      FALSE         FALSE          FALSE  FALSE      FALSE       FALSE
#>   vz.iv.all vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all
#> 1     FALSE      FALSE        FALSE         FALSE   FALSE      FALSE
#>   vss.ivint.all vss.ivint.last vss.sparse.last aucinf.obs aucinf.pred
#> 1         FALSE          FALSE           FALSE      FALSE       FALSE
#>   aumcinf.obs aumcinf.pred aucint.inf.obs aucint.inf.obs.dose aucint.inf.pred
#> 1       FALSE        FALSE          FALSE               FALSE           FALSE
#>   aucint.inf.pred.dose aumcint.inf.obs aumcint.inf.obs.dose aumcint.inf.pred
#> 1                FALSE           FALSE                FALSE            FALSE
#>   aumcint.inf.pred.dose aucivinf.obs aucivinf.pred aucivpbextinf.obs
#> 1                 FALSE        FALSE         FALSE             FALSE
#>   aucivpbextinf.pred aumcivinf.obs aumcivinf.pred aucpext.obs aucpext.pred
#> 1              FALSE         FALSE          FALSE       FALSE        FALSE
#>   kel.iv.all kel.ivint.all kel.ivint.last kel.sparse.last cl.obs cl.pred
#> 1      FALSE         FALSE          FALSE           FALSE  FALSE   FALSE
#>   cl.int.inf.obs cl.int.inf.pred cl.iv.obs cl.iv.pred f.obs f.pred f.int.obs
#> 1          FALSE           FALSE     FALSE      FALSE FALSE  FALSE     FALSE
#>   f.int.pred mrt.obs mrt.pred mrt.int.inf.obs mrt.int.inf.pred mrt.iv.obs
#> 1      FALSE   FALSE    FALSE           FALSE            FALSE      FALSE
#>   mrt.iv.pred mrt.md.obs mrt.md.pred mrt.ivmd.obs mrt.ivmd.pred vz.obs vz.pred
#> 1       FALSE      FALSE       FALSE        FALSE         FALSE  FALSE   FALSE
#>   vz.int.inf.obs vz.int.inf.pred vz.iv.obs vz.iv.pred vz.sparse.last vss.obs
#> 1          FALSE           FALSE     FALSE      FALSE          FALSE   FALSE
#>   vss.pred vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred vss.ivmd.obs
#> 1    FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#>   vss.ivmd.pred vss.int.inf.obs vss.int.inf.pred cav.int.inf.obs
#> 1         FALSE           FALSE            FALSE           FALSE
#>   cav.int.inf.pred ratio.aucinf.obs ratio.aucinf.pred thalf.eff.obs
#> 1            FALSE            FALSE             FALSE         FALSE
#>   thalf.eff.pred thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs
#> 1          FALSE            FALSE             FALSE   FALSE    FALSE      FALSE
#>   kel.iv.pred kel.int.inf.obs kel.int.inf.pred auclast.dn aucall.dn
#> 1       FALSE           FALSE            FALSE      FALSE     FALSE
#>   aucinf.obs.dn aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn
#> 1         FALSE          FALSE       FALSE      FALSE          FALSE
#>   aumcinf.pred.dn cmax.dn cmin.dn clast.obs.dn clast.pred.dn cav.dn ctrough.dn
#> 1           FALSE   FALSE   FALSE        FALSE         FALSE  FALSE      FALSE
#>   clr.last.dn clr.obs.dn clr.pred.dn
#> 1       FALSE      FALSE       FALSE
```
