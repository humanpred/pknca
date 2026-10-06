# PKNCA Best Practices Review

## Documentation

### Roxygen2 Coverage
- **Status: Good.** Nearly all exported functions have `@param`, `@returns`, and `@examples` tags.
- Markdown rendering is enabled (`Roxygen: list(markdown = TRUE)` in DESCRIPTION).
- `@family` tags are used consistently to group related functions in documentation.
- `@seealso` links are used where appropriate.

### Vignettes
- 18 vignettes cover the full range of use cases from basic through advanced.
- Coverage includes: basic usage, AUC calculation, BLQ handling, units, superposition, sparse PK, exclusions, steady state.
- The vignette set is comprehensive and well-maintained.

### NEWS.md
- Maintained in a structured, user-facing format.
- Tracks API changes, deprecations, and bug fixes.
- Could benefit from more explicit "migration guide" sections when deprecated interfaces are removed.

### Internal Functions
- Some internal helper functions lack sufficient inline comments, making their purpose non-obvious:
  - `getColumnValueOrNot()` (`class-general.R:41`) — the name doesn't convey its behavior clearly
  - `full_join_PKNCAconc_PKNCAdose()` (`prepare_data.R`) — complex joining logic with minimal documentation
  - `element_find()` (`assertions.R`) — purpose is not obvious from name

---

## NAMESPACE Hygiene

- **Status: Good.** The `NAMESPACE` is fully managed by roxygen2.
- All `@importFrom` tags exist because of S3 generic registration and re-export requirements, not convenience — they are all necessary.
  - dplyr verbs (`filter`, `group_by`, etc.) are imported because PKNCA defines S3 methods and re-exports them for user convenience.
  - `nlme::getGroups` is imported and re-exported for the same reason.
  - `stats::formula` and `stats::model.frame` are imported as generics for which PKNCA defines S3 methods.
  - `lifecycle::deprecated` must be imported to function correctly as a default argument value at call time.
  - `rlang::.data` is used 83 times throughout the package.
- No blanket `import()` calls — all imports are selective.
- `utils::globalVariables()` is used to declare legitimate global variable references in tidy eval contexts.

---

## Error Handling

### Patterns Used
- `stop()` for invalid inputs and logic errors
- `warning()` for recoverable issues
- `rlang::warn()` with custom condition classes for categorized, suppressible warnings
- `structure(NA_real_, exclude = "reason")` for graceful degradation — calculation functions return NA with an attached exclusion reason rather than throwing errors for expected data quality issues

### Quality
- **Good:** Error messages are generally informative and actionable.
- **Good:** Warning classes are used (e.g., `pknca_warn_*`) so users can suppress specific warnings with `suppressWarnings()` or `withCallingHandlers()`.
- **Concern:** Some internal `stop()` calls for "should never happen" logic paths use `# nocov` without clear comments explaining what invariant would need to break for them to fire. This is acceptable but worth documenting.

---

## Input Validation

- **File:** `R/assertions.R` (295 lines)
- Heavy use of `checkmate` package for structured validation.
- Dedicated assertion functions:
  - `assert_conc_time()` — validates concentration-time pairs together
  - `assert_conc()` — validates concentrations with appropriate rlang warnings
  - `assert_time()` — validates time values
  - `assert_numeric_between()` — range checks with strict/non-strict inequality options
  - `assert_aucmethod()` — validates integration method string
  - `assert_lambdaz()` — validates terminal slope values
  - `assert_dosetau()` — validates dosing interval

- **Good pattern:** Most calculation functions accept a `check = TRUE` parameter that can be set to `FALSE` when calling internally, avoiding redundant validation overhead in the calculation pipeline.
- **Good pattern:** Most functions accept an `options = list()` parameter for settings injection, enabling testable code without needing to change global state.

---

## Dependencies

### Direct Imports

| Package | Version | Usage |
|---------|---------|-------|
| `checkmate` | any | Input validation throughout |
| `dplyr` | ≥1.1.0 | Data manipulation, S3 generics |
| `digest` | any | Provenance hash computation |
| `nlme` | any | `getGroups` generic (re-exported) |
| `purrr` | any | `pmap()` in `pk.calc.all.R` |
| `rlang` | any | Tidy eval, condition handling |
| `stats` | (base) | `formula`, `model.frame`, `lm`, etc. |
| `tidyr` | any | `pivot_longer` / `pivot_wider` |
| `tibble` | any | `tibble` class for outputs |
| `utils` | (base) | `globalVariables()` |
| `lifecycle` | any | Deprecation management |

