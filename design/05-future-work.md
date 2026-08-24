# PKNCA Future Work & Design Decisions

This document covers design decisions that could be improved, deprecation candidates, and suggestions for future versions. Items marked **[BREAKING]** would require a breaking change and should be deferred to v1.0 or communicated well in advance.

---

## Ongoing: Dot-to-Underscore Naming Transition

**Status:** In progress, target completion at v1.0.

The package is transitioning all public API parameter names from `dot.separated` to `under_score` style. Deprecation warnings are already in place for:

| Old Name | New Name | Location |
|----------|----------|----------|
| `out.format` | `out_format` | `as.data.frame.PKNCAresults()` |
| `drop.group` | `drop_group` | `summary.PKNCAresults()` |
| `not.requested.string` | `not_requested` | `summary.PKNCAresults()` |
| `not.calculated.string` | `not_calculated` | `summary.PKNCAresults()` |

**Remaining work:**
- PKNCA option names (`adj.r.squared.factor`, `allow.tmax.in.half.life`, `min.hl.points`, etc.) are not yet transitioned. These will require `PKNCA.options()` to support both old and new names with deprecation warnings before removing the old names.
- Exported utility functions that use dot notation in their argument names (e.g., `assert_conc_time()`, `add.interval.col()`) should be audited and transitioned.

**Recommendation:** Complete the remaining option name transitions before v1.0, adding `lifecycle::deprecated()` defaults for old names.

---

## [BREAKING] Rename `add.interval.col()` and Related Registration Functions

`add.interval.col()`, `get.interval.cols()`, `PKNCA.options()`, `PKNCA.choose.option()`, and `PKNCA.options.describe()` all use dot-separated names that are inconsistent with the modern underscore convention.

**Suggested new names:**
- `add.interval.col()` → `pknca_add_parameter()`
- `get.interval.cols()` → `pknca_get_parameters()`
- `PKNCA.options()` → `pknca_options()`
- `PKNCA.choose.option()` → `pknca_choose_option()`
- `PKNCA.options.describe()` → `pknca_options_describe()`

This would be a breaking change and requires a deprecation cycle (old names kept as wrappers with warnings before eventual removal).

---

## [BREAKING] Formalize the Exclusion Reason Structure

Currently, exclusion reasons are accumulated as semicolon-delimited strings in a single column (e.g., `"Reason 1; Reason 2"`). This is human-readable but machine-unfriendly — filtering or counting by specific exclusion reason requires string parsing.

**Suggested future design:** Store exclusion reasons as a list-column of character vectors, or use a separate long-format exclusions table. This would make programmatic analysis of exclusion patterns much easier.

This is a significant structural change to `PKNCAresults` and would break any code that parses the exclusion column as a string.

---

## [BREAKING] Reconsider `PKNCAconc` Sparse PK Representation

Sparse PK data is currently stored in a separate `data_sparse` slot alongside the standard `data` slot in `PKNCAconc`. This creates two code paths throughout the package and adds complexity to every function that accesses concentration data.

**Suggested future design:** Unify sparse and dense data under a single storage format, using a column or attribute to mark data as sparse. This would simplify the class internals and reduce code duplication.

---

## [NON-BREAKING] Better Documentation of the Parameter Registration System

The `formalsmap` mechanism and dependency injection pattern in `add.interval.col()` are powerful but underdocumented. Consider adding:

- A vignette titled "Extending PKNCA: registering custom NCA parameters" with worked examples
- A concrete flowchart showing how `pk.nca()` uses `depends` and `formalsmap` to orchestrate calculations
- More inline comments in `R/001-add.interval.col.R` explaining the algorithm

---

## [NON-BREAKING] Cache the Dependency-Sorted Parameter List

`get.interval.cols()` performs topological sorting every time it is called. Since parameters are only registered at package load time (via `add.interval.col()`), the sorted list could be cached in `.PKNCAEnv` after the first call and invalidated only when a new parameter is registered.

This is a safe, low-risk optimization that would slightly improve startup performance and repeated calls.

---

## [NON-BREAKING] Pre-Compute Unit Conversion Factors

Unit conversion factors are computed at result-display time. For the case where the `units` package is used to compute conversion factors (calling `units::set_units()` per unique unit pair), these could be pre-computed at `PKNCAdata` creation time and stored in the unit table.

**Benefit:** Faster result display, especially for large result sets with many unique unit combinations.

---

## [NON-BREAKING] Split Large Source Files

The following files could be split for easier navigation without any change to the public API:

| Current File | Suggested Split |
|-------------|-----------------|
| `R/pk.calc.simple.R` (1,465 lines) | Split by category: concentration parameters, time parameters, clearance/volume, etc. |
| `R/class-summary_PKNCAresults.R` (602 lines) | Separate formatting logic from statistical aggregation |
| `R/PKNCA.options.R` (606 lines) | Separate option validation from storage and retrieval |
| `R/unit-support.R` (688 lines) | Separate unit table construction from unit conversion application |

---

## [NON-BREAKING] Clarify Half-Life Selection Side Effects

In `R/half.life.R` lines 225–241, a warning is emitted as a side effect of constructing a logical mask. Refactor to separate the warning emission from the mask construction for clearer code:

```r
# Current (warning mixed with mask construction):
mask_best <- condition1 & if (edge_case) { warn(...); TRUE } else { condition2 }

# Suggested (separate warning from logic):
if (edge_case) rlang::warn(...)
mask_best <- condition1 & if (edge_case) TRUE else condition2
```

---

## [NON-BREAKING] Add Optional Parallel Execution

For large studies (hundreds to thousands of subjects), the per-subject calculation loop in `pk.nca()` could benefit from optional parallelization. A natural integration point would be to use the `future` package with a PKNCA option to enable it:

```r
PKNCA.options(use_parallel = TRUE)
```

This would allow users with large datasets to take advantage of multi-core systems without changing the API.

---

## [NON-BREAKING] Improve Integration Test Coverage

The current test suite is comprehensive at the unit level but has limited end-to-end integration tests. Consider adding:

- A standard test dataset (published PK data) with known NCA results for cross-validation
- Regression tests that run the full pipeline from `PKNCAconc`/`PKNCAdose` through `summary()` and compare against reference values
- Performance tests that verify calculation time stays below a threshold for a representative large dataset

---

## [NON-BREAKING] Reduce `nlme` Dependency

`nlme` is imported solely for the `getGroups` generic. It is a large package. If future versions redesign the grouping interface (e.g., replacing `getGroups` with a PKNCA-native generic), this dependency could be removed.

---

## [NON-BREAKING] Vectorize Interpolation Inner Loop

The interpolation function in `R/interpolate.conc.R` processes one output time point at a time. For superposition calculations that request many time points, a vectorized implementation using `findInterval()` could provide meaningful speedups.

This would require careful handling of the method-dispatch logic (which interval method applies to each pair of time points) but is mathematically straightforward.

---

## Summary Table

| Item | Breaking? | Priority |
|------|-----------|----------|
| Complete dot→underscore transition for option names | Yes (eventually) | High |
| Rename `add.interval.col()` etc. | Yes | Medium |
| Formalize exclusion reason structure | Yes | Low |
| Unify sparse/dense PK storage | Yes | Low |
| Document parameter registration system | No | High |
| Cache dependency-sorted parameter list | No | Low |
| Pre-compute unit conversion factors | No | Low |
| Split large source files | No | Medium |
| Clarify half-life selection side effects | No | Low |
| Add optional parallel execution | No | Low |
| Improve integration test coverage | No | High |
| Reduce nlme dependency | No | Low |
| Vectorize interpolation inner loop | No | Low |
