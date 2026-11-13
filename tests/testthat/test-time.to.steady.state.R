test_that("pk.tss.data.prep", {
  conc.test <- 1:5
  time.test <- 0:4
  subject.test <- letters[1:5]
  treatment.test <- LETTERS[1:5]
  time.dosing.test <- 0
  # Confirm that any NAs in time.dosing are an error
  expect_error(
    pk.tss.data.prep(
      conc=conc.test,
      time=time.test,
      subject=subject.test,
      treatment=treatment.test,
      time.dosing=NA
    ),
    regexp="time.dosing may not contain any NA values"
  )
  expect_error(
    pk.tss.data.prep(
      conc=conc.test,
      time=time.test,
      subject.dosing=subject.test,
      treatment=treatment.test,
      time.dosing=NA
    ),
    regexp="Cannot give subject.dosing without subject"
  )
  expect_equal(
    pk.tss.data.prep(
      conc=conc.test,
      time=time.test,
      time.dosing=0
    ),
    data.frame(conc=1, time=0)
  )
  
  expect_error(pk.tss.data.prep(conc=conc.test,
                                time=time.test,
                                subject=subject.test,
                                treatment=treatment.test,
                                time.dosing=c(0, NA)),
               regexp="time.dosing may not contain any NA values")

  # Confirm that conc and subject must be the same length
  expect_error(pk.tss.data.prep(conc=conc.test,
                                time=time.test,
                                subject=subject.test[-1],
                                treatment=treatment.test,
                                time.dosing=time.dosing.test),
               regexp="arguments imply differing number of rows: 5, 4")

  # Confirm that conc and treatment must be the same length
  expect_error(pk.tss.data.prep(conc=conc.test,
                                time=time.test,
                                subject=subject.test,
                                treatment=treatment.test[-1],
                                time.dosing=time.dosing.test),
               regexp="arguments imply differing number of rows: 5, 4")

  # If removed down to one treatment, treatment is not a column of
  # the output.
  expect_equal(pk.tss.data.prep(conc=conc.test,
                                time=time.test,
                                subject=subject.test,
                                treatment=treatment.test,
                                time.dosing=time.dosing.test),
               data.frame(conc=1, time=0))

  # If no treatment is given, it still works.
  expect_equal(pk.tss.data.prep(conc=conc.test,
                                time=time.test,
                                subject=subject.test,
                                time.dosing=time.dosing.test),
               data.frame(conc=1, time=0))

  # If no subject is given, it still works
  expect_equal(pk.tss.data.prep(conc=conc.test,
                                time=time.test,
                                treatment=treatment.test,
                                time.dosing=time.dosing.test),
               data.frame(conc=1, time=0))
  
  # What do we actually expect to get out?
  # Check a single row output dropping treatment
  expect_equal(pk.tss.data.prep(conc=conc.test,
                                time=time.test,
                                subject=subject.test,
                                treatment=treatment.test,
                                time.dosing=time.dosing.test,
                                subject.dosing=subject.test),
               data.frame(time=0, conc=1))

  # Check a single row output with no treatment given
  expect_equal(pk.tss.data.prep(conc=conc.test,
                                time=time.test,
                                subject=subject.test,
                                time.dosing=time.dosing.test),
               data.frame(conc=1, time=0))

  # Check a multi-row output with treatments kept
  conc.test <- 1:10
  time.test <- rep(0:4, 2)
  subject.test <- letters[1:10]
  treatment.test <- LETTERS[1:10]
  time.dosing.test <- 0
  expect_equal(
    pk.tss.data.prep(
      conc=conc.test,
      time=time.test,
      subject=subject.test,
      treatment=treatment.test,
      time.dosing=time.dosing.test
    ),
    data.frame(
      conc=c(1, 6), time=c(0, 0),
      subject=factor(c("a", "f")),
      treatment=factor(c("A", "F"))
    ),
    ignore_attr = TRUE
  )

  # Check a multi-row output with treatments dropped
  conc.test <- 1:10
  time.test <- rep(0:4, 2)
  subject.test <- letters[1:10]
  treatment.test <- rep(LETTERS[1:5], 2)
  time.dosing.test <- 0
  expect_equal(
    pk.tss.data.prep(
      conc=conc.test,
      time=time.test,
      subject=subject.test,
      treatment=treatment.test,
      time.dosing=time.dosing.test
    ),
    data.frame(
      conc=c(1, 6),
      time=c(0, 0),
      subject=factor(c("a", "f"))
    ),
    ignore_attr = TRUE
  )
})

# This data will be used multiple times in testing, and it is
# nontrivial to create.
generate.data <- function() {
  set.seed(5)
  tmpdata <-
    merge(
      data.frame(
        subject=factor(1:10),
        css.re=rnorm(10, sd=0.2),
        tss.re=rnorm(10, sd=0.2),
        treatment=rep(c("A", "B"), each=5)
      ),
      data.frame(
        treatment=c("A", "B"),
        css.mean=c(5, 10),
        tss.mean=5
      )
    )
  tmpdata <- merge(tmpdata, data.frame(time=0:14))
  tmpdata$conc.resid <- rnorm(nrow(tmpdata), sd=0.05)
  tmpdata$conc <- with(tmpdata,
                       css.mean*exp(css.re+conc.resid)*
                       (1-exp(log(1-0.9)*time/(tss.mean*exp(tss.re)))))
  tmpdata
}

# Note that this graphically represents the test
# library(latticeExtra)
# (xyplot(conc~time|treatment,
#         groups=subject,
#         data=generate.data(),
#         type="l") +
#  layer(panel.abline(h=5, col="gray", lty=2), packets=1) +
#  layer(panel.abline(h=10, col="gray", lty=2), packets=2))

test_that("pk.tss.stepwise.linear", {
  tmpdata <- generate.data()
  expect_equal(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           verbose=FALSE),
    data.frame(tss.stepwise.linear=7),
    ignore_attr = "estimates"
  )

  expect_warning(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           min.points=c(3, 4),
                           time.dosing=0:14,
                           verbose=FALSE),
    regexp="Only first value of min.points is used"
  )

  expect_error(
    pk.tss.stepwise.linear(
      conc=tmpdata$conc,
      time=tmpdata$time,
      subject=tmpdata$subject,
      treatment=tmpdata$treatment,
      time.dosing=0:14,
      min.points="A",
      level="A",
      verbose=FALSE
    ),
    regexp="Must be of type 'number'"
  )
  expect_error(
    pk.tss.stepwise.linear(
      conc=tmpdata$conc,
      time=tmpdata$time,
      subject=tmpdata$subject,
      treatment=tmpdata$treatment,
      time.dosing=0:14,
      min.points=1,
      level="A",
      verbose=FALSE
    ),
    regexp="Element 1 is not >= 3"
  )
  
  expect_error(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           level="A",
                           verbose=FALSE),
    regexp="Must be of type 'numeric'"
  )

  expect_error(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           level=2,
                           verbose=FALSE),
    regexp="level must be between 0 and 1, exclusive"
  )
  
  expect_error(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           level=-1,
                           verbose=FALSE),
    regexp="level must be between 0 and 1, exclusive"
  )
  expect_error(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           level=0,
                           verbose=FALSE),
    regexp="level must be between 0 and 1, exclusive"
  )
  expect_error(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           level=1,
                           verbose=FALSE),
    regexp="level must be between 0 and 1, exclusive"
  )

  expect_warning(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           level=c(0.95, 0.99),
                           verbose=FALSE),
    regexp="Only first value of level is being used"
  )

  # This is mainly to test verbosity
  expect_warning(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           level=c(0.95, 0.99),
                           verbose=FALSE),
    regexp="Only first value of level is being used"
  )

  # Check outputs
  suppressMessages(
    withr::with_options(
      list(try.outFile=nullfile()),
      expect_message(
        pk.tss.stepwise.linear(
          conc=tmpdata$conc,
          time=tmpdata$time,
          subject=tmpdata$subject,
          treatment=tmpdata$treatment,
          time.dosing=0:14,
          level=0.8,
          verbose=TRUE
        ),
        regexp="Trying 0"
      )
    )
  )
  suppressMessages(
    withr::with_options(
      list(try.outFile=nullfile()),
      expect_message(
        pk.tss.stepwise.linear(
          conc=tmpdata$conc,
          time=tmpdata$time,
          subject=tmpdata$subject,
          treatment=tmpdata$treatment,
          time.dosing=0:14,
          level=0.8,
          verbose=TRUE
        ),
        regexp="Current interval"
      )
    )
  )
  
  # Ensure that the first value really is used
  expect_warning(v1 <-
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           level=c(0.8, 0.99),
                           verbose=FALSE))
  expect_equal(
    v1,
    pk.tss.stepwise.linear(
      conc=tmpdata$conc,
      time=tmpdata$time,
      subject=tmpdata$subject,
      treatment=tmpdata$treatment,
      time.dosing=0:14,
      level=0.8,
      verbose=FALSE
    )
  )

  # Confirm testing for minimum number of data points
  expect_warning(
    v1 <- pk.tss.stepwise.linear(
      conc=tmpdata$conc,
      time=tmpdata$time,
      subject=tmpdata$subject,
      treatment=tmpdata$treatment,
      time.dosing=0:1,
      min.points=3,
      level=0.99,
      verbose=FALSE
    ),
    regexp="After removing non-dosing time points, insufficient data remains for tss calculation"
  )
  expect_equal(v1, data.frame(tss.stepwise.linear=NA_real_), ignore_attr = "estimates")
  expect_warning(
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:1,
                           min.points=3,
                           level=0.99,
                           verbose=FALSE),
    regexp="After removing non-dosing time points, insufficient data remains for tss calculation")

  # Confirm the glm model works when subject-level data is not given.
  suppressMessages(
    expect_equal(
      pk.tss.stepwise.linear(conc=tmpdata$conc,
                             time=tmpdata$time,
                             treatment=tmpdata$treatment,
                             time.dosing=0:14,
                             verbose=FALSE),
      data.frame(tss.stepwise.linear=5),
      info="pk.tss.stepwise.linear no subject",
      ignore_attr = "estimates"
    )
  )
})

