#!/usr/bin/env Rscript
# tools/make_images.R -- generates the book cover, the social-share card, and the
# apple-touch icon from the Theory Atlas. Run from the repo root:
#   Rscript tools/make_images.R
# Uses Windows system fonts (Georgia, Segoe UI); adjust `serif`/`sans` elsewhere.

suppressPackageStartupMessages({
  library(ggplot2); library(dplyr); library(igraph); library(ragg)
})

serif <- "Georgia"
sans  <- "Segoe UI"
navy  <- "#0f2a44"
part_levels <- c("Foundations", "Organizations & Strategy", "Markets, Finance & Economics",
                 "Individuals & Groups", "Consumers & Marketing", "Effects, Phenomena & Frameworks")
part_cols <- setNames(c("#9085e9", "#5aa2ef", "#f2b84b", "#f08a5d", "#ee9bbd", "#3cc59a"), part_levels)

atlas <- readr::read_csv("data/theory-atlas.csv", show_col_types = FALSE)

# A constellation: theories sharing a mechanism are linked in a ring, plus a few
# cross-mechanism bridges, laid out with a force-directed algorithm.
set.seed(1973)
# Edges = the book's own cross-references: a link inside one entry's section to
# another entry's anchor (same rule as the theory map in Chapter 1).
files <- yaml::read_yaml("_bookdown.yml")$rmd_files
files <- files[file.exists(files)]
edges <- bind_rows(lapply(files, function(f) {
  cur <- NA_character_; out <- list()
  for (ln in readLines(f, warn = FALSE, encoding = "UTF-8")) {
    h <- regmatches(ln, regexec("^#{2,3} .*\\{#([A-Za-z0-9-]+)", ln))[[1]]
    if (length(h) == 2 && h[2] %in% atlas$anchor) cur <- h[2]
    if (!is.na(cur)) {
      l <- gsub("^\\]\\(#|\\)$", "", regmatches(ln, gregexpr("\\]\\(#[A-Za-z0-9-]+\\)", ln))[[1]])
      l <- l[l %in% atlas$anchor & l != cur]
      if (length(l)) out[[length(out) + 1]] <- data.frame(from = cur, to = l)
    }
  }
  bind_rows(out)
}))
edges <- distinct(edges, a = pmin(from, to), b = pmax(from, to)) |> rename(from = a, to = b)
g <- graph_from_data_frame(edges, vertices = atlas[, c("anchor", "part")], directed = FALSE)
g <- induced_subgraph(g, which(degree(g) > 0))
xy <- layout_with_fr(g, niter = 3000)
xy <- apply(xy, 2, function(v) 2 * (v - min(v)) / (max(v) - min(v)) - 1)   # fit to [-1, 1]
nodes <- data.frame(anchor = V(g)$name, part = V(g)$part, x = xy[, 1], y = xy[, 2])
nodes$deg <- pmin(sqrt(degree(g)), 4.5)   # damp hubs so no single node dominates
el <- as_edgelist(g)
segs <- data.frame(x = nodes$x[match(el[, 1], nodes$anchor)], y = nodes$y[match(el[, 1], nodes$anchor)],
                   xend = nodes$x[match(el[, 2], nodes$anchor)], yend = nodes$y[match(el[, 2], nodes$anchor)])

constellation <- function(point_scale = 1) {
  list(
    geom_segment(data = segs, aes(x, y, xend = xend, yend = yend),
                 colour = "#ffffff", alpha = 0.16, linewidth = 0.35 * point_scale),
    geom_point(data = nodes, aes(x, y, colour = part), size = (4 + 1.6 * nodes$deg) * point_scale, alpha = 0.18),
    geom_point(data = nodes, aes(x, y, colour = part), size = (1.3 + 0.55 * nodes$deg) * point_scale),
    scale_colour_manual(values = part_cols, guide = "none")
  )
}

