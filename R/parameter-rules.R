# Rules that make registry members from a base parameter.
#
# A rule has a prefix, an `eligible(base, spec)` predicate on a registered
# base's entry, and a `make(base, spec)` function returning the arguments for
# add.interval.col() (and, optionally, a `summary` list for
# PKNCA.set.summary()).  `<prefix>.<base>` becomes a parameter the first time
# its name is looked up through resolve_parameter_name(), so a member is an
# ordinary registry entry from then on.

#' Add a rule that makes NCA parameters from a base parameter
#'
#' A name `<prefix>.<base>` that is not registered becomes a parameter, the
#' first time it is looked up, when `base` is a registered parameter for which
#' `eligible()` is `TRUE`.
#'
#' @param prefix The prefix of the member names (without the trailing `.`)
#' @param eligible A function of `base` (the base parameter name) and `spec`
#'   (its registry entry from [get.interval.cols()]) giving `TRUE` when a member
#'   can be made from it
#' @param make A function of `base` and `spec` giving a list of arguments for
#'   [add.interval.col()] (without `name`), and optionally an element `summary`
#'   with the arguments for [PKNCA.set.summary()] (without `name`)
#' @returns `NULL`, invisibly
#' @keywords Internal
#' @noRd
add_parameter_rule <- function(prefix, eligible, make) {
  checkmate::assert_string(prefix, min.chars = 1, pattern = "^[A-Za-z][A-Za-z0-9_]*$")
  checkmate::assert_function(eligible, args = c("base", "spec"))
  checkmate::assert_function(make, args = c("base", "spec"))
  rules <- get0("parameter_rules", envir = .PKNCAEnv, inherits = FALSE, ifnotfound = list())
  rules[[prefix]] <- list(prefix = prefix, eligible = eligible, make = make)
  assign("parameter_rules", rules, envir = .PKNCAEnv)
  invisible(NULL)
}

#' The rules that make NCA parameters from base parameters
#'
#' Some NCA parameters are not registered one by one but made by a rule from a
#' base parameter:  `ratio.<base>` is the ratio of `<base>` to its value in a
#' reference interval.  A member is made the first time its name is used, for
#' example in an interval specification.
#'
#' @returns A data frame with one row per rule:  `prefix` (members are named
#'   `<prefix>.<base>`) and `bases` (the registered parameters a member can be
#'   made from, separated by commas)
#' @examples
#' pknca_parameter_rules()
#' @family Interval specifications
#' @export
pknca_parameter_rules <- function() {
  rules <- get0("parameter_rules", envir = .PKNCAEnv, inherits = FALSE, ifnotfound = list())
  all_intervals <- get.interval.cols()
  bases <-
    vapply(
      X = rules,
      FUN = function(rule) paste(parameter_rule_bases(rule, all_intervals), collapse = ", "),
      FUN.VALUE = ""
    )
  data.frame(prefix = names(rules), bases = unname(bases))
}

# The registered parameters that `rule` can make a member from
parameter_rule_bases <- function(rule, all_intervals = get.interval.cols()) {
  is_base <-
    vapply(
      X = names(all_intervals),
      FUN = function(base) isTRUE(rule$eligible(base = base, spec = all_intervals[[base]])),
      FUN.VALUE = TRUE
    )
  names(all_intervals)[is_base]
}

#' Register any rule-made parameters among `name`
#'
#' @param name Parameter names (a character vector)
#' @returns `name`, unchanged.  Each name that is not registered and that a rule
#'   can make is registered as a side effect; any other name is left for the
#'   caller to accept or refuse.
#' @keywords Internal
#' @noRd
resolve_parameter_name <- function(name) {
  rules <- get0("parameter_rules", envir = .PKNCAEnv, inherits = FALSE, ifnotfound = list())
  if (length(rules) == 0 || length(name) == 0) {
    return(name)
  }
  # The unsorted registry:  sorting needs every dependency to be registered,
  # which is not yet so while the package is being sourced
  all_names <- names(get("interval.cols", envir = .PKNCAEnv))
  for (current_name in setdiff(unique(stats::na.omit(name)), all_names)) {
    for (rule in rules) {
      prefix_dot <- paste0(rule$prefix, ".")
      if (startsWith(current_name, prefix_dot)) {
        base <- substring(current_name, nchar(prefix_dot) + 1)
        all_intervals <- get("interval.cols", envir = .PKNCAEnv)
        if (base %in% names(all_intervals) && isTRUE(rule$eligible(base = base, spec = all_intervals[[base]]))) {
          register_parameter_rule_member(rule = rule, base = base, spec = all_intervals[[base]])
          break
        }
      }
    }
  }
  name
}

