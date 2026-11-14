# Concentrations above the upper limit of quantification

Against main be353efa; for Bill's decision before any code.  His rule:
"Cmax should be noted as greater than uloq not a value.  Tmax should use the
above value as the maximum concentration.  AUC is likely incalculable."  In
summaries an above-limit value is censored at the limit (Tobit).  PKNCA has
no upper limit today; `lloq` is used only by the Tobit half-life.

## 1. The argument and the marker

- `PKNCAconc(uloq = )` takes a number or a column name, mirroring `lloq`:
  positive and finite, `NA` allowed, anything else
  `pknca_error_conc_invalid_uloq`; `uloq > lloq` where a row has both
  (`pknca_error_conc_uloq_below_lloq`).  Stored with
  `setAttributeColumn(attr_name = "uloq")`, where results and nca.reporter
  read it as they read `lloq`.  It goes wherever `lloq` goes per observation
  (imputation's `impute_obs_values()`, the sparse median per time, the
  unbound scaling by `fu`).
- **Marker:** a record is above the limit when `conc >= uloq`, the mirror of
  BLQ as zero, with the data layer delivering it at its limit.  A value
  strictly above its `uloq` is outside the validated range and is treated the
  same way, with `pknca_warning_conc_above_uloq` naming the rows, so it can
  never become a Cmax.
- **Equality is safe only with the qualifier "≥":** a value measured exactly
  at L is "≥ L" too, while "> L" would be false for it.  Its cost is that such
  a value loses its AUC.  A flag column would avoid that and is not proposed,
  because the mirror works.  With no `uloq`, or all `NA`, nothing is marked.

## 2. Cmax, Tmax, and a qualifier on results

- **A results column `qualifier`:** `NA`, or `">="` for a lower bound.  It is
  lowercase like `exclude` and `pknca_parameter`, so it is not taken for an
  SDTM variable; that is the only reason to reject the data layer's
  `PPBOUND`.  PPORRES keeps the number L, so numeric readers keep working.
- **Cmax** is the largest of the measured values and the limits, qualified
  when any above-limit sample is in the interval.  With per-row limits, a
  measured 1500 beside a sample above a limit of 1000 gives "≥ 1500".
- **Tmax** is the time of that maximum.  An above-limit sample at L ranks
  above a measured L, and above-limit samples tie with each other under
  `first.tmax`.  When another above-limit sample's L is below Cmax (per-row
  limits), Tmax is reported with the exclude reason "Tmax may be at <time>
  (above the upper limit)".
- **Propagation:** a monotone increasing function of a qualified value is
  qualified (cmax.dn, ptr, swing, cmax ratios with an unqualified reference);
  anything else is not calculated (section 3).  The same holds for cmin,
  ctrough, cstart, clast.obs, ceoi, and the `c0` method of `pk.calc.c0()`
  when they pick an above-limit sample.
- **Outputs:** long and `out_format = "cdisc"` carry `qualifier`, and CDISC
  also gains `PPSTRESC = ">=1000"`.  `wide` keeps the number and warns
  (`pknca_warning_wide_qualifier_dropped`).  `summary()` gives the geometric
  mean and CV from a lognormal estimate censored at the limits (Tobit) when
  any value is qualified, with a footnote giving n censored; the other
  statistics are NC, except the median and range when they can be ordered.

## 3. Not calculated, with a reason

- An AUC, AUMC, or amount excreted (the `int` and `iv` forms included) is
  `NA` when its range contains an above-limit sample or interpolates or
  extrapolates through one, with the reason "Concentration above the upper
  limit of quantification at <time>".  One whose range ends before the first
  such sample is calculated (`aucint` 0 to 1 with the sample at 2 and one
  measured at 1).
- Dependants need no new code:  `pk.nca.interval()` already carries each
  input's reason into its dependants (`combine_exclude_reasons()`).  A test
  iterates `get.parameter.deps()` for every AUC and AUMC and checks each
  dependant is `NA` with the reason.
- **Grouping by reason (nca.reporter):** reasons today are free text joined
  with "; ".  Proposed:  a results column `exclude_code` with the codes, here
  `"conc_above_uloq"`, each with a template listed by `pknca_exclude_codes()`;
  the existing reasons get codes in a later PR.

## 4. Half-life

An above-limit sample is left out of the fit, as `exclude_half.life` leaves
one out, and `get_halflife_points()` shows it with the reason "above the upper
limit".  The Tobit half-life gains right censoring at `uloq` (the upper tail
of `pnorm()` beside today's lower tail in `fit_half_life_tobit_LL()`); only
there do such points count toward `min.hl.points`.

## 5. What follows elsewhere

- **Sparse:** a time with any above-limit sample has no mean, so sparse AUCs
  across it are not calculated; the sparse Cmax there is "≥" the mean with
  those samples at their limits.
- **Imputation:** the marker moves with its observation (`start_predose`
  shifting an above-limit sample carries its `uloq`; `start_cmin` copying a
  qualified Cmin is qualified); `start_conc0` replaces it with 0 as it
  replaces any value.
- **BLQ rules (`conc.blq`):** unaffected; an above-limit sample is measurable
  when they look for the first and last measured value.
- **Steady state (`pk.tss*`):** above-limit samples are left out with a
  reason; no censored model.
- **Secondary parameters (§3.16):** a qualified value over an unqualified one
  is "≥"; any other combination is not calculated.

## 6. Backward compatibility

With no `uloq`, every result is identical to main (values, `exclude`,
PPANMETH), with `qualifier` and `exclude_code` all `NA`.  A test pins it by
running every registered parameter on the package's datasets with and without
an all-`NA` `uloq`.  Nothing existing is renamed or removed.

## 7. For Bill to decide (recommendation first)

1. Marker `conc >= uloq` with "≥" (recommended), or ">" with a flag column to
   tell a measured value at L apart.
2. Column `qualifier` in long and CDISC output (recommended), or `PPBOUND`.
3. A value strictly above `uloq`: above the limit with a warning
   (recommended), or a typed error.
4. `summary()`: Tobit geometric mean and CV (recommended), or NC with a
   footnote until the Tobit summary is written.
5. Reason codes: an `exclude_code` column starting with this one
   (recommended), or text only.

**Release:** two PRs in 0.13.0.  (a) Sections 1, 2 without the Tobit
summary, 3, 4 without Tobit, and 6, with sparse data and steady state as
exclusions with reasons.  (b) Tobit right censoring for the half-life and for
`summary()`.