# ---- Cover (1600 x 2400) ------------------------------------------------------
cover <- ggplot() +
  constellation(point_scale = 1.15) +
  coord_cartesian(xlim = c(-1.12, 1.12), ylim = c(-1.12, 1.12), expand = FALSE) +
  annotate("text", x = -2.15, y = 4.55 - 6.2 + 4.2, label = "", colour = "white") +
  theme_void() +
  theme(plot.background = element_rect(fill = navy, colour = NA),
        plot.margin = margin(0, 0, 0, 0))
title_layer <- ggplot() +
  annotate("text", x = 0.07, y = 0.93, label = "SOCIAL\nSCIENCE\nTHEORY", hjust = 0, vjust = 1,
           family = serif, fontface = "bold", size = 30, colour = "white", lineheight = 0.88) +
  annotate("segment", x = 0.075, xend = 0.30, y = 0.637, yend = 0.637, colour = "#f08a5d", linewidth = 2.2) +
  annotate("text", x = 0.07, y = 0.612, hjust = 0, vjust = 1, family = sans, size = 7.6, colour = "#d6e3f0",
           lineheight = 1.15,
           label = "A Field Guide to the Theories, Effects,\nand Frameworks Behind Research and Business") +
  annotate("text", x = 0.07, y = 0.05, hjust = 0, family = sans, fontface = "bold", size = 10,
           colour = "white", label = "MIKE NGUYEN") +
  annotate("text", x = 0.93, y = 0.05, hjust = 1, family = sans, size = 6.2,
           colour = "#9fb4c9", label = "150+ theories · open access") +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  theme_void()

dir.create("images", showWarnings = FALSE)
agg_png("images/cover.png", width = 1600, height = 2400, res = 200, background = navy)
grid::grid.newpage()
print(cover, vp = grid::viewport(x = 0.5, y = 0.27, width = 1, height = 0.38))
print(title_layer, vp = grid::viewport(x = 0.5, y = 0.5, width = 1, height = 1))
invisible(dev.off())

# ---- Social card (1280 x 640) ------------------------------------------------
card_art <- ggplot() + constellation(point_scale = 0.75) +
  coord_cartesian(xlim = c(-1.1, 1.1), ylim = c(-1.1, 1.1), expand = FALSE) +
  theme_void() + theme(plot.background = element_rect(fill = navy, colour = NA))
card_text <- ggplot() +
  annotate("text", x = 0.05, y = 0.90, label = "Social Science\nTheory", hjust = 0, vjust = 1,
           family = serif, fontface = "bold", size = 15, colour = "white", lineheight = 0.9) +
  annotate("segment", x = 0.052, xend = 0.2, y = 0.585, yend = 0.585, colour = "#f08a5d", linewidth = 1.6) +
  annotate("text", x = 0.05, y = 0.52, hjust = 0, vjust = 1, family = sans, size = 5.8, colour = "#d6e3f0",
           lineheight = 1.1,
           label = "150+ theories, 200+ entries in all,\nwith mechanisms, evidence, critiques,\nbusiness cases, and research hypotheses") +
  annotate("text", x = 0.05, y = 0.1, hjust = 0, family = sans, fontface = "bold", size = 5.2,
           colour = "white", label = "Mike Nguyen  ·  free & open source") +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) + theme_void()
agg_png("images/social-card.png", width = 1280, height = 640, res = 144, background = navy)
grid::grid.newpage()
print(card_art, vp = grid::viewport(x = 0.80, y = 0.5, width = 0.40, height = 0.92))
print(card_text, vp = grid::viewport(x = 0.5, y = 0.5, width = 1, height = 1))
invisible(dev.off())

# ---- Apple touch icon (180 x 180) -----------------------------------------------
icon <- ggplot() + constellation(point_scale = 0.22) +
  coord_cartesian(xlim = c(-1.1, 1.1), ylim = c(-1.1, 1.1), expand = FALSE) +
  theme_void() + theme(plot.background = element_rect(fill = navy, colour = NA))
agg_png("images/apple-touch-icon.png", width = 180, height = 180, res = 72, background = navy)
print(icon)
invisible(dev.off())
cat("Wrote images/cover.png, images/social-card.png, images/apple-touch-icon.png\n")
