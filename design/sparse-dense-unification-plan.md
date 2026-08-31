# Unifying sparse and dense NCA parameters: feasibility and plan

Status: feasibility analysis, no implementation. Written against the code as of
2026-08-31 (post PR 629).

## The proposal

For most NCA parameters, the sparse-sampling method is the dense method applied
to a summary (mean) concentration-time profile. The proposal: give each
registered parameter an optional sparse-specific calculation function (a
`FUN_sparse` alongside `FUN` in `add.interval.col()`). When the data are sparse
and `FUN_sparse` exists, use it; when it does not exist, fall back to the dense
`FUN`. The visible consequence is one parameter name (`auclast`) instead of a
parallel sparse vocabulary (`sparse_auclast`).

## Key finding: half of the proposal is already implemented

The fallback half of the proposal exists today, implemented at the **data**
level rather than the **dispatch** level:

- `prepare_PKNCAconc_sparse()` (R/prepare_data.R) builds *two* representations
  of sparse data per group: `data_sparse_conc` (pooled individual samples) and
  `data_conc`, the arithmetic-mean profile via `as_sparse_pk()` →
  `sparse_mean()` → `sparse_to_dense_pk()`.
- `pk.nca()` then runs two passes: a dense pass over the mean profile and a
  sparse pass over the pooled data. Each registered parameter carries a
  `sparse` flag, and `pk.nca.interval()` computes it only in the matching pass
  (`all_intervals[[n]]$sparse == sparse`).
- So requesting `cmax` or `aucinf.obs` on sparse data *already* computes the
  dense function on the mean profile — exactly the proposed fallback. The
  sparse vignette documents this: "Any of the non-sparse parameters will be
  calculated based on the mean profile of the animals in a group."

What the proposal would actually change is therefore only the **dispatch**
half: requesting `auclast` on sparse data would run the Bailer/Nedelman-Jia
estimator (point estimate + SE + df) instead of a bare trapezoid on the mean
profile, and the parallel `sparse_*` / `*.sparse.*` names would collapse into
the standard ones.

## What would collapse

Eleven registrations become redundant under unification:

- `sparse_auclast`, `sparse_auc_se`, `sparse_auc_df`
- `sparse_aumclast`, `sparse_aumc_se`, `sparse_aumc_df`
- `cl.sparse.last`, `mrt.sparse.last`, `kel.sparse.last`, `vss.sparse.last`,
  `vz.sparse.last`

The five derived parameters collapse for free: `cl.last` is `dose/auclast` via
`formalsmap`, and the interval engine resolves parameter arguments from
`computed_value` by name. If the sparse estimator stores its result under
`auclast`, every downstream dense registration (`cl.last`, `mrt.last`,
`vss.iv.*`, dose-normalized variants, secondary parameters) picks up the
sparse-derived value with no new code. That is the strongest argument for the
proposal: today the sparse derived-parameter set must be maintained pairwise by
hand and covers only five parameters; unification makes the entire derived
graph available to sparse data automatically.

## Conceptual issues, in decreasing order of severity

### 1. The fallback and the sparse estimator disagree under the default AUC method

The sparse estimator is linear-trapezoidal only (`pk.calc.sparse_auc` errors
for any other `method`; the SE theory is defined for linear weights). The dense
fallback respects `PKNCA.options("auc.method")`, whose default is
`"lin up/log down"`. Consequences:

- Today, `auclast` (dense-on-mean) and `sparse_auclast` on the same sparse data
  give *different point estimates* by default. The two names make that
  coexistence legible.
- Under unification, requesting `auclast` on sparse data changes behavior: the
  value switches from lin-up/log-down-on-mean to linear-on-mean, and SE/df rows
  appear. Same name, different number — the headline breaking change, and it
  must not be silent.
- The point estimate and its SE must come from the same estimator; computing
  the point with `lin up/log down` and the SE with linear weights would be
  statistically incoherent. So the policy must be: **on sparse data, a
  parameter with a sparse estimator uses that estimator wholesale**, and
  `auc.method` does not apply to it (already the documented behavior for
  `sparse_auclast`). Emit a message when the option differs so the user is not
  surprised.

### 2. Multi-value results and their companion registrations

Sparse estimators return estimate + SE + df. The engine already supports this
(a calculation function may return a data.frame; each column becomes a result
row; companions are registered with `FUN=NA` and `depends=`). Under unification
the companions need dense-namespace names — `auclast_se`, `auclast_df`, etc. —
which incidentally fixes the current naming inconsistency (`sparse_auc_se` is
the SE of `sparse_auclast`, not of a `sparse_auc`).

