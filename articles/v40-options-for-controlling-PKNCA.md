# Options for Controlling PKNCA

## Summary

PKNCA has many options that control its function. These options have
effects throughout the package. The options are controlled using either
the `PKNCA.options` function or by passing the `options` argument to any
of the functions with that as an argument. All options supported by the
current version of PKNCA (0.12.1.9003) are listed below with their
descriptions.

## Options

### adj.r.squared.factor

During the calculation of lambda.z, all candidate regressions with an
adjusted r^2 within adj.r.squared.factor of the best adjusted r^2 are
considered acceptable, and the acceptable regression using the most data
points is selected. It allows for more data points to be preferred in
the calculation of half-life. Setting either of adj.r.squared.factor and
r.squared.factor takes the other out of use, so exactly one of them is
ever in use; setting this one to NA therefore selects on the other
r-squared.

The default value is: 1e-04

### r.squared.factor

During the calculation of lambda.z, all candidate regressions with an
r^2 within r.squared.factor of the best r^2 are considered acceptable,
and the acceptable regression using the most data points is selected.
Unlike the adjusted r^2, the r^2 does not reward more data points, so it
generally selects fewer of them. Setting either of adj.r.squared.factor
and r.squared.factor takes the other out of use, so exactly one of them
is ever in use; setting this one to NA therefore selects on the other
r-squared.

The default value is: NA

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

If there is more than one time point with the maximum value (Cmax or
ERmax), which time should be selected for Tmax/ERTmax? If ‘TRUE’, the
first will be selected. If ‘FALSE’, the last will be selected.

The default value is: TRUE

### first.tmin

If there is more than one time point with the minimum value (Cmin),
which time should be selected for Tmin? If ‘TRUE’, the first will be
selected. If ‘FALSE’, the last will be selected.

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

### max.hl.points

What is the maximum number of points that automatic point selection may
use for half-life? It must be more than min.hl.points.

The default value is: Inf

### min.hl.start.time

What is the earliest time at which automatic point selection may start
the half-life (0 does not restrict it)?

The default value is: 0

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

### auto.interval.method

When automatically determining the intervals, where do the parameters to
calculate come from? ‘builder’ asks ‘pknca_interval_table’ for the
parameters that suit each interval’s context. ‘legacy’ uses the
parameter lists PKNCA used before that was available: the
‘single.dose.aucs’ option for single-dose data, and AUClast, Cmax, and
Tmax for each interval of multiple-dose data. Only the choice of
parameters differs; the intervals themselves are found the same way
either way. See ‘choose.auc.intervals’ for more information.

The default value is: builder

### auto.interval.tolerance

When automatically determining the intervals, how far from the boundary
of an interval may a sample be drawn and still count as the sample at
that boundary? It is given as a fraction of the interval’s length (the
dosing interval, tau, for a dosing interval), so that a trough drawn at
167.5 hours still ends an interval nominally ending at 168 hours. See
‘choose.auc.intervals’ for more information.

The default value is: 0.05

### single.dose.aucs

When data is single-dose, what intervals should be used?

