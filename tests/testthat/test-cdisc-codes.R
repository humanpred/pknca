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

  ct <- cdiscdata::get_ct(type = "sdtm")
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
  # in_ct agrees with the live CT check just performed by hand above
  expect_true(all(to_check$in_ct))

  # The documented exceptions really are gaps, not typos: confirm they are
  # still not in the current CT so this list stays honest as CT evolves.
  gap_rows <- common[common$parameter %in% known_cdisc_gap_common, ]
  expect_true(all(!(gap_rows$pptestcd_cdisc %in% names(decode))))
  expect_true(all(!gap_rows$in_ct))
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

test_that("every registered parameter description is <=40 characters", {
  # add.interval.col() only warns about a long description when the package
  # loads, which no test sees
  descriptions <- vapply(get.interval.cols(), function(x) x$desc %||% NA_character_, FUN.VALUE = "")
  over_desc <- descriptions[!is.na(descriptions) & nchar(descriptions) > 40]
  expect_equal(length(over_desc), 0L, info = paste(names(over_desc), over_desc, sep = ": ", collapse = "\n"))
})

test_that("pknca_cdisc_codes() reflects the live registry", {
  codes <- pknca_cdisc_codes()
  expect_true(is.data.frame(codes))
  expect_setequal(
    names(codes),
    c("parameter", "tier", "variant", "pptestcd_cdisc", "pptest_cdisc", "in_ct")
  )
  expect_true("cmax" %in% codes$parameter)
  cmax_row <- codes[codes$parameter %in% "cmax", ]
  expect_equal(cmax_row$pptestcd_cdisc, "CMAX")

  # A route-keyed parameter expands into one row per route.
  cl_obs_rows <- codes[codes$parameter %in% "cl.obs", ]
  expect_setequal(cl_obs_rows$variant, c("extravascular", "intravascular"))
  expect_setequal(cl_obs_rows$pptestcd_cdisc, c("CLFO", "CLO"))
})

test_that("pknca_cdisc_codes() flags CT membership when cdiscdata is installed", {
  skip_if_not_installed("cdiscdata")
  codes <- pknca_cdisc_codes()
  cmax_row <- codes[codes$parameter %in% "cmax", ]
  expect_true(cmax_row$in_ct)
})

test_that("pknca_cdisc_codes()'s in_ct is NA with a message when cdiscdata is unavailable", {
  local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )
  expect_message(
    ret <- pknca_cdisc_in_ct(c("CMAX", "not-a-real-code")),
    class = "pknca_message_cdiscdata_unavailable"
  )
  expect_equal(ret, c(NA, NA))
})
