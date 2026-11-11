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
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbext.int.last
#> 1        FALSE       FALSE         FALSE        FALSE               FALSE
#>   aucivpbext.int.all aumcivint.last aumcivint.all    c0 cmax  cmin tmax  tmin
#> 1              FALSE          FALSE         FALSE FALSE TRUE FALSE TRUE FALSE
#>   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
#> 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#>   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
#> 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#>   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
#> 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#>   vss.int.last vss.ivint.all vss.ivint.last cav.last cav.int.last cav.int.all
#> 1        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
#>   cav.all cav.ivint.last cav.ivint.all ctrough cstart   ptr tlag deg.fluc swing
#> 1   FALSE          FALSE         FALSE   FALSE  FALSE FALSE TRUE    FALSE FALSE
#>    ceoi aucabove.predose.all aucabove.trough.all count.conc count.conc.measured
#> 1 FALSE                FALSE               FALSE       TRUE               FALSE
#>   totdose volpk    ae clr.last clr.int.inf.pred clr.int.inf.obs clr.int.all
#> 1   FALSE FALSE FALSE    FALSE            FALSE           FALSE       FALSE
#>   clr.int.last clr.all clr.inf.obs clr.inf.pred    fe ertlst ermax ertmax erint
#> 1        FALSE   FALSE       FALSE        FALSE FALSE  FALSE FALSE  FALSE FALSE
#>   erlst ratio.cmax ratio.auclast ratio.aucint.last ratio.aucint.all
#> 1 FALSE      FALSE         FALSE             FALSE            FALSE
#>   sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast sparse_aumc_se
#> 1          FALSE         FALSE         FALSE           FALSE          FALSE
#>   sparse_aumc_df time.above aucivlast aucivlast_se aucivlast_df aucivall
#> 1          FALSE      FALSE     FALSE        FALSE        FALSE    FALSE
#>   aucivall_se aucivall_df aucivpbext.last aucivpbext.all aumcivlast
#> 1       FALSE       FALSE           FALSE          FALSE      FALSE
#>   aumcivlast_se aumcivlast_df aumcivall aumcivall_se aumcivall_df half.life
#> 1         FALSE         FALSE     FALSE        FALSE        FALSE      TRUE
#>   r.squared adj.r.squared lambda.z.corrxy lambda.z lambda.z.time.first
#> 1     FALSE         FALSE           FALSE    FALSE               FALSE
#>   lambda.z.time.last lambda.z.n.points clast.pred span.ratio tobit.residual
#> 1              FALSE             FALSE      FALSE      FALSE          FALSE
#>   adj.tobit.residual lambda.z.n.points.blq thalf.eff.last thalf.eff.int.all
#> 1              FALSE                 FALSE          FALSE             FALSE
#>   thalf.eff.int.last thalf.eff.all thalf.eff.iv.last thalf.eff.ivint.all
#> 1              FALSE         FALSE             FALSE               FALSE
#>   thalf.eff.ivint.last kel.last kel.iv.last kel.all kel.int.all kel.int.last
#> 1                FALSE    FALSE       FALSE   FALSE       FALSE        FALSE
#>   kel.ivint.all kel.ivint.last cl.iv.all cl.iv.last cl.sparse.last f.last f.all
#> 1         FALSE          FALSE     FALSE      FALSE          FALSE  FALSE FALSE
#>   f.int.last f.int.all mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last
#> 1      FALSE     FALSE           FALSE      FALSE  FALSE      FALSE       FALSE
#>   vz.iv.all vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all
#> 1     FALSE      FALSE        FALSE         FALSE   FALSE      FALSE
#>   vss.sparse.last cav.iv.last cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df
#> 1           FALSE       FALSE      FALSE       TRUE         FALSE         FALSE
#>   aucinf.pred aumcinf.obs aumcinf.obs_se aumcinf.obs_df aumcinf.pred
#> 1       FALSE       FALSE          FALSE          FALSE        FALSE
#>   aucint.inf.obs aucint.inf.pred aumcint.inf.obs aumcint.inf.pred
#> 1          FALSE           FALSE           FALSE            FALSE
#>   aucivint.inf.obs aucivint.inf.pred aucivinf.obs aucivinf.obs_se
#> 1            FALSE             FALSE        FALSE           FALSE
#>   aucivinf.obs_df aucivinf.pred aucivpbext.inf.obs aucivpbext.inf.pred
#> 1           FALSE         FALSE              FALSE               FALSE
#>   aumcivint.inf.pred aumcivint.inf.obs aumcivinf.obs aumcivinf.obs_se
#> 1              FALSE             FALSE         FALSE            FALSE
#>   aumcivinf.obs_df aumcivinf.pred thalf.eff.iv.all aucpext.inf.obs
#> 1            FALSE          FALSE            FALSE            TRUE
#>   aucpext.inf.pred kel.iv.all kel.sparse.last cl.inf.obs cl.inf.pred
#> 1            FALSE      FALSE           FALSE       TRUE       FALSE
#>   cl.int.inf.obs cl.int.inf.pred cl.iv.inf.obs cl.iv.inf.pred cl.ivint.inf.pred
#> 1          FALSE           FALSE         FALSE          FALSE             FALSE
#>   cl.ivint.inf.obs f.inf.obs f.inf.pred f.int.inf.obs f.int.inf.pred
#> 1            FALSE     FALSE      FALSE         FALSE          FALSE
#>   mrt.inf.obs mrt.inf.pred mrt.int.inf.obs mrt.int.inf.pred mrt.iv.inf.obs
#> 1       FALSE        FALSE           FALSE            FALSE          FALSE
#>   mrt.iv.inf.pred mrt.ivint.inf.pred mrt.ivint.inf.obs mrt.md.inf.obs
#> 1           FALSE              FALSE             FALSE          FALSE
#>   mrt.md.inf.pred mrt.ivmd.inf.obs mrt.ivmd.inf.pred vz.inf.obs vz.inf.pred
#> 1           FALSE            FALSE             FALSE      FALSE       FALSE
#>   vz.int.inf.obs vz.int.inf.pred vz.iv.inf.obs vz.iv.inf.pred vz.ivint.inf.pred
#> 1          FALSE           FALSE         FALSE          FALSE             FALSE
#>   vz.ivint.inf.obs vz.sparse.last vss.inf.obs vss.inf.pred vss.iv.inf.obs
#> 1            FALSE          FALSE       FALSE        FALSE          FALSE
#>   vss.iv.inf.pred vss.md.inf.obs vss.md.inf.pred vss.ivmd.inf.obs
#> 1           FALSE          FALSE           FALSE            FALSE
#>   vss.ivmd.inf.pred vss.int.inf.obs vss.int.inf.pred vss.ivint.inf.pred
#> 1             FALSE           FALSE            FALSE              FALSE
#>   vss.ivint.inf.obs cav.int.inf.obs cav.int.inf.pred cav.ivint.inf.obs
#> 1             FALSE           FALSE            FALSE             FALSE
#>   cav.ivint.inf.pred ratio.aucinf.obs ratio.aucinf.pred thalf.eff.inf.obs
#> 1              FALSE            FALSE             FALSE             FALSE
#>   thalf.eff.inf.pred thalf.eff.int.inf.pred thalf.eff.int.inf.obs
#> 1              FALSE                  FALSE                 FALSE
#>   thalf.eff.iv.inf.obs thalf.eff.iv.inf.pred thalf.eff.ivint.inf.pred
#> 1                FALSE                 FALSE                    FALSE
#>   thalf.eff.ivint.inf.obs kel.inf.obs kel.inf.pred kel.iv.inf.obs
#> 1                   FALSE       FALSE        FALSE          FALSE
#>   kel.iv.inf.pred kel.int.inf.obs kel.int.inf.pred kel.ivint.inf.pred
#> 1           FALSE           FALSE            FALSE              FALSE
#>   kel.ivint.inf.obs auclast.dn aucall.dn aucinf.obs.dn aucinf.pred.dn
#> 1             FALSE      FALSE     FALSE         FALSE          FALSE
#>   aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn cmin.dn
#> 1       FALSE      FALSE          FALSE           FALSE   FALSE   FALSE
#>   clast.obs.dn clast.pred.dn cav.last.dn ctrough.dn adj_tobit_residual
#> 1        FALSE         FALSE       FALSE      FALSE              FALSE
#>   aucivpbextall aucivpbextinf.obs aucivpbextinf.pred aucivpbextint.all
#> 1         FALSE             FALSE              FALSE             FALSE
#>   aucivpbextint.last aucivpbextlast aucpext.obs aucpext.pred   cav cav.dn
#> 1              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
#>   cl.iv.obs cl.iv.pred cl.obs cl.pred clr.obs clr.pred count_conc
#> 1     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
#>   count_conc_measured f.int.obs f.int.pred f.obs f.pred kel.iv.obs kel.iv.pred
#> 1               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
#>   kel.obs kel.pred lambda.z.n.points_blq mrt.iv.obs mrt.iv.pred mrt.ivmd.obs
#> 1   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
#>   mrt.ivmd.pred mrt.md.obs mrt.md.pred mrt.obs mrt.pred thalf.eff.iv.obs
#> 1         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
#>   thalf.eff.iv.pred thalf.eff.obs thalf.eff.pred time_above tobit_residual
#> 1             FALSE         FALSE          FALSE      FALSE          FALSE
#>   vss.iv.obs vss.iv.pred vss.ivmd.obs vss.ivmd.pred vss.md.obs vss.md.pred
#> 1      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
#>   vss.obs vss.pred vz.iv.obs vz.iv.pred vz.obs vz.pred              impute
#> 1   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE start_predose_conc0

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
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbext.int.last
#> 1        FALSE       FALSE         FALSE        FALSE               FALSE
#>   aucivpbext.int.all aumcivint.last aumcivint.all    c0 cmax  cmin tmax  tmin
#> 1              FALSE          FALSE         FALSE FALSE TRUE FALSE TRUE FALSE
#>   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
#> 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#>   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
#> 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#>   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
#> 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#>   vss.int.last vss.ivint.all vss.ivint.last cav.last cav.int.last cav.int.all
#> 1        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
#>   cav.all cav.ivint.last cav.ivint.all ctrough cstart  ptr tlag deg.fluc swing
#> 1   FALSE          FALSE         FALSE    TRUE  FALSE TRUE TRUE     TRUE  TRUE
#>    ceoi aucabove.predose.all aucabove.trough.all count.conc count.conc.measured
#> 1 FALSE                FALSE               FALSE       TRUE               FALSE
#>   totdose volpk    ae clr.last clr.int.inf.pred clr.int.inf.obs clr.int.all
#> 1   FALSE FALSE FALSE    FALSE            FALSE           FALSE       FALSE
#>   clr.int.last clr.all clr.inf.obs clr.inf.pred    fe ertlst ermax ertmax erint
#> 1        FALSE   FALSE       FALSE        FALSE FALSE  FALSE FALSE  FALSE FALSE
#>   erlst ratio.cmax ratio.auclast ratio.aucint.last ratio.aucint.all
#> 1 FALSE      FALSE         FALSE             FALSE            FALSE
#>   sparse_auclast sparse_auc_se sparse_auc_df sparse_aumclast sparse_aumc_se
#> 1          FALSE         FALSE         FALSE           FALSE          FALSE
#>   sparse_aumc_df time.above aucivlast aucivlast_se aucivlast_df aucivall
#> 1          FALSE      FALSE     FALSE        FALSE        FALSE    FALSE
#>   aucivall_se aucivall_df aucivpbext.last aucivpbext.all aumcivlast
#> 1       FALSE       FALSE           FALSE          FALSE      FALSE
#>   aumcivlast_se aumcivlast_df aumcivall aumcivall_se aumcivall_df half.life
#> 1         FALSE         FALSE     FALSE        FALSE        FALSE      TRUE
#>   r.squared adj.r.squared lambda.z.corrxy lambda.z lambda.z.time.first
#> 1     FALSE         FALSE           FALSE    FALSE               FALSE
#>   lambda.z.time.last lambda.z.n.points clast.pred span.ratio tobit.residual
#> 1              FALSE             FALSE      FALSE      FALSE          FALSE
#>   adj.tobit.residual lambda.z.n.points.blq thalf.eff.last thalf.eff.int.all
#> 1              FALSE                 FALSE          FALSE             FALSE
#>   thalf.eff.int.last thalf.eff.all thalf.eff.iv.last thalf.eff.ivint.all
#> 1              FALSE         FALSE             FALSE               FALSE
#>   thalf.eff.ivint.last kel.last kel.iv.last kel.all kel.int.all kel.int.last
#> 1                FALSE    FALSE       FALSE   FALSE       FALSE        FALSE
#>   kel.ivint.all kel.ivint.last cl.iv.all cl.iv.last cl.sparse.last f.last f.all
#> 1         FALSE          FALSE     FALSE      FALSE          FALSE  FALSE FALSE
#>   f.int.last f.int.all mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last
#> 1      FALSE     FALSE           FALSE      FALSE  FALSE      FALSE       FALSE
#>   vz.iv.all vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all
#> 1     FALSE      FALSE        FALSE         FALSE   FALSE      FALSE
#>   vss.sparse.last cav.iv.last cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df
#> 1           FALSE       FALSE      FALSE      FALSE         FALSE         FALSE
#>   aucinf.pred aumcinf.obs aumcinf.obs_se aumcinf.obs_df aumcinf.pred
#> 1       FALSE       FALSE          FALSE          FALSE        FALSE
#>   aucint.inf.obs aucint.inf.pred aumcint.inf.obs aumcint.inf.pred
#> 1           TRUE           FALSE           FALSE            FALSE
#>   aucivint.inf.obs aucivint.inf.pred aucivinf.obs aucivinf.obs_se
#> 1            FALSE             FALSE        FALSE           FALSE
#>   aucivinf.obs_df aucivinf.pred aucivpbext.inf.obs aucivpbext.inf.pred
#> 1           FALSE         FALSE              FALSE               FALSE
#>   aumcivint.inf.pred aumcivint.inf.obs aumcivinf.obs aumcivinf.obs_se
#> 1              FALSE             FALSE         FALSE            FALSE
#>   aumcivinf.obs_df aumcivinf.pred thalf.eff.iv.all aucpext.inf.obs
#> 1            FALSE          FALSE            FALSE           FALSE
#>   aucpext.inf.pred kel.iv.all kel.sparse.last cl.inf.obs cl.inf.pred
#> 1            FALSE      FALSE           FALSE      FALSE       FALSE
#>   cl.int.inf.obs cl.int.inf.pred cl.iv.inf.obs cl.iv.inf.pred cl.ivint.inf.pred
#> 1           TRUE           FALSE         FALSE          FALSE             FALSE
#>   cl.ivint.inf.obs f.inf.obs f.inf.pred f.int.inf.obs f.int.inf.pred
#> 1            FALSE     FALSE      FALSE         FALSE          FALSE
#>   mrt.inf.obs mrt.inf.pred mrt.int.inf.obs mrt.int.inf.pred mrt.iv.inf.obs
#> 1       FALSE        FALSE           FALSE            FALSE          FALSE
#>   mrt.iv.inf.pred mrt.ivint.inf.pred mrt.ivint.inf.obs mrt.md.inf.obs
#> 1           FALSE              FALSE             FALSE          FALSE
#>   mrt.md.inf.pred mrt.ivmd.inf.obs mrt.ivmd.inf.pred vz.inf.obs vz.inf.pred
#> 1           FALSE            FALSE             FALSE      FALSE       FALSE
#>   vz.int.inf.obs vz.int.inf.pred vz.iv.inf.obs vz.iv.inf.pred vz.ivint.inf.pred
#> 1          FALSE           FALSE         FALSE          FALSE             FALSE
#>   vz.ivint.inf.obs vz.sparse.last vss.inf.obs vss.inf.pred vss.iv.inf.obs
#> 1            FALSE          FALSE       FALSE        FALSE          FALSE
#>   vss.iv.inf.pred vss.md.inf.obs vss.md.inf.pred vss.ivmd.inf.obs
#> 1           FALSE          FALSE           FALSE            FALSE
#>   vss.ivmd.inf.pred vss.int.inf.obs vss.int.inf.pred vss.ivint.inf.pred
#> 1             FALSE           FALSE            FALSE              FALSE
#>   vss.ivint.inf.obs cav.int.inf.obs cav.int.inf.pred cav.ivint.inf.obs
#> 1             FALSE           FALSE            FALSE             FALSE
#>   cav.ivint.inf.pred ratio.aucinf.obs ratio.aucinf.pred thalf.eff.inf.obs
#> 1              FALSE            FALSE             FALSE             FALSE
#>   thalf.eff.inf.pred thalf.eff.int.inf.pred thalf.eff.int.inf.obs
#> 1              FALSE                  FALSE                 FALSE
#>   thalf.eff.iv.inf.obs thalf.eff.iv.inf.pred thalf.eff.ivint.inf.pred
#> 1                FALSE                 FALSE                    FALSE
#>   thalf.eff.ivint.inf.obs kel.inf.obs kel.inf.pred kel.iv.inf.obs
#> 1                   FALSE       FALSE        FALSE          FALSE
#>   kel.iv.inf.pred kel.int.inf.obs kel.int.inf.pred kel.ivint.inf.pred
#> 1           FALSE           FALSE            FALSE              FALSE
#>   kel.ivint.inf.obs auclast.dn aucall.dn aucinf.obs.dn aucinf.pred.dn
#> 1             FALSE      FALSE     FALSE         FALSE          FALSE
#>   aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn cmin.dn
#> 1       FALSE      FALSE          FALSE           FALSE   FALSE   FALSE
#>   clast.obs.dn clast.pred.dn cav.last.dn ctrough.dn adj_tobit_residual
#> 1        FALSE         FALSE       FALSE      FALSE              FALSE
#>   aucivpbextall aucivpbextinf.obs aucivpbextinf.pred aucivpbextint.all
#> 1         FALSE             FALSE              FALSE             FALSE
#>   aucivpbextint.last aucivpbextlast aucpext.obs aucpext.pred   cav cav.dn
#> 1              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
#>   cl.iv.obs cl.iv.pred cl.obs cl.pred clr.obs clr.pred count_conc
#> 1     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
#>   count_conc_measured f.int.obs f.int.pred f.obs f.pred kel.iv.obs kel.iv.pred
#> 1               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
#>   kel.obs kel.pred lambda.z.n.points_blq mrt.iv.obs mrt.iv.pred mrt.ivmd.obs
#> 1   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
#>   mrt.ivmd.pred mrt.md.obs mrt.md.pred mrt.obs mrt.pred thalf.eff.iv.obs
#> 1         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
#>   thalf.eff.iv.pred thalf.eff.obs thalf.eff.pred time_above tobit_residual
#> 1             FALSE         FALSE          FALSE      FALSE          FALSE
#>   vss.iv.obs vss.iv.pred vss.ivmd.obs vss.ivmd.pred vss.md.obs vss.md.pred
#> 1      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
#>   vss.obs vss.pred vz.iv.obs vz.iv.pred vz.obs vz.pred        impute
#> 1   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE start_predose

