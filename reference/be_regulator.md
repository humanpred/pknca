# Regulatory framework constants for bioequivalence assessment

`be_regulator()` returns the scaling type, switching and capping rules,
and regulatory constants that define a bioequivalence (BE) assessment
framework. It is the single source of truth for these values:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
and the internal decision functions pull every constant from here rather
than hard-coding it.

## Usage

``` r
be_regulator(
  name = c("ABE", "EMA", "HC", "GCC", "FDA", "NTID", "HVNTID", "descriptive")
)
```

## Arguments

- name:

  The regulatory framework, one of `"ABE"`, `"EMA"`, `"HC"`, `"GCC"`,
  `"FDA"`, `"NTID"`, `"HVNTID"`, or `"descriptive"`.

## Value

An object of class `be_regulator`: a list with elements `name`,
`scaling` (one of `"none"`, `"abel"`, `"rsabe"`, `"ntid"`, `"hvntid"`),
`cvswitch`, `r_const`, `cvcap`, `switch_swr`, `est_method` (`"anova"` or
`"isc"`), `widen_like` (for the expanding-limits frameworks, whether the
endpoints judged like `"cmax"` or like `"auc"` widen), `pe_only_like`
(those judged by the point estimate alone), `reference` (the source
guidance, or `NA`), `pe_constr`, `decision` (`FALSE` only for
`"descriptive"`), `sw_ratio_cap`, and `switch_basis`.

## Details

The supported frameworks, the acceptance limits each applies to each
endpoint, and their sources are:

