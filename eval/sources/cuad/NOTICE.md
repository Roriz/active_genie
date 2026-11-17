# CUAD v1 (Contract Understanding Atticus Dataset)

The `cuad_*` cases in `eval/cases/extractor.data.jsonl` and their gold in
`eval/gold/extractor.data.jsonl` are derived from CUAD v1 by The Atticus Project, licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Unlike the rest of this repository (MIT),
those lines remain under CC BY 4.0.

- Source: https://zenodo.org/records/4595826 (CUAD_v1.zip, SHA-256
  `88b694d99007d39777fa44cd72daf8297773d285dc3eab0091ba32078888d18e`)
- Paper: Hendrycks, Burns, Chen, Ball. "CUAD: An Expert-Annotated NLP Dataset for Legal Contract
  Review." NeurIPS 2021 Datasets and Benchmarks.
- Changes: contract texts are copied with trailing whitespace removed; the gold is converted from the
  normalized answers in `master_clauses.csv` by `build.rb` (dates to ISO 8601, Yes/No to booleans,
  blank answers to "absent").
