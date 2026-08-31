# Writing PKNCA Parameter Functions

## Writing PKNCA Parameter Functions

The PKNCA package is designed to be comprehensive in its coverage of the
needs of an noncompartmental analysis (NCA) specialist. While it has
many NCA parameters specified, it may not have all parameters defined,
and its design is modular to accept new parameter definitions. From its
inception, PKNCA is built in modules to allow addition of new components
(or removal of unnecessary ones). Defining new NCA parameters is
straight-forward, and this guide will describe how it is done. The three
parts to writing a new NCA parameter in PKNCA are described below.

## Writing the Parameter Function

### Requirements

The starting point to writing a new NCA parameter is writing the
function that calculates the parameter value. The function can be passed
any of the following arguments. The arguments must be named as described
below:

- `conc` is the numeric vector of plasma concentrations for an interval
  for a single group (usually a single analyte for a single subject in a
  single study).
- `time` is the numeric vector of the time for plasma concentration
  measurements.
- `duration.conc` is the duration of a concentration measurement
  (usually for urine or fecal measurements)
- `dose` is the numeric vector of dose amounts for an interval for a
  single group. NOTE: This is a vector and not always a scalar. If your
  function expects a scalar, you should usually take the sum of the dose
  argument.
- `time.dose` is the numeric vector of time for the doses.
- `duration.dose` is the duration of a dose (usually for intravenous
  infusions)
- `start` and `end` are the scalar numbers for the start and end time of
  the current interval. NOTE: `end` may be `Inf` (infinity).
