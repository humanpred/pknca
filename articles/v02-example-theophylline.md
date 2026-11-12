# Computing NCA Parameters for Theophylline

Examples simplify understanding. Below is an example of how to use the
theophylline dataset to generate NCA parameters.

## Load the data

``` r

## It is always a good idea to look at the data
knitr::kable(head(datasets::Theoph))
```

| Subject |   Wt | Dose | Time |  conc |
|:--------|-----:|-----:|-----:|------:|
| 1       | 79.6 | 4.02 | 0.00 |  0.74 |
| 1       | 79.6 | 4.02 | 0.25 |  2.84 |
| 1       | 79.6 | 4.02 | 0.57 |  6.57 |
| 1       | 79.6 | 4.02 | 1.12 | 10.50 |
| 1       | 79.6 | 4.02 | 2.02 |  9.66 |
| 1       | 79.6 | 4.02 | 3.82 |  8.58 |

The columns that we will be interested in for our analysis are conc,
Time, and Subject in the concentration data set and Dose, Time, and
Subject for the dosing data set. Note that `Dose` in the theophylline
dataset is in mg/kg rather than mg; the parameters calculated below do
not use the dose amount, but dose-dependent parameters (for example,
clearance, volume of distribution, or dose-normalized parameters) would
first require converting the dose to mg by multiplying by the subject’s
body weight (`Wt`).

``` r

## By default it is groupedData; convert it to a data frame for use
conc_obj <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)

## Dosing data needs to only have one row per dose, so subset for
## that first.
d_dose <- unique(datasets::Theoph[datasets::Theoph$Time == 0,
                                  c("Dose", "Time", "Subject")])
knitr::kable(d_dose,
             caption="Example dosing data extracted from theophylline data set")
```

|     | Dose | Time | Subject |
|:----|-----:|-----:|:--------|
| 1   | 4.02 |    0 | 1       |
| 12  | 4.40 |    0 | 2       |
| 23  | 4.53 |    0 | 3       |
| 34  | 4.40 |    0 | 4       |
| 45  | 5.86 |    0 | 5       |
| 56  | 4.00 |    0 | 6       |
| 67  | 4.95 |    0 | 7       |
| 78  | 4.53 |    0 | 8       |
| 89  | 3.10 |    0 | 9       |
| 100 | 5.50 |    0 | 10      |
| 111 | 4.92 |    0 | 11      |
| 122 | 5.30 |    0 | 12      |

Example dosing data extracted from theophylline data set {.table}

``` r

dose_obj <- PKNCAdose(d_dose, Dose~Time|Subject)
```

## Merge the Concentration and Dose

After loading the data, they must be combined to prepare for parameter
calculation. Intervals for calculation will automatically be selected
based on the `single.dose.aucs` setting in `PKNCA.options`

``` r

data_obj_automatic <- PKNCAdata(conc_obj, dose_obj)
knitr::kable(PKNCA.options("single.dose.aucs"))
```

| start | end | auclast | auclast_se | auclast_df | aucall | aucall_se | aucall_df | aumclast | aumclast_se | aumclast_df | aumcall | aumcall_se | aumcall_df | aucint.last | aucint.all | aumcint.last | aumcint.all | aucivint.last | aucivint.all | aucivpbext.int.last | aucivpbext.int.all | aumcivint.last | aumcivint.all | c0 | cmax | cmin | tmax | tmin | tlast | tfirst | clast.obs | cl.last | cl.all | cl.int.all | cl.int.last | cl.ivint.all | cl.ivint.last | mrt.last | mrt.all | mrt.int.all | mrt.int.last | mrt.iv.last | mrt.ivint.all | mrt.ivint.last | vss.last | vss.iv.last | vss.all | vss.int.all | vss.int.last | vss.ivint.all | vss.ivint.last | cav.last | cav.int.last | cav.int.all | cav.all | cav.ivint.last | cav.ivint.all | ctrough | cstart | ptr | tlag | deg.fluc | swing | ceoi | aucabove.predose.all | aucabove.trough.all | count.conc | count.conc.measured | totdose | volpk | ae | clr.last | clr.int.inf.pred | clr.int.inf.obs | clr.int.all | clr.int.last | clr.all | clr.inf.obs | clr.inf.pred | fe | ertlst | ermax | ertmax | erint | erlst | ratio.cmax | ratio.auclast | ratio.aucint.last | ratio.aucint.all | sparse_auclast | sparse_auc_se | sparse_auc_df | sparse_aumclast | sparse_aumc_se | sparse_aumc_df | time.above | aucivlast | aucivlast_se | aucivlast_df | aucivall | aucivall_se | aucivall_df | aucivpbext.last | aucivpbext.all | aumcivlast | aumcivlast_se | aumcivlast_df | aumcivall | aumcivall_se | aumcivall_df | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | tobit.residual | adj.tobit.residual | lambda.z.n.points.blq | thalf.eff.last | thalf.eff.int.all | thalf.eff.int.last | thalf.eff.all | thalf.eff.iv.last | thalf.eff.ivint.all | thalf.eff.ivint.last | kel.last | kel.iv.last | kel.all | kel.int.all | kel.int.last | kel.ivint.all | kel.ivint.last | cl.iv.all | cl.iv.last | cl.sparse.last | f.last | f.all | f.int.last | f.int.all | mrt.sparse.last | mrt.iv.all | vz.all | vz.int.all | vz.int.last | vz.iv.all | vz.iv.last | vz.ivint.all | vz.ivint.last | vz.last | vss.iv.all | vss.sparse.last | cav.iv.last | cav.iv.all | aucinf.obs | aucinf.obs_se | aucinf.obs_df | aucinf.pred | aumcinf.obs | aumcinf.obs_se | aumcinf.obs_df | aumcinf.pred | aucint.inf.obs | aucint.inf.pred | aumcint.inf.obs | aumcint.inf.pred | aucivint.inf.obs | aucivint.inf.pred | aucivinf.obs | aucivinf.obs_se | aucivinf.obs_df | aucivinf.pred | aucivpbext.inf.obs | aucivpbext.inf.pred | aumcivint.inf.pred | aumcivint.inf.obs | aumcivinf.obs | aumcivinf.obs_se | aumcivinf.obs_df | aumcivinf.pred | thalf.eff.iv.all | aucpext.inf.obs | aucpext.inf.pred | kel.iv.all | kel.sparse.last | cl.inf.obs | cl.inf.pred | cl.int.inf.obs | cl.int.inf.pred | cl.iv.inf.obs | cl.iv.inf.pred | cl.ivint.inf.pred | cl.ivint.inf.obs | f.inf.obs | f.inf.pred | f.int.inf.obs | f.int.inf.pred | mrt.inf.obs | mrt.inf.pred | mrt.int.inf.obs | mrt.int.inf.pred | mrt.iv.inf.obs | mrt.iv.inf.pred | mrt.ivint.inf.pred | mrt.ivint.inf.obs | mrt.md.inf.obs | mrt.md.inf.pred | mrt.ivmd.inf.obs | mrt.ivmd.inf.pred | vz.inf.obs | vz.inf.pred | vz.int.inf.obs | vz.int.inf.pred | vz.iv.inf.obs | vz.iv.inf.pred | vz.ivint.inf.pred | vz.ivint.inf.obs | vz.sparse.last | vss.inf.obs | vss.inf.pred | vss.iv.inf.obs | vss.iv.inf.pred | vss.md.inf.obs | vss.md.inf.pred | vss.ivmd.inf.obs | vss.ivmd.inf.pred | vss.int.inf.obs | vss.int.inf.pred | vss.ivint.inf.pred | vss.ivint.inf.obs | cav.int.inf.obs | cav.int.inf.pred | cav.ivint.inf.obs | cav.ivint.inf.pred | ratio.aucinf.obs | ratio.aucinf.pred | thalf.eff.inf.obs | thalf.eff.inf.pred | thalf.eff.int.inf.pred | thalf.eff.int.inf.obs | thalf.eff.iv.inf.obs | thalf.eff.iv.inf.pred | thalf.eff.ivint.inf.pred | thalf.eff.ivint.inf.obs | kel.inf.obs | kel.inf.pred | kel.iv.inf.obs | kel.iv.inf.pred | kel.int.inf.obs | kel.int.inf.pred | kel.ivint.inf.pred | kel.ivint.inf.obs | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.last.dn | ctrough.dn | adj_tobit_residual | aucivpbextall | aucivpbextinf.obs | aucivpbextinf.pred | aucivpbextint.all | aucivpbextint.last | aucivpbextlast | aucpext.obs | aucpext.pred | cav | cav.dn | cl.iv.obs | cl.iv.pred | cl.obs | cl.pred | clr.obs | clr.pred | count_conc | count_conc_measured | f.int.obs | f.int.pred | f.obs | f.pred | kel.iv.obs | kel.iv.pred | kel.obs | kel.pred | lambda.z.n.points_blq | mrt.iv.obs | mrt.iv.pred | mrt.ivmd.obs | mrt.ivmd.pred | mrt.md.obs | mrt.md.pred | mrt.obs | mrt.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | thalf.eff.obs | thalf.eff.pred | time_above | tobit_residual | vss.iv.obs | vss.iv.pred | vss.ivmd.obs | vss.ivmd.pred | vss.md.obs | vss.md.pred | vss.obs | vss.pred | vz.iv.obs | vz.iv.pred | vz.obs | vz.pred |
|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 0 | 24 | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE |
| 0 | Inf | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE |

``` r

knitr::kable(data_obj_automatic$intervals)
```

| start | end | auclast | auclast_se | auclast_df | aucall | aucall_se | aucall_df | aumclast | aumclast_se | aumclast_df | aumcall | aumcall_se | aumcall_df | aucint.last | aucint.all | aumcint.last | aumcint.all | aucivint.last | aucivint.all | aucivpbext.int.last | aucivpbext.int.all | aumcivint.last | aumcivint.all | c0 | cmax | cmin | tmax | tmin | tlast | tfirst | clast.obs | cl.last | cl.all | cl.int.all | cl.int.last | cl.ivint.all | cl.ivint.last | mrt.last | mrt.all | mrt.int.all | mrt.int.last | mrt.iv.last | mrt.ivint.all | mrt.ivint.last | vss.last | vss.iv.last | vss.all | vss.int.all | vss.int.last | vss.ivint.all | vss.ivint.last | cav.last | cav.int.last | cav.int.all | cav.all | cav.ivint.last | cav.ivint.all | ctrough | cstart | ptr | tlag | deg.fluc | swing | ceoi | aucabove.predose.all | aucabove.trough.all | count.conc | count.conc.measured | totdose | volpk | ae | clr.last | clr.int.inf.pred | clr.int.inf.obs | clr.int.all | clr.int.last | clr.all | clr.inf.obs | clr.inf.pred | fe | ertlst | ermax | ertmax | erint | erlst | ratio.cmax | ratio.auclast | ratio.aucint.last | ratio.aucint.all | sparse_auclast | sparse_auc_se | sparse_auc_df | sparse_aumclast | sparse_aumc_se | sparse_aumc_df | time.above | aucivlast | aucivlast_se | aucivlast_df | aucivall | aucivall_se | aucivall_df | aucivpbext.last | aucivpbext.all | aumcivlast | aumcivlast_se | aumcivlast_df | aumcivall | aumcivall_se | aumcivall_df | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | tobit.residual | adj.tobit.residual | lambda.z.n.points.blq | thalf.eff.last | thalf.eff.int.all | thalf.eff.int.last | thalf.eff.all | thalf.eff.iv.last | thalf.eff.ivint.all | thalf.eff.ivint.last | kel.last | kel.iv.last | kel.all | kel.int.all | kel.int.last | kel.ivint.all | kel.ivint.last | cl.iv.all | cl.iv.last | cl.sparse.last | f.last | f.all | f.int.last | f.int.all | mrt.sparse.last | mrt.iv.all | vz.all | vz.int.all | vz.int.last | vz.iv.all | vz.iv.last | vz.ivint.all | vz.ivint.last | vz.last | vss.iv.all | vss.sparse.last | cav.iv.last | cav.iv.all | aucinf.obs | aucinf.obs_se | aucinf.obs_df | aucinf.pred | aumcinf.obs | aumcinf.obs_se | aumcinf.obs_df | aumcinf.pred | aucint.inf.obs | aucint.inf.pred | aumcint.inf.obs | aumcint.inf.pred | aucivint.inf.obs | aucivint.inf.pred | aucivinf.obs | aucivinf.obs_se | aucivinf.obs_df | aucivinf.pred | aucivpbext.inf.obs | aucivpbext.inf.pred | aumcivint.inf.pred | aumcivint.inf.obs | aumcivinf.obs | aumcivinf.obs_se | aumcivinf.obs_df | aumcivinf.pred | thalf.eff.iv.all | aucpext.inf.obs | aucpext.inf.pred | kel.iv.all | kel.sparse.last | cl.inf.obs | cl.inf.pred | cl.int.inf.obs | cl.int.inf.pred | cl.iv.inf.obs | cl.iv.inf.pred | cl.ivint.inf.pred | cl.ivint.inf.obs | f.inf.obs | f.inf.pred | f.int.inf.obs | f.int.inf.pred | mrt.inf.obs | mrt.inf.pred | mrt.int.inf.obs | mrt.int.inf.pred | mrt.iv.inf.obs | mrt.iv.inf.pred | mrt.ivint.inf.pred | mrt.ivint.inf.obs | mrt.md.inf.obs | mrt.md.inf.pred | mrt.ivmd.inf.obs | mrt.ivmd.inf.pred | vz.inf.obs | vz.inf.pred | vz.int.inf.obs | vz.int.inf.pred | vz.iv.inf.obs | vz.iv.inf.pred | vz.ivint.inf.pred | vz.ivint.inf.obs | vz.sparse.last | vss.inf.obs | vss.inf.pred | vss.iv.inf.obs | vss.iv.inf.pred | vss.md.inf.obs | vss.md.inf.pred | vss.ivmd.inf.obs | vss.ivmd.inf.pred | vss.int.inf.obs | vss.int.inf.pred | vss.ivint.inf.pred | vss.ivint.inf.obs | cav.int.inf.obs | cav.int.inf.pred | cav.ivint.inf.obs | cav.ivint.inf.pred | ratio.aucinf.obs | ratio.aucinf.pred | thalf.eff.inf.obs | thalf.eff.inf.pred | thalf.eff.int.inf.pred | thalf.eff.int.inf.obs | thalf.eff.iv.inf.obs | thalf.eff.iv.inf.pred | thalf.eff.ivint.inf.pred | thalf.eff.ivint.inf.obs | kel.inf.obs | kel.inf.pred | kel.iv.inf.obs | kel.iv.inf.pred | kel.int.inf.obs | kel.int.inf.pred | kel.ivint.inf.pred | kel.ivint.inf.obs | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.last.dn | ctrough.dn | adj_tobit_residual | aucivpbextall | aucivpbextinf.obs | aucivpbextinf.pred | aucivpbextint.all | aucivpbextint.last | aucivpbextlast | aucpext.obs | aucpext.pred | cav | cav.dn | cl.iv.obs | cl.iv.pred | cl.obs | cl.pred | clr.obs | clr.pred | count_conc | count_conc_measured | f.int.obs | f.int.pred | f.obs | f.pred | kel.iv.obs | kel.iv.pred | kel.obs | kel.pred | lambda.z.n.points_blq | mrt.iv.obs | mrt.iv.pred | mrt.ivmd.obs | mrt.ivmd.pred | mrt.md.obs | mrt.md.pred | mrt.obs | mrt.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | thalf.eff.obs | thalf.eff.pred | time_above | tobit_residual | vss.iv.obs | vss.iv.pred | vss.ivmd.obs | vss.ivmd.pred | vss.md.obs | vss.md.pred | vss.obs | vss.pred | vz.iv.obs | vz.iv.pred | vz.obs | vz.pred | Subject | impute |
|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 1 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 2 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 3 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 4 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 5 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 6 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 7 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 8 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 9 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 10 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 11 | start_predose_conc0 |
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | 12 | start_predose_conc0 |