test_that("pk.tss.monoexponential", {
  tmpdata <- generate.data()
  expect_equal(
    pk.tss.monoexponential(
      conc=tmpdata$conc,
      time=tmpdata$time,
      subject=tmpdata$subject,
      treatment=tmpdata$treatment,
      time.dosing=0:14,
      verbose=FALSE
    ),
    data.frame(
      subject=factor(c(1, 10, 2:9), levels=1:10),
      treatment=
        factor(c("A", "B", "A", "A", "A", "A", "B", "B", "B", "B")),
      tss.monoexponential.population=4.57618156812974,
      tss.monoexponential.popind=c(
        5.14156352865421, 4.64862524830397, 4.45956707917941,
        4.41492203844343, 4.6782583033301, 4.0823047621517,
        4.96242115751172, 4.52424147509819, 3.70338406668837,
        5.1465280219363),
      tss.monoexponential.individual=c(
        5.87784329336254, 4.71066285661623, 4.51882509145954,
        3.91269286106442, 4.74475071729459, 3.99341726779716,
        5.08737230904342, 4.50068650719192, 3.4876172020751,
        5.35051537086801),
      # Each treatment's own fit
      tss.monoexponential.single=
        rep(c(4.49364717175, 4.59871031113), c(1, 1))[c(1, 2, 1, 1, 1, 1, 2, 2, 2, 2)]
    ),
    tolerance=1e-4,
    ignore_attr = "estimates"
  )
  expect_warning(
    expect_equal(
      pk.tss.monoexponential(
        conc=c(0, 0, 0, 0),
        time=0:3,
        subject=c(1, 1, 1, 1),
        treatment=c("A", "A", "A", "A"),
        time.dosing=0:3,
        tss.fraction=0.9,
        output="single"
      ),
      data.frame(tss.monoexponential.single=NA_real_),
      info="Single-subject data fitting works when it does not converge.",
      ignore_attr = "estimates"
    ),
    regexp = "approximate covariance matrix for parameter estimates not of full rank",
    class = "pknca_warning_tss_individual_fit_failed"
  )
})

test_that("pk.tss.monoexponential without treatment", {
  tmpdata <- generate.data()
    expect_equal(
      pk.tss.monoexponential(
        conc=tmpdata$conc,
        time=tmpdata$time,
        subject=tmpdata$subject,
        time.dosing=0:14,
        verbose=FALSE
      ),
      data.frame(
        # The levels are those of the subject given
        subject=factor(c(1, 10, 2:9), levels=1:10),
        tss.monoexponential.population=4.561580,
        tss.monoexponential.popind=c(
          5.028357, 4.672555, 4.536178,
          4.295758, 4.660561, 4.158700,
          4.940674, 4.507900, 3.676531,
          5.138583),
        tss.monoexponential.individual=c(
          5.87784329336254, 4.71066285661623, 4.51882509145954,
          3.91269286106442, 4.74475071729459, 3.99341726779716,
          5.08737230904342, 4.50068650719192, 3.4876172020751,
          5.35051537086801),
        tss.monoexponential.single=4.56067603534
      ),
      tolerance=1e-4,
      ignore_attr = "estimates"
    )
})

test_that("pk.tss.monoexponential corner case tests", {
  tmpdata <- generate.data()
  # population output, only:  one row per subject, with its treatment
  expect_equal(
    pk.tss.monoexponential(
      conc=tmpdata$conc,
      time=tmpdata$time,
      subject=tmpdata$subject,
      treatment=tmpdata$treatment,
      time.dosing=0:14,
      output = "population",
      verbose=FALSE
    ),
    data.frame(
      subject=factor(seq_len(10)),
      treatment=factor(rep(c("A", "B"), each=5)),
      tss.monoexponential.population=4.57618156812974
    ),
    tolerance=1e-4,
    ignore_attr = "estimates"
  )
  # (Pseudo) single treatment, only
  expect_equal(
    pk.tss.monoexponential(
      conc=tmpdata$conc,
      time=tmpdata$time,
      subject=tmpdata$subject,
      time.dosing=0:14,
      output = "population",
      verbose=FALSE
    ),
    data.frame(
      subject=factor(seq_len(10)),
      tss.monoexponential.population=4.56157960341961
    ),
    tolerance=1e-4,
    ignore_attr = "estimates"
  )
})

test_that("pk.tss.monoexponential expected warnings and errors", {
  tmpdata <- generate.data()
  expect_error(
    pk.tss.monoexponential(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           tss.fraction=factor(1)),
    regexp="Must be of type 'number'"
  )
  suppressWarnings(
    expect_warning(
      pk.tss.monoexponential(
        conc=tmpdata$conc,
        time=tmpdata$time,
        subject=tmpdata$subject,
        treatment=tmpdata$treatment,
        time.dosing=0:14,
        tss.fraction=c(0.5, 0.8)
      ),
      regexp="Only first value of tss.fraction is being used"
    )
  )
  expect_error(
    pk.tss.monoexponential(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           tss.fraction=0),
    regexp="tss.fraction must be between 0 and 1, exclusive")
  expect_error(
    pk.tss.monoexponential(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           tss.fraction=1),
    regexp="tss.fraction must be between 0 and 1, exclusive")
  expect_error(
    pk.tss.monoexponential(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           tss.fraction=-1),
    regexp="tss.fraction must be between 0 and 1, exclusive")
  expect_error(
    pk.tss.monoexponential(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           tss.fraction=2),
    regexp="tss.fraction must be between 0 and 1, exclusive")
  suppressWarnings(
    expect_warning(
      pk.tss.monoexponential(conc=tmpdata$conc,
                             time=tmpdata$time,
                             subject=tmpdata$subject,
                             treatment=tmpdata$treatment,
                             time.dosing=0:14,
                             tss.fraction=0.5),
      regexp="tss.fraction is usually >= 0.8"
    )
  )
  suppressWarnings(
    expect_warning(
      pk.tss.monoexponential(conc=tmpdata$conc,
                             time=tmpdata$time,
                             subject=tmpdata$subject,
                             treatment=tmpdata$treatment,
                             time.dosing=0:14,
                             tss.fraction=c(0.5, 0.8)),
      regexp="Only first value of tss.fraction is being used"
    )
  )
  tmpdata_single_subject <- tmpdata[tmpdata$subject == 1 & tmpdata$treatment == "A", ]
  expect_warning(
    tss_single_subject <-
      pk.tss.monoexponential(
        conc=tmpdata_single_subject$conc,
        time=tmpdata_single_subject$time,
        subject=tmpdata_single_subject$subject,
        treatment=tmpdata_single_subject$treatment,
        time.dosing=0:14,
        tss.fraction=0.8
      ),
    regexp="Cannot give 'population', 'popind', or 'individual' output without multiple subjects of data",
    fixed=TRUE
  )
  expect_equal(
    tss_single_subject,
    data.frame(tss.monoexponential.single=4.108541),
    tolerance=1e-5,
    ignore_attr = "estimates"
  )
})

test_that("pk.tss", {
  # Ensure that pk.tss will go to the correct type of model
  tmpdata <- generate.data()
  suppressWarnings(
    expect_equal(
      pk.tss(
        conc=tmpdata$conc,
        time=tmpdata$time,
        subject=tmpdata$subject,
        treatment=tmpdata$treatment,
        time.dosing=0:14,
        verbose=FALSE,
        type="monoexponential"
      ),
      pk.tss.monoexponential(
        conc=tmpdata$conc,
        time=tmpdata$time,
        subject=tmpdata$subject,
        treatment=tmpdata$treatment,
        time.dosing=0:14,
        verbose=FALSE
      )
    )
  )

  expect_equal(
    pk.tss(conc=tmpdata$conc,
           time=tmpdata$time,
           subject=tmpdata$subject,
           treatment=tmpdata$treatment,
           time.dosing=0:14,
           verbose=FALSE,
           type="stepwise.linear"),
    pk.tss.stepwise.linear(conc=tmpdata$conc,
                           time=tmpdata$time,
                           subject=tmpdata$subject,
                           treatment=tmpdata$treatment,
                           time.dosing=0:14,
                           verbose=FALSE))

  # pk.tss will calculate both if requested
  suppressWarnings(
    expect_equal(
      pk.tss(
        conc=tmpdata$conc,
        time=tmpdata$time,
        subject=tmpdata$subject,
        treatment=tmpdata$treatment,
        time.dosing=0:14,
        verbose=FALSE,
        type=c("monoexponential", "stepwise.linear")
      ),
      merge(
        pk.tss.monoexponential(
          conc=tmpdata$conc,
          time=tmpdata$time,
          subject=tmpdata$subject,
          treatment=tmpdata$treatment,
          time.dosing=0:14,
          verbose=FALSE
        ),
        pk.tss.stepwise.linear(
          conc=tmpdata$conc,
          time=tmpdata$time,
          subject=tmpdata$subject,
          treatment=tmpdata$treatment,
          time.dosing=0:14,
          verbose=FALSE
        ),
        all=TRUE
      ),
      ignore_attr = "estimates"
    )
  )
})

test_that("pk.tss.monoexponential with single-subject data", {
  d_prep <- datasets::Theoph[datasets::Theoph$Subject %in% 2, ]
  dose_times <- seq(0, 96-1, by=6)
  d_multidose <-
    superposition(
      conc=d_prep$conc,
      time=d_prep$Time,
      tau=96, # 48 hours
      n.tau=1, # One tau interval (0 to 48 hours)
      dose.times=dose_times
    )
  expect_equal(
    pk.tss.monoexponential(
      conc=d_multidose$conc, time=d_multidose$time, subject=rep(1, nrow(d_multidose)),
      time.dosing=dose_times, subject.dosing=rep(1, length(dose_times)),
      output="single"
    ),
    data.frame(tss.monoexponential.single=22.53),
    tolerance=0.001,
    ignore_attr = "estimates"
  )
})

test_that("verbose being TRUE", {
  d_prep <- datasets::Theoph[datasets::Theoph$Subject %in% 2, ]
  dose_times <- seq(0, 96-1, by=6)
  d_multidose <-
    superposition(
      conc=d_prep$conc,
      time=d_prep$Time,
      tau=96, # 48 hours
      n.tau=1, # One tau interval (0 to 48 hours)
      dose.times=dose_times
    )
  expect_equal(
    pk.tss.monoexponential(
      conc=d_multidose$conc, time=d_multidose$time, subject=rep(1, nrow(d_multidose)),
      time.dosing=dose_times, subject.dosing=rep(1, length(dose_times)),
      output="single", verbose = TRUE
    ),
    data.frame(tss.monoexponential.single=22.53),
    tolerance=0.001,
    ignore_attr = "estimates"
  )
})

