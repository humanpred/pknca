# Parameter names that were replaced by names that follow one pattern:  the
# suffix names the AUC the parameter is calculated from, as the AUC names do
# (`cl.inf.obs` from `aucinf.obs`, `cav.last` from `auclast`), and words are
# separated by dots (`count.conc`).  The old names still calculate, and give the
# same values they always have, because each is registered as a copy of its
# replacement (at the end of R/zzz-pk.calc.dn.R, after every replacement is
# registered); requesting one warns (see warn_deprecated_renamed_parameters()).
deprecated_renamed_parameters <- c(
  adj_tobit_residual = "adj.tobit.residual",
  aucivpbextall = "aucivpbext.all",
  aucivpbextinf.obs = "aucivpbext.inf.obs",
  aucivpbextinf.pred = "aucivpbext.inf.pred",
  aucivpbextint.all = "aucivpbext.int.all",
  aucivpbextint.last = "aucivpbext.int.last",
  aucivpbextlast = "aucivpbext.last",
  aucpext.obs = "aucpext.inf.obs",
  aucpext.pred = "aucpext.inf.pred",
  cav = "cav.last",
  cav.dn = "cav.last.dn",
  cl.iv.obs = "cl.iv.inf.obs",
  cl.iv.pred = "cl.iv.inf.pred",
  cl.obs = "cl.inf.obs",
  cl.pred = "cl.inf.pred",
  clr.obs = "clr.inf.obs",
  clr.pred = "clr.inf.pred",
  count_conc = "count.conc",
  count_conc_measured = "count.conc.measured",
  f.int.obs = "f.int.inf.obs",
  f.int.pred = "f.int.inf.pred",
  f.obs = "f.inf.obs",
  f.pred = "f.inf.pred",
  kel.iv.obs = "kel.iv.inf.obs",
  kel.iv.pred = "kel.iv.inf.pred",
  kel.obs = "kel.inf.obs",
  kel.pred = "kel.inf.pred",
  lambda.z.n.points_blq = "lambda.z.n.points.blq",
  mrt.iv.obs = "mrt.iv.inf.obs",
  mrt.iv.pred = "mrt.iv.inf.pred",
  mrt.ivmd.obs = "mrt.ivmd.inf.obs",
  mrt.ivmd.pred = "mrt.ivmd.inf.pred",
  mrt.md.obs = "mrt.md.inf.obs",
  mrt.md.pred = "mrt.md.inf.pred",
  mrt.obs = "mrt.inf.obs",
  mrt.pred = "mrt.inf.pred",
  thalf.eff.iv.obs = "thalf.eff.iv.inf.obs",
  thalf.eff.iv.pred = "thalf.eff.iv.inf.pred",
  thalf.eff.obs = "thalf.eff.inf.obs",
  thalf.eff.pred = "thalf.eff.inf.pred",
  time_above = "time.above",
  tobit_residual = "tobit.residual",
  vss.iv.obs = "vss.iv.inf.obs",
  vss.iv.pred = "vss.iv.inf.pred",
  vss.ivmd.obs = "vss.ivmd.inf.obs",
  vss.ivmd.pred = "vss.ivmd.inf.pred",
  vss.md.obs = "vss.md.inf.obs",
  vss.md.pred = "vss.md.inf.pred",
  vss.obs = "vss.inf.obs",
  vss.pred = "vss.inf.pred",
  vz.iv.obs = "vz.iv.inf.obs",
  vz.iv.pred = "vz.iv.inf.pred",
  vz.obs = "vz.inf.obs",
  vz.pred = "vz.inf.pred"
)

# Warn once per session for each set of deprecated names an interval
# specification requests
warn_deprecated_renamed_parameters <- function(requested) {
  warn_deprecated_parameter_names(
    requested = requested,
    replacements = deprecated_renamed_parameters,
    new_name = c("the new name", "the new names"),
    class = "pknca_warning_deprecated_parameter",
    frequency_id = "pknca_deprecated_renamed"
  )
}

# The requested deprecated names that are not calculated by a function of their
# own but given by the calculation of another parameter (as tobit_residual is
# by half.life)
deprecated_output_names <- function(requested, all_intervals = get.interval.cols()) {
  old <- intersect(requested, names(deprecated_renamed_parameters))
  old[vapply(X = all_intervals[old], FUN = function(x) is.na(interval_col_fun(x)), FUN.VALUE = TRUE)]
}

# The names an exclusion rule looks a parameter up by:  the parameter, then the
# deprecated names that it replaced, which give the same value
parameter_and_deprecated_names <- function(parameter) {
  c(parameter, names(deprecated_renamed_parameters)[deprecated_renamed_parameters %in% parameter])
}

# Register a deprecated parameter name as a copy of the parameter that
# replaced it, with the same summary.  The tier is left at "uncommon" so that
# the profile selector does not offer a deprecated name among the common ones.
register_deprecated_parameter <- function(old, new) {
  spec <- get.interval.cols()[[new]]
  add.interval.col(
    name = old,
    FUN = spec$FUN,
    values = spec$values,
    unit_type = spec$unit_type,
    pretty_name = spec$pretty_name,
    depends = spec$depends,
    desc = spec$desc,
    sparse = isTRUE(spec$sparse),
    formalsmap = spec$formalsmap,
    FUN_sparse = spec$FUN_sparse,
    formalsmap_sparse = spec$formalsmap_sparse,
    datatype = spec$datatype,
    pptestcd_cdisc = spec$pptestcd_cdisc,
    pptest_cdisc = spec$pptest_cdisc,
    formula = spec$formula,
    formula_note = spec$formula_note,
    selection = spec$selection
  )
  summary_instructions <- get("summary", envir = .PKNCAEnv)
  if (!is.null(summary_instructions[[new]])) {
    summary_instructions[[old]] <- summary_instructions[[new]]
    assign("summary", summary_instructions, envir = .PKNCAEnv)
  }
  invisible(NULL)
}
