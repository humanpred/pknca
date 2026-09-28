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
#'   `pptestcd_cdisc` is a code in the bundled CDISC PKPARMCD snapshot; see
#'   `data-raw/pknca_ct_pkparmcd.R` for its source and version).
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
  ret$in_ct <- ret$pptestcd_cdisc %in% pknca_ct_pkparmcd$pptestcd_cdisc
  rownames(ret) <- NULL
  ret
}