test_that("tss Monoexponential no models converged", {
  bad_data <- data.frame(subject=rep(1:2, each = 4), time=0, conc=0, tss.constant=0.9)
  expect_warning(pk.tss.monoexponential.population(data = bad_data, output = "population"),
  regexp = "No population model for monoexponential Tss converged, no results given")
})

test_that("tss Monoexponential no models converged with verbose = TRUE", {
  bad_data <- data.frame(subject=rep(1:2, each = 4), time=0, conc=0, tss.constant=0.9)
  expect_warning(pk.tss.monoexponential.population(data = bad_data, output = "population", verbose = TRUE),
                 regexp = "No population model for monoexponential Tss converged, no results given")
})

test_that("pk.tss.stepwise.linear's Wald interval equals the profile interval of confint()", {
  # Before R 4.4, confint() on a glm needs MASS (a recommended package, so
  # usually installed); the Wald interval does not, and for this Gaussian
  # identity-link model the two are the same
  if (getRversion() < "4.4") {
    skip_if_not_installed("MASS")
  }
  tmpdata <- generate.data()
  for (start_time in 0:10) {
    current_data <- tmpdata[tmpdata$time >= start_time, ]
    fit <- stats::glm(conc ~ time + treatment, data = current_data)
    for (level in c(0.9, 0.95, 0.99)) {
      expected <- as.vector(suppressMessages(stats::confint(fit, "time", level = level)))
      interval <-
        pk.tss.stepwise.linear_interval(
          modeldata = current_data[, c("conc", "time", "treatment")],
          formula.to.fit = conc ~ time + treatment,
          level = level
        )
      expect_equal(interval[c(1, 3)], expected, tolerance = 1e-10)
      expect_equal(interval[2], unname(stats::coef(fit)[["time"]]))
    }
  }
})

test_that("pk.tss.stepwise.linear warns when model failures may explain no steady state", {
  tmpdata <- generate.data()
  local_mocked_bindings(
    pk.tss.stepwise.linear_interval = function(...) stop("the model did not converge")
  )
  expect_warning(
    res <-
      pk.tss.stepwise.linear(
        conc = tmpdata$conc, time = tmpdata$time, treatment = tmpdata$treatment,
        time.dosing = 0:14, verbose = FALSE
      ),
    regexp = "from time 0: the model did not converge",
    class = "pknca_warning_tss_stepwise_fit_failed"
  )
  expect_equal(res, data.frame(tss.stepwise.linear = NA_real_), ignore_attr = "estimates")
})

test_that("pk.tss.stepwise.linear does not warn for failures when steady state is found", {
  # The early start times of the mixed-effects model do not converge with
  # these data, and the later ones find steady state
  tmpdata <- generate.data()
  expect_no_warning(
    res <-
      pk.tss.stepwise.linear(
        conc = tmpdata$conc, time = tmpdata$time, subject = tmpdata$subject,
        treatment = tmpdata$treatment, time.dosing = 0:14, verbose = FALSE
      )
  )
  expect_equal(res, data.frame(tss.stepwise.linear = 7), ignore_attr = "estimates")
})

# Single-estimate path, warnings, and NA meanings ####

test_that("nca.reporter's per-treatment estimates: population and stepwise for each treatment", {
  d <- tss_test_theoph()
  ret <- list()
  for (trt in c("A", "B")) {
    d_trt <- d[d$treatment == trt, ]
    args <-
      list(
        conc = d_trt$conc, time = d_trt$time, subject = d_trt$Subject,
        subject.dosing = rep(unique(d_trt$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 6)
      )
    fit_mono <- suppressWarnings(do.call(pk.tss, c(args, list(type = "monoexponential", output = "population"))))
    fit_step <- suppressWarnings(do.call(pk.tss, c(args, list(type = "stepwise.linear"))))
    ret[[trt]] <-
      c(unique(fit_mono$tss.monoexponential.population), unique(fit_step$tss.stepwise.linear))
  }
  expect_equal(ret$A, c(27.0640998681, NA), tolerance = 1e-8)
  expect_equal(ret$B, c(25.9513099761, 60), tolerance = 1e-8)
})

test_that("only the selected population model's nlme warnings are given, as one classed warning", {
  d <- tss_test_theoph()
  d_a <- d[d$treatment == "A", ]
  fit_a <-
    tss_test_with_warnings(
      pk.tss(
        conc = d_a$conc, time = d_a$time, subject = d_a$Subject,
        subject.dosing = rep(unique(d_a$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 6),
        type = "monoexponential", output = "population"
      )
    )
  # A Tss random effect is selected, so there is one row per subject
  expect_equal(
    fit_a$value,
    data.frame(subject = factor(as.character(1:6)), tss.monoexponential.population = 27.0640998681),
    tolerance = 1e-8,
    ignore_attr = "estimates"
  )
  # The selected model warned (in an inner step of an outer loop that
  # converged)
  expect_equal(
    vapply(fit_a$warnings, conditionMessage, ""),
    paste(
      "The selected population model for monoexponential Tss",
      "(Fixed effects of Single Ctrough.ss and Single value for Tss; random effects of Ctrough.ss and Tss)",
      "gave warnings while fitting:",
      "Iteration 1, LME step: nlminb() did not converge (code = 1). Do increase 'msMaxIter'!"
    )
  )
  expect_equal(tss_test_warning_classes(fit_a), "pknca_warning_tss_population_fit_warning")

  d_b <- d[d$treatment == "B", ]
  fit_b <-
    tss_test_with_warnings(
      pk.tss(
        conc = d_b$conc, time = d_b$time, subject = d_b$Subject,
        subject.dosing = rep(unique(d_b$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 6),
        type = "monoexponential", output = "population"
      )
    )
  # No Tss random effect is selected, and there is still one row per subject
  expect_equal(
    fit_b$value,
    data.frame(subject = factor(as.character(c(10:12, 7:9))), tss.monoexponential.population = 25.9513099761),
    tolerance = 1e-8,
    ignore_attr = "estimates"
  )
  # Only a candidate that is not selected warned (see the next test); its
  # warnings do not bear on the estimate, so none is given
  expect_length(fit_b$warnings, 0)
})

test_that("nlme warns for candidate population models that are not selected", {
  # Treatment A: the selected candidate (lowest AIC) is the one that warns
  expect_equal(
    tss_test_candidates("A"),
    data.frame(
      ranef = c("Ctrough.ss and Tss", "Tss", "Ctrough.ss"),
      AIC = c(235.918109899, 365.855715464, 237.871937182),
      tss = c(27.0640998681, 337.7406623001, 32.4765305943),
      n_warnings = c(1L, 0L, 0L)
    ),
    tolerance = 1e-8
  )
  # Treatment B: only a candidate that is not selected warns
  expect_equal(
    tss_test_candidates("B"),
    data.frame(
      ranef = c("Ctrough.ss and Tss", "Tss", "Ctrough.ss"),
      AIC = c(170.254924939, 331.967162491, 166.466076310),
      tss = c(26.3881365002, 86.8843944195, 25.9513099761),
      n_warnings = c(2L, 0L, 0L)
    ),
    tolerance = 1e-8
  )
})

test_that("one call with two treatments gives the population value with each subject's treatment", {
  d <- tss_test_theoph()
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$Subject, treatment = d$treatment,
        subject.dosing = rep(unique(d$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 12),
        type = "monoexponential", output = "population"
      )
    )
  # The selected model has one Tss for both treatments
  expect_equal(
    fit,
    data.frame(
      subject = factor(as.character(c(1, 10:12, 2:9))),
      treatment = factor(c("A", "B", "B", "B", "A", "A", "A", "A", "A", "B", "B", "B")),
      tss.monoexponential.population = 26.416445513
    ),
    tolerance = 1e-8,
    ignore_attr = "estimates"
  )
})

test_that("the single output per treatment fits each treatment and joins the population rows of the treatment", {
  d <- tss_test_theoph()
  args <-
    list(
      conc = d$conc, time = d$time, subject = d$Subject,
      subject.dosing = rep(unique(d$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 12),
      type = "monoexponential"
    )
  fit <-
    suppressWarnings(do.call(pk.tss, c(args, list(treatment = d$treatment, output = c("population", "single")))))
  # Each subject is in its own treatment only:  the single rows join the
  # population rows by treatment, so a subject is not paired with another
  # treatment's estimate
  expect_equal(
    fit,
    data.frame(
      treatment = factor(rep(c("A", "B"), each = 6)),
      subject = factor(as.character(c(1, 3:5, 2, 6, 10:12, 7:9)), levels = as.character(c(1, 10:12, 2:9))),
      tss.monoexponential.population = 26.416445513,
      tss.monoexponential.single = rep(c(29.5184173115, 26.1732211957), each = 6)
    ),
    tolerance = 1e-8,
    ignore_attr = "estimates"
  )
  # ... which are the fits of each treatment alone (the fit of all the data is
  # 27.87592)
  for (trt in c("A", "B")) {
    d_trt <- d[d$treatment == trt, ]
    fit_trt <-
      suppressWarnings(
        pk.tss(
          conc = d_trt$conc, time = d_trt$time, subject = d_trt$Subject, time.dosing = tss_test_dose_times(),
          type = "monoexponential", output = "single"
        )
      )
    expect_equal(
      fit_trt$tss.monoexponential.single,
      unique(fit$tss.monoexponential.single[fit$treatment == trt]),
      tolerance = 1e-6
    )
  }
  fit_no_treatment <- suppressWarnings(do.call(pk.tss, c(args, list(output = "single"))))
  expect_equal(fit_no_treatment, data.frame(tss.monoexponential.single = 27.87592), tolerance = 1e-6, ignore_attr = "estimates")
})

test_that("the stepwise estimate, common to the treatments, repeats on every monoexponential row", {
  d <- tss_test_theoph()
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$Subject, treatment = d$treatment,
        subject.dosing = rep(unique(d$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 12),
        type = c("monoexponential", "stepwise.linear"), output = "population"
      )
    )
  expect_equal(
    fit,
    data.frame(
      subject = factor(as.character(c(1, 10:12, 2:9))),
      treatment = factor(c("A", "B", "B", "B", "A", "A", "A", "A", "A", "B", "B", "B")),
      tss.monoexponential.population = 26.416445513,
      tss.stepwise.linear = 108
    ),
    tolerance = 1e-8,
    ignore_attr = "estimates"
  )
})

test_that("stepwise with too few troughs returns a data frame with NA", {
  d <- tss_test_theoph()
  keep <- d$time %in% c(0, 12)
  expect_warning(
    fit_step <-
      pk.tss(conc = d$conc[keep], time = d$time[keep], subject = d$Subject[keep], time.dosing = c(0, 12), type = "stepwise.linear"),
    class = "pknca_warning_tss_insufficient_data"
  )
  # A data frame with the estimate's column, so that pk.tss() merges it as
  # that column
  expect_equal(fit_step, data.frame(tss.stepwise.linear = NA_real_), ignore_attr = "estimates")
  fit_both <-
    suppressWarnings(
      pk.tss(
        conc = d$conc[keep], time = d$time[keep], subject = d$Subject[keep], time.dosing = c(0, 12),
        type = c("monoexponential", "stepwise.linear"), output = "single"
      )
    )
  expect_equal(fit_both, data.frame(tss.monoexponential.single = NA_real_, tss.stepwise.linear = NA_real_), ignore_attr = "estimates")
})

test_that("a treatment column with one level is dropped from the result", {
  d <- tss_test_theoph()
  d_a <- d[d$treatment == "A", ]
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d_a$conc, time = d_a$time, subject = d_a$Subject, treatment = d_a$treatment,
        time.dosing = tss_test_dose_times(), type = "monoexponential", output = c("population", "single")
      )
    )
  expect_equal(
    fit,
    data.frame(
      subject = factor(as.character(1:6)),
      tss.monoexponential.population = 27.06413,
      tss.monoexponential.single = 29.51842
    ),
    tolerance = 1e-6,
    ignore_attr = "estimates"
  )
})

