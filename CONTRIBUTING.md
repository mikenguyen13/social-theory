# Contributing to *Social Science Theory*

Thank you for helping improve the book. Contributions of every size are welcome:
typo fixes, clearer explanations, better business examples, new theories,
figures, and translations.

## Quick fixes

Every page of the online book has an **Edit this page** link. It opens the
source file on GitHub, where you can propose a change in your browser.

## Suggesting a theory or reporting an error

Open an [issue](https://github.com/mikenguyen13/social-theory/issues/new/choose)
using the *Suggest a theory* or *Report an error* template. For factual or
citation errors, please include the source that supports the correction.

## Larger contributions

1. Read the [style guide](STYLE_GUIDE.md) and the exemplar chapter
   [`08-information.Rmd`](08-information.Rmd).
2. Fork the repository and create a branch.
3. Write or edit the chapter. Add new references to the chapter's own
   `bib/NN.bib` file (key format: `surnameYEAR`, e.g. `spence1973`).
4. Check your chapter:
   ```bash
   Rscript tools/check_chapter.R 08-information.Rmd
   ```
5. If you add a theory, add a row to [`data/theory-atlas.csv`](data/theory-atlas.csv)
   so it appears in the Theory Atlas and the interactive theory map.
6. Open a pull request describing what changed and why.

## Standards

- **Accuracy first.** Cite only sources you have read or verified. Never invent
  statistics, quotations, or page numbers. References are checked against
  Crossref (`tools/verify_refs.R`).
- **Balance.** Present critiques and replication evidence alongside the theory.
- **Respect.** Be kind and constructive in issues and reviews.
