#!/usr/bin/env Rscript
# generate_sitemap.R - writes sitemap.xml and robots.txt into the rendered book.
# Run after bookdown::render_book():  Rscript generate_sitemap.R
# The site URL is read from the `url:` field in index.Rmd (skipped if absent).

read_field <- function(file, field) {
  lines <- readLines(file, warn = FALSE)
  m <- grep(paste0("^", field, ":"), lines, value = TRUE)
  if (!length(m)) return(NA_character_)
  v <- sub(paste0("^", field, ":\\s*"), "", m[1])
  v <- gsub("\\\\:", ":", v)        # bookdown may escape the colon: https\://
  gsub('^"|"$', "", trimws(v))
}

out_dir <- "_book"
if (file.exists("_bookdown.yml")) {
  v <- read_field("_bookdown.yml", "output_dir")
  if (!is.na(v)) out_dir <- v
}
base_url <- read_field("index.Rmd", "url")
if (is.na(base_url)) {
  message("No `url:` field in index.Rmd; skipping sitemap.")
  quit(status = 0)
}
if (!grepl("/$", base_url)) base_url <- paste0(base_url, "/")
if (!dir.exists(out_dir)) stop("Output dir '", out_dir, "' not found. Render the book first.")

pages <- setdiff(list.files(out_dir, pattern = "\\.html$"), "404.html")
lastmod <- format(file.mtime(file.path(out_dir, pages)), "%Y-%m-%d")
loc <- paste0(base_url, ifelse(pages == "index.html", "", pages))
xml <- c('<?xml version="1.0" encoding="UTF-8"?>',
         '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
         paste0("  <url><loc>", loc, "</loc><lastmod>", lastmod, "</lastmod></url>"),
         "</urlset>")
writeLines(xml, file.path(out_dir, "sitemap.xml"))
writeLines(c("User-agent: *", "Allow: /", paste0("Sitemap: ", base_url, "sitemap.xml")),
           file.path(out_dir, "robots.txt"))
cat("Wrote", file.path(out_dir, "sitemap.xml"), "-", length(pages), "URLs, and robots.txt\n")
