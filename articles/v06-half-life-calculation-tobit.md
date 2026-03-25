# Half-life calculation with Tobit regression

``` r
library(PKNCA)
#> 
#> Attaching package: 'PKNCA'
#> The following object is masked from 'package:stats':
#> 
#>     filter
```

## Half-life calculation with Tobit regression

Half-life calculation with Tobit regression allows inclusion of
concentrations that are below the lower limit of quantification in the
half-life estimate.

### Comparison to semi-log regression

Typical half-life calculation uses curve-stripping semi-log regression
of the natural logarithm of the concentration by time. Based on the use
of the logarithm of the concentration, concentrations below the lower
limit of quantification (LLOQ) which are set to zero are ignored.

Tobit regression allows inclusion of the concentrations below the LLOQ
in the half-life calculation. Tobit regression for half-life is
equivalent to using Beal’s M3 method in population pharmacokinetic (PK)
models.

With Tobit regression, a line is fit using maximum likelihood. For
points above the LLOQ, the likelihood is based on the probability
density at the observed concentration. For points below the LLOQ, the
likelihood is based on the cumulative probability distribution function
from negative infinity to the limit of quantification.

### Automatic point selection

### Automatic point selection with semi-log regression

With semi-log regression, the typical method used to automatically
select concentrations for inclusion in the half-life estimate is to:

1.  Omit all concentrations that are missing.
2.  Omit all concentrations that are below the LLOQ.
3.  Estimate the half-life for each set of points from the first
    concentration measure after T_(max) to the third measure before
    T_(last).
4.  Select the best half-life with the following criteria, in order:
    1.  The adjusted r-squared must be within a tolerance factor
        (typically 0.0001) of the largest adjusted r-squared.
    2.  The $\lambda_{z}$ value (slope for the half-life line) must be
        positive; in other words, the half-life slope must be
        decreasing.
    3.  If multiple choices of points fit the above criteria, choose the
        one with the most concentration measurements included.

For comparison with PKNCA, note that Phoenix WinNonlin switches the
order for selection of 4.1 and 4.2 above. So, if the best adjusted
r-squared is for an increasing slope but there is another adjusted
r-squared with a decreasing slope, Phoenix will report the half-life.

### Automatic point selection with Tobit regression

With Tobit regression, the method is generally similar to the semi-log
regression with two changes. The first change is that concentrations
below the LLOQ are retained in the estimate. The second change is that
the adjusted r-squared is not possible to calculate when including
points below the LLOQ, so the minimum standard deviation estimate is
used.

The selection method below results in effectively the same estimates for
half-life when all points are above the LLOQ and improved estimates for
half-life when some points are below the LLOQ. Future research may
investigate optimization of this method.

The steps for Tobit regression are:

1.  Omit all concentrations that are missing.
2.  Estimate the half-life for each set of points from the first
    concentration measure after T_(max) to the third measure before
    T_(last) while including all points below the LLOQ after T_(last).
3.  Select the best half-life with the following criteria, in order:
    1.  The estimated standard deviation of the slope is minimized.
    2.  The $\lambda_{z}$ value (slope for the half-life line) must be
        positive; in other words, the half-life slope must be
        decreasing.

## Comparison of Tobit and semi-log regression

In almost all scenarios, Tobit regression using the algorithm above
improves the half-life estimate compared to semi-log regression. In the
figure below, concentration-time profiles were simulated with 1-, 2-,
and 3-compartment linear PK models with intravenous or extravascular
administration and a variety of compartmental model parameters. The true
half-life was calculated based on the compartmental model parameters.
Then, the ratio of the estimated to true half-life was calculated.
Values closer to 1 indicate a better fit and values farther from 1
indicate a poorer fit.

![The empirical cumulative distribution function for ratio of estimated
to theoretical half-lives for Tobit regression (aqua line) and semi-log
regression (red line) are
shown.](v06-half-life-calculation-tobit_figure_1.svg)

The empirical cumulative distribution function for ratio of estimated to
theoretical half-lives for Tobit regression (aqua line) and semi-log
regression (red line) are shown.

Tobit regression performs universally better than least-squares up to
the estimated theoretical half-life, and better at \>2-fold above the
theoretical half-life while least-squares performs slightly better
between the theoretical and 2-fold above. The fact that the Tobit
regression cumulative distribution function is closer to 1 across the
range of simulations indicates that Tobit regression provides better
half-life estimate across a broad range of data.

## Usage

### Basic usage: a single subject