# Register any rule-made parameters named by interval columns:  a parameter
# column, or its `_ref` or `_ref_vary` column
resolve_interval_parameter_names <- function(col_names) {
  resolve_parameter_name(unique(c(
    col_names,
    sub(pattern = "_ref$", replacement = "", x = col_names),
    sub(pattern = "_ref_vary$", replacement = "", x = col_names)
  )))
  invisible(col_names)
}

# Register the rule-made parameters of a results object, which may have been
# saved in a session where they were registered and read in one where they are
# not yet
resolve_results_parameter_names <- function(object) {
  resolve_interval_parameter_names(names(object$data$intervals))
  resolve_parameter_name(unique(object$result$PPTESTCD))
  invisible(object)
}

# Register the member of `rule` made from `base`
register_parameter_rule_member <- function(rule, base, spec) {
  name <- paste0(rule$prefix, ".", base)
  args <- rule$make(base = base, spec = spec)
  summary_args <- args$summary
  args$summary <- NULL
  do.call(add.interval.col, c(list(name = name), args))
  if (!is.null(summary_args)) {
    do.call(PKNCA.set.summary, c(list(name = name), summary_args))
  }
  invisible(name)
}

# Is the registry entry `spec` a secondary parameter (calculated with a value
# from another interval), or calculated from one?
parameter_spec_is_secondary <- function(spec, all_intervals = get("interval.cols", envir = .PKNCAEnv)) {
  if (any(vapply(X = spec$formalsmap, FUN = is_pknca_ref, FUN.VALUE = TRUE))) {
    return(TRUE)
  }
  any(vapply(
    X = intersect(unlist(spec$depends), names(all_intervals)),
    FUN = function(x) parameter_spec_is_secondary(all_intervals[[x]], all_intervals = all_intervals),
    FUN.VALUE = TRUE
  ))
}

# ratio.<base> ####

# Six ratios had CDISC codes and their own wording before ratios were made by
# rule; they keep both.  Any other ratio is labelled from its base's pretty
# name, and its PPTESTCD is its name until a controlled-terminology code is
# confirmed.
ratio_overrides <- function() {
  list(
    cmax = list(label = "Cmax", pptestcd = "RCMAX"),
    auclast = list(label = "AUClast", pptestcd = "RAUCLST"),
    aucinf.obs = list(label = "AUCinf,obs", pptestcd = "RAUCIFO"),
    aucinf.pred = list(label = "AUCinf,pred", pptestcd = "RAUCIFP"),
    aucint.last = list(label = "AUCint,last", pptestcd = "RAUCINL"),
    aucint.all = list(label = "AUCint,all", pptestcd = "RAUCINA")
  )
}

# A ratio's base is a concentration, an AUC, or an amount that is calculated
# directly (not dose-normalized, not secondary, not an earlier name of another
# parameter)
ratio_rule_eligible <- function(base, spec) {
  !is.null(spec$FUN) && !is.na(spec$FUN) &&
    spec$unit_type %in% c("conc", "auc", "amount") &&
    is.null(spec$historical_of) &&
    !parameter_spec_is_secondary(spec)
}

# The description is limited to 40 characters (SDTM PPTEST); a label that is too
# long for it gives way to the base's name
ratio_rule_desc <- function(base, label) {
  candidates <-
    c(
      sprintf("Ratio of %s to reference", label),
      sprintf("Ratio of %s to reference", base),
      sprintf("Ratio of %s to ref", base)
    )
  fits <- nchar(candidates) <= 40
  if (any(fits)) candidates[fits][1] else candidates[3]
}

ratio_rule_make <- function(base, spec) {
  override <- ratio_overrides()[[base]]
  label <- if (is.null(override)) spec$pretty_name else override$label
  pptestcd <- if (is.null(override)) paste0("ratio.", base) else override$pptestcd
  list(
    FUN = "pk.calc.ratio",
    values = c(FALSE, TRUE),
    unit_type = "fraction",
    pretty_name = sprintf("Ratio of %s to reference", label),
    desc = ratio_rule_desc(base = base, label = label),
    formalsmap = list(test = base, reference = pknca_ref(base)),
    depends = base,
    pptestcd_cdisc = pptestcd,
    pptest_cdisc = sprintf("Ratio of %s to Reference", label),
    selection = list(concept = "parameter_ratio"),
    summary =
      list(
        description = "geometric mean and geometric coefficient of variation",
        point = business.geomean,
        spread = business.geocv
      )
  )
}
