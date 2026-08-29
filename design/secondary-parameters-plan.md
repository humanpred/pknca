# Implementation plan: secondary PK parameters (cross-interval linkage)

Resolves the request in issue 76 (secondary parameters such as renal clearance,
bioavailability, accumulation ratio, and metabolite ratio, which need results
from two different profiles).  This document is an implementation-grade
specification: an implementer should be able to follow it section by section
without making design decisions.  Every judgement call has been made and is
recorded in the "Confirmed decisions" table.

Prior art reviewed while designing this: `pharmaverse/aNCA`
(`R/ratio_calculations.R` computes ratios post-hoc on the results data.frame —
it ignores reference-side exclusions, which this design must not) and
`john-harrold/ruminate` (its NCA module is a pure consumer of the intervals
data.frame; it needs the linkage to be plain, editable columns).

**Vocabulary used throughout**

| Term | Meaning |
|---|---|
| home row / test row | The intervals row that *requests* the secondary parameter.  Results are reported on this row's group and interval. |
| reference row | The intervals row that supplies the cross-interval input(s), identified by its `interval_id`. |
| pointer column | `<param>_ref`, a character column holding the `interval_id` of the reference row (`NA` = no explicit reference). |
| source parameter | A parameter whose *result* feeds the secondary calculation (e.g. `aucinf.obs` for `clr.obs`, `totdose` for `f`). |
| instance | One (group values, start, end) realization of an intervals row in the results.  An intervals row without group columns yields one instance per matching data group. |
| ref-marked argument | A `formalsmap` entry wrapped in `pknca_ref()`: its value comes from the reference interval. |
| home argument | A `formalsmap` entry that is a plain parameter name: its value comes from the home interval, as today. |
| explicit link | A pointer the user set (in their intervals, or via `interval_add_secondary()`). |
| automatic link | A pointer the engine derived (the PR 3 reference finder). |

**Confirmed decisions** (maintainer-confirmed 2026-08-28; implement exactly
these):

| # | Decision |
|---|---|
| 1 | Pointer columns are named `<param>_ref` (e.g. `clr.obs_ref`). |
| 2 | Engine-side dependency expansion (completing or creating reference intervals) is **ephemeral**: it operates on a working copy inside `pk.nca()`; the `PKNCAresults$data$intervals` the user gets back is their own intervals unchanged.  Visible materialization happens only through `interval_add_secondary()`. |
| 3 | The automatic reference finder (PR 3) is on by default and only acts where the alternative would be an error (§5.1 eligibility rule). |
| 4 | Adding a needed source parameter to a reference interval is **silent** — calculating dependencies without announcement is default PKNCA behavior.  Creating a whole reference *interval* (PR 3) is announced with `pknca_message_secondary_ref_created`, and every link is disclosed in `PPANMETH`. |
| 5 | **Explicit links fail loud; automatic links degrade.**  When an explicit link cannot supply a value (missing reference instance or missing source value), `pk.nca()` aborts (`pknca_error_secondary_ref_value_missing`).  When the automatic path fails (no unique reference found, or an auto-linked value is missing), the affected results are `NA` with an `exclude` reason and a warning (`pknca_warning_secondary_auto_reference`). |
| 6 | Reference-group steering: `PKNCAdata()` gains `group_ref`, a **data.frame** of group values (e.g. `data.frame(PCSPEC = "PLASMA")`) that constrains — and can by itself direct — the automatic finder.  `interval_add_secondary()`'s `reference` argument is likewise a data.frame. |
| 7 | Ratio starter set: `ratio.cmax`, `ratio.auclast`, `ratio.aucinf.obs`, `ratio.aucinf.pred`, `ratio.aucint.last`, `ratio.aucint.all`.  Bioavailability names its AUC basis: `f` is renamed `f.obs` (AUCinf,obs-based) and gains `f.pred`, `f.last`, `f.int.last`, `f.int.all`. |
| 8 | **Unit reconciliation is in scope** and is the final PR (PR 4): reference-side input values are converted into the home group's units before the calculation; non-convertible units give `NA` + reason + `pknca_warning_secondary_units`.  §6.1; the text to post on issue 76 is Appendix A. |
| 9 | Sparse data (`is_sparse_pk(data)` is `TRUE`) with any secondary parameter requested aborts with `pknca_error_secondary_sparse_unsupported`.  Lifting this is a to-do (§8). |
| 10 | Aggregated (across-subject) references are **not** planned: parallel-design comparisons of that kind are bioavailability-style analyses already served by the existing bioavailability/`be_assess()` calculation methods. |

**Work is split into four PRs, in order.**  Each PR ends with the "Definition
of done" in §7.  Do not start a PR before the previous one is merged or at
least green.

---

## 1. Orientation: read these before writing code

| File | What to learn |
|---|---|
| `R/001-add.interval.col.R` | The parameter registry: `add.interval.col()` arguments, `formalsmap`, `selection`, cache invalidation, `get.interval.cols()`. |
| `R/pk.calc.all.R` | `pk.nca()` (top-level flow, where the options merge happens, where results are combined), `pk.nca.intervals()` (per-group loop), `pk.nca.interval()` (per-interval loop; the argument-resolution chain around line 510–600; the exclusion concatenation around line 625–640; the `depends` expansion around line 488–492). |
| `R/check.intervals.R` | `check.interval.specification()`, `parameter_direct_refs()`, `parameter_source_inputs()`, `set_requires_inputs()`. |
| `R/parameter-classification.R` | `classify_secondary()`, `parameter_classification()`, `pknca_parameter_table()`. |
| `R/intervals_support.R` | `interval_longer()`/`interval_wider()` key semantics, `interval_match_groups()` (multi-row data.frames match with AND-across-columns, OR-across-rows), the `interval_add_param()` S3 pattern (PR 2 copies this pattern). |
| `R/set_and_assert_intervals.R` | `assert_intervals()` allowed-column computation. |
| `R/class-PKNCAdata.R` | `PKNCAdata.default()` (named arguments after `...`; PR 3 adds `group_ref` there). |
| `R/prepare_data.R` | `full_join_PKNCAdata()` — how intervals scope to groups (the reference-matching rule reuses this mental model; no code change here). |
| `R/unit-support.R` | `pknca_units_table()` (group-stratified units tables and how conversion factors are computed — PR 4 reuses that machinery), `pknca_unit_conversion()`. |
| `R/pk.calc.simple.R` lines ~850–880 and ~2020–2045 | Current registrations of `f` and `totdose`. |
| `R/pk.calc.urine.R` lines ~60–130 | Current registrations of `pk.calc.clr` / `clr.last` / `clr.obs` / `clr.pred`. |
| `tests/testthat/helper-generate_data.R` | `generate.conc()` / `generate.dose()` (optional; the fixtures below are explicit). |
| `vignettes/v80-writing-parameter-functions.Rmd` | The documented contract for parameter functions and the exclude attribute (PR 4 extends it). |

Run R like this on this machine (single-line `-e` only; multi-line `-e` crashes
R on Windows):

```
ls "C:/Program Files/R/"          # pick the newest version listed
"C:/Program Files/R/R-4.6.0/bin/Rscript.exe" -e "devtools::test()"
"C:/Program Files/R/R-4.6.0/bin/Rscript.exe" -e "devtools::test_active_file('tests/testthat/test-secondary-parameters.R')"
"C:/Program Files/R/R-4.6.0/bin/Rscript.exe" -e "devtools::document(); devtools::check()"
```

---

## 2. Complete inventory of new/changed surface

New exported functions (all in the new file `R/secondary-parameters.R` unless
noted): `pknca_ref()`, `is_pknca_ref()`, `interval_add_secondary()` (+
`.data.frame`, `.PKNCAdata` methods), `interval_add_renal_clearance()`,
`interval_add_accumulation_ratio()`, `interval_add_metabolite_ratio()`,
`pk.calc.ratio()`.

Changed exported function: `PKNCAdata()` gains a `group_ref` argument (PR 3).

New registered parameters: `ratio.cmax`, `ratio.auclast`, `ratio.aucinf.obs`,
`ratio.aucinf.pred`, `ratio.aucint.last`, `ratio.aucint.all`, `f.pred`,
`f.last`, `f.int.last`, `f.int.all` (all PR 2).

New internal functions (in `R/secondary-parameters.R` unless noted):
`secondary_param_info()`, `combine_exclude_reasons()` (extracted, lives in
`R/pk.calc.all.R`), `interval_deferred_params()`,
`expand_secondary_intervals()`, `pk_nca_secondary()`, `secondary_lookup()`,
`secondary_ppanmeth()`, `secondary_parameter_names()`,
`find_secondary_reference()` (PR 3), `secondary_legacy_resolvable()` (PR 3),
`pknca_unit_reconcile_factor()` (PR 4, in `R/unit-support.R`).

New intervals columns: `interval_id` (character), `<param>_ref` (character,
one per secondary parameter, only when used).

New condition classes (all follow the existing `pknca_error_*` /
`pknca_warning_*` / `pknca_message_*` naming):

| Class | Type | Raised when |
|---|---|---|
| `pknca_error_secondary_ref_unknown` | error | A pointer names an `interval_id` no row has. |
| `pknca_error_secondary_ref_without_request` | error | `<p>_ref` is non-`NA` on a row where `<p>` is not `TRUE`. |
| `pknca_error_secondary_ref_not_secondary` | error | A `<p>_ref` column exists where `p` is a registered parameter that is not secondary. |
| `pknca_error_secondary_ref_self` | error | A row's pointer equals its own `interval_id`. |
| `pknca_error_secondary_id_conflict` | error | Rows sharing an `interval_id` disagree outside parameter/impute columns. |
| `pknca_error_secondary_interval_id_invalid` | error | `interval_id` or a pointer column is not an atomic vector (e.g. a list column). |
| `pknca_error_secondary_ref_class_mismatch` | error | The linkage columns do not share one comparable class (`interval_id` vs the pointer columns, or the pointer columns among themselves when `interval_id` is absent); factors must also share their level sets. |
| `pknca_error_param_name_reserved` | error | `add.interval.col()` was given a name ending in `_ref` or the name `interval_id`. |
| `pknca_error_secondary_needs_ref` | error | A secondary parameter is requested with no pointer, no legacy fallback, and no way for the finder to act (finder not applicable: no sample-type contrast and no `group_ref`). |
| `pknca_error_secondary_ref_value_missing` | error | An **explicit** link cannot supply a value: the reference instance or a source value does not exist in the results. |
| `pknca_error_secondary_ambiguous_reference` | error | A results lookup for one (group, start, end, parameter) matches more than one row. |
| `pknca_error_secondary_target_unregistered` | error | A `pknca_ref()` target is not a registered parameter at calculation time. |
| `pknca_error_secondary_registration` | error | A secondary registration is malformed (uncovered formals; home argument missing from `depends`). |
| `pknca_error_secondary_sparse_unsupported` | error | Sparse data plus any requested secondary parameter. |
| `pknca_error_secondary_not_secondary_param` | error | `interval_add_secondary()` called for a non-secondary parameter. |
| `pknca_error_secondary_ref_ambiguous_spec` | error | `interval_add_secondary()` cannot pick one reference row per test row. |
| `pknca_error_group_ref_invalid` | error | `PKNCAdata(group_ref=)` is not a data.frame with >= 1 row and >= 1 column, or has columns that are not concentration group columns. |
| `pknca_error_group_ref_value` | error | A `group_ref` column contains a value that appears nowhere in that column of the concentration data. |
| `pknca_warning_secondary_ref_exists` | warning | `interval_add_secondary()` skips a test row that already has a different pointer. |
| `pknca_warning_secondary_auto_reference` | warning | The **automatic** path failed for some instances (no unique reference; auto-linked value missing); results are `NA` with reasons. |
| `pknca_warning_secondary_units` | warning | PR 1–3: group-stratified units differ between home and reference for a source parameter.  PR 4 narrows it to: the units differ and are **not convertible** (result `NA` + reason). |
| `pknca_message_secondary_ref_created` | message | The finder derived and created/linked a reference interval. |
| `pknca_message_secondary_created_interval` | message | `interval_add_secondary()` created reference rows / assigned ids (visible). |

