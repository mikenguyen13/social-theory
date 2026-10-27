#!/usr/bin/env Rscript
# tools/depunctuate.R -- house style: no em dashes, en dashes, or semicolons in
# reader-facing text. Rewrites prose and quoted strings (captions, table cells,
# figure labels) in the book sources; leaves code syntax, citation keys
# ([@a; @b] is pandoc syntax), math, URLs, and inline code untouched.
#   Usage: Rscript tools/depunctuate.R [files...]   (default: all book sources)
#   --check   report remaining occurrences without changing files

EM <- "\u2014"; EN <- "\u2013"
conj <- c("and", "but", "or", "so", "yet", "nor", "which", "who", "whose", "where",
          "while", "whereas", "although", "though", "because", "not", "including",
          "especially", "often", "usually", "even", "as", "if", "unless", "then",
          "particularly", "typically", "sometimes", "rather", "only", "plus")

# ---- masking: protect spans that must not change ------------------------------
mask <- function(s) {
  keep <- character()
  pats <- c("\\$\\$.*?\\$\\$", "\\$[^$\n]+\\$", "`[^`\n]+`", "\\[[^\\[\\]]*@[^\\[\\]]*\\]",
            "\\b(?:e\\.g|i\\.e|vs|cf|al|etc|pp|p|Inc|Co|No|vol|ed|eds|Dr|Mr|Ms|St)\\.",
            "\\]\\([^)\n]*\\)", "https?://[^\\s)\"'>]+", "&[A-Za-z]+;", "\\\\;", "<!--.*?-->")
  for (p in pats) {
    repeat {
      m <- regexpr(p, s, perl = TRUE)
      if (m == -1) break
      tok <- sprintf("\u0001%d\u0002", length(keep) + 1)
      keep <- c(keep, regmatches(s, m))
      regmatches(s, m) <- tok
    }
  }
  list(s = s, keep = keep)
}
unmask <- function(s, keep) {
  for (i in rev(seq_along(keep))) s <- sub(sprintf("\u0001%d\u0002", i), keep[i], s, fixed = TRUE)
  s
}

words <- function(x) length(strsplit(trimws(gsub("[*_\\[\\]()]", "", x)), "\\s+")[[1]])
cap_first <- function(x) {
  m <- regexpr("[A-Za-z]", x)
  if (m == -1) return(x)
  pre <- substr(x, 1, m - 1)
  if (grepl("\u0001", pre) || grepl("@$", pre)) return(x)   # citation or masked span first
  # leave tokens like e.g. / i.e. / p-values / iPhone untouched
  if (grepl("^(e\\.g\\.|i\\.e\\.|vs\\.|et al\\.|p\\b|iP|eB)", substring(x, m))) return(x)
  paste0(pre, toupper(substr(x, m, m)), substring(x, m + 1))
}
first_word <- function(x) tolower(sub("^[^A-Za-z]*([A-Za-z]+).*$", "\\1", x))

fix_sentence <- function(sen) {
  # ---- em dashes ----
  parts <- strsplit(sen, paste0("[ \t]*", EM, "[ \t]*"), perl = TRUE)[[1]]
  if (length(parts) > 1) {
    n <- length(parts) - 1
    out <- parts[1]
    has_colon <- grepl(":", sen)
    for (k in seq_len(n)) {
      nxt <- parts[k + 1]
      paired <- (n >= 2 && k <= 2 * (n %/% 2))
      if (!nzchar(trimws(out)) ) sep <- ""                 # leading dash (table placeholder etc.)
      else if (!nzchar(trimws(nxt))) sep <- ""
      else if (paired) sep <- ", "
      else if (first_word(nxt) %in% conj || has_colon) sep <- ", "
      else { sep <- ": "; has_colon <- TRUE }
      out <- paste0(sub("[,:][ \t]*$", "", out, perl = TRUE), sep, nxt)
    }
    sen <- out
  }
  # ---- semicolons ----
  segs <- strsplit(sen, "[ \t]*;[ \t]*", perl = TRUE)[[1]]
  if (length(segs) > 1) {
    trailing <- grepl(";\\s*$", sen)
    wc <- vapply(segs, words, numeric(1))
    is_list <- length(segs) >= 3 && median(wc) <= 6      # e.g. "Key constructs. A; B; C"
    out <- segs[1]
    for (k in 2:length(segs)) {
      nxt <- segs[k]
      fw <- first_word(nxt)
      if (is_list || (wc[k - 1] <= 6 && wc[k] <= 6)) out <- paste0(out, ", ", nxt)
      else if (fw %in% c("and", "but", "or", "so", "yet", "nor", "while", "whereas")) out <- paste0(out, ", ", nxt)
      else out <- paste0(sub("[, \t]*$", "", out, perl = TRUE), ". ", cap_first(nxt))
    }
    if (trailing) out <- paste0(out, ".")
    sen <- out
  }
  sen
}

