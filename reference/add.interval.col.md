# Add columns for calculations within PKNCA intervals

Add columns for calculations within PKNCA intervals

## Usage

``` r
add.interval.col(
  name,
  FUN,
  values = c(FALSE, TRUE),
  unit_type,
  pretty_name,
  depends = NULL,
  desc = "",
  sparse = FALSE,
  formalsmap = list(),
  datatype = c("interval", "individual", "population"),
  pptestcd_cdisc = NULL,
  pptest_cdisc = NULL,
  formula = NULL,
  formula_note = NULL,
  tier = "uncommon",
  selection = NULL
)
```

## Arguments

- name:

  The column name as a non-empty character string (length 1, may not be
  `NA` or `""`).

- FUN:

  The function to run (as a character string) or `NA` if the parameter
  is automatically calculated when calculating another parameter.

- values:

  Valid values for the column: either a function used to coerce/validate
  values (e.g. `as.numeric`) or a vector of allowed values (e.g.
  `c(FALSE, TRUE)`).

- unit_type:

  The type of units to use for assigning and converting units. Must be
  one of the pre-defined unit types (see Details). This argument is
  required and has no default; omitting it raises an error.

- pretty_name:

  The name of the parameter to use for printing in summary tables with
  units. (If an analysis does not include units, then the normal name is
  used.)

- depends:

  Character vector of columns that must be run before this column.

- desc:

  A human-readable description of the parameter. SDTM requires \<=40
  characters; a longer description is accepted with a warning.

- sparse:

  Is the calculation for sparse PK?

- formalsmap:

  A named list mapping parameter names in the function call to NCA
  parameter names. See the details for information on use of
  `formalsmap`.

- datatype:

  The data type used for the calculation. The default is `"interval"`,
  which is currently the only supported value. The `"individual"` and
  `"population"` data types are reserved for future use and will
  currently raise an error if selected.

- pptestcd_cdisc:

  The CDISC PPTESTCD code for this parameter. Can be a character string
  for simple mappings, or a named list for route-dependent mappings with
  a `route` element whose value is itself a named list keyed by route
  (e.g.
  `list(route = list(extravascular = "CLF/FO", intravascular = "CLO"))`).
  Defaults to `name` if not provided.

- pptest_cdisc:

  The CDISC PPTEST name for this parameter. Can be a character string or
  a named list (same structure as `pptestcd_cdisc`). Defaults to `desc`
  if not provided.

- formula:

  Character value providing a LaTeX expression for how the parameter is
  calculated. Optional and used only for documentation.

- formula_note:

  Character value providing additional context about the formula (e.g.
  assumptions or method details). Displayed alongside the formula in
  documentation tables.

