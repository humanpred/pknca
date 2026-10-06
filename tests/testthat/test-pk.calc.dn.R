test_that("pk.calc.dn", {
  # Ensure correct calculation
  expect_equal(pk.calc.dn(1, 5), 0.2)
  expect_equal(pk.calc.dn(NA, 5), NA_real_)
  expect_equal(pk.calc.dn(1, NA), NA_real_)
})

test_that("pk.calc.cmax", {
  # Ensure that the formalsmap functionality works within pk.nca
  tmpconc <- generate.conc(2, 2, 0:24)
  tmpdose <- generate.dose(tmpconc)
  tmpconc <- merge(tmpconc, tmpdose[,c("ID", "treatment", "dose")])
  myconc <- PKNCAconc(tmpconc,
                      conc~time|treatment+dose+ID)
  mydose <- PKNCAdose(tmpdose,
                      dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose,
                      intervals=data.frame(start=0, end=24, auclast.dn=TRUE))
  myres <- pk.nca(mydata)
  expect_equal(myres$result$PPORRES[myres$result$PPTESTCD %in% "auclast"]/
                 myres$result$PPORRES[myres$result$PPTESTCD %in% "auclast.dn"],
               myres$result$dose[myres$result$PPTESTCD %in% "auclast"],
               info="Dose normalization works when requested as a parameter in pk.nca")
})

test_that("dose-normalized CDISC codes derive from dense/sparse mappings elementwise", {
  # auclast's own pptestcd_cdisc/pptest_cdisc are plain strings (CDISC has no
  # code distinguishing a sparse AUClast from one integrated per subject), so
  # auclast.dn gets the simple suffix behavior on both.
  expect_equal(get.interval.cols()[["auclast.dn"]]$pptestcd_cdisc, "AUCLSTD")
  expect_equal(
    get.interval.cols()[["auclast.dn"]]$pptest_cdisc,
    "AUC to Last Nonzero Conc by Dose"
  )
  # aumclast carries a dense/sparse *test name* mapping (CDISC has no separate
  # code for a sparsely estimated AUMClast, so only the test name
  # distinguishes it); the derived aumclast.dn test name must stay
  # elementwise distinguishable, while its code keeps the simple suffix
  # behavior.
  expect_equal(get.interval.cols()[["aumclast.dn"]]$pptestcd_cdisc, "AUMCLSTD")
  expect_equal(
    get.interval.cols()[["aumclast.dn"]]$pptest_cdisc,
    list(dense = "AUMC to Last Nonzero Conc by Dose", sparse = "Sparse AUMClast by Dose")
  )
})
