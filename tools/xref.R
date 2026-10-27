#!/usr/bin/env Rscript
# tools/xref.R -- cross-referencing pass over the book sources.
#  1. Every numbered figure and table is cited in the text: unreferenced ones get
#     "(Figure X.Y)" / "(Table X.Y)" added to the paragraph that introduces them.
#  2. The first mention of each theory in a chapter links to that theory's section.
#     Mentions in another chapter also get "(Section X.Y)" or "(Chapter X)".
# Idempotent: existing links and references are left alone.
# Usage: Rscript tools/xref.R [--dry-run] [files...]

args <- commandArgs(trailingOnly = TRUE)
dry <- "--dry-run" %in% args
env <- new.env(); sys.source("_common.R", envir = env)
book_files <- yaml::read_yaml("_bookdown.yml")$rmd_files
files <- setdiff(args, "--dry-run")
if (!length(files)) files <- grep("^(0[1-9]|[12][0-9]|3[01])-.*\\.Rmd$", book_files, value = TRUE)

atlas <- readr::read_csv("data/theory-atlas.csv", show_col_types = FALSE)
pages <- env$anchor_pages()                           # anchor -> chapter id

# chapter ids (to decide Chapter vs Section references)
chapter_ids <- unique(unname(pages))

# ---- term list ----------------------------------------------------------------
clean_name <- function(x) trimws(gsub("\\s*\\([^)]*\\)", "", x))
terms <- data.frame(term = clean_name(atlas$theory), anchor = atlas$anchor)
extra <- tibble::tribble(
  ~term, ~anchor,
  "resource-based view", "resource-based-theory", "resource-based theory", "resource-based-theory",
  "RBV", "resource-based-theory", "VRIO", "vrio", "TCE", "transaction-cost-economics",
  "transaction cost theory", "transaction-cost-economics", "signalling theory", "signaling-theory",
  "TAM", "technology-acceptance-model", "UTAUT", "utaut", "ELM", "elaboration-likelihood-model",
  "CAPM", "capm", "LMX", "leader-member-exchange", "JD-R model", "job-demands-resources",
  "self-determination theory", "self-determination-theory", "goal-setting theory", "goal-setting-theory",
  "expectancy theory", "expectancy-theory", "equity theory", "equity-theory",
  "social identity theory", "social-identity-theory", "social comparison theory", "social-comparison-theory",
  "regulatory focus", "regulatory-focus-theory", "construal level theory", "construal-level-theory",
  "loss aversion", "loss-aversion", "endowment effect", "endowment-effect", "mental accounting", "mental-accounting",
  "prospect theory", "prospect-theory", "cumulative prospect theory", "cumulative-prospect-theory",
  "status quo bias", "status-quo-bias", "disposition effect", "disposition-effect",
  "expected utility theory", "expected-utility-theory", "agency theory", "agency-theory",
  "stewardship theory", "stewardship-theory", "institutional theory", "institutional-theory",
  "resource dependence theory", "resource-dependence-theory", "stakeholder theory", "stakeholder-theory",
  "upper echelons theory", "upper-echelons-theory", "dynamic capabilities", "dynamic-capabilities-framework",
  "absorptive capacity", "absorptive-capacity", "structural holes", "structural-holes",
  "weak ties", "weak-ties", "social exchange theory", "social-exchange-theory",
  "diffusion of innovations", "diffusion-of-innovations", "Bass model", "bass-model",
  "theory of planned behavior", "theory-of-planned-behavior", "bounded rationality", "bounded-rationality",
  "dual-process", "dual-process-theory", "processing fluency", "processing-fluency",
  "hedonic adaptation", "hedonic-adaptation", "peak-end rule", "peak-end-rule",
  "cognitive dissonance", "cognitive-dissonance-theory", "attribution theory", "attribution-theory",
  "self-efficacy", "social-cognitive-theory", "reactance", "reactance-theory",
  "optimal distinctiveness", "optimal-distinctiveness-theory", "social norms", "social-norms",
  "social facilitation", "social-facilitation", "spiral of silence", "spiral-of-silence",
  "mere exposure", "mere-exposure-effect", "decoy effect", "decoy-effect", "attraction effect", "decoy-effect",
  "anchoring", "anchoring-effect", "IKEA effect", "ikea-effect", "glass cliff", "glass-cliff-effect",
  "snob effect", "snob-effect", "bandwagon effect", "snob-effect", "Veblen effect", "snob-effect",
  "wisdom of crowds", "wisdom-of-the-crowd", "Matthew effect", "matthew-effect", "groupthink", "groupthink",
  "social loafing", "social-loafing", "bystander effect", "bystander-effect", "homophily", "homophily",
  "tragedy of the commons", "tragedy-of-the-commons", "five forces", "five-forces",
  "game theory", "game-theory", "real options", "real-options-theory", "first-mover advantage", "first-mover-advantage",
  "behavioral theory of the firm", "behavioral-theory-of-the-firm", "attention-based view", "attention-based-view",
  "disruptive innovation", "disruptive-innovation", "creative destruction", "creative-destruction",
  "open innovation", "open-innovation", "effectuation", "effectuation", "liability of newness", "liability-of-newness",
  "liability of foreignness", "liability-of-foreignness", "institutional voids", "institutional-voids",
  "Uppsala model", "uppsala-model", "OLI paradigm", "oli-paradigm", "eclectic paradigm", "oli-paradigm",
  "garbage can model", "garbage-can-model", "escalation of commitment", "escalation-of-commitment",
  "psychological safety", "psychological-safety", "sensemaking", "sensemaking", "organizational learning", "organizational-learning",
  "job characteristics model", "job-characteristics-model", "job demands-resources", "job-demands-resources",
  "conservation of resources", "conservation-of-resources", "transformational leadership", "transformational-leadership",
  "psychological contract", "psychological-contract", "organizational justice", "organizational-justice",
  "human capital theory", "human-capital-theory", "tournament theory", "tournament-theory",
  "portfolio theory", "portfolio-theory", "efficient market hypothesis", "efficient-market-hypothesis",
  "Modigliani-Miller", "modigliani-miller", "pecking order", "trade-off-pecking-order",
  "free cash flow", "free-cash-flow", "limits to arbitrage", "limits-to-arbitrage", "behavioral finance", "behavioral-finance",
  "Coase theorem", "coase-theorem", "collective action", "collective-action", "network effects", "network-effects",
  "two-sided markets", "two-sided-markets", "two-sided platforms", "two-sided-markets", "auction theory", "auction-theory",
  "efficiency wages", "efficiency-wages", "gift exchange", "efficiency-wages", "inequity aversion", "social-preferences",
  "social preferences", "social-preferences", "property rights theory", "property-rights-theory",
  "search theory", "search-theory", "new institutional economics", "new-institutional-economics",
  "brand equity", "customer-based-brand-equity", "brand personality", "brand-personality",
  "self-congruity", "self-congruity", "means-end chain", "means-end-chain", "reference price", "reference-price",
  "psychological ownership", "psychological-ownership", "variety seeking", "variety-seeking",
  "consumer culture theory", "consumer-culture-theory", "expectancy-disconfirmation", "expectancy-disconfirmation",
  "market orientation", "market-orientation", "service-dominant logic", "service-dominant-logic",
  "SERVQUAL", "service-quality-gap-model", "customer lifetime value", "customer-equity", "customer equity", "customer-equity",
  "hierarchy of effects", "hierarchy-of-effects", "product life cycle", "product-life-cycle", "marketing mix", "marketing-mix",
  "bullwhip effect", "bullwhip-effect", "shared value", "shared-value", "Hofstede", "hofstede",
  "information asymmetry", "information-asymmetry", "adverse selection", "information-asymmetry",
  "screening", "screening-theory", "costly signaling", "costly-signaling", "countersignaling", "countersignaling",
  "identity signaling", "identity-signaling", "commitment-trust theory", "commitment-trust-theory",
  "social capital", "social-capital", "heuristics and biases", "heuristics-biases", "choice architecture", "choice-architecture",
  "feelings-as-information", "feelings-as-information-theory", "broaden-and-build", "broaden-and-build-theory",
  "appraisal theory", "appraisal-theory", "agenda setting", "agenda-setting", "framing", "framing-theory",
  "persuasion knowledge", "persuasion-knowledge-model", "uses and gratifications", "uses-and-gratifications",
  "word of mouth", "social-transmission", "goal gradient", "goal-gradient-hypothesis",
  "exploration and exploitation", "exploration-exploitation", "ambidexterity", "ambidexterity",
  "knowledge-based view", "knowledge-based-view", "isomorphism", "institutional-theory", "legitimacy", "legitimacy",
  "organizational ecology", "organizational-ecology", "contingency theory", "contingency-theory"
)
terms <- rbind(terms, as.data.frame(extra))
# drop terms that are too generic or too short to link safely
generic <- c("conformity", "explanation", "framing", "screening", "anchoring", "reactance")
terms <- terms[nchar(terms$term) >= 3 & !tolower(terms$term) %in% generic & terms$anchor %in% names(pages), ]
terms <- terms[!duplicated(tolower(terms$term)), ]
terms <- terms[order(-nchar(terms$term)), ]