# A urine collection
pknca_interval_table(0, 24, dosing = "single", route = "extravascular",
                     sample_type = "interval")
#>   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
#> 1     0  24   FALSE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#>   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
#> 1       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbext.int.last
#> 1        FALSE       FALSE         FALSE        FALSE               FALSE
#>   aucivpbext.int.all aumcivint.last aumcivint.all    c0  cmax  cmin  tmax  tmin
#> 1              FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
#>   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
#> 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
#>   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
#> 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
#>   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
#> 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
#>   vss.int.last vss.ivint.all vss.ivint.last cav.last cav.int.last cav.int.all
#> 1        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
#>   cav.all cav.ivint.last cav.ivint.all ctrough cstart   ptr  tlag deg.fluc
#> 1   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE    FALSE
#>   swing  ceoi aucabove.predose.all aucabove.trough.all count.conc
#> 1 FALSE FALSE                FALSE               FALSE      FALSE
#>   count.conc.measured totdose volpk   ae clr.last clr.int.inf.pred
#> 1               FALSE   FALSE  TRUE TRUE    FALSE            FALSE
#>   clr.int.inf.obs clr.int.all clr.int.last clr.all clr.inf.obs clr.inf.pred
#> 1           FALSE       FALSE        FALSE   FALSE       FALSE        FALSE
#>     fe ertlst ermax ertmax erint erlst ratio.cmax ratio.auclast
#> 1 TRUE  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE
#>   ratio.aucint.last ratio.aucint.all sparse_auclast sparse_auc_se sparse_auc_df
#> 1             FALSE            FALSE          FALSE         FALSE         FALSE
#>   sparse_aumclast sparse_aumc_se sparse_aumc_df time.above aucivlast
#> 1           FALSE          FALSE          FALSE      FALSE     FALSE
#>   aucivlast_se aucivlast_df aucivall aucivall_se aucivall_df aucivpbext.last
#> 1        FALSE        FALSE    FALSE       FALSE       FALSE           FALSE
#>   aucivpbext.all aumcivlast aumcivlast_se aumcivlast_df aumcivall aumcivall_se
#> 1          FALSE      FALSE         FALSE         FALSE     FALSE        FALSE
#>   aumcivall_df half.life r.squared adj.r.squared lambda.z.corrxy lambda.z
#> 1        FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
#>   lambda.z.time.first lambda.z.time.last lambda.z.n.points clast.pred
#> 1               FALSE              FALSE             FALSE      FALSE
#>   span.ratio tobit.residual adj.tobit.residual lambda.z.n.points.blq
#> 1      FALSE          FALSE              FALSE                 FALSE
#>   thalf.eff.last thalf.eff.int.all thalf.eff.int.last thalf.eff.all
#> 1          FALSE             FALSE              FALSE         FALSE
#>   thalf.eff.iv.last thalf.eff.ivint.all thalf.eff.ivint.last kel.last
#> 1             FALSE               FALSE                FALSE    FALSE
#>   kel.iv.last kel.all kel.int.all kel.int.last kel.ivint.all kel.ivint.last
#> 1       FALSE   FALSE       FALSE        FALSE         FALSE          FALSE
#>   cl.iv.all cl.iv.last cl.sparse.last f.last f.all f.int.last f.int.all
#> 1     FALSE      FALSE          FALSE  FALSE FALSE      FALSE     FALSE
#>   mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last vz.iv.all vz.iv.last
#> 1           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
#>   vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.sparse.last cav.iv.last
#> 1        FALSE         FALSE   FALSE      FALSE           FALSE       FALSE
#>   cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred aumcinf.obs
#> 1      FALSE      FALSE         FALSE         FALSE       FALSE       FALSE
#>   aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs aucint.inf.pred
#> 1          FALSE          FALSE        FALSE          FALSE           FALSE
#>   aumcint.inf.obs aumcint.inf.pred aucivint.inf.obs aucivint.inf.pred
#> 1           FALSE            FALSE            FALSE             FALSE
#>   aucivinf.obs aucivinf.obs_se aucivinf.obs_df aucivinf.pred aucivpbext.inf.obs
#> 1        FALSE           FALSE           FALSE         FALSE              FALSE
#>   aucivpbext.inf.pred aumcivint.inf.pred aumcivint.inf.obs aumcivinf.obs
#> 1               FALSE              FALSE             FALSE         FALSE
#>   aumcivinf.obs_se aumcivinf.obs_df aumcivinf.pred thalf.eff.iv.all
#> 1            FALSE            FALSE          FALSE            FALSE
#>   aucpext.inf.obs aucpext.inf.pred kel.iv.all kel.sparse.last cl.inf.obs
#> 1           FALSE            FALSE      FALSE           FALSE      FALSE
#>   cl.inf.pred cl.int.inf.obs cl.int.inf.pred cl.iv.inf.obs cl.iv.inf.pred
#> 1       FALSE          FALSE           FALSE         FALSE          FALSE
#>   cl.ivint.inf.pred cl.ivint.inf.obs f.inf.obs f.inf.pred f.int.inf.obs
#> 1             FALSE            FALSE     FALSE      FALSE         FALSE
#>   f.int.inf.pred mrt.inf.obs mrt.inf.pred mrt.int.inf.obs mrt.int.inf.pred
#> 1          FALSE       FALSE        FALSE           FALSE            FALSE
#>   mrt.iv.inf.obs mrt.iv.inf.pred mrt.ivint.inf.pred mrt.ivint.inf.obs
#> 1          FALSE           FALSE              FALSE             FALSE
#>   mrt.md.inf.obs mrt.md.inf.pred mrt.ivmd.inf.obs mrt.ivmd.inf.pred vz.inf.obs
#> 1          FALSE           FALSE            FALSE             FALSE      FALSE
#>   vz.inf.pred vz.int.inf.obs vz.int.inf.pred vz.iv.inf.obs vz.iv.inf.pred
#> 1       FALSE          FALSE           FALSE         FALSE          FALSE
#>   vz.ivint.inf.pred vz.ivint.inf.obs vz.sparse.last vss.inf.obs vss.inf.pred
#> 1             FALSE            FALSE          FALSE       FALSE        FALSE
#>   vss.iv.inf.obs vss.iv.inf.pred vss.md.inf.obs vss.md.inf.pred
#> 1          FALSE           FALSE          FALSE           FALSE
#>   vss.ivmd.inf.obs vss.ivmd.inf.pred vss.int.inf.obs vss.int.inf.pred
#> 1            FALSE             FALSE           FALSE            FALSE
#>   vss.ivint.inf.pred vss.ivint.inf.obs cav.int.inf.obs cav.int.inf.pred
#> 1              FALSE             FALSE           FALSE            FALSE
#>   cav.ivint.inf.obs cav.ivint.inf.pred ratio.aucinf.obs ratio.aucinf.pred
#> 1             FALSE              FALSE            FALSE             FALSE
#>   thalf.eff.inf.obs thalf.eff.inf.pred thalf.eff.int.inf.pred
#> 1             FALSE              FALSE                  FALSE
#>   thalf.eff.int.inf.obs thalf.eff.iv.inf.obs thalf.eff.iv.inf.pred
#> 1                 FALSE                FALSE                 FALSE
#>   thalf.eff.ivint.inf.pred thalf.eff.ivint.inf.obs kel.inf.obs kel.inf.pred
#> 1                    FALSE                   FALSE       FALSE        FALSE
#>   kel.iv.inf.obs kel.iv.inf.pred kel.int.inf.obs kel.int.inf.pred
#> 1          FALSE           FALSE           FALSE            FALSE
#>   kel.ivint.inf.pred kel.ivint.inf.obs auclast.dn aucall.dn aucinf.obs.dn
#> 1              FALSE             FALSE      FALSE     FALSE         FALSE
#>   aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn
#> 1          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
#>   cmin.dn clast.obs.dn clast.pred.dn cav.last.dn ctrough.dn adj_tobit_residual
#> 1   FALSE        FALSE         FALSE       FALSE      FALSE              FALSE
#>   aucivpbextall aucivpbextinf.obs aucivpbextinf.pred aucivpbextint.all
#> 1         FALSE             FALSE              FALSE             FALSE
#>   aucivpbextint.last aucivpbextlast aucpext.obs aucpext.pred   cav cav.dn
#> 1              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
#>   cl.iv.obs cl.iv.pred cl.obs cl.pred clr.obs clr.pred count_conc
#> 1     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
#>   count_conc_measured f.int.obs f.int.pred f.obs f.pred kel.iv.obs kel.iv.pred
#> 1               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
#>   kel.obs kel.pred lambda.z.n.points_blq mrt.iv.obs mrt.iv.pred mrt.ivmd.obs
#> 1   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
#>   mrt.ivmd.pred mrt.md.obs mrt.md.pred mrt.obs mrt.pred thalf.eff.iv.obs
#> 1         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
#>   thalf.eff.iv.pred thalf.eff.obs thalf.eff.pred time_above tobit_residual
#> 1             FALSE         FALSE          FALSE      FALSE          FALSE
#>   vss.iv.obs vss.iv.pred vss.ivmd.obs vss.ivmd.pred vss.md.obs vss.md.pred
#> 1      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
#>   vss.obs vss.pred vz.iv.obs vz.iv.pred vz.obs vz.pred
#> 1   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE
```
