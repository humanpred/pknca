# Design plan: pk.nca() engine performance

Status: planned; to be implemented after the secondary-parameters pull
request (branch `claude/secondary-parameters-pr3`) merges.  Findings are from
`Rprof` line-level profiling of commit `93bc3032` (merged main after the
authoring-API pull request) on 2026-08-30.

## Hard constraint

**No change may make the code less readable** (maintainer requirement).  Every
item below was selected because its fix is readability-neutral or better; an
optimization that needs an unreadable trick is out of scope regardless of its
payoff.  Each item is a small, independently testable change; do not bundle
them with unrelated work.

## How the numbers were measured (reproduction)

Three workloads against `devtools::load_all()` of the package, each phase
under `Rprof(interval = 0.005, line.profiling = TRUE)`:

- **A — dense single-dose crossover**: 150 subjects x 2 treatments, 10
  concentration times, `pknca_interval_table(0, 24, dosing = "single",
  route = "extravascular")` (the common-tier set with its default
  `start_predose_conc0` imputation).  6,000 result rows.
- **B — multiple dose, many intervals**: 60 subjects, doses every 24 h to
  120 h, 7 samples per dose, an explicit 6-row interval table requesting
  `aucint.last`, `cmax`, `tmax`, `ctrough`, `half.life`.  5,400 result rows.
- **C — secondary parameters**: 150 subjects with plasma (7 times) and urine
  (2 collections with volume and duration), units declared, explicit
  `clr.last` linkage.  450 result rows.

Percentages below are of sampled `pk.nca()` time.  Caveats: Windows `Rprof`
samples R evaluation only (roughly a third of wall time was sampled; the
proportions are the reliable quantity, the absolute seconds are not), and the
5 ms interval is below Windows' effective timer resolution.  Setup
(`PKNCAdata()`), `summary()`, and `as.data.frame()` were profiled separately
and are all trivial (under 0.3 s at these sizes).

## Findings and plans, ranked by payoff

### 1. Imputation-method lookup: ~28% of workload A

`PKNCA_impute_fun_list()` validates each imputation method name with
`utils::getAnywhere()` (`R/impute.R`, the `found_fun <-
utils::getAnywhere(...)` line) once per interval, and `getAnywhere()` runs
`ls()` over every environment on the search path.  With the common single-dose
imputation this fires ~600 times for the same two names; the actual imputation
work (`PKNCA_impute_method_*`) is 1.4%.

**Plan:** resolve and validate the method functions once per `pk.nca()` call
(the impute strings are known before the group split), or memoise
`PKNCA_impute_fun_list()` on its input string.  `exists(x, mode = "function")`
against the PKNCA namespace and the calling environment replaces the
search-path scan; keep the current clear error for an unknown method.
Readability improves (one resolution site instead of a per-interval loop).

### 2. Per-parameter result assembly: ~10% (A), larger share in B

Each calculated parameter builds a one-row `data.frame()` and `rbind`s it
onto `ret` (`pk.nca.interval()`, the `single_result <- data.frame(...)` /
`ret <- rbind(ret, single_result)` lines).  `data.frame()`'s per-call
`deparse`/`make.names` overhead is most of it (the `deparse` entries in
workload B trace here).

**Plan:** accumulate per-parameter entries in a pre-allocated list and build
one data.frame per interval at the end — the same grow-then-bind idiom
`pk.nca.intervals()` already uses one level up (`ret_list`).  Note the
mid-loop reads of `ret$PPTESTCD`/`ret$PPORRES`/`ret$exclude` (parameter
values feeding later parameters) must keep working; a parallel named list of
computed values alongside the row list keeps those lookups direct.
Readability neutral.

### 3. Half-life candidate fitting: ~16% total, ~7% in `fit_half_life()`

`.lm.fit()` is already used and is not the cost; building a one-row
`data.frame` per candidate fit is (`R/half.life.R`, the `ret <- data.frame(...)`
in `fit_half_life()`), at roughly seven candidate fits per interval.

**Plan:** have `fit_half_life()` return a named list or numeric vector per
candidate and materialize only the selected best fit as the data.frame the
callers expect.  Tests compare whole data frames including column order for
the log-linear method — keep the final shape byte-identical.  Readability
neutral.

### 4. Full-registry scan per interval: ~6% (A), ~12% (B)

The calculation loop iterates every registered parameter (221 and growing)
for every interval (`pk.nca.interval()`, the `for (n in names(all_intervals))`
loop and the `depends` expansion above it), even when an interval requests
five.

**Plan:** compute the requested set once per interval
(`names(all_intervals)[vapply(...)]` after `depends` expansion) and iterate
only it; registry order is preserved by filtering the sorted names.  The
`depends` expansion loop can likewise iterate only columns that are `TRUE`.
Readability slightly better.  This is the biggest win for many-small-interval
studies (workload B).

### 5. Repeated input validation: ~5% — needs its own careful review

`assert_conc_time()` re-validates the same conc/time vectors for every
parameter function within an interval and builds a `data.frame(conc, time)`
that is often discarded (`R/assertions.R`).

**Plan (flagged, not committed):** validate once per interval in
`pk.nca.interval()` and pass `check = FALSE` through the internal calls — the
`check =` escape already exists in several `pk.calc.*` functions — while
public direct calls keep validating.  This touches the documented validation
contract of exported functions, so it needs its own small pull request with
deliberate review of which functions may skip re-validation, and tests that
the public entry points still fail loud on bad input.

### 6. `formals(get(FUN))` per parameter per interval: ~2–3%

`pk.nca.interval()` rebuilds the cleaned formal-name list of every
calculation function on every use (the `arglist <- setdiff(names(formals(get(...))))`
line).

**Plan:** cache the cleaned formal names on the registry entry at first use —
exactly the existing `set_requires_inputs()` / `requires_*` caching precedent,
invalidated the same way.  Readability neutral.

## Measured and explicitly fine (do not optimize)

- **The secondary-parameter pass**: `pk_nca_secondary()` is ~5% of workload C
  (0.1 s for 150 linked instances).  Its per-instance lookups only matter if
  instances x linked parameters approach ~10^4; revisit with a keyed join
  then, not before.
- `PKNCAdata()` construction, `check.interval.specification()`,
  `assert_intervals()`, the units join, `summary()`, and `as.data.frame()`.

## Acceptance criteria for the implementation

- Before/after timings on the three workloads above, reported in the pull
  request; items 1–4 and 6 together are expected to remove roughly 40% of
  engine time on workload A.
- The full test suite passes unchanged — none of these items may alter any
  result value, result ordering, message, or error.
- No readability regression, judged against the hard constraint above; where
  a reviewer finds a change harder to read than what it replaced, the change
  is dropped, not defended.
- One item per commit (or pull request, for item 5), so any regression
  bisects to a single optimization.
