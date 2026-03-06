#' Update pqverse packages
#'
#' Check which pqverse packages are out of date and optionally update them.
#'
#' @export
pqverse_update <- function() {
  pkgs <- pqverse_packages()
  installed <- vapply(
    pkgs,
    function(p) {
      if (is_installed(p)) {
        as.character(utils::packageVersion(p))
      } else {
        NA_character_
      }
    },
    character(1)
  )

  cli::cli_h1("pqverse packages")
  for (i in seq_along(pkgs)) {
    if (is.na(installed[i])) {
      cli::cli_alert_danger("{pkgs[i]}: not installed")
    } else {
      cli::cli_alert_success("{pkgs[i]} {installed[i]}")
    }
  }
  invisible(installed)
}
