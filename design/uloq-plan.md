# Concentrations above the upper limit of quantification

Against main be353efa, revised with Bill's answers of 2026-11-15 and 16
(including his four decisions of 2026-11-16, now in the text); no code before
he has read this.  His rule:  "Cmax should be noted as greater
than uloq not a value.  Tmax should use the above value as the maximum
concentration.  AUC is likely incalculable."

## 1. The argument and the marker

- **`PKNCAconc(uloq = )`** takes a number or a column name, mirroring `lloq`:
  positive and finite, `NA` allowed, anything else
  `pknca_error_conc_invalid_uloq`; `uloq > lloq` where a row has both
  (`pknca_error_conc_uloq_below_lloq`).  It is stored with
  `setAttributeColumn(attr_name = "uloq")`, where results and nca.reporter
  read it, and goes wherever `lloq` goes per observation (imputation's
  `impute_obs_values()`, the sparse median per time, the unbound scaling by
  `fu`).
- **The marker is `conc = Inf`** ("so that it is hard to miss"):  the data
  layer sets the concentration of an above-limit record to `Inf` and its limit
  in `uloq`.  A value equal to its limit is an ordinary measurement.
- **A finite value above its `uloq`** (1200 with a limit of 1000) is kept and
  used as measured, with `pknca_warning_conc_above_uloq` naming the rows.
- **An `Inf` on a row with no `uloq`** is the error
  `pknca_error_conc_inf_without_uloq`, naming the rows:  without a limit,
  nothing can be censored.
- **Today**, `PKNCAconc()` refuses any `Inf` ("Assertion on 'conc' failed:
  Must be finite", with no class), so no data or result contains one now.
  `+Inf` with a `uloq` becomes valid; `-Inf` stays an error.

## 2. Results carry `Inf` and `PPULOQ`

- A result taken from an above-limit sample is `Inf` in PPORRES (and PPSTRES:
  unit conversion multiplies `Inf` by its factor and keeps it).
- **`PPULOQ`** is a new results column, not part of SDTM, named after the
  `--ULOQ` convention.  It is filled on every concentration result of a
  profile that has a `uloq`, whether the value is `Inf` or not, and is `NA`
  on every other result and on every result of a profile without a `uloq`.
  The concentration results are those with a concentration unit in the
  registry, each in its own unit:
  - in the concentration unit:  `cmax`, `cmin`, `ctrough`, `cstart`,
    `clast.obs`, `clast.pred`, `ceoi`, `c0`, and the average concentrations
    (`cav`, `cav.last`, `cav.all`, and the `int`, `iv`, and `ivint` forms);
  - dose-normalized:  `cmax.dn`, `cmin.dn`, `ctrough.dn`, `clast.obs.dn`,
    `clast.pred.dn`, `cav.dn`, `cav.last.dn`, with `PPULOQ` divided by the
    dose as the value is.
  For a result taken from one sample (`cmax`, `cmin`, `ctrough`, `cstart`,
  `clast.obs`, `ceoi`, `c0`) the limit is that sample's; for the others (the
  average concentrations, `clast.pred`) it is the profile's when every sample
  has the same limit, and `NA` when the limits differ.  The Tobit summary
  censors each `Inf` at its `PPULOQ`.
