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
Subject for the dosing data set.

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

Example dosing data extracted from theophylline data set

``` r
dose_obj <- PKNCAdose(d_dose, Dose~Time|Subject)
```

## Merge the Concentration and Dose

After loading the data, they must be combined to prepare for parameter
calculation. Intervals for calculation will automatically be selected
based on the `single.dose.aucs setting` in `PKNCA.options`

``` r
data_obj_automatic <- PKNCAdata(conc_obj, dose_obj)
knitr::kable(PKNCA.options("single.dose.aucs"))
```

| start | end | auclast | aucall | aumclast | aumcall | aucint.last | aucint.last.dose | aucint.all | aucint.all.dose | c0    | cmax  | cmin  | tmax  | tlast | tfirst | clast.obs | cl.last | cl.all | f     | mrt.last | mrt.iv.last | vss.last | vss.iv.last | cav   | cav.int.last | cav.int.all | ctrough | cstart | ptr   | tlag  | deg.fluc | swing | ceoi  | aucabove.predose.all | aucabove.trough.all | count_conc | count_conc_measured | totdose | volpk | ae    | clr.last | clr.obs | clr.pred | fe    | sparse_auclast | sparse_auc_se | sparse_auc_df | time_above | aucivlast | aucivall | aucivint.last | aucivint.all | aucivpbextlast | aucivpbextall | aucivpbextint.last | aucivpbextint.all | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | thalf.eff.last | thalf.eff.iv.last | kel.last | kel.iv.last | aucinf.obs | aucinf.pred | aumcinf.obs | aumcinf.pred | aucint.inf.obs | aucint.inf.obs.dose | aucint.inf.pred | aucint.inf.pred.dose | aucivinf.obs | aucivinf.pred | aucivpbextinf.obs | aucivpbextinf.pred | aucpext.obs | aucpext.pred | cl.obs | cl.pred | mrt.obs | mrt.pred | mrt.iv.obs | mrt.iv.pred | mrt.md.obs | mrt.md.pred | vz.obs | vz.pred | vss.obs | vss.pred | vss.iv.obs | vss.iv.pred | vss.md.obs | vss.md.pred | cav.int.inf.obs | cav.int.inf.pred | thalf.eff.obs | thalf.eff.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | kel.obs | kel.pred | kel.iv.obs | kel.iv.pred | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.dn | ctrough.dn | clr.last.dn | clr.obs.dn | clr.pred.dn |
|------:|----:|:--------|:-------|:---------|:--------|:------------|:-----------------|:-----------|:----------------|:------|:------|:------|:------|:------|:-------|:----------|:--------|:-------|:------|:---------|:------------|:---------|:------------|:------|:-------------|:------------|:--------|:-------|:------|:------|:---------|:------|:------|:---------------------|:--------------------|:-----------|:--------------------|:--------|:------|:------|:---------|:--------|:---------|:------|:---------------|:--------------|:--------------|:-----------|:----------|:---------|:--------------|:-------------|:---------------|:--------------|:-------------------|:------------------|:----------|:----------|:--------------|:----------------|:---------|:--------------------|:-------------------|:------------------|:-----------|:-----------|:---------------|:------------------|:---------|:------------|:-----------|:------------|:------------|:-------------|:---------------|:--------------------|:----------------|:---------------------|:-------------|:--------------|:------------------|:-------------------|:------------|:-------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:----------------|:-----------------|:--------------|:---------------|:-----------------|:------------------|:--------|:---------|:-----------|:------------|:-----------|:----------|:--------------|:---------------|:------------|:-----------|:---------------|:----------------|:--------|:--------|:-------------|:--------------|:-------|:-----------|:------------|:-----------|:------------|
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       |

``` r
knitr::kable(data_obj_automatic$intervals)
```

