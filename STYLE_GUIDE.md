# Style Guide: *Social Science Theory*

This guide keeps every chapter of the book consistent. Contributors
should read it before writing or editing a chapter. The exemplar chapter is
[`08-information.Rmd`](08-information.Rmd): when in doubt, match it.

## Voice and audience

- **Audience:** PhD students, faculty, and analytically minded practitioners in
  management, marketing, economics, psychology, sociology, and information systems.
- **Voice:** authoritative, precise, and readable, the tone of a top handbook
  chapter (*Annual Review*, *Academy of Management Annals*) with the clarity of a
  great textbook. Third person or inclusive "we". No hype, no emoji, no filler.
- **Every theory answers four questions:** *What* (constructs), *How* (relationships),
  *Why* (mechanism), and *Who/Where/When* (boundary conditions), Whetten (1989).
- Define a term in **bold** the first time it is used.
- Prefer short paragraphs (3-6 sentences), concrete examples, and explicit logic.

## Chapter template

```
# Chapter Title {#chapter-id}

Opening hook: a concrete puzzle from business or everyday life (1-2 paragraphs),
then what the chapter covers and why it matters.

Table: "Chapter at a glance" (theory | core question | level of analysis | key source).

## Theory Name {#theory-id}

::: {.theory-card}
**Core claim.** One or two sentences.

**Origins.** Who, when, which discipline [@key].

**Level of analysis.** Individual / dyad / group / firm / market / institution.

**Key constructs.** Construct A; Construct B; ...

**Boundary conditions.** When the theory should and should not hold.

**Related theories.** Links to other sections, e.g., [Agency theory](#agency-theory).
:::

### Origins and intellectual history
### Core logic and propositions          (numbered propositions P1, P2, ... where natural)
### Mechanism                            (a mechanism_diagram() or a ggplot figure)
### Evidence and extensions
::: {.debate}  critiques, boundary disputes, replication status  :::
### Applications in business
::: {.business-case}  a concrete, accurately described case  :::
### Using the theory in research
::: {.research-toolkit}  sample hypotheses, measures, designs, data sources  :::
::: {.pitfall}  the most common misuse of the theory  :::

(Repeat for each major theory. Minor theories/effects get a shorter treatment:
theory card + logic + example + one figure or table.)

## Chapter summary
::: {.key-takeaways}  5–8 bullets  :::
Comparison table of the chapter's theories.

## Discussion questions
5–6 numbered questions (mix of conceptual, research-design, and managerial).

## Further reading
4–8 annotated entries: [@key] — one sentence on why to read it.
```

Use `::: {.try-it}` for short exercises and `::: {.definition}` for formal definitions.

## Figures and tables (every chapter)

- **At least three figures per chapter**, of which at least one is a
  `ggplot2` figure and at least one a `mechanism_diagram()`.
- **At least three tables per chapter** via `book_table()`.
- All helpers live in `_common.R` (sourced automatically): `theme_book()` (default),
  `pal` (fixed categorical order, use `pal[["blue"]]`, `pal[["orange"]]`, … in
  that order. At most 3 colours in scatter-type plots), `ink`, `brand`,
  `scale_colour_book()`, `scale_fill_book()`, `scale_fill_seq()`, `scale_fill_div()`,
  `book_table()`, `mechanism_diagram()`, and node styles `node_construct`,
  `node_mechanism`, `node_outcome`, `node_moderator`.
- **Never present simulated data as empirical.** Figures built from simulated or
  stylised data must say "Illustrative" / "Stylised" in the caption and use
  `set.seed()`.
- Chunk labels are unique across the book: prefix with the chapter id,
  e.g. `fig-sig-timeline`, `tab-sig-glance`. Every figure has `fig.cap`, every
  table has `caption`. Cross-reference with `Figure \@ref(fig:fig-sig-timeline)`
  and `Table \@ref(tab:tab-sig-glance)`.
- Charts: one y-axis only (no dual axes), thin marks, direct labels where helpful,
  a legend when there are ≥ 2 series, text in ink colours (not series colours).
- Interactive widgets (`plotly`, `DT`, `visNetwork`) only inside
  `if (is_html())` guards so the PDF/EPUB builds do not break.
- `mechanism_diagram()` takes Graphviz node/edge statements, e.g.

  ```r
  mechanism_diagram(sprintf('
    A [label = "Signal cost", %s]
    B [label = "Separating\\nequilibrium", %s]
    C [label = "Receiver\\nbelief", %s]
    A -> B -> C
  ', node_construct, node_mechanism, node_outcome))
  ```

## Citations: accuracy is non-negotiable

- Pandoc syntax: `[@spence1973]`, `@spence1973 argues …`, `[@spence1973, p. 359]`.
- **Key convention:** lowercase first-author surname + year (+ `a`/`b` if needed),
  ASCII only: `spence1973`, `kahneman1979`, `dimaggio1983`.