esc <- function(s) gsub("([.\\\\+*?^$(){}|\\[\\]])", "\\\\\\1", s)
term_anchor <- setNames(as.list(terms$anchor), tolower(terms$term))
big_pat <- paste0("(?i)(?<![\\w\\-\u0001])(", paste(esc(terms$term), collapse = "|"), ")(?![\\w\\-\u0002])")
section_number_ref <- function(anchor) {
  if (anchor %in% chapter_ids) sprintf("Chapter \\@ref(%s)", anchor) else sprintf("Section \\@ref(%s)", anchor)
}

# ---- helpers -------------------------------------------------------------------
mask <- function(s) {
  keep <- character()
  pats <- c("\\[[^\\]]*\\]\\([^)]*\\)", "\\[@[^\\]]*\\]", "(?<![\\w])@[A-Za-z0-9_][A-Za-z0-9_:.-]*",
            "`[^`]*`", "\\$[^$]*\\$", "\\\\@ref\\([^)]*\\)", "<[^>]+>", "https?://\\S+")
  for (p in pats) repeat {
    m <- regexpr(p, s, perl = TRUE)
    if (m == -1) break
    keep <- c(keep, regmatches(s, m))
    regmatches(s, m) <- sprintf("\u0001%d\u0002", length(keep))
  }
  list(s = s, keep = keep)
}
unmask <- function(s, keep) {
  for (i in rev(seq_along(keep))) s <- sub(sprintf("\u0001%d\u0002", i), keep[i], s, fixed = TRUE)
  s
}

