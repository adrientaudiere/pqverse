# Preferred pqverse idioms (developer guide)

> **Status:** developer-only, living document. Not part of the package
> documentation or pkgdown site. Its purpose is to settle the recurring
> question *"there are several ways to do this across the pqverse — which one
> do we use?"* so that human- and AI-written code stops drifting between
> idioms.
>
> To propose a change, edit this file and flag it to the maintainer; the
> golden rule below is the tie-breaker for anything not covered explicitly.

## The golden rule

Each pqverse package owns one job. When an operation could be done in more than
one package, route it by *what the operation is*, not by which function you
remember first:

| You are… | Use | Why |
|----------|-----|-----|
| **manipulating a single phyloseq** (subset, reorder, add/edit columns) | **tidypq** verbs | composable pipes, data-masking `.` pronoun, one consistent grammar across the four scales (samples, taxa, occurrences, tree) |
| **computing or transforming counts** (diversity, normalization, rarefaction) | **MiscMetabar** | the published, tested home for numeric methods; single source of truth for transforms |
| **comparing several phyloseq objects** | **comparpq** (`list_phyloseq`, `*_lpq()`) | the only package built around the multi-object `list_phyloseq` S7 class |

A common task crosses two of these (compute *then* write back a column). That is
expected: **compute with MiscMetabar, write with tidypq.** The worked examples
below are exactly these boundary-crossing cases.

### Specialized-domain packages

The three packages above are the ones with real *overlap*. The rest of the
pqverse own distinct domains — there is usually no choice to make, but route to
them rather than re-implementing their job in MiscMetabar:

| Domain | Package | Notes |
|--------|---------|-------|
| Networks & machine learning | **netaipq** | co-occurrence networks, `ggclusternet_pq()`, ML models on phyloseq |
| ggplot2 visualization helpers | **ggplotpq** | prefer over ad-hoc plotting code; pairs with MiscMetabar plots |
| Bootstrap / rarefaction permutations | **bootpq** | resampling-based estimates and tests |
| FASTA reference databases | **dbpq** | download/format/manage assignment databases |
| Taxonomy-based augmentation | **taxinfo** | enrich from GBIF, Wikipedia, GloBI, … |
| Carbon-footprint estimation | **greenAlgoR** | Green Algorithms accounting, incl. targets pipelines |

If a task in one of these domains can *also* be done with a general MiscMetabar
helper, prefer the specialized package — it is the maintained home for that
domain. (`databases/` at the workspace root is reference-data files, not a
package.)

## Quick reference

PREFER the left column. The right column is the idiom it replaces (still valid,
just not the default).

| Operation | PREFER | over | Why |
|-----------|--------|------|-----|
| Filter taxa (taxonomy / abundance) | `tidypq::filter_taxa_pq(physeq, Phylum == "x", taxa_sums(.) > 100)` | `MiscMetabar::subset_taxa_pq()` / `filt_taxa_pq()` | data-masking + `.` pronoun, no pre-computed boolean vector |
| Filter samples (metadata) | `tidypq::filter_samples_pq(physeq, Height == "Low", sample_sums(.) > 1000)` | `MiscMetabar::subset_samples_pq()` | same arbitrary-expression flexibility |
| Keep top-N taxa | `physeq \|> arrange_taxa_pq(dplyr::desc(taxa_sums(.))) \|> slice_taxa_pq(1:N)` | `subset_taxa_pq()` + manual `sort(taxa_sums())` | order/select separated, no manual ranking |
| Add / edit a `sam_data` column | `tidypq::mutate_samdata_pq(physeq, x = ...)` | `physeq@sam_data$x <- ...` / `add_info_to_sam_data()` | length-checked, sample names preserved, pipeable |
| Add / edit a `tax_table` column | `tidypq::mutate_taxa_pq(physeq, x = ...)` | manual `@tax_table` edits | same guarantees as above |
| Normalize / rel. abundance / rarefy / CLR | `MiscMetabar::transform_pq(physeq, method = "tss" \| "clr" \| "rclr" \| …)` | hand-rolled `mutate_occurrences_pq(. / sample_total)` | one named, tested method per transform |
| Ad-hoc per-cell count math (no named method) | `tidypq::mutate_occurrences_pq(physeq, …)` | — | use only when no `transform_pq()` method fits |
| Hill numbers / diversity (per sample) | `MiscMetabar::divent_hill_matrix_pq()` (low-level) | — | computation lives in MiscMetabar |
| Hill / diversity **with grouping or significance** | `comparpq::div_pq(physeq, modality =, q =, significance =)` | manual per-group loop | wraps the above + aggregation + tests |
| Merge samples by a grouping variable | `MiscMetabar::merge_samples2(physeq, group, …)` | — | only generic sample-merge in the verse |
| Anything over a **list** of phyloseq | `comparpq` `*_lpq()` (`filter_common_lpq()`, `merge_lpq()`, …) | looping a single-object function yourself | `list_phyloseq` is comparpq's domain |
| Convert phyloseq to a tidy tibble | `tidypq::pq_to_tidy(physeq, fact =, bifactor =, merge_sample_by =, transform =, ranks =)` | hand-rolled `psmelt()` + `pivot_longer()` + manual fact/bifactor resolution | canonical deep module (ADR 0002); owns clean_pq, aggregation, transform, rank filtering, NA→"Unknown", 2-level bifactor enforcement |