- Keys that already exist in `references.bib` must be **reused exactly**
  (e.g. `Barney_2001`, `connelly2010`, `Berger_2016`).
- New entries go in `bib/<chapter-number>.bib` (e.g. `bib/08.bib`). They are
  merged and verified against Crossref at build time.
- **Only cite works you are certain exist**, with correct authors, year, title,
  venue, volume, issue and pages. Add `doi` only when certain of it. When unsure
  of a detail, cite a different, better-known source instead. Never fabricate a
  citation, quotation, page number, statistic, or effect size.
- Quote sparingly (< 40 words) and only with a page number you are sure of.
  Otherwise paraphrase.

## Business examples

- Prefer well-documented public cases (e.g., Opower home energy reports, Netflix vs.
  Blockbuster, Toyota Production System, Starbucks loyalty, Apple, Kodak, Airbnb
  reviews). Describe them at the level of established public record. Do not invent
  figures.
- Clearly label hypothetical cases as **"Illustrative scenario"** and keep their
  numbers obviously stylised.
- Each major theory gets at least one business case, ideally spanning different
  functions (marketing, strategy, HR, finance, operations, product, policy).

## House style: punctuation

- **No em dashes, en dashes, or semicolons** anywhere in reader-facing text:
  prose, captions, table cells, figure labels, and code-chunk strings. Use
  commas, colons, parentheses, or separate sentences instead. Use a hyphen
  for number ranges (pp. 39-67, 1990-2010).
- The only allowed semicolons are pandoc citation groups such as
  `[@spence1973; @akerlof1970]` (rendered with commas) and R code syntax.
- Run `Rscript tools/depunctuate.R <file>` to check and fix a chapter.
- No AI or tool attribution anywhere in the book, commits, or pull requests.

## Cross-reference IDs (use these exact anchors)

