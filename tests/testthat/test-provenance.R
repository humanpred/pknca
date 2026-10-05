test_that("provenance", {
  a <- addProvenance("a")
  # It may take a bit of time between setting the value in addProvenance
  # and checking
  expect_true(as.numeric(difftime(Sys.time(), attr(a, "provenance", exact=TRUE)$datetime, units="secs")) < 1,
              info="A correct time is set in provenance")
  expect_equal(attr(a, "provenance", exact=TRUE)$sysInfo, Sys.info(),
               info="Correct system information is set in provenance")
  expect_equal(attr(a, "provenance", exact=TRUE)$sessionInfo, sessionInfo(),
               info="Correct session information is set in provenance")
  expect_error(addProvenance(a),
               regexp="object already has provenance and the option to replace it was not selected.",
               info="Adding provenance to an object that already has provenance is an error")
  expect_true(
    {
      # Sleep so that there is a difference and it confirms replacement
      Sys.sleep(2)
      as.numeric(difftime(Sys.time(),
                          attr(addProvenance(a, replace=TRUE), "provenance", exact=TRUE)$datetime, units="secs")) < 1
    },
    info="A correct time is reset in provenance")
  
  expect_true(checkProvenance(a),
              info="Provenance checking works to find correct provenance")
  b <- "b"
  expect_true(is.na(checkProvenance(b)),
              info="Provenance checking works to find missing provenance")
  attr(b, "provenance") <- attr(a, "provenance")
  expect_false(checkProvenance(b),
               info="Provenance checking works to find incorrect provenance")
  
  # Test printing with a fake provenance object
  fakeprov <- list(hash="a",
                   datetime="b",
                   sessionInfo=list(R.version=c(version.string="c")))
  expect_output(print.provenance(fakeprov),
                regexp="Provenance hash a generated on b with c.",
                info="Provenance prints correctly")
  expect_output(
    expect_equal(
      print.provenance(fakeprov),
      invisible("Provenance hash a generated on b with c."),
      info="Provenance printing returns an invisible string with the information in it."
    )
  )
})

# Operations that change a PKNCAresults object after the run; each must mark
# the provenance with its own verb.
modifying_results_operations <- list(
  filter = list(
    verb = "filtered",
    run = function(x) filter(x, part == "SAD")
  ),
  mutate = list(
    verb = "mutated",
    run = function(x) mutate(x, foo = "bar")
  ),
  group_by = list(
    verb = "grouped",
    run = function(x) group_by(x, part)
  ),
  ungroup = list(
    verb = "ungrouped from grouped",
    run = function(x) ungroup(group_by(x, part))
  ),
  inner_join = list(
    verb = "inner-joined",
    run = function(x) suppressMessages(inner_join(x, data.frame(part = "SAD", foo = "bar")))
  ),
  left_join = list(
    verb = "left-joined",
    run = function(x) suppressMessages(left_join(x, data.frame(part = "SAD", foo = "bar")))
  ),
  right_join = list(
    verb = "right-joined",
    run = function(x) suppressMessages(right_join(x, data.frame(part = "SAD", foo = "bar")))
  ),
  full_join = list(
    verb = "full-joined",
    run = function(x) suppressMessages(full_join(x, data.frame(part = "SAD", foo = "bar")))
  ),
  exclude = list(
    verb = "excluded",
    run = function(x) exclude(x, reason = "test", mask = x$result$part == "SAD")
  ),
  normalize = list(
    verb = "normalized",
    run = function(x) {
      norm_table <- data.frame(part = c("SAD", "MAD"), normalization = 2, unit = "kg")
      normalize(x, norm_table, parameters = "cmax", suffix = ".wn")
    }
  )
)

test_that("every operation that modifies a PKNCAresults marks its provenance", {
  myresult <- make_part_results()
  expect_true(checkProvenance(myresult))
  original_hash <- attr(myresult, "provenance", exact = TRUE)$hash
  for (nm in names(modifying_results_operations)) {
    op <- modifying_results_operations[[nm]]
    modified <- op$run(myresult)
    expect_s3_class(modified, "PKNCAresults")
    expect_false(checkProvenance(modified), info = nm)
    expect_equal(
      attr(modified, "provenance", exact = TRUE)$hash,
      paste(op$verb, "from", original_hash),
      info = nm
    )
    expect_s3_class(attr(modified, "provenance", exact = TRUE), "provenance")
    # The input is not changed
    expect_true(checkProvenance(myresult), info = nm)
  }
})

test_that("successive modifications of a PKNCAresults nest their provenance markers", {
  myresult <- make_part_results()
  original_hash <- attr(myresult, "provenance", exact = TRUE)$hash
  modified <- mutate(filter(myresult, part == "SAD"), foo = "bar")
  expect_equal(
    attr(modified, "provenance", exact = TRUE)$hash,
    paste("mutated from filtered from", original_hash)
  )
  expect_false(checkProvenance(modified))
  expect_output(print(attr(modified, "provenance", exact = TRUE)), "Provenance hash mutated from filtered from")
})

test_that("an operation that leaves a PKNCAresults identical keeps its provenance", {
  myresult <- make_part_results()
  expect_true(checkProvenance(filter(myresult, TRUE)))
  expect_true(checkProvenance(exclude(myresult, reason = "none", mask = rep(FALSE, nrow(myresult$result)))))
})

test_that("modifying operations on objects without provenance leave them without provenance", {
  myresult <- make_part_results()
  conc <- myresult$data$conc
  expect_true(is.na(checkProvenance(conc)))
  expect_true(is.na(checkProvenance(filter(conc, part == "SAD"))))
  expect_true(is.na(checkProvenance(mutate(conc, foo = "bar"))))
  expect_true(is.na(checkProvenance(group_by(conc, part))))
})

test_that("every PKNCAresults method is classified as modifying or read-only", {
  # A new S3 method on PKNCAresults fails this test until it is classified, and
  # a modifying one must also be added to modifying_results_operations.
  modifying <- c(
    "filter", "mutate", "group_by", "ungroup", "inner_join", "left_join",
    "right_join", "full_join", "normalize", "update"
  )
  read_only <- c(
    "as.data.frame", "as_PKNCAconc", "as_PKNCAdata", "as_PKNCAdose",
    "as_PKNCAresults", "get_halflife_fit", "get_halflife_points",
    "getDataName", "getGroups", "group_vars", "is_sparse_pk", "summary"
  )
  # The methods that PKNCA registers for the class; methods that other
  # packages register are not ours, and the namespace table lists the generics
  # whether or not they are attached or exported.
  s3_methods <- getNamespaceInfo("PKNCA", "S3methods")
  generics <- s3_methods[s3_methods[, 2] == "PKNCAresults", 1]
  expect_equal(setdiff(generics, c(modifying, read_only)), character(0))
  # A stale entry in either list is caught
  expect_equal(setdiff(c(modifying, read_only), generics), character(0))
  # exclude() dispatches to its default method, so it is not in the method list
  # and is tested in modifying_results_operations only.  update() recalculates
  # and stamps a new provenance, so it is not a marking operation.
  expect_equal(
    setdiff(c(modifying, "exclude"), c("update", names(modifying_results_operations))),
    character(0)
  )
})
