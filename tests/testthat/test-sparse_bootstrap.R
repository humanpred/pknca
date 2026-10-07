# Serial sacrifice:  three animals at each time
d_boot_serial <-
  data.frame(
    time = rep(c(0, 1, 2, 4, 8, 24), each = 3),
    conc = c(0, 0, 0, 5, 6, 4, 8, 7, 9, 6, 5, 7, 3, 2.5, 3.5, 0.6, 0.4, 0.5)
  )
d_boot_serial$animal <- seq_len(nrow(d_boot_serial))

# Batch design:  two batches of three animals, each sampled at three times
d_boot_batch <-
  data.frame(
    animal = rep(1:6, each = 3),
    time = c(rep(c(0, 2, 8), 3), rep(c(1, 4, 24), 3)),
    conc = c(0, 8, 3,  0, 7, 2.5,  0, 9, 3.5,  5, 6, 0.6,  6, 5, 0.4,  4, 7, 0.5)
  )

# Crossover:  each animal receives both treatments at one time
d_boot_crossover <-
  rbind(
    data.frame(d_boot_serial, treatment = "R"),
    data.frame(time = d_boot_serial$time, conc = d_boot_serial$conc*1.1, animal = d_boot_serial$animal, treatment = "T")
  )

test_that("sparse_bootstrap() checks its input", {
  o_dense <- PKNCAconc(d_boot_serial, conc ~ time | animal)
  expect_error(sparse_bootstrap(o_dense), class = "pknca_error_bootstrap_not_sparse")
  o_sparse <- PKNCAconc(d_boot_serial, conc ~ time | animal, sparse = TRUE)
  expect_error(sparse_bootstrap(o_sparse, n_boot = 0), regexp = "n_boot")
  expect_error(sparse_bootstrap(o_sparse, paired = "animal"), regexp = "paired")
  o_boot <- sparse_bootstrap(o_sparse, n_boot = 2, seed = 1)
  expect_error(sparse_bootstrap(o_boot), class = "pknca_error_bootstrap_already")
  d_clash <- d_boot_serial
  d_clash$bootstrap <- 1
  expect_error(
    sparse_bootstrap(PKNCAconc(d_clash, conc ~ time | animal, sparse = TRUE)),
    class = "pknca_error_bootstrap_column_exists"
  )
})

test_that("sparse_bootstrap() keeps the original data and resamples within each time", {
  o_sparse <- PKNCAconc(d_boot_serial, conc ~ time | animal, sparse = TRUE)
  o_boot <- sparse_bootstrap(o_sparse, n_boot = 5, seed = 2)
  d <- o_boot$data_sparse
  expect_equal(unique(d$bootstrap), c("original", paste0("bootstrap", 1:5)))
  expect_equal(o_boot$bootstrap, list(n_boot = 5, seed = 2, paired = NULL, replicate_col = "bootstrap", subject = "animal"))
  expect_equal(o_boot$columns$groups$group_vars, c("bootstrap", "bootstrap_subject"))
  expect_equal(o_boot$columns$subject, "bootstrap_subject")
  expect_true(is_sparse_pk(o_boot))
  # The original data are unchanged
  original <- d[d$bootstrap == "original", ]
  expect_equal(original[, c("time", "conc", "animal")], d_boot_serial, ignore_attr = TRUE)
  for (current in paste0("bootstrap", 1:5)) {
    replicate <- d[d$bootstrap == current, ]
    # Three draws at each time, each from an animal sampled at that time
    expect_equal(as.vector(table(replicate$time)), rep(3, 6))
    expect_equal(replicate$time, d_boot_serial$time[match(replicate$animal, d_boot_serial$animal)])
    expect_equal(replicate$conc, d_boot_serial$conc[match(replicate$animal, d_boot_serial$animal)])
    # A repeated draw is a separate animal
    expect_equal(anyDuplicated(replicate$bootstrap_subject), 0L)
  }
})

