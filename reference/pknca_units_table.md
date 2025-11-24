# Create a unit assignment and conversion table

This data.frame is typically used for the `units` argument for
[`PKNCAdata()`](http://humanpred.github.io/pknca/reference/PKNCAdata.md).
If a unit is not given, then all of the units derived from that unit
will be `NA`.

## Usage

``` r
pknca_units_table(
  concu,
  doseu,
  amountu,
  timeu,
  concu_pref = NULL,
  doseu_pref = NULL,
  amountu_pref = NULL,
  timeu_pref = NULL,
  conversions = data.frame()
)
```

## Arguments

- concu, doseu, amountu, timeu:

  Units for concentration, dose, amount, and time in the source data

- concu_pref, doseu_pref, amountu_pref, timeu_pref:

  Preferred units for reporting; `conversions` will be automatically.

- conversions:

  An optional data.frame with columns of c("PPORRESU", "PPSTRESU",
  "conversion_factor") for the original calculation units, the
  standardized units, and a conversion factor to multiply the initial
  value by to get a standardized value. This argument overrides any
  preferred unit conversions from `concu_pref`, `doseu_pref`,
  `amountu_pref`, or `timeu_pref`.

## Value

A unit conversion table with columns for "PPTESTCD" and "PPORRESU" if
`conversions` is not given, and adding "PPSTRESU" and
"conversion_factor" if `conversions` is given.

## See also

The `units` argument for
[`PKNCAdata()`](http://humanpred.github.io/pknca/reference/PKNCAdata.md)

## Examples

``` r
pknca_units_table() # only parameters that are unitless
#>     PPORRESU             PPTESTCD
#> 1   unitless            r.squared
#> 2   unitless        adj.r.squared
#> 3   unitless      lambda.z.corrxy
#> 4   fraction                    f
#> 5   fraction                  ptr
#> 6   fraction           span.ratio
#> 7          %             deg.fluc
#> 8          %                swing
#> 9          %       aucivpbextlast
#> 10         %        aucivpbextall
#> 11         %   aucivpbextint.last
#> 12         %    aucivpbextint.all
#> 13         %    aucivpbextinf.obs
#> 14         %   aucivpbextinf.pred
#> 15         %          aucpext.obs
#> 16         %         aucpext.pred
#> 17     count           count_conc
#> 18     count  count_conc_measured
#> 19     count        sparse_auc_df
#> 20     count    lambda.z.n.points
#> 21      <NA>                start
#> 22      <NA>                  end
#> 23      <NA>                 tmax
#> 24      <NA>                tlast
#> 25      <NA>               tfirst
#> 26      <NA>             mrt.last
#> 27      <NA>          mrt.iv.last
#> 28      <NA>                 tlag
#> 29      <NA>               ertlst
#> 30      <NA>               ertmax
#> 31      <NA>           time_above
#> 32      <NA>            half.life
#> 33      <NA>  lambda.z.time.first
#> 34      <NA>   lambda.z.time.last
#> 35      <NA>       thalf.eff.last
#> 36      <NA>    thalf.eff.iv.last
#> 37      <NA>              mrt.obs
#> 38      <NA>             mrt.pred
#> 39      <NA>           mrt.iv.obs
#> 40      <NA>          mrt.iv.pred
#> 41      <NA>           mrt.md.obs
#> 42      <NA>          mrt.md.pred
#> 43      <NA>        thalf.eff.obs
#> 44      <NA>       thalf.eff.pred
#> 45      <NA>     thalf.eff.iv.obs
#> 46      <NA>    thalf.eff.iv.pred
#> 47      <NA>             lambda.z
#> 48      <NA>             kel.last
#> 49      <NA>          kel.iv.last
#> 50      <NA>              kel.obs
#> 51      <NA>             kel.pred
#> 52      <NA>           kel.iv.obs
#> 53      <NA>          kel.iv.pred
#> 54      <NA>                   c0
#> 55      <NA>                 cmax
#> 56      <NA>                 cmin
#> 57      <NA>            clast.obs
#> 58      <NA>                  cav
#> 59      <NA>         cav.int.last
#> 60      <NA>          cav.int.all
#> 61      <NA>              ctrough
#> 62      <NA>               cstart
#> 63      <NA>                 ceoi
#> 64      <NA>           clast.pred
#> 65      <NA>      cav.int.inf.obs
#> 66      <NA>     cav.int.inf.pred
#> 67      <NA>                   ae
#> 68      <NA>                   fe
#> 69      <NA>              totdose
#> 70      <NA>              cmax.dn
#> 71      <NA>              cmin.dn
#> 72      <NA>         clast.obs.dn
#> 73      <NA>        clast.pred.dn
#> 74      <NA>               cav.dn
#> 75      <NA>           ctrough.dn
#> 76      <NA>             vss.last
#> 77      <NA>          vss.iv.last
#> 78      <NA>                volpk
#> 79      <NA>               vz.obs
#> 80      <NA>              vz.pred
#> 81      <NA>              vss.obs
#> 82      <NA>             vss.pred
#> 83      <NA>           vss.iv.obs
#> 84      <NA>          vss.iv.pred
#> 85      <NA>           vss.md.obs
#> 86      <NA>          vss.md.pred
#> 87      <NA>              auclast
#> 88      <NA>               aucall
#> 89      <NA>          aucint.last
#> 90      <NA>     aucint.last.dose
#> 91      <NA>           aucint.all
#> 92      <NA>      aucint.all.dose
#> 93      <NA> aucabove.predose.all
#> 94      <NA>  aucabove.trough.all
#> 95      <NA>       sparse_auclast
#> 96      <NA>        sparse_auc_se
#> 97      <NA>            aucivlast
#> 98      <NA>             aucivall
#> 99      <NA>        aucivint.last
#> 100     <NA>         aucivint.all
#> 101     <NA>           aucinf.obs
#> 102     <NA>          aucinf.pred
#> 103     <NA>       aucint.inf.obs
#> 104     <NA>  aucint.inf.obs.dose
#> 105     <NA>      aucint.inf.pred
#> 106     <NA> aucint.inf.pred.dose
#> 107     <NA>         aucivinf.obs
#> 108     <NA>        aucivinf.pred
#> 109     <NA>             aumclast
#> 110     <NA>              aumcall
#> 111     <NA>          aumcinf.obs
#> 112     <NA>         aumcinf.pred
#> 113     <NA>                ermax
#> 114     <NA>           auclast.dn
#> 115     <NA>            aucall.dn
#> 116     <NA>        aucinf.obs.dn
#> 117     <NA>       aucinf.pred.dn
#> 118     <NA>          aumclast.dn
#> 119     <NA>           aumcall.dn
#> 120     <NA>       aumcinf.obs.dn
#> 121     <NA>      aumcinf.pred.dn
#> 122     <NA>              cl.last
#> 123     <NA>               cl.all
#> 124     <NA>               cl.obs
#> 125     <NA>              cl.pred
#> 126     <NA>             clr.last
#> 127     <NA>              clr.obs
#> 128     <NA>             clr.pred
#> 129     <NA>          clr.last.dn
#> 130     <NA>           clr.obs.dn
#> 131     <NA>          clr.pred.dn
pknca_units_table(
  concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr"
)
#>                    PPORRESU             PPTESTCD
#> 1                  unitless            r.squared
#> 2                  unitless        adj.r.squared
#> 3                  unitless      lambda.z.corrxy
#> 4                  fraction                    f
#> 5                  fraction                  ptr
#> 6                  fraction           span.ratio
#> 7                         %             deg.fluc
#> 8                         %                swing
#> 9                         %       aucivpbextlast
#> 10                        %        aucivpbextall
#> 11                        %   aucivpbextint.last
#> 12                        %    aucivpbextint.all
#> 13                        %    aucivpbextinf.obs
#> 14                        %   aucivpbextinf.pred
#> 15                        %          aucpext.obs
#> 16                        %         aucpext.pred
#> 17                    count           count_conc
#> 18                    count  count_conc_measured
#> 19                    count        sparse_auc_df
#> 20                    count    lambda.z.n.points
#> 21                       hr                start
#> 22                       hr                  end
#> 23                       hr                 tmax
#> 24                       hr                tlast
#> 25                       hr               tfirst
#> 26                       hr             mrt.last
#> 27                       hr          mrt.iv.last
#> 28                       hr                 tlag
#> 29                       hr               ertlst
#> 30                       hr               ertmax
#> 31                       hr           time_above
#> 32                       hr            half.life
#> 33                       hr  lambda.z.time.first
#> 34                       hr   lambda.z.time.last
#> 35                       hr       thalf.eff.last
#> 36                       hr    thalf.eff.iv.last
#> 37                       hr              mrt.obs
#> 38                       hr             mrt.pred
#> 39                       hr           mrt.iv.obs
#> 40                       hr          mrt.iv.pred
#> 41                       hr           mrt.md.obs
#> 42                       hr          mrt.md.pred
#> 43                       hr        thalf.eff.obs
#> 44                       hr       thalf.eff.pred
#> 45                       hr     thalf.eff.iv.obs
#> 46                       hr    thalf.eff.iv.pred
#> 47                     1/hr             lambda.z
#> 48                     1/hr             kel.last
#> 49                     1/hr          kel.iv.last
#> 50                     1/hr              kel.obs
#> 51                     1/hr             kel.pred
#> 52                     1/hr           kel.iv.obs
#> 53                     1/hr          kel.iv.pred
#> 54                    ng/mL                   c0
#> 55                    ng/mL                 cmax
#> 56                    ng/mL                 cmin
#> 57                    ng/mL            clast.obs
#> 58                    ng/mL                  cav
#> 59                    ng/mL         cav.int.last
#> 60                    ng/mL          cav.int.all
#> 61                    ng/mL              ctrough
#> 62                    ng/mL               cstart
#> 63                    ng/mL                 ceoi
#> 64                    ng/mL           clast.pred
#> 65                    ng/mL      cav.int.inf.obs
#> 66                    ng/mL     cav.int.inf.pred
#> 67                       mg                   ae
#> 68               mg/(mg/kg)                   fe
#> 69                    mg/kg              totdose
#> 70          (ng/mL)/(mg/kg)              cmax.dn
#> 71          (ng/mL)/(mg/kg)              cmin.dn
#> 72          (ng/mL)/(mg/kg)         clast.obs.dn
#> 73          (ng/mL)/(mg/kg)        clast.pred.dn
#> 74          (ng/mL)/(mg/kg)               cav.dn
#> 75          (ng/mL)/(mg/kg)           ctrough.dn
#> 76          (mg/kg)/(ng/mL)             vss.last
#> 77          (mg/kg)/(ng/mL)          vss.iv.last
#> 78          (mg/kg)/(ng/mL)                volpk
#> 79          (mg/kg)/(ng/mL)               vz.obs
#> 80          (mg/kg)/(ng/mL)              vz.pred
#> 81          (mg/kg)/(ng/mL)              vss.obs
#> 82          (mg/kg)/(ng/mL)             vss.pred
#> 83          (mg/kg)/(ng/mL)           vss.iv.obs
#> 84          (mg/kg)/(ng/mL)          vss.iv.pred
#> 85          (mg/kg)/(ng/mL)           vss.md.obs
#> 86          (mg/kg)/(ng/mL)          vss.md.pred
#> 87                 hr*ng/mL              auclast
#> 88                 hr*ng/mL               aucall
#> 89                 hr*ng/mL          aucint.last
#> 90                 hr*ng/mL     aucint.last.dose
#> 91                 hr*ng/mL           aucint.all
#> 92                 hr*ng/mL      aucint.all.dose
#> 93                 hr*ng/mL aucabove.predose.all
#> 94                 hr*ng/mL  aucabove.trough.all
#> 95                 hr*ng/mL       sparse_auclast
#> 96                 hr*ng/mL        sparse_auc_se
#> 97                 hr*ng/mL            aucivlast
#> 98                 hr*ng/mL             aucivall
#> 99                 hr*ng/mL        aucivint.last
#> 100                hr*ng/mL         aucivint.all
#> 101                hr*ng/mL           aucinf.obs
#> 102                hr*ng/mL          aucinf.pred
#> 103                hr*ng/mL       aucint.inf.obs
#> 104                hr*ng/mL  aucint.inf.obs.dose
#> 105                hr*ng/mL      aucint.inf.pred
#> 106                hr*ng/mL aucint.inf.pred.dose
#> 107                hr*ng/mL         aucivinf.obs
#> 108                hr*ng/mL        aucivinf.pred
#> 109              hr^2*ng/mL             aumclast
#> 110              hr^2*ng/mL              aumcall
#> 111              hr^2*ng/mL          aumcinf.obs
#> 112              hr^2*ng/mL         aumcinf.pred
#> 113                   hr*mg                ermax
#> 114      (hr*ng/mL)/(mg/kg)           auclast.dn
#> 115      (hr*ng/mL)/(mg/kg)            aucall.dn
#> 116      (hr*ng/mL)/(mg/kg)        aucinf.obs.dn
#> 117      (hr*ng/mL)/(mg/kg)       aucinf.pred.dn
#> 118    (hr^2*ng/mL)/(mg/kg)          aumclast.dn
#> 119    (hr^2*ng/mL)/(mg/kg)           aumcall.dn
#> 120    (hr^2*ng/mL)/(mg/kg)       aumcinf.obs.dn
#> 121    (hr^2*ng/mL)/(mg/kg)      aumcinf.pred.dn
#> 122      (mg/kg)/(hr*ng/mL)              cl.last
#> 123      (mg/kg)/(hr*ng/mL)               cl.all
#> 124      (mg/kg)/(hr*ng/mL)               cl.obs
#> 125      (mg/kg)/(hr*ng/mL)              cl.pred
#> 126           mg/(hr*ng/mL)             clr.last
#> 127           mg/(hr*ng/mL)              clr.obs
#> 128           mg/(hr*ng/mL)             clr.pred
#> 129 (mg/(hr*ng/mL))/(mg/kg)          clr.last.dn
#> 130 (mg/(hr*ng/mL))/(mg/kg)           clr.obs.dn
#> 131 (mg/(hr*ng/mL))/(mg/kg)          clr.pred.dn
pknca_units_table(
  concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr",
  # Convert clearance and volume units to more understandable units with
  # automatic unit conversion
  conversions=data.frame(
    PPORRESU=c("(mg/kg)/(hr*ng/mL)", "(mg/kg)/(ng/mL)"),
    PPSTRESU=c("mL/hr/kg", "mL/kg")
  )
)
#>                    PPORRESU             PPTESTCD                PPSTRESU
#> 1                  unitless            r.squared                unitless
#> 2                  unitless        adj.r.squared                unitless
#> 3                  unitless      lambda.z.corrxy                unitless
#> 4                  fraction                    f                fraction
#> 5                  fraction                  ptr                fraction
#> 6                  fraction           span.ratio                fraction
#> 7                         %             deg.fluc                       %
#> 8                         %                swing                       %
#> 9                         %       aucivpbextlast                       %
#> 10                        %        aucivpbextall                       %
#> 11                        %   aucivpbextint.last                       %
#> 12                        %    aucivpbextint.all                       %
#> 13                        %    aucivpbextinf.obs                       %
#> 14                        %   aucivpbextinf.pred                       %
#> 15                        %          aucpext.obs                       %
#> 16                        %         aucpext.pred                       %
#> 17                    count           count_conc                   count
#> 18                    count  count_conc_measured                   count
#> 19                    count        sparse_auc_df                   count
#> 20                    count    lambda.z.n.points                   count
#> 21                       hr                start                      hr
#> 22                       hr                  end                      hr
#> 23                       hr                 tmax                      hr
#> 24                       hr                tlast                      hr
#> 25                       hr               tfirst                      hr
#> 26                       hr             mrt.last                      hr
#> 27                       hr          mrt.iv.last                      hr
#> 28                       hr                 tlag                      hr
#> 29                       hr               ertlst                      hr
#> 30                       hr               ertmax                      hr
#> 31                       hr           time_above                      hr
#> 32                       hr            half.life                      hr
#> 33                       hr  lambda.z.time.first                      hr
#> 34                       hr   lambda.z.time.last                      hr
#> 35                       hr       thalf.eff.last                      hr
#> 36                       hr    thalf.eff.iv.last                      hr
#> 37                       hr              mrt.obs                      hr
#> 38                       hr             mrt.pred                      hr
#> 39                       hr           mrt.iv.obs                      hr
#> 40                       hr          mrt.iv.pred                      hr
#> 41                       hr           mrt.md.obs                      hr
#> 42                       hr          mrt.md.pred                      hr
#> 43                       hr        thalf.eff.obs                      hr
#> 44                       hr       thalf.eff.pred                      hr
#> 45                       hr     thalf.eff.iv.obs                      hr
#> 46                       hr    thalf.eff.iv.pred                      hr
#> 47                     1/hr             lambda.z                    1/hr
#> 48                     1/hr             kel.last                    1/hr
#> 49                     1/hr          kel.iv.last                    1/hr
#> 50                     1/hr              kel.obs                    1/hr
#> 51                     1/hr             kel.pred                    1/hr
#> 52                     1/hr           kel.iv.obs                    1/hr
#> 53                     1/hr          kel.iv.pred                    1/hr
#> 54                    ng/mL                   c0                   ng/mL
#> 55                    ng/mL                 cmax                   ng/mL
#> 56                    ng/mL                 cmin                   ng/mL
#> 57                    ng/mL            clast.obs                   ng/mL
#> 58                    ng/mL                  cav                   ng/mL
#> 59                    ng/mL         cav.int.last                   ng/mL
#> 60                    ng/mL          cav.int.all                   ng/mL
#> 61                    ng/mL              ctrough                   ng/mL
#> 62                    ng/mL               cstart                   ng/mL
#> 63                    ng/mL                 ceoi                   ng/mL
#> 64                    ng/mL           clast.pred                   ng/mL
#> 65                    ng/mL      cav.int.inf.obs                   ng/mL
#> 66                    ng/mL     cav.int.inf.pred                   ng/mL
#> 67                       mg                   ae                      mg
#> 68               mg/(mg/kg)                   fe              mg/(mg/kg)
#> 69                    mg/kg              totdose                   mg/kg
#> 70          (ng/mL)/(mg/kg)              cmax.dn         (ng/mL)/(mg/kg)
#> 71          (ng/mL)/(mg/kg)              cmin.dn         (ng/mL)/(mg/kg)
#> 72          (ng/mL)/(mg/kg)         clast.obs.dn         (ng/mL)/(mg/kg)
#> 73          (ng/mL)/(mg/kg)        clast.pred.dn         (ng/mL)/(mg/kg)
#> 74          (ng/mL)/(mg/kg)               cav.dn         (ng/mL)/(mg/kg)
#> 75          (ng/mL)/(mg/kg)           ctrough.dn         (ng/mL)/(mg/kg)
#> 76          (mg/kg)/(ng/mL)             vss.last                   mL/kg
#> 77          (mg/kg)/(ng/mL)          vss.iv.last                   mL/kg
#> 78          (mg/kg)/(ng/mL)                volpk                   mL/kg
#> 79          (mg/kg)/(ng/mL)               vz.obs                   mL/kg
#> 80          (mg/kg)/(ng/mL)              vz.pred                   mL/kg
#> 81          (mg/kg)/(ng/mL)              vss.obs                   mL/kg
#> 82          (mg/kg)/(ng/mL)             vss.pred                   mL/kg
#> 83          (mg/kg)/(ng/mL)           vss.iv.obs                   mL/kg
#> 84          (mg/kg)/(ng/mL)          vss.iv.pred                   mL/kg
#> 85          (mg/kg)/(ng/mL)           vss.md.obs                   mL/kg
#> 86          (mg/kg)/(ng/mL)          vss.md.pred                   mL/kg
#> 87                 hr*ng/mL              auclast                hr*ng/mL
#> 88                 hr*ng/mL               aucall                hr*ng/mL
#> 89                 hr*ng/mL          aucint.last                hr*ng/mL
#> 90                 hr*ng/mL     aucint.last.dose                hr*ng/mL
#> 91                 hr*ng/mL           aucint.all                hr*ng/mL
#> 92                 hr*ng/mL      aucint.all.dose                hr*ng/mL
#> 93                 hr*ng/mL aucabove.predose.all                hr*ng/mL
#> 94                 hr*ng/mL  aucabove.trough.all                hr*ng/mL
#> 95                 hr*ng/mL       sparse_auclast                hr*ng/mL
#> 96                 hr*ng/mL        sparse_auc_se                hr*ng/mL
#> 97                 hr*ng/mL            aucivlast                hr*ng/mL
#> 98                 hr*ng/mL             aucivall                hr*ng/mL
#> 99                 hr*ng/mL        aucivint.last                hr*ng/mL
#> 100                hr*ng/mL         aucivint.all                hr*ng/mL
#> 101                hr*ng/mL           aucinf.obs                hr*ng/mL
#> 102                hr*ng/mL          aucinf.pred                hr*ng/mL
#> 103                hr*ng/mL       aucint.inf.obs                hr*ng/mL
#> 104                hr*ng/mL  aucint.inf.obs.dose                hr*ng/mL
#> 105                hr*ng/mL      aucint.inf.pred                hr*ng/mL
#> 106                hr*ng/mL aucint.inf.pred.dose                hr*ng/mL
#> 107                hr*ng/mL         aucivinf.obs                hr*ng/mL
#> 108                hr*ng/mL        aucivinf.pred                hr*ng/mL
#> 109              hr^2*ng/mL             aumclast              hr^2*ng/mL
#> 110              hr^2*ng/mL              aumcall              hr^2*ng/mL
#> 111              hr^2*ng/mL          aumcinf.obs              hr^2*ng/mL
#> 112              hr^2*ng/mL         aumcinf.pred              hr^2*ng/mL
#> 113                   hr*mg                ermax                   hr*mg
#> 114      (hr*ng/mL)/(mg/kg)           auclast.dn      (hr*ng/mL)/(mg/kg)
#> 115      (hr*ng/mL)/(mg/kg)            aucall.dn      (hr*ng/mL)/(mg/kg)
#> 116      (hr*ng/mL)/(mg/kg)        aucinf.obs.dn      (hr*ng/mL)/(mg/kg)
#> 117      (hr*ng/mL)/(mg/kg)       aucinf.pred.dn      (hr*ng/mL)/(mg/kg)
#> 118    (hr^2*ng/mL)/(mg/kg)          aumclast.dn    (hr^2*ng/mL)/(mg/kg)
#> 119    (hr^2*ng/mL)/(mg/kg)           aumcall.dn    (hr^2*ng/mL)/(mg/kg)
#> 120    (hr^2*ng/mL)/(mg/kg)       aumcinf.obs.dn    (hr^2*ng/mL)/(mg/kg)
#> 121    (hr^2*ng/mL)/(mg/kg)      aumcinf.pred.dn    (hr^2*ng/mL)/(mg/kg)
#> 122      (mg/kg)/(hr*ng/mL)              cl.last                mL/hr/kg
#> 123      (mg/kg)/(hr*ng/mL)               cl.all                mL/hr/kg
#> 124      (mg/kg)/(hr*ng/mL)               cl.obs                mL/hr/kg
#> 125      (mg/kg)/(hr*ng/mL)              cl.pred                mL/hr/kg
#> 126           mg/(hr*ng/mL)             clr.last           mg/(hr*ng/mL)
#> 127           mg/(hr*ng/mL)              clr.obs           mg/(hr*ng/mL)
#> 128           mg/(hr*ng/mL)             clr.pred           mg/(hr*ng/mL)
#> 129 (mg/(hr*ng/mL))/(mg/kg)          clr.last.dn (mg/(hr*ng/mL))/(mg/kg)
#> 130 (mg/(hr*ng/mL))/(mg/kg)           clr.obs.dn (mg/(hr*ng/mL))/(mg/kg)
#> 131 (mg/(hr*ng/mL))/(mg/kg)          clr.pred.dn (mg/(hr*ng/mL))/(mg/kg)
#>     conversion_factor
#> 1               1e+00
#> 2               1e+00
#> 3               1e+00
#> 4               1e+00
#> 5               1e+00
#> 6               1e+00
#> 7               1e+00
#> 8               1e+00
#> 9               1e+00
#> 10              1e+00
#> 11              1e+00
#> 12              1e+00
#> 13              1e+00
#> 14              1e+00
#> 15              1e+00
#> 16              1e+00
#> 17              1e+00
#> 18              1e+00
#> 19              1e+00
#> 20              1e+00
#> 21              1e+00
#> 22              1e+00
#> 23              1e+00
#> 24              1e+00
#> 25              1e+00
#> 26              1e+00
#> 27              1e+00
#> 28              1e+00
#> 29              1e+00
#> 30              1e+00
#> 31              1e+00
#> 32              1e+00
#> 33              1e+00
#> 34              1e+00
#> 35              1e+00
#> 36              1e+00
#> 37              1e+00
#> 38              1e+00
#> 39              1e+00
#> 40              1e+00
#> 41              1e+00
#> 42              1e+00
#> 43              1e+00
#> 44              1e+00
#> 45              1e+00
#> 46              1e+00
#> 47              1e+00
#> 48              1e+00
#> 49              1e+00
#> 50              1e+00
#> 51              1e+00
#> 52              1e+00
#> 53              1e+00
#> 54              1e+00
#> 55              1e+00
#> 56              1e+00
#> 57              1e+00
#> 58              1e+00
#> 59              1e+00
#> 60              1e+00
#> 61              1e+00
#> 62              1e+00
#> 63              1e+00
#> 64              1e+00
#> 65              1e+00
#> 66              1e+00
#> 67              1e+00
#> 68              1e+00
#> 69              1e+00
#> 70              1e+00
#> 71              1e+00
#> 72              1e+00
#> 73              1e+00
#> 74              1e+00
#> 75              1e+00
#> 76              1e+06
#> 77              1e+06
#> 78              1e+06
#> 79              1e+06
#> 80              1e+06
#> 81              1e+06
#> 82              1e+06
#> 83              1e+06
#> 84              1e+06
#> 85              1e+06
#> 86              1e+06
#> 87              1e+00
#> 88              1e+00
#> 89              1e+00
#> 90              1e+00
#> 91              1e+00
#> 92              1e+00
#> 93              1e+00
#> 94              1e+00
#> 95              1e+00
#> 96              1e+00
#> 97              1e+00
#> 98              1e+00
#> 99              1e+00
#> 100             1e+00
#> 101             1e+00
#> 102             1e+00
#> 103             1e+00
#> 104             1e+00
#> 105             1e+00
#> 106             1e+00
#> 107             1e+00
#> 108             1e+00
#> 109             1e+00
#> 110             1e+00
#> 111             1e+00
#> 112             1e+00
#> 113             1e+00
#> 114             1e+00
#> 115             1e+00
#> 116             1e+00
#> 117             1e+00
#> 118             1e+00
#> 119             1e+00
#> 120             1e+00
#> 121             1e+00
#> 122             1e+06
#> 123             1e+06
#> 124             1e+06
#> 125             1e+06
#> 126             1e+00
#> 127             1e+00
#> 128             1e+00
#> 129             1e+00
#> 130             1e+00
#> 131             1e+00
pknca_units_table(
  concu="mg/L", doseu="mg/kg", amountu="mg", timeu="hr",
  # Convert clearance and volume units to molar units (assuming
  conversions=data.frame(
    PPORRESU=c("mg/L", "(mg/kg)/(hr*ng/mL)", "(mg/kg)/(ng/mL)"),
    PPSTRESU=c("mmol/L", "mL/hr/kg", "mL/kg"),
    # Manual conversion of concentration units from ng/mL to mmol/L (assuming
    # a molecular weight of 138.121 g/mol)
    conversion_factor=c(1/138.121, NA, NA)
  )
)
#> Warning: The following unit conversions were supplied but do not match any units to convert: '(mg/kg)/(hr*ng/mL)', '(mg/kg)/(ng/mL)'
#>                   PPORRESU             PPTESTCD               PPSTRESU
#> 1                 unitless            r.squared               unitless
#> 2                 unitless        adj.r.squared               unitless
#> 3                 unitless      lambda.z.corrxy               unitless
#> 4                 fraction                    f               fraction
#> 5                 fraction                  ptr               fraction
#> 6                 fraction           span.ratio               fraction
#> 7                        %             deg.fluc                      %
#> 8                        %                swing                      %
#> 9                        %       aucivpbextlast                      %
#> 10                       %        aucivpbextall                      %
#> 11                       %   aucivpbextint.last                      %
#> 12                       %    aucivpbextint.all                      %
#> 13                       %    aucivpbextinf.obs                      %
#> 14                       %   aucivpbextinf.pred                      %
#> 15                       %          aucpext.obs                      %
#> 16                       %         aucpext.pred                      %
#> 17                   count           count_conc                  count
#> 18                   count  count_conc_measured                  count
#> 19                   count        sparse_auc_df                  count
#> 20                   count    lambda.z.n.points                  count
#> 21                      hr                start                     hr
#> 22                      hr                  end                     hr
#> 23                      hr                 tmax                     hr
#> 24                      hr                tlast                     hr
#> 25                      hr               tfirst                     hr
#> 26                      hr             mrt.last                     hr
#> 27                      hr          mrt.iv.last                     hr
#> 28                      hr                 tlag                     hr
#> 29                      hr               ertlst                     hr
#> 30                      hr               ertmax                     hr
#> 31                      hr           time_above                     hr
#> 32                      hr            half.life                     hr
#> 33                      hr  lambda.z.time.first                     hr
#> 34                      hr   lambda.z.time.last                     hr
#> 35                      hr       thalf.eff.last                     hr
#> 36                      hr    thalf.eff.iv.last                     hr
#> 37                      hr              mrt.obs                     hr
#> 38                      hr             mrt.pred                     hr
#> 39                      hr           mrt.iv.obs                     hr
#> 40                      hr          mrt.iv.pred                     hr
#> 41                      hr           mrt.md.obs                     hr
#> 42                      hr          mrt.md.pred                     hr
#> 43                      hr        thalf.eff.obs                     hr
#> 44                      hr       thalf.eff.pred                     hr
#> 45                      hr     thalf.eff.iv.obs                     hr
#> 46                      hr    thalf.eff.iv.pred                     hr
#> 47                    1/hr             lambda.z                   1/hr
#> 48                    1/hr             kel.last                   1/hr
#> 49                    1/hr          kel.iv.last                   1/hr
#> 50                    1/hr              kel.obs                   1/hr
#> 51                    1/hr             kel.pred                   1/hr
#> 52                    1/hr           kel.iv.obs                   1/hr
#> 53                    1/hr          kel.iv.pred                   1/hr
#> 54                    mg/L                   c0                 mmol/L
#> 55                    mg/L                 cmax                 mmol/L
#> 56                    mg/L                 cmin                 mmol/L
#> 57                    mg/L            clast.obs                 mmol/L
#> 58                    mg/L                  cav                 mmol/L
#> 59                    mg/L         cav.int.last                 mmol/L
#> 60                    mg/L          cav.int.all                 mmol/L
#> 61                    mg/L              ctrough                 mmol/L
#> 62                    mg/L               cstart                 mmol/L
#> 63                    mg/L                 ceoi                 mmol/L
#> 64                    mg/L           clast.pred                 mmol/L
#> 65                    mg/L      cav.int.inf.obs                 mmol/L
#> 66                    mg/L     cav.int.inf.pred                 mmol/L
#> 67                      mg                   ae                     mg
#> 68              mg/(mg/kg)                   fe             mg/(mg/kg)
#> 69                   mg/kg              totdose                  mg/kg
#> 70          (mg/L)/(mg/kg)              cmax.dn         (mg/L)/(mg/kg)
#> 71          (mg/L)/(mg/kg)              cmin.dn         (mg/L)/(mg/kg)
#> 72          (mg/L)/(mg/kg)         clast.obs.dn         (mg/L)/(mg/kg)
#> 73          (mg/L)/(mg/kg)        clast.pred.dn         (mg/L)/(mg/kg)
#> 74          (mg/L)/(mg/kg)               cav.dn         (mg/L)/(mg/kg)
#> 75          (mg/L)/(mg/kg)           ctrough.dn         (mg/L)/(mg/kg)
#> 76          (mg/kg)/(mg/L)             vss.last         (mg/kg)/(mg/L)
#> 77          (mg/kg)/(mg/L)          vss.iv.last         (mg/kg)/(mg/L)
#> 78          (mg/kg)/(mg/L)                volpk         (mg/kg)/(mg/L)
#> 79          (mg/kg)/(mg/L)               vz.obs         (mg/kg)/(mg/L)
#> 80          (mg/kg)/(mg/L)              vz.pred         (mg/kg)/(mg/L)
#> 81          (mg/kg)/(mg/L)              vss.obs         (mg/kg)/(mg/L)
#> 82          (mg/kg)/(mg/L)             vss.pred         (mg/kg)/(mg/L)
#> 83          (mg/kg)/(mg/L)           vss.iv.obs         (mg/kg)/(mg/L)
#> 84          (mg/kg)/(mg/L)          vss.iv.pred         (mg/kg)/(mg/L)
#> 85          (mg/kg)/(mg/L)           vss.md.obs         (mg/kg)/(mg/L)
#> 86          (mg/kg)/(mg/L)          vss.md.pred         (mg/kg)/(mg/L)
#> 87                 hr*mg/L              auclast                hr*mg/L
#> 88                 hr*mg/L               aucall                hr*mg/L
#> 89                 hr*mg/L          aucint.last                hr*mg/L
#> 90                 hr*mg/L     aucint.last.dose                hr*mg/L
#> 91                 hr*mg/L           aucint.all                hr*mg/L
#> 92                 hr*mg/L      aucint.all.dose                hr*mg/L
#> 93                 hr*mg/L aucabove.predose.all                hr*mg/L
#> 94                 hr*mg/L  aucabove.trough.all                hr*mg/L
#> 95                 hr*mg/L       sparse_auclast                hr*mg/L
#> 96                 hr*mg/L        sparse_auc_se                hr*mg/L
#> 97                 hr*mg/L            aucivlast                hr*mg/L
#> 98                 hr*mg/L             aucivall                hr*mg/L
#> 99                 hr*mg/L        aucivint.last                hr*mg/L
#> 100                hr*mg/L         aucivint.all                hr*mg/L
#> 101                hr*mg/L           aucinf.obs                hr*mg/L
#> 102                hr*mg/L          aucinf.pred                hr*mg/L
#> 103                hr*mg/L       aucint.inf.obs                hr*mg/L
#> 104                hr*mg/L  aucint.inf.obs.dose                hr*mg/L
#> 105                hr*mg/L      aucint.inf.pred                hr*mg/L
#> 106                hr*mg/L aucint.inf.pred.dose                hr*mg/L
#> 107                hr*mg/L         aucivinf.obs                hr*mg/L
#> 108                hr*mg/L        aucivinf.pred                hr*mg/L
#> 109              hr^2*mg/L             aumclast              hr^2*mg/L
#> 110              hr^2*mg/L              aumcall              hr^2*mg/L
#> 111              hr^2*mg/L          aumcinf.obs              hr^2*mg/L
#> 112              hr^2*mg/L         aumcinf.pred              hr^2*mg/L
#> 113                  hr*mg                ermax                  hr*mg
#> 114      (hr*mg/L)/(mg/kg)           auclast.dn      (hr*mg/L)/(mg/kg)
#> 115      (hr*mg/L)/(mg/kg)            aucall.dn      (hr*mg/L)/(mg/kg)
#> 116      (hr*mg/L)/(mg/kg)        aucinf.obs.dn      (hr*mg/L)/(mg/kg)
#> 117      (hr*mg/L)/(mg/kg)       aucinf.pred.dn      (hr*mg/L)/(mg/kg)
#> 118    (hr^2*mg/L)/(mg/kg)          aumclast.dn    (hr^2*mg/L)/(mg/kg)
#> 119    (hr^2*mg/L)/(mg/kg)           aumcall.dn    (hr^2*mg/L)/(mg/kg)
#> 120    (hr^2*mg/L)/(mg/kg)       aumcinf.obs.dn    (hr^2*mg/L)/(mg/kg)
#> 121    (hr^2*mg/L)/(mg/kg)      aumcinf.pred.dn    (hr^2*mg/L)/(mg/kg)
#> 122      (mg/kg)/(hr*mg/L)              cl.last      (mg/kg)/(hr*mg/L)
#> 123      (mg/kg)/(hr*mg/L)               cl.all      (mg/kg)/(hr*mg/L)
#> 124      (mg/kg)/(hr*mg/L)               cl.obs      (mg/kg)/(hr*mg/L)
#> 125      (mg/kg)/(hr*mg/L)              cl.pred      (mg/kg)/(hr*mg/L)
#> 126           mg/(hr*mg/L)             clr.last           mg/(hr*mg/L)
#> 127           mg/(hr*mg/L)              clr.obs           mg/(hr*mg/L)
#> 128           mg/(hr*mg/L)             clr.pred           mg/(hr*mg/L)
#> 129 (mg/(hr*mg/L))/(mg/kg)          clr.last.dn (mg/(hr*mg/L))/(mg/kg)
#> 130 (mg/(hr*mg/L))/(mg/kg)           clr.obs.dn (mg/(hr*mg/L))/(mg/kg)
#> 131 (mg/(hr*mg/L))/(mg/kg)          clr.pred.dn (mg/(hr*mg/L))/(mg/kg)
#>     conversion_factor
#> 1         1.000000000
#> 2         1.000000000
#> 3         1.000000000
#> 4         1.000000000
#> 5         1.000000000
#> 6         1.000000000
#> 7         1.000000000
#> 8         1.000000000
#> 9         1.000000000
#> 10        1.000000000
#> 11        1.000000000
#> 12        1.000000000
#> 13        1.000000000
#> 14        1.000000000
#> 15        1.000000000
#> 16        1.000000000
#> 17        1.000000000
#> 18        1.000000000
#> 19        1.000000000
#> 20        1.000000000
#> 21        1.000000000
#> 22        1.000000000
#> 23        1.000000000
#> 24        1.000000000
#> 25        1.000000000
#> 26        1.000000000
#> 27        1.000000000
#> 28        1.000000000
#> 29        1.000000000
#> 30        1.000000000
#> 31        1.000000000
#> 32        1.000000000
#> 33        1.000000000
#> 34        1.000000000
#> 35        1.000000000
#> 36        1.000000000
#> 37        1.000000000
#> 38        1.000000000
#> 39        1.000000000
#> 40        1.000000000
#> 41        1.000000000
#> 42        1.000000000
#> 43        1.000000000
#> 44        1.000000000
#> 45        1.000000000
#> 46        1.000000000
#> 47        1.000000000
#> 48        1.000000000
#> 49        1.000000000
#> 50        1.000000000
#> 51        1.000000000
#> 52        1.000000000
#> 53        1.000000000
#> 54        0.007240029
#> 55        0.007240029
#> 56        0.007240029
#> 57        0.007240029
#> 58        0.007240029
#> 59        0.007240029
#> 60        0.007240029
#> 61        0.007240029
#> 62        0.007240029
#> 63        0.007240029
#> 64        0.007240029
#> 65        0.007240029
#> 66        0.007240029
#> 67        1.000000000
#> 68        1.000000000
#> 69        1.000000000
#> 70        1.000000000
#> 71        1.000000000
#> 72        1.000000000
#> 73        1.000000000
#> 74        1.000000000
#> 75        1.000000000
#> 76        1.000000000
#> 77        1.000000000
#> 78        1.000000000
#> 79        1.000000000
#> 80        1.000000000
#> 81        1.000000000
#> 82        1.000000000
#> 83        1.000000000
#> 84        1.000000000
#> 85        1.000000000
#> 86        1.000000000
#> 87        1.000000000
#> 88        1.000000000
#> 89        1.000000000
#> 90        1.000000000
#> 91        1.000000000
#> 92        1.000000000
#> 93        1.000000000
#> 94        1.000000000
#> 95        1.000000000
#> 96        1.000000000
#> 97        1.000000000
#> 98        1.000000000
#> 99        1.000000000
#> 100       1.000000000
#> 101       1.000000000
#> 102       1.000000000
#> 103       1.000000000
#> 104       1.000000000
#> 105       1.000000000
#> 106       1.000000000
#> 107       1.000000000
#> 108       1.000000000
#> 109       1.000000000
#> 110       1.000000000
#> 111       1.000000000
#> 112       1.000000000
#> 113       1.000000000
#> 114       1.000000000
#> 115       1.000000000
#> 116       1.000000000
#> 117       1.000000000
#> 118       1.000000000
#> 119       1.000000000
#> 120       1.000000000
#> 121       1.000000000
#> 122       1.000000000
#> 123       1.000000000
#> 124       1.000000000
#> 125       1.000000000
#> 126       1.000000000
#> 127       1.000000000
#> 128       1.000000000
#> 129       1.000000000
#> 130       1.000000000
#> 131       1.000000000

# This will make all time-related parameters use "day" even though the
# original units are "hr"
pknca_units_table(
  concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
  timeu_pref = "day"
)
#>                    PPORRESU             PPTESTCD                 PPSTRESU
#> 1                  unitless            r.squared                 unitless
#> 2                  unitless        adj.r.squared                 unitless
#> 3                  unitless      lambda.z.corrxy                 unitless
#> 4                  fraction                    f                 fraction
#> 5                  fraction                  ptr                 fraction
#> 6                  fraction           span.ratio                 fraction
#> 7                         %             deg.fluc                        %
#> 8                         %                swing                        %
#> 9                         %       aucivpbextlast                        %
#> 10                        %        aucivpbextall                        %
#> 11                        %   aucivpbextint.last                        %
#> 12                        %    aucivpbextint.all                        %
#> 13                        %    aucivpbextinf.obs                        %
#> 14                        %   aucivpbextinf.pred                        %
#> 15                        %          aucpext.obs                        %
#> 16                        %         aucpext.pred                        %
#> 17                    count           count_conc                    count
#> 18                    count  count_conc_measured                    count
#> 19                    count        sparse_auc_df                    count
#> 20                    count    lambda.z.n.points                    count
#> 21                       hr                start                      day
#> 22                       hr                  end                      day
#> 23                       hr                 tmax                      day
#> 24                       hr                tlast                      day
#> 25                       hr               tfirst                      day
#> 26                       hr             mrt.last                      day
#> 27                       hr          mrt.iv.last                      day
#> 28                       hr                 tlag                      day
#> 29                       hr               ertlst                      day
#> 30                       hr               ertmax                      day
#> 31                       hr           time_above                      day
#> 32                       hr            half.life                      day
#> 33                       hr  lambda.z.time.first                      day
#> 34                       hr   lambda.z.time.last                      day
#> 35                       hr       thalf.eff.last                      day
#> 36                       hr    thalf.eff.iv.last                      day
#> 37                       hr              mrt.obs                      day
#> 38                       hr             mrt.pred                      day
#> 39                       hr           mrt.iv.obs                      day
#> 40                       hr          mrt.iv.pred                      day
#> 41                       hr           mrt.md.obs                      day
#> 42                       hr          mrt.md.pred                      day
#> 43                       hr        thalf.eff.obs                      day
#> 44                       hr       thalf.eff.pred                      day
#> 45                       hr     thalf.eff.iv.obs                      day
#> 46                       hr    thalf.eff.iv.pred                      day
#> 47                     1/hr             lambda.z                    1/day
#> 48                     1/hr             kel.last                    1/day
#> 49                     1/hr          kel.iv.last                    1/day
#> 50                     1/hr              kel.obs                    1/day
#> 51                     1/hr             kel.pred                    1/day
#> 52                     1/hr           kel.iv.obs                    1/day
#> 53                     1/hr          kel.iv.pred                    1/day
#> 54                    ng/mL                   c0                    ng/mL
#> 55                    ng/mL                 cmax                    ng/mL
#> 56                    ng/mL                 cmin                    ng/mL
#> 57                    ng/mL            clast.obs                    ng/mL
#> 58                    ng/mL                  cav                    ng/mL
#> 59                    ng/mL         cav.int.last                    ng/mL
#> 60                    ng/mL          cav.int.all                    ng/mL
#> 61                    ng/mL              ctrough                    ng/mL
#> 62                    ng/mL               cstart                    ng/mL
#> 63                    ng/mL                 ceoi                    ng/mL
#> 64                    ng/mL           clast.pred                    ng/mL
#> 65                    ng/mL      cav.int.inf.obs                    ng/mL
#> 66                    ng/mL     cav.int.inf.pred                    ng/mL
#> 67                       mg                   ae                       mg
#> 68               mg/(mg/kg)                   fe               mg/(mg/kg)
#> 69                    mg/kg              totdose                    mg/kg
#> 70          (ng/mL)/(mg/kg)              cmax.dn          (ng/mL)/(mg/kg)
#> 71          (ng/mL)/(mg/kg)              cmin.dn          (ng/mL)/(mg/kg)
#> 72          (ng/mL)/(mg/kg)         clast.obs.dn          (ng/mL)/(mg/kg)
#> 73          (ng/mL)/(mg/kg)        clast.pred.dn          (ng/mL)/(mg/kg)
#> 74          (ng/mL)/(mg/kg)               cav.dn          (ng/mL)/(mg/kg)
#> 75          (ng/mL)/(mg/kg)           ctrough.dn          (ng/mL)/(mg/kg)
#> 76          (mg/kg)/(ng/mL)             vss.last          (mg/kg)/(ng/mL)
#> 77          (mg/kg)/(ng/mL)          vss.iv.last          (mg/kg)/(ng/mL)
#> 78          (mg/kg)/(ng/mL)                volpk          (mg/kg)/(ng/mL)
#> 79          (mg/kg)/(ng/mL)               vz.obs          (mg/kg)/(ng/mL)
#> 80          (mg/kg)/(ng/mL)              vz.pred          (mg/kg)/(ng/mL)
#> 81          (mg/kg)/(ng/mL)              vss.obs          (mg/kg)/(ng/mL)
#> 82          (mg/kg)/(ng/mL)             vss.pred          (mg/kg)/(ng/mL)
#> 83          (mg/kg)/(ng/mL)           vss.iv.obs          (mg/kg)/(ng/mL)
#> 84          (mg/kg)/(ng/mL)          vss.iv.pred          (mg/kg)/(ng/mL)
#> 85          (mg/kg)/(ng/mL)           vss.md.obs          (mg/kg)/(ng/mL)
#> 86          (mg/kg)/(ng/mL)          vss.md.pred          (mg/kg)/(ng/mL)
#> 87                 hr*ng/mL              auclast                day*ng/mL
#> 88                 hr*ng/mL               aucall                day*ng/mL
#> 89                 hr*ng/mL          aucint.last                day*ng/mL
#> 90                 hr*ng/mL     aucint.last.dose                day*ng/mL
#> 91                 hr*ng/mL           aucint.all                day*ng/mL
#> 92                 hr*ng/mL      aucint.all.dose                day*ng/mL
#> 93                 hr*ng/mL aucabove.predose.all                day*ng/mL
#> 94                 hr*ng/mL  aucabove.trough.all                day*ng/mL
#> 95                 hr*ng/mL       sparse_auclast                day*ng/mL
#> 96                 hr*ng/mL        sparse_auc_se                day*ng/mL
#> 97                 hr*ng/mL            aucivlast                day*ng/mL
#> 98                 hr*ng/mL             aucivall                day*ng/mL
#> 99                 hr*ng/mL        aucivint.last                day*ng/mL
#> 100                hr*ng/mL         aucivint.all                day*ng/mL
#> 101                hr*ng/mL           aucinf.obs                day*ng/mL
#> 102                hr*ng/mL          aucinf.pred                day*ng/mL
#> 103                hr*ng/mL       aucint.inf.obs                day*ng/mL
#> 104                hr*ng/mL  aucint.inf.obs.dose                day*ng/mL
#> 105                hr*ng/mL      aucint.inf.pred                day*ng/mL
#> 106                hr*ng/mL aucint.inf.pred.dose                day*ng/mL
#> 107                hr*ng/mL         aucivinf.obs                day*ng/mL
#> 108                hr*ng/mL        aucivinf.pred                day*ng/mL
#> 109              hr^2*ng/mL             aumclast              day^2*ng/mL
#> 110              hr^2*ng/mL              aumcall              day^2*ng/mL
#> 111              hr^2*ng/mL          aumcinf.obs              day^2*ng/mL
#> 112              hr^2*ng/mL         aumcinf.pred              day^2*ng/mL
#> 113                   hr*mg                ermax                   day*mg
#> 114      (hr*ng/mL)/(mg/kg)           auclast.dn      (day*ng/mL)/(mg/kg)
#> 115      (hr*ng/mL)/(mg/kg)            aucall.dn      (day*ng/mL)/(mg/kg)
#> 116      (hr*ng/mL)/(mg/kg)        aucinf.obs.dn      (day*ng/mL)/(mg/kg)
#> 117      (hr*ng/mL)/(mg/kg)       aucinf.pred.dn      (day*ng/mL)/(mg/kg)
#> 118    (hr^2*ng/mL)/(mg/kg)          aumclast.dn    (day^2*ng/mL)/(mg/kg)
#> 119    (hr^2*ng/mL)/(mg/kg)           aumcall.dn    (day^2*ng/mL)/(mg/kg)
#> 120    (hr^2*ng/mL)/(mg/kg)       aumcinf.obs.dn    (day^2*ng/mL)/(mg/kg)
#> 121    (hr^2*ng/mL)/(mg/kg)      aumcinf.pred.dn    (day^2*ng/mL)/(mg/kg)
#> 122      (mg/kg)/(hr*ng/mL)              cl.last      (mg/kg)/(day*ng/mL)
#> 123      (mg/kg)/(hr*ng/mL)               cl.all      (mg/kg)/(day*ng/mL)
#> 124      (mg/kg)/(hr*ng/mL)               cl.obs      (mg/kg)/(day*ng/mL)
#> 125      (mg/kg)/(hr*ng/mL)              cl.pred      (mg/kg)/(day*ng/mL)
#> 126           mg/(hr*ng/mL)             clr.last           mg/(day*ng/mL)
#> 127           mg/(hr*ng/mL)              clr.obs           mg/(day*ng/mL)
#> 128           mg/(hr*ng/mL)             clr.pred           mg/(day*ng/mL)
#> 129 (mg/(hr*ng/mL))/(mg/kg)          clr.last.dn (mg/(day*ng/mL))/(mg/kg)
#> 130 (mg/(hr*ng/mL))/(mg/kg)           clr.obs.dn (mg/(day*ng/mL))/(mg/kg)
#> 131 (mg/(hr*ng/mL))/(mg/kg)          clr.pred.dn (mg/(day*ng/mL))/(mg/kg)
#>     conversion_factor
#> 1         1.000000000
#> 2         1.000000000
#> 3         1.000000000
#> 4         1.000000000
#> 5         1.000000000
#> 6         1.000000000
#> 7         1.000000000
#> 8         1.000000000
#> 9         1.000000000
#> 10        1.000000000
#> 11        1.000000000
#> 12        1.000000000
#> 13        1.000000000
#> 14        1.000000000
#> 15        1.000000000
#> 16        1.000000000
#> 17        1.000000000
#> 18        1.000000000
#> 19        1.000000000
#> 20        1.000000000
#> 21        0.041666667
#> 22        0.041666667
#> 23        0.041666667
#> 24        0.041666667
#> 25        0.041666667
#> 26        0.041666667
#> 27        0.041666667
#> 28        0.041666667
#> 29        0.041666667
#> 30        0.041666667
#> 31        0.041666667
#> 32        0.041666667
#> 33        0.041666667
#> 34        0.041666667
#> 35        0.041666667
#> 36        0.041666667
#> 37        0.041666667
#> 38        0.041666667
#> 39        0.041666667
#> 40        0.041666667
#> 41        0.041666667
#> 42        0.041666667
#> 43        0.041666667
#> 44        0.041666667
#> 45        0.041666667
#> 46        0.041666667
#> 47       24.000000000
#> 48       24.000000000
#> 49       24.000000000
#> 50       24.000000000
#> 51       24.000000000
#> 52       24.000000000
#> 53       24.000000000
#> 54        1.000000000
#> 55        1.000000000
#> 56        1.000000000
#> 57        1.000000000
#> 58        1.000000000
#> 59        1.000000000
#> 60        1.000000000
#> 61        1.000000000
#> 62        1.000000000
#> 63        1.000000000
#> 64        1.000000000
#> 65        1.000000000
#> 66        1.000000000
#> 67        1.000000000
#> 68        1.000000000
#> 69        1.000000000
#> 70        1.000000000
#> 71        1.000000000
#> 72        1.000000000
#> 73        1.000000000
#> 74        1.000000000
#> 75        1.000000000
#> 76        1.000000000
#> 77        1.000000000
#> 78        1.000000000
#> 79        1.000000000
#> 80        1.000000000
#> 81        1.000000000
#> 82        1.000000000
#> 83        1.000000000
#> 84        1.000000000
#> 85        1.000000000
#> 86        1.000000000
#> 87        0.041666667
#> 88        0.041666667
#> 89        0.041666667
#> 90        0.041666667
#> 91        0.041666667
#> 92        0.041666667
#> 93        0.041666667
#> 94        0.041666667
#> 95        0.041666667
#> 96        0.041666667
#> 97        0.041666667
#> 98        0.041666667
#> 99        0.041666667
#> 100       0.041666667
#> 101       0.041666667
#> 102       0.041666667
#> 103       0.041666667
#> 104       0.041666667
#> 105       0.041666667
#> 106       0.041666667
#> 107       0.041666667
#> 108       0.041666667
#> 109       0.001736111
#> 110       0.001736111
#> 111       0.001736111
#> 112       0.001736111
#> 113       0.041666667
#> 114       0.041666667
#> 115       0.041666667
#> 116       0.041666667
#> 117       0.041666667
#> 118       0.001736111
#> 119       0.001736111
#> 120       0.001736111
#> 121       0.001736111
#> 122      24.000000000
#> 123      24.000000000
#> 124      24.000000000
#> 125      24.000000000
#> 126      24.000000000
#> 127      24.000000000
#> 128      24.000000000
#> 129      24.000000000
#> 130      24.000000000
#> 131      24.000000000
```
