#!/usr/bin/env Rscript
# tools/deploy.R -- publish the rendered site (docs/) to Posit Connect Cloud as
# static content. Requires an rsconnect account for server "connect.posit.cloud"
# (set up once with rsconnect::connectCloudUser()).
# Usage: Rscript tools/deploy.R

stopifnot(file.exists("docs/index.html"))
rsconnect::deployApp(
  appDir = "docs",
  appId = "01a17b63-f04b-c542-bc6c-ece12120ea40",  # live at https://01a17b63-f04b-c542-bc6c-ece12120ea40.share.connect.posit.cloud/
  appPrimaryDoc = "index.html",
  appName = "social-science-theory",
  appTitle = "Social Science Theory",
  server = "connect.posit.cloud",
  account = "mike",
  forceUpdate = TRUE,
  launch.browser = FALSE,
  logLevel = "normal"
)