test_that("sparse_bootstrap() is reproducible and restores the random number state", {
  o_sparse <- PKNCAconc(d_boot_serial, conc ~ time | animal, sparse = TRUE)
  set.seed(10)
  expected_next <- stats::runif(1)
  set.seed(10)
  o_boot1 <- sparse_bootstrap(o_sparse, n_boot = 3, seed = 5)
  expect_equal(stats::runif(1), expected_next)
  o_boot2 <- sparse_bootstrap(o_sparse, n_boot = 3, seed = 5)
  expect_equal(o_boot1$data_sparse, o_boot2$data_sparse)
  expect_false(identical(o_boot1$data_sparse, sparse_bootstrap(o_sparse, n_boot = 3, seed = 6)$data_sparse))
  # Without a seed, one is drawn from the session and stored
  set.seed(11)
  o_boot_auto <- sparse_bootstrap(o_sparse, n_boot = 3)
  expect_true(is.numeric(o_boot_auto$bootstrap$seed))
  expect_equal(
    o_boot_auto$data_sparse,
    sparse_bootstrap(o_sparse, n_boot = 3, seed = o_boot_auto$bootstrap$seed)$data_sparse
  )
})

test_that("sparse_bootstrap() keeps each animal's samples together in a batch design", {
  o_sparse <- PKNCAconc(d_boot_batch, conc ~ time | animal, sparse = TRUE)
  o_boot <- sparse_bootstrap(o_sparse, n_boot = 10, seed = 3)
  d <- o_boot$data_sparse[o_boot$data_sparse$bootstrap != "original", ]
  for (current_subject in unique(paste(d$bootstrap, d$bootstrap_subject))) {
    rows <- d[paste(d$bootstrap, d$bootstrap_subject) == current_subject, ]
    # All three samples of one animal
    expect_equal(rows$time, d_boot_batch$time[d_boot_batch$animal == rows$animal[1]])
  }
  # Three animals from each batch in every replicate
  for (current in unique(d$bootstrap)) {
    animals <- unique(d$bootstrap_subject[d$bootstrap == current])
    original_animal <- as.integer(sub("_[0-9]+$", "", animals))
    expect_equal(sum(original_animal <= 3), 3)
    expect_equal(sum(original_animal > 3), 3)
  }
})

test_that("sparse_bootstrap() resamples paired groups together and others independently", {
  o_sparse <- PKNCAconc(d_boot_crossover, conc ~ time | treatment + animal, sparse = TRUE)
  paired <- sparse_bootstrap(o_sparse, n_boot = 10, seed = 4, paired = "treatment")
  d <- paired$data_sparse[paired$data_sparse$bootstrap != "original", ]
  # Each drawn animal brings both treatments
  for (current in unique(d$bootstrap)) {
    replicate <- d[d$bootstrap == current, ]
    expect_equal(
      sort(replicate$animal[replicate$treatment == "R"]),
      sort(replicate$animal[replicate$treatment == "T"])
    )
  }
  # Without pairing, the treatments are drawn separately
  independent <- sparse_bootstrap(o_sparse, n_boot = 10, seed = 4)
  d <- independent$data_sparse[independent$data_sparse$bootstrap != "original", ]
  same_draws <- logical()
  for (current in unique(d$bootstrap)) {
    same_draws[current] <-
      identical(
        sort(d$animal[d$bootstrap == current & d$treatment == "R"]),
        sort(d$animal[d$bootstrap == current & d$treatment == "T"])
      )
  }
  expect_false(all(same_draws))
})

test_that("sparse_bootstrap() resamples analytes together", {
  d_analytes <-
    rbind(
      data.frame(d_boot_serial, analyte = "parent"),
      data.frame(time = d_boot_serial$time, conc = d_boot_serial$conc/2, animal = d_boot_serial$animal, analyte = "metabolite")
    )
  o_sparse <- PKNCAconc(d_analytes, conc ~ time | animal/analyte, sparse = TRUE)
  o_boot <- sparse_bootstrap(o_sparse, n_boot = 5, seed = 7)
  expect_equal(o_boot$columns$groups$group_analyte, "analyte")
  d <- o_boot$data_sparse[o_boot$data_sparse$bootstrap != "original", ]
  for (current in unique(d$bootstrap)) {
    replicate <- d[d$bootstrap == current, ]
    expect_equal(
      sort(replicate$bootstrap_subject[replicate$analyte == "parent"]),
      sort(replicate$bootstrap_subject[replicate$analyte == "metabolite"])
    )
  }
})

