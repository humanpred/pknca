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
  auc_type = "last",
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

  Is this a sparse sampling design? The parameters chosen are the same
  either way – the AUCs and AUMCs with a sparse estimator are estimated
  with the sparse methods when the data are sparse, and the rest are
  calculated from the arithmetic-mean profile – but the imputation
  differs: the sparse estimators accept only an imputed zero, so a
  sparse single dose imputes zero at the start (`"start_conc0"`), and
  other sparse designs impute nothing.

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

- auc_type:

  Is the AUC over the observations the AUC to the last measurable
  concentration (`"last"`, giving `auclast` or `aucint.last` and what
  follows from it) or AUCall (`"all"`, giving `aucall` or `aucint.all`)?

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

An interval that ends at infinity gets no parameter that needs a finite
end: no average concentration (which would be zero) or anything
calculated from one, and no parameter that applies only to repeated
dosing.

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
[`pknca_cdisc_codes()`](https://humanpred.github.io/pknca/reference/pknca_cdisc_codes.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_match_route()`](https://humanpred.github.io/pknca/reference/pknca_match_route.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)

## Examples

``` r
# A single oral dose
pknca_interval_table(0, 24, dosing = "single", route = "extravascular")
#>   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
#> 1     0  24    TRUE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#>   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
#> 1       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbextint.last
#> 1        FALSE       FALSE         FALSE        FALSE              FALSE
#>   aucivpbextint.all aumcivint.last aumcivint.all    c0 cmax  cmin tmax  tmin
#> 1             FALSE          FALSE         FALSE FALSE TRUE FALSE TRUE FALSE
#>   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
#> 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#>   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
#> 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#>   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
#> 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#>   vss.int.last vss.ivint.all vss.ivint.last   cav cav.last cav.int.last
#> 1        FALSE         FALSE          FALSE FALSE    FALSE        FALSE
#>   cav.int.all cav.all cav.ivint.last cav.ivint.all ctrough cstart   ptr tlag
#> 1       FALSE   FALSE          FALSE         FALSE   FALSE  FALSE FALSE TRUE
#>   deg.fluc swing  ceoi aucabove.predose.all aucabove.trough.all count_conc
#> 1    FALSE FALSE FALSE                FALSE               FALSE       TRUE
#>   count_conc_measured totdose volpk    ae clr.last clr.obs clr.pred    fe
#> 1               FALSE   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE
#>   ertlst ermax ertmax erint erlst ratio.cmax ratio.auclast ratio.aucint.last
#> 1  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE             FALSE
#>   ratio.aucint.all sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast
#> 1            FALSE          FALSE         FALSE         FALSE           FALSE
#>   sparse_aumc_se sparse_aumc_df time_above aucivlast aucivlast_se aucivlast_df
#> 1          FALSE          FALSE      FALSE     FALSE        FALSE        FALSE
#>   aucivall aucivall_se aucivall_df aucivpbextlast aucivpbextall aumcivlast
#> 1    FALSE       FALSE       FALSE          FALSE         FALSE      FALSE
#>   aumcivlast_se aumcivlast_df aumcivall aumcivall_se aumcivall_df half.life
#> 1         FALSE         FALSE     FALSE        FALSE        FALSE      TRUE
#>   r.squared adj.r.squared lambda.z.corrxy lambda.z lambda.z.time.first
#> 1     FALSE         FALSE           FALSE    FALSE               FALSE
#>   lambda.z.time.last lambda.z.n.points clast.pred span.ratio tobit_residual
#> 1              FALSE             FALSE      FALSE      FALSE          FALSE
#>   adj_tobit_residual lambda.z.n.points_blq thalf.eff.last thalf.eff.iv.last
#> 1              FALSE                 FALSE          FALSE             FALSE
#>   kel.last kel.iv.last kel.all kel.int.all kel.int.last kel.ivint.all
#> 1    FALSE       FALSE   FALSE       FALSE        FALSE         FALSE
#>   kel.ivint.last cl.iv.all cl.iv.last cl.sparse.last f.last f.int.last
#> 1          FALSE     FALSE      FALSE          FALSE  FALSE      FALSE
#>   f.int.all mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last vz.iv.all
#> 1     FALSE           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE
#>   vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.sparse.last
#> 1      FALSE        FALSE         FALSE   FALSE      FALSE           FALSE
#>   cav.iv.last cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred
#> 1       FALSE      FALSE       TRUE         FALSE         FALSE       FALSE
#>   aumcinf.obs aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs
#> 1       FALSE          FALSE          FALSE        FALSE          FALSE
#>   aucint.inf.pred aumcint.inf.obs aumcint.inf.pred aucivint.inf.obs
#> 1           FALSE           FALSE            FALSE            FALSE
#>   aucivint.inf.pred aucivinf.obs aucivinf.obs_se aucivinf.obs_df aucivinf.pred
#> 1             FALSE        FALSE           FALSE           FALSE         FALSE
#>   aucivpbextinf.obs aucivpbextinf.pred aumcivinf.obs aumcivinf.obs_se
#> 1             FALSE              FALSE         FALSE            FALSE
#>   aumcivinf.obs_df aumcivinf.pred aucpext.obs aucpext.pred kel.iv.all
#> 1            FALSE          FALSE        TRUE        FALSE      FALSE
#>   kel.sparse.last cl.obs cl.pred cl.int.inf.obs cl.int.inf.pred cl.iv.obs
#> 1           FALSE   TRUE   FALSE          FALSE           FALSE     FALSE
#>   cl.iv.pred f.obs f.pred f.int.obs f.int.pred mrt.obs mrt.pred mrt.int.inf.obs
#> 1      FALSE FALSE  FALSE     FALSE      FALSE   FALSE    FALSE           FALSE
#>   mrt.int.inf.pred mrt.iv.obs mrt.iv.pred mrt.md.obs mrt.md.pred mrt.ivmd.obs
#> 1            FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#>   mrt.ivmd.pred vz.obs vz.pred vz.int.inf.obs vz.int.inf.pred vz.iv.obs
#> 1         FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#>   vz.iv.pred vz.sparse.last vss.obs vss.pred vss.iv.obs vss.iv.pred vss.md.obs
#> 1      FALSE          FALSE   FALSE    FALSE      FALSE       FALSE      FALSE
#>   vss.md.pred vss.ivmd.obs vss.ivmd.pred vss.int.inf.obs vss.int.inf.pred
#> 1       FALSE        FALSE         FALSE           FALSE            FALSE
#>   cav.int.inf.obs cav.int.inf.pred cav.ivint.inf.obs cav.ivint.inf.pred
#> 1           FALSE            FALSE             FALSE              FALSE
#>   ratio.aucinf.obs ratio.aucinf.pred thalf.eff.obs thalf.eff.pred
#> 1            FALSE             FALSE         FALSE          FALSE
#>   thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs kel.iv.pred
#> 1            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
#>   kel.int.inf.obs kel.int.inf.pred auclast.dn aucall.dn aucinf.obs.dn
#> 1           FALSE            FALSE      FALSE     FALSE         FALSE
#>   aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn
#> 1          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
#>   cmin.dn clast.obs.dn clast.pred.dn cav.dn cav.last.dn ctrough.dn clr.last.dn
#> 1   FALSE        FALSE         FALSE  FALSE       FALSE      FALSE       FALSE
#>   clr.obs.dn clr.pred.dn              impute
#> 1      FALSE       FALSE start_predose_conc0

# At steady state, with the fluctuation parameters added
pknca_interval_table(
  144, 168,
  dosing = "steady_state", route = "extravascular",
  include = "fluctuation"
)
#>   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
#> 1   144 168   FALSE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#>   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
#> 1       FALSE       FALSE   FALSE      FALSE      FALSE        TRUE      FALSE
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbextint.last
#> 1        FALSE       FALSE         FALSE        FALSE              FALSE
#>   aucivpbextint.all aumcivint.last aumcivint.all    c0 cmax  cmin tmax  tmin
#> 1             FALSE          FALSE         FALSE FALSE TRUE FALSE TRUE FALSE
#>   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
#> 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#>   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
#> 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#>   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
#> 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#>   vss.int.last vss.ivint.all vss.ivint.last   cav cav.last cav.int.last
#> 1        FALSE         FALSE          FALSE FALSE    FALSE        FALSE
#>   cav.int.all cav.all cav.ivint.last cav.ivint.all ctrough cstart  ptr tlag
#> 1       FALSE   FALSE          FALSE         FALSE    TRUE  FALSE TRUE TRUE
#>   deg.fluc swing  ceoi aucabove.predose.all aucabove.trough.all count_conc
#> 1     TRUE  TRUE FALSE                FALSE               FALSE       TRUE
#>   count_conc_measured totdose volpk    ae clr.last clr.obs clr.pred    fe
#> 1               FALSE   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE
#>   ertlst ermax ertmax erint erlst ratio.cmax ratio.auclast ratio.aucint.last
#> 1  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE             FALSE
#>   ratio.aucint.all sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast
#> 1            FALSE          FALSE         FALSE         FALSE           FALSE
#>   sparse_aumc_se sparse_aumc_df time_above aucivlast aucivlast_se aucivlast_df
#> 1          FALSE          FALSE      FALSE     FALSE        FALSE        FALSE
#>   aucivall aucivall_se aucivall_df aucivpbextlast aucivpbextall aumcivlast
#> 1    FALSE       FALSE       FALSE          FALSE         FALSE      FALSE
#>   aumcivlast_se aumcivlast_df aumcivall aumcivall_se aumcivall_df half.life
#> 1         FALSE         FALSE     FALSE        FALSE        FALSE      TRUE
#>   r.squared adj.r.squared lambda.z.corrxy lambda.z lambda.z.time.first
#> 1     FALSE         FALSE           FALSE    FALSE               FALSE
#>   lambda.z.time.last lambda.z.n.points clast.pred span.ratio tobit_residual
#> 1              FALSE             FALSE      FALSE      FALSE          FALSE
#>   adj_tobit_residual lambda.z.n.points_blq thalf.eff.last thalf.eff.iv.last
#> 1              FALSE                 FALSE          FALSE             FALSE
#>   kel.last kel.iv.last kel.all kel.int.all kel.int.last kel.ivint.all
#> 1    FALSE       FALSE   FALSE       FALSE        FALSE         FALSE
#>   kel.ivint.last cl.iv.all cl.iv.last cl.sparse.last f.last f.int.last
#> 1          FALSE     FALSE      FALSE          FALSE  FALSE      FALSE
#>   f.int.all mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last vz.iv.all
#> 1     FALSE           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE
#>   vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.sparse.last
#> 1      FALSE        FALSE         FALSE   FALSE      FALSE           FALSE
#>   cav.iv.last cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred
#> 1       FALSE      FALSE      FALSE         FALSE         FALSE       FALSE
#>   aumcinf.obs aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs
#> 1       FALSE          FALSE          FALSE        FALSE           TRUE
#>   aucint.inf.pred aumcint.inf.obs aumcint.inf.pred aucivint.inf.obs
#> 1           FALSE           FALSE            FALSE            FALSE
#>   aucivint.inf.pred aucivinf.obs aucivinf.obs_se aucivinf.obs_df aucivinf.pred
#> 1             FALSE        FALSE           FALSE           FALSE         FALSE
#>   aucivpbextinf.obs aucivpbextinf.pred aumcivinf.obs aumcivinf.obs_se
#> 1             FALSE              FALSE         FALSE            FALSE
#>   aumcivinf.obs_df aumcivinf.pred aucpext.obs aucpext.pred kel.iv.all
#> 1            FALSE          FALSE       FALSE        FALSE      FALSE
#>   kel.sparse.last cl.obs cl.pred cl.int.inf.obs cl.int.inf.pred cl.iv.obs
#> 1           FALSE  FALSE   FALSE           TRUE           FALSE     FALSE
#>   cl.iv.pred f.obs f.pred f.int.obs f.int.pred mrt.obs mrt.pred mrt.int.inf.obs
#> 1      FALSE FALSE  FALSE     FALSE      FALSE   FALSE    FALSE           FALSE
#>   mrt.int.inf.pred mrt.iv.obs mrt.iv.pred mrt.md.obs mrt.md.pred mrt.ivmd.obs
#> 1            FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#>   mrt.ivmd.pred vz.obs vz.pred vz.int.inf.obs vz.int.inf.pred vz.iv.obs
#> 1         FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#>   vz.iv.pred vz.sparse.last vss.obs vss.pred vss.iv.obs vss.iv.pred vss.md.obs
#> 1      FALSE          FALSE   FALSE    FALSE      FALSE       FALSE      FALSE
#>   vss.md.pred vss.ivmd.obs vss.ivmd.pred vss.int.inf.obs vss.int.inf.pred
#> 1       FALSE        FALSE         FALSE           FALSE            FALSE
#>   cav.int.inf.obs cav.int.inf.pred cav.ivint.inf.obs cav.ivint.inf.pred
#> 1           FALSE            FALSE             FALSE              FALSE
#>   ratio.aucinf.obs ratio.aucinf.pred thalf.eff.obs thalf.eff.pred
#> 1            FALSE             FALSE         FALSE          FALSE
#>   thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs kel.iv.pred
#> 1            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
#>   kel.int.inf.obs kel.int.inf.pred auclast.dn aucall.dn aucinf.obs.dn
#> 1           FALSE            FALSE      FALSE     FALSE         FALSE
#>   aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn
#> 1          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
#>   cmin.dn clast.obs.dn clast.pred.dn cav.dn cav.last.dn ctrough.dn clr.last.dn
#> 1   FALSE        FALSE         FALSE  FALSE       FALSE      FALSE       FALSE
#>   clr.obs.dn clr.pred.dn        impute
#> 1      FALSE       FALSE start_predose

# A urine collection
pknca_interval_table(0, 24, dosing = "single", route = "extravascular",
                     sample_type = "interval")
#>   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
#> 1     0  24   FALSE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#>   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
#> 1       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbextint.last
#> 1        FALSE       FALSE         FALSE        FALSE              FALSE
#>   aucivpbextint.all aumcivint.last aumcivint.all    c0  cmax  cmin  tmax  tmin
#> 1             FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
#>   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
#> 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#>   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
#> 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#>   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
#> 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#>   vss.int.last vss.ivint.all vss.ivint.last   cav cav.last cav.int.last
#> 1        FALSE         FALSE          FALSE FALSE    FALSE        FALSE
#>   cav.int.all cav.all cav.ivint.last cav.ivint.all ctrough cstart   ptr  tlag
#> 1       FALSE   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE
#>   deg.fluc swing  ceoi aucabove.predose.all aucabove.trough.all count_conc
#> 1    FALSE FALSE FALSE                FALSE               FALSE      FALSE
#>   count_conc_measured totdose volpk   ae clr.last clr.obs clr.pred   fe ertlst
#> 1               FALSE   FALSE  TRUE TRUE    FALSE   FALSE    FALSE TRUE  FALSE
#>   ermax ertmax erint erlst ratio.cmax ratio.auclast ratio.aucint.last
#> 1 FALSE  FALSE FALSE FALSE      FALSE         FALSE             FALSE
#>   ratio.aucint.all sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast
#> 1            FALSE          FALSE         FALSE         FALSE           FALSE
#>   sparse_aumc_se sparse_aumc_df time_above aucivlast aucivlast_se aucivlast_df
#> 1          FALSE          FALSE      FALSE     FALSE        FALSE        FALSE
#>   aucivall aucivall_se aucivall_df aucivpbextlast aucivpbextall aumcivlast
#> 1    FALSE       FALSE       FALSE          FALSE         FALSE      FALSE
#>   aumcivlast_se aumcivlast_df aumcivall aumcivall_se aumcivall_df half.life
#> 1         FALSE         FALSE     FALSE        FALSE        FALSE     FALSE
#>   r.squared adj.r.squared lambda.z.corrxy lambda.z lambda.z.time.first
#> 1     FALSE         FALSE           FALSE    FALSE               FALSE
#>   lambda.z.time.last lambda.z.n.points clast.pred span.ratio tobit_residual
#> 1              FALSE             FALSE      FALSE      FALSE          FALSE
#>   adj_tobit_residual lambda.z.n.points_blq thalf.eff.last thalf.eff.iv.last
#> 1              FALSE                 FALSE          FALSE             FALSE
#>   kel.last kel.iv.last kel.all kel.int.all kel.int.last kel.ivint.all
#> 1    FALSE       FALSE   FALSE       FALSE        FALSE         FALSE
#>   kel.ivint.last cl.iv.all cl.iv.last cl.sparse.last f.last f.int.last
#> 1          FALSE     FALSE      FALSE          FALSE  FALSE      FALSE
#>   f.int.all mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last vz.iv.all
#> 1     FALSE           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE
#>   vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.sparse.last
#> 1      FALSE        FALSE         FALSE   FALSE      FALSE           FALSE
#>   cav.iv.last cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred
#> 1       FALSE      FALSE      FALSE         FALSE         FALSE       FALSE
#>   aumcinf.obs aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs
#> 1       FALSE          FALSE          FALSE        FALSE          FALSE
#>   aucint.inf.pred aumcint.inf.obs aumcint.inf.pred aucivint.inf.obs
#> 1           FALSE           FALSE            FALSE            FALSE
#>   aucivint.inf.pred aucivinf.obs aucivinf.obs_se aucivinf.obs_df aucivinf.pred
#> 1             FALSE        FALSE           FALSE           FALSE         FALSE
#>   aucivpbextinf.obs aucivpbextinf.pred aumcivinf.obs aumcivinf.obs_se
#> 1             FALSE              FALSE         FALSE            FALSE
#>   aumcivinf.obs_df aumcivinf.pred aucpext.obs aucpext.pred kel.iv.all
#> 1            FALSE          FALSE       FALSE        FALSE      FALSE
#>   kel.sparse.last cl.obs cl.pred cl.int.inf.obs cl.int.inf.pred cl.iv.obs
#> 1           FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#>   cl.iv.pred f.obs f.pred f.int.obs f.int.pred mrt.obs mrt.pred mrt.int.inf.obs
#> 1      FALSE FALSE  FALSE     FALSE      FALSE   FALSE    FALSE           FALSE
#>   mrt.int.inf.pred mrt.iv.obs mrt.iv.pred mrt.md.obs mrt.md.pred mrt.ivmd.obs
#> 1            FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#>   mrt.ivmd.pred vz.obs vz.pred vz.int.inf.obs vz.int.inf.pred vz.iv.obs
#> 1         FALSE  FALSE   FALSE          FALSE           FALSE     FALSE
#>   vz.iv.pred vz.sparse.last vss.obs vss.pred vss.iv.obs vss.iv.pred vss.md.obs
#> 1      FALSE          FALSE   FALSE    FALSE      FALSE       FALSE      FALSE
#>   vss.md.pred vss.ivmd.obs vss.ivmd.pred vss.int.inf.obs vss.int.inf.pred
#> 1       FALSE        FALSE         FALSE           FALSE            FALSE
#>   cav.int.inf.obs cav.int.inf.pred cav.ivint.inf.obs cav.ivint.inf.pred
#> 1           FALSE            FALSE             FALSE              FALSE
#>   ratio.aucinf.obs ratio.aucinf.pred thalf.eff.obs thalf.eff.pred
#> 1            FALSE             FALSE         FALSE          FALSE
#>   thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs kel.iv.pred
#> 1            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
#>   kel.int.inf.obs kel.int.inf.pred auclast.dn aucall.dn aucinf.obs.dn
#> 1           FALSE            FALSE      FALSE     FALSE         FALSE
#>   aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn
#> 1          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
#>   cmin.dn clast.obs.dn clast.pred.dn cav.dn cav.last.dn ctrough.dn clr.last.dn
#> 1   FALSE        FALSE         FALSE  FALSE       FALSE      FALSE       FALSE
#>   clr.obs.dn clr.pred.dn
#> 1      FALSE       FALSE
```
