#!/usr/bin/env Rscript
# tools/verify_refs.R -- audit references.bib against Crossref.
#   * entries with a DOI: the DOI must resolve and its title/year must match;
#   * articles without a DOI: search Crossref by title + first author and report the
#     best match (and its DOI) so the entry can be checked or completed.
# Only cited keys are audited. Writes _scratch/ref-audit.csv and prints problems.
# Usage: Rscript tools/verify_refs.R [--all]

suppressPackageStartupMessages({ library(httr); library(jsonlite); library(stringdist) })

audit_all <- "--all" %in% commandArgs(trailingOnly = TRUE)
bib <- bib2df::bib2df("references.bib")
names(bib) <- tolower(names(bib))

# Keys cited anywhere in the book
rmds <- yaml::read_yaml("_bookdown.yml")$rmd_files
rmds <- rmds[file.exists(rmds)]
txt <- paste(unlist(lapply(rmds, readLines, warn = FALSE, encoding = "UTF-8")), collapse = "\n")
txt <- gsub("(?s)```.*?```", "", txt, perl = TRUE)
cited <- regmatches(txt, gregexpr("(?<![A-Za-z0-9_.\\\\])@([A-Za-z0-9][A-Za-z0-9_:.-]*[A-Za-z0-9_])", txt, perl = TRUE))[[1]]
cited <- unique(sub("^@", "", cited))
if (!audit_all) bib <- bib[bib$bibtexkey %in% cited, ]

norm <- function(x) {
  x <- gsub("[{}\\\\]", "", x)
  x <- iconv(x, to = "ASCII//TRANSLIT")
  tolower(gsub("[^A-Za-z0-9 ]", " ", x)) |> gsub(pattern = "\\s+", replacement = " ") |> trimws()
}
sim <- function(a, b) 1 - stringdist::stringdist(norm(a), norm(b), method = "jw")
first_author <- function(a) {
  if (is.null(a) || all(is.na(a))) return("")
  a <- a[[1]][1]
  if (grepl(",", a)) sub(",.*$", "", a) else sub("^.* ", "", a)
}

ua <- user_agent("social-theory-book reference audit (https://github.com/mikenguyen13/social-theory)")
cr_get <- function(url, query = NULL) {
  for (i in 1:3) {
    r <- tryCatch(GET(url, query = query, ua, timeout(30)), error = function(e) NULL)
    if (!is.null(r) && status_code(r) == 200) return(fromJSON(content(r, "text", encoding = "UTF-8"), simplifyVector = FALSE))
    if (!is.null(r) && status_code(r) == 404) return(NULL)
    Sys.sleep(1.5 * i)
  }
  NULL
}
cr_title <- function(m) if (length(m$title)) m$title[[1]] else NA_character_
cr_year <- function(m) {
  for (f in c("published-print", "published-online", "issued", "created")) {
    d <- m[[f]]$`date-parts`
    if (length(d) && length(d[[1]]) && !is.null(d[[1]][[1]])) return(as.integer(d[[1]][[1]]))
  }
  NA_integer_
}

rows <- vector("list", nrow(bib))
for (i in seq_len(nrow(bib))) {
  e <- bib[i, ]
  key <- e$bibtexkey; type <- tolower(e$category); title <- e$title; year <- suppressWarnings(as.integer(e$year))
  doi <- if (!is.null(e$doi)) e$doi else NA
  status <- "unchecked"; cr_t <- NA; cr_y <- NA; cr_doi <- NA; s <- NA
  if (!is.na(doi) && nzchar(doi)) {
    m <- cr_get(paste0("https://api.crossref.org/works/", utils::URLencode(doi, reserved = TRUE)))
    if (is.null(m)) { status <- "DOI_NOT_FOUND" } else {
      m <- m$message; cr_t <- cr_title(m); cr_y <- cr_year(m); cr_doi <- doi
      s <- sim(title, cr_t)
      status <- if (s >= 0.88 && (is.na(year) || is.na(cr_y) || abs(year - cr_y) <= 1)) "ok_doi"
                else if (s >= 0.88) "YEAR_MISMATCH" else "TITLE_MISMATCH"
    }
  } else if (type %in% c("article", "inproceedings", "incollection")) {
    q <- list(query.bibliographic = paste(title, first_author(e$author), year), rows = 3,
              select = "DOI,title,issued,published-print,published-online,author,container-title")
    res <- cr_get("https://api.crossref.org/works", q)
    items <- if (!is.null(res)) res$message$items else list()
    if (length(items)) {
      sims <- vapply(items, function(m) sim(title, cr_title(m)), numeric(1))
      b <- which.max(sims); m <- items[[b]]
      cr_t <- cr_title(m); cr_y <- cr_year(m); cr_doi <- m$DOI; s <- sims[b]
      status <- if (s >= 0.9 && (is.na(year) || is.na(cr_y) || abs(year - cr_y) <= 1)) "ok_search"
                else if (s >= 0.9) "YEAR_MISMATCH_search" else "NO_CLOSE_MATCH"
    } else status <- "NO_CLOSE_MATCH"
  } else status <- "skipped_book_or_other"
  rows[[i]] <- data.frame(key = key, type = type, year = year, title = title, status = status,
                          similarity = round(s, 3), crossref_year = cr_y, crossref_title = cr_t,
                          crossref_doi = cr_doi, stringsAsFactors = FALSE)
  Sys.sleep(0.15)
}
out <- do.call(rbind, rows)
dir.create("_scratch", showWarnings = FALSE)
write.csv(out, "_scratch/ref-audit.csv", row.names = FALSE)
cat("\nAudited", nrow(out), "entries\n"); print(table(out$status))
bad <- out[!out$status %in% c("ok_doi", "ok_search", "skipped_book_or_other"), ]
if (nrow(bad)) {
  cat("\nEntries needing attention:\n")
  print(bad[, c("key", "year", "status", "similarity", "crossref_year", "crossref_doi")], row.names = FALSE)
}
