test_that("pk.calc.half.life", {
  # Confirm that half-life is correctly calculated with a simple
  # exponential decay
  v1 <-
    pk.calc.half.life(conc=c(1, 0.5, 0.25),
                      time=c(0, 1, 2),
                      min.hl.points=3,
                      allow.tmax.in.half.life=TRUE,
                      adj.r.squared.factor=0.0001)$half.life
  expect_equal(v1, 1)

  # Ensure that when input data is not checked, the code works
  # correctly.
  v2 <-
    pk.calc.half.life(conc=c(1, 0.5, 0.25),
                      time=c(0, 1, 2),
                      min.hl.points=3,
                      allow.tmax.in.half.life=TRUE,
                      adj.r.squared.factor=0.0001,
                      check=FALSE)$half.life

  expect_equal(v2, 1)

  # Ensure that min.hl.points is respected
  expect_warning(pk.calc.half.life(conc=c(1, 0.5, 0.25),
                                   time=c(0, 1, 2),
                                   min.hl.points=4),
                 regexp="Too few points for half-life calculation")

  # Ensure that when there are more than one best models by adjusted
  # r-squared, the one with the most points is used.
  expect_warning(
    expect_equal(pk.calc.half.life(conc=c(1, 0.5, 0.25, 0.1251),
                                   time=c(0, 1, 2, 3),
                                   min.hl.points=3,
                                   allow.tmax.in.half.life=TRUE,
                                   adj.r.squared.factor=0.1,
                                   check=FALSE)$half.life,
                 1.000346,
                 tolerance=0.0001))

  # Ensure that the allow.tmax.in.half.life parameter is followed
  expect_equal(pk.calc.half.life(conc=c(1, 0.5, 0.25, 0.1251),
                                 time=c(0, 1, 2, 3),
                                 min.hl.points=3,
                                 allow.tmax.in.half.life=FALSE,
                                 check=FALSE)$half.life,
               1.000577,
               tolerance=0.00001)
  expect_warning(
    expect_equal(pk.calc.half.life(conc=c(1, 0.5, 0.25, 0.1251),
                                   time=c(0, 1, 2, 3),
                                   min.hl.points=3,
                                   allow.tmax.in.half.life=TRUE,
                                   adj.r.squared.factor=0.1,
                                   check=FALSE)$half.life,
                 1.000346,
                 tolerance=0.00001))


  # Make sure that when tmax and tlast are given that they are
  # automatically included and not recalculated
  expect_equal(pk.calc.half.life(conc=c(1, 0.5, 0.25, 0.1251),
                                 time=c(0, 1, 2, 3),
                                 min.hl.points=3,
                                 tmax=0,
                                 tlast=3,
                                 allow.tmax.in.half.life=TRUE,
                                 adj.r.squared.factor=0.01,
                                 check=FALSE),
               data.frame(lambda.z=0.6929073,
                          r.squared=0.9999999,
                          adj.r.squared=0.9999999,
                          lambda.z.corrxy = -1.000000,
                          lambda.z.time.first=0,
                          lambda.z.time.last=3,
                          lambda.z.n.points=4,
                          clast.pred=0.12507,
                          half.life=1.000346,
                          span.ratio=2.998962),
               tolerance=0.0001)
  # It only gives tlast or tmax if you don't give them as inputs.
  expect_equal(pk.calc.half.life(conc=c(1, 0.5, 0.25, 0.1251),
                                 time=c(0, 1, 2, 3),
                                 min.hl.points=3,
                                 tlast=3,
                                 allow.tmax.in.half.life=TRUE,
                                 adj.r.squared.factor=0.01,
                                 check=FALSE),
               data.frame(lambda.z=0.6929073,
                          r.squared=0.9999999,
                          adj.r.squared=0.9999999,
                          lambda.z.corrxy = -1.000000,
                          lambda.z.time.first=0,
                          lambda.z.time.last=3,
                          lambda.z.n.points=4,
                          clast.pred=0.12507,
                          half.life=1.000346,
                          span.ratio=2.998962,
                          tmax=0),
               tolerance=0.0001)
    expect_equal(pk.calc.half.life(conc=c(1, 0.5, 0.25, 0.1251),
                                 time=c(0, 1, 2, 3),
                                 min.hl.points=3,
                                 tmax=0,
                                 allow.tmax.in.half.life=TRUE,
                                 adj.r.squared.factor=0.01,
                                 check=FALSE),
               data.frame(lambda.z=0.6929073,
                          r.squared=0.9999999,
                          adj.r.squared=0.9999999,
                          lambda.z.corrxy = -1.000000,
                          lambda.z.time.first=0,
                          lambda.z.time.last=3,
                          lambda.z.n.points=4,
                          clast.pred=0.12507,
                          half.life=1.000346,
                          span.ratio=2.998962,
                          tlast=3),
               tolerance=0.0001)

})

