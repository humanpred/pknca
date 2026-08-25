test_that("PKNCA_impute_method_start_conc0", {
  # Time 0 is replaced
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = 1:3, time = 0:2),
    data.frame(conc = c(0, 2:3), time = 0:2)
  )
  # Time 0 is added
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = 2:3, time = 1:2),
    data.frame(conc = c(0, 2:3), time = 0:2),
    ignore_attr = TRUE
  )
  # Time 0 is inserted
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = 1:3, time = c(-1, 1:2)),
    data.frame(conc = c(1, 0, 2:3), time = -1:2),
    ignore_attr = TRUE
  )
})

test_that("PKNCA_impute_method_start_conc0 with degenerate data (#361)", {
  # All concentrations missing: the start concentration is still set to 0 and
  # the missing values are left alone
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = rep(NA_real_, 3), time = 0:2),
    data.frame(conc = c(0, NA, NA), time = 0:2)
  )
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = rep(NA_real_, 3), time = 1:3),
    data.frame(conc = c(0, NA, NA, NA), time = 0:3),
    ignore_attr = TRUE
  )
  # All times missing: no time matches the start, so a start row is added and
  # the unknown times sort to the end
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = 1:3, time = rep(NA_real_, 3)),
    data.frame(conc = c(0, 1:3), time = c(0, NA, NA, NA)),
    ignore_attr = TRUE
  )
  # All concentrations zero: setting the start to 0 is a no-op
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = rep(0, 3), time = 0:2),
    data.frame(conc = rep(0, 3), time = 0:2)
  )
  # All concentrations zero without a start time: a zero row is still added
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = rep(0, 3), time = 1:3),
    data.frame(conc = rep(0, 4), time = 0:3),
    ignore_attr = TRUE
  )
})

test_that("start_conc0 intentionally replaces an existing start concentration with 0 (#578)", {
  # A nonzero concentration at the start time is forced to 0
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = c(5, 2, 3), time = 0:2),
    data.frame(conc = c(0, 2, 3), time = 0:2)
  )
  # The replacement also occurs at a nonzero start time
  expect_equal(
    PKNCA_impute_method_start_conc0(conc = 1:3, time = 0:2, start = 1),
    data.frame(conc = c(1, 0, 3), time = 0:2)
  )
})

test_that("start_predose,start_conc0 collapses to start_conc0 by design (#578)", {
  # A predose sample within max_shift (5% of the 0-24 interval, so within 1.2)
  d_conc <-
    data.frame(
      subject = 1,
      time = c(-0.5, 1, 2, 4, 8, 12, 24),
      conc = c(2, 5, 4, 3, 2.5, 2, 1)
    )
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  d_intervals <- data.frame(start = 0, end = 24, auclast = TRUE)
  get_auclast <- function(impute) {
    o_data <- suppressMessages(PKNCAdata(o_conc, intervals = d_intervals, impute = impute))
    d_res <- as.data.frame(suppressMessages(pk.nca(o_data)))
    d_res$PPORRES[d_res$PPTESTCD == "auclast"]
  }
  auclast_chain <- get_auclast("start_predose,start_conc0")
  auclast_conc0 <- get_auclast("start_conc0")
  auclast_predose <- get_auclast("start_predose")
  # start_conc0 replaces the concentration that start_predose shifted to the
  # start time, so the chain gives the same result as start_conc0 alone
  expect_equal(auclast_chain, auclast_conc0)
  expect_equal(
    auclast_chain,
    as.numeric(pk.calc.auc.last(
      conc = c(0, 5, 4, 3, 2.5, 2, 1),
      time = c(0, 1, 2, 4, 8, 12, 24)
    ))
  )
  # start_predose alone carries the predose concentration to the start time
  expect_equal(
    auclast_predose,
    as.numeric(pk.calc.auc.last(
      conc = c(2, 5, 4, 3, 2.5, 2, 1),
      time = c(0, 1, 2, 4, 8, 12, 24)
    ))
  )
  expect_true(auclast_predose != auclast_conc0)
})