There is deliberately **no** message when a source parameter is added to a
reference interval (either ephemerally by the engine or visibly by the
helper): silently calculating what a requested parameter depends on is default
PKNCA behavior.

---

## 3. PR 1 — engine and explicit linkage

Branch naming: continue on the existing feature branch or a new branch off
`origin/main`; never commit to `main`.

### 3.1 `pknca_ref()` marker

Create `R/secondary-parameters.R`.  Top of file:

```r
#' Mark a formalsmap entry as coming from the reference interval
#'
#' Used in the `formalsmap` argument of [add.interval.col()] to declare that
#' an argument takes the value of `param` calculated in the *reference*
#' interval (the interval named by the `<parameter>_ref` column of the
#' interval specification) rather than in the current interval.
#'
#' @param param The name of the NCA parameter to take from the reference
#'   interval (a single non-missing character string).  It does not need to be
#'   registered yet when `pknca_ref()` is called; it is validated when the
#'   parameter is calculated.
#' @returns An object of class `pknca_ref`.
#' @seealso [add.interval.col()], the vignette "Secondary parameters"
#' @examples
#' pknca_ref("aucinf.obs")
#' @family Interval specifications
#' @export
pknca_ref <- function(param) {
  checkmate::assert_string(param, min.chars = 1, na.ok = FALSE)
  structure(list(param = param), class = "pknca_ref")
}

#' @rdname pknca_ref
#' @param x An object to test.
#' @export
is_pknca_ref <- function(x) {
  inherits(x, "pknca_ref")
}
```

### 3.2 `secondary_param_info()` (internal)

Same file.  This is the single authority on what a secondary registration
means; both the engine and validation call it.

```r
# What a secondary parameter's registration says about its inputs.
#
# ref_args:  named character vector, formal name -> parameter taken from the
#            reference interval.
# home_args: named character vector, formal name -> parameter taken from the
#            home interval.
# Errors (classed) when the registration cannot be computed by the secondary
# pass: a formal not covered by formalsmap, an unregistered ref target, or a
# home argument not listed in `depends`.
secondary_param_info <- function(param) {
  spec <- get.interval.cols()[[param]]
  fm <- spec$formalsmap
  is_ref <- vapply(fm, is_pknca_ref, TRUE)
  ref_args <- vapply(fm[is_ref], function(x) x$param, "")
  plain <- fm[!is_ref]
  plain <- plain[!vapply(plain, inherits, TRUE, what = "AsIs")]
  home_args <- unlist(plain)   # named character vector (may be empty)
  # Every formal (minus ...) must be covered so that the pass only ever needs
  # parameter results as inputs
  fun_formals <- setdiff(names(formals(get(spec$FUN))), "...")
  uncovered <- setdiff(fun_formals, names(fm))
  if (length(uncovered) > 0) {
    rlang::abort(
      sprintf(
        "The secondary parameter '%s' has arguments not covered by formalsmap (%s); a secondary parameter's calculation function may only take NCA parameter values as inputs",
        param, paste(uncovered, collapse = ", ")
      ),
      class = "pknca_error_secondary_registration"
    )
  }
  unregistered <- setdiff(ref_args, names(get.interval.cols()))
  if (length(unregistered) > 0) {
    rlang::abort(
      sprintf(
        "pknca_ref() target(s) for parameter '%s' are not registered NCA parameters: %s",
        param, paste(unregistered, collapse = ", ")
      ),
      class = "pknca_error_secondary_target_unregistered"
    )
  }
  home_params <- home_args[home_args %in% names(get.interval.cols())]
  missing_depends <- setdiff(home_params, spec$depends)
  if (length(missing_depends) > 0) {
    rlang::abort(
      sprintf(
        "The secondary parameter '%s' uses home-interval parameter(s) not listed in `depends`: %s",
        param, paste(missing_depends, collapse = ", ")
      ),
      class = "pknca_error_secondary_registration"
    )
  }
  list(fun = spec$FUN, ref_args = ref_args, home_args = home_params)
}

# Names of all registered secondary parameters
secondary_parameter_names <- function() {
  cls <- parameter_classification()
  names(cls$secondary)[cls$secondary]
}
```

### 3.3 Registry changes (`R/001-add.interval.col.R`)

* In `add.interval.col()`, the only change needed is documentation: extend the
  `formalsmap` roxygen (the "Constants" block) with a new described item:
  a value wrapped in `pknca_ref()` means "the value of that NCA parameter
  calculated in the reference interval named by the `<name>_ref` column; see
  the vignette 'Secondary parameters'".  The existing validation (names must
  be formals of `FUN`) already accepts list values of any type — verify with a
  test, do not add type restrictions.

### 3.4 Classification derivation (`R/parameter-classification.R`)

In `classify_secondary()`, replace the computation of `declared` with:

```r
  declared <-
    names(all_intervals)[
      vapply(
        all_intervals,
        function(x) {
          isTRUE(x$selection$secondary) ||
            any(vapply(x$formalsmap, is_pknca_ref, TRUE))
        },
        TRUE
      )
    ]
```

(`vapply` over an empty `formalsmap` list gives `logical(0)` and `any()` of
that is `FALSE`, so parameters without a formalsmap are unaffected.)

### 3.5 Dependency traversal (`R/check.intervals.R`)

In `parameter_direct_refs()`, immediately after the line that drops `AsIs`
values, unwrap ref markers so the backward source-inputs search continues
through them:

```r
  args <- lapply(args, function(a) if (is_pknca_ref(a)) a$param else a)
```

No change to `get.parameter.deps_helper_funmap()` (`identical()` works on
`pknca_ref` objects as-is).

### 3.6 Interval-specification validation (`R/check.intervals.R`)

Add a block inside `check.interval.specification()` after the existing
`start`/`end` checks and before the "Confirm that something is being
calculated" block.  Implement as a helper
`check_interval_secondary_cols(x)` (defined next to it) called from there,
returning the possibly-coerced `x`.  Rules, in order:

1. Identify pointer columns: `ref_cols <- names(x)` ending in `"_ref"` whose
   prefix (`sub("_ref$", "", col)`) is a *registered parameter name*.  Columns
   ending in `_ref` whose prefix is not a registered parameter are ignored
   (they are user passthrough data).
2. For each pointer column: the prefix parameter must be secondary
   (`parameter_classification()$secondary[[prefix]]` is `TRUE`), else abort
   `pknca_error_secondary_ref_not_secondary` with message
   `"Column '<col>' is a reference pointer for '<prefix>', which is not a secondary parameter"`.
3. Type coercion/validation for `interval_id` and every pointer column: a
   factor aborts `pknca_error_secondary_interval_id_invalid`; an all-`NA`
   logical column is coerced to `NA_character_`; anything else non-character
   aborts the same class.  (Mirrors the tolerance in `setExcludeColumn()`.)
4. If any pointer column exists but `interval_id` does not, create
   `x$interval_id <- NA_character_` (pointers will then always fail rule 6 —
   which is the correct error; do NOT skip creating the column).
5. Rows sharing a non-`NA` `interval_id` must be identical in every column
   *except* the registered parameter request columns and `impute`.  Compare
   with `duplicated()` on the subset of other columns within each id; on
   violation abort `pknca_error_secondary_id_conflict` naming the id.  (This
   makes an id name exactly one logical interval; impute-split rows pass
   because they differ only in parameter columns and `impute`.)
6. For each pointer column `<p>_ref`:
   * every non-`NA` value must appear in `x$interval_id`, else abort
     `pknca_error_secondary_ref_unknown` listing the missing ids and the
     column name;
   * every row with a non-`NA` pointer must have `isTRUE(x[[p]])` on that
     row, else abort `pknca_error_secondary_ref_without_request`;
   * a row whose own `interval_id` equals its pointer aborts
     `pknca_error_secondary_ref_self` with message containing
     `"must reference a different interval"`.

### 3.7 Allowed columns (`R/set_and_assert_intervals.R`)

In `assert_intervals()`, extend `allowed_columns` with:

```r
      "interval_id",
      paste0(secondary_parameter_names(), "_ref"),
```

### 3.8 Extract the exclusion combiner (`R/pk.calc.all.R`)

Replace the block in `pk.nca.interval()` that currently computes
`exclude_reason` from `exclude_from_argument` and
`attr(tmp_result, "exclude")` (the block beginning `exclude_reason <-
stats::na.omit(...)`) with a call to a new helper, and define the helper in
the same file:

```r
# Combine exclusion reasons from a calculation's inputs with the exclusion
# the calculation itself set (the "exclude" attribute).  "DO NOT EXCLUDE" on
# the result wins and clears everything.  Documented in
# vignettes/v80-writing-parameter-functions.Rmd.
combine_exclude_reasons <- function(from_inputs, from_result) {
  reasons <- stats::na.omit(c(from_inputs, from_result))
  if (identical(from_result, "DO NOT EXCLUDE")) {
    NA_character_
  } else if (length(reasons) > 0) {
    paste(reasons, collapse = "; ")
  } else {
    NA_character_
  }
}
```

Call site: `exclude_reason <- combine_exclude_reasons(exclude_from_argument,
attr(tmp_result, "exclude"))`.  Behavior must be bit-identical to today; the
existing test suite is the guard.

