test_that("setExcludeColumn", {
  # exclude argument not given
  expect_equal(
    setExcludeColumn(list(data=data.frame(a=1), columns = list(exclude="fake"))),
    list(data=data.frame(a=1), columns = list(exclude="fake")),
    info="setExcludeColumn does nothing if the exclude name is already given."
  )
  expect_equal(
    setExcludeColumn(list(data=data.frame(a=1))),
    list(data=data.frame(a=1, exclude=NA_character_),
         columns = list(exclude="exclude")),
    info="setExcludeColumn adds a column named exclude"
  )
  expect_equal(
    setExcludeColumn(list(data=data.frame(a=1, exclude=2))),
    list(data=data.frame(a=1, exclude=2, exclude.exclude=NA_character_),
         columns = list(exclude="exclude.exclude")),
    info="setExcludeColumn adds a column named exclude.exclude if 'exclude' is already present"
  )
  expect_equal(
    setExcludeColumn(list(results=data.frame(a=1)), dataname="results"),
    list(results=data.frame(a=1, exclude=NA_character_),
         columns = list(exclude="exclude")),
    info="setExcludeColumn works with an alternate dataname"
  )

  # exclude argument given
  expect_equal(
    setExcludeColumn(
      list(data=data.frame(a=1, exclude=2),
           columns = list(exclude="exclude")),
      exclude="exclude"
    ),
    list(
      data=data.frame(a=1, exclude=2),
      columns = list(exclude="exclude")
    ),
    info="setExcludeColumn does nothing if exclude is given and matching"
  )
  expect_error(setExcludeColumn(list(data=data.frame(a=1, exclude=2),
                                     columns = list(exclude="exclude")),
                                exclude="foo"),
               regexp="exclude is already set for the object.",
               info="setExcludeColumn gives an error if exclude is given and not matching")
  expect_error(setExcludeColumn(list(data=data.frame(a=1)),
                                exclude="exclude"),
               regexp="exclude, if given, must be a column name in the input data.",
               info="setExcludeColumn exclude column must be in the data.")
  expect_equal(
    setExcludeColumn(list(data=data.frame(a=1, exclude=factor("a"))),
                     exclude="exclude"),
    list(data=data.frame(a=1, exclude="a"),
         columns = list(exclude="exclude")),
    info="setExcludeColumn converts factor column to character"
  )
  expect_equal(
    setExcludeColumn(list(data=data.frame(a=1, exclude=NA)),
                     exclude="exclude"),
    list(data=data.frame(a=1, exclude=NA_character_),
         columns = list(exclude="exclude")),
    info="setExcludeColumn converts logical NA column to character"
  )
  expect_error(setExcludeColumn(list(data=data.frame(a=1, exclude=FALSE)),
                                exclude="exclude"),
               regexp="exclude column must be character vector or something convertable to character without loss of information.",
               info="setExcludeColumn gives error on logical non-NA value")
  expect_error(setExcludeColumn(list(data=data.frame(a=1, exclude=5)),
                                exclude="exclude"),
               regexp="exclude column must be character vector or something convertable to character without loss of information.",
               info="setExcludeColumn gives error on non-character value")

  # Zero-row data works
  expect_warning(
    expect_equal(
      setExcludeColumn(list(data=data.frame())),
      list(
        data=data.frame(exclude=NA_character_)[-1,,drop=FALSE],
        columns = list(exclude="exclude")
      )
    ),
    info="setExcludeColumn works with zero-row data"
  )
  expect_equal(
    setExcludeColumn(list(data=data.frame()), exclude="foo"),
    list(
      data=data.frame(foo=NA_character_)[-1,,drop=FALSE],
      columns = list(exclude="foo")
    ),
    info="setExcludeColumn works with zero-row data"
  )
})

