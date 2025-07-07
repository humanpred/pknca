test_that("normalize.data.frame works for basic normalization", {
  df <- data.frame(ID = 1:2, PPTESTCD = "cmax", PPORRES = c(10, 20), PPORRESU = "ng/mL")
  norm_table <- data.frame(ID = 1:2, normalization = c(2, 4), unit = "kg")
  res <- normalize(df, norm_table, parameters = "cmax", suffix = ".wn")
  expect_equal(res$PPSTRES, c(5, 5))
  expect_equal(res$PPSTRESU, c("ng/mL/kg", "ng/mL/kg"))
  expect_equal(res$PPTESTCD, c("cmax.wn", "cmax.wn"))
})


# Create a basic PKNCAresults object for use in tests
d_conc <- data.frame(ID = c(1, 1, 2, 2), analyte = c("A", "B"), time = 0:1, conc = c(10, 20, 30, 40))
o_conc <- PKNCAconc(tmpconc, conc~time|ID/analyte)
d_dose <- data.frame(ID = c(1, 2), dose = c(100, 200), time = 0, doseu = "mg")
o_dose <- PKNCAdose(tmpdose, dose~time|ID)
o_data <- PKNCAdata(o_conc, o_dose)
o_nca <- pk.nca(o_data)

test_that("normalize.PKNCAresults appends normalized parameters", {
  norm_table <- data.frame(ID = 1:2, normalization = 2, unit = "kg")
  res <- normalize(o_nca, norm_table, parameters = "cmax", suffix = ".wn")
  expect_true(any(res$result$PPTESTCD == "cmax.wn"))
  expect_equal(res$result$PPSTRES[res$result$PPTESTCD == "cmax.wn"],
               res$result$PPORRES[res$result$PPTESTCD == "cmax"] / 2)
})

test_that("normalize.data.frame errors for missing group", {
  df <- data.frame(ID = 1, PPTESTCD = "cmax", PPORRES = 10, PPORRESU = "ng/mL")
  norm_table <- data.frame(ID = 2, normalization = 2, unit = "kg")
  expect_error(normalize(df, norm_table, parameters = "cmax", suffix = ".wn"),
               "The normalization table contains groups not present in the data")
})

test_that("normalize.data.frame errors for duplicate group", {
  df <- data.frame(ID = 1, PPTESTCD = "cmax", PPORRES = 10, PPORRESU = "ng/mL")
  norm_table <- data.frame(ID = c(1, 1), normalization = c(2, 3), unit = "kg")
  expect_error(normalize(df, norm_table, parameters = "cmax", suffix = ".wn"),
               "The normalization table contains duplicate groups")
})

test_that("normalize_by_column errors for wrong object type", {
  expect_error(normalize_by_column(1, "subject", 1, 1, "kg", "cmax", ".wn"),
               "The object must be a PKNCAresults object")
})

test_that("normalize_by_column errors for missing column", {
  o_nca2 <- o_nca
  o_nca2$data$conc$columns$subject <- NULL
  expect_error(normalize_by_column(o_nca2, "subject", 1, 1, "kg", "cmax", ".wn"),
               "Column subject not found")
})

test_that("normalize_by_column errors for mismatched lengths", {
  expect_error(normalize_by_column(o_nca, "subject", 1:2, 1, "kg", "cmax", ".wn"),
               "The length of subject values and normalization_values must be the same")
})

test_that("normalize_by_column errors for duplicate values", {
  expect_error(normalize_by_column(o_nca, "subject", c(1,1), c(1,2), "kg", "cmax", ".wn"),
               "The subject values must not contain duplicates")
})

test_that("normalize_weight, normalize_bmi, normalize_sa, normalize_mw call normalize_by_column", {
  expect_silent(normalize_weight(o_nca, 1, 2, "kg", "cmax"))
  expect_silent(normalize_bmi(o_nca, 1, 2, "kg/m^2", "cmax"))
  expect_silent(normalize_sa(o_nca, 1, 2, "m^2", "cmax"))
  expect_silent(normalize_mw(o_nca, "A", 2, "g/mol", "cmax"))
})