### 3.9 Deferral in `pk.nca.interval()` (`R/pk.calc.all.R`)

Add the helper (in `R/secondary-parameters.R`):

```r
# Parameters in this one-row interval that are deferred to the cross-interval
# pass: requested, and with a non-NA reference pointer.
interval_deferred_params <- function(interval) {
  params <- intersect(names(interval), names(get.interval.cols()))
  ref_cols <- paste0(params, "_ref")
  has_ref <- ref_cols %in% names(interval)
  params <- params[has_ref]
  ref_cols <- ref_cols[has_ref]
  keep <- vapply(
    seq_along(params),
    function(i) isTRUE(interval[[params[i]]]) && !is.na(interval[[ref_cols[i]]]),
    TRUE
  )
  params[keep]
}
```

In `pk.nca.interval()`:

1. Compute `deferred <- interval_deferred_params(interval)` once, right after
   the `depends` expansion loop (the loop `for (n in rev(names(all_intervals)))
   ... interval[all_intervals[[n]]$depends] <- TRUE`).  The `depends`
   expansion must keep running for deferred parameters (it is what computes
   `ae`, `totdose`, and the home-side AUC in-pass) — it already does, since it
   only looks at `interval[[n]]`.
2. In the main calculation loop, extend the guard so a deferred parameter is
   skipped:
   `if (request_to_calculate && has_calculation_function && is_correct_sparse_dense && !(n %in% deferred)) {`.
3. In the argument-resolution chain (the long `if/else if` ladder), insert a
   new branch **first** (before the `AsIs` branch) handling
   `is_pknca_ref(arg_mapped)`.  This branch only runs for *non-deferred*
   parameters (deferred ones were skipped), i.e. it is the legacy-fallback
   path for a secondary parameter requested without a pointer:

```r
        if (is_pknca_ref(arg_mapped)) {
          info <- secondary_param_info(n)
          target <- arg_mapped$param
          if (!is.null(interval[[arg_formal]])) {
            # Historical escape hatch: a value column named by the formal
            # (e.g. `dose1` for f), passed through via keep_interval_cols
            call_args[[arg_formal]] <- interval[[arg_formal]]
          } else if (!(target %in% info$home_args) &&
                     any(mask_arg <- ret$PPTESTCD %in% target)) {
            # Historical same-interval behavior (e.g. clr with auclast
            # requested in the same interval).  Disallowed when the target is
            # also a home argument, because test/reference would then be the
            # same value and the result degenerate (f would always be 1).
            call_args[[arg_formal]] <- ret$PPORRES[mask_arg]
            exclude_from_argument <- c(exclude_from_argument, ret$exclude[mask_arg])
          } else {
            rlang::abort(
              sprintf(
                "The secondary parameter '%s' needs a reference interval for its '%s' argument (the value of '%s' from another interval). Set the '%s_ref' column in the interval specification to the 'interval_id' of the reference interval, give `group_ref` to PKNCAdata(), or use interval_add_secondary().",
                n, arg_formal, target, n
              ),
              class = "pknca_error_secondary_needs_ref"
            )
          }
        } else if (inherits(arg_mapped, "AsIs")) {
          ...unchanged ladder...
```

Behavior notes the implementer must preserve and test:

* `clr.last` requested together with `auclast` in one interval keeps working
  exactly as today (same-interval branch).
* `clr.last` requested *without* `auclast` and without a pointer previously
  fell through to `interval[["auclast"]]`, which is the logical request flag
  `FALSE`, silently computing `sum(ae)/0 = Inf`.  The new chain turns that
  into `pknca_error_secondary_needs_ref` (until PR 3's finder makes it
  resolvable).  This is an intended fix; add a NEWS bullet and a test.
* `f` with legacy `dose1`/`auc1` value columns (allowed only via
  `PKNCA.options(keep_interval_cols = ...)`) keeps computing; its `dose2`/
  `auc2` legacy columns are now ignored in favor of the calculated `totdose`
  and `aucinf.obs` (they are home arguments resolved from `ret`).  NEWS
  bullet.

### 3.10 Ephemeral expansion, step 1 (`R/secondary-parameters.R`)

Silent by design (decision 4): adding a needed source parameter to a
reference interval is dependency calculation, which PKNCA never announces.

```r
# Ensure every pointed-at reference interval requests the source parameters
# the link needs.  Operates on (and returns) a working copy; pk.nca() never
# stores the modified intervals in the returned PKNCAresults.
expand_secondary_intervals <- function(data) {
  iv <- data$intervals
  params <- intersect(names(iv), names(get.interval.cols()))
  ref_cols <- paste0(params, "_ref")
  present <- ref_cols %in% names(iv)
  if (!any(present)) {
    return(data)
  }
  if (is_sparse_pk(data)) {
    rlang::abort(
      "Secondary parameters are not yet supported with sparse data",
      class = "pknca_error_secondary_sparse_unsupported"
    )
  }
  for (i in which(present)) {
    p <- params[i]
    rc <- ref_cols[i]
    rows <- which(!is.na(iv[[rc]]) & vapply(iv[[p]], isTRUE, TRUE))
    for (r in rows) {
      info <- secondary_param_info(p)
      ref_rows <- which(!is.na(iv$interval_id) & iv$interval_id == iv[[rc]][r])
      for (target in info$ref_args) {
        if (!any(vapply(iv[[target]][ref_rows], isTRUE, TRUE))) {
          # First reference row only: when the reference interval is
          # impute-split, the source parameter is calculated under the first
          # split row's imputation.  A user needing a different imputation
          # requests the source parameter on the appropriate row explicitly.
          iv[[target]][ref_rows[1]] <- TRUE
        }
      }
    }
  }
  data$intervals <- iv
  data
}
```

(PR 3 extends this function — including the sparse guard moving so it also
covers finder-eligible requests without pointers; keep its shape.)

### 3.11 The secondary pass (`R/secondary-parameters.R`)

Helpers first:

```r
# The single result value of `param` for one instance.  Returns
# list(value, exclude, n) with n the number of matching rows; the caller
# decides what n != 1 means.
secondary_lookup <- function(results, group_values, start, end, param, group_cols) {
  m <- results$PPTESTCD %in% param & results$start %in% start & results$end %in% end
  for (col in group_cols) {
    m <- m & (results[[col]] %in% group_values[[col]])
  }
  idx <- which(m)
  list(
    value = if (length(idx) == 1) results$PPORRES[idx] else NA_real_,
    exclude = if (length(idx) == 1) results$exclude[idx] else NA_character_,
    n = length(idx)
  )
}

# "Reference interval: plasma024 (PCSPEC=plasma, 0-24)"
secondary_ppanmeth <- function(ref_id, override_cols, g_home, g_ref, ref_start, ref_end) {
  differing <- override_cols[
    vapply(override_cols, function(col) !(g_ref[[col]] %in% g_home[[col]]), TRUE)
  ]
  details <- c(
    vapply(differing, function(col) sprintf("%s=%s", col, g_ref[[col]]), ""),
    sprintf("%s-%s", format(ref_start), format(ref_end))
  )
  sprintf("Reference interval: %s (%s)", ref_id, paste(details, collapse = ", "))
}

stop_secondary_ambiguous <- function(param, target, group_values) {
  rlang::abort(
    sprintf(
      "More than one result found for '%s' (needed by secondary parameter '%s') for group %s. Differentiate the intervals (for example with distinct start/end or groups) so the reference is unique.",
      target, param,
      paste(names(group_values), unlist(lapply(group_values, as.character)),
            sep = "=", collapse = ", ")
    ),
    class = "pknca_error_secondary_ambiguous_reference"
  )
}

stop_secondary_value_missing <- function(param, target, ref_id, group_values, side) {
  rlang::abort(
    sprintf(
      "The secondary parameter '%s' could not be calculated for group %s: the %s value '%s'%s is not available. Calculate it in the linked intervals, or remove the request.",
      param,
      paste(names(group_values), unlist(lapply(group_values, as.character)),
            sep = "=", collapse = ", "),
      side, target,
      if (identical(side, "reference")) sprintf(" from reference interval '%s'", ref_id) else ""
    ),
    class = "pknca_error_secondary_ref_value_missing"
  )
}
```

