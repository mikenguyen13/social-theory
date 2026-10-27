#!/usr/bin/env Rscript
# tools/build.R -- full build: merge bibliography, render the site, add share
# images, sitemap and robots.txt. Optional flags:
#   --pdf     also build the PDF
#   --deploy  publish docs/ to Posit Connect Cloud afterwards (tools/deploy.R)
# Usage: Rscript tools/build.R [--pdf] [--deploy]

args <- commandArgs(trailingOnly = TRUE)
source("tools/merge_bib.R")
bookdown::render_book("index.Rmd", "bookdown::bs4_book", quiet = TRUE)
if ("--pdf" %in% args) bookdown::render_book("index.Rmd", "bookdown::pdf_book", quiet = TRUE)

dir.create("docs/images", showWarnings = FALSE, recursive = TRUE)
file.copy(c("images/social-card.png", "images/cover.png", "images/apple-touch-icon.png"),
          "docs/images", overwrite = TRUE)
file.copy("data/theory-atlas.csv", "docs/theory-atlas.csv", overwrite = TRUE)
source("generate_sitemap.R")
if ("--deploy" %in% args) source("tools/deploy.R")