test_that("PKNCA_impute_method_start_predose", {
  # No modification if no predose samples
  expect_equal(
    PKNCA_impute_method_start_predose(conc = 1:3, time = 1:3, conc.group = 1:3, time.group = 1:3, start = 0, end = 24),
    data.frame(conc = 1:3, time = 1:3)
  )
  # No modification if time 0 is already present
  expect_equal(
    PKNCA_impute_method_start_predose(conc = 1:3, time = 0:2, conc.group = 1:3, time.group = 0:2, start = 0, end = 24),
    data.frame(conc = 1:3, time = 0:2)
  )
  # Shift happens when time is within max_shift
  expect_equal(
    PKNCA_impute_method_start_predose(conc = 2:3, time = 1:2, conc.group = 1:3, time.group = c(-1, 1:2), start = 0, end = 24),
    data.frame(conc = 1:3, time = 0:2)
  )
  # Shift happens when time is equal to max_shift
  expect_equal(
    PKNCA_impute_method_start_predose(conc = 2:3, time = 1:2, conc.group = 1:3, time.group = c(-1.2, 1:2), start = 0, end = 24),
    data.frame(conc = 1:3, time = 0:2)
  )
  # Shift occurs to a new start
  expect_equal(
    PKNCA_impute_method_start_predose(conc = 2:3, time = 1:2, conc.group = 1:3, time.group = c(-0.3, 1:2), start = 0.5, end = 24),
    data.frame(conc = 1:3, time = c(0.5, 1:2))
  )
  # Shift does not when time is more than max_shift
  expect_equal(
    PKNCA_impute_method_start_predose(conc = 2:3, time = 1:2, conc.group = 1:3, time.group =c(-3, 1:2), start = 0, end = 24),
    data.frame(conc = 2:3, time = 1:2)
  )
  # max_shift overrides the start/end automation
  expect_equal(
    PKNCA_impute_method_start_predose(conc = 2:3, time = 1:2, conc.group = 1:3, time.group = c(-3, 1:2), max_shift = 3, start = 0, end = 24),
    data.frame(conc = 1:3, time = 0:2)
  )
  # shift automation works reasonably even when the end is infinite
  expect_equal(
    PKNCA_impute_method_start_predose(conc = 2:4, time = c(1:2, 24), conc.group = 1:4, time.group = c(-1.25, 1:2, 24), start = 0, end = Inf),
    data.frame(conc = 2:4, time = c(1:2, 24))
  )
  expect_equal(
    PKNCA_impute_method_start_predose(conc = 2:4, time = c(1:2, 24), conc.group = 1:4, time.group = c(-1.2, 1:2, 24), start = 0, end = Inf),
    data.frame(conc = 1:4, time = c(0:2, 24))
  )
})

