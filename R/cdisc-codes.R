# Enumerate the resolved values of a pptestcd_cdisc/pptest_cdisc argument
# (see add.interval.col()): one value for a plain string, one per dense/sparse
# key, or one per route.  Mirrors the resolution resolve_cdisc_value() does
# for a single row, but returns every variant instead of one.
cdisc_value_variants <- function(x) {
  if (is.character(x)) {
    return(c(single = x))
  }
  if (is.list(x) && setequal(names(x), c("dense", "sparse"))) {
    return(unlist(x))
  }
  if (is.list(x) && !is.null(x$route)) {
    return(unlist(x$route))
  }
  c(single = as.character(x))
}

#' Every registered CDISC PPTESTCD/PPTEST code, with CT membership
#'
#' Enumerates the `pptestcd_cdisc`/`pptest_cdisc` values registered on every
#' NCA parameter (see [add.interval.col()] and [get.interval.cols()]),
#' expanding a route- or sparse-keyed mapping into one row per variant, and
#' flags whether each code is a real CDISC PKPARMCD term.  Generated from the
#' registry at call time; never hand-written, so it always reflects the
#' parameters actually registered (including by another package).
#'
#' @returns A data.frame with one row per parameter/variant and columns
#'   `parameter`, `tier`, `variant` (`"single"`, a route, or `"dense"`/
#'   `"sparse"`), `pptestcd_cdisc`, `pptest_cdisc`, and `in_ct` (whether
#'   `pptestcd_cdisc` is a code in the CDISC PKPARMCD codelist, checked
#'   against the installed cdiscdata package; `NA` for every row, with a
#'   message, if cdiscdata is not installed).
#' @details A parameter with no CDISC PKPARMCD equivalent (for example a
#'   sample count or a standard error, neither of which CDISC assigns its own
#'   PP parameter code) keeps a sponsor-defined code with `in_ct` `FALSE`;
#'   that is expected for some `"uncommon"` tier parameters and, for a few
#'   documented exceptions, for `"common"` tier ones as well (see the
#'   comments at their `add.interval.col()` registrations).
#' @seealso [pknca_parameter_table()], [add.interval.col()]
#' @examples
#' head(pknca_cdisc_codes())
#' @family Interval specifications
#' @export
pknca_cdisc_codes <- function() {
  all_intervals <- get.interval.cols()
  all_intervals <- all_intervals[setdiff(names(all_intervals), c("start", "end"))]
  rows <- lapply(
    X = names(all_intervals),
    FUN = function(p) {
      spec <- all_intervals[[p]]
      codes <- cdisc_value_variants(spec$pptestcd_cdisc)
      tests <- cdisc_value_variants(spec$pptest_cdisc)
      variant <- names(codes)
      test_aligned <- unname(ifelse(variant %in% names(tests), tests[variant], tests[1]))
      data.frame(
        parameter = p,
        tier = spec$tier %||% "uncommon",
        variant = variant,
        pptestcd_cdisc = unname(codes),
        pptest_cdisc = test_aligned,
        stringsAsFactors = FALSE
      )
    }
  )
  ret <- do.call(rbind, rows)
  ret$in_ct <- pknca_cdisc_in_ct(ret$pptestcd_cdisc)
  rownames(ret) <- NULL
  ret
}

# Whether each pptestcd_cdisc value is a real CDISC PKPARMCD code, checked
# against the installed cdiscdata package's controlled terminology.  NA for
# every value, with a message, when cdiscdata is not installed.
pknca_cdisc_in_ct <- function(codes) {
  if (!requireNamespace("cdiscdata", quietly = TRUE)) {
    rlang::inform(
      paste(
        "cdiscdata is not installed; `in_ct` in pknca_cdisc_codes() will be NA.",
        "Install cdiscdata to check CDISC PPTESTCD codes against the current",
        "PKPARMCD controlled terminology."
      ),
      class = "pknca_message_cdiscdata_unavailable"
    )
    return(rep(NA, length(codes)))
  }
  # cdiscdata 0.1.0's get_ct() resolves its dataset catalogue through a
  # reference that only exists once the package is attached, not merely
  # namespace-loaded (a packaging quirk expected to be fixed upstream).
  # attachNamespace()/detach() attach it for this call only, without altering
  # the caller's search path the way a bare library() call would.
  already_attached <- "package:cdiscdata" %in% search()
  if (!already_attached) {
    attachNamespace(asNamespace("cdiscdata"))
    on.exit(try(detach("package:cdiscdata"), silent = TRUE), add = TRUE)
  }
  ct <- cdiscdata::get_ct(type = "sdtm")
  pkparmcd_codes <- ct$term[ct$codelist_code %in% "C85839"]
  codes %in% pkparmcd_codes
}
