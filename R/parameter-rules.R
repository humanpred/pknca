# Rules that make registry members from a base parameter.
#
# A rule has a prefix, an `eligible(base, spec)` predicate on a registered
# base's entry, a `make(base, spec)` function returning the arguments for
# add.interval.col() (and, optionally, a `summary` list for
# PKNCA.set.summary()), and a `refusal(base, spec)` function saying why a base
# is not eligible.  `<prefix>.<base>` is registered for every eligible base
# when the package is built (at the end of R/zzz-pk.calc.dn.R), so a member is
# an ordinary registry entry and every session has the same registry.

#' Add a rule that makes NCA parameters from a base parameter
#'
#' @param prefix The prefix of the member names (without the trailing `.`)
#' @param eligible A function of `base` (the base parameter name) and `spec`
#'   (its registry entry from [get.interval.cols()]) giving `TRUE` when a member
#'   is made from it
#' @param make A function of `base` and `spec` giving a list of arguments for
#'   [add.interval.col()] (without `name`), and optionally an element `summary`
#'   with the arguments for [PKNCA.set.summary()] (without `name`)
#' @param refusal A function of `base` and `spec` giving one sentence saying why
#'   no member is made from an ineligible base
#' @returns `NULL`, invisibly
#' @keywords Internal
#' @noRd
add_parameter_rule <- function(prefix, eligible, make, refusal) {
  checkmate::assert_string(prefix, min.chars = 1, pattern = "^[A-Za-z][A-Za-z0-9_]*$")
  checkmate::assert_function(eligible, args = c("base", "spec"))
  checkmate::assert_function(make, args = c("base", "spec"))
  checkmate::assert_function(refusal, args = c("base", "spec"))
  rules <- get0("parameter_rules", envir = .PKNCAEnv, inherits = FALSE, ifnotfound = list())
  rules[[prefix]] <- list(prefix = prefix, eligible = eligible, make = make, refusal = refusal)
  assign("parameter_rules", rules, envir = .PKNCAEnv)
  invisible(NULL)
}

#' The rules that make NCA parameters from base parameters
#'
#' Some NCA parameters are not registered one by one but made by a rule from a
#' base parameter:  `ratio.<base>` is the ratio of `<base>` to its value in a
#' reference interval, and `mr.<base>` is the metabolite to parent ratio of
#' `<base>` (its reference is the same interval of the parent analyte, named
#' with the `group_ref` argument of [PKNCAdata()]).  A member is registered for every eligible base when
#' PKNCA is loaded; a parameter registered later with [add.interval.col()] does
#' not get one.
#'
#' @returns A data frame with one row per rule:  `prefix` (members are named
#'   `<prefix>.<base>`) and `bases` (the registered parameters a member is made
#'   from, separated by commas)
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
      FUN = function(rule) paste(parameter_rule_bases(rule, all_intervals, registered = TRUE), collapse = ", "),
      FUN.VALUE = ""
    )
  data.frame(prefix = names(rules), bases = unname(bases))
}

# The registered parameters that `rule` makes a member from, in registry order;
# with `registered = TRUE`, only those whose member is registered
parameter_rule_bases <- function(rule, all_intervals = get("interval.cols", envir = .PKNCAEnv),
                                 registered = FALSE) {
  is_base <-
    vapply(
      X = names(all_intervals),
      FUN = function(base) isTRUE(rule$eligible(base = base, spec = all_intervals[[base]])),
      FUN.VALUE = TRUE
    )
  if (registered) {
    is_base <- is_base & paste0(rule$prefix, ".", names(all_intervals)) %in% names(all_intervals)
  }
  names(all_intervals)[is_base]
}

