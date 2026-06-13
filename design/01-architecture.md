# PKNCA Architecture & Design Patterns

## Package Overview

PKNCA is an R package for non-compartmental analysis (NCA) of pharmacokinetic data. It provides a pipeline from raw concentration/dose data through calculation of NCA parameters to formatted results tables. The package is organized around four core S3 classes and a dynamic parameter registration system.

- **Version at audit:** 0.12.2
- **License:** AGPL-3
- **Total R source files:** 46 (~12,875 lines)
- **Test files:** 43 (~13,162 lines)
- **Vignettes:** 18

---

## Source File Organization

### Core Classes (S3 OOP)

| File | Lines | Purpose |
|------|-------|---------|
| `R/class-PKNCAconc.R` | 389 | Concentration-time data object |
| `R/class-PKNCAdose.R` | 337 | Dosing information object |
| `R/class-PKNCAdata.R` | 258 | Container combining conc + dose data |
| `R/class-PKNCAresults.R` | 143 | NCA calculation results object |
| `R/class-summary_PKNCAresults.R` | 602 | Summary formatting and statistics |
| `R/class-general.R` | 260 | Common utilities across classes |

### Calculation Engine

| File | Lines | Purpose |
|------|-------|---------|
| `R/pk.calc.simple.R` | 1,465 | Basic NCA parameters (Cmax, Tmax, Cmin, etc.) |
| `R/pk.calc.all.R` | 550 | Master calculation runner |
| `R/auc.R` | 385 | AUC and AUMC calculations |
| `R/aucint.R` | 358 | Interval AUC calculations |
| `R/half.life.R` | 552 | Half-life and terminal slope estimation |
| `R/interpolate.conc.R` | 733 | Concentration interpolation/extrapolation |
| `R/auc_integrate.R` | 121 | Low-level AUC integration primitives |
| `R/auciv.R` | 184 | IV-specific AUC calculations |
| `R/pk.calc.c0.R` | 141 | C0 calculation for IV dosing |
| `R/pk.calc.urine.R` | 336 | Urinary excretion parameters |

### Infrastructure

| File | Lines | Purpose |
|------|-------|---------|
| `R/001-add.interval.col.R` | 255 | Parameter registration system |
| `R/002-pk.business.rules.R` | 180 | Business rules for parameter calculation |
| `R/PKNCA.options.R` | 606 | Global options and settings |
| `R/PKNCA.R` | 44 | Package initialization |
| `R/zzz-pk.calc.dn.R` | 155 | Dose-normalized parameter variants |

### Data Quality

| File | Lines | Purpose |
|------|-------|---------|
| `R/unit-support.R` | 688 | Unit assignment and conversion |
| `R/cleaners.R` | 222 | BLQ/NA concentration cleaning |
| `R/exclude.R` | 220 | Data exclusion mechanism |
| `R/exclude_nca.R` | 237 | NCA-specific exclusion rules |
| `R/impute.R` | 144 | Imputation methods |
| `R/assertions.R` | 295 | Input validation functions |
| `R/check.intervals.R` | 217 | Interval specification validation |
| `R/prepare_data.R` | 350 | Data preparation and joining |

---

## Class Hierarchy

```
PKNCAconc  ─── concentration-time measurements
PKNCAdose  ─── dosing information
    │
    └── PKNCAdata ─── combined analysis dataset
            │         (holds intervals, options, units)
            │
            └── PKNCAresults ─── calculation output (long format)
                    │
                    └── summary.PKNCAresults ─── formatted summary table
```

### PKNCAconc

Stores concentration-time measurements for one or more subjects/analytes.

- Formula: `concentration ~ time | group1 + group2`
- Supports sparse and dense PK data (`data_sparse` vs `data` slots)
- Stores an exclusion column for data quality flags
- Unit handling integrated via `pknca_units_table()`
- S3 methods: `formula()`, `as.data.frame()`, `print()`, `summary()`, dplyr verbs, `getGroups()`, `group_vars()`

### PKNCAdose

Stores dosing information aligned with concentration data.

- Formula: `dose ~ time | group1 + group2`
- Handles dose amount, time, route (IV/extravascular), infusion duration/rate
- Unit handling integrated
- Shares most S3 method patterns with PKNCAconc

### PKNCAdata

Container that combines PKNCAconc and PKNCAdose objects.

- Automatically generates calculation intervals from dose times if not provided
- Stores global options, intervals data frame, and unit tables
- `PKNCAdata()` constructor validates column alignment between concentration and dose data
- `pknca_units_table.PKNCAdata()` builds the combined unit table

### PKNCAresults

Holds results of NCA calculations in long format.

