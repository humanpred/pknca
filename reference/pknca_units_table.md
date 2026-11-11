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
#>     PPORRESU                 PPTESTCD
#> 1   unitless                r.squared
#> 2   unitless            adj.r.squared
#> 3   unitless          lambda.z.corrxy
#> 4   unitless           tobit.residual
#> 5   unitless       adj.tobit.residual
#> 6   unitless       adj_tobit_residual
#> 7   unitless           tobit_residual
#> 8   fraction                      ptr
#> 9   fraction               ratio.cmax
#> 10  fraction            ratio.auclast
#> 11  fraction        ratio.aucint.last
#> 12  fraction         ratio.aucint.all
#> 13  fraction               span.ratio
#> 14  fraction                   f.last
#> 15  fraction                    f.all
#> 16  fraction               f.int.last
#> 17  fraction                f.int.all
#> 18  fraction                f.inf.obs
#> 19  fraction               f.inf.pred
#> 20  fraction            f.int.inf.obs
#> 21  fraction           f.int.inf.pred
#> 22  fraction         ratio.aucinf.obs
#> 23  fraction        ratio.aucinf.pred
#> 24  fraction                f.int.obs
#> 25  fraction               f.int.pred
#> 26  fraction                    f.obs
#> 27  fraction                   f.pred
#> 28         %      aucivpbext.int.last
#> 29         %       aucivpbext.int.all
#> 30         %                 deg.fluc
#> 31         %                    swing
#> 32         %          aucivpbext.last
#> 33         %           aucivpbext.all
#> 34         %       aucivpbext.inf.obs
#> 35         %      aucivpbext.inf.pred
#> 36         %          aucpext.inf.obs
#> 37         %         aucpext.inf.pred
#> 38         %            aucivpbextall
#> 39         %        aucivpbextinf.obs
#> 40         %       aucivpbextinf.pred
#> 41         %        aucivpbextint.all
#> 42         %       aucivpbextint.last
#> 43         %           aucivpbextlast
#> 44         %              aucpext.obs
#> 45         %             aucpext.pred
#> 46     count               auclast_df
#> 47     count                aucall_df
#> 48     count              aumclast_df
#> 49     count               aumcall_df
#> 50     count               count.conc
#> 51     count      count.conc.measured
#> 52     count            sparse_auc_df
#> 53     count           sparse_aumc_df
#> 54     count             aucivlast_df
#> 55     count              aucivall_df
#> 56     count            aumcivlast_df
#> 57     count             aumcivall_df
#> 58     count        lambda.z.n.points
#> 59     count    lambda.z.n.points.blq
#> 60     count            aucinf.obs_df
#> 61     count           aumcinf.obs_df
#> 62     count          aucivinf.obs_df
#> 63     count         aumcivinf.obs_df
#> 64     count               count_conc
#> 65     count      count_conc_measured
#> 66     count    lambda.z.n.points_blq
#> 67      <NA>                    start
#> 68      <NA>                      end
#> 69      <NA>                     tmax
#> 70      <NA>                     tmin
#> 71      <NA>                    tlast
#> 72      <NA>                   tfirst
#> 73      <NA>                 mrt.last
#> 74      <NA>                  mrt.all
#> 75      <NA>              mrt.int.all
#> 76      <NA>             mrt.int.last
#> 77      <NA>              mrt.iv.last
#> 78      <NA>            mrt.ivint.all
#> 79      <NA>           mrt.ivint.last
#> 80      <NA>                     tlag
#> 81      <NA>                   ertlst
#> 82      <NA>                   ertmax
#> 83      <NA>               time.above
#> 84      <NA>                half.life
#> 85      <NA>      lambda.z.time.first
#> 86      <NA>       lambda.z.time.last
#> 87      <NA>           thalf.eff.last
#> 88      <NA>        thalf.eff.int.all
#> 89      <NA>       thalf.eff.int.last
#> 90      <NA>            thalf.eff.all
#> 91      <NA>        thalf.eff.iv.last
#> 92      <NA>      thalf.eff.ivint.all
#> 93      <NA>     thalf.eff.ivint.last
#> 94      <NA>          mrt.sparse.last
#> 95      <NA>               mrt.iv.all
#> 96      <NA>         thalf.eff.iv.all
#> 97      <NA>              mrt.inf.obs
#> 98      <NA>             mrt.inf.pred
#> 99      <NA>          mrt.int.inf.obs
#> 100     <NA>         mrt.int.inf.pred
#> 101     <NA>           mrt.iv.inf.obs
#> 102     <NA>          mrt.iv.inf.pred
#> 103     <NA>       mrt.ivint.inf.pred
#> 104     <NA>        mrt.ivint.inf.obs
#> 105     <NA>           mrt.md.inf.obs
#> 106     <NA>          mrt.md.inf.pred
#> 107     <NA>         mrt.ivmd.inf.obs
#> 108     <NA>        mrt.ivmd.inf.pred
#> 109     <NA>        thalf.eff.inf.obs
#> 110     <NA>       thalf.eff.inf.pred
#> 111     <NA>   thalf.eff.int.inf.pred
#> 112     <NA>    thalf.eff.int.inf.obs
#> 113     <NA>     thalf.eff.iv.inf.obs
#> 114     <NA>    thalf.eff.iv.inf.pred
#> 115     <NA> thalf.eff.ivint.inf.pred
#> 116     <NA>  thalf.eff.ivint.inf.obs
#> 117     <NA>               mrt.iv.obs
#> 118     <NA>              mrt.iv.pred
#> 119     <NA>             mrt.ivmd.obs
#> 120     <NA>            mrt.ivmd.pred
#> 121     <NA>               mrt.md.obs
#> 122     <NA>              mrt.md.pred
#> 123     <NA>                  mrt.obs
#> 124     <NA>                 mrt.pred
#> 125     <NA>         thalf.eff.iv.obs
#> 126     <NA>        thalf.eff.iv.pred
#> 127     <NA>            thalf.eff.obs
#> 128     <NA>           thalf.eff.pred
#> 129     <NA>               time_above
#> 130     <NA>                 lambda.z
#> 131     <NA>                 kel.last
#> 132     <NA>              kel.iv.last
#> 133     <NA>                  kel.all
#> 134     <NA>              kel.int.all
#> 135     <NA>             kel.int.last
#> 136     <NA>            kel.ivint.all
#> 137     <NA>           kel.ivint.last
#> 138     <NA>               kel.iv.all
#> 139     <NA>          kel.sparse.last
#> 140     <NA>              kel.inf.obs
#> 141     <NA>             kel.inf.pred
#> 142     <NA>           kel.iv.inf.obs
#> 143     <NA>          kel.iv.inf.pred
#> 144     <NA>          kel.int.inf.obs
#> 145     <NA>         kel.int.inf.pred
#> 146     <NA>       kel.ivint.inf.pred
#> 147     <NA>        kel.ivint.inf.obs
#> 148     <NA>               kel.iv.obs
#> 149     <NA>              kel.iv.pred
#> 150     <NA>                  kel.obs
#> 151     <NA>                 kel.pred
#> 152     <NA>                       c0
#> 153     <NA>                     cmax
#> 154     <NA>                     cmin
#> 155     <NA>                clast.obs
#> 156     <NA>                 cav.last
#> 157     <NA>             cav.int.last
#> 158     <NA>              cav.int.all
#> 159     <NA>                  cav.all
#> 160     <NA>           cav.ivint.last
#> 161     <NA>            cav.ivint.all
#> 162     <NA>                  ctrough
#> 163     <NA>                   cstart
#> 164     <NA>                     ceoi
#> 165     <NA>               clast.pred
#> 166     <NA>              cav.iv.last
#> 167     <NA>               cav.iv.all
#> 168     <NA>          cav.int.inf.obs
#> 169     <NA>         cav.int.inf.pred
#> 170     <NA>        cav.ivint.inf.obs
#> 171     <NA>       cav.ivint.inf.pred
#> 172     <NA>                      cav
#> 173     <NA>                       ae
#> 174     <NA>                       fe
#> 175     <NA>                  totdose
#> 176     <NA>                  cmax.dn
#> 177     <NA>                  cmin.dn
#> 178     <NA>             clast.obs.dn
#> 179     <NA>            clast.pred.dn
#> 180     <NA>              cav.last.dn
#> 181     <NA>               ctrough.dn
#> 182     <NA>                   cav.dn
#> 183     <NA>                 vss.last
#> 184     <NA>              vss.iv.last
#> 185     <NA>                  vss.all
#> 186     <NA>              vss.int.all
#> 187     <NA>             vss.int.last
#> 188     <NA>            vss.ivint.all
#> 189     <NA>           vss.ivint.last
#> 190     <NA>                    volpk
#> 191     <NA>                   vz.all
#> 192     <NA>               vz.int.all
#> 193     <NA>              vz.int.last
#> 194     <NA>                vz.iv.all
#> 195     <NA>               vz.iv.last
#> 196     <NA>             vz.ivint.all
#> 197     <NA>            vz.ivint.last
#> 198     <NA>                  vz.last
#> 199     <NA>               vss.iv.all
#> 200     <NA>          vss.sparse.last
#> 201     <NA>               vz.inf.obs
#> 202     <NA>              vz.inf.pred
#> 203     <NA>           vz.int.inf.obs
#> 204     <NA>          vz.int.inf.pred
#> 205     <NA>            vz.iv.inf.obs
#> 206     <NA>           vz.iv.inf.pred
#> 207     <NA>        vz.ivint.inf.pred
#> 208     <NA>         vz.ivint.inf.obs
#> 209     <NA>           vz.sparse.last
#> 210     <NA>              vss.inf.obs
#> 211     <NA>             vss.inf.pred
#> 212     <NA>           vss.iv.inf.obs
#> 213     <NA>          vss.iv.inf.pred
#> 214     <NA>           vss.md.inf.obs
#> 215     <NA>          vss.md.inf.pred
#> 216     <NA>         vss.ivmd.inf.obs
#> 217     <NA>        vss.ivmd.inf.pred
#> 218     <NA>          vss.int.inf.obs
#> 219     <NA>         vss.int.inf.pred
#> 220     <NA>       vss.ivint.inf.pred
#> 221     <NA>        vss.ivint.inf.obs
#> 222     <NA>               vss.iv.obs
#> 223     <NA>              vss.iv.pred
#> 224     <NA>             vss.ivmd.obs
#> 225     <NA>            vss.ivmd.pred
#> 226     <NA>               vss.md.obs
#> 227     <NA>              vss.md.pred
#> 228     <NA>                  vss.obs
#> 229     <NA>                 vss.pred
#> 230     <NA>                vz.iv.obs
#> 231     <NA>               vz.iv.pred
#> 232     <NA>                   vz.obs
#> 233     <NA>                  vz.pred
#> 234     <NA>                  auclast
#> 235     <NA>               auclast_se
#> 236     <NA>                   aucall
#> 237     <NA>                aucall_se
#> 238     <NA>              aucint.last
#> 239     <NA>               aucint.all
#> 240     <NA>            aucivint.last
#> 241     <NA>             aucivint.all
#> 242     <NA>     aucabove.predose.all
#> 243     <NA>      aucabove.trough.all
#> 244     <NA>           sparse_auclast
#> 245     <NA>            sparse_auc_se
#> 246     <NA>                aucivlast
#> 247     <NA>             aucivlast_se
#> 248     <NA>                 aucivall
#> 249     <NA>              aucivall_se
#> 250     <NA>               aucinf.obs
#> 251     <NA>            aucinf.obs_se
#> 252     <NA>              aucinf.pred
#> 253     <NA>           aucint.inf.obs
#> 254     <NA>          aucint.inf.pred
#> 255     <NA>         aucivint.inf.obs
#> 256     <NA>        aucivint.inf.pred
#> 257     <NA>             aucivinf.obs
#> 258     <NA>          aucivinf.obs_se
#> 259     <NA>            aucivinf.pred
#> 260     <NA>                 aumclast
#> 261     <NA>              aumclast_se
#> 262     <NA>                  aumcall
#> 263     <NA>               aumcall_se
#> 264     <NA>             aumcint.last
#> 265     <NA>              aumcint.all
#> 266     <NA>           aumcivint.last
#> 267     <NA>            aumcivint.all
#> 268     <NA>          sparse_aumclast
#> 269     <NA>           sparse_aumc_se
#> 270     <NA>               aumcivlast
#> 271     <NA>            aumcivlast_se
#> 272     <NA>                aumcivall
#> 273     <NA>             aumcivall_se
#> 274     <NA>              aumcinf.obs
#> 275     <NA>           aumcinf.obs_se
#> 276     <NA>             aumcinf.pred
#> 277     <NA>          aumcint.inf.obs
#> 278     <NA>         aumcint.inf.pred
#> 279     <NA>       aumcivint.inf.pred
#> 280     <NA>        aumcivint.inf.obs
#> 281     <NA>            aumcivinf.obs
#> 282     <NA>         aumcivinf.obs_se
#> 283     <NA>           aumcivinf.pred
#> 284     <NA>                    ermax
#> 285     <NA>                    erint
#> 286     <NA>                    erlst
#> 287     <NA>               auclast.dn
#> 288     <NA>                aucall.dn
#> 289     <NA>            aucinf.obs.dn
#> 290     <NA>           aucinf.pred.dn
#> 291     <NA>              aumclast.dn
#> 292     <NA>               aumcall.dn
#> 293     <NA>           aumcinf.obs.dn
#> 294     <NA>          aumcinf.pred.dn
#> 295     <NA>                  cl.last
#> 296     <NA>                   cl.all
#> 297     <NA>               cl.int.all
#> 298     <NA>              cl.int.last
#> 299     <NA>             cl.ivint.all
#> 300     <NA>            cl.ivint.last
#> 301     <NA>                cl.iv.all
#> 302     <NA>               cl.iv.last
#> 303     <NA>           cl.sparse.last
#> 304     <NA>               cl.inf.obs
#> 305     <NA>              cl.inf.pred
#> 306     <NA>           cl.int.inf.obs
#> 307     <NA>          cl.int.inf.pred
#> 308     <NA>            cl.iv.inf.obs
#> 309     <NA>           cl.iv.inf.pred
#> 310     <NA>        cl.ivint.inf.pred
#> 311     <NA>         cl.ivint.inf.obs
#> 312     <NA>                cl.iv.obs
#> 313     <NA>               cl.iv.pred
#> 314     <NA>                   cl.obs
#> 315     <NA>                  cl.pred
#> 316     <NA>                 clr.last
#> 317     <NA>         clr.int.inf.pred
#> 318     <NA>          clr.int.inf.obs
#> 319     <NA>              clr.int.all
#> 320     <NA>             clr.int.last
#> 321     <NA>                  clr.all
#> 322     <NA>              clr.inf.obs
#> 323     <NA>             clr.inf.pred
#> 324     <NA>                  clr.obs
#> 325     <NA>                 clr.pred
pknca_units_table(
  concu="ng/mL", doseu="mg/kg", amountu="mg", timeu="hr"
)
#>                 PPORRESU                 PPTESTCD
#> 1               unitless                r.squared
#> 2               unitless            adj.r.squared
#> 3               unitless          lambda.z.corrxy
#> 4               unitless           tobit.residual
#> 5               unitless       adj.tobit.residual
#> 6               unitless       adj_tobit_residual
#> 7               unitless           tobit_residual
#> 8               fraction                      ptr
#> 9               fraction               ratio.cmax
#> 10              fraction            ratio.auclast
#> 11              fraction        ratio.aucint.last
#> 12              fraction         ratio.aucint.all
#> 13              fraction               span.ratio
#> 14              fraction                   f.last
#> 15              fraction                    f.all
#> 16              fraction               f.int.last
#> 17              fraction                f.int.all
#> 18              fraction                f.inf.obs
#> 19              fraction               f.inf.pred
#> 20              fraction            f.int.inf.obs
#> 21              fraction           f.int.inf.pred
#> 22              fraction         ratio.aucinf.obs
#> 23              fraction        ratio.aucinf.pred
#> 24              fraction                f.int.obs
#> 25              fraction               f.int.pred
#> 26              fraction                    f.obs
#> 27              fraction                   f.pred
#> 28                     %      aucivpbext.int.last
#> 29                     %       aucivpbext.int.all
#> 30                     %                 deg.fluc
#> 31                     %                    swing
#> 32                     %          aucivpbext.last
#> 33                     %           aucivpbext.all
#> 34                     %       aucivpbext.inf.obs
#> 35                     %      aucivpbext.inf.pred
#> 36                     %          aucpext.inf.obs
#> 37                     %         aucpext.inf.pred
#> 38                     %            aucivpbextall
#> 39                     %        aucivpbextinf.obs
#> 40                     %       aucivpbextinf.pred
#> 41                     %        aucivpbextint.all
#> 42                     %       aucivpbextint.last
#> 43                     %           aucivpbextlast
#> 44                     %              aucpext.obs
#> 45                     %             aucpext.pred
#> 46                 count               auclast_df
#> 47                 count                aucall_df
#> 48                 count              aumclast_df
#> 49                 count               aumcall_df
#> 50                 count               count.conc
#> 51                 count      count.conc.measured
#> 52                 count            sparse_auc_df
#> 53                 count           sparse_aumc_df
#> 54                 count             aucivlast_df
#> 55                 count              aucivall_df
#> 56                 count            aumcivlast_df
#> 57                 count             aumcivall_df
#> 58                 count        lambda.z.n.points
#> 59                 count    lambda.z.n.points.blq
#> 60                 count            aucinf.obs_df
#> 61                 count           aumcinf.obs_df
#> 62                 count          aucivinf.obs_df
#> 63                 count         aumcivinf.obs_df
#> 64                 count               count_conc
#> 65                 count      count_conc_measured
#> 66                 count    lambda.z.n.points_blq
#> 67                    hr                    start
#> 68                    hr                      end
#> 69                    hr                     tmax
#> 70                    hr                     tmin
#> 71                    hr                    tlast
#> 72                    hr                   tfirst
#> 73                    hr                 mrt.last
#> 74                    hr                  mrt.all
#> 75                    hr              mrt.int.all
#> 76                    hr             mrt.int.last
#> 77                    hr              mrt.iv.last
#> 78                    hr            mrt.ivint.all
#> 79                    hr           mrt.ivint.last
#> 80                    hr                     tlag
#> 81                    hr                   ertlst
#> 82                    hr                   ertmax
#> 83                    hr               time.above
#> 84                    hr                half.life
#> 85                    hr      lambda.z.time.first
#> 86                    hr       lambda.z.time.last
#> 87                    hr           thalf.eff.last
#> 88                    hr        thalf.eff.int.all
#> 89                    hr       thalf.eff.int.last
#> 90                    hr            thalf.eff.all
#> 91                    hr        thalf.eff.iv.last
#> 92                    hr      thalf.eff.ivint.all
#> 93                    hr     thalf.eff.ivint.last
#> 94                    hr          mrt.sparse.last
#> 95                    hr               mrt.iv.all
#> 96                    hr         thalf.eff.iv.all
#> 97                    hr              mrt.inf.obs
#> 98                    hr             mrt.inf.pred
#> 99                    hr          mrt.int.inf.obs
#> 100                   hr         mrt.int.inf.pred
#> 101                   hr           mrt.iv.inf.obs
#> 102                   hr          mrt.iv.inf.pred
#> 103                   hr       mrt.ivint.inf.pred
#> 104                   hr        mrt.ivint.inf.obs
#> 105                   hr           mrt.md.inf.obs
#> 106                   hr          mrt.md.inf.pred
#> 107                   hr         mrt.ivmd.inf.obs
#> 108                   hr        mrt.ivmd.inf.pred
#> 109                   hr        thalf.eff.inf.obs
#> 110                   hr       thalf.eff.inf.pred
#> 111                   hr   thalf.eff.int.inf.pred
#> 112                   hr    thalf.eff.int.inf.obs
#> 113                   hr     thalf.eff.iv.inf.obs
#> 114                   hr    thalf.eff.iv.inf.pred
#> 115                   hr thalf.eff.ivint.inf.pred
#> 116                   hr  thalf.eff.ivint.inf.obs
#> 117                   hr               mrt.iv.obs
#> 118                   hr              mrt.iv.pred
#> 119                   hr             mrt.ivmd.obs
#> 120                   hr            mrt.ivmd.pred
#> 121                   hr               mrt.md.obs
#> 122                   hr              mrt.md.pred
#> 123                   hr                  mrt.obs
#> 124                   hr                 mrt.pred
#> 125                   hr         thalf.eff.iv.obs
#> 126                   hr        thalf.eff.iv.pred
#> 127                   hr            thalf.eff.obs
#> 128                   hr           thalf.eff.pred
#> 129                   hr               time_above
#> 130                 1/hr                 lambda.z
#> 131                 1/hr                 kel.last
#> 132                 1/hr              kel.iv.last
#> 133                 1/hr                  kel.all
#> 134                 1/hr              kel.int.all
#> 135                 1/hr             kel.int.last
#> 136                 1/hr            kel.ivint.all
#> 137                 1/hr           kel.ivint.last
#> 138                 1/hr               kel.iv.all
#> 139                 1/hr          kel.sparse.last
#> 140                 1/hr              kel.inf.obs
#> 141                 1/hr             kel.inf.pred
#> 142                 1/hr           kel.iv.inf.obs
#> 143                 1/hr          kel.iv.inf.pred
#> 144                 1/hr          kel.int.inf.obs
#> 145                 1/hr         kel.int.inf.pred
#> 146                 1/hr       kel.ivint.inf.pred
#> 147                 1/hr        kel.ivint.inf.obs
#> 148                 1/hr               kel.iv.obs
#> 149                 1/hr              kel.iv.pred
#> 150                 1/hr                  kel.obs
#> 151                 1/hr                 kel.pred
#> 152                ng/mL                       c0
#> 153                ng/mL                     cmax
#> 154                ng/mL                     cmin
#> 155                ng/mL                clast.obs
#> 156                ng/mL                 cav.last
#> 157                ng/mL             cav.int.last
#> 158                ng/mL              cav.int.all
#> 159                ng/mL                  cav.all
#> 160                ng/mL           cav.ivint.last
#> 161                ng/mL            cav.ivint.all
#> 162                ng/mL                  ctrough
#> 163                ng/mL                   cstart
#> 164                ng/mL                     ceoi
#> 165                ng/mL               clast.pred
#> 166                ng/mL              cav.iv.last
#> 167                ng/mL               cav.iv.all
#> 168                ng/mL          cav.int.inf.obs
#> 169                ng/mL         cav.int.inf.pred
#> 170                ng/mL        cav.ivint.inf.obs
#> 171                ng/mL       cav.ivint.inf.pred
#> 172                ng/mL                      cav
#> 173                   mg                       ae
#> 174           mg/(mg/kg)                       fe
#> 175                mg/kg                  totdose
#> 176      (ng/mL)/(mg/kg)                  cmax.dn
#> 177      (ng/mL)/(mg/kg)                  cmin.dn
#> 178      (ng/mL)/(mg/kg)             clast.obs.dn
#> 179      (ng/mL)/(mg/kg)            clast.pred.dn
#> 180      (ng/mL)/(mg/kg)              cav.last.dn
#> 181      (ng/mL)/(mg/kg)               ctrough.dn
#> 182      (ng/mL)/(mg/kg)                   cav.dn
#> 183      (mg/kg)/(ng/mL)                 vss.last
#> 184      (mg/kg)/(ng/mL)              vss.iv.last
#> 185      (mg/kg)/(ng/mL)                  vss.all
#> 186      (mg/kg)/(ng/mL)              vss.int.all
#> 187      (mg/kg)/(ng/mL)             vss.int.last
#> 188      (mg/kg)/(ng/mL)            vss.ivint.all
#> 189      (mg/kg)/(ng/mL)           vss.ivint.last
#> 190      (mg/kg)/(ng/mL)                    volpk
#> 191      (mg/kg)/(ng/mL)                   vz.all
#> 192      (mg/kg)/(ng/mL)               vz.int.all
#> 193      (mg/kg)/(ng/mL)              vz.int.last
#> 194      (mg/kg)/(ng/mL)                vz.iv.all
#> 195      (mg/kg)/(ng/mL)               vz.iv.last
#> 196      (mg/kg)/(ng/mL)             vz.ivint.all
#> 197      (mg/kg)/(ng/mL)            vz.ivint.last
#> 198      (mg/kg)/(ng/mL)                  vz.last
#> 199      (mg/kg)/(ng/mL)               vss.iv.all
#> 200      (mg/kg)/(ng/mL)          vss.sparse.last
#> 201      (mg/kg)/(ng/mL)               vz.inf.obs
#> 202      (mg/kg)/(ng/mL)              vz.inf.pred
#> 203      (mg/kg)/(ng/mL)           vz.int.inf.obs
#> 204      (mg/kg)/(ng/mL)          vz.int.inf.pred
#> 205      (mg/kg)/(ng/mL)            vz.iv.inf.obs
#> 206      (mg/kg)/(ng/mL)           vz.iv.inf.pred
#> 207      (mg/kg)/(ng/mL)        vz.ivint.inf.pred
#> 208      (mg/kg)/(ng/mL)         vz.ivint.inf.obs
#> 209      (mg/kg)/(ng/mL)           vz.sparse.last
#> 210      (mg/kg)/(ng/mL)              vss.inf.obs
#> 211      (mg/kg)/(ng/mL)             vss.inf.pred
#> 212      (mg/kg)/(ng/mL)           vss.iv.inf.obs
#> 213      (mg/kg)/(ng/mL)          vss.iv.inf.pred
#> 214      (mg/kg)/(ng/mL)           vss.md.inf.obs
#> 215      (mg/kg)/(ng/mL)          vss.md.inf.pred
#> 216      (mg/kg)/(ng/mL)         vss.ivmd.inf.obs
#> 217      (mg/kg)/(ng/mL)        vss.ivmd.inf.pred
#> 218      (mg/kg)/(ng/mL)          vss.int.inf.obs
#> 219      (mg/kg)/(ng/mL)         vss.int.inf.pred
#> 220      (mg/kg)/(ng/mL)       vss.ivint.inf.pred
#> 221      (mg/kg)/(ng/mL)        vss.ivint.inf.obs
#> 222      (mg/kg)/(ng/mL)               vss.iv.obs
#> 223      (mg/kg)/(ng/mL)              vss.iv.pred
#> 224      (mg/kg)/(ng/mL)             vss.ivmd.obs
#> 225      (mg/kg)/(ng/mL)            vss.ivmd.pred
#> 226      (mg/kg)/(ng/mL)               vss.md.obs
#> 227      (mg/kg)/(ng/mL)              vss.md.pred
#> 228      (mg/kg)/(ng/mL)                  vss.obs
#> 229      (mg/kg)/(ng/mL)                 vss.pred
#> 230      (mg/kg)/(ng/mL)                vz.iv.obs
#> 231      (mg/kg)/(ng/mL)               vz.iv.pred
#> 232      (mg/kg)/(ng/mL)                   vz.obs
#> 233      (mg/kg)/(ng/mL)                  vz.pred
#> 234             hr*ng/mL                  auclast
#> 235             hr*ng/mL               auclast_se
#> 236             hr*ng/mL                   aucall
#> 237             hr*ng/mL                aucall_se
#> 238             hr*ng/mL              aucint.last
#> 239             hr*ng/mL               aucint.all
#> 240             hr*ng/mL            aucivint.last
#> 241             hr*ng/mL             aucivint.all
#> 242             hr*ng/mL     aucabove.predose.all
#> 243             hr*ng/mL      aucabove.trough.all
#> 244             hr*ng/mL           sparse_auclast
#> 245             hr*ng/mL            sparse_auc_se
#> 246             hr*ng/mL                aucivlast
#> 247             hr*ng/mL             aucivlast_se
#> 248             hr*ng/mL                 aucivall
#> 249             hr*ng/mL              aucivall_se
#> 250             hr*ng/mL               aucinf.obs
#> 251             hr*ng/mL            aucinf.obs_se
#> 252             hr*ng/mL              aucinf.pred
#> 253             hr*ng/mL           aucint.inf.obs
#> 254             hr*ng/mL          aucint.inf.pred
#> 255             hr*ng/mL         aucivint.inf.obs
#> 256             hr*ng/mL        aucivint.inf.pred
#> 257             hr*ng/mL             aucivinf.obs
#> 258             hr*ng/mL          aucivinf.obs_se
#> 259             hr*ng/mL            aucivinf.pred
#> 260           hr^2*ng/mL                 aumclast
#> 261           hr^2*ng/mL              aumclast_se
#> 262           hr^2*ng/mL                  aumcall
#> 263           hr^2*ng/mL               aumcall_se
#> 264           hr^2*ng/mL             aumcint.last
#> 265           hr^2*ng/mL              aumcint.all
#> 266           hr^2*ng/mL           aumcivint.last
#> 267           hr^2*ng/mL            aumcivint.all
#> 268           hr^2*ng/mL          sparse_aumclast
#> 269           hr^2*ng/mL           sparse_aumc_se
#> 270           hr^2*ng/mL               aumcivlast
#> 271           hr^2*ng/mL            aumcivlast_se
#> 272           hr^2*ng/mL                aumcivall
#> 273           hr^2*ng/mL             aumcivall_se
#> 274           hr^2*ng/mL              aumcinf.obs
#> 275           hr^2*ng/mL           aumcinf.obs_se
#> 276           hr^2*ng/mL             aumcinf.pred
#> 277           hr^2*ng/mL          aumcint.inf.obs
#> 278           hr^2*ng/mL         aumcint.inf.pred
#> 279           hr^2*ng/mL       aumcivint.inf.pred
#> 280           hr^2*ng/mL        aumcivint.inf.obs
#> 281           hr^2*ng/mL            aumcivinf.obs
#> 282           hr^2*ng/mL         aumcivinf.obs_se
#> 283           hr^2*ng/mL           aumcivinf.pred
#> 284                mg/hr                    ermax
#> 285                mg/hr                    erint
#> 286                mg/hr                    erlst
#> 287   (hr*ng/mL)/(mg/kg)               auclast.dn
#> 288   (hr*ng/mL)/(mg/kg)                aucall.dn
#> 289   (hr*ng/mL)/(mg/kg)            aucinf.obs.dn
#> 290   (hr*ng/mL)/(mg/kg)           aucinf.pred.dn
#> 291 (hr^2*ng/mL)/(mg/kg)              aumclast.dn
#> 292 (hr^2*ng/mL)/(mg/kg)               aumcall.dn
#> 293 (hr^2*ng/mL)/(mg/kg)           aumcinf.obs.dn
#> 294 (hr^2*ng/mL)/(mg/kg)          aumcinf.pred.dn
#> 295   (mg/kg)/(hr*ng/mL)                  cl.last
#> 296   (mg/kg)/(hr*ng/mL)                   cl.all
#> 297   (mg/kg)/(hr*ng/mL)               cl.int.all
#> 298   (mg/kg)/(hr*ng/mL)              cl.int.last
#> 299   (mg/kg)/(hr*ng/mL)             cl.ivint.all
#> 300   (mg/kg)/(hr*ng/mL)            cl.ivint.last
#> 301   (mg/kg)/(hr*ng/mL)                cl.iv.all
#> 302   (mg/kg)/(hr*ng/mL)               cl.iv.last
#> 303   (mg/kg)/(hr*ng/mL)           cl.sparse.last
#> 304   (mg/kg)/(hr*ng/mL)               cl.inf.obs
#> 305   (mg/kg)/(hr*ng/mL)              cl.inf.pred
#> 306   (mg/kg)/(hr*ng/mL)           cl.int.inf.obs
#> 307   (mg/kg)/(hr*ng/mL)          cl.int.inf.pred
#> 308   (mg/kg)/(hr*ng/mL)            cl.iv.inf.obs
#> 309   (mg/kg)/(hr*ng/mL)           cl.iv.inf.pred
#> 310   (mg/kg)/(hr*ng/mL)        cl.ivint.inf.pred
#> 311   (mg/kg)/(hr*ng/mL)         cl.ivint.inf.obs
#> 312   (mg/kg)/(hr*ng/mL)                cl.iv.obs
#> 313   (mg/kg)/(hr*ng/mL)               cl.iv.pred
#> 314   (mg/kg)/(hr*ng/mL)                   cl.obs
#> 315   (mg/kg)/(hr*ng/mL)                  cl.pred
#> 316        mg/(hr*ng/mL)                 clr.last
#> 317        mg/(hr*ng/mL)         clr.int.inf.pred
#> 318        mg/(hr*ng/mL)          clr.int.inf.obs
#> 319        mg/(hr*ng/mL)              clr.int.all
#> 320        mg/(hr*ng/mL)             clr.int.last
#> 321        mg/(hr*ng/mL)                  clr.all
#> 322        mg/(hr*ng/mL)              clr.inf.obs
#> 323        mg/(hr*ng/mL)             clr.inf.pred
#> 324        mg/(hr*ng/mL)                  clr.obs
#> 325        mg/(hr*ng/mL)                 clr.pred
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
#>                 PPORRESU                 PPTESTCD             PPSTRESU
#> 1               unitless                r.squared             unitless
#> 2               unitless            adj.r.squared             unitless
#> 3               unitless          lambda.z.corrxy             unitless
#> 4               unitless           tobit.residual             unitless
#> 5               unitless       adj.tobit.residual             unitless
#> 6               unitless       adj_tobit_residual             unitless
#> 7               unitless           tobit_residual             unitless
#> 8               fraction                      ptr             fraction
#> 9               fraction               ratio.cmax             fraction
#> 10              fraction            ratio.auclast             fraction
#> 11              fraction        ratio.aucint.last             fraction
#> 12              fraction         ratio.aucint.all             fraction
#> 13              fraction               span.ratio             fraction
#> 14              fraction                   f.last             fraction
#> 15              fraction                    f.all             fraction
#> 16              fraction               f.int.last             fraction
#> 17              fraction                f.int.all             fraction
#> 18              fraction                f.inf.obs             fraction
#> 19              fraction               f.inf.pred             fraction
#> 20              fraction            f.int.inf.obs             fraction
#> 21              fraction           f.int.inf.pred             fraction
#> 22              fraction         ratio.aucinf.obs             fraction
#> 23              fraction        ratio.aucinf.pred             fraction
#> 24              fraction                f.int.obs             fraction
#> 25              fraction               f.int.pred             fraction
#> 26              fraction                    f.obs             fraction
#> 27              fraction                   f.pred             fraction
#> 28                     %      aucivpbext.int.last                    %
#> 29                     %       aucivpbext.int.all                    %
#> 30                     %                 deg.fluc                    %
#> 31                     %                    swing                    %
#> 32                     %          aucivpbext.last                    %
#> 33                     %           aucivpbext.all                    %
#> 34                     %       aucivpbext.inf.obs                    %
#> 35                     %      aucivpbext.inf.pred                    %
#> 36                     %          aucpext.inf.obs                    %
#> 37                     %         aucpext.inf.pred                    %
#> 38                     %            aucivpbextall                    %
#> 39                     %        aucivpbextinf.obs                    %
#> 40                     %       aucivpbextinf.pred                    %
#> 41                     %        aucivpbextint.all                    %
#> 42                     %       aucivpbextint.last                    %
#> 43                     %           aucivpbextlast                    %
#> 44                     %              aucpext.obs                    %
#> 45                     %             aucpext.pred                    %
#> 46                 count               auclast_df                count
#> 47                 count                aucall_df                count
#> 48                 count              aumclast_df                count
#> 49                 count               aumcall_df                count
#> 50                 count               count.conc                count
#> 51                 count      count.conc.measured                count
#> 52                 count            sparse_auc_df                count
#> 53                 count           sparse_aumc_df                count
#> 54                 count             aucivlast_df                count
#> 55                 count              aucivall_df                count
#> 56                 count            aumcivlast_df                count
#> 57                 count             aumcivall_df                count
#> 58                 count        lambda.z.n.points                count
#> 59                 count    lambda.z.n.points.blq                count
#> 60                 count            aucinf.obs_df                count
#> 61                 count           aumcinf.obs_df                count
#> 62                 count          aucivinf.obs_df                count
#> 63                 count         aumcivinf.obs_df                count
#> 64                 count               count_conc                count
#> 65                 count      count_conc_measured                count
#> 66                 count    lambda.z.n.points_blq                count
#> 67                    hr                    start                   hr
#> 68                    hr                      end                   hr
#> 69                    hr                     tmax                   hr
#> 70                    hr                     tmin                   hr
#> 71                    hr                    tlast                   hr
#> 72                    hr                   tfirst                   hr
#> 73                    hr                 mrt.last                   hr
#> 74                    hr                  mrt.all                   hr
#> 75                    hr              mrt.int.all                   hr
#> 76                    hr             mrt.int.last                   hr
#> 77                    hr              mrt.iv.last                   hr
#> 78                    hr            mrt.ivint.all                   hr
#> 79                    hr           mrt.ivint.last                   hr
#> 80                    hr                     tlag                   hr
#> 81                    hr                   ertlst                   hr
#> 82                    hr                   ertmax                   hr
#> 83                    hr               time.above                   hr
#> 84                    hr                half.life                   hr
#> 85                    hr      lambda.z.time.first                   hr
#> 86                    hr       lambda.z.time.last                   hr
#> 87                    hr           thalf.eff.last                   hr
#> 88                    hr        thalf.eff.int.all                   hr
#> 89                    hr       thalf.eff.int.last                   hr
#> 90                    hr            thalf.eff.all                   hr
#> 91                    hr        thalf.eff.iv.last                   hr
#> 92                    hr      thalf.eff.ivint.all                   hr
#> 93                    hr     thalf.eff.ivint.last                   hr
#> 94                    hr          mrt.sparse.last                   hr
#> 95                    hr               mrt.iv.all                   hr
#> 96                    hr         thalf.eff.iv.all                   hr
#> 97                    hr              mrt.inf.obs                   hr
#> 98                    hr             mrt.inf.pred                   hr
#> 99                    hr          mrt.int.inf.obs                   hr
#> 100                   hr         mrt.int.inf.pred                   hr
#> 101                   hr           mrt.iv.inf.obs                   hr
#> 102                   hr          mrt.iv.inf.pred                   hr
#> 103                   hr       mrt.ivint.inf.pred                   hr
#> 104                   hr        mrt.ivint.inf.obs                   hr
#> 105                   hr           mrt.md.inf.obs                   hr
#> 106                   hr          mrt.md.inf.pred                   hr
#> 107                   hr         mrt.ivmd.inf.obs                   hr
#> 108                   hr        mrt.ivmd.inf.pred                   hr
#> 109                   hr        thalf.eff.inf.obs                   hr
#> 110                   hr       thalf.eff.inf.pred                   hr
#> 111                   hr   thalf.eff.int.inf.pred                   hr
#> 112                   hr    thalf.eff.int.inf.obs                   hr
#> 113                   hr     thalf.eff.iv.inf.obs                   hr
#> 114                   hr    thalf.eff.iv.inf.pred                   hr
#> 115                   hr thalf.eff.ivint.inf.pred                   hr
#> 116                   hr  thalf.eff.ivint.inf.obs                   hr
#> 117                   hr               mrt.iv.obs                   hr
#> 118                   hr              mrt.iv.pred                   hr
#> 119                   hr             mrt.ivmd.obs                   hr
#> 120                   hr            mrt.ivmd.pred                   hr
#> 121                   hr               mrt.md.obs                   hr
#> 122                   hr              mrt.md.pred                   hr
#> 123                   hr                  mrt.obs                   hr
#> 124                   hr                 mrt.pred                   hr
#> 125                   hr         thalf.eff.iv.obs                   hr
#> 126                   hr        thalf.eff.iv.pred                   hr
#> 127                   hr            thalf.eff.obs                   hr
#> 128                   hr           thalf.eff.pred                   hr
#> 129                   hr               time_above                   hr
#> 130                 1/hr                 lambda.z                 1/hr
#> 131                 1/hr                 kel.last                 1/hr
#> 132                 1/hr              kel.iv.last                 1/hr
#> 133                 1/hr                  kel.all                 1/hr
#> 134                 1/hr              kel.int.all                 1/hr
#> 135                 1/hr             kel.int.last                 1/hr
#> 136                 1/hr            kel.ivint.all                 1/hr
#> 137                 1/hr           kel.ivint.last                 1/hr
#> 138                 1/hr               kel.iv.all                 1/hr
#> 139                 1/hr          kel.sparse.last                 1/hr
#> 140                 1/hr              kel.inf.obs                 1/hr
#> 141                 1/hr             kel.inf.pred                 1/hr
#> 142                 1/hr           kel.iv.inf.obs                 1/hr
#> 143                 1/hr          kel.iv.inf.pred                 1/hr
#> 144                 1/hr          kel.int.inf.obs                 1/hr
#> 145                 1/hr         kel.int.inf.pred                 1/hr
#> 146                 1/hr       kel.ivint.inf.pred                 1/hr
#> 147                 1/hr        kel.ivint.inf.obs                 1/hr
#> 148                 1/hr               kel.iv.obs                 1/hr
#> 149                 1/hr              kel.iv.pred                 1/hr
#> 150                 1/hr                  kel.obs                 1/hr
#> 151                 1/hr                 kel.pred                 1/hr
#> 152                ng/mL                       c0                ng/mL
#> 153                ng/mL                     cmax                ng/mL
#> 154                ng/mL                     cmin                ng/mL
#> 155                ng/mL                clast.obs                ng/mL
#> 156                ng/mL                 cav.last                ng/mL
#> 157                ng/mL             cav.int.last                ng/mL
#> 158                ng/mL              cav.int.all                ng/mL
#> 159                ng/mL                  cav.all                ng/mL
#> 160                ng/mL           cav.ivint.last                ng/mL
#> 161                ng/mL            cav.ivint.all                ng/mL
#> 162                ng/mL                  ctrough                ng/mL
#> 163                ng/mL                   cstart                ng/mL
#> 164                ng/mL                     ceoi                ng/mL
#> 165                ng/mL               clast.pred                ng/mL
#> 166                ng/mL              cav.iv.last                ng/mL
#> 167                ng/mL               cav.iv.all                ng/mL
#> 168                ng/mL          cav.int.inf.obs                ng/mL
#> 169                ng/mL         cav.int.inf.pred                ng/mL
#> 170                ng/mL        cav.ivint.inf.obs                ng/mL
#> 171                ng/mL       cav.ivint.inf.pred                ng/mL
#> 172                ng/mL                      cav                ng/mL
#> 173                   mg                       ae                   mg
#> 174           mg/(mg/kg)                       fe           mg/(mg/kg)
#> 175                mg/kg                  totdose                mg/kg
#> 176      (ng/mL)/(mg/kg)                  cmax.dn      (ng/mL)/(mg/kg)
#> 177      (ng/mL)/(mg/kg)                  cmin.dn      (ng/mL)/(mg/kg)
#> 178      (ng/mL)/(mg/kg)             clast.obs.dn      (ng/mL)/(mg/kg)
#> 179      (ng/mL)/(mg/kg)            clast.pred.dn      (ng/mL)/(mg/kg)
#> 180      (ng/mL)/(mg/kg)              cav.last.dn      (ng/mL)/(mg/kg)
#> 181      (ng/mL)/(mg/kg)               ctrough.dn      (ng/mL)/(mg/kg)
#> 182      (ng/mL)/(mg/kg)                   cav.dn      (ng/mL)/(mg/kg)
#> 183      (mg/kg)/(ng/mL)                 vss.last                mL/kg
#> 184      (mg/kg)/(ng/mL)              vss.iv.last                mL/kg
#> 185      (mg/kg)/(ng/mL)                  vss.all                mL/kg
#> 186      (mg/kg)/(ng/mL)              vss.int.all                mL/kg
#> 187      (mg/kg)/(ng/mL)             vss.int.last                mL/kg
#> 188      (mg/kg)/(ng/mL)            vss.ivint.all                mL/kg
#> 189      (mg/kg)/(ng/mL)           vss.ivint.last                mL/kg
#> 190      (mg/kg)/(ng/mL)                    volpk                mL/kg
#> 191      (mg/kg)/(ng/mL)                   vz.all                mL/kg
#> 192      (mg/kg)/(ng/mL)               vz.int.all                mL/kg
#> 193      (mg/kg)/(ng/mL)              vz.int.last                mL/kg
#> 194      (mg/kg)/(ng/mL)                vz.iv.all                mL/kg
#> 195      (mg/kg)/(ng/mL)               vz.iv.last                mL/kg
#> 196      (mg/kg)/(ng/mL)             vz.ivint.all                mL/kg
#> 197      (mg/kg)/(ng/mL)            vz.ivint.last                mL/kg
#> 198      (mg/kg)/(ng/mL)                  vz.last                mL/kg
#> 199      (mg/kg)/(ng/mL)               vss.iv.all                mL/kg
#> 200      (mg/kg)/(ng/mL)          vss.sparse.last                mL/kg
#> 201      (mg/kg)/(ng/mL)               vz.inf.obs                mL/kg
#> 202      (mg/kg)/(ng/mL)              vz.inf.pred                mL/kg
#> 203      (mg/kg)/(ng/mL)           vz.int.inf.obs                mL/kg
#> 204      (mg/kg)/(ng/mL)          vz.int.inf.pred                mL/kg
#> 205      (mg/kg)/(ng/mL)            vz.iv.inf.obs                mL/kg
#> 206      (mg/kg)/(ng/mL)           vz.iv.inf.pred                mL/kg
#> 207      (mg/kg)/(ng/mL)        vz.ivint.inf.pred                mL/kg
#> 208      (mg/kg)/(ng/mL)         vz.ivint.inf.obs                mL/kg
#> 209      (mg/kg)/(ng/mL)           vz.sparse.last                mL/kg
#> 210      (mg/kg)/(ng/mL)              vss.inf.obs                mL/kg
#> 211      (mg/kg)/(ng/mL)             vss.inf.pred                mL/kg
#> 212      (mg/kg)/(ng/mL)           vss.iv.inf.obs                mL/kg
#> 213      (mg/kg)/(ng/mL)          vss.iv.inf.pred                mL/kg
#> 214      (mg/kg)/(ng/mL)           vss.md.inf.obs                mL/kg
#> 215      (mg/kg)/(ng/mL)          vss.md.inf.pred                mL/kg
#> 216      (mg/kg)/(ng/mL)         vss.ivmd.inf.obs                mL/kg
#> 217      (mg/kg)/(ng/mL)        vss.ivmd.inf.pred                mL/kg
#> 218      (mg/kg)/(ng/mL)          vss.int.inf.obs                mL/kg
#> 219      (mg/kg)/(ng/mL)         vss.int.inf.pred                mL/kg
#> 220      (mg/kg)/(ng/mL)       vss.ivint.inf.pred                mL/kg
#> 221      (mg/kg)/(ng/mL)        vss.ivint.inf.obs                mL/kg
#> 222      (mg/kg)/(ng/mL)               vss.iv.obs                mL/kg
#> 223      (mg/kg)/(ng/mL)              vss.iv.pred                mL/kg
#> 224      (mg/kg)/(ng/mL)             vss.ivmd.obs                mL/kg
#> 225      (mg/kg)/(ng/mL)            vss.ivmd.pred                mL/kg
#> 226      (mg/kg)/(ng/mL)               vss.md.obs                mL/kg
#> 227      (mg/kg)/(ng/mL)              vss.md.pred                mL/kg
#> 228      (mg/kg)/(ng/mL)                  vss.obs                mL/kg
#> 229      (mg/kg)/(ng/mL)                 vss.pred                mL/kg
#> 230      (mg/kg)/(ng/mL)                vz.iv.obs                mL/kg
#> 231      (mg/kg)/(ng/mL)               vz.iv.pred                mL/kg
#> 232      (mg/kg)/(ng/mL)                   vz.obs                mL/kg
#> 233      (mg/kg)/(ng/mL)                  vz.pred                mL/kg
#> 234             hr*ng/mL                  auclast             hr*ng/mL
#> 235             hr*ng/mL               auclast_se             hr*ng/mL
#> 236             hr*ng/mL                   aucall             hr*ng/mL
#> 237             hr*ng/mL                aucall_se             hr*ng/mL
#> 238             hr*ng/mL              aucint.last             hr*ng/mL
#> 239             hr*ng/mL               aucint.all             hr*ng/mL
#> 240             hr*ng/mL            aucivint.last             hr*ng/mL
#> 241             hr*ng/mL             aucivint.all             hr*ng/mL
#> 242             hr*ng/mL     aucabove.predose.all             hr*ng/mL
#> 243             hr*ng/mL      aucabove.trough.all             hr*ng/mL
#> 244             hr*ng/mL           sparse_auclast             hr*ng/mL
#> 245             hr*ng/mL            sparse_auc_se             hr*ng/mL
#> 246             hr*ng/mL                aucivlast             hr*ng/mL
#> 247             hr*ng/mL             aucivlast_se             hr*ng/mL
#> 248             hr*ng/mL                 aucivall             hr*ng/mL
#> 249             hr*ng/mL              aucivall_se             hr*ng/mL
#> 250             hr*ng/mL               aucinf.obs             hr*ng/mL
#> 251             hr*ng/mL            aucinf.obs_se             hr*ng/mL
#> 252             hr*ng/mL              aucinf.pred             hr*ng/mL
#> 253             hr*ng/mL           aucint.inf.obs             hr*ng/mL
#> 254             hr*ng/mL          aucint.inf.pred             hr*ng/mL
#> 255             hr*ng/mL         aucivint.inf.obs             hr*ng/mL
#> 256             hr*ng/mL        aucivint.inf.pred             hr*ng/mL
#> 257             hr*ng/mL             aucivinf.obs             hr*ng/mL
#> 258             hr*ng/mL          aucivinf.obs_se             hr*ng/mL
#> 259             hr*ng/mL            aucivinf.pred             hr*ng/mL
#> 260           hr^2*ng/mL                 aumclast           hr^2*ng/mL
#> 261           hr^2*ng/mL              aumclast_se           hr^2*ng/mL
#> 262           hr^2*ng/mL                  aumcall           hr^2*ng/mL
#> 263           hr^2*ng/mL               aumcall_se           hr^2*ng/mL
#> 264           hr^2*ng/mL             aumcint.last           hr^2*ng/mL
#> 265           hr^2*ng/mL              aumcint.all           hr^2*ng/mL
#> 266           hr^2*ng/mL           aumcivint.last           hr^2*ng/mL
#> 267           hr^2*ng/mL            aumcivint.all           hr^2*ng/mL
#> 268           hr^2*ng/mL          sparse_aumclast           hr^2*ng/mL
#> 269           hr^2*ng/mL           sparse_aumc_se           hr^2*ng/mL
#> 270           hr^2*ng/mL               aumcivlast           hr^2*ng/mL
#> 271           hr^2*ng/mL            aumcivlast_se           hr^2*ng/mL
#> 272           hr^2*ng/mL                aumcivall           hr^2*ng/mL
#> 273           hr^2*ng/mL             aumcivall_se           hr^2*ng/mL
#> 274           hr^2*ng/mL              aumcinf.obs           hr^2*ng/mL
#> 275           hr^2*ng/mL           aumcinf.obs_se           hr^2*ng/mL
#> 276           hr^2*ng/mL             aumcinf.pred           hr^2*ng/mL
#> 277           hr^2*ng/mL          aumcint.inf.obs           hr^2*ng/mL
#> 278           hr^2*ng/mL         aumcint.inf.pred           hr^2*ng/mL
#> 279           hr^2*ng/mL       aumcivint.inf.pred           hr^2*ng/mL
#> 280           hr^2*ng/mL        aumcivint.inf.obs           hr^2*ng/mL
#> 281           hr^2*ng/mL            aumcivinf.obs           hr^2*ng/mL
#> 282           hr^2*ng/mL         aumcivinf.obs_se           hr^2*ng/mL
#> 283           hr^2*ng/mL           aumcivinf.pred           hr^2*ng/mL
#> 284                mg/hr                    ermax                mg/hr
#> 285                mg/hr                    erint                mg/hr
#> 286                mg/hr                    erlst                mg/hr
#> 287   (hr*ng/mL)/(mg/kg)               auclast.dn   (hr*ng/mL)/(mg/kg)
#> 288   (hr*ng/mL)/(mg/kg)                aucall.dn   (hr*ng/mL)/(mg/kg)
#> 289   (hr*ng/mL)/(mg/kg)            aucinf.obs.dn   (hr*ng/mL)/(mg/kg)
#> 290   (hr*ng/mL)/(mg/kg)           aucinf.pred.dn   (hr*ng/mL)/(mg/kg)
#> 291 (hr^2*ng/mL)/(mg/kg)              aumclast.dn (hr^2*ng/mL)/(mg/kg)
#> 292 (hr^2*ng/mL)/(mg/kg)               aumcall.dn (hr^2*ng/mL)/(mg/kg)
#> 293 (hr^2*ng/mL)/(mg/kg)           aumcinf.obs.dn (hr^2*ng/mL)/(mg/kg)
#> 294 (hr^2*ng/mL)/(mg/kg)          aumcinf.pred.dn (hr^2*ng/mL)/(mg/kg)
#> 295   (mg/kg)/(hr*ng/mL)                  cl.last             mL/hr/kg
#> 296   (mg/kg)/(hr*ng/mL)                   cl.all             mL/hr/kg
#> 297   (mg/kg)/(hr*ng/mL)               cl.int.all             mL/hr/kg
#> 298   (mg/kg)/(hr*ng/mL)              cl.int.last             mL/hr/kg
#> 299   (mg/kg)/(hr*ng/mL)             cl.ivint.all             mL/hr/kg
#> 300   (mg/kg)/(hr*ng/mL)            cl.ivint.last             mL/hr/kg
#> 301   (mg/kg)/(hr*ng/mL)                cl.iv.all             mL/hr/kg
#> 302   (mg/kg)/(hr*ng/mL)               cl.iv.last             mL/hr/kg
#> 303   (mg/kg)/(hr*ng/mL)           cl.sparse.last             mL/hr/kg
#> 304   (mg/kg)/(hr*ng/mL)               cl.inf.obs             mL/hr/kg
#> 305   (mg/kg)/(hr*ng/mL)              cl.inf.pred             mL/hr/kg
#> 306   (mg/kg)/(hr*ng/mL)           cl.int.inf.obs             mL/hr/kg
#> 307   (mg/kg)/(hr*ng/mL)          cl.int.inf.pred             mL/hr/kg
#> 308   (mg/kg)/(hr*ng/mL)            cl.iv.inf.obs             mL/hr/kg
#> 309   (mg/kg)/(hr*ng/mL)           cl.iv.inf.pred             mL/hr/kg
#> 310   (mg/kg)/(hr*ng/mL)        cl.ivint.inf.pred             mL/hr/kg
#> 311   (mg/kg)/(hr*ng/mL)         cl.ivint.inf.obs             mL/hr/kg
#> 312   (mg/kg)/(hr*ng/mL)                cl.iv.obs             mL/hr/kg
#> 313   (mg/kg)/(hr*ng/mL)               cl.iv.pred             mL/hr/kg
#> 314   (mg/kg)/(hr*ng/mL)                   cl.obs             mL/hr/kg
#> 315   (mg/kg)/(hr*ng/mL)                  cl.pred             mL/hr/kg
#> 316        mg/(hr*ng/mL)                 clr.last        mg/(hr*ng/mL)
#> 317        mg/(hr*ng/mL)         clr.int.inf.pred        mg/(hr*ng/mL)
#> 318        mg/(hr*ng/mL)          clr.int.inf.obs        mg/(hr*ng/mL)
#> 319        mg/(hr*ng/mL)              clr.int.all        mg/(hr*ng/mL)
#> 320        mg/(hr*ng/mL)             clr.int.last        mg/(hr*ng/mL)
#> 321        mg/(hr*ng/mL)                  clr.all        mg/(hr*ng/mL)
#> 322        mg/(hr*ng/mL)              clr.inf.obs        mg/(hr*ng/mL)
#> 323        mg/(hr*ng/mL)             clr.inf.pred        mg/(hr*ng/mL)
#> 324        mg/(hr*ng/mL)                  clr.obs        mg/(hr*ng/mL)
#> 325        mg/(hr*ng/mL)                 clr.pred        mg/(hr*ng/mL)
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
#> 179             1e+00
#> 180             1e+00
#> 181             1e+00
#> 182             1e+00
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
#> 194             1e+06
#> 195             1e+06
#> 196             1e+06
#> 197             1e+06
#> 198             1e+06
#> 199             1e+06
#> 200             1e+06
#> 201             1e+06
#> 202             1e+06
#> 203             1e+06
#> 204             1e+06
#> 205             1e+06
#> 206             1e+06
#> 207             1e+06
#> 208             1e+06
#> 209             1e+06
#> 210             1e+06
#> 211             1e+06
#> 212             1e+06
#> 213             1e+06
#> 214             1e+06
#> 215             1e+06
#> 216             1e+06
#> 217             1e+06
#> 218             1e+06
#> 219             1e+06
#> 220             1e+06
#> 221             1e+06
#> 222             1e+06
#> 223             1e+06
#> 224             1e+06
#> 225             1e+06
#> 226             1e+06
#> 227             1e+06
#> 228             1e+06
#> 229             1e+06
#> 230             1e+06
#> 231             1e+06
#> 232             1e+06
#> 233             1e+06
#> 234             1e+00
#> 235             1e+00
#> 236             1e+00
#> 237             1e+00
#> 238             1e+00
#> 239             1e+00
#> 240             1e+00
#> 241             1e+00
#> 242             1e+00
#> 243             1e+00
#> 244             1e+00
#> 245             1e+00
#> 246             1e+00
#> 247             1e+00
#> 248             1e+00
#> 249             1e+00
#> 250             1e+00
#> 251             1e+00
#> 252             1e+00
#> 253             1e+00
#> 254             1e+00
#> 255             1e+00
#> 256             1e+00
#> 257             1e+00
#> 258             1e+00
#> 259             1e+00
#> 260             1e+00
#> 261             1e+00
#> 262             1e+00
#> 263             1e+00
#> 264             1e+00
#> 265             1e+00
#> 266             1e+00
#> 267             1e+00
#> 268             1e+00
#> 269             1e+00
#> 270             1e+00
#> 271             1e+00
#> 272             1e+00
#> 273             1e+00
#> 274             1e+00
#> 275             1e+00
#> 276             1e+00
#> 277             1e+00
#> 278             1e+00
#> 279             1e+00
#> 280             1e+00
#> 281             1e+00
#> 282             1e+00
#> 283             1e+00
#> 284             1e+00
#> 285             1e+00
#> 286             1e+00
#> 287             1e+00
#> 288             1e+00
#> 289             1e+00
#> 290             1e+00
#> 291             1e+00
#> 292             1e+00
#> 293             1e+00
#> 294             1e+00
#> 295             1e+06
#> 296             1e+06
#> 297             1e+06
#> 298             1e+06
#> 299             1e+06
#> 300             1e+06
#> 301             1e+06
#> 302             1e+06
#> 303             1e+06
#> 304             1e+06
#> 305             1e+06
#> 306             1e+06
#> 307             1e+06
#> 308             1e+06
#> 309             1e+06
#> 310             1e+06
#> 311             1e+06
#> 312             1e+06
#> 313             1e+06
#> 314             1e+06
#> 315             1e+06
#> 316             1e+00
#> 317             1e+00
#> 318             1e+00
#> 319             1e+00
#> 320             1e+00
#> 321             1e+00
#> 322             1e+00
#> 323             1e+00
#> 324             1e+00
#> 325             1e+00
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
#>                PPORRESU                 PPTESTCD            PPSTRESU
#> 1              unitless                r.squared            unitless
#> 2              unitless            adj.r.squared            unitless
#> 3              unitless          lambda.z.corrxy            unitless
#> 4              unitless           tobit.residual            unitless
#> 5              unitless       adj.tobit.residual            unitless
#> 6              unitless       adj_tobit_residual            unitless
#> 7              unitless           tobit_residual            unitless
#> 8              fraction                      ptr            fraction
#> 9              fraction               ratio.cmax            fraction
#> 10             fraction            ratio.auclast            fraction
#> 11             fraction        ratio.aucint.last            fraction
#> 12             fraction         ratio.aucint.all            fraction
#> 13             fraction               span.ratio            fraction
#> 14             fraction                   f.last            fraction
#> 15             fraction                    f.all            fraction
#> 16             fraction               f.int.last            fraction
#> 17             fraction                f.int.all            fraction
#> 18             fraction                f.inf.obs            fraction
#> 19             fraction               f.inf.pred            fraction
#> 20             fraction            f.int.inf.obs            fraction
#> 21             fraction           f.int.inf.pred            fraction
#> 22             fraction         ratio.aucinf.obs            fraction
#> 23             fraction        ratio.aucinf.pred            fraction
#> 24             fraction                f.int.obs            fraction
#> 25             fraction               f.int.pred            fraction
#> 26             fraction                    f.obs            fraction
#> 27             fraction                   f.pred            fraction
#> 28                    %      aucivpbext.int.last                   %
#> 29                    %       aucivpbext.int.all                   %
#> 30                    %                 deg.fluc                   %
#> 31                    %                    swing                   %
#> 32                    %          aucivpbext.last                   %
#> 33                    %           aucivpbext.all                   %
#> 34                    %       aucivpbext.inf.obs                   %
#> 35                    %      aucivpbext.inf.pred                   %
#> 36                    %          aucpext.inf.obs                   %
#> 37                    %         aucpext.inf.pred                   %
#> 38                    %            aucivpbextall                   %
#> 39                    %        aucivpbextinf.obs                   %
#> 40                    %       aucivpbextinf.pred                   %
#> 41                    %        aucivpbextint.all                   %
#> 42                    %       aucivpbextint.last                   %
#> 43                    %           aucivpbextlast                   %
#> 44                    %              aucpext.obs                   %
#> 45                    %             aucpext.pred                   %
#> 46                count               auclast_df               count
#> 47                count                aucall_df               count
#> 48                count              aumclast_df               count
#> 49                count               aumcall_df               count
#> 50                count               count.conc               count
#> 51                count      count.conc.measured               count
#> 52                count            sparse_auc_df               count
#> 53                count           sparse_aumc_df               count
#> 54                count             aucivlast_df               count
#> 55                count              aucivall_df               count
#> 56                count            aumcivlast_df               count
#> 57                count             aumcivall_df               count
#> 58                count        lambda.z.n.points               count
#> 59                count    lambda.z.n.points.blq               count
#> 60                count            aucinf.obs_df               count
#> 61                count           aumcinf.obs_df               count
#> 62                count          aucivinf.obs_df               count
#> 63                count         aumcivinf.obs_df               count
#> 64                count               count_conc               count
#> 65                count      count_conc_measured               count
#> 66                count    lambda.z.n.points_blq               count
#> 67                   hr                    start                  hr
#> 68                   hr                      end                  hr
#> 69                   hr                     tmax                  hr
#> 70                   hr                     tmin                  hr
#> 71                   hr                    tlast                  hr
#> 72                   hr                   tfirst                  hr
#> 73                   hr                 mrt.last                  hr
#> 74                   hr                  mrt.all                  hr
#> 75                   hr              mrt.int.all                  hr
#> 76                   hr             mrt.int.last                  hr
#> 77                   hr              mrt.iv.last                  hr
#> 78                   hr            mrt.ivint.all                  hr
#> 79                   hr           mrt.ivint.last                  hr
#> 80                   hr                     tlag                  hr
#> 81                   hr                   ertlst                  hr
#> 82                   hr                   ertmax                  hr
#> 83                   hr               time.above                  hr
#> 84                   hr                half.life                  hr
#> 85                   hr      lambda.z.time.first                  hr
#> 86                   hr       lambda.z.time.last                  hr
#> 87                   hr           thalf.eff.last                  hr
#> 88                   hr        thalf.eff.int.all                  hr
#> 89                   hr       thalf.eff.int.last                  hr
#> 90                   hr            thalf.eff.all                  hr
#> 91                   hr        thalf.eff.iv.last                  hr
#> 92                   hr      thalf.eff.ivint.all                  hr
#> 93                   hr     thalf.eff.ivint.last                  hr
#> 94                   hr          mrt.sparse.last                  hr
#> 95                   hr               mrt.iv.all                  hr
#> 96                   hr         thalf.eff.iv.all                  hr
#> 97                   hr              mrt.inf.obs                  hr
#> 98                   hr             mrt.inf.pred                  hr
#> 99                   hr          mrt.int.inf.obs                  hr
#> 100                  hr         mrt.int.inf.pred                  hr
#> 101                  hr           mrt.iv.inf.obs                  hr
#> 102                  hr          mrt.iv.inf.pred                  hr
#> 103                  hr       mrt.ivint.inf.pred                  hr
#> 104                  hr        mrt.ivint.inf.obs                  hr
#> 105                  hr           mrt.md.inf.obs                  hr
#> 106                  hr          mrt.md.inf.pred                  hr
#> 107                  hr         mrt.ivmd.inf.obs                  hr
#> 108                  hr        mrt.ivmd.inf.pred                  hr
#> 109                  hr        thalf.eff.inf.obs                  hr
#> 110                  hr       thalf.eff.inf.pred                  hr
#> 111                  hr   thalf.eff.int.inf.pred                  hr
#> 112                  hr    thalf.eff.int.inf.obs                  hr
#> 113                  hr     thalf.eff.iv.inf.obs                  hr
#> 114                  hr    thalf.eff.iv.inf.pred                  hr
#> 115                  hr thalf.eff.ivint.inf.pred                  hr
#> 116                  hr  thalf.eff.ivint.inf.obs                  hr
#> 117                  hr               mrt.iv.obs                  hr
#> 118                  hr              mrt.iv.pred                  hr
#> 119                  hr             mrt.ivmd.obs                  hr
#> 120                  hr            mrt.ivmd.pred                  hr
#> 121                  hr               mrt.md.obs                  hr
#> 122                  hr              mrt.md.pred                  hr
#> 123                  hr                  mrt.obs                  hr
#> 124                  hr                 mrt.pred                  hr
#> 125                  hr         thalf.eff.iv.obs                  hr
#> 126                  hr        thalf.eff.iv.pred                  hr
#> 127                  hr            thalf.eff.obs                  hr
#> 128                  hr           thalf.eff.pred                  hr
#> 129                  hr               time_above                  hr
#> 130                1/hr                 lambda.z                1/hr
#> 131                1/hr                 kel.last                1/hr
#> 132                1/hr              kel.iv.last                1/hr
#> 133                1/hr                  kel.all                1/hr
#> 134                1/hr              kel.int.all                1/hr
#> 135                1/hr             kel.int.last                1/hr
#> 136                1/hr            kel.ivint.all                1/hr
#> 137                1/hr           kel.ivint.last                1/hr
#> 138                1/hr               kel.iv.all                1/hr
#> 139                1/hr          kel.sparse.last                1/hr
#> 140                1/hr              kel.inf.obs                1/hr
#> 141                1/hr             kel.inf.pred                1/hr
#> 142                1/hr           kel.iv.inf.obs                1/hr
#> 143                1/hr          kel.iv.inf.pred                1/hr
#> 144                1/hr          kel.int.inf.obs                1/hr
#> 145                1/hr         kel.int.inf.pred                1/hr
#> 146                1/hr       kel.ivint.inf.pred                1/hr
#> 147                1/hr        kel.ivint.inf.obs                1/hr
#> 148                1/hr               kel.iv.obs                1/hr
#> 149                1/hr              kel.iv.pred                1/hr
#> 150                1/hr                  kel.obs                1/hr
#> 151                1/hr                 kel.pred                1/hr
#> 152                mg/L                       c0              mmol/L
#> 153                mg/L                     cmax              mmol/L
#> 154                mg/L                     cmin              mmol/L
#> 155                mg/L                clast.obs              mmol/L
#> 156                mg/L                 cav.last              mmol/L
#> 157                mg/L             cav.int.last              mmol/L
#> 158                mg/L              cav.int.all              mmol/L
#> 159                mg/L                  cav.all              mmol/L
#> 160                mg/L           cav.ivint.last              mmol/L
#> 161                mg/L            cav.ivint.all              mmol/L
#> 162                mg/L                  ctrough              mmol/L
#> 163                mg/L                   cstart              mmol/L
#> 164                mg/L                     ceoi              mmol/L
#> 165                mg/L               clast.pred              mmol/L
#> 166                mg/L              cav.iv.last              mmol/L
#> 167                mg/L               cav.iv.all              mmol/L
#> 168                mg/L          cav.int.inf.obs              mmol/L
#> 169                mg/L         cav.int.inf.pred              mmol/L
#> 170                mg/L        cav.ivint.inf.obs              mmol/L
#> 171                mg/L       cav.ivint.inf.pred              mmol/L
#> 172                mg/L                      cav              mmol/L
#> 173                  mg                       ae                  mg
#> 174          mg/(mg/kg)                       fe          mg/(mg/kg)
#> 175               mg/kg                  totdose               mg/kg
#> 176      (mg/L)/(mg/kg)                  cmax.dn      (mg/L)/(mg/kg)
#> 177      (mg/L)/(mg/kg)                  cmin.dn      (mg/L)/(mg/kg)
#> 178      (mg/L)/(mg/kg)             clast.obs.dn      (mg/L)/(mg/kg)
#> 179      (mg/L)/(mg/kg)            clast.pred.dn      (mg/L)/(mg/kg)
#> 180      (mg/L)/(mg/kg)              cav.last.dn      (mg/L)/(mg/kg)
#> 181      (mg/L)/(mg/kg)               ctrough.dn      (mg/L)/(mg/kg)
#> 182      (mg/L)/(mg/kg)                   cav.dn      (mg/L)/(mg/kg)
#> 183      (mg/kg)/(mg/L)                 vss.last      (mg/kg)/(mg/L)
#> 184      (mg/kg)/(mg/L)              vss.iv.last      (mg/kg)/(mg/L)
#> 185      (mg/kg)/(mg/L)                  vss.all      (mg/kg)/(mg/L)
#> 186      (mg/kg)/(mg/L)              vss.int.all      (mg/kg)/(mg/L)
#> 187      (mg/kg)/(mg/L)             vss.int.last      (mg/kg)/(mg/L)
#> 188      (mg/kg)/(mg/L)            vss.ivint.all      (mg/kg)/(mg/L)
#> 189      (mg/kg)/(mg/L)           vss.ivint.last      (mg/kg)/(mg/L)
#> 190      (mg/kg)/(mg/L)                    volpk      (mg/kg)/(mg/L)
#> 191      (mg/kg)/(mg/L)                   vz.all      (mg/kg)/(mg/L)
#> 192      (mg/kg)/(mg/L)               vz.int.all      (mg/kg)/(mg/L)
#> 193      (mg/kg)/(mg/L)              vz.int.last      (mg/kg)/(mg/L)
#> 194      (mg/kg)/(mg/L)                vz.iv.all      (mg/kg)/(mg/L)
#> 195      (mg/kg)/(mg/L)               vz.iv.last      (mg/kg)/(mg/L)
#> 196      (mg/kg)/(mg/L)             vz.ivint.all      (mg/kg)/(mg/L)
#> 197      (mg/kg)/(mg/L)            vz.ivint.last      (mg/kg)/(mg/L)
#> 198      (mg/kg)/(mg/L)                  vz.last      (mg/kg)/(mg/L)
#> 199      (mg/kg)/(mg/L)               vss.iv.all      (mg/kg)/(mg/L)
#> 200      (mg/kg)/(mg/L)          vss.sparse.last      (mg/kg)/(mg/L)
#> 201      (mg/kg)/(mg/L)               vz.inf.obs      (mg/kg)/(mg/L)
#> 202      (mg/kg)/(mg/L)              vz.inf.pred      (mg/kg)/(mg/L)
#> 203      (mg/kg)/(mg/L)           vz.int.inf.obs      (mg/kg)/(mg/L)
#> 204      (mg/kg)/(mg/L)          vz.int.inf.pred      (mg/kg)/(mg/L)
#> 205      (mg/kg)/(mg/L)            vz.iv.inf.obs      (mg/kg)/(mg/L)
#> 206      (mg/kg)/(mg/L)           vz.iv.inf.pred      (mg/kg)/(mg/L)
#> 207      (mg/kg)/(mg/L)        vz.ivint.inf.pred      (mg/kg)/(mg/L)
#> 208      (mg/kg)/(mg/L)         vz.ivint.inf.obs      (mg/kg)/(mg/L)
#> 209      (mg/kg)/(mg/L)           vz.sparse.last      (mg/kg)/(mg/L)
#> 210      (mg/kg)/(mg/L)              vss.inf.obs      (mg/kg)/(mg/L)
#> 211      (mg/kg)/(mg/L)             vss.inf.pred      (mg/kg)/(mg/L)
#> 212      (mg/kg)/(mg/L)           vss.iv.inf.obs      (mg/kg)/(mg/L)
#> 213      (mg/kg)/(mg/L)          vss.iv.inf.pred      (mg/kg)/(mg/L)
#> 214      (mg/kg)/(mg/L)           vss.md.inf.obs      (mg/kg)/(mg/L)
#> 215      (mg/kg)/(mg/L)          vss.md.inf.pred      (mg/kg)/(mg/L)
#> 216      (mg/kg)/(mg/L)         vss.ivmd.inf.obs      (mg/kg)/(mg/L)
#> 217      (mg/kg)/(mg/L)        vss.ivmd.inf.pred      (mg/kg)/(mg/L)
#> 218      (mg/kg)/(mg/L)          vss.int.inf.obs      (mg/kg)/(mg/L)
#> 219      (mg/kg)/(mg/L)         vss.int.inf.pred      (mg/kg)/(mg/L)
#> 220      (mg/kg)/(mg/L)       vss.ivint.inf.pred      (mg/kg)/(mg/L)
#> 221      (mg/kg)/(mg/L)        vss.ivint.inf.obs      (mg/kg)/(mg/L)
#> 222      (mg/kg)/(mg/L)               vss.iv.obs      (mg/kg)/(mg/L)
#> 223      (mg/kg)/(mg/L)              vss.iv.pred      (mg/kg)/(mg/L)
#> 224      (mg/kg)/(mg/L)             vss.ivmd.obs      (mg/kg)/(mg/L)
#> 225      (mg/kg)/(mg/L)            vss.ivmd.pred      (mg/kg)/(mg/L)
#> 226      (mg/kg)/(mg/L)               vss.md.obs      (mg/kg)/(mg/L)
#> 227      (mg/kg)/(mg/L)              vss.md.pred      (mg/kg)/(mg/L)
#> 228      (mg/kg)/(mg/L)                  vss.obs      (mg/kg)/(mg/L)
#> 229      (mg/kg)/(mg/L)                 vss.pred      (mg/kg)/(mg/L)
#> 230      (mg/kg)/(mg/L)                vz.iv.obs      (mg/kg)/(mg/L)
#> 231      (mg/kg)/(mg/L)               vz.iv.pred      (mg/kg)/(mg/L)
#> 232      (mg/kg)/(mg/L)                   vz.obs      (mg/kg)/(mg/L)
#> 233      (mg/kg)/(mg/L)                  vz.pred      (mg/kg)/(mg/L)
#> 234             hr*mg/L                  auclast             hr*mg/L
#> 235             hr*mg/L               auclast_se             hr*mg/L
#> 236             hr*mg/L                   aucall             hr*mg/L
#> 237             hr*mg/L                aucall_se             hr*mg/L
#> 238             hr*mg/L              aucint.last             hr*mg/L
#> 239             hr*mg/L               aucint.all             hr*mg/L
#> 240             hr*mg/L            aucivint.last             hr*mg/L
#> 241             hr*mg/L             aucivint.all             hr*mg/L
#> 242             hr*mg/L     aucabove.predose.all             hr*mg/L
#> 243             hr*mg/L      aucabove.trough.all             hr*mg/L
#> 244             hr*mg/L           sparse_auclast             hr*mg/L
#> 245             hr*mg/L            sparse_auc_se             hr*mg/L
#> 246             hr*mg/L                aucivlast             hr*mg/L
#> 247             hr*mg/L             aucivlast_se             hr*mg/L
#> 248             hr*mg/L                 aucivall             hr*mg/L
#> 249             hr*mg/L              aucivall_se             hr*mg/L
#> 250             hr*mg/L               aucinf.obs             hr*mg/L
#> 251             hr*mg/L            aucinf.obs_se             hr*mg/L
#> 252             hr*mg/L              aucinf.pred             hr*mg/L
#> 253             hr*mg/L           aucint.inf.obs             hr*mg/L
#> 254             hr*mg/L          aucint.inf.pred             hr*mg/L
#> 255             hr*mg/L         aucivint.inf.obs             hr*mg/L
#> 256             hr*mg/L        aucivint.inf.pred             hr*mg/L
#> 257             hr*mg/L             aucivinf.obs             hr*mg/L
#> 258             hr*mg/L          aucivinf.obs_se             hr*mg/L
#> 259             hr*mg/L            aucivinf.pred             hr*mg/L
#> 260           hr^2*mg/L                 aumclast           hr^2*mg/L
#> 261           hr^2*mg/L              aumclast_se           hr^2*mg/L
#> 262           hr^2*mg/L                  aumcall           hr^2*mg/L
#> 263           hr^2*mg/L               aumcall_se           hr^2*mg/L
#> 264           hr^2*mg/L             aumcint.last           hr^2*mg/L
#> 265           hr^2*mg/L              aumcint.all           hr^2*mg/L
#> 266           hr^2*mg/L           aumcivint.last           hr^2*mg/L
#> 267           hr^2*mg/L            aumcivint.all           hr^2*mg/L
#> 268           hr^2*mg/L          sparse_aumclast           hr^2*mg/L
#> 269           hr^2*mg/L           sparse_aumc_se           hr^2*mg/L
#> 270           hr^2*mg/L               aumcivlast           hr^2*mg/L
#> 271           hr^2*mg/L            aumcivlast_se           hr^2*mg/L
#> 272           hr^2*mg/L                aumcivall           hr^2*mg/L
#> 273           hr^2*mg/L             aumcivall_se           hr^2*mg/L
#> 274           hr^2*mg/L              aumcinf.obs           hr^2*mg/L
#> 275           hr^2*mg/L           aumcinf.obs_se           hr^2*mg/L
#> 276           hr^2*mg/L             aumcinf.pred           hr^2*mg/L
#> 277           hr^2*mg/L          aumcint.inf.obs           hr^2*mg/L
#> 278           hr^2*mg/L         aumcint.inf.pred           hr^2*mg/L
#> 279           hr^2*mg/L       aumcivint.inf.pred           hr^2*mg/L
#> 280           hr^2*mg/L        aumcivint.inf.obs           hr^2*mg/L
#> 281           hr^2*mg/L            aumcivinf.obs           hr^2*mg/L
#> 282           hr^2*mg/L         aumcivinf.obs_se           hr^2*mg/L
#> 283           hr^2*mg/L           aumcivinf.pred           hr^2*mg/L
#> 284               mg/hr                    ermax               mg/hr
#> 285               mg/hr                    erint               mg/hr
#> 286               mg/hr                    erlst               mg/hr
#> 287   (hr*mg/L)/(mg/kg)               auclast.dn   (hr*mg/L)/(mg/kg)
#> 288   (hr*mg/L)/(mg/kg)                aucall.dn   (hr*mg/L)/(mg/kg)
#> 289   (hr*mg/L)/(mg/kg)            aucinf.obs.dn   (hr*mg/L)/(mg/kg)
#> 290   (hr*mg/L)/(mg/kg)           aucinf.pred.dn   (hr*mg/L)/(mg/kg)
#> 291 (hr^2*mg/L)/(mg/kg)              aumclast.dn (hr^2*mg/L)/(mg/kg)
#> 292 (hr^2*mg/L)/(mg/kg)               aumcall.dn (hr^2*mg/L)/(mg/kg)
#> 293 (hr^2*mg/L)/(mg/kg)           aumcinf.obs.dn (hr^2*mg/L)/(mg/kg)
#> 294 (hr^2*mg/L)/(mg/kg)          aumcinf.pred.dn (hr^2*mg/L)/(mg/kg)
#> 295   (mg/kg)/(hr*mg/L)                  cl.last   (mg/kg)/(hr*mg/L)
#> 296   (mg/kg)/(hr*mg/L)                   cl.all   (mg/kg)/(hr*mg/L)
#> 297   (mg/kg)/(hr*mg/L)               cl.int.all   (mg/kg)/(hr*mg/L)
#> 298   (mg/kg)/(hr*mg/L)              cl.int.last   (mg/kg)/(hr*mg/L)
#> 299   (mg/kg)/(hr*mg/L)             cl.ivint.all   (mg/kg)/(hr*mg/L)
#> 300   (mg/kg)/(hr*mg/L)            cl.ivint.last   (mg/kg)/(hr*mg/L)
#> 301   (mg/kg)/(hr*mg/L)                cl.iv.all   (mg/kg)/(hr*mg/L)
#> 302   (mg/kg)/(hr*mg/L)               cl.iv.last   (mg/kg)/(hr*mg/L)
#> 303   (mg/kg)/(hr*mg/L)           cl.sparse.last   (mg/kg)/(hr*mg/L)
#> 304   (mg/kg)/(hr*mg/L)               cl.inf.obs   (mg/kg)/(hr*mg/L)
#> 305   (mg/kg)/(hr*mg/L)              cl.inf.pred   (mg/kg)/(hr*mg/L)
#> 306   (mg/kg)/(hr*mg/L)           cl.int.inf.obs   (mg/kg)/(hr*mg/L)
#> 307   (mg/kg)/(hr*mg/L)          cl.int.inf.pred   (mg/kg)/(hr*mg/L)
#> 308   (mg/kg)/(hr*mg/L)            cl.iv.inf.obs   (mg/kg)/(hr*mg/L)
#> 309   (mg/kg)/(hr*mg/L)           cl.iv.inf.pred   (mg/kg)/(hr*mg/L)
#> 310   (mg/kg)/(hr*mg/L)        cl.ivint.inf.pred   (mg/kg)/(hr*mg/L)
#> 311   (mg/kg)/(hr*mg/L)         cl.ivint.inf.obs   (mg/kg)/(hr*mg/L)
#> 312   (mg/kg)/(hr*mg/L)                cl.iv.obs   (mg/kg)/(hr*mg/L)
#> 313   (mg/kg)/(hr*mg/L)               cl.iv.pred   (mg/kg)/(hr*mg/L)
#> 314   (mg/kg)/(hr*mg/L)                   cl.obs   (mg/kg)/(hr*mg/L)
#> 315   (mg/kg)/(hr*mg/L)                  cl.pred   (mg/kg)/(hr*mg/L)
#> 316        mg/(hr*mg/L)                 clr.last        mg/(hr*mg/L)
#> 317        mg/(hr*mg/L)         clr.int.inf.pred        mg/(hr*mg/L)
#> 318        mg/(hr*mg/L)          clr.int.inf.obs        mg/(hr*mg/L)
#> 319        mg/(hr*mg/L)              clr.int.all        mg/(hr*mg/L)
#> 320        mg/(hr*mg/L)             clr.int.last        mg/(hr*mg/L)
#> 321        mg/(hr*mg/L)                  clr.all        mg/(hr*mg/L)
#> 322        mg/(hr*mg/L)              clr.inf.obs        mg/(hr*mg/L)
#> 323        mg/(hr*mg/L)             clr.inf.pred        mg/(hr*mg/L)
#> 324        mg/(hr*mg/L)                  clr.obs        mg/(hr*mg/L)
#> 325        mg/(hr*mg/L)                 clr.pred        mg/(hr*mg/L)
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
#> 152       0.007240029
#> 153       0.007240029
#> 154       0.007240029
#> 155       0.007240029
#> 156       0.007240029
#> 157       0.007240029
#> 158       0.007240029
#> 159       0.007240029
#> 160       0.007240029
#> 161       0.007240029
#> 162       0.007240029
#> 163       0.007240029
#> 164       0.007240029
#> 165       0.007240029
#> 166       0.007240029
#> 167       0.007240029
#> 168       0.007240029
#> 169       0.007240029
#> 170       0.007240029
#> 171       0.007240029
#> 172       0.007240029
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
#> 249       1.000000000
#> 250       1.000000000
#> 251       1.000000000
#> 252       1.000000000
#> 253       1.000000000
#> 254       1.000000000
#> 255       1.000000000
#> 256       1.000000000
#> 257       1.000000000
#> 258       1.000000000
#> 259       1.000000000
#> 260       1.000000000
#> 261       1.000000000
#> 262       1.000000000
#> 263       1.000000000
#> 264       1.000000000
#> 265       1.000000000
#> 266       1.000000000
#> 267       1.000000000
#> 268       1.000000000
#> 269       1.000000000
#> 270       1.000000000
#> 271       1.000000000
#> 272       1.000000000
#> 273       1.000000000
#> 274       1.000000000
#> 275       1.000000000
#> 276       1.000000000
#> 277       1.000000000
#> 278       1.000000000
#> 279       1.000000000
#> 280       1.000000000
#> 281       1.000000000
#> 282       1.000000000
#> 283       1.000000000
#> 284       1.000000000
#> 285       1.000000000
#> 286       1.000000000
#> 287       1.000000000
#> 288       1.000000000
#> 289       1.000000000
#> 290       1.000000000
#> 291       1.000000000
#> 292       1.000000000
#> 293       1.000000000
#> 294       1.000000000
#> 295       1.000000000
#> 296       1.000000000
#> 297       1.000000000
#> 298       1.000000000
#> 299       1.000000000
#> 300       1.000000000
#> 301       1.000000000
#> 302       1.000000000
#> 303       1.000000000
#> 304       1.000000000
#> 305       1.000000000
#> 306       1.000000000
#> 307       1.000000000
#> 308       1.000000000
#> 309       1.000000000
#> 310       1.000000000
#> 311       1.000000000
#> 312       1.000000000
#> 313       1.000000000
#> 314       1.000000000
#> 315       1.000000000
#> 316       1.000000000
#> 317       1.000000000
#> 318       1.000000000
#> 319       1.000000000
#> 320       1.000000000
#> 321       1.000000000
#> 322       1.000000000
#> 323       1.000000000
#> 324       1.000000000
#> 325       1.000000000

