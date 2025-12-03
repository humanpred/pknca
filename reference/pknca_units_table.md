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
#>     PPORRESU              PPTESTCD
#> 1   unitless             r.squared
#> 2   unitless         adj.r.squared
#> 3   unitless       lambda.z.corrxy
#> 4   fraction                     f
#> 5   fraction                   ptr
#> 6   fraction            span.ratio
#> 7          %              deg.fluc
#> 8          %                 swing
#> 9          %        aucivpbextlast
#> 10         %         aucivpbextall
#> 11         %    aucivpbextint.last
#> 12         %     aucivpbextint.all
#> 13         %     aucivpbextinf.obs
#> 14         %    aucivpbextinf.pred
#> 15         %           aucpext.obs
#> 16         %          aucpext.pred
#> 17     count            count_conc
#> 18     count   count_conc_measured
#> 19     count         sparse_auc_df
#> 20     count        sparse_aumc_df
#> 21     count     lambda.z.n.points
#> 22      <NA>                 start
#> 23      <NA>                   end
#> 24      <NA>                  tmax
#> 25      <NA>                 tlast
#> 26      <NA>                tfirst
#> 27      <NA>              mrt.last
#> 28      <NA>               mrt.all
#> 29      <NA>           mrt.int.all
#> 30      <NA>          mrt.int.last
#> 31      <NA>           mrt.iv.last
#> 32      <NA>                  tlag
#> 33      <NA>                ertlst
#> 34      <NA>                ertmax
#> 35      <NA>            time_above
#> 36      <NA>             half.life
#> 37      <NA>   lambda.z.time.first
#> 38      <NA>    lambda.z.time.last
#> 39      <NA>        thalf.eff.last
#> 40      <NA>     thalf.eff.iv.last
#> 41      <NA>       mrt.sparse.last
#> 42      <NA>            mrt.iv.all
#> 43      <NA>         mrt.ivint.all
#> 44      <NA>        mrt.ivint.last
#> 45      <NA>               mrt.obs
#> 46      <NA>              mrt.pred
#> 47      <NA>       mrt.int.inf.obs
#> 48      <NA>      mrt.int.inf.pred
#> 49      <NA>            mrt.iv.obs
#> 50      <NA>           mrt.iv.pred
#> 51      <NA>            mrt.md.obs
#> 52      <NA>           mrt.md.pred
#> 53      <NA>         thalf.eff.obs
#> 54      <NA>        thalf.eff.pred
#> 55      <NA>      thalf.eff.iv.obs
#> 56      <NA>     thalf.eff.iv.pred
#> 57      <NA>              lambda.z
#> 58      <NA>              kel.last
#> 59      <NA>           kel.iv.last
#> 60      <NA>               kel.all
#> 61      <NA>           kel.int.all
#> 62      <NA>          kel.int.last
#> 63      <NA>            kel.iv.all
#> 64      <NA>         kel.ivint.all
#> 65      <NA>        kel.ivint.last
#> 66      <NA>       kel.sparse.last
#> 67      <NA>               kel.obs
#> 68      <NA>              kel.pred
#> 69      <NA>            kel.iv.obs
#> 70      <NA>           kel.iv.pred
#> 71      <NA>       kel.int.inf.obs
#> 72      <NA>      kel.int.inf.pred
#> 73      <NA>                    c0
#> 74      <NA>                  cmax
#> 75      <NA>                  cmin
#> 76      <NA>             clast.obs
#> 77      <NA>                   cav
#> 78      <NA>          cav.int.last
#> 79      <NA>           cav.int.all
#> 80      <NA>               ctrough
#> 81      <NA>                cstart
#> 82      <NA>                  ceoi
#> 83      <NA>            clast.pred
#> 84      <NA>       cav.int.inf.obs
#> 85      <NA>      cav.int.inf.pred
#> 86      <NA>                    ae
#> 87      <NA>                    fe
#> 88      <NA>               totdose
#> 89      <NA>               cmax.dn
#> 90      <NA>               cmin.dn
#> 91      <NA>          clast.obs.dn
#> 92      <NA>         clast.pred.dn
#> 93      <NA>                cav.dn
#> 94      <NA>            ctrough.dn
#> 95      <NA>              vss.last
#> 96      <NA>           vss.iv.last
#> 97      <NA>               vss.all
#> 98      <NA>           vss.int.all
#> 99      <NA>          vss.int.last
#> 100     <NA>                 volpk
#> 101     <NA>                vz.all
#> 102     <NA>            vz.int.all
#> 103     <NA>           vz.int.last
#> 104     <NA>             vz.iv.all
#> 105     <NA>            vz.iv.last
#> 106     <NA>          vz.ivint.all
#> 107     <NA>         vz.ivint.last
#> 108     <NA>               vz.last
#> 109     <NA>        vz.sparse.last
#> 110     <NA>            vss.iv.all
#> 111     <NA>         vss.ivint.all
#> 112     <NA>        vss.ivint.last
#> 113     <NA>       vss.sparse.last
#> 114     <NA>                vz.obs
#> 115     <NA>               vz.pred
#> 116     <NA>        vz.int.inf.obs
#> 117     <NA>       vz.int.inf.pred
#> 118     <NA>             vz.iv.obs
#> 119     <NA>            vz.iv.pred
#> 120     <NA>               vss.obs
#> 121     <NA>              vss.pred
#> 122     <NA>            vss.iv.obs
#> 123     <NA>           vss.iv.pred
#> 124     <NA>            vss.md.obs
#> 125     <NA>           vss.md.pred
#> 126     <NA>       vss.int.inf.obs
#> 127     <NA>      vss.int.inf.pred
#> 128     <NA>               auclast
#> 129     <NA>                aucall
#> 130     <NA>           aucint.last
#> 131     <NA>      aucint.last.dose
#> 132     <NA>            aucint.all
#> 133     <NA>       aucint.all.dose
#> 134     <NA>  aucabove.predose.all
#> 135     <NA>   aucabove.trough.all
#> 136     <NA>        sparse_auclast
#> 137     <NA>         sparse_auc_se
#> 138     <NA>             aucivlast
#> 139     <NA>              aucivall
#> 140     <NA>         aucivint.last
#> 141     <NA>          aucivint.all
#> 142     <NA>            aucinf.obs
#> 143     <NA>           aucinf.pred
#> 144     <NA>        aucint.inf.obs
#> 145     <NA>   aucint.inf.obs.dose
#> 146     <NA>       aucint.inf.pred
#> 147     <NA>  aucint.inf.pred.dose
#> 148     <NA>          aucivinf.obs
#> 149     <NA>         aucivinf.pred
#> 150     <NA>              aumclast
#> 151     <NA>               aumcall
#> 152     <NA>          aumcint.last
#> 153     <NA>     aumcint.last.dose
#> 154     <NA>           aumcint.all
#> 155     <NA>      aumcint.all.dose
#> 156     <NA>       sparse_aumclast
#> 157     <NA>        sparse_aumc_se
#> 158     <NA>            aumcivlast
#> 159     <NA>             aumcivall
#> 160     <NA>        aumcivint.last
#> 161     <NA>         aumcivint.all
#> 162     <NA>           aumcinf.obs
#> 163     <NA>          aumcinf.pred
#> 164     <NA>       aumcint.inf.obs
#> 165     <NA>  aumcint.inf.obs.dose
#> 166     <NA>      aumcint.inf.pred
#> 167     <NA> aumcint.inf.pred.dose
#> 168     <NA>         aumcivinf.obs
#> 169     <NA>        aumcivinf.pred
#> 170     <NA>                 ermax
#> 171     <NA>            auclast.dn
#> 172     <NA>             aucall.dn
#> 173     <NA>         aucinf.obs.dn
#> 174     <NA>        aucinf.pred.dn
#> 175     <NA>           aumclast.dn
#> 176     <NA>            aumcall.dn
#> 177     <NA>        aumcinf.obs.dn
#> 178     <NA>       aumcinf.pred.dn
#> 179     <NA>               cl.last
#> 180     <NA>                cl.all
#> 181     <NA>            cl.int.all
#> 182     <NA>           cl.int.last
#> 183     <NA>             cl.iv.all
#> 184     <NA>            cl.iv.last
#> 185     <NA>          cl.ivint.all
#> 186     <NA>         cl.ivint.last
#> 187     <NA>        cl.sparse.last
#> 188     <NA>                cl.obs
#> 189     <NA>               cl.pred
#> 190     <NA>        cl.int.inf.obs
#> 191     <NA>       cl.int.inf.pred
#> 192     <NA>             cl.iv.obs
#> 193     <NA>            cl.iv.pred
#> 194     <NA>              clr.last
#> 195     <NA>               clr.obs
#> 196     <NA>              clr.pred
#> 197     <NA>           clr.last.dn
#> 198     <NA>            clr.obs.dn
#> 199     <NA>           clr.pred.dn
pknca_units_table(
  concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr"
)
#>                    PPORRESU              PPTESTCD
#> 1                  unitless             r.squared
#> 2                  unitless         adj.r.squared
#> 3                  unitless       lambda.z.corrxy
#> 4                  fraction                     f
#> 5                  fraction                   ptr
#> 6                  fraction            span.ratio
#> 7                         %              deg.fluc
#> 8                         %                 swing
#> 9                         %        aucivpbextlast
#> 10                        %         aucivpbextall
#> 11                        %    aucivpbextint.last
#> 12                        %     aucivpbextint.all
#> 13                        %     aucivpbextinf.obs
#> 14                        %    aucivpbextinf.pred
#> 15                        %           aucpext.obs
#> 16                        %          aucpext.pred
#> 17                    count            count_conc
#> 18                    count   count_conc_measured
#> 19                    count         sparse_auc_df
#> 20                    count        sparse_aumc_df
#> 21                    count     lambda.z.n.points
#> 22                       hr                 start
#> 23                       hr                   end
#> 24                       hr                  tmax
#> 25                       hr                 tlast
#> 26                       hr                tfirst
#> 27                       hr              mrt.last
#> 28                       hr               mrt.all
#> 29                       hr           mrt.int.all
#> 30                       hr          mrt.int.last
#> 31                       hr           mrt.iv.last
#> 32                       hr                  tlag
#> 33                       hr                ertlst
#> 34                       hr                ertmax
#> 35                       hr            time_above
#> 36                       hr             half.life
#> 37                       hr   lambda.z.time.first
#> 38                       hr    lambda.z.time.last
#> 39                       hr        thalf.eff.last
#> 40                       hr     thalf.eff.iv.last
#> 41                       hr       mrt.sparse.last
#> 42                       hr            mrt.iv.all
#> 43                       hr         mrt.ivint.all
#> 44                       hr        mrt.ivint.last
#> 45                       hr               mrt.obs
#> 46                       hr              mrt.pred
#> 47                       hr       mrt.int.inf.obs
#> 48                       hr      mrt.int.inf.pred
#> 49                       hr            mrt.iv.obs
#> 50                       hr           mrt.iv.pred
#> 51                       hr            mrt.md.obs
#> 52                       hr           mrt.md.pred
#> 53                       hr         thalf.eff.obs
#> 54                       hr        thalf.eff.pred
#> 55                       hr      thalf.eff.iv.obs
#> 56                       hr     thalf.eff.iv.pred
#> 57                     1/hr              lambda.z
#> 58                     1/hr              kel.last
#> 59                     1/hr           kel.iv.last
#> 60                     1/hr               kel.all
#> 61                     1/hr           kel.int.all
#> 62                     1/hr          kel.int.last
#> 63                     1/hr            kel.iv.all
#> 64                     1/hr         kel.ivint.all
#> 65                     1/hr        kel.ivint.last
#> 66                     1/hr       kel.sparse.last
#> 67                     1/hr               kel.obs
#> 68                     1/hr              kel.pred
#> 69                     1/hr            kel.iv.obs
#> 70                     1/hr           kel.iv.pred
#> 71                     1/hr       kel.int.inf.obs
#> 72                     1/hr      kel.int.inf.pred
#> 73                    ng/mL                    c0
#> 74                    ng/mL                  cmax
#> 75                    ng/mL                  cmin
#> 76                    ng/mL             clast.obs
#> 77                    ng/mL                   cav
#> 78                    ng/mL          cav.int.last
#> 79                    ng/mL           cav.int.all
#> 80                    ng/mL               ctrough
#> 81                    ng/mL                cstart
#> 82                    ng/mL                  ceoi
#> 83                    ng/mL            clast.pred
#> 84                    ng/mL       cav.int.inf.obs
#> 85                    ng/mL      cav.int.inf.pred
#> 86                       mg                    ae
#> 87               mg/(mg/kg)                    fe
#> 88                    mg/kg               totdose
#> 89          (ng/mL)/(mg/kg)               cmax.dn
#> 90          (ng/mL)/(mg/kg)               cmin.dn
#> 91          (ng/mL)/(mg/kg)          clast.obs.dn
#> 92          (ng/mL)/(mg/kg)         clast.pred.dn
#> 93          (ng/mL)/(mg/kg)                cav.dn
#> 94          (ng/mL)/(mg/kg)            ctrough.dn
#> 95          (mg/kg)/(ng/mL)              vss.last
#> 96          (mg/kg)/(ng/mL)           vss.iv.last
#> 97          (mg/kg)/(ng/mL)               vss.all
#> 98          (mg/kg)/(ng/mL)           vss.int.all
#> 99          (mg/kg)/(ng/mL)          vss.int.last
#> 100         (mg/kg)/(ng/mL)                 volpk
#> 101         (mg/kg)/(ng/mL)                vz.all
#> 102         (mg/kg)/(ng/mL)            vz.int.all
#> 103         (mg/kg)/(ng/mL)           vz.int.last
#> 104         (mg/kg)/(ng/mL)             vz.iv.all
#> 105         (mg/kg)/(ng/mL)            vz.iv.last
#> 106         (mg/kg)/(ng/mL)          vz.ivint.all
#> 107         (mg/kg)/(ng/mL)         vz.ivint.last
#> 108         (mg/kg)/(ng/mL)               vz.last
#> 109         (mg/kg)/(ng/mL)        vz.sparse.last
#> 110         (mg/kg)/(ng/mL)            vss.iv.all
#> 111         (mg/kg)/(ng/mL)         vss.ivint.all
#> 112         (mg/kg)/(ng/mL)        vss.ivint.last
#> 113         (mg/kg)/(ng/mL)       vss.sparse.last
#> 114         (mg/kg)/(ng/mL)                vz.obs
#> 115         (mg/kg)/(ng/mL)               vz.pred
#> 116         (mg/kg)/(ng/mL)        vz.int.inf.obs
#> 117         (mg/kg)/(ng/mL)       vz.int.inf.pred
#> 118         (mg/kg)/(ng/mL)             vz.iv.obs
#> 119         (mg/kg)/(ng/mL)            vz.iv.pred
#> 120         (mg/kg)/(ng/mL)               vss.obs
#> 121         (mg/kg)/(ng/mL)              vss.pred
#> 122         (mg/kg)/(ng/mL)            vss.iv.obs
#> 123         (mg/kg)/(ng/mL)           vss.iv.pred
#> 124         (mg/kg)/(ng/mL)            vss.md.obs
#> 125         (mg/kg)/(ng/mL)           vss.md.pred
#> 126         (mg/kg)/(ng/mL)       vss.int.inf.obs
#> 127         (mg/kg)/(ng/mL)      vss.int.inf.pred
#> 128                hr*ng/mL               auclast
#> 129                hr*ng/mL                aucall
#> 130                hr*ng/mL           aucint.last
#> 131                hr*ng/mL      aucint.last.dose
#> 132                hr*ng/mL            aucint.all
#> 133                hr*ng/mL       aucint.all.dose
#> 134                hr*ng/mL  aucabove.predose.all
#> 135                hr*ng/mL   aucabove.trough.all
#> 136                hr*ng/mL        sparse_auclast
#> 137                hr*ng/mL         sparse_auc_se
#> 138                hr*ng/mL             aucivlast
#> 139                hr*ng/mL              aucivall
#> 140                hr*ng/mL         aucivint.last
#> 141                hr*ng/mL          aucivint.all
#> 142                hr*ng/mL            aucinf.obs
#> 143                hr*ng/mL           aucinf.pred
#> 144                hr*ng/mL        aucint.inf.obs
#> 145                hr*ng/mL   aucint.inf.obs.dose
#> 146                hr*ng/mL       aucint.inf.pred
#> 147                hr*ng/mL  aucint.inf.pred.dose
#> 148                hr*ng/mL          aucivinf.obs
#> 149                hr*ng/mL         aucivinf.pred
#> 150              hr^2*ng/mL              aumclast
#> 151              hr^2*ng/mL               aumcall
#> 152              hr^2*ng/mL          aumcint.last
#> 153              hr^2*ng/mL     aumcint.last.dose
#> 154              hr^2*ng/mL           aumcint.all
#> 155              hr^2*ng/mL      aumcint.all.dose
#> 156              hr^2*ng/mL       sparse_aumclast
#> 157              hr^2*ng/mL        sparse_aumc_se
#> 158              hr^2*ng/mL            aumcivlast
#> 159              hr^2*ng/mL             aumcivall
#> 160              hr^2*ng/mL        aumcivint.last
#> 161              hr^2*ng/mL         aumcivint.all
#> 162              hr^2*ng/mL           aumcinf.obs
#> 163              hr^2*ng/mL          aumcinf.pred
#> 164              hr^2*ng/mL       aumcint.inf.obs
#> 165              hr^2*ng/mL  aumcint.inf.obs.dose
#> 166              hr^2*ng/mL      aumcint.inf.pred
#> 167              hr^2*ng/mL aumcint.inf.pred.dose
#> 168              hr^2*ng/mL         aumcivinf.obs
#> 169              hr^2*ng/mL        aumcivinf.pred
#> 170                   hr*mg                 ermax
#> 171      (hr*ng/mL)/(mg/kg)            auclast.dn
#> 172      (hr*ng/mL)/(mg/kg)             aucall.dn
#> 173      (hr*ng/mL)/(mg/kg)         aucinf.obs.dn
#> 174      (hr*ng/mL)/(mg/kg)        aucinf.pred.dn
#> 175    (hr^2*ng/mL)/(mg/kg)           aumclast.dn
#> 176    (hr^2*ng/mL)/(mg/kg)            aumcall.dn
#> 177    (hr^2*ng/mL)/(mg/kg)        aumcinf.obs.dn
#> 178    (hr^2*ng/mL)/(mg/kg)       aumcinf.pred.dn
#> 179      (mg/kg)/(hr*ng/mL)               cl.last
#> 180      (mg/kg)/(hr*ng/mL)                cl.all
#> 181      (mg/kg)/(hr*ng/mL)            cl.int.all
#> 182      (mg/kg)/(hr*ng/mL)           cl.int.last
#> 183      (mg/kg)/(hr*ng/mL)             cl.iv.all
#> 184      (mg/kg)/(hr*ng/mL)            cl.iv.last
#> 185      (mg/kg)/(hr*ng/mL)          cl.ivint.all
#> 186      (mg/kg)/(hr*ng/mL)         cl.ivint.last
#> 187      (mg/kg)/(hr*ng/mL)        cl.sparse.last
#> 188      (mg/kg)/(hr*ng/mL)                cl.obs
#> 189      (mg/kg)/(hr*ng/mL)               cl.pred
#> 190      (mg/kg)/(hr*ng/mL)        cl.int.inf.obs
#> 191      (mg/kg)/(hr*ng/mL)       cl.int.inf.pred
#> 192      (mg/kg)/(hr*ng/mL)             cl.iv.obs
#> 193      (mg/kg)/(hr*ng/mL)            cl.iv.pred
#> 194           mg/(hr*ng/mL)              clr.last
#> 195           mg/(hr*ng/mL)               clr.obs
#> 196           mg/(hr*ng/mL)              clr.pred
#> 197 (mg/(hr*ng/mL))/(mg/kg)           clr.last.dn
#> 198 (mg/(hr*ng/mL))/(mg/kg)            clr.obs.dn
#> 199 (mg/(hr*ng/mL))/(mg/kg)           clr.pred.dn
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
#> 4                  fraction                     f                fraction
#> 5                  fraction                   ptr                fraction
#> 6                  fraction            span.ratio                fraction
#> 7                         %              deg.fluc                       %
#> 8                         %                 swing                       %
#> 9                         %        aucivpbextlast                       %
#> 10                        %         aucivpbextall                       %
#> 11                        %    aucivpbextint.last                       %
#> 12                        %     aucivpbextint.all                       %
#> 13                        %     aucivpbextinf.obs                       %
#> 14                        %    aucivpbextinf.pred                       %
#> 15                        %           aucpext.obs                       %
#> 16                        %          aucpext.pred                       %
#> 17                    count            count_conc                   count
#> 18                    count   count_conc_measured                   count
#> 19                    count         sparse_auc_df                   count
#> 20                    count        sparse_aumc_df                   count
#> 21                    count     lambda.z.n.points                   count
#> 22                       hr                 start                      hr
#> 23                       hr                   end                      hr
#> 24                       hr                  tmax                      hr
#> 25                       hr                 tlast                      hr
#> 26                       hr                tfirst                      hr
#> 27                       hr              mrt.last                      hr
#> 28                       hr               mrt.all                      hr
#> 29                       hr           mrt.int.all                      hr
#> 30                       hr          mrt.int.last                      hr
#> 31                       hr           mrt.iv.last                      hr
#> 32                       hr                  tlag                      hr
#> 33                       hr                ertlst                      hr
#> 34                       hr                ertmax                      hr
#> 35                       hr            time_above                      hr
#> 36                       hr             half.life                      hr
#> 37                       hr   lambda.z.time.first                      hr
#> 38                       hr    lambda.z.time.last                      hr
#> 39                       hr        thalf.eff.last                      hr
#> 40                       hr     thalf.eff.iv.last                      hr
#> 41                       hr       mrt.sparse.last                      hr
#> 42                       hr            mrt.iv.all                      hr
#> 43                       hr         mrt.ivint.all                      hr
#> 44                       hr        mrt.ivint.last                      hr
#> 45                       hr               mrt.obs                      hr
#> 46                       hr              mrt.pred                      hr
#> 47                       hr       mrt.int.inf.obs                      hr
#> 48                       hr      mrt.int.inf.pred                      hr
#> 49                       hr            mrt.iv.obs                      hr
#> 50                       hr           mrt.iv.pred                      hr
#> 51                       hr            mrt.md.obs                      hr
#> 52                       hr           mrt.md.pred                      hr
#> 53                       hr         thalf.eff.obs                      hr
#> 54                       hr        thalf.eff.pred                      hr
#> 55                       hr      thalf.eff.iv.obs                      hr
#> 56                       hr     thalf.eff.iv.pred                      hr
#> 57                     1/hr              lambda.z                    1/hr
#> 58                     1/hr              kel.last                    1/hr
#> 59                     1/hr           kel.iv.last                    1/hr
#> 60                     1/hr               kel.all                    1/hr
#> 61                     1/hr           kel.int.all                    1/hr
#> 62                     1/hr          kel.int.last                    1/hr
#> 63                     1/hr            kel.iv.all                    1/hr
#> 64                     1/hr         kel.ivint.all                    1/hr
#> 65                     1/hr        kel.ivint.last                    1/hr
#> 66                     1/hr       kel.sparse.last                    1/hr
#> 67                     1/hr               kel.obs                    1/hr
#> 68                     1/hr              kel.pred                    1/hr
#> 69                     1/hr            kel.iv.obs                    1/hr
#> 70                     1/hr           kel.iv.pred                    1/hr
#> 71                     1/hr       kel.int.inf.obs                    1/hr
#> 72                     1/hr      kel.int.inf.pred                    1/hr
#> 73                    ng/mL                    c0                   ng/mL
#> 74                    ng/mL                  cmax                   ng/mL
#> 75                    ng/mL                  cmin                   ng/mL
#> 76                    ng/mL             clast.obs                   ng/mL
#> 77                    ng/mL                   cav                   ng/mL
#> 78                    ng/mL          cav.int.last                   ng/mL
#> 79                    ng/mL           cav.int.all                   ng/mL
#> 80                    ng/mL               ctrough                   ng/mL
#> 81                    ng/mL                cstart                   ng/mL
#> 82                    ng/mL                  ceoi                   ng/mL
#> 83                    ng/mL            clast.pred                   ng/mL
#> 84                    ng/mL       cav.int.inf.obs                   ng/mL
#> 85                    ng/mL      cav.int.inf.pred                   ng/mL
#> 86                       mg                    ae                      mg
#> 87               mg/(mg/kg)                    fe              mg/(mg/kg)
#> 88                    mg/kg               totdose                   mg/kg
#> 89          (ng/mL)/(mg/kg)               cmax.dn         (ng/mL)/(mg/kg)
#> 90          (ng/mL)/(mg/kg)               cmin.dn         (ng/mL)/(mg/kg)
#> 91          (ng/mL)/(mg/kg)          clast.obs.dn         (ng/mL)/(mg/kg)
#> 92          (ng/mL)/(mg/kg)         clast.pred.dn         (ng/mL)/(mg/kg)
#> 93          (ng/mL)/(mg/kg)                cav.dn         (ng/mL)/(mg/kg)
#> 94          (ng/mL)/(mg/kg)            ctrough.dn         (ng/mL)/(mg/kg)
#> 95          (mg/kg)/(ng/mL)              vss.last                   mL/kg
#> 96          (mg/kg)/(ng/mL)           vss.iv.last                   mL/kg
#> 97          (mg/kg)/(ng/mL)               vss.all                   mL/kg
#> 98          (mg/kg)/(ng/mL)           vss.int.all                   mL/kg
#> 99          (mg/kg)/(ng/mL)          vss.int.last                   mL/kg
#> 100         (mg/kg)/(ng/mL)                 volpk                   mL/kg
#> 101         (mg/kg)/(ng/mL)                vz.all                   mL/kg
#> 102         (mg/kg)/(ng/mL)            vz.int.all                   mL/kg
#> 103         (mg/kg)/(ng/mL)           vz.int.last                   mL/kg
#> 104         (mg/kg)/(ng/mL)             vz.iv.all                   mL/kg
#> 105         (mg/kg)/(ng/mL)            vz.iv.last                   mL/kg
#> 106         (mg/kg)/(ng/mL)          vz.ivint.all                   mL/kg
#> 107         (mg/kg)/(ng/mL)         vz.ivint.last                   mL/kg
#> 108         (mg/kg)/(ng/mL)               vz.last                   mL/kg
#> 109         (mg/kg)/(ng/mL)        vz.sparse.last                   mL/kg
#> 110         (mg/kg)/(ng/mL)            vss.iv.all                   mL/kg
#> 111         (mg/kg)/(ng/mL)         vss.ivint.all                   mL/kg
#> 112         (mg/kg)/(ng/mL)        vss.ivint.last                   mL/kg
#> 113         (mg/kg)/(ng/mL)       vss.sparse.last                   mL/kg
#> 114         (mg/kg)/(ng/mL)                vz.obs                   mL/kg
#> 115         (mg/kg)/(ng/mL)               vz.pred                   mL/kg
#> 116         (mg/kg)/(ng/mL)        vz.int.inf.obs                   mL/kg
#> 117         (mg/kg)/(ng/mL)       vz.int.inf.pred                   mL/kg
#> 118         (mg/kg)/(ng/mL)             vz.iv.obs                   mL/kg
#> 119         (mg/kg)/(ng/mL)            vz.iv.pred                   mL/kg
#> 120         (mg/kg)/(ng/mL)               vss.obs                   mL/kg
#> 121         (mg/kg)/(ng/mL)              vss.pred                   mL/kg
#> 122         (mg/kg)/(ng/mL)            vss.iv.obs                   mL/kg
#> 123         (mg/kg)/(ng/mL)           vss.iv.pred                   mL/kg
#> 124         (mg/kg)/(ng/mL)            vss.md.obs                   mL/kg
#> 125         (mg/kg)/(ng/mL)           vss.md.pred                   mL/kg
#> 126         (mg/kg)/(ng/mL)       vss.int.inf.obs                   mL/kg
#> 127         (mg/kg)/(ng/mL)      vss.int.inf.pred                   mL/kg
#> 128                hr*ng/mL               auclast                hr*ng/mL
#> 129                hr*ng/mL                aucall                hr*ng/mL
#> 130                hr*ng/mL           aucint.last                hr*ng/mL
#> 131                hr*ng/mL      aucint.last.dose                hr*ng/mL
#> 132                hr*ng/mL            aucint.all                hr*ng/mL
#> 133                hr*ng/mL       aucint.all.dose                hr*ng/mL
#> 134                hr*ng/mL  aucabove.predose.all                hr*ng/mL
#> 135                hr*ng/mL   aucabove.trough.all                hr*ng/mL
#> 136                hr*ng/mL        sparse_auclast                hr*ng/mL
#> 137                hr*ng/mL         sparse_auc_se                hr*ng/mL
#> 138                hr*ng/mL             aucivlast                hr*ng/mL
#> 139                hr*ng/mL              aucivall                hr*ng/mL
#> 140                hr*ng/mL         aucivint.last                hr*ng/mL
#> 141                hr*ng/mL          aucivint.all                hr*ng/mL
#> 142                hr*ng/mL            aucinf.obs                hr*ng/mL
#> 143                hr*ng/mL           aucinf.pred                hr*ng/mL
#> 144                hr*ng/mL        aucint.inf.obs                hr*ng/mL
#> 145                hr*ng/mL   aucint.inf.obs.dose                hr*ng/mL
#> 146                hr*ng/mL       aucint.inf.pred                hr*ng/mL
#> 147                hr*ng/mL  aucint.inf.pred.dose                hr*ng/mL
#> 148                hr*ng/mL          aucivinf.obs                hr*ng/mL
#> 149                hr*ng/mL         aucivinf.pred                hr*ng/mL
#> 150              hr^2*ng/mL              aumclast              hr^2*ng/mL
#> 151              hr^2*ng/mL               aumcall              hr^2*ng/mL
#> 152              hr^2*ng/mL          aumcint.last              hr^2*ng/mL
#> 153              hr^2*ng/mL     aumcint.last.dose              hr^2*ng/mL
#> 154              hr^2*ng/mL           aumcint.all              hr^2*ng/mL
#> 155              hr^2*ng/mL      aumcint.all.dose              hr^2*ng/mL
#> 156              hr^2*ng/mL       sparse_aumclast              hr^2*ng/mL
#> 157              hr^2*ng/mL        sparse_aumc_se              hr^2*ng/mL
#> 158              hr^2*ng/mL            aumcivlast              hr^2*ng/mL
#> 159              hr^2*ng/mL             aumcivall              hr^2*ng/mL
#> 160              hr^2*ng/mL        aumcivint.last              hr^2*ng/mL
#> 161              hr^2*ng/mL         aumcivint.all              hr^2*ng/mL
#> 162              hr^2*ng/mL           aumcinf.obs              hr^2*ng/mL
#> 163              hr^2*ng/mL          aumcinf.pred              hr^2*ng/mL
#> 164              hr^2*ng/mL       aumcint.inf.obs              hr^2*ng/mL
#> 165              hr^2*ng/mL  aumcint.inf.obs.dose              hr^2*ng/mL
#> 166              hr^2*ng/mL      aumcint.inf.pred              hr^2*ng/mL
#> 167              hr^2*ng/mL aumcint.inf.pred.dose              hr^2*ng/mL
#> 168              hr^2*ng/mL         aumcivinf.obs              hr^2*ng/mL
#> 169              hr^2*ng/mL        aumcivinf.pred              hr^2*ng/mL
#> 170                   hr*mg                 ermax                   hr*mg
#> 171      (hr*ng/mL)/(mg/kg)            auclast.dn      (hr*ng/mL)/(mg/kg)
#> 172      (hr*ng/mL)/(mg/kg)             aucall.dn      (hr*ng/mL)/(mg/kg)
#> 173      (hr*ng/mL)/(mg/kg)         aucinf.obs.dn      (hr*ng/mL)/(mg/kg)
#> 174      (hr*ng/mL)/(mg/kg)        aucinf.pred.dn      (hr*ng/mL)/(mg/kg)
#> 175    (hr^2*ng/mL)/(mg/kg)           aumclast.dn    (hr^2*ng/mL)/(mg/kg)
#> 176    (hr^2*ng/mL)/(mg/kg)            aumcall.dn    (hr^2*ng/mL)/(mg/kg)
#> 177    (hr^2*ng/mL)/(mg/kg)        aumcinf.obs.dn    (hr^2*ng/mL)/(mg/kg)
#> 178    (hr^2*ng/mL)/(mg/kg)       aumcinf.pred.dn    (hr^2*ng/mL)/(mg/kg)
#> 179      (mg/kg)/(hr*ng/mL)               cl.last                mL/hr/kg
#> 180      (mg/kg)/(hr*ng/mL)                cl.all                mL/hr/kg
#> 181      (mg/kg)/(hr*ng/mL)            cl.int.all                mL/hr/kg
#> 182      (mg/kg)/(hr*ng/mL)           cl.int.last                mL/hr/kg
#> 183      (mg/kg)/(hr*ng/mL)             cl.iv.all                mL/hr/kg
#> 184      (mg/kg)/(hr*ng/mL)            cl.iv.last                mL/hr/kg
#> 185      (mg/kg)/(hr*ng/mL)          cl.ivint.all                mL/hr/kg
#> 186      (mg/kg)/(hr*ng/mL)         cl.ivint.last                mL/hr/kg
#> 187      (mg/kg)/(hr*ng/mL)        cl.sparse.last                mL/hr/kg
#> 188      (mg/kg)/(hr*ng/mL)                cl.obs                mL/hr/kg
#> 189      (mg/kg)/(hr*ng/mL)               cl.pred                mL/hr/kg
#> 190      (mg/kg)/(hr*ng/mL)        cl.int.inf.obs                mL/hr/kg
#> 191      (mg/kg)/(hr*ng/mL)       cl.int.inf.pred                mL/hr/kg
#> 192      (mg/kg)/(hr*ng/mL)             cl.iv.obs                mL/hr/kg
#> 193      (mg/kg)/(hr*ng/mL)            cl.iv.pred                mL/hr/kg
#> 194           mg/(hr*ng/mL)              clr.last           mg/(hr*ng/mL)
#> 195           mg/(hr*ng/mL)               clr.obs           mg/(hr*ng/mL)
#> 196           mg/(hr*ng/mL)              clr.pred           mg/(hr*ng/mL)
#> 197 (mg/(hr*ng/mL))/(mg/kg)           clr.last.dn (mg/(hr*ng/mL))/(mg/kg)
#> 198 (mg/(hr*ng/mL))/(mg/kg)            clr.obs.dn (mg/(hr*ng/mL))/(mg/kg)
#> 199 (mg/(hr*ng/mL))/(mg/kg)           clr.pred.dn (mg/(hr*ng/mL))/(mg/kg)
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
#> 83              1e+00
#> 84              1e+00
#> 85              1e+00
#> 86              1e+00
#> 87              1e+00
#> 88              1e+00
#> 89              1e+00
#> 90              1e+00
#> 91              1e+00
#> 92              1e+00
#> 93              1e+00
#> 94              1e+00
#> 95              1e+06
#> 96              1e+06
#> 97              1e+06
#> 98              1e+06
#> 99              1e+06
#> 100             1e+06
#> 101             1e+06
#> 102             1e+06
#> 103             1e+06
#> 104             1e+06
#> 105             1e+06
#> 106             1e+06
#> 107             1e+06
#> 108             1e+06
#> 109             1e+06
#> 110             1e+06
#> 111             1e+06
#> 112             1e+06
#> 113             1e+06
#> 114             1e+06
#> 115             1e+06
#> 116             1e+06
#> 117             1e+06
#> 118             1e+06
#> 119             1e+06
#> 120             1e+06
#> 121             1e+06
#> 122             1e+06
#> 123             1e+06
#> 124             1e+06
#> 125             1e+06
#> 126             1e+06
#> 127             1e+06
#> 128             1e+00
#> 129             1e+00
#> 130             1e+00
#> 131             1e+00
#> 132             1e+00
#> 133             1e+00
#> 134             1e+00
#> 135             1e+00
#> 136             1e+00
#> 137             1e+00
#> 138             1e+00
#> 139             1e+00
#> 140             1e+00
#> 141             1e+00
#> 142             1e+00
#> 143             1e+00
#> 144             1e+00
#> 145             1e+00
#> 146             1e+00
#> 147             1e+00
#> 148             1e+00
#> 149             1e+00
#> 150             1e+00
#> 151             1e+00
#> 152             1e+00
#> 153             1e+00
#> 154             1e+00
#> 155             1e+00
#> 156             1e+00
#> 157             1e+00
#> 158             1e+00
#> 159             1e+00
#> 160             1e+00
#> 161             1e+00
#> 162             1e+00
#> 163             1e+00
#> 164             1e+00
#> 165             1e+00
#> 166             1e+00
#> 167             1e+00
#> 168             1e+00
#> 169             1e+00
#> 170             1e+00
#> 171             1e+00
#> 172             1e+00
#> 173             1e+00
#> 174             1e+00
#> 175             1e+00
#> 176             1e+00
#> 177             1e+00
#> 178             1e+00
#> 179             1e+06
#> 180             1e+06
#> 181             1e+06
#> 182             1e+06
#> 183             1e+06
#> 184             1e+06
#> 185             1e+06
#> 186             1e+06
#> 187             1e+06
#> 188             1e+06
#> 189             1e+06
#> 190             1e+06
#> 191             1e+06
#> 192             1e+06
#> 193             1e+06
#> 194             1e+00
#> 195             1e+00
#> 196             1e+00
#> 197             1e+00
#> 198             1e+00
#> 199             1e+00
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
#> 4                 fraction                     f               fraction
#> 5                 fraction                   ptr               fraction
#> 6                 fraction            span.ratio               fraction
#> 7                        %              deg.fluc                      %
#> 8                        %                 swing                      %
#> 9                        %        aucivpbextlast                      %
#> 10                       %         aucivpbextall                      %
#> 11                       %    aucivpbextint.last                      %
#> 12                       %     aucivpbextint.all                      %
#> 13                       %     aucivpbextinf.obs                      %
#> 14                       %    aucivpbextinf.pred                      %
#> 15                       %           aucpext.obs                      %
#> 16                       %          aucpext.pred                      %
#> 17                   count            count_conc                  count
#> 18                   count   count_conc_measured                  count
#> 19                   count         sparse_auc_df                  count
#> 20                   count        sparse_aumc_df                  count
#> 21                   count     lambda.z.n.points                  count
#> 22                      hr                 start                     hr
#> 23                      hr                   end                     hr
#> 24                      hr                  tmax                     hr
#> 25                      hr                 tlast                     hr
#> 26                      hr                tfirst                     hr
#> 27                      hr              mrt.last                     hr
#> 28                      hr               mrt.all                     hr
#> 29                      hr           mrt.int.all                     hr
#> 30                      hr          mrt.int.last                     hr
#> 31                      hr           mrt.iv.last                     hr
#> 32                      hr                  tlag                     hr
#> 33                      hr                ertlst                     hr
#> 34                      hr                ertmax                     hr
#> 35                      hr            time_above                     hr
#> 36                      hr             half.life                     hr
#> 37                      hr   lambda.z.time.first                     hr
#> 38                      hr    lambda.z.time.last                     hr
#> 39                      hr        thalf.eff.last                     hr
#> 40                      hr     thalf.eff.iv.last                     hr
#> 41                      hr       mrt.sparse.last                     hr
#> 42                      hr            mrt.iv.all                     hr
#> 43                      hr         mrt.ivint.all                     hr
#> 44                      hr        mrt.ivint.last                     hr
#> 45                      hr               mrt.obs                     hr
#> 46                      hr              mrt.pred                     hr
#> 47                      hr       mrt.int.inf.obs                     hr
#> 48                      hr      mrt.int.inf.pred                     hr
#> 49                      hr            mrt.iv.obs                     hr
#> 50                      hr           mrt.iv.pred                     hr
#> 51                      hr            mrt.md.obs                     hr
#> 52                      hr           mrt.md.pred                     hr
#> 53                      hr         thalf.eff.obs                     hr
#> 54                      hr        thalf.eff.pred                     hr
#> 55                      hr      thalf.eff.iv.obs                     hr
#> 56                      hr     thalf.eff.iv.pred                     hr
#> 57                    1/hr              lambda.z                   1/hr
#> 58                    1/hr              kel.last                   1/hr
#> 59                    1/hr           kel.iv.last                   1/hr
#> 60                    1/hr               kel.all                   1/hr
#> 61                    1/hr           kel.int.all                   1/hr
#> 62                    1/hr          kel.int.last                   1/hr
#> 63                    1/hr            kel.iv.all                   1/hr
#> 64                    1/hr         kel.ivint.all                   1/hr
#> 65                    1/hr        kel.ivint.last                   1/hr
#> 66                    1/hr       kel.sparse.last                   1/hr
#> 67                    1/hr               kel.obs                   1/hr
#> 68                    1/hr              kel.pred                   1/hr
#> 69                    1/hr            kel.iv.obs                   1/hr
#> 70                    1/hr           kel.iv.pred                   1/hr
#> 71                    1/hr       kel.int.inf.obs                   1/hr
#> 72                    1/hr      kel.int.inf.pred                   1/hr
#> 73                    mg/L                    c0                 mmol/L
#> 74                    mg/L                  cmax                 mmol/L
#> 75                    mg/L                  cmin                 mmol/L
#> 76                    mg/L             clast.obs                 mmol/L
#> 77                    mg/L                   cav                 mmol/L
#> 78                    mg/L          cav.int.last                 mmol/L
#> 79                    mg/L           cav.int.all                 mmol/L
#> 80                    mg/L               ctrough                 mmol/L
#> 81                    mg/L                cstart                 mmol/L
#> 82                    mg/L                  ceoi                 mmol/L
#> 83                    mg/L            clast.pred                 mmol/L
#> 84                    mg/L       cav.int.inf.obs                 mmol/L
#> 85                    mg/L      cav.int.inf.pred                 mmol/L
#> 86                      mg                    ae                     mg
#> 87              mg/(mg/kg)                    fe             mg/(mg/kg)
#> 88                   mg/kg               totdose                  mg/kg
#> 89          (mg/L)/(mg/kg)               cmax.dn         (mg/L)/(mg/kg)
#> 90          (mg/L)/(mg/kg)               cmin.dn         (mg/L)/(mg/kg)
#> 91          (mg/L)/(mg/kg)          clast.obs.dn         (mg/L)/(mg/kg)
#> 92          (mg/L)/(mg/kg)         clast.pred.dn         (mg/L)/(mg/kg)
#> 93          (mg/L)/(mg/kg)                cav.dn         (mg/L)/(mg/kg)
#> 94          (mg/L)/(mg/kg)            ctrough.dn         (mg/L)/(mg/kg)
#> 95          (mg/kg)/(mg/L)              vss.last         (mg/kg)/(mg/L)
#> 96          (mg/kg)/(mg/L)           vss.iv.last         (mg/kg)/(mg/L)
#> 97          (mg/kg)/(mg/L)               vss.all         (mg/kg)/(mg/L)
#> 98          (mg/kg)/(mg/L)           vss.int.all         (mg/kg)/(mg/L)
#> 99          (mg/kg)/(mg/L)          vss.int.last         (mg/kg)/(mg/L)
#> 100         (mg/kg)/(mg/L)                 volpk         (mg/kg)/(mg/L)
#> 101         (mg/kg)/(mg/L)                vz.all         (mg/kg)/(mg/L)
#> 102         (mg/kg)/(mg/L)            vz.int.all         (mg/kg)/(mg/L)
#> 103         (mg/kg)/(mg/L)           vz.int.last         (mg/kg)/(mg/L)
#> 104         (mg/kg)/(mg/L)             vz.iv.all         (mg/kg)/(mg/L)
#> 105         (mg/kg)/(mg/L)            vz.iv.last         (mg/kg)/(mg/L)
#> 106         (mg/kg)/(mg/L)          vz.ivint.all         (mg/kg)/(mg/L)
#> 107         (mg/kg)/(mg/L)         vz.ivint.last         (mg/kg)/(mg/L)
#> 108         (mg/kg)/(mg/L)               vz.last         (mg/kg)/(mg/L)
#> 109         (mg/kg)/(mg/L)        vz.sparse.last         (mg/kg)/(mg/L)
#> 110         (mg/kg)/(mg/L)            vss.iv.all         (mg/kg)/(mg/L)
#> 111         (mg/kg)/(mg/L)         vss.ivint.all         (mg/kg)/(mg/L)
#> 112         (mg/kg)/(mg/L)        vss.ivint.last         (mg/kg)/(mg/L)
#> 113         (mg/kg)/(mg/L)       vss.sparse.last         (mg/kg)/(mg/L)
#> 114         (mg/kg)/(mg/L)                vz.obs         (mg/kg)/(mg/L)
#> 115         (mg/kg)/(mg/L)               vz.pred         (mg/kg)/(mg/L)
#> 116         (mg/kg)/(mg/L)        vz.int.inf.obs         (mg/kg)/(mg/L)
#> 117         (mg/kg)/(mg/L)       vz.int.inf.pred         (mg/kg)/(mg/L)
#> 118         (mg/kg)/(mg/L)             vz.iv.obs         (mg/kg)/(mg/L)
#> 119         (mg/kg)/(mg/L)            vz.iv.pred         (mg/kg)/(mg/L)
#> 120         (mg/kg)/(mg/L)               vss.obs         (mg/kg)/(mg/L)
#> 121         (mg/kg)/(mg/L)              vss.pred         (mg/kg)/(mg/L)
#> 122         (mg/kg)/(mg/L)            vss.iv.obs         (mg/kg)/(mg/L)
#> 123         (mg/kg)/(mg/L)           vss.iv.pred         (mg/kg)/(mg/L)
#> 124         (mg/kg)/(mg/L)            vss.md.obs         (mg/kg)/(mg/L)
#> 125         (mg/kg)/(mg/L)           vss.md.pred         (mg/kg)/(mg/L)
#> 126         (mg/kg)/(mg/L)       vss.int.inf.obs         (mg/kg)/(mg/L)
#> 127         (mg/kg)/(mg/L)      vss.int.inf.pred         (mg/kg)/(mg/L)
#> 128                hr*mg/L               auclast                hr*mg/L
#> 129                hr*mg/L                aucall                hr*mg/L
#> 130                hr*mg/L           aucint.last                hr*mg/L
#> 131                hr*mg/L      aucint.last.dose                hr*mg/L
#> 132                hr*mg/L            aucint.all                hr*mg/L
#> 133                hr*mg/L       aucint.all.dose                hr*mg/L
#> 134                hr*mg/L  aucabove.predose.all                hr*mg/L
#> 135                hr*mg/L   aucabove.trough.all                hr*mg/L
#> 136                hr*mg/L        sparse_auclast                hr*mg/L
#> 137                hr*mg/L         sparse_auc_se                hr*mg/L
#> 138                hr*mg/L             aucivlast                hr*mg/L
#> 139                hr*mg/L              aucivall                hr*mg/L
#> 140                hr*mg/L         aucivint.last                hr*mg/L
#> 141                hr*mg/L          aucivint.all                hr*mg/L
#> 142                hr*mg/L            aucinf.obs                hr*mg/L
#> 143                hr*mg/L           aucinf.pred                hr*mg/L
#> 144                hr*mg/L        aucint.inf.obs                hr*mg/L
#> 145                hr*mg/L   aucint.inf.obs.dose                hr*mg/L
#> 146                hr*mg/L       aucint.inf.pred                hr*mg/L
#> 147                hr*mg/L  aucint.inf.pred.dose                hr*mg/L
#> 148                hr*mg/L          aucivinf.obs                hr*mg/L
#> 149                hr*mg/L         aucivinf.pred                hr*mg/L
#> 150              hr^2*mg/L              aumclast              hr^2*mg/L
#> 151              hr^2*mg/L               aumcall              hr^2*mg/L
#> 152              hr^2*mg/L          aumcint.last              hr^2*mg/L
#> 153              hr^2*mg/L     aumcint.last.dose              hr^2*mg/L
#> 154              hr^2*mg/L           aumcint.all              hr^2*mg/L
#> 155              hr^2*mg/L      aumcint.all.dose              hr^2*mg/L
#> 156              hr^2*mg/L       sparse_aumclast              hr^2*mg/L
#> 157              hr^2*mg/L        sparse_aumc_se              hr^2*mg/L
#> 158              hr^2*mg/L            aumcivlast              hr^2*mg/L
#> 159              hr^2*mg/L             aumcivall              hr^2*mg/L
#> 160              hr^2*mg/L        aumcivint.last              hr^2*mg/L
#> 161              hr^2*mg/L         aumcivint.all              hr^2*mg/L
#> 162              hr^2*mg/L           aumcinf.obs              hr^2*mg/L
#> 163              hr^2*mg/L          aumcinf.pred              hr^2*mg/L
#> 164              hr^2*mg/L       aumcint.inf.obs              hr^2*mg/L
#> 165              hr^2*mg/L  aumcint.inf.obs.dose              hr^2*mg/L
#> 166              hr^2*mg/L      aumcint.inf.pred              hr^2*mg/L
#> 167              hr^2*mg/L aumcint.inf.pred.dose              hr^2*mg/L
#> 168              hr^2*mg/L         aumcivinf.obs              hr^2*mg/L
#> 169              hr^2*mg/L        aumcivinf.pred              hr^2*mg/L
#> 170                  hr*mg                 ermax                  hr*mg
#> 171      (hr*mg/L)/(mg/kg)            auclast.dn      (hr*mg/L)/(mg/kg)
#> 172      (hr*mg/L)/(mg/kg)             aucall.dn      (hr*mg/L)/(mg/kg)
#> 173      (hr*mg/L)/(mg/kg)         aucinf.obs.dn      (hr*mg/L)/(mg/kg)
#> 174      (hr*mg/L)/(mg/kg)        aucinf.pred.dn      (hr*mg/L)/(mg/kg)
#> 175    (hr^2*mg/L)/(mg/kg)           aumclast.dn    (hr^2*mg/L)/(mg/kg)
#> 176    (hr^2*mg/L)/(mg/kg)            aumcall.dn    (hr^2*mg/L)/(mg/kg)
#> 177    (hr^2*mg/L)/(mg/kg)        aumcinf.obs.dn    (hr^2*mg/L)/(mg/kg)
#> 178    (hr^2*mg/L)/(mg/kg)       aumcinf.pred.dn    (hr^2*mg/L)/(mg/kg)
#> 179      (mg/kg)/(hr*mg/L)               cl.last      (mg/kg)/(hr*mg/L)
#> 180      (mg/kg)/(hr*mg/L)                cl.all      (mg/kg)/(hr*mg/L)
#> 181      (mg/kg)/(hr*mg/L)            cl.int.all      (mg/kg)/(hr*mg/L)
#> 182      (mg/kg)/(hr*mg/L)           cl.int.last      (mg/kg)/(hr*mg/L)
#> 183      (mg/kg)/(hr*mg/L)             cl.iv.all      (mg/kg)/(hr*mg/L)
#> 184      (mg/kg)/(hr*mg/L)            cl.iv.last      (mg/kg)/(hr*mg/L)
#> 185      (mg/kg)/(hr*mg/L)          cl.ivint.all      (mg/kg)/(hr*mg/L)
#> 186      (mg/kg)/(hr*mg/L)         cl.ivint.last      (mg/kg)/(hr*mg/L)
#> 187      (mg/kg)/(hr*mg/L)        cl.sparse.last      (mg/kg)/(hr*mg/L)
#> 188      (mg/kg)/(hr*mg/L)                cl.obs      (mg/kg)/(hr*mg/L)
#> 189      (mg/kg)/(hr*mg/L)               cl.pred      (mg/kg)/(hr*mg/L)
#> 190      (mg/kg)/(hr*mg/L)        cl.int.inf.obs      (mg/kg)/(hr*mg/L)
#> 191      (mg/kg)/(hr*mg/L)       cl.int.inf.pred      (mg/kg)/(hr*mg/L)
#> 192      (mg/kg)/(hr*mg/L)             cl.iv.obs      (mg/kg)/(hr*mg/L)
#> 193      (mg/kg)/(hr*mg/L)            cl.iv.pred      (mg/kg)/(hr*mg/L)
#> 194           mg/(hr*mg/L)              clr.last           mg/(hr*mg/L)
#> 195           mg/(hr*mg/L)               clr.obs           mg/(hr*mg/L)
#> 196           mg/(hr*mg/L)              clr.pred           mg/(hr*mg/L)
#> 197 (mg/(hr*mg/L))/(mg/kg)           clr.last.dn (mg/(hr*mg/L))/(mg/kg)
#> 198 (mg/(hr*mg/L))/(mg/kg)            clr.obs.dn (mg/(hr*mg/L))/(mg/kg)
#> 199 (mg/(hr*mg/L))/(mg/kg)           clr.pred.dn (mg/(hr*mg/L))/(mg/kg)
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
#> 73        0.007240029
#> 74        0.007240029
#> 75        0.007240029
#> 76        0.007240029
#> 77        0.007240029
#> 78        0.007240029
#> 79        0.007240029
#> 80        0.007240029
#> 81        0.007240029
#> 82        0.007240029
#> 83        0.007240029
#> 84        0.007240029
#> 85        0.007240029
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
#> 144       1.000000000
#> 145       1.000000000
#> 146       1.000000000
#> 147       1.000000000
#> 148       1.000000000
#> 149       1.000000000
#> 150       1.000000000
#> 151       1.000000000
#> 152       1.000000000
#> 153       1.000000000
#> 154       1.000000000
#> 155       1.000000000
#> 156       1.000000000
#> 157       1.000000000
#> 158       1.000000000
#> 159       1.000000000
#> 160       1.000000000
#> 161       1.000000000
#> 162       1.000000000
#> 163       1.000000000
#> 164       1.000000000
#> 165       1.000000000
#> 166       1.000000000
#> 167       1.000000000
#> 168       1.000000000
#> 169       1.000000000
#> 170       1.000000000
#> 171       1.000000000
#> 172       1.000000000
#> 173       1.000000000
#> 174       1.000000000
#> 175       1.000000000
#> 176       1.000000000
#> 177       1.000000000
#> 178       1.000000000
#> 179       1.000000000
#> 180       1.000000000
#> 181       1.000000000
#> 182       1.000000000
#> 183       1.000000000
#> 184       1.000000000
#> 185       1.000000000
#> 186       1.000000000
#> 187       1.000000000
#> 188       1.000000000
#> 189       1.000000000
#> 190       1.000000000
#> 191       1.000000000
#> 192       1.000000000
#> 193       1.000000000
#> 194       1.000000000
#> 195       1.000000000
#> 196       1.000000000
#> 197       1.000000000
#> 198       1.000000000
#> 199       1.000000000

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
#> 4                  fraction                     f                 fraction
#> 5                  fraction                   ptr                 fraction
#> 6                  fraction            span.ratio                 fraction
#> 7                         %              deg.fluc                        %
#> 8                         %                 swing                        %
#> 9                         %        aucivpbextlast                        %
#> 10                        %         aucivpbextall                        %
#> 11                        %    aucivpbextint.last                        %
#> 12                        %     aucivpbextint.all                        %
#> 13                        %     aucivpbextinf.obs                        %
#> 14                        %    aucivpbextinf.pred                        %
#> 15                        %           aucpext.obs                        %
#> 16                        %          aucpext.pred                        %
#> 17                    count            count_conc                    count
#> 18                    count   count_conc_measured                    count
#> 19                    count         sparse_auc_df                    count
#> 20                    count        sparse_aumc_df                    count
#> 21                    count     lambda.z.n.points                    count
#> 22                       hr                 start                      day
#> 23                       hr                   end                      day
#> 24                       hr                  tmax                      day
#> 25                       hr                 tlast                      day
#> 26                       hr                tfirst                      day
#> 27                       hr              mrt.last                      day
#> 28                       hr               mrt.all                      day
#> 29                       hr           mrt.int.all                      day
#> 30                       hr          mrt.int.last                      day
#> 31                       hr           mrt.iv.last                      day
#> 32                       hr                  tlag                      day
#> 33                       hr                ertlst                      day
#> 34                       hr                ertmax                      day
#> 35                       hr            time_above                      day
#> 36                       hr             half.life                      day
#> 37                       hr   lambda.z.time.first                      day
#> 38                       hr    lambda.z.time.last                      day
#> 39                       hr        thalf.eff.last                      day
#> 40                       hr     thalf.eff.iv.last                      day
#> 41                       hr       mrt.sparse.last                      day
#> 42                       hr            mrt.iv.all                      day
#> 43                       hr         mrt.ivint.all                      day
#> 44                       hr        mrt.ivint.last                      day
#> 45                       hr               mrt.obs                      day
#> 46                       hr              mrt.pred                      day
#> 47                       hr       mrt.int.inf.obs                      day
#> 48                       hr      mrt.int.inf.pred                      day
#> 49                       hr            mrt.iv.obs                      day
#> 50                       hr           mrt.iv.pred                      day
#> 51                       hr            mrt.md.obs                      day
#> 52                       hr           mrt.md.pred                      day
#> 53                       hr         thalf.eff.obs                      day
#> 54                       hr        thalf.eff.pred                      day
#> 55                       hr      thalf.eff.iv.obs                      day
#> 56                       hr     thalf.eff.iv.pred                      day
#> 57                     1/hr              lambda.z                    1/day
#> 58                     1/hr              kel.last                    1/day
#> 59                     1/hr           kel.iv.last                    1/day
#> 60                     1/hr               kel.all                    1/day
#> 61                     1/hr           kel.int.all                    1/day
#> 62                     1/hr          kel.int.last                    1/day
#> 63                     1/hr            kel.iv.all                    1/day
#> 64                     1/hr         kel.ivint.all                    1/day
#> 65                     1/hr        kel.ivint.last                    1/day
#> 66                     1/hr       kel.sparse.last                    1/day
#> 67                     1/hr               kel.obs                    1/day
#> 68                     1/hr              kel.pred                    1/day
#> 69                     1/hr            kel.iv.obs                    1/day
#> 70                     1/hr           kel.iv.pred                    1/day
#> 71                     1/hr       kel.int.inf.obs                    1/day
#> 72                     1/hr      kel.int.inf.pred                    1/day
#> 73                    ng/mL                    c0                    ng/mL
#> 74                    ng/mL                  cmax                    ng/mL
#> 75                    ng/mL                  cmin                    ng/mL
#> 76                    ng/mL             clast.obs                    ng/mL
#> 77                    ng/mL                   cav                    ng/mL
#> 78                    ng/mL          cav.int.last                    ng/mL
#> 79                    ng/mL           cav.int.all                    ng/mL
#> 80                    ng/mL               ctrough                    ng/mL
#> 81                    ng/mL                cstart                    ng/mL
#> 82                    ng/mL                  ceoi                    ng/mL
#> 83                    ng/mL            clast.pred                    ng/mL
#> 84                    ng/mL       cav.int.inf.obs                    ng/mL
#> 85                    ng/mL      cav.int.inf.pred                    ng/mL
#> 86                       mg                    ae                       mg
#> 87               mg/(mg/kg)                    fe               mg/(mg/kg)
#> 88                    mg/kg               totdose                    mg/kg
#> 89          (ng/mL)/(mg/kg)               cmax.dn          (ng/mL)/(mg/kg)
#> 90          (ng/mL)/(mg/kg)               cmin.dn          (ng/mL)/(mg/kg)
#> 91          (ng/mL)/(mg/kg)          clast.obs.dn          (ng/mL)/(mg/kg)
#> 92          (ng/mL)/(mg/kg)         clast.pred.dn          (ng/mL)/(mg/kg)
#> 93          (ng/mL)/(mg/kg)                cav.dn          (ng/mL)/(mg/kg)
#> 94          (ng/mL)/(mg/kg)            ctrough.dn          (ng/mL)/(mg/kg)
#> 95          (mg/kg)/(ng/mL)              vss.last          (mg/kg)/(ng/mL)
#> 96          (mg/kg)/(ng/mL)           vss.iv.last          (mg/kg)/(ng/mL)
#> 97          (mg/kg)/(ng/mL)               vss.all          (mg/kg)/(ng/mL)
#> 98          (mg/kg)/(ng/mL)           vss.int.all          (mg/kg)/(ng/mL)
#> 99          (mg/kg)/(ng/mL)          vss.int.last          (mg/kg)/(ng/mL)
#> 100         (mg/kg)/(ng/mL)                 volpk          (mg/kg)/(ng/mL)
#> 101         (mg/kg)/(ng/mL)                vz.all          (mg/kg)/(ng/mL)
#> 102         (mg/kg)/(ng/mL)            vz.int.all          (mg/kg)/(ng/mL)
#> 103         (mg/kg)/(ng/mL)           vz.int.last          (mg/kg)/(ng/mL)
#> 104         (mg/kg)/(ng/mL)             vz.iv.all          (mg/kg)/(ng/mL)
#> 105         (mg/kg)/(ng/mL)            vz.iv.last          (mg/kg)/(ng/mL)
#> 106         (mg/kg)/(ng/mL)          vz.ivint.all          (mg/kg)/(ng/mL)
#> 107         (mg/kg)/(ng/mL)         vz.ivint.last          (mg/kg)/(ng/mL)
#> 108         (mg/kg)/(ng/mL)               vz.last          (mg/kg)/(ng/mL)
#> 109         (mg/kg)/(ng/mL)        vz.sparse.last          (mg/kg)/(ng/mL)
#> 110         (mg/kg)/(ng/mL)            vss.iv.all          (mg/kg)/(ng/mL)
#> 111         (mg/kg)/(ng/mL)         vss.ivint.all          (mg/kg)/(ng/mL)
#> 112         (mg/kg)/(ng/mL)        vss.ivint.last          (mg/kg)/(ng/mL)
#> 113         (mg/kg)/(ng/mL)       vss.sparse.last          (mg/kg)/(ng/mL)
#> 114         (mg/kg)/(ng/mL)                vz.obs          (mg/kg)/(ng/mL)
#> 115         (mg/kg)/(ng/mL)               vz.pred          (mg/kg)/(ng/mL)
#> 116         (mg/kg)/(ng/mL)        vz.int.inf.obs          (mg/kg)/(ng/mL)
#> 117         (mg/kg)/(ng/mL)       vz.int.inf.pred          (mg/kg)/(ng/mL)
#> 118         (mg/kg)/(ng/mL)             vz.iv.obs          (mg/kg)/(ng/mL)
#> 119         (mg/kg)/(ng/mL)            vz.iv.pred          (mg/kg)/(ng/mL)
#> 120         (mg/kg)/(ng/mL)               vss.obs          (mg/kg)/(ng/mL)
#> 121         (mg/kg)/(ng/mL)              vss.pred          (mg/kg)/(ng/mL)
#> 122         (mg/kg)/(ng/mL)            vss.iv.obs          (mg/kg)/(ng/mL)
#> 123         (mg/kg)/(ng/mL)           vss.iv.pred          (mg/kg)/(ng/mL)
#> 124         (mg/kg)/(ng/mL)            vss.md.obs          (mg/kg)/(ng/mL)
#> 125         (mg/kg)/(ng/mL)           vss.md.pred          (mg/kg)/(ng/mL)
#> 126         (mg/kg)/(ng/mL)       vss.int.inf.obs          (mg/kg)/(ng/mL)
#> 127         (mg/kg)/(ng/mL)      vss.int.inf.pred          (mg/kg)/(ng/mL)
#> 128                hr*ng/mL               auclast                day*ng/mL
#> 129                hr*ng/mL                aucall                day*ng/mL
#> 130                hr*ng/mL           aucint.last                day*ng/mL
#> 131                hr*ng/mL      aucint.last.dose                day*ng/mL
#> 132                hr*ng/mL            aucint.all                day*ng/mL
#> 133                hr*ng/mL       aucint.all.dose                day*ng/mL
#> 134                hr*ng/mL  aucabove.predose.all                day*ng/mL
#> 135                hr*ng/mL   aucabove.trough.all                day*ng/mL
#> 136                hr*ng/mL        sparse_auclast                day*ng/mL
#> 137                hr*ng/mL         sparse_auc_se                day*ng/mL
#> 138                hr*ng/mL             aucivlast                day*ng/mL
#> 139                hr*ng/mL              aucivall                day*ng/mL
#> 140                hr*ng/mL         aucivint.last                day*ng/mL
#> 141                hr*ng/mL          aucivint.all                day*ng/mL
#> 142                hr*ng/mL            aucinf.obs                day*ng/mL
#> 143                hr*ng/mL           aucinf.pred                day*ng/mL
#> 144                hr*ng/mL        aucint.inf.obs                day*ng/mL
#> 145                hr*ng/mL   aucint.inf.obs.dose                day*ng/mL
#> 146                hr*ng/mL       aucint.inf.pred                day*ng/mL
#> 147                hr*ng/mL  aucint.inf.pred.dose                day*ng/mL
#> 148                hr*ng/mL          aucivinf.obs                day*ng/mL
#> 149                hr*ng/mL         aucivinf.pred                day*ng/mL
#> 150              hr^2*ng/mL              aumclast              day^2*ng/mL
#> 151              hr^2*ng/mL               aumcall              day^2*ng/mL
#> 152              hr^2*ng/mL          aumcint.last              day^2*ng/mL
#> 153              hr^2*ng/mL     aumcint.last.dose              day^2*ng/mL
#> 154              hr^2*ng/mL           aumcint.all              day^2*ng/mL
#> 155              hr^2*ng/mL      aumcint.all.dose              day^2*ng/mL
#> 156              hr^2*ng/mL       sparse_aumclast              day^2*ng/mL
#> 157              hr^2*ng/mL        sparse_aumc_se              day^2*ng/mL
#> 158              hr^2*ng/mL            aumcivlast              day^2*ng/mL
#> 159              hr^2*ng/mL             aumcivall              day^2*ng/mL
#> 160              hr^2*ng/mL        aumcivint.last              day^2*ng/mL
#> 161              hr^2*ng/mL         aumcivint.all              day^2*ng/mL
#> 162              hr^2*ng/mL           aumcinf.obs              day^2*ng/mL
#> 163              hr^2*ng/mL          aumcinf.pred              day^2*ng/mL
#> 164              hr^2*ng/mL       aumcint.inf.obs              day^2*ng/mL
#> 165              hr^2*ng/mL  aumcint.inf.obs.dose              day^2*ng/mL
#> 166              hr^2*ng/mL      aumcint.inf.pred              day^2*ng/mL
#> 167              hr^2*ng/mL aumcint.inf.pred.dose              day^2*ng/mL
#> 168              hr^2*ng/mL         aumcivinf.obs              day^2*ng/mL
#> 169              hr^2*ng/mL        aumcivinf.pred              day^2*ng/mL
#> 170                   hr*mg                 ermax                   day*mg
#> 171      (hr*ng/mL)/(mg/kg)            auclast.dn      (day*ng/mL)/(mg/kg)
#> 172      (hr*ng/mL)/(mg/kg)             aucall.dn      (day*ng/mL)/(mg/kg)
#> 173      (hr*ng/mL)/(mg/kg)         aucinf.obs.dn      (day*ng/mL)/(mg/kg)
#> 174      (hr*ng/mL)/(mg/kg)        aucinf.pred.dn      (day*ng/mL)/(mg/kg)
#> 175    (hr^2*ng/mL)/(mg/kg)           aumclast.dn    (day^2*ng/mL)/(mg/kg)
#> 176    (hr^2*ng/mL)/(mg/kg)            aumcall.dn    (day^2*ng/mL)/(mg/kg)
#> 177    (hr^2*ng/mL)/(mg/kg)        aumcinf.obs.dn    (day^2*ng/mL)/(mg/kg)
#> 178    (hr^2*ng/mL)/(mg/kg)       aumcinf.pred.dn    (day^2*ng/mL)/(mg/kg)
#> 179      (mg/kg)/(hr*ng/mL)               cl.last      (mg/kg)/(day*ng/mL)
#> 180      (mg/kg)/(hr*ng/mL)                cl.all      (mg/kg)/(day*ng/mL)
#> 181      (mg/kg)/(hr*ng/mL)            cl.int.all      (mg/kg)/(day*ng/mL)
#> 182      (mg/kg)/(hr*ng/mL)           cl.int.last      (mg/kg)/(day*ng/mL)
#> 183      (mg/kg)/(hr*ng/mL)             cl.iv.all      (mg/kg)/(day*ng/mL)
#> 184      (mg/kg)/(hr*ng/mL)            cl.iv.last      (mg/kg)/(day*ng/mL)
#> 185      (mg/kg)/(hr*ng/mL)          cl.ivint.all      (mg/kg)/(day*ng/mL)
#> 186      (mg/kg)/(hr*ng/mL)         cl.ivint.last      (mg/kg)/(day*ng/mL)
#> 187      (mg/kg)/(hr*ng/mL)        cl.sparse.last      (mg/kg)/(day*ng/mL)
#> 188      (mg/kg)/(hr*ng/mL)                cl.obs      (mg/kg)/(day*ng/mL)
#> 189      (mg/kg)/(hr*ng/mL)               cl.pred      (mg/kg)/(day*ng/mL)
#> 190      (mg/kg)/(hr*ng/mL)        cl.int.inf.obs      (mg/kg)/(day*ng/mL)
#> 191      (mg/kg)/(hr*ng/mL)       cl.int.inf.pred      (mg/kg)/(day*ng/mL)
#> 192      (mg/kg)/(hr*ng/mL)             cl.iv.obs      (mg/kg)/(day*ng/mL)
#> 193      (mg/kg)/(hr*ng/mL)            cl.iv.pred      (mg/kg)/(day*ng/mL)
#> 194           mg/(hr*ng/mL)              clr.last           mg/(day*ng/mL)
#> 195           mg/(hr*ng/mL)               clr.obs           mg/(day*ng/mL)
#> 196           mg/(hr*ng/mL)              clr.pred           mg/(day*ng/mL)
#> 197 (mg/(hr*ng/mL))/(mg/kg)           clr.last.dn (mg/(day*ng/mL))/(mg/kg)
#> 198 (mg/(hr*ng/mL))/(mg/kg)            clr.obs.dn (mg/(day*ng/mL))/(mg/kg)
#> 199 (mg/(hr*ng/mL))/(mg/kg)           clr.pred.dn (mg/(day*ng/mL))/(mg/kg)
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
#> 47        0.041666667
#> 48        0.041666667
#> 49        0.041666667
#> 50        0.041666667
#> 51        0.041666667
#> 52        0.041666667
#> 53        0.041666667
#> 54        0.041666667
#> 55        0.041666667
#> 56        0.041666667
#> 57       24.000000000
#> 58       24.000000000
#> 59       24.000000000
#> 60       24.000000000
#> 61       24.000000000
#> 62       24.000000000
#> 63       24.000000000
#> 64       24.000000000
#> 65       24.000000000
#> 66       24.000000000
#> 67       24.000000000
#> 68       24.000000000
#> 69       24.000000000
#> 70       24.000000000
#> 71       24.000000000
#> 72       24.000000000
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
#> 128       0.041666667
#> 129       0.041666667
#> 130       0.041666667
#> 131       0.041666667
#> 132       0.041666667
#> 133       0.041666667
#> 134       0.041666667
#> 135       0.041666667
#> 136       0.041666667
#> 137       0.041666667
#> 138       0.041666667
#> 139       0.041666667
#> 140       0.041666667
#> 141       0.041666667
#> 142       0.041666667
#> 143       0.041666667
#> 144       0.041666667
#> 145       0.041666667
#> 146       0.041666667
#> 147       0.041666667
#> 148       0.041666667
#> 149       0.041666667
#> 150       0.001736111
#> 151       0.001736111
#> 152       0.001736111
#> 153       0.001736111
#> 154       0.001736111
#> 155       0.001736111
#> 156       0.001736111
#> 157       0.001736111
#> 158       0.001736111
#> 159       0.001736111
#> 160       0.001736111
#> 161       0.001736111
#> 162       0.001736111
#> 163       0.001736111
#> 164       0.001736111
#> 165       0.001736111
#> 166       0.001736111
#> 167       0.001736111
#> 168       0.001736111
#> 169       0.001736111
#> 170       0.041666667
#> 171       0.041666667
#> 172       0.041666667
#> 173       0.041666667
#> 174       0.041666667
#> 175       0.001736111
#> 176       0.001736111
#> 177       0.001736111
#> 178       0.001736111
#> 179      24.000000000
#> 180      24.000000000
#> 181      24.000000000
#> 182      24.000000000
#> 183      24.000000000
#> 184      24.000000000
#> 185      24.000000000
#> 186      24.000000000
#> 187      24.000000000
#> 188      24.000000000
#> 189      24.000000000
#> 190      24.000000000
#> 191      24.000000000
#> 192      24.000000000
#> 193      24.000000000
#> 194      24.000000000
#> 195      24.000000000
#> 196      24.000000000
#> 197      24.000000000
#> 198      24.000000000
#> 199      24.000000000
```