## Worked example 1 — Hill q=2 into `sam_data`

**Goal:** add the Hill number of order 2 (≈ inverse Simpson) as a per-sample
column of `sam_data`.

### Preferred — compute with MiscMetabar, write with tidypq

```r
library(MiscMetabar)
library(tidypq)

# compute: MiscMetabar owns the numeric method.
# divent_hill_matrix_pq() wants samples as rows -> taxa_as_columns().
hill_q2 <- divent_hill_matrix_pq(taxa_as_columns(physeq), q = 2)[["2"]]

# write: tidypq owns manipulation. Values are in sample order; length-checked.
physeq <- mutate_samdata_pq(physeq, hill_q2 = hill_q2)
```

### Use `div_pq()` instead when you also want grouping / significance

`comparpq::div_pq()` wraps the same `divent_hill_matrix_pq()` and adds grouping
by a modality, aggregation, and significance testing. Reach for it when you need
those, not for a single plain column.

```r
library(comparpq)

# one row per sample, columns hill_0 / hill_1 / hill_2
div <- div_pq(physeq, indices = NULL, q = c(0, 1, 2))
physeq <- tidypq::mutate_samdata_pq(physeq, hill_q2 = div$hill_2)

# grouped + tested in one call:
div_pq(physeq, modality = "Height", indices = NULL, q = 2, significance = TRUE)
```

### The all-MiscMetabar variant this replaces (still valid)

```r
hill_df <- divent_hill_matrix_pq(taxa_as_columns(physeq), q = 2) # rownames = samples
physeq <- add_info_to_sam_data(physeq, df_info = hill_df)
```

This works, but it mixes the *write* step into MiscMetabar. Prefer
`mutate_samdata_pq()` for the write so the manipulation stays in tidypq.

> Note: `MiscMetabar::hill_pq()` is a **plotting** function (it returns
> ggplots) — do not use it to put values into `sam_data`.

## Worked example 2 — keep the 20 most abundant taxa

### Preferred — two tidypq verbs

```r
library(tidypq)

physeq |>
  arrange_taxa_pq(dplyr::desc(taxa_sums(.))) |>
  slice_taxa_pq(1:20)
```

Ordering (`arrange_taxa_pq`) and selection (`slice_taxa_pq`) are separate,
mirroring dplyr; the `.` pronoun refers to the phyloseq object.

### The MiscMetabar variant this replaces (still valid)

```r
top20 <- names(sort(taxa_sums(physeq), decreasing = TRUE))[1:20]
MiscMetabar::subset_taxa_pq(
  physeq,
  taxa_names(physeq) %in% top20,
  taxa_names_from_physeq = TRUE
)
```

Correct, but requires manually computing and matching the ranked names.

## Worked example 3 — convert a phyloseq to a tidy tibble for plotting

**Goal:** produce a long-format tibble from a phyloseq object, with samples
aggregated by a grouping variable, relative-abundance transform applied, and
fact/bifactor columns resolved — ready for ggplot2.

### Preferred — `tidypq::pq_to_tidy()`

```r
library(tidypq)

tidy_df <- pq_to_tidy(
  physeq,
  fact = "Treatment",
  bifactor = "Time",
  merge_sample_by = "Site",
  transform = function(x) x / sum(x),
  ranks = c("Phylum", "Genus")
)

ggplot2::ggplot(tidy_df, ggplot2::aes(x = sample_id, y = abundance, fill = Genus)) +
  ggplot2::geom_col()
```