| start | end | auclast | auclast_se | auclast_df | aucall | aucall_se | aucall_df | aumclast | aumclast_se | aumclast_df | aumcall | aumcall_se | aumcall_df | aucint.last | aucint.all | aumcint.last | aumcint.all | aucivint.last | aucivint.all | aucivpbext.int.last | aucivpbext.int.all | aumcivint.last | aumcivint.all | c0 | cmax | cmin | tmax | tmin | tlast | tfirst | clast.obs | cl.last | cl.all | cl.int.all | cl.int.last | cl.ivint.all | cl.ivint.last | mrt.last | mrt.all | mrt.int.all | mrt.int.last | mrt.iv.last | mrt.ivint.all | mrt.ivint.last | vss.last | vss.iv.last | vss.all | vss.int.all | vss.int.last | vss.ivint.all | vss.ivint.last | cav.last | cav.int.last | cav.int.all | cav.all | cav.ivint.last | cav.ivint.all | ctrough | cstart | ptr | tlag | deg.fluc | swing | ceoi | aucabove.predose.all | aucabove.trough.all | count.conc | count.conc.measured | totdose | volpk | ae | clr.last | clr.int.inf.pred | clr.int.inf.obs | clr.int.all | clr.int.last | clr.all | clr.inf.obs | clr.inf.pred | fe | ertlst | ermax | ertmax | erint | erlst | ratio.cmax | ratio.auclast | ratio.aucint.last | ratio.aucint.all | sparse_auclast | sparse_auc_se | sparse_auc_df | sparse_aumclast | sparse_aumc_se | sparse_aumc_df | time.above | aucivlast | aucivlast_se | aucivlast_df | aucivall | aucivall_se | aucivall_df | aucivpbext.last | aucivpbext.all | aumcivlast | aumcivlast_se | aumcivlast_df | aumcivall | aumcivall_se | aumcivall_df | half.life | r.squared | adj.r.squared | lambda.z.corrxy | lambda.z | lambda.z.time.first | lambda.z.time.last | lambda.z.n.points | clast.pred | span.ratio | tobit.residual | adj.tobit.residual | lambda.z.n.points.blq | thalf.eff.last | thalf.eff.int.all | thalf.eff.int.last | thalf.eff.all | thalf.eff.iv.last | thalf.eff.ivint.all | thalf.eff.ivint.last | kel.last | kel.iv.last | kel.all | kel.int.all | kel.int.last | kel.ivint.all | kel.ivint.last | cl.iv.all | cl.iv.last | cl.sparse.last | f.last | f.all | f.int.last | f.int.all | mrt.sparse.last | mrt.iv.all | vz.all | vz.int.all | vz.int.last | vz.iv.all | vz.iv.last | vz.ivint.all | vz.ivint.last | vz.last | vss.iv.all | vss.sparse.last | cav.iv.last | cav.iv.all | aucinf.obs | aucinf.obs_se | aucinf.obs_df | aucinf.pred | aumcinf.obs | aumcinf.obs_se | aumcinf.obs_df | aumcinf.pred | aucint.inf.obs | aucint.inf.pred | aumcint.inf.obs | aumcint.inf.pred | aucivint.inf.obs | aucivint.inf.pred | aucivinf.obs | aucivinf.obs_se | aucivinf.obs_df | aucivinf.pred | aucivpbext.inf.obs | aucivpbext.inf.pred | aumcivint.inf.pred | aumcivint.inf.obs | aumcivinf.obs | aumcivinf.obs_se | aumcivinf.obs_df | aumcivinf.pred | thalf.eff.iv.all | aucpext.inf.obs | aucpext.inf.pred | kel.iv.all | kel.sparse.last | cl.inf.obs | cl.inf.pred | cl.int.inf.obs | cl.int.inf.pred | cl.iv.inf.obs | cl.iv.inf.pred | cl.ivint.inf.pred | cl.ivint.inf.obs | f.inf.obs | f.inf.pred | f.int.inf.obs | f.int.inf.pred | mrt.inf.obs | mrt.inf.pred | mrt.int.inf.obs | mrt.int.inf.pred | mrt.iv.inf.obs | mrt.iv.inf.pred | mrt.ivint.inf.pred | mrt.ivint.inf.obs | mrt.md.inf.obs | mrt.md.inf.pred | mrt.ivmd.inf.obs | mrt.ivmd.inf.pred | vz.inf.obs | vz.inf.pred | vz.int.inf.obs | vz.int.inf.pred | vz.iv.inf.obs | vz.iv.inf.pred | vz.ivint.inf.pred | vz.ivint.inf.obs | vz.sparse.last | vss.inf.obs | vss.inf.pred | vss.iv.inf.obs | vss.iv.inf.pred | vss.md.inf.obs | vss.md.inf.pred | vss.ivmd.inf.obs | vss.ivmd.inf.pred | vss.int.inf.obs | vss.int.inf.pred | vss.ivint.inf.pred | vss.ivint.inf.obs | cav.int.inf.obs | cav.int.inf.pred | cav.ivint.inf.obs | cav.ivint.inf.pred | ratio.aucinf.obs | ratio.aucinf.pred | thalf.eff.inf.obs | thalf.eff.inf.pred | thalf.eff.int.inf.pred | thalf.eff.int.inf.obs | thalf.eff.iv.inf.obs | thalf.eff.iv.inf.pred | thalf.eff.ivint.inf.pred | thalf.eff.ivint.inf.obs | kel.inf.obs | kel.inf.pred | kel.iv.inf.obs | kel.iv.inf.pred | kel.int.inf.obs | kel.int.inf.pred | kel.ivint.inf.pred | kel.ivint.inf.obs | auclast.dn | aucall.dn | aucinf.obs.dn | aucinf.pred.dn | aumclast.dn | aumcall.dn | aumcinf.obs.dn | aumcinf.pred.dn | cmax.dn | cmin.dn | clast.obs.dn | clast.pred.dn | cav.last.dn | ctrough.dn | adj_tobit_residual | aucivpbextall | aucivpbextinf.obs | aucivpbextinf.pred | aucivpbextint.all | aucivpbextint.last | aucivpbextlast | aucpext.obs | aucpext.pred | cav | cav.dn | cl.iv.obs | cl.iv.pred | cl.obs | cl.pred | clr.obs | clr.pred | count_conc | count_conc_measured | f.int.obs | f.int.pred | f.obs | f.pred | kel.iv.obs | kel.iv.pred | kel.obs | kel.pred | lambda.z.n.points_blq | mrt.iv.obs | mrt.iv.pred | mrt.ivmd.obs | mrt.ivmd.pred | mrt.md.obs | mrt.md.pred | mrt.obs | mrt.pred | thalf.eff.iv.obs | thalf.eff.iv.pred | thalf.eff.obs | thalf.eff.pred | time_above | tobit_residual | vss.iv.obs | vss.iv.pred | vss.ivmd.obs | vss.ivmd.pred | vss.md.obs | vss.md.pred | vss.obs | vss.pred | vz.iv.obs | vz.iv.pred | vz.obs | vz.pred |
|---:|---:|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| 0 | 24 | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE |
| 0 | Inf | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE |

### allow_partial_missing_units

When using unit assignment and conversions, should some units be allowed
to be missing?

The default value is: FALSE

### hl_method

The method used to calculate the half-life and related parameters.
Options are: “log-linear”, “tobit”

The default value is: log-linear

### sparse_lambda_z_se

How the standard error of a sparse AUCinf,obs or AUMCinf,obs accounts
for the estimated lambda.z: “delta” (the default) adds its uncertainty
with the delta method, and “none” treats it as known (Yuan 1993).
Options are: “delta”, “none”

The default value is: delta

### tobit_n_points_penalty

The penalty exponent applied to the number of points when selecting the
best Tobit regression half-life fit. The selection criterion is
tobit.residual \* n_points ^ tobit_n_points_penalty, and the window
minimizing this criterion is selected. A value of 0 (the default) uses
the raw Tobit residual with no point-count penalty.

The default value is: 0

### tobit_optim_control

A list of control parameters passed to stats::optim() when fitting the
Tobit regression half-life. See ?stats::optim for available options.

list()
