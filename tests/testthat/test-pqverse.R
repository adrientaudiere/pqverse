test_that("pqverse_packages returns all core packages", {
  pkgs <- pqverse_packages()
  expect_true("MiscMetabar" %in% pkgs)
  expect_true("tidypq" %in% pkgs)
  expect_true("comparpq" %in% pkgs)
  expect_true("taxinfo" %in% pkgs)
  expect_true("greenAlgoR" %in% pkgs)
  expect_true("pqverse" %in% pkgs)
})

test_that("pqverse_packages can exclude self", {
  pkgs <- pqverse_packages(include_self = FALSE)
  expect_false("pqverse" %in% pkgs)
  expect_length(pkgs, 5)
})