test_that("when the Tss-by-treatment model is selected, each treatment has its own population Tss", {
  # The model with a Tss by treatment has no coefficient named "tss":  each
  # treatment's Tss is its own coefficient
  d <- tss_test_two_tss()
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$subject, treatment = d$treatment,
        time.dosing = 0:30, type = "monoexponential", output = c("population", "popind")
      )
    )
  # The true Tss are 5 and 15; the individual estimates add the subject's
  # random effect to the Tss of its treatment
  expect_equal(
    fit,
    data.frame(
      subject = factor(1:10),
      treatment = factor(rep(c("A", "B"), each = 5)),
      tss.monoexponential.population = rep(c(4.55515409582, 13.65350210893), each = 5),
      tss.monoexponential.popind =
        c(
          5.90625086071, 4.40940947938, 3.99206337780, 4.61448083346, 3.85356592774,
          14.21690725051, 14.06000708786, 10.32522534867, 15.47027499399, 14.19509586364
        )
    ),
    tolerance = 1e-8,
    ignore_attr = "estimates"
  )
})

test_that("when the troughs are still rising, monoexponential gives an extrapolated estimate with no flag", {
  d <- tss_test_rising()
  fit <-
    tss_test_with_warnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$subject, time.dosing = 0:14,
        type = c("monoexponential", "stepwise.linear"), output = c("population", "single")
      )
    )
  # The last trough is at 14; both monoexponential estimates are past it
  expect_equal(
    fit$value,
    data.frame(
      subject = factor(1:8),
      tss.monoexponential.population = 54.7548037064,
      tss.monoexponential.single = 56.2803272907,
      tss.stepwise.linear = NA_real_
    ),
    tolerance = 1e-8,
    ignore_attr = "estimates"
  )
  # The nlme warning came from a candidate population model that is not
  # selected, so it is not given
  expect_equal(tss_test_warning_classes(fit), "pknca_warning_tss_stepwise_fit_failed")
})

test_that("a failed single fit is NA with a classed warning that names the fit, and prints nothing", {
  # All the troughs are zero, so gnls cannot estimate the curve
  expect_silent(
    expect_warning(
      fit <-
        pk.tss(conc = c(0, 0, 0, 0), time = 0:3, subject = rep(1, 4), time.dosing = 0:3, type = "monoexponential", output = "single"),
      regexp = "A monoexponential gnls fit for Tss failed, so its estimate is NA:\nsingle: approximate covariance matrix for parameter estimates not of full rank",
      fixed = TRUE,
      class = "pknca_warning_tss_individual_fit_failed"
    )
  )
  expect_equal(fit, data.frame(tss.monoexponential.single = NA_real_), ignore_attr = "estimates")
})

test_that("a group with fewer than three troughs is not fit and has insufficient data, like one subject", {
  # Subject 2 has two troughs, too few for the two parameters of the curve and
  # its residual error
  d <- tss_test_theoph()
  d <- d[d$treatment == "A" & (d$Subject != "2" | d$time %in% c(0, 12)), ]
  expect_warning(
    fit <-
      pk.tss(
        conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(),
        type = "monoexponential", output = "individual"
      ),
    regexp =
      paste0(
        "Too few troughs for a monoexponential gnls fit for Tss, so its estimate is NA:\n",
        "individual (subject 2): 2 trough(s), fewer than the 3 needed for the two parameters of the monoexponential curve and its residual error"
      ),
    fixed = TRUE,
    class = "pknca_warning_tss_insufficient_data"
  )
  expect_equal(is.na(fit$tss.monoexponential.individual), as.character(fit$subject) == "2")
  est <- tss_test_check_estimates(fit)
  expect_equal(est$status[est$subject == "2"], "insufficient_data")
  expect_equal(unique(est$status[est$subject != "2"]), "estimated")
  # A single fit with two troughs
  expect_warning(
    fit <-
      pk.tss(conc = c(0, 1000), time = 0:1, subject = c(1, 1), time.dosing = 0:1, type = "monoexponential", output = "single"),
    regexp = "single: 2 trough(s), fewer than the 3 needed",
    fixed = TRUE,
    class = "pknca_warning_tss_insufficient_data"
  )
  expect_equal(attr(fit, "estimates")$status, "insufficient_data")
})

test_that("the warnings of a gnls fit that gives an estimate are one classed warning", {
  local_mocked_bindings(
    tss_try_gnls = function(data, verbose, collector) {
      tss_collect_warnings(
        {
          warning("a gnls warning")
          nlme::gnls(
            conc ~ ctrough.ss * (1 - exp(tss.constant * time / tss)),
            params = list(ctrough.ss ~ 1, tss ~ 1),
            start = c(mean(data$conc), stats::median(unique(data$time))),
            data = data
          )
        },
        collector
      )
    }
  )
  d <- tss_test_theoph()
  d <- d[d$Subject %in% "1", ]
  expect_warning(
    fit <-
      pk.tss(
        conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(),
        type = "monoexponential", output = "single"
      ),
    regexp = "A monoexponential gnls fit for Tss gave warnings while fitting:\nsingle: a gnls warning",
    fixed = TRUE,
    class = "pknca_warning_tss_individual_fit_warning"
  )
  expect_false(is.na(fit$tss.monoexponential.single))
})

test_that("stepwise NA when every start time fails to fit looks like steady state not reached", {
  d <- tss_test_linear_rise()
  expect_warning(
    fit <- pk.tss(conc = d$conc, time = d$time, subject = d$subject, time.dosing = 0:14, type = "stepwise.linear"),
    class = "pknca_warning_tss_stepwise_fit_failed"
  )
  expect_equal(fit, data.frame(tss.stepwise.linear = NA_real_), ignore_attr = "estimates")
})

# Repeated records ####

test_that("repeated subject-time records are an error", {
  d <- tss_test_theoph()
  plasma <- d[d$treatment == "A", ]
  blood <- plasma
  blood$conc <- blood$conc * 0.4
  both <- rbind(plasma, blood)
  fit_plasma <-
    suppressWarnings(
      pk.tss(
        conc = plasma$conc, time = plasma$time, subject = plasma$Subject, time.dosing = tss_test_dose_times(),
        type = c("monoexponential", "stepwise.linear"), output = "population"
      )
    )
  expect_equal(unique(fit_plasma$tss.monoexponential.population), 27.06413, tolerance = 1e-6)
  expect_equal(unique(fit_plasma$tss.stepwise.linear), NA_real_)
  # Plasma and blood rows that no group separates would give one estimate from
  # both matrices (31.6 and 84 here, where plasma alone gives 27.1 and NA), so
  # they are refused
  err <-
    expect_error(
      pk.tss(
        conc = both$conc, time = both$time, subject = both$Subject, time.dosing = tss_test_dose_times(),
        type = c("monoexponential", "stepwise.linear"), output = "population"
      ),
      regexp =
        sprintf(
          "Rows that are not unique per group and time (column names: subject, time) found within time to steady-state concentration data.  Row numbers: %d, %d,",
          nrow(plasma) + 1L, nrow(plasma) + 2L
        ),
      fixed = TRUE,
      class = "pknca_error_tss_duplicate_rows"
    )
  expect_s3_class(err, "pknca_error_duplicate_rows")
  expect_equal(err$rows, nrow(plasma) + seq_len(nrow(plasma)))
  # The check is part of `check`
  expect_equal(
    nrow(pk.tss.data.prep(conc = both$conc, time = both$time, subject = both$Subject, time.dosing = 0, check = FALSE)),
    12L
  )
})

test_that("every record is checked for repeats, before cleaning and trough selection", {
  # At a time that is not a dose time, and with a missing concentration
  expect_error(
    pk.tss.data.prep(conc = c(1, 2, 3, 4), time = c(0, 0.5, 0.5, 1), subject = 1, time.dosing = 0:1),
    regexp = "Row numbers: 3",
    class = "pknca_error_tss_duplicate_rows"
  )
  expect_error(
    pk.tss.data.prep(conc = c(1, 2, NA, 4), time = c(0, 1, 1, 2), subject = 1, time.dosing = 0:2),
    regexp = "Row numbers: 3",
    class = "pknca_error_tss_duplicate_rows"
  )
})

test_that("a missing subject or treatment is an error, not a repeated record", {
  # Two missing subjects at one time would otherwise look like a repeat
  expect_error(
    pk.tss.data.prep(conc = c(1, 2, 3, 4), time = c(0, 0, 1, 1), subject = c(NA, NA, 1, 1), time.dosing = 0:1),
    regexp = "subject may not contain any NA values",
    class = "pknca_error_tss_subject_na"
  )
  expect_error(
    pk.tss.data.prep(
      conc = c(1, 2, 3, 4), time = c(0, 0, 1, 1), subject = c(1, 1, 1, 1), treatment = c(NA, NA, "A", "A"),
      time.dosing = 0:1
    ),
    regexp = "treatment may not contain any NA values",
    class = "pknca_error_tss_treatment_na"
  )
  # A missing time is the assertion of the times
  expect_error(
    pk.tss.data.prep(conc = c(1, 2), time = c(NA, NA), subject = c(1, 1), time.dosing = 0),
    regexp = "Assertion on 'time' failed: Contains missing values"
  )
})

