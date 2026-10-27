#!/usr/bin/env Rscript
# tools/build.R -- full build: merge bibliography, render the site, add share
# images, sitemap and robots.txt. Optional flags:
#   --pdf     also build the PDF (saved to pdf/ and linked from the website)
#   --deploy  publish docs/ to Posit Connect Cloud afterwards (tools/deploy.R)
# Usage: Rscript tools/build.R [--pdf] [--deploy]

args <- commandArgs(trailingOnly = TRUE)
# Use the system LaTeX (MiKTeX/TeX Live) as is: no TinyTeX path changes, no
# automatic package installs.
options(tinytex.tlmgr.path = "", tinytex.install_packages = FALSE)

source("tools/merge_bib.R")
if ("--pdf" %in% args) {
  bookdown::render_book("index.Rmd", "bookdown::pdf_book", quiet = TRUE)
  dir.create("pdf", showWarnings = FALSE)
  file.copy("docs/social-science-theory.pdf", "pdf/social-science-theory.pdf", overwrite = TRUE)
}
bookdown::render_book("index.Rmd", "bookdown::bs4_book", quiet = TRUE)

dir.create("docs/images", showWarnings = FALSE, recursive = TRUE)
file.copy(c("images/social-card.png", "images/cover.png", "images/apple-touch-icon.png"),
          "docs/images", overwrite = TRUE)
file.copy("data/theory-atlas.csv", "docs/theory-atlas.csv", overwrite = TRUE)
if (file.exists("pdf/social-science-theory.pdf"))
  file.copy("pdf/social-science-theory.pdf", "docs/social-science-theory.pdf", overwrite = TRUE)
source("tools/postprocess_html.R")   # house style: no en/em dashes or semicolons
source("generate_sitemap.R")
unlink(Sys.glob("docs/*.md"))
if ("--deploy" %in% args) source("tools/deploy.R")
