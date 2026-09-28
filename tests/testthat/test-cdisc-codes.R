# A few common-tier parameters have no CDISC PKPARMCD equivalent at all (a
# sample count, a standard error, and a clearance based on an interval AUC
# extrapolated to infinity -- CDISC assigns no PP parameter code to any of
# those concepts).  See the comments at their add.interval.col()
# registrations.  Listed here explicitly so a *new* common-tier parameter
# without a valid CT mapping fails the test below instead of being silently
# accepted.
known_cdisc_gap_common <- c("count_conc", "sparse_auc_se", "cl.int.inf.obs")

test_that("common-tier CDISC codes are valid PKPARMCD codes with matching decode text", {
  skip_if_not_installed("cdiscdata")
  # cdiscdata 0.1.0's get_ct() looks up its dataset catalogue in its own
  # namespace's search path and errors unless the package is attached (not
  # just namespace-loaded), so `library()` it rather than using `::`.
  library(cdiscdata) # nolint

  ct <- get_ct(type = "sdtm")
  pkparmcd <- ct[ct$codelist_code %in% "C85839", c("term_code", "term")]
  pkparm <- ct[ct$codelist_code %in% "C85493", c("term_code", "term")]
  ct_map <- merge(pkparmcd, pkparm, by = "term_code", suffixes = c("_cd", "_parm"))
  decode <- stats::setNames(ct_map$term_parm, ct_map$term_cd)

  codes <- pknca_cdisc_codes()
  common <- codes[codes$tier %in% "common", ]
  to_check <- common[!(common$parameter %in% known_cdisc_gap_common), ]

  expect_true(nrow(to_check) > 0)
  expect_true(
    all(to_check$pptestcd_cdisc %in% names(decode)),
    info = paste(
      "Not in the CDISC PKPARMCD codelist:",
      paste(setdiff(to_check$pptestcd_cdisc, names(decode)), collapse = ", ")
    )
  )
  expect_equal(
    unname(decode[to_check$pptestcd_cdisc]),
    to_check$pptest_cdisc
  )
  expect_true(all(nchar(to_check$pptestcd_cdisc) <= 8))

  # The documented exceptions really are gaps, not typos: confirm they are
  # still not in the current CT so this list stays honest as CT evolves.
  gap_rows <- common[common$parameter %in% known_cdisc_gap_common, ]
  expect_true(all(!(gap_rows$pptestcd_cdisc %in% names(decode))))
})

test_that("every registered CDISC PPTESTCD is <=8 characters and PPTEST is <=40 characters", {
  codes <- pknca_cdisc_codes()
  # count_conc_measured is registered in R/exclude_nca.R, out of scope for
  # this change; tracked as a known violation so a *different* new violation
  # still fails loud.
  known_length_violation <- c("count_conc_measured")
  to_check <- codes[!(codes$parameter %in% known_length_violation), ]

  over_code <- to_check[nchar(to_check$pptestcd_cdisc) > 8, c("parameter", "variant", "pptestcd_cdisc")]
  expect_equal(nrow(over_code), 0L, info = paste(capture.output(print(over_code)), collapse = "\n"))

  over_test <- to_check[nchar(to_check$pptest_cdisc) > 40, c("parameter", "variant", "pptest_cdisc")]
  expect_equal(nrow(over_test), 0L, info = paste(capture.output(print(over_test)), collapse = "\n"))
})

test_that("pknca_cdisc_codes() reflects the live registry and flags CT membership", {
  codes <- pknca_cdisc_codes()
  expect_true(is.data.frame(codes))
  expect_setequal(
    names(codes),
    c("parameter", "tier", "variant", "pptestcd_cdisc", "pptest_cdisc", "in_ct")
  )
  expect_true("cmax" %in% codes$parameter)
  cmax_row <- codes[codes$parameter %in% "cmax", ]
  expect_equal(cmax_row$pptestcd_cdisc, "CMAX")
  expect_true(cmax_row$in_ct)

  # A route-keyed parameter expands into one row per route.
  cl_obs_rows <- codes[codes$parameter %in% "cl.obs", ]
  expect_setequal(cl_obs_rows$variant, c("extravascular", "intravascular"))
  expect_setequal(cl_obs_rows$pptestcd_cdisc, c("CLFO", "CLO"))
})
