# Analytical consulting: current state to future state

## Engagement and evidence

The archived engagement covered a review of 26 operational workflows and analysis of more than 25,000 conversation records from January–May 2025. The historical analysis was undertaken in **R/RStudio**, with **tidyverse, dplyr, tidyr, lubridate, ggplot2 and widyr** supporting transformation, aggregation, visualisation and tag co-occurrence analysis. **Quarto** was used to organise technical analysis and stakeholder-facing findings. The scope numbers are recorded in the private archive; no underlying records are redistributed here.

## 1. Current-state data audit

The analysis examined the organisation and reliability of existing metadata before attempting an automation redesign:

| Diagnostic question | Analytical approach | Decision relevance |
|---|---|---|
| How does interaction volume vary over time? | Monthly counts of distinct conversations and trend visualisations | Separate sustained demand from episodic changes |
| How completely are interactions classified? | Tagged versus untagged coverage; missing-label counts | Assess reporting gaps and metadata governance |
| How are categories used? | Frequency distributions and multi-tag expansion | Distinguish classification conventions from operational facts |
| Which labels occur together? | Deduplicated conversation–tag pairs and pairwise co-occurrence | Detect overlapping purposes and inform taxonomy redesign |
| What channels or business areas can be reliably segmented? | Exploratory source/category mappings and cross-tabulation | Test whether existing labels can answer management questions |
| What do automations actually do? | Inventory and functional grouping of workflows | Identify coverage gaps and candidates for consolidation |

**Measurement discipline:** A conversation bearing several tags must not be counted as several distinct conversations. Tag occurrences, tagged conversations and unique conversations are different denominators and should be labelled separately. Derived indicators were exploratory, not causal estimates.

## 2. Diagnosis

The original audit identified a material classification issue: tags were being used for different functions, including interaction source, business/product grouping, intent and other operational purposes. The archive also records significant untagged coverage and inconsistent application across workflows. These findings limited the interpretability of native reports and the ability to compare operational segments consistently.

The workflow review distinguished lightweight tag/closure automations from more elaborate routing and customer interaction flows. A larger number of workflows was not treated as evidence of better coverage or performance.

## 3. Future-state design and implementation

The proposed direction was a **purpose-separated data model** supporting clearer operational decisions, together with more consistent automation coverage:

- Establish separate dimensions for interaction source, business/product category, intent, outcome and workflow provenance.
- Govern the permitted values and rules for applying them; distinguish known, unknown and not-applicable classifications.
- Align the automation inventory with channel and business coverage instead of accumulating independent ad hoc flows.
- Evaluate an external reporting solution if the operational platform's native reports cannot expose the required fields and measures.
- Pilot the proposed model in a bounded workflow before broader rollout; use observed classification and routing results to refine the design.

The recommendations guided subsequent implementation of AI-bot chat workflows and a structured custom-data-attribute model. Design options beyond the delivered scope are presented as recommendations, not completed changes.

## 4. Technical implementation and operational reporting

A historical subset was used to test mapping legacy classifications into structured conversation attributes through the platform's API. This feasibility work informed a refined custom-data-attribute structure used to capture progression through newly created AI-bot chat workflows. Supporting operational reports provided visibility into the workflow data. The delivered solution joined the current-state assessment to practical workflow and reporting configuration.

The private implementation covers request construction, batch updates, status handling and operational logging. Those scripts and exact client mappings remain private. The public Python ETL demo separately demonstrates traceable revisions, quarantine and reconciliation using fictional input; it is **not** a reconstruction of the client's environment.

The initial audit identified limitations in reporting on the legacy metadata model. The subsequent delivery included structured attributes and supporting operational reports for the new AI-bot workflows. The exploratory reporting constraints and the delivered operational reporting serve different purposes and should not be conflated.

## 5. Communication and decision support

R-generated tables and ggplot visualisations were incorporated into Quarto reporting, translating exploratory results into taxonomy governance, workflow design and reporting recommendations. The subsequent implementation delivered a refined attribute structure, new AI-bot chat workflows and supporting operational reports. These are the reported deliverables; this case study does not present invented financial or performance-impact estimates.

## 6. Transferable skills

- **Applied analytics:** use R to identify reporting-data quality problems and quantify their scope.
- **Data modelling:** derive a coherent schema from inconsistent operational classifications.
- **System analysis:** integrate quantitative findings with workflow discovery and platform constraints.
- **Implementation:** translate validated metadata and workflow requirements into a delivered attribute structure, AI-bot chat workflows and operational reports.
- **Decision communication:** connect reproducible analysis to prioritised options and implementation sequencing.

## Scope and disclosure

This is a retrospectively authored, non-client-specific case study. Illustrative category names and descriptions are generic. The private archive contains the contemporaneous R analysis and client materials; no original client charts, source records, scripts or detailed configuration are reproduced here. Source-specific outcomes are reported only where supported by the archive.
