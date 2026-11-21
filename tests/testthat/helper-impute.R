# Helpers for the imputation tests

# impute_conc_time() for one profile with its per-observation values, as
# pk.nca.interval() calls it, over an interval from 0 to `end`; `conc.group`
# and `time.group` add a predose sample of 5 at `predose_time` to the profile
# when `predose` is TRUE.  `drop_missing_start` is FALSE for a numeric conc.na.
impute_test_obs_chain <- function(impute_funs, conc, time, volume, duration.conc, include_half.life,
                                  exclude_half.life, lloq, predose, predose_time = -0.05, end = 4,
                                  drop_missing_start = TRUE) {
  obs <-
    impute_obs_values(
      time = time, volume = volume, duration.conc = duration.conc,
      include_half.life = include_half.life, exclude_half.life = exclude_half.life, lloq = lloq
    )
  impute_conc_time(
    impute_funs = impute_funs, conc = conc, time = time, start = 0, end = end,
    conc.group = c(if (predose) 5, conc), time.group = c(if (predose) predose_time, time), options = list(),
    drop_missing_start = drop_missing_start,
    obs_values = obs$values, obs_fill = obs$fill
  )
}

# impute_conc_time() for one profile without per-observation values, as
# pk.nca.interval() calls it (with conc.na "drop" unless `drop_missing_start` is
# FALSE); `conc.group` and `time.group` default to the profile itself
impute_test_chain <- function(impute_funs, conc, time, start = 0, end, conc.group = conc, time.group = time,
                              drop_missing_start = TRUE) {
  impute_conc_time(
    impute_funs = impute_funs, conc = conc, time = time, start = start, end = end,
    conc.group = conc.group, time.group = time.group, options = list(),
    drop_missing_start = drop_missing_start
  )
}

# What the imputation method PKNCA_impute_method_test_user_record() last
# received
impute_test_user_seen <- new.env(parent = emptyenv())

# A user's imputation method (not registered) that records its input and
# returns it unchanged; tests assign it into the global environment, where
# PKNCA finds a user's method by name
impute_test_user_record <- function(conc, time, start, ..., options = list()) {
  impute_test_user_seen$conc <- conc
  impute_test_user_seen$time <- time
  data.frame(conc = conc, time = time)
}
