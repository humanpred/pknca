# Design plan: comprehensive bioequivalence calculator in PKNCA

Starting point for extending the bioequivalence work on this branch
(`bioequivalence-functions`, PR
[#547](https://github.com/humanpred/pknca/pull/547)), which formalizes the
prototype in PR [#490](https://github.com/humanpred/pknca/pull/490).

**Work this in plan mode first.** Do the "Learn" and "Design" phases before
writing code, then present a plan for approval.

> Note: this branch is currently behind `origin/main` (≈9 commits at the time
> of writing). Consider `git merge origin/main` before starting implementation.

## Mission

Extend PKNCA's bioequivalence (BE) functions to cover the **full BE assessment
and regulatory-comparison space** of `replicateBE` and `PowerTOST`, so that
(a) downstream packages (notably `nlmixr2mbbe`, model-based bioequivalence) can
delegate all their BE math to PKNCA, and (b) PKNCA becomes a one-stop BE
*assessment* engine across regulators. Reuse `PowerTOST` for regulatory
constants/limits (never hardcode) and validate against `replicateBE`.

## What already exists on this branch — the ABE foundation (do not rebuild)

`R/bioequivalence.R`:

- `fitbe_models(object, endpoints = c("cmax","aucinf.obs","aucinf.pred","auclast"), reference_col, reference_value, fixed = NULL, random = NULL)`
  — fits `lmerTest::lmer(log(value) ~ fixed + random)` per endpoint; consumes a
  `PKNCAresults` (auto-extracts subject + grouping columns,
  `filter_excluded = TRUE`) or a long data.frame; reference set via
  `relevel(factor(...), ref = reference_value)`. Returns class `fitbe_models`
  (per-endpoint fits, fixed-effects table with Satterthwaite df, variance
  components, metadata).
- `fitbe_table(fit, alpha = 0.10)` — geometric mean ratio (test/ref %), 90% CI
  via `emmeans::contrast(..., "revpairwise", type = "response")`, Satterthwaite
  df, intra-subject `cv_intra_percent = sqrt(exp(resid_sd^2) - 1) * 100`.
- `fitbe_calculate(...)` — wrapper returning `list(table, fit)`.

Engines `lme4`, `lmerTest`, `emmeans` are guarded Suggests. **No
reference-scaling, no regulatory decision, single (non-treatment-specific)
residual variance.** That gap is the core deliverable.

## The gap to close (core deliverable)

A regulatory **decision + reference-scaling** layer on top of `fitbe_*`,
covering every framework below, plus the infrastructure they need.

### Regulatory frameworks to support

| Framework | Scaling | Switch | Cap / extra | Decision | PE constraint | Source |
|---|---|---|---|---|---|---|
| **ABE** (default) | none | — | — | 90% CI ⊂ [80, 125]% | — | universal |
| **EMA ABEL** | widen limits | CVwR > 30% | cap at CVwR 50% (limits 69.84–143.19%) | 90% CI ⊂ widened limits | 80–125% | `PowerTOST::scABEL("EMA")`; `replicateBE` Method A/B |
| **Health Canada** | widen limits | CVwR > 30% | upper cap ≈ 1/0.6667; mixed model | 90% CI ⊂ HC limits | 80–125% | `scABEL("HC")`; `replicateBE` (HC needs `method.B` `option`) |
| **GCC** | widen limits | CVwR > 30% | **fixed** widened 75.00–133.33% (not CV-dependent) | 90% CI ⊂ limits | 80–125% | `scABEL("GCC")`; `replicateBE` |
| **FDA RSABE** | linearized | swR ≥ 0.294 (CVwR ≈ 30%) | r_const = ln(1.25)/0.25 ≈ 0.8926 | Howe/Hyslop 95% upper bound of (d² − θ·s²wR) ≤ 0, θ = r_const² | 80–125% | `PowerTOST::reg_const("FDA")` |
| **FDA NTID** | linearized (tighter) | always (fully replicated) | σ_w0 = ln(1.11111)/0.1 | RSABE bound ≤ 0 **and** 90% CI ⊂ [80,125]% **and** upper 90% CI of swT/swR ≤ 2.5 | 80–125% | FDA warfarin guidance |
| **HVNTID** | scaled | high-var NTID | — | per FDA HVNTID | 80–125% | `PowerTOST::power.HVNTID` family |

Verify every constant/limit against the current `PowerTOST::reg_const` /
`scABEL` and the FDA/EMA/HC/GCC guidances during the Learn phase — do not trust
this table blindly.

### Key technical addition: treatment-specific within-subject variances

`fitbe_*` currently yields one residual SD. Reference-scaling needs **s²wR**
(and **s²wT** for NTID) separately, which requires a replicate design.
Implement both standard estimators and let the user pick (`method = "A"`/`"B"`):

- **Method A (ANOVA / difference-based, FDA-acceptable, matches
  `replicateBE::method.A`):** within each subject form `RR = R1 − R2`,
  `s²wR = var(RR)/2`; `TT = T1 − T2`, `s²wT = var(TT)/2` (handle partial
  replicate where only R is replicated).
- **Method B (mixed model, matches `replicateBE::method.B` / FDA progesterone
  guidance):** one mixed model with treatment-specific residual variances
  (`nlme::lme(..., weights = varIdent(~treatment))` or the lmer equivalent) →
  s²wR, s²wT directly.

### Proposed new functions (extend `R/bioequivalence.R`)

1. `be_design(data, subject, sequence, period, treatment)` — detect/classify
   design (2×2×2, full replicate TRTR/RTRT, partial replicate TRR/RTR/RRT,
   etc.); report replication of R and T; flag which frameworks are feasible.
   Use `replicateBE::info.design` as a reference, but reimplement cleanly.
2. `be_within_var(object_or_fit, method = c("A","B"))` — s²wR, s²wT, swR, swT,
   CVwR, CVwT with their degrees of freedom.
3. `be_regulator(name)` — pulls `CVswitch`, `CVcap`, `r_const`, `pe_constr`,
   scaling type from `PowerTOST::reg_const` + `scABEL`; single source of truth.
4. Per-framework deciders: `.be_abe()`, `.be_abel()` (EMA/HC/GCC via `scABEL`),
   `.be_rsabe()` (FDA Howe/Hyslop), `.be_ntid()` / `.be_hvntid()`.
5. **Top-level assessor** `be_assess(object, reference_col, reference_value, endpoints, regulator = "FDA", method = "B", alpha = 0.10, design = NULL)`
   → per-endpoint table: `endpoint, n, design, gmr_percent, ci_lower, ci_upper, cvwr_percent, cvwt_percent, swr, limit_lower, limit_upper / criterion, regulator, method, pass`.
   **This is the function `nlmixr2mbbe` will call.**
6. **Regulatory comparison** `be_compare(object, ..., regulators = c("FDA","EMA","HC","GCC"))`
   → the same data assessed under each framework side by side.
7. `print` / `format` / `summary` / `as.data.frame` methods mirroring
   `PKNCAresults` idioms.

## nlmixr2mbbe integration (the consuming side)

After this lands, `nlmixr2mbbe::mbbeBe()` becomes a thin wrapper: build a tidy
frame from each simulated study's NCA and call
`PKNCA::be_assess(..., regulator = control$regulator)`, mapping the returned
`pass` into the power calculation. **Delete** nlmixr2mbbe's hand-coded
RSABE/ABEL/NTID (`.mbbeScaledAssess`, `.mbbeNtidAssess`, `.mbbeRsabeBound`,
`.mbbeWithinVar`) in favor of PKNCA. nlmixr2mbbe's EMA path is already validated
against `replicateBE` (PE/CI identical), so a regression test can pin parity.
Reconcile the swR estimator: nlmixr2mbbe currently uses the residual variance of
`lm(log(value) ~ subject)` on reference rows, which disagreed with
`replicateBE` by ~1.4 CV points — align to the regulatory definition here.

## Other `replicateBE`/`PowerTOST` features — suggested follow-ups for PKNCA

Out of scope for nlmixr2mbbe's needs and for the first PR, but natural homes in
PKNCA. `PowerTOST` is overwhelmingly *planning* (power/sample size) and assesses
no data, so it is complementary to the assessment calculator. Recommend as
separate follow-up issues/PRs — a **BE planning** module:

- **Power & sample size:** `power.TOST`/`sampleN.TOST`,
  `power.scABEL`/`sampleN.scABEL` (+`.ad`), `power.RSABE`/`sampleN.RSABE`,
  `power.NTID`/`power.HVNTID` (+ `sampleN.*`), `power.2TOST` (two simultaneous
  endpoints), `power.noninf` (non-inferiority),
  `power.RatioF`/`CI.RatioF` (Fieller ratio-of-means, e.g. for Tmax).
- **Dose proportionality:** `power.dp`/`sampleN.dp` — a natural NCA companion.
- **Expected power / sample size under uncertainty:** `exppower.TOST`,
  `expsampleN.TOST`, `exppower.noninf`, `expsampleN.noninf`.
- **Sensitivity / power analysis:** `pa.ABE`, `pa.scABE`, `pa.NTID`.
- **Type-1-error control / alpha adjustment:** `scABEL.ad`,
  `sampleN.scABEL.ad`, `type1error.2TOST`.
- **Simulation-based reference-scaling:** `power.RSABE2L.sds`/`.sdsims`,
  `power.scABEL.sdsims`.
- **CV utilities (exported helpers):** `CVfromCI`, `CI2CV`, `CVpooled`,
  `CVp2CV`, `CV2se`/`se2CV`, `CV2mse`/`mse2CV`, `CVCL`, `CVwRfromU`, `U2CVwR`.
- **From `replicateBE`:** reference-outlier detection (its `fence`/boxplot
  logic), partial-replicate & incomplete/unbalanced-design handling, and the
  `rds01`–`rds30` reference datasets (use as validation fixtures).
- **Math primitives:** `OwensQ`, `OwensQOwen`, `OwensT` (only if a planning
  function needs exact power internally).

## Learn phase (before designing)

- `replicateBE` source: `method.A`, `method.B`, `ABE`, and internals `CV.calc`,
  `info.design`, `info.data`. **Known quirks (from prior investigation):**
  `method.A/B` support **only** EMA/HC/GCC (no FDA — `CV.calc` assigns
  `reg_set` only in those branches); they return a frame **only** with
  `details = TRUE`; the in-memory `data=` path is broken (needs a forged
  `rset` attribute) — use the file path:
  `method.B(path.in = dir, file = "study", ext = "csv", print = FALSE, details = TRUE, regulator = "EMA")`.
  Use these to extract the exact ABEL algorithm and swR estimation, and as the
  cross-check oracle.
- `PowerTOST`: `reg_const`, `scABEL`, `scABEL.ad`, `CI.BE`, and the
  RSABE/NTID/HVNTID power functions for the criteria/constants; read its `ABE`,
  `ABEL`, `RSABE`, and `NTID` vignettes.
- Regulatory guidances: FDA progesterone (RSABE) and warfarin (NTID) draft
  guidances, EMA BE guideline + Q&A (ABEL), Health Canada and GCC BE guidance.
- PKNCA idioms: `PKNCAresults` structure,
  `as.data.frame(..., filter_excluded = TRUE)`, grouping/units/exclusions/
  provenance, and the existing `fitbe_*` conventions on this branch.

## Testing & validation

- **Oracle tests:** for EMA/HC/GCC, assert `be_assess` / `.be_abel` matches
  `replicateBE::method.A` and `method.B` (file path, `details = TRUE`) on the
  `rds01`–`rds30` datasets — PE, 90% CI, CVwR, and decision (published/known
  answers).
- **FDA RSABE/NTID:** validate against the FDA guidance worked examples and
  `PowerTOST::CI.BE` / known constants; include FDA progesterone and warfarin
  example data.
- **Unit tests** for `be_design` (every design type), `be_within_var`
  (Method A vs B agree on balanced full replicate), each regulator's
  switch/cap boundaries, and PE-constraint failures.
- Guards: `skip_if_not_installed()` for `lme4`/`lmerTest`/`emmeans`/`PowerTOST`/
  `replicateBE`. Target 100% coverage; `# nocov` only for genuinely unreachable
  defensive branches.
- Extend the `v50`-bioequivalence vignette with the regulatory assessment +
  comparison, and add a regression test mirroring the `nlmixr2mbbe` EMA parity.

## References

PRs [#490](https://github.com/humanpred/pknca/pull/490),
[#547](https://github.com/humanpred/pknca/pull/547); CRAN `replicateBE`
(H. Schütz) and `PowerTOST` (D. Labes, H. Schütz, B. Lang); FDA/EMA/HC/GCC
bioequivalence guidances.