- **ABE** – average bioequivalence; the 90% confidence interval of the
  geometric mean ratio within 80.00-125.00% for Cmax and AUC, with no
  reference scaling ([ICH
  M13A](https://database.ich.org/sites/default/files/ICH_M13A_Step4_Final_Guideline_2024_0723.pdf),
  section 2.2.4).

- **EMA** – average bioequivalence with expanding limits (ABEL) for
  **Cmax** and the parameters judged like it (see below); AUC and the
  parameters judged like it keep the 90% confidence interval within
  80.00-125.00% whatever their variability ([EMA Guideline on the
  Investigation of Bioequivalence, Rev.
  1](https://www.ema.europa.eu/en/documents/scientific-guideline/guideline-investigation-bioequivalence-rev1_en.pdf),
  sections 4.1.8 and 4.1.10). Cmax limits widen when the
  within-reference coefficient of variation (`CVwR`) exceeds 30%
  (`cvswitch = 0.30`), as `exp(+/- k * swR)` with the regulatory
  constant `k = 0.760`, capped at `CVwR = 50%` (limits 69.84-143.19%),
  and the geometric mean ratio must lie within 80.00-125.00%. The
  constant is `log(1.25) / sqrt(log(1 + 0.30^2))` rounded to three
  decimals. For modified-release products the EMA also allows the same
  widening for Cmax,ss, Ctau,ss, and partial AUCs ([EMA Guideline on the
  Pharmacokinetic and Clinical Evaluation of Modified Release Dosage
  Forms](https://www.ema.europa.eu/en/documents/scientific-guideline/guideline-pharmacokinetic-and-clinical-evaluation-modified-release-dosage-forms_en.pdf),
  section 6.8.2.2). Cmax,ss and Ctau,ss are judged like Cmax; PKNCA
  cannot tell a partial AUC from AUC(0-tau) by its name, so name it in
  the `widen_endpoints` argument of
  [`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md).

- **HC** – Health Canada. ABEL for **AUC** and the parameters judged
  like it: the 90% confidence interval within limits widened as
  `exp(+/- 0.76 * swR)` when `swR > 0.294` (`CVwR > 30%`), capped at
  66.7-150.0% (`CVwR = 57.4%`), with the ratio of geometric means within
  80.0-125.0% ([Policy on Bioequivalence Standards for Highly Variable
  Drug
  Products](https://www.canada.ca/en/health-canada/services/drugs-health-products/drug-products/announcements/notice-policy-bioequivalence-standards-highly-variable-drug-products.html),
  effective 2018). **Cmax**, and the parameters judged like it, **is
  judged by its point estimate alone**: the ratio of geometric means
  within 80.0-125.0%, with no requirement on its confidence interval
  ([Comparative Bioavailability Standards: Formulations Used for
  Systemic
  Effects](https://www.canada.ca/en/health-canada/services/drugs-health-products/drug-products/applications-submissions/guidance-documents/bioavailability-bioequivalence/comparative-bioavailability-standards-formulations-used-systemic-effects.html),
  sections 2.1 and 2.1.1.1). Health Canada requires the relative mean
  Cmin at steady state to be at least 80.0%, with no upper limit; judged
  like Cmax, it must also be at most 125.0%. Health Canada no longer
  uses urinary data. These are the standards for drugs that are not
  critical dose drugs.

- **GCC** – Gulf Cooperation Council; the EMA rules: ABEL for **Cmax**
  and the parameters judged like it, with `k = 0.760`, the 30% switch,
  the 69.84-143.19% cap, and the geometric mean ratio within
  80.00-125.00%; AUC and the parameters judged like it keep
  80.00-125.00% ([GCC Guidelines for Bioequivalence, version
  3.2](https://sfda.gov.sa/sites/default/files/2024-05/GCC_Guidelines_Bioequivalence32.pdf),
  sections 3.1.8 and 3.1.10).

- **FDA** – reference-scaled average bioequivalence (RSABE) for both AUC
  and Cmax ([FDA Draft Guidance on
  Progesterone](https://www.accessdata.fda.gov/drugsatfda_docs/psg/Progesterone_caps_19781_RC02-11.pdf)).
  The linearized (Howe/Hyslop) criterion uses
  `r_const = log(1.25) / 0.25 = 0.8926` (`theta = r_const^2`) and
  switches from unscaled ABE (90% confidence interval within
  80.00-125.00%) when `swR >= 0.294` (`CVwR` of about 30%).

- **NTID** – FDA narrow therapeutic index drugs, for both AUC and Cmax
  ([FDA Draft Guidance on Warfarin
  Sodium](https://www.accessdata.fda.gov/drugsatfda_docs/psg/Warfarin_Sodium_tab_09218_RC12-12.pdf)):
  the scaled criterion with `r_const = -log(0.9) / 0.1 = 1.0536` (always
  applied), the 90% confidence interval within 80.00-125.00%, and the
  upper 90% confidence bound of swT/swR at most 2.5 (a fully replicated
  design is required).

- **HVNTID** – FDA highly variable narrow therapeutic index drugs, for
  both AUC and Cmax ([FDA Draft Guidance on Dabigatran Etexilate
  Mesylate](https://www.accessdata.fda.gov/drugsatfda_docs/psg/Dabigatran%20etexilate%20mesylate_oral%20capsule_NDA%20022512_RV05-17.pdf)):
  unscaled, with the 90% confidence interval within 80.00-125.00% and
  the upper 90% confidence bound of swT/swR at most 2.5.

- **descriptive** – no regulatory decision. The geometric means, their
  ratio, and its confidence interval are estimated exactly as for ABE,
  but no acceptance limits are applied and no pass/fail is reported. Use
  it for comparisons that are estimated rather than judged, such as food
  effect and drug-drug interaction studies.

All decision frameworks additionally impose the point-estimate
constraint that the geometric mean ratio fall within 80.00-125.00%.

The guidances name more parameters than Cmax and AUC and judge each like
one of them. An endpoint is matched by its PKNCA parameter name or its
CDISC `PPTESTCD` code (see
[`pknca_cdisc_codes()`](https://humanpred.github.io/pknca/reference/pknca_cdisc_codes.md)).
Judged like Cmax:

- `cmax`: Cmax, and Cmax,ss at steady state (EMA section 4.1.8);

- `cmin` and `ctrough`: Cmin,ss and Ctau,ss (EMA modified-release
  guideline section 6.8.2.2; Health Canada section 2.1.1.1);

- `ermax`: Rmax, the maximal rate of urinary excretion, "analysed using
  the same acceptance interval as for Cmax" (EMA section 4.1.8; GCC
  section 3.1.8);

- and their dose-normalized forms.

Judged like AUC:

- the AUCs: `auclast` (AUC(0-t)), `aucall`, `aucinf.obs` and
  `aucinf.pred` (AUC(0-inf)), `aucint.*` (for example AUC(0-tau) at
  steady state and AUC(0-72h); EMA section 4.1.8, Health Canada section
  2.1.1.4), the IV-extrapolated `auciv*`, and `sparse_auclast`;

- `cav*`: the average concentration at steady state, AUC(0-tau)/tau;

- `ae`: Ae(0-t), the amount excreted in urine, "analysed using the same
  acceptance interval as stated above for AUC(0-t)" (EMA section 4.1.8;
  GCC section 3.1.8), and `fe`, Ae as a fraction of the dose;

- and their dose-normalized forms.

Other endpoints, such as `tmax`, use the 90% confidence interval within
80.00-125.00%. An endpoint that is neither a PKNCA parameter nor a CDISC
code keeps 80.00-125.00% under the expanding-limits frameworks, with a
warning, unless it is named in `widen_endpoints`.

## References

International Council for Harmonisation. ICH M13A: Bioequivalence for
immediate-release solid oral dosage forms. Step 4, 23 July 2024.
<https://database.ich.org/sites/default/files/ICH_M13A_Step4_Final_Guideline_2024_0723.pdf>

European Medicines Agency. Guideline on the investigation of
bioequivalence. CPMP/EWP/QWP/1401/98 Rev. 1/Corr\*\*, 2010.
<https://www.ema.europa.eu/en/documents/scientific-guideline/guideline-investigation-bioequivalence-rev1_en.pdf>

European Medicines Agency. Guideline on the pharmacokinetic and clinical
evaluation of modified release dosage forms. EMA/CHMP/EWP/280/96 Rev1,
2014.
<https://www.ema.europa.eu/en/documents/scientific-guideline/guideline-pharmacokinetic-and-clinical-evaluation-modified-release-dosage-forms_en.pdf>

Health Canada. Comparative bioavailability standards: Formulations used
for systemic effects. Revised 8 June 2018, effective 1 September 2018.
<https://www.canada.ca/en/health-canada/services/drugs-health-products/drug-products/applications-submissions/guidance-documents/bioavailability-bioequivalence/comparative-bioavailability-standards-formulations-used-systemic-effects.html>

Health Canada. Notice: Policy on bioequivalence standards for highly
variable drug products. Effective 1 September 2018.
<https://www.canada.ca/en/health-canada/services/drugs-health-products/drug-products/announcements/notice-policy-bioequivalence-standards-highly-variable-drug-products.html>

Gulf Cooperation Council. The GCC guidelines for bioequivalence. Version
3.2, 2024.
<https://sfda.gov.sa/sites/default/files/2024-05/GCC_Guidelines_Bioequivalence32.pdf>

US Food and Drug Administration. Draft guidance on progesterone. 2011.
<https://www.accessdata.fda.gov/drugsatfda_docs/psg/Progesterone_caps_19781_RC02-11.pdf>

US Food and Drug Administration. Draft guidance on warfarin sodium.
2012.
<https://www.accessdata.fda.gov/drugsatfda_docs/psg/Warfarin_Sodium_tab_09218_RC12-12.pdf>

US Food and Drug Administration. Draft guidance on dabigatran etexilate
mesylate. 2012, revised 2017.
<https://www.accessdata.fda.gov/drugsatfda_docs/psg/Dabigatran%20etexilate%20mesylate_oral%20capsule_NDA%20022512_RV05-17.pdf>

## See also

[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md)
for the ABEL acceptance limits and
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md)
for the full assessment.

Other Bioequivalence:
[`be_assess()`](https://humanpred.github.io/pknca/reference/be_assess.md),
[`be_compare()`](https://humanpred.github.io/pknca/reference/be_compare.md),
[`be_dataset()`](https://humanpred.github.io/pknca/reference/be_dataset.md),
[`be_design()`](https://humanpred.github.io/pknca/reference/be_design.md),
[`be_expand_limits()`](https://humanpred.github.io/pknca/reference/be_expand_limits.md),
[`be_extract_param()`](https://humanpred.github.io/pknca/reference/be_extract_param.md),
[`be_fit_model_single()`](https://humanpred.github.io/pknca/reference/be_fit_model_single.md),
[`be_fit_models()`](https://humanpred.github.io/pknca/reference/be_fit_models.md),
[`be_table()`](https://humanpred.github.io/pknca/reference/be_table.md),
[`be_within_var()`](https://humanpred.github.io/pknca/reference/be_within_var.md)

## Examples

``` r
be_regulator("EMA")
#> Bioequivalence regulator: EMA
#>   Scaling:            abel
#>   CV switch:          30%
#>   Regulatory const.:  0.76
#>   CV cap:             50%
#>   Widened endpoints:  Cmax and the parameters judged like it
#>   PE constraint:      80.00-125.00%
#>   Point estimate:     anova
#>   Reference:          EMA Guideline on the Investigation of Bioequivalence (CPMP/EWP/QWP/1401/98 Rev. 1), sections 4.1.8 and 4.1.10
be_regulator("FDA")
#> Bioequivalence regulator: FDA
#>   Scaling:            rsabe
#>   CV switch:          30%
#>   swR switch:         0.294
#>   Regulatory const.:  0.8925742
#>   PE constraint:      80.00-125.00%
#>   Point estimate:     isc
#>   Reference:          FDA Draft Guidance on Progesterone (2011)
be_regulator("descriptive")
#> Bioequivalence regulator: descriptive
#>   Scaling:            none
#>   PE constraint:      none
#>   Point estimate:     anova
#>   Decision:           none (descriptive; no acceptance limits or pass/fail)
```