test_that("repeated subject-time records are allowed when the treatment tells them apart", {
  # A crossover with times relative to each period
  expect_equal(
    pk.tss.data.prep(
      conc = c(1, 2, 3, 4), time = c(0, 1, 0, 1), subject = c(1, 1, 1, 1), treatment = c("A", "A", "B", "B"),
      time.dosing = 0:1
    ),
    data.frame(conc = c(1, 2, 3, 4), time = c(0, 1, 0, 1), treatment = factor(c("A", "A", "B", "B")))
  )
  expect_error(
    pk.tss.data.prep(
      conc = c(1, 2, 3, 4), time = c(0, 1, 0, 1), subject = c(1, 1, 1, 1), treatment = c("A", "A", "A", "B"),
      time.dosing = 0:1
    ),
    regexp = "(column names: subject, treatment, time) found within time to steady-state concentration data.  Row numbers: 3",
    fixed = TRUE,
    class = "pknca_error_tss_duplicate_rows"
  )
})

test_that("without subject, repeated times are an untyped error without treatment and accepted with it", {
  err <-
    expect_error(
      pk.tss(conc = c(1, 2, 2, 3, 3), time = c(0, 1, 1, 2, 2), time.dosing = 0:2, type = "stepwise.linear"),
      regexp = "Contains duplicated values"
    )
  expect_false(any(grepl("^pknca_", class(err))))
  # Pooled data with a treatment and no subject repeat times legitimately
  expect_equal(
    pk.tss.data.prep(conc = c(1, 2, 2, 3), time = c(0, 0, 1, 1), treatment = c("A", "B", "A", "B"), time.dosing = 0:1),
    data.frame(conc = c(1, 2, 2, 3), time = c(0, 0, 1, 1), treatment = factor(c("A", "B", "A", "B")))
  )
})

test_that("a repeated dose record selects its trough once", {
  d <- tss_test_theoph()
  d_a <- d[d$treatment == "A", ]
  once <-
    pk.tss.data.prep(
      conc = d_a$conc, time = d_a$time, subject = d_a$Subject,
      subject.dosing = rep(unique(d_a$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 6)
    )
  twice <-
    pk.tss.data.prep(
      conc = d_a$conc, time = d_a$time, subject = d_a$Subject,
      subject.dosing = rep(unique(d_a$Subject), each = 28), time.dosing = rep(rep(tss_test_dose_times(), each = 2), 6)
    )
  expect_equal(nrow(once), 84L)
  expect_equal(twice, once)
})

# The "estimates" attribute ####

test_that("the estimates attribute is on every return path and agrees with the result", {
  tmpdata <- generate.data()
  args_trt <-
    list(conc = tmpdata$conc, time = tmpdata$time, subject = tmpdata$subject, treatment = tmpdata$treatment, time.dosing = 0:14)
  args_no_trt <- args_trt[names(args_trt) != "treatment"]
  for (current_output in c("population", "popind", "individual", "single")) {
    for (args in list(args_trt, args_no_trt)) {
      fit <- suppressWarnings(do.call(pk.tss, c(args, list(type = "monoexponential", output = current_output))))
      est <- tss_test_check_estimates(fit)
      expect_equal(unique(est$output), current_output)
    }
  }
  # Every output at once, and both types
  est <- tss_test_check_estimates(suppressWarnings(do.call(pk.tss, args_trt)))
  expect_equal(unique(est$output), c("population", "popind", "single", "individual", NA))
  expect_equal(unique(est$type), c("monoexponential", "stepwise.linear"))
  # The methods called directly
  tss_test_check_estimates(suppressWarnings(do.call(pk.tss.monoexponential, args_trt)))
  est <- tss_test_check_estimates(do.call(pk.tss.stepwise.linear, args_trt))
  expect_equal(
    est,
    data.frame(
      type = "stepwise.linear", output = NA_character_, treatment = NA_character_, subject = NA_character_,
      estimate = 7, lower = NA_real_, upper = NA_real_, level = 0.95, status = "estimated", fit_warning = NA_character_,
      message = "No confidence interval: the estimate is the first dose time of a sequence of tests, which has no derived sampling distribution"
    )
  )
})

test_that("the estimates attribute says when steady state is not reached and when a fit failed", {
  d <- tss_test_rising()
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$subject, time.dosing = 0:14,
        type = c("monoexponential", "stepwise.linear"), output = c("population", "single")
      )
    )
  est <- tss_test_check_estimates(fit)
  expect_equal(est$status, c("not_reached", "not_reached", "fit_failed"))
  expect_equal(est$estimate, c(54.7548037064, 56.2803272907, NA), tolerance = 1e-8)
  # The population interval is reported for an estimate that is not reached
  expect_equal(est$lower, c(46.436731877, NA, NA), tolerance = 1e-8)
  expect_equal(est$upper, c(63.0728755358, NA, NA), tolerance = 1e-8)
  expect_equal(
    est$message[1:2],
    c(
      "The estimate is later than the last trough (time 14), so steady state was not observed",
      paste(
        "The estimate is later than the last trough (time 14), so steady state was not observed;",
        "No confidence interval: the troughs of several subjects are pooled, and the troughs of a subject are correlated"
      )
    )
  )
  expect_match(
    est$message[3],
    "^Steady state was not found, and the stepwise linear model could not be fit for 8 start time\\(s\\), which were skipped:\nfrom time 0: "
  )

  # A gnls fit that failed
  fit <-
    suppressWarnings(
      pk.tss(conc = c(0, 0, 0, 0), time = 0:3, subject = rep(1, 4), time.dosing = 0:3, type = "monoexponential", output = "single")
    )
  expect_equal(
    tss_test_check_estimates(fit),
    data.frame(
      type = "monoexponential", output = "single", treatment = NA_character_, subject = NA_character_,
      estimate = NA_real_, lower = NA_real_, upper = NA_real_, level = 0.95, status = "fit_failed", fit_warning = NA_character_,
      message = "approximate covariance matrix for parameter estimates not of full rank"
    )
  )

  # No population model converges
  bad_data <- data.frame(subject = factor(rep(1:2, each = 4)), time = 0, conc = 0, tss.constant = 0.9)
  expect_warning(
    fit <- pk.tss.monoexponential.population(data = bad_data, output = c("population", "popind")),
    class = "pknca_warning_tss_population_no_convergence"
  )
  expect_equal(
    tss_test_check_estimates(fit),
    data.frame(
      type = "monoexponential", output = c("population", "popind", "popind"),
      treatment = NA_character_, subject = c(NA, "1", "2"),
      estimate = NA_real_, lower = NA_real_, upper = NA_real_, level = 0.95, status = "fit_failed", fit_warning = NA_character_,
      message = "No population model for monoexponential Tss converged, no results given"
    )
  )
})

test_that("the estimates attribute of stepwise linear separates not reached, too few troughs, and failed fits", {
  # Without subjects, the linear model fits from every start time, and the
  # slope stays significant
  d <- tss_test_linear_rise()
  expect_no_warning(
    fit <- pk.tss(conc = d$conc, time = d$time, treatment = rep("A", nrow(d)), time.dosing = 0:14, type = "stepwise.linear")
  )
  expect_equal(
    tss_test_check_estimates(fit),
    data.frame(
      type = "stepwise.linear", output = NA_character_, treatment = NA_character_, subject = NA_character_,
      estimate = NA_real_, lower = NA_real_, upper = NA_real_, level = 0.95, status = "not_reached", fit_warning = NA_character_,
      message = "The slope of the troughs is significant from every start time, so steady state was not observed"
    )
  )
  # With subjects, every mixed-effects fit fails
  fit <- suppressWarnings(pk.tss(conc = d$conc, time = d$time, subject = d$subject, time.dosing = 0:14, type = "stepwise.linear"))
  expect_equal(tss_test_check_estimates(fit)$status, "fit_failed")
  # Too few troughs
  fit <- suppressWarnings(pk.tss(conc = d$conc, time = d$time, subject = d$subject, time.dosing = 0:1, type = "stepwise.linear"))
  expect_equal(
    tss_test_check_estimates(fit),
    data.frame(
      type = "stepwise.linear", output = NA_character_, treatment = NA_character_, subject = NA_character_,
      estimate = NA_real_, lower = NA_real_, upper = NA_real_, level = 0.95, status = "insufficient_data", fit_warning = NA_character_,
      message = "After removing non-dosing time points, insufficient data remains for tss calculation (fewer than 3 dose times)"
    )
  )
})

test_that("the estimates attribute gives the selected model's warnings and the reason popind is missing", {
  d <- tss_test_theoph()
  d_a <- d[d$treatment == "A", ]
  fit_a <-
    suppressWarnings(
      pk.tss(conc = d_a$conc, time = d_a$time, subject = d_a$Subject, time.dosing = tss_test_dose_times(), type = "monoexponential", output = "population")
    )
  expect_equal(
    tss_test_check_estimates(fit_a),
    data.frame(
      type = "monoexponential", output = "population", treatment = NA_character_, subject = NA_character_,
      estimate = 27.06413, lower = 19.4642037164, upper = 34.6640579272, level = 0.95, status = "estimated",
      fit_warning = "Iteration 1, LME step: nlminb() did not converge (code = 1). Do increase 'msMaxIter'!",
      message = NA_character_
    ),
    tolerance = 1e-6
  )
  d_b <- d[d$treatment == "B", ]
  expect_warning(
    fit_b <-
      pk.tss(conc = d_b$conc, time = d_b$time, subject = d_b$Subject, time.dosing = tss_test_dose_times(), type = "monoexponential", output = c("population", "popind")),
    class = "pknca_warning_tss_popind_no_random_effect"
  )
  est_b <- tss_test_check_estimates(fit_b)
  expect_equal(est_b$output, c("population", rep("popind", 6)))
  expect_equal(est_b$status, c("estimated", rep("no_random_effect", 6)))
  expect_equal(est_b$fit_warning, rep(NA_character_, 7))
  expect_equal(
    est_b$message,
    c(NA, rep("The selected population model has no random effect on Tss, so there are no individual estimates", 6))
  )
})