test_that("PKNCA_impute_method_start_predose with degenerate data (#361)", {
  # All concentrations missing: a missing predose concentration is not shifted,
  # so no missing value is added at the start time
  expect_equal(
    PKNCA_impute_method_start_predose(
      conc = rep(NA_real_, 2), time = 1:2,
      conc.group = rep(NA_real_, 3), time.group = c(-1, 1:2),
      start = 0, end = 24
    ),
    data.frame(conc = rep(NA_real_, 2), time = 1:2)
  )
  # A missing concentration at the nearest predose time falls back to the most
  # recent measured predose sample (max_shift here is 0.05*24 = 1.2)
  expect_equal(
    PKNCA_impute_method_start_predose(
      conc = 3:4, time = 1:2,
      conc.group = c(5, NA, 3, 4), time.group = c(-1, -0.5, 1, 2),
      start = 0, end = 24
    ),
    data.frame(conc = c(5, 3, 4), time = 0:2)
  )
  # The fallback is still bound by max_shift: the measured sample at -2 is too
  # far back to shift, even though the nearer sample at -0.5 is missing
  expect_equal(
    PKNCA_impute_method_start_predose(
      conc = 3:4, time = 1:2,
      conc.group = c(5, NA, 3, 4), time.group = c(-2, -0.5, 1, 2),
      start = 0, end = 24
    ),
    data.frame(conc = 3:4, time = 1:2)
  )
  # max_shift is measured against the sample that is actually shifted, so
  # raising it lets the fallback through
  expect_equal(
    PKNCA_impute_method_start_predose(
      conc = 3:4, time = 1:2,
      conc.group = c(5, NA, 3, 4), time.group = c(-2, -0.5, 1, 2),
      start = 0, end = 24, max_shift = 2
    ),
    data.frame(conc = c(5, 3, 4), time = 0:2)
  )
  # With duplicate predose times, only the measured concentrations are shifted
  expect_equal(
    PKNCA_impute_method_start_predose(
      conc = 3:4, time = 1:2,
      conc.group = c(NA, 2, 3, 4), time.group = c(-1, -1, 1, 2),
      start = 0, end = 24
    ),
    data.frame(conc = c(2, 3, 4), time = 0:2)
  )
  # All times missing: nothing is known to be predose, so the data are
  # unchanged (previously this stopped with "missing value where TRUE/FALSE
  # needed")
  expect_equal(
    PKNCA_impute_method_start_predose(
      conc = 1:2, time = rep(NA_real_, 2),
      conc.group = 1:3, time.group = rep(NA_real_, 3),
      start = 0, end = 24
    ),
    data.frame(conc = 1:2, time = rep(NA_real_, 2))
  )
  # The same holds when max_shift must be derived from the times
  expect_equal(
    PKNCA_impute_method_start_predose(
      conc = 1:2, time = rep(NA_real_, 2),
      conc.group = 1:3, time.group = rep(NA_real_, 3),
      start = 0, end = Inf
    ),
    data.frame(conc = 1:2, time = rep(NA_real_, 2))
  )
  # A missing time alongside a usable predose sample is neither selected as the
  # predose sample nor carried along with the one that is
  expect_equal(
    PKNCA_impute_method_start_predose(
      conc = 3:4, time = 1:2,
      conc.group = c(5, 2, 3, 4), time.group = c(NA, -1, 1, 2),
      start = 0, end = 24
    ),
    data.frame(conc = c(2, 3, 4), time = 0:2)
  )
  # All concentrations zero: the zero predose value is shifted
  expect_equal(
    PKNCA_impute_method_start_predose(
      conc = c(0, 0), time = 1:2,
      conc.group = rep(0, 3), time.group = c(-1, 1:2),
      start = 0, end = 24
    ),
    data.frame(conc = rep(0, 3), time = 0:2)
  )
})

test_that("start_predose does not fabricate a start concentration from a missing predose sample (#361)", {
  # With conc.na = 0 a shifted missing predose value becomes a measured zero at
  # the start time.  auclast was then reported as 51.17835 from a measurement
  # that was never made; it must instead be missing because the interval starts
  # before the first real measurement.
  d_conc <-
    data.frame(
      subject = 1,
      time = c(-0.5, 1, 2, 4, 8, 12, 24),
      conc = c(NA, 5, 4, 3, 2.5, 2, 1)
    )
  o_conc <- PKNCAconc(d_conc, conc~time|subject)
  o_data <-
    suppressMessages(PKNCAdata(
      o_conc,
      intervals = data.frame(start = 0, end = 24, auclast = TRUE),
      impute = "start_predose",
      options = list(conc.na = 0)
    ))
  expect_warning(
    d_res <- as.data.frame(pk.nca(o_data)),
    regexp = "Requesting an AUC range starting .0. before the first measurement .1. is not allowed"
  )
  expect_equal(d_res$PPORRES[d_res$PPTESTCD == "auclast"], NA_real_)
})

test_that("PKNCA_impute_method_start_cmin", {
  # No imputation when start is in the data
  expect_equal(
    PKNCA_impute_method_start_cmin(conc = 1:3, time = 0:2, start = 0, end = 24),
    data.frame(conc = 1:3, time = 0:2)
  )
  # impute when start is not in the data
  expect_equal(
    PKNCA_impute_method_start_cmin(conc = 1:3, time = 1:3, start = 0, end = 24),
    data.frame(conc = c(1, 1:3), time = 0:3),
    ignore_attr = TRUE
  )
  # data outside the interval are ignored (before interval)
  expect_equal(
    PKNCA_impute_method_start_cmin(conc = 1:3, time = 1:3, start = 1.5, end = 24),
    data.frame(conc = c(1, 2, 2:3), time = c(1, 1.5, 2:3)),
    ignore_attr = TRUE
  )
  # data outside the interval are ignored (after interval)
  expect_equal(
    PKNCA_impute_method_start_cmin(conc = c(1:3, 0.5), time = c(1:3, 25), start = 1.5, end = 24),
    data.frame(conc = c(1, 2, 2:3, 0.5), time = c(1, 1.5, 2:3, 25)),
    ignore_attr = TRUE
  )

})

