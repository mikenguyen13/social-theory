#!/usr/bin/env Rscript
# tools/check_chapter.R -- knit one chapter in isolation and audit its citations.
# Usage: Rscript tools/check_chapter.R 08-information.Rmd
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Usage: Rscript tools/check_chapter.R <chapter.Rmd>")
rmd <- args[1]
stopifnot(file.exists(rmd))
stem <- tools::file_path_sans_ext(basename(rmd))
out_dir <- file.path("_scratch", stem)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Knit (runs all R chunks with the book's shared setup)
env <- new.env()
sys.source("_common.R", envir = env)
knitr::opts_knit$set(base.dir = normalizePath(out_dir), root.dir = getwd())
knitr::opts_chunk$set(fig.path = "figs/")
md <- file.path(out_dir, paste0(stem, ".md"))
ok <- tryCatch({ knitr::knit(rmd, output = md, envir = env, quiet = TRUE); TRUE },
               error = function(e) { message("KNIT ERROR: ", conditionMessage(e)); FALSE })

# 2. Citation audit
bibs <- c("references.bib", "book.bib", Sys.glob("bib/*.bib"))
bibs <- bibs[file.exists(bibs)]
keys <- unlist(lapply(bibs, function(f) {
  x <- readLines(f, warn = FALSE, encoding = "UTF-8")
  trimws(sub("^@[A-Za-z]+[{]\\s*([^,]+),.*$", "\\1", grep("^@[A-Za-z]+[{]", x, value = TRUE)))
}))
txt <- paste(readLines(rmd, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
txt <- gsub("(?s)```.*?```", "", txt, perl = TRUE)                      # drop code chunks
cited <- regmatches(txt, gregexpr("(?<![A-Za-z0-9_.\\\\])@([A-Za-z][A-Za-z0-9_:.-]*[A-Za-z0-9_])", txt, perl = TRUE))[[1]]
cited <- unique(sub("^@", "", cited))
cited <- cited[!grepl("^(fig|tab|eq)[:-]", cited)]
missing <- setdiff(cited, keys)
dups <- keys[duplicated(keys)]

cat("\n== ", rmd, " ==\n", sep = "")
cat("Knit: ", if (ok) "OK" else "FAILED", "\n", sep = "")
if (ok) {
  figs <- list.files(file.path(out_dir, "figs"))
  cat("Static figures produced: ", length(figs), "\n", sep = "")
}
cat("Citation keys used: ", length(cited), "\n", sep = "")
if (length(missing)) cat("MISSING keys (add to bib/<nn>.bib): ", paste(missing, collapse = ", "), "\n", sep = "") else cat("All citation keys resolved.\n")
if (length(dups)) cat("Note: duplicate keys across bib files (fine if identical works): ", paste(unique(dups), collapse = ", "), "\n", sep = "")
words <- length(strsplit(gsub("(?s)```.*?```", "", txt, perl = TRUE), "\\s+")[[1]])
cat("Approx. words (prose): ", words, "\n", sep = "")
if (!ok) quit(status = 1)