| start | end | auclast | aucall | aumclast | aumcall | aucint.last | aucint.last.dose | aucint.all | aucint.all.dose | c0    | cmax  | cmin  | tmax  | tlast | tfirst | clast.obs | cl.last | cl.all | f     | mrt.last | mrt.iv.last | vss.last | vss.iv.last | cav   | cav.int.last | cav.int.all | ctrough | cstart | ptr   | tlag  | deg.fluc | swing | ceoi  | aucabove.predose.all | aucabove.trough.all | count_conc | count_conc_measured | totdose | volpk | ae    | clr.last | clr.obs | clr.pred | fe    | sparse_auclast | sparse_auc_se | sparse_auc_df | time_above | aucivlast | aucivall | aucivint.last | aucivint.all | aucivpbextlast | aucivpbextall | aucivpbextint.last | aucivpbextint.all | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | thalf.eff.last | thalf.eff.iv.last | kel.last | kel.iv.last | aucinf.obs | aucinf.pred | aumcinf.obs | aumcinf.pred | aucint.inf.obs | aucint.inf.obs.dose | aucint.inf.pred | aucint.inf.pred.dose | aucivinf.obs | aucivinf.pred | aucivpbextinf.obs | aucivpbextinf.pred | aucpext.obs | aucpext.pred | cl.obs | cl.pred | mrt.obs | mrt.pred | mrt.iv.obs | mrt.iv.pred | mrt.md.obs | mrt.md.pred | vz.obs | vz.pred | vss.obs | vss.pred | vss.iv.obs | vss.iv.pred | vss.md.obs | vss.md.pred | cav.int.inf.obs | cav.int.inf.pred | thalf.eff.obs | thalf.eff.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | kel.obs | kel.pred | kel.iv.obs | kel.iv.pred | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.dn | ctrough.dn | clr.last.dn | clr.obs.dn | clr.pred.dn | Subject |
|------:|----:|:--------|:-------|:---------|:--------|:------------|:-----------------|:-----------|:----------------|:------|:------|:------|:------|:------|:-------|:----------|:--------|:-------|:------|:---------|:------------|:---------|:------------|:------|:-------------|:------------|:--------|:-------|:------|:------|:---------|:------|:------|:---------------------|:--------------------|:-----------|:--------------------|:--------|:------|:------|:---------|:--------|:---------|:------|:---------------|:--------------|:--------------|:-----------|:----------|:---------|:--------------|:-------------|:---------------|:--------------|:-------------------|:------------------|:----------|:----------|:--------------|:----------------|:---------|:--------------------|:-------------------|:------------------|:-----------|:-----------|:---------------|:------------------|:---------|:------------|:-----------|:------------|:------------|:-------------|:---------------|:--------------------|:----------------|:---------------------|:-------------|:--------------|:------------------|:-------------------|:------------|:-------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:----------------|:-----------------|:--------------|:---------------|:-----------------|:------------------|:--------|:---------|:-----------|:------------|:-----------|:----------|:--------------|:---------------|:------------|:-----------|:---------------|:----------------|:--------|:--------|:-------------|:--------------|:-------|:-----------|:------------|:-----------|:------------|:--------|
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 1       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 1       |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 2       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 2       |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 3       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 3       |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 4       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 4       |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 5       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 5       |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 6       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 6       |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 7       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 7       |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 8       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 8       |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 9       |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 9       |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 10      |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 10      |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 11      |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 11      |
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 12      |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       | 12      |

