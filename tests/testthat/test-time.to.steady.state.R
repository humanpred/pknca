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
    data.frame(tss.stepwise.linear=7)
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
  expect_equal(v1, NA)
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
      info="pk.tss.stepwise.linear no subject"
    )
  )
})

test_that("pk.tss.monoexponential", {
  tmpdata <- generate.data()
  expect_warning(
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
        subject=factor(as.character(c(1, 10, 2:9))),
        tss.monoexponential.population=4.57618156812974,
        tss.monoexponential.popind=c(
          5.14156352865421, 4.64862524830397, 4.45956707917941,
          4.41492203844343, 4.6782583033301, 4.0823047621517,
          4.96242115751172, 4.52424147509819, 3.70338406668837,
          5.1465280219363),
        treatment=
          factor(c("A", "B", "A", "A", "A", "A", "B", "B", "B", "B")),
        tss.monoexponential.individual=c(
          5.87784329336254, 4.71066285661623, 4.51882509145954,
          3.91269286106442, 4.74475071729459, 3.99341726779716,
          5.08737230904342, 4.50068650719192, 3.4876172020751,
          5.35051537086801),
        # Each treatment's own fit
        tss.monoexponential.single=
          c(A=4.49364717175, B=4.59871031113)[c("A", "B", "A", "A", "A", "A", "B", "B", "B", "B")]
      ),
      tolerance=1e-4,
      ignore_attr=TRUE
    )
  )
  expect_output(
    expect_equal(
      pk.tss.monoexponential(
        conc=c(0, 1000),
        time=0:1,
        subject=c(1, 1),
        treatment=c("A", "A"),
        time.dosing=0:1,
        tss.fraction=0.9,
        output="single"
      ),
      data.frame(tss.monoexponential.single=NA_real_),
      info="Single-subject data fitting works when it does not converge."
    ),
    regexp = "approximate covariance matrix for parameter estimates not of full rank"
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
        subject=factor(as.character(c(1, 10, 2:9))),
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
      tolerance=1e-4
    )
})

test_that("pk.tss.monoexponential corner case tests", {
  tmpdata <- generate.data()
  # population output, only
  expect_warning(
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
        subject=factor(as.character(seq_len(10))),
        tss.monoexponential.population=4.57618156812974
      ),
      tolerance=1e-4
    )
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
      subject=factor(as.character(seq_len(10))),
      tss.monoexponential.population=4.56157960341961
    ),
    tolerance=1e-4
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
    tolerance=1e-5
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
      )
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
    tolerance=0.001
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
    tolerance=0.001
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
  expect_equal(res, data.frame(tss.stepwise.linear = NA))
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
  expect_equal(res, data.frame(tss.stepwise.linear = 7))
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

