test_that("every exported exclusion rule is registered, and only those", {
  rules <- pknca_exclude_rules()
  exported_rules <- sort(grep("^exclude_nca_", getNamespaceExports("PKNCA"), value = TRUE))
  expect_equal(rules$rule, exported_rules)
  expect_named(
    rules,
    c("rule", "description", "arguments", "callable_with_defaults", "options", "affected_parameters")
  )
  for (idx in seq_len(nrow(rules))) {
    current_rule <- rules$rule[idx]
    expect_match(rules$description[idx], "^Exclude based on \\S", info = current_rule)
    expect_equal(
      rules$arguments[[idx]]$argument,
      as.character(names(formals(getExportedValue("PKNCA", current_rule)))),
      info = current_rule
    )
    # Every option a rule uses is a real option
    expect_true(all(rules$options[[idx]] %in% names(PKNCA.options())), info = current_rule)
  }
  # Exactly these rules need an argument to be created
  expect_equal(
    rules$rule[!rules$callable_with_defaults],
    c("exclude_nca_by_param", "exclude_nca_count_conc_measured")
  )
})

test_that("pknca_exclude_rules gives arguments, defaults, and options", {
  rules <- pknca_exclude_rules()
  get_rule <- function(rule) rules[rules$rule == rule, ]

  span_ratio <- get_rule("exclude_nca_span.ratio")
  expect_equal(span_ratio$description, "Exclude based on the half-life span ratio")
  expect_equal(span_ratio$arguments[[1]], data.frame(argument = "min.span.ratio", default = NA_character_))
  expect_true(span_ratio$callable_with_defaults)
  # The threshold falls back to its option, as it does in use
  expect_equal(span_ratio$options[[1]], "min.span.ratio")
  expect_equal(span_ratio$affected_parameters[[1]], sort(get.parameter.deps("half.life")))

  pext <- get_rule("exclude_nca_max.aucinf.pext")
  expect_equal(pext$options[[1]], "max.aucinf.pext")
  expect_equal(
    pext$affected_parameters[[1]],
    sort(unique(c(get.parameter.deps("aucinf.obs"), get.parameter.deps("aucinf.pred"))))
  )

  # A default in the function is not an option
  adj_r_squared <- get_rule("exclude_nca_min.hl.adj.r.squared")
  expect_equal(adj_r_squared$arguments[[1]]$default, "0.9")
  expect_equal(adj_r_squared$options[[1]], character())

  # Rules that need an argument have no defaults to describe
  by_param <- get_rule("exclude_nca_by_param")
  expect_equal(by_param$arguments[[1]]$argument, c("parameter", "min_thr", "max_thr", "affected_parameters"))
  expect_equal(by_param$arguments[[1]]$default, c(NA, "NULL", "NULL", "parameter"))
  expect_false(by_param$callable_with_defaults)
  expect_null(by_param$options[[1]])
  expect_null(by_param$affected_parameters[[1]])
  count_conc <- get_rule("exclude_nca_count_conc_measured")
  expect_equal(
    count_conc$arguments[[1]]$default[2],
    'c("^aucall", "^aucinf", "^aucint", "^auciv", "^auclast", "^aumc", "^sparse_auc")'
  )
  expect_null(count_conc$affected_parameters[[1]])

  tmax_0 <- get_rule("exclude_nca_tmax_0")
  expect_equal(nrow(tmax_0$arguments[[1]]), 0)
})

test_that("the exclusion function describes itself", {
  # A threshold given by the user is not an option
  fun_given <- exclude_nca_span.ratio(min.span.ratio = 3)
  expect_equal(exclude_nca_options_used(fun_given), character())
  expect_equal(exclude_nca_affected_parameters(fun_given), sort(get.parameter.deps("half.life")))
  fun_by_param <- exclude_nca_by_param("cmax", max_thr = 10, affected_parameters = c("tmax", "cmax"))
  expect_equal(exclude_nca_affected_parameters(fun_by_param), c("cmax", "tmax"))
  fun_count <- exclude_nca_count_conc_measured(min_count = 3, exclude_param_pattern = "^auclast$")
  expect_true("auclast" %in% exclude_nca_affected_parameters(fun_count))
  expect_false("aumclast" %in% exclude_nca_affected_parameters(fun_count))
})

test_that("pknca_register_exclude_rule checks what it registers", {
  expect_error(pknca_register_exclude_rule(name = "not_a_rule", description = "Exclude based on x"))
  expect_error(pknca_register_exclude_rule(name = "exclude_nca_x", description = "Removes x"))
})