Intervals for calculation can also be specified manually. Manual
specification requires at least columns for `start` time, `end` time,
and the parameters requested. The manual specification can also include
any grouping factors from the concentration data set. Column order of
the intervals is not important. When intervals are manually specified,
they are expanded to the full interval set when added to a PKNCAdata
object (in other words, a column is created for each parameter). Also,
PKNCA automatically calculates parameters required for the NCA, so while
lambda.z is required for calculating AUC_(0-$`\infty`$), you do not have
to specify it in the parameters requested.

``` r

intervals_manual <- data.frame(start=0,
                               end=Inf,
                               cmax=TRUE,
                               tmax=TRUE,
                               aucinf.obs=TRUE,
                               auclast=TRUE)
data_obj_manual <- PKNCAdata(conc_obj, dose_obj,
                             intervals=intervals_manual)
knitr::kable(data_obj_manual$intervals)
```

| start | end | auclast | auclast_se | auclast_df | aucall | aucall_se | aucall_df | aumclast | aumclast_se | aumclast_df | aumcall | aumcall_se | aumcall_df | aucint.last | aucint.all | aumcint.last | aumcint.all | aucivint.last | aucivint.all | aucivpbext.int.last | aucivpbext.int.all | aumcivint.last | aumcivint.all | c0 | cmax | cmin | tmax | tmin | tlast | tfirst | clast.obs | cl.last | cl.all | cl.int.all | cl.int.last | cl.ivint.all | cl.ivint.last | mrt.last | mrt.all | mrt.int.all | mrt.int.last | mrt.iv.last | mrt.ivint.all | mrt.ivint.last | vss.last | vss.iv.last | vss.all | vss.int.all | vss.int.last | vss.ivint.all | vss.ivint.last | cav.last | cav.int.last | cav.int.all | cav.all | cav.ivint.last | cav.ivint.all | ctrough | cstart | ptr | tlag | deg.fluc | swing | ceoi | aucabove.predose.all | aucabove.trough.all | count.conc | count.conc.measured | totdose | volpk | ae | clr.last | clr.int.inf.pred | clr.int.inf.obs | clr.int.all | clr.int.last | clr.all | clr.inf.obs | clr.inf.pred | fe | ertlst | ermax | ertmax | erint | erlst | ratio.cmax | ratio.auclast | ratio.aucint.last | ratio.aucint.all | sparse_auclast | sparse_auc_se | sparse_auc_df | sparse_aumclast | sparse_aumc_se | sparse_aumc_df | time.above | aucivlast | aucivlast_se | aucivlast_df | aucivall | aucivall_se | aucivall_df | aucivpbext.last | aucivpbext.all | aumcivlast | aumcivlast_se | aumcivlast_df | aumcivall | aumcivall_se | aumcivall_df | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | tobit.residual | adj.tobit.residual | lambda.z.n.points.blq | thalf.eff.last | thalf.eff.int.all | thalf.eff.int.last | thalf.eff.all | thalf.eff.iv.last | thalf.eff.ivint.all | thalf.eff.ivint.last | kel.last | kel.iv.last | kel.all | kel.int.all | kel.int.last | kel.ivint.all | kel.ivint.last | cl.iv.all | cl.iv.last | cl.sparse.last | f.last | f.all | f.int.last | f.int.all | mrt.sparse.last | mrt.iv.all | vz.all | vz.int.all | vz.int.last | vz.iv.all | vz.iv.last | vz.ivint.all | vz.ivint.last | vz.last | vss.iv.all | vss.sparse.last | cav.iv.last | cav.iv.all | aucinf.obs | aucinf.obs_se | aucinf.obs_df | aucinf.pred | aumcinf.obs | aumcinf.obs_se | aumcinf.obs_df | aumcinf.pred | aucint.inf.obs | aucint.inf.pred | aumcint.inf.obs | aumcint.inf.pred | aucivint.inf.obs | aucivint.inf.pred | aucivinf.obs | aucivinf.obs_se | aucivinf.obs_df | aucivinf.pred | aucivpbext.inf.obs | aucivpbext.inf.pred | aumcivint.inf.pred | aumcivint.inf.obs | aumcivinf.obs | aumcivinf.obs_se | aumcivinf.obs_df | aumcivinf.pred | thalf.eff.iv.all | aucpext.inf.obs | aucpext.inf.pred | kel.iv.all | kel.sparse.last | cl.inf.obs | cl.inf.pred | cl.int.inf.obs | cl.int.inf.pred | cl.iv.inf.obs | cl.iv.inf.pred | cl.ivint.inf.pred | cl.ivint.inf.obs | f.inf.obs | f.inf.pred | f.int.inf.obs | f.int.inf.pred | mrt.inf.obs | mrt.inf.pred | mrt.int.inf.obs | mrt.int.inf.pred | mrt.iv.inf.obs | mrt.iv.inf.pred | mrt.ivint.inf.pred | mrt.ivint.inf.obs | mrt.md.inf.obs | mrt.md.inf.pred | mrt.ivmd.inf.obs | mrt.ivmd.inf.pred | vz.inf.obs | vz.inf.pred | vz.int.inf.obs | vz.int.inf.pred | vz.iv.inf.obs | vz.iv.inf.pred | vz.ivint.inf.pred | vz.ivint.inf.obs | vz.sparse.last | vss.inf.obs | vss.inf.pred | vss.iv.inf.obs | vss.iv.inf.pred | vss.md.inf.obs | vss.md.inf.pred | vss.ivmd.inf.obs | vss.ivmd.inf.pred | vss.int.inf.obs | vss.int.inf.pred | vss.ivint.inf.pred | vss.ivint.inf.obs | cav.int.inf.obs | cav.int.inf.pred | cav.ivint.inf.obs | cav.ivint.inf.pred | ratio.aucinf.obs | ratio.aucinf.pred | thalf.eff.inf.obs | thalf.eff.inf.pred | thalf.eff.int.inf.pred | thalf.eff.int.inf.obs | thalf.eff.iv.inf.obs | thalf.eff.iv.inf.pred | thalf.eff.ivint.inf.pred | thalf.eff.ivint.inf.obs | kel.inf.obs | kel.inf.pred | kel.iv.inf.obs | kel.iv.inf.pred | kel.int.inf.obs | kel.int.inf.pred | kel.ivint.inf.pred | kel.ivint.inf.obs | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.last.dn | ctrough.dn | adj_tobit_residual | aucivpbextall | aucivpbextinf.obs | aucivpbextinf.pred | aucivpbextint.all | aucivpbextint.last | aucivpbextlast | aucpext.obs | aucpext.pred | cav | cav.dn | cl.iv.obs | cl.iv.pred | cl.obs | cl.pred | clr.obs | clr.pred | count_conc | count_conc_measured | f.int.obs | f.int.pred | f.obs | f.pred | kel.iv.obs | kel.iv.pred | kel.obs | kel.pred | lambda.z.n.points_blq | mrt.iv.obs | mrt.iv.pred | mrt.ivmd.obs | mrt.ivmd.pred | mrt.md.obs | mrt.md.pred | mrt.obs | mrt.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | thalf.eff.obs | thalf.eff.pred | time_above | tobit_residual | vss.iv.obs | vss.iv.pred | vss.ivmd.obs | vss.ivmd.pred | vss.md.obs | vss.md.pred | vss.obs | vss.pred | vz.iv.obs | vz.iv.pred | vz.obs | vz.pred |
|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 0 | Inf | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE |

## Compute the parameters

Parameter calculation will automatically split the data by the grouping
factor(s), subset by the interval, calculate all required parameters,
record all options used for the calculations, and include data
provenance to show that the calculation was performed as described. For
all this, just call the `pk.nca` function with your PKNCAdata object.

