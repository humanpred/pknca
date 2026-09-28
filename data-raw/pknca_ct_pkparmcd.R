# Generates the internal PKPARMCD/PKPARM CDISC controlled-terminology
# snapshot used by pknca_cdisc_codes() and the common-tier CDISC compliance
# test (test-cdisc-codes.R).  PKNCA does not depend on cdiscdata at run time;
# this script is run by a maintainer whenever the CT should be refreshed, and
# its output (R/sysdata.rda) is what ships in the package.
#
# Requires cdiscdata (https://github.com/... ; not a PKNCA dependency):
#   devtools::install("path/to/cdiscdata")

library(cdiscdata)

# Pin the version explicitly (the newest available) so a re-run of this
# script is reproducible even after a newer CT release ships.
pknca_ct_pkparmcd_version <- available_ct_versions("sdtm")[1]
ct <- get_ct(type = "sdtm", version = pknca_ct_pkparmcd_version)

# C85839 = "PK Parameters Code" (PKPARMCD), C85493 = "PK Parameters" (PKPARM).
# The two codelists share term_code, one term per PK parameter concept: the
# PKPARMCD row's `term` is the short code, the matching PKPARM row's `term` is
# the CT decode text used for PPTEST.
pkparmcd <- ct[ct$codelist_code %in% "C85839", c("term_code", "term")]
pkparm <- ct[ct$codelist_code %in% "C85493", c("term_code", "term")]
pknca_ct_pkparmcd <- merge(
  pkparmcd, pkparm,
  by = "term_code", suffixes = c("_cd", "_parm")
)
pknca_ct_pkparmcd <- data.frame(
  pptestcd_cdisc = pknca_ct_pkparmcd$term_cd,
  pptest_cdisc = pknca_ct_pkparmcd$term_parm,
  stringsAsFactors = FALSE
)

save(
  pknca_ct_pkparmcd, pknca_ct_pkparmcd_version,
  file = "R/sysdata.rda", version = 2, compress = "bzip2"
)
