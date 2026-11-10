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
  ref_vary = NULL,
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
  column. A `ref_id` that differs from the identifier the reference rows
  already have renames that interval, which is an error when another
  interval points at the old identifier or already has `ref_id`.
  Reference rows that already carry more than one `interval_id` are an
  error (`pknca_error_secondary_ref_ambiguous_spec`) when `ref_id` is
  given, as it cannot name more than one interval.

- ref_vary:

  The group columns in which the reference may differ from the interval
  calculating `param`, such as `"period"` in a crossover (see "Group
  columns that may differ"). They are written into the
  `<param>_ref_vary` column of the linked intervals, so the names may
  not contain spaces or commas (per-link declarations need group column
  names without spaces or commas; give such a column to
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  instead). The default of `NULL` writes nothing, so the `ref_vary`
  given to
  [`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
  applies, and `character(0)` declares that no column may differ
  (overriding that default).

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

## Group columns that may differ

A reference is matched on the requesting group's own values in every
group column except the ones the reference interval names: with groups
`treatment+subject` and `reference = data.frame(treatment = "iv")`, each
subject's oral profile uses that subject's IV profile. When the
concentration data are also grouped by a column that the reference
treatment does not share, such as the period of a crossover, the IV
profile is in a different period than the oral one and is not found
(`pknca_error_secondary_ref_value_missing`).

`ref_vary` names such columns. The reference is then matched on every
other group column and on the reference interval's own columns, and
takes whichever value of the varying columns has the reference
interval's results. Exactly one may: more than one (a replicate design
giving the reference twice) is an error
(`pknca_error_secondary_ref_vary_ambiguous`) naming the requesting group
and the candidates. A candidate counts when the reference interval has a
result row for it, even an `NA` one, so a replicate design with one
administration that could not be fitted is still ambiguous rather than
silently using the other. It is resolved by adding a group column that
tells them apart to the intervals and naming it in `reference`. A
varying column that the reference interval names is pinned by it. The
subject column cannot vary, as a reference is always the subject's own
profile.

The declaration is stored per link as column names separated by commas
in the `<param>_ref_vary` column of the intervals, so it can also be
written by hand. `NA` there takes the `ref_vary` of
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)
(which declares the varying columns once for every link of the data),
and `""` declares that no column varies. The result names the
reference's group in its `<group column>_ref` columns and in `PPANMETH`
(`"Reference interval: treatment=iv, period=1, 0-Inf"`).

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
[`pknca_cdisc_codes()`](https://humanpred.github.io/pknca/reference/pknca_cdisc_codes.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_match_route()`](https://humanpred.github.io/pknca/reference/pknca_match_route.md),
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
#>   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
#> 1     0  24    TRUE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#> 2     0  24   FALSE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#>   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
#> 1       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
#> 2       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbextint.last
#> 1        FALSE       FALSE         FALSE        FALSE              FALSE
#> 2        FALSE       FALSE         FALSE        FALSE              FALSE
#>   aucivpbextint.all aumcivint.last aumcivint.all    c0  cmax  cmin  tmax  tmin
#> 1             FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
#> 2             FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
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
#> 2               FALSE   FALSE FALSE  TRUE     TRUE   FALSE    FALSE FALSE
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
#> 2         FALSE         FALSE     FALSE        FALSE        FALSE     FALSE
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
#> 2       FALSE      FALSE      FALSE         FALSE         FALSE       FALSE
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
#>   clr.obs.dn clr.pred.dn PCSPEC interval_id clr.last_ref
#> 1      FALSE       FALSE plasma        ref1         <NA>
#> 2      FALSE       FALSE  urine        <NA>         ref1

# A crossover where each subject received the IV reference in a different
# period than the oral treatment
intervals_crossover <-
  data.frame(treatment = c("iv", "oral"), start = 0, end = Inf, aucinf.obs = TRUE)
interval_add_secondary(
  intervals_crossover,
  param = "f.obs",
  reference = data.frame(treatment = "iv"),
  ref_vary = "period"
)
#>   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
#> 1     0 Inf   FALSE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#> 2     0 Inf   FALSE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
#>   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
#> 1       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
#> 2       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
#>   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbextint.last
#> 1        FALSE       FALSE         FALSE        FALSE              FALSE
#> 2        FALSE       FALSE         FALSE        FALSE              FALSE
#>   aucivpbextint.all aumcivint.last aumcivint.all    c0  cmax  cmin  tmax  tmin
#> 1             FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
#> 2             FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
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
#> 1               FALSE    TRUE FALSE FALSE    FALSE   FALSE    FALSE FALSE
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
#> 2         FALSE         FALSE     FALSE        FALSE        FALSE     FALSE
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
#> 1       FALSE      FALSE       TRUE         FALSE         FALSE       FALSE
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
#> 2      FALSE  TRUE  FALSE     FALSE      FALSE   FALSE    FALSE           FALSE
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
#>   clr.obs.dn clr.pred.dn treatment interval_id f.obs_ref f.obs_ref_vary
#> 1      FALSE       FALSE        iv        ref1      <NA>           <NA>
#> 2      FALSE       FALSE      oral        <NA>      ref1         period
```
