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
  datatype = c("interval", "individual", "population")
)
```

## Arguments

- name:

  The column name as a character string

- FUN:

  The function to run (as a character string) or `NA` if the parameter
  is automatically calculated when calculating another parameter.

- values:

  Valid values for the column

- unit_type:

  The type of units to use for assigning and converting units.

- pretty_name:

  The name of the parameter to use for printing in summary tables with
  units. (If an analysis does not include units, then the normal name is
  used.)

- depends:

  Character vector of columns that must be run before this column.

- desc:

  A human-readable description of the parameter (\<=40 characters to
  comply with SDTM)

- sparse:

  Is the calculation for sparse PK?

- formalsmap:

  A named list mapping parameter names in the function call to NCA
  parameter names. See the details for information on use of
  `formalsmap`.

- datatype:

  The type of data used for the calculation

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

## See also

Other Interval specifications:
[`check.interval.deps()`](http://humanpred.github.io/pknca/reference/check.interval.deps.md),
[`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](http://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.interval.cols()`](http://humanpred.github.io/pknca/reference/get.interval.cols.md),
[`get.parameter.deps()`](http://humanpred.github.io/pknca/reference/get.parameter.deps.md)

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
