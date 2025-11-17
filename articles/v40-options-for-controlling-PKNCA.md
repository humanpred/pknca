# Options for Controlling PKNCA

## Summary

PKNCA has many options that control its function. These options have
effects throughout the package. The options are controlled using either
the `PKNCA.options` function or by passing the `options` argument to any
of the functions with that as an argument. All options supported by the
current version of PKNCA (0.12.1.9000) are listed below with their
descriptions.

## Options

### adj.r.squared.factor

The adjusted r^2 for the calculation of lambda.z has this factor times
the number of data points added to it. It allows for more data points to
be preferred in the calculation of half-life.

The default value is: 1e-04

### max.missing

The maximum fraction of the data that may be missing (‘NA’) to calculate
summary statistics with the business.\* functions.

The default value is: 0.5

### auc.method

The method used to calculate the AUC and related statistics. Options
are: “lin up/log down”, “linear”, “lin-log”

The default value is: lin up/log down

### conc.na

How should missing (‘NA’) concentration values be handled? See help for
‘clean.conc.na’ for how to use this option.

The default value is: drop

### conc.blq

How should below the limit of quantification (zero, 0) concentration
values be handled? See help for ‘clean.conc.blq’ for how to use this
option.

\$first \[1\] “keep”

\$middle \[1\] “drop”

\$last \[1\] “keep”

### debug

Enable PKNCA debugging mode (not for production use)

NULL

### first.tmax

If there is more than one concentration equal to Cmax, which time should
be selected for Tmax? If ‘TRUE’, the first will be selected. If ‘FALSE’,
the last will be selected.

The default value is: TRUE

### allow.tmax.in.half.life

Should the concentration and time at Tmax be allowed in the half-life
calculation? ‘TRUE’ is yes and ‘FALSE’ is no.

The default value is: FALSE

### keep_interval_cols

What additional columns from the intervals should be kept in the
results?

NULL

### min.hl.points

What is the minimum number of points required to calculate half-life?

The default value is: 3

### min.span.ratio

What is the minimum span ratio required to consider a half-life valid?

The default value is: 2

### max.aucinf.pext

What is the maximum percent extrapolation to consider an AUCinf valid?

The default value is: 20

### min.hl.r.squared

What is the minimum r-squared value to consider a half-life calculation
valid?

The default value is: 0.9

### progress

A value to pass to purrr::pmap(.progress = ) to create a progress bar
while running

The default value is: TRUE

### tau.choices

What values for tau (repeating interdose interval) should be considered
when attempting to automatically determine the intervals for multiple
dosing? See ‘choose.auc.intervals’ and ‘find.tau’ for more information.
‘NA’ means automatically look at any potential interval.

The default value is: NA

### single.dose.aucs

When data is single-dose, what intervals should be used?

| start | end | auclast | aucall | aumclast | aumcall | aucint.last | aucint.last.dose | aucint.all | aucint.all.dose | c0    | cmax  | cmin  | tmax  | tlast | tfirst | clast.obs | cl.last | cl.all | f     | mrt.last | mrt.iv.last | vss.last | vss.iv.last | cav   | cav.int.last | cav.int.all | ctrough | cstart | ptr   | tlag  | deg.fluc | swing | ceoi  | aucabove.predose.all | aucabove.trough.all | count_conc | count_conc_measured | totdose | ae    | clr.last | clr.obs | clr.pred | fe    | sparse_auclast | sparse_auc_se | sparse_auc_df | time_above | aucivlast | aucivall | aucivint.last | aucivint.all | aucivpbextlast | aucivpbextall | aucivpbextint.last | aucivpbextint.all | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | thalf.eff.last | thalf.eff.iv.last | kel.last | kel.iv.last | aucinf.obs | aucinf.pred | aumcinf.obs | aumcinf.pred | aucint.inf.obs | aucint.inf.obs.dose | aucint.inf.pred | aucint.inf.pred.dose | aucivinf.obs | aucivinf.pred | aucivpbextinf.obs | aucivpbextinf.pred | aucpext.obs | aucpext.pred | cl.obs | cl.pred | mrt.obs | mrt.pred | mrt.iv.obs | mrt.iv.pred | mrt.md.obs | mrt.md.pred | vz.obs | vz.pred | vss.obs | vss.pred | vss.iv.obs | vss.iv.pred | vss.md.obs | vss.md.pred | cav.int.inf.obs | cav.int.inf.pred | thalf.eff.obs | thalf.eff.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | kel.obs | kel.pred | kel.iv.obs | kel.iv.pred | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.dn | ctrough.dn |
|------:|----:|:--------|:-------|:---------|:--------|:------------|:-----------------|:-----------|:----------------|:------|:------|:------|:------|:------|:-------|:----------|:--------|:-------|:------|:---------|:------------|:---------|:------------|:------|:-------------|:------------|:--------|:-------|:------|:------|:---------|:------|:------|:---------------------|:--------------------|:-----------|:--------------------|:--------|:------|:---------|:--------|:---------|:------|:---------------|:--------------|:--------------|:-----------|:----------|:---------|:--------------|:-------------|:---------------|:--------------|:-------------------|:------------------|:----------|:----------|:--------------|:----------------|:---------|:--------------------|:-------------------|:------------------|:-----------|:-----------|:---------------|:------------------|:---------|:------------|:-----------|:------------|:------------|:-------------|:---------------|:--------------------|:----------------|:---------------------|:-------------|:--------------|:------------------|:-------------------|:------------|:-------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:-------|:--------|:--------|:---------|:-----------|:------------|:-----------|:------------|:----------------|:-----------------|:--------------|:---------------|:-----------------|:------------------|:--------|:---------|:-----------|:------------|:-----------|:----------|:--------------|:---------------|:------------|:-----------|:---------------|:----------------|:--------|:--------|:-------------|:--------------|:-------|:-----------|
|     0 |  24 | TRUE    | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | FALSE     | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | FALSE      | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      |
|     0 | Inf | FALSE   | FALSE  | FALSE    | FALSE   | FALSE       | FALSE            | FALSE      | FALSE           | FALSE | TRUE  | FALSE | TRUE  | FALSE | FALSE  | FALSE     | FALSE   | FALSE  | FALSE | FALSE    | FALSE       | FALSE    | FALSE       | FALSE | FALSE        | FALSE       | FALSE   | FALSE  | FALSE | FALSE | FALSE    | FALSE | FALSE | FALSE                | FALSE               | FALSE      | FALSE               | FALSE   | FALSE | FALSE    | FALSE   | FALSE    | FALSE | FALSE          | FALSE         | FALSE         | FALSE      | FALSE     | FALSE    | FALSE         | FALSE        | FALSE          | FALSE         | FALSE              | FALSE             | TRUE      | FALSE     | FALSE         | FALSE           | FALSE    | FALSE               | FALSE              | FALSE             | FALSE      | FALSE      | FALSE          | FALSE             | FALSE    | FALSE       | TRUE       | FALSE       | FALSE       | FALSE        | FALSE          | FALSE               | FALSE           | FALSE                | FALSE        | FALSE         | FALSE             | FALSE              | FALSE       | FALSE        | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE  | FALSE   | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE       | FALSE           | FALSE            | FALSE         | FALSE          | FALSE            | FALSE             | FALSE   | FALSE    | FALSE      | FALSE       | FALSE      | FALSE     | FALSE         | FALSE          | FALSE       | FALSE      | FALSE          | FALSE           | FALSE   | FALSE   | FALSE        | FALSE         | FALSE  | FALSE      |

### allow_partial_missing_units

When using unit assignment and conversions, should some units be allowed
to be missing?

The default value is: FALSE
