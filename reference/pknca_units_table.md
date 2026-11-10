# Create a unit assignment and conversion table

This data.frame is typically used for the `units` argument for
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md).
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

## Secondary parameters and reference groups

A secondary parameter (renal clearance, bioavailability, a ratio; see
[`vignette("v09-secondary-parameters")`](https://humanpred.github.io/pknca/articles/v09-secondary-parameters.md))
takes one value from the interval requesting it and another from a
reference interval, so its units are a quotient of the two groups'
units. When the `PKNCAdata` method finds more than one set of units
among the groups, the table therefore gains a `<group column>_ref`
column for each of its group columns and, for each secondary parameter,
one row per pair of (own group, reference group) with "PPORRESU"
composed from the correct side of each. Rows describing a result that
names no reference – every primary parameter, and a secondary parameter
calculated without a reference – hold `NA` in the `_ref` columns, and
results carrying no reference group join to them. A quotient whose two
sides are convertible into one another is dimensionless, and such a row
also gets "PPSTRESU" of "fraction" with the "conversion_factor" that
turns the raw quotient into that number.

With one set of units for every group there is no reference side to name
and no `_ref` column is added.

## See also

The `units` argument for
[`PKNCAdata()`](https://humanpred.github.io/pknca/reference/PKNCAdata.md)

## Examples

``` r
pknca_units_table() # only parameters that are unitless
#>     PPORRESU              PPTESTCD
#> 1   unitless             r.squared
#> 2   unitless         adj.r.squared
#> 3   unitless       lambda.z.corrxy
#> 4   unitless        tobit_residual
#> 5   unitless    adj_tobit_residual
#> 6   fraction                   ptr
#> 7   fraction            ratio.cmax
#> 8   fraction         ratio.auclast
#> 9   fraction     ratio.aucint.last
#> 10  fraction      ratio.aucint.all
#> 11  fraction            span.ratio
#> 12  fraction                f.last
#> 13  fraction            f.int.last
#> 14  fraction             f.int.all
#> 15  fraction                 f.obs
#> 16  fraction                f.pred
#> 17  fraction             f.int.obs
#> 18  fraction            f.int.pred
#> 19  fraction      ratio.aucinf.obs
#> 20  fraction     ratio.aucinf.pred
#> 21         %    aucivpbextint.last
#> 22         %     aucivpbextint.all
#> 23         %              deg.fluc
#> 24         %                 swing
#> 25         %        aucivpbextlast
#> 26         %         aucivpbextall
#> 27         %     aucivpbextinf.obs
#> 28         %    aucivpbextinf.pred
#> 29         %           aucpext.obs
#> 30         %          aucpext.pred
#> 31     count            auclast_df
#> 32     count             aucall_df
#> 33     count           aumclast_df
#> 34     count            aumcall_df
#> 35     count            count_conc
#> 36     count   count_conc_measured
#> 37     count         sparse_auc_df
#> 38     count        sparse_aumc_df
#> 39     count          aucivlast_df
#> 40     count           aucivall_df
#> 41     count         aumcivlast_df
#> 42     count          aumcivall_df
#> 43     count     lambda.z.n.points
#> 44     count lambda.z.n.points_blq
#> 45     count         aucinf.obs_df
#> 46     count        aumcinf.obs_df
#> 47     count       aucivinf.obs_df
#> 48     count      aumcivinf.obs_df
#> 49      <NA>                 start
#> 50      <NA>                   end
#> 51      <NA>                  tmax
#> 52      <NA>                  tmin
#> 53      <NA>                 tlast
#> 54      <NA>                tfirst
#> 55      <NA>              mrt.last
#> 56      <NA>               mrt.all
#> 57      <NA>           mrt.int.all
#> 58      <NA>          mrt.int.last
#> 59      <NA>           mrt.iv.last
#> 60      <NA>         mrt.ivint.all
#> 61      <NA>        mrt.ivint.last
#> 62      <NA>                  tlag
#> 63      <NA>                ertlst
#> 64      <NA>                ertmax
#> 65      <NA>            time_above
#> 66      <NA>             half.life
#> 67      <NA>   lambda.z.time.first
#> 68      <NA>    lambda.z.time.last
#> 69      <NA>        thalf.eff.last
#> 70      <NA>     thalf.eff.iv.last
#> 71      <NA>       mrt.sparse.last
#> 72      <NA>            mrt.iv.all
#> 73      <NA>               mrt.obs
#> 74      <NA>              mrt.pred
#> 75      <NA>       mrt.int.inf.obs
#> 76      <NA>      mrt.int.inf.pred
#> 77      <NA>            mrt.iv.obs
#> 78      <NA>           mrt.iv.pred
#> 79      <NA>            mrt.md.obs
#> 80      <NA>           mrt.md.pred
#> 81      <NA>          mrt.ivmd.obs
#> 82      <NA>         mrt.ivmd.pred
#> 83      <NA>         thalf.eff.obs
#> 84      <NA>        thalf.eff.pred
#> 85      <NA>      thalf.eff.iv.obs
#> 86      <NA>     thalf.eff.iv.pred
#> 87      <NA>              lambda.z
#> 88      <NA>              kel.last
#> 89      <NA>           kel.iv.last
#> 90      <NA>               kel.all
#> 91      <NA>           kel.int.all
#> 92      <NA>          kel.int.last
#> 93      <NA>         kel.ivint.all
#> 94      <NA>        kel.ivint.last
#> 95      <NA>            kel.iv.all
#> 96      <NA>       kel.sparse.last
#> 97      <NA>               kel.obs
#> 98      <NA>              kel.pred
#> 99      <NA>            kel.iv.obs
#> 100     <NA>           kel.iv.pred
#> 101     <NA>       kel.int.inf.obs
#> 102     <NA>      kel.int.inf.pred
#> 103     <NA>                    c0
#> 104     <NA>                  cmax
#> 105     <NA>                  cmin
#> 106     <NA>             clast.obs
#> 107     <NA>                   cav
#> 108     <NA>              cav.last
#> 109     <NA>          cav.int.last
#> 110     <NA>           cav.int.all
#> 111     <NA>               cav.all
#> 112     <NA>        cav.ivint.last
#> 113     <NA>         cav.ivint.all
#> 114     <NA>               ctrough
#> 115     <NA>                cstart
#> 116     <NA>                  ceoi
#> 117     <NA>            clast.pred
#> 118     <NA>           cav.iv.last
#> 119     <NA>            cav.iv.all
#> 120     <NA>       cav.int.inf.obs
#> 121     <NA>      cav.int.inf.pred
#> 122     <NA>     cav.ivint.inf.obs
#> 123     <NA>    cav.ivint.inf.pred
#> 124     <NA>                    ae
#> 125     <NA>                    fe
#> 126     <NA>               totdose
#> 127     <NA>               cmax.dn
#> 128     <NA>               cmin.dn
#> 129     <NA>          clast.obs.dn
#> 130     <NA>         clast.pred.dn
#> 131     <NA>                cav.dn
#> 132     <NA>           cav.last.dn
#> 133     <NA>            ctrough.dn
#> 134     <NA>              vss.last
#> 135     <NA>           vss.iv.last
#> 136     <NA>               vss.all
#> 137     <NA>           vss.int.all
#> 138     <NA>          vss.int.last
#> 139     <NA>         vss.ivint.all
#> 140     <NA>        vss.ivint.last
#> 141     <NA>                 volpk
#> 142     <NA>                vz.all
#> 143     <NA>            vz.int.all
#> 144     <NA>           vz.int.last
#> 145     <NA>             vz.iv.all
#> 146     <NA>            vz.iv.last
#> 147     <NA>          vz.ivint.all
#> 148     <NA>         vz.ivint.last
#> 149     <NA>               vz.last
#> 150     <NA>            vss.iv.all
#> 151     <NA>       vss.sparse.last
#> 152     <NA>                vz.obs
#> 153     <NA>               vz.pred
#> 154     <NA>        vz.int.inf.obs
#> 155     <NA>       vz.int.inf.pred
#> 156     <NA>             vz.iv.obs
#> 157     <NA>            vz.iv.pred
#> 158     <NA>        vz.sparse.last
#> 159     <NA>               vss.obs
#> 160     <NA>              vss.pred
#> 161     <NA>            vss.iv.obs
#> 162     <NA>           vss.iv.pred
#> 163     <NA>            vss.md.obs
#> 164     <NA>           vss.md.pred
#> 165     <NA>          vss.ivmd.obs
#> 166     <NA>         vss.ivmd.pred
#> 167     <NA>       vss.int.inf.obs
#> 168     <NA>      vss.int.inf.pred
#> 169     <NA>               auclast
#> 170     <NA>            auclast_se
#> 171     <NA>                aucall
#> 172     <NA>             aucall_se
#> 173     <NA>           aucint.last
#> 174     <NA>            aucint.all
#> 175     <NA>         aucivint.last
#> 176     <NA>          aucivint.all
#> 177     <NA>  aucabove.predose.all
#> 178     <NA>   aucabove.trough.all
#> 179     <NA>        sparse_auclast
#> 180     <NA>         sparse_auc_se
#> 181     <NA>             aucivlast
#> 182     <NA>          aucivlast_se
#> 183     <NA>              aucivall
#> 184     <NA>           aucivall_se
#> 185     <NA>            aucinf.obs
#> 186     <NA>         aucinf.obs_se
#> 187     <NA>           aucinf.pred
#> 188     <NA>        aucint.inf.obs
#> 189     <NA>       aucint.inf.pred
#> 190     <NA>      aucivint.inf.obs
#> 191     <NA>     aucivint.inf.pred
#> 192     <NA>          aucivinf.obs
#> 193     <NA>       aucivinf.obs_se
#> 194     <NA>         aucivinf.pred
#> 195     <NA>              aumclast
#> 196     <NA>           aumclast_se
#> 197     <NA>               aumcall
#> 198     <NA>            aumcall_se
#> 199     <NA>          aumcint.last
#> 200     <NA>           aumcint.all
#> 201     <NA>        aumcivint.last
#> 202     <NA>         aumcivint.all
#> 203     <NA>       sparse_aumclast
#> 204     <NA>        sparse_aumc_se
#> 205     <NA>            aumcivlast
#> 206     <NA>         aumcivlast_se
#> 207     <NA>             aumcivall
#> 208     <NA>          aumcivall_se
#> 209     <NA>           aumcinf.obs
#> 210     <NA>        aumcinf.obs_se
#> 211     <NA>          aumcinf.pred
#> 212     <NA>       aumcint.inf.obs
#> 213     <NA>      aumcint.inf.pred
#> 214     <NA>         aumcivinf.obs
#> 215     <NA>      aumcivinf.obs_se
#> 216     <NA>        aumcivinf.pred
#> 217     <NA>                 ermax
#> 218     <NA>                 erint
#> 219     <NA>                 erlst
#> 220     <NA>            auclast.dn
#> 221     <NA>             aucall.dn
#> 222     <NA>         aucinf.obs.dn
#> 223     <NA>        aucinf.pred.dn
#> 224     <NA>           aumclast.dn
#> 225     <NA>            aumcall.dn
#> 226     <NA>        aumcinf.obs.dn
#> 227     <NA>       aumcinf.pred.dn
#> 228     <NA>               cl.last
#> 229     <NA>                cl.all
#> 230     <NA>            cl.int.all
#> 231     <NA>           cl.int.last
#> 232     <NA>          cl.ivint.all
#> 233     <NA>         cl.ivint.last
#> 234     <NA>             cl.iv.all
#> 235     <NA>            cl.iv.last
#> 236     <NA>        cl.sparse.last
#> 237     <NA>                cl.obs
#> 238     <NA>               cl.pred
#> 239     <NA>        cl.int.inf.obs
#> 240     <NA>       cl.int.inf.pred
#> 241     <NA>             cl.iv.obs
#> 242     <NA>            cl.iv.pred
#> 243     <NA>              clr.last
#> 244     <NA>               clr.obs
#> 245     <NA>              clr.pred
#> 246     <NA>           clr.last.dn
#> 247     <NA>            clr.obs.dn
#> 248     <NA>           clr.pred.dn
pknca_units_table(
  concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr"
)
#>                    PPORRESU              PPTESTCD
#> 1                  unitless             r.squared
#> 2                  unitless         adj.r.squared
#> 3                  unitless       lambda.z.corrxy
#> 4                  unitless        tobit_residual
#> 5                  unitless    adj_tobit_residual
#> 6                  fraction                   ptr
#> 7                  fraction            ratio.cmax
#> 8                  fraction         ratio.auclast
#> 9                  fraction     ratio.aucint.last
#> 10                 fraction      ratio.aucint.all
#> 11                 fraction            span.ratio
#> 12                 fraction                f.last
#> 13                 fraction            f.int.last
#> 14                 fraction             f.int.all
#> 15                 fraction                 f.obs
#> 16                 fraction                f.pred
#> 17                 fraction             f.int.obs
#> 18                 fraction            f.int.pred
#> 19                 fraction      ratio.aucinf.obs
#> 20                 fraction     ratio.aucinf.pred
#> 21                        %    aucivpbextint.last
#> 22                        %     aucivpbextint.all
#> 23                        %              deg.fluc
#> 24                        %                 swing
#> 25                        %        aucivpbextlast
#> 26                        %         aucivpbextall
#> 27                        %     aucivpbextinf.obs
#> 28                        %    aucivpbextinf.pred
#> 29                        %           aucpext.obs
#> 30                        %          aucpext.pred
#> 31                    count            auclast_df
#> 32                    count             aucall_df
#> 33                    count           aumclast_df
#> 34                    count            aumcall_df
#> 35                    count            count_conc
#> 36                    count   count_conc_measured
#> 37                    count         sparse_auc_df
#> 38                    count        sparse_aumc_df
#> 39                    count          aucivlast_df
#> 40                    count           aucivall_df
#> 41                    count         aumcivlast_df
#> 42                    count          aumcivall_df
#> 43                    count     lambda.z.n.points
#> 44                    count lambda.z.n.points_blq
#> 45                    count         aucinf.obs_df
#> 46                    count        aumcinf.obs_df
#> 47                    count       aucivinf.obs_df
#> 48                    count      aumcivinf.obs_df
#> 49                       hr                 start
#> 50                       hr                   end
#> 51                       hr                  tmax
#> 52                       hr                  tmin
#> 53                       hr                 tlast
#> 54                       hr                tfirst
#> 55                       hr              mrt.last
#> 56                       hr               mrt.all
#> 57                       hr           mrt.int.all
#> 58                       hr          mrt.int.last
#> 59                       hr           mrt.iv.last
#> 60                       hr         mrt.ivint.all
#> 61                       hr        mrt.ivint.last
#> 62                       hr                  tlag
#> 63                       hr                ertlst
#> 64                       hr                ertmax
#> 65                       hr            time_above
#> 66                       hr             half.life
#> 67                       hr   lambda.z.time.first
#> 68                       hr    lambda.z.time.last
#> 69                       hr        thalf.eff.last
#> 70                       hr     thalf.eff.iv.last
#> 71                       hr       mrt.sparse.last
#> 72                       hr            mrt.iv.all
#> 73                       hr               mrt.obs
#> 74                       hr              mrt.pred
#> 75                       hr       mrt.int.inf.obs
#> 76                       hr      mrt.int.inf.pred
#> 77                       hr            mrt.iv.obs
#> 78                       hr           mrt.iv.pred
#> 79                       hr            mrt.md.obs
#> 80                       hr           mrt.md.pred
#> 81                       hr          mrt.ivmd.obs
#> 82                       hr         mrt.ivmd.pred
#> 83                       hr         thalf.eff.obs
#> 84                       hr        thalf.eff.pred
#> 85                       hr      thalf.eff.iv.obs
#> 86                       hr     thalf.eff.iv.pred
#> 87                     1/hr              lambda.z
#> 88                     1/hr              kel.last
#> 89                     1/hr           kel.iv.last
#> 90                     1/hr               kel.all
#> 91                     1/hr           kel.int.all
#> 92                     1/hr          kel.int.last
#> 93                     1/hr         kel.ivint.all
#> 94                     1/hr        kel.ivint.last
#> 95                     1/hr            kel.iv.all
#> 96                     1/hr       kel.sparse.last
#> 97                     1/hr               kel.obs
#> 98                     1/hr              kel.pred
#> 99                     1/hr            kel.iv.obs
#> 100                    1/hr           kel.iv.pred
#> 101                    1/hr       kel.int.inf.obs
#> 102                    1/hr      kel.int.inf.pred
#> 103                   ng/mL                    c0
#> 104                   ng/mL                  cmax
#> 105                   ng/mL                  cmin
#> 106                   ng/mL             clast.obs
#> 107                   ng/mL                   cav
#> 108                   ng/mL              cav.last
#> 109                   ng/mL          cav.int.last
#> 110                   ng/mL           cav.int.all
#> 111                   ng/mL               cav.all
#> 112                   ng/mL        cav.ivint.last
#> 113                   ng/mL         cav.ivint.all
#> 114                   ng/mL               ctrough
#> 115                   ng/mL                cstart
#> 116                   ng/mL                  ceoi
#> 117                   ng/mL            clast.pred
#> 118                   ng/mL           cav.iv.last
#> 119                   ng/mL            cav.iv.all
#> 120                   ng/mL       cav.int.inf.obs
#> 121                   ng/mL      cav.int.inf.pred
#> 122                   ng/mL     cav.ivint.inf.obs
#> 123                   ng/mL    cav.ivint.inf.pred
#> 124                      mg                    ae
#> 125              mg/(mg/kg)                    fe
#> 126                   mg/kg               totdose
#> 127         (ng/mL)/(mg/kg)               cmax.dn
#> 128         (ng/mL)/(mg/kg)               cmin.dn
#> 129         (ng/mL)/(mg/kg)          clast.obs.dn
#> 130         (ng/mL)/(mg/kg)         clast.pred.dn
#> 131         (ng/mL)/(mg/kg)                cav.dn
#> 132         (ng/mL)/(mg/kg)           cav.last.dn
#> 133         (ng/mL)/(mg/kg)            ctrough.dn
#> 134         (mg/kg)/(ng/mL)              vss.last
#> 135         (mg/kg)/(ng/mL)           vss.iv.last
#> 136         (mg/kg)/(ng/mL)               vss.all
#> 137         (mg/kg)/(ng/mL)           vss.int.all
#> 138         (mg/kg)/(ng/mL)          vss.int.last
#> 139         (mg/kg)/(ng/mL)         vss.ivint.all
#> 140         (mg/kg)/(ng/mL)        vss.ivint.last
#> 141         (mg/kg)/(ng/mL)                 volpk
#> 142         (mg/kg)/(ng/mL)                vz.all
#> 143         (mg/kg)/(ng/mL)            vz.int.all
#> 144         (mg/kg)/(ng/mL)           vz.int.last
#> 145         (mg/kg)/(ng/mL)             vz.iv.all
#> 146         (mg/kg)/(ng/mL)            vz.iv.last
#> 147         (mg/kg)/(ng/mL)          vz.ivint.all
#> 148         (mg/kg)/(ng/mL)         vz.ivint.last
#> 149         (mg/kg)/(ng/mL)               vz.last
#> 150         (mg/kg)/(ng/mL)            vss.iv.all
#> 151         (mg/kg)/(ng/mL)       vss.sparse.last
#> 152         (mg/kg)/(ng/mL)                vz.obs
#> 153         (mg/kg)/(ng/mL)               vz.pred
#> 154         (mg/kg)/(ng/mL)        vz.int.inf.obs
#> 155         (mg/kg)/(ng/mL)       vz.int.inf.pred
#> 156         (mg/kg)/(ng/mL)             vz.iv.obs
#> 157         (mg/kg)/(ng/mL)            vz.iv.pred
#> 158         (mg/kg)/(ng/mL)        vz.sparse.last
#> 159         (mg/kg)/(ng/mL)               vss.obs
#> 160         (mg/kg)/(ng/mL)              vss.pred
#> 161         (mg/kg)/(ng/mL)            vss.iv.obs
#> 162         (mg/kg)/(ng/mL)           vss.iv.pred
#> 163         (mg/kg)/(ng/mL)            vss.md.obs
#> 164         (mg/kg)/(ng/mL)           vss.md.pred
#> 165         (mg/kg)/(ng/mL)          vss.ivmd.obs
#> 166         (mg/kg)/(ng/mL)         vss.ivmd.pred
#> 167         (mg/kg)/(ng/mL)       vss.int.inf.obs
#> 168         (mg/kg)/(ng/mL)      vss.int.inf.pred
#> 169                hr*ng/mL               auclast
#> 170                hr*ng/mL            auclast_se
#> 171                hr*ng/mL                aucall
#> 172                hr*ng/mL             aucall_se
#> 173                hr*ng/mL           aucint.last
#> 174                hr*ng/mL            aucint.all
#> 175                hr*ng/mL         aucivint.last
#> 176                hr*ng/mL          aucivint.all
#> 177                hr*ng/mL  aucabove.predose.all
#> 178                hr*ng/mL   aucabove.trough.all
#> 179                hr*ng/mL        sparse_auclast
#> 180                hr*ng/mL         sparse_auc_se
#> 181                hr*ng/mL             aucivlast
#> 182                hr*ng/mL          aucivlast_se
#> 183                hr*ng/mL              aucivall
#> 184                hr*ng/mL           aucivall_se
#> 185                hr*ng/mL            aucinf.obs
#> 186                hr*ng/mL         aucinf.obs_se
#> 187                hr*ng/mL           aucinf.pred
#> 188                hr*ng/mL        aucint.inf.obs
#> 189                hr*ng/mL       aucint.inf.pred
#> 190                hr*ng/mL      aucivint.inf.obs
#> 191                hr*ng/mL     aucivint.inf.pred
#> 192                hr*ng/mL          aucivinf.obs
#> 193                hr*ng/mL       aucivinf.obs_se
#> 194                hr*ng/mL         aucivinf.pred
#> 195              hr^2*ng/mL              aumclast
#> 196              hr^2*ng/mL           aumclast_se
#> 197              hr^2*ng/mL               aumcall
#> 198              hr^2*ng/mL            aumcall_se
#> 199              hr^2*ng/mL          aumcint.last
#> 200              hr^2*ng/mL           aumcint.all
#> 201              hr^2*ng/mL        aumcivint.last
#> 202              hr^2*ng/mL         aumcivint.all
#> 203              hr^2*ng/mL       sparse_aumclast
#> 204              hr^2*ng/mL        sparse_aumc_se
#> 205              hr^2*ng/mL            aumcivlast
#> 206              hr^2*ng/mL         aumcivlast_se
#> 207              hr^2*ng/mL             aumcivall
#> 208              hr^2*ng/mL          aumcivall_se
#> 209              hr^2*ng/mL           aumcinf.obs
#> 210              hr^2*ng/mL        aumcinf.obs_se
#> 211              hr^2*ng/mL          aumcinf.pred
#> 212              hr^2*ng/mL       aumcint.inf.obs
#> 213              hr^2*ng/mL      aumcint.inf.pred
#> 214              hr^2*ng/mL         aumcivinf.obs
#> 215              hr^2*ng/mL      aumcivinf.obs_se
#> 216              hr^2*ng/mL        aumcivinf.pred
#> 217                   mg/hr                 ermax
#> 218                   mg/hr                 erint
#> 219                   mg/hr                 erlst
#> 220      (hr*ng/mL)/(mg/kg)            auclast.dn
#> 221      (hr*ng/mL)/(mg/kg)             aucall.dn
#> 222      (hr*ng/mL)/(mg/kg)         aucinf.obs.dn
#> 223      (hr*ng/mL)/(mg/kg)        aucinf.pred.dn
#> 224    (hr^2*ng/mL)/(mg/kg)           aumclast.dn
#> 225    (hr^2*ng/mL)/(mg/kg)            aumcall.dn
#> 226    (hr^2*ng/mL)/(mg/kg)        aumcinf.obs.dn
#> 227    (hr^2*ng/mL)/(mg/kg)       aumcinf.pred.dn
#> 228      (mg/kg)/(hr*ng/mL)               cl.last
#> 229      (mg/kg)/(hr*ng/mL)                cl.all
#> 230      (mg/kg)/(hr*ng/mL)            cl.int.all
#> 231      (mg/kg)/(hr*ng/mL)           cl.int.last
#> 232      (mg/kg)/(hr*ng/mL)          cl.ivint.all
#> 233      (mg/kg)/(hr*ng/mL)         cl.ivint.last
#> 234      (mg/kg)/(hr*ng/mL)             cl.iv.all
#> 235      (mg/kg)/(hr*ng/mL)            cl.iv.last
#> 236      (mg/kg)/(hr*ng/mL)        cl.sparse.last
#> 237      (mg/kg)/(hr*ng/mL)                cl.obs
#> 238      (mg/kg)/(hr*ng/mL)               cl.pred
#> 239      (mg/kg)/(hr*ng/mL)        cl.int.inf.obs
#> 240      (mg/kg)/(hr*ng/mL)       cl.int.inf.pred
#> 241      (mg/kg)/(hr*ng/mL)             cl.iv.obs
#> 242      (mg/kg)/(hr*ng/mL)            cl.iv.pred
#> 243           mg/(hr*ng/mL)              clr.last
#> 244           mg/(hr*ng/mL)               clr.obs
#> 245           mg/(hr*ng/mL)              clr.pred
#> 246 (mg/(hr*ng/mL))/(mg/kg)           clr.last.dn
#> 247 (mg/(hr*ng/mL))/(mg/kg)            clr.obs.dn
#> 248 (mg/(hr*ng/mL))/(mg/kg)           clr.pred.dn
# Automatic unit conversion needs the units package
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
#> 6                  fraction                   ptr                fraction
#> 7                  fraction            ratio.cmax                fraction
#> 8                  fraction         ratio.auclast                fraction
#> 9                  fraction     ratio.aucint.last                fraction
#> 10                 fraction      ratio.aucint.all                fraction
#> 11                 fraction            span.ratio                fraction
#> 12                 fraction                f.last                fraction
#> 13                 fraction            f.int.last                fraction
#> 14                 fraction             f.int.all                fraction
#> 15                 fraction                 f.obs                fraction
#> 16                 fraction                f.pred                fraction
#> 17                 fraction             f.int.obs                fraction
#> 18                 fraction            f.int.pred                fraction
#> 19                 fraction      ratio.aucinf.obs                fraction
#> 20                 fraction     ratio.aucinf.pred                fraction
#> 21                        %    aucivpbextint.last                       %
#> 22                        %     aucivpbextint.all                       %
#> 23                        %              deg.fluc                       %
#> 24                        %                 swing                       %
#> 25                        %        aucivpbextlast                       %
#> 26                        %         aucivpbextall                       %
#> 27                        %     aucivpbextinf.obs                       %
#> 28                        %    aucivpbextinf.pred                       %
#> 29                        %           aucpext.obs                       %
#> 30                        %          aucpext.pred                       %
#> 31                    count            auclast_df                   count
#> 32                    count             aucall_df                   count
#> 33                    count           aumclast_df                   count
#> 34                    count            aumcall_df                   count
#> 35                    count            count_conc                   count
#> 36                    count   count_conc_measured                   count
#> 37                    count         sparse_auc_df                   count
#> 38                    count        sparse_aumc_df                   count
#> 39                    count          aucivlast_df                   count
#> 40                    count           aucivall_df                   count
#> 41                    count         aumcivlast_df                   count
#> 42                    count          aumcivall_df                   count
#> 43                    count     lambda.z.n.points                   count
#> 44                    count lambda.z.n.points_blq                   count
#> 45                    count         aucinf.obs_df                   count
#> 46                    count        aumcinf.obs_df                   count
#> 47                    count       aucivinf.obs_df                   count
#> 48                    count      aumcivinf.obs_df                   count
#> 49                       hr                 start                      hr
#> 50                       hr                   end                      hr
#> 51                       hr                  tmax                      hr
#> 52                       hr                  tmin                      hr
#> 53                       hr                 tlast                      hr
#> 54                       hr                tfirst                      hr
#> 55                       hr              mrt.last                      hr
#> 56                       hr               mrt.all                      hr
#> 57                       hr           mrt.int.all                      hr
#> 58                       hr          mrt.int.last                      hr
#> 59                       hr           mrt.iv.last                      hr
#> 60                       hr         mrt.ivint.all                      hr
#> 61                       hr        mrt.ivint.last                      hr
#> 62                       hr                  tlag                      hr
#> 63                       hr                ertlst                      hr
#> 64                       hr                ertmax                      hr
#> 65                       hr            time_above                      hr
#> 66                       hr             half.life                      hr
#> 67                       hr   lambda.z.time.first                      hr
#> 68                       hr    lambda.z.time.last                      hr
#> 69                       hr        thalf.eff.last                      hr
#> 70                       hr     thalf.eff.iv.last                      hr
#> 71                       hr       mrt.sparse.last                      hr
#> 72                       hr            mrt.iv.all                      hr
#> 73                       hr               mrt.obs                      hr
#> 74                       hr              mrt.pred                      hr
#> 75                       hr       mrt.int.inf.obs                      hr
#> 76                       hr      mrt.int.inf.pred                      hr
#> 77                       hr            mrt.iv.obs                      hr
#> 78                       hr           mrt.iv.pred                      hr
#> 79                       hr            mrt.md.obs                      hr
#> 80                       hr           mrt.md.pred                      hr
#> 81                       hr          mrt.ivmd.obs                      hr
#> 82                       hr         mrt.ivmd.pred                      hr
#> 83                       hr         thalf.eff.obs                      hr
#> 84                       hr        thalf.eff.pred                      hr
#> 85                       hr      thalf.eff.iv.obs                      hr
#> 86                       hr     thalf.eff.iv.pred                      hr
#> 87                     1/hr              lambda.z                    1/hr
#> 88                     1/hr              kel.last                    1/hr
#> 89                     1/hr           kel.iv.last                    1/hr
#> 90                     1/hr               kel.all                    1/hr
#> 91                     1/hr           kel.int.all                    1/hr
#> 92                     1/hr          kel.int.last                    1/hr
#> 93                     1/hr         kel.ivint.all                    1/hr
#> 94                     1/hr        kel.ivint.last                    1/hr
#> 95                     1/hr            kel.iv.all                    1/hr
#> 96                     1/hr       kel.sparse.last                    1/hr
#> 97                     1/hr               kel.obs                    1/hr
#> 98                     1/hr              kel.pred                    1/hr
#> 99                     1/hr            kel.iv.obs                    1/hr
#> 100                    1/hr           kel.iv.pred                    1/hr
#> 101                    1/hr       kel.int.inf.obs                    1/hr
#> 102                    1/hr      kel.int.inf.pred                    1/hr
#> 103                   ng/mL                    c0                   ng/mL
#> 104                   ng/mL                  cmax                   ng/mL
#> 105                   ng/mL                  cmin                   ng/mL
#> 106                   ng/mL             clast.obs                   ng/mL
#> 107                   ng/mL                   cav                   ng/mL
#> 108                   ng/mL              cav.last                   ng/mL
#> 109                   ng/mL          cav.int.last                   ng/mL
#> 110                   ng/mL           cav.int.all                   ng/mL
#> 111                   ng/mL               cav.all                   ng/mL
#> 112                   ng/mL        cav.ivint.last                   ng/mL
#> 113                   ng/mL         cav.ivint.all                   ng/mL
#> 114                   ng/mL               ctrough                   ng/mL
#> 115                   ng/mL                cstart                   ng/mL
#> 116                   ng/mL                  ceoi                   ng/mL
#> 117                   ng/mL            clast.pred                   ng/mL
#> 118                   ng/mL           cav.iv.last                   ng/mL
#> 119                   ng/mL            cav.iv.all                   ng/mL
#> 120                   ng/mL       cav.int.inf.obs                   ng/mL
#> 121                   ng/mL      cav.int.inf.pred                   ng/mL
#> 122                   ng/mL     cav.ivint.inf.obs                   ng/mL
#> 123                   ng/mL    cav.ivint.inf.pred                   ng/mL
#> 124                      mg                    ae                      mg
#> 125              mg/(mg/kg)                    fe              mg/(mg/kg)
#> 126                   mg/kg               totdose                   mg/kg
#> 127         (ng/mL)/(mg/kg)               cmax.dn         (ng/mL)/(mg/kg)
#> 128         (ng/mL)/(mg/kg)               cmin.dn         (ng/mL)/(mg/kg)
#> 129         (ng/mL)/(mg/kg)          clast.obs.dn         (ng/mL)/(mg/kg)
#> 130         (ng/mL)/(mg/kg)         clast.pred.dn         (ng/mL)/(mg/kg)
#> 131         (ng/mL)/(mg/kg)                cav.dn         (ng/mL)/(mg/kg)
#> 132         (ng/mL)/(mg/kg)           cav.last.dn         (ng/mL)/(mg/kg)
#> 133         (ng/mL)/(mg/kg)            ctrough.dn         (ng/mL)/(mg/kg)
#> 134         (mg/kg)/(ng/mL)              vss.last                   mL/kg
#> 135         (mg/kg)/(ng/mL)           vss.iv.last                   mL/kg
#> 136         (mg/kg)/(ng/mL)               vss.all                   mL/kg
#> 137         (mg/kg)/(ng/mL)           vss.int.all                   mL/kg
#> 138         (mg/kg)/(ng/mL)          vss.int.last                   mL/kg
#> 139         (mg/kg)/(ng/mL)         vss.ivint.all                   mL/kg
#> 140         (mg/kg)/(ng/mL)        vss.ivint.last                   mL/kg
#> 141         (mg/kg)/(ng/mL)                 volpk                   mL/kg
#> 142         (mg/kg)/(ng/mL)                vz.all                   mL/kg
#> 143         (mg/kg)/(ng/mL)            vz.int.all                   mL/kg
#> 144         (mg/kg)/(ng/mL)           vz.int.last                   mL/kg
#> 145         (mg/kg)/(ng/mL)             vz.iv.all                   mL/kg
#> 146         (mg/kg)/(ng/mL)            vz.iv.last                   mL/kg
#> 147         (mg/kg)/(ng/mL)          vz.ivint.all                   mL/kg
#> 148         (mg/kg)/(ng/mL)         vz.ivint.last                   mL/kg
#> 149         (mg/kg)/(ng/mL)               vz.last                   mL/kg
#> 150         (mg/kg)/(ng/mL)            vss.iv.all                   mL/kg
#> 151         (mg/kg)/(ng/mL)       vss.sparse.last                   mL/kg
#> 152         (mg/kg)/(ng/mL)                vz.obs                   mL/kg
#> 153         (mg/kg)/(ng/mL)               vz.pred                   mL/kg
#> 154         (mg/kg)/(ng/mL)        vz.int.inf.obs                   mL/kg
#> 155         (mg/kg)/(ng/mL)       vz.int.inf.pred                   mL/kg
#> 156         (mg/kg)/(ng/mL)             vz.iv.obs                   mL/kg
#> 157         (mg/kg)/(ng/mL)            vz.iv.pred                   mL/kg
#> 158         (mg/kg)/(ng/mL)        vz.sparse.last                   mL/kg
#> 159         (mg/kg)/(ng/mL)               vss.obs                   mL/kg
#> 160         (mg/kg)/(ng/mL)              vss.pred                   mL/kg
#> 161         (mg/kg)/(ng/mL)            vss.iv.obs                   mL/kg
#> 162         (mg/kg)/(ng/mL)           vss.iv.pred                   mL/kg
#> 163         (mg/kg)/(ng/mL)            vss.md.obs                   mL/kg
#> 164         (mg/kg)/(ng/mL)           vss.md.pred                   mL/kg
#> 165         (mg/kg)/(ng/mL)          vss.ivmd.obs                   mL/kg
#> 166         (mg/kg)/(ng/mL)         vss.ivmd.pred                   mL/kg
#> 167         (mg/kg)/(ng/mL)       vss.int.inf.obs                   mL/kg
#> 168         (mg/kg)/(ng/mL)      vss.int.inf.pred                   mL/kg
#> 169                hr*ng/mL               auclast                hr*ng/mL
#> 170                hr*ng/mL            auclast_se                hr*ng/mL
#> 171                hr*ng/mL                aucall                hr*ng/mL
#> 172                hr*ng/mL             aucall_se                hr*ng/mL
#> 173                hr*ng/mL           aucint.last                hr*ng/mL
#> 174                hr*ng/mL            aucint.all                hr*ng/mL
#> 175                hr*ng/mL         aucivint.last                hr*ng/mL
#> 176                hr*ng/mL          aucivint.all                hr*ng/mL
#> 177                hr*ng/mL  aucabove.predose.all                hr*ng/mL
#> 178                hr*ng/mL   aucabove.trough.all                hr*ng/mL
#> 179                hr*ng/mL        sparse_auclast                hr*ng/mL
#> 180                hr*ng/mL         sparse_auc_se                hr*ng/mL
#> 181                hr*ng/mL             aucivlast                hr*ng/mL
#> 182                hr*ng/mL          aucivlast_se                hr*ng/mL
#> 183                hr*ng/mL              aucivall                hr*ng/mL
#> 184                hr*ng/mL           aucivall_se                hr*ng/mL
#> 185                hr*ng/mL            aucinf.obs                hr*ng/mL
#> 186                hr*ng/mL         aucinf.obs_se                hr*ng/mL
#> 187                hr*ng/mL           aucinf.pred                hr*ng/mL
#> 188                hr*ng/mL        aucint.inf.obs                hr*ng/mL
#> 189                hr*ng/mL       aucint.inf.pred                hr*ng/mL
#> 190                hr*ng/mL      aucivint.inf.obs                hr*ng/mL
#> 191                hr*ng/mL     aucivint.inf.pred                hr*ng/mL
#> 192                hr*ng/mL          aucivinf.obs                hr*ng/mL
#> 193                hr*ng/mL       aucivinf.obs_se                hr*ng/mL
#> 194                hr*ng/mL         aucivinf.pred                hr*ng/mL
#> 195              hr^2*ng/mL              aumclast              hr^2*ng/mL
#> 196              hr^2*ng/mL           aumclast_se              hr^2*ng/mL
#> 197              hr^2*ng/mL               aumcall              hr^2*ng/mL
#> 198              hr^2*ng/mL            aumcall_se              hr^2*ng/mL
#> 199              hr^2*ng/mL          aumcint.last              hr^2*ng/mL
#> 200              hr^2*ng/mL           aumcint.all              hr^2*ng/mL
#> 201              hr^2*ng/mL        aumcivint.last              hr^2*ng/mL
#> 202              hr^2*ng/mL         aumcivint.all              hr^2*ng/mL
#> 203              hr^2*ng/mL       sparse_aumclast              hr^2*ng/mL
#> 204              hr^2*ng/mL        sparse_aumc_se              hr^2*ng/mL
#> 205              hr^2*ng/mL            aumcivlast              hr^2*ng/mL
#> 206              hr^2*ng/mL         aumcivlast_se              hr^2*ng/mL
#> 207              hr^2*ng/mL             aumcivall              hr^2*ng/mL
#> 208              hr^2*ng/mL          aumcivall_se              hr^2*ng/mL
#> 209              hr^2*ng/mL           aumcinf.obs              hr^2*ng/mL
#> 210              hr^2*ng/mL        aumcinf.obs_se              hr^2*ng/mL
#> 211              hr^2*ng/mL          aumcinf.pred              hr^2*ng/mL
#> 212              hr^2*ng/mL       aumcint.inf.obs              hr^2*ng/mL
#> 213              hr^2*ng/mL      aumcint.inf.pred              hr^2*ng/mL
#> 214              hr^2*ng/mL         aumcivinf.obs              hr^2*ng/mL
#> 215              hr^2*ng/mL      aumcivinf.obs_se              hr^2*ng/mL
#> 216              hr^2*ng/mL        aumcivinf.pred              hr^2*ng/mL
#> 217                   mg/hr                 ermax                   mg/hr
#> 218                   mg/hr                 erint                   mg/hr
#> 219                   mg/hr                 erlst                   mg/hr
#> 220      (hr*ng/mL)/(mg/kg)            auclast.dn      (hr*ng/mL)/(mg/kg)
#> 221      (hr*ng/mL)/(mg/kg)             aucall.dn      (hr*ng/mL)/(mg/kg)
#> 222      (hr*ng/mL)/(mg/kg)         aucinf.obs.dn      (hr*ng/mL)/(mg/kg)
#> 223      (hr*ng/mL)/(mg/kg)        aucinf.pred.dn      (hr*ng/mL)/(mg/kg)
#> 224    (hr^2*ng/mL)/(mg/kg)           aumclast.dn    (hr^2*ng/mL)/(mg/kg)
#> 225    (hr^2*ng/mL)/(mg/kg)            aumcall.dn    (hr^2*ng/mL)/(mg/kg)
#> 226    (hr^2*ng/mL)/(mg/kg)        aumcinf.obs.dn    (hr^2*ng/mL)/(mg/kg)
#> 227    (hr^2*ng/mL)/(mg/kg)       aumcinf.pred.dn    (hr^2*ng/mL)/(mg/kg)
#> 228      (mg/kg)/(hr*ng/mL)               cl.last                mL/hr/kg
#> 229      (mg/kg)/(hr*ng/mL)                cl.all                mL/hr/kg
#> 230      (mg/kg)/(hr*ng/mL)            cl.int.all                mL/hr/kg
#> 231      (mg/kg)/(hr*ng/mL)           cl.int.last                mL/hr/kg
#> 232      (mg/kg)/(hr*ng/mL)          cl.ivint.all                mL/hr/kg
#> 233      (mg/kg)/(hr*ng/mL)         cl.ivint.last                mL/hr/kg
#> 234      (mg/kg)/(hr*ng/mL)             cl.iv.all                mL/hr/kg
#> 235      (mg/kg)/(hr*ng/mL)            cl.iv.last                mL/hr/kg
#> 236      (mg/kg)/(hr*ng/mL)        cl.sparse.last                mL/hr/kg
#> 237      (mg/kg)/(hr*ng/mL)                cl.obs                mL/hr/kg
#> 238      (mg/kg)/(hr*ng/mL)               cl.pred                mL/hr/kg
#> 239      (mg/kg)/(hr*ng/mL)        cl.int.inf.obs                mL/hr/kg
#> 240      (mg/kg)/(hr*ng/mL)       cl.int.inf.pred                mL/hr/kg
#> 241      (mg/kg)/(hr*ng/mL)             cl.iv.obs                mL/hr/kg
#> 242      (mg/kg)/(hr*ng/mL)            cl.iv.pred                mL/hr/kg
#> 243           mg/(hr*ng/mL)              clr.last           mg/(hr*ng/mL)
#> 244           mg/(hr*ng/mL)               clr.obs           mg/(hr*ng/mL)
#> 245           mg/(hr*ng/mL)              clr.pred           mg/(hr*ng/mL)
#> 246 (mg/(hr*ng/mL))/(mg/kg)           clr.last.dn (mg/(hr*ng/mL))/(mg/kg)
#> 247 (mg/(hr*ng/mL))/(mg/kg)            clr.obs.dn (mg/(hr*ng/mL))/(mg/kg)
#> 248 (mg/(hr*ng/mL))/(mg/kg)           clr.pred.dn (mg/(hr*ng/mL))/(mg/kg)
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
#> 133             1e+00
#> 134             1e+06
#> 135             1e+06
#> 136             1e+06
#> 137             1e+06
#> 138             1e+06
#> 139             1e+06
#> 140             1e+06
#> 141             1e+06
#> 142             1e+06
#> 143             1e+06
#> 144             1e+06
#> 145             1e+06
#> 146             1e+06
#> 147             1e+06
#> 148             1e+06
#> 149             1e+06
#> 150             1e+06
#> 151             1e+06
#> 152             1e+06
#> 153             1e+06
#> 154             1e+06
#> 155             1e+06
#> 156             1e+06
#> 157             1e+06
#> 158             1e+06
#> 159             1e+06
#> 160             1e+06
#> 161             1e+06
#> 162             1e+06
#> 163             1e+06
#> 164             1e+06
#> 165             1e+06
#> 166             1e+06
#> 167             1e+06
#> 168             1e+06
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
#> 179             1e+00
#> 180             1e+00
#> 181             1e+00
#> 182             1e+00
#> 183             1e+00
#> 184             1e+00
#> 185             1e+00
#> 186             1e+00
#> 187             1e+00
#> 188             1e+00
#> 189             1e+00
#> 190             1e+00
#> 191             1e+00
#> 192             1e+00
#> 193             1e+00
#> 194             1e+00
#> 195             1e+00
#> 196             1e+00
#> 197             1e+00
#> 198             1e+00
#> 199             1e+00
#> 200             1e+00
#> 201             1e+00
#> 202             1e+00
#> 203             1e+00
#> 204             1e+00
#> 205             1e+00
#> 206             1e+00
#> 207             1e+00
#> 208             1e+00
#> 209             1e+00
#> 210             1e+00
#> 211             1e+00
#> 212             1e+00
#> 213             1e+00
#> 214             1e+00
#> 215             1e+00
#> 216             1e+00
#> 217             1e+00
#> 218             1e+00
#> 219             1e+00
#> 220             1e+00
#> 221             1e+00
#> 222             1e+00
#> 223             1e+00
#> 224             1e+00
#> 225             1e+00
#> 226             1e+00
#> 227             1e+00
#> 228             1e+06
#> 229             1e+06
#> 230             1e+06
#> 231             1e+06
#> 232             1e+06
#> 233             1e+06
#> 234             1e+06
#> 235             1e+06
#> 236             1e+06
#> 237             1e+06
#> 238             1e+06
#> 239             1e+06
#> 240             1e+06
#> 241             1e+06
#> 242             1e+06
#> 243             1e+00
#> 244             1e+00
#> 245             1e+00
#> 246             1e+00
#> 247             1e+00
#> 248             1e+00
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
#> 6                 fraction                   ptr               fraction
#> 7                 fraction            ratio.cmax               fraction
#> 8                 fraction         ratio.auclast               fraction
#> 9                 fraction     ratio.aucint.last               fraction
#> 10                fraction      ratio.aucint.all               fraction
#> 11                fraction            span.ratio               fraction
#> 12                fraction                f.last               fraction
#> 13                fraction            f.int.last               fraction
#> 14                fraction             f.int.all               fraction
#> 15                fraction                 f.obs               fraction
#> 16                fraction                f.pred               fraction
#> 17                fraction             f.int.obs               fraction
#> 18                fraction            f.int.pred               fraction
#> 19                fraction      ratio.aucinf.obs               fraction
#> 20                fraction     ratio.aucinf.pred               fraction
#> 21                       %    aucivpbextint.last                      %
#> 22                       %     aucivpbextint.all                      %
#> 23                       %              deg.fluc                      %
#> 24                       %                 swing                      %
#> 25                       %        aucivpbextlast                      %
#> 26                       %         aucivpbextall                      %
#> 27                       %     aucivpbextinf.obs                      %
#> 28                       %    aucivpbextinf.pred                      %
#> 29                       %           aucpext.obs                      %
#> 30                       %          aucpext.pred                      %
#> 31                   count            auclast_df                  count
#> 32                   count             aucall_df                  count
#> 33                   count           aumclast_df                  count
#> 34                   count            aumcall_df                  count
#> 35                   count            count_conc                  count
#> 36                   count   count_conc_measured                  count
#> 37                   count         sparse_auc_df                  count
#> 38                   count        sparse_aumc_df                  count
#> 39                   count          aucivlast_df                  count
#> 40                   count           aucivall_df                  count
#> 41                   count         aumcivlast_df                  count
#> 42                   count          aumcivall_df                  count
#> 43                   count     lambda.z.n.points                  count
#> 44                   count lambda.z.n.points_blq                  count
#> 45                   count         aucinf.obs_df                  count
#> 46                   count        aumcinf.obs_df                  count
#> 47                   count       aucivinf.obs_df                  count
#> 48                   count      aumcivinf.obs_df                  count
#> 49                      hr                 start                     hr
#> 50                      hr                   end                     hr
#> 51                      hr                  tmax                     hr
#> 52                      hr                  tmin                     hr
#> 53                      hr                 tlast                     hr
#> 54                      hr                tfirst                     hr
#> 55                      hr              mrt.last                     hr
#> 56                      hr               mrt.all                     hr
#> 57                      hr           mrt.int.all                     hr
#> 58                      hr          mrt.int.last                     hr
#> 59                      hr           mrt.iv.last                     hr
#> 60                      hr         mrt.ivint.all                     hr
#> 61                      hr        mrt.ivint.last                     hr
#> 62                      hr                  tlag                     hr
#> 63                      hr                ertlst                     hr
#> 64                      hr                ertmax                     hr
#> 65                      hr            time_above                     hr
#> 66                      hr             half.life                     hr
#> 67                      hr   lambda.z.time.first                     hr
#> 68                      hr    lambda.z.time.last                     hr
#> 69                      hr        thalf.eff.last                     hr
#> 70                      hr     thalf.eff.iv.last                     hr
#> 71                      hr       mrt.sparse.last                     hr
#> 72                      hr            mrt.iv.all                     hr
#> 73                      hr               mrt.obs                     hr
#> 74                      hr              mrt.pred                     hr
#> 75                      hr       mrt.int.inf.obs                     hr
#> 76                      hr      mrt.int.inf.pred                     hr
#> 77                      hr            mrt.iv.obs                     hr
#> 78                      hr           mrt.iv.pred                     hr
#> 79                      hr            mrt.md.obs                     hr
#> 80                      hr           mrt.md.pred                     hr
#> 81                      hr          mrt.ivmd.obs                     hr
#> 82                      hr         mrt.ivmd.pred                     hr
#> 83                      hr         thalf.eff.obs                     hr
#> 84                      hr        thalf.eff.pred                     hr
#> 85                      hr      thalf.eff.iv.obs                     hr
#> 86                      hr     thalf.eff.iv.pred                     hr
#> 87                    1/hr              lambda.z                   1/hr
#> 88                    1/hr              kel.last                   1/hr
#> 89                    1/hr           kel.iv.last                   1/hr
#> 90                    1/hr               kel.all                   1/hr
#> 91                    1/hr           kel.int.all                   1/hr
#> 92                    1/hr          kel.int.last                   1/hr
#> 93                    1/hr         kel.ivint.all                   1/hr
#> 94                    1/hr        kel.ivint.last                   1/hr
#> 95                    1/hr            kel.iv.all                   1/hr
#> 96                    1/hr       kel.sparse.last                   1/hr
#> 97                    1/hr               kel.obs                   1/hr
#> 98                    1/hr              kel.pred                   1/hr
#> 99                    1/hr            kel.iv.obs                   1/hr
#> 100                   1/hr           kel.iv.pred                   1/hr
#> 101                   1/hr       kel.int.inf.obs                   1/hr
#> 102                   1/hr      kel.int.inf.pred                   1/hr
#> 103                   mg/L                    c0                 mmol/L
#> 104                   mg/L                  cmax                 mmol/L
#> 105                   mg/L                  cmin                 mmol/L
#> 106                   mg/L             clast.obs                 mmol/L
#> 107                   mg/L                   cav                 mmol/L
#> 108                   mg/L              cav.last                 mmol/L
#> 109                   mg/L          cav.int.last                 mmol/L
#> 110                   mg/L           cav.int.all                 mmol/L
#> 111                   mg/L               cav.all                 mmol/L
#> 112                   mg/L        cav.ivint.last                 mmol/L
#> 113                   mg/L         cav.ivint.all                 mmol/L
#> 114                   mg/L               ctrough                 mmol/L
#> 115                   mg/L                cstart                 mmol/L
#> 116                   mg/L                  ceoi                 mmol/L
#> 117                   mg/L            clast.pred                 mmol/L
#> 118                   mg/L           cav.iv.last                 mmol/L
#> 119                   mg/L            cav.iv.all                 mmol/L
#> 120                   mg/L       cav.int.inf.obs                 mmol/L
#> 121                   mg/L      cav.int.inf.pred                 mmol/L
#> 122                   mg/L     cav.ivint.inf.obs                 mmol/L
#> 123                   mg/L    cav.ivint.inf.pred                 mmol/L
#> 124                     mg                    ae                     mg
#> 125             mg/(mg/kg)                    fe             mg/(mg/kg)
#> 126                  mg/kg               totdose                  mg/kg
#> 127         (mg/L)/(mg/kg)               cmax.dn         (mg/L)/(mg/kg)
#> 128         (mg/L)/(mg/kg)               cmin.dn         (mg/L)/(mg/kg)
#> 129         (mg/L)/(mg/kg)          clast.obs.dn         (mg/L)/(mg/kg)
#> 130         (mg/L)/(mg/kg)         clast.pred.dn         (mg/L)/(mg/kg)
#> 131         (mg/L)/(mg/kg)                cav.dn         (mg/L)/(mg/kg)
#> 132         (mg/L)/(mg/kg)           cav.last.dn         (mg/L)/(mg/kg)
#> 133         (mg/L)/(mg/kg)            ctrough.dn         (mg/L)/(mg/kg)
#> 134         (mg/kg)/(mg/L)              vss.last         (mg/kg)/(mg/L)
#> 135         (mg/kg)/(mg/L)           vss.iv.last         (mg/kg)/(mg/L)
#> 136         (mg/kg)/(mg/L)               vss.all         (mg/kg)/(mg/L)
#> 137         (mg/kg)/(mg/L)           vss.int.all         (mg/kg)/(mg/L)
#> 138         (mg/kg)/(mg/L)          vss.int.last         (mg/kg)/(mg/L)
#> 139         (mg/kg)/(mg/L)         vss.ivint.all         (mg/kg)/(mg/L)
#> 140         (mg/kg)/(mg/L)        vss.ivint.last         (mg/kg)/(mg/L)
#> 141         (mg/kg)/(mg/L)                 volpk         (mg/kg)/(mg/L)
#> 142         (mg/kg)/(mg/L)                vz.all         (mg/kg)/(mg/L)
#> 143         (mg/kg)/(mg/L)            vz.int.all         (mg/kg)/(mg/L)
#> 144         (mg/kg)/(mg/L)           vz.int.last         (mg/kg)/(mg/L)
#> 145         (mg/kg)/(mg/L)             vz.iv.all         (mg/kg)/(mg/L)
#> 146         (mg/kg)/(mg/L)            vz.iv.last         (mg/kg)/(mg/L)
#> 147         (mg/kg)/(mg/L)          vz.ivint.all         (mg/kg)/(mg/L)
#> 148         (mg/kg)/(mg/L)         vz.ivint.last         (mg/kg)/(mg/L)
#> 149         (mg/kg)/(mg/L)               vz.last         (mg/kg)/(mg/L)
#> 150         (mg/kg)/(mg/L)            vss.iv.all         (mg/kg)/(mg/L)
#> 151         (mg/kg)/(mg/L)       vss.sparse.last         (mg/kg)/(mg/L)
#> 152         (mg/kg)/(mg/L)                vz.obs         (mg/kg)/(mg/L)
#> 153         (mg/kg)/(mg/L)               vz.pred         (mg/kg)/(mg/L)
#> 154         (mg/kg)/(mg/L)        vz.int.inf.obs         (mg/kg)/(mg/L)
#> 155         (mg/kg)/(mg/L)       vz.int.inf.pred         (mg/kg)/(mg/L)
#> 156         (mg/kg)/(mg/L)             vz.iv.obs         (mg/kg)/(mg/L)
#> 157         (mg/kg)/(mg/L)            vz.iv.pred         (mg/kg)/(mg/L)
#> 158         (mg/kg)/(mg/L)        vz.sparse.last         (mg/kg)/(mg/L)
#> 159         (mg/kg)/(mg/L)               vss.obs         (mg/kg)/(mg/L)
#> 160         (mg/kg)/(mg/L)              vss.pred         (mg/kg)/(mg/L)
#> 161         (mg/kg)/(mg/L)            vss.iv.obs         (mg/kg)/(mg/L)
#> 162         (mg/kg)/(mg/L)           vss.iv.pred         (mg/kg)/(mg/L)
#> 163         (mg/kg)/(mg/L)            vss.md.obs         (mg/kg)/(mg/L)
#> 164         (mg/kg)/(mg/L)           vss.md.pred         (mg/kg)/(mg/L)
#> 165         (mg/kg)/(mg/L)          vss.ivmd.obs         (mg/kg)/(mg/L)
#> 166         (mg/kg)/(mg/L)         vss.ivmd.pred         (mg/kg)/(mg/L)
#> 167         (mg/kg)/(mg/L)       vss.int.inf.obs         (mg/kg)/(mg/L)
#> 168         (mg/kg)/(mg/L)      vss.int.inf.pred         (mg/kg)/(mg/L)
#> 169                hr*mg/L               auclast                hr*mg/L
#> 170                hr*mg/L            auclast_se                hr*mg/L
#> 171                hr*mg/L                aucall                hr*mg/L
#> 172                hr*mg/L             aucall_se                hr*mg/L
#> 173                hr*mg/L           aucint.last                hr*mg/L
#> 174                hr*mg/L            aucint.all                hr*mg/L
#> 175                hr*mg/L         aucivint.last                hr*mg/L
#> 176                hr*mg/L          aucivint.all                hr*mg/L
#> 177                hr*mg/L  aucabove.predose.all                hr*mg/L
#> 178                hr*mg/L   aucabove.trough.all                hr*mg/L
#> 179                hr*mg/L        sparse_auclast                hr*mg/L
#> 180                hr*mg/L         sparse_auc_se                hr*mg/L
#> 181                hr*mg/L             aucivlast                hr*mg/L
#> 182                hr*mg/L          aucivlast_se                hr*mg/L
#> 183                hr*mg/L              aucivall                hr*mg/L
#> 184                hr*mg/L           aucivall_se                hr*mg/L
#> 185                hr*mg/L            aucinf.obs                hr*mg/L
#> 186                hr*mg/L         aucinf.obs_se                hr*mg/L
#> 187                hr*mg/L           aucinf.pred                hr*mg/L
#> 188                hr*mg/L        aucint.inf.obs                hr*mg/L
#> 189                hr*mg/L       aucint.inf.pred                hr*mg/L
#> 190                hr*mg/L      aucivint.inf.obs                hr*mg/L
#> 191                hr*mg/L     aucivint.inf.pred                hr*mg/L
#> 192                hr*mg/L          aucivinf.obs                hr*mg/L
#> 193                hr*mg/L       aucivinf.obs_se                hr*mg/L
#> 194                hr*mg/L         aucivinf.pred                hr*mg/L
#> 195              hr^2*mg/L              aumclast              hr^2*mg/L
#> 196              hr^2*mg/L           aumclast_se              hr^2*mg/L
#> 197              hr^2*mg/L               aumcall              hr^2*mg/L
#> 198              hr^2*mg/L            aumcall_se              hr^2*mg/L
#> 199              hr^2*mg/L          aumcint.last              hr^2*mg/L
#> 200              hr^2*mg/L           aumcint.all              hr^2*mg/L
#> 201              hr^2*mg/L        aumcivint.last              hr^2*mg/L
#> 202              hr^2*mg/L         aumcivint.all              hr^2*mg/L
#> 203              hr^2*mg/L       sparse_aumclast              hr^2*mg/L
#> 204              hr^2*mg/L        sparse_aumc_se              hr^2*mg/L
#> 205              hr^2*mg/L            aumcivlast              hr^2*mg/L
#> 206              hr^2*mg/L         aumcivlast_se              hr^2*mg/L
#> 207              hr^2*mg/L             aumcivall              hr^2*mg/L
#> 208              hr^2*mg/L          aumcivall_se              hr^2*mg/L
#> 209              hr^2*mg/L           aumcinf.obs              hr^2*mg/L
#> 210              hr^2*mg/L        aumcinf.obs_se              hr^2*mg/L
#> 211              hr^2*mg/L          aumcinf.pred              hr^2*mg/L
#> 212              hr^2*mg/L       aumcint.inf.obs              hr^2*mg/L
#> 213              hr^2*mg/L      aumcint.inf.pred              hr^2*mg/L
#> 214              hr^2*mg/L         aumcivinf.obs              hr^2*mg/L
#> 215              hr^2*mg/L      aumcivinf.obs_se              hr^2*mg/L
#> 216              hr^2*mg/L        aumcivinf.pred              hr^2*mg/L
#> 217                  mg/hr                 ermax                  mg/hr
#> 218                  mg/hr                 erint                  mg/hr
#> 219                  mg/hr                 erlst                  mg/hr
#> 220      (hr*mg/L)/(mg/kg)            auclast.dn      (hr*mg/L)/(mg/kg)
#> 221      (hr*mg/L)/(mg/kg)             aucall.dn      (hr*mg/L)/(mg/kg)
#> 222      (hr*mg/L)/(mg/kg)         aucinf.obs.dn      (hr*mg/L)/(mg/kg)
#> 223      (hr*mg/L)/(mg/kg)        aucinf.pred.dn      (hr*mg/L)/(mg/kg)
#> 224    (hr^2*mg/L)/(mg/kg)           aumclast.dn    (hr^2*mg/L)/(mg/kg)
#> 225    (hr^2*mg/L)/(mg/kg)            aumcall.dn    (hr^2*mg/L)/(mg/kg)
#> 226    (hr^2*mg/L)/(mg/kg)        aumcinf.obs.dn    (hr^2*mg/L)/(mg/kg)
#> 227    (hr^2*mg/L)/(mg/kg)       aumcinf.pred.dn    (hr^2*mg/L)/(mg/kg)
#> 228      (mg/kg)/(hr*mg/L)               cl.last      (mg/kg)/(hr*mg/L)
#> 229      (mg/kg)/(hr*mg/L)                cl.all      (mg/kg)/(hr*mg/L)
#> 230      (mg/kg)/(hr*mg/L)            cl.int.all      (mg/kg)/(hr*mg/L)
#> 231      (mg/kg)/(hr*mg/L)           cl.int.last      (mg/kg)/(hr*mg/L)
#> 232      (mg/kg)/(hr*mg/L)          cl.ivint.all      (mg/kg)/(hr*mg/L)
#> 233      (mg/kg)/(hr*mg/L)         cl.ivint.last      (mg/kg)/(hr*mg/L)
#> 234      (mg/kg)/(hr*mg/L)             cl.iv.all      (mg/kg)/(hr*mg/L)
#> 235      (mg/kg)/(hr*mg/L)            cl.iv.last      (mg/kg)/(hr*mg/L)
#> 236      (mg/kg)/(hr*mg/L)        cl.sparse.last      (mg/kg)/(hr*mg/L)
#> 237      (mg/kg)/(hr*mg/L)                cl.obs      (mg/kg)/(hr*mg/L)
#> 238      (mg/kg)/(hr*mg/L)               cl.pred      (mg/kg)/(hr*mg/L)
#> 239      (mg/kg)/(hr*mg/L)        cl.int.inf.obs      (mg/kg)/(hr*mg/L)
#> 240      (mg/kg)/(hr*mg/L)       cl.int.inf.pred      (mg/kg)/(hr*mg/L)
#> 241      (mg/kg)/(hr*mg/L)             cl.iv.obs      (mg/kg)/(hr*mg/L)
#> 242      (mg/kg)/(hr*mg/L)            cl.iv.pred      (mg/kg)/(hr*mg/L)
#> 243           mg/(hr*mg/L)              clr.last           mg/(hr*mg/L)
#> 244           mg/(hr*mg/L)               clr.obs           mg/(hr*mg/L)
#> 245           mg/(hr*mg/L)              clr.pred           mg/(hr*mg/L)
#> 246 (mg/(hr*mg/L))/(mg/kg)           clr.last.dn (mg/(hr*mg/L))/(mg/kg)
#> 247 (mg/(hr*mg/L))/(mg/kg)            clr.obs.dn (mg/(hr*mg/L))/(mg/kg)
#> 248 (mg/(hr*mg/L))/(mg/kg)           clr.pred.dn (mg/(hr*mg/L))/(mg/kg)
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
#> 103       0.007240029
#> 104       0.007240029
#> 105       0.007240029
#> 106       0.007240029
#> 107       0.007240029
#> 108       0.007240029
#> 109       0.007240029
#> 110       0.007240029
#> 111       0.007240029
#> 112       0.007240029
#> 113       0.007240029
#> 114       0.007240029
#> 115       0.007240029
#> 116       0.007240029
#> 117       0.007240029
#> 118       0.007240029
#> 119       0.007240029
#> 120       0.007240029
#> 121       0.007240029
#> 122       0.007240029
#> 123       0.007240029
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
#> 200       1.000000000
#> 201       1.000000000
#> 202       1.000000000
#> 203       1.000000000
#> 204       1.000000000
#> 205       1.000000000
#> 206       1.000000000
#> 207       1.000000000
#> 208       1.000000000
#> 209       1.000000000
#> 210       1.000000000
#> 211       1.000000000
#> 212       1.000000000
#> 213       1.000000000
#> 214       1.000000000
#> 215       1.000000000
#> 216       1.000000000
#> 217       1.000000000
#> 218       1.000000000
#> 219       1.000000000
#> 220       1.000000000
#> 221       1.000000000
#> 222       1.000000000
#> 223       1.000000000
#> 224       1.000000000
#> 225       1.000000000
#> 226       1.000000000
#> 227       1.000000000
#> 228       1.000000000
#> 229       1.000000000
#> 230       1.000000000
#> 231       1.000000000
#> 232       1.000000000
#> 233       1.000000000
#> 234       1.000000000
#> 235       1.000000000
#> 236       1.000000000
#> 237       1.000000000
#> 238       1.000000000
#> 239       1.000000000
#> 240       1.000000000
#> 241       1.000000000
#> 242       1.000000000
#> 243       1.000000000
#> 244       1.000000000
#> 245       1.000000000
#> 246       1.000000000
#> 247       1.000000000
#> 248       1.000000000

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
#> 6                  fraction                   ptr                 fraction
#> 7                  fraction            ratio.cmax                 fraction
#> 8                  fraction         ratio.auclast                 fraction
#> 9                  fraction     ratio.aucint.last                 fraction
#> 10                 fraction      ratio.aucint.all                 fraction
#> 11                 fraction            span.ratio                 fraction
#> 12                 fraction                f.last                 fraction
#> 13                 fraction            f.int.last                 fraction
#> 14                 fraction             f.int.all                 fraction
#> 15                 fraction                 f.obs                 fraction
#> 16                 fraction                f.pred                 fraction
#> 17                 fraction             f.int.obs                 fraction
#> 18                 fraction            f.int.pred                 fraction
#> 19                 fraction      ratio.aucinf.obs                 fraction
#> 20                 fraction     ratio.aucinf.pred                 fraction
#> 21                        %    aucivpbextint.last                        %
#> 22                        %     aucivpbextint.all                        %
#> 23                        %              deg.fluc                        %
#> 24                        %                 swing                        %
#> 25                        %        aucivpbextlast                        %
#> 26                        %         aucivpbextall                        %
#> 27                        %     aucivpbextinf.obs                        %
#> 28                        %    aucivpbextinf.pred                        %
#> 29                        %           aucpext.obs                        %
#> 30                        %          aucpext.pred                        %
#> 31                    count            auclast_df                    count
#> 32                    count             aucall_df                    count
#> 33                    count           aumclast_df                    count
#> 34                    count            aumcall_df                    count
#> 35                    count            count_conc                    count
#> 36                    count   count_conc_measured                    count
#> 37                    count         sparse_auc_df                    count
#> 38                    count        sparse_aumc_df                    count
#> 39                    count          aucivlast_df                    count
#> 40                    count           aucivall_df                    count
#> 41                    count         aumcivlast_df                    count
#> 42                    count          aumcivall_df                    count
#> 43                    count     lambda.z.n.points                    count
#> 44                    count lambda.z.n.points_blq                    count
#> 45                    count         aucinf.obs_df                    count
#> 46                    count        aumcinf.obs_df                    count
#> 47                    count       aucivinf.obs_df                    count
#> 48                    count      aumcivinf.obs_df                    count
#> 49                       hr                 start                      day
#> 50                       hr                   end                      day
#> 51                       hr                  tmax                      day
#> 52                       hr                  tmin                      day
#> 53                       hr                 tlast                      day
#> 54                       hr                tfirst                      day
#> 55                       hr              mrt.last                      day
#> 56                       hr               mrt.all                      day
#> 57                       hr           mrt.int.all                      day
#> 58                       hr          mrt.int.last                      day
#> 59                       hr           mrt.iv.last                      day
#> 60                       hr         mrt.ivint.all                      day
#> 61                       hr        mrt.ivint.last                      day
#> 62                       hr                  tlag                      day
#> 63                       hr                ertlst                      day
#> 64                       hr                ertmax                      day
#> 65                       hr            time_above                      day
#> 66                       hr             half.life                      day
#> 67                       hr   lambda.z.time.first                      day
#> 68                       hr    lambda.z.time.last                      day
#> 69                       hr        thalf.eff.last                      day
#> 70                       hr     thalf.eff.iv.last                      day
#> 71                       hr       mrt.sparse.last                      day
#> 72                       hr            mrt.iv.all                      day
#> 73                       hr               mrt.obs                      day
#> 74                       hr              mrt.pred                      day
#> 75                       hr       mrt.int.inf.obs                      day
#> 76                       hr      mrt.int.inf.pred                      day
#> 77                       hr            mrt.iv.obs                      day
#> 78                       hr           mrt.iv.pred                      day
#> 79                       hr            mrt.md.obs                      day
#> 80                       hr           mrt.md.pred                      day
#> 81                       hr          mrt.ivmd.obs                      day
#> 82                       hr         mrt.ivmd.pred                      day
#> 83                       hr         thalf.eff.obs                      day
#> 84                       hr        thalf.eff.pred                      day
#> 85                       hr      thalf.eff.iv.obs                      day
#> 86                       hr     thalf.eff.iv.pred                      day
#> 87                     1/hr              lambda.z                    1/day
#> 88                     1/hr              kel.last                    1/day
#> 89                     1/hr           kel.iv.last                    1/day
#> 90                     1/hr               kel.all                    1/day
#> 91                     1/hr           kel.int.all                    1/day
#> 92                     1/hr          kel.int.last                    1/day
#> 93                     1/hr         kel.ivint.all                    1/day
#> 94                     1/hr        kel.ivint.last                    1/day
#> 95                     1/hr            kel.iv.all                    1/day
#> 96                     1/hr       kel.sparse.last                    1/day
#> 97                     1/hr               kel.obs                    1/day
#> 98                     1/hr              kel.pred                    1/day
#> 99                     1/hr            kel.iv.obs                    1/day
#> 100                    1/hr           kel.iv.pred                    1/day
#> 101                    1/hr       kel.int.inf.obs                    1/day
#> 102                    1/hr      kel.int.inf.pred                    1/day
#> 103                   ng/mL                    c0                    ng/mL
#> 104                   ng/mL                  cmax                    ng/mL
#> 105                   ng/mL                  cmin                    ng/mL
#> 106                   ng/mL             clast.obs                    ng/mL
#> 107                   ng/mL                   cav                    ng/mL
#> 108                   ng/mL              cav.last                    ng/mL
#> 109                   ng/mL          cav.int.last                    ng/mL
#> 110                   ng/mL           cav.int.all                    ng/mL
#> 111                   ng/mL               cav.all                    ng/mL
#> 112                   ng/mL        cav.ivint.last                    ng/mL
#> 113                   ng/mL         cav.ivint.all                    ng/mL
#> 114                   ng/mL               ctrough                    ng/mL
#> 115                   ng/mL                cstart                    ng/mL
#> 116                   ng/mL                  ceoi                    ng/mL
#> 117                   ng/mL            clast.pred                    ng/mL
#> 118                   ng/mL           cav.iv.last                    ng/mL
#> 119                   ng/mL            cav.iv.all                    ng/mL
#> 120                   ng/mL       cav.int.inf.obs                    ng/mL
#> 121                   ng/mL      cav.int.inf.pred                    ng/mL
#> 122                   ng/mL     cav.ivint.inf.obs                    ng/mL
#> 123                   ng/mL    cav.ivint.inf.pred                    ng/mL
#> 124                      mg                    ae                       mg
#> 125              mg/(mg/kg)                    fe               mg/(mg/kg)
#> 126                   mg/kg               totdose                    mg/kg
#> 127         (ng/mL)/(mg/kg)               cmax.dn          (ng/mL)/(mg/kg)
#> 128         (ng/mL)/(mg/kg)               cmin.dn          (ng/mL)/(mg/kg)
#> 129         (ng/mL)/(mg/kg)          clast.obs.dn          (ng/mL)/(mg/kg)
#> 130         (ng/mL)/(mg/kg)         clast.pred.dn          (ng/mL)/(mg/kg)
#> 131         (ng/mL)/(mg/kg)                cav.dn          (ng/mL)/(mg/kg)
#> 132         (ng/mL)/(mg/kg)           cav.last.dn          (ng/mL)/(mg/kg)
#> 133         (ng/mL)/(mg/kg)            ctrough.dn          (ng/mL)/(mg/kg)
#> 134         (mg/kg)/(ng/mL)              vss.last          (mg/kg)/(ng/mL)
#> 135         (mg/kg)/(ng/mL)           vss.iv.last          (mg/kg)/(ng/mL)
#> 136         (mg/kg)/(ng/mL)               vss.all          (mg/kg)/(ng/mL)
#> 137         (mg/kg)/(ng/mL)           vss.int.all          (mg/kg)/(ng/mL)
#> 138         (mg/kg)/(ng/mL)          vss.int.last          (mg/kg)/(ng/mL)
#> 139         (mg/kg)/(ng/mL)         vss.ivint.all          (mg/kg)/(ng/mL)
#> 140         (mg/kg)/(ng/mL)        vss.ivint.last          (mg/kg)/(ng/mL)
#> 141         (mg/kg)/(ng/mL)                 volpk          (mg/kg)/(ng/mL)
#> 142         (mg/kg)/(ng/mL)                vz.all          (mg/kg)/(ng/mL)
#> 143         (mg/kg)/(ng/mL)            vz.int.all          (mg/kg)/(ng/mL)
#> 144         (mg/kg)/(ng/mL)           vz.int.last          (mg/kg)/(ng/mL)
#> 145         (mg/kg)/(ng/mL)             vz.iv.all          (mg/kg)/(ng/mL)
#> 146         (mg/kg)/(ng/mL)            vz.iv.last          (mg/kg)/(ng/mL)
#> 147         (mg/kg)/(ng/mL)          vz.ivint.all          (mg/kg)/(ng/mL)
#> 148         (mg/kg)/(ng/mL)         vz.ivint.last          (mg/kg)/(ng/mL)
#> 149         (mg/kg)/(ng/mL)               vz.last          (mg/kg)/(ng/mL)
#> 150         (mg/kg)/(ng/mL)            vss.iv.all          (mg/kg)/(ng/mL)
#> 151         (mg/kg)/(ng/mL)       vss.sparse.last          (mg/kg)/(ng/mL)
#> 152         (mg/kg)/(ng/mL)                vz.obs          (mg/kg)/(ng/mL)
#> 153         (mg/kg)/(ng/mL)               vz.pred          (mg/kg)/(ng/mL)
#> 154         (mg/kg)/(ng/mL)        vz.int.inf.obs          (mg/kg)/(ng/mL)
#> 155         (mg/kg)/(ng/mL)       vz.int.inf.pred          (mg/kg)/(ng/mL)
#> 156         (mg/kg)/(ng/mL)             vz.iv.obs          (mg/kg)/(ng/mL)
#> 157         (mg/kg)/(ng/mL)            vz.iv.pred          (mg/kg)/(ng/mL)
#> 158         (mg/kg)/(ng/mL)        vz.sparse.last          (mg/kg)/(ng/mL)
#> 159         (mg/kg)/(ng/mL)               vss.obs          (mg/kg)/(ng/mL)
#> 160         (mg/kg)/(ng/mL)              vss.pred          (mg/kg)/(ng/mL)
#> 161         (mg/kg)/(ng/mL)            vss.iv.obs          (mg/kg)/(ng/mL)
#> 162         (mg/kg)/(ng/mL)           vss.iv.pred          (mg/kg)/(ng/mL)
#> 163         (mg/kg)/(ng/mL)            vss.md.obs          (mg/kg)/(ng/mL)
#> 164         (mg/kg)/(ng/mL)           vss.md.pred          (mg/kg)/(ng/mL)
#> 165         (mg/kg)/(ng/mL)          vss.ivmd.obs          (mg/kg)/(ng/mL)
#> 166         (mg/kg)/(ng/mL)         vss.ivmd.pred          (mg/kg)/(ng/mL)
#> 167         (mg/kg)/(ng/mL)       vss.int.inf.obs          (mg/kg)/(ng/mL)
#> 168         (mg/kg)/(ng/mL)      vss.int.inf.pred          (mg/kg)/(ng/mL)
#> 169                hr*ng/mL               auclast                day*ng/mL
#> 170                hr*ng/mL            auclast_se                day*ng/mL
#> 171                hr*ng/mL                aucall                day*ng/mL
#> 172                hr*ng/mL             aucall_se                day*ng/mL
#> 173                hr*ng/mL           aucint.last                day*ng/mL
#> 174                hr*ng/mL            aucint.all                day*ng/mL
#> 175                hr*ng/mL         aucivint.last                day*ng/mL
#> 176                hr*ng/mL          aucivint.all                day*ng/mL
#> 177                hr*ng/mL  aucabove.predose.all                day*ng/mL
#> 178                hr*ng/mL   aucabove.trough.all                day*ng/mL
#> 179                hr*ng/mL        sparse_auclast                day*ng/mL
#> 180                hr*ng/mL         sparse_auc_se                day*ng/mL
#> 181                hr*ng/mL             aucivlast                day*ng/mL
#> 182                hr*ng/mL          aucivlast_se                day*ng/mL
#> 183                hr*ng/mL              aucivall                day*ng/mL
#> 184                hr*ng/mL           aucivall_se                day*ng/mL
#> 185                hr*ng/mL            aucinf.obs                day*ng/mL
#> 186                hr*ng/mL         aucinf.obs_se                day*ng/mL
#> 187                hr*ng/mL           aucinf.pred                day*ng/mL
#> 188                hr*ng/mL        aucint.inf.obs                day*ng/mL
#> 189                hr*ng/mL       aucint.inf.pred                day*ng/mL
#> 190                hr*ng/mL      aucivint.inf.obs                day*ng/mL
#> 191                hr*ng/mL     aucivint.inf.pred                day*ng/mL
#> 192                hr*ng/mL          aucivinf.obs                day*ng/mL
#> 193                hr*ng/mL       aucivinf.obs_se                day*ng/mL
#> 194                hr*ng/mL         aucivinf.pred                day*ng/mL
#> 195              hr^2*ng/mL              aumclast              day^2*ng/mL
#> 196              hr^2*ng/mL           aumclast_se              day^2*ng/mL
#> 197              hr^2*ng/mL               aumcall              day^2*ng/mL
#> 198              hr^2*ng/mL            aumcall_se              day^2*ng/mL
#> 199              hr^2*ng/mL          aumcint.last              day^2*ng/mL
#> 200              hr^2*ng/mL           aumcint.all              day^2*ng/mL
#> 201              hr^2*ng/mL        aumcivint.last              day^2*ng/mL
#> 202              hr^2*ng/mL         aumcivint.all              day^2*ng/mL
#> 203              hr^2*ng/mL       sparse_aumclast              day^2*ng/mL
#> 204              hr^2*ng/mL        sparse_aumc_se              day^2*ng/mL
#> 205              hr^2*ng/mL            aumcivlast              day^2*ng/mL
#> 206              hr^2*ng/mL         aumcivlast_se              day^2*ng/mL
#> 207              hr^2*ng/mL             aumcivall              day^2*ng/mL
#> 208              hr^2*ng/mL          aumcivall_se              day^2*ng/mL
#> 209              hr^2*ng/mL           aumcinf.obs              day^2*ng/mL
#> 210              hr^2*ng/mL        aumcinf.obs_se              day^2*ng/mL
#> 211              hr^2*ng/mL          aumcinf.pred              day^2*ng/mL
#> 212              hr^2*ng/mL       aumcint.inf.obs              day^2*ng/mL
#> 213              hr^2*ng/mL      aumcint.inf.pred              day^2*ng/mL
#> 214              hr^2*ng/mL         aumcivinf.obs              day^2*ng/mL
#> 215              hr^2*ng/mL      aumcivinf.obs_se              day^2*ng/mL
#> 216              hr^2*ng/mL        aumcivinf.pred              day^2*ng/mL
#> 217                   mg/hr                 ermax                   mg/day
#> 218                   mg/hr                 erint                   mg/day
#> 219                   mg/hr                 erlst                   mg/day
#> 220      (hr*ng/mL)/(mg/kg)            auclast.dn      (day*ng/mL)/(mg/kg)
#> 221      (hr*ng/mL)/(mg/kg)             aucall.dn      (day*ng/mL)/(mg/kg)
#> 222      (hr*ng/mL)/(mg/kg)         aucinf.obs.dn      (day*ng/mL)/(mg/kg)
#> 223      (hr*ng/mL)/(mg/kg)        aucinf.pred.dn      (day*ng/mL)/(mg/kg)
#> 224    (hr^2*ng/mL)/(mg/kg)           aumclast.dn    (day^2*ng/mL)/(mg/kg)
#> 225    (hr^2*ng/mL)/(mg/kg)            aumcall.dn    (day^2*ng/mL)/(mg/kg)
#> 226    (hr^2*ng/mL)/(mg/kg)        aumcinf.obs.dn    (day^2*ng/mL)/(mg/kg)
#> 227    (hr^2*ng/mL)/(mg/kg)       aumcinf.pred.dn    (day^2*ng/mL)/(mg/kg)
#> 228      (mg/kg)/(hr*ng/mL)               cl.last      (mg/kg)/(day*ng/mL)
#> 229      (mg/kg)/(hr*ng/mL)                cl.all      (mg/kg)/(day*ng/mL)
#> 230      (mg/kg)/(hr*ng/mL)            cl.int.all      (mg/kg)/(day*ng/mL)
#> 231      (mg/kg)/(hr*ng/mL)           cl.int.last      (mg/kg)/(day*ng/mL)
#> 232      (mg/kg)/(hr*ng/mL)          cl.ivint.all      (mg/kg)/(day*ng/mL)
#> 233      (mg/kg)/(hr*ng/mL)         cl.ivint.last      (mg/kg)/(day*ng/mL)
#> 234      (mg/kg)/(hr*ng/mL)             cl.iv.all      (mg/kg)/(day*ng/mL)
#> 235      (mg/kg)/(hr*ng/mL)            cl.iv.last      (mg/kg)/(day*ng/mL)
#> 236      (mg/kg)/(hr*ng/mL)        cl.sparse.last      (mg/kg)/(day*ng/mL)
#> 237      (mg/kg)/(hr*ng/mL)                cl.obs      (mg/kg)/(day*ng/mL)
#> 238      (mg/kg)/(hr*ng/mL)               cl.pred      (mg/kg)/(day*ng/mL)
#> 239      (mg/kg)/(hr*ng/mL)        cl.int.inf.obs      (mg/kg)/(day*ng/mL)
#> 240      (mg/kg)/(hr*ng/mL)       cl.int.inf.pred      (mg/kg)/(day*ng/mL)
#> 241      (mg/kg)/(hr*ng/mL)             cl.iv.obs      (mg/kg)/(day*ng/mL)
#> 242      (mg/kg)/(hr*ng/mL)            cl.iv.pred      (mg/kg)/(day*ng/mL)
#> 243           mg/(hr*ng/mL)              clr.last           mg/(day*ng/mL)
#> 244           mg/(hr*ng/mL)               clr.obs           mg/(day*ng/mL)
#> 245           mg/(hr*ng/mL)              clr.pred           mg/(day*ng/mL)
#> 246 (mg/(hr*ng/mL))/(mg/kg)           clr.last.dn (mg/(day*ng/mL))/(mg/kg)
#> 247 (mg/(hr*ng/mL))/(mg/kg)            clr.obs.dn (mg/(day*ng/mL))/(mg/kg)
#> 248 (mg/(hr*ng/mL))/(mg/kg)           clr.pred.dn (mg/(day*ng/mL))/(mg/kg)
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
#> 49        0.041666667
#> 50        0.041666667
#> 51        0.041666667
#> 52        0.041666667
#> 53        0.041666667
#> 54        0.041666667
#> 55        0.041666667
#> 56        0.041666667
#> 57        0.041666667
#> 58        0.041666667
#> 59        0.041666667
#> 60        0.041666667
#> 61        0.041666667
#> 62        0.041666667
#> 63        0.041666667
#> 64        0.041666667
#> 65        0.041666667
#> 66        0.041666667
#> 67        0.041666667
#> 68        0.041666667
#> 69        0.041666667
#> 70        0.041666667
#> 71        0.041666667
#> 72        0.041666667
#> 73        0.041666667
#> 74        0.041666667
#> 75        0.041666667
#> 76        0.041666667
#> 77        0.041666667
#> 78        0.041666667
#> 79        0.041666667
#> 80        0.041666667
#> 81        0.041666667
#> 82        0.041666667
#> 83        0.041666667
#> 84        0.041666667
#> 85        0.041666667
#> 86        0.041666667
#> 87       24.000000000
#> 88       24.000000000
#> 89       24.000000000
#> 90       24.000000000
#> 91       24.000000000
#> 92       24.000000000
#> 93       24.000000000
#> 94       24.000000000
#> 95       24.000000000
#> 96       24.000000000
#> 97       24.000000000
#> 98       24.000000000
#> 99       24.000000000
#> 100      24.000000000
#> 101      24.000000000
#> 102      24.000000000
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
#> 169       0.041666667
#> 170       0.041666667
#> 171       0.041666667
#> 172       0.041666667
#> 173       0.041666667
#> 174       0.041666667
#> 175       0.041666667
#> 176       0.041666667
#> 177       0.041666667
#> 178       0.041666667
#> 179       0.041666667
#> 180       0.041666667
#> 181       0.041666667
#> 182       0.041666667
#> 183       0.041666667
#> 184       0.041666667
#> 185       0.041666667
#> 186       0.041666667
#> 187       0.041666667
#> 188       0.041666667
#> 189       0.041666667
#> 190       0.041666667
#> 191       0.041666667
#> 192       0.041666667
#> 193       0.041666667
#> 194       0.041666667
#> 195       0.001736111
#> 196       0.001736111
#> 197       0.001736111
#> 198       0.001736111
#> 199       0.001736111
#> 200       0.001736111
#> 201       0.001736111
#> 202       0.001736111
#> 203       0.001736111
#> 204       0.001736111
#> 205       0.001736111
#> 206       0.001736111
#> 207       0.001736111
#> 208       0.001736111
#> 209       0.001736111
#> 210       0.001736111
#> 211       0.001736111
#> 212       0.001736111
#> 213       0.001736111
#> 214       0.001736111
#> 215       0.001736111
#> 216       0.001736111
#> 217      24.000000000
#> 218      24.000000000
#> 219      24.000000000
#> 220       0.041666667
#> 221       0.041666667
#> 222       0.041666667
#> 223       0.041666667
#> 224       0.001736111
#> 225       0.001736111
#> 226       0.001736111
#> 227       0.001736111
#> 228      24.000000000
#> 229      24.000000000
#> 230      24.000000000
#> 231      24.000000000
#> 232      24.000000000
#> 233      24.000000000
#> 234      24.000000000
#> 235      24.000000000
#> 236      24.000000000
#> 237      24.000000000
#> 238      24.000000000
#> 239      24.000000000
#> 240      24.000000000
#> 241      24.000000000
#> 242      24.000000000
#> 243      24.000000000
#> 244      24.000000000
#> 245      24.000000000
#> 246      24.000000000
#> 247      24.000000000
#> 248      24.000000000
```