test_that("half-life manual point selection", {
  expect_equal(
      pk.calc.half.life(conc=c(3, 1, 0.5, 0.13, 0.12, 0.113),
                        time=c(0, 1, 2, 3, 4, 5),
                        manually.selected.points=TRUE,
                        min.hl.points=3,
                        allow.tmax.in.half.life=FALSE,
                        check=FALSE)$half.life,
      1.00653,
      tolerance=0.0001,
      info="manual selection uses the given points as is")
  expect_true(
    pk.calc.half.life(conc=c(3, 1, 0.5, 0.13, 0.12, 0.113),
                      time=c(0, 1, 2, 3, 4, 5),
                      manually.selected.points=TRUE,
                      min.hl.points=3,
                      allow.tmax.in.half.life=FALSE,
                      check=FALSE)$half.life !=
      pk.calc.half.life(conc=c(3, 1, 0.5, 0.13, 0.12, 0.113),
                        time=c(0, 1, 2, 3, 4, 5),
                        min.hl.points=3,
                        allow.tmax.in.half.life=FALSE,
                        check=FALSE)$half.life,
    info="manual selection is different than automatic selection")
  expect_true(
    pk.calc.half.life(conc=c(3, 1, 0.5, 0.13, 0.12, 0.113),
                      time=c(0, 1, 2, 3, 4, 5),
                      manually.selected.points=TRUE,
                      min.hl.points=3,
                      tlast=20,
                      allow.tmax.in.half.life=FALSE,
                      check=FALSE)$clast.pred <
      pk.calc.half.life(conc=c(3, 1, 0.5, 0.13, 0.12, 0.113),
                        time=c(0, 1, 2, 3, 4, 5),
                        manually.selected.points=TRUE,
                        min.hl.points=3,
                        allow.tmax.in.half.life=FALSE,
                        check=FALSE)$clast.pred,
    info="manually-selected half-life respects tlast and generates a different clast.pred")
  expect_warning(
    manual_blq <-
      pk.calc.half.life(
        conc=rep(0, 6),
        time=c(0, 1, 2, 3, 4, 5),
        manually.selected.points=TRUE,
        min.hl.points=3,
        tlast=20,
        allow.tmax.in.half.life=FALSE,
        check=FALSE
      ),
    regexp="No data to manually fit for half-life (all concentrations may be 0 or excluded)",
    fixed=TRUE,
    info="All BLQ with manual point selection gives a warning"
  )
  expect_true(all(is.na(unlist(manual_blq))),
              info="All BLQ with manual point selection gives all NA results")

  excluded_result <-
    data.frame(
      lambda.z = -log(2),
      r.squared = 1,
      adj.r.squared = 1,
      lambda.z.corrxy = 1,
      lambda.z.time.first = 1L,
      lambda.z.time.last = 3L,
      lambda.z.n.points = 3L,
      clast.pred = 8,
      half.life = -1,
      span.ratio = -2,
      tmax = 3L,
      tlast = 3L
    )
  attr(excluded_result, "exclude") <- "Negative half-life estimated with manually-selected points"
  expect_equal(
    pk.calc.half.life(conc = 2^(1:3), time = 1:3, manually.selected.points = TRUE),
    excluded_result
  )
})

