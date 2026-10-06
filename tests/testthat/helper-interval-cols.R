# Snapshot the parameter registry and restore it (with its derived caches
# dropped) when the calling frame exits.  Use in any test that registers or
# modifies an interval column, so that no test can leak a temporary parameter
# or a stale classification into another test file running in the same
# parallel worker.
local_interval_cols <- function(env = parent.frame()) {
  saved_cols <- get("interval.cols", envir = PKNCA:::.PKNCAEnv)
  saved_sorted <- get0("interval.cols_sorted", envir = PKNCA:::.PKNCAEnv)
  withr::defer(
    {
      assign("interval.cols", saved_cols, envir = PKNCA:::.PKNCAEnv)
      if (!is.null(saved_sorted)) {
        assign("interval.cols_sorted", saved_sorted, envir = PKNCA:::.PKNCAEnv)
      } else if (exists("interval.cols_sorted", envir = PKNCA:::.PKNCAEnv, inherits = FALSE)) {
        rm("interval.cols_sorted", envir = PKNCA:::.PKNCAEnv)
      }
      for (cache_name in c("parameter_classification", "auc_basis_families")) {
        if (exists(cache_name, envir = PKNCA:::.PKNCAEnv, inherits = FALSE)) {
          rm(list = cache_name, envir = PKNCA:::.PKNCAEnv)
        }
      }
    },
    envir = env
  )
}