- Each row is one (subject, interval, parameter) combination
- `PPTESTCD` column contains parameter names; `PPORRES` contains values
- `exclude` column records data quality exclusion reasons
- Methods: `as.data.frame()`, `summary()`, `print()`, dplyr verbs

---

## Parameter Registration System

**Files:** `R/001-add.interval.col.R`, `R/002-pk.business.rules.R`, `R/zzz-pk.calc.dn.R`

All NCA parameters are registered at package load time via `add.interval.col()`. This populates `.PKNCAEnv$interval.cols` with a named list where each entry describes one parameter.

### Registration Fields

Each registered parameter stores:

- `FUN`: the function that calculates it
- `values`: valid values for the interval specification (typically `TRUE`/`FALSE`)
- `unit_type`: what kind of unit applies (concentration, time, AUC, etc.)
- `pretty_name`: human-readable display name
- `desc`: description string
- `depends`: character vector of parameter names that must be calculated first
- `formalsmap`: named list mapping function arguments to previously-calculated parameter names

### `formalsmap` Mechanism

`formalsmap` allows parameter functions to receive results of previously calculated parameters as arguments, enabling a dependency injection pattern. For example, `aucinf.obs` depends on `clast.obs` and `lambda.z`, so its `formalsmap` maps those function arguments to those parameter results.

### Dependency Ordering

`get.interval.cols()` returns parameters sorted by their dependency graph using a topological-sort-like mechanism, ensuring parameters are always calculated in a valid order.

### Dose-Normalized Parameters

`R/zzz-pk.calc.dn.R` (loaded last due to `zzz` prefix) automatically registers dose-normalized variants of applicable parameters by iterating over all registered parameters and creating `*.dn` variants.

---

## Global Options System

**File:** `R/PKNCA.options.R`

Options are stored in `.PKNCAEnv` (a package-level environment). Validation functions for each option are stored in `.PKNCA.option.check`.

### Key Options

| Option | Default | Description |
|--------|---------|-------------|
| `auc.method` | `"lin up/log down"` | Integration method |
| `conc.blq` | (list) | BLQ handling strategy |
| `conc.na` | `"drop"` | NA concentration handling |
| `adj.r.squared.factor` | `0.0001` | Tolerance for half-life R² selection |
| `first.tmax` | `TRUE` | Use first or last tmax when tied |
| `allow.tmax.in.half.life` | `FALSE` | Allow tmax in terminal slope window |
| `min.hl.points` | `3` | Minimum points for half-life fit |
| `max.missing` | `0.5` | Max fraction of missing values allowed |
| `progress` | `TRUE` | Show progress bar |

---

## Formula Interface

PKNCA uses standard R formula syntax with a `|` separator for grouping:

```r
concentration ~ time | subject
concentration ~ time | treatment + subject
dose ~ time | study / analyte
```

Parsing is handled in `R/parse_formula_to_cols.R`. The `/` operator creates nested grouping (interaction). Groups are expanded left-to-right and stored as character vectors in the object's `$columns$groups` slot.

---

## Data Flow

```
User data (data.frame)
    │
    ├── PKNCAconc()  ──── validates, stores concentration data + metadata
    ├── PKNCAdose()  ──── validates, stores dose data + metadata
    │
    └── PKNCAdata()  ──── combines conc + dose, generates intervals
            │
            └── pk.nca()  ──── orchestrates all parameter calculations
                    │            (R/pk.calc.all.R)
                    │
                    └── PKNCAresults  ──── long-format results
                            │
                            └── summary()  ──── formatted wide table
```

---

## dplyr Integration

**File:** `R/dplyr.R`

PKNCA registers S3 methods for the major dplyr generics so that users can use familiar dplyr syntax on PKNCA objects. The pattern is: apply the operation to the embedded data frame (`object[[dataname]]`), then return the modified PKNCA object.

This is implemented by wrapping dplyr functions via factory functions (`join_maker_PKNCA`, `filter_PKNCA`, etc.) that intercept the call, operate on the inner data, and return the original PKNCA class structure.

All dplyr generics used as S3 dispatch targets must also be imported (via `@importFrom`) so that their S3 dispatch tables are populated — this is not redundancy but a requirement of R's S3 system for generics defined in other packages.

---

## Unit Support

**File:** `R/unit-support.R`

The unit system supports two modes:

1. **Manual:** User calls `pknca_units_table()` to build a unit assignment table and passes it to `PKNCAdata()`.
2. **Automatic:** `PKNCAdata()` can auto-build units from column metadata if units are attached to the data.

Unit conversion (when the `units` package is available) is handled at the results level, converting from calculation units to preferred display units using `conversion_factor` entries in the unit table.

The `pknca_units_table()` function is an S3 generic, with methods for `PKNCAdata` and a `default` that works from explicit vectors.
