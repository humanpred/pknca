# based on purrr:::capture_output
msg_grabber <- function(code) {
  messages <- character()
  handler <- function(m) {
    messages <<- c(messages, m$message)
    invokeRestart("muffleMessage")
  }
  withCallingHandlers(code, message = handler)
  messages
}

test_that("dplyr filter", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose)
  myresult <- pk.nca(mydata)

  filtered <- filter(myresult, PPTESTCD == "auclast")
  filtered_manual <- myresult
  filtered_manual$result <- filtered_manual$result[filtered_manual$result$PPTESTCD == "auclast", ]
  filtered_manual <- set_provenance_marker(filtered_manual, "filtered", myresult)
  expect_equal(filtered, filtered_manual)

  filtered <- filter(myconc, ID == 1)
  filtered_manual <- myconc
  filtered_manual$data <- myconc$data[myconc$data$ID == 1, ]
  expect_equal(filtered, filtered_manual)

  # .by is passed on to dplyr
  filtered <- filter(myconc, conc == max(conc), .by = ID)
  expect_equal(nrow(filtered$data), 2)
  expect_equal(sort(filtered$data$ID), 1:2)
})

test_that("dplyr left_join", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose)
  myresult <- pk.nca(mydata)

  joindf <- data.frame(ID=1, foo="bar")
  msg_join_id <- msg_grabber(left_join(data.frame(ID = 1), data.frame(ID = 1)))
  expect_message(
    joined <- left_join(myresult, joindf),
    msg_join_id,
    fixed = TRUE
  )
  joined_manual <- myresult
  expect_message(
    joined_manual$result <- dplyr::left_join(joined_manual$result, joindf),
    msg_join_id,
    fixed = TRUE
  )
  joined_manual <- set_provenance_marker(joined_manual, "left-joined", myresult)
  expect_equal(joined, joined_manual)

  expect_message(
    joined <- left_join(myconc, joindf),
    msg_join_id,
    fixed = TRUE
  )
  joined_manual <- myconc
  expect_message(
    joined_manual$data <- left_join(joined_manual$data, joindf),
    msg_join_id,
    fixed = TRUE
  )
  expect_equal(joined, joined_manual)
})

test_that("dplyr mutate", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose)
  myresult <- pk.nca(mydata)

  mutated <- mutate(myresult, foo="bar")
  mutated_manual <- myresult
  mutated_manual$result <- mutate(mutated_manual$result, foo="bar")
  mutated_manual <- set_provenance_marker(mutated_manual, "mutated", myresult)
  expect_equal(mutated, mutated_manual)

  mutated <- mutate(myconc, foo="bar")
  mutated_manual <- myconc
  mutated_manual$data <- mutate(mutated_manual$data, foo="bar")
  expect_equal(mutated, mutated_manual)
})

test_that("dplyr group_by and ungroup", {
  tmpconc <- generate.conc(2, 1, 0:24)
  tmpdose <- generate.dose(tmpconc)
  myconc <- PKNCAconc(tmpconc, formula=conc~time|treatment+ID)
  mydose <- PKNCAdose(tmpdose, formula=dose~time|treatment+ID)
  mydata <- PKNCAdata(myconc, mydose)
  myresult <- pk.nca(mydata)

  grouped <- group_by(myconc, treatment)
  expect_s3_class(grouped$data, "grouped_df")
  ungrouped <- ungroup(grouped)
  expect_false("grouped_df" %in% class(ungrouped$data))
  expect_s3_class(ungrouped$data, "data.frame")
})

