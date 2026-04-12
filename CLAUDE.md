# CLAUDE.md - AI Assistant Guide for PKNCA

## Project Overview

PKNCA (Perform Pharmacokinetic Non-Compartmental Analysis) is an R
package that computes standard NCA parameters for pharmacokinetic
analyses and summarizes them. It has been cross-validated with Phoenix
WinNonlin and Pumas. Licensed under AGPL-3.

## Quick Reference Commands

``` r
devtools::load_all()                                       # Load package for interactive testing
devtools::test()                                           # Run full testthat suite
devtools::test_active_file("tests/testthat/test-auc.R")    # Run a single test file
devtools::check()                                          # Full R CMD check
devtools::document()                                       # Regenerate roxygen2 docs + NAMESPACE
pkgdown::build_site()                                      # Build documentation website
spelling::spell_check_package()                            # Spell check (wordlist: inst/WORDLIST)
```

## Repository Structure

    R/                     # Source code (47 files)
    man/                   # Auto-generated roxygen2 documentation (do not edit by hand)
    tests/testthat/        # testthat test files (43 tests + helper)
    vignettes/             # Rmd vignettes (19 files)
    data-raw/              # Scripts that generate package datasets
    inst/                  # Installed files (CITATION, WORDLIST)
    courses/               # Training materials and presentations
    .github/workflows/     # CI: R-CMD-check, test-coverage, pkgdown

## Core Workflow & Architecture

A typical PKNCA analysis follows this pipeline:

``` r
# 1. Wrap concentration-time data
my.conc <- PKNCAconc(d.conc, conc~time|subject)

# 2. Wrap dosing data
my.dose <- PKNCAdose(d.dose, dose~time|subject)

# 3. Combine into a data object (intervals auto-generated from dose times)
my.data <- PKNCAdata(my.conc, my.dose)

# 4. Run NCA calculations
my.results <- pk.nca(my.data)

# 5. View results
summary(my.results)
as.data.frame(my.results)
```

### PKNCAconc - Concentration Data

`PKNCAconc(data, formula, ...)` wraps concentration-time data.

- **Formula:** `conc~time|groups` (e.g.,
  `conc~time|Study+Subject/Analyte`)
- The last group variable (or the one before `/`) defaults as the
  `subject` column
- **Sparse PK:** set `sparse = TRUE` for sparse sampling designs
- **Optional args:** `volume`, `duration` (for urine/feces),
  `time.nominal`, `exclude`, `exclude_half.life` / `include_half.life`
- **Unit args:** `concu`, `amountu`, `timeu` accept scalar values (e.g.,
  `"ng/mL"`) or column names in the data; `concu_pref`, `amountu_pref`,
  `timeu_pref` set preferred reporting units

### PKNCAdose - Dosing Data

`PKNCAdose(data, formula, ...)` wraps dosing data.

- **Formula:** `dose~time|groups`; supports one-sided formulas (omit
  dose or time with `.`)
- **Route:** `route` parameter – `"extravascular"` (default) or
  `"intravascular"` (column name or scalar)
- **IV dosing:** specify `rate` or `duration` (not both); bolus assumed
  if neither given
- **Unit args:** `doseu` (scalar or column name); `doseu_pref` for
  preferred reporting units

### PKNCAdata - Combined Data Object

`PKNCAdata(data.conc, data.dose, ...)` combines concentration + dose +
intervals.

- Accepts `PKNCAconc`/`PKNCAdose` objects or raw data.frames (with
  `formula.conc`/`formula.dose`)
- **Intervals:** auto-generated from dose times if omitted; pass a
  data.frame for manual specification
