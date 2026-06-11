# PKNCA Validation

## Introduction

To run the tests, the package must be installed with its tests:

- To install from CRAN:
  - `install.packages(pkgs="PKNCA", INSTALL_opts="--install-tests", type="source")`
- To install from GitHub:
  - [`library(devtools)`](https://devtools.r-lib.org/)
  - `install_github("humanpred/pknca", INSTALL_opts="--install-tests")`

Testing and validation that results match in a local environment
compared to the original environment is an important part of
confirmation that a package works as expected.

Re-running this vignette in your local environment will confirm that
local results match those in the original package development. Test
success is confirmed by the existence of no failed tests; warnings are
expected during testing (and not shown in this vignette for that
reason); and some tests may be skipped, but those are expected as well.

## Summary of Testing

The following sentence is dynamically generated to summarize the testing
results: Tests were not run because tests are not installed.

## Session Information

``` r

Sys.Date()
```

    ## [1] "2026-06-11"

``` r

sessionInfo()
```

    ## R version 4.6.0 (2026-04-24)
    ## Platform: x86_64-pc-linux-gnu
    ## Running under: Ubuntu 24.04.4 LTS
    ## 
    ## Matrix products: default
    ## BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
    ## LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
    ## 
    ## locale:
    ##  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
    ##  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
    ##  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    ## [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
    ## 
    ## time zone: UTC
    ## tzcode source: system (glibc)
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ## [1] dplyr_1.2.1    testthat_3.3.2 knitr_1.51     PKNCA_0.12.2  
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] jsonlite_2.0.0    compiler_4.6.0    brio_1.1.5        tidyselect_1.2.1 
    ##  [5] Rcpp_1.1.1-1.1    jquerylib_0.1.4   systemfonts_1.3.2 textshaping_1.0.5
    ##  [9] yaml_2.3.12       fastmap_1.2.0     lattice_0.22-9    R6_2.6.1         
    ## [13] generics_0.1.4    tibble_3.3.1      desc_1.4.3        units_1.0-1      
    ## [17] bslib_0.11.0      pillar_1.11.1     rlang_1.2.0       cachem_1.1.0     
    ## [21] xfun_0.58         fs_2.1.0          sass_0.4.10       otel_0.2.0       
    ## [25] cli_3.6.6         pkgdown_2.2.0     magrittr_2.0.5    digest_0.6.39    
    ## [29] grid_4.6.0        lifecycle_1.0.5   nlme_3.1-169      vctrs_0.7.3      
    ## [33] evaluate_1.0.5    glue_1.8.1        ragg_1.5.2        rmarkdown_2.31   
    ## [37] tools_4.6.0       pkgconfig_2.0.3   htmltools_0.5.9
