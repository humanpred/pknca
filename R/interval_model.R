#' Choose parameters for an interval
#'
#' @inheritParams assert_choose_params_control
#' @inheritParams assert_choose_params_auc_choices
#' @inheritParams assert_choose_params_iv_choices
choose_params <- function(route, num_doses, sample_type, clast_type, auc_choices, iv_choices) {
  control <- assert_choose_params_control(route, num_doses, sample_type, clast_type)
  auc_choices <- assert_choose_params_auc_choices(auc_choices, route = control$route, clast_type = control$clast_type)
  iv_choices <- assert_choose_params_iv_choices(iv_choices, route = control$route)
}

#' Verify parameter options for choose_params
#'
#' @param route The route of administration
#' @param num_doses Were "single" or "multiple" doses administered
#' @param sample_type Was this a "spot" sample (typical for serum, plasma, and
#'   blood) or an "interval" sample (typical for urine and feces)
#' @param clast_type Should "pred"icted or "obs"erved clast be used?
#' @returns A list of valid parameters
assert_choose_params_control <- function(route, num_doses, sample_type, clast_type) {
  checkmate::assert_choice(route, choices = c("extravascular", "intravascular"), null.ok = FALSE)
  checkmate::assert_choice(num_doses, choices = c("single", "multiple"), null.ok = FALSE)
  checkmate::assert_choice(sample_type, choices = c("spot", "interval"), null.ok = FALSE)
  checkmate::assert_choice(clast_type, choices = c("pred", "obs"), null.ok = FALSE)
}

#' @describeIn assert_choose_params_control Choose valid AUC types
#'
#' @param auc_choices Zero or more types of AUC to calculate ("all", "inf", "last")
#' @param auc_prefix "auc" or "aumc" to indicate what type of AUC calculation it will be
#' @returns A character vector of AUC types to calculate
assert_choose_params_auc_choices <- function(auc_choices, route, clast_type, auc_prefix) {
  if (is.null(auc_choices)) {
    return(character())
  }
  auc_choices <- unique(checkmate::assert_subset(auc_choices, choices = c("all", "inf", "last")))
  which_inf <- which(auc_choices %in% "inf")
  if (length(which_inf) > 0) {
    auc_choices[which_inf] <- paste(auc_choices[which_inf], clast_type, sep = ".")
  }
  auc_prefix <- checkmate::assert_choice(auc_prefix, choices = c("auc", "aumc"))
  if (route %in% "intravascular") {
    ret <- paste0(auc_prefix, "iv")
  } else {
    ret <- auc_prefix
  }
  ret <- paste0(ret, auc_choices)
  assert_param_name(ret)
}

#' Choose IV-specific parameters
#'
#' @param iv_choices intravenous-specific parameter names ("c0", "ceoi")
assert_choose_params_iv_choices <- function(iv_choices) {
  unique(checkmate::assert_subset(x = iv_choices, choices = c("c0", "ceoi"))
}