test_that("two-point half-life succeeds (fix #114)", {
  expect_warning(expect_warning(
    expect_equal(
      pk.calc.half.life(
        conc=c(1, 0.5),
        time=c(0, 1),
        min.hl.points=2,
        allow.tmax.in.half.life=TRUE,
        check=FALSE
      ),
      data.frame(
        lambda.z=log(2),
        r.squared=1,
        adj.r.squared=NA_real_,
        lambda.z.corrxy = -1,
        lambda.z.time.first=0,
        lambda.z.time.last=1,
        lambda.z.n.points=2,
        clast.pred=0.5,
        half.life=1,
        span.ratio=1,
        tmax=0,
        tlast=1
      )
    ),
    class = "pknca_halflife_2points"),
    class = "pknca_adjr2_2points"
  )
})

test_that("When tlast is excluded, lambda.z.time.last != tlast", {
  d_conc <- data.frame(
    conc = c(1, 0.5, 0.25, 0.1251, 0.05, 0),
    time = c(0, 1, 2, 3, 4, 5),
    exclude_hl = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE),
    subject = 1
  )
  d_dose <- data.frame(dose = 1, time = 0, subject = 1)

  o_conc <- PKNCAconc(d_conc, formula = conc ~ time | subject, exclude_half.life = "exclude_hl")
  o_dose <- PKNCAdose(d_dose, formula = dose ~ time | subject)
  o_data <- PKNCAdata(o_conc, o_dose)
  myresult <- pk.nca(o_data)
  expect_equal(
    myresult$result[myresult$result$PPTESTCD == "lambda.z.time.last",]$PPORRES,
    3
  )
})


test_that("lambda.z.time.first is after the absorption phase in infusion studies (shifts with duration)", {
  # Simulate an infusion with two different durations
  d_conc <- data.frame(
    conc = c(0.5, 1.0, 0.5, 0.12, 0.25, 0.05),
    time = 1:6,
    subject = 1
  )
  d_dose <- data.frame(
    dose = 1,
    time = 0,
    duration1 = 2,  # Duration for case 1
    duration2 = 3,  # Duration for case 2
    route = "intravascular",
    subject = 1
  )

  # First case: duration = 2, so lambda.z.time.first should be after 2
  o_data1 <- PKNCAdata(
    PKNCAconc(d_conc, conc ~ time | subject),
    PKNCAdose(d_dose, dose ~ time | subject, route = "route", duration = "duration1"),
    intervals = data.frame(start = 0, end = Inf, half.life = TRUE)
  )
  res1 <- pk.nca(o_data1)
  lz_first1 <- res1$result$PPORRES[res1$result$PPTESTCD == "lambda.z.time.first"]
  expect_equal(lz_first1, 3)

  # Second case: duration = 4, so lambda.z.time.first should be after 3
  o_data2 <- PKNCAdata(
    PKNCAconc(d_conc, conc ~ time | subject),
    PKNCAdose(d_dose, dose ~ time | subject, route = "route", duration = "duration2"),
    intervals = data.frame(start = 0, end = Inf, half.life = TRUE)
  )
  res2 <- pk.nca(o_data2)
  lz_first2 <- res2$result$PPORRES[res2$result$PPTESTCD == "lambda.z.time.first"]
  expect_equal(lz_first2, 4)

  # And the second case should be later than the first
  expect_true(lz_first2 > lz_first1)
})