| Chapter | id | Section anchors |
|---|---|---|
| 1 Introduction | `intro` | `how-to-read`, `theory-map` |
| 2 What is theory | `what-is-theory` | `theory-building-blocks`, `theory-criteria`, `levels-of-analysis` |
| 3 Using theory | `using-theory` | `from-theory-to-hypotheses`, `mediation-moderation`, `choosing-theory`, `replication-crisis` |
| 4 Resources | `resources` | `resource-based-theory`, `vrio`, `knowledge-based-view`, `resource-advantage-theory`, `market-based-assets` |
| 5 Dynamic capabilities | `dynamic-capabilities` | `dynamic-capabilities-framework`, `absorptive-capacity`, `exploration-exploitation`, `ambidexterity` |
| 6 Governance | `governance` | `agency-theory`, `stewardship-theory`, `transaction-cost-economics`, `upper-echelons-theory` |
| 7 Environment | `environment` | `resource-dependence-theory`, `institutional-theory`, `legitimacy`, `stakeholder-theory`, `organizational-ecology`, `contingency-theory`, `csr-pyramid`, `shared-value` |
| 8 Information | `information` | `information-asymmetry`, `signaling-theory`, `screening-theory`, `costly-signaling`, `identity-signaling`, `countersignaling` |
| 9 Networks & exchange | `networks-exchange` | `social-exchange-theory`, `network-exchange-theory`, `weak-ties`, `structural-holes`, `social-capital`, `commitment-trust-theory` |
| 10 Innovation & adoption | `innovation-adoption` | `diffusion-of-innovations`, `bass-model`, `theory-of-planned-behavior`, `technology-acceptance-model`, `utaut`, `is-success-model`, `task-technology-fit` |
| 11 Strategy & competition | `strategy-competition` | `structure-conduct-performance`, `strategic-groups`, `competitive-dynamics`, `game-theory`, `first-mover-advantage`, `real-options-theory`, `behavioral-theory-of-the-firm`, `attention-based-view` |
| 12 Innovation & entrepreneurship | `innovation-entrepreneurship` | `creative-destruction`, `disruptive-innovation`, `profiting-from-innovation`, `architectural-innovation`, `dominant-design`, `open-innovation`, `effectuation`, `opportunity-discovery-creation`, `bricolage`, `liability-of-newness` |
| 13 International business | `international-business` | `uppsala-model`, `oli-paradigm`, `internalization-theory`, `liability-of-foreignness`, `institutional-voids`, `born-globals` |
| 14 Organizations & decisions | `organizations-decisions` | `garbage-can-model`, `escalation-of-commitment`, `organizational-learning`, `knowledge-creation`, `organizational-identity`, `organizational-culture`, `paradox-theory`, `psychological-safety`, `attraction-selection-attrition`, `social-information-processing`, `sensemaking` |
| 15 Work & leadership | `work-leadership` | `job-characteristics-model`, `job-demands-resources`, `conservation-of-resources`, `affective-events-theory`, `leader-member-exchange`, `transformational-leadership`, `path-goal-theory`, `psychological-contract`, `organizational-justice`, `organizational-commitment`, `person-environment-fit`, `human-capital-theory`, `tournament-theory` |
| 16 Finance | `finance` | `portfolio-theory`, `capm`, `efficient-market-hypothesis`, `modigliani-miller`, `trade-off-pecking-order`, `free-cash-flow`, `limits-to-arbitrage`, `behavioral-finance` |
| 17 Economics & institutions | `economics-institutions` | `coase-theorem`, `collective-action`, `property-rights-theory`, `search-theory`, `efficiency-wages`, `network-effects`, `two-sided-markets`, `auction-theory`, `new-institutional-economics`, `social-preferences` |
| 18 Culture | `culture` | `hofstede`, `power-distance-theory`, `globe`, `schwartz-values`, `tight-loose`, `self-construal` |
| 19 Motivation | `motivation` | `expectancy-theory`, `equity-theory`, `goal-setting-theory`, `goal-gradient-hypothesis`, `self-determination-theory`, `losing-leads-to-winning` |
| 20 Self-regulation | `self-regulation` | `regulatory-focus-theory`, `regulatory-fit`, `construal-level-theory`, `self-control` |
| 21 Attitudes & attribution | `attitudes-attribution` | `cognitive-dissonance-theory`, `self-perception-theory`, `attribution-theory`, `balance-theory`, `social-cognitive-theory`, `reactance-theory` |
| 22 Social influence | `social-influence` | `social-comparison-theory`, `social-identity-theory`, `optimal-distinctiveness-theory`, `conformity`, `social-norms`, `social-facilitation`, `distraction-conflict-theory`, `spiral-of-silence` |
| 23 Judgment & decision | `judgment-decision` | `bounded-rationality`, `heuristics-biases`, `prospect-theory-overview`, `endowment-effect`, `mental-accounting`, `dual-process-theory`, `feelings-as-information-theory`, `processing-fluency`, `discrepancy-attribution-hypothesis`, `choice-architecture` |
| 24 Prospect theory | `prospect-theory` | `expected-utility-theory`, `prospect-theory-model`, `cumulative-prospect-theory`, `loss-aversion`, `reference-dependent-preferences`, `status-quo-bias`, `myopic-loss-aversion`, `disposition-effect` |
| 25 Emotion & well-being | `emotion-wellbeing` | `broaden-and-build-theory`, `hedonic-adaptation`, `affect-circumplex`, `emotion-and-virality`, `appraisal-theory`, `peak-end-rule` |
| 26 Persuasion & communication | `persuasion-communication` | `elaboration-likelihood-model`, `persuasion-knowledge-model`, `social-transmission`, `agenda-setting`, `framing-theory`, `uses-and-gratifications`, `microblogging` |
| 27 Consumer behavior & branding | `consumer-behavior` | `expectancy-disconfirmation`, `means-end-chain`, `customer-based-brand-equity`, `brand-personality`, `consumer-brand-relationships`, `self-congruity`, `schema-congruity`, `hedonic-utilitarian`, `psychological-ownership`, `variety-seeking`, `reference-price`, `consumer-culture-theory` |
| 28 Marketing strategy & services | `marketing-strategy` | `market-orientation`, `service-dominant-logic`, `service-quality-gap-model`, `customer-equity`, `hierarchy-of-effects`, `product-life-cycle`, `marketing-mix` |
| 29 Effects | `effects` | `mere-exposure-effect`, `warm-glow-heuristic`, `goldilocks-effect`, `coolidge-effect`, `snob-effect`, `glass-cliff-effect`, `ikea-effect`, `decoy-effect`, `anchoring-effect`, `beauty-in-averageness`, `pratfall-effect` |
| 30 Phenomena | `phenomena` | `similarity-asymmetry`, `homophily`, `assortative-mating`, `social-magnet`, `wisdom-of-the-crowd`, `pack-journalism`, `scent-and-emotion`, `matthew-effect`, `social-loafing`, `bystander-effect`, `tragedy-of-the-commons`, `groupthink`, `bullwhip-effect` |
| 31 Frameworks | `frameworks` | `information-processing-model`, `geneplore-model`, `five-forces`, `combinatorial-creativity`, `sor-framework`, `mechanism-toolkit` |
| 32 Theory atlas | `theory-atlas` | `atlas-table`, `atlas-mechanisms`, `glossary` |

Write section headers as `## Signaling Theory {#signaling-theory}`.

## Checking a chapter

```bash
"/c/Program Files/R/R-4.4.3/bin/Rscript.exe" tools/check_chapter.R 08-information.Rmd
```

This knits the chapter in isolation (into `_scratch/`), reports R errors, and
lists any citation keys missing from `references.bib` + `bib/*.bib`.
