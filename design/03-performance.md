# PKNCA Performance Review

## Summary

PKNCA's performance is adequate for typical clinical study sizes (dozens to low hundreds of subjects). No critical performance bottlenecks have been identified for standard use. However, several areas may become problematic for very large datasets (thousands of subjects, sparse PK studies with many samples) or for users running repeated analyses (e.g., bootstrap/simulation workflows).

---

## Identified Concerns

### 1. Per-Subject Calculation Loop (`R/pk.calc.all.R`)

**Concern:** `pk.nca()` processes data in groups (one subject × interval at a time) using a grouped dplyr pipeline. For each group, it calls the full calculation pipeline and collects results. This is inherently sequential and cannot easily be parallelized with the current architecture.

**Impact:** For a study with 1,000 subjects × 10 intervals × 70 parameters, this means ~700,000 individual calculations dispatched through the same pipeline.

**Suggestion:** No immediate action required. If performance becomes a concern, consider:
- Adding optional parallel execution via `future` or `parallel` packages, controlled by a PKNCA option
- Profiling with a representative large dataset before optimizing

---

### 2. Interpolation Function (R/interpolate.conc.R, ~733 lines)

**Concern:** `interpolate.conc()` has a time-point-by-time-point dispatch loop. For each requested output time, it must:
1. Find the bracketing time points in the input data
2. Determine the appropriate interpolation method
3. Call the correct low-level function

When called with a large `time.out` vector, this is O(n × m) where n = length(time.out) and m = length(data).

**Impact:** Moderate. Typical NCA use involves small time vectors per subject. However, superposition (`R/superposition.R`) generates many requested time points and calls interpolation repeatedly.

**Suggestion:** The inner loop could be vectorized using `findInterval()` or `approx()`-style logic. This would require significant refactoring but could yield meaningful speedups for superposition calculations.

---

### 3. Data Copying in dplyr Pipeline

**Concern:** The dplyr-based calculation pipeline in `pk.calc.all.R` and `prepare_data.R` creates multiple intermediate data frames. Each `mutate()`, `filter()`, and `full_join()` creates a copy of (portions of) the data.

**Impact:** For large datasets with many columns, this increases memory allocation and GC pressure. For typical NCA data sizes this is unlikely to be noticeable.

**Suggestion:** No immediate action needed. If memory is a concern for very large studies, consider using `data.table` as an alternative backend (a substantial undertaking, likely not worth it without profiling data showing it matters).

---

### 4. Parameter Dependency Graph Recomputed Per Call

**Concern:** `get.interval.cols()` performs dependency sorting each time it is called. In `pk.nca()`, this is called once per run, so the impact is minimal. However, if `get.interval.cols()` is ever called inside a per-subject loop, this would add repeated overhead.

**Current status:** The call appears to be outside the per-subject loop, so this is not currently a problem.

**Suggestion:** Cache the sorted parameter list in `.PKNCAEnv` after the first computation and invalidate only when `add.interval.col()` is called (which only happens at package load time). This is a low-risk optimization.

---

### 5. `purrr::pmap()` in pk.calc.all.R

**Concern:** `purrr::pmap()` is used to apply calculations across rows of the interval specification. This is idiomatic and readable, but carries some overhead compared to a direct `for` loop for small iteration counts.

**Impact:** Negligible for typical use.

**Suggestion:** No change needed.

---

### 6. Sparse PK Memory Duplication

**Concern:** `PKNCAconc` objects that hold sparse PK data store the data in `object$data_sparse` (a data frame with a list-column of per-subject data frames) in addition to the standard `object$data` slot. This adds memory overhead proportional to data size.

**Impact:** Moderate for large sparse PK datasets with many subjects and time points.

**Suggestion:** Consider whether the sparse and dense representations could share a single storage format. This would be a significant refactoring effort and would likely require a breaking change to the internal structure.

---

### 7. Unit Conversion in Large Result Sets

**Concern:** Unit conversion in `R/unit-support.R` operates on the full results data frame. For large result sets, this involves iterating over each unique `PPORRESU` value and applying a conversion factor or calling `units::set_units()`.

**Impact:** `units::set_units()` calls are relatively slow. If many unique unit combinations are present, this could be noticeable.

**Suggestion:** Pre-compute all conversion factors once (at `PKNCAdata` creation or before running `pk.nca()`) so that the per-result unit conversion is a simple numeric multiplication rather than a `units` package call.

---

## Memory

- No memory leaks identified.
- The package creates moderately sized intermediate objects but releases them promptly via normal R garbage collection.
- For very large studies, the long-format `PKNCAresults` data frame (one row per subject × interval × parameter) can become large. For 1,000 subjects × 10 intervals × 70 parameters, this is 700,000 rows, which is easily manageable in modern R.

---

## Recommendations

| Priority | Recommendation |
|----------|---------------|
| Low | Cache dependency-sorted parameter list in `.PKNCAEnv` |
| Low | Pre-compute unit conversion factors at `PKNCAdata` creation |
| Medium | Profile superposition calculations and consider vectorizing interpolation loop |
| Low | Consider optional parallelism via `future` for per-subject calculations |