test_that("for an interval with multiple doses lambda.z is calculated for the latest one", {
  # Simulate two infusions: one at time 0 (duration 2), one at time 4 (duration 2)
  d_conc <- data.frame(
    conc = c(0.5, 1.0, 0.99, 0.98, 0.97, 0.96,
             0.5, 1.0, 0.8, 0.5, 0.2, 0.1),
    time = 1:12,
    subject = 1
  )
  d_dose <- data.frame(
    dose = c(1, 1),
    time = c(6, 0),
    duration = c(2, 2),
    route = "intravascular",
    subject = 1
  )
  o_data <- PKNCAdata(
    PKNCAconc(d_conc, conc ~ time | subject),
    PKNCAdose(d_dose, dose ~ time | subject, route = "route", duration = "duration"),
    intervals = data.frame(start = c(0, 0, 6),
                           end = c(Inf, 6, 12),
                           half.life = TRUE)
  )
  res <- pk.nca(o_data)
  lzs <- res$result$PPORRES[res$result$PPTESTCD == "lambda.z"]
  # Lambda z for the first interval (0 to Inf) should be the same as for the third interval (6 to 12)
  expect_equal(lzs[1], lzs[3])
})

test_that("get_halflife_points method (1: PKNCAdata, 2: PKNCAresults)", {
  # Standard analysis ----
  o_conc <- PKNCAconc(Theoph, conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_nca <- suppressMessages(pk.nca(o_data))

  hl_points1 <- suppressMessages(get_halflife_points(o_data))
  hl_points2 <- suppressMessages(get_halflife_points(o_nca))

  # Visualize the results
  # d_all <- Theoph
  # d_all$hl_points2 <- hl_points2
  # ggplot(d_all, aes(x = Time, y = conc, colour = hl_points2, groups = Subject)) +
  #   geom_point() + geom_line()
  expect_equal(hl_points1, hl_points2)
  expect_equal(
    hl_points2,
    c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE,
      TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
      TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE,
      FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE,
      FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, FALSE,
      FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
      FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE,
      TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, FALSE, TRUE, TRUE, TRUE)
  )

  # Other analyses that are dependent on half-life trigger the half-life calculation ----
  o_conc <- PKNCAconc(Theoph, conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, aucinf.obs = TRUE))
  o_nca <- suppressMessages(pk.nca(o_data))

  hl_points1 <- suppressMessages(get_halflife_points(o_data))
  hl_points2 <- suppressMessages(get_halflife_points(o_nca))

  # Visualize the results
  # d_all <- Theoph
  # d_all$hl_points2 <- hl_points2
  # ggplot(d_all, aes(x = Time, y = conc, colour = hl_points2, groups = Subject)) +
  #   geom_point() + geom_line()
  expect_equal(hl_points1, hl_points2)
  expect_equal(
    hl_points2,
    c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE,
      TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
      TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE,
      FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE,
      FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, FALSE,
      FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
      FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE,
      TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE,
      FALSE, FALSE, FALSE, TRUE, TRUE, TRUE)
  )


  # start != 0 (#470) ----
  o_data_nzstart <- PKNCAdata(o_conc, intervals = data.frame(start = 5, end = Inf, half.life = TRUE))
  o_nca_nzstart <- suppressMessages(pk.nca(o_data_nzstart))

  hl_points1_nzstart <- suppressMessages(get_halflife_points(o_data_nzstart))
  hl_points2_nzstart <- suppressMessages(get_halflife_points(o_nca_nzstart))
  # Find the specific rows that have differences
  expect_equal(hl_points1_nzstart, hl_points2_nzstart)
  expect_equal(which(!is.na(hl_points2_nzstart) & hl_points2 != hl_points2_nzstart), c(62, 63, 84))
  expect_true(all(is.na(hl_points2_nzstart[Theoph$Time < 5])))
  expect_true(!any(is.na(hl_points2_nzstart[Theoph$Time > 5])))

  # Setup for the remaining tests ----
  d_conc <- as.data.frame(Theoph[Theoph$Subject %in% Theoph$Subject[1], ])
  d_conc$incl <- c(FALSE, TRUE, rep(NA, 8), TRUE)
  d_conc$excl_txt <- c(NA, "x", rep(NA, 8), "x")
  d_conc$excl <- c(NA, TRUE, rep(NA, 6), TRUE, FALSE, TRUE)

  ## No modification/exclusion ----
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_nca <- suppressMessages(suppressWarnings(pk.nca(o_data)))
  hl_points1 <- suppressMessages(get_halflife_points(o_data))
  hl_points2 <- suppressMessages(get_halflife_points(o_nca))
  expect_equal(hl_points1, hl_points2)
  expect_equal(
    hl_points1,
    c(rep(FALSE, 8), rep(TRUE, 3))
  )

  ## Test include_half.life ----
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject, include_half.life = "incl")
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_nca <- suppressMessages(suppressWarnings(pk.nca(o_data)))

  hl_points1 <- suppressMessages(suppressWarnings(get_halflife_points(o_data)))
  hl_points2 <- suppressMessages(get_halflife_points(o_nca))
  expect_equal(hl_points1, hl_points2)
  expect_equal(
    hl_points1,
    c(FALSE, TRUE, rep(FALSE, 8), TRUE)
  )

  ## Test exclude ----
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject, exclude = "excl_txt")
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_nca <- suppressMessages(pk.nca(o_data))

  hl_points1 <- suppressMessages(get_halflife_points(o_data))
  hl_points2 <- suppressMessages(get_halflife_points(o_nca))
  expect_equal(hl_points1, hl_points2)
  expect_equal(
    hl_points2,
    # NA values indicate that the point was excluded from all calculations
    c(FALSE, NA, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, NA)
  )

  ## Test exclude_half.life ----
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject, exclude_half.life = "excl")
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_nca <- suppressMessages(pk.nca(o_data))

  hl_points1 <- suppressMessages(get_halflife_points(o_data))
  hl_points2 <- suppressMessages(get_halflife_points(o_nca))
  expect_equal(hl_points1, hl_points2)
  expect_equal(
    hl_points1,
    # NA values indicate that the point was excluded from all calculations
    c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, TRUE, FALSE)
  )

  ## Multiple, overlapping half-life calculations gives an error ----
  o_conc <- PKNCAconc(d_conc, conc~Time|Subject)
  o_data <-
    PKNCAdata(
      o_conc,
      intervals =
        data.frame(
          start = 0, end = c(24, Inf),
          half.life = TRUE
        )
    )
  o_nca <- suppressMessages(suppressWarnings(pk.nca(o_data)))

  exp_error <- "More than one half-life calculation was attempted on the following rows: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11"
  expect_error(suppressMessages(get_halflife_points(o_data)), regexp = exp_error)
  expect_error(suppressMessages(get_halflife_points(o_nca)), regexp = exp_error)

  ## Half-life points are selected right even if lambda.z.time.last != tlast (#448) ----
  d_conc <- data.frame(
    conc = c(1, 0.5, 0.25, 0.125, 0.07, 0, 0.01),
    time = c(0, 1, 2, 3, 4, 5, 6),
    exclude_hl = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE),
    subject = 1
  )
  # without exclusion of Tlast
  o_conc <- PKNCAconc(d_conc, formula = conc ~ time | subject)
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_nca <- suppressMessages(pk.nca(o_data))
  hl_points1 <- suppressMessages(get_halflife_points(o_data))
  hl_points2 <- suppressMessages(get_halflife_points(o_nca))
  # Note that BLQ times are included
  expect_equal(hl_points1, hl_points2)
  expect_equal(
    d_conc$time[which(hl_points2)],
    1:6,
    info = "get_halflife_points uses lambda.z.time.last, not tlast"
  )
  ## with exclusion of Tlast ----
  o_conc <- PKNCAconc(d_conc, formula = conc ~ time | subject, exclude_half.life = "exclude_hl")
  o_data <- PKNCAdata(o_conc, intervals = data.frame(start = 0, end = Inf, half.life = TRUE))
  o_nca <- suppressMessages(pk.nca(o_data))
  hl_points1 <- suppressMessages(get_halflife_points(o_data))
  hl_points2 <- suppressMessages(get_halflife_points(o_nca))
  # lambda.z.time.last should be 4, tlast is 6 and excluded
  expect_equal(hl_points1, hl_points2)
  expect_equal(
    d_conc$time[which(hl_points2)],
    1:4,
    info = "get_halflife_points uses lambda.z.time.last, not tlast"
  )
})

