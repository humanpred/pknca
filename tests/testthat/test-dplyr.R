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
  expect_equal(filtered, filtered_manual)

  filtered <- filter(myconc, ID == 1)
  filtered_manual <- myconc
  filtered_manual$data <- myconc$data[myconc$data$ID == 1, ]
  expect_equal(filtered, filtered_manual)
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

# Two study parts with two subjects each; subject ids are unique across parts.
make_part_results <- function(dose_groups = c("part", "ID"), intervals_part = TRUE) {
  d_conc <- generate.conc(4, 1, 0:24)
  d_conc$part <- ifelse(d_conc$ID <= 2, "SAD", "MAD")
  d_dose <- generate.dose(d_conc)
  d_dose$part <- ifelse(d_dose$ID <= 2, "SAD", "MAD")
  if (!("part" %in% dose_groups)) {
    d_dose$part <- NULL
  }
  intervals <- data.frame(
    part = rep(c("SAD", "MAD"), each = 2),
    ID = 1:4,
    start = 0,
    end = 24,
    cmax = TRUE,
    auclast = TRUE
  )
  if (!intervals_part) {
    intervals$part <- NULL
  }
  my_conc <- PKNCAconc(d_conc, conc~time|part+ID)
  my_dose <- PKNCAdose(
    d_dose,
    stats::as.formula(sprintf("dose~time|%s", paste(dose_groups, collapse = "+")))
  )
  pk.nca(PKNCAdata(my_conc, my_dose, intervals = intervals))
}

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

test_that("dplyr filter that references no column changes nothing", {
  myresult <- make_part_results()
  expect_equal(filter(myresult, TRUE), myresult)
  # Position-based filters do not name a column and are not applied to the data
  filtered <- filter(myresult, dplyr::row_number() <= 2)
  expect_equal(nrow(filtered$result), 2)
  expect_equal(filtered$data, myresult$data)
})

test_that("dplyr filter leaves data slots without the referenced column whole", {
  # Dose data not grouped by part
  myresult <- make_part_results(dose_groups = "ID")
  filtered <- filter(myresult, part == "SAD")
  expect_equal(unique(filtered$result$part), "SAD")
  expect_equal(unique(filtered$data$conc$data$part), "SAD")
  expect_equal(nrow(filtered$data$conc$data), 50)
  expect_equal(filtered$data$dose, myresult$data$dose)
  expect_equal(nrow(filtered$data$dose$data), 4)
  expect_equal(unique(filtered$data$intervals$part), "SAD")

  # Intervals without the part column
  myresult <- make_part_results(intervals_part = FALSE)
  filtered <- filter(myresult, part == "SAD")
  expect_equal(unique(filtered$data$conc$data$part), "SAD")
  expect_equal(unique(filtered$data$dose$data$part), "SAD")
  expect_equal(filtered$data$intervals, myresult$data$intervals)
  expect_equal(nrow(filtered$data$intervals), 4)

  # One missing column is enough to leave the dose data whole
  myresult <- make_part_results(dose_groups = "ID")
  filtered <- filter(myresult, part == "SAD", ID == 1)
  expect_equal(nrow(filtered$data$dose$data), 4)
  expect_equal(unique(filtered$data$conc$data$ID), 1L)
  expect_equal(unique(filtered$data$intervals$ID), 1L)
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