test_that("dplyr filter on a group column filters the data slots of PKNCAresults", {
  myresult <- make_part_results()
  expect_equal(nrow(myresult$data$conc$data), 100)
  expect_equal(nrow(myresult$data$dose$data), 4)
  expect_equal(nrow(myresult$data$intervals), 4)

  filtered <- filter(myresult, part == "SAD")
  expect_s3_class(filtered, "PKNCAresults")
  expect_equal(unique(filtered$result$part), "SAD")
  expect_equal(unique(filtered$result$ID), 1:2)
  expect_equal(nrow(filtered$result), 2*2)
  expect_equal(unique(filtered$data$conc$data$part), "SAD")
  expect_equal(nrow(filtered$data$conc$data), 50)
  expect_equal(unique(filtered$data$dose$data$part), "SAD")
  expect_equal(nrow(filtered$data$dose$data), 2)
  expect_equal(unique(filtered$data$intervals$part), "SAD")
  expect_equal(nrow(filtered$data$intervals), 2)
  expect_s3_class(filtered$data$conc, "PKNCAconc")
  expect_s3_class(filtered$data$dose, "PKNCAdose")

  # Several group columns, and a variable from the calling environment
  wanted <- 3L
  filtered <- filter(myresult, part == "MAD", ID == wanted)
  expect_equal(unique(filtered$result$ID), 3L)
  expect_equal(unique(filtered$data$conc$data$ID), 3L)
  expect_equal(nrow(filtered$data$conc$data), 25)
  expect_equal(unique(filtered$data$dose$data$ID), 3L)
  expect_equal(unique(filtered$data$intervals$ID), 3L)
  expect_equal(nrow(filtered$data$intervals), 1)
})

test_that("dplyr filter on a result-only column leaves the data slots whole", {
  myresult <- make_part_results()
  filtered <- filter(myresult, PPTESTCD == "cmax")
  expect_equal(unique(filtered$result$PPTESTCD), "cmax")
  expect_equal(nrow(filtered$result), 4)
  expect_equal(filtered$data, myresult$data)

  # A mix of a group column and a result-only column is a result-only filter
  filtered <- filter(myresult, part == "SAD", PPTESTCD == "cmax")
  expect_equal(unique(filtered$result$part), "SAD")
  expect_equal(nrow(filtered$result), 2)
  expect_equal(filtered$data, myresult$data)
})

test_that("dplyr filter on start or end filters the result table only", {
  myresult <- make_part_results()
  myresult$result$end[myresult$result$ID > 2] <- 12
  filtered <- filter(myresult, end == 12)
  expect_equal(unique(filtered$result$ID), 3:4)
  expect_equal(filtered$data, myresult$data)
  filtered <- filter(myresult, part == "MAD", start == 0)
  expect_equal(unique(filtered$result$ID), 3:4)
  expect_equal(filtered$data, myresult$data)
})

test_that("dplyr filter that references no column changes nothing", {
  myresult <- make_part_results()
  expect_identical(filter(myresult, TRUE), myresult)
  expect_true(checkProvenance(filter(myresult, TRUE)))
  # Position-based filters do not name a column and are not applied to the data
  filtered <- filter(myresult, dplyr::row_number() <= 2)
  expect_equal(nrow(filtered$result), 2)
  expect_equal(filtered$data, myresult$data)
  expect_false(checkProvenance(filtered))
})

test_that("dplyr filter keeps the surviving groups in slots that share only some group columns", {
  # Dose data not grouped by part and without a part column: matched on ID
  myresult <- make_part_results(dose_groups = "ID")
  expect_false("part" %in% names(myresult$data$dose$data))
  filtered <- filter(myresult, part == "SAD")
  expect_equal(unique(filtered$result$part), "SAD")
  expect_equal(unique(filtered$data$conc$data$part), "SAD")
  expect_equal(nrow(filtered$data$conc$data), 50)
  expect_equal(filtered$data$dose$data$ID, 1:2)
  expect_equal(unique(filtered$data$intervals$part), "SAD")

  # Intervals without the part column: matched on ID
  myresult <- make_part_results(intervals_part = FALSE)
  filtered <- filter(myresult, part == "SAD")
  expect_equal(unique(filtered$data$conc$data$part), "SAD")
  expect_equal(unique(filtered$data$dose$data$part), "SAD")
  expect_equal(filtered$data$intervals$ID, 1:2)
  expect_false("part" %in% names(filtered$data$intervals))

  # Dose data and intervals that share only the ID group
  myresult <- make_part_results(dose_groups = "ID")
  filtered <- filter(myresult, part == "MAD", ID == 3)
  expect_equal(filtered$data$dose$data$ID, 3L)
  expect_equal(unique(filtered$data$conc$data$ID), 3L)
  expect_equal(filtered$data$intervals$ID, 3L)

  # Intervals with no group columns apply to every group and stay whole
  myresult <- make_part_results()
  myresult$data$intervals <- data.frame(start = 0, end = 24, cmax = TRUE)
  filtered <- filter(myresult, part == "SAD")
  expect_equal(filtered$data$intervals, myresult$data$intervals)
  expect_equal(unique(filtered$data$conc$data$part), "SAD")
})