test_that("half-life has a exclude message when it cannot be calculated for flat data (#503)", {
  result <- suppressMessages(
    pk.calc.half.life(
      conc = c(1, 1, 1, 1),
      time = c(0, 1, 2, 3),
      min.hl.points = 3,
      allow.tmax.in.half.life = TRUE,
      adj.r.squared.factor = 0.0001,
      check = FALSE
    )
  )
  expect_equal(
    attr(result, "exclude"),
    "No point variability in concentrations for half-life calculation"
  )
})

# ---- Tobit half-life tests ----

test_that("fit_half_life_tobit_LL returns correct negative log-likelihood", {
  # All above-LLOQ: result should match dnorm log-likelihood
  log_conc <- log(c(1, 0.5, 0.25))
  time <- c(0, 1, 2)
  mask_blq <- c(FALSE, FALSE, FALSE)
  log_lloq <- rep(log(0.01), 3)
  # par: log_c0 = log(1) = 0, lambda_z = log(2), log_resid_error = log(0.01)
  par <- c(log_c0 = 0, lambda_z = log(2), log_resid_error = log(0.01))
  ll <- PKNCA:::fit_half_life_tobit_LL(par, log_conc, time, mask_blq, log_lloq)
  est <- par[["log_c0"]] - par[["lambda_z"]] * time
  expected_ll <- -sum(dnorm(log_conc, mean = est, sd = exp(par[["log_resid_error"]]), log = TRUE))
  expect_equal(ll, expected_ll)
})

