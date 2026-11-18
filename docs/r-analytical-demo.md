# Reproducible synthetic R analysis

This is a **newly authored illustration**, not the original consulting implementation or dataset. The fictional CSV contains 20 interactions across three months, with source, intent and outcome tags and deliberate missing classifications. Names and numbers have no relationship to the original client.

## Run

- R (base packages) for tabular analysis and regression tests.
- `ggplot2` for saved charts.

```bash
Rscript tests/test_current_state.R
Rscript analysis/current_state.R data/fictional_conversations.csv output/r-analysis
```

The CLI writes `quality.csv`, `monthly.csv`, `tags.csv`, `cooccurrence.csv`, `recommendations.csv`, `monthly_volume.png` and `tag_coverage.png` into the ignored output directory.

## What is measured

| Diagnostic | Definition | Decision supported |
|---|---|---|
| Conversation volume | Unique conversation IDs per month | Demand trends |
| Tag coverage | Conversation IDs with at least one nonempty tag / all IDs | Classification completeness |
| Tag frequency | Unique conversation–tag pairs per label | Taxonomy use; deliberately not a sum of exclusive categories |
| Tag co-occurrence | Number of conversations containing both tags, counting each pair once per conversation | Separation of mixed classification dimensions |
| Recommendations | Rule-triggered prompts based on observed fixture characteristics | Illustrates how diagnostics inform a governance discussion |

**Expected synthetic fixture:** 20 conversations, 15 tagged and 5 untagged (75% coverage); monthly conversation totals 6, 6 and 8. Labels are not mutually exclusive. Tag occurrences must never be represented as a count of unique conversations.

## Limitations

The charts and recommendations are **illustrative**; the sample is deliberately too small for inference, benchmarking or operational performance claims. Tag co-occurrence indicates shared classification, not association causality. The recommendation rules are simple pedagogical prompts, not optimisation or deployed AI workflow logic. This R module is intentionally separate from the synthetic Python pipeline and does not consume its inputs.

The historical engagement also included direct workflow inspection, stakeholder consultation and implementation of structured custom attributes supporting AI-bot workflow progression and operational reports. None of those client artefacts is reproduced by this fictional example.
