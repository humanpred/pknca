# Create a unit assignment and conversion table

This data.frame is typically used for the `units` argument for
[`PKNCAdata()`](http://humanpred.github.io/pknca/reference/PKNCAdata.md).
If a unit is not given, then all of the units derived from that unit
will be `NA`.

## Usage

``` r
pknca_units_table(concu, ...)

# Default S3 method
pknca_units_table(
  concu,
  doseu,
  amountu,
  timeu,
  concu_pref = NULL,
  doseu_pref = NULL,
  amountu_pref = NULL,
  timeu_pref = NULL,
  conversions = data.frame(),
  ...
)

# S3 method for class 'PKNCAdata'
pknca_units_table(concu, ..., conversions = data.frame())
```

## Arguments

- concu, doseu, amountu, timeu:

  Units for concentration, dose, amount, and time in the source data

- ...:

  Additional arguments (not used)

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
#>     PPORRESU              PPTESTCD
#> 1   unitless             r.squared
#> 2   unitless         adj.r.squared
#> 3   unitless       lambda.z.corrxy
#> 4   unitless        tobit_residual
#> 5   unitless    adj_tobit_residual
#> 6   fraction                     f
#> 7   fraction                   ptr
#> 8   fraction            span.ratio
#> 9          %              deg.fluc
#> 10         %                 swing
#> 11         %        aucivpbextlast
#> 12         %         aucivpbextall
#> 13         %    aucivpbextint.last
#> 14         %     aucivpbextint.all
#> 15         %     aucivpbextinf.obs
#> 16         %    aucivpbextinf.pred
#> 17         %           aucpext.obs
#> 18         %          aucpext.pred
#> 19     count            count_conc
#> 20     count   count_conc_measured
#> 21     count         sparse_auc_df
#> 22     count        sparse_aumc_df
#> 23     count     lambda.z.n.points
#> 24     count lambda.z.n.points_blq
#> 25      <NA>                 start
#> 26      <NA>                   end
#> 27      <NA>                  tmax
#> 28      <NA>                  tmin
#> 29      <NA>                 tlast
#> 30      <NA>                tfirst
#> 31      <NA>              mrt.last
#> 32      <NA>           mrt.iv.last
#> 33      <NA>                  tlag
#> 34      <NA>                ertlst
#> 35      <NA>                ertmax
#> 36      <NA>            time_above
#> 37      <NA>             half.life
#> 38      <NA>   lambda.z.time.first
#> 39      <NA>    lambda.z.time.last
#> 40      <NA>        thalf.eff.last
#> 41      <NA>     thalf.eff.iv.last
#> 42      <NA>       mrt.sparse.last
#> 43      <NA>               mrt.obs
#> 44      <NA>              mrt.pred
#> 45      <NA>            mrt.iv.obs
#> 46      <NA>           mrt.iv.pred
#> 47      <NA>            mrt.md.obs
#> 48      <NA>           mrt.md.pred
#> 49      <NA>         thalf.eff.obs
#> 50      <NA>        thalf.eff.pred
#> 51      <NA>      thalf.eff.iv.obs
#> 52      <NA>     thalf.eff.iv.pred
#> 53      <NA>              lambda.z
#> 54      <NA>              kel.last
#> 55      <NA>           kel.iv.last
#> 56      <NA>       kel.sparse.last
#> 57      <NA>               kel.obs
#> 58      <NA>              kel.pred
#> 59      <NA>            kel.iv.obs
#> 60      <NA>           kel.iv.pred
#> 61      <NA>                    c0
#> 62      <NA>                  cmax
#> 63      <NA>                  cmin
#> 64      <NA>             clast.obs
#> 65      <NA>                   cav
#> 66      <NA>          cav.int.last
#> 67      <NA>           cav.int.all
#> 68      <NA>               ctrough
#> 69      <NA>                cstart
#> 70      <NA>                  ceoi
#> 71      <NA>            clast.pred
#> 72      <NA>       cav.int.inf.obs
#> 73      <NA>      cav.int.inf.pred
#> 74      <NA>                    ae
#> 75      <NA>                    fe
#> 76      <NA>               totdose
#> 77      <NA>               cmax.dn
#> 78      <NA>               cmin.dn
#> 79      <NA>          clast.obs.dn
#> 80      <NA>         clast.pred.dn
#> 81      <NA>                cav.dn
#> 82      <NA>            ctrough.dn
#> 83      <NA>              vss.last
#> 84      <NA>           vss.iv.last
#> 85      <NA>                 volpk
#> 86      <NA>       vss.sparse.last
#> 87      <NA>                vz.obs
#> 88      <NA>               vz.pred
#> 89      <NA>        vz.sparse.last
#> 90      <NA>               vss.obs
#> 91      <NA>              vss.pred
#> 92      <NA>            vss.iv.obs
#> 93      <NA>           vss.iv.pred
#> 94      <NA>            vss.md.obs
#> 95      <NA>           vss.md.pred
#> 96      <NA>               auclast
#> 97      <NA>                aucall
#> 98      <NA>           aucint.last
#> 99      <NA>      aucint.last.dose
#> 100     <NA>            aucint.all
#> 101     <NA>       aucint.all.dose
#> 102     <NA>  aucabove.predose.all
#> 103     <NA>   aucabove.trough.all
#> 104     <NA>        sparse_auclast
#> 105     <NA>         sparse_auc_se
#> 106     <NA>             aucivlast
#> 107     <NA>              aucivall
#> 108     <NA>         aucivint.last
#> 109     <NA>          aucivint.all
#> 110     <NA>            aucinf.obs
#> 111     <NA>           aucinf.pred
#> 112     <NA>        aucint.inf.obs
#> 113     <NA>   aucint.inf.obs.dose
#> 114     <NA>       aucint.inf.pred
#> 115     <NA>  aucint.inf.pred.dose
#> 116     <NA>          aucivinf.obs
#> 117     <NA>         aucivinf.pred
#> 118     <NA>              aumclast
#> 119     <NA>               aumcall
#> 120     <NA>       sparse_aumclast
#> 121     <NA>        sparse_aumc_se
#> 122     <NA>           aumcinf.obs
#> 123     <NA>          aumcinf.pred
#> 124     <NA>                 ermax
#> 125     <NA>            auclast.dn
#> 126     <NA>             aucall.dn
#> 127     <NA>         aucinf.obs.dn
#> 128     <NA>        aucinf.pred.dn
#> 129     <NA>           aumclast.dn
#> 130     <NA>            aumcall.dn
#> 131     <NA>        aumcinf.obs.dn
#> 132     <NA>       aumcinf.pred.dn
#> 133     <NA>               cl.last
#> 134     <NA>                cl.all
#> 135     <NA>        cl.sparse.last
#> 136     <NA>                cl.obs
#> 137     <NA>               cl.pred
#> 138     <NA>              clr.last
#> 139     <NA>               clr.obs
#> 140     <NA>              clr.pred
#> 141     <NA>           clr.last.dn
#> 142     <NA>            clr.obs.dn
#> 143     <NA>           clr.pred.dn
pknca_units_table(
  concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr"
)
#>                    PPORRESU              PPTESTCD
#> 1                  unitless             r.squared
#> 2                  unitless         adj.r.squared
#> 3                  unitless       lambda.z.corrxy
#> 4                  unitless        tobit_residual
#> 5                  unitless    adj_tobit_residual
#> 6                  fraction                     f
#> 7                  fraction                   ptr
#> 8                  fraction            span.ratio
#> 9                         %              deg.fluc
#> 10                        %                 swing
#> 11                        %        aucivpbextlast
#> 12                        %         aucivpbextall
#> 13                        %    aucivpbextint.last
#> 14                        %     aucivpbextint.all
#> 15                        %     aucivpbextinf.obs
#> 16                        %    aucivpbextinf.pred
#> 17                        %           aucpext.obs
#> 18                        %          aucpext.pred
#> 19                    count            count_conc
#> 20                    count   count_conc_measured
#> 21                    count         sparse_auc_df
#> 22                    count        sparse_aumc_df
#> 23                    count     lambda.z.n.points
#> 24                    count lambda.z.n.points_blq
#> 25                       hr                 start
#> 26                       hr                   end
#> 27                       hr                  tmax
#> 28                       hr                  tmin
#> 29                       hr                 tlast
#> 30                       hr                tfirst
#> 31                       hr              mrt.last
#> 32                       hr           mrt.iv.last
#> 33                       hr                  tlag
#> 34                       hr                ertlst
#> 35                       hr                ertmax
#> 36                       hr            time_above
#> 37                       hr             half.life
#> 38                       hr   lambda.z.time.first
#> 39                       hr    lambda.z.time.last
#> 40                       hr        thalf.eff.last
#> 41                       hr     thalf.eff.iv.last
#> 42                       hr       mrt.sparse.last
#> 43                       hr               mrt.obs
#> 44                       hr              mrt.pred
#> 45                       hr            mrt.iv.obs
#> 46                       hr           mrt.iv.pred
#> 47                       hr            mrt.md.obs
#> 48                       hr           mrt.md.pred
#> 49                       hr         thalf.eff.obs
#> 50                       hr        thalf.eff.pred
#> 51                       hr      thalf.eff.iv.obs
#> 52                       hr     thalf.eff.iv.pred
#> 53                     1/hr              lambda.z
#> 54                     1/hr              kel.last
#> 55                     1/hr           kel.iv.last
#> 56                     1/hr       kel.sparse.last
#> 57                     1/hr               kel.obs
#> 58                     1/hr              kel.pred
#> 59                     1/hr            kel.iv.obs
#> 60                     1/hr           kel.iv.pred
#> 61                    ng/mL                    c0
#> 62                    ng/mL                  cmax
#> 63                    ng/mL                  cmin
#> 64                    ng/mL             clast.obs
#> 65                    ng/mL                   cav
#> 66                    ng/mL          cav.int.last
#> 67                    ng/mL           cav.int.all
#> 68                    ng/mL               ctrough
#> 69                    ng/mL                cstart
#> 70                    ng/mL                  ceoi
#> 71                    ng/mL            clast.pred
#> 72                    ng/mL       cav.int.inf.obs
#> 73                    ng/mL      cav.int.inf.pred
#> 74                       mg                    ae
#> 75               mg/(mg/kg)                    fe
#> 76                    mg/kg               totdose
#> 77          (ng/mL)/(mg/kg)               cmax.dn
#> 78          (ng/mL)/(mg/kg)               cmin.dn
#> 79          (ng/mL)/(mg/kg)          clast.obs.dn
#> 80          (ng/mL)/(mg/kg)         clast.pred.dn
#> 81          (ng/mL)/(mg/kg)                cav.dn
#> 82          (ng/mL)/(mg/kg)            ctrough.dn
#> 83          (mg/kg)/(ng/mL)              vss.last
#> 84          (mg/kg)/(ng/mL)           vss.iv.last
#> 85          (mg/kg)/(ng/mL)                 volpk
#> 86          (mg/kg)/(ng/mL)       vss.sparse.last
#> 87          (mg/kg)/(ng/mL)                vz.obs
#> 88          (mg/kg)/(ng/mL)               vz.pred
#> 89          (mg/kg)/(ng/mL)        vz.sparse.last
#> 90          (mg/kg)/(ng/mL)               vss.obs
#> 91          (mg/kg)/(ng/mL)              vss.pred
#> 92          (mg/kg)/(ng/mL)            vss.iv.obs
#> 93          (mg/kg)/(ng/mL)           vss.iv.pred
#> 94          (mg/kg)/(ng/mL)            vss.md.obs
#> 95          (mg/kg)/(ng/mL)           vss.md.pred
#> 96                 hr*ng/mL               auclast
#> 97                 hr*ng/mL                aucall
#> 98                 hr*ng/mL           aucint.last
#> 99                 hr*ng/mL      aucint.last.dose
#> 100                hr*ng/mL            aucint.all
#> 101                hr*ng/mL       aucint.all.dose
#> 102                hr*ng/mL  aucabove.predose.all
#> 103                hr*ng/mL   aucabove.trough.all
#> 104                hr*ng/mL        sparse_auclast
#> 105                hr*ng/mL         sparse_auc_se
#> 106                hr*ng/mL             aucivlast
#> 107                hr*ng/mL              aucivall
#> 108                hr*ng/mL         aucivint.last
#> 109                hr*ng/mL          aucivint.all
#> 110                hr*ng/mL            aucinf.obs
#> 111                hr*ng/mL           aucinf.pred
#> 112                hr*ng/mL        aucint.inf.obs
#> 113                hr*ng/mL   aucint.inf.obs.dose
#> 114                hr*ng/mL       aucint.inf.pred
#> 115                hr*ng/mL  aucint.inf.pred.dose
#> 116                hr*ng/mL          aucivinf.obs
#> 117                hr*ng/mL         aucivinf.pred
#> 118              hr^2*ng/mL              aumclast
#> 119              hr^2*ng/mL               aumcall
#> 120              hr^2*ng/mL       sparse_aumclast
#> 121              hr^2*ng/mL        sparse_aumc_se
#> 122              hr^2*ng/mL           aumcinf.obs
#> 123              hr^2*ng/mL          aumcinf.pred
#> 124                   mg/hr                 ermax
#> 125      (hr*ng/mL)/(mg/kg)            auclast.dn
#> 126      (hr*ng/mL)/(mg/kg)             aucall.dn
#> 127      (hr*ng/mL)/(mg/kg)         aucinf.obs.dn
#> 128      (hr*ng/mL)/(mg/kg)        aucinf.pred.dn
#> 129    (hr^2*ng/mL)/(mg/kg)           aumclast.dn
#> 130    (hr^2*ng/mL)/(mg/kg)            aumcall.dn
#> 131    (hr^2*ng/mL)/(mg/kg)        aumcinf.obs.dn
#> 132    (hr^2*ng/mL)/(mg/kg)       aumcinf.pred.dn
#> 133      (mg/kg)/(hr*ng/mL)               cl.last
#> 134      (mg/kg)/(hr*ng/mL)                cl.all
#> 135      (mg/kg)/(hr*ng/mL)        cl.sparse.last
#> 136      (mg/kg)/(hr*ng/mL)                cl.obs
#> 137      (mg/kg)/(hr*ng/mL)               cl.pred
#> 138           mg/(hr*ng/mL)              clr.last
#> 139           mg/(hr*ng/mL)               clr.obs
#> 140           mg/(hr*ng/mL)              clr.pred
#> 141 (mg/(hr*ng/mL))/(mg/kg)           clr.last.dn
#> 142 (mg/(hr*ng/mL))/(mg/kg)            clr.obs.dn
#> 143 (mg/(hr*ng/mL))/(mg/kg)           clr.pred.dn
pknca_units_table(
  concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr",
  # Convert clearance and volume units to more understandable units with
  # automatic unit conversion
  conversions=data.frame(
    PPORRESU=c("(mg/kg)/(hr*ng/mL)", "(mg/kg)/(ng/mL)"),
    PPSTRESU=c("mL/hr/kg", "mL/kg")
  )
)
#>                    PPORRESU              PPTESTCD                PPSTRESU
#> 1                  unitless             r.squared                unitless
#> 2                  unitless         adj.r.squared                unitless
#> 3                  unitless       lambda.z.corrxy                unitless
#> 4                  unitless        tobit_residual                unitless
#> 5                  unitless    adj_tobit_residual                unitless
#> 6                  fraction                     f                fraction
#> 7                  fraction                   ptr                fraction
#> 8                  fraction            span.ratio                fraction
#> 9                         %              deg.fluc                       %
#> 10                        %                 swing                       %
#> 11                        %        aucivpbextlast                       %
#> 12                        %         aucivpbextall                       %
#> 13                        %    aucivpbextint.last                       %
#> 14                        %     aucivpbextint.all                       %
#> 15                        %     aucivpbextinf.obs                       %
#> 16                        %    aucivpbextinf.pred                       %
#> 17                        %           aucpext.obs                       %
#> 18                        %          aucpext.pred                       %
#> 19                    count            count_conc                   count
#> 20                    count   count_conc_measured                   count
#> 21                    count         sparse_auc_df                   count
#> 22                    count        sparse_aumc_df                   count
#> 23                    count     lambda.z.n.points                   count
#> 24                    count lambda.z.n.points_blq                   count
#> 25                       hr                 start                      hr
#> 26                       hr                   end                      hr
#> 27                       hr                  tmax                      hr
#> 28                       hr                  tmin                      hr
#> 29                       hr                 tlast                      hr
#> 30                       hr                tfirst                      hr
#> 31                       hr              mrt.last                      hr
#> 32                       hr           mrt.iv.last                      hr
#> 33                       hr                  tlag                      hr
#> 34                       hr                ertlst                      hr
#> 35                       hr                ertmax                      hr
#> 36                       hr            time_above                      hr
#> 37                       hr             half.life                      hr
#> 38                       hr   lambda.z.time.first                      hr
#> 39                       hr    lambda.z.time.last                      hr
#> 40                       hr        thalf.eff.last                      hr
#> 41                       hr     thalf.eff.iv.last                      hr
#> 42                       hr       mrt.sparse.last                      hr
#> 43                       hr               mrt.obs                      hr
#> 44                       hr              mrt.pred                      hr
#> 45                       hr            mrt.iv.obs                      hr
#> 46                       hr           mrt.iv.pred                      hr
#> 47                       hr            mrt.md.obs                      hr
#> 48                       hr           mrt.md.pred                      hr
#> 49                       hr         thalf.eff.obs                      hr
#> 50                       hr        thalf.eff.pred                      hr
#> 51                       hr      thalf.eff.iv.obs                      hr
#> 52                       hr     thalf.eff.iv.pred                      hr
#> 53                     1/hr              lambda.z                    1/hr
#> 54                     1/hr              kel.last                    1/hr
#> 55                     1/hr           kel.iv.last                    1/hr
#> 56                     1/hr       kel.sparse.last                    1/hr
#> 57                     1/hr               kel.obs                    1/hr
#> 58                     1/hr              kel.pred                    1/hr
#> 59                     1/hr            kel.iv.obs                    1/hr
#> 60                     1/hr           kel.iv.pred                    1/hr
#> 61                    ng/mL                    c0                   ng/mL
#> 62                    ng/mL                  cmax                   ng/mL
#> 63                    ng/mL                  cmin                   ng/mL
#> 64                    ng/mL             clast.obs                   ng/mL
#> 65                    ng/mL                   cav                   ng/mL
#> 66                    ng/mL          cav.int.last                   ng/mL
#> 67                    ng/mL           cav.int.all                   ng/mL
#> 68                    ng/mL               ctrough                   ng/mL
#> 69                    ng/mL                cstart                   ng/mL
#> 70                    ng/mL                  ceoi                   ng/mL
#> 71                    ng/mL            clast.pred                   ng/mL
#> 72                    ng/mL       cav.int.inf.obs                   ng/mL
#> 73                    ng/mL      cav.int.inf.pred                   ng/mL
#> 74                       mg                    ae                      mg
#> 75               mg/(mg/kg)                    fe              mg/(mg/kg)
#> 76                    mg/kg               totdose                   mg/kg
#> 77          (ng/mL)/(mg/kg)               cmax.dn         (ng/mL)/(mg/kg)
#> 78          (ng/mL)/(mg/kg)               cmin.dn         (ng/mL)/(mg/kg)
#> 79          (ng/mL)/(mg/kg)          clast.obs.dn         (ng/mL)/(mg/kg)
#> 80          (ng/mL)/(mg/kg)         clast.pred.dn         (ng/mL)/(mg/kg)
#> 81          (ng/mL)/(mg/kg)                cav.dn         (ng/mL)/(mg/kg)
#> 82          (ng/mL)/(mg/kg)            ctrough.dn         (ng/mL)/(mg/kg)
#> 83          (mg/kg)/(ng/mL)              vss.last                   mL/kg
#> 84          (mg/kg)/(ng/mL)           vss.iv.last                   mL/kg
#> 85          (mg/kg)/(ng/mL)                 volpk                   mL/kg
#> 86          (mg/kg)/(ng/mL)       vss.sparse.last                   mL/kg
#> 87          (mg/kg)/(ng/mL)                vz.obs                   mL/kg
#> 88          (mg/kg)/(ng/mL)               vz.pred                   mL/kg
#> 89          (mg/kg)/(ng/mL)        vz.sparse.last                   mL/kg
#> 90          (mg/kg)/(ng/mL)               vss.obs                   mL/kg
#> 91          (mg/kg)/(ng/mL)              vss.pred                   mL/kg
#> 92          (mg/kg)/(ng/mL)            vss.iv.obs                   mL/kg
#> 93          (mg/kg)/(ng/mL)           vss.iv.pred                   mL/kg
#> 94          (mg/kg)/(ng/mL)            vss.md.obs                   mL/kg
#> 95          (mg/kg)/(ng/mL)           vss.md.pred                   mL/kg
#> 96                 hr*ng/mL               auclast                hr*ng/mL
#> 97                 hr*ng/mL                aucall                hr*ng/mL
#> 98                 hr*ng/mL           aucint.last                hr*ng/mL
#> 99                 hr*ng/mL      aucint.last.dose                hr*ng/mL
#> 100                hr*ng/mL            aucint.all                hr*ng/mL
#> 101                hr*ng/mL       aucint.all.dose                hr*ng/mL
#> 102                hr*ng/mL  aucabove.predose.all                hr*ng/mL
#> 103                hr*ng/mL   aucabove.trough.all                hr*ng/mL
#> 104                hr*ng/mL        sparse_auclast                hr*ng/mL
#> 105                hr*ng/mL         sparse_auc_se                hr*ng/mL
#> 106                hr*ng/mL             aucivlast                hr*ng/mL
#> 107                hr*ng/mL              aucivall                hr*ng/mL
#> 108                hr*ng/mL         aucivint.last                hr*ng/mL
#> 109                hr*ng/mL          aucivint.all                hr*ng/mL
#> 110                hr*ng/mL            aucinf.obs                hr*ng/mL
#> 111                hr*ng/mL           aucinf.pred                hr*ng/mL
#> 112                hr*ng/mL        aucint.inf.obs                hr*ng/mL
#> 113                hr*ng/mL   aucint.inf.obs.dose                hr*ng/mL
#> 114                hr*ng/mL       aucint.inf.pred                hr*ng/mL
#> 115                hr*ng/mL  aucint.inf.pred.dose                hr*ng/mL
#> 116                hr*ng/mL          aucivinf.obs                hr*ng/mL
#> 117                hr*ng/mL         aucivinf.pred                hr*ng/mL
#> 118              hr^2*ng/mL              aumclast              hr^2*ng/mL
#> 119              hr^2*ng/mL               aumcall              hr^2*ng/mL
#> 120              hr^2*ng/mL       sparse_aumclast              hr^2*ng/mL
#> 121              hr^2*ng/mL        sparse_aumc_se              hr^2*ng/mL
#> 122              hr^2*ng/mL           aumcinf.obs              hr^2*ng/mL
#> 123              hr^2*ng/mL          aumcinf.pred              hr^2*ng/mL
#> 124                   mg/hr                 ermax                   mg/hr
#> 125      (hr*ng/mL)/(mg/kg)            auclast.dn      (hr*ng/mL)/(mg/kg)
#> 126      (hr*ng/mL)/(mg/kg)             aucall.dn      (hr*ng/mL)/(mg/kg)
#> 127      (hr*ng/mL)/(mg/kg)         aucinf.obs.dn      (hr*ng/mL)/(mg/kg)
#> 128      (hr*ng/mL)/(mg/kg)        aucinf.pred.dn      (hr*ng/mL)/(mg/kg)
#> 129    (hr^2*ng/mL)/(mg/kg)           aumclast.dn    (hr^2*ng/mL)/(mg/kg)
#> 130    (hr^2*ng/mL)/(mg/kg)            aumcall.dn    (hr^2*ng/mL)/(mg/kg)
#> 131    (hr^2*ng/mL)/(mg/kg)        aumcinf.obs.dn    (hr^2*ng/mL)/(mg/kg)
#> 132    (hr^2*ng/mL)/(mg/kg)       aumcinf.pred.dn    (hr^2*ng/mL)/(mg/kg)
#> 133      (mg/kg)/(hr*ng/mL)               cl.last                mL/hr/kg
#> 134      (mg/kg)/(hr*ng/mL)                cl.all                mL/hr/kg
#> 135      (mg/kg)/(hr*ng/mL)        cl.sparse.last                mL/hr/kg
#> 136      (mg/kg)/(hr*ng/mL)                cl.obs                mL/hr/kg
#> 137      (mg/kg)/(hr*ng/mL)               cl.pred                mL/hr/kg
#> 138           mg/(hr*ng/mL)              clr.last           mg/(hr*ng/mL)
#> 139           mg/(hr*ng/mL)               clr.obs           mg/(hr*ng/mL)
#> 140           mg/(hr*ng/mL)              clr.pred           mg/(hr*ng/mL)
#> 141 (mg/(hr*ng/mL))/(mg/kg)           clr.last.dn (mg/(hr*ng/mL))/(mg/kg)
#> 142 (mg/(hr*ng/mL))/(mg/kg)            clr.obs.dn (mg/(hr*ng/mL))/(mg/kg)
#> 143 (mg/(hr*ng/mL))/(mg/kg)           clr.pred.dn (mg/(hr*ng/mL))/(mg/kg)
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
#> 76              1e+00
#> 77              1e+00
#> 78              1e+00
#> 79              1e+00
#> 80              1e+00
#> 81              1e+00
#> 82              1e+00
#> 83              1e+06
#> 84              1e+06
#> 85              1e+06
#> 86              1e+06
#> 87              1e+06
#> 88              1e+06
#> 89              1e+06
#> 90              1e+06
#> 91              1e+06
#> 92              1e+06
#> 93              1e+06
#> 94              1e+06
#> 95              1e+06
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
#> 122             1e+00
#> 123             1e+00
#> 124             1e+00
#> 125             1e+00
#> 126             1e+00
#> 127             1e+00
#> 128             1e+00
#> 129             1e+00
#> 130             1e+00
#> 131             1e+00
#> 132             1e+00
#> 133             1e+06
#> 134             1e+06
#> 135             1e+06
#> 136             1e+06
#> 137             1e+06
#> 138             1e+00
#> 139             1e+00
#> 140             1e+00
#> 141             1e+00
#> 142             1e+00
#> 143             1e+00
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
#>                   PPORRESU              PPTESTCD               PPSTRESU
#> 1                 unitless             r.squared               unitless
#> 2                 unitless         adj.r.squared               unitless
#> 3                 unitless       lambda.z.corrxy               unitless
#> 4                 unitless        tobit_residual               unitless
#> 5                 unitless    adj_tobit_residual               unitless
#> 6                 fraction                     f               fraction
#> 7                 fraction                   ptr               fraction
#> 8                 fraction            span.ratio               fraction
#> 9                        %              deg.fluc                      %
#> 10                       %                 swing                      %
#> 11                       %        aucivpbextlast                      %
#> 12                       %         aucivpbextall                      %
#> 13                       %    aucivpbextint.last                      %
#> 14                       %     aucivpbextint.all                      %
#> 15                       %     aucivpbextinf.obs                      %
#> 16                       %    aucivpbextinf.pred                      %
#> 17                       %           aucpext.obs                      %
#> 18                       %          aucpext.pred                      %
#> 19                   count            count_conc                  count
#> 20                   count   count_conc_measured                  count
#> 21                   count         sparse_auc_df                  count
#> 22                   count        sparse_aumc_df                  count
#> 23                   count     lambda.z.n.points                  count
#> 24                   count lambda.z.n.points_blq                  count
#> 25                      hr                 start                     hr
#> 26                      hr                   end                     hr
#> 27                      hr                  tmax                     hr
#> 28                      hr                  tmin                     hr
#> 29                      hr                 tlast                     hr
#> 30                      hr                tfirst                     hr
#> 31                      hr              mrt.last                     hr
#> 32                      hr           mrt.iv.last                     hr
#> 33                      hr                  tlag                     hr
#> 34                      hr                ertlst                     hr
#> 35                      hr                ertmax                     hr
#> 36                      hr            time_above                     hr
#> 37                      hr             half.life                     hr
#> 38                      hr   lambda.z.time.first                     hr
#> 39                      hr    lambda.z.time.last                     hr
#> 40                      hr        thalf.eff.last                     hr
#> 41                      hr     thalf.eff.iv.last                     hr
#> 42                      hr       mrt.sparse.last                     hr
#> 43                      hr               mrt.obs                     hr
#> 44                      hr              mrt.pred                     hr
#> 45                      hr            mrt.iv.obs                     hr
#> 46                      hr           mrt.iv.pred                     hr
#> 47                      hr            mrt.md.obs                     hr
#> 48                      hr           mrt.md.pred                     hr
#> 49                      hr         thalf.eff.obs                     hr
#> 50                      hr        thalf.eff.pred                     hr
#> 51                      hr      thalf.eff.iv.obs                     hr
#> 52                      hr     thalf.eff.iv.pred                     hr
#> 53                    1/hr              lambda.z                   1/hr
#> 54                    1/hr              kel.last                   1/hr
#> 55                    1/hr           kel.iv.last                   1/hr
#> 56                    1/hr       kel.sparse.last                   1/hr
#> 57                    1/hr               kel.obs                   1/hr
#> 58                    1/hr              kel.pred                   1/hr
#> 59                    1/hr            kel.iv.obs                   1/hr
#> 60                    1/hr           kel.iv.pred                   1/hr
#> 61                    mg/L                    c0                 mmol/L
#> 62                    mg/L                  cmax                 mmol/L
#> 63                    mg/L                  cmin                 mmol/L
#> 64                    mg/L             clast.obs                 mmol/L
#> 65                    mg/L                   cav                 mmol/L
#> 66                    mg/L          cav.int.last                 mmol/L
#> 67                    mg/L           cav.int.all                 mmol/L
#> 68                    mg/L               ctrough                 mmol/L
#> 69                    mg/L                cstart                 mmol/L
#> 70                    mg/L                  ceoi                 mmol/L
#> 71                    mg/L            clast.pred                 mmol/L
#> 72                    mg/L       cav.int.inf.obs                 mmol/L
#> 73                    mg/L      cav.int.inf.pred                 mmol/L
#> 74                      mg                    ae                     mg
#> 75              mg/(mg/kg)                    fe             mg/(mg/kg)
#> 76                   mg/kg               totdose                  mg/kg
#> 77          (mg/L)/(mg/kg)               cmax.dn         (mg/L)/(mg/kg)
#> 78          (mg/L)/(mg/kg)               cmin.dn         (mg/L)/(mg/kg)
#> 79          (mg/L)/(mg/kg)          clast.obs.dn         (mg/L)/(mg/kg)
#> 80          (mg/L)/(mg/kg)         clast.pred.dn         (mg/L)/(mg/kg)
#> 81          (mg/L)/(mg/kg)                cav.dn         (mg/L)/(mg/kg)
#> 82          (mg/L)/(mg/kg)            ctrough.dn         (mg/L)/(mg/kg)
#> 83          (mg/kg)/(mg/L)              vss.last         (mg/kg)/(mg/L)
#> 84          (mg/kg)/(mg/L)           vss.iv.last         (mg/kg)/(mg/L)
#> 85          (mg/kg)/(mg/L)                 volpk         (mg/kg)/(mg/L)
#> 86          (mg/kg)/(mg/L)       vss.sparse.last         (mg/kg)/(mg/L)
#> 87          (mg/kg)/(mg/L)                vz.obs         (mg/kg)/(mg/L)
#> 88          (mg/kg)/(mg/L)               vz.pred         (mg/kg)/(mg/L)
#> 89          (mg/kg)/(mg/L)        vz.sparse.last         (mg/kg)/(mg/L)
#> 90          (mg/kg)/(mg/L)               vss.obs         (mg/kg)/(mg/L)
#> 91          (mg/kg)/(mg/L)              vss.pred         (mg/kg)/(mg/L)
#> 92          (mg/kg)/(mg/L)            vss.iv.obs         (mg/kg)/(mg/L)
#> 93          (mg/kg)/(mg/L)           vss.iv.pred         (mg/kg)/(mg/L)
#> 94          (mg/kg)/(mg/L)            vss.md.obs         (mg/kg)/(mg/L)
#> 95          (mg/kg)/(mg/L)           vss.md.pred         (mg/kg)/(mg/L)
#> 96                 hr*mg/L               auclast                hr*mg/L
#> 97                 hr*mg/L                aucall                hr*mg/L
#> 98                 hr*mg/L           aucint.last                hr*mg/L
#> 99                 hr*mg/L      aucint.last.dose                hr*mg/L
#> 100                hr*mg/L            aucint.all                hr*mg/L
#> 101                hr*mg/L       aucint.all.dose                hr*mg/L
#> 102                hr*mg/L  aucabove.predose.all                hr*mg/L
#> 103                hr*mg/L   aucabove.trough.all                hr*mg/L
#> 104                hr*mg/L        sparse_auclast                hr*mg/L
#> 105                hr*mg/L         sparse_auc_se                hr*mg/L
#> 106                hr*mg/L             aucivlast                hr*mg/L
#> 107                hr*mg/L              aucivall                hr*mg/L
#> 108                hr*mg/L         aucivint.last                hr*mg/L
#> 109                hr*mg/L          aucivint.all                hr*mg/L
#> 110                hr*mg/L            aucinf.obs                hr*mg/L
#> 111                hr*mg/L           aucinf.pred                hr*mg/L
#> 112                hr*mg/L        aucint.inf.obs                hr*mg/L
#> 113                hr*mg/L   aucint.inf.obs.dose                hr*mg/L
#> 114                hr*mg/L       aucint.inf.pred                hr*mg/L
#> 115                hr*mg/L  aucint.inf.pred.dose                hr*mg/L
#> 116                hr*mg/L          aucivinf.obs                hr*mg/L
#> 117                hr*mg/L         aucivinf.pred                hr*mg/L
#> 118              hr^2*mg/L              aumclast              hr^2*mg/L
#> 119              hr^2*mg/L               aumcall              hr^2*mg/L
#> 120              hr^2*mg/L       sparse_aumclast              hr^2*mg/L
#> 121              hr^2*mg/L        sparse_aumc_se              hr^2*mg/L
#> 122              hr^2*mg/L           aumcinf.obs              hr^2*mg/L
#> 123              hr^2*mg/L          aumcinf.pred              hr^2*mg/L
#> 124                  mg/hr                 ermax                  mg/hr
#> 125      (hr*mg/L)/(mg/kg)            auclast.dn      (hr*mg/L)/(mg/kg)
#> 126      (hr*mg/L)/(mg/kg)             aucall.dn      (hr*mg/L)/(mg/kg)
#> 127      (hr*mg/L)/(mg/kg)         aucinf.obs.dn      (hr*mg/L)/(mg/kg)
#> 128      (hr*mg/L)/(mg/kg)        aucinf.pred.dn      (hr*mg/L)/(mg/kg)
#> 129    (hr^2*mg/L)/(mg/kg)           aumclast.dn    (hr^2*mg/L)/(mg/kg)
#> 130    (hr^2*mg/L)/(mg/kg)            aumcall.dn    (hr^2*mg/L)/(mg/kg)
#> 131    (hr^2*mg/L)/(mg/kg)        aumcinf.obs.dn    (hr^2*mg/L)/(mg/kg)
#> 132    (hr^2*mg/L)/(mg/kg)       aumcinf.pred.dn    (hr^2*mg/L)/(mg/kg)
#> 133      (mg/kg)/(hr*mg/L)               cl.last      (mg/kg)/(hr*mg/L)
#> 134      (mg/kg)/(hr*mg/L)                cl.all      (mg/kg)/(hr*mg/L)
#> 135      (mg/kg)/(hr*mg/L)        cl.sparse.last      (mg/kg)/(hr*mg/L)
#> 136      (mg/kg)/(hr*mg/L)                cl.obs      (mg/kg)/(hr*mg/L)
#> 137      (mg/kg)/(hr*mg/L)               cl.pred      (mg/kg)/(hr*mg/L)
#> 138           mg/(hr*mg/L)              clr.last           mg/(hr*mg/L)
#> 139           mg/(hr*mg/L)               clr.obs           mg/(hr*mg/L)
#> 140           mg/(hr*mg/L)              clr.pred           mg/(hr*mg/L)
#> 141 (mg/(hr*mg/L))/(mg/kg)           clr.last.dn (mg/(hr*mg/L))/(mg/kg)
#> 142 (mg/(hr*mg/L))/(mg/kg)            clr.obs.dn (mg/(hr*mg/L))/(mg/kg)
#> 143 (mg/(hr*mg/L))/(mg/kg)           clr.pred.dn (mg/(hr*mg/L))/(mg/kg)
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
#> 54        1.000000000
#> 55        1.000000000
#> 56        1.000000000
#> 57        1.000000000
#> 58        1.000000000
#> 59        1.000000000
#> 60        1.000000000
#> 61        0.007240029
#> 62        0.007240029
#> 63        0.007240029
#> 64        0.007240029
#> 65        0.007240029
#> 66        0.007240029
#> 67        0.007240029
#> 68        0.007240029
#> 69        0.007240029
#> 70        0.007240029
#> 71        0.007240029
#> 72        0.007240029
#> 73        0.007240029
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
#> 132       1.000000000
#> 133       1.000000000
#> 134       1.000000000
#> 135       1.000000000
#> 136       1.000000000
#> 137       1.000000000
#> 138       1.000000000
#> 139       1.000000000
#> 140       1.000000000
#> 141       1.000000000
#> 142       1.000000000
#> 143       1.000000000

# This will make all time-related parameters use "day" even though the
# original units are "hr"
pknca_units_table(
  concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
  timeu_pref = "day"
)
#>                    PPORRESU              PPTESTCD                 PPSTRESU
#> 1                  unitless             r.squared                 unitless
#> 2                  unitless         adj.r.squared                 unitless
#> 3                  unitless       lambda.z.corrxy                 unitless
#> 4                  unitless        tobit_residual                 unitless
#> 5                  unitless    adj_tobit_residual                 unitless
#> 6                  fraction                     f                 fraction
#> 7                  fraction                   ptr                 fraction
#> 8                  fraction            span.ratio                 fraction
#> 9                         %              deg.fluc                        %
#> 10                        %                 swing                        %
#> 11                        %        aucivpbextlast                        %
#> 12                        %         aucivpbextall                        %
#> 13                        %    aucivpbextint.last                        %
#> 14                        %     aucivpbextint.all                        %
#> 15                        %     aucivpbextinf.obs                        %
#> 16                        %    aucivpbextinf.pred                        %
#> 17                        %           aucpext.obs                        %
#> 18                        %          aucpext.pred                        %
#> 19                    count            count_conc                    count
#> 20                    count   count_conc_measured                    count
#> 21                    count         sparse_auc_df                    count
#> 22                    count        sparse_aumc_df                    count
#> 23                    count     lambda.z.n.points                    count
#> 24                    count lambda.z.n.points_blq                    count
#> 25                       hr                 start                      day
#> 26                       hr                   end                      day
#> 27                       hr                  tmax                      day
#> 28                       hr                  tmin                      day
#> 29                       hr                 tlast                      day
#> 30                       hr                tfirst                      day
#> 31                       hr              mrt.last                      day
#> 32                       hr           mrt.iv.last                      day
#> 33                       hr                  tlag                      day
#> 34                       hr                ertlst                      day
#> 35                       hr                ertmax                      day
#> 36                       hr            time_above                      day
#> 37                       hr             half.life                      day
#> 38                       hr   lambda.z.time.first                      day
#> 39                       hr    lambda.z.time.last                      day
#> 40                       hr        thalf.eff.last                      day
#> 41                       hr     thalf.eff.iv.last                      day
#> 42                       hr       mrt.sparse.last                      day
#> 43                       hr               mrt.obs                      day
#> 44                       hr              mrt.pred                      day
#> 45                       hr            mrt.iv.obs                      day
#> 46                       hr           mrt.iv.pred                      day
#> 47                       hr            mrt.md.obs                      day
#> 48                       hr           mrt.md.pred                      day
#> 49                       hr         thalf.eff.obs                      day
#> 50                       hr        thalf.eff.pred                      day
#> 51                       hr      thalf.eff.iv.obs                      day
#> 52                       hr     thalf.eff.iv.pred                      day
#> 53                     1/hr              lambda.z                    1/day
#> 54                     1/hr              kel.last                    1/day
#> 55                     1/hr           kel.iv.last                    1/day
#> 56                     1/hr       kel.sparse.last                    1/day
#> 57                     1/hr               kel.obs                    1/day
#> 58                     1/hr              kel.pred                    1/day
#> 59                     1/hr            kel.iv.obs                    1/day
#> 60                     1/hr           kel.iv.pred                    1/day
#> 61                    ng/mL                    c0                    ng/mL
#> 62                    ng/mL                  cmax                    ng/mL
#> 63                    ng/mL                  cmin                    ng/mL
#> 64                    ng/mL             clast.obs                    ng/mL
#> 65                    ng/mL                   cav                    ng/mL
#> 66                    ng/mL          cav.int.last                    ng/mL
#> 67                    ng/mL           cav.int.all                    ng/mL
#> 68                    ng/mL               ctrough                    ng/mL
#> 69                    ng/mL                cstart                    ng/mL
#> 70                    ng/mL                  ceoi                    ng/mL
#> 71                    ng/mL            clast.pred                    ng/mL
#> 72                    ng/mL       cav.int.inf.obs                    ng/mL
#> 73                    ng/mL      cav.int.inf.pred                    ng/mL
#> 74                       mg                    ae                       mg
#> 75               mg/(mg/kg)                    fe               mg/(mg/kg)
#> 76                    mg/kg               totdose                    mg/kg
#> 77          (ng/mL)/(mg/kg)               cmax.dn          (ng/mL)/(mg/kg)
#> 78          (ng/mL)/(mg/kg)               cmin.dn          (ng/mL)/(mg/kg)
#> 79          (ng/mL)/(mg/kg)          clast.obs.dn          (ng/mL)/(mg/kg)
#> 80          (ng/mL)/(mg/kg)         clast.pred.dn          (ng/mL)/(mg/kg)
#> 81          (ng/mL)/(mg/kg)                cav.dn          (ng/mL)/(mg/kg)
#> 82          (ng/mL)/(mg/kg)            ctrough.dn          (ng/mL)/(mg/kg)
#> 83          (mg/kg)/(ng/mL)              vss.last          (mg/kg)/(ng/mL)
#> 84          (mg/kg)/(ng/mL)           vss.iv.last          (mg/kg)/(ng/mL)
#> 85          (mg/kg)/(ng/mL)                 volpk          (mg/kg)/(ng/mL)
#> 86          (mg/kg)/(ng/mL)       vss.sparse.last          (mg/kg)/(ng/mL)
#> 87          (mg/kg)/(ng/mL)                vz.obs          (mg/kg)/(ng/mL)
#> 88          (mg/kg)/(ng/mL)               vz.pred          (mg/kg)/(ng/mL)
#> 89          (mg/kg)/(ng/mL)        vz.sparse.last          (mg/kg)/(ng/mL)
#> 90          (mg/kg)/(ng/mL)               vss.obs          (mg/kg)/(ng/mL)
#> 91          (mg/kg)/(ng/mL)              vss.pred          (mg/kg)/(ng/mL)
#> 92          (mg/kg)/(ng/mL)            vss.iv.obs          (mg/kg)/(ng/mL)
#> 93          (mg/kg)/(ng/mL)           vss.iv.pred          (mg/kg)/(ng/mL)
#> 94          (mg/kg)/(ng/mL)            vss.md.obs          (mg/kg)/(ng/mL)
#> 95          (mg/kg)/(ng/mL)           vss.md.pred          (mg/kg)/(ng/mL)
#> 96                 hr*ng/mL               auclast                day*ng/mL
#> 97                 hr*ng/mL                aucall                day*ng/mL
#> 98                 hr*ng/mL           aucint.last                day*ng/mL
#> 99                 hr*ng/mL      aucint.last.dose                day*ng/mL
#> 100                hr*ng/mL            aucint.all                day*ng/mL
#> 101                hr*ng/mL       aucint.all.dose                day*ng/mL
#> 102                hr*ng/mL  aucabove.predose.all                day*ng/mL
#> 103                hr*ng/mL   aucabove.trough.all                day*ng/mL
#> 104                hr*ng/mL        sparse_auclast                day*ng/mL
#> 105                hr*ng/mL         sparse_auc_se                day*ng/mL
#> 106                hr*ng/mL             aucivlast                day*ng/mL
#> 107                hr*ng/mL              aucivall                day*ng/mL
#> 108                hr*ng/mL         aucivint.last                day*ng/mL
#> 109                hr*ng/mL          aucivint.all                day*ng/mL
#> 110                hr*ng/mL            aucinf.obs                day*ng/mL
#> 111                hr*ng/mL           aucinf.pred                day*ng/mL
#> 112                hr*ng/mL        aucint.inf.obs                day*ng/mL
#> 113                hr*ng/mL   aucint.inf.obs.dose                day*ng/mL
#> 114                hr*ng/mL       aucint.inf.pred                day*ng/mL
#> 115                hr*ng/mL  aucint.inf.pred.dose                day*ng/mL
#> 116                hr*ng/mL          aucivinf.obs                day*ng/mL
#> 117                hr*ng/mL         aucivinf.pred                day*ng/mL
#> 118              hr^2*ng/mL              aumclast              day^2*ng/mL
#> 119              hr^2*ng/mL               aumcall              day^2*ng/mL
#> 120              hr^2*ng/mL       sparse_aumclast              day^2*ng/mL
#> 121              hr^2*ng/mL        sparse_aumc_se              day^2*ng/mL
#> 122              hr^2*ng/mL           aumcinf.obs              day^2*ng/mL
#> 123              hr^2*ng/mL          aumcinf.pred              day^2*ng/mL
#> 124                   mg/hr                 ermax                   mg/day
#> 125      (hr*ng/mL)/(mg/kg)            auclast.dn      (day*ng/mL)/(mg/kg)
#> 126      (hr*ng/mL)/(mg/kg)             aucall.dn      (day*ng/mL)/(mg/kg)
#> 127      (hr*ng/mL)/(mg/kg)         aucinf.obs.dn      (day*ng/mL)/(mg/kg)
#> 128      (hr*ng/mL)/(mg/kg)        aucinf.pred.dn      (day*ng/mL)/(mg/kg)
#> 129    (hr^2*ng/mL)/(mg/kg)           aumclast.dn    (day^2*ng/mL)/(mg/kg)
#> 130    (hr^2*ng/mL)/(mg/kg)            aumcall.dn    (day^2*ng/mL)/(mg/kg)
#> 131    (hr^2*ng/mL)/(mg/kg)        aumcinf.obs.dn    (day^2*ng/mL)/(mg/kg)
#> 132    (hr^2*ng/mL)/(mg/kg)       aumcinf.pred.dn    (day^2*ng/mL)/(mg/kg)
#> 133      (mg/kg)/(hr*ng/mL)               cl.last      (mg/kg)/(day*ng/mL)
#> 134      (mg/kg)/(hr*ng/mL)                cl.all      (mg/kg)/(day*ng/mL)
#> 135      (mg/kg)/(hr*ng/mL)        cl.sparse.last      (mg/kg)/(day*ng/mL)
#> 136      (mg/kg)/(hr*ng/mL)                cl.obs      (mg/kg)/(day*ng/mL)
#> 137      (mg/kg)/(hr*ng/mL)               cl.pred      (mg/kg)/(day*ng/mL)
#> 138           mg/(hr*ng/mL)              clr.last           mg/(day*ng/mL)
#> 139           mg/(hr*ng/mL)               clr.obs           mg/(day*ng/mL)
#> 140           mg/(hr*ng/mL)              clr.pred           mg/(day*ng/mL)
#> 141 (mg/(hr*ng/mL))/(mg/kg)           clr.last.dn (mg/(day*ng/mL))/(mg/kg)
#> 142 (mg/(hr*ng/mL))/(mg/kg)            clr.obs.dn (mg/(day*ng/mL))/(mg/kg)
#> 143 (mg/(hr*ng/mL))/(mg/kg)           clr.pred.dn (mg/(day*ng/mL))/(mg/kg)
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
#> 47        0.041666667
#> 48        0.041666667
#> 49        0.041666667
#> 50        0.041666667
#> 51        0.041666667
#> 52        0.041666667
#> 53       24.000000000
#> 54       24.000000000
#> 55       24.000000000
#> 56       24.000000000
#> 57       24.000000000
#> 58       24.000000000
#> 59       24.000000000
#> 60       24.000000000
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
#> 87        1.000000000
#> 88        1.000000000
#> 89        1.000000000
#> 90        1.000000000
#> 91        1.000000000
#> 92        1.000000000
#> 93        1.000000000
#> 94        1.000000000
#> 95        1.000000000
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
#> 109       0.041666667
#> 110       0.041666667
#> 111       0.041666667
#> 112       0.041666667
#> 113       0.041666667
#> 114       0.041666667
#> 115       0.041666667
#> 116       0.041666667
#> 117       0.041666667
#> 118       0.001736111
#> 119       0.001736111
#> 120       0.001736111
#> 121       0.001736111
#> 122       0.001736111
#> 123       0.001736111
#> 124      24.000000000
#> 125       0.041666667
#> 126       0.041666667
#> 127       0.041666667
#> 128       0.041666667
#> 129       0.001736111
#> 130       0.001736111
#> 131       0.001736111
#> 132       0.001736111
#> 133      24.000000000
#> 134      24.000000000
#> 135      24.000000000
#> 136      24.000000000
#> 137      24.000000000
#> 138      24.000000000
#> 139      24.000000000
#> 140      24.000000000
#> 141      24.000000000
#> 142      24.000000000
#> 143      24.000000000
```
