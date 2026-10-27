#!/usr/bin/env Rscript
# tools/audit_pdf.R -- automated checks on the rendered PDF:
# unresolved cross-references (??), forbidden punctuation, missing glyphs,
# leftover HTML-only placeholders, and near-empty pages.
# Usage: Rscript tools/audit_pdf.R [pdf]
args <- commandArgs(trailingOnly = TRUE)
f <- if (length(args)) args[1] else "pdf/social-science-theory.pdf"
t <- pdftools::pdf_text(f)
n <- length(t)
cat("Pages:", n, "\n")
report <- function(label, pages) cat(sprintf("%-32s %s\n", label, if (length(pages)) paste(head(pages, 40), collapse = " ") else "none"))
report("Unresolved refs (??):", which(grepl("\\?\\?", t)))
report("En/em dash:", which(grepl("[–—]", t)))
report("Semicolon:", which(grepl(";", t)))
report("Replacement glyph:", which(grepl("�|□", t)))
report("HTML-only placeholder:", which(grepl("Interactive diagram available", t)))
chars <- nchar(gsub("\\s", "", t))
report("Near-empty pages (<60 chars):", which(chars < 60))
for (p in which(grepl("\\?\\?|;|[–—]", t))[1:min(8, sum(grepl("\\?\\?|;|[–—]", t)))]) {
  l <- strsplit(t[p], "\n")[[1]]
  cat(sprintf("  p%d: %s\n", p, trimws(head(grep("\\?\\?|;|[–—]", l, value = TRUE), 2))))
}
