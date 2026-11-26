# hh-rlhf (Anthropic), helpful-base test split

The `hh_*` rows in `evals/comparator/sets/comparator.jsonl` (inputs and gold) and their labeling
passes in `evals/comparator/labels/comparator.jsonl` are derived from
[Anthropic/hh-rlhf](https://huggingface.co/datasets/Anthropic/hh-rlhf)
([github.com/anthropics/hh-rlhf](https://github.com/anthropics/hh-rlhf)), under the MIT License:

```
MIT License

Copyright (c) 2022 Anthropic

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- Source: `helpful-base/test.jsonl.gz` at revision `09be8c5bbc57cb3887f3a9732ad6aa7ec602a1fa`
  (SHA-256 `8be3fc1a13b27901631696f2be6f184c799f1baeaf145f53ac5db24960adc37b`).
- Paper: Bai et al. "Training a Helpful and Harmless Assistant with Reinforcement Learning from Human
  Feedback." 2022.
- Changes (`build.rb`): the shared conversation becomes the `criteria` and the two last replies the
  players, with the side picked by a hash; conversations with sensitive topics, more than two user
  turns or very short or long replies are left out.