### Suggested (Optional) Imports

| Package | Usage |
|---------|-------|
| `units` | Automatic unit conversion |
| `knitr`, `rmarkdown` | Vignette building |
| `testthat` | Testing |
| `ggplot2`, `cowplot` | Vignette figures |

### Assessment
- **Good:** Dependency count is moderate and all packages are actively maintained.
- **Good:** `units` is optional, so the package does not force users to install it.
- **Note:** `purrr` is used only for `pmap()` in `pk.calc.all.R`; this could be replaced with base R `Map()` to reduce one dependency, though purrr is already a transitive dependency of dplyr in most environments.
- **Note:** `tidyr` is used for reshaping in summary; could potentially be replaced with base R `reshape()` to reduce dependencies, but tidyr is also already a common transitive dependency.
- **Note:** `nlme` is a required dependency purely to register an S3 method for `getGroups`. The `nlme` package is large. If future versions reduce reliance on nlme-style grouping, this dependency could be removed.

---

## Test Coverage

### Infrastructure
- **Framework:** testthat ≥ 3.0.0
- **Coverage tracking:** codecov integration via GitHub Actions
- **Test helper:** `tests/testthat/helper-generate_data.R` provides `generate.conc()` and `generate.dose()` for consistent test data

### Coverage by Area

| Area | Test File | Assessment |
|------|-----------|------------|
| PKNCAconc class | `test-class-PKNCAconc.R` (631 lines) | Comprehensive |
| PKNCAdose class | `test-class-PKNCAdose.R` (581 lines) | Comprehensive |
| PKNCAdata class | `test-class-PKNCAdata.R` | Good |
| AUC calculation | `test-auc.R` (730 lines) | Comprehensive |
| Half-life | `test-half.life.R` | Good |
| Interpolation | `test-interpolate.conc.R` (1,061 lines) | Comprehensive |
| Parameter calculation | `test-pk.calc.all.R` (800 lines) | Good |
| Simple parameters | `test-pk.calc.simple.R` (528 lines) | Good |
| Options | `test-PKNCA.options.R` (471 lines) | Good |
| Unit support | `test-unit-support.R` (508 lines) | Good |
| Steady state | `test-time.to.steady.state.R` (758 lines) | Comprehensive |
| Provenance | `test-provenance.R` | Adequate |
| Exclusions | `test-exclude.R` | Good |

### Known Coverage Gaps

- **`# nocov` usage:** Approximately 70 statements are marked `# nocov` across the codebase. Most are legitimately hard-to-reach paths (e.g., "should never happen" guards). The largest concentrations are:
  - `R/interpolate.conc.R`: 20 statements — complex edge cases at the intersection of extrapolation methods and data quality
  - `R/class-summary_PKNCAresults.R`: 8 statements
- **No performance/benchmarking tests:** There are no stress tests with large datasets (e.g., 1000-subject studies). Performance regressions would not be caught by the current test suite.
- **No full pipeline integration tests:** Most tests are unit tests for individual functions. End-to-end tests from raw data to formatted summary table are limited to the vignettes (which are not run as part of `R CMD check` by default unless `NOT_CRAN` is set).

### Test Quality Observations
- **Good:** Warning classes are tested explicitly with `expect_warning(..., class = "pknca_warn_*")`.
- **Good:** Tests use `ignore_attr = TRUE/FALSE` deliberately on `expect_equal()`.
- **Good:** Edge cases (empty data, all-NA, all-BLQ) are tested for most calculation functions.
- **Good:** Cross-validation against reference software (Phoenix WinNonlin, Pumas) is mentioned in documentation.

---

## Coding Style

- **Indentation:** 2 spaces (standard R style) — consistent throughout
- **Line length:** Generally ≤ 100 characters
- **Naming:** Transitioning from dot-separated (`out.format`) to underscore-separated (`out_format`) names — see [05-future-work.md](05-future-work.md)
- **`::` notation:** Used consistently for package-qualified calls where functions are not imported; all `@importFrom` tags have legitimate reasons
- **No use of `T`/`F`:** `TRUE`/`FALSE` used throughout — good practice
- **`|` vs `||`:** Occasional use of `|` where `||` would be more idiomatic in scalar contexts (not a bug but a style concern); see [06-potential-bugs.md](06-potential-bugs.md)
