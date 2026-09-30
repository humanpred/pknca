test_that("every exported exclusion rule is registered, and only those", {
  rules <- pknca_exclude_rules()
  exported_rules <- sort(grep("^exclude_nca_", getNamespaceExports("PKNCA"), value = TRUE))
  expect_equal(rules$rule, exported_rules)
  expect_named(
    rules,
    c("rule", "description", "arguments", "callable_with_defaults", "affected_parameters")
  )
  for (idx in seq_len(nrow(rules))) {
    current_rule <- rules$rule[idx]
    expect_match(rules$description[idx], "^Exclude based on \\S", info = current_rule)
    expect_equal(
      rules$arguments[[idx]]$argument,
      as.character(names(formals(getExportedValue("PKNCA", current_rule)))),
      info = current_rule
    )
    # Every registered option is a real option and a real argument
    registered_options <- stats::na.omit(rules$arguments[[idx]]$option)
    expect_true(all(registered_options %in% names(PKNCA.options())), info = current_rule)
  }
})

test_that("pknca_exclude_rules gives arguments, defaults, and options", {
  rules <- pknca_exclude_rules()
  get_rule <- function(rule) rules[rules$rule == rule, ]

  span_ratio <- get_rule("exclude_nca_span.ratio")
  expect_equal(span_ratio$description, "Exclude based on the half-life span ratio")
  expect_equal(
    span_ratio$arguments[[1]],
    data.frame(argument = "min.span.ratio", default = NA_character_, option = "min.span.ratio")
  )
  expect_true(span_ratio$callable_with_defaults)
  expect_equal(span_ratio$affected_parameters[[1]], sort(get.parameter.deps("half.life")))

  adj_r_squared <- get_rule("exclude_nca_min.hl.adj.r.squared")
  expect_equal(adj_r_squared$arguments[[1]]$default, "0.9")
  expect_equal(adj_r_squared$arguments[[1]]$option, NA_character_)

  # A rule whose parameters depend on an argument without a default
  by_param <- get_rule("exclude_nca_by_param")
  expect_equal(by_param$arguments[[1]]$argument, c("parameter", "min_thr", "max_thr", "affected_parameters"))
  expect_equal(by_param$arguments[[1]]$default, c(NA, "NULL", "NULL", "parameter"))
  expect_false(by_param$callable_with_defaults)
  expect_null(by_param$affected_parameters[[1]])

  # The affected parameters use the factory's defaults, even when the rule
  # itself needs an argument
  count_conc <- get_rule("exclude_nca_count_conc_measured")
  expect_equal(
    count_conc$arguments[[1]]$default[2],
    'c("^aucall", "^aucinf", "^aucint", "^auciv", "^auclast", "^aumc", "^sparse_auc")'
  )
  expect_false(count_conc$callable_with_defaults)
  expect_true(all(c("auclast", "aucinf.obs", "aumclast") %in% count_conc$affected_parameters[[1]]))
  expect_false("cmax" %in% count_conc$affected_parameters[[1]])

  tmax_0 <- get_rule("exclude_nca_tmax_0")
  expect_equal(nrow(tmax_0$arguments[[1]]), 0)
})

test_that("pknca_register_exclude_rule checks what it registers", {
  expect_error(pknca_register_exclude_rule(name = "not_a_rule", description = "Exclude based on x"))
  expect_error(pknca_register_exclude_rule(name = "exclude_nca_x", description = "Removes x"))
  expect_error(
    pknca_register_exclude_rule(name = "exclude_nca_x", description = "Exclude based on x", affects = "cmax")
  )
})

# A PKNCAresults object with one row for every NCA parameter, used to confirm
# that each rule excludes exactly the parameters registered for it
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

test_that("each rule excludes exactly its registered parameters", {
  rules <- pknca_exclude_rules()
  fixture <- exclude_rules_fixture()
  for (idx in which(rules$callable_with_defaults)) {
    rule_fun <- getExportedValue("PKNCA", rules$rule[idx])()
    excluded <- character()
    # Every rule compares a parameter to a threshold, so an extremely low or an
    # extremely high value of every parameter triggers it.
    for (current_value in c(-1e300, 1e300)) {
      current_fixture <- fixture
      current_fixture$result$PPORRES <- current_value
      current_excluded <- exclude(current_fixture, FUN = rule_fun)
      excluded <- c(excluded, current_excluded$result$PPTESTCD[!is.na(current_excluded$result$exclude)])
    }
    expect_equal(sort(unique(excluded)), rules$affected_parameters[[idx]], info = rules$rule[idx])
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
  expect_equal(documented[rules$rule], stats::setNames(rules$description, rules$rule))
})
