test_that("pknca_routes() without synonyms is unchanged", {
  expect_equal(
    pknca_routes(),
    c("extravascular", "iv_bolus", "iv_infusion", "iv_continuous_infusion")
  )
  expect_equal(pknca_routes(synonyms = FALSE), pknca_routes())
  expect_error(pknca_routes(synonyms = NA))
  expect_error(pknca_routes(synonyms = "yes"))
})

test_that("the synonym table is well formed", {
  tbl <- pknca_routes(synonyms = TRUE)
  expect_s3_class(tbl, "data.frame")
  expect_equal(names(tbl), c("synonym", "route", "dose_route"))
  expect_type(tbl$synonym, "character")
  expect_false(anyNA(tbl$synonym))
  expect_false(anyDuplicated(tbl$synonym) > 0)
  # Stored as the matcher normalizes its input
  expect_equal(tbl$synonym, gsub("[[:space:]]+", " ", trimws(tolower(tbl$synonym))))
  expect_false(anyNA(tbl$route))
  expect_true(all(tbl$route %in% c(pknca_routes(), "iv")))
  expect_false("iv" %in% pknca_routes())
  expect_false(anyNA(tbl$dose_route))
  expect_true(all(tbl$dose_route %in% c("extravascular", "intravascular")))
  # The canonical route decides the dose route when it is known
  expect_equal(
    tbl$dose_route,
    ifelse(tbl$route == "extravascular", "extravascular", "intravascular")
  )
  # Every canonical route has a spelling, including its own name
  for (r in pknca_routes()) {
    expect_true(r %in% tbl$synonym[tbl$route %in% r], info = r)
  }
  # Both PKNCAdose values are reachable, including the unresolved IV spellings
  expect_true(all(c("intravascular", "iv", "intravenous") %in% tbl$synonym[tbl$route == "iv"]))
  expect_equal(unique(tbl$dose_route[tbl$route == "iv"]), "intravascular")
})

test_that("every dose_route in the table is accepted by PKNCAdose", {
  tbl <- pknca_routes(synonyms = TRUE)
  for (dr in unique(tbl$dose_route)) {
    d <- data.frame(id = 1, time = 0, dose = 1, route = dr)
    expect_equal(
      as.data.frame(PKNCAdose(d, dose ~ time | id, route = "route"))$route,
      dr
    )
  }
})

test_that("pknca_match_route() resolves spellings and abbreviations", {
  expect_equal(
    pknca_match_route(c("po", "oral", "sc", "im", "inhaled", "topical", "extravascular")),
    data.frame(
      route = rep("extravascular", 7),
      dose_route = rep("extravascular", 7)
    )
  )
  expect_equal(
    pknca_match_route(c("iv", "intravenous", "intravascular")),
    data.frame(
      route = rep("iv", 3),
      dose_route = rep("intravascular", 3)
    )
  )
  expect_equal(
    pknca_match_route(c("intravenous bolus", "iv bolus", "iv_bolus", "intravenous drip", "iv infusion", "continuous infusion", "iv_continuous_infusion")),
    data.frame(
      route = c("iv_bolus", "iv_bolus", "iv_bolus", "iv_infusion", "iv_infusion", "iv_continuous_infusion", "iv_continuous_infusion"),
      dose_route = rep("intravascular", 7)
    )
  )
})

test_that("pknca_match_route() ignores case and white space", {
  expect_equal(
    pknca_match_route(c("ORAL", " Po ", "INTRAVENOUS   BOLUS", "Intravenous\tDrip")),
    data.frame(
      route = c("extravascular", "extravascular", "iv_bolus", "iv_infusion"),
      dose_route = c("extravascular", "extravascular", "intravascular", "intravascular")
    )
  )
  expect_equal(pknca_match_route(factor("SUBCUTANEOUS")), pknca_match_route("subcutaneous"))
})

test_that("pknca_match_route() gives NA for unknown, NA, and empty input", {
  expect_equal(
    pknca_match_route(c("unknown", NA, "", "oral")),
    data.frame(
      route = c(NA, NA, NA, "extravascular"),
      dose_route = c(NA, NA, NA, "extravascular")
    )
  )
  expect_equal(
    pknca_match_route(character()),
    data.frame(route = character(), dose_route = character())
  )
  expect_equal(nrow(pknca_match_route(NA_character_)), 1)
})

test_that("pknca_match_route() errors on non-character input", {
  expect_error(pknca_match_route(1), regexp = "character")
  expect_error(pknca_match_route(list("oral")), regexp = "character")
  expect_error(pknca_match_route(NULL), regexp = "character")
})

test_that("every spelling in the table matches itself, in any case", {
  tbl <- pknca_routes(synonyms = TRUE)
  expect_equal(
    pknca_match_route(toupper(tbl$synonym)),
    tbl[, c("route", "dose_route")],
    ignore_attr = TRUE
  )
})
