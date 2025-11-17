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

[`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md)
and the vignette "Selection of Calculation Intervals"

Other Interval specifications:
[`add.interval.col()`](http://humanpred.github.io/pknca/reference/add.interval.col.md),
[`check.interval.deps()`](http://humanpred.github.io/pknca/reference/check.interval.deps.md),
[`check.interval.specification()`](http://humanpred.github.io/pknca/reference/check.interval.specification.md),
[`choose.auc.intervals()`](http://humanpred.github.io/pknca/reference/choose.auc.intervals.md),
[`get.parameter.deps()`](http://humanpred.github.io/pknca/reference/get.parameter.deps.md)

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
#> [1] "Ending time of the interval (potentially infinity)"
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
#> [1] "The area under the concentration time curve from the beginning of the interval to the last concentration above the limit of quantification"
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
#> [1] "The area under the concentration time curve from the beginning of the interval to the last concentration above the limit of quantification plus the triangle from that last concentration to 0 at the first concentration below the limit of quantification"
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
#> [1] "The area under the concentration time moment curve from the beginning of the interval to the last concentration above the limit of quantification"
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
#> [1] "The area under the concentration time moment curve from the beginning of the interval to the last concentration above the limit of quantification plus the moment of the triangle from that last concentration to 0 at the first concentration below the limit of quantification"
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
#> [1] "The area under the concentration time curve in the interval extrapolating from Tlast to infinity with zeros (matching AUClast)"
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
#> [1] "The area under the concentration time curve in the interval extrapolating from Tlast to infinity with zeros (matching AUClast) with dose-aware interpolation/extrapolation of concentrations"
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
#> [1] "The area under the concentration time curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUCall)"
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
#> [1] "The area under the concentration time curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUCall) with dose-aware interpolation/extrapolation of concentrations"
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
#> [1] "Initial concentration after an IV bolus"
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
#> [1] "Time of the maximum observed concentration"
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
#> [1] "Time of the last concentration observed above the limit of quantification"
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
#> [1] "Time of the first concentration above the limit of quantification"
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
#> [1] "The last concentration observed above the limit of quantification"
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
#> [1] "Clearance or observed oral clearance calculated to Clast"
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
#> [1] "Clearance or observed oral clearance calculated with AUCall"
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
#> [1] "Bioavailability or relative bioavailability"
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
#> [1] "The mean residence time to the last observed concentration above the LOQ"
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
#> [1] "The mean residence time to the last observed concentration above the LOQ correcting for dosing duration"
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
#> [1] "The steady-state volume of distribution calculating through Tlast"
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
#> [1] "The steady-state volume of distribution with intravenous infusion calculating through Tlast"
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
#> [1] "The average concentration during an interval (calculated with AUClast)"
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
#> [1] "The average concentration during an interval (calculated with AUCint.last)"
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
#> [1] "The average concentration during an interval (calculated with AUCint.all)"
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
#> [1] "The trough (end of interval) concentration"
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
#> [1] "Peak-to-Trough ratio (fraction)"
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
#> [1] "The area under the concentration time the beginning of the interval to the last concentration above the limit of quantification plus the triangle from that last concentration to 0 at the first concentration below the limit of quantification, with a concentration subtracted from all concentrations and values below zero after subtraction set to zero"
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
#> [1] "The area under the concentration time the beginning of the interval to the last concentration above the limit of quantification plus the triangle from that last concentration to 0 at the first concentration below the limit of quantification, with a concentration subtracted from all concentrations and values below zero after subtraction set to zero"
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
#> [1] "Number of non-missing concentrations for an interval"
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
#> [1] "Number of measured and non BLQ/ALQ concentrations for an interval"
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
#> [1] "Total dose administered during an interval"
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
#> [1] "The amount excreted (typically into urine or feces)"
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
#> [1] "The renal clearance calculated using AUClast"
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
#> NULL
#> 
#> $clr.last$datatype
#> [1] "interval"
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
#> [1] "The renal clearance calculated using AUCinf,obs"
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
#> NULL
#> 
#> $clr.obs$datatype
#> [1] "interval"
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
#> [1] "The renal clearance calculated using AUCinf,pred"
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
#> NULL
#> 
#> $clr.pred$datatype
#> [1] "interval"
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
#> [1] "The fraction of the dose excreted"
#> 
#> $fe$sparse
#> [1] FALSE
#> 
#> $fe$formalsmap
#> list()
#> 
#> $fe$depends
#> NULL
#> 
#> $fe$datatype
#> [1] "interval"
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
#> [1] "For sparse PK sampling, the area under the concentration time curve from the beginning of the interval to the last concentration above the limit of quantification"
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
#> [1] "For sparse PK sampling, the standard error of the area under the concentration time curve from the beginning of the interval to the last concentration above the limit of quantification"
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
#> [1] "For sparse PK sampling, the standard error degrees of freedom of the area under the concentration time curve from the beginning of the interval to the last concentration above the limit of quantification"
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
#> [1] "The AUClast calculated with back-extrapolation for intravenous dosing using extrapolated C0"
#> 
#> $aucivlast$sparse
#> [1] FALSE
#> 
#> $aucivlast$formalsmap
#> $aucivlast$formalsmap$auc
#> [1] "auclast"
#> 
#> 
#> $aucivlast$depends
#> [1] "auclast" "c0"     
#> 
#> $aucivlast$datatype
#> [1] "interval"
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
#> [1] "The AUCall calculated with back-extrapolation for intravenous dosing using extrapolated C0"
#> 
#> $aucivall$sparse
#> [1] FALSE
#> 
#> $aucivall$formalsmap
#> $aucivall$formalsmap$auc
#> [1] "aucall"
#> 
#> 
#> $aucivall$depends
#> [1] "aucall" "c0"    
#> 
#> $aucivall$datatype
#> [1] "interval"
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
#> [1] "The AUCint,last calculated with back-extrapolation for intravenous dosing using extrapolated C0"
#> 
#> $aucivint.last$sparse
#> [1] FALSE
#> 
#> $aucivint.last$formalsmap
#> $aucivint.last$formalsmap$auc
#> [1] "aucint.last"
#> 
#> 
#> $aucivint.last$depends
#> [1] "aucint.last" "c0"         
#> 
#> $aucivint.last$datatype
#> [1] "interval"
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
#> [1] "The AUCint,all calculated with back-extrapolation for intravenous dosing using extrapolated C0"
#> 
#> $aucivint.all$sparse
#> [1] FALSE
#> 
#> $aucivint.all$formalsmap
#> $aucivint.all$formalsmap$auc
#> [1] "aucint.all"
#> 
#> 
#> $aucivint.all$depends
#> [1] "aucint.all" "c0"        
#> 
#> $aucivint.all$datatype
#> [1] "interval"
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
#> [1] "The back-extrapolation percent for intravenous dosing based on AUClast"
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
#> [1] "The back-extrapolation percent for intravenous dosing based on AUCall"
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
#> [1] "The back-extrapolation percent for intravenous dosing based on AUCint,last"
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
#> [1] "The back-extrapolation percent for intravenous dosing based on AUCint,all"
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
#> [1] "The r^2 value of the half-life calculation"
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
#> [1] "The adjusted r^2 value of the half-life calculation"
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
#> [1] "Correlation between time and log-concentration for lambda.z points"
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
#> [1] "The elimination rate of the terminal half-life"
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
#> [1] "The first time point used for the calculation of half-life"
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
#> [1] "The last time point used for the calculation of half-life"
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
#> [1] "The number of points used for the calculation of half-life"
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
#> [1] "The concentration at Tlast as predicted by the half-life"
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
#> [1] "The ratio of the half-life to the duration used for half-life calculation"
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
#> [1] "The effective half-life (as determined from the MRTlast)"
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
#> [1] "The effective half-life (as determined from the intravenous MRTlast)"
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
#> [1] "Elimination rate (as calculated from the MRT using AUClast)"
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
#> [1] "Elimination rate (as calculated from the intravenous MRTlast)"
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
#> [1] "The area under the concentration time curve from the beginning of the interval to infinity with extrapolation to infinity from the observed Clast"
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
#> [1] "The area under the concentration time curve from the beginning of the interval to infinity with extrapolation to infinity from the predicted Clast"
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
#> [1] "The area under the concentration time moment curve from the beginning of the interval to infinity with extrapolation to infinity from the observed Clast"
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
#> [1] "The area under the concentration time moment curve from the beginning of the interval to infinity with extrapolation to infinity from the predicted Clast"
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
#> [1] "The area under the concentration time curve in the interval extrapolating from Tlast to infinity with zeros (matching AUClast)"
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
#> [1] "The area under the concentration time curve in the interval extrapolating from Tlast to infinity with zeros (matching AUClast) with dose-aware interpolation/extrapolation of concentrations"
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
#> [1] "The area under the concentration time curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUCall)"
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
#> [1] "The area under the concentration time curve in the interval extrapolating from Tlast to infinity with the triangle from Tlast to the next point and zero thereafter (matching AUCall) with dose-aware interpolation/extrapolation of concentrations"
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
#> [1] "The AUCinf,obs calculated with back-extrapolation for intravenous dosing using extrapolated C0"
#> 
#> $aucivinf.obs$sparse
#> [1] FALSE
#> 
#> $aucivinf.obs$formalsmap
#> $aucivinf.obs$formalsmap$auc
#> [1] "aucinf.obs"
#> 
#> 
#> $aucivinf.obs$depends
#> [1] "aucinf.obs" "c0"        
#> 
#> $aucivinf.obs$datatype
#> [1] "interval"
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
#> [1] "The  calculated with back-extrapolation for intravenous dosing using extrapolated C0"
#> 
#> $aucivinf.pred$sparse
#> [1] FALSE
#> 
#> $aucivinf.pred$formalsmap
#> $aucivinf.pred$formalsmap$auc
#> [1] "aucinf.pred"
#> 
#> 
#> $aucivinf.pred$depends
#> [1] "aucinf.pred" "c0"         
#> 
#> $aucivinf.pred$datatype
#> [1] "interval"
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
#> [1] "The back-extrapolation percent for intravenous dosing based on AUCinf,obs"
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
#> [1] "The back-extrapolation percent for intravenous dosing based on AUCinf,pred"
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
#> [1] "Percent of the AUCinf that is extrapolated after Tlast calculated from the observed Clast"
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
#> [1] "Percent of the AUCinf that is extrapolated after Tlast calculated from the predicted Clast"
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
#> [1] "Clearance or observed oral clearance calculated with observed Clast"
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
#> [1] "Clearance or observed oral clearance calculated with predicted Clast"
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
#> [1] "The mean residence time to infinity using observed Clast"
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
#> [1] "The mean residence time to infinity using predicted Clast"
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
#> [1] "The mean residence time to infinity using observed Clast correcting for dosing duration"
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
#> [1] "The mean residence time to infinity using predicted Clast correcting for dosing duration"
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
#> [1] "The mean residence time with multiple dosing and nonlinear kinetics using observed Clast"
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
#> [1] "The mean residence time with multiple dosing and nonlinear kinetics using predicted Clast"
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
#> [1] "The terminal volume of distribution using observed Clast"
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
#> [1] "The terminal volume of distribution using predicted Clast"
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
#> [1] "The steady-state volume of distribution using observed Clast"
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
#> [1] "The steady-state volume of distribution using predicted Clast"
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
#> [1] "The steady-state volume of distribution with intravenous infusion using observed Clast"
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
#> [1] "The steady-state volume of distribution with intravenous infusion using predicted Clast"
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
#> [1] "The steady-state volume of distribution for nonlinear multiple-dose data using observed Clast"
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
#> [1] "The steady-state volume of distribution for nonlinear multiple-dose data using predicted Clast"
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
#> [1] "The average concentration during an interval (calculated with AUCint.inf.obs)"
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
#> [1] "The average concentration during an interval (calculated with AUCint.inf.pred)"
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
#> [1] "The effective half-life (as determined from the MRTobs)"
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
#> [1] "The effective half-life (as determined from the MRTpred)"
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
#> [1] "The effective half-life (as determined from the intravenous MRTobs)"
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
#> [1] "The effective half-life (as determined from the intravenous MRTpred)"
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
#> [1] "Elimination rate (as calculated from the MRT with observed Clast)"
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
#> [1] "Elimination rate (as calculated from the MRT with predicted Clast)"
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
#> [1] "Elimination rate (as calculated from the intravenous MRTobs)"
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
#> [1] "Elimination rate (as calculated from the intravenous MRTpred)"
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
#> 
```