# This will make all time-related parameters use "day" even though the
# original units are "hr"
pknca_units_table(
  concu = "ng/mL", doseu = "mg/kg", timeu = "hr", amountu = "mg",
  timeu_pref = "day"
)
#>                 PPORRESU                 PPTESTCD              PPSTRESU
#> 1               unitless                r.squared              unitless
#> 2               unitless            adj.r.squared              unitless
#> 3               unitless          lambda.z.corrxy              unitless
#> 4               unitless           tobit.residual              unitless
#> 5               unitless       adj.tobit.residual              unitless
#> 6               unitless       adj_tobit_residual              unitless
#> 7               unitless           tobit_residual              unitless
#> 8               fraction                      ptr              fraction
#> 9               fraction               ratio.cmax              fraction
#> 10              fraction            ratio.auclast              fraction
#> 11              fraction        ratio.aucint.last              fraction
#> 12              fraction         ratio.aucint.all              fraction
#> 13              fraction               span.ratio              fraction
#> 14              fraction                   f.last              fraction
#> 15              fraction                    f.all              fraction
#> 16              fraction               f.int.last              fraction
#> 17              fraction                f.int.all              fraction
#> 18              fraction                f.inf.obs              fraction
#> 19              fraction               f.inf.pred              fraction
#> 20              fraction            f.int.inf.obs              fraction
#> 21              fraction           f.int.inf.pred              fraction
#> 22              fraction         ratio.aucinf.obs              fraction
#> 23              fraction        ratio.aucinf.pred              fraction
#> 24              fraction                f.int.obs              fraction
#> 25              fraction               f.int.pred              fraction
#> 26              fraction                    f.obs              fraction
#> 27              fraction                   f.pred              fraction
#> 28                     %      aucivpbext.int.last                     %
#> 29                     %       aucivpbext.int.all                     %
#> 30                     %                 deg.fluc                     %
#> 31                     %                    swing                     %
#> 32                     %          aucivpbext.last                     %
#> 33                     %           aucivpbext.all                     %
#> 34                     %       aucivpbext.inf.obs                     %
#> 35                     %      aucivpbext.inf.pred                     %
#> 36                     %          aucpext.inf.obs                     %
#> 37                     %         aucpext.inf.pred                     %
#> 38                     %            aucivpbextall                     %
#> 39                     %        aucivpbextinf.obs                     %
#> 40                     %       aucivpbextinf.pred                     %
#> 41                     %        aucivpbextint.all                     %
#> 42                     %       aucivpbextint.last                     %
#> 43                     %           aucivpbextlast                     %
#> 44                     %              aucpext.obs                     %
#> 45                     %             aucpext.pred                     %
#> 46                 count               auclast_df                 count
#> 47                 count                aucall_df                 count
#> 48                 count              aumclast_df                 count
#> 49                 count               aumcall_df                 count
#> 50                 count               count.conc                 count
#> 51                 count      count.conc.measured                 count
#> 52                 count            sparse_auc_df                 count
#> 53                 count           sparse_aumc_df                 count
#> 54                 count             aucivlast_df                 count
#> 55                 count              aucivall_df                 count
#> 56                 count            aumcivlast_df                 count
#> 57                 count             aumcivall_df                 count
#> 58                 count        lambda.z.n.points                 count
#> 59                 count    lambda.z.n.points.blq                 count
#> 60                 count            aucinf.obs_df                 count
#> 61                 count           aumcinf.obs_df                 count
#> 62                 count          aucivinf.obs_df                 count
#> 63                 count         aumcivinf.obs_df                 count
#> 64                 count               count_conc                 count
#> 65                 count      count_conc_measured                 count
#> 66                 count    lambda.z.n.points_blq                 count
#> 67                    hr                    start                   day
#> 68                    hr                      end                   day
#> 69                    hr                     tmax                   day
#> 70                    hr                     tmin                   day
#> 71                    hr                    tlast                   day
#> 72                    hr                   tfirst                   day
#> 73                    hr                 mrt.last                   day
#> 74                    hr                  mrt.all                   day
#> 75                    hr              mrt.int.all                   day
#> 76                    hr             mrt.int.last                   day
#> 77                    hr              mrt.iv.last                   day
#> 78                    hr            mrt.ivint.all                   day
#> 79                    hr           mrt.ivint.last                   day
#> 80                    hr                     tlag                   day
#> 81                    hr                   ertlst                   day
#> 82                    hr                   ertmax                   day
#> 83                    hr               time.above                   day
#> 84                    hr                half.life                   day
#> 85                    hr      lambda.z.time.first                   day
#> 86                    hr       lambda.z.time.last                   day
#> 87                    hr           thalf.eff.last                   day
#> 88                    hr        thalf.eff.int.all                   day
#> 89                    hr       thalf.eff.int.last                   day
#> 90                    hr            thalf.eff.all                   day
#> 91                    hr        thalf.eff.iv.last                   day
#> 92                    hr      thalf.eff.ivint.all                   day
#> 93                    hr     thalf.eff.ivint.last                   day
#> 94                    hr          mrt.sparse.last                   day
#> 95                    hr               mrt.iv.all                   day
#> 96                    hr         thalf.eff.iv.all                   day
#> 97                    hr              mrt.inf.obs                   day
#> 98                    hr             mrt.inf.pred                   day
#> 99                    hr          mrt.int.inf.obs                   day
#> 100                   hr         mrt.int.inf.pred                   day
#> 101                   hr           mrt.iv.inf.obs                   day
#> 102                   hr          mrt.iv.inf.pred                   day
#> 103                   hr       mrt.ivint.inf.pred                   day
#> 104                   hr        mrt.ivint.inf.obs                   day
#> 105                   hr           mrt.md.inf.obs                   day
#> 106                   hr          mrt.md.inf.pred                   day
#> 107                   hr         mrt.ivmd.inf.obs                   day
#> 108                   hr        mrt.ivmd.inf.pred                   day
#> 109                   hr        thalf.eff.inf.obs                   day
#> 110                   hr       thalf.eff.inf.pred                   day
#> 111                   hr   thalf.eff.int.inf.pred                   day
#> 112                   hr    thalf.eff.int.inf.obs                   day
#> 113                   hr     thalf.eff.iv.inf.obs                   day
#> 114                   hr    thalf.eff.iv.inf.pred                   day
#> 115                   hr thalf.eff.ivint.inf.pred                   day
#> 116                   hr  thalf.eff.ivint.inf.obs                   day
#> 117                   hr               mrt.iv.obs                   day
#> 118                   hr              mrt.iv.pred                   day
#> 119                   hr             mrt.ivmd.obs                   day
#> 120                   hr            mrt.ivmd.pred                   day
#> 121                   hr               mrt.md.obs                   day
#> 122                   hr              mrt.md.pred                   day
#> 123                   hr                  mrt.obs                   day
#> 124                   hr                 mrt.pred                   day
#> 125                   hr         thalf.eff.iv.obs                   day
#> 126                   hr        thalf.eff.iv.pred                   day
#> 127                   hr            thalf.eff.obs                   day
#> 128                   hr           thalf.eff.pred                   day
#> 129                   hr               time_above                   day
#> 130                 1/hr                 lambda.z                 1/day
#> 131                 1/hr                 kel.last                 1/day
#> 132                 1/hr              kel.iv.last                 1/day
#> 133                 1/hr                  kel.all                 1/day
#> 134                 1/hr              kel.int.all                 1/day
#> 135                 1/hr             kel.int.last                 1/day
#> 136                 1/hr            kel.ivint.all                 1/day
#> 137                 1/hr           kel.ivint.last                 1/day
#> 138                 1/hr               kel.iv.all                 1/day
#> 139                 1/hr          kel.sparse.last                 1/day
#> 140                 1/hr              kel.inf.obs                 1/day
#> 141                 1/hr             kel.inf.pred                 1/day
#> 142                 1/hr           kel.iv.inf.obs                 1/day
#> 143                 1/hr          kel.iv.inf.pred                 1/day
#> 144                 1/hr          kel.int.inf.obs                 1/day
#> 145                 1/hr         kel.int.inf.pred                 1/day
#> 146                 1/hr       kel.ivint.inf.pred                 1/day
#> 147                 1/hr        kel.ivint.inf.obs                 1/day
#> 148                 1/hr               kel.iv.obs                 1/day
#> 149                 1/hr              kel.iv.pred                 1/day
#> 150                 1/hr                  kel.obs                 1/day
#> 151                 1/hr                 kel.pred                 1/day
#> 152                ng/mL                       c0                 ng/mL
#> 153                ng/mL                     cmax                 ng/mL
#> 154                ng/mL                     cmin                 ng/mL
#> 155                ng/mL                clast.obs                 ng/mL
#> 156                ng/mL                 cav.last                 ng/mL
#> 157                ng/mL             cav.int.last                 ng/mL
#> 158                ng/mL              cav.int.all                 ng/mL
#> 159                ng/mL                  cav.all                 ng/mL
#> 160                ng/mL           cav.ivint.last                 ng/mL
#> 161                ng/mL            cav.ivint.all                 ng/mL
#> 162                ng/mL                  ctrough                 ng/mL
#> 163                ng/mL                   cstart                 ng/mL
#> 164                ng/mL                     ceoi                 ng/mL
#> 165                ng/mL               clast.pred                 ng/mL
#> 166                ng/mL              cav.iv.last                 ng/mL
#> 167                ng/mL               cav.iv.all                 ng/mL
#> 168                ng/mL          cav.int.inf.obs                 ng/mL
#> 169                ng/mL         cav.int.inf.pred                 ng/mL
#> 170                ng/mL        cav.ivint.inf.obs                 ng/mL
#> 171                ng/mL       cav.ivint.inf.pred                 ng/mL
#> 172                ng/mL                      cav                 ng/mL
#> 173                   mg                       ae                    mg
#> 174           mg/(mg/kg)                       fe            mg/(mg/kg)
#> 175                mg/kg                  totdose                 mg/kg
#> 176      (ng/mL)/(mg/kg)                  cmax.dn       (ng/mL)/(mg/kg)
#> 177      (ng/mL)/(mg/kg)                  cmin.dn       (ng/mL)/(mg/kg)
#> 178      (ng/mL)/(mg/kg)             clast.obs.dn       (ng/mL)/(mg/kg)
#> 179      (ng/mL)/(mg/kg)            clast.pred.dn       (ng/mL)/(mg/kg)
#> 180      (ng/mL)/(mg/kg)              cav.last.dn       (ng/mL)/(mg/kg)
#> 181      (ng/mL)/(mg/kg)               ctrough.dn       (ng/mL)/(mg/kg)
#> 182      (ng/mL)/(mg/kg)                   cav.dn       (ng/mL)/(mg/kg)
#> 183      (mg/kg)/(ng/mL)                 vss.last       (mg/kg)/(ng/mL)
#> 184      (mg/kg)/(ng/mL)              vss.iv.last       (mg/kg)/(ng/mL)
#> 185      (mg/kg)/(ng/mL)                  vss.all       (mg/kg)/(ng/mL)
#> 186      (mg/kg)/(ng/mL)              vss.int.all       (mg/kg)/(ng/mL)
#> 187      (mg/kg)/(ng/mL)             vss.int.last       (mg/kg)/(ng/mL)
#> 188      (mg/kg)/(ng/mL)            vss.ivint.all       (mg/kg)/(ng/mL)
#> 189      (mg/kg)/(ng/mL)           vss.ivint.last       (mg/kg)/(ng/mL)
#> 190      (mg/kg)/(ng/mL)                    volpk       (mg/kg)/(ng/mL)
#> 191      (mg/kg)/(ng/mL)                   vz.all       (mg/kg)/(ng/mL)
#> 192      (mg/kg)/(ng/mL)               vz.int.all       (mg/kg)/(ng/mL)
#> 193      (mg/kg)/(ng/mL)              vz.int.last       (mg/kg)/(ng/mL)
#> 194      (mg/kg)/(ng/mL)                vz.iv.all       (mg/kg)/(ng/mL)
#> 195      (mg/kg)/(ng/mL)               vz.iv.last       (mg/kg)/(ng/mL)
#> 196      (mg/kg)/(ng/mL)             vz.ivint.all       (mg/kg)/(ng/mL)
#> 197      (mg/kg)/(ng/mL)            vz.ivint.last       (mg/kg)/(ng/mL)
#> 198      (mg/kg)/(ng/mL)                  vz.last       (mg/kg)/(ng/mL)
#> 199      (mg/kg)/(ng/mL)               vss.iv.all       (mg/kg)/(ng/mL)
#> 200      (mg/kg)/(ng/mL)          vss.sparse.last       (mg/kg)/(ng/mL)
#> 201      (mg/kg)/(ng/mL)               vz.inf.obs       (mg/kg)/(ng/mL)
#> 202      (mg/kg)/(ng/mL)              vz.inf.pred       (mg/kg)/(ng/mL)
#> 203      (mg/kg)/(ng/mL)           vz.int.inf.obs       (mg/kg)/(ng/mL)
#> 204      (mg/kg)/(ng/mL)          vz.int.inf.pred       (mg/kg)/(ng/mL)
#> 205      (mg/kg)/(ng/mL)            vz.iv.inf.obs       (mg/kg)/(ng/mL)
#> 206      (mg/kg)/(ng/mL)           vz.iv.inf.pred       (mg/kg)/(ng/mL)
#> 207      (mg/kg)/(ng/mL)        vz.ivint.inf.pred       (mg/kg)/(ng/mL)
#> 208      (mg/kg)/(ng/mL)         vz.ivint.inf.obs       (mg/kg)/(ng/mL)
#> 209      (mg/kg)/(ng/mL)           vz.sparse.last       (mg/kg)/(ng/mL)
#> 210      (mg/kg)/(ng/mL)              vss.inf.obs       (mg/kg)/(ng/mL)
#> 211      (mg/kg)/(ng/mL)             vss.inf.pred       (mg/kg)/(ng/mL)
#> 212      (mg/kg)/(ng/mL)           vss.iv.inf.obs       (mg/kg)/(ng/mL)
#> 213      (mg/kg)/(ng/mL)          vss.iv.inf.pred       (mg/kg)/(ng/mL)
#> 214      (mg/kg)/(ng/mL)           vss.md.inf.obs       (mg/kg)/(ng/mL)
#> 215      (mg/kg)/(ng/mL)          vss.md.inf.pred       (mg/kg)/(ng/mL)
#> 216      (mg/kg)/(ng/mL)         vss.ivmd.inf.obs       (mg/kg)/(ng/mL)
#> 217      (mg/kg)/(ng/mL)        vss.ivmd.inf.pred       (mg/kg)/(ng/mL)
#> 218      (mg/kg)/(ng/mL)          vss.int.inf.obs       (mg/kg)/(ng/mL)
#> 219      (mg/kg)/(ng/mL)         vss.int.inf.pred       (mg/kg)/(ng/mL)
#> 220      (mg/kg)/(ng/mL)       vss.ivint.inf.pred       (mg/kg)/(ng/mL)
#> 221      (mg/kg)/(ng/mL)        vss.ivint.inf.obs       (mg/kg)/(ng/mL)
#> 222      (mg/kg)/(ng/mL)               vss.iv.obs       (mg/kg)/(ng/mL)
#> 223      (mg/kg)/(ng/mL)              vss.iv.pred       (mg/kg)/(ng/mL)
#> 224      (mg/kg)/(ng/mL)             vss.ivmd.obs       (mg/kg)/(ng/mL)
#> 225      (mg/kg)/(ng/mL)            vss.ivmd.pred       (mg/kg)/(ng/mL)
#> 226      (mg/kg)/(ng/mL)               vss.md.obs       (mg/kg)/(ng/mL)
#> 227      (mg/kg)/(ng/mL)              vss.md.pred       (mg/kg)/(ng/mL)
#> 228      (mg/kg)/(ng/mL)                  vss.obs       (mg/kg)/(ng/mL)
#> 229      (mg/kg)/(ng/mL)                 vss.pred       (mg/kg)/(ng/mL)
#> 230      (mg/kg)/(ng/mL)                vz.iv.obs       (mg/kg)/(ng/mL)
#> 231      (mg/kg)/(ng/mL)               vz.iv.pred       (mg/kg)/(ng/mL)
#> 232      (mg/kg)/(ng/mL)                   vz.obs       (mg/kg)/(ng/mL)
#> 233      (mg/kg)/(ng/mL)                  vz.pred       (mg/kg)/(ng/mL)
#> 234             hr*ng/mL                  auclast             day*ng/mL
#> 235             hr*ng/mL               auclast_se             day*ng/mL
#> 236             hr*ng/mL                   aucall             day*ng/mL
#> 237             hr*ng/mL                aucall_se             day*ng/mL
#> 238             hr*ng/mL              aucint.last             day*ng/mL
#> 239             hr*ng/mL               aucint.all             day*ng/mL
#> 240             hr*ng/mL            aucivint.last             day*ng/mL
#> 241             hr*ng/mL             aucivint.all             day*ng/mL
#> 242             hr*ng/mL     aucabove.predose.all             day*ng/mL
#> 243             hr*ng/mL      aucabove.trough.all             day*ng/mL
#> 244             hr*ng/mL           sparse_auclast             day*ng/mL
#> 245             hr*ng/mL            sparse_auc_se             day*ng/mL
#> 246             hr*ng/mL                aucivlast             day*ng/mL
#> 247             hr*ng/mL             aucivlast_se             day*ng/mL
#> 248             hr*ng/mL                 aucivall             day*ng/mL
#> 249             hr*ng/mL              aucivall_se             day*ng/mL
#> 250             hr*ng/mL               aucinf.obs             day*ng/mL
#> 251             hr*ng/mL            aucinf.obs_se             day*ng/mL
#> 252             hr*ng/mL              aucinf.pred             day*ng/mL
#> 253             hr*ng/mL           aucint.inf.obs             day*ng/mL
#> 254             hr*ng/mL          aucint.inf.pred             day*ng/mL
#> 255             hr*ng/mL         aucivint.inf.obs             day*ng/mL
#> 256             hr*ng/mL        aucivint.inf.pred             day*ng/mL
#> 257             hr*ng/mL             aucivinf.obs             day*ng/mL
#> 258             hr*ng/mL          aucivinf.obs_se             day*ng/mL
#> 259             hr*ng/mL            aucivinf.pred             day*ng/mL
#> 260           hr^2*ng/mL                 aumclast           day^2*ng/mL
#> 261           hr^2*ng/mL              aumclast_se           day^2*ng/mL
#> 262           hr^2*ng/mL                  aumcall           day^2*ng/mL
#> 263           hr^2*ng/mL               aumcall_se           day^2*ng/mL
#> 264           hr^2*ng/mL             aumcint.last           day^2*ng/mL
#> 265           hr^2*ng/mL              aumcint.all           day^2*ng/mL
#> 266           hr^2*ng/mL           aumcivint.last           day^2*ng/mL
#> 267           hr^2*ng/mL            aumcivint.all           day^2*ng/mL
#> 268           hr^2*ng/mL          sparse_aumclast           day^2*ng/mL
#> 269           hr^2*ng/mL           sparse_aumc_se           day^2*ng/mL
#> 270           hr^2*ng/mL               aumcivlast           day^2*ng/mL
#> 271           hr^2*ng/mL            aumcivlast_se           day^2*ng/mL
#> 272           hr^2*ng/mL                aumcivall           day^2*ng/mL
#> 273           hr^2*ng/mL             aumcivall_se           day^2*ng/mL
#> 274           hr^2*ng/mL              aumcinf.obs           day^2*ng/mL
#> 275           hr^2*ng/mL           aumcinf.obs_se           day^2*ng/mL
#> 276           hr^2*ng/mL             aumcinf.pred           day^2*ng/mL
#> 277           hr^2*ng/mL          aumcint.inf.obs           day^2*ng/mL
#> 278           hr^2*ng/mL         aumcint.inf.pred           day^2*ng/mL
#> 279           hr^2*ng/mL       aumcivint.inf.pred           day^2*ng/mL
#> 280           hr^2*ng/mL        aumcivint.inf.obs           day^2*ng/mL
#> 281           hr^2*ng/mL            aumcivinf.obs           day^2*ng/mL
#> 282           hr^2*ng/mL         aumcivinf.obs_se           day^2*ng/mL
#> 283           hr^2*ng/mL           aumcivinf.pred           day^2*ng/mL
#> 284                mg/hr                    ermax                mg/day
#> 285                mg/hr                    erint                mg/day
#> 286                mg/hr                    erlst                mg/day
#> 287   (hr*ng/mL)/(mg/kg)               auclast.dn   (day*ng/mL)/(mg/kg)
#> 288   (hr*ng/mL)/(mg/kg)                aucall.dn   (day*ng/mL)/(mg/kg)
#> 289   (hr*ng/mL)/(mg/kg)            aucinf.obs.dn   (day*ng/mL)/(mg/kg)
#> 290   (hr*ng/mL)/(mg/kg)           aucinf.pred.dn   (day*ng/mL)/(mg/kg)
#> 291 (hr^2*ng/mL)/(mg/kg)              aumclast.dn (day^2*ng/mL)/(mg/kg)
#> 292 (hr^2*ng/mL)/(mg/kg)               aumcall.dn (day^2*ng/mL)/(mg/kg)
#> 293 (hr^2*ng/mL)/(mg/kg)           aumcinf.obs.dn (day^2*ng/mL)/(mg/kg)
#> 294 (hr^2*ng/mL)/(mg/kg)          aumcinf.pred.dn (day^2*ng/mL)/(mg/kg)
#> 295   (mg/kg)/(hr*ng/mL)                  cl.last   (mg/kg)/(day*ng/mL)
#> 296   (mg/kg)/(hr*ng/mL)                   cl.all   (mg/kg)/(day*ng/mL)
#> 297   (mg/kg)/(hr*ng/mL)               cl.int.all   (mg/kg)/(day*ng/mL)
#> 298   (mg/kg)/(hr*ng/mL)              cl.int.last   (mg/kg)/(day*ng/mL)
#> 299   (mg/kg)/(hr*ng/mL)             cl.ivint.all   (mg/kg)/(day*ng/mL)
#> 300   (mg/kg)/(hr*ng/mL)            cl.ivint.last   (mg/kg)/(day*ng/mL)
#> 301   (mg/kg)/(hr*ng/mL)                cl.iv.all   (mg/kg)/(day*ng/mL)
#> 302   (mg/kg)/(hr*ng/mL)               cl.iv.last   (mg/kg)/(day*ng/mL)
#> 303   (mg/kg)/(hr*ng/mL)           cl.sparse.last   (mg/kg)/(day*ng/mL)
#> 304   (mg/kg)/(hr*ng/mL)               cl.inf.obs   (mg/kg)/(day*ng/mL)
#> 305   (mg/kg)/(hr*ng/mL)              cl.inf.pred   (mg/kg)/(day*ng/mL)
#> 306   (mg/kg)/(hr*ng/mL)           cl.int.inf.obs   (mg/kg)/(day*ng/mL)
#> 307   (mg/kg)/(hr*ng/mL)          cl.int.inf.pred   (mg/kg)/(day*ng/mL)
#> 308   (mg/kg)/(hr*ng/mL)            cl.iv.inf.obs   (mg/kg)/(day*ng/mL)
#> 309   (mg/kg)/(hr*ng/mL)           cl.iv.inf.pred   (mg/kg)/(day*ng/mL)
#> 310   (mg/kg)/(hr*ng/mL)        cl.ivint.inf.pred   (mg/kg)/(day*ng/mL)
#> 311   (mg/kg)/(hr*ng/mL)         cl.ivint.inf.obs   (mg/kg)/(day*ng/mL)
#> 312   (mg/kg)/(hr*ng/mL)                cl.iv.obs   (mg/kg)/(day*ng/mL)
#> 313   (mg/kg)/(hr*ng/mL)               cl.iv.pred   (mg/kg)/(day*ng/mL)
#> 314   (mg/kg)/(hr*ng/mL)                   cl.obs   (mg/kg)/(day*ng/mL)
#> 315   (mg/kg)/(hr*ng/mL)                  cl.pred   (mg/kg)/(day*ng/mL)
#> 316        mg/(hr*ng/mL)                 clr.last        mg/(day*ng/mL)
#> 317        mg/(hr*ng/mL)         clr.int.inf.pred        mg/(day*ng/mL)
#> 318        mg/(hr*ng/mL)          clr.int.inf.obs        mg/(day*ng/mL)
#> 319        mg/(hr*ng/mL)              clr.int.all        mg/(day*ng/mL)
#> 320        mg/(hr*ng/mL)             clr.int.last        mg/(day*ng/mL)
#> 321        mg/(hr*ng/mL)                  clr.all        mg/(day*ng/mL)
#> 322        mg/(hr*ng/mL)              clr.inf.obs        mg/(day*ng/mL)
#> 323        mg/(hr*ng/mL)             clr.inf.pred        mg/(day*ng/mL)
#> 324        mg/(hr*ng/mL)                  clr.obs        mg/(day*ng/mL)
#> 325        mg/(hr*ng/mL)                 clr.pred        mg/(day*ng/mL)
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
#> 109       0.041666667
#> 110       0.041666667
#> 111       0.041666667
#> 112       0.041666667
#> 113       0.041666667
#> 114       0.041666667
#> 115       0.041666667
#> 116       0.041666667
#> 117       0.041666667
#> 118       0.041666667
#> 119       0.041666667
#> 120       0.041666667
#> 121       0.041666667
#> 122       0.041666667
#> 123       0.041666667
#> 124       0.041666667
#> 125       0.041666667
#> 126       0.041666667
#> 127       0.041666667
#> 128       0.041666667
#> 129       0.041666667
#> 130      24.000000000
#> 131      24.000000000
#> 132      24.000000000
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
#> 144      24.000000000
#> 145      24.000000000
#> 146      24.000000000
#> 147      24.000000000
#> 148      24.000000000
#> 149      24.000000000
#> 150      24.000000000
#> 151      24.000000000
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
#> 234       0.041666667
#> 235       0.041666667
#> 236       0.041666667
#> 237       0.041666667
#> 238       0.041666667
#> 239       0.041666667
#> 240       0.041666667
#> 241       0.041666667
#> 242       0.041666667
#> 243       0.041666667
#> 244       0.041666667
#> 245       0.041666667
#> 246       0.041666667
#> 247       0.041666667
#> 248       0.041666667
#> 249       0.041666667
#> 250       0.041666667
#> 251       0.041666667
#> 252       0.041666667
#> 253       0.041666667
#> 254       0.041666667
#> 255       0.041666667
#> 256       0.041666667
#> 257       0.041666667
#> 258       0.041666667
#> 259       0.041666667
#> 260       0.001736111
#> 261       0.001736111
#> 262       0.001736111
#> 263       0.001736111
#> 264       0.001736111
#> 265       0.001736111
#> 266       0.001736111
#> 267       0.001736111
#> 268       0.001736111
#> 269       0.001736111
#> 270       0.001736111
#> 271       0.001736111
#> 272       0.001736111
#> 273       0.001736111
#> 274       0.001736111
#> 275       0.001736111
#> 276       0.001736111
#> 277       0.001736111
#> 278       0.001736111
#> 279       0.001736111
#> 280       0.001736111
#> 281       0.001736111
#> 282       0.001736111
#> 283       0.001736111
#> 284      24.000000000
#> 285      24.000000000
#> 286      24.000000000
#> 287       0.041666667
#> 288       0.041666667
#> 289       0.041666667
#> 290       0.041666667
#> 291       0.001736111
#> 292       0.001736111
#> 293       0.001736111
#> 294       0.001736111
#> 295      24.000000000
#> 296      24.000000000
#> 297      24.000000000
#> 298      24.000000000
#> 299      24.000000000
#> 300      24.000000000
#> 301      24.000000000
#> 302      24.000000000
#> 303      24.000000000
#> 304      24.000000000
#> 305      24.000000000
#> 306      24.000000000
#> 307      24.000000000
#> 308      24.000000000
#> 309      24.000000000
#> 310      24.000000000
#> 311      24.000000000
#> 312      24.000000000
#> 313      24.000000000
#> 314      24.000000000
#> 315      24.000000000
#> 316      24.000000000
#> 317      24.000000000
#> 318      24.000000000
#> 319      24.000000000
#> 320      24.000000000
#> 321      24.000000000
#> 322      24.000000000
#> 323      24.000000000
#> 324      24.000000000
#> 325      24.000000000
```
