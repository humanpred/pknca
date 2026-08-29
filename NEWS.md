Note that backward compatibility of function arguments will not be
(near-)guaranteed until version 1.0.  Argument and function changes
will continue until then.  These will be especially noticeable around
the inclusion of IV NCA parameters and additional specifications of
the dosing including dose amount and route.

# Development version

* Secondary parameters can now be calculated by linking intervals with
  `interval_id` and `<parameter>_ref` columns in the interval specification.
  The reference interval supplies the cross-profile input (the plasma AUC for
  renal clearance, the reference dose and AUC for bioavailability), it gains
  the source parameter it needs without any change to the intervals the user
  gets back, and exclusions on the source values carry through to the secondary
  result (#76).

* `interval_add_secondary()` writes that linkage for you:  given the parameter
  and a data.frame describing the reference profile, it requests the parameter,
  gives the reference interval an `interval_id`, points the calculating
  intervals at it, and creates the reference interval when the specification
  does not have one yet.  `interval_add_renal_clearance()`,
  `interval_add_accumulation_ratio()`, and `interval_add_metabolite_ratio()` are
  the same call with the reference specification each analysis implies (#76).

* When `interval_add_secondary()` on a `PKNCAdata` object creates a spot-sample
  reference for an excretion analysis (renal clearance), the created interval
  spans the excreta collections whole:  a collection that begins inside the
  interval contributes its full amount, so a collection running past the
  interval's end extends the created reference to cover its duration, and the
  paired plasma AUC covers the same span as the amount excreted (#76).

* New `ratio.cmax`, `ratio.auclast`, `ratio.aucinf.obs`, `ratio.aucinf.pred`,
  `ratio.aucint.last`, and `ratio.aucint.all` parameters give the ratio of a
  parameter between the interval calculating it and its reference interval, for
  accumulation ratios, metabolite ratios, and any other two-profile comparison
  (#76).

* Bioavailability names the AUC basis it is built on: the `f` parameter is
  renamed `f.obs` (AUCinf,obs-based), joined by the new variants `f.pred`,
  `f.last`, `f.int.last`, and `f.int.all`, matching how the `clr.*` family is
  named.  An interval specification requesting the old name `f` gets an error
  pointing at `f.obs` (#76).

* `add.interval.col()` accepts `pknca_ref()` in `formalsmap` to declare an
  argument that comes from the reference interval rather than the current one.

* `add.interval.col()` rejects parameter names ending in `_ref` and the name
  `interval_id`, which are reserved for the interval-linkage columns of the
  interval specification.

* The `interval_id` and `<parameter>_ref` columns hold identifiers of any
  comparable class: character names, factors, or numbers such as row indices.
  The linkage columns must share one class (factors must also share their
  levels) so that the values can be compared.

* Bug fix: requesting `clr.last`, `clr.obs`, or `clr.pred` without its AUC (and
  without a reference interval) silently divided by zero and gave `Inf`.  It is
  now an error saying which reference interval to give.

* `f.obs` (previously `f`) now takes `dose1`/`auc1` from the reference interval
  and computes `dose2`/`auc2` from its own interval as `totdose` and
  `aucinf.obs`; the old `dose2` and `auc2` interval columns are ignored.

* `add.interval.col()` gains a `secondary` element in `selection`, marking a
  parameter that needs inputs from more than one profile.  Bioavailability
  compares two administrations and renal clearance needs both an amount
  excreted and a plasma AUC, so one interval cannot supply what they need;
  they are never chosen automatically but remain available by name.

* `pknca_interval_table()` builds an interval specification from a description
  of the analysis:  when the interval runs, how the drug was given, how often,
  and what was collected.  Given only a start, an end, `dosing`, and `route` it
  chooses the parameters usually reported for that context, the AUC they are
  built on, and the imputation to calculate them from, and it keeps a parameter
  out of the imputation when the imputed value would become the answer.
  `pknca_presets()` gives named argument sets for common analyses.

* Bug fix: `aucint.inf.obs` and `aucint.inf.pred` were classified as
  single-dose parameters.  The "inf" in the name is the extrapolation used for
  the tail, not the end of the interval, so they apply to any dosing pattern;
  over a bounded interval they give AUCtau.

* Bug fix: the standard errors and degrees of freedom produced alongside a
  sparse AUC (`sparse_auc_se` and similar) were not classified as sparse, so
  `pknca_parameter_table()` described them as dense.
* `pk.calc.count_conc()` and `pk.calc.count_conc_measured()` document how they
  treat imputed concentrations.  Neither distinguishes an imputed concentration
  from a measured one, and `count_conc_measured` counts by value:  an imputed
  zero is excluded because it is not above the limit of quantification, while a
  concentration carried to the start time or a fabricated minimum is counted.

* A new imputation method, `start_predose_conc0`, uses a predose concentration
  as the start concentration when one is available and 0 when it is not, and
  keeps a concentration measured at the start time.  The chain
  `"start_predose,start_conc0"` cannot express this because `start_conc0`
  overwrites whatever `start_predose` shifted.  Keeping a measured start
  concentration matters after an intravenous bolus dose, where it is the C0 for
  that dose.

* Bug fix: PKNCA loads in a session where `utils` is not attached (an
  `Rscript` with a trimmed `R_DEFAULT_PACKAGES`, or a `callr` subprocess).
  `add.interval.col()` checks that its `FUN` exists with `utils::getAnywhere()`,
  which looks a dotted name up as a generic and class with an unqualified
  `getS3method()` evaluated in the calling namespace.  Nearly every PKNCA
  function name has a dot in it, so loading the package failed with `could not
  find function "getS3method"`.  `getS3method` is now imported.

* Bug fix: `aucint.inf.pred` and `aumcint.inf.pred` (and their dose-aware
  versions) no longer fail with `tlast (...) must occur exactly once in time`
  when the interval ends at infinity.  The concentration at tlast is calculated
  twice so that integration up to tlast uses `clast.obs` and integration after
  tlast starts from `clast.pred`.  When nothing in the interval follows tlast,
  extrapolation to infinity is analytic and the duplicate only added a
  zero-width interval, so it is now omitted (#620).

* New parameters `mrt.ivmd.obs`, `mrt.ivmd.pred`, `vss.ivmd.obs`, and
  `vss.ivmd.pred` give the multiple-dose (steady-state) MRT and Vss for an IV
  infusion.  They subtract half of the infusion duration, the correction that
  the `mrt.md.*` and `vss.md.*` parameters do not apply, so those were high by
  `duration.dose/2` and by `cl.last*duration.dose/2` respectively for an
  infusion (#151).

* Bug fix: the multiple-dose parameters `mrt.md.obs`, `mrt.md.pred`,
  `vss.md.obs`, and `vss.md.pred` can now be calculated by `pk.nca()`.
  Requesting any of them previously stopped with `Cannot find argument 'tau'`
  because nothing supplied the dosing interval.  `tau` is now detected from the
  group's dose times, and the interval specification accepts a `tau` column
  that takes precedence over detection (needed when only the profiled dose is
  in the dosing data, so nothing repeats).  When `tau` can be neither given nor
  detected, the parameters are `NA` with a warning rather than silently
  reducing to their single-dose equivalents (#151).

* Bug fix: the `start_predose` imputation method no longer stops with `missing
  value where TRUE/FALSE needed` when a concentration has a missing time.  A
  measurement at an unknown time cannot be known to be predose, so it is now
  ignored by the imputation (#361).

* The `start_predose` imputation method no longer shifts a predose
  concentration that is `NA`.  A missing predose value carries no information,
  and shifting it added a missing concentration at the start time where there
  had been no measurement at all.  The most recent predose sample with a
  measured concentration is shifted instead, as long as it is within
  `max_shift` (#361).

* `pk.nca()` only asks for a bug report when it did not diagnose the error
  itself.  A parameter that needs a value from the interval specification
  (`conc_above` for `time_above`, `dose1` and `dose2` for `f`) now names the
  parameter and says to give it as an interval column, instead of prefixing
  "Please report a bug." to an error that is not one (#367).

* Bug fix: the dose-aware interval parameters (`aucint.last.dose`,
  `aumcint.inf.pred.dose`, and the rest of the `*int.*.dose` family) return
  `NA` when the dose time is missing.  With no dosing data, the dose time was
  `NA`, which became a time point to interpolate to and stopped the calculation
  with `Assertion on 'time' failed: Contains missing values` (#367).

* `vignette("v06-half-life-calculation")` gains a decision tree for choosing
  between automatic curve stripping, `exclude_half.life`, and
  `include_half.life`, and it now states that the points named by
  `include_half.life` are still subject to dropping BLQ values and points
  at or before the end of the last dose (#412).

* A new function `get_halflife_fit()` gives the slope, intercept, and time
  range of the half-life fit for each group and interval so that the fitted
  line can be drawn or predicted from.  Times are given on the same scale as
  the concentration data rather than relative to the interval start (#342).

* A new function `get_halflife_curve()` interpolates and extrapolates
  concentrations along the half-life fit.  Give `tout` for specific times or
  `n` for equally-spaced times, as with `stats::approx()`.  Extrapolation
  after the last concentration used for the fit is done by default and
  extrapolation before the first is not; both are controlled by the
  `extrapolate_later` and `extrapolate_earlier` arguments (#342).

* IV bolus AUC and AUMC parameters (`aucivlast`, `aucivinf.obs`, `aumcivlast`,
  and the rest of the `auciv`/`aumciv` family) no longer require a measured
  concentration at time 0.  When the profile starts after the dose, `c0`
  supplies the concentration at time 0 and the AU(M)C is calculated from it
  (#352).

* Breaking change: `pk.calc.auciv_pbext()` gains `conc` and `time` arguments.
  The percent back-extrapolated (`aucivpbextlast`, `aucivpbextint.last`, and
  the rest) is now `NA` unless a concentration was measured at time 0.  Without
  one, the AUC it compares against either cannot be calculated or, for the
  `aucint` family, already extrapolates back to time 0 with `conc.origin`, so
  it does not describe the observed part of the IV AUC (#352).

* `add.interval.col()` accepts an `I()`-wrapped value in `formalsmap` to pass a
  constant to the calculation function instead of naming a data source or
  another parameter.  See `vignette("v80-writing-parameter-functions")`.

* Bug fix: `superposition()` drops missing concentrations before calculating.
  They previously reached the half-life fit and stopped the calculation with
  `NA/NaN/Inf in 'x'` (#308).

* `superposition()` checks the `method` and `auc.type` arguments for every
  input.  An invalid value was previously ignored when the calculation
  required neither interpolation nor extrapolation (#247).

* `add.interval.col()` gains `formula` and `formula_note` arguments giving the
  calculation as a LaTeX expression.  They are shown in the parameter table in
  `vignette("v03-selection-of-calculation-intervals")` (#507).

* Requesting a parameter that needs a sample volume (`ae`, `fe`, `volpk`,
  `clr.last`, and similar) when no `volume` was given to `PKNCAconc()` is now
  an error naming those parameters, rather than silently reporting them as
  not calculated (#194).

* `PKNCAconc()` no longer adds `volume` and `duration` columns to the data
  when those arguments are not given.  They are only used by urine and fecal
  calculations, so most datasets carried two columns of `NA` and `0` that
  nothing read (#166).  Requesting an excretion rate parameter (`ermax`,
  `ertmax`, `ertlst`) without a `duration` is now an error naming those
  parameters; previously the collection duration silently defaulted to zero
  and the rates were reported as infinite.  The error class for a missing
  volume changed from `pknca_error_missing_volume` to
  `pknca_error_missing_conc_input`, which now covers both inputs.

* Bug fix: `pk.calc.cl()`, `pk.calc.totdose()`, `pk.calc.ae()`,
  `pk.calc.clr()`, and `pk.calc.fe()` return `NA` rather than 0 when an input
  is zero-length.  `sum()` of nothing is 0, so a clearance calculated without
  a dose was reported as 0 instead of as missing (#601).  Counting parameters
  such as `pk.calc.count_conc()` still return 0, which is their documented
  behavior.

* The message about missing dosing information is now raised only when a
  requested parameter actually needs it, and it names the parameters that will
  not be calculated (#538).  Dose amount, time, and duration are checked
  separately, so requesting `c0` with dose times but no amounts is quiet while
  requesting `cl.last` is not.

* `get.parameter.deps()` gains a `recursive` argument.  The default is
  unchanged and returns the parameters calculated from `x`; `recursive = TRUE`
  returns what `x` is calculated from, following each dependency back to raw
  inputs such as `conc`, `time`, and `dose`.

* PKNCA now declares a minimum R version of 4.4 in DESCRIPTION, and
  continuous integration tests it.  The floor comes from `Matrix`, which
  requires R >= 4.4 and is needed by `lme4` and so by the bioequivalence
  functions; the rest of the package would run on R 4.1.

* Breaking change: The `exclude_half.life` and `include_half.life` columns must
  now be logical (`TRUE`/`FALSE`/`NA`).  A non-logical column (e.g. character
  `"yes"`) previously was accepted silently and excluded or included nothing; it
  is now an error.  Likewise, an `exclude_half.life` or `include_half.life`
  column name that does not exist in the data previously created an all-`NA`
  column silently (so a typo deactivated the point selection); it is now an
  error naming the missing column (#583).

* Bug fix: `pk.calc.half.life()` now attaches an exclusion reason ("No valid
  terminal phase...") when no candidate window survives point selection (for
  example, when a well-fitting window with `lambda.z <= 0` anchors the adjusted
  r-squared tolerance), instead of returning `NA` with no reason.  The reason
  appears in the `exclude` column of `pk.nca()` results (#583).

* Bug fix: `update()` on a `PKNCAresults` object now works when group columns
  are factors whose levels differ between the old and new data (for example,
  ordered factors like `datasets::Theoph$Subject` after re-leveling); group
  columns are matched by value while keeping their classes and levels in the
  results.  `update()` also no longer warns "No concentration data" for every
  unchanged group, because the intervals are now filtered to the changed groups
  along with the concentration and dose data (#581).

* Bug fix: `superposition()` no longer loops forever when steady-state is
  requested (the default `n.tau=Inf`) and concentrations are extrapolated as
  zero after `tlast` (for example, `auc.type="AUClast"` when `tlast < tau`).
  Steady-state is now assessed on the concentrations that can become nonzero,
  a warning is given when zero concentrations remain in the steady-state
  profile, and an informative error (instead of an infinite loop) is raised if
  steady-state cannot be reached within 10000 dosing intervals (#580).
  Warnings, messages, and printed output from `superposition()` on a
  `PKNCAconc` object are now raised by the parent process.  Each subject runs
  through `parallel::mclapply()`, which forks on every platform except
  Windows, and a condition raised in a forked worker never reaches the
  caller, so the new warning was previously invisible except on Windows.

* Corrected registry description strings that did not match the
  implementation (#582).  `adj.r.squared.factor` is described as selecting
  the regression with the most points among those within the tolerance of
  the best adjusted r^2, rather than as a factor added per data point.
  `span.ratio` is described as the lambda z time span divided by the
  half-life; the previous text stated the inverse.  The eight dose-aware
  `aucint*`/`aumcint*` parameters ending in `.dose` no longer describe
  themselves as `AUCdn`/`AUMCdn`, which is this package's abbreviation for
  dose normalization (`auclast.dn` and similar).

* Bug fix: `pk.calc.sparse_auc()` and `pk.calc.sparse_aumc()` now use their
  `options` argument when integrating the mean concentration-time profile, so
  per-run options (e.g. `PKNCAdata(options = list(conc.blq = "keep"))`) affect
  sparse AUC and AUMC calculations the same way global `PKNCA.options()`
  settings always did.  The documentation for `sparse_mean()` now correctly
  states that a timepoint mean is zeroed when >50% of the measurements are
  BLQ (#579).

* Parameter descriptions in `add.interval.col()` longer than 40 characters now
  warn, since SDTM requires descriptions of 40 characters or fewer.  The
  description is still registered, so a package that supplies a longer one
  keeps working and can shorten it before an SDTM submission.

* Bug fix: `pk.nca()` no longer errors on unsorted concentration-time data.
  Group-level concentration data are now sorted by time before calculation, so
  parameters that use the full group (e.g. `aucint.all` and the other `aucint*`
  parameters) work when the input rows are not in time order (#568).

* Migrated input validation across the package from base R checks
  (`stopifnot()`, `is.character()`, `is.numeric()`, etc.) to `checkmate`
  assertions, and standardized error/warning signaling on classed
  `rlang::abort()`/`rlang::warn()` conditions (e.g. `pknca_error_*`,
  `pknca_warning_*`) instead of unclassed base `stop()`/`warning()`. This
  makes failure modes catchable by class rather than by matching message
  text. As a side effect, some validations became stricter (rejecting
  previously-accepted edge cases like non-finite numbers); see
  the entries below for specifics.

* `pk.calc.aucabove()` now requires `conc_above` to be finite. Previously,
  `Inf` or `-Inf` were silently accepted and produced a degenerate result
  (AUC of 0 for all profiles, since `conc - Inf` is always `-Inf`). Passing
  a non-finite `conc_above` now raises an error instead.
  
* `get_impute_method()` now requires `impute` to be an atomic scalar (via
  `checkmate::assert_scalar()`). Previously, a bare `length(impute) == 1`
  check meant a length-1 list (e.g. `list("start_conc0")`) could pass through,
  relying on `%in%`'s implicit list coercion downstream instead of failing
  clearly. Passing a list now raises an error instead.

* `add.interval.col()` now validates the structure of `pptestcd_cdisc` and
  `pptest_cdisc` rather than only checking that they are a character string or
  a list.  A character value must be length 1 and non-missing, and a list must
  have exactly one element named `route` whose value is a named list.  Values
  that were previously accepted and would have produced incorrect CDISC output
  (for example a multi-element character vector, or a list named something
  other than `route`) now raise an error.

* Business functions (used for calculations of means, etc.) now return NA_real_
  for empty inputs rather than giving an error (#559).

* `PKNCAconc()` gains an `lloq` argument (a column name or a numeric scalar) that
  is passed through to `pk.calc.half.life()`.  This wires the lower limit of
  quantification through a full `pk.nca()` run so the Tobit half-life method
  (`hl_method = "tobit"`, set via `PKNCAdata(options = list(hl_method = "tobit"))`)
  works end-to-end instead of failing because no `lloq` was available.

* Added sparse AUMC function and five sparse-derived parameters (cl.sparse.last,
  kel.sparse.last, mrt.sparse.last, vss.sparse.last, vz.sparse.last)

* New imputation method `PKNCA_impute_method_end_conc_drop()` drops a
  concentration observed exactly at the end of the interval from that interval
  (e.g. a predose sample from the next dose measured at the interval boundary)

* New IV dosing AUMC parameters with C0 back-extrapolation (`aumciv*`)

* New interval AUMC parameters with interpolation/extrapolation support
  (`aumcint*`), mirroring the existing `aucint` family (#152)

* New derived PK parameters to complete coverage across all AUC variants
  (#152):
  * 11 clearance parameters (`cl.*`)
  * 9 elimination rate constant parameters (`kel.*`)
  * 6 mean residence time parameters (`mrt.*`)
  * 3 IV mean residence time parameters (`mrt.iv.*`)
  * 9 volume of distribution at steady state parameters (`vss.*`)
  * 13 terminal volume of distribution parameters (`vz.*`)

## Features added

* `add.interval.col()` gains `pptestcd_cdisc` and `pptest_cdisc` arguments for
  CDISC standard parameter code and name mappings.  Route-dependent parameters
  (CL, VZ, MRT, VSS) accept a nested list to distinguish intravascular and
  extravascular CDISC codes (#403)
* `as.data.frame.PKNCAresults()` gains `out_format = "cdisc"` to translate
  PPTESTCD to CDISC standard codes and add a PPTEST column.  Route-dependent
  translations are resolved from the dose data (#403)
* When `out_format = "cdisc"` and any parameter has "INT" in its PPTESTCD,
  PPSTINT and PPENINT columns are added with ISO 8601 durations relative to
  the last dose time.  The time unit is taken from `timeu_pref` or `timeu`
  (#403)

## Bug Fixes

* `normalize.data.frame()` no longer triggers a dplyr deprecation warning
  (`Using 'by = character()' to perform a cross join was deprecated in dplyr 1.1.0`)
  when called with ungrouped data (i.e., no common group columns between `object`
  and `norm_table`). `dplyr::cross_join()` is now used explicitly for this case.

## Improvements

* Documentation for `include_half.life` and `exclude_half.life` now describes
  the three-state (`TRUE`/`FALSE`/`NA`) per-point behavior, clarifies that a
  column counts as "in use" whenever it is not entirely `NA` (so an all-`FALSE`
  column still engages the method), and states that only one of the two may be
  in use for the same interval. The half-life vignette gains the same note and
  fixes a mislabeled "include" example.

* The sparse NCA vignette now explains how subjects are grouped: sparse
  parameters pool all subjects that share the same concentration grouping
  variables with the subject column removed (#530).

* `normalize.data.frame()` now validates that `norm_table` contains exactly one
  row when used with ungrouped data, giving a clear error message instead of
  silently producing incorrect results.

* `normalize.data.frame()` now uses `dplyr::inner_join()` instead of `merge()`
  for grouped joins, preserving left-table row order. Missing group validation
  ensures no rows are silently dropped.

* `PKNCAresults()` now includes `start` and `end` in `group_vars`

## Breaking changes

* The pre-existing `pknca_*` condition classes were renamed to carry an explicit
  `error`/`warning`/`message` element, so code that catches them by class must be
  updated.  For example, `pknca_conc_none` is now `pknca_warning_no_concentration`,
  `pknca_no_intervals` is now `pknca_warning_no_intervals`, and
  `pknca_all_warnings_no_results` is now `pknca_warning_no_results`.  One change
  goes beyond renaming: the two classes `pknca_sparse_auclast_change_auclast` and
  `pknca_sparse_aumclast_change_auc_type` were merged into the single class
  `pknca_error_auc_last_type_override`, so they can no longer be caught
  separately.

* `pknca_units_table()` called on a `PKNCAdata` object now raises an error if
  unit columns within the same concentration group contain mixed values (e.g.,
  two different `concu` strings for the same subject group).  Previously, `NA`
  values in unit columns were silently ignored and multiple values caused a
  different error message; now any intra-group inconsistency is detected and
  reported with the offending group identifiers.

* Both include and excluding half-life points may not be done for the same interval (#406)

## Bugs fixed

* `get_halflife_points()` now correctly accounts for start time != 0 and sets
  times outside of any interval to `NA` (#470)
* The `PKNCAconc` function won't give an error for a concentration-time check
when the issue is due to an excluded point (#310)
* The `PKNCAdose` function won't give an error for a missing-time check when the issue is due to an excluded point (#310)
* `pk.nca` will calculate `fe` and `clr` even if their dependent parameters (e.g, `ae`) were not requested to be calculated in the intervals (#473)
* sparse calculations won't abort with `pk.nca` when the data contains missing (NA) concentrations. It will silently drop them.

## New features

* Added bioequivalence (BE) assessment via a single calculation path.
  `be_assess()` computes the full regulatory pass/fail decision for average
  bioequivalence, the EMA/Health Canada/GCC expanding-limits (ABEL) frameworks,
  and the FDA reference-scaled (RSABE), narrow therapeutic index (NTID), and
  highly variable NTID (HVNTID) frameworks, with the model auto-selected from
  the regulator and design; `be_compare()` assesses one dataset under several
  frameworks at once.  These are coordinated by `be_fit_models()`, which runs
  the pipeline `be_dataset()` -> `be_fit_model_single()` -> `be_extract_param()`
  -> `be_table()`; the supporting functions `be_design()`, `be_within_var()`,
  `be_regulator()`, and `be_expand_limits()` are also exported.  All regulatory
  constants and criteria are internalized, so no additional packages are
  required beyond `lme4`/`lmerTest`/`emmeans` (suggested) for the average-BE
  model.  See the new `vignette("v50-bioequivalence")`.  Based on work by
  @Sang-j111 (#490)

* `pknca_units_table()` is now an S3 generic with a `PKNCAdata` method.  When
  called on a `PKNCAdata` object it automatically builds the unit conversion
  table from any unit columns stored in the underlying `PKNCAconc` and
  `PKNCAdose` objects, supporting per-analyte or per-specimen unit
  stratification.  The table is also built automatically on `PKNCAdata()`
  construction when no `units` argument is supplied.

* `pk.calc.half.life()` now supports Tobit regression for half-life estimation via
  `hl_method = "tobit"`.  Tobit regression treats BLQ observations as
  left-censored rather than discarding them, which generally improves half-life
  accuracy when some measurements are below the LLOQ.  The new `lloq` argument
  (required for Tobit) accepts a scalar or per-observation vector.  New
  PKNCA options: `hl_method` (default `"log-linear"`), `tobit_n_points_penalty`
  (default 0), and `tobit_optim_control`.  New NCA output columns:
  `tobit_residual`, `adj_tobit_residual`, and `lambda.z.n.points_blq`.

* `pk.calc.half.life()` now returns also `lambda.z.corrxy`, the correlation between
  the time and the log-concentration of the lambda z points.
* `get_halflife_points()` can now be used on PKNCAdata objects to see which points
  would be used for half-life calculation (#476)
* New excretion parameters: `volpk` (total urine volume for an interval) and
  dose-normalized renal clearance parameters: `clr.last.dn`, `clr.obs.dn`,
  `clr.pred.dn` (#433)
* `PKNCA.set.summary(reset = TRUE)` warns that it may break the use of
  `summary()` (#477)
* `pk.nca` output now includes a `PPANMETH` column describing the analysis methods used for each parameter regarding imputations, AUC and half.life calculations (#457)
* Added new `tmin` parameter
* New post-processing functions to normalize PKNCA result parameters based on any column in PKNCAconc data.frame (`normalize_by_col()`) or by using a custom normalization table (`normalize()`)
* New excretion rate parameters: `ermax`  (Maximum excretion rate), `ertmax` (Midpoint time of maximum excretion rate) and `ertlst` (Time of last excretion rate measurement) (#433)

* New functions simplify the modification of intervals:
  `interval_add_param()`, `interval_remove_param()`, `interval_add_impute()`,
  and `interval_remove_impute()`.  Each accepts either a `PKNCAdata` object or
  a data.frame of intervals, and the change may be restricted to specific
  parameters (`target_params`) or specific intervals (`target_groups`).  When
  the parameters within an interval no longer share the same imputation, the
  interval is split into as many rows as are needed, and rows that come to
  share every value are merged (#379).

* Two excretion parameters were added:  `erint`, the excretion rate over the
  interval (the amount recovered divided by the interval duration), and
  `erlst`, the last measurable excretion rate.  Both are standard CDISC
  parameters (`ERINT` and `ERLST`) that PKNCA calculated internally but did
  not report.

* Bug fix: the CDISC parameter names for `ertlst` and `volpk` did not match
  the standard and did not describe what the functions return.  `ertlst` is now
  "Midpoint of Interval of Last Nonzero ER" rather than "Time of Last
  Excretion Rate" (it returns the collection midpoint, as `ertmax` does), and
  `volpk` is now "Sum of Urine Vol" rather than "Volume of PK sample".

* NCA parameters are now classified so that they can be chosen automatically
  for a calculation interval.  `pknca_parameter_table()` shows the
  classification:  the `concept` a parameter computes, its reporting `tier`,
  and the route, dosing, and sample-collection contexts it applies to.  Most of
  it is derived from the existing registry; `add.interval.col()` gains a `tier`
  argument and a `selection` argument for the few cases that cannot be derived.
  A parameter's concept is declared on its calculation function with
  `pknca_concept()`, so a parameter added by another package can carry one too.
  Nothing here raises an error:  an unclassified parameter is simply never
  chosen automatically, and `pknca_check_parameter_classification()` reports
  those.

## Minor changes (unlikely to affect PKNCA use)

* Remove dead code: unused internal functions, commented-out code, unused
  variable, stale comment, and unused `pmxTools` Suggests dependency

# PKNCA 0.12.1

## Minor changes (unlikely to affect PKNCA use)

* Units for fraction excretion parameter (fe) are now accurately captured as
  amount/dose units rather than "fraction" (#426)
* `get_halflife_points` will ignore points after `lambda.z.time.last`, instead
  of `tlast` (#448)
* `lambda.z` calculations will now only consider time points that occur after
  the end of the latest dose administration (#139)
* `aucint.inf.pred` is `NA` when half-life is not estimable (#450)

## New features

* PKNCA now has a debugging mode to support troubleshooting; it is not intended
  for production use. Debugging mode can be enabled using
  `PKNCA.options(debug = TRUE)`.
* It is now possible to update an existing analysis when data changes but other
  NCA settings stay the same (fix #417)
* New assertion functions were created to ensure that an object is the correct
  type (fix #328)

# PKNCA 0.12.0

## Breaking changes

* PKNCA will now give an error when there are unexpected interval columns.
  The `keep_interval_cols` option can be used to mitigate this error.
* `NA` results from calculating `c0` will now add an exclusion reason.
* AUC for intravenous dosing (all the `auciv*` parameters) now more robustly
  calculate `c0` and does not raise an error when `is.na(c0)` (#353).
* Manual calculation of half.life no longer allows negative half-live values
  (#373).
* pk.calc.half.life() now returns also lambda.z.time.last, the last time point used for terminal slope estimation.

## New Features

* `PKNCAconc()` and `PKNCAdose()` can now accept unit specifications as either
  column names or units to use (#336).
* PKNCA options can now use `tmax` as a reference for BLQ handling by using new
  names in the `conc.blq` argument (`before.tmax`,`after.tmax`)
* A new parameter `count_conc_measured` was added to enable quality checks,
  typically on AUC measurements. An associated exclusion function,
  `exclude_nca_count_conc_measured()` was also added.
* The `PKNCAconc()` arguments of `include_half.life` and `exclude_half.life` now
  allow `NA` values. If all values are `NA`, then no inclusion or exclusion is
  applied (the interval is treated as-is, like the argument had not been given).
  If some values are `NA` for the interval, those are treated as `FALSE`.
* `group_vars()` methods were added for `PKNCAdata` and `PKNCAresults` objects.
* If intervals have attributes on the columns, there will no longer be an error
  during parameter calculation, and the attributes are preserved (#381)
* When adding units, if some but not all units are provided, then an error will
  be raised. This error can be converted to a warning using the option
  `allow_partial_missing_units = TRUE`. (#398)
* A new function `get_halflife_points()` lets users know which points were used
  for half-life calculation. (#387)
* A new function `exclude_nca_min.hl.adj.r.squared()` to allow exclusion of
  half-life results based on a minimum adjusted r-squared threshold.

## Minor changes (unlikely to affect PKNCA use)

* PKNCA will now verify the `intervals` data.frame when creating PKNCAdata. The
  checking includes confirming intended column naming and ensuring the correct
  data types.
* PKNCA now contains a `getGroups.PKNCAdata` function to capture grouping columns.
* Duplicate data checks now account for excluded rows.  So, if a row is
  duplicated and all but one of the duplicated rows is excluded, it is not an
  error.  (#298)
* Removed native pipes (`|>`) so that PKNCA will work with older versions of R
  (#304).
* Missing dosing times to `pk.calc.c0()` will not cause an error (#344)
* `getGroups()` includes the `end` column when applied to a `PKNCAresults` object (#419).

# PKNCA 0.11.0

* PKNCA will now indicate the number of observations included in a summary ("n")
  when it is not the same as the number of subjects included in the summary
  ("N") and the caption will also indicate the definition of "N" and "n".  Note
  that counting of "n" includes all non-missing values that were not excluded
  from summarization; this will included all zeros that are e.g. excluded from
  geometric statistics.
  * If `n == 1`, spread statistics are no longer calculated in the summary.
* A new AUC integration method, "lin-log", has been added using the linear
  method through tmax and log after tmax, with required exceptions for zeros
  (fix #23)
* The parameter `vd` was removed (it was not specific like `vz` or `vss`, and it
  was effectively a duplicate of `vz`).  Use `vz`, instead.
* The `count_conc` NCA parameter was added to assist in data quality checking.
* Subject count ("N") previously counted the number of rows of data, but in
  unusual circumstances, the number of subjects in an NCA result could be fewer
  than the number of rows.  Now the number of subjects is counted (fix #223).
* Extra column in the `intervals` argument to `PKNCAdata()` will no longer cause
  an error (fix #238)
* Many new `assert_*` functions were added to standardize input checking in the
  style of the `checkmate` library.
* Interpolation of zero concentrations in the middle of a set of concentrations
  is now more extensively supported.
* PKNCA has begun the process of deprecating dots in favor of underscores in
  function and parameter names.  Functions with dots instead of underscores
  should continue to work for the foreseeable future (until version 1.0) with
  warnings.
* AUCint will now extrapolate the AUC beyond Tlast using logarithmic
  extrapolation, regardless of the method used (fix #203).
* Imputation will now automatically search for a column named "impute" in the
  interval definition (fix #257).
* Imputation now can look outside the concentration-time of the interval to the
  full concentration-time profile for the group with the `conc.group` and
  `time.group` arguments to the imputation functions.  And,
  `PKNCA_impute_method_start_predose()` imputation performs more reasonably when
  the end of the interval is infinite.
* A progress bar is now available via the `PKNCA.options(progress = )` option
  (fix #193).
* Additional versions of average concentration based on AUCint are now available
  (fix #45).
* A new option "keep_interval_cols" was added to allow keeping a column from the
  intervals in the NCA results.  Note that these are not included in the summary
  groups by default.
* A new argument "filter_requested" for `as.data.frame.PKNCAresults()` allows
  you to filter only to requested results from a PKNCAresults object.
* `pknca_units_table()` now has four new arguments to allow for simplified
  automatic conversion from source units to desired reporting units,
  `concu_pref`, `doseu_pref`, `amountu_pref`, and `timeu_pref` (#197)
* Extraction of PKNCA objects from within other PKNCA objects is now supported
  by various `as_PKNCA*` functions like `as_PKNCAconc()` which can be used to
  extract the concentration data from within a PKNCAdata or PKNCAresults object
  (#278)
* A new "totdose" parameter gives the total dose administered during an interval
* You may exclude parameters from a summary with the new `drop_param` argument
  to `summary()` for PKNCAresults objects.
* The `as.data.frame()` method for `PKNCAresults` objects has a new
  `filter_excluded` argument to remove excluded results from the extracted
  data.frame.  The default behavior is to keep the excluded results with the
  exclude column indicating the reason they were excluded.

## Bugs fixed

* `superpostion()` and the `interp.extrap.conc()` family of functions now
  respect the interpolation and extrapolation types requested rather than using
  default.
* Concentration extrapolation with `extrapolate.conc()` using the "AUCall"
  method now has decreasing instead of increasing concentrations (#249).
* The aucint.inf.obs parameter when calculated with all zero concentrations
  returns zero and aucint.inf.pred returns `NA_real_` (#253)

## Breaking changes

* The arguments `interp.method` and `extrap.method` have been replaced with
  `method` and `auc.type` in the `interp.extrap.conc()` family of functions for
  consistency with the rest of PKNCA (fix #244)
* The AIC.list() function is no longer exported (it was never intended to be an
  external function).
* The `depends` argument to `add.interval.col()` must either be NULL or a
  character vector.
* The names of the `fun.linear`, `fun.log`, and `fun.inf` arguments to
  `pk.calc.auxc` were changed to use underscores.  (If you were using those
  directly, please reach out as they were intended to be internal arguments, and
  I would like to know your use case for changing them.)
* `check.conc.time()` is defunct (it was never intended to be an external
  function).  It has been replaced by `assert_conc()`, `assert_time()` and
  `assert_conc_time()`.
* The clast.obs parameter is now zero when all concentrations are zero (see #253
  for part of the reason).
* (This is not likely to be important for most users.)  The `business...`
  functions (e.g. `business.geomean()`) now include an attribute in non-`NA`
  results with `n`, the number of values included in the statistic.

## Changes under the hood

* Multiple changes were made to speed up calculations.  These will mainly be
  noticed when performing NCA on many subjects (for instance, following
  simulations).  None of these should have external effects that users will
  notice:
  * Adding in dependent parameters required for requested parameters is now more
    efficient (approx 40% time savings)
  * Sorting interval dependencies happens less often (approx 5% time savings)
  * Determining if a parameter is needed for calculation when looking across all
    parameters is more efficient (negligible time savings)
* An internal change was made to make AUC integration and concentration
  interpolation simpler and simplify the ability to create new AUC integration
  or concentration interpolation methods

# PKNCA 0.10.2

* A minor change to `pk.calc.aucpext()` was made so that it now returns
  `NA_real_` instead of `NaN`.
* A minor change was made so that AUC and amount excreted (ae) calculations will
  provide an exclusion reason the result is `NA`.
* A minor new feature makes the specification of imputation easier.  You can
  give the imputation with or without the "PKNCA_impute_method_" prefix.  So,
  "PKNCA_impute_method_start_predose" and "start_predose" are equivalent.

# PKNCA 0.10.1

* A new parameter `aucabove.trough.all` was added to calculate the NCA above the
  trough concentration.
* Testing updates were made to work with dplyr version 1.1.0 (fix #198)
* Internal changes to how columns are identified were made, and the parseFormula
  function was subsequently removed (parseFormula was never intended for
  external use).

# PKNCA 0.10.0

## Bugs Fixed

* When calculating AUC with only a single concentration measurement, NA is now
  returned instead of 0. (fix #176)

## New Features

* Initial support for unit assignment and conversion has been added.  See the
  `units` argument to the `PKNCAdata()` function and the function
  `pknca_units_table()`.
* Initial support for imputation has been added.  See the `impute` argument to
  the `PKNCAdata()` function and the Data Imputation vignette.
* With the addition of units, several outputs now will differ, if units are
  used:
    * `summary()` on a PKNCAresults object shows the units in the column
      heading.
    * When running `as.data.frame()` on a PKNCAresults object with the argument
      `out.format="wide"`, if standardized units values are available, they will
      be used.  And if any unit are available, they will be in the column names.
* Summary tables with units use the "pretty_name" for a parameter which is
  intended for clearer representation in reports.  "pretty_name" use can be
  controlled with the "pretty_names" argument to `summary()`.
    * Note that the pretty names themselves may be modified to help clarify and/or
      shorten the names to make the table heading more useful.  If you intend to
      modify column headers programmatically, set `pretty_names=FALSE` when
      calling the `summary()` function.
* New, IV AUC calculation methods have been added.
* `pk.calc.time_above()` now uses the default AUC calculation method for
  interpolation of time above.  And, it can use 'lin up/log down' interpolation.
* PKNCA can now calculate parameters that require extra information by adding
  the extra information to the intervals data.frame.  For example, add
  `conc_above` as a column to the intervals to allow calculation of
  `time_above`.  With this change, the "conc_above" `PKNCA.options()` value has
  been removed.
* Added dplyr joins, filter, mutate, group_by, and ungroup to allow modification
  of PKNCA objects after creation.  (Note that these functions will make the
  provenance no longer match for PKNCAresults objects.)

## Breaking Changes

* Some functions that were intended to be internal were removed:
    * All `getData()` functions were removed.
    * The `getDataName()` function for PKNCAdata objects was removed.
* `interpolate.conc()` and `interp.extrap.conc()` now give more errors with
  missing (NA) input.  This should not affect typical NCA (where NA values are
  dropped), but it may affect direct calls to the functions themselves.

## Internal Breaking Changes (these should not affect PKNCA users)

* print.parseFormula() was removed from the package.

# PKNCA 0.9.5

* The internals of how PKNCA performs calculations had a significant update. The
  only user-visible change should be that PKNCA does not perform parallel
  computations as of this version. Parallel computation is planned to return in
  the near future.
  * Breaking change:  As part of this change, the split methods for PKNCAconc
    and PKNCAdose objects were removed along with the merge.splitList function.
* Single-subject (ungrouped) analysis works without creating a dummy group (#74)
* PKNCAconc objects are checked earlier for valid data (#154)
* Add time_above parameter to calculate time above a given concentration.
* Fix numeric BLQ replacement when the value is a number and different values
  are given for first, middle, and last (related to #145).  This only affects
  datasets where BLQ is being replaced with a nonzero value (not a common
  scenario).
* Fix issue where intervals could not be tibbles (#141)
* Fix minor issue where only the first exclusion reason would show in the
  exclusion column and other reasons would be ignored (#113). Note that the
  impact of this bug is minimal as the result would have been excluded from
  summaries for the first reason found, but if there were multiple reasons for
  exclusion the subsequent reasons would not be recorded.

# PKNCA 0.9.4

* Additional changes required for compatibility dplyr version 1.0 and CRAN
  checks.  No functionality changed.
* Minor typographical and documentation consistency cleanups throughout.

# PKNCA 0.9.3

* Changes required for compatibility dplyr version 1.0.  No functionality
  changed.

# PKNCA 0.9.2

* New feature: the `time_calc()` function will help convert time values to be
  relative to events (such as calculating time after and before doses)
* Fix issue summarizing results when "start" and "end" are dropped and there are
  multiple interval rows matched for a single group.
* Enable exclusions to be prevented when the input arguments suggest exclusion,
  but the parameter calculating function may be aware of better information about
  exclusion.
* Ensure that exclusions are maintained if an earlier parameter is excluded
  during the initial parameter calculations (Fix #112).
* Two-point half-life calculation works and adjusted r-squared gives a warning
  instead of an error with 2 points (Fix #114).
* Half-life calculation time was decreased by using `.lm.fit()` instead of
  `lm()` decreasing time for a full NCA run by ~30% (and half-life by ~50%).
* For R version 4.0, much more care was taken not to create factors from strings
  unless required (see
  https://developer.r-project.org/Blog/public/2020/02/16/stringsasfactors/index.html)

# PKNCA 0.9.1

* Correct vignette building.

# PKNCA 0.9.0

* Breaking Change: `plot.PKNCAconc()` was moved to the pknca.reporting package
  (https://github.com/humanpred/pknca.reporting)
* Breaking Change: `summary.PKNCAresults()` now provides a caption
  including the summary method for each parameter.  If you change
  summary functions using `PKNCA.set.summary()`, you must now use the
  `description` option to set the description of the summary.
* Breaking Change: ptr now accurately uses ctrough instead of cmin (fix #106)
* Issue fixed where aucint* calculations now respect BLQ and NA rules like other
  calculations. (#104)
* When half.life is not calculated due to insufficient number of points (default
  < 3), an exclusion reason is added. (#102)
* tibbles now work as the interval argument for `PKNCAdata()` (fix #72)
* Issue fixed with summarization of data that has exclusions.
  Exclusions are now correctly handled as missing instead of never
  calculated.
* parseFormula now internally uses NULL for no-group formula definitions.
* signifString and roundString now have sci_range (deprecating si_range) and
  sci_sep arguments.
* Documentation is improved, especially around the selection of
  parameters for intervals.
* Multiple dose data with a single concentration measurement no longer
  generates an error (fixes #84).
* The "start" and "end" columns may now be dropped from the summary of
  `PKNCAresults` objects.
* `PKNCAdata()` is more restrictive on unknown arguments issuing an error
  when unknown arguments are present.
* `intervals` argument to `PKNCAdata()` may now be a tibble (fixes #72).
* Documentation has been extensively updated (fixes #81).
* CRAN changes: Vignettes now better respect not loading suggested
  packages.  Tests are now more permissive in timing.

# PKNCA 0.8.5

* Cleaned AUCint names
* Added dose-count within interval (to warn of multiple doses within an
  interval)
* Various documentation updates
* signifString and roundString now by default use scientific notation
  for values >=1e6 and <=1e-6
* Fix bug in option handling within `pk.nca` (Fix #68)

# PKNCA 0.8.4

* Added AUCint flavors
* Parameter names for NCA parameters will likely be changing in the
  next version; code will still work, but some calculation methods and
  therefore results may be subtly different.  These changes will be
  fully documented.)

# PKNCA 0.8.2

* BACKWARD INCOMPATIBILITY: The function supplied to the exclude
  argument 'FUN' now requires two arguments and operates on the level
  of a single group rather than the full object.  The function can
  also return the reason as a character string instead of a logical
  mask of when to exclude data.
* BACKWARD INCOMPATIBILITY: Added back-end functionality to only
  require one function to handle many NCA parameters that are related
  (e.g. combine pk.calc.aucpext, pk.calc.aucpext.obs,
  pk.calc.aucpext.pred, etc.).  If your current code calls a specific
  function (like pk.calc.aucpext.pred), you must change to using the
  generic function (like pk.calc.aucpext)
* BACKWARD INCOMPATIBILITY: Functions that previously may have
  returned Infinity due to dividing by zero (e.g. when AUC=0
  calculating clearance) now return NA.

* Added Validation vignette.

* Corrected issue where time to steady-state with a single estimate
  may have given more than one estimated time to steady-state.
* Corrected issue with exclude handling where now a blank string is
  also accepted as included (not excluded).
* PKNCAconc now accepts a "volume" argument and pk.nca can now
  calculate urine/feces-related parameters (fe, ae, clr)
* exclude_nca* functions added (Fixes issue #20)
* Add manual half-life point selection (Fixes issue #18)
* Improved summary settings (Fixes issue #54)
* Add parameters for Ceoi and intravenous MRT
* Updated vignettes to improve clarity
* Added dose-normalized PK parameters (Fixes issue #41)
* Added checks to confirm that concentration and time are numeric
  (Fixes feature request #40)
* Improved test coverage

# PKNCA 0.8.1

* A PKNCAdose is no longer required for calculations.
* Data may now be excluded from calculations.

# PKNCA 0.8

This release is not backward compatible.  The switch to observed and
predicted-related NCA parameters (like aucinf.obs and aucinf.pred)
changed the format of the intervals specification.

* Remove dependency on doBy library
* Dose-aware interpolation and extrapolation was added with the interp.extrap.conc.dose function.
* Added Clast.pred related NCA calculations
* Added N to summary of PKNCAresults
* Added parameter selection between Clast,observed and Clast,predicted across all parameters
* Enabled PKNCAdose to be specified with one-sided formula
* Improved error reporting so that the group and time (interval specification) is reported in addition to the error.
* PKNCAdose now allows route of administration and IV infusion parameters of rate/duration to be specified

# PKNCA 0.7.1

* Updated vignettes
* Standardize rounding and significance with missing values in signifString and roundString
* Enable wide data output with as.data.frame(PKNCAresults, out.format="wide")
* Correct calculation of Vz
* Various CRAN-related cleanups

# PKNCA 0.7

* Features added
  * Additional PK parameters to support IV dosing added
  * Fix #11, Intervals can be specified manually, and will apply across appropriate parts of the grouping variables
  * Enable dose and dose.time as parameters to NCA calculations
  * More NCA parameters are calculated, especially related to IV dosing
  * Fix #8, Reporting times for time-based parameters are now within the current interval rather than since first dose (e.g. Tmax on day 14 should be between 0 and 24 not 2*7*24+c(0, 24))
  * Added several vignettes
* Bugs fixed
  * Dosing without concentration is probably placebo; warn and continue
  * Fix #6, make merge.splitByData work with more than one dosing level
  * Export some generic classes that were not previously exported to simplify their use
  * Superposition extensions when lambda.z cannot be calculated
  * Significance rounding into character strings works when the rounding moves up one order of magnitude.
  * Fix #9, summarization of parameters that are not calculated show not calculated instead of missing.

# PKNCA 0.6

First release targeting CRAN