test_that("fit_half_life_tobit_LL handles BLQ observations", {
  # One BLQ observation: should use pnorm for that point
  log_conc <- c(log(1), log(0.5), -Inf)  # third is BLQ
  time <- c(0, 1, 2)
  lloq_val <- 0.3
  mask_blq <- c(FALSE, FALSE, TRUE)
  log_lloq <- rep(log(lloq_val), 3)
  par <- c(log_c0 = 0, lambda_z = log(2), log_resid_error = log(0.1))
  ll <- PKNCA:::fit_half_life_tobit_LL(par, log_conc, time, mask_blq, log_lloq)
  est <- par[["log_c0"]] - par[["lambda_z"]] * time
  sd_val <- exp(par[["log_resid_error"]])
  expected_ll <- -(
    sum(dnorm(log_conc[!mask_blq], mean = est[!mask_blq], sd = sd_val, log = TRUE)) +
    sum(pnorm(log_lloq[mask_blq], mean = est[mask_blq], sd = sd_val, log.p = TRUE))
  )
  expect_equal(ll, expected_ll)
})

test_that("fit_half_life_tobit recovers known parameters (all above-LLOQ)", {
  # Exact exponential decay with no noise: half-life should be 1
  conc <- c(1, 0.5, 0.25, 0.125)
  time <- c(0, 1, 2, 3)
  lloq <- rep(0.01, 4)
  data <- data.frame(
    log_conc = log(conc),
    time = time,
    log_lloq = log(lloq),
    mask_blq = conc < lloq
  )
  result <- PKNCA:::fit_half_life_tobit(data, tlast = 3)
  expect_equal(result$half.life, 1, tolerance = 0.01)
  expect_equal(result$lambda.z, log(2), tolerance = 0.01)
  expect_equal(result$lambda.z.n.points, 4L)
  expect_equal(result$lambda.z.n.points_blq, 0L)
  expect_false(is.na(result$tobit_residual))
  expect_false(is.na(result$adj_tobit_residual))
})

test_that("fit_half_life_tobit returns NA with warning on too few above-LLOQ points", {
  data <- data.frame(
    log_conc = log(c(0.05, 0.03)),
    time = c(1, 2),
    log_lloq = log(c(0.1, 0.1)),
    mask_blq = c(TRUE, TRUE)  # both BLQ
  )
  expect_warning(
    result <- PKNCA:::fit_half_life_tobit(data, tlast = 2),
    class = "pknca_tobit_too_few_points"
  )
  expect_true(is.na(result$lambda.z))
  expect_true(is.na(result$half.life))
})

