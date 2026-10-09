# Sparse AUC to Infinity and the Uncertainty of lambda.z

## Summary and recommendations

For sparse sampling, where each animal gives one or a few samples:

- **Use the delta-method standard error for the AUC to infinity (the
  default).** When little of the AUC is extrapolated, Yuan’s standard
  error, which treats $`\lambda_z`$ as known, and the delta method both
  cover close to the nominal 95% (Yuan 94 to 96%). When about a fifth of
  the AUC is extrapolated, Yuan’s intervals are too narrow (81 to 89%
  coverage), and the delta method is closer to nominal (90 to 94%). Set
  `sparse_lambda_z_se = "none"` for Yuan’s method.
- **Give the AUC a concentration at time 0.** As for any PKNCA AUC, the
  sparse AUC is `NA` without one. Sacrificial designs rarely sample at
  the dose, so after an extravascular dose impute zero with
  `impute = "start_conc0"`. After an IV bolus, request the IV parameters
  (`aucivlast`, `aucivinf.obs`): they back-extrapolate $`C_0`$ from the
  mean profile and include its uncertainty.
- **Treat the AUMC, and the MRT and Vss that come from it, with
  caution.** The AUMC to infinity was biased low in most scenarios, and
  its confidence intervals under-covered in every scenario, even with
  the delta method (79 to 92%), most when elimination was slow.
- **The half-life of the mean profile is not the typical animal’s
  half-life.** It was too long when the terminal phase was well sampled
  (by up to 11%) and too short when the profile was cut short by BLQ
  samples or a two-compartment distribution (down to -10%). Sample long
  enough to see at least three terminal half-lives.
- **Cmax of the mean profile reads high with few animals per time.**
  Taking the maximum of noisy means near a broad peak overestimated Cmax
  by up to 10%.
- **Geometric-mean profiles were evaluated and not adopted.** They were
  no more biased and were as precise or modestly more precise, but they
  estimate a different quantity (the typical animal rather than the
  population mean curve), need a rule for BLQ samples that drives their
  BLQ results, and fall outside the variance methods for sparse AUCs,
  which are for arithmetic means; adopting them would change all sparse
  calculations for a modest gain.