- **Units:** auto-built via
  [`pknca_units_table()`](http://humanpred.github.io/pknca/reference/pknca_units_table.md)
  from unit columns on PKNCAconc/PKNCAdose if omitted; or supply a
  manual table
- **Imputation:** `impute` parameter for data imputation methods (see
  [`vignette("v08-data-imputation")`](http://humanpred.github.io/pknca/articles/v08-data-imputation.md))
- **Options:** `options` list for
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md)
  overrides

### Units System

Units flow from PKNCAconc (`concu`, `amountu`, `timeu`) and PKNCAdose
(`doseu`) through to derived NCA parameter units:

- **Scalar or column-based:** unit args accept a string (e.g.,
  `"ng/mL"`) applied to all rows, or a column name for per-row
  stratification
- **[`pknca_units_table()`](http://humanpred.github.io/pknca/reference/pknca_units_table.md)**
  builds the full mapping from base units to derived units (AUC =
  `time*conc`, clearance = `dose/(time*conc)`, etc.)
- **Preferred units:** `*_pref` args enable automatic conversion
  (requires the `units` package)
- **Auto-build:**
  [`PKNCAdata()`](http://humanpred.github.io/pknca/reference/PKNCAdata.md)
  calls
  [`pknca_units_table()`](http://humanpred.github.io/pknca/reference/pknca_units_table.md)
  automatically when no `units` argument is supplied

Example with units:

``` r
my.conc <- PKNCAconc(d.conc, conc~time|subject,
                     concu = "ng/mL", timeu = "hr", amountu = "mg")
my.dose <- PKNCAdose(d.dose, dose~time|subject, doseu = "mg/kg")
my.data <- PKNCAdata(my.conc, my.dose)  # units table auto-generated
```

## Key Classes (S3)

All classes use S3 dispatch (not S4 or R6):

| Class                  | Purpose                                     | Defined in                     |
|------------------------|---------------------------------------------|--------------------------------|
| `PKNCAconc`            | Concentration-time data                     | `class-PKNCAconc.R`            |
| `PKNCAdose`            | Dosing data                                 | `class-PKNCAdose.R`            |
| `PKNCAdata`            | Combined data + intervals + units + options | `class-PKNCAdata.R`            |
| `PKNCAresults`         | NCA calculation results                     | `class-PKNCAresults.R`         |
| `summary_PKNCAresults` | Summary statistics                          | `class-summary_PKNCAresults.R` |

dplyr verbs are supported on these classes: `filter`, `mutate`,
`group_by`, `inner_join`, `full_join` (see `R/dplyr.R`).

## Naming Conventions

- **Functions:** dot notation –
  [`pk.calc.cmax()`](http://humanpred.github.io/pknca/reference/pk.calc.cmax.md),
  [`pk.calc.auc()`](http://humanpred.github.io/pknca/reference/pk.calc.auxc.md),
  [`clean.conc.blq()`](http://humanpred.github.io/pknca/reference/clean.conc.blq.md),
  [`business.geomean()`](http://humanpred.github.io/pknca/reference/business.mean.md)
- **Validation:** `assert_*` with underscores –
  [`assert_conc()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md),
  [`assert_conc_time()`](http://humanpred.github.io/pknca/reference/assert_conc_time.md)
  (exception to dot convention)
- **Class constructors:** PascalCase –
  [`PKNCAconc()`](http://humanpred.github.io/pknca/reference/PKNCAconc.md),
  [`PKNCAdose()`](http://humanpred.github.io/pknca/reference/PKNCAdose.md),
  [`PKNCAdata()`](http://humanpred.github.io/pknca/reference/PKNCAdata.md)
- **File naming:**
  - `class-*.R` for class definitions
  - Some legacy files use numbered prefixes (`001-add.interval.col.R`)
    or `zzz-` prefixes for load order – **do not create new files with
    these prefixes**
  - New files should use descriptive names (e.g., `half.life.R`,
    `interpolate.conc.R`)
  - Test files mirror source: `R/auc.R` -\> `tests/testthat/test-auc.R`

## Code Style

- **Style guide:** tidyverse (package is slowly migrating from older
  dot-style; don’t restyle unrelated code)
- **Documentation:** roxygen2 with Markdown syntax
  (`Roxygen: list(markdown = TRUE)` in DESCRIPTION)
  - Use `@inheritParams` and `@rdname` to avoid duplication
  - Use `@family PKNCA objects` to group related class documentation
  - Use `@keywords Internal` for non-exported helper functions
- **Validation:** `checkmate` package for input validation;
  [`rlang::warn()`](https://rlang.r-lib.org/reference/abort.html) with
  custom error classes (e.g., `"pknca_conc_none"`)
- **Deprecation:** `lifecycle` package for managing deprecated functions
  (see `R/defunct.R`)
- **Global options:** managed through
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md)
  /
  [`PKNCA.choose.option()`](http://humanpred.github.io/pknca/reference/PKNCA.choose.option.md)
  in `R/PKNCA.options.R`

## Testing Conventions

- **Framework:** testthat Edition 3 (`Config/testthat/edition: 3` in
  DESCRIPTION)
- **No snapshot tests** – use explicit expected-value comparisons
- **Numerical tolerance:** use `tolerance=` in `expect_equal()` for
  floating-point PK calculations
- **Test data generators:** `generate.conc(nsub, ntreat, time.points)`
  and `generate.dose(concdata)` in
  `tests/testthat/helper-generate_data.R`
- **Global state:** save and restore
  [`PKNCA.options()`](http://humanpred.github.io/pknca/reference/PKNCA.options.md)
  when modifying options in tests
- **Validation tests:** use `expect_error(..., regexp=)` and
  `expect_warning(..., regexp=)` for input validation
- **Spelling:** checked via
  [`spelling::spell_check_package()`](https://docs.ropensci.org/spelling//reference/spell_check_package.html)
  with custom wordlist at `inst/WORDLIST`

## CI/CD

Three GitHub Actions workflows in `.github/workflows/`:

| Workflow             | Trigger                     | What it does                                                                         |
|----------------------|-----------------------------|--------------------------------------------------------------------------------------|
| `R-CMD-check.yaml`   | push to main, PRs           | R CMD check on macOS (release), Windows (release), Ubuntu (devel, release, oldrel-1) |
| `test-coverage.yaml` | push to main, PRs           | Code coverage via covr, uploads to Codecov                                           |
| `pkgdown.yaml`       | push to main, PRs, releases | Builds and deploys documentation site to GitHub Pages                                |

Build args: `--no-manual --compact-vignettes=gs+qpdf`

## Contributing Checklist

- Update `NEWS.md` for user-facing changes (bullet under current dev
  version header, with GitHub username and issue/PR links)
- Include testthat tests with contributions
- Don’t restyle code outside your change scope
- Run `devtools::document()` after changing any roxygen2 comments –
  always verify that `man/` files and `NAMESPACE` are up to date
- Run `devtools::check()` before submitting – must pass cleanly
- Add new words to `inst/WORDLIST` if spell check flags domain-specific
  terms
