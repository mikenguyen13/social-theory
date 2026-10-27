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
  out <- knitr::kable(df, caption = caption, col.names = col.names, align = align,
                      booktabs = TRUE, escape = TRUE, ...)
  if (knitr::is_latex_output()) {
    out <- kableExtra::kable_styling(out, latex_options = c("hold_position", "scale_down"))
  }
  out
}

# ---- Diagrams ----------------------------------------------------------------
# mechanism_diagram(): Graphviz causal/mechanism diagrams in the book's style.
# `dot` is the body of a digraph (nodes and edges only). HTML output only;
# other formats get a short note instead.
mechanism_diagram <- function(dot, rankdir = "LR", height = NULL) {
  if (!is_html()) return(knitr::asis_output("*(Interactive diagram available in the online edition.)*"))
  spec <- sprintf('digraph {
    graph [rankdir = %s, bgcolor = "transparent", fontname = "Helvetica", nodesep = 0.35, ranksep = 0.45, pad = 0.2]
    node  [shape = box, style = "rounded,filled", fillcolor = "#eef4fb", color = "#1f4e79",
           fontname = "Helvetica", fontsize = 12, fontcolor = "#0b0b0b", penwidth = 1.2, margin = "0.18,0.08"]
    edge  [color = "#52514e", arrowsize = 0.7, fontname = "Helvetica", fontsize = 10, fontcolor = "#52514e"]
    %s
  }', rankdir, dot)
  if (is.null(height)) height <- if (rankdir %in% c("LR", "RL")) 320 else 460
  DiagrammeR::grViz(spec, height = height)
}

# Node fill helpers for mechanism diagrams (use inside `dot` strings).
node_construct <- 'fillcolor = "#eef4fb", color = "#1f4e79"'
node_mechanism <- 'fillcolor = "#fff4e5", color = "#eb6834"'
node_outcome   <- 'fillcolor = "#e8f6ef", color = "#1baf7a"'
node_moderator <- 'shape = ellipse, fillcolor = "#f4f0ff", color = "#6250d6"'
