<p align="center">
  <a href="https://mikenguyen13.github.io/social-theory"><img src="images/social-card.png" alt="Social Science Theory: a field guide to 100+ theories, effects, and frameworks" width="100%"></a>
</p>

<h1 align="center">Social Science Theory</h1>

<p align="center">
  <b>A free, open-source field guide to the theories, effects, and frameworks behind research and business.</b><br>
  100+ entries · mechanism diagrams · evidence & critiques · business cases · ready-to-use hypotheses
</p>

<p align="center">
  <a href="https://mikenguyen13.github.io/social-theory"><img alt="Read the book" src="https://img.shields.io/badge/read-the%20book-1f4e79?style=for-the-badge"></a>
  <a href="https://github.com/mikenguyen13/social-theory/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/mikenguyen13/social-theory?style=for-the-badge&color=eda100"></a>
  <a href="https://github.com/mikenguyen13/social-theory/actions/workflows/book.yml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/mikenguyen13/social-theory/book.yml?branch=master&style=for-the-badge&label=build"></a>
  <a href="CONTRIBUTING.md"><img alt="PRs welcome" src="https://img.shields.io/badge/PRs-welcome-1baf7a?style=for-the-badge"></a>
</p>

---

Every field has theories its members "just know", **signaling**, **agency**,
**the resource-based view**, **prospect theory**, **social identity**,
**diffusion of innovations**, and newcomers are expected to absorb them one paper
at a time. This book puts them in one place, in one consistent format, with the
depth researchers need and the examples practitioners want.

> **Read it online:** **[mikenguyen13.github.io/social-theory](https://mikenguyen13.github.io/social-theory/)**  
> Mirror: [Posit Connect Cloud](https://01a17b63-f04b-c542-bc6c-ece12120ea40.share.connect.posit.cloud/)

## Why this book

- **Systematic.** Each theory gets a *theory card* (core claim, origins, level of
  analysis, constructs, boundary conditions, related theories) so you can compare
  theories at a glance.
- **Rigorous.** Core logic and propositions, mechanism diagrams, empirical
  evidence, critiques, and replication status: with references to the original
  sources.
- **Practical.** Business cases across strategy, marketing, finance, HR,
  operations, and policy show where each theory earns its keep.
- **Research-ready.** Every major theory includes a *research toolkit*: sample
  hypotheses, operationalizations, designs, and data sources.
- **Visual and reproducible.** 60+ figures and diagrams, all generated from R code
  in this repository, plus an interactive theory map and a searchable
  [Theory Atlas](data/theory-atlas.csv).

## What's inside

| Part | Chapters |
|---|---|
| **Foundations** | 1 Introduction · 2 What Is a Theory? · 3 Using Theory in Research and Practice |
| **Organizations & Strategy** | 4 Resources and Competitive Advantage (RBV, VRIO, KBV, R-A theory) · 5 Dynamic Capabilities, Learning, and Renewal · 6 Governance, Contracts, and Leadership (agency, stewardship, TCE, upper echelons) · 7 Organizations and Their Environments (resource dependence, institutional, stakeholder, ecology) · 8 Information, Signals, and Markets · 9 Social Exchange and Networks · 10 Innovation Diffusion and Technology Adoption |
| **Individuals & Groups** | 11 Culture · 12 Motivation · 13 Self-Regulation and Construal · 14 Social Comparison, Identity, and Influence · 15 Judgment and Decision Making · 16 Emotion and Well-Being · 17 Persuasion and Communication |
| **Effects, Phenomena & Frameworks** | 18 Named Effects (mere exposure, decoy, IKEA, glass cliff, …) · 19 Social Phenomena (wisdom of crowds, Matthew effect, groupthink, …) · 20 Models and Frameworks · 21 Theory Atlas & Glossary |

## A taste: the theory card

> **Signaling theory**
> **Core claim.** An informed party can credibly convey unobservable quality by taking a costly, observable action that low-quality types would find too expensive to imitate.
> **Origins.** Spence (1973), *Quarterly Journal of Economics*.
> **Level of analysis.** Dyad and market.
> **Boundary conditions.** Quality is unobservable ex ante. Signal cost is negatively correlated with quality. Receivers can observe and interpret the signal.
> **Business use.** Warranties, credentials, IPO underwriters, verified-seller badges.

## Who it's for

- **PhD students** looking for a map of the theoretical landscape and a fast way
  to find the right lens for a research question.
- **Faculty** who want a free, citable companion text for seminars in management,
  marketing, organizational behaviour, consumer behaviour, and economic sociology.
- **Practitioners**, strategists, marketers, product managers, analysts, HR
  leaders, consultants, who want to know *why* an intervention works and when it
  will stop working.

## Build the book locally

Requirements: R (≥ 4.2) and the packages below. Pandoc ships with RStudio/Positron
or Quarto.

```r
install.packages(c("bookdown", "rmarkdown", "knitr", "ggplot2", "dplyr", "tidyr",
                   "kableExtra", "DiagrammeR", "visNetwork", "DT", "igraph", "ggraph",
                   "readr", "tibble", "scales", "patchwork", "ggrepel", "yaml",
                   "bslib", "downlit", "xml2", "ragg"))
source("tools/merge_bib.R")                        # merge bib/*.bib -> references.bib
bookdown::render_book("index.Rmd", "bookdown::bs4_book")
```

The site is written to `docs/`. Check a single chapter quickly with
`Rscript tools/check_chapter.R 08-information.Rmd`.

## Cite this book

```bibtex
@book{nguyen_social_theory,
  author = {Nguyen, Mike},
  title  = {Social Science Theory: A Field Guide to the Theories, Effects,
            and Frameworks Behind Research and Business},
  year   = {2026},
  url    = {https://github.com/mikenguyen13/social-theory}
}
```

GitHub's **"Cite this repository"** button (from [`CITATION.cff`](CITATION.cff))
gives APA and BibTeX formats.

## Contribute

Found an error? Want to add a theory, a better business example, or a
translation? Contributions are very welcome: see
[CONTRIBUTING.md](CONTRIBUTING.md) and the [style guide](STYLE_GUIDE.md), or
[suggest a theory](https://github.com/mikenguyen13/social-theory/issues/new/choose).

If this book helps you, **please ⭐ the repository**: it is the simplest way to
help other students and researchers find it.

## Related

- *A Guide on Data Analysis*: the author's companion book on statistics, causal
  inference, and research methods.