- **Wide format:** the cell is `Inf`, with no `PPULOQ`.  **`summary()`:**
  in the first PR, `NC` with a footnote ("n of N above the upper limit of
  quantification") for a parameter with an `Inf` among its values; in the
  second, the geometric mean and CV from a lognormal Tobit fit right-censored
  at `PPULOQ`.

## 3. Every parameter is `Inf` or `NA` with a reason, never `NaN`

- **`Inf`** (a concentration at or above the limit, or a function increasing
  in one):  `cmax`; `cmin`, `ctrough`, `cstart`, `clast.obs`, `ceoi`, and `c0`
  (its `c0` method) when they pick an above-limit sample; their `.dn` forms;
  `ptr` and `swing` with a finite denominator; the excretion rates `ermax` and
  `erlst` from an above-limit collection; `ratio.*` of an `Inf` over a finite
  reference.  **Tmax** is the time of the above-limit sample (several:
  `first.tmax` decides); `tlast`, `tfirst`, and `tlag` count it as measured.
- **`NA` with the reason** "Concentration above the upper limit of
  quantification at <time>":  every AUC and AUMC (`last`, `all`, `inf`, `int`,
  `iv`, `pbext`, `pext`, `aucabove.*`) whose range contains the sample or
  interpolates or extrapolates through it; `ae` and what depends on it;
  `time.above`; and what depends on any of them (`cav*`, `deg.fluc`, `cl*`,
  `kel*`, `mrt*`, `thalf.eff*`, `vss*`, `vz*`, `f*`, `clr*`, `fe`, `erint`),
  through the existing reason propagation (`combine_exclude_reasons()`).
  `ptr`, `swing`, and ratios with an `Inf` denominator are `NA` with the same
  reason.  An AUC whose range ends before the first such sample is calculated.
- **The guard:**  `pk.nca.interval()` refuses a non-finite result other than
  `Inf` from a parameter registered as increasing in the concentration
  (`above_limit = "inf"` in `add.interval.col()`); every other parameter whose
  inputs contain an `Inf` gives `NA` with the reason.  One test iterates the
  registry on a profile with an above-limit sample and checks each parameter
  is either `Inf` (declared) or `NA` with the reason.

## 4. Half-life

An above-limit sample is left out of the fit before `lm()`, as
`exclude_half.life` leaves one out, and `get_halflife_points()` shows it with
the reason.  In the second PR the Tobit half-life right-censors it at its
`uloq` (the upper tail of `pnorm()` beside today's lower one).  An `Inf` never
reaches `lm()` or the likelihood as a number.

## 5. Everything else that meets an `Inf`

- **Imputation:**  `start_cmin` takes Cmin of the finite concentrations and
  adds nothing when there is none; `start_predose` shifts an above-limit
  predose sample with its `uloq` (Bill:  shift it), so the start is `Inf` and the AUCs from it
  are `NA`; `start_conc0` replaces it with 0 by design; `start_predose_conc0`
  keeps a measured `Inf` start.
- **Sparse:**  a time with an above-limit sample has an `Inf` mean; sparse
  AUCs across it are `NA` with the reason, and the sparse Cmax is `Inf`.
- **Interpolation and extrapolation:**  a concentration interpolated between
  an `Inf` and a finite value, or extrapolated from an `Inf`, is `NA` with the
  reason, never `Inf` or `NaN` by arithmetic.
- **BLQ rules (`conc.blq`):**  an `Inf` is measurable.
- **Steady state (`pk.tss*`):**  an `Inf` trough is left out, with the reason.
- **Superposition:**  `superposition()` refuses a profile with an `Inf`
  with the typed error `pknca_error_superposition_above_limit` (Bill:
  refuse); it predicts concentrations and has no limit to give them.
- **Units:**  `Inf` converts to `Inf`; `PPULOQ` converts with the same factor.

## 6. Backward compatibility

`Inf` is refused today, so existing data cannot contain one.  With no `uloq`
and no `Inf`, every result is identical to main and `PPULOQ` is all `NA`, which
a test pins for every registered parameter on the package's test data.
Nothing existing is renamed or removed.

## 7. Decided (Bill, 2026-11-16)

1. An `Inf` on a row with no `uloq`:  a typed error.
2. `PPULOQ`:  on every concentration result of a profile with a `uloq`.
3. `start_predose` with an above-limit predose sample:  it is shifted, with
   its limit.
4. `superposition()` with an `Inf`:  a typed error.

**Release:**  two PRs in 0.13.0.  (a) Sections 1 to 6 with `NC` in
`summary()` and the half-life exclusion.  (b) The Tobit right-censoring for
`summary()` and the half-life.
