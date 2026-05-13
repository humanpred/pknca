# PKNCA Code Clarity Review

## Summary

PKNCA is generally well-organized and its code reflects deep domain knowledge. The main clarity challenges stem from the complexity of NCA itself (many edge cases, many BLQ/NA scenarios), the ongoing naming convention transition (dots → underscores), and some large files that bundle many functions together.

---

## Confusing or Unclear Sections

### 1. Interpolation/Extrapolation Dispatch (`R/interpolate.conc.R`, 733 lines)

This is the most complex single file in the package. Key sources of confusion:

- **Multiple deprecated parameters** (`interp.method`, `extrap.method`) are handled via `.Defunct()` calls near the top of the function. A reader must understand that these code paths always error before understanding the current interface.
- **Three different extrapolation modes** (AUCinf, AUCall, AUClast) interact with interpolation method choice in non-obvious ways. The conditions under which "log" vs "linear" vs "zero" interpolation is used require careful reading.
- **`tlast` boundary handling** is subtle: time points between `tlast` and the last observation get "zero" interpolation, but the point at `tlast` itself depends on `auc.type`.
- The file would benefit from a multi-paragraph header comment explaining the overall decision tree before the function definitions begin.

---

### 2. Half-Life Selection Logic (`R/half.life.R`, lines 225–255)

The selection of the "best" terminal slope fit involves an embedded `if()` inside a `&` expression:

```r
mask_best <-
  half_lives_for_selection$lambda.z > 0 &
  if (min.hl.points == 2 & nrow(half_lives_for_selection) == 2) {
    rlang::warn(...)
    TRUE
  } else {
    half_lives_for_selection$adj.r.squared >
      (max(half_lives_for_selection$adj.r.squared, na.rm=TRUE) - adj.r.squared.factor)
  }
```

This pattern — embedding an `if()` expression that has a side effect (the `rlang::warn()` call) inside a logical mask construction — is non-idiomatic and hard to follow. The warning is emitted as a side effect of building a logical mask. Consider separating the warning from the mask construction.

---

### 3. `exclude()` FUN Parameter (`R/exclude.R`, lines 39–75)

The `exclude()` function's `FUN` argument mechanism uses dynamically-named temporary columns (`exclude_current_group_XXX`, `row_number_XXX` where `XXX` is based on the current time) to pass per-group information to user-supplied functions. This avoids scope issues in dplyr grouped operations but is very non-obvious. The comment explaining why this approach is used is minimal.

A more explicit approach using `dplyr::group_modify()` (introduced in dplyr 1.0.0) might be clearer while achieving the same result.

---

### 4. BLQ Handling Configuration (`R/PKNCA.options.R`, `R/cleaners.R`)

The BLQ handling option is a nested list with keys `first`, `middle`, `last`, `before.tmax`, `after.tmax`. The interaction between these keys and when each applies is not immediately obvious. The option validation code is comprehensive, but the mental model requires reading both `cleaners.R` and `PKNCA.options.R` together.

A dedicated vignette section or worked example showing exactly which rules apply in which order for a given concentration profile would help users considerably.

---

### 5. `formalsmap` in Parameter Registration (`R/001-add.interval.col.R`)

The `formalsmap` mechanism is powerful but requires careful reading to understand. It maps formal argument names of a calculation function to the names of previously-calculated parameters. For example:

```r
add.interval.col(
  name = "aucinf.obs",
  FUN = pk.calc.aucinf.obs,
  formalsmap = list(clast.obs = "clast.obs", lambda.z = "lambda.z"),
  depends = c("clast.obs", "lambda.z")
)
```

The `formalsmap` tells the engine: "when calling `pk.calc.aucinf.obs()`, pass the result of `clast.obs` as the argument named `clast.obs` and the result of `lambda.z` as the argument named `lambda.z`."

The documentation for `add.interval.col()` describes this, but a concrete worked example showing a full chain (e.g., `clast.obs` → `lambda.z` → `aucinf.obs`) would help maintainers.

---

### 6. Summary Pipeline (`R/class-summary_PKNCAresults.R`, lines 105–178)

The multi-step summary preparation creates several intermediate data frames with similar names (`result_groups`, `result_n`, `group_cols`). The steps are:

1. Determine grouping columns
2. Count subjects per group
3. Apply per-parameter summary functions
4. Pivot to wide format
5. Format numeric values
6. Apply column renaming

Each step is correct but the variable names at each stage are not clearly differentiated. A reader must track state through ~70 lines of pipeline code. Adding section comments marking each step would improve readability significantly.

---

## Naming Inconsistencies

### Dots vs Underscores

The package is mid-transition from `dot.separated.names` to `under_score_names`. This affects:

- Public API parameter names: `out.format` (deprecated) → `out_format`; `drop.group` → `drop_group`; `not.requested.string` → `not_requested`; `not.calculated.string` → `not_calculated`
- Internal function names: most new code uses underscores; most old code uses dots
- Option names: currently still using dots (`adj.r.squared.factor`, `allow.tmax.in.half.life`) — these will need to be addressed for v1.0

Users reading source code alongside documentation may be confused by this inconsistency until v1.0 completes the transition.

### Abbreviated vs Full Names

No single convention is applied consistently:

- `conc` used in some places, `concentration` in others
- `hl` used for half-life in internal code, `half.life` in parameter names
- `tmax` vs `time.to.max` (the latter is the registered parameter name)
- `dose` vs `dosing` in various contexts

For maintainers this is manageable, but it occasionally makes `grep`-style searches require multiple patterns.

### `getColumnValueOrNot()`

This function name (`R/class-general.R:41`) does not convey what "or not" means. The function retrieves a column value if the column exists, or returns a default value. A clearer name would be `get_column_or_default()` or similar. (Rename only appropriate as a future breaking change since it is exported.)

---

## Large Files

| File | Lines | Concern |
|------|-------|---------|
| `R/pk.calc.simple.R` | 1,465 | Contains ~40 individual parameter functions; could be split by category |
| `R/class-summary_PKNCAresults.R` | 602 | Mixes formatting, statistics, and output; could be split |
| `R/PKNCA.options.R` | 606 | Mixes option storage, validation, and description; could be split |
| `R/unit-support.R` | 688 | Mixes unit table construction, conversion, and column handling |

None of these represent bugs or design flaws — R packages commonly have large files — but splitting them would improve navigation and maintainability. Any split would be non-breaking (internal restructuring only).

---

## Missing Inline Comments

The following functions have non-obvious logic that would benefit from additional inline comments:

- `full_join_PKNCAconc_PKNCAdose()` (`R/prepare_data.R`) — the join logic and how mismatched groups are handled
- `choose_interval_method()` (`R/auc_integrate.R`, lines 77–151) — the decision tree for assigning "zero"/"linear"/"log"/"extrap_log" to each interval
- `pk.nca()` inner loop (`R/pk.calc.all.R`) — how parameter results are collected and error conditions propagated
- `clean.conc.blq()` all-BLQ branch (`R/cleaners.R`) — the `tlast = tfirst + 1` sentinel value and why it is used