test_that("exclude.default", {
  # Check inputs
  my_conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  obj1 <- PKNCAconc(my_conc, formula=conc~time|treatment+ID)

  expect_error(exclude.default(obj1,
                              reason="Just because"),
               regexp="Either mask or FUN must be given \\(but not both\\).",
               info="One of mask and FUN must be given")
  expect_error(exclude.default(obj1,
                              reason="Just because",
                              mask=rep(TRUE, 5),
                              FUN=function(x) rep(TRUE, nrow(x$data))),
               regexp="Either mask or FUN must be given \\(but not both\\).",
               info="Both mask and FUN may not be given")
  obj2 <- obj1
  obj2$columns$exclude <- NULL
  expect_error(exclude.default(obj2,
                              reason="Just because",
                              mask=rep(TRUE, 5)),
               regexp="object must have an exclude column specified.",
               info="exclude column is required.")
  obj3 <- obj1
  obj3$columns$exclude <- "foo"
  expect_error(exclude.default(obj3,
                              reason="Just because",
                              mask=rep(TRUE, 5)),
               regexp="exclude column must exist in object\\[\\['data'\\]\\].",
               info="exclude column must exist in the data")
  expect_error(exclude.default(obj1,
                              reason="Just because",
                              mask=TRUE),
               regexp="mask must match the length of the data.",
               info="mask may not be a scalar")
  expect_error(exclude.default(obj1,
                              reason="Just because",
                              mask=rep(TRUE, 6)),
               regexp="mask must match the length of the data.",
               info="mask must match the length of the data.")
  expect_error(exclude.default(obj1,
                              reason=1:2,
                              FUN=function(x, ...) TRUE),
               regexp="reason must be a scalar or have the same length as the data",
               info="Interpretation of a non-scalar reason is unclear")
  expect_error(exclude.default(obj1,
                               reason=1,
                               FUN=function(x, ...) TRUE),
               regexp="reason must be a character vector.",
               info="Interpretation of a non-character reason is unclear")
  # Check operation
  obj4 <- obj1
  obj4$data$exclude <- c(NA_character_, rep("Just because", nrow(obj4$data)-1))

  expect_equal(exclude.default(obj1,
                              reason="Just because",
                              mask=c(FALSE, rep(TRUE, nrow(obj1$data)-1))),
               obj4,
               info="Mask given as a vector works")

  obj5 <- obj1
  obj5$data$exclude <- ifelse(obj5$data$time == 0,
                              NA_character_, "Just because")
  expect_equal(exclude.default(obj1,
                              reason="Just because",
                              FUN=function(x, ...) c(FALSE, rep(TRUE, nrow(x)-1))),
               obj5,
               info="A function returning a vector works")

  obj7 <- obj1
  obj7$data <- obj7$data[rev(seq_len(nrow(obj7$data))),]
  exclude_1 <- function(x, ...) {
    ifelse(x$ID == 1,
           "Drop 1",
           NA_character_)
  }
  expect_equal(exclude.default(obj1,
                               FUN=exclude_1)$exclude,
               rev(
                 exclude.default(obj7,
                                 FUN=exclude_1)$exclude),
               info="Function application is order-invariant")

  expect_equal(exclude.default(obj1,
                               FUN=function(x, ...) c(NA_character_, rep("Just because", nrow(x)-1))),
               obj5,
               info="A function returning a character vector works")

  obj6 <- obj5
  obj6$data$exclude[1:2] <- c("really", "Just because; really")

  expect_equal(
    exclude.default(
      exclude.default(obj1,
                     reason="Just because",
                     FUN=function(x, ...) c(FALSE, rep(TRUE, nrow(x)-1))),
      reason="really",
      mask=c(TRUE, TRUE, rep(FALSE, nrow(obj1$data) - 2))),
    obj6,
    info="Multiple reasons are tracked.")

  # Check exclusion for PKNCAdose class
  my_dose <- generate.dose(my_conc)
  dose_obj <- PKNCAdose(my_dose, dose~time|treatment+ID)
  dose_obj_ex1 <- dose_obj
  dose_obj_ex1$data$exclude[dose_obj_ex1$data$ID == 1] <- "Not 1"
  expect_equal(exclude(dose_obj, reason="Not 1", FUN=function(x, ...) x$ID == 1),
               dose_obj_ex1,
               info="exclude works for PKNCAdose objects (with functions)")

  # Dose exclusion is respected
  data_obj <- PKNCAdata(obj1, dose_obj, intervals=data.frame(start=0, end=Inf, cl.last=TRUE))
  data_obj_ex1 <- PKNCAdata(obj1, dose_obj_ex1, intervals=data.frame(start=0, end=Inf, cl.last=TRUE))
  result_obj <- pk.nca(data_obj)
  result_obj_ex1 <- pk.nca(data_obj_ex1)

  expect_equal(result_obj_ex1$result$PPORRES[result_obj_ex1$result$ID == 1 &
                                               result_obj_ex1$result$PPTESTCD == "cl.last"],
               rep(NA_real_, 2),
               info="exclude of dose is respected")

  # Check exclusion for PKNCAresults class
  result_obj_not_1 <- result_obj
  result_obj_not_1$result$exclude[result_obj_not_1$result$ID == 1] <- "Not 1"
  result_obj_not_1 <- set_provenance_marker(result_obj_not_1, "excluded", result_obj)
  expect_equal(
    exclude(result_obj, reason="Not 1", FUN=function(x, ...) x$ID == 1),
    result_obj_not_1,
    info="exclude works for PKNCAresults object"
  )

  expect_false(any(summary(result_obj)$cl.last == summary(result_obj_not_1)$cl.last),
               info="summary.PKNCAresults respects exclude")
})

