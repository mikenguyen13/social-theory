#!/usr/bin/env Rscript
# tools/postprocess_html.R -- final house-style pass on the rendered site:
# replaces any remaining en dashes, em dashes, and semicolons in visible text
# (mostly page ranges and titles in the bibliography). Scripts, styles, code,
# and math are left untouched.
# Usage: Rscript tools/postprocess_html.R [dir]   (default: docs)

args <- commandArgs(trailingOnly = TRUE)
dir <- if (length(args)) args[1] else "docs"
EM <- "—"; EN <- "–"
skip <- c("script", "style", "code", "pre", "math", "svg", "textarea")

clean <- function(s) {
  if (grepl("\\\\\\(|\\\\\\[|\\$\\$", s)) return(s)          # MathJax source
  s <- gsub(paste0("(\\d)\\s*", EN, "\\s*(\\d)"), "\\1-\\2", s, perl = TRUE)
  s <- gsub(paste0("\\s+[", EN, EM, "]\\s+"), ", ", s, perl = TRUE)
  s <- gsub(paste0("[", EN, EM, "]{2,}"), "", s, perl = TRUE)
  s <- gsub(paste0("(\\w)", EM, "(\\w)"), "\\1: \\2", s, perl = TRUE)
  s <- gsub(paste0("[", EN, EM, "]"), "-", s, perl = TRUE)
  s <- gsub("\\s*;\\s*", ", ", s, perl = TRUE)
  s
}

n_fixed <- 0
for (f in list.files(dir, pattern = "\\.html$", full.names = TRUE)) {
  doc <- xml2::read_html(f, encoding = "UTF-8")
  xp <- sprintf("//body//text()[not(ancestor::*[%s])]",
                paste(sprintf("self::%s", skip), collapse = " or "))
  nodes <- xml2::xml_find_all(doc, xp)
  txt <- xml2::xml_text(nodes)
  hit <- grepl(paste0("[", EN, EM, ";]"), txt)
  if (any(hit)) {
    for (i in which(hit)) xml2::xml_text(nodes[[i]]) <- clean(txt[i])
    n_fixed <- n_fixed + sum(hit)
    xml2::write_html(doc, f, options = "as_html")
  }
}
cat("postprocess_html: cleaned", n_fixed, "text nodes in", dir, "\n")