The pass.  Provenance (decision 5): links created by the finder are recorded
by PR 3 in `data_calc$secondary_auto` — a plain list element of the
working-copy PKNCAdata (never an attribute on the intervals, which subsetting
or joins could strip) with elements `links` (data.frame: `param`, `ref_id`)
and `failures` (data.frame: one row per failed (interval row, param) with the
row's intervals group columns, `start`, `end`, `param`, `reason`).  In PR 1
that element is always absent, so every link is explicit.

```r
# Compute deferred secondary parameters from the combined results and append
# their rows.  `results` is the data.frame produced inside pk.nca() (group
# columns + start/end + keep_interval_cols + PPTESTCD/PPORRES/PPANMETH/
# exclude); `data_calc` is the PKNCAdata whose intervals carry the pointers
# (the expanded working copy).
pk_nca_secondary <- function(results, data_calc) {
  if (nrow(results) == 0 || !("PPTESTCD" %in% names(results))) {
    return(results)
  }
  iv <- data_calc$intervals
  auto <- attr(iv, "pknca_secondary_auto")   # NULL in PR 1
  params <- intersect(names(iv), names(get.interval.cols()))
  ref_cols <- paste0(params, "_ref")
  present <- ref_cols %in% names(iv)
  if (!any(present) && is.null(auto)) {
    return(results)
  }
  keep_cols <- data_calc$options$keep_interval_cols
  result_group_cols <- setdiff(
    names(results),
    c("start", "end", "PPTESTCD", "PPORRES", "PPANMETH", "exclude", keep_cols)
  )
  override_cols <- intersect(names(iv), result_group_cols)
  new_rows <- list()
  for (i in which(present)) {
    p <- params[i]
    rc <- ref_cols[i]
    for (r in which(!is.na(iv[[rc]]) & vapply(iv[[p]], isTRUE, TRUE))) {
      info <- secondary_param_info(p)
      ref_id <- iv[[rc]][r]
      is_auto <- !is.null(auto) &&
        any(auto$links$param %in% p & auto$links$ref_id %in% ref_id)
      ref_row <- which(!is.na(iv$interval_id) & iv$interval_id == ref_id)[1]
      # Home instances: distinct group combinations with any result for this
      # row's scope and times
      m_home <- results$start %in% iv$start[r] & results$end %in% iv$end[r]
      for (col in override_cols) {
        m_home <- m_home & (results[[col]] %in% iv[[col]][r])
      }
      instances <- unique(results[m_home, result_group_cols, drop = FALSE])
      for (k in seq_len(nrow(instances))) {
        g_home <- instances[k, , drop = FALSE]
        g_ref <- g_home
        for (col in override_cols) {
          g_ref[[col]] <- iv[[col]][ref_row]
        }
        inputs <- list()      # formal -> value
        excludes <- character(0)
        failed_reason <- NULL
        for (formal in names(info$home_args)) {
          found <- secondary_lookup(results, g_home, iv$start[r], iv$end[r],
                                    info$home_args[[formal]], result_group_cols)
          if (found$n > 1) stop_secondary_ambiguous(p, info$home_args[[formal]], g_home)
          if (found$n == 0) {
            if (!is_auto) {
              stop_secondary_value_missing(p, info$home_args[[formal]], ref_id,
                                           g_home, side = "home")
            }
            failed_reason <- sprintf(
              "Home value '%s' is not available for the interval",
              info$home_args[[formal]]
            )
          }
          inputs[[formal]] <- found$value
          excludes <- c(excludes, found$exclude)
        }
        for (formal in names(info$ref_args)) {
          found <- secondary_lookup(results, g_ref, iv$start[ref_row], iv$end[ref_row],
                                    info$ref_args[[formal]], result_group_cols)
          if (found$n > 1) stop_secondary_ambiguous(p, info$ref_args[[formal]], g_ref)
          if (found$n == 0) {
            if (!is_auto) {
              stop_secondary_value_missing(p, info$ref_args[[formal]], ref_id,
                                           g_home, side = "reference")
            }
            failed_reason <- sprintf(
              "Reference value '%s' is not available from reference interval '%s'",
              info$ref_args[[formal]], ref_id
            )
          }
          inputs[[formal]] <- found$value
          excludes <- c(excludes, found$exclude)
        }
        # PR 4 inserts unit reconciliation of the ref-side inputs here.
        if (is.null(failed_reason)) {
          value <- do.call(info$fun, inputs)
          excl <- combine_exclude_reasons(excludes, attr(value, "exclude"))
          value <- as.numeric(value)
        } else {
          value <- NA_real_
          excl <- combine_exclude_reasons(c(excludes, failed_reason), NULL)
        }
        template <- results[m_home, , drop = FALSE]
        template <- template[
          Reduce(`&`, lapply(result_group_cols,
                             function(col) template[[col]] %in% g_home[[col]])), ,
          drop = FALSE
        ][1, , drop = FALSE]
        template$PPTESTCD <- p
        template$PPORRES <- value
        template$PPANMETH <- secondary_ppanmeth(
          ref_id, override_cols, g_home, g_ref,
          iv$start[ref_row], iv$end[ref_row]
        )
        template$exclude <- excl
        new_rows[[length(new_rows) + 1L]] <- template
      }
    }
  }
  # PR 3 adds here: NA rows from auto$failures, plus one
  # pknca_warning_secondary_auto_reference per parameter that had any
  # automatic failure (finder failure or missing auto-linked value).
  if (length(new_rows) == 0) results else dplyr::bind_rows(results, new_rows)
}
```

Interim units warning (superseded by the PR 4 reconciliation): after
computing `override_cols`, if `data_calc$units` is a data.frame containing
any column in `result_group_cols`, then for each computed instance compare
the units row matched by the *home* group with the row matched by the
*reference* group for each `info$ref_args` target's PPTESTCD; if they differ,
`rlang::warn(..., class = "pknca_warning_secondary_units")` once per
(parameter, pair).  Keep this self-contained and defensive (wrap lookups so
absent PPTESTCD rows do not error); PR 4 replaces it.

### 3.12 Hooking into `pk.nca()` (`R/pk.calc.all.R`)

In `pk.nca()`:

* After the options merge (`data$options <- tmp_options`), add
  `data_calc <- expand_secondary_intervals(data)` and change
  `splitdata <- full_join_PKNCAdata(data)` to use `data_calc`.
* After the sparse block (right before `PKNCAresults(...)`), add
  `results <- pk_nca_secondary(results, data_calc)`.
* The `PKNCAresults(result = results, data = data, ...)` call keeps `data`
  (the user's intervals, merged options) — **not** `data_calc`.  This is what
  makes the expansion ephemeral: `filter_requested` and `summary()` consult
  `x$data$intervals` and therefore never see machinery additions.

### 3.13 Re-registrations

`R/pk.calc.urine.R` — change only the `formalsmap` lines (keep every other
argument byte-identical, including `selection = list(secondary = TRUE)`):

* `clr.last`: `formalsmap=list(auc=pknca_ref("auclast")),`
* `clr.obs`: `formalsmap=list(auc=pknca_ref("aucinf.obs")),`
* `clr.pred`: `formalsmap=list(auc=pknca_ref("aucinf.pred")),`

`R/pk.calc.simple.R` — in the `f` registration replace `depends=NULL,` with:

```r
                 formalsmap=list(dose1=pknca_ref("totdose"),
                                 auc1=pknca_ref("aucinf.obs"),
                                 dose2="totdose",
                                 auc2="aucinf.obs"),
                 depends=c("totdose", "aucinf.obs"),
```

`totdose` is registered later in the same file than `f`; that is fine —
`depends` and `pknca_ref` targets are validated lazily (`sort_interval_cols()`
and `secondary_param_info()` respectively), not at registration time.

### 3.14 PR 1 tests (`tests/testthat/test-secondary-parameters.R`)

Shared fixture (put at the top of the file; note `auc.method = "linear"` so
trapezoids are hand-computable):

```r
d_conc_sec <- data.frame(
  subject = 1,
  PCSPEC = rep(c("plasma", "urine"), times = c(3, 2)),
  time = c(0, 12, 24, 0, 12),
  conc = c(10, 6, 2, 2, 1),
  vol  = c(NA, NA, NA, 100, 150)
)
o_conc_sec <- PKNCAconc(d_conc_sec, conc~time|PCSPEC+subject, volume = "vol")
iv_sec <- data.frame(
  PCSPEC = c("plasma", "urine"),
  start = 0, end = 24,
  interval_id = c("plasma024", NA),
  auclast = c(TRUE, FALSE),
  ae = c(FALSE, TRUE),
  clr.last = c(FALSE, TRUE),
  clr.last_ref = c(NA, "plasma024")
)
o_data_sec <- PKNCAdata(o_conc_sec, intervals = iv_sec,
                        options = list(auc.method = "linear"))
```

Hand-computed expectations: `auclast = (10+6)/2*12 + (6+2)/2*12 = 144`;
`ae = 2*100 + 1*150 = 350`; `clr.last = 350/144`.

Write these tests (strict `expect_equal` on exact values wherever the value is
knowable; `expect_error(..., class = )` for every classed condition):

1. `pknca_ref()` stores the parameter and has class `pknca_ref`;
   `is_pknca_ref()` is `TRUE`/`FALSE` appropriately; `pknca_ref(NA_character_)`,
   `pknca_ref("")`, and `pknca_ref(c("a","b"))` error.
2. `pknca_parameter_table()$secondary` is unchanged by the re-registrations
   (the existing pinned test in `test-parameter-classification.R` must still
   pass — run it and do not edit it in PR 1).
3. `check.interval.specification()`: one test per rule in §3.6 (unknown ref
   id; pointer without request; `cmax_ref` column aborts as not-secondary;
   factor `interval_id` aborts; all-`NA` logical pointer column is accepted
   and coerced; id conflict when two rows share an id but differ in `start`;
   self-reference aborts).
4. `assert_intervals()` accepts `interval_id` and `clr.last_ref` columns and
   still rejects a misspelled column.
5. End-to-end exact value: `pk.nca(o_data_sec)` gives one `clr.last` row with
   `PPORRES == 350/144`, on the urine group, `start == 0`, `end == 24`.
6. PPANMETH exact: that row's `PPANMETH ==
   "Reference interval: plasma024 (PCSPEC=plasma, 0-24)"`.
7. Deferral is ephemeral: `result$data$intervals` is identical to
   `check.interval.specification(iv_sec)` (no machinery mutations), and the
   `ae` row exists in the results (home-side `depends` ran).
8. Silent completion: with `auclast = c(FALSE, FALSE)` in the fixture
   intervals, `pk.nca()` still gives `clr.last == 350/144` and emits no
   secondary-related message or warning; the plasma `auclast` row is present
   in `as.data.frame(result)` and absent with `filter_requested = TRUE`.
9. `f` end-to-end self-consistency: two-treatment crossover fixture (one
   subject, groups `treatment %in% c("ref", "test")`, doses 100 and 50,
   concentration profiles long enough for `aucinf.obs` — at least 3 points
   after tmax).  Assert
   `f == (aucinf_test/totdose_test)/(aucinf_ref/totdose_ref)` where the four
   values are extracted from the same run's results, and
   `totdose` rows equal `c(100, 50)` exactly.
10. Exclusion carry-through: plasma profile `time = c(0, 2, 4, 6)`,
    `conc = c(10, 8, 7, 6.5)` (span ratio below the default minimum) with
    `clr.obs`/`aucinf.obs`.  The `aucinf.obs` row's `exclude` is non-`NA`;
    the `clr.obs` row's `exclude` contains the same text
    (`expect_match(..., regexp = "[Ss]pan ratio")` — verify the exact wording
    from the `aucinf.obs` row and assert the `clr.obs` text `expect_equal`
    to it), and `clr.obs` `PPORRES` is the computed (non-`NA`) ratio.
11. Explicit link, missing reference instance (decision 5): add
    `subject = 2` urine-only data; `pk.nca()` aborts with
    `pknca_error_secondary_ref_value_missing` and a message naming
    `clr.last`, `auclast`, `plasma024`, and `subject=2`.
12. Ambiguous reference: duplicate the plasma intervals row (second copy with
    `interval_id = NA`) so `auclast` is computed twice for the same
    (group, start, end); `pk.nca()` aborts with
    `pknca_error_secondary_ambiguous_reference`.
13. Needs-ref error: intervals requesting only `f = TRUE` abort with class
    `pknca_error_secondary_needs_ref` and message containing `"f_ref"` and
    `"group_ref"`.  **Update** the existing expectation in
    `tests/testthat/test-pk.calc.all.R` (around line 227–235) that currently
    expects `"Cannot find argument 'dose1' ..."` to the new class/message.
14. Legacy same-interval clr: single interval with `ae`, `auclast`, and
    `clr.last` all `TRUE` (no pointer) on data carrying both `conc` and
    `volume` values gives `clr.last == sum(conc*vol)/auclast` exactly (the
    pre-existing behavior).
15. Legacy-degenerate guard: requesting `f` with `totdose` and `aucinf.obs`
    requested in the same interval and no pointer still aborts with
    `pknca_error_secondary_needs_ref` (the same-interval fallback must not
    produce `f == 1`).
16. Fixed silent-`Inf` bug: `clr.last` requested with `ae` but *without*
    `auclast` and without a pointer aborts with
    `pknca_error_secondary_needs_ref` (previously computed `Inf`).
17. Units: fixture with `concu = "ng/mL"`, `timeu = "hr"`, `amountu = "mg"`
    on `PKNCAconc`; the `clr.last` row's `PPORRESU == "mg/(hr*ng/mL)"`.
18. `summary()` on the fixture result contains a `clr.last` column with a
    non-`"NC"`, non-`"not requested"` value on the urine row.
19. Sparse guard: a sparse `PKNCAconc` (`sparse = TRUE`) with a secondary
    request aborts `pknca_error_secondary_sparse_unsupported`.
20. `combine_exclude_reasons()` unit tests: (`NULL`, `NULL`) gives `NA`;
    inputs concatenate with `"; "`; `"DO NOT EXCLUDE"` as `from_result`
    clears input reasons.

### 3.15 PR 1 documentation and bookkeeping

* `devtools::document()`; stage `NAMESPACE` and new/changed `man/` files.
* `NEWS.md` bullets under "# Development version" (follow the existing bullet
  style; issue references like `(#76)` are fine in NEWS, never in commit
  messages):
  * Secondary parameters can now be calculated by linking intervals with
    `interval_id` and `<parameter>_ref` columns; exclusions on the source
    values carry through (#76).
  * `add.interval.col()` `formalsmap` accepts `pknca_ref()` to declare an
    argument that comes from the reference interval.
  * Requesting `clr.*` without its AUC (and without a reference interval) is
    now an error instead of silently dividing by zero.
  * `f` now computes `dose1`/`auc1` from the reference interval and
    `dose2`/`auc2` from its own interval (`totdose`, `aucinf.obs`); the old
    `dose2`/`auc2` passthrough columns are ignored.
* Run `spelling::spell_check_package()`; add genuinely new words to
  `inst/WORDLIST`.

### 3.16 As built (PR 1 and its review)

PR 1 merged with these differences from the section-3 text above.  PR 2–4
implementers should trust the code over the sketches where they differ:

* `pknca_ref()`/`is_pknca_ref()` live in `R/001-add.interval.col.R` (the
  `clr.*`/`f` registrations call `pknca_ref()` at source time, so it must be
  defined before the `pk.calc.*` files load); everything else is in
  `R/secondary-parameters.R`.
* `secondary_param_info()`: a formal that `formalsmap` does not mention keeps
  `pk.nca.interval()`'s identity mapping and is a home argument when a
  parameter of that name is registered (`ae` for `clr.*`); a plain formalsmap
  value that is not a registered parameter is reported as uncovered.  The
  original "every formal must be in `formalsmap`" rule would have rejected
  the `clr.*` registrations this spec itself prescribes.
* Section 3.14's test 10 was rewritten: span-ratio exclusion is post-hoc only
  (`exclude_nca_span.ratio()` on a finished `PKNCAresults`), so the fixture
  uses the too-few-half-life-points exclusion, and the excluded value
  crossing the link is `NA` (every exclusion PKNCA sets during a calculation
  leaves the value `NA`).
* `parameter_classification()` and `auc_basis_families()` cache with the
  registry's parameter names as the key, so a registry restored by direct
  assignment cannot leave a stale cache.  Tests snapshot and restore the
  registry only through the shared helper `local_interval_cols()`
  (`tests/testthat/helper-interval-cols.R`).
* Ungrouped data is one anonymous instance in `pk_nca_secondary()`
  (`duplicated()` on a zero-column data.frame returns length zero before
  R 4.5, so `unique()` cannot be used there).
* From the pull-request review of PR 1:
  * `add.interval.col()` rejects parameter names ending in `_ref` and the
    name `interval_id` (`pknca_error_param_name_reserved`) — they would
    collide with the linkage columns.
  * The linkage columns hold identifiers of **any comparable class** —
    character names, factors, or numbers such as row indices — instead of
    being forced to character.  Rules (replacing section 3.6's rule 3):
    every linkage column must be an atomic vector
    (`pknca_error_secondary_interval_id_invalid`); `interval_id` and every
    pointer column must share one class, factors must also share their level
    sets, and with no `interval_id` column the pointer columns must agree
    among themselves (`pknca_error_secondary_ref_class_mismatch`); an all-`NA`
    logical column is an unfilled column, compatible with anything and left
    uncoerced.  Integer and double are one class for this purpose.  When
    pointer columns exist without `interval_id`, the created all-`NA`
    `interval_id` takes the pointer columns' class.
  * `PPANMETH` names the reference by how it differs and by its times only
    (`"Reference interval: PCSPEC=plasma, 0-24"`); the `interval_id` is
    tracking information, not part of the analysis method, so it is not in
    `PPANMETH` (it still appears in error messages).
  * The missing-value messages read "the value 'x' from this interval / from
    the reference interval ('id') is not available" and list the remedies,
    including restricting the interval rows to groups that have the data.
  * The ambiguity message points at the impute-split remedy (request the
    source parameter on only one split row).
  * `name_value_text()` (`R/general.functions.R`) renders `name=value`
    message text package-wide (secondary messages, interval error preambles,
    group warning preambles, sparse-dose mismatches, unit-mismatch listings).
  * The intervals data.frame variables are named `current_intervals`, never
    `iv` (which reads as intravenous).
* `interval_remove_param()` clears the reference pointer of a removed
  secondary parameter (`clear_orphan_ref_pointers()` in
  `R/secondary-parameters.R`), so edited intervals keep validating; removing
  a reference row's last parameter still surfaces as
  `pknca_error_secondary_ref_unknown` at the next validation, which is the
  correct loud outcome.

---

## 4. PR 2 — authoring API, ratio parameters, and bioavailability variants

### 4.1 `pk.calc.ratio()` and ratio registrations (`R/secondary-parameters.R`)

```r
#' Calculate the ratio of a parameter between two intervals
#'
#' @param test The parameter value in the current (test) interval
#' @param reference The parameter value in the reference interval
#' @returns test/reference, or NA if the reference is missing or <= 0
#' @export
pk.calc.ratio <- function(test, reference) {
  if (is.na(reference) || reference <= 0) {
    NA_real_
  } else {
    test/reference
  }
}
```

Add `"parameter_ratio"` to the vector returned by `pknca_concepts()` in
`R/001-add.interval.col.R` (append in the "Bookkeeping" group).  **Check
whether a test pins the `pknca_concepts()` vector and update it.**

Register the six ratios (explicit calls, house style).  For each `p` in
`c("cmax", "auclast", "aucinf.obs", "aucinf.pred", "aucint.last",
"aucint.all")`:

```r
add.interval.col(
  paste0("ratio.", p),
  FUN = "pk.calc.ratio",
  values = c(FALSE, TRUE),
  unit_type = "fraction",
  pretty_name = paste("Ratio of", p),
  desc = paste("Ratio of", p, "vs reference"),   # longest is 33 chars
  formalsmap = list(test = p, reference = pknca_ref(p)),
  depends = p,
  selection = list(concept = "parameter_ratio")
)
```

After the registrations, add the summary settings in the same file:

```r
PKNCA.set.summary(
  name = paste0("ratio.", c("cmax", "auclast", "aucinf.obs", "aucinf.pred",
                            "aucint.last", "aucint.all")),
  description = "geometric mean and geometric coefficient of variation",
  point = business.geomean,
  spread = business.geocv
)
```

### 4.2 Bioavailability basis variants (`R/pk.calc.simple.R`, next to `f`)

Four new registrations sharing `FUN = "pk.calc.f"`.  `f` itself stays as
re-registered in PR 1 (AUCinf,obs basis, CDISC `FAB`).  For each pair
(name, basis) in `("f.pred", "aucinf.pred")`, `("f.last", "auclast")`,
`("f.int.last", "aucint.last")`, `("f.int.all", "aucint.all")`:

```r
add.interval.col("f.pred",
                 FUN="pk.calc.f",
                 values=c(FALSE, TRUE),
                 unit_type="fraction",
                 pretty_name="Bioavailability (AUCinf,pred)",
                 desc="Bioavailability from AUCinf,pred",
                 formalsmap=list(dose1=pknca_ref("totdose"),
                                 auc1=pknca_ref("aucinf.pred"),
                                 dose2="totdose",
                                 auc2="aucinf.pred"),
                 depends=c("totdose", "aucinf.pred"),
                 pptestcd_cdisc="FAB",
                 pptest_cdisc="Absolute Bioavailability",
                 formula="$F = \\frac{AUC_{\\infty,pred,2} / Dose_2}{AUC_{\\infty,pred,1} / Dose_1}$",
                 selection = list(secondary = TRUE))
```

Analogous for the other three (`pretty_name` "Bioavailability (AUClast)" /
"(AUCint,last)" / "(AUCint,all)"; `desc` "Bioavailability from AUClast" /
"from AUCint,last" / "from AUCint,all" — all under 40 characters; the formula
strings substitute the basis).  Repeating `pptestcd_cdisc="FAB"` across
variants follows the `clr.*`/`RENALCL` precedent.  Add all four names plus
`"f"` to a geomean/geocv `PKNCA.set.summary()` call if `f` is not already
covered (check `grep 'PKNCA.set.summary' R/pk.calc.simple.R` — `f` is in an
existing geomean group; extend that call with the new names).

**Update the pinned secondary-parameter list** in
`tests/testthat/test-parameter-classification.R` (the test
"secondary marks the parameters needing more than one profile") to include the
six `ratio.*` names and the four `f.*` variants.  Also confirm
`pknca_check_parameter_classification()` still returns zero rows (the ratio
concept declaration and the `bioavailability` concept on `pk.calc.f`
guarantee it).

### 4.3 `interval_add_secondary()` (`R/secondary-parameters.R`)

S3 generic + methods, modeled line-for-line on the `interval_add_param()`
pattern in `R/intervals_support.R` (data.frame method does the work; the
PKNCAdata method delegates on `data$intervals`).

```r
interval_add_secondary <- function(data, param, reference = NULL,
                                   target_groups = NULL, ref_id = NULL, ...)
```

`reference` is a **data.frame** (decision 6): columns name intervals columns
and/or `start`/`end`; multiple rows mean "any of these" (OR), matching
`interval_match_groups()` semantics.  A named list input is accepted by
coercing with `as.data.frame()` for convenience, but the data.frame form is
the documented interface.

Data.frame-method algorithm (each numbered step is sequential):

1. `assert_param_name(param)` (from `R/assertions.R`); `param` must be length
   1.  If `!parameter_classification()$secondary[[param]]`, abort
   `pknca_error_secondary_not_secondary_param` with message
   `"'<param>' is not a secondary parameter; use interval_add_param() instead"`.
2. If `reference` is `NULL`: in PR 2, abort with a plain error
   `"reference must be given"`; PR 3 replaces this branch with the finder
   (and, for the PKNCAdata method, with `data$group_ref` as the default).
   Otherwise coerce to a data.frame; its names must each be `"start"`,
   `"end"`, or an existing column of the intervals data.frame; unknown names
   abort (reuse the message style of `interval_match_groups()`).
3. Locate reference rows: start from all rows; if `reference` has group
   columns, keep rows matching them via
   `interval_match_groups(iv, reference[group cols])`; if it has `start`/`end`
   columns, additionally require equality on them.  Zero matching rows means
   **create** (step 4); otherwise go to step 5.
4. Create reference rows: take the test rows (step 6 determines them; compute
   test rows first in the implementation), keep only their non-parameter,
   non-pointer columns (drop `impute` too — created rows get `NA` imputation;
   the data-level `data$impute` still applies to them automatically), override
   the columns named in `reference` with its values (one created row per
   `reference` row when it has several), set every registered parameter
   column `FALSE`, set the source parameters
   (`secondary_param_info(param)$ref_args`) `TRUE`, and `unique()` the
   result.  Append to the intervals.  Emit
   `pknca_message_secondary_created_interval` listing each created row as
   `col=value` pairs.
5. Assign ids: reference rows lacking a non-`NA` `interval_id` get one.  If
   `ref_id` is given and there is exactly one distinct reference interval, use
   it; otherwise generate an id **matching the class of the existing
   `interval_id` column** (identifiers may be any comparable class, per
   section 3.16): `"ref1"`, `"ref2"`, ... for character (skipping ids already
   present anywhere in the intervals), `max(interval_id, na.rm = TRUE) + 1`
   for numeric, and a new level `"ref<k>"` appended to the levels for factor.
   An all-`NA` unfilled column defaults to character ids.  Reference rows
   that already share ids keep them.
6. Test rows: rows matching `target_groups` (via `interval_match_groups()`)
   when given, otherwise all rows that are not reference rows.  For each test
   row pick the reference row: if more than one distinct reference interval
   matched in step 3, prefer the one with the same `start`/`end` as the test
   row; if that leaves anything ambiguous, abort
   `pknca_error_secondary_ref_ambiguous_spec` telling the user to narrow
   `reference` (for example by adding `start`/`end` columns).
7. For each test row: if it already has a non-`NA` pointer differing from the
   chosen id, `rlang::warn(class = "pknca_warning_secondary_ref_exists")` and
   skip; otherwise set `iv[[param]] <- TRUE` and
   `iv[[paste0(param, "_ref")]] <- id` on that row.  Also set the source
   parameters `TRUE` on the chosen reference rows (visible and silent —
   dependency completion is not announced).
8. Return `check.interval.specification(iv)` so the output is always valid.

Wrappers (thin, one-line bodies delegating to `interval_add_secondary()`):

```r
interval_add_renal_clearance <- function(data, reference, param = "clr.obs",
                                         target_groups = NULL, ...)
interval_add_accumulation_ratio <- function(data, ref_start, ref_end,
                                            param = "ratio.aucint.last",
                                            target_groups = NULL, ...)
  # builds reference = data.frame(start = ref_start, end = ref_end)
interval_add_metabolite_ratio <- function(data, reference,
                                          param = "ratio.aucinf.obs",
                                          target_groups = NULL, ...)
```

### 4.4 PR 2 tests

1. `pk.calc.ratio()` exact: `pk.calc.ratio(10, 20) == 0.5`; reference `0`,
   negative, and `NA` give `NA_real_`.
2. `interval_add_secondary()` on the §3.14 fixture intervals *without* the
   pointer/id columns, `reference = data.frame(PCSPEC = "plasma")`: the
   returned data.frame equals the hero-table intervals (`expect_equal` on the
   full data.frame after column reordering by
   `check.interval.specification()`), with the auto id `"ref1"`.
3. `ref_id = "plasma024"` reproduces the fixture exactly.
4. Creation: intervals containing only the urine row; the same call creates
   the plasma row (message class checked with `expect_message(..., class =)`),
   and `pk.nca()` on the result gives `clr.last == 350/144`.
5. Existing-pointer warning; not-secondary abort; unknown reference-column
   abort; ambiguous-reference-spec abort (two plasma rows with different
   times, no `start`/`end` in `reference`).
6. Accumulation ratio end-to-end: one group, two intervals 0–24 and 24–48
   with `aucint.last`; `interval_add_accumulation_ratio(iv, 0, 24)` then
   `pk.nca()`; assert `ratio.aucint.last == aucint_2/aucint_1` from the same
   run's rows, and PPANMETH `"Reference interval: 0-24"` (the as-built format
   of section 3.16: the id is tracking information and stays out of
   PPANMETH).
7. Metabolite ratio end-to-end across an `Analyte` group, including the
   exclusion-carry assertion (excluded parent AUC marks the ratio).
8. Cross-check: in a crossover run computing `f` (via linkage), extract
   `aucinf.obs.dn` for both treatments and assert
   `f == aucinf.obs.dn_test / aucinf.obs.dn_ref`.
9. `f.last` end-to-end with the linear-AUC crossover fixture: assert against
   the hand-computable `auclast` values and doses
   (`f.last == (auclast_test/dose_test)/(auclast_ref/dose_ref)` exactly);
   `f.pred` self-consistency against same-run `aucinf.pred` rows.
10. Summary settings: geomean/geocv registered for all six ratios and the
    four `f.*` variants (query the summary settings the way existing tests
    do).
11. Registered `desc` lengths: `nchar(desc) <= 40` for every new
    registration (loop over `get.interval.cols()` entries added here).

### 4.5 PR 2 documentation

`devtools::document()`; NEWS bullets (new `interval_add_secondary()` family;
new `ratio.*` parameters; new `f.*` basis variants); spell check.

### 4.6 As built (PR 2)

PR 2 merged with these differences from the section-4 text above; trust the
code over the sketches:

* **The parameter `f` is renamed `f.obs`** (maintainer decision on review),
  matching the specificity of `f.pred` and the `clr.*` family.
  `pk.calc.f()` keeps its name (it computes every basis), the CDISC code
  stays `FAB`, and `assert_intervals()` points an interval specification
  using the old name `f` at `f.obs`.  Everywhere else this document says the
  parameter `f`, read `f.obs`.

* `pk.calc.ratio()` is vectorized (`ret <- test/reference` with an `NA` mask
  for missing or non-positive references) rather than the scalar `if` sketch,
  matching `pk.calc.f()`'s style and tolerating zero-length input.
* `ref_id` given while `reference` matches more than one distinct reference
  interval is an error (`pknca_error_secondary_ref_ambiguous_spec`), not
  silent generation.
* Invalid `reference` columns reuse the existing
  `pknca_error_interval_target_groups_cols` class with a reference-specific
  message; a parameter request column is rejected as a reference descriptor.
  Valid descriptor columns are `interval_describe_cols()`: everything except
  parameter requests, pointer columns, `interval_id`, and `impute`.
* `target_groups` matching nothing (or only reference rows) warns
  `pknca_warning_interval_no_target_rows` and returns the input unchanged,
  mirroring `interval_edit_param()`.
* Generating a factor identifier re-levels every pointer column to the
  identifier column's levels (`interval_sync_ref_cols()`), or the result
  would fail the comparability rule.
* Reference rows are always excluded from the test rows, so a row can never
  become its own reference.
* When several reference intervals match, a test row takes the one sharing
  its own `start`/`end` (`interval_pick_reference()`), or failing that the
  single one *covering* its times; with neither the ambiguity abort names the
  row.
* **Created spot-sample references span the collections whole** (maintainer
  decision on review):  when the parameter pairs an interval collection with
  spot-sample references (`secondary_interval_over_spot()`, i.e. renal
  clearance) and the `PKNCAdata` method creates the reference, the created
  interval's `end` extends to `max(time + duration)` over the test rows'
  collections (`interval_collection_ends()`), because a collection beginning
  inside the interval contributes its full amount and the paired AUC must
  cover the same span.  An explicit `end` in `reference` overrides it, and
  the data.frame method (no concentration data) copies the test times
  unchanged.
* The `interval_edit_secondary()` internals PR 3 will touch: the
  `reference = NULL` branch to replace lives in
  `interval_secondary_validate()`, and id generation is
  `interval_new_ids()`/`interval_assign_ref_ids()` (already class-matched per
  section 4.3 step 5).
* Two test files (`test-pk.calc.all.R`, `test-interval-table.R`) derive their
  secondary-parameter exclusion lists from
  `pknca_parameter_table()$secondary` instead of hard-coding names, so new
  secondary registrations do not break unrelated tests.

---

## 5. PR 3 — automatic reference finder, `group_ref`, and interval creation

### 5.1 Eligibility (the error-replacing rule)

The finder may only fire where PR 1 would abort with
`pknca_error_secondary_needs_ref`.  Implement:

```r
# TRUE when the parameter can be calculated on this row without any
# cross-interval linkage (the PR 1 legacy fallbacks).
secondary_legacy_resolvable <- function(iv_row, info) {
  all(vapply(
    seq_along(info$ref_args),
    function(i) {
      formal <- names(info$ref_args)[i]
      target <- info$ref_args[[i]]
      !is.null(iv_row[[formal]]) ||
        (!(target %in% info$home_args) && isTRUE(iv_row[[target]]))
    },
    TRUE
  ))
}
```

### 5.2 `group_ref` on `PKNCAdata()` (`R/class-PKNCAdata.R`)

Add `group_ref = NULL` to the named arguments of `PKNCAdata.default()` (after
`options`), store it as `ret$group_ref`, and document it:

> `group_ref`: A data.frame of group values identifying reference profiles
> for automatically-linked secondary parameters.  Columns must be group
> columns of the concentration data; multiple rows mean any row may match.
> For example, with groups crossing `TRTP`, `PCTEST`, and `PCSPEC`,
> `group_ref = data.frame(PCSPEC = "PLASMA")` directs renal-clearance
> references to the plasma profiles, and
> `group_ref = data.frame(PCTEST = "midazolam")` directs metabolite ratios to
> the parent analyte.

Validation at `PKNCAdata()` time (fail loud on typos):

* Not `NULL` and not a data.frame with at least one row and one column, or
  any column not in `names(getGroups(o_conc))` — abort
  `pknca_error_group_ref_invalid`.
* Any value in a `group_ref` column that appears nowhere in that column of
  the concentration data — abort `pknca_error_group_ref_value` naming the
  column and value.

### 5.3 The finder

```r
# For one home intervals row and secondary parameter, derive the reference
# group override(s) from the data.  Returns a named list of override values
# (restricted to columns present in the intervals) on success, or a character
# string holding the failure reason.  Returns NULL when the finder is not
# applicable (caller falls through to the in-interval needs-ref abort).
find_secondary_reference <- function(data, iv, row, param, info) { ... }
```

Algorithm (all outcomes are per (intervals row, parameter); see step 7):

1. `group_ref <- data$group_ref` (may be `NULL`).
   `cls <- parameter_classification()`.
   Sample-type applicability: `st_applicable <-` every
   `cls$sample_type[[t]]` for `t` in `info$ref_args` equals `"spot"`, AND
   `cls$sample_type[[param]] == "interval"`, AND the concentration data
   declares a volume column (`!is.null(data$conc$columns$volume)`).  This
   rule is mechanical — never special-case parameter names.
2. If `is.null(group_ref) && !st_applicable`, return `NULL` (not applicable;
   `ratio.*` with no `group_ref` lands here).
3. Group table: `gcols <- unlist(data$conc$columns$groups)`; for each
   distinct group combination in `data$conc$data`, compute `has_volume`
   (`any(!is.na(vol) & vol > 0)` over that group's rows of the declared
   volume column; `FALSE` when no volume column exists).
4. Candidate pool: start from all groups; if `st_applicable`, keep
   `has_volume == FALSE`; if `group_ref` is non-`NULL`, keep groups matching
   it (`interval_match_groups()`).  Empty pool: return the failure reason
   `"no candidate reference groups match"` (mentioning `group_ref` when it
   was given).
5. Home instances: distinct group combinations matching the row's values for
   the group columns present in the intervals.  If a home instance matches
   `group_ref` itself (all `group_ref` columns), the row fails with reason
   `"the interval's own group matches group_ref; there is no distinct reference"`
   (this is the parent-analyte row when a metabolite ratio is requested
   everywhere).
6. Per home instance: candidates are pool groups minus the instance itself
   (distance 0 excluded); distance = number of `gcols` where the candidate
   differs; keep the minimum distance.  Exactly one candidate: its differing
   column/value pairs form the override set.  A tie: the row fails with a
   reason listing the tied candidates and suggesting `group_ref` or an
   explicit pointer.  An override column not present in the intervals
   data.frame: the row fails with reason
   `"add '<col>' to the intervals so the reference can be expressed, or set '<param>_ref'"`.
7. Collapse across instances: all home instances of the row must produce the
   same override set (they share the row's intervals-column values, so this
   is the normal case).  More than one distinct set, or any instance-level
   failure, fails the whole row (single-pointer model; the reason names the
   first conflict).  Success returns the one override set.

### 5.4 Extending `expand_secondary_intervals()`

Restructure so the sparse guard runs whenever any secondary parameter is
requested at all (not only when pointer columns exist).  Then, after the
PR 1 step-1 loop, for every (row `r`, secondary parameter `p`) with
`isTRUE(iv[[p]][r])`, pointer `NA` (or column absent), and
`!secondary_legacy_resolvable(iv[r, ], info)`:

1. `res <- find_secondary_reference(data, iv, r, p, info)`.
   `NULL`: do nothing (the in-interval `needs_ref` abort handles it).
2. Character (failure reason), per decision 5: record a row in the
   `failures` ledger (the row's intervals group-column values, `start`,
   `end`, `param = p`, `reason = res`) and set `iv[[p]][r] <- FALSE` so the
   in-interval abort never fires.  Do not warn here; the pass warns once per
   parameter (§5.5).
3. Named list (success): look for an existing intervals row with the same
   `start`/`end` as row `r` whose values match the override set for those
   columns and match row `r` for every other intervals group column.  Found:
   reuse it (assign an id if it has none).  Not found: append a working-copy
   row — copy row `r`'s non-parameter/non-pointer columns, apply the
   override, set all parameter columns `FALSE`, `impute <- NA_character_` if
   that column exists.  Apply the whole-collection span of section 4.6 to the
   created row: for an interval-over-spot parameter, extend its `end` with
   `interval_collection_ends()` so the ephemeral reference covers the home
   row's collections including their durations.  Ids: `"autoref1"`, `"autoref2"`, ... skipping
   existing ids, matched to the `interval_id` column's class as in section
   4.3 step 5 (numeric ids continue with `max + 1`; factor ids gain a new
   level).  Ensure the pointer column exists (created with the
   `interval_id` column's class if absent), set it on row `r`, record
   `(param = p, ref_id = id)` in the `links` ledger, and run the shared
   completion logic (source parameters `TRUE` on the reference row —
   silent).  Announce the linkage:
   `rlang::inform(class = "pknca_message_secondary_ref_created")` with
   message
   `sprintf("Secondary parameter '%s': using (%s) as the reference interval ('%s').", p, <col=value pairs plus start-end>, id)`
   — wording "created reference interval" when a row was appended, "using
   existing interval" when reused.
4. Attach the ledgers before returning:
   `data$secondary_auto <- list(links = ..., failures = ...)`
   (both zero-row data.frames when nothing automatic happened).  Do **not**
   re-run `check.interval.specification()` on the working copy — its
   mutations preserve validity by construction, and a re-run would emit a
   spurious "nothing to calculate" warning for a row whose only request was
   removed in step 2.

### 5.5 Automatic-failure results (`pk_nca_secondary()`)

Extend the pass (the marked insertion point in §3.11):

* For each row of `auto$failures`: enumerate its instances from `results`
  (match the ledger's group-column values plus `start`/`end`, the same
  template mechanics as §3.11), and append one row per instance with
  `PPTESTCD = param`, `PPORRES = NA_real_`, `PPANMETH = NA_character_`, and
  `exclude = reason`.
* Remove the three `# nocov` blocks in `pk_nca_secondary()` that guard the
  automatic-failure branches (home-side missing, `failed_reason` recording,
  and the `NA`-result arm) — they become reachable and tested here.
* Emit **one** `rlang::warn(class = "pknca_warning_secondary_auto_reference")`
  per parameter that had any automatic failure (finder failures and missing
  auto-linked values combined), e.g.
  `"Secondary parameter 'clr.obs': no unique reference interval could be determined for 3 interval(s); results are NA (see the exclude column). Set 'clr.obs_ref', give group_ref to PKNCAdata(), or use interval_add_secondary()."`
* Missing values on **auto** links already give `NA` + reason via the
  `is_auto` branch in §3.11; count those instances into the same one-per-
  parameter warning.

### 5.6 `interval_add_secondary(reference = NULL)` and `group_ref`

Replace the PR 2 "reference must be given" branch:

* The PKNCAdata method with `reference = NULL` uses `data$group_ref` as the
  reference specification when set (equivalent to passing it as
  `reference`); otherwise both methods run `find_secondary_reference()` per
  test row and **materialize** its answer (created rows, ids, pointers) with
  the PR 2 message.  Finder failures here are errors (this is an explicit
  user call, not the automatic path): abort with the failure reason, class
  `pknca_error_secondary_needs_ref`.

### 5.7 PR 3 tests

The worked steering example (from the maintainer): groups
`tidyr::crossing(TRTP = c("10 mg", "20 mg"), PCTEST = c("midazolam",
"1-OH-midazolam"), PCSPEC = c("URINE", "PLASMA"))` with
`group_ref = data.frame(PCSPEC = "PLASMA")`.

1. Urine-only specification: the §3.14 conc fixture with intervals containing
   *only* the urine row (`ae`, `clr.last`); `pk.nca()` emits
   `pknca_message_secondary_ref_created`, and the `clr.last` value equals
   `350/144` — `expect_equal` to the explicit-linkage run's value.
2. Ephemerality: `result$data$intervals` identical to the checked input
   intervals; the machinery `auclast` row present in `as.data.frame()`,
   absent under `filter_requested = TRUE`; absent from `summary()`.
3. Reuse: when a plasma 0–24 row already exists (with or without `auclast`),
   no duplicate is created — exactly one `auclast` result row for the plasma
   group.
4. Ambiguity degrades (decision 5): add a second spot group
   (`PCSPEC = "serum"`) with data and no `group_ref`; `pk.nca()` warns
   (`pknca_warning_secondary_auto_reference`, message listing both
   candidates), the `clr.last` rows are `NA` with the reason in `exclude`,
   and every other requested parameter still calculates.
5. `group_ref` breaks the tie: same fixture plus
   `group_ref = data.frame(PCSPEC = "plasma")`; no warning, `clr.last ==
   350/144`.
6. Four-group steering fixture (the crossing above, minimal data per group):
   `clr.*` requested on urine rows resolves each (TRTP, PCTEST) to its own
   plasma reference — assert the PPANMETH of each result names the matching
   PCTEST and TRTP is unchanged.
7. `group_ref`-directed metabolite ratio: `ratio.aucinf.obs` requested on
   all rows, `group_ref = data.frame(PCTEST = "midazolam")`, intervals carry
   the `PCTEST` column: metabolite rows get parent-referenced ratios
   (values asserted against same-run AUCs); parent rows get `NA` with the
   "own group matches group_ref" reason and the one-per-parameter warning.
8. Inexpressible override: intervals *without* the `PCSPEC` column on
   mixed-specimen data — `clr` requests fail with the
   "add 'PCSPEC' to the intervals" reason (NA + warning, not an abort).
9. Eligibility: urine row requesting `clr.last` *and* `auclast` (legacy
   same-interval) — finder must NOT fire; value is the legacy same-interval
   value; no `pknca_message_secondary_ref_created`.
10. Ratio params without `group_ref` never trigger the finder: `ratio.cmax`
    requested without a pointer aborts `pknca_error_secondary_needs_ref`.
11. Multi-subject: two subjects with plasma+urine; both get correct values;
    one created reference row serves both instances.
12. `PKNCAdata(group_ref=)` validation: non-data.frame aborts
    `pknca_error_group_ref_invalid`; a column that is not a group column
    aborts the same; a typo'd value (`PCSPEC = "PLASMAA"`) aborts
    `pknca_error_group_ref_value`.
13. `interval_add_secondary(iv, param = "clr.last", reference = NULL)` on a
    data.frame materializes the same rows/pointers the engine derives
    (compare data.frames); on a PKNCAdata with `group_ref` set, uses it.

### 5.8 PR 3 documentation

NEWS bullets ("Requesting renal clearance now derives and creates the plasma
reference interval automatically when it is unambiguous"; "`PKNCAdata()`
gains `group_ref` to steer automatic reference selection"); document the
finder's rules in the `interval_add_secondary()` and `PKNCAdata()` roxygen.

---

## 6. PR 4 — unit reconciliation and documentation

### 6.1 Unit reconciliation (decision 8)

Principle: a secondary result keeps its registered unit type and continues to
receive `PPORRESU` from the standard units-table join on the **home** group.
For that assigned unit string to be *correct*, every reference-side input
value must first be expressed in the units the home group's units table
implies for that source parameter.  (Modeled on aNCA's convert-or-flag
behavior in `calculate_ratios()`, done at calculation time instead of
post-hoc.)

Implementation, at the marked insertion point in `pk_nca_secondary()`
(§3.11), active only when `data_calc$units` is a data.frame:

1. For each ref-marked input: find the units-table `PPORRESU` for the source
   parameter under the **reference** group (`u_ref`) and under the **home**
   group (`u_home`).  The units table's group columns are a (possibly
   minimal) subset of the result group columns — match with `%in%` on the
   columns the units table actually has; a table without group columns means
   uniform units (`u_ref == u_home`, nothing to do — make this the fast
   path).
2. `u_ref == u_home` (or either is `NA`): no change.
3. Otherwise compute `factor <- pknca_unit_reconcile_factor(u_ref, u_home)`
   (new internal in `R/unit-support.R`): returns the multiplicative factor
   that converts a value in `u_ref` into `u_home`, or `NA_real_` when the
   units are not convertible or the `units` package is unavailable.
   Implement it by reusing the conversion-factor machinery that
   `pknca_units_table(..., conversions=)` already uses (search
   `R/unit-support.R` for where `units::set_units()` is called and factor it
   out rather than re-implementing; wrap in
   `requireNamespace("units", quietly = TRUE)`).
4. Finite factor: multiply the reference-side input value by it before the
   calculation.  Record nothing extra — `PPANMETH` already names the
   reference interval, and the assigned home-group units are now correct.
5. `NA` factor (not convertible): per the fail-loud rule, the result must
   not be a number with wrong implied units.  Set the instance's result to
   `NA_real_` with `exclude` reason
   `sprintf("Units of '%s' differ between the reference ('%s') and home ('%s') groups and are not convertible", target, u_ref, u_home)`,
   and emit one `pknca_warning_secondary_units` per (parameter, unit pair)
   per run.  This applies to explicit and automatic links alike (it is a
   data/units gap, not a specification error).

Remove the interim PR 1 mismatch-only warning (§3.11 last paragraph) when
this lands — reconciliation supersedes it, and
`pknca_warning_secondary_units` keeps its class with the narrowed
(non-convertible-only) meaning.

Tests (extend `test-secondary-parameters.R`):

1. Convertible stratified units: the §3.14 fixture with per-group units —
   plasma `concu = "ng/mL"`, urine `concu = "mg/L"`, both `timeu = "hr"`,
   urine `amountu = "mg"` (unit columns on the conc data so
   `pknca_units_table()` stratifies).  1 ng/mL = 0.001 mg/L, so the plasma
   `auclast` (144 hr*ng/mL) reconciles to `144*0.001` hr*mg/L and
   `clr.last == 350/(144*0.001)` exactly, with `PPORRESU ==
   "mg/(hr*mg/L)"`.
2. Uniform units: values and units identical to the PR 1 run (fast path — no
   behavior change; compare full result data.frames).
3. Non-convertible: urine `concu = "mg/L"`, plasma `concu = "IU/mL"` (no
   conversion defined): `clr.last` is `NA`, `exclude` matches
   `"not convertible"`, warning class `pknca_warning_secondary_units`.
4. `pknca_unit_reconcile_factor()` unit tests: `("ng/mL", "mg/L") == 0.001`;
   identical units give 1; non-convertible gives `NA`; behaves when the
   `units` package is missing (mock or skip-if-installed pattern used
   elsewhere in the suite).

### 6.2 Documentation

1. New vignette `vignettes/v22-secondary-parameters.Rmd` (check the existing
   numbering scheme with `ls vignettes/` and pick the first free number in
   the intervals-related range; do not renumber existing vignettes).
   Sections: what a secondary parameter is; the hero table (hand
   specification); renal clearance start-to-finish (reuse the §3.14 fixture);
   the automatic path (urine-only request; `group_ref` steering with the
   midazolam example); `interval_add_secondary()` and the wrappers
   (accumulation ratio, metabolite ratio); bioavailability and its basis
   variants; how exclusions propagate (show the excluded-AUC example and the
   `exclude` column); unit reconciliation (the stratified-units example);
   reporting (`PPANMETH`, `summary()`, `filter_requested`); limitations
   (sparse; §8 to-dos).
2. `vignettes/v80-writing-parameter-functions.Rmd`: a new section "Parameters
   that need another interval" documenting `pknca_ref()`, the requirement
   that every formal be covered by `formalsmap`, home arguments listed in
   `depends`, and how exclusions carry (pointing at
   `combine_exclude_reasons()`'s behavior).
3. `_pkgdown.yml` currently lists no vignettes or reference index — verify
   this is still true and change nothing if so.
4. `spelling::spell_check_package()`; update `inst/WORDLIST`.
5. NEWS: unit-reconciliation and vignette bullets.
6. Post the Appendix A text as a comment on issue 76 (maintainer action —
   the `gh` credential in this environment is read-only).

---

## 7. Definition of done (every PR)

* `devtools::document()` run; `man/` and `NAMESPACE` staged with the change.
* `devtools::test()` fully green; new behavior covered by tests named after
  this plan's numbered lists.
* `devtools::check()` clean (no new errors/warnings/notes).
* `spelling::spell_check_package()` clean or `inst/WORDLIST` updated.
* `NEWS.md` updated for user-facing changes.
* No `#<number>` or `!<number>` in any commit message (write "issue 76");
  commits end with the Claude co-author trailer per repository convention.
* No restyling of untouched code; new code follows the file's local style
  (registrations keep the aligned `argument=value` style of their file).

## 8. To-do list (deferred, in priority order)

Kept here so nothing is lost; each becomes a GitHub issue when its turn
comes.  (Aggregated/across-subject references are deliberately **not** on
this list — decision 10.)

1. **Sparse-data secondary parameters** (release blocker) — lift
   `pknca_error_secondary_sparse_unsupported` (decision 9).  Maintainer
   decision on the pull-request review: this must be supported before the
   release that ships secondary-parameter calculations.
2. **Route-based reference finder for absolute bioavailability** —
   extravascular home, intravascular reference, derivable from `PKNCAdose`'s
   route; relative bioavailability stays explicit/`group_ref`-driven, since
   which formulation is the reference is not derivable from data.
3. **Context-aware CDISC codes for ratios** — emit `RA*`/`MR*`-style
   PPTESTCD by which columns differ between home and reference (aNCA's
   `RA<param>` naming is prior art); refine FAB/FREL for the `f.*` family.
4. **Post-hoc cross-group exclusion propagation** — `exclude()`/
   `exclude_nca_*()` on a finished `PKNCAresults` cannot reach across groups;
   includes teaching the forward `get.parameter.deps()` search to see
   `formalsmap` references.
5. **Preset integration** — `pknca_interval_table()`/`pknca_presets()`
   emitting linked rows directly (largely subsumed by the finder plus
   `group_ref`; revisit after PR 3 experience).
6. **Molecular-weight-adjusted metabolite ratios** — molar conversion in the
   units layer (`mw_reference`/`mw_test` style), explicitly not an
   `adj_factor` on the secondary calculation.

---

## Appendix A — text to post on issue 76 (unit reconciliation)

**Unit handling for secondary parameters** (recording this here so it is not
lost): when a secondary parameter combines values from two different
profiles, the two sides can carry different units — for example, renal
clearance divides a urine amount in mg by a plasma AUC in hr\*ng/mL, and a
metabolite ratio can compare analytes reported in different concentration
units.  The cross-interval implementation
(`design/secondary-parameters-plan.md`) handles this as follows, as the final
step of the work:

- Secondary results keep their registered unit types (`renal_clearance` =
  amount/(time×conc), `fraction` for ratios and bioavailability), and units
  continue to be assigned by the standard units-table join on the reporting
  (home) interval's group.
- Before a secondary value is computed, every reference-side input value is
  converted into the units the *home* group's units table implies for that
  source parameter (e.g., a plasma AUC in hr\*ng/mL is converted to hr\*mg/L
  when the urine group's concentration unit is mg/L), using the `units`
  package.  After that conversion, the home group's assigned unit string is
  correct as-is.
- When the two unit strings are not convertible (or the `units` package is
  unavailable), the result is NA with an explanatory `exclude` reason and a
  `pknca_warning_secondary_units` warning, rather than a number whose implied
  units are wrong.
- Molecular-weight adjustment for metabolite ratios remains a units-layer
  feature (molar conversion), not part of the secondary-parameter linkage;
  `adj_factor`-style multipliers are deliberately not part of the interface.

## Appendix B — guardrails and known traps

* **Do not** store `data_calc` in the returned `PKNCAresults`; ephemerality
  (decision 2) depends on storing the user's `data`.
* **Do not** resolve a ref-marked argument from the interval column named by
  the *target* (`interval[["auclast"]]` is the logical request flag — the
  historical silent-`Inf` bug).  Only the formal-named column
  (`interval[["auc"]]`, `interval[["dose1"]]`) is a legacy value channel.
* `%in%` (not `==`) for all group-value matching so `NA` group values match
  literally, mirroring the join semantics of `full_join_PKNCAdata()`.
* `results$start`/`end` comparisons may involve `Inf`; `%in%` handles it.
* The auto ledger rides as `data_calc$secondary_auto`, a plain list element
  of the working-copy PKNCAdata — never as an attribute on the intervals,
  which subsetting or joins could silently strip.
* Adding source parameters to reference intervals is **silent** everywhere
  (decision 4); only interval creation/linking is announced.
* The registry is global state: any test that registers a parameter must
  snapshot `get("interval.cols", envir = PKNCA:::.PKNCAEnv)` before and
  `assign` it back (the caches self-invalidate).  Prefer testing through
  `f`/`clr`/`ratio.*` instead of dynamic registration.
* Tests that set `PKNCA.options()` must save and restore the previous values
  (existing suite has the pattern).
* `interval_longer()`/`interval_wider()` treat `interval_id` and pointer
  columns as key columns automatically — no change there; do not add them to
  `interval_param_cols()`.
* Registration order: `pknca_ref` targets and `depends` may be forward
  references (validated lazily); the calculation *function* must exist at
  registration time, so `pk.calc.ratio()` must be defined above the
  `ratio.*` registrations in the same file.
* `R/secondary-parameters.R` sorts alphabetically after `R/pk.calc.*.R` and
  before `R/zzz-pk.calc.dn.R`; the dose-normalized machinery in the `zzz`
  file must not be touched (no `.dn` variants for `ratio.*` or `f.*`).