test_that("normalize_exclude makes blanks into NA_character_ (#55)", {
  my_conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  my_conc$exclude <- c("", rep(NA_character_, nrow(my_conc) - 1))
  obj1 <- PKNCAconc(my_conc,
                    formula=conc~time|treatment+ID,
                    exclude="exclude")
  expect_equal(normalize_exclude(obj1),
               rep(NA_character_, nrow(my_conc)),
               info="normalize_exclude makes blanks into NA_character_")
  obj2 <- obj1
  obj2$data$exclude[2] <- "foo"
  expect_equal(normalize_exclude(obj2),
               c(NA_character_, "foo", rep(NA_character_, nrow(my_conc)-2)),
               info="normalize_exclude makes blanks into NA_character_ and leaves non-blank alone.")
  expect_equal(normalize_exclude(1:5), 1:5,
               info="normalize_exclude works with bare vectors (as opposed to PKNCA objects)")
})

test_that("multiple exclusions for the same row provide all the reasons (fix #113)", {
  my_conc <- generate.conc(nsub=5, ntreat=2, time.points=0:24)
  my_conc$exclude <- c("", rep(NA_character_, nrow(my_conc) - 1))
  suppressMessages(
    result_obj <-
      pk.nca(PKNCAdata(
        PKNCAconc(
          my_conc,
          formula=conc~time|treatment+ID,
          exclude="exclude"
        ),
        intervals=data.frame(start=0, end=Inf, cmax=TRUE)
      ))
  )
  result_excl1 <-
    exclude(
      result_obj,
      reason="test1",
      mask=c(TRUE, TRUE, rep(FALSE, nrow(as.data.frame(result_obj)) - 2))
    )
  result_excl2 <-
    exclude(
      result_excl1,
      reason="test2",
      mask=c(TRUE, FALSE, TRUE, rep(FALSE, nrow(as.data.frame(result_obj)) - 3))
    )
  expect_equal(
    as.data.frame(result_excl2)$exclude,
    c("test1; test2", "test1", "test2", rep(NA_character_, 7))
  )
})

test_that("a condition signaled by an exclusion function reaches the caller with its class and fields", {
  my_conc <- generate.conc(nsub = 2, ntreat = 1, time.points = 0:4)
  obj <- PKNCAconc(my_conc, formula = conc ~ time | treatment + ID)
  warn_per_group <- function(x, ...) {
    rlang::warn(
      paste("Checked subject", x$ID[1]),
      class = "pknca_test_warning_exclude_fun",
      subject = x$ID[1]
    )
    rep(NA_character_, nrow(x))
  }
  acc <- new.env(parent = emptyenv())
  acc$caught <- list()
  withCallingHandlers(
    exclude(obj, FUN = warn_per_group),
    pknca_test_warning_exclude_fun = function(w) {
      acc$caught[[length(acc$caught) + 1]] <- w
      invokeRestart("muffleWarning")
    }
  )
  caught <- acc$caught
  expect_length(caught, 2)
  expect_s3_class(caught[[1]], "pknca_test_warning_exclude_fun")
  expect_equal(vapply(caught, `[[`, "subject", FUN.VALUE = 1L), 1:2)
  expect_equal(conditionMessage(caught[[2]]), "Checked subject 2")
})