``` r

results_obj_automatic <- pk.nca(data_obj_automatic)
knitr::kable(head(as.data.frame(results_obj_automatic)))
```

| Subject | start | end | PPTESTCD | PPORRES | PPANMETH | exclude |
|:---|---:|---:|:---|---:|:---|:---|
| 1 | 0 | Inf | auclast | 147.2347 | Imputation: start_predose_conc0. AUC: lin up/log down | NA |
| 1 | 0 | Inf | cmax | 10.5000 | Imputation: start_predose_conc0 | NA |
| 1 | 0 | Inf | tmax | 1.1200 | Imputation: start_predose_conc0 | NA |
| 1 | 0 | Inf | tlast | 24.3700 | Imputation: start_predose_conc0 | NA |
| 1 | 0 | Inf | clast.obs | 3.2800 | Imputation: start_predose_conc0 | NA |
| 1 | 0 | Inf | tlag | 0.0000 | Imputation: start_predose_conc0 | NA |

``` r

summary(results_obj_automatic)
```

| start | end | N | auclast | cmax | tmax | tlag | count.conc | half.life | aucinf.obs | aucpext.inf.obs | cl.inf.obs |
|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 0 | Inf | 12 | 98.7 \[22.5\] | 8.65 \[17.0\] | 1.14 \[0.630, 3.55\] | 0.000 \[0.000, 0.000\] | 11.0 \[11.0, 11.0\] | 8.18 \[2.12\] | 115 \[28.4\] | 13.8 \[6.34\] | 0.0398 \[29.4\] |

``` r

results_obj_manual <- pk.nca(data_obj_manual)
knitr::kable(head(as.data.frame(results_obj_manual)))
```

| Subject | start | end | PPTESTCD  |    PPORRES | PPANMETH             | exclude |
|:--------|------:|----:|:----------|-----------:|:---------------------|:--------|
| 6       |     0 | Inf | auclast   | 71.6970150 | AUC: lin up/log down | NA      |
| 6       |     0 | Inf | cmax      |  6.4400000 |                      | NA      |
| 6       |     0 | Inf | tmax      |  1.1500000 |                      | NA      |
| 6       |     0 | Inf | tlast     | 23.8500000 |                      | NA      |
| 6       |     0 | Inf | clast.obs |  0.9200000 |                      | NA      |
| 6       |     0 | Inf | lambda.z  |  0.0877957 |                      | NA      |

``` r

summary(results_obj_manual)
```

| start | end | N   | auclast       | cmax          | tmax                 | aucinf.obs   |
|------:|----:|:----|:--------------|:--------------|:---------------------|:-------------|
|     0 | Inf | 12  | 98.7 \[22.5\] | 8.65 \[17.0\] | 1.14 \[0.630, 3.55\] | 115 \[28.4\] |

## Multiple Dose Example

Assessing multiple dose pharmacokinetics is conceptually the same as
single-dose in PKNCA.