# Register the members of the rules that are not registered yet:  those of
# `bases` (every eligible base when `NULL`) for the rule `prefix` (every rule
# when `NULL`).  The members are added in the registry order of their bases.
register_parameter_rule_members <- function(prefix = NULL, bases = NULL) {
  rules <- get0("parameter_rules", envir = .PKNCAEnv, inherits = FALSE, ifnotfound = list())
  if (!is.null(prefix)) {
    rules <- rules[prefix]
  }
  for (rule in rules) {
    # The unsorted registry:  sorting needs every dependency to be registered,
    # which is not yet so while the package is being sourced
    all_intervals <- get("interval.cols", envir = .PKNCAEnv)
    current_bases <- bases %||% parameter_rule_bases(rule, all_intervals)
    for (base in current_bases) {
      if (!(paste0(rule$prefix, ".", base) %in% names(all_intervals))) {
        if (!isTRUE(rule$eligible(base = base, spec = all_intervals[[base]]))) {
          rlang::abort(
            sprintf("Please report a bug.  '%s' is not an eligible base of the '%s' rule", base, rule$prefix),
            class = "pknca_error_internal_parameter_rule_base"
          )
        }
        register_parameter_rule_member(rule = rule, base = base, spec = all_intervals[[base]])
      }
    }
  }
  invisible(NULL)
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

# For each of `name` that has the form `<rule prefix>.<registered parameter>`
# but is not registered, one sentence saying why the rule makes no such
# parameter (named by `name`)
parameter_rule_refusals <- function(name) {
  rules <- get0("parameter_rules", envir = .PKNCAEnv, inherits = FALSE, ifnotfound = list())
  all_intervals <- get("interval.cols", envir = .PKNCAEnv)
  ret <- character()
  for (current_name in setdiff(unique(name), names(all_intervals))) {
    for (rule in rules) {
      prefix_dot <- paste0(rule$prefix, ".")
      base <- substring(current_name, nchar(prefix_dot) + 1)
      if (startsWith(current_name, prefix_dot) && base %in% names(all_intervals)) {
        reason <-
          if (isTRUE(rule$eligible(base = base, spec = all_intervals[[base]]))) {
            sprintf(
              "'%s' was registered after PKNCA was loaded, and members of '%s' are made only for the parameters registered when PKNCA is loaded",
              base, rule$prefix
            )
          } else {
            rule$refusal(base = base, spec = all_intervals[[base]])
          }
        ret[current_name] <- sprintf("'%s' is not a parameter:  %s.", current_name, reason)
        break
      }
    }
  }
  ret
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

# Why `base` has no ratio, in the order of the conditions above
ratio_rule_refusal <- function(base, spec) {
  ratio_refusal_text(base = base, spec = spec, prefix = "ratio")
}

# Why `base` has no member of the rule `prefix` (a ratio or a metabolite ratio,
# which have the same bases)
ratio_refusal_text <- function(base, spec, prefix) {
  if (!is.null(spec$historical_of)) {
    sprintf(
      "'%s' is an earlier name of '%s', and a ratio is made only of the current name ('%s.%s')",
      base, spec$historical_of, prefix, spec$historical_of
    )
  } else if (parameter_spec_is_secondary(spec)) {
    sprintf("'%s' is calculated with a value from a reference interval, and a ratio is not made of it", base)
  } else if (spec$unit_type %in% c("conc_dosenorm", "auc_dosenorm", "aumc_dosenorm")) {
    sprintf("'%s' is dose-normalized, and a ratio is made of the parameter before dose normalization", base)
  } else if (spec$unit_type %in% "aumc") {
    sprintf("'%s' is an AUMC, and a ratio is made only of a concentration, an AUC, or an amount", base)
  } else if (is.null(spec$FUN) || is.na(spec$FUN)) {
    sprintf("'%s' is not calculated by a function of its own, and a ratio is not made of it", base)
  } else {
    sprintf(
      "'%s' is not a concentration, an AUC, or an amount (its unit type is '%s'), and a ratio is made only of those",
      base, spec$unit_type
    )
  }
}

# The description is limited to 40 characters (SDTM PPTEST); a label that is too
# long for it gives way to the base's name
ratio_rule_desc <- function(base, label) {
  rule_desc_fit(c(
    sprintf("Ratio of %s to reference", label),
    sprintf("Ratio of %s to reference", base),
    sprintf("Ratio of %s to ref", base)
  ))
}

# The first description of `candidates` that fits the 40 characters of SDTM
# PPTEST, or the last one when none does
rule_desc_fit <- function(candidates) {
  fits <- nchar(candidates) <= 40
  if (any(fits)) candidates[fits][1] else candidates[length(candidates)]
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

# mr.<base> ####

# A metabolite to parent ratio has the bases of a ratio, and its reference is
# the same interval of the parent analyte (named with `group_ref`)
mr_rule_eligible <- function(base, spec) {
  ratio_rule_eligible(base = base, spec = spec)
}

mr_rule_refusal <- function(base, spec) {
  ratio_refusal_text(base = base, spec = spec, prefix = "mr")
}

mr_rule_make <- function(base, spec) {
  label <- spec$pretty_name
  desc <-
    rule_desc_fit(c(
      sprintf("Metabolite to parent ratio of %s", label),
      sprintf("Metabolite to parent ratio of %s", base),
      sprintf("Met/parent ratio of %s", base)
    ))
  list(
    FUN = "pk.calc.ratio",
    values = c(FALSE, TRUE),
    unit_type = "fraction",
    pretty_name = sprintf("Metabolite to parent ratio of %s", label),
    desc = desc,
    formalsmap = list(test = base, reference = pknca_ref(base)),
    depends = base,
    pptestcd_cdisc = paste0("mr.", base),
    pptest_cdisc = desc,
    selection = list(concept = "metabolite_ratio"),
    summary =
      list(
        description = "geometric mean and geometric coefficient of variation",
        point = business.geomean,
        spread = business.geocv
      )
  )
}

# Is `param` a metabolite ratio, whose reference must be the parent analyte?
is_metabolite_ratio <- function(param) {
  startsWith(param, "mr.") &
    vapply(
      X = param,
      FUN = function(x) identical(get.interval.cols()[[x]]$selection$concept, "metabolite_ratio"),
      FUN.VALUE = TRUE,
      USE.NAMES = FALSE
    )
}

# The error for a metabolite ratio requested with no way to find its parent
abort_mr_needs_parent <- function(param, call = rlang::caller_env()) {
  rlang::abort(
    sprintf(
      paste(
        "The metabolite ratio '%s' needs its parent analyte as the reference, and none is named.",
        "Give `group_ref` to PKNCAdata() naming the parent (for example, `group_ref = data.frame(<analyte column> = \"<parent>\")`),",
        "set the '%s_ref' column in the interval specification to the parent's 'interval_id', or use interval_add_secondary()."
      ),
      param, param
    ),
    class = c("pknca_error_mr_needs_parent", "pknca_error_secondary_needs_ref"),
    call = call
  )
}