test_that("PKNCA_impute_method_start_cmin with degenerate data (#361)", {
  # All concentrations missing: there is no minimum to impute, so the data are
  # unchanged
  expect_equal(
    PKNCA_impute_method_start_cmin(conc = rep(NA_real_, 3), time = 1:3, start = 0, end = 24),
    data.frame(conc = rep(NA_real_, 3), time = 1:3)
  )
  # All times missing: no concentration is known to be within the interval, so
  # the data are unchanged
  expect_equal(
    PKNCA_impute_method_start_cmin(conc = 1:3, time = rep(NA_real_, 3), start = 0, end = 24),
    data.frame(conc = 1:3, time = rep(NA_real_, 3))
  )
  # A missing time is ignored when finding the minimum within the interval, and
  # the row with the unknown time sorts to the end
  expect_equal(
    PKNCA_impute_method_start_cmin(conc = c(0.5, 1:3), time = c(NA, 1:3), start = 0, end = 24),
    data.frame(conc = c(1, 1:3, 0.5), time = c(0, 1:3, NA)),
    ignore_attr = TRUE
  )
  # All concentrations zero: zero is the minimum and is imputed at the start
  expect_equal(
    PKNCA_impute_method_start_cmin(conc = rep(0, 3), time = 1:3, start = 0, end = 24),
    data.frame(conc = rep(0, 4), time = 0:3),
    ignore_attr = TRUE
  )
})

test_that("PKNCA_impute_method_end_conc_drop", {
  # A concentration exactly at the end is dropped
  expect_equal(
    PKNCA_impute_method_end_conc_drop(conc = c(10, 5, 1), time = c(0, 12, 24), end = 24),
    data.frame(conc = c(10, 5), time = c(0, 12)),
    ignore_attr = TRUE
  )
  # No modification when nothing sits exactly at the end
  expect_equal(
    PKNCA_impute_method_end_conc_drop(conc = c(10, 5, 1), time = c(0, 12, 23), end = 24),
    data.frame(conc = c(10, 5, 1), time = c(0, 12, 23))
  )
  # Only the end point is dropped, earlier points are untouched
  expect_equal(
    PKNCA_impute_method_end_conc_drop(conc = c(10, 8, 6, 100), time = c(0, 1, 2, 24), end = 24),
    data.frame(conc = c(10, 8, 6), time = c(0, 1, 2)),
    ignore_attr = TRUE
  )
  # Works through the impute column of pk.nca: the boundary point (a foreign
  # spike mimicking the next dose's C0) is removed for that interval only.
  clean <- data.frame(
    ID = 1,
    time = c(0, 1, 2, 4, 8, 12, 24),
    conc = c(10, 8, 6.5, 4, 2, 1, 0.5)
  )
  spiked <- clean
  spiked$conc[spiked$time == 24] <- 100
  dose <- data.frame(ID = 1, time = 0, dose = 100)
  
  make_tmax <- function(conc_df, impute) {
    o_conc <- PKNCAconc(conc_df, formula = conc~time|ID)
    o_dose <- PKNCAdose(dose, formula = dose~time|ID, route = "intravascular")
    intervals <- data.frame(start = 0, end = 24, tmax = TRUE)
    if (!is.null(impute)) intervals$impute <- impute
    o_data <- PKNCAdata(o_conc, o_dose, intervals = intervals)
    res <- as.data.frame(pk.nca(o_data))
    res$PPORRES[res$PPTESTCD == "tmax"]
  }
  
  # Without imputation the boundary spike wins tmax (== end)
  expect_equal(make_tmax(spiked, NULL), 24)
  # With the drop imputation the spike is removed and tmax returns to 0
  expect_equal(make_tmax(spiked, "end_conc_drop"), 0)
  # Applying the imputation to clean data (no boundary point) is a no-op
  expect_equal(
    make_tmax(clean, "end_conc_drop"),
    make_tmax(clean, NULL)
  )
})

