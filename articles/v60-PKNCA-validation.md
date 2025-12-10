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

    ## [1] "2025-12-10"

``` r
sessionInfo()
```

    ## R version 4.5.2 (2025-10-31)
    ## Platform: x86_64-pc-linux-gnu
    ## Running under: Ubuntu 24.04.3 LTS
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
    ## [1] dplyr_1.1.4       testthat_3.3.1    knitr_1.50        PKNCA_0.12.1.9000
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] vctrs_0.6.5       nlme_3.1-168      cli_3.6.5         rlang_1.1.6      
    ##  [5] xfun_0.54         generics_0.1.4    textshaping_1.0.4 jsonlite_2.0.0   
    ##  [9] glue_1.8.0        htmltools_0.5.9   ragg_1.5.0        sass_0.4.10      
    ## [13] brio_1.1.5        rmarkdown_2.30    grid_4.5.2        tibble_3.3.0     
    ## [17] evaluate_1.0.5    jquerylib_0.1.4   fastmap_1.2.0     yaml_2.3.11      
    ## [21] lifecycle_1.0.4   compiler_4.5.2    fs_1.6.6          Rcpp_1.1.0       
    ## [25] pkgconfig_2.0.3   lattice_0.22-7    systemfonts_1.3.1 digest_0.6.39    
    ## [29] R6_2.6.1          tidyselect_1.2.1  pillar_1.11.1     magrittr_2.0.4   
    ## [33] bslib_0.9.0       tools_4.5.2       units_1.0-0       pkgdown_2.2.0    
    ## [37] cachem_1.1.0      desc_1.4.3