The `hl_method` argument to
[`pk.calc.half.life()`](http://humanpred.github.io/pknca/reference/pk.calc.half.life.md)
selects the estimation method. When using `"tobit"`, the `lloq` argument
is required and must be either a scalar (one LLOQ applied to all
observations) or a vector the same length as `conc`.

#### Example 1: All observations above the LLOQ

When no observations are below the LLOQ, Tobit and log-linear regression
produce essentially the same answer.

``` r
conc_no_blq <- c(10, 5, 2.5, 1.25, 0.625)
time_points  <- c(0,  1, 2,   3,    4)
lloq         <- 0.1   # well below all observations

hl_loglinear <- pk.calc.half.life(
  conc = conc_no_blq,
  time = time_points,
  allow.tmax.in.half.life = TRUE
)

hl_tobit <- pk.calc.half.life(
  conc = conc_no_blq,
  time = time_points,
  lloq = lloq,
  hl_method = "tobit",
  allow.tmax.in.half.life = TRUE
)
#> Warning: Tobit half-life optimization did not converge (code 10)

cat("Log-linear half-life:", round(hl_loglinear$half.life, 3), "\n")
#> Log-linear half-life: 1
cat("Tobit half-life:     ", round(hl_tobit$half.life, 3),    "\n")
#> Tobit half-life:      1
```

Note the columns that are returned:

``` r
# Log-linear returns r-squared and related diagnostics
names(hl_loglinear)
#>  [1] "lambda.z"            "r.squared"           "adj.r.squared"      
#>  [4] "lambda.z.corrxy"     "lambda.z.time.first" "lambda.z.time.last" 
#>  [7] "lambda.z.n.points"   "clast.pred"          "half.life"          
#> [10] "span.ratio"          "tmax"                "tlast"

# Tobit returns tobit_residual and BLQ point counts instead
names(hl_tobit)
#>  [1] "lambda.z"              "lambda.z.time.first"   "lambda.z.time.last"   
#>  [4] "lambda.z.n.points"     "lambda.z.n.points_blq" "clast.pred"           
#>  [7] "half.life"             "span.ratio"            "tobit_residual"       
#> [10] "adj_tobit_residual"    "tmax"                  "tlast"
```

#### Example 2: BLQ observations before T_(last)

When some observations are below the LLOQ, the log-linear method drops
them entirely. Tobit regression treats them as left-censored, which can
provide a better estimate.

``` r
lloq <- 1.0
conc_true  <- c(10, 5, 2.5, 1.25, 0.5, 0.2)
time_points <- c(0,  1, 2,   3,    4,   5)
# Observations below the LLOQ are reported as zero
conc_obs <- ifelse(conc_true < lloq, 0, conc_true)

cat("Observed concentrations:", conc_obs, "\n")
#> Observed concentrations: 10 5 2.5 1.25 0 0
cat("LLOQ:", lloq, "\n")
#> LLOQ: 1
cat("Number of BLQ observations:", sum(conc_obs < lloq), "\n")
#> Number of BLQ observations: 2

hl_loglinear <- pk.calc.half.life(
  conc = conc_obs,
  time = time_points,
  allow.tmax.in.half.life = TRUE
)

hl_tobit <- pk.calc.half.life(
  conc = conc_obs,
  time = time_points,
  lloq = lloq,
  hl_method = "tobit",
  allow.tmax.in.half.life = TRUE
)

cat("\nLog-linear (drops BLQ):\n")
#> 
#> Log-linear (drops BLQ):
cat("  Half-life:      ", round(hl_loglinear$half.life, 3), "\n")
#>   Half-life:       1
cat("  Points used:    ", hl_loglinear$lambda.z.n.points, "\n")
#>   Points used:     4

cat("\nTobit (includes BLQ as censored):\n")
#> 
#> Tobit (includes BLQ as censored):
cat("  Half-life:      ", round(hl_tobit$half.life, 3), "\n")
#>   Half-life:       1
cat("  Total points:   ", hl_tobit$lambda.z.n.points, "\n")
#>   Total points:    6
cat("  BLQ points:     ", hl_tobit$lambda.z.n.points_blq, "\n")
#>   BLQ points:      2
cat("  Tobit residual: ", round(hl_tobit$tobit_residual, 4), "\n")
#>   Tobit residual:  0
```

### Using the global option

To use Tobit regression for all half-life calculations in a session, set
the global option. Calculations that do not explicitly set `hl_method`
will then use Tobit regression by default.

``` r
PKNCA.options(hl_method = "tobit")

# Now all pk.calc.half.life() calls default to Tobit
# Reset to the package default when done:
PKNCA.options(default = TRUE)
```

### Full NCA workflow with PKNCAdata

The `lloq` argument can be passed through the interval calculation via
the `options` list when running a full NCA.

``` r
# Suppose d_conc is your concentration data frame with columns
# subject, time, conc, and your LLOQ is 1.0

o_conc <- PKNCAconc(d_conc, conc ~ time | subject)
o_dose <- PKNCAdose(d_dose, dose ~ time | subject)
o_data <- PKNCAdata(
  o_conc, o_dose,
  intervals = data.frame(start = 0, end = Inf, half.life = TRUE),
  options = list(hl_method = "tobit")
)
# Note: lloq must be provided per-subject in the concentration data or
# as a scalar in the options when using the Tobit method in pk.nca().
```

### Controlling Tobit point selection

The `tobit_n_points_penalty` option controls how the number of points
influences window selection. With the default value of 0 the window with
the smallest Tobit residual is selected. Positive values penalize larger
windows, requiring them to have a meaningfully lower residual to be
preferred.

``` r
# Penalise larger windows slightly
PKNCA.options(tobit_n_points_penalty = 0.5)
PKNCA.options(default = TRUE)  # reset
```

The `tobit_optim_control` option passes a list of control parameters
directly to [`stats::optim()`](https://rdrr.io/r/stats/optim.html). This
is rarely needed but can help when the default optimization settings
fail to converge for unusual concentration-time profiles.

``` r
# Increase the maximum number of iterations
PKNCA.options(tobit_optim_control = list(maxit = 1000))
PKNCA.options(default = TRUE)  # reset
```