test_that("dplyr filter evaluates an aggregating filter once, on the results", {
  myresult <- make_part_results()
  filtered <- filter(myresult, ID == max(ID))
  expect_equal(unique(filtered$result$ID), 4L)
  expect_equal(unique(filtered$data$conc$data$ID), 4L)
  expect_equal(nrow(filtered$data$conc$data), 25)
  expect_equal(filtered$data$dose$data$ID, 4L)
  expect_equal(filtered$data$intervals$ID, 4L)

  # The maximum is of the results, not of each table: with results already
  # limited to subjects 1 and 2 by an earlier filter the maximum is subject 2
  filtered <- filter(filter(myresult, part == "SAD"), ID == max(ID))
  expect_equal(unique(filtered$data$conc$data$ID), 2L)
  expect_equal(filtered$data$dose$data$ID, 2L)
  expect_equal(filtered$data$intervals$ID, 2L)
})

test_that("dplyr filter recognizes .data$col and the columns of .by", {
  myresult <- make_part_results()
  filtered <- filter(myresult, .data$part == "SAD")
  expect_equal(unique(filtered$data$conc$data$part), "SAD")
  expect_equal(filtered$data$dose$data$ID, 1:2)

  # .by columns count as referenced; the filter itself is evaluated per group
  filtered <- filter(myresult, ID == max(ID), .by = part)
  expect_equal(unique(filtered$result$ID), c(2L, 4L))
  expect_equal(sort(unique(filtered$data$conc$data$ID)), c(2L, 4L))
  expect_equal(sort(filtered$data$dose$data$ID), c(2L, 4L))
  expect_equal(sort(filtered$data$intervals$ID), c(2L, 4L))

  # A result-only column in .by makes the filter a result-only filter
  filtered <- filter(myresult, PPORRES == max(PPORRES), .by = PPTESTCD)
  expect_equal(filtered$data, myresult$data)
})

test_that("dplyr filter that chooses columns indirectly filters the results only, with a message", {
  myresult <- make_part_results()
  var <- "part"
  expect_message(
    filtered <- filter(myresult, .data[["part"]] == "SAD"),
    class = "pknca_message_filter_indirect_columns"
  )
  expect_equal(unique(filtered$result$part), "SAD")
  expect_equal(filtered$data, myresult$data)
  expect_message(
    filtered <- filter(myresult, .data[[var]] == "SAD"),
    class = "pknca_message_filter_indirect_columns"
  )
  expect_equal(filtered$data, myresult$data)
  expect_message(
    filtered <- filter(myresult, dplyr::if_any(dplyr::all_of(var), ~ .x == "SAD")),
    class = "pknca_message_filter_indirect_columns"
  )
  expect_equal(unique(filtered$result$part), "SAD")
  expect_equal(filtered$data, myresult$data)
  expect_message(
    filtered <- filter(myresult, dplyr::if_all(dplyr::starts_with("par"), ~ .x == "SAD")),
    class = "pknca_message_filter_indirect_columns"
  )
  expect_equal(filtered$data, myresult$data)
  expect_message(
    filtered <- filter(myresult, part == "SAD", .by = dplyr::all_of(var)),
    class = "pknca_message_filter_indirect_columns"
  )
  expect_equal(filtered$data, myresult$data)
  # Named columns give no message
  expect_no_message(filter(myresult, part == "SAD"))
})

