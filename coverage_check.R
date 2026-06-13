cov <- covr::package_coverage(quiet=TRUE)
df <- covr::tally_coverage(cov)
df_zero <- df[df[,"value"] == 0,]
writeLines("=== UNCOVERED LINES ===")
for (f in unique(df_zero[,"filename"])) {
  lines <- df_zero[df_zero[,"filename"] == f, "line"]
  writeLines(paste0(f, ": lines ", paste(sort(lines), collapse=", ")))
}