test_that("the estimates attribute has one population row per treatment when the model has a Tss by treatment", {
  d <- tss_test_two_tss()
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$subject, treatment = d$treatment,
        time.dosing = 0:30, type = "monoexponential", output = "population"
      )
    )
  expect_equal(
    tss_test_check_estimates(fit),
    data.frame(
      type = "monoexponential", output = "population", treatment = c("A", "B"), subject = NA_character_,
      estimate = c(4.55515409582, 13.65350210893),
      lower = c(3.24165300657, 12.30140056707), upper = c(5.86865518507, 15.00560365080), level = 0.95,
      status = "estimated", fit_warning = NA_character_,
      message = NA_character_
    ),
    tolerance = 1e-8
  )
})

# Confidence intervals ####

test_that("the population interval is the Wald interval of the selected nlme model's Tss", {
  # Fit the selected model (Tss by treatment, random effects on Ctrough,ss and
  # Tss) and compute the interval from its estimate, standard error, and
  # degrees of freedom
  d <- tss_test_two_tss()
  modeldata <- pk.tss.data.prep(conc = d$conc, time = d$time, subject = d$subject, treatment = d$treatment, time.dosing = 0:30)
  modeldata$tss.constant <- log(0.1)
  model <-
    nlme::nlme(
      conc ~ ctrough.ss * (1 - exp(tss.constant * time / tss)),
      fixed = list(ctrough.ss ~ treatment - 1, tss ~ treatment - 1),
      random = ctrough.ss + tss ~ 1 | subject,
      start = c(tapply(modeldata$conc, modeldata$treatment, mean), rep(stats::median(unique(modeldata$time)), 2)),
      data = modeldata
    )
  name <- c("tss.treatmentA", "tss.treatmentB")
  tss <- unname(nlme::fixef(model)[name])
  # The standard error is from vcov() (the summary() standard errors of a
  # maximum likelihood fit are larger by sqrt(N/(N - p)))
  half_width <- unname(stats::qt(0.95, df = model$fixDF$X[name]) * sqrt(diag(stats::vcov(model))[name]))
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$subject, treatment = d$treatment,
        time.dosing = 0:30, type = "monoexponential", output = "population", level = 0.9
      )
    )
  est <- attr(fit, "estimates")
  expect_equal(est$estimate, tss, tolerance = 1e-6)
  expect_equal(est$lower, tss - half_width, tolerance = 1e-6)
  expect_equal(est$upper, tss + half_width, tolerance = 1e-6)
  expect_equal(est$lower, c(3.45388614086, 12.51987069280), tolerance = 1e-8)
  expect_equal(est$level, c(0.9, 0.9))
})

test_that("the individual interval is the Wald interval of the subject's gnls fit, and single has one only for one subject", {
  d <- tss_test_theoph()
  d_one <- d[d$Subject %in% "1", ]
  modeldata <- pk.tss.data.prep(conc = d_one$conc, time = d_one$time, time.dosing = tss_test_dose_times())
  modeldata$tss.constant <- log(0.1)
  model <-
    nlme::gnls(
      conc ~ ctrough.ss * (1 - exp(tss.constant * time / tss)),
      params = list(ctrough.ss ~ 1, tss ~ 1),
      start = c(mean(modeldata$conc), stats::median(unique(modeldata$time))),
      data = modeldata
    )
  tss <- stats::coef(model)[["tss"]]
  half_width <- stats::qt(0.975, df = nrow(modeldata) - 2) * sqrt(stats::vcov(model)["tss", "tss"])
  # The estimate (40.65) is before the last trough (156)
  expected_one <-
    data.frame(
      type = "monoexponential", output = "single", treatment = NA_character_, subject = NA_character_,
      estimate = tss, lower = tss - half_width, upper = tss + half_width, level = 0.95,
      status = "estimated", fit_warning = NA_character_, message = NA_character_
    )
  # Single with one subject
  fit <- pk.tss(conc = d_one$conc, time = d_one$time, subject = d_one$Subject, time.dosing = tss_test_dose_times(), type = "monoexponential", output = "single")
  expect_equal(attr(fit, "estimates"), expected_one, tolerance = 1e-6)
  # Individual within a group of subjects
  d_a <- d[d$treatment == "A", ]
  fit <- pk.tss(conc = d_a$conc, time = d_a$time, subject = d_a$Subject, time.dosing = tss_test_dose_times(), type = "monoexponential", output = "individual")
  est <- tss_test_check_estimates(fit)
  expected_individual <- expected_one
  expected_individual$output <- "individual"
  expected_individual$subject <- "1"
  expect_equal(est[est$subject == "1", ], expected_individual, tolerance = 1e-6, ignore_attr = "row.names")
  expect_true(all(est$lower < est$estimate & est$estimate < est$upper))

  # The subject counts however it is given:  by position, through pk.tss() or
  # pk.tss.monoexponential()
  fit <- pk.tss(d_one$conc, d_one$time, d_one$Subject, time.dosing = tss_test_dose_times(), type = "monoexponential", output = "single")
  expect_equal(attr(fit, "estimates"), expected_one, tolerance = 1e-6)
  fit <- pk.tss.monoexponential(d_one$conc, d_one$time, d_one$Subject, time.dosing = tss_test_dose_times(), output = "single")
  expect_equal(attr(fit, "estimates"), expected_one, tolerance = 1e-6)
  # (A partial name cannot match subject:  it also matches subject.dosing.)
  expect_error(
    pk.tss.monoexponential(conc = d_one$conc, time = d_one$time, subj = d_one$Subject, time.dosing = tss_test_dose_times(), output = "single"),
    regexp = "matches multiple formal arguments"
  )

  # Single without subject:  the number of subjects is not known
  fit <- pk.tss(conc = d_one$conc, time = d_one$time, time.dosing = tss_test_dose_times(), type = "monoexponential", output = "single")
  expect_equal(attr(fit, "estimates")$estimate, tss, tolerance = 1e-6)
  expect_equal(attr(fit, "estimates")$lower, NA_real_)
  expect_equal(
    attr(fit, "estimates")$message,
    "No confidence interval: without subject, the troughs may come from several subjects, and the troughs of a subject are correlated"
  )
  # Single with several subjects:  pooled
  fit <- pk.tss(conc = d_a$conc, time = d_a$time, subject = d_a$Subject, time.dosing = tss_test_dose_times(), type = "monoexponential", output = "single")
  expect_equal(attr(fit, "estimates")$upper, NA_real_)
  expect_equal(
    attr(fit, "estimates")$message,
    "No confidence interval: the troughs of several subjects are pooled, and the troughs of a subject are correlated"
  )
})

test_that("popind and stepwise linear estimates have no interval, and level goes to both methods", {
  tmpdata <- generate.data()
  fit <-
    suppressWarnings(
      pk.tss(
        conc = tmpdata$conc, time = tmpdata$time, subject = tmpdata$subject, treatment = tmpdata$treatment,
        time.dosing = 0:14, output = "popind", level = 0.8
      )
    )
  est <- tss_test_check_estimates(fit)
  expect_equal(est$type, c(rep("monoexponential", 10), "stepwise.linear"))
  expect_equal(est$status, rep("estimated", 11))
  expect_equal(est$lower, rep(NA_real_, 11))
  expect_equal(est$upper, rep(NA_real_, 11))
  expect_equal(est$level, rep(0.8, 11))
  expect_equal(
    unique(est$message[1:10]),
    "No confidence interval: individual estimates of a mixed-effects model are predictions of random effects, for which nlme gives no standard errors"
  )
  expect_equal(
    est$message[11],
    "No confidence interval: the estimate is the first dose time of a sequence of tests, which has no derived sampling distribution"
  )
  # The level is the level of the stepwise linear test, too
  expect_equal(
    est$estimate[11],
    pk.tss.stepwise.linear(
      conc = tmpdata$conc, time = tmpdata$time, subject = tmpdata$subject, treatment = tmpdata$treatment,
      time.dosing = 0:14, level = 0.8
    )$tss.stepwise.linear
  )
})

test_that("nlme's degrees of freedom for the Tss of the population model count troughs, not subjects", {
  # The numbers in the documentation of the population interval:  troughs,
  # less subjects, less the fixed effects other than the first
  d <- tss_test_theoph()
  d <- d[d$Subject %in% c("1", "2", "3", "4"), ]
  modeldata <- pk.tss.data.prep(conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times())
  modeldata$tss.constant <- log(0.1)
  # nlme warns for an inner step of this fit, which does not change its
  # degrees of freedom
  model <-
    suppressWarnings(
      nlme::nlme(
        conc ~ ctrough.ss * (1 - exp(tss.constant * time / tss)),
        fixed = list(ctrough.ss ~ 1, tss ~ 1), random = ctrough.ss + tss ~ 1 | subject,
        start = c(mean(modeldata$conc), stats::median(unique(modeldata$time))), data = modeldata
      )
    )
  expect_equal(nrow(modeldata), 56L)
  expect_equal(unname(model$fixDF$X[["tss"]]), 56 - 4 - 1)

  d <- tss_test_two_tss()
  modeldata <- pk.tss.data.prep(conc = d$conc, time = d$time, subject = d$subject, treatment = d$treatment, time.dosing = 0:30)
  modeldata$tss.constant <- log(0.1)
  model <-
    nlme::nlme(
      conc ~ ctrough.ss * (1 - exp(tss.constant * time / tss)),
      fixed = list(ctrough.ss ~ treatment - 1, tss ~ treatment - 1),
      random = ctrough.ss + tss ~ 1 | subject,
      start = c(tapply(modeldata$conc, modeldata$treatment, mean), rep(stats::median(unique(modeldata$time)), 2)),
      data = modeldata
    )
  expect_equal(nrow(modeldata), 310L)
  expect_equal(unname(model$fixDF$X[c("tss.treatmentA", "tss.treatmentB")]), rep(310 - 10 - 3, 2))
})

test_that("pk.tss() warns once for more than one level and uses the first for both methods", {
  d <- tss_test_theoph()
  d <- d[d$Subject %in% "1", ]
  fit <-
    tss_test_with_warnings(
      pk.tss(conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(), output = "single", level = c(0.9, 0.8))
    )
  expect_equal(tss_test_warning_classes(fit), "pknca_warning_tss_level_multiple")
  expect_equal(attr(fit$value, "estimates")$level, c(0.9, 0.9))
})

