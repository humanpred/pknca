# Helpers for the imputation tests

# impute_conc_time() for one profile with its per-observation values, as
# pk.nca.interval() calls it, over an interval from 0 to `end`; `conc.group`
# and `time.group` add a predose sample of 5 at `predose_time` to the profile
# when `predose` is TRUE
impute_test_obs_chain <- function(impute_funs, conc, time, volume, duration.conc, include_half.life,
                                  exclude_half.life, lloq, predose, predose_time = -0.05, end = 4) {
  obs <-
    impute_obs_values(
      time = time, volume = volume, duration.conc = duration.conc,
      include_half.life = include_half.life, exclude_half.life = exclude_half.life, lloq = lloq
    )
  impute_conc_time(
    impute_funs = impute_funs, conc = conc, time = time, start = 0, end = end,
    conc.group = c(if (predose) 5, conc), time.group = c(if (predose) predose_time, time), options = list(),
    obs_values = obs$values, obs_fill = obs$fill
  )
}