test_that("sparse_bootstrap_summary() summarizes the replicates", {
  o_sparse <- PKNCAconc(d_boot_serial, conc ~ time | animal, sparse = TRUE)
  o_boot <- sparse_bootstrap(o_sparse, n_boot = 30, seed = 8)
  d_intervals <- data.frame(start = 0, end = 24, auclast = TRUE, cmax = TRUE)
  o_nca_boot <- suppressMessages(pk.nca(PKNCAdata(o_boot, intervals = d_intervals)))
  o_nca <- suppressMessages(pk.nca(PKNCAdata(o_sparse, intervals = d_intervals)))
  result <- sparse_bootstrap_summary(o_nca_boot, conf_level = 0.9)
  expect_equal(result$PPTESTCD, c("cmax", "auclast"))
  # The standard errors of one replicate are not part of the bootstrap
  expect_false(any(c("auclast_se", "auclast_df") %in% result$PPTESTCD))
  values <- as.data.frame(o_nca_boot)
  auclast_boot <- values$PPORRES[values$PPTESTCD == "auclast" & values$bootstrap != "original"]
  expected <- as.data.frame(o_nca)
  row <- result[result$PPTESTCD == "auclast", ]
  expect_equal(row$estimate, expected$PPORRES[expected$PPTESTCD == "auclast"])
  expect_equal(row$n_boot, 30)
  expect_equal(row$n, 30)
  expect_equal(row$mean, mean(auclast_boot))
  expect_equal(row$sd, stats::sd(auclast_boot))
  expect_equal(row$geomean, exp(mean(log(auclast_boot))))
  expect_equal(row$geocv, 100*sqrt(exp(stats::sd(log(auclast_boot))^2) - 1))
  expect_equal(c(row$ci_lower, row$ci_upper), unname(stats::quantile(auclast_boot, c(0.05, 0.95))))
  expect_equal(attr(result, "seed"), 8)
  # Results that are not from a bootstrap are refused
  expect_error(sparse_bootstrap_summary(o_nca), class = "pknca_error_bootstrap_not_bootstrap")
})

test_that("sparse_bootstrap_compare() gives the percentile interval of the ratio", {
  o_sparse <- PKNCAconc(d_boot_crossover, conc ~ time | treatment + animal, sparse = TRUE)
  o_boot <- sparse_bootstrap(o_sparse, n_boot = 40, seed = 9, paired = "treatment")
  d_intervals <- data.frame(start = 0, end = 24, auclast = TRUE, cmax = TRUE)
  o_nca_boot <- suppressMessages(pk.nca(PKNCAdata(o_boot, intervals = d_intervals)))
  result <- sparse_bootstrap_compare(o_nca_boot, reference_col = "treatment", reference_value = "R", parameters = "auclast")
  values <- as.data.frame(o_nca_boot)
  values <- values[values$PPTESTCD == "auclast", ]
  test <- values[values$treatment == "T", ]
  reference <- values[values$treatment == "R", ]
  ratio <- test$PPORRES/reference$PPORRES[match(test$bootstrap, reference$bootstrap)]
  is_original <- test$bootstrap == "original"
  expect_equal(nrow(result), 1)
  expect_equal(result$endpoint, "auclast")
  expect_equal(result$test, "T")
  expect_equal(result$reference, "R")
  expect_equal(result$ratio_percent, 100*ratio[is_original])
  expect_equal(c(result$ci_lower, result$ci_upper), 100*unname(stats::quantile(ratio[!is_original], c(0.05, 0.95))))
  expect_equal(c(result$limit_lower, result$limit_upper), c(80, 125))
  # The test is 1.1 times the reference in every animal, and the animals are
  # drawn together, so every replicate ratio is 1.1 and the products pass
  expect_equal(result$ci_lower, 110)
  expect_equal(result$ci_upper, 110)
  expect_true(result$pass)
  # Narrow limits fail
  narrow <- sparse_bootstrap_compare(o_nca_boot, "treatment", "R", parameters = "auclast", limits = c(90, 105))
  expect_false(narrow$pass)
  expect_error(sparse_bootstrap_compare(o_nca_boot, "treatment", "X"), regexp = "reference_value")
  expect_error(sparse_bootstrap_compare(o_nca_boot, "bootstrap", "original"), regexp = "reference_col")
})