test_that("fit_half_life_tobit returns NA with warning on no variability", {
  data <- data.frame(
    log_conc = log(c(1, 1, 1)),
    time = c(0, 1, 2),
    log_lloq = log(c(0.1, 0.1, 0.1)),
    mask_blq = c(FALSE, FALSE, FALSE)
  )
  expect_warning(
    result <- PKNCA:::fit_half_life_tobit(data, tlast = 2),
    class = "pknca_tobit_no_variability"
  )
  expect_true(is.na(result$lambda.z))
})

test_that("pk.calc.half.life hl_method='tobit' requires lloq", {
  expect_error(
    pk.calc.half.life(
      conc = c(1, 0.5, 0.25),
      time = c(0, 1, 2),
      hl_method = "tobit"
    ),
    regexp = "lloq must be provided"
  )
})

test_that("pk.calc.half.life hl_method='tobit' matches log-linear when no BLQ", {
  # Slightly noisy data (well above LLOQ) — Tobit and log-linear should agree closely.
  # Exact exponential data is avoided here because n_points == n_parameters in the
  # smallest window causes the optimizer's residual to degenerate toward 0.
  conc <- c(1.02, 0.49, 0.26, 0.123)   # ~2 % noise around exact decay
  time <- c(0, 1, 2, 3)
  lloq <- 0.01

  result_ll <- pk.calc.half.life(
    conc = conc, time = time,
    hl_method = "log-linear",
    allow.tmax.in.half.life = TRUE,
    min.hl.points = 3
  )
  result_tobit <- pk.calc.half.life(
    conc = conc, time = time, lloq = lloq,
    hl_method = "tobit",
    allow.tmax.in.half.life = TRUE,
    min.hl.points = 3
  )
  expect_equal(result_tobit$half.life, result_ll$half.life, tolerance = 0.05)
  expect_equal(result_tobit$lambda.z, result_ll$lambda.z, tolerance = 0.05)
  # Tobit-specific columns present
  expect_false(is.na(result_tobit$tobit_residual))
  expect_false(is.na(result_tobit$lambda.z.n.points_blq))
  # Log-linear-specific columns absent from Tobit result
  expect_null(result_tobit$r.squared)
  expect_null(result_tobit$adj.r.squared)
  expect_null(result_tobit$lambda.z.corrxy)
})

test_that("pk.calc.half.life hl_method='tobit' includes BLQ points and improves estimate", {
  # True half-life = 1.  Without Tobit (log-linear ignores BLQ), only 3 above-LLOQ
  # points are used and the estimate is less accurate.
  # With Tobit, the BLQ points provide additional information.
  conc_true <- c(1, 0.5, 0.25, 0.1, 0.03, 0.009)
  time <- c(0, 1, 2, 3, 4, 5)
  lloq <- 0.05
  conc_obs <- ifelse(conc_true < lloq, 0, conc_true)

  result_ll <- pk.calc.half.life(
    conc = conc_obs, time = time,
    hl_method = "log-linear",
    allow.tmax.in.half.life = TRUE,
    min.hl.points = 3
  )
  result_tobit <- pk.calc.half.life(
    conc = conc_obs, time = time, lloq = lloq,
    hl_method = "tobit",
    allow.tmax.in.half.life = TRUE,
    min.hl.points = 3
  )
  # Tobit should include BLQ points
  expect_true(result_tobit$lambda.z.n.points_blq > 0)
  # Both should give a positive half-life
  expect_true(result_ll$half.life > 0)
  expect_true(result_tobit$half.life > 0)
})

