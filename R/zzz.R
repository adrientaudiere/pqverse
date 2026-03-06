.onAttach <- function(...) {
  attached <- pqverse_attach()
  if (length(attached) > 0) {
    msg <- paste0(
      cli::rule(left = cli::style_bold("Attaching pqverse packages")),
      "\n",
      paste0(
        cli::col_green(cli::symbol$tick),
        " ",
        cli::col_blue(format(attached)),
        " ",
        vapply(
          attached,
          function(p) {
            as.character(utils::packageVersion(p))
          },
          character(1)
        ),
        collapse = "\n"
      )
    )
    packageStartupMessage(msg)
  }
}
