# Methods Used for Dose-Aware Concentration Interpolation/Extrapolation

## Introduction

Interpolation and extrapolation with awareness of doses occurring
before, at the same time of, or after the requested interpolation time
point must account for many interactions. To ensure clarity in the
interpolation/extrapolation methods and the decisions made by the
algorithm, each potential choice is listed below with its accompanying
calculation method. The code used to generate the table is the same as
the code within the function.

## Methods

The method list below is described and sorted in order of how many
scenarios the method is applied to in the list.

For each of the summary tables below, the column headers are as follows:

- **Event Before**: The type of event before the time of the requested
  output may be one of the following
- **Event At**: The equivalent to “Event Before” but for the event
  occurring at the requested output time.
- **Event After**: The equivalent to “Event Before” but for the next
  event occurring after the requested output time.

### Observed concentration

Copy the input concentration at the given time to the output.

| Event Before             | Event At                 | Event After              |
|:-------------------------|:-------------------------|:-------------------------|
| conc                     | conc                     | conc                     |
| conc                     | conc                     | conc_dose                |
| conc                     | conc                     | conc_dose_iv_bolus_after |
| conc                     | conc                     | dose                     |
| conc                     | conc                     | dose_iv_bolus_after      |
| conc                     | conc                     | none                     |
| conc                     | conc_dose                | conc                     |
| conc                     | conc_dose                | conc_dose                |
| conc                     | conc_dose                | conc_dose_iv_bolus_after |
| conc                     | conc_dose                | dose                     |
| conc                     | conc_dose                | dose_iv_bolus_after      |
| conc                     | conc_dose                | none                     |
| conc                     | conc_dose_iv_bolus_after | conc                     |
| conc                     | conc_dose_iv_bolus_after | conc_dose                |
| conc                     | conc_dose_iv_bolus_after | dose                     |
| conc                     | conc_dose_iv_bolus_after | none                     |
| conc_dose                | conc                     | conc                     |
| conc_dose                | conc                     | conc_dose                |
| conc_dose                | conc                     | conc_dose_iv_bolus_after |
| conc_dose                | conc                     | dose                     |
| conc_dose                | conc                     | dose_iv_bolus_after      |
| conc_dose                | conc                     | none                     |
| conc_dose                | conc_dose                | conc                     |
| conc_dose                | conc_dose                | conc_dose                |
| conc_dose                | conc_dose                | conc_dose_iv_bolus_after |
| conc_dose                | conc_dose                | dose                     |
| conc_dose                | conc_dose                | dose_iv_bolus_after      |
| conc_dose                | conc_dose                | none                     |
| conc_dose                | conc_dose_iv_bolus_after | conc                     |
| conc_dose                | conc_dose_iv_bolus_after | conc_dose                |
| conc_dose                | conc_dose_iv_bolus_after | dose                     |
| conc_dose                | conc_dose_iv_bolus_after | none                     |
| conc_dose_iv_bolus_after | conc                     | conc                     |
| conc_dose_iv_bolus_after | conc                     | conc_dose                |
| conc_dose_iv_bolus_after | conc                     | conc_dose_iv_bolus_after |
| conc_dose_iv_bolus_after | conc                     | dose                     |
| conc_dose_iv_bolus_after | conc                     | dose_iv_bolus_after      |
| conc_dose_iv_bolus_after | conc                     | none                     |
| conc_dose_iv_bolus_after | conc_dose                | conc                     |
| conc_dose_iv_bolus_after | conc_dose                | conc_dose                |
| conc_dose_iv_bolus_after | conc_dose                | conc_dose_iv_bolus_after |
| conc_dose_iv_bolus_after | conc_dose                | dose                     |
| conc_dose_iv_bolus_after | conc_dose                | dose_iv_bolus_after      |
| conc_dose_iv_bolus_after | conc_dose                | none                     |
| dose                     | conc                     | conc                     |
| dose                     | conc                     | conc_dose                |
| dose                     | conc                     | conc_dose_iv_bolus_after |
| dose                     | conc                     | dose                     |
| dose                     | conc                     | dose_iv_bolus_after      |
| dose                     | conc                     | none                     |
| dose                     | conc_dose                | conc                     |
| dose                     | conc_dose                | conc_dose                |
| dose                     | conc_dose                | conc_dose_iv_bolus_after |
| dose                     | conc_dose                | dose                     |
| dose                     | conc_dose                | dose_iv_bolus_after      |
| dose                     | conc_dose                | none                     |
| dose                     | conc_dose_iv_bolus_after | conc                     |
| dose                     | conc_dose_iv_bolus_after | conc_dose                |
| dose                     | conc_dose_iv_bolus_after | dose                     |
| dose                     | conc_dose_iv_bolus_after | none                     |
| dose_iv_bolus_after      | conc                     | conc                     |
| dose_iv_bolus_after      | conc                     | conc_dose                |
| dose_iv_bolus_after      | conc                     | conc_dose_iv_bolus_after |
| dose_iv_bolus_after      | conc                     | dose                     |
| dose_iv_bolus_after      | conc                     | dose_iv_bolus_after      |
| dose_iv_bolus_after      | conc                     | none                     |
| dose_iv_bolus_after      | conc_dose                | conc                     |
| dose_iv_bolus_after      | conc_dose                | conc_dose                |
| dose_iv_bolus_after      | conc_dose                | conc_dose_iv_bolus_after |
| dose_iv_bolus_after      | conc_dose                | dose                     |
| dose_iv_bolus_after      | conc_dose                | dose_iv_bolus_after      |
| dose_iv_bolus_after      | conc_dose                | none                     |
| none                     | conc                     | conc                     |
| none                     | conc                     | conc_dose                |
| none                     | conc                     | conc_dose_iv_bolus_after |
| none                     | conc                     | dose                     |
| none                     | conc                     | dose_iv_bolus_after      |
| none                     | conc                     | none                     |
| none                     | conc_dose                | conc                     |
| none                     | conc_dose                | conc_dose                |
| none                     | conc_dose                | conc_dose_iv_bolus_after |
| none                     | conc_dose                | dose                     |
| none                     | conc_dose                | dose_iv_bolus_after      |
| none                     | conc_dose                | none                     |
| none                     | conc_dose_iv_bolus_after | conc                     |
| none                     | conc_dose_iv_bolus_after | conc_dose                |
| none                     | conc_dose_iv_bolus_after | dose                     |
| none                     | conc_dose_iv_bolus_after | none                     |

