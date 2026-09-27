# The registry reads descriptions from the Rd documentation:  the source man/
# directory under devtools::load_all() and the installed help under R CMD check.
# Both are exercised; the Rd must be current (run devtools::document()).

test_that("every exported exclusion rule is in the registry with documentation", {
  rules <- pknca_exclude_rules()
  exported_rules <- sort(grep("^exclude_nca_", getNamespaceExports("PKNCA"), value = TRUE))
  expect_equal(rules$rule, exported_rules)
  expect_named(
    rules,
    c("rule", "description", "arguments", "callable_with_defaults", "affected_parameters")
  )
  for (idx in seq_len(nrow(rules))) {
    current_rule <- rules$rule[idx]
    # One description phrasing for every rule
    expect_match(rules$description[idx], "^Exclude based on \\S", info = current_rule)
    current_args <- rules$arguments[[idx]]
    expect_equal(current_args$argument, as.character(names(formals(getExportedValue("PKNCA", current_rule)))), info = current_rule)
    # Every argument is documented
    expect_false(anyNA(current_args$description), info = current_rule)
    expect_true(all(nzchar(current_args$description)), info = current_rule)
  }
})

test_that("pknca_exclude_rules reads arguments, defaults, and option fallbacks", {
  rules <- pknca_exclude_rules()
  get_rule <- function(rule) rules[rules$rule == rule, ]

  span_ratio <- get_rule("exclude_nca_span.ratio")
  expect_equal(span_ratio$description, "Exclude based on the half-life span ratio")
  expect_equal(
    span_ratio$arguments[[1]],
    data.frame(
      argument = "min.span.ratio",
      default = NA_character_,
      option = "min.span.ratio",
      description = 'The minimum acceptable span ratio (uses PKNCA.options("min.span.ratio") if not provided).'
    )
  )
  expect_true(span_ratio$callable_with_defaults)
  expect_equal(span_ratio$affected_parameters[[1]], sort(get.parameter.deps("half.life")))

  adj_r_squared <- get_rule("exclude_nca_min.hl.adj.r.squared")
  expect_equal(adj_r_squared$arguments[[1]]$default, "0.9")
  expect_equal(adj_r_squared$arguments[[1]]$option, NA_character_)

  pext <- get_rule("exclude_nca_max.aucinf.pext")
  expect_equal(pext$arguments[[1]]$option, "max.aucinf.pext")
  expect_equal(
    pext$affected_parameters[[1]],
    sort(unique(c(get.parameter.deps("aucinf.obs"), get.parameter.deps("aucinf.pred"))))
  )

  # A rule with a required argument cannot be called to find its parameters
  by_param <- get_rule("exclude_nca_by_param")
  expect_equal(by_param$description, "Exclude based on NCA parameter thresholds")
  expect_equal(by_param$arguments[[1]]$argument, c("parameter", "min_thr", "max_thr", "affected_parameters"))
  expect_equal(by_param$arguments[[1]]$default, c(NA, "NULL", "NULL", "parameter"))
  expect_false(by_param$callable_with_defaults)
  expect_null(by_param$affected_parameters[[1]])

  count_conc <- get_rule("exclude_nca_count_conc_measured")
  expect_equal(
    count_conc$arguments[[1]]$default[2],
    'c("^aucall", "^aucinf", "^aucint", "^auciv", "^auclast", "^aumc", "^sparse_auc")'
  )
  expect_false(count_conc$callable_with_defaults)

  # A rule without arguments has a zero-row argument table
  tmax_0 <- get_rule("exclude_nca_tmax_0")
  expect_equal(nrow(tmax_0$arguments[[1]]), 0)
  expect_equal(
    tmax_0$affected_parameters[[1]],
    sort(setdiff(names(get.interval.cols()), c("start", "end")))
  )
})

test_that("pknca_find_option_fallbacks finds both option-reading functions", {
  expect_equal(
    pknca_find_option_fallbacks(quote({
      if (missing(a)) a <- PKNCA.options("opt_a")
      b = PKNCA::PKNCA.choose.option(name = "opt_b", value = NULL)
      x[, 1] <- 2
      d <- PKNCA.options(name_variable)
      e <- other_fun("opt_e")
    })),
    c(a = "opt_a", b = "opt_b")
  )
  expect_equal(pknca_find_option_fallbacks(quote(x)), character())
})

test_that("pknca_option_call_name handles calls without an option name", {
  expect_equal(pknca_option_call_name(quote(PKNCA.options())), NA_character_)
  expect_equal(pknca_option_call_name(quote(PKNCA.options(check = TRUE))), NA_character_)
  expect_equal(pknca_option_call_name(quote(PKNCA.options(check = TRUE, "a"))), "a")
  expect_equal(pknca_option_call_name(quote(f("a"))), NA_character_)
  expect_equal(pknca_option_call_name(quote(obj$f("a"))), NA_character_)
})

test_that("Rd helpers read descriptions and fail loudly for undocumented functions", {
  rd <- pknca_rd_db()
  expect_error(
    pknca_rd_page(rd, alias = "exclude_nca_not_a_rule"),
    class = "pknca_error_rd_alias_missing"
  )
  page <- pknca_rd_page(rd, alias = "PKNCAconc")
  # Arguments documented together share their description
  args <- pknca_rd_arguments(page)
  expect_equal(args[["exclude_half.life"]], args[["include_half.life"]])
  # A function with its own page is described by the title
  expect_equal(pknca_rd_function_description(page, name = "PKNCAconc"), "Create a PKNCAconc object")
})