New failure mode to guard: requesting `auclast_se=TRUE` on **dense** data. With
`FUN=NA` and no sparse pass, it would silently produce nothing. Per the
fail-loud rule this must be an error at interval-check time ("`auclast_se`
requires sparse data"), which requires the interval check to know
`is_sparse_pk(data)` — it runs inside `pk.nca()`/`PKNCAdata()`, so that is
available.

### 3. The two-pass engine becomes one pass with two data representations

Today each pass sees one concentration representation (mean profile *or* pooled
data). Under per-parameter dispatch, a single interval needs both in scope:
`cmax` wants the mean profile, `auclast` wants pooled `conc/time/subject`. The
plumbing change is contained: `pk.nca()` drops the second `pmap` loop,
`pk.nca.interval()`'s `source_map` gains pooled entries (e.g. `conc.sparse`,
`time.sparse`, `subject`), and the per-parameter branch becomes "sparse data
and `FUN_sparse` exists → call it with the sparse formals map; otherwise call
`FUN` with the dense map". `any_sparse_dense_in_interval()` and the `sparse`
argument threading disappear.

A sparse estimator has a different calling convention than its dense
counterpart (it needs `subject`), so the registry needs `formalsmap_sparse`
alongside `FUN_sparse`. That doubles the registration surface for the few
parameters that carry both — acceptable for ~4–6 parameters, and `add.interval.col()`
already validates formals maps against the named function.

### 4. The statistics pin the profile summary to the arithmetic mean

The proposal mentions mean, median, or geometric mean of the original
measurements. Important asymmetry:

- The **fallback** path (dense function on a summary profile) is a pure point
  estimate; any summary function is *mechanically* possible there.
- The **sparse estimators** are not summary-agnostic: Bailer/Nedelman-Jia
  variance and Holder covariance are derived for the arithmetic mean with the
  specific >50%-BLQ-to-zero rule. A geometric-mean or median profile has no SE
  under this theory, and a geometric mean is undefined once BLQ values are
  carried as zero.

So if the profile-summary function ever becomes configurable, it can apply only
to the fallback path, the sparse estimators must refuse (not silently accept) a
non-arithmetic summary, and the result needs a method annotation because
"auclast on sparse data" would no longer name a single estimator. Recommend
deferring configurability entirely; it is orthogonal to unification and adds
its own ambiguity.

### 5. Backward compatibility and migration

The `sparse_*` names are exported API: in the vignette, in
`pknca_interval_table()`'s `sparse_single_dose` preset and `sparse`
classification, in CDISC mappings (`SPARSEAL` etc.), in users' saved interval
specifications, and in downstream packages. A cut-over is a multi-release
lifecycle deprecation:

- Old names stay registered and functional, warning once per session with the
  new-name equivalent (`check.interval.specification()` can translate old
  interval-spec columns with a warning, since interval specs are plain
  data.frames).
- `PKNCA.set.summary()` entries, `pknca_interval_table()` presets, the
  parameter classification (`classify_sparse()` currently derives sparseness
  from the flag + dependency closure; it would derive "has a sparse estimator"
  from `FUN_sparse` presence), and the vignette all move in the same release.
- CDISC codes become context-dependent (dense `AUCLST` vs sparse `SPARSEAL`
  under one parameter). The registry already supports route-keyed
  `pptestcd_cdisc` mappings (`list(route = list(...))`); a sparse-keyed variant
  is the same pattern.

### 6. Derived-parameter semantics change, mostly for the better

- `vz.sparse.last` is today `cl.sparse.last / kel.sparse.last` with
  `kel = 1/MRT`, which makes Vz numerically equal to Vss — the vignette itself
  flags this as an artifact. Under unification, `vz.last` on sparse data would
  use `lambda.z` fit on the mean profile (the standard toxicokinetic approach,
  and what Phoenix does). Better, but the numbers change relative to the
  current sparse outputs; validation comparisons must be re-run and the change
  called out.
- SE does **not** propagate through derived parameters: `cl.last` from a sparse
  `auclast` gets a point estimate but no SE (a delta-method SE is possible but
  out of scope). This is not a regression — `cl.sparse.last` has no SE today —
  but unified naming makes the absence easier to miss, so it needs explicit
  documentation.

### 7. Result grain and traceability