### Impossible combinations

The event combination cannot exist.

| Event Before             | Event At                 | Event After              |
|:-------------------------|:-------------------------|:-------------------------|
| conc                     | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after |
| conc                     | conc_dose_iv_bolus_after | dose_iv_bolus_after      |
| conc                     | dose_iv_bolus_after      | conc_dose_iv_bolus_after |
| conc                     | dose_iv_bolus_after      | dose_iv_bolus_after      |
| conc                     | output_only              | conc_dose_iv_bolus_after |
| conc                     | output_only              | dose_iv_bolus_after      |
| conc_dose                | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after |
| conc_dose                | conc_dose_iv_bolus_after | dose_iv_bolus_after      |
| conc_dose                | dose_iv_bolus_after      | conc_dose_iv_bolus_after |
| conc_dose                | dose_iv_bolus_after      | dose_iv_bolus_after      |
| conc_dose                | output_only              | conc_dose_iv_bolus_after |
| conc_dose                | output_only              | dose_iv_bolus_after      |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | conc                     |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | conc_dose                |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | dose                     |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | dose_iv_bolus_after      |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | none                     |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | conc                     |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | conc_dose                |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | conc_dose_iv_bolus_after |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | dose                     |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | dose_iv_bolus_after      |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | none                     |
| conc_dose_iv_bolus_after | output_only              | conc_dose_iv_bolus_after |
| conc_dose_iv_bolus_after | output_only              | dose_iv_bolus_after      |
| dose                     | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after |
| dose                     | conc_dose_iv_bolus_after | dose_iv_bolus_after      |
| dose                     | dose_iv_bolus_after      | conc_dose_iv_bolus_after |
| dose                     | dose_iv_bolus_after      | dose_iv_bolus_after      |
| dose                     | output_only              | conc_dose_iv_bolus_after |
| dose                     | output_only              | dose_iv_bolus_after      |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | conc                     |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | conc_dose                |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | dose                     |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | dose_iv_bolus_after      |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | none                     |
| dose_iv_bolus_after      | dose_iv_bolus_after      | conc                     |
| dose_iv_bolus_after      | dose_iv_bolus_after      | conc_dose                |
| dose_iv_bolus_after      | dose_iv_bolus_after      | conc_dose_iv_bolus_after |
| dose_iv_bolus_after      | dose_iv_bolus_after      | dose                     |
| dose_iv_bolus_after      | dose_iv_bolus_after      | dose_iv_bolus_after      |
| dose_iv_bolus_after      | dose_iv_bolus_after      | none                     |
| dose_iv_bolus_after      | output_only              | conc_dose_iv_bolus_after |
| dose_iv_bolus_after      | output_only              | dose_iv_bolus_after      |
| none                     | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after |
| none                     | conc_dose_iv_bolus_after | dose_iv_bolus_after      |
| none                     | dose_iv_bolus_after      | conc_dose_iv_bolus_after |
| none                     | dose_iv_bolus_after      | dose_iv_bolus_after      |
| none                     | output_only              | conc_dose_iv_bolus_after |
| none                     | output_only              | dose_iv_bolus_after      |