test_that("the selected population model's nlme warning surfaces unclassed, and the population rows depend on the model", {
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
    tolerance = 1e-8
  )
  expect_equal(
    vapply(fit_a$warnings, conditionMessage, ""),
    "Iteration 1, LME step: nlminb() did not converge (code = 1). Do increase 'msMaxIter'!"
  )
  expect_equal(class(fit_a$warnings[[1]]), c("simpleWarning", "warning", "condition"))

  d_b <- d[d$treatment == "B", ]
  fit_b <-
    tss_test_with_warnings(
      pk.tss(
        conc = d_b$conc, time = d_b$time, subject = d_b$Subject,
        subject.dosing = rep(unique(d_b$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 6),
        type = "monoexponential", output = "population"
      )
    )
  # No Tss random effect is selected, so there is one row and no subject
  expect_equal(fit_b$value, data.frame(tss.monoexponential.population = 25.9513099761), tolerance = 1e-8)
  expect_equal(
    vapply(fit_b$warnings, conditionMessage, ""),
    c(
      "Iteration 1, LME step: nlminb() did not converge (code = 1). Do increase 'msMaxIter'!",
      "Iteration 2, LME step: nlminb() did not converge (code = 1). Do increase 'msMaxIter'!"
    )
  )
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

test_that("one call with two treatments gives one population value with no treatment column", {
  d <- tss_test_theoph()
  fit <-
    suppressWarnings(
      pk.tss(
        conc = d$conc, time = d$time, subject = d$Subject, treatment = d$treatment,
        subject.dosing = rep(unique(d$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 12),
        type = "monoexponential", output = "population"
      )
    )
  expect_equal(
    fit,
    data.frame(subject = factor(as.character(c(1, 10:12, 2:9))), tss.monoexponential.population = 26.41645),
    tolerance = 1e-6
  )
})

test_that("the single output per treatment fits each treatment, cross-joined with the population rows", {
  d <- tss_test_theoph()
  args <-
    list(
      conc = d$conc, time = d$time, subject = d$Subject,
      subject.dosing = rep(unique(d$Subject), each = 14), time.dosing = rep(tss_test_dose_times(), 12),
      type = "monoexponential"
    )
  fit <-
    suppressWarnings(do.call(pk.tss, c(args, list(treatment = d$treatment, output = c("population", "single")))))
  expect_equal(nrow(fit), 24L)
  expect_equal(names(fit), c("subject", "tss.monoexponential.population", "treatment", "tss.monoexponential.single"))
  expect_equal(as.character(fit$treatment), rep(c("A", "B"), each = 12))
  # Every subject appears under both treatments
  expect_equal(as.character(fit$subject), rep(as.character(c(1, 10:12, 2:9)), 2))
  expect_equal(fit$tss.monoexponential.single, rep(c(29.5184173115, 26.1732211957), each = 12), tolerance = 1e-8)
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
  expect_equal(fit_no_treatment, data.frame(tss.monoexponential.single = 27.87592), tolerance = 1e-6)
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
      tss.monoexponential.population = 26.41645,
      tss.stepwise.linear = 108
    ),
    tolerance = 1e-6
  )
})

test_that("stepwise with too few troughs returns a bare NA, which pk.tss() merges as column y", {
  d <- tss_test_theoph()
  keep <- d$time %in% c(0, 12)
  expect_warning(
    fit_step <-
      pk.tss(conc = d$conc[keep], time = d$time[keep], subject = d$Subject[keep], time.dosing = c(0, 12), type = "stepwise.linear"),
    class = "pknca_warning_tss_insufficient_data"
  )
  expect_identical(fit_step, NA)
  fit_both <-
    suppressWarnings(
      pk.tss(
        conc = d$conc[keep], time = d$time[keep], subject = d$Subject[keep], time.dosing = c(0, 12),
        type = c("monoexponential", "stepwise.linear"), output = "single"
      )
    )
  expect_equal(fit_both, data.frame(tss.monoexponential.single = NA_real_, y = NA))
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
    tolerance = 1e-6
  )
})

test_that("when the Tss-by-treatment model is selected, pk.tss() stops with an unclassed error", {
  d <- tss_test_two_tss()
  err <-
    expect_error(
      suppressWarnings(
        pk.tss(
          conc = d$conc, time = d$time, subject = d$subject, treatment = d$treatment,
          time.dosing = 0:30, type = "monoexponential", output = "population"
        )
      ),
      regexp = "subscript out of bounds",
      fixed = TRUE
    )
  expect_false(any(grepl("^pknca_", class(err))))
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
      tss.monoexponential.population = 54.7548037064,
      tss.monoexponential.single = 56.2803272907,
      tss.stepwise.linear = NA
    ),
    tolerance = 1e-8
  )
  expect_equal(tss_test_warning_classes(fit), c("simpleWarning", "pknca_warning_tss_stepwise_fit_failed"))
})

test_that("a failed single fit is NA with no warning", {
  expect_no_warning(
    expect_output(
      fit <-
        pk.tss(conc = c(0, 1000), time = 0:1, subject = c(1, 1), time.dosing = 0:1, type = "monoexponential", output = "single"),
      regexp = "approximate covariance matrix for parameter estimates not of full rank"
    )
  )
  expect_equal(fit, data.frame(tss.monoexponential.single = NA_real_))
})

test_that("stepwise NA when every start time fails to fit looks like steady state not reached", {
  d <- tss_test_linear_rise()
  expect_warning(
    fit <- pk.tss(conc = d$conc, time = d$time, subject = d$subject, time.dosing = 0:14, type = "stepwise.linear"),
    class = "pknca_warning_tss_stepwise_fit_failed"
  )
  expect_equal(fit, data.frame(tss.stepwise.linear = NA))
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
  expect_equal(unique(fit_plasma$tss.stepwise.linear), NA)
  # Fitting plasma and blood together gave 31.6 (monoexponential) and 84
  # (stepwise) without complaint
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
