# Get the columns that can be used in an interval specification

Get the columns that can be used in an interval specification

## Usage

``` r
get.interval.cols()
```

## Value

A list with named elements for each parameter. Each list element
contains the parameter definition.

## See also

[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md)
and the vignette "Selection of Calculation Intervals"

Other Interval specifications:
[`add.interval.col()`](https://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.specification()`](https://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](https://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
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
get.interval.cols()
#> $start
#> $start$FUN
#> [1] NA
#> 
#> $start$values
#> function (x, ...)  .Primitive("as.double")
#> 
#> $start$unit_type
#> [1] "time"
#> 
#> $start$pretty_name
#> [1] "Interval Start"
#> 
#> $start$desc
#> [1] "Starting time of the interval"
#> 
#> $start$sparse
#> [1] FALSE
#> 
#> $start$formalsmap
#> list()
#> 
#> $start$depends
#> NULL
#> 
#> $start$datatype
#> [1] "interval"
#> 
#> $start$pptestcd_cdisc
#> [1] "start"
#> 
#> $start$pptest_cdisc
#> [1] "Starting time of the interval"
#> 
#> $start$formula
#> NULL
#> 
#> $start$formula_note
#> NULL
#> 
#> $start$tier
#> [1] "uncommon"
#> 
#> $start$selection
#> list()
#> 
#> 
#> $end
#> $end$FUN
#> [1] NA
#> 
#> $end$values
#> function (x, ...)  .Primitive("as.double")
#> 
#> $end$unit_type
#> [1] "time"
#> 
#> $end$pretty_name
#> [1] "Interval End"
#> 
#> $end$desc
#> [1] "End time of interval (may be Inf)"
#> 
#> $end$sparse
#> [1] FALSE
#> 
#> $end$formalsmap
#> list()
#> 
#> $end$depends
#> NULL
#> 
#> $end$datatype
#> [1] "interval"
#> 
#> $end$pptestcd_cdisc
#> [1] "end"
#> 
#> $end$pptest_cdisc
#> [1] "End time of interval (may be Inf)"
#> 
#> $end$formula
#> NULL
#> 
#> $end$formula_note
#> NULL
#> 
#> $end$tier
#> [1] "uncommon"
#> 
#> $end$selection
#> list()
#> 
#> 
#> $auclast
#> $auclast$FUN
#> [1] "pk.calc.auc.last"
#> 
#> $auclast$values
#> [1] FALSE  TRUE
#> 
#> $auclast$unit_type
#> [1] "auc"
#> 
#> $auclast$pretty_name
#> [1] "AUClast"
#> 
#> $auclast$desc
#> [1] "AUC start to last conc above LOQ"
#> 
#> $auclast$sparse
#> [1] FALSE
#> 
#> $auclast$formalsmap
#> list()
#> 
#> $auclast$depends
#> NULL
#> 
#> $auclast$datatype
#> [1] "interval"
#> 
#> $auclast$pptestcd_cdisc
#> [1] "AUCLST"
#> 
#> $auclast$pptest_cdisc
#> [1] "AUC to Last Nonzero Conc"
#> 
#> $auclast$formula
#> [1] "$AUC_{\\text{last}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $auclast$formula_note
#> [1] "Trapezoidal rule (linear-up/log-down by default)"
#> 
#> $auclast$tier
#> [1] "common"
#> 
#> $auclast$selection
#> list()
#> 
#> $auclast$requires_dose_amt
#> [1] FALSE
#> 
#> $auclast$requires_dose_time
#> [1] FALSE
#> 
#> $auclast$requires_dose_dur
#> [1] FALSE
#> 
#> $auclast$requires_volume
#> [1] FALSE
#> 
#> $auclast$requires_conc_dur
#> [1] FALSE
#> 
#> 
#> $aucall
#> $aucall$FUN
#> [1] "pk.calc.auc.all"
#> 
#> $aucall$values
#> [1] FALSE  TRUE
#> 
#> $aucall$unit_type
#> [1] "auc"
#> 
#> $aucall$pretty_name
#> [1] "AUCall"
#> 
#> $aucall$desc
#> [1] "AUClast plus triangle, 0 at BLQ"
#> 
#> $aucall$sparse
#> [1] FALSE
#> 
#> $aucall$formalsmap
#> list()
#> 
#> $aucall$depends
#> NULL
#> 
#> $aucall$datatype
#> [1] "interval"
#> 
#> $aucall$pptestcd_cdisc
#> [1] "AUCALL"
#> 
#> $aucall$pptest_cdisc
#> [1] "AUC All"
#> 
#> $aucall$formula
#> [1] "$AUC_{\\text{all}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aucall$formula_note
#> [1] "Trapezoidal rule (linear-up/log-down by default)"
#> 
#> $aucall$tier
#> [1] "uncommon"
#> 
#> $aucall$selection
#> list()
#> 
#> 
#> $aumclast
#> $aumclast$FUN
#> [1] "pk.calc.aumc.last"
#> 
#> $aumclast$values
#> [1] FALSE  TRUE
#> 
#> $aumclast$unit_type
#> [1] "aumc"
#> 
#> $aumclast$pretty_name
#> [1] "AUMC,last"
#> 
#> $aumclast$desc
#> [1] "AUMC start to last conc above LOQ"
#> 
#> $aumclast$sparse
#> [1] FALSE
#> 
#> $aumclast$formalsmap
#> list()
#> 
#> $aumclast$depends
#> NULL
#> 
#> $aumclast$datatype
#> [1] "interval"
#> 
#> $aumclast$pptestcd_cdisc
#> [1] "AUMCLST"
#> 
#> $aumclast$pptest_cdisc
#> [1] "AUMC to Last Nonzero Conc"
#> 
#> $aumclast$formula
#> [1] "$AUMC_{\\text{last}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumclast$formula_note
#> [1] "Trapezoidal rule (linear-up/log-down by default)"
#> 
#> $aumclast$tier
#> [1] "uncommon"
#> 
#> $aumclast$selection
#> list()
#> 
#> 
#> $aumcall
#> $aumcall$FUN
#> [1] "pk.calc.aumc.all"
#> 
#> $aumcall$values
#> [1] FALSE  TRUE
#> 
#> $aumcall$unit_type
#> [1] "aumc"
#> 
#> $aumcall$pretty_name
#> [1] "AUMC,all"
#> 
#> $aumcall$desc
#> [1] "AUMClast plus triangle moment, 0 at BLQ"
#> 
#> $aumcall$sparse
#> [1] FALSE
#> 
#> $aumcall$formalsmap
#> list()
#> 
#> $aumcall$depends
#> NULL
#> 
#> $aumcall$datatype
#> [1] "interval"
#> 
#> $aumcall$pptestcd_cdisc
#> [1] "AUMCALL"
#> 
#> $aumcall$pptest_cdisc
#> [1] "AUMC All"
#> 
#> $aumcall$formula
#> [1] "$AUMC_{\\text{all}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumcall$formula_note
#> [1] "Trapezoidal rule (linear-up/log-down by default)"
#> 
#> $aumcall$tier
#> [1] "uncommon"
#> 
#> $aumcall$selection
#> list()
#> 
#> 
#> $aucint.last
#> $aucint.last$FUN
#> [1] "pk.calc.aucint.last"
#> 
#> $aucint.last$values
#> [1] FALSE  TRUE
#> 
#> $aucint.last$unit_type
#> [1] "auc"
#> 
#> $aucint.last$pretty_name
#> [1] "AUCint (based on AUClast extrapolation)"
#> 
#> $aucint.last$desc
#> [1] "AUC from T1 to T2 (zero extrap)"
#> 
#> $aucint.last$sparse
#> [1] FALSE
#> 
#> $aucint.last$formalsmap
#> $aucint.last$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aucint.last$formalsmap$time
#> [1] "time.group"
#> 
#> $aucint.last$formalsmap$time.dose
#> NULL
#> 
#> 
#> $aucint.last$depends
#> NULL
#> 
#> $aucint.last$datatype
#> [1] "interval"
#> 
#> $aucint.last$pptestcd_cdisc
#> [1] "AUCINT"
#> 
#> $aucint.last$pptest_cdisc
#> [1] "AUC from T1 to T2"
#> 
#> $aucint.last$formula
#> [1] "$AUC_{\\text{int,last}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aucint.last$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aucint.last$tier
#> [1] "common"
#> 
#> $aucint.last$selection
#> list()
#> 
#> 
#> $aucint.last.dose
#> $aucint.last.dose$FUN
#> [1] "pk.calc.aucint.last"
#> 
#> $aucint.last.dose$values
#> [1] FALSE  TRUE
#> 
#> $aucint.last.dose$unit_type
#> [1] "auc"
#> 
#> $aucint.last.dose$pretty_name
#> [1] "AUCint (based on AUClast extrapolation, dose-aware)"
#> 
#> $aucint.last.dose$desc
#> [1] "AUC T1 to T2, dose-aware (zero extrap)"
#> 
#> $aucint.last.dose$sparse
#> [1] FALSE
#> 
#> $aucint.last.dose$formalsmap
#> $aucint.last.dose$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aucint.last.dose$formalsmap$time
#> [1] "time.group"
#> 
#> $aucint.last.dose$formalsmap$time.dose
#> [1] "time.dose.group"
#> 
#> 
#> $aucint.last.dose$depends
#> NULL
#> 
#> $aucint.last.dose$datatype
#> [1] "interval"
#> 
#> $aucint.last.dose$pptestcd_cdisc
#> [1] "AUCINTD"
#> 
#> $aucint.last.dose$pptest_cdisc
#> [1] "AUC from T1 to T2 Normalized by Dose"
#> 
#> $aucint.last.dose$formula
#> [1] "$AUC_{\\text{int,last,dose}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aucint.last.dose$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aucint.last.dose$tier
#> [1] "uncommon"
#> 
#> $aucint.last.dose$selection
#> list()
#> 
#> 
#> $aucint.all
#> $aucint.all$FUN
#> [1] "pk.calc.aucint.all"
#> 
#> $aucint.all$values
#> [1] FALSE  TRUE
#> 
#> $aucint.all$unit_type
#> [1] "auc"
#> 
#> $aucint.all$pretty_name
#> [1] "AUCint (based on AUCall extrapolation)"
#> 
#> $aucint.all$desc
#> [1] "AUC from T1 to T2 (AUCall extrap)"
#> 
#> $aucint.all$sparse
#> [1] FALSE
#> 
#> $aucint.all$formalsmap
#> $aucint.all$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aucint.all$formalsmap$time
#> [1] "time.group"
#> 
#> $aucint.all$formalsmap$time.dose
#> NULL
#> 
#> 
#> $aucint.all$depends
#> NULL
#> 
#> $aucint.all$datatype
#> [1] "interval"
#> 
#> $aucint.all$pptestcd_cdisc
#> [1] "AUCINTA"
#> 
#> $aucint.all$pptest_cdisc
#> [1] "AUCint (based on AUCall extrapolation)"
#> 
#> $aucint.all$formula
#> [1] "$AUC_{\\text{int,all}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aucint.all$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aucint.all$tier
#> [1] "uncommon"
#> 
#> $aucint.all$selection
#> list()
#> 
#> 
#> $aucint.all.dose
#> $aucint.all.dose$FUN
#> [1] "pk.calc.aucint.all"
#> 
#> $aucint.all.dose$values
#> [1] FALSE  TRUE
#> 
#> $aucint.all.dose$unit_type
#> [1] "auc"
#> 
#> $aucint.all.dose$pretty_name
#> [1] "AUCint (based on AUCall extrapolation, dose-aware)"
#> 
#> $aucint.all.dose$desc
#> [1] "AUC T1 to T2, dose-aware (AUCall)"
#> 
#> $aucint.all.dose$sparse
#> [1] FALSE
#> 
#> $aucint.all.dose$formalsmap
#> $aucint.all.dose$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aucint.all.dose$formalsmap$time
#> [1] "time.group"
#> 
#> $aucint.all.dose$formalsmap$time.dose
#> [1] "time.dose.group"
#> 
#> 
#> $aucint.all.dose$depends
#> NULL
#> 
#> $aucint.all.dose$datatype
#> [1] "interval"
#> 
#> $aucint.all.dose$pptestcd_cdisc
#> [1] "AUCINTAD"
#> 
#> $aucint.all.dose$pptest_cdisc
#> [1] "AUCint (based on AUCall extrapolation, dose-aware)"
#> 
#> $aucint.all.dose$formula
#> [1] "$AUC_{\\text{int,all,dose}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aucint.all.dose$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aucint.all.dose$tier
#> [1] "uncommon"
#> 
#> $aucint.all.dose$selection
#> list()
#> 
#> 
#> $aumcint.last
#> $aumcint.last$FUN
#> [1] "pk.calc.aumcint.last"
#> 
#> $aumcint.last$values
#> [1] FALSE  TRUE
#> 
#> $aumcint.last$unit_type
#> [1] "aumc"
#> 
#> $aumcint.last$pretty_name
#> [1] "AUMCint (based on AUMClast extrapolation)"
#> 
#> $aumcint.last$desc
#> [1] "AUMC from T1 to T2 (zero extrap)"
#> 
#> $aumcint.last$sparse
#> [1] FALSE
#> 
#> $aumcint.last$formalsmap
#> $aumcint.last$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aumcint.last$formalsmap$time
#> [1] "time.group"
#> 
#> $aumcint.last$formalsmap$time.dose
#> NULL
#> 
#> 
#> $aumcint.last$depends
#> NULL
#> 
#> $aumcint.last$datatype
#> [1] "interval"
#> 
#> $aumcint.last$pptestcd_cdisc
#> [1] "aumcint.last"
#> 
#> $aumcint.last$pptest_cdisc
#> [1] "AUMC from T1 to T2 (zero extrap)"
#> 
#> $aumcint.last$formula
#> [1] "$AUMC_{\\text{int,last}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumcint.last$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aumcint.last$tier
#> [1] "uncommon"
#> 
#> $aumcint.last$selection
#> list()
#> 
#> 
#> $aumcint.last.dose
#> $aumcint.last.dose$FUN
#> [1] "pk.calc.aumcint.last"
#> 
#> $aumcint.last.dose$values
#> [1] FALSE  TRUE
#> 
#> $aumcint.last.dose$unit_type
#> [1] "aumc"
#> 
#> $aumcint.last.dose$pretty_name
#> [1] "AUMCint (based on AUMClast extrapolation, dose-aware)"
#> 
#> $aumcint.last.dose$desc
#> [1] "AUMC T1 to T2, dose-aware (zero extrap)"
#> 
#> $aumcint.last.dose$sparse
#> [1] FALSE
#> 
#> $aumcint.last.dose$formalsmap
#> $aumcint.last.dose$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aumcint.last.dose$formalsmap$time
#> [1] "time.group"
#> 
#> $aumcint.last.dose$formalsmap$time.dose
#> [1] "time.dose.group"
#> 
#> 
#> $aumcint.last.dose$depends
#> NULL
#> 
#> $aumcint.last.dose$datatype
#> [1] "interval"
#> 
#> $aumcint.last.dose$pptestcd_cdisc
#> [1] "aumcint.last.dose"
#> 
#> $aumcint.last.dose$pptest_cdisc
#> [1] "AUMC T1 to T2, dose-aware (zero extrap)"
#> 
#> $aumcint.last.dose$formula
#> [1] "$AUMC_{\\text{int,last,dose}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumcint.last.dose$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aumcint.last.dose$tier
#> [1] "uncommon"
#> 
#> $aumcint.last.dose$selection
#> list()
#> 
#> 
#> $aumcint.all
#> $aumcint.all$FUN
#> [1] "pk.calc.aumcint.all"
#> 
#> $aumcint.all$values
#> [1] FALSE  TRUE
#> 
#> $aumcint.all$unit_type
#> [1] "aumc"
#> 
#> $aumcint.all$pretty_name
#> [1] "AUMCint (based on AUMCall extrapolation)"
#> 
#> $aumcint.all$desc
#> [1] "AUMC from T1 to T2 (AUMCall extrap)"
#> 
#> $aumcint.all$sparse
#> [1] FALSE
#> 
#> $aumcint.all$formalsmap
#> $aumcint.all$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aumcint.all$formalsmap$time
#> [1] "time.group"
#> 
#> $aumcint.all$formalsmap$time.dose
#> NULL
#> 
#> 
#> $aumcint.all$depends
#> NULL
#> 
#> $aumcint.all$datatype
#> [1] "interval"
#> 
#> $aumcint.all$pptestcd_cdisc
#> [1] "aumcint.all"
#> 
#> $aumcint.all$pptest_cdisc
#> [1] "AUMC from T1 to T2 (AUMCall extrap)"
#> 
#> $aumcint.all$formula
#> [1] "$AUMC_{\\text{int,all}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumcint.all$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aumcint.all$tier
#> [1] "uncommon"
#> 
#> $aumcint.all$selection
#> list()
#> 
#> 
#> $aumcint.all.dose
#> $aumcint.all.dose$FUN
#> [1] "pk.calc.aumcint.all"
#> 
#> $aumcint.all.dose$values
#> [1] FALSE  TRUE
#> 
#> $aumcint.all.dose$unit_type
#> [1] "aumc"
#> 
#> $aumcint.all.dose$pretty_name
#> [1] "AUMCint (based on AUMCall extrapolation, dose-aware)"
#> 
#> $aumcint.all.dose$desc
#> [1] "AUMC T1 to T2, dose-aware (AUMCall)"
#> 
#> $aumcint.all.dose$sparse
#> [1] FALSE
#> 
#> $aumcint.all.dose$formalsmap
#> $aumcint.all.dose$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aumcint.all.dose$formalsmap$time
#> [1] "time.group"
#> 
#> $aumcint.all.dose$formalsmap$time.dose
#> [1] "time.dose.group"
#> 
#> 
#> $aumcint.all.dose$depends
#> NULL
#> 
#> $aumcint.all.dose$datatype
#> [1] "interval"
#> 
#> $aumcint.all.dose$pptestcd_cdisc
#> [1] "aumcint.all.dose"
#> 
#> $aumcint.all.dose$pptest_cdisc
#> [1] "AUMC T1 to T2, dose-aware (AUMCall)"
#> 
#> $aumcint.all.dose$formula
#> [1] "$AUMC_{\\text{int,all,dose}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumcint.all.dose$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aumcint.all.dose$tier
#> [1] "uncommon"
#> 
#> $aumcint.all.dose$selection
#> list()
#> 
#> 
#> $c0
#> $c0$FUN
#> [1] "pk.calc.c0"
#> 
#> $c0$values
#> [1] FALSE  TRUE
#> 
#> $c0$unit_type
#> [1] "conc"
#> 
#> $c0$pretty_name
#> [1] "C0"
#> 
#> $c0$desc
#> [1] "Initial conc after IV bolus"
#> 
#> $c0$sparse
#> [1] FALSE
#> 
#> $c0$formalsmap
#> list()
#> 
#> $c0$depends
#> NULL
#> 
#> $c0$datatype
#> [1] "interval"
#> 
#> $c0$pptestcd_cdisc
#> [1] "C0"
#> 
#> $c0$pptest_cdisc
#> [1] "Initial Conc"
#> 
#> $c0$formula
#> [1] "$C_0 = \\text{if measured, } C_{t=0}; \\text{ else, } C_0 = C_1 \\exp\\left(-\\frac{\\ln(C_2) - \\ln(C_1)}{t_2-t_1} (t_1 - t_{\\text{dose}})\\right)$"
#> 
#> $c0$formula_note
#> [1] "Methods are tried in order: c0, logslope, c1, cmin, set0; the formula shows c0 and logslope"
#> 
#> $c0$tier
#> [1] "common"
#> 
#> $c0$selection
#> list()
#> 
#> 
#> $cmax
#> $cmax$FUN
#> [1] "pk.calc.cmax"
#> 
#> $cmax$values
#> [1] FALSE  TRUE
#> 
#> $cmax$unit_type
#> [1] "conc"
#> 
#> $cmax$pretty_name
#> [1] "Cmax"
#> 
#> $cmax$desc
#> [1] "Maximum observed concentration"
#> 
#> $cmax$sparse
#> [1] FALSE
#> 
#> $cmax$formalsmap
#> list()
#> 
#> $cmax$depends
#> NULL
#> 
#> $cmax$datatype
#> [1] "interval"
#> 
#> $cmax$pptestcd_cdisc
#> [1] "CMAX"
#> 
#> $cmax$pptest_cdisc
#> [1] "Max Conc"
#> 
#> $cmax$formula
#> [1] "$C_{\\max} = \\max_i C_i$"
#> 
#> $cmax$formula_note
#> NULL
#> 
#> $cmax$tier
#> [1] "common"
#> 
#> $cmax$selection
#> list()
#> 
#> $cmax$requires_dose_amt
#> [1] FALSE
#> 
#> $cmax$requires_dose_time
#> [1] FALSE
#> 
#> $cmax$requires_dose_dur
#> [1] FALSE
#> 
#> $cmax$requires_volume
#> [1] FALSE
#> 
#> $cmax$requires_conc_dur
#> [1] FALSE
#> 
#> 
#> $cmin
#> $cmin$FUN
#> [1] "pk.calc.cmin"
#> 
#> $cmin$values
#> [1] FALSE  TRUE
#> 
#> $cmin$unit_type
#> [1] "conc"
#> 
#> $cmin$pretty_name
#> [1] "Cmin"
#> 
#> $cmin$desc
#> [1] "Minimum observed concentration"
#> 
#> $cmin$sparse
#> [1] FALSE
#> 
#> $cmin$formalsmap
#> list()
#> 
#> $cmin$depends
#> NULL
#> 
#> $cmin$datatype
#> [1] "interval"
#> 
#> $cmin$pptestcd_cdisc
#> [1] "CMIN"
#> 
#> $cmin$pptest_cdisc
#> [1] "Min Conc"
#> 
#> $cmin$formula
#> [1] "$C_{\\min} = \\min_i C_i$"
#> 
#> $cmin$formula_note
#> NULL
#> 
#> $cmin$tier
#> [1] "uncommon"
#> 
#> $cmin$selection
#> list()
#> 
#> 
#> $tmax
#> $tmax$FUN
#> [1] "pk.calc.tmax"
#> 
#> $tmax$values
#> [1] FALSE  TRUE
#> 
#> $tmax$unit_type
#> [1] "time"
#> 
#> $tmax$pretty_name
#> [1] "Tmax"
#> 
#> $tmax$desc
#> [1] "Time of maximum observed conc"
#> 
#> $tmax$sparse
#> [1] FALSE
#> 
#> $tmax$formalsmap
#> list()
#> 
#> $tmax$depends
#> NULL
#> 
#> $tmax$datatype
#> [1] "interval"
#> 
#> $tmax$pptestcd_cdisc
#> [1] "TMAX"
#> 
#> $tmax$pptest_cdisc
#> [1] "Time of CMAX"
#> 
#> $tmax$formula
#> [1] "$T_{\\max} = t_{i: C_i = C_{\\max}}$"
#> 
#> $tmax$formula_note
#> NULL
#> 
#> $tmax$tier
#> [1] "common"
#> 
#> $tmax$selection
#> list()
#> 
#> $tmax$requires_dose_amt
#> [1] FALSE
#> 
#> $tmax$requires_dose_time
#> [1] FALSE
#> 
#> $tmax$requires_dose_dur
#> [1] FALSE
#> 
#> $tmax$requires_volume
#> [1] FALSE
#> 
#> $tmax$requires_conc_dur
#> [1] FALSE
#> 
#> 
#> $tmin
#> $tmin$FUN
#> [1] "pk.calc.tmin"
#> 
#> $tmin$values
#> [1] FALSE  TRUE
#> 
#> $tmin$unit_type
#> [1] "time"
#> 
#> $tmin$pretty_name
#> [1] "Tmin"
#> 
#> $tmin$desc
#> [1] "Time of minimum observed conc"
#> 
#> $tmin$sparse
#> [1] FALSE
#> 
#> $tmin$formalsmap
#> list()
#> 
#> $tmin$depends
#> NULL
#> 
#> $tmin$datatype
#> [1] "interval"
#> 
#> $tmin$pptestcd_cdisc
#> [1] "TMIN"
#> 
#> $tmin$pptest_cdisc
#> [1] "Time of CMIN Observation"
#> 
#> $tmin$formula
#> NULL
#> 
#> $tmin$formula_note
#> NULL
#> 
#> $tmin$tier
#> [1] "uncommon"
#> 
#> $tmin$selection
#> list()
#> 
#> 
#> $tlast
#> $tlast$FUN
#> [1] "pk.calc.tlast"
#> 
#> $tlast$values
#> [1] FALSE  TRUE
#> 
#> $tlast$unit_type
#> [1] "time"
#> 
#> $tlast$pretty_name
#> [1] "Tlast"
#> 
#> $tlast$desc
#> [1] "Time of last conc above LOQ"
#> 
#> $tlast$sparse
#> [1] FALSE
#> 
#> $tlast$formalsmap
#> list()
#> 
#> $tlast$depends
#> NULL
#> 
#> $tlast$datatype
#> [1] "interval"
#> 
#> $tlast$pptestcd_cdisc
#> [1] "TLST"
#> 
#> $tlast$pptest_cdisc
#> [1] "Time of Last Nonzero Conc"
#> 
#> $tlast$formula
#> [1] "$T_{\\text{last}} = t_{i: C_i > 0, i = \\max}$"
#> 
#> $tlast$formula_note
#> NULL
#> 
#> $tlast$tier
#> [1] "uncommon"
#> 
#> $tlast$selection
#> list()
#> 
#> 
#> $tfirst
#> $tfirst$FUN
#> [1] "pk.calc.tfirst"
#> 
#> $tfirst$values
#> [1] FALSE  TRUE
#> 
#> $tfirst$unit_type
#> [1] "time"
#> 
#> $tfirst$pretty_name
#> [1] "Tfirst"
#> 
#> $tfirst$desc
#> [1] "Time of first conc above LOQ"
#> 
#> $tfirst$sparse
#> [1] FALSE
#> 
#> $tfirst$formalsmap
#> list()
#> 
#> $tfirst$depends
#> NULL
#> 
#> $tfirst$datatype
#> [1] "interval"
#> 
#> $tfirst$pptestcd_cdisc
#> [1] "TFIRST"
#> 
#> $tfirst$pptest_cdisc
#> [1] "Time of First Nonzero Conc"
#> 
#> $tfirst$formula
#> [1] "$T_{\\text{first}} = t_{i: C_i > 0, i = \\min}$"
#> 
#> $tfirst$formula_note
#> NULL
#> 
#> $tfirst$tier
#> [1] "uncommon"
#> 
#> $tfirst$selection
#> list()
#> 
#> 
#> $clast.obs
#> $clast.obs$FUN
#> [1] "pk.calc.clast.obs"
#> 
#> $clast.obs$values
#> [1] FALSE  TRUE
#> 
#> $clast.obs$unit_type
#> [1] "conc"
#> 
#> $clast.obs$pretty_name
#> [1] "Clast"
#> 
#> $clast.obs$desc
#> [1] "Last conc observed above LOQ"
#> 
#> $clast.obs$sparse
#> [1] FALSE
#> 
#> $clast.obs$formalsmap
#> list()
#> 
#> $clast.obs$depends
#> NULL
#> 
#> $clast.obs$datatype
#> [1] "interval"
#> 
#> $clast.obs$pptestcd_cdisc
#> [1] "CLST"
#> 
#> $clast.obs$pptest_cdisc
#> [1] "Last Nonzero Conc"
#> 
#> $clast.obs$formula
#> [1] "$C_{\\text{last,obs}} = C_{i: t_i = T_{\\text{last}}}$"
#> 
#> $clast.obs$formula_note
#> NULL
#> 
#> $clast.obs$tier
#> [1] "uncommon"
#> 
#> $clast.obs$selection
#> list()
#> 
#> 
#> $cl.last
#> $cl.last$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.last$values
#> [1] FALSE  TRUE
#> 
#> $cl.last$unit_type
#> [1] "clearance"
#> 
#> $cl.last$pretty_name
#> [1] "CL (based on AUClast)"
#> 
#> $cl.last$desc
#> [1] "Clearance, AUClast"
#> 
#> $cl.last$sparse
#> [1] FALSE
#> 
#> $cl.last$formalsmap
#> $cl.last$formalsmap$auc
#> [1] "auclast"
#> 
#> 
#> $cl.last$depends
#> [1] "auclast"
#> 
#> $cl.last$datatype
#> [1] "interval"
#> 
#> $cl.last$pptestcd_cdisc
#> $cl.last$pptestcd_cdisc$route
#> $cl.last$pptestcd_cdisc$route$extravascular
#> [1] "CLF/FLST"
#> 
#> $cl.last$pptestcd_cdisc$route$intravascular
#> [1] "CLLST"
#> 
#> 
#> 
#> $cl.last$pptest_cdisc
#> $cl.last$pptest_cdisc$route
#> $cl.last$pptest_cdisc$route$extravascular
#> [1] "CL by F (based on AUClast)"
#> 
#> $cl.last$pptest_cdisc$route$intravascular
#> [1] "CL (based on AUClast)"
#> 
#> 
#> 
#> $cl.last$formula
#> [1] "$CL_{\\text{last}} = \\frac{Dose}{AUC_{\\text{last}}}$"
#> 
#> $cl.last$formula_note
#> NULL
#> 
#> $cl.last$tier
#> [1] "uncommon"
#> 
#> $cl.last$selection
#> list()
#> 
#> 
#> $cl.all
#> $cl.all$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.all$values
#> [1] FALSE  TRUE
#> 
#> $cl.all$unit_type
#> [1] "clearance"
#> 
#> $cl.all$pretty_name
#> [1] "CL (based on AUCall)"
#> 
#> $cl.all$desc
#> [1] "Clearance, AUCall"
#> 
#> $cl.all$sparse
#> [1] FALSE
#> 
#> $cl.all$formalsmap
#> $cl.all$formalsmap$auc
#> [1] "aucall"
#> 
#> 
#> $cl.all$depends
#> [1] "aucall"
#> 
#> $cl.all$datatype
#> [1] "interval"
#> 
#> $cl.all$pptestcd_cdisc
#> $cl.all$pptestcd_cdisc$route
#> $cl.all$pptestcd_cdisc$route$extravascular
#> [1] "CLF/FALL"
#> 
#> $cl.all$pptestcd_cdisc$route$intravascular
#> [1] "CLALL"
#> 
#> 
#> 
#> $cl.all$pptest_cdisc
#> $cl.all$pptest_cdisc$route
#> $cl.all$pptest_cdisc$route$extravascular
#> [1] "CL by F (based on AUCall)"
#> 
#> $cl.all$pptest_cdisc$route$intravascular
#> [1] "CL (based on AUCall)"
#> 
#> 
#> 
#> $cl.all$formula
#> [1] "$CL_{\\text{all}} = \\frac{Dose}{AUC_{\\text{all}}}$"
#> 
#> $cl.all$formula_note
#> NULL
#> 
#> $cl.all$tier
#> [1] "uncommon"
#> 
#> $cl.all$selection
#> list()
#> 
#> 
#> $cl.int.all
#> $cl.int.all$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.int.all$values
#> [1] FALSE  TRUE
#> 
#> $cl.int.all$unit_type
#> [1] "clearance"
#> 
#> $cl.int.all$pretty_name
#> [1] "CL (based on AUCint.all)"
#> 
#> $cl.int.all$desc
#> [1] "Clearance, AUCint.all"
#> 
#> $cl.int.all$sparse
#> [1] FALSE
#> 
#> $cl.int.all$formalsmap
#> $cl.int.all$formalsmap$auc
#> [1] "aucint.all"
#> 
#> 
#> $cl.int.all$depends
#> [1] "aucint.all"
#> 
#> $cl.int.all$datatype
#> [1] "interval"
#> 
#> $cl.int.all$pptestcd_cdisc
#> [1] "cl.int.all"
#> 
#> $cl.int.all$pptest_cdisc
#> [1] "Clearance, AUCint.all"
#> 
#> $cl.int.all$formula
#> [1] "$CL_{\\text{int,all}} = \\frac{Dose}{AUC_{\\text{int,all}}}$"
#> 
#> $cl.int.all$formula_note
#> NULL
#> 
#> $cl.int.all$tier
#> [1] "uncommon"
#> 
#> $cl.int.all$selection
#> list()
#> 
#> 
#> $cl.int.last
#> $cl.int.last$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.int.last$values
#> [1] FALSE  TRUE
#> 
#> $cl.int.last$unit_type
#> [1] "clearance"
#> 
#> $cl.int.last$pretty_name
#> [1] "CL (based on AUCint.last)"
#> 
#> $cl.int.last$desc
#> [1] "Clearance, AUCint.last"
#> 
#> $cl.int.last$sparse
#> [1] FALSE
#> 
#> $cl.int.last$formalsmap
#> $cl.int.last$formalsmap$auc
#> [1] "aucint.last"
#> 
#> 
#> $cl.int.last$depends
#> [1] "aucint.last"
#> 
#> $cl.int.last$datatype
#> [1] "interval"
#> 
#> $cl.int.last$pptestcd_cdisc
#> [1] "cl.int.last"
#> 
#> $cl.int.last$pptest_cdisc
#> [1] "Clearance, AUCint.last"
#> 
#> $cl.int.last$formula
#> [1] "$CL_{\\text{int,last}} = \\frac{Dose}{AUC_{\\text{int,last}}}$"
#> 
#> $cl.int.last$formula_note
#> NULL
#> 
#> $cl.int.last$tier
#> [1] "uncommon"
#> 
#> $cl.int.last$selection
#> list()
#> 
#> 
#> $f
#> $f$FUN
#> [1] "pk.calc.f"
#> 
#> $f$values
#> [1] FALSE  TRUE
#> 
#> $f$unit_type
#> [1] "fraction"
#> 
#> $f$pretty_name
#> [1] "Bioavailability"
#> 
#> $f$desc
#> [1] "Bioavailability (absolute or relative)"
#> 
#> $f$sparse
#> [1] FALSE
#> 
#> $f$formalsmap
#> list()
#> 
#> $f$depends
#> NULL
#> 
#> $f$datatype
#> [1] "interval"
#> 
#> $f$pptestcd_cdisc
#> [1] "FAB"
#> 
#> $f$pptest_cdisc
#> [1] "Absolute Bioavailability"
#> 
#> $f$formula
#> [1] "$F = \\frac{AUC_2 / Dose_2}{AUC_1 / Dose_1}$"
#> 
#> $f$formula_note
#> NULL
#> 
#> $f$tier
#> [1] "uncommon"
#> 
#> $f$selection
#> $f$selection$secondary
#> [1] TRUE
#> 
#> 
#> 
#> $mrt.last
#> $mrt.last$FUN
#> [1] "pk.calc.mrt"
#> 
#> $mrt.last$values
#> [1] FALSE  TRUE
#> 
#> $mrt.last$unit_type
#> [1] "time"
#> 
#> $mrt.last$pretty_name
#> [1] "MRT (based on AUClast)"
#> 
#> $mrt.last$desc
#> [1] "MRT, AUClast/AUMClast"
#> 
#> $mrt.last$sparse
#> [1] FALSE
#> 
#> $mrt.last$formalsmap
#> $mrt.last$formalsmap$auc
#> [1] "auclast"
#> 
#> $mrt.last$formalsmap$aumc
#> [1] "aumclast"
#> 
#> 
#> $mrt.last$depends
#> [1] "auclast"  "aumclast"
#> 
#> $mrt.last$datatype
#> [1] "interval"
#> 
#> $mrt.last$pptestcd_cdisc
#> $mrt.last$pptestcd_cdisc$route
#> $mrt.last$pptestcd_cdisc$route$extravascular
#> [1] "MRTEVLST"
#> 
#> $mrt.last$pptestcd_cdisc$route$intravascular
#> [1] "MRTICLST"
#> 
#> 
#> 
#> $mrt.last$pptest_cdisc
#> $mrt.last$pptest_cdisc$route
#> $mrt.last$pptest_cdisc$route$extravascular
#> [1] "MRT Extravasc to Last Nonzero Conc"
#> 
#> $mrt.last$pptest_cdisc$route$intravascular
#> [1] "MRT IV Cont Inf to Last Nonzero Conc"
#> 
#> 
#> 
#> $mrt.last$formula
#> [1] "$MRT_{\\text{last}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}}$"
#> 
#> $mrt.last$formula_note
#> NULL
#> 
#> $mrt.last$tier
#> [1] "uncommon"
#> 
#> $mrt.last$selection
#> list()
#> 
#> 
#> $mrt.all
#> $mrt.all$FUN
#> [1] "pk.calc.mrt"
#> 
#> $mrt.all$values
#> [1] FALSE  TRUE
#> 
#> $mrt.all$unit_type
#> [1] "time"
#> 
#> $mrt.all$pretty_name
#> [1] "MRT (based on AUCall)"
#> 
#> $mrt.all$desc
#> [1] "MRT, AUCall/AUMCall"
#> 
#> $mrt.all$sparse
#> [1] FALSE
#> 
#> $mrt.all$formalsmap
#> $mrt.all$formalsmap$auc
#> [1] "aucall"
#> 
#> $mrt.all$formalsmap$aumc
#> [1] "aumcall"
#> 
#> 
#> $mrt.all$depends
#> [1] "aucall"  "aumcall"
#> 
#> $mrt.all$datatype
#> [1] "interval"
#> 
#> $mrt.all$pptestcd_cdisc
#> [1] "mrt.all"
#> 
#> $mrt.all$pptest_cdisc
#> [1] "MRT, AUCall/AUMCall"
#> 
#> $mrt.all$formula
#> [1] "$MRT_{\\text{all}} = \\frac{AUMC_{\\text{all}}}{AUC_{\\text{all}}}$"
#> 
#> $mrt.all$formula_note
#> NULL
#> 
#> $mrt.all$tier
#> [1] "uncommon"
#> 
#> $mrt.all$selection
#> list()
#> 
#> 
#> $mrt.int.all
#> $mrt.int.all$FUN
#> [1] "pk.calc.mrt"
#> 
#> $mrt.int.all$values
#> [1] FALSE  TRUE
#> 
#> $mrt.int.all$unit_type
#> [1] "time"
#> 
#> $mrt.int.all$pretty_name
#> [1] "MRT (based on AUCint.all)"
#> 
#> $mrt.int.all$desc
#> [1] "MRT, interval AUCall/AUMCall"
#> 
#> $mrt.int.all$sparse
#> [1] FALSE
#> 
#> $mrt.int.all$formalsmap
#> $mrt.int.all$formalsmap$auc
#> [1] "aucint.all"
#> 
#> $mrt.int.all$formalsmap$aumc
#> [1] "aumcint.all"
#> 
#> 
#> $mrt.int.all$depends
#> [1] "aucint.all"  "aumcint.all"
#> 
#> $mrt.int.all$datatype
#> [1] "interval"
#> 
#> $mrt.int.all$pptestcd_cdisc
#> [1] "mrt.int.all"
#> 
#> $mrt.int.all$pptest_cdisc
#> [1] "MRT, interval AUCall/AUMCall"
#> 
#> $mrt.int.all$formula
#> [1] "$MRT_{\\text{int,all}} = \\frac{AUMC_{\\text{int,all}}}{AUC_{\\text{int,all}}}$"
#> 
#> $mrt.int.all$formula_note
#> NULL
#> 
#> $mrt.int.all$tier
#> [1] "uncommon"
#> 
#> $mrt.int.all$selection
#> list()
#> 
#> 
#> $mrt.int.last
#> $mrt.int.last$FUN
#> [1] "pk.calc.mrt"
#> 
#> $mrt.int.last$values
#> [1] FALSE  TRUE
#> 
#> $mrt.int.last$unit_type
#> [1] "time"
#> 
#> $mrt.int.last$pretty_name
#> [1] "MRT (based on AUCint.last)"
#> 
#> $mrt.int.last$desc
#> [1] "MRT, interval AUClast/AUMClast"
#> 
#> $mrt.int.last$sparse
#> [1] FALSE
#> 
#> $mrt.int.last$formalsmap
#> $mrt.int.last$formalsmap$auc
#> [1] "aucint.last"
#> 
#> $mrt.int.last$formalsmap$aumc
#> [1] "aumcint.last"
#> 
#> 
#> $mrt.int.last$depends
#> [1] "aucint.last"  "aumcint.last"
#> 
#> $mrt.int.last$datatype
#> [1] "interval"
#> 
#> $mrt.int.last$pptestcd_cdisc
#> [1] "mrt.int.last"
#> 
#> $mrt.int.last$pptest_cdisc
#> [1] "MRT, interval AUClast/AUMClast"
#> 
#> $mrt.int.last$formula
#> [1] "$MRT_{\\text{int,last}} = \\frac{AUMC_{\\text{int,last}}}{AUC_{\\text{int,last}}}$"
#> 
#> $mrt.int.last$formula_note
#> NULL
#> 
#> $mrt.int.last$tier
#> [1] "uncommon"
#> 
#> $mrt.int.last$selection
#> list()
#> 
#> 
#> $mrt.iv.last
#> $mrt.iv.last$FUN
#> [1] "pk.calc.mrt.iv"
#> 
#> $mrt.iv.last$values
#> [1] FALSE  TRUE
#> 
#> $mrt.iv.last$unit_type
#> [1] "time"
#> 
#> $mrt.iv.last$pretty_name
#> [1] "MRT (for IV dosing, based on AUClast)"
#> 
#> $mrt.iv.last$desc
#> [1] "IV MRT, AUClast/AUMClast"
#> 
#> $mrt.iv.last$sparse
#> [1] FALSE
#> 
#> $mrt.iv.last$formalsmap
#> $mrt.iv.last$formalsmap$auc
#> [1] "auclast"
#> 
#> $mrt.iv.last$formalsmap$aumc
#> [1] "aumclast"
#> 
#> 
#> $mrt.iv.last$depends
#> [1] "auclast"  "aumclast"
#> 
#> $mrt.iv.last$datatype
#> [1] "interval"
#> 
#> $mrt.iv.last$pptestcd_cdisc
#> [1] "MRTIBLST"
#> 
#> $mrt.iv.last$pptest_cdisc
#> [1] "MRT Intravasc to Last Nonzero Conc"
#> 
#> $mrt.iv.last$formula
#> [1] "$MRT_{\\text{iv,last}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} - \\frac{T_{\\text{inf}}}{2}$"
#> 
#> $mrt.iv.last$formula_note
#> NULL
#> 
#> $mrt.iv.last$tier
#> [1] "uncommon"
#> 
#> $mrt.iv.last$selection
#> list()
#> 
#> 
#> $vss.last
#> $vss.last$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.last$values
#> [1] FALSE  TRUE
#> 
#> $vss.last$unit_type
#> [1] "volume"
#> 
#> $vss.last$pretty_name
#> [1] "Vss (based on AUClast)"
#> 
#> $vss.last$desc
#> [1] "Vss, calc'd through Tlast"
#> 
#> $vss.last$sparse
#> [1] FALSE
#> 
#> $vss.last$formalsmap
#> $vss.last$formalsmap$cl
#> [1] "cl.last"
#> 
#> $vss.last$formalsmap$mrt
#> [1] "mrt.last"
#> 
#> 
#> $vss.last$depends
#> [1] "cl.last"  "mrt.last"
#> 
#> $vss.last$datatype
#> [1] "interval"
#> 
#> $vss.last$pptestcd_cdisc
#> $vss.last$pptestcd_cdisc$route
#> $vss.last$pptestcd_cdisc$route$extravascular
#> [1] "VSSF/FLST"
#> 
#> $vss.last$pptestcd_cdisc$route$intravascular
#> [1] "VSSLST"
#> 
#> 
#> 
#> $vss.last$pptest_cdisc
#> $vss.last$pptest_cdisc$route
#> $vss.last$pptest_cdisc$route$extravascular
#> [1] "Vss by F (based on AUClast)"
#> 
#> $vss.last$pptest_cdisc$route$intravascular
#> [1] "Vss (based on AUClast)"
#> 
#> 
#> 
#> $vss.last$formula
#> [1] "$V_{ss,\\text{last}} = CL_{\\text{last}} \\cdot MRT_{\\text{last}}$"
#> 
#> $vss.last$formula_note
#> NULL
#> 
#> $vss.last$tier
#> [1] "uncommon"
#> 
#> $vss.last$selection
#> list()
#> 
#> 
#> $vss.iv.last
#> $vss.iv.last$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.iv.last$values
#> [1] FALSE  TRUE
#> 
#> $vss.iv.last$unit_type
#> [1] "volume"
#> 
#> $vss.iv.last$pretty_name
#> [1] "Vss (for IV dosing, based on AUClast)"
#> 
#> $vss.iv.last$desc
#> [1] "IV Vss, calc from AUClast"
#> 
#> $vss.iv.last$sparse
#> [1] FALSE
#> 
#> $vss.iv.last$formalsmap
#> $vss.iv.last$formalsmap$cl
#> [1] "cl.last"
#> 
#> $vss.iv.last$formalsmap$mrt
#> [1] "mrt.iv.last"
#> 
#> 
#> $vss.iv.last$depends
#> [1] "cl.last"     "mrt.iv.last"
#> 
#> $vss.iv.last$datatype
#> [1] "interval"
#> 
#> $vss.iv.last$pptestcd_cdisc
#> [1] "VSSIVLST"
#> 
#> $vss.iv.last$pptest_cdisc
#> [1] "Vss (for IV dosing, based on AUClast)"
#> 
#> $vss.iv.last$formula
#> [1] "$V_{ss,\\text{iv,last}} = CL_{\\text{last}} \\cdot MRT_{\\text{iv,last}}$"
#> 
#> $vss.iv.last$formula_note
#> NULL
#> 
#> $vss.iv.last$tier
#> [1] "uncommon"
#> 
#> $vss.iv.last$selection
#> list()
#> 
#> 
#> $vss.all
#> $vss.all$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.all$values
#> [1] FALSE  TRUE
#> 
#> $vss.all$unit_type
#> [1] "volume"
#> 
#> $vss.all$pretty_name
#> [1] "Vss (based on AUCall)"
#> 
#> $vss.all$desc
#> [1] "Vss, calc from AUCall"
#> 
#> $vss.all$sparse
#> [1] FALSE
#> 
#> $vss.all$formalsmap
#> $vss.all$formalsmap$cl
#> [1] "cl.all"
#> 
#> $vss.all$formalsmap$mrt
#> [1] "mrt.all"
#> 
#> 
#> $vss.all$depends
#> [1] "cl.all"  "mrt.all"
#> 
#> $vss.all$datatype
#> [1] "interval"
#> 
#> $vss.all$pptestcd_cdisc
#> [1] "vss.all"
#> 
#> $vss.all$pptest_cdisc
#> [1] "Vss, calc from AUCall"
#> 
#> $vss.all$formula
#> [1] "$V_{ss,\\text{all}} = CL_{\\text{all}} \\cdot MRT_{\\text{all}}$"
#> 
#> $vss.all$formula_note
#> NULL
#> 
#> $vss.all$tier
#> [1] "uncommon"
#> 
#> $vss.all$selection
#> list()
#> 
#> 
#> $vss.int.all
#> $vss.int.all$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.int.all$values
#> [1] FALSE  TRUE
#> 
#> $vss.int.all$unit_type
#> [1] "volume"
#> 
#> $vss.int.all$pretty_name
#> [1] "Vss (based on AUCint.all)"
#> 
#> $vss.int.all$desc
#> [1] "Vss, calc from interval AUCint.all"
#> 
#> $vss.int.all$sparse
#> [1] FALSE
#> 
#> $vss.int.all$formalsmap
#> $vss.int.all$formalsmap$cl
#> [1] "cl.int.all"
#> 
#> $vss.int.all$formalsmap$mrt
#> [1] "mrt.int.all"
#> 
#> 
#> $vss.int.all$depends
#> [1] "cl.int.all"  "mrt.int.all"
#> 
#> $vss.int.all$datatype
#> [1] "interval"
#> 
#> $vss.int.all$pptestcd_cdisc
#> [1] "vss.int.all"
#> 
#> $vss.int.all$pptest_cdisc
#> [1] "Vss, calc from interval AUCint.all"
#> 
#> $vss.int.all$formula
#> [1] "$V_{ss,\\text{int,all}} = CL_{\\text{int,all}} \\cdot MRT_{\\text{int,all}}$"
#> 
#> $vss.int.all$formula_note
#> NULL
#> 
#> $vss.int.all$tier
#> [1] "uncommon"
#> 
#> $vss.int.all$selection
#> list()
#> 
#> 
#> $vss.int.last
#> $vss.int.last$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.int.last$values
#> [1] FALSE  TRUE
#> 
#> $vss.int.last$unit_type
#> [1] "volume"
#> 
#> $vss.int.last$pretty_name
#> [1] "Vss (based on AUCint.last)"
#> 
#> $vss.int.last$desc
#> [1] "Vss, calc from interval AUCint.last"
#> 
#> $vss.int.last$sparse
#> [1] FALSE
#> 
#> $vss.int.last$formalsmap
#> $vss.int.last$formalsmap$cl
#> [1] "cl.int.last"
#> 
#> $vss.int.last$formalsmap$mrt
#> [1] "mrt.int.last"
#> 
#> 
#> $vss.int.last$depends
#> [1] "cl.int.last"  "mrt.int.last"
#> 
#> $vss.int.last$datatype
#> [1] "interval"
#> 
#> $vss.int.last$pptestcd_cdisc
#> [1] "vss.int.last"
#> 
#> $vss.int.last$pptest_cdisc
#> [1] "Vss, calc from interval AUCint.last"
#> 
#> $vss.int.last$formula
#> [1] "$V_{ss,\\text{int,last}} = CL_{\\text{int,last}} \\cdot MRT_{\\text{int,last}}$"
#> 
#> $vss.int.last$formula_note
#> NULL
#> 
#> $vss.int.last$tier
#> [1] "uncommon"
#> 
#> $vss.int.last$selection
#> list()
#> 
#> 
#> $cav
#> $cav$FUN
#> [1] "pk.calc.cav"
#> 
#> $cav$values
#> [1] FALSE  TRUE
#> 
#> $cav$unit_type
#> [1] "conc"
#> 
#> $cav$pretty_name
#> [1] "Cav"
#> 
#> $cav$desc
#> [1] "Avg conc in interval (AUClast)"
#> 
#> $cav$sparse
#> [1] FALSE
#> 
#> $cav$formalsmap
#> $cav$formalsmap$auc
#> [1] "auclast"
#> 
#> 
#> $cav$depends
#> [1] "auclast"
#> 
#> $cav$datatype
#> [1] "interval"
#> 
#> $cav$pptestcd_cdisc
#> [1] "CAVG"
#> 
#> $cav$pptest_cdisc
#> [1] "Average Conc"
#> 
#> $cav$formula
#> [1] "$C_{av} = \\frac{AUC_{\\text{last}}}{t_{end} - t_{start}}$"
#> 
#> $cav$formula_note
#> NULL
#> 
#> $cav$tier
#> [1] "uncommon"
#> 
#> $cav$selection
#> list()
#> 
#> 
#> $cav.int.last
#> $cav.int.last$FUN
#> [1] "pk.calc.cav"
#> 
#> $cav.int.last$values
#> [1] FALSE  TRUE
#> 
#> $cav.int.last$unit_type
#> [1] "conc"
#> 
#> $cav.int.last$pretty_name
#> [1] "Cav"
#> 
#> $cav.int.last$desc
#> [1] "Avg conc in interval (AUCint.last)"
#> 
#> $cav.int.last$sparse
#> [1] FALSE
#> 
#> $cav.int.last$formalsmap
#> $cav.int.last$formalsmap$auc
#> [1] "aucint.last"
#> 
#> 
#> $cav.int.last$depends
#> [1] "aucint.last"
#> 
#> $cav.int.last$datatype
#> [1] "interval"
#> 
#> $cav.int.last$pptestcd_cdisc
#> [1] "CAVGINT"
#> 
#> $cav.int.last$pptest_cdisc
#> [1] "Average Conc from T1 to T2"
#> 
#> $cav.int.last$formula
#> [1] "$C_{av,\\text{int,last}} = \\frac{AUC_{\\text{int,last}}}{t_{end} - t_{start}}$"
#> 
#> $cav.int.last$formula_note
#> NULL
#> 
#> $cav.int.last$tier
#> [1] "uncommon"
#> 
#> $cav.int.last$selection
#> list()
#> 
#> 
#> $cav.int.all
#> $cav.int.all$FUN
#> [1] "pk.calc.cav"
#> 
#> $cav.int.all$values
#> [1] FALSE  TRUE
#> 
#> $cav.int.all$unit_type
#> [1] "conc"
#> 
#> $cav.int.all$pretty_name
#> [1] "Cav"
#> 
#> $cav.int.all$desc
#> [1] "Avg conc in interval (AUCint.all)"
#> 
#> $cav.int.all$sparse
#> [1] FALSE
#> 
#> $cav.int.all$formalsmap
#> $cav.int.all$formalsmap$auc
#> [1] "aucint.all"
#> 
#> 
#> $cav.int.all$depends
#> [1] "aucint.all"
#> 
#> $cav.int.all$datatype
#> [1] "interval"
#> 
#> $cav.int.all$pptestcd_cdisc
#> [1] "CAVGINA"
#> 
#> $cav.int.all$pptest_cdisc
#> [1] "Cavg All"
#> 
#> $cav.int.all$formula
#> [1] "$C_{av,\\text{int,all}} = \\frac{AUC_{\\text{int,all}}}{t_{end} - t_{start}}$"
#> 
#> $cav.int.all$formula_note
#> NULL
#> 
#> $cav.int.all$tier
#> [1] "uncommon"
#> 
#> $cav.int.all$selection
#> list()
#> 
#> 
#> $ctrough
#> $ctrough$FUN
#> [1] "pk.calc.ctrough"
#> 
#> $ctrough$values
#> [1] FALSE  TRUE
#> 
#> $ctrough$unit_type
#> [1] "conc"
#> 
#> $ctrough$pretty_name
#> [1] "Ctrough"
#> 
#> $ctrough$desc
#> [1] "Trough (end of interval) conc"
#> 
#> $ctrough$sparse
#> [1] FALSE
#> 
#> $ctrough$formalsmap
#> list()
#> 
#> $ctrough$depends
#> NULL
#> 
#> $ctrough$datatype
#> [1] "interval"
#> 
#> $ctrough$pptestcd_cdisc
#> [1] "CTROUGH"
#> 
#> $ctrough$pptest_cdisc
#> [1] "Conc Trough"
#> 
#> $ctrough$formula
#> [1] "$C_{\\text{trough}} = C(t_{\\text{end}})$"
#> 
#> $ctrough$formula_note
#> NULL
#> 
#> $ctrough$tier
#> [1] "common"
#> 
#> $ctrough$selection
#> $ctrough$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $cstart
#> $cstart$FUN
#> [1] "pk.calc.cstart"
#> 
#> $cstart$values
#> [1] FALSE  TRUE
#> 
#> $cstart$unit_type
#> [1] "conc"
#> 
#> $cstart$pretty_name
#> [1] "Cstart"
#> 
#> $cstart$desc
#> [1] "The predose concentration"
#> 
#> $cstart$sparse
#> [1] FALSE
#> 
#> $cstart$formalsmap
#> list()
#> 
#> $cstart$depends
#> NULL
#> 
#> $cstart$datatype
#> [1] "interval"
#> 
#> $cstart$pptestcd_cdisc
#> [1] "CSTART"
#> 
#> $cstart$pptest_cdisc
#> [1] "Cstart"
#> 
#> $cstart$formula
#> [1] "$C_{\\text{start}} = C(t_{\\text{start}})$"
#> 
#> $cstart$formula_note
#> NULL
#> 
#> $cstart$tier
#> [1] "uncommon"
#> 
#> $cstart$selection
#> list()
#> 
#> 
#> $ptr
#> $ptr$FUN
#> [1] "pk.calc.ptr"
#> 
#> $ptr$values
#> [1] FALSE  TRUE
#> 
#> $ptr$unit_type
#> [1] "fraction"
#> 
#> $ptr$pretty_name
#> [1] "Peak-to-trough ratio"
#> 
#> $ptr$desc
#> [1] "Peak-to-trough ratio"
#> 
#> $ptr$sparse
#> [1] FALSE
#> 
#> $ptr$formalsmap
#> list()
#> 
#> $ptr$depends
#> [1] "cmax"    "ctrough"
#> 
#> $ptr$datatype
#> [1] "interval"
#> 
#> $ptr$pptestcd_cdisc
#> [1] "PTROUGHR"
#> 
#> $ptr$pptest_cdisc
#> [1] "Peak Trough Ratio"
#> 
#> $ptr$formula
#> [1] "$PTR = \\frac{C_{\\max}}{C_{\\text{trough}}}$"
#> 
#> $ptr$formula_note
#> NULL
#> 
#> $ptr$tier
#> [1] "uncommon"
#> 
#> $ptr$selection
#> list()
#> 
#> 
#> $tlag
#> $tlag$FUN
#> [1] "pk.calc.tlag"
#> 
#> $tlag$values
#> [1] FALSE  TRUE
#> 
#> $tlag$unit_type
#> [1] "time"
#> 
#> $tlag$pretty_name
#> [1] "Tlag"
#> 
#> $tlag$desc
#> [1] "Lag time"
#> 
#> $tlag$sparse
#> [1] FALSE
#> 
#> $tlag$formalsmap
#> list()
#> 
#> $tlag$depends
#> NULL
#> 
#> $tlag$datatype
#> [1] "interval"
#> 
#> $tlag$pptestcd_cdisc
#> [1] "TLAG"
#> 
#> $tlag$pptest_cdisc
#> [1] "Time to First Nonzero Conc"
#> 
#> $tlag$formula
#> [1] "$T_{\\text{lag}} = t_{i: C_{i+1} > C_i, i = \\min}$"
#> 
#> $tlag$formula_note
#> NULL
#> 
#> $tlag$tier
#> [1] "common"
#> 
#> $tlag$selection
#> $tlag$selection$route
#> [1] "extravascular"
#> 
#> 
#> 
#> $deg.fluc
#> $deg.fluc$FUN
#> [1] "pk.calc.deg.fluc"
#> 
#> $deg.fluc$values
#> [1] FALSE  TRUE
#> 
#> $deg.fluc$unit_type
#> [1] "%"
#> 
#> $deg.fluc$pretty_name
#> [1] "Degree of fluctuation"
#> 
#> $deg.fluc$desc
#> [1] "Degree of fluctuation"
#> 
#> $deg.fluc$sparse
#> [1] FALSE
#> 
#> $deg.fluc$formalsmap
#> list()
#> 
#> $deg.fluc$depends
#> [1] "cmax" "cmin" "cav" 
#> 
#> $deg.fluc$datatype
#> [1] "interval"
#> 
#> $deg.fluc$pptestcd_cdisc
#> [1] "DEGFLUC"
#> 
#> $deg.fluc$pptest_cdisc
#> [1] "Degree of fluctuation"
#> 
#> $deg.fluc$formula
#> [1] "$DF = 100 \\cdot \\frac{C_{\\max} - C_{\\min}}{C_{av}}$"
#> 
#> $deg.fluc$formula_note
#> NULL
#> 
#> $deg.fluc$tier
#> [1] "uncommon"
#> 
#> $deg.fluc$selection
#> $deg.fluc$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $swing
#> $swing$FUN
#> [1] "pk.calc.swing"
#> 
#> $swing$values
#> [1] FALSE  TRUE
#> 
#> $swing$unit_type
#> [1] "%"
#> 
#> $swing$pretty_name
#> [1] "Swing"
#> 
#> $swing$desc
#> [1] "Swing relative to Cmin"
#> 
#> $swing$sparse
#> [1] FALSE
#> 
#> $swing$formalsmap
#> list()
#> 
#> $swing$depends
#> [1] "cmax" "cmin"
#> 
#> $swing$datatype
#> [1] "interval"
#> 
#> $swing$pptestcd_cdisc
#> [1] "SWING"
#> 
#> $swing$pptest_cdisc
#> [1] "Swing"
#> 
#> $swing$formula
#> [1] "$Swing = 100 \\cdot \\frac{C_{\\max} - C_{\\min}}{C_{\\min}}$"
#> 
#> $swing$formula_note
#> NULL
#> 
#> $swing$tier
#> [1] "uncommon"
#> 
#> $swing$selection
#> $swing$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $ceoi
#> $ceoi$FUN
#> [1] "pk.calc.ceoi"
#> 
#> $ceoi$values
#> [1] FALSE  TRUE
#> 
#> $ceoi$unit_type
#> [1] "conc"
#> 
#> $ceoi$pretty_name
#> [1] "Ceoi"
#> 
#> $ceoi$desc
#> [1] "Concentration at the end of infusion"
#> 
#> $ceoi$sparse
#> [1] FALSE
#> 
#> $ceoi$formalsmap
#> list()
#> 
#> $ceoi$depends
#> NULL
#> 
#> $ceoi$datatype
#> [1] "interval"
#> 
#> $ceoi$pptestcd_cdisc
#> [1] "CEOI"
#> 
#> $ceoi$pptest_cdisc
#> [1] "Ceoi"
#> 
#> $ceoi$formula
#> [1] "$C_{\\text{eoi}} = C(t = T_{\\text{inf}})$"
#> 
#> $ceoi$formula_note
#> NULL
#> 
#> $ceoi$tier
#> [1] "common"
#> 
#> $ceoi$selection
#> $ceoi$selection$route
#> [1] "iv_infusion"
#> 
#> 
#> 
#> $aucabove.predose.all
#> $aucabove.predose.all$FUN
#> [1] "pk.calc.aucabove"
#> 
#> $aucabove.predose.all$values
#> [1] FALSE  TRUE
#> 
#> $aucabove.predose.all$unit_type
#> [1] "auc"
#> 
#> $aucabove.predose.all$pretty_name
#> [1] "AUC,above"
#> 
#> $aucabove.predose.all$desc
#> [1] "AUC above predose, floor at 0"
#> 
#> $aucabove.predose.all$sparse
#> [1] FALSE
#> 
#> $aucabove.predose.all$formalsmap
#> $aucabove.predose.all$formalsmap$conc_above
#> [1] "cstart"
#> 
#> 
#> $aucabove.predose.all$depends
#> [1] "cstart"
#> 
#> $aucabove.predose.all$datatype
#> [1] "interval"
#> 
#> $aucabove.predose.all$pptestcd_cdisc
#> [1] "AUCABVPA"
#> 
#> $aucabove.predose.all$pptest_cdisc
#> [1] "AUC above predose"
#> 
#> $aucabove.predose.all$formula
#> [1] "$AUC_{\\text{above,predose}} = \\int \\max(C(t) - C_{\\text{start}},\\; 0)\\; dt$"
#> 
#> $aucabove.predose.all$formula_note
#> NULL
#> 
#> $aucabove.predose.all$tier
#> [1] "uncommon"
#> 
#> $aucabove.predose.all$selection
#> list()
#> 
#> 
#> $aucabove.trough.all
#> $aucabove.trough.all$FUN
#> [1] "pk.calc.aucabove"
#> 
#> $aucabove.trough.all$values
#> [1] FALSE  TRUE
#> 
#> $aucabove.trough.all$unit_type
#> [1] "auc"
#> 
#> $aucabove.trough.all$pretty_name
#> [1] "AUC,above"
#> 
#> $aucabove.trough.all$desc
#> [1] "AUC above trough, floor at 0"
#> 
#> $aucabove.trough.all$sparse
#> [1] FALSE
#> 
#> $aucabove.trough.all$formalsmap
#> $aucabove.trough.all$formalsmap$conc_above
#> [1] "ctrough"
#> 
#> 
#> $aucabove.trough.all$depends
#> [1] "ctrough"
#> 
#> $aucabove.trough.all$datatype
#> [1] "interval"
#> 
#> $aucabove.trough.all$pptestcd_cdisc
#> [1] "AUCABVTA"
#> 
#> $aucabove.trough.all$pptest_cdisc
#> [1] "AUC above trough"
#> 
#> $aucabove.trough.all$formula
#> [1] "$AUC_{\\text{above,trough}} = \\int \\max(C(t) - C_{\\text{trough}},\\; 0)\\; dt$"
#> 
#> $aucabove.trough.all$formula_note
#> NULL
#> 
#> $aucabove.trough.all$tier
#> [1] "uncommon"
#> 
#> $aucabove.trough.all$selection
#> list()
#> 
#> 
#> $count_conc
#> $count_conc$FUN
#> [1] "pk.calc.count_conc"
#> 
#> $count_conc$values
#> [1] FALSE  TRUE
#> 
#> $count_conc$unit_type
#> [1] "count"
#> 
#> $count_conc$pretty_name
#> [1] "Concentration count"
#> 
#> $count_conc$desc
#> [1] "Count of non-missing conc"
#> 
#> $count_conc$sparse
#> [1] FALSE
#> 
#> $count_conc$formalsmap
#> list()
#> 
#> $count_conc$depends
#> NULL
#> 
#> $count_conc$datatype
#> [1] "interval"
#> 
#> $count_conc$pptestcd_cdisc
#> [1] "CNTCONC"
#> 
#> $count_conc$pptest_cdisc
#> [1] "Concentration count"
#> 
#> $count_conc$formula
#> [1] "$n_{\\text{conc}} = \\sum_{i} \\mathbf{1}(C_i \\neq NA)$"
#> 
#> $count_conc$formula_note
#> NULL
#> 
#> $count_conc$tier
#> [1] "common"
#> 
#> $count_conc$selection
#> list()
#> 
#> 
#> $count_conc_measured
#> $count_conc_measured$FUN
#> [1] "pk.calc.count_conc_measured"
#> 
#> $count_conc_measured$values
#> [1] FALSE  TRUE
#> 
#> $count_conc_measured$unit_type
#> [1] "count"
#> 
#> $count_conc_measured$pretty_name
#> [1] "Measured concentration count"
#> 
#> $count_conc_measured$desc
#> [1] "Count of measured, non-BLQ conc"
#> 
#> $count_conc_measured$sparse
#> [1] FALSE
#> 
#> $count_conc_measured$formalsmap
#> list()
#> 
#> $count_conc_measured$depends
#> NULL
#> 
#> $count_conc_measured$datatype
#> [1] "interval"
#> 
#> $count_conc_measured$pptestcd_cdisc
#> [1] "count_conc_measured"
#> 
#> $count_conc_measured$pptest_cdisc
#> [1] "Count of measured, non-BLQ conc"
#> 
#> $count_conc_measured$formula
#> [1] "$n_{\\text{measured}} = \\sum_{i} \\mathbf{1}(C_i > 0)$"
#> 
#> $count_conc_measured$formula_note
#> NULL
#> 
#> $count_conc_measured$tier
#> [1] "uncommon"
#> 
#> $count_conc_measured$selection
#> list()
#> 
#> 
#> $totdose
#> $totdose$FUN
#> [1] "pk.calc.totdose"
#> 
#> $totdose$values
#> [1] FALSE  TRUE
#> 
#> $totdose$unit_type
#> [1] "dose"
#> 
#> $totdose$pretty_name
#> [1] "Total dose"
#> 
#> $totdose$desc
#> [1] "Total dose given in interval"
#> 
#> $totdose$sparse
#> [1] FALSE
#> 
#> $totdose$formalsmap
#> list()
#> 
#> $totdose$depends
#> NULL
#> 
#> $totdose$datatype
#> [1] "interval"
#> 
#> $totdose$pptestcd_cdisc
#> [1] "TDOSE"
#> 
#> $totdose$pptest_cdisc
#> [1] "Total dose administered"
#> 
#> $totdose$formula
#> [1] "$Dose_{\\text{total}} = \\sum_i Dose_i$"
#> 
#> $totdose$formula_note
#> NULL
#> 
#> $totdose$tier
#> [1] "uncommon"
#> 
#> $totdose$selection
#> list()
#> 
#> 
#> $volpk
#> $volpk$FUN
#> [1] "pk.calc.volpk"
#> 
#> $volpk$values
#> [1] FALSE  TRUE
#> 
#> $volpk$unit_type
#> [1] "volume"
#> 
#> $volpk$pretty_name
#> [1] "Total Urine Volume"
#> 
#> $volpk$desc
#> [1] "Sum of urine volumes for interval"
#> 
#> $volpk$sparse
#> [1] FALSE
#> 
#> $volpk$formalsmap
#> list()
#> 
#> $volpk$depends
#> NULL
#> 
#> $volpk$datatype
#> [1] "interval"
#> 
#> $volpk$pptestcd_cdisc
#> [1] "VOLPK"
#> 
#> $volpk$pptest_cdisc
#> [1] "Sum of Urine Vol"
#> 
#> $volpk$formula
#> [1] "$V_{\\text{urine}} = \\sum_i V_i$"
#> 
#> $volpk$formula_note
#> NULL
#> 
#> $volpk$tier
#> [1] "common"
#> 
#> $volpk$selection
#> list()
#> 
#> 
#> $ae
#> $ae$FUN
#> [1] "pk.calc.ae"
#> 
#> $ae$values
#> [1] FALSE  TRUE
#> 
#> $ae$unit_type
#> [1] "amount"
#> 
#> $ae$pretty_name
#> [1] "Amount excreted"
#> 
#> $ae$desc
#> [1] "Amount excreted (urine/feces)"
#> 
#> $ae$sparse
#> [1] FALSE
#> 
#> $ae$formalsmap
#> list()
#> 
#> $ae$depends
#> NULL
#> 
#> $ae$datatype
#> [1] "interval"
#> 
#> $ae$pptestcd_cdisc
#> [1] "RCAMINT"
#> 
#> $ae$pptest_cdisc
#> [1] "Amt Rec from T1 to T2"
#> 
#> $ae$formula
#> [1] "$AE = \\sum_i C_i V_i$"
#> 
#> $ae$formula_note
#> NULL
#> 
#> $ae$tier
#> [1] "common"
#> 
#> $ae$selection
#> list()
#> 
#> 
#> $clr.last
#> $clr.last$FUN
#> [1] "pk.calc.clr"
#> 
#> $clr.last$values
#> [1] FALSE  TRUE
#> 
#> $clr.last$unit_type
#> [1] "renal_clearance"
#> 
#> $clr.last$pretty_name
#> [1] "Renal clearance (from AUClast)"
#> 
#> $clr.last$desc
#> [1] "Renal clearance, AUClast"
#> 
#> $clr.last$sparse
#> [1] FALSE
#> 
#> $clr.last$formalsmap
#> $clr.last$formalsmap$auc
#> [1] "auclast"
#> 
#> 
#> $clr.last$depends
#> [1] "ae"
#> 
#> $clr.last$datatype
#> [1] "interval"
#> 
#> $clr.last$pptestcd_cdisc
#> [1] "RENALCL"
#> 
#> $clr.last$pptest_cdisc
#> [1] "Renal CL"
#> 
#> $clr.last$formula
#> [1] "$CL_{R,\\text{last}} = \\frac{AE}{AUC_{\\text{last}}}$"
#> 
#> $clr.last$formula_note
#> NULL
#> 
#> $clr.last$tier
#> [1] "uncommon"
#> 
#> $clr.last$selection
#> $clr.last$selection$secondary
#> [1] TRUE
#> 
#> 
#> 
#> $clr.obs
#> $clr.obs$FUN
#> [1] "pk.calc.clr"
#> 
#> $clr.obs$values
#> [1] FALSE  TRUE
#> 
#> $clr.obs$unit_type
#> [1] "renal_clearance"
#> 
#> $clr.obs$pretty_name
#> [1] "Renal clearance (from AUCinf,obs)"
#> 
#> $clr.obs$desc
#> [1] "Renal clearance, AUCinf,obs"
#> 
#> $clr.obs$sparse
#> [1] FALSE
#> 
#> $clr.obs$formalsmap
#> $clr.obs$formalsmap$auc
#> [1] "aucinf.obs"
#> 
#> 
#> $clr.obs$depends
#> [1] "ae"
#> 
#> $clr.obs$datatype
#> [1] "interval"
#> 
#> $clr.obs$pptestcd_cdisc
#> [1] "RENALCL"
#> 
#> $clr.obs$pptest_cdisc
#> [1] "Renal CL"
#> 
#> $clr.obs$formula
#> [1] "$CL_{R,\\text{obs}} = \\frac{AE}{AUC_{\\infty,\\text{obs}}}$"
#> 
#> $clr.obs$formula_note
#> NULL
#> 
#> $clr.obs$tier
#> [1] "common"
#> 
#> $clr.obs$selection
#> $clr.obs$selection$secondary
#> [1] TRUE
#> 
#> 
#> 
#> $clr.pred
#> $clr.pred$FUN
#> [1] "pk.calc.clr"
#> 
#> $clr.pred$values
#> [1] FALSE  TRUE
#> 
#> $clr.pred$unit_type
#> [1] "renal_clearance"
#> 
#> $clr.pred$pretty_name
#> [1] "Renal clearance (from AUCinf,pred)"
#> 
#> $clr.pred$desc
#> [1] "Renal clearance, AUCinf,pred"
#> 
#> $clr.pred$sparse
#> [1] FALSE
#> 
#> $clr.pred$formalsmap
#> $clr.pred$formalsmap$auc
#> [1] "aucinf.pred"
#> 
#> 
#> $clr.pred$depends
#> [1] "ae"
#> 
#> $clr.pred$datatype
#> [1] "interval"
#> 
#> $clr.pred$pptestcd_cdisc
#> [1] "RENALCL"
#> 
#> $clr.pred$pptest_cdisc
#> [1] "Renal CL"
#> 
#> $clr.pred$formula
#> [1] "$CL_{R,\\text{pred}} = \\frac{AE}{AUC_{\\infty,\\text{pred}}}$"
#> 
#> $clr.pred$formula_note
#> NULL
#> 
#> $clr.pred$tier
#> [1] "uncommon"
#> 
#> $clr.pred$selection
#> $clr.pred$selection$secondary
#> [1] TRUE
#> 
#> 
#> 
#> $fe
#> $fe$FUN
#> [1] "pk.calc.fe"
#> 
#> $fe$values
#> [1] FALSE  TRUE
#> 
#> $fe$unit_type
#> [1] "amount_dose"
#> 
#> $fe$pretty_name
#> [1] "Fraction excreted"
#> 
#> $fe$desc
#> [1] "Fraction of dose excreted"
#> 
#> $fe$sparse
#> [1] FALSE
#> 
#> $fe$formalsmap
#> list()
#> 
#> $fe$depends
#> [1] "ae"
#> 
#> $fe$datatype
#> [1] "interval"
#> 
#> $fe$pptestcd_cdisc
#> [1] "FREXINT"
#> 
#> $fe$pptest_cdisc
#> [1] "Fract Excr from T1 to T2"
#> 
#> $fe$formula
#> [1] "$f_e = \\frac{AE}{Dose}$"
#> 
#> $fe$formula_note
#> NULL
#> 
#> $fe$tier
#> [1] "common"
#> 
#> $fe$selection
#> list()
#> 
#> 
#> $ertlst
#> $ertlst$FUN
#> [1] "pk.calc.ertlst"
#> 
#> $ertlst$values
#> [1] FALSE  TRUE
#> 
#> $ertlst$unit_type
#> [1] "time"
#> 
#> $ertlst$pretty_name
#> [1] "Tlast excretion rate"
#> 
#> $ertlst$desc
#> [1] "Midpoint time of last excr rate"
#> 
#> $ertlst$sparse
#> [1] FALSE
#> 
#> $ertlst$formalsmap
#> list()
#> 
#> $ertlst$depends
#> NULL
#> 
#> $ertlst$datatype
#> [1] "interval"
#> 
#> $ertlst$pptestcd_cdisc
#> [1] "ERTLST"
#> 
#> $ertlst$pptest_cdisc
#> [1] "Midpoint of Interval of Last Nonzero ER"
#> 
#> $ertlst$formula
#> [1] "$T_{\\text{last,ER}} = t_{\\text{mid},i: ER_i > 0, i = \\max}$"
#> 
#> $ertlst$formula_note
#> NULL
#> 
#> $ertlst$tier
#> [1] "uncommon"
#> 
#> $ertlst$selection
#> list()
#> 
#> 
#> $ermax
#> $ermax$FUN
#> [1] "pk.calc.ermax"
#> 
#> $ermax$values
#> [1] FALSE  TRUE
#> 
#> $ermax$unit_type
#> [1] "amount_time"
#> 
#> $ermax$pretty_name
#> [1] "Maximum excretion rate"
#> 
#> $ermax$desc
#> [1] "Maximum excretion rate"
#> 
#> $ermax$sparse
#> [1] FALSE
#> 
#> $ermax$formalsmap
#> list()
#> 
#> $ermax$depends
#> NULL
#> 
#> $ermax$datatype
#> [1] "interval"
#> 
#> $ermax$pptestcd_cdisc
#> [1] "ERMAX"
#> 
#> $ermax$pptest_cdisc
#> [1] "Max Excretion Rate"
#> 
#> $ermax$formula
#> [1] "$ER_{\\max} = \\max_i \\left( \\frac{C_i V_i}{d_i} \\right)$"
#> 
#> $ermax$formula_note
#> NULL
#> 
#> $ermax$tier
#> [1] "uncommon"
#> 
#> $ermax$selection
#> list()
#> 
#> 
#> $ertmax
#> $ertmax$FUN
#> [1] "pk.calc.ertmax"
#> 
#> $ertmax$values
#> [1] FALSE  TRUE
#> 
#> $ertmax$unit_type
#> [1] "time"
#> 
#> $ertmax$pretty_name
#> [1] "Tmax excretion rate"
#> 
#> $ertmax$desc
#> [1] "Midpoint time of max excr rate"
#> 
#> $ertmax$sparse
#> [1] FALSE
#> 
#> $ertmax$formalsmap
#> list()
#> 
#> $ertmax$depends
#> NULL
#> 
#> $ertmax$datatype
#> [1] "interval"
#> 
#> $ertmax$pptestcd_cdisc
#> [1] "ERTMAX"
#> 
#> $ertmax$pptest_cdisc
#> [1] "Midpoint of Interval of Maximum ER"
#> 
#> $ertmax$formula
#> [1] "$T_{\\max,ER} = t_{\\text{mid},i: ER_i = ER_{\\max}}$"
#> 
#> $ertmax$formula_note
#> NULL
#> 
#> $ertmax$tier
#> [1] "uncommon"
#> 
#> $ertmax$selection
#> list()
#> 
#> 
#> $erint
#> $erint$FUN
#> [1] "pk.calc.erint"
#> 
#> $erint$values
#> [1] FALSE  TRUE
#> 
#> $erint$unit_type
#> [1] "amount_time"
#> 
#> $erint$pretty_name
#> [1] "Excretion rate"
#> 
#> $erint$desc
#> [1] "Excretion rate from T1 to T2"
#> 
#> $erint$sparse
#> [1] FALSE
#> 
#> $erint$formalsmap
#> list()
#> 
#> $erint$depends
#> [1] "ae"
#> 
#> $erint$datatype
#> [1] "interval"
#> 
#> $erint$pptestcd_cdisc
#> [1] "ERINT"
#> 
#> $erint$pptest_cdisc
#> [1] "Excret Rate from T1 to T2"
#> 
#> $erint$formula
#> [1] "$ER_{T_1 \\rightarrow T_2} = \\frac{A_e}{T_2 - T_1}$"
#> 
#> $erint$formula_note
#> [1] "Amount recovered during the interval divided by the interval duration"
#> 
#> $erint$tier
#> [1] "uncommon"
#> 
#> $erint$selection
#> list()
#> 
#> 
#> $erlst
#> $erlst$FUN
#> [1] "pk.calc.erlst"
#> 
#> $erlst$values
#> [1] FALSE  TRUE
#> 
#> $erlst$unit_type
#> [1] "amount_time"
#> 
#> $erlst$pretty_name
#> [1] "Last measurable excretion rate"
#> 
#> $erlst$desc
#> [1] "Last measurable excretion rate"
#> 
#> $erlst$sparse
#> [1] FALSE
#> 
#> $erlst$formalsmap
#> list()
#> 
#> $erlst$depends
#> NULL
#> 
#> $erlst$datatype
#> [1] "interval"
#> 
#> $erlst$pptestcd_cdisc
#> [1] "ERLST"
#> 
#> $erlst$pptest_cdisc
#> [1] "Last Meas Excretion Rate"
#> 
#> $erlst$formula
#> [1] "$ER_{\\text{last}} = \\frac{C_l V_l}{d_l}$"
#> 
#> $erlst$formula_note
#> [1] "The last collection with a nonzero excretion rate, ordered by collection midpoint"
#> 
#> $erlst$tier
#> [1] "uncommon"
#> 
#> $erlst$selection
#> list()
#> 
#> 
#> $sparse_auclast
#> $sparse_auclast$FUN
#> [1] "pk.calc.sparse_auclast"
#> 
#> $sparse_auclast$values
#> [1] FALSE  TRUE
#> 
#> $sparse_auclast$unit_type
#> [1] "auc"
#> 
#> $sparse_auclast$pretty_name
#> [1] "Sparse AUClast"
#> 
#> $sparse_auclast$desc
#> [1] "Sparse AUC to last conc above LOQ"
#> 
#> $sparse_auclast$sparse
#> [1] TRUE
#> 
#> $sparse_auclast$formalsmap
#> list()
#> 
#> $sparse_auclast$depends
#> NULL
#> 
#> $sparse_auclast$datatype
#> [1] "interval"
#> 
#> $sparse_auclast$pptestcd_cdisc
#> [1] "SPARSEAL"
#> 
#> $sparse_auclast$pptest_cdisc
#> [1] "Sparse AUClast"
#> 
#> $sparse_auclast$formula
#> [1] "$AUC_{\\text{sparse}} = \\sum_k \\frac{\\bar{C}_k + \\bar{C}_{k+1}}{2} \\Delta t_k$"
#> 
#> $sparse_auclast$formula_note
#> [1] "Linear trapezoidal using population mean concentrations"
#> 
#> $sparse_auclast$tier
#> [1] "common"
#> 
#> $sparse_auclast$selection
#> list()
#> 
#> 
#> $sparse_auc_se
#> $sparse_auc_se$FUN
#> [1] NA
#> 
#> $sparse_auc_se$values
#> [1] FALSE  TRUE
#> 
#> $sparse_auc_se$unit_type
#> [1] "auc"
#> 
#> $sparse_auc_se$pretty_name
#> [1] "Sparse AUClast standard error"
#> 
#> $sparse_auc_se$desc
#> [1] "SE of sparse AUC to last conc above LOQ"
#> 
#> $sparse_auc_se$sparse
#> [1] FALSE
#> 
#> $sparse_auc_se$formalsmap
#> list()
#> 
#> $sparse_auc_se$depends
#> [1] "sparse_auclast"
#> 
#> $sparse_auc_se$datatype
#> [1] "interval"
#> 
#> $sparse_auc_se$pptestcd_cdisc
#> [1] "SPARSEAS"
#> 
#> $sparse_auc_se$pptest_cdisc
#> [1] "Sparse AUClast standard error"
#> 
#> $sparse_auc_se$formula
#> [1] "$SE(AUC_{\\text{sparse}}) = \\sqrt{\\sum_{i,j} w_i w_j \\hat{\\sigma}_{ij} / n}$"
#> 
#> $sparse_auc_se$formula_note
#> [1] "Variance from weighted covariance across subjects (Nedelman and Jia 1998, Holder 2001)"
#> 
#> $sparse_auc_se$tier
#> [1] "common"
#> 
#> $sparse_auc_se$selection
#> list()
#> 
#> 
#> $sparse_auc_df
#> $sparse_auc_df$FUN
#> [1] NA
#> 
#> $sparse_auc_df$values
#> [1] FALSE  TRUE
#> 
#> $sparse_auc_df$unit_type
#> [1] "count"
#> 
#> $sparse_auc_df$pretty_name
#> [1] "Sparse AUClast degrees of freedom"
#> 
#> $sparse_auc_df$desc
#> [1] "DF for sparse AUC to last conc above LOQ"
#> 
#> $sparse_auc_df$sparse
#> [1] FALSE
#> 
#> $sparse_auc_df$formalsmap
#> list()
#> 
#> $sparse_auc_df$depends
#> [1] "sparse_auclast"
#> 
#> $sparse_auc_df$datatype
#> [1] "interval"
#> 
#> $sparse_auc_df$pptestcd_cdisc
#> [1] "SPARSEAD"
#> 
#> $sparse_auc_df$pptest_cdisc
#> [1] "Sparse AUClast degrees of freedom"
#> 
#> $sparse_auc_df$formula
#> [1] "$df = \\frac{\\left(\\sum w_i^2 \\hat{\\sigma}_{ii}/n_i\\right)^2}{\\sum w_i^4 \\hat{\\sigma}_{ii}^2 / (n_i^2(n_i-1))}$"
#> 
#> $sparse_auc_df$formula_note
#> [1] "Satterthwaite approximation (Nedelman et al 1995, eq. 6a)"
#> 
#> $sparse_auc_df$tier
#> [1] "uncommon"
#> 
#> $sparse_auc_df$selection
#> list()
#> 
#> 
#> $sparse_aumclast
#> $sparse_aumclast$FUN
#> [1] "pk.calc.sparse_aumclast"
#> 
#> $sparse_aumclast$values
#> [1] FALSE  TRUE
#> 
#> $sparse_aumclast$unit_type
#> [1] "aumc"
#> 
#> $sparse_aumclast$pretty_name
#> [1] "Sparse AUMClast"
#> 
#> $sparse_aumclast$desc
#> [1] "Sparse AUMC to last conc above LOQ"
#> 
#> $sparse_aumclast$sparse
#> [1] TRUE
#> 
#> $sparse_aumclast$formalsmap
#> list()
#> 
#> $sparse_aumclast$depends
#> [1] "sparse_auclast"
#> 
#> $sparse_aumclast$datatype
#> [1] "interval"
#> 
#> $sparse_aumclast$pptestcd_cdisc
#> [1] "sparse_aumclast"
#> 
#> $sparse_aumclast$pptest_cdisc
#> [1] "Sparse AUMC to last conc above LOQ"
#> 
#> $sparse_aumclast$formula
#> NULL
#> 
#> $sparse_aumclast$formula_note
#> NULL
#> 
#> $sparse_aumclast$tier
#> [1] "uncommon"
#> 
#> $sparse_aumclast$selection
#> list()
#> 
#> 
#> $sparse_aumc_se
#> $sparse_aumc_se$FUN
#> [1] NA
#> 
#> $sparse_aumc_se$values
#> [1] FALSE  TRUE
#> 
#> $sparse_aumc_se$unit_type
#> [1] "aumc"
#> 
#> $sparse_aumc_se$pretty_name
#> [1] "Sparse AUMC standard error"
#> 
#> $sparse_aumc_se$desc
#> [1] "SE of sparse AUMC to last conc above LOQ"
#> 
#> $sparse_aumc_se$sparse
#> [1] FALSE
#> 
#> $sparse_aumc_se$formalsmap
#> list()
#> 
#> $sparse_aumc_se$depends
#> [1] "sparse_aumclast"
#> 
#> $sparse_aumc_se$datatype
#> [1] "interval"
#> 
#> $sparse_aumc_se$pptestcd_cdisc
#> [1] "sparse_aumc_se"
#> 
#> $sparse_aumc_se$pptest_cdisc
#> [1] "SE of sparse AUMC to last conc above LOQ"
#> 
#> $sparse_aumc_se$formula
#> NULL
#> 
#> $sparse_aumc_se$formula_note
#> NULL
#> 
#> $sparse_aumc_se$tier
#> [1] "uncommon"
#> 
#> $sparse_aumc_se$selection
#> list()
#> 
#> 
#> $sparse_aumc_df
#> $sparse_aumc_df$FUN
#> [1] NA
#> 
#> $sparse_aumc_df$values
#> [1] FALSE  TRUE
#> 
#> $sparse_aumc_df$unit_type
#> [1] "count"
#> 
#> $sparse_aumc_df$pretty_name
#> [1] "Sparse AUMC degrees of freedom"
#> 
#> $sparse_aumc_df$desc
#> [1] "variance DF for sparse AUMC to Tlast"
#> 
#> $sparse_aumc_df$sparse
#> [1] FALSE
#> 
#> $sparse_aumc_df$formalsmap
#> list()
#> 
#> $sparse_aumc_df$depends
#> [1] "sparse_aumclast"
#> 
#> $sparse_aumc_df$datatype
#> [1] "interval"
#> 
#> $sparse_aumc_df$pptestcd_cdisc
#> [1] "sparse_aumc_df"
#> 
#> $sparse_aumc_df$pptest_cdisc
#> [1] "variance DF for sparse AUMC to Tlast"
#> 
#> $sparse_aumc_df$formula
#> NULL
#> 
#> $sparse_aumc_df$formula_note
#> NULL
#> 
#> $sparse_aumc_df$tier
#> [1] "uncommon"
#> 
#> $sparse_aumc_df$selection
#> list()
#> 
#> 
#> $time_above
#> $time_above$FUN
#> [1] "pk.calc.time_above"
#> 
#> $time_above$values
#> [1] FALSE  TRUE
#> 
#> $time_above$unit_type
#> [1] "time"
#> 
#> $time_above$pretty_name
#> [1] "Time above Concentration"
#> 
#> $time_above$desc
#> [1] "Time above a given concentration"
#> 
#> $time_above$sparse
#> [1] FALSE
#> 
#> $time_above$formalsmap
#> list()
#> 
#> $time_above$depends
#> NULL
#> 
#> $time_above$datatype
#> [1] "interval"
#> 
#> $time_above$pptestcd_cdisc
#> [1] "TAT"
#> 
#> $time_above$pptest_cdisc
#> [1] "Time Above Threshold"
#> 
#> $time_above$formula
#> [1] "$T_{\\text{above}} = \\sum \\Delta t_{i: C_i \\geq C_{\\text{ref}}}$"
#> 
#> $time_above$formula_note
#> [1] "Crossing times interpolated using the AUC method (linear or log-linear)"
#> 
#> $time_above$tier
#> [1] "uncommon"
#> 
#> $time_above$selection
#> list()
#> 
#> 
#> $aucivlast
#> $aucivlast$FUN
#> [1] "pk.calc.auciv"
#> 
#> $aucivlast$values
#> [1] FALSE  TRUE
#> 
#> $aucivlast$unit_type
#> [1] "auc"
#> 
#> $aucivlast$pretty_name
#> [1] "AUClast (IV dosing)"
#> 
#> $aucivlast$desc
#> [1] "AUClast, IV back-extrap C0"
#> 
#> $aucivlast$sparse
#> [1] FALSE
#> 
#> $aucivlast$formalsmap
#> $aucivlast$formalsmap$auc
#> [1] "auclast"
#> 
#> $aucivlast$formalsmap$auc.type
#> [1] "AUClast"
#> 
#> $aucivlast$formalsmap$lambda.z
#> NULL
#> 
#> $aucivlast$formalsmap$clast
#> NULL
#> 
#> 
#> $aucivlast$depends
#> [1] "auclast" "c0"     
#> 
#> $aucivlast$datatype
#> [1] "interval"
#> 
#> $aucivlast$pptestcd_cdisc
#> [1] "AUCIVLST"
#> 
#> $aucivlast$pptest_cdisc
#> [1] "AUClast (IV dosing)"
#> 
#> $aucivlast$formula
#> [1] "$AUC_{\\text{iv,last}} = AUC_{\\text{last}} + AUC(C_0, t_1) - AUC(C(0), t_1)$"
#> 
#> $aucivlast$formula_note
#> NULL
#> 
#> $aucivlast$tier
#> [1] "uncommon"
#> 
#> $aucivlast$selection
#> list()
#> 
#> 
#> $aucivall
#> $aucivall$FUN
#> [1] "pk.calc.auciv"
#> 
#> $aucivall$values
#> [1] FALSE  TRUE
#> 
#> $aucivall$unit_type
#> [1] "auc"
#> 
#> $aucivall$pretty_name
#> [1] "AUCall (IV dosing)"
#> 
#> $aucivall$desc
#> [1] "AUCall, IV back-extrap C0"
#> 
#> $aucivall$sparse
#> [1] FALSE
#> 
#> $aucivall$formalsmap
#> $aucivall$formalsmap$auc
#> [1] "aucall"
#> 
#> $aucivall$formalsmap$auc.type
#> [1] "AUCall"
#> 
#> $aucivall$formalsmap$lambda.z
#> NULL
#> 
#> $aucivall$formalsmap$clast
#> NULL
#> 
#> 
#> $aucivall$depends
#> [1] "aucall" "c0"    
#> 
#> $aucivall$datatype
#> [1] "interval"
#> 
#> $aucivall$pptestcd_cdisc
#> [1] "AUCIVA"
#> 
#> $aucivall$pptest_cdisc
#> [1] "AUCall (IV dosing)"
#> 
#> $aucivall$formula
#> [1] "$AUC_{\\text{iv,all}} = AUC_{\\text{all}} + AUC(C_0, t_1) - AUC(C(0), t_1)$"
#> 
#> $aucivall$formula_note
#> NULL
#> 
#> $aucivall$tier
#> [1] "uncommon"
#> 
#> $aucivall$selection
#> list()
#> 
#> 
#> $aucivint.last
#> $aucivint.last$FUN
#> [1] "pk.calc.auciv"
#> 
#> $aucivint.last$values
#> [1] FALSE  TRUE
#> 
#> $aucivint.last$unit_type
#> [1] "auc"
#> 
#> $aucivint.last$pretty_name
#> [1] "AUCint,last (IV dosing)"
#> 
#> $aucivint.last$desc
#> [1] "AUCint.last, IV back-extrap C0"
#> 
#> $aucivint.last$sparse
#> [1] FALSE
#> 
#> $aucivint.last$formalsmap
#> $aucivint.last$formalsmap$auc
#> [1] "aucint.last"
#> 
#> $aucivint.last$formalsmap$auc.type
#> NULL
#> 
#> $aucivint.last$formalsmap$lambda.z
#> NULL
#> 
#> $aucivint.last$formalsmap$clast
#> NULL
#> 
#> 
#> $aucivint.last$depends
#> [1] "aucint.last" "c0"         
#> 
#> $aucivint.last$datatype
#> [1] "interval"
#> 
#> $aucivint.last$pptestcd_cdisc
#> [1] "AUCIVILT"
#> 
#> $aucivint.last$pptest_cdisc
#> [1] "AUCint,last (IV dosing)"
#> 
#> $aucivint.last$formula
#> [1] "$AUC_{\\text{iv,int,last}} = AUC_{\\text{int,last}} + AUC(C_0, t_1) - AUC(C(0), t_1)$"
#> 
#> $aucivint.last$formula_note
#> NULL
#> 
#> $aucivint.last$tier
#> [1] "uncommon"
#> 
#> $aucivint.last$selection
#> list()
#> 
#> 
#> $aucivint.all
#> $aucivint.all$FUN
#> [1] "pk.calc.auciv"
#> 
#> $aucivint.all$values
#> [1] FALSE  TRUE
#> 
#> $aucivint.all$unit_type
#> [1] "auc"
#> 
#> $aucivint.all$pretty_name
#> [1] "AUCint,all (IV dosing)"
#> 
#> $aucivint.all$desc
#> [1] "AUCint.all, IV back-extrap C0"
#> 
#> $aucivint.all$sparse
#> [1] FALSE
#> 
#> $aucivint.all$formalsmap
#> $aucivint.all$formalsmap$auc
#> [1] "aucint.all"
#> 
#> $aucivint.all$formalsmap$auc.type
#> NULL
#> 
#> $aucivint.all$formalsmap$lambda.z
#> NULL
#> 
#> $aucivint.all$formalsmap$clast
#> NULL
#> 
#> 
#> $aucivint.all$depends
#> [1] "aucint.all" "c0"        
#> 
#> $aucivint.all$datatype
#> [1] "interval"
#> 
#> $aucivint.all$pptestcd_cdisc
#> [1] "AUCIVINA"
#> 
#> $aucivint.all$pptest_cdisc
#> [1] "AUCint,all (IV dosing)"
#> 
#> $aucivint.all$formula
#> [1] "$AUC_{\\text{iv,int,all}} = AUC_{\\text{int,all}} + AUC(C_0, t_1) - AUC(C(0), t_1)$"
#> 
#> $aucivint.all$formula_note
#> NULL
#> 
#> $aucivint.all$tier
#> [1] "uncommon"
#> 
#> $aucivint.all$selection
#> list()
#> 
#> 
#> $aucivpbextlast
#> $aucivpbextlast$FUN
#> [1] "pk.calc.auciv_pbext"
#> 
#> $aucivpbextlast$values
#> [1] FALSE  TRUE
#> 
#> $aucivpbextlast$unit_type
#> [1] "%"
#> 
#> $aucivpbextlast$pretty_name
#> [1] "AUCbext (based on AUClast)"
#> 
#> $aucivpbextlast$desc
#> [1] "Back-extrap %, IV, AUClast"
#> 
#> $aucivpbextlast$sparse
#> [1] FALSE
#> 
#> $aucivpbextlast$formalsmap
#> $aucivpbextlast$formalsmap$auc
#> [1] "auclast"
#> 
#> $aucivpbextlast$formalsmap$auciv
#> [1] "aucivlast"
#> 
#> 
#> $aucivpbextlast$depends
#> [1] "auclast"   "aucivlast"
#> 
#> $aucivpbextlast$datatype
#> [1] "interval"
#> 
#> $aucivpbextlast$pptestcd_cdisc
#> [1] "AUCIVPLT"
#> 
#> $aucivpbextlast$pptest_cdisc
#> [1] "AUCbext (based on AUClast)"
#> 
#> $aucivpbextlast$formula
#> [1] "$\\%AUC_{\\text{bext,last}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{last}}}{AUC_{\\text{iv,last}}}\\right)$"
#> 
#> $aucivpbextlast$formula_note
#> NULL
#> 
#> $aucivpbextlast$tier
#> [1] "uncommon"
#> 
#> $aucivpbextlast$selection
#> list()
#> 
#> 
#> $aucivpbextall
#> $aucivpbextall$FUN
#> [1] "pk.calc.auciv_pbext"
#> 
#> $aucivpbextall$values
#> [1] FALSE  TRUE
#> 
#> $aucivpbextall$unit_type
#> [1] "%"
#> 
#> $aucivpbextall$pretty_name
#> [1] "AUCbext (based on AUCall)"
#> 
#> $aucivpbextall$desc
#> [1] "Back-extrap %, IV, AUCall"
#> 
#> $aucivpbextall$sparse
#> [1] FALSE
#> 
#> $aucivpbextall$formalsmap
#> $aucivpbextall$formalsmap$auc
#> [1] "aucall"
#> 
#> $aucivpbextall$formalsmap$auciv
#> [1] "aucivall"
#> 
#> 
#> $aucivpbextall$depends
#> [1] "aucall"   "aucivall"
#> 
#> $aucivpbextall$datatype
#> [1] "interval"
#> 
#> $aucivpbextall$pptestcd_cdisc
#> [1] "AUCIVPEA"
#> 
#> $aucivpbextall$pptest_cdisc
#> [1] "AUCbext (based on AUCall)"
#> 
#> $aucivpbextall$formula
#> [1] "$\\%AUC_{\\text{bext,all}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{all}}}{AUC_{\\text{iv,all}}}\\right)$"
#> 
#> $aucivpbextall$formula_note
#> NULL
#> 
#> $aucivpbextall$tier
#> [1] "uncommon"
#> 
#> $aucivpbextall$selection
#> list()
#> 
#> 
#> $aucivpbextint.last
#> $aucivpbextint.last$FUN
#> [1] "pk.calc.auciv_pbext"
#> 
#> $aucivpbextint.last$values
#> [1] FALSE  TRUE
#> 
#> $aucivpbextint.last$unit_type
#> [1] "%"
#> 
#> $aucivpbextint.last$pretty_name
#> [1] "AUCbext (based on AUCint,last)"
#> 
#> $aucivpbextint.last$desc
#> [1] "Back-extrap %, IV, AUCint.last"
#> 
#> $aucivpbextint.last$sparse
#> [1] FALSE
#> 
#> $aucivpbextint.last$formalsmap
#> $aucivpbextint.last$formalsmap$auc
#> [1] "aucint.last"
#> 
#> $aucivpbextint.last$formalsmap$auciv
#> [1] "aucivint.last"
#> 
#> 
#> $aucivpbextint.last$depends
#> [1] "aucint.last"   "aucivint.last"
#> 
#> $aucivpbextint.last$datatype
#> [1] "interval"
#> 
#> $aucivpbextint.last$pptestcd_cdisc
#> [1] "AUCIVPIL"
#> 
#> $aucivpbextint.last$pptest_cdisc
#> [1] "AUCbext (based on AUCint,last)"
#> 
#> $aucivpbextint.last$formula
#> [1] "$\\%AUC_{\\text{bext,int,last}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{int,last}}}{AUC_{\\text{iv,int,last}}}\\right)$"
#> 
#> $aucivpbextint.last$formula_note
#> NULL
#> 
#> $aucivpbextint.last$tier
#> [1] "uncommon"
#> 
#> $aucivpbextint.last$selection
#> list()
#> 
#> 
#> $aucivpbextint.all
#> $aucivpbextint.all$FUN
#> [1] "pk.calc.auciv_pbext"
#> 
#> $aucivpbextint.all$values
#> [1] FALSE  TRUE
#> 
#> $aucivpbextint.all$unit_type
#> [1] "%"
#> 
#> $aucivpbextint.all$pretty_name
#> [1] "AUCbext (based on AUCint,all)"
#> 
#> $aucivpbextint.all$desc
#> [1] "Back-extrap %, IV, AUCint.all"
#> 
#> $aucivpbextint.all$sparse
#> [1] FALSE
#> 
#> $aucivpbextint.all$formalsmap
#> $aucivpbextint.all$formalsmap$auc
#> [1] "aucint.all"
#> 
#> $aucivpbextint.all$formalsmap$auciv
#> [1] "aucivint.all"
#> 
#> 
#> $aucivpbextint.all$depends
#> [1] "aucint.all"   "aucivint.all"
#> 
#> $aucivpbextint.all$datatype
#> [1] "interval"
#> 
#> $aucivpbextint.all$pptestcd_cdisc
#> [1] "AUCIVPIA"
#> 
#> $aucivpbextint.all$pptest_cdisc
#> [1] "AUCbext (based on AUCint,all)"
#> 
#> $aucivpbextint.all$formula
#> [1] "$\\%AUC_{\\text{bext,int,all}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{int,all}}}{AUC_{\\text{iv,int,all}}}\\right)$"
#> 
#> $aucivpbextint.all$formula_note
#> NULL
#> 
#> $aucivpbextint.all$tier
#> [1] "uncommon"
#> 
#> $aucivpbextint.all$selection
#> list()
#> 
#> 
#> $aumcivlast
#> $aumcivlast$FUN
#> [1] "pk.calc.aumciv"
#> 
#> $aumcivlast$values
#> [1] FALSE  TRUE
#> 
#> $aumcivlast$unit_type
#> [1] "aumc"
#> 
#> $aumcivlast$pretty_name
#> [1] "AUMClast (IV dosing)"
#> 
#> $aumcivlast$desc
#> [1] "AUMClast, IV back-extrap C0"
#> 
#> $aumcivlast$sparse
#> [1] FALSE
#> 
#> $aumcivlast$formalsmap
#> $aumcivlast$formalsmap$aumc
#> [1] "aumclast"
#> 
#> $aumcivlast$formalsmap$auc.type
#> [1] "AUClast"
#> 
#> $aumcivlast$formalsmap$lambda.z
#> NULL
#> 
#> $aumcivlast$formalsmap$clast
#> NULL
#> 
#> 
#> $aumcivlast$depends
#> [1] "aumclast" "c0"      
#> 
#> $aumcivlast$datatype
#> [1] "interval"
#> 
#> $aumcivlast$pptestcd_cdisc
#> [1] "aumcivlast"
#> 
#> $aumcivlast$pptest_cdisc
#> [1] "AUMClast, IV back-extrap C0"
#> 
#> $aumcivlast$formula
#> NULL
#> 
#> $aumcivlast$formula_note
#> NULL
#> 
#> $aumcivlast$tier
#> [1] "uncommon"
#> 
#> $aumcivlast$selection
#> list()
#> 
#> 
#> $aumcivall
#> $aumcivall$FUN
#> [1] "pk.calc.aumciv"
#> 
#> $aumcivall$values
#> [1] FALSE  TRUE
#> 
#> $aumcivall$unit_type
#> [1] "aumc"
#> 
#> $aumcivall$pretty_name
#> [1] "AUMCall (IV dosing)"
#> 
#> $aumcivall$desc
#> [1] "AUMCall, IV back-extrap C0"
#> 
#> $aumcivall$sparse
#> [1] FALSE
#> 
#> $aumcivall$formalsmap
#> $aumcivall$formalsmap$aumc
#> [1] "aumcall"
#> 
#> $aumcivall$formalsmap$auc.type
#> [1] "AUCall"
#> 
#> $aumcivall$formalsmap$lambda.z
#> NULL
#> 
#> $aumcivall$formalsmap$clast
#> NULL
#> 
#> 
#> $aumcivall$depends
#> [1] "aumcall" "c0"     
#> 
#> $aumcivall$datatype
#> [1] "interval"
#> 
#> $aumcivall$pptestcd_cdisc
#> [1] "aumcivall"
#> 
#> $aumcivall$pptest_cdisc
#> [1] "AUMCall, IV back-extrap C0"
#> 
#> $aumcivall$formula
#> NULL
#> 
#> $aumcivall$formula_note
#> NULL
#> 
#> $aumcivall$tier
#> [1] "uncommon"
#> 
#> $aumcivall$selection
#> list()
#> 
#> 
#> $aumcivint.last
#> $aumcivint.last$FUN
#> [1] "pk.calc.aumciv"
#> 
#> $aumcivint.last$values
#> [1] FALSE  TRUE
#> 
#> $aumcivint.last$unit_type
#> [1] "aumc"
#> 
#> $aumcivint.last$pretty_name
#> [1] "AUMCint,last (IV dosing)"
#> 
#> $aumcivint.last$desc
#> [1] "AUMCint.last, IV back-extrap C0"
#> 
#> $aumcivint.last$sparse
#> [1] FALSE
#> 
#> $aumcivint.last$formalsmap
#> $aumcivint.last$formalsmap$aumc
#> [1] "aumcint.last"
#> 
#> $aumcivint.last$formalsmap$auc.type
#> NULL
#> 
#> $aumcivint.last$formalsmap$lambda.z
#> NULL
#> 
#> $aumcivint.last$formalsmap$clast
#> NULL
#> 
#> 
#> $aumcivint.last$depends
#> [1] "aumcint.last" "c0"          
#> 
#> $aumcivint.last$datatype
#> [1] "interval"
#> 
#> $aumcivint.last$pptestcd_cdisc
#> [1] "aumcivint.last"
#> 
#> $aumcivint.last$pptest_cdisc
#> [1] "AUMCint.last, IV back-extrap C0"
#> 
#> $aumcivint.last$formula
#> NULL
#> 
#> $aumcivint.last$formula_note
#> NULL
#> 
#> $aumcivint.last$tier
#> [1] "uncommon"
#> 
#> $aumcivint.last$selection
#> list()
#> 
#> 
#> $aumcivint.all
#> $aumcivint.all$FUN
#> [1] "pk.calc.aumciv"
#> 
#> $aumcivint.all$values
#> [1] FALSE  TRUE
#> 
#> $aumcivint.all$unit_type
#> [1] "aumc"
#> 
#> $aumcivint.all$pretty_name
#> [1] "AUMCint,all (IV dosing)"
#> 
#> $aumcivint.all$desc
#> [1] "AUMCint.all, IV back-extrap C0"
#> 
#> $aumcivint.all$sparse
#> [1] FALSE
#> 
#> $aumcivint.all$formalsmap
#> $aumcivint.all$formalsmap$aumc
#> [1] "aumcint.all"
#> 
#> $aumcivint.all$formalsmap$auc.type
#> NULL
#> 
#> $aumcivint.all$formalsmap$lambda.z
#> NULL
#> 
#> $aumcivint.all$formalsmap$clast
#> NULL
#> 
#> 
#> $aumcivint.all$depends
#> [1] "aumcint.all" "c0"         
#> 
#> $aumcivint.all$datatype
#> [1] "interval"
#> 
#> $aumcivint.all$pptestcd_cdisc
#> [1] "aumcivint.all"
#> 
#> $aumcivint.all$pptest_cdisc
#> [1] "AUMCint.all, IV back-extrap C0"
#> 
#> $aumcivint.all$formula
#> NULL
#> 
#> $aumcivint.all$formula_note
#> NULL
#> 
#> $aumcivint.all$tier
#> [1] "uncommon"
#> 
#> $aumcivint.all$selection
#> list()
#> 
#> 
#> $half.life
#> $half.life$FUN
#> [1] "pk.calc.half.life"
#> 
#> $half.life$values
#> [1] FALSE  TRUE
#> 
#> $half.life$unit_type
#> [1] "time"
#> 
#> $half.life$pretty_name
#> [1] "Half-life"
#> 
#> $half.life$desc
#> [1] "The (terminal) half-life"
#> 
#> $half.life$sparse
#> [1] FALSE
#> 
#> $half.life$formalsmap
#> list()
#> 
#> $half.life$depends
#> [1] "tmax"  "tlast"
#> 
#> $half.life$datatype
#> [1] "interval"
#> 
#> $half.life$pptestcd_cdisc
#> [1] "LAMZHL"
#> 
#> $half.life$pptest_cdisc
#> [1] "Half-Life Lambda z"
#> 
#> $half.life$formula
#> [1] "$t_{1/2} = \\frac{\\ln(2)}{\\lambda_z}$"
#> 
#> $half.life$formula_note
#> NULL
#> 
#> $half.life$tier
#> [1] "common"
#> 
#> $half.life$selection
#> list()
#> 
#> $half.life$requires_dose_amt
#> [1] FALSE
#> 
#> $half.life$requires_dose_time
#> [1] FALSE
#> 
#> $half.life$requires_dose_dur
#> [1] FALSE
#> 
#> $half.life$requires_volume
#> [1] FALSE
#> 
#> $half.life$requires_conc_dur
#> [1] FALSE
#> 
#> 
#> $r.squared
#> $r.squared$FUN
#> [1] NA
#> 
#> $r.squared$values
#> [1] FALSE  TRUE
#> 
#> $r.squared$unit_type
#> [1] "unitless"
#> 
#> $r.squared$pretty_name
#> [1] "$r^2$"
#> 
#> $r.squared$desc
#> [1] "R-squared of half-life fit"
#> 
#> $r.squared$sparse
#> [1] FALSE
#> 
#> $r.squared$formalsmap
#> list()
#> 
#> $r.squared$depends
#> [1] "half.life"
#> 
#> $r.squared$datatype
#> [1] "interval"
#> 
#> $r.squared$pptestcd_cdisc
#> [1] "R2"
#> 
#> $r.squared$pptest_cdisc
#> [1] "R Squared"
#> 
#> $r.squared$formula
#> [1] "$r^2 = 1 - \\frac{\\sum_{i \\in \\lambda_z} (y_i - \\hat{y}_i)^2}{\\sum_{i \\in \\lambda_z} (y_i - \\bar{y})^2}$"
#> 
#> $r.squared$formula_note
#> [1] "Regression of $y = \\log C$ on time over the terminal points"
#> 
#> $r.squared$tier
#> [1] "uncommon"
#> 
#> $r.squared$selection
#> list()
#> 
#> 
#> $adj.r.squared
#> $adj.r.squared$FUN
#> [1] NA
#> 
#> $adj.r.squared$values
#> [1] FALSE  TRUE
#> 
#> $adj.r.squared$unit_type
#> [1] "unitless"
#> 
#> $adj.r.squared$pretty_name
#> [1] "$r^2_{adj}$"
#> 
#> $adj.r.squared$desc
#> [1] "Adjusted R-sq of half-life fit"
#> 
#> $adj.r.squared$sparse
#> [1] FALSE
#> 
#> $adj.r.squared$formalsmap
#> list()
#> 
#> $adj.r.squared$depends
#> [1] "half.life"
#> 
#> $adj.r.squared$datatype
#> [1] "interval"
#> 
#> $adj.r.squared$pptestcd_cdisc
#> [1] "R2ADJ"
#> 
#> $adj.r.squared$pptest_cdisc
#> [1] "R Squared Adjusted"
#> 
#> $adj.r.squared$formula
#> [1] "$r^2_{adj} = 1 - (1 - r^2) \\frac{n-1}{n-2}$"
#> 
#> $adj.r.squared$formula_note
#> NULL
#> 
#> $adj.r.squared$tier
#> [1] "uncommon"
#> 
#> $adj.r.squared$selection
#> list()
#> 
#> 
#> $lambda.z.corrxy
#> $lambda.z.corrxy$FUN
#> [1] NA
#> 
#> $lambda.z.corrxy$values
#> [1] FALSE  TRUE
#> 
#> $lambda.z.corrxy$unit_type
#> [1] "unitless"
#> 
#> $lambda.z.corrxy$pretty_name
#> [1] "Correlation (time, log-conc)"
#> 
#> $lambda.z.corrxy$desc
#> [1] "Corr(time,log-conc) for lambda.z"
#> 
#> $lambda.z.corrxy$sparse
#> [1] FALSE
#> 
#> $lambda.z.corrxy$formalsmap
#> list()
#> 
#> $lambda.z.corrxy$depends
#> [1] "half.life"
#> 
#> $lambda.z.corrxy$datatype
#> [1] "interval"
#> 
#> $lambda.z.corrxy$pptestcd_cdisc
#> [1] "CORRXY"
#> 
#> $lambda.z.corrxy$pptest_cdisc
#> [1] "Correlation Between TimeX and Log ConcY"
#> 
#> $lambda.z.corrxy$formula
#> [1] "$r_{t,\\log C} = \\text{cor}(t_{\\lambda_z}, \\log C_{\\lambda_z})$"
#> 
#> $lambda.z.corrxy$formula_note
#> NULL
#> 
#> $lambda.z.corrxy$tier
#> [1] "uncommon"
#> 
#> $lambda.z.corrxy$selection
#> list()
#> 
#> 
#> $lambda.z
#> $lambda.z$FUN
#> [1] NA
#> 
#> $lambda.z$values
#> [1] FALSE  TRUE
#> 
#> $lambda.z$unit_type
#> [1] "inverse_time"
#> 
#> $lambda.z$pretty_name
#> [1] "$\\lambda_z$"
#> 
#> $lambda.z$desc
#> [1] "Terminal elim rate (lambda.z)"
#> 
#> $lambda.z$sparse
#> [1] FALSE
#> 
#> $lambda.z$formalsmap
#> list()
#> 
#> $lambda.z$depends
#> [1] "half.life"
#> 
#> $lambda.z$datatype
#> [1] "interval"
#> 
#> $lambda.z$pptestcd_cdisc
#> [1] "LAMZ"
#> 
#> $lambda.z$pptest_cdisc
#> [1] "Lambda z"
#> 
#> $lambda.z$formula
#> [1] "$\\lambda_z = -\\text{slope of } \\log(C) \\text{ vs } t$"
#> 
#> $lambda.z$formula_note
#> NULL
#> 
#> $lambda.z$tier
#> [1] "uncommon"
#> 
#> $lambda.z$selection
#> list()
#> 
#> 
#> $lambda.z.time.first
#> $lambda.z.time.first$FUN
#> [1] NA
#> 
#> $lambda.z.time.first$values
#> [1] FALSE  TRUE
#> 
#> $lambda.z.time.first$unit_type
#> [1] "time"
#> 
#> $lambda.z.time.first$pretty_name
#> [1] "First time for $\\lambda_z$"
#> 
#> $lambda.z.time.first$desc
#> [1] "First time point for lambda.z"
#> 
#> $lambda.z.time.first$sparse
#> [1] FALSE
#> 
#> $lambda.z.time.first$formalsmap
#> list()
#> 
#> $lambda.z.time.first$depends
#> [1] "half.life"
#> 
#> $lambda.z.time.first$datatype
#> [1] "interval"
#> 
#> $lambda.z.time.first$pptestcd_cdisc
#> [1] "LAMZLL"
#> 
#> $lambda.z.time.first$pptest_cdisc
#> [1] "Lambda z Lower Limit"
#> 
#> $lambda.z.time.first$formula
#> [1] "$\\lambda_z t_{\\text{first}} = \\min\\left(t_{\\lambda_z}\\right)$"
#> 
#> $lambda.z.time.first$formula_note
#> NULL
#> 
#> $lambda.z.time.first$tier
#> [1] "uncommon"
#> 
#> $lambda.z.time.first$selection
#> list()
#> 
#> 
#> $lambda.z.time.last
#> $lambda.z.time.last$FUN
#> [1] NA
#> 
#> $lambda.z.time.last$values
#> [1] FALSE  TRUE
#> 
#> $lambda.z.time.last$unit_type
#> [1] "time"
#> 
#> $lambda.z.time.last$pretty_name
#> [1] "Last time for $\\lambda_z$"
#> 
#> $lambda.z.time.last$desc
#> [1] "Last time point for lambda.z"
#> 
#> $lambda.z.time.last$sparse
#> [1] FALSE
#> 
#> $lambda.z.time.last$formalsmap
#> list()
#> 
#> $lambda.z.time.last$depends
#> [1] "half.life"
#> 
#> $lambda.z.time.last$datatype
#> [1] "interval"
#> 
#> $lambda.z.time.last$pptestcd_cdisc
#> [1] "LAMZUL"
#> 
#> $lambda.z.time.last$pptest_cdisc
#> [1] "Lambda z Upper Limit"
#> 
#> $lambda.z.time.last$formula
#> [1] "$\\lambda_z t_{\\text{last}} = \\max\\left(t_{\\lambda_z}\\right)$"
#> 
#> $lambda.z.time.last$formula_note
#> NULL
#> 
#> $lambda.z.time.last$tier
#> [1] "uncommon"
#> 
#> $lambda.z.time.last$selection
#> list()
#> 
#> 
#> $lambda.z.n.points
#> $lambda.z.n.points$FUN
#> [1] NA
#> 
#> $lambda.z.n.points$values
#> [1] FALSE  TRUE
#> 
#> $lambda.z.n.points$unit_type
#> [1] "count"
#> 
#> $lambda.z.n.points$pretty_name
#> [1] "Number of points used for lambda_z"
#> 
#> $lambda.z.n.points$desc
#> [1] "Number of points used, lambda.z"
#> 
#> $lambda.z.n.points$sparse
#> [1] FALSE
#> 
#> $lambda.z.n.points$formalsmap
#> list()
#> 
#> $lambda.z.n.points$depends
#> [1] "half.life"
#> 
#> $lambda.z.n.points$datatype
#> [1] "interval"
#> 
#> $lambda.z.n.points$pptestcd_cdisc
#> [1] "LAMZNPT"
#> 
#> $lambda.z.n.points$pptest_cdisc
#> [1] "Number of Points for Lambda z"
#> 
#> $lambda.z.n.points$formula
#> [1] "$n_{\\lambda_z} = \\left| t_{\\lambda_z} \\right|$"
#> 
#> $lambda.z.n.points$formula_note
#> NULL
#> 
#> $lambda.z.n.points$tier
#> [1] "uncommon"
#> 
#> $lambda.z.n.points$selection
#> list()
#> 
#> 
#> $clast.pred
#> $clast.pred$FUN
#> [1] NA
#> 
#> $clast.pred$values
#> [1] FALSE  TRUE
#> 
#> $clast.pred$unit_type
#> [1] "conc"
#> 
#> $clast.pred$pretty_name
#> [1] "Clast,pred"
#> 
#> $clast.pred$desc
#> [1] "Predicted Clast from half-life"
#> 
#> $clast.pred$sparse
#> [1] FALSE
#> 
#> $clast.pred$formalsmap
#> list()
#> 
#> $clast.pred$depends
#> [1] "half.life"
#> 
#> $clast.pred$datatype
#> [1] "interval"
#> 
#> $clast.pred$pptestcd_cdisc
#> [1] "CLSTP"
#> 
#> $clast.pred$pptest_cdisc
#> [1] "Clast pred"
#> 
#> $clast.pred$formula
#> [1] "$C_{\\text{last,pred}} = e^{\\text{intercept} - \\lambda_z \\cdot t_{\\text{last}}}$"
#> 
#> $clast.pred$formula_note
#> NULL
#> 
#> $clast.pred$tier
#> [1] "uncommon"
#> 
#> $clast.pred$selection
#> $clast.pred$selection$concept
#> [1] "last_conc"
#> 
#> 
#> 
#> $span.ratio
#> $span.ratio$FUN
#> [1] NA
#> 
#> $span.ratio$values
#> [1] FALSE  TRUE
#> 
#> $span.ratio$unit_type
#> [1] "fraction"
#> 
#> $span.ratio$pretty_name
#> [1] "Span ratio"
#> 
#> $span.ratio$desc
#> [1] "Lambda z time span to half-life ratio"
#> 
#> $span.ratio$sparse
#> [1] FALSE
#> 
#> $span.ratio$formalsmap
#> list()
#> 
#> $span.ratio$depends
#> [1] "half.life"
#> 
#> $span.ratio$datatype
#> [1] "interval"
#> 
#> $span.ratio$pptestcd_cdisc
#> [1] "LAMZSPN"
#> 
#> $span.ratio$pptest_cdisc
#> [1] "Lambda z Span"
#> 
#> $span.ratio$formula
#> [1] "$\\text{span ratio} = \\frac{t_{\\lambda_z,\\text{last}} - t_{\\lambda_z,\\text{first}}}{t_{1/2}}$"
#> 
#> $span.ratio$formula_note
#> NULL
#> 
#> $span.ratio$tier
#> [1] "uncommon"
#> 
#> $span.ratio$selection
#> list()
#> 
#> 
#> $tobit_residual
#> $tobit_residual$FUN
#> [1] NA
#> 
#> $tobit_residual$values
#> [1] FALSE  TRUE
#> 
#> $tobit_residual$unit_type
#> [1] "unitless"
#> 
#> $tobit_residual$pretty_name
#> [1] "Tobit residual SD"
#> 
#> $tobit_residual$desc
#> [1] "Tobit fit residual SD, log-conc"
#> 
#> $tobit_residual$sparse
#> [1] FALSE
#> 
#> $tobit_residual$formalsmap
#> list()
#> 
#> $tobit_residual$depends
#> [1] "half.life"
#> 
#> $tobit_residual$datatype
#> [1] "interval"
#> 
#> $tobit_residual$pptestcd_cdisc
#> [1] "tobit_residual"
#> 
#> $tobit_residual$pptest_cdisc
#> [1] "Tobit fit residual SD, log-conc"
#> 
#> $tobit_residual$formula
#> NULL
#> 
#> $tobit_residual$formula_note
#> NULL
#> 
#> $tobit_residual$tier
#> [1] "uncommon"
#> 
#> $tobit_residual$selection
#> list()
#> 
#> 
#> $adj_tobit_residual
#> $adj_tobit_residual$FUN
#> [1] NA
#> 
#> $adj_tobit_residual$values
#> [1] FALSE  TRUE
#> 
#> $adj_tobit_residual$unit_type
#> [1] "unitless"
#> 
#> $adj_tobit_residual$pretty_name
#> [1] "Adjusted Tobit residual SD"
#> 
#> $adj_tobit_residual$desc
#> [1] "Adjusted Tobit residual SD"
#> 
#> $adj_tobit_residual$sparse
#> [1] FALSE
#> 
#> $adj_tobit_residual$formalsmap
#> list()
#> 
#> $adj_tobit_residual$depends
#> [1] "half.life"
#> 
#> $adj_tobit_residual$datatype
#> [1] "interval"
#> 
#> $adj_tobit_residual$pptestcd_cdisc
#> [1] "adj_tobit_residual"
#> 
#> $adj_tobit_residual$pptest_cdisc
#> [1] "Adjusted Tobit residual SD"
#> 
#> $adj_tobit_residual$formula
#> NULL
#> 
#> $adj_tobit_residual$formula_note
#> NULL
#> 
#> $adj_tobit_residual$tier
#> [1] "uncommon"
#> 
#> $adj_tobit_residual$selection
#> list()
#> 
#> 
#> $lambda.z.n.points_blq
#> $lambda.z.n.points_blq$FUN
#> [1] NA
#> 
#> $lambda.z.n.points_blq$values
#> [1] FALSE  TRUE
#> 
#> $lambda.z.n.points_blq$unit_type
#> [1] "count"
#> 
#> $lambda.z.n.points_blq$pretty_name
#> [1] "Number of BLQ points for lambda_z (Tobit)"
#> 
#> $lambda.z.n.points_blq$desc
#> [1] "BLQ points in Tobit lambda.z"
#> 
#> $lambda.z.n.points_blq$sparse
#> [1] FALSE
#> 
#> $lambda.z.n.points_blq$formalsmap
#> list()
#> 
#> $lambda.z.n.points_blq$depends
#> [1] "half.life"
#> 
#> $lambda.z.n.points_blq$datatype
#> [1] "interval"
#> 
#> $lambda.z.n.points_blq$pptestcd_cdisc
#> [1] "lambda.z.n.points_blq"
#> 
#> $lambda.z.n.points_blq$pptest_cdisc
#> [1] "BLQ points in Tobit lambda.z"
#> 
#> $lambda.z.n.points_blq$formula
#> NULL
#> 
#> $lambda.z.n.points_blq$formula_note
#> NULL
#> 
#> $lambda.z.n.points_blq$tier
#> [1] "uncommon"
#> 
#> $lambda.z.n.points_blq$selection
#> list()
#> 
#> 
#> $thalf.eff.last
#> $thalf.eff.last$FUN
#> [1] "pk.calc.thalf.eff"
#> 
#> $thalf.eff.last$values
#> [1] FALSE  TRUE
#> 
#> $thalf.eff.last$unit_type
#> [1] "time"
#> 
#> $thalf.eff.last$pretty_name
#> [1] "Effective half-life (based on MRT,last)"
#> 
#> $thalf.eff.last$desc
#> [1] "Effective half-life, MRTlast"
#> 
#> $thalf.eff.last$sparse
#> [1] FALSE
#> 
#> $thalf.eff.last$formalsmap
#> $thalf.eff.last$formalsmap$mrt
#> [1] "mrt.last"
#> 
#> 
#> $thalf.eff.last$depends
#> [1] "mrt.last"
#> 
#> $thalf.eff.last$datatype
#> [1] "interval"
#> 
#> $thalf.eff.last$pptestcd_cdisc
#> [1] "EFFHL"
#> 
#> $thalf.eff.last$pptest_cdisc
#> [1] "Effective Half-Life (based on AUClast)"
#> 
#> $thalf.eff.last$formula
#> [1] "$t_{1/2,\\text{eff,last}} = \\ln(2) \\cdot MRT_{\\text{last}}$"
#> 
#> $thalf.eff.last$formula_note
#> NULL
#> 
#> $thalf.eff.last$tier
#> [1] "uncommon"
#> 
#> $thalf.eff.last$selection
#> list()
#> 
#> 
#> $thalf.eff.iv.last
#> $thalf.eff.iv.last$FUN
#> [1] "pk.calc.thalf.eff"
#> 
#> $thalf.eff.iv.last$values
#> [1] FALSE  TRUE
#> 
#> $thalf.eff.iv.last$unit_type
#> [1] "time"
#> 
#> $thalf.eff.iv.last$pretty_name
#> [1] "Effective half-life (for IV dosing, based on MRTlast)"
#> 
#> $thalf.eff.iv.last$desc
#> [1] "Effective half-life, IV MRTlast"
#> 
#> $thalf.eff.iv.last$sparse
#> [1] FALSE
#> 
#> $thalf.eff.iv.last$formalsmap
#> $thalf.eff.iv.last$formalsmap$mrt
#> [1] "mrt.iv.last"
#> 
#> 
#> $thalf.eff.iv.last$depends
#> [1] "mrt.iv.last"
#> 
#> $thalf.eff.iv.last$datatype
#> [1] "interval"
#> 
#> $thalf.eff.iv.last$pptestcd_cdisc
#> [1] "EFFIVLHL"
#> 
#> $thalf.eff.iv.last$pptest_cdisc
#> [1] "Effective Half-Life (for IV dosing, based on AUClast)"
#> 
#> $thalf.eff.iv.last$formula
#> [1] "$t_{1/2,\\text{eff,iv,last}} = \\ln(2) \\cdot MRT_{\\text{iv,last}}$"
#> 
#> $thalf.eff.iv.last$formula_note
#> NULL
#> 
#> $thalf.eff.iv.last$tier
#> [1] "uncommon"
#> 
#> $thalf.eff.iv.last$selection
#> list()
#> 
#> 
#> $kel.last
#> $kel.last$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.last$values
#> [1] FALSE  TRUE
#> 
#> $kel.last$unit_type
#> [1] "inverse_time"
#> 
#> $kel.last$pretty_name
#> [1] "Kel (based on AUClast)"
#> 
#> $kel.last$desc
#> [1] "Elim rate, MRT via AUClast"
#> 
#> $kel.last$sparse
#> [1] FALSE
#> 
#> $kel.last$formalsmap
#> $kel.last$formalsmap$mrt
#> [1] "mrt.last"
#> 
#> 
#> $kel.last$depends
#> [1] "mrt.last"
#> 
#> $kel.last$datatype
#> [1] "interval"
#> 
#> $kel.last$pptestcd_cdisc
#> [1] "KELLST"
#> 
#> $kel.last$pptest_cdisc
#> [1] "Kel (based on AUClast)"
#> 
#> $kel.last$formula
#> [1] "$k_{el,\\text{last}} = \\frac{1}{MRT_{\\text{last}}}$"
#> 
#> $kel.last$formula_note
#> NULL
#> 
#> $kel.last$tier
#> [1] "uncommon"
#> 
#> $kel.last$selection
#> list()
#> 
#> 
#> $kel.iv.last
#> $kel.iv.last$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.iv.last$values
#> [1] FALSE  TRUE
#> 
#> $kel.iv.last$unit_type
#> [1] "inverse_time"
#> 
#> $kel.iv.last$pretty_name
#> [1] "Kel (for IV dosing, based on AUClast)"
#> 
#> $kel.iv.last$desc
#> [1] "Elim rate, IV MRTlast"
#> 
#> $kel.iv.last$sparse
#> [1] FALSE
#> 
#> $kel.iv.last$formalsmap
#> $kel.iv.last$formalsmap$mrt
#> [1] "mrt.iv.last"
#> 
#> 
#> $kel.iv.last$depends
#> [1] "mrt.iv.last"
#> 
#> $kel.iv.last$datatype
#> [1] "interval"
#> 
#> $kel.iv.last$pptestcd_cdisc
#> [1] "KELIVLT"
#> 
#> $kel.iv.last$pptest_cdisc
#> [1] "Kel (for IV dosing, based on AUClast)"
#> 
#> $kel.iv.last$formula
#> [1] "$k_{el,\\text{iv,last}} = \\frac{1}{MRT_{\\text{iv,last}}}$"
#> 
#> $kel.iv.last$formula_note
#> NULL
#> 
#> $kel.iv.last$tier
#> [1] "uncommon"
#> 
#> $kel.iv.last$selection
#> list()
#> 
#> 
#> $kel.all
#> $kel.all$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.all$values
#> [1] FALSE  TRUE
#> 
#> $kel.all$unit_type
#> [1] "inverse_time"
#> 
#> $kel.all$pretty_name
#> [1] "Kel (based on AUCall)"
#> 
#> $kel.all$desc
#> [1] "Elim rate, MRTall"
#> 
#> $kel.all$sparse
#> [1] FALSE
#> 
#> $kel.all$formalsmap
#> $kel.all$formalsmap$mrt
#> [1] "mrt.all"
#> 
#> 
#> $kel.all$depends
#> [1] "mrt.all"
#> 
#> $kel.all$datatype
#> [1] "interval"
#> 
#> $kel.all$pptestcd_cdisc
#> [1] "kel.all"
#> 
#> $kel.all$pptest_cdisc
#> [1] "Elim rate, MRTall"
#> 
#> $kel.all$formula
#> [1] "$k_{el,\\text{all}} = \\frac{1}{MRT_{\\text{all}}}$"
#> 
#> $kel.all$formula_note
#> NULL
#> 
#> $kel.all$tier
#> [1] "uncommon"
#> 
#> $kel.all$selection
#> list()
#> 
#> 
#> $kel.int.all
#> $kel.int.all$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.int.all$values
#> [1] FALSE  TRUE
#> 
#> $kel.int.all$unit_type
#> [1] "inverse_time"
#> 
#> $kel.int.all$pretty_name
#> [1] "Kel (based on AUCint.all)"
#> 
#> $kel.int.all$desc
#> [1] "Elim rate, MRTint.all"
#> 
#> $kel.int.all$sparse
#> [1] FALSE
#> 
#> $kel.int.all$formalsmap
#> $kel.int.all$formalsmap$mrt
#> [1] "mrt.int.all"
#> 
#> 
#> $kel.int.all$depends
#> [1] "mrt.int.all"
#> 
#> $kel.int.all$datatype
#> [1] "interval"
#> 
#> $kel.int.all$pptestcd_cdisc
#> [1] "kel.int.all"
#> 
#> $kel.int.all$pptest_cdisc
#> [1] "Elim rate, MRTint.all"
#> 
#> $kel.int.all$formula
#> [1] "$k_{el,\\text{int,all}} = \\frac{1}{MRT_{\\text{int,all}}}$"
#> 
#> $kel.int.all$formula_note
#> NULL
#> 
#> $kel.int.all$tier
#> [1] "uncommon"
#> 
#> $kel.int.all$selection
#> list()
#> 
#> 
#> $kel.int.last
#> $kel.int.last$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.int.last$values
#> [1] FALSE  TRUE
#> 
#> $kel.int.last$unit_type
#> [1] "inverse_time"
#> 
#> $kel.int.last$pretty_name
#> [1] "Kel (based on AUCint.last)"
#> 
#> $kel.int.last$desc
#> [1] "Elim rate, MRTint.last"
#> 
#> $kel.int.last$sparse
#> [1] FALSE
#> 
#> $kel.int.last$formalsmap
#> $kel.int.last$formalsmap$mrt
#> [1] "mrt.int.last"
#> 
#> 
#> $kel.int.last$depends
#> [1] "mrt.int.last"
#> 
#> $kel.int.last$datatype
#> [1] "interval"
#> 
#> $kel.int.last$pptestcd_cdisc
#> [1] "kel.int.last"
#> 
#> $kel.int.last$pptest_cdisc
#> [1] "Elim rate, MRTint.last"
#> 
#> $kel.int.last$formula
#> [1] "$k_{el,\\text{int,last}} = \\frac{1}{MRT_{\\text{int,last}}}$"
#> 
#> $kel.int.last$formula_note
#> NULL
#> 
#> $kel.int.last$tier
#> [1] "uncommon"
#> 
#> $kel.int.last$selection
#> list()
#> 
#> 
#> $cl.iv.all
#> $cl.iv.all$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.iv.all$values
#> [1] FALSE  TRUE
#> 
#> $cl.iv.all$unit_type
#> [1] "clearance"
#> 
#> $cl.iv.all$pretty_name
#> [1] "CL (for IV dosing,  based on AUCall)"
#> 
#> $cl.iv.all$desc
#> [1] "IV clearance, AUCall"
#> 
#> $cl.iv.all$sparse
#> [1] FALSE
#> 
#> $cl.iv.all$formalsmap
#> $cl.iv.all$formalsmap$auc
#> [1] "aucivall"
#> 
#> 
#> $cl.iv.all$depends
#> [1] "aucivall"
#> 
#> $cl.iv.all$datatype
#> [1] "interval"
#> 
#> $cl.iv.all$pptestcd_cdisc
#> [1] "cl.iv.all"
#> 
#> $cl.iv.all$pptest_cdisc
#> [1] "IV clearance, AUCall"
#> 
#> $cl.iv.all$formula
#> [1] "$CL_{\\text{iv,all}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,all}}}$"
#> 
#> $cl.iv.all$formula_note
#> NULL
#> 
#> $cl.iv.all$tier
#> [1] "uncommon"
#> 
#> $cl.iv.all$selection
#> list()
#> 
#> 
#> $cl.iv.last
#> $cl.iv.last$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.iv.last$values
#> [1] FALSE  TRUE
#> 
#> $cl.iv.last$unit_type
#> [1] "clearance"
#> 
#> $cl.iv.last$pretty_name
#> [1] "CL (for IV dosing,  based on AUClast)"
#> 
#> $cl.iv.last$desc
#> [1] "IV clearance, AUClast"
#> 
#> $cl.iv.last$sparse
#> [1] FALSE
#> 
#> $cl.iv.last$formalsmap
#> $cl.iv.last$formalsmap$auc
#> [1] "aucivlast"
#> 
#> 
#> $cl.iv.last$depends
#> [1] "aucivlast"
#> 
#> $cl.iv.last$datatype
#> [1] "interval"
#> 
#> $cl.iv.last$pptestcd_cdisc
#> [1] "cl.iv.last"
#> 
#> $cl.iv.last$pptest_cdisc
#> [1] "IV clearance, AUClast"
#> 
#> $cl.iv.last$formula
#> [1] "$CL_{\\text{iv,last}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,last}}}$"
#> 
#> $cl.iv.last$formula_note
#> NULL
#> 
#> $cl.iv.last$tier
#> [1] "uncommon"
#> 
#> $cl.iv.last$selection
#> list()
#> 
#> 
#> $cl.ivint.all
#> $cl.ivint.all$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.ivint.all$values
#> [1] FALSE  TRUE
#> 
#> $cl.ivint.all$unit_type
#> [1] "clearance"
#> 
#> $cl.ivint.all$pretty_name
#> [1] "CL (IV dose interval, based on AUCint.all)"
#> 
#> $cl.ivint.all$desc
#> [1] "IV clearance, AUCint.all"
#> 
#> $cl.ivint.all$sparse
#> [1] FALSE
#> 
#> $cl.ivint.all$formalsmap
#> $cl.ivint.all$formalsmap$auc
#> [1] "aucivint.all"
#> 
#> 
#> $cl.ivint.all$depends
#> [1] "aucivint.all"
#> 
#> $cl.ivint.all$datatype
#> [1] "interval"
#> 
#> $cl.ivint.all$pptestcd_cdisc
#> [1] "cl.ivint.all"
#> 
#> $cl.ivint.all$pptest_cdisc
#> [1] "IV clearance, AUCint.all"
#> 
#> $cl.ivint.all$formula
#> [1] "$CL_{\\text{iv,int,all}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,int,all}}}$"
#> 
#> $cl.ivint.all$formula_note
#> NULL
#> 
#> $cl.ivint.all$tier
#> [1] "uncommon"
#> 
#> $cl.ivint.all$selection
#> list()
#> 
#> 
#> $cl.ivint.last
#> $cl.ivint.last$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.ivint.last$values
#> [1] FALSE  TRUE
#> 
#> $cl.ivint.last$unit_type
#> [1] "clearance"
#> 
#> $cl.ivint.last$pretty_name
#> [1] "CL (IV dose interval, based on AUCint.last)"
#> 
#> $cl.ivint.last$desc
#> [1] "IV clearance, AUCint.last"
#> 
#> $cl.ivint.last$sparse
#> [1] FALSE
#> 
#> $cl.ivint.last$formalsmap
#> $cl.ivint.last$formalsmap$auc
#> [1] "aucivint.last"
#> 
#> 
#> $cl.ivint.last$depends
#> [1] "aucivint.last"
#> 
#> $cl.ivint.last$datatype
#> [1] "interval"
#> 
#> $cl.ivint.last$pptestcd_cdisc
#> [1] "cl.ivint.last"
#> 
#> $cl.ivint.last$pptest_cdisc
#> [1] "IV clearance, AUCint.last"
#> 
#> $cl.ivint.last$formula
#> [1] "$CL_{\\text{iv,int,last}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,int,last}}}$"
#> 
#> $cl.ivint.last$formula_note
#> NULL
#> 
#> $cl.ivint.last$tier
#> [1] "uncommon"
#> 
#> $cl.ivint.last$selection
#> list()
#> 
#> 
#> $cl.sparse.last
#> $cl.sparse.last$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.sparse.last$values
#> [1] FALSE  TRUE
#> 
#> $cl.sparse.last$unit_type
#> [1] "clearance"
#> 
#> $cl.sparse.last$pretty_name
#> [1] "CL (for sparse data, based on AUClast)"
#> 
#> $cl.sparse.last$desc
#> [1] "Clearance, sparse AUClast"
#> 
#> $cl.sparse.last$sparse
#> [1] TRUE
#> 
#> $cl.sparse.last$formalsmap
#> $cl.sparse.last$formalsmap$auc
#> [1] "sparse_auclast"
#> 
#> 
#> $cl.sparse.last$depends
#> [1] "sparse_auclast"
#> 
#> $cl.sparse.last$datatype
#> [1] "interval"
#> 
#> $cl.sparse.last$pptestcd_cdisc
#> [1] "cl.sparse.last"
#> 
#> $cl.sparse.last$pptest_cdisc
#> [1] "Clearance, sparse AUClast"
#> 
#> $cl.sparse.last$formula
#> [1] "$CL_{\\text{sparse,last}} = \\frac{Dose}{AUC_{\\text{sparse,last}}}$"
#> 
#> $cl.sparse.last$formula_note
#> NULL
#> 
#> $cl.sparse.last$tier
#> [1] "uncommon"
#> 
#> $cl.sparse.last$selection
#> list()
#> 
#> 
#> $mrt.sparse.last
#> $mrt.sparse.last$FUN
#> [1] "pk.calc.mrt"
#> 
#> $mrt.sparse.last$values
#> [1] FALSE  TRUE
#> 
#> $mrt.sparse.last$unit_type
#> [1] "time"
#> 
#> $mrt.sparse.last$pretty_name
#> [1] "MRT (for sparse data, based on AUClast)"
#> 
#> $mrt.sparse.last$desc
#> [1] "MRT, sparse AUClast/AUMClast"
#> 
#> $mrt.sparse.last$sparse
#> [1] TRUE
#> 
#> $mrt.sparse.last$formalsmap
#> $mrt.sparse.last$formalsmap$auc
#> [1] "sparse_auclast"
#> 
#> $mrt.sparse.last$formalsmap$aumc
#> [1] "sparse_aumclast"
#> 
#> 
#> $mrt.sparse.last$depends
#> [1] "sparse_auclast"  "sparse_aumclast"
#> 
#> $mrt.sparse.last$datatype
#> [1] "interval"
#> 
#> $mrt.sparse.last$pptestcd_cdisc
#> [1] "mrt.sparse.last"
#> 
#> $mrt.sparse.last$pptest_cdisc
#> [1] "MRT, sparse AUClast/AUMClast"
#> 
#> $mrt.sparse.last$formula
#> NULL
#> 
#> $mrt.sparse.last$formula_note
#> NULL
#> 
#> $mrt.sparse.last$tier
#> [1] "uncommon"
#> 
#> $mrt.sparse.last$selection
#> list()
#> 
#> 
#> $mrt.iv.all
#> $mrt.iv.all$FUN
#> [1] "pk.calc.mrt.iv"
#> 
#> $mrt.iv.all$values
#> [1] FALSE  TRUE
#> 
#> $mrt.iv.all$unit_type
#> [1] "time"
#> 
#> $mrt.iv.all$pretty_name
#> [1] "MRT (for IV dosing, based on AUCall)"
#> 
#> $mrt.iv.all$desc
#> [1] "IV MRT, AUCall/AUMCall"
#> 
#> $mrt.iv.all$sparse
#> [1] FALSE
#> 
#> $mrt.iv.all$formalsmap
#> $mrt.iv.all$formalsmap$auc
#> [1] "aucivall"
#> 
#> $mrt.iv.all$formalsmap$aumc
#> [1] "aumcivall"
#> 
#> 
#> $mrt.iv.all$depends
#> [1] "aucivall"  "aumcivall"
#> 
#> $mrt.iv.all$datatype
#> [1] "interval"
#> 
#> $mrt.iv.all$pptestcd_cdisc
#> [1] "mrt.iv.all"
#> 
#> $mrt.iv.all$pptest_cdisc
#> [1] "IV MRT, AUCall/AUMCall"
#> 
#> $mrt.iv.all$formula
#> NULL
#> 
#> $mrt.iv.all$formula_note
#> NULL
#> 
#> $mrt.iv.all$tier
#> [1] "uncommon"
#> 
#> $mrt.iv.all$selection
#> list()
#> 
#> 
#> $mrt.ivint.all
#> $mrt.ivint.all$FUN
#> [1] "pk.calc.mrt.iv"
#> 
#> $mrt.ivint.all$values
#> [1] FALSE  TRUE
#> 
#> $mrt.ivint.all$unit_type
#> [1] "time"
#> 
#> $mrt.ivint.all$pretty_name
#> [1] "MRT (IV dose interval, based on AUCint.all)"
#> 
#> $mrt.ivint.all$desc
#> [1] "IV MRT, interval AUC/AUMCall"
#> 
#> $mrt.ivint.all$sparse
#> [1] FALSE
#> 
#> $mrt.ivint.all$formalsmap
#> $mrt.ivint.all$formalsmap$auc
#> [1] "aucivint.all"
#> 
#> $mrt.ivint.all$formalsmap$aumc
#> [1] "aumcivint.all"
#> 
#> 
#> $mrt.ivint.all$depends
#> [1] "aucivint.all"  "aumcivint.all"
#> 
#> $mrt.ivint.all$datatype
#> [1] "interval"
#> 
#> $mrt.ivint.all$pptestcd_cdisc
#> [1] "mrt.ivint.all"
#> 
#> $mrt.ivint.all$pptest_cdisc
#> [1] "IV MRT, interval AUC/AUMCall"
#> 
#> $mrt.ivint.all$formula
#> NULL
#> 
#> $mrt.ivint.all$formula_note
#> NULL
#> 
#> $mrt.ivint.all$tier
#> [1] "uncommon"
#> 
#> $mrt.ivint.all$selection
#> list()
#> 
#> 
#> $mrt.ivint.last
#> $mrt.ivint.last$FUN
#> [1] "pk.calc.mrt.iv"
#> 
#> $mrt.ivint.last$values
#> [1] FALSE  TRUE
#> 
#> $mrt.ivint.last$unit_type
#> [1] "time"
#> 
#> $mrt.ivint.last$pretty_name
#> [1] "MRT (IV dose interval, based on AUCint.last)"
#> 
#> $mrt.ivint.last$desc
#> [1] "IV MRT, interval AUC/AUMClast"
#> 
#> $mrt.ivint.last$sparse
#> [1] FALSE
#> 
#> $mrt.ivint.last$formalsmap
#> $mrt.ivint.last$formalsmap$auc
#> [1] "aucivint.last"
#> 
#> $mrt.ivint.last$formalsmap$aumc
#> [1] "aumcivint.last"
#> 
#> 
#> $mrt.ivint.last$depends
#> [1] "aucivint.last"  "aumcivint.last"
#> 
#> $mrt.ivint.last$datatype
#> [1] "interval"
#> 
#> $mrt.ivint.last$pptestcd_cdisc
#> [1] "mrt.ivint.last"
#> 
#> $mrt.ivint.last$pptest_cdisc
#> [1] "IV MRT, interval AUC/AUMClast"
#> 
#> $mrt.ivint.last$formula
#> NULL
#> 
#> $mrt.ivint.last$formula_note
#> NULL
#> 
#> $mrt.ivint.last$tier
#> [1] "uncommon"
#> 
#> $mrt.ivint.last$selection
#> list()
#> 
#> 
#> $vz.all
#> $vz.all$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.all$values
#> [1] FALSE  TRUE
#> 
#> $vz.all$unit_type
#> [1] "volume"
#> 
#> $vz.all$pretty_name
#> [1] "Vz (based on AUCall)"
#> 
#> $vz.all$desc
#> [1] "Vz, AUCall-based CL"
#> 
#> $vz.all$sparse
#> [1] FALSE
#> 
#> $vz.all$formalsmap
#> $vz.all$formalsmap$cl
#> [1] "cl.all"
#> 
#> 
#> $vz.all$depends
#> [1] "cl.all"   "lambda.z"
#> 
#> $vz.all$datatype
#> [1] "interval"
#> 
#> $vz.all$pptestcd_cdisc
#> [1] "vz.all"
#> 
#> $vz.all$pptest_cdisc
#> [1] "Vz, AUCall-based CL"
#> 
#> $vz.all$formula
#> [1] "$V_{z,\\text{all}} = \\frac{CL_{\\text{all}}}{\\lambda_z}$"
#> 
#> $vz.all$formula_note
#> NULL
#> 
#> $vz.all$tier
#> [1] "uncommon"
#> 
#> $vz.all$selection
#> list()
#> 
#> 
#> $vz.int.all
#> $vz.int.all$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.int.all$values
#> [1] FALSE  TRUE
#> 
#> $vz.int.all$unit_type
#> [1] "volume"
#> 
#> $vz.int.all$pretty_name
#> [1] "Vz (based on AUCint.all)"
#> 
#> $vz.int.all$desc
#> [1] "Vz, interval AUCint.all"
#> 
#> $vz.int.all$sparse
#> [1] FALSE
#> 
#> $vz.int.all$formalsmap
#> $vz.int.all$formalsmap$cl
#> [1] "cl.int.all"
#> 
#> 
#> $vz.int.all$depends
#> [1] "cl.int.all" "lambda.z"  
#> 
#> $vz.int.all$datatype
#> [1] "interval"
#> 
#> $vz.int.all$pptestcd_cdisc
#> [1] "vz.int.all"
#> 
#> $vz.int.all$pptest_cdisc
#> [1] "Vz, interval AUCint.all"
#> 
#> $vz.int.all$formula
#> [1] "$V_{z,\\text{int,all}} = \\frac{CL_{\\text{int,all}}}{\\lambda_z}$"
#> 
#> $vz.int.all$formula_note
#> NULL
#> 
#> $vz.int.all$tier
#> [1] "uncommon"
#> 
#> $vz.int.all$selection
#> list()
#> 
#> 
#> $vz.int.last
#> $vz.int.last$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.int.last$values
#> [1] FALSE  TRUE
#> 
#> $vz.int.last$unit_type
#> [1] "volume"
#> 
#> $vz.int.last$pretty_name
#> [1] "Vz (based on AUCint.last)"
#> 
#> $vz.int.last$desc
#> [1] "Vz, interval AUCint.last"
#> 
#> $vz.int.last$sparse
#> [1] FALSE
#> 
#> $vz.int.last$formalsmap
#> $vz.int.last$formalsmap$cl
#> [1] "cl.int.last"
#> 
#> 
#> $vz.int.last$depends
#> [1] "cl.int.last" "lambda.z"   
#> 
#> $vz.int.last$datatype
#> [1] "interval"
#> 
#> $vz.int.last$pptestcd_cdisc
#> [1] "vz.int.last"
#> 
#> $vz.int.last$pptest_cdisc
#> [1] "Vz, interval AUCint.last"
#> 
#> $vz.int.last$formula
#> [1] "$V_{z,\\text{int,last}} = \\frac{CL_{\\text{int,last}}}{\\lambda_z}$"
#> 
#> $vz.int.last$formula_note
#> NULL
#> 
#> $vz.int.last$tier
#> [1] "uncommon"
#> 
#> $vz.int.last$selection
#> list()
#> 
#> 
#> $vz.iv.all
#> $vz.iv.all$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.iv.all$values
#> [1] FALSE  TRUE
#> 
#> $vz.iv.all$unit_type
#> [1] "volume"
#> 
#> $vz.iv.all$pretty_name
#> [1] "Vz (for IV dosing,  based on AUCall)"
#> 
#> $vz.iv.all$desc
#> [1] "IV Vz, AUCall"
#> 
#> $vz.iv.all$sparse
#> [1] FALSE
#> 
#> $vz.iv.all$formalsmap
#> $vz.iv.all$formalsmap$cl
#> [1] "cl.iv.all"
#> 
#> 
#> $vz.iv.all$depends
#> [1] "cl.iv.all" "lambda.z" 
#> 
#> $vz.iv.all$datatype
#> [1] "interval"
#> 
#> $vz.iv.all$pptestcd_cdisc
#> [1] "vz.iv.all"
#> 
#> $vz.iv.all$pptest_cdisc
#> [1] "IV Vz, AUCall"
#> 
#> $vz.iv.all$formula
#> [1] "$V_{z,\\text{iv,all}} = \\frac{CL_{\\text{iv,all}}}{\\lambda_z}$"
#> 
#> $vz.iv.all$formula_note
#> NULL
#> 
#> $vz.iv.all$tier
#> [1] "uncommon"
#> 
#> $vz.iv.all$selection
#> list()
#> 
#> 
#> $vz.iv.last
#> $vz.iv.last$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.iv.last$values
#> [1] FALSE  TRUE
#> 
#> $vz.iv.last$unit_type
#> [1] "volume"
#> 
#> $vz.iv.last$pretty_name
#> [1] "Vz (for IV dosing,  based on AUClast)"
#> 
#> $vz.iv.last$desc
#> [1] "IV Vz, AUClast"
#> 
#> $vz.iv.last$sparse
#> [1] FALSE
#> 
#> $vz.iv.last$formalsmap
#> $vz.iv.last$formalsmap$cl
#> [1] "cl.iv.last"
#> 
#> 
#> $vz.iv.last$depends
#> [1] "cl.iv.last" "lambda.z"  
#> 
#> $vz.iv.last$datatype
#> [1] "interval"
#> 
#> $vz.iv.last$pptestcd_cdisc
#> [1] "vz.iv.last"
#> 
#> $vz.iv.last$pptest_cdisc
#> [1] "IV Vz, AUClast"
#> 
#> $vz.iv.last$formula
#> [1] "$V_{z,\\text{iv,last}} = \\frac{CL_{\\text{iv,last}}}{\\lambda_z}$"
#> 
#> $vz.iv.last$formula_note
#> NULL
#> 
#> $vz.iv.last$tier
#> [1] "uncommon"
#> 
#> $vz.iv.last$selection
#> list()
#> 
#> 
#> $vz.ivint.all
#> $vz.ivint.all$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.ivint.all$values
#> [1] FALSE  TRUE
#> 
#> $vz.ivint.all$unit_type
#> [1] "volume"
#> 
#> $vz.ivint.all$pretty_name
#> [1] "Vz (IV dose interval, based on AUCint.all)"
#> 
#> $vz.ivint.all$desc
#> [1] "IV Vz, interval AUCint.all"
#> 
#> $vz.ivint.all$sparse
#> [1] FALSE
#> 
#> $vz.ivint.all$formalsmap
#> $vz.ivint.all$formalsmap$cl
#> [1] "cl.ivint.all"
#> 
#> 
#> $vz.ivint.all$depends
#> [1] "cl.ivint.all" "lambda.z"    
#> 
#> $vz.ivint.all$datatype
#> [1] "interval"
#> 
#> $vz.ivint.all$pptestcd_cdisc
#> [1] "vz.ivint.all"
#> 
#> $vz.ivint.all$pptest_cdisc
#> [1] "IV Vz, interval AUCint.all"
#> 
#> $vz.ivint.all$formula
#> [1] "$V_{z,\\text{iv,int,all}} = \\frac{CL_{\\text{iv,int,all}}}{\\lambda_z}$"
#> 
#> $vz.ivint.all$formula_note
#> NULL
#> 
#> $vz.ivint.all$tier
#> [1] "uncommon"
#> 
#> $vz.ivint.all$selection
#> list()
#> 
#> 
#> $vz.ivint.last
#> $vz.ivint.last$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.ivint.last$values
#> [1] FALSE  TRUE
#> 
#> $vz.ivint.last$unit_type
#> [1] "volume"
#> 
#> $vz.ivint.last$pretty_name
#> [1] "Vz (IV dose interval, based on AUCint.last)"
#> 
#> $vz.ivint.last$desc
#> [1] "IV Vz, interval AUCint.last"
#> 
#> $vz.ivint.last$sparse
#> [1] FALSE
#> 
#> $vz.ivint.last$formalsmap
#> $vz.ivint.last$formalsmap$cl
#> [1] "cl.ivint.last"
#> 
#> 
#> $vz.ivint.last$depends
#> [1] "cl.ivint.last" "lambda.z"     
#> 
#> $vz.ivint.last$datatype
#> [1] "interval"
#> 
#> $vz.ivint.last$pptestcd_cdisc
#> [1] "vz.ivint.last"
#> 
#> $vz.ivint.last$pptest_cdisc
#> [1] "IV Vz, interval AUCint.last"
#> 
#> $vz.ivint.last$formula
#> [1] "$V_{z,\\text{iv,int,last}} = \\frac{CL_{\\text{iv,int,last}}}{\\lambda_z}$"
#> 
#> $vz.ivint.last$formula_note
#> NULL
#> 
#> $vz.ivint.last$tier
#> [1] "uncommon"
#> 
#> $vz.ivint.last$selection
#> list()
#> 
#> 
#> $vz.last
#> $vz.last$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.last$values
#> [1] FALSE  TRUE
#> 
#> $vz.last$unit_type
#> [1] "volume"
#> 
#> $vz.last$pretty_name
#> [1] "Vz (based on AUClast)"
#> 
#> $vz.last$desc
#> [1] "Vz, AUClast-based CL"
#> 
#> $vz.last$sparse
#> [1] FALSE
#> 
#> $vz.last$formalsmap
#> $vz.last$formalsmap$cl
#> [1] "cl.last"
#> 
#> 
#> $vz.last$depends
#> [1] "cl.last"  "lambda.z"
#> 
#> $vz.last$datatype
#> [1] "interval"
#> 
#> $vz.last$pptestcd_cdisc
#> [1] "vz.last"
#> 
#> $vz.last$pptest_cdisc
#> [1] "Vz, AUClast-based CL"
#> 
#> $vz.last$formula
#> [1] "$V_{z,\\text{last}} = \\frac{CL_{\\text{last}}}{\\lambda_z}$"
#> 
#> $vz.last$formula_note
#> NULL
#> 
#> $vz.last$tier
#> [1] "uncommon"
#> 
#> $vz.last$selection
#> list()
#> 
#> 
#> $vss.iv.all
#> $vss.iv.all$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.iv.all$values
#> [1] FALSE  TRUE
#> 
#> $vss.iv.all$unit_type
#> [1] "volume"
#> 
#> $vss.iv.all$pretty_name
#> [1] "Vss (for IV dosing,  based on AUCall)"
#> 
#> $vss.iv.all$desc
#> [1] "IV Vss, calc from AUCall"
#> 
#> $vss.iv.all$sparse
#> [1] FALSE
#> 
#> $vss.iv.all$formalsmap
#> $vss.iv.all$formalsmap$cl
#> [1] "cl.iv.all"
#> 
#> $vss.iv.all$formalsmap$mrt
#> [1] "mrt.iv.all"
#> 
#> 
#> $vss.iv.all$depends
#> [1] "cl.iv.all"  "mrt.iv.all"
#> 
#> $vss.iv.all$datatype
#> [1] "interval"
#> 
#> $vss.iv.all$pptestcd_cdisc
#> [1] "vss.iv.all"
#> 
#> $vss.iv.all$pptest_cdisc
#> [1] "IV Vss, calc from AUCall"
#> 
#> $vss.iv.all$formula
#> NULL
#> 
#> $vss.iv.all$formula_note
#> NULL
#> 
#> $vss.iv.all$tier
#> [1] "uncommon"
#> 
#> $vss.iv.all$selection
#> list()
#> 
#> 
#> $vss.ivint.all
#> $vss.ivint.all$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.ivint.all$values
#> [1] FALSE  TRUE
#> 
#> $vss.ivint.all$unit_type
#> [1] "volume"
#> 
#> $vss.ivint.all$pretty_name
#> [1] "Vss (IV dose interval, based on AUCint.all)"
#> 
#> $vss.ivint.all$desc
#> [1] "IV Vss, calc from interval AUCint.all"
#> 
#> $vss.ivint.all$sparse
#> [1] FALSE
#> 
#> $vss.ivint.all$formalsmap
#> $vss.ivint.all$formalsmap$cl
#> [1] "cl.ivint.all"
#> 
#> $vss.ivint.all$formalsmap$mrt
#> [1] "mrt.ivint.all"
#> 
#> 
#> $vss.ivint.all$depends
#> [1] "cl.ivint.all"  "mrt.ivint.all"
#> 
#> $vss.ivint.all$datatype
#> [1] "interval"
#> 
#> $vss.ivint.all$pptestcd_cdisc
#> [1] "vss.ivint.all"
#> 
#> $vss.ivint.all$pptest_cdisc
#> [1] "IV Vss, calc from interval AUCint.all"
#> 
#> $vss.ivint.all$formula
#> NULL
#> 
#> $vss.ivint.all$formula_note
#> NULL
#> 
#> $vss.ivint.all$tier
#> [1] "uncommon"
#> 
#> $vss.ivint.all$selection
#> list()
#> 
#> 
#> $vss.ivint.last
#> $vss.ivint.last$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.ivint.last$values
#> [1] FALSE  TRUE
#> 
#> $vss.ivint.last$unit_type
#> [1] "volume"
#> 
#> $vss.ivint.last$pretty_name
#> [1] "Vss (IV dose interval, based on AUCint.last)"
#> 
#> $vss.ivint.last$desc
#> [1] "IV Vss, calc from interval AUCint.last"
#> 
#> $vss.ivint.last$sparse
#> [1] FALSE
#> 
#> $vss.ivint.last$formalsmap
#> $vss.ivint.last$formalsmap$cl
#> [1] "cl.ivint.last"
#> 
#> $vss.ivint.last$formalsmap$mrt
#> [1] "mrt.ivint.last"
#> 
#> 
#> $vss.ivint.last$depends
#> [1] "cl.ivint.last"  "mrt.ivint.last"
#> 
#> $vss.ivint.last$datatype
#> [1] "interval"
#> 
#> $vss.ivint.last$pptestcd_cdisc
#> [1] "vss.ivint.last"
#> 
#> $vss.ivint.last$pptest_cdisc
#> [1] "IV Vss, calc from interval AUCint.last"
#> 
#> $vss.ivint.last$formula
#> NULL
#> 
#> $vss.ivint.last$formula_note
#> NULL
#> 
#> $vss.ivint.last$tier
#> [1] "uncommon"
#> 
#> $vss.ivint.last$selection
#> list()
#> 
#> 
#> $vss.sparse.last
#> $vss.sparse.last$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.sparse.last$values
#> [1] FALSE  TRUE
#> 
#> $vss.sparse.last$unit_type
#> [1] "volume"
#> 
#> $vss.sparse.last$pretty_name
#> [1] "Vss (for sparse data, based on AUClast)"
#> 
#> $vss.sparse.last$desc
#> [1] "Vss, calc from sparse AUClast"
#> 
#> $vss.sparse.last$sparse
#> [1] TRUE
#> 
#> $vss.sparse.last$formalsmap
#> $vss.sparse.last$formalsmap$cl
#> [1] "cl.sparse.last"
#> 
#> $vss.sparse.last$formalsmap$mrt
#> [1] "mrt.sparse.last"
#> 
#> 
#> $vss.sparse.last$depends
#> [1] "cl.sparse.last"  "mrt.sparse.last"
#> 
#> $vss.sparse.last$datatype
#> [1] "interval"
#> 
#> $vss.sparse.last$pptestcd_cdisc
#> [1] "vss.sparse.last"
#> 
#> $vss.sparse.last$pptest_cdisc
#> [1] "Vss, calc from sparse AUClast"
#> 
#> $vss.sparse.last$formula
#> NULL
#> 
#> $vss.sparse.last$formula_note
#> NULL
#> 
#> $vss.sparse.last$tier
#> [1] "uncommon"
#> 
#> $vss.sparse.last$selection
#> list()
#> 
#> 
#> $aucinf.obs
#> $aucinf.obs$FUN
#> [1] "pk.calc.auc.inf.obs"
#> 
#> $aucinf.obs$values
#> [1] FALSE  TRUE
#> 
#> $aucinf.obs$unit_type
#> [1] "auc"
#> 
#> $aucinf.obs$pretty_name
#> [1] "AUCinf,obs"
#> 
#> $aucinf.obs$desc
#> [1] "AUC start to inf, obs Clast extrap"
#> 
#> $aucinf.obs$sparse
#> [1] FALSE
#> 
#> $aucinf.obs$formalsmap
#> list()
#> 
#> $aucinf.obs$depends
#> [1] "lambda.z"  "clast.obs"
#> 
#> $aucinf.obs$datatype
#> [1] "interval"
#> 
#> $aucinf.obs$pptestcd_cdisc
#> [1] "AUCIFO"
#> 
#> $aucinf.obs$pptest_cdisc
#> [1] "AUC Infinity Obs"
#> 
#> $aucinf.obs$formula
#> [1] "$AUC_{\\infty,\\text{obs}} = AUC_{0-\\text{last}} + \\frac{C_{\\text{last,obs}}}{\\lambda_z}$"
#> 
#> $aucinf.obs$formula_note
#> NULL
#> 
#> $aucinf.obs$tier
#> [1] "common"
#> 
#> $aucinf.obs$selection
#> list()
#> 
#> $aucinf.obs$requires_dose_amt
#> [1] FALSE
#> 
#> $aucinf.obs$requires_dose_time
#> [1] FALSE
#> 
#> $aucinf.obs$requires_dose_dur
#> [1] FALSE
#> 
#> $aucinf.obs$requires_volume
#> [1] FALSE
#> 
#> $aucinf.obs$requires_conc_dur
#> [1] FALSE
#> 
#> 
#> $aucinf.pred
#> $aucinf.pred$FUN
#> [1] "pk.calc.auc.inf.pred"
#> 
#> $aucinf.pred$values
#> [1] FALSE  TRUE
#> 
#> $aucinf.pred$unit_type
#> [1] "auc"
#> 
#> $aucinf.pred$pretty_name
#> [1] "AUCinf,pred"
#> 
#> $aucinf.pred$desc
#> [1] "AUC start to inf, pred Clast extrap"
#> 
#> $aucinf.pred$sparse
#> [1] FALSE
#> 
#> $aucinf.pred$formalsmap
#> list()
#> 
#> $aucinf.pred$depends
#> [1] "lambda.z"   "clast.pred"
#> 
#> $aucinf.pred$datatype
#> [1] "interval"
#> 
#> $aucinf.pred$pptestcd_cdisc
#> [1] "AUCIFP"
#> 
#> $aucinf.pred$pptest_cdisc
#> [1] "AUC Infinity Pred"
#> 
#> $aucinf.pred$formula
#> [1] "$AUC_{\\infty,\\text{pred}} = AUC_{0-\\text{last}} + \\frac{C_{\\text{last,pred}}}{\\lambda_z}$"
#> 
#> $aucinf.pred$formula_note
#> NULL
#> 
#> $aucinf.pred$tier
#> [1] "uncommon"
#> 
#> $aucinf.pred$selection
#> list()
#> 
#> 
#> $aumcinf.obs
#> $aumcinf.obs$FUN
#> [1] "pk.calc.aumc.inf.obs"
#> 
#> $aumcinf.obs$values
#> [1] FALSE  TRUE
#> 
#> $aumcinf.obs$unit_type
#> [1] "aumc"
#> 
#> $aumcinf.obs$pretty_name
#> [1] "AUMC,inf,obs"
#> 
#> $aumcinf.obs$desc
#> [1] "AUMC start to inf, obs Clast extrap"
#> 
#> $aumcinf.obs$sparse
#> [1] FALSE
#> 
#> $aumcinf.obs$formalsmap
#> list()
#> 
#> $aumcinf.obs$depends
#> [1] "lambda.z"  "clast.obs"
#> 
#> $aumcinf.obs$datatype
#> [1] "interval"
#> 
#> $aumcinf.obs$pptestcd_cdisc
#> [1] "AUMCIFO"
#> 
#> $aumcinf.obs$pptest_cdisc
#> [1] "AUMC Infinity Obs"
#> 
#> $aumcinf.obs$formula
#> [1] "$AUMC_{\\infty,\\text{obs}} = AUMC_{0-\\text{last}} + \\frac{C_{\\text{last,obs}} T_{\\text{last}}}{\\lambda_z} + \\frac{C_{\\text{last,obs}}}{\\lambda_z^2}$"
#> 
#> $aumcinf.obs$formula_note
#> NULL
#> 
#> $aumcinf.obs$tier
#> [1] "uncommon"
#> 
#> $aumcinf.obs$selection
#> list()
#> 
#> 
#> $aumcinf.pred
#> $aumcinf.pred$FUN
#> [1] "pk.calc.aumc.inf.pred"
#> 
#> $aumcinf.pred$values
#> [1] FALSE  TRUE
#> 
#> $aumcinf.pred$unit_type
#> [1] "aumc"
#> 
#> $aumcinf.pred$pretty_name
#> [1] "AUMC,inf,pred"
#> 
#> $aumcinf.pred$desc
#> [1] "AUMC start to inf, pred Clast extrap"
#> 
#> $aumcinf.pred$sparse
#> [1] FALSE
#> 
#> $aumcinf.pred$formalsmap
#> list()
#> 
#> $aumcinf.pred$depends
#> [1] "lambda.z"   "clast.pred"
#> 
#> $aumcinf.pred$datatype
#> [1] "interval"
#> 
#> $aumcinf.pred$pptestcd_cdisc
#> [1] "AUMCIFP"
#> 
#> $aumcinf.pred$pptest_cdisc
#> [1] "AUMC Infinity Pred"
#> 
#> $aumcinf.pred$formula
#> [1] "$AUMC_{\\infty,\\text{pred}} = AUMC_{0-\\text{last}} + \\frac{C_{\\text{last,pred}} T_{\\text{last}}}{\\lambda_z} + \\frac{C_{\\text{last,pred}}}{\\lambda_z^2}$"
#> 
#> $aumcinf.pred$formula_note
#> NULL
#> 
#> $aumcinf.pred$tier
#> [1] "uncommon"
#> 
#> $aumcinf.pred$selection
#> list()
#> 
#> 
#> $aucint.inf.obs
#> $aucint.inf.obs$FUN
#> [1] "pk.calc.aucint.inf.obs"
#> 
#> $aucint.inf.obs$values
#> [1] FALSE  TRUE
#> 
#> $aucint.inf.obs$unit_type
#> [1] "auc"
#> 
#> $aucint.inf.obs$pretty_name
#> [1] "AUCint (based on AUCinf,obs extrapolation)"
#> 
#> $aucint.inf.obs$desc
#> [1] "AUC from T1 to T2 (AUCinf,obs extrap)"
#> 
#> $aucint.inf.obs$sparse
#> [1] FALSE
#> 
#> $aucint.inf.obs$formalsmap
#> $aucint.inf.obs$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aucint.inf.obs$formalsmap$time
#> [1] "time.group"
#> 
#> $aucint.inf.obs$formalsmap$time.dose
#> NULL
#> 
#> 
#> $aucint.inf.obs$depends
#> [1] "lambda.z"  "clast.obs"
#> 
#> $aucint.inf.obs$datatype
#> [1] "interval"
#> 
#> $aucint.inf.obs$pptestcd_cdisc
#> [1] "AUCINTIS"
#> 
#> $aucint.inf.obs$pptest_cdisc
#> [1] "AUCint (based on AUCinf,obs extrapolation)"
#> 
#> $aucint.inf.obs$formula
#> [1] "$AUC_{\\text{int,}\\infty\\text{,obs}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aucint.inf.obs$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aucint.inf.obs$tier
#> [1] "common"
#> 
#> $aucint.inf.obs$selection
#> list()
#> 
#> 
#> $aucint.inf.obs.dose
#> $aucint.inf.obs.dose$FUN
#> [1] "pk.calc.aucint.inf.obs"
#> 
#> $aucint.inf.obs.dose$values
#> [1] FALSE  TRUE
#> 
#> $aucint.inf.obs.dose$unit_type
#> [1] "auc"
#> 
#> $aucint.inf.obs.dose$pretty_name
#> [1] "AUCint (based on AUCinf,obs extrapolation, dose-aware)"
#> 
#> $aucint.inf.obs.dose$desc
#> [1] "AUC T1 to T2, dose-aware (AUCinf,obs)"
#> 
#> $aucint.inf.obs.dose$sparse
#> [1] FALSE
#> 
#> $aucint.inf.obs.dose$formalsmap
#> $aucint.inf.obs.dose$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aucint.inf.obs.dose$formalsmap$time
#> [1] "time.group"
#> 
#> $aucint.inf.obs.dose$formalsmap$time.dose
#> [1] "time.dose.group"
#> 
#> 
#> $aucint.inf.obs.dose$depends
#> [1] "lambda.z"  "clast.obs"
#> 
#> $aucint.inf.obs.dose$datatype
#> [1] "interval"
#> 
#> $aucint.inf.obs.dose$pptestcd_cdisc
#> [1] "AUCINTID"
#> 
#> $aucint.inf.obs.dose$pptest_cdisc
#> [1] "AUCint (based on AUCinf,obs extrapolation, dose-aware)"
#> 
#> $aucint.inf.obs.dose$formula
#> [1] "$AUC_{\\text{int,}\\infty\\text{,obs,dose}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aucint.inf.obs.dose$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aucint.inf.obs.dose$tier
#> [1] "uncommon"
#> 
#> $aucint.inf.obs.dose$selection
#> list()
#> 
#> 
#> $aucint.inf.pred
#> $aucint.inf.pred$FUN
#> [1] "pk.calc.aucint.inf.pred"
#> 
#> $aucint.inf.pred$values
#> [1] FALSE  TRUE
#> 
#> $aucint.inf.pred$unit_type
#> [1] "auc"
#> 
#> $aucint.inf.pred$pretty_name
#> [1] "AUCint (based on AUCinf,pred extrapolation)"
#> 
#> $aucint.inf.pred$desc
#> [1] "AUC from T1 to T2 (AUCinf,pred extrap)"
#> 
#> $aucint.inf.pred$sparse
#> [1] FALSE
#> 
#> $aucint.inf.pred$formalsmap
#> $aucint.inf.pred$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aucint.inf.pred$formalsmap$time
#> [1] "time.group"
#> 
#> $aucint.inf.pred$formalsmap$time.dose
#> NULL
#> 
#> 
#> $aucint.inf.pred$depends
#> [1] "lambda.z"   "clast.pred"
#> 
#> $aucint.inf.pred$datatype
#> [1] "interval"
#> 
#> $aucint.inf.pred$pptestcd_cdisc
#> [1] "AUCINTIP"
#> 
#> $aucint.inf.pred$pptest_cdisc
#> [1] "AUCint (based on AUCinf,pred extrapolation)"
#> 
#> $aucint.inf.pred$formula
#> [1] "$AUC_{\\text{int,}\\infty\\text{,pred}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aucint.inf.pred$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aucint.inf.pred$tier
#> [1] "uncommon"
#> 
#> $aucint.inf.pred$selection
#> list()
#> 
#> 
#> $aucint.inf.pred.dose
#> $aucint.inf.pred.dose$FUN
#> [1] "pk.calc.aucint.inf.pred"
#> 
#> $aucint.inf.pred.dose$values
#> [1] FALSE  TRUE
#> 
#> $aucint.inf.pred.dose$unit_type
#> [1] "auc"
#> 
#> $aucint.inf.pred.dose$pretty_name
#> [1] "AUCint (based on AUCinf,pred extrapolation, dose-aware)"
#> 
#> $aucint.inf.pred.dose$desc
#> [1] "AUC T1 to T2, dose-aware (AUCinf,pred)"
#> 
#> $aucint.inf.pred.dose$sparse
#> [1] FALSE
#> 
#> $aucint.inf.pred.dose$formalsmap
#> $aucint.inf.pred.dose$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aucint.inf.pred.dose$formalsmap$time
#> [1] "time.group"
#> 
#> $aucint.inf.pred.dose$formalsmap$time.dose
#> [1] "time.dose.group"
#> 
#> 
#> $aucint.inf.pred.dose$depends
#> [1] "lambda.z"   "clast.pred"
#> 
#> $aucint.inf.pred.dose$datatype
#> [1] "interval"
#> 
#> $aucint.inf.pred.dose$pptestcd_cdisc
#> [1] "AUCINTPD"
#> 
#> $aucint.inf.pred.dose$pptest_cdisc
#> [1] "AUCint (based on AUCinf,pred extrapolation, dose-aware)"
#> 
#> $aucint.inf.pred.dose$formula
#> [1] "$AUC_{\\text{int,}\\infty\\text{,pred,dose}} = \\sum_{k} AUC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aucint.inf.pred.dose$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aucint.inf.pred.dose$tier
#> [1] "uncommon"
#> 
#> $aucint.inf.pred.dose$selection
#> list()
#> 
#> 
#> $aumcint.inf.obs
#> $aumcint.inf.obs$FUN
#> [1] "pk.calc.aumcint.inf.obs"
#> 
#> $aumcint.inf.obs$values
#> [1] FALSE  TRUE
#> 
#> $aumcint.inf.obs$unit_type
#> [1] "aumc"
#> 
#> $aumcint.inf.obs$pretty_name
#> [1] "AUMCint (based on AUMCinf,obs extrapolation)"
#> 
#> $aumcint.inf.obs$desc
#> [1] "AUMC from T1 to T2 (AUMCinf,obs extrap)"
#> 
#> $aumcint.inf.obs$sparse
#> [1] FALSE
#> 
#> $aumcint.inf.obs$formalsmap
#> $aumcint.inf.obs$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aumcint.inf.obs$formalsmap$time
#> [1] "time.group"
#> 
#> $aumcint.inf.obs$formalsmap$time.dose
#> NULL
#> 
#> 
#> $aumcint.inf.obs$depends
#> [1] "lambda.z"  "clast.obs"
#> 
#> $aumcint.inf.obs$datatype
#> [1] "interval"
#> 
#> $aumcint.inf.obs$pptestcd_cdisc
#> [1] "aumcint.inf.obs"
#> 
#> $aumcint.inf.obs$pptest_cdisc
#> [1] "AUMC from T1 to T2 (AUMCinf,obs extrap)"
#> 
#> $aumcint.inf.obs$formula
#> [1] "$AUMC_{\\text{int,}\\infty\\text{,obs}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumcint.inf.obs$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aumcint.inf.obs$tier
#> [1] "uncommon"
#> 
#> $aumcint.inf.obs$selection
#> list()
#> 
#> 
#> $aumcint.inf.obs.dose
#> $aumcint.inf.obs.dose$FUN
#> [1] "pk.calc.aumcint.inf.obs"
#> 
#> $aumcint.inf.obs.dose$values
#> [1] FALSE  TRUE
#> 
#> $aumcint.inf.obs.dose$unit_type
#> [1] "aumc"
#> 
#> $aumcint.inf.obs.dose$pretty_name
#> [1] "AUMCint (based on AUMCinf,obs extrapolation, dose-aware)"
#> 
#> $aumcint.inf.obs.dose$desc
#> [1] "AUMC T1 to T2, dose-aware (AUMCinf,obs)"
#> 
#> $aumcint.inf.obs.dose$sparse
#> [1] FALSE
#> 
#> $aumcint.inf.obs.dose$formalsmap
#> $aumcint.inf.obs.dose$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aumcint.inf.obs.dose$formalsmap$time
#> [1] "time.group"
#> 
#> $aumcint.inf.obs.dose$formalsmap$time.dose
#> [1] "time.dose.group"
#> 
#> 
#> $aumcint.inf.obs.dose$depends
#> [1] "lambda.z"  "clast.obs"
#> 
#> $aumcint.inf.obs.dose$datatype
#> [1] "interval"
#> 
#> $aumcint.inf.obs.dose$pptestcd_cdisc
#> [1] "aumcint.inf.obs.dose"
#> 
#> $aumcint.inf.obs.dose$pptest_cdisc
#> [1] "AUMC T1 to T2, dose-aware (AUMCinf,obs)"
#> 
#> $aumcint.inf.obs.dose$formula
#> [1] "$AUMC_{\\text{int,}\\infty\\text{,obs,dose}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumcint.inf.obs.dose$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aumcint.inf.obs.dose$tier
#> [1] "uncommon"
#> 
#> $aumcint.inf.obs.dose$selection
#> list()
#> 
#> 
#> $aumcint.inf.pred
#> $aumcint.inf.pred$FUN
#> [1] "pk.calc.aumcint.inf.pred"
#> 
#> $aumcint.inf.pred$values
#> [1] FALSE  TRUE
#> 
#> $aumcint.inf.pred$unit_type
#> [1] "aumc"
#> 
#> $aumcint.inf.pred$pretty_name
#> [1] "AUMCint (based on AUMCinf,pred extrapolation)"
#> 
#> $aumcint.inf.pred$desc
#> [1] "AUMC from T1 to T2 (AUMCinf,pred extrap)"
#> 
#> $aumcint.inf.pred$sparse
#> [1] FALSE
#> 
#> $aumcint.inf.pred$formalsmap
#> $aumcint.inf.pred$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aumcint.inf.pred$formalsmap$time
#> [1] "time.group"
#> 
#> $aumcint.inf.pred$formalsmap$time.dose
#> NULL
#> 
#> 
#> $aumcint.inf.pred$depends
#> [1] "lambda.z"   "clast.pred"
#> 
#> $aumcint.inf.pred$datatype
#> [1] "interval"
#> 
#> $aumcint.inf.pred$pptestcd_cdisc
#> [1] "aumcint.inf.pred"
#> 
#> $aumcint.inf.pred$pptest_cdisc
#> [1] "AUMC from T1 to T2 (AUMCinf,pred extrap)"
#> 
#> $aumcint.inf.pred$formula
#> [1] "$AUMC_{\\text{int,}\\infty\\text{,pred}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumcint.inf.pred$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aumcint.inf.pred$tier
#> [1] "uncommon"
#> 
#> $aumcint.inf.pred$selection
#> list()
#> 
#> 
#> $aumcint.inf.pred.dose
#> $aumcint.inf.pred.dose$FUN
#> [1] "pk.calc.aumcint.inf.pred"
#> 
#> $aumcint.inf.pred.dose$values
#> [1] FALSE  TRUE
#> 
#> $aumcint.inf.pred.dose$unit_type
#> [1] "aumc"
#> 
#> $aumcint.inf.pred.dose$pretty_name
#> [1] "AUMCint (based on AUMCinf,pred extrapolation, dose-aware)"
#> 
#> $aumcint.inf.pred.dose$desc
#> [1] "AUMC T1 to T2, dose-aware (AUMCinf,pred)"
#> 
#> $aumcint.inf.pred.dose$sparse
#> [1] FALSE
#> 
#> $aumcint.inf.pred.dose$formalsmap
#> $aumcint.inf.pred.dose$formalsmap$conc
#> [1] "conc.group"
#> 
#> $aumcint.inf.pred.dose$formalsmap$time
#> [1] "time.group"
#> 
#> $aumcint.inf.pred.dose$formalsmap$time.dose
#> [1] "time.dose.group"
#> 
#> 
#> $aumcint.inf.pred.dose$depends
#> [1] "lambda.z"   "clast.pred"
#> 
#> $aumcint.inf.pred.dose$datatype
#> [1] "interval"
#> 
#> $aumcint.inf.pred.dose$pptestcd_cdisc
#> [1] "aumcint.inf.pred.dose"
#> 
#> $aumcint.inf.pred.dose$pptest_cdisc
#> [1] "AUMC T1 to T2, dose-aware (AUMCinf,pred)"
#> 
#> $aumcint.inf.pred.dose$formula
#> [1] "$AUMC_{\\text{int,}\\infty\\text{,pred,dose}} = \\sum_{k} AUMC_k(C_k, C_{k+1}, t_k, t_{k+1})$"
#> 
#> $aumcint.inf.pred.dose$formula_note
#> [1] "Trapezoidal rule with interpolation at interval boundaries"
#> 
#> $aumcint.inf.pred.dose$tier
#> [1] "uncommon"
#> 
#> $aumcint.inf.pred.dose$selection
#> list()
#> 
#> 
#> $aucivinf.obs
#> $aucivinf.obs$FUN
#> [1] "pk.calc.auciv"
#> 
#> $aucivinf.obs$values
#> [1] FALSE  TRUE
#> 
#> $aucivinf.obs$unit_type
#> [1] "auc"
#> 
#> $aucivinf.obs$pretty_name
#> [1] "AUCinf,obs (IV dosing)"
#> 
#> $aucivinf.obs$desc
#> [1] "AUCinf.obs, IV back-extrap C0"
#> 
#> $aucivinf.obs$sparse
#> [1] FALSE
#> 
#> $aucivinf.obs$formalsmap
#> $aucivinf.obs$formalsmap$auc
#> [1] "aucinf.obs"
#> 
#> $aucivinf.obs$formalsmap$auc.type
#> [1] "AUCinf"
#> 
#> $aucivinf.obs$formalsmap$clast
#> [1] "clast.obs"
#> 
#> 
#> $aucivinf.obs$depends
#> [1] "aucinf.obs" "c0"         "lambda.z"   "clast.obs" 
#> 
#> $aucivinf.obs$datatype
#> [1] "interval"
#> 
#> $aucivinf.obs$pptestcd_cdisc
#> [1] "AUCIVIS"
#> 
#> $aucivinf.obs$pptest_cdisc
#> [1] "AUCinf,obs (IV dosing)"
#> 
#> $aucivinf.obs$formula
#> [1] "$AUC_{\\text{iv,}\\infty\\text{,obs}} = AUC_{\\infty,\\text{obs}} + AUC(C_0, t_1) - AUC(C(0), t_1)$"
#> 
#> $aucivinf.obs$formula_note
#> NULL
#> 
#> $aucivinf.obs$tier
#> [1] "uncommon"
#> 
#> $aucivinf.obs$selection
#> list()
#> 
#> 
#> $aucivinf.pred
#> $aucivinf.pred$FUN
#> [1] "pk.calc.auciv"
#> 
#> $aucivinf.pred$values
#> [1] FALSE  TRUE
#> 
#> $aucivinf.pred$unit_type
#> [1] "auc"
#> 
#> $aucivinf.pred$pretty_name
#> [1] "AUCinf,pred (IV dosing)"
#> 
#> $aucivinf.pred$desc
#> [1] "AUCinf.pred, IV back-extrap C0"
#> 
#> $aucivinf.pred$sparse
#> [1] FALSE
#> 
#> $aucivinf.pred$formalsmap
#> $aucivinf.pred$formalsmap$auc
#> [1] "aucinf.pred"
#> 
#> $aucivinf.pred$formalsmap$auc.type
#> [1] "AUCinf"
#> 
#> $aucivinf.pred$formalsmap$clast
#> [1] "clast.pred"
#> 
#> 
#> $aucivinf.pred$depends
#> [1] "aucinf.pred" "c0"          "lambda.z"    "clast.pred" 
#> 
#> $aucivinf.pred$datatype
#> [1] "interval"
#> 
#> $aucivinf.pred$pptestcd_cdisc
#> [1] "AUCIVIP"
#> 
#> $aucivinf.pred$pptest_cdisc
#> [1] "AUCinf,pred (IV dosing)"
#> 
#> $aucivinf.pred$formula
#> [1] "$AUC_{\\text{iv,}\\infty\\text{,pred}} = AUC_{\\infty,\\text{pred}} + AUC(C_0, t_1) - AUC(C(0), t_1)$"
#> 
#> $aucivinf.pred$formula_note
#> NULL
#> 
#> $aucivinf.pred$tier
#> [1] "uncommon"
#> 
#> $aucivinf.pred$selection
#> list()
#> 
#> 
#> $aucivpbextinf.obs
#> $aucivpbextinf.obs$FUN
#> [1] "pk.calc.auciv_pbext"
#> 
#> $aucivpbextinf.obs$values
#> [1] FALSE  TRUE
#> 
#> $aucivpbextinf.obs$unit_type
#> [1] "%"
#> 
#> $aucivpbextinf.obs$pretty_name
#> [1] "AUCbext (based on AUCinf,obs)"
#> 
#> $aucivpbextinf.obs$desc
#> [1] "Back-extrap %, IV, AUCinf.obs"
#> 
#> $aucivpbextinf.obs$sparse
#> [1] FALSE
#> 
#> $aucivpbextinf.obs$formalsmap
#> $aucivpbextinf.obs$formalsmap$auc
#> [1] "aucinf.obs"
#> 
#> $aucivpbextinf.obs$formalsmap$auciv
#> [1] "aucivinf.obs"
#> 
#> 
#> $aucivpbextinf.obs$depends
#> [1] "aucinf.obs"   "aucivinf.obs"
#> 
#> $aucivpbextinf.obs$datatype
#> [1] "interval"
#> 
#> $aucivpbextinf.obs$pptestcd_cdisc
#> [1] "AUCIVPEI"
#> 
#> $aucivpbextinf.obs$pptest_cdisc
#> [1] "AUCbext (based on AUCinf,obs)"
#> 
#> $aucivpbextinf.obs$formula
#> [1] "$\\%AUC_{\\text{bext,}\\infty\\text{,obs}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\infty,\\text{obs}}}{AUC_{\\text{iv,}\\infty\\text{,obs}}}\\right)$"
#> 
#> $aucivpbextinf.obs$formula_note
#> NULL
#> 
#> $aucivpbextinf.obs$tier
#> [1] "uncommon"
#> 
#> $aucivpbextinf.obs$selection
#> list()
#> 
#> 
#> $aucivpbextinf.pred
#> $aucivpbextinf.pred$FUN
#> [1] "pk.calc.auciv_pbext"
#> 
#> $aucivpbextinf.pred$values
#> [1] FALSE  TRUE
#> 
#> $aucivpbextinf.pred$unit_type
#> [1] "%"
#> 
#> $aucivpbextinf.pred$pretty_name
#> [1] "AUCbext (based on AUCinf,pred)"
#> 
#> $aucivpbextinf.pred$desc
#> [1] "Back-extrap %, IV, AUCinf.pred"
#> 
#> $aucivpbextinf.pred$sparse
#> [1] FALSE
#> 
#> $aucivpbextinf.pred$formalsmap
#> $aucivpbextinf.pred$formalsmap$auc
#> [1] "aucinf.pred"
#> 
#> $aucivpbextinf.pred$formalsmap$auciv
#> [1] "aucivinf.pred"
#> 
#> 
#> $aucivpbextinf.pred$depends
#> [1] "aucinf.pred"   "aucivinf.pred"
#> 
#> $aucivpbextinf.pred$datatype
#> [1] "interval"
#> 
#> $aucivpbextinf.pred$pptestcd_cdisc
#> [1] "AUCIVPEP"
#> 
#> $aucivpbextinf.pred$pptest_cdisc
#> [1] "AUCbext (based on AUCinf,pred)"
#> 
#> $aucivpbextinf.pred$formula
#> [1] "$\\%AUC_{\\text{bext,}\\infty\\text{,pred}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\infty,\\text{pred}}}{AUC_{\\text{iv,}\\infty\\text{,pred}}}\\right)$"
#> 
#> $aucivpbextinf.pred$formula_note
#> NULL
#> 
#> $aucivpbextinf.pred$tier
#> [1] "uncommon"
#> 
#> $aucivpbextinf.pred$selection
#> list()
#> 
#> 
#> $aumcivinf.obs
#> $aumcivinf.obs$FUN
#> [1] "pk.calc.aumciv"
#> 
#> $aumcivinf.obs$values
#> [1] FALSE  TRUE
#> 
#> $aumcivinf.obs$unit_type
#> [1] "aumc"
#> 
#> $aumcivinf.obs$pretty_name
#> [1] "AUMCinf,obs (IV dosing)"
#> 
#> $aumcivinf.obs$desc
#> [1] "AUMCinf.obs, IV back-extrap C0"
#> 
#> $aumcivinf.obs$sparse
#> [1] FALSE
#> 
#> $aumcivinf.obs$formalsmap
#> $aumcivinf.obs$formalsmap$aumc
#> [1] "aumcinf.obs"
#> 
#> $aumcivinf.obs$formalsmap$auc.type
#> [1] "AUCinf"
#> 
#> $aumcivinf.obs$formalsmap$clast
#> [1] "clast.obs"
#> 
#> 
#> $aumcivinf.obs$depends
#> [1] "aumcinf.obs" "c0"          "lambda.z"    "clast.obs"  
#> 
#> $aumcivinf.obs$datatype
#> [1] "interval"
#> 
#> $aumcivinf.obs$pptestcd_cdisc
#> [1] "aumcivinf.obs"
#> 
#> $aumcivinf.obs$pptest_cdisc
#> [1] "AUMCinf.obs, IV back-extrap C0"
#> 
#> $aumcivinf.obs$formula
#> NULL
#> 
#> $aumcivinf.obs$formula_note
#> NULL
#> 
#> $aumcivinf.obs$tier
#> [1] "uncommon"
#> 
#> $aumcivinf.obs$selection
#> list()
#> 
#> 
#> $aumcivinf.pred
#> $aumcivinf.pred$FUN
#> [1] "pk.calc.aumciv"
#> 
#> $aumcivinf.pred$values
#> [1] FALSE  TRUE
#> 
#> $aumcivinf.pred$unit_type
#> [1] "aumc"
#> 
#> $aumcivinf.pred$pretty_name
#> [1] "AUMCinf,pred (IV dosing)"
#> 
#> $aumcivinf.pred$desc
#> [1] "AUMCinf.pred, IV back-extrap C0"
#> 
#> $aumcivinf.pred$sparse
#> [1] FALSE
#> 
#> $aumcivinf.pred$formalsmap
#> $aumcivinf.pred$formalsmap$aumc
#> [1] "aumcinf.pred"
#> 
#> $aumcivinf.pred$formalsmap$auc.type
#> [1] "AUCinf"
#> 
#> $aumcivinf.pred$formalsmap$clast
#> [1] "clast.pred"
#> 
#> 
#> $aumcivinf.pred$depends
#> [1] "aumcinf.pred" "c0"           "lambda.z"     "clast.pred"  
#> 
#> $aumcivinf.pred$datatype
#> [1] "interval"
#> 
#> $aumcivinf.pred$pptestcd_cdisc
#> [1] "aumcivinf.pred"
#> 
#> $aumcivinf.pred$pptest_cdisc
#> [1] "AUMCinf.pred, IV back-extrap C0"
#> 
#> $aumcivinf.pred$formula
#> NULL
#> 
#> $aumcivinf.pred$formula_note
#> NULL
#> 
#> $aumcivinf.pred$tier
#> [1] "uncommon"
#> 
#> $aumcivinf.pred$selection
#> list()
#> 
#> 
#> $aucpext.obs
#> $aucpext.obs$FUN
#> [1] "pk.calc.aucpext"
#> 
#> $aucpext.obs$values
#> [1] FALSE  TRUE
#> 
#> $aucpext.obs$unit_type
#> [1] "%"
#> 
#> $aucpext.obs$pretty_name
#> [1] "AUCpext (based on AUCinf,obs)"
#> 
#> $aucpext.obs$desc
#> [1] "% AUCinf extrap after Tlast, obs"
#> 
#> $aucpext.obs$sparse
#> [1] FALSE
#> 
#> $aucpext.obs$formalsmap
#> $aucpext.obs$formalsmap$aucinf
#> [1] "aucinf.obs"
#> 
#> 
#> $aucpext.obs$depends
#> [1] "auclast"    "aucinf.obs"
#> 
#> $aucpext.obs$datatype
#> [1] "interval"
#> 
#> $aucpext.obs$pptestcd_cdisc
#> [1] "AUCPEO"
#> 
#> $aucpext.obs$pptest_cdisc
#> [1] "AUC %Extrapolation Obs"
#> 
#> $aucpext.obs$formula
#> [1] "$\\%AUC_{\\text{ext,obs}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{last}}}{AUC_{\\infty,\\text{obs}}}\\right)$"
#> 
#> $aucpext.obs$formula_note
#> NULL
#> 
#> $aucpext.obs$tier
#> [1] "common"
#> 
#> $aucpext.obs$selection
#> list()
#> 
#> $aucpext.obs$requires_dose_amt
#> [1] FALSE
#> 
#> $aucpext.obs$requires_dose_time
#> [1] FALSE
#> 
#> $aucpext.obs$requires_dose_dur
#> [1] FALSE
#> 
#> $aucpext.obs$requires_volume
#> [1] FALSE
#> 
#> $aucpext.obs$requires_conc_dur
#> [1] FALSE
#> 
#> 
#> $aucpext.pred
#> $aucpext.pred$FUN
#> [1] "pk.calc.aucpext"
#> 
#> $aucpext.pred$values
#> [1] FALSE  TRUE
#> 
#> $aucpext.pred$unit_type
#> [1] "%"
#> 
#> $aucpext.pred$pretty_name
#> [1] "AUCpext (based on AUCinf,pred)"
#> 
#> $aucpext.pred$desc
#> [1] "% AUCinf extrap after Tlast, pred"
#> 
#> $aucpext.pred$sparse
#> [1] FALSE
#> 
#> $aucpext.pred$formalsmap
#> $aucpext.pred$formalsmap$aucinf
#> [1] "aucinf.pred"
#> 
#> 
#> $aucpext.pred$depends
#> [1] "auclast"     "aucinf.pred"
#> 
#> $aucpext.pred$datatype
#> [1] "interval"
#> 
#> $aucpext.pred$pptestcd_cdisc
#> [1] "AUCPEP"
#> 
#> $aucpext.pred$pptest_cdisc
#> [1] "AUC %Extrapolation Pred"
#> 
#> $aucpext.pred$formula
#> [1] "$\\%AUC_{\\text{ext,pred}} = 100 \\cdot \\left(1 - \\frac{AUC_{\\text{last}}}{AUC_{\\infty,\\text{pred}}}\\right)$"
#> 
#> $aucpext.pred$formula_note
#> NULL
#> 
#> $aucpext.pred$tier
#> [1] "uncommon"
#> 
#> $aucpext.pred$selection
#> list()
#> 
#> 
#> $kel.iv.all
#> $kel.iv.all$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.iv.all$values
#> [1] FALSE  TRUE
#> 
#> $kel.iv.all$unit_type
#> [1] "inverse_time"
#> 
#> $kel.iv.all$pretty_name
#> [1] "Kel (for IV dosing,  based on AUCall)"
#> 
#> $kel.iv.all$desc
#> [1] "Elim rate, IV MRTall"
#> 
#> $kel.iv.all$sparse
#> [1] FALSE
#> 
#> $kel.iv.all$formalsmap
#> $kel.iv.all$formalsmap$mrt
#> [1] "mrt.iv.all"
#> 
#> 
#> $kel.iv.all$depends
#> [1] "mrt.iv.all"
#> 
#> $kel.iv.all$datatype
#> [1] "interval"
#> 
#> $kel.iv.all$pptestcd_cdisc
#> [1] "kel.iv.all"
#> 
#> $kel.iv.all$pptest_cdisc
#> [1] "Elim rate, IV MRTall"
#> 
#> $kel.iv.all$formula
#> NULL
#> 
#> $kel.iv.all$formula_note
#> NULL
#> 
#> $kel.iv.all$tier
#> [1] "uncommon"
#> 
#> $kel.iv.all$selection
#> list()
#> 
#> 
#> $kel.ivint.all
#> $kel.ivint.all$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.ivint.all$values
#> [1] FALSE  TRUE
#> 
#> $kel.ivint.all$unit_type
#> [1] "inverse_time"
#> 
#> $kel.ivint.all$pretty_name
#> [1] "Kel (IV dose interval, based on AUCint.all)"
#> 
#> $kel.ivint.all$desc
#> [1] "Elim rate, IV MRTint.all"
#> 
#> $kel.ivint.all$sparse
#> [1] FALSE
#> 
#> $kel.ivint.all$formalsmap
#> $kel.ivint.all$formalsmap$mrt
#> [1] "mrt.ivint.all"
#> 
#> 
#> $kel.ivint.all$depends
#> [1] "mrt.ivint.all"
#> 
#> $kel.ivint.all$datatype
#> [1] "interval"
#> 
#> $kel.ivint.all$pptestcd_cdisc
#> [1] "kel.ivint.all"
#> 
#> $kel.ivint.all$pptest_cdisc
#> [1] "Elim rate, IV MRTint.all"
#> 
#> $kel.ivint.all$formula
#> NULL
#> 
#> $kel.ivint.all$formula_note
#> NULL
#> 
#> $kel.ivint.all$tier
#> [1] "uncommon"
#> 
#> $kel.ivint.all$selection
#> list()
#> 
#> 
#> $kel.ivint.last
#> $kel.ivint.last$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.ivint.last$values
#> [1] FALSE  TRUE
#> 
#> $kel.ivint.last$unit_type
#> [1] "inverse_time"
#> 
#> $kel.ivint.last$pretty_name
#> [1] "Kel (IV dose interval, based on AUCint.last)"
#> 
#> $kel.ivint.last$desc
#> [1] "Elim rate, IV MRTint.last"
#> 
#> $kel.ivint.last$sparse
#> [1] FALSE
#> 
#> $kel.ivint.last$formalsmap
#> $kel.ivint.last$formalsmap$mrt
#> [1] "mrt.ivint.last"
#> 
#> 
#> $kel.ivint.last$depends
#> [1] "mrt.ivint.last"
#> 
#> $kel.ivint.last$datatype
#> [1] "interval"
#> 
#> $kel.ivint.last$pptestcd_cdisc
#> [1] "kel.ivint.last"
#> 
#> $kel.ivint.last$pptest_cdisc
#> [1] "Elim rate, IV MRTint.last"
#> 
#> $kel.ivint.last$formula
#> NULL
#> 
#> $kel.ivint.last$formula_note
#> NULL
#> 
#> $kel.ivint.last$tier
#> [1] "uncommon"
#> 
#> $kel.ivint.last$selection
#> list()
#> 
#> 
#> $kel.sparse.last
#> $kel.sparse.last$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.sparse.last$values
#> [1] FALSE  TRUE
#> 
#> $kel.sparse.last$unit_type
#> [1] "inverse_time"
#> 
#> $kel.sparse.last$pretty_name
#> [1] "Kel (for sparse data, based on AUClast)"
#> 
#> $kel.sparse.last$desc
#> [1] "Elim rate, sparse MRTlast"
#> 
#> $kel.sparse.last$sparse
#> [1] TRUE
#> 
#> $kel.sparse.last$formalsmap
#> $kel.sparse.last$formalsmap$mrt
#> [1] "mrt.sparse.last"
#> 
#> 
#> $kel.sparse.last$depends
#> [1] "mrt.sparse.last"
#> 
#> $kel.sparse.last$datatype
#> [1] "interval"
#> 
#> $kel.sparse.last$pptestcd_cdisc
#> [1] "kel.sparse.last"
#> 
#> $kel.sparse.last$pptest_cdisc
#> [1] "Elim rate, sparse MRTlast"
#> 
#> $kel.sparse.last$formula
#> NULL
#> 
#> $kel.sparse.last$formula_note
#> NULL
#> 
#> $kel.sparse.last$tier
#> [1] "uncommon"
#> 
#> $kel.sparse.last$selection
#> list()
#> 
#> 
#> $cl.obs
#> $cl.obs$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.obs$values
#> [1] FALSE  TRUE
#> 
#> $cl.obs$unit_type
#> [1] "clearance"
#> 
#> $cl.obs$pretty_name
#> [1] "CL (based on AUCinf,obs)"
#> 
#> $cl.obs$desc
#> [1] "Clearance, observed Clast"
#> 
#> $cl.obs$sparse
#> [1] FALSE
#> 
#> $cl.obs$formalsmap
#> $cl.obs$formalsmap$auc
#> [1] "aucinf.obs"
#> 
#> 
#> $cl.obs$depends
#> [1] "aucinf.obs"
#> 
#> $cl.obs$datatype
#> [1] "interval"
#> 
#> $cl.obs$pptestcd_cdisc
#> $cl.obs$pptestcd_cdisc$route
#> $cl.obs$pptestcd_cdisc$route$extravascular
#> [1] "CLF/FO"
#> 
#> $cl.obs$pptestcd_cdisc$route$intravascular
#> [1] "CLO"
#> 
#> 
#> 
#> $cl.obs$pptest_cdisc
#> $cl.obs$pptest_cdisc$route
#> $cl.obs$pptest_cdisc$route$extravascular
#> [1] "Total CL Obs by F"
#> 
#> $cl.obs$pptest_cdisc$route$intravascular
#> [1] "Total CL Obs"
#> 
#> 
#> 
#> $cl.obs$formula
#> [1] "$CL_{\\text{obs}} = \\frac{Dose}{AUC_{\\infty,\\text{obs}}}$"
#> 
#> $cl.obs$formula_note
#> NULL
#> 
#> $cl.obs$tier
#> [1] "common"
#> 
#> $cl.obs$selection
#> list()
#> 
#> 
#> $cl.pred
#> $cl.pred$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.pred$values
#> [1] FALSE  TRUE
#> 
#> $cl.pred$unit_type
#> [1] "clearance"
#> 
#> $cl.pred$pretty_name
#> [1] "CL (based on AUCinf,pred)"
#> 
#> $cl.pred$desc
#> [1] "Clearance, predicted Clast"
#> 
#> $cl.pred$sparse
#> [1] FALSE
#> 
#> $cl.pred$formalsmap
#> $cl.pred$formalsmap$auc
#> [1] "aucinf.pred"
#> 
#> 
#> $cl.pred$depends
#> [1] "aucinf.pred"
#> 
#> $cl.pred$datatype
#> [1] "interval"
#> 
#> $cl.pred$pptestcd_cdisc
#> $cl.pred$pptestcd_cdisc$route
#> $cl.pred$pptestcd_cdisc$route$extravascular
#> [1] "CLF/FP"
#> 
#> $cl.pred$pptestcd_cdisc$route$intravascular
#> [1] "CLP"
#> 
#> 
#> 
#> $cl.pred$pptest_cdisc
#> $cl.pred$pptest_cdisc$route
#> $cl.pred$pptest_cdisc$route$extravascular
#> [1] "Total CL Pred by F"
#> 
#> $cl.pred$pptest_cdisc$route$intravascular
#> [1] "Total CL Pred"
#> 
#> 
#> 
#> $cl.pred$formula
#> [1] "$CL_{\\text{pred}} = \\frac{Dose}{AUC_{\\infty,\\text{pred}}}$"
#> 
#> $cl.pred$formula_note
#> NULL
#> 
#> $cl.pred$tier
#> [1] "uncommon"
#> 
#> $cl.pred$selection
#> list()
#> 
#> 
#> $cl.int.inf.obs
#> $cl.int.inf.obs$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.int.inf.obs$values
#> [1] FALSE  TRUE
#> 
#> $cl.int.inf.obs$unit_type
#> [1] "clearance"
#> 
#> $cl.int.inf.obs$pretty_name
#> [1] "CL (based on AUCint.inf.obs)"
#> 
#> $cl.int.inf.obs$desc
#> [1] "Clearance, AUCint.inf.obs"
#> 
#> $cl.int.inf.obs$sparse
#> [1] FALSE
#> 
#> $cl.int.inf.obs$formalsmap
#> $cl.int.inf.obs$formalsmap$auc
#> [1] "aucint.inf.obs"
#> 
#> 
#> $cl.int.inf.obs$depends
#> [1] "aucint.inf.obs"
#> 
#> $cl.int.inf.obs$datatype
#> [1] "interval"
#> 
#> $cl.int.inf.obs$pptestcd_cdisc
#> [1] "cl.int.inf.obs"
#> 
#> $cl.int.inf.obs$pptest_cdisc
#> [1] "Clearance, AUCint.inf.obs"
#> 
#> $cl.int.inf.obs$formula
#> [1] "$CL_{\\text{int,}\\infty\\text{,obs}} = \\frac{Dose}{AUC_{\\text{int,}\\infty\\text{,obs}}}$"
#> 
#> $cl.int.inf.obs$formula_note
#> NULL
#> 
#> $cl.int.inf.obs$tier
#> [1] "common"
#> 
#> $cl.int.inf.obs$selection
#> list()
#> 
#> 
#> $cl.int.inf.pred
#> $cl.int.inf.pred$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.int.inf.pred$values
#> [1] FALSE  TRUE
#> 
#> $cl.int.inf.pred$unit_type
#> [1] "clearance"
#> 
#> $cl.int.inf.pred$pretty_name
#> [1] "CL (based on AUCint.inf.pred)"
#> 
#> $cl.int.inf.pred$desc
#> [1] "Clearance, AUCint.inf.pred"
#> 
#> $cl.int.inf.pred$sparse
#> [1] FALSE
#> 
#> $cl.int.inf.pred$formalsmap
#> $cl.int.inf.pred$formalsmap$auc
#> [1] "aucint.inf.pred"
#> 
#> 
#> $cl.int.inf.pred$depends
#> [1] "aucint.inf.pred"
#> 
#> $cl.int.inf.pred$datatype
#> [1] "interval"
#> 
#> $cl.int.inf.pred$pptestcd_cdisc
#> [1] "cl.int.inf.pred"
#> 
#> $cl.int.inf.pred$pptest_cdisc
#> [1] "Clearance, AUCint.inf.pred"
#> 
#> $cl.int.inf.pred$formula
#> [1] "$CL_{\\text{int,}\\infty\\text{,pred}} = \\frac{Dose}{AUC_{\\text{int,}\\infty\\text{,pred}}}$"
#> 
#> $cl.int.inf.pred$formula_note
#> NULL
#> 
#> $cl.int.inf.pred$tier
#> [1] "uncommon"
#> 
#> $cl.int.inf.pred$selection
#> list()
#> 
#> 
#> $cl.iv.obs
#> $cl.iv.obs$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.iv.obs$values
#> [1] FALSE  TRUE
#> 
#> $cl.iv.obs$unit_type
#> [1] "clearance"
#> 
#> $cl.iv.obs$pretty_name
#> [1] "CL (for IV dosing,  based on AUCinf,obs)"
#> 
#> $cl.iv.obs$desc
#> [1] "IV clearance, AUCinf.obs"
#> 
#> $cl.iv.obs$sparse
#> [1] FALSE
#> 
#> $cl.iv.obs$formalsmap
#> $cl.iv.obs$formalsmap$auc
#> [1] "aucivinf.obs"
#> 
#> 
#> $cl.iv.obs$depends
#> [1] "aucivinf.obs"
#> 
#> $cl.iv.obs$datatype
#> [1] "interval"
#> 
#> $cl.iv.obs$pptestcd_cdisc
#> [1] "cl.iv.obs"
#> 
#> $cl.iv.obs$pptest_cdisc
#> [1] "IV clearance, AUCinf.obs"
#> 
#> $cl.iv.obs$formula
#> [1] "$CL_{\\text{iv,obs}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,}\\infty\\text{,obs}}}$"
#> 
#> $cl.iv.obs$formula_note
#> NULL
#> 
#> $cl.iv.obs$tier
#> [1] "uncommon"
#> 
#> $cl.iv.obs$selection
#> list()
#> 
#> 
#> $cl.iv.pred
#> $cl.iv.pred$FUN
#> [1] "pk.calc.cl"
#> 
#> $cl.iv.pred$values
#> [1] FALSE  TRUE
#> 
#> $cl.iv.pred$unit_type
#> [1] "clearance"
#> 
#> $cl.iv.pred$pretty_name
#> [1] "CL (for IV dosing,  based on AUCinf,pred)"
#> 
#> $cl.iv.pred$desc
#> [1] "IV clearance, AUCinf.pred"
#> 
#> $cl.iv.pred$sparse
#> [1] FALSE
#> 
#> $cl.iv.pred$formalsmap
#> $cl.iv.pred$formalsmap$auc
#> [1] "aucivinf.pred"
#> 
#> 
#> $cl.iv.pred$depends
#> [1] "aucivinf.pred"
#> 
#> $cl.iv.pred$datatype
#> [1] "interval"
#> 
#> $cl.iv.pred$pptestcd_cdisc
#> [1] "cl.iv.pred"
#> 
#> $cl.iv.pred$pptest_cdisc
#> [1] "IV clearance, AUCinf.pred"
#> 
#> $cl.iv.pred$formula
#> [1] "$CL_{\\text{iv,pred}} = \\frac{Dose_{\\text{iv}}}{AUC_{\\text{iv,}\\infty\\text{,pred}}}$"
#> 
#> $cl.iv.pred$formula_note
#> NULL
#> 
#> $cl.iv.pred$tier
#> [1] "uncommon"
#> 
#> $cl.iv.pred$selection
#> list()
#> 
#> 
#> $mrt.obs
#> $mrt.obs$FUN
#> [1] "pk.calc.mrt"
#> 
#> $mrt.obs$values
#> [1] FALSE  TRUE
#> 
#> $mrt.obs$unit_type
#> [1] "time"
#> 
#> $mrt.obs$pretty_name
#> [1] "MRT (based on AUCinf,obs)"
#> 
#> $mrt.obs$desc
#> [1] "MRT to inf, observed Clast"
#> 
#> $mrt.obs$sparse
#> [1] FALSE
#> 
#> $mrt.obs$formalsmap
#> $mrt.obs$formalsmap$auc
#> [1] "aucinf.obs"
#> 
#> $mrt.obs$formalsmap$aumc
#> [1] "aumcinf.obs"
#> 
#> 
#> $mrt.obs$depends
#> [1] "aucinf.obs"  "aumcinf.obs"
#> 
#> $mrt.obs$datatype
#> [1] "interval"
#> 
#> $mrt.obs$pptestcd_cdisc
#> $mrt.obs$pptestcd_cdisc$route
#> $mrt.obs$pptestcd_cdisc$route$extravascular
#> [1] "MRTEVFO"
#> 
#> $mrt.obs$pptestcd_cdisc$route$intravascular
#> [1] "MRTICFO"
#> 
#> 
#> 
#> $mrt.obs$pptest_cdisc
#> $mrt.obs$pptest_cdisc$route
#> $mrt.obs$pptest_cdisc$route$extravascular
#> [1] "MRT Extravasc Infinity Obs"
#> 
#> $mrt.obs$pptest_cdisc$route$intravascular
#> [1] "MRT IV Cont Inf Infinity Obs"
#> 
#> 
#> 
#> $mrt.obs$formula
#> [1] "$MRT_{\\text{obs}} = \\frac{AUMC_{\\infty,\\text{obs}}}{AUC_{\\infty,\\text{obs}}}$"
#> 
#> $mrt.obs$formula_note
#> NULL
#> 
#> $mrt.obs$tier
#> [1] "uncommon"
#> 
#> $mrt.obs$selection
#> list()
#> 
#> 
#> $mrt.pred
#> $mrt.pred$FUN
#> [1] "pk.calc.mrt"
#> 
#> $mrt.pred$values
#> [1] FALSE  TRUE
#> 
#> $mrt.pred$unit_type
#> [1] "time"
#> 
#> $mrt.pred$pretty_name
#> [1] "MRT (based on AUCinf,pred)"
#> 
#> $mrt.pred$desc
#> [1] "MRT to inf, predicted Clast"
#> 
#> $mrt.pred$sparse
#> [1] FALSE
#> 
#> $mrt.pred$formalsmap
#> $mrt.pred$formalsmap$auc
#> [1] "aucinf.pred"
#> 
#> $mrt.pred$formalsmap$aumc
#> [1] "aumcinf.pred"
#> 
#> 
#> $mrt.pred$depends
#> [1] "aucinf.pred"  "aumcinf.pred"
#> 
#> $mrt.pred$datatype
#> [1] "interval"
#> 
#> $mrt.pred$pptestcd_cdisc
#> $mrt.pred$pptestcd_cdisc$route
#> $mrt.pred$pptestcd_cdisc$route$extravascular
#> [1] "MRTEVFP"
#> 
#> $mrt.pred$pptestcd_cdisc$route$intravascular
#> [1] "MRTICFP"
#> 
#> 
#> 
#> $mrt.pred$pptest_cdisc
#> $mrt.pred$pptest_cdisc$route
#> $mrt.pred$pptest_cdisc$route$extravascular
#> [1] "MRT Extravasc Infinity Pred"
#> 
#> $mrt.pred$pptest_cdisc$route$intravascular
#> [1] "MRT IV Cont Inf Infinity Pred"
#> 
#> 
#> 
#> $mrt.pred$formula
#> [1] "$MRT_{\\text{pred}} = \\frac{AUMC_{\\infty,\\text{pred}}}{AUC_{\\infty,\\text{pred}}}$"
#> 
#> $mrt.pred$formula_note
#> NULL
#> 
#> $mrt.pred$tier
#> [1] "uncommon"
#> 
#> $mrt.pred$selection
#> list()
#> 
#> 
#> $mrt.int.inf.obs
#> $mrt.int.inf.obs$FUN
#> [1] "pk.calc.mrt"
#> 
#> $mrt.int.inf.obs$values
#> [1] FALSE  TRUE
#> 
#> $mrt.int.inf.obs$unit_type
#> [1] "time"
#> 
#> $mrt.int.inf.obs$pretty_name
#> [1] "MRT (based on AUCint.inf.obs)"
#> 
#> $mrt.int.inf.obs$desc
#> [1] "MRT, interval AUC/AUMCinf obs"
#> 
#> $mrt.int.inf.obs$sparse
#> [1] FALSE
#> 
#> $mrt.int.inf.obs$formalsmap
#> $mrt.int.inf.obs$formalsmap$auc
#> [1] "aucint.inf.obs"
#> 
#> $mrt.int.inf.obs$formalsmap$aumc
#> [1] "aumcint.inf.obs"
#> 
#> 
#> $mrt.int.inf.obs$depends
#> [1] "aucint.inf.obs"  "aumcint.inf.obs"
#> 
#> $mrt.int.inf.obs$datatype
#> [1] "interval"
#> 
#> $mrt.int.inf.obs$pptestcd_cdisc
#> [1] "mrt.int.inf.obs"
#> 
#> $mrt.int.inf.obs$pptest_cdisc
#> [1] "MRT, interval AUC/AUMCinf obs"
#> 
#> $mrt.int.inf.obs$formula
#> [1] "$MRT_{\\text{int,}\\infty\\text{,obs}} = \\frac{AUMC_{\\text{int,}\\infty\\text{,obs}}}{AUC_{\\text{int,}\\infty\\text{,obs}}}$"
#> 
#> $mrt.int.inf.obs$formula_note
#> NULL
#> 
#> $mrt.int.inf.obs$tier
#> [1] "uncommon"
#> 
#> $mrt.int.inf.obs$selection
#> list()
#> 
#> 
#> $mrt.int.inf.pred
#> $mrt.int.inf.pred$FUN
#> [1] "pk.calc.mrt"
#> 
#> $mrt.int.inf.pred$values
#> [1] FALSE  TRUE
#> 
#> $mrt.int.inf.pred$unit_type
#> [1] "time"
#> 
#> $mrt.int.inf.pred$pretty_name
#> [1] "MRT (based on AUCint.inf.pred)"
#> 
#> $mrt.int.inf.pred$desc
#> [1] "MRT, interval AUC/AUMCinf pred"
#> 
#> $mrt.int.inf.pred$sparse
#> [1] FALSE
#> 
#> $mrt.int.inf.pred$formalsmap
#> $mrt.int.inf.pred$formalsmap$auc
#> [1] "aucint.inf.pred"
#> 
#> $mrt.int.inf.pred$formalsmap$aumc
#> [1] "aumcint.inf.pred"
#> 
#> 
#> $mrt.int.inf.pred$depends
#> [1] "aucint.inf.pred"  "aumcint.inf.pred"
#> 
#> $mrt.int.inf.pred$datatype
#> [1] "interval"
#> 
#> $mrt.int.inf.pred$pptestcd_cdisc
#> [1] "mrt.int.inf.pred"
#> 
#> $mrt.int.inf.pred$pptest_cdisc
#> [1] "MRT, interval AUC/AUMCinf pred"
#> 
#> $mrt.int.inf.pred$formula
#> [1] "$MRT_{\\text{int,}\\infty\\text{,pred}} = \\frac{AUMC_{\\text{int,}\\infty\\text{,pred}}}{AUC_{\\text{int,}\\infty\\text{,pred}}}$"
#> 
#> $mrt.int.inf.pred$formula_note
#> NULL
#> 
#> $mrt.int.inf.pred$tier
#> [1] "uncommon"
#> 
#> $mrt.int.inf.pred$selection
#> list()
#> 
#> 
#> $mrt.iv.obs
#> $mrt.iv.obs$FUN
#> [1] "pk.calc.mrt.iv"
#> 
#> $mrt.iv.obs$values
#> [1] FALSE  TRUE
#> 
#> $mrt.iv.obs$unit_type
#> [1] "time"
#> 
#> $mrt.iv.obs$pretty_name
#> [1] "MRT (for IV dosing, based on AUCinf,obs)"
#> 
#> $mrt.iv.obs$desc
#> [1] "IV MRT, AUCinf.obs/AUMCinf.obs"
#> 
#> $mrt.iv.obs$sparse
#> [1] FALSE
#> 
#> $mrt.iv.obs$formalsmap
#> $mrt.iv.obs$formalsmap$auc
#> [1] "aucinf.obs"
#> 
#> $mrt.iv.obs$formalsmap$aumc
#> [1] "aumcinf.obs"
#> 
#> 
#> $mrt.iv.obs$depends
#> [1] "aucinf.obs"  "aumcinf.obs"
#> 
#> $mrt.iv.obs$datatype
#> [1] "interval"
#> 
#> $mrt.iv.obs$pptestcd_cdisc
#> [1] "MRTIBIFO"
#> 
#> $mrt.iv.obs$pptest_cdisc
#> [1] "MRT Intravasc Infinity Obs"
#> 
#> $mrt.iv.obs$formula
#> [1] "$MRT_{\\text{iv,obs}} = \\frac{AUMC_{\\infty,\\text{obs}}}{AUC_{\\infty,\\text{obs}}} - \\frac{T_{\\text{inf}}}{2}$"
#> 
#> $mrt.iv.obs$formula_note
#> NULL
#> 
#> $mrt.iv.obs$tier
#> [1] "uncommon"
#> 
#> $mrt.iv.obs$selection
#> list()
#> 
#> 
#> $mrt.iv.pred
#> $mrt.iv.pred$FUN
#> [1] "pk.calc.mrt.iv"
#> 
#> $mrt.iv.pred$values
#> [1] FALSE  TRUE
#> 
#> $mrt.iv.pred$unit_type
#> [1] "time"
#> 
#> $mrt.iv.pred$pretty_name
#> [1] "MRT (for IV dosing, based on AUCinf,pred)"
#> 
#> $mrt.iv.pred$desc
#> [1] "IV MRT, AUCinf.pred/AUMCinf.pred"
#> 
#> $mrt.iv.pred$sparse
#> [1] FALSE
#> 
#> $mrt.iv.pred$formalsmap
#> $mrt.iv.pred$formalsmap$auc
#> [1] "aucinf.pred"
#> 
#> $mrt.iv.pred$formalsmap$aumc
#> [1] "aumcinf.pred"
#> 
#> 
#> $mrt.iv.pred$depends
#> [1] "aucinf.pred"  "aumcinf.pred"
#> 
#> $mrt.iv.pred$datatype
#> [1] "interval"
#> 
#> $mrt.iv.pred$pptestcd_cdisc
#> [1] "MRTIBIFP"
#> 
#> $mrt.iv.pred$pptest_cdisc
#> [1] "MRT Intravasc Infinity Pred"
#> 
#> $mrt.iv.pred$formula
#> [1] "$MRT_{\\text{iv,pred}} = \\frac{AUMC_{\\infty,\\text{pred}}}{AUC_{\\infty,\\text{pred}}} - \\frac{T_{\\text{inf}}}{2}$"
#> 
#> $mrt.iv.pred$formula_note
#> NULL
#> 
#> $mrt.iv.pred$tier
#> [1] "uncommon"
#> 
#> $mrt.iv.pred$selection
#> list()
#> 
#> 
#> $mrt.md.obs
#> $mrt.md.obs$FUN
#> [1] "pk.calc.mrt.md"
#> 
#> $mrt.md.obs$values
#> [1] FALSE  TRUE
#> 
#> $mrt.md.obs$unit_type
#> [1] "time"
#> 
#> $mrt.md.obs$pretty_name
#> [1] "MRT (for multiple dosing, based on AUCinf,obs)"
#> 
#> $mrt.md.obs$desc
#> [1] "MRT, multi-dose AUCinf.obs/AUMCinf.obs"
#> 
#> $mrt.md.obs$sparse
#> [1] FALSE
#> 
#> $mrt.md.obs$formalsmap
#> $mrt.md.obs$formalsmap$auctau
#> [1] "auclast"
#> 
#> $mrt.md.obs$formalsmap$aumctau
#> [1] "aumclast"
#> 
#> $mrt.md.obs$formalsmap$aucinf
#> [1] "aucinf.obs"
#> 
#> 
#> $mrt.md.obs$depends
#> [1] "auclast"    "aumclast"   "aucinf.obs"
#> 
#> $mrt.md.obs$datatype
#> [1] "interval"
#> 
#> $mrt.md.obs$pptestcd_cdisc
#> [1] "MRTMDO"
#> 
#> $mrt.md.obs$pptest_cdisc
#> [1] "MRT (for multiple dosing, based on AUCinf,obs)"
#> 
#> $mrt.md.obs$formula
#> [1] "$MRT_{\\text{md,obs}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{obs}} - AUC_{\\text{last}}}{AUC_{\\text{last}}}$"
#> 
#> $mrt.md.obs$formula_note
#> NULL
#> 
#> $mrt.md.obs$tier
#> [1] "uncommon"
#> 
#> $mrt.md.obs$selection
#> $mrt.md.obs$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $mrt.md.pred
#> $mrt.md.pred$FUN
#> [1] "pk.calc.mrt.md"
#> 
#> $mrt.md.pred$values
#> [1] FALSE  TRUE
#> 
#> $mrt.md.pred$unit_type
#> [1] "time"
#> 
#> $mrt.md.pred$pretty_name
#> [1] "MRT (for multiple dosing, based on AUCinf,pred)"
#> 
#> $mrt.md.pred$desc
#> [1] "MRT, multi-dose AUCinf.pred/AUMCinf.pred"
#> 
#> $mrt.md.pred$sparse
#> [1] FALSE
#> 
#> $mrt.md.pred$formalsmap
#> $mrt.md.pred$formalsmap$auctau
#> [1] "auclast"
#> 
#> $mrt.md.pred$formalsmap$aumctau
#> [1] "aumclast"
#> 
#> $mrt.md.pred$formalsmap$aucinf
#> [1] "aucinf.pred"
#> 
#> 
#> $mrt.md.pred$depends
#> [1] "auclast"     "aumclast"    "aucinf.pred"
#> 
#> $mrt.md.pred$datatype
#> [1] "interval"
#> 
#> $mrt.md.pred$pptestcd_cdisc
#> [1] "MRTMDP"
#> 
#> $mrt.md.pred$pptest_cdisc
#> [1] "MRT (for multiple dosing, based on AUCinf,pred)"
#> 
#> $mrt.md.pred$formula
#> [1] "$MRT_{\\text{md,pred}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{pred}} - AUC_{\\text{last}}}{AUC_{\\text{last}}}$"
#> 
#> $mrt.md.pred$formula_note
#> NULL
#> 
#> $mrt.md.pred$tier
#> [1] "uncommon"
#> 
#> $mrt.md.pred$selection
#> $mrt.md.pred$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $mrt.ivmd.obs
#> $mrt.ivmd.obs$FUN
#> [1] "pk.calc.mrt.md.iv"
#> 
#> $mrt.ivmd.obs$values
#> [1] FALSE  TRUE
#> 
#> $mrt.ivmd.obs$unit_type
#> [1] "time"
#> 
#> $mrt.ivmd.obs$pretty_name
#> [1] "MRT (for multiple dosing of an IV infusion, based on AUCinf,obs)"
#> 
#> $mrt.ivmd.obs$desc
#> [1] "IV MRT, multi-dose, AUCinf.obs"
#> 
#> $mrt.ivmd.obs$sparse
#> [1] FALSE
#> 
#> $mrt.ivmd.obs$formalsmap
#> $mrt.ivmd.obs$formalsmap$auctau
#> [1] "auclast"
#> 
#> $mrt.ivmd.obs$formalsmap$aumctau
#> [1] "aumclast"
#> 
#> $mrt.ivmd.obs$formalsmap$aucinf
#> [1] "aucinf.obs"
#> 
#> 
#> $mrt.ivmd.obs$depends
#> [1] "auclast"    "aumclast"   "aucinf.obs"
#> 
#> $mrt.ivmd.obs$datatype
#> [1] "interval"
#> 
#> $mrt.ivmd.obs$pptestcd_cdisc
#> [1] "mrt.ivmd.obs"
#> 
#> $mrt.ivmd.obs$pptest_cdisc
#> [1] "IV MRT, multi-dose, AUCinf.obs"
#> 
#> $mrt.ivmd.obs$formula
#> [1] "$MRT_{\\text{ivmd,obs}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{obs}} - AUC_{\\text{last}}}{AUC_{\\text{last}}} - \\frac{T_{\\text{inf}}}{2}$"
#> 
#> $mrt.ivmd.obs$formula_note
#> NULL
#> 
#> $mrt.ivmd.obs$tier
#> [1] "uncommon"
#> 
#> $mrt.ivmd.obs$selection
#> $mrt.ivmd.obs$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $mrt.ivmd.pred
#> $mrt.ivmd.pred$FUN
#> [1] "pk.calc.mrt.md.iv"
#> 
#> $mrt.ivmd.pred$values
#> [1] FALSE  TRUE
#> 
#> $mrt.ivmd.pred$unit_type
#> [1] "time"
#> 
#> $mrt.ivmd.pred$pretty_name
#> [1] "MRT (for multiple dosing of an IV infusion, based on AUCinf,pred)"
#> 
#> $mrt.ivmd.pred$desc
#> [1] "IV MRT, multi-dose, AUCinf.pred"
#> 
#> $mrt.ivmd.pred$sparse
#> [1] FALSE
#> 
#> $mrt.ivmd.pred$formalsmap
#> $mrt.ivmd.pred$formalsmap$auctau
#> [1] "auclast"
#> 
#> $mrt.ivmd.pred$formalsmap$aumctau
#> [1] "aumclast"
#> 
#> $mrt.ivmd.pred$formalsmap$aucinf
#> [1] "aucinf.pred"
#> 
#> 
#> $mrt.ivmd.pred$depends
#> [1] "auclast"     "aumclast"    "aucinf.pred"
#> 
#> $mrt.ivmd.pred$datatype
#> [1] "interval"
#> 
#> $mrt.ivmd.pred$pptestcd_cdisc
#> [1] "mrt.ivmd.pred"
#> 
#> $mrt.ivmd.pred$pptest_cdisc
#> [1] "IV MRT, multi-dose, AUCinf.pred"
#> 
#> $mrt.ivmd.pred$formula
#> [1] "$MRT_{\\text{ivmd,pred}} = \\frac{AUMC_{\\text{last}}}{AUC_{\\text{last}}} + \\tau \\cdot \\frac{AUC_{\\infty,\\text{pred}} - AUC_{\\text{last}}}{AUC_{\\text{last}}} - \\frac{T_{\\text{inf}}}{2}$"
#> 
#> $mrt.ivmd.pred$formula_note
#> NULL
#> 
#> $mrt.ivmd.pred$tier
#> [1] "uncommon"
#> 
#> $mrt.ivmd.pred$selection
#> $mrt.ivmd.pred$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $vz.obs
#> $vz.obs$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.obs$values
#> [1] FALSE  TRUE
#> 
#> $vz.obs$unit_type
#> [1] "volume"
#> 
#> $vz.obs$pretty_name
#> [1] "Vz (based on AUCinf,obs)"
#> 
#> $vz.obs$desc
#> [1] "Vz, observed Clast"
#> 
#> $vz.obs$sparse
#> [1] FALSE
#> 
#> $vz.obs$formalsmap
#> $vz.obs$formalsmap$cl
#> [1] "cl.obs"
#> 
#> 
#> $vz.obs$depends
#> [1] "cl.obs"   "lambda.z"
#> 
#> $vz.obs$datatype
#> [1] "interval"
#> 
#> $vz.obs$pptestcd_cdisc
#> $vz.obs$pptestcd_cdisc$route
#> $vz.obs$pptestcd_cdisc$route$extravascular
#> [1] "VZF/FO"
#> 
#> $vz.obs$pptestcd_cdisc$route$intravascular
#> [1] "VZO"
#> 
#> 
#> 
#> $vz.obs$pptest_cdisc
#> $vz.obs$pptest_cdisc$route
#> $vz.obs$pptest_cdisc$route$extravascular
#> [1] "Vz by F Obs"
#> 
#> $vz.obs$pptest_cdisc$route$intravascular
#> [1] "Vz Obs"
#> 
#> 
#> 
#> $vz.obs$formula
#> [1] "$V_{z,\\text{obs}} = \\frac{CL_{\\text{obs}}}{\\lambda_z}$"
#> 
#> $vz.obs$formula_note
#> NULL
#> 
#> $vz.obs$tier
#> [1] "uncommon"
#> 
#> $vz.obs$selection
#> list()
#> 
#> 
#> $vz.pred
#> $vz.pred$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.pred$values
#> [1] FALSE  TRUE
#> 
#> $vz.pred$unit_type
#> [1] "volume"
#> 
#> $vz.pred$pretty_name
#> [1] "Vz (based on AUCinf,pred)"
#> 
#> $vz.pred$desc
#> [1] "Vz, predicted Clast"
#> 
#> $vz.pred$sparse
#> [1] FALSE
#> 
#> $vz.pred$formalsmap
#> $vz.pred$formalsmap$cl
#> [1] "cl.pred"
#> 
#> 
#> $vz.pred$depends
#> [1] "cl.pred"  "lambda.z"
#> 
#> $vz.pred$datatype
#> [1] "interval"
#> 
#> $vz.pred$pptestcd_cdisc
#> $vz.pred$pptestcd_cdisc$route
#> $vz.pred$pptestcd_cdisc$route$extravascular
#> [1] "VZF/FP"
#> 
#> $vz.pred$pptestcd_cdisc$route$intravascular
#> [1] "VZP"
#> 
#> 
#> 
#> $vz.pred$pptest_cdisc
#> $vz.pred$pptest_cdisc$route
#> $vz.pred$pptest_cdisc$route$extravascular
#> [1] "Vz by F Pred"
#> 
#> $vz.pred$pptest_cdisc$route$intravascular
#> [1] "Vz Pred"
#> 
#> 
#> 
#> $vz.pred$formula
#> [1] "$V_{z,\\text{pred}} = \\frac{CL_{\\text{pred}}}{\\lambda_z}$"
#> 
#> $vz.pred$formula_note
#> NULL
#> 
#> $vz.pred$tier
#> [1] "uncommon"
#> 
#> $vz.pred$selection
#> list()
#> 
#> 
#> $vz.int.inf.obs
#> $vz.int.inf.obs$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.int.inf.obs$values
#> [1] FALSE  TRUE
#> 
#> $vz.int.inf.obs$unit_type
#> [1] "volume"
#> 
#> $vz.int.inf.obs$pretty_name
#> [1] "Vz (based on AUCint.inf.obs)"
#> 
#> $vz.int.inf.obs$desc
#> [1] "Vz, interval AUCint.inf.obs"
#> 
#> $vz.int.inf.obs$sparse
#> [1] FALSE
#> 
#> $vz.int.inf.obs$formalsmap
#> $vz.int.inf.obs$formalsmap$cl
#> [1] "cl.int.inf.obs"
#> 
#> 
#> $vz.int.inf.obs$depends
#> [1] "cl.int.inf.obs" "lambda.z"      
#> 
#> $vz.int.inf.obs$datatype
#> [1] "interval"
#> 
#> $vz.int.inf.obs$pptestcd_cdisc
#> [1] "vz.int.inf.obs"
#> 
#> $vz.int.inf.obs$pptest_cdisc
#> [1] "Vz, interval AUCint.inf.obs"
#> 
#> $vz.int.inf.obs$formula
#> [1] "$V_{z,\\text{int,}\\infty\\text{,obs}} = \\frac{CL_{\\text{int,}\\infty\\text{,obs}}}{\\lambda_z}$"
#> 
#> $vz.int.inf.obs$formula_note
#> NULL
#> 
#> $vz.int.inf.obs$tier
#> [1] "uncommon"
#> 
#> $vz.int.inf.obs$selection
#> list()
#> 
#> 
#> $vz.int.inf.pred
#> $vz.int.inf.pred$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.int.inf.pred$values
#> [1] FALSE  TRUE
#> 
#> $vz.int.inf.pred$unit_type
#> [1] "volume"
#> 
#> $vz.int.inf.pred$pretty_name
#> [1] "Vz (based on AUCint.inf.pred)"
#> 
#> $vz.int.inf.pred$desc
#> [1] "Vz, interval AUCint.inf.pred"
#> 
#> $vz.int.inf.pred$sparse
#> [1] FALSE
#> 
#> $vz.int.inf.pred$formalsmap
#> $vz.int.inf.pred$formalsmap$cl
#> [1] "cl.int.inf.pred"
#> 
#> 
#> $vz.int.inf.pred$depends
#> [1] "cl.int.inf.pred" "lambda.z"       
#> 
#> $vz.int.inf.pred$datatype
#> [1] "interval"
#> 
#> $vz.int.inf.pred$pptestcd_cdisc
#> [1] "vz.int.inf.pred"
#> 
#> $vz.int.inf.pred$pptest_cdisc
#> [1] "Vz, interval AUCint.inf.pred"
#> 
#> $vz.int.inf.pred$formula
#> [1] "$V_{z,\\text{int,}\\infty\\text{,pred}} = \\frac{CL_{\\text{int,}\\infty\\text{,pred}}}{\\lambda_z}$"
#> 
#> $vz.int.inf.pred$formula_note
#> NULL
#> 
#> $vz.int.inf.pred$tier
#> [1] "uncommon"
#> 
#> $vz.int.inf.pred$selection
#> list()
#> 
#> 
#> $vz.iv.obs
#> $vz.iv.obs$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.iv.obs$values
#> [1] FALSE  TRUE
#> 
#> $vz.iv.obs$unit_type
#> [1] "volume"
#> 
#> $vz.iv.obs$pretty_name
#> [1] "Vz (for IV dosing,  based on AUCinf,obs)"
#> 
#> $vz.iv.obs$desc
#> [1] "IV Vz, observed AUCinf"
#> 
#> $vz.iv.obs$sparse
#> [1] FALSE
#> 
#> $vz.iv.obs$formalsmap
#> $vz.iv.obs$formalsmap$cl
#> [1] "cl.iv.obs"
#> 
#> 
#> $vz.iv.obs$depends
#> [1] "cl.iv.obs" "lambda.z" 
#> 
#> $vz.iv.obs$datatype
#> [1] "interval"
#> 
#> $vz.iv.obs$pptestcd_cdisc
#> [1] "vz.iv.obs"
#> 
#> $vz.iv.obs$pptest_cdisc
#> [1] "IV Vz, observed AUCinf"
#> 
#> $vz.iv.obs$formula
#> [1] "$V_{z,\\text{iv,obs}} = \\frac{CL_{\\text{iv,obs}}}{\\lambda_z}$"
#> 
#> $vz.iv.obs$formula_note
#> NULL
#> 
#> $vz.iv.obs$tier
#> [1] "uncommon"
#> 
#> $vz.iv.obs$selection
#> list()
#> 
#> 
#> $vz.iv.pred
#> $vz.iv.pred$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.iv.pred$values
#> [1] FALSE  TRUE
#> 
#> $vz.iv.pred$unit_type
#> [1] "volume"
#> 
#> $vz.iv.pred$pretty_name
#> [1] "Vz (for IV dosing,  based on AUCinf,pred)"
#> 
#> $vz.iv.pred$desc
#> [1] "IV Vz, predicted AUCinf"
#> 
#> $vz.iv.pred$sparse
#> [1] FALSE
#> 
#> $vz.iv.pred$formalsmap
#> $vz.iv.pred$formalsmap$cl
#> [1] "cl.iv.pred"
#> 
#> 
#> $vz.iv.pred$depends
#> [1] "cl.iv.pred" "lambda.z"  
#> 
#> $vz.iv.pred$datatype
#> [1] "interval"
#> 
#> $vz.iv.pred$pptestcd_cdisc
#> [1] "vz.iv.pred"
#> 
#> $vz.iv.pred$pptest_cdisc
#> [1] "IV Vz, predicted AUCinf"
#> 
#> $vz.iv.pred$formula
#> [1] "$V_{z,\\text{iv,pred}} = \\frac{CL_{\\text{iv,pred}}}{\\lambda_z}$"
#> 
#> $vz.iv.pred$formula_note
#> NULL
#> 
#> $vz.iv.pred$tier
#> [1] "uncommon"
#> 
#> $vz.iv.pred$selection
#> list()
#> 
#> 
#> $vz.sparse.last
#> $vz.sparse.last$FUN
#> [1] "pk.calc.vz"
#> 
#> $vz.sparse.last$values
#> [1] FALSE  TRUE
#> 
#> $vz.sparse.last$unit_type
#> [1] "volume"
#> 
#> $vz.sparse.last$pretty_name
#> [1] "Vz (for sparse data, based on AUClast)"
#> 
#> $vz.sparse.last$desc
#> [1] "Vz from sparse sampling"
#> 
#> $vz.sparse.last$sparse
#> [1] TRUE
#> 
#> $vz.sparse.last$formalsmap
#> $vz.sparse.last$formalsmap$cl
#> [1] "cl.sparse.last"
#> 
#> $vz.sparse.last$formalsmap$lambda.z
#> [1] "kel.sparse.last"
#> 
#> 
#> $vz.sparse.last$depends
#> [1] "cl.sparse.last"  "kel.sparse.last"
#> 
#> $vz.sparse.last$datatype
#> [1] "interval"
#> 
#> $vz.sparse.last$pptestcd_cdisc
#> [1] "vz.sparse.last"
#> 
#> $vz.sparse.last$pptest_cdisc
#> [1] "Vz from sparse sampling"
#> 
#> $vz.sparse.last$formula
#> [1] "$V_{z,\\text{sparse,last}} = \\frac{CL_{\\text{sparse,last}}}{\\lambda_z}$"
#> 
#> $vz.sparse.last$formula_note
#> NULL
#> 
#> $vz.sparse.last$tier
#> [1] "uncommon"
#> 
#> $vz.sparse.last$selection
#> list()
#> 
#> 
#> $vss.obs
#> $vss.obs$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.obs$values
#> [1] FALSE  TRUE
#> 
#> $vss.obs$unit_type
#> [1] "volume"
#> 
#> $vss.obs$pretty_name
#> [1] "Vss (based on AUCinf,obs)"
#> 
#> $vss.obs$desc
#> [1] "Vss, observed Clast"
#> 
#> $vss.obs$sparse
#> [1] FALSE
#> 
#> $vss.obs$formalsmap
#> $vss.obs$formalsmap$cl
#> [1] "cl.obs"
#> 
#> $vss.obs$formalsmap$mrt
#> [1] "mrt.obs"
#> 
#> 
#> $vss.obs$depends
#> [1] "cl.obs"  "mrt.obs"
#> 
#> $vss.obs$datatype
#> [1] "interval"
#> 
#> $vss.obs$pptestcd_cdisc
#> $vss.obs$pptestcd_cdisc$route
#> $vss.obs$pptestcd_cdisc$route$extravascular
#> [1] "VSSF/FO"
#> 
#> $vss.obs$pptestcd_cdisc$route$intravascular
#> [1] "VSSO"
#> 
#> 
#> 
#> $vss.obs$pptest_cdisc
#> $vss.obs$pptest_cdisc$route
#> $vss.obs$pptest_cdisc$route$extravascular
#> [1] "Vss by F Obs"
#> 
#> $vss.obs$pptest_cdisc$route$intravascular
#> [1] "Vol Dist Steady State Obs"
#> 
#> 
#> 
#> $vss.obs$formula
#> [1] "$V_{ss,\\text{obs}} = CL_{\\text{obs}} \\cdot MRT_{\\text{obs}}$"
#> 
#> $vss.obs$formula_note
#> NULL
#> 
#> $vss.obs$tier
#> [1] "uncommon"
#> 
#> $vss.obs$selection
#> list()
#> 
#> 
#> $vss.pred
#> $vss.pred$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.pred$values
#> [1] FALSE  TRUE
#> 
#> $vss.pred$unit_type
#> [1] "volume"
#> 
#> $vss.pred$pretty_name
#> [1] "Vss (based on AUCinf,pred)"
#> 
#> $vss.pred$desc
#> [1] "Vss, predicted Clast"
#> 
#> $vss.pred$sparse
#> [1] FALSE
#> 
#> $vss.pred$formalsmap
#> $vss.pred$formalsmap$cl
#> [1] "cl.pred"
#> 
#> $vss.pred$formalsmap$mrt
#> [1] "mrt.pred"
#> 
#> 
#> $vss.pred$depends
#> [1] "cl.pred"  "mrt.pred"
#> 
#> $vss.pred$datatype
#> [1] "interval"
#> 
#> $vss.pred$pptestcd_cdisc
#> $vss.pred$pptestcd_cdisc$route
#> $vss.pred$pptestcd_cdisc$route$extravascular
#> [1] "VSSF/FP"
#> 
#> $vss.pred$pptestcd_cdisc$route$intravascular
#> [1] "VSSP"
#> 
#> 
#> 
#> $vss.pred$pptest_cdisc
#> $vss.pred$pptest_cdisc$route
#> $vss.pred$pptest_cdisc$route$extravascular
#> [1] "Vss by F Pred"
#> 
#> $vss.pred$pptest_cdisc$route$intravascular
#> [1] "Vol Dist Steady State Pred"
#> 
#> 
#> 
#> $vss.pred$formula
#> [1] "$V_{ss,\\text{pred}} = CL_{\\text{pred}} \\cdot MRT_{\\text{pred}}$"
#> 
#> $vss.pred$formula_note
#> NULL
#> 
#> $vss.pred$tier
#> [1] "uncommon"
#> 
#> $vss.pred$selection
#> list()
#> 
#> 
#> $vss.iv.obs
#> $vss.iv.obs$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.iv.obs$values
#> [1] FALSE  TRUE
#> 
#> $vss.iv.obs$unit_type
#> [1] "volume"
#> 
#> $vss.iv.obs$pretty_name
#> [1] "Vss (for IV dosing, based on AUCinf,obs)"
#> 
#> $vss.iv.obs$desc
#> [1] "IV Vss, observed Clast"
#> 
#> $vss.iv.obs$sparse
#> [1] FALSE
#> 
#> $vss.iv.obs$formalsmap
#> $vss.iv.obs$formalsmap$cl
#> [1] "cl.obs"
#> 
#> $vss.iv.obs$formalsmap$mrt
#> [1] "mrt.iv.obs"
#> 
#> 
#> $vss.iv.obs$depends
#> [1] "cl.obs"     "mrt.iv.obs"
#> 
#> $vss.iv.obs$datatype
#> [1] "interval"
#> 
#> $vss.iv.obs$pptestcd_cdisc
#> [1] "VSSIVO"
#> 
#> $vss.iv.obs$pptest_cdisc
#> [1] "Vss (for IV dosing, based on AUCinf,obs)"
#> 
#> $vss.iv.obs$formula
#> [1] "$V_{ss,\\text{iv,obs}} = CL_{\\text{obs}} \\cdot MRT_{\\text{iv,obs}}$"
#> 
#> $vss.iv.obs$formula_note
#> NULL
#> 
#> $vss.iv.obs$tier
#> [1] "uncommon"
#> 
#> $vss.iv.obs$selection
#> list()
#> 
#> 
#> $vss.iv.pred
#> $vss.iv.pred$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.iv.pred$values
#> [1] FALSE  TRUE
#> 
#> $vss.iv.pred$unit_type
#> [1] "volume"
#> 
#> $vss.iv.pred$pretty_name
#> [1] "Vss (for IV dosing, based on AUCinf,pred)"
#> 
#> $vss.iv.pred$desc
#> [1] "IV Vss, predicted Clast"
#> 
#> $vss.iv.pred$sparse
#> [1] FALSE
#> 
#> $vss.iv.pred$formalsmap
#> $vss.iv.pred$formalsmap$cl
#> [1] "cl.pred"
#> 
#> $vss.iv.pred$formalsmap$mrt
#> [1] "mrt.iv.pred"
#> 
#> 
#> $vss.iv.pred$depends
#> [1] "cl.pred"     "mrt.iv.pred"
#> 
#> $vss.iv.pred$datatype
#> [1] "interval"
#> 
#> $vss.iv.pred$pptestcd_cdisc
#> [1] "VSSIVP"
#> 
#> $vss.iv.pred$pptest_cdisc
#> [1] "Vss (for IV dosing, based on AUCinf,pred)"
#> 
#> $vss.iv.pred$formula
#> [1] "$V_{ss,\\text{iv,pred}} = CL_{\\text{pred}} \\cdot MRT_{\\text{iv,pred}}$"
#> 
#> $vss.iv.pred$formula_note
#> NULL
#> 
#> $vss.iv.pred$tier
#> [1] "uncommon"
#> 
#> $vss.iv.pred$selection
#> list()
#> 
#> 
#> $vss.md.obs
#> $vss.md.obs$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.md.obs$values
#> [1] FALSE  TRUE
#> 
#> $vss.md.obs$unit_type
#> [1] "volume"
#> 
#> $vss.md.obs$pretty_name
#> [1] "Vss (for multiple-dose, based on Clast,obs)"
#> 
#> $vss.md.obs$desc
#> [1] "Vss, multi-dose, obs"
#> 
#> $vss.md.obs$sparse
#> [1] FALSE
#> 
#> $vss.md.obs$formalsmap
#> $vss.md.obs$formalsmap$cl
#> [1] "cl.last"
#> 
#> $vss.md.obs$formalsmap$mrt
#> [1] "mrt.md.obs"
#> 
#> 
#> $vss.md.obs$depends
#> [1] "cl.last"    "mrt.md.obs"
#> 
#> $vss.md.obs$datatype
#> [1] "interval"
#> 
#> $vss.md.obs$pptestcd_cdisc
#> [1] "VSSMDO"
#> 
#> $vss.md.obs$pptest_cdisc
#> [1] "Vss (for multiple-dose, based on AUCinf,obs)"
#> 
#> $vss.md.obs$formula
#> [1] "$V_{ss,\\text{md,obs}} = CL_{\\text{last}} \\cdot MRT_{\\text{md,obs}}$"
#> 
#> $vss.md.obs$formula_note
#> NULL
#> 
#> $vss.md.obs$tier
#> [1] "uncommon"
#> 
#> $vss.md.obs$selection
#> $vss.md.obs$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $vss.md.pred
#> $vss.md.pred$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.md.pred$values
#> [1] FALSE  TRUE
#> 
#> $vss.md.pred$unit_type
#> [1] "volume"
#> 
#> $vss.md.pred$pretty_name
#> [1] "Vss (for multiple-dose, based on Clast,pred)"
#> 
#> $vss.md.pred$desc
#> [1] "Vss, multi-dose, pred"
#> 
#> $vss.md.pred$sparse
#> [1] FALSE
#> 
#> $vss.md.pred$formalsmap
#> $vss.md.pred$formalsmap$cl
#> [1] "cl.last"
#> 
#> $vss.md.pred$formalsmap$mrt
#> [1] "mrt.md.pred"
#> 
#> 
#> $vss.md.pred$depends
#> [1] "cl.last"     "mrt.md.pred"
#> 
#> $vss.md.pred$datatype
#> [1] "interval"
#> 
#> $vss.md.pred$pptestcd_cdisc
#> [1] "VSSMDP"
#> 
#> $vss.md.pred$pptest_cdisc
#> [1] "Vss (for multiple-dose, based on AUCinf,pred)"
#> 
#> $vss.md.pred$formula
#> [1] "$V_{ss,\\text{md,pred}} = CL_{\\text{last}} \\cdot MRT_{\\text{md,pred}}$"
#> 
#> $vss.md.pred$formula_note
#> NULL
#> 
#> $vss.md.pred$tier
#> [1] "uncommon"
#> 
#> $vss.md.pred$selection
#> $vss.md.pred$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $vss.ivmd.obs
#> $vss.ivmd.obs$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.ivmd.obs$values
#> [1] FALSE  TRUE
#> 
#> $vss.ivmd.obs$unit_type
#> [1] "volume"
#> 
#> $vss.ivmd.obs$pretty_name
#> [1] "Vss (for multiple-dose IV infusion, based on Clast,obs)"
#> 
#> $vss.ivmd.obs$desc
#> [1] "IV Vss, multi-dose, obs"
#> 
#> $vss.ivmd.obs$sparse
#> [1] FALSE
#> 
#> $vss.ivmd.obs$formalsmap
#> $vss.ivmd.obs$formalsmap$cl
#> [1] "cl.last"
#> 
#> $vss.ivmd.obs$formalsmap$mrt
#> [1] "mrt.ivmd.obs"
#> 
#> 
#> $vss.ivmd.obs$depends
#> [1] "cl.last"      "mrt.ivmd.obs"
#> 
#> $vss.ivmd.obs$datatype
#> [1] "interval"
#> 
#> $vss.ivmd.obs$pptestcd_cdisc
#> [1] "vss.ivmd.obs"
#> 
#> $vss.ivmd.obs$pptest_cdisc
#> [1] "IV Vss, multi-dose, obs"
#> 
#> $vss.ivmd.obs$formula
#> [1] "$V_{ss,\\text{ivmd,obs}} = CL_{\\text{last}} \\cdot MRT_{\\text{ivmd,obs}}$"
#> 
#> $vss.ivmd.obs$formula_note
#> NULL
#> 
#> $vss.ivmd.obs$tier
#> [1] "uncommon"
#> 
#> $vss.ivmd.obs$selection
#> $vss.ivmd.obs$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $vss.ivmd.pred
#> $vss.ivmd.pred$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.ivmd.pred$values
#> [1] FALSE  TRUE
#> 
#> $vss.ivmd.pred$unit_type
#> [1] "volume"
#> 
#> $vss.ivmd.pred$pretty_name
#> [1] "Vss (for multiple-dose IV infusion, based on Clast,pred)"
#> 
#> $vss.ivmd.pred$desc
#> [1] "IV Vss, multi-dose, pred"
#> 
#> $vss.ivmd.pred$sparse
#> [1] FALSE
#> 
#> $vss.ivmd.pred$formalsmap
#> $vss.ivmd.pred$formalsmap$cl
#> [1] "cl.last"
#> 
#> $vss.ivmd.pred$formalsmap$mrt
#> [1] "mrt.ivmd.pred"
#> 
#> 
#> $vss.ivmd.pred$depends
#> [1] "cl.last"       "mrt.ivmd.pred"
#> 
#> $vss.ivmd.pred$datatype
#> [1] "interval"
#> 
#> $vss.ivmd.pred$pptestcd_cdisc
#> [1] "vss.ivmd.pred"
#> 
#> $vss.ivmd.pred$pptest_cdisc
#> [1] "IV Vss, multi-dose, pred"
#> 
#> $vss.ivmd.pred$formula
#> [1] "$V_{ss,\\text{ivmd,pred}} = CL_{\\text{last}} \\cdot MRT_{\\text{ivmd,pred}}$"
#> 
#> $vss.ivmd.pred$formula_note
#> NULL
#> 
#> $vss.ivmd.pred$tier
#> [1] "uncommon"
#> 
#> $vss.ivmd.pred$selection
#> $vss.ivmd.pred$selection$dosing
#> [1] "multiple"     "steady_state"
#> 
#> 
#> 
#> $vss.int.inf.obs
#> $vss.int.inf.obs$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.int.inf.obs$values
#> [1] FALSE  TRUE
#> 
#> $vss.int.inf.obs$unit_type
#> [1] "volume"
#> 
#> $vss.int.inf.obs$pretty_name
#> [1] "Vss (based on AUCint.inf.obs)"
#> 
#> $vss.int.inf.obs$desc
#> [1] "Vss, calc from interval AUCint.inf.obs"
#> 
#> $vss.int.inf.obs$sparse
#> [1] FALSE
#> 
#> $vss.int.inf.obs$formalsmap
#> $vss.int.inf.obs$formalsmap$cl
#> [1] "cl.int.inf.obs"
#> 
#> $vss.int.inf.obs$formalsmap$mrt
#> [1] "mrt.int.inf.obs"
#> 
#> 
#> $vss.int.inf.obs$depends
#> [1] "cl.int.inf.obs"  "mrt.int.inf.obs"
#> 
#> $vss.int.inf.obs$datatype
#> [1] "interval"
#> 
#> $vss.int.inf.obs$pptestcd_cdisc
#> [1] "vss.int.inf.obs"
#> 
#> $vss.int.inf.obs$pptest_cdisc
#> [1] "Vss, calc from interval AUCint.inf.obs"
#> 
#> $vss.int.inf.obs$formula
#> [1] "$V_{ss,\\text{int,}\\infty\\text{,obs}} = CL_{\\text{int,}\\infty\\text{,obs}} \\cdot MRT_{\\text{int,}\\infty\\text{,obs}}$"
#> 
#> $vss.int.inf.obs$formula_note
#> NULL
#> 
#> $vss.int.inf.obs$tier
#> [1] "uncommon"
#> 
#> $vss.int.inf.obs$selection
#> list()
#> 
#> 
#> $vss.int.inf.pred
#> $vss.int.inf.pred$FUN
#> [1] "pk.calc.vss"
#> 
#> $vss.int.inf.pred$values
#> [1] FALSE  TRUE
#> 
#> $vss.int.inf.pred$unit_type
#> [1] "volume"
#> 
#> $vss.int.inf.pred$pretty_name
#> [1] "Vss (based on AUCint.inf.pred)"
#> 
#> $vss.int.inf.pred$desc
#> [1] "Vss, calc from interval AUCint.inf.pred"
#> 
#> $vss.int.inf.pred$sparse
#> [1] FALSE
#> 
#> $vss.int.inf.pred$formalsmap
#> $vss.int.inf.pred$formalsmap$cl
#> [1] "cl.int.inf.pred"
#> 
#> $vss.int.inf.pred$formalsmap$mrt
#> [1] "mrt.int.inf.pred"
#> 
#> 
#> $vss.int.inf.pred$depends
#> [1] "cl.int.inf.pred"  "mrt.int.inf.pred"
#> 
#> $vss.int.inf.pred$datatype
#> [1] "interval"
#> 
#> $vss.int.inf.pred$pptestcd_cdisc
#> [1] "vss.int.inf.pred"
#> 
#> $vss.int.inf.pred$pptest_cdisc
#> [1] "Vss, calc from interval AUCint.inf.pred"
#> 
#> $vss.int.inf.pred$formula
#> [1] "$V_{ss,\\text{int,}\\infty\\text{,pred}} = CL_{\\text{int,}\\infty\\text{,pred}} \\cdot MRT_{\\text{int,}\\infty\\text{,pred}}$"
#> 
#> $vss.int.inf.pred$formula_note
#> NULL
#> 
#> $vss.int.inf.pred$tier
#> [1] "uncommon"
#> 
#> $vss.int.inf.pred$selection
#> list()
#> 
#> 
#> $cav.int.inf.obs
#> $cav.int.inf.obs$FUN
#> [1] "pk.calc.cav"
#> 
#> $cav.int.inf.obs$values
#> [1] FALSE  TRUE
#> 
#> $cav.int.inf.obs$unit_type
#> [1] "conc"
#> 
#> $cav.int.inf.obs$pretty_name
#> [1] "Cav"
#> 
#> $cav.int.inf.obs$desc
#> [1] "Avg conc in interval (AUCint.inf.obs)"
#> 
#> $cav.int.inf.obs$sparse
#> [1] FALSE
#> 
#> $cav.int.inf.obs$formalsmap
#> $cav.int.inf.obs$formalsmap$auc
#> [1] "aucint.inf.obs"
#> 
#> 
#> $cav.int.inf.obs$depends
#> [1] "aucint.inf.obs"
#> 
#> $cav.int.inf.obs$datatype
#> [1] "interval"
#> 
#> $cav.int.inf.obs$pptestcd_cdisc
#> [1] "CAVGINO"
#> 
#> $cav.int.inf.obs$pptest_cdisc
#> [1] "Cavg Infinity Obs"
#> 
#> $cav.int.inf.obs$formula
#> [1] "$C_{av,\\text{int,}\\infty\\text{,obs}} = \\frac{AUC_{\\text{int,}\\infty\\text{,obs}}}{t_{end} - t_{start}}$"
#> 
#> $cav.int.inf.obs$formula_note
#> NULL
#> 
#> $cav.int.inf.obs$tier
#> [1] "uncommon"
#> 
#> $cav.int.inf.obs$selection
#> list()
#> 
#> 
#> $cav.int.inf.pred
#> $cav.int.inf.pred$FUN
#> [1] "pk.calc.cav"
#> 
#> $cav.int.inf.pred$values
#> [1] FALSE  TRUE
#> 
#> $cav.int.inf.pred$unit_type
#> [1] "conc"
#> 
#> $cav.int.inf.pred$pretty_name
#> [1] "Cav"
#> 
#> $cav.int.inf.pred$desc
#> [1] "Avg conc in interval (AUCint.inf.pred)"
#> 
#> $cav.int.inf.pred$sparse
#> [1] FALSE
#> 
#> $cav.int.inf.pred$formalsmap
#> $cav.int.inf.pred$formalsmap$auc
#> [1] "aucint.inf.pred"
#> 
#> 
#> $cav.int.inf.pred$depends
#> [1] "aucint.inf.pred"
#> 
#> $cav.int.inf.pred$datatype
#> [1] "interval"
#> 
#> $cav.int.inf.pred$pptestcd_cdisc
#> [1] "CAVGINP"
#> 
#> $cav.int.inf.pred$pptest_cdisc
#> [1] "Cavg Infinity Pred"
#> 
#> $cav.int.inf.pred$formula
#> [1] "$C_{av,\\text{int,}\\infty\\text{,pred}} = \\frac{AUC_{\\text{int,}\\infty\\text{,pred}}}{t_{end} - t_{start}}$"
#> 
#> $cav.int.inf.pred$formula_note
#> NULL
#> 
#> $cav.int.inf.pred$tier
#> [1] "uncommon"
#> 
#> $cav.int.inf.pred$selection
#> list()
#> 
#> 
#> $thalf.eff.obs
#> $thalf.eff.obs$FUN
#> [1] "pk.calc.thalf.eff"
#> 
#> $thalf.eff.obs$values
#> [1] FALSE  TRUE
#> 
#> $thalf.eff.obs$unit_type
#> [1] "time"
#> 
#> $thalf.eff.obs$pretty_name
#> [1] "Effective half-life (based on MRT,obs)"
#> 
#> $thalf.eff.obs$desc
#> [1] "Effective half-life, MRTobs"
#> 
#> $thalf.eff.obs$sparse
#> [1] FALSE
#> 
#> $thalf.eff.obs$formalsmap
#> $thalf.eff.obs$formalsmap$mrt
#> [1] "mrt.obs"
#> 
#> 
#> $thalf.eff.obs$depends
#> [1] "mrt.obs"
#> 
#> $thalf.eff.obs$datatype
#> [1] "interval"
#> 
#> $thalf.eff.obs$pptestcd_cdisc
#> [1] "EFFOHL"
#> 
#> $thalf.eff.obs$pptest_cdisc
#> [1] "Effective Half-Life Obs"
#> 
#> $thalf.eff.obs$formula
#> [1] "$t_{1/2,\\text{eff,obs}} = \\ln(2) \\cdot MRT_{\\text{obs}}$"
#> 
#> $thalf.eff.obs$formula_note
#> NULL
#> 
#> $thalf.eff.obs$tier
#> [1] "uncommon"
#> 
#> $thalf.eff.obs$selection
#> list()
#> 
#> 
#> $thalf.eff.pred
#> $thalf.eff.pred$FUN
#> [1] "pk.calc.thalf.eff"
#> 
#> $thalf.eff.pred$values
#> [1] FALSE  TRUE
#> 
#> $thalf.eff.pred$unit_type
#> [1] "time"
#> 
#> $thalf.eff.pred$pretty_name
#> [1] "Effective half-life (based on MRT,pred)"
#> 
#> $thalf.eff.pred$desc
#> [1] "Effective half-life, MRTpred"
#> 
#> $thalf.eff.pred$sparse
#> [1] FALSE
#> 
#> $thalf.eff.pred$formalsmap
#> $thalf.eff.pred$formalsmap$mrt
#> [1] "mrt.pred"
#> 
#> 
#> $thalf.eff.pred$depends
#> [1] "mrt.pred"
#> 
#> $thalf.eff.pred$datatype
#> [1] "interval"
#> 
#> $thalf.eff.pred$pptestcd_cdisc
#> [1] "EFFPHL"
#> 
#> $thalf.eff.pred$pptest_cdisc
#> [1] "Effective Half-Life Pred"
#> 
#> $thalf.eff.pred$formula
#> [1] "$t_{1/2,\\text{eff,pred}} = \\ln(2) \\cdot MRT_{\\text{pred}}$"
#> 
#> $thalf.eff.pred$formula_note
#> NULL
#> 
#> $thalf.eff.pred$tier
#> [1] "uncommon"
#> 
#> $thalf.eff.pred$selection
#> list()
#> 
#> 
#> $thalf.eff.iv.obs
#> $thalf.eff.iv.obs$FUN
#> [1] "pk.calc.thalf.eff"
#> 
#> $thalf.eff.iv.obs$values
#> [1] FALSE  TRUE
#> 
#> $thalf.eff.iv.obs$unit_type
#> [1] "time"
#> 
#> $thalf.eff.iv.obs$pretty_name
#> [1] "Effective half-life (for IV dosing, based on MRT,obs)"
#> 
#> $thalf.eff.iv.obs$desc
#> [1] "Effective half-life, IV MRTobs"
#> 
#> $thalf.eff.iv.obs$sparse
#> [1] FALSE
#> 
#> $thalf.eff.iv.obs$formalsmap
#> $thalf.eff.iv.obs$formalsmap$mrt
#> [1] "mrt.iv.obs"
#> 
#> 
#> $thalf.eff.iv.obs$depends
#> [1] "mrt.iv.obs"
#> 
#> $thalf.eff.iv.obs$datatype
#> [1] "interval"
#> 
#> $thalf.eff.iv.obs$pptestcd_cdisc
#> [1] "EFFIVOHL"
#> 
#> $thalf.eff.iv.obs$pptest_cdisc
#> [1] "Effective Half-Life (for IV dosing, based on MRT Obs)"
#> 
#> $thalf.eff.iv.obs$formula
#> [1] "$t_{1/2,\\text{eff,iv,obs}} = \\ln(2) \\cdot MRT_{\\text{iv,obs}}$"
#> 
#> $thalf.eff.iv.obs$formula_note
#> NULL
#> 
#> $thalf.eff.iv.obs$tier
#> [1] "uncommon"
#> 
#> $thalf.eff.iv.obs$selection
#> list()
#> 
#> 
#> $thalf.eff.iv.pred
#> $thalf.eff.iv.pred$FUN
#> [1] "pk.calc.thalf.eff"
#> 
#> $thalf.eff.iv.pred$values
#> [1] FALSE  TRUE
#> 
#> $thalf.eff.iv.pred$unit_type
#> [1] "time"
#> 
#> $thalf.eff.iv.pred$pretty_name
#> [1] "Effective half-life (for IV dosing, based on MRT,pred)"
#> 
#> $thalf.eff.iv.pred$desc
#> [1] "Effective half-life, IV MRTpred"
#> 
#> $thalf.eff.iv.pred$sparse
#> [1] FALSE
#> 
#> $thalf.eff.iv.pred$formalsmap
#> $thalf.eff.iv.pred$formalsmap$mrt
#> [1] "mrt.iv.pred"
#> 
#> 
#> $thalf.eff.iv.pred$depends
#> [1] "mrt.iv.pred"
#> 
#> $thalf.eff.iv.pred$datatype
#> [1] "interval"
#> 
#> $thalf.eff.iv.pred$pptestcd_cdisc
#> [1] "EFFIVPHL"
#> 
#> $thalf.eff.iv.pred$pptest_cdisc
#> [1] "Effective Half-Life (for IV dosing, based on MRT Pred)"
#> 
#> $thalf.eff.iv.pred$formula
#> [1] "$t_{1/2,\\text{eff,iv,pred}} = \\ln(2) \\cdot MRT_{\\text{iv,pred}}$"
#> 
#> $thalf.eff.iv.pred$formula_note
#> NULL
#> 
#> $thalf.eff.iv.pred$tier
#> [1] "uncommon"
#> 
#> $thalf.eff.iv.pred$selection
#> list()
#> 
#> 
#> $kel.obs
#> $kel.obs$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.obs$values
#> [1] FALSE  TRUE
#> 
#> $kel.obs$unit_type
#> [1] "inverse_time"
#> 
#> $kel.obs$pretty_name
#> [1] "Kel (based on AUCinf,obs)"
#> 
#> $kel.obs$desc
#> [1] "Elim rate, MRT w/ obs Clast"
#> 
#> $kel.obs$sparse
#> [1] FALSE
#> 
#> $kel.obs$formalsmap
#> $kel.obs$formalsmap$mrt
#> [1] "mrt.obs"
#> 
#> 
#> $kel.obs$depends
#> [1] "mrt.obs"
#> 
#> $kel.obs$datatype
#> [1] "interval"
#> 
#> $kel.obs$pptestcd_cdisc
#> [1] "KELOS"
#> 
#> $kel.obs$pptest_cdisc
#> [1] "Kel (based on AUCinf,obs)"
#> 
#> $kel.obs$formula
#> [1] "$k_{el,\\text{obs}} = \\frac{1}{MRT_{\\text{obs}}}$"
#> 
#> $kel.obs$formula_note
#> NULL
#> 
#> $kel.obs$tier
#> [1] "uncommon"
#> 
#> $kel.obs$selection
#> list()
#> 
#> 
#> $kel.pred
#> $kel.pred$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.pred$values
#> [1] FALSE  TRUE
#> 
#> $kel.pred$unit_type
#> [1] "inverse_time"
#> 
#> $kel.pred$pretty_name
#> [1] "Kel (based on AUCinf,pred)"
#> 
#> $kel.pred$desc
#> [1] "Elim rate, MRT w/ pred Clast"
#> 
#> $kel.pred$sparse
#> [1] FALSE
#> 
#> $kel.pred$formalsmap
#> $kel.pred$formalsmap$mrt
#> [1] "mrt.pred"
#> 
#> 
#> $kel.pred$depends
#> [1] "mrt.pred"
#> 
#> $kel.pred$datatype
#> [1] "interval"
#> 
#> $kel.pred$pptestcd_cdisc
#> [1] "KELP"
#> 
#> $kel.pred$pptest_cdisc
#> [1] "Kel (based on AUCinf,pred)"
#> 
#> $kel.pred$formula
#> [1] "$k_{el,\\text{pred}} = \\frac{1}{MRT_{\\text{pred}}}$"
#> 
#> $kel.pred$formula_note
#> NULL
#> 
#> $kel.pred$tier
#> [1] "uncommon"
#> 
#> $kel.pred$selection
#> list()
#> 
#> 
#> $kel.iv.obs
#> $kel.iv.obs$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.iv.obs$values
#> [1] FALSE  TRUE
#> 
#> $kel.iv.obs$unit_type
#> [1] "inverse_time"
#> 
#> $kel.iv.obs$pretty_name
#> [1] "Kel (for IV dosing, based on AUCinf,obs)"
#> 
#> $kel.iv.obs$desc
#> [1] "Elim rate, IV MRTobs"
#> 
#> $kel.iv.obs$sparse
#> [1] FALSE
#> 
#> $kel.iv.obs$formalsmap
#> $kel.iv.obs$formalsmap$mrt
#> [1] "mrt.iv.obs"
#> 
#> 
#> $kel.iv.obs$depends
#> [1] "mrt.iv.obs"
#> 
#> $kel.iv.obs$datatype
#> [1] "interval"
#> 
#> $kel.iv.obs$pptestcd_cdisc
#> [1] "KELIVOS"
#> 
#> $kel.iv.obs$pptest_cdisc
#> [1] "Kel (for IV dosing, based on AUCinf,obs)"
#> 
#> $kel.iv.obs$formula
#> [1] "$k_{el,\\text{iv,obs}} = \\frac{1}{MRT_{\\text{iv,obs}}}$"
#> 
#> $kel.iv.obs$formula_note
#> NULL
#> 
#> $kel.iv.obs$tier
#> [1] "uncommon"
#> 
#> $kel.iv.obs$selection
#> list()
#> 
#> 
#> $kel.iv.pred
#> $kel.iv.pred$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.iv.pred$values
#> [1] FALSE  TRUE
#> 
#> $kel.iv.pred$unit_type
#> [1] "inverse_time"
#> 
#> $kel.iv.pred$pretty_name
#> [1] "Kel (for IV dosing, based on AUCinf,pred)"
#> 
#> $kel.iv.pred$desc
#> [1] "Elim rate, IV MRTpred"
#> 
#> $kel.iv.pred$sparse
#> [1] FALSE
#> 
#> $kel.iv.pred$formalsmap
#> $kel.iv.pred$formalsmap$mrt
#> [1] "mrt.iv.pred"
#> 
#> 
#> $kel.iv.pred$depends
#> [1] "mrt.iv.pred"
#> 
#> $kel.iv.pred$datatype
#> [1] "interval"
#> 
#> $kel.iv.pred$pptestcd_cdisc
#> [1] "KELIVP"
#> 
#> $kel.iv.pred$pptest_cdisc
#> [1] "Kel (for IV dosing, based on AUCinf,pred)"
#> 
#> $kel.iv.pred$formula
#> [1] "$k_{el,\\text{iv,pred}} = \\frac{1}{MRT_{\\text{iv,pred}}}$"
#> 
#> $kel.iv.pred$formula_note
#> NULL
#> 
#> $kel.iv.pred$tier
#> [1] "uncommon"
#> 
#> $kel.iv.pred$selection
#> list()
#> 
#> 
#> $kel.int.inf.obs
#> $kel.int.inf.obs$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.int.inf.obs$values
#> [1] FALSE  TRUE
#> 
#> $kel.int.inf.obs$unit_type
#> [1] "inverse_time"
#> 
#> $kel.int.inf.obs$pretty_name
#> [1] "Kel (based on AUCint.inf.obs)"
#> 
#> $kel.int.inf.obs$desc
#> [1] "Elim rate, MRTint.inf.obs"
#> 
#> $kel.int.inf.obs$sparse
#> [1] FALSE
#> 
#> $kel.int.inf.obs$formalsmap
#> $kel.int.inf.obs$formalsmap$mrt
#> [1] "mrt.int.inf.obs"
#> 
#> 
#> $kel.int.inf.obs$depends
#> [1] "mrt.int.inf.obs"
#> 
#> $kel.int.inf.obs$datatype
#> [1] "interval"
#> 
#> $kel.int.inf.obs$pptestcd_cdisc
#> [1] "kel.int.inf.obs"
#> 
#> $kel.int.inf.obs$pptest_cdisc
#> [1] "Elim rate, MRTint.inf.obs"
#> 
#> $kel.int.inf.obs$formula
#> [1] "$k_{el,\\text{int,}\\infty\\text{,obs}} = \\frac{1}{MRT_{\\text{int,}\\infty\\text{,obs}}}$"
#> 
#> $kel.int.inf.obs$formula_note
#> NULL
#> 
#> $kel.int.inf.obs$tier
#> [1] "uncommon"
#> 
#> $kel.int.inf.obs$selection
#> list()
#> 
#> 
#> $kel.int.inf.pred
#> $kel.int.inf.pred$FUN
#> [1] "pk.calc.kel"
#> 
#> $kel.int.inf.pred$values
#> [1] FALSE  TRUE
#> 
#> $kel.int.inf.pred$unit_type
#> [1] "inverse_time"
#> 
#> $kel.int.inf.pred$pretty_name
#> [1] "Kel (based on AUCint.inf.pred)"
#> 
#> $kel.int.inf.pred$desc
#> [1] "Elim rate, MRTint.inf.pred"
#> 
#> $kel.int.inf.pred$sparse
#> [1] FALSE
#> 
#> $kel.int.inf.pred$formalsmap
#> $kel.int.inf.pred$formalsmap$mrt
#> [1] "mrt.int.inf.pred"
#> 
#> 
#> $kel.int.inf.pred$depends
#> [1] "mrt.int.inf.pred"
#> 
#> $kel.int.inf.pred$datatype
#> [1] "interval"
#> 
#> $kel.int.inf.pred$pptestcd_cdisc
#> [1] "kel.int.inf.pred"
#> 
#> $kel.int.inf.pred$pptest_cdisc
#> [1] "Elim rate, MRTint.inf.pred"
#> 
#> $kel.int.inf.pred$formula
#> [1] "$k_{el,\\text{int,}\\infty\\text{,pred}} = \\frac{1}{MRT_{\\text{int,}\\infty\\text{,pred}}}$"
#> 
#> $kel.int.inf.pred$formula_note
#> NULL
#> 
#> $kel.int.inf.pred$tier
#> [1] "uncommon"
#> 
#> $kel.int.inf.pred$selection
#> list()
#> 
#> 
#> $auclast.dn
#> $auclast.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $auclast.dn$values
#> [1] FALSE  TRUE
#> 
#> $auclast.dn$unit_type
#> [1] "auc_dosenorm"
#> 
#> $auclast.dn$pretty_name
#> [1] "AUClast (dose-normalized)"
#> 
#> $auclast.dn$desc
#> [1] "Dose normalized auclast"
#> 
#> $auclast.dn$sparse
#> [1] FALSE
#> 
#> $auclast.dn$formalsmap
#> $auclast.dn$formalsmap$parameter
#> [1] "auclast"
#> 
#> 
#> $auclast.dn$depends
#> [1] "auclast"
#> 
#> $auclast.dn$datatype
#> [1] "interval"
#> 
#> $auclast.dn$pptestcd_cdisc
#> [1] "AUCLSTD"
#> 
#> $auclast.dn$pptest_cdisc
#> [1] "AUC to Last Nonzero Conc by Dose"
#> 
#> $auclast.dn$formula
#> [1] "$AUC_{\\text{last},dn} = \\frac{AUC_{\\text{last}}}{Dose}$"
#> 
#> $auclast.dn$formula_note
#> NULL
#> 
#> $auclast.dn$tier
#> [1] "uncommon"
#> 
#> $auclast.dn$selection
#> list()
#> 
#> 
#> $aucall.dn
#> $aucall.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $aucall.dn$values
#> [1] FALSE  TRUE
#> 
#> $aucall.dn$unit_type
#> [1] "auc_dosenorm"
#> 
#> $aucall.dn$pretty_name
#> [1] "AUCall (dose-normalized)"
#> 
#> $aucall.dn$desc
#> [1] "Dose normalized aucall"
#> 
#> $aucall.dn$sparse
#> [1] FALSE
#> 
#> $aucall.dn$formalsmap
#> $aucall.dn$formalsmap$parameter
#> [1] "aucall"
#> 
#> 
#> $aucall.dn$depends
#> [1] "aucall"
#> 
#> $aucall.dn$datatype
#> [1] "interval"
#> 
#> $aucall.dn$pptestcd_cdisc
#> [1] "AUCALLD"
#> 
#> $aucall.dn$pptest_cdisc
#> [1] "AUC All by Dose"
#> 
#> $aucall.dn$formula
#> [1] "$AUC_{\\text{all},dn} = \\frac{AUC_{\\text{all}}}{Dose}$"
#> 
#> $aucall.dn$formula_note
#> NULL
#> 
#> $aucall.dn$tier
#> [1] "uncommon"
#> 
#> $aucall.dn$selection
#> list()
#> 
#> 
#> $aucinf.obs.dn
#> $aucinf.obs.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $aucinf.obs.dn$values
#> [1] FALSE  TRUE
#> 
#> $aucinf.obs.dn$unit_type
#> [1] "auc_dosenorm"
#> 
#> $aucinf.obs.dn$pretty_name
#> [1] "AUCinf,obs (dose-normalized)"
#> 
#> $aucinf.obs.dn$desc
#> [1] "Dose normalized aucinf.obs"
#> 
#> $aucinf.obs.dn$sparse
#> [1] FALSE
#> 
#> $aucinf.obs.dn$formalsmap
#> $aucinf.obs.dn$formalsmap$parameter
#> [1] "aucinf.obs"
#> 
#> 
#> $aucinf.obs.dn$depends
#> [1] "aucinf.obs"
#> 
#> $aucinf.obs.dn$datatype
#> [1] "interval"
#> 
#> $aucinf.obs.dn$pptestcd_cdisc
#> [1] "AUCIFOD"
#> 
#> $aucinf.obs.dn$pptest_cdisc
#> [1] "AUC Infinity Obs by Dose"
#> 
#> $aucinf.obs.dn$formula
#> [1] "$AUC_{\\infty,\\text{obs},dn} = \\frac{AUC_{\\infty,\\text{obs}}}{Dose}$"
#> 
#> $aucinf.obs.dn$formula_note
#> NULL
#> 
#> $aucinf.obs.dn$tier
#> [1] "uncommon"
#> 
#> $aucinf.obs.dn$selection
#> list()
#> 
#> 
#> $aucinf.pred.dn
#> $aucinf.pred.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $aucinf.pred.dn$values
#> [1] FALSE  TRUE
#> 
#> $aucinf.pred.dn$unit_type
#> [1] "auc_dosenorm"
#> 
#> $aucinf.pred.dn$pretty_name
#> [1] "AUCinf,pred (dose-normalized)"
#> 
#> $aucinf.pred.dn$desc
#> [1] "Dose normalized aucinf.pred"
#> 
#> $aucinf.pred.dn$sparse
#> [1] FALSE
#> 
#> $aucinf.pred.dn$formalsmap
#> $aucinf.pred.dn$formalsmap$parameter
#> [1] "aucinf.pred"
#> 
#> 
#> $aucinf.pred.dn$depends
#> [1] "aucinf.pred"
#> 
#> $aucinf.pred.dn$datatype
#> [1] "interval"
#> 
#> $aucinf.pred.dn$pptestcd_cdisc
#> [1] "AUCIFPD"
#> 
#> $aucinf.pred.dn$pptest_cdisc
#> [1] "AUC Infinity Pred by Dose"
#> 
#> $aucinf.pred.dn$formula
#> [1] "$AUC_{\\infty,\\text{pred},dn} = \\frac{AUC_{\\infty,\\text{pred}}}{Dose}$"
#> 
#> $aucinf.pred.dn$formula_note
#> NULL
#> 
#> $aucinf.pred.dn$tier
#> [1] "uncommon"
#> 
#> $aucinf.pred.dn$selection
#> list()
#> 
#> 
#> $aumclast.dn
#> $aumclast.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $aumclast.dn$values
#> [1] FALSE  TRUE
#> 
#> $aumclast.dn$unit_type
#> [1] "aumc_dosenorm"
#> 
#> $aumclast.dn$pretty_name
#> [1] "AUMC,last (dose-normalized)"
#> 
#> $aumclast.dn$desc
#> [1] "Dose normalized aumclast"
#> 
#> $aumclast.dn$sparse
#> [1] FALSE
#> 
#> $aumclast.dn$formalsmap
#> $aumclast.dn$formalsmap$parameter
#> [1] "aumclast"
#> 
#> 
#> $aumclast.dn$depends
#> [1] "aumclast"
#> 
#> $aumclast.dn$datatype
#> [1] "interval"
#> 
#> $aumclast.dn$pptestcd_cdisc
#> [1] "AUMCLSTD"
#> 
#> $aumclast.dn$pptest_cdisc
#> [1] "AUMC to Last Nonzero Conc by Dose"
#> 
#> $aumclast.dn$formula
#> [1] "$AUMC_{\\text{last},dn} = \\frac{AUMC_{\\text{last}}}{Dose}$"
#> 
#> $aumclast.dn$formula_note
#> NULL
#> 
#> $aumclast.dn$tier
#> [1] "uncommon"
#> 
#> $aumclast.dn$selection
#> list()
#> 
#> 
#> $aumcall.dn
#> $aumcall.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $aumcall.dn$values
#> [1] FALSE  TRUE
#> 
#> $aumcall.dn$unit_type
#> [1] "aumc_dosenorm"
#> 
#> $aumcall.dn$pretty_name
#> [1] "AUMC,all (dose-normalized)"
#> 
#> $aumcall.dn$desc
#> [1] "Dose normalized aumcall"
#> 
#> $aumcall.dn$sparse
#> [1] FALSE
#> 
#> $aumcall.dn$formalsmap
#> $aumcall.dn$formalsmap$parameter
#> [1] "aumcall"
#> 
#> 
#> $aumcall.dn$depends
#> [1] "aumcall"
#> 
#> $aumcall.dn$datatype
#> [1] "interval"
#> 
#> $aumcall.dn$pptestcd_cdisc
#> [1] "AUMCALLD"
#> 
#> $aumcall.dn$pptest_cdisc
#> [1] "AUMC All by Dose"
#> 
#> $aumcall.dn$formula
#> [1] "$AUMC_{\\text{all},dn} = \\frac{AUMC_{\\text{all}}}{Dose}$"
#> 
#> $aumcall.dn$formula_note
#> NULL
#> 
#> $aumcall.dn$tier
#> [1] "uncommon"
#> 
#> $aumcall.dn$selection
#> list()
#> 
#> 
#> $aumcinf.obs.dn
#> $aumcinf.obs.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $aumcinf.obs.dn$values
#> [1] FALSE  TRUE
#> 
#> $aumcinf.obs.dn$unit_type
#> [1] "aumc_dosenorm"
#> 
#> $aumcinf.obs.dn$pretty_name
#> [1] "AUMC,inf,obs (dose-normalized)"
#> 
#> $aumcinf.obs.dn$desc
#> [1] "Dose normalized aumcinf.obs"
#> 
#> $aumcinf.obs.dn$sparse
#> [1] FALSE
#> 
#> $aumcinf.obs.dn$formalsmap
#> $aumcinf.obs.dn$formalsmap$parameter
#> [1] "aumcinf.obs"
#> 
#> 
#> $aumcinf.obs.dn$depends
#> [1] "aumcinf.obs"
#> 
#> $aumcinf.obs.dn$datatype
#> [1] "interval"
#> 
#> $aumcinf.obs.dn$pptestcd_cdisc
#> [1] "AUMCIFOD"
#> 
#> $aumcinf.obs.dn$pptest_cdisc
#> [1] "AUMC Infinity Obs by Dose"
#> 
#> $aumcinf.obs.dn$formula
#> [1] "$AUMC_{\\infty,\\text{obs},dn} = \\frac{AUMC_{\\infty,\\text{obs}}}{Dose}$"
#> 
#> $aumcinf.obs.dn$formula_note
#> NULL
#> 
#> $aumcinf.obs.dn$tier
#> [1] "uncommon"
#> 
#> $aumcinf.obs.dn$selection
#> list()
#> 
#> 
#> $aumcinf.pred.dn
#> $aumcinf.pred.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $aumcinf.pred.dn$values
#> [1] FALSE  TRUE
#> 
#> $aumcinf.pred.dn$unit_type
#> [1] "aumc_dosenorm"
#> 
#> $aumcinf.pred.dn$pretty_name
#> [1] "AUMC,inf,pred (dose-normalized)"
#> 
#> $aumcinf.pred.dn$desc
#> [1] "Dose normalized aumcinf.pred"
#> 
#> $aumcinf.pred.dn$sparse
#> [1] FALSE
#> 
#> $aumcinf.pred.dn$formalsmap
#> $aumcinf.pred.dn$formalsmap$parameter
#> [1] "aumcinf.pred"
#> 
#> 
#> $aumcinf.pred.dn$depends
#> [1] "aumcinf.pred"
#> 
#> $aumcinf.pred.dn$datatype
#> [1] "interval"
#> 
#> $aumcinf.pred.dn$pptestcd_cdisc
#> [1] "AUMCIFPD"
#> 
#> $aumcinf.pred.dn$pptest_cdisc
#> [1] "AUMC Infinity Pred by Dose"
#> 
#> $aumcinf.pred.dn$formula
#> [1] "$AUMC_{\\infty,\\text{pred},dn} = \\frac{AUMC_{\\infty,\\text{pred}}}{Dose}$"
#> 
#> $aumcinf.pred.dn$formula_note
#> NULL
#> 
#> $aumcinf.pred.dn$tier
#> [1] "uncommon"
#> 
#> $aumcinf.pred.dn$selection
#> list()
#> 
#> 
#> $cmax.dn
#> $cmax.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $cmax.dn$values
#> [1] FALSE  TRUE
#> 
#> $cmax.dn$unit_type
#> [1] "conc_dosenorm"
#> 
#> $cmax.dn$pretty_name
#> [1] "Cmax (dose-normalized)"
#> 
#> $cmax.dn$desc
#> [1] "Dose normalized cmax"
#> 
#> $cmax.dn$sparse
#> [1] FALSE
#> 
#> $cmax.dn$formalsmap
#> $cmax.dn$formalsmap$parameter
#> [1] "cmax"
#> 
#> 
#> $cmax.dn$depends
#> [1] "cmax"
#> 
#> $cmax.dn$datatype
#> [1] "interval"
#> 
#> $cmax.dn$pptestcd_cdisc
#> [1] "CMAXD"
#> 
#> $cmax.dn$pptest_cdisc
#> [1] "Max Conc by Dose"
#> 
#> $cmax.dn$formula
#> [1] "$C_{\\max,dn} = \\frac{C_{\\max}}{Dose}$"
#> 
#> $cmax.dn$formula_note
#> NULL
#> 
#> $cmax.dn$tier
#> [1] "uncommon"
#> 
#> $cmax.dn$selection
#> list()
#> 
#> 
#> $cmin.dn
#> $cmin.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $cmin.dn$values
#> [1] FALSE  TRUE
#> 
#> $cmin.dn$unit_type
#> [1] "conc_dosenorm"
#> 
#> $cmin.dn$pretty_name
#> [1] "Cmin (dose-normalized)"
#> 
#> $cmin.dn$desc
#> [1] "Dose normalized cmin"
#> 
#> $cmin.dn$sparse
#> [1] FALSE
#> 
#> $cmin.dn$formalsmap
#> $cmin.dn$formalsmap$parameter
#> [1] "cmin"
#> 
#> 
#> $cmin.dn$depends
#> [1] "cmin"
#> 
#> $cmin.dn$datatype
#> [1] "interval"
#> 
#> $cmin.dn$pptestcd_cdisc
#> [1] "CMIND"
#> 
#> $cmin.dn$pptest_cdisc
#> [1] "Min Conc by Dose"
#> 
#> $cmin.dn$formula
#> [1] "$C_{\\min,dn} = \\frac{C_{\\min}}{Dose}$"
#> 
#> $cmin.dn$formula_note
#> NULL
#> 
#> $cmin.dn$tier
#> [1] "uncommon"
#> 
#> $cmin.dn$selection
#> list()
#> 
#> 
#> $clast.obs.dn
#> $clast.obs.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $clast.obs.dn$values
#> [1] FALSE  TRUE
#> 
#> $clast.obs.dn$unit_type
#> [1] "conc_dosenorm"
#> 
#> $clast.obs.dn$pretty_name
#> [1] "Clast (dose-normalized)"
#> 
#> $clast.obs.dn$desc
#> [1] "Dose normalized clast.obs"
#> 
#> $clast.obs.dn$sparse
#> [1] FALSE
#> 
#> $clast.obs.dn$formalsmap
#> $clast.obs.dn$formalsmap$parameter
#> [1] "clast.obs"
#> 
#> 
#> $clast.obs.dn$depends
#> [1] "clast.obs"
#> 
#> $clast.obs.dn$datatype
#> [1] "interval"
#> 
#> $clast.obs.dn$pptestcd_cdisc
#> [1] "CLSTD"
#> 
#> $clast.obs.dn$pptest_cdisc
#> [1] "Last Nonzero Conc by Dose"
#> 
#> $clast.obs.dn$formula
#> [1] "$C_{\\text{last,obs},dn} = \\frac{C_{\\text{last,obs}}}{Dose}$"
#> 
#> $clast.obs.dn$formula_note
#> NULL
#> 
#> $clast.obs.dn$tier
#> [1] "uncommon"
#> 
#> $clast.obs.dn$selection
#> list()
#> 
#> 
#> $clast.pred.dn
#> $clast.pred.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $clast.pred.dn$values
#> [1] FALSE  TRUE
#> 
#> $clast.pred.dn$unit_type
#> [1] "conc_dosenorm"
#> 
#> $clast.pred.dn$pretty_name
#> [1] "Clast,pred (dose-normalized)"
#> 
#> $clast.pred.dn$desc
#> [1] "Dose normalized clast.pred"
#> 
#> $clast.pred.dn$sparse
#> [1] FALSE
#> 
#> $clast.pred.dn$formalsmap
#> $clast.pred.dn$formalsmap$parameter
#> [1] "clast.pred"
#> 
#> 
#> $clast.pred.dn$depends
#> [1] "clast.pred"
#> 
#> $clast.pred.dn$datatype
#> [1] "interval"
#> 
#> $clast.pred.dn$pptestcd_cdisc
#> [1] "CLSTPD"
#> 
#> $clast.pred.dn$pptest_cdisc
#> [1] "Clast pred by Dose"
#> 
#> $clast.pred.dn$formula
#> [1] "$C_{\\text{last,pred},dn} = \\frac{C_{\\text{last,pred}}}{Dose}$"
#> 
#> $clast.pred.dn$formula_note
#> NULL
#> 
#> $clast.pred.dn$tier
#> [1] "uncommon"
#> 
#> $clast.pred.dn$selection
#> list()
#> 
#> 
#> $cav.dn
#> $cav.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $cav.dn$values
#> [1] FALSE  TRUE
#> 
#> $cav.dn$unit_type
#> [1] "conc_dosenorm"
#> 
#> $cav.dn$pretty_name
#> [1] "Cav (dose-normalized)"
#> 
#> $cav.dn$desc
#> [1] "Dose normalized cav"
#> 
#> $cav.dn$sparse
#> [1] FALSE
#> 
#> $cav.dn$formalsmap
#> $cav.dn$formalsmap$parameter
#> [1] "cav"
#> 
#> 
#> $cav.dn$depends
#> [1] "cav"
#> 
#> $cav.dn$datatype
#> [1] "interval"
#> 
#> $cav.dn$pptestcd_cdisc
#> [1] "CAVGD"
#> 
#> $cav.dn$pptest_cdisc
#> [1] "Average Conc by Dose"
#> 
#> $cav.dn$formula
#> [1] "$C_{av,dn} = \\frac{C_{av}}{Dose}$"
#> 
#> $cav.dn$formula_note
#> NULL
#> 
#> $cav.dn$tier
#> [1] "uncommon"
#> 
#> $cav.dn$selection
#> list()
#> 
#> 
#> $ctrough.dn
#> $ctrough.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $ctrough.dn$values
#> [1] FALSE  TRUE
#> 
#> $ctrough.dn$unit_type
#> [1] "conc_dosenorm"
#> 
#> $ctrough.dn$pretty_name
#> [1] "Ctrough (dose-normalized)"
#> 
#> $ctrough.dn$desc
#> [1] "Dose normalized ctrough"
#> 
#> $ctrough.dn$sparse
#> [1] FALSE
#> 
#> $ctrough.dn$formalsmap
#> $ctrough.dn$formalsmap$parameter
#> [1] "ctrough"
#> 
#> 
#> $ctrough.dn$depends
#> [1] "ctrough"
#> 
#> $ctrough.dn$datatype
#> [1] "interval"
#> 
#> $ctrough.dn$pptestcd_cdisc
#> [1] "CTROUGHD"
#> 
#> $ctrough.dn$pptest_cdisc
#> [1] "Conc Trough by Dose"
#> 
#> $ctrough.dn$formula
#> [1] "$C_{\\text{trough},dn} = \\frac{C_{\\text{trough}}}{Dose}$"
#> 
#> $ctrough.dn$formula_note
#> NULL
#> 
#> $ctrough.dn$tier
#> [1] "uncommon"
#> 
#> $ctrough.dn$selection
#> list()
#> 
#> 
#> $clr.last.dn
#> $clr.last.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $clr.last.dn$values
#> [1] FALSE  TRUE
#> 
#> $clr.last.dn$unit_type
#> [1] "renal_clearance_dosenorm"
#> 
#> $clr.last.dn$pretty_name
#> [1] "Renal clearance (from AUClast) (dose-normalized)"
#> 
#> $clr.last.dn$desc
#> [1] "Dose normalized clr.last"
#> 
#> $clr.last.dn$sparse
#> [1] FALSE
#> 
#> $clr.last.dn$formalsmap
#> $clr.last.dn$formalsmap$parameter
#> [1] "clr.last"
#> 
#> 
#> $clr.last.dn$depends
#> [1] "clr.last"
#> 
#> $clr.last.dn$datatype
#> [1] "interval"
#> 
#> $clr.last.dn$pptestcd_cdisc
#> [1] "RENALCLD"
#> 
#> $clr.last.dn$pptest_cdisc
#> [1] "Renal CL by Dose"
#> 
#> $clr.last.dn$formula
#> [1] "$CL_{R,\\text{last},dn} = \\frac{CL_{R,\\text{last}}}{Dose}$"
#> 
#> $clr.last.dn$formula_note
#> NULL
#> 
#> $clr.last.dn$tier
#> [1] "uncommon"
#> 
#> $clr.last.dn$selection
#> list()
#> 
#> 
#> $clr.obs.dn
#> $clr.obs.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $clr.obs.dn$values
#> [1] FALSE  TRUE
#> 
#> $clr.obs.dn$unit_type
#> [1] "renal_clearance_dosenorm"
#> 
#> $clr.obs.dn$pretty_name
#> [1] "Renal clearance (from AUCinf,obs) (dose-normalized)"
#> 
#> $clr.obs.dn$desc
#> [1] "Dose normalized clr.obs"
#> 
#> $clr.obs.dn$sparse
#> [1] FALSE
#> 
#> $clr.obs.dn$formalsmap
#> $clr.obs.dn$formalsmap$parameter
#> [1] "clr.obs"
#> 
#> 
#> $clr.obs.dn$depends
#> [1] "clr.obs"
#> 
#> $clr.obs.dn$datatype
#> [1] "interval"
#> 
#> $clr.obs.dn$pptestcd_cdisc
#> [1] "RENALCLD"
#> 
#> $clr.obs.dn$pptest_cdisc
#> [1] "Renal CL by Dose"
#> 
#> $clr.obs.dn$formula
#> [1] "$CL_{R,\\text{obs},dn} = \\frac{CL_{R,\\text{obs}}}{Dose}$"
#> 
#> $clr.obs.dn$formula_note
#> NULL
#> 
#> $clr.obs.dn$tier
#> [1] "uncommon"
#> 
#> $clr.obs.dn$selection
#> list()
#> 
#> 
#> $clr.pred.dn
#> $clr.pred.dn$FUN
#> [1] "pk.calc.dn"
#> 
#> $clr.pred.dn$values
#> [1] FALSE  TRUE
#> 
#> $clr.pred.dn$unit_type
#> [1] "renal_clearance_dosenorm"
#> 
#> $clr.pred.dn$pretty_name
#> [1] "Renal clearance (from AUCinf,pred) (dose-normalized)"
#> 
#> $clr.pred.dn$desc
#> [1] "Dose normalized clr.pred"
#> 
#> $clr.pred.dn$sparse
#> [1] FALSE
#> 
#> $clr.pred.dn$formalsmap
#> $clr.pred.dn$formalsmap$parameter
#> [1] "clr.pred"
#> 
#> 
#> $clr.pred.dn$depends
#> [1] "clr.pred"
#> 
#> $clr.pred.dn$datatype
#> [1] "interval"
#> 
#> $clr.pred.dn$pptestcd_cdisc
#> [1] "RENALCLD"
#> 
#> $clr.pred.dn$pptest_cdisc
#> [1] "Renal CL by Dose"
#> 
#> $clr.pred.dn$formula
#> [1] "$CL_{R,\\text{pred},dn} = \\frac{CL_{R,\\text{pred}}}{Dose}$"
#> 
#> $clr.pred.dn$formula_note
#> NULL
#> 
#> $clr.pred.dn$tier
#> [1] "uncommon"
#> 
#> $clr.pred.dn$selection
#> list()
#> 
#> 
```