### Doses with no concentrations between

Two doses with no concentrations between them, return NA.

| Event Before | Event At    | Event After              |
|:-------------|:------------|:-------------------------|
| conc_dose    | dose        | conc                     |
| conc_dose    | dose        | conc_dose                |
| conc_dose    | dose        | conc_dose_iv_bolus_after |
| conc_dose    | dose        | dose                     |
| conc_dose    | dose        | dose_iv_bolus_after      |
| conc_dose    | dose        | none                     |
| conc_dose    | output_only | conc_dose                |
| conc_dose    | output_only | dose                     |
| dose         | dose        | conc                     |
| dose         | dose        | conc_dose                |
| dose         | dose        | conc_dose_iv_bolus_after |
| dose         | dose        | dose                     |
| dose         | dose        | dose_iv_bolus_after      |
| dose         | dose        | none                     |
| dose         | output_only | conc_dose                |
| dose         | output_only | dose                     |

### Extrapolation

Extrapolate from a concentration to a dose

| Event Before             | Event At    | Event After              |
|:-------------------------|:------------|:-------------------------|
| conc                     | dose        | conc                     |
| conc                     | dose        | conc_dose                |
| conc                     | dose        | conc_dose_iv_bolus_after |
| conc                     | dose        | dose                     |
| conc                     | dose        | dose_iv_bolus_after      |
| conc                     | dose        | none                     |
| conc                     | output_only | dose                     |
| conc                     | output_only | none                     |
| conc_dose_iv_bolus_after | dose        | conc                     |
| conc_dose_iv_bolus_after | dose        | conc_dose                |
| conc_dose_iv_bolus_after | dose        | conc_dose_iv_bolus_after |
| conc_dose_iv_bolus_after | dose        | dose                     |
| conc_dose_iv_bolus_after | dose        | dose_iv_bolus_after      |
| conc_dose_iv_bolus_after | dose        | none                     |
| conc_dose_iv_bolus_after | output_only | dose                     |
| conc_dose_iv_bolus_after | output_only | none                     |

### Immediately after an IV bolus without a concentration next

Cannot calculate C0 without a concentration after an IV bolus; return
NA.

| Event Before        | Event At            | Event After              |
|:--------------------|:--------------------|:-------------------------|
| conc                | dose_iv_bolus_after | dose                     |
| conc                | dose_iv_bolus_after | none                     |
| conc_dose           | dose_iv_bolus_after | dose                     |
| conc_dose           | dose_iv_bolus_after | none                     |
| dose                | dose_iv_bolus_after | dose                     |
| dose                | dose_iv_bolus_after | none                     |
| dose_iv_bolus_after | dose                | conc                     |
| dose_iv_bolus_after | dose                | conc_dose                |
| dose_iv_bolus_after | dose                | conc_dose_iv_bolus_after |
| dose_iv_bolus_after | dose                | dose                     |
| dose_iv_bolus_after | dose                | dose_iv_bolus_after      |
| dose_iv_bolus_after | dose                | none                     |
| none                | dose_iv_bolus_after | dose                     |
| none                | dose_iv_bolus_after | none                     |