test_that("PKNCA_impute_method_end_conc_drop with degenerate data (#361)", {
  # All concentrations missing: the row at the end is still dropped
  expect_equal(
    PKNCA_impute_method_end_conc_drop(conc = rep(NA_real_, 3), time = c(0, 12, 24), end = 24),
    data.frame(conc = rep(NA_real_, 2), time = c(0, 12)),
    ignore_attr = TRUE
  )
  # All times missing: no time is known to be at the end, so nothing is dropped
  expect_equal(
    PKNCA_impute_method_end_conc_drop(conc = 1:3, time = rep(NA_real_, 3), end = 24),
    data.frame(conc = 1:3, time = rep(NA_real_, 3))
  )
  # All concentrations zero: the row at the end is still dropped
  expect_equal(
    PKNCA_impute_method_end_conc_drop(conc = rep(0, 3), time = c(0, 12, 24), end = 24),
    data.frame(conc = rep(0, 2), time = c(0, 12)),
    ignore_attr = TRUE
  )
})

test_that("PKNCA_impute_fun_list", {
  expect_equal(
    PKNCA_impute_fun_list(NA_character_),
    list(NA_character_)
  )
  # an empty string is the same as NA
  expect_equal(
    PKNCA_impute_fun_list(NA_character_),
    PKNCA_impute_fun_list("")
  )
  # logical NA works the same as character NA
  expect_equal(
    PKNCA_impute_fun_list(NA_character_),
    PKNCA_impute_fun_list(NA)
  )
  # Non-character input (other than all NA) is an error
  expect_error(
    PKNCA_impute_fun_list(1),
    regexp = "non-character argument"
  )
  # One imputation method works
  expect_equal(
    PKNCA_impute_fun_list("start_conc0"),
    list("PKNCA_impute_method_start_conc0")
  )
  # Two imputation methods detect errors correctly
  expect_error(
    PKNCA_impute_fun_list("start_conc0,foo"),
    regexp = "The following imputation functions were not found: PKNCA_impute_method_foo"
  )
  # Two imputation methods work
  expect_equal(
    PKNCA_impute_fun_list("start_conc0,start_predose"),
    list(c("PKNCA_impute_method_start_conc0", "PKNCA_impute_method_start_predose"))
  )
  # A vector of different imputation methods works
  expect_equal(
    PKNCA_impute_fun_list(c(NA, NA_character_, "", "start_conc0,start_predose", "start_conc0")),
    list(
      NA_character_,
      NA_character_,
      NA_character_,
      c("PKNCA_impute_method_start_conc0", "PKNCA_impute_method_start_predose"),
      "PKNCA_impute_method_start_conc0"
    )
  )
})

test_that("PKNCA_impute_fun_list_paste", {
  expect_equal(
    PKNCA_impute_fun_list_paste("A"),
    "PKNCA_impute_method_A"
  )
  expect_equal(
    PKNCA_impute_fun_list_paste("PKNCA_impute_method_A"),
    "PKNCA_impute_method_A"
  )
  expect_equal(
    PKNCA_impute_fun_list_paste(NA_character_),
    NA_character_
  )
  expect_equal(
    PKNCA_impute_fun_list_paste(c("PKNCA_impute_method_A", "A", NA)),
    c("PKNCA_impute_method_A", "PKNCA_impute_method_A", NA_character_)
  )
})

test_that("PKNCAdata moves imputation to the intervals column, as applicable", {
  d_conc <- generate.conc(nsub = 1, ntreat = 1, time.points = 1:3, nstudies = 1)
  o_conc <- PKNCAconc(conc~time, data = d_conc)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 3, auclast = TRUE))
  # No imputation creates no imputation instructions
  expect_equal(o_data$impute, NA_character_)

  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 3, auclast = TRUE), impute = "PKNCA_impute_method_start_conc0")
  expect_equal(o_data$impute, "PKNCA_impute_method_start_conc0")
  pk.nca(o_data)

  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = 3, auclast = TRUE), impute = "start_conc0")
  expect_equal(o_data$impute, "start_conc0")
})

