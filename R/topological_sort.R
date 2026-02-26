#' Perform topological sort of interval column specifications (Kahn's algorithm)
#'
#' Orders interval columns so that each parameter appears after
#' all parameters it depends on.
#'
#' The function:
#' \itemize{
#'   \item Validates structure of `specs`
#'   \item Ensures all dependencies exist
#'   \item Detects circular dependencies
#'   \item Returns deterministic ordering
#' }
#'
#' @param specs Named list of interval column specifications.
#'
#' @return Character vector of sorted parameter names.
#'
#' @keywords internal
topological_sort <- function(specs) {
  
  # ------------------------------------------------------------
  # 1. Structural validation
  # ------------------------------------------------------------
  checkmate::assert_list(
    specs,
    names = "named",
    min.len = 1,
    .var.name = "specs"
  )
  
  checkmate::assert_names(
    names(specs),
    type = "unique",
    .var.name = "names(specs)"
  )
  
  for (nm in names(specs)) {
    checkmate::assert_list(
      specs[[nm]],
      .var.name = paste0("specs[['", nm, "']]")
    )
    
    if (!"depends" %in% names(specs[[nm]])) {
      rlang::abort(
        sprintf("Column '%s' must contain a 'depends' field", nm),
        class = "pknca_error_invalid_spec_structure"
      )
    }
    
    # Allow NULL or empty depends (no dependencies)
    if (!is.null(specs[[nm]]$depends)) {
      checkmate::assert_character(
        specs[[nm]]$depends,
        any.missing = FALSE,
        .var.name = paste0("specs[['", nm, "']]$depends")
      )
    }
  }
  
  params <- names(specs)
  n <- length(params)
  
  # ------------------------------------------------------------
  # 2. Validate dependencies exist
  # ------------------------------------------------------------
  missing <- unique(unlist(lapply(specs, function(spec) {
    if (is.null(spec$depends)) return(character(0))
    setdiff(spec$depends, params)
  }), use.names = FALSE))
  
  if (length(missing)) {
    rlang::abort(
      sprintf(
        "Missing interval column definitions for: %s",
        paste(dQuote(missing), collapse = ", ")
      ),
      class = "pknca_error_missing_dependency"
    )
  }
  
  # ------------------------------------------------------------
  # 3. Build dependency graph
  # ------------------------------------------------------------
  in_deg <- setNames(integer(n), params)
  adj <- setNames(vector("list", n), params)
  
  for (p in params) {
    deps <- specs[[p]]$depends
    if (is.null(deps)) next  # Skip parameters with no dependencies
    
    for (d in deps) {
      adj[[d]] <- c(adj[[d]], p)
      in_deg[p] <- in_deg[p] + 1
    }
  }
  
  # ------------------------------------------------------------
  # 4. Topological sort (deterministic)
  # ------------------------------------------------------------
  queue <- sort(params[in_deg == 0])
  result <- character(n)
  idx <- 1
  
  while (length(queue)) {
    node <- queue[1]
    queue <- queue[-1]
    
    result[idx] <- node
    idx <- idx + 1
    
    for (nbr in adj[[node]]) {
      in_deg[nbr] <- in_deg[nbr] - 1
      if (in_deg[nbr] == 0) {
        queue <- sort(c(queue, nbr))
      }
    }
  }
  
  # ------------------------------------------------------------
  # 5. Cycle detection
  # ------------------------------------------------------------
  if (idx <= n) {
    rlang::abort(
      "Circular dependency detected in interval column specifications",
      class = "pknca_error_circular_dependency"
    )
  }
  
  result
}