Dense results are one row per subject; sparse results are one row per group.
Under one name, the grain of `auclast` depends on the analysis. Within a single
`PKNCAresults` it is consistent (a `PKNCAconc` is entirely sparse or dense),
and this is already true today; but the method must remain visible in the
output. The `PPANMETH` mechanism already carries it (`pk.calc.sparse_auc` sets
a method attribute, e.g. "Sparse: arithmetic mean, <=50% BLQ"), so the
requirement is just that every `FUN_sparse` sets it.

### 8. Summary layer

Minor. `sparse_auclast` and `auclast` already share the same summary functions
(geometric mean / geoCV), and `summary.PKNCAresults` already special-cases the
absent subject column for N counting. Cross-group summaries ignore the
per-group SEs (no inverse-variance weighting) — a pre-existing limitation,
unchanged by unification.

## Which parameters genuinely get a sparse estimator

The premise that only a limited number need one holds:

| Parameter | Sparse estimator | Notes |
|---|---|---|
| `auclast` (and `aucall`, `aucint.*` restricted to observed times) | Bailer point + Nedelman-Jia/Holder SE + Satterthwaite df | Exists today |
| `aumclast` | Same theory on the moment curve | Exists today |
| `cmax` | Max of mean profile + SE of the mean at that time point | New; matches Phoenix sparse output |
| `aucinf.*` | None — no SE theory for the extrapolated portion | Falls back (mean-profile extrapolation), consistent with Phoenix |
| everything else | None | Falls back to dense-on-mean |

## Alternatives considered

- **A. Full unification (`FUN_sparse` + name collapse)** — as analyzed above.
  Delivers the real benefits: one vocabulary, the whole derived-parameter graph
  available to sparse data, comparable output columns across sparse and dense
  studies.
- **B. Request translation only** — keep the current engine and registrations;
  when data are sparse, `check.interval.specification()` maps `auclast=TRUE` to
  `sparse_auclast=TRUE` with a message. Cheap (no engine change), removes the
  "you must know the sparse names" burden, but output names still differ, the
  derived-parameter graph stays five parameters wide, and it adds a hidden
  indirection. Reasonable as a transitional UX shim, not as the end state.
- **C. Status quo + gap filling** — keep parallel names; add `sparse_cmax`
  (+SE), sparse AUCtau, etc. as demanded. No breakage, but the registry grows
  pairwise forever and every future derived parameter needs a sparse twin by
  hand. This is the trajectory the package is already on, and issue 6 above
  (`vz == vss`) shows the kind of wart it produces.

## Verdict and recommended sequence

Conceptually sound; no fundamental blocker. The engine's mechanisms
(data.frame-returning calculation functions, `formalsmap`, `computed_value`
dependency resolution, `PPANMETH`, route-keyed CDISC maps) each already have
the shape the unification needs. The dominant costs are the migration of
exported names (issue 5) and honest handling of the one real behavior change
(issue 1: same name, linear-only estimator with SE, where the fallback used to
honor `auc.method`). The proposal's fallback rule needs one refinement: the
fallback is not "run the dense function on the raw sparse data" but "run it on
the arithmetic-mean profile", which the data-preparation layer already
provides.

Suggested phases (each a separate release-sized unit):

1. **Groundwork (no user-visible change):** merge the two passes into one with
   both data representations in scope, keeping the current flag-based routing.
   Fix incidentally-found validation gap (below).
2. **Additive:** `FUN_sparse`/`formalsmap_sparse` in `add.interval.col()`;
   register sparse estimators for `auclast`/`aumclast` under the unified names
   with `_se`/`_df` companions; dense-data guard for companion requests; method
   messaging for the `auc.method` interaction; NEWS prominently.
3. **Deprecate:** lifecycle-deprecate the eleven `sparse_*`/`*.sparse.*`
   registrations with interval-spec translation; move vignette, presets,
   classification, and CDISC mappings; re-run cross-validation comparisons
   (point estimates for AUC/AUMC are unchanged; Vz/Kel change by design).
4. **Optional additions:** sparse `cmax` SE; sparse AUCtau for multiple-dose
   toxicokinetics.

Decision points settled before phase 2: the companion-name convention is the
underscore suffix (`auclast_se`, `auclast_df`), matching the `sparse_auc_se`
precedent rather than `auclast.se`. Still open for phase 3: whether the old
names ever hard-error, and whether `vz.last`/`kel`-family on sparse data should
use the mean-profile `lambda.z` (recommended) or preserve the current 1/MRT
chain under a named-only parameter.

## Incidental finding (out of scope, fix independently)