Intervals for calculation can also be specified manually. Manual
specification requires at least columns for `start` time, `end` time,
and the parameters requested. The manual specification can also include
any grouping factors from the concentration data set. Column order of
the intervals is not important. When intervals are manually specified,
they are expanded to the full interval set when added to a PKNCAdata
object (in other words, a column is created for each parameter. Also,
PKNCA automatically calculates parameters required for the NCA, so while
lambda.z is required for calculating AUC_(0-$\infty$), you do not have
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

| start | end | auclast | aucall | aumclast | aumcall | aucint.last | aucint.last.dose | aucint.all | aucint.all.dose | c0    | cmax | cmin  | tmax | tlast | tfirst | clast.obs | cl.last | cl.all | f     | mrt.last | mrt.iv.last | vss.last | vss.iv.last | cav   | cav.int.last | cav.int.all | ctrough | cstart | ptr   | tlag  | deg.fluc | swing | ceoi  | aucabove.predose.all | aucabove.trough.all | count_conc | count_conc_measured | totdose | volpk | ae    | clr.last | clr.obs | clr.pred | fe    | sparse_auclast | sparse_auc_se | sparse_auc_df | time_above | aucivlast | aucivall | aucivint.last | aucivint.all | aucivpbextlast | aucivpbextall | aucivpbextint.last | aucivpbextint.all | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | thalf.eff.last | thalf.eff.iv.last | kel.last | kel.iv.last | aucinf.obs | aucinf.pred | aumcinf.obs | aumcinf.pred | aucint.inf.obs | aucint.inf.obs.dose | aucint.inf.pred | aucint.inf.pred.dose | aucivinf.obs | aucivinf.pred | aucivpbextinf.obs | aucivpbextinf.pred | aucpext.obs | aucpext.pred | cl.obs | cl.pred | mrt.obs | mrt.pred | mrt.iv.obs | mrt.iv.pred | mrt.md.obs | mrt.md.pred | vz.obs | vz.pred | vss.obs | vss.pred | vss.iv.obs | vss.iv.pred | vss.md.obs | vss.md.pred | cav.int.inf.obs | cav.int.inf.pred | thalf.eff.obs | thalf.eff.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | kel.obs | kel.pred | kel.iv.obs | kel.iv.pred | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.dn | ctrough.dn | clr.last.dn | clr.obs.dn | clr.pred.dn |
|------:|----:|:--------|:-------|:---------|:--------|:------------|:-----------------|:-----------|:----------------|:------|:-----|:------|:-----|:------|:-------|:----------|:--------|:-------|:------|:---------|:------------|:---------|:------------|:------|:-------------|:------------|:--------|:-------|:------|:------|:---------|:------|:------|:---------------------|:--------------------|:-----------|:--------------------|:--------|:------|:------|:---------|:--------|:---------|:------|:---------------|:--------------|:--------------|:-----------|:----------|:---------|:--------------|:-------------|:---------------|:--------------|:-------------------|:------------------|:----------|:----------|:--------------|:----------------|:---------|:--------------------|:-------------------|:------------------|:-----------|:-----------|:---------------|:------------------|:---------|:------------|:-----------|:------------|:------------|:-------------|:---------------|:--------------------|:----------------|:---------------------|:-------------|:--------------|:------------------|:-------------------|:------------|:-------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:----------------|:-----------------|:--------------|:---------------|:-----------------|:------------------|:--------|:---------|:-----------|:------------|:-----------|:----------|:--------------|:---------------|:------------|:-----------|:---------------|:----------------|:--------|:--------|:-------------|:--------------|:-------|:-----------|:------------|:-----------|:------------|
|     0 | Inf | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      | FALSE       | FALSE      | FALSE       |

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

| Subject | start | end | PPTESTCD  |   PPORRES | exclude |
|:--------|------:|----:|:----------|----------:|:--------|
| 1       |     0 |  24 | auclast   | 92.365442 | NA      |
| 1       |     0 | Inf | cmax      | 10.500000 | NA      |
| 1       |     0 | Inf | tmax      |  1.120000 | NA      |
| 1       |     0 | Inf | tlast     | 24.370000 | NA      |
| 1       |     0 | Inf | clast.obs |  3.280000 | NA      |
| 1       |     0 | Inf | lambda.z  |  0.048457 | NA      |

``` r
summary(results_obj_automatic)
```

| start | end | N   | auclast       | cmax          | tmax                 | half.life     | aucinf.obs   |
|------:|----:|:----|:--------------|:--------------|:---------------------|:--------------|:-------------|
|     0 |  24 | 12  | 74.6 \[24.3\] | .             | .                    | .             | .            |
|     0 | Inf | 12  | .             | 8.65 \[17.0\] | 1.14 \[0.630, 3.55\] | 8.18 \[2.12\] | 115 \[28.4\] |

``` r
results_obj_manual <- pk.nca(data_obj_manual)
knitr::kable(head(as.data.frame(results_obj_manual)))
```

| Subject | start | end | PPTESTCD  |    PPORRES | exclude |
|:--------|------:|----:|:----------|-----------:|:--------|
| 6       |     0 | Inf | auclast   | 71.6970150 | NA      |
| 6       |     0 | Inf | cmax      |  6.4400000 | NA      |
| 6       |     0 | Inf | tmax      |  1.1500000 | NA      |
| 6       |     0 | Inf | tlast     | 23.8500000 | NA      |
| 6       |     0 | Inf | clast.obs |  0.9200000 | NA      |
| 6       |     0 | Inf | lambda.z  |  0.0877957 | NA      |

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
[superposition](http://humanpred.github.io/pknca/articles/v20-superposition.md)
vignette for more information).

``` r
d_conc <- PKNCAconc(as.data.frame(Theoph), conc~Time|Subject)
conc_obj_multi <-
  PKNCAconc(
    superposition(d_conc,
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
    ##  Subject     conc time exclude volume duration
    ##        1  0.74000 0.00    <NA>     NA        0
    ##        1  2.84000 0.25    <NA>     NA        0
    ##        1  4.23875 0.37    <NA>     NA        0
    ##        1  6.57000 0.57    <NA>     NA        0
    ##        1 10.50000 1.12    <NA>     NA        0
    ##        1  9.66000 2.02    <NA>     NA        0

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

    ##   start end auclast aucall aumclast aumcall aucint.last aucint.last.dose
    ## 1     0  24    TRUE  FALSE    FALSE   FALSE       FALSE            FALSE
    ## 2   144 168    TRUE  FALSE    FALSE   FALSE       FALSE            FALSE
    ##   aucint.all aucint.all.dose    c0 cmax  cmin  tmax tlast tfirst clast.obs
    ## 1      FALSE           FALSE FALSE TRUE FALSE FALSE FALSE  FALSE     FALSE
    ## 2      FALSE           FALSE FALSE TRUE FALSE FALSE FALSE  FALSE     FALSE
    ##   cl.last cl.all     f mrt.last mrt.iv.last vss.last vss.iv.last   cav
    ## 1   FALSE  FALSE FALSE    FALSE       FALSE    FALSE       FALSE FALSE
    ## 2   FALSE  FALSE FALSE    FALSE       FALSE    FALSE       FALSE FALSE
    ##   cav.int.last cav.int.all ctrough cstart   ptr  tlag deg.fluc swing  ceoi
    ## 1        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
    ## 2        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
    ##   aucabove.predose.all aucabove.trough.all count_conc count_conc_measured
    ## 1                FALSE               FALSE      FALSE               FALSE
    ## 2                FALSE               FALSE      FALSE               FALSE
    ##   totdose volpk    ae clr.last clr.obs clr.pred    fe sparse_auclast
    ## 1   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE          FALSE
    ## 2   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE          FALSE
    ##   sparse_auc_se sparse_auc_df time_above aucivlast aucivall aucivint.last
    ## 1         FALSE         FALSE      FALSE     FALSE    FALSE         FALSE
    ## 2         FALSE         FALSE      FALSE     FALSE    FALSE         FALSE
    ##   aucivint.all aucivpbextlast aucivpbextall aucivpbextint.last
    ## 1        FALSE          FALSE         FALSE              FALSE
    ## 2        FALSE          FALSE         FALSE              FALSE
    ##   aucivpbextint.all half.life r.squared adj.r.squared lambda.z.corrxy lambda.z
    ## 1             FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
    ## 2             FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
    ##   lambda.z.time.first lambda.z.time.last lambda.z.n.points clast.pred
    ## 1               FALSE              FALSE             FALSE      FALSE
    ## 2               FALSE              FALSE             FALSE      FALSE
    ##   span.ratio thalf.eff.last thalf.eff.iv.last kel.last kel.iv.last aucinf.obs
    ## 1      FALSE          FALSE             FALSE    FALSE       FALSE      FALSE
    ## 2      FALSE          FALSE             FALSE    FALSE       FALSE      FALSE
    ##   aucinf.pred aumcinf.obs aumcinf.pred aucint.inf.obs aucint.inf.obs.dose
    ## 1       FALSE       FALSE        FALSE          FALSE               FALSE
    ## 2       FALSE       FALSE        FALSE          FALSE               FALSE
    ##   aucint.inf.pred aucint.inf.pred.dose aucivinf.obs aucivinf.pred
    ## 1           FALSE                FALSE        FALSE         FALSE
    ## 2           FALSE                FALSE        FALSE         FALSE
    ##   aucivpbextinf.obs aucivpbextinf.pred aucpext.obs aucpext.pred cl.obs cl.pred
    ## 1             FALSE              FALSE       FALSE        FALSE  FALSE   FALSE
    ## 2             FALSE              FALSE       FALSE        FALSE  FALSE   FALSE
    ##   mrt.obs mrt.pred mrt.iv.obs mrt.iv.pred mrt.md.obs mrt.md.pred vz.obs vz.pred
    ## 1   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE  FALSE   FALSE
    ## 2   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE  FALSE   FALSE
    ##   vss.obs vss.pred vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred
    ## 1   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
    ## 2   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
    ##   cav.int.inf.obs cav.int.inf.pred thalf.eff.obs thalf.eff.pred
    ## 1           FALSE            FALSE         FALSE          FALSE
    ## 2           FALSE            FALSE         FALSE          FALSE
    ##   thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs kel.iv.pred
    ## 1            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
    ## 2            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
    ##   auclast.dn aucall.dn aucinf.obs.dn aucinf.pred.dn aumclast.dn aumcall.dn
    ## 1      FALSE     FALSE         FALSE          FALSE       FALSE      FALSE
    ## 2      FALSE     FALSE         FALSE          FALSE       FALSE      FALSE
    ##   aumcinf.obs.dn aumcinf.pred.dn cmax.dn cmin.dn clast.obs.dn clast.pred.dn
    ## 1          FALSE           FALSE   FALSE   FALSE        FALSE         FALSE
    ## 2          FALSE           FALSE   FALSE   FALSE        FALSE         FALSE
    ##   cav.dn ctrough.dn clr.last.dn clr.obs.dn clr.pred.dn
    ## 1  FALSE      FALSE       FALSE      FALSE       FALSE
    ## 2  FALSE      FALSE       FALSE      FALSE       FALSE

After the data is ready, the calculations and summary can progress.

``` r
results_obj <- pk.nca(data_obj)
print(results_obj)
```

    ## $result
    ## # A tibble: 48 × 6
    ##    Subject start   end PPTESTCD PPORRES exclude
    ##    <ord>   <dbl> <dbl> <chr>      <dbl> <chr>  
    ##  1 6           0    24 auclast    71.8  NA     
    ##  2 6           0    24 cmax        6.44 NA     
    ##  3 6         144   168 auclast    82.2  NA     
    ##  4 6         144   168 cmax        7.37 NA     
    ##  5 7           0    24 auclast    89.0  NA     
    ##  6 7           0    24 cmax        7.09 NA     
    ##  7 7         144   168 auclast   101.   NA     
    ##  8 7         144   168 cmax        8.07 NA     
    ##  9 8           0    24 auclast    86.7  NA     
    ## 10 8           0    24 cmax        7.56 NA     
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
    ##  Subject     conc time exclude volume duration
    ##        1  0.74000 0.00    <NA>     NA        0
    ##        1  2.84000 0.25    <NA>     NA        0
    ##        1  4.23875 0.37    <NA>     NA        0
    ##        1  6.57000 0.57    <NA>     NA        0
    ##        1 10.50000 1.12    <NA>     NA        0
    ##        1  9.66000 2.02    <NA>     NA        0
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
    ## With imputation: NA
    ## Options changed from default are:
    ## $adj.r.squared.factor
    ## [1] 1e-04
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
    ## $allow.tmax.in.half.life
    ## [1] FALSE
    ## 
    ## $keep_interval_cols
    ## NULL
    ## 
    ## $min.hl.points
    ## [1] 3
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
    ## $single.dose.aucs
    ##   start end auclast aucall aumclast aumcall aucint.last aucint.last.dose
    ## 1     0  24    TRUE  FALSE    FALSE   FALSE       FALSE            FALSE
    ## 2     0 Inf   FALSE  FALSE    FALSE   FALSE       FALSE            FALSE
    ##   aucint.all aucint.all.dose    c0  cmax  cmin  tmax tlast tfirst clast.obs
    ## 1      FALSE           FALSE FALSE FALSE FALSE FALSE FALSE  FALSE     FALSE
    ## 2      FALSE           FALSE FALSE  TRUE FALSE  TRUE FALSE  FALSE     FALSE
    ##   cl.last cl.all     f mrt.last mrt.iv.last vss.last vss.iv.last   cav
    ## 1   FALSE  FALSE FALSE    FALSE       FALSE    FALSE       FALSE FALSE
    ## 2   FALSE  FALSE FALSE    FALSE       FALSE    FALSE       FALSE FALSE
    ##   cav.int.last cav.int.all ctrough cstart   ptr  tlag deg.fluc swing  ceoi
    ## 1        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
    ## 2        FALSE       FALSE   FALSE  FALSE FALSE FALSE    FALSE FALSE FALSE
    ##   aucabove.predose.all aucabove.trough.all count_conc count_conc_measured
    ## 1                FALSE               FALSE      FALSE               FALSE
    ## 2                FALSE               FALSE      FALSE               FALSE
    ##   totdose volpk    ae clr.last clr.obs clr.pred    fe sparse_auclast
    ## 1   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE          FALSE
    ## 2   FALSE FALSE FALSE    FALSE   FALSE    FALSE FALSE          FALSE
    ##   sparse_auc_se sparse_auc_df time_above aucivlast aucivall aucivint.last
    ## 1         FALSE         FALSE      FALSE     FALSE    FALSE         FALSE
    ## 2         FALSE         FALSE      FALSE     FALSE    FALSE         FALSE
    ##   aucivint.all aucivpbextlast aucivpbextall aucivpbextint.last
    ## 1        FALSE          FALSE         FALSE              FALSE
    ## 2        FALSE          FALSE         FALSE              FALSE
    ##   aucivpbextint.all half.life r.squared adj.r.squared lambda.z.corrxy lambda.z
    ## 1             FALSE     FALSE     FALSE         FALSE           FALSE    FALSE
    ## 2             FALSE      TRUE     FALSE         FALSE           FALSE    FALSE
    ##   lambda.z.time.first lambda.z.time.last lambda.z.n.points clast.pred
    ## 1               FALSE              FALSE             FALSE      FALSE
    ## 2               FALSE              FALSE             FALSE      FALSE
    ##   span.ratio thalf.eff.last thalf.eff.iv.last kel.last kel.iv.last aucinf.obs
    ## 1      FALSE          FALSE             FALSE    FALSE       FALSE      FALSE
    ## 2      FALSE          FALSE             FALSE    FALSE       FALSE       TRUE
    ##   aucinf.pred aumcinf.obs aumcinf.pred aucint.inf.obs aucint.inf.obs.dose
    ## 1       FALSE       FALSE        FALSE          FALSE               FALSE
    ## 2       FALSE       FALSE        FALSE          FALSE               FALSE
    ##   aucint.inf.pred aucint.inf.pred.dose aucivinf.obs aucivinf.pred
    ## 1           FALSE                FALSE        FALSE         FALSE
    ## 2           FALSE                FALSE        FALSE         FALSE
    ##   aucivpbextinf.obs aucivpbextinf.pred aucpext.obs aucpext.pred cl.obs cl.pred
    ## 1             FALSE              FALSE       FALSE        FALSE  FALSE   FALSE
    ## 2             FALSE              FALSE       FALSE        FALSE  FALSE   FALSE
    ##   mrt.obs mrt.pred mrt.iv.obs mrt.iv.pred mrt.md.obs mrt.md.pred vz.obs vz.pred
    ## 1   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE  FALSE   FALSE
    ## 2   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE  FALSE   FALSE
    ##   vss.obs vss.pred vss.iv.obs vss.iv.pred vss.md.obs vss.md.pred
    ## 1   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
    ## 2   FALSE    FALSE      FALSE       FALSE      FALSE       FALSE
    ##   cav.int.inf.obs cav.int.inf.pred thalf.eff.obs thalf.eff.pred
    ## 1           FALSE            FALSE         FALSE          FALSE
    ## 2           FALSE            FALSE         FALSE          FALSE
    ##   thalf.eff.iv.obs thalf.eff.iv.pred kel.obs kel.pred kel.iv.obs kel.iv.pred
    ## 1            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
    ## 2            FALSE             FALSE   FALSE    FALSE      FALSE       FALSE
    ##   auclast.dn aucall.dn aucinf.obs.dn aucinf.pred.dn aumclast.dn aumcall.dn
    ## 1      FALSE     FALSE         FALSE          FALSE       FALSE      FALSE
    ## 2      FALSE     FALSE         FALSE          FALSE       FALSE      FALSE
    ##   aumcinf.obs.dn aumcinf.pred.dn cmax.dn cmin.dn clast.obs.dn clast.pred.dn
    ## 1          FALSE           FALSE   FALSE   FALSE        FALSE         FALSE
    ## 2          FALSE           FALSE   FALSE   FALSE        FALSE         FALSE
    ##   cav.dn ctrough.dn clr.last.dn clr.obs.dn clr.pred.dn
    ## 1  FALSE      FALSE       FALSE      FALSE       FALSE
    ## 2  FALSE      FALSE       FALSE      FALSE       FALSE
    ## 
    ## $allow_partial_missing_units
    ## [1] FALSE
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
    ## Provenance hash ee687a520af821aa354fef62aa53cba0 generated on 2025-11-24 16:13:17.954169 with R version 4.5.2 (2025-10-31).

``` r
summary(results_obj)
```

    ##  start end  N     auclast        cmax
    ##      0  24 12 98.8 [23.0] 8.65 [17.0]
    ##    144 168 12  115 [28.4] 10.0 [21.0]
    ## 
    ## Caption: auclast, cmax: geometric mean and geometric coefficient of variation; N: number of subjects