test_that("an exclusion function must return one value or one value per row", {
  my_conc <- generate.conc(nsub = 2, ntreat = 1, time.points = 0:4)
  obj <- PKNCAconc(my_conc, formula = conc ~ time | treatment + ID)
  expect_error(
    exclude(obj, reason = "x", FUN = function(x, ...) c(TRUE, FALSE)),
    class = "pknca_error_exclude_fun_length"
  )
  expect_error(
    exclude(obj, reason = "x", FUN = function(x, ...) logical()),
    regexp = "it returned 0 values for a group of 5 rows",
    fixed = TRUE
  )
})

test_that("a missing group value is its own group for an exclusion function", {
  my_conc <- generate.conc(nsub = 3, ntreat = 1, time.points = 0:2)
  my_conc$ID[my_conc$ID == 3] <- NA
  obj <- suppressWarnings(PKNCAconc(my_conc, formula = conc ~ time | treatment + ID))
  group_size <- function(x, ...) rep(as.character(nrow(x)), nrow(x))
  expect_equal(
    exclude(obj, FUN = group_size)$data$exclude,
    rep("3", 9)
  )
  first_id <- function(x, ...) rep(paste("ID", x$ID[1]), nrow(x))
  expect_equal(
    exclude(obj, FUN = first_id)$data$exclude,
    rep(c("ID 1", "ID 2", "ID NA"), each = 3)
  )
})

# The exclusion text each group of a PKNCAresults object gets when every group
# (the groups of the results with start and end) is given to FUN on its own
exclude_by_group_oracle <- function(object, FUN) {
  data <- object$result
  groupnames <- unique(c(names(getGroups(object)), "start", "end"))
  key <- do.call(paste, c(lapply(data[groupnames], as.character), sep = "\r"))
  ret <- rep(NA_character_, nrow(data))
  for (current_key in unique(key)) {
    idx <- which(key == current_key)
    ret[idx] <- FUN(data[idx, , drop = FALSE], object)
  }
  ret
}

test_that("every exclusion rule gives the same result as applying it to each group on its own", {
  my_conc <- generate.conc(nsub = 3, ntreat = 2, time.points = c(0, 0.5, 1, 2, 4, 8, 12, 24))
  my_dose <- generate.dose(my_conc)
  o_data <-
    PKNCAdata(
      PKNCAconc(my_conc, conc ~ time | treatment + ID),
      PKNCAdose(my_dose, dose ~ time | treatment + ID),
      intervals =
        rbind(
          data.frame(start = 0, end = 24, cmax = TRUE, tmax = TRUE, auclast = TRUE, half.life = FALSE, aucinf.obs = FALSE),
          data.frame(start = 0, end = Inf, cmax = FALSE, tmax = FALSE, auclast = FALSE, half.life = TRUE, aucinf.obs = TRUE)
        )
    )
  o_nca <- suppressMessages(pk.nca(o_data))
  arguments <-
    list(
      exclude_nca_by_param = list(parameter = "cmax", max_thr = 0.9, affected_parameters = c("cmax", "tmax")),
      exclude_nca_count_conc_measured = list(min_count = 3),
      exclude_nca_span.ratio = list(min.span.ratio = 4),
      exclude_nca_tmax_early = list(tmax_early = 1.5)
    )
  any_excluded <- FALSE
  for (rule in names(get("exclude_rules", envir = .PKNCAEnv))) {
    rule_args <- if (is.null(arguments[[rule]])) list() else arguments[[rule]]
    rule_fun <- do.call(getExportedValue("PKNCA", rule), rule_args)
    expected <- suppressMessages(exclude_by_group_oracle(o_nca, rule_fun))
    actual <- suppressMessages(exclude(o_nca, FUN = rule_fun))$result$exclude
    expect_equal(actual, expected, info = rule)
    any_excluded <- any_excluded || any(!is.na(actual))
  }
  # The fixture triggers the rules, so the comparison is not only of NA values
  expect_true(any_excluded)
})
