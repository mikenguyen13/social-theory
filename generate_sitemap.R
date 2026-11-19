#!/usr/bin/env Rscript
# generate_sitemap.R - points every page of the rendered book at its one
# canonical URL and writes sitemap.xml and robots.txt for that host.
# Run after bookdown::render_book():  Rscript generate_sitemap.R
# The site URL is read from the `url:` field in index.Rmd (skipped if absent).
#
# For each content page (every top-level .html file except 404.html):
#   * <link rel="canonical"> set to the page's OWN URL on the site
#     (index.html -> the site root), replacing any existing one;
#   * og:url set to the same URL.
# The same docs/ is also deployed to the Posit Connect Cloud mirror
# (tools/deploy.R), where these tags tell search engines that the GitHub Pages
# copy is the original.

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
loc <- paste0(base_url, ifelse(pages == "index.html", "", pages))
lastmod <- format(file.mtime(file.path(out_dir, pages)), "%Y-%m-%d")

# Canonical link and og:url on every content page. Plain text edits (no HTML
# re-serialization), so the rest of each file is left byte for byte.
read_text <- function(p) readChar(p, file.size(p), useBytes = TRUE)
write_text <- function(x, p) {
  con <- file(p, open = "wb"); on.exit(close(con))
  writeChar(x, con, eos = NULL, useBytes = TRUE)
}
for (i in seq_along(pages)) {
  p <- file.path(out_dir, pages[i])
  x <- read_text(p)
  x <- gsub('<link rel="canonical"[^>]*>[ \t]*\r?\n?', "", x, useBytes = TRUE)
  x <- sub("</head>", paste0('<link rel="canonical" href="', loc[i], '">\n</head>'),
           x, fixed = TRUE, useBytes = TRUE)
  x <- gsub('(<meta property="og:url" content=")[^"]*(")', paste0("\\1", loc[i], "\\2"),
            x, useBytes = TRUE)
  write_text(x, p)
}

xml <- c('<?xml version="1.0" encoding="UTF-8"?>',
         '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
         paste0("  <url><loc>", loc, "</loc><lastmod>", lastmod, "</lastmod></url>"),
         "</urlset>")
writeLines(xml, file.path(out_dir, "sitemap.xml"))
writeLines(c("User-agent: *", "Allow: /", paste0("Sitemap: ", base_url, "sitemap.xml")),
           file.path(out_dir, "robots.txt"))
cat("Set canonical on", length(pages), "pages; wrote", file.path(out_dir, "sitemap.xml"),
    "-", length(pages), "URLs, and robots.txt for", base_url, "\n")