One call owns the full pipeline: `verify_pq` → `clean_pq` → `pivot_longer` →
join sample_data + tax_table → aggregate by `merge_sample_by` (tibble space) →
apply `transform` per sample (keeps `abundance_raw`) → resolve fact/bifactor
(enforces 2-level on bifactor) → filter zeros. Returns an ungrouped tibble
with `sample_id`, `taxon_id`, `abundance`, `abundance_raw`, `fact`,
`bifactor`, rank columns (NA→"Unknown"), and all sample_data columns.

### The hand-rolled variant this replaces (still valid, but discouraged)

```r
ps <- MiscMetabar::clean_pq(physeq)
otu <- as(phyloseq::otu_table(ps), "matrix")
if (!phyloseq::taxa_are_rows(ps)) otu <- t(otu)
df <- as.data.frame(otu) |> tibble::rownames_to_column("taxon_id")
df <- tidyr::pivot_longer(df, -taxon_id, names_to = "sample_id", values_to = "abundance")
sd <- as.data.frame(phyloseq::sample_data(ps)); sd$sample_id <- rownames(sd)
df <- dplyr::left_join(df, sd, by = "sample_id")
tax <- as.data.frame(phyloseq::tax_table(ps)); tax$taxon_id <- rownames(tax)
df <- dplyr::left_join(df, tax, by = "taxon_id")
# ... then aggregate, transform, resolve fact/bifactor manually
```

Every step is now `pq_to_tidy()`'s job. The hand-rolled version drifts between
callers (NULL semantics, rank filling, aggregation logic).

> **Note:** `phyloseq::psmelt()` still exists and is not deprecated. It is a
> lower-level flatten that does not handle fact/bifactor resolution,
> aggregation, transformation, or rank filtering. Prefer `pq_to_tidy()` when
> you need the full pipeline; use `psmelt()` only when you need its exact
> output format (e.g. for `MiscMetabar::psmelt_samples_pq()`).
>
> **Alternative transforms:** users may also transform the phyloseq object
> before calling `pq_to_tidy()` via `MiscMetabar::transform_pq()`, or
> transform the tibble after via tidyverse `mutate()` (e.g.
> `dplyr::mutate(abundance = abundance / sum(abundance))`).

## Per-domain rules

- **Samples.** Subset/reorder/rename/add columns → tidypq
  (`filter_samples_pq`, `arrange_samples_pq`, `rename_samples_pq`,
  `mutate_samdata_pq`, `select_samdata_pq`). Merge samples by a group →
  `MiscMetabar::merge_samples2()` (computation, no tidypq equivalent).
- **Taxa.** Same tidypq verbs (`filter_taxa_pq`, `arrange_taxa_pq`,
  `slice_taxa_pq`, `mutate_taxa_pq`, `select_taxa_pq`, `rename_taxa_pq`).
  Prefer them over `subset_taxa_pq()` / `filt_taxa_pq()`.
- **Occurrences (counts).** A *named* transform (relative abundance,
  Hellinger, CLR, rarefaction, …) → `MiscMetabar::transform_pq(method =)`.
  Only drop to `tidypq::mutate_occurrences_pq()` for ad-hoc cell math that no
  `transform_pq()` method covers.
- **Diversity.** Per-sample values → `MiscMetabar::divent_hill_matrix_pq()`.
  Grouped / tested / aggregated → `comparpq::div_pq()`. Write results back with
  `tidypq::mutate_samdata_pq()`.
- **Multi-object.** Anything over more than one phyloseq → comparpq's
  `list_phyloseq` and the `*_lpq()` family. Don't reinvent it by looping a
  single-object function.
- **Tidy conversion.** Converting a phyloseq to a long tibble (for ggplot2,
  export, or custom analysis) → `tidypq::pq_to_tidy()`. Don't reinvent the
  pipeline with `psmelt()` + `pivot_longer()` + manual fact/bifactor
  resolution. `pq_to_tidy()` owns clean_pq, aggregation, transform, rank
  filtering, and the canonical NULL semantics for fact/bifactor (ADR 0002).

## When to deviate

- **Performance-sensitive inner loops.** tidypq verbs call `verify_pq()` /
  `clean_pq()` each invocation; in a tight loop, operate on the raw slots once.
- **MiscMetabar CRAN check budget.** Inside MiscMetabar's own examples/tests,
  do not add a tidypq dependency just for style — MiscMetabar must not depend on
  its downstream packages.
- **No tidypq available.** Code that must run with only MiscMetabar installed
  uses the MiscMetabar variants shown above; that is an acceptable, documented
  fallback.

---

Some functions overlap (e.g. `MiscMetabar::filt_taxa_pq()` vs
`tidypq::filter_taxa_pq()`); the golden rule decides which to use. This document
records *preference*, not deprecation — both remain supported.
