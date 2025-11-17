# AUC integration methods

## Integration methods for Area Under the Concentration-Time curve (AUC)

There are 3 methods for choosing how to integrate the AUC between two
concentration measurements in `PKNCA`. They are lin up/log down, linear
and lin-log. Additionally, there are 3 methods for extrapolating after
the last concentration above the limit of quantification. They are
AUCinf, AUClast and AUCall. Other methods of calculating AUC (such as
AUC_(tau) and AUC_(int)) are made with variants of these.

## Definitions and abbreviations

- AUC: Area under the concentration-time curve
- BLQ: Below the lower limit of quantification
- LLOQ: lower limit of quantification
- NCA: Noncompartmental analysis
- Profile: A set of concentration-time points for calculation
- T_(last): The last concentration above the limit of quantification
  within a profile
- T_(max): The time of the maximum concentration

## Description of methods of integrating between two concentrations before T_(last)

Note that other NCA tools may not describe interpolation as zero. The
zero-interpolation rules are used by PKNCA to assist with other methods
used across the suite of tools for interpolation and data cleaning
within PKNCA. The zero-interpolation rules could be swapped for linear
trapezoidal rules with the same effects here.

### Linear up/logarithmic down (`"lin up/log down"`) interpolation

Linear up/logarithmic down interpolation is the most commonly used
method for PK, and it is the default for `PKNCA`.

Linear up/logarithmic down interpolation is often used when an exogenous
substance is dosed and measured, and when the elimination likely occurs
by first-order elimination from the body.

Linear up/logarithmic down interpolation uses the following rules in
order for each pair of concentrations through T_(last):

1.  If concentrations are both zero, interpolate as zero;
2.  If concentrations are decreasing and the second concentration is not
    zero, use logarithmic interpolation; and
3.  If concentrations are decreasing before T_(last) or increasing ever,
    use linear interpolation.

### Linear trapezoidal (`"linear"`) interpolation

Linear trapezoidal interpolation is often used when an endogenous
substance is measured (and possibly dosed), and when the elimination may
not occur by first-order elimination processes.

Linear trapezoidal interpolation uses the following rules in order for
each pair of concentrations through T_(last):

1.  If concentrations are both zero, interpolate as zero; and
2.  Use linear interpolation for all other times (this could be the only
    rule).

### Linear to T_(max)/logarithmic after T_(max) (`"lin-log"`) interpolation

Linear to T_(max)/logarithmic after T_(max) interpolation is
infrequently used. It uses the following rules in order for each pair of
concentrations through T_(last):

1.  If concentrations are both zero, interpolate as zero;
2.  If concentrations are before T_(max), use linear interpolation;
3.  If concentrations are after T_(max) (and before T_(last)) and either
    concentration is zero, use linear interpolation; and
4.  If concentrations are after T_(max) and neither is zero, use
    logarithmic interpolation.

## Description of methods of integrating between two concentrations after T_(last)

### `"AUClast"` extrapolation

AUClast extrapolation after T_(last) is the simplest. It is no
extrapolation; the extrapolated AUC integral is zero.

### `"AUCall"` extrapolation

AUCall extrapolation after T_(last) has two rules:

1.  If the last concentration measured is above the limit of
    quantification (in other words, the last time is T_(last)), then no
    extrapolation is done; otherwise
2.  Integrate linearly the triangle between T_(last) and the time of
    zero concentration after T_(last).

### `"AUCinf"` extrapolation

AUCinf extrapolation requires estimation of a half-life. It extrapolates
using the equation

$Extrap = \frac{C_{last}}{\lambda_{z}}$

## Examples

![Example PK where Clast is above the LLOQ; lin up/log down
interpolation method; AUCinf extrapolation method (AUC type); and
keeping all BLQ values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-1.png)

Example PK where Clast is above the LLOQ; lin up/log down interpolation
method; AUCinf extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ handling)

![Example PK where Clast is above the LLOQ; lin up/log down
interpolation method; AUClast extrapolation method (AUC type); and
keeping all BLQ values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-2.png)

Example PK where Clast is above the LLOQ; lin up/log down interpolation
method; AUClast extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ handling)

![Example PK where Clast is above the LLOQ; lin up/log down
interpolation method; AUCall extrapolation method (AUC type); and
keeping all BLQ values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-3.png)

Example PK where Clast is above the LLOQ; lin up/log down interpolation
method; AUCall extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ handling)

![Example PK where Clast is above the LLOQ; linear interpolation method;
AUCinf extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-4.png)

Example PK where Clast is above the LLOQ; linear interpolation method;
AUCinf extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is above the LLOQ; linear interpolation method;
AUClast extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-5.png)

Example PK where Clast is above the LLOQ; linear interpolation method;
AUClast extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is above the LLOQ; linear interpolation method;
AUCall extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-6.png)

Example PK where Clast is above the LLOQ; linear interpolation method;
AUCall extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is above the LLOQ; lin-log interpolation
method; AUCinf extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-7.png)

Example PK where Clast is above the LLOQ; lin-log interpolation method;
AUCinf extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is above the LLOQ; lin-log interpolation
method; AUClast extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-8.png)

