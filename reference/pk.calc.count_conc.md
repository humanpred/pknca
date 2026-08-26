# Count the number of concentration measurements in an interval

`count_conc` and `count_conc_measured` are typically used for quality
control on the data to ensure that there are a sufficient number of
non-missing samples for a calculation and to ensure that data are
consistent between individuals.

## Usage

``` r
pk.calc.count_conc(conc, check = TRUE)

pk.calc.count_conc_measured(conc, check = TRUE)
```

## Arguments

- conc:

  Measured concentrations

- check:

  Run
  [`assert_conc()`](https://humanpred.github.io/pknca/reference/assert_conc_time.md)?

## Value

a count of the non-missing concentrations (0 if all concentrations are
missing)

a count of the non-missing, measured (not below or above the limit of
quantification) concentrations (0 if all concentrations are missing).
"Measured" here means above the limit of quantification; an imputed
concentration above it is counted (see the "Imputed concentrations"
section).

## Functions

- `pk.calc.count_conc_measured()`: Count the number of concentration
  measurements that are not missing, above, or below the limit of
  quantification in an interval

## Imputed concentrations

Both counts are taken after imputation, and neither distinguishes an
imputed concentration from a measured one. `count_conc` counts every
non-missing concentration, so any imputation that adds a point increases
it. `count_conc_measured` counts concentrations above the limit of
quantification, so whether an imputed point is counted depends on its
value rather than on its being imputed: the zero added by
[`PKNCA_impute_method_start_conc0()`](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md)
is not counted, while the concentration carried to the start time by
[`PKNCA_impute_method_start_predose()`](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md)
and the minimum added by
[`PKNCA_impute_method_start_cmin()`](https://humanpred.github.io/pknca/reference/PKNCA_impute_method.md)
are.

To count only measured samples, calculate the counts in an interval with
no imputation.

## See also

Other NCA parameters for concentrations during the intervals:
[`pk.calc.c0()`](https://humanpred.github.io/pknca/reference/pk.calc.c0.md),
[`pk.calc.cav()`](https://humanpred.github.io/pknca/reference/pk.calc.cav.md),
[`pk.calc.ceoi()`](https://humanpred.github.io/pknca/reference/pk.calc.ceoi.md),
[`pk.calc.clast.obs()`](https://humanpred.github.io/pknca/reference/pk.calc.clast.obs.md),
[`pk.calc.cmax()`](https://humanpred.github.io/pknca/reference/pk.calc.cmax.md),
[`pk.calc.ctrough()`](https://humanpred.github.io/pknca/reference/pk.calc.ctrough.md)