- tier:

  How commonly the parameter is reported: `"common"` for one that
  belongs in a default report for at least one context, or `"uncommon"`
  (the default) for one that is calculated only when asked for by name.
  See
  [`pknca_tiers()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md).

- selection:

  A named list declaring what cannot be derived about where the
  parameter applies. Every element is optional, and the default of
  `NULL` derives everything:

  `concept`

  :   The kind of quantity the parameter is (see
      [`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md)).
      Needed only when the calculation function carries no
      [`pknca_concept()`](https://humanpred.github.io/pknca/reference/pknca_concept.md)
      and the concept cannot be taken from `depends`.

  `route`

  :   The routes of administration the parameter applies to (see
      [`pknca_routes()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md)).
      Derived as intravenous for anything calculated from `c0` or
      needing a dose duration, and as any route otherwise.

  `dosing`

  :   The dosing patterns the parameter applies to (see
      [`pknca_dosing()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md)).
      Derived as single-dose for anything calculated from an
      extrapolation to infinity. A declared value propagates to every
      parameter calculated from this one.

  `secondary`

  :   `TRUE` for a parameter that needs inputs from more than one
      profile, such as bioavailability, which compares two
      administrations, or renal clearance, which needs an amount
      excreted and a plasma AUC. One interval cannot supply those, so a
      secondary parameter is never chosen automatically; it stays
      available by name. A declared value propagates to every parameter
      calculated from this one.

## Value

NULL (Calling this function has a side effect of changing the available
intervals for calculations)

## Details

The `formalsmap` argument enables mapping some alternate formal argument
names to parameters. It is used to generalize functions that may use
multiple similar arguments (such as the variants of mean residence
time). The names of the list should correspond to function formal
parameter names and the values should be one of the following:

- For the current interval:

  - character strings of NCA parameter name:

    The value of the parameter calculated for the current interval.

  - "conc":

    Concentration measurements for the current interval.

  - "time":

    Times associated with concentration measurements for the current
    interval (values start at 0 at the beginning of the current
    interval).

  - "volume":

    Volume associated with concentration measurements for the current
    interval (typically applies for excretion parameters like urine).

  - "duration.conc":

    Durations associated with concentration measurements for the current
    interval.

  - "dose":

    Dose amounts assocuated with the current interval.

  - "time.dose":

    Time of dose start associated with the current interval (values
    start at 0 at the beginning of the current interval).

  - "duration.dose":

    Duration of dose (typically infusion duration) for doses in the
    current interval.

  - "route":

    Route of dosing for the current interval.

  - "start":

    Time of interval start.

  - "end":

    Time of interval end.

  - "options":

    PKNCA.options governing calculations.

- For the current group:

  - "conc.group":

    Concentration measurements for the current group.

  - "time.group":

    Times associated with concentration measurements for the current
    group (values start at 0 at the beginning of the current interval).

  - "volume.group":

    Volume associated with concentration measurements for the current
    interval (typically applies for excretion parameters like urine).

  - "duration.conc.group":

    Durations assocuated with concentration measurements for the current
    group.

  - "dose.group":

    Dose amounts assocuated with the current group.

  - "time.dose.group":

    Time of dose start associated with the current group (values start
    at 0 at the beginning of the current interval).

  - "duration.dose.group":

    Duration of dose (typically infusion duration) for doses in the
    current group.

  - "route.group":

    Route of dosing for the current group.

- Constants:

  - a value wrapped in [`base::I()`](https://rdrr.io/r/base/AsIs.html):

    The value itself, passed to the function unchanged. Use this for an
    argument that selects a variant of a shared calculation function
    (for example, `auc.type = I("AUCall")`) rather than naming a data
    source or another parameter.

## See also

Other Interval specifications:
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](https://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](https://humanpred.github.io/pknca/reference/get.parameter.deps.md),
[`interval_add_impute()`](https://humanpred.github.io/pknca/reference/interval_add_impute.md),
[`interval_add_param()`](https://humanpred.github.io/pknca/reference/interval_add_param.md),
[`pknca_check_parameter_classification()`](https://humanpred.github.io/pknca/reference/pknca_check_parameter_classification.md),
[`pknca_concepts()`](https://humanpred.github.io/pknca/reference/pknca_concepts.md),
[`pknca_interval_table()`](https://humanpred.github.io/pknca/reference/pknca_interval_table.md),
[`pknca_parameter_table()`](https://humanpred.github.io/pknca/reference/pknca_parameter_table.md),
[`pknca_presets()`](https://humanpred.github.io/pknca/reference/pknca_presets.md)

## Examples

``` r
if (FALSE) { # \dontrun{
add.interval.col("cmax",
                 FUN="pk.calc.cmax",
                 values=c(FALSE, TRUE),
                 unit_type="conc",
                 pretty_name="Cmax",
                 desc="Maximum observed concentration")
add.interval.col("cmax.dn",
                 FUN="pk.calc.dn",
                 values=c(FALSE, TRUE),
                 unit_type="conc_dosenorm",
                 pretty_name="Cmax (dose-normalized)",
                 desc="Maximum observed concentration, dose normalized",
                 formalsmap=list(parameter="cmax"),
                 depends="cmax")
} # }
```
