# _common.R -- sourced before every chapter (see before_chapter_script in _bookdown.yml).
# Shared knitr options, a single figure theme, a validated categorical palette,
# and small helpers so every chapter looks like part of one book.

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(knitr)
  library(kableExtra)
})

knitr::opts_chunk$set(
  echo = FALSE,
  message = FALSE,
  warning = FALSE,
  comment = "#>",
  fig.align = "center",
  fig.width = 7,
  fig.height = 4.2,
  out.width = "100%",
  dpi = 200,
  dev = if (requireNamespace("ragg", quietly = TRUE)) "ragg_png" else "png",
  fig.retina = 1,
  cache = FALSE
)

options(knitr.kable.NA = "", dplyr.summarise.inform = FALSE)

is_html <- function() knitr::is_html_output(excludes = "epub")

# Captions are written into raw LaTeX by knitr/kable, so escape LaTeX specials.
latex_escape_caption <- function(x) if (!is.character(x)) x else gsub("([&%#])", "\\\\\\1", x)
knitr::opts_hooks$set(fig.cap = function(options) {
  if (knitr::is_latex_output()) {
    options$fig.cap <- latex_escape_caption(options$fig.cap)
    if (is.null(options$fig.pos) || !nzchar(options$fig.pos)) options$fig.pos <- "!htb"
    if (identical(options$out.width, "100%")) options$out.width <- "88%"
    options$dev <- "cairo_pdf"          # vector figures with embedded fonts
  }
  options
})

# ---- Palette -----------------------------------------------------------------
# Categorical order is fixed (never cycled). Validated for colour-vision
# deficiency on adjacent pairs; scatter-type plots should use at most 3 slots.
pal <- c(
  blue    = "#2a78d6",
  orange  = "#eb6834",
  aqua    = "#1baf7a",
  yellow  = "#eda100",
  magenta = "#e87ba4",
  green   = "#008300",
  violet  = "#6250d6",
  red     = "#e34948"
)
ink <- c(primary = "#0b0b0b", secondary = "#52514e", muted = "#8a8984",
         grid = "#e6e5e1", surface = "#ffffff")
brand <- "#1f4e79"

# Parts of the book (used by the theory map, the atlas, and the preface).
part_levels <- c("Foundations", "Organizations & Strategy", "Markets, Finance & Economics",
                 "Individuals & Groups", "Consumers & Marketing",
                 "Effects, Phenomena & Frameworks")
part_cols <- setNames(unname(pal[c("violet", "blue", "yellow", "orange", "magenta", "aqua")]),
                      part_levels)
part_chapters <- setNames(c("1-3", "4-15", "16-17", "18-26", "27-28", "29-31"), part_levels)

# Sequential (magnitude) and diverging (polarity) helpers.
scale_fill_seq <- function(...) scale_fill_gradient(low = "#dceaf8", high = "#1f4e79", ...)
scale_fill_div <- function(...) scale_fill_gradient2(low = pal[["orange"]], mid = "#f2f1ee",
                                                     high = pal[["blue"]], midpoint = 0, ...)
scale_colour_book <- function(...) scale_colour_manual(values = unname(pal), ...)
scale_fill_book <- function(...) scale_fill_manual(values = unname(pal), ...)

# ---- Figure theme ------------------------------------------------------------
theme_book <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      text = element_text(colour = ink[["primary"]]),
      plot.title = element_text(face = "bold", size = rel(1.1), margin = margin(b = 4)),
      plot.subtitle = element_text(colour = ink[["secondary"]], margin = margin(b = 10)),
      plot.caption = element_text(colour = ink[["muted"]], size = rel(0.75), hjust = 0),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      axis.title = element_text(colour = ink[["secondary"]], size = rel(0.9)),
      axis.text = element_text(colour = ink[["secondary"]]),
      panel.grid.major = element_line(colour = ink[["grid"]], linewidth = 0.3),
      panel.grid.minor = element_blank(),
      legend.position = "top",
      legend.justification = "left",
      legend.title = element_text(colour = ink[["secondary"]], size = rel(0.85)),
      strip.text = element_text(face = "bold", hjust = 0),
      plot.margin = margin(8, 12, 8, 8)
    )
}
theme_set(theme_book())
update_geom_defaults("line", list(linewidth = 0.9))
update_geom_defaults("point", list(size = 2.4))