`as_sparse_pk()` (R/sparse.R) calls `checkmate::check_vector(subject, ...)` and
discards the result; `check_*` functions return a string rather than throwing,
so the subject validation is a no-op and a wrong-length or missing-value
`subject` passes silently into the covariance bookkeeping.

## Appendix: why the sparse estimators are linear-only

What exactly is missing for a `lin up/log down` sparse method, and would
weighting each segment's rule by the fraction of animals going up vs. down
suffice?

**The estimand is not the problem.** By Fubini, the population-mean AUC over
the sampled range is `∫ E[C(t)] dt = E[∫ C(t) dt]` — integrating the mean
curve targets the same quantity as averaging individual AUCs. The integration
rule (linear vs. log-down) is a *discretization* choice for approximating that
integral from the sampled times, so choosing the rule from the mean curve's own
direction is coherent. Cross-animal direction heterogeneity biases neither
approach toward a different estimand; it only shifts discretization bias.

**The variance and df theory is the problem.** The whole
Bailer/Nedelman-Jia/Holder edifice rests on the estimator being a *linear
combination of the per-time-point means with fixed weights*,
`AUC = Σ wᵢ x̄ᵢ`, where `wᵢ` depends only on the time grid:

- `Var(Σ wᵢ x̄ᵢ) = w'Σw` is exact given the covariance of the means; the only
  approximations are in estimating `Σ` (Holder) and the df.
- The Satterthwaite df formula matches a fixed-weight combination of
  independent sample variances.

The log-trapezoid segment, `(Cᵢ − Cᵢ₊₁)Δt / ln(Cᵢ/Cᵢ₊₁)`, is nonlinear in the
concentrations, so the "weights" become functions of the estimated means.
Three consequences:

1. **Variance becomes a delta-method approximation.** One can differentiate
   the piecewise functional and use the gradient as effective weights
   (`∂g/∂a = Δt[L − (a−b)/a]/L²` with `L = ln(a/b)`, etc.), keeping the Holder
   covariance. But it is first-order only, the plug-in gradients are random
   and correlated with the means, and with the r ≈ 3 animals/time point and
   30–100% CVs typical of sparse designs the neglected terms are not small.
   There is also a second-order Jensen bias in the point estimate,
   `E[f(x̄)] − f(μ) ≈ ½·tr(H·Σ)`, absent in the linear case.
2. **The gradient blows up in the tail.** As the lower concentration of a
   down-segment approaches zero, `∂g/∂Cᵢ₊₁ → ∞`: the delta-method SE is
   unstable exactly where log-down is supposed to help. Worse, the sparse
   >50%-BLQ rule sets tail means to exactly zero and zero endpoints force a
   fall-back to the linear rule, a genuinely non-smooth, data-dependent regime
   switch that no delta method covers — and it means the segments where
   log-down would matter most are largely forced linear anyway.
3. **The df derivation dissolves.** With weights that are random and
   correlated with the sample variances, the weighted-chi-square matching
   behind the Satterthwaite formula has no basis; a replacement would be
   heuristic and need simulation calibration.

One reassuring detail: at a flat segment the linear and log rules agree in
*both value and first derivative* (the estimator is C¹ across the up/down
switch), so noise-induced direction flips near ties contribute only
second-order error. The rule switching per se is not the obstacle; the
nonlinearity within the log regime is.

**Why fraction-weighting does not suffice.** Weighting each segment as
`p·log-trap(x̄ᵢ, x̄ᵢ₊₁) + (1−p)·lin-trap(x̄ᵢ, x̄ᵢ₊₁)` with `p` the fraction of
animals decreasing over the segment fails on four counts: (i) in serial
sacrifice — the canonical sparse design — no animal is sampled at two adjacent
time points, so `p` is unobservable; (ii) even in batch designs it corrects
only the regime *mixture*, not the within-regime Jensen gap — the average of
`g(aₖ, bₖ)` over animals differs from `g(ā, b̄)` by terms involving second
moments, which fractions cannot supply; (iii) it makes the variance harder,
adding a random mixing weight correlated with the concentrations; and (iv) per
the estimand argument above it is solving a non-problem — the quantity it
approximates differs from `∫E[C]dt` only in discretization bias.

**Conclusion.** A `lin up/log down` sparse method is a derivable *research*
extension (delta-method gradient weights + Holder covariance + a heuristic df,
validated by simulation for coverage), not a port of existing theory — nothing
in Bailer 1988, Yeh 1990, Nedelman et al. 1995/1998, or Holder 2001 covers it.
If ever pursued, it belongs behind its own validation study; the default stays
linear.