test_that("with verbose, the warnings of each candidate population model are shown with the model", {
  d <- tss_test_theoph()
  d <- d[d$treatment == "B", ]
  # The candidate that warns is not selected, so without verbose its warnings
  # are not given
  utils::capture.output(
    expect_message(
      fit <-
        pk.tss.monoexponential(
          conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(),
          output = "population", verbose = TRUE
        ),
      regexp =
        paste0(
          "Warnings while fitting Fixed effects of Single Ctrough.ss and Single value for Tss; random effects of Ctrough.ss and Tss:\n",
          "Iteration 1, LME step: nlminb() did not converge (code = 1). Do increase 'msMaxIter'!\n",
          "Iteration 2, LME step: nlminb() did not converge (code = 1). Do increase 'msMaxIter'!"
        ),
      fixed = TRUE,
      class = "pknca_message_tss_candidate_warnings"
    )
  )
  expect_equal(attr(fit, "estimates")$fit_warning, NA_character_)
})

test_that("with options(warn = 2), candidates fit despite their warnings, and the selected model's warning is the error", {
  withr::local_options(warn = 2)
  d <- tss_test_theoph()
  # Treatment B:  the candidate that warns is fitted and not selected
  d_b <- d[d$treatment == "B", ]
  fit_b <-
    pk.tss(
      conc = d_b$conc, time = d_b$time, subject = d_b$Subject, time.dosing = tss_test_dose_times(),
      type = "monoexponential", output = "population"
    )
  expect_equal(unique(fit_b$tss.monoexponential.population), 25.95131, tolerance = 1e-6)
  # Treatment A:  the selected model warned, and warn = 2 makes that an error
  d_a <- d[d$treatment == "A", ]
  expect_error(
    pk.tss(
      conc = d_a$conc, time = d_a$time, subject = d_a$Subject, time.dosing = tss_test_dose_times(),
      type = "monoexponential", output = "population"
    ),
    regexp = "The selected population model for monoexponential Tss"
  )
})

test_that("an interval that nlme cannot compute gives a classed warning and says why", {
  local_mocked_bindings(intervals = function(...) stop("no interval here"), .package = "nlme")
  d <- tss_test_theoph()
  d_a <- d[d$treatment == "A", ]
  expect_warning(
    fit <-
      suppressWarnings(
        pk.tss(
          conc = d_a$conc, time = d_a$time, subject = d_a$Subject, time.dosing = tss_test_dose_times(),
          type = "monoexponential", output = "population"
        ),
        classes = "pknca_warning_tss_population_fit_warning"
      ),
    regexp = "The confidence interval of the population Tss could not be computed: no interval here",
    fixed = TRUE,
    class = "pknca_warning_tss_interval_failed"
  )
  est <- attr(fit, "estimates")
  expect_equal(c(est$lower, est$upper), c(NA_real_, NA_real_))
  expect_equal(est$message, "The confidence interval could not be computed: no interval here")

  expect_warning(
    fit <-
      pk.tss(
        conc = d_a$conc, time = d_a$time, subject = d_a$Subject, time.dosing = tss_test_dose_times(),
        type = "monoexponential", output = "individual"
      ),
    regexp = "The confidence interval of a monoexponential gnls fit for Tss could not be computed:\nindividual (subject 1): no interval here\n",
    fixed = TRUE,
    class = "pknca_warning_tss_interval_failed"
  )
  expect_equal(
    unique(attr(fit, "estimates")$message),
    "The confidence interval could not be computed: no interval here"
  )
})

test_that("level is checked, and an interval that cannot be computed says why", {
  d <- tss_test_theoph()
  d <- d[d$Subject %in% "1", ]
  args <- list(conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(), output = "single")
  expect_error(do.call(pk.tss.monoexponential, c(args, list(level = 1))), class = "pknca_error_tss_level_range")
  expect_error(do.call(pk.tss.monoexponential, c(args, list(level = "A"))), regexp = "Must be of type 'number'")
  expect_warning(
    fit <- do.call(pk.tss.monoexponential, c(args, list(level = c(0.9, 0.8)))),
    class = "pknca_warning_tss_level_multiple"
  )
  expect_equal(attr(fit, "estimates")$level, 0.9)
  expect_equal(
    tss_model_interval(structure(list(), class = "gnls"), name = "tss", level = 0.95)[c("lower", "upper")],
    list(lower = NA_real_, upper = NA_real_)
  )
  expect_match(
    tss_model_interval(structure(list(), class = "gnls"), name = "tss", level = 0.95)$message,
    "^The confidence interval could not be computed: "
  )
})

test_that("later data frame operations drop the estimates attribute or keep it unchanged", {
  d <- tss_test_theoph()
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$Subject, treatment = d$treatment,
        time.dosing = tss_test_dose_times(), type = "monoexponential", output = "single"
      )
    )
  est <- attr(fit, "estimates")
  expect_equal(est$treatment, c("A", "B"))
  # Dropped
  expect_null(attr(merge(fit, data.frame(x = 1)), "estimates"))
  expect_null(attr(fit[, "tss.monoexponential.single", drop = FALSE], "estimates"))
  # Kept unchanged, so it still describes the rows that are gone
  expect_identical(attr(fit[fit$treatment == "A", , drop = FALSE], "estimates"), est)
})

test_that("a population, popind, or individual request with one subject is NA with insufficient data", {
  # One subject cannot give these outputs:  the data are valid but too few, so
  # this is a status (as for too few troughs), not an error
  d <- tss_test_theoph()
  d <- d[d$Subject %in% "1", ]
  msg <- "Cannot give 'population', 'popind', or 'individual' output without multiple subjects of data"
  expect_warning(
    fit <-
      pk.tss(
        conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(),
        type = "monoexponential", output = c("population", "popind")
      ),
    regexp = msg, fixed = TRUE,
    class = "pknca_warning_tss_output_no_subjects"
  )
  expect_equal(
    fit,
    data.frame(tss.monoexponential.population = NA_real_, tss.monoexponential.popind = NA_real_),
    ignore_attr = "estimates"
  )
  expect_equal(
    tss_test_check_estimates(fit),
    data.frame(
      type = "monoexponential", output = c("population", "popind"), treatment = NA_character_, subject = NA_character_,
      estimate = NA_real_, lower = NA_real_, upper = NA_real_, level = 0.95,
      status = "insufficient_data", fit_warning = NA_character_, message = msg
    )
  )
  # With stepwise linear, its estimate is still given
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(),
        output = "individual"
      )
    )
  est <- tss_test_check_estimates(fit)
  expect_equal(est$output, c("individual", NA))
  expect_equal(est$status, c("insufficient_data", "estimated"))
  # With single, the outputs that need several subjects are not columns of the
  # result, and the estimates say why they are missing
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(),
        type = "monoexponential", output = c("population", "single")
      )
    )
  expect_named(fit, "tss.monoexponential.single")
  est <- tss_test_check_estimates(fit)
  expect_equal(est$output, c("single", "population"))
  expect_equal(est$status, c("estimated", "insufficient_data"))
})

test_that("several dosed subjects with troughs for only one are NA with insufficient data", {
  # Every subject of treatment A is dosed at each dose time, but only subject 1
  # is sampled at the dose times (the others an hour later), so one subject is
  # left after the troughs are selected
  d <- tss_test_theoph()
  d <- d[d$treatment == "A", ]
  other <- d$Subject != "1"
  d$time[other] <- d$time[other] + 1
  dose_subjects <- unique(d$Subject)
  msg <- "Cannot give 'population', 'popind', or 'individual' output without multiple subjects of data"
  expected_est <-
    data.frame(
      type = "monoexponential", output = "population", treatment = NA_character_, subject = NA_character_,
      estimate = NA_real_, lower = NA_real_, upper = NA_real_, level = 0.95,
      status = "insufficient_data", fit_warning = NA_character_, message = msg
    )
  # With subject.dosing for every subject, and with time.dosing only
  fits <-
    list(
      tss_test_with_warnings(
        pk.tss(
          conc = d$conc, time = d$time, subject = d$Subject,
          subject.dosing = rep(dose_subjects, each = 14),
          time.dosing = rep(tss_test_dose_times(), length(dose_subjects)),
          type = "monoexponential", output = "population"
        )
      ),
      tss_test_with_warnings(
        pk.tss(
          conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(),
          type = "monoexponential", output = "population"
        )
      )
    )
  for (current in fits) {
    expect_equal(tss_test_warning_classes(current), "pknca_warning_tss_output_no_subjects")
    expect_equal(vapply(current$warnings, conditionMessage, ""), msg)
    expect_equal(current$value, data.frame(tss.monoexponential.population = NA_real_), ignore_attr = "estimates")
    expect_equal(tss_test_check_estimates(current$value), expected_est)
  }
  # With both types, stepwise linear is still estimated from subject 1's
  # troughs
  both <-
    tss_test_with_warnings(
      pk.tss(conc = d$conc, time = d$time, subject = d$Subject, time.dosing = tss_test_dose_times(), output = "population")
    )
  expect_equal(tss_test_warning_classes(both), "pknca_warning_tss_output_no_subjects")
  expect_equal(
    both$value,
    data.frame(tss.monoexponential.population = NA_real_, tss.stepwise.linear = 60),
    ignore_attr = "estimates"
  )
  est <- tss_test_check_estimates(both$value)
  expect_equal(est[1, ], expected_est)
  expect_equal(est$type[2], "stepwise.linear")
  expect_equal(est$estimate[2], 60)
  expect_equal(est$status[2], "estimated")
})

# BLQ rules ####