# ---- Tables ------------------------------------------------------------------
# book_table(): one consistent look for every table in the book.
book_table <- function(df, caption = NULL, col.names = NA, align = NULL,
                       full_width = TRUE, font_size = NULL, ...) {
  # Markdown links such as [Agency theory](#agency-theory) are allowed in cells.
  md_link <- "\\[([^]]+)\\]\\(([^)]+)\\)"
  if (is_html()) {
    # Plain HTML kable + Bootstrap classes. (kableExtra::kable_styling duplicates
    # bookdown's table numbers in bs4_book, so it is avoided for HTML.)
    df[] <- lapply(df, function(x) {
      if (!is.character(x)) return(x)
      gsub(md_link, '<a href="\\2">\\1</a>', htmltools::htmlEscape(x))
    })
    cls <- paste("table table-sm table-striped table-hover book-table",
                 if (!full_width) "w-auto" else "")
    return(knitr::kable(df, format = "html", caption = caption, col.names = col.names,
                        align = align, escape = FALSE,
                        table.attr = sprintf('class="%s"', cls), ...))
  }
  df[] <- lapply(df, function(x) if (is.character(x)) gsub(md_link, "\\1", x) else x)
  if (knitr::is_latex_output()) {
    # Print layout: long tables break across pages, header repeats, and column
    # widths are proportional to content so text wraps instead of shrinking.
    nc <- ncol(df)
    len <- vapply(seq_len(nc), function(j) {
      v <- c(if (length(col.names) == nc && !all(is.na(col.names))) col.names[j] else names(df)[j], as.character(df[[j]]))
      min(max(nchar(v), na.rm = TRUE), 60)
    }, numeric(1))
    len <- pmax(len, 6)
    total_cm <- 15.5 - 0.4 * nc
    w <- total_cm * len / sum(len)
    # never narrower than the longest single word in the column (about 0.17cm per character)
    word <- vapply(seq_len(nc), function(j) {
      v <- c(names(df)[j], as.character(df[[j]]))
      max(nchar(unlist(strsplit(v, "[[:space:]/]+"))), 1, na.rm = TRUE)
    }, numeric(1))
    minw <- pmin(word * 0.17 + 0.1, total_cm / 2)
    for (k in 1:3) {
      short <- w < minw
      if (!any(short)) break
      w[short] <- minw[short]
      free <- !short
      if (any(free)) w[free] <- w[free] * (total_cm - sum(w[short])) / sum(w[free])
    }
    widths <- sprintf("%.2fcm", w)
    out <- knitr::kable(df, format = "latex", caption = latex_escape_caption(caption), col.names = col.names, align = align,
                        booktabs = TRUE, longtable = TRUE, escape = TRUE, ...)
    out <- kableExtra::kable_styling(out, latex_options = c("repeat_header"), font_size = 8.5,
                                     repeat_header_text = "\\textit{(continued)}")
    for (j in seq_len(nc)) out <- kableExtra::column_spec(out, j, width = widths[j])
    return(out)
  }
  out <- knitr::kable(df, caption = caption, col.names = col.names, align = align,
                      booktabs = TRUE, escape = TRUE, ...)
  out
}

