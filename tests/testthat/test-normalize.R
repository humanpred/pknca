test_that("normalize.data.frame works for basic normalization", {
  df <- data.frame(ID = 1:2, PPTESTCD = "cmax", PPORRES = c(10, 20), PPORRESU = "ng/mL")
  norm_table <- data.frame(ID = 1:2, normalization = c(2, 4), unit = "kg")
  res <- normalize(df, norm_table, parameters = "cmax", suffix = ".wn")
  expect_equal(res$PPORRES, c(5, 5))
  expect_equal(res$PPORRESU, c("ng/mL/kg", "ng/mL/kg"))
  expect_equal(res$PPTESTCD, c("cmax.wn", "cmax.wn"))
})


# Create a basic PKNCAresults object for use in tests
d_conc <- data.frame(ID = c(1, 1, 2, 2), analyte = c("A", "B"), time = 0:1, conc = c(10, 20, 30, 40))
o_conc <- PKNCAconc(d_conc, conc ~ time | ID / analyte, concu = "ng/mL", concu_pref = "g/mL")
d_dose <- data.frame(ID = c(1, 2), dose = c(100, 200), time = 0, doseu = "mg")
o_dose <- PKNCAdose(d_dose, dose ~ time | ID)
o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(cmax = TRUE, start = 0, end = 1))
o_nca <- pk.nca(o_data)

test_that("normalize.PKNCAresults appends normalized parameters", {
  norm_table <- data.frame(ID = 1:2, normalization = 2, unit = "kg")
  res <- normalize(o_nca, norm_table, parameters = "cmax", suffix = ".wn")
  expect_true(any(res$result$PPTESTCD == "cmax.wn"))
  expect_equal(
    res$result$PPORRES[res$result$PPTESTCD == "cmax.wn"],
    res$result$PPORRES[res$result$PPTESTCD == "cmax"] / 2
  )
  expect_equal(
    res$result$PPSTRES[res$result$PPTESTCD == "cmax.wn"],
    res$result$PPSTRES[res$result$PPTESTCD == "cmax"] / 2
  )
  expect_equal(
    res$result$PPSTRESU[res$result$PPTESTCD == "cmax.wn"],
    paste0(res$result$PPSTRESU[res$result$PPTESTCD == "cmax"], "/kg")
  )
})

test_that("normalize.data.frame errors for missing group", {
  o_nca2 <- o_nca %>% filter(ID == 1)
  norm_table <- data.frame(ID = 2, normalization = 2, unit = "kg")
  expect_error(
    normalize(o_nca2$result, norm_table, parameters = "cmax", suffix = ".wn"),
    "The normalization table contains groups not present in the data"
  )
})

test_that("normalize.data.frame errors for duplicate group", {
  df <- data.frame(ID = 1, PPTESTCD = "cmax", PPORRES = 10, PPORRESU = "ng/mL")
  norm_table <- data.frame(ID = c(1, 1), normalization = c(2, 3), unit = "kg")
  expect_error(
    normalize(o_nca$result, norm_table, parameters = "cmax", suffix = ".wn"),
    "The normalization table contains duplicate groups"
  )
})

# Create a basic PKNCAresults object for use in tests
d_conc <- data.frame(
  ID = c(1, 1, 2, 2),
  weight = c(2, 2, 4, 4),
  analyte = c("A", "B", "A", "B"),
  analyte_mw = c(200, 300, 200, 300),
  analyte_mw_unit = c("g/mol", "kg/mol", "g/mol", "kg/mol"),
  time = 0:1,
  conc = c(10, 20, 30, 40),
  weight = c(2, 2, 4, 4), weight_unit = c("kg", "kg", "kg", "kg")
)
o_conc <- PKNCAconc(d_conc, conc ~ time | ID / analyte, concu = "ng/mL", concu_pref = "g/mL")
d_dose <- data.frame(ID = c(1, 2), dose = c(100, 200), time = 0, doseu = "mg")
o_dose <- PKNCAdose(d_dose, dose ~ time | ID)
o_data <- PKNCAdata(o_conc, o_dose, intervals = data.frame(cmax = TRUE, start = 0, end = 1))
o_nca <- pk.nca(o_data)

test_that("normalize_by_col normalizes by a numeric column in PKNCAconc data", {
  # Use the highlighted d_conc/o_conc/o_nca objects
  # Normalize by the 'weight' column (numeric), unit = 'kg', parameter = 'cmax', suffix = '.wn'
  res <- normalize_by_col(o_nca, col = "weight", unit = "kg", parameters = "cmax", suffix = ".wn")
  # Check that normalization occurred as expected, and values were appended
  expect_equal(res$result$PPTESTCD,  rep(c("cmax", "cmax.wn"), each = 4))
  expect_equal(res$result$PPORRES, rep(c(10, 20, 30, 40, 10/2, 20/2, 30/4, 40/4), each = 1))
  expect_equal(res$result$PPORRESU, rep(c("ng/mL", "ng/mL/kg"), each = 4))
})

test_that("normalize_by_col normalizes by a unit column in PKNCAconc data", {
  # Use the highlighted d_conc/o_conc/o_nca objects
  # Normalize by the 'analyte_mw' column, unit = 'analyte_mw_unit', parameter = 'cmax', suffix = '.mwn'
  res <- normalize_by_col(o_nca, col = "analyte_mw", unit = "analyte_mw_unit", parameters = "cmax", suffix = ".mwn")
  expect_equal(res$result$PPTESTCD,  rep(c("cmax", "cmax.mwn"), each = 4))
  expect_equal(res$result$PPORRES, c(10, 20, 30, 40, 10/200, 20/300, 30/200, 40/300))
  expect_equal(res$result$PPORRESU, c(rep("ng/mL", 4), rep(c("ng/mL/g/mol", "ng/mL/kg/mol"), 2)))
})

test_that("normalize_by_col errors for missing normalization column in PKNCAconc data", {
  expect_error(
    normalize_by_col(o_nca, col = "not_a_column", unit = "kg", parameters = "cmax", suffix = ".wn"),
    "Column not_a_column not found"
  )
})

test_that("normalize_by_col errors for duplicate normalizations per PKNCAconc group", {
  # Duplicate group: all rows have same ID and weight
  d_conc_dup <- d_conc
  d_conc_dup$analyte <- "A"
  d_conc_dup$weight <- 1:4
  o_conc_dup <- PKNCAconc(d_conc_dup, conc ~ time | ID / analyte, concu = "ng/mL", concu_pref = "g/mL")
  d_dose_dup <- data.frame(ID = 1, dose = 100, time = 0, doseu = "mg")
  o_dose_dup <- PKNCAdose(d_dose_dup, dose ~ time | ID)
  o_data_dup <- PKNCAdata(o_conc_dup, o_dose_dup, intervals = data.frame(cmax = TRUE, start = 0, end = 1))
  o_nca_dup <- pk.nca(o_data_dup)
  expect_error(
    normalize_by_col(o_nca_dup, col = "weight", unit = "kg", parameters = "cmax", suffix = ".wn"),
    "There is at least one concentration group with multiple normalization values"
  )
})
