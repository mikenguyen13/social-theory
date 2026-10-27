#!/usr/bin/env Rscript
# tools/check_retractions.R -- flag cited works that Crossref lists as retracted,
# withdrawn, or subject to an expression of concern. Run after merge_bib.R.
# Usage: Rscript tools/check_retractions.R

suppressPackageStartupMessages({ library(httr); library(jsonlite) })
bib <- bib2df::bib2df("references.bib")
names(bib) <- tolower(names(bib))
rmds <- yaml::read_yaml("_bookdown.yml")$rmd_files
rmds <- rmds[file.exists(rmds)]
txt <- paste(unlist(lapply(rmds, readLines, warn = FALSE, encoding = "UTF-8")), collapse = "\n")
txt <- gsub("(?s)```.*?```", "", txt, perl = TRUE)
cited <- unique(sub("^@", "", regmatches(txt, gregexpr("(?<![A-Za-z0-9_.\\\\])@[A-Za-z0-9][A-Za-z0-9_:.-]*[A-Za-z0-9_]", txt, perl = TRUE))[[1]]))
bib <- bib[bib$bibtexkey %in% cited & !is.na(bib$doi) & nzchar(bib$doi), ]

ua <- user_agent("social-theory-book retraction check (https://github.com/mikenguyen13/social-theory)")
hits <- list(); failed <- character()
for (i in seq_len(nrow(bib))) {
  doi <- tolower(bib$doi[i])
  r <- NULL
  for (attempt in 1:4) {
    r <- tryCatch(GET("https://api.crossref.org/works", ua, timeout(30),
                      query = list(filter = paste0("updates:", doi), rows = 5,
                                   select = "DOI,title,update-to")), error = function(e) NULL)
    if (!is.null(r) && status_code(r) == 200) break
    Sys.sleep(2 * attempt)
  }
  if (is.null(r) || status_code(r) != 200) { failed <- c(failed, bib$bibtexkey[i]); next }
  items <- fromJSON(content(r, "text", encoding = "UTF-8"), simplifyVector = FALSE)$message$items
  for (it in items) for (u in it$`update-to`) {
    if (tolower(u$DOI) == doi && u$type %in% c("retraction", "withdrawal", "expression_of_concern", "removal")) {
      hits[[length(hits) + 1]] <- data.frame(key = bib$bibtexkey[i], doi = doi, update = u$type,
                                            notice = it$DOI)
    }
  }
  Sys.sleep(0.1)
}
cat("Checked", nrow(bib) - length(failed), "of", nrow(bib), "cited DOIs\n")
if (length(failed)) cat("Lookup failed for:", paste(failed, collapse = ", "), "\n")
if (length(hits)) { cat("FLAGGED:\n"); print(do.call(rbind, hits), row.names = FALSE) } else cat("No retractions or expressions of concern found.\n")