# anchor_pages(): map every section anchor to the bs4_book page that holds it
# (one page per chapter, named after the chapter id).
anchor_pages <- function() {
  files <- yaml::read_yaml("_bookdown.yml")$rmd_files
  files <- files[file.exists(files)]
  out <- character()
  for (f in files) {
    x <- readLines(f, warn = FALSE, encoding = "UTF-8")
    ch <- regmatches(x, regexec("^# [^(].*\\{#([A-Za-z0-9-]+)", x))
    ch <- unlist(lapply(ch, `[`, 2))
    if (!length(ch)) next
    ids <- unlist(lapply(regmatches(x, regexec("^#{1,4} .*\\{#([A-Za-z0-9-]+)", x)), `[`, 2))
    out[ids[!is.na(ids)]] <- ch[1]
  }
  out
}

# ---- Diagrams ----------------------------------------------------------------
# mechanism_diagram(): Graphviz causal/mechanism diagrams in the book's style.
# `dot` is the body of a digraph (nodes and edges only). HTML output only;
# other formats get a short note instead.
mechanism_diagram <- function(dot, rankdir = "LR", height = NULL) {
  spec <- sprintf('digraph {
    graph [rankdir = %s, bgcolor = "transparent", fontname = "Helvetica", nodesep = 0.35, ranksep = 0.45, pad = 0.2]
    node  [shape = box, style = "rounded,filled", fillcolor = "#eef4fb", color = "#1f4e79",
           fontname = "Helvetica", fontsize = 12, fontcolor = "#0b0b0b", penwidth = 1.2, margin = "0.18,0.08"]
    edge  [color = "#52514e", arrowsize = 0.7, fontname = "Helvetica", fontsize = 10, fontcolor = "#52514e"]
    %s
  }', rankdir, dot)
  if (!is_html()) return(static_diagram(spec))
  if (is.null(height)) height <- if (rankdir %in% c("LR", "RL")) 320 else 460
  DiagrammeR::grViz(spec, height = height)
}

# static_diagram(): render Graphviz to a vector PDF (print) or PNG (EPUB) with the
# viz.js engine bundled in DiagrammeR, so diagrams appear in every edition.
static_diagram <- local({
  ctx <- NULL
  counter <- 0
  function(spec) {
    if (is.null(ctx)) {
      ctx <<- V8::v8()
      ctx$source(system.file("htmlwidgets/lib/viz/viz.js", package = "DiagrammeR"))
    }
    svg <- ctx$call("Viz", spec)
    # Pad narrow diagrams to the text width (about 460pt) so out.width = 100%
    # keeps them at natural size instead of enlarging them.
    w <- suppressWarnings(as.numeric(sub('(?s).*<svg width="([0-9.]+)pt".*', "\\1", svg, perl = TRUE)))
    vb <- suppressWarnings(as.numeric(strsplit(sub('(?s).*viewBox="([^"]+)".*', "\\1", svg, perl = TRUE), " ")[[1]]))
    target <- 460
    if (!is.na(w) && length(vb) == 4 && w < target) {
      pad <- (target - w) / 2 * (vb[3] / w)
      svg <- sub('<svg width="[0-9.]+pt"', sprintf('<svg width="%.2fpt"', target), svg)
      svg <- sub('viewBox="[^"]+"', sprintf('viewBox="%.2f %.2f %.2f %.2f"', vb[1] - pad, vb[2], vb[3] + 2 * pad, vb[4]), svg)
    }
    counter <<- counter + 1
    latex <- knitr::is_latex_output()
    path <- knitr::fig_path(paste0("-dot", counter, if (latex) ".pdf" else ".png"))
    dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
    if (latex) rsvg::rsvg_pdf(charToRaw(svg), path) else rsvg::rsvg_png(charToRaw(svg), path, width = 1600)
    knitr::include_graphics(path)
  }
})

# Node fill helpers for mechanism diagrams (use inside `dot` strings).
node_construct <- 'fillcolor = "#eef4fb", color = "#1f4e79"'
node_mechanism <- 'fillcolor = "#fff4e5", color = "#eb6834"'
node_outcome   <- 'fillcolor = "#e8f6ef", color = "#1baf7a"'
node_moderator <- 'shape = ellipse, fillcolor = "#f4f0ff", color = "#6250d6"'