### Before all events

Interpolation before any events is NA or zero (0) depending on the value
of conc.origin. conc.origin defaults to zero which is the implicit
assumption that a complete washout occurred and there is no endogenous
source of the analyte.

| Event Before | Event At    | Event After              |
|:-------------|:------------|:-------------------------|
| none         | dose        | conc                     |
| none         | dose        | conc_dose                |
| none         | dose        | conc_dose_iv_bolus_after |
| none         | dose        | dose                     |
| none         | dose        | dose_iv_bolus_after      |
| none         | dose        | none                     |
| none         | output_only | conc                     |
| none         | output_only | conc_dose                |
| none         | output_only | dose                     |
| none         | output_only | none                     |

### Immediately after an IV bolus with a concentration next

Calculate C0 for the time immediately after an IV bolus. First, attempt
using log slope back-extrapolation. If that fails, use the first
concentration after the dose as C0.

| Event Before | Event At            | Event After |
|:-------------|:--------------------|:------------|
| conc         | dose_iv_bolus_after | conc        |
| conc         | dose_iv_bolus_after | conc_dose   |
| conc_dose    | dose_iv_bolus_after | conc        |
| conc_dose    | dose_iv_bolus_after | conc_dose   |
| dose         | dose_iv_bolus_after | conc        |
| dose         | dose_iv_bolus_after | conc_dose   |
| none         | dose_iv_bolus_after | conc        |
| none         | dose_iv_bolus_after | conc_dose   |

### Interpolation

With concentrations before and after and not an IV bolus before,
interpolate between observed concentrations.

| Event Before             | Event At    | Event After |
|:-------------------------|:------------|:------------|
| conc                     | output_only | conc        |
| conc                     | output_only | conc_dose   |
| conc_dose                | output_only | conc        |
| conc_dose_iv_bolus_after | output_only | conc        |
| conc_dose_iv_bolus_after | output_only | conc_dose   |

### After an IV bolus with a concentration next

First, calculate C0 using log slope back-extrapolation (falling back to
the first post-dose concentration if that fails). Then, interpolate
between C0 and the first post-dose concentration.

| Event Before        | Event At    | Event After |
|:--------------------|:------------|:------------|
| dose_iv_bolus_after | output_only | conc        |
| dose_iv_bolus_after | output_only | conc_dose   |

### After an IV bolus without a concentration next

Between an IV bolus and anything other than a concentration,
interpolation cannot occur. Return NA

| Event Before        | Event At    | Event After |
|:--------------------|:------------|:------------|
| dose_iv_bolus_after | output_only | dose        |
| dose_iv_bolus_after | output_only | none        |

### Dose as the last event in the timeline and requesting a concentration after

Cannot estimate the concentration after a dose without concentrations
after the dose, return NA.

| Event Before | Event At    | Event After |
|:-------------|:------------|:------------|
| conc_dose    | output_only | none        |
| dose         | output_only | none        |

### Dose before, concentration after without a dose

If the concentration at the dose is estimable, interpolate. Otherwise,
NA.

| Event Before | Event At    | Event After |
|:-------------|:------------|:------------|
| dose         | output_only | conc        |

## Appendix: Complete Methods Table