test_that("pk.calc.half.life hl_method='tobit' lambda.z.n.points counts all (including BLQ)", {
  conc_obs <- c(1, 0.5, 0, 0)  # last two are BLQ
  time <- c(0, 1, 2, 3)
  lloq <- 0.1

  result <- pk.calc.half.life(
    conc = conc_obs, time = time, lloq = lloq,
    hl_method = "tobit",
    allow.tmax.in.half.life = TRUE,
    min.hl.points = 2
  )
  # lambda.z.n.points should be >= 3 (includes BLQ points)
  expect_gte(result$lambda.z.n.points, 3L)
  expect_gte(result$lambda.z.n.points_blq, 1L)
  expect_equal(result$lambda.z.n.points_blq + (result$lambda.z.n.points - result$lambda.z.n.points_blq),
               result$lambda.z.n.points)
})

test_that("pk.calc.half.life hl_method='tobit' warns with too few above-LLOQ points", {
  conc_obs <- c(1, 0, 0, 0)  # only 1 above LLOQ
  time <- c(0, 1, 2, 3)
  lloq <- 0.1

  expect_warning(
    result <- pk.calc.half.life(
      conc = conc_obs, time = time, lloq = lloq,
      hl_method = "tobit",
      allow.tmax.in.half.life = TRUE,
      min.hl.points = 3
    ),
    class = "pknca_halflife_too_few_points"
  )
  expect_true(is.na(result$lambda.z))
})

test_that("pk.calc.half.life hl_method='tobit' manually.selected.points works", {
  conc <- c(1, 0.5, 0.25, 0, 0)
  time <- c(0, 1, 2, 3, 4)
  lloq <- 0.1

  result <- pk.calc.half.life(
    conc = conc, time = time, lloq = lloq,
    hl_method = "tobit",
    manually.selected.points = TRUE,
    allow.tmax.in.half.life = TRUE
  )
  expect_false(is.na(result$half.life))
  expect_true(result$half.life > 0)
  expect_equal(result$lambda.z.n.points_blq, 2L)
})

test_that("pk.calc.half.life hl_method='tobit' scalar lloq is broadcast correctly", {
  conc <- c(1, 0.5, 0.25, 0)
  time <- c(0, 1, 2, 3)
  # Single scalar lloq should work identically to a vector of the same value
  result_scalar <- pk.calc.half.life(
    conc = conc, time = time, lloq = 0.1,
    hl_method = "tobit", allow.tmax.in.half.life = TRUE, min.hl.points = 2
  )
  result_vec <- pk.calc.half.life(
    conc = conc, time = time, lloq = rep(0.1, 4),
    hl_method = "tobit", allow.tmax.in.half.life = TRUE, min.hl.points = 2
  )
  expect_equal(result_scalar$half.life, result_vec$half.life)
})

test_that("pk.calc.half.life hl_method='tobit' global option is respected", {
  withr::with_options(
    list(),
    {
      PKNCA.options(hl_method = "tobit")
      on.exit(PKNCA.options(default = TRUE))
      # Use 5 data points with slight noise so all optimisation windows are
      # overdetermined (more points than parameters) and converge reliably.
      result <- pk.calc.half.life(
        conc = c(1.02, 0.49, 0.26, 0.123, 0.064),
        time = c(0, 1, 2, 3, 4),
        lloq = 0.01,
        allow.tmax.in.half.life = TRUE, min.hl.points = 3
      )
      expect_false(is.na(result$tobit_residual))
      expect_null(result$r.squared)
    }
  )
})

test_that("pk.calc.half.life log-linear result is unaffected by Tobit additions", {
  # Existing log-linear behaviour should be completely unchanged
  result <- pk.calc.half.life(
    conc = c(1, 0.5, 0.25),
    time = c(0, 1, 2),
    min.hl.points = 3,
    allow.tmax.in.half.life = TRUE,
    adj.r.squared.factor = 0.0001
  )
  expect_equal(result$half.life, 1)
  expect_false(is.na(result$r.squared))
  expect_false(is.na(result$adj.r.squared))
  expect_null(result$tobit_residual)
  expect_null(result$lambda.z.n.points_blq)
})