To assess multiple dose PK, the theophylline data will be extended from
single to multiple doses using superposition (see the
[superposition](https://humanpred.github.io/pknca/articles/v20-superposition.md)
vignette for more information).

``` r

conc_obj <- PKNCAconc(as.data.frame(datasets::Theoph), conc~Time|Subject)
conc_obj_multi <-
  PKNCAconc(
    superposition(conc_obj,
                  tau=168,
                  dose.times=seq(0, 144, by=24),
                  n.tau=1,
                  check.blq=FALSE),
    conc~time|Subject)
conc_obj_multi
```

    ## Formula for concentration:
    ##  conc ~ time | Subject
    ## Data are dense PK.
    ## With 12 subjects defined in the 'Subject' column.
    ## Nominal time column is not specified.
    ## 
    ## First 6 rows of concentration data:
    ##  Subject     conc time exclude
    ##        1  0.74000 0.00    <NA>
    ##        1  2.84000 0.25    <NA>
    ##        1  4.23875 0.37    <NA>
    ##        1  6.57000 0.57    <NA>
    ##        1 10.50000 1.12    <NA>
    ##        1  9.66000 2.02    <NA>

``` r

dose_obj_multi <- PKNCAdose(expand.grid(Subject=unique(as.data.frame(conc_obj_multi)$Subject),
                                      time=seq(0, 144, by=24)),
                          ~time|Subject)
dose_obj_multi
```

    ## Formula for dosing:
    ##  ~time | Subject
    ## Nominal time column is not specified.
    ## 
    ## First 6 rows of dosing data:
    ##  Subject time exclude         route duration
    ##        1    0    <NA> extravascular        0
    ##        2    0    <NA> extravascular        0
    ##        3    0    <NA> extravascular        0
    ##        4    0    <NA> extravascular        0
    ##        5    0    <NA> extravascular        0
    ##        6    0    <NA> extravascular        0

The superposition-simulated scenario is not especially realistic as it
includes dense sampling on every day. With this scenario, the intervals
automatically selected have an interval for every subject on every day.

``` r

data_obj <- PKNCAdata(conc_obj_multi, dose_obj_multi)
data_obj$intervals[,c("Subject", "start", "end")]
```

    ## # A tibble: 84 × 3
    ##    Subject start   end
    ##    <ord>   <dbl> <dbl>
    ##  1 1           0    24
    ##  2 1          24    48
    ##  3 1          48    72
    ##  4 1          72    96
    ##  5 1          96   120
    ##  6 1         120   144
    ##  7 1         144   168
    ##  8 2           0    24
    ##  9 2          24    48
    ## 10 2          48    72
    ## # ℹ 74 more rows

In a more realistic scenario, dense PK sampling occurs for every subject
on the first and last days. To select those intervals manually, specify
the intervals of interest in the `intervals` argument to the PKNCAdata
function call. The intervals are automatically expanded not to calculate
anything that was not requested.

``` r

intervals_manual <- data.frame(start=c(0, 144),
                               end=c(24, 168),
                               cmax=TRUE,
                               auclast=TRUE)
data_obj <- PKNCAdata(conc_obj_multi, dose_obj_multi,
                      intervals=intervals_manual)
data_obj$intervals
```

    ##   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
    ## 1     0  24    TRUE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
    ## 2   144 168    TRUE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
    ##   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
    ## 1       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
    ## 2       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
    ##   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbext.int.last
    ## 1        FALSE       FALSE         FALSE        FALSE               FALSE
    ## 2        FALSE       FALSE         FALSE        FALSE               FALSE
    ##   aucivpbext.int.all aumcivint.last aumcivint.all    c0 cmax  cmin  tmax  tmin
    ## 1              FALSE          FALSE         FALSE FALSE TRUE FALSE FALSE FALSE
    ## 2              FALSE          FALSE         FALSE FALSE TRUE FALSE FALSE FALSE
    ##   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
    ## 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
    ## 2 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
    ##   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
    ## 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
    ## 2         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
    ##   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
    ## 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
    ## 2         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
    ##   vss.int.last vss.ivint.all vss.ivint.last cav.last cav.int.last cav.int.all
    ## 1        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
    ## 2        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
    ##   cav.all cav.ivint.last cav.ivint.all ctrough cstart   ptr  tlag deg.fluc
    ## 1   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE    FALSE
    ## 2   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE    FALSE
    ##   swing  ceoi aucabove.predose.all aucabove.trough.all count.conc
    ## 1 FALSE FALSE                FALSE               FALSE      FALSE
    ## 2 FALSE FALSE                FALSE               FALSE      FALSE
    ##   count.conc.measured totdose volpk    ae clr.last clr.int.inf.pred
    ## 1               FALSE   FALSE FALSE FALSE    FALSE            FALSE
    ## 2               FALSE   FALSE FALSE FALSE    FALSE            FALSE
    ##   clr.int.inf.obs clr.int.all clr.int.last clr.all clr.inf.obs clr.inf.pred
    ## 1           FALSE       FALSE        FALSE   FALSE       FALSE        FALSE
    ## 2           FALSE       FALSE        FALSE   FALSE       FALSE        FALSE
    ##      fe ertlst ermax ertmax erint erlst ratio.cmax ratio.auclast
    ## 1 FALSE  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE
    ## 2 FALSE  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE
    ##   ratio.aucint.last ratio.aucint.all sparse_auclast sparse_auc_se sparse_auc_df
    ## 1             FALSE            FALSE          FALSE         FALSE         FALSE
    ## 2             FALSE            FALSE          FALSE         FALSE         FALSE
    ##   sparse_aumclast sparse_aumc_se sparse_aumc_df time.above aucivlast
    ## 1           FALSE          FALSE          FALSE      FALSE     FALSE
    ## 2           FALSE          FALSE          FALSE      FALSE     FALSE
    ##   aucivlast_se aucivlast_df aucivall aucivall_se aucivall_df aucivpbext.last
    ## 1        FALSE        FALSE    FALSE       FALSE       FALSE           FALSE
    ## 2        FALSE        FALSE    FALSE       FALSE       FALSE           FALSE
    ##   aucivpbext.all aumcivlast aumcivlast_se aumcivlast_df aumcivall aumcivall_se
    ## 1          FALSE      FALSE         FALSE         FALSE     FALSE        FALSE
    ## 2          FALSE      FALSE         FALSE         FALSE     FALSE        FALSE
    ##   aumcivall_df half.life r.squared adj.r.squared lambda.z.corrxy lambda.z
    ## 1        FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
    ## 2        FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
    ##   lambda.z.time.first lambda.z.time.last lambda.z.n.points clast.pred
    ## 1               FALSE              FALSE             FALSE      FALSE
    ## 2               FALSE              FALSE             FALSE      FALSE
    ##   span.ratio tobit.residual adj.tobit.residual lambda.z.n.points.blq
    ## 1      FALSE          FALSE              FALSE                 FALSE
    ## 2      FALSE          FALSE              FALSE                 FALSE
    ##   thalf.eff.last thalf.eff.int.all thalf.eff.int.last thalf.eff.all
    ## 1          FALSE             FALSE              FALSE         FALSE
    ## 2          FALSE             FALSE              FALSE         FALSE
    ##   thalf.eff.iv.last thalf.eff.ivint.all thalf.eff.ivint.last kel.last
    ## 1             FALSE               FALSE                FALSE    FALSE
    ## 2             FALSE               FALSE                FALSE    FALSE
    ##   kel.iv.last kel.all kel.int.all kel.int.last kel.ivint.all kel.ivint.last
    ## 1       FALSE   FALSE       FALSE        FALSE         FALSE          FALSE
    ## 2       FALSE   FALSE       FALSE        FALSE         FALSE          FALSE
    ##   cl.iv.all cl.iv.last cl.sparse.last f.last f.all f.int.last f.int.all
    ## 1     FALSE      FALSE          FALSE  FALSE FALSE      FALSE     FALSE
    ## 2     FALSE      FALSE          FALSE  FALSE FALSE      FALSE     FALSE
    ##   mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last vz.iv.all vz.iv.last
    ## 1           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
    ## 2           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
    ##   vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.sparse.last cav.iv.last
    ## 1        FALSE         FALSE   FALSE      FALSE           FALSE       FALSE
    ## 2        FALSE         FALSE   FALSE      FALSE           FALSE       FALSE
    ##   cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred aumcinf.obs
    ## 1      FALSE      FALSE         FALSE         FALSE       FALSE       FALSE
    ## 2      FALSE      FALSE         FALSE         FALSE       FALSE       FALSE
    ##   aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs aucint.inf.pred
    ## 1          FALSE          FALSE        FALSE          FALSE           FALSE
    ## 2          FALSE          FALSE        FALSE          FALSE           FALSE
    ##   aumcint.inf.obs aumcint.inf.pred aucivint.inf.obs aucivint.inf.pred
    ## 1           FALSE            FALSE            FALSE             FALSE
    ## 2           FALSE            FALSE            FALSE             FALSE
    ##   aucivinf.obs aucivinf.obs_se aucivinf.obs_df aucivinf.pred aucivpbext.inf.obs
    ## 1        FALSE           FALSE           FALSE         FALSE              FALSE
    ## 2        FALSE           FALSE           FALSE         FALSE              FALSE
    ##   aucivpbext.inf.pred aumcivint.inf.pred aumcivint.inf.obs aumcivinf.obs
    ## 1               FALSE              FALSE             FALSE         FALSE
    ## 2               FALSE              FALSE             FALSE         FALSE
    ##   aumcivinf.obs_se aumcivinf.obs_df aumcivinf.pred thalf.eff.iv.all
    ## 1            FALSE            FALSE          FALSE            FALSE
    ## 2            FALSE            FALSE          FALSE            FALSE
    ##   aucpext.inf.obs aucpext.inf.pred kel.iv.all kel.sparse.last cl.inf.obs
    ## 1           FALSE            FALSE      FALSE           FALSE      FALSE
    ## 2           FALSE            FALSE      FALSE           FALSE      FALSE
    ##   cl.inf.pred cl.int.inf.obs cl.int.inf.pred cl.iv.inf.obs cl.iv.inf.pred
    ## 1       FALSE          FALSE           FALSE         FALSE          FALSE
    ## 2       FALSE          FALSE           FALSE         FALSE          FALSE
    ##   cl.ivint.inf.pred cl.ivint.inf.obs f.inf.obs f.inf.pred f.int.inf.obs
    ## 1             FALSE            FALSE     FALSE      FALSE         FALSE
    ## 2             FALSE            FALSE     FALSE      FALSE         FALSE
    ##   f.int.inf.pred mrt.inf.obs mrt.inf.pred mrt.int.inf.obs mrt.int.inf.pred
    ## 1          FALSE       FALSE        FALSE           FALSE            FALSE
    ## 2          FALSE       FALSE        FALSE           FALSE            FALSE
    ##   mrt.iv.inf.obs mrt.iv.inf.pred mrt.ivint.inf.pred mrt.ivint.inf.obs
    ## 1          FALSE           FALSE              FALSE             FALSE
    ## 2          FALSE           FALSE              FALSE             FALSE
    ##   mrt.md.inf.obs mrt.md.inf.pred mrt.ivmd.inf.obs mrt.ivmd.inf.pred vz.inf.obs
    ## 1          FALSE           FALSE            FALSE             FALSE      FALSE
    ## 2          FALSE           FALSE            FALSE             FALSE      FALSE
    ##   vz.inf.pred vz.int.inf.obs vz.int.inf.pred vz.iv.inf.obs vz.iv.inf.pred
    ## 1       FALSE          FALSE           FALSE         FALSE          FALSE
    ## 2       FALSE          FALSE           FALSE         FALSE          FALSE
    ##   vz.ivint.inf.pred vz.ivint.inf.obs vz.sparse.last vss.inf.obs vss.inf.pred
    ## 1             FALSE            FALSE          FALSE       FALSE        FALSE
    ## 2             FALSE            FALSE          FALSE       FALSE        FALSE
    ##   vss.iv.inf.obs vss.iv.inf.pred vss.md.inf.obs vss.md.inf.pred
    ## 1          FALSE           FALSE          FALSE           FALSE
    ## 2          FALSE           FALSE          FALSE           FALSE
    ##   vss.ivmd.inf.obs vss.ivmd.inf.pred vss.int.inf.obs vss.int.inf.pred
    ## 1            FALSE             FALSE           FALSE            FALSE
    ## 2            FALSE             FALSE           FALSE            FALSE
    ##   vss.ivint.inf.pred vss.ivint.inf.obs cav.int.inf.obs cav.int.inf.pred
    ## 1              FALSE             FALSE           FALSE            FALSE
    ## 2              FALSE             FALSE           FALSE            FALSE
    ##   cav.ivint.inf.obs cav.ivint.inf.pred ratio.aucinf.obs ratio.aucinf.pred
    ## 1             FALSE              FALSE            FALSE             FALSE
    ## 2             FALSE              FALSE            FALSE             FALSE
    ##   thalf.eff.inf.obs thalf.eff.inf.pred thalf.eff.int.inf.pred
    ## 1             FALSE              FALSE                  FALSE
    ## 2             FALSE              FALSE                  FALSE
    ##   thalf.eff.int.inf.obs thalf.eff.iv.inf.obs thalf.eff.iv.inf.pred
    ## 1                 FALSE                FALSE                 FALSE
    ## 2                 FALSE                FALSE                 FALSE
    ##   thalf.eff.ivint.inf.pred thalf.eff.ivint.inf.obs kel.inf.obs kel.inf.pred
    ## 1                    FALSE                   FALSE       FALSE        FALSE
    ## 2                    FALSE                   FALSE       FALSE        FALSE
    ##   kel.iv.inf.obs kel.iv.inf.pred kel.int.inf.obs kel.int.inf.pred
    ## 1          FALSE           FALSE           FALSE            FALSE
    ## 2          FALSE           FALSE           FALSE            FALSE
    ##   kel.ivint.inf.pred kel.ivint.inf.obs auclast.dn aucall.dn aucinf.obs.dn
    ## 1              FALSE             FALSE      FALSE     FALSE         FALSE
    ## 2              FALSE             FALSE      FALSE     FALSE         FALSE
    ##   aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn
    ## 1          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
    ## 2          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
    ##   cmin.dn clast.obs.dn clast.pred.dn cav.last.dn ctrough.dn adj_tobit_residual
    ## 1   FALSE        FALSE         FALSE       FALSE      FALSE              FALSE
    ## 2   FALSE        FALSE         FALSE       FALSE      FALSE              FALSE
    ##   aucivpbextall aucivpbextinf.obs aucivpbextinf.pred aucivpbextint.all
    ## 1         FALSE             FALSE              FALSE             FALSE
    ## 2         FALSE             FALSE              FALSE             FALSE
    ##   aucivpbextint.last aucivpbextlast aucpext.obs aucpext.pred   cav cav.dn
    ## 1              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
    ## 2              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
    ##   cl.iv.obs cl.iv.pred cl.obs cl.pred clr.obs clr.pred count_conc
    ## 1     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
    ## 2     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
    ##   count_conc_measured f.int.obs f.int.pred f.obs f.pred kel.iv.obs kel.iv.pred
    ## 1               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
    ## 2               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
    ##   kel.obs kel.pred lambda.z.n.points_blq mrt.iv.obs mrt.iv.pred mrt.ivmd.obs
    ## 1   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
    ## 2   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
    ##   mrt.ivmd.pred mrt.md.obs mrt.md.pred mrt.obs mrt.pred thalf.eff.iv.obs
    ## 1         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
    ## 2         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
    ##   thalf.eff.iv.pred thalf.eff.obs thalf.eff.pred time_above tobit_residual
    ## 1             FALSE         FALSE          FALSE      FALSE          FALSE
    ## 2             FALSE         FALSE          FALSE      FALSE          FALSE
    ##   vss.iv.obs vss.iv.pred vss.ivmd.obs vss.ivmd.pred vss.md.obs vss.md.pred
    ## 1      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
    ## 2      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
    ##   vss.obs vss.pred vz.iv.obs vz.iv.pred vz.obs vz.pred
    ## 1   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE
    ## 2   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE

After the data is ready, the calculations and summary can progress.

``` r

results_obj <- pk.nca(data_obj)
print(results_obj)
```

    ## $result
    ## # A tibble: 48 × 7
    ##    Subject start   end PPTESTCD PPORRES PPANMETH               exclude
    ##    <ord>   <dbl> <dbl> <chr>      <dbl> <chr>                  <chr>  
    ##  1 6           0    24 auclast    71.8  "AUC: lin up/log down" NA     
    ##  2 6           0    24 cmax        6.44 ""                     NA     
    ##  3 6         144   168 auclast    82.2  "AUC: lin up/log down" NA     
    ##  4 6         144   168 cmax        7.37 ""                     NA     
    ##  5 7           0    24 auclast    89.0  "AUC: lin up/log down" NA     
    ##  6 7           0    24 cmax        7.09 ""                     NA     
    ##  7 7         144   168 auclast   101.   "AUC: lin up/log down" NA     
    ##  8 7         144   168 cmax        8.07 ""                     NA     
    ##  9 8           0    24 auclast    86.7  "AUC: lin up/log down" NA     
    ## 10 8           0    24 cmax        7.56 ""                     NA     
    ## # ℹ 38 more rows
    ## 
    ## $data
    ## Formula for concentration:
    ##  conc ~ time | Subject
    ## Data are dense PK.
    ## With 12 subjects defined in the 'Subject' column.
    ## Nominal time column is not specified.
    ## 
    ## First 6 rows of concentration data:
    ##  Subject     conc time exclude
    ##        1  0.74000 0.00    <NA>
    ##        1  2.84000 0.25    <NA>
    ##        1  4.23875 0.37    <NA>
    ##        1  6.57000 0.57    <NA>
    ##        1 10.50000 1.12    <NA>
    ##        1  9.66000 2.02    <NA>
    ## Formula for dosing:
    ##  ~time | Subject
    ## Nominal time column is not specified.
    ## 
    ## First 6 rows of dosing data:
    ##  Subject time exclude         route duration
    ##        1    0    <NA> extravascular        0
    ##        2    0    <NA> extravascular        0
    ##        3    0    <NA> extravascular        0
    ##        4    0    <NA> extravascular        0
    ##        5    0    <NA> extravascular        0
    ##        6    0    <NA> extravascular        0
    ## 
    ## With 2 rows of interval specifications.
    ## Options changed from default are:
    ## $adj.r.squared.factor
    ## [1] 1e-04
    ## 
    ## $r.squared.factor
    ## [1] NA
    ## 
    ## $max.missing
    ## [1] 0.5
    ## 
    ## $auc.method
    ## [1] "lin up/log down"
    ## 
    ## $conc.na
    ## [1] "drop"
    ## 
    ## $conc.blq
    ## $conc.blq$first
    ## [1] "keep"
    ## 
    ## $conc.blq$middle
    ## [1] "drop"
    ## 
    ## $conc.blq$last
    ## [1] "keep"
    ## 
    ## 
    ## $debug
    ## NULL
    ## 
    ## $first.tmax
    ## [1] TRUE
    ## 
    ## $first.tmin
    ## [1] TRUE
    ## 
    ## $allow.tmax.in.half.life
    ## [1] FALSE
    ## 
    ## $keep_interval_cols
    ## NULL
    ## 
    ## $min.hl.points
    ## [1] 3
    ## 
    ## $max.hl.points
    ## [1] Inf
    ## 
    ## $min.hl.start.time
    ## [1] 0
    ## 
    ## $min.span.ratio
    ## [1] 2
    ## 
    ## $max.aucinf.pext
    ## [1] 20
    ## 
    ## $min.hl.r.squared
    ## [1] 0.9
    ## 
    ## $progress
    ## [1] TRUE
    ## 
    ## $tau.choices
    ## [1] NA
    ## 
    ## $auto.interval.method
    ## [1] "builder"
    ## 
    ## $auto.interval.tolerance
    ## [1] 0.05
    ## 
    ## $single.dose.aucs
    ##   start end auclast auclast_se auclast_df aucall aucall_se aucall_df aumclast
    ## 1     0  24    TRUE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
    ## 2     0 Inf   FALSE      FALSE      FALSE  FALSE     FALSE     FALSE    FALSE
    ##   aumclast_se aumclast_df aumcall aumcall_se aumcall_df aucint.last aucint.all
    ## 1       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
    ## 2       FALSE       FALSE   FALSE      FALSE      FALSE       FALSE      FALSE
    ##   aumcint.last aumcint.all aucivint.last aucivint.all aucivpbext.int.last
    ## 1        FALSE       FALSE         FALSE        FALSE               FALSE
    ## 2        FALSE       FALSE         FALSE        FALSE               FALSE
    ##   aucivpbext.int.all aumcivint.last aumcivint.all    c0  cmax  cmin  tmax  tmin
    ## 1              FALSE          FALSE         FALSE FALSE FALSE FALSE FALSE FALSE
    ## 2              FALSE          FALSE         FALSE FALSE  TRUE FALSE  TRUE FALSE
    ##   tlast tfirst clast.obs cl.last cl.all cl.int.all cl.int.last cl.ivint.all
    ## 1 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
    ## 2 FALSE  FALSE     FALSE   FALSE  FALSE      FALSE       FALSE        FALSE
    ##   cl.ivint.last mrt.last mrt.all mrt.int.all mrt.int.last mrt.iv.last
    ## 1         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
    ## 2         FALSE    FALSE   FALSE       FALSE        FALSE       FALSE
    ##   mrt.ivint.all mrt.ivint.last vss.last vss.iv.last vss.all vss.int.all
    ## 1         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
    ## 2         FALSE          FALSE    FALSE       FALSE   FALSE       FALSE
    ##   vss.int.last vss.ivint.all vss.ivint.last cav.last cav.int.last cav.int.all
    ## 1        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
    ## 2        FALSE         FALSE          FALSE    FALSE        FALSE       FALSE
    ##   cav.all cav.ivint.last cav.ivint.all ctrough cstart   ptr  tlag deg.fluc
    ## 1   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE    FALSE
    ## 2   FALSE          FALSE         FALSE   FALSE  FALSE FALSE FALSE    FALSE
    ##   swing  ceoi aucabove.predose.all aucabove.trough.all count.conc
    ## 1 FALSE FALSE                FALSE               FALSE      FALSE
    ## 2 FALSE FALSE                FALSE               FALSE      FALSE
    ##   count.conc.measured totdose volpk    ae clr.last clr.int.inf.pred
    ## 1               FALSE   FALSE FALSE FALSE    FALSE            FALSE
    ## 2               FALSE   FALSE FALSE FALSE    FALSE            FALSE
    ##   clr.int.inf.obs clr.int.all clr.int.last clr.all clr.inf.obs clr.inf.pred
    ## 1           FALSE       FALSE        FALSE   FALSE       FALSE        FALSE
    ## 2           FALSE       FALSE        FALSE   FALSE       FALSE        FALSE
    ##      fe ertlst ermax ertmax erint erlst ratio.cmax ratio.auclast
    ## 1 FALSE  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE
    ## 2 FALSE  FALSE FALSE  FALSE FALSE FALSE      FALSE         FALSE
    ##   ratio.aucint.last ratio.aucint.all sparse_auclast sparse_auc_se sparse_auc_df
    ## 1             FALSE            FALSE          FALSE         FALSE         FALSE
    ## 2             FALSE            FALSE          FALSE         FALSE         FALSE
    ##   sparse_aumclast sparse_aumc_se sparse_aumc_df time.above aucivlast
    ## 1           FALSE          FALSE          FALSE      FALSE     FALSE
    ## 2           FALSE          FALSE          FALSE      FALSE     FALSE
    ##   aucivlast_se aucivlast_df aucivall aucivall_se aucivall_df aucivpbext.last
    ## 1        FALSE        FALSE    FALSE       FALSE       FALSE           FALSE
    ## 2        FALSE        FALSE    FALSE       FALSE       FALSE           FALSE
    ##   aucivpbext.all aumcivlast aumcivlast_se aumcivlast_df aumcivall aumcivall_se
    ## 1          FALSE      FALSE         FALSE         FALSE     FALSE        FALSE
    ## 2          FALSE      FALSE         FALSE         FALSE     FALSE        FALSE
    ##   aumcivall_df half.life r.squared adj.r.squared lambda.z.corrxy lambda.z
    ## 1        FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
    ## 2        FALSE      TRUE     FALSE         FALSE           FALSE    FALSE
    ##   lambda.z.time.first lambda.z.time.last lambda.z.n.points clast.pred
    ## 1               FALSE              FALSE             FALSE      FALSE
    ## 2               FALSE              FALSE             FALSE      FALSE
    ##   span.ratio tobit.residual adj.tobit.residual lambda.z.n.points.blq
    ## 1      FALSE          FALSE              FALSE                 FALSE
    ## 2      FALSE          FALSE              FALSE                 FALSE
    ##   thalf.eff.last thalf.eff.int.all thalf.eff.int.last thalf.eff.all
    ## 1          FALSE             FALSE              FALSE         FALSE
    ## 2          FALSE             FALSE              FALSE         FALSE
    ##   thalf.eff.iv.last thalf.eff.ivint.all thalf.eff.ivint.last kel.last
    ## 1             FALSE               FALSE                FALSE    FALSE
    ## 2             FALSE               FALSE                FALSE    FALSE
    ##   kel.iv.last kel.all kel.int.all kel.int.last kel.ivint.all kel.ivint.last
    ## 1       FALSE   FALSE       FALSE        FALSE         FALSE          FALSE
    ## 2       FALSE   FALSE       FALSE        FALSE         FALSE          FALSE
    ##   cl.iv.all cl.iv.last cl.sparse.last f.last f.all f.int.last f.int.all
    ## 1     FALSE      FALSE          FALSE  FALSE FALSE      FALSE     FALSE
    ## 2     FALSE      FALSE          FALSE  FALSE FALSE      FALSE     FALSE
    ##   mrt.sparse.last mrt.iv.all vz.all vz.int.all vz.int.last vz.iv.all vz.iv.last
    ## 1           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
    ## 2           FALSE      FALSE  FALSE      FALSE       FALSE     FALSE      FALSE
    ##   vz.ivint.all vz.ivint.last vz.last vss.iv.all vss.sparse.last cav.iv.last
    ## 1        FALSE         FALSE   FALSE      FALSE           FALSE       FALSE
    ## 2        FALSE         FALSE   FALSE      FALSE           FALSE       FALSE
    ##   cav.iv.all aucinf.obs aucinf.obs_se aucinf.obs_df aucinf.pred aumcinf.obs
    ## 1      FALSE      FALSE         FALSE         FALSE       FALSE       FALSE
    ## 2      FALSE       TRUE         FALSE         FALSE       FALSE       FALSE
    ##   aumcinf.obs_se aumcinf.obs_df aumcinf.pred aucint.inf.obs aucint.inf.pred
    ## 1          FALSE          FALSE        FALSE          FALSE           FALSE
    ## 2          FALSE          FALSE        FALSE          FALSE           FALSE
    ##   aumcint.inf.obs aumcint.inf.pred aucivint.inf.obs aucivint.inf.pred
    ## 1           FALSE            FALSE            FALSE             FALSE
    ## 2           FALSE            FALSE            FALSE             FALSE
    ##   aucivinf.obs aucivinf.obs_se aucivinf.obs_df aucivinf.pred aucivpbext.inf.obs
    ## 1        FALSE           FALSE           FALSE         FALSE              FALSE
    ## 2        FALSE           FALSE           FALSE         FALSE              FALSE
    ##   aucivpbext.inf.pred aumcivint.inf.pred aumcivint.inf.obs aumcivinf.obs
    ## 1               FALSE              FALSE             FALSE         FALSE
    ## 2               FALSE              FALSE             FALSE         FALSE
    ##   aumcivinf.obs_se aumcivinf.obs_df aumcivinf.pred thalf.eff.iv.all
    ## 1            FALSE            FALSE          FALSE            FALSE
    ## 2            FALSE            FALSE          FALSE            FALSE
    ##   aucpext.inf.obs aucpext.inf.pred kel.iv.all kel.sparse.last cl.inf.obs
    ## 1           FALSE            FALSE      FALSE           FALSE      FALSE
    ## 2           FALSE            FALSE      FALSE           FALSE      FALSE
    ##   cl.inf.pred cl.int.inf.obs cl.int.inf.pred cl.iv.inf.obs cl.iv.inf.pred
    ## 1       FALSE          FALSE           FALSE         FALSE          FALSE
    ## 2       FALSE          FALSE           FALSE         FALSE          FALSE
    ##   cl.ivint.inf.pred cl.ivint.inf.obs f.inf.obs f.inf.pred f.int.inf.obs
    ## 1             FALSE            FALSE     FALSE      FALSE         FALSE
    ## 2             FALSE            FALSE     FALSE      FALSE         FALSE
    ##   f.int.inf.pred mrt.inf.obs mrt.inf.pred mrt.int.inf.obs mrt.int.inf.pred
    ## 1          FALSE       FALSE        FALSE           FALSE            FALSE
    ## 2          FALSE       FALSE        FALSE           FALSE            FALSE
    ##   mrt.iv.inf.obs mrt.iv.inf.pred mrt.ivint.inf.pred mrt.ivint.inf.obs
    ## 1          FALSE           FALSE              FALSE             FALSE
    ## 2          FALSE           FALSE              FALSE             FALSE
    ##   mrt.md.inf.obs mrt.md.inf.pred mrt.ivmd.inf.obs mrt.ivmd.inf.pred vz.inf.obs
    ## 1          FALSE           FALSE            FALSE             FALSE      FALSE
    ## 2          FALSE           FALSE            FALSE             FALSE      FALSE
    ##   vz.inf.pred vz.int.inf.obs vz.int.inf.pred vz.iv.inf.obs vz.iv.inf.pred
    ## 1       FALSE          FALSE           FALSE         FALSE          FALSE
    ## 2       FALSE          FALSE           FALSE         FALSE          FALSE
    ##   vz.ivint.inf.pred vz.ivint.inf.obs vz.sparse.last vss.inf.obs vss.inf.pred
    ## 1             FALSE            FALSE          FALSE       FALSE        FALSE
    ## 2             FALSE            FALSE          FALSE       FALSE        FALSE
    ##   vss.iv.inf.obs vss.iv.inf.pred vss.md.inf.obs vss.md.inf.pred
    ## 1          FALSE           FALSE          FALSE           FALSE
    ## 2          FALSE           FALSE          FALSE           FALSE
    ##   vss.ivmd.inf.obs vss.ivmd.inf.pred vss.int.inf.obs vss.int.inf.pred
    ## 1            FALSE             FALSE           FALSE            FALSE
    ## 2            FALSE             FALSE           FALSE            FALSE
    ##   vss.ivint.inf.pred vss.ivint.inf.obs cav.int.inf.obs cav.int.inf.pred
    ## 1              FALSE             FALSE           FALSE            FALSE
    ## 2              FALSE             FALSE           FALSE            FALSE
    ##   cav.ivint.inf.obs cav.ivint.inf.pred ratio.aucinf.obs ratio.aucinf.pred
    ## 1             FALSE              FALSE            FALSE             FALSE
    ## 2             FALSE              FALSE            FALSE             FALSE
    ##   thalf.eff.inf.obs thalf.eff.inf.pred thalf.eff.int.inf.pred
    ## 1             FALSE              FALSE                  FALSE
    ## 2             FALSE              FALSE                  FALSE
    ##   thalf.eff.int.inf.obs thalf.eff.iv.inf.obs thalf.eff.iv.inf.pred
    ## 1                 FALSE                FALSE                 FALSE
    ## 2                 FALSE                FALSE                 FALSE
    ##   thalf.eff.ivint.inf.pred thalf.eff.ivint.inf.obs kel.inf.obs kel.inf.pred
    ## 1                    FALSE                   FALSE       FALSE        FALSE
    ## 2                    FALSE                   FALSE       FALSE        FALSE
    ##   kel.iv.inf.obs kel.iv.inf.pred kel.int.inf.obs kel.int.inf.pred
    ## 1          FALSE           FALSE           FALSE            FALSE
    ## 2          FALSE           FALSE           FALSE            FALSE
    ##   kel.ivint.inf.pred kel.ivint.inf.obs auclast.dn aucall.dn aucinf.obs.dn
    ## 1              FALSE             FALSE      FALSE     FALSE         FALSE
    ## 2              FALSE             FALSE      FALSE     FALSE         FALSE
    ##   aucinf.pred.dn aumclast.dn aumcall.dn aumcinf.obs.dn aumcinf.pred.dn cmax.dn
    ## 1          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
    ## 2          FALSE       FALSE      FALSE          FALSE           FALSE   FALSE
    ##   cmin.dn clast.obs.dn clast.pred.dn cav.last.dn ctrough.dn adj_tobit_residual
    ## 1   FALSE        FALSE         FALSE       FALSE      FALSE              FALSE
    ## 2   FALSE        FALSE         FALSE       FALSE      FALSE              FALSE
    ##   aucivpbextall aucivpbextinf.obs aucivpbextinf.pred aucivpbextint.all
    ## 1         FALSE             FALSE              FALSE             FALSE
    ## 2         FALSE             FALSE              FALSE             FALSE
    ##   aucivpbextint.last aucivpbextlast aucpext.obs aucpext.pred   cav cav.dn
    ## 1              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
    ## 2              FALSE          FALSE       FALSE        FALSE FALSE  FALSE
    ##   cl.iv.obs cl.iv.pred cl.obs cl.pred clr.obs clr.pred count_conc
    ## 1     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
    ## 2     FALSE      FALSE  FALSE   FALSE   FALSE    FALSE      FALSE
    ##   count_conc_measured f.int.obs f.int.pred f.obs f.pred kel.iv.obs kel.iv.pred
    ## 1               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
    ## 2               FALSE     FALSE      FALSE FALSE  FALSE      FALSE       FALSE
    ##   kel.obs kel.pred lambda.z.n.points_blq mrt.iv.obs mrt.iv.pred mrt.ivmd.obs
    ## 1   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
    ## 2   FALSE    FALSE                 FALSE      FALSE       FALSE        FALSE
    ##   mrt.ivmd.pred mrt.md.obs mrt.md.pred mrt.obs mrt.pred thalf.eff.iv.obs
    ## 1         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
    ## 2         FALSE      FALSE       FALSE   FALSE    FALSE            FALSE
    ##   thalf.eff.iv.pred thalf.eff.obs thalf.eff.pred time_above tobit_residual
    ## 1             FALSE         FALSE          FALSE      FALSE          FALSE
    ## 2             FALSE         FALSE          FALSE      FALSE          FALSE
    ##   vss.iv.obs vss.iv.pred vss.ivmd.obs vss.ivmd.pred vss.md.obs vss.md.pred
    ## 1      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
    ## 2      FALSE       FALSE        FALSE         FALSE      FALSE       FALSE
    ##   vss.obs vss.pred vz.iv.obs vz.iv.pred vz.obs vz.pred
    ## 1   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE
    ## 2   FALSE    FALSE     FALSE      FALSE  FALSE   FALSE
    ## 
    ## $allow_partial_missing_units
    ## [1] FALSE
    ## 
    ## $hl_method
    ## [1] "log-linear"
    ## 
    ## $sparse_lambda_z_se
    ## [1] "delta"
    ## 
    ## $tobit_n_points_penalty
    ## [1] 0
    ## 
    ## $tobit_optim_control
    ## list()
    ## 
    ## 
    ## $columns
    ## $columns$exclude
    ## [1] "exclude"
    ## 
    ## 
    ## attr(,"class")
    ## [1] "PKNCAresults" "list"        
    ## attr(,"provenance")
    ## Provenance hash 1010dd656fa2060bf5d457ba131dbe6d generated on 2026-11-12 15:45:20.00672 with R version 4.6.2 (2026-10-29).

``` r

summary(results_obj)
```

    ##  start end  N     auclast        cmax
    ##      0  24 12 98.8 [23.0] 8.65 [17.0]
    ##    144 168 12  115 [28.4] 10.0 [21.0]
    ## 
    ## Caption: auclast, cmax: geometric mean and geometric coefficient of variation; N: number of subjects