n_fig <- n_tab <- n_link <- 0
for (f in files) {
  x <- readLines(f, warn = FALSE, encoding = "UTF-8")
  orig <- x
  txt_all <- paste(x, collapse = "\n")

  # ---------- 1. figure / table references ----------
  starts <- grep("^```\\{r ", x)
  for (s in rev(starts)) {
    hdr <- x[s]
    lab <- sub("^```\\{r ([^, }]+).*", "\\1", hdr)
    e <- s + which(grepl("^```\\s*$", x[(s + 1):length(x)]))[1]
    body <- paste(x[(s + 1):(e - 1)], collapse = "\n")
    kind <- if (grepl("fig.cap", hdr)) "fig" else if (grepl("book_table\\(", body) && grepl("caption", body)) "tab" else NA
    if (is.na(kind)) next
    ref <- sprintf("\\@ref(%s:%s)", kind, lab)
    if (grepl(ref, txt_all, fixed = TRUE)) next
    word <- if (kind == "fig") "Figure" else "Table"
    j <- s - 1
    while (j > 0 && !nzchar(trimws(x[j]))) j <- j - 1
    prev <- if (j > 0) x[j] else ""
    is_prose <- j > 0 && !grepl("^\\s*(#|:::|```|\\||<|\\$\\$|\\*\\*[A-Z][^*]*\\.\\*\\*\\s*$)", prev) &&
                grepl("[.:)]\\s*$", prev)
    if (is_prose && grepl("\\.\\s*$", prev)) {
      x[j] <- paste0(sub("\\.\\s*$", "", prev), sprintf(" (%s %s).", word, ref))
    } else if (is_prose && grepl(":\\s*$", prev)) {
      x[j] <- paste0(sub(":\\s*$", "", prev), sprintf(" (%s %s):", word, ref))
    } else {
      cap <- if (kind == "fig") sub('.*fig\\.cap\\s*=\\s*"([^"]*)".*', "\\1", hdr) else
        sub('(?s).*caption\\s*=\\s*"([^"]*)".*', "\\1", body, perl = TRUE)
      cap <- sub("\\.\\s.*$", "", cap)                       # first sentence only
      cap <- sub("\\.$", "", cap)
      cap <- sub("^(The|A|An) ", "", cap)
      cap <- paste0(tolower(substr(cap, 1, 1)), substring(cap, 2))
      verb <- if (kind == "fig") "shows" else "presents"
      x <- append(x, c(sprintf("%s %s %s the %s.", word, ref, verb, cap), ""), after = s - 1)
    }
    txt_all <- paste(x, collapse = "\n")
    if (kind == "fig") n_fig <- n_fig + 1 else n_tab <- n_tab + 1
  }

  # ---------- 2. theory links ----------
  this_chapter <- {
    h <- regmatches(x, regexec("^# [^(].*\\{#([A-Za-z0-9-]+)", x)); h <- unlist(lapply(h, `[`, 2)); h[!is.na(h)][1]
  }
  # anchors already linked earlier in this chapter (updated as we scan)
  linked <- character()
  in_chunk <- FALSE; in_yaml <- FALSE; cur_sec <- NA; in_math <- FALSE
  for (i in seq_along(x)) {
    ln <- x[i]
    if (i == 1 && ln == "---") { in_yaml <- TRUE; next }
    if (in_yaml) { if (ln == "---") in_yaml <- FALSE; next }
    if (grepl("^\\s*```", ln)) { in_chunk <- !in_chunk; next }
    if (in_chunk) next
    if (grepl("^\\$\\$", ln)) { if (!grepl("^\\$\\$.+\\$\\$\\s*$", ln)) in_math <- !in_math; next }
    if (in_math) next
    if (grepl("^#", ln)) {
      id <- regmatches(ln, regexec("\\{#([A-Za-z0-9-]+)", ln))[[1]]
      if (length(id) == 2 && grepl("^##? ", ln)) cur_sec <- id[2]
      next
    }
    if (grepl("^\\s*(:::|\\||<|!\\[)", ln) || grepl("^\\*\\*(Related theories|Origins|Key constructs)", ln)) next
    if (!nzchar(trimws(ln))) next
    explicit <- gsub("^\\]\\(#|\\)$", "", regmatches(ln, gregexpr("\\]\\(#[A-Za-z0-9-]+\\)", ln))[[1]])
    mk <- mask(ln); s <- mk$s
    hits <- gregexpr(big_pat, s, perl = TRUE)[[1]]
    if (hits[1] == -1) { linked <- c(linked, explicit); next }
    txts <- regmatches(s, list(hits))[[1]]
    changed <- FALSE
    # process right-to-left so earlier positions stay valid
    for (h in rev(seq_along(hits))) {
      a <- term_anchor[[tolower(txts[h])]]
      if (is.null(a) || identical(a, cur_sec)) next
      # only the first mention per chapter: skip if an earlier hit on this line has the same anchor
      if (a %in% linked || any(vapply(txts[seq_len(h - 1)], function(t) identical(term_anchor[[tolower(t)]], a), logical(1)))) next
      rep <- sprintf("[%s](#%s)", txts[h], a)
      if (!identical(pages[[a]], this_chapter)) rep <- sprintf("%s (%s)", rep, section_number_ref(a))
      s <- paste0(substr(s, 1, hits[h] - 1), rep, substr(s, hits[h] + attr(hits, "match.length")[h], nchar(s)))
      changed <- TRUE
    }
    new_anchors <- setdiff(unique(unlist(lapply(tolower(txts), function(t) term_anchor[[t]]))), cur_sec)
    linked <- c(linked, explicit, if (changed) new_anchors)
    if (changed) { x[i] <- unmask(s, mk$keep); n_link <- n_link + 1 }
  }

  # ---------- 3. numbered pointer after every cross-chapter link ----------
  in_chunk <- FALSE; in_yaml <- FALSE
  for (i in seq_along(x)) {
    ln <- x[i]
    if (i == 1 && ln == "---") { in_yaml <- TRUE; next }
    if (in_yaml) { if (ln == "---") in_yaml <- FALSE; next }
    if (grepl("^\\s*```", ln)) { in_chunk <- !in_chunk; next }
    if (in_chunk || grepl("^#", ln)) next
    m <- gregexpr("\\]\\(#([A-Za-z0-9-]+)\\)(?!\\s*\\((Section|Chapter) \\\\@ref)", ln, perl = TRUE)[[1]]
    if (m[1] == -1) next
    hits <- regmatches(ln, list(m))[[1]]
    for (h in rev(seq_along(m))) {
      a <- sub("^\\]\\(#([A-Za-z0-9-]+)\\)$", "\\1", hits[h])
      if (is.null(pages[a]) || is.na(pages[a]) || identical(unname(pages[a]), this_chapter)) next
      end <- m[h] + attr(m, "match.length")[h] - 1
      ln <- paste0(substr(ln, 1, end), " (", section_number_ref(a), ")", substr(ln, end + 1, nchar(ln)))
      n_link <- n_link + 1
    }
    x[i] <- ln
  }

  if (!identical(x, orig)) {
    if (dry) cat("would update", f, "\n") else {
      con <- file(f, open = "wb"); writeLines(enc2utf8(x), con, useBytes = TRUE); close(con)
      cat("updated", f, "\n")
    }
  }
}
cat(sprintf("Added %d figure refs, %d table refs, links on %d lines\n", n_fig, n_tab, n_link))