test_that("dplyr filter that removes every row leaves consistent empty data", {
  myresult <- make_part_results()
  filtered <- filter(myresult, part == "none")
  expect_equal(nrow(filtered$result), 0)
  expect_equal(nrow(filtered$data$conc$data), 0)
  expect_equal(nrow(filtered$data$dose$data), 0)
  expect_equal(nrow(filtered$data$intervals), 0)
  expect_equal(names(filtered$data$conc$data), names(myresult$data$conc$data))
  expect_equal(nrow(as.data.frame(filtered)), 0)
  expect_equal(nrow(summary(filtered)), 0)
})

test_that("dplyr filter works with a factor group column", {
  d_conc <- generate.conc(4, 1, 0:24)
  d_conc$part <- factor(ifelse(d_conc$ID <= 2, "SAD", "MAD"), levels = c("SAD", "MAD"))
  d_dose <- generate.dose(d_conc)
  d_dose$part <- factor(ifelse(d_dose$ID <= 2, "SAD", "MAD"), levels = c("MAD", "SAD"))
  # The intervals use character values and the dose data other factor levels
  intervals <- data.frame(
    part = rep(c("SAD", "MAD"), each = 2), ID = 1:4, start = 0, end = 24, cmax = TRUE
  )
  myresult <- pk.nca(
    PKNCAdata(
      PKNCAconc(d_conc, conc~time|part+ID),
      PKNCAdose(d_dose, dose~time|part+ID),
      intervals = intervals
    )
  )
  filtered <- filter(myresult, part == "SAD")
  expect_equal(unique(as.character(filtered$data$conc$data$part)), "SAD")
  expect_equal(nrow(filtered$data$conc$data), 50)
  expect_s3_class(filtered$data$conc$data$part, "factor")
  expect_equal(levels(filtered$data$dose$data$part), c("MAD", "SAD"))
  expect_equal(filtered$data$dose$data$ID, 1:2)
  expect_equal(filtered$data$intervals$ID, 1:2)
})

test_that("dplyr filter on sparse PKNCAresults filters data_sparse", {
  d_conc <- data.frame(
    part = rep(c("SAD", "MAD"), each = 18),
    id = rep(1:6, each = 6),
    time = rep(c(0, 1, 2, 4, 8, 24), 6),
    conc = rep(c(0, 5, 4, 3, 2, 1), 6) + rep(1:6, each = 6) / 10
  )
  d_intervals <- data.frame(
    part = c("SAD", "MAD"), start = 0, end = 24, auclast = TRUE
  )
  suppressMessages(suppressWarnings(
    myresult <- pk.nca(
      PKNCAdata(PKNCAconc(d_conc, conc~time|part+id, sparse = TRUE), intervals = d_intervals)
    )
  ))
  expect_false("id" %in% names(myresult$result))
  filtered <- filter(myresult, part == "SAD")
  expect_equal(unique(filtered$result$part), "SAD")
  expect_equal(unique(filtered$data$conc$data_sparse$part), "SAD")
  expect_equal(nrow(filtered$data$conc$data_sparse), 18)
  expect_equal(filtered$data$intervals$part, "SAD")
})

test_that("dplyr filter on PKNCAresults without dose data filters conc and intervals", {
  d_conc <- generate.conc(4, 1, 0:24)
  d_conc$part <- ifelse(d_conc$ID <= 2, "SAD", "MAD")
  intervals <- data.frame(
    part = rep(c("SAD", "MAD"), each = 2), ID = 1:4, start = 0, end = 24, cmax = TRUE
  )
  myresult <- pk.nca(PKNCAdata(PKNCAconc(d_conc, conc~time|part+ID), intervals = intervals))
  expect_identical(myresult$data$dose, NA)
  filtered <- filter(myresult, part == "SAD")
  expect_identical(filtered$data$dose, NA)
  expect_equal(unique(filtered$data$conc$data$part), "SAD")
  expect_equal(nrow(filtered$data$conc$data), 50)
  expect_equal(nrow(filtered$data$intervals), 2)
})