# Putting it all together
test_that("pk.nca with imputation", {
  d_conc <- as.data.frame(datasets::Theoph)[!datasets::Theoph$Time == 0, ]
  conc_obj <- PKNCAconc(d_conc, conc~Time|Subject)
  d_dose <- unique(datasets::Theoph[datasets::Theoph$Time == 0,
                                    c("Dose", "Time", "Subject")])
  dose_obj <- PKNCAdose(d_dose, Dose~Time|Subject)
  data_obj_noimpute <- PKNCAdata(conc_obj, dose_obj)
  data_obj_impute <- PKNCAdata(conc_obj, dose_obj, impute = "start_predose,start_conc0")
  suppressWarnings(nca_obj_noimpute <- pk.nca(data_obj_noimpute))
  nca_obj_impute <- pk.nca(data_obj_impute)

  # By interval imputation works
  d_intervals <-
    data.frame(
      start=0, end=c(24, 24.1),
      auclast=TRUE,
      impute=c(NA, "start_conc0")
    )

  data_obj_manualimpute <- PKNCAdata(conc_obj, dose_obj, intervals = d_intervals, impute = "impute")
  suppressWarnings(nca_obj_manualimpute <- pk.nca(data_obj_manualimpute))

  auclast_noimpute <- as.data.frame(nca_obj_noimpute)
  auclast_noimpute <- auclast_noimpute$PPORRES[auclast_noimpute$PPTESTCD %in% "auclast"]
  expect_true(all(is.na(auclast_noimpute)))
  auclast_impute <- as.data.frame(nca_obj_impute)
  auclast_impute <- auclast_impute$PPORRES[auclast_impute$PPTESTCD %in% "auclast"]
  expect_true(!any(is.na(auclast_impute)))

  auclast_manualimpute <- as.data.frame(nca_obj_manualimpute)
  auclast_manualimpute_24 <- auclast_manualimpute$PPORRES[auclast_manualimpute$PPTESTCD %in% "auclast" & auclast_manualimpute$end %in% 24]
  auclast_manualimpute_24.1 <- auclast_manualimpute$PPORRES[auclast_manualimpute$PPTESTCD %in% "auclast" & auclast_manualimpute$end %in% 24.1]
  expect_true(all(is.na(auclast_manualimpute_24)))
  expect_true(!any(is.na(auclast_manualimpute_24.1)))
})

test_that("start_conc0 imputation works (fix #257)", {
  d <- data.frame(time=c(0.08, 1, 2, 3, 4),
                  conc=c(1, 0.5, 0.4, 0.3, 0.2),
                  subject=1)
  myconc <- PKNCAconc(data=d, conc~time|subject)
  mydata <-
    PKNCAdata(
      myconc,
      intervals=
        data.frame(
          start=0, end=5,
          impute="start_conc0",
          cmax        = TRUE,
          tmax        = TRUE,
          aucinf.obs  = TRUE,
          aucint.last = TRUE,
          auclast     = TRUE
        )
    )
  suppressMessages(suppressWarnings(
    myres <- pk.nca(mydata)
  ))
  df_myres <- as.data.frame(myres)
  expect_false(is.na(df_myres$PPORRES[df_myres$PPTESTCD == "auclast"]))
})

test_that("PKNCA_impute_fun_list", {
  PKNCA_impute_method_character <- "A"
  expect_error(PKNCA_impute_fun_list("character"),
               regexp = "The following imputation functions were not found: PKNCA_impute_method_character"
  )
})

test_that("PKNCA_impute_fun_list errors when imputation name resolves to a non-function", {
  # utils::getAnywhere only searches namespaces and the search path, not local
  # frames. Assign a non-function object to .GlobalEnv so getAnywhere finds it.
  nm <- "PKNCA_impute_method_notafun_cov_test"
  assign(nm, 42L, envir = .GlobalEnv)
  on.exit(rm(list = nm, envir = .GlobalEnv), add = TRUE)
  expect_error(
    PKNCA_impute_fun_list("notafun_cov_test"),
    regexp = "The following imputation functions were not found"
  )
})

test_that("get_impute_method", {
  ivals <- data.frame(start = 0, end = 24, impute = "start_conc0")
  
  # impute names a column in intervals directly
  expect_equal(
    get_impute_method(intervals = data.frame(start = 0, end = 24, myimpute = "start_conc0"), impute = "myimpute"),
    "start_conc0"
  )
  # impute is NA and a generic "impute" column exists
  expect_equal(
    get_impute_method(intervals = ivals, impute = NA),
    "start_conc0"
  )
  # impute is NA and no "impute" column exists -- returns NA itself
  expect_equal(
    get_impute_method(intervals = data.frame(start = 0, end = 24), impute = NA_character_),
    NA_character_
  )
  
  # the checkmate::assert_scalar() tightening 
  expect_error(
    get_impute_method(intervals = ivals, impute = list("start_conc0"))
  )
})
