# Core packages that are attached when library(pqverse) is called
core <- c("MiscMetabar", "tidypq", "comparpq", "taxinfo", "greenAlgoR", "dbpq", "bootpq", "phylopq", "netaipq", "ggplotpq")

core_unloaded <- function() {
  search <- paste0("package:", core)
  core[!search %in% search()]
}

pqverse_attach <- function() {
  to_load <- core_unloaded()
  suppressPackageStartupMessages(
    lapply(to_load, library, character.only = TRUE, warn.conflicts = FALSE)
  )
  invisible(to_load)
}

#' List all pqverse packages
#'
#' @param include_self Include pqverse in the list?
#' @return A character vector of package names.
#' @export
pqverse_packages <- function(include_self = TRUE) {
  pkgs <- core
  if (include_self) {
    pkgs <- c(pkgs, "pqverse")
  }
  pkgs
}