- `options` are the PKNCA options used for the current calculation
  usually as defined by the `PKNCA.options` function (though these
  options may be over-ridden by the `options` argument to the
  `PKNCAdata` function.
- Or, any NCA parameters by name (as given by
  `names(get.interval.cols())`).

The function should return either a scalar which is the value for the
parameter (usually the case) or a data.frame with parameters named for
each parameter calculated. For an example of returning a data.frame, see
the `half.life` function.

The return value may have an attribute of `exclude` (set by
`attr(return_value, "exclude") <- "reason"`). If the `exclude` attribute
is set to a character string, then that string will be included in the
`exclude` column for results. If any of the input parameters have an
exclude attribute set, then those are also added to the `exclude`
column. The exception to the setting of the `exclude` column is if the
`exclude` attribute is `"DO NOT EXCLUDE"`, then the `exclude` column is
set to `NA_character_`.

### Best Practices

- Use the function `assert_conc_time` if the function takes either
  `conc` or `time` as an input.
- Make sure that you check for missing values (`NA`) in your inputs.
- Don’t recalculate other NCA parameters within your function unless you
  absolutely must. Take the NCA parameter as an input. That way, PKNCA
  will track the calculation dependencies.
- For consistency with the rest of PKNCA, start the function name with
  “pk.calc” (like “pk.calc.cmax”).

## Tell PKNCA about the Parameter

Just writing a function doesn’t connect it to the rest of PKNCA. You
have to tell PKNCA that the function exists and a few more details about
it. To do this, you need to use the `add.interval.col` function. The
function takes up to seven arguments:

- `name` is the name of the parameter (as a character string).
- `FUN` is the function name (as a character string).
- `values` are the possible values for the interval column (currently
  only `TRUE` and `FALSE` are supported).
- `depends` is a character vector of columns that must exist before this
  column can be created. Use this to tell PKNCA about calculation
  dependencies (parameter X must be calculated to be able to calculate
  parameter Y).
- `formalsmap` remaps the (formal) function arguments. `formalsmap` is
  usually used when the same function may be used for multiple different
  parameters, for example the function `pk.calc.thalf.eff` is used to
  calculate the parameters `thalf.eff.obs`, `thalf.eff.pred`,
  `thalf.eff.last`, `thalf.eff.iv.obs`, `thalf.eff.iv.pred`, and
  `thalf.eff.iv.last` with different mean residence time inputs.
- `desc` is a text description of the parameter.

### Passing a Constant with `formalsmap`

A `formalsmap` value is normally the name of an NCA parameter or of one
of the data inputs (`"conc"`, `"time"`, `"dose"`, and the rest listed in
[`help("add.interval.col")`](https://humanpred.github.io/pknca/reference/add.interval.col.md)).
Wrapping the value in [`I()`](https://rdrr.io/r/base/AsIs.html) passes
it to the function unchanged instead of looking it up:

    formalsmap = list(auc="aucall", auc.type=I("AUCall"))

Use this when one function serves several parameters and an argument
selects which variant to calculate. `pk.calc.auciv` is shared by all six
IV AUC parameters, and each registration names its own `auc.type`:

    add.interval.col(
      name = "aucivlast",
      FUN = "pk.calc.auciv",
      unit_type = "auc",
      pretty_name = "AUClast (IV dosing)",
      depends = c("auclast", "c0"),
      desc = "AUClast, IV back-extrap C0",
      formalsmap = list(auc="auclast", auc.type=I("AUClast"), lambda.z=NULL, clast=NULL)
    )

Without [`I()`](https://rdrr.io/r/base/AsIs.html), `"AUCall"` would be
looked up as a parameter name, not found, and the argument would
silently keep its default.

Two related points:

- A constant is not a calculation dependency, so it does not appear in
  `get.parameter.deps(recursive=TRUE)` and does not affect whether PKNCA
  reports the parameter as needing dose or volume information.
- Mapping an argument to `NULL` (as with `lambda.z` and `clast` above)
  drops it from the call so that it keeps its default. Do this for any
  argument whose name matches an NCA parameter that this parameter does
  not use. An argument named `lambda.z` that is left out of the
  `formalsmap` is filled from the calculated `lambda.z` when one exists,
  and otherwise from the interval column of the same name, which is the
  `TRUE`/`FALSE` requesting the parameter rather than a value.

### Parameters That Need Another Interval

A few parameters cannot be calculated from one interval of one profile.
Renal clearance divides an amount excreted into a urine collection by
the plasma AUC over the same times, and bioavailability compares two
administrations. Wrapping a `formalsmap` value in `pknca_ref` says that
the argument takes its value from the *reference* interval – the one
named by the `<parameter>_ref` column of the interval specification –
instead of from the interval being calculated:

    add.interval.col("clr.last",
                     FUN="pk.calc.clr",
                     values=c(FALSE, TRUE),
                     unit_type="renal_clearance",
                     pretty_name="Renal clearance (from AUClast)",
                     formalsmap=list(auc=pknca_ref("auclast")),
                     depends="ae",
                     desc="Renal clearance, AUClast",
                     selection = list(secondary = TRUE))

A `pknca_ref` anywhere in the `formalsmap` makes the parameter
*secondary*, whether or not `selection` says so. `pknca_parameter_table`
reports which parameters are secondary, and the vignette “Secondary
Parameters”
([`vignette("v09-secondary-parameters", package="PKNCA")`](https://humanpred.github.io/pknca/articles/v09-secondary-parameters.md))
covers requesting and linking them.

A secondary parameter is calculated after every interval has been
calculated, from the results rather than from the concentrations, so its
function may take only NCA parameter values as inputs. That imposes two
requirements, which `add.interval.col` does not check when the parameter
is registered (the parameters it names may not be registered yet) but
which are checked, with an error naming the parameter, the first time it
is calculated:

- Every formal of the function other than `...` must be covered: either
  it is named in the `formalsmap`, or it is itself the name of a
  registered NCA parameter and is filled from the interval being
  calculated. A formal that is neither – `conc`, `time`, `options`, or a
  name of your own – cannot be filled, because the data and the options
  are no longer at hand. [`I()`](https://rdrr.io/r/base/AsIs.html)
  constants and `NULL` mappings work as they do for any parameter, since
  neither needs a value looked up.
- Every argument taken from the interval being calculated must be listed
  in `depends`, so that it is calculated there before the secondary
  calculation reads it. In the registration above, `ae` is a formal of
  `pk.calc.clr` named after a parameter, so it is filled from the
  interval calculating `clr.last` and appears in `depends`. `auc` comes
  from the reference interval and does not.

Exclusions cross the link with no help from the function. As for any
parameter, the `exclude` reasons of all of the inputs – from either
interval – are joined with `"; "`, the `exclude` attribute the function
set on its own return value is added to them, and `"DO NOT EXCLUDE"` on
the return value clears all of them. An excluded plasma AUC therefore
cannot quietly become a reported renal clearance.

Units are the one thing a new secondary parameter does not get for free.
Where units are given per group, the two intervals can report theirs
differently, and `pknca_units_table` composes the units of
`pk.calc.clr`, `pk.calc.ratio`, and `pk.calc.f` from both sides for that
reason. A parameter built on a calculation function of your own is given
the units of its `unit_type` under its own interval’s group, as any
primary parameter is; supply a `units` table to `PKNCAdata` if that is
not what its two sides mean.

## Tell PKNCA How to Summarize the Parameter

For any parameter, PKNCA needs to know how to summarize it for the
`summary` function of the `PKNCAresults` class. To tell PKNCA how to
summarize a parameter, use the `PKNCA.set.summary` function. It takes at
least these four arguments:

- `name` must match an already existing parameter name (added by the
  `add.interval.col` function).
- `description` is a human-readable description of the `point` and
  `spread` for use in table captions.
- `point` is the function to calculate the point estimate (called as
  `point(x)`, and it must return a scalar).
- `spread` is the function to calculate the spread (or variability). The
  function will be called as `spread(x)` and must return a scalar or a
  two-long vector.

## Putting It Together

One of the most common examples is the function to calculate C_(max):

    #' Determine maximum observed PK concentration
    #'
    #' @inheritParams assert_conc_time
    #' @param check Run \code{\link{assert_conc_time}}?
    #' @return a number for the maximum concentration or NA if all
    #' concentrations are missing
    #' @export
    pk.calc.cmax <- function(conc, check=TRUE) {
      if (check)
        assert_conc_time(conc=conc)
      if (length(conc) == 0 | all(is.na(conc))) {
        NA
      } else {
        max(conc, na.rm=TRUE)
      }
    }
    ## Add the column to the interval specification
    add.interval.col("cmax",
                     FUN="pk.calc.cmax",
                     values=c(FALSE, TRUE),
                     unit_type="conc",
                     pretty_name="Cmax",
                     desc="Maximum observed concentration",
                     depends=c())
    PKNCA.set.summary("cmax", "geometric mean and geometric coefficient of variation", business.geomean, business.geocv)
