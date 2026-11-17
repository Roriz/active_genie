# CondaQA

The `condaqa_*` cases in `eval/cases/extractor.with_litote.jsonl` and their gold in
`eval/gold/extractor.with_litote.jsonl` are derived from CondaQA, licensed under the
[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

- Source: https://huggingface.co/datasets/lasha-nlp/CONDAQA, commit
  `3c9caa2f2f6960711e7f4d2e800581def2b6c183`, `test.json` (SHA-256
  `ffd7f4ad85689b2317283430a226cd759c3ccc40070e6a32652e7ae84ae90e8e`)
- Paper: Ravichander, Gardner, Marasović. "CondaQA: A Contrastive Reading Comprehension Dataset for
  Reasoning about Negation." EMNLP 2022.
- Changes: each selected question becomes a one-field extraction (`answer`: yes or no); the
  passage text is copied unchanged; "DON'T KNOW" becomes absent gold (null). Selection is done by `build.rb`.
