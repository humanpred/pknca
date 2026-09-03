# The deprecated sparse parameter names still calculate, and several tests
# exercise them on purpose.  Those silence the deprecation warning rather than
# letting it into the test output; the warning itself is tested in
# test-sparse.R.
without_sparse_deprecation <- function(expr) {
  withCallingHandlers(
    expr,
    pknca_warning_deprecated_sparse_parameter = function(w) rlang::cnd_muffle(w)
  )
}

# Likewise for the note that auc.method does not reach the sparse estimators,
# which pk.nca() emits once per run for any sparse analysis calculating an AUC.
without_sparse_auc_method_note <- function(expr) {
  withCallingHandlers(
    expr,
    pknca_message_sparse_auc_method = function(m) rlang::cnd_muffle(m)
  )
}
