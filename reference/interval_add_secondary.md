# Link a secondary parameter to the interval it is calculated against

A secondary parameter needs a result from a second profile: renal
clearance divides an amount excreted in urine by a plasma AUC, an
accumulation ratio compares one dosing interval with another, and a
metabolite ratio compares two analytes. This adds the request and the
linkage columns (`interval_id` on the reference interval and
`<param>_ref` on the intervals calculating the parameter) that
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
reads.

## Usage

``` r
interval_add_secondary(
  data,
  param,
  reference = NULL,
  target_groups = NULL,
  ref_id = NULL,
  ...
)
```

## Arguments

- data:

  A `PKNCAdata` object or a data.frame of intervals.

- param:

  The name of one secondary NCA parameter (see
  [`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md)
  for which parameters are secondary).

- reference:

  A data.frame describing the reference interval: its columns are
  `start`, `end`, and/or group columns of the intervals, every column
  must match (and) for at least one of its rows (or). A named list is
  accepted and coerced. When no interval matches, one is created and the
  creation is reported with a `pknca_message_secondary_created_interval`
  message. `NULL` (the default) takes the `group_ref` given to
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  (resolved for `param` when it is parameter-specific), or derives the
  reference from the data (see Details).

- target_groups:

  A data.frame of group values restricting the parameter request to
  matching intervals, with the same matching rules as `reference`.
  `NULL` (the default) requests it on every interval that is not a
  reference interval.

- ref_id:

  The `interval_id` to give the reference interval. The default of
  `NULL` keeps an identifier the reference rows already have and
  otherwise generates one matching the class of the `interval_id`
  column.

- ...:

  Ignored.

## Value

The input with the parameter requested and the linkage columns set,
after
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md).

## Details

The reference interval gains whatever the linked calculation reads from
it (the plasma AUC for a renal clearance, for example) without being
announced, as calculating any dependency is.

An interval that already names a different reference for `param` is left
alone with a `pknca_warning_secondary_ref_exists` warning, so that the
helper never silently re-points an analysis.

With `reference = NULL` the reference is derived from the data, which
needs a `PKNCAdata` object (a bare intervals data.frame carries no
concentrations to derive it from). The `group_ref` given to
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
is used when it is set. Otherwise the derivation applies where the
parameter is measured on an interval collection while everything it
references is a spot sample (renal clearance) and the concentration data
declare a collection `volume`: each interval takes the profile with no
collection volume that differs from its own in the fewest group columns.
This is the same derivation
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
makes on its own, written out into the returned intervals instead of
being ephemeral. Anything the derivation cannot resolve is an error here
(`pknca_error_secondary_needs_ref`) rather than the `NA` result the
automatic path gives, so narrow the request with `target_groups` when
some intervals are not meant to calculate `param`.

When the parameter pairs an interval collection with spot-sample
references (renal clearance: an amount excreted against a plasma AUC)
and the reference interval is created by the `PKNCAdata` method, the
created interval spans the collections whole: a collection that begins
inside the interval contributes its full amount (see
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)), so
a collection running past the interval's `end` extends the created
reference's `end` to `time + duration` of the latest collection. An
explicit `end` in `reference` overrides the extension, and the
data.frame method (which has no concentration data) copies the test
interval's times unchanged.

## See also

[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md),
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md),
[`pknca_ref()`](https://humanpred.github.io/pknca/reference/pknca_ref.md)

## Examples

``` r
intervals <-
  data.frame(
    PCSPEC = c("plasma", "urine"),
    start = 0, end = 24,
    auclast = c(TRUE, FALSE),
    ae = c(FALSE, TRUE)
  )
interval_add_secondary(
  intervals,
  param = "clr.last",
  reference = data.frame(PCSPEC = "plasma")
)
#>   start end auclast aucall aumclast aumcall aucint.last aucint.last.dose
#> 1     0  24    TRUE  FALSE    FALSE   FALSE       FALSE            FALSE
#> 2     0  24   FALSE  FALSE    FALSE   FALSE       FALSE            FALSE
#>   aucint.all aucint.all.dose aumcint.last aumcint.last.dose aumcint.all
#> 1      FALSE           FALSE        FALSE             FALSE       FALSE
#> 2      FALSE           FALSE        FALSE             FALSE       FALSE
#>   aumcint.all.dose    c0  cmax  cmin  tmax  tmin tlast tfirst clast.obs cl.last
#> 1            FALSE FALSE FALSE FALSE FALSE FALSE FALSE  FALSE     FALSE   FALSE
#> 2            FALSE FALSE FALSE FALSE FALSE FALSE FALSE  FALSE     FALSE   FALSE
#>   cl.all cl.int.all cl.int.last mrt.last mrt.all mrt.int.all mrt.int.last
#> 1  FALSE      FALSE       FALSE    FALSE   FALSE       FALSE        FALSE
#> 2  FALSE      FALSE       FALSE    FALSE   FALSE       FALSE        FALSE
#>   mrt.iv.last vss.last vss.iv.last vss.all vss.int.all vss.int.last   cav
#> 1       FALSE    FALSE       FALSE   FALSE       FALSE        FALSE FALSE
#> 2       FALSE    FALSE       FALSE   FALSE       FALSE        FALSE FALSE
#>   cav.int.last cav.int.all ctrough cstart   ptr  tlag deg.fluc swing  ceoi
#> 1        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
#> 2        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
#>   aucabove.predose.all aucabove.trough.all count_conc count_conc_measured
#> 1                FALSE               FALSE      FALSE               FALSE
#> 2                FALSE               FALSE      FALSE               FALSE
#>   totdose volpk    ae clr.last clr.obs clr.pred    fe ertlst ermax ertmax erint
#> 1   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE  FALSE FALSE  FALSE FALSE
#> 2   FALSE FALSE  TRUE     TRUE   FALSE    FALSE FALSE  FALSE FALSE  FALSE FALSE
#>   erlst ratio.cmax ratio.auclast ratio.aucint.last ratio.aucint.all
#> 1 FALSE      FALSE         FALSE             FALSE            FALSE
#> 2 FALSE      FALSE         FALSE             FALSE            FALSE
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
#> 2     FALSE          FALSE         FALSE     FALSE     FALSE         FALSE
#>   lambda.z.corrxy lambda.z lambda.z.time.first lambda.z.time.last
#> 1           FALSE    FALSE               FALSE              FALSE
#> 2           FALSE    FALSE               FALSE              FALSE
#>   lambda.z.n.points clast.pred span.ratio tobit_residual adj_tobit_residual
#> 1             FALSE      FALSE      FALSE          FALSE              FALSE
#> 2             FALSE      FALSE      FALSE          FALSE              FALSE
#>   lambda.z.n.points_blq thalf.eff.last thalf.eff.iv.last kel.last kel.iv.last
#> 1                 FALSE          FALSE             FALSE    FALSE       FALSE
#> 2                 FALSE          FALSE             FALSE    FALSE       FALSE
#>   kel.all kel.int.all kel.int.last cl.iv.all cl.iv.last cl.ivint.all
#> 1   FALSE       FALSE        FALSE     FALSE      FALSE        FALSE
#> 2   FALSE       FALSE        FALSE     FALSE      FALSE        FALSE
#>   cl.ivint.last cl.sparse.last f.last f.int.last f.int.all mrt.sparse.last
#> 1         FALSE          FALSE  FALSE      FALSE     FALSE           FALSE
#> 2         FALSE          FALSE  FALSE      FALSE     FALSE           FALSE
#>   mrt.iv.all mrt.ivint.all mrt.ivint.last vz.all vz.int.all vz.int.last
#> 1      FALSE         FALSE          FALSE  FALSE      FALSE       FALSE
#> 2      FALSE         FALSE          FALSE  FALSE      FALSE       FALSE
#>   vz.iv.all vz.iv.last vz.ivint.all vz.ivint.last vz.last vss.iv.all
#> 1     FALSE      FALSE        FALSE         FALSE   FALSE      FALSE
#> 2     FALSE      FALSE        FALSE         FALSE   FALSE      FALSE
#>   vss.ivint.all vss.ivint.last vss.sparse.last aucinf.obs aucinf.pred
#> 1         FALSE          FALSE           FALSE      FALSE       FALSE
#> 2         FALSE          FALSE           FALSE      FALSE       FALSE
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
#>   cl.int.inf.obs cl.int.inf.pred cl.iv.obs cl.iv.pred f.obs f.pred f.int.obs
#> 1          FALSE           FALSE     FALSE      FALSE FALSE  FALSE     FALSE
#> 2          FALSE           FALSE     FALSE      FALSE FALSE  FALSE     FALSE
#>   f.int.pred mrt.obs mrt.pred mrt.int.inf.obs mrt.int.inf.pred mrt.iv.obs
#> 1      FALSE   FALSE    FALSE           FALSE            FALSE      FALSE
#> 2      FALSE   FALSE    FALSE           FALSE            FALSE      FALSE
#>   mrt.iv.pred mrt.md.obs mrt.md.pred mrt.ivmd.obs mrt.ivmd.pred vz.obs vz.pred
#> 1       FALSE      FALSE       FALSE        FALSE         FALSE  FALSE   FALSE
#> 2       FALSE      FALSE       FALSE        FALSE         FALSE  FALSE   FALSE
#>   vz.int.inf.obs vz.int.inf.pred vz.iv.obs vz.iv.pred vz.sparse.last vss.obs
#> 1          FALSE           FALSE     FALSE      FALSE          FALSE   FALSE
#> 2          FALSE           FALSE     FALSE      FALSE          FALSE   FALSE
#>   vss.pred vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred vss.ivmd.obs
#> 1    FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#> 2    FALSE      FALSE       FALSE      FALSE       FALSE        FALSE
#>   vss.ivmd.pred vss.int.inf.obs vss.int.inf.pred cav.int.inf.obs
#> 1         FALSE           FALSE            FALSE           FALSE
#> 2         FALSE           FALSE            FALSE           FALSE
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
#>   clr.last.dn clr.obs.dn clr.pred.dn PCSPEC interval_id clr.last_ref
#> 1       FALSE      FALSE       FALSE plasma        ref1         <NA>
#> 2       FALSE      FALSE       FALSE  urine        <NA>         ref1
```