- **The bootstrap
  ([`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md))
  gives intervals for any parameter, but they are too narrow with few
  animals at each time.** With three or four animals per time, its 95%
  intervals for the AUC to infinity covered 82 to 90% of the time.
  Prefer the analytical standard errors for the AUCs, and use the
  bootstrap for parameters and comparisons that have none, such as Cmax
  and ratios between groups. With 20 or more animals per time, its
  standard error was accurate and its intervals matched the delta
  method’s.
- **With many animals, the bias of the sparse estimate dominates.** BLQ
  samples and the extrapolation of the mean profile biased the AUC to
  infinity low (by about 7% with BLQ samples here), whatever the number
  of animals and whichever half-life was used, so with many animals
  every confidence interval missed the truth more often than its nominal
  level.
- **The Tobit half-life was evaluated with BLQ samples and not adopted
  for the sparse AUC.** The Tobit fit of the mean profile
  (`hl_method = "tobit"`, with the LLOQ carried through the mean
  profile) gave nearly the same AUC to infinity as the log-linear fit,
  and it has no delta-method standard error. A (mixed-effects) Tobit fit
  of the individual samples was slightly less biased and more precise,
  but its standard error added to Yuan’s covered less well than the
  delta method with slow elimination (87 to 92% against 91 to 94%), and
  neither Tobit fit removed the bias that BLQ samples cause.

## Introduction

With sparse sampling, each animal contributes only one or a few samples
to a concentration-time profile, so there is no individual AUC to
summarize. Instead, the AUC is estimated from the mean concentration at
each time, and its standard error comes from the variability between
animals at each time. Bailer (1988) gave the estimator and its variance
for the AUC from time 0 to the last sampling time with serial sacrifice
(one sample per animal). Nedelman and Jia (1998) extended it to designs
where animals give more than one sample, with a Satterthwaite
approximation for the degrees of freedom, and Holder (2001) gave an
unbiased estimator of the covariance between times. Yuan (1993) extended
Bailer’s method to the AUC from 0 to infinity by adding the
extrapolation $`\bar{y}_n/\lambda_z`$, treating the terminal elimination
rate $`\lambda_z`$ as known.

In practice, $`\lambda_z`$ is estimated from the same data, so its
uncertainty adds to that of the AUC to infinity. This vignette describes
how PKNCA calculates the sparse AUC and AUMC to infinity with their
standard errors and degrees of freedom, gives a delta-method extension
of Yuan’s method that includes the uncertainty in $`\lambda_z`$, extends
both to IV bolus dosing, and compares the methods in a
simulation-estimation study. A second study compares arithmetic and
geometric mean profiles.

## The sparse AUC to the last measurement

At each sampling time $`t_i`$ ($`i = 0, \ldots, n`$), $`r_i`$ animals
are sampled and $`\bar{y}_i`$ is the arithmetic mean concentration.
$`r_{ij}`$ animals are sampled at both $`t_i`$ and $`t_j`$
($`r_{ii} = r_i`$). The linear trapezoidal AUC of the mean profile is a
weighted sum of the means,

``` math
\widehat{AUC}_{0-t_{last}} = \sum_{i=0}^{n} w_i \bar{y}_i,
\quad w_0 = \frac{t_1 - t_0}{2},
\quad w_i = \frac{t_{i+1} - t_{i-1}}{2},
\quad w_n = \frac{t_n - t_{n-1}}{2},
```

where $`t_n = t_{last}`$ is the last time with a positive mean. Since
the estimate is linear in the means, its variance is

``` math
\text{Var}\left(\widehat{AUC}_{0-t_{last}}\right) = \sum_{i}\sum_{j} w_i w_j \frac{r_{ij}\,\sigma_{ij}}{r_i r_j},
```

with $`\sigma_{ij}`$ the covariance of the concentrations at $`t_i`$ and
$`t_j`$ within an animal. PKNCA estimates $`\sigma_{ii}`$ with the
sample variance and $`\sigma_{ij}`$ ($`i \neq j`$) with the unbiased
estimator of Holder (2001), setting it to 0 when fewer than two animals
are sampled at both times. With serial sacrifice, $`r_{ij} = 0`$ for
$`i \neq j`$ and this is Bailer’s (1988) variance,
$`\sum_i w_i^2 s_i^2/r_i`$.

Only times up to $`t_{last}`$ have weight. When more than half of the
samples at a time are below the limit of quantification (BLQ), PKNCA
sets that time’s mean to zero; times after the last positive mean are
not part of $`AUC_{0-t_{last}}`$, and they contribute nothing to its
variance either.

As for any AUC in PKNCA, the area starts at the start of the interval,
so a concentration is needed there, measured or imputed; without one,
the sparse AUC is `NA`. Animals are rarely sampled at the dose in
sacrificial designs, so after an extravascular dose the usual choice is
to impute a concentration of zero with `impute = "start_conc0"`. An
imputed zero is known rather than measured, so it has weight in the
estimate (as $`\bar{y}_0 = 0`$) but no variance.

## Extrapolation to infinity (Yuan 1993)

With first-order terminal elimination, the area after $`t_{last}`$ is
$`\bar{y}_{n}/\lambda_z`$, so

``` math
\widehat{AUC}_{0-\infty} = \sum_{i=0}^{n} w_i \bar{y}_i + \frac{\bar{y}_n}{\lambda_z}.
```

This is still linear in the means if $`\lambda_z`$ is known, with the
last weight increased by $`1/\lambda_z`$. Yuan’s (1993) variance (his
equation 4) is Bailer’s with that weight, $`g_n = w_n + 1/\lambda_z`$:

``` math
\text{Var}\left(\widehat{AUC}_{0-\infty}\right) = \sum_{i}\sum_{j} g_i g_j \frac{r_{ij}\,\sigma_{ij}}{r_i r_j},
\qquad g_i = w_i + \frac{\delta_{i,n}}{\lambda_z}.
```

Written this way, the method applies to any sampling design, not only
serial sacrifice.

The AUMC is the AUC of the moment curve $`t\,C(t)`$. Its estimate uses
the moment means $`\bar{m}_i = t_i \bar{y}_i`$, and the extrapolation
$`t_{last} C_{last}/\lambda_z + C_{last}/\lambda_z^2`$ is
$`\bar{m}_n\left(1/\lambda_z + 1/(t_{last}\lambda_z^2)\right)`$, so the
AUMC weights are
$`g_i = w_i + \delta_{i,n}\left(1/\lambda_z + 1/(t_{last}\lambda_z^2)\right)`$
applied to the moment means, with the covariances of the moments
$`t_i t_j \sigma_{ij}`$.

## IV bolus: the back-extrapolated C0

After an IV bolus, the concentration at time 0 is not zero, and it
cannot be measured. As for dense data, PKNCA estimates it from the mean
profile with the methods of
[`pk.calc.c0()`](https://humanpred.github.io/pknca/reference/pk.calc.c0.md):
log-linear back-extrapolation from the first two means when they
decline,

``` math
\hat{C}_0 = \bar{y}_1 \left(\frac{\bar{y}_1}{\bar{y}_2}\right)^{t_1/(t_2 - t_1)},
```

and otherwise $`\bar{y}_1`$. The AUC adds the trapezoid from time 0 to
$`t_1`$, $`t_1(\hat{C}_0 + \bar{y}_1)/2`$. $`\hat{C}_0`$ is a smooth
function of the first two means, so its uncertainty enters the variance
through its gradient, as in the next section: the weights of
$`\bar{y}_1`$ and $`\bar{y}_2`$ gain
$`(t_1/2)\,\partial \hat{C}_0/\partial \bar{y}_j`$, with

``` math
\frac{\partial \hat{C}_0}{\partial \bar{y}_1} = \frac{\hat{C}_0\, t_2}{(t_2 - t_1)\,\bar{y}_1},
\qquad
\frac{\partial \hat{C}_0}{\partial \bar{y}_2} = -\frac{\hat{C}_0\, t_1}{(t_2 - t_1)\,\bar{y}_2}.
```

With the linear trapezoidal rule, the AUMC from time 0 to $`t_1`$ is
$`t_1^2\bar{y}_1/2`$ whatever $`C_0`$ is, so $`C_0`$ does not affect the
AUMC. These are the sparse `aucivlast`, `aucivall`, and `aucivinf.obs`
(and their AUMC equivalents), each with its standard error and degrees
of freedom.

## The uncertainty of lambda.z (delta method)

$`\lambda_z`$ is estimated from the mean profile: PKNCA fits a line to
the log mean concentrations at the half-life points, chosen
automatically by the adjusted $`r^2`$ (see
[`vignette("v06-half-life-calculation")`](https://humanpred.github.io/pknca/articles/v06-half-life-calculation.md)).
For a given set of half-life points $`H`$, the estimate is minus the
least-squares slope,

``` math
\hat{\lambda}_z = -\sum_{j \in H} c_j \log \bar{y}_j,
\qquad c_j = \frac{t_j - \bar{t}_H}{\sum_{k \in H}\left(t_k - \bar{t}_H\right)^2},
```

a smooth function of the means. So $`\widehat{AUC}_{0-\infty}`$ is a
smooth function of the means, and the delta method gives its variance
from the same covariance of the means with the gradient in place of the
weights:

``` math
g_j = \frac{\partial \widehat{AUC}_{0-\infty}}{\partial \bar{y}_j}
= w_j + \frac{\delta_{j,n}}{\lambda_z}
+ \frac{\bar{y}_n}{\lambda_z^2}\,\frac{c_j}{\bar{y}_j}\,\mathbb{1}_{j \in H}.
```

The last term is the uncertainty in $`\lambda_z`$. Because the gradient
is taken with respect to all of the means together, the variance
includes the covariance of $`\hat{\lambda}_z`$ with $`\bar{y}_n`$ and
with $`\widehat{AUC}_{0-t_{last}}`$. Those covariances matter: a high
mean at an early half-life point raises the AUC to $`t_{last}`$ but
steepens the slope, which lowers the extrapolated area, so the two
partly cancel. Adding a separately estimated variance of
$`\hat{\lambda}_z`$ to Yuan’s variance would miss that.

For the AUMC, with the moment means,
$`\hat{\lambda}_z = -\sum_{j \in H} c_j \left(\log \bar{m}_j - \log t_j\right)`$
and

``` math
g_j = w_j + \delta_{j,n}\left(\frac{1}{\lambda_z} + \frac{1}{t_{last}\lambda_z^2}\right)
+ \bar{m}_n\left(\frac{1}{\lambda_z^2} + \frac{2}{t_{last}\lambda_z^3}\right)\frac{c_j}{\bar{m}_j}\,\mathbb{1}_{j \in H}.
```

The method conditions on the selected half-life points: the variability
from choosing them is not included. It is a first-order approximation,
which is most accurate when the coefficient of variation of the means at
the half-life points is small.

## Degrees of freedom

Confidence intervals use a $`t`$ distribution. The variance estimate is
a quadratic form in the individual measurements $`y`$,
$`\hat{V} = y^T M y`$, where $`M`$ centers the measurements at each time
and weights the products of each animal’s measurements by
$`g_i g_j r_{ij}/(r_i r_j h_{ij})`$, with $`h_{ij}`$ the divisor of the
Holder covariance. With $`\Omega`$ the covariance of the measurements,
Nedelman and Jia’s (1998) equation 6 gives the Satterthwaite degrees of
freedom,

``` math
\nu = \frac{2\,E^2}{V}, \qquad E = \text{tr}(M\Omega), \qquad V = 2\,\text{tr}(M\Omega M\Omega).
```

With serial sacrifice, this is equation 6a of Nedelman, Gibiansky, and
Lau (1995). PKNCA uses the same expression with the weights $`g`$ for
the AUC and AUMC to infinity, with or without the delta-method terms.

## An alternative: lambda.z from the individual samples

Instead of the log means, $`\lambda_z`$ could be estimated from every
individual sample in the terminal phase, with its standard error from
that regression. Samples below the limit of quantification are censored,
so the regression is a Tobit regression on the log concentrations; when
animals give more than one sample, a random intercept for each animal
accounts for their correlation. The variance of $`\hat{\lambda}_z`$ is
then added to Yuan’s variance.

Two properties of this approach differ from the delta method. A line
through the individual log concentrations follows the geometric-mean
profile, while the AUC and $`C_{last}`$ come from the arithmetic means;
the two have the same terminal slope only when the between-animal
coefficient of variation is the same at every terminal time. And the
regression does not give the covariance of $`\hat{\lambda}_z`$ with the
means, so it is added as though it were independent. The simulation
below compares both.

## Simulation-estimation study

### Design

Both studies in this vignette share one design
(`data-raw/sparse_simulation_design.R` in the PKNCA source).
Concentrations come from one- and two-compartment models (pmxTools)
after a dose of 100, given orally or as an IV bolus, with log-normal
between-animal variability (30% on each structural parameter) and a
multiplicative residual error (15%) with mean 1:

- **One compartment:** $`V`$ 10, $`k_e`$ 0.15/hr (fast elimination,
  half-life 4.6 hr) or 0.07/hr (slow, 9.9 hr), and oral $`k_a`$ 5/hr
  (Tmax 0.7 to 0.9 hr).
- **Two compartments:** $`V_1`$ 10, $`V_2`$ 15, $`Q`$ 6, and $`CL`$
  chosen for the same terminal half-lives after a distribution phase
  with a half-life of about 0.5 hr; oral $`k_a`$ 2.5/hr (Tmax 0.6 to 0.7
  hr).

The slow elimination leaves about a fifth of the AUC to extrapolate
after 24 hours, and the fast elimination less than a tenth. Two limits
of quantification gave no BLQ samples or about a third of the samples at
24 hours BLQ (70% of the typical concentration at 24 hours). No animal
was sampled at the dose. The serial-sacrifice design sampled 4 animals
at each of 9 times (0.25, 0.5, 1, 2, 4, 6, 8, 12, 24 hours for oral
dosing; for IV bolus dosing, the first time was 5 minutes and 6 hours
was omitted); the batch design sampled three batches of 4 animals, each
batch at a third of those times. With 32 scenarios (two models, two
routes, two designs, two limits of quantification, and two elimination
rates), the standard error study had 5,000 replicates per scenario.

The truth is the AUC (and AUMC) from 0 to infinity of the population
mean concentration curve, which is what the arithmetic means estimate:
the mean of the individual values over 100,000 virtual animals (Monte
Carlo standard error at most 0.24%). For each replicate, the oral
concentration at time 0 was imputed as zero and the IV bolus $`C_0`$ was
back-extrapolated, the half-life was fit to the mean profile as PKNCA
does, and three standard errors were calculated:

- **Yuan:** $`\lambda_z`$ treated as known
  (`sparse_lambda_z_se = "none"`);
- **Delta:** the delta method for $`\lambda_z`$
  (`sparse_lambda_z_se = "delta"`);
- **Individual:** $`\lambda_z`$ and its standard error from a Tobit
  regression of the individual samples from the first half-life time
  onward (with a random intercept for each animal in the batch design),
  with that $`\lambda_z`$ in the extrapolation and its variance added to
  Yuan’s.

The simulation is in `data-raw/sparse_aucinf_simulation.R` in the PKNCA
source, which was run with PKNCA 0.12.1.9002 and pmxTools 1.5 (R version
4.6.1 (2026-06-24), 2026-10-07); every replicate has its own seed, so
the results can be reproduced.

### Results: coverage of the AUC to infinity

| Model | Route | Design | BLQ | Elimination | Extrap. (%) | Coverage Yuan | Coverage delta | Coverage indiv. | CI width Yuan | CI width delta | CI width indiv. |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | none | fast | 4.5 | 94.9 | 95.5 | 94.9 | 41 | 42 | 40 |
| 1-cmt | IV bolus | serial | none | fast | 4.4 | 95.9 | 96.3 | 95.8 | 44 | 45 | 43 |
| 1-cmt | oral | batch | none | fast | 4.5 | 95.0 | 95.4 | 94.8 | 60 | 61 | 59 |
| 1-cmt | IV bolus | batch | none | fast | 4.3 | 95.9 | 96.2 | 95.8 | 59 | 60 | 58 |
| 1-cmt | oral | serial | moderate | fast | 7.2 | 93.7 | 95.1 | 94.1 | 41 | 44 | 40 |
| 1-cmt | IV bolus | serial | moderate | fast | 6.8 | 94.4 | 95.7 | 94.7 | 45 | 47 | 44 |
| 1-cmt | oral | batch | moderate | fast | 7.3 | 94.9 | 95.6 | 94.9 | 61 | 64 | 59 |
| 1-cmt | IV bolus | batch | moderate | fast | 7.0 | 94.8 | 95.7 | 94.7 | 59 | 62 | 58 |
| 1-cmt | oral | serial | none | slow | 21.1 | 84.5 | 90.6 | 85.7 | 45 | 64 | 46 |
| 1-cmt | IV bolus | serial | none | slow | 20.6 | 86.7 | 91.2 | 87.3 | 45 | 61 | 45 |
| 1-cmt | oral | batch | none | slow | 20.8 | 88.5 | 91.9 | 88.8 | 57 | 72 | 56 |
| 1-cmt | IV bolus | batch | none | slow | 20.3 | 89.1 | 92.0 | 89.6 | 57 | 70 | 56 |
| 1-cmt | oral | serial | moderate | slow | 20.9 | 82.9 | 92.2 | 88.8 | 51 | 77 | 54 |
| 1-cmt | IV bolus | serial | moderate | slow | 20.7 | 85.7 | 93.6 | 90.2 | 52 | 74 | 55 |
| 1-cmt | oral | batch | moderate | slow | 20.9 | 87.7 | 93.6 | 91.4 | 63 | 83 | 65 |
| 1-cmt | IV bolus | batch | moderate | slow | 20.9 | 87.8 | 93.4 | 91.0 | 63 | 82 | 65 |
| 2-cmt | oral | serial | none | fast | 3.5 | 94.4 | 95.2 | 94.6 | 31 | 32 | 31 |
| 2-cmt | IV bolus | serial | none | fast | 3.3 | 93.7 | 95.1 | 94.2 | 32 | 33 | 32 |
| 2-cmt | oral | batch | none | fast | 3.6 | 95.4 | 95.9 | 95.4 | 43 | 44 | 42 |
| 2-cmt | IV bolus | batch | none | fast | 3.2 | 94.9 | 95.5 | 95.0 | 43 | 44 | 42 |
| 2-cmt | oral | serial | moderate | fast | 4.9 | 94.1 | 95.7 | 94.9 | 31 | 33 | 31 |
| 2-cmt | IV bolus | serial | moderate | fast | 4.6 | 94.1 | 95.5 | 94.6 | 32 | 34 | 32 |
| 2-cmt | oral | batch | moderate | fast | 5.0 | 94.7 | 95.7 | 95.2 | 43 | 45 | 43 |
| 2-cmt | IV bolus | batch | moderate | fast | 4.5 | 94.7 | 95.5 | 94.8 | 42 | 44 | 42 |
| 2-cmt | oral | serial | none | slow | 18.4 | 83.6 | 90.2 | 84.7 | 34 | 50 | 34 |
| 2-cmt | IV bolus | serial | none | slow | 17.6 | 85.5 | 91.6 | 86.3 | 33 | 47 | 34 |
| 2-cmt | oral | batch | none | slow | 18.4 | 87.3 | 92.4 | 88.1 | 40 | 54 | 40 |
| 2-cmt | IV bolus | batch | none | slow | 17.6 | 88.1 | 92.5 | 88.3 | 39 | 52 | 39 |
| 2-cmt | oral | serial | moderate | slow | 17.9 | 81.3 | 91.9 | 87.8 | 41 | 61 | 44 |
| 2-cmt | IV bolus | serial | moderate | slow | 17.1 | 83.6 | 92.1 | 88.7 | 40 | 58 | 42 |
| 2-cmt | oral | batch | moderate | slow | 17.6 | 84.3 | 92.9 | 89.6 | 46 | 64 | 49 |
| 2-cmt | IV bolus | batch | moderate | slow | 17.1 | 86.1 | 93.3 | 90.3 | 46 | 63 | 48 |

### Results: coverage of the AUMC to infinity

| Model | Route | Design | BLQ | Elimination | Extrap. (%) | Coverage Yuan | Coverage delta | Coverage indiv. | CI width Yuan | CI width delta | CI width indiv. |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | none | fast | 4.5 | 85.3 | 87.5 | 83.9 | 74 | 88 | 71 |
| 1-cmt | IV bolus | serial | none | fast | 4.4 | 85.3 | 87.3 | 84.1 | 75 | 86 | 72 |
| 1-cmt | oral | batch | none | fast | 4.5 | 86.9 | 88.8 | 85.6 | 84 | 95 | 80 |
| 1-cmt | IV bolus | batch | none | fast | 4.3 | 86.3 | 87.7 | 85.1 | 82 | 91 | 78 |
| 1-cmt | oral | serial | moderate | fast | 7.2 | 84.0 | 89.0 | 84.7 | 80 | 101 | 76 |
| 1-cmt | IV bolus | serial | moderate | fast | 6.8 | 85.1 | 89.5 | 84.8 | 80 | 99 | 77 |
| 1-cmt | oral | batch | moderate | fast | 7.3 | 88.1 | 91.8 | 88.3 | 91 | 111 | 87 |
| 1-cmt | IV bolus | batch | moderate | fast | 7.0 | 86.5 | 89.9 | 86.1 | 88 | 107 | 84 |
| 1-cmt | oral | serial | none | slow | 21.1 | 66.5 | 82.8 | 67.8 | 83 | 159 | 83 |
| 1-cmt | IV bolus | serial | none | slow | 20.6 | 68.2 | 81.8 | 68.6 | 83 | 151 | 82 |
| 1-cmt | oral | batch | none | slow | 20.8 | 68.5 | 82.1 | 68.0 | 86 | 153 | 81 |
| 1-cmt | IV bolus | batch | none | slow | 20.3 | 69.8 | 82.5 | 69.3 | 86 | 146 | 81 |
| 1-cmt | oral | serial | moderate | slow | 20.9 | 66.0 | 84.6 | 75.2 | 99 | 185 | 109 |
| 1-cmt | IV bolus | serial | moderate | slow | 20.7 | 67.8 | 86.2 | 76.6 | 100 | 177 | 107 |
| 1-cmt | oral | batch | moderate | slow | 20.9 | 69.4 | 85.6 | 77.5 | 102 | 178 | 107 |
| 1-cmt | IV bolus | batch | moderate | slow | 20.9 | 69.7 | 85.8 | 77.6 | 101 | 171 | 106 |
| 2-cmt | oral | serial | none | fast | 3.5 | 85.0 | 87.4 | 83.5 | 68 | 81 | 65 |
| 2-cmt | IV bolus | serial | none | fast | 3.3 | 84.3 | 86.7 | 82.8 | 70 | 82 | 67 |
| 2-cmt | oral | batch | none | fast | 3.6 | 86.7 | 88.7 | 85.6 | 78 | 89 | 74 |
| 2-cmt | IV bolus | batch | none | fast | 3.2 | 85.4 | 87.5 | 83.9 | 77 | 87 | 73 |
| 2-cmt | oral | serial | moderate | fast | 4.9 | 82.8 | 87.5 | 83.8 | 72 | 91 | 70 |
| 2-cmt | IV bolus | serial | moderate | fast | 4.6 | 82.6 | 86.9 | 83.2 | 74 | 92 | 72 |
| 2-cmt | oral | batch | moderate | fast | 5.0 | 85.0 | 89.5 | 86.3 | 81 | 98 | 80 |
| 2-cmt | IV bolus | batch | moderate | fast | 4.5 | 84.0 | 87.5 | 84.0 | 79 | 95 | 77 |
| 2-cmt | oral | serial | none | slow | 18.4 | 62.5 | 80.0 | 61.9 | 70 | 134 | 69 |
| 2-cmt | IV bolus | serial | none | slow | 17.6 | 62.2 | 79.9 | 60.9 | 70 | 129 | 68 |
| 2-cmt | oral | batch | none | slow | 18.4 | 64.5 | 81.2 | 62.8 | 74 | 135 | 69 |
| 2-cmt | IV bolus | batch | none | slow | 17.6 | 62.9 | 79.2 | 61.2 | 72 | 129 | 69 |
| 2-cmt | oral | serial | moderate | slow | 17.9 | 62.1 | 82.4 | 71.8 | 86 | 158 | 97 |
| 2-cmt | IV bolus | serial | moderate | slow | 17.1 | 60.5 | 80.3 | 69.1 | 84 | 148 | 94 |
| 2-cmt | oral | batch | moderate | slow | 17.6 | 62.1 | 81.9 | 72.3 | 87 | 154 | 97 |
| 2-cmt | IV bolus | batch | moderate | slow | 17.1 | 62.8 | 81.7 | 71.4 | 87 | 151 | 96 |

Coverage is the percentage of 95% confidence intervals that contain the
truth, and the CI width is the median width relative to the truth (%).
The Monte Carlo standard error of each coverage is at most 0.7
percentage points.

### Results: the bootstrap

The bootstrap of Shen and Machado (2017)
([`sparse_bootstrap()`](https://humanpred.github.io/pknca/reference/sparse_bootstrap.md))
was run on the first 2,000 data sets of each scenario with 200
replicates each, its default. Each replicate resampled the animals
within each sampling time (or batch), and its AUC and AUMC to infinity
were calculated as for the original data. Two intervals were formed: the
percentile interval of the replicates and the estimate plus or minus
1.96 bootstrap standard errors (the standard deviation of the
replicates). The delta method (on all of the scenario’s data sets, which
include these) is shown for comparison.

| Model | Route | Design | BLQ | Elimination | Coverage percentile | Coverage boot. SE | Coverage delta | CI width percentile | CI width delta |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | none | fast | 87.8 | 90.5 | 95.5 | 31 | 42 |
| 1-cmt | IV bolus | serial | none | fast | 86.7 | 89.2 | 96.3 | 33 | 45 |
| 1-cmt | oral | batch | none | fast | 85.4 | 86.8 | 95.4 | 41 | 61 |
| 1-cmt | IV bolus | batch | none | fast | 86.3 | 88.6 | 96.2 | 41 | 60 |
| 1-cmt | oral | serial | moderate | fast | 87.5 | 92.2 | 95.1 | 36 | 44 |
| 1-cmt | IV bolus | serial | moderate | fast | 88.3 | 92.8 | 95.7 | 37 | 47 |
| 1-cmt | oral | batch | moderate | fast | 88.0 | 89.9 | 95.6 | 46 | 64 |
| 1-cmt | IV bolus | batch | moderate | fast | 87.0 | 89.6 | 95.7 | 44 | 62 |
| 1-cmt | oral | serial | none | slow | 82.0 | 84.1 | 90.6 | 45 | 64 |
| 1-cmt | IV bolus | serial | none | slow | 83.1 | 85.3 | 91.2 | 43 | 61 |
| 1-cmt | oral | batch | none | slow | 81.8 | 84.2 | 91.9 | 48 | 72 |
| 1-cmt | IV bolus | batch | none | slow | 81.6 | 83.8 | 92.0 | 47 | 70 |
| 1-cmt | oral | serial | moderate | slow | 89.4 | 90.3 | 92.2 | 64 | 77 |
| 1-cmt | IV bolus | serial | moderate | slow | 89.6 | 90.4 | 93.6 | 62 | 74 |
| 1-cmt | oral | batch | moderate | slow | 89.6 | 91.1 | 93.6 | 67 | 83 |
| 1-cmt | IV bolus | batch | moderate | slow | 89.6 | 90.1 | 93.4 | 63 | 82 |
| 2-cmt | oral | serial | none | fast | 86.5 | 88.8 | 95.2 | 25 | 32 |
| 2-cmt | IV bolus | serial | none | fast | 83.7 | 86.6 | 95.1 | 25 | 33 |
| 2-cmt | oral | batch | none | fast | 84.9 | 87.4 | 95.9 | 30 | 44 |
| 2-cmt | IV bolus | batch | none | fast | 84.0 | 87.1 | 95.5 | 30 | 44 |
| 2-cmt | oral | serial | moderate | fast | 89.0 | 91.6 | 95.7 | 27 | 33 |
| 2-cmt | IV bolus | serial | moderate | fast | 85.2 | 88.1 | 95.5 | 27 | 34 |
| 2-cmt | oral | batch | moderate | fast | 87.3 | 90.0 | 95.7 | 33 | 45 |
| 2-cmt | IV bolus | batch | moderate | fast | 86.4 | 89.8 | 95.5 | 32 | 44 |
| 2-cmt | oral | serial | none | slow | 81.8 | 82.9 | 90.2 | 33 | 50 |
| 2-cmt | IV bolus | serial | none | slow | 83.2 | 83.9 | 91.6 | 32 | 47 |
| 2-cmt | oral | batch | none | slow | 82.4 | 84.4 | 92.4 | 35 | 54 |
| 2-cmt | IV bolus | batch | none | slow | 83.2 | 83.9 | 92.5 | 35 | 52 |
| 2-cmt | oral | serial | moderate | slow | 86.4 | 86.2 | 91.9 | 42 | 61 |
| 2-cmt | IV bolus | serial | moderate | slow | 87.1 | 86.6 | 92.1 | 40 | 58 |
| 2-cmt | oral | batch | moderate | slow | 86.7 | 86.9 | 92.9 | 45 | 64 |
| 2-cmt | IV bolus | batch | moderate | slow | 89.0 | 89.2 | 93.3 | 44 | 63 |

| Model | Route | Design | BLQ | Elimination | Coverage percentile | Coverage boot. SE | Coverage delta | CI width percentile | CI width delta |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | none | fast | 79.8 | 81.0 | 87.5 | 58 | 88 |
| 1-cmt | IV bolus | serial | none | fast | 77.6 | 77.4 | 87.3 | 58 | 86 |
| 1-cmt | oral | batch | none | fast | 78.6 | 79.0 | 88.8 | 61 | 95 |
| 1-cmt | IV bolus | batch | none | fast | 79.1 | 80.0 | 87.7 | 61 | 91 |
| 1-cmt | oral | serial | moderate | fast | 88.1 | 88.8 | 89.0 | 87 | 101 |
| 1-cmt | IV bolus | serial | moderate | fast | 87.0 | 86.9 | 89.5 | 82 | 99 |
| 1-cmt | oral | batch | moderate | fast | 87.9 | 89.0 | 91.8 | 92 | 111 |
| 1-cmt | IV bolus | batch | moderate | fast | 87.4 | 87.1 | 89.9 | 87 | 107 |
| 1-cmt | oral | serial | none | slow | 75.8 | 74.0 | 82.8 | 116 | 159 |
| 1-cmt | IV bolus | serial | none | slow | 76.2 | 74.7 | 81.8 | 107 | 151 |
| 1-cmt | oral | batch | none | slow | 75.6 | 73.9 | 82.1 | 108 | 153 |
| 1-cmt | IV bolus | batch | none | slow | 74.8 | 73.8 | 82.5 | 102 | 146 |
| 1-cmt | oral | serial | moderate | slow | 89.0 | 88.5 | 84.6 | 185 | 185 |
| 1-cmt | IV bolus | serial | moderate | slow | 89.4 | 88.2 | 86.2 | 172 | 177 |
| 1-cmt | oral | batch | moderate | slow | 90.0 | 89.6 | 85.6 | 180 | 178 |
| 1-cmt | IV bolus | batch | moderate | slow | 89.4 | 89.4 | 85.8 | 162 | 171 |
| 2-cmt | oral | serial | none | fast | 80.0 | 80.2 | 87.4 | 54 | 81 |
| 2-cmt | IV bolus | serial | none | fast | 77.7 | 77.6 | 86.7 | 55 | 82 |
| 2-cmt | oral | batch | none | fast | 78.0 | 78.9 | 88.7 | 57 | 89 |
| 2-cmt | IV bolus | batch | none | fast | 76.0 | 76.7 | 87.5 | 57 | 87 |
| 2-cmt | oral | serial | moderate | fast | 84.5 | 85.2 | 87.5 | 72 | 91 |
| 2-cmt | IV bolus | serial | moderate | fast | 84.2 | 83.6 | 86.9 | 70 | 92 |
| 2-cmt | oral | batch | moderate | fast | 86.1 | 86.7 | 89.5 | 76 | 98 |
| 2-cmt | IV bolus | batch | moderate | fast | 85.5 | 85.2 | 87.5 | 73 | 95 |
| 2-cmt | oral | serial | none | slow | 74.3 | 70.5 | 80.0 | 89 | 134 |
| 2-cmt | IV bolus | serial | none | slow | 73.2 | 69.0 | 79.9 | 85 | 129 |
| 2-cmt | oral | batch | none | slow | 74.7 | 71.6 | 81.2 | 87 | 135 |
| 2-cmt | IV bolus | batch | none | slow | 71.8 | 68.9 | 79.2 | 85 | 129 |
| 2-cmt | oral | serial | moderate | slow | 80.6 | 77.6 | 82.4 | 112 | 158 |
| 2-cmt | IV bolus | serial | moderate | slow | 80.2 | 74.4 | 80.3 | 105 | 148 |
| 2-cmt | oral | batch | moderate | slow | 82.8 | 80.1 | 81.9 | 113 | 154 |
| 2-cmt | IV bolus | batch | moderate | slow | 83.5 | 79.0 | 81.7 | 110 | 151 |

### Results: the bootstrap with more animals at each time

Published uses of the bootstrap had either a few animals per time (three
mice in Takemoto et al. 2006, which compared only the means and standard
deviations with Bailer’s) or many (about 88 subjects per time and
treatment in the bioequivalence study of Shen and Machado 2017). To see
how the number of animals per time changes the comparison, the
two-compartment, oral, serial-sacrifice design with slow elimination was
simulated with 4, 6, 10, 20, 50, 100 animals per time, without and with
BLQ samples (2,000 data sets each, 200 bootstrap replicates;
`data-raw/sparse_bootstrap_n_profile.R`). The data seeds do not depend
on the number of animals, so 4 animals per time reproduces the data sets
above. The bias is that of the point estimate, which all of the methods
share.

| BLQ | Animals per time | Coverage percentile | Coverage boot. SE | Coverage Yuan | Coverage delta | CI width percentile | CI width delta | Bias (%) |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| none | 4 | 81.8 | 82.9 | 83.9 | 89.9 | 33 | 49 | -2.3 |
| none | 6 | 84.9 | 85.3 | 81.4 | 90.4 | 30 | 38 | -2.4 |
| none | 10 | 87.6 | 87.8 | 77.7 | 89.8 | 25 | 29 | -2.2 |
| none | 20 | 89.8 | 89.6 | 79.8 | 90.0 | 19 | 20 | -1.9 |
| none | 50 | 89.8 | 88.9 | 74.2 | 89.1 | 12 | 13 | -1.8 |
| none | 100 | 86.3 | 85.9 | 69.4 | 85.6 | 9 | 9 | -1.7 |
| moderate | 4 | 86.5 | 86.2 | 80.6 | 90.9 | 42 | 60 | -6.1 |
| moderate | 6 | 89.2 | 87.5 | 76.2 | 88.2 | 38 | 44 | -6.7 |
| moderate | 10 | 90.1 | 86.6 | 69.8 | 83.9 | 31 | 33 | -6.7 |
| moderate | 20 | 84.3 | 78.8 | 55.8 | 74.3 | 22 | 22 | -6.8 |
| moderate | 50 | 55.9 | 50.3 | 30.0 | 49.4 | 14 | 14 | -7.0 |
| moderate | 100 | 29.2 | 26.0 | 11.2 | 25.8 | 10 | 10 | -6.9 |

| BLQ | Animals per time | Coverage percentile | Coverage boot. SE | Coverage Yuan | Coverage delta | CI width percentile | CI width delta | Bias (%) |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| none | 4 | 74.3 | 70.5 | 62.9 | 79.8 | 89 | 135 | -18.6 |
| none | 6 | 75.8 | 71.9 | 56.8 | 77.6 | 83 | 100 | -18.5 |
| none | 10 | 77.0 | 72.2 | 48.9 | 73.6 | 68 | 75 | -17.3 |
| none | 20 | 74.1 | 66.8 | 39.0 | 66.6 | 51 | 51 | -16.7 |
| none | 50 | 59.0 | 52.5 | 21.0 | 51.8 | 33 | 33 | -16.1 |
| none | 100 | 37.1 | 32.6 | 8.7 | 30.6 | 23 | 23 | -15.9 |
| moderate | 4 | 80.6 | 77.6 | 60.5 | 81.3 | 112 | 154 | -29.1 |
| moderate | 6 | 81.7 | 75.8 | 48.0 | 72.8 | 97 | 108 | -29.4 |
| moderate | 10 | 78.8 | 71.0 | 37.9 | 63.1 | 80 | 79 | -29.8 |
| moderate | 20 | 65.5 | 55.2 | 20.9 | 47.0 | 57 | 54 | -29.4 |
| moderate | 50 | 24.6 | 18.0 | 3.9 | 16.2 | 34 | 33 | -30.0 |
| moderate | 100 | 3.8 | 2.4 | 0.1 | 2.1 | 24 | 23 | -29.5 |

### Results: the Tobit half-life with BLQ samples

PKNCA can also fit the half-life by Tobit regression
(`hl_method = "tobit"`), which treats BLQ samples as censored below the
LLOQ rather than dropping them. For sparse data, it fits the mean
profile, with the median LLOQ of the samples at each time and a time
whose mean is BLQ censored. With the BLQ scenarios above (the first
1,000 data sets of each) and the BLQ arm of the profile over the number
of animals per time (2,000 data sets at each number), three estimates of
$`\lambda_z`$ were compared: the log-linear fit of the mean profile
(“log-linear”, as above), the Tobit fit of the mean profile (“Tobit
mean”), and the Tobit fit of the individual samples (“Tobit indiv.”, as
the “individual” method above). Each gave the AUC and AUMC to infinity
from the same sparse AUC to $`t_{last}`$ and mean at $`t_{last}`$, with
these intervals: Yuan’s and the delta method for the log-linear fit;
Yuan’s for the Tobit fit of the mean profile, which has no standard
error for $`\lambda_z`$; Yuan’s variance plus that of $`\lambda_z`$ for
the Tobit fit of the individual samples; and, for each, the bootstrap
percentile interval (200 replicates, each refitting its own
$`\lambda_z`$; `data-raw/sparse_tobit_simulation.R`).

Coverage (%) of the 95% intervals for the AUC to infinity, with four
animals per time (three per batch):

| Model | Route | Design | Elimination | Log-lin. Yuan | Log-lin. delta | Log-lin. boot. | Tobit mean Yuan | Tobit mean boot. | Tobit indiv. Yuan+var | Tobit indiv. boot. |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | fast | 94.9 | 96.3 | 88.0 | 94.5 | 87.9 | 95.5 | 87.7 |
| 1-cmt | IV bolus | serial | fast | 94.9 | 96.4 | 88.2 | 95.0 | 88.1 | 95.0 | 87.7 |
| 1-cmt | oral | batch | fast | 95.2 | 95.5 | 88.5 | 94.9 | 86.9 | 95.2 | 87.1 |
| 1-cmt | IV bolus | batch | fast | 94.9 | 96.2 | 87.3 | 94.7 | 87.5 | 94.7 | 87.0 |
| 1-cmt | oral | serial | slow | 82.7 | 92.9 | 88.8 | 82.0 | 82.2 | 89.0 | 82.8 |
| 1-cmt | IV bolus | serial | slow | 86.3 | 93.5 | 89.7 | 85.8 | 84.4 | 91.2 | 85.0 |
| 1-cmt | oral | batch | slow | 87.5 | 94.3 | 89.9 | 87.2 | 80.6 | 92.2 | 83.9 |
| 1-cmt | IV bolus | batch | slow | 89.1 | 93.8 | 90.3 | 88.8 | 84.1 | 91.5 | 85.4 |
| 2-cmt | oral | serial | fast | 94.2 | 95.6 | 90.2 | 94.5 | 89.4 | 94.7 | 89.4 |
| 2-cmt | IV bolus | serial | fast | 93.5 | 94.9 | 85.4 | 93.7 | 85.0 | 94.4 | 85.7 |
| 2-cmt | oral | batch | fast | 95.1 | 96.4 | 88.4 | 95.3 | 87.1 | 96.0 | 87.6 |
| 2-cmt | IV bolus | batch | fast | 95.2 | 95.8 | 87.2 | 95.4 | 86.7 | 95.5 | 86.8 |
| 2-cmt | oral | serial | slow | 80.6 | 90.9 | 86.5 | 80.6 | 78.9 | 86.7 | 80.1 |
| 2-cmt | IV bolus | serial | slow | 84.2 | 92.0 | 86.6 | 82.6 | 80.2 | 89.5 | 82.1 |
| 2-cmt | oral | batch | slow | 85.0 | 93.4 | 86.2 | 84.8 | 80.0 | 89.5 | 81.2 |
| 2-cmt | IV bolus | batch | slow | 86.0 | 93.6 | 88.9 | 86.3 | 80.9 | 90.4 | 83.3 |

And for the AUMC to infinity:

| Model | Route | Design | Elimination | Log-lin. Yuan | Log-lin. delta | Log-lin. boot. | Tobit mean Yuan | Tobit mean boot. | Tobit indiv. Yuan+var | Tobit indiv. boot. |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | fast | 86.6 | 91.5 | 88.5 | 86.6 | 82.1 | 87.4 | 82.1 |
| 1-cmt | IV bolus | serial | fast | 84.6 | 89.2 | 86.8 | 83.5 | 79.4 | 84.9 | 79.3 |
| 1-cmt | oral | batch | fast | 88.9 | 91.8 | 88.4 | 87.8 | 81.6 | 88.8 | 82.2 |
| 1-cmt | IV bolus | batch | fast | 88.2 | 91.9 | 89.2 | 86.9 | 81.4 | 88.0 | 82.0 |
| 1-cmt | oral | serial | slow | 66.8 | 85.0 | 89.2 | 64.1 | 77.7 | 76.5 | 78.2 |
| 1-cmt | IV bolus | serial | slow | 67.5 | 85.1 | 89.0 | 65.2 | 77.2 | 76.0 | 77.9 |
| 1-cmt | oral | batch | slow | 67.5 | 86.3 | 89.8 | 64.7 | 74.8 | 77.1 | 77.6 |
| 1-cmt | IV bolus | batch | slow | 71.2 | 86.8 | 89.8 | 68.7 | 77.1 | 78.7 | 79.2 |
| 2-cmt | oral | serial | fast | 82.4 | 87.2 | 84.7 | 83.1 | 76.6 | 83.7 | 76.6 |
| 2-cmt | IV bolus | serial | fast | 84.6 | 88.3 | 85.1 | 85.0 | 79.0 | 85.3 | 79.0 |
| 2-cmt | oral | batch | fast | 84.3 | 87.7 | 85.9 | 84.3 | 78.3 | 85.2 | 78.2 |
| 2-cmt | IV bolus | batch | fast | 84.7 | 88.6 | 85.4 | 83.9 | 77.6 | 85.0 | 76.6 |
| 2-cmt | oral | serial | slow | 60.5 | 81.3 | 80.6 | 59.2 | 71.8 | 69.7 | 71.8 |
| 2-cmt | IV bolus | serial | slow | 61.4 | 80.5 | 80.6 | 59.4 | 73.4 | 68.9 | 72.5 |
| 2-cmt | oral | batch | slow | 64.2 | 82.6 | 83.1 | 62.2 | 74.0 | 74.3 | 74.3 |
| 2-cmt | IV bolus | batch | slow | 62.7 | 81.7 | 82.8 | 61.0 | 73.2 | 71.9 | 72.5 |

Bias and median absolute error (MAE), relative to the truth (%), of the
AUC and then the AUMC to infinity with each $`\lambda_z`$ (the point
estimate does not depend on the interval):

| Model | Route | Design | Elimination | Bias log-lin. | Bias Tobit mean | Bias Tobit indiv. | MAE log-lin. | MAE Tobit mean | MAE Tobit indiv. |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | fast | 2.7 | 2.1 | 1.9 | 7.0 | 6.8 | 6.7 |
| 1-cmt | IV bolus | serial | fast | 3.0 | 2.4 | 2.1 | 8.1 | 8.1 | 7.6 |
| 1-cmt | oral | batch | fast | 2.6 | 1.7 | 1.4 | 9.2 | 9.0 | 8.9 |
| 1-cmt | IV bolus | batch | fast | 2.8 | 2.0 | 1.7 | 9.0 | 9.0 | 9.0 |
| 1-cmt | oral | serial | slow | -6.0 | -6.6 | -5.8 | 12.5 | 12.8 | 11.6 |
| 1-cmt | IV bolus | serial | slow | -6.0 | -6.3 | -5.7 | 11.8 | 11.9 | 11.0 |
| 1-cmt | oral | batch | slow | -4.9 | -6.1 | -5.1 | 13.1 | 13.5 | 12.1 |
| 1-cmt | IV bolus | batch | slow | -4.0 | -5.5 | -4.7 | 12.6 | 13.1 | 11.5 |
| 2-cmt | oral | serial | fast | 1.9 | 1.9 | 1.7 | 5.5 | 5.4 | 5.2 |
| 2-cmt | IV bolus | serial | fast | 4.0 | 4.0 | 3.6 | 6.2 | 6.1 | 6.0 |
| 2-cmt | oral | batch | fast | 2.1 | 1.9 | 1.4 | 7.0 | 7.0 | 6.7 |
| 2-cmt | IV bolus | batch | fast | 3.2 | 3.4 | 2.9 | 7.1 | 7.2 | 6.9 |
| 2-cmt | oral | serial | slow | -6.1 | -6.2 | -5.5 | 10.3 | 10.7 | 9.6 |
| 2-cmt | IV bolus | serial | slow | -5.3 | -5.3 | -4.9 | 9.9 | 10.3 | 8.9 |
| 2-cmt | oral | batch | slow | -5.7 | -5.7 | -5.0 | 10.4 | 10.8 | 9.4 |
| 2-cmt | IV bolus | batch | slow | -4.9 | -4.8 | -4.4 | 9.8 | 10.4 | 9.1 |

| Model | Route | Design | Elimination | Bias log-lin. | Bias Tobit mean | Bias Tobit indiv. | MAE log-lin. | MAE Tobit mean | MAE Tobit indiv. |
|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | fast | -5.1 | -6.7 | -7.1 | 16.4 | 16.4 | 14.7 |
| 1-cmt | IV bolus | serial | fast | -6.6 | -8.2 | -8.8 | 16.4 | 17.1 | 15.9 |
| 1-cmt | oral | batch | fast | -5.4 | -7.5 | -7.7 | 16.8 | 17.1 | 16.1 |
| 1-cmt | IV bolus | batch | fast | -7.0 | -9.2 | -10.3 | 17.0 | 17.5 | 16.0 |
| 1-cmt | oral | serial | slow | -23.1 | -25.3 | -21.8 | 35.4 | 37.5 | 31.8 |
| 1-cmt | IV bolus | serial | slow | -25.6 | -26.8 | -24.0 | 34.4 | 35.3 | 31.1 |
| 1-cmt | oral | batch | slow | -22.2 | -25.5 | -22.3 | 34.0 | 36.2 | 30.0 |
| 1-cmt | IV bolus | batch | slow | -21.6 | -23.8 | -21.6 | 33.0 | 35.4 | 28.5 |
| 2-cmt | oral | serial | fast | -8.5 | -9.6 | -10.4 | 16.0 | 16.6 | 15.5 |
| 2-cmt | IV bolus | serial | fast | -9.0 | -8.9 | -10.5 | 15.8 | 16.1 | 15.2 |
| 2-cmt | oral | batch | fast | -8.6 | -9.3 | -10.0 | 17.1 | 18.1 | 16.3 |
| 2-cmt | IV bolus | batch | fast | -9.8 | -9.8 | -11.2 | 17.0 | 17.6 | 16.5 |
| 2-cmt | oral | serial | slow | -29.1 | -29.4 | -26.3 | 34.8 | 36.0 | 32.2 |
| 2-cmt | IV bolus | serial | slow | -30.0 | -29.9 | -27.7 | 35.8 | 37.9 | 32.3 |
| 2-cmt | oral | batch | slow | -27.5 | -27.9 | -25.5 | 33.7 | 35.7 | 30.7 |
| 2-cmt | IV bolus | batch | slow | -28.8 | -28.4 | -27.1 | 35.0 | 37.1 | 31.9 |

Over the number of animals per time (two compartments, oral, serial
sacrifice, slow elimination, BLQ samples), the coverage (%) and the bias
(%) of the AUC to infinity:

| Animals per time | Log-lin. Yuan | Log-lin. delta | Log-lin. boot. | Tobit mean Yuan | Tobit mean boot. | Tobit indiv. Yuan+var | Tobit indiv. boot. | Bias log-lin. | Bias Tobit mean | Bias Tobit indiv. |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 80.6 | 90.9 | 86.5 | 80.6 | 78.9 | 86.7 | 80.1 | -6.1 | -6.2 | -5.5 |
| 6 | 76.2 | 88.2 | 89.2 | 75.3 | 81.3 | 83.9 | 83.0 | -6.7 | -6.7 | -5.8 |
| 10 | 69.8 | 83.9 | 90.1 | 68.4 | 82.2 | 79.7 | 84.5 | -6.7 | -6.8 | -5.6 |
| 20 | 55.8 | 74.3 | 84.3 | 55.5 | 77.1 | 69.4 | 79.2 | -6.8 | -6.9 | -5.6 |
| 50 | 30.0 | 49.4 | 55.9 | 30.6 | 54.6 | 48.2 | 63.0 | -7.0 | -7.0 | -5.6 |
| 100 | 11.2 | 25.8 | 29.2 | 11.3 | 30.6 | 27.4 | 43.5 | -6.9 | -6.8 | -5.5 |

And of the AUMC to infinity:

| Animals per time | Log-lin. Yuan | Log-lin. delta | Log-lin. boot. | Tobit mean Yuan | Tobit mean boot. | Tobit indiv. Yuan+var | Tobit indiv. boot. | Bias log-lin. | Bias Tobit mean | Bias Tobit indiv. |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 60.5 | 81.3 | 80.6 | 59.2 | 71.8 | 69.7 | 71.8 | -29.1 | -29.4 | -26.3 |
| 6 | 48.0 | 72.8 | 81.7 | 47.5 | 72.0 | 60.2 | 72.5 | -29.4 | -30.1 | -26.3 |
| 10 | 37.9 | 63.1 | 78.8 | 37.2 | 70.2 | 50.7 | 71.0 | -29.8 | -29.8 | -26.0 |
| 20 | 20.9 | 47.0 | 65.5 | 22.0 | 58.1 | 36.0 | 60.8 | -29.4 | -29.7 | -25.1 |
| 50 | 3.9 | 16.2 | 24.6 | 4.0 | 25.6 | 12.3 | 30.9 | -30.0 | -29.8 | -25.4 |
| 100 | 0.1 | 2.1 | 3.8 | 0.1 | 4.2 | 1.8 | 8.3 | -29.5 | -29.5 | -24.8 |

### Results: accuracy of the point estimates

The point estimate with $`\lambda_z`$ from the log means (“mean”, shared
by Yuan and delta) and with $`\lambda_z`$ from the Tobit fit of the
individual samples (“indiv.”): bias, median absolute error (MAE), and
root mean squared error (RMSE), all relative to the truth (%).

| Model | Route | Design | BLQ | Elimination | Bias mean | Bias indiv. | MAE mean | MAE indiv. | RMSE mean | RMSE indiv. |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | none | fast | 3.2 | 2.5 | 6.9 | 6.7 | 11.1 | 10.6 |
| 1-cmt | IV bolus | serial | none | fast | 4.1 | 3.4 | 7.3 | 7.1 | 11.8 | 11.2 |
| 1-cmt | oral | batch | none | fast | 3.4 | 2.6 | 9.2 | 9.1 | 14.7 | 14.0 |
| 1-cmt | IV bolus | batch | none | fast | 3.7 | 3.0 | 8.7 | 8.6 | 14.3 | 13.7 |
| 1-cmt | oral | serial | moderate | fast | 3.0 | 1.6 | 7.3 | 6.9 | 13.1 | 10.8 |
| 1-cmt | IV bolus | serial | moderate | fast | 3.6 | 2.6 | 7.7 | 7.4 | 12.3 | 11.2 |
| 1-cmt | oral | batch | moderate | fast | 3.5 | 2.1 | 9.3 | 8.9 | 16.7 | 14.5 |
| 1-cmt | IV bolus | batch | moderate | fast | 3.8 | 2.6 | 9.3 | 9.1 | 15.5 | 14.2 |
| 1-cmt | oral | serial | none | slow | 1.7 | -0.2 | 9.9 | 9.7 | 19.9 | 17.5 |
| 1-cmt | IV bolus | serial | none | slow | 1.4 | -0.2 | 9.6 | 9.6 | 18.2 | 16.7 |
| 1-cmt | oral | batch | none | slow | 1.6 | -1.0 | 10.8 | 10.6 | 26.9 | 17.6 |
| 1-cmt | IV bolus | batch | none | slow | 1.3 | -0.8 | 10.7 | 10.5 | 21.7 | 18.3 |
| 1-cmt | oral | serial | moderate | slow | 0.8 | -2.4 | 12.4 | 11.4 | 103.9 | 20.8 |
| 1-cmt | IV bolus | serial | moderate | slow | -0.4 | -2.1 | 11.7 | 10.8 | 54.4 | 17.4 |
| 1-cmt | oral | batch | moderate | slow | 0.3 | -2.3 | 12.7 | 11.5 | 50.0 | 26.1 |
| 1-cmt | IV bolus | batch | moderate | slow | 0.7 | -1.6 | 12.7 | 11.7 | 60.8 | 48.7 |
| 2-cmt | oral | serial | none | fast | 3.8 | 3.3 | 5.5 | 5.4 | 8.9 | 8.5 |
| 2-cmt | IV bolus | serial | none | fast | 5.2 | 4.7 | 6.2 | 6.0 | 9.8 | 9.3 |
| 2-cmt | oral | batch | none | fast | 3.9 | 3.4 | 6.8 | 6.5 | 10.6 | 10.2 |
| 2-cmt | IV bolus | batch | none | fast | 5.1 | 4.6 | 7.1 | 6.8 | 11.4 | 10.9 |
| 2-cmt | oral | serial | moderate | fast | 3.3 | 2.6 | 5.7 | 5.5 | 12.1 | 8.5 |
| 2-cmt | IV bolus | serial | moderate | fast | 4.5 | 4.0 | 6.1 | 5.8 | 9.5 | 8.9 |
| 2-cmt | oral | batch | moderate | fast | 3.3 | 2.5 | 6.8 | 6.6 | 12.1 | 10.2 |
| 2-cmt | IV bolus | batch | moderate | fast | 4.3 | 3.7 | 6.9 | 6.7 | 11.4 | 10.7 |
| 2-cmt | oral | serial | none | slow | -0.3 | -1.5 | 7.8 | 7.9 | 12.7 | 12.2 |
| 2-cmt | IV bolus | serial | none | slow | 0.2 | -1.0 | 7.5 | 7.5 | 13.2 | 12.5 |
| 2-cmt | oral | batch | none | slow | -0.2 | -1.6 | 8.1 | 8.2 | 13.7 | 13.0 |
| 2-cmt | IV bolus | batch | none | slow | 0.0 | -1.2 | 7.9 | 7.9 | 13.5 | 12.6 |
| 2-cmt | oral | serial | moderate | slow | -3.3 | -2.9 | 10.2 | 9.5 | 15.6 | 14.0 |
| 2-cmt | IV bolus | serial | moderate | slow | -3.1 | -2.9 | 9.8 | 9.0 | 14.7 | 13.5 |
| 2-cmt | oral | batch | moderate | slow | -3.4 | -3.5 | 10.3 | 9.4 | 24.3 | 14.8 |
| 2-cmt | IV bolus | batch | moderate | slow | -2.8 | -2.7 | 9.8 | 9.0 | 15.4 | 14.1 |

| Model | Route | Design | BLQ | Elimination | Bias mean | Bias indiv. | MAE mean | MAE indiv. | RMSE mean | RMSE indiv. |
|:---|:---|:---|:---|:---|---:|---:|---:|---:|---:|---:|
| 1-cmt | oral | serial | none | fast | -0.7 | -4.4 | 15.3 | 14.9 | 27.3 | 23.1 |
| 1-cmt | IV bolus | serial | none | fast | -0.9 | -4.7 | 15.9 | 15.5 | 33.3 | 24.8 |
| 1-cmt | oral | batch | none | fast | -0.1 | -4.2 | 16.5 | 16.0 | 43.5 | 29.4 |
| 1-cmt | IV bolus | batch | none | fast | -2.2 | -5.8 | 16.5 | 16.4 | 30.3 | 25.6 |
| 1-cmt | oral | serial | moderate | fast | 1.6 | -4.8 | 17.1 | 15.9 | 55.0 | 24.5 |
| 1-cmt | IV bolus | serial | moderate | fast | -1.2 | -5.7 | 16.6 | 16.0 | 33.8 | 24.6 |
| 1-cmt | oral | batch | moderate | fast | 3.1 | -3.7 | 16.9 | 16.0 | 98.4 | 47.0 |
| 1-cmt | IV bolus | batch | moderate | fast | -0.1 | -5.8 | 17.3 | 16.6 | 41.1 | 25.5 |
| 1-cmt | oral | serial | none | slow | 3.0 | -4.8 | 28.6 | 28.8 | 83.1 | 64.0 |
| 1-cmt | IV bolus | serial | none | slow | 0.3 | -6.1 | 27.7 | 27.8 | 77.7 | 70.4 |
| 1-cmt | oral | batch | none | slow | 8.0 | -8.7 | 27.9 | 27.1 | 556.4 | 53.9 |
| 1-cmt | IV bolus | batch | none | slow | 1.5 | -8.0 | 26.7 | 26.4 | 165.0 | 86.5 |
| 1-cmt | oral | serial | moderate | slow | 172.3 | -5.5 | 35.2 | 32.1 | 11262.8 | 156.6 |
| 1-cmt | IV bolus | serial | moderate | slow | 38.3 | -8.6 | 34.5 | 31.7 | 2893.8 | 63.7 |
| 1-cmt | oral | batch | moderate | slow | 37.2 | -0.5 | 33.7 | 29.4 | 1580.1 | 701.5 |
| 1-cmt | IV bolus | batch | moderate | slow | 55.4 | 29.5 | 33.0 | 29.3 | 2504.9 | 2824.0 |
| 2-cmt | oral | serial | none | fast | -1.5 | -4.9 | 14.1 | 14.1 | 26.2 | 21.8 |
| 2-cmt | IV bolus | serial | none | fast | -2.3 | -5.7 | 15.5 | 15.4 | 28.2 | 25.4 |
| 2-cmt | oral | batch | none | fast | -1.2 | -4.6 | 15.3 | 14.9 | 27.0 | 23.3 |
| 2-cmt | IV bolus | batch | none | fast | -2.7 | -6.3 | 16.2 | 15.9 | 31.4 | 24.8 |
| 2-cmt | oral | serial | moderate | fast | 0.2 | -6.0 | 15.5 | 15.0 | 165.7 | 23.0 |
| 2-cmt | IV bolus | serial | moderate | fast | -4.1 | -7.3 | 16.2 | 15.9 | 28.9 | 23.3 |
| 2-cmt | oral | batch | moderate | fast | -0.2 | -5.9 | 16.6 | 15.7 | 72.2 | 23.7 |
| 2-cmt | IV bolus | batch | moderate | fast | -3.8 | -7.6 | 17.5 | 17.1 | 33.9 | 25.5 |
| 2-cmt | oral | serial | none | slow | -9.2 | -13.7 | 27.0 | 28.0 | 43.4 | 40.5 |
| 2-cmt | IV bolus | serial | none | slow | -9.9 | -14.5 | 27.6 | 28.9 | 50.2 | 48.4 |
| 2-cmt | oral | batch | none | slow | -8.8 | -13.8 | 26.6 | 27.9 | 47.0 | 42.9 |
| 2-cmt | IV bolus | batch | none | slow | -10.2 | -15.2 | 27.2 | 28.4 | 51.3 | 44.6 |
| 2-cmt | oral | serial | moderate | slow | -15.6 | -14.9 | 33.8 | 31.3 | 58.0 | 48.2 |
| 2-cmt | IV bolus | serial | moderate | slow | -18.1 | -17.4 | 35.4 | 32.8 | 53.2 | 50.7 |
| 2-cmt | oral | batch | moderate | slow | -10.0 | -16.4 | 33.9 | 31.0 | 471.3 | 74.6 |
| 2-cmt | IV bolus | batch | moderate | slow | -17.3 | -17.1 | 34.0 | 31.1 | 54.0 | 52.6 |

### Findings

**Coverage of the AUC to infinity.** With fast elimination, when 3 to 7%
of the AUC was extrapolated, all three methods covered close to the
nominal 95% (Yuan 93.7 to 95.9%, delta 95.1 to 96.3%, individual 94.1 to
95.8%), so the uncertainty of $`\lambda_z`$ matters little when little
is extrapolated. With slow elimination, when 17 to 21% was extrapolated,
treating $`\lambda_z`$ as known under-covered (Yuan 81.3 to 89.1%), and
the delta method was closest to nominal in every scenario (90.2 to
93.6%), though still a few points short. Adding the variance of
$`\lambda_z`$ from the individual samples (84.7 to 91.4%) recovered only
part of the shortfall, because it omits the covariance of
$`\hat{\lambda}_z`$ with the means. The results were alike for the oral
and IV bolus routes, so back-extrapolating $`C_0`$ added little
uncertainty, and alike for the one- and two-compartment models and the
two designs.

**Accuracy of the AUC to infinity.** The bias of the AUC to infinity was
-3.4 to 5.2%: slightly high with fast elimination, where the linear
trapezoidal rule overestimates the area under the declining curve, and
near zero with slow elimination (slightly low with two compartments and
BLQ samples). The median absolute errors were similar for the two
estimates of $`\lambda_z`$, but the log-mean $`\lambda_z`$ occasionally
came out near zero with slow elimination and BLQ samples, which made the
AUC to infinity heavy-tailed (RMSE up to 104%). The Tobit fit uses every
terminal sample, including the censored ones, rather than means that
count BLQ samples as zero, and it was steadier (RMSE up to 49%).

**The AUMC to infinity.** All three methods under-covered the AUMC in
every scenario (delta 79 to 92%, Yuan 61 to 88%, individual 61 to 88%),
most with slow elimination. Its extrapolation is proportional to
$`1/\lambda_z^2`$, so the first-order delta method is a poorer
approximation, and the estimate is more heavy-tailed: its median
absolute error was 14 to 35%, and with two compartments and slow
elimination it was biased low (-18 to -9%), because the arithmetic mean
of animals with different elimination rates declines ever more slowly,
which a single exponential from $`t_{last}`$ misses.

**Interval width.** The delta-method intervals were wider than Yuan’s,
most when elimination was slow; the extra width is what improved the
coverage.

**The bootstrap.** With three or four animals at each time, the
bootstrap intervals were too narrow. For the AUC to infinity, the
percentile interval covered 83.7 to 89.0% with fast elimination and 81.6
to 89.6% with slow elimination, against 95.1 to 96.3% and 90.2 to 93.6%
for the delta method, and the interval from the bootstrap standard error
was little better (82.9 to 92.8%). Resampling $`n`$ animals understates
the variance of their mean by the factor $`(n - 1)/n`$ (3/4 with four
animals), and the percentile interval of a skewed estimate is narrow as
well. For the AUMC to infinity, the bootstrap covered 71.8 to 90.0%:
better than Yuan’s method when elimination was slow, and as good as or
better than the delta method only with slow elimination and BLQ samples,
where the first-order delta method is weakest. The bootstrap’s advantage
is that it applies to every parameter and to ratios between groups (Shen
and Machado 2017), including parameters with no analytical standard
error, such as Cmax and the half-life; with few animals at each time,
its intervals should be read as too narrow.

**More animals at each time.** The bootstrap improved with more animals,
as its $`(n - 1)/n`$ shortfall shrank. Without BLQ samples, its
percentile interval for the AUC to infinity covered 81.8% with 4 animals
per time and 89.8% with 20, when the delta method covered 90.0%; with
BLQ samples, it matched or passed the delta method from 6 animals per
time. Its standard error was then as accurate as the delta method’s. But
with many animals, every interval under-covered: with 100 animals per
time, the percentile interval covered 86.3% without and 29.2% with BLQ
samples (the delta method, 85.6% and 25.8%). The cause is the estimate,
not its standard error: the sparse AUC to infinity was biased by -1.7%
without and -6.9% with BLQ samples, whatever the number of animals, from
the BLQ samples counted as zero in the late means and the extrapolation
of a mean of animals with different elimination rates. More animals make
every interval narrower around the same biased estimate, so no choice of
interval corrects it. The AUMC to infinity, biased by -15.9% and -29.5%,
showed the same pattern sooner.

**The Tobit half-life.** With BLQ samples, the Tobit fit of the mean
profile changed little: the bias of the AUC to infinity was -6.6 to
4.0%, against -6.1 to 4.0% for the log-linear fit, and Yuan’s intervals
covered the same. Its bootstrap intervals were narrower than the
log-linear fit’s and covered less (79 to 84% against 86 to 90% with slow
elimination), and with no standard error for $`\lambda_z`$ it cannot use
the delta method. The Tobit fit of the individual samples was slightly
less biased and more precise: with 100 animals per time, its AUC to
infinity was biased by -5.5% and its AUMC by -24.8%, against -6.9% and
-29.5% for the log-linear fit. Its intervals were still less reliable
than the delta method with few animals per time, and with many animals
the bias left every interval short of nominal, whichever $`\lambda_z`$
was used. So most of the bias that BLQ samples add does not come from
$`\lambda_z`$, and a better fit of $`\lambda_z`$ does not remove it: it
comes from the late means, where BLQ samples count as zero, and from the
mean profile ending earlier, when more than half of a time’s samples are
BLQ.

## Arithmetic or geometric mean profiles

The sparse AUC uses the arithmetic mean at each time, whose profile is
the population mean concentration curve. A geometric mean profile
instead approximates the typical animal, and it may be less affected by
animals with high concentrations. The second study compared the two for
the AUClast, AUCinf, Cmax ($`C_0`$ for IV bolus), AUMClast, AUMCinf, and
half-life, using the same design with 2,000 replicates per scenario
(`data-raw/sparse_mean_type_simulation.R`).

For each replicate, both mean profiles were formed, and
[`pk.nca()`](https://humanpred.github.io/pknca/reference/pk.nca.md)
calculated the parameters from each with the linear trapezoidal rule
(imputing zero at time 0 for oral dosing and back-extrapolating $`C_0`$
for IV bolus). For the geometric mean, a time with more than half of its
samples BLQ was BLQ (as for the arithmetic sparse mean), and otherwise
BLQ samples counted as half of the LLOQ. Each profile was compared with
its own target (the arithmetic or geometric mean of the individual
parameters of 50,000 virtual animals) and with the typical animal.
Precision is the robust coefficient of variation (the interquartile
range divided by 1.349, relative to the median).

| Parameter | Bias vs own target, arith. | Bias vs own target, geom. | Bias vs typical, arith. | Bias vs typical, geom. | Robust CV, arith. | Robust CV, geom. | Geom. CV lower (scenarios) |
|:---|:---|:---|:---|:---|:---|:---|:---|
| AUClast | -1 to 5 | 0 to 4 | 0 to 11 | -3 to 3 | 6 to 15 | 6 to 15 | 1 of 32 |
| AUCinf | -6 to 5 | -6 to 4 | -2 to 13 | -6 to 3 | 7 to 19 | 7 to 16 | 10 of 32 |
| Cmax (C0 for IV) | -4 to 10 | -3 to 10 | -1 to 15 | -4 to 10 | 11 to 26 | 11 to 25 | 1 of 32 |
| AUMClast | -7 to 0 | -5 to 1 | -7 to 12 | -11 to -3 | 10 to 23 | 11 to 22 | 5 of 32 |
| AUMCinf | -30 to -6 | -19 to 1 | -12 to 18 | -18 to 1 | 19 to 50 | 18 to 39 | 28 of 32 |
| Half-life | -18 to 5 | -14 to 3 | -10 to 11 | -12 to 3 | 20 to 34 | 16 to 29 | 17 of 32 |

Bias (median, %) and robust CV (%) over the scenarios; the last column
counts the scenarios where the geometric robust CV was more than 1 point
lower. {.table}

| Model | Elimination | BLQ      | Arithmetic | Geometric |
|:------|:------------|:---------|:-----------|:----------|
| 1-cmt | fast        | moderate | 8 to 10    | 2 to 3    |
| 1-cmt | fast        | none     | 9 to 10    | -4 to -3  |
| 1-cmt | slow        | moderate | -6 to -2   | -8 to -5  |
| 1-cmt | slow        | none     | 2 to 3     | -4 to -4  |
| 2-cmt | fast        | moderate | 6 to 8     | 0 to 1    |
| 2-cmt | fast        | none     | 8 to 11    | -5 to -2  |
| 2-cmt | slow        | moderate | -10 to -7  | -12 to -9 |
| 2-cmt | slow        | none     | -3 to 2    | -9 to -5  |

Bias (%) of the half-life of the mean profile against the typical
animal’s half-life, over routes and designs. {.table}

**Findings.** Against their own targets, the two profiles were similarly
accurate for the AUCs and Cmax. The geometric profile was as precise or
more precise, most clearly for the half-life with BLQ samples and for
the AUMC to infinity, but the gains were modest elsewhere. Both
underestimated the AUMC to infinity (arithmetic -30 to -6%, geometric
-19 to 1%). The half-life of the arithmetic mean profile was not
consistently too short: it was too long when the terminal phase was well
sampled, because the late mean is dominated by the slowly eliminating
animals, and too short with BLQ samples (counted as zero in the late
means) and in the two-compartment model with slow elimination, where the
fitted points reach back toward the distribution phase. The geometric
profile was generally a few percent short, because the geometric mean of
exponentials declines at the average elimination rate.

The geometric profile was not adopted. Its gains were modest; it
estimates a different quantity (the typical animal rather than the
population mean curve); its BLQ rule (here, half the LLOQ) is a choice
that drives its results with BLQ samples; and the sparse variance
methods (Bailer, Nedelman and Jia, Holder) are for arithmetic means, so
adopting it would change every sparse calculation.

## Calculating it with PKNCA

Request `aucinf.obs` (or `aumcinf.obs`) with sparse data. The standard
error and degrees of freedom are reported with it as `aucinf.obs_se` and
`aucinf.obs_df`, and the summary shows the estimate with its standard
error. These animals were not sampled at the dose, so the concentration
at time 0 is imputed as zero.

``` r

d_sparse <-
  data.frame(
    time = rep(c(0.5, 1, 2, 4, 6, 8, 12, 24), each = 4),
    conc =
      c(3.1, 4.4, 3.6, 5.2,  5.8, 6.9, 5.1, 7.4,  7.2, 6.1, 8.3, 6.6,
        5.0, 6.2, 4.4, 5.6,  4.1, 3.4, 4.8, 3.7,  2.9, 3.5, 2.4, 3.1,
        1.6, 1.9, 1.3, 1.8,  0.33, 0.27, 0.41, 0.30)
  )
d_sparse$animal <- seq_len(nrow(d_sparse))
o_data <-
  PKNCAdata(
    PKNCAconc(d_sparse, conc ~ time | animal, sparse = TRUE),
    intervals = data.frame(start = 0, end = Inf, aucinf.obs = TRUE, aumcinf.obs = TRUE),
    impute = "start_conc0"
  )
o_nca <- pk.nca(o_data)
#> The sparse estimators use the linear trapezoidal rule, so the auc.method option
#> ("lin up/log down") does not apply to: aucinf.obs, aumcinf.obs
d_result <- as.data.frame(o_nca)
d_result[grepl("^au.*inf|^lambda.z$", d_result$PPTESTCD), c("PPTESTCD", "PPORRES")]
#> # A tibble: 7 × 2
#>   PPTESTCD       PPORRES
#>   <chr>            <dbl>
#> 1 lambda.z         0.139
#> 2 aucinf.obs      62.4  
#> 3 aucinf.obs_se    1.85 
#> 4 aucinf.obs_df   15.6  
#> 5 aumcinf.obs    468.   
#> 6 aumcinf.obs_se  20.2  
#> 7 aumcinf.obs_df   7.14
summary(o_nca)
#>  start end  aucinf.obs aumcinf.obs
#>      0 Inf 62.4 [1.85]  468 [20.2]
#> 
#> Caption: aucinf.obs, aumcinf.obs: estimate and standard error
```

The `sparse_lambda_z_se` option (set globally with
[`PKNCA.options()`](https://humanpred.github.io/pknca/reference/PKNCA.options.md)
or for one analysis with the `options` argument of
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md))
is `"delta"` (the default) for the delta method or `"none"` for Yuan’s
method. The method used is recorded in the `PPANMETH` column.

After an IV bolus, request the IV parameters; $`C_0`$ is
back-extrapolated from the mean profile, and no imputation is needed.

``` r

d_sparse_iv <-
  data.frame(
    time = rep(c(0.25, 0.5, 1, 2, 4, 8, 24), each = 4),
    conc =
      c(9.1, 10.4, 8.7, 9.9,  8.8, 9.5, 8.1, 9.2,  8.2, 7.6, 8.9, 7.9,
        6.4, 7.1, 6.0, 6.9,  4.6, 4.1, 5.0, 4.3,  2.1, 1.8, 2.3, 1.9,
        0.10, 0.08, 0.12, 0.09)
  )
d_sparse_iv$animal <- seq_len(nrow(d_sparse_iv))
o_data_iv <-
  PKNCAdata(
    PKNCAconc(d_sparse_iv, conc ~ time | animal, sparse = TRUE),
    PKNCAdose(data.frame(time = 0, dose = 100), dose ~ time, route = "intravascular"),
    intervals = data.frame(start = 0, end = Inf, c0 = TRUE, aucivinf.obs = TRUE)
  )
d_result_iv <- as.data.frame(suppressWarnings(pk.nca(o_data_iv)))
#> The sparse estimators use the linear trapezoidal rule, so the auc.method option
#> ("lin up/log down") does not apply to: aucinf.obs, aucivinf.obs
d_result_iv[grepl("^c0$|^aucivinf", d_result_iv$PPTESTCD), c("PPTESTCD", "PPORRES")]
#> # A tibble: 4 × 2
#>   PPTESTCD        PPORRES
#>   <chr>             <dbl>
#> 1 c0                10.2 
#> 2 aucivinf.obs      58.0 
#> 3 aucivinf.obs_se    1.35
#> 4 aucivinf.obs_df    5.97
```

The warnings suppressed here say that the AUCs from time 0 without
$`C_0`$ (`aucinf.obs`, which `aucivinf.obs` depends on) are not
calculated.

## Discussion

When $`\lambda_z`$ is estimated from the same samples, its uncertainty
adds to that of the AUC to infinity, and treating it as known, as Yuan’s
(1993) standard error does, under-covers once the extrapolated area is a
substantial part of the AUC. The delta method on the log means is a
consistent extension of Yuan’s method: it keeps his estimate, applies to
serial-sacrifice and batch designs alike through the covariance of the
means, includes the covariance of $`\hat{\lambda}_z`$ with $`C_{last}`$
and the AUC to $`t_{last}`$, and needs nothing beyond the quantities
already used for the sparse AUC to $`t_{last}`$. In the simulation it
brought the coverage of the AUC to infinity much closer to nominal when
the extrapolated area was large (90.2 to 93.6%, against 81.3 to 89.1%
for Yuan), though still a few points short, and it cost little when the
extrapolated area was small. For this reason, it is PKNCA’s default
(`sparse_lambda_z_se = "delta"`). The same delta method carries the
uncertainty of the back-extrapolated $`C_0`$ after an IV bolus, and the
IV bolus scenarios covered as well as the oral ones.

Estimating $`\lambda_z`$ from the individual samples with a
(mixed-effects) Tobit regression gave a more stable point estimate when
samples were BLQ, but adding its variance to Yuan’s did not give
adequate coverage, and its mixed-effects fit was itself occasionally
unstable in the batch design with BLQ samples and slow elimination. A
bootstrap over animals, which includes the covariance of that
$`\lambda_z`$ with the means, was too narrow with few animals per time,
as every bootstrap was. The Tobit fit of the mean profile, which uses
the LLOQs, gave nearly the same results as the log-linear fit. Neither
Tobit fit removed the bias of the sparse estimate with BLQ samples,
which comes mostly from counting BLQ samples as zero in the late means
and from the mean profile ending earlier; estimating those means with
the censoring taken into account would be the place to reduce it.

Limitations remain. The delta method conditions on the selected
half-life points, so the uncertainty of the automatic point selection is
not included; it is a first-order approximation, which is least accurate
when $`\lambda_z`$ is imprecise, as for the AUMC with slow elimination;
and the arithmetic mean profile of animals with different elimination
rates is not monoexponential, so the extrapolation
$`C_{last}/\lambda_z`$ is itself biased for the population mean curve,
which is part of why the AUMC to infinity is underestimated. Where the
extrapolated area is large, sampling longer remains the better remedy.

## References

Bailer AJ. Testing for the equality of area under the curves when using
destructive measurement techniques. Journal of Pharmacokinetics and
Biopharmaceutics. 1988;16(3):303-309.

Holder DJ. Comments on Nedelman and Jia’s extension of Satterthwaite’s
approximation applied to pharmacokinetics. Journal of Biopharmaceutical
Statistics. 2001;11(1-2):75-79. <doi:10.1081/BIP-100104199>

Nedelman JR, Gibiansky E, Lau DTW. Applying Bailer’s method for AUC
confidence intervals to sparse sampling. Pharmaceutical Research.
1995;12(1):124-128.

Nedelman JR, Jia X. An extension of Satterthwaite’s approximation
applied to pharmacokinetics. Journal of Biopharmaceutical Statistics.
1998;8(2):317-328. <doi:10.1080/10543409808835241>

Shen M, Machado SG. Bioequivalence evaluation of sparse sampling
pharmacokinetics data using bootstrap resampling method. Journal of
Biopharmaceutical Statistics. 2017;27(2):257-264.
<doi:10.1080/10543406.2016.1265543>

Takemoto S, Yamaoka K, Nishikawa M, Takakura Y. Histogram analysis of
pharmacokinetic parameters by bootstrap resampling from one-point
sampling data in animal experiments. Drug Metabolism and
Pharmacokinetics. 2006;21(6):458-464. <doi:10.2133/dmpk.21.458>

Yuan J. Estimation of variance for AUC in animal studies. Journal of
Pharmaceutical Sciences. 1993;82(7):761-763.
<doi:10.1002/jps.2600820718>