| Event Before             | Event At                 | Event After              | Method Used                                                                 |
|:-------------------------|:-------------------------|:-------------------------|:----------------------------------------------------------------------------|
| conc                     | conc                     | conc                     | Observed concentration                                                      |
| conc                     | conc                     | conc_dose                | Observed concentration                                                      |
| conc                     | conc                     | conc_dose_iv_bolus_after | Observed concentration                                                      |
| conc                     | conc                     | dose                     | Observed concentration                                                      |
| conc                     | conc                     | dose_iv_bolus_after      | Observed concentration                                                      |
| conc                     | conc                     | none                     | Observed concentration                                                      |
| conc                     | conc_dose                | conc                     | Observed concentration                                                      |
| conc                     | conc_dose                | conc_dose                | Observed concentration                                                      |
| conc                     | conc_dose                | conc_dose_iv_bolus_after | Observed concentration                                                      |
| conc                     | conc_dose                | dose                     | Observed concentration                                                      |
| conc                     | conc_dose                | dose_iv_bolus_after      | Observed concentration                                                      |
| conc                     | conc_dose                | none                     | Observed concentration                                                      |
| conc                     | conc_dose_iv_bolus_after | conc                     | Observed concentration                                                      |
| conc                     | conc_dose_iv_bolus_after | conc_dose                | Observed concentration                                                      |
| conc                     | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| conc                     | conc_dose_iv_bolus_after | dose                     | Observed concentration                                                      |
| conc                     | conc_dose_iv_bolus_after | dose_iv_bolus_after      | Impossible combinations                                                     |
| conc                     | conc_dose_iv_bolus_after | none                     | Observed concentration                                                      |
| conc                     | dose                     | conc                     | Extrapolation                                                               |
| conc                     | dose                     | conc_dose                | Extrapolation                                                               |
| conc                     | dose                     | conc_dose_iv_bolus_after | Extrapolation                                                               |
| conc                     | dose                     | dose                     | Extrapolation                                                               |
| conc                     | dose                     | dose_iv_bolus_after      | Extrapolation                                                               |
| conc                     | dose                     | none                     | Extrapolation                                                               |
| conc                     | dose_iv_bolus_after      | conc                     | Immediately after an IV bolus with a concentration next                     |
| conc                     | dose_iv_bolus_after      | conc_dose                | Immediately after an IV bolus with a concentration next                     |
| conc                     | dose_iv_bolus_after      | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| conc                     | dose_iv_bolus_after      | dose                     | Immediately after an IV bolus without a concentration next                  |
| conc                     | dose_iv_bolus_after      | dose_iv_bolus_after      | Impossible combinations                                                     |
| conc                     | dose_iv_bolus_after      | none                     | Immediately after an IV bolus without a concentration next                  |
| conc                     | output_only              | conc                     | Interpolation                                                               |
| conc                     | output_only              | conc_dose                | Interpolation                                                               |
| conc                     | output_only              | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| conc                     | output_only              | dose                     | Extrapolation                                                               |
| conc                     | output_only              | dose_iv_bolus_after      | Impossible combinations                                                     |
| conc                     | output_only              | none                     | Extrapolation                                                               |
| conc_dose                | conc                     | conc                     | Observed concentration                                                      |
| conc_dose                | conc                     | conc_dose                | Observed concentration                                                      |
| conc_dose                | conc                     | conc_dose_iv_bolus_after | Observed concentration                                                      |
| conc_dose                | conc                     | dose                     | Observed concentration                                                      |
| conc_dose                | conc                     | dose_iv_bolus_after      | Observed concentration                                                      |
| conc_dose                | conc                     | none                     | Observed concentration                                                      |
| conc_dose                | conc_dose                | conc                     | Observed concentration                                                      |
| conc_dose                | conc_dose                | conc_dose                | Observed concentration                                                      |
| conc_dose                | conc_dose                | conc_dose_iv_bolus_after | Observed concentration                                                      |
| conc_dose                | conc_dose                | dose                     | Observed concentration                                                      |
| conc_dose                | conc_dose                | dose_iv_bolus_after      | Observed concentration                                                      |
| conc_dose                | conc_dose                | none                     | Observed concentration                                                      |
| conc_dose                | conc_dose_iv_bolus_after | conc                     | Observed concentration                                                      |
| conc_dose                | conc_dose_iv_bolus_after | conc_dose                | Observed concentration                                                      |
| conc_dose                | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| conc_dose                | conc_dose_iv_bolus_after | dose                     | Observed concentration                                                      |
| conc_dose                | conc_dose_iv_bolus_after | dose_iv_bolus_after      | Impossible combinations                                                     |
| conc_dose                | conc_dose_iv_bolus_after | none                     | Observed concentration                                                      |
| conc_dose                | dose                     | conc                     | Doses with no concentrations between                                        |
| conc_dose                | dose                     | conc_dose                | Doses with no concentrations between                                        |
| conc_dose                | dose                     | conc_dose_iv_bolus_after | Doses with no concentrations between                                        |
| conc_dose                | dose                     | dose                     | Doses with no concentrations between                                        |
| conc_dose                | dose                     | dose_iv_bolus_after      | Doses with no concentrations between                                        |
| conc_dose                | dose                     | none                     | Doses with no concentrations between                                        |
| conc_dose                | dose_iv_bolus_after      | conc                     | Immediately after an IV bolus with a concentration next                     |
| conc_dose                | dose_iv_bolus_after      | conc_dose                | Immediately after an IV bolus with a concentration next                     |
| conc_dose                | dose_iv_bolus_after      | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| conc_dose                | dose_iv_bolus_after      | dose                     | Immediately after an IV bolus without a concentration next                  |
| conc_dose                | dose_iv_bolus_after      | dose_iv_bolus_after      | Impossible combinations                                                     |
| conc_dose                | dose_iv_bolus_after      | none                     | Immediately after an IV bolus without a concentration next                  |
| conc_dose                | output_only              | conc                     | Interpolation                                                               |
| conc_dose                | output_only              | conc_dose                | Doses with no concentrations between                                        |
| conc_dose                | output_only              | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| conc_dose                | output_only              | dose                     | Doses with no concentrations between                                        |
| conc_dose                | output_only              | dose_iv_bolus_after      | Impossible combinations                                                     |
| conc_dose                | output_only              | none                     | Dose as the last event in the timeline and requesting a concentration after |
| conc_dose_iv_bolus_after | conc                     | conc                     | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc                     | conc_dose                | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc                     | conc_dose_iv_bolus_after | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc                     | dose                     | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc                     | dose_iv_bolus_after      | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc                     | none                     | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc_dose                | conc                     | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc_dose                | conc_dose                | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc_dose                | conc_dose_iv_bolus_after | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc_dose                | dose                     | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc_dose                | dose_iv_bolus_after      | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc_dose                | none                     | Observed concentration                                                      |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | conc                     | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | conc_dose                | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | dose                     | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | dose_iv_bolus_after      | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | none                     | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | dose                     | conc                     | Extrapolation                                                               |
| conc_dose_iv_bolus_after | dose                     | conc_dose                | Extrapolation                                                               |
| conc_dose_iv_bolus_after | dose                     | conc_dose_iv_bolus_after | Extrapolation                                                               |
| conc_dose_iv_bolus_after | dose                     | dose                     | Extrapolation                                                               |
| conc_dose_iv_bolus_after | dose                     | dose_iv_bolus_after      | Extrapolation                                                               |
| conc_dose_iv_bolus_after | dose                     | none                     | Extrapolation                                                               |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | conc                     | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | conc_dose                | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | dose                     | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | dose_iv_bolus_after      | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | dose_iv_bolus_after      | none                     | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | output_only              | conc                     | Interpolation                                                               |
| conc_dose_iv_bolus_after | output_only              | conc_dose                | Interpolation                                                               |
| conc_dose_iv_bolus_after | output_only              | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | output_only              | dose                     | Extrapolation                                                               |
| conc_dose_iv_bolus_after | output_only              | dose_iv_bolus_after      | Impossible combinations                                                     |
| conc_dose_iv_bolus_after | output_only              | none                     | Extrapolation                                                               |
| dose                     | conc                     | conc                     | Observed concentration                                                      |
| dose                     | conc                     | conc_dose                | Observed concentration                                                      |
| dose                     | conc                     | conc_dose_iv_bolus_after | Observed concentration                                                      |
| dose                     | conc                     | dose                     | Observed concentration                                                      |
| dose                     | conc                     | dose_iv_bolus_after      | Observed concentration                                                      |
| dose                     | conc                     | none                     | Observed concentration                                                      |
| dose                     | conc_dose                | conc                     | Observed concentration                                                      |
| dose                     | conc_dose                | conc_dose                | Observed concentration                                                      |
| dose                     | conc_dose                | conc_dose_iv_bolus_after | Observed concentration                                                      |
| dose                     | conc_dose                | dose                     | Observed concentration                                                      |
| dose                     | conc_dose                | dose_iv_bolus_after      | Observed concentration                                                      |
| dose                     | conc_dose                | none                     | Observed concentration                                                      |
| dose                     | conc_dose_iv_bolus_after | conc                     | Observed concentration                                                      |
| dose                     | conc_dose_iv_bolus_after | conc_dose                | Observed concentration                                                      |
| dose                     | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| dose                     | conc_dose_iv_bolus_after | dose                     | Observed concentration                                                      |
| dose                     | conc_dose_iv_bolus_after | dose_iv_bolus_after      | Impossible combinations                                                     |
| dose                     | conc_dose_iv_bolus_after | none                     | Observed concentration                                                      |
| dose                     | dose                     | conc                     | Doses with no concentrations between                                        |
| dose                     | dose                     | conc_dose                | Doses with no concentrations between                                        |
| dose                     | dose                     | conc_dose_iv_bolus_after | Doses with no concentrations between                                        |
| dose                     | dose                     | dose                     | Doses with no concentrations between                                        |
| dose                     | dose                     | dose_iv_bolus_after      | Doses with no concentrations between                                        |
| dose                     | dose                     | none                     | Doses with no concentrations between                                        |
| dose                     | dose_iv_bolus_after      | conc                     | Immediately after an IV bolus with a concentration next                     |
| dose                     | dose_iv_bolus_after      | conc_dose                | Immediately after an IV bolus with a concentration next                     |
| dose                     | dose_iv_bolus_after      | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| dose                     | dose_iv_bolus_after      | dose                     | Immediately after an IV bolus without a concentration next                  |
| dose                     | dose_iv_bolus_after      | dose_iv_bolus_after      | Impossible combinations                                                     |
| dose                     | dose_iv_bolus_after      | none                     | Immediately after an IV bolus without a concentration next                  |
| dose                     | output_only              | conc                     | Dose before, concentration after without a dose                             |
| dose                     | output_only              | conc_dose                | Doses with no concentrations between                                        |
| dose                     | output_only              | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| dose                     | output_only              | dose                     | Doses with no concentrations between                                        |
| dose                     | output_only              | dose_iv_bolus_after      | Impossible combinations                                                     |
| dose                     | output_only              | none                     | Dose as the last event in the timeline and requesting a concentration after |
| dose_iv_bolus_after      | conc                     | conc                     | Observed concentration                                                      |
| dose_iv_bolus_after      | conc                     | conc_dose                | Observed concentration                                                      |
| dose_iv_bolus_after      | conc                     | conc_dose_iv_bolus_after | Observed concentration                                                      |
| dose_iv_bolus_after      | conc                     | dose                     | Observed concentration                                                      |
| dose_iv_bolus_after      | conc                     | dose_iv_bolus_after      | Observed concentration                                                      |
| dose_iv_bolus_after      | conc                     | none                     | Observed concentration                                                      |
| dose_iv_bolus_after      | conc_dose                | conc                     | Observed concentration                                                      |
| dose_iv_bolus_after      | conc_dose                | conc_dose                | Observed concentration                                                      |
| dose_iv_bolus_after      | conc_dose                | conc_dose_iv_bolus_after | Observed concentration                                                      |
| dose_iv_bolus_after      | conc_dose                | dose                     | Observed concentration                                                      |
| dose_iv_bolus_after      | conc_dose                | dose_iv_bolus_after      | Observed concentration                                                      |
| dose_iv_bolus_after      | conc_dose                | none                     | Observed concentration                                                      |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | conc                     | Impossible combinations                                                     |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | conc_dose                | Impossible combinations                                                     |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | dose                     | Impossible combinations                                                     |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | dose_iv_bolus_after      | Impossible combinations                                                     |
| dose_iv_bolus_after      | conc_dose_iv_bolus_after | none                     | Impossible combinations                                                     |
| dose_iv_bolus_after      | dose                     | conc                     | Immediately after an IV bolus without a concentration next                  |
| dose_iv_bolus_after      | dose                     | conc_dose                | Immediately after an IV bolus without a concentration next                  |
| dose_iv_bolus_after      | dose                     | conc_dose_iv_bolus_after | Immediately after an IV bolus without a concentration next                  |
| dose_iv_bolus_after      | dose                     | dose                     | Immediately after an IV bolus without a concentration next                  |
| dose_iv_bolus_after      | dose                     | dose_iv_bolus_after      | Immediately after an IV bolus without a concentration next                  |
| dose_iv_bolus_after      | dose                     | none                     | Immediately after an IV bolus without a concentration next                  |
| dose_iv_bolus_after      | dose_iv_bolus_after      | conc                     | Impossible combinations                                                     |
| dose_iv_bolus_after      | dose_iv_bolus_after      | conc_dose                | Impossible combinations                                                     |
| dose_iv_bolus_after      | dose_iv_bolus_after      | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| dose_iv_bolus_after      | dose_iv_bolus_after      | dose                     | Impossible combinations                                                     |
| dose_iv_bolus_after      | dose_iv_bolus_after      | dose_iv_bolus_after      | Impossible combinations                                                     |
| dose_iv_bolus_after      | dose_iv_bolus_after      | none                     | Impossible combinations                                                     |
| dose_iv_bolus_after      | output_only              | conc                     | After an IV bolus with a concentration next                                 |
| dose_iv_bolus_after      | output_only              | conc_dose                | After an IV bolus with a concentration next                                 |
| dose_iv_bolus_after      | output_only              | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| dose_iv_bolus_after      | output_only              | dose                     | After an IV bolus without a concentration next                              |
| dose_iv_bolus_after      | output_only              | dose_iv_bolus_after      | Impossible combinations                                                     |
| dose_iv_bolus_after      | output_only              | none                     | After an IV bolus without a concentration next                              |
| none                     | conc                     | conc                     | Observed concentration                                                      |
| none                     | conc                     | conc_dose                | Observed concentration                                                      |
| none                     | conc                     | conc_dose_iv_bolus_after | Observed concentration                                                      |
| none                     | conc                     | dose                     | Observed concentration                                                      |
| none                     | conc                     | dose_iv_bolus_after      | Observed concentration                                                      |
| none                     | conc                     | none                     | Observed concentration                                                      |
| none                     | conc_dose                | conc                     | Observed concentration                                                      |
| none                     | conc_dose                | conc_dose                | Observed concentration                                                      |
| none                     | conc_dose                | conc_dose_iv_bolus_after | Observed concentration                                                      |
| none                     | conc_dose                | dose                     | Observed concentration                                                      |
| none                     | conc_dose                | dose_iv_bolus_after      | Observed concentration                                                      |
| none                     | conc_dose                | none                     | Observed concentration                                                      |
| none                     | conc_dose_iv_bolus_after | conc                     | Observed concentration                                                      |
| none                     | conc_dose_iv_bolus_after | conc_dose                | Observed concentration                                                      |
| none                     | conc_dose_iv_bolus_after | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| none                     | conc_dose_iv_bolus_after | dose                     | Observed concentration                                                      |
| none                     | conc_dose_iv_bolus_after | dose_iv_bolus_after      | Impossible combinations                                                     |
| none                     | conc_dose_iv_bolus_after | none                     | Observed concentration                                                      |
| none                     | dose                     | conc                     | Before all events                                                           |
| none                     | dose                     | conc_dose                | Before all events                                                           |
| none                     | dose                     | conc_dose_iv_bolus_after | Before all events                                                           |
| none                     | dose                     | dose                     | Before all events                                                           |
| none                     | dose                     | dose_iv_bolus_after      | Before all events                                                           |
| none                     | dose                     | none                     | Before all events                                                           |
| none                     | dose_iv_bolus_after      | conc                     | Immediately after an IV bolus with a concentration next                     |
| none                     | dose_iv_bolus_after      | conc_dose                | Immediately after an IV bolus with a concentration next                     |
| none                     | dose_iv_bolus_after      | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| none                     | dose_iv_bolus_after      | dose                     | Immediately after an IV bolus without a concentration next                  |
| none                     | dose_iv_bolus_after      | dose_iv_bolus_after      | Impossible combinations                                                     |
| none                     | dose_iv_bolus_after      | none                     | Immediately after an IV bolus without a concentration next                  |
| none                     | output_only              | conc                     | Before all events                                                           |
| none                     | output_only              | conc_dose                | Before all events                                                           |
| none                     | output_only              | conc_dose_iv_bolus_after | Impossible combinations                                                     |
| none                     | output_only              | dose                     | Before all events                                                           |
| none                     | output_only              | dose_iv_bolus_after      | Impossible combinations                                                     |
| none                     | output_only              | none                     | Before all events                                                           |