# A PKNCAresults object with one row for every NCA parameter, used to confirm
# that each rule excludes exactly the parameters it says it can
exclude_rules_fixture <- function() {
  o_conc <- PKNCAconc(data.frame(conc = c(1, 2, 1), time = 0:2, subject = 1), conc ~ time | subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, cmax = TRUE))
  parameters <- setdiff(names(get.interval.cols()), c("start", "end"))
  result <-
    data.frame(
      subject = 1, start = 0, end = Inf,
      PPTESTCD = parameters, PPORRES = 0, exclude = NA_character_
    )
  PKNCAresults(result = result, data = o_data, exclude = "exclude")
}

# The parameters an exclusion function actually excludes on the fixture.  Every
# rule compares a parameter to a threshold, so an extremely low or an extremely
# high value of every parameter triggers it.
excluded_on_fixture <- function(rule_fun, fixture) {
  excluded <- character()
  for (current_value in c(-1e300, 1e300)) {
    current_fixture <- fixture
    current_fixture$result$PPORRES <- current_value
    current_excluded <- exclude(current_fixture, FUN = rule_fun)
    excluded <- c(excluded, current_excluded$result$PPTESTCD[!is.na(current_excluded$result$exclude)])
  }
  sort(unique(excluded))
}

test_that("each rule created with its defaults excludes exactly its listed parameters", {
  rules <- pknca_exclude_rules()
  fixture <- exclude_rules_fixture()
  for (idx in which(rules$callable_with_defaults)) {
    rule_fun <- getExportedValue("PKNCA", rules$rule[idx])()
    expect_equal(excluded_on_fixture(rule_fun, fixture), rules$affected_parameters[[idx]], info = rules$rule[idx])
  }
})

test_that("every rule's affected-parameter attribute is what it excludes", {
  # Rules that need arguments are created with them here, so that every
  # registered rule is checked
  arguments <-
    list(
      exclude_nca_by_param = list(parameter = "span.ratio", min_thr = 2, affected_parameters = c("span.ratio", "half.life")),
      exclude_nca_count_conc_measured = list(min_count = 3)
    )
  fixture <- exclude_rules_fixture()
  registered <- names(get("exclude_rules", envir = .PKNCAEnv))
  expect_true(all(names(arguments) %in% registered))
  for (rule in registered) {
    rule_args <- if (is.null(arguments[[rule]])) list() else arguments[[rule]]
    rule_fun <- do.call(getExportedValue("PKNCA", rule), rule_args)
    expect_equal(
      excluded_on_fixture(rule_fun, fixture),
      exclude_nca_affected_parameters(rule_fun),
      info = rule
    )
  }
})

# The registered description and the "Exclude based on ..." documentation are
# the same text.  The Rd is read from the installed help, which load_all()
# does not provide.
rd_text <- function(x) {
  raw <-
    if (identical(attr(x, "Rd_tag"), "COMMENT")) {
      ""
    } else if (is.list(x)) {
      paste(vapply(X = x, FUN = rd_text, FUN.VALUE = ""), collapse = "")
    } else {
      paste(x, collapse = "")
    }
  trimws(gsub(pattern = "\\s+", replacement = " ", x = raw))
}

rd_tagged <- function(x, tag) {
  x[vapply(X = x, FUN = function(el) identical(attr(el, "Rd_tag"), tag), FUN.VALUE = TRUE)]
}

rd_function_descriptions <- function(page) {
  ret <- character()
  for (section in rd_tagged(page, "\\section")) {
    if (identical(rd_text(section[[1]]), "Functions")) {
      for (itemize in rd_tagged(section[[2]], "\\itemize")) {
        is_item <- vapply(X = itemize, FUN = function(el) identical(attr(el, "Rd_tag"), "\\item"), FUN.VALUE = TRUE)
        item_id <- cumsum(is_item)
        for (current_id in unique(item_id[item_id > 0])) {
          item_text <- rd_text(itemize[item_id == current_id & !is_item])
          ret[sub("\\(\\):.*$", "", item_text)] <- sub("^[^:]*:\\s*", "", item_text)
        }
      }
    }
  }
  ret
}

test_that("registered descriptions match the documentation", {
  skip_if(
    dir.exists(file.path(getNamespaceInfo("PKNCA", "path"), "man")),
    "The installed help is needed (run under R CMD check, not devtools::load_all())"
  )
  rd <- tools::Rd_db(package = "PKNCA", lib.loc = dirname(getNamespaceInfo("PKNCA", "path")))
  documented <-
    c(
      rd_function_descriptions(rd[["exclude_nca.Rd"]]),
      exclude_nca_by_param = rd_text(rd_tagged(rd[["exclude_nca_by_param.Rd"]], "\\title"))
    )
  rules <- pknca_exclude_rules()
  # The installed Rd keeps words but not always the spaces at line breaks, so
  # the comparison ignores white space.
  squish <- function(x) gsub(pattern = "\\s+", replacement = "", x = x)
  expect_equal(
    squish(documented[rules$rule]),
    stats::setNames(squish(rules$description), rules$rule)
  )
})