fix_text <- function(s) {
  if (!grepl(paste0("[", EM, EN, ";]"), s)) return(s)
  mk <- mask(s); s <- mk$s
  # en dashes: spaced en dash acts as an em dash; otherwise a hyphen
  s <- gsub(paste0("\\s+", EN, "\\s+"), paste0(" ", EM, " "), s, perl = TRUE)
  s <- gsub(EN, "-", s, fixed = TRUE)
  if (grepl(paste0("[", EM, ";]"), s)) {
    # split into sentences, keeping the boundary whitespace
    pieces <- regmatches(s, gregexpr("[^.!?]+(?:[.!?]+(?=\\s|$|\\*|\\)|\"|\u201d)|$)|[.!?]+", s, perl = TRUE))[[1]]
    if (length(pieces) && paste(pieces, collapse = "") == s) {
      s <- paste(vapply(pieces, fix_sentence, character(1)), collapse = "")
    } else s <- fix_sentence(s)
  }
  unmask(s, mk$keep)
}

# Rewrite only the contents of double-quoted strings on a code line.
fix_code_line <- function(ln) {
  if (!grepl(paste0("[", EM, EN, ";]"), ln)) return(ln)
  m <- gregexpr('"(?:[^"\\\\]|\\\\.)*"', ln, perl = TRUE)
  strs <- regmatches(ln, m)[[1]]
  if (!length(strs)) return(ln)
  regmatches(ln, m) <- list(vapply(strs, function(q) {
    inner <- substr(q, 2, nchar(q) - 1)
    if (grepl("^\\s*(\\{|rank|digraph)", inner)) return(q)          # graphviz syntax
    paste0('"', fix_text(inner), '"')
  }, character(1)))
  ln
}

process_file <- function(f, check = FALSE) {
  x <- readLines(f, warn = FALSE, encoding = "UTF-8")
  is_csv <- grepl("\\.csv$", f)
  in_chunk <- FALSE; in_yaml <- FALSE; in_math <- FALSE; chunk_is_r <- FALSE
  out <- x; block <- integer()
  flush <- function() {
    if (length(block)) {
      txt <- paste(out[block], collapse = "\n")
      new <- strsplit(fix_text(txt), "\n", fixed = TRUE)[[1]]
      if (length(new) == length(block)) out[block] <<- new
      else for (j in seq_along(block)) out[block[j]] <<- fix_text(out[block[j]])
    }
    block <<- integer()
  }
  for (i in seq_along(x)) {
    ln <- x[i]
    if (i == 1 && ln == "---" && !is_csv) { in_yaml <- TRUE; next }
    if (in_yaml) { if (ln == "---") in_yaml <- FALSE; next }
    if (grepl("^\\s*```", ln)) {
      flush()
      if (!in_chunk) {
        chunk_is_r <- grepl("^\\s*```\\s*\\{r", ln)
        if (chunk_is_r) out[i] <- fix_code_line(ln)   # fig.cap etc. in the chunk header
      }
      in_chunk <- !in_chunk
      next
    }
    if (in_chunk) {
      # R chunks: fix quoted strings. Other fenced blocks (bash, bibtex): leave alone.
      if (chunk_is_r) out[i] <- fix_code_line(ln)
      next
    }
    if (grepl("^\\$\\$", ln)) { flush(); in_math <- !in_math || grepl("^\\$\\$.*\\$\\$$", ln); if (grepl("^\\$\\$.*\\$\\$$", ln)) in_math <- FALSE; next }
    if (in_math) next
    if (is_csv) { out[i] <- if (i == 1) ln else fix_code_line(ln); next }
    if (!nzchar(trimws(ln)) || grepl("^\\s*(#|:::|<|\\|)", ln)) {
      flush()
      if (grepl("^\\s*#", ln) || grepl("^\\s*\\|", ln)) out[i] <- fix_text(ln)  # headings, md tables
      next
    }
    block <- c(block, i)
  }
  flush()
  changed <- out != x
  out[changed] <- sub("[ \t]+$", "", out[changed])
  if (check) return(invisible(sum(lengths(regmatches(out, gregexpr(paste0("[", EM, EN, "]"), out))))))
  if (!identical(out, x)) {
    con <- file(f, open = "wb"); writeLines(enc2utf8(out), con, useBytes = TRUE); close(con)
    cat("updated", f, "\n")
  }
}

args <- commandArgs(trailingOnly = TRUE)
check <- "--check" %in% args
files <- setdiff(args, "--check")
if (!length(files)) files <- c(Sys.glob("[0-9][0-9]-*.Rmd"), "index.Rmd", "README.md",
                               "CONTRIBUTING.md", "STYLE_GUIDE.md", "launch-kit/README.md",
                               "data/theory-atlas.csv")
for (f in files) process_file(f, check)