Example PK where Clast is above the LLOQ; lin-log interpolation method;
AUClast extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is above the LLOQ; lin-log interpolation
method; AUCall extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-9.png)

Example PK where Clast is above the LLOQ; lin-log interpolation method;
AUCall extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is below the LLOQ; lin up/log down
interpolation method; AUCinf extrapolation method (AUC type); and
keeping all BLQ values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-10.png)

Example PK where Clast is below the LLOQ; lin up/log down interpolation
method; AUCinf extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ handling)

![Example PK where Clast is below the LLOQ; lin up/log down
interpolation method; AUClast extrapolation method (AUC type); and
keeping all BLQ values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-11.png)

Example PK where Clast is below the LLOQ; lin up/log down interpolation
method; AUClast extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ handling)

![Example PK where Clast is below the LLOQ; lin up/log down
interpolation method; AUCall extrapolation method (AUC type); and
keeping all BLQ values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-12.png)

Example PK where Clast is below the LLOQ; lin up/log down interpolation
method; AUCall extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ handling)

![Example PK where Clast is below the LLOQ; linear interpolation method;
AUCinf extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-13.png)

Example PK where Clast is below the LLOQ; linear interpolation method;
AUCinf extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is below the LLOQ; linear interpolation method;
AUClast extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-14.png)

Example PK where Clast is below the LLOQ; linear interpolation method;
AUClast extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is below the LLOQ; linear interpolation method;
AUCall extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-15.png)

Example PK where Clast is below the LLOQ; linear interpolation method;
AUCall extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is below the LLOQ; lin-log interpolation
method; AUCinf extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-16.png)

Example PK where Clast is below the LLOQ; lin-log interpolation method;
AUCinf extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is below the LLOQ; lin-log interpolation
method; AUClast extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-17.png)

Example PK where Clast is below the LLOQ; lin-log interpolation method;
AUClast extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Clast is below the LLOQ; lin-log interpolation
method; AUCall extrapolation method (AUC type); and keeping all BLQ
values (not default BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-18.png)

Example PK where Clast is below the LLOQ; lin-log interpolation method;
AUCall extrapolation method (AUC type); and keeping all BLQ values (not
default BLQ handling)

![Example PK where Concentrations increase and decrease after T~max~
with zeros in the middle; lin up/log down interpolation method; AUCinf
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-19.png)

Example PK where Concentrations increase and decrease after T_(max) with
zeros in the middle; lin up/log down interpolation method; AUCinf
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ handling)

![Example PK where Concentrations increase and decrease after T~max~
with zeros in the middle; lin up/log down interpolation method; AUClast
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-20.png)

Example PK where Concentrations increase and decrease after T_(max) with
zeros in the middle; lin up/log down interpolation method; AUClast
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ handling)

![Example PK where Concentrations increase and decrease after T~max~
with zeros in the middle; lin up/log down interpolation method; AUCall
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-21.png)

Example PK where Concentrations increase and decrease after T_(max) with
zeros in the middle; lin up/log down interpolation method; AUCall
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ handling)

![Example PK where Concentrations increase and decrease after T~max~
with zeros in the middle; linear interpolation method; AUCinf
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-22.png)

Example PK where Concentrations increase and decrease after T_(max) with
zeros in the middle; linear interpolation method; AUCinf extrapolation
method (AUC type); and keeping all BLQ values (not default BLQ handling)

![Example PK where Concentrations increase and decrease after T~max~
with zeros in the middle; linear interpolation method; AUClast
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-23.png)

Example PK where Concentrations increase and decrease after T_(max) with
zeros in the middle; linear interpolation method; AUClast extrapolation
method (AUC type); and keeping all BLQ values (not default BLQ handling)

![Example PK where Concentrations increase and decrease after T~max~
with zeros in the middle; linear interpolation method; AUCall
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-24.png)

Example PK where Concentrations increase and decrease after T_(max) with
zeros in the middle; linear interpolation method; AUCall extrapolation
method (AUC type); and keeping all BLQ values (not default BLQ handling)

![Example PK where Concentrations increase and decrease after T~max~
with zeros in the middle; lin-log interpolation method; AUCinf
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-25.png)

Example PK where Concentrations increase and decrease after T_(max) with
zeros in the middle; lin-log interpolation method; AUCinf extrapolation
method (AUC type); and keeping all BLQ values (not default BLQ handling)

![Example PK where Concentrations increase and decrease after T~max~
with zeros in the middle; lin-log interpolation method; AUClast
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-26.png)

Example PK where Concentrations increase and decrease after T_(max) with
zeros in the middle; lin-log interpolation method; AUClast extrapolation
method (AUC type); and keeping all BLQ values (not default BLQ handling)

![Example PK where Concentrations increase and decrease after T~max~
with zeros in the middle; lin-log interpolation method; AUCall
extrapolation method (AUC type); and keeping all BLQ values (not default
BLQ
handling)](v23-auc-integration-methods_files/figure-html/example-figures-27.png)

Example PK where Concentrations increase and decrease after T_(max) with
zeros in the middle; lin-log interpolation method; AUCall extrapolation
method (AUC type); and keeping all BLQ values (not default BLQ handling)
