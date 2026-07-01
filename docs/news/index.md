# Changelog

## pqverse 0.2.0 (Development version)

## pqverse 0.1.0

- Added `pkgdown/_pkgdown.yml` and rebuilt the pkgdown site at
  <https://adrientaudiere.github.io/pqverse/>. The site is now reachable
  from the GitHub Pages URL declared in `DESCRIPTION` and ships a
  navigation bar (Home / Reference / Changelog) plus a reference index
  for `pqverse-package`,
  [`pqverse_packages()`](https://adrientaudiere.github.io/pqverse/reference/pqverse_packages.md),
  and
  [`pqverse_update()`](https://adrientaudiere.github.io/pqverse/reference/pqverse_update.md).
- `dbpq` is now included in `Imports` and attached by
  [`library(pqverse)`](https://adrientaudiere.github.io/pqverse/),
  alongside MiscMetabar, tidypq, comparpq, taxinfo, and greenAlgoR.
  Previously, `dbpq` was listed in the README package table but was
  missing from `DESCRIPTION` Imports and the `core` vector in
  `attach.R`.

## pqverse 0.1.0

- Initial release.
- Loads and attaches all pqverse packages: MiscMetabar, tidypq,
  comparpq, taxinfo, greenAlgoR.
- [`pqverse_packages()`](https://adrientaudiere.github.io/pqverse/reference/pqverse_packages.md)
  lists all pqverse packages.
- [`pqverse_update()`](https://adrientaudiere.github.io/pqverse/reference/pqverse_update.md)
  shows installed versions of all pqverse packages.