test_that("BLQ rules are applied to each subject's troughs", {
  # Subject 2's zeros are before its own first positive trough, so they are
  # "first" and kept, though subject 1 has positive troughs at those times
  expect_equal(
    pk.tss.data.prep(conc = c(0, 3, 5, 6, 0, 0, 0, 6), time = rep(0:3, 2), subject = rep(1:2, each = 4), time.dosing = 0:3),
    data.frame(conc = c(0, 3, 5, 6, 0, 0, 0, 6), time = rep(0:3, 2), subject = factor(rep(1:2, each = 4)))
  )
  # Subject 2 alone gives the same rows
  expect_equal(
    pk.tss.data.prep(conc = c(0, 0, 0, 6), time = 0:3, subject = rep(2, 4), time.dosing = 0:3),
    data.frame(conc = c(0, 0, 0, 6), time = 0:3)
  )
  # With rules by Tmax, each subject's zeros are classed by its own Tmax (1 for
  # subject 1, 2 for subject 2), whatever the order of the rows
  rule <- list(before.tmax = "drop", after.tmax = "keep")
  conc <- c(0, 6, 0, 0, 0, 6, 0, 0)
  time <- c(0, 1, 2, 3, 0, 2, 3, 1)
  subject <- rep(1:2, each = 4)
  expect_equal(
    pk.tss.data.prep(conc = conc, time = time, subject = subject, time.dosing = 0:3, conc.blq = rule),
    structure(
      data.frame(conc = c(6, 0, 0, 6, 0), time = c(1, 2, 3, 2, 3), subject = factor(c(1, 1, 1, 2, 2))),
      row.names = c(2:4, 6:7)
    )
  )
  idx <- c(5:8, 1:4)
  expect_equal(
    pk.tss.data.prep(conc = conc[idx], time = time[idx], subject = subject[idx], time.dosing = 0:3, conc.blq = rule),
    structure(
      data.frame(conc = c(6, 0, 6, 0, 0), time = c(2, 3, 1, 2, 3), subject = factor(c(2, 2, 1, 1, 1))),
      row.names = c(2:3, 6:8)
    )
  )
})

test_that("BLQ rules are applied to each subject's troughs in each treatment", {
  # A crossover subject:  positive troughs from time 1 with treatment A and
  # from time 3 with treatment B, so B's zeros at times 1 and 2 are "first" in
  # their own profile (the pooled data would make them "middle" and drop them)
  d <-
    data.frame(
      subject = 1, treatment = rep(c("A", "B"), each = 4), time = rep(0:3, 2),
      conc = c(0, 3, 5, 6, 0, 0, 0, 6)
    )
  expect_equal(
    pk.tss.data.prep(conc = d$conc, time = d$time, subject = d$subject, treatment = d$treatment, time.dosing = 0:3),
    data.frame(conc = d$conc, time = d$time, treatment = factor(d$treatment))
  )
  # A zero between two positive troughs of the same profile is still "middle"
  # and dropped
  expect_equal(
    pk.tss.data.prep(
      conc = c(0, 3, 0, 6, 0, 0, 0, 6), time = d$time, subject = d$subject, treatment = d$treatment, time.dosing = 0:3
    ),
    structure(
      data.frame(conc = c(0, 3, 6, 0, 0, 0, 6), time = c(0, 1, 3, 0, 1, 2, 3), treatment = factor(rep(c("A", "B"), c(3, 4)))),
      row.names = c(1:2, 4:8)
    )
  )
})

test_that("BLQ rules are applied to each treatment's troughs without subject, and to all troughs without either", {
  # Without subject, the troughs of a treatment are one profile
  expect_equal(
    pk.tss.data.prep(
      conc = c(0, 3, 5, 6, 0, 0, 0, 6), time = rep(0:3, 2), treatment = rep(c("A", "B"), each = 4), time.dosing = 0:3
    ),
    data.frame(conc = c(0, 3, 5, 6, 0, 0, 0, 6), time = rep(0:3, 2), treatment = factor(rep(c("A", "B"), each = 4)))
  )
  # Without subject or treatment, all the troughs are one profile, as
  # clean.conc.blq() gives them
  expect_equal(
    pk.tss.data.prep(conc = c(0, 3, 0, 6), time = 0:3, time.dosing = 0:3),
    clean.conc.blq(conc = c(0, 3, 0, 6), time = 0:3)
  )
})

test_that("the BLQ rules per profile keep the input order of the rows", {
  # Times out of order within a subject:  the rules see each profile sorted by
  # time, and the rows come back in the order given, named by their positions
  expect_equal(
    pk.tss.data.prep(
      conc = c(6, 0, 3, 0, 0, 5, 0, 6), time = c(3, 2, 1, 0, 0, 2, 1, 3), subject = rep(1:2, each = 4),
      time.dosing = 0:3
    ),
    structure(
      data.frame(conc = c(6, 3, 0, 0, 5, 0, 6), time = c(3, 1, 0, 0, 2, 1, 3), subject = factor(c(1, 1, 1, 2, 2, 2, 2))),
      row.names = c(1L, 3:8)
    )
  )
})

test_that("subject and treatment values that paste to the same label are separate profiles", {
  # Subject "1.A" in treatment "B" and subject "1" in treatment "A.B" would both
  # be "1.A.B":  pooled, the first profile's zero at time 2 would be "middle"
  # and dropped; on its own, it is "first" and kept
  expect_equal(
    pk.tss.data.prep(
      conc = c(0, 0, 0, 6, 0, 3, 5, 6), time = rep(0:3, 2),
      subject = rep(c("1.A", "1"), each = 4), treatment = rep(c("B", "A.B"), each = 4),
      time.dosing = 0:3
    ),
    data.frame(
      conc = c(0, 0, 0, 6, 0, 3, 5, 6), time = rep(0:3, 2),
      subject = factor(rep(c("1.A", "1"), each = 4)), treatment = factor(rep(c("B", "A.B"), each = 4))
    )
  )
  # The same with a numeric subject (1.1 in treatment "2" and 1 in "1.2")
  expect_equal(
    pk.tss.data.prep(
      conc = c(0, 0, 0, 6, 0, 3, 5, 6), time = rep(0:3, 2),
      subject = rep(c(1.1, 1), each = 4), treatment = rep(c("2", "1.2"), each = 4),
      time.dosing = 0:3
    ),
    data.frame(
      conc = c(0, 0, 0, 6, 0, 3, 5, 6), time = rep(0:3, 2),
      subject = factor(rep(c("1.1", "1"), each = 4)), treatment = factor(rep(c("2", "1.2"), each = 4))
    )
  )
})

test_that("BLQ rules per profile with a factor subject and with a profile whose rows are all dropped", {
  # A factor subject is kept as given, with its unused levels; subject 3's
  # concentrations are all missing, so its profile is dropped
  subject <- factor(rep(c("1", "2", "3"), each = 4), levels = c("1", "2", "3", "4"))
  expect_equal(
    pk.tss.data.prep(
      conc = c(0, 3, 5, 6, 0, 0, 0, 6, NA, NA, NA, NA), time = rep(0:3, 3), subject = subject, time.dosing = 0:3
    ),
    data.frame(
      conc = c(0, 3, 5, 6, 0, 0, 0, 6), time = rep(0:3, 2),
      subject = factor(rep(c("1", "2"), each = 4), levels = c("1", "2", "3", "4"))
    )
  )
  # Subject 3's troughs are all BLQ:  dropped with conc.blq = "drop", and kept
  # with the default rules, as clean.conc.blq() gives them for that subject
  # alone
  conc <- c(1, 3, 5, 6, 2, 1, 1, 6, 0, 0, 0, 0)
  expect_equal(
    pk.tss.data.prep(conc = conc, time = rep(0:3, 3), subject = subject, time.dosing = 0:3, conc.blq = "drop"),
    data.frame(conc = conc[1:8], time = rep(0:3, 2), subject = factor(rep(c("1", "2"), each = 4), levels = c("1", "2", "3", "4")))
  )
  expect_equal(
    pk.tss.data.prep(conc = conc, time = rep(0:3, 3), subject = subject, time.dosing = 0:3),
    data.frame(conc = conc, time = rep(0:3, 3), subject = subject)
  )
  expect_equal(clean.conc.blq(conc = c(0, 0, 0, 0), time = 0:3)$time, 0:3)
})

test_that("zero rows of input give zero rows with the columns given", {
  expect_equal(
    pk.tss.data.prep(conc = numeric(0), time = numeric(0), time.dosing = 0:3, check = FALSE),
    data.frame(conc = numeric(0), time = numeric(0))
  )
  expect_equal(
    pk.tss.data.prep(
      conc = numeric(0), time = numeric(0), subject = character(0), treatment = character(0), time.dosing = 0:3,
      check = FALSE
    ),
    data.frame(conc = numeric(0), time = numeric(0), subject = factor(character(0)), treatment = factor(character(0)))
  )
  # With check = TRUE, the empty data are warned about and then give the same
  ret <-
    tss_test_with_warnings(
      pk.tss.data.prep(conc = numeric(0), time = numeric(0), subject = character(0), time.dosing = 0:3)
    )
  expect_equal(
    vapply(ret$warnings, conditionMessage, ""),
    c("No concentration data given", "No time data given")
  )
  expect_equal(ret$value, data.frame(conc = numeric(0), time = numeric(0), subject = factor(character(0))))
  # pk.tss() has insufficient data
  fit <-
    suppressWarnings(
      pk.tss(conc = numeric(0), time = numeric(0), time.dosing = 0:3, type = "stepwise.linear")
    )
  expect_equal(fit, data.frame(tss.stepwise.linear = NA_real_), ignore_attr = "estimates")
  expect_equal(tss_test_check_estimates(fit)$status, "insufficient_data")
})

test_that("with check = FALSE, a missing subject is a value of its own for the BLQ rules", {
  # The rows without a subject (times 1 and 2) are one profile, of zeros only,
  # so they are kept; subjects 1 and 2 have no zero between positive troughs
  expect_equal(
    pk.tss.data.prep(
      conc = c(0, 3, 0, 6, 0, 0, 0, 6), time = rep(0:3, 2), subject = c(1, 1, NA, 1, 2, NA, 2, 2),
      time.dosing = 0:3, check = FALSE
    ),
    data.frame(conc = c(0, 3, 0, 6, 0, 0, 0, 6), time = rep(0:3, 2), subject = factor(c(1, 1, NA, 1, 2, NA, 2, 2)))
  )
  # A missing treatment likewise:  subject 2's rows are one profile
  expect_equal(
    pk.tss.data.prep(
      conc = c(0, 3, 0, 6, 0, 0, 0, 6), time = rep(0:3, 2), subject = rep(1:2, each = 4),
      treatment = rep(c("A", NA), each = 4), time.dosing = 0:3, check = FALSE
    ),
    structure(
      data.frame(
        conc = c(0, 3, 6, 0, 0, 0, 6), time = c(0, 1, 3, 0:3),
        subject = factor(rep(1:2, c(3, 4))), treatment = factor(rep(c("A", NA), c(3, 4)))
      ),
      row.names = c(1:2, 4:8)
    )
  )
})
